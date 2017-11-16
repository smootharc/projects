#!/usr/bin/perl

use strict;
use warnings;

my $date = "";

while(<>) {

    chomp;

    if ( length($_) > 0 ) {

        my @chunks = split ;

        if ( $date ne "$chunks[0]" ) {

            print "\n$chunks[0]\n\n";

        }
        
        print "\t$chunks[1] ";

        my $line = join ' ', @chunks[3..$#chunks];

        print "$line\n";

        $date = "$chunks[0]";

    }

}


