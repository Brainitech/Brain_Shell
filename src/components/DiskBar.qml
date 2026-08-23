import QtQuick
import "../"

Item {
    id: root

    property string source:   ""
    property string mount:    ""
    property int    usedPct:  0
    property string usedStr:  "—"
    property string totalStr: "—"
    property real   localScale: 1.0

    property real _animPct: 0
    Behavior on _animPct { NumberAnimation { duration: 550; easing.type: Easing.OutCubic } }
    Component.onCompleted: _animPct = root.usedPct
    onUsedPctChanged: _animPct = root.usedPct

    implicitWidth:  Math.round(200 * localScale)
    implicitHeight: Math.round(40 * localScale)

    readonly property color barColor: {
        if (usedPct >= 90) return "#f38ba8"
        if (usedPct >= 75) return "#f5c47a"
        return Theme.active
    }

    // Mount label — left, fixed width
    Text {
        id: mountLabel
        anchors.left:           parent.left
        anchors.verticalCenter: barTrack.verticalCenter
        text:           root.mount
        font.pixelSize: Math.round(10 * localScale)
        color:          Theme.subtext
        width:          Math.round(32 * localScale)
        elide:          Text.ElideRight
    }

    // Bar track + fill
    Item {
        id: barTrack
        anchors.left:    mountLabel.right
        anchors.right:   pctLabel.left
        anchors.top:     parent.top
        anchors.topMargin:   Math.round(12 * localScale)
        anchors.leftMargin:  Math.round(6 * localScale)
        anchors.rightMargin: Math.round(6 * localScale)
        height: Math.round(6 * localScale)

        Rectangle {
            anchors.fill: parent
            radius:       height / 2
            color:        Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
            border.color: Theme.border
            border.width: 1
        }

        Rectangle {
            anchors.left:   parent.left
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          parent.width * Math.max(0, Math.min(1, root._animPct / 100))
            radius:         height / 2
            color:          root.barColor

            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    // Percentage — right of bar
    Text {
        id: pctLabel
        anchors.right:          parent.right
        anchors.verticalCenter: barTrack.verticalCenter
        text:           root.usedPct + "%"
        font.pixelSize: Math.round(10 * localScale)
        font.weight:    Font.Medium
        color:          root.barColor
        width:          Math.round(28 * localScale)
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: Anim.mediumSlow} }
    }

    // Size info — below the bar, aligned with bar
    Text {
        anchors.horizontalCenter: barTrack.horizontalCenter
        anchors.top:     barTrack.bottom
        anchors.topMargin: Math.round(4 * localScale)
        text:           root.usedStr + " / " + root.totalStr + "  ·  " + root.source
        font.pixelSize: Math.round(9 * localScale)
        color:          Theme.subtext
    }
}
