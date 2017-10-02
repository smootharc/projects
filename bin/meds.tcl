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

set options {
    {add  "comment for option a"}
    {edit  "comment for option e"}
}

puts [cmdline::getKnownOptions argv $options]
