#!/bin/bash
#Brain Shell — Main Installation Script
#github.com/Brainitech/Brain_Shell           


set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# WELCOME & VALIDATION
clear
cat << "EOF"
#replace this line with ur ascii art 
EOF

log_info "Starting Brain Shell installation..."
echo ""

# Check if running in Hyprland
if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    log_warn "Not running in Hyprland. Installation will proceed, but you must"
    log_warn "restart Hyprland after completion for changes to take effect."
    echo ""
fi

# Validate we're on Linux
if [[ ! "$OSTYPE" =~ ^linux ]]; then
    log_error "This installer only supports Linux systems."
    exit 1
fi

log_info "Detecting Linux distribution..."

# DISTRO DETECTION

DISTRO=""

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
elif [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    DISTRO="$DISTRIB_ID"
fi

case "$DISTRO" in
    arch|manjaro)
        log_success "Detected: Arch Linux / Manjaro"
        DISTRO_TYPE="arch"
        ;;
    *)
        log_error "Unsupported distribution: $DISTRO"
        log_error "Currently supported: Arch Linux, Manjaro, NixOS"
        exit 1
        ;;
esac

echo ""

# BACKUP ~/.config

log_info "Backing up ~/.config directory..."

CONFIG_DIR="$HOME/.config"
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config.backup-${BACKUP_TIMESTAMP}"

if [[ -d "$CONFIG_DIR" ]]; then
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
    log_success "Backup created: ${BACKUP_DIR##*/}"
    log_info "You can restore with: cp -r \"$BACKUP_DIR\" \"$CONFIG_DIR\""
else
    log_warn "~/.config does not exist (first install?). Skipping backup."
fi

echo ""

# HYPRLAND VALIDATION


log_info "Validating Hyprland configuration..."

HYPRLAND_CONF="$CONFIG_DIR/hypr/hyprland.conf"

if [[ ! -f "$HYPRLAND_CONF" ]]; then
    log_error "Hyprland config not found at: $HYPRLAND_CONF"
    log_error "Please set up Hyprland first before installing Brain Shell."
    exit 1
fi

log_success "Hyprland config found."
echo ""

# DISTRO-SPECIFIC INSTALLER

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRO_INSTALLER="${SCRIPT_DIR}/dots-extra/install-${DISTRO_TYPE}.sh"

if [[ ! -f "$DISTRO_INSTALLER" ]]; then
    log_error "Distro installer not found: $DISTRO_INSTALLER"
    exit 1
fi

log_info "Executing distro-specific installer..."
echo ""

# Pass backup directory path to distro installer
bash "$DISTRO_INSTALLER" "$HYPRLAND_CONF" "$BACKUP_DIR"

# COMPLETION

echo ""
log_success "Brain Shell installation complete!"
echo ""
log_warn "You must restart Hyprland for changes to take effect."
log_info "Restart options:"
log_info "  • Exit and log back in (preferred)"
log_info "  • Press Ctrl+Alt+Q in Hyprland (if configured)"
log_info "  • Run: hyprctl dispatch exit"
echo ""
log_info "After restart, Brain Shell will launch automatically via exec-once."
echo ""
log_info "Configuration located at: ~/.config/Brain_Shell"
log_info "Repository cloned to: ~/.local/src/repo/Brain_Shell"
echo ""

exit 0
