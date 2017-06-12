 #Connect-MsolService
 
 $lines = Get-Content c:\tmp\postfixbrukere.txt
    $lines |
     ForEach-Object{
         $user = Get-MsolUser -UserPrincipalName $_ -ErrorAction SilentlyContinue

         if($user) {
         }
         else {
            Write-Output $_
         }
     }