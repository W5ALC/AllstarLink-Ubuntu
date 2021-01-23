#!/bin/bash
# Modified 2016/04/07 by Chris, W0ANM 
# Modified 2016/09/27 by David, KB4FXC
# ---------------
# Copyright (C) 2014, 2015, 2016 David, KB4FXC 
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
#MENUFT%020%Change the primary NODE number
#
# The purpose of this script is to setup the NODE parameter
# 

# need to set the node number initially for the sayIP to work
# correctly
# NODE1=1998   # for testing
if [ "$(expr $NODE1)" -lt 2000 ] ; then
	ANSWER=n
	$SOFF
	$D --title "Private Node Check" --defaultno --yesno "If you have a node number and password assignment from Allstarlink.org you should answer 'NO' to this question. If you intend to use Allstar in a strictly private network such as a repeater link or commercial use then answer 'YES'.\n\nPrivate nodes have self assigned node numbers of less than 2000, are not registered with Allstar and do not require a password. Private nodes require manual routing in the nodes stanza of rpt.conf. Most users would answer 'No' to this question.\n \n Is this a private node?" 20 78
	PVT=$?

	# Private Node Info
	if [ $PVT -eq 0 ] ; then 

		while true ; do #private, get number

			$SON
			NODE1=$($D --title "Private Node Input" --nocancel --inputbox "Enter private node number:" 8 78 "$NODE1"  3>&1 1>&2 2>&3)
			if [ "$(expr $NODE1)" -gt 1999 ]; then
				$SOFF
				$D --title "Node Number Error" --msgbox  "Error, for private number, it must be less then 2000" 8 60
			else
				break
			fi
		done

		sed -i "s/^export PRIVATE_NODE=.*/export PRIVATE_NODE=1/" /usr/local/etc/allstar.env
		sed -i "s/^export NODE1=.*/export NODE1=${NODE1}/" /usr/local/etc/allstar.env

	else

		while true ; do # public, get number

			$SON
			NODE1=$($D --title "Public Node Input" --nocancel  --inputbox "Enter public node number:" 8 78 3>&1 1>&2 2>&3)
			if [ "$(expr $NODE1)" -lt 2000 ]; then
				$SOFF
				$D --title "Node Number Error" --msgbox  "Error, for public number, it must be greater then 1999." 8 60
			else
				break
			fi
		done

		sed -i "s/^export NODE1=.*/export NODE1=${NODE1}/" /usr/local/etc/allstar.env
		sed -i "s/^export PRIVATE_NODE=.*/export PRIVATE_NODE=0/" /usr/local/etc/allstar.env
	fi
fi

# setup for the node-config script

$SOFF
$D --title "Set Node Configuration" --yesno "Set Node Configuration\n\n Do you want to setup your node configuration for asterisk " 10 70
RES=$?

if [ $RES -eq 0 ] ; then
	touch /node-config
	$SOFF
	$D --title "Node Configuration" --msgbox "Node configuration will be run after reboot." 10 70
fi


$SON
exit 0


