import QtQuick
import QtQuick.Particles
import QtQuick.Effects

// Slow, quiet motion over the login wallpaper, one mood per theme:
//   sumi    ink blooming in the dark, a few embers rising from the red sun
//   iso     sea mist, glints on the water, the swell breathing at the shore
//   kiri    three layers of fog moving against each other, the whole veil breathing
//   hagane  fine snow and a cold sheen of light running across the steel
//   summit  twinkling stars, fog in the valleys, snow blown off the ridge, a shooting star
Item {
    id: amb
    property string name: "sumi"
    property color accent: "#c8323a"
    property color accent2: "#e46876"
    property color fg: "#dcd7ba"
    property real s: 1

    // a band of fog that drifts sideways forever (fog.png tiles horizontally)
    component Fog: Item {
        id: fog
        property real speed: 120000
        property color tint: "white"
        property bool rightwards: false
        width: amb.width
        Item {
            id: strip
            width: fog.width * 2; height: fog.height
            Image { width: fog.width; height: fog.height; source: "fog.png"; smooth: true }
            Image { x: fog.width; width: fog.width; height: fog.height; source: "fog.png"; smooth: true }
            NumberAnimation on x {
                from: fog.rightwards ? -fog.width : 0; to: fog.rightwards ? 0 : -fog.width
                duration: fog.speed; loops: Animation.Infinite; running: fog.visible
            }
        }
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: fog.tint }
    }

    // a soft round blot that grows and fades, then reappears somewhere else
    component Bloom: Image {
        id: bl
        property color tint: "black"
        property real top: 0.5          // where on the screen (fraction of the height) it may appear
        property real peak: 0.4
        property int period: 11000
        property int offset: 0
        source: "blob.png"
        width: 520 * amb.s; height: width
        opacity: 0; scale: 0.2
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: bl.tint }
        SequentialAnimation {
            running: bl.visible; loops: Animation.Infinite
            PauseAnimation { duration: bl.offset }
            ScriptAction { script: { bl.x = amb.width * (0.05 + Math.random() * 0.8) - bl.width / 2; bl.y = amb.height * (bl.top + Math.random() * (0.95 - bl.top)) - bl.height / 2; } }
            ParallelAnimation {
                NumberAnimation { target: bl; property: "scale"; from: 0.15; to: 1.5; duration: bl.period; easing.type: Easing.OutCubic }
                SequentialAnimation {
                    NumberAnimation { target: bl; property: "opacity"; from: 0; to: bl.peak; duration: bl.period * 0.25; easing.type: Easing.OutQuad }
                    NumberAnimation { target: bl; property: "opacity"; to: 0; duration: bl.period * 0.75; easing.type: Easing.InOutSine }
                }
            }
            PauseAnimation { duration: 1500 }
        }
    }

    ParticleSystem { id: sys; anchors.fill: parent; running: amb.visible }
    ImageParticle { system: sys; groups: ["star"]; source: "dot.png"; color: "#ffffff"; colorVariation: 0.08; alpha: 0.9; entryEffect: ImageParticle.Fade }
    ImageParticle { system: sys; groups: ["ember"]; source: "dot.png"; color: amb.accent; alpha: 0.6; alphaVariation: 0.3; entryEffect: ImageParticle.Fade }
    ImageParticle { system: sys; groups: ["snow"]; source: "dot.png"; color: "#ffffff"; alpha: 0.6; alphaVariation: 0.25; entryEffect: ImageParticle.Fade }
    ImageParticle { system: sys; groups: ["glint"]; source: "dot.png"; color: "#ffffff"; alpha: 0.85; entryEffect: ImageParticle.Scale }
    ImageParticle { system: sys; groups: ["mote"]; source: "dot.png"; color: amb.fg; alpha: 0.35; alphaVariation: 0.2; entryEffect: ImageParticle.Fade }

    // ================= sumi =================
    Item {
        anchors.fill: parent
        visible: amb.name === "sumi"
        // dark ink seeping through the lower half, now and then a thread of red
        Bloom { tint: "#000000"; top: 0.45; peak: 0.55; period: 12000; offset: 0 }
        Bloom { tint: "#000000"; top: 0.55; peak: 0.5; period: 14000; offset: 4200 }
        Bloom { tint: amb.accent; top: 0.5; peak: 0.16; period: 13000; offset: 8000; width: 380 * amb.s }
        Fog { y: amb.height * 0.7; height: amb.height * 0.32; speed: 260000; tint: "#000000"; opacity: 0.45 }
    }
    Emitter {
        system: sys; group: "ember"
        enabled: amb.name === "sumi"
        x: amb.width * 0.15; y: amb.height; width: amb.width * 0.7; height: 10
        emitRate: 5
        lifeSpan: 17000; lifeSpanVariation: 5000
        size: 6 * amb.s; sizeVariation: 3 * amb.s
        velocity: AngleDirection { angle: 270; angleVariation: 12; magnitude: 36 * amb.s; magnitudeVariation: 16 * amb.s }
        acceleration: AngleDirection { angle: 0; angleVariation: 180; magnitude: 3 * amb.s }
    }

    // ================= iso =================
    Item {
        anchors.fill: parent
        visible: amb.name === "iso"
        Fog { y: amb.height * 0.48; height: amb.height * 0.3; speed: 200000; tint: "#d8e8ec"; opacity: 0.18 }
        Fog { y: amb.height * 0.66; height: amb.height * 0.34; speed: 120000; tint: "#eef6f6"; opacity: 0.16; rightwards: true }
        // the swell: light at the shore rises and falls like waves coming in
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * 0.5
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0.75, 0.92, 0.92, 1) } }
            opacity: 0
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.10; duration: 2600; easing.type: Easing.OutCubic }
                NumberAnimation { to: 0.0; duration: 4600; easing.type: Easing.InOutSine }
            }
        }
    }
    Emitter {
        system: sys; group: "glint"
        enabled: amb.name === "iso"
        x: 0; y: amb.height * 0.45; width: amb.width; height: amb.height * 0.5
        emitRate: 9
        lifeSpan: 900; lifeSpanVariation: 500
        size: 5 * amb.s; sizeVariation: 3 * amb.s; endSize: 0
        velocity: AngleDirection { angle: 0; magnitude: 6 * amb.s }
    }
    Emitter {   // fine spray drifting off the water
        system: sys; group: "mote"
        enabled: amb.name === "iso"
        x: -20; y: amb.height * 0.55; width: 20; height: amb.height * 0.45
        emitRate: 6
        lifeSpan: 20000
        size: 4 * amb.s; sizeVariation: 2 * amb.s
        velocity: AngleDirection { angle: -6; angleVariation: 8; magnitude: 70 * amb.s; magnitudeVariation: 30 * amb.s }
    }

    // ================= kiri =================
    Item {
        anchors.fill: parent
        visible: amb.name === "kiri"
        Fog { y: amb.height * 0.30; height: amb.height * 0.36; speed: 300000; tint: "#e8eeec"; opacity: 0.16 }
        Fog { y: amb.height * 0.52; height: amb.height * 0.34; speed: 170000; tint: "#eef3f1"; opacity: 0.22; rightwards: true }
        Fog { y: amb.height * 0.70; height: amb.height * 0.34; speed: 95000; tint: "#f4f7f6"; opacity: 0.24 }
        // the whole veil thickens and thins
        Rectangle {
            anchors.fill: parent
            color: "#e8eeec"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.02; to: 0.11; duration: 9000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.11; to: 0.02; duration: 9000; easing.type: Easing.InOutSine }
            }
        }
    }
    Emitter {
        system: sys; group: "mote"
        enabled: amb.name === "kiri"
        anchors.fill: parent
        emitRate: 4
        lifeSpan: 9000; lifeSpanVariation: 3000
        size: 3 * amb.s; sizeVariation: 2 * amb.s
        velocity: AngleDirection { angle: 200; angleVariation: 40; magnitude: 8 * amb.s; magnitudeVariation: 5 * amb.s }
    }

    // ================= hagane =================
    Emitter {
        system: sys; group: "snow"
        enabled: amb.name === "hagane"
        x: -amb.width * 0.1; y: -20; width: amb.width * 1.2; height: 10
        emitRate: 16
        lifeSpan: 24000
        size: 5 * amb.s; sizeVariation: 3 * amb.s
        velocity: AngleDirection { angle: 100; angleVariation: 10; magnitude: 48 * amb.s; magnitudeVariation: 20 * amb.s }
    }
    // a sheen of cold light runs diagonally across the screen every few seconds
    Item {
        id: sheenLane
        anchors.fill: parent
        visible: amb.name === "hagane"
        clip: true
        Rectangle {
            id: sheen
            width: 260 * amb.s; height: amb.height * 2.2
            y: -amb.height * 0.6
            x: -width * 2
            rotation: 18
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 0.52; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 1; color: "transparent" } }
            SequentialAnimation on x {
                running: sheenLane.visible; loops: Animation.Infinite
                PauseAnimation { duration: 2500 }
                NumberAnimation { from: -sheen.width * 2; to: amb.width + sheen.width; duration: 2600; easing.type: Easing.InOutCubic }
                PauseAnimation { duration: 7000 }
            }
        }
    }

    // ================= summit =================
    Item {
        anchors.fill: parent
        visible: amb.name === "summit"
        Fog { y: amb.height * 0.5; height: amb.height * 0.32; speed: 220000; tint: "#9fb4d8"; opacity: 0.24 }
        Fog { y: amb.height * 0.68; height: amb.height * 0.3; speed: 130000; tint: "#b8c8e8"; opacity: 0.2 }
    }
    Emitter {
        system: sys; group: "star"
        enabled: amb.name === "summit"
        x: 0; y: 0; width: amb.width; height: amb.height * 0.42
        emitRate: 12
        lifeSpan: 3600; lifeSpanVariation: 1800
        size: 7 * amb.s; sizeVariation: 4 * amb.s
        velocity: PointDirection { }
    }
    // gusts: now and then the wind blows snow off the ridge
    Emitter {
        id: gust
        system: sys; group: "snow"
        enabled: false
        x: amb.width; y: amb.height * 0.25; width: 20; height: amb.height * 0.35
        emitRate: 70
        lifeSpan: 7000; lifeSpanVariation: 2000
        size: 4 * amb.s; sizeVariation: 3 * amb.s
        velocity: AngleDirection { angle: 186; angleVariation: 8; magnitude: 300 * amb.s; magnitudeVariation: 120 * amb.s }
        acceleration: AngleDirection { angle: 90; magnitude: 14 * amb.s }
    }
    SequentialAnimation {
        running: amb.name === "summit" && amb.visible; loops: Animation.Infinite
        PauseAnimation { duration: 6000 }
        ScriptAction { script: gust.enabled = true }
        PauseAnimation { duration: 1400 }
        ScriptAction { script: gust.enabled = false }
        PauseAnimation { duration: 9000 }
    }
    // a shooting star: the lane jumps to a random spot, the streak runs a fixed path inside it
    Item {
        id: lane
        visible: amb.name === "summit"
        Rectangle {
            id: meteor
            width: 170 * amb.s; height: Math.max(1.5, 1.6 * amb.s)
            rotation: 26
            transformOrigin: Item.Right
            opacity: 0
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "#ffffff" } }
        }
        SequentialAnimation {
            running: lane.visible && amb.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 9000 }
            ScriptAction { script: { lane.x = amb.width * (0.4 + Math.random() * 0.4); lane.y = amb.height * (0.04 + Math.random() * 0.2); meteor.x = 0; meteor.y = 0; } }
            ParallelAnimation {
                NumberAnimation { target: meteor; property: "opacity"; from: 0; to: 0.9; duration: 160 }
                NumberAnimation { target: meteor; property: "x"; from: 0; to: 240 * amb.s; duration: 800; easing.type: Easing.InQuad }
                NumberAnimation { target: meteor; property: "y"; from: 0; to: 120 * amb.s; duration: 800; easing.type: Easing.InQuad }
            }
            NumberAnimation { target: meteor; property: "opacity"; to: 0; duration: 260 }
            PauseAnimation { duration: 6000 }
        }
    }
}
