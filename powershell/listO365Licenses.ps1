# Script to list all Office365 SKUs (licenses) with associated plans (ServiceName)
# UNINETT AS (Rune Myrhaug)

# Install the Azure AD Module - https://msdn.microsoft.com/en-us/library/jj151815.aspx
# In order to use this script you need to login to O365 (AzureAD) with a user that is assigned "Global Administrator" role
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential

$accountSkuIds = Get-MsolAccountSku

$skuPlanArray = @()

foreach($sku in $accountSkuIds) {

    $sku_plans = $sku.ServiceStatus

    foreach($plan in $sku_plans) {

        $skuPlanObject = New-Object -TypeName psobject -Property @{
            AccountName = $sku.AccountName
            SkuPartNumber = $sku.SkuPartNumber
            ServiceName = $plan.ServicePlan.ServiceName
        }

        $skuPlanArray += $skuPlanObject
    }
}

Write-Output $skuPlanArray