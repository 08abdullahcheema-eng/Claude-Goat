import QtQuick
import Quickshell

// Sumi: one floating strip of dark glass along the top. Seal and kanji workspaces on the left,
// time and date in the middle, the few status icons and a battery ring on the right.
// It shows no window titles or music, the desktop stays quiet.
Scope {
    id: lay
    required property var screenRef
    property bool preview: false        // a copy drawn above the theme picker

    BarWindow {
        screen: lay.screenRef
        preview: lay.preview
        edge: "top"
        Rectangle {
            id: strip
            x: Theme.px(10); y: Theme.barM
            width: parent.width - Theme.px(20); height: Theme.barH
            radius: Theme.px(10)
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.72)
            border.width: 1
            border.color: (Theme.p.barFx ?? "") === "neon" ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.07)
            // light along the upper edge of the glass
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: parent.radius; rightMargin: parent.radius; topMargin: 1 }
                height: 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.12) }
                    GradientStop { position: 1; color: "transparent" } }
            }

            Row {
                anchors { left: parent.left; leftMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(8)
                // the theme's seal (Sumi: the red hanko), opens the launcher
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.px(24); height: width
                    source: Quickshell.shellPath("assets/lock/avatar-" + Theme.name + ".png")
                    sourceSize: Qt.size(width * 2, height * 2)
                    smooth: true; mipmap: true
                    MouseArea { anchors.fill: parent; anchors.margins: -Theme.px(4); cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
                }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            }

            ModClock {
                id: clock
                anchors.centerIn: parent
                showKanji: false
                timeFont: Theme.head; timeSize: Theme.px(15)
                fontFamily: "Inter"; fontSize: Theme.px(12.5)
                activeStyle: "none"
            }
            // ink: a short brush stroke of the accent under the clock
            Rectangle {
                visible: (Theme.p.barFx ?? "") === "ink"
                anchors { horizontalCenter: clock.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(3) }
                width: clock.width * 0.45; height: Theme.px(2); radius: height / 2
                opacity: Ui.panel === "calendar" ? 1 : 0.55
                Behavior on opacity { NumberAnimation { duration: Theme.mMed } }
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Theme.accent } GradientStop { position: 1; color: "transparent" } }
            }

            Row {
                anchors { right: parent.right; rightMargin: Theme.px(4); verticalCenter: parent.verticalCenter }
                spacing: 0
                ModDnd { anchors.verticalCenter: parent.verticalCenter; visible: Ui.dnd }
                ModNet { anchors.verticalCenter: parent.verticalCenter; text: "" }
                ModBt { anchors.verticalCenter: parent.verticalCenter; text: "" }
                ModVol { anchors.verticalCenter: parent.verticalCenter; text: "" }
                ModBatRing { anchors.verticalCenter: parent.verticalCenter; showPct: true; ringSize: Theme.px(17); rowDirection: Qt.RightToLeft }
            }
        }
    }
}
