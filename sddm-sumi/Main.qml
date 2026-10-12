import QtQuick 2.15
import QtQuick.Effects

// Sumi login: the wallpaper of the active theme with slow motion over it (Ambient.qml), the
// theme's colours and fonts and its own layout: a glass card for Sumi, Kiri, Hagane, Suna and
// Iso, own scenes for Dune, Summit, Unkai and Ginga.
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

    // which layout: the four landscape themes have their own, the rest share the glass card
    readonly property string variant: ["dune", "summit", "unkai", "ginga"].indexOf(pal.name) >= 0 ? pal.name : "card"
    // the password field of the active layout
    readonly property var pw: variant === "dune" ? duneScene.field : variant === "summit" ? summitScene.field
        : variant === "unkai" ? unkaiScene.field : variant === "ginga" ? gingaScene.field : password
    onVariantChanged: Qt.callLater(function () { root.pw.forceActiveFocus() })

    // ---------------- pieces the landscape scenes share ----------------
    property var now: new Date()
    property real shakeX: 0
    readonly property var romanN: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII", "XXIII", "XXIV", "XXV", "XXVI", "XXVII", "XXVIII", "XXIX", "XXX", "XXXI"]
    readonly property var dayNames: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
    readonly property var monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
    readonly property var ordinals: ["erste", "zweite", "dritte", "vierte", "fünfte", "sechste", "siebte", "achte", "neunte", "zehnte", "elfte", "zwölfte", "dreizehnte", "vierzehnte", "fünfzehnte", "sechzehnte", "siebzehnte", "achtzehnte", "neunzehnte", "zwanzigste", "einundzwanzigste", "zweiundzwanzigste", "dreiundzwanzigste", "vierundzwanzigste", "fünfundzwanzigste", "sechsundzwanzigste", "siebenundzwanzigste", "achtundzwanzigste", "neunundzwanzigste", "dreißigste", "einunddreißigste"]
    readonly property string hhmm: Qt.formatTime(now, "hh:mm")
    readonly property string romanDate: (dayNames[now.getDay()] + " · " + romanN[now.getDate() - 1] + " · " + monthNames[now.getMonth()]).toUpperCase()
    readonly property string wordsDate: dayNames[now.getDay()] + ", der " + ordinals[now.getDate() - 1] + " " + monthNames[now.getMonth()]
    readonly property string shortDate: (dayNames[now.getDay()].slice(0, 2) + " " + String(now.getDate()).padStart(2, "0") + " " + monthNames[now.getMonth()].slice(0, 3)).toUpperCase()

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
        Rectangle {
            visible: f.look === "line"
            anchors.bottom: parent.bottom
            width: parent.width; height: Math.max(1, 1.5 * root.s)
            color: root.failed ? pal.error : f.edge
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
            font.family: sr.fontFamily; font.italic: sr.italic; font.pixelSize: 11 * root.s; font.letterSpacing: sr.ls
            MouseArea { id: srm; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.nextSession(); root.pw.forceActiveFocus() } }
        }
        Text { text: "·"; color: pal.mute; font.pixelSize: 11 * root.s }
        Text {
            text: { var l = keyboard.layouts[keyboard.currentLayout]; return l ? (sr.caps ? l.shortName.toUpperCase() : l.shortName) : "DE" }
            color: skm.containsMouse ? pal.hi : pal.dim
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
        function onLoginSucceeded() { launchCover.opacity = 1 }
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
        blurEnabled: root.variant === "card"; blur: 0.25; blurMax: 32
        brightness: root.variant === "card" ? -0.32 : root.variant === "unkai" ? -0.08 : root.variant === "ginga" ? -0.12 : -0.16
        saturation: root.variant === "card" ? 0.05 : 0.0
        // the picture breathes: a very slow zoom in and out
        transformOrigin: Item.Center
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.06; duration: 45000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.06; to: 1.0; duration: 45000; easing.type: Easing.InOutSine }
        }
    }
    Ambient {
        anchors.fill: parent
        name: pal.name; accent: pal.accent; accent2: pal.accent2; fg: pal.fg; s: root.s
    }

    Item {
        id: cardScene
        anchors.fill: parent
        visible: root.variant === "card"

        // ---------------- clock ----------------
        Column {
            x: 56 * root.s; y: 46 * root.s
            spacing: 2 * root.s
            Text { id: clock; color: pal.hi; font.family: pal.head; font.pixelSize: 68 * root.s; font.weight: Font.Bold }
            Text { id: dateText; x: 3 * root.s; color: pal.fg; font.family: pal.body; font.pixelSize: 16 * root.s; font.letterSpacing: 2.5 * root.s }
        }

        // ---------------- glass card ----------------
        Item {
            id: card
            width: 388 * root.s
            height: cardCol.implicitHeight + 64 * root.s
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 10 * root.s
            transform: Translate { x: root.shakeX }

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
                        color: pal.bg
                        border.width: 2 * root.s
                        border.color: pal.accent
                    }
                    Image {
                        anchors.centerIn: parent
                        width: parent.width - 6 * root.s; height: width
                        source: "file://" + root.stateDir + "/logo.svg"
                        sourceSize.width: 256; sourceSize.height: 256
                        cache: false
                        onStatusChanged: if (status === Image.Error) source = "logo.svg"
                    }
                    MouseArea { anchors.fill: parent; cursorShape: root.userNames.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: { root.nextUser(); root.pw.forceActiveFocus() } }
                }
                Item { width: 1; height: 16 * root.s }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.userName
                    color: pal.hi
                    font.family: pal.head
                    font.pixelSize: 27 * root.s
                    font.weight: Font.Bold
                }
                Item { width: 1; height: 22 * root.s }

                // password
                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 276 * root.s; height: 40 * root.s
                    radius: Math.min(pal.radius, 20) * root.s
                    color: Qt.rgba(1, 1, 1, 0.07)
                    border.width: Math.max(1, 1.5 * root.s)
                    border.color: root.failed ? pal.error : (password.activeFocus ? pal.accent : Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.7))
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
                        color: sm.containsMouse ? pal.hi : pal.dim
                        font.family: pal.body; font.pixelSize: 10.5 * root.s; font.letterSpacing: 2.5 * root.s
                        MouseArea { id: sm; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.nextSession(); password.forceActiveFocus() } }
                    }
                    Text { text: pal.kanji; color: pal.accent; font.family: "Noto Serif CJK JP"; font.pixelSize: 11 * root.s }
                    Text {
                        text: { var l = keyboard.layouts[keyboard.currentLayout]; return l ? l.shortName.toUpperCase() : "DE" }
                        color: km.containsMouse ? pal.hi : pal.dim
                        font.family: pal.body; font.pixelSize: 10.5 * root.s; font.letterSpacing: 2.5 * root.s
                        MouseArea {
                            id: km; anchors.fill: parent; anchors.margins: -6 * root.s; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length; password.forceActiveFocus() }
                        }
                    }
                }
            }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: root; property: "shakeX"; to: -12 * root.s; duration: 50 }
                NumberAnimation { target: root; property: "shakeX"; to: 12 * root.s; duration: 70 }
                NumberAnimation { target: root; property: "shakeX"; to: -7 * root.s; duration: 60 }
                NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 50 }
            }
        }

        // ---------------- bottom: host on the left, sleep / restart / power on the right ----------------
        Text {
            anchors { left: parent.left; leftMargin: 58 * root.s; bottom: parent.bottom; bottomMargin: 46 * root.s }
            text: (sddm.hostName || "nixos") + "  ·  " + pal.label.toUpperCase()
            color: pal.dim; font.family: pal.body; font.pixelSize: 12 * root.s; font.letterSpacing: 2 * root.s
        }
    }

    // ---------------- Dune: a Roman clock over the desert, everything on one axis ----------------
    Item {
        id: duneScene
        anchors.fill: parent
        visible: root.variant === "dune"
        property alias field: dField.input
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 118 * root.s
            textFormat: Text.StyledText
            text: root.hhmm.slice(0, 2) + "<font color='" + pal.accent2 + "'>:</font>" + root.hhmm.slice(3)
            color: pal.hi; font.family: pal.head; font.pixelSize: 74 * root.s; font.letterSpacing: 8 * root.s
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 222 * root.s
            text: root.romanDate
            color: pal.fg; font.family: pal.head; font.pixelSize: 15 * root.s; font.letterSpacing: 7 * root.s
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 345 * root.s
            spacing: 18 * root.s
            transform: Translate { x: root.shakeX }
            Avatar { anchors.horizontalCenter: parent.horizontalCenter; size: 92 * root.s; ring: pal.accent2 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.userName.toUpperCase(); color: pal.hi; font.family: pal.head; font.pixelSize: 28 * root.s; font.letterSpacing: 6 * root.s }
            Field { id: dField; anchors.horizontalCenter: parent.horizontalCenter; width: 330 * root.s; look: "line"; fontFamily: pal.head; placeholder: "PASSWORT"; ls: 4 * root.s }
            SessionRow { anchors.horizontalCenter: parent.horizontalCenter; fontFamily: pal.head; ls: 3.5 * root.s }
        }
    }

    // ---------------- Summit: a glass panel on the left with contour lines, the clock up right ----------------
    Item {
        id: summitScene
        anchors.fill: parent
        visible: root.variant === "summit"
        property alias field: sField.input
        Rectangle {
            id: sPanel
            width: 520 * root.s; height: parent.height
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(pal.bg.r, pal.bg.g, pal.bg.b, 0.88) }
                GradientStop { position: 1; color: Qt.rgba(pal.bg.r, pal.bg.g, pal.bg.b, 0.55) } }
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.2) }
            Canvas {
                anchors.fill: parent
                opacity: 0.13
                onWidthChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"); c.reset(); c.strokeStyle = "#d6e2f5"; c.lineWidth = 1
                    for (var i = 0; i < 16; i++) {
                        c.beginPath(); c.ellipse(190 * root.s - (75 + i * 44) * root.s, 810 * root.s - (50 + i * 29) * root.s, 2 * (75 + i * 44) * root.s, 2 * (50 + i * 29) * root.s); c.stroke()
                    }
                }
            }
        }
        Text {
            x: 70 * root.s; y: 72 * root.s
            text: pal.kanji + "  ·  " + pal.label.toUpperCase()
            color: pal.accent; font.family: pal.head; font.pixelSize: 15 * root.s; font.letterSpacing: 7 * root.s
        }
        Column {
            x: 70 * root.s; y: 320 * root.s
            spacing: 18 * root.s
            transform: Translate { x: root.shakeX }
            Avatar { size: 82 * root.s; ring: pal.accent }
            Text { text: root.userName; color: pal.hi; font.family: pal.head; font.weight: Font.Light; font.pixelSize: 46 * root.s; font.letterSpacing: 2.5 * root.s }
            Field { id: sField; width: 375 * root.s; look: "line"; fontFamily: pal.head; placeholder: "PASSWORT"; ls: 4 * root.s; edge: Qt.rgba(pal.hi.r, pal.hi.g, pal.hi.b, 0.6) }
            SessionRow { fontFamily: pal.head; ls: 3 * root.s }
        }
        Column {
            anchors { right: parent.right; rightMargin: 70 * root.s }
            y: 56 * root.s
            Text { anchors.right: parent.right; text: root.hhmm; color: pal.hi; font.family: pal.head; font.weight: Font.Light; font.pixelSize: 84 * root.s; font.letterSpacing: 4 * root.s }
            Text { anchors.right: parent.right; text: root.shortDate; color: pal.accent; font.family: pal.head; font.pixelSize: 16 * root.s; font.letterSpacing: 7.5 * root.s }
        }
    }

    // ---------------- Unkai: an italic clock above the clouds, a card resting on the cloud sea ----------------
    Item {
        id: unkaiScene
        anchors.fill: parent
        visible: root.variant === "unkai"
        property alias field: uField.input
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 62 * root.s
            spacing: 2 * root.s
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.hhmm; color: pal.hi; font.family: pal.head; font.italic: true; font.weight: Font.Light; font.pixelSize: 96 * root.s
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: pal.accent; shadowOpacity: 0.45; shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.wordsDate; color: pal.accent2; font.family: pal.head; font.italic: true; font.pixelSize: 19 * root.s }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 530 * root.s
            width: 400 * root.s; height: uCol.implicitHeight + 56 * root.s
            radius: 26 * root.s
            color: Qt.rgba(pal.bg1.r, pal.bg1.g, pal.bg1.b, 0.55)
            border.width: 1; border.color: Qt.rgba(pal.hi.r, pal.hi.g, pal.hi.b, 0.18)
            transform: Translate { x: root.shakeX }
            Column {
                id: uCol
                anchors { top: parent.top; topMargin: 30 * root.s; horizontalCenter: parent.horizontalCenter }
                spacing: 14 * root.s
                Avatar { anchors.horizontalCenter: parent.horizontalCenter; size: 76 * root.s; ring: pal.accent }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.userName; color: pal.hi; font.family: pal.head; font.italic: true; font.pixelSize: 34 * root.s }
                Field { id: uField; anchors.horizontalCenter: parent.horizontalCenter; width: 300 * root.s; look: "box"; fontFamily: pal.head; italic: true; placeholder: "Passwort"; edge: Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.7) }
                SessionRow { anchors.horizontalCenter: parent.horizontalCenter; fontFamily: pal.head; italic: true; caps: false; ls: 0.5 * root.s }
            }
        }
    }

    // ---------------- Ginga: the avatar at the centre of slowly turning orbits ----------------
    Item {
        id: gingaScene
        anchors.fill: parent
        visible: root.variant === "ginga"
        property alias field: gField.input
        readonly property real cy: 400 * root.s
        Canvas {
            id: orbits
            width: 620 * root.s; height: width
            x: parent.width / 2 - width / 2; y: gingaScene.cy - height / 2
            onWidthChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset()
                var cx = width / 2, rs = [94, 150, 212, 288], dots = [[0.6, 1], [2.2, 2], [4.1, 3], [5.3, 0], [3.1, 2], [1.4, 3]]
                for (var i = 0; i < rs.length; i++) {
                    c.beginPath(); c.lineWidth = 1
                    c.globalAlpha = 0.4 - i * 0.07; c.strokeStyle = String(pal.accent)
                    if (i % 2) c.setLineDash([3, 8]); else c.setLineDash([])
                    c.arc(cx, cx, rs[i] * root.s, 0, 2 * Math.PI); c.stroke()
                }
                c.setLineDash([]); c.globalAlpha = 1
                for (var k = 0; k < dots.length; k++) {
                    var r = rs[dots[k][1]] * root.s, a = dots[k][0]
                    c.beginPath(); c.fillStyle = k === 3 ? String(pal.accent2) : "#ffffff"
                    c.arc(cx + r * Math.cos(a), cx + r * Math.sin(a), 3.2 * root.s, 0, 2 * Math.PI); c.fill()
                }
            }
            RotationAnimation on rotation { from: 0; to: 360; duration: 240000; loops: Animation.Infinite; running: gingaScene.visible }
        }
        Avatar { x: parent.width / 2 - width / 2; y: gingaScene.cy - height / 2; size: 106 * root.s; ring: "#ffffff" }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 705 * root.s
            spacing: 16 * root.s
            transform: Translate { x: root.shakeX }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.userName; color: pal.hi; font.family: pal.head; font.weight: Font.Light; font.pixelSize: 38 * root.s; font.letterSpacing: 6 * root.s }
            Field { id: gField; anchors.horizontalCenter: parent.horizontalCenter; width: 330 * root.s; look: "box"; edge: Qt.rgba(pal.accent.r, pal.accent.g, pal.accent.b, 0.6) }
            SessionRow { anchors.horizontalCenter: parent.horizontalCenter }
        }
        Column {
            x: 56 * root.s; y: 48 * root.s
            Text { text: root.hhmm; color: pal.hi; font.family: pal.head; font.weight: Font.Light; font.pixelSize: 62 * root.s; font.letterSpacing: 3 * root.s }
            Text { text: root.shortDate + "  ·  " + pal.kanji; color: pal.accent; font.family: pal.body; font.pixelSize: 12.5 * root.s; font.letterSpacing: 2.5 * root.s }
        }
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

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            root.now = d
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
        color: pal.bg
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 350 } }
        Text {
            anchors.centerIn: parent
            text: pal.kanji
            color: pal.accent
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

    Component.onCompleted: { root.pw.forceActiveFocus(); Qt.callLater(root.pickSessions) }
}
