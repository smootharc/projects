shopt -s globstar
shopt -s autocd
shopt -s cdspell
shopt -s extglob
shopt -s nocaseglob
set -o vi
#set +H
#shopt -s failglob
ulimit -s 65536
export BROWSER=google-chrome-stable
export INFO_PRINT_COMMAND="a2ps -s 2"
export EDITOR=vim
export VISUAL=vim
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=erasedups:ignoreboth
export PAGER=less
export CDPATH=.:~:~/.config
export RLWRAP_HOME=$HOME/.local/share/rlwrap
alias pics='feh -rqdFD -5 &>/dev/null'
alias weather='curl wttr.in/08096'
alias meds='gcalcli --calendar Medical'
alias mana='man -a'
alias mank='man -k'
alias unrardl='{ pushd ~/Downloads;unrar x -r -o- "*.rar";popd; }'
alias hdf='df -h -T -x devtmpfs -x tmpfs'
alias hdt='for d in /dev/sd?; do hddtemp $d; done'
alias hds='udisksctl status'

hdu () 
{

[[ -n $1 ]] && udisksctl unmount --block-device "/dev/$1"

}

= ()
{
    bc -l <<< "$@"
}

now ()
{
    date +"%Y-%m-%d %H:%M"
}
