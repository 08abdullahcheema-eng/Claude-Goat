import QtQuick
// Keycap hint.
Rectangle {
    property alias text: t.text
    implicitWidth: t.implicitWidth + Theme.px(10)
    implicitHeight: t.implicitHeight + Theme.px(4)
    radius: Theme.px(4)
    color: "transparent"
    border.width: 1
    border.color: Theme.line2
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Theme.px(2); radius: Theme.px(2); color: Theme.line2 }
    Text { id: t; anchors.centerIn: parent; font.family: Theme.mono; font.pixelSize: Theme.px(10); color: Theme.dim }
}
