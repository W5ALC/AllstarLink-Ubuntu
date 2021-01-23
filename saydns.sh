#!/bin/bash

# saydns.sh
# Interrogate and say the IP address and port of 
# a node as found in the hamvoip dns lookup
#
# D. Crompton WA3DSP 7/2018

# Location of Asterisk sound files
Sfiles="/var/lib/asterisk/sounds"

# Location of additional sound files
#Csound="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/sounds"
Csound="/usr/local/sbin/sounds"

# Location of output file to play
Outfile="/tmp/tmpout" 

if [ -z $1 ]
  then
    echo -e "\n *No Lookup Node Number Given*\n"
    echo -e " Usage: saydns.sh <node-to-lookup> <node-to-play-sound>"
    echo -e " If node to play sound is not given then\c"
    echo -e " the first node on the server is used.\n\n"
    exit
fi

if [ -z $2 ]
 then
   PlayNode=$NODE1
else
   PlayNode=$2
fi

res=`dns-query $1`

echo $res

if [[ "$res" == *-* ]]
   then
     echo "Node $1 is not found"
     # form gsm file
     cat $Sfiles/silence/2.gsm > $Outfile.gsm
     /usr/local/sbin/speaktext.sh $1 "File"
     cat $Csound/node.gsm /tmp/randommsg.gsm $Sfiles/num-not-in-db.gsm $Sfiles/silence/1.gsm >> $Outfile.gsm
else

     
     IP=`echo $res | awk -F'[@|:)]' '{print $3}'`
     PORT=`echo $res | awk -F'[:|/)]' '{print $3}'`

     echo "Node $1 is at IP address $IP and IAX port $PORT"
     # form gsm file
     cat $Sfiles/silence/2.gsm > $Outfile.gsm	
     /usr/local/sbin/speaktext.sh $1 "File"
     cat $Csound/node.gsm /tmp/randommsg.gsm $Sfiles/is-at.gsm $Sfiles/address.gsm >> $Outfile.gsm   
     /usr/local/sbin/speaktext.sh $IP "File"
     cat /tmp/randommsg.gsm $Sfiles/port.gsm >> $Outfile.gsm 
     /usr/local/sbin/speaktext.sh $PORT "File"
     cat /tmp/randommsg.gsm $Sfiles/silence/1.gsm >> $Outfile.gsm
     > /tmp/randommsg.txt
fi

echo "Playing on node - $PlayNode"
/usr/bin/asterisk -rx "rpt localplay $PlayNode $Outfile"

