#!/bin/bash

if ! [ $EUID = 0 ]
then
    read -p "Will run as root. Press a key."
    sudo "$0" "$@"
    exit
fi

#Latest mpv requires the following ppa.
add-apt-repository -y ppa:mc3man/mpv-tests 
#ppa for googler and ddgr
add-apt-repository -y ppa:twodopeshaggy/jarun

apt update

apt-get -y install \
byobu ranger mpv feh glances moreutils configure-debian openssh-server apt-file \
firefox pinfo hddtemp googler ddgr pdd gcalcli vim-gtk xmonad dmenu restic \
zathura zathura-ps a2ps fossil dwww rlwrap smartmontools sshfs sqlite3 sqlite3-doc dict \
tcl8.6 tcllib tkinspect tcl8.6-doc tk8.6 tk8.6-doc tcl-tclreadline expect libsqlite3-tcl exim4

read -t 60 -n 1 -p "Press y to install pan and sabnzbdplus."

if [[ $REPLY =~ y|Y ]]; then

    #ppa for pan
    add-apt-repository -y ppa:klaus-vormweg/pan
    #ppas for sabnzbdplus
    add-apt-repository -y ppa:jcfp/nobetas
    add-apt-repository -y ppa:jcfp/sab-addons
    apt-get -y install pan sabnzbdplus par2-tbb

fi

#dwww returns cgi errors fix whith sudo a2enmod cgi then sudo service apache2 restart.  Still need to edit a perl script to fix this completely.  I forget exactly what it is.
a2enmod cgi
service apache2 restart

pushd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
popd
apt install -f
apt autoremove

#Just accept all of the defaults presented by the following program except the mailbox location.
dpkg-reconfigure exim4-config

echo "Background color for desktop and login screen is #152233."
