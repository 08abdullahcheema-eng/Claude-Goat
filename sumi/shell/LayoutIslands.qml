import QtQuick
import Quickshell

// Islands: three floating bubbles along the top (workspaces and stats, clock, controls).
Scope {
    id: lay
    required property var screenRef

    component Island: Rectangle {
        default property alias content: row.data
        property real padX: Theme.px(7)
        height: Theme.barH
        width: row.implicitWidth + padX * 2
        radius: Theme.px(11)
        color: Theme.barBg
        border.width: 1
        border.color: Theme.line
        Row { id: row; anchors.centerIn: parent; spacing: Theme.px(3) }
    }

    BarWindow {
        screen: lay.screenRef
        edge: "top"
        Island {
            x: Theme.px(10); y: Theme.barM
            Logo { anchors.verticalCenter: parent.verticalCenter; size: Theme.px(24) }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            ModFan { anchors.verticalCenter: parent.verticalCenter }
            ModCpu { anchors.verticalCenter: parent.verticalCenter }
            ModAgent { anchors.verticalCenter: parent.verticalCenter }
        }
        Island {
            id: mid
            x: (parent.width - width) / 2; y: Theme.barM; padX: Theme.px(4)
            ModClock { anchors.verticalCenter: parent.verticalCenter; showKanji: Theme.wsKanji; timeFont: Theme.head; timeSize: Theme.px(15) }
        }
        // ink: a short brush stroke of the accent under the clock
        Rectangle {
            visible: (Theme.p.barFx ?? "") === "ink"
            x: mid.x + mid.width / 2 - width / 2; y: mid.y + mid.height - height
            width: mid.width * 0.34; height: Theme.px(2); radius: height / 2
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Theme.accent } GradientStop { position: 1; color: "transparent" } }
        }
        Island {
            x: parent.width - width - Theme.px(10); y: Theme.barM
            ModNet { anchors.verticalCenter: parent.verticalCenter }
            ModBt { anchors.verticalCenter: parent.verticalCenter }
            ModVol { anchors.verticalCenter: parent.verticalCenter }
            ModMic { anchors.verticalCenter: parent.verticalCenter }
            ModDnd { anchors.verticalCenter: parent.verticalCenter }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            KbdLayout { anchors.verticalCenter: parent.verticalCenter }
            ModBat { anchors.verticalCenter: parent.verticalCenter }
            ModPower { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
