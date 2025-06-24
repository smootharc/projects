#!/usr/bin/env fish

if string match -q (status dirname) -- $PATH

    set db ~/.local/share/medical.db

else if string match -q src -- (status dirname)

    set db ~/projects/.local/share/medical.db

else

    echo "Can't find database file."

    exit 1

end

set commandname (status basename)

function isValidDate

    if test 16 -eq (string length $argv)

        and datetest --isvalid -i '%Y-%m-%d %H:%M' $argv

        return 0

    else

        return 1

    end

    # test 16 -eq (string length $argv); and datetest --isvalid -i '%Y-%m-%d %H:%M' $argv

end

function avg

    argparse -n "$commandname select" h -- $argv

    or return

    if set -q _flag_h

        echo "Usage: $commandname avg: [Option] [LIMIT]  

    Print the average blood pressure and heart rate from the blood pressure table.
    Optionally limit the average to the last LIMIT number of records.

    Option:
        -h Print help message.
    "

        return

    end

    if string match -qr '\d+' $argv[1]

        set query "select round(avg(systolic),2), round(avg(diastolic),2), round(avg(hr),2) from (select systolic, diastolic, hr from bp order by datetime desc limit $argv[1])"

    else

        set query "select round(avg(systolic),2), round(avg(diastolic),2), round(avg(hr),2)from bp"

    end

    set avg (sqlite3 -batch "file:$db?mode=ro" ".headers off" $query)

    set avg (string split '|' $avg)

    echo -e "Average Blood Pressure: $avg[1]/$avg[2] and Heart Rate: $avg[3]"

end

function select

    argparse -n "$commandname select" h -- $argv

    or return

    if set -q _flag_h

        echo "Usage: $commandname select [Option] [LIMIT]

    Print records from the blood pressure table.
    Optionally print only the last LIMIT number of records.

    Option:
        -h Print help message.
    "

        return

    end

    if string match -qr '\d+' $argv[1]

        set query "select id, datetime, systolic, diastolic, hr, comment from (select id, datetime, systolic, diastolic, hr, comment from bp order by datetime desc limit $argv[1]) order by datetime asc"

    else

        set query "select id, datetime, systolic, diastolic, hr, comment from bp order by datetime"

    end

    # for row in (sqlite3 -batch $db ".headers off" "select id, datetime, systolic, diastolic, hr, comment from bp order by datetime")
    printf "%-5s %-10s %-6s %-8s %-3s %s\n" ID Date Time BP HR Comment
    for row in (sqlite3 -batch "file:$db?mode=ro" ".headers off" $query)

        set row (string split '|' $row)

        printf "%-5d %s %4d/%-3d %4d  %s\n" $row[1] $row[2] $row[3] $row[4] $row[5] $row[6]

    end

end

function insert

    argparse -n "$commandname insert" h 'c=' 't=' -- $argv

    or return

    function help

        echo "Usage: $commandname insert: [Options]... BP HR

    Insert a blood pressure (BP) and heart rate (HR) measurement into the blood pressure table.

    Options:
        -c COMMENT        
        -t TIME  
        -h Print help message.

        The valid TIME format is %Y-%m-%d %H:%M        

    Arguments:
        BP: BP Must be of the form ddd/dd or dd/dd.  Where d is a digit.
        HR: HR Must be of either two or three digits.
    "

    end

    if set -q _flag_h

        help

        return

    end

    if set -q _flag_c

        set comment $_flag_c

    end

    if set -q _flag_t

        set datetime $_flag_t

        if not isValidDate $datetime

            # echo "$commandname insert: Invalid TIME. The valid TIME format is %Y-%m-%d %H:%M"
            help

            return 1

        end

    else

        set datetime ''

    end


    if string match -q --regex '^\d{2,3}\/\d{2,3}$' -- $argv[1]

        set bp (string split / $argv[1])

    else

        help
        # echo "$commandname insert: Incorrect BP.  Blood pressure must be of the form 'ddd/dd' or 'dd/dd' where d is a single digit."

        return 1

    end

    if string match -q --regex '^\d{2,3}$' -- $argv[2]

        set hr $argv[2]

    else

        echo "$commandname insert: Incorrect HR.  Heart Rate must be of the form 'dd' or 'ddd' where d is a single digit."

        return 1

    end

    if isValidDate $datetime

        set query "insert into bp (datetime, systolic, diastolic, hr, comment) values('$datetime', $bp[1], $bp[2], $hr,iif(length('$comment'),'$comment',''))" "select last_insert_rowid()"

    else

        set query "insert into bp (systolic, diastolic, hr, comment) values($bp[1], $bp[2], $hr,iif(length('$comment'),'$comment',''))" "select last_insert_rowid()"

    end

    # set id (sqlite3 -batch $db ".headers off" "insert into bp (systolic, diastolic, hr, comment) values($bp[1], $bp[2], $hr,iif(length('$comment'),'$comment',''))" "select last_insert_rowid()")
    set id (sqlite3 -batch $db ".headers off" $query)


    if test $id -gt 0

        echo "Successfully inserted a row with the id $id"

    else

        echo "Failed to insert row."

        return 1

    end

