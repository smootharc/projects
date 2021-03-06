#!/usr/bin/tclsh

package require sqlite3

sqlite3 db /home/paul/Documents/.medical.db

db eval { pragma foreign_keys = on }

proc usage { message } {
    puts "\n [string totitle [file tail [info script]]] $message\n"
    exit 1
}

proc ifempty { var ifemptyvar } {

    if { [string length $var] == 0 } {
        set var $ifemptyvar
    }

    return $var

}

proc lines { thestring length} {

    set start 0
    set linelist {}
    while 1 {
        set end [expr $start + $length - 1]
        set nextline [string range $thestring $start $end]
        if { [string length $nextline] < $length } {
            set line $nextline
        } else {
            set line [regsub {[^[:space:]]+$} [string range $thestring $start $end] "" ]
        }
        set linelength [string length $line]
        if { $linelength > 0 } {
            lappend linelist $line
            set start [expr { $start + $linelength }]
        } else { break }
    }

    return $linelist

}

proc printdoses { sql } {
    
    if { ! [db exists $sql] } { 
        puts "\nNone found.\n"
        exit 1
    }

    set lastdate ""
    set count 1      

    db eval $sql { 
        
        if { $date == $lastdate } {
            incr count
            set date ""
        } else {
            set count 1
            set lastdate $date
            puts ""
        }
        
        printdoseline $date $time $count $id $name $comment
 
    }

    puts ""

}

proc printdoseline { date time count id name comment } {

    set columns [lindex [exec stty size] 1]
    set datelength 11
    set timelength 9
    set countlength 3
    set idlength 7
    set namelength [db onecolumn {select max(length(name)) from medication}]
    incr namelength 2

    set commentlength [expr { $columns - $datelength - $timelength - $countlength - $idlength - $namelength }]

    set commentlines [lines $comment $commentlength]
    puts [format "%-${datelength}s%-${timelength}s%-${countlength}s%-${idlength}s%-${namelength}s%-${commentlength}s" $date $time $count $id "$name." [lindex $commentlines 0]]
    set commentlines [lrange $commentlines 1 end]
    set indent [expr { $datelength + $timelength + $countlength + $idlength + $namelength }]
    foreach line $commentlines {
        puts [format "%s%-${commentlength}s" [string repeat " " $indent] $line]
    }

}

proc datetimeadd { date increment unit } {

    set seconds [clock add [clock scan $date] $increment $unit]
    set time [clock format $seconds]
    return [datetimestring $time]

}

proc makedatetime { timestring } {

    if { [string length $timestring] == 0 } {
        set datecommand "date -Iseconds"
    } else {
        set datecommand {date -Iseconds -d "$timestring"}
    }

    try {
        set timestring [eval exec $datecommand]
        set timestring [string replace $timestring end-5 end ""]
        set timestring [string map {T " "} $timestring]
    } on error e {
        usage $e
    }

}

proc elapseddays { starttime endtime } {
    
    set startseconds [clock scan $starttime]
    set endseconds [clock scan $endtime]
    set elapsedseconds [expr { $endseconds - $startseconds }]
    return [format %.2f [expr { $elapsedseconds/86400.00 }]]

}

proc add {} {
    
    puts ""
    set datetime [exec rlwrap -D 2 -C datetime -S "Date Time: " -o cat]
    set name [exec rlwrap -D 2 -C name -S "     Name: " -o cat]
    set comment [exec rlwrap -D 2 -C comment -S "  Comment: " -o cat]
    set datetime [makedatetime $datetime]

    if { ! [db eval { select count(*) from medication where name = $name }] } {
        puts "\nMedication $name not found.\n"
        exit 1
    }

    db eval {insert into dose (datetime, name, comment) values($datetime,$name,$comment)}
    set id [db last_insert_rowid]
    db eval { select * from dose where id = $id } {

            puts "\nRecord added:\n"
            puts "       Id: $id"
            puts "Date Time: $datetime"
            puts "     Name: $name"
            puts "  Comment: $comment"
            puts ""

    }        
        
}

