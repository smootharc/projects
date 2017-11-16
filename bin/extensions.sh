#!/bin/bash

getextensions () {

    local retval

    words=("$@")
    wordcount="${#words[@]}"

    if [[ $wordcount -le 1 ]] 
    then
        return
    fi
    
    for (( i=1; i < "$wordcount"; i++))
    do
        retval=$retval"${words[$i]}|"
    done
    if [[ -n $retval ]] 
    then
        printf "%s" $retval
    fi
}

if [[ $# -ne 1 ]]
then

    printf "\n%s\n\n" "Usage: $(basename $0) somefiletype"
    exit 1

fi

mapfile < /etc/mime.types

for line in "${MAPFILE[@]}"
do
     
    if [[ $line != ${1}* ]]
    then
        continue
    fi

    extensions=$(getextensions $line)

    allextensions="$allextensions$extensions"

done

echo ${allextensions::-1}
