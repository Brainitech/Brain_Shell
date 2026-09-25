#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — Arch Linux Installer
#  Invoked by install.sh:  $1=HYPRLAND_CONF  $2=BACKUP_DIR  $3=CONFIG_TYPE
# ─────────────────────────────────────────────────────────────────────────────


set -eo pipefail

# ── Arguments (validated up-front) ───────────────────────────────────────────
HYPRLAND_CONF="${1:?Missing arg: HYPRLAND_CONF path}"
CONFIG_TYPE="${2:?Missing arg: CONFIG_TYPE (conf|lua)}"
REPO_DIR="${3:-$HOME/.local/src/Brain_Shell}"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m';   GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';  CYAN='\033[0;36m';   BOLD='\033[1m'
DIM='\033[2m';      NC='\033[0m'

# ── Logging ───────────────────────────────────────────────────────────────────
log_info()  { echo -e "  ${BLUE}·${NC} $1"; }
log_ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
log_warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "  ${RED}✗${NC} $1" >&2; }
die()       { echo ""; log_error "$1"; exit 1; }

TOTAL_STEPS=6
step() {
    echo ""
    echo -e "${BOLD}${CYAN}  [$1/$TOTAL_STEPS]  $2${NC}"
    echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
}

# ── Failure Tracking ──────────────────────────────────────────────────────────
# Packages that couldn't be installed are collected here and shown in the
# final summary with manual fix commands instead of aborting the whole install.
declare -a FAILED_PKGS=()


pacman_install() {
    local -a pkgs=("$@")
    local total=${#pkgs[@]}

    log_info "Installing $total packages via pacman..."

    # Attempt 1 — bulk
    if sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        log_ok "All $total packages installed."
        return 0
    fi

    # Bulk failed — at least one conflict. Fall back to one-by-one.
    echo ""
    log_warn "Bulk install hit a conflict. Retrying individually..."
    echo ""

    local installed=0 already=0
    local -a failed=()

    for pkg in "${pkgs[@]}"; do
        # Skip silently if already present
        if pacman -Qi "$pkg" &>/dev/null; then
            already=$(( already + 1 ))
            continue
        fi

        printf "    ${DIM}%-32s${NC} " "$pkg"

        # Attempt 2 — standard per-package
        if sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            installed=$(( installed + 1 ))
            continue
        fi

        # Attempt 3 — overwrite (file-ownership conflicts)
        if sudo pacman -S --needed --noconfirm --overwrite='*' "$pkg" &>/dev/null; then
            echo -e "${YELLOW}✓ overwrite${NC}"
            installed=$(( installed + 1 ))
            continue
        fi

        # Hard conflict — needs manual resolution
        echo -e "${RED}✗ conflict${NC}"
        failed+=("$pkg")
    done

    echo ""
    log_ok "$installed installed,  $already already present"

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "${#failed[@]} package(s) failed (hard conflict — see summary):"
        for pkg in "${failed[@]}"; do
            log_warn "    $pkg"
            FAILED_PKGS+=("pacman:$pkg")
        done
    fi
}

# aur_install <helper> <pkg> [<pkg> ...]
#
# Installs packages individually via yay/paru. AUR helpers build from source,
# so they don't support the same --overwrite shortcut. Failures are tracked but
# non-fatal; quickshell is checked explicitly afterwards.
#
aur_install() {
    local helper="$1"; shift
    local -a pkgs=("$@")
    local -a failed=()

    echo ""
    for pkg in "${pkgs[@]}"; do
        printf "    ${DIM}%-32s${NC} " "$pkg"

        if $helper -Q "$pkg" &>/dev/null; then
            echo -e "${GREEN}✓ already installed${NC}"
            continue
        fi

        if $helper -S --needed --noconfirm "$pkg" &>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            failed+=("$pkg")
        fi
    done

    echo ""

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "${#failed[@]} AUR package(s) failed (see summary):"
        for pkg in "${failed[@]}"; do
            log_warn "    $pkg"
            FAILED_PKGS+=("aur:$pkg")
        done
    else
        log_ok "All AUR packages installed."
    fi
}



step 1 "AUR Helper"

AUR_HELPER=""

if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    log_ok "yay detected"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    log_ok "paru detected"
else
    log_warn "No AUR helper found (yay / paru)."
    echo ""
    echo -e "  ${BOLD}Select one to install:${NC}"
    echo "    1) yay   — more interactive, widely used"
    echo "    2) paru  — faster builds, more features"
    echo "    3) Skip  — pacman-only (quickshell will be missing)"
    echo ""
    read -rp "  Choice [1/2/3]: " _aur_choice < /dev/tty

    _bootstrap_aur_helper() {
        local name="$1"
        local bin_pkg="${name}-bin"
        log_info "Bootstrapping $name from AUR..."
        sudo pacman -S --needed --noconfirm git base-devel
        local tmp; tmp=$(mktemp -d)
        # Prefer precompiled -bin to prevent compiler OOM kills (Rust/Go) on VMs
        if git clone --depth=1 "https://aur.archlinux.org/${bin_pkg}.git" "$tmp/$bin_pkg" 2>/dev/null; then
            if ( cd "$tmp/$bin_pkg" && makepkg -si --noconfirm ); then
                rm -rf "$tmp"
                log_ok "$name installed."
                return 0
            fi
        fi
        # Fallback to source build
        git clone --depth=1 "https://aur.archlinux.org/${name}.git" "$tmp/$name"
        ( cd "$tmp/$name" && makepkg -si --noconfirm )
        rm -rf "$tmp"
        log_ok "$name installed."
    }

    case "$_aur_choice" in
        1) _bootstrap_aur_helper yay;  AUR_HELPER="yay"  ;;
        2) _bootstrap_aur_helper paru; AUR_HELPER="paru" ;;
        3)
            log_warn "Skipping AUR helper."
            log_warn "quickshell is required — install yay or paru later and re-run."
            AUR_HELPER="none"
            ;;
        *) die "Invalid choice." ;;
    esac
