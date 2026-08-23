import QtQuick
import "../../components"
import "../../"

Item {
    id: root
    property real localScale: 1.0

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + Math.round(40 * localScale)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: Math.round(32 * localScale)
            anchors.top: parent.top
            anchors.topMargin: Math.round(10 * localScale)

            SettingsGroup {
                localScale: root.localScale
                title: "Miscellaneous"
                description: "Advanced system integrations and external tooling."

                Item {
                    width: parent.width
                    height: 60
                    Text {
                        anchors.centerIn: parent
                        text: "More Options Coming Soon..."
                        font.pixelSize: Math.round(13 * root.localScale)
                        font.italic: true
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    }
                }
            }
        }
    }
}
