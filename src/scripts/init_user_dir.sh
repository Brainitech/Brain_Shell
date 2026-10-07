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

# 3. Touch initial user state files if missing
touch_state() {
    local file="$1"
    if [ ! -f "$file" ]; then
        touch "$file" 2>/dev/null || {
            echo "[Brain_Shell] Warning: Failed to initialize state file $file" >&2
        }
    fi
}

touch_state "$CONFIG_DIR/src/user_data/shell_prefs.json"
touch_state "$CONFIG_DIR/src/user_data/wallpaper.json"
touch_state "$CONFIG_DIR/src/user_data/tasks.json"
touch_state "$CONFIG_DIR/src/user_data/config_Provider.json"

# 4. Mark initialization complete
touch "$VERSION_MARKER" 2>/dev/null || true

exit 0
