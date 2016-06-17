# Script to create a new Global Admin in AzureAD
# UNINETT AS (Rune Myrhaug)

# Install the Azure AD Module - https://msdn.microsoft.com/en-us/library/jj151815.aspx
# In order to use this script you need to login to O365 (AzureAD) with a user that is assigned "Global Administrator" role

# Usage ->
# Replace myUserName with the username you like to use
# Replace myTenantName with your own tenantname
# Replace myPassword with your own password

$myUserName = "AutomateO365Cred"
$myTenantName = "iktuninett"
$myPassword = "Passw0rd"

$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential

New-MsolUser -UserPrincipalName "$myUserName@$myTenantName.onmicrosoft.com" -DisplayName "Azure Automation" -PasswordNeverExpires $true -Password $myPassword -ForceChangePassword $false
Add-MsolRoleMember -RoleName "Company Administrator" -RoleMemberEmailAddress "$myUserName@$myTenantName.onmicrosoft.com"