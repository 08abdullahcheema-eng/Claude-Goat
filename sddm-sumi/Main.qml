import QtQuick 2.15
import QtQuick.Effects

// Sumi login: the wallpaper of the active theme, a glass card in the middle with the λ logo,
// the theme's colours and fonts. sumi-theme writes them to /var/lib/sumi on every theme switch.
Rectangle {
    id: root
    width: 1600
    height: 1000
    color: P.bg

    readonly property real s: Math.min(width / 1600, height / 1000)
    readonly property string stateDir: (config.stateDir && config.stateDir !== "") ? config.stateDir : "/var/lib/sumi"

    // palette of the active theme, Sumi when nothing has been written yet
    Loader { id: palLoader; source: "file://" + root.stateDir + "/palette.qml" }
    QtObject {
        id: P
        readonly property var t: palLoader.status === Loader.Ready ? palLoader.item : null
        readonly property string name: t ? t.name : "sumi"
        readonly property string label: t ? t.label : "Sumi"
        readonly property string kanji: t ? t.kanji : "墨"
        readonly property color bg: t ? t.bg : "#0f0f14"
        readonly property color bg1: t ? t.bg1 : "#16161d"
        readonly property color line: t ? t.line : "#2a2a37"
        readonly property color mute: t ? t.mute : "#54546d"
        readonly property color dim: t ? t.dim : "#727169"
        readonly property color fg: t ? t.fg : "#dcd7ba"
        readonly property color hi: t ? t.hi : "#f2ecd2"
        readonly property color accent: t ? t.accent : "#c8323a"
        readonly property color accent2: t ? t.accent2 : "#e46876"
        readonly property color error: t ? t.error : "#e46876"
        readonly property string head: t ? t.head : "Shippori Mincho"
        readonly property string body: t ? t.body : "JetBrainsMono Nerd Font"
        readonly property real radius: t ? t.radius : 22
    }

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: userModel.lastUser !== "" ? userModel.lastUser : "larp"
    property var userNames: []
    property bool busy: false
    property bool failed: false

    // only offer these sessions, Hyprland first
    property var wanted: []
    function pickSessions() {
        var list = []
        for (var i = 0; i < sessionRepeater.count; i++) {
            var it = sessionRepeater.itemAt(i)
            if (!it) continue
            if (it.sName === "Hyprland" || it.sName === "Plasma (Wayland)") list.push({ i: i, name: it.sName === "Plasma (Wayland)" ? "Plasma" : it.sName })
        }
        if (list.length === 0) for (var j = 0; j < sessionRepeater.count; j++) {
            var it2 = sessionRepeater.itemAt(j)
            if (it2) list.push({ i: j, name: it2.sName })
        }
        list.sort(function (a, b) { return a.name === "Hyprland" ? -1 : (b.name === "Hyprland" ? 1 : 0) })
        wanted = list
        if (list.length) root.sessionIndex = list[0].i
    }
    function sessionName() {
        for (var k = 0; k < wanted.length; k++) if (wanted[k].i === root.sessionIndex) return wanted[k].name
        return wanted.length ? wanted[0].name : "Session"
    }
    function nextSession() {
        if (wanted.length < 2) return
        var at = 0
        for (var k = 0; k < wanted.length; k++) if (wanted[k].i === root.sessionIndex) at = k
        root.sessionIndex = wanted[(at + 1) % wanted.length].i
    }
    function nextUser() {
        if (userNames.length < 2) return
        var at = userNames.indexOf(root.userName)
        root.userName = userNames[(at + 1) % userNames.length]
    }

    Repeater {
        id: sessionRepeater
        model: sessionModel
        delegate: Item { property string sName: model.name; visible: false }
        onCountChanged: root.pickSessions()
    }
    Repeater {
        id: userRepeater
        model: userModel
        delegate: Item { property string uName: model.name; visible: false }
        onCountChanged: {
            var l = []
            for (var i = 0; i < count; i++) { var it = itemAt(i); if (it) l.push(it.uName) }
            root.userNames = l
        }
    }

    function doLogin() {
        if (root.busy) return
        root.failed = false
        root.busy = true
        sddm.login(root.userName, password.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() { launchCover.opacity = 1 }
        function onLoginFailed() {
            root.busy = false
            root.failed = true
            password.text = ""
            shake.restart()
            password.forceActiveFocus()
        }
    }

    // ---------------- wallpaper ----------------
    Image {
        id: wallSrc
        anchors.fill: parent
        source: "file://" + root.stateDir + "/login-wall.jpg"
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 1920
        cache: false
        visible: false
        onStatusChanged: if (status === Image.Error) source = "wall.jpg"
    }
    MultiEffect {
        anchors.fill: parent
        source: wallSrc
        blurEnabled: true; blur: 0.25; blurMax: 32
        brightness: -0.32
        saturation: 0.05
    }

    // ---------------- clock ----------------
    Column {
        x: 56 * root.s; y: 46 * root.s
        spacing: 2 * root.s
        Text { id: clock; color: P.hi; font.family: P.head; font.pixelSize: 68 * root.s; font.weight: Font.Bold }
        Text { id: dateText; x: 3 * root.s; color: P.fg; font.family: P.body; font.pixelSize: 16 * root.s; font.letterSpacing: 2.5 * root.s }
    }

    // ---------------- glass card ----------------
    Item {
        id: card
        width: 388 * root.s
        height: cardCol.implicitHeight + 64 * root.s
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10 * root.s
        transform: Translate { id: shakeT; x: 0 }

        // frosted glass: the wallpaper behind the card, blurred hard, cut to the rounded card
        Item {
            id: glass
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: glassMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            MultiEffect {
                x: -card.x; y: -card.y
                width: root.width; height: root.height
                source: wallSrc
                blurEnabled: true; blur: 1.0; blurMax: 64
                brightness: -0.42
                saturation: 0.15
            }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.28) }
        }
        Item {
            id: glassMask
            anchors.fill: parent
            layer.enabled: true
            visible: false
            Rectangle { anchors.fill: parent; radius: Math.min(P.radius, 24) * root.s; color: "black" }
        }
        Rectangle {
            anchors.fill: parent
            radius: Math.min(P.radius, 24) * root.s
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
        }

        Column {
            id: cardCol
            anchors { top: parent.top; topMargin: 38 * root.s; horizontalCenter: parent.horizontalCenter }
            spacing: 0

            // avatar: the λ logo in a ring of the accent
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96 * root.s; height: width
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 14 * root.s; height: width; radius: width / 2
                    color: "transparent"
                    border.width: 5 * root.s
                    border.color: Qt.rgba(0, 0, 0, 0.28)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: P.bg
                    border.width: 2 * root.s
                    border.color: P.accent
                }
                Image {
                    anchors.centerIn: parent
                    width: parent.width - 6 * root.s; height: width
                    source: "file://" + root.stateDir + "/logo.svg"
                    sourceSize.width: 256; sourceSize.height: 256
                    cache: false
                    onStatusChanged: if (status === Image.Error) source = "logo.svg"
                }
                MouseArea { anchors.fill: parent; cursorShape: root.userNames.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: { root.nextUser(); password.forceActiveFocus() } }
            }
            Item { width: 1; height: 16 * root.s }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                color: P.hi
                font.family: P.head
                font.pixelSize: 27 * root.s
                font.weight: Font.Bold
            }
            Item { width: 1; height: 22 * root.s }

            // password
            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 276 * root.s; height: 40 * root.s
                radius: Math.min(P.radius, 20) * root.s
                color: Qt.rgba(1, 1, 1, 0.07)
                border.width: Math.max(1, 1.5 * root.s)
                border.color: root.failed ? P.error : (password.activeFocus ? P.accent : Qt.rgba(P.accent.r, P.accent.g, P.accent.b, 0.7))
                TextInput {
                    id: password
                    anchors { left: parent.left; leftMargin: 16 * root.s; right: go.left; rightMargin: 8 * root.s; verticalCenter: parent.verticalCenter }
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    color: P.hi
                    selectionColor: P.accent
                    font.family: P.body
                    font.pixelSize: 13 * root.s
                    font.letterSpacing: 4 * root.s
                    focus: true
                    clip: true
                    Keys.onReturnPressed: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()
                }
                Text {
                    anchors { left: password.left; verticalCenter: parent.verticalCenter }
                    visible: password.text.length === 0
                    text: root.failed ? "falsches Passwort" : "Passwort"
                    color: root.failed ? P.error : P.dim
                    font.family: P.body
                    font.pixelSize: 13 * root.s
                }
                Text {
                    id: go
                    anchors { right: parent.right; rightMargin: 14 * root.s; verticalCenter: parent.verticalCenter }
                    text: root.busy ? "…" : "➜"
                    color: gm.containsMouse ? P.hi : P.accent
                    font.pixelSize: 15 * root.s
                    MouseArea { id: gm; anchors.fill: parent; anchors.margins: -8 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                }
            }
            Item { width: 1; height: 18 * root.s }
            // session and keyboard layout, click to change
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14 * root.s
                Text {
                    text: root.sessionName().toUpperCase()
                    color: sm.containsMouse ? P.hi : P.dim
                    font.family: P.body; font.pixelSize: 10.5 * root.s; font.letterSpacing: 2.5 * root.s
                    MouseArea { id: sm; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.nextSession(); password.forceActiveFocus() } }
                }
                Text { text: P.kanji; color: P.accent; font.family: "Noto Serif CJK JP"; font.pixelSize: 11 * root.s }
                Text {
                    text: { var l = keyboard.layouts[keyboard.currentLayout]; return l ? l.shortName.toUpperCase() : "DE" }
                    color: km.containsMouse ? P.hi : P.dim
                    font.family: P.body; font.pixelSize: 10.5 * root.s; font.letterSpacing: 2.5 * root.s
                    MouseArea {
                        id: km; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length; password.forceActiveFocus() }
                    }
                }
            }
        }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeT; property: "x"; to: -12 * root.s; duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: 12 * root.s; duration: 70 }
            NumberAnimation { target: shakeT; property: "x"; to: -7 * root.s; duration: 60 }
            NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
        }
    }

    // ---------------- bottom: host on the left, sleep / restart / power on the right ----------------
    Text {
        anchors { left: parent.left; leftMargin: 58 * root.s; bottom: parent.bottom; bottomMargin: 46 * root.s }
        text: (sddm.hostName || "nixos") + "  ·  " + P.label.toUpperCase()
        color: P.dim; font.family: P.body; font.pixelSize: 12 * root.s; font.letterSpacing: 2 * root.s
    }
    Row {
        anchors { right: parent.right; rightMargin: 50 * root.s; bottom: parent.bottom; bottomMargin: 40 * root.s }
        spacing: 20 * root.s
        Repeater {
            model: sddm.canSuspend ? ["sleep", "reboot", "power"] : ["reboot", "power"]
            delegate: Item {
                width: 26 * root.s; height: width
                Canvas {
                    id: ic
                    anchors.fill: parent
                    property color c: modelData === "power" ? P.accent : (pa.containsMouse ? P.hi : P.fg)
                    onCChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        var w = width, cx = w / 2, cy = w / 2 + w * 0.04, r = w * 0.34
                        ctx.strokeStyle = ic.c; ctx.lineWidth = Math.max(1.4, w * 0.08); ctx.lineCap = "round"; ctx.lineJoin = "round"
                        ctx.beginPath()
                        if (modelData === "power") {
                            ctx.arc(cx, cy, r, -Math.PI / 2 + 0.6, 1.5 * Math.PI - 0.6, false)
                            ctx.moveTo(cx, cy - r * 1.25); ctx.lineTo(cx, cy - r * 0.3)
                        } else if (modelData === "sleep") {
                            ctx.arc(cx, cy, r, 0.45 * Math.PI, 1.85 * Math.PI, false)
                            ctx.arc(cx + r * 0.55, cy - r * 0.35, r * 0.78, 1.62 * Math.PI, 0.72 * Math.PI, true)
                        } else {
                            var e = 1.5 * Math.PI - 0.15
                            ctx.arc(cx, cy, r, -Math.PI / 2 + 0.75, e, false)
                            var px = cx + r * Math.cos(e), py = cy + r * Math.sin(e)
                            var dx = -Math.sin(e), dy = Math.cos(e), L = w * 0.24
                            ctx.moveTo(px, py); ctx.lineTo(px - L * (dx * Math.cos(0.6) - dy * Math.sin(0.6)), py - L * (dx * Math.sin(0.6) + dy * Math.cos(0.6)))
                            ctx.moveTo(px, py); ctx.lineTo(px - L * (dx * Math.cos(-0.6) - dy * Math.sin(-0.6)), py - L * (dx * Math.sin(-0.6) + dy * Math.cos(-0.6)))
                        }
                        ctx.stroke()
                    }
                }
                MouseArea {
                    id: pa; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: modelData === "power" ? sddm.powerOff() : (modelData === "sleep" ? sddm.suspend() : sddm.reboot())
                }
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            clock.text = Qt.formatTime(d, "hh:mm")
            var wd = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"][d.getDay()]
            var mo = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"][d.getMonth()]
            dateText.text = wd + ", " + d.getDate() + ". " + mo
        }
    }

    // shown after a successful login, until Hyprland takes over
    Rectangle {
        id: launchCover
        anchors.fill: parent
        color: P.bg
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 350 } }
        Text {
            anchors.centerIn: parent
            text: P.kanji
            color: P.accent
            font.family: "Noto Serif CJK JP"
            font.pixelSize: 54 * root.s
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: launchCover.visible
                NumberAnimation { to: 0.35; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
    }

    Component.onCompleted: { password.forceActiveFocus(); Qt.callLater(root.pickSessions) }
}
