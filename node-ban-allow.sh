#!/bin/bash

# D. Crompton, WA3DSP 
# Copyright 10/2017
#

function Info {
clear
cat << EOF

                   **** Block/Ban nodes  ****

   This script can be used to temporarily or permanently block or
   allow remote nodes to connect to your node. Commonly called a 
   blacklist or whitelist. Only one list can be in effect but both
   could be defined. You can either specify a list to allow (whitelist)
   or ban (blacklist). The blacklist is useful when there is an issue
   with a node that is causing problems at your end. This could be a
   node that has some technical issue that is keying or hanging up your
   node or perhaps someone who is not abiding by FCC or your rules.
   You should always try to contact the person you are blocking but in
   some cases that may not be possible. On the other hand a whitelist
   allows you to specify a list of nodes that can connect to your node.
   Only those nodes in the whitelist will be able to connect. In most
   situations you would use the blacklist blocking one or several nodes.
   If the blacklist is empty and active all nodes can connect, if the
   whitelist is empty and active no nodes can connect.

   The database name is either "whitelist" or "blacklist" You MUST
   configure your extension.conf and iax.conf files as described at
   this URL in order for this to work.
   
   http://wiki.allstarlink.org/wiki/Blacklist_or_whitelist 
   
EOF
while true; do
read -p "Do you wish to continue? [Y,N] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo -e "\nNo Change made\n"; exit;;
        * ) echo "Please answer [y]es or [n]o";;
    esac
done
}

function doDbase {
/usr/sbin/asterisk -rx "database $Cmd"
}

function listbans { 
echo -e "\nCurrent Nodes in the ban list"
echo "----------------------------"
Cmd="show blacklist"
doDbase
echo
Cmd="show whitelist"
doDbase
echo -e "\nCurrent Nodes in the Allow list"
echo "-------------------------------"
echo 
}

function testban {
if  grep -qr "\bcontext=blacklist\b" /etc/asterisk/iax.conf
   then
     Ban="using the blacklist"
     elif grep -qr "^\bcontext=whitelist\b" /etc/asterisk/iax.conf
       then
         Ban="using the whitelist"
     else
         Ban="using no black or whitelist"
fi
echo -e "Currently $Ban in iax.conf\n"
}

function addban {
read -p "Enter Node number to add to nodeban list - " node
read -p "Enter a comment or blank for this entry - " Comment
if [ -z "$Comment" ]; then 
	if [ "$Dbname" = "blacklist" ]; then
		Comment="node-$node banned"
	else
		Comment="node-$node allowed"
	fi
fi
Cmd="put $Dbname $node \"$Comment\""
doDbase
echo -e "\nAdded node - $node to nodeban list\n"
}

function delban {
read -p "Enter Node number to delete from nodeban list - " node
Cmd="del $Dbname $node"
doDbase
echo -e "\nDeleted node - $node from nodeban list\n" 
}


Info
listbans
testban

while true; do
while true; do
read -p "Do you want to modify a [W]hitelist, [B]lacklist, [Q]uit - " ans
    case $ans in
       [Ww]* ) Dbname="whitelist"; break;;
       [Bb]* ) Dbname="blacklist"; break;;
       [Qq]* ) echo -e "\n"; exit;;
	* ) echo "Please enter [W,B,Q]";;
    esac
done
echo
while true; do
read -p "Modifying $Dbname - [D]elete, [A]dd [S]how] [Q]uit? - " ans
    case $ans in
        [Dd]* ) delban;;
        [Aa]* ) addban;;
	[Ss]* ) listbans;;
        [Qq]* ) echo -e "\n"; break ;;
        * ) echo "Please enter [D,A,S,Q]";;
    esac
done
done

