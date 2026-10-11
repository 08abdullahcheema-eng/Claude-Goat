import QtQuick
// PredatorSense: thermal profile and CPU temperature, opens the Predator panel.
Pill {
    visible: Predator.available
    icon: "fan"; label: "fan"
    iconColor: Predator.profile === "performance" ? Theme.accent : Theme.dim
    iconSize: Theme.px(14)
    text: (labels ? "" : Predator.profileKanji(Predator.profile) + " ") + (Predator.cpuTemp >= 0 ? Predator.cpuTemp + "°" : "")
    textColor: Predator.cpuTemp >= 90 ? Theme.accent2 : (labels ? Theme.fg : Theme.dim)
    active: Ui.panel === "predator"
    onClicked: Ui.toggleAt("predator", centerX())
}
