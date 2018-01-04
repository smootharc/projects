#!/bin/bash
gcalcli --calendar Medical --tsv search " " | egrep -iv "00:00.*00:00|doctor|blood|weight|alcohol" \
| cut --complement -f 3,4 | sed 's/\t/ /' | tr "\t" "|" | sed 's/|/:00|/' | nl -s"|" > /tmp/dose.dat

cat /tmp/dose.dat | cut -d"|" -f 3 | sort | uniq | sed 's/$/|/'> /tmp/medication.dat
sqlite3 /home/paul/Desktop/medical.db < /home/paul/projects/medical/medical.sql
#sqlite3 medical.db "select * from medication;" | less
#sqlite3 medical.db "select * from dose;" | less
