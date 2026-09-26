import QtQuick
import "../../"

Text {
    id: clock
    property real localScale: 1.0

    text: Qt.formatDateTime(new Date(), "hh:mm")
    color: clockHov.hovered ? Theme.active : Theme.text
    Behavior on color { ColorAnimation { duration: Anim.color} }
    font.bold: true
    anchors.verticalCenter: parent.verticalCenter
    font.pixelSize: Math.round(16 * localScale)

    property int formatMode: 0

    state: "time"
    states: [
        State {
            name: "time"
            PropertyChanges { target: clock; formatMode: 0 }
        },
        State {
            name: "timeSeconds"
            PropertyChanges { target: clock; formatMode: 1 }
        },
        State {
            name: "date"
            PropertyChanges { target: clock; formatMode: 2 }
        }
    ]

    HoverHandler { id: clockHov }
    MouseArea {
        anchors.fill: parent
        acceptedButtons:     Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (clock.state === "time" || clock.state === "timeSeconds") {
                    clock.state = "date"
                } else if (clock.state === "date" || clock.state === "timeSeconds") {
                    clock.state = "time"
                }
            } else {
                if (clock.state === "time"|| clock.state === "date") {
                    clock.state = "timeSeconds"
                } else if (clock.state === "timeSeconds" || clock.state === "date") {
                    clock.state = "time"
                }
            }
            updateText()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateText()
    }

    function updateText() {
        let now = new Date()
        let tf = PrefsService.use24HourTime ? "hh:mm" : "h:mm ap"
        let tfs = PrefsService.use24HourTime ? "hh:mm:ss" : "h:mm:ss ap"
        switch(formatMode) {
            case 0:
                text = Qt.formatDateTime(now, tf)
                break
            case 1:
                text = Qt.formatDateTime(now, tfs)
                break
            case 2:
                text = Qt.formatDateTime(now, "dd-MM-yyyy")
                break
        }
    }
    
    Connections {
        target: PrefsService
        function onUse24HourTimeChanged() { updateText() }
    }

    Component.onCompleted: updateText()
}
