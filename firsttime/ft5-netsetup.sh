#!/bin/bash

# Extensively modified 2014/06/20 by KB4FXC
# Revision 1.1

# modified for the Rpi2 by w0anm
#  $Id: netsetup.sh 26 2016-04-11 13:50:22Z w0anm $

# ---------------
# Copyright (C) 2015, 2016 David, KB4FXC
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
# Network interface setup script
#
#MENUFT%050%Configure the Wired Ethernet Networking

NETSERVICETYPE="SYSTEMD"           # SYSTEMD = systemd networking
                                   # NETCTL = netctl service
# gets current IP address
function getIPaddr {
    # DEVTMP=`ip link show | grep " UP " | grep -v lo | grep -v "link/ether" | awk '{print $2}'`
    # DEVICE=${DEVTMP/:/}
    DEVICE=$1
    IP=$(ip addr show $DEVICE | awk '/inet / {print $2}' | awk 'BEGIN { FS = "/"}  {print $1}')
   # echo "$IP"
   if (ip addr show $DEVICE | grep dynamic > /dev/null) ; then
     CURSTATE=DYNAMIC
   else
     CURSTATE=STATIC
   fi
    # echo "$IP $CURSTATE"
}

### calc_network does not perform error testing on the
### IP address octets! Insure that the octets are valid
### before calling.
function calc_network
{
    IFS=. read -r i1 i2 i3 i4 <<< "$1"
    IFS=. read -r m1 m2 m3 m4 <<< "$2"
    NETWORK=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$(($i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")
    echo $NETWORK

}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
        
# Function calculates number of bit in a netmask
mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "0"; exit 1
        esac
    done
    echo "$nbits"
}

# get current IP address info
getIPaddr eth0

$SOFF
if ($D --title "Network Interface Setup" --defaultno --yesno "Network Interface Setup\n\n Current IP Address:  $IP\n Current state: $CURSTATE \n\n Do you want to change this ?" 10 70) then
    # yes
    ANSWER=y
else
   # no
   ANSWER=n
   exit 0
fi

VAL=1
while [ "$VAL" = "1" ] ; do
	$SOFF
	if ($D --title "Type of Network Connection" --yes-button "Static" --no-button "DHCP"  --yesno "o you want to set up (S)tatic, or (D)CHP for the main network interface?" 10 60) then
		ANS=S
	else
		ANS=D
	fi

    case "$ANS" in
       [Ss]) IFMODE=STATIC
            VAL=0
            ;;
        [Dd]) IFMODE=DHCP
            VAL=0
            ;;
         *) echo "Invalid Selection, enter S or D"
            VAL=1
     esac
done

if [ "$IFMODE" = "STATIC" ] ; then
    ANSWER=""
    while [ -z "$ANSWER" ] ; do
        TIP=0 
        while [ $TIP -eq 0 ] ; do
		$SON
            IPADDR=$($D --title "IP Address" --inputbox "Enter the IP address in the form XXX.XXX.XXX.XXX:" 10 70 3>&1 1>&2 2>&3)
            if (! valid_ip $IPADDR) ; then
		$SOFF
                $D --title "Error" --msgbox "Error! IP=$IPADDR is invalid. Please try again!." 10 70 
                echo
             else
                TIP=1
            fi
        done

        while [ true ] ; do
		$SON
            NETMASK=$($D --title "Netmask" --inputbox "Enter the netmask in the form XXX.XXX.XXX.XXX:" 10 70 3>&1 1>&2 2>&3)
            NBITS=$(mask2cidr $NETMASK)
            if [ "$NBITS" -lt 7 -o  "$NBITS" -gt 30 ] ; then
		$SOFF
                $D --title "Error" --msgbox "$NETMASK ($NBITS) is not a valid Netmask!!/n/n/n/n Try Again..." 10 70 
                continue
            fi
            break;
        done

        TIP=0 
        while [ $TIP -eq 0 ] ; do
		$SON
            DGW=$($D --title "Default Gateway" --inputbox "Enter the default gateway address  in the form XXX.XXX.XXX.XXX:" 10 70 3>&1 1>&2 2>&3)
            if (! valid_ip $DGW) ; then
		$SOFF
                $D --title "Error" --msgbox "Gateway=$DSW is invalid!!/n/n/n/n Try Again..." 10 70 
            else
                TIP=1
            fi
        done

        NET0=$(calc_network $IPADDR $NETMASK)
        NET1=$(calc_network $DGW $NETMASK)

        #echo "NET0=$NET0, NET1=$NET1"
        echo 
        if [ "$NET0" != "$NET1" ] ; then
		$SOFF
            if ($D --title "Network Check" --yesno "Network addresses do not match! Your configuration\n appears invalid. Please check carefully:\n\n Netmask               : $NETMASK\n IP Address            : $IPADDR\n Network for IP Address: $NET0\n Default Gateway       : $DGW\n Network for Gateway   : $NET1 \n\n\n Do you accept this configuration?" 20 70) then
                #yes
                ANSWER=y
            else
                #no
                ANSWER=no
            fi
        else
		$SOFF
            if ($D --title "Network Review" --yesno "Please review your configuration:\n\n IP Address       : $IPADDR\n Netmask          : $NETMASK\n Default Gateway  : $DGW \n\n\n Do you accept this configuration?" 20 70 ) then
                #yes
                ANSWER=y
            else
                #no
                ANSWER=no
            fi
        fi

        if [ "$ANSWER" = "y" ]; then      # answer 
		$SOFF
            {
                for ((i = 0 ; i <= 100 ; i+=5)); do
                sleep 0.1
                echo $i
                done
            } | $D --gauge "Creating /etc/systemd/network/eth0.network file." 8 50 0
            if [ "$NETSERVICETYPE" = "SYSTEMD" ] ; then 
                NET_CONF_PATH=/etc/systemd/network/eth0.network
                cat << _EOF > $NET_CONF_PATH 
