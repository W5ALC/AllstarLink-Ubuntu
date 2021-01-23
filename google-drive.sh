#!/bin/bash

# Simple script to upload, download, and list files from
# Google drive. Script adds retries to commands so you
# don't have to manually retry.

# You must have an account with Google and be setup to  
# use this script. See the howto at hamvoip.org

# WA3DSP 3/2019 HAMVOIP

# Example :
# 
#   google-drive.sh upload <filename>    - upload a file to Google drive
#   google-drive.sh download <filename>  - Download a file from Google drive
#   google-drive.sh list                 - List all files at Google drive

if [ -z $1 ]
  then
    echo -e "\n No Command given"
    echo 
    echo "   google-drive.sh upload   <filename>  - upload a file to Google drive"
    echo "   google-drive.sh download <filename>  - Download a file from Google drive"
    echo "   google-drive.sh list                 - List all files at Google drive"
    echo
    echo "   Filename can contain paths. Download path and filename are checked"
    echo "   for existence and the user is given an overwrite option"
    echo
    echo "   You must have a Google account and be setup to use this script"
    echo "   See the howto at hamvoip.org"
    echo
    exit
fi

function google_send_command() {
dt=$(date +"%D-%H:%M:%S")
ERROR=0
while :
do
  RESULT=$(gdrive $1 $2)
  echo $RESULT | grep -q "Error 403:"
  if [ $? -eq 1 ]
     then
       echo -e "\n$dt - Success - $RESULT with $ERROR retries\n"
       break 
  fi
  let "ERROR+=1"
  if [ $ERROR -gt 10 ]
     then
       echo -e "\n$dt - Retries Exceeded for command  $1 - try again\n"
       break
  fi
  sleep 3
done 
}

case "$1" in
        download)
            if [ -z $2 ]
               then
                 echo -e "\nNo Filename given\n"
                 exit
            fi 
            DIRECTORY="$(dirname "$2")"
            FILENAME="$(basename "$2")"
            google_send_command "list"
            if [ -e "$2" ]
               then
                  read -p "File exists, overwrite? [y/n] - " yn
                  if [ $yn == "n" ]
                     then
                       echo -e "\nNo file downloaded\n"
                       exit
                  fi
            fi
            FILE_ID=$(echo "$RESULT" | grep "$FILENAME" | awk '{print $1}')
            google_send_command "download" "--path $DIRECTORY --force  $FILE_ID"
            ;;
         
        upload)
            if [ -z $2 ]
               then
                 echo -e "\nNo Filename given\n"
                 exit
            fi
            google_send_command "upload" "$2" 
            ;;
         
        list)
            google_send_command "list"
            ;;
         
        *)
            echo -e "\nUsage: $0 {download|upload|list} [filename]\n"
            exit 1
 
esac

exit

