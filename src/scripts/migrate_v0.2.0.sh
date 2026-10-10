#!/usr/bin/env bash
# v0.2.0 OTA Migration Script
# Triggered by Quickshell QML on startup if flag is missing.

CONFIG_DIR="${BRAIN_SHELL_CONFIG_DIR:-$HOME/.config/Brain_Shell}"
FLAG_FILE="$CONFIG_DIR/.v0.2.0_migrated"
if [ -n "$BRAIN_SHELL_INSTALL_DIR" ]; then
    REPO_DIR="$BRAIN_SHELL_INSTALL_DIR"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    POSSIBLE_DIR="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd)"
    if [ -f "$POSSIBLE_DIR/shell.qml" ]; then
        REPO_DIR="$POSSIBLE_DIR"
    else
        REPO_DIR="$HOME/.local/src/Brain_Shell"
    fi
fi

# 1. Determine active Hyprland config
HYPR_DIR="$HOME/.config/hypr"
CONF=""
if [[ -f "$HYPR_DIR/hyprland.lua" ]]; then
    CONF="$HYPR_DIR/hyprland.lua"
elif [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
    CONF="$HYPR_DIR/hyprland.conf"
fi

# 2. Check if already migrated
if [[ -n "$CONF" ]] && grep -q "brain-shell" "$CONF" && ( [ -f "$CONFIG_DIR/BrainShell-hyprland.conf" ] || [ -f "$CONFIG_DIR/BrainShell-hyprland.lua" ] ); then
    touch "$FLAG_FILE"
    exit 2 # Silently recover flag
fi

# 3. Deploy modular autostarts
mkdir -p "$CONFIG_DIR/hypr"
cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.conf" "$CONFIG_DIR/BrainShell-hyprland.conf" || exit 1
cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.lua" "$CONFIG_DIR/BrainShell-hyprland.lua" || exit 1
sed -i "s|\$HOME/.local/src/Brain_Shell|$REPO_DIR|g" "$CONFIG_DIR/BrainShell-hyprland.conf" "$CONFIG_DIR/BrainShell-hyprland.lua"
sed -i "s|os.getenv(\"HOME\") .. \"/.local/src/Brain_Shell\"|\"$REPO_DIR\"|g" "$CONFIG_DIR/BrainShell-hyprland.lua"

if [[ -n "$CONF" ]]; then
    # 4. Backup config
    TS=$(date +%Y%m%d_%H%M%S)
    cp "$CONF" "${CONF}.mod-backup-${TS}"
    
    # 5. Scrub legacy autostarts
    python3 -c '
import sys, re
try:
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
except Exception as e:
    sys.exit(1)
' "$CONF" || exit 1

    # 6. Inject modular source lines
    if ! grep -q "brain-shell" "$CONF"; then
        if [[ "$CONF" == *.lua ]]; then
            cat << 'EOF' >> "$CONF"

-- >>> Brain Shell Startup >>>
dofile(os.getenv("HOME") .. "/.config/Brain_Shell/BrainShell-hyprland.lua")
-- <<< Brain Shell Startup <<<
EOF
        else
            cat << 'EOF' >> "$CONF"

# >>> Brain Shell Startup >>>
source = ~/.config/Brain_Shell/BrainShell-hyprland.conf
# <<< Brain Shell Startup <<<
EOF
        fi
    fi
    
    # Force hyprland to reload
    hyprctl reload &>/dev/null || true
fi

# 7. Migrate JSON user data to shell_prefs.json
python3 -c '
import json, os
config_dir = os.environ.get("BRAIN_SHELL_CONFIG_DIR") or os.path.expanduser("~/.config/Brain_Shell")
ud = os.path.join(config_dir, "src/user_data")
prefs = os.path.join(ud, "shell_prefs.json")
old_files = ["animation_prefs.json", "update_prefs.json", "screenrec.json", "hotspot.json"]
merged = {}
if os.path.exists(prefs):
    try:
        with open(prefs, "r") as f: merged = json.load(f)
    except: pass
changed = False
for of in old_files:
    ofp = os.path.join(ud, of)
    if os.path.exists(ofp):
        try:
            with open(ofp, "r") as f: data = json.load(f)
            merged.update(data)
            changed = True
        except: pass
        try: os.remove(ofp)
        except: pass
if changed:
    try:
        with open(prefs, "w") as f: json.dump(merged, f, indent=4)
    except: pass
' || true

# 8. Set flag and notify
# Pre-generate default colors to prevent unstyled first boot
mkdir -p "$CONFIG_DIR/matugen"
(cd "$REPO_DIR" && matugen image "src/assets/wallpapers/brain-shell-default-0.png" -c "src/config/matugen.toml" -m dark --source-color-index 0 --type scheme-smart >/dev/null 2>&1 || true)

touch "$FLAG_FILE"
notify-send -a "Brain Shell" -u normal "Update Successful" "v0.2.0 Migration Complete."
exit 0
