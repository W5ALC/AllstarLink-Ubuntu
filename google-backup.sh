#!/bin/bash
#
# Backup Script for hamvoip Allstar
# to a Google cloud drive.
# The Google drive must be setup
# See the howto at hamvoip.org for directions. 
# 
# 3/2019 WA3DSP
# Copyright (C) 2018 WA3DSP

# ---------------
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
# restoring the Allstar BBB setup to a tar file and then stored on your
# Google cloud drive.
# 
#  - use compress tar
#  - create tar file (options to exclude)
#  - before backup, save system information, system, mac, basic config
 
# Program Variables.

BACKUP_INFO_FILE="/tmp/.backup_info"

# Date code
DATE=$(date '+%F-%H%M')

# name for tar file
HOSTNAME=$(hostname)
BACKUPNAME="${HOSTNAME}_backup_${DATE}.tgz"
LOGDIR="/var/log/asterisk"
RETRIES=10

# Description of program
if [ "$1" == "-h" ]
   then
     clear
cat << _EOF
   +=================================================+
   |  This script backs up your node information and |
   |  files which are likely to change and are not   |
   |  included in hamvoip updates. Users can change  |
   |  the included files and directories in the      |
   |  /usr/local/etc/backup.conf file. Backups       |
   |  are to a pre-configured Google cloud drive.    |
   +=================================================+

_EOF
     exit
fi

# User changes to the include list should be made in the
# /usr/local/etc/backup.conf file.

if [ -f /usr/local/etc/backup.conf ] ; then
    # source file contains the exclude and include lists for greater flexiblity
    source /usr/local/etc/backup.conf
    echo -e "\nUsing include definitions from /usr/local/etc/backup.sh\n"
else
    # EXCLUDE needs a dummy value.
    EXCLUDE_LIST="/root/restore"
    INCLUDE_LIST="/etc/asterisk /usr/local/etc /var/spool/cron /var/www/http/* /var/www/http/supermon/* ${BACKUP_INFO_FILE}"

fi

#create the .backup_info file:  hostname, mac address, backup date, and version
echo "BKUP_HOSTNAME=\"${HOSTNAME}\"" > $BACKUP_INFO_FILE
echo "MACADDR=\"$(ip addr show | grep   -A1 "wlp2s0: " | grep "link/ether" | awk '{print $2}')\"" >> $BACKUP_INFO_FILE
echo "BKUP_DATE=\"$(date)\"" >> $BACKUP_INFO_FILE
echo "VERSION=\"$(head -1 /etc/allstar_version)\"" >> $BACKUP_INFO_FILE

DESTDIR="/tmp"

echo "Backup Started..."
echo

echo -e  "Compressing files -\n"
echo " tar zcf "${DESTDIR}/${BACKUPNAME}" --exclude=$EXCLUDE_LIST $INCLUDE_LIST "

tar zvcf "${DESTDIR}/${BACKUPNAME}" --exclude=$EXCLUDE_LIST $INCLUDE_LIST &> /dev/null 

STATUS="$?"

if [ "$STATUS" -ne 0  ]; then
    echo -e "\n$BACKUPNAME - A tar error has occured (exit code ${STATUS})\n"
    echo -"$BACKUPNAME - A tar error has occured (exit code ${STATUS})" >> ${LOGDIR}/backup_log
    exit
fi

# Write to Google Drive
ERROR=0
while :
do
  echo -e "\nAttempting Upload of ${DESTDIR}/${BACKUPNAME}"
  RESULT=$(/usr/local/bin/gdrive upload ${DESTDIR}/${BACKUPNAME}) > /dev/null 2>&1
  echo $RESULT | grep -q "Error 403:" > /dev/null 2>&1
  if [ $? -eq 1 ]
     then
       echo -e "Success - $RESULT - Retries = $ERROR\n"
       echo -e "Success - $RESULT - Retries = $ERROR\n" >> ${LOGDIR}/backup_log
       break
  fi
  let "ERROR+=1"
  if [ $ERROR -gt $RETRIES ]
     then
       echo "$BACKUPNAME - Retries Exceeded on upload - Backup not completed!"
       echo "$BACKUPNAME - Retries Exceeded on upload - backup not completed!" >> ${LOGDIR}/backup_log
       break
  fi
  sleep 3
done

rm -f ${DESTDIR}/${BACKUPNAME}

exit 0

