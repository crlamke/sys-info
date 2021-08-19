# sysreport.sh
A Linux bash script useful for determining system resources and health.

I'm actively working on this script and taking bug reports and suggestions for functionality. The easiest way to contact me is to tweet at me - https://twitter.com/crlamke.

## Current functionality 
1. Generates single file HTML report, useful for cron based automated run and email
2. Disk space stats
3. Top processes by CPU
4. Top processes by RAM
5. Docker stats
6. Recent package changes (e.g. yum or apt history)
7. Recent user history
8. Recent sys logs (currently only dmesg)
9.    
## Planned functionality
1. Generate plain text report
2.  
## Requirements to run script 
1. You must run this script as root/superuser.
2. This script outputs HTML and text results and requires the ability to write files to the current/run directory
3. Tools required for the script to fully run
   * systemd-detect-virt - to determine whether the script is running in a VM and if so what type of VM
   * getconf - used to determine number of processors online
   * column - used to format text output
4. This script fully supports RHEL/CENTOS 7 and partially supports Ubuntu 20.x LTS. More support will be added as time allows.
5. bash v4.2 or later
6. Note that tools like ps, sed, awk, etc. universally included in Linux distros are required for this script but not listed here.
7. mailx - Only if you want the email functionality
8.   
## Optional components that will be reported if present
1. If docker is running, the script will provide information on docker containers (currently) with more info to be added.
2. 
## Inspired By
1. The article [Linux Performance Analysis in 60,000 Milliseconds | Netflix TechBlog](https://netflixtechblog.com/linux-performance-analysis-in-60-000-milliseconds-accc10403c55)
2. My experience in development, sysadmin, and security roles.
