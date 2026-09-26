#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — NixOS Installer
#  Invoked by install.sh:  $1=HYPRLAND_CONF  $2=BACKUP_DIR  $3=CONFIG_TYPE
# ─────────────────────────────────────────────────────────────────────────────

set -eo pipefail

HYPRLAND_CONF="${1:?Missing arg: HYPRLAND_CONF path}"
CONFIG_TYPE="${2:?Missing arg: CONFIG_TYPE (conf|lua)}"
REPO_DIR="${3:-$HOME/.local/src/Brain_Shell}"

RED='\033[0;31m';   GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';  CYAN='\033[0;36m';   BOLD='\033[1m'
DIM='\033[2m';      NC='\033[0m'

log_info()  { echo -e "  ${BLUE}·${NC} $1"; }
log_ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
log_warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "  ${RED}✗${NC} $1" >&2; }
die()       { echo ""; log_error "$1"; exit 1; }

TOTAL_STEPS=2
step() {
    echo ""
    echo -e "${BOLD}${CYAN}  [$1/$TOTAL_STEPS]  $2${NC}"
    echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Hyprland Config
# ══════════════════════════════════════════════════════════════════════════════
step 1 "Hyprland Config"

# ── Pre-generate fallback keybinds for first-boot ─────────────────────────────
_KB_DIR="$HOME/.config/Brain_Shell"
mkdir -p "$_KB_DIR"
if [[ ! -f "$_KB_DIR/Brain_ShellKeybinds.lua" ]]; then
    cat << LUAEOF > "$_KB_DIR/Brain_ShellKeybinds.lua"
local shell = "$REPO_DIR"
hl.define_submap("BrainShell_clean", function()
    hl.bind("CTRL + ESCAPE", function()
        hl.dispatch(hl.dsp.exec_cmd("notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'"))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { description = "Emergency return to global submap" })
end)
hl.bind("SUPER + D", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-home toggle"), { description = "Brain Shell: Dashboard" })
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-stats toggle"), { description = "Brain Shell: Task Manager" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-kanban toggle"), { description = "Brain Shell: Kanban Board" })
hl.bind("SUPER + Q", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-launcher toggle"), { description = "Brain Shell: App Launcher" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call dashboard-config toggle"), { description = "Brain Shell: Shell Config" })
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call PowerMenu-toggle toggle"), { description = "Brain Shell: Power Menu" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call notification-toggle toggle"), { description = "Brain Shell: Notifications" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call wallpaper-toggle toggle"), { description = "Brain Shell: Wallpaper" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call clipboard-toggle toggle"), { description = "Brain Shell: Clipboard" })
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call wifi-toggle toggle"), { description = "Brain Shell: Network Wi-Fi" })
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call bluetooth-toggle toggle"), { description = "Brain Shell: Network Bluetooth" })
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call vpn-toggle toggle"), { description = "Brain Shell: Network VPN" })
hl.bind("SUPER + ALT + H", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call hotspot-toggle toggle"), { description = "Brain Shell: Network Hotspot" })
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call audioOut-toggle toggle"), { description = "Brain Shell: Audio Output" })
hl.bind("SUPER + ALT + I", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call audioIn-toggle toggle"), { description = "Brain Shell: Audio Input" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call audioMix-toggle toggle"), { description = "Brain Shell: Audio Mixer" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call focus-toggle toggle"), { description = "Brain Shell: Focus Mode" })
hl.bind("SUPER + X", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call lock-session toggle"), { description = "Brain Shell: Lock Screen" })
hl.bind("PRINT", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call screenshot-toggle toggle"), { description = "Brain Shell: Screenshot" })
hl.bind("ALT + F9", hl.dsp.exec_cmd("qs ipc -c " .. shell .. " call screenrec-on toggle"), { description = "Brain Shell: Screen Record" })
LUAEOF
fi

if [[ ! -f "$_KB_DIR/Brain_ShellKeybinds.conf" ]]; then
    cat << CONFEOF > "$_KB_DIR/Brain_ShellKeybinds.conf"
submap = BrainShell_clean
bind = CTRL, ESCAPE, exec, notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'
bind = CTRL, ESCAPE, submap, reset
submap = reset
bind = SUPER, D, exec, qs ipc -c $REPO_DIR call dashboard-home toggle
bind = CTRL SHIFT, ESCAPE, exec, qs ipc -c $REPO_DIR call dashboard-stats toggle
bind = SUPER, Z, exec, qs ipc -c $REPO_DIR call dashboard-kanban toggle
bind = SUPER, Q, exec, qs ipc -c $REPO_DIR call dashboard-launcher toggle
bind = SUPER, C, exec, qs ipc -c $REPO_DIR call dashboard-config toggle
bind = SUPER, ESCAPE, exec, qs ipc -c $REPO_DIR call PowerMenu-toggle toggle
bind = SUPER, N, exec, qs ipc -c $REPO_DIR call notification-toggle toggle
bind = SUPER, W, exec, qs ipc -c $REPO_DIR call wallpaper-toggle toggle
bind = SUPER, V, exec, qs ipc -c $REPO_DIR call clipboard-toggle toggle
bind = SUPER ALT, W, exec, qs ipc -c $REPO_DIR call wifi-toggle toggle
bind = SUPER ALT, B, exec, qs ipc -c $REPO_DIR call bluetooth-toggle toggle
bind = SUPER ALT, G, exec, qs ipc -c $REPO_DIR call vpn-toggle toggle
bind = SUPER ALT, H, exec, qs ipc -c $REPO_DIR call hotspot-toggle toggle
bind = SUPER, A, exec, qs ipc -c $REPO_DIR call audioOut-toggle toggle
bind = SUPER ALT, I, exec, qs ipc -c $REPO_DIR call audioIn-toggle toggle
bind = SUPER, M, exec, qs ipc -c $REPO_DIR call audioMix-toggle toggle
bind = SUPER, B, exec, qs ipc -c $REPO_DIR call focus-toggle toggle
bind = SUPER, X, exec, qs ipc -c $REPO_DIR call lock-session toggle
bind = , PRINT, exec, qs ipc -c $REPO_DIR call screenshot-toggle toggle
bind = ALT, F9, exec, qs ipc -c $REPO_DIR call screenrec-on toggle
CONFEOF
fi

STARTUP_CONF="$HOME/.config/Brain_Shell/hypr/brain-shell.conf"
STARTUP_LUA="$HOME/.config/Brain_Shell/hypr/brain-shell.lua"
mkdir -p "$HOME/.config/Brain_Shell/hypr"

cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.conf" "$STARTUP_CONF"
cp "$REPO_DIR/src/config/autostart/BrainShell-hyprland.lua"  "$STARTUP_LUA"
sed -i "s|\$HOME/.local/src/Brain_Shell|$REPO_DIR|g" "$STARTUP_CONF" "$STARTUP_LUA"
log_ok "Generated isolated startup configs"

_BEGIN_MARK_CONF="# >>> Brain Shell Startup >>>"
_END_MARK_CONF="# <<< Brain Shell Startup <<<"
_BEGIN_MARK_LUA="-- >>> Brain Shell Startup >>>"
_END_MARK_LUA="-- <<< Brain Shell Startup <<<"

if [[ "${FRESH_INSTALL:-}" == "true" ]]; then
    log_info "Detecting keyboard layout for base config..."
    detect_keyboard_layout() {
        local layout="" variant=""
        if command -v localectl &>/dev/null; then
            local status; status="$(localectl status 2>/dev/null)"
            layout="$(awk -F': ' '/X11 Layout/{print $2; exit}'  <<< "$status" | tr -d '[:space:]')"
            variant="$(awk -F': ' '/X11 Variant/{print $2; exit}' <<< "$status" | tr -d '[:space:]')"
        fi
        layout="${layout%%,*}"
        [[ -z "$layout" ]] && layout="us"
        printf '%s\t%s\n' "$layout" "$variant"
    }
    KB_LAYOUT=""; KB_VARIANT=""
    IFS=$'\t' read -r KB_LAYOUT KB_VARIANT <<< "$(detect_keyboard_layout)"
    KB_LAYOUT="${KB_LAYOUT//[[:space:]]/}"
    KB_VARIANT="${KB_VARIANT//[[:space:]]/}"
    [[ -z "$KB_LAYOUT" || "$KB_LAYOUT" == "(unset)" || "$KB_LAYOUT" == "n/a" ]] && KB_LAYOUT="us"
    [[ "$KB_VARIANT" == "(unset)" || "$KB_VARIANT" == "n/a" ]] && KB_VARIANT=""
    log_ok "Keyboard layout detected: ${KB_LAYOUT}${KB_VARIANT:+ (${KB_VARIANT})}"

    HYPR_DIR="$(dirname "$HYPRLAND_CONF")"
    mkdir -p "$HYPR_DIR"
    
    _TMP_HYPR=$(mktemp -d)
    cp -r "$REPO_DIR/src/config/hypr_template/"* "$_TMP_HYPR/"
    sed -i -e "s|kb_layout[[:space:]]*=.*|kb_layout          = \"${KB_LAYOUT}\",|g" \
           -e "s|kb_variant[[:space:]]*=.*|kb_variant         = \"${KB_VARIANT}\",|g" \
           "$_TMP_HYPR/config/input.lua"
    cp -r "$_TMP_HYPR/"* "$HYPR_DIR/"
    rm -rf "$_TMP_HYPR"
    log_ok "Generated base hyprland config with keyboard layout"
fi

if [[ -f "$HYPRLAND_CONF" ]]; then
    TS=$(date +%Y%m%d_%H%M%S)
    cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.mod-backup-${TS}"
    log_info "Backup created: ${HYPRLAND_CONF}.mod-backup-${TS}"
fi

log_info "Migrating active configuration..."
python3 -c '
import sys, re
with open(sys.argv[1], "r") as f: content = f.read()
# Scrub legacy inline autostarts (conf)
content = re.sub(r"\n*# Brain Shell Autostarts\n(exec-once = .*\n){1,8}", "\n", content)
# Scrub legacy inline autostarts (lua)
content = re.sub(r"\n*-- Brain Shell Autostarts\nhl\.on\(\"hyprland\.start\", function\(\)\n(    hl\.exec_cmd\(.*\)\n){1,8}end\)\n*", "\n", content)
# Scrub legacy keybind injections (conf)
content = re.sub(r"\n*# Brain_ShellKeybinds\nsource = .*Brain_ShellKeybinds\.conf\n*", "\n", content)
# Scrub legacy keybind injections (lua)
content = re.sub(r"\n*-- Brain_ShellKeybinds\ndofile\(.*Brain_ShellKeybinds\.lua\"\)\n*", "\n", content)
with open(sys.argv[1], "w") as f: f.write(content.strip() + "\n")
' "$HYPRLAND_CONF"

if grep -q "brain-shell" "$HYPRLAND_CONF"; then
    log_ok "Brain Shell startup already sourced in $HYPRLAND_CONF"
else
    case "$CONFIG_TYPE" in
        conf)
            {
                echo ""
                echo "$_BEGIN_MARK_CONF"
                echo "source = $HOME/.config/Brain_Shell/hypr/brain-shell.conf"
                echo "$_END_MARK_CONF"
            } >> "$HYPRLAND_CONF"
            log_ok "Brain Shell startup sourced from hyprland.conf (1 line)"
            ;;
        lua)
            {
                echo ""
                echo "$_BEGIN_MARK_LUA"
                echo 'dofile(os.getenv("HOME") .. "/.config/Brain_Shell/hypr/brain-shell.lua")'
                echo "$_END_MARK_LUA"
            } >> "$HYPRLAND_CONF"
            log_ok "Brain Shell startup loaded from hyprland.lua (1 line)"
            ;;
        *)
            log_warn "Unknown config type '$CONFIG_TYPE' — skipping Hyprland config update."
            ;;
    esac
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Brain Shell Config & Keybind Check
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Brain Shell Config"

USER_DATA="$HOME/.config/Brain_Shell/src/user_data"
# Pre-generate default colors to prevent unstyled first boot
mkdir -p "$HOME/.config/Brain_Shell/matugen"
(cd "$REPO_DIR" && matugen image "src/assets/wallpapers/brain-shell-default-0.png" -c "src/config/matugen.toml" -m dark --source-color-index 0 --type scheme-content >/dev/null 2>&1 || true)

mkdir -p "$USER_DATA" \
         "$HOME/.config/hypr/shaders" \
         "$HOME/.config/matugen/templates" \
         "$HOME/.cache/brain-shell" \
         "$HOME/Pictures/Wallpapers"

cp -n "$REPO_DIR/src/config/hypridle.conf" "$HOME/.config/hypr/" 2>/dev/null || true
cp -n "$REPO_DIR/src/config/hyprlock.conf" "$HOME/.config/hypr/" 2>/dev/null || true
touch "$HOME/.cache/brain-shell/colors.json"
cp -n -r "$REPO_DIR/src/assets/wallpapers"/* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
printf '{"configProvider": "%s"}\n' "$CONFIG_TYPE" > "$USER_DATA/config_Provider.json"
if [[ ! -f "$USER_DATA/keybinds.json" ]]; then
    printf '{}\n' > "$USER_DATA/keybinds.json"
fi

log_ok "Config and cache directories initialized."

# ── Keybind Conflict Detection ────────────────────────────────────────────────
echo ""
log_info "Checking keybind conflicts against active Hyprland session..."

python3 << 'PYEOF' || log_warn "Keybind check skipped (Python error or no Hyprland session)."
import subprocess, json, os, sys, re

DEFAULTS = {
    "dashboard-home":      {"mods": "SUPER",        "key": "D",      "label": "Dashboard: Home"},
    "dashboard-stats":     {"mods": "CTRL + SHIFT", "key": "ESCAPE", "label": "Dashboard: System"},
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
    "lock-session":        {"mods": "SUPER",        "key": "X",      "label": "Lock Screen"},
    "screenshot-toggle":   {"mods": "",             "key": "PRINT",  "label": "Screenshot"},
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
    with open("/tmp/bs_keybind_skipped", "w") as f: f.write("1")
    sys.exit(0)

bs_lua_binds = []
kb_lua = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.lua")
if os.path.isfile(kb_lua):
    try:
        with open(kb_lua) as f:
            content = f.read()
        for m in re.finditer(r'hl\.bind\s*\(\s*["\']([^"\']+)["\']\s*,\s*hl\.dsp\.exec_cmd\([^)]*qs ipc', content):
            combo = m.group(1).strip()
            parts = [p.strip() for p in combo.split("+")]
            key = parts[-1].lower()
            mods = "+".join(parts[:-1]) if len(parts) > 1 else ""
            bs_lua_binds.append((mods_to_mask(mods), key))
    except Exception:
        pass

consumed_bind_indices = set()
for i, hb in enumerate(hypr_binds):
    if hb.get("submap", "") or hb.get("mouse"):
        continue
    desc = hb.get("dispatcher", "")
    arg = hb.get("arg", "")
    hb_desc = hb.get("description", "")

    if "qs ipc" in arg or "brain_shell" in arg.lower() or "brain-shell" in arg.lower():
        consumed_bind_indices.add(i)
        continue
    if "brain shell" in hb_desc.lower() or "brain_shell" in hb_desc.lower() or "brain-shell" in hb_desc.lower():
        consumed_bind_indices.add(i)
        continue

    if desc == "__lua" and ("brain shell" in hb_desc.lower() or "brain-shell" in hb_desc.lower()):
        consumed_bind_indices.add(i)
        continue

conflicts = {}
for action, data in DEFAULTS.items():
    mask = mods_to_mask(data["mods"])
    key  = data["key"].lower()
    for i, hb in enumerate(hypr_binds):
        if i in consumed_bind_indices:
            continue
        if hb.get("submap", "") or hb.get("mouse"):
            continue
        if hb.get("modmask") == mask and str(hb.get("key", "")).lower() == key:
            desc = hb.get("dispatcher", "")
            arg  = hb.get("arg", "")
            hb_desc = hb.get("description", "")
            used_by = f"{desc} {arg}".strip()
            if hb_desc:
                used_by += f" ({hb_desc})"
            conflicts[action] = {
                "bind":    f"{data['mods']} + {data['key']}" if data['mods'] else data['key'],
                "label":   data["label"],
                "used_by": used_by,
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
existing = {}
if os.path.isfile(config_path):
    try:
        with open(config_path) as f:
            existing = json.load(f)
    except Exception:
        existing = {}
existing.update(unbound)
os.makedirs(os.path.dirname(config_path), exist_ok=True)
with open(config_path, "w") as f:
    json.dump(existing, f, indent=2)

lua_path = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.lua")
conf_path = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.conf")
for p in [lua_path, conf_path]:
    if os.path.isfile(p):
        with open(p) as f: lines = f.readlines()
        with open(p, "w") as f:
            for line in lines:
                if not any(f"call {a} toggle" in line for a in conflicts):
                    f.write(line)

print("  \033[1;33m⚠\033[0m  Conflicting binds left unbound in Brain Shell.")
print("       Re-assign them: Dashboard  →  Config  →  Keybinds\n")
PYEOF

echo ""
echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
log_ok "NixOS configuration complete."
log_info "System packages and services are managed via your flake."

touch "$HOME/.config/Brain_Shell/.v0.2.0_migrated"

if ! command -v quickshell &>/dev/null; then
    cat << NIXEOF > "$HOME/.config/Brain_Shell/nix-deps.txt"
# Brain Shell - Required NixOS Packages Checklist
# Add these to your environment.systemPackages or home.packages:

- quickshell
- hyprland
- python3
- brightnessctl
- playerctl
- lm_sensors
- networkmanager
- bluez
- pipewire
- wireplumber
- pulseaudio (for pactl)
- wl-clipboard
- hypridle
- hyprlock
- hyprpolkitagent
- xdg-desktop-portal-hyprland
- xdg-desktop-portal-gtk
- matugen
- awww
- kitty
- grimblast
- slurp
- wf-recorder
- cava
- wtype
- cliphist
- imagemagick
- hyprsunset
- libnotify
- xdg-user-dirs
- rfkill
- mpv-mpris
- mpd-mpris
- ranger
- nerd-fonts.jetbrains-mono
- nerd-fonts.symbols-only
- qt6Packages.qt6ct
- qt6.qtmultimedia
- qt6.qt5compat

# Optional hardware tools:
# - auto-cpufreq (enable via: services.auto-cpufreq.enable = true;)
# - envycontrol (for NVIDIA GPU switching, if applicable)
NIXEOF
    log_info "A package checklist has been saved to ~/.config/Brain_Shell/nix-deps.txt"
fi

echo -e "  ${BOLD}Hardware Features Status:${NC}"
if command -v envycontrol &>/dev/null; then
    log_ok "GPU Switching:      envycontrol active"
else
    log_info "GPU Switching:      disabled (optional — configure via flake or PRIME)"
fi
if command -v nbfc &>/dev/null; then
    log_ok "Fan Control:        nbfc-linux active"
else
    log_info "Fan Control:        disabled (optional — laptop EC fan control)"
fi
if command -v auto-cpufreq &>/dev/null; then
    log_ok "Power Profile:      auto-cpufreq active"
else
    log_info "Power Profile:      disabled (optional — enable services.auto-cpufreq)"
fi
echo ""

if [[ -f "/tmp/bs_keybind_skipped" ]]; then
    log_warn "Keybind conflict check skipped (Hyprland not running)."
    log_info "Please run 'qs ipc call dashboard-config' after booting to resolve overlaps."
    rm -f "/tmp/bs_keybind_skipped"
fi

touch "$HOME/.config/Brain_Shell/.v0.2.0_migrated"
exit 0
