# automateO365EnableMailboxArchive.ps1
# This script is "forked" from https://gist.github.com/arjancornelissen/7732b20ac9fad440d2aba5cb66233001

# HowTo / Usage:
# Replace group-name license-o365-uninett wit your own group-name

$msoExchangeUrl = "https://ps.outlook.com/powershell"
$msoExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $msoExchangeUrl -Credential $cred -AllowRedirection -Authentication Basic
Import-PSSession $msoExchSession

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
Remove-PSSession $msoExchSession
Write-Output "Done enabling mailbox archives"