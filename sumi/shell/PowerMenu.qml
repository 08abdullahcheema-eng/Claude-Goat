import QtQuick
import Quickshell
import Quickshell.Io

// Power menu: lock, suspend, log out, reboot, shut down.
Item {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var items: [
        { key: "L", icon: "lock", name: "Lock", kanji: "錠", cmd: "pidof hyprlock || hyprlock", confirm: false },
        { key: "S", icon: "moon", name: "Suspend", kanji: "眠", cmd: "systemctl suspend", confirm: false },
        { key: "E", icon: "logout", name: "Log out", kanji: "出", cmd: "hyprctl dispatch exit", confirm: true },
        { key: "R", icon: "reboot", name: "Reboot", kanji: "再", cmd: "systemctl reboot", confirm: true },
        { key: "P", icon: "power", name: "Shut down", kanji: "終", cmd: "systemctl poweroff", confirm: true }
    ]
    property int sel: 4
    property int armed: -1
    property int countdown: 5
    property string uptime: Theme.demo ? "up 3 h 12 m" : ""
    property string gen: Theme.demo ? "generation 41" : ""
    property string host: Theme.demo ? "helios" : ""

    function go(i) {
        const it = items[i];
        Ui.close();
        Ui.run(it.cmd);
    }
    function press(i) {
        sel = i;
        if (!items[i].confirm || armed === i) { go(i); return; }
        armed = i; countdown = 5; tick.restart();
    }
    function focusFirst() { root.forceActiveFocus(); }

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Left) { sel = (sel + 4) % 5; armed = -1; e.accepted = true; }
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { sel = (sel + 1) % 5; armed = -1; e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { press(sel); e.accepted = true; }
        else if (e.key === Qt.Key_Escape) { if (armed >= 0) armed = -1; else Ui.close(); e.accepted = true; }
        else {
            const k = e.text.toUpperCase();
            const i = items.findIndex(x => x.key === k);
            if (i >= 0) { press(i); e.accepted = true; }
        }
    }

    Timer {
        id: tick; interval: 1000; repeat: true; running: root.armed >= 0
        onTriggered: { root.countdown--; if (root.countdown <= 0) root.go(root.armed); }
    }

    Process {
        running: !Theme.demo
        command: ["sh", "-c", "cat /proc/uptime; cat /etc/hostname 2>/dev/null || hostname; readlink /nix/var/nix/profiles/system"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                const s = parseFloat(l[0]);
                const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
                root.uptime = "up " + (h > 0 ? h + " h " : "") + m + " m";
                root.host = (l[1] || "").trim();
                const g = (l[2] || "").match(/system-(\d+)-link/);
                root.gen = g ? "generation " + g[1] : "";
            }
        }
    }

    // solid card, so the menu stays readable on top of white windows
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: col.implicitWidth + Theme.px(88)
        height: col.implicitHeight + Theme.px(72)
        radius: Theme.px(16)
        color: Theme.panelBg
        border.width: 1
        border.color: Theme.line2

        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: Theme.px(8)
            anchors.bottomMargin: -Theme.px(16)
            anchors.leftMargin: -Theme.px(2)
            anchors.rightMargin: -Theme.px(2)
            radius: parent.radius + Theme.px(4)
            color: Qt.rgba(0, 0, 0, 0.45)
        }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: Theme.px(10)

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.px(74); height: width
            source: "file://" + Theme.logo
            sourceSize: Qt.size(width * 2, height * 2)
        }
        T { anchors.horizontalCenter: parent.horizontalCenter; text: (Quickshell.env("USER") || "larp") + "@" + root.host; color: Theme.hi; font.pixelSize: Theme.px(18); topPadding: Theme.px(4) }
        T { anchors.horizontalCenter: parent.horizontalCenter; text: [root.uptime, "NixOS", root.gen].filter(x => x).join(" · "); color: Theme.dim; font.pixelSize: Theme.px(12) }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.px(18)
            topPadding: Theme.px(28)
            Repeater {
                model: root.items
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    width: Theme.px(188); height: Theme.px(212)
                    radius: Theme.px(10)
                    color: on ? Qt.tint(Theme.bg2, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)) : Theme.bg2
                    border.width: on ? Theme.px(2) : 1
                    border.color: on ? Theme.accent : Theme.line2
                    scale: tm.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.mFast; easing.type: Theme.mEaseSmall } }
                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.px(12)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.kanji
                            font.family: Theme.serif; font.weight: Font.Bold; font.pixelSize: Theme.px(52)
                            color: tile.on ? Theme.accent2 : Theme.hi
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.px(7)
                            Icon { name: tile.modelData.icon; size: Theme.px(14); color: tile.on ? Theme.hi : Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                            T { text: tile.modelData.name; color: tile.on ? Theme.hi : Theme.fg; font.pixelSize: Theme.px(14) }
                        }
                    }
                    Kbd { text: tile.modelData.key; anchors { top: parent.top; right: parent.right; margins: Theme.px(10) } }
                    MouseArea {
                        id: tm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (root.armed < 0) root.sel = tile.index
                        onClicked: root.press(tile.index)
                    }
                }
            }
        }

        Item { width: 1; height: Theme.px(18) }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.px(8)
            T {
                anchors.verticalCenter: parent.verticalCenter
                color: root.armed >= 0 ? Theme.hi : Theme.fg
                font.pixelSize: Theme.px(13)
                text: root.armed >= 0
                    ? root.items[root.armed].name + " in " + root.countdown + " s, press again to do it now"
                    : (root.items[root.sel].confirm ? root.items[root.sel].name + " asks once more before it happens" : root.items[root.sel].name + " right away")
            }
            Kbd { visible: root.armed >= 0; text: "↵"; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.px(14)
            topPadding: Theme.px(4)
            Repeater {
                model: [["←→", "move"], ["↵", "confirm"], ["esc", "cancel"]]
                delegate: Row {
                    required property var modelData
                    spacing: Theme.px(6)
                    Kbd { text: modelData[0] }
                    T { text: modelData[1]; color: Theme.dim; font.pixelSize: Theme.px(11); anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
    }
}
