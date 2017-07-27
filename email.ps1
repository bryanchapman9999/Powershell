Set-ExecutionPolicy RemoteSigned
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/?proxymethod=rps -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber
Import-csv "C:\pics\1\2.csv" | foreach {Set-UserPhoto -Identity $_.UserName -PictureData ([System.IO.File]::ReadAllBytes($_.Picture))}
