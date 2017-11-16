#!/usr/bin/awk -f

function scriptname () {

    split(ENVIRON["_"],scriptarray,"/")
    returnval = scriptarray[length(scriptarray)]
    return returnval

}


BEGIN {

    search = ARGV[1]
    ARGC = 2
    if ( length(search) == 0 ) {
        print "\n", "Usage:", scriptname(), "somefiletype.\n"
        exit 1
    }
    ARGV[1] = "/etc/mime.types"
    ARGC = 2

}

$1 ~ search && NF > 1 {
        for ( i = 2; i <=  NF; i++ ) {
            output = output$i"|"
        }
    }

END {
    printf "%s",  substr(output, 1, length(output) - 1)
}
