import QtQuick 2.15
import QtQuick.Effects

// Sumi login: the wallpaper of the active theme with slow motion over it (Ambient.qml), the
// theme's colours, fonts and motion. Sumi, Iso, Kiri and Hagane share the glass card, each
// with its own way of arriving, refusing and leaving; Summit has its own scene.
// sumi-theme writes the theme to /var/lib/sumi on every theme switch.
Rectangle {
    id: root
    width: 1600
    height: 1000
    color: pal.bg

    readonly property real s: Math.min(width / 1600, height / 1000)
    readonly property string stateDir: (config.stateDir && config.stateDir !== "") ? config.stateDir : "/var/lib/sumi"

    // palette of the active theme, Sumi when nothing has been written yet
    Loader { id: palLoader; source: "file://" + root.stateDir + "/palette.qml" }
    QtObject {
        id: pal
        readonly property var t: palLoader.status === Loader.Ready ? palLoader.item : null
        readonly property string name: t ? t.name : "yoru"
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

    // ---------------- motion of the theme ----------------
    // How the screen arrives, how it refuses a wrong password and how it leaves after login.
    //   sumi    ink: everything seeps in slowly, an ensō is brushed around the avatar, ink floods the screen
    //   iso     waves: the pieces roll up from below and overshoot, a wrong password wobbles, the tide rises
    //   kiri    fog: the scene condenses out of a blur, the card drifts, fog swallows the screen
    //   hagane  steel: hard, short cuts from the side, a scan line runs over the card, shutters close
    //   summit  cold air: the panel slides in, the clock descends, contour lines widen, the night settles
    readonly property var motions: ({
        sumi:   { dur: 1300, ease: Easing.OutQuint, dx: 0,   dy: 18,  s0: 0.96, stag: 150, delay: 350, wall: 1400, amp: 12, cyc: 2.5, sdur: 460 },
        iso:    { dur: 1100, ease: Easing.OutBack,  dx: 0,   dy: 48,  s0: 1.0,  stag: 120, delay: 250, wall: 1200, amp: 16, cyc: 4.5, sdur: 760 },
        kiri:   { dur: 2000, ease: Easing.OutCubic, dx: 0,   dy: 10,  s0: 1.04, stag: 240, delay: 300, wall: 2400, amp: 6,  cyc: 2,   sdur: 620 },
        hagane: { dur: 420,  ease: Easing.OutCubic, dx: -28, dy: 0,   s0: 1.0,  stag: 80,  delay: 150, wall: 350,  amp: 7,  cyc: 3,   sdur: 240 },
        summit: { dur: 1400, ease: Easing.OutExpo,  dx: 0,   dy: -28, s0: 1.0,  stag: 130, delay: 300, wall: 1600, amp: 12, cyc: 3,   sdur: 500 }
    })
    readonly property var m: motions[root.st] || motions.sumi
    // the new themes borrow the motion of an earlier one: Yoru cuts in hard like steel, Kōyō and Tsuki
    // seep in like ink, Hotaru condenses out of the dark like fog, Shinkai rolls in like waves
    readonly property string st: ({ yoru: "hagane", koyo: "sumi", hotaru: "kiri", shinkai: "iso", tsuki: "sumi" })[pal.name] || pal.name

    // the screen arrives piece by piece: put an Rv inside an item and it fades and moves into place
    // (order = its place in the sequence). With shake: true it also follows the wrong-password shake.
    component Rv: Item {
        id: rv
        property int order: 0
        property real dx: root.m.dx * root.s
        property real dy: root.m.dy * root.s
        property real s0: root.m.s0
        property int dur: root.m.dur
        property int ease: root.m.ease
        property bool shake: false
        property real k: 0
        visible: false
        width: 0; height: 0
        Translate { id: rvT; x: (1 - rv.k) * rv.dx + (rv.shake ? root.shakeX : 0); y: (1 - rv.k) * rv.dy - root.lift }
        Scale {
            id: rvS
            origin.x: rv.parent ? rv.parent.width / 2 : 0; origin.y: rv.parent ? rv.parent.height / 2 : 0
            xScale: rv.s0 + (1 - rv.s0) * rv.k; yScale: xScale
        }
        Binding { target: rv.parent; property: "opacity"; value: Math.max(0, Math.min(1, rv.k * 1.25)) }
        Component.onCompleted: parent.transform = [rvS, rvT]
        SequentialAnimation {
            running: true
            PauseAnimation { duration: root.m.delay + rv.order * root.m.stag }
            NumberAnimation { target: rv; property: "k"; to: 1; duration: rv.dur; easing.type: rv.ease; easing.overshoot: 1.5 }
        }
    }

    // wrong password: a decaying shake, its size and rhythm come from the theme
    property real shakeT: 1
    readonly property real shakeX: m.amp * root.s * Math.sin(shakeT * m.cyc * 2 * Math.PI) * (1 - shakeT)
    NumberAnimation { id: shake; target: root; property: "shakeT"; from: 0; to: 1; duration: root.m.sdur; easing.type: Easing.Linear }
    // after login everything rises a little while the outro covers it (summit)
    property real lift: 0

    // a soft pulse on every key press, the field glows a little brighter
    property real typed: 0
    NumberAnimation { id: typePulse; target: root; property: "typed"; from: 1; to: 0; duration: root.st === "hagane" ? 160 : 520; easing.type: Easing.OutCubic }

    // ---------------- pieces the scenes share ----------------
    property var now: new Date()
    readonly property var dayNames: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
    readonly property var monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
    readonly property string hhmm: Qt.formatTime(now, "hh:mm")
    readonly property string longDate: dayNames[now.getDay()] + ", " + now.getDate() + ". " + monthNames[now.getMonth()]
    readonly property string shortDate: (dayNames[now.getDay()].slice(0, 2) + " " + String(now.getDate()).padStart(2, "0") + " " + monthNames[now.getMonth()].slice(0, 3)).toUpperCase()

    // the password field of the active layout
    readonly property bool ownScene: root.st === "summit"
    readonly property var pw: ownScene ? summitScene.field : password
    onOwnSceneChanged: Qt.callLater(function () { root.pw.forceActiveFocus() })

    // password field: an underline ("line") or a rounded box ("box")
    component Field: Rectangle {
        id: f
        property alias input: ti
        property string look: "line"
        property string placeholder: "Passwort"
        property string fontFamily: pal.body
        property bool italic: false
        property real ls: 0
        property color edge: pal.accent
        height: 42 * root.s
        radius: look === "box" ? height / 2 : 0
        color: look === "box" ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
        border.width: look === "box" ? Math.max(1, 1.2 * root.s) : 0
        border.color: root.failed ? pal.error : f.edge
        Behavior on border.color { ColorAnimation { duration: 220 } }
        // underline: dim at rest, it fills with the accent from the left when focused
        Rectangle {
            visible: f.look === "line"
            anchors.bottom: parent.bottom
            width: parent.width; height: Math.max(1, 1.5 * root.s)
            color: Qt.rgba(f.edge.r, f.edge.g, f.edge.b, 0.35)
        }
        Rectangle {
            visible: f.look === "line"
            anchors.bottom: parent.bottom
            width: ti.activeFocus ? parent.width : 0; height: Math.max(1, (1.5 + root.typed) * root.s)
            color: root.failed ? pal.error : f.edge
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
        }
        TextInput {
            id: ti
            anchors { left: parent.left; leftMargin: f.look === "box" ? 18 * root.s : 2 * root.s; right: go.left; rightMargin: 8 * root.s; verticalCenter: parent.verticalCenter }
            echoMode: TextInput.Password
            passwordCharacter: "●"
            color: pal.hi
            selectionColor: pal.accent
            font.family: pal.body
            font.pixelSize: 13 * root.s
            font.letterSpacing: 4 * root.s
            clip: true
            onTextChanged: if (text.length > 0) typePulse.restart()
            Keys.onReturnPressed: root.doLogin()
            Keys.onEnterPressed: root.doLogin()
        }
        Text {
            anchors { left: ti.left; verticalCenter: parent.verticalCenter }
            visible: ti.text.length === 0
            text: root.failed ? (f.ls > 0 ? "FALSCHES PASSWORT" : "falsches Passwort") : f.placeholder
            color: root.failed ? pal.error : pal.dim
            font.family: f.fontFamily; font.italic: f.italic
            font.pixelSize: 13 * root.s; font.letterSpacing: f.ls
        }
        Text {
            id: go
            anchors { right: parent.right; rightMargin: (f.look === "box" ? 16 : 2) * root.s; verticalCenter: parent.verticalCenter }
            text: root.busy ? "…" : "➜"
            color: gm2.containsMouse ? pal.hi : pal.accent
            font.pixelSize: 15 * root.s
            MouseArea { id: gm2; anchors.fill: parent; anchors.margins: -8 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
        }
        MouseArea { anchors.fill: ti; onClicked: ti.forceActiveFocus() }
    }

    // the theme's logo in a ring
    component Avatar: Item {
        id: av
        property real size: 96 * root.s
        property color ring: pal.accent
        width: size; height: size
        Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.rgba(pal.bg.r, pal.bg.g, pal.bg.b, 0.7); border.width: Math.max(1.5, 2 * root.s); border.color: av.ring }
        Image {
            anchors.centerIn: parent
            width: parent.width - 8 * root.s; height: width
            source: "file://" + root.stateDir + "/logo.svg"
            sourceSize.width: 256; sourceSize.height: 256
            cache: false
            onStatusChanged: if (status === Image.Error) source = "logo.svg"
        }
        MouseArea { anchors.fill: parent; cursorShape: root.userNames.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: { root.nextUser(); root.pw.forceActiveFocus() } }
    }

    // session and keyboard layout, click to change
    component SessionRow: Row {
        id: sr
        property string fontFamily: pal.body
        property bool caps: true
        property bool italic: false
        property real ls: 2.5 * root.s
        spacing: 14 * root.s
        Text {
            text: sr.caps ? root.sessionName().toUpperCase() : root.sessionName()
            color: srm.containsMouse ? pal.hi : pal.dim
            Behavior on color { ColorAnimation { duration: 160 } }
            font.family: sr.fontFamily; font.italic: sr.italic; font.pixelSize: 11 * root.s; font.letterSpacing: sr.ls
            MouseArea { id: srm; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.nextSession(); root.pw.forceActiveFocus() } }
        }
        Text { text: "·"; color: pal.mute; font.pixelSize: 11 * root.s }
        Text {
            text: { var l = keyboard.layouts[keyboard.currentLayout]; return l ? (sr.caps ? l.shortName.toUpperCase() : l.shortName) : "DE" }
            color: skm.containsMouse ? pal.hi : pal.dim
            Behavior on color { ColorAnimation { duration: 160 } }
            font.family: sr.fontFamily; font.italic: sr.italic; font.pixelSize: 11 * root.s; font.letterSpacing: sr.ls
            MouseArea {
                id: skm; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length; root.pw.forceActiveFocus() }
            }
        }
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
        sddm.login(root.userName, root.pw.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() { outro.start() }
        function onLoginFailed() {
            root.busy = false
            root.failed = true
            root.pw.text = ""
            shake.restart()
            root.pw.forceActiveFocus()
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
        id: wallFx
        anchors.fill: parent
        source: wallSrc
        blurEnabled: !root.ownScene; blur: 0.25; blurMax: 32
        brightness: root.ownScene ? -0.16 : -0.32
        saturation: root.ownScene ? 0.0 : 0.05
        // the picture comes up out of the theme's background, then breathes: a very slow zoom
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: root.m.wall; easing.type: Easing.InOutSine }
        transformOrigin: Item.Center
        scale: zIntro * zBreath
        property real zIntro: 1
        property real zBreath: 1
        NumberAnimation on zIntro { from: root.st === "summit" ? 1.08 : 1.03; to: 1.0; duration: 4000; easing.type: Easing.OutCubic }
        SequentialAnimation on zBreath {
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.06; duration: 45000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.06; to: 1.0; duration: 45000; easing.type: Easing.InOutSine }
        }
    }
    Ambient {
        anchors.fill: parent
        name: pal.name; accent: pal.accent; accent2: pal.accent2; fg: pal.fg; s: root.s
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: root.m.wall * 1.5; easing.type: Easing.InOutSine }
    }

    // ================= the glass card: sumi, iso, kiri, hagane =================
    Item {
        id: cardScene
        anchors.fill: parent
        visible: !root.ownScene

        // kiri: the whole scene condenses out of the fog
        property real fogBlur: root.st === "kiri" ? 1 : 0
        NumberAnimation on fogBlur { running: root.st === "kiri"; from: 1; to: 0; duration: 2600; easing.type: Easing.OutCubic }
        layer.enabled: fogBlur > 0.002
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 48; blur: cardScene.fogBlur }
        // kiri: the card floats, very slowly
        property real floatY: 0
        SequentialAnimation on floatY {
            running: root.st === "kiri"; loops: Animation.Infinite
            NumberAnimation { from: 0; to: 8; duration: 7000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 8; to: 0; duration: 7000; easing.type: Easing.InOutSine }
        }

        // ---------------- clock ----------------
        Column {
            x: 56 * root.s; y: 46 * root.s
            spacing: 2 * root.s
            Text {
                id: clock
                textFormat: Text.StyledText
                text: root.st === "sumi" ? root.hhmm.slice(0, 2) + "<font color='" + pal.accent + "'>:</font>" + root.hhmm.slice(3) : root.hhmm
                color: pal.hi; font.family: pal.head; font.pixelSize: 68 * root.s
                font.weight: root.st === "hagane" || root.st === "iso" ? Font.Light : Font.Bold
                Rv { order: 0; dx: root.st === "hagane" ? -40 * root.s : 0; dy: root.st === "iso" ? 30 * root.s : (root.st === "hagane" ? 0 : -14 * root.s) }
            }
            Text {
                x: 3 * root.s
                text: root.longDate
                color: pal.fg; font.family: pal.body; font.pixelSize: 16 * root.s; font.letterSpacing: 2.5 * root.s
                Rv { order: 1; dx: root.st === "hagane" ? -40 * root.s : 0; dy: root.st === "iso" ? 30 * root.s : (root.st === "hagane" ? 0 : -10 * root.s) }
            }
            // hagane: the seconds of the minute as a hairline under the date
            Item {
                visible: root.st === "hagane"
                width: 230 * root.s; height: 10 * root.s
                Rectangle { y: 8 * root.s; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.18) }
                Rectangle {
                    id: secBar
                    y: 8 * root.s; height: 1; color: pal.accent
                    width: parent.width * (root.now.getSeconds() + 1) / 60
                    Behavior on width { enabled: root.now.getSeconds() > 0; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
                Rv { order: 2; dx: -40 * root.s }
            }
        }

        // ---------------- glass card ----------------
        Item {
            id: card
            width: 388 * root.s
            height: cardCol.implicitHeight + 64 * root.s
            anchors.centerIn: parent
            anchors.verticalCenterOffset: (10 - cardScene.floatY) * root.s
            Rv { order: 1; shake: true }

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
                // hagane: a scan line runs down the card once when it appears
                Rectangle {
                    id: scanLine
                    visible: root.st === "hagane" && y < card.height
                    width: parent.width; height: 2 * root.s
                    y: -10
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: pal.accent }
                        GradientStop { position: 1; color: "transparent" } }
                    SequentialAnimation on y {
                        running: root.st === "hagane"
                        PauseAnimation { duration: 420 }
                        NumberAnimation { from: -10; to: card.height + 10; duration: 620; easing.type: Easing.InOutCubic }
                    }
                }
            }
            Item {
                id: glassMask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle { anchors.fill: parent; radius: Math.min(pal.radius, 24) * root.s; color: "black" }
            }
            Rectangle {
                anchors.fill: parent
                radius: Math.min(pal.radius, 24) * root.s
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
            }


            Column {
                id: cardCol
                anchors { top: parent.top; topMargin: 38 * root.s; horizontalCenter: parent.horizontalCenter }
                spacing: 0

                // avatar: the logo in a ring of the accent
                Item {
                    id: avatarBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96 * root.s; height: width
                    Rv { order: 2; s0: root.st === "sumi" ? 0.8 : (root.st === "kiri" ? 1.1 : 1); dy: root.st === "iso" ? 36 * root.s : 0; dx: 0 }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 14 * root.s; height: width; radius: width / 2
                        color: "transparent"
                        border.width: 5 * root.s
                        border.color: Qt.rgba(0, 0, 0, 0.28)
                    }
                    // iso: rings spread out from the avatar like ripples, now and then
                    Repeater {
                        model: root.st === "iso" ? 2 : 0
                        delegate: Rectangle {
                            id: ripple
                            required property int index
                            anchors.centerIn: parent
                            width: avatarBox.width; height: width; radius: width / 2
                            color: "transparent"; border.width: Math.max(1, 1.2 * root.s); border.color: pal.accent
                            opacity: 0
                            SequentialAnimation {
                                running: true; loops: Animation.Infinite
                                PauseAnimation { duration: 2200 + ripple.index * 900 }
                                ParallelAnimation {
                                    NumberAnimation { target: ripple; property: "scale"; from: 1; to: 1.9; duration: 2600; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: ripple; property: "opacity"; from: 0.6; to: 0; duration: 2600; easing.type: Easing.OutCubic }
                                }
                                PauseAnimation { duration: 3200 - ripple.index * 900 }
                            }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: pal.bg
                        border.width: 2 * root.s
                        border.color: root.st === "sumi" ? Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.35) : pal.accent
                    }
                    Image {
                        anchors.centerIn: parent
                        width: parent.width - 6 * root.s; height: width
                        source: "file://" + root.stateDir + "/logo.svg"
                        sourceSize.width: 256; sourceSize.height: 256
                        cache: false
                        onStatusChanged: if (status === Image.Error) source = "logo.svg"
                    }
                    // sumi: an ensō is brushed around the avatar, thick where the brush lands, thin where it lifts
                    Canvas {
                        id: enso
                        visible: root.st === "sumi"
                        anchors.centerIn: parent
                        width: parent.width + 30 * root.s; height: width
                        property real p: 0
                        onPChanged: requestPaint()
                        SequentialAnimation on p {
                            running: root.st === "sumi"
                            PauseAnimation { duration: 900 }
                            NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutCubic }
                        }
                        onPaint: {
                            var c = getContext("2d"); c.reset()
                            var cx = width / 2, r = width / 2 - 5 * root.s
                            var a0 = -Math.PI * 0.62, sweep = Math.PI * 1.86 * p
                            var steps = Math.max(2, Math.round(120 * p))
                            c.strokeStyle = String(pal.accent); c.lineCap = "round"
                            for (var i = 0; i < steps; i++) {
                                var t0 = i / steps, t1 = (i + 1) / steps
                                var u = t0 * p                               // position along the whole stroke
                                c.lineWidth = Math.max(0.8, (5.2 - 4.2 * u + Math.sin(u * 19) * 0.5) * root.s)
                                c.globalAlpha = 0.95 - 0.35 * u
                                var rr = r + Math.sin(u * 7) * 1.2 * root.s
                                c.beginPath()
                                c.arc(cx, cx, rr, a0 + sweep * t0, a0 + sweep * t1 + 0.01, false)
                                c.stroke()
                            }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: root.userNames.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: { root.nextUser(); password.forceActiveFocus() } }
                }
                Item { width: 1; height: 16 * root.s }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.userName
                    color: pal.hi
                    font.family: pal.head
                    font.pixelSize: 27 * root.s
                    font.weight: root.st === "hagane" ? Font.Light : Font.Bold
                    Rv { order: 3; dx: 0; dy: root.st === "iso" ? 30 * root.s : (root.st === "hagane" ? 0 : 10 * root.s) }
                }
                Item { width: 1; height: 22 * root.s }

                // password
                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: (password.activeFocus ? 284 : 268) * root.s; height: 40 * root.s
                    Behavior on width { NumberAnimation { duration: root.st === "hagane" ? 140 : 600; easing.type: root.st === "iso" ? Easing.OutBack : Easing.OutQuint } }
                    radius: Math.min(pal.radius, 20) * root.s
                    color: Qt.rgba(1, 1, 1, 0.07 + 0.05 * root.typed)
                    border.width: Math.max(1, (1.5 + 0.8 * root.typed) * root.s)
                    border.color: root.failed ? pal.error : (password.activeFocus ? pal.accent : Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.55))
                    Behavior on border.color { ColorAnimation { duration: root.st === "hagane" ? 80 : 260 } }
                    Rv { order: 4; dx: 0; dy: root.st === "iso" ? 30 * root.s : (root.st === "hagane" ? 0 : 10 * root.s) }
                    // a soft glow around the field that lights up with each key
                    Rectangle {
                        z: -1
                        anchors.fill: parent; anchors.margins: -4 * root.s
                        radius: parent.radius + 4 * root.s
                        color: "transparent"
                        border.width: 3 * root.s
                        border.color: pal.accent
                        opacity: 0.35 * root.typed
                    }
                    TextInput {
                        id: password
                        anchors { left: parent.left; leftMargin: 16 * root.s; right: go.left; rightMargin: 8 * root.s; verticalCenter: parent.verticalCenter }
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: pal.hi
                        selectionColor: pal.accent
                        font.family: pal.body
                        font.pixelSize: 13 * root.s
                        font.letterSpacing: 4 * root.s
                        focus: true
                        clip: true
                        onTextChanged: if (text.length > 0) typePulse.restart()
                        Keys.onReturnPressed: root.doLogin()
                        Keys.onEnterPressed: root.doLogin()
                    }
                    Text {
                        anchors { left: password.left; verticalCenter: parent.verticalCenter }
                        visible: password.text.length === 0
                        text: root.failed ? "falsches Passwort" : "Passwort"
                        color: root.failed ? pal.error : pal.dim
                        font.family: pal.body
                        font.pixelSize: 13 * root.s
                    }
                    Text {
                        id: go
                        anchors { right: parent.right; rightMargin: 14 * root.s; verticalCenter: parent.verticalCenter }
                        text: root.busy ? "…" : "➜"
                        color: gm.containsMouse ? pal.hi : pal.accent
                        font.pixelSize: 15 * root.s
                        Behavior on anchors.rightMargin { NumberAnimation { duration: 160 } }
                        MouseArea {
                            id: gm; anchors.fill: parent; anchors.margins: -8 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.doLogin()
                            onContainsMouseChanged: go.anchors.rightMargin = (containsMouse ? 10 : 14) * root.s
                        }
                    }
                }
                Item { width: 1; height: 18 * root.s }
                // session and keyboard layout, click to change
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14 * root.s
                    Rv { order: 5; dx: 0; dy: root.st === "iso" ? 24 * root.s : (root.st === "hagane" ? 0 : 8 * root.s) }
                    Text {
                        text: root.sessionName().toUpperCase()
                        color: sm.containsMouse ? pal.hi : pal.dim
                        Behavior on color { ColorAnimation { duration: 160 } }
                        font.family: pal.body; font.pixelSize: 10.5 * root.s; font.letterSpacing: 2.5 * root.s
                        MouseArea { id: sm; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.nextSession(); password.forceActiveFocus() } }
                    }
                    Text { text: pal.kanji; color: pal.accent; font.family: "Noto Serif CJK JP"; font.pixelSize: 11 * root.s }
                    Text {
                        text: { var l = keyboard.layouts[keyboard.currentLayout]; return l ? l.shortName.toUpperCase() : "DE" }
                        color: km.containsMouse ? pal.hi : pal.dim
                        Behavior on color { ColorAnimation { duration: 160 } }
                        font.family: pal.body; font.pixelSize: 10.5 * root.s; font.letterSpacing: 2.5 * root.s
                        MouseArea {
                            id: km; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length; password.forceActiveFocus() }
                        }
                    }
                }
            }
        }

        // ---------------- bottom left: host and theme ----------------
        Text {
            anchors { left: parent.left; leftMargin: 58 * root.s; bottom: parent.bottom; bottomMargin: 46 * root.s }
            text: (sddm.hostName || "nixos") + "  ·  " + pal.label.toUpperCase()
            color: pal.dim; font.family: pal.body; font.pixelSize: 12 * root.s; font.letterSpacing: 2 * root.s
            Rv { order: 6; dy: root.st === "iso" ? 20 * root.s : 0 }
        }
    }

    // ================= Summit: a glass panel on the left with contour lines, the clock up right =================
    Item {
        id: summitScene
        anchors.fill: parent
        visible: root.ownScene
        property alias field: sField.input
        Rectangle {
            id: sPanel
            width: 520 * root.s; height: parent.height
            clip: true
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(pal.bg.r, pal.bg.g, pal.bg.b, 0.88) }
                GradientStop { position: 1; color: Qt.rgba(pal.bg.r, pal.bg.g, pal.bg.b, 0.55) } }
            Rv { order: 0; dx: -520 * root.s; dy: 0; dur: 1500 }
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.2) }
            // contour lines that slowly widen outwards, like height lines read from the summit down
            Item {
                id: contours
                anchors.fill: parent
                opacity: 0.16
                readonly property real cx: 190 * root.s
                readonly property real cy: 810 * root.s
                property real phase: 0
                NumberAnimation on phase { running: summitScene.visible; from: 0; to: 1; duration: 9000; loops: Animation.Infinite }
                Repeater {
                    model: 16
                    delegate: Rectangle {
                        required property int index
                        readonly property real f: index + contours.phase
                        readonly property real rx: (75 + f * 44) * root.s
                        x: contours.cx - rx; y: contours.cy - rx
                        width: rx * 2; height: rx * 2; radius: rx
                        color: "transparent"; border.width: 1; border.color: "#d6e2f5"
                        // the innermost line fades in, the outermost fades out, so the loop has no seam
                        opacity: Math.min(1, f) * Math.min(1, (16 - f) / 2)
                        transform: Scale { origin.x: rx; origin.y: rx; yScale: 0.66 }
                    }
                }
            }
        }
        Text {
            x: 70 * root.s; y: 72 * root.s
            text: pal.kanji + "  ·  " + pal.label.toUpperCase()
            color: pal.accent; font.family: pal.head; font.pixelSize: 15 * root.s; font.letterSpacing: 7 * root.s
            Rv { order: 3; dy: -16 * root.s }
        }
        Column {
            x: 70 * root.s; y: 320 * root.s
            spacing: 18 * root.s
            Avatar { size: 82 * root.s; ring: pal.accent; Rv { order: 4; shake: true } }
            Text {
                text: root.userName; color: pal.hi; font.family: pal.head; font.weight: Font.Light; font.pixelSize: 46 * root.s; font.letterSpacing: 2.5 * root.s
                Rv { order: 5; shake: true }
            }
            Field {
                id: sField; width: 375 * root.s; look: "line"; fontFamily: pal.head; placeholder: "PASSWORT"; ls: 4 * root.s; edge: Qt.rgba(pal.hi.r, pal.hi.g, pal.hi.b, 0.6)
                Rv { order: 6; shake: true }
            }
            SessionRow { fontFamily: pal.head; ls: 3 * root.s; Rv { order: 7 } }
        }
        Column {
            anchors { right: parent.right; rightMargin: 70 * root.s }
            y: 56 * root.s
            Text {
                anchors.right: parent.right; text: root.hhmm; color: pal.hi; font.family: pal.head; font.weight: Font.Light; font.pixelSize: 84 * root.s; font.letterSpacing: 4 * root.s
                Rv { order: 1; dy: -40 * root.s }
            }
            Text {
                anchors.right: parent.right; text: root.shortDate; color: pal.accent; font.family: pal.head; font.pixelSize: 16 * root.s; font.letterSpacing: 7.5 * root.s
                Rv { order: 2; dy: -30 * root.s }
            }
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 50 * root.s; bottom: parent.bottom; bottomMargin: 40 * root.s }
        spacing: 20 * root.s
        Rv { order: 7; dy: 0; dx: 0 }
        Repeater {
            model: sddm.canSuspend ? ["sleep", "reboot", "power"] : ["reboot", "power"]
            delegate: Item {
                width: 26 * root.s; height: width
                Canvas {
                    id: ic
                    anchors.fill: parent
                    property color c: modelData === "power" ? pal.accent : (pa.containsMouse ? pal.hi : pal.fg)
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

    // ---------------- after a successful login: the theme's way out, then the kanji until Hyprland is up ----------------
    Item {
        id: outroLayer
        anchors.fill: parent
        visible: false
        readonly property real diag: Math.sqrt(width * width + height * height)

        // sumi: ink spreads out of the avatar until it fills the screen
        Rectangle {
            id: inkDot
            visible: root.st === "sumi"
            property real cx: root.width / 2
            property real cy: root.height / 2
            width: 0; height: width; radius: width / 2
            x: cx - width / 2; y: cy - width / 2
            color: pal.bg
        }
        // iso: the tide comes in from below, with a soft foam edge
        Item {
            id: tide
            visible: root.st === "iso"
            width: parent.width; height: parent.height + edge.height
            y: parent.height
            Image { id: edge; source: "blob.png"; width: parent.width * 1.6; x: -parent.width * 0.3; height: 260 * root.s; y: 0
                layer.enabled: true; layer.effect: MultiEffect { colorization: 1.0; colorizationColor: pal.bg } }
            Rectangle { y: edge.height / 2; width: parent.width; height: parent.height; color: pal.bg }
        }
        // kiri: the fog thickens to white, then darkens to the theme's night
        Rectangle { id: whiteout; anchors.fill: parent; visible: root.st === "kiri"; color: "#dfe6e3"; opacity: 0 }
        // hagane: two steel shutters close on a bright seam
        Rectangle { id: shutTop; visible: root.st === "hagane"; width: parent.width; height: 0; color: pal.bg }
        Rectangle { id: shutBot; visible: root.st === "hagane"; width: parent.width; height: 0; y: parent.height - height; color: pal.bg }
        Rectangle { id: seam; visible: root.st === "hagane" && width > 0; anchors.centerIn: parent; width: 0; height: 1; color: pal.accent }

        Rectangle {
            id: launchCover
            anchors.fill: parent
            color: pal.bg
            opacity: 0
            Text {
                id: coverKanji
                anchors.centerIn: parent
                text: pal.kanji
                color: pal.accent
                font.family: "Noto Serif CJK JP"
                font.pixelSize: 54 * root.s
                opacity: 0
                SequentialAnimation {
                    running: launchCover.opacity > 0.99; loops: Animation.Infinite
                    NumberAnimation { target: coverKanji; property: "opacity"; to: 1; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { target: coverKanji; property: "opacity"; to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    NumberAnimation { id: coverIn; target: launchCover; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: outroSumi
        NumberAnimation { target: inkDot; property: "width"; from: 0; to: outroLayer.diag * 2.2; duration: 1100; easing.type: Easing.InCubic }
        ScriptAction { script: coverIn.start() }
    }
    SequentialAnimation {
        id: outroIso
        NumberAnimation { target: tide; property: "y"; to: -edge.height; duration: 950; easing.type: Easing.InOutCubic }
        ScriptAction { script: coverIn.start() }
    }
    SequentialAnimation {
        id: outroKiri
        NumberAnimation { target: whiteout; property: "opacity"; to: 1; duration: 900; easing.type: Easing.InOutSine }
        ColorAnimation { target: whiteout; property: "color"; to: pal.bg; duration: 700; easing.type: Easing.InOutSine }
        ScriptAction { script: coverIn.start() }
    }
    SequentialAnimation {
        id: outroHagane
        ParallelAnimation {
            NumberAnimation { target: shutTop; property: "height"; to: root.height / 2; duration: 260; easing.type: Easing.InCubic }
            NumberAnimation { target: shutBot; property: "height"; to: root.height / 2; duration: 260; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: seam; property: "width"; to: root.width; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: seam; property: "opacity"; to: 0; duration: 220 }
        ScriptAction { script: coverIn.start() }
    }
    SequentialAnimation {
        id: outroSummit
        ParallelAnimation {
            NumberAnimation { target: root; property: "lift"; to: 40 * root.s; duration: 900; easing.type: Easing.InCubic }
            NumberAnimation { target: launchCover; property: "opacity"; to: 1; duration: 900; easing.type: Easing.InCubic }
        }
    }
    // "start" so Connections can call outro.start() like an animation
    QtObject {
        id: outro
        function start() {
            outroLayer.visible = true
            if (root.st === "sumi") {
                var p = avatarBox.mapToItem(root, avatarBox.width / 2, avatarBox.height / 2)
                inkDot.cx = p.x; inkDot.cy = p.y
                outroSumi.start()
            } else if (root.st === "iso") outroIso.start()
            else if (root.st === "kiri") outroKiri.start()
            else if (root.st === "hagane") outroHagane.start()
            else outroSummit.start()
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Component.onCompleted: { root.pw.forceActiveFocus(); Qt.callLater(root.pickSessions) }
}
