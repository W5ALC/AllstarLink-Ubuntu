#!/bin/bash
#
# Script to connect to Allstar ssh port
# IP addresses from Allstar database
# WA3DSP 2/2015
# ---------------
# Copyright (C) 2015, 2016, 2017 Doug Crompton, WA3DSP
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

NDBASE="/var/lib/asterisk/rpt_extnodes"
Local_File="/etc/asterisk/rpt.conf"
PORT=222

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

if [ -z "$1" ]
  then
    echo -e "\nssh to an Allstar node" 
    echo -e "Usage: allstar_ssh.sh node [port]"
    echo -e "Default port- $PORT\n"
    exit
fi

if [ -n "$2" ]
  then
    PORT=$2
fi


if [ "$1" -lt 2000 ]
   then
      echo -e "\nUsing Local File lookup"
      if grep -q $1 $Local_File;  then
           IP=`grep $1 $Local_File | grep "^[^;]" | grep -oP '(?<=@)[0-9.]+'`
           IAX=`grep $1 $Local_File | grep "^[^;]" | grep -oP '(?<=:)[0-9]+'`
           if [ "$IP" == "" ]
                then
                   IP=$(grep $1 $Local_File | grep "^[^;]" | grep -oP '(?<=@)[aA0-zZ9.]+' | awk -F: '{print $1}')

           fi
           if [ "$IP" == "" ]
                then
                   echo -e "Cannot resolve IP address for node $1\n"
                   exit
           fi
      else
           echo -e "Node not Found\n"
           exit
      fi
elif [ -f $NDBASE ]
    then
      echo -e "\nUsing File Lookup"
      if grep -q $1 $NDBASE;  then 
           IP=`grep $1 $NDBASE |  grep -oP '(?<=@)[0-9.]+'`
           IAX=`grep $1 $NDBASE | grep -oP '(?<=:)[0-9]+'`
      else
           echo -e "Node not Found\n"
           exit
      fi
else      
      echo -e "\nUsing DNS Lookup"
      lookup=`dns-query $1`
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
echo -e "\nNode- $1  IAX port- $IAX   Domain- $DOMAIN"
echo -e "\nConnecting ssh to Allstar node- $1 at IP address- $IP port- $PORT\n"
ssh -o ConnectTimeout=6 root@$IP -p $PORT

