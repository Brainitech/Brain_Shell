import QtQuick
import Quickshell
import Quickshell.Io
import "../../components"
import "../../"

IconBtn {
    id: rootBtn
    text: ""
    textColor: "#1793d1"

    Process {
        id: osProcess
        command: ["bash", "-c", "source /etc/os-release && echo $ID"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let osId = text.trim().toLowerCase()
                let defaultSize = Math.round(16 * rootBtn.localScale)
                let smallSize = Math.round(14 * rootBtn.localScale)

                if (osId === "arch") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#1793d1"
                    rootBtn.fontSize = smallSize
                } else if (osId === "nixos") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#5277C3"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "manjaro") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#35bf5c"
                    rootBtn.fontSize = smallSize
                } else if (osId === "garuda") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#f94416"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "endeavouros") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#7f71ad"
                    rootBtn.fontSize = defaultSize
                } else if (osId === "cachyos") {
                    rootBtn.text = ""
                    rootBtn.textColor = "#00fde8"
                    rootBtn.fontSize = defaultSize
                } else {
                    rootBtn.text = ""
                    rootBtn.textColor = "#dfe7ec"
                    rootBtn.fontSize = defaultSize
                }
            }
        }
    }

    onClicked: {
        if (!Popups.archMenuOpen) {
            SurfaceState.open("leftCenter", "archMenu")
            Popups.archMenuPinned = true
        } else {
            SurfaceState.close()
        }
    }
}
