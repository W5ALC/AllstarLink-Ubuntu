#!/bin/bash
#  cpu_turbo.sh - turns Raspberry Pi turbo mode on/off

config_file="/boot/config.txt"

function warning {
cat << EOF

           ****  WARNING WARNING ****

Setting turning turbo mode ON can damage your board.
Be sure you have a heatsink on the CPU and adequate
ventilation. A closed case without a fan is not
recommended. Use cpu_stats.sh to check the temperature.
The temperature should remain below about 60C. See
the howto at the hamvoip.org website for more info.

EOF

while true; do
read -p "Do you wish to continue? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo -e "\nNo Change made\n"; exit;;
        * ) echo "Please answer [y]es or [n]o";;
    esac
done
}

if ! grep -q "boot_wait" $config_file ; then
	echo "boot_wait=1" >> $config_file

fi

param=`echo $1 | tr "[:upper:]" "[:lower:]"`

if [ "$param" == "off" ]
    then
       if grep -q "#force_turbo=1" $config_file
            then
	       echo -e "\nTurbo mode already OFF\n"
            else
               echo -e "\nTurbo Mode set to OFF at next reboot\n"
	       sed -i /force_turbo=1/s/^/#/ $config_file 
       fi
exit
fi

if [ "$param" == "on" ]
    then
       if grep -q "#force_turbo=1" $config_file
            then
               warning
               echo -e "\nTurbo mode set to ON at next reboot\n"
               sed -i 's/#force_turbo=1/force_turbo=1/' $config_file
	    else
	       if ! grep -q "force_turbo=1" $config_file
		    then
		       warning
		       echo -e "\nTurbo mode ON added for next reboot\n"
                       echo -n "force_turbo=1" >> $config_file
	       	    else
		       echo -e "\nTurbo mode already ON\n" 	
	       fi
        fi
     else
	echo -e "\nParameter error - cpu_turbo.sh on|off\n" 	
fi

              