fi



step 2 "Pacman Packages"

PACMAN_DEPS=(
    # Qt6 runtime
    qt6-base qt6-declarative qt6-wayland qt6-multimedia qt6-5compat qt6ct

    # Audio / PipeWire
    pipewire pipewire-pulse wireplumber

    # Media & player control
    playerctl mpv-mpris mpd-mpris

    # Network / Bluetooth
    networkmanager bluez bluez-utils

    # System services
    brightnessctl upower libnotify polkit kitty
    python wl-clipboard slurp xdg-user-dirs

    # Screen recording
    wf-recorder cava

    # Wallpaper / theming
    imagemagick awww matugen

    # Input simulation
    wtype

    # Hardware sensors
    lm_sensors rfkill

    # Hyprland ecosystem
    hyprland hyprsunset hyprlock hyprpolkitagent hypridle
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

    # Fonts
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common

    cliphist
)

log_info "Synchronizing package database..."
if ! sudo pacman -Sy --noconfirm &>/dev/null; then
    log_warn "Database sync failed — continuing with current DB. Some packages may be stale."
fi

pacman_install "${PACMAN_DEPS[@]}"



step 3 "AUR Packages"

_use_variant() {
    local stable="$1" git_variant="${1}-git"
    if pacman -Qi "$stable" &>/dev/null; then
        echo "$stable"
    else
        echo "$git_variant"
    fi
}

_has_nvidia() {
    { command -v lspci &>/dev/null && lspci | grep -iq nvidia; } || grep -iq nvidia /proc/modules 2>/dev/null
}

_is_laptop() {
    if command -v systemd-detect-virt &>/dev/null && systemd-detect-virt -q; then
        return 1
    fi
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
        case "$(< /sys/class/dmi/id/chassis_type)" in
            8|9|10|11|14|30|31|32) return 0 ;;
        esac
    fi
    compgen -G "/sys/class/power_supply/BAT*" >/dev/null && return 0
    return 1
}

AUR_DEPS=(
    "$(_use_variant quickshell)"
)

# Optional hardware tools — detected dynamically
if _has_nvidia; then
    log_info "NVIDIA GPU detected — adding envycontrol for GPU switching"
    AUR_DEPS+=(envycontrol)
else
    log_info "No NVIDIA GPU detected — skipping envycontrol"
fi

if _is_laptop; then
    log_info "Laptop detected — adding nbfc-linux for fan control"
    AUR_DEPS+=(nbfc-linux)
else
    log_info "Desktop or virtual machine detected — skipping nbfc-linux"
fi

AUR_DEPS+=(
    auto-cpufreq
    grimblast-git
)

if [[ "$AUR_HELPER" == "none" ]]; then
    log_warn "No AUR helper — skipping all AUR packages."
    for pkg in "${AUR_DEPS[@]}"; do
        FAILED_PKGS+=("aur:$pkg (no helper)")
    done