[Match]
Name=eth0

[Network]
DHCP=none
Address=$IPADDR/$NBITS
Gateway=$DGW
DNS=127.0.0.1

_EOF
            fi
            if [ "$NETSERVICETYPE" = "NETCTL" ] ; then 
                NET_CONF_PATH=/etc/netctl/eth0
                cat << _EOF > $NET_CONF_PATH 
Description='A basic static or dhcp Ethernet connection'
Interface=eth0
Connection=ethernet

## Uncomment either (not both) DHCP or Static IP lines
## Uncomment the following lines for dhcp IP
#IP=dhcp" >> $INTPATH

## IP6 not normally used leave following lines commented
## for DHCPv6
#IP6=dhcp
## for IPv6 autoconfiguration
#IP6=stateless
## END dhcp

## Uncomment the following 5 lines for static IP
## and change to your local parameters
AutoWired=yes
IP=static
Address=('$IPADDR/$NBITS')
Gateway='$DGW'
DNS=('127.0.0.1')

## Routes not normally used - leave commented unless you have reason not to
#Routes=('192.168.0.0/24 via 192.168.1.2')

## IPV6 not normally used - leave following lines commented
## For IPv6 autoconfiguration
#IP6=stateless
## For IPv6 static address configuration
#IP6=static
#Address6=('1234:5678:9abc:def::1/64' '1234:3456::123/96')
#Routes6=('abcd::1234')
#Gateway6='1234:0:123::abcd'
## END static IP"
_EOF

               # disable dhcpd services
               /usr/bin/systemctl disable dhcpcd 1>/dev/null 2>&1

           fi ; # answer
        else
            #reset answer to null to keep in loop
            ANSWER=""
        fi

    done ; # static enter loop - done
fi ; # end of Static section

if [ "$IFMODE" = "DHCP" ] ; then
    if [ "$NETSERVICETYPE" = "SYSTEMD" ] ; then 
        NET_CONF_PATH=/etc/systemd/network/eth0.network
        cat << _EOF > $NET_CONF_PATH
[Match]
Name=eth0

[Network]
# Set DHCP = both or ipv4 for dhcp and
# Set DHCP = none for static
DHCP=both
# uncomment and set these lines for static IP
# Address=192.168.0.142/24
# Gateway=192.168.0.10
# DNS is hardwired in resolv.conf to 127.0.0.1
#DNS=127.0.0.1
_EOF

    ########### systemctl enable, don't think we need it. ########
    #        /usr/bin/systemctl enable dhcpcd 1>/dev/null 2>&1

    fi
    if [ "$NETSERVICETYPE" = "NETCTL" ] ; then 
        NET_CONF_PATH=/etc/netctl/eth0
        cat << _EOF > $NET_CONF_PATH

Setting network address mode to DHCP
Description='A basic static or dhcp Ethernet connection'
Interface=eth0
Connection=ethernet
#
## Uncomment either (not both) DHCP or Static IP lines
## Uncomment the following lines for dhcp IP
IP=dhcp

## IP6 not normally used leave following lines commented
## for DHCPv6
#IP6=dhcp
## for IPv6 autoconfiguration
#IP6=stateless
## END dhcp
## Uncomment the following 5 lines for static IP
## and change to your local parameters
#AutoWired=yes
#IP=static
#Address=('192.168.0.132/24')
#Gateway='192.168.0.9'
DNS=('127.0.0.1')

## Routes not normally used - leave commented unless you have reason not to
#Routes=('192.168.0.0/24 via 192.168.1.2')

## IPV6 not normally used - leave following lines commented
## For IPv6 autoconfiguration
#IP6=stateless
## For IPv6 static address configuration
#IP6=static
#Address6=('1234:5678:9abc:def::1/64' '1234:3456::123/96')
#Routes6=('abcd::1234')
#Gateway6='1234:0:123::abcd'
## END static IP
_EOF

        /usr/bin/systemctl enable dhcpcd >/dev/null 2>&1
    fi

$SOFF
$D --title "Network Setup" --msgbox "Network setup is now complete." 10 70

fi

$SON
