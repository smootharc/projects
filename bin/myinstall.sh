#!/usr/bin/env bash
sudo su
tasksel install xubuntu-core
tasksel install openssh-server
apt-get install xfce4-goodies ranger mpv feh htop glances desktop-webmail alarm-clock-applet firefox system-config-printer-gnome
pushd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
apt-get install -f
apt autoremove
popd
