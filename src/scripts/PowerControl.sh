#!/bin/bash

case "$1" in
    shutdown)
        (setsid bash -c 'systemctl poweroff' &>/dev/null &);;
    reboot)
        (setsid bash -c 'systemctl reboot' &>/dev/null &);;
    logout)
        (setsid bash -c 'loginctl terminate-user $USER' &>/dev/null &);;
    *)
        exit 1
        ;;
esac