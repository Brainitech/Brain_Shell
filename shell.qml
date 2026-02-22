import Quickshell
import QtQuick
import "./src/windows"
import "./src/popups"
import "./src/"

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                required property var modelData

                property string screenName: modelData.name

                // --- Windows ---
                TopBar   { screen: modelData }

                Border   { screen: modelData; edge: "left";   id: leftBorder  }
                Border   { screen: modelData; edge: "right"  }
                Border   { screen: modelData; edge: "bottom" }

                // Dismiss all popups on click-outside or Escape
                PopupDismiss { screen: modelData }

                // --- Popups ---
                ArchMenu { anchorWindow: leftBorder }
            }
        }
    }
}
