shopt -s globstar
shopt -s autocd
shopt -s cdspell
#shopt -s failglob
shopt -s extglob
shopt -s nocaseglob
set -o vi
ulimit -s 65536
PATH=~/.local/bin:$PATH
export BROWSER=google-chrome-stable
export INFO_PRINT_COMMAND="a2ps -s 2"
export EDITOR=vim
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=erasedups:ignoreboth
export PAGER=less
export CDPATH=.:~:~/.config
#LS_COLORS=$LS_COLORS;export LS_COLORS
#export LS_COLORS
#alias ls='ls --color=auto'
alias pics='feh -rqdF'
alias pan='pan &> /dev/null &'
alias weather='curl wttr.in/08096'
#alias byobu='uxterm -maximize -e byobu &'
#alias meds='gcalcli --calendar Medical'

ddl () 
{
        if numfmt -- "$1" &> /dev/null; then

                find /home/paul/Downloads -type f -mmin +"$1" -delete
                find /home/paul/Downloads -not -path '/home/paul/Downloads' -type d -empty -delete

        else

                echo "No or non-numeric time specified.  Nothing deleted."

        fi
}

videoextensions ()
{
        awk '/video/ && $2 != "" { $1=""; gsub(/^ /,"",$0);gsub(" ","|");output = output $0 "|"} END {print substr(output,1,length(output) -1) }' /etc/mime.types
}

vdl ()
{
        if ! feh -rqdFnSmtime ~/Downloads &> /dev/null; then
                echo "No images found!"
        fi
        vids ~/Downloads
        ddl $1
}

= ()
{
        bc -l <<< "$@"
}

now ()
{
        date +"%Y-%m-%d %H:%M"
}

tclsh ()
{
        rlwrap tclsh "$@"
}
