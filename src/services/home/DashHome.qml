import QtQuick
import "../"
import "../components"

// Dashboard Home tab — layout only.
//
//  ┌──────────────┬───────────────────────────┬──────────────┐
//  │ ProfileCard  │  ClockCard                │              │
//  ├──────────────┤                           │ QuickSettings│
//  │ CalendarCard │  PlayerCard               │ (brightness  │
//  │              │                           │  + toggles)  │
//  └──────────────┴───────────────────────────┴──────────────┘

Item {
    id: root

    readonly property int colW:   210
    readonly property int gap:      8
    readonly property int profileH: 160
    readonly property int clockH:   220

    // ── Left column ───────────────────────────────────────────────────────────
    Item {
        id: leftCol
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW

        ProfileCard {
            id: profileCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.profileH
            avatarPath: "/home/brainiac/.curr_wall_static"
        }
        CalendarCard {
            anchors {
                left: parent.left; right: parent.right
                top: profileCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }

    // ── Right column — QuickSettings fills full height ────────────────────────
    QuickSettings {
        id: rightCard
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: root.gap }
        width: root.colW
    }

    // ── Center column ─────────────────────────────────────────────────────────
    Item {
        id: centerCol
        anchors {
            left:  leftCol.right;  leftMargin:  root.gap
            right: rightCard.left; rightMargin: root.gap
            top:   parent.top;     bottom:      parent.bottom
            topMargin: root.gap;
        }

        ClockCard {
            id: clockCard
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.clockH
        }
        PlayerCard {
            anchors {
                left:   parent.left;  right:  parent.right
                top:    clockCard.bottom; topMargin: root.gap
                bottom: parent.bottom
            }
        }
    }
}
