#!/bin/bash

add () {

        case "$allday" in
                --allday)
                        gcalcli --calendar Medical add "$allday"
                        ;;
                "")
                        gcalcli --calendar Medical add
                        ;;
                *)
                        help "Subcommand add expects either --allday or nothing."
                        ;;
        esac

}

count () {

        if ! startseconds=$(date +%s -d "$starttime" 2> /dev/null); then
                help "Incorrect start time."
        fi
        
        if ! endseconds=$(date +%s -d "$endtime" 2> /dev/null ); then
                help "Incorrect end time."
        fi

        elapsedseconds=$(bc -l <<< "$endseconds - $startseconds")
        
        doses=$(gcalcli --tsv --calendar Medical agenda "$starttime" "$endtime" | grep -v 00:00 | grep "$medication" | wc -l)

        [[ $doses -eq 0 ]] && help "Medication not found."

        days=$(bc <<< "scale=2;$elapsedseconds/86400")

        dosesperday=$(bc <<< "scale=2;$doses/$days")

        echo
        echo "Medication: $medication"
        echo "      From: "$(date +"%Y-%m-%d %H:%M" -d "$starttime")
        echo "        To: "$(date +"%Y-%m-%d %H:%M" -d "$endtime")
        echo "      Days: $days"
        echo "     Doses: $doses"
        echo " Doses/Day: $dosesperday"
        echo

}

agenda () {

        gcalcli --calendar Medical agenda "$starttime" "$endtime"

}


help () {

        [[ $# -eq 1 ]] && printf "\n%s\n" "$1"
       
        echo
         
        printf "Usage: %s add [--allday]\n" $(basename "$0")
        
        echo "or"
        
        printf "Usage: %s agenda [starttime] [endtime]\n" $(basename "$0")
        
        echo "or"
        
        printf "Usage: %s count medication [starttime] [endtime]\n" $(basename "$0")
        
        echo "or"
        
        printf "Usage: %s help\n" $(basename "$0")
        
        exit 1

}

main () {
        
#arguments=$(getopt -n $(basename "$0") -o ac:gh -- "$@")
#eval set -- "$arguments"

[[ " add agenda count help " =~ " "$1" " ]] || help "Subcommand not found."

[[ $1 == "count" && -z $2 ]] && help "Subcommand count requires a medication name."

case $1 in

        add)    
                allday="$2"
                add $allday
                ;;
        count) 
                medication="$2"
                starttime=${3:-"90 days ago"}
                endtime=${4:-"now"}
                count "$medication" "$starttime" "$endtime" 
                ;;
        agenda) 
                starttime=${2:-"5 days ago"}
                endtime=${3:-"tomorrow"}
                agenda "$starttime" "$endtime"
                ;;
        help) 
                help
                ;;
        *) 
                help
                ;;

esac

}

main "$@"
