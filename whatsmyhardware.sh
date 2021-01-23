#!/bin/bash

# Read Raspberry Pi hardwarw Type
# If no parameter is specified reads form /proc
# Parameter is the Pi revision number
# Available at - 
# https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/

# D. Crompton 11/2018

if [ -z "$1" ]
  then
     Revision=`grep Revision /proc/cpuinfo | cut -d ":" -f 2 | sed 's/ //g'`
  else
     Revision=$1
fi
#echo "$Revision"

#Revision="a22042"

echo -e "\nRaspberry Pi Hardware Information\n"

echo -e "Revision\tRelease Date\tModel\tPCB Revision\tMemory\tNotes"

case "$Revision" in
 
	a01040)
	 	echo -e "Unknown   \t2 Model B   \t1.0   \t\t\t1 GB   \t(Mfg by Sony UK)"
		;;
	a01041)
	 	echo -e "$Revision   \tQ1 2015   \t2 Model B   \t1.1   \t1 GB   \t(Mfg by Sony UK)"
		;;
	a21041)
	 	echo -e "$Revistion   \tQ1 2015   \t2 Model B   \t1.1   \t1 GB   \t(Mfg by Embest)"
		;;
	a22042)
	 	echo -e "$Revision   \tQ3 2016   \t2 Model B   \t1.2   \t1 GB   \t(Mfg by Embest) with BCM2837"
		;;
	900021)
	 	echo -e "$Revision   \tQ3 2016   \tA+   \t1.1   \t512 MB   \t(Mfg by Sony)"
		;;
	900032)
		echo -e "$Revision   \tQ2 2016?   \tB+   \t1.2   \t512 MB   \t(Mfg by Sony)"
		;;
	900092)
	 	echo -e "$Revision   \tQ4 2015t   \tZero   \t1.2   \t512 MB   \t(Mfg by Sony)"
		;;
	900093)
	 	echo -e "$Revision   \tQ2 2016   \tZero   \t1.3   \t512 MB   \t(Mfg by Sony)"
		;;
	920093)
	 	echo -e "$Revision   \tQ4 2016?   \tZero   \t1.3   \t512 MB   \t(Mfg by Embest)"
		;;
	9000c1)
	 	echo -e "$Revision   \tQ1 2017   \tZero W   \t1.1   \t512 MB   \t(Mfg by Sony)"
		;;
	a02082)
	 	echo -e "$Revision   \tQ1 2016   \t3 Model B   \t1.2   \t1 GB   \t(Mfg by Sony UK)"
		;;
	a020a0)
	 	echo -e "$Revision   \tQ1 2017   \tCompute Module 3   \t1.0   \t1 GB   \t(Mfg by Sony UK) (and CM3 Lite)"
		;;
	a22082)
	 	echo -e "$Revision   \tQ1 2016   \t3 Model B   \t1.2   \t1 GB   \t(Mfg by Embest)"
		;;
	a32082)
 		echo -e "$Revision   \tQ4 2016   \t3 Model B   \t1.2   \t1 GB   \t(Mfg by Sony Japan)"
		;;
	a020d3)
	 	echo -e "$Revision   \tQ1 2018   \t3 Model B+   \t1.3   \t1 GB   \t(Mfg by Sony UK)"
		;;
	a52082)
		echo -e "$Revision   \t2016   \t3 Model B   \t1.2   \t1 GB   \t(Mfg by Stadium"
		;;
	*)
		echo "Hardware Type Unknown"
esac
echo
 
