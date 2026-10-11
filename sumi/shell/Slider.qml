import QtQuick
// Horizontal slider with value label.
Item {
    id: s
    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 50
    property color color: Theme.accent
    property string suffix: ""
    property bool enabled2: true
    signal moved(real value)
    implicitHeight: Theme.px(22)
    opacity: enabled2 ? 1 : 0.4

    readonly property real frac: (value - from) / Math.max(1e-6, to - from)
    Rectangle {
        id: track
        anchors { left: parent.left; right: lbl.left; rightMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
        height: Theme.px(6); radius: height / 2; color: Theme.line
        Rectangle { width: parent.width * s.frac; height: parent.height; radius: parent.radius; color: s.color }
        Rectangle {
            x: parent.width * s.frac - width / 2; anchors.verticalCenter: parent.verticalCenter
            width: Theme.px(14); height: width; radius: width / 2
            color: Theme.hi; border.width: Theme.px(2); border.color: s.color
        }
        MouseArea {
            anchors.fill: parent; anchors.margins: -Theme.px(8)
            enabled: s.enabled2
            cursorShape: Qt.PointingHandCursor
            function upd(mx) {
                const f = Math.max(0, Math.min(1, (mx - Theme.px(8)) / track.width));
                let v = s.from + f * (s.to - s.from);
                v = Math.round(v / s.step) * s.step;
                if (v !== s.value) { s.value = v; s.moved(v); }
            }
            onPressed: (m) => upd(m.x)
            onPositionChanged: (m) => { if (pressed) upd(m.x); }
        }
    }
    Text {
        id: lbl
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: Theme.px(46); horizontalAlignment: Text.AlignRight
        text: Math.round(s.value) + s.suffix
        color: Theme.hi; font.family: Theme.mono; font.pixelSize: Theme.fsm
    }
}
