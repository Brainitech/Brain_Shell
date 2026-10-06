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
    property string inputType: "button" // "button", "options", "text"
    
    property var options: []
    property string selectedOption: ""
    property string inputText: ""
    property string placeholder: ""
    
    property string validateAs: ""
    property bool _isInvalid: false
    
    property string swatchColor: ""
    property var defaultValue: undefined
    readonly property bool _hasDefault: defaultValue !== undefined
    readonly property bool _isDefault: _hasDefault && 
        (inputType === "options" ? selectedOption === defaultValue : 
         (inputType === "text" ? inputText === defaultValue : false))

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
        var safePath = expandedTxt.replace(/'/g, "'\\''")
        
        if (root.validateAs === "image") {
            _valProc.command = ["bash", "-c", "if [ -f '" + safePath + "' ] && [[ '" + safePath.toLowerCase() + "' =~ \\.(png|jpg|jpeg|svg|webp|bmp)$ ]]; then echo 1; else echo 0; fi"]
        } else {
            var flag = root.validateAs === "dir" ? "-d" : "-f"
            _valProc.command = ["bash", "-c", "if [ " + flag + " '" + safePath + "' ]; then echo 1; else echo 0; fi"]
        }
        
        _valProc.running = false
        _valProc.running = true
    }
    
    property bool expanded: false
    onExpandedChanged: {
        if (expanded) {
            if (Popups.activeExpandedButton && Popups.activeExpandedButton !== root) {
                Popups.activeExpandedButton.expanded = false
            }
            Popups.activeExpandedButton = root
        } else if (Popups.activeExpandedButton === root) {
            Popups.activeExpandedButton = null
        }
    }

    signal clicked()
    signal optionSelected(string opt)
    signal inputAccepted(string text)

    readonly property bool _hasExpandable: root.inputType !== "button"

    width: parent ? parent.width : 400
    height: baseRow.height + (expanded ? expandArea.implicitHeight : 0)
    clip: true
    
    Behavior on height { NumberAnimation { duration: Anim.fast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }


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
                color: root.destructive ? Theme.error : Theme.text
                font.pixelSize: Math.round(13 * localScale)
            }

            Text {
                visible: root.description !== ""
                text: root.description
                color: Theme.subtext
                font.pixelSize: Math.round(11 * localScale)
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }



        // Reset to default
        Rectangle {
            id: rstBtn
            visible: root._hasDefault && !root._isDefault
            width: Math.round(22 * localScale)
            height: Math.round(22 * localScale)
            radius: Math.round(6 * localScale)
            anchors { right: actionBtn.left; rightMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
            color: rstH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09) : "transparent"
            Behavior on color { ColorAnimation { duration: Anim.fast } }
            
            Text { 
                anchors.centerIn: parent
                text: "↺"
                font.pixelSize: Math.round(13 * localScale)
                color: rstH.hovered ? Theme.active : Theme.subtext 
            }
            
            HoverHandler { id: rstH; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.inputType === "options") {
                        root.optionSelected(root.defaultValue)
                    } else if (root.inputType === "text") {
                        root.inputText = root.defaultValue
                        root.inputAccepted(root.defaultValue)
                        root._validate(root.inputText)
                    }
                }
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
            width: root.swatchColor !== "" ? Math.round(40 * localScale) : (btnLabel.implicitWidth + Math.round(24 * localScale))
            height: Math.round(24 * localScale)
            radius: Math.round(6 * localScale)
            color: root.swatchColor !== "" ? root.swatchColor : (root.expanded ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15) 
                 : ((actionMouse.hovered ? (root.destructive ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)) : (root.destructive ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.05) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)))))
            Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
            
            border.color: root.swatchColor !== "" ? Theme.border : (root.expanded ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4)
                        : (root.destructive ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.5) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)))
            border.width: 1

            HoverHandler { id: actionMouse; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
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

            Text {
                id: btnLabel
                visible: root.swatchColor === ""
                anchors.centerIn: parent
                text: root._hasExpandable ? (root.expanded ? "Close" : root.buttonText) : root.buttonText
                color: root.expanded ? Theme.active : (root.destructive ? Theme.error : Theme.text)
                font.pixelSize: Math.round(11 * localScale)
                font.weight: Font.Medium
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
                                          : (_pHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04))
                        border.color: isSelected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
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
            
            HoverHandler { id: txtHover; cursorShape: Qt.IBeamCursor }

            color: root._isInvalid ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08) : (txtHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04))
            border.color: root._isInvalid ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.5) 
                        : (_txtInput.activeFocus ? Theme.active : (txtHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)))
            border.width: 1
            radius: Math.round(8 * localScale)
            Behavior on border.color { ColorAnimation { duration: Anim.fast } }
            Behavior on color { ColorAnimation { duration: Anim.fast } }

            Text {
                visible: _txtInput.text === "" && root.placeholder !== ""
                anchors.fill: parent
                anchors.leftMargin: Math.round(10 * root.localScale)
                anchors.rightMargin: Math.round(10 * root.localScale)
                verticalAlignment: Text.AlignVCenter
                text: root.placeholder
                color: Theme.subtext
                font.pixelSize: Math.round(12 * root.localScale)
                font.family: "JetBrains Mono"
            }

            TextInput {
                id: _txtInput
                anchors.fill: parent
                anchors.leftMargin: Math.round(10 * root.localScale)
                anchors.rightMargin: Math.round(10 * root.localScale)
                verticalAlignment: TextInput.AlignVCenter
                color: root._isInvalid ? Theme.error : Theme.text
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
                onActiveFocusChanged: Popups.isInputFocused = activeFocus

                Keys.onEscapePressed: function(event) {
                    event.accepted = true
                    text = root.inputText
                    root.expanded = false
                    root.forceActiveFocus()
                }
            }
        }
    }
}
