#!/bin/bash
#
#Script Name : sys-info.sh
#Description : This script provides the system resources and configuration
#              including RAM,CPUs, disk, last update date, uptime, ...
#Author      : Chris Lamke
#Copyright   : 2021 Christopher R Lamke
#License     : MIT - See https://opensource.org/licenses/MIT
#Last Update : 2021-06-26
#Version     : 0.2
#Usage       : sys-info.sh
#Notes       : 
#

# Report header and data display formats
reportLabelDivider="********************"
subReportHeader="****************"
subReportFooter="****************"
headerFormat="%-10s %-13s %-13s %-24s %-8s"
dataFormat="%-10s %-13s %-13s %-24s %-8s"
NL=$'\n'

# Paths to external tools if needed

# Constants to define function behavior
topProcessCount=5
HTMLOutput=1
TextOutput=1

cores=$(getconf _NPROCESSORS_ONLN)
ram=$(grep 'MemTotal:' /proc/meminfo | awk '{print int($2 / 1024)}')
hostName=$(hostname)
hostIP=$(hostname -I)
runDTG=$(date +"%Y-%m-%d-%H:%M %Z")

# Report Variables - used to build report after gathering sys info
hwBasicsHTML=""
hwBasicsText=""
topProcStatsHTML=""
topProcStatsText=""
diskStatsHTML=""
diskStatsText=""
dockerStatsHTML=""
dockerStatsText=""
packageChangeStatsHTML=""
packageChangeStatsText=""
recentUserStatsHTML=""
recentUserStatsText=""
anomalousStatsHTML=""
anomalousStatsText=""
syslogStatsHTML=""
syslogStatsText=""
#suggestionsHTML=""
#suggestionsText=""


# Name: reportHWBasicStats
# Parameters: none
# Description: Print report header with machine type and resource info
function reportHWBasicStats
{
  hwBasicsText+="Report Run Time: ${runDTG}${NL}"
  hwBasicsText+="Hardware Resources: ${cores} CPU cores | ${ram} MB RAM ${NL}"
  vmtype=$(systemd-detect-virt)
  if [[ $? -eq 0 ]]; then
    hwBasicsText+="Virtualization: Machine is a VM with \"${vmtype}\" type virtualization.${NL}"
  else
    hwBasicsText+="Virtualization: No virtualization detected.${NL}"
  fi
  hwBasicsText+="Hostname: ${hostName}${NL}"
  hwBasicsText+="Host IPs: ${hostIP}${NL}"
  # TODO make cmd below support more platforms
  hwBasicsText+="OS Name and Version: $(cat /etc/redhat-release)${NL}"
  hwBasicsHTML+=$hwBasicsText
  printf "%s" "$hwBasicsText"
  #printf "%s" "$hwBasicsHTML"
}


# Name: reportTopProcesses
# Parameters: none
# Description: Report on processes consuming the most RAM and CPU
function reportTopProcesses()
{
  # Add one to topProcessCount to account for showing the header line.
  processLinesToShow=$(($topProcessCount+1))
  mkfifo tpPipe
  textOut="${subReportHeader}Top Processes${subReportHeader}${NL}"
  htmlOut="<table>"
  IFS=$'\n'
  textOut+="Top ${topProcessCount} processes by CPU${NL}"
  ps -Ao pcpu,comm,pid,user,uid,pmem,cmd --sort=-pcpu | \
    head -n $processLinesToShow > tpPipe &
  while read -r line;
  do
    htmlOut+="<tr><td>$line</td></tr>"
    textOut+="${line}${NL}"
  done < tpPipe
  htmlOut+="</table>"
  rm tpPipe

  mkfifo tpPipe
  htmlOut+="<table>"
  textOut+="Top ${topProcessCount} processes by RAM${NL}"
  ps -Ao pmem,pcpu,comm,pid,user,uid,cmd --sort=-pmem | \
    head -n $processLinesToShow > tpPipe &
  while read -r line;
  do
    htmlOut+="<tr><td>$line</td></tr>"
    textOut+="${line}${NL}"
  done < tpPipe
  htmlOut+="</table>"
  rm tpPipe
  topProcStatsText=$textOut
  topProcStatsHTML=$htmlOut
  printf "\ntopProcStatsHTML out: %s\n" "$topProcStatsHTML"
  #printf "\ntext out: %s\n" "$textOut"
}


# Name: reportDiskStatus
# Parameters: none
# Description: Report on disk status, usage and mounts
function reportDiskStatus()
{
  mkfifo dfPipe
  htmlOut="<table>"
  textOut="***Disk Space***\n"
  IFS=$'\n'
  df -h | grep -vE \
    "^Filesystem|\/sys\/|^cdrom|^cgroup|^proc|^fusectl|^sunrpc|^securityfs|^pstore|^sys" \
    | awk '{ print $6 " "$7" "$1 }' > dfPipe &

  while read -r line;
  do
    htmlOut+="<tr><td>$line</td></tr>"
    textOut+="${line}${NL}"
  done < dfPipe
  htmlOut+="</table>"
  #printf "\nhtml out: %s\n" "$htmlOut"
  #printf "\ntext out: %s\n" "$textOut"
  rm dfPipe
  diskStatsText=$textOut
  diskStatsHTML=$htmlOut
  printf "%s\n\n" "$diskStatsText"
  #printf "HTML is %s\n\n" "$diskStatsHTML"
}


