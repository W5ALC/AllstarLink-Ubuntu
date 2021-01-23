#! /bin/bash
if [ -e /var/run/asterisk.ctl ]
then
        echo "Stopping Asterisk..."
        /sbin/asterisk -rx 'stop now'
else
        echo "Asterisk is not running!"
fi
#
/sbin/killall safe_asterisk &>/dev/null
/bin/sleep 1
/sbin/killall asterisk &>/dev/null
/bin/rm -f /var/run/asterisk.ctl /var/run/asterisk.pid
