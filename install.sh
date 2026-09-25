#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — main Installer
#  github.com/Brainitech/Brain_Shell  v0.2.0
# ─────────────────────────────────────────────────────────────────────────────
# Hesitation is Defeat — Isshin Ashina
set -eo pipefail

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

TOTAL_STEPS=5
step() {
    echo ""
    echo -e "${BOLD}${CYAN}  [$1/$TOTAL_STEPS]  $2${NC}"
    echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
}

# ── Trap ──────────────────────────────────────────────────────────────────────
trap 'echo ""; log_error "Installation aborted unexpectedly (line $LINENO)."; exit 1' ERR

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo " ███████████  ███████████     █████████   █████ ██████   █████     █████████  █████   █████ ██████████ █████       █████      "
echo "▒▒███▒▒▒▒▒███▒▒███▒▒▒▒▒███   ███▒▒▒▒▒███ ▒▒███ ▒▒██████ ▒▒███     ███▒▒▒▒▒███▒▒███   ▒▒███ ▒▒███▒▒▒▒▒█▒▒███       ▒▒███      "
echo " ▒███    ▒███ ▒███    ▒███  ▒███    ▒███  ▒███  ▒███▒███ ▒███    ▒███    ▒▒▒  ▒███    ▒███  ▒███  █ ▒  ▒███        ▒███      "
echo " ▒██████████  ▒██████████   ▒███████████  ▒███  ▒███▒▒███▒███    ▒▒█████████  ▒███████████  ▒██████    ▒███        ▒███      "
echo " ▒███▒▒▒▒▒███ ▒███▒▒▒▒▒███  ▒███▒▒▒▒▒███  ▒███  ▒███ ▒▒██████     ▒▒▒▒▒▒▒▒███ ▒███▒▒▒▒▒███  ▒███▒▒█    ▒███        ▒███      "
echo " ▒███    ▒███ ▒███    ▒███  ▒███    ▒███  ▒███  ▒███  ▒▒█████     ███    ▒███ ▒███    ▒███  ▒███ ▒   █ ▒███      █ ▒███      █"
echo " ███████████  █████   █████ █████   █████ █████ █████  ▒▒█████   ▒▒█████████  █████   █████ ██████████ ███████████ ███████████"
echo -e "${NC}"
echo -e "  ${DIM}v0.2.0  ·  github.com/Brainitech/Brain_Shell${NC}" # Update is finally seeing it's light after getting the TeamCherry Treatment
echo ""


# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Pre-Flight Checks
# ══════════════════════════════════════════════════════════════════════════════
step 1 "Pre-Flight Checks"

# OS
[[ "$OSTYPE" =~ ^linux ]] || die "This installer only supports Linux."
log_ok "Linux confirmed"

# Deps
command -v git &>/dev/null || die "git is not installed. Please install git first."
command -v curl &>/dev/null || die "curl is not installed. Please install curl first."
log_ok "Git & Curl detected"

# Distro
DISTRO_TYPE=""
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
        arch|manjaro|garuda|cachyos|endeavouros)
            log_ok "Distro: ${ID} (Arch-based)"
            DISTRO_TYPE="arch"
            ;;
        nixos)
            log_ok "Distro: NixOS"
            DISTRO_TYPE="nix"
            ;;
        *)
            die "Unsupported distro: ${ID:-unknown}. Supported: Arch-based, NixOS."
            ;;
    esac
else
    die "Cannot detect distro — /etc/os-release not found."
fi

# Check if Hyprland is installed (allows installation from TTY)
if command -v hyprland &>/dev/null; then
    log_ok "Hyprland installation detected"
else
    log_warn "Hyprland binary not found in PATH."
    log_info "Make sure Hyprland is installed before launching it." #Future work: Prompt user for Hyprland installation, waititng for config files so
                                                                    #default files are not picked up
fi

# Hyprland config
HYPR_DIR="$HOME/.config/hypr"
HYPRLAND_CONF=""
CONFIG_TYPE=""

