#!/usr/bin/env tclsh

package require sqlite3

sqlite3 medical $env(HOME)/.local/share/medical.db -readonly true

puts [format {%s   %s                %s       %s     %s} LBS. DTM BP HR RPP]
puts "----------------------------------------------"
medical eval { select w.weight as weight, bp.datetime as datetime, bp.systolic as systolic, bp.diastolic as diastolic, bp.hr as hr, (bp.systolic * bp.hr) as rpp
               from weight as w
               join bp on w.date = date(bp.datetime)
               order by bp.datetime
 } { puts [format {%.1f  %s  %7s %4d %8d} $weight $datetime $systolic/$diastolic $hr $rpp]}
