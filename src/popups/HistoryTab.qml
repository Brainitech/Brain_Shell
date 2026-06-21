import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../"

Item {
    id: root
    property real localScale: 1.0

    readonly property var pinned:  ClipboardService.pinned  ?? []
    readonly property var history: ClipboardService.entries ?? []

    // ── Flat unified model ─────────────────────────────────────────────────────
    readonly property var flatModel: {
        var result = []
        var pins   = root.pinned
        var hist   = root.history

        // Build fast-lookup set of pinned previews/texts for O(1) dedup
        var lookup = {}
        for (var k = 0; k < pins.length; k++) {
            if (pins[k].preview) lookup[pins[k].preview] = true
            if (pins[k].text)    lookup[pins[k].text]    = true
        }

        // Pinned section (top)
        for (var pi = 0; pi < pins.length; pi++) {
            result.push({
                kind:     "pinned",
                text:     pins[pi].text    ?? "",
                preview:  pins[pi].preview ?? pins[pi].text ?? "",
                storedId: pins[pi].id      ?? "",
                pinIndex: pi,
                isImage:  false
            })
        }

        // History section
        for (var hi = 0; hi < hist.length; hi++) {
            var e = hist[hi]
            if (!e.isImage && (lookup[e.preview] || lookup[(e.preview ?? "").trim()])) continue
            result.push({
                kind:    "entry",
                id:      e.id,
                preview: e.preview,
                isImage: e.isImage ?? false
            })
        }

        return result
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // ── Header ─────────────────────────────────────────────────────────────
        Item {
            width:  parent.width
            height: Math.round(44 * localScale)

            Text {
                anchors.centerIn: parent
                text:           "Clipboard"
                font.pixelSize: Math.round(14 * localScale)
                font.weight:    Font.DemiBold
                color:          Theme.text
            }

            // Clear unpinned history button
            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Math.round(4 * localScale) }
                width:  clearRow.implicitWidth + Math.round(14 * localScale)
                height: Math.round(26 * localScale); radius: Math.round(8 * localScale)
                color: clearH.hovered
                    ? Qt.rgba(248/255, 113/255, 113/255, 0.18)
                    : Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(248/255, 113/255, 113/255, clearH.hovered ? 0.38 : 0.12)
                border.width: 1
                Behavior on color        { ColorAnimation { duration: Anim.mediumFast} }
                Behavior on border.color { ColorAnimation { duration: Anim.mediumFast} }

                Row {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: Math.round(5 * localScale)
                    Text {
                        text: "󰩺"; font.pixelSize: Math.round(12 * localScale)
                        color: Qt.rgba(248/255, 113/255, 113/255, 0.80)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Clear"; font.pixelSize: Math.round(10 * localScale)
                        color: Qt.rgba(248/255, 113/255, 113/255, 0.80)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                HoverHandler { id: clearH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: ClipboardService.wipeHistory() }
            }
        }

        // Divider
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }

        // ── Content ────────────────────────────────────────────────────────────
        Item {
            width:  parent.width
            height: parent.height - 45

            // Loading state
            Column {
                anchors.centerIn: parent; spacing: 10
                visible: (ClipboardService.loading ?? false)
                         && root.history.length === 0
                         && root.pinned.length  === 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "○"; font.pixelSize: 22; color: Theme.active
                    SequentialAnimation on opacity {
                        running: parent.visible; loops: Animation.Infinite
                        NumberAnimation { to: 0.15; duration: Anim.verySlow}
                        NumberAnimation { to: 1.0;  duration: Anim.verySlow}
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Loading…"; font.pixelSize: 12; color: Qt.rgba(1,1,1,0.25)
                }
            }

            // Empty state
            Column {
                anchors.centerIn: parent; spacing: 10
                visible: !(ClipboardService.loading ?? false)
                         && root.history.length === 0
                         && root.pinned.length  === 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰅍"; font.pixelSize: 32; color: Qt.rgba(1,1,1,0.08)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Clipboard is empty"; font.pixelSize: 12; color: Qt.rgba(1,1,1,0.20)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Copy something to get started"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.13)
                }
            }

            // ── List ───────────────────────────────────────────────────────────
            ListView {
                id: mainList
                anchors {
                    fill:         parent
                    topMargin:    6
                    leftMargin:   2
                    rightMargin:  12
                    bottomMargin: 4
                }
                clip:                true
                spacing:             4
                boundsBehavior:      Flickable.StopAtBounds
                visible:             root.flatModel.length > 0
                model:               root.flatModel
                focus:               true
                keyNavigationEnabled: true
                keyNavigationWraps:  true

                // Point to the detached scrollbar below
                ScrollBar.vertical: vbar

                // Smooth repositioning when items are removed
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: Anim.normal; easing.type: Anim.outCubic}
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        Popups.clipboardOpen = false
                        event.accepted = true
                        return
                    }
                    var item = root.flatModel[mainList.currentIndex]
                    if (!item) return
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (item.kind === "pinned")
                            ClipboardService.copyText(item.text || item.preview)
                        else
                            ClipboardService.copyEntry(item.id)
                        Popups.clipboardOpen = false
                        event.accepted = true
                    } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                        if (mainList.currentItem) mainList.currentItem.deleteRow()
                        event.accepted = true
                    } else if (event.key === Qt.Key_P) {
                        if (mainList.currentItem && !item.isImage) mainList.currentItem.togglePin()
                        event.accepted = true
                    }
                }

                delegate: ClipRow {
                    required property var modelData
                    required property int index
                    width: mainList.width - 4

                    highlighted: index === mainList.currentIndex
                    isPinned:    modelData.kind === "pinned"
                    entryId:     modelData.kind === "pinned" ? (modelData.storedId ?? "") : (modelData.id ?? "")
                    previewText: modelData.preview ?? ""
                    fullText:    modelData.kind === "pinned" ? (modelData.text ?? "") : ""
                    isImage:     modelData.isImage ?? false
                    pinnedIndex: modelData.kind === "pinned" ? modelData.pinIndex : -1
                }
            }

            // ── External Scrollbar placed at the absolute edge ────────────────
            ScrollBar {
                id: vbar
                anchors {
                    top:    parent.top
                    bottom: parent.bottom
                    right:  parent.right
                    topMargin: 6
                    bottomMargin: 4
                }
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth:  4
                    implicitHeight: 10
                    radius:         2
                    color:          Qt.rgba(1, 1, 1, 0.22)
                }
            }
        }
    }


