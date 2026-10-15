import QtQuick
import Quickshell

// Corners: no bar, only quiet text in the corners of the screen.
Scope {
    id: lay
    required property var screenRef
    property bool preview: false        // a copy drawn above the theme picker

    BarWindow {
        screen: lay.screenRef
        preview: lay.preview
        edge: "top"
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.35) } GradientStop { position: 1; color: "transparent" } } }
        Row {
            anchors { left: parent.left; leftMargin: Theme.px(24); verticalCenter: parent.verticalCenter }
            spacing: Theme.px(18)
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
        }
        // time, large and thin, with the date under it
        Item {
            anchors { right: parent.right; rightMargin: Theme.px(24); verticalCenter: parent.verticalCenter }
            width: tcol.implicitWidth; height: tcol.implicitHeight
            readonly property var d: Dev.clockDate
            Column {
                id: tcol
                spacing: -Theme.px(2)
                Text { anchors.right: parent.right; text: Qt.formatTime(parent.parent.d, "HH:mm"); color: Ui.panel === "calendar" ? Theme.accent : Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(22); font.weight: Font.Light; font.letterSpacing: -Theme.px(0.5) }
                Text { anchors.right: parent.right; text: parent.parent.d.toLocaleDateString(Qt.locale("de_DE"), "ddd dd.MM").replace(/\./, "").toUpperCase(); color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(8.5); font.letterSpacing: Theme.px(2.5) }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("calendar", mapToItem(null, width / 2, 0).x) }
        }
    }
    BarWindow {
        screen: lay.screenRef
        preview: lay.preview
        edge: "bottom"
        reserve: Theme.px(30)
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.35) } } }
        Text {
            anchors { left: parent.left; leftMargin: Theme.px(24); verticalCenter: parent.verticalCenter }
            text: "NIXOS / HYPRLAND / " + Theme.label.toUpperCase()
            color: Theme.mute; font.family: Theme.body; font.pixelSize: Theme.px(9.5); font.letterSpacing: Theme.px(2.5)
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
        }
        Row {
            anchors { right: parent.right; rightMargin: Theme.px(18); verticalCenter: parent.verticalCenter }
            spacing: Theme.px(2)
            ModFan {} ModCpuCurve {} ModAgent {} ModNet {} ModBt {} ModVol {} ModMic {} ModDnd {}
            KbdLayout { anchors.verticalCenter: parent.verticalCenter }
            ModBatRing { showPct: true }
            // the red dot is the power button
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.px(22); height: width; color: "transparent"
                Rectangle { anchors.centerIn: parent; width: Theme.px(8); height: width; radius: width / 2; color: Theme.accent; scale: pm.containsMouse ? 1.4 : 1; Behavior on scale { NumberAnimation { duration: 120 } } }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("power") }
            }
        }
    }
}
