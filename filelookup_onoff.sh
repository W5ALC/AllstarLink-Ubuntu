#!/bin/bash
#  filelookup_onoff.sh - Checks node lookup methods and enables or disables rc.updatenodelist
#  D. crompton WA3DSP 9/2017

allstar_env_file="/usr/local/etc/allstar.env"

Fdef=0

function Info {
cat << EOF

          **** Enable/Disable rc.updatenodefile  ****

   This script is used to disable or enable the rc_updatenodelist 
   script. When using only the default DNS node lookup method it is
   recommended that the rc_updatenodelist script be disabled as
   it uses additional unnecessary bandwiidth. The script checks if
   you currently have any nodes defined to use the FILE lookup method
   and will not disable the rc.updatenodefile unless no nodes on this
   server are using the FILE lookup method. If no lookup method is
   defined in the rpt.conf file node lookup defaults to DNS. See the dns 
   howto at the hamvoip.org web page for more information.
   
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

function rcupdate_off {

if [ "$Fdef" == 1 ]
  then
     echo  -e "\nYou have nodes defined in rpt.conf using the FILE lookup method. rc_update cannot be disabled.\n"
     exit
fi
echo -e "\nDisabling rc.updatenodelist script"
#backup file
cp $allstar_env_file $allstar_env_file.old

grep -qle "GET_NODELIST_UPDATES" $allstar_env_file 
if [ $? -eq 0 ]
  then
     echo  -e "\nChanging GET_NODELIST_UPDATES in allstar.env to disabled\n"
     sed -i -e 's/GET_NODELIST_UPDATES="enabled"/GET_NODELIST_UPDATES="disabled"/g' $allstar_env_file
     
else
     # if entry does not exist add it
     echo -e "\nAdding GET_NODELIST_UPDATES=\"disabled\"" to $allstar_env_file
     cat <<EOT >> $allstar_env_file
# enable or disable the updating of the rpt_extnodes file
export GET_NODELIST_UPDATES="disabled"
EOT
fi
echo "Killing rc.updatenodelist process"
pkill -f -9 rc.updatenodelist
echo -e "\nRemoving /tmp/rpt_extnodes file\n"
rm -f /tmp/rpt_extnodes
}

function rcupdate_on {

if [ "$Fdef" == 0 ]
  then
     echo -e "\nYou have no nodes defined to use FILE lookup"
     read -r -p  "Do you still want the rc.updatenodelist script enabled? [y/N] - " rsp
     if [[ ! "$rsp" =~ ^([yY][eE][sS]|[yY])+$ ]]
       then
         echo -e "\nNo Change made\n"
         exit
     fi
fi
echo -e "\nEnabling rc.updatenodelist script"
#backup file
cp $allstar_env_file $allstar_env_file.old
grep -qle "GET_NODELIST_UPDATES" $allstar_env_file
if [ $? -eq 0 ]
  then
     echo  -e "\nChanging GET_NODELIST_UPDATES in allstar.env to enabled\n"
     sed -i -e 's/GET_NODELIST_UPDATES="disabled"/GET_NODELIST_UPDATES="enabled"/g' $allstar_env_file 
else
     # if entry does not exist add it
     echo -e "\nAdding GET_NODELIST_UPDATES=\"disabled\"" to $allstar_env_file
     cat <<EOT >> $allstar_env_file
# enable or disable the updating of the rpt_extnodes file
export GET_NODELIST_UPDATES="enabled"
EOT
fi

echo "Starting rc.updatenodelist script"
pkill -f -9 rc.updatenodelist
sleep 2
/usr/local/etc/rc.updatenodelist &
echo
}

function check_extnodes {

echo -e "\nNode lookup methods for nodes on this server"
echo -e "\nNode\tLookup Method"
echo "-----------------------"
IFS=$'\n' 
for i in $(asterisk -rx "rpt lookup $NODE1")
do
 echo $i | awk '{printf "%s", $2} {printf "\t%s\n", $4}'  | sed 's/\,//g'
 if echo "$i" | grep -q "FILE"; then
 Fdef=1
 fi 
done

echo
if [ -z `pgrep -f rc.updatenodelist` ]
  then
    echo -e "rc.updatenodelist not running - FILE lookup method disabled\n"
  else
    echo -e "rc.updatenodelist running - FILE lookup method enabled if defined in rpt.conf\n"
fi
}

clear
Info
check_extnodes
while true; do
read -p "[D]isable or [E]nable the rc_updatenodelist script or (q)uit? " ans
    case $ans in
        [Dd]* ) rcupdate_off; exit;;
	[Ee]* ) rcupdate_on; exit;;
        [Qq]* ) echo -e "\nNo Change made\n"; exit;;
        * ) echo "Please answer [1]yes or [0]no [q]uit";;
    esac
done


              
