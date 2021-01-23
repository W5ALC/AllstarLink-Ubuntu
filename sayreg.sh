#!/bin/bash

# Say registration status for all nodes on a server
# D. Crompton, WA3DSP 5/2018
#
# sayreg.sh <node>
# If node is not specified it plays on $NODE1
# the first defined node on the server

# sayreg.sh checks for all registered nodes on a server
# and annuciates the status of each, either registered or not.
# This script would typically be call from a DTMF function.

# Location of Asterisk sound files
Sfiles="/var/lib/asterisk/sounds"

# Location of additional sound files
#Csound="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/sounds"
Csound="/usr/local/sbin/sounds"

# Location of output file to play
Outfile="/tmp/tmpout" 

if [ -z $1 ]
 then
   PlayNode=$NODE1
else
   PlayNode=$1
fi

Registrations=$(/bin/asterisk -rx "iax2 show registry" | tail -n +2)

IFS=$'\n'

if [ -z "$Registrations" ]
  then
    echo "No Registrations on this server"
    /usr/bin/asterisk -rx "rpt localplay $PlayNode $Csound/no-nodes-registered"	
    exit
fi

echo
> /tmp/randommsg.gsm
cat $Sfiles/silence/2.gsm > $Outfile.gsm
for i in $Registrations
do
# Node = $3, Ip address = $4, Registration status= $6
   nodenum=`echo $i | awk '{print $3}'`
   reg=`echo $i | awk '{print $6}'`
#echo "$nodenum - $reg"
   /usr/local/sbin/speaktext.sh $nodenum "File"
   case "$reg" in
        Registered)
	    echo "$nodenum Registered"
	    cat $Csound/node.gsm /tmp/randommsg.gsm $Csound/is-registered.gsm >> $Outfile.gsm	
            ;;

	Rejected)
	    echo "$nodenum Rejected"
	    cat $Csound/node.gsm /tmp/randommsg.gsm $Csound/is-rejected.gsm >> $Outfile.gsm	
	    ;;

# Additional Status' could be added but would require sound files

        *)
	    echo "$nodenum not Registered"
	    cat $Csound/node.gsm /tmp/randommsg.gsm $Csound/is-not-registered.gsm >> $Outfile.gsm
	    ;;
   esac
cat $Sfiles/silence/1.gsm >> $Outfile.gsm
> /tmp/randommsg.gsm
done
/usr/bin/asterisk -rx "rpt localplay $PlayNode $Outfile"

