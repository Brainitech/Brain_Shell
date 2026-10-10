#!/usr/bin/env bash
if [ -z "$BRAIN_SHELL_CONFIG_DIR" ]; then
    export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"
fi

if [ "$1" = "ipc" ]; then
    shift
    exec quickshell ipc -p "@out@/share/brain-shell" "$@"
fi

if [ -x "@out@/share/brain-shell/src/scripts/init_user_dir.sh" ]; then
    "@out@/share/brain-shell/src/scripts/init_user_dir.sh" || true
fi

# Ensure daemons are killed when shell exits.
cleanup() {
    kill $(jobs -p) 2>/dev/null || true
}
trap cleanup EXIT TERM INT

# Start session daemons.
if [ "${BRAIN_SHELL_WALLPAPER_DAEMON:-awww}" = "awww" ]; then
    pgrep -x awww-daemon >/dev/null || awww-daemon &
else
    pgrep -x "${BRAIN_SHELL_WALLPAPER_DAEMON}" >/dev/null || ${BRAIN_SHELL_WALLPAPER_DAEMON} &
fi
pgrep -x hypridle >/dev/null || hypridle &
pgrep -f "cliphist store" >/dev/null || {
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
}

if [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]]; then
    if systemctl --user list-unit-files hyprpolkitagent.service >/dev/null 2>&1; then
        systemctl --user is-active hyprpolkitagent.service >/dev/null 2>&1 || systemctl --user start hyprpolkitagent
    elif command -v hyprpolkitagent >/dev/null 2>&1; then
        pgrep -x hyprpolkitagent >/dev/null || hyprpolkitagent &
    fi
fi

quickshell -p "@out@/share/brain-shell" "$@"