else
    log_info "Using: $AUR_HELPER"
    aur_install "$AUR_HELPER" "${AUR_DEPS[@]}"
fi

# quickshell is non-negotiable
if ! pacman -Q quickshell &>/dev/null && ! pacman -Q quickshell-git &>/dev/null; then
    die "quickshell failed to install. Brain Shell cannot run without it."
fi



step 4 "Systemd Services"

_svc_system() {
    sudo systemctl enable --now "$1" 2>/dev/null \
        && log_ok   "system: $1" \
        || log_warn "system: $1  (failed to enable — may not apply to your setup)"
}
_svc_user() {
    systemctl --user enable --now "$1" 2>/dev/null \
        && log_ok   "user:   $1" \
        || log_warn "user:   $1  (failed to enable)"
}

_svc_system NetworkManager
_svc_system bluetooth
_svc_system upower
_svc_user   pipewire
_svc_user   pipewire-pulse
_svc_user   wireplumber

# Optional hardware services
if command -v auto-cpufreq &>/dev/null || pacman -Q auto-cpufreq &>/dev/null; then
    _svc_system auto-cpufreq
fi
if command -v nbfc &>/dev/null || pacman -Q nbfc-linux &>/dev/null; then
    _svc_system nbfc_service
fi


step 5 "Hyprland Config"

# ── Pre-generate fallback keybinds for first-boot ─────────────────────────────
_KB_DIR="$HOME/.config/Brain_Shell"
mkdir -p "$_KB_DIR"
if [[ ! -f "$_KB_DIR/Brain_ShellKeybinds.lua" ]]; then
    cat << EOF > "$_KB_DIR/Brain_ShellKeybinds.lua"
