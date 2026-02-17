// shell.qml - FINAL WORKING VERSION
import Quickshell
import QtQuick
import "./src/windows"
import "./src/components"
import "./src/theme/"

ShellRoot {
    Variants {
        model: Quickshell.screens
        
        delegate: Component {
            Scope {
                required property var modelData
                
                // Store screen name for easy access
                property string screenName: modelData.name
                
                // ===========================================
                // WINDOWS
                // ===========================================
                
                TopBar {
                    screen: modelData
                }
                
                Border {
                    screen: modelData
                    edge: "left"
                }

                Border {
                    screen: modelData
                    edge: "right"
                }

                Border {
                    screen: modelData
                    edge: "bottom"
                }
                
            }
        }
    }
}
