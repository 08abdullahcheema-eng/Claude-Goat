import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio panel: output and microphone volume with mute, choose the output and input device.
Item {
    id: root
    anchors.fill: parent

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    readonly property bool outMuted: Theme.demo ? false : (sink?.audio?.muted ?? false)
    readonly property real outVol: Theme.demo ? 0.64 : (sink?.audio?.volume ?? 0)
    readonly property bool inMuted: Theme.demo ? false : (source?.audio?.muted ?? false)
    readonly property real inVol: Theme.demo ? 0.8 : (source?.audio?.volume ?? 0)

    readonly property var demoOut: [
        { description: "Laptop speakers", nickname: "", name: "speakers", demoOn: true },
        { description: "Sony WH-1000XM5", nickname: "", name: "bluez_output.headphones", demoOn: false },
        { description: "HDMI / DisplayPort", nickname: "", name: "hdmi", demoOn: false }
    ]
    readonly property var demoIn: [
        { description: "Laptop microphone", nickname: "", name: "mic", demoOn: true },
        { description: "Sony WH-1000XM5", nickname: "", name: "bluez_input.headset", demoOn: false }
    ]

    function devs(sinks) {
        if (Theme.demo) return sinks ? demoOut : demoIn;
        const out = [];
        for (const n of Pipewire.nodes.values) {
            if (!n || n.isStream || !n.audio) continue;
            if (n.isSink === sinks) out.push(n);
        }
        return out;
    }
    readonly property var outputs: devs(true)
    readonly property var inputs: devs(false)

    function nodeName(n) { return n.description || n.nickname || n.name || "?"; }
    function isDefault(n, sinks) {
        if (Theme.demo) return n.demoOn;
        return sinks ? n === Pipewire.defaultAudioSink : n === Pipewire.defaultAudioSource;
    }
    function nodeIcon(n, sinks) {
        if (!sinks) return "mic";
        const s = (n.name + " " + nodeName(n)).toLowerCase();
        if (s.indexOf("bluez") >= 0 || s.indexOf("head") >= 0) return "headphones";
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return "monitor";
        return "speaker";
    }
    function volIcon(v, muted) { return muted ? "volmute" : (v <= 0.001 ? "vol0" : (v < 0.4 ? "vollow" : "vol")); }

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
                    Icon { name: root.volIcon(root.outVol, root.outMuted); color: Theme.hi; size: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Sound"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "音"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // output volume
            Label { text: "Output" }
            Row {
                width: parent.width
                spacing: Theme.px(10)
                Rectangle {
                    width: Theme.px(30); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: om.containsMouse ? Theme.bg2 : Theme.bg
                    border.width: 1; border.color: root.outMuted ? Theme.accent : Theme.line2
                    Icon { anchors.centerIn: parent; name: root.volIcon(root.outVol, root.outMuted); color: root.outMuted ? Theme.accent : Theme.fg; size: Theme.px(15) }
                    MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted }
                }
                Slider {
                    width: parent.width - Theme.px(40)
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0; to: 100; step: 1; suffix: "%"
                    value: Math.round(Math.min(1, root.outVol) * 100)
                    color: root.outMuted ? Theme.mute : Theme.accent
                    enabled2: Theme.demo || !!root.sink?.audio
                    onMoved: (v) => { if (root.sink?.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v / 100; } }
                }
            }
            Column {
                width: parent.width
                spacing: Theme.px(6)
                Repeater {
                    model: root.outputs
                    delegate: Loader {
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: item ? item.height : 0
                        sourceComponent: devRow
                        onLoaded: { item.sinks = true; item.modelData = modelData; }
                    }
                }
            }

            // microphone
            Label { text: "Microphone" }
            Row {
                width: parent.width
                spacing: Theme.px(10)
                Rectangle {
                    width: Theme.px(30); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: im.containsMouse ? Theme.bg2 : Theme.bg
                    border.width: 1; border.color: root.inMuted ? Theme.accent : Theme.line2
                    Icon { anchors.centerIn: parent; name: root.inMuted ? "micoff" : "mic"; color: root.inMuted ? Theme.accent : Theme.fg; size: Theme.px(15) }
                    MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted }
                }
                Slider {
                    width: parent.width - Theme.px(40)
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0; to: 100; step: 1; suffix: "%"
                    value: Math.round(Math.min(1, root.inVol) * 100)
                    color: root.inMuted ? Theme.mute : Theme.blue
                    enabled2: Theme.demo || !!root.source?.audio
                    onMoved: (v) => { if (root.source?.audio) { root.source.audio.muted = false; root.source.audio.volume = v / 100; } }
                }
            }
            Column {
                width: parent.width
                spacing: Theme.px(6)
                Repeater {
                    model: root.inputs
                    delegate: Loader {
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: item ? item.height : 0
                        sourceComponent: devRow
                        onLoaded: { item.sinks = false; item.modelData = modelData; }
                    }
                }
            }

            Item {
                width: parent.width; height: Theme.px(16)
                T { anchors.right: parent.right; text: "Mixer →"; color: Theme.mute; font.pixelSize: Theme.px(10.5)
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Ui.close(); Ui.run("pavucontrol"); } } }
            }
        }
    }

    // one output or input device; click to make it the default
    Component {
        id: devRow
        Rectangle {
            id: row
            property var modelData
            property bool sinks: true
            readonly property bool on: modelData ? root.isDefault(modelData, sinks) : false
            width: parent ? parent.width : 0
            height: Theme.px(38)
            radius: Theme.px(7)
            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : (dm.containsMouse ? Theme.bg2 : Theme.bg)
            border.width: 1
            border.color: on ? Theme.accent : (dm.containsMouse ? Theme.line2 : Theme.line)
            Behavior on color { ColorAnimation { duration: 120 } }
            Row {
                anchors { left: parent.left; leftMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(10)
                Icon { name: row.modelData ? root.nodeIcon(row.modelData, row.sinks) : "speaker"; color: row.on ? Theme.accent : Theme.dim; size: Theme.px(15); anchors.verticalCenter: parent.verticalCenter }
                T { text: row.modelData ? root.nodeName(row.modelData) : ""; color: row.on ? Theme.hi : Theme.fg; font.pixelSize: Theme.px(12.5); width: card.width - Theme.px(110); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
            }
            Icon { visible: row.on; name: "check"; color: Theme.accent; size: Theme.px(14); anchors { right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter } }
            MouseArea {
                id: dm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Theme.demo || !row.modelData || row.on) return;
                    if (row.sinks) Pipewire.preferredDefaultAudioSink = row.modelData;
                    else Pipewire.preferredDefaultAudioSource = row.modelData;
                }
            }
        }
    }
}
