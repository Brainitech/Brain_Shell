#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — Arch Linux Installer
#  Invoked by install.sh:  $1=HYPRLAND_CONF  $2=BACKUP_DIR  $3=CONFIG_TYPE
# ─────────────────────────────────────────────────────────────────────────────

set -eo pipefail

# ── Arguments (validated up-front) ───────────────────────────────────────────
HYPRLAND_CONF="${1:?Missing arg: HYPRLAND_CONF path}"
BACKUP_DIR="${2:?Missing arg: BACKUP_DIR}"
CONFIG_TYPE="${3:?Missing arg: CONFIG_TYPE (conf|lua)}"
REPO_DIR="$HOME/.local/src/Brain_Shell"

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


# ══════════════════════════════════════════════════════════════════════════════
# PACKAGE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# pacman_install <pkg> [<pkg> ...]
#
# Strategy (three attempts, most to least aggressive):
#
#   1. Bulk install — fastest; skips already-installed packages via --needed.
#
#   2. Per-package retry — if the bulk transaction fails because ONE package
#      has a conflict, the entire batch is rejected. Retrying individually
#      isolates which package is actually broken so the rest can still install.
#
#   3. --overwrite='*' per package — resolves FILE-OWNERSHIP conflicts, where
#      two packages both claim the same path. Safe in practice: the new package
#      just wins the ownership. This does NOT help with hard PKGBUILD conflicts
#      (ConflictsWith). Those need manual resolution (see summary output).
#
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

        if $helper -S --noconfirm "$pkg" &>/dev/null; then
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


# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — AUR Helper
# ══════════════════════════════════════════════════════════════════════════════
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
        log_info "Bootstrapping $name from AUR..."
        sudo pacman -S --needed --noconfirm git base-devel
        local tmp; tmp=$(mktemp -d)
        git clone "https://aur.archlinux.org/${name}.git" "$tmp/$name"
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


# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Pacman Packages
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Pacman Packages"

PACMAN_DEPS=(
    # Qt6 runtime
    qt6-base qt6-declarative qt6-multimedia qt6-5compat qt6ct

    # Audio / PipeWire
    pipewire pipewire-pulse wireplumber

    # Media & player control
    playerctl mpv-mpris mpd-mpris

    # Network / Bluetooth
    networkmanager bluez bluez-utils

    # System services
    brightnessctl upower libnotify polkit
    python wl-clipboard slurp xdg-user-dirs

    # Screen recording
    wf-recorder cava

    # Wallpaper / theming
    imagemagick

    # Input simulation
    wtype

    # Hardware sensors
    lm_sensors rfkill

    # Hyprland ecosystem  (hyprshutdown is AUR-only — kept out of here)
    hyprland hyprsunset hyprlock hyprpolkitagent hypridle
    xdg-desktop-portal-hyprland

    # Fonts
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common
)

log_info "Syncing package database..."
sudo pacman -Syu --noconfirm 2>/dev/null || {
    log_warn "System update failed — continuing with current DB. Some packages may be stale."
}

pacman_install "${PACMAN_DEPS[@]}"


# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — AUR Packages
# ══════════════════════════════════════════════════════════════════════════════
step 3 "AUR Packages"

AUR_DEPS=(
    quickshell       # REQUIRED — the shell runtime
    awww             # animation daemon
    matugen          # Material You color generation
    envycontrol      # GPU switching
    auto-cpufreq     # CPU power management
    nbfc-linux       # fan control
    cliphist         # clipboard history
    hyprshutdown     # power menu backend
    grimblast-git    # screenshot tool
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
if ! "$AUR_HELPER" -Q quickshell &>/dev/null 2>&1; then
    die "quickshell failed to install. Brain Shell cannot run without it."
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Systemd Services
# ══════════════════════════════════════════════════════════════════════════════
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


# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Hyprland Config
# ══════════════════════════════════════════════════════════════════════════════
step 5 "Hyprland Config"

# Marker used to detect whether the block was already appended
_MARKER="quickshell.*Brain_Shell"

_append_conf() {
    cat << 'EOF' >> "$1"

# Brain Shell Autostarts
exec-once = awww-daemon
exec-once = hypridle -c $HOME/.local/src/Brain_Shell/src/config/hypridle.conf
exec-once = quickshell -c $HOME/.local/src/Brain_Shell/.
exec-once = systemctl --user start hyprpolkitagent
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
EOF
}

_append_lua() {
    cat << 'EOF' >> "$1"

-- Brain Shell Autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell/src/config/hypridle.conf")
    hl.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
EOF
}

if grep -q "$_MARKER" "$HYPRLAND_CONF" 2>/dev/null; then
    log_warn "Autostart block already present — skipping."
else
    case "$CONFIG_TYPE" in
        conf)
            _append_conf "$HYPRLAND_CONF"
            log_ok "Autostart block appended to hyprland.conf"
            ;;
        lua)
            # Extra safety backup before touching a Lua config
            cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.pre-brain-shell"
            log_info "Safety backup: ${HYPRLAND_CONF}.pre-brain-shell"
            _append_lua "$HYPRLAND_CONF"
            log_ok "Autostart block appended to hyprland.lua"
            ;;
        *)
            log_warn "Unknown config type '$CONFIG_TYPE' — skipping Hyprland config update."
            ;;
    esac
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — Brain Shell Config & Keybind Check
# ══════════════════════════════════════════════════════════════════════════════
step 6 "Brain Shell Config"

USER_DATA="$HOME/.config/Brain_Shell/src/user_data"

mkdir -p "$USER_DATA" \
         "$HOME/.config/hypr/shaders" \
         "$HOME/.config/matugen/templates"

# Copy hypridle config; -n = do not overwrite if already customised
if cp -n "$REPO_DIR/src/config/hypridle.conf" "$HOME/.config/hypr/" 2>/dev/null; then
    log_ok "hypridle.conf → ~/.config/hypr/"
else
    log_info "hypridle.conf already exists — not overwritten"
fi

printf '{"configProvider": "%s"}\n' "$CONFIG_TYPE" > "$USER_DATA/config_Provider.json"
printf '{}\n'                                       > "$USER_DATA/keybinds.json"

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
import subprocess, json, os, sys

DEFAULTS = {
    "dashboard-home":      {"mods": "SUPER",        "key": "D",      "label": "Dashboard: System"},
    "dashboard-stats":     {"mods": "CTRL + SHIFT", "key": "ESCAPE", "label": "Dashboard: Home"},
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
    sys.exit(0)

conflicts = {}
for action, data in DEFAULTS.items():
    mask = mods_to_mask(data["mods"])
    key  = data["key"].lower()
    for hb in hypr_binds:
        if hb.get("submap", "") or hb.get("mouse"):
            continue
        if hb.get("modmask") == mask and str(hb.get("key", "")).lower() == key:
            desc = hb.get("dispatcher", "")
            arg  = hb.get("arg", "")
            conflicts[action] = {
                "bind":    f"{data['mods']} + {data['key']}",
                "label":   data["label"],
                "used_by": f"{desc} {arg}".strip(),
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
with open(config_path, "w") as f:
    json.dump(unbound, f, indent=2)

print("  \033[1;33m⚠\033[0m  Conflicting binds left unbound in Brain Shell.")
print("       Re-assign them: Dashboard  →  Config  →  Keybinds\n")
PYEOF


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
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

exit 0
