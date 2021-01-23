#!/bin/bash

# Voice weather from the National weather service XML sites or 
# weatherungerground stations.

# # Copyright 2017 - Doug Crompton, WA3DSP - hamvoip.org

# Modified 5/2018 to allow any length ID. Converts WUNDER ID to upper case
# Added choise of Degrees F or C - defaults to Degress F
# WA3DSP

# This is preliminary code to say weather conditions for your area.
# Use the Station ID which can be found at http://w1.weather.gov/xml/current_obs/
# or w-<weatherunderground id>

#  wx_condition.sh w-<wunder-ID> node mode
#  wx_condition.sh <NWS-ID> node mode

# mode = 'v' for display weather conditions only, 'd' for debug, display all and play
# 'p' or blank for play voice only, 'b' for both display and play, 'x' to view raw xml

# This script requires the xml2 package 
# pacman -Sy xml2

# To play using an Allstar function - add the following to the
# /etc/asterisk/rpt.conf file functions stanza
#  
# 820=cmd,/usr/local/sbin/wx_condition.sh <NWS-ID or -wWeatherundergroundID> <node>
#
# replace 820 with DTMF sequence you desire, include ID and local node on that
# server to play on. Example:
#
#  860=cmd,/usr/local/sbin/wx_condition.sh KPHL 40000
#
#  Play weather to node 40000 when DTMF *860 is entered.

# Because of its length it would generally not be suitable to put this in a cron

# Two optional files can be user defined - /etc/asterisk/local/wx_header.gsm and
# /etc/asterisk/local/wx_footer.gsm

# The header file when present plays BEFORE the weather data and the footer file after.
# These files must be in .gsm format and standalone playable as such.

# The header file could say something like "weather for philadelphia, pa" using of
# course your location.

# 6/27/2018 - added ability to set C or F or Both from 
#   /etc/asterisk/local/wx_condition.ini file
#
#  File should contain -

#Set Degrees F or C or BOTH
# Set to "0" to not use, "1" to use
# Uncomment these lines in wx_condition.ini file
#CDEG="0"
#FDEG="1"
# End of wx_condition.ini file

# END OF COMMENTS 

base="/var/lib/asterisk/sounds"

if [ -f /etc/asterisk/local/wx_condition.ini ] ; then
    . /etc/asterisk/local/wx_condition.ini
else
    # Set Degrees F or C or BOTH
    # Set to "0" to not use, "1" to use
    CDEG="0"
    FDEG="1"
fi

#echo $CDEG
#echo $FDEG

function read_xml()
{
# Requires package xml2
    local Value=`echo $wx_xml | xml2 | grep /$1= | sed 's/.*=//'`
# Alternative - SLOW! requires package perl-xml-twig
#    local Value=`echo $wx_xml | xml_grep $1 --text_only`
    echo $Value
}

function round()
{
    if [[ $(isnum $1) -eq 1 ]]
        then
	   local r=`printf "%.0f\n" $1`
	   echo $r
	else
	   echo ""
    fi	
}

function format_number_string
{
    local Value=$1
    local FNAME1=""
    if [[ "$Value" -lt "-1" ]]
        then {
          FNAME1="$base/digits/minus.gsm "
          Value=`echo ${Value#-}`
    } fi

   if [[ "$Value" -ge "100" ]]
        then {
          FNAME1+="$base/digits/1.gsm "
          FNAME1+="$base/digits/hundred.gsm "
          if [[ "$Value" -ne "100" ]]
            then {
             Value=$(( $Value - 100 )) 
	  } fi 
    } fi


    if [[ "$Value" -lt "20" ]]
        then {
          FNAME1+="$base/digits/$Value.gsm "
        } elif [[ $Value -ne "100" ]] 
           then {
          Value10=${Value:0:1}"0"
          FNAME1+="$base/digits/$Value10.gsm "
          Value1=${Value:1:1}
          if [[ "$Value1" -gt "0" ]]
            then {
              FNAME1+="$base/digits/$Value1.gsm "
          } fi
    }  fi

    echo "$FNAME1"
}

