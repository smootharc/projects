#!/usr/bin/env tclsh
    
package require fileutil

set searchstring [lindex $argv 0]

if ![string length $searchstring] { puts "\nUsage: [file tail $argv0] somesearchstring.\n"; exit 1 }

set mimefile [::fileutil::cat /etc/mime.types]

set mimefile [regsub -all {\t+| } $mimefile |] 

append searchstring "*|*"

set result ""

foreach line [split $mimefile \n] {
    
    set ismatch [string match $searchstring $line]
    
    if $ismatch {
        
        set line [regsub {[^\|]+\|} $line ""]

        append result $line "|"

    }

}

puts -nonewline [string trim $result "|"]


