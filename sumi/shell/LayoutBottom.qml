import QtQuick
import Quickshell

// Bottom: one solid, square bar along the bottom edge, everything in capitals.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "bottom"
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.97)
            // fire: embers glowing up from the top edge
            Rectangle {
                visible: (Theme.p.barFx ?? "") === "fire"
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: parent.height * 0.7
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
                    GradientStop { position: 1; color: "transparent" } }
            }
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: Theme.px(2.5); color: Theme.accent }

            Row {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: Theme.px(2.5) }
                spacing: Theme.px(6)
                // name block, opens the launcher
                Rectangle {
                    height: parent.height; width: nm.implicitWidth + Theme.px(28)
                    color: nmMa.containsMouse ? Theme.accent2 : Theme.accent
                    Text { id: nm; anchors.centerIn: parent; text: Theme.kanji + "  " + Theme.label.toUpperCase(); color: Theme.onAccent; font.family: Theme.head; font.pixelSize: Theme.px(19); font.letterSpacing: Theme.px(1.5) }
                    MouseArea { id: nmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
                }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; h: parent.height; screenName: lay.screenRef.name }
            }
            Row {
                anchors { right: clockBlock.left; rightMargin: Theme.px(10); verticalCenter: parent.verticalCenter; verticalCenterOffset: Theme.px(1) }
                spacing: Theme.px(4)
                ModFan {} ModCpu {} ModAgent {}
                Rectangle { width: 1; height: Theme.px(18); color: Theme.line2; anchors.verticalCenter: parent.verticalCenter }
                ModNet {} ModBt {} ModVol {} ModMic {} ModDnd {}
                KbdLayout { anchors.verticalCenter: parent.verticalCenter }
                ModBat {} ModPower {}
            }
            Rectangle {
                id: clockBlock
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: Theme.px(2.5) }
                width: ck.implicitWidth + Theme.px(24)
                color: Ui.panel === "calendar" ? Theme.accent : (ckMa.containsMouse ? Theme.line : Theme.bg2)
                readonly property var d: Dev.clockDate
                Text { id: ck; anchors.centerIn: parent; text: Qt.formatTime(parent.d, "HH:mm"); color: Ui.panel === "calendar" ? Theme.onAccent : Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(24); font.letterSpacing: Theme.px(1) }
                MouseArea { id: ckMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("calendar", mapToItem(null, width / 2, 0).x) }
            }
        }
    }
}
