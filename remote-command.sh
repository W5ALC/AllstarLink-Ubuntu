#!/bin/bash

# Script to connect and send remote command to Allstar ssh port
# IP addresses from Allstar database, hamvoip database, local file

# ---------------
# Copyright (C) 2019 Doug Crompton, WA3DSP
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

# This script supplied with an Allstar node number will connect ssh
# using either local lookup in rpt.conf if private IP or in the node
# file - /tmp/rpt_extnodes if it exists. If not it does a dns-query
# for the address using the hamvoip node database.


# 10/12/17 Added support for DNS lookup if file method not available
# 11/18/17 Added local file lookup if private domain
#
# 11/11/18 Added check for local vs. public IP and Commented lines
#          in rpt.conf
#
# 2/19/22019 Added ability to lookup local private domain names
#            as well as IP addresses
#
# Command Syntax

# remote-command.sh <node> <command> <port>
# Port defaults to 222

# Command Examples
# remote-command.sh 40000 *81
# remote-command.sh 40000 *340001
# remote-command.sh 40000 *76
# remote-command.sh 40000 *140001 223
# remote-command.sh 1500 *81

# Send remote ssh command automatically

# Function help
remote_help() {
cat <<EOF

           Remote Command via SSH
           ----------------------

  This script looks up the IP address for the
  given node and sends the given command to that
  node on port 222 unless a third port parameter
  is given. The IP address must be in the Allstar
  or hamvoip registry or defined as a local sddress
  in the [nodes] stanza of rpt.conf. The command
  is prefixed by "rpt fun node" The login password
  must be defined in the /root/pname file or a key
  setup for login.

  Command Examples (default port 222)

    remote-command.sh 40000 *81
    remote-command.sh 40000 *340001
    remote-command.sh 40000 *76
    remote-command.sh 40000 *140001 223
    remote-command.sh 1500 *81

EOF
}

if [ -z $1 ]
  then
   remote_help
   echo -e "\nNo remote node number given\n"
   exit
  else
   node=$1
fi

if [ -z "$2" ]
  then
   echo -e "\nNo remote command given\n"
   exit
  else
   command=$2
fi

if [ -z "$3" ]
  then
    PORT="22"
  else
    PORT=$3
fi

# This is the command to be executed
full_command="\"rpt fun $node $command\""

NDBASE="/var/lib/asterisk/rpt_extnodes"
Local_File="/etc/asterisk/rpt.conf"

# Function - test for local IP
test_local() {
# Function to check if local IP
# 10.0..0.0 - 10.255.255.255
# 172.16.0.0 - 172.31.255.255
# 192.168.0.0 - 192.168.255.255
#
ip1=`echo "$IP" | awk -F. '{print $1}'`
ip2=`echo "$IP" | awk -F. '{print $2}'`
ip3=`echo "$IP" | awk -F. '{print $3}'`
ip4=`echo "$IP" | awk -F. '{print $4}'`

if ( [ $ip1 = 10 ] ) || ( [ $ip1 = 192 ] && [ $ip2 = 168 ] ) || ( [ $ip1 = 172 ] && [ $ip2 -gt 15 ] && [ $ip2 -lt 32 ] )
  then 
#   echo "IP address local"
    LocalIP=1
  else
    LocalIP=0
fi
}

# Function get the IP address
get_ip() {

if [ "$node" -lt 2000 ]
   then
      echo -e "\nUsing Local File lookup"
      if grep -q $node $Local_File;  then
           IP=$(grep $node $Local_File | grep "^[^;]" | grep -oP '(?<=@)[0-9.]+')
           IAX=$(grep $node $Local_File | grep "^[^;]" | grep -oP '(?<=:)[0-9]+')

	   if [ "$IP" == "" ]
		then                
	           IP=$(grep $node $Local_File | grep "^[^;]" | grep -oP '(?<=@)[aA0-zZ9.]+' | awk -F: '{print $1}')
	   fi
	   if [ "$IP" == "" ]
		then
		   echo -e "Cannot resolve IP address for node $node\n"
		   exit
	   fi	
      else
           echo -e "Node not Found\n"
           exit
      fi

elif [ -f $NDBASE ]
    then
      echo -e "\nUsing File Lookup"
      if grep -q $node $NDBASE;  then 
           IP=`grep $node $NDBASE |  grep -oP '(?<=@)[0-9.]+'`
           IAX=`grep $node $NDBASE | grep -oP '(?<=:)[0-9]+'`
      else
           echo -e "Node not Found\n"
           exit
      fi
else      
      echo -e "\nUsing DNS Lookup"
      lookup=`dns-query $node`
      if [[ $lookup == "-ER"* ]]; then
          echo -e "Node not Found\n"
          exit
      fi
      IP=`echo $lookup | grep -oP '(?<=@)[0-9.]+'`
      IAX=`echo $lookup | grep -oP '(?<=:)[0-9]+'`
fi

test_local
if [ $LocalIP = 0 ]
  then
     DOMAIN=`dig +short -x $IP`
  else
     DOMAIN=""
fi

if [ "$DOMAIN" = "" ]
   then
      DOMAIN="Non Public Domain"
fi

}

get_ip
echo "Node - $node / IP = $IP / Port = $PORT / Command - $full_command"

# The -f specifies where the password for this login is located
# This file must be protected or use protected keys instead.
# If you use passwords make them secure = 8-12 alpha, digit, special char.

ssh allstar@$IP -p $PORT "asterisk -rx $full_command"

