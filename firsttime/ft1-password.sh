#/!bin/bash
# Created 2016/09/17 by David, KB4FXC
#
# ---------------
# Copyright (C) 2016 David, KB4FXC
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
#MENUFT%010%Change the ROOT password
#
# Change the root password using dialog
#

PASS="invalid"

while true ; do

	$SON
	data1=$($D --insecure --passwordbox "Enter a new root password" 8 78 3>&1- 1>&2- 2>&3-)
	ret=$?

	if [ $ret -ne 0 ] ; then ### Bail out on cancel, escape, etc.
		break
	fi

	OUT=$(pwqcheck -1 min=7,7,7,7,7 2>&1 <<< "$data1")
	if [ $? -ne 0 ] ; then
		$SOFF
		$D --title "Error" --msgbox "Error: $OUT\n\nPlease try again!." 10 70
		continue
	fi
	$SON
	data2=$($D --insecure --passwordbox "Re-enter root password for verification" 8 78 3>&1- 1>&2- 2>&3-)
	ret=$?

	if [ $ret -ne 0 ] ; then ### Bail out on cancel, escape, etc.
		break
	fi

	if [ "$data1" != "$data2" ] ; then
		$SOFF
		$D --title "Error" --msgbox "Error! Password do not match!\n\nPlease try again!." 10 70
	else
		PASS=valid
		break
	fi
done

$SON
if [ "$PASS" == "valid" ] ; then
	PASS="root:$data1"
	chpasswd <<< "$PASS"
fi
