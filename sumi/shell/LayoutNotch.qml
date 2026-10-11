import QtQuick
import Quickshell
import QtQuick.Effects

// Notch: one compact tab hanging from the middle of the top edge.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "top"
        // lantern: warm light spilling out under the tab
        MultiEffect {
            visible: (Theme.p.barFx ?? "") === "lantern"
            anchors.fill: tab
            source: tab
            shadowEnabled: true; shadowColor: Theme.gold; shadowBlur: 1.0; shadowOpacity: 0.45; shadowVerticalOffset: Theme.px(3)
        }
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
            Rectangle {
                visible: (Theme.p.barFx ?? "") === "lantern"
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                width: parent.width * 0.7; height: Theme.px(1.5)
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Theme.gold } GradientStop { position: 1; color: "transparent" } }
            }
            Row {
                id: row
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(3) }
                height: BarStyle.itemH
                spacing: Theme.px(4)
                Logo { anchors.verticalCenter: parent.verticalCenter; size: Theme.px(20) }
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
