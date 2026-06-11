#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — Main Installer
#  github.com/Brainitech/Brain_Shell  v0.1.0
# ─────────────────────────────────────────────────────────────────────────────

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

TOTAL_STEPS=7
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

# No root
[[ "$EUID" -eq 0 ]] && die "Do not run as root. Use sudo where needed."
log_ok "Running as user (not root)"

# ── Distro Detection ─────────────────────────────────────────────────────────
DISTRO_TYPE=""
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    case "${ID:-}" in
        arch|manjaro|garuda|cachyos|endeavouros)
            log_ok "Distro: ${ID} (Arch-based)"
            DISTRO_TYPE="arch"
            ;;
        fedora)
            log_ok "Distro: ${ID} (Fedora)"
            DISTRO_TYPE="fedora"
            ;;
        debian|ubuntu|pop)
            log_ok "Distro: ${ID} (Debian-based)"
            DISTRO_TYPE="debian"
            ;;
        nixos)
            log_ok "Distro: NixOS"
            DISTRO_TYPE="nix"
            ;;
        *)
            die "Unsupported distro: ${ID:-unknown}. Supported: Arch-based, Fedora, Debian-based, NixOS."
            ;;
    esac
else
    die "Cannot detect distro — /etc/os-release not found."
fi

# ── Essential Commands ───────────────────────────────────────────────────────
has_cmd() { command -v "$1" >/dev/null 2>&1; }

for cmd in git curl bash; do
    has_cmd "$cmd" || die "Missing essential command: $cmd"
done
log_ok "Essential commands available (git, curl, bash)"

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
    log_warn "~/.config/hypr not found — nothing to back up."
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
    
    # Compare hashes before pulling
    REMOTE_HASH=$(git -C "$REPO_DIR" rev-parse origin/main 2>/dev/null || echo "")
    LOCAL_HASH=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
    
    if [[ -n "$REMOTE_HASH" && "$REMOTE_HASH" == "$LOCAL_HASH" ]]; then
        log_ok "Repository already up to date ($(echo "$LOCAL_HASH" | cut -c1-8))"
    else
        git -C "$REPO_DIR" pull origin main 2>/dev/null || true
        log_ok "Repository updated: $REPO_DIR"
    fi
else
    log_info "Cloning from GitHub..."
    git clone -b main https://github.com/Brainitech/Brain_Shell.git "$REPO_DIR"
    log_ok "Repository cloned: $REPO_DIR"
fi

# Ensure CLI is executable
chmod +x "$REPO_DIR/cli.sh"


# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Distro-Specific Install
# ══════════════════════════════════════════════════════════════════════════════
step 4 "Distro-Specific Installation"
echo ""

# Check if distro-specific installer exists
DISTRO_INSTALLER="$REPO_DIR/dots-extra/install-${DISTRO_TYPE}.sh"
if [[ -f "$DISTRO_INSTALLER" ]]; then
    chmod +x "$DISTRO_INSTALLER"
    bash "$DISTRO_INSTALLER" "$HYPRLAND_CONF" "$BACKUP_DIR" "$CONFIG_TYPE"
else
    log_warn "Distro installer not found: $DISTRO_INSTALLER"
    log_info "Skipping dependency installation."
    log_info "Make sure you have the required packages installed."
fi

# ── Quickshell verification ──────────────────────────────────────────────────
if ! has_cmd qs && ! has_cmd quickshell; then
    log_warn "quickshell not found in PATH after distro install."
    log_info "Attempting to build from source..."
    
    QUICKSHELL_REPO="https://git.outfoxxed.me/outfoxxed/quickshell"
    BUILD_DIR=$(mktemp -d)
    
    git clone --recursive "$QUICKSHELL_REPO" "$BUILD_DIR" 2>/dev/null || {
        log_warn "Failed to clone Quickshell repo. Manual install required."
        rm -rf "$BUILD_DIR"
    }
    
    if [[ -d "$BUILD_DIR" ]]; then
        (
            cd "$BUILD_DIR"
            cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" 2>/dev/null || {
                log_warn "cmake failed — installing build tools..."
                case "$DISTRO_TYPE" in
                    arch) sudo pacman -S --needed --noconfirm cmake ninja gcc 2>/dev/null || true ;;
                    fedora) sudo dnf install -y cmake ninja-build gcc-c++ 2>/dev/null || true ;;
                    debian) sudo apt-get install -y cmake ninja-build g++ 2>/dev/null || true ;;
                esac
                cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" 2>/dev/null || {
                    log_warn "cmake still failed. Skipping Quickshell build."
                    exit 1
                }
            }
            cmake --build build 2>/dev/null || { log_warn "Build failed."; exit 1; }
            cmake --install build 2>/dev/null || { log_warn "Install failed."; exit 1; }
        ) && {
            log_ok "Quickshell built and installed to ~/.local/bin/"
            export PATH="$HOME/.local/bin:$PATH"
        } || {
            log_warn "Quickshell build failed. Please install manually."
        }
        rm -rf "$BUILD_DIR"
    fi
else
    log_ok "quickshell is available"
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Global Command
# ══════════════════════════════════════════════════════════════════════════════
step 5 "Global Command"

BIN_DIR="/usr/local/bin"
BIN_NAME="brain-shell"
BIN_PATH="$BIN_DIR/$BIN_NAME"
REPO_DIR="$HOME/.local/src/Brain_Shell"