function speak_text {
# Script to speak letters and numbers from asterisk sounds
# Modified from a script by Ramon Gonzalez KP4TR 2014
#
        local SPEAKTEXT=$(echo -n "$1" | tr '[:upper:]' '[:lower:]')
        local SPEAKLEN=$(echo -n "$SPEAKTEXT" | /usr/bin/wc -m)
        local COUNTER=0
	local CH

        while [  "$COUNTER" -lt "$SPEAKLEN" ]; do
                let COUNTER++
                CH=$(echo -n "$SPEAKTEXT" | cut -c${COUNTER})
                if [[ $CH =~ ^[A-Za-z_]+$ ]]; then
			FNAME+="$base/letters/${CH}.gsm "		                
                fi
                if [[ ${CH} =~ ^-?[0-9]+$ ]]; then
			FNAME+="$base/digits/${CH}.gsm "
                fi
                case $CH in
                .) FNAME+="$base/letters/dot.gsm " ;;
                -) FNAME+="$base/letters/dash.gsm " ;;
                =) FNAME+="$base/letters/equals.gsm " ;;
                /) FNAME+="$base/letters/slash.gsm " ;;
                !) FNAME+="$base/letters/exclaimation-point.gsm " ;;
                @) FNAME+="$base/letters/at.gsm " ;;
                $) FNAME+="$base/letters/dollar.gsm ";;
                *) ;;
                esac
        done
}

function format_wx_header()
{
	FNAME="$base/silence/2.gsm "
	if [[ -f /etc/asterisk/local/wx_header.gsm ]]
		then {
			FNAME+="/etc/asterisk/local/wx_header.gsm "
		} else {
			FNAME+="$base/weather.gsm "
			FNAME+="$base/conditions.gsm "
			FNAME+="$base/for.gsm "
			FNAME+="$base/letters/i.gsm "
			FNAME+="$base/letters/d.gsm "
			speak_text $Station_ID
	} fi
	FNAME+="$base/silence/1.gsm "
}

function format_wx_footer()
{
	if [[ -f /etc/asterisk/local/wx_footer.gsm ]]
                then {
			FNAME+="$base/silence/1.gsm "
                        FNAME+="/etc/asterisk/local/wx_footer.gsm "
	} fi
	FNAME+="$base/silence/1.gsm "
}

