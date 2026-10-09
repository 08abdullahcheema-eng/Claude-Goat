import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// One layer surface that hosts whichever panel is open.
// Launcher, power menu and themes cover the whole screen; network and agents sit under the bar.
PanelWindow {
    id: win
    visible: Ui.panel !== "" && Ui.panel !== "polkit"
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: Ui.panelIsFull ? ExclusionMode.Ignore : ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "sumi-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Ui.panelIsFull ? Theme.scrim : Qt.rgba(0, 0, 0, Theme.dark ? 0.28 : 0.12)
        opacity: win.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: Ui.close()
    }

    Item {
        id: host
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.close()

        Loader {
            id: loader
            anchors.fill: parent
            focus: true
            active: win.visible
            sourceComponent: {
                switch (Ui.panel) {
                case "launcher": return launcherC;
                case "network": return networkC;
                case "agents": return agentsC;
                case "power": return powerC;
                case "themes": return themesC;
                }
                return null;
            }
            onLoaded: { if (item.focusFirst) item.focusFirst(); else item.forceActiveFocus(); }
        }
    }

    Component { id: launcherC; Launcher {} }
    Component { id: networkC; NetworkPanel {} }
    Component { id: agentsC; AgentPanel {} }
    Component { id: powerC; PowerMenu {} }
    Component { id: themesC; ThemeSwitcher {} }
}
