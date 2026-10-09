import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit

// Polkit agent: themed password prompt for admin actions.
Scope {
    id: root
    readonly property bool demoShow: Theme.demo && Quickshell.env("SUMI_DEMO_POLKIT") === "1"
    readonly property var flow: agent.flow
    readonly property bool active: demoShow || (agent.isActive && flow !== null)
    property bool failed: false

    PolkitAgent {
        id: agent
    }

    component KV: Row {
        property string k: ""
        property string v: ""
        property color c: Theme.fg
        width: parent ? parent.width : 0
        spacing: Theme.px(10)
        T { text: parent.k; color: Theme.mute; width: Theme.px(90); font.pixelSize: Theme.px(12) }
        T { text: parent.v; color: parent.c; font.pixelSize: Theme.px(12); width: parent.width - Theme.px(100); elide: Text.ElideMiddle }
    }
    Connections {
        target: root.flow
        function onAuthenticationFailed() { root.failed = true; shake.restart(); pw.text = ""; }
        function onAuthenticationSucceeded() { root.failed = false; pw.text = ""; }
        function onIsResponseRequiredChanged() { if (root.flow?.isResponseRequired) pw.forceActiveFocus(); }
    }
    onActiveChanged: { failed = false; pw.text = ""; if (active) Qt.callLater(() => pw.forceActiveFocus()); }

    function submit() {
        if (demoShow || !flow) return;
        flow.submit(pw.text);
    }
    function cancel() {
        if (demoShow || !flow) return;
        flow.cancelAuthenticationRequest();
    }

    PanelWindow {
        visible: root.active
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "sumi-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle { anchors.fill: parent; color: Theme.scrim }

        Card {
            id: dlg
            width: Theme.px(560)
            anchors.centerIn: parent
            accentBorder: Theme.accent
            pad: Theme.px(24)
            transform: Translate { id: tr; x: 0 }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: tr; property: "x"; to: -Theme.px(10); duration: 50 }
                NumberAnimation { target: tr; property: "x"; to: Theme.px(10); duration: 70 }
                NumberAnimation { target: tr; property: "x"; to: -Theme.px(6); duration: 60 }
                NumberAnimation { target: tr; property: "x"; to: 0; duration: 50 }
            }

            Column {
                width: parent.width
                spacing: Theme.px(18)

                Item {
                    width: parent.width; height: Theme.px(48)
                    Rectangle {
                        id: badge
                        width: Theme.px(48); height: width; radius: Theme.px(9)
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        border.width: 1; border.color: Theme.accent
                        Icon { anchors.centerIn: parent; name: "shield"; color: Theme.accent; size: Theme.px(24) }
                    }
                    Column {
                        anchors { left: badge.right; leftMargin: Theme.px(16); right: kanji.left; rightMargin: Theme.px(8); verticalCenter: parent.verticalCenter }
                        spacing: Theme.px(3)
                        T { text: "Authentication required"; color: Theme.hi; font.pixelSize: Theme.px(18) }
                        T {
                            width: parent.width; elide: Text.ElideRight
                            text: root.demoShow ? "nixos-rebuild wants to change the system" : (root.flow?.message ?? "")
                            color: Theme.dim; font.pixelSize: Theme.px(12)
                        }
                    }
                    Text { id: kanji; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "認証"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(19) }
                }

                Rectangle {
                    width: parent.width
                    height: det.implicitHeight + Theme.px(24)
                    radius: Theme.px(6); color: Theme.bg; border.width: 1; border.color: Theme.line
                    Column {
                        id: det
                        x: Theme.px(14); y: Theme.px(12)
                        width: parent.width - Theme.px(28)
                        spacing: Theme.px(4)
                        KV { k: "action"; v: root.demoShow ? "org.freedesktop.policykit.exec" : (root.flow?.actionId ?? ""); c: Theme.gold }
                        KV { k: "message"; v: root.demoShow ? "Authentication is needed to run nixos-rebuild as root" : (root.flow?.message ?? ""); c: Theme.dim }
                        KV { k: "as user"; v: root.demoShow ? "larp" : (root.flow?.selectedIdentity?.displayName ?? root.flow?.selectedIdentity?.string ?? "") }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.px(12)
                    Image {
                        width: Theme.px(30); height: width
                        anchors.verticalCenter: parent.verticalCenter
                        source: "file://" + Theme.logo
                        sourceSize: Qt.size(64, 64)
                    }
                    Rectangle {
                        width: parent.width - Theme.px(42)
                        height: Theme.px(40); radius: Theme.px(7)
                        color: Theme.bg
                        border.width: Theme.px(1.5)
                        border.color: root.failed ? Theme.accent2 : Theme.accent
                        Icon { id: lk; name: "lock"; color: Theme.dim; size: Theme.px(14); anchors { left: parent.left; leftMargin: Theme.px(12); verticalCenter: parent.verticalCenter } }
                        TextInput {
                            id: pw
                            anchors { left: lk.right; leftMargin: Theme.px(10); right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                            echoMode: (root.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            color: Theme.hi; font.family: Theme.mono; font.pixelSize: Theme.px(15)
                            text: root.demoShow ? "password" : ""
                            onAccepted: root.submit()
                            Keys.onEscapePressed: root.cancel()
                            Text {
                                visible: !pw.text
                                text: root.failed ? "wrong password, try again" : ((root.flow?.inputPrompt ?? "password").replace(/:\s*$/, ""))
                                color: root.failed ? Theme.accent2 : Theme.mute
                                font.family: Theme.mono; font.pixelSize: Theme.px(13)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
                T {
                    visible: !root.demoShow && (root.flow?.supplementaryMessage ?? "") !== ""
                    text: root.flow?.supplementaryMessage ?? ""
                    color: (root.flow?.supplementaryIsError ?? false) ? Theme.accent2 : Theme.dim
                    font.pixelSize: Theme.px(11.5)
                    width: parent.width; wrapMode: Text.Wrap
                }
                Row {
                    anchors.right: parent.right
                    spacing: Theme.px(10)
                    Btn { text: "Cancel  esc"; onClicked: root.cancel() }
                    Btn { text: "Authenticate  ↵"; primary: true; onClicked: root.submit() }
                }
            }
        }
    }
}
