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

TOTAL_STEPS=4
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
echo -e "  ${DIM}v0.2.0  ·  github.com/Brainitech/Brain_Shell${NC}" # Update is finally seeing its light after getting the TeamCherry Treatment
echo ""


# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Pre-Flight Checks
# ══════════════════════════════════════════════════════════════════════════════
step 1 "Pre-Flight Checks"

[[ "$EUID" -eq 0 ]] && die "Do not run this script as root or with sudo. It prompts for sudo when required."

# OS
[[ "$OSTYPE" =~ ^linux ]] || die "This installer only supports Linux."
log_ok "Linux confirmed"

# NixOS Detection
if [[ -f /etc/NIXOS ]] || { [[ -d /nix ]] && command -v nixos-version &>/dev/null; } || { [[ -f /etc/os-release ]] && grep -Eq '^ID=("?nixos"?|.*nixos)' /etc/os-release 2>/dev/null; }; then
    log_ok "Distro: NixOS"
    echo ""
    echo -e "  ${BOLD}${CYAN}Brain Shell on NixOS${NC}"
    echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
    echo -e "  Brain Shell provides official declarative NixOS and Home Manager modules."
    echo -e "  Imperative installation via this script is not needed and not recommended."
    echo ""
    echo -e "  ${BOLD}Declarative Configuration Options:${NC}"
    echo ""
    echo -e "  ${BOLD}1. NixOS System Flake (/etc/nixos/flake.nix):${NC}"
    echo -e "     inputs.brain-shell = {"
    echo -e "       url = \"github:Brainitech/Brain_Shell?ref=main\";"
    echo -e "       inputs.nixpkgs.follows = \"nixpkgs\";"
    echo -e "     };"
    echo -e "     modules = [ brain-shell.nixosModules.default ];"
    echo -e "     ${GREEN}programs.brain-shell.enable = true;${NC}"
    echo ""
    echo -e "  ${BOLD}2. Home Manager Flake:${NC}"
    echo -e "     inputs.brain-shell = {"
    echo -e "       url = \"github:Brainitech/Brain_Shell?ref=main\";"
    echo -e "       inputs.nixpkgs.follows = \"nixpkgs\";"
    echo -e "     };"
    echo -e "     modules = [ brain-shell.homeManagerModules.default ];"
    echo -e "     ${GREEN}programs.brain-shell.enable = true;${NC}"
    echo ""
    echo -e "  For complete documentation and configuration examples, see:"
    echo -e "  ${CYAN}https://github.com/Brainitech/Brain_Shell#nixos${NC}"
    echo ""
    exit 0
fi

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
        arch|manjaro|garuda|cachyos|endeavouros|artix)
            log_ok "Distro: ${ID} (Arch-based)"
            DISTRO_TYPE="arch"
            ;;
        nixos)
            die "Install Brain_Shell via flakes/home-manager modules provided on the README"
            ;;
        omarchy)
            log_ok "Distro: ${ID} (Omarchy) detected."
            DISTRO_TYPE="arch"
            IS_OMARCHY="true"
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
    log_info "Make sure Hyprland is installed before launching it." #Future work: Prompt user for Hyprland installation, waiting for config files so
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
# STEP 2 — Repository
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Repository"

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
        BRAIN_SHELL_BRANCH="${BRAIN_SHELL_BRANCH:-main}"
        git -C "$REPO_DIR" fetch origin "$BRAIN_SHELL_BRANCH" || true
        # Verify untracked changes before destructive clean
        if [[ -n $(git -C "$REPO_DIR" status --porcelain) ]]; then
            log_warn "Local repository has uncommitted changes. Using git pull --rebase instead of hard reset."
            git -C "$REPO_DIR" pull --rebase origin "$BRAIN_SHELL_BRANCH" || true
        else
            git -C "$REPO_DIR" reset --hard "origin/$BRAIN_SHELL_BRANCH" &>/dev/null || true
            git -C "$REPO_DIR" clean -fd &>/dev/null || true
        fi
        log_ok "Repository updated: $REPO_DIR"
    fi
else
    log_info "Cloning from GitHub..."
    BRAIN_SHELL_BRANCH="${BRAIN_SHELL_BRANCH:-main}"
    git clone -b "$BRAIN_SHELL_BRANCH" https://github.com/Brainitech/Brain_Shell.git "$REPO_DIR"
    log_ok "Repository cloned: $REPO_DIR"
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Distro-Specific Install
# ══════════════════════════════════════════════════════════════════════════════
step 3 "Distro-Specific Installation"
echo ""

DISTRO_INSTALLER="$REPO_DIR/dots-extra/install-${DISTRO_TYPE}.sh"
[[ -f "$DISTRO_INSTALLER" ]] || die "Distro installer not found: $DISTRO_INSTALLER"

bash "$DISTRO_INSTALLER" "$HYPRLAND_CONF" "$CONFIG_TYPE" "$REPO_DIR"


# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Done
# ══════════════════════════════════════════════════════════════════════════════
step 3 "Done"

echo ""
log_ok "Brain Shell v0.2.0 installed successfully."
echo ""

if [[ "$IS_OMARCHY" == "true" ]]; then
    log_warn "Omarchy OS detected. omarchy-shell conflicts with Brain_Shell's Notification and Wallpaper Manager."
    OMARCHY_AUTOSTART="/usr/share/omarchy/default/hypr/autostart.lua"
    if [[ -f "$OMARCHY_AUTOSTART" ]]; then
        read -p "  Do you want to automatically disable omarchy-shell? (Requires sudo) [Y/n] " -n 1 -r < /dev/tty
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "Skipping automatic disable. Please follow the README to disable it manually."
        else
            log_info "Disabling omarchy-shell..."
            sudo sed -i --follow-symlinks '/omarchy-launch-shell/!b; /^[[:space:]]*--/b; s/^[[:space:]]*/&-- /' "$OMARCHY_AUTOSTART" 2>/dev/null || \
            sudo sed -i '/omarchy-launch-shell/!b; /^[[:space:]]*--/b; s/^[[:space:]]*/&-- /' "$OMARCHY_AUTOSTART"
            
            if grep -q "^[[:space:]]*--.*omarchy-launch-shell" "$OMARCHY_AUTOSTART" 2>/dev/null; then
                log_ok "omarchy-shell successfully disabled in $OMARCHY_AUTOSTART."
            else
                log_warn "Failed to comment out line (File might be protected or line missing)."
                log_info "Please check $OMARCHY_AUTOSTART manually."
            fi
        fi
        echo ""
    else
        log_warn "Could not find $OMARCHY_AUTOSTART. Please check the README to disable it manually."
        echo ""
    fi
fi


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
log_info "Wallpapers:          Stored in ~/Pictures/Wallpapers"
echo ""

exit 0
