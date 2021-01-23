# !/bin/bash

# bcd_control_usb.sh
# Script to control BCD lines to USB FOB
# Typically used to channel steer
# Call with Decimal Digit 1-16 to control
# Assumes using CM119x - controls up to 4 bits
# Default is 4 bits and GPIO mapping 1,2,4,5
# Change this number of bits and mapping below
# D. Crompton, WA3DSP 1/2018
#  Update to add last_channel - 3/2018

######################
# USER CONFIGURATION #
######################

# Initialize simpleusb.conf lines
# To use USB FOB GPIO lines must be initialized 
# in the simpleusb.conf file in the stanza
# for the USB device you are using.
# 
# NOTE - THESE NEXT FOUR LINES ARE 
# PLACED IN simpleusb.conf NOT HERE!
# Initialize only the lines you are
# using. Change the gpio number to 
# match the lines used. These need
# to match the bit map below. Bits
# are initialized to outputs 0 state.
#
# gpio1 = out0
# gpio2 = out0
# gpio4 = out0
# gpio5 = out0

# Number of bits to process (1-4)

bits=4

# Map Bit order 1,2,4,8 to GPIO bit
# Note GPIO3 is PTT - do NOT use
# Other bits may be reserved - CHECK!
# Change only the equal value to the
# actual GPIO bit.

bit1=1
bit2=2
bit4=4
bit8=5

# Invert bits
# Useful if radio requires it or
# interface inverts - 0=no, 1=yes

invert_bits=0

# Audibly say channel number - 0=no, 1=yes

say_channel=1

# Save channel to a file - 0=no 1=yes

save_channel=1

#############################
# END OF USER CONFIGURATION #
#############################

 . /usr/local/etc/allstar.env

if [ -z $1 ] 
 then
   echo -e "\nBCD output to USB FOB GPIO\n"
   echo -e " Ex: bcd_control_usb_fob.sh <channel 1-16> <node>\n"
   echo -e "  Node assumes first node number if not given\n"
   echo -e " Edit script for number of bits, inversion, bit mapping, and voice response\n"
   exit 0
fi

if [ -z $2 ]
 then
   # Use $NODE1
   NODE=$NODE1
 else
   NODE=$2
fi

vpath="/var/lib/asterisk/sounds"

# Assign commands for each bit 

ASTcommand="/bin/asterisk -rx \"rpt cmd $NODE cop 61 " 
BCD1=$ASTcommand"GPIO$bit1="
BCD2=$ASTcommand"GPIO$bit2="
BCD4=$ASTcommand"GPIO$bit4="
BCD8=$ASTcommand"GPIO$bit8="

#echo "$BCD1 $BCD2 $BCD4 $BCD8"

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

if (( invert_bits ))
  then
    BCD_data1=$((1-BCD_data1))
    BCD_data2=$((1-BCD_data2))
    BCD_data4=$((1-BCD_data4))
    BCD_data8=$((1-BCD_data8))
fi

# Setup BCD lines

cmd1="$BCD1$BCD_data1\""
cmd2="$BCD2$BCD_data2\""
cmd3="$BCD4$BCD_data4\""
cmd4="$BCD8$BCD_data8\""

if (( say_channel ))
  then
   cat $vpath/silence/2.gsm $vpath/changing.gsm $vpath/to.gsm $vpath/channel.gsm $vpath/digits/$1.gsm > /tmp/set-channel.gsm 
   /usr/bin/asterisk -rx "rpt localplay $NODE /tmp/set-channel"
   sleep 6
   rm -rf /tmp/set-channel.gsm
fi

for i in `seq 1 $bits`;
  do
    tmp="cmd$i"
    echo "Executing - ${!tmp}"
    eval "${!tmp}"
  done    

if (( save_channel ))
  then
    echo $1 > /tmp/last_channel
fi

exit 0

# END of script

