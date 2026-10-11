#!/usr/bin/env bash
#
# Brain Shell
# Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# Non-destructive self-initialization of user mutable configuration directory.
# Safe to run on every launch (idempotent).

CONFIG_DIR="${BRAIN_SHELL_CONFIG_DIR:-$HOME/.config/Brain_Shell}"

if [ -n "$BRAIN_SHELL_INSTALL_DIR" ]; then
    INSTALL_DIR="$BRAIN_SHELL_INSTALL_DIR"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    POSSIBLE_DIR="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd)"
    if [ -f "$POSSIBLE_DIR/shell.qml" ]; then
        INSTALL_DIR="$POSSIBLE_DIR"
    else
        INSTALL_DIR="$HOME/.local/src/Brain_Shell"
    fi
fi

VERSION_MARKER="$CONFIG_DIR/.init_done_v0.2.0"

# Check if already initialized for this version
if [ -f "$VERSION_MARKER" ]; then
    exit 0
fi

# 1. Create target directories
mkdir -p "$CONFIG_DIR/src/user_data" "$CONFIG_DIR/matugen" 2>/dev/null || {
    echo "[Brain_Shell] Warning: Failed to create directories in $CONFIG_DIR" >&2
}

# 2. Copy templates if missing (non-destructive)
copy_template() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$dst" ]; then
        if [ -f "$src" ]; then
            cp "$src" "$dst" 2>/dev/null || {
                echo "[Brain_Shell] Warning: Failed to copy template $src to $dst" >&2
            }
        else
            echo "[Brain_Shell] Notice: Template $src not found" >&2
        fi
    fi
}

copy_template "$INSTALL_DIR/src/config/hypridle.conf" "$CONFIG_DIR/hypridle.conf"
copy_template "$INSTALL_DIR/src/config/hyprlock.conf" "$CONFIG_DIR/hyprlock.conf"
copy_template "$INSTALL_DIR/src/config/matugen.toml"  "$CONFIG_DIR/matugen.toml"
copy_template "$INSTALL_DIR/src/config/brain-shell-colors.json.example" "$CONFIG_DIR/brain-shell-colors.json.example"
copy_template "$INSTALL_DIR/src/config/colors.conf.template" "$CONFIG_DIR/colors.conf.template"
copy_template "$INSTALL_DIR/src/config/autostart/BrainShell-hyprland.conf" "$CONFIG_DIR/BrainShell-hyprland.conf"
copy_template "$INSTALL_DIR/src/config/autostart/BrainShell-hyprland.lua"  "$CONFIG_DIR/BrainShell-hyprland.lua"

# 3. Detect Hyprland configuration format (Lua vs Hyprlang)
# BRAIN_SHELL_CONFIG_TYPE can be set by a wrapper (e.g. Nix) to "lua" or "hyprlang"
# to override file-based detection for declarative setups where hyprland.lua
# may not exist at the standard path.
HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"
HYPR_LUA="$HYPR_DIR/hyprland.lua"

IS_LUA=0
if [ "${BRAIN_SHELL_CONFIG_TYPE:-}" = "lua" ]; then
    IS_LUA=1
elif [ "${BRAIN_SHELL_CONFIG_TYPE:-}" = "hyprlang" ]; then
    IS_LUA=0
elif [ -f "$HYPR_LUA" ]; then
    IS_LUA=1
fi

# 4. Touch initial user state files if missing
touch_state() {
    local file="$1"
    if [ ! -f "$file" ]; then
        if [[ "$file" == *.json ]]; then
            echo '{}' > "$file" 2>/dev/null || {
                echo "[Brain_Shell] Warning: Failed to initialize state file $file" >&2
            }
        else
            touch "$file" 2>/dev/null || {
                echo "[Brain_Shell] Warning: Failed to initialize state file $file" >&2
            }
        fi
    fi
}

touch_state "$CONFIG_DIR/src/user_data/shell_prefs.json"
touch_state "$CONFIG_DIR/src/user_data/wallpaper.json"
touch_state "$CONFIG_DIR/src/user_data/tasks.json"
touch_state "$CONFIG_DIR/src/user_data/config_Provider.json"

if [ "$IS_LUA" -eq 1 ]; then
    touch_state "$CONFIG_DIR/Brain_ShellKeybinds.lua"
else
    touch_state "$CONFIG_DIR/Brain_ShellKeybinds.conf"
fi

# 5. Smart Hyprland integration (inject source line or seed default config)
if [ -f "$HYPR_LUA" ]; then
    if [ -w "$HYPR_LUA" ] && ! grep -q "BrainShell-hyprland" "$HYPR_LUA" 2>/dev/null; then
        cat >> "$HYPR_LUA" <<'EOF'

-- >>> Brain Shell Autostart & Integration >>>
local bs_autostart = os.getenv("HOME") .. "/.config/Brain_Shell/BrainShell-hyprland.lua"
local f = io.open(bs_autostart, "r")
if f then f:close(); dofile(bs_autostart) end
-- <<< Brain Shell Autostart & Integration <<<
EOF
    fi
elif [ -f "$HYPR_CONF" ]; then
    if [ -w "$HYPR_CONF" ] && ! grep -q "BrainShell-hyprland" "$HYPR_CONF" 2>/dev/null; then
        cat >> "$HYPR_CONF" <<'EOF'

# >>> Brain Shell Autostart & Integration >>>
source = ~/.config/Brain_Shell/BrainShell-hyprland.conf
# <<< Brain Shell Autostart & Integration <<<
EOF
    fi
elif [ ! -e "$HYPR_CONF" ] && [ ! -e "$HYPR_LUA" ]; then
    # No Hyprland config found — seed Brain_Shell's curated Lua template.
    HYPR_TEMPLATE="$INSTALL_DIR/src/config/hypr_template"
    if [ -d "$HYPR_TEMPLATE" ]; then
        mkdir -p "$HYPR_DIR" 2>/dev/null || true
        cp -r "$HYPR_TEMPLATE/"* "$HYPR_DIR/" 2>/dev/null || {
            echo "[Brain_Shell] Warning: Failed to seed Hyprland config from template" >&2
        }
        
        # Inject the autostart into the newly created template
        if [ -w "$HYPR_LUA" ]; then
            cat >> "$HYPR_LUA" <<'EOF'

-- >>> Brain Shell Autostart & Integration >>>
local bs_autostart = os.getenv("HOME") .. "/.config/Brain_Shell/BrainShell-hyprland.lua"
local f = io.open(bs_autostart, "r")
if f then f:close(); dofile(bs_autostart) end
-- <<< Brain Shell Autostart & Integration <<<
EOF
        fi
    fi
fi

# 6. Copy default wallpapers if missing (non-destructive)
WALLPAPER_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"
mkdir -p "$WALLPAPER_DIR" 2>/dev/null || true
if [ -d "$INSTALL_DIR/src/assets/wallpapers" ]; then
    cp -n -r "$INSTALL_DIR/src/assets/wallpapers"/* "$WALLPAPER_DIR/" 2>/dev/null || true
fi

# 7. Mark initialization complete
touch "$VERSION_MARKER" 2>/dev/null || true

exit 0
