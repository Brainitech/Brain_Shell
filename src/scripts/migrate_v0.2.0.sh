#!/bin/bash
# v0.2.0 OTA Migration Script
# Triggered by Quickshell QML on startup if flag is missing.

set -e

FLAG_FILE="$HOME/.config/Brain_Shell/.v0.2.0_migrated"
REPO_DIR="$HOME/.local/src/Brain_Shell"

# 1. Determine active Hyprland config
HYPR_DIR="$HOME/.config/hypr"
CONF=""
if [[ -f "$HYPR_DIR/hyprland.lua" ]]; then
    CONF="$HYPR_DIR/hyprland.lua"
elif [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
    CONF="$HYPR_DIR/hyprland.conf"
fi

# 2. Deploy modular autostarts
mkdir -p "$HOME/.config/Brain_Shell/hypr"
cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.conf" "$HOME/.config/Brain_Shell/hypr/brain-shell.conf"
cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.lua" "$HOME/.config/Brain_Shell/hypr/brain-shell.lua"
sed -i "s|\$HOME/.local/src/Brain_Shell|$REPO_DIR|g" "$HOME/.config/Brain_Shell/hypr/brain-shell.conf" "$HOME/.config/Brain_Shell/hypr/brain-shell.lua"

if [[ -n "$CONF" ]]; then
    # 3. Backup config
    TS=$(date +%Y%m%d_%H%M%S)
    cp "$CONF" "${CONF}.mod-backup-${TS}"
    
    # 4. Scrub legacy autostarts
    python3 -c '
import sys, re
with open(sys.argv[1], "r") as f: content = f.read()

# Scrub legacy inline autostarts (conf)
content = re.sub(r"\n*# Brain Shell Autostarts\n(exec-once = .*\n){1,8}", "\n", content)
# Scrub legacy inline autostarts (lua)
content = re.sub(r"\n*-- Brain Shell Autostarts\nhl\.on\(\"hyprland\.start\", function\(\)\n(    hl\.exec_cmd\(.*\)\n){1,8}end\)\n*", "\n", content)
# Scrub legacy keybind injections (conf)
content = re.sub(r"\n*# Brain_ShellKeybinds\nsource = .*Brain_ShellKeybinds\.conf\n*", "\n", content)
# Scrub legacy keybind injections (lua)
content = re.sub(r"\n*-- Brain_ShellKeybinds\ndofile\(.*Brain_ShellKeybinds\.lua\"\)\n*", "\n", content)

with open(sys.argv[1], "w") as f: f.write(content.strip() + "\n")
' "$CONF"

    # 5. Inject modular source lines
    if ! grep -q "brain-shell" "$CONF"; then
        if [[ "$CONF" == *.lua ]]; then
            cat << 'EOF' >> "$CONF"

-- >>> Brain Shell Startup >>>
dofile(os.getenv("HOME") .. "/.config/Brain_Shell/hypr/brain-shell.lua")
-- <<< Brain Shell Startup <<<
EOF
        else
            cat << 'EOF' >> "$CONF"

# >>> Brain Shell Startup >>>
source = ~/.config/Brain_Shell/hypr/brain-shell.conf
# <<< Brain Shell Startup <<<
EOF
        fi
    fi
    
    # Force hyprland to reload
    hyprctl reload &>/dev/null || true
fi

# 6. Set flag and notify
touch "$FLAG_FILE"
notify-send -a "Brain Shell" -u normal "Update Successful" "v0.2.0 Migration Complete."
