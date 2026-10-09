import QtQuick
import Quickshell

// PredatorSense panel: thermal profile, fans, keyboard lighting, battery and display extras.
Item {
    id: root
    anchors.fill: parent
    property int zoneSel: -1          // -1 = all zones
    property bool customFans: Predator.fanCpu > 1 && Predator.fanCpu < 100 || Predator.fanGpu > 1 && Predator.fanGpu < 100
    readonly property var swatches: [Theme.accent, Theme.accent2, Theme.orange, Theme.gold, Theme.green, Theme.cyan, Theme.blue, Theme.violet, "#f2ecd2", "#000000"]
    function hex(c) { return String(c).replace("#", "").slice(-6); }

    component ToggleRow: Item {
        property string label: ""
        property string sub: ""
        property int value: -1
        signal toggled(bool v)
        visible: value >= 0
        width: parent ? parent.width : 0
        height: visible ? Theme.px(40) : 0
        Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: Theme.px(1)
            T { text: parent.parent.label; font.pixelSize: Theme.px(12.5) }
            T { text: parent.parent.sub; color: Theme.mute; font.pixelSize: Theme.px(10); visible: text !== "" }
        }
        Toggle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            checked: parent.value === 1
            onToggled: (v) => parent.toggled(v)
        }
    }

    Card {
        id: card
        width: Math.min(parent.width - Theme.px(20), Theme.px(780))
        x: Math.max(Theme.px(10), Math.min(parent.width - width - Theme.px(10), parent.width - width - Theme.px(80)))
        y: Theme.px(8)
        pad: Theme.px(18)

        Column {
            width: parent.width
            spacing: Theme.px(16)

            // header
            Item {
                width: parent.width; height: Theme.px(28)
                Row {
                    spacing: Theme.px(10); anchors.verticalCenter: parent.verticalCenter
                    Icon { name: "fan"; color: Theme.accent; size: Theme.px(19); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Predator"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "熱"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                    T { text: Predator.model; color: Theme.mute; font.pixelSize: Theme.px(10.5); leftPadding: Theme.px(8); anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(14)
                    visible: Predator.available
                    T { text: "CPU " + (Predator.cpuTemp >= 0 ? Predator.cpuTemp + "°" : "–"); color: Predator.cpuTemp >= 90 ? Theme.accent2 : Theme.fg; font.pixelSize: Theme.fsm }
                    T { text: "GPU " + (Predator.gpuTemp >= 0 ? Predator.gpuTemp + "°" : "–"); color: Predator.gpuTemp >= 85 ? Theme.accent2 : Theme.fg; font.pixelSize: Theme.fsm }
                }
            }

            // not installed / no permission
            Rectangle {
                visible: !Predator.available || !Predator.writable
                width: parent.width
                height: msg.implicitHeight + Theme.px(24)
                radius: Theme.px(7)
                color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.08)
                border.width: 1; border.color: Theme.gold
                T {
                    id: msg
                    x: Theme.px(14); y: Theme.px(12); width: parent.width - Theme.px(28)
                    wrapMode: Text.Wrap; font.pixelSize: Theme.fsm; color: Theme.fg
                    text: !Predator.available
                        ? "The PredatorSense driver (linuwu_sense) is not loaded. Rebuild with predator.nix and reboot once."
                        : "Read only: log out and back in once so your user joins the 'predator' group and can change settings."
                }
            }

            Row {
                visible: Predator.available
                width: parent.width
                spacing: Theme.px(22)
                readonly property real colW: (width - spacing) / 2

                // ------------- left: thermal + fans
                Column {
                    width: parent.colW
                    spacing: Theme.px(12)

                    Label { text: "Thermal profile" }
                    Seg {
                        width: parent.width
                        enabled2: Predator.writable
                        model: Predator.profiles.map(p => [p, Predator.profileLabel(p), Predator.profileKanji(p)])
                        current: Predator.profile
                        onPicked: (v) => Predator.setProfile(v)
                    }

                    Item {
                        width: parent.width; height: Theme.px(14)
                        Label { text: "Fans"; anchors.verticalCenter: parent.verticalCenter }
                        T {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: (Predator.cpuRpm >= 0 ? Predator.cpuRpm : "–") + " / " + (Predator.gpuRpm >= 0 ? Predator.gpuRpm : "–") + " rpm"
                            color: Theme.mute; font.pixelSize: Theme.px(10.5)
                        }
                    }
                    Seg {
                        width: parent.width
                        enabled2: Predator.writable
                        model: [["auto", "Auto"], ["max", "Max"], ["custom", "Custom"]]
                        current: root.customFans ? "custom" : (Predator.fanCpu >= 100 ? "max" : "auto")
                        onPicked: (v) => {
                            if (v === "auto") { root.customFans = false; Predator.setFans(0, 0); }
                            else if (v === "max") { root.customFans = false; Predator.setFans(100, 100); }
                            else { root.customFans = true; Predator.setFans(60, 60); }
                        }
                    }
                    Column {
                        visible: root.customFans
                        width: parent.width
                        spacing: Theme.px(6)
                        Row {
                            width: parent.width; spacing: Theme.px(10)
                            T { text: "CPU"; width: Theme.px(34); color: Theme.dim; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                            Slider { width: parent.width - Theme.px(44); from: 10; to: 100; step: 5; suffix: "%"; value: Predator.fanCpu; enabled2: Predator.writable; onMoved: (v) => Predator.setFans(v, Predator.fanGpu) }
                        }
                        Row {
                            width: parent.width; spacing: Theme.px(10)
                            T { text: "GPU"; width: Theme.px(34); color: Theme.dim; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                            Slider { width: parent.width - Theme.px(44); from: 10; to: 100; step: 5; suffix: "%"; value: Predator.fanGpu; enabled2: Predator.writable; color: Theme.gold; onMoved: (v) => Predator.setFans(Predator.fanCpu, v) }
                        }
                    }
                    Row {
                        width: parent.width
                        spacing: Theme.px(8)
                        readonly property real w4: (width - spacing * 3) / 4
                        Stat { width: parent.w4; label: "cpu"; value: Predator.cpuTemp >= 0 ? Predator.cpuTemp + "°" : "–"; valueColor: Predator.cpuTemp >= 90 ? Theme.accent2 : Theme.hi }
                        Stat { width: parent.w4; label: "gpu"; value: Predator.gpuTemp >= 0 ? Predator.gpuTemp + "°" : "–"; valueColor: Predator.gpuTemp >= 85 ? Theme.accent2 : Theme.hi }
                        Stat { width: parent.w4; label: "cpu fan"; value: Predator.cpuRpm >= 0 ? (Predator.cpuRpm / 1000).toFixed(1) + "k" : "–"; valueColor: Theme.dim }
                        Stat { width: parent.w4; label: "gpu fan"; value: Predator.gpuRpm >= 0 ? (Predator.gpuRpm / 1000).toFixed(1) + "k" : "–"; valueColor: Theme.dim }
                    }
                }

                // ------------- right: keyboard
                Column {
                    width: parent.colW
                    spacing: Theme.px(12)
                    visible: Predator.hasKb

                    Item {
                        width: parent.width; height: Theme.px(14)
                        Label { text: "Keyboard · 4 zones"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    // zone chips
                    Row {
                        width: parent.width
                        spacing: Theme.px(6)
                        readonly property real zw: (width - spacing * 4 - Theme.px(46)) / 4
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                required property int index
                                readonly property bool on: root.zoneSel === index || root.zoneSel < 0
                                width: parent.zw; height: Theme.px(30); radius: Theme.px(5)
                                color: "#" + Predator.zones[index]
                                opacity: Predator.kbMode === 0 || index === 0 ? 1 : 0.35
                                border.width: root.zoneSel === index ? Theme.px(2) : 1
                                border.color: root.zoneSel === index ? Theme.hi : Theme.line2
                                T { anchors.centerIn: parent; text: index + 1; color: "#0f0f14"; font.pixelSize: Theme.px(10.5); opacity: 0.7 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.zoneSel = (root.zoneSel === parent.index ? -1 : parent.index) }
                            }
                        }
                        Rectangle {
                            width: Theme.px(46); height: Theme.px(30); radius: Theme.px(5)
                            color: root.zoneSel < 0 ? Theme.bg2 : "transparent"
                            border.width: 1; border.color: root.zoneSel < 0 ? Theme.hi : Theme.line2
                            T { anchors.centerIn: parent; text: "all"; font.pixelSize: Theme.px(10.5); color: root.zoneSel < 0 ? Theme.hi : Theme.dim }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.zoneSel = -1 }
                        }
                    }
                    // colour swatches
                    Row {
                        width: parent.width
                        spacing: Theme.px(5)
                        readonly property real sw: (width - spacing * 9) / 10
                        Repeater {
                            model: root.swatches
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.sw; height: width; radius: Theme.px(4)
                                color: modelData
                                border.width: 1; border.color: Theme.line2
                                Icon { visible: root.hex(parent.modelData) === "000000"; anchors.centerIn: parent; name: "x"; color: Theme.mute; size: parent.width * 0.6 }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: Predator.writable
                                    onClicked: { Predator.setZone(Predator.kbMode === 0 ? root.zoneSel : -1, root.hex(parent.modelData)); if (Predator.followTheme) Predator.setFollowTheme(false); }
                                }
                            }
                        }
                    }
                    // effects
                    Grid {
                        width: parent.width
                        columns: 4
                        columnSpacing: Theme.px(5); rowSpacing: Theme.px(5)
                        readonly property real cw: (width - columnSpacing * 3) / 4
                        Repeater {
                            model: Predator.modeNames
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                readonly property bool on: Predator.kbMode === index
                                width: parent.cw; height: Theme.px(26); radius: Theme.px(5)
                                color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : (mm.containsMouse ? Theme.bg2 : Theme.bg)
                                border.width: 1; border.color: on ? Theme.accent : Theme.line
                                T { anchors.centerIn: parent; text: modelData; font.pixelSize: Theme.px(10.5); color: parent.on ? Theme.hi : Theme.dim }
                                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: Predator.writable; onClicked: { Predator.kbMode = parent.index; Predator.applyKb(); } }
                            }
                        }
                    }
                    Row {
                        width: parent.width; spacing: Theme.px(10)
                        T { text: "Light"; width: Theme.px(46); color: Theme.dim; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                        Slider { width: parent.width - Theme.px(56); from: 0; to: 100; step: 5; suffix: "%"; value: Predator.kbBright; enabled2: Predator.writable; onMoved: (v) => { Predator.kbBright = v; Predator.applyKb(); } }
                    }
                    Row {
                        width: parent.width; spacing: Theme.px(10)
                        visible: Predator.kbMode !== 0
                        T { text: "Speed"; width: Theme.px(46); color: Theme.dim; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
                        Slider { width: parent.width - Theme.px(56) - Theme.px(70); from: 1; to: 9; step: 1; value: Predator.kbSpeed; color: Theme.gold; enabled2: Predator.writable; onMoved: (v) => { Predator.kbSpeed = v; Predator.applyKb(); } }
                        Btn {
                            width: Theme.px(60); text: Predator.kbDir === 1 ? "← dir" : "dir →"
                            onClicked: { Predator.kbDir = Predator.kbDir === 1 ? 2 : 1; Predator.applyKb(); }
                        }
                    }
                    ToggleRow {
                        label: "Follow theme colour"
                        sub: "keyboard takes the accent of the current theme"
                        value: Predator.followTheme ? 1 : 0
                        onToggled: (v) => Predator.setFollowTheme(v)
                    }
                }
            }

            // ------------- bottom: battery + extras
            Rectangle { visible: Predator.available; width: parent.width; height: 1; color: Theme.line }
            Row {
                visible: Predator.available
                width: parent.width
                spacing: Theme.px(22)
                readonly property real colW: (width - spacing) / 2
                Column {
                    width: parent.colW
                    spacing: Theme.px(4)
                    Label { text: "Battery" }
                    ToggleRow {
                        label: "Charge limit 80%"; sub: "keeps the battery healthy when you're mostly plugged in"
                        value: Predator.limiter
                        onToggled: (v) => Predator.setToggle("limiter", v)
                    }
                    Item {
                        visible: Predator.usbCharge >= 0
                        width: parent.width; height: Theme.px(40)
                        T { text: "USB power when off"; font.pixelSize: Theme.px(12.5); anchors.verticalCenter: parent.verticalCenter }
                        Seg {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: Theme.px(190)
                            enabled2: Predator.writable
                            model: [[0, "off"], [10, "10%"], [20, "20%"], [30, "30%"]]
                            current: Predator.usbCharge
                            onPicked: (v) => Predator.setUsbCharge(v)
                        }
                    }
                }
                Column {
                    width: parent.colW
                    spacing: Theme.px(4)
                    Label { text: "Extras" }
                    ToggleRow { label: "LCD overdrive"; sub: "less ghosting"; value: Predator.lcdOverdrive; onToggled: (v) => Predator.setToggle("lcdOverdrive", v) }
                    ToggleRow { label: "Boot animation + sound"; sub: "Predator logo when powering on"; value: Predator.bootSound; onToggled: (v) => Predator.setToggle("bootSound", v) }
                    ToggleRow { label: "Keyboard light sleeps"; sub: "off after 30 s idle"; value: Predator.kbTimeout; onToggled: (v) => Predator.setToggle("kbTimeout", v) }
                }
            }
        }
    }
}
