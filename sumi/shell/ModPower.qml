import QtQuick
// Power menu.
Pill {
    icon: "power"; label: "⏻"; labelColor: Theme.accent
    iconColor: Theme.accent; iconSize: Theme.px(14)
    active: Ui.panel === "power"
    onClicked: Ui.toggle("power")
}