# ── Install wrapper (not a symlink — wrapper sets up PATH + QML_IMPORT_PATH first) ──
if [[ -f "$BIN_PATH" ]]; then
    # Check if it's our wrapper or an old symlink
    if [[ -L "$BIN_PATH" ]]; then
        log_info "Replacing old symlink with wrapper..."
        sudo rm -f "$BIN_PATH"
    elif grep -q "Brain_Shell.*wrapper" "$BIN_PATH" 2>/dev/null; then
        log_ok "Wrapper already installed: $BIN_PATH"
    else
        log_warn "$BIN_PATH exists but is not our wrapper — backing up."
        sudo mv "$BIN_PATH" "${BIN_PATH}.bak-${BACKUP_TS}"
    fi
fi

if [[ ! -f "$BIN_PATH" ]] || ! grep -q "Brain_Shell.*wrapper" "$BIN_PATH" 2>/dev/null; then
    sudo mkdir -p "$BIN_DIR"
    # Generate wrapper that sets up environment before calling cli.sh
    sudo tee "$BIN_PATH" > /dev/null << WRAPPEREOF
#!/usr/bin/env bash
# Brain_Shell — global launcher wrapper
INSTALL_DIR="\${BRAIN_SHELL_DIR:-\$HOME/.local/src/Brain_Shell}"
case ":\$PATH:" in
    *:"\$HOME/.local/bin":*) ;;
    *) export PATH="\$HOME/.local/bin:\$PATH" ;;
esac
case ":\$QML2_IMPORT_PATH:" in
    *:"\$HOME/.local/lib/qml":*) ;;
    *) export QML2_IMPORT_PATH="\$HOME/.local/lib/qml:\$QML2_IMPORT_PATH" ;;
esac
export QML_IMPORT_PATH="\$QML2_IMPORT_PATH"
exec "\${INSTALL_DIR}/cli.sh" "\$@"
WRAPPEREOF
    sudo chmod +x "$BIN_PATH"
    log_ok "Global command created: ${BIN_NAME}"
fi

# Verify
if command -v "$BIN_NAME" &>/dev/null; then
    log_ok "'${BIN_NAME}' is now available system-wide"
else
    log_info "Restart your terminal or run: export PATH=\"$BIN_DIR:\$PATH\""
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — Fonts & Assets
# ══════════════════════════════════════════════════════════════════════════════
step 6 "Fonts & Assets"

# Install JetBrains Mono if missing (Brain Shell primary font)
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
    log_info "JetBrains Mono not detected — installing..."
    if ! has_cmd unzip; then
        log_warn "unzip not found — installing..."
        case "$DISTRO_TYPE" in
            arch) sudo pacman -S --needed --noconfirm unzip 2>/dev/null || true ;;
            fedora) sudo dnf install -y unzip 2>/dev/null || true ;;
            debian) sudo apt-get install -y unzip 2>/dev/null || true ;;
        esac
    fi
    FONT_DIR="$HOME/.local/share/fonts/jetbrains-mono"
    mkdir -p "$FONT_DIR"
    TEMP_DIR=$(mktemp -d)
    curl -sL "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip" -o "$TEMP_DIR/jb.zip" 2>/dev/null || {
        log_warn "Could not download JetBrains Mono. Install manually if text looks off."
        rm -rf "$TEMP_DIR"
    }
    if [[ -f "$TEMP_DIR/jb.zip" ]]; then
        unzip -q "$TEMP_DIR/jb.zip" -d "$TEMP_DIR"
        find "$TEMP_DIR" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
        rm -rf "$TEMP_DIR"
        fc-cache -f "$FONT_DIR" 2>/dev/null || true
        log_ok "JetBrains Mono installed"
    fi
else
    log_ok "JetBrains Mono already available"
fi

# Ensure wallpapers directory exists
mkdir -p "$HOME/Pictures/Wallpapers"
if [[ -d "$REPO_DIR/src/assets/wallpapers" ]]; then
    cp -n -r "$REPO_DIR/src/assets/wallpapers"/* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
    log_ok "Default wallpapers copied to ~/Pictures/Wallpapers/"
fi


# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — Hyprland Integration
# ══════════════════════════════════════════════════════════════════════════════
step 7 "Hyprland Integration"

log_info "Configuring Hyprland autostart..."
"$REPO_DIR/cli.sh" install hyprland "--${CONFIG_TYPE}" 2>/dev/null && {
    log_ok "Brain_Shell added to Hyprland autostart (${CONFIG_TYPE})"
} || {
    log_warn "Could not auto-configure Hyprland."
    log_info "Run manually:  brain-shell install hyprland"
}

# ── Post-install verification ────────────────────────────────────────────────
echo ""
echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
log_info "Post-install verification:"

# Check essential binaries
MISSING=()
for bin in qs quickshell hyprctl matugen; do
    has_cmd "$bin" || MISSING+=("$bin")
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
    log_ok "All essential binaries available"
else
    log_warn "Missing binaries: ${MISSING[*]}"
    log_info "Some features may not work until these are installed."
fi


# ══════════════════════════════════════════════════════════════════════════════
# DONE
# ══════════════════════════════════════════════════════════════════════════════
echo ""
log_ok "Brain Shell is installed."
echo ""
echo -e "  ${BOLD}Quick start:${NC}"
log_info "brain-shell                     ${DIM}Launch the shell${NC}"
log_info "brain-shell help                ${DIM}Show all commands${NC}"
log_info "brain-shell run launcher        ${DIM}Open app launcher${NC}"
echo ""
echo -e "  ${BOLD}Restart Hyprland to activate the bar:${NC}"
log_info "Log out and log back in  ${DIM}(recommended)${NC}"
log_info "hyprctl dispatch exit"
log_info "Ctrl+Alt+Q               ${DIM}(if configured)${NC}"
echo ""
echo -e "  ${BOLD}Paths:${NC}"
log_info "Config:  ~/.config/Brain_Shell"
log_info "Source:  $REPO_DIR"
log_info "Data:    ~/.local/share/Brain_Shell"
echo ""

exit 0
