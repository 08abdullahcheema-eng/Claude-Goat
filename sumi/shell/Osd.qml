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
    // 0 = gone, 1 = on screen; the window stays mapped while it animates out
    property real k: shown ? 1 : 0
    Behavior on k { NumberAnimation { duration: root.shown ? Theme.mIn : Theme.mOut + 80; easing.type: root.shown ? Theme.mEase : Theme.mEaseOut; easing.overshoot: Theme.mOvershoot } }

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
        visible: root.k > 0.001
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors.bottom: true
        // a little taller than the pill so it can move in without being cut off
        margins.bottom: (Theme.barEdge === "bottom" ? Theme.barReserve + Theme.px(24) : Theme.px(56)) - Theme.px(20)
        implicitWidth: Theme.px(380)
        implicitHeight: Theme.px(92)
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "sumi-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.centerIn: parent
            width: Theme.px(350); height: Theme.px(52)
            opacity: Math.max(0, Math.min(1, root.k * 1.4))
            scale: Theme.mStyle === "bloom" || Theme.mStyle === "mist" ? (Theme.mScale + (1 - Theme.mScale) * root.k) : 1
            transform: Translate { y: (1 - root.k) * (Theme.mStyle === "descend" ? -Theme.px(14) : Theme.px(18)) }
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
                        Behavior on width { NumberAnimation { duration: Theme.mFast; easing.type: Easing.OutCubic } }
                    }
                }
                T { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(36); horizontalAlignment: Text.AlignRight; text: Math.round(parent.parent.v * 100); color: Theme.hi }
            }
        }
    }
}
