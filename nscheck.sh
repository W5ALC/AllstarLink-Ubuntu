#! /bin/bash
#
#nscheck.sh

#---------------
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


TOPDOMAIN=allstarlink.org                                                       
WGET=`which wget`

for i in nodes1 nodes2 nodes3 nodes4
do                                                               
	$WGET  -q -O /tmp/$i.out http://$i.$TOPDOMAIN/cgi-bin/nodes.pl
	if [ $? -ne 0 ]
	then
		rm -f /tmp/$i.out
		echo "$i.$TOPDOMAIN is down"
	else
		echo "$i.$TOPDOMAIN is up"
		sites=$((sites+1))
		if [ -z "$nodelist" ]
		then
			nodelist=$i 
		else
			nodelist="$nodelist $i"
		fi

	fi
done

if ! [ -z $1 ]
then
	files=$(echo "/tmp/nodes?.out")
	for file in $files
	do
		node=$(echo $file | cut -d '/' -f3 | cut -d '.' -f1)
		echo "***** $node *****"
		grep $1 < $file
	done
else
	files=$(echo "/tmp/nodes?.out")
	for file in $files
	do
		node=$(echo $file | cut -d '/' -f3 | cut -d '.' -f1)
		echo "***** $node  *****"
		head -n 3 $file
	done
fi

rm /tmp/nodes*.out
