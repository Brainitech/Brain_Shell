import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../"
import "../theme"

Item {
    id: root

    readonly property var pinned:  ClipboardService.pinned  ?? []
    readonly property var history: ClipboardService.entries ?? []

    // ── Search & filter state ──────────────────────────────────────────────────
    property string searchQuery: ""
    property string activeCategory: "all"  // "all" | "text" | "images" | "links"

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
                isImage:  false,
                isLink:   (pins[pi].text ?? pins[pi].preview ?? "").match(/^https?:\/\//) !== null
            })
        }

        // History section
        for (var hi = 0; hi < hist.length; hi++) {
            var e = hist[hi]
            if (!e.isImage && (lookup[e.preview] || lookup[(e.preview ?? "").trim()])) continue
            var preview = e.preview ?? ""
            result.push({
                kind:    "entry",
                id:      e.id,
                preview: preview,
                isImage: e.isImage ?? false,
                isLink:  !e.isImage && preview.match(/^https?:\/\//) !== null
            })
        }

        return result
    }

    // ── Filtered model (search + category) ─────────────────────────────────────
    readonly property var filteredModel: {
        if (root.searchQuery === "" && root.activeCategory === "all") return root.flatModel

        var q = root.searchQuery.toLowerCase().trim()
        var result = []
        for (var i = 0; i < root.flatModel.length; i++) {
            var item = root.flatModel[i]

            // Category filter
            if (root.activeCategory === "images" && !item.isImage) continue
            if (root.activeCategory === "links"  && !item.isLink)  continue
            if (root.activeCategory === "text"   && (item.isImage || item.isLink)) continue

            // Search filter
            if (q !== "") {
                var preview = (item.preview || "").toLowerCase()
                var text    = (item.text || "").toLowerCase()
                if (preview.indexOf(q) < 0 && text.indexOf(q) < 0) continue
            }

            result.push(item)
        }
        return result
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // ── Header ─────────────────────────────────────────────────────────────
        Item {
            width:  parent.width
            height: 44

            Text {
                anchors.centerIn: parent
                text:           "Clipboard"
                font.pixelSize: 14
                font.weight:    Font.DemiBold
                color:          Theme.text
            }

            // Clear unpinned history button
            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 }
                width:  clearRow.implicitWidth + 14
                height: 26; radius: 8
                color: clearH.hovered
                    ? Qt.rgba(248/255, 113/255, 113/255, 0.18)
                    : Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(248/255, 113/255, 113/255, clearH.hovered ? 0.38 : 0.12)
                border.width: 1
                Behavior on color        { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "󰩺"; font.pixelSize: 12
                        color: Qt.rgba(248/255, 113/255, 113/255, 0.80)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Clear"; font.pixelSize: 10
                        color: Qt.rgba(248/255, 113/255, 113/255, 0.80)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                HoverHandler { id: clearH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: ClipboardService.wipeHistory() }
            }
        }

        // ── Search bar ─────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 36
            color: Qt.rgba(1, 1, 1, 0.03)
            visible: root.flatModel.length > 0

            Row {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 6

                Text {
                    text: "󰍉"
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.25)
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: searchField
                    width: 140
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 11
                    color: Theme.text
                    activeFocusOnPress: true

                    Text {
                        visible: searchField.text === ""
                        text: "Search clipboard…"
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.18)
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    }

                    onTextChanged: root.searchQuery = text

                    // Clear button
                    Rectangle {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 18; height: 18; radius: 9
                        color: Qt.rgba(1, 1, 1, 0.06)
                        visible: searchField.text !== ""

                        Text {
                            anchors.centerIn: parent
                            text: "✕"; font.pixelSize: 8
                            color: Qt.rgba(1, 1, 1, 0.35)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.text = ""
                                root.searchQuery = ""
                            }
                        }
                    }
                }
            }

            // Category tabs
            Row {
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 3
                property var tabs: [
                    { key: "all",    label: "All" },
                    { key: "text",   label: "Text" },
                    { key: "images", label: "Images" },
                    { key: "links",  label: "Links" }
                ]

                Repeater {
                    model: parent.tabs
                    delegate: Rectangle {
                        required property var modelData
                        width: catLabel.implicitWidth + 14
                        height: 22
                        radius: 6
                        color: root.activeCategory === modelData.key
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                            : catHover.containsMouse
                                ? Qt.rgba(1, 1, 1, 0.06)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 10
                            color: root.activeCategory === modelData.key
                                ? Theme.active
                                : Qt.rgba(1, 1, 1, 0.45)
                        }

                        HoverHandler { id: catHover; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.activeCategory = modelData.key
                        }
                    }
                }
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
                        NumberAnimation { to: 0.15; duration: 500 }
                        NumberAnimation { to: 1.0;  duration: 500 }
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
                clip:           true
                spacing:        4
                boundsBehavior: Flickable.StopAtBounds
                visible:        root.filteredModel.length > 0
                model:          root.filteredModel
                cacheBuffer:    2000

                // Point to the detached scrollbar below
                ScrollBar.vertical: vbar

                // Smooth repositioning when items are removed
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
                }

                delegate: ClipRow {
                    required property var modelData
                    required property int index
                    width: mainList.width - 4

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
    property string entryId:     ""   // cliphist row id (for history) or storedId (for pinned)
    property string previewText: ""   // cliphist list preview string
    property string fullText:    ""   // full decoded text (pinned items only)
    property bool   isImage:     false
    property int    pinnedIndex: -1

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

    Behavior on height  { NumberAnimation { duration: 210; easing.type: Easing.InCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 1 }

        height: Math.max(row.isImage ? 66 : 42, innerRow.height + 18)
        radius: 9

        color: row.isPinned
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, rHov.hovered ? 0.10 : 0.055)
            : rHov.hovered ? Qt.rgba(1, 1, 1, 0.065) : Qt.rgba(1, 1, 1, 0.024)

        border.color: row.isPinned
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, rHov.hovered ? 0.30 : 0.18)
            : rHov.hovered ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(1, 1, 1, 0.065)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

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
                        sourceSize.width:  128
                        sourceSize.height: 128
                        opacity: thumbImg.status === Image.Ready ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
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
                opacity: rHov.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

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
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
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

    Behavior on color { ColorAnimation { duration: 110 } }

    // Subtle scale-up on hover
    transform: Scale {
        origin.x: 13; origin.y: 13
        xScale: aH.hovered ? 1.10 : 1.0
        yScale: aH.hovered ? 1.10 : 1.0
        Behavior on xScale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on yScale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
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
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    HoverHandler { id: aH; cursorShape: Qt.PointingHandCursor }
    MouseArea    { anchors.fill: parent; onClicked: ab.clicked() }
}
}
