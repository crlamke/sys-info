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
HTMLOutput=1

cores=$(getconf _NPROCESSORS_ONLN)
ram=$(grep 'MemTotal:' /proc/meminfo | awk '{print int($2 / 1024)}')
hostName=$(hostname)
hostIP=$(hostname -I)
runDTG=$(date)

# Name: reportHeader
# Parameters: none
# Description: Print report header with machine type and resource info
function reportHeader
{
  printf "\n\n%s %s %s %s\n\n" $reportLabelDivider "$hostName" "Status Report" \
    $reportLabelDivider
  printf "Report Run Time: %s\n" "$runDTG"
  printf "Hardware Resources: %s CPU cores | %s MB RAM %s\n" "$cores" "$ram"
  vmtype=$(systemd-detect-virt)
  if [[ $? -eq 0 ]]; then
    printf "Virtualization: Machine is a VM with \"%s\" type virtualization.\n" "$vmtype"
  else
    printf "Virtualization: No virtualization detected.\n"
  fi
  printf "Hostname: %s\n" "$hostName"
  printf "Host IPs: %s\n" "$hostIP"
  # TODO make cmd below support more platforms
  printf "OS Name and Version: %s\n" "$(cat /etc/redhat-release)"
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
  ps -Ao pmem,pcpu,comm,pid,user,uid,cmd --sort=-pmem | head -n $processLinesToShow
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


# Name: reportRecentEvents
# Parameters: none
# Description: Report current system status
function reportRecentEvents
{
  printf "\n%s %s %s\n" $reportLabelDivider "Recent System Events" $reportLabelDivider

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
  printf "\n%s %s %s\n" $reportLabelDivider "End System Status Report" $reportLabelDivider
}

# Name: createHTMLHeader
# Parameters: pageTitle 
# Description: Outputs a basic HTML header with style info.
function createHTMLHeader
{
  header="<!DOCTYPE html><html><head><title>"
  header+=$1
  header+="</title></head>"
  header+="<style>"
  header+="</style>"
  header+="<body>"
  printf "%s" "$header"
}

# Name: createHTMLFooter
# Parameters: pageTitle 
# Description: Outputs a basic HTML footer
function createHTMLFooter
{
  footer="</body></html>"
  printf "%s" $footer
}

# Name: createHTMLTOC
# Parameters: 
# Description: Outputs a HTML TOC
function createHTMLTOC
{
  toc="<div id=\"toc\"><p class=\"tocTitle\">Machine Status Report</p>"
  toc+="<ul class=\"tocList\">"
  toc+="<li><a href="#BasicInfo">Basic Machine Info</a></li>"
  toc+="<li><a href="#TopProcesses">Top Processes</a></li>"
  toc+="<li><a href="#DiskStats">Disk Stats</a></li>"
  toc+="</ul></div>"
  printf "%s" "$toc"
}

# Name: createHTMLBody
# Parameters: 
# Description: Outputs a HTML Body
function createHTMLBody
{
  body="<h4 id=\"#BasicInfo\">Basic Machine Info</h4>"
  body+="<p><a href="#toc">Back to Top</a></p>"
  body+="<h4 id=\"#TopProcesses\">Top Processes</h4>"
  body+="<p><a href="#toc">Back to Top</a></p>"
  body+="<h4 id=\"#DiskStats\">Disk Stats</h4>"
  body+="<p><a href="#toc">Back to Top</a></p>"
  printf "%s" "$body"
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

reportTopProcesses

reportDiskStatus

reportAnomalousProcesses

reportRecentUsers

reportRecentPackageChanges

reportRecentEvents

reportSuggestions

reportFooter

if (( $HTMLOutput != 0 )); then
  printf "Creating HTML Output\n"
  htmlPage=$(createHTMLHeader "Test File")
  htmlPage+=$(createHTMLTOC)
  htmlPage+=$(createHTMLBody)
  htmlPage+=$(createHTMLFooter)
  echo $htmlPage >./test.html
fi

