#!/bin/bash

# Display registration status for all nodes on a server
# D. Crompton, WA3DSP 10/2017
#
# WA3DSP Modified 8/2018 to accompdate new registration system. 

Registrations=$(/bin/asterisk -rx "iax2 show registry" | tail -n +2)

IFS=$'\n'
echo
for i in $Registrations
do
Server_IP_port=`echo $i | awk '{print $1}'`
Server_IP=`echo $Server_IP_port | sed 's/:.*//'`
Server_PORT=`echo $Server_IP_port | cut -d ":" -f2`
Perceived_IP_port=`echo $i | awk '{print $4}'`
if [ ! $Perceived_IP_port == "<Unregistered>" ]
 then
  IP=`echo $Perceived_IP_port | sed 's/:.*//'` 
  PORT=`echo $Perceived_IP_port | cut -d ":" -f2`
fi
NODE=`echo $i | awk '{print $3}'`
TMP=`echo $i | awk '{printf ("%s %s %s",$6,$7,$8)}' | sed -e 's/[[:space:]]*$//'`
REGISTERED=$(echo -n \"$TMP\")

Server_DOMAIN=`dig +short -x $Server_IP`

echo  "Node - $NODE at IP address- $IP, Port- $PORT is $REGISTERED at Server"
echo "IP- $Server_IP ("$Server_DOMAIN"), Port- $Server_PORT"

  if [ -e /usr/local/sbin/dns-query ]
    then
	j=$(awk '{print $3}' <<< $i| sed 's/#.*//' | sed 's/.*\///')
	echo -e "\n DNS lookup returns - \c"
	dns-query $j
  fi
  echo
done

