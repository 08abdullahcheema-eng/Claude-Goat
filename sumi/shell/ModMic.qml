import QtQuick
// Microphone mute toggle.
Pill {
    visible: Dev.hasMic
    icon: Dev.micMuted ? "micoff" : "mic"; label: Dev.micMuted ? "mic off" : "mic"
    iconColor: Dev.micMuted ? Theme.accent : Theme.dim
    labelColor: Dev.micMuted ? Theme.accent : Theme.mute
    iconSize: Theme.px(14)
    onClicked: Dev.toggleMic()
}
