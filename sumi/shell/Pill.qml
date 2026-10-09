import QtQuick

// Clickable bar item: icon and/or text with hover + active state.
Rectangle {
    id: root
    property string icon: ""
    property color iconColor: Theme.fg
    property string text: ""
    property color textColor: Theme.dim
    property bool active: false
    property real iconSize: Theme.px(15)
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitHeight: Theme.px(26)
    implicitWidth: row.implicitWidth + Theme.px(16)
    radius: Theme.px(5)
    color: active ? Theme.bg2 : (ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent")
    border.width: active ? 1 : 0
    border.color: Theme.line2

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(6)
        Icon {
            visible: root.icon !== ""
            name: root.icon
            color: root.iconColor
            size: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.text !== ""
            text: root.text
            color: root.textColor
            font.family: Theme.mono
            font.pixelSize: Theme.fsm
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => root.clicked(m)
        onWheel: (w) => root.wheel(w)
    }
}
