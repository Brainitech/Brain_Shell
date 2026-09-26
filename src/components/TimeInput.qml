import QtQuick
import "../"

// TimeInput — reusable HH:MM input
// Props : hours (int, readonly), minutes (int, readonly), minuteStep (int, default 1)
// Call  : initialize(h, m) to push values from outside

Item {
    id: root

    property real localScale: 1.0

    readonly property int hours:   hVal
    readonly property int minutes: mVal

    property int minuteStep: 1
    property int hVal: 0
    property int mVal: 0

    function initialize(h, m) { hVal = h; mVal = m }

    function zp(n)  { var s = "" + n; return s.length < 2 ? "0" + s : s }
    function incH() { hVal = hVal >= 23 ? 0  : hVal + 1 }
    function decH() { hVal = hVal <= 0  ? 23 : hVal - 1 }
    function incM() { var n = mVal + minuteStep; mVal = n > 59 ? 0 : n }
    function decM() { var n = mVal - minuteStep; mVal = n < 0 ? Math.floor(59 / minuteStep) * minuteStep : n }

    implicitWidth:  _row.implicitWidth
    implicitHeight: _row.implicitHeight

    Row {
        id: _row
        spacing: Math.round(8 * localScale)

        // ══ HOURS ═════════════════════════════════════════════════════════════
        Column {
            spacing: Math.round(2 * localScale)
            width: Math.round(36 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "HH"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Medium
                font.family: "JetBrains Mono"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: hUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: hUpH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.incH() }
            }

            Item {
                width: parent.width; height: Math.round(30 * localScale)

                Text {
                    anchors.centerIn: parent
                    text: root.zp(root.hVal)
                    font.pixelSize: Math.round(20 * localScale); font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(ev) {
                        ev.accepted = true
                        if (ev.angleDelta.y > 0) root.incH()
                        else                     root.decH()
                    }
                }
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: hDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: hDnH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.decH() }
            }
        }

        // Colon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(8 * localScale)
            text: ":"
            font.pixelSize: Math.round(22 * localScale); font.weight: Font.Bold
            font.family: "JetBrains Mono"
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
        }

        // ══ MINUTES ═══════════════════════════════════════════════════════════
        Column {
            spacing: Math.round(2 * localScale)
            width: Math.round(36 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MM"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Medium
                font.family: "JetBrains Mono"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: mUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: mUpH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.incM() }
            }

            Item {
                width: parent.width; height: Math.round(30 * localScale)

                Text {
                    anchors.centerIn: parent
                    text: root.zp(root.mVal)
                    font.pixelSize: Math.round(20 * localScale); font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(ev) {
                        ev.accepted = true
                        if (ev.angleDelta.y > 0) root.incM()
                        else                     root.decM()
                    }
                }
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: mDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: mDnH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.decM() }
            }
        }
    }
}
