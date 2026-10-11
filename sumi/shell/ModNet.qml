import QtQuick
// Network, opens the network panel; right click opens the connection editor.
Pill {
    icon: Net.kind === "ethernet" ? "eth" : (Net.kind === "wifi" ? "wifi" : "wifioff")
    label: Net.kind === "ethernet" ? "eth" : "wifi"
    labelColor: Net.kind === "none" ? Theme.mute : Theme.fg
    iconColor: Net.kind === "none" ? Theme.mute : Theme.fg
    active: Ui.panel === "network"
    onClicked: (m) => {
        if (m.button === Qt.RightButton) Ui.run("nm-connection-editor");
        else Ui.toggleAt("network", centerX());
    }
}
