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
export VISUAL=vim
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
alias meds='gcalcli --calendar Medical'
alias mana='man -a'
alias mank='man -k'

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
