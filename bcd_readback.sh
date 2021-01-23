#!/bin/bash

# Script to read last channel set by
# bcd_control_pi.sh or bcd_control_usb_fob.sh
# Call this script with no parameters
#
# D. Crompton, WA3DSP 3/2018

 . /usr/local/etc/allstar.env

vpath="/var/lib/asterisk/sounds"

if [ ! -f /tmp/last_channel ]
  then
      echo -e "\nNo '/tmp/last_channel' file found.\n"
      exit
  else
      channel=`cat /tmp/last_channel`
      echo -e "\nChannel set to $channel.\n"
      cat $vpath/silence/2.gsm $vpath/system.gsm $vpath/ha/set.gsm $vpath/to.gsm $vpath/channel.gsm $vpath/digits/$channel.gsm > /tmp/set-channel.gsm
      /usr/bin/asterisk -rx "rpt localplay $NODE1 /tmp/set-channel"
      sleep 6
      rm -rf /tmp/set-channel.gsm
fi

   
