import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth

// Floating bar made of three islands: workspaces on the left, the clock in the middle,
// status and system on the right. Every icon opens a panel, press it again to close it.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins.top: Theme.barM
    margins.left: Theme.px(10)
    margins.right: Theme.px(10)
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

    Component.onCompleted: Ui.barWindows = Ui.barWindows.concat([bar])
    Component.onDestruction: Ui.barWindows = Ui.barWindows.filter(w => w !== bar)

    // click on empty bar space closes an open panel
    MouseArea { anchors.fill: parent; onClicked: Ui.close() }

    component Island: Rectangle {
        id: isl
        default property alias content: row.data
        property real pad: Theme.px(7)
        height: Theme.barH
        implicitWidth: row.implicitWidth + pad * 2
        radius: Theme.px(11)
        color: Theme.barBg
        border.width: 1
        border.color: Theme.line
        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.px(3)
        }
    }

    // ---------------- left: logo and workspaces
    Island {
        anchors.left: parent.left
        Item {
            width: Theme.px(28); height: Theme.px(26)
            anchors.verticalCenter: parent.verticalCenter
            Image {
                anchors.centerIn: parent
                width: Theme.px(24); height: width
                source: "file://" + Theme.logo
                sourceSize: Qt.size(width * 2, height * 2)
                smooth: true
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
        }
            Sep { anchors.verticalCenter: parent.verticalCenter }
        Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: bar.modelData.name }
        Sep { anchors.verticalCenter: parent.verticalCenter }
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                visible: Predator.available
                icon: "fan"
                iconColor: Predator.profile === "performance" ? Theme.accent : Theme.dim
                iconSize: Theme.px(14)
                text: Predator.profileKanji(Predator.profile) + (Predator.cpuTemp >= 0 ? " " + Predator.cpuTemp + "°" : "")
                textColor: Predator.cpuTemp >= 90 ? Theme.accent2 : Theme.dim
                active: Ui.panel === "predator"
                onClicked: Ui.toggleAt("predator", centerX())
            }
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                icon: "cpu"; iconColor: Theme.dim; iconSize: Theme.px(14)
                text: Sys.cpu + "%"
                textColor: Theme.fg
                active: Ui.panel === "system"
                onClicked: Ui.toggleAt("system", centerX())
            }
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                icon: "agent"
                iconColor: Theme.gold
                iconSize: Theme.px(14)
                text: Agents.fivePct >= 0 ? Math.round(Agents.fivePct) + "%" : (Agents.installed ? "·" : "")
                textColor: Theme.gold
                active: Ui.panel === "agents"
                visible: Agents.installed || Theme.demo
                onClicked: Ui.toggleAt("agents", centerX())
            }
    }

    // ---------------- centre: clock, opens the calendar
    Island {
        anchors.horizontalCenter: parent.horizontalCenter
        pad: Theme.px(4)
        Pill {
            id: clockPill
            anchors.verticalCenter: parent.verticalCenter
            active: Ui.panel === "calendar"
            text: ""
            implicitWidth: clockRow.implicitWidth + Theme.px(20)
            onClicked: (m) => {
                Ui.toggleAt("calendar", clockPill.centerX());
            }
            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: Theme.px(9)
                readonly property var d: Theme.demo ? new Date(2026, 9, 9, 8, 12) : clock.date
                Text { text: Qt.formatTime(clockRow.d, "HH:mm"); color: Theme.hi; font.family: Theme.mono; font.pixelSize: Theme.fmd; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                Text { text: clockRow.d.toLocaleDateString(Qt.locale("de_DE"), "ddd dd MMM").replace(/\./g, ""); color: Theme.dim; font.family: Theme.mono; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                Text { text: ["日", "月", "火", "水", "木", "金", "土"][clockRow.d.getDay()]; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    // ---------------- right: one bubble with quick controls, battery and power
    Island {
        anchors.right: parent.right
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                icon: Net.kind === "ethernet" ? "eth" : (Net.kind === "wifi" ? "wifi" : "wifioff")
                iconColor: Net.kind === "none" ? Theme.mute : Theme.fg
                active: Ui.panel === "network"
                onClicked: (m) => {
                    if (m.button === Qt.RightButton) Ui.run("nm-connection-editor");
                    else Ui.toggleAt("network", centerX());
                }
            }
            Pill {
                id: btPill
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool on: Theme.demo || (bar.bt?.enabled ?? false)
                // connected devices: name of the first one when it is the only one, else the count
                readonly property var conn: Theme.demo ? ["WH-1000XM5"]
                    : (bar.bt ? bar.bt.devices.values.filter(d => d && d.connected).map(d => d.name || d.deviceName) : [])
                icon: !on ? "btoff" : (conn.length > 0 ? "btcon" : "bt")
                iconColor: !on ? Theme.mute : (conn.length > 0 ? Theme.blue : Theme.fg)
                text: conn.length > 1 ? conn.length + "" : ""
                textColor: Theme.blue
                active: Ui.panel === "bluetooth"
                onClicked: (m) => {
                    if (m.button === Qt.RightButton) { if (bar.bt) bar.bt.enabled = !bar.bt.enabled; }
                    else Ui.toggleAt("bluetooth", centerX());
                }
            }
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool muted: bar.sink?.audio?.muted ?? false
                readonly property int vol: Theme.demo ? 64 : Math.round((bar.sink?.audio?.volume ?? 0) * 100)
                icon: muted ? "volmute" : (vol <= 0 ? "vol0" : (vol < 40 ? "vollow" : "vol"))
                iconColor: muted ? Theme.mute : Theme.fg
                text: muted ? "mute" : vol + ""
                textColor: muted ? Theme.mute : Theme.fg
                active: Ui.panel === "audio"
                onClicked: (m) => {
                    if (m.button === Qt.RightButton || m.button === Qt.MiddleButton) { if (bar.sink?.audio) bar.sink.audio.muted = !bar.sink.audio.muted; }
                    else Ui.toggleAt("audio", centerX());
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
            Row {
                spacing: Theme.px(5); anchors.verticalCenter: parent.verticalCenter
                visible: Sys.layout !== ""
                leftPadding: Theme.px(6)
                Icon { name: "kbd"; color: Theme.dim; size: Theme.px(14); anchors.verticalCenter: parent.verticalCenter }
                Text { text: Sys.layout; color: Theme.dim; font.family: Theme.mono; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
            }
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                visible: Theme.demo || (bar.bat && bar.bat.isLaptopBattery)
                readonly property int pct: Theme.demo ? 84 : Math.round((bar.bat?.percentage ?? 0) * 100)
                readonly property bool charging: Theme.demo || bar.bat?.state === UPowerDeviceState.Charging
                icon: charging ? "plug" : "bat"
                iconColor: pct <= 15 && !charging ? Theme.accent : (pct >= 50 || charging ? Theme.green : Theme.gold)
                iconSize: Theme.px(15)
                text: pct + "%"
                textColor: Theme.fg
                active: Ui.panel === "battery"
                onClicked: Ui.toggleAt("battery", centerX())
            }
            Pill {
                anchors.verticalCenter: parent.verticalCenter
                icon: "power"; iconColor: Theme.accent; iconSize: Theme.px(14)
                active: Ui.panel === "power"
                onClicked: Ui.toggle("power")
            }
    }
}
