import QtQuick
// Segmented choice row. model: [[value, label, sub?], ...]
Row {
    id: seg
    property var model: []
    property var current
    property color accent: Theme.accent
    property bool enabled2: true
    signal picked(var value)
    spacing: Theme.px(6)
    opacity: enabled2 ? 1 : 0.4
    readonly property real cellW: (width - spacing * (model.length - 1)) / Math.max(1, model.length)
    Repeater {
        model: seg.model
        delegate: Rectangle {
            required property var modelData
            readonly property bool on: seg.current === modelData[0]
            width: seg.cellW
            height: modelData.length > 2 && modelData[2] ? Theme.px(52) : Theme.px(30)
            radius: Theme.px(6)
            color: on ? Qt.rgba(seg.accent.r, seg.accent.g, seg.accent.b, 0.12) : (ma.containsMouse ? Theme.bg2 : Theme.bg)
            border.width: on ? Theme.px(1.5) : 1
            border.color: on ? seg.accent : Theme.line
            Column {
                anchors.centerIn: parent
                spacing: Theme.px(1)
                Text {
                    visible: modelData.length > 2 && !!modelData[2]
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData[2] || ""
                    font.family: Theme.serif; font.weight: Font.Bold; font.pixelSize: Theme.px(16)
                    color: parent.parent.on ? seg.accent : Theme.dim
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData[1]
                    font.family: Theme.mono; font.pixelSize: Theme.px(10.5)
                    color: parent.parent.on ? Theme.hi : Theme.dim
                }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; enabled: seg.enabled2; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(parent.modelData[0]) }
        }
    }
}
