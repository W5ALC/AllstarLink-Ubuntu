#! /bin/bash
#
# Send current IP address in Morse code to BBB LED
# WA3DSP 5/2014

# Following changed due to interim kernel changes 3.16.1 to 3.16.3
#LED=/sys/class/leds/beaglebone:green:usr0       ### KB4FXC 2014-09-20
#LED=/sys/class/leds/beaglebone:green:heartbeat	### KB4FXC 2014-08-23
#
# RPi2 only has one usuable LED
# WA3DSP 2015-03-08
# ---------------
# Copyright (C) 2015, 2016 Doug, WA3DSP; David, KB4FXC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
# ---------------
#

LED=/sys/class/leds/led0

DOTDELAY=0.1
DASHDELAY=0.3

# Turn off LED automation just in case
echo none >$LED/trigger


function dot {
# Note: The space after 255 (or 0) is important!
echo 255 >$LED/brightness
# Note: GNU Core utilis sleep allows floating point
sleep $DOTDELAY
echo 0 >$LED/brightness
sleep $DOTDELAY

}

function dash {
# Note: The space after 255 (or 0) is important!
echo 255 >$LED/brightness
# Note: GNU Core utilis sleep allows floating point
sleep $DASHDELAY
echo 0 >$LED/brightness
sleep $DOTDELAY
}

function space {
sleep $DASHDELAY
}

function zero {
dash
dash
dash
dash
dash
}

function sendH {
dot
dot
dot
dot
}

function sendI {
dot
dot
}

function one {
dot
dash
dash
dash
dash
}

function two {
dot
dot
dash
dash
dash
}

function three {
dot
dot
dot
dash
dash
}

function four {
dot
dot
dot
dot
dash
}

function five {
dot
dot
dot
dot
dot
}

function six {
dash
dot
dot
dot
dot
}

function seven {
dash
dash
dot
dot
dot
}

function eight {
dash
dash
dash
dot
dot
}

function nine {
dash
dash
dash
dash
dot
}

function period {
space
space
}


function sendHI {
for I in 1 2 
do
 sendH
 space
 sendI
 space
 space
 space
done
}

DEVTMP=`ip link show | grep " UP " | grep -v lo | grep -v "link/ether" | awk '{print $2}'`

DEVICE=${DEVTMP/:/}

ip=`ip addr show $DEVICE | awk '/inet / {print $2}' | awk 'BEGIN { FS = "/"}  {print $1}'`

for I in 1 2 3 
do
 sendHI
 sleep 1
 for ((k=0;k<${#ip};++k)); do
   n=(${ip:k:1}) 
   case "$n" in

   0) zero ;; 
   1) one ;;
   2) two ;;
   3) three ;;
   4) four ;;
   5) five ;;
   6) six ;;
   7) seven ;;
   8) eight ;;
   9) nine ;;
   .) period ;;

   esac
 space
 space
 done
done

sleep 4
echo heartbeat >$LED/trigger

