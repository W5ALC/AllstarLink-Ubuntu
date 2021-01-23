#!/bin/bash
# Modified 2014/05/17 by David, KB4FXC
# Modified 2016/04/07 by Chris, W0ANM 
# Modified 2017/01/22 by David, KB4FXC
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
#
#
#
# The purpose of this script is to ask some key configuration questions,
# save the configuration, and reboot.
# 
export SON="setterm --term linux --background blue --foreground white --clear all --cursor on"
export SOFF="setterm --term linux --background blue --foreground white --clear all --cursor off"
export D="dialog --clear "

source /usr/local/etc/allstar.env

###First, perform a pacman update!
if [ -f /usr/local/sbin/firsttime/sys-update.sh ]; then
	/usr/local/sbin/firsttime/sys-update.sh
	if [ $? -eq 14 ] ; then		## If we did an update, restart...
		/bin/touch /firsttime
		/bin/sync
          	$SOFF
		$D --title "System has been updated" --msgbox  "The system has been updated and will now reboot to apply changes!" 8 60
		$SON
        	### Poke the watchdog to make SURE we reboot!
		/sbin/killall watchdog &> /dev/null
		echo "1" > /dev/watchdog
		/sbin/reboot
		exit 0
	fi
fi

$SOFF
$D --title "First Time Script" --yesno "Would you like to run first setup now " 8 78
RES=$?

if [ $RES -eq 1 ] ; then
	$SOFF
	$D --msgbox "Okay, if you want to re-run this initial setup script type: firsttime.sh at prompt" 8 78
	$SON
	exit 0
fi


###
#### Run all scripts in the firsttime folder...
###

PROGPATH=/usr/local/sbin/firsttime
NEEDBOOT=N
for i in $(grep MENUFT $PROGPATH/*.sh | sort -t '%' -k 2) ; do
        script=$(awk -F: '{print $1}' <<< "$i")
	if [ -f "$script" ]; then
		$script
		if [ $? -eq 10 ] ; then		### Reboot needed!
			NEEDBOOT=Y
		fi
	fi
done


###
#### Scripts are complete. Prepare to reboot.
###

setterm --reset
echo NEEDBOOT=$NEEDBOOT
sync

if [ "$NEEDBOOT" != "N" ] ; then
        ### Poke the watchdog to make SURE we reboot!
        echo "1" > /dev/watchdog
        /usr/local/sbin/reboot.sh
fi


exit 0
