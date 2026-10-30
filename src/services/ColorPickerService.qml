/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../state"

QtObject {
    id: root

    property string format: "HEX"
    property string lastColor: ""
    readonly property bool picking: Popups.colorPickerActive

    signal colorPicked(string color)

    function cycleFormat() {
        if (root.format === "HEX") root.format = "RGB";
        else if (root.format === "RGB") root.format = "HSL";
        else root.format = "HEX";
    }

    function pick(customFormat) {
        Popups.colorPickerActive = true
        var fmt = customFormat || root.format

        pickerProc.command = ["bash", "-c",
            "geom=$(slurp -p -b 00000000 -c 00000000 2>/dev/null) || exit 0; " +
            "rgb=$(grim -g \"$geom\" -t ppm - 2>/dev/null | tail -c 3 | od -An -t u1) || exit 0; " +
            "res=$(echo \"$rgb\" | awk -v fmt=\"" + fmt + "\" '{" +
            "  r=$1+0; g=$2+0; b=$3+0; " +
            "  if(fmt==\"RGB\") printf \"rgb(%d, %d, %d)\",r,g,b; " +
            "  else if(fmt==\"HSL\"){ " +
            "    rf=r/255;gf=g/255;bf=b/255; mx=rf;mn=rf; " +
            "    if(gf>mx)mx=gf; if(bf>mx)mx=bf; if(gf<mn)mn=gf; if(bf<mn)mn=bf; " +
            "    l=(mx+mn)/2; if(mx==mn){h=0;sv=0} else { d=mx-mn; " +
            "    sv=(l>0.5)?d/(2-mx-mn):d/(mx+mn); " +
            "    if(mx==rf)h=(gf-bf)/d+(gf<bf?6:0); else if(mx==gf)h=(bf-rf)/d+2; else h=(rf-gf)/d+4; h=h/6; } " +
            "    printf \"hsl(%d, %d%%, %d%%)\",int(h*360+0.5),int(sv*100+0.5),int(l*100+0.5); " +
            "  } else { " +
            "    printf \"#%02x%02x%02x\",r,g,b; " +
            "  } " +
            "}'); " +
            "if [ -n \"$res\" ]; then " +
            "  printf '%s' \"$res\" | { if command -v wl-copy >/dev/null 2>&1; then setsid -f wl-copy; else wl-copy; fi; }; " +
            "  echo \"$res\"; " +
            "fi"
        ]

        pickerProc.running = false
        pickerProc.running = true
    }

    property var pickerProc: Process {
        stdout: SplitParser {
            onRead: function(l) {
                var c = l.trim()
                if (c !== "") {
                    root.lastColor = c
                    root.colorPicked(c)
                }
            }
        }
        onExited: Popups.colorPickerActive = false
    }
}
