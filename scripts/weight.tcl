#!/usr/bin/env tclsh

package require sqlite3

puts "Weight Statistics"
puts "-----------------"

puts ""

sqlite3 medical $env(HOME)/.local/share/medical.db -readonly true

puts "Date         Min/Max Weights"
puts "----------   ---------------"
medical eval { select date, weight as min from weight where weight = ( select min(weight) from weight where weight > 0 ) order by date desc } {

  puts "$date   $min"
  
}

medical eval { select date, max(weight) as max from weight where weight = ( select max(weight) from weight where weight > 0 ) order by date desc } {

  puts "$date   $max"
  
}

puts ""

puts "#   Date        25 Lowest Weights"
puts "--  ----------  -----------------"

medical eval { select row_number() over (order by weight asc, date desc) as row, date, weight from weight where weight > 0 limit 25 } {

  puts [format "%0-2d  %s  %s" $row $date $weight ]
  
}

set max [medical eval {select max(weight) from weight}]

set min [medical eval {select min(weight) from weight where weight > 0}]

puts ""

puts "Total weight lost: [format %1.1f [expr $max - $min]]"
