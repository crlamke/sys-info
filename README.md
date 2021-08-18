# sysreport.sh
A Linux bash script useful for determining system resources and health.

I'm actively working on this script and taking bug reports suggestions for functionality. The easiest way to contact me is to tweet at me - https://twitter.com/crlamke.

## Inspired By
This script is partially based on the article [Linux Performance Analysis in 60,000 Milliseconds | Netflix TechBlog](https://netflixtechblog.com/linux-performance-analysis-in-60-000-milliseconds-accc10403c55), plus my experience wearing a sysadmin hat.

## Current functionality 

## Planned functionality

## requirements to run script 
1. You must run this script as root/superuser.
2. This script outputs HTML and text results and requires the ability to write files to the current/run directory
3. Tools required for the script to fully run
  * systemd-detect-virt - to determine whether the script is running in a VM and if so what type of VM
  * getconf - used to determine number of processors online
4. This script fully supports RHEL/CENTOS 7 and partially supports Ubuntu 20.x LTS. More support will be added as time allows.
5. bash v4.2 or later
6. Note that tools like ps, sed, awk, etc. universally included in Linux distros are required for this script but not listed here.
7. mailx - Only if you want the email functionality
8.   
 
