#######################################################################################################################
# This file will be removed when PowerCLI is uninstalled. To make your own scripts run when PowerCLI starts, create a
# file named "Initialize-PowerCLIEnvironment_Custom.ps1" in the same directory as this file, and place your scripts in
# it. The "Initialize-PowerCLIEnvironment_Custom.ps1" is not automatically deleted when PowerCLI is uninstalled.
#######################################################################################################################
param([bool]$promptForCEIP = $false)

# List of modules to be loaded
$moduleList = @(
    "VMware.VimAutomation.Core",
    "VMware.VimAutomation.Vds",
    "VMware.VimAutomation.Cloud",
    "VMware.VimAutomation.PCloud",
    "VMware.VimAutomation.Cis.Core",
    "VMware.VimAutomation.Storage",
    "VMware.VimAutomation.HorizonView",
    "VMware.VimAutomation.HA",
    "VMware.VimAutomation.vROps",
    "VMware.VumAutomation",
    "VMware.DeployAutomation",
    "VMware.ImageBuilder",
    "VMware.VimAutomation.License"
    )

$productName = "PowerCLI"
$productShortName = "PowerCLI"

$loadingActivity = "Loading $productName"
$script:completedActivities = 0
$script:percentComplete = 0
$script:currentActivity = ""
$script:totalActivities = `
   $moduleList.Count + 1

function ReportStartOfActivity($activity) {
   $script:currentActivity = $activity
   Write-Progress -Activity $loadingActivity -CurrentOperation $script:currentActivity -PercentComplete $script:percentComplete
}
function ReportFinishedActivity() {
   $script:completedActivities++
   $script:percentComplete = (100.0 / $totalActivities) * $script:completedActivities
   $script:percentComplete = [Math]::Min(99, $percentComplete)
   
   Write-Progress -Activity $loadingActivity -CurrentOperation $script:currentActivity -PercentComplete $script:percentComplete
}

# Load modules
function LoadModules(){
   ReportStartOfActivity "Searching for $productShortName module components..."
   
   $loaded = Get-Module -Name $moduleList -ErrorAction Ignore | % {$_.Name}
   $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction Ignore | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}
   
   ReportFinishedActivity
   
   foreach ($module in $registered) {
      if ($loaded -notcontains $module) {
		 ReportStartOfActivity "Loading module $module"
         
		 Import-Module $module
		 
		 ReportFinishedActivity
      }
   }
}

LoadModules

# Update PowerCLI version after snap-in load
$powerCliFriendlyVersion = [VMware.VimAutomation.Sdk.Util10.ProductInfo]::PowerCLIFriendlyVersion
$host.ui.RawUI.WindowTitle = $powerCliFriendlyVersion

# Launch text
write-host "          Welcome to VMware $productName!"
write-host ""
write-host "Log in to a vCenter Server or ESX host:              " -NoNewLine
write-host "Connect-VIServer" -foregroundcolor yellow
write-host "To find out what commands are available, type:       " -NoNewLine
write-host "Get-VICommand" -foregroundcolor yellow
write-host "To show searchable help for all PowerCLI commands:   " -NoNewLine
write-host "Get-PowerCLIHelp" -foregroundcolor yellow  
write-host "Once you've connected, display all virtual machines: " -NoNewLine
write-host "Get-VM" -foregroundcolor yellow
write-host "If you need more help, visit the PowerCLI community: " -NoNewLine
write-host "Get-PowerCLICommunity" -foregroundcolor yellow
write-host ""
write-host "       Copyright (C) VMware, Inc. All rights reserved."
write-host ""
write-host ""

# CEIP
Try	{
	$configuration = Get-PowerCLIConfiguration -Scope Session

	if ($promptForCEIP -and
		$configuration.ParticipateInCEIP -eq $null -and `
		[VMware.VimAutomation.Sdk.Util10Ps.CommonUtil]::InInteractiveMode($Host.UI)) {

		# Prompt
		$caption = "Participate in VMware Customer Experience Improvement Program (CEIP)"
		$message = `
			"VMware's Customer Experience Improvement Program (`"CEIP`") provides VMware with information " +
			"that enables VMware to improve its products and services, to fix problems, and to advise you " +
			"on how best to deploy and use our products.  As part of the CEIP, VMware collects technical information " +
			"about your organization’s use of VMware products and services on a regular basis in association " +
			"with your organization’s VMware license key(s).  This information does not personally identify " +
			"any individual." +
			"`n`nFor more details: press Ctrl+C to exit this prompt and type `"help about_ceip`" to see the related help article." +
			"`n`nYou can join or leave the program at any time by executing: Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP `$true or `$false. "

		$acceptLabel = "&Join"
		$choices = (
			(New-Object -TypeName "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $acceptLabel,"Participate in the CEIP"),
			(New-Object -TypeName "System.Management.Automation.Host.ChoiceDescription" -ArgumentList "&Leave","Don't participate")
		)
		$userChoiceIndex = $Host.UI.PromptForChoice($caption, $message, $choices, 0)
		
		$participate = $choices[$userChoiceIndex].Label -eq $acceptLabel

		if ($participate) {
         [VMware.VimAutomation.Sdk.Interop.V1.CoreServiceFactory]::CoreService.CeipService.JoinCeipProgram();
      } else {
         Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
      }
	}
} Catch {
	# Fail silently
}
# end CEIP

Write-Progress -Activity $loadingActivity -Completed

cd \
###########################################################################################
# Title:	VMware health check 
# Filename:	healtcheck.sp1       	
# Created by:	Ivo Beerens ivo@ivobeerens.nl			
# Date:		28-08-2008					
# Version       1.3						
###########################################################################################
# Description:	Scripts that checks the status of a VMware      
# enviroment on the following point:		
# - VMware ESX server Hardware and version	       	
# - VMware VC version				
# - Active Snapshots				
# - CDROMs connected to VMs			
# - Floppy drives connected to VMs		
# - Datastores and the free space available	
# - VM information such as VMware tools version,  
#   processor and memory limits					
# - Witch VMs have VMware timesync options not 	
#   enabled					
###########################################################################################
# Configuration:
#
#   Edit the powershell.ps1 file and edit the following variables:
#   $vcserver="localhost"
#   Enter the VC server, if you execute the script on the VC server you can use localhost
#   $filelocation="D:\temp\healthcheck.htm"
#   Specify the path where to store the HTML output
#   $enablemail="yes"
#   Enable (yes) or disable (no) to sent the script by e-mail
#   $smtpServer = "mail.ictivity.nl" 
#   Specify the SMTP server in your network
#   $mailfrom = "VMware Healtcheck <powershell@ivobeerens.nl>"
#   Specify the from field
#   $mailto = "ivo.beerens@ictivity.nl"
#   Specify the e-mail address
###########################################################################################
# Usage:
#
#   Manually run the healthcheck.ps1 script":
#   1. Open Powershell
#   2. Browse to the directory where the healthcheck.ps1 script resides
#   3. enter the command:
#   ./healthcheck.ps1
#
#   To create a schedule task in for example Windows 2003 use the following 
#   syntax in the run property:
#   powershell -command "& 'path\healthcheck.ps1'
#   edit the path 
###########################################################################################

####################################
# VMware VirtualCenter server name #
####################################
$vcserver="172.31.100.126"

##################
# Add VI-toolkit #
##################
Add-PSsnapin VMware.VimAutomation.Core
Initialize-VIToolkitEnvironment.ps1
connect-VIServer $vcserver

#############
# Variables #
#############
$filelocation="C:\temp\healthSPS.htm"
$vcversion = get-view serviceinstance
$snap = get-vm | get-snapshot
$date=get-date

##################
# Mail variables #
##################
$enablemail="yes"
$smtpServer = "spseu-com.mail.protection.outlook.com" 
$mailfrom = "VMware Healtcheck <powershell@spseu.com>"
$mailto = "bryan.chapman@spseu.com"

#############################
# Add Text to the HTML file #
#############################
ConvertTo-Html –title "VMware Health Check " –body "<H1>VMware Health script</H1>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File $filelocation
ConvertTo-Html –title "VMware Health Check " –body "<H4>Date and time</H4>",$date -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

#######################
# VMware ESX hardware #
#######################
Get-VMHost | Get-View | ForEach-Object { $_.Summary.Hardware } | Select-object Vendor, Model, MemorySize, CpuModel, CpuMhz, NumCpuPkgs, NumCpuCores, NumCpuThreads, NumNics, NumHBAs | ConvertTo-Html –title "VMware ESX server Hardware configuration" –body "<H2>VMware ESX server Hardware configuration.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

#######################
# VMware ESX versions #
#######################
get-vmhost | % { $server = $_ |get-view; $server.Config.Product | select { $server.Name }, Version, Build, FullName }| ConvertTo-Html –title "VMware ESX server versions" –body "<H2>VMware ESX server versions and builds.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

######################
# VMware VC version  #
######################
$vcversion.content.about | select Version, Build, FullName | ConvertTo-Html –title "VMware VirtualCenter version" –body "<H2>VMware VC version.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" |Out-File -Append $filelocation

#############
# Snapshots # 
#############
$snap | select vm, name,created,description | ConvertTo-Html –title "Snaphots active" –body "<H2>Snapshots active.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />"| Out-File -Append $filelocation

#################################
# VMware CDROM connected to VMs # 
#################################
Get-vm | where { $_ | get-cddrive | where { $_.ConnectionState.Connected -eq "true" } } | Select Name | ConvertTo-Html –title "CDROMs connected" –body "<H2>CDROMs connected.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />"|Out-File -Append $filelocation

#########################################
# VMware floppy drives connected to VMs #
#########################################
Get-vm | where { $_ | get-floppydrive | where { $_.ConnectionState.Connected -eq "true" } } | select Name |ConvertTo-Html –title "Floppy drives connected" –body "<H2>Floppy drives connected.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" |Out-File -Append $filelocation

#########################
# Datastore information #
#########################

function UsedSpace
{
	param($ds)
	[math]::Round(($ds.CapacityMB - $ds.FreeSpaceMB)/1024,2)
}

function FreeSpace
{
	param($ds)
	[math]::Round($ds.FreeSpaceMB/1024,2)
}

function PercFree
{
	param($ds)
	[math]::Round((100 * $ds.FreeSpaceMB / $ds.CapacityMB),0)
}

$Datastores = Get-Datastore
$myCol = @()
ForEach ($Datastore in $Datastores)
{
	$myObj = "" | Select-Object Datastore, UsedGB, FreeGB, PercFree
	$myObj.Datastore = $Datastore.Name
	$myObj.UsedGB = UsedSpace $Datastore
	$myObj.FreeGB = FreeSpace $Datastore
	$myObj.PercFree = PercFree $Datastore
	$myCol += $myObj
}
$myCol | Sort-Object PercFree | ConvertTo-Html –title "Datastore space " –body "<H2>Datastore space available.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

# Invoke-Item $filelocation

##################
# VM information #
##################
$Report = @()
 
get-vm | % {
  $vm = Get-View $_.ID
    $vms = "" | Select-Object VMName, Hostname, IPAddress, VMState, TotalCPU, TotalMemory, MemoryUsage, TotalNics, ToolsStatus, ToolsVersion, MemoryLimit, MemoryReservation, CPUreservation, CPUlimit
    $vms.VMName = $vm.Name
    $vms.HostName = $vm.guest.hostname
    $vms.IPAddress = $vm.guest.ipAddress
    $vms.VMState = $vm.summary.runtime.powerState
    $vms.TotalCPU = $vm.summary.config.numcpu
    $vms.TotalMemory = $vm.summary.config.memorysizemb
    $vms.MemoryUsage = $vm.summary.quickStats.guestMemoryUsage
    $vms.TotalNics = $vm.summary.config.numEthernetCards
    $vms.ToolsStatus = $vm.guest.toolsstatus
    $vms.ToolsVersion = $vm.config.tools.toolsversion
    $vms.MemoryLimit = $vm.resourceconfig.memoryallocation.limit
    $vms.MemoryReservation = $vm.resourceconfig.memoryallocation.reservation
    $vms.CPUreservation = $vm.resourceconfig.cpuallocation.reservation
    $vms.CPUlimit = $vm.resourceconfig.cpuallocation.limit
    $Report += $vms
}
$Report | ConvertTo-Html –title "Virtual Machine information" –body "<H2>Virtual Machine information.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation


###############################
# VMware Timesync not enabled #
###############################

#Get-VM | Get-View | ? { $_.Config.Tools.syncTimeWithHost -eq $false } | Select Name | Sort-object Name | ConvertTo-Html –title "VMware timesync not enabled" –body "<H2>VMware timesync not enabled.</H2>" -head "<link rel='stylesheet' href='style.css' type='text/css' />" | Out-File -Append $filelocation

######################
# E-mail HTML output #
######################
if ($enablemail -match "yes") 
{ 
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($filelocation)
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$msg.From = $mailfrom
$msg.To.Add($mailto) 
$msg.Subject = “VMware Healthscript SPS Cluster”
$msg.Body = “VMware healthscript”
$msg.Attachments.Add($att) 
$smtp.Send($msg)
}

##############################
# Disconnect session from VC #
##############################

disconnect-viserver -confirm:$false

##########################
# End Of Healthcheck.ps1 #
##########################



