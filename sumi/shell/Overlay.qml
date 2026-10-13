import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Effects

// One layer surface that hosts whichever panel is open.
// Launcher, power menu and themes cover the whole screen; the other panels sit under the bar.
PanelWindow {
    id: win
    // the panel on screen: follows Ui.panel, but stays a moment longer when closing so it can animate out
    property string cur: ""
    readonly property bool full: Ui.fullscreenPanels.indexOf(cur) >= 0
    readonly property bool open: Ui.panel !== "" && Ui.panel !== "polkit"
    visible: cur !== "" && cur !== "polkit"
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    // small panels start under the bar so the bar icons stay clickable (press again = close)
    exclusionMode: ExclusionMode.Ignore
    margins.top: full || Theme.barEdge !== "top" ? 0 : Theme.barReserve
    margins.bottom: full || Theme.barEdge !== "bottom" ? 0 : Theme.barReserve
    margins.left: full || Theme.barEdge !== "left" ? 0 : Theme.barReserve
    color: "transparent"
    WlrLayershell.namespace: "sumi-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    // focus goes back to the windows as soon as the panel starts closing
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Connections {
        target: Ui
        function onPanelChanged() { win.sync(); }
    }
    Component.onCompleted: sync()
    function sync() {
        const want = Ui.panel === "polkit" ? "" : Ui.panel;
        if (want === "") {
            if (cur !== "" && !exitAnim.running) { enterAnim.stop(); exitAnim.start(); }
            return;
        }
        exitAnim.stop();
        if (want !== cur) cur = want;      // the Loader swaps the panel and starts enterAnim
        else if (motion.k < 1) enterAnim.restart();
    }

    // k runs 0 -> 1 when a panel opens and back to 0 when it closes; every style maps it differently
    QtObject {
        id: motion
        property real k: 0
        readonly property string style: Theme.mStyle
        readonly property real kc: Math.max(0, Math.min(1, k))
        // direction of travel: away from the bar the panel hangs from (summit always descends)
        readonly property real dirY: win.full ? 0 : (style === "descend" ? -1 : Theme.barEdge === "bottom" ? 1 : Theme.barEdge === "left" ? 0 : -1)
        readonly property real dirX: !win.full && Theme.barEdge === "left" && style !== "descend" ? -1 : 0
        readonly property real dist: win.full ? Theme.mDist * 0.6 : Theme.mDist
    }

    Rectangle {
        anchors.fill: parent
        color: win.cur === "themes" ? Qt.rgba(0, 0, 0, 0.8) : (win.full ? Theme.scrim : Qt.rgba(0, 0, 0, Theme.dark ? 0.28 : 0.12))
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: win.open ? Theme.mIn : Theme.mOut; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        enabled: win.open
        acceptedButtons: Qt.AllButtons
        onPressed: Ui.close()
    }

    // Hyprland's own popup grab: any click outside the panel and the bar closes it.
    // Clicks on the bar still reach the icons, so pressing the same icon again closes it too.
    HyprlandFocusGrab {
        active: win.open
        windows: [win].concat(Ui.barWindows)
        onCleared: Ui.close()
    }

    Item {
        id: host
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.close()

        // hagane cuts the panel in like a blade: a clip that opens from the bar edge
        Item {
            id: clipper
            readonly property bool wipe: motion.style === "wipe" && !win.full
            readonly property real reach: Theme.px(620)
            clip: wipe && motion.kc < 1
            x: 0
            y: wipe && Theme.barEdge === "bottom" && motion.kc < 1 ? host.height - reach * motion.kc : 0
            width: wipe && Theme.barEdge === "left" && motion.kc < 1 ? reach * motion.kc : host.width
            height: wipe && Theme.barEdge !== "left" && motion.kc < 1 ? reach * motion.kc : host.height

            Loader {
                id: loader
                // keep the panel where it is while the clip moves
                x: -clipper.x; y: -clipper.y
                width: host.width; height: host.height
                focus: true
                active: win.visible
                sourceComponent: {
                    switch (win.cur) {
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
                    motion.k = 0;
                    enterAnim.restart();
                }
                opacity: motion.style === "mist" ? motion.kc * motion.kc : Math.min(1, motion.kc * 1.5)
                transform: [
                    Scale {
                        // grow out of the icon that opened the panel (or the screen centre)
                        origin.x: win.full || Ui.anchorX < 0 ? loader.width / 2 : Ui.anchorX - (Theme.barEdge === "left" ? Theme.barReserve : 0)
                        origin.y: win.full ? loader.height / 2 : (Theme.barEdge === "bottom" ? loader.height : (Theme.barEdge === "left" && Ui.anchorY >= 0 ? Ui.anchorY : 0))
                        xScale: Theme.mScale + (1 - Theme.mScale) * motion.k
                        yScale: xScale
                    },
                    Translate {
                        x: (1 - motion.k) * motion.dist * motion.dirX
                        y: (1 - motion.k) * motion.dist * motion.dirY
                    }
                ]
                // kiri: the panel condenses out of a blur
                layer.enabled: motion.style === "mist" && motion.kc < 0.999
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 40; blur: 1 - motion.kc }
            }
        }
        NumberAnimation {
            id: enterAnim
            target: motion; property: "k"; to: 1
            duration: win.full ? Math.round(Theme.mIn * 0.85) : Theme.mIn
            easing.type: Theme.mEase
            easing.overshoot: Theme.mOvershoot
        }
        NumberAnimation {
            id: exitAnim
            target: motion; property: "k"; to: 0
            duration: Theme.mOut
            easing.type: Theme.mEaseOut
            onFinished: if (Ui.panel === "" || Ui.panel === "polkit") win.cur = ""
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
