#!/bin/bash
#
# Raspberry Pi 2/3 and  Wireless setup using systemd networking. This is not 
# compatible with netctld
# You must have your system configured using DHCP and not static IP addressing. 
# For this release, static IP addressing does not play nicely together.

# Modified 2017/01/23 by David, KB4FXC
# Bug fixes 2017/04/28 by David, KB4FXC
# ---------------
# Copyright (C) 2017 David, KB4FXC
#
#
#MENU%051%Configure the WiFi Interface Networking
#
#
# ---------------
# Copyright (C) 2016 Christopher Kovacs, W0ANM
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
#  Modified for no passphrase (open) access and SSID's with spaces
#  D. Crompton, WA3DSP - 6/29/2016

#  Integrated both wireless control and clear_wpa_supplicant 
#  into one script and made into a menu program. Added display
#  option for wpa_supplicant file.
#  D. Crompton, WA3DSP - 12/11/2016

# Added manually entered SSID option and corrected cancel bug
# in password entry.
# D. Crompton, WA3DSP - 12/4/2017

export DD="/usr/bin/dialog"


# tmp scan file
WL_SCAN_FILE=/tmp/wireless_scan.info

WL_DEV=wlan0

# wpa supplicant file for wlan0
WPA_SUPP_CONF=/etc/wpa_supplicant/wpa_supplicant_custom-wlan0.conf
#WPA_SUPP_CONF=/root/test.conf
# functions

