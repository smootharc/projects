#!/bin/sh

awk -F, '

function thirdslash(url) {
    
    slashcount = 0

    for (i=1; i <= length(url); i++) {

        if ("/" == substr(url,i,1))
            slashcount++

        if (slashcount == 3)
            return substr(url,1,i-1)
    }

    return url
} 

function bareurl(url) {

    split(url,a,"/")
    return a[1]"/"a[2]"/"a[3]
    
}


BEGIN {

#    print ARGC
#    for (i = 0; i < ARGC; i++) print ARGV[i]
    if ( ARGC > 2 || ARGC < 2 ) { printf( "\nNo File Name.\n");print;exit }
    else print

}

/http/ { printf( "%02d %-40s %-25s %-20s\n", ++count, bareurl($1), $2, $3) } 

END { print "" }

' $1
