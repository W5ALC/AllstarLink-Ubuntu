#!/bin/bash
#
# Extensive Modification made 3/2018 WA3DSP
# Copyright (C) 2018 WA3DSP
#
# by w0anm
# Old_Id: usb-restore.sh 6 2015-03-08 17:11:48Z w0anm "
#  $Id: usb-restore.sh 8 2016-01-28 20:35:57Z w0anm $

# Restore
#   - use devmon to mount usb device
#   - script to look at a specific directory and list the backups.
#   - extract the save system information and verify with user. see below.
#   - When restoring, check for MAC address. If the mac address is different,
#     then prompt "Detected a Different BBB system backup, do you still want to
#     restore, no, continue..
# ---------------
# Copyright (C) 2015, 2016 Christopher Kovacs, W0ANM
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

# Program Variables.

BACKUP_INFO_FILE=/tmp/.backup_info

# Make sure we are user root
if [ "$(/usr/bin/whoami)" != "root" ] ; then
  echo "${0##*/} must be run as user \"root\"!"
  exit 1
fi

# Functions

ExitComplete() {

    sync; sync
    echo
    echo "  OK to remove USB device, if inserted..."
    echo
    echo "Done..."
    exit 0
}

# Description of program
clear
cat << _EOF

   +==========================================================+
   |  This script restores your allstar backup files from a   |
   |  USB stick that was backed up with the usb-backup.sh     |
   |  script. To restore tar files not backed up to a USB     |
   |  stick use 'tar xvzf <filename.tar.gz> at the Linux      |
   |  prompt in the '/' top directory.                        |
   +==========================================================+

_EOF

while true; do
    read -p "Would you like to continue? [y/n] - " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) echo -e "\nNo Restore made\n"; exit;;
      * ) echo -e "\nPlease answer [y]es or [n]o";;
    esac
done

# check if devmon is running, if not running,  start it
pgrep devmon &> /dev/null || exec /usr/bin/devmon &> /dev/null &

echo
echo "+===========================================================================+"
echo "| Please insert your allstar backup usb thumb drive.                        |"
echo "|                                                                           |"
echo "| Press any key when disk has been inserted, or control-c (Ctl-C) to abort..|"
echo "|                                                                           |"
echo "+===========================================================================+"
read dummy

echo "Checking for media, please wait..."
sleep 4

# get mount point
PREMOUNTPT=$(grep "/dev/sda1" /proc/mounts |grep media | awk '{ print $2 }')

if [ -z "$PREMOUNTPT" ] ; then
    echo "ERROR media not found! Aborting."
    echo
    ExitComplete
fi

# fix spaces, if any,  in mount point
MOUNTPT=$(printf "%s" "${PREMOUNTPT}" | sed 's/\\040/ /g')

# Restore tar file location:

echo "************$MOUNTPT*****************"

cd "$MOUNTPT"

# Select the backup file
echo "Select the desired backup file to restore by entering "
echo "Enter the number of the file you want to use for restore:"
echo "+===========================================================================+"

# enter directory where the backup files are stored.

PS3="==== Your choice === >   "
QUIT="QUIT"
touch "$QUIT"

select FILENAME in *;
do
  case $FILENAME in
        "$QUIT")
          echo "Exiting."
          rm -f ${QUIT}
          exit
          ;;
        *)
          # echo "You picked $FILENAME ($REPLY)"
          TARFILE=$FILENAME
          break
          ;;
  esac
done

# if quit selected, clean up and exit
# you wont file the file if exited
if [ "$TARFILE" = "${QUIT}" ] ; then
    echo
    echo "    Exiting Program..."
    echo
    rm -f ${QUIT}
    ExitComplete
else
    rm -f ${QUIT}
fi

# read the the tar file to gather the backup information
tar zxf "$TARFILE" -C / "${BACKUP_INFO_FILE#/}"

STATUS="$?"

if [ "$STATUS" -ne 0  ]; then
    echo
    echo "An error has occured (exit code ${STATUS})"
    echo 
    ExitComplete
fi

source "$BACKUP_INFO_FILE"
echo
echo "Backup information on the file selected: "

cat "$BACKUP_INFO_FILE"

echo
echo -n "If this is correct press any key to continue or control-c to abort? "
read ANS

# The backup file select  verification
MAC=$(ip addr show | grep  -A1 "eth0: " | grep "link/ether" | awk '{print $2}')

#compare the MAC address with backed up address
if [ "$MAC" != "$MACADDR" ] ; then
    echo
    echo "This backup file does not match the current system."
    echo -n "Do you still will to continue (y or n)?"
    read ANS
    if [ "$ANS" = "n" ] ; then
        echo
        echo "Aborting..."
        echo
        exit
    fi

fi

echo
echo "Restore"
echo "========================================================"
echo "    Started..."
echo

# for testing you can change "-C /" to "-C /tmp" for example:
#     tar zxf "$TARFILE" -C /tmp 
# this will restore the files to /tmp

# extract the files
# below alternative for testing
# tar ztvf "$TARFILE" -C /tmp 
tar zxf "$TARFILE" -C / 

STATUS="$?"

if [ "$STATUS" -eq 0  ]; then
    echo
    echo "Restore Completed."
    echo
else
    echo
    echo "An error has occured (exit code ${STATUS})"
    echo 
fi

echo "========================================================"
echo
ExitComplete

exit  #EOF
