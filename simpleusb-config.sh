#!/bin/bash
#
# Asterisk Simple USB Configuration script
#
# Modified 2016/09/29 David McGough, KB4FXC
# Modified 2017/01/09 David McGough, KB4FXC
#
# $Id: simpleusb-config.sh 39 2016-04-14 09:52:47Z w0anm $
#
# ---------------
# Copyright (C) 2015, 2016 Christopher Kovacs, W0ANM
# Copyright (C) 2016, 2017 David McGough, KB4FXC
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
#

# modifies the /etc/asterisk/simpleusb.conf file based upon pre-defined radio
# definitions.  

export SON="setterm --term linux --background blue --foreground white --clear all --cursor on"
export SOFF="setterm --term linux --background blue --foreground white --clear all --cursor off"
export D="dialog --clear "

#Variables:
CURRENT_SETTINGS=/usr/local/etc/cur_simple_usb.conf
SIMPLE_USB_CONF=/etc/asterisk/simpleusb.conf
SIMPLE_TUNE_USB_CONF=/etc/asterisk/simpleusb_tune_usb.conf
TMP_SETTINGS=/tmp/tmp_settings
RADIODB=/usr/local/etc/radio.db
DBTMP=/tmp/db_tmp
DATE=`date +%Y.%m.%d.\%H\%M`

# cleand-up
rm -f $DBTMP $TMP_SETTINGS


###################################################
# Introduction
$SOFF
if (! $D --title "Simple USB Configuration" --yesno \
"This script will create the configuration file for the simple
usb device.

During each setting, you will see the currently defined setting
followed by a description of the values.  You will be prompted
with a simple yes or no question with the previously selected
value indicated as shaded value (default).

The default selection is based upon either the previous selected
value or the selected radio information.

NOTE, you can run this script as many times as required. If 
it is run for the first time, you will be prompted for a radio 
selection which will load its default settings. Please review 
these settings when you are prompted and change if necessary.

Do you wish to continue? " 22 75 ) then

    #no
	setterm --reset
    exit 0
fi

# Make a backup of the existing configuration file:
cp -p ${SIMPLE_USB_CONF} ${SIMPLE_USB_CONF}_${DATE}

###################################################
# Selection of data
# check if current setting file is available, if NOT, prompt - defaults or pick from radio DB.
if [ ! -f "$CURRENT_SETTINGS" ] ; then

    # strip out comments 
    awk '{ print $1 }' $RADIODB | grep -v ^\; | grep -v '^$' > $DBTMP

    # get Radio Type this will return a list of radio types
    RADIO_TYPE=$(awk 'BEGIN { FS = "[" } { print $2 }' $DBTMP | sed 's/]/ /g' | awk '{ print $1}' | grep -v '^$' | grep -v '_end')

    ## echo "Radio Types= $RADIO_TYPE"

    index=1
rm -f /tmp/dialog_tmp
    # input select, check for number and range, if invalid,re-prompt
    while true ; do
        clear
        echo "--------------------------------------------------------------------"

        for radio in $RADIO_TYPE; do
            echo "$radio"  >> /tmp/dialog_tmp
            RAD[$index]=$radio
            index=$((index+1))
            echo
        done

        radiolist=$(cat /tmp/dialog_tmp)
        n=1

        for item in ${radiolist[@]}
        do
           menuitems="$menuitems $n ${item}"
           let n+=1
        done

		$SOFF
        OPTION=$($D --title "Radio Selection" --menu \
          "Choose one of the following or Cancel to exit. Choose 'default' if radio is not listed:" \
          20 50 10 $menuitems 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            ANS=$OPTION
        else
		setterm --reset
            exit
        fi

# if [ $? -gt 0 ]; then
#     rm -f /tmp/$$
#     clear
#     echo "Interrupted"
#     exit 0
# fi
# selection=${radiolist[$(cat /tmp/$$)]}
# echo "You selected $selection"

#        echo "If radio type is not shown above, select 'default'"
#        echo "--------------------------------------------------------------------"
#        echo -n  "Enter number from above to select radio type: "
#        read -e ANS

        re='^[0-9]+$'
        if ! [[ $ANS =~ $re ]] ; then
            echo
            echo "Error, not a valid number..."
            sleep 2
            index=0
        elif [ $ANS -gt $(($index-1)) ] ; then
            echo
            echo "Error, not a valid range..."
            sleep 2
            index=0
        else
            break
        fi
    done

    # get description
    DESC=$(sed -n /"${RAD[$ANS]}]"/,/"${RAD[$ANS]}"_end]/p $RADIODB  | grep description)

    # below will strip suffix, not needed
    # DESC=${DESC#description\=}

    # create the source file and read it
    sed -n /"${RAD[$ANS]}"]/,/"${RAD[$ANS]}"_end]/p $RADIODB | awk '{ print $1 }' | grep -v ^\; | grep -v '^$' > $TMP_SETTINGS

    # fix description, by appending to file. This is required to avoid
    # splitting the description entry.
    grep -v "description=" $TMP_SETTINGS > $CURRENT_SETTINGS
    echo $DESC >> $CURRENT_SETTINGS

    # check for valid settings, if you get multiple entries, there is a 
    #syntax error in the radio.db file
    TEST=$(grep eeprom $CURRENT_SETTINGS | wc -l)
    if  [ $TEST != "1" ] ; then
	$SOFF
        $D --title "Error" --msgbox "Syntax Error in $RADIODB. Please review file. Aborting..." 10 70 
        rm -f $CURRENT_SETTINGS
		setterm --reset
        exit 1
    fi

    # strip out brackets
    grep -v  "^\[" $CURRENT_SETTINGS > $TMP_SETTINGS
    
    # read current settings into system
    source $TMP_SETTINGS
