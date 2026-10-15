import QtQuick
import Quickshell
import QtQuick.Effects

// Shinkai: one glass pill floating at the bottom, like the dashboard of a small submarine.
// Mark and workspaces on the left, time and date in the middle, a few icons and the battery ring on the right.
Scope {
    id: lay
    required property var screenRef
    property bool preview: false        // a copy drawn above the theme picker

    BarWindow {
        screen: lay.screenRef
        preview: lay.preview
        edge: "bottom"
        // a soft glow of the accent around the pill
        MultiEffect {
            anchors.fill: cap
            source: cap
            shadowEnabled: true; shadowColor: Theme.accent; shadowBlur: 1.0; shadowOpacity: 0.28
        }
        Rectangle {
            id: cap
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(9) }
            height: Theme.px(42)
            width: Math.min(parent.width - Theme.px(40), Math.max(Theme.px(700), parent.width * 0.46))
            radius: height / 2
            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)

            Row {
                anchors { left: parent.left; leftMargin: Theme.px(8); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(10)
                Logo { anchors.verticalCenter: parent.verticalCenter; size: Theme.px(26) }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            }
            ModClock {
                anchors.centerIn: parent
                activeStyle: "none"
                timeFont: Theme.head; timeSize: Theme.px(16); timeWeight: Font.Medium
                fontFamily: "Inter"; fontSize: Theme.px(12.5)
            }
            Row {
                anchors { right: parent.right; rightMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                spacing: 0
                ModDnd { anchors.verticalCenter: parent.verticalCenter; visible: Ui.dnd }
                ModNet { anchors.verticalCenter: parent.verticalCenter; text: ""; pad: Theme.px(6) }
                ModBt { anchors.verticalCenter: parent.verticalCenter; text: ""; pad: Theme.px(6) }
                ModVol { anchors.verticalCenter: parent.verticalCenter; text: ""; pad: Theme.px(6) }
                ModBatRing { anchors.verticalCenter: parent.verticalCenter; ringSize: Theme.px(20); color: "transparent" }
            }
        }
    }
}
