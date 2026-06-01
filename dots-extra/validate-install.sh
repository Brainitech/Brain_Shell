#!/bin/bash

# Brain Shell — Post-Installation Validator

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALLED=0
MISSING=0
OPTIONAL_MISSING=0

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

clear
echo "Brain Shell — Post-Installation Validator"
echo "Verify all dependencies are installed"
echo ""

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
else
    DISTRO="unknown"
fi

log_info "Detected distribution: $DISTRO"
echo ""

echo "# CORE RUNTIME"
check_command "quickshell"
check_command "hyprland"
check_command "hyprctl"

echo ""
echo "# QT6 & RENDERING"
check_package "qt6-base" "qdbus"
check_command "qt6ct"

echo ""
echo "# SYSTEM TOOLS"
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
echo "# SCREEN RECORDING"
check_command "wf-recorder"
check_command "cava"

echo ""
echo "# WALLPAPER & THEMING"
check_command "magick"
check_optional "awww"
check_optional "matugen"

echo ""
echo "# CLIPBOARD"
check_command "wtype"
check_optional "cliphist"

echo ""
echo "# POWER & HARDWARE"
check_optional "envycontrol"
check_optional "auto-cpufreq"
check_command "sensors"
check_optional "nbfc"
check_command "rfkill"

echo ""
echo "# HYPRLAND ECOSYSTEM"
check_command "hyprsunset"
check_command "hyprlock"
check_command "hypridle"
check_optional "hyprshutdown"

echo ""
echo "# FONTS"
if fc-list | grep -q "JetBrains Mono"; then
    log_installed "JetBrains Mono Nerd Font"
else
    log_missing "JetBrains Mono Nerd Font"
fi

echo ""
echo "# CONFIGURATION FILES"

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

if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    log_installed "Hyprland Lua config"
    
    if grep -q "quickshell.*Brain_Shell" "$HOME/.config/hypr/hyprland.lua"; then
        log_installed "Brain Shell exec-once in hyprland.lua"
    else
        log_optional "Brain Shell exec-once in hyprland.lua (optional)"
    fi
else
    log_optional "Hyprland Lua config (optional)"
fi

if [[ -d "$HOME/.local/src/Brain_Shell" ]]; then
    log_installed "Brain Shell repository"
else
    log_missing "Brain Shell repository"
fi

if [[ -d "$HOME/.config/Brain_Shell" ]]; then
    log_installed "Brain Shell config directory"
else
    log_missing "Brain Shell config directory"
fi

echo ""
echo "# BACKUPS"
BACKUP_COUNT=$(ls -d $HOME/.config.backup-* 2>/dev/null | wc -l)

if [[ $BACKUP_COUNT -gt 0 ]]; then
    log_info "Found $BACKUP_COUNT config backup(s)"
    ls -d $HOME/.config.backup-* 2>/dev/null | while read backup; do
        echo -e "  ${BLUE}→${NC} ${backup##*/}"
    done
else
    log_optional "No config backups found"
fi

echo ""
echo "# SUMMARY"
TOTAL=$((INSTALLED + MISSING + OPTIONAL_MISSING))

echo -e "${GREEN}✓ Installed: $INSTALLED${NC}"
echo -e "${RED}✗ Missing: $MISSING${NC}"
echo -e "${YELLOW}○ Optional: $OPTIONAL_MISSING${NC}"
echo ""

if [[ $MISSING -eq 0 ]]; then
    echo -e "${GREEN}All required dependencies are installed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some required dependencies are missing.${NC}"
    echo ""
    echo "To fix:"
    echo "  • Arch:  Re-run install-arch.sh or install missing packages with pacman/yay"
    echo "  • NixOS: Re-run install-nix.sh or add packages to your flake.nix"
    echo ""
    exit 1
fi
