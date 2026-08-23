#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — main Installer
#  github.com/Brainitech/Brain_Shell  v0.1.0
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
echo -e "  ${DIM}v0.1.0  ·  github.com/Brainitech/Brain_Shell${NC}"
echo ""


# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Pre-Flight Checks
# ══════════════════════════════════════════════════════════════════════════════
step 1 "Pre-Flight Checks"

# OS
[[ "$OSTYPE" =~ ^linux ]] || die "This installer only supports Linux."
log_ok "Linux confirmed"

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

# Hyprland session (warn only, don't abort)
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    log_warn "Not running inside a Hyprland session."
    log_info "Changes will apply after you restart Hyprland."
else
    log_ok "Hyprland session active"
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
    die "No Hyprland config found in $HYPR_DIR. Set up Hyprland first."
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Backup
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Backup"

BACKUP_TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config.backup-${BACKUP_TS}-Brain_Shell"
mkdir -p "$BACKUP_DIR"

if [[ -d "$HYPR_DIR" ]]; then
    cp -r "$HYPR_DIR" "$BACKUP_DIR/"
    log_ok "Backed up: ~/.config/hypr → $BACKUP_DIR"
else
    log_warn "$HOME/.config/hypr not found — nothing to back up."
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Repository
# ══════════════════════════════════════════════════════════════════════════════
step 3 "Repository"

REPO_PARENT="$HOME/.local/src"
REPO_DIR="$REPO_PARENT/Brain_Shell"
mkdir -p "$REPO_PARENT"

if [[ -d "$REPO_DIR/.git" ]]; then
    log_info "Existing clone found — updating..."
    git -C "$REPO_DIR" fetch origin main 2>/dev/null || true
    git -C "$REPO_DIR" checkout main 2>/dev/null || true
    git -C "$REPO_DIR" pull origin main 2>/dev/null || true
    log_ok "Repository updated: $REPO_DIR"
else
    log_info "Cloning from GitHub..."
    git clone -b main https://github.com/Brainitech/Brain_Shell.git "$REPO_DIR"
    log_ok "Repository cloned: $REPO_DIR"
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Distro-Specific Install
# ══════════════════════════════════════════════════════════════════════════════
step 4 "Distro-Specific Installation"
echo ""

DISTRO_INSTALLER="$REPO_DIR/dots-extra/install-${DISTRO_TYPE}.sh"
[[ -f "$DISTRO_INSTALLER" ]] || die "Distro installer not found: $DISTRO_INSTALLER"

chmod +x "$DISTRO_INSTALLER"
bash "$DISTRO_INSTALLER" "$HYPRLAND_CONF" "$BACKUP_DIR" "$CONFIG_TYPE"


# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Done
# ══════════════════════════════════════════════════════════════════════════════
step 5 "Done"

echo ""
log_ok "Brain Shell is installed."
echo ""
echo -e "  ${BOLD}Restart Hyprland to activate Brain Shell:${NC}"
log_info "Log out and log back in  ${DIM}(recommended)${NC}"
log_info "hyprctl dispatch exit"
log_info "Ctrl+Alt+Q               ${DIM}(if configured)${NC}"
echo ""
echo -e "  ${BOLD}Paths:${NC}"
log_info "Config:  ~/.config/Brain_Shell"
log_info "Source:  $REPO_DIR"
echo ""

exit 0
