import QtQuick
// Do not disturb toggle.
Pill {
    icon: Ui.dnd ? "belloff" : "bell"; label: Ui.dnd ? "dnd" : "notif"
    iconColor: Ui.dnd ? Theme.accent : Theme.dim
    labelColor: Ui.dnd ? Theme.accent : Theme.mute
    iconSize: Theme.px(14)
    onClicked: Ui.dnd = !Ui.dnd
}
