import QtQuick
import Quickshell

// Float (Unkai): one glass band floating over the top of the screen, with a thin dusk line
// along its lower edge. Italic serif workspaces and music on the left, the clock in the
// middle, CPU, RAM, controls and battery on the right.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "top"
        Rectangle {
            id: band
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.px(8)
            width: Math.min(parent.width - Theme.px(24), Theme.px(1500)); height: Theme.px(38)
            radius: height / 2
            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.52)
            border.width: 1
            border.color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.12)
            clip: true
            // dusk along the bottom edge: blue, peach, violet
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: parent.radius; rightMargin: parent.radius; bottomMargin: 1 }
                height: Theme.px(1.5)
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.25; color: Theme.blue }
                    GradientStop { position: 0.5; color: Theme.accent }
                    GradientStop { position: 0.75; color: Theme.violet }
                    GradientStop { position: 1.0; color: "transparent" } }
                opacity: 0.85
            }

            Row {
                anchors { left: parent.left; leftMargin: Theme.px(16); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(10)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.kanji.charAt(0); color: Theme.accent; font.family: Theme.serif; font.pixelSize: Theme.px(17); font.weight: Font.Bold
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
                }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
                Item { width: Theme.px(2); height: 1 }
                Sep { anchors.verticalCenter: parent.verticalCenter; visible: Media.active }
                ModMedia {
                    anchors.verticalCenter: parent.verticalCenter
                    fontFamily: Theme.head; fontSize: Theme.px(12.5); maxTitle: Theme.px(170)
                    coverSize: Theme.px(22); coverRadius: Theme.px(11); barW: Theme.px(52); barColor: Theme.accent
                }
            }

            Item {
                id: clock
                anchors.centerIn: parent
                width: crow.implicitWidth + Theme.px(20); height: parent.height
                readonly property var d: Dev.clockDate
                Row {
                    id: crow
                    anchors.centerIn: parent
                    spacing: Theme.px(9)
                    Text {
                        anchors.baseline: dt.baseline
                        text: Qt.formatTime(clock.d, "HH:mm")
                        color: Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(21); font.weight: Font.Light
                    }
                    Text {
                        id: dt
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: Theme.px(2)
                        text: clock.d.toLocaleDateString(Qt.locale("de_DE"), "dddd, d. MMMM")
                        color: Theme.accent2; font.family: Theme.head; font.italic: true; font.pixelSize: Theme.px(13)
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("calendar", clock.mapToItem(null, clock.width / 2, 0).x) }
            }

            Row {
                anchors { right: parent.right; rightMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(1)
                ModCpu { anchors.verticalCenter: parent.verticalCenter }
                ModMem { anchors.verticalCenter: parent.verticalCenter }
                ModFan { anchors.verticalCenter: parent.verticalCenter }
                ModAgent { anchors.verticalCenter: parent.verticalCenter }
                ModNet { anchors.verticalCenter: parent.verticalCenter }
                ModBt { anchors.verticalCenter: parent.verticalCenter }
                ModVol { anchors.verticalCenter: parent.verticalCenter }
                ModMic { anchors.verticalCenter: parent.verticalCenter }
                ModDnd { anchors.verticalCenter: parent.verticalCenter }
                KbdLayout { anchors.verticalCenter: parent.verticalCenter }
                ModBatRing { anchors.verticalCenter: parent.verticalCenter; showPct: true; ringSize: Theme.px(17) }
                ModPower { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
