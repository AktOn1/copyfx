import QtQuick
import "../.."

// A green CRT oscilloscope sweeps a waveform built from the copied bytes over the real text.
SpriteText {
  id: fx
  total: 1500
  readonly property real sweep: Math.min(1, fx.t / (fx.total * 0.8))
  hlColor: "#031a0a"
  tintFn: function() { return 15 }
  onSweepChanged: trace.requestPaint()
  Rectangle {
    x: fx.tg.x - fx.lh * 0.6; y: fx.tg.y - fx.lh * 0.8; width: fx.tg.w + fx.lh * 1.2; height: fx.tg.h + fx.lh * 1.6
    color: "#021207"; opacity: 0.55 * fx.hlAlpha; z: -1; border.color: "#0b5d2a"; border.width: 1
  }
  Canvas {
    id: trace
    anchors.fill: parent
    opacity: fx.hlAlpha
    renderTarget: Canvas.Image
    onPaint: {
      var c = getContext("2d"); c.clearRect(0, 0, width, height)
      var x0 = fx.tg.x - fx.lh * 0.6, y0 = fx.tg.y - fx.lh * 0.8, w = fx.tg.w + fx.lh * 1.2, h = fx.tg.h + fx.lh * 1.6
      c.strokeStyle = "rgba(0,255,65,0.16)"; c.lineWidth = 1
      for (var gx = 0; gx <= 10; gx++) { c.beginPath(); c.moveTo(x0 + w * gx / 10, y0); c.lineTo(x0 + w * gx / 10, y0 + h); c.stroke() }
      for (var gy = 0; gy <= 4; gy++) { c.beginPath(); c.moveTo(x0, y0 + h * gy / 4); c.lineTo(x0 + w, y0 + h * gy / 4); c.stroke() }
      var txt = fx.text, m = Math.max(1, Math.min(64, txt.length))
      c.strokeStyle = "#7dff9a"; c.lineWidth = 2; c.shadowColor = "#00ff41"; c.shadowBlur = 6; c.beginPath()
      var steps = 160
      for (var i = 0; i <= steps * fx.sweep; i++) {
        var f = i / steps, code = txt.charCodeAt(Math.floor(f * (m - 1))) || 64
        var y = y0 + h / 2 + Math.sin(f * 40) * h * 0.28 * ((code % 32) / 32 + 0.25)
        if (i === 0) c.moveTo(x0 + w * f, y); else c.lineTo(x0 + w * f, y)
      }
      c.stroke()
    }
  }
}
