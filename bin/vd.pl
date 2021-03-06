#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Temp;
use File::MimeInfo;
use File::stat;
use Cwd 'abs_path'; 
use 5.22.1;

sub processdir
{

    my @return;

    opendir( my $fh, "$_[0]" );

    while (readdir $fh) {

        if ( $_ eq "." || $_ eq ".." || -l $_ || /.*iso$/) { next }

        my $fullname = "$_[0]/$_";

        if ( -d $fullname ) { 
            
            push @return, processdir( $fullname )
        
        } else {

            push @return, "$fullname";
        
        }

    }

    closedir $fh;

    return( @return );
} 

sub filesoftype
{
    my @args = @_;
    my $filetype = pop @args;
    my @return;

    foreach(@args) {

        if ( mimetype($_) =~ /$filetype/ ) {
            
            my $ctime = stat($_)->ctime;
            
            push @return, "$ctime\x00$_\n";

        }

    }

    @return = sort {$b cmp $a} @return;

    s/.*\x00// for @return;

    return( @return );
}

my $directory = glob $ARGV[0] // glob "~/Downloads";

my $time = $ARGV[1] // '';

if ( -d $directory ) {
    
    $directory = abs_path($directory);

} else {

    if ( $directory =~ /^\d+$/ ) {
        
            $time = $directory;
            $directory = glob "~/Downloads";

        } else {

            $0 =~ s/.*\///;
            die "\nUsage: $0 [ValidDirectory] [Time]\n\n";

        }

}

my @files = processdir( $directory );

my @images = filesoftype( @files, "image" );

my @videos = filesoftype( @files, "video" );

#print @images;

if ( scalar @images ) {

    my $playlist = new File::Temp( UNLINK => 1 );

    print $playlist $_ for @images;

    system "feh", "-dqFf", $playlist;

} else {

    print "No images found!\n";

}

if ( scalar @videos ) {

    my $playlist = new File::Temp( UNLINK => 1 );

    print $playlist "#EXTM3U\n";

    print $playlist $_ for @videos;

    system "mpv", "--really-quiet", $playlist;

} else {

    print "No videos found!\n"

}


if ( $directory eq "/home/paul/Downloads" ) {

    exec "ddl", $time;

} else {

    print "Not Downloads directory. Nothing deleted.\n";

}
