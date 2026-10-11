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
            Item {
                width: Theme.px(28); height: Theme.px(26)
                anchors.verticalCenter: parent.verticalCenter
                Image { anchors.centerIn: parent; width: Theme.px(24); height: width; source: "file://" + Theme.logo; sourceSize: Qt.size(width * 2, height * 2); smooth: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            ModFan { anchors.verticalCenter: parent.verticalCenter }
            ModCpu { anchors.verticalCenter: parent.verticalCenter }
            ModAgent { anchors.verticalCenter: parent.verticalCenter }
        }
        Island {
            x: (parent.width - width) / 2; y: Theme.barM; padX: Theme.px(4)
            ModClock { anchors.verticalCenter: parent.verticalCenter; showKanji: Theme.wsKanji; timeFont: Theme.body }
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
