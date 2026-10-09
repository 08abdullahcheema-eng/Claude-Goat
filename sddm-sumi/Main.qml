import QtQuick 2.15

// Sumi login: glass panel on the left, wallpaper on the right.
Rectangle {
    id: root
    width: 1600
    height: 1000
    color: "#0f0f14"

    // designed on a 1600x1000 canvas
    readonly property real s: Math.min(width / 1600, height / 1000)
    readonly property color bg: "#0f0f14"
    readonly property color bg1: "#16161d"
    readonly property color bg2: "#1d1d26"
    readonly property color line: "#2a2a37"
    readonly property color line2: "#363646"
    readonly property color mute: "#54546d"
    readonly property color dim: "#727169"
    readonly property color fg: "#dcd7ba"
    readonly property color hi: "#f2ecd2"
    readonly property color red: "#c8323a"
    readonly property color red2: "#e46876"
    readonly property color gold: "#e6c384"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string jp: "Noto Serif CJK JP"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: userModel.lastUser !== "" ? userModel.lastUser : "larp"
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
        if (!wanted.length) return
        var at = 0
        for (var k = 0; k < wanted.length; k++) if (wanted[k].i === root.sessionIndex) at = k
        root.sessionIndex = wanted[(at + 1) % wanted.length].i
    }

    // hidden helper to read session names (sessionModel is a C++ model)
    Repeater {
        id: sessionRepeater
        model: sessionModel
        delegate: Item { property string sName: model.name; visible: false }
        onCountChanged: root.pickSessions()
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

    Image {
        anchors.fill: parent
        source: "wall.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: false
    }

    // ---------------- panel ----------------
    Rectangle {
        id: panel
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 475 * root.s
        color: "#f20d0d12"
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: root.line2 }

        Item {
            id: inner
            anchors { fill: parent; leftMargin: 62 * root.s; rightMargin: 62 * root.s; topMargin: 69 * root.s; bottomMargin: 56 * root.s }

            Image {
                id: logo
                width: 69 * root.s; height: width
                source: "logo.svg"
                sourceSize.width: width * 2
                sourceSize.height: height * 2
            }
            Text {
                id: hello
                anchors { top: logo.bottom; topMargin: 25 * root.s }
                text: "おかえり"
                color: root.hi
                font.family: root.jp
                font.pixelSize: 34 * root.s
            }
            Text {
                id: sub
                anchors { top: hello.bottom; topMargin: 4 * root.s }
                text: "welcome back · " + (sddm.hostName || "helios")
                color: root.dim
                font.family: root.mono
                font.pixelSize: 13 * root.s
            }

            // users
            Text {
                id: userLbl
                anchors { top: sub.bottom; topMargin: 44 * root.s }
                text: "USER"
                color: root.mute; font.family: root.mono; font.pixelSize: 9.5 * root.s; font.letterSpacing: 2.5 * root.s
            }
            Column {
                id: users
                anchors { top: userLbl.bottom; topMargin: 8 * root.s; left: parent.left; right: parent.right; leftMargin: -12 * root.s }
                spacing: 2 * root.s
                Repeater {
                    model: userModel
                    delegate: Rectangle {
                        readonly property bool on: model.name === root.userName
                        width: users.width
                        height: 54 * root.s
                        radius: 6 * root.s
                        color: on ? root.bg2 : (um.containsMouse ? "#801d1d26" : "transparent")
                        Rectangle { visible: parent.on; width: 2.5 * root.s; height: parent.height; color: root.red }
                        Rectangle {
                            id: av
                            x: 12 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34 * root.s; height: width; radius: width / 2
                            color: root.bg1; border.width: 1; border.color: root.line2
                            Image { visible: parent.parent.on; anchors.centerIn: parent; width: parent.width * 0.82; height: width; source: "logo.svg"; sourceSize.width: 96; sourceSize.height: 96 }
                            Text { visible: !parent.parent.on; anchors.centerIn: parent; text: (model.name || "?").charAt(0).toUpperCase(); color: root.dim; font.family: root.mono; font.pixelSize: 14 * root.s }
                        }
                        Column {
                            anchors { left: av.right; leftMargin: 12 * root.s; verticalCenter: parent.verticalCenter }
                            spacing: 1 * root.s
                            Text { text: model.name; color: parent.parent.on ? root.hi : root.dim; font.family: root.mono; font.pixelSize: 15 * root.s }
                            Text { text: (model.realName && model.realName !== model.name) ? model.realName : (parent.parent.on ? "last user" : "user"); color: root.mute; font.family: root.mono; font.pixelSize: 10 * root.s }
                        }
                        MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.userName = model.name; password.forceActiveFocus() } }
                    }
                }
            }

            // password
            Text {
                id: pwLbl
                anchors { top: users.bottom; topMargin: 28 * root.s }
                text: "PASSWORD"
                color: root.mute; font.family: root.mono; font.pixelSize: 9.5 * root.s; font.letterSpacing: 2.5 * root.s
            }
            Rectangle {
                id: field
                anchors { top: pwLbl.bottom; topMargin: 9 * root.s; left: parent.left; right: parent.right }
                height: 45 * root.s
                radius: 6 * root.s
                color: root.bg
                border.width: Math.max(1, 1.5 * root.s)
                border.color: root.failed ? root.red2 : root.red
                transform: Translate { id: shakeT; x: 0 }

                TextInput {
                    id: password
                    anchors { left: parent.left; leftMargin: 14 * root.s; right: enterKey.left; rightMargin: 10 * root.s; verticalCenter: parent.verticalCenter }
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.hi
                    selectionColor: root.red
                    font.family: root.mono
                    font.pixelSize: 17 * root.s
                    font.letterSpacing: 3 * root.s
                    focus: true
                    clip: true
                    Keys.onReturnPressed: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()
                }
                Text {
                    anchors { left: password.left; verticalCenter: parent.verticalCenter }
                    visible: password.text.length === 0
                    text: root.failed ? "wrong password, try again" : "password"
                    color: root.failed ? root.red2 : root.mute
                    font.family: root.mono
                    font.pixelSize: 13 * root.s
                }
                Rectangle {
                    id: enterKey
                    anchors { right: parent.right; rightMargin: 9 * root.s; verticalCenter: parent.verticalCenter }
                    width: 30 * root.s; height: 24 * root.s; radius: 4 * root.s
                    color: ek.containsMouse ? root.red : "transparent"
                    border.width: 1; border.color: root.line2
                    Text { anchors.centerIn: parent; text: root.busy ? "…" : "↵"; color: root.dim; font.family: root.mono; font.pixelSize: 12 * root.s }
                    MouseArea { id: ek; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeT; property: "x"; to: -10 * root.s; duration: 50 }
                    NumberAnimation { target: shakeT; property: "x"; to: 10 * root.s; duration: 70 }
                    NumberAnimation { target: shakeT; property: "x"; to: -6 * root.s; duration: 60 }
                    NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
                }
            }

            // session + keyboard
            Row {
                id: opts
                anchors { top: field.bottom; topMargin: 12 * root.s; left: parent.left; right: parent.right }
                spacing: 9 * root.s
                Rectangle {
                    width: opts.width - kb.width - opts.spacing
                    height: 38 * root.s; radius: 6 * root.s
                    color: sm.containsMouse ? root.bg2 : "transparent"
                    border.width: 1; border.color: root.line2
                    Canvas {
                        id: monIcon
                        x: 12 * root.s; anchors.verticalCenter: parent.verticalCenter
                        width: 15 * root.s; height: width
                        onPaint: {
                            var c = getContext("2d"); c.reset()
                            var w = width
                            c.strokeStyle = root.dim; c.lineWidth = Math.max(1, w * 0.09); c.lineJoin = "round"
                            c.strokeRect(w * 0.08, w * 0.14, w * 0.84, w * 0.56)
                            c.beginPath(); c.moveTo(w * 0.32, w * 0.9); c.lineTo(w * 0.68, w * 0.9); c.moveTo(w * 0.5, w * 0.7); c.lineTo(w * 0.5, w * 0.9); c.stroke()
                        }
                    }
                    Text { anchors { left: monIcon.right; leftMargin: 10 * root.s; verticalCenter: parent.verticalCenter } text: root.sessionName(); color: root.fg; font.family: root.mono; font.pixelSize: 13 * root.s }
                    Text { anchors { right: parent.right; rightMargin: 12 * root.s; verticalCenter: parent.verticalCenter } text: root.wanted.length > 1 ? "⇄" : ""; color: root.mute; font.family: root.mono; font.pixelSize: 13 * root.s }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.nextSession(); password.forceActiveFocus() } }
                }
                Rectangle {
                    id: kb
                    width: 69 * root.s; height: 38 * root.s; radius: 6 * root.s
                    color: km.containsMouse ? root.bg2 : "transparent"
                    border.width: 1; border.color: root.line2
                    Text {
                        anchors.centerIn: parent
                        text: {
                            var l = keyboard.layouts[keyboard.currentLayout]
                            return l ? l.shortName.toUpperCase() : "DE"
                        }
                        color: root.fg; font.family: root.mono; font.pixelSize: 13 * root.s
                    }
                    MouseArea {
                        id: km; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length; password.forceActiveFocus() }
                    }
                }
            }

            // bottom: power buttons + clock
            Row {
                anchors { left: parent.left; bottom: parent.bottom }
                spacing: 10 * root.s
                Repeater {
                    model: ["reboot", "power"]
                    delegate: Rectangle {
                        width: 39 * root.s; height: width; radius: 6 * root.s
                        color: pa.containsMouse ? root.bg2 : "transparent"
                        border.width: 1; border.color: root.line2
                        Canvas {
                            id: ic
                            anchors.centerIn: parent
                            width: 17 * root.s; height: width
                            property color c: modelData === "power" ? root.red : root.dim
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                var w = width, cx = w / 2, cy = w / 2 + w * 0.05, r = w * 0.36
                                ctx.strokeStyle = ic.c; ctx.lineWidth = Math.max(1.4, w * 0.1); ctx.lineCap = "round"; ctx.lineJoin = "round"
                                ctx.beginPath()
                                if (modelData === "power") {
                                    ctx.arc(cx, cy, r, -Math.PI / 2 + 0.6, 1.5 * Math.PI - 0.6, false)
                                    ctx.moveTo(cx, cy - r * 1.25); ctx.lineTo(cx, cy - r * 0.3)
                                } else {
                                    var e = 1.5 * Math.PI - 0.15
                                    ctx.arc(cx, cy, r, -Math.PI / 2 + 0.75, e, false)
                                    var px = cx + r * Math.cos(e), py = cy + r * Math.sin(e)
                                    var dx = -Math.sin(e), dy = Math.cos(e), L = w * 0.26
                                    ctx.moveTo(px, py); ctx.lineTo(px - L * (dx * Math.cos(0.6) - dy * Math.sin(0.6)), py - L * (dx * Math.sin(0.6) + dy * Math.cos(0.6)))
                                    ctx.moveTo(px, py); ctx.lineTo(px - L * (dx * Math.cos(-0.6) - dy * Math.sin(-0.6)), py - L * (dx * Math.sin(-0.6) + dy * Math.cos(-0.6)))
                                }
                                ctx.stroke()
                            }
                        }
                        MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData === "power" ? sddm.powerOff() : sddm.reboot() }
                    }
                }
            }
            Column {
                anchors { right: parent.right; bottom: parent.bottom }
                spacing: 2 * root.s
                Text { id: clock; anchors.right: parent.right; color: root.hi; font.family: root.mono; font.pixelSize: 21 * root.s }
                Text { id: dateText; anchors.right: parent.right; color: root.mute; font.family: root.mono; font.pixelSize: 11 * root.s }
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            clock.text = Qt.formatTime(d, "hh:mm")
            var wd = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"][d.getDay()]
            var mo = ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"][d.getMonth()]
            dateText.text = wd + " " + Qt.formatDate(d, "dd") + " " + mo + " · " + ["日", "月", "火", "水", "木", "金", "土"][d.getDay()]
        }
    }

    // shown after a successful login, until Hyprland takes over
    Rectangle {
        id: launchCover
        anchors.fill: parent
        color: root.bg
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Image { anchors.fill: parent; source: "wall.jpg"; fillMode: Image.PreserveAspectCrop; smooth: true }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.62
            text: "起動中"
            color: root.hi
            font.family: root.jp
            font.pixelSize: 22 * root.s
            font.letterSpacing: 10 * root.s
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
