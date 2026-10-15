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
            // the saver never takes the keyboard: hypridle sees any key or mouse move and hides it
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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
                // yoru: rain streaks falling through neon light   koyo: maple leaves drifting down
                // hotaru: fireflies wandering and pulsing           shinkai: marine snow rising slowly
                // tsuki: stars twinkling out of step
                Repeater {
                    model: win.style === "tsuki" ? 90 : win.style === "yoru" ? 70 : win.style === "hotaru" ? 36 : 42
                    delegate: Item {
                        id: pt
                        required property int index
                        // a fixed pseudo random sequence per particle
                        function rnd(k) { const v = Math.sin((pt.index + 1) * 12.9898 + k * 78.233) * 43758.5453; return v - Math.floor(v); }
                        readonly property real x0: rnd(1) * fade.width
                        readonly property real y0: rnd(2) * fade.height
                        readonly property real sz: win.style === "tsuki" ? Theme.px(1 + 2 * rnd(3))
                                                  : win.style === "koyo" ? Theme.px(7 + 7 * rnd(3))
                                                  : win.style === "hotaru" ? Theme.px(3 + 3 * rnd(3))
                                                  : Theme.px(1.5 + 3 * rnd(3))
                        readonly property int life: win.style === "yoru" ? 900 + 900 * rnd(4)
                                                  : win.style === "koyo" ? 12000 + 9000 * rnd(4)
                                                  : win.style === "hotaru" ? 14000 + 12000 * rnd(4)
                                                  : win.style === "tsuki" ? 2400 + 4000 * rnd(4)
                                                  : 16000 + 12000 * rnd(4)
                        property real t: rnd(5)
                        NumberAnimation on t { running: Ui.saver; loops: Animation.Infinite; from: 0; to: 1; duration: pt.life }

                        x: {
                            switch (win.style) {
                            case "yoru": return x0 - t * Theme.px(60);
                            case "koyo": return x0 + Math.sin(t * Math.PI * 3 + rnd(6) * 6) * Theme.px(60) + t * Theme.px(80);
                            case "hotaru": return x0 + Math.sin(t * Math.PI * 2 * (1 + rnd(8)) + rnd(6) * 6) * Theme.px(120);
                            case "tsuki": return x0;
                            }
                            return x0 + Math.sin(t * Math.PI * 2 + rnd(6) * 6) * Theme.px(18);
                        }
                        y: {
                            switch (win.style) {
                            case "yoru": return (y0 + t * fade.height) % fade.height;
                            case "koyo": return (y0 + t * fade.height * 0.9) % (fade.height + Theme.px(40)) - Theme.px(20);
                            case "hotaru": return fade.height * 0.35 + y0 * 0.6 + Math.cos(t * Math.PI * 2 * (1 + rnd(9)) + rnd(7) * 6) * Theme.px(60);
                            case "tsuki": return y0 * 0.85;
                            }
                            return fade.height - ((fade.height - y0) + t * fade.height * 0.7) % fade.height;     // rising
                        }
                        opacity: {
                            switch (win.style) {
                            case "yoru": return 0.25 + 0.35 * rnd(7);
                            case "koyo": return 0.55 + 0.35 * rnd(7);
                            case "hotaru": return Math.max(0, Math.sin(t * Math.PI * 6 + rnd(7) * 6)) * (0.6 + 0.4 * rnd(8));
                            case "tsuki": return 0.25 + 0.6 * Math.abs(Math.sin(t * Math.PI));
                            }
                            return Math.sin(t * Math.PI) * (0.4 + 0.5 * rnd(7));
                        }

                        // dots: marine snow, stars, fireflies (with a soft glow)
                        Rectangle {
                            visible: win.style === "shinkai" || win.style === "tsuki" || win.style === "hotaru"
                            width: pt.sz; height: pt.sz; radius: width / 2
                            color: win.style === "tsuki" ? Theme.hi : win.style === "hotaru" ? Qt.lighter(Theme.accent, 1.25) : (pt.index % 3 === 0 ? Theme.accent2 : Theme.accent)
                        }
                        Rectangle {
                            visible: win.style === "hotaru"
                            x: -pt.sz * 2.5; y: -pt.sz * 2.5
                            width: pt.sz * 6; height: width; radius: width / 2
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                        }
                        // yoru: rain streaks, some catching the neon
                        Rectangle {
                            visible: win.style === "yoru"
                            width: Theme.px(1.2); height: Theme.px(18 + 22 * pt.rnd(8))
                            rotation: 8
                            gradient: Gradient {
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: pt.index % 5 === 0 ? Theme.accent : pt.index % 7 === 0 ? Theme.accent2 : Qt.rgba(0.85, 0.88, 1, 0.8) }
                            }
                        }
                        // koyo: a small five-pointed maple leaf, turning as it falls
                        Text {
                            visible: win.style === "koyo"
                            text: "✦"
                            rotation: pt.t * 720 * (pt.rnd(9) > 0.5 ? 1 : -1)
                            color: pt.index % 3 === 0 ? Theme.accent2 : Theme.accent
                            font.pixelSize: pt.sz * 2
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
