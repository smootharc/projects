#!/bin/bash

if ! [ $EUID = 0 ]
then
    sudo "$0" "$@"
    exit
fi

#Latest mpv requires the following ppa.
add-apt-repository -y ppa:mc3man/mpv-tests 
#ppa for googler and ddgr
add-apt-repository -y ppa:twodopeshaggy/jarun

apt update

apt-get -y install \
tmux sakura ranger mpv feh glances moreutils configure-debian openssh-server apt-file xfce4-goodies \
firefox pinfo hddtemp googler ddgr pdd pip vim-gtk herbstluftwm suckless-tools stalonetray restic \
dex zathura zathura-ps a2ps fossil dwww rlwrap smartmontools sshfs sqlite3 sqlite3-doc dict system-config-printer-gnome \
tcl8.6 tcllib tkinspect tcl8.6-doc tk8.6 tk8.6-doc tcl-tclreadline expect libsqlite3-tcl exim4 megatools blueman
