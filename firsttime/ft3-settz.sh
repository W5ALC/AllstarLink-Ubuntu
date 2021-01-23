#!/bin/bash
#
#     timezone configure script
#
# Created 2016/09/28 by David McGough, KB4FXC
#
# ---------------
# Copyright (C) 2016 David McGough, KB4FXC
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
#MENUFT%030%Change the system Timezone

CUR_TZ=$(/usr/bin/timedatectl | /usr/bin/grep "Time zone" | /usr/bin/awk '{print $3}')

###
#### Ask if user wants to change Timezones...If not, bail out.
###

$SOFF
$D --title "Time Zone Configuration" --yesno "Time Zone Configuration\n\nThe current time zone is set to: ${CUR_TZ}\n\nA correct time zone entry will allow the system clock to report the correct time.\n\nDo you want to change the default time zone?" 20 78
RET=$?
if [ $RET -ne 0 ] ; then
	$SOFF
	$D --title "Selection Cancelled!" --msgbox "If you need to change the time zone at a future date, enter:\n\n     admin.sh\n" 8 78
	$SON
	exit 0
fi


###
#### User wants to change Timezones...
#### Build an array of timezones, in the format for a dialog radiolist.
#### Generate a dialog progress gauge while building the list.
###

FILE_TZ=/tmp/settz.$$.1
/usr/bin/timedatectl --no-pager list-timezones > $FILE_TZ
LENGTH=$(/usr/bin/wc $FILE_TZ | /usr/bin/awk '{print $1}')

idx=1
old_percent=0
ARY=()
TZLIST=()

$SOFF
for zone in $(cat $FILE_TZ) ; do
	offset=$(env TZ=":$zone" date +"(%Z, %z)")
	printf -v ttemp "%-30s %s" "$zone" "$offset"
	if [ "$zone" == "$CUR_TZ" ] ; then 
		ARY+=($idx "$ttemp" ON)
	else
		ARY+=($idx "$ttemp" OFF)
	fi
	TZLIST[$idx]="$zone"
	let idx+=1
	let percent=idx*100/LENGTH
	if [ $percent -ne $old_percent ] ; then
		echo $percent
		let old_percent=percent
	fi
done > >(dialog --gauge "Building Timezone List" 6 60 0)

/usr/bin/rm -f /tmp/settz.$$.*

###
#### Display a radiolist of timezones and have the user select the desired timezone.
###

while true; do
	$SOFF
	selection=$($D --no-tags --title "Timezone List" --cancel-label "Exit" --radiolist "Please select:" 40 60 30 "${ARY[@]}" 3>&1- 1>&2- 2>&3-)
	RET=$?
	if [ $RET -ne 0 ] ; then
		$SOFF
		$D --title "Selection Cancelled!" --msgbox "If you need to change the time zone at a future date, enter:\n\n     admin.sh\n" 8 78
		$SON
		exit 0
	fi

	$SOFF
	$D --title "Time Zone Selection" --yesno "Your original Timezone was: ${CUR_TZ}\nYour new Timezone is:       ${TZLIST[$selection]}\n\nIs this correct?" 8 78
	RET=$?
	if [ $RET -eq 0 ] ; then
		break
	fi

done

###
#### And, set the new timezone....
###

/usr/bin/timedatectl set-timezone "${TZLIST[$selection]}"

$SON
exit 0


