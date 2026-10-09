import QtQuick
// Text button, primary = filled accent.
Rectangle {
    id: b
    property alias text: lbl.text
    property bool primary: false
    property bool enabled2: true
    signal clicked()
    implicitWidth: lbl.implicitWidth + Theme.px(24)
    implicitHeight: Theme.px(28)
    radius: Theme.px(5)
    color: primary ? (ma.containsMouse ? Theme.accent2 : Theme.accent) : (ma.containsMouse ? Theme.bg2 : "transparent")
    border.width: primary ? 0 : 1
    border.color: Theme.line2
    opacity: enabled2 ? 1 : 0.5
    Text { id: lbl; anchors.centerIn: parent; color: b.primary ? Theme.onAccent : Theme.dim; font.family: Theme.mono; font.pixelSize: Theme.fsm }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (b.enabled2) b.clicked() }
}
