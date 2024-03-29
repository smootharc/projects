#!/bin/bash

rmempty() {

    find ~/Downloads -mindepth 1 -type d -empty -delete 2> /dev/null

}

help() {

    echo -e "\nUsage: $(basename "$0") [M]\n\nAll files in the ~/Downloads directory older than M minutes will be deleted.  Empty directories will be deleted.\nM must be an integer greater than or equal to zero.\n"
    exit "$1"
    
}

trap rmempty EXIT

[[ $1 == "-h" ]] && help 0

[[ $1 == "" ]] && exit 0

if [[ $1 =~ ^[[:digit:]]+$ ]]; then

    find ~/Downloads -mindepth 1 -cmin +"$1" -delete 2> /dev/null
    exit 0

else

    help 1

fi
