#/!bin/bash
# Created 2016/09/17 by David, KB4FXC
# Updated 2017/07/27 by David, KB4FXC
# Updated 2018/03/11 by David, KB4FXC
#
# ---------------
# Copyright (C) 2015-2018 David McGough, KB4FXC
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
# Perform pacman update of system unattended
# 
# This script can be run attended or unattended. 
# If run unattended such as in a cron job output
# goes to a log script. This script should only
# be run unattended on systems with stable power.
# Update intervales should generally not be more
# than once a week. User can manually run the update
# when a known update is available in addition to it
# running on a scheduled basis.

logFile="/tmp/update.log"

main() {

IP=$(curl -s http://myip.hamvoip.org/ 2>&1)
PACMAN=/usr/local/hamvoip-pacman/bin/pacman

### Test for Internet Connectivity
if [ "$IP" != "" -a -x "$PACMAN" ] ; then

	text="\nRetrieving the latest system updates\n" 
	output_text
	/bin/rm -f /var/lib/pacman/db.lock /var/lib/pacman/db.lck
        text="\nUpdating - please do not remove power or reboot\n"
	output_text
	$PACMAN --force --noconfirm --yes -Syu 2>&1 
        text="\nFilesystem SYNC in progress. Do NOT power cycle or logout.\n" 
	output_text
	sync
	if [ -f /tmp/pacman-post-process ] ; then
		. /tmp/pacman-post-process
		rm -f /tmp/pacman-post-process
	fi
	echo -e "Update completed\n"
else
	echo -e "Internet not available - cannot update\n"		
fi

}

output_text() {

if [ -t 1 ]
  then
   echo -e $text
fi
}

if [ -t 1 ] ; then 
    main
else
    echo `date` >> $logFile
    main 2>&1 >> $logFile
fi

