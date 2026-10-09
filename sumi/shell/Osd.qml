import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Volume / brightness pill at the bottom centre.
Scope {
    id: root
    property bool shown: Theme.demo && Quickshell.env("SUMI_DEMO_OSD") === "1"
    property bool ready: false

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    Timer { interval: 2500; running: true; onTriggered: root.ready = true }
    Timer { id: hide; interval: 1400; onTriggered: root.shown = false }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumesChanged() { if (root.ready) Ui.showOsd("volume", root.sink.audio.volume, root.sink.audio.muted); }
        function onMutedChanged() { if (root.ready) Ui.showOsd("volume", root.sink.audio.volume, root.sink.audio.muted); }
    }
    Connections {
        target: Ui
        function onOsdSerialChanged() { root.shown = true; hide.restart(); }
    }

    PanelWindow {
        visible: root.shown
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors.bottom: true
        margins.bottom: Theme.px(56)
        implicitWidth: Theme.px(350)
        implicitHeight: Theme.px(52)
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "sumi-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.panelBg
            border.width: 1; border.color: Theme.line2
            readonly property real v: Theme.demo && Ui.osdKind === "" ? 0.64 : Ui.osdValue
            readonly property bool bright: Ui.osdKind === "brightness"
            Row {
                anchors { fill: parent; leftMargin: Theme.px(18); rightMargin: Theme.px(18) }
                spacing: Theme.px(14)
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: parent.parent.bright ? "sun" : (Ui.osdMuted ? "volmute" : "vol")
                    color: Theme.hi; size: Theme.px(18)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.px(18) - Theme.px(36) - Theme.px(28); height: Theme.px(7); radius: height / 2
                    color: Theme.line
                    Rectangle {
                        width: parent.width * Math.min(1, parent.parent.parent.v); height: parent.height; radius: parent.radius
                        color: Ui.osdMuted ? Theme.mute : (parent.parent.parent.bright ? Theme.gold : Theme.accent)
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }
                }
                T { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(36); horizontalAlignment: Text.AlignRight; text: Math.round(parent.parent.v * 100); color: Theme.hi }
            }
        }
    }
}
