Import-Module ActiveDirectory -ErrorAction SilentlyContinue

$firstname = "Amanda"
$surname = "Moody"
$office = "Neptune House"
$samaccountname = "$firstname.$surname"
$logonscript = "Logon.bat"

New-ADUser -AccountPassword (ConvertTo-SecureString “SPSjun17” -AsPlainText -Force) -Enabled $true `
-Name "$firstname $surname" -SamAccountName $samaccountname -GivenName $firstname -Surname $surname `
-DisplayName "$firstname $surname" -UserPrincipalName ($samaccountname + '@spseu.com') -ScriptPath $logonscript `
-HomeDrive H: -HomeDirectory "\\spssrv03\users\$($samaccountname)" -EmailAddress ($samaccountname + '@spseu.com') `
-office $office 