#!/usr/bin/env python3
import json
import sys
import hyprland_socket
import hyprland_config
from hyprland_config import is_bind_keyword, parse_bind_line
from hyprmod.binds.live import live_bind_to_data

def main():
    try:
        live_binds = hyprland_socket.get_binds()
        live_data = [live_bind_to_data(b) for b in live_binds]
        
        entry = hyprland_config.default_entrypoint()
        
        # Build by_combo ourselves to extract description
        by_combo = {}
        if entry:
            doc = hyprland_config.load_any(entry)
            for kw in doc.find_all("bind*"):
                if not is_bind_keyword(kw.key):
                    continue
                parsed = parse_bind_line(doc.expand(kw.raw.strip()))
                if parsed:
                    # Fix bindd misparsing
                    if parsed.bind_type == "bindd":
                        # parsed.dispatcher is the description, parsed.arg is "dispatcher, arg"
                        desc = parsed.dispatcher
                        rest = parsed.arg.split(",", 1)
                        dispatcher = rest[0].strip()
                        arg = rest[1].strip() if len(rest) > 1 else ""
                        by_combo[parsed.combo] = {
                            "dispatcher": dispatcher,
                            "arg": arg,
                            "description": desc
                        }
                    else:
                        by_combo[parsed.combo] = {
                            "dispatcher": parsed.dispatcher,
                            "arg": parsed.arg,
                            "description": ""
                        }

        out = []
        for live_b, b in zip(live_binds, live_data):
            mods_str = " + ".join(b.mods) if b.mods else ""
            desc = getattr(live_b, "description", "") or ""
            dispatcher = b.dispatcher
            arg = b.arg
            
            if b.dispatcher == "__lua":
                match = by_combo.get(b.combo)
                if match:
                    dispatcher = match["dispatcher"]
                    arg = match["arg"]
                    if not desc:
                        desc = match["description"]

            # Also fix fallback for conf users if IPC description somehow failed
            if dispatcher == "bindd" or (not desc and by_combo.get(b.combo)):
                match = by_combo.get(b.combo)
                if match and not desc:
                    desc = match["description"]

            out.append({
                "modmask": getattr(b, "modmask", 0), # live_data dropped modmask, it's ok we use mods_str
                "mods_str": mods_str,
                "key": b.key,
                "dispatcher": dispatcher,
                "arg": arg,
                "description": desc,
                "submap": getattr(b, "submap", "") or "",
                "submap_universal": "false"
            })
            
        print(json.dumps(out))
    except Exception as e:
        print("[]")
        sys.exit(1)

if __name__ == "__main__":
    main()
