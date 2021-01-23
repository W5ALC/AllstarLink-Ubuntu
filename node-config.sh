#!/bin/bash
#
# Asterisk Node Configuration
#
# by w0anm
#
# $Id: node-config.sh 39 2016-04-14 09:52:47Z w0anm $

# ---------------
# Copyright (C) 2015, 2016 Christopher Kovacs, W0ANM
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

# create a config file that can be sourced to bring back configuation 
# values for the next run.

export SON="setterm --term linux --background blue --foreground white --clear all --cursor on"
export SOFF="setterm --term linux --background blue --foreground white --clear all --cursor off"
export D="dialog --clear "

# Variables
CONFIGFILE=/usr/local/etc/allstar_node_info.conf
SRCDIR=/usr/local/etc/asterisk_tpl
CONVDIR=/etc/asterisk
SOUNDS=/var/lib/asterisk/sounds
IDFILE=/etc/asterisk/local/node-id
DATE=$(date '+%Y.%m.%d.%H%M')

if [ -f $CONFIGFILE  ] ; then
   source $CONFIGFILE
   UPDATE=yes
else
   UPDATE=no
fi

if [ -f /usr/local/etc/allstar.env ] ; then
    source /usr/local/etc/allstar.env
else
	$SOFF
    $D --title "Error!" --msgbox "Error! Missing Allstar Environment file (/usr/local/etc/allstar.env), Aborting..." 10 60
	setterm --reset
    exit
fi

# change variables in file to there value
ConvertFile () {
  file_input=$1
  file_output=$2
  # echo "file_input=$file_input"
  # echo "file_output=$file_output"

  eval "echo \"$( < $file_input)\"" > $file_output
}


# ckyorn function with defaults

ckyorn () {
    return=0
    if [ "$1" = "y" ] ; then
        def="y"
        sec="n"
    else
        def="n"
        sec="y"
    fi
 
    while [ $return -eq 0 ]
    do
        read -e -p "([$def],$sec): ? " answer
        case "$answer" in
                "" )    # default
                        printf "$def"
                        return=1 ;;
        [Yy])   # yes
                        printf "y"
                        return=1
                        ;;
        [Nn] )   # no
                        printf "n"
                        return=1
                        ;;
                   *)   printf "    ERROR: Please enter y, n or return.  " >&2
                        printf ""
                        return=0 ;;
        esac
    done

}
####################################################
# Start
####################################################

# back backup of old config files
if [ ! -f /etc/asterisk/rpt.conf_orig ] ; then
    cp /etc/asterisk/rpt.conf /etc/asterisk/rpt.conf_orig
    cp /etc/asterisk/iax.conf /etc/asterisk/iax.conf_orig
    cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf_orig
fi
# back backup existing config files
if [ ! -f /etc/asterisk/rpt.conf_${DATE} ] ; then
    cp /etc/asterisk/rpt.conf /etc/asterisk/rpt.conf_${DATE}
    cp /etc/asterisk/iax.conf /etc/asterisk/iax.conf_${DATE}
    cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf_${DATE}
fi

# Added tests for additional templates
# WA3DSP 3/2019

if [ -z $RPT_TEMPLATE_FILE ]
    then
      RPT_TXT="rpt.conf_tpl"
    else  
      RPT_TXT=$RPT_TEMPLATE_FILE
    
fi
if [ -z $IAX_TEMPLATE_FILE ]
    then
       IAX_TXT="iax.conf_tpl"
    else
       IAX_TXT=$IAX_TEMPLATE_FILE
fi
if [ -z $EXTENSIONS_TEMPLATE_FILE ]
    then
       EXTENSIONS_TXT="extensions.conf_tpl"
    else
       EXTENSIONS_TXT=$EXTENSIONS_TEMPLATE_FILE
fi

# Check if template files exist
if [ ! -f "$SRCDIR/$RPT_TXT" ]
    then
       TXT2="$SRCDIR/$RPT_TXT "
