#!/usr/bin/perl

use warnings;
use strict;
use File::Temp;
use File::Find;
use File::MimeInfo;
use File::stat;

my $dir = glob '~/Downloads';

my @images;

find(\&images, $dir);

sub images
{
    if (mimetype($_) =~ /image/)
    {
        my $name = $File::Find::name;
        my $ctime = stat($name)->ctime;
        push @images, "$ctime\x01$name\n";
    }
}

@images = sort @images;

s/.*\x01// for @images;

if (scalar @images) {

    my $playlist  = new File::Temp( UNLINK => 1 );
    
    foreach my $image (@images) {
        
        print $playlist $image;

    }

    system "feh", "-dqFf", $playlist;

} else {
    
    print "No images found!\n";
}
    
my @videos;

find( \&videos, $dir);

sub videos
{
    if (mimetype($_) =~ /video/)
    {
        my $name = $File::Find::name;
        my $ctime = stat($name)->ctime;
        push @videos, "$ctime\x01$name\n";
    }
}

@videos = sort @videos;

s/.*\x01// for @videos;

if (scalar @videos) {

    my $playlist  = new File::Temp( UNLINK => 1 );
    
    foreach my $video (@videos) {
        
        print $playlist $video;

    }

    system "mpv", "--really-quiet", "--playlist=$playlist";

} else {
    
    print "No videos found!\n";
}

my $time = $ARGV[0] // '';

exec "ddl", $time;

