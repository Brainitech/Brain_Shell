#!/bin/bash

# Brain Shell — Main Installation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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

clear
echo "Brain Shell — Installation"
echo "github.com/Brainitech/Brain_Shell v0.1.0"
echo ""

log_info "Starting Brain Shell installation..."
echo ""

if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    log_warn "Not running in Hyprland. Installation will proceed, but you must"
    log_warn "restart Hyprland after completion for changes to take effect."
    echo ""
fi

if [[ ! "$OSTYPE" =~ ^linux ]]; then
    log_error "This installer only supports Linux systems."
    exit 1
fi

log_info "Detecting Linux distribution..."

DISTRO=""

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
elif [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    DISTRO="$DISTRIB_ID"
fi

case "$DISTRO" in
    arch|manjaro|garuda|cachyos|endeavouros)
        log_success "Detected: Arch-based distro ($DISTRO)"
        DISTRO_TYPE="arch"
        ;;
    nixos)
        log_success "Detected: NixOS"
        DISTRO_TYPE="nix"
        ;;
    *)
        log_error "Unsupported distribution: $DISTRO"
        log_error "Currently supported: Arch Linux, Manjaro, Garuda, CachyOS, EndeavourOS, NixOS"
        exit 1
        ;;
esac

echo ""

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

log_info "Validating Hyprland configuration..."

HYPRLAND_CONF_PATH="$CONFIG_DIR/hypr/hyprland.conf"
HYPRLAND_LUA_PATH="$CONFIG_DIR/hypr/hyprland.lua"

if [[ -f "$HYPRLAND_CONF_PATH" ]]; then
    HYPRLAND_CONF="$HYPRLAND_CONF_PATH"
    log_success "Hyprland config found (.conf)."
elif [[ -f "$HYPRLAND_LUA_PATH" ]]; then
    HYPRLAND_CONF="$HYPRLAND_LUA_PATH"
    log_success "Hyprland config found (.lua)."
else
    log_error "Hyprland config not found (checked for .conf and .lua) in $CONFIG_DIR/hypr/"
    log_error "Please set up Hyprland first before installing Brain Shell."
    exit 1
fi

echo ""

log_info "Downloading Brain Shell repository..."

REPO_DIR="$HOME/.local/src"
mkdir -p "$REPO_DIR"

if [[ -d "$REPO_DIR/Brain_Shell" ]]; then
    log_warn "Brain Shell repo already exists. Updating..."
    cd "$REPO_DIR/Brain_Shell"
    git fetch origin main 2>/dev/null || true
    git checkout main 2>/dev/null || true
    git pull origin main 2>/dev/null || true
else
    log_info "Cloning from GitHub (main branch)..."
    cd "$REPO_DIR"
    git clone -b main https://github.com/Brainitech/Brain_Shell.git
fi

cd "$REPO_DIR/Brain_Shell"
log_success "Repository ready at: $REPO_DIR/Brain_Shell"
echo ""

DISTRO_INSTALLER="./dots-extra/install-${DISTRO_TYPE}.sh"

if [[ ! -f "$DISTRO_INSTALLER" ]]; then
    log_error "Distro installer not found: $DISTRO_INSTALLER"
    exit 1
fi

log_info "Executing distro-specific installer..."
echo ""

bash "$DISTRO_INSTALLER" "$HYPRLAND_CONF" "$BACKUP_DIR"

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
log_info "Repository cloned to: ~/.local/src/Brain_Shell"
echo ""

exit 0
