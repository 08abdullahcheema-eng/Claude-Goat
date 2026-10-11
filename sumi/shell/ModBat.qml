import QtQuick
// Battery, opens the battery panel.
Pill {
    visible: Dev.hasBattery
    icon: Dev.charging ? "plug" : "bat"; label: Dev.charging ? "ac" : "bat"
    iconColor: Dev.batColor
    iconSize: Theme.px(15)
    text: Dev.batPct + (labels ? "" : "%")
    textColor: labels ? Dev.batColor : Theme.fg
    active: Ui.panel === "battery"
    onClicked: Ui.toggleAt("battery", centerX())
}
