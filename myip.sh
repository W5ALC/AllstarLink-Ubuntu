#!/bin/bash
#
# myip.sh - display local (LAN or WAN) ip address
# WA3DSP 8/2014
# ---------------
# Copyright (C) 2015, 2016 - Doug, WA3DSP
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
# $Id: myip.sh 22 2016-01-30 02:07:39Z w0anm $


# Old method - may not work well with wifi
# ip=`ifconfig eth0 | awk '/inet / {print $2}'`
# New method
DEVTMP=`ip link show | grep " UP " | grep -v lo | grep -v "link/ether" | awk '{print $2}'`

DEVICE=${DEVTMP/:/}

ip=`ip addr show $DEVICE | awk '/inet / {print $2}' | awk 'BEGIN { FS = "/"}  {print $1}'`

echo $ip

