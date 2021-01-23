#!/bin/bash
#
# Backup Script for hamvoip Allstar
# by w0anm
# 
# Extensive Modification made 3/2018 WA3DSP
# Copyright (C) 2018 WA3DSP

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
#
# This script will backup the main directories that will be required for 
# restoring the Allstar BBB setup.
# 
#  - use compress tar
#  - use devmon to automount the usb, and the script to detect the device
#  - create tar file (options to exclude)
#  - before backup, save system information, system, mac, basic config

# Restore
#   - use devmon to mount usb device
#   - script to look at a specific directory and list the backups.
#   - extract the save system information and verify with user. see below.
#   - When restoring, check for the MAC address. If the mac address is different,
#     then prompt "Detected a Different BBB system backup, do you still want to
#     restore, no, continue..

 
# Program Variables.

BACKUP_INFO_FILE=/tmp/.backup_info

# Date code
DATE=$(date '+%F-%H%M')

# name for tar file
HOSTNAME=$(hostname)
BACKUPNAME="${HOSTNAME}_${DATE}.tgz"

# Make sure we are user root
if [ "$(/usr/bin/whoami)" != "root" ] ; then
  echo "${0##*/} must be run as user \"root\"!"
  exit 1
fi

# Description of program
clear
cat << _EOF
   +=================================================+
   |  This script backs up your node information and |
   |  files which are likely to change and are not   |
   |  included in hamvoip updates. Users can change  |
   |  the included files and directories in the      |
   |  /usr/local/etc/backup.conf file. Backups   |
   |  are to a standard USB stick with vFAT, exFAT,  |
   |  ntfs, or Linux formatting or if a stick is not |
   |  available to the '/' top directory where you   |
   |  can copy to another system or medium.          |
   +=================================================+

_EOF

while true; do
    read -p "Would you like to continue? [y/n] - " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) echo -e "\nNo Backup made\n"; exit;;
      * ) echo -e "\nPlease answer [y]es or [n]o";;
    esac
done
echo
while true; do
    read -p "Would you like to backup to a [U]sb stick or [F]ile or [E]xit? - " ans
    case $ans in
        [Uu]* ) USB=1; break;;
        [Ff]* ) USB=0; break;;
        [Ee]* ) echo -e "\nNo Backup made\n"; exit;;
        * ) echo -e "\nPlease answer [Usb], [F]ile, or [E]xit - ";;
    esac
done

# User changes to the include list should be made in the
# /usr/local/etc/backup.conf file.

if [ -f /usr/local/etc/backup.conf ] ; then
    # source file contains the exclude and include lists for greater flexiblity
    source /usr/local/etc/backup.conf
    echo -e "\nUsing include definitions from /usr/local/etc/backup.sh\n"
else
    # EXCLUDE needs a dummy value.
    EXCLUDE_LIST="/root/restore"
    INCLUDE_LIST="/root /etc/asterisk /usr/local/etc /var/spool/cron /srv/http/allmon2/allmon.ini.php /srv/http/supermon/allmon.ini /srv/http/supermon/global.inc ${BACKUP_INFO_FILE}"

fi

if [ $USB == 1 ]; then

# check if devmon is running, if not running,  start it
pgrep devmon &> /dev/null || /usr/bin/devmon &> /dev/null &

cat << _EOF

  +=========================================================================+
  | Please insert a vFAT, exFAT, NTFS or Linux formated usb thumb drive for |
  | your backup.                                                            |
  |                                                                         |
  | Press any key when disk has been inserted, or  (Ctl-C) to abort..       |
  |                                                                         |                      +=========================================================================+ 
_EOF

read dummy

echo
echo "Checking for media, please wait..."
sleep 4

# probe USB drives
# get mount point
PREMOUNTPT=$(grep "/dev/sda1" /proc/mounts |grep media | awk '{ print $2 }')

if [ -z "$PREMOUNTPT" ]; then 
    echo -e "\nERROR media not found!\n"
    exit 1
fi

# fix spaces, if any,  in mount point
MOUNTPT=$(printf "%s" "${PREMOUNTPT}" | sed 's/\\040/ /g')

else

MOUNTPT=""

fi

#create the .backup_info file:  hostname, mac address, backup date, and version
echo "BKUP_HOSTNAME=\"${HOSTNAME}\"" > $BACKUP_INFO_FILE
echo "MACADDR=\"$(ip addr show | grep   -A1 "eth0: " | grep "link/ether" | awk '{print $2}')\"" >> $BACKUP_INFO_FILE
echo "BKUP_DATE=\"$(date)\"" >> $BACKUP_INFO_FILE
echo "VERSION=\"$(head -1 /etc/allstar_version)\"" >> $BACKUP_INFO_FILE

# Destnation based upon devmon results

DESTDIR=$MOUNTPT

if [ -z $MOUNTPT ]; then
    echo -e "\nBacking up to '/' directory"
else
    echo -e "\nBacking up to $MOUNTPT..."
fi

echo "Backup Started..."
echo

echo -e  "Executing-\n"
echo " tar zcf "${DESTDIR}/${BACKUPNAME}" --exclude=$EXCLUDE_LIST $INCLUDE_LIST "

tar zvcf "${DESTDIR}/${BACKUPNAME}" --exclude=$EXCLUDE_LIST $INCLUDE_LIST &> /dev/null 

STATUS="$?"

if [ "$STATUS" -eq 0  ]; then
    echo -e "\nBackup Completed.  Backup is located at: ${DESTDIR}/${BACKUPNAME}\n"
else
    echo -e "\nAn error has occured (exit code ${STATUS})\n"
fi

sync; sync

if [ ! -z $MOUNTPT ]; then
    cat << _END 
     +===============================+
     |  OK to remove the usb device. |
     +===============================+

_END
else
    cat << _END
    +=================================================+
    |  To recover your backup in the future place the |
    |  tar backup file in the "/" top directory and   |
    |  use - tar xvzf $BACKUPNAME    |
    |  to recover your files to their original        |
    |  locations.                                     |
    +=================================================+

_END
fi
exit 0


