#!/bin/bash
#
#Script Name : sys-info.sh
#Description : This script provides the system resources and configuration
#              including RAM,CPUs, disk, last update date, uptime, ...
#Author      : Chris Lamke
#Copyright   : 2021 Christopher R Lamke
#License     : MIT - See https://opensource.org/licenses/MIT
#Last Update : 2021-06-26
#Version     : 0.1
#Usage       : sys-info.sh
#Notes       : 
#

# Report header and data display formats
reportLabelDivider="--------------------"
subReportHeader="****************"
subReportFooter="****************"
headerFormat="%-10s %-13s %-13s %-24s %-8s"
dataFormat="%-10s %-13s %-13s %-24s %-8s"

# Paths to external tools if needed

# Constants to define function behavior
topProcessCount=5


# Name: reportHeader
# Parameters: none
# Description: Print report header
function reportHeader
{
  # Print headers and data such as hostname and IP
  # that won't change over script run.
  hostName=$(hostname)
  hostIP=$(hostname -i)
  printf "\n\n%s %s %s\n" $reportLabelDivider "System Status Report" $reportLabelDivider
  printf "\nHostname: %s\tHost IP: %s\n" $hostName $hostIP
  # TODO make cmd below support more platforms
  printf "\nOS Ver: %s\n" "$(cat /etc/redhat-release)"
  
}

# Name: reportSystemHW
# Parameters: none
# Description: Report recent system changes via yum
function reportSystemHW()
{
  #if [[ vmtype=$(systemd-detect-virt) ]] 
  vmtype=$(systemd-detect-virt)
  printf "%s CPU cores | %s RAM | %s virtual. VM Type: %s\n" "$subReportHeader" "Recent Package Changes" "$subReportHeader" 
  printf "yum history\n"
  yum history
}

# Name: reportTopProcesses
# Parameters: none
# Description: Report on processes consuming the most RAM and CPU
function reportTopProcesses()
{
  printf "\n%s %s %s\n" "$subReportHeader" "Top Processes" "$subReportHeader" 
  # Add one to topProcessCount to account for showing the header line.
  processLinesToShow=$(($topProcessCount+1))
  printf "Top %s processes by CPU\n" $topProcessCount
  ps -Ao pcpu,comm,pid,user,uid,pmem,cmd --sort=-pcpu | head -n $processLinesToShow
  printf "\nTop %s processes by RAM\n" $topProcessCount
  ps -Ao pmem,pcpu,comm,pid,user,uid,pcpu,cmd --sort=-pmem | head -n $processLinesToShow
}


# Name: reportDiskStatus
# Parameters: none
# Description: Report on disk status, usage and mounts
function reportDiskStatus()
{
  printf "\n%s %s %s\n" "$subReportHeader" "Disk Status" "$subReportHeader" 
  printf "Disk Status using \"df -kh\"\n"
  df -kh
}


# Name: reportAnomalousProcesses
# Parameters: none
# Description: Report zombie, orphan, and other potentially anomalous processes
function reportAnomalousProcesses()
{
  printf "\n%s %s %s\n" "$subReportHeader" "Anomalous Processes" "$subReportHeader" 
  printf "Checking for zombie processes using \"ps axo pid=,stat= | awk '$2~/^Z/ { print $1 }'\"\n"
  ps axo pid=,stat= | awk '$2~/^Z/ { print $1 }'
  printf "Checking for orphan processes - not yet implemented\n"
}


# Name: reportRecentUsers
# Parameters: none
# Description: Report recently logged in users
function reportRecentUsers()
{
  printf "\n%s %s %s\n" "$subReportHeader" "Recent Users" "$subReportHeader" 
  printf "Current users and their activities using \"w\"\n"
  w
  printf "\nRecently logged in users using \"last\"\n"
  last -F -n 10
}


# Name: reportRecentPackageChanges
# Parameters: none
# Description: Report recent system changes via yum
function reportRecentPackageChanges()
{
  printf "\n%s %s %s\n" "$subReportHeader" "Recent Package Changes" "$subReportHeader" 
  printf "yum history\n"
  yum history
}


# Name: reportCurrentStatus
# Parameters: none
# Description: Report current system status
function reportCurrentStatus
{
  printf "\n%s %s %s\n" $reportLabelDivider "Current System Status" $reportLabelDivider

  reportTopProcesses

  reportDiskStatus

  reportRecentUsers

  reportAnomalousProcesses
}

# Name: reportRecentEvents
# Parameters: none
# Description: Report current system status
function reportRecentEvents
{
  printf "\n%s %s %s\n" $reportLabelDivider "Recent System Events" $reportLabelDivider

  reportRecentPackageChanges
}


