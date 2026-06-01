#!/bin/bash

#Brain Shell — Arch Linux Installer 
#Handles pacman + AUR packages


set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Parameters from main installer
HYPRLAND_CONF="$1"
BACKUP_DIR="$2"

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


# AUR HELPER DETECTION & SELECTION


AUR_HELPER=""

log_info "Detecting AUR helper..."

# Check if yay is installed
if command -v yay &> /dev/null; then
    log_success "Found: yay"
    AUR_HELPER="yay"
# Check if paru is installed
elif command -v paru &> /dev/null; then
    log_success "Found: paru"
    AUR_HELPER="paru"
else
    log_warn "No AUR helper found (yay/paru). Please choose one to install:"
    echo ""
    echo "  1) yay (recommended, more interactive)"
    echo "  2) paru (faster builds, more features)"
    echo "  3) Skip AUR packages (will install pacman packages only)"
    echo ""
    read -p "Enter choice [1/2/3]: " AUR_CHOICE

    case "$AUR_CHOICE" in
        1)
            log_info "Installing yay..."
            if ! command -v git &> /dev/null; then
                sudo pacman -S --noconfirm git base-devel
            fi
            cd /tmp
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            cd /tmp && rm -rf yay
            AUR_HELPER="yay"
            log_success "yay installed."
            ;;
        2)
            log_info "Installing paru..."
            if ! command -v git &> /dev/null; then
                sudo pacman -S --noconfirm git base-devel
            fi
            cd /tmp
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si --noconfirm
            cd /tmp && rm -rf paru
            AUR_HELPER="paru"
            log_success "paru installed."
            ;;
        3)
            log_warn "Skipping AUR packages. Some features may not work correctly."
            AUR_HELPER="none"
            ;;
        *)
            log_error "Invalid choice."
            exit 1
            ;;
    esac
fi

echo ""


# DEPENDENCY INSTALLATION


log_info "Installing dependencies from pacman..."

# Pacman packages (from dependency doc)
PACMAN_DEPS=(
    # Core runtime
    "hyprland"
    "qt6-base"
    "qt6-declarative"
    "qt6-multimedia"
    "qt6-5compat"
    "qt6ct"
    
    # System tools
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "brightnessctl"
    "upower"
    "libnotify"
    "polkit"
    "python"
    "wl-clipboard"
    "slurp"
    "xdg-user-dirs"
    
    # Screen recording
    "wf-recorder"
    "cava"
    
    # Wallpaper & theming
    "imagemagick"
    
    # Clipboard
    "wtype"
    
    # Power & hardware
    "lm_sensors"
    "rfkill"
    
    # Hyprland ecosystem
    "hyprsunset"
    "hyprlock"
    "hypridle"
    "xdg-desktop-portal-hyprland"
    
    # Fonts
    "ttf-jetbrains-mono-nerd"
)

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

log_success "Pacman packages installed."
echo ""

# AUR packages
if [[ "$AUR_HELPER" != "none" ]]; then
    log_info "Installing dependencies from AUR..."
    
    AUR_DEPS=(
        "quickshell"
        "awww"
        "matugen"
        "envycontrol"
        "auto-cpufreq"
        "nbfc-linux"
        "cliphist"
        "hyprshutdown"
    )
    
    for pkg in "${AUR_DEPS[@]}"; do
        if ! $AUR_HELPER -Q "$pkg" &> /dev/null; then
            log_info "Installing $pkg..."
            $AUR_HELPER -S --noconfirm "$pkg"
        else
            log_success "$pkg already installed."
        fi
    done
    
    log_success "AUR packages installed."
else
    log_warn "Skipping AUR packages:"
    log_warn "  - quickshell (REQUIRED - cannot proceed without this)"
    log_warn "  - awww, matugen, envycontrol, auto-cpufreq, nbfc-linux, cliphist, hyprshutdown"
    echo ""
    log_error "quickshell is required. Please install an AUR helper and run this script again."
    exit 1
fi

echo ""


# ENABLE SYSTEMD SERVICES


log_info "Enabling system services..."

sudo systemctl enable --now NetworkManager 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true
sudo systemctl enable --now upower 2>/dev/null || true
systemctl --user enable --now pipewire 2>/dev/null || true
systemctl --user enable --now pipewire-pulse 2>/dev/null || true
systemctl --user enable --now wireplumber 2>/dev/null || true

