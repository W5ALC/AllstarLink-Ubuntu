#!/usr/bin/perl
#

use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;
cls();
#    print setmode(1), setkey('a','b');
#    print "40x25 mode now, with 'a' mapped to 'b'.";
#    <STDIN>; resetkey; setmode 3; cls;
print setmode(3);
    locate 10, 10; print " This is (10,10)", savepos;
    print locate(24,60), " This is (24,60)"; loadpos;
    print down(2), clline, " This is (3,15)\n";

#    setscroll 1, 20;

    color 'black on white'; clline;
    print "This line is black on white.\n";
    print color 'reset'; print "This text is normal.\n";

    print colored ("This text is bold blue.\n", 'bold blue');
    print "This text is normal.\n";
    print colored ['bold blue'], "This text is bold blue.\n";
    print "This text is normal.\n";

    use Term::ANSIScreen qw/:constants/; # constants mode
    print BLUE ON GREEN . "Blue on green.\n";

    $Term::ANSIScreen::AUTORESET = 1;
    print BOLD GREEN . ON_BLUE "Bold green on blue.", CLEAR;
    print "\nThis text is normal.\n", RESET;

    # Win32::Console emulation mode
    # this returns a Win32::Console object on a Win32 platform
#    my $console = Term::ANSIScreen->new;
#    $console->Cls;      # also works on non-Win32 platform

