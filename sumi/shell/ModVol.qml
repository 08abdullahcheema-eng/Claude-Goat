import QtQuick
// Volume: click opens the sound panel, right or middle click mutes, wheel changes the level.
Pill {
    icon: Dev.volIcon; label: "vol"
    iconColor: Dev.muted ? Theme.mute : Theme.fg
    text: Dev.muted ? "mute" : Dev.vol + ""
    textColor: Dev.muted ? Theme.mute : Theme.fg
    active: Ui.panel === "audio"
    onClicked: (m) => {
        if (m.button === Qt.RightButton || m.button === Qt.MiddleButton) Dev.toggleMute();
        else Ui.toggleAt("audio", centerX());
    }
    onWheel: (w) => Dev.stepVolume(w.angleDelta.y > 0)
}
