#!/bin/sh

function help {

    echo "Usage: $(basename $0) sshservername"
    
}

if [ -z "$1" ]; then

    help

    exit 1  

fi

if ssh -q $1 sh -c 'exit'; then

#    if rsync -HaPr --delete --delete-excluded --timeout=60 --exclude-from ~/.config/rsync/exclude-home --files-from ~/.config/rsync/from-home ~/ "$1:"; then
    if rsync -HaPr --timeout=60 --exclude-from ~/.config/rsync/exclude-home ~/ "$1:"; then

        ssh $1 chmod 640 ~/.local/bin/dose ~/.local/bin/wf ~/.local/bin/bp        

        if rsync -HaPr -q --delete --delete-excluded --exclude-from ~/.config/rsync/exclude-home ~/ /backup/home
        then

            exit 0

        else

            echo "Command synchome to /backup/home failed."

            exit 1

        fi

    else

        exit 1

    fi

else

    echo "Command synchome to hostname $1 failed."

    exit 1

fi
 
#if rsync -HaPr --delete --delete-excluded --timeout=60 --exclude-from ~/.config/rsync/exclude-home --files-from ~/.config/rsync/from-home ~/ "$1"; then
# if rsync -HaPr --delete --exclude-from ~/.config/rsync/exclude-home ~ "$1"; then

#     exit 0

# else

#     exit 1

# fi