else
    # Read from current saved settings file

    # strip out brackets
    grep -v  "^\[" $CURRENT_SETTINGS > $TMP_SETTINGS
    
    # read current settings into system
    source $TMP_SETTINGS
    
fi


if [ -f /tmp/simpleusb.conf ] ; then
    rm -f /tmp/simpleusb.conf
fi

cat << _EOF >> /tmp/simpleusb.conf
; simple usb configration added by simpleusb-config.sh
;  $DATE

[general]

[usb]

; $description


_EOF

#############################################################
# eeprom   (0,1)
if [ "$eeprom" -eq 0 ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi
  #default no
$SOFF
if ($D --title "eeprom Setting" --no-collapse $DEFAULT --yesno \
"eeprom

  eeprom=$eeprom
                    ; 1 = Indicates that an EEPROM internal to the radio
                    ;     adapter and cable is expected.
                    ; 0 = no warning message if no EEPROM found.

Normally, you will select 'No' unless you are using an internal eeprom.
('No' for eeprom=0) or 'Yes' for eeprom=1)

Are you using an eeprom in your URI/radio?" 16 78 ) then
    #yes
    eeprom=1
else
    #no
    eeprom=0
fi

cat << _EOF >> /tmp/simpleusb.conf
eeprom=$eeprom
			; 1 = Indicates that an EEPROM internal to the radio
			;     adapter and cable is expected. 
			; 0 = no warning message if no EEPROM found.

_EOF

#############################################################
# rxboost   (0,1)
if [ "$rxboost" -eq 0 ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi

$SOFF
if ($D --title "Audio Boost Setting" --no-collapse $DEFAULT --yesno \
"Receiver Audio Boost

  rxboost=$rxboost
                        ; Rx Audio Boost
                        ; 0 = 20db attenuator inserted
                        ; 1 = 20db attenuator removed
                        ; Set to 1 for additonal gain if using a low-level
                        ; receiver output.

Answer 'Yes' if you are using a low-level receiver output." 14 78 ) then
    #yes
    rxboost=1
else
    #no
    rxboost=0
fi

cat << _EOF >> /tmp/simpleusb.conf
rxboost=$rxboost
			; Rx Audio Boost
			; 0 = 20db attenuator inserted 
			; 1 = 20db attenuator removed
			; Set to 1 for additonal gain if using a low-level
			; receiver output.

_EOF

#############################################################
# carrierfrom=         (no,usb,usbinvert)
if [ "$carrierfrom" = "no" ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi
$SOFF
if ($D --title "Carrier Detection Setting" --no-collapse $DEFAULT --yesno \
"Carrier Detection

    carrierfrom=$carrierfrom
                        ; Options - no,usb,usbinvert
                        ; no - no carrier detection at all
                        ; usb - via USB radio adapter COR connection
                        ; usbinvert - same as above but inverted polarity.

Normally, you will be using this option. This is the COS (carrier
detection) which indicates that a carrier is present. This signal comes
for the radio to the modified FOB or URI. This supports the option to
invert the detected signal which depends on the radio.

Do you want to use carrier detecton?" 18 78 ) then
    #yes
    if [ "$carrierfrom" = "usb" ] ; then
       DEFAULT="--defaultno"
    else
       DEFAULT=""
    fi
$SOFF
    if ($D  --title "COR Inverted" --no-collapse $DEFAULT --yesno \
    "Does the COR line need to be inverted?" 6 45) then
        #yes
        carrierfrom=usbinvert
    else
        #no
        carrierfrom=usb
    fi
else
    carrierfrom=no

fi

cat << _EOF >> /tmp/simpleusb.conf
carrierfrom=$carrierfrom
			; Options - no,usb,usbinvert 
			; no - no carrier detection at all
			; usb - via USB radio adapter COR connection
			; usbinvert - same as above but inverted polarity.

_EOF


#############################################################
# ctcssfrom=no  (no,usb,usbinvert)
if [ "$ctcssfrom" = "no" ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi

$SOFF
if ($D --title "CTCSS Decoding Setting" --no-collapse $DEFAULT --yesno \
"CTCSS Decoding

    ctcssfrom=$ctcssfrom
                    ; CTCSS Decoder Source
                    ; Options = no,usb,dsp
                    ; no - CTCSS decoding, system will be carrier squelch
                    ; usb - CTCSS decoding using input from USB adapter
                    ; usbinvert - same as above but inverted polarity.

Some radios use the CTCSS signal to indicate that a CTCSS signal is 
preset, like COS, it provides a method of  signal detection and 
indicates that a carrier is present. This signal comes from the radio 
to the modified FOB or URI. This supports the option to invert the 
detected signal which depends on the radio.

Do you want to use CTCSS decoding?" 20 78 ) then
    #yes
    if [ "$ctcssfrom" = "usb" ] ; then
       DEFAULT="--defaultno"
    else
       DEFAULT=""
    fi
$SOFF
    if ($D  --title "CTCSS Inverted" --no-collapse $DEFAULT --yesno \
    "Does the CTCSS decoding line need to be inverted" 10 50) then
        #yes
        ctcssfrom=usbinvert
    else
        #no
        ctcssfrom=usb
    fi
else
    ctcssfrom=no

fi

cat << _EOF >> /tmp/simpleusb.conf
ctcssfrom=$ctcssfrom
			; CTCSS Decoder Source
			; Options = no,usb,dsp
			; no - CTCSS decoding, system will be carrier squelch
			; usb - CTCSS decoding using input from USB adapter 
			; usbinvert - same as above but inverted polarity.

_EOF

#############################################################
# invertptt=0   (0,1)
if [ "$invertptt" -eq 0 ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi
  #default no
$SOFF
if ($D --title "PTT Setting" --no-collapse $DEFAULT --yesno \
"PTT

    invertptt=$invertptt
                ; Invert PTT 0 = ground to transmit, 1 = open to transmit
                ; This is the collector lead of the 2n4401 on the modified
                ; usb sound fob.

Please refer to the howto for the procedure to do this.

Should the PTT be grounded to transmit?" 15 78 ) then
    #yes
    invertptt=1
else
    #no
    invertptt=0
fi

cat << _EOF >> /tmp/simpleusb.conf
invertptt=$invertptt
			; Invert PTT 0 = ground to transmit, 1 = open to
                        ; transmit
 
                        ; This is the collector lead of the 2n4401 on the 
                        ; modified usb sound fob.

_EOF

#############################################################
# plfilters (yes,no)
if [ "$plfilter" = "no" ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi
  #default no
$SOFF
if ($D --title "PL Filter Setting" --no-collapse $DEFAULT --yesno \
"PL Filter

    plfilter=$plfilter
                        ; enable PL filter
                        ; yes, enabled
                        ; no, disabled

**Only use if necessary for your installation**

Some radios require addtional filtering the the PL tones, this will
help attenuate this signal from the receiver.

Should the plfilter be enabled " 18 78 ) then
    #yes
    plfilter=yes
else
    #no
    plfilter=no
fi

cat << _EOF >> /tmp/simpleusb.conf
plfilter=$plfilter
			; enable PL filter
			; yes, enabled
			; no, disabled

_EOF

#############################################################
# deemphasis (yes,no)
if [ "$deemphasis" = "no" ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi
  #default no
$SOFF
if ($D --title "De-emphasis Filter Setting" --no-collapse $DEFAULT --yesno \
"De-emphasis Filter

    deemphasis=$deemphasis
                        ; enable de-emphasis (input from discriminator)
                        ; yes, enabled
                        ; no, disabled

**Only use if necessary for your installation**

Should the De-emphasis Filter be enabled?" 15 78 ) then
    #yes
    deemphasis=yes
else
    #no
    deemphasis=no
fi

cat << _EOF >> /tmp/simpleusb.conf
deemphasis=$deemphasis
			; enable de-emphasis (input from discriminator)
			; yes, enabled
			; no, disabled

_EOF

#############################################################
# preemphasis (yes,no)
if [ "$deemphasis" = "no" ] ; then
   DEFAULT="--defaultno"
else
   DEFAULT=""
fi
  #default no
$SOFF
if ($D --title "Pre-emphasis Filter Setting" --no-collapse $DEFAULT --yesno \
"Pre-emphasis Filter

    preemphasis=$preemphasis
                        ; enable pre-emphasis (output to Tx)
                        ; yes, enabled
                        ; no, disabled

**Only use if necessary for your installation**

Should the Pre-emphasis Filter be enabled?" 15 78 ) then
    #yes
    preemphasis=yes
else
    #no
    preemphasis=no
fi

cat << _EOF >> /tmp/simpleusb.conf
preemphasis=$preemphasis
			; enable pre-emphasis (output to Tx)
			; yes, enabled
			; no, disabled

_EOF


#############################################################
# rxaudiodelay=N Where N is the number of 20ms frames to delay
VALOK=false
while  [ "$VALOK" = "false" ] ; do
$SON
    ANS=$($D --title "RX Audio Delay" --inputbox \
"rxaudiodelay parameter

    rxaudiodelay=$rxaudiodelay
                    ; default value is 0
                    ; rx audio delay for squelch tail elimination.
                    ; Squelch tail delay in 20ms frames. Values range
                    ; from  0 (no delay) to 24 (480ms delay)
                    ; Typical values would range from 5-10 (100-200ms)

Please refer to the documentation prior to changing from the default
value.
 
Enter the value of rxaudiodelay?" 20 78 $rxaudiodelay 3>&1 1>&2 2>&3)

    # convert to in integer value and verify that the range is  
    # between 1 and 999
    if [ -z "${ANS}" ] ; then
        break
    elif  [[ ! ${ANS} =~ ^[0-9]+$ ]] ; then
$SOFF
        $D --title "Value Error" --msgbox "Value must be a numeric value." 10 60
        VALOK=false
    elif  [ ${ANS} -gt 50 ] || [ ${ANS} -lt 0 ] ; then
$SOFF
        $D --title "Range Error" --msgbox "Value must be in the range of 0-50"
        VALOK=false
    else
        VALOK=true
    fi
done

rxaudiodelay=$ANS

cat << _EOF >> /tmp/simpleusb.conf
rxaudiodelay=$rxaudiodelay
			; default value is 0
			; rx audio delay for squelch tail elimination.
			; Squelch tail delay in 20ms frames. Values range
			; from  0 (no delay) to 24 (480ms delay)
			; Typical values would range from 5-10 (100-200ms)


_EOF

# need to check values entered.

cat << _EOF > $CURRENT_SETTINGS
[current]
description="$description"
eeprom=$eeprom
rxboost=$rxboost
carrierfrom=$carrierfrom
ctcssfrom=$ctcssfrom
invertptt=$invertptt
plfilter=$plfilter
deemphasis=$deemphasis
preemphasis=$preemphasis
rxaudiodelay=$rxaudiodelay
[current_end]
_EOF

#adding usb1 entry
cat << _EOF >> /tmp/simpleusb.conf
; Uncomment and configure following lines for second USB node

;[usb1]

;eeprom=0

;rxboost=1
			; 0 = 20db attenuator inserted, 1= 20db attenuator removed
			; Set to 1 for additonal gain if using a low-level
			; receiver output

;carrierfrom=usbinvert
			; no,usb,usbinvert
			; no - no carrier detection at all
			; usb - from the COR line on the modified USB sound fob
			; usbinvert - from the inverted COR line on the
			;  modified USB sound fob

;ctcssfrom=no
			; no,usb,usbinvert
			; no - CTCSS decoding, system will be carrier squelch
			; usb - CTCSS decoding using input from USB FOB
			; usbinvert - from the inverted CTCSS line on the
			; modified USB sound fob

;invertptt=0
			; Invert PTT 0 = ground to transmit, 1 = open to transmit
			; This is the collector lead of the 2n4401 on the modified
			; usb sound fob.
			; please refer to the howto for the procedure to do this.

plfilter=yes
			; enable PL filter


; Only uncomment following two lines if necessary for your installation

;deemphasis=yes
			; enable de-emphasis (input from discriminator)

;preemphasis=yes
			; enable pre-emphasis (output to TX)

;rxaudiodelay=0
                        ; default value is 0
                        ; rx audio delay for squelch tail elimination.
                        ; Squelch tail delay in 20ms frames. Values range
                        ; from  0 (no delay) to 24 (480ms delay)
                        ; Typical values would range from 5-10 (100-200ms)

; EOF
_EOF

mv /tmp/simpleusb.conf $SIMPLE_USB_CONF

######################################
# Audio Levels
$SOFF
if ( $D --title "Audio Level Settings" --defaultno --yesno \
"If you know the audio values for your node setup, you can modify them
now.  If not, please run 'simpleusb-tune-menu' program at the Linux 
prompt to properly set your sound levels.

Do you want to set your audio levels for your node now?" 08 75 ) then
    #yes -- > source the configuration file
    # and prompt
    grep -v "\["  ${SIMPLE_TUNE_USB_CONF} | grep -v ";" > /tmp/simpleusb_tune_usb.conf
    source /tmp/simpleusb_tune_usb.conf
    # make a backup
    cp $SIMPLE_TUNE_USB_CONF ${SIMPLE_TUNE_USB_CONF}_${DATE} 

    #########################################
    # RX Mixer Value (rxmixerset)
    #########################################
    VALOK=false
    while  [ "$VALOK" = "false" ] ; do
		$SON
        ANS=$($D --title "RX Mixer" --nocancel --inputbox \
"RX Mixer Value
    rxmixerset=$rxmixerset

This value sets the Receiver Audio Levels or incoming 
audio levels "from" the node radio.

 
Enter the new value for the RX Mixer Level" 14 60 $rxmixerset  3>&1 1>&2 2>&3)

        # convert to in integer value and verify that the range is  
        # between 1 and 999
        if  [[ ! ${ANS} =~ ^[0-9]+$ ]] ; then
		$SOFF
            $D --title "Value Error" --msgbox "Value must be a numeric value." 6 40
            VALOK=false
        elif  [ ${ANS} -gt 999 ] || [ ${ANS} -lt 0 ] ; then
		$SOFF
            $D --title "Range Error" --msgbox "Value must be in the range of 0-999." 6 40
            VALOK=false
        else
            VALOK=true
        fi
    done

    # make sure that value is set
    rxmixerset=$rxmixerset

    # if null, use default
    if [ -z "$ANS" ] ; then
        rxmixersetnew=$rxmixerset
    else
        rxmixersetnew=$ANS
    fi

    # now use sed to update the value in /etc/asterisk/simpleusb_tune_usb.conf
    sed "s/rxmixerset=${rxmixerset}/rxmixerset=${rxmixersetnew}/g" $SIMPLE_TUNE_USB_CONF > /tmp/simpleusb_tune_usb.conf
    # copy to the correct location
    cp /tmp/simpleusb_tune_usb.conf $SIMPLE_TUNE_USB_CONF

    #########################################
    # TX Mixer A Value (txmixaset)
    #########################################
    VALOK=false
    while  [ "$VALOK" = "false" ] ; do
		$SON
        ANS=$($D --title "TX Mixer A" --nocancel --inputbox \
"TX Mixer A Value
    txmixaset=$txmixaset

This value sets the Transmit Audio Levels or outgoing 
audio on the A output side "to" the node radio.

Enter the new value for the TX Mixer A Level:" 13 60 $txmixaset 3>&1 1>&2 2>&3)
        # convert to in integer value and verify that the range is  
        # between 1 and 999
        if  [[ ! ${ANS} =~ ^[0-9]+$ ]] ; then
		$SOFF
            $D --title "Value Error" --msgbox "Value must be a numeric value." 6 40
            VALOK=false
        elif  [ ${ANS} -gt 999 ] || [ ${ANS} -lt 0 ] ; then
		$SOFF
            $D --title "Range Error" --msgbox "Value must be in the range of 0-999." 6 40
            VALOK=false
        else
            VALOK=true
        fi
    done

    # make sure that value is set
    txmixaset=$txmixaset

    # if null, use default
    if [ -z "$ANS" ] ; then
        txmixasetnew=$txmixaset
    else
        txmixasetnew=$ANS
    fi

    # now use sed to update the value in /etc/asterisk/simpleusb_tune_usb.conf
    sed "s/txmixaset=${txmixaset}/txmixaset=${txmixasetnew}/g" $SIMPLE_TUNE_USB_CONF > /tmp/simpleusb_tune_usb.conf
 # copy to the correct location
    cp /tmp/simpleusb_tune_usb.conf $SIMPLE_TUNE_USB_CONF

    #########################################
    # TX Mixer B Value (txmixbset)
    #########################################
    VALOK=false
    while  [ "$VALOK" = "false" ] ; do
		$SON
        ANS=$($D --title "TX Mixer B" --nocancel --inputbox \
"TX Mixer B Value
    txmixbset=$txmixbset

This value sets the Transmit Audio Levels or outgoing
audio on the A output side "to" the node radio.

Enter the new value for the TX Mixer B Level:" 13 60 $txmixbset 3>&1 1>&2 2>&3)

        # convert to in integer value and verify that the range is  
        # between 1 and 999
        if  [[ ! ${ANS} =~ ^[0-9]+$ ]] ; then
		$SOFF
            $D --title "Value Error" --msgbox "Value must be a numeric value." 6 40
            VALOK=false
        elif  [ ${ANS} -gt 999 ] || [ ${ANS} -lt 0 ] ; then
		$SOFF
            $D --title "Range Error" --msgbox "Value must be in the range of 0-999." 6 40
            VALOK=false
        else
            VALOK=true
        fi
    done

    # make sure that value is set
    txmixbset=$txmixbset

    # if null, use default
    if [ -z "$ANS" ] ; then
        txmixbsetnew=$txmixbset
    else
        txmixbsetnew=$ANS
    fi

    # now use sed to update the value in /etc/asterisk/simpleusb_tune_usb.conf
    sed "s/txmixbset=${txmixbset}/txmixbset=${txmixbsetnew}/g" $SIMPLE_TUNE_USB_CONF > /tmp/simpleusb_tune_usb.conf
    # copy to the correct location
    cp /tmp/simpleusb_tune_usb.conf $SIMPLE_TUNE_USB_CONF

fi # Audio Setup code

# Asterisk Restart and final instructions
		$SOFF
if ( $D --title "Final Instructions" --defaultno --yesno \
"
After any simpleusb.conf changes you should do an Asterisk restart.
This will restart and reload the Asterisk modules. These simpleusb
changes will not take effect until Asterisk is restarted.

If needed, please run "simpleusb-tune-menu" program at the Linux 
prompt to set your sound levels.

Do you want to restart Asterisk to enable selections?" 14 70) then
    #yes
    /usr/local/sbin/astdn.sh
	sleep 1
    /usr/local/sbin/astup.sh

fi

setterm --reset

# end of file
