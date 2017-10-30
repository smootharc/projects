#!/usr/bin/env bash
#tasksel install xubuntu-core
#tasksel install openssh-server
#Latest mpv requires the following ppa.
add-apt-repository ppa:mc3man/mpv-tests
apt update
apt install \
xfce4-goodies ranger mpv feh htop glances desktop-webmail \
firefox system-config-printer-gnome xfce4-pulseaudio-plugin \
pan sabnzbdplus zathura a2ps fossil dwww ncdu rlwrap smartmontools

#dwww returns cgi errors fix whith sudo a2enmod cgi then sudo service apache2 restart
pushd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
apt install -f
apt autoremove
popd
