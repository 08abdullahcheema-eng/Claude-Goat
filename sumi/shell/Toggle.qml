import QtQuick
// On/off switch.
Rectangle {
    id: t
    property bool checked: false
    signal toggled(bool value)
    width: Theme.px(36); height: Theme.px(20); radius: height / 2
    color: checked ? Theme.accent : Theme.line2
    Behavior on color { ColorAnimation { duration: 120 } }
    Rectangle {
        width: parent.height - Theme.px(6); height: width; radius: width / 2
        y: Theme.px(3)
        x: t.checked ? parent.width - width - Theme.px(3) : Theme.px(3)
        Behavior on x { NumberAnimation { duration: 120 } }
        color: t.checked ? Theme.onAccent : Theme.dim
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled(!t.checked) }
}
