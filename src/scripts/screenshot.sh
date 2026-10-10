#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/Screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

if SLURP_ARGS="-b 00000000" grimblast --freeze copysave area "$FILE"; then
    ACTION=$(notify-send "Screenshot Captured" "Region saved to Pictures and clipboard" \
        -i "$FILE" \
        --action="icat=View in Terminal" \
        --action="folder=Open Folder")

    case "$ACTION" in
        "icat")
            ${BRAIN_SHELL_TERMINAL:-kitty} --hold sh -c "kitten icat '$FILE'" > /dev/null 2>&1 &
            ;;
        "folder")
            ${BRAIN_SHELL_TERMINAL:-kitty} ranger --selectfile="$FILE" > /dev/null 2>&1 &
            ;;
    esac
fi
