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

QtObject {
    id: root

    // Environment overrides (priority 1)
    readonly property string envInstallDir: Quickshell.env("BRAIN_SHELL_INSTALL_DIR")
    readonly property string envConfigDir:  Quickshell.env("BRAIN_SHELL_CONFIG_DIR")
    readonly property string envIsNix:      Quickshell.env("BRAIN_SHELL_NIX")

    // Fallback detection (priority 2 & 3)
    readonly property string defaultInstallDir: Quickshell.env("HOME") + "/.local/src/Brain_Shell"
    readonly property string defaultConfigDir:  Quickshell.env("HOME") + "/.config/Brain_Shell"

    readonly property string installDir: (envInstallDir && envInstallDir !== "") ? envInstallDir : (Quickshell.shellDir !== "" ? Quickshell.shellDir : defaultInstallDir)
    readonly property string configDir:  (envConfigDir && envConfigDir !== "") ? envConfigDir : defaultConfigDir
    readonly property string userDataDir: configDir + "/src/user_data"

    readonly property bool isNix: envIsNix === "1" || installDir.indexOf("/nix/store") !== -1
}
