#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/Screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

CAPTURE_SUCCESS=false
if command -v grimblast &>/dev/null; then
    if SLURP_ARGS="-b 00000000" grimblast --freeze copysave area "$FILE"; then
        CAPTURE_SUCCESS=true
    fi
elif command -v grim &>/dev/null && command -v slurp &>/dev/null; then
    GEOM=$(slurp -b 00000000 2>/dev/null)
    if [ -n "$GEOM" ]; then
        if grim -g "$GEOM" "$FILE"; then
            command -v wl-copy &>/dev/null && wl-copy < "$FILE"
            CAPTURE_SUCCESS=true
        fi
    fi
fi

if [ "$CAPTURE_SUCCESS" = true ]; then
    ACTION=$(notify-send "Screenshot Captured" "Region saved to Pictures and clipboard" \
        -i "$FILE" \
        -t 600000 \
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
