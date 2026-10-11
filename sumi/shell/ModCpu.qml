import QtQuick
// CPU usage, opens the system panel.
Pill {
    icon: "cpu"; label: "cpu"; iconColor: Theme.dim; iconSize: Theme.px(14)
    text: Sys.cpu + (labels ? "" : "%")
    textColor: Theme.fg
    active: Ui.panel === "system"
    onClicked: Ui.toggleAt("system", centerX())
}
