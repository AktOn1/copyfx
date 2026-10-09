import QtQuick
import "../.."

// A rainbow grows in an arc over the real text while the letters glow in matching colours.
SpriteText {
  id: fx
  total: 1500
  readonly property real grow: Math.min(1, fx.t / (fx.total * 0.6))
  readonly property real fadeOut: fx.t > fx.total * 0.75 ? Math.max(0, 1 - (fx.t - fx.total * 0.75) / (fx.total * 0.25)) : 1
  onGrowChanged: arc.requestPaint()
  tintFn: function(u) { return fx.grow > 0.15 ? 1 + Math.min(11, Math.floor((u.cx - fx.tg.x) / Math.max(1, fx.tg.w) * 12)) : 0 }
  Canvas {
    id: arc
    anchors.fill: parent
    opacity: fx.fadeOut * fx.hlAlpha
    renderTarget: Canvas.Image
    onPaint: {
      var c = getContext("2d"); c.clearRect(0, 0, width, height)
      var cx = fx.tg.x + fx.tg.w / 2, R = Math.max(fx.tg.w / 2, fx.lh * 3), bw = Math.max(3, fx.lh * 0.32)
      var cols = [fx.theme.red, fx.theme.orange, fx.theme.yellow, fx.theme.green, "#1982c4", "#6a4c93", fx.theme.magenta]
      c.lineWidth = bw
      for (var i = 0; i < cols.length; i++) {
        c.strokeStyle = cols[i]; c.beginPath()
        c.arc(cx, fx.tg.y - fx.lh * 0.3, R - i * bw * 0.95, Math.PI, Math.PI + Math.PI * fx.grow, false); c.stroke()
      }
    }
  }
}
