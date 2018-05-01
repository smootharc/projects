#!/bin/bash

if ! [ $EUID = 0 ]
then
    sudo "$0" "$@"
    exit
fi

pushd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
popd
apt install -f
apt autoremove
