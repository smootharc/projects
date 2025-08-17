#!/usr/bin/env tclsh

package require sqlite3

sqlite3 weight ~/.local/share/medical.db

set rows [weight onecolumn { select count(*) from weight }]

set total 0

weight eval { select food from weight where food like '%Vodka%' } {

	# regexp {\d+} $food number
	regsub {\D*} $food {} food

	regsub {\D.*} $food {} number

	incr total $number

}

puts "[ expr { $total / $rows } ] ml/day."
