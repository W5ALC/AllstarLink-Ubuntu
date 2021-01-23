#!/bin/bash

# Write program to attached Arduino
# D. Crompton, WA3DSP 1/2019

if [ -z $1 ]
  then
    echo -e "\nNo parameters given\n"
    echo -e "arduino_write <file> [port]\n"
    exit
  else
    FNAME=$1
fi

if [ -z $2 ]
  then
    PORT="/dev/ttyUSB0"
  else
    PORT=$2
fi

# Location of avrdude config file
CONFIG="/etc/avrdude.conf"

echo -e "\nWriting $FNAME to Arduino at port $PORT\n"
echo -e "avrdude -C$CONFIG -patmega328p -carduino -P$PORT -b57600 -D -Uflash:w:$FNAME:i\n"
avrdude -C$CONFIG -patmega328p -carduino -P$PORT -b57600 -D -Uflash:w:$FNAME:i
echo -e "Writing complete\n"
# end of script


