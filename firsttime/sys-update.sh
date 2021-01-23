#/!bin/bash
# Created 2016/09/17 by David, KB4FXC
# Updated 2017/07/27 by David, KB4FXC
#
# ---------------
# Copyright (C) 2015, 2016, 2017 David McGough, KB4FXC
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
# Perform pacman update of system
#
#MENU%007%Perform a system UPDATE (Internet access required)

IP=$(curl -s http://myip.hamvoip.org/ 2>&1)
PACMAN=/usr/local/hamvoip-pacman/bin/pacman
export DD="/usr/bin/dialog"

### Test for Internet Connectivity
if [ "$IP" != "" -a -x "$PACMAN" ] ; then

	$SOFF
	if ($D --title "Perform System Update" --yesno "\nRetrieve the latest system updates?\n\nDo you want to do this now?" 10 70) then
		# yes -- make sure no old lock files are present.
		/bin/rm -f /var/lib/pacman/db.lock /var/lib/pacman/db.lck
		$SOFF
		$PACMAN --force --noconfirm --yes -Syu 2>&1 | tee /tmp/update.$$ | $D --sleep 1 --progressbox "Updating...Please do NOT reboot!" 10 70 

		$SOFF
		$DD --infobox "Filesystem SYNC in progress.\n\nDo not power cycle or logout." 8 70
		OUT=$(tail -1 /tmp/update.$$ | grep "there is nothing to do")
		/bin/rm -f /tmp/update.$$
		sync

		if [ -f /tmp/pacman-post-process ] ; then
			. /tmp/pacman-post-process
			rm -f /tmp/pacman-post-process
		fi
			
		if [ "$OUT" != "" ] ; then
			RETURN=0
		else
			RETURN=14
		fi
	fi
	exit $RETURN
fi



