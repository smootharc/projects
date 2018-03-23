#!/bin/bash

if ! [ $EUID = 0 ]
then
    read -p "Will run as root. Press a key."
    sudo "$0" "$@"
    exit
fi

#Latest mpv requires the following ppa.
add-apt-repository ppa:mc3man/mpv-tests
#ppa for pan
add-apt-repository ppa:klaus-vormweg/pan
#ppas for sabnzbdplus
add-apt-repository ppa:jcfp/nobetas
add-apt-repository ppa:jcfp/sab-addons
#ppa for googler and ddgr
add-apt-repository ppa:twodopeshaggy/jarun

apt update

apt install \
byobu xfce4-goodies catfish ranger mpv feh htop glances desktop-webmail moreutils configure-debian \
firefox system-config-printer-gnome xfce4-pulseaudio-plugin pinfo clementine hddtemp googler blueman pulseaudio-module-bluetooth \
pan sabnzbdplus zathura zathura-ps a2ps fossil dwww ncdu rlwrap smartmontools backintime-qt4 sshfs \
tcl8.6 tcllib tkinspect tcl8.6-doc tk8.6 tk8.6-doc tcl-tclreadline expect libsqlite3-tcl lightdm-gtk-greeter-settings exim4

#dwww returns cgi errors fix whith sudo a2enmod cgi then sudo service apache2 restart.  Still need to edit a perl script to fix this completely.  I forget exactly what it is.
a2enmod cgi
service apache2 restart

pushd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
popd
apt install -f
apt autoremove

#Just accept all of the defaults presented by the following program.
dpkg-reconfigure exim4-config
