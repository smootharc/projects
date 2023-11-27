#!/bin/sh

if [ -z "$1" ]; then

    echo "Usage: $(basename $0) [sshservername|directory]"

    exit 1  
fi

if ssh -q $1 sh -c 'exit'; then

    if rsync -HaPr --delete --timeout=60 --exclude-from ~/.config/rsync/exclude-home --files-from ~/.config/rsync/from-home ~ "$1:"; then

        exit 0

    else

        exit 1

    fi

fi

if [ "$1" = "${1#/}" ]; then

    echo "Error: target directory $1 must be an absolute path."

    exit 1

fi
 
if rsync -HaPr --delete --timeout=60 --exclude-from ~/.config/rsync/exclude-home --files-from ~/.config/rsync/from-home ~ "$1"; then

    exit 0

else

    exit 1

fi