fi
if [ ! -f "$SRCDIR/$IAX_TXT" ]
    then
       TXT2="$TXT2 $SRCDIR/$IAX_TXT "
fi
if [ ! -f "$SRCDIR/$EXTENSIONS_TXT" ]
    then
       TXT2="$TXT2 $SRCDIR/$EXTENSIONS_TXT"
fi

if [ "$TXT2" != "" ]
     then
        $SOFF
        $D --msgbox "Missing Template file(s) - $TXT2 - cannot continue with setup." 8 78
        setterm --reset
        exit 0
fi

TXT1="{$RPT_TXT - $IAX_TXT - $EXTENSIONS_TXT}"

remain=$((78-${#TXT1}))
pad=$((remain / 2))
TXT1=$(printf "%*s%s" $pad '' "$TXT1")
   
$SOFF
if (! $D --colors --cr-wrap --title "Introduction" --defaultno --no-collapse --yesno \
"This script configures the Asterisk configuration files based upon 
template files found in /usr/local/etc/asterisk_tpl directory.  The files
that will be changed are: iax.conf, rpt.conf, and  extensions.conf.

While this script is intended for first time configuration of these files,
it can be run at anytime to make changes. BUT, please keep in mind that
every time you execute this script, it uses the template directory files
and NOT the active configurations files to create new active configuration
files. See the setup howto on changing templates for special applications.

If this is a first time configuration, it is safe to continue otherwise
read the above paragraph and understand that any manual changes that you
have made to the active configuration files in the /etc/asterisk directory
will be overwritten. The old files will be renamed extensions.conf_orig, 
iax.conf_orig, and rpt.conf_orig. \Z1\ZbUsing the following template files -\n$TXT1\ZB\Zn 

Do you wish to continue?" 24 78 ) then
    #no
	setterm --reset
    exit 0
fi

return=0
while [ $return -eq 0 ]
do
	$SON
    ANS=$($D --title "Node Number" --nocancel --inputbox "Enter Node Number:"  8 40 "$NODE1" 3>&1 1>&2 2>&3 )
    if [ "$ANS" = "$NODE1" ] ; then
        NODE1=$ANS
           if [ $(expr $NODE1) -gt 1999 ] ; then
               PV_NODE=0
           else
               PV_NODE=1
           fi
         source /usr/local/etc/allstar.env
         break ; # break out of main loop, don't do anything
    fi
    # set new node number
    NODE1=$ANS

	$SOFF
    if ($D --title "Node Number Change" --defaultno --yesno "You have entered a different node number that is currently used in the\nsystem setup.\n\nDo you really want to change your node number? " 10 60 ) then
        #yes
        ANS=y
    else
        ANS=n
    fi

    if [ "$ANS" = "y" ] ; then
	$SOFF
        if ( $D --title "Node Number Type" --defaultno --no-collapse --yesno \
"If you have a node number and password assignment from Allstarlink.org
you should answer 'No' to the next question. If you intend to use Allstar
in a strictly private network such as a repeater link or commercial
use then answer 'Yes'. Private nodes have self assigned node numbers
of less than 2000, are not registered with Allstar and do not require
a password. Private nodes require manual routing in the nodes stanza
of rpt.conf. Most users would answer 'No' to this question.

Is this a private node" 20 78 )  then
        #yes
            NODETYPE=PRIV
        else
            NODETYPE=PUB
        fi
        again=0
        case $NODETYPE in
           PRIV)  # Private node
                  while [ $again -eq 0 ] 
                  do
                   #private, get number
                   if [ $(expr $NODE1) -gt 1999 ] ; then
			$SON
                     NODE1=$($D --title "Node Number Input" --inputbox "Error, private node number must be less than 2000!\n\nRe-enter your private node number or Cancel to abort"  10 60  3>&1 1>&2 2>&3 )
                     # if cancel abort
                     exitstatus=$?
                     if [ $exitstatus != 0 ]; then
	setterm --reset
                          exit
                     fi

                     # test it
                     if [ "$(expr $NODE1)" -gt 1999 ]; then
			$SOFF
			$D --title "Error" --msgbox "Error, private node number must be less than 2000):"  8 60 
                        again=0
                     else
                        again=1
                        PV_NODE=1
                     fi
                   else  # if node number < 2000, then we are good
                     PV_NODE=1
                     #break
                     again=1
                   fi
                 done
                 ;;
           PUB)  # Public Node
                 while [ $again -eq 0 ]
                 do
                     # public, get number
                   if [ "$(expr $NODE1)" -lt 2000 ]; then
			$SON
			NODE1=$($D --title "Error" --inputbox "Error, for public number the node number must be greater than 1999!\n\n Re-enter your public node number or Cancel to abort:"  12 70  3>&1 1>&2 2>&3 )
                     # if cancel - abort
                     exitstatus=$?
                     if [ $exitstatus != 0 ]; then
	setterm --reset
                          exit
                     fi
                     again=0
                   else
                     again=1
                     PV_NODE=0
                   fi
                 done
                 ;;
        esac
        # set to exit out, done
        sed -i "s/^export NODE1=.*/export NODE1=${NODE1}/" /usr/local/etc/allstar.env
        sed -i "s/^export PRIVATE_NODE=.*/export PRIVATE_NODE=${PV_NODE}/" /usr/local/etc/allstar.env
        return=1
    #no
    else
        # if you do not want to change your node, just source and exit out.
        source /usr/local/etc/allstar.env
    fi
       
    #  sed -i "s/^export NODE1=.*/export NODE1=${NODE1}/" /usr/local/etc/allstar.env
    #  sed -i "s/^export PRIVATE_NODE=.*/export PRIVATE_NODE=${PV_NODE}/" /usr/local/etc/allstar.env
    return=1
done

# Station Call
$SON
ANS=$($D --title "Node Station Call" --nocancel --inputbox "Enter Station Call for node:" 8 40 $STNCALL  3>&1 1>&2 2>&3 )

STNCALL="`echo \$ANS | tr '[:lower:]' '[:upper:]'`"

# Report status to stats.allstarlink.org
# description of report status
# if report status is y or update is yes, then default is yes
if [ "$REPORTSTAT" = "y" ] ; then
    # update default
    if [ "$UPDATE" = "yes" ] ; then
       DEFAULT = ""
    else
       DEFAULT = "--defaultno"
    fi
else
    #new install default
    DEFAULT = ""
fi

$SOFF
if ($D --title "Report Status" $DEFAULT --yesno \
"Note that reporting the status of your node is not mandatory but without 
reporting your node will not appear in the allstarlink.org status screen
and others will not know your node exists unless you give them your node
number.  Even if your node does not appear on the status page another
node will be able to connect to you using your node number.  While the 
usual answer is to say yes and report your status some may wish to 
remain private by not advertising their node.

Do you want your node to report status to stats.allstarlink.org " 14 78) then
       # yes
    REPORTSTAT=y
else
    REPORTSTAT=n
fi

# Setup CW or Voice ID
# (update default value for voiceid is no)
if [ "$UPDATE" = "yes" ] ; then
    # update default
    if [ "$VOICEID" = "y" ] ; then
       DEFAULT=""
    else
       DEFAULT="--defaultno"
    fi
else
    #new install default
    DEFAULT="--defaultno"
fi
$SOFF
if ( $D --title "CW ID" $DEFAULT  --yesno \
"Asterisk can use either voice or CW id for FCC identfication.  If 
you select voice id a simple gsm voice ID audio file will be 
generated.  This file is located at '/etc/asterisk/local/' and is
called 'node_id.gsm'.

If you select 'Yes' to voice id, then a voice id will be created.
If you select 'No', then the default CW id will be used.

Do you want to use voice id?" 14 70) then
   #yes
    VOICEID=y
else
    VOICEID=n
fi

# simple voiceid
# create voiceid, if needed via gsm files
if [ "$VOICEID" = "y" ] ; then
    if [ -f "${IDFILE}.gsm" ] ; then
        rm -f ${IDFILE}.gsm
    fi
    # create gsm id file
    #convert to lower case:
    CALL="`echo \$STNCALL | tr '[:upper:]' '[:lower:]'`"
    #CALLID="${CALL}4id"
    CALLID="${CALL}"

    length=${#CALLID}

    for val in `seq 1 $length`
    do
        # extract a character at a time
        charval=`expr substr "$CALLID" $val 1`
        # check to if it's a number or a letter

        re='^[0-9]+$'
        if ! [[ $charval =~ $re ]] ; then
           # letter
           cat $SOUNDS/letters/$charval.gsm >> ${IDFILE}.gsm
        else
           # number
           cat  $SOUNDS/digits/$charval.gsm >> ${IDFILE}.gsm
        fi
    done
fi # voiceid create

# with voice ID, you will need to use GSM or TTS to create the audio ID file.

# with CW, it's a matter of changing the idrecording value 
# voice idrecording=/etc/asterisk/local/node_id
# cw    idrecording=|iDE ${STNCALL}

if [ "$VOICEID" = "y" ] ; then
    IDREC="$IDFILE"
else
    IDREC="|iDE ${STNCALL}/L"
fi

# Register (iax.conf)
# NODE1_PW
# NODE1
# BINDPORT
# DUPLEX
# if bindport is null, it's update, then set it to 4569
if [ -z "$BINDPORT" ] ; then
    BINDPORT=4569
fi

$SON
ANS=$($D --title "Bind Port" --nocancel --inputbox \
"Port 4569 is the default iax protocol port. If you are using just
one server on your public IP address, then you can select the 
default value (4569) by hitting 'Ok'.

Enter Bind Port: " 10 70 "$BINDPORT" 3>&1 1>&2 2>&3 )

if [ -z "$ANS" ] ; then
    BINDPORT=$BINDPORT
else
    BINDPORT=$ANS
fi


# duplex 
if [ -z "$DUPLEX" ] ; then
    DUPLEX=1
fi

$SOFF
ANS=$($D --title "Duplex Setting" --nocancel --default-item "$DUPLEX" --menu  \
"This setting setups up the different duplex modes for your allstar node.

 - Normally for a simplex node, you would choose '1'.

 - For a repeater, you would choose '2'.

 - If you want a 'silent' simplex node (no courtesy tones or telemetry),
you would choose '0'.

Choose the desired duplex mode:" 22 78 5 \
"0" "half duplex (telemetry and courtesy tones do not transmit)" \
"1" "semi-half duplex (telemetry and courtesy tones transmit" \
"2" "normal full-duplex mode)" \
"3" "full-duplex mode, without repeated audio from main input source" \
"4" "Normal except no main repeat audio during autopatch only" 3>&1 1>&2 2>&3)

DUPLEX=$ANS


# if this is a private node, skip the password
if [ "$(expr $NODE1)" -gt 1999 ] ;  then 

    # test password, 6-digit number
    PASSOK=false
     while  [ "$PASSOK" = "false" ] ; do

		$SON
         ANS=$($D --title "Node Password" --nocancel --inputbox \
"The node password is the password that is assigned 
with your node number. If you dont have this handy it 
can be retrieved by logging into your account at 
allstarlink.org and checking node $NODE1 password.
Currently, the password can be up to 12 characters.

Enter Node password for node $NODE1:" 14 60 "$NODE1_PW" 3>&1 1>&2 2>&3)

        # test, if null, use default else check answer
        if [ -z "${ANS}" ] ; then
            break
        elif  [[ ! ${ANS} =~ ^[0-9a-zA-Z]+$ ]] || [ ${#ANS} >= 16 ] ; then
		$SOFF
		$D --title "Password Error" --infobox "Password format is invalid.." 3 34 ; sleep 2
		PASSOK=false
        else
            PASSOK=true
        fi
    done

    if [ -z "$ANS" ] ; then
        NODE1_PW=$NODE1_PW
    else
        NODE1_PW=$ANS
    fi

fi ; # end node password

#iax rpt user info
if [ "$UPDATE" = "yes" ] ; then
   if [ -z "$IAXRPT_PW" ] ; then
       DEFAULT="--defaultno"
   else
       DEFAULT=""
   fi
else
   DEFAULT="--defaultno"
fi


$SOFF
if ($D --title "IAXRPT Password" $DEFAULT --yesno \
"Asterisk Allstar has the capability to receive 
connections from a Windows computer using a program 
called iaxRpt. In order to do this you need to 
specify a password which will be used to confirm 
connections from that program. You would then use 
this same password to configure a iaxRpt account 
on a Windows computer. Information on how to configure 
iaxRpt can be found at the hamvoip.org website.  

Do you want to configure the password for an iaxrpt 
connection?" 16 70) then
   #yes
   IAXRPT=y
else
   #no
   IAXRPT=n
fi

if  [ "$IAXRPT" = "n" ] ; then
   IAXRPT_PW=""
else
	$SOFF
	ANS=$($D --title "IAXRPT Password" --nocancel --inputbox "Enter your iaxrpt password" 8 40 "$IAXRPT_PW"  3>&1 1>&2 2>&3 )
	IAXRPT_PW=$ANS
fi

echo "NODE1=\"$NODE1\"" > $CONFIGFILE
echo "STNCALL=\"$STNCALL\"" >> $CONFIGFILE
echo "REPORTSTAT=\"$REPORTSTAT\"" >> $CONFIGFILE
echo "BINDPORT=\"$BINDPORT\"" >> $CONFIGFILE
echo "NODE1_PW=\"$NODE1_PW\"" >> $CONFIGFILE
echo "IAXRPT_PW=\"$IAXRPT_PW\"" >> $CONFIGFILE
echo "VOICEID=\"$VOICEID\""  >> $CONFIGFILE
echo "TTS_ID=\"$TTS_ID\""  >> $CONFIGFILE
echo "DUPLEX=\"$DUPLEX\"" >> $CONFIGFILE
echo "IDREC=\"$IDREC\"" >> $CONFIGFILE
echo "TEXTTOCONVERT=\"$TEXTTOCONVERT\"" >> $CONFIGFILE


##############################################################
#           Start of file modification                       #
##############################################################
# first create a header file for template files  and save in /tmp
cat << _EOF > /tmp/tpl_info.txt
; WARNING - THIS FILE WAS AUTOMATICALLY CONFIGURED FROM A
; TEMPLATE FILE IN   /usr/local/etc/asterisk_tpl   BY THE
; NODE-CONFIG.SH SCRIPT.
;
; EACH TIME THIS SCRIPT IS RUN, THIS FILE WILL BE OVERWRITTEN.
; IF YOU CHANGE ANYTHING IN THIS FILE AND RUN THE NODE-CONFIG.SH
; SCRIPT, IT WILL BE LOST.
;
; IF YOU INTEND TO USE THE NODE-CONFIG.SH SCRIPT,  THEN YOU SHOULD
; MAKE MODIFICATIONS TO THE ACTUAL TEMPLATE FILES LOCATED IN
; /usr/local/etc/asterisk_tpl directory.
;
_EOF

##############################################################
# rpt.conf
# NODE1;NODE2;STNCALL
# change number 1999 to <nodenumber>
# change WA3ZYZ to <stncall>

# Check allstar.env for possible different setup RPT template file
# WA3DSP 3/2019
if [ -z $RPT_TEMPLATE_FILE ]
    then
        RPT_TMP="rpt.conf_tpl"
    else
        RPT_TMP=$RPT_TEMPLATE_FILE
fi

# then convert the template using ConverFile and save in /tmp 
ConvertFile "$SRCDIR"/$RPT_TMP /tmp/rpt.conf_main

# cat the header file with the converted tpl file and save to 
# "$CONVDIR"/rpt.conf
cat /tmp/tpl_info.txt  /tmp/rpt.conf_main > "$CONVDIR"/rpt.conf

# setup report status

if [ "$REPORTSTAT" = "y" ] ; then
    sed 's/;statpost_/statpost_'/g "$CONVDIR"/rpt.conf > "$CONVDIR"/rpt.conf_1
    mv "$CONVDIR"/rpt.conf_1 "$CONVDIR"/rpt.conf
fi

# ID Change

#$SOFF
#$D --title "Updating Configuration" --infobox "rpt.conf update completed..." 3 34


##############################################################
# extensions
# change 1999 to <nodenumber>
# had to use sed since eval failed to convert the file correctly.
# ConvertFile "$SRCDIR"/extensions.conf_tpl "$CONVDIR"/extensions.conf

# Check allstar.env for possible different setup EXTENSIONS template file
# WA3DSP 3/2019
if [ -z $EXTENSIONS_TEMPLATE_FILE ]
    then
        EXTENSIONS_TMP="extensions.conf_tpl"
    else
        EXTENSIONS_TMP=$EXTENSIONS_TEMPLATE_FILE
fi

sed "s/_NODE1_/${NODE1}/g" "$SRCDIR"/$EXTENSIONS_TMP > /tmp/extensions.conf_main

# add the tpl info and conf file
cat /tmp/tpl_info.txt /tmp/extensions.conf_main > "$CONVDIR"/extensions.conf

#$SOFF
#$D --title "Updating Configuration" --infobox "extensions.conf completed..." 3 34

##############################################################
# iax.conf
# bindport
# register
# iphone/secret

# Check allstar.env for possible different setup IAX template file
# WA3DSP 3/2019
if [ -z $IAX_TEMPLATE_FILE ]
    then
        IAX_TMP="iax.conf_tpl"
    else
        IAX_TMP=$IAX_TEMPLATE_FILE
fi

ConvertFile "$SRCDIR"/$IAX_TMP /tmp/iax.conf_main

cat /tmp/tpl_info.txt /tmp/iax.conf_main > "$CONVDIR"/iax.conf

#$SOFF
#$D --title "Updating Configuration" --infobox "iax.conf completed..." 3 34

##############################################################
# clean up tmp
rm -f /tmp/tpl_info.txt /tmp/extensions.conf_main /tmp/iax.conf_main /tmp/rpt.conf_main

##############################################################
# Setup the allstar.env file
#
# this replaces the export NODE1 line with the new line
sed -i  "s/^export NODE1=.*/export NODE1=${NODE1}/" /usr/local/etc/allstar.env

# Added skip simpleusb setup
# WA3DSP 3/2019
if [ "${SETUP_SIMPLEUSB,,}" != "disabled" ]; then

#cjk
if [ ! -f /tmp/rpt_config.tmp ] ; then
	$SOFF
    if ($D --title "Simple USB Configuration" --defaultno --yesno \
"You now will need to review and configure simpleusb.conf. 
In particular, the 'carrier from' needs to be set to match 
your radios COS polarity.  See the configuration howto on 
the hamvoip.org web page for more info on configuring 
simpleusb and setting audio levels.  

Do you want to configure Simple USB settings now?" 12 70 ) then
        #yes
        /usr/local/sbin/simpleusb-config.sh
	setterm --reset
        exit
    fi

fi # ; simpleusb-config

fi # end simpleusb enable test

$SOFF
if ($D --title "Restart Asterisk" --yesno \
"When running this script live to change things most 
things other than the voice ID do not change without a
restart or you could do reloads of all the files.

Do you want to restart Asterisk to enable selections?" 10 60 ) then
    #yes
    /usr/local/sbin/astdn.sh >/dev/null 2>&1
    sleep 2
    /usr/local/sbin/astup.sh >/dev/null 2>&1

fi

setterm --reset
exit #EOF
