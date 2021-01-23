#!/usr/bin/perl
#
# say24time.pl  - D. Crompton, WA3DSP 9/20/2014
#

# ---------------
# Copyright (C) 2015, 2016, 2017 Doug Crompton, WA3DSP
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
# ---------------
#
# Modified from original saytime.pl to say 24 hour time
# Time is said as  23 hours 49 minutes Eastern Daylight Time
# or  zero hours one minute etc.
# The zone is optional
#
# if you want to have the standard *81 in Allstar say the 24 hour
# time add or modifying the following line in your rpt.conf 
# under the functions context.
#  81=cmd,/etc/asterisk/local/saytime24.pl 
#
# hamvoip packages use *82 by default for 24 hour time.
#
# Perl program to emulate and replace the app_rpt time of day 
# function call. This allows for easy changes and also volume and 
# tempo modifications.
#
# Call this program from a cron job and/or rpt.conf when you want to 
# hear the time on your local node
#
# Example Cron job to say the time on the hour every hour:
#   Change directory and times to your liking
#
# 00 0-23 * * * cd /etc/asterisk/wa3dsp; perl saytime.pl > /dev/null
#
# Note in this program all sound files must be .gsm
# All combined soundfiile formats need to be the same. 
# This could be changed if necessary. To use this with the
# stock Acid release you will need to convert a couple
# of the ulaw files in the /sounds/rpt directory to .gsm
# using sox or another conversion program and place them
# in the sounds directory for use by this program.
# The good-xxx.gsm files and the-time-is.gsm were created
# from ulaw files in the /sounds/rpt directory.
# An example sox command to do this is -
#
#  sox -t ul -r 8000 /var/lib/asterisk/sounds/rpt/thetimeis.ulaw /var/lib/asterisk/sounds/the-time-is.gsm
#
# Added optional weather condition and temperature statement after time 
# WA3DSP 4/2017

# For weather condtions and temperature Use:  saytime <locationID> <node>
# Location ID is either your zipcode or nearest airport three letter designator
# This REQUIRES the /usr/local/sbin/weather.sh script to run

use strict;
use warnings;
#
select (STDOUT);
$| = 1;
select (STDERR);
$| = 1;
#
# Replace with your output directory
my $outdir = "/tmp";
#
my $ampm = "PM";
my $base = "/var/lib/asterisk/sounds";
#
# Specify whether zone should be announced (Y|N)
my $sayzone="N";
#
# Replace with your zone - eastern, central, mountain, pacific, etc.i
# use lowercase
my $zone="eastern";
#
my $FNAME,my $error,my $day,my $hour,my $min,my $mynode,my $wx,my $wxid;
my @proglist,my @list,my $sec,my $wday,my $mon,my $year,my $greet;
my $year_1900,my $isdst,my $yday,my $min1,my $min10,my $localwxtemp10,my $localwxtemp1;
my $hour1, my $hour10;
#
# command-line args
my $num_args = $#ARGV + 1;
# if arg number is only 1, then arg = node, else arg1 is wx ID, arg2 is node

if ($num_args == 1) {
    $mynode=$ARGV[0];
    $wx = "NO";
    $error=0;
} elsif ($num_args == 2) {
    $wxid = ($ARGV[0]); 
    $wx = "YES";
    $mynode=$ARGV[1];
    $error=0;
} else {
    $error=1;
}

if ($error == 1) {
  print "\nUsage: saytime.pl [<locationid>] nodenumber\n";
  exit;
}

my $localwxtemp="";

if (! -f "/usr/local/sbin/weather.sh" ) {
     $wx="NO";
}

if ($wx eq "YES") {

  @proglist = ("/usr/local/sbin/weather.sh " . $wxid);
  system(@proglist);

  if (-f "$outdir/temperature") { 
    open(my $fh, '<', "$outdir/temperature") or die "cannot open file";
    {
        local $/;
        $localwxtemp = <$fh>;
    }
    close($fh);
  } else {
    $localwxtemp="";
  }
}

#
@list = ($sec,$min,$hour,$day,$mon,$year_1900,$wday,$yday,$isdst)=localtime;
#
#
if ($hour < 12) { 
  $greet = "Good Morning"; 
  $ampm = "AM";
  $FNAME = $base . "/good-morning.gsm ";
 }
elsif ($hour >= 12 && $hour < 18) { 
  $greet = "Good Afternoon";
  $FNAME = $base . "/good-afternoon.gsm ";
 }
else { 
  $greet = "Good Evening";
  $FNAME = $base . "/good-evening.gsm ";
}

