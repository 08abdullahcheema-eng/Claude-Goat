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
    // screen x of this pill's centre (the bar window sits Theme.px(10) in from the screen edge)
    function centerX() { return mapToItem(null, width / 2, 0).x + Theme.px(10); }
    signal wheel(var wheel)

    implicitHeight: Theme.barH - Theme.px(8)
    implicitWidth: Math.max(Theme.px(32), row.implicitWidth + Theme.px(20))
    radius: Theme.px(8)
    color: active ? Theme.bg2 : (ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent")
    border.width: active ? 1 : 0
    border.color: Theme.line2
    Behavior on color { ColorAnimation { duration: 120 } }

    // small accent dot under an open panel's icon
    Rectangle {
        visible: root.active
        width: Theme.px(10); height: 2; radius: 1
        color: Theme.accent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
    }

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
        onPressed: if (Theme.demo) console.log("pill pressed", root.icon)
        onClicked: (m) => root.clicked(m)
        onWheel: (w) => root.wheel(w)
    }
}
