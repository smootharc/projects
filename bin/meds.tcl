#!/usr/bin/tclsh

package require cmdline

proc usage {} {
    puts ""
    puts -nonewline {Usage: }
    puts -nonewline [file tail $::argv0]
    puts {-add|-count|-agenda [startdate] [enddate]}
    puts ""
    exit 1
}

proc agenda { startdate enddate }   {
    exec gcalcli --calendar Medical agenda "$startdate" "$enddate" >@stdout 2>@stderr
}

proc add { {allday --noallday} } {
    puts "Allday: $allday"
    eval exec gcalcli --calendar Medical $allday add <@stdin >@stdout 2>@stderr
}

proc count {startdate enddate} {
    puts "Count $startdate $enddate"
}

catch {cmdline::getopt argv "add count agenda" opt val} returnval

puts "Return from catch: $returnval"
puts "Option: $opt Value: $val"
puts "Length of argv: [llength $argv] Value of argv: $argv"
after 5000

set startdate [lindex $argv 0]
set enddate [lindex $argv 1]

switch $opt {
    add { add $argv }
    count { count $startdate $enddate }
    agenda { agenda $startdate $enddate }
    default { usage }
}