function format_wind_dir()
{
	# Converts degress to coordinate

	local deg=$1
        Wind_FNAME=""
	if (( $(echo "$deg >= 11.25" | bc -l) )) && (( $(echo "$deg < 33.75" | bc -l) )); then
		Wind_DIR='NNE'
		Wind_FNAME+="$base/north.gsm "
		Wind_FNAME+="$base/north.gsm " 
		Wind_FNAME+="$base/east.gsm "
	elif 
	   (( $(echo "$deg >= 33.75" | bc -l) )) && (( $(echo "$deg < 56.25" | bc -l) )); then
		Wind_DIR='NE' 
		Wind_FNAME+="$base/north.gsm "
		Wind_FNAME+="$base/east.gsm "

	elif 
	   (( $(echo "$deg >= 56.25" | bc -l) )) && (( $(echo "$deg < 78.75" | bc -l) )); then
		Wind_DIR='ENE'
		Wind_FNAME+="$base/east.gsm "
		Wind_FNAME+="$base/north.gsm "
		Wind_FNAME+="$base/east.gsm "
 	elif 
	   (( $(echo "$deg >= 78.75" | bc -l) )) && (( $(echo "$deg < 101.25" | bc -l) )); then
		Wind_DIR='East' 
		Wind_FNAME+="$base/east.gsm "
	elif 
	   (( $(echo "$deg >= 101.25" | bc -l) )) && (( $(echo "$deg < 123.75" | bc -l) )); then
		Wind_DIR='ESE' 
		Wind_FNAME+="$base/east.gsm "
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/east.gsm "
	elif
	   (( $(echo "$deg >= 123.75" | bc -l) )) && (( $(echo "$deg < 146.25" | bc -l) )); then
		Wind_DIR='SE'
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/east.gsm "
 	elif 
	   (( $(echo "$deg >= 146.25" | bc -l) )) && (( $(echo "$deg < 168.75" | bc -l) )); then
		Wind_DIR='SSE' 
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/east.gsm "
	elif 
	   (( $(echo "$deg >= 168.75" | bc -l) )) && (( $(echo "$deg < 191.25" | bc -l) )); then
		Wind_DIR='South' 
		Wind_FNAME+="$base/south.gsm "
	elif 
	   (( $(echo "$deg >= 191.25" | bc -l) )) && (( $(echo "$deg < 213.75" | bc -l) )); then
		Wind_DIR='SSW' 
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/west.gsm "
	elif 
	   (( $(echo "$deg >= 213.75" | bc -l) )) && (( $(echo "$deg < 236.25" | bc -l) )); then
		Wind_DIR='SW' 
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/west.gsm "
	elif 
	   (( $(echo "$deg >= 236.25" | bc -l) )) && (( $(echo "$deg < 258.75" | bc -l) )); then
		Wind_DIR='WSW' 
		Wind_FNAME+="$base/west.gsm "
		Wind_FNAME+="$base/south.gsm "
		Wind_FNAME+="$base/west.gsm "
	elif 
	   (( $(echo "$deg >= 258.75" | bc -l) )) && (( $(echo "$deg < 281.25" | bc -l) )); then
		Wind_DIR='West' 
		Wind_FNAME+="$base/west.gsm "
	elif 
	   (( $(echo "$deg >= 281.25" | bc -l) )) && (( $(echo "$deg < 303.75" | bc -l) )); then
		Wind_DIR='WNW' 
		Wind_FNAME+="$base/west.gsm "
		Wind_FNAME+="$base/north.gsm "
		Wind_FNAME+="$base/west.gsm "
	elif 
	   (( $(echo "$deg >= 303.75" | bc -l) )) && (( $(echo "$deg < 326.25" | bc -l) )); then
		Wind_DIR='NW' 
		Wind_FNAME+="$base/north.gsm "
                Wind_FNAME+="$base/west.gsm "
	elif 
	   (( $(echo "$deg >= 326.25" | bc -l) )) && (( $(echo "$deg < 348.75" | bc -l) )); then
		Wind_DIR='NNW' 
		Wind_FNAME+="$base/north.gsm "
		Wind_FNAME+="$base/north.gsm "
		Wind_FNAME+="$base/west.gsm "
	else
		Wind_DIR='North'
		Wind_FNAME+="$base/north.gsm "
fi
}

function format_wx_condition()
{
	if [[ -z "$Weather_COND" ]] 
	   then	{
		return
	} fi
	local txt1=`echo $Weather_COND | awk '{ print tolower($1) }'`
	local txt2=`echo $Weather_COND | awk '{ print tolower($2) }'`
	if [[ "$txt2" == "" ]] 
	   then {
 		if [[ -e $base/$txt1.gsm ]] ; then FNAME+="$base/$txt1.gsm " ; fi
	} else {
		if [[ -e $base/$txt1.gsm ]] ; then FNAME+="$base/$txt1.gsm " ; fi
		if [[ -e $base/$txt2.gsm ]] ; then FNAME+="$base/$txt2.gsm " ; fi
	} fi
}

isnum() { local a; awk -v a="$1" 'BEGIN {print (a == a + 0)}'; }


# Begin Main

if [ `pacman -q -Qi xml2 2> /dev/null | wc -c` == 0 ]
     then
	echo -e "\nThis script requires the 'xml2' package\nUse 'pacman -Sy xml2' to install\n"
	exit
fi

