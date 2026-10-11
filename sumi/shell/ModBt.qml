import QtQuick
// Bluetooth, opens the Bluetooth panel; right click turns the adapter on or off.
Pill {
    icon: Dev.btIcon; label: "bt"
    iconColor: !Dev.btOn ? Theme.mute : (Dev.btConnected.length > 0 ? Theme.blue : Theme.fg)
    labelColor: !Dev.btOn ? Theme.mute : (Dev.btConnected.length > 0 ? Theme.blue : Theme.fg)
    text: Dev.btConnected.length > 1 ? Dev.btConnected.length + "" : ""
    textColor: Theme.blue
    active: Ui.panel === "bluetooth"
    onClicked: (m) => {
        if (m.button === Qt.RightButton) Dev.toggleBt();
        else Ui.toggleAt("bluetooth", centerX());
    }
}
