#!/bin/bash
#
# Wireless Control script.

# ---------------
# Copyright (C) 2016 Christopher Kovacs, W0ANM
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

$SOFF
OPTION=$($D --title "Wireless Control Menu" --menu "Choose your option" 15 60 4 \
"1" "Enable Wireless Device (wlan0)" \
"2" "Disable Wireless Device (wlan0)" \
"3" "Wireless Status" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then

    if [ "$OPTION" = "1" ] ; then
        
		# check if symlink is present, if so, skip
		if [ ! -h /etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service ] ; then
			ln -s /usr/lib/systemd/system/wpa_supplicant@wlan0.service /etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service
		fi

		systemctl enable  wpa_supplicant@wlan0.service 1>/dev/null 2>/dev/null
		systemctl start wpa_supplicant@wlan0.service 1>/dev/null 2>/dev/null
		OPTION=3
    fi

    if [ "$OPTION" = "2" ] ; then
		systemctl stop  wpa_supplicant@wlan0.service 1>/dev/null 2>/dev/null 
		systemctl disable wpa_supplicant@wlan0.service	1>/dev/null 2>/dev/null

		# check if link is present, if so remove link
		if [ ! -h /etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service ] ; then
			rm  -f /etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service
		fi

		OPTION=3
    fi

    if [ "$OPTION" = "3" ] ; then
        REPORT=$(iwconfig wlan0) 
	$SOFF
        $D --title "iwconfig wlan0 results" --msgbox "$REPORT" 24 78
        REPORT=$(ip a s wlan0)
	$SOFF
        $D --title "ip addr show  wlan0 results" --msgbox "$REPORT" 24 78
    fi
else
    echo "Cancelling..."
fi

