#!/bin/bash

# Google drive file download script
# D. Crompton WA3DSP 3/2019 HAMVOIP 

echo -e "\n  This script lists your Google cloud files and allows"
echo "  you to select a file to download. There are options"
echo "  for listing all files or just backup files and for"
echo  "  a narrow or wide display. You must have a Google"
echo "  account and be setup according to the howto at"
echo -e "  hamvoip.org in order to use this script\n" 
echo "  For safety reasons files are downloaded to /tmp"
echo "  Once downloaded please copy the file to the required"
echo -e "  directory. For backup files this is the / directory.\n"

while true; do
    read -p "Would you like to continue? [y/n] - " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) echo -e "\nNo Restore made\n"; exit;;
      * ) echo -e "\nPlease answer [y]es or [n]o";;
    esac
done

while true; do
    read -p "Would you like to list all files (n=just backups) [y/n] - " yn
    case $yn in
      [Yy]* ) LISTALL=1; break;;
      [Nn]* ) LISTALL=0; break;;
      * ) echo -e "\nPlease answer [y]es or [n]o";;
    esac
done

while true; do
    read -p "Would you like to list all columns (wide display) [y/n] - " yn
    case $yn in
      [Yy]* ) SHORTDISP=0; break;;
      [Nn]* ) SHORTDISP=1; break;;
      * ) echo -e "\nPlease answer [y]es or [n]o";;
    esac
done

ERROR=0
echo -e "\nGetting Google file list... please wait "

while :
do
  RESULT=$(gdrive list)
  echo $RESULT | grep -q "Error 403:"
  if [ $? -eq 1 ]
     then
     #  echo "$dt - Success - $RESULT"
     #  echo "$dt - Success - $RESULT" >> /tmp/gdrive_check.txt
       break 
  fi
  let "ERROR+=1"
  if [ $ERROR -gt 10 ]
     then
     #  echo "$dt - Retries Exceeded of upload $1"
     #!  echo "$dt - Retries exceeeded for upload $1" >> /tmp/gdrive_check.txt
       break
  fi
  sleep 3
done 

# Process list into array
LINES=$(echo "$RESULT" | wc -l)
x=1
while [ $x -le $LINES ]
do 
  if [ $x -eq 1 ]
    then
      HEADER="$(echo "$RESULT" | awk "NR==$x {print}")"
  fi
  if [ $x -gt 1 ]
    then
      CURLINE="$(echo "$RESULT" | awk "NR==$x {print}")"
      if [ $SHORTDISP -eq 1 ]
         then
           CURLINE=$(echo "$CURLINE" | awk '{print $1"  " $2}')
      fi
      if [ $LISTALL -eq 1 ]
         then 
         #  opt[$x]="$(echo "$RESULT" | awk "NR==$x {print}")"
           opt[$x]=$CURLINE
           opt[$x]=$(echo -e "${opt[$x]}\n")
      else
           echo $CURLINE | grep -q "_backup_" 
           if [ $? -eq 0 ]
             then
                opt[$x]=$CURLINE
                opt[$x]=$(echo -e "${opt[$x]}\n")
           fi
      fi
  fi
  let "x+=1"
done

# Display selection list
opt[$x]="QUIT"

if [ $SHORTDISP -eq 1 ]
   then
     HEADER=$(echo "$HEADER" | colrm 50)
     echo -e "\n   $HEADER"
     printf "%0.s-" {1..73}
   else
     echo -e "\n   $HEADER"
     printf "%0.s-" {1..115}
fi

while :
do
 echo
 PS3="==== Please select your number choice === >   "
 QUIT="QUIT"

 select i in "${opt[@]}";
 do
   case $i in
         "$QUIT")
           echo -e "\nExiting.\n"
           exit
           ;;
         *)
           # echo "You picked ($REPLY)"
           break
           ;;
   esac
 done

 # Download selected file
 SELECTION=$(echo "${opt[${!i}((REPLY+1))]}")
 FILE_ID=$(echo "$SELECTION" | awk '{print $1}')
 FILE_NAME=$(echo "$SELECTION" | awk '{print $2}')


 if [ $REPLY -lt 1 ] || [ $REPLY -gt "${#opt[@]}" ] || [ "$FILE_ID" == "" ]
     then
       echo -e "\n** INVALIDi ENTRY **\n"
     else
       break
 fi
done

echo -e "\n\nFile - $FILE_NAME with ID - $FILE_ID is being downloaded to /tmp\n"
echo -e "Please wait....\n"
FORCE=""

if [ -e "/tmp/$FILE_NAME" ]
   then
    while true; do
       read -p "File $FILE_NAME already exists in /tmp - Overwrite? [y/n] - " yn
       case $yn in
         [Yy]* ) FORCE="--force"; break;;
         [Nn]* ) echo -e "\nNo file downloaded\n"; exit;;
         * ) echo -e "\nPlease answer [y]es or [n]o";;
       esac
    done
fi
echo -e "\nDownloading $FILE_NAME - please wait....\n"

while :
do
  RESULT=$(gdrive download $FORCE --path /tmp "$FILE_ID")
  echo $RESULT | grep -q "Error 403:"
  if [ $? -eq 1 ]
     then
       echo -e "\nSUCCESS - file $FILE_NAME downloaded to /tmp\n"
       break
  fi
  let "ERROR+=1"
  if [ $ERROR -gt 10 ]
     then
       echo -e "\nRetries exceeded to Google - try again\n"
       break
  fi
  sleep 3
done
echo

