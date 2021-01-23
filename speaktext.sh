#!/bin/bash

#
# Script to speak letters and numbers from asterisk sounds
# over a radio node using simpleusb
# by Ramon Gonzalez KP4TR 2014
#

#set -xv

ASTERISKSND=/var/lib/asterisk/sounds
LOCALSND=/tmp/randommsg


function speak {
        SPEAKTEXT=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        let SPEAKLEN=$(echo "$SPEAKTEXT" | /usr/bin/wc -m)-1
        COUNTER=0
        rm -f ${LOCALSND}.gsm
        touch ${LOCALSND}.gsm
        while [  $COUNTER -lt $SPEAKLEN ]; do
                let COUNTER=COUNTER+1
                CH=$(echo "$SPEAKTEXT"|cut -c${COUNTER})
                if [[ $CH =~ ^[A-Za-z_]+$ ]]; then
                        cat ${ASTERISKSND}/letters/${CH}.gsm >> ${LOCALSND}.gsm
                fi
                if [[ ${CH} =~ ^-?[0-9]+$ ]]; then
                        cat /var/lib/asterisk/sounds/digits/${CH}.gsm >> ${LOCALSND}.gsm
                fi

                case $CH in
                .) cat ${ASTERISKSND}/letters/dot.gsm >> ${LOCALSND}.gsm;;
                -) cat ${ASTERISKSND}/letters/dash.gsm >> ${LOCALSND}.gsm;;
                =) cat ${ASTERISKSND}/letters/equals.gsm >> ${LOCALSND}.gsm;;
                /) cat ${ASTERISKSND}/letters/slash.gsm >> ${LOCALSND}.gsm;;
                !) cat ${ASTERISKSND}/letters/exclaimation-point.gsm >> ${LOCALSND}.gsm;;
                @) cat ${ASTERISKSND}/letters/at.gsm >> ${LOCALSND}.gsm;;
                $) cat ${ASTERISKSND}/letters/dollar.gsm >> ${LOCALSND}.gsm;;
                *) ;;
                esac
        done
        if [ $2 == "File" ]
		then
			exit	
		else
			asterisk -rx "rpt localplay $2 ${LOCALSND}"
	fi
}

if [ "$1" == "" -o "$2" == "" ];then
        echo "Usage: speaktext.sh \"abc123\" node#"
        exit
fi

speak "$1" $2

