#!/usr/bin/env perl
use 5.40.2;

use List::Util qw(sum);

my $days = `sqlite3 -batch ~/.local/share/medical.db '.headers off' 'select count(*) from weight'`;

my @food = `sqlite3 -batch ~/.local/share/medical.db '.headers off' "select food from weight"`;

# my @vodka = grep { /Vodka/ and /\d+/} @food;
my @vodka = grep { /Vodka \d+/} @food;

foreach ( @vodka ) { s/\D*//;  s/\D.*//; }

my $ml = sum @vodka;

my $mlperday = $ml / $days;

printf '%d %s', "$mlperday", "ml/day.\n";
