#!/bin/bash

#Brain Shell — Post-Installation Validator                   
#Verify all dependencies                            

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
INSTALLED=0
MISSING=0
OPTIONAL_MISSING=0

# Logging functions
log_installed() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((INSTALLED++))
}

log_missing() {
    echo -e "${RED}[✗]${NC} $1 ${YELLOW}(MISSING)${NC}"
    ((MISSING++))
}

log_optional() {
    echo -e "${YELLOW}[○]${NC} $1 ${YELLOW}(optional)${NC}"
    ((OPTIONAL_MISSING++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log_installed "$1"
    else
        log_missing "$1"
    fi
}

check_optional() {
    if command -v "$1" &> /dev/null; then
        log_installed "$1 (optional)"
    else
        log_optional "$1"
    fi
}

check_package() {
    local pkg="$1"
    local cmd="$2"
    [[ -z "$cmd" ]] && cmd="$pkg"
    
    if command -v "$cmd" &> /dev/null; then
        log_installed "$pkg"
    else
        log_missing "$pkg"
    fi
}


# HEADER

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║              Brain Shell — Post-Installation Validator                       ║
║                  Verify all dependencies are installed                       ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

echo ""


# DETECT DISTRO

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
else
    DISTRO="unknown"
fi

log_info "Detected distribution: $DISTRO"
echo ""

# CORE DEPENDENCIES CHECK

echo -e "${BOLD}━━━ CORE RUNTIME ━━━${NC}"

check_command "quickshell"
check_command "hyprland"
check_command "hyprctl"

echo ""
echo -e "${BOLD}━━━ QT6 & RENDERING ━━━${NC}"

check_package "qt6-base" "qdbus"
check_command "qt6ct"

echo ""
echo -e "${BOLD}━━━ SYSTEM TOOLS ━━━${NC}"

check_command "pactl" || check_command "pacmd"
check_command "bluetoothctl"
check_command "brightnessctl"
check_command "upower"
check_command "notify-send"
check_command "pkexec"
check_command "python"
check_command "wl-copy"
check_command "slurp"

echo ""
echo -e "${BOLD}━━━ SCREEN RECORDING ━━━${NC}"

check_command "wf-recorder"
check_command "cava"

echo ""
echo -e "${BOLD}━━━ WALLPAPER & THEMING ━━━${NC}"

check_command "magick"
check_optional "awww"
check_optional "matugen"

echo ""
echo -e "${BOLD}━━━ CLIPBOARD ━━━${NC}"

check_command "wtype"
check_optional "cliphist"

echo ""
echo -e "${BOLD}━━━ POWER & HARDWARE ━━━${NC}"

check_optional "envycontrol"
check_optional "auto-cpufreq"
check_command "sensors"
check_optional "nbfc"
check_command "rfkill"

echo ""
echo -e "${BOLD}━━━ HYPRLAND ECOSYSTEM ━━━${NC}"

check_command "hyprsunset"
check_command "hyprlock"
check_command "hypridle"
check_optional "hyprshutdown"

echo ""
echo -e "${BOLD}━━━ FONTS ━━━${NC}"

if fc-list | grep -q "JetBrains Mono"; then
    log_installed "JetBrains Mono Nerd Font"
else
    log_missing "JetBrains Mono Nerd Font"
fi

# CONFIGURATION FILES

echo ""
echo -e "${BOLD}━━━ CONFIGURATION FILES ━━━${NC}"

if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    log_installed "Hyprland config"
    
    if grep -q "quickshell.*-c.*Brain_Shell" "$HOME/.config/hypr/hyprland.conf"; then
        log_installed "Brain Shell exec-once in hyprland.conf"
    else
        log_missing "Brain Shell exec-once in hyprland.conf"
    fi
else
    log_missing "Hyprland config"
fi

if [[ -d "$HOME/.local/src/repo/Brain_Shell" ]]; then
    log_installed "Brain Shell repository"
else
    log_missing "Brain Shell repository"
fi

if [[ -d "$HOME/.config/Brain_Shell" ]]; then
    log_installed "Brain Shell config directory"
else
    log_missing "Brain Shell config directory"
fi

# BACKUP CHECK
echo ""
echo -e "${BOLD}━━━ BACKUPS ━━━${NC}"

BACKUP_COUNT=$(ls -d $HOME/.config.backup-* 2>/dev/null | wc -l)

if [[ $BACKUP_COUNT -gt 0 ]]; then
    log_info "Found $BACKUP_COUNT config backup(s)"
    ls -d $HOME/.config.backup-* 2>/dev/null | while read backup; do
        echo -e "  ${BLUE}→${NC} ${backup##*/}"
    done
else
    log_optional "No config backups found"
fi

################################################################################
# SERVICES CHECK
################################################################################

echo ""
echo -e "${BOLD}━━━ SYSTEMD SERVICES ━━━${NC}"

check_service_enabled() {
    if systemctl is-enabled "$1" &> /dev/null; then
        log_installed "Service: $1"
    else
        log_optional "Service: $1 (not enabled)"
    fi
}

check_user_service() {
    if systemctl --user is-enabled "$1" &> /dev/null; then
        log_installed "User service: $1"
    else
        log_optional "User service: $1 (not enabled)"
    fi
}

check_service_enabled "NetworkManager"
check_service_enabled "bluetooth"
check_service_enabled "upower"
check_user_service "pipewire"
check_user_service "wireplumber"

# OPTIONAL FEATURES

echo ""
echo -e "${BOLD}━━━ OPTIONAL FEATURES ━━━${NC}"

if [[ -f "$HOME/.config/matugen/templates/brain-shell-colors.json" ]]; then
    log_installed "Matugen color template"
else
    log_optional "Matugen color template (needed for live color sync)"
fi

if [[ -f "$HOME/.config/hypr/shaders" ]] && [[ -n "$(ls -A $HOME/.config/hypr/shaders 2>/dev/null)" ]]; then
    log_installed "Custom shaders directory"
else
    log_optional "Custom shaders (optional)"
fi

if grep -q "cliphist" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
    log_installed "Clipboard history (cliphist)"
else
    log_optional "Clipboard history (add wl-paste watchers to hyprland.conf)"
fi


# SUMMARY

echo ""
echo -e "${BOLD}━━━ SUMMARY ━━━${NC}"

TOTAL=$((INSTALLED + MISSING + OPTIONAL_MISSING))

echo -e "${GREEN}✓ Installed: $INSTALLED${NC}"
echo -e "${RED}✗ Missing: $MISSING${NC}"
echo -e "${YELLOW}○ Optional: $OPTIONAL_MISSING${NC}"
echo ""

if [[ $MISSING -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All required dependencies are installed!${NC}"
    exit 0
else
    echo -e "${YELLOW}${BOLD}Some required dependencies are missing.${NC}"
    echo ""
    echo "To fix:"
    echo "  • Arch:  Re-run install-arch.sh or install missing packages with pacman/yay"
    echo "  • NixOS: Re-run install-nix.sh or add packages to your flake.nix"
    echo ""
    exit 1
fi
