#!/usr/local/bin/perl -w

# Test of Tk::ROTextANSIColor
#  This test requires that Tk widgets can be opened
#  This test will launch a Tk widget and write to it using
#  ANSI color codes. Unfortunately, it can not check that the
#  codes were displayed correctly......

# Also tests the tied version

#  In order to do this it simply keeps the window up for a few seconds
#  in case anyone needs to look at it

# Copyright (C) 2000 Tim Jenness and the Particle Physics and Astronomy
# Research Council. All Rights Reserved.

use strict;
use Test;

BEGIN { plan tests => 13 }

use Tk;
use Tk::ROTextANSIColor;
use Term::ANSIColor;


ok(1);


# Create new Tk

my $MW = MainWindow->new();

ok( defined $MW );

# Abort if this is not working

die "Unable to create Tk object. Not on a graphics display??"
	unless defined $MW;

# Create a simple text wiget

my $text = $MW->ROTextANSIColor->pack;

ok( defined $text );

# We dont want to run an event loop - just do an update
$MW->update;

# Some normal text
doprint("Normal text, no ANSI codes\n");
ok(1);

# Some colored text

foreach (qw/ red green blue magenta yellow cyan bold underline /) {
  doprint( colored("This is a test of $_\n", "$_") );
  ok(1);
}

# Now try a tie
use vars qw/ *HDL /;
my $tie = tie(*HDL, ref($text), $text);

ok(defined $tie);

# Cant yet test the return status of a print from a tied text widget
# since it always returns undef (as of v800.021).

print HDL "Some normal text from a tied handle.\n";
print HDL colored("Some tied text in red\n", 'red');

$tie->update;

sleep 3;


exit;


# Sub to print a string to the widget and update the display
# could do it with a tied filehandle instead

sub doprint {
  my $str = shift;
  my $ret = $text->insert('end', $str);
  $text->update;
}



