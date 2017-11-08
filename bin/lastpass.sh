#!/usr/bin/awk -f 

function bareurl(url) {

    split(url,a,"/")
    return a[1]"/"a[2]"/"a[3]
    
}

BEGIN {

    ARGV[1] = "/home/paul/Documents/lastpass.csv"
    ARGC = 2
    FS = ","
    print

}

/http/ { printf( "%02d %-40s %-25s %-20s\n", ++count, bareurl($1), $2, $3) } 

END { print "" }


