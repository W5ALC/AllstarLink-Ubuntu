#!/bin/bash
# Modified 2018/01/05 by David, KB4FXC
# ---------------
# Copyright (C) 2014-2018 David, KB4FXC 
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
# 
#MENU%15%Power-cycle the USB sub-system

export HC=/usr/local/sbin/hub-ctrl

$SOFF
$D --title 'Feature not active' --msgbox "\n\nThis feature is not\ncurrently available.\n\n" 20 70

#if ($D --title "Restart USB?" --defaultno --yesno "Press [YES] to power-cycle the USB bus" 20 70) then
#        #yes
#        ANSWER=y
#else
#        #no
#        ANSWER=n
#        $SON
#        exit
#fi



### This method causes 3B+ kernel panics.
#echo 0 >  /sys/devices/platform/soc/3f980000.usb/buspower 
#sleep 1
#echo 1 >  /sys/devices/platform/soc/3f980000.usb/buspower 
#
### New method -- 2019-01-04 -- Doesn't work as expected, removed for now.
#$HC -h 0 -P 2 -p 0 ; sleep 2; $HC -h 0 -P 2 -p 1

exit 0

