#!/bin/bash

# script to test hamvoip system for diagnostic purposes
# Use the results of this script to email a hamvoip developer
# DO NOT put the results on the arm-allstar forum
# 
# Doug Crompton - WA3DSP - 9/2017

Capture_File="/tmp/test_data.txt"

clear
echo -e "\n\nGathering Diagnostic Information\n"
echo "Saving IP addresses"
ip a > $Capture_File
echo -e "\n" >> $Capture_File
echo "Checking DNS server"
cat /etc/resolv.conf >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Checking DNS resolution"
ping -c 3 -W 10 ucsd.edu >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Checking USB devices"
lsusb >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Checking Asterisk process"
ps ax | grep "[a]sterisk" >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Get Asterisk Version Information"
R1=$(head -1 /etc/allstar_version)
R2=$(/sbin/asterisk -V)
R3=$(cat /proc/version | awk -F '[(][g]' '{print $1}')
R4=$(cat /proc/version | awk -F '[(][g]' '{print "g"$2}')
echo "Hamvoip Firmware Version - $R1" >> $Capture_File
echo "Hamvoip Allstar Version - $R2" >> $Capture_File
echo -e "Linux Kernel Version - $R3\n$R4" >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Get registration state"
/usr/bin/asterisk -rx "iax2 show registry" >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Saving rpt_extnodes file status"
ls -ls /tmp/rpt_extnodes >> $Capture_File
echo "Checking Node lookup methods"
/usr/bin/asterisk -rx "rpt lookup $NODE1" >> $Capture_File
echo -e "\n" >> $Capture_File
echo "Checking Node dns lookup"
if [ -e dns_query ]; then dns_query "$NODE1" >> $Capture_File; fi
echo "Checking Node File Lookup"
grep "$NODE1" /tmp/rpt_extnodes >> $Capture_File
echo -e "\n" >> $Capture_File
echo
read -n 1 -s -r -p "Press any key to continue"
tput reset
echo -e "\n\nCopy from here down"
echo "--------------------------------------------------------------------------------------------"
cat /tmp/test_data.txt
echo "--------------------------------------------------------------------------------------------"
echo -e "Scroll back and copy to here and paste in an email"
echo -e "or copy the /tmp/test_data.txt file and attach to an email"
echo -e "Send the results to a hamvoip developer directly"
echo -e "DO NOT send to the arm-allstar email list!\n"


