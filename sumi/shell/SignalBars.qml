import QtQuick
// Four wifi strength bars.
Row {
    property int strength: 0     // 0..100
    property color color: Theme.fg
    readonly property int n: strength >= 75 ? 4 : strength >= 50 ? 3 : strength >= 25 ? 2 : strength > 0 ? 1 : 0
    spacing: Theme.px(2)
    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            width: Theme.px(3); height: Theme.px(4 + index * 3)
            anchors.bottom: parent.bottom
            radius: 1
            color: index < parent.n ? parent.color : Theme.line2
        }
    }
    height: Theme.px(13)
}
