# © 2011 Chris Stone, Beerware Licensed
# Derived from http://www.jbmurphy.com/2011/09/22/powershell © 2011 Jeffrey B. Murphy

import-module ActiveDirectory

$warningPeriod = 9
#$emailAdmin = "admin@example.com"
#$emailFrom = "PasswordBot." + $env:COMPUTERNAME + "@example.com"
#$smtp = new-object Net.Mail.SmtpClient("mail.example.com")

$maxdays=(Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.TotalDays
$summarybody="Name `t ExpireDate `t DaysToExpire `n"

(Get-ADUser -filter {(Enabled -eq "True") -and (PasswordNeverExpires -eq "False")} -properties *) | Sort-Object pwdLastSet | foreach-object {

    $lastset=Get-Date([System.DateTime]::FromFileTimeUtc($_.pwdLastSet))
    $expires=$lastset.AddDays($maxdays).ToShortDateString()
    $daystoexpire=[math]::round((New-TimeSpan -Start $(Get-Date) -End $expires).TotalDays)
    $samname=$_.samaccountname
    $firstname=$_.GivenName

    if (($daystoexpire -le $warningPeriod) -and ($daystoexpire -gt 0)) {
        $ThereAreExpiring=$true

        $subject = "$firstname, your password expires in $daystoexpire day(s)"
        $body = "$firstname,`n`nYour password expires in $daystoexpire day(s).`nPlease press Ctrl + Alt + Del -> Change password`n`nSincerely,`n`nPassword Robot"

        $smtp.Send($emailFrom, $_.EmailAddress, $subject, $body)

        $summarybody += "$samname `t $expires `t $daystoexpire `n"
    }
#}

#if ($ThereAreExpiring) {
#    $subject = "Expiring passwords"

#    $smtp.Send($emailFrom, $emailAdmin, $subject, $summarybody)
#}