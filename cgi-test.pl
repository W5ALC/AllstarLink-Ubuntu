#!/usr/bin/perl
#use CGI::Carp qw(fatalsToBrowser);

use CGI qw(:cgi-lib :standard);  # Use CGI modules that let people read data passed from a form


	&ReadParse(%in);                 # This grabs the data passed by the form and puts it in an array
	
	$node = $in{"node"};             # Get the user's name and assign to variable
#	$preference = $in{"choice"};     # Get the choice and assign to variable
	
	                                 # Start printing HTML document
print<<EOSTUFF;
Content-type: text/html

<HTML>
<BODY BGCOLOR=WHITE TEXT=BLACK>
<H1> The node is $node </H1>
<BR>
EOSTUFF

print "this is a test \n";
print "<BR>and another test \n";
print "<BR>";

print<<EOF;
</BODY>
</HTML>
EOF
	
