import QtQuick
// Small labelled number tile.
Rectangle {
    id: st
    property alias label: l.text
    property alias value: v.text
    property color valueColor: Theme.hi
    implicitHeight: Theme.px(54)
    radius: Theme.px(6)
    color: Theme.bg
    border.width: 1; border.color: Theme.line
    Column {
        anchors { left: parent.left; leftMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
        spacing: Theme.px(3)
        Label { id: l; font.pixelSize: Theme.px(8.5) }
        Text { id: v; color: st.valueColor; font.family: Theme.mono; font.pixelSize: Theme.px(16) }
    }
}
