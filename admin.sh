#!/bin/bash
# 2017/02/22 by David, KB4FXC
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
### Test for only a single instance!
if [ "$ADMINSH" = "RUNNING" ] ; then
        echo -e "\nAdmin Menu already Running. Type 'exit' to re-enter\n" >&2
        exit 1
fi
export ADMINSH="RUNNING"

### Test for valid terminal type!
TINFO=$(/usr/bin/infocmp "$TERM" 2>&1 | /bin/grep "infocmp: couldn't open terminfo file")
if [ -n "$TINFO" ] ; then
        echo -e "\n\nERROR: admin.sh can't determine your terminal type!"
        echo -e "EXITING to shell prompt.\n\n\n"
        /bin/bash
        exit
fi
#
#
# 
export SON="/usr/bin/setterm --term linux --background blue --foreground white --clear all --cursor on"
export SOFF="/usr/bin/setterm --term linux --background blue --foreground white --clear all --cursor off"
export D="/usr/bin/dialog --clear "

source /usr/local/etc/allstar.env


PROGPATH=/usr/local/sbin/firsttime
NEEDBOOT=NO

while true; do
	idx=1
	MENU=()
	SCRIPT_LIST=()

	NORM=$IFS
	IFS=$'\n'
	for i in $(grep MENU $PROGPATH/*.sh | sort -t '%' -k 2) ; do
		script=$(awk -F: '{print $1}' <<< "$i")
		menuitem=$(awk -F% '{print $3}' <<< "$i")
		MENU+=($idx "$idx $menuitem")
		SCRIPT_LIST[$idx]="$script"
		let idx+=1
	done
	IFS=$NORM
	myip=$(/sbin/ifconfig | awk -F "[: ]+" '/inet / { if ($3 != "127.0.0.1") printf ("%s, ", $3) }')
	if [ -n "$myip" ] ; then myip=${myip::-2}; else myip="none"; fi
###
#### Display a radiolist of menu items and have the user select items to change.
###

	while true; do
		$SOFF
		selection=$($D --no-tags --colors --title "\Zb\Z1Admin Menu List for: $HOSTNAME ($myip)\Zn" --ok-label "Run Selected Item" --cancel-label "Exit / Logout" --menu "Please select:" 23 79 17 "${MENU[@]}" 3>&1- 1>&2- 2>&3-)
		RET=$?
		if [ $RET -ne 0 ] ; then
			NEEDBOOT=LOGOUT
			break;
		fi
		script=${SCRIPT_LIST[$selection]}
		if [ -f "$script" ]; then
			$script
			VAL=$?
			if [ $VAL -eq 10 ] ; then         ### Reboot needed!
				NEEDBOOT=REBOOT
				break
			fi
			if [ $VAL -eq 11 ] ; then         ### Halt needed!
				NEEDBOOT=HALT
				break
			fi
			if [ $VAL -eq 14 ] ; then         ### Reload needed!
				NEEDBOOT=RELOAD
				break
			fi
		fi
	
	done

	if [ "$NEEDBOOT" != "RELOAD" ] ; then         ### break from inner loop!
		break;
	fi
	NEEDBOOT=NO
done

setterm --reset
sync
#echo NEEDBOOT=$NEEDBOOT
#exit 0

if [ "$NEEDBOOT" = "REBOOT" ] ; then         ### Perform Reboot
	### Poke the watchdog to make SURE we reboot!
	/usr/bin/killall watchdog &>/dev/null
	/bin/sleep 1
	echo "1" > /dev/watchdog
	/usr/local/sbin/reboot.sh
fi
if [ "$NEEDBOOT" = "HALT" ] ; then         ### Perform System Halt
	/usr/local/sbin/halt.sh
fi
exit 0
