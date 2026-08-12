import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../"

PopupWindow {
    id: root

    required property var anchorWindow

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int _padH: Math.round(5 * root.localScale)
    readonly property int _padV: Math.round(5 * root.localScale)
    readonly property int _optionWidth: Math.round(112 * root.localScale)

    implicitWidth:  _optionWidth + _padH * 2
    implicitHeight: optCol.implicitHeight + _padV * 2

    anchor.window:     root.anchorWindow
    anchor.gravity:    Edges.Bottom
    anchor.adjustment: PopupAdjustment.None
    anchor.rect: Qt.rect(
       ScreenRecService.popupTargetX + (ScreenRecService.popupTargetWidth / 2),
        Math.round(25 * root.localScale),
        root.implicitWidth,
        Math.round(Theme.notchHeight * root.localScale)
    )

    color:   "transparent"
    visible: ScreenRecService.openStrip !== ""

    Region {
        id: screenRecBlurReg
        item: recBg
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? screenRecBlurReg : null

    HoverHandler {
        onHoveredChanged: {
            if (hovered) ScreenRecService.keepStripOpen()
            else         ScreenRecService.scheduleStripClose()
        }
    }

    Rectangle {
        id: recBg
        anchors.fill: parent
        radius:       Math.round((Theme.cornerRadius - 6) * root.localScale)
        color:        Theme.background
        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
        border.width: 1
    }

    Column {
        id: optCol
        x:       _padH
        y:       _padV
        width: _optionWidth
        spacing: Math.round(2 * root.localScale)

        Repeater {
            model: ScreenRecService.openStrip === "capture"
                   ? ["screen", "window", "region"] : []
            delegate: OptionRow {
                required property string modelData
                required property int    index
                _icon:     ScreenRecService._captureIcons[modelData]  ?? ""
                _label:    ScreenRecService._captureLabels[modelData] ?? ""
                _selected: ScreenRecService.captureTarget === modelData
                onClicked: ScreenRecService.captureTarget = modelData
            }
        }

        Repeater {
            model: ScreenRecService.openStrip === "audio"
                   ? ["mic", "system", "none"] : []
            delegate: OptionRow {
                required property string modelData
                required property int    index

                readonly property var _icons:  ({ mic: "󰍬", system: "󰕾", none: "󰖁" })
                readonly property var _labels: ({ mic: "Mic", system: "System", none: "No Audio" })

                _icon:    _icons[modelData]  ?? ""
                _label:   _labels[modelData] ?? ""
                _selected: {
                    if (modelData === "none")   return !ScreenRecService.audioMic && !ScreenRecService.audioSystem
                    if (modelData === "mic")    return ScreenRecService.audioMic
                    return ScreenRecService.audioSystem
                }

                onClicked: {
                    if (modelData === "none") {
                        ScreenRecService.audioMic    = false
                        ScreenRecService.audioSystem = false
                    } else if (modelData === "mic") {
                        ScreenRecService.audioMic = !ScreenRecService.audioMic
                    } else {
                        ScreenRecService.audioSystem = !ScreenRecService.audioSystem
                    }
                }
            }
        }
    }

    // ── Option row — highlight only, no dots or checkboxes ────────────────────
    component OptionRow: Item {
        id: row

        property string _icon:     ""
        property string _label:    ""
        property bool   _selected: false

        signal clicked()

        implicitWidth:  root._optionWidth
        implicitHeight: Math.round(26 * root.localScale)

        Rectangle {
            anchors.fill: parent
            radius:       Math.round(5 * root.localScale)
            color: row._selected
                   ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                   : rH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) : "transparent"
            Behavior on color { ColorAnimation { duration: Anim.fast} }
        }

        Row {
            anchors.centerIn: parent
            spacing: Math.round(6 * root.localScale)

            Text {
                text:           row._icon
                font.pixelSize: Math.round(13 * root.localScale)
                color:          row._selected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Anim.fast} }
            }
            Text {
                id:             _lbl
                text:           row._label
                font.pixelSize: Math.round(12 * root.localScale)
                color:          row._selected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.70)
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Anim.fast} }
            }
        }

        HoverHandler { id: rH; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: row.clicked() }
    }
}
