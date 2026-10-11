import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery: big gauge, power draw, time left, health and the power profile switch.
Item {
    id: root
    anchors.fill: parent

    readonly property var bat: UPower.displayDevice
    readonly property bool demo: Theme.demo
    readonly property real pct: demo ? 84 : Math.round((bat?.percentage ?? 0) * 100)
    readonly property bool charging: demo || bat?.state === UPowerDeviceState.Charging
    readonly property bool full: !demo && bat?.state === UPowerDeviceState.FullyCharged
    readonly property real watts: demo ? 18.4 : Math.abs(bat?.changeRate ?? 0)
    readonly property real secs: demo ? 6180 : (charging ? (bat?.timeToFull ?? 0) : (bat?.timeToEmpty ?? 0))
    readonly property real energy: demo ? 71.2 : (bat?.energy ?? 0)
    readonly property real energyFull: demo ? 85 : (bat?.energyCapacity ?? 0)
    readonly property real health: demo ? 96 : (bat?.healthPercentage ?? 0)
    readonly property color tone: charging || full ? Theme.green : (pct <= 15 ? Theme.accent2 : (pct <= 35 ? Theme.gold : Theme.green))

    function span(s) {
        if (!(s > 0)) return "n/a";
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    property string profile: demo ? "balanced" : ""
    Process {
        id: getP
        running: !root.demo
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.profile = this.text.trim() }
    }
    Process {
        id: setP
        property string target: "balanced"
        command: ["powerprofilesctl", "set", target]
        onExited: getP.running = true
    }
    function setProfile(n) { setP.target = n; setP.running = true; profile = n; }

    Card {
        id: card
        width: Theme.px(350)
        x: parent.width - width - Theme.px(10)
        y: Theme.px(8)
        pad: Theme.px(18)

        Column {
            width: parent.width
            spacing: Theme.px(16)

            Row {
                spacing: Theme.px(10)
                Icon { name: root.charging ? "plug" : "bat"; color: root.tone; size: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
                T { text: "Battery"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                Text { text: "電池"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
            }

            Ring {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.px(176)
                thickness: Theme.px(12)
                value: root.pct / 100
                color: root.tone
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.px(2)
                    T { anchors.horizontalCenter: parent.horizontalCenter; text: root.pct + "%"; color: Theme.hi; font.pixelSize: Theme.px(36) }
                    T {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.full ? "Full" : (root.charging ? "Charging" : "On battery")
                        color: root.tone; font.pixelSize: Theme.px(12)
                    }
                }
            }

            Row {
                spacing: Theme.px(8)
                readonly property real cw: (parent.width - spacing * 2) / 3
                Stat { width: parent.cw; label: root.charging ? "Charge rate" : "Draw"; value: root.watts > 0 ? root.watts.toFixed(1) + " W" : "n/a" }
                Stat { width: parent.cw; label: root.charging ? "Until full" : "Time left"; value: root.full ? "full" : root.span(root.secs) }
                Stat { width: parent.cw; label: "Health"; value: root.health > 0 ? Math.round(root.health) + "%" : "n/a"; valueColor: root.health > 0 && root.health < 80 ? Theme.gold : Theme.hi }
            }

            T {
                visible: root.energyFull > 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.energy.toFixed(1) + " of " + root.energyFull.toFixed(1) + " Wh"
                color: Theme.dim; font.pixelSize: Theme.fsm
            }

            // power profile (power-profiles-daemon)
            Column {
                width: parent.width
                spacing: Theme.px(7)
                visible: root.profile !== ""
                Label { text: "Power profile" }
                Row {
                    spacing: Theme.px(6)
                    readonly property real cw: (parent.width - spacing * 2) / 3
                    Repeater {
                        model: [
                            { id: "power-saver", name: "Saver", kanji: "省" },
                            { id: "balanced", name: "Balanced", kanji: "均" },
                            { id: "performance", name: "Boost", kanji: "速" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool on: root.profile === modelData.id
                            width: parent.cw; height: Theme.px(58)
                            radius: Theme.px(8)
                            color: on ? Qt.tint(Theme.bg2, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)) : (pm.containsMouse ? Theme.bg2 : "transparent")
                            border.width: on ? Theme.px(1.5) : 1
                            border.color: on ? Theme.accent : Theme.line2
                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.px(3)
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.kanji; font.family: Theme.serif; font.weight: Font.Bold; font.pixelSize: Theme.px(20); color: on ? Theme.accent2 : Theme.hi }
                                T { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: on ? Theme.hi : Theme.fg; font.pixelSize: Theme.px(11) }
                            }
                            MouseArea {
                                id: pm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.setProfile(parent.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
