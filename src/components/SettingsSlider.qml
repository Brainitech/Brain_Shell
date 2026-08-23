import QtQuick
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Slider Option"
    property string description: ""
    property real value: 0.5
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.1
    property bool showValue: true
    property string valueSuffix: ""
    property var formatValue: function(v) { 
        if (valueSuffix === "ms") {
            if (v >= 1000) return (v / 1000).toString() + "s"
            return v.toString() + "ms"
        }
        return (Math.round(v * 10) / 10).toString() + valueSuffix
    }
    
    property var defaultValue: undefined
    readonly property bool _hasDefault: defaultValue !== undefined
    readonly property bool _isDefault: _hasDefault && Math.abs(value - defaultValue) < 0.001

    width: parent ? parent.width : 400
    height: Math.round(description !== "" ? (44 * localScale) : (32 * localScale))

    Column {
        anchors {
            left: parent.left
            right: sliderArea.left
            rightMargin: Math.round(12 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: Math.round(4 * localScale)

        Text {
            text: root.text
            color: Theme.text
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

    // Slider Area
    Item {
        id: sliderArea
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: Math.round(160 * localScale)
        height: Math.round(24 * localScale)

        // Track
        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: root.showValue ? (parent.width - Math.round(50 * localScale)) : parent.width
            height: Math.round(6 * localScale)
            radius: height / 2
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)

            // Fill
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: {
                    var range = root.to - root.from
                    var percent = (root.value - root.from) / range
                    return Math.max(0, Math.min(track.width, track.width * percent))
                }
                radius: parent.radius
                color: Theme.active
                Behavior on width { 
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: Anim.superFast; easing.type: Anim.linear } 
                }
            }

            // Thumb
            Rectangle {
                width: Math.round(14 * localScale)
                height: Math.round(14 * localScale)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: {
                    var range = root.to - root.from
                    var percent = (root.value - root.from) / range
                    return Math.max(0, Math.min(track.width - width, (track.width - width) * percent))
                }
                color: "white"
                border.color: Qt.rgba(0, 0, 0, 0.2)
                border.width: 1
                Behavior on x { 
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: Anim.superFast; easing.type: Anim.linear } 
                }
            }

            // Drag area
            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.margins: Math.round(-10 * localScale)
                cursorShape: Qt.PointingHandCursor
                
                function updateValue(mouseX) {
                    var percent = Math.max(0.0, Math.min(1.0, mouseX / track.width))
                    var range = root.to - root.from
                    var rawVal = root.from + (percent * range)
                    var steps = Math.round(rawVal / root.stepSize)
                    var snapped = steps * root.stepSize
                    snapped = Math.max(root.from, Math.min(root.to, snapped))
                    root.value = snapped
                }

                onPressed: updateValue(mouseX)
                onPositionChanged: if (pressed) updateValue(mouseX)
            }
            
            // Scroll wheel support
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    var delta = event.angleDelta.y > 0 ? root.stepSize : -root.stepSize
                    var newVal = Math.max(root.from, Math.min(root.to, root.value + delta))
                    root.value = newVal
                }
            }
        }

        // Reset to default
        Rectangle {
            id: rstBtn
            visible: root._hasDefault && !root._isDefault
            width: Math.round(20 * localScale)
            height: Math.round(20 * localScale)
            radius: Math.round(6 * localScale)
            anchors { right: sliderArea.left; rightMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
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
                onClicked: root.value = root.defaultValue
            }
        }

        // Value text
        Text {
            id: valText
            visible: root.showValue
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: root.formatValue(root.value)
            color: Theme.subtext
            font.pixelSize: Math.round(12 * localScale)
            horizontalAlignment: Text.AlignRight
            width: Math.round(45 * localScale)
        }
    }
}
