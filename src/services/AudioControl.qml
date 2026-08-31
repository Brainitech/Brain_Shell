import QtQuick
import Quickshell.Services.Pipewire
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0
    property bool fullyOpen: true

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    
    function reset() { switcher.reset() }

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    readonly property var sinkNodes: {
        var result = []
        var nodes = Pipewire.nodes.values
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n.audio !== null && !n.isStream && n.isSink)
                result.push(n)
        }
        return result
    }

    readonly property var sourceNodes: {
        var result = []
        var nodes = Pipewire.nodes.values
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i]
            if (n.audio !== null && !n.isStream && !n.isSink)
                result.push(n)
        }
        return result
    }

    function deviceName(node) {
        if (!node) return "Unknown"
        return node.nickname || node.description || node.name || "Unknown"
    }

    property string page: Popups.audioPage

    Connections {
        target: Popups
        function onAudioPageChanged() {
            root.page = Popups.audioPage
        }
    }

    Row {
        anchors.fill: parent
        spacing: 8

        // ── Page content ──────────────────────────────────────────────────────
        Item {
            id: contentArea
            width:  parent.width - switcher.implicitWidth - parent.spacing - 1 - parent.spacing
            height: parent.height
            clip:   true

            property int pageIdx: Math.max(0, ["output", "input", "mixer"].indexOf(root.page))

            // Output
            PopupPage {
                id: pageOutput
                readonly property int myIdx: 0
                property bool isCurrent: root.page === "output"
                property bool wasCurrent: false
                property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                onIsCurrentChanged: { 
                    if (isCurrent) wasCurrent = false;
                    else if (Anim.style === "none") wasCurrent = false;
                    else wasCurrent = true;
                }
                
                width: parent.width; height: parent.height
                
                property real targetY: {
                    if (Anim.style === "none") return 0;
                    if (isCurrent) return 0;
                    if (myIdx < contentArea.pageIdx) return -height * parallaxFactor;
                    return height;
                }
                
                y: targetY
                Behavior on y {
                    enabled: Anim.style !== "none" && Popups.audioOpen && root.fullyOpen
                    NumberAnimation { 
                        duration: Anim.slow; easing.type: Anim.outExpo
                        onRunningChanged: { if (!running && !pageOutput.isCurrent) pageOutput.wasCurrent = false; }
                    }
                }
                
                property real targetOpacity: {
                    if (Anim.style !== "parallax") return 1.0;
                    if (isCurrent) return 1.0;
                    return 0.0;
                }
                opacity: targetOpacity
                Behavior on opacity {
                    enabled: Anim.style === "parallax"
                    NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                }
                
                visible: isCurrent || wasCurrent

                ChannelColumn {
                    localScale: root.localScale
                    width:  parent.width
                    height: pageOutput.height - Math.round(16 * root.localScale)
                    label:  (root.sink && root.sink.ready) ? root.deviceName(root.sink) : "Output"
                    icon: {
                        if (!root.sink || !root.sink.ready)           return "󰕾"
                        if (root.sink.audio.muted)        return "󰖁"
                        if (root.sink.audio.volume > 0.6) return "󰕾"
                        if (root.sink.audio.volume > 0.2) return "󰖀"
                        return "󰕿"
                    }
                    value:  (root.sink && root.sink.ready) ? root.sink.audio.volume : 0
                    muted:  (root.sink && root.sink.audio) ? root.sink.audio.muted : false
                    active: (root.sink && root.sink.ready) || false
                    onVolumeChanged: function(v) {
                        if (root.sink && root.sink.ready) root.sink.audio.volume = v
                    }
                    onMuteToggled: {
                        if (root.sink && root.sink.ready)
                            root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
            }

            // Input
            PopupPage {
                id: pageInput
                readonly property int myIdx: 1
                property bool isCurrent: root.page === "input"
                property bool wasCurrent: false
                property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                onIsCurrentChanged: { 
                    if (isCurrent) wasCurrent = false;
                    else if (Anim.style === "none") wasCurrent = false;
                    else wasCurrent = true;
                }
                
                width: parent.width; height: parent.height
                
                property real targetY: {
                    if (Anim.style === "none") return 0;
                    if (isCurrent) return 0;
                    if (myIdx < contentArea.pageIdx) return -height * parallaxFactor;
                    return height;
                }
                
                y: targetY
                Behavior on y {
                    enabled: Anim.style !== "none" && Popups.audioOpen && root.fullyOpen
                    NumberAnimation { 
                        duration: Anim.slow; easing.type: Anim.outExpo
                        onRunningChanged: { if (!running && !pageInput.isCurrent) pageInput.wasCurrent = false; }
                    }
                }
                
                property real targetOpacity: {
                    if (Anim.style !== "parallax") return 1.0;
                    if (isCurrent) return 1.0;
                    return 0.0;
                }
                opacity: targetOpacity
                Behavior on opacity {
                    enabled: Anim.style === "parallax"
                    NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                }
                
                visible: isCurrent || wasCurrent

                ChannelColumn {
                    localScale: root.localScale
                    width:  parent.width
                    height: pageInput.height - Math.round(16 * root.localScale)
                    label:  (root.source && root.source.ready) ? root.deviceName(root.source) : "Input"
                    icon:   (root.source && root.source.audio && root.source.audio.muted) ? "󰍭" : "󰍬"
                    value:  (root.source && root.source.ready) ? root.source.audio.volume : 0
                    muted:  (root.source && root.source.audio) ? root.source.audio.muted : false
                    active: (root.source && root.source.ready) || false
                    onVolumeChanged: function(v) {
                        if (root.source && root.source.ready) root.source.audio.volume = v
                    }
                    onMuteToggled: {
                        if (root.source && root.source.ready)
                            root.source.audio.muted = !root.source.audio.muted
                    }
                }
            }

            // Mixer
            PopupPage {
                id: pageMixer
                readonly property int myIdx: 2
                property bool isCurrent: root.page === "mixer"
                property bool wasCurrent: false
                property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                onIsCurrentChanged: { 
                    if (isCurrent) wasCurrent = false;
                    else if (Anim.style === "none") wasCurrent = false;
                    else wasCurrent = true;
                }
                
                width: parent.width; height: parent.height
                
                property real targetY: {
                    if (Anim.style === "none") return 0;
                    if (isCurrent) return 0;
                    if (myIdx < contentArea.pageIdx) return -height * parallaxFactor;
                    return height;
                }
                
                y: targetY
                Behavior on y {
                    enabled: Anim.style !== "none" && Popups.audioOpen && root.fullyOpen
                    NumberAnimation { 
                        duration: Anim.slow; easing.type: Anim.outExpo
                        onRunningChanged: { if (!running && !pageMixer.isCurrent) pageMixer.wasCurrent = false; }
                    }
                }
                
                property real targetOpacity: {
                    if (Anim.style !== "parallax") return 1.0;
                    if (isCurrent) return 1.0;
                    return 0.0;
                }
                opacity: targetOpacity
                Behavior on opacity {
                    enabled: Anim.style === "parallax"
                    NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                }
                
                visible: isCurrent || wasCurrent

                SectionLabel { text: "Output Devices" }

                Repeater {
                    model: root.sinkNodes
                    delegate: DeviceRow {
                        localScale: root.localScale
                        width:     parent.width
                        label:     root.deviceName(modelData)
                        isDefault: (root.sink && root.sink.ready && modelData.name === root.sink.name) || false
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }

                Text {
                    visible:        root.sinkNodes.length === 0
                    text:           "No output devices"
                    color:          Theme.subtext
                    font.pixelSize: Math.round(11 * localScale)
                    leftPadding:    Math.round(10 * localScale)
                }

                Rectangle {
                    width: parent.width; height: 1
                    color: Theme.border
                }

                SectionLabel { localScale: root.localScale; text: "Input Devices" }

                Repeater {
                    model: root.sourceNodes
                    delegate: DeviceRow {
                        localScale: root.localScale
                        width:     parent.width
                        label:     root.deviceName(modelData)
                        isDefault: (root.source && root.source.ready && modelData.name === root.source.name) || false
                        onClicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }

                Text {
                    visible:        root.sourceNodes.length === 0
                    text:           "No input devices"
                    color:          Theme.subtext
                    font.pixelSize: Math.round(11 * localScale)
                    leftPadding:    Math.round(10 * localScale)
                }
            }
        }

        // Divider
        Rectangle {
            width: 1; height: parent.height
            color: Theme.border
        }

        // Tab switcher — right side
        TabSwitcher {
            id: switcher
            localScale: root.localScale
            orientation: "vertical"
            height: (parent.height - Math.round(17 * localScale))
            anchors.verticalCenter: parent.verticalCenter
            model: [
                { key: "output", icon: "󰕾" },
                { key: "input",  icon: "󰍬" },
                { key: "mixer",  icon: "󰾝" },
            ]
            currentPage: root.page
            onPageChanged: function(key) { Popups.audioPage = key }
        }
    }

    // ── ChannelColumn ─────────────────────────────────────────────────────────
    component ChannelColumn: Item {
        id: col

        property real localScale: 1.0
        property string label:  ""
        property string icon:   ""
        property real   value:  0.0
        property bool   muted:  false
        property bool   active: false

        readonly property int trackHeight: Math.round(160 * localScale)
        readonly property int barW:        Math.round(22 * localScale)
        readonly property int thumbD:      barW - Math.round(6 * localScale)

        signal volumeChanged(real value)
        signal muteToggled()

        // Expose size so PopupPage Flickable can measure content
        implicitWidth:  inner.implicitWidth
        implicitHeight: inner.implicitHeight

        readonly property string pctText:
            active ? Math.round(value * 100) + "%" : "--%"

        Column {
            id: inner
            anchors.centerIn: parent
            spacing: Math.round(8 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           col.pctText
                color:          col.muted ? Theme.subtext : Theme.text
                font.pixelSize: Math.round(13 * localScale)
                font.bold:      true
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW
                height: col.trackHeight

                Rectangle {
                    id: track
                    anchors.fill: parent
                    radius: width / 2
                    color:  Theme.border

                    // Fill bar
                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: Math.max(parent.radius * 2, parent.height * col.value)
                        radius: parent.radius
                        color:  col.muted ? Theme.subtext : Theme.active
                        Behavior on color  { ColorAnimation  { duration: Anim.mediumFast} }
                        Behavior on height { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic} }
                    }

                    // Thumb
                    Rectangle {
                        id: thumb
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:  col.thumbD
                        height: width
                        radius: width / 2
                        color:  col.muted ? Theme.subtext : Theme.text
                        y: {
                            var travel = track.height - height
                            return Math.max(0, Math.min(travel, (1.0 - col.value) * travel))
                        }
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                    }

                    // Drag to change volume
                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.SizeVerCursor
                        function calc(my) {
                            var travel = track.height - thumb.height
                            return Math.max(0.0, Math.min(1.0,
                                1.0 - (my - thumb.height / 2) / travel))
                        }
                        onPressed:         col.volumeChanged(calc(mouseY))
                        onPositionChanged: if (pressed) col.volumeChanged(calc(mouseY))
                    }

                    // Scroll wheel to change volume
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            var step = 0.05
                            var delta = event.angleDelta.y > 0 ? step : -step
                            col.volumeChanged(Math.max(0.0, Math.min(1.0, col.value + delta)))
                        }
                    }
                }
            }

            // Mute button
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  col.barW + Math.round(32 * localScale)
                height: Math.round(28 * localScale)
                radius: Math.round(Theme.cornerRadius * localScale)
                color:  col.muted
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                            : Theme.border
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }

                Row {
                    anchors.centerIn: parent
                    spacing: Math.round(5 * localScale)
                    Text {
                        text:           col.icon
                        font.pixelSize: Math.round(13 * localScale)
                        color:          col.muted ? Theme.active : Theme.icon
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                    }
                    Text {
                        text:           col.muted ? "Muted" : "Mute"
                        font.pixelSize: Math.round(11 * localScale)
                        color:          col.muted ? Theme.active : Theme.subtext
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    color: muteHov.hovered ? Theme.border : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                }
                HoverHandler { id: muteHov; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: col.muteToggled() }
            }

            // Label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:            col.label
                color:           Theme.subtext
                font.pixelSize:  Math.round(10 * localScale)
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                elide:           Text.ElideRight
                width:           col.barW + Math.round(60 * localScale)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ── SectionLabel ──────────────────────────────────────────────────────────
    component SectionLabel: Text {
        property real localScale: 1.0
        color:           Theme.subtext
        font.pixelSize:  Math.round(10 * localScale)
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
        leftPadding: Math.round(4 * localScale)
        topPadding:  Math.round(2 * localScale)
    }

    // ── DeviceRow ─────────────────────────────────────────────────────────────
    component DeviceRow: Item {
        id: row
        property real localScale: 1.0
        implicitHeight: Math.round(28 * localScale)

        property string label:     ""
        property bool   isDefault: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: Math.round((Theme.cornerRadius - 4) * localScale)
            color:  row.isDefault
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                        : (rowHov.hovered ? Theme.border : "transparent")
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }

        Row {
            anchors { left: parent.left; leftMargin: Math.round(8 * localScale); right: parent.right; rightMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(6 * localScale)

            Rectangle {
                width: Math.round(6 * localScale); height: Math.round(6 * localScale); radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: row.isDefault ? Theme.active : Theme.subtext
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
            }

            Text {
                text:           row.label
                color:          row.isDefault ? Theme.text : Theme.subtext
                font.pixelSize: Math.round(11 * localScale)
                elide:          Text.ElideRight
                width:          parent.width - Math.round(14 * localScale) - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
            }
        }

        HoverHandler { id: rowHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: row.clicked() }
    }
}
