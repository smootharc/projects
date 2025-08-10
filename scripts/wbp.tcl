#!/usr/bin/env tclsh

package require sqlite3

sqlite3 medical $env(HOME)/.local/share/medical.db -readonly true

medical eval { select w.weight as weight, bp.datetime as datetime, bp.systolic as systolic, bp.diastolic as diastolic, bp.hr as hr
               from weight as w
               join bp on w.date = date(bp.datetime)
               order by bp.datetime
 } { puts "$weight, $datetime, $systolic, $diastolic, $hr"}
