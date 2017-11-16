#!/usr/bin/perl -w

use strict;
use warnings;
use 5.022;
use File::Basename;


open(MIMETYPES, '/etc/mime.types');

$0 = basename($0);

my $type = $ARGV[0] || die "\nUsage: $0 sometype\n\n";

my $output = "";

while( my $line = <MIMETYPES> ) {

    if ( $line =~ /^$type.*\t/ ) {

        $line =~ s/ |\t+/~/;
        $line =~ s/\s/\|/;
        $line =~ s/.+~//;
        $line =~ s/\n/\|/;
        $output = "${output}${line}"

    }
}

$output =~ s/\|$//;
print "$output"
