import QtQuick
import QtQuick.Shapes
import Quickshell

// Horizon (Dune): a thin horizon line along the bottom of the screen. Above it the sun travels
// along its arc through the day (the moon at night), the clock sits under it. Roman workspaces
// and music on the left, CPU, RAM, controls and battery on the right.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        id: bw
        screen: lay.screenRef
        edge: "bottom"
        readonly property real lineY: Theme.px(28)
        readonly property real bandY: lineY + Theme.px(2)
        readonly property real r: Theme.px(21)

        // the desert fades into the bar
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.45; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.62) }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9) }
            }
        }
        // horizon line, fading out at both ends
        Rectangle {
            x: Theme.px(26); y: bw.lineY
            width: parent.width - Theme.px(52); height: 1
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.18; color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.42) }
                GradientStop { position: 0.82; color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.42) }
                GradientStop { position: 1.0; color: "transparent" } }
        }

        // sun (or moon) on its arc above the line
        Item {
            id: sky
            anchors.horizontalCenter: parent.horizontalCenter
            y: bw.lineY - bw.r - Theme.px(6)
            width: bw.r * 2 + Theme.px(24); height: bw.r + Theme.px(6)
            readonly property real cx: width / 2
            readonly property real cy: height
            readonly property real f: Sky.night ? Sky.nightPart : Sky.day
            readonly property real a: Math.PI * (1 - f)
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.34)
                    strokeWidth: 1
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [2, 4]
                    fillColor: "transparent"
                    startX: sky.cx - bw.r; startY: sky.cy
                    PathArc { x: sky.cx + bw.r; y: sky.cy; radiusX: bw.r; radiusY: bw.r }
                }
            }
            Rectangle {   // glow
                x: sky.cx + bw.r * Math.cos(sky.a) - width / 2; y: sky.cy - bw.r * Math.sin(sky.a) - height / 2
                width: Theme.px(16); height: width; radius: width / 2
                color: Sky.night ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.14) : Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.28)
            }
            Rectangle {   // body
                x: sky.cx + bw.r * Math.cos(sky.a) - width / 2; y: sky.cy - bw.r * Math.sin(sky.a) - height / 2
                width: Theme.px(8); height: width; radius: width / 2
                color: Sky.night ? "transparent" : Theme.accent2
                border.width: Sky.night ? 1.5 : 0
                border.color: Theme.fg
            }
        }

        // clock under the sun
        Item {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            y: bw.bandY
            width: t1.implicitWidth + Theme.px(20); height: parent.height - bw.bandY
            readonly property var d: Dev.clockDate
            Text {
                id: t1
                anchors.centerIn: parent
                textFormat: Text.StyledText
                text: Qt.formatTime(clock.d, "HH") + "<font color='" + Theme.accent2 + "'>:</font>" + Qt.formatTime(clock.d, "mm")
                color: Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(20); font.letterSpacing: Theme.px(3.5)
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("calendar", clock.mapToItem(null, clock.width / 2, 0).x) }
        }

        Row {
            x: Theme.px(26); y: bw.bandY
            height: parent.height - bw.bandY
            spacing: Theme.px(10)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.kanji; color: Theme.accent; font.family: Theme.serif; font.pixelSize: Theme.px(16); font.weight: Font.Bold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            Sep { anchors.verticalCenter: parent.verticalCenter; visible: Media.active }
            ModMedia {
                anchors.verticalCenter: parent.verticalCenter
                fontFamily: Theme.head; fontSize: Theme.px(11.5); maxTitle: Theme.px(170)
                coverSize: Theme.px(18); coverRadius: Theme.px(9); barW: Theme.px(56); barColor: Theme.accent
            }
        }
        Row {
            anchors { right: parent.right; rightMargin: Theme.px(22) }
            y: bw.bandY
            height: parent.height - bw.bandY
            spacing: Theme.px(1)
            ModCpu { anchors.verticalCenter: parent.verticalCenter }
            ModMem { anchors.verticalCenter: parent.verticalCenter }
            ModFan { anchors.verticalCenter: parent.verticalCenter }
            ModAgent { anchors.verticalCenter: parent.verticalCenter }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            ModNet { anchors.verticalCenter: parent.verticalCenter }
            ModBt { anchors.verticalCenter: parent.verticalCenter }
            ModVol { anchors.verticalCenter: parent.verticalCenter }
            ModMic { anchors.verticalCenter: parent.verticalCenter }
            ModDnd { anchors.verticalCenter: parent.verticalCenter }
            KbdLayout { anchors.verticalCenter: parent.verticalCenter }
            ModBat { anchors.verticalCenter: parent.verticalCenter }
            ModPower { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
