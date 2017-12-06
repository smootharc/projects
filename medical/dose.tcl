#!/usr/bin/tclsh

package require sqlite3

sqlite3 db /home/paul/Desktop/medical.db

db eval { pragma foreign_keys = on }

proc usage { message } {
    puts "\nUsage: [string totitle [file tail [info script]]] $message]\n"
    exit 1
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

proc makedatetime { timestring insteadof } {

    if { [string length $timestring] eq 0 } {
        set timestring $insteadof
    }

    try {
#        set timeseconds [clock scan $timestring -format {%Y-%m-%d %H:%M:%S}]
        set timeseconds [clock scan $timestring]
        set datetime [clock format $timeseconds -format {%Y-%m-%d %H:%M:%S}]
    } on error e {
        usage $e
        exit 1
    }
    
    return $datetime

}

proc elapseddays { starttime endtime } {
    
    set startseconds [clock scan $starttime]
    set endseconds [clock scan $endtime]
    set elapsedseconds [expr { $endseconds - $startseconds }]
    return [format %.2f [expr { $elapsedseconds/86400.00 }]]

}

proc add {} {
    
    set datetime [exec rlwrap -D 2 -C datetime -S "Date Time: " -o cat]
    set name [exec rlwrap -D 2 -C name -S "     Name: " -o cat]
    set comment [exec rlwrap -D 2 -C comment -S "  Comment: " -o cat]
    set datetime [makedatetime $datetime now]
    db eval {insert into dose (datetime, name, comment) values($datetime,$name,$comment)}
    set id [db last_insert_rowid]
    db eval { select * from dose where id = $id } {

            puts ""
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

proc edit { args } { 
    puts [lindex [info level 0] 0]
}
 
proc count { medication starttime endtime } { 
  
    if { ! [db exists "select * from medication where name like '%$medication%'"] } {
        puts "\nMedication $medication not found.\n"
        exit 1
    } else {
        set medication [db onecolumn "select name from medication where name like '%$medication%'"]
    }

    set sql "select count(*) from dose where name like '%$medication%' and datetime between '$starttime' and '$endtime'"
    set doses [db onecolumn $sql]
    if { ! $doses } {
        puts "\nNo doses for Medication $medication found.\n"
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

set command [lindex $argv 0]

switch -exact $command {
    
    add     { 
                add 
            }

    remove  { 
                set id [lindex $argv 1]
                remove $id 
            }

    list    {
                set starttime [makedatetime [lindex $argv 1] "last week"]
                set endtime [makedatetime [lindex $argv 2] "now"]
                doselist $starttime $endtime
            }

    search  { 
                set medication [lindex $argv 1]
                set starttime [makedatetime [lindex $argv 2] "last year"]
                set endtime [makedatetime [lindex $argv 3] "now"]
                search $medication $starttime $endtime
            }

    edit    { 
                edit 
            }

    count   { 
                set medication [lindex $argv 1]
                set starttime [makedatetime [lindex $argv 2] "1 month ago"]
                set endtime [makedatetime [lindex $argv 3] "now"]
                count $medication $starttime $endtime 
            }
    default { 
                usage "Missing arguments."
            }

}
