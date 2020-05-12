shopt -s globstar
shopt -s autocd
shopt -s cdspell
shopt -s extglob
shopt -s nocaseglob
stty -ixon
#set -o vi
#set +H
#shopt -s failglob
ulimit -s 65536

hdt () {

    for d in /dev/sd?
        do hddtemp $d
    done

}

hdu () {

    [[ -n $1 ]] && udisksctl unmount --block-device "/dev/$1"

}

calc () {

    bc -l <<< "$@"

}

export -f calc
export -f hdu
export -f hdt
export INFO_PRINT_COMMAND="a2ps -s 2"
export EDITOR=vim
export VISUAL=vim
export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTCONTROL=erasedups:ignoreboth
export PAGER=less
export CDPATH=.:~:~/.config:~/.config/systemd
export RESTIC_PASSWORD_FILE=~/.config/restic/password
export RESTIC_REPOSITORY=/backup/$USER

alias we='curl wttr.in/08096'
alias meds='gcalcli --calendar Medical'
alias hds='udisksctl status'

[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
