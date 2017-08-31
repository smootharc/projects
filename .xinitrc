
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

#[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
xrdb ~/.Xresources
#start-pulseaudio-x11 &
#sleep 1 &
#xset s off &
#Numbers for xset dpms are in seconds
#sleep 1 &
#xset dpms 600 1200 1800 &
#Numbers for xautolock -time are in minutes
#xautolock -time 720 -locker slock &
#xautolock -time 720 -locker "xtrlock -b" &
#urxvtd -q -o -f 
#urxvtc &
#dex -a &
#xscreensaver -no-splash &
sabnzbdplus -b 0 &
caffeine &
caffeine-indicator &
udiskie -a -2 &
clipit  &
google-chrome-stable --password-store=basic --no-default-browser-check &
echo $DESKTOP_STARTUP_ID > desktopid.txt
exec awesome
