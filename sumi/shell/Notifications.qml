import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Notification daemon + popups in the top-right corner.
Scope {
    id: root

    property var demoList: []

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true
        onNotification: (n) => {
            if (Ui.dnd && n.urgency !== NotificationUrgency.Critical) { n.expire(); return; }
            n.tracked = true;
        }
    }

    Component.onCompleted: {
        if (!Theme.demo) return;
        demoList = [
            { appName: "claude · nixos-config", summary: "Waiting for your input", body: "Build finished. Apply with nixos-rebuild switch?", accent: "gold", icon: "agent", actions: [{ text: "Switch", primary: true }, { text: "Later" }], time: "now" },
            { appName: "Discord", summary: "Jonas", body: "kommst du heute noch online? cs2 um 8", appIcon: "discord", time: "2 m" },
            { appName: "power", summary: "Charging · 84%", body: "Full in 35 min.", accent: "green", icon: "plug", time: "6 m" }
        ];
    }

    readonly property var items: Theme.demo ? demoList : server.trackedNotifications.values.slice().reverse().slice(0, 4)

    PanelWindow {
        id: win
        visible: root.items.length > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; right: true }
        margins.top: Theme.px(8)
        margins.right: Theme.px(8)
        implicitWidth: Theme.px(380)
        implicitHeight: Math.max(1, col.implicitHeight)
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "sumi-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: col
            width: parent.width
            spacing: Theme.px(8)
            Repeater {
                model: root.items
                delegate: Rectangle {
                    id: nd
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool crit: !Theme.demo && n.urgency === NotificationUrgency.Critical
                    readonly property color stripe: crit ? Theme.accent : (n.accent === "gold" || (n.appName || "").toLowerCase().indexOf("claude") >= 0 ? Theme.gold : (n.accent === "green" ? Theme.green : Theme.line2))
                    width: col.width
                    height: body.implicitHeight + Theme.px(26)
                    radius: Theme.px(9)
                    color: Theme.panelBg
                    border.width: 1; border.color: Theme.line2

                    Rectangle { width: Theme.px(3); height: parent.height - Theme.px(16); y: Theme.px(8); x: 0; radius: 2; color: nd.stripe }

                    Timer {
                        running: !Theme.demo && !nd.crit && !hover.containsMouse
                        interval: (nd.n.expireTimeout > 0 ? nd.n.expireTimeout : 6000)
                        onTriggered: nd.n.expire()
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (m) => {
                            if (Theme.demo) return;
                            const def = (nd.n.actions || []).find(a => a.identifier === "default");
                            if (m.button === Qt.LeftButton && def) def.invoke();
                            nd.n.dismiss();
                        }
                    }

                    Row {
                        id: body
                        x: Theme.px(14); y: Theme.px(13)
                        width: parent.width - Theme.px(28)
                        spacing: Theme.px(12)
                        Item {
                            width: Theme.px(28); height: Theme.px(28)
                            Image {
                                id: img
                                anchors.fill: parent
                                visible: status === Image.Ready
                                source: nd.n.image ? nd.n.image : (nd.n.appIcon ? Quickshell.iconPath(nd.n.appIcon, true) : "")
                                sourceSize: Qt.size(56, 56)
                                fillMode: Image.PreserveAspectCrop
                            }
                            Icon { visible: !img.visible; anchors.centerIn: parent; name: nd.n.icon || "bell"; color: nd.stripe === Theme.line2 ? Theme.dim : nd.stripe; size: Theme.px(18) }
                        }
                        Column {
                            width: parent.width - Theme.px(40)
                            spacing: Theme.px(3)
                            Item {
                                width: parent.width; height: Theme.px(14)
                                T { text: nd.n.appName || ""; color: Theme.mute; font.pixelSize: Theme.px(10); width: parent.width - Theme.px(40); elide: Text.ElideRight }
                                T { anchors.right: parent.right; text: nd.n.time || "now"; color: Theme.mute; font.pixelSize: Theme.px(10) }
                            }
                            T { width: parent.width; text: nd.n.summary || ""; color: Theme.hi; font.pixelSize: Theme.px(13.5); elide: Text.ElideRight }
                            T { width: parent.width; text: nd.n.body || ""; visible: text !== ""; color: Theme.dim; font.pixelSize: Theme.px(11.5); wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Row {
                                visible: (nd.n.actions || []).filter(a => a.identifier !== "default").length > 0 || (Theme.demo && nd.n.actions)
                                spacing: Theme.px(6)
                                topPadding: Theme.px(6)
                                Repeater {
                                    model: Theme.demo ? (nd.n.actions || []) : (nd.n.actions || []).filter(a => a.identifier !== "default")
                                    delegate: Btn {
                                        required property var modelData
                                        required property int index
                                        text: modelData.text
                                        primary: Theme.demo ? !!modelData.primary : index === 0
                                        onClicked: { if (!Theme.demo) { modelData.invoke(); nd.n.dismiss(); } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