proc remove { id } { 
    
    set sql "select * from dose where id = $id"
    if [db exists $sql] {
        db eval $sql {
            puts ""
            puts "       Id: $id"
            puts "Date Time: $datetime"
            puts "     Name: $name"
            puts "  Comment: $comment"
            puts ""
        }
   } else {
        puts "\nDose not found.\n"
        return
   }
    
    set ttysettings [exec stty -g]
    exec stty raw -echo

    while 1 {
        puts -nonewline "\rConfirm removal of this record. \[y/n\] "
        flush stdout
        set reply [read stdin 1] 
        if { $reply == y } { 
            db eval { delete from dose where id = $id }
            break
        } elseif { $reply == n } { 
            break 
        } else { continue }
    }

    exec stty $ttysettings

    if { [db changes] } { 
        puts "\n\nRecord removed.\n"
    } else { 
        puts "\n\nRecord not removed.\n"
    }

}

proc doselist { starttime endtime } {

    set sql "select date(datetime) as date, time(datetime) as time, id, name, comment from dose where datetime between '$starttime' and '$endtime' order by datetime"

    printdoses $sql
    
}
 
proc search { searchstring starttime endtime } { 

    set sql "select date(datetime) as date, time(datetime) as time, id, name, comment from dose where id in 
            ( select docid from doseft where doseft match '$searchstring' ) and datetime between '$starttime' and '$endtime' order by datetime"

    printdoses $sql

}

proc edit { id } { 

    puts ""
    db eval { select * from dose where id = $id } {

        set datetime [exec rlwrap -D 2 -C datetime -S "Date Time: " -P $datetime -o cat]
        set name [exec rlwrap -D 2 -C name -S "     Name: " -P $name -o cat]
        set comment [exec rlwrap -D 2 -C comment -S "  Comment: " -P $comment -o cat]
        set datetime [makedatetime $datetime]

    }

    if { ! [db eval { select count(*) from medication where name = $name }] } {
        puts "\nMedication $name not found.\n"
        exit 1
    }
        
    try {

        db eval { update dose set datetime = $datetime,  name = $name, comment = $comment where id = $id }

    } on error e {
        puts $e
        exit 1
    }
    

    db eval { select * from dose where id = $id } {
            
            puts "\nRecord changed to:\n"
            puts "         Id: $id"
            puts "  Date Time: $datetime"
            puts "       Name: $name"
            puts "    Comment: $comment"
            puts ""

    }
        
}
 
proc count { medication starttime endtime } { 
  
    set medcount [db eval "select count(*) from medication where upper(name) = upper('$medication')"]
    #set medcount [db eval "select count(*) from medication where name like '%$medication%'"]

    switch $medcount {

        1 {
                        
            set medication [db onecolumn "select name from medication where upper(name) = upper('$medication')"]
    
        }

        default {
        
            set medication ""

            while { [ expr { $medication eq "" } ] } {

                puts "\nNo or more than one medication found."

                medications
    
                puts -nonewline "Enter the number of the one you want: "

                flush stdout

                gets stdin response

                set medication [db eval "select name from medication where rowid = '$response'"]

            }

        }

    }
       

    set sql "select count(*) from dose where name = '$medication' and datetime between '$starttime' and '$endtime'"
    set doses [db onecolumn $sql]
    if { ! $doses } {
        puts "\nNo doses for Medication $medication found between $starttime and $endtime.\n"
        exit 1
    }
    set days [elapseddays $starttime $endtime]

    puts ""
    puts "Medication: $medication"
    puts "      From: $starttime"
    puts "        To: $endtime"
    puts "     Doses: $doses"
    puts "      Days: $days"
    puts " Doses/Day: [format %.2f [expr { $doses/$days }]]"
    puts ""

}

proc medications {} {

    puts ""

    db eval { select rowid, name from medication order by rowid } {

    puts "$rowid $name"

    }

    puts ""

}

set options [lassign $argv command]

switch $command {
    
    add     { 

                add 

            }


    remove  { 

                lassign $options id
                remove $id 

            }

    list    {

                lassign $options starttime endtime
                set starttime [makedatetime [ifempty $starttime "last month"]]
                set endtime [makedatetime $endtime]
                doselist $starttime $endtime

            }

    search  { 

                lassign $options medication starttime endtime
                set starttime [makedatetime [ifempty $starttime "last year"]]
                set endtime [makedatetime $endtime]
                search $medication $starttime $endtime

            }

    edit    { 

                lassign $options id
                edit $id

            }

    count   { 

                lassign $options medication starttime endtime
                set starttime [makedatetime [ifempty $starttime "30 days ago"]]
                set endtime [makedatetime $endtime]
                count $medication $starttime $endtime

            }

    medications {

                medications

            }

    default { 

                usage "Missing arguments."

            }

}
