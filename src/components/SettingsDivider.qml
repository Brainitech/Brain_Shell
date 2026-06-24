import QtQuick

Rectangle {
    property real localScale: 1.0
    width: parent ? parent.width : 400
    height: Math.max(1, Math.round(1 * localScale))
    color: Qt.rgba(1, 1, 1, 0.05)
}
