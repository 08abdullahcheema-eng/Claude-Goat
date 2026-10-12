import QtQuick
// RAM in use, opens the system panel.
Pill {
    icon: "mem"; label: "ram"; iconColor: Theme.dim; iconSize: Theme.px(14)
    text: Sys.memPct + (labels ? "" : "%")
    textColor: Theme.fg
    active: Ui.panel === "system"
    onClicked: Ui.toggleAt("system", centerX())
}
