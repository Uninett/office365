# automateO365UserLicense.ps1
# PowerShell script to assign Office 365 licenses to users based on AzureAD group membership
# This script is "forked" from https://gist.github.com/arjancornelissen/5ab44f0ef5a29f621a147f13a4a3ff42 
# Modified by Rune Myrhaug UNINETT AS (16.06.2016)

#############################################################################
# LicenseSKU -> ServicePlan 15.06.2016:
# https://github.com/UNINETT/office365/blob/master/documentation/o365-licenses.md
#############################################################################

# HowTo / usage:
# Assign users to AzureAD SecurityGroups to organize your license assigment.
# This script will not remove any licenses (SKUs or Plans) that is assigned outside this script.
# NB: If you assign SKU PROJECTONLINE_PLAN_1_FACULTY to a user you first will have to disable the plan SHAREPOINTSTANDARD_EDU (In SKU STANDARDWOFFPACK_FACULTY), since Plan SHAREPOINTENTERPRISE_EDU and SHAREPOINTSTANDARD_EDU cannot coexist.

# Other usefull links:
# https://exitcodezero.wordpress.com/2013/03/14/how-to-assign-selective-office-365-license-options/
# http://social.technet.microsoft.com/wiki/contents/articles/28552.microsoft-azure-active-directory-powershell-module-version-release-history.aspx

#------------------------------------------------------------------------------

# Using this script in Azure Automation you will use "Credential assets" (Get-AutomationPSCredential) to securly authenticate to AzureAD
# https://azure.microsoft.com/nb-no/documentation/articles/automation-credentials/

#$cred = Get-Credential
$cred = Get-AutomationPSCredential -Name 'AutomateO365Cred'
Connect-MsolService -Credential $cred

$Licenses = @{
   'STANDARDWOFFPACK_FACULTY' = @{
        LicenseSKU = 'iktuninett:STANDARDWOFFPACK_FACULTY'
        EnabledPlans = 'OFFICE_FORMS_PLAN_2','PROJECTWORKMANAGEMENT','SWAY','YAMMER_EDU','SHAREPOINTWAC_EDU','MCOSTANDARD','SHAREPOINTSTANDARD_EDU','EXCHANGE_S_STANDARD'
        Group = 'license-o365-uninett'
    }
    'OFFICESUBSCRIPTION_FACULTY' = @{
        LicenseSKU = 'iktuninett:OFFICESUBSCRIPTION_FACULTY'
        Group = 'license-o365-uninett'
    }
    'EMS' = @{
        LicenseSKU = 'iktuninett:EMS'
        Group = 'license-o365-uninett-ems'
    }
}

foreach ($license in $Licenses.Keys) {
    Write-Output "Setting licenses for $license"
    $GroupName = $Licenses[$license].Group
    $GroupID = (Get-MsolGroup -All | Where-Object {$_.DisplayName -eq $GroupName}).ObjectId

    if($GroupID -eq $null) {
        Write-Warning "Group with GroupName $GroupName do not exist in AzureAD. Please check spelling (case-sensitive)."
        break
    }

    $GroupMembers = Get-MsolGroupMember -GroupObjectId $GroupID
    
    # You can assign licenses only to user accounts that have the UsageLocation property set to a valid ISO 3166-1 alpha-2 country code
    # https://technet.microsoft.com/en-us/library/dn771770.aspx
    # Setting UsageLocation to NO (Norway) for all users in group
    $GroupMembers | Get-MsolUser | where {$_.UsageLocation -eq $null} | Set-MsolUser -UsageLocation NO
    
    $AccountSKU = Get-MsolAccountSku | Where-Object {$_.AccountSKUID -eq $Licenses[$license].LicenseSKU}

    #region Disable non specific plans
    $EnabledPlans = $Licenses[$license].EnabledPlans

    if ($EnabledPlans) {
        $DisabledPlans = (Compare-Object -ReferenceObject $AccountSKU.ServiceStatus.ServicePlan.ServiceName -DifferenceObject $EnabledPlans).InputObject
        $LicenseOptionHt = @{
            AccountSkuId = $AccountSKU.AccountSkuId
            DisabledPlans = $DisabledPlans
        }
        $LicenseOptions = New-MsolLicenseOptions @LicenseOptionHt
    }
    #endregion Disable non specific plans

    #Write-Output "Enabled Plans: $EnabledPlans"
    #Write-Output "Disabled Plans: $DisabledPlans"

    foreach ($user in $GroupMembers) 
    {
        $msoluser = Get-MsolUser -ObjectId $User.ObjectId
        $upn = $msoluser.UserPrincipalName
        try
        {
            $LicenseConfig = @{
                UserPrincipalName = $upn
                AddLicenses = $AccountSKU.AccountSkuId
            }
            if ($EnabledPlans) {
                $LicenseConfig['LicenseOptions'] = $LicenseOptions
            }
            # Check if User already has a license and check what needs to be changed (Only adding for now)
            if($msoluser.Licenses.AccountSkuId -notcontains $AccountSKU.AccountSkuId)
            {
                # check license amount quit this loop because there are no licenses left
                $AvailableSku = Get-MsolAccountSku | Where-Object {$_.AccountSKUID -eq $Licenses[$license].LicenseSKU}
                if($AvailableSku.ActiveUnits - $AvailableSku.ConsumedUnits -gt 0 )
                {
                    Set-MsolUserLicense @LicenseConfig -ErrorAction Stop -WarningAction Stop
                    Write-Output "SUCCESS: licensed $upn with $license"
                }
                else
                {
                    Write-Warning "No more licenses ($license) left, order at least $($GroupMembers.Count - $AvailableSku.ActiveUnits)"
                    break
                }
            }
            else
            {
                # User has a license or a part of the license
                # Get current SKU on user
                $currentUserSkuAssignment = $msoluser.Licenses | Where-Object {$_.AccountSkuId -eq $AccountSKU.AccountSkuId}
                # Get disabled plans on this SKU, for user.
                $CurrentDisabledPlans = $currentUserSkuAssignment.ServiceStatus | ? {$_.ProvisioningStatus -eq "Disabled"}
                
                if($EnabledPlans) # If selected (EnabledPlans) plans is defined in $Licenses config
                {
                    if($CurrentDisabledPlans -ne $null) {
                        $div = Compare-Object -ReferenceObject $DisabledPlans -DifferenceObject $CurrentDisabledPlans.ServicePlan.ServiceName

                        if($div.Count -gt 0)
                        {
                            Write-Warning "Detected difference between defined license/plans in this script and assigned license/plan in Office365. $upn needs to be manualy updated for now to license $license"
                        }
                    }
                    else{
                            #$outMessage = "No plans with ProvisionStatus Disabled exist on this SKU (" + $AccountSKU.AccountSkuId + ") for user $upn."
                            #Write-Output $outMessage
                    }

                }
                else # If complete SKU is defined in $Licenses config (Without using EnabledPlans parameter)
                {
                    # All subplans has to be enabled
                    if($CurrentDisabledPlans.Count -gt 0)
                    {
                        Write-Warning "All subplans has to be enabled - $upn needs to be manualy updated for now to license $license"
                    }
                }
            }
        } 
        catch 
        {
            Write-Error "Error when licensing $upn`r`n$_"
        }
    }
}