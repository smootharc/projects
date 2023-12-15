#!/usr/bin/fish

function help

    echo -e "Usage: "(status basename) "[-h/--help]" dosesPrescribed dosesPerDay dosesTaken "\n"

    echo -e "This program calculates the estimated date and time of the last dose of a prescription medication.\n" 

    echo "All three arguments are required and must be integers. If -h or --help is provided all others will be ignored."

    exit $argv

end

function main -a dosesPrescribed dosesPerDay dosesTaken

    string match -qr '^[[:digit:]]+$' (string join '' -- $argv)

    or help 1

    test $dosesPrescribed -lt $dosesPerDay

    or test $dosesPrescribed -lt $dosesTaken

    and echo "Doses Prescribed must be greater than the other arguments."

    and exit 1

    set -l daysAndHours (math "($dosesPrescribed - $dosesTaken) / $dosesPerDay")

    set -l days (math -s0 "($dosesPrescribed - $dosesTaken) / $dosesPerDay")

    set -l fractionalHours (math $daysAndHours - $days)

    set -l hours (math -s0 $fractionalHours x 24)

    echo "Time left until the last dose: $days Days and $hours Hours"

    echo "Date and time of the last dose is:" (date -Rd "+$days days +$hours hours") 

end

argparse -n (status basename) 'h/help' -- $argv

or help 1

set -q _flag_h

and help 0

test (count $argv) -ne 3

and help 1

main $argv
