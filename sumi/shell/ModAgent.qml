import QtQuick
// Claude Code usage, opens the agent panel. Hidden until Claude Code is set up.
Pill {
    icon: "agent"; label: "ai"; iconColor: Theme.gold; iconSize: Theme.px(14)
    text: Agents.fivePct >= 0 ? Math.round(Agents.fivePct) + "%" : (Agents.installed ? "·" : "")
    textColor: Theme.gold
    active: Ui.panel === "agents"
    visible: Agents.installed || Theme.demo
    onClicked: Ui.toggleAt("agents", centerX())
}
