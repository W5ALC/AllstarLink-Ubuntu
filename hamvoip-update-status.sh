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
# Perform pacman update of system
#

IP=$(curl -s http://myip.hamvoip.org/ 2>&1)
PACMAN=/usr/local/hamvoip-pacman/bin/pacman

### Test for Internet Connectivity
if [ "$IP" != "" -a -x "$PACMAN" ] ; then

	echo -e "\nChecking update status\n"
	result=`$PACMAN -Sy`
	result=`$PACMAN -Qu`
	if [ -z "$result" ]
	then
		echo -e "System up to date\n"
	else
		echo -e "The following packages need updating - \n\n$result\n"
	fi
else
	echo "\nNo Internet connectivity - cannot check update status\n"
fi
read -n 1 -s -r -p "Press any key to continue"
echo -e "\n"
