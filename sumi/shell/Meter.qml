import QtQuick
// Usage meter with title, percent and reset line.
Column {
    id: m
    property string title: ""
    property real pct: 0
    property string sub: ""
    property color barColor: Theme.accent
    spacing: Theme.px(6)
    Item {
        width: parent.width; height: Theme.px(20)
        T { text: m.title; anchors.bottom: parent.bottom }
        T { text: Math.round(m.pct) + "%"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors { right: parent.right; bottom: parent.bottom } }
    }
    Rectangle {
        width: parent.width; height: Theme.px(9); radius: height / 2; color: Theme.line
        Rectangle { width: parent.width * Math.min(1, m.pct / 100); height: parent.height; radius: parent.radius; color: m.pct >= 90 ? Theme.accent2 : m.barColor }
    }
    T { text: m.sub; color: Theme.mute; font.pixelSize: Theme.px(10.5) }
}
