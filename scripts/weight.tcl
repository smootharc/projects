#!/usr/bin/env tclsh

package require sqlite3

puts "Weight Statistics"
puts "-----------------"

puts ""

sqlite3 medical $env(HOME)/.local/share/medical.db -readonly true

# medical eval { select date as Date, weight as {Min/Max Weights} from weight where weight = (select max(weight) from weight) or weight = (select min(weight) from weight where weight > 0 ) order by weight } {
puts "Date         Min/Max Weights"
puts "----------   ---------------"
medical eval { select date, weight as min from weight where weight = ( select min(weight) from weight where weight > 0 ) order by date desc } {

  puts "$date   $min"
  
}

# medical eval { select date, min(weight) as min from weight where weight > 0 } {

#   puts "$date   $min"
  
# }

medical eval { select date, max(weight) as max from weight where weight = ( select max(weight) from weight where weight > 0 ) order by date desc } {

  puts "$date   $max"
  
}

# medical eval { select date, max(weight) as max, min(weight) as min from weight where weight > 0} {

  # puts "$date, $max, $min"
  
# }

puts ""

puts "#   Date        25 Lowest Weights"
puts "--  ----------  -----------------"

# medical eval { select row_number() over (order by weight asc) as row, date, weight from weight where weight > 0 order by date desc limit 25 } {
medical eval { select row_number() over (order by weight asc, date desc) as row, date, weight from weight where weight > 0 limit 25 } {

  puts [format "%0-2d  %s  %s" $row $date $weight ]
  
}

# echo
# sqlite3 -batch ~/.local/share/medical.db '.mode columns' 'select date as "Start Date", weight as "Weight" from weight where weight > 0 order by date limit 1'
# sqlite3 -batch -readonly ~/.local/share/medical.db '.mode columns' 'select date as Date, weight as "Min/Max Weights" from weight where weight = (select max(weight) from weight) or weight = (select min(weight) from weight where weight > 0) order by weight'
# sqlite3 -batch -readonly  ~/.local/share/medical.db '.mode columns' 'select row_number() over (order by weight asc) "#", date as Date,weight as "25 Lowest Weights" from weight where weight > 0 limit 25'