# Name: reportSuggestions
# Parameters: none
# Description: Report current system status
function reportSuggestions
{
  printf "\n%s %s %s\n" $reportLabelDivider "Troubleshooting Suggestions" $reportLabelDivider
  printf "\nSuggestions not yet implemented\n"

}


# Name: reportFooter
# Parameters: none
# Description: Report on processes consuming the most RAM and CPU
function reportFooter
{
  hostName=$(hostname)
  hostIP=$(hostname -i)
  printf "\n\nHostname: %s\tHost IP: %s\n" $hostName $hostIP
  printf "\n%s %s %s\n" $reportLabelDivider "End System Status Report" $reportLabelDivider
}

function potential-code() 
{
echo -e "-------------------------------System Information----------------------------"
echo -e "Hostname:\t\t"`hostname`
echo -e "uptime:\t\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
echo -e "Manufacturer:\t\t"`cat /sys/class/dmi/id/chassis_vendor`
echo -e "Product Name:\t\t"`cat /sys/class/dmi/id/product_name`
echo -e "Version:\t\t"`cat /sys/class/dmi/id/product_version`
echo -e "Serial Number:\t\t"`cat /sys/class/dmi/id/product_serial`
echo -e "Machine Type:\t\t"`vserver=$(lscpu | grep Hypervisor | wc -l); if [ $vserver -gt 0 ]; then echo "VM"; else echo "Physical"; fi`
echo -e "Operating System:\t"`hostnamectl | grep "Operating System" | cut -d ' ' -f5-`
echo -e "Kernel:\t\t\t"`uname -r`
echo -e "Architecture:\t\t"`arch`
echo -e "Processor Name:\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
echo -e "Active User:\t\t"`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
echo -e "System Main IP:\t\t"`hostname -I`
echo ""
echo -e "-------------------------------CPU/Memory Usage------------------------------"
echo -e "Memory Usage:\t"`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}'`
echo -e "Swap Usage:\t"`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'`
echo -e "CPU Usage:\t"`cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1`
echo ""
echo -e "-------------------------------Disk Usage >80%-------------------------------"
df -Ph | sed s/%//g | awk '{ if($5 > 80) print $0;}'
echo ""

echo -e "-------------------------------For WWN Details-------------------------------"
vserver=$(lscpu | grep Hypervisor | wc -l)
if [ $vserver -gt 0 ]
then
echo "$(hostname) is a VM"
else
cat /sys/class/fc_host/host?/port_name
fi
echo ""
echo -e "-------------------------------System Information----------------------------"
echo -e "Hostname:\t\t"`hostname`
echo -e "uptime:\t\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
echo -e "Manufacturer:\t\t"`cat /sys/class/dmi/id/chassis_vendor`
echo -e "Product Name:\t\t"`cat /sys/class/dmi/id/product_name`
echo -e "Version:\t\t"`cat /sys/class/dmi/id/product_version`
echo -e "Serial Number:\t\t"`cat /sys/class/dmi/id/product_serial`
echo -e "Machine Type:\t\t"`vserver=$(lscpu | grep Hypervisor | wc -l); if [ $vserver -gt 0 ]; then echo "VM"; else echo "Physical"; fi`
echo -e "Operating System:\t"`hostnamectl | grep "Operating System" | cut -d ' ' -f5-`
echo -e "Kernel:\t\t\t"`uname -r`
echo -e "Architecture:\t\t"`arch`
echo -e "Processor Name:\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
echo -e "Active User:\t\t"`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
echo -e "System Main IP:\t\t"`hostname -I`
echo ""
echo -e "-------------------------------CPU/Memory Usage------------------------------"
echo -e "Memory Usage:\t"`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}'`
echo -e "Swap Usage:\t"`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'`
echo -e "CPU Usage:\t"`cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1`
echo ""
echo -e "-------------------------------Disk Usage >80%-------------------------------"
df -Ph | sed s/%//g | awk '{ if($5 > 80) print $0;}'
echo ""

echo -e "-------------------------------For WWN Details-------------------------------"
vserver=$(lscpu | grep Hypervisor | wc -l)
if [ $vserver -gt 0 ]
then
echo "$(hostname) is a VM"
else
cat /sys/class/fc_host/host?/port_name
fi
echo ""

}




# Trap ctrl + c 
trap ctrl_c INT
function ctrl_c() 
{
  printf "\n\nctrl-c received. Exiting\n"
  exit
}

#First, check that we have sudo permissions so we can gather the info we need.
if [ "$EUID" -ne 0 ]
  then echo "Please run as root/sudo"
  exit
fi


reportHeader

reportCurrentStatus

reportRecentEvents

reportSuggestions

reportFooter

