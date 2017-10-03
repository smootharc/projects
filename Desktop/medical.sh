#!/bin/bash
pushd ~/Desktop
gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk -F"\t" 'BEGIN { count=1 } !(/00:00/ || /Doctor/ || /Blood/ || /Weight/ || /Alcohol/ ) { printf "%s|%s|%s|%s|%s\n", count++, $1, $2, $5, $6}' > dose.dat
gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk 'BEGIN { count=1 } /Weight/ { printf "%s|%s|%s|%s|", count++, $1, $2, $6; for(i=7;i<=NF;i++) { printf "%s ", $i; }; printf "\n" }' > weight.dat
gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk 'BEGIN { count=1 } /Alcohol/ { printf "%s|%s|%s|%s\n", count++, $1, $6, $7 }' > alcohol.dat
cat dose.dat | cut -d"|" -f 4 | sort | uniq > medication.dat
sqlite3 medical.db < medical.sql
sqlite3 medical.db "select * from dose;" | less
sqlite3 medical.db "select * from weight;" | less
sqlite3 medical.db "select * from alcohol;" | less
sqlite3 medical.db "select * from medication;" | less
popd

#gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk -F"\t" 'BEGIN { count=1 } { printf "%s|%s|%s|%s|%s\n", count++, $1, $2, $5, $6 }' | less
#gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk 'BEGIN { count=1 } !(/00:00/ || /Doctor/ || /Blood/ || /Weight/ || /Alcohol/ ) { printf "%s|%s|%s|%s|%s", count++, $1, $2, $5, $6 } { for(i=7;i<=NF;i++) { printf "%s ", $i; } printf "\n" }'
#gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk 'BEGIN { count=1 } !(/00:00/ || /Doctor/ || /Blood/ || /Weight/ || /Alcohol/ ) { printf "%s|%s|%s|%s|%s", count++, $1, $2, $5, $6 } { for(i=7;i<=NF;i++) { printf "%s ", $i; } printf "\n" }' > medications.dat
#gcalcli --tsv --calendar Medical agenda 2017-01-01 now | awk 'BEGIN { count=1 } /Weight/ { printf "%s|%s|%s|%s|", count++, $1, $2, $6; for(i=7;i<=NF;i++) { printf "%s ", $i; }; printf "\n" }' > weight.dat
