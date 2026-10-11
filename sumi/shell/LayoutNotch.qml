import QtQuick
import Quickshell

// Notch: one compact tab hanging from the middle of the top edge.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "top"
        Rectangle {
            id: tab
            anchors.horizontalCenter: parent.horizontalCenter
            y: -Theme.px(14)
            height: parent.height + Theme.px(14) - Theme.px(4)
            width: row.implicitWidth + Theme.px(36)
            radius: Theme.px(16)
            color: Theme.barBg
            border.width: 1
            border.color: Theme.line
            Row {
                id: row
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(3) }
                height: BarStyle.itemH
                spacing: Theme.px(4)
                Item {
                    width: Theme.px(26); height: parent.height
                    Image { anchors.centerIn: parent; width: Theme.px(20); height: width; source: "file://" + Theme.logo; sourceSize: Qt.size(width * 2, height * 2); smooth: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
                }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
                Sep { anchors.verticalCenter: parent.verticalCenter }
                ModClock { anchors.verticalCenter: parent.verticalCenter; timeFont: Theme.head; timeSize: Theme.px(16); timeWeight: Font.Bold }
                Sep { anchors.verticalCenter: parent.verticalCenter }
                ModFan { anchors.verticalCenter: parent.verticalCenter }
                ModCpu { anchors.verticalCenter: parent.verticalCenter }
                ModAgent { anchors.verticalCenter: parent.verticalCenter }
                ModNet { anchors.verticalCenter: parent.verticalCenter }
                ModBt { anchors.verticalCenter: parent.verticalCenter }
                ModVol { anchors.verticalCenter: parent.verticalCenter }
                ModMic { anchors.verticalCenter: parent.verticalCenter }
                ModBat { anchors.verticalCenter: parent.verticalCenter }
                ModPower { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
