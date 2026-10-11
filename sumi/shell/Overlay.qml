import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// One layer surface that hosts whichever panel is open.
// Launcher, power menu and themes cover the whole screen; the other panels sit under the bar.
PanelWindow {
    id: win
    visible: Ui.panel !== "" && Ui.panel !== "polkit"
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    // small panels start under the bar so the bar icons stay clickable (press again = close)
    exclusionMode: ExclusionMode.Ignore
    margins.top: Ui.panelIsFull ? 0 : Theme.barH + Theme.barM
    color: "transparent"
    WlrLayershell.namespace: "sumi-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Ui.panel === "themes" ? Qt.rgba(0, 0, 0, 0.8) : (Ui.panelIsFull ? Theme.scrim : Qt.rgba(0, 0, 0, Theme.dark ? 0.28 : 0.12))
        opacity: win.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Ui.close()
    }

    // Hyprland's own popup grab: any click outside the panel and the bar closes it.
    // Clicks on the bar still reach the icons, so pressing the same icon again closes it too.
    HyprlandFocusGrab {
        active: win.visible
        windows: [win].concat(Ui.barWindows)
        onCleared: Ui.close()
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
                case "calendar": return calendarC;
                case "system": return systemC;
                case "battery": return batteryC;
                case "predator": return predatorC;
                case "bluetooth": return bluetoothC;
                case "audio": return audioC;
                }
                return null;
            }
            onLoaded: {
                if (item.focusFirst) item.focusFirst(); else item.forceActiveFocus();
                enterAnim.restart();
            }
            transform: Translate { id: slide }
        }
        // panels fade in and drop down a few pixels; full-screen ones only fade
        ParallelAnimation {
            id: enterAnim
            NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: 190; easing.type: Easing.OutCubic }
            NumberAnimation { target: slide; property: "y"; from: Ui.panelIsFull ? 0 : -Theme.px(10); to: 0; duration: 280; easing.type: Easing.OutQuint }
        }
    }

    Component { id: launcherC; Launcher {} }
    Component { id: networkC; NetworkPanel {} }
    Component { id: agentsC; AgentPanel {} }
    Component { id: powerC; PowerMenu {} }
    Component { id: themesC; ThemeSwitcher {} }
    Component { id: calendarC; CalendarPanel {} }
    Component { id: systemC; SysPanel {} }
    Component { id: batteryC; BatteryPanel {} }
    Component { id: predatorC; PredatorPanel {} }
    Component { id: bluetoothC; BluetoothPanel {} }
    Component { id: audioC; AudioPanel {} }
}
