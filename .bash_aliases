shopt -s globstar
shopt -s autocd
shopt -s cdspell
shopt -s extglob
shopt -s nocaseglob
set -o vi
#set +H
#shopt -s failglob
ulimit -s 65536

hdf () {

    df -h -T -x devtmpfs -x tmpfs -x squashfs

}

hdt () {

    for d in /dev/sd?
        do hddtemp $d
    done

}

hdu () {

    [[ -n $1 ]] && udisksctl unmount --block-device "/dev/$1"

}

= () {

    bc -l <<< "$@"

}

now () {

    date +"%Y-%m-%d %H:%M"

}

export -f now
export -f =
export -f hdu
export -f hdf
export BROWSER=google-chrome-stable
export INFO_PRINT_COMMAND="a2ps -s 2"
export EDITOR=vim
export VISUAL=vim
export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTCONTROL=erasedups:ignoreboth
export PAGER=less
export CDPATH=.:~:~/.config
export RLWRAP_HOME=$HOME/.local/share/rlwrap
export RESTIC_PASSWORD_FILE=~/.config/restic/password
export RESTIC_REPOSITORY=/backup/$USER


alias keys='less /usr/include/X11/keysymdef.h'
alias pics='feh -rqdFD -5 &>/dev/null'
alias weather='curl wttr.in/08096'
alias meds='gcalcli --calendar Medical'
alias hds='udisksctl status'
alias unrardl='{ pushd ~/Downloads;unrar x -r -o- "*.rar";popd; }'
