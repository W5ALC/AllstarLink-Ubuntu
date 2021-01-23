#/!bin/bash

# Modified 2014/09/29 by David, KB4FXC
# Modified 2016/04/07 by Chris, W0ANM
#
#  $Id: sethost.sh 26 2016-04-11 13:50:22Z w0anm $
#
# ---------------
# Copyright (C) 2015, 2016 David, KB4FXC
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
#MENUFT%040%Change the system Hostname
#
# Host name  setup script
#

HNPATH=/etc/hostname
CUR_HOSTNAME=$(cat $HNPATH)

$SOFF
$D --title "Host Name Setup" --yesno "\nThe current hostname is: ${CUR_HOSTNAME}\n\nDo you want to change this ?" 10 70
RET=$?
if [ $RET -eq 0 ] ; then	# yes
	$SON
	HOSTNAME=$($D --title "Host Name" --inputbox "Enter the new hostname:" 10 70 "${CUR_HOSTNAME}" 3>&1 1>&2 2>&3)
	echo "$HOSTNAME" > $HNPATH
fi
$SON
sync
exit 0


