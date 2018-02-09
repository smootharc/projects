#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
	echo 'Usage: vids.sh Directory [files ...]'
	exit
fi

pushd "$1" >/dev/null

error=$?

if [[ $error -gt 0 ]]; then
	echo "Could not access the directory"
	exit
fi
if [[ $# -eq 1 ]]; then
	popd >/dev/null
	videolist.py $1
	mpv -playlist=/tmp/playlist.txt
	rm /tmp/playlist.txt
else
	shift
	mpv $@
fi
