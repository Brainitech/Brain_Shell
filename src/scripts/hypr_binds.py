#!/usr/bin/env python3
import json
import subprocess
import sys

MOD_BITS = {1: "SHIFT", 4: "CTRL", 8: "ALT", 64: "SUPER"}

def parse_mods(mask):
    parts = []
    for bit in [64, 4, 8, 1]:  # SUPER, CTRL, ALT, SHIFT
        if mask & bit:
            parts.append(MOD_BITS[bit])
    return " + ".join(parts)

def main():
    try:
        raw = subprocess.check_output(["hyprctl", "binds", "-j"], stderr=subprocess.DEVNULL).decode()
        live_binds = json.loads(raw)
    except Exception:
        print("[]")
        sys.exit(1)

    import re, os
    bs_lua_binds = []
    kb_lua = os.path.expanduser("~/.config/Brain_Shell/Brain_ShellKeybinds.lua")
    if os.path.isfile(kb_lua):
        try:
            with open(kb_lua) as f:
                content = f.read()
            for m in re.finditer(r'hl\.bind\s*\(\s*["\']([^"\']+)["\']\s*,\s*hl\.dsp\.exec_cmd\([^)]*qs ipc', content):
                combo = m.group(1).strip()
                parts = [p.strip() for p in combo.split("+")]
                k = parts[-1].lower()
                m_parts = [p.upper() for p in parts[:-1]]
                mask = 0
                for bit, name in MOD_BITS.items():
                    if name in m_parts:
                        mask |= bit
                bs_lua_binds.append((mask, k))
        except Exception:
            pass

    out = []
    for b in live_binds:
        dispatcher = b.get("dispatcher", "")
        arg = b.get("arg", "")
        desc = b.get("description", "")
        
        # Omit Brain Shell bindings
        if "qs ipc" in arg or "brain_shell" in arg.lower() or "brain-shell" in arg.lower():
            continue
        if "brain shell" in desc.lower() or "brain_shell" in desc.lower() or "brain-shell" in desc.lower():
            continue

        if dispatcher == "__lua":
            b_mask = b.get("modmask", 0)
            b_key = str(b.get("key", "")).lower()
            matched = False
            for idx, (l_mask, l_key) in enumerate(bs_lua_binds):
                if l_mask == b_mask and l_key == b_key:
                    matched = True
                    bs_lua_binds.pop(idx)
                    break
            if matched:
                continue
            
        out.append({
            "modmask": b.get("modmask", 0),
            "mods_str": parse_mods(b.get("modmask", 0)),
            "key": b.get("key", ""),
            "dispatcher": dispatcher,
            "arg": arg,
            "description": desc,
            "submap": b.get("submap", ""),
            "submap_universal": b.get("submap_universal", "false")
        })
        
    print(json.dumps(out))

if __name__ == "__main__":
    main()
