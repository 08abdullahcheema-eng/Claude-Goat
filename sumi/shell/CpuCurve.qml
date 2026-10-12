import QtQuick

// A smooth line of the last CPU samples (Sys.hist) with a soft fill under it.
Canvas {
    id: cv
    property color color: Theme.accent
    property int samples: 24
    property bool fill: true
    property real lineWidth: Theme.px(1.5)
    implicitWidth: Theme.px(58)
    implicitHeight: Theme.px(16)
    readonly property var data: Sys.hist.slice(-samples)
    onDataChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    renderStrategy: Canvas.Cooperative

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const v = data.length > 1 ? data : [0, 0];
        const n = v.length, w = width, h = height, pad = lineWidth + 1;
        const X = i => pad + i * (w - 2 * pad) / (n - 1);
        const Y = x => h - pad - Math.max(0, Math.min(100, x)) / 100 * (h - 2 * pad);
        const path = () => {
            c.beginPath();
            c.moveTo(X(0), Y(v[0]));
            for (let i = 1; i < n; i++) {
                const xm = (X(i - 1) + X(i)) / 2;
                c.bezierCurveTo(xm, Y(v[i - 1]), xm, Y(v[i]), X(i), Y(v[i]));
            }
        };
        if (fill) {
            path();
            c.lineTo(X(n - 1), h); c.lineTo(X(0), h); c.closePath();
            const g = c.createLinearGradient(0, 0, 0, h);
            g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.38));
            g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
            c.fillStyle = g; c.fill();
        }
        path();
        c.strokeStyle = color; c.lineWidth = lineWidth; c.lineCap = "round"; c.lineJoin = "round";
        c.stroke();
        c.beginPath(); c.arc(X(n - 1), Y(v[n - 1]), lineWidth * 1.4, 0, 2 * Math.PI); c.fillStyle = color; c.fill();
    }
}