if [[ -z $1 ]]
   then {
        echo -e "\nNo Station ID given\n"
	echo -e "Command Format:\n"
	echo -e "    wx_condition.sh <station-id> or -w<wunderID> <node> <mode>\n"
        echo -e "    mode = 'v' - view only, 'd' - debug - show all output"
	echo -e "           'p' or blank - play output to node, 'b' - both play and view"
	echo -e "           'x' - view raw xml in less\n"
	echo -e "    wx_condition.sh KPHL 40000        << play NWS to node 40000"
	echo -e "    wx_condition.sh w-KPAPHL12 40000  << play weatherunderground to node 40000"
	echo -e "    wx_condition.sh KPHL 40000 v      << just view weather, no play"
	echo -e "    wx_condition.sh KPHL 40000 b      << View and play weather to node 40000"
	echo -e "    wx_condition.sh KPHL 40000 d      << debug, View all data and play"	
	echo -e "    wx_condition.sh KPHL 40000 x      << View raw xml in less (type 'q' to exit)\n\n"
	echo -e "    Set Degrees F or C in the script. Default degrees F\n\n"
        exit
} fi

if [[ -z $2 ]]
   then {
        echo -e "\nNode Number not given\n"
        exit
   } else {
        if [[ $(isnum $2) -ne 1 ]]
           then {
                echo -e "\nNode number not valid\n"
                exit
        } else {
		node=$2
	} fi

} fi

if [[ -z $3 ]]
   then {
	View="p"
  } else {	
	View=$3
} fi

if [[ ${1:0:2} == "w-" ]]
    then
        wcode=${1:2}
	wunder_code=${wcode^^}
	w_type="wunder"
	Station_ID=$wunder_code
	wget -q -O /tmp/wx.xml http://api.wunderground.com/weatherstation/WXCurrentObXML.asp?ID=$wunder_code
    else
	Station_ID=$1
	wget -q -O /tmp/wx.xml http://w1.weather.gov/xml/current_obs/$1.xml
fi

wgetreturn=$?
if [[ $wgetreturn -ne 0 ]]
      then
         echo -e "URL - http://w1.weather.gov/xml/current_obs/$1.xml Not found"
         exit
fi

