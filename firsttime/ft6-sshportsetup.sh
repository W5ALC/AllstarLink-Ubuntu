#!/bin/bash
#
# Modified 2016/09/29 by David, KB4FXC
#
# sshportsetup.sh
#    Sets up ssh port setting
# Modified to include dialog menus, 2016.04.07 W0ANM
#
# $Id: sshportsetup.sh 26 2016-04-11 13:50:22Z w0anm $
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
#MENUFT%060%Change the Secure Shell (SSH) port

SSHSERVER_CONFIG=/etc/ssh/sshd_config

# get current ssh port value
DEFSSHPORT=$(grep "^Port" $SSHSERVER_CONFIG | awk '{print $2}')

SSH_TEXT=$(cat << _EOF

***** ssh Port setup *****

This setup script allows you to select the Openssh port setting 
for the built in ssh server on your node. 

Currently, the port value is: $DEFSSHPORT.

Do you want to change your ssh port configuration for asterisk?
_EOF
)


$SOFF
if ($D --title "SSH Setup" --defaultno --yesno "$SSH_TEXT" 20 70) then
	#yes
	ANSWER=y
else
	#no
	ANSWER=n
	$SON
	exit
fi

# prompt, test, and change port
PORTOK=false
 while  [ "$PORTOK" = "false" ] ; do
	$SON
    ANS=$($D --title "SSH Setup" --inputbox "Enter the port number for ssh server:" 8 70 "$DEFSSHPORT" 3>&1 1>&2 2>&3)

    # test, if null, use default else check answer
    if [ -z "${ANS}" ] ; then
        ANS=$DEFSSHPORT
        break
    elif  [[ ! ${ANS} =~ ^[0-9]+$ ]] ; then
	$SOFF
        $D --title "SSH Port Error" --msgbox "Password must be a numeric value." 6 70
        PORTOK=false
    else
        PORTOK=true
    fi
done

SSHPORT=$ANS

PORTVAL=$(grep ^Port $SSHSERVER_CONFIG)

# Change the Port value of /etc/ssh/sshd_config
# echo "sed 's/^${PORTVAL}/Port ${SSHPORT}/g' "$SSHSERVER_CONFIG""
sed "s/^${PORTVAL}/Port ${SSHPORT}/g" "$SSHSERVER_CONFIG" > /tmp/sed_tmp

mv /tmp/sed_tmp "$SSHSERVER_CONFIG"

$SOFF
$D --title "SSH Configuration Completed" --msgbox "SSH Configuration Completed." 6 70 

$SON
exit
