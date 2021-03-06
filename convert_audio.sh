#!/bin/bash

# Convert audio mp3 file to playable Asterisk Allstar audio file
# D. Crompton 2/2019
# Changed to use mp3 for personal reasons

if [ -z $1 ] || [ ! -f $1 ]
  then
   echo -e "\n Convert mp3 file to Asterisk/Allstar format\n"
   echo -e "   convert_audio.sh <input file.mp3> [output_filename]\n"
   echo -e "   Input file must be .mp3, output file is input filename.ul"
   echo -e "   unless different second parameter filename is given.\n"
   exit
fi

extent=$(echo ${1,,} | cut -f 2 -d '.')
if [ "$extent" != "mp3" ]
  then
   echo -e "\nInput file must be .mp3\n"
   exit
fi

if [ ! -z $2 ]
  then
    outname="${2%.*}.ul"
  else 
    outname="${1%.*}.ul"
fi
echo -e "\nConverting $1 to $(pwd)/$outname in Asterisk/Allstar format"
#sox -V2 $1 -r 8000 -c 1 -t ul $outname 
ffmpeg -i $1 -ar 8000 -ac 1 -ab 64 -f mulaw $outname -map 0:0 -map 0:0
echo -e "\nCONVERSION COMPLETE\n\nUse Asterisk localplay or playback wihout the extent to play\n"
echo -e "EXAMPLE - asterisk -rx \"rpt localplay <node> `pwd`/${outname%.*}\"\n" 

while true; do
    read -p "Would you like to test play the $outname file now [y/n] - " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit;;
      * )     exit;;
    esac
done

read -p "Enter the node number to play on: " node
if [ -z $node ]
  then
    echo -e "\nNo node given\n"
    exit
fi
echo -e "\nPlaying $outname locally to node $node\n"
asterisk -rx "rpt localplay $node `pwd`/${outname%.*}"






