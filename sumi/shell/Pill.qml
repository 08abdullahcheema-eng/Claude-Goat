import QtQuick

// Clickable bar item used by every bar layout: icon and/or text, hover and open state.
// Layouts restyle it through the properties below (text labels instead of icons, fonts, shapes).
Rectangle {
    id: root
    property string icon: ""
    property color iconColor: Theme.fg
    property string text: ""
    property color textColor: Theme.dim
    property string label: ""                 // e.g. "CPU", shown instead of the icon in label mode
    property color labelColor: Theme.mute
    property bool labels: BarStyle.labels      // true: text labels, no icons
    property bool active: false
    property real iconSize: Theme.px(15)
    property string fontFamily: BarStyle.fontFamily
    property int fontSize: BarStyle.fontSize
    property real letterSpacing: BarStyle.letterSpacing
    property bool caps: BarStyle.caps
    property bool bold: false
    property string activeStyle: BarStyle.activeStyle   // "box" | "line" | "fill" | "none"
    property real pad: BarStyle.pad
    signal clicked(var mouse)
    signal wheel(var wheel)

    // screen x of this item's centre (bar windows span the whole screen width)
    function centerX() { return mapToItem(null, width / 2, 0).x; }

    implicitHeight: BarStyle.itemH
    implicitWidth: Math.max(labels ? 0 : Theme.px(32), row.implicitWidth + pad * 2)
    radius: BarStyle.radius
    color: active && activeStyle === "box" ? Theme.bg2
         : active && activeStyle === "fill" ? Theme.accent
         : (ma.containsMouse && activeStyle !== "none" ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent")
    border.width: active && activeStyle === "box" ? 1 : 0
    border.color: Theme.line2
    Behavior on color { ColorAnimation { duration: 120 } }

    // accent mark under an open panel's item
    Rectangle {
        visible: root.active && (root.activeStyle === "box" || root.activeStyle === "line")
        width: root.activeStyle === "line" ? parent.width - Theme.px(8) : Theme.px(10)
        height: 2; radius: 1
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
            visible: root.icon !== "" && !root.labels
            name: root.icon
            color: root.active && root.activeStyle === "fill" ? Theme.onAccent : root.iconColor
            size: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.labels && root.label !== ""
            text: root.caps ? root.label.toUpperCase() : root.label
            color: root.active && root.activeStyle === "fill" ? Theme.onAccent : root.labelColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.letterSpacing: root.letterSpacing
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.text !== ""
            text: root.caps ? root.text.toUpperCase() : root.text
            color: root.active && root.activeStyle === "fill" ? Theme.onAccent : root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.letterSpacing: root.letterSpacing
            font.weight: root.bold ? Font.DemiBold : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => root.clicked(m)
        onWheel: (w) => root.wheel(w)
    }
}
