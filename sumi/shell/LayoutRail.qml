import QtQuick
import Quickshell

// Hagane: a bare rail across the top with one hairline under it. Text only:
// the kanji and name, numbered workspaces with an accent underline, time and date in the middle,
// uppercase labels with values on the right.
Scope {
    id: lay
    required property var screenRef
    property bool preview: false        // a copy drawn above the theme picker

    BarWindow {
        screen: lay.screenRef
        preview: lay.preview
        edge: "top"
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.55) }
        }
        Row {
            anchors { left: parent.left; leftMargin: Theme.px(16); verticalCenter: parent.verticalCenter }
            spacing: Theme.px(10)
            Text {
                text: Theme.kanji; color: Theme.accent; font.family: Theme.serif; font.pixelSize: Theme.px(14); anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; anchors.margins: -Theme.px(4); cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }
            Text { text: Theme.label.toUpperCase(); color: Theme.hi; font.family: Theme.body; font.pixelSize: Theme.px(10.5); font.weight: Font.DemiBold; font.letterSpacing: Theme.px(1.2); anchors.verticalCenter: parent.verticalCenter }
            Item { width: Theme.px(30); height: 1 }
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
        }
        ModClock { anchors.centerIn: parent; timeSize: Theme.px(12); timeFont: Theme.body; activeStyle: "line" }
        Row {
            anchors { right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
            spacing: Theme.px(6)
            ModDnd { visible: Ui.dnd }
            ModCpu { text: Sys.cpu + "%"; textColor: Theme.hi }
            ModMem { label: "mem"; text: Sys.memPct + "%"; textColor: Theme.hi }
            ModNet { text: Net.kind === "ethernet" ? "eth" : Net.kind === "wifi" ? "wifi" : "off"; textColor: Theme.hi; label: "net" }
            ModVol { textColor: Theme.hi }
            ModBat { text: Dev.batPct + "%"; textColor: Theme.hi }
        }
    }
}
