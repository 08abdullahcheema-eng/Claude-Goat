import QtQuick
import Quickshell

// Capsule: one long frosted capsule across the top. Workspaces as dots, music on the left,
// the clock in the middle, CPU curve and a battery ring on the right.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "top"
        Rectangle {
            id: cap
            x: Theme.px(10); y: Theme.px(6)
            width: parent.width - Theme.px(20); height: Theme.px(38)
            radius: height / 2
            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.58)
            border.width: 1
            border.color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.14)
            // a faint highlight along the top edge, like light on glass
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: parent.radius; rightMargin: parent.radius; topMargin: 1 }
                height: 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.22) }
                    GradientStop { position: 1; color: "transparent" } }
            }

            Row {
                anchors { left: parent.left; leftMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(6)
                Logo { anchors.verticalCenter: parent.verticalCenter; size: Theme.px(22) }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
                Item { width: Theme.px(4); height: 1 }
                Sep { anchors.verticalCenter: parent.verticalCenter; visible: Media.active }
                ModMedia { anchors.verticalCenter: parent.verticalCenter; coverRadius: Theme.px(6); maxTitle: Theme.px(170) }
            }
            ModClock {
                anchors.centerIn: parent
                timeFont: Theme.head; timeSize: Theme.px(16); timeWeight: Font.DemiBold
            }
            Row {
                anchors { right: parent.right; rightMargin: Theme.px(5); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(2)
                ModCpuCurve { anchors.verticalCenter: parent.verticalCenter; curveColor: Theme.accent; textColor: Theme.dim }
                ModFan { anchors.verticalCenter: parent.verticalCenter }
                ModAgent { anchors.verticalCenter: parent.verticalCenter }
                ModNet { anchors.verticalCenter: parent.verticalCenter }
                ModBt { anchors.verticalCenter: parent.verticalCenter }
                ModVol { anchors.verticalCenter: parent.verticalCenter }
                ModMic { anchors.verticalCenter: parent.verticalCenter }
                ModDnd { anchors.verticalCenter: parent.verticalCenter }
                KbdLayout { anchors.verticalCenter: parent.verticalCenter }
                ModBatRing {
                    anchors.verticalCenter: parent.verticalCenter
                    showPct: true; ringSize: Theme.px(18)
                    color: active ? Theme.bg2 : Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.08)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.px(30); height: width; radius: width / 2
                    color: pm.containsMouse ? Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.16) : Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.08)
                    Icon { anchors.centerIn: parent; name: "power"; color: Theme.accent2; size: Theme.px(14) }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("power") }
                }
            }
        }
    }
}
