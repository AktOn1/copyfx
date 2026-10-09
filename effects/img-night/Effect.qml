import QtQuick
import "../.."

// Stars twinkle around the real text and a crescent moon rises; the letters take on a pale moonlight.
SpriteText {
  id: fx
  total: 1900
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  onEnvChanged: moon.requestPaint()
  tintFn: function() { return fx.env > 0.1 ? 21 : 0 }
  Repeater {
    model: 36
    delegate: Rectangle {
      required property int index
      width: Math.max(1.5, fx.lh * (0.06 + 0.1 * fx.hash(index, 1))); height: width; rotation: 45; color: "#fdf6d6"
      x: fx.tg.x - fx.lh * 2 + (fx.tg.w + fx.lh * 4) * fx.hash(index, 2); y: fx.tg.y - fx.lh * 2.5 + (fx.tg.h + fx.lh * 5) * fx.hash(index, 3)
      opacity: (0.4 + 0.6 * Math.abs(Math.sin(fx.t / 260 + index * 1.7))) * fx.env * fx.hlAlpha
    }
  }
  Canvas {
    id: moon
    anchors.fill: parent
    renderTarget: Canvas.Image
    opacity: fx.env * fx.hlAlpha
    onPaint: {
      var c = getContext("2d"); c.clearRect(0, 0, width, height)
      var r = fx.lh * 1.1, cx = fx.tg.x + fx.tg.w + fx.lh * 1.6, cy = fx.tg.y - fx.lh * 0.6
      c.fillStyle = "#f7f1c8"; c.shadowColor = "#f7f1c8"; c.shadowBlur = 12
      c.beginPath(); c.arc(cx, cy, r, Math.PI * 0.5, Math.PI * 1.5, false)
      c.bezierCurveTo(cx - r * 0.9, cy - r * 0.6, cx - r * 0.9, cy + r * 0.6, cx, cy + r); c.fill()
    }
  }
}
