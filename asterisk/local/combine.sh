#! /bin/bash

cat   /var/lib/asterisk/sounds/letters/w.gsm   /var/lib/asterisk/sounds/letters/a.gsm   /var/lib/asterisk/sounds/digits/3.gsm   /var/lib/asterisk/sounds/letters/x.gsm   /var/lib/asterisk/sounds/letters/y.gsm   /var/lib/asterisk/sounds/letters/z.gsm /var/lib/asterisk/sounds/letters/p.gsm /var/lib/asterisk/sounds/letters/l.gsm /var/lib/asterisk/sounds/digits/80.gsm /var/lib/asterisk/sounds/digits/8.gsm /var/lib/asterisk/sounds/letters/dot.gsm /var/lib/asterisk/sounds/digits/5.gsm  >   /etc/asterisk/local/node-id.gsm  

# Combines Allison voice fragments to create a combined voice file.
# Look in the /var/lib/asterisk/sounds directory for filenames
# All mixed voice files must be of the same type - .ulaw, .gsm etc.
# and the output file must be of the same type. If you need
# to change file type use sox -
# Ex -  sox -t ul -r 8000 <input file>.ulaw <output file>.gsm
#
# Change the combined text above to your choice
# Change the output directory and filename to suit your needs.
#
# Make this script executable and run it to create combined audio file
#
# WA3DSP 11/2013

