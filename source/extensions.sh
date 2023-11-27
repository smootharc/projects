#!/bin/sh

#if test "$#" -ne 1; then
if test -z "$1"; then

    printf "\nUsage: %s filetype\n\n" $(basename $0)
    exit 1

fi

#Previous versions of this script.
#sed -nr "s~^$1.*\t+~~p" /etc/mime.types | tr " \n" "|" | sed 's/|$//'
#grep "$1" /etc/mime.types | tr -s " \t" "|" | cut --complement -s -d "|" -f 1 | tr "\n" "|" | sed 's/|$//'
#grep "$1" /etc/mime.types | sed -nr 's/.*\t+//p' | tr " \n" "|" | sed 's/|$//'
perl -ne "if (s~^$1.*\t+~~) { push @result, split /\s+/; } END { @result = sort @result; print join( '|', @result); }" /etc/mime.types
