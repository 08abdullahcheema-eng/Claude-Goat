import QtQuick
import Quickshell

// Kiri: one frosted capsule floating in the middle of the top edge.
// Workspace dots on the left, the time in the centre, a few icons and the battery ring on the right.
Scope {
    id: lay
    required property var screenRef
    property bool preview: false        // a copy drawn above the theme picker

    BarWindow {
        screen: lay.screenRef
        preview: lay.preview
        edge: "top"
        Rectangle {
            id: cap
            y: Theme.px(7)
            width: Math.min(parent.width - Theme.px(40), Math.max(Theme.px(620), parent.width * 0.4))
            x: (parent.width - width) / 2
            height: Theme.px(36)
            radius: height / 2
            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.52)
            border.width: 1
            border.color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.16)
            // a faint highlight along the top edge, like light on frosted glass
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: parent.radius; rightMargin: parent.radius; topMargin: 1 }
                height: 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.26) }
                    GradientStop { position: 1; color: "transparent" } }
            }

            Row {
                anchors { left: parent.left; leftMargin: Theme.px(8); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(10)
                Logo { anchors.verticalCenter: parent.verticalCenter; size: Theme.px(24) }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            }
            ModClock {
                anchors.centerIn: parent
                showDate: false
                activeStyle: "none"
                timeFont: Theme.head; timeSize: Theme.px(16); timeWeight: Font.Medium
            }
            Row {
                anchors { right: parent.right; rightMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                spacing: 0
                ModDnd { anchors.verticalCenter: parent.verticalCenter; visible: Ui.dnd }
                ModNet { anchors.verticalCenter: parent.verticalCenter; text: ""; pad: Theme.px(6) }
                ModBt { anchors.verticalCenter: parent.verticalCenter; text: ""; pad: Theme.px(6) }
                ModVol { anchors.verticalCenter: parent.verticalCenter; text: ""; pad: Theme.px(6) }
                ModBatRing {
                    anchors.verticalCenter: parent.verticalCenter
                    ringSize: Theme.px(20)
                    color: "transparent"
                }
            }
        }
    }
}
