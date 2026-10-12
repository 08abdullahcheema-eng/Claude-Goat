import QtQuick
import QtQuick.Particles
import QtQuick.Effects

// Slow, quiet motion over the login wallpaper, one mood per theme:
// drifting fog, sand on the wind, twinkling stars, falling snow, rising embers, a shooting star.
Item {
    id: amb
    property string name: "sumi"
    property color accent: "#c8323a"
    property color accent2: "#e46876"
    property color fg: "#dcd7ba"
    property real s: 1

    readonly property bool fogTheme: ["kiri", "iso", "summit", "unkai", "suna", "dune"].indexOf(name) >= 0
    readonly property bool starTheme: ["summit", "unkai", "ginga"].indexOf(name) >= 0

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
                duration: fog.speed; loops: Animation.Infinite
            }
        }
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1.0; colorizationColor: fog.tint }
    }

    // ---- fog and clouds ----
    Fog {   // far layer
        visible: amb.fogTheme
        y: amb.name === "unkai" ? amb.height * 0.52 : amb.name === "summit" ? amb.height * 0.5 : amb.height * 0.6
        height: amb.name === "unkai" ? amb.height * 0.5 : amb.height * 0.32
        speed: amb.name === "unkai" ? 160000 : 220000
        rightwards: amb.name === "dune" || amb.name === "suna"
        tint: amb.name === "unkai" ? "#c9bcd8" : (amb.name === "dune" || amb.name === "suna") ? "#e8c49a" : amb.name === "summit" ? "#9fb4d8" : "#e8eeec"
        opacity: amb.name === "unkai" ? 0.34 : (amb.name === "dune" || amb.name === "suna") ? 0.16 : 0.26
    }
    Fog {   // near layer, faster
        visible: amb.fogTheme && amb.name !== "dune" && amb.name !== "suna"
        y: amb.name === "unkai" ? amb.height * 0.66 : amb.height * 0.68
        height: amb.name === "unkai" ? amb.height * 0.42 : amb.height * 0.3
        speed: amb.name === "unkai" ? 90000 : 130000
        tint: amb.name === "unkai" ? "#e8d4dc" : amb.name === "summit" ? "#b8c8e8" : "#f2f6f4"
        opacity: amb.name === "unkai" ? 0.28 : 0.2
    }

    ParticleSystem { id: sys; anchors.fill: parent; running: amb.visible }

    // ---- twinkling stars ----
    ImageParticle {
        system: sys; groups: ["star"]
        source: "dot.png"
        color: "#ffffff"; colorVariation: 0.08
        alpha: 0.9
        entryEffect: ImageParticle.Fade
    }
    Emitter {
        system: sys; group: "star"
        enabled: amb.starTheme
        x: 0; y: 0; width: amb.width
        height: amb.name === "ginga" ? amb.height * 0.75 : amb.height * 0.4
        emitRate: amb.name === "ginga" ? 26 : 12
        lifeSpan: 3600; lifeSpanVariation: 1800
        size: 7 * amb.s; sizeVariation: 4 * amb.s
        velocity: PointDirection { }
    }

    // ---- sand on the wind ----
    ImageParticle { system: sys; groups: ["sand"]; source: "dot.png"; color: amb.accent2; alpha: 0.4; alphaVariation: 0.2; entryEffect: ImageParticle.Fade }
    Emitter {
        system: sys; group: "sand"
        enabled: amb.name === "dune" || amb.name === "suna"
        x: -20; y: amb.height * 0.45; width: 20; height: amb.height * 0.55
        emitRate: 34
        lifeSpan: 16000; lifeSpanVariation: 4000
        size: 4 * amb.s; sizeVariation: 2 * amb.s
        velocity: AngleDirection { angle: 4; angleVariation: 6; magnitude: 130 * amb.s; magnitudeVariation: 60 * amb.s }
    }

    // ---- snow ----
    ImageParticle { system: sys; groups: ["snow"]; source: "dot.png"; color: "#ffffff"; alpha: 0.75; alphaVariation: 0.2; entryEffect: ImageParticle.Fade }
    Emitter {
        system: sys; group: "snow"
        enabled: amb.name === "hagane"
        x: -amb.width * 0.1; y: -20; width: amb.width * 1.2; height: 10
        emitRate: 28
        lifeSpan: 22000
        size: 7 * amb.s; sizeVariation: 4 * amb.s
        velocity: AngleDirection { angle: 98; angleVariation: 12; magnitude: 55 * amb.s; magnitudeVariation: 25 * amb.s }
    }

    // ---- embers rising (sumi) ----
    ImageParticle { system: sys; groups: ["ember"]; source: "dot.png"; color: amb.accent; alpha: 0.6; alphaVariation: 0.3; entryEffect: ImageParticle.Fade }
    Emitter {
        system: sys; group: "ember"
        enabled: amb.name === "sumi"
        x: 0; y: amb.height; width: amb.width; height: 10
        emitRate: 7
        lifeSpan: 16000; lifeSpanVariation: 5000
        size: 6 * amb.s; sizeVariation: 3 * amb.s
        velocity: AngleDirection { angle: 270; angleVariation: 14; magnitude: 40 * amb.s; magnitudeVariation: 18 * amb.s }
    }

    // ---- a shooting star now and then (ginga) ----
    // the lane jumps to a random spot, the streak runs a fixed path inside it
    Item {
        id: lane
        visible: amb.name === "ginga"
        Rectangle {
            id: meteor
            width: 190 * amb.s; height: Math.max(1.5, 1.6 * amb.s)
            rotation: 28
            transformOrigin: Item.Right
            opacity: 0
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "#ffffff" } }
        }
        SequentialAnimation {
            running: lane.visible && amb.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 5200 }
            ScriptAction { script: { lane.x = amb.width * (0.15 + Math.random() * 0.55); lane.y = amb.height * (0.05 + Math.random() * 0.25); meteor.x = 0; meteor.y = 0; } }
            ParallelAnimation {
                NumberAnimation { target: meteor; property: "opacity"; from: 0; to: 0.95; duration: 160 }
                NumberAnimation { target: meteor; property: "x"; from: 0; to: 260 * amb.s; duration: 850; easing.type: Easing.InQuad }
                NumberAnimation { target: meteor; property: "y"; from: 0; to: 140 * amb.s; duration: 850; easing.type: Easing.InQuad }
            }
            NumberAnimation { target: meteor; property: "opacity"; to: 0; duration: 260 }
            PauseAnimation { duration: 3600 }
        }
    }
}
