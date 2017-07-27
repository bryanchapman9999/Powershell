# PowerShell script to check for VM snapshots and send Email report

add-pssnapin VMware.VimAutomation.Core
Connect-VIServer -Server '172.31.100.175' -User 'supreme\bryan.chapman' -Password 'piZZama3'
Connect-VIServer -Server '172.31.100.176' -User 'supreme\bryan.chapman' -Password 'piZZama3'

# HTML formatting
$a = "<style>"
$a = $a + "BODY{background-color:white;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;foreground-color: black;background-color: LightBlue}"
$a = $a + "TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;foreground-color: black;background-color: white}"
$a = $a + "</style>"

# Main section of check
Write-Host "Checking VMs for for snapshots"
$date = get-date
$datefile = get-date -uformat '%m-%d-%Y-%H%M%S'
$filename = "c:\Snaps\Snaps_" + $datefile + ".htm"

# Get list of VMs with snapshots
# Note:  It may take some time for the  Get-VM cmdlet to enumerate VMs in larger environments
$ss = Get-vm | Get-Snapshot
Write-Host "   Complete" -ForegroundColor Green
Write-Host "Generating VM snapshot report"
#$ss | Select-Object vm, name, description, powerstate | ConvertTo-HTML -head $a -body "<H2>VM Snapshot Report</H2>"| Out-File $filename
$ss | Select-Object parent, vm, name, description, created, SizeGB, powerstate | ConvertTo-HTML -head $a -body "<H2>VM Snapshot Report</H2>"| Out-File $filename
Write-Host "   Complete" -ForegroundColor Green
Write-Host "Your snapshot report has been saved to:" $filename

# Create mail message
$server = "spseu-com.mail.protection.outlook.com"
$port = 25
$to      = "bryan.chapman@spseu.com,tom.eaton@spseu.com"
$from    = "admin@spseu.comment"
$subject = "VM Snapshot Report"
$body = Get-Content $filename

$message = New-Object system.net.mail.MailMessage $from, $to, $subject, $body

# Create SMTP client
$client = New-Object system.Net.Mail.SmtpClient $server, $port
# Credentials are necessary if the server requires the client # to authenticate before it will send e-mail on the client's behalf.
$client.Credentials = [system.Net.CredentialCache]::DefaultNetworkCredentials

# Try to send the message

try {

# Convert body to HTML
    $message.IsBodyHTML = $true
# Uncomment these lines if you want to attach the html file to the email message
#   $attachment = new-object Net.Mail.Attachment($filename)
#   $message.attachments.add($attachment)

# Send message
    $client.Send($message)
    "Message sent successfully"

}

#Catch error

catch {

    "Exception caught in CreateTestMessage1(): "

}