if [[ "$View" != "x" ]]
    then { 


wx_xml=`cat /tmp/wx.xml`

Weather_COND=$(read_xml "weather")
Location=$(read_xml "location")
Full=$(read_xml "full")
Temperature_F=$(read_xml "temp_f")
Temperature_F=$(round $Temperature_F)
Temperature_C=$(read_xml "temp_c")
Temperature_C=$(round $Temperature_C)
Humidity=$(read_xml "relative_humidity")
#Wind_Dir=$(read_xml "wind_dir")
Wind_DEG=$(read_xml "wind_degrees")
Wind_MPH=$(read_xml "wind_mph")
Wind_MPH=$(round $Wind_MPH)
Wind_KT=$(read_xml "wind_kt")
Pressure=$(read_xml "pressure_in")
Dewpoint_F=$(read_xml "dewpoint_f")
Dewpoint_F=$(round $Dewpoint_F)
Dewpoint_C=$(read_xml "dewpoint_c")
Dewpoint_C=$(round $Dewpoint_C)
Visibility=$(read_xml "visibility_mi")
Visibility=$(round $Visibility)
Wind_Gust_MPH=$(read_xml "wind_gust_mph")
Wind_Gust_MPH=$(round $Wind_Gust_MPH)
Wind_Gust_KT=$(read_xml "wind_gust_kt")
Wind_Gust_KT=$(round $Wind_Gust_KT)
Heat_Index_F=$(read_xml "heat_index_f")
Heat_Index_F=$(round $Heat_Index_F)
Heat_Index_C=$(read_xml "heat_index_c")
Heat_Index_C=$(round $Heat_Index_C)
Wind_Chill_F=$(read_xml "windchill_f")
Wind_Chill_F=$(round $Wind_Chill_F)
Wind_Chill_C=$(read_xml "windchill_c")
Wind_Chill_C=$(round $Wind_Chill_C)
Precip_Today_IN=$(read_xml "precip_today_in")

format_wind_dir $Wind_DEG		

if [ "$View" == "v" ] || [ "$View" == "b" ] || [ "$View" == "d" ]
    then { 
	echo -e "\nWeather for Station ID - $Station_ID"
	if [[ "$w_type" == "wunder" ]]
		then
		  echo "$Full"
		else
		  echo "$Location"
	fi
	echo -e "-----------------------------------"
	if [[ ! -z $Weather_COND ]]; then echo "Weather - $Weather_COND" ;fi
	if [[ $(isnum $Temperature_F) -eq 1 ]]; then echo -e "Temperature - $Temperature_F F / $Temperature_C C" ;fi
	if [[ $(isnum $Humidity) -eq 1 ]]; then echo -e "Humidity - $Humidity Percent" ;fi
	echo -n "Wind Direction - $Wind_DIR at $Wind_MPH miles per hour" 
	if [[ $(isnum $Wind_KT) -eq 1 ]]; then echo -n " / $Wind_KT knots" ;fi
	echo
	if [[ $(isnum $Wind_Gust_MPH) -eq 1 ]]; then echo -e "Wind Gusts - $Wind_Gust_MPH miles per hour" ;fi
	if [[ $(isnum $Pressure) -eq 1 ]]; then echo -e "Barometric Pressure - $Pressure inches" ;fi
	if [[ $(isnum $Dewpoint_F) -eq 1 ]]; then echo -e "Dew point - $Dewpoint_F F / $Dewpoint_C C" ;fi
	if [[ $(isnum $Precip_Today_IN) -eq 1 ]]; then echo -e "Precipitation Today - $Precip_Today_IN inches" ;fi
	if [[ $(isnum $Visibility) -eq 1 ]]; then echo -e "Visibility - $Visibility Miles" ;fi
	if [[ $(isnum $Wind_Chill_F) -eq 1 ]]; then echo -e "Wind Chill - $Wind_Chill_F F / $Wind_Chill_C C" ;fi
	if [[ $(isnum $Heat_Index_F) -eq "1" ]]
		then
		  echo -e "Heat Index - $Heat_Index_F F / $Heat_Index_C C\n"
	else
		echo
	fi
} fi

# Assemble files for voice play

format_wx_header

format_wx_condition

if [[ $(isnum $Temperature_F) -eq "1" ]] 
   then {
	FNAME+="$base/wx/temperature.gsm "
	if [[ $FDEG -eq "1" ]]
	   then
		FNAME+=$(format_number_string $Temperature_F)
		FNAME+="$base/degrees.gsm "
		FNAME+="$base/letters/f.gsm "
	fi
	if [[ $CDEG -eq "1" ]]
	   then 
		FNAME+=$(format_number_string $Temperature_C)
		FNAME+="$base/degrees.gsm "
		FNAME+="$base/letters/c.gsm "
	fi
} fi

if [[ $(isnum $Humidity) -eq "1" ]]
   then {
	FNAME+="$base/humidity.gsm "
	FNAME+=$(format_number_string $Humidity)
	FNAME+="$base/wx/percent.gsm "
} fi

if [[ $(isnum $Pressure) -eq "1" ]]
   then {
	# Format Pressure
	P_10=`echo $Pressure | awk -F. '{print $1}'`
	P_1=`echo $Pressure | awk -F. '{print $2}'`
	P_10A=${P_10:0:1}
	P_10B=${P_10:1:1}
	P_1A=${P_1:0:1}
	P_1B=${P_1:1:1}

	FNAME+="$base/pressure.gsm "
	FNAME+="$base/digits/$P_10A.gsm "
	FNAME+="$base/digits/$P_10B.gsm "
	FNAME+="$base/wx/point.gsm "
	FNAME+="$base/digits/$P_1A.gsm "
	FNAME+="$base/digits/$P_1B.gsm "
	FNAME+="$base/wx/inches.gsm "
} fi

if [[ $(isnum $Wind_MPH) -eq "1" ]]
   then {
	FNAME+="$base/wx/winds.gsm "
        FNAME+=$Wind_FNAME
	FNAME+="$base/letters/at.gsm "
	FNAME+=$(format_number_string $Wind_MPH)
	FNAME+="$base/miles-per-hour.gsm "
} fi

if [[ $(isnum $Wind_KT) -eq "1" ]]
   then {
        FNAME+="$base/or.gsm "
        FNAME+=$(format_number_string $Wind_KT)
        FNAME+="$base/knots.gsm "
} fi

if [[ $(isnum $Wind_Gust_MPH) -eq "1" ]]
   then {
	FNAME+="$base/wx/gusting-to.gsm "
	FNAME+=$(format_number_string $Wind_Gust_MPH)
	FNAME+="$base/miles-per-hour.gsm "
} fi

if [[ $(isnum $Dewpoint_F) -eq "1" ]] 
   then {
	FNAME+="$base/wx/dew-point.gsm "
	if [[ $FDEG -eq "1" ]]
	   then
		FNAME+=$(format_number_string $Dewpoint_F)
		FNAME+="$base/degrees.gsm "
		FNAME+="$base/letters/f.gsm "
	fi
	if [[ $CDEG -eq "1" ]]
	   then 
		FNAME+=$(format_number_string $Dewpoint_C)
		FNAME+="$base/degrees.gsm "
		FNAME+="$base/letters/c.gsm "
	fi
} fi

if [[ $(isnum $Precip_Today_IN) -eq "1" ]]
   then {
	# Format percipitation
	Precip_10=`echo $Precip_Today_IN | awk -F. '{print $1}'`
	Precip_1=`echo $Precip_Today_IN | awk -F. '{print $2}'`
	Precip_1A=${Precip_1:0:1}
	Precip_1B=${Precip_1:1:1}

	FNAME+="$base/rainfall.gsm "
	FNAME+="$base/digits/today.gsm "
	FNAME+="$base/digits/$Precip_10.gsm "
	FNAME+="$base/letters/dot.gsm "
	FNAME+="$base/digits/$Precip_1A.gsm "
	FNAME+="$base/digits/$Precip_1B.gsm "
	FNAME+="$base/wx/inches.gsm "
} fi

if [[ $(isnum $Heat_Index_F) -eq "1" ]]
   then {
	FNAME+="$base/wx/heat-index.gsm "
        if [[ $FDEG -eq "1" ]]
	   then
		FNAME+=$(format_number_string $Heat_Index_F)
		FNAME+="$base/degrees.gsm "
		FNAME+="$base/letters/f.gsm "
	fi
	if [[ $CDEG -eq "1" ]]
	   then
		FNAME+=$(format_number_string $Heat_Index_C)
		FNAME+="$base/degrees.gsm "
		FNAME+="$base/letters/c.gsm "
	fi
} fi

if [[ $(isnum $Wind_Chill_F) -eq "1" ]]
   then {
        FNAME+="$base/wx/wind-chill.gsm "
	if [[ $FDEG -eq "1" ]]
	   then
	        FNAME+=$(format_number_string $Wind_Chill_F)
	        FNAME+="$base/degrees.gsm "
	        FNAME+="$base/letters/f.gsm "
	fi
	if  [[ $CDEG -eq "1" ]]
	   then
	        FNAME+=$(format_number_string $Wind_Chill_C)
	        FNAME+="$base/degrees.gsm "
	        FNAME+="$base/letters/c.gsm "
	fi
} fi


if [[ $(isnum $Visibility) -eq "1" ]]
    then {
	FNAME+="$base/visibility.gsm "
	FNAME+=$(format_number_string $Visibility)
	FNAME+="$base/miles.gsm "
} fi

format_wx_footer

if [ "$View" == "d" ] 
    then {
	echo -e "$FNAME\n\n"
} fi

if [ "$View" == "p" ] || [ "$View" == "b" ] || [ "$View" == "d" ]
    then {
	cat $FNAME > /tmp/current_wx.gsm
	/usr/bin/asterisk -rx "rpt localplay $node /tmp/current_wx"
	sleep 2
	rm -f /tmp/current_wx.gsm
} fi

} fi  # End $View != "x"
 
if [[ "$View" == "x" ]]
    then {
less /tmp/wx.xml
} fi

rm -f /tmp/wx.xml

# End of wx_condition.sh script