log_success "System services configured."
echo ""


# CLONE BRAIN SHELL REPOSITORY


log_info "Cloning Brain Shell repository..."

REPO_DIR="$HOME/.local/src"
mkdir -p "$REPO_DIR"

if [[ -d "$REPO_DIR/Brain_Shell" ]]; then
    log_warn "Brain Shell repo already exists. Updating..."
    cd "$REPO_DIR/Brain_Shell"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    log_info "Cloning from GitHub..."
    cd "$REPO_DIR"
    git clone https://github.com/Brainitech/Brain_Shell.git
fi

log_success "Repository cloned/updated to: $REPO_DIR/Brain_Shell"
echo ""


# UPDATE HYPRLAND CONFIG


log_info "Updating Hyprland configuration..."

# Check for hyprland.conf
HYPRLAND_LUA="$HOME/.config/hypr/hyprland.lua"

# Create backup if not already done by main script
if [[ ! -f "${HYPRLAND_CONF}.backup" ]]; then
    cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.backup"
    log_info "Backup created: ${HYPRLAND_CONF}.backup"
fi

# Update hyprland.conf if it exists
if grep -q "exec-once.*quickshell.*-c.*Brain_Shell" "$HYPRLAND_CONF" 2>/dev/null; then
    log_warn "Brain Shell exec-once already present in hyprland.conf"
else
    EXEC_CMD="exec-once = quickshell -c \$HOME/.local/src/Brain_Shell"
    
    if tail -1 "$HYPRLAND_CONF" | grep -q '}'; then
        sed -i "$ s/^/# Brain Shell\n$EXEC_CMD\n\n/" "$HYPRLAND_CONF"
    else
        echo "" >> "$HYPRLAND_CONF"
        echo "# Brain Shell" >> "$HYPRLAND_CONF"
        echo "$EXEC_CMD" >> "$HYPRLAND_CONF"
    fi
    
    log_success "Added Brain Shell to hyprland.conf"
fi

# Update hyprland.lua if it exists
HYPRLAND_LUA="$HOME/.config/hypr/hyprland.lua"

if [[ -f "$HYPRLAND_LUA" ]]; then
    if grep -q "quickshell.*Brain_Shell" "$HYPRLAND_LUA" 2>/dev/null; then
        log_warn "Brain Shell exec-once already present in hyprland.lua"
    else
        # Create backup of lua file
        if [[ ! -f "${HYPRLAND_LUA}.backup" ]]; then
            cp "$HYPRLAND_LUA" "${HYPRLAND_LUA}.backup"
            log_info "Backup created: ${HYPRLAND_LUA}.backup"
        fi
        
        # Add to lua file
        echo "" >> "$HYPRLAND_LUA"
        echo "-- Brain Shell" >> "$HYPRLAND_LUA"
        echo "hl.exec_once(\"quickshell -c \$HOME/.local/src/Brain_Shell\")" >> "$HYPRLAND_LUA"
        
        log_success "Added Brain Shell to hyprland.lua"
    fi
fi

echo ""


# CONFIGURATION SETUP


log_info "Setting up configuration directories..."

CONFIG_BRAIN_SHELL="$HOME/.config/Brain_Shell"
mkdir -p "$CONFIG_BRAIN_SHELL"

# Create default config directories if they don't exist
mkdir -p "$HOME/.config/hypr/shaders"
mkdir -p "$HOME/.config/matugen/templates"

log_success "Configuration directories created."
echo ""


# COMPLETION MESSAGE


log_success "Arch Linux installation complete!"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "1. Review/update your Hyprland config (if needed)"
echo "2. (Optional) Copy matugen template: cp ~/.local/src/repo/Brain_Shell/src/config/brain-shell-colors.json.example ~/.config/matugen/templates/brain-shell-colors.json"
echo "3. Restart Hyprland (Ctrl+Alt+Q or log out and back in)"
echo ""
echo -e "${BOLD}Additional Configuration:${NC}"
echo "• See installation doc for optional features (GPU switching, VPN, etc.)"
echo "• Qt6 theme: Run 'qt6ct' to configure fonts and appearance"
echo "• Clipboard: Add to Hyprland exec-once (see doc for exact commands)"
echo ""

exit 0
