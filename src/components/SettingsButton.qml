import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Action Option"
    property string description: ""
    property string buttonText: "Click"
    property bool destructive: false
    // New modes
    property string inputType: "button" // "button", "options", "text"
    
    property var options: []
    property string selectedOption: ""
    property string inputText: ""
    
    // Built-in file/dir validation ("file" or "dir")
    property string validateAs: ""
    property bool _isInvalid: false

    property var _valProc: Process {
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                root._isInvalid = (line.trim() === "0")
            }
        }
    }

    function _validate(txt) {
        if (root.validateAs === "" || txt === "") {
            root._isInvalid = false
            return
        }
        var expandedTxt = txt.replace(/^~/, Quickshell.env("HOME"))
        
        if (root.validateAs === "image") {
            _valProc.command = ["bash", "-c", "if [ -f '" + expandedTxt + "' ] && [[ '" + expandedTxt.toLowerCase() + "' =~ \\.(png|jpg|jpeg|svg|webp|bmp)$ ]]; then echo 1; else echo 0; fi"]
        } else {
            var flag = root.validateAs === "dir" ? "-d" : "-f"
            _valProc.command = ["bash", "-c", "if [ " + flag + " '" + expandedTxt + "' ]; then echo 1; else echo 0; fi"]
        }
        
        _valProc.running = false
        _valProc.running = true
    }
    
    property bool expanded: false

    signal clicked()
    signal optionSelected(string opt)
    signal inputAccepted(string text)

    readonly property bool _hasExpandable: root.inputType !== "button"

    width: parent ? parent.width : 400
    height: baseRow.height + (expanded ? expandArea.implicitHeight : 0)
    clip: true
    
    Behavior on height { NumberAnimation { duration: Anim.fast; easing.type: Anim.outCubic } }

    // Background Hover Highlight
    Rectangle {
        anchors.fill: parent
        radius: Math.round(8 * localScale)
        color: btnMouse.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
    }

    Item {
        id: baseRow
        width: parent.width
        height: Math.round(root.description !== "" ? (52 * root.localScale) : (40 * root.localScale))

        Column {
            anchors {
                left: parent.left
                leftMargin: Math.round(8 * localScale)
                right: actionBtn.left
                rightMargin: Math.round(12 * localScale)
                verticalCenter: parent.verticalCenter
            }
            spacing: Math.round(4 * localScale)

            Text {
                text: root.text
                color: root.destructive ? "#f87171" : Theme.text
                font.pixelSize: Math.round(13 * localScale)
            }

            Text {
                visible: root.description !== ""
                text: root.description
                color: Qt.rgba(1, 1, 1, 0.4)
                font.pixelSize: Math.round(11 * localScale)
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        // Action Button / Value Display
        Rectangle {
            id: actionBtn
            anchors {
                right: parent.right
                rightMargin: Math.round(8 * localScale)
                verticalCenter: parent.verticalCenter
            }
            width: btnLabel.implicitWidth + Math.round(24 * localScale)
            height: Math.round(24 * localScale)
            radius: Math.round(4 * localScale)
            color: root.expanded ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15) 
                 : (btnMouse.pressed ? Qt.rgba(1, 1, 1, 0.15) : (btnMouse.hovered ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)))
            Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
            
            border.color: root.expanded ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                        : (root.destructive ? Qt.rgba(248/255, 113/255, 113/255, 0.3) : Qt.rgba(1, 1, 1, 0.1))
            border.width: 1

            Text {
                id: btnLabel
                anchors.centerIn: parent
                text: root._hasExpandable ? (root.expanded ? "Close" : root.buttonText) : root.buttonText
                color: root.expanded ? Theme.active : (root.destructive ? "#fca5a5" : Theme.text)
                font.pixelSize: Math.round(11 * localScale)
                font.weight: Font.Medium
            }
        }

        HoverHandler {
            id: btnMouse
            cursorShape: Qt.PointingHandCursor
        }
        MouseArea {
            anchors.fill: actionBtn
            onClicked: {
                if (root._hasExpandable) {
                    root.expanded = !root.expanded
                    if (root.expanded && root.inputType === "text") {
                        _txtInput.text = root.inputText
                        _txtInput.forceActiveFocus()
                    }
                } else {
                    root.clicked()
                }
            }
        }
    }

    // Expanding Area
    Item {
        id: expandArea
        width: parent.width
        anchors.top: baseRow.bottom
        implicitHeight: root.inputType === "options" ? Math.round(50 * root.localScale) : (root.inputType === "text" ? Math.round(50 * root.localScale) : 0)
        visible: root.height > baseRow.height

        // Left indicator line
        Rectangle {
            width: 2; color: Theme.active; radius: 1
            anchors { left: parent.left; leftMargin: Math.round(8 * localScale); top: parent.top; bottom: parent.bottom; bottomMargin: Math.round(12 * localScale) }
        }

        // --- Options Mode (Horizontal Flickable Pills) ---
        Flickable {
            visible: root.inputType === "options"
            anchors { left: parent.left; leftMargin: Math.round(20 * localScale); right: parent.right; rightMargin: Math.round(12 * localScale); top: parent.top; bottom: parent.bottom; bottomMargin: Math.round(12 * localScale) }
            contentWidth: _pillRow.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: _pillRow
                spacing: Math.round(8 * localScale)
                height: parent.height

                Repeater {
                    model: root.options
                    delegate: Rectangle {
                        required property var modelData
                        height: parent.height
                        width: _lbl.implicitWidth + Math.round(24 * root.localScale)
                        radius: Math.round(8 * root.localScale)
                        
                        property bool isSelected: root.selectedOption === modelData
                        
                        color: isSelected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15) 
                                          : (_pHov.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: isSelected ? Theme.active : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: Anim.fast } }

                        Text {
                            id: _lbl
                            anchors.centerIn: parent
                            text: modelData
                            color: isSelected ? Theme.active : Theme.text
                            font.pixelSize: Math.round(11 * root.localScale)
                        }

                        HoverHandler { id: _pHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedOption = modelData
                                root.optionSelected(modelData)
                                root.expanded = false
                            }
                        }
                    }
                }
            }
        }

        // --- Input Mode (Text Field) ---
        Rectangle {
            visible: root.inputType === "text"
            anchors { left: parent.left; leftMargin: Math.round(20 * localScale); right: parent.right; rightMargin: Math.round(12 * localScale); top: parent.top; bottom: parent.bottom; bottomMargin: Math.round(12 * localScale) }
            color: root._isInvalid ? Qt.rgba(248/255, 113/255, 113/255, 0.08) : Qt.rgba(1, 1, 1, 0.04)
            border.color: root._isInvalid ? Qt.rgba(248/255, 113/255, 113/255, 0.5) 
                        : (_txtInput.activeFocus ? Theme.active : Qt.rgba(1, 1, 1, 0.1))
            border.width: 1
            radius: Math.round(8 * localScale)
            Behavior on border.color { ColorAnimation { duration: Anim.fast } }
            Behavior on color { ColorAnimation { duration: Anim.fast } }

            TextInput {
                id: _txtInput
                anchors.fill: parent
                anchors.leftMargin: Math.round(10 * root.localScale)
                anchors.rightMargin: Math.round(10 * root.localScale)
                verticalAlignment: TextInput.AlignVCenter
                color: root._isInvalid ? "#f87171" : Theme.text
                font.pixelSize: Math.round(12 * root.localScale)
                font.family: "JetBrains Mono"
                selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                clip: true
                
                onTextChanged: root._validate(text)
                
                Keys.onReturnPressed: {
                    if (root._isInvalid) return // Block save if invalid
                    root.inputText = text
                    root.inputAccepted(text)
                    root.expanded = false
                }
                Keys.onEscapePressed: {
                    root.expanded = false
                }
            }
        }
    }
}