$FNAME = $FNAME . $base . "/the-time-is.gsm ";

if ($hour == 0) {
	$FNAME = $FNAME . $base . "/digits/0.gsm ";
}
elsif ($hour > 20) {
	$hour10 = substr ($hour,0,1) . "0";
	$hour1 = substr ($hour,1,1);
	$FNAME = $FNAME . $base . "/digits/" . $hour10 . ".gsm ";
        $FNAME = $FNAME . $base . "/digits/" . $hour1 . ".gsm ";
 }
else {
	$FNAME = $FNAME . $base . "/digits/" . $hour . ".gsm ";
}

# Commented - no hour.gsm in sounds
#if ($hour == 1) {
#	$FNAME = $FNAME . $base . "/hour.gsm ";
#} 
#else {
	$FNAME = $FNAME . $base . "/hours.gsm ";
#}

if ($min == 0) { 
	$FNAME = $FNAME . $base . "/digits/0.gsm ";
} 
else {
	if ($min < 10) {
		$FNAME = $FNAME . $base . "/digits/" . $min . ".gsm ";
	}
	elsif ($min < 20) {
		$FNAME = $FNAME . $base . "/digits/" . $min . ".gsm ";
	} else {
		$min10 = substr ($min,0,1) . "0";
		$FNAME = $FNAME . $base . "/digits/" . $min10 . ".gsm ";
		$min1 = substr ($min,1,1);
		if ($min1 > 0) {
			$FNAME = $FNAME . $base . "/digits/" . $min1 . ".gsm ";
		}
	}
} 

if ($min == 1) {
	$FNAME = $FNAME . $base . "/minute.gsm ";
}
else { 
	$FNAME = $FNAME . $base . "/minutes.gsm ";
}

if ($sayzone eq "Y") {
	$FNAME = $FNAME . $base . "/$zone.gsm ";
	if ($isdst) {
		$FNAME = $FNAME . $base . "/daylight.gsm ";
	}	
	else {
		$FNAME = $FNAME . $base . "/standard.gsm ";
	}
	$FNAME = $FNAME . $base . "/time.gsm ";
}

if ($wx eq "YES") {
    $FNAME = $FNAME . $base . "/silence/1.gsm ";

if (-e "$outdir/condition.gsm") {
    $FNAME = $FNAME . $base . "/weather.gsm ";
    $FNAME = $FNAME . $base . "/conditions.gsm ";
    $FNAME = $FNAME . "$outdir/condition.gsm ";
}
if ($localwxtemp ne "" ) {
    $FNAME = $FNAME . $base . "/wx/temperature.gsm ";

    if ($localwxtemp < -1 ) {
        $FNAME = $FNAME . $base . "/digits/minus.gsm ";
        $localwxtemp=int(abs($localwxtemp));
    } else {
        $localwxtemp=int($localwxtemp);
    }

    if ($localwxtemp > 100) {
        $FNAME = $FNAME . $base . "/digits/" . "1" . ".gsm ";
        $FNAME = $FNAME . $base . "/digits/" . "hundred" . ".gsm ";
        $localwxtemp=($localwxtemp-100);
    }

    if ($localwxtemp < 20) {
        $FNAME = $FNAME . $base . "/digits/" . $localwxtemp . ".gsm ";
    } else {
        $localwxtemp10 = substr ($localwxtemp,0,1) . "0";
        $FNAME = $FNAME . $base . "/digits/" . $localwxtemp10 . ".gsm ";
        $localwxtemp1 = substr ($localwxtemp,1,1);
        if ($localwxtemp1 > 0) {
          $FNAME = $FNAME . $base . "/digits/" . $localwxtemp1 . ".gsm ";
        }
    }
    $FNAME = $FNAME . $base . "/degrees.gsm ";
 }
}

# Following lines concatenate all of the files to one output file
#
@proglist = ("cat " . $FNAME . " > " . $outdir . "/current-time.gsm");
system(@proglist);
#
# Following lines process the output file with sox to lower the volume
# negative numbers lower than -1 reduce the volume - see Sox man page
# Other processing could be done if necessary
#
# REMOVED V1.5 - use telemetry levels
#
#@proglist = ("sox --temp /tmp " . $outdir . "/temp.gsm " . $outdir . "/current-time.gsm vol -0.35");
#system(@proglist);
#
# Say the time on the local node
#
@proglist = ("/usr/sbin/asterisk -rx \"rpt localplay " . $mynode . " " . $outdir . "/current-time\"");
system(@proglist);

# end of saytime.pl

