#!/bin/perl

#!/usr/bin/parallel --shebang-wrap -r /usr/bin/perl

use 5.40.2;
use Cwd;
use File::Find;
use File::MimeInfo;
use File::Temp;
use Getopt::Long qw(:config pass_through);
use vars qw($files $minutes $sort $help @files %mtimes @args);
use English;

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

GetOptions('files:s' => \$files,
           'minutes:i' => \$minutes,
           'sort:s' => \$sort,
           'help' => \$help)
         or die(help(1));


help if $help;

# say for @ARGV;
# say $sort;
# sleep 5;
# newest, oldest, alphabetical, reverse alphabetical
my @sortoptions = ("n", "o", "a", "r");

unless (length($sort) == 1 and (grep /^$sort$/, @sortoptions)) {

  help(1);
  
}

while (<@ARGV>) {

  unless (-d or -f) { next }

  push @args, $ARG;

}

# say for @args;

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

# @files = sort {lc($a) cmp lc($b) } @files;

# foreach my $key (sort { lc($b) cmp lc($a) } keys %mtimes) {

#   print($key, " ", $mtimes{$key}, "\n")
  
# }

# my @values = ( sort { $b cmp $a } values %mtimes )

if ( $sort eq "a" ) {

  my @files= sort {lc($a) cmp lc($b) } @files;

  foreach ( @files) {

    say($ARG);

  }

  exit;

} elsif ( $sort eq "r" ) {

  @files = sort {lc($b) cmp lc($a) } @files;

  foreach ( @files ) {

    say($ARG);

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
