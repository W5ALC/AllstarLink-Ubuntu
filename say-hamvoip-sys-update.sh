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
## Perform pacman update of hamvoip system unattended
#  using voice feedback prompts.
#
# WA3DSP 7/2018
# 
# say-hamvoip-sys-update.sh <node to play voice>
#
# If no node parameter given uses the first $NODE1 parameter
#
# This will redirect logging informmation to the
# log file defined below in the logfile statement.
#
# This script should only be run on systems with
# stable power. That is the power cannot be interrupted
# during the update process.
#
# Update intervals should generally not be more
# than once a week. User can manually run the update
# when a known update is available in addition to it
# running on a scheduled basis.

# This script can be run from the command line but
# is also intended to be used from head-less
# systems using an Allstar function code
#
# Example function - 
#
#	C2=cmd,/usr/local/sbin/say-hamvoip-sys-update.sys
#
#  An optional node to play if not the default first node 
#  can be added as a parameter

# Location of log file. Change this to a non volatile
# area to retain though a boot. Logfile is appended
# and date stamped.

logFile="/tmp/update.log"

# Location of Asterisk sound files
Sfiles="/var/lib/asterisk/sounds"

# Location of additional sound files
Csound="/usr/local/sbin/sounds"

# Location of output file to play
Outfile="/tmp/tmpout"

if [ -z $1 ]
 then
   PlayNode=$NODE1
else
   PlayNode=$1
fi

main() {

IP=$(curl -s http://myip.hamvoip.org/ 2>&1)
PACMAN=/usr/local/hamvoip-pacman/bin/pacman

cat $Sfiles/silence/2.gsm > $Outfile.gsm

### Test for Internet Connectivity
if [ "$IP" != "" -a -x "$PACMAN" ] ; then

	text="\nRetrieving the latest system updates\n" 
	output_text
	Sfilename="system-update-in-progress.gsm"
	playfile 
	/bin/rm -f /var/lib/pacman/db.lock /var/lib/pacman/db.lck
        text="Updating - please do not remove power or reboot\n"
	output_text
	text=`$PACMAN --force --noconfirm --yes -Syu 2>&1`
	output_text 
	Sstring="there is nothing to do"
	if [ "${text/$Sstring}" = "$text" ] ; then
		Update=1
		Sfilename="system-updated.gsm" 
	else
		Update=0
		Sfilename="system-was-up-to-date.gsm" 
	fi
	text="\nFilesystem SYNC in progress. Do NOT power cycle or logout.\n" 
	output_text
	sync
	if [ -f /tmp/pacman-post-process ] ; then
		. /tmp/pacman-post-process
		rm -f /tmp/pacman-post-process
	fi
	text="Update completed\n"
	output_text
	sleep 10
	playfile
else
	text="\nInternet not available - cannot update\n"
	output_text
	Sfilename="system-update-could-not-take-place.gsm"
	playfile			
fi

}

output_text() {
    echo -e "$text"
}

playfile() {
    cat $Sfiles/silence/2.gsm $Csound/$Sfilename  > $Outfile.gsm
    asterisk -rx "rpt localplay $PlayNode $Outfile"
    sleep 4	
}

if [ -z $1 ]
 then
   PlayNode=$NODE1
else
   PlayNode=$1
fi

echo -e "\n`date`" >> $logFile
main 2>&1 >> $logFile