// ── ClipRow ────────────────────────────────────────────────────────────────────
component ClipRow: Item {
    id: row


    property bool   isPinned:    false
    property bool   highlighted: false
    property string entryId:     ""   // cliphist row id (for history) or storedId (for pinned)
    property string previewText: ""   // cliphist list preview string
    property string fullText:    ""   // full decoded text (pinned items only)
    property bool   isImage:     false
    property int    pinnedIndex: -1

    function deleteRow() {
        row._removing = true
        delayedAction.isPinned    = row.isPinned
        delayedAction.pinnedIndex = row.pinnedIndex
        delayedAction.entryId     = row.entryId
        delayedAction.restart()
    }

    function togglePin() {
        if (row.isPinned) ClipboardService.unpinAt(row.pinnedIndex)
        else              ClipboardService.pinEntry(row.entryId, row.previewText)
    }

    // Image preview: decoded to a temp file per entry id
    property string _imgPath: ""

    property var _imgDecodeProc: Process {
        command: []
        running: false
        onRunningChanged: {
            if (!running) row._imgPath = "/tmp/clip_prev_" + row.entryId
        }
    }

    Component.onCompleted: {
        if (row.isImage && row.entryId !== "") {
            _imgDecodeProc.command = ["bash", "-c",
                "cliphist decode '" + row.entryId + "' > '/tmp/clip_prev_" + row.entryId + "' 2>/dev/null"]
            _imgDecodeProc.running = true
        }
    }

    // Collapse height to zero for animated removal
    property bool _removing: false

    height:  _removing ? 0 : (card.height + 2)
    opacity: _removing ? 0 : 1
    clip: true

    Behavior on height  { NumberAnimation { duration: Anim.normal; easing.type: Anim.inCubic} }
    Behavior on opacity { NumberAnimation { duration: Anim.mediumFast} }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 1 }

        height: Math.max(row.isImage ? 66 : 42, innerRow.height + 18)
        radius: 9

        color: row.isPinned
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, (rHov.hovered || row.highlighted) ? 0.10 : 0.055)
            : (rHov.hovered || row.highlighted) ? Qt.rgba(1, 1, 1, 0.065) : Qt.rgba(1, 1, 1, 0.024)

        border.color: row.isPinned
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, (rHov.hovered || row.highlighted) ? 0.30 : 0.18)
            : row.highlighted
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.50)
                : rHov.hovered ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(1, 1, 1, 0.065)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: Anim.color} }
        Behavior on border.color { ColorAnimation { duration: Anim.color} }

        // ── Inner layout ──────────────────────────────────────────────────────
        Row {
            id: innerRow
            anchors {
                left:           parent.left;  leftMargin:  10
                right:          parent.right; rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            spacing: 8
            height: Math.max(row.isImage ? 56 : 22, previewLabel.implicitHeight)

            // Left: image thumbnail -OR- text glyph
            Item {
                id:     leftSlot
                width:  row.isImage ? 74 : 18
                height: innerRow.height
                anchors.verticalCenter: parent.verticalCenter

                // ── Image thumbnail ───────────────────────────────────────────
                Rectangle {
                    visible: row.isImage
                    anchors {
                        left: parent.left; top: parent.top
                        bottom: parent.bottom; right: parent.right
                        rightMargin: 6
                    }
                    radius: 6
                    color:  Qt.rgba(1, 1, 1, 0.05)
                    clip:   true

                    Image {
                        id: thumbImg
                        anchors.fill: parent
                        source:   row._imgPath !== "" ? ("file://" + row._imgPath) : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth:   true
                        asynchronous: true
                        opacity: thumbImg.status === Image.Ready ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Anim.mediumSlow; easing.type: Anim.outCubic} }
                    }

                    // Placeholder while loading / no path yet
                    Item {
                        anchors.fill: parent
                        visible: thumbImg.status !== Image.Ready

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(1,1,1,0.03)
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "🖼"; font.pixelSize: 18; opacity: 0.22
                        }
                    }
                }

                // ── Text icon glyph ───────────────────────────────────────────
                Text {
                    visible: !row.isImage
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "󰅍"
                    font.pixelSize: 12
                    color:          Qt.rgba(1, 1, 1, 0.22)
                }
            }

            // ── Preview text / image label ─────────────────────────────────────
            Text {
                id: previewLabel
                width: innerRow.width
                       - leftSlot.width
                       - actionsRow.implicitWidth
                       - innerRow.spacing * 2
                       - 2
                anchors.verticalCenter: parent.verticalCenter

                text: row.isImage ? "Image" : row.previewText
                font.pixelSize:   12
                color: row.isImage
                    ? Qt.rgba(1, 1, 1, 0.28)
                    : Qt.rgba(1, 1, 1, 0.78)
                font.italic:      row.isImage
                elide:            Text.ElideRight
                maximumLineCount: 2
                wrapMode:         Text.WordWrap
            }

            // ── Action buttons (appear on hover) ──────────────────────────────
            Row {
                id: actionsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                opacity: rHov.hovered || row.highlighted ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Anim.mediumFast} }

                // Copy
                ActionBtn {
                    icon: "󰆏"
                    onClicked: {
                        if (row.isPinned) ClipboardService.copyText(row.fullText || row.previewText)
                        else             ClipboardService.copyEntry(row.entryId)
                        Popups.clipboardOpen = false
                    }
                }

                // Pin / Unpin  (hidden for image entries — images can't be pinned)
                ActionBtn {
                    icon:    row.isPinned ? "󰐄" : "󰐃"
                    active:  row.isPinned
                    visible: !row.isImage
                    onClicked: {
                        if (row.isPinned)
                            ClipboardService.unpinAt(row.pinnedIndex)
                        else
                            ClipboardService.pinEntry(row.entryId, row.previewText)
                    }
                }

                // Delete / fully remove
                ActionBtn {
                    icon:   "󰩺"
                    danger: true
                    onClicked: {
                        row._removing = true
                        delayedAction.isPinned    = row.isPinned
                        delayedAction.pinnedIndex = row.pinnedIndex
                        delayedAction.entryId     = row.entryId
                        delayedAction.restart()
                    }
                }
            }
        }

        // ── Pin badge: small circle in the top-right corner ───────────────────
        Rectangle {
            visible: row.isPinned
            anchors { top: parent.top; right: parent.right; topMargin: 5; rightMargin: 4 }
            width: 18; height: 18; radius: 8
            color: Theme.active

            Text {
                anchors.centerIn: parent
                text: " 󰐃"; font.pixelSize: 8; font.weight: Font.Bold
                color: Qt.rgba(0, 0, 0, 0.65)
            }

            scale: row.isPinned ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Anim.outBack} }
        }
    }

    HoverHandler { id: rHov }

    // ── Double-tap: copy + close popup + paste into active field ───────────────
    TapHandler {
        onDoubleTapped: {
            if (row.isPinned) ClipboardService.copyText(row.fullText || row.previewText)
            else             ClipboardService.copyEntry(row.entryId)
            Popups.clipboardOpen = false
            ClipboardService.typeFromClipboard()
        }
    }

    // Fires after the collapse animation completes so the list reflows smoothly
    Timer {
        id: delayedAction
        property bool   isPinned:    false
        property int    pinnedIndex: -1
        property string entryId:     ""
        interval: 220
        onTriggered: {
            if (isPinned) {
                // Remove from pin list
                if (pinnedIndex >= 0) ClipboardService.unpinAt(pinnedIndex)
                if (entryId !== "") ClipboardService.deleteEntry(entryId)
            } else {
                if (entryId !== "") ClipboardService.deleteEntry(entryId)
            }
        }
    }
}


