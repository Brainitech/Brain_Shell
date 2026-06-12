#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Brain Shell CLI — Standalone launcher & manager
#  github.com/Brainitech/Brain_Shell
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

_script_src="${BASH_SOURCE[0]}"
# Resolve symlinks to get the real script directory (for global brain-shell command)
if [[ -L "$_script_src" ]]; then
    _script_src=$(readlink -f "$_script_src" 2>/dev/null || readlink "$_script_src")
fi
SCRIPT_DIR="${_script_src%/*}"
if [[ "$SCRIPT_DIR" == "$_script_src" ]] && [[ ! -f "$_script_src" ]]; then
    SCRIPT_DIR="$PWD"
fi
if [[ "$SCRIPT_DIR" != /* ]]; then
    SCRIPT_DIR="$PWD/$SCRIPT_DIR"
fi
unset _script_src

QS_BIN="${BRAIN_SHELL_QS:-qs}"
NIXGL_BIN="${BRAIN_SHELL_NIXGL:-}"
if [[ -n "${QML2_IMPORT_PATH:-}" ]] && [[ -z "${QML_IMPORT_PATH:-}" ]]; then
    export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
fi

SHELL_QML="${SCRIPT_DIR}/shell.qml"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Brain_Shell"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Brain_Shell"
PID_FILE="/tmp/brain_shell.pid"
PIPE="/tmp/brain_shell_ipc.pipe"
VERSION_FILE="${SCRIPT_DIR}/version"
BRIGHTNESS_SAVE_FILE="/tmp/brain_shell_brightness_saved.txt"

if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(<"$VERSION_FILE")
else
    VERSION="0.1.0"
fi

show_help() {
    cat <<'EOF'
Brain Shell CLI — Desktop Environment Control

Usage: brain-shell [COMMAND]

Commands:
    (none)                            Launch Brain_Shell
    update                            Update Brain_Shell
    reload                            Restart Brain_Shell
    sync                              Regenerate hyprland binds
    quit                              Stop Brain_Shell
    lock                              Activate lockscreen
    screen [on|off]                   Turn screen on/off
    suspend                           Suspend the system

    brightness <percent> [monitor]    Set brightness (0-100)
    brightness +/-<delta> [monitor]   Adjust brightness relatively
    brightness -s [monitor]           Save current brightness
    brightness -r [monitor]           Restore saved brightness
    brightness -l                     List monitors

    volume-up                         Increase volume
    volume-down                       Decrease volume
    volume-mute                       Toggle volume mute
    mic-mute                          Toggle microphone mute
    caffeine                          Toggle caffeine (idle inhibition)
    gamemode                          Toggle game mode (reduced motion)
    nightlight                        Toggle night light (blue light filter)

    run <command>                     Send IPC command to running shell
      Available: dashboard, dashboard-home, dashboard-stats, dashboard-kanban,
                 dashboard-launcher, dashboard-config, launcher,
                 audio, network, notifications, clipboard, wallpaper,
                 arch-menu, screenshot, color-picker, focus, close-all

    help, -h, --help                  Show this help message
    version, -v, --version            Show Brain_Shell version
    goodbye                           Uninstall Brain_Shell :(
    install <target>                  Install compositor integration
      brain-shell install hyprland          Add to Hyprland autostart (.conf)
      brain-shell install hyprland --lua    Add to Hyprland autostart (Lua)
      brain-shell install hyprland --conf   Add to Hyprland autostart (safe)
    remove <target>                   Remove compositor integration
      brain-shell remove hyprland           Remove from Hyprland config

Examples:
    brain-shell brightness 75                      Set all monitors to 75%
    brain-shell brightness 50 HDMI-A-1             Set HDMI-A-1 to 50%
    brain-shell brightness +10                     Increase brightness by 10%
    brain-shell brightness -s                      Save current brightness
    brain-shell brightness -r                      Restore saved brightness
    brain-shell run dashboard-home                 Open dashboard on Home tab
    brain-shell run launcher                       Open app launcher
    brain-shell run screenshot                     Take a region screenshot
    brain-shell install hyprland                   Auto-start with Hyprland
    brain-shell reload                             Quick restart after edits

EOF
}

# ── Config bootstrap ──────────────────────────────────────────────────────────
ensure_config_files() {
    local cfg_dir="${CONFIG_DIR}/src/user_data"
    mkdir -p "$cfg_dir"

    local provider_json="${cfg_dir}/config_Provider.json"
    if [[ ! -f "$provider_json" ]]; then
        printf '{"configProvider":"lua"}' > "$provider_json"
    fi

    local shell_json="${cfg_dir}/shell_config.json"
    if [[ ! -f "$shell_json" ]]; then
        printf '{\n  "animationSpeed": 1.0,\n  "barEnabled": true,\n  "dashboardWidth": 900,\n  "dashboardHeight": 520,\n  "focusModeOnStartup": false,\n  "autoUpdateCheck": true\n}\n' > "$shell_json"
    fi

    local permon_json="${cfg_dir}/per_monitor.json"
    if [[ ! -f "$permon_json" ]]; then
        printf '{}' > "$permon_json"
    fi

    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/Brain_Shell"
}

# ── Process management ────────────────────────────────────────────────────────
find_brain_shell_pid() {
    local pid
    pid=$(pgrep -f "qs.*${SCRIPT_DIR}/shell.qml" 2>/dev/null | head -1)
    if [[ -z "$pid" ]]; then
        pid=$(pgrep -f "quickshell.*${SCRIPT_DIR}/shell.qml" 2>/dev/null | head -1)
    fi
    if [[ -z "$pid" ]]; then
        pid=$(pgrep -f "qs.*shell.qml" 2>/dev/null | head -1)
    fi
    if [[ -z "$pid" ]]; then
        pid=$(pgrep -f "quickshell.*shell.qml" 2>/dev/null | head -1)
    fi
    if [[ -z "$pid" ]]; then
        pid=$(pgrep -a "qs" 2>/dev/null | grep -F "$SCRIPT_DIR" | awk '{print $1}' | head -1)
    fi
    if [[ -z "$pid" ]]; then
        pid=$(pgrep -a quickshell 2>/dev/null | grep -F "$SCRIPT_DIR" | awk '{print $1}' | head -1)
    fi
    echo "$pid"
}

find_brain_shell_pid_cached() {
    local pid
    if [[ -f "$PID_FILE" ]]; then
        pid=$(<"$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        fi
        rm -f "$PID_FILE"
    fi
    pid=$(find_brain_shell_pid)
    echo "$pid"
}

launch_shell() {
    local pid
    pid=$(find_brain_shell_pid)
    if [[ -n "$pid" ]]; then
        echo "Brain_Shell is already running (PID $pid)"
        return 0
    fi

    ensure_config_files

    echo "Starting Brain_Shell v${VERSION}..."

    local launch_cmd=("$QS_BIN" -p "$SHELL_QML")
    if [[ -n "$NIXGL_BIN" ]] && command -v "$NIXGL_BIN" &>/dev/null; then
        launch_cmd=("$NIXGL_BIN" "${launch_cmd[@]}")
    fi

    nohup "${launch_cmd[@]}" > /dev/null 2>&1 &
    local new_pid=$!
    echo "$new_pid" > "$PID_FILE"

    # Wait for shell to initialize (Quickshell takes 2-4 seconds)
    sleep 3
    if ! kill -0 "$new_pid" 2>/dev/null; then
        echo "Error: Brain_Shell failed to start. Check logs with: qs -p ${SHELL_QML}"
        rm -f "$PID_FILE"
        exit 1
    fi

    echo "Brain_Shell started (PID $new_pid)"
}

restart_shell() {
    local pid
    pid=$(find_brain_shell_pid_cached)

    if [[ -n "$pid" ]]; then
        echo "Stopping Brain_Shell (PID $pid)..."
        kill "$pid" 2>/dev/null || true
        local waited=0
        while kill -0 "$pid" 2>/dev/null && [[ $waited -lt 30 ]]; do
            sleep 0.1
            waited=$((waited + 1))
        done
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi

    launch_shell
}

quit_shell() {
    local pid
    pid=$(find_brain_shell_pid_cached)

    if [[ -n "$pid" ]]; then
        echo "Stopping Brain_Shell (PID $pid)..."
        kill "$pid" 2>/dev/null || true
        sleep 0.3
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
        echo "Brain_Shell stopped."
    else
        echo "Brain_Shell is not running."
    fi
}

lock_screen() {
    if [[ -p "$PIPE" ]]; then
        echo "lockscreen" > "$PIPE" &
        exit 0
    fi

    local pid
    pid=$(find_brain_shell_pid_cached)
    if [[ -n "$pid" ]] && command -v qs &>/dev/null; then
        qs ipc --pid "$pid" call brain-shell run lockscreen 2>/dev/null && exit 0
    fi

    if command -v hyprlock &>/dev/null; then
        hyprlock &
    elif command -v loginctl &>/dev/null; then
        loginctl lock-session
    else
        echo "Error: Could not lock screen"
        exit 1
    fi
}

# ── IPC ───────────────────────────────────────────────────────────────────────
# ── IPC target mapping (friendly name → original IpcManager target) ──────────
# Translates brain-shell run <cmd> to the correct qs ipc call <target> toggle
declare -A IPC_MAP=(
    # Dashboard
    ["dashboard"]="dashboard-home"
    ["dashboard-home"]="dashboard-home"
    ["dashboard-stats"]="dashboard-stats"
    ["dashboard-kanban"]="dashboard-kanban"
    ["dashboard-launcher"]="dashboard-launcher"
    ["dashboard-config"]="dashboard-config"
    ["launcher"]="dashboard-launcher"
    # Popups
    ["audio"]="audioOut-toggle"
    ["network"]="wifi-toggle"
    ["notifications"]="notifications-toggle"
    ["clipboard"]="clipboard-toggle"
    ["wallpaper"]="wallpaper-toggle"
    ["arch-menu"]="PowerMenu-toggle"
    # Network tabs
    ["wifi-toggle"]="wifi-toggle"
    ["bt-toggle"]="bt-toggle"
    ["vpn-toggle"]="vpn-toggle"
    ["hotspot-toggle"]="hotspot-toggle"
    # Tools
    ["focus"]="focus-toggle"
    ["screen-record"]="screenrec-on"
    ["close-all"]="focus-toggle"
)

send_ipc() {
    local cmd="$1"
    if [[ -p "$PIPE" ]]; then
        echo "$cmd" > "$PIPE" &
        return 0
    fi

    local pid
    pid=$(find_brain_shell_pid_cached)
    if [[ -z "$pid" ]]; then
        echo "Error: Brain_Shell is not running"
        return 1
    fi

    # Translate friendly name to original IPC target
    local target="${IPC_MAP[$cmd]:-$cmd}"
    qs ipc --pid "$pid" call "$target" toggle 2>/dev/null || {
        # Fallback: try as brain-shell run (for screenshot/color-picker/etc.)
        qs ipc --pid "$pid" call brain-shell "$cmd" 2>/dev/null || {
            echo "Error: Could not send command '$cmd'"
            return 1
        }
    }
}

# ── Brightness ────────────────────────────────────────────────────────────────
brightness_list_monitors() {
    echo "Monitors:"
    if command -v hyprctl &>/dev/null; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[] | "  \(.name)"' 2>/dev/null || {
            echo "Error: Could not list monitors (jq required)"
            exit 1
        }
    else
        echo "Error: hyprctl not found"
        exit 1
    fi
}

brightness_get_current() {
    local monitor="${1:-}"
    if command -v brightnessctl &>/dev/null; then
        if [[ -z "$monitor" ]]; then
            brightnessctl -m 2>/dev/null | while IFS=, read -r dev _ cur max; do
                dev="${dev// /}"
                local pct=$(( cur * 100 / max ))
                echo "${dev}:${pct}"
            done
        else
            local info
            info=$(brightnessctl -d "$monitor" -m 2>/dev/null) || return 1
            IFS=, read -r _ _ cur max <<< "$info"
            echo $(( cur * 100 / max ))
        fi
    else
        echo "Warning: brightnessctl not found"
        return 1
    fi
}

brightness_save() {
    local monitor="${1:-}"
    if [[ -z "$monitor" ]]; then
        brightness_get_current > "$BRIGHTNESS_SAVE_FILE" 2>/dev/null || {
            echo "Warning: Could not query current brightness"
        }
        if [[ -s "$BRIGHTNESS_SAVE_FILE" ]]; then
            echo "Saved current brightness for all monitors"
        fi
    else
        local cur
        cur=$(brightness_get_current "$monitor" 2>/dev/null) || {
            echo "Error: Monitor $monitor not found"
            exit 1
        }
        if [[ -f "$BRIGHTNESS_SAVE_FILE" ]]; then
            grep -v "^${monitor}:" "$BRIGHTNESS_SAVE_FILE" > "${BRIGHTNESS_SAVE_FILE}.tmp" 2>/dev/null || true
            echo "${monitor}:${cur}" >> "${BRIGHTNESS_SAVE_FILE}.tmp"
            mv "${BRIGHTNESS_SAVE_FILE}.tmp" "$BRIGHTNESS_SAVE_FILE"
        else
            echo "${monitor}:${cur}" > "$BRIGHTNESS_SAVE_FILE"
        fi
        echo "Saved current brightness for $monitor (${cur}%)"
    fi
}

brightness_restore() {
    local monitor="${1:-}"
    if [[ ! -f "$BRIGHTNESS_SAVE_FILE" ]]; then
        echo "Error: No saved brightness found. Use -s to save first."
        exit 1
    fi

    if [[ -z "$monitor" ]]; then
        while IFS=: read -r name value; do
            [[ -n "$name" && -n "$value" ]] || continue
            brightnessctl -d "$name" set "${value}%" 2>/dev/null || echo "Warning: Could not restore brightness for $name"
        done < "$BRIGHTNESS_SAVE_FILE"
        echo "Restored brightness for all monitors"
    else
        local value
        value=$(grep "^${monitor}:" "$BRIGHTNESS_SAVE_FILE" | cut -d: -f2)
        if [[ -z "$value" ]]; then
            echo "Error: No saved brightness for monitor $monitor"
            exit 1
        fi
        brightnessctl -d "$monitor" set "${value}%" 2>/dev/null || {
            echo "Error: Could not restore brightness for $monitor"
            exit 1
        }
        echo "Restored brightness for $monitor to ${value}%"
    fi
}

brightness_set() {
    local value="$1"
    local monitor="${2:-}"
    local save_flag="$3"

    if [[ "$value" -lt 0 ]] || [[ "$value" -gt 100 ]]; then
        echo "Error: Brightness must be between 0 and 100"
        exit 1
    fi

    if [[ "$save_flag" == "true" ]]; then
        brightness_save "$monitor"
    fi

    if [[ -z "$monitor" ]]; then
        brightnessctl set "${value}%" 2>/dev/null || {
            echo "Error: Could not set brightness"
            exit 1
        }
        echo "Set brightness to ${value}% for all monitors"
    else
        brightnessctl -d "$monitor" set "${value}%" 2>/dev/null || {
            echo "Error: Could not set brightness for $monitor"
            exit 1
        }
        echo "Set brightness to ${value}% for $monitor"
    fi
}

brightness_adjust() {
    local delta="$1"
    local monitor="${2:-}"

    if [[ -z "$monitor" ]]; then
        brightnessctl set "${delta}%" 2>/dev/null || {
            echo "Error: Could not adjust brightness"
            exit 1
        }
        echo "Adjusted brightness by ${delta}% for all monitors"
    else
        brightnessctl -d "$monitor" set "${delta}%" 2>/dev/null || {
            echo "Error: Could not adjust brightness for $monitor"
            exit 1
        }
        echo "Adjusted brightness by ${delta}% for $monitor"
    fi
}

# ── Volume ────────────────────────────────────────────────────────────────────
_vol_ctl() {
    if command -v wpctl &>/dev/null; then echo "wpctl"; else echo "pactl"; fi
}

volume_up() {
    case "$(_vol_ctl)" in
        wpctl) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null ;;
        pactl) pactl set-sink-volume @DEFAULT_SINK@ +5% 2>/dev/null ;;
    esac
}
volume_down() {
    case "$(_vol_ctl)" in
        wpctl) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null ;;
        pactl) pactl set-sink-volume @DEFAULT_SINK@ -5% 2>/dev/null ;;
    esac
}
volume_mute() {
    case "$(_vol_ctl)" in
        wpctl) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null ;;
        pactl) pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null ;;
    esac
}
mic_mute() {
    case "$(_vol_ctl)" in
        wpctl) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null ;;
        pactl) pactl set-source-mute @DEFAULT_SOURCE@ toggle 2>/dev/null ;;
    esac
}

caffeine_toggle() {
    if pgrep -f "systemd-inhibit.*BrainShell.*Caffeine" &>/dev/null; then
        pkill -f "systemd-inhibit.*BrainShell.*Caffeine" 2>/dev/null || true
        echo "Caffeine: OFF"
    else
        systemd-inhibit --what=idle:sleep --who="Brain Shell" --why="Caffeine mode" sleep infinity &
        echo "Caffeine: ON"
    fi
}

# ── Hyprland integration ──────────────────────────────────────────────────────
HYPR_DIR="$HOME/.config/hypr"

BRAIN_SHELL_CONF_BLOCK='# Brain_Shell
source = ~/.local/share/Brain_Shell/hyprland.conf

# OVERRIDES
# Add your own Hyprland settings below. They will override Brain_Shell defaults.'

BRAIN_SHELL_LUA_BLOCK='-- Brain_Shell
loadfile(os.getenv("HOME") .. "/.local/share/Brain_Shell/hyprland.lua")()

-- OVERRIDES
-- Add your own Hyprland settings below. They will override Brain_Shell defaults.'

append_hyprland_block() {
    local conf="$1"
    local source="$2"
    local block="$3"

    if [[ -f "$conf" ]] && grep -qF "$source" "$conf" 2>/dev/null; then
        echo "Brain_Shell is already integrated in $conf"
        return 0
    fi

    if [[ -f "$conf" ]] && [[ -s "$conf" ]]; then
        printf "\n%s\n" "$block" >> "$conf"
    else
        printf "%s\n" "$block" > "$conf"
    fi

    echo "Brain_Shell integrated into $conf"
}

remove_hyprland_block() {
    local conf="$1"
    local source="$2"

    if [[ ! -f "$conf" ]]; then
        return 0
    fi

    awk '
        /^# Brain_Shell$/   { skip=1; next }
        /^-- Brain_Shell$/  { skip=1; next }
        /^source =.*Brain_Shell/ { next }
        /^loadfile.*Brain_Shell/ { next }
        /^exec-once = brain-shell/ { next }
        /^# OVERRIDES$/     { if(skip) next }
        /^-- OVERRIDES$/    { if(skip) next }
        /^# Add your own/   { if(skip) { skip=0; next } }
        /^-- Add your own/  { if(skip) { skip=0; next } }
        { if(!skip) print }
    ' "$conf" > "${conf}.tmp" && mv "${conf}.tmp" "$conf"

    echo "Brain_Shell removed from $conf"
}

detect_hyprland_config() {
    if [[ -f "${HYPR_DIR}/hyprland.lua" ]]; then echo "lua"
    elif [[ -f "${HYPR_DIR}/hyprland.conf" ]]; then echo "conf"
    else echo "conf"; fi
}

generate_hyprland_configs() {
    mkdir -p "$DATA_DIR"

    cat > "${DATA_DIR}/hyprland.conf" <<'HYPRCONF'
# Brain_Shell — generated by HyprlandSyncService
# Regenerated on keybind changes. Do not edit manually.

$mainMod = SUPER

exec-once = brain-shell

windowrule = no_blur on, match:class ^(quickshell)$
windowrule = border_size 0, match:class ^(quickshell)$
windowrule = no_anim on, match:class ^(quickshell)$
windowrule = rounding 0, match:class ^(quickshell)$
windowrule = stay_focused on, match:class ^(quickshell)$
windowrule = no_max_size on, match:class ^(quickshell)$

layerrule = blur on, match:namespace ^(quickshell)$
layerrule = ignore_alpha 0, match:namespace ^(quickshell)$
layerrule = no_anim on, match:namespace ^(quickshell)$
HYPRCONF

    cat > "${DATA_DIR}/hyprland.lua" <<'HYPRLUA'
-- Brain_Shell — generated by HyprlandSyncService
-- This file is regenerated automatically when keybinds change.
-- Do not edit manually.

-- ── Autostart ─────────────────────────────────────────────────────────────
hl.on("hyprland.start", function ()
    hl.exec_cmd("brain-shell")
end)

-- ── Window rules (quickshell integration) ────────────────────────────────
hl.window_rule({ match = { class = "^(quickshell)$" }, no_blur = true })
hl.window_rule({ match = { class = "^(quickshell)$" }, border_size = 0 })
hl.window_rule({ match = { class = "^(quickshell)$" }, no_anim = true })
hl.window_rule({ match = { class = "^(quickshell)$" }, rounding = 0 })
hl.window_rule({ match = { class = "^(quickshell)$" }, stay_focused = true })
hl.window_rule({ match = { class = "^(quickshell)$" }, no_max_size = true })

-- ── Layer rules (quickshell integration) ──────────────────────────────────
hl.layer_rule({ match = { namespace = "^(quickshell)$" }, blur = true })
hl.layer_rule({ match = { namespace = "^(quickshell)$" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "^(quickshell)$" }, no_anim = true })

-- ── Submap for keybind interception ────────────────────────────────────────
hl.define_submap("BrainShell_clean", function()
    hl.bind("Escape", hl.dsp.submap("reset"))
end)
HYPRLUA
}

install_hyprland() {
    local mode="${1:-auto}"
    if [[ "$mode" == "auto" ]]; then mode=$(detect_hyprland_config); fi

    mkdir -p "$HYPR_DIR" "$DATA_DIR"
    generate_hyprland_configs

    if [[ "$mode" == "lua" ]]; then
        local lua_source='loadfile(os.getenv("HOME") .. "/.local/share/Brain_Shell/hyprland.lua")()'
        append_hyprland_block "${HYPR_DIR}/hyprland.lua" "$lua_source" "$BRAIN_SHELL_LUA_BLOCK"
        remove_hyprland_block "${HYPR_DIR}/hyprland.conf" "source = ${DATA_DIR}/hyprland.conf" 2>/dev/null || true
    else
        local conf_source="source = ${DATA_DIR}/hyprland.conf"
        append_hyprland_block "${HYPR_DIR}/hyprland.conf" "$conf_source" "$BRAIN_SHELL_CONF_BLOCK"
        remove_hyprland_block "${HYPR_DIR}/hyprland.lua" 'loadfile(os.getenv("HOME") .. "/.local/share/Brain_Shell/hyprland.lua")()' 2>/dev/null || true
    fi

    echo ""
    echo "  Restart Hyprland or run:  brain-shell"
}

remove_hyprland() {
    remove_hyprland_block "${HYPR_DIR}/hyprland.conf" "source = ${DATA_DIR}/hyprland.conf" 2>/dev/null || true
    remove_hyprland_block "${HYPR_DIR}/hyprland.lua" 'loadfile(os.getenv("HOME") .. "/.local/share/Brain_Shell/hyprland.lua")()' 2>/dev/null || true
    rm -f "${DATA_DIR}/hyprland.conf" "${DATA_DIR}/hyprland.lua"
}

# ── Update ────────────────────────────────────────────────────────────────────
update_shell() {
    echo "Updating Brain_Shell..."
    if [[ -d "${SCRIPT_DIR}/.git" ]]; then
        cd "$SCRIPT_DIR"
        git pull --ff-only || { echo "Error: git pull failed."; exit 1; }
        echo "Brain_Shell updated."
    else
        echo "Error: Not a git repository."
        exit 1
    fi

    local pid
    pid=$(find_brain_shell_pid)
    if [[ -n "$pid" ]]; then
        echo "Restarting..."
        restart_shell
    fi
}

# ── Goodbye ───────────────────────────────────────────────────────────────────
goodbye() {
    echo "This will remove Brain_Shell from your system."
    echo "Your configs will be preserved at: $CONFIG_DIR"
    echo ""
    read -rp "Continue? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo "Cancelled."
        exit 0
    fi

    quit_shell 2>/dev/null || true
    remove_hyprland

    if [[ -L /usr/local/bin/brain-shell ]]; then
        sudo rm -f /usr/local/bin/brain-shell 2>/dev/null || echo "  Please remove /usr/local/bin/brain-shell manually"
    fi

    echo ""
    echo "Brain_Shell removed."
    echo "  Configs:  $CONFIG_DIR"
    echo "  Full wipe: rm -rf $CONFIG_DIR ${DATA_DIR} $SCRIPT_DIR"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════════
case "${1:-}" in
    ""|launch) launch_shell ;;
    help|-h|--help) show_help ;;
    version|-v|--version) echo "Brain_Shell v${VERSION}" ;;
    update) update_shell ;;
    reload|restart) restart_shell ;;
    sync) send_ipc "sync-binds" 2>/dev/null || echo "Brain_Shell not running — binds will sync on next start" ;;
    quit|stop|exit) quit_shell ;;
    lock|lockscreen) lock_screen ;;

    screen)
        case "${2:-}" in
            off) hyprctl dispatch dpms off 2>/dev/null || echo "Error: hyprctl not found" ;;
            on)  hyprctl dispatch dpms on 2>/dev/null || echo "Error: hyprctl not found" ;;
            *)   echo "Usage: brain-shell screen [on|off]"; exit 1 ;;
        esac ;;

    suspend)
        if command -v systemctl &>/dev/null; then systemctl suspend
        elif command -v loginctl &>/dev/null; then loginctl suspend
        else dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true
        fi ;;

    brightness)
        ARG2="${2:-}"; ARG3="${3:-}"; ARG4="${4:-}"
        case "$ARG2" in
            -l|--list) brightness_list_monitors ;;
            -r|--restore) brightness_restore "${ARG3:-}" ;;
            -s|--save) brightness_save "${ARG3:-}" ;;
            [+-][0-9]*)
                MONITOR=""
                [[ -n "$ARG3" && "$ARG3" != "-s" && "$ARG3" != "--save" ]] && MONITOR="$ARG3"
                brightness_adjust "$ARG2" "$MONITOR" ;;
            [0-9]*)
                VALUE="$ARG2"; MONITOR=""; SAVE="false"
                [[ "$ARG3" == "-s" || "$ARG3" == "--save" ]] && { SAVE="true"; }
                [[ -n "$ARG3" && "$ARG3" != "-s" && "$ARG3" != "--save" ]] && { MONITOR="$ARG3"; [[ "${ARG4:-}" == "-s" || "${ARG4:-}" == "--save" ]] && SAVE="true"; }
                brightness_set "$VALUE" "$MONITOR" "$SAVE" ;;
            *) echo "Error: Invalid brightness argument '$ARG2'."; echo "Usage: brain-shell brightness <0-100|+/-delta|-s|-r|-l> [monitor]"; exit 1 ;;
        esac ;;

    volume-up) volume_up ;;
    volume-down) volume_down ;;
    volume-mute) volume_mute ;;
    mic-mute) mic_mute ;;
    caffeine) caffeine_toggle ;;
    gamemode) send_ipc "gamemode" 2>/dev/null || echo "Error: Brain_Shell is not running" ;;
    nightlight)
        if command -v hyprsunset &>/dev/null; then
            if pgrep -x hyprsunset &>/dev/null; then
                pkill -x hyprsunset 2>/dev/null && echo "Night light: OFF"
            else
                hyprsunset -t 4000 &>/dev/null &
                echo "Night light: ON (4000K)"
            fi
        else
            echo "Error: hyprsunset not found. Install hyprsunset for night light."
        fi
        ;;

    run)
        CMD="${2:-}"
        if [[ -z "$CMD" ]]; then
            echo "Error: No command specified."
            echo "Run 'brain-shell help' for available commands."
            exit 1
        fi
        send_ipc "$CMD" ;;

    install)
        TARGET="${2:-}"
        if [[ "$TARGET" == "hyprland" ]]; then
            MODE="auto"
            for arg in "${@:3}"; do
                case "$arg" in --lua) MODE="lua" ;; --conf) MODE="conf" ;; esac
            done
            install_hyprland "$MODE"
        else
            echo "Error: Unknown install target '$TARGET'."
            echo "Usage: brain-shell install hyprland [--lua|--conf]"
            exit 1
        fi ;;

    remove)
        TARGET="${2:-}"
        if [[ "$TARGET" == "hyprland" ]]; then remove_hyprland
        else echo "Error: Unknown remove target '$TARGET'."; echo "Usage: brain-shell remove hyprland"; exit 1
        fi ;;

    goodbye) goodbye ;;

    *) echo "Error: Unknown command '$1'."; echo "Run 'brain-shell help' for usage information."; exit 1 ;;
esac
