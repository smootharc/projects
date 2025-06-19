#!/bin/perl

#!/usr/bin/parallel --shebang-wrap -r /usr/bin/perl

use 5.40.2;
use Cwd;
use File::Find;
use File::MimeInfo;
use File::Temp qw/ tempfile /;
use File::Basename;
use Getopt::Long;
use English;
use vars qw(@args @files @videos @images $files $minutes $sort $help %mtimes);

sub help {
  
  say "Usage: vd [OPTION]... [DIRECTORY]... [default: ~/Downloads] [FILE]...

    Display images and videos contained in DIRECTORYs and FILEs where each absolute pathname contains some regex.
    If no regex is given display all.  Options and arguments may appear in any order. 
  
    The options are:
  
    -f[=:]TEXT           Display only files containing the regex TEXT in the absolute pathname of the file.
                         If any of TEXT contain capital letters the search will be case sensitive.
    -m[=:]INTEGER        Delete files in the ~/Downloads folder older than INTEGER minutes.
    -s[=:][n,o,a,r]      Sort by time, newest first or time, oldest first. Name alphabetically or name alphabetically reversed. [default: n, newest first]
    -h                   Show this message and exit.
  
    An equal sign or a colon separates the option from the option value.";

   if ( @ARG ) { 

        exit $ARG[0];

   } else {

      exit

   }
  
}

$files = '.';

$minutes = -1;

$sort = 'n';

my $valid_option = GetOptions(
  'files:s' => \$files,
  'minutes:i' => \$minutes,
  'sort:s' => \$sort,
  'help' => \$help);

unless ( $valid_option ) { print "\n"; help 1};

my @sortoptions = ("n", "o", "a", "r");

unless (length($sort) == 1 and (grep {/^$sort$/i} @sortoptions)) {

  help(1);
  
}

help if $help;

while (<@ARGV>) {

  unless (-d or -f) { say basename($0), ": $ARG is not a file or directory."; exit 1 }

  push @args, $ARG;

}

unless (@args) {

  @args = (glob("~/Downloads"))
  
}

foreach (@args) {

  if (-f and /$files/) { 

    push(@files, "$ARG\n");

    next;
  
  }

  if (-d) {

    push(@files, `fd '$files' -t f -p $ARG`);
    
  }

}

chop(@files);

if ( $sort eq "a" ) {

  my @files= sort {lc($a) cmp lc($b) } @files;

  

  foreach ( @files) {

    say($ARG, mimetype($ARG));

  }

  exit;

} elsif ( $sort eq "r" ) {

  @files = sort {lc($b) cmp lc($a) } @files;

  foreach ( @files ) {

    say($ARG, mimetype($ARG));

  }

  exit;

}

foreach (@files) {

  my $ctime = (stat($ARG))[9];

  $mtimes{$ARG} = $ctime;
  # print($ctime, "\t", $_, "\n");

}

if ( $sort eq "o" ) {

  foreach my $file (sort { $mtimes{$a} cmp $mtimes{$b} } keys %mtimes) {

  print($file, " ", $mtimes{$file}, "\n")
  
}

} else {

  foreach my $file (sort { $mtimes{$b} cmp $mtimes{$a} } keys %mtimes) {

    print($file, " ", $mtimes{$file}, "\n")
  
  }

}


