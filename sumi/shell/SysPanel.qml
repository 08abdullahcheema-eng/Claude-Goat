import QtQuick
import Quickshell

// System details: gauges for CPU, RAM and temperature, every thread as a live bar,
// load history, clock speed and the biggest memory users.
Item {
    id: root
    anchors.fill: parent

    Component.onCompleted: Sys.detail = true
    Component.onDestruction: Sys.detail = false

    function gb(kb) { return (kb / 1048576).toFixed(1); }
    function span(s) {
        const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
        return (d > 0 ? d + "d " : "") + (h > 0 || d > 0 ? h + "h " : "") + m + "m";
    }
    function loadColor(u) { return u >= 85 ? Theme.accent2 : (u >= 55 ? Theme.gold : (u >= 25 ? Theme.cyan : Theme.blue)); }

    readonly property real memUsed: Sys.memTotal - Sys.memAvail
    readonly property real memPct: Sys.memTotal > 0 ? 100 * memUsed / Sys.memTotal : 0
    readonly property real swapUsed: Sys.swapTotal - Sys.swapFree
    readonly property color tempColor: Sys.temp >= 85 ? Theme.accent2 : (Sys.temp >= 70 ? Theme.gold : Theme.green)
    readonly property real maxMb: Math.max(1, ...Sys.procs.map(p => p.mb))

    Card {
        id: card
        width: Theme.px(440)
        x: Ui.dropX(width, parent.width, parent.width - width - Theme.px(10))
        y: Theme.px(8)
        pad: Theme.px(18)

        Column {
            width: parent.width
            spacing: Theme.px(16)

            // header
            Item {
                width: parent.width; height: Theme.px(26)
                Row {
                    spacing: Theme.px(10); anchors.verticalCenter: parent.verticalCenter
                    Icon { name: "cpu"; color: Theme.accent2; size: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "System"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "系統"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                }
                T {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: Sys.model
                    color: Theme.dim; font.pixelSize: Theme.px(10.5)
                }
            }

            // three gauges
            Row {
                id: rings
                width: parent.width
                spacing: Theme.px(8)
                readonly property real rs: (width - spacing * 2) / 3

                Ring {
                    width: rings.rs
                    value: Sys.cpu / 100
                    color: root.loadColor(Sys.cpu)
                    Column {
                        anchors.centerIn: parent
                        T { anchors.horizontalCenter: parent.horizontalCenter; text: Sys.cpu + "%"; color: Theme.hi; font.pixelSize: Theme.px(24) }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "CPU" }
                    }
                }
                Ring {
                    width: rings.rs
                    value: root.memPct / 100
                    color: Theme.blue
                    Column {
                        anchors.centerIn: parent
                        T { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.memPct) + "%"; color: Theme.hi; font.pixelSize: Theme.px(24) }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "RAM" }
                    }
                }
                Ring {
                    width: rings.rs
                    value: Sys.temp >= 0 ? Math.max(0, Sys.temp - 20) / 80 : 0
                    color: root.tempColor
                    Column {
                        anchors.centerIn: parent
                        T { anchors.horizontalCenter: parent.horizontalCenter; text: Sys.temp >= 0 ? Sys.temp + "°" : "n/a"; color: Theme.hi; font.pixelSize: Theme.px(24) }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Temp" }
                    }
                }
            }

            // quick facts
            Row {
                spacing: Theme.px(8)
                readonly property real cw: (parent.width - spacing * 3) / 4
                Stat { width: parent.cw; label: "Clock"; value: Sys.freqAvg > 0 ? Sys.freqAvg.toFixed(1) + " GHz" : "n/a" }
                Stat { width: parent.cw; label: "Boost"; value: Sys.freqMax > 0 ? Sys.freqMax.toFixed(1) + " GHz" : "n/a"; valueColor: Theme.gold }
                Stat { width: parent.cw; label: "Load"; value: Sys.load !== "" ? Sys.load.split(" ")[0] : "n/a" }
                Stat { width: parent.cw; label: "Up"; value: root.span(Sys.upSec) }
            }

            // every thread as a bar
            Column {
                width: parent.width
                spacing: Theme.px(6)
                visible: Sys.cores.length > 0

                Item {
                    width: parent.width; height: Theme.px(14)
                    Label { text: Sys.cores.length === 32 ? "P-cores  16 threads" : "Threads  " + Sys.cores.length }
                    Label { visible: Sys.cores.length === 32; text: "E-cores  16 threads"; anchors.right: parent.right }
                }
                Item {
                    id: coreBox
                    width: parent.width; height: Theme.px(62)
                    readonly property int n: Sys.cores.length
                    readonly property real gap: Theme.px(3)
                    readonly property real split: n === 32 ? Theme.px(10) : 0
                    readonly property real bw: n > 0 ? (width - (n - 1) * gap - split) / n : 0
                    Repeater {
                        model: Sys.cores
                        delegate: Item {
                            required property var modelData
                            required property int index
                            x: index * (coreBox.bw + coreBox.gap) + (coreBox.n === 32 && index >= 16 ? coreBox.split : 0)
                            width: coreBox.bw; height: coreBox.height
                            Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.bg; border.width: 1; border.color: Theme.line }
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: Math.max(width, parent.height * parent.modelData / 100)
                                radius: width / 2
                                color: root.loadColor(parent.modelData)
                                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }

            // last 3 minutes
            Column {
                width: parent.width
                spacing: Theme.px(6)
                Item {
                    width: parent.width; height: Theme.px(14)
                    Label { text: "Load, last 3 min" }
                    Label { text: "peak " + Math.max(0, ...Sys.hist) + "%"; anchors.right: parent.right }
                }
                Item {
                    id: graph
                    width: parent.width; height: Theme.px(48)
                    Rectangle { anchors.fill: parent; radius: Theme.px(5); color: Theme.bg; border.width: 1; border.color: Theme.line }
                    Repeater {
                        model: Sys.hist
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property real bw: (graph.width - 2) / 60
                            x: 1 + (60 - Sys.hist.length + index) * bw
                            width: Math.max(1, bw - 1)
                            height: Math.max(1, (graph.height - 2) * modelData / 100)
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            radius: 1
                            color: root.loadColor(modelData)
                            opacity: 0.4 + 0.6 * (index / Math.max(1, Sys.hist.length - 1))
                        }
                    }
                }
            }

            // memory
            Column {
                width: parent.width
                spacing: Theme.px(7)
                Item {
                    width: parent.width; height: Theme.px(14)
                    Label { text: "Memory  " + root.gb(root.memUsed) + " of " + root.gb(Sys.memTotal) + " GB" }
                    Label { visible: Sys.swapTotal > 0; text: "swap " + root.gb(root.swapUsed) + " GB"; anchors.right: parent.right }
                }
                Repeater {
                    model: Sys.procs
                    delegate: Item {
                        required property var modelData
                        width: parent.width; height: Theme.px(22)
                        Rectangle {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            height: parent.height - Theme.px(4); radius: Theme.px(4)
                            width: Math.max(Theme.px(6), parent.width * parent.modelData.mb / root.maxMb)
                            color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.20)
                        }
                        T { text: modelData.name; color: Theme.hi; font.pixelSize: Theme.fsm; x: Theme.px(8); width: parent.width - Theme.px(96); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                        T { text: modelData.mb >= 1024 ? (modelData.mb / 1024).toFixed(1) + " GB" : Math.round(modelData.mb) + " MB"; color: Theme.fg; font.pixelSize: Theme.fsm; anchors { right: parent.right; rightMargin: Theme.px(8); verticalCenter: parent.verticalCenter } }
                    }
                }
            }
        }
    }
}
