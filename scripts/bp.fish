#!/usr/bin/env fish

set commandname (status basename)

function sqlexec

    argparse -n $commandname r -- $argv

    or return 1

    if set -q _flag_r

        set cmd sqlite3 -batch -readonly

    else

        set cmd sqlite3 -batch

    end

    if string match -q (realpath (status dirname)) -- $PATH

        set db ~/.local/share/medical.db

    else if string match -q '*projects*' -- (realpath (status dirname))

        set db ~/projects/.local/share/medical.db

    else

        echo "Can't find database file."

        return 1

    end

    $cmd $db ".headers off" "$argv"

end

function isValidDate

    if test 16 -eq (string length $argv)

        and datetest --isvalid -i '%Y-%m-%d %H:%M' $argv

        return 0

    else

        # return 1

    end

end

function avg

    function help

        echo "Usage: $commandname avg [Option]  

    Print the average blood pressure and heart rate from the blood pressure table.
    Optionally limit the average to the last LIMIT number of records.
    All other arguments will be silently ignored.

    Option:
        -l LIMIT must be an integer greater than zero.
        -h Print help message."

    end

    if contains -- -h $argv

        help

        return

    end

    argparse -n "$commandname $(status function)" 'l=!_validate_int --min 1 "$_flag_value"' -- $argv

    or return 1

    if set -q _flag_l

        set limit $_flag_l

        set query "select round(avg(systolic),2), round(avg(diastolic),2), round(avg(hr),2) from (select systolic, diastolic, hr from bp order by datetime desc limit $limit)"

    else

        set query "select round(avg(systolic),2), round(avg(diastolic),2), round(avg(hr),2)from bp"

    end

    set avg (sqlexec -r $query)

    set avg (string split '|' $avg)

    echo -e "Average Blood Pressure: $avg[1]/$avg[2] and Heart Rate: $avg[3]"

end

function select

    function help

        echo "Usage: $commandname $(status function) [Option]

    Print records from the blood pressure table.
    Optionally print only the last LIMIT number of records.
    All other command arguments will be ignored.

    Option:
        -l LIMIT must be an integer greater than zero.
        -h Print this help message."

    end

    if contains -- -h $argv

        help

        return

    end

    argparse -n "$commandname $(status function)" 'l=!_validate_int --min 1 "$_flag_value"' -- $argv

    or return 1

    if set -q _flag_l

        set limit $_flag_l

        set query "select id, datetime, systolic, diastolic, hr, comment from (select id, datetime, systolic, diastolic, hr, comment from bp order by datetime desc limit $limit) order by datetime asc"

    else

        set query "select id, datetime, systolic, diastolic, hr, comment from bp order by datetime"

    end

    # for row in (sqlite3 -batch $db ".headers off" "select id, datetime, systolic, diastolic, hr, comment from bp order by datetime")
    printf "%-5s %-10s %-6s %-8s %-3s %s\n" ID Date Time BP HR Comment

    for row in (sqlexec -r $query)

        set row (string split '|' $row)

        printf "%-5d %s %4d/%-3d %4d  %s\n" $row[1] $row[2] $row[3] $row[4] $row[5] $row[6]

    end

end

function insert

    function help

        echo "Usage: $commandname insert [Options]... BP HR

    Insert a blood pressure (BP) and heart rate (HR) measurement into the blood pressure table.

    Options:
        -c COMMENT        
        -t TIME  
        -h Print help message.

        The valid TIME format is %Y-%m-%d %H:%M        

    Arguments:
        BP: BP Must be of the form ddd/dd or dd/dd.  Where d is a digit.
        HR: HR Must be of either two or three digits."

    end

    if contains -- -h $argv

        help

        return

    end

    argparse -n "$commandname insert" 'c=' 't=' -- $argv

    or return 1

    if set -q _flag_c

        set comment $_flag_c

    end

    if set -q _flag_t

        set datetime $_flag_t

        if not isValidDate $datetime

            echo -e "$commandname $(status function): Invalid TIME. The valid TIME format is %Y-%m-%d %H:%M\n"

            help

            return 1

        end

    else

        set datetime ''

    end

    if test (count $argv) -ne 2

        echo -e "$commandname $(status function): Both blood pressure and heart rate must be provided.\n"

        help

        return 1

    end

    if string match -q --regex '^\d{2,3}\/\d{2,3}$' -- $argv[1]

        set bp (string split / $argv[1])

    else

        echo -e "$commandname $(status function): Incorrect BP.  Blood pressure must be of the form 'ddd/dd' or 'dd/dd' where d is a single digit.\n"

        help

        return 1

    end

    if string match -q --regex '^\d{2,3}$' -- $argv[2]

        set hr $argv[2]

    else

        echo "$commandname $(status function): Incorrect HR: $argv[2]. Heart Rate must be of the form 'dd' or 'ddd' where d is a single digit."

        return 1

    end

    if isValidDate $datetime

        set query "insert into bp (datetime, systolic, diastolic, hr, comment) values('$datetime', $bp[1], $bp[2], $hr,iif(length('$comment'),'$comment',''));select last_insert_rowid()"

    else

        set query "insert into bp (systolic, diastolic, hr, comment) values($bp[1], $bp[2], $hr,iif(length('$comment'),'$comment',''));select last_insert_rowid()"

    end

    # set id (sqlite3 -batch $db ".headers off" "insert into bp (systolic, diastolic, hr, comment) values($bp[1], $bp[2], $hr,iif(length('$comment'),'$comment',''))" "select last_insert_rowid()")
    set id (sqlexec $query)

    if test $id -gt 0

        echo "Successfully inserted a row with the id $id"

    else

        echo "Failed to insert row."

        return 1

    end

