import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth panel: power switch, scan, connected and paired devices, new devices while scanning.
// Click a device to connect or disconnect it, click a new device to pair it.
Item {
    id: root
    anchors.fill: parent

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasAdapter: Theme.demo || adapter !== null
    readonly property bool powered: Theme.demo ? true : (adapter?.enabled ?? false)
    readonly property bool scanning: Theme.demo ? true : (adapter?.discovering ?? false)

    readonly property var demoDevices: [
        { deviceName: "Sony WH-1000XM5", address: "AC:80:0A:11:22:33", icon: "audio-headphones", connected: true, paired: true, batteryAvailable: true, battery: 0.72, pairing: false, state: 1 },
        { deviceName: "Logitech MX Master 3S", address: "D4:01:9F:44:55:66", icon: "input-mouse", connected: true, paired: true, batteryAvailable: true, battery: 0.35, pairing: false, state: 1 },
        { deviceName: "Pixel 8", address: "58:24:29:77:88:99", icon: "phone", connected: false, paired: true, batteryAvailable: false, battery: 0, pairing: false, state: 0 },
        { deviceName: "DualSense", address: "A0:AB:51:AA:BB:CC", icon: "input-gaming", connected: false, paired: true, batteryAvailable: false, battery: 0, pairing: false, state: 0 },
        { deviceName: "JBL Flip 6", address: "F8:5C:7D:12:34:56", icon: "audio-card", connected: false, paired: false, batteryAvailable: false, battery: 0, pairing: false, state: 0 }
    ]

    // all devices, sorted: connected, then paired, then new ones (named only)
    readonly property var devices: {
        const list = Theme.demo ? demoDevices : (adapter ? adapter.devices.values : []);
        const arr = [];
        for (const d of list) {
            if (!d) continue;
            if (!d.paired && !d.connected && !hasName(d)) continue;
            arr.push(d);
        }
        arr.sort((a, b) => rank(a) - rank(b) || label(a).localeCompare(label(b)));
        return arr;
    }
    readonly property var known: devices.filter(d => d.paired || d.connected)
    readonly property var fresh: devices.filter(d => !d.paired && !d.connected)

    function hasName(d) {
        const n = d.name || d.deviceName || "";
        return n !== "" && n.replace(/[-:]/g, "") !== (d.address || "").replace(/[-:]/g, "");
    }
    function label(d) { return d.name || d.deviceName || d.address || "?"; }
    function rank(d) { return d.connected ? 0 : (d.paired ? 1 : 2); }
    function iconFor(d) {
        const i = (d.icon || "").toLowerCase();
        if (i.indexOf("head") >= 0 || i.indexOf("audio") >= 0) return "headphones";
        if (i.indexOf("mouse") >= 0) return "mouse";
        if (i.indexOf("keyboard") >= 0) return "kbd";
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0) return "gamepad";
        if (i.indexOf("phone") >= 0) return "phone";
        if (i.indexOf("computer") >= 0) return "monitor";
        return "bt";
    }
    function busy(d) { return d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting; }
    function status(d) {
        if (d.pairing) return "pairing…";
        if (d.state === BluetoothDeviceState.Connecting) return "connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "disconnecting…";
        if (d.connected) return "connected";
        if (d.paired) return "paired";
        return "new";
    }
    function activate(d) {
        if (Theme.demo || busy(d)) return;
        if (d.connected) { d.disconnect(); return; }
        if (!d.paired) { d.trusted = true; d.pair(); return; }
        d.connect();
    }
    function setPower(v) { if (adapter) adapter.enabled = v; }
    function setScan(v) { if (adapter && adapter.enabled) adapter.discovering = v; }

    // stop scanning when the panel goes away
    Component.onDestruction: if (!Theme.demo && adapter && adapter.discovering) adapter.discovering = false

    Card {
        id: card
        width: Theme.px(400)
        x: Ui.dropX(width, parent.width, parent.width - width - Theme.px(10))
        y: Theme.px(8)

        Column {
            width: parent.width
            spacing: Theme.px(12)

            // header
            Item {
                width: parent.width; height: Theme.px(24)
                Row {
                    spacing: Theme.px(10); anchors.verticalCenter: parent.verticalCenter
                    Icon { name: root.powered ? "bt" : "btoff"; color: root.powered ? Theme.blue : Theme.mute; size: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Bluetooth"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "藍"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                }
                Toggle {
                    visible: root.hasAdapter
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    checked: root.powered
                    onToggled: (v) => root.setPower(v)
                }
            }

            // no adapter / powered off
            Rectangle {
                visible: !root.hasAdapter || !root.powered
                width: parent.width; height: Theme.px(64); radius: Theme.px(7)
                color: Theme.bg; border.width: 1; border.color: Theme.line
                Column {
                    anchors.centerIn: parent; spacing: Theme.px(4)
                    T { anchors.horizontalCenter: parent.horizontalCenter; text: root.hasAdapter ? "Bluetooth is off" : "No Bluetooth adapter found"; color: Theme.hi }
                    T { anchors.horizontalCenter: parent.horizontalCenter; text: root.hasAdapter ? "turn it on with the switch" : "is bluetooth.nix in your flake?"; color: Theme.mute; font.pixelSize: Theme.px(10.5) }
                }
            }

            // known devices
            Label { visible: root.powered && root.known.length > 0; text: "Devices · " + root.known.length }
            Column {
                visible: root.powered && root.known.length > 0
                width: parent.width
                spacing: Theme.px(6)
                Repeater {
                    model: root.known
                    delegate: devRow
                }
            }

            // scanning
            Item {
                visible: root.powered
                width: parent.width; height: Theme.px(28)
                Label { text: root.scanning ? "Nearby · searching" : "Nearby"; anchors.verticalCenter: parent.verticalCenter }
                Btn {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: root.scanning ? "Stop" : "Scan"
                    primary: !root.scanning
                    onClicked: root.setScan(!root.scanning)
                }
            }
            Column {
                visible: root.powered && root.fresh.length > 0
                width: parent.width
                spacing: Theme.px(6)
                Repeater {
                    model: root.fresh
                    delegate: devRow
                }
            }
            T {
                visible: root.powered && root.fresh.length === 0
                text: root.scanning ? "looking for devices…" : "press Scan to find new devices"
                color: Theme.mute; font.pixelSize: Theme.px(10.5)
            }

            Item {
                width: parent.width; height: Theme.px(16)
                T { anchors.right: parent.right; text: "Advanced →"; color: Theme.mute; font.pixelSize: Theme.px(10.5)
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Ui.close(); Ui.run("blueman-manager"); } } }
            }
        }
    }

    Component {
        id: devRow
        Rectangle {
            id: row
            required property var modelData
            readonly property var d: modelData
            readonly property bool on: d.connected
            width: parent ? parent.width : 0
            height: Theme.px(48)
            radius: Theme.px(7)
            color: on ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.08) : (rm.containsMouse ? Theme.bg2 : Theme.bg)
            border.width: 1
            border.color: on ? Theme.blue : (rm.containsMouse ? Theme.line2 : Theme.line)
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                anchors { left: parent.left; leftMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(12)
                Rectangle {
                    width: Theme.px(30); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: row.on ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.18) : Theme.bg2
                    Icon { anchors.centerIn: parent; name: root.iconFor(row.d); color: row.on ? Theme.blue : Theme.dim; size: Theme.px(16) }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.px(2)
                    T { text: root.label(row.d); color: Theme.hi; font.pixelSize: Theme.px(13); width: card.width - Theme.px(190); elide: Text.ElideRight }
                    T { text: root.status(row.d); color: row.on ? Theme.blue : Theme.mute; font.pixelSize: Theme.px(10.5) }
                }
            }
            Row {
                anchors { right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(10)
                Row {
                    visible: row.d.batteryAvailable === true
                    spacing: Theme.px(5); anchors.verticalCenter: parent.verticalCenter
                    readonly property int pct: Math.round((row.d.battery ?? 0) * 100)
                    Icon { name: "bat"; size: Theme.px(14); color: parent.pct <= 20 ? Theme.accent : Theme.green; anchors.verticalCenter: parent.verticalCenter }
                    T { text: parent.pct + "%"; color: Theme.dim; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                }
                T {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.busy(row.d) ? "…" : (row.on ? "Disconnect" : (row.d.paired ? "Connect" : "Pair"))
                    color: rm.containsMouse ? Theme.hi : Theme.mute
                    font.pixelSize: Theme.px(10.5)
                }
            }
            MouseArea {
                id: rm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (m) => {
                    if (m.button === Qt.RightButton) { if (!Theme.demo && row.d.paired) row.d.forget(); }
                    else root.activate(row.d);
                }
            }
        }
    }
}
