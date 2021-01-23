#!/bin/bash
# updated to use hamvoip.org for search - WA3DSP 8/2016
# updated to use public-ip-address.gsm - KB4FXC 9/29/2016

if [ -z "$1" ]
  then
    echo "No node number supplied - saypublicip.sh <node> "
    exit 1
fi

ip=`curl -s http://myip.hamvoip.org/ 2>&1`

#cat /var/lib/asterisk/sounds/letters/i.gsm /var/lib/asterisk/sounds/letters/p.gsm /var/lib/asterisk/sounds/address.gsm > /tmp/ip.gsm

asterisk -rx "rpt localplay $1 /var/lib/asterisk/sounds/public-ip-address"
sleep 1
/usr/local/sbin/speaktext.sh $ip $1

