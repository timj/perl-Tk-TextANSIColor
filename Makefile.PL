# perl makefile for Tk::TextANSIColor

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Tk::TextANSIColor',
    'VERSION_FROM'   => 'TextANSIColor.pm',
    'PREREQ_PM' => { 
	Term::ANSIColor => '1.00',
	Tk => 0
	},
    'dist'      => { COMPRESS => "gzip -9f"},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM => 'TextANSIColor.pm',
      AUTHOR     => 'Tim Jenness <t.jenness@jach.hawaii.edu>') : ()),
    );

