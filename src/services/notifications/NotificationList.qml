import QtQuick
import Quickshell.Services.Notifications
import "../"
import "../../"

// ─────────────────────────────────────────────────────────────
// NotificationList — content panel for NotificationsPopup
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    property real localScale: 1.0

    width:  Math.round(360 * root.localScale)

    // Total height: header + list area (or empty state)
    height: header.height
            + (NotificationService.count > 0 ? listArea.height : emptyState.height)

    // ── Header ─────────────────────────────────────────────────
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 44

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; leftMargin: 16; verticalCenter: parent.verticalCenter }
            text:           "Notifications"
            color:          Theme.text
            font.pixelSize: 14
            font.bold:      true
        }

        // Clear-all — only visible when there are notifications
        Item {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width:   clearLabel.width + 16
            height:  26
            visible: NotificationService.count > 0

            Rectangle {
                anchors.fill: parent
                radius:       13
                color:        clearHover.containsMouse ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.10) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.color} }
            }
            Text {
                id:               clearLabel
                anchors.centerIn: parent
                text:             "Clear all"
                color:            Theme.subtext
                font.pixelSize:   12
            }
            HoverHandler { id: clearHover }
            TapHandler   { onTapped: NotificationService.dismissAll() }
        }
    }

    // Divider — only when list is non-empty
    Rectangle {
        id: divider
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        height:  1
        color:   Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
        visible: NotificationService.count > 0
    }

    // ── Scrollable list ─────────────────────────────────────────
    Item {
        id:      listArea
        anchors { top: divider.bottom; left: parent.left; right: parent.right }
        // Clamp to maxListHeight — ListView scrolls inside
        height:  Math.min(contentList.contentHeight, maxListHeight)
        visible: NotificationService.count > 0

        readonly property int maxListHeight: Math.round(440 * root.localScale)

        ListView {
            id:             contentList
            anchors.fill:   parent
            model:          NotificationService.list
            clip:           true
            spacing:        Math.round(1 * root.localScale)
            boundsBehavior: Flickable.StopAtBounds

            delegate: NotificationCard {
                required property var modelData
                width:        ListView.view.width
                notification: modelData
            }
        }

        // Fade overlay when clipped
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height:  Math.round(28 * root.localScale)
            visible: contentList.contentHeight > listArea.maxListHeight
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0.09, 0.11, 0.13, 1.0) }
            }
        }
    }

    // ── Empty state ─────────────────────────────────────────────
    Item {
        id:      emptyState
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        height:  Math.round(80 * root.localScale)
        visible: NotificationService.count === 0

        Column {
            anchors.centerIn: parent
            spacing:          Math.round(6 * root.localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "󰂚"
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                font.pixelSize: Math.round(28 * root.localScale)
                font.family:    Theme.iconFont
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "No notifications"
                color:          Theme.subtext
                font.pixelSize: Math.round(12 * root.localScale)
            }
        }
    }

    // ── NotificationCard ── inline component ────────────────────
    component NotificationCard: Item {
        id: card

        // notification is required — guard every access with ?. and ?? fallback
        required property var notification

        // Urgency accent color — guard against undefined notification/urgency
        readonly property color urgencyColor: {
            if (!notification) return Theme.active
            switch (notification.urgency) {
                case NotificationUrgency.Critical: return "#e06c75"
                case NotificationUrgency.Low:      return Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                default:                           return Theme.active
            }
        }

        height: cardRow.height + Math.round(20 * root.localScale)

        // Hover background
        Rectangle {
            anchors.fill: parent
            color:        cardHover.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }

        // Left urgency accent bar
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width:   Math.round(3 * root.localScale)
            color:   card.urgencyColor
            opacity: 0.85
        }

        // Content row
        Row {
            id: cardRow
            anchors {
                left:        parent.left; leftMargin:  Math.round(12 * root.localScale)
                right:       parent.right; rightMargin:  Math.round(8 * root.localScale)
                top:         parent.top;   topMargin:   Math.round(10 * root.localScale)
            }
            spacing: Math.round(10 * root.localScale)
            height:  Math.max(iconArea.height, textCol.implicitHeight)

            // App icon
            Item {
                id:     iconArea
                width:  Math.round(32 * root.localScale)
                height: Math.round(32 * root.localScale)

                Image {
                    id:        iconImg
                    anchors.fill: parent
                    source: {
                        var ic = card.notification?.appIcon ?? ""
                        if (ic === "") return ""
                        if (ic.startsWith("/")) return "file://" + ic
                        return "image://icon/" + ic
                    }
                    fillMode:          Image.PreserveAspectFit
                    smooth:            true
                    visible:           status === Image.Ready
                    sourceSize.width:  Math.round(32 * root.localScale)
                    sourceSize.height: Math.round(32 * root.localScale)
                }

                // Letter fallback
                Rectangle {
                    anchors.fill: parent
                    radius:       width / 2
                    color:        Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                    visible:      iconImg.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text:           (card.notification?.appName ?? "?").charAt(0).toUpperCase()
                        color:          Theme.text
                        font.pixelSize: Math.round(14 * root.localScale)
                        font.bold:      true
                    }
                }
            }

            // Text column
            Column {
                id:     textCol
                // Leave room for dismiss button
                width: cardRow.width - iconArea.width - dismissBtn.width - (cardRow.spacing * 2)
                spacing: Math.round(3 * root.localScale)

                // App name
                Text {
                    width:          parent.width
                    text:           card.notification?.appName ?? ""
                    color:          Theme.subtext
                    font.pixelSize: Math.round(11 * root.localScale)
                    elide:          Text.ElideRight
                    visible:        text !== ""
                }

                // Summary
                Text {
                    width:            parent.width
                    text:             card.notification?.summary ?? ""
                    color:            Theme.text
                    font.pixelSize:   Math.round(13 * root.localScale)
                    font.bold:        true
                    wrapMode:         Text.WordWrap
                    maximumLineCount: 2
                    elide:            Text.ElideRight
                    visible:          text !== ""
                }

                // Body
                Text {
                    width:            parent.width
                    text:             card.notification?.body ?? ""
                    color:            Theme.subtext
                    font.pixelSize:   Math.round(12 * root.localScale)
                    wrapMode:         Text.WordWrap
                    maximumLineCount: 3
                    elide:            Text.ElideRight
                    textFormat:       Text.StyledText
                    visible:          text !== ""
                }

                // Action buttons
                Row {
                    spacing: Math.round(6 * root.localScale)
                    visible: (card.notification?.actions?.length ?? 0) > 0

                    Repeater {
                        model: card.notification?.actions ?? []
                        delegate: Item {
                            required property var modelData
                            width:  actionLbl.width + Math.round(20 * root.localScale)
                            height: Math.round(22 * root.localScale)

                            Rectangle {
                                anchors.fill: parent
                                radius:       Math.round(3 * root.localScale)
                                color:        actHover.containsMouse
                                              ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.15)
                                              : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.07)
                                Behavior on color { ColorAnimation { duration: Anim.fast} }
                            }
                            Text {
                                id:               actionLbl
                                anchors.centerIn: parent
                                text:             modelData?.text ?? ""
                                color:            Theme.text
                                font.pixelSize:   Math.round(11 * root.localScale)
                            }
                            HoverHandler { id: actHover }
                            TapHandler   { onTapped: modelData?.invoke() }
                        }
                    }
                }
            }

            // Dismiss ✕
            Item {
                id:     dismissBtn
                width:  Math.round(24 * root.localScale)
                height: Math.round(24 * root.localScale)

                Rectangle {
                    anchors.fill: parent
                    radius:       width / 2
                    color:        xHover.containsMouse ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                }
                Text {
                    anchors.centerIn: parent
                    text:             "✕"
                    color:            Theme.subtext
                    font.pixelSize:   Math.round(10 * root.localScale)
                }
                HoverHandler { id: xHover }
                TapHandler   { onTapped: card.notification?.dismiss() }
            }
        }

        HoverHandler { id: cardHover }
    }
}
