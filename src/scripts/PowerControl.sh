#!/bin/bash

case "$1" in
    shutdown)
        (setsid bash -c 'hyprshutdown --post-cmd "systemctl poweroff"' &>/dev/null &);;
    reboot)
        (setsid bash -c 'hyprshutdown --post-cmd "systemctl reboot"' &>/dev/null &);;
    logout)
        (setsid bash -c 'hyprshutdown --post-cmd "loginctl terminate-user $USER"' &>/dev/null &);;
    *)
        exit 1
        ;;
esac