# Hyprland loads .lua first when both exist; mirror that priority here so
# the installer always targets the file Hyprland is actually reading.
if [[ -f "$HYPR_DIR/hyprland.lua" ]]; then
    HYPRLAND_CONF="$HYPR_DIR/hyprland.lua"
    CONFIG_TYPE="lua"
    if [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
        log_ok "Hyprland config: hyprland.lua  ${DIM}(hyprland.conf also present but ignored by Hyprland)${NC}"
    else
        log_ok "Hyprland config: hyprland.lua"
    fi
elif [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
    HYPRLAND_CONF="$HYPR_DIR/hyprland.conf"
    CONFIG_TYPE="conf"
    log_ok "Hyprland config: hyprland.conf"
    log_warn "hyprland.conf support is deprecated as of 0.55 and will be removed in a future release."
    log_info "Consider migrating to hyprland.lua — see https://wiki.hypr.land/Configuring/Start/"
else
    log_warn "No Hyprland config found in $HYPR_DIR."
    log_info "A curated base config will be generated."
    mkdir -p "$HYPR_DIR"
    HYPRLAND_CONF="$HYPR_DIR/hyprland.lua"
    CONFIG_TYPE="lua"
    export FRESH_INSTALL="true"
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Backup
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Backup"

BACKUP_TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config.backup-${BACKUP_TS}-Brain_Shell"
mkdir -p "$BACKUP_DIR"

if [[ "${FRESH_INSTALL:-}" != "true" && -f "$HYPRLAND_CONF" ]]; then
    cp "$HYPRLAND_CONF" "$BACKUP_DIR/"
    log_ok "Backed up: $HYPRLAND_CONF → $BACKUP_DIR"
else
    log_warn "Hyprland config not found or newly created — skipped backup."
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Repository
# ══════════════════════════════════════════════════════════════════════════════
step 3 "Repository"

# Check if we are already running from a clone
if [[ -d "$PWD/.git" ]] && grep -q "Brain_Shell" "$PWD/.git/config" 2>/dev/null; then
    REPO_DIR="$PWD"
    log_info "Running from local clone: $REPO_DIR"
else
    REPO_PARENT="$HOME/.local/src"
    REPO_DIR="$REPO_PARENT/Brain_Shell"
    mkdir -p "$REPO_PARENT"
fi

if [[ -d "$REPO_DIR/.git" ]]; then
    if [[ "$REPO_DIR" == "$PWD" ]]; then
        log_info "Running from local dev clone — skipping destructive git reset."
    else
        log_info "Existing clone found — updating..."
        git -C "$REPO_DIR" fetch origin feat/v0.2.0-installer &>/dev/null || true
        git -C "$REPO_DIR" reset --hard origin/feat/v0.2.0-installer &>/dev/null || true
        git -C "$REPO_DIR" clean -fd &>/dev/null || true
        log_ok "Repository updated: $REPO_DIR"
    fi
else
    log_info "Cloning from GitHub..."
    git clone -q -b feat/v0.2.0-installer https://github.com/Brainitech/Brain_Shell.git "$REPO_DIR" &>/dev/null
    log_ok "Repository cloned: $REPO_DIR"
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Distro-Specific Install
# ══════════════════════════════════════════════════════════════════════════════
step 4 "Distro-Specific Installation"
echo ""

DISTRO_INSTALLER="$REPO_DIR/dots-extra/install-${DISTRO_TYPE}.sh"
[[ -f "$DISTRO_INSTALLER" ]] || die "Distro installer not found: $DISTRO_INSTALLER"

bash "$DISTRO_INSTALLER" "$HYPRLAND_CONF" "$BACKUP_DIR" "$CONFIG_TYPE" "$REPO_DIR"


# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Done
# ══════════════════════════════════════════════════════════════════════════════
step 5 "Done"

echo ""
log_ok "Brain Shell v0.2.0 installed successfully."
echo ""

echo -e "  ${BOLD}Next Steps:${NC}"
if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && command -v hyprctl &>/dev/null && hyprctl activeworkspace &>/dev/null; then
    log_info "Active Hyprland session detected:"
    log_info "  • Log out and back in, or run: ${CYAN}hyprctl dispatch exit${NC}"
else
    log_info "From TTY, launch your Hyprland session:"
    log_info "  • Run: ${CYAN}Hyprland${NC}"
fi
echo ""

echo -e "  ${BOLD}Essential Shortcuts:${NC}"
log_info "  ${BOLD}SUPER + D${NC}          Dashboard (Home & System Monitoring)"
log_info "  ${BOLD}SUPER + Q${NC}          Application Launcher"
log_info "  ${BOLD}SUPER + C${NC}          Shell Configuration & Settings"
log_info "  ${BOLD}SUPER + ESC${NC}        Power Menu"
log_info "  ${BOLD}CTRL + ESC${NC}         Emergency Keybind Exit (if ever trapped)"
echo ""

echo -e "  ${BOLD}Paths & Configuration:${NC}"
log_info "Config:              ~/.config/Brain_Shell"
log_info "Source:              $REPO_DIR"
if [[ -d "$BACKUP_DIR" ]]; then
    log_info "Backup:              $BACKUP_DIR"
fi
log_info "Wallpapers:          Stored in ~/Pictures/Wallpapers"
echo ""

exit 0
