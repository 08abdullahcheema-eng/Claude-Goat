import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects

// Screensaver: before the lock screen, the desktop sinks into black washi paper and the theme's
// kanji bleeds in in its accent colour. Particles in the theme's character drift across:
// Sumi embers rise, Iso spray swirls, Kiri mist drifts, Hagane sparks fall, Summit stars twinkle.
// A small clock sits at the bottom. Any key, click or mouse movement ends it.
// hypridle shows it (qs ipc call shell saver true) and hides it again on activity.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: Ui.saver || fade.opacity > 0.01
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "sumi-saver"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: Ui.saver ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property string style: Theme.name
            // the first moments after it appears do not count as input (the cursor reports its position)
            property bool armed: false
            Timer { id: arm; interval: 900; onTriggered: win.armed = true }
            Connections {
                target: Ui
                function onSaverChanged() { win.armed = false; if (Ui.saver) arm.restart(); }
            }
            Component.onCompleted: if (Ui.saver) arm.restart()

            Item {
                id: fade
                anchors.fill: parent
                opacity: Ui.saver ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Ui.saver ? 1600 : 260; easing.type: Easing.InOutSine } }
                focus: true
                Keys.onPressed: (e) => { if (win.armed) Ui.saver = false; e.accepted = true; }

                // paper: nearly black, a hint of the theme's own background
                Rectangle {
                    anchors.fill: parent
                    color: Qt.darker(Theme.bg, 2.2)
                }
                // a faint pool of the accent behind the kanji
                Rectangle {
                    anchors.centerIn: kanji
                    width: Math.min(parent.width, parent.height) * 0.56; height: width; radius: width / 2
                    color: Theme.accent
                    opacity: 0.07 * fade.glowK * fade.bleed
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64 }
                }

                // the kanji: it bleeds in from a blur, then breathes slowly
                property real bleed: 0
                property real glowK: 0.6
                NumberAnimation on bleed { running: Ui.saver; from: 0; to: 1; duration: 5200; easing.type: Easing.OutCubic }
                SequentialAnimation on glowK {
                    running: Ui.saver; loops: Animation.Infinite
                    NumberAnimation { to: 1; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.5; duration: 4200; easing.type: Easing.InOutSine }
                }
                Text {
                    id: kanji
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -parent.height * 0.06
                    text: Theme.kanji
                    color: Theme.accent
                    font.family: Theme.serif
                    font.weight: Font.Black
                    font.pixelSize: Math.min(parent.width, parent.height) * 0.33
                    opacity: 0.25 + 0.75 * fade.bleed
                    scale: 1.04 - 0.04 * fade.bleed
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true; blurMax: 48; blur: 1 - fade.bleed
                        shadowEnabled: true; shadowColor: Theme.accent; shadowBlur: 1
                        shadowOpacity: 0.35 * fade.glowK; shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                    }
                }

                // particles in the theme's character
                Repeater {
                    model: win.style === "summit" ? 90 : win.style === "kiri" ? 9 : 42
                    delegate: Item {
                        id: pt
                        required property int index
                        // a fixed pseudo random sequence per particle
                        function rnd(k) { const v = Math.sin((pt.index + 1) * 12.9898 + k * 78.233) * 43758.5453; return v - Math.floor(v); }
                        readonly property real x0: rnd(1) * fade.width
                        readonly property real y0: rnd(2) * fade.height
                        readonly property real sz: win.style === "kiri" ? Theme.px(220 + 260 * rnd(3))
                                                  : win.style === "summit" ? Theme.px(1 + 2 * rnd(3))
                                                  : win.style === "hagane" ? Theme.px(1.4)
                                                  : Theme.px(1.5 + 3 * rnd(3))
                        readonly property int life: win.style === "kiri" ? 40000 + 30000 * rnd(4)
                                                  : win.style === "hagane" ? 1800 + 1800 * rnd(4)
                                                  : win.style === "summit" ? 2400 + 4000 * rnd(4)
                                                  : 9000 + 9000 * rnd(4)
                        property real t: rnd(5)
                        NumberAnimation on t { running: Ui.saver; loops: Animation.Infinite; from: 0; to: 1; duration: pt.life }

                        x: {
                            switch (win.style) {
                            case "kiri": return (x0 + t * fade.width * 0.6) % (fade.width + sz) - sz;
                            case "hagane": return x0 + t * Theme.px(140);
                            case "iso": return x0 + Math.sin(t * Math.PI * 4 + rnd(6) * 6) * Theme.px(26);
                            case "summit": return x0;
                            }
                            return x0 + Math.sin(t * Math.PI * 2 + rnd(6) * 6) * Theme.px(18);
                        }
                        y: {
                            switch (win.style) {
                            case "kiri": return y0 * 0.8;
                            case "hagane": return (y0 + t * fade.height * 0.55) % fade.height;
                            case "summit": return y0 * 0.85;
                            }
                            return fade.height - ((fade.height - y0) + t * fade.height * 0.7) % fade.height;     // rising
                        }
                        opacity: {
                            switch (win.style) {
                            case "kiri": return 0.05 + 0.04 * Math.sin(t * Math.PI);
                            case "summit": return 0.25 + 0.6 * Math.abs(Math.sin(t * Math.PI));
                            case "hagane": return 0.9 * (1 - t);
                            }
                            return Math.sin(t * Math.PI) * (0.4 + 0.5 * rnd(7));
                        }

                        Rectangle {
                            visible: win.style !== "hagane"
                            width: pt.sz; height: pt.sz; radius: width / 2
                            color: win.style === "summit" ? Theme.hi : win.style === "kiri" ? Theme.fg : (pt.index % 3 === 0 ? Theme.accent2 : Theme.accent)
                            layer.enabled: win.style === "kiri"
                            layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 64 }
                        }
                        // hagane: short slanted spark streaks
                        Rectangle {
                            visible: win.style === "hagane"
                            width: Theme.px(1.2); height: Theme.px(10 + 14 * pt.rnd(8))
                            rotation: -14
                            gradient: Gradient {
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: pt.index % 4 === 0 ? Theme.hi : Theme.accent }
                            }
                        }
                    }
                }

                // washi grain over everything, it also dries the brush edges of the kanji
                Image {
                    anchors.fill: parent
                    source: Quickshell.shellPath("assets/grain.png")
                    fillMode: Image.Tile
                    opacity: 0.16
                    smooth: false
                }

                // the time, small and quiet
                Column {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.1 }
                    spacing: Theme.px(6)
                    opacity: 0.75
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(Dev.clockDate, "HH : mm")
                        color: Theme.dim
                        font.family: Theme.head; font.pixelSize: Theme.px(26)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Dev.clockDate.toLocaleDateString(Qt.locale("de_DE"), "dddd  ·  d. MMMM")
                        color: Theme.mute
                        font.family: "Inter"; font.pixelSize: Theme.px(12)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.AllButtons
                    property point last: Qt.point(-1, -1)
                    onPositionChanged: (m) => {
                        // a real move, not the first report of where the cursor already is
                        if (last.x >= 0 && win.armed && (Math.abs(m.x - last.x) + Math.abs(m.y - last.y)) > 6) Ui.saver = false;
                        last = Qt.point(m.x, m.y);
                    }
                    onPressed: if (win.armed) Ui.saver = false
                    onWheel: if (win.armed) Ui.saver = false
                }
            }
        }
    }
}
