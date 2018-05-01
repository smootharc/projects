#!/bin/bash

if ! [ $EUID = 0 ]
then
    sudo "$0" "$@"
    exit
fi

#ppa for pan
add-apt-repository -y ppa:klaus-vormweg/pan
#ppas for sabnzbdplus
add-apt-repository -y ppa:jcfp/nobetas
add-apt-repository -y ppa:jcfp/sab-addons

apt update

apt-get -y install pan sabnzbdplus par2-tbb
