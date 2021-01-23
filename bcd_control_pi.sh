# !/bin/bash

# bcd_control.sh
# Script to ouput BCD on RPi2/3 GPIO
# Call with Decimal Digit 1-16 to control
# Use 'gpio readall' to verify bits
# D. Crompton, WA3DSP 1/2016
# Updated - 1/2018
# Added last_channel save and fixed a bug 3/2018

##################################
# CAUTION!!! Pi GPIO is 3V logic #
# DO NOT APPLY MORE VOLTAGE !!!  #
##################################

######################
# USER CONFIGURATION #
######################

# Number of bits

bits=4

# Assign bits to use on Pi. Run 'gpio readall'
# and use the wPi column to identify bits and
# pin numbers
#

BCD1=21 # Pin 29
BCD2=22 # Pin 31
BCD4=23 # Pin 33
BCD8=24 # Pin 35

# Invert bits
# Useful if radio requires it or
# interface inverts - 0=no, 1=yes

invert_bits=0

# Use Strobe bit - 0=no, 1=yes

Use_Strobe=0

BCD_STROBE=25 # Pin 37

# Say channel change - 0=no, 1=yes
# Sent to first node number ($NODE1)
# Unless second parameter set to node
# Node must be on same server

say_channel=1

# Save channel to a file - 0=no 1=yes

save_channel=1

##########################
# END USER CONFIGURATION #
##########################

 . /usr/local/etc/allstar.env

vpath="/var/lib/asterisk/sounds"

if [ -z $1 ]
 then
   echo -e "\nBCD Output using Pi GPIO\n"
   echo -e "  EX: bcd_control_pi <Channel  1-16> <node>\n"
   echo -e "   Node assumes first node number if not given\n" 
   echo -e " Edit script for number of bits, inversion, strobe, bit mapping, and voice\n"
   exit 0
fi

if [ -z $2 ]
 then
   # Use $NODE1
   NODE=$NODE1
 else
   NODE=$2
fi

echo -n "Entered "

case "$1" in

  1) echo "Channel 1"
     BCD_data1=1
     BCD_data2=0
     BCD_data4=0
     BCD_data8=0
     ;;

  2) echo "Channel 2"
     BCD_data1=0
     BCD_data2=1
     BCD_data4=0
     BCD_data8=0
     ;;

  3) echo "Channel 3"
     BCD_data1=1
     BCD_data2=1
     BCD_data4=0
     BCD_data8=0
     ;;


  4) echo "Channel 4"
     BCD_data1=0
     BCD_data2=0
     BCD_data4=1
     BCD_data8=0
     ;;

  5) echo "Channel 5"
     BCD_data1=1
     BCD_data2=0
     BCD_data4=1
     BCD_data8=0
     ;;

  6) echo "channel 6"
     BCD_data1=0
     BCD_data2=1
     BCD_data4=1
     BCD_data8=0
     ;;

  7) echo "Channel 7"
     BCD_data1=1
     BCD_data2=1
     BCD_data4=1
     BCD_data8=0
     ;;

  8) echo "Channel 8"
     BCD_data1=0
     BCD_data2=0
     BCD_data4=0
     BCD_data8=1
     ;;

  9) echo "Channel 9"
     BCD_data1=1
     BCD_data2=0
     BCD_data4=0
     BCD_data8=1
     ;;

 10) echo "Channel 10"
     BCD_data1=0
     BCD_data2=1
     BCD_data4=0
     BCD_data8=1
     ;;

 11) echo "Channel 11"
     BCD_data1=1
     BCD_data2=1
     BCD_data4=0
     BCD_data8=1
     ;;

 12) echo "Channel 12"
     BCD_data1=0
     BCD_data2=0
     BCD_data4=1
     BCD_data8=1
     ;;

 13) echo "channel 13"
     BCD_data1=1
     BCD_data2=0
     BCD_data4=1
     BCD_data8=1
     ;;

 14) echo "Channel 14"
     BCD_data1=0
     BCD_data2=1
     BCD_data4=1
     BCD_data8=1
     ;;

 15) echo "Channel 15"
     BCD_data1=1
     BCD_data2=1
     BCD_data4=1
     BCD_data8=1
     ;;

 16) echo "channel 16"
     BCD_data1=1
     BCD_data2=1
     BCD_data4=1
     BCD_data8=1
     ;;
esac

# Initialize lines

cmd1="$BCD1"
cmd2="$BCD2"
cmd3="$BCD4"
cmd4="$BCD8"

for i in `seq 1 $bits`;
  do
    tmp="cmd$i"
    echo "Initializing ${!tmp}"
    cmd="gpio mode ${!tmp} out"
    $cmd
 done

if (( use_strobe )) 
  then
    gpio mode $BCD_STROBE out
    gpio write $BCD_STROBE 0
fi

if (( invert_bits ))
  then
    BCD_data1=$((1-BCD_data1))
    BCD_data2=$((1-BCD_data2))
    BCD_data4=$((1-BCD_data4))
    BCD_data8=$((1-BCD_data8))
fi

if (( say_channel ))
  then
   cat $vpath/silence/2.gsm $vpath/changing.gsm $vpath/to.gsm $vpath/channel.gsm $vpath/digits/$1.gsm > /tmp/set-channel.gsm 
   /usr/bin/asterisk -rx "rpt localplay $NODE /tmp/set-channel"
   sleep 6
   rm -rf /tmp/set-channel.gsm
fi

# Setup BCD lines

cmd1="$BCD1 $BCD_data1"
cmd2="$BCD2 $BCD_data2"
cmd3="$BCD4 $BCD_data4"
cmd4="$BCD8 $BCD_data8"

for i in `seq 1 $bits`;
  do
    tmp="cmd$i"
    echo "Executing - gpio write ${!tmp}"
    cmd="gpio write ${!tmp}"
    $cmd
  done

if (( use_strobe ))
  then
# Lower strobe for 100 ms
    gpio toggle $BCD_STROBE
    sleep .1
    gpio toggle $BCD_STROBE
fi

if (( save_channel ))
  then
    echo $1 > /tmp/last_channel
fi

echo "Channel $1 written to BCD - $BCD_data8$BCD_data4$BCD_data2$BCD_data1"

exit 0

# END of script

