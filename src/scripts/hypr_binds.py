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

    out = []
    for b in live_binds:
        dispatcher = b.get("dispatcher", "")
        arg = b.get("arg", "")
        desc = b.get("description", "")
        
        # Omit Brain Shell bindings
        if "qs ipc" in arg or "Brain_Shell" in arg:
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