// ── ActionBtn ──────────────────────────────────────────────────────────────────
component ActionBtn: Rectangle {
    id: ab
    property string icon:   ""
    property bool   active: false
    property bool   danger: false
    signal clicked()

    width: 26; height: 26; radius: 7

    color: ab.danger
        ? (aH.hovered ? Qt.rgba(248/255, 113/255, 113/255, 0.20) : "transparent")
        : ab.active
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
            : (aH.hovered ? Qt.rgba(1, 1, 1, 0.11) : "transparent")

    Behavior on color { ColorAnimation { duration: Anim.color} }

    // Subtle scale-up on hover
    transform: Scale {
        origin.x: 13; origin.y: 13
        xScale: aH.hovered ? 1.10 : 1.0
        yScale: aH.hovered ? 1.10 : 1.0
        Behavior on xScale { NumberAnimation { duration: Anim.color; easing.type: Anim.outCubic} }
        Behavior on yScale { NumberAnimation { duration: Anim.color; easing.type: Anim.outCubic} }
    }

    Text {
        anchors.centerIn: parent
        text:           ab.icon
        font.pixelSize: 13
        color: ab.danger
            ? (aH.hovered ? "#f87171" : Qt.rgba(248/255, 113/255, 113/255, 0.50))
            : ab.active
                ? Theme.active
                : (aH.hovered ? Qt.rgba(1, 1, 1, 0.88) : Qt.rgba(1, 1, 1, 0.38))
        Behavior on color { ColorAnimation { duration: Anim.color} }
    }

    HoverHandler { id: aH; cursorShape: Qt.PointingHandCursor }
    MouseArea    { anchors.fill: parent; onClicked: ab.clicked() }
}
}