# Name: reportDockerStatus
# Parameters: none
# Description: Report on disk status, usage and mounts
function reportDockerStatus()
{
  htmlOut="<table>"
  textOut="${subReportHeader}Docker Stats${subReportHeader}${NL}"
  # Add one to topProcessCount to account for showing the header line.
  processLinesToShow=$(($topProcessCount+1))
  mkfifo tpPipe
  IFS=$'\n'
  textOut+="Top ${topProcessCount} processes by CPU${NL}"
  ps -Ao pcpu,comm,pid,user,uid,pmem,cmd --sort=-pcpu | \
    head -n $processLinesToShow > tpPipe &
  while read -r line;
  do
    htmlOut+="<tr><td>$line</td></tr>"
    textOut+="${line}${NL}"
  done < tpPipe
  htmlOut+="</table>"
  #printf "\nhtml out: %s\n" "$htmlOut"
  #printf "\ntext out: %s\n" "$textOut"
  rm tpPipe
  mkfifo tpPipe
  htmlOut+="<table>"
  textOut+="Top ${topProcessCount} processes by RAM${NL}"
  ps -Ao pmem,pcpu,comm,pid,user,uid,cmd --sort=-pmem | \
    head -n $processLinesToShow > tpPipe &
  while read -r line;
  do
    htmlOut+="<tr><td>$line</td></tr>"
    textOut+="${line}${NL}"
  done < tpPipe
  htmlOut+="</table>"
  #printf "\nhtml out: %s\n" "$htmlOut"
  #printf "\ntext out: %s\n" "$textOut"
  rm tpPipe
  dockerStatsText=$textOut
  dockerStatsHTML=$htmlOut
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
  printf "\n%s %s %s\n" "$reportLabelDivider" "Recent System Events" "$reportLabelDivider"

}


# Name: reportSuggestions
# Parameters: none
# Description: Report current system status
function reportSuggestions
{
  #printf "\n%s %s %s\n" $reportLabelDivider "Troubleshooting Suggestions" $reportLabelDivider"
  printf "\nSuggestions not yet implemented\n"

}


# Name: createHTMLTOC
# Parameters: 
# Description: Outputs a HTML TOC
function createHTMLTOC
{
  toc="<ul class=\"tocList\">"
  toc+="<li><a href="#BasicInfo">Basic Machine Info</a></li>"
  toc+="<li><a href="#TopProcesses">Top Processes</a></li>"
  toc+="<li><a href="#DiskStats">Disk Stats</a></li>"
  toc+="</ul></div>"
  printf "%s" "$toc"
}


# Name: gatherInfo
# Parameters: 
# Description: Run functions that gather the sys info
function gatherInfo
{
  reportHWBasicStats
  reportDiskStatus
  reportTopProcesses
  reportDockerStatus
  #reportAnomalousProcesses
  reportRecentUsers
  reportRecentPackageChanges
  #reportRecentEvents
  #reportSuggestions
}


# Name: createHTMLReport
# Description: Build the HTML report output file
function createHTMLReport
{
  printf "Creating HTML Output\n"
  htmlPage="<!DOCTYPE html><html><head><title>"
  htmlPage+="Status Report"
  htmlPage+="</title></head>"
  htmlPage+="<style>"
  htmlPage+="table, th, td { border: 1px solid black; }"
  htmlPage+="h2 { text-align: center; }"
  htmlPage+=".sectionTitle { border: 5px blue; background-color: lightblue;"
  htmlPage+="text-align: center; font-weight: bold;}"
  htmlPage+="</style>"
  htmlPage+="<body>"
  htmlPage+="<div id=\"toc\"><h2><p class=\"pageTitle\">Machine Status Report</p></h2>"
  htmlPage+=$(createHTMLTOC)
  htmlPage+="<div id=\"BasicInfo\"><p class=\"sectionTitle\">Basic Hardware Info</p>"
  htmlPage+="${hwBasicsHTML}"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  htmlPage+="<div id=\"DiskStats\"><p class=\"sectionTitle\">Disk Stats</p>"
  htmlPage+="$diskStatsHTML"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  htmlPage+="<div id=\"TopProcesses\"><p class=\"sectionTitle\">Top Processes</p>"
  htmlPage+="$topProcStatsHTML"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  htmlPage+="<div id=\"DockerStats\"><p class=\"sectionTitle\">Docker Stats</p>"
  htmlPage+="$dockerStatsHTML"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  htmlPage+="<div id=\"PackageChanges\"><p class=\"sectionTitle\">Package Changes</p>"
  htmlPage+="$packageChangeStatsHTML"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  htmlPage+="<div id=\"RecentUsers\"><p class=\"sectionTitle\">Recent Users</p>"
  htmlPage+="$recentUserStatsHTML"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  #htmlPage+="$anomalousStatsHTML"
  htmlPage+="<div id=\"Syslog\"><p class=\"sectionTitle\">Syslog</p>"
  htmlPage+="$syslogStatsHTML"
  htmlPage+="<p><a href="#toc">Back to Top</a></p>"
  htmlPage+="</div>"
  #htmlPage+="$suggestionsHTML"
  htmlPage+="</body></html>"
  echo $htmlPage >./test.html
}

# Name: createTextReport
# Parameters: 
# Description: Build the Text report output file
function createTextReport
{
  printf "Creating Text Output\n"
  textOut="${NL}${NL}${reportLabelDivider} ${hostName} Status Report ${reportLabelDivider}${NL}"
#hwBasicsText=""
#topProcStatsText=""
#diskStatsText=""
#dockerStatsText=""
#packageChangeStatsText=""
#recentUserStatsText=""
#anomalousStatsText=""
#syslogStatsText=""
#suggestionsText=""
#footerText=""
  echo $textOut
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

#Run the sys info gathering functions
gatherInfo

if (( $HTMLOutput != 0 )); then
  createHTMLReport
fi

if (( $TextOutput != 0 )); then
  createTextReport
fi

