#!/bin/bash

# Check your Internet connectibility
# WA3DSP Hamvoip 5/2018

declare -a domain_array=(
	        "localhost"
		"hamvoip.org" 
		"register.hamvoip.org"
		"stats.hamvoip.org"
		"allstarlink.org"
                "stats.allstarlink.org"
		"register.allstarlink.org"
		"google.com"
               )

echo -e "\n\t\t\e[4m\e[1mCheck Internet Connectivity\e[0m\n"
myip=$(/sbin/ifconfig | awk -F "[: ]+" '/inet / { if ($3 != "127.0.0.1") printf ("%s ", $3) }')
if [[ "$myip" == "127.0.0.1" ]]
   then
     myip="$myip - no connection to Internet"
fi
echo -e "\tYour local IP address is - $myip"
public_ip=`curl -s http://myip.hamvoip.org/ 2>&1`
echo -e "\tYour public IP address is - $public_ip"
a=`cat "/etc/resolv.conf"`

echo -e "\n\t\e[4m\e[1mCurrent nameserver(s)\e[0m\n"
while read -r line; do
 if [ ! "${line/nameserver}" = "$line" ]
    then
      echo -e "\t$line"
	CDNS=$(awk '{print $2}' <<< $line)
fi
done <<< "$a"
echo

declare -a dns_array=(
		"$CDNS"
	        "8.8.8.8"
		"8.8.4.4"
	       )


bad=0
echo -e "\t\e[4m\e[1mChecking DNS Servers\e[0m\n"
for dns in "${dns_array[@]}"
do
   for domain in "${domain_array[@]}"
   do
	if [[ "$domain" == "localhost" ]]
	    then 
		continue
	fi
	answer=`dig @$dns $domain | awk '/ANSWER SECTION:/{getline; print$5}'`
	if [[ "$answer" == "" ]]
	    then
		echo -e "\tNo response from $dns for $domain"
		bad=$((bad + 1))
	else
		echo -e "\tDNS $dns returns $answer for $domain"
	fi
   done
done
echo

echo -e "\t\e[4m\e[1mImportant Destination Checks\e[0m\n"
for domain in "${domain_array[@]}"
do
	a=`ping -q -c 1 -W 1 $domain 2>/dev/null`
	string=${a#*(} # remove before _
	IP=${string%%)*} # remove after -

 	if ping -q -c 1 -W 1 $domain >/dev/null 2>&1; then
		echo -e "\t$domain is reachable at $IP"
	else
		echo -e "\t$domain is not reachable"
		bad=$((bad + 1)) 
	fi
done

if [[ $bad > 0 ]]
    then
      echo -e "\n\t\e[1mNOT ALL SITES REACHABLE!\e[0m\n"
    else
      echo -e "\n\t\e[1mYour DNS and connectivity looks good\e[0m\n" 
fi
echo