end

function update

    argparse -n "$commandname update" h -- $argv

    or return

    function help

        echo "Usage: $commandname update: [Option] ID

    Update the blood pressure record having the given integer ID number. 

    Option:
        -h Print help message.
    "

    end

    if test (count $argv) -eq 0 || string match -qvr '\d+' -- $argv[1]

        help

        return 1

    end

    if set -q _flag_h

        help

        return

    end

    set -l id $argv[1]

    if test (sqlite3 -batch $db ".headers off" "select count(id) from bp where id = $id") -eq 0

        echo "No record with the id $id exists."

        exit 1

    end

    set row (sqlite3 -batch $db ".headers off" "select datetime, systolic, diastolic, hr, comment from bp where id = $id")

    set row (string split '|' $row)

    set -l datetime $row[1]
    set -l systolic $row[2]
    set -l diastolic $row[3]
    set -l hr $row[4]
    set -l comment $row[5]

    function isempty

        if not string length -q $argv[1]

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

    isempty $datetime

    while read -c $systolic -fP"Systolic: " systolic

        if string match -qr '^\d{2,3}$' $systolic

            break

        else

            echo "Invalid systolic blood presure."

        end

    end

    isempty $systolic

    while read -c $diastolic -fP"Diastolic: " diastolic

        if string match -qr '^\d{2}$' $diastolic

            break

        else

            echo "Invalid diastolic blood pressure."

        end

    end

    while read -c $hr -fP"Heart Rate: " hr

        if string match -qr '^\d{2,3}$' $hr

            break

        else

            echo "Invalid heart rate."

        end

    end

    isempty $diastolic

    read -c $comment -fP"Comment: " comment

    # isempty $comment

    set changed (sqlite3 -batch $db ".headers off" "update bp set datetime = '$datetime', systolic = $systolic, diastolic = $diastolic, hr = $hr, comment = '$comment' where id = $id; select changes()")

    if test $changed -eq 1

        echo "Successfully updated the row with the id: $id."

    else

        echo "Failed to update the row whith the id: $id"

    end

end

function delete

    argparse -n "$commandname delete" h -- $argv

    or return

    function help

        echo "Usage: $commandname delete: [Option] ID

    Delete the blood pressure record having the given integer ID number. 

    Option:
        -h Print help message.
    "

    end

    if test (count $argv) -eq 0 || string match -qvr '\d+' -- $argv[1]

        help

        return 1

    end

    if set -q _flag_h

        help

        return

    end

    if test (sqlite3 -batch $db ".headers off" "select count(id) from bp where id = $argv[1]") -eq 0

        echo "No record with the id $argv[1] exists."

        exit 1

    end

    set changed (sqlite3 -batch $db ".headers off" "delete from bp where id = $argv[1]" "select changes()")

    if test $changed -eq 1

        echo "Successfully deleted row with the id $argv[1]"

    else

        echo "Failed to delete row with the id $argv[1]"

        exit 1

    end

end

switch $argv[1]

    case select

        select $argv[2..-1]

    case insert

        insert $argv[2..-1]

    case update

        update $argv[2]

    case delete

        delete $argv[2]

    case avg

        avg $argv[2]

    case '*'

        echo "Usage: $commandname SUBCOMMAND [ARGS]

    Sub Commands:
        select
        insert
        update
        delete
        avg

    Type bp SUBCOMMAND -h for help on each SUBCOMMAND
    "

end
