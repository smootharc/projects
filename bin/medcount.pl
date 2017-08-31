#!/usr/bin/perl -w

use strict;
use warnings;
use DateTime;

my $date = "";
my $time = "";
my $text = "";
my $currentdate = "";
my $reportdate = localtime();

print $#ARGV + 1, " ";
print "@ARGV\n";
#my $result = `jrnl \@medications --export markdown`;

#open(my $result, '-|', 'jrnl @medications --export text') or die $!;

#while( my $record = <$result> ) {

#    chomp $record; 

#}


