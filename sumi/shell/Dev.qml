pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth

// Audio, battery and Bluetooth state shared by every bar layout.
Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int vol: Theme.demo ? 64 : Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property bool hasMic: Theme.demo || source !== null
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function toggleMic() { if (source?.audio) source.audio.muted = !source.audio.muted; }
    function stepVolume(up) {
        if (!sink?.audio) return;
        sink.audio.volume = Math.max(0, Math.min(1.0, sink.audio.volume + (up ? 0.05 : -0.05)));
    }
    readonly property string volIcon: muted ? "volmute" : (vol <= 0 ? "vol0" : (vol < 40 ? "vollow" : "vol"))

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: Theme.demo || (bat && bat.isLaptopBattery)
    readonly property int batPct: Theme.demo ? 84 : Math.round((bat?.percentage ?? 0) * 100)
    readonly property bool charging: Theme.demo || bat?.state === UPowerDeviceState.Charging
    readonly property color batColor: batPct <= 15 && !charging ? Theme.accent : (batPct >= 50 || charging ? Theme.green : Theme.gold)

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: Theme.demo || (bt?.enabled ?? false)
    readonly property var btConnected: Theme.demo ? ["WH-1000XM5"]
        : (bt ? bt.devices.values.filter(d => d && d.connected).map(d => d.name || d.deviceName) : [])
    readonly property string btIcon: !btOn ? "btoff" : (btConnected.length > 0 ? "btcon" : "bt")
    function toggleBt() { if (bt) bt.enabled = !bt.enabled; }

    readonly property var clockDate: Theme.demo ? new Date(2026, 9, 11, 21, 9) : clock.date
    SystemClock { id: clock; precision: SystemClock.Minutes }
}