ssid_view () {

	echo > $WL_SCAN_FILE
	iwlist wlan0 scan >> $WL_SCAN_FILE

	grep 'No scan results' $WL_SCAN_FILE 2>/dev/null 1>&2
	RES=$?
	CNT=$(wc $WL_SCAN_FILE | awk '{print $1}')
 
	if [ $CNT -lt 4 -o $RES -eq 0 ] ; then
		$SOFF
		$D --msgbox " No scan results found! " 10 30
		continue
	fi 
        
    entries=$(cat $WL_SCAN_FILE)

    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    count=1
    SIGNAL=()
    QUALITY=()
    ESSID=()
    ENTRY=()
    for line in $entries ; do

	  essid=$(echo $line | grep ESSID: | sed 's/^[ \t]*//;s/[ \t]*$//')   #  sed -e 's/^[ \t]*//')
          essid=${essid#ESSID:}

          # stip off any quotes
          essid=$(echo ${essid} | sed -e 's/^"//' -e 's/"$//')

          if [ -n "$essid" ] ; then
          	ESSID[$count]="$essid"
		continue
          fi 

          quality=$(echo $line | grep Quality | awk '{print $1}' | awk -F= '{ print $2 }')
          signal=$(echo $line | grep "Signal level" | awk -F= '{ print $3 }')
          if [ -n "$quality" ] ; then
          	QUALITY[$count]="$quality"
          	SIGNAL[$count]="$signal"
          fi

	  if [ -n "${SIGNAL[$count]}" -a -n "${QUALITY[$count]}" -a -n "${ESSID[$count]}" ] ; then
          	let count=count+1
	  fi

      done


	IFS=$SAVEIFS
	ITEMS=()
	ptr=1
	while [ $ptr -lt $count ] ; do
		if (grep "${ESSID[$ptr]}" /etc/wpa_supplicant/wpa_supplicant_custom-wlan0.conf> /dev/null) ; then
			ENTRY[$ptr]="****"
			#printf "   %s\t **%-20s\t %-8s\t %s\n" $ptr ${ESSID[$ptr]} ${QUALITY[$ptr]} ${SIGNAL[$ptr]}
		else
			ENTRY[$ptr]="    "
			#printf "   %s\t  %-20s\t %-8s\t %s\n" $ptr ${ESSID[$ptr]} ${QUALITY[$ptr]} ${SIGNAL[$ptr]}
		fi
		ITEMS+=($ptr "$ptr ${ESSID[$ptr]} | ${QUALITY[$ptr]} | ${SIGNAL[$ptr]} ${ENTRY[$ptr]}")
		let ptr=ptr+1
	done

###
#### Display menu items and have the user select items to change.
###

	if [ $count -le 1 ] ; then
		$SOFF
		$D --msgbox " No scan results found! " 10 30
		continue
	fi 
        
	$SOFF
	SSID_SEL=$($D --no-tags --title "Select SSID" --ok-label "Select SSID" --cancel-label "CANCEL" --menu "Below shows SSID Signal Quality and if entry present:" 20 70 10 "${ITEMS[@]}" 3>&1- 1>&2- 2>&3-)
	RET=$?

  if [ "$RET" = 1 ] ; then
      #exit 1
      continue
  fi

  ESSID_SEL=${ESSID[${SSID_SEL}]}

}  # end of function

### main
while true; do
$SOFF
OPTION=$($D --nocancel --title "Wireless Menu" --menu "Select an option:" 15 60 4 \
1 "Setup Wireless SSID and passphrase" \
2 "Control/Status of the Wireless Interface" \
3 "Display the wpa_supplicant file" \
4 "Exit" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ] ; then

    if [ "$OPTION" = "1" ] ; then

$SOFF
$D --yesno "This program sets the SSID and Password for the wireless network.  Do you wish to continue?" 10 60
if [ "$?" = 1 ] ; then
    continue
fi

# if not file, create one.
if [ ! -f "$WPA_SUPP_CONF" ] ; then
  touch "$WPA_SUPP_CONF"
  REBOOTNEEDED=yes
else
	$SOFF
	$D --defaultno --yesno "Do you want to clear the wpa_supplicant file? Doing so will delete all prior SSID and passphrase entires!!!" 10 60
  if [ "$?" = 0 ] ; then
 
    # remove if file present
    if [ -f "$WPA_SUPP_CONF" ] ; then
        rm -f $WPA_SUPP_CONF
    fi
   $SOFF
   $D --msgbox "wpa_supplicant file cleared" 10 60
   touch "$WPA_SUPP_CONF"
   REBOOTNEEDED=yes
  else
	$SOFF
   $D --msgbox "wpa_supplicant file not cleared" 10 60
  fi
fi

# bring up link
ip link set wlan0 up
  
        $SOFF
        $D --defaultno --yesno "Do you want to manully enter the SSID" 10 60
  if [ "$?" = 1 ] ; then
        $SOFF
$DD --infobox "Scanning WiFi SSID's, please wait.." 8 70

# scan network
ssid_view
 else
        $SOFF
    ESSID_SEL=$($D --title "SSID" \
    --clear \
    --insecure \
    --inputbox "Enter your wireless network SSID." 10 60 3>&1 1>&2 2>&3)

    if [ "$?" = 1 ] ; then
        #exit
        continue 
    fi

  fi

# cjk
# check if already already configured, if so, prompt to remove and re-add 
# get the current entries
CONFIG_SSID=$(grep "ssid=" $WPA_SUPP_CONF | grep -v grep)

if (echo $CONFIG_SSID | grep "ssid=\"${ESSID_SEL}\"") ; then
	$SOFF
    $D --yes-button "Add" --no-button "Quit" --yesno  "${ESSID_SEL} SSID entry is already present in $WPA_SUPP_CONF file. Do you want to remove and re-add this entry or Quit?" 10 60 
    if [ "$?" = 0 ] ; then
        # remove entry
        foo="$(cat "$WPA_SUPP_CONF" | awk '/'$ESSID_SEL'/ { flag=1 }; flag==0 { print $0 }; /network={/ { flag=0 }' )"

        if echo -e "$foo" | tail -1 | grep -q 'network={'; then
            foo=$(echo -e "$foo" | head -n -1)
        fi
        echo "foo --> $foo"
        echo -e "$foo" > "$WPA_SUPP_CONF"
    else
        #exit 1
	continue 
    fi
fi

SSID=${ESSID_SEL}

PASSOK=false
while [ "$PASSOK" = false ] ; do
	$SON
    WIREPASS=$($D --title "SSID Password" \
    --clear \
    --insecure \
    --inputbox "Enter your wireless network password for SSID - \"$SSID\" (8-32 characters), enter blank for open network and press Ok to continue." 10 60 3>&1 1>&2 2>&3)

    if [ "$?" = 1 ] ; then
        #exit
	continue 2
    fi

    # validate password, if not valid, re-ask passwd.
    # check entered length. must be 8 to 32 characters or none if open.
    # Made changes for no passphrase (open) access

    site="closed"

   if [ "${#WIREPASS}" -eq "0" ] ; then  
	$SOFF
	$D --msgbox "No password entered assuming open site." 10 60
	site="open"
	PASSOK=true
    else 
    	if [ ${#WIREPASS} -lt 8 ] || [ ${#WIREPASS} -gt 32 ] ; then
		$SOFF
        	$D --msgbox "Pasword length must be between 8 and 32 characters in length." 10 60
        	PASSOK=false
    	else
        	PASSOK=true
    	fi
    fi
done



# if adding new SSID, append the the config file.
if [ "$site" == "open" ] ; then
	$SOFF
	$D --yesno "Adding \"open\" no passphrase site with SSID = \"$SSID\"\n\nOK to Add?" 10 80
	if [ "$?" != "0" ] ; then
	    #exit
	    continue
	fi
	echo >> $WPA_SUPP_CONF
	echo "network={" >> $WPA_SUPP_CONF 
	echo -e "\tssid=\"$SSID\"" >> $WPA_SUPP_CONF
	echo -e "\tkey_mgmt=NONE" >> $WPA_SUPP_CONF
	echo "}" >> $WPA_SUPP_CONF
else
	$SOFF
	$D --yesno "Adding SSID = \"$SSID\" with passphrase = \"$WIREPASS\"\n\nOK to Add?" 10 80
	if [ "$?" != "0" ] ; then
	    #exit
	    continue
	fi
	wpa_passphrase "$SSID" "$WIREPASS"  >> $WPA_SUPP_CONF
fi

# Restart the wireless network for next reboot
systemctl restart wpa_supplicant@wlan0.service
# you may be able to start the service or re-enable.

if [ "$REBOOTNEEDED" = "yes" ] ; then
	$SOFF
    if ($D --yesno "You should now reboot your server by selecting 'YES' below. You also have the option of selecting 'NO' and rebooting at a later time.

If you are using a wired Ethernet connection to the server you will need to reboot by selecting 'YES'. You will then lose connection. You should then immediately disconnect the wired connection to the server during the reboot. Once rebooted if all went well you should be connected the the wireless access point your selected. 

It is important to not have both wired and wireless connections at the same time during normal operation.

If you have problems you can reconnect the wired connection, ssh back in, and retry the setup.

Do you want to reboot the server now?" 22 70) then
	### Signal a reboot!
	exit 10
    else
	$SOFF
        $D --msgbox "If you need to reboot, please select the admin.sh menu option 14. " 10 60
    fi
fi

fi

# Call wireless control
if [ "$OPTION" = "2" ] ; then
  /usr/local/sbin/firsttime/wireless-control.sh
fi

# Display wpa_supplicant
if [ "$OPTION" = "3" ] ; then
	$SOFF
	if [ -s $WPA_SUPP_CONF ] ; then
		$D --textbox $WPA_SUPP_CONF 20 80
	else
		$D --msgbox "wpa_supplicant file is not configured.\n\nSelect setup to create the file and setup wireless access." 10 70  
	fi
fi

# Exit menu
if [ "$OPTION" = "4" ] ; then
break
fi

continue
fi
done

