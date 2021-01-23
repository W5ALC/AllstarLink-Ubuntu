#!/bin/bash
# Modified 2017/01/20 by David, KB4FXC
# ---------------
# Copyright (C) 2014-2017 David, KB4FXC 
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
# 
#MENU%11%Display System Version Numbers

R1=$(head -1 /etc/allstar_version)
R2=$(/sbin/asterisk -V)
R3=$(cat /proc/version | awk -F '[(][g]' '{print $1}')
R4=$(cat /proc/version | awk -F '[(][g]' '{print "g"$2}')


$SOFF
$D --title 'HamVoIP AllStar Version Numbers' --msgbox "\n---HamVoIP Firmware Version---\n$R1\n\n---HamVoIP AllStar Version---\n$R2\n\n---Linux Kernel Version---\n$R3\n$R4\n\n" 24 78

exit 0

