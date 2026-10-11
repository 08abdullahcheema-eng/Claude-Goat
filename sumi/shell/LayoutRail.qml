import QtQuick
import Quickshell

// Rail: a hairline-thin strip across the top, text only.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "top"
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92) }
                GradientStop { position: 1; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.55) }
            }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.22) }
        }
        Row {
            anchors { left: parent.left; leftMargin: Theme.px(14); verticalCenter: parent.verticalCenter }
            spacing: Theme.px(12)
            Text {
                text: Theme.kanji; color: Theme.accent; font.family: Theme.head; font.pixelSize: Theme.px(14); anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }
            Text { text: Theme.label.toUpperCase(); color: Theme.fg; font.family: Theme.body; font.pixelSize: Theme.px(10.5); font.letterSpacing: Theme.px(2.2); anchors.verticalCenter: parent.verticalCenter }
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
        }
        ModClock { anchors.centerIn: parent; timeSize: Theme.px(11.5); timeFont: Theme.body }
        Row {
            anchors { right: parent.right; rightMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
            spacing: Theme.px(2)
            ModFan {} ModCpu {} ModAgent {} ModVol {} ModMic {} ModNet {} ModBt {} ModDnd {}
            KbdLayout { anchors.verticalCenter: parent.verticalCenter }
            ModBat {} ModPower {}
        }
    }
}
