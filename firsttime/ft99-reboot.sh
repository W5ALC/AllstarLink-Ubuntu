#!/bin/bash
# Modified 2016/04/07 by Chris, W0ANM 
# Modified 2017/01/10 by David, KB4FXC
# ---------------
# Copyright (C) 2014-2017 David, KB4FXC 
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
#	Display final config data to user and prepare for reboot!
# 
#MENUFT%998%Reboot this system

function getIPaddr {
    DEVICE=$1
    IP=$(ip addr show $DEVICE | awk '/inet / {print $2}' | awk 'BEGIN { FS = "/"}  {print $1}')
   # echo "$IP"
   if (ip addr show $DEVICE | grep dynamic ) ; then
     CURSTATE=DYNAMIC
   else
     CURSTATE=STATIC
   fi
}

# if static, read /etc/systemd/network for Rpi2, if BBB, source the
# config file
grep -v "\[" /etc/systemd/network/eth0.network > /tmp/ip
source /tmp/ip
# find out if dhcp selected or static
if [ "$DHCP" = "none" ] ; then
    # static
    IFMODE=static
else
    #dhcp
    IFMODE=dhcp
fi

getIPaddr eth0

# if CURSTATE=dynamic--> dynamic, then use IP ADDR from ip a
if [ "$CURSTATE" = "DYNAMIC" ] && [ "$IFMODE" = "dhcp" ] ; then
    # get IP address info
    Address=$(getIPaddr eth0 | awk '/inet / {print $2}' | awk 'BEGIN { FS = "/"}  {print $1}')
    ADDRESS=${Address%/*}
fi

# if CURSTATE=static --> dynamic
if [ "$CURSTATE" = "STATIC" ] && [ "$IFMODE" = "dhcp" ] ; then
    ADDRESS="unable to determine as not yet assigned."
fi
    
# if CURSTATE=dynamic --> static, parse eth0.netowrk
if [ "$CURSTATE" = "DYNAMIC" ] && [ "$IFMODE" = "static" ] ; then
    grep -v "\[" /etc/systemd/network/eth0.network > /tmp/ip
    source /tmp/ip
    ADDRESS=${Address%/*}
fi

# if CURSTATE=static --> static, then use IP ADDR form ip a
if [ "$CURSTATE" = "STATIC" ] && [ "$IFMODE" = "static" ] ; then
    grep -v "\[" /etc/systemd/network/eth0.network > /tmp/ip
    source /tmp/ip
    ADDRESS=${Address%/*}
fi

# echo "CURSTATE --> $CURSTATE"
# echo "IFMODE --> $IFMODE"

MESSAGE=$(cat << _EOF
System Reboot

Remember to log back in using the new password and using the
new IP address if you changed it.

Use these values for your next login after reboot: 
   IP Address -  $ADDRESS 
   ssh Port   -  $(grep "Port " /etc/ssh/sshd_config | awk '{print $2}') 

Press <Reboot> to start the reboot process

_EOF
)

$SOFF
if ($D --title "Reboot Info" --yes-label "Reboot" --no-label "Cancel" --yesno "$MESSAGE" 20 70) then
        #yes
        RETURN=10
else
        ##no
        RETURN=0
fi

$SON

###Exit value 10 causes reboot!

exit $RETURN