local shell = "$REPO_DIR"
hl.define_submap("BrainShell_clean", function()
    hl.bind("CTRL + ESCAPE", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { description = "Emergency return to global submap" })
end)
hl.bind("SUPER + D", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-home toggle"), { description = "Brain Shell: Dashboard" })
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-stats toggle"), { description = "Brain Shell: Task Manager" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-kanban toggle"), { description = "Brain Shell: Kanban Board" })
hl.bind("SUPER + Q", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-launcher toggle"), { description = "Brain Shell: App Launcher" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-config toggle"), { description = "Brain Shell: Shell Config" })
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call PowerMenu-toggle toggle"), { description = "Brain Shell: Power Menu" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call notification-toggle toggle"), { description = "Brain Shell: Notifications" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call wallpaper-toggle toggle"), { description = "Brain Shell: Wallpaper" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call clipboard-toggle toggle"), { description = "Brain Shell: Clipboard" })
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call wifi-toggle toggle"), { description = "Brain Shell: Network Wi-Fi" })
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call bluetooth-toggle toggle"), { description = "Brain Shell: Network Bluetooth" })
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call vpn-toggle toggle"), { description = "Brain Shell: Network VPN" })
hl.bind("SUPER + ALT + H", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call hotspot-toggle toggle"), { description = "Brain Shell: Network Hotspot" })
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call audioOut-toggle toggle"), { description = "Brain Shell: Audio Output" })
hl.bind("SUPER + ALT + I", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call audioIn-toggle toggle"), { description = "Brain Shell: Audio Input" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call audioMix-toggle toggle"), { description = "Brain Shell: Audio Mixer" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call focus-toggle toggle"), { description = "Brain Shell: Focus Mode" })
hl.bind("SUPER + X", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call lock-session toggle"), { description = "Brain Shell: Lock Screen" })
hl.bind("PRINT", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call screenshot-toggle toggle"), { description = "Brain Shell: Screenshot" })
hl.bind("ALT + F9", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call screenrec-on toggle"), { description = "Brain Shell: Screen Record" })
EOF
fi

if [[ ! -f "$_KB_DIR/Brain_ShellKeybinds.conf" ]]; then
    cat << EOF > "$_KB_DIR/Brain_ShellKeybinds.conf"
submap = BrainShell_clean
bind = CTRL, ESCAPE, exec, notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'
bind = CTRL, ESCAPE, submap, reset
submap = reset
bind = SUPER, D, exec, qs ipc -c $REPO_DIR call dashboard-home toggle
bind = CTRL SHIFT, ESCAPE, exec, qs ipc -c $REPO_DIR call dashboard-stats toggle
bind = SUPER, Z, exec, qs ipc -c $REPO_DIR call dashboard-kanban toggle
bind = SUPER, Q, exec, qs ipc -c $REPO_DIR call dashboard-launcher toggle
bind = SUPER, C, exec, qs ipc -c $REPO_DIR call dashboard-config toggle
bind = SUPER, ESCAPE, exec, qs ipc -c $REPO_DIR call PowerMenu-toggle toggle
bind = SUPER, N, exec, qs ipc -c $REPO_DIR call notification-toggle toggle
bind = SUPER, W, exec, qs ipc -c $REPO_DIR call wallpaper-toggle toggle
bind = SUPER, V, exec, qs ipc -c $REPO_DIR call clipboard-toggle toggle
bind = SUPER ALT, W, exec, qs ipc -c $REPO_DIR call wifi-toggle toggle
bind = SUPER ALT, B, exec, qs ipc -c $REPO_DIR call bluetooth-toggle toggle
bind = SUPER ALT, G, exec, qs ipc -c $REPO_DIR call vpn-toggle toggle
bind = SUPER ALT, H, exec, qs ipc -c $REPO_DIR call hotspot-toggle toggle
bind = SUPER, A, exec, qs ipc -c $REPO_DIR call audioOut-toggle toggle
bind = SUPER ALT, I, exec, qs ipc -c $REPO_DIR call audioIn-toggle toggle
bind = SUPER, M, exec, qs ipc -c $REPO_DIR call audioMix-toggle toggle
bind = SUPER, B, exec, qs ipc -c $REPO_DIR call focus-toggle toggle
bind = SUPER, X, exec, qs ipc -c $REPO_DIR call lock-session toggle
bind = , PRINT, exec, qs ipc -c $REPO_DIR call screenshot-toggle toggle
bind = ALT, F9, exec, qs ipc -c $REPO_DIR call screenrec-on toggle
EOF
fi

if [[ "${FRESH_INSTALL:-}" == "true" ]]; then
    log_info "Detecting keyboard layout for base config..."
    detect_keyboard_layout() {
        local layout="" variant=""
        if command -v localectl &>/dev/null; then
            local status; status="$(localectl status 2>/dev/null)"
            layout="$(awk -F': ' '/X11 Layout/{print $2; exit}'  <<< "$status" | tr -d '[:space:]')"
            variant="$(awk -F': ' '/X11 Variant/{print $2; exit}' <<< "$status" | tr -d '[:space:]')"
        fi
        layout="${layout%%,*}"
        [[ -z "$layout" ]] && layout="us"
        printf '%s\t%s\n' "$layout" "$variant"
    }
    KB_LAYOUT=""; KB_VARIANT=""
    IFS=$'\t' read -r KB_LAYOUT KB_VARIANT <<< "$(detect_keyboard_layout)"
    KB_LAYOUT="${KB_LAYOUT//[[:space:]]/}"
    KB_VARIANT="${KB_VARIANT//[[:space:]]/}"
    [[ -z "$KB_LAYOUT" || "$KB_LAYOUT" == "(unset)" || "$KB_LAYOUT" == "n/a" ]] && KB_LAYOUT="us"
    [[ "$KB_VARIANT" == "(unset)" || "$KB_VARIANT" == "n/a" ]] && KB_VARIANT=""
    log_ok "Keyboard layout detected: ${KB_LAYOUT}${KB_VARIANT:+ (${KB_VARIANT})}"

    HYPR_DIR="$(dirname "$HYPRLAND_CONF")"
    mkdir -p "$HYPR_DIR"
    
    _TMP_HYPR=$(mktemp -d)
    cp -r "$REPO_DIR/src/config/hypr_template/"* "$_TMP_HYPR/"
    sed -i -e "s|kb_layout[[:space:]]*=.*|kb_layout          = \"${KB_LAYOUT}\",|g" \
           -e "s|kb_variant[[:space:]]*=.*|kb_variant         = \"${KB_VARIANT}\",|g" \
           "$_TMP_HYPR/config/input.lua"
    cp -r "$_TMP_HYPR/"* "$HYPR_DIR/"
    rm -rf "$_TMP_HYPR"
    log_ok "Generated base hyprland config with keyboard layout"
fi

STARTUP_CONF="$HOME/.config/Brain_Shell/hypr/brain-shell.conf"
STARTUP_LUA="$HOME/.config/Brain_Shell/hypr/brain-shell.lua"
mkdir -p "$HOME/.config/Brain_Shell/hypr"

cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.conf" "$STARTUP_CONF"
cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.lua"  "$STARTUP_LUA"
sed -i "s|\$HOME/.local/src/Brain_Shell|$REPO_DIR|g" "$STARTUP_CONF" "$STARTUP_LUA"
log_ok "Generated isolated startup configs"

_BEGIN_MARK_CONF="# >>> Brain Shell Startup >>>"
_END_MARK_CONF="# <<< Brain Shell Startup <<<"
_BEGIN_MARK_LUA="-- >>> Brain Shell Startup >>>"
_END_MARK_LUA="-- <<< Brain Shell Startup <<<"


if [[ -f "$HYPRLAND_CONF" ]]; then
    TS=$(date +%Y%m%d_%H%M%S)
    cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.mod-backup-${TS}"
    log_info "Backup created: ${HYPRLAND_CONF}.mod-backup-${TS}"
fi

log_info "Migrating active configuration..."
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
' "$HYPRLAND_CONF"

if grep -q "brain-shell" "$HYPRLAND_CONF"; then
    log_ok "Brain Shell startup already sourced in $HYPRLAND_CONF"
else
    case "$CONFIG_TYPE" in
        conf)
            {
                echo ""
                echo "$_BEGIN_MARK_CONF"
                echo "source = $HOME/.config/Brain_Shell/hypr/brain-shell.conf"
                echo "$_END_MARK_CONF"
            } >> "$HYPRLAND_CONF"
            log_ok "Brain Shell startup sourced from hyprland.conf (1 line)"
            ;;
        lua)
            {
                echo ""
                echo "$_BEGIN_MARK_LUA"
                echo 'dofile(os.getenv("HOME") .. "/.config/Brain_Shell/hypr/brain-shell.lua")'
                echo "$_END_MARK_LUA"
            } >> "$HYPRLAND_CONF"
            log_ok "Brain Shell startup loaded from hyprland.lua (1 line)"
            ;;
        *)
            log_warn "Unknown config type '$CONFIG_TYPE' — skipping Hyprland config update."
            ;;
    esac
fi

step 6 "Brain Shell Config"

USER_DATA="$HOME/.config/Brain_Shell/src/user_data"

mkdir -p "$USER_DATA" \
         "$HOME/.config/hypr/shaders" \
         "$HOME/.config/matugen/templates"

# Copy hypridle and hyprlock configs; -n = do not overwrite if already customised
if cp -n "$REPO_DIR/src/config/hypridle.conf" "$HOME/.config/hypr/" 2>/dev/null; then
    log_ok "hypridle.conf → $HOME/.config/hypr/"
else
    log_info "hypridle.conf already exists — not overwritten"
fi

if cp -n "$REPO_DIR/src/config/hyprlock.conf" "$HOME/.config/hypr/" 2>/dev/null; then
    log_ok "hyprlock.conf → $HOME/.config/hypr/"
else
    log_info "hyprlock.conf already exists — not overwritten"
fi

printf '{"configProvider": "%s"}\n' "$CONFIG_TYPE" > "$USER_DATA/config_Provider.json"
if [[ ! -f "$USER_DATA/keybinds.json" ]]; then
    printf '{}\n' > "$USER_DATA/keybinds.json"
fi

log_ok "Config dirs created"
log_ok "config_Provider.json  →  $CONFIG_TYPE"

log_info "Initializing cache directories..."
mkdir -p "$HOME/.cache/brain-shell"
touch "$HOME/.cache/brain-shell/colors.json"
mkdir -p "$HOME/Pictures/Wallpapers"
cp -n -r "$REPO_DIR/src/assets/wallpapers"/* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true

log_ok "Cache directories initialized"

# ── Keybind Conflict Detection ────────────────────────────────────────────────
echo ""
log_info "Checking keybind conflicts against active Hyprland session..."

python3 << 'PYEOF' || log_warn "Keybind check skipped (Python error or no Hyprland session)."
import subprocess, json, os, sys, re

DEFAULTS = {
    "dashboard-home":      {"mods": "SUPER",        "key": "D",      "label": "Dashboard: Home"},
    "dashboard-stats":     {"mods": "CTRL + SHIFT", "key": "ESCAPE", "label": "Dashboard: System"},
    "dashboard-kanban":    {"mods": "SUPER",        "key": "Z",      "label": "Dashboard: Tasks"},
    "dashboard-launcher":  {"mods": "SUPER",        "key": "Q",      "label": "Dashboard: Apps"},
    "dashboard-config":    {"mods": "SUPER",        "key": "C",      "label": "Dashboard: Config"},
    "PowerMenu-toggle":    {"mods": "SUPER",        "key": "ESCAPE", "label": "Power Menu"},
    "notification-toggle": {"mods": "SUPER",        "key": "N",      "label": "Notifications"},
    "wallpaper-toggle":    {"mods": "SUPER",        "key": "W",      "label": "Wallpaper"},
    "clipboard-toggle":    {"mods": "SUPER",        "key": "V",      "label": "Clipboard"},
    "wifi-toggle":         {"mods": "SUPER + ALT",  "key": "W",      "label": "Network: Wi-Fi"},
    "bluetooth-toggle":    {"mods": "SUPER + ALT",  "key": "B",      "label": "Network: Bluetooth"},
    "vpn-toggle":          {"mods": "SUPER + ALT",  "key": "G",      "label": "Network: VPN"},
    "hotspot-toggle":      {"mods": "SUPER + ALT",  "key": "H",      "label": "Network: Hotspot"},
    "audioOut-toggle":     {"mods": "SUPER",        "key": "A",      "label": "Audio: Output"},
    "audioIn-toggle":      {"mods": "SUPER + ALT",  "key": "I",      "label": "Audio: Input"},
    "audioMix-toggle":     {"mods": "SUPER",        "key": "M",      "label": "Audio: Mixer"},
    "focus-toggle":        {"mods": "SUPER",        "key": "B",      "label": "Focus Mode"},
    "lock-session":        {"mods": "SUPER",        "key": "X",      "label": "Lock Screen"},
    "screenshot-toggle":   {"mods": "",             "key": "PRINT",  "label": "Screenshot"},
    "screenrec-on":        {"mods": "ALT",          "key": "F9",     "label": "Screen Record"},
}

MOD_BITS = {"SHIFT": 1, "CTRL": 4, "ALT": 8, "SUPER": 64}

def mods_to_mask(mods_str):
    mask = 0
    for part in mods_str.upper().split("+"):
        mask |= MOD_BITS.get(part.strip(), 0)
    return mask

try:
    raw = subprocess.check_output(["hyprctl", "binds", "-j"], stderr=subprocess.DEVNULL).decode()
    hypr_binds = json.loads(raw)
except Exception:
    print("  \033[2m(not inside Hyprland — skipping live conflict check)\033[0m")
    with open("/tmp/bs_keybind_skipped", "w") as f: f.write("1")
    sys.exit(0)

bs_lua_binds = []
kb_lua = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.lua")
if os.path.isfile(kb_lua):
    try:
        with open(kb_lua) as f:
            content = f.read()
        for m in re.finditer(r'hl\.bind\s*\(\s*["\']([^"\']+)["\']\s*,\s*hl\.dsp\.exec_cmd\([^)]*qs ipc', content):
            combo = m.group(1).strip()
            parts = [p.strip() for p in combo.split("+")]
            key = parts[-1].lower()
            mods = "+".join(parts[:-1]) if len(parts) > 1 else ""
            bs_lua_binds.append((mods_to_mask(mods), key))
    except Exception:
        pass

consumed_bind_indices = set()
for i, hb in enumerate(hypr_binds):
    if hb.get("submap", "") or hb.get("mouse"):
        continue
    desc = hb.get("dispatcher", "")
    arg = hb.get("arg", "")
    hb_desc = hb.get("description", "")

    if "qs ipc" in arg or "brain_shell" in arg.lower() or "brain-shell" in arg.lower():
        consumed_bind_indices.add(i)
        continue
    if "brain shell" in hb_desc.lower() or "brain_shell" in hb_desc.lower() or "brain-shell" in hb_desc.lower():
        consumed_bind_indices.add(i)
        continue

    if desc == "__lua":
        b_mask = hb.get("modmask")
        b_key = str(hb.get("key", "")).lower()
        for idx, (l_mask, l_key) in enumerate(bs_lua_binds):
            if l_mask == b_mask and l_key == b_key:
                consumed_bind_indices.add(i)
                bs_lua_binds.pop(idx)
                break

conflicts = {}
for action, data in DEFAULTS.items():
    mask = mods_to_mask(data["mods"])
    key  = data["key"].lower()
    for i, hb in enumerate(hypr_binds):
        if i in consumed_bind_indices:
            continue
        if hb.get("submap", "") or hb.get("mouse"):
            continue
        if hb.get("modmask") == mask and str(hb.get("key", "")).lower() == key:
            desc = hb.get("dispatcher", "")
            arg  = hb.get("arg", "")
            hb_desc = hb.get("description", "")
            used_by = f"{desc} {arg}".strip()
            if hb_desc:
                used_by += f" ({hb_desc})"
            conflicts[action] = {
                "bind":    f"{data['mods']} + {data['key']}" if data['mods'] else data['key'],
                "label":   data["label"],
                "used_by": used_by,
            }
            break

if not conflicts:
    print("  \033[0;32m✓\033[0m  No keybind conflicts detected.")
    sys.exit(0)

print(f"\n  \033[0;31m✗\033[0m  {len(conflicts)} conflict(s) found:\n")
unbound = {}
for action, info in conflicts.items():
    print(f"    \033[1m{info['bind']:<24}\033[0m  {info['label']}")
    print(f"    {'':24}  already used by: {info['used_by']}\n")
    unbound[action] = {"mods": "", "key": ""}

config_path = os.path.expanduser("~/.config/Brain_Shell/src/user_data/keybinds.json")
existing = {}
if os.path.isfile(config_path):
    try:
        with open(config_path) as f:
            existing = json.load(f)
    except Exception:
        existing = {}
existing.update(unbound)
os.makedirs(os.path.dirname(config_path), exist_ok=True)
with open(config_path, "w") as f:
    json.dump(existing, f, indent=2)

lua_path = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.lua")
conf_path = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.conf")
for p in [lua_path, conf_path]:
    if os.path.isfile(p):
        with open(p) as f: lines = f.readlines()
        with open(p, "w") as f:
            for line in lines:
                if not any(f"call {a} toggle" in line for a in conflicts):
                    f.write(line)

print("  \033[1;33m⚠\033[0m  Conflicting binds left unbound in Brain Shell.")
print("       Re-assign them: Dashboard  →  Config  →  Keybinds\n")
PYEOF



echo ""
echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"

if [[ ${#FAILED_PKGS[@]} -eq 0 ]]; then
    log_ok "Arch installation complete — no failures."
    echo ""
else
    log_warn "Installation finished with ${#FAILED_PKGS[@]} unresolved package(s)."
    echo ""
    echo -e "  ${BOLD}Retry commands:${NC}"

    for entry in "${FAILED_PKGS[@]}"; do
        _src="${entry%%:*}"
        _pkg="${entry#*:}"
        # Strip any parenthetical note before displaying the install command
        _pkg_name="${_pkg%% (*}"
        if [[ "$_src" == "pacman" ]]; then
            log_info "sudo pacman -S $_pkg_name"
        else
            log_info "$AUR_HELPER -S $_pkg_name"
        fi
    done

    echo ""
    echo -e "  ${BOLD}Resolving hard package conflicts (ConflictsWith):${NC}"
    log_info "Find what conflicts:  pacman -Si <pkg> | grep Conflicts"
    log_info "Remove the old one:   sudo pacman -Rdd <conflicting-pkg>"
    log_info "Then retry:           sudo pacman -S <pkg>"
    echo ""
fi

echo -e "  ${BOLD}Hardware Features Status:${NC}"
if command -v envycontrol &>/dev/null; then
    log_ok "GPU Switching:      envycontrol active"
else
    log_info "GPU Switching:      disabled (non-NVIDIA or envycontrol omitted)"
fi
if command -v nbfc &>/dev/null; then
    log_ok "Fan Control:        nbfc-linux active"
else
    log_info "Fan Control:        disabled (desktop / VM or nbfc-linux omitted)"
fi
if command -v auto-cpufreq &>/dev/null; then
    log_ok "Power Profile:      auto-cpufreq active"
else
    log_info "Power Profile:      disabled"
fi
echo ""

if [[ -f "/tmp/bs_keybind_skipped" ]]; then
    log_warn "Keybind conflict check skipped (Hyprland not running)."
    log_info "Please run 'qs ipc call dashboard-config' after booting to resolve overlaps."
    rm -f "/tmp/bs_keybind_skipped"
    echo ""
fi

exit 0
