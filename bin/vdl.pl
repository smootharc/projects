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
        push @images, "$ctime\x00$name\n";
    }
}

@images = sort @images;

s/.*\x00// for @images;

if (scalar @images) {

    my $playlist  = new File::Temp( UNLINK => 1 );
    
    print $playlist $_ for @images;

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
        push @videos, "$ctime\x00$name\n";
    }
}

@videos = sort @videos;

s/.*\x00// for @videos;

if (scalar @videos) {

    my $playlist  = new File::Temp( UNLINK => 1 );
    
    print $playlist $_ for @videos;

    system "mpv", "--really-quiet", "--playlist=$playlist";

} else {
    
    print "No videos found!\n";
}

my $time = $ARGV[0] // '';

exec "ddl", $time;