end

function update

    function help

        echo "Usage: $commandname update [Option] ID

    Update the blood pressure record having the given integer ID number. 

    Option:
        -h Print help message."

    end

    if contains -- -h $argv

        help

        return

    end

    if test (count $argv) -eq 0 || string match -qvr '\d+' -- $argv[1]

        echo -e "$commandname $(status function): ID must be an integer.\n"

        help

        return 1

    end

    set -l id $argv[1]

    if test (sqlexec "select count(id) from bp where id = $id") -eq 0

        echo "No record with the id $id exists."

        exit 1

    end

    set row (sqlexec "select datetime, systolic, diastolic, hr, comment from bp where id = $id")

    set row (string split '|' $row)

    set -l datetime $row[1]
    set -l systolic $row[2]
    set -l diastolic $row[3]
    set -l hr $row[4]
    set -l comment $row[5]

    # If C-c then exit.
    function isset

        if set -q argv[1]

            return

        else

            exit 0

        end

    end

    while read -c $datetime -fP"DateTime: " datetime

        if isValidDate $datetime

            break

        else

            echo "Invalid date."

        end

    end

    isset $datetime

    while read -c $systolic -fP"Systolic: " systolic

        if string match -qr '^\d{2,3}$' $systolic

            break

        else

            echo "Invalid systolic blood presure."

        end

    end

    isset $systolic

    while read -c $diastolic -fP"Diastolic: " diastolic

        if string match -qr '^\d{2}$' $diastolic

            break

        else

            echo "Invalid diastolic blood pressure."

        end

    end

    isset $diastolic

    while read -c $hr -fP"Heart Rate: " hr

        if string match -qr '^\d{2,3}$' $hr
            and test "$hr" -lt 150

            break

        else

            echo "Invalid heart rate."

        end

    end

    isset $hr

    read -c $comment -fP"Comment: " comment

    isset $comment

    set changed (sqlexec "update bp set datetime = '$datetime', systolic = $systolic, diastolic = $diastolic, hr = $hr, comment = '$comment' where id = $id; select changes()")

    if test $changed -eq 1

        echo "Successfully updated the row with the id: $id."

    else

        echo "Failed to update the row with the id: $id"

    end

end

function delete

    function help

        echo "Usage: $commandname $(status function) [Option] ID

    Delete the blood pressure record having the given integer ID number. 

    Option:
        -h Print help message."

    end

    if test (count $argv) -eq 0 && string match -qr '\d+' -- $argv[1]

        echo -e "$commandname $(status function): ID must be an integer.\n"

        help

        return 1

    end

    set id $argv[1]

    if test (sqlexec -r "select count(id) from bp where id = $id") -eq 0

        echo "No record with the id $id exists."

        exit 1

    end

    set changed (sqlexec "delete from bp where id = $id;select changes()")

    if test $changed -eq 1

        echo "Successfully deleted row with the id $id"

    else

        echo "Failed to delete row with the id $id"

        exit 1

    end

end

function help

    echo "Usage: $commandname [-h] SUBCOMMAND [ARGS]

    Sub Commands:
        select
        insert
        update
        delete
        avg

    Type bp SUBCOMMAND -h for help on each SUBCOMMAND."

end

argparse -s -n $commandname h -- $argv

or return

if set -q _flag_h

    help

    return

end

switch $argv[1]

    case select

        select $argv[2..-1]

    case insert

        insert $argv[2..-1]

    case update

        update $argv[2..-1]

    case delete

        delete $argv[2..-1]

    case avg

        avg $argv[2..-1]

    case -h

        help

    case '*'

        if test (count $argv) -eq 0

            echo -e "$commandname: Command line arguments must begind with a SUBCOMMAND.\n"

            help

            return 1

        else

            echo -e "$commandname: Incorrect SUBCOMMAND: $argv.\n"

            help

            return 1

        end
end
