# automateO365EnableMailboxArchive.ps1
# This script is "forked" from https://gist.github.com/arjancornelissen/7732b20ac9fad440d2aba5cb66233001
# Modified by Rune Myrhaug UNINETT AS (20.06.2016)

# HowTo / Usage:
# PowerShell Script to use in Azure Automation (Runbook type = powershell) to manage mailbox.
# Replace group-name license-o365-uninett with your own SecurityGroupName

$ConnectionName = "ExchangeOnline"
$cred = Get-AutomationPSCredential -Name 'AutomateO365Cred'
#$cred = Get-Credential

Connect-MsolService -Credential $cred

$ExchangeOnlineSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection -Name $ConnectionName
Import-Module (Import-PSSession -Session $ExchangeOnlineSession -AllowClobber -DisableNameChecking) -Global

Write-Output "Get all group members"
$GroupID = (Get-MsolGroup -All | Where-Object {$_.DisplayName -eq "license-o365-uninett"}).ObjectId
$GroupMembers = Get-MsolGroupMember -GroupObjectId $GroupID

Write-Output "Go thru all users"
foreach ($user in $GroupMembers) 
{
    $msoluser = Get-MsolUser -ObjectId $User.ObjectId
    $upn = $msoluser.UserPrincipalName
    $mailbox = Get-Mailbox -Identity $upn -ErrorAction SilentlyContinue
    if($mailbox -ne $null -and $mailbox.ArchiveStatus -ne "Active")
    {
        Write-Output "User $upn has no archive enabling"
        $updatedMailbox = Enable-MailBox -Identity $upn -Archive
    }
}
Remove-PSSession $ExchangeOnlineSession
Write-Output "Done enabling mailbox archives"