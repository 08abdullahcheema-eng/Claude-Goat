pragma Singleton
import QtQuick
import Quickshell

// Sun and moon for the landscape bars: how far the day has gone, how full the moon is.
Singleton {
    readonly property var d: Dev.clockDate
    readonly property real hour: d.getHours() + d.getMinutes() / 60
    // daylight from 7 to 19 o'clock, night the rest
    readonly property bool night: hour < 7 || hour >= 19
    readonly property real day: Math.max(0, Math.min(1, (hour - 7) / 12))
    readonly property real nightPart: { const h = hour < 7 ? hour + 24 : hour; return Math.max(0, Math.min(1, (h - 19) / 12)); }
    // moon: days since the new moon of 2024-01-11 11:57 UTC over the synodic month
    readonly property real moonPhase: { const p = ((d.getTime() / 1000 - 1704974220) / 86400) / 29.530588853; return p - Math.floor(p); }
    readonly property int moon: Math.round((1 - Math.cos(2 * Math.PI * moonPhase)) / 2 * 100)
}
