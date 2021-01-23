#!/bin/bash
# Quick CPU Stats
# WA3DSP 3/2015

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
bold=`tput bold`
rev=`tput rev`
reset=`tput sgr0`

echo -e "\n\t\tCurrent CPU stats"
echo -e "\t\t-----------------"
for info in /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_*
do 
  echo -n $(basename "${info}")" = "
  result=`sudo cat ${info}`
  if [[ ${info} != *"transition"* ]]; then
    echo "$((result / 1000)) MHz."
  else
    echo $result
  fi
done
echo -n "cpu frequency ondemand up threshold = "
if [ -s /sys/devices/system/cpu/cpufreq/ondemand/up_threshold ]; then
     cat /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
else
     echo
fi
echo -n "cpu frequency scaling governor = "
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo -n "Current CPU Temperature = "
PTEMP=`cat /sys/class/thermal/thermal_zone0/temp` 
PTEMP=`expr $PTEMP / 1000`
echo -en $bold$rev
if [ "$PTEMP" -le "50" ]
	then
          echo -en $green
elif [ "$PTEMP" -le "60" ]
        then
          echo -en $yellow
else
	  echo -en $red
fi
echo -n $PTEMP
echo -n "C / "
FTEMP=`expr 9 '*' $PTEMP / 5 + 32`
echo -n "$FTEMP"
echo "F"
echo -en $reset
#echo -n "CPU Trip Point Temperature - "
#PTRIP=`cat /sys/class/thermal/thermal_zone0/trip_point_0_temp`
#PTRIP=`expr $PTRIP / 1000`
#echo -n $PTRIP
#echo "C"
echo Core `/opt/vc/bin/vcgencmd measure_volts core`
echo sdram core `/opt/vc/bin/vcgencmd measure_volts sdram_c`
echo sdram I/O `/opt/vc/bin/vcgencmd measure_volts sdram_i`
echo sdram PHY `/opt/vc/bin/vcgencmd measure_volts sdram_p`
echo `grep -m 1 Bogo /proc/cpuinfo` X 4 CORES
echo 
