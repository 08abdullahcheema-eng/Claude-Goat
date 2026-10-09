import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth

// Top bar: workspaces left, clock + quick toggles centre, system right.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barH
    exclusiveZone: Theme.barH
    color: "transparent"
    WlrLayershell.namespace: "sumi-bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [bar.sink, bar.source] }

    readonly property var bat: UPower.displayDevice
    readonly property var bt: Bluetooth.defaultAdapter

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.line }
    }

    // ---------------- left
    Row {
        anchors { left: parent.left; leftMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
        spacing: Theme.px(12)

        Item {
            width: Theme.px(26); height: Theme.px(26)
            anchors.verticalCenter: parent.verticalCenter
            Image {
                anchors.fill: parent
                source: "file://" + Theme.logo
                sourceSize: Qt.size(width * 2, height * 2)
                smooth: true
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
        }

        Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: bar.modelData.name }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, bar.width * 0.22)
            elide: Text.ElideRight
            text: Theme.demo ? "nvim · home.nix" : (Hyprland.activeToplevel?.title ?? "")
            color: Theme.mute
            font.family: Theme.mono
            font.pixelSize: Theme.fsm
        }
    }

    // ---------------- centre
    Row {
        anchors.centerIn: parent
        spacing: Theme.px(4)

        Pill {
            active: false
            text: ""
            implicitWidth: clockRow.implicitWidth + Theme.px(16)
            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: Theme.px(8)
                readonly property var d: Theme.demo ? new Date(2026, 9, 9, 8, 12) : clock.date
                Text { text: Qt.formatTime(clockRow.d, "HH:mm"); color: Theme.hi; font.family: Theme.mono; font.pixelSize: Theme.fmd; anchors.verticalCenter: parent.verticalCenter }
                Text { text: clockRow.d.toLocaleDateString(Qt.locale("de_DE"), "ddd dd MMM").replace(/\./g, ""); color: Theme.dim; font.family: Theme.mono; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                Text { text: ["日", "月", "火", "水", "木", "金", "土"][clockRow.d.getDay()]; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Sep { anchors.verticalCenter: parent.verticalCenter }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            icon: Net.kind === "ethernet" ? "eth" : (Net.kind === "wifi" ? "wifi" : "wifioff")
            iconColor: Net.kind === "none" ? Theme.mute : Theme.fg
            active: Ui.panel === "network"
            onClicked: (m) => {
                if (m.button === Qt.RightButton) Ui.run("nm-connection-editor");
                else Ui.toggle("network");
            }
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            icon: "bt"
            iconColor: (Theme.demo || (bar.bt && bar.bt.enabled)) ? Theme.fg : Theme.mute
            visible: Theme.demo || bar.bt !== null
            onClicked: (m) => {
                if (m.button === Qt.RightButton) Ui.run("blueman-manager || overskride");
                else if (bar.bt) bar.bt.enabled = !bar.bt.enabled;
            }
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool muted: bar.sink?.audio?.muted ?? false
            readonly property int vol: Theme.demo ? 64 : Math.round((bar.sink?.audio?.volume ?? 0) * 100)
            icon: muted ? "volmute" : "vol"
            iconColor: muted ? Theme.mute : Theme.fg
            text: vol + ""
            onClicked: (m) => {
                if (m.button === Qt.RightButton) Ui.run("pavucontrol");
                else if (bar.sink?.audio) bar.sink.audio.muted = !bar.sink.audio.muted;
            }
            onWheel: (w) => {
                if (!bar.sink?.audio) return;
                const step = w.angleDelta.y > 0 ? 0.05 : -0.05;
                bar.sink.audio.volume = Math.max(0, Math.min(1.0, bar.sink.audio.volume + step));
            }
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool muted: bar.source?.audio?.muted ?? false
            icon: muted ? "micoff" : "mic"
            iconColor: muted ? Theme.accent : Theme.dim
            iconSize: Theme.px(14)
            visible: Theme.demo || bar.source !== null
            onClicked: if (bar.source?.audio) bar.source.audio.muted = !bar.source.audio.muted
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            icon: Ui.dnd ? "belloff" : "bell"
            iconColor: Ui.dnd ? Theme.accent : Theme.dim
            iconSize: Theme.px(14)
            onClicked: Ui.dnd = !Ui.dnd
        }

        Sep { anchors.verticalCenter: parent.verticalCenter }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            icon: "agent"
            iconColor: Theme.gold
            iconSize: Theme.px(14)
            text: Agents.fivePct >= 0 ? Math.round(Agents.fivePct) + "%" : (Agents.installed ? "·" : "")
            textColor: Theme.gold
            active: Ui.panel === "agents"
            visible: Agents.installed || Theme.demo
            onClicked: Ui.toggle("agents")
        }
    }

    // ---------------- right
    Row {
        anchors { right: parent.right; rightMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
        spacing: Theme.px(10)

        Row {
            spacing: Theme.px(5); anchors.verticalCenter: parent.verticalCenter
            Icon { name: "cpu"; color: Theme.dim; size: Theme.px(14); anchors.verticalCenter: parent.verticalCenter }
            Text { text: Sys.cpu + "%"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
            MouseArea { width: 0; height: 0 }
        }
        Row {
            spacing: Theme.px(5); anchors.verticalCenter: parent.verticalCenter
            visible: Sys.layout !== ""
            Icon { name: "kbd"; color: Theme.dim; size: Theme.px(14); anchors.verticalCenter: parent.verticalCenter }
            Text { text: Sys.layout; color: Theme.dim; font.family: Theme.mono; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            spacing: Theme.px(5); anchors.verticalCenter: parent.verticalCenter
            visible: Theme.demo || (bar.bat && bar.bat.isLaptopBattery)
            readonly property int pct: Theme.demo ? 84 : Math.round((bar.bat?.percentage ?? 0) * 100)
            readonly property bool charging: Theme.demo || bar.bat?.state === UPowerDeviceState.Charging
            Icon {
                name: parent.charging ? "plug" : "bat"
                color: parent.pct <= 15 && !parent.charging ? Theme.accent : (parent.pct >= 50 || parent.charging ? Theme.green : Theme.gold)
                size: Theme.px(15); anchors.verticalCenter: parent.verticalCenter
            }
            Text { text: parent.pct + "%"; color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            icon: "power"; iconColor: Theme.accent; iconSize: Theme.px(14)
            active: Ui.panel === "power"
            onClicked: Ui.toggle("power")
        }
    }
}
