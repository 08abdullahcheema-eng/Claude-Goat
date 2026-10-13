import QtQuick
// The theme's mark in the bar: the larp logo, or the theme's kanji as a badge
// (a hanko stamp for Ronin, a glowing glyph for the others). Click opens the launcher.
Item {
    id: lg
    property real size: Theme.px(22)
    readonly property string badge: Theme.p.badge ?? ""
    readonly property bool hanko: (Theme.p.barFx ?? "") === "hanko"
    implicitWidth: size + Theme.px(6)
    implicitHeight: size
    Image {
        visible: lg.badge === ""
        anchors.centerIn: parent
        width: lg.size; height: width
        source: "file://" + Theme.logo
        sourceSize: Qt.size(width * 2, height * 2)
        smooth: true
    }
    Rectangle {
        visible: lg.badge !== "" && lg.hanko
        anchors.centerIn: parent
        width: lg.size * 0.95; height: width
        radius: Theme.px(3)
        rotation: -4
        color: "transparent"
        border.width: Math.max(1.5, lg.size * 0.09)
        border.color: Theme.accent
    }
    Text {
        visible: lg.badge !== ""
        anchors.centerIn: parent
        text: lg.badge
        rotation: lg.hanko ? -4 : 0
        color: Theme.accent
        font.family: Theme.head === "Space Grotesk" || Theme.head === "Inter" ? Theme.serif : Theme.head
        font.pixelSize: lg.size * (lg.hanko ? 0.62 : 0.86)
        font.weight: Font.Bold
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
}
