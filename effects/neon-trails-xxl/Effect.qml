import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 11 : Math.round(fx.fontSize * 0.85)
  property real prog: 0        // how far the cycles got, 0..1 (each covers half of the frame)
  property real flash: 0
  property real fade: 1
  readonly property real pad: 20 * fx.u + 6

  Item {
    id: box
    width: label.width + fx.pad * 2
    height: label.height + fx.pad * 1.6
    x: fx.boxX(width)
    y: fx.boxY(height)
    opacity: fx.fade

    Rectangle { anchors.fill: parent; color: "#02060d"; opacity: 0.88 }

    Canvas {            // the neon grid
      anchors.fill: parent
      renderTarget: Canvas.Image
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.clearRect(0, 0, width, height)
        c.strokeStyle = "rgba(0,229,255,0.13)"
        c.lineWidth = 1
        for (var x = 0; x < width; x += 14) { c.beginPath(); c.moveTo(x + 0.5, 0); c.lineTo(x + 0.5, height); c.stroke() }
        for (var y = 0; y < height; y += 14) { c.beginPath(); c.moveTo(0, y + 0.5); c.lineTo(width, y + 0.5); c.stroke() }
      }
    }

    FxText { textFormat: Text.PlainText;
      id: label
      x: fx.pad
      y: fx.pad * 0.8
      text: fx.text
      color: "#e6ffff"
      font.family: "monospace"
      font.bold: true
      font.pixelSize: fx.fs
      maxWidth: Math.min(fx.width * (fx.compact ? 0.7 : 0.5), 640)
      maxLines: 8
    }

    Canvas {            // the trails
      id: trails
      anchors.fill: parent
      renderTarget: Canvas.Image
      property real p: fx.prog
      property real fl: fx.flash
      onPChanged: requestPaint()
      onFlChanged: requestPaint()
      onPaint: {
        var c = getContext("2d"), m = 3, L = m, T = m, R = width - m, B = height - m
        var W = R - L, H = B - T, per = 2 * (W + H)
        c.clearRect(0, 0, width, height)
        function pt(d) {                      // point at distance d along the frame, clockwise from the top-left corner
          d = ((d % per) + per) % per
          if (d < W) return [L + d, T]
          d -= W; if (d < H) return [R, T + d]
          d -= H; if (d < W) return [R - d, B]
          d -= W; return [L, B - d]
        }
        function trail(from, len, col) {
          if (len <= 0) return
          c.beginPath()
          var a = pt(from); c.moveTo(a[0], a[1])
          var corners = [W, W + H, 2 * W + H, per]
          for (var i = 0; i < corners.length; i++) {
            var d = corners[i], rel = d - (from % per)
            if (rel > 0 && rel < len) { var q = pt(d); c.lineTo(q[0], q[1]) }
          }
          var e = pt(from + len); c.lineTo(e[0], e[1])
          c.shadowColor = col; c.shadowBlur = 10
          c.strokeStyle = fl > 0 ? "#ffffff" : col
          c.lineWidth = 3
          c.stroke()
          c.shadowBlur = 0
          c.fillStyle = "#ffffff"; c.fillRect(e[0] - 4, e[1] - 4, 8, 8)     // the cycle itself
        }
        var half = per / 2, len = half * p
        trail(0, len, "#00e5ff")              // cyan from the top-left
        trail(half, len, "#ff9a1f")           // orange from the bottom-right
      }
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "prog"; to: 1; duration: fx.compact ? 350 : 520; easing.type: Easing.InQuad }
    PauseAnimation { duration: Math.max(300, fx.readMs) }
    NumberAnimation { target: fx; property: "flash"; to: 1; duration: 90 }               // derezz
    NumberAnimation { target: fx; property: "fade"; to: 0; duration: 350 }
  }
}
