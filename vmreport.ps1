#Script written by Mark Bernhardt

#This script will give a basic overview of your VM environment exported into
#a plain text file: report.txt.
#It will also collect a list of "hot" items that may warrant attention in a 
#separate hotlist.txt.
#You will need to run get-vc prior to running script.

#TimeStamp for calculating total run time.
$start = Get-Date;

#Supress Error Messages
$erroractionpreference = "SilentlyContinue";

#Status Message
"Generating Reports..."

"VM Environment Report: " + (Get-Date) > report.txt;
"" >> report.txt;
"" >> report.txt;

#Status Message
"Cluster Resources..."

#Resource Usage By Cluster

foreach ($c in get-cluster | sort-object `
@{expression={$_.name};ascending=$true}) `
{'==================== ' + $c.name + ' ====================' >> report.txt; `
#Cluster-Wide Stats (CPU & Mem)
($c | select `
@{name='Cluster CPU Average %';expression={"{0,21:#.00}" -f ($_ | get-vmhost | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}}, `
@{name='Cluster Mem Average %';expression={"{0,21:#.00}" -f ($_ | get-vmhost | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> report.txt; `
#Individual Host Stats (CPU & Mem)
($c | get-vmhost | sort-object @{expression={$_.name};ascending=$true} | `
select name, `
@{name='Host CPU Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}}, `
@{name='Host Mem Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> report.txt; `
#VM to ESX Host Ratio (Powered On VM's Only)
($c | select `
@{name='VMs per Host';expression={"{0,12:#.00}" -f ((($c | get-vm | `
where-object {$_.powerstate -eq "PoweredOn"}).count) / (($c | `
get-vmhost).count))}} `
) >> report.txt; `
#Blank spaces between clusters
"" >> report.txt; `
"" >> report.txt; `
"" >> report.txt; `
};

#Status Message
"Datastore Overview..."

#Datastore Overview. Total Capacity, Free Space, Space used by Powered Off VM's.

"Datastore Overview:" >> report.txt;

#NOTE: VM space is marked as being in kb's but is actually mb's.
(get-datacenter | select name, `
@{name='Total Capacity(GB)';expression={"{0,18:#.00}" -f ((get-datastore | `
Measure-Object -Sum -Property capacitymb).sum/1gb)}}, `
@{name='Free Space(GB)';expression={"{0,14:#.00}" -f ((get-datastore | `
Measure-Object -Sum -Property freespacemb).sum/1gb)}}, `
@{name='Powered Off VMs(GB)';expression={"{0,19:#.00}" -f ((get-vm | `
where-object {$_.PowerState -eq "PoweredOff"} | get-harddisk | `
Measure-Object -Sum -Property capacitykb).sum/1mb)}} `
) >> report.txt;
"" >> report.txt;
"" >> report.txt;


#Datastore Usage (AvailableGB, CapacityGB, % Used)

get-datastore | sort-object @{expression={$_.name};ascending=$true} | `
select name, `
@{name='Available(GB)';expression={"{0,13:#.00}" -f ($_.freespacemb/1gb)}}, `
@{name='Capacity(GB)';expression={"{0,12:#.00}" -f ($_.capacitymb/1gb)}}, `
@{name='% Used';expression={"{0,6:#.00}" -f `
((($_.capacitymb - $_.freespacemb)/$_.capacitymb) * 100)}} `
>> report.txt;

#Status Message
"Generating Hotlist..."

#This section creates a hotlist.txt report for VM's and Hosts that are 
#running "hot".
#This also includes Datastores that are nearly full.

"VM Environment Hot List: " + (Get-Date) > hotlist.txt;
"" >> hotlist.txt;
"" >> hotlist.txt;

#Status Message
"  VMs..."

#VM's that average over 75% memory usage.
"Virtual Machines Over 75% Average Memory Usage:" >> hotlist.txt;

(get-vm | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | get-stat -mem -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -gt 10} | select name, memorymb, `
@{name='VM Mem Usage';expression={"{0,9:#.00}" -f (($_ | `
get-stat -mem -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average)}} `
) >> hotlist.txt;
"" >> hotlist.txt;

#Status Message
"  Hosts..."

#Hosts that average over 75% memory usage.
"ESX Hosts Over 75% Average Memory Usage:" >> hotlist.txt;

(get-vmhost | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -gt 10} | select name, `
@{name='Host Mem Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> hotlist.txt;
"" >> hotlist.txt;

#Hosts that average over 75% cpu usage.
"ESX Hosts Over 75% Average CPU Usage:" >> hotlist.txt;

(get-vmhost | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -gt 10} | select name, `
@{name='Host CPU Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> hotlist.txt;
"" >> hotlist.txt;

#Status Message
"  Datastores..."

#Datastores with less than 10% free.
"Datastores with less than 10% free:" >> hotlist.txt;

(get-datastore | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {(($_.freespacemb / $_.capacitymb) * 100) -lt 10} | select name, `
@{name='Available(GB)';expression={"{0,13:#.00}" -f ($_.freespacemb/1gb)}}, `
@{name='Capacity(GB)';expression={"{0,12:#.00}" -f ($_.capacitymb/1gb)}}, `
@{name='% Used';expression={"{0,6:#.00}" -f `
((($_.capacitymb - $_.freespacemb)/$_.capacitymb) * 100)}}`
) >> hotlist.txt;
"" >> hotlist.txt;
"" >> hotlist.txt;

#Status Message
"Checking ESX Logs..."

#This section will dump ESX vmkwarning messages since the previous day.
"ESX Hosts VMKWarnings since " + `
(get-date (get-date).AddDays(-1) -f MMMdd) + ":" >> hotlist.txt;

foreach ($h in get-vmhost -server $vcserver | `
sort-object @{expression={$_.name};ascending=$true}) `
{(get-log -host $h vmkwarning).entries | `
select-string -pattern ( `
("{0,0} {1,2}" -f (get-date (get-date).AddDays(-1) -f MMM), `
(get-date (get-date).AddDays(-1) -f %d)) `
-or ("{0,0} {1,2}" -f (get-date -f MMM),(get-date -f %d))) `
>> hotlist.txt `
};

#Status Message
"Completed in " + ("{0,2:#.00}" -f `
((Get-Date).Subtract($start).totalminutes)) + " Minutes.";