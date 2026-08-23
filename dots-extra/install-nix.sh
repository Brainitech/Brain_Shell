#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Brain Shell — NixOS Installer
#  Invoked by install.sh:  $1=HYPRLAND_CONF  $2=BACKUP_DIR  $3=CONFIG_TYPE
# ─────────────────────────────────────────────────────────────────────────────

set -eo pipefail

HYPRLAND_CONF="${1:?Missing arg: HYPRLAND_CONF path}"
BACKUP_DIR="${2:?Missing arg: BACKUP_DIR}"
CONFIG_TYPE="${3:?Missing arg: CONFIG_TYPE (conf|lua)}"
REPO_DIR="$HOME/.local/src/Brain_Shell"

RED='\033[0;31m';   GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';  CYAN='\033[0;36m';   BOLD='\033[1m'
DIM='\033[2m';      NC='\033[0m'

log_info()  { echo -e "  ${BLUE}·${NC} $1"; }
log_ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
log_warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }

TOTAL_STEPS=3
step() {
    echo ""
    echo -e "${BOLD}${CYAN}  [$1/$TOTAL_STEPS]  $2${NC}"
    echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Hyprland Config
# ══════════════════════════════════════════════════════════════════════════════
step 1 "Hyprland Config"

_MARKER="quickshell.*Brain_Shell"

_append_conf() {
    cat << 'EOF' >> "$1"

# Brain Shell Autostarts
exec-once = awww-daemon
exec-once = hypridle -c $HOME/.local/src/Brain_Shell/src/config/hypridle.conf
exec-once = quickshell -c $HOME/.local/src/Brain_Shell/.
exec-once = systemctl --user start hyprpolkitagent
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
EOF
}

_append_lua() {
    cat << 'EOF' >> "$1"

-- Brain Shell Autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell/src/config/hypridle.conf")
    hl.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.local/src/Brain_Shell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
EOF
}

if grep -q "$_MARKER" "$HYPRLAND_CONF" 2>/dev/null; then
    log_warn "Autostart block already present — skipping."
else
    case "$CONFIG_TYPE" in
        conf)
            _append_conf "$HYPRLAND_CONF"
            log_ok "Autostart block appended to hyprland.conf"
            ;;
        lua)
            cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.pre-brain-shell"
            _append_lua "$HYPRLAND_CONF"
            log_ok "Autostart block appended to hyprland.lua"
            ;;
    esac
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Brain Shell Config & Keybind Check
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Brain Shell Config"

USER_DATA="$HOME/.config/Brain_Shell/src/user_data"

mkdir -p "$USER_DATA" \
         "$HOME/.config/hypr/shaders" \
         "$HOME/.config/matugen/templates" \
         "$HOME/.cache/brain-shell" \
         "$HOME/Pictures/Wallpapers"

cp -n "$REPO_DIR/src/config/hypridle.conf" "$HOME/.config/hypr/" 2>/dev/null || true
touch "$HOME/.cache/brain-shell/colors.json"
cp -n -r "$REPO_DIR/src/assets/wallpapers"/* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
touch "$USER_DATA/keybinds.json"

printf '{"configProvider": "%s"}\n' "$CONFIG_TYPE" > "$USER_DATA/config_Provider.json"
printf '{}\n' > "$USER_DATA/keybinds.json"

log_ok "Config and cache directories initialized."

# ── Keybind Conflict Detection ────────────────────────────────────────────────
echo ""
log_info "Checking keybind conflicts against active Hyprland session..."

python3 << 'PYEOF' || log_warn "Keybind check skipped (Python error or no Hyprland session)."
import subprocess, json, os, sys

DEFAULTS = {
    "dashboard-home":      {"mods": "SUPER",        "key": "D",      "label": "Dashboard: System"},
    "dashboard-stats":     {"mods": "CTRL + SHIFT", "key": "ESCAPE", "label": "Dashboard: Home"},
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
    sys.exit(0)

conflicts = {}
for action, data in DEFAULTS.items():
    mask = mods_to_mask(data["mods"])
    key  = data["key"].lower()
    for hb in hypr_binds:
        if hb.get("submap", "") or hb.get("mouse"):
            continue
        if hb.get("modmask") == mask and str(hb.get("key", "")).lower() == key:
            desc = hb.get("dispatcher", "")
            arg  = hb.get("arg", "")
            conflicts[action] = {
                "bind":    f"{data['mods']} + {data['key']}",
                "label":   data["label"],
                "used_by": f"{desc} {arg}".strip(),
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
with open(config_path, "w") as f:
    json.dump(unbound, f, indent=2)

print("  \033[1;33m⚠\033[0m  Conflicting binds left unbound in Brain Shell.")
print("       Re-assign them: Dashboard  →  Config  →  Keybinds\n")
PYEOF

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Done
# ══════════════════════════════════════════════════════════════════════════════
step 3 "Done"

echo ""
log_ok "NixOS setup complete."
log_info "System packages and dependencies are managed entirely by your flake."
echo ""
echo -e "  ${BOLD}Restart Hyprland to activate Brain Shell:${NC}"
log_info "Log out and log back in  ${DIM}(recommended)${NC}"
log_info "hyprctl dispatch exit"
echo ""

exit 0
