package Tk::TextANSIColor;

use strict;

require Tk;
require Tk::Text;

use Term::ANSIColor;

use vars qw/ $VERSION /;
$VERSION = '0.11';

# Inherit from Tk::Text
use base qw(Tk::Text);

# Construct the new widget
Construct Tk::Widget 'TextANSIColor';

# Setup some local (my'ed) variables that contain the
# control codes. Set up hashes which have keys of the control
# codes and values containing the actual color (the TAG).
# Currently retrieve these from Term::ANSIColor module.

my (%fgcolors, %bgcolors);
my $clear = color('clear');  # Code to reset control codes

my $code_bold = color('bold');
my $code_uline= color('underline');
my @colors = qw/black red green yellow blue magenta cyan white/;
for (@colors) {
  my $fg = color($_);
  my $bg = color("on_$_");

  $fgcolors{$fg} = "ANSIfg$_";
  $bgcolors{$bg} = "ANSIbg$_";
}


# Initialise class.
# This effectively means create a whole load of Tag shortcuts
# that can be used on this widget

sub InitObject {
  my ($widget, $args) = @_;

  # Initialise base class
  $widget->SUPER::InitObject($args);

  # Setup tags
  # colors
  for (@colors) {
    $widget->tagConfigure("ANSIfg$_", -foreground => $_);
    $widget->tagConfigure("ANSIbg$_", -background => $_);
  }
  # Underline
  $widget->tagConfigure("ANSIul", -underline => 1);
  $widget->tagConfigure("ANSIbd", -font => [-weight => "bold" ]);

#  return $widget;
}



# Sub-classed insert method
# We replace ANSI color codes with Text tags

sub insert {

  my $self= shift;  # The widget reference
  my $pos = shift;  # The position to insert
  my @userstuff = @_; # Strings and tags

  # This is the array containing text and tags pairs
  # We pass this to SUPER::insert 
  # as (POS, string, [tags], string, [tags]....)
  # insert_array contains string,[tags] pairs
  my @insert_array = ();

  # Need to loop over @userstuff
  # extracting out the text string and any user supplied tags.
  # note that multiple sets of text strings and tags can be supplied
  # as arguments to the insert() method, and we have to process
  # each set in turn.
  # Use an old-fashioned for since we have to extract two items at 
  # a time

  for (my $i=0; $i <= $#userstuff; $i += 2) {

    my $text = $userstuff[$i];
    my $utags = $userstuff[$i+1];
    
    # Store the usertags in an array, expanding the
    # array ref if required
    my @taglist = ();
    if (ref($utags) eq 'ARRAY') {
      @taglist = @{$utags};
    } else {
      @taglist = ($utags);
    }

    # Split the string on control codes
    # returning the codes as well as the strings between
    # the codes
    # Note that this pattern also checks for the case when
    # multiple escape codes are embedded together separated
    # by semi-colons.
    my @split = split /(\e\[(?:\d{1,2};?)+m)/, $text;

    # Array containing the tags to use with the insertion
    # Note that this routine *always* assumes the colors are reset
    # after the last insertion. ie it does not allow the colors to be 
    # remembered between calls to insert(). 
    my @ansitags = ();

    # Current text string
    my $cur_text = undef;

    # Now loop over the split strings
    for my $part (@split) {

      # If we have a plain string, just store it
      if ($part !~ /^\e/) {
	$cur_text = $part;
      } else {
	# We have an escape sequence
	# Need to store the current string with required tags
	# Include the ansi tags and the user-supplied tag list
	push(@insert_array, $cur_text, [@taglist, @ansitags])
	  if defined $cur_text;

	# There is no longer a 'current string'
	$cur_text = undef;

	# The escape sequence can have semi-colon separated bits
	# in it. Need to strip off the \e[ and the m. Split on
	# semi-colon and then reconstruct before comparing
	# We know it matches \e[....m so use substr

	# Only bother if we have a semi-colon

	my @escs = ($part);
	if ($part =~ /;/) {
	  my $strip = substr($part, 2, length($part) - 3);

	  # Split on ; (overwriting @escs)
	  @escs = split(/;/,$strip);

	  # Now attach the correct escape sequence
	  foreach (@escs) { $_ = "\e[${_}m" }
	}

	# Loop over all the escape sequences
	for my $esc (@escs) {

	  # Check what type of escape
	  if ($esc eq $clear) {
	    # Clear all escape sequences
	    @ansitags = ();
	  } elsif (exists $fgcolors{$esc}) {
	    # A foreground color has been specified
	    push(@ansitags, $fgcolors{$esc});
	  } elsif (exists $bgcolors{$esc}) {
	    # A background color
	    push(@ansitags, $bgcolors{$esc});
	  } elsif ($esc eq $code_bold) {
	    # Boldify
	    push(@ansitags, "ANSIbd");
	  } elsif ($esc eq $code_uline) {
	    # underline
	    push(@ansitags, "ANSIul");
	  } else {
	    print "Unrecognised control code - ignoring\n";
	    foreach (split //, $esc) {
	      print ord($_) . ": $_\n";
	    }
	  }
	
	}
      }
    }

    # If we still have a current string, push that onto the array
    push(@insert_array, $cur_text, [@taglist, @ansitags])
      if defined $cur_text;

  }

  # Finally, insert  the string
  $self->SUPER::insert($pos, @insert_array)
    if $#insert_array > 0;

}

1;

__END__


=head1 NAME

Tk::TextANSIColor - Tk::Text widget with support for ANSI color escape codes

=for pm Tk/TextANSIColor.pm

=for category Derived Widgets

=head1 SYNOPSIS

  use Tk::TextANSIColor;

  $wid = $mw->TextANSIColor(?options,...?);

  $wid->insert($pos, $string, ?taglist, ?string, ?taglist);

  use Term::ANSIColor; 
  $red = color('red');  # Retrieve color codes
  $bold = color('bold');
  $wid->insert('end', "$red red text $bold with bold\n");

=head1 DESCRIPTION

This widget extends the capabilities of the standard Tk::Text
widget by adding support for ANSI color escape codes. When these
escape codes are detected they are replaced by equivalent tags.

This widget was developed to solve the problem associated with
driving a scrolling status display on a GUI as well as a status display 
going to an Xterm without having to know whether an xterm
or Tk window is receiving the status information. Mainly used
in conjunction with a tied filehandle:

  $text = $MW->TextANSIColor->pack;
  tie *TEXT, "Tk::TextANSIColor", $text;

  $info = colored("Some information\n", 'red');

  # Print information to all filehandles
  print TEXT $info
  print STDOUT $info

Currently the Term::ANSIColor module is required in order
to decode the escape codes (and probably to generate them in
the first place).

=head1 TAGS

This widget uses the following tags internally:

  ANSIbd - bold
  ANSIul - underline
  ANSIfgCOL - foreground color
  ANSIbgCOL - background color

where COL can be one of black, red, green, yellow, blue, magenta, 
cyan or white.

If required, the tags can be altered after the widget is created by
using the tagConfigure() method. e.g.:

  $widget->tagConfigure('ANSIfgred', -foreground => 'blue');

in order to make 'red' appear 'blue'.

=head1 REQUIREMENTS

This modules requires the C<Term::ANSIColor> module.
The C<Tk> module is also required.

=head1 SEE ALSO

L<Tk::Text>, L<Term::ANSIColor>

=head1 AUTHOR

Tim Jenness (E<lt>F<t.jenness@jach.hawaii.edu>E<gt>)

=head1 COPYRIGHT

Copyright (c) 1999-2000 Tim Jenness. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
