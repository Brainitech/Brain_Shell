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

QtObject {
    id: root

    function isModKey(key) {
        if (!key) return false
        var u = key.toUpperCase().trim()
        return u === "SUPER_L" || u === "SUPER_R" ||
               u === "ALT_L"   || u === "ALT_R"   ||
               u === "CONTROL_L" || u === "CONTROL_R" ||
               u === "SHIFT_L" || u === "SHIFT_R" ||
               u === "SUPER"   || u === "ALT"     ||
               u === "CTRL"    || u === "SHIFT"
    }

    function modForModKey(key) {
        if (!key) return ""
        var u = key.toUpperCase().trim()
        if (u === "SUPER_L" || u === "SUPER_R" || u === "SUPER") return "SUPER"
        if (u === "ALT_L" || u === "ALT_R" || u === "ALT" || u === "ALTGR") return "ALT"
        if (u === "CONTROL_L" || u === "CONTROL_R" || u === "CTRL_L" || u === "CTRL_R" || u === "CTRL") return "CTRL"
        if (u === "SHIFT_L" || u === "SHIFT_R" || u === "SHIFT") return "SHIFT"
        return ""
    }

    function normalizeKey(key) {
        if (!key) return ""
        var s = key.trim()
        var u = s.toUpperCase()
        if (u === "UNKNOWN") return ""
        if (u === "SUPER_L" || u === "SUPER") return "SUPER_L"
        if (u === "SUPER_R") return "SUPER_R"
        if (u === "ALT_L" || u === "ALT") return "Alt_L"
        if (u === "ALT_R" || u === "ALTGR") return "Alt_R"
        if (u === "CONTROL_L" || u === "CTRL_L" || u === "CTRL") return "Control_L"
        if (u === "CONTROL_R" || u === "CTRL_R") return "Control_R"
        if (u === "SHIFT_L" || u === "SHIFT") return "Shift_L"
        if (u === "SHIFT_R") return "Shift_R"
        return u
    }

    function effectiveMods(mods, key) {
        if ((!mods || mods === "") && isModKey(key)) {
            return modForModKey(key)
        }
        return mods || ""
    }

    function modsToMask(modsStr) {
        if (!modsStr) return 0
        var mask = 0
        var parts = modsStr.toUpperCase().split("+")
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim()
            if      (p === "SUPER" || p === "MOD") mask |= 64
            else if (p === "SHIFT") mask |= 1
            else if (p === "CTRL" || p === "CONTROL")  mask |= 4
            else if (p === "ALT")   mask |= 8
        }
        return mask
    }

    function groupedKeybinds(keybinds) {
        var groups = {}
        var order = []
        var ks = Object.keys(keybinds || {})
        for (var i = 0; i < ks.length; i++) {
            var k = ks[i]
            var b = keybinds[k]
            if (!b || b.mods === undefined || !b.key || b.key === "" || b.key.toUpperCase() === "UNKNOWN") continue
            var g = b.group || "Other"
            if (!groups[g]) {
                groups[g] = []
                order.push(g)
            }
            var entry = { k: k, mods: b.mods, key: b.key, label: b.label }
            groups[g].push(entry)
        }
        return { groups: groups, order: order }
    }

    function wouldConflict(rawKeybinds, action, mods, key, defaultLabel) {
        if (!key || key === "" || !rawKeybinds) return ""
        var mask = modsToMask(effectiveMods(mods, key))
        var k = normalizeKey(key).toLowerCase()
        for (var i = 0; i < rawKeybinds.length; i++) {
            var b = rawKeybinds[i]
            if (b.submap && b.submap !== "") continue
            if (b.mouse) continue
            if (b.arg && (b.arg.indexOf("qs ipc") >= 0 || b.arg.indexOf("quickshell ipc") >= 0 || b.arg.indexOf("brain-shell ipc") >= 0)) continue
            if (b.description && b.description.toLowerCase().indexOf("brain shell") >= 0) continue

            if (b.modmask === mask && (b.key || "").toLowerCase() === k) {
                if (b.description && b.description.trim() !== "") return b.description
                if (b.dispatcher === "__lua") return "Lua Bind (No Description)"
                var desc = b.dispatcher || ""
                if (b.arg) desc += ": " + b.arg.substring(0, 36)
                return desc || (defaultLabel || "Compositor bind")
            }
        }
        return ""
    }
}
