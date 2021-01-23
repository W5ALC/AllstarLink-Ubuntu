# ! /bin/bash

# Truncate selected logs 
#
# D. Crompton 9/2015
#
# To add files that are check use these parameters
# and add or modifiy the current files listed below.
#
# FILE= full path and file name
# maximumsize= maximum size in bytes
# text_truncate= text to echo and log if truncated
# text_ok= text to echo and log if size OK
#
# This script can be run manually or 
# with a cron at a minimum of once daily
#
# 05 04 * * * /usr/local/sbin//truncate_logs

function truncate_log {

actualsize=$(wc -c <"$FILE")
if [ $actualsize -ge $maximumsize ]; then
    
    tail -c $maximumsize $FILE > /tmp/out.tmp
    cp /tmp/out.tmp $FILE
    rm -rf /tmp/out.tmp
    echo $text_truncate
    logger $text_truncate
else
    echo $text_ok
    logger $text_ok
fi
}

# Begin main script
#
# Add or change definitions below for 
# files to monitor. Files shown should
# typically be monitored in a busy 
# Allstar system.

FILE="/var/log/httpd/access_log"
maximumsize=300000
text_truncate="LOG - httpd access_log size adjusted"
text_ok="LOG - httpd access_log size OK"
truncate_log

FILE="/var/log/asterisk/messages"
maximumsize=300000
text_truncate="LOG - Asterisk message log size adjusted"
text_ok="LOG - Asterisk message log size OK"
truncate_log

FILE="/var/log/httpd/error_log"
maximumsize=20000
text_truncate="LOG - httpd error_log size adjusted"
text_ok="LOG - httpd error_log size OK"
truncate_log

