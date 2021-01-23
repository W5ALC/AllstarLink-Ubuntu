#! /bin/bash
if [ -e /var/run/asterisk.ctl ]
then
	echo "Asterisk is currently running!"
else
	echo "Starting asterisk..."
	/usr/sbin/safe_asterisk
fi

