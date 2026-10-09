import QtQuick
import "../.."

// The sky flashes white, a lightning bolt strikes the real text and the letters jolt.
SpriteText {
  id: fx
  total: 1300
  readonly property bool f1: fx.t > 300 && fx.t < 360
  readonly property bool f2: fx.t > 470 && fx.t < 520
  readonly property bool flash: fx.f1 || fx.f2
  onFlashChanged: bolt.requestPaint()
  alphaFn: function() { return fx.t < 300 ? 0.55 : 1 }
  dxFn: function(u) { return fx.flash ? (fx.hash(u.i, Math.floor(fx.t / 25)) - 0.5) * fx.lh * 0.4 : 0 }
  tintFn: function() { return fx.flash ? 14 : 0 }
  Rectangle { x: fx.tg.x - fx.lh * 3; y: fx.tg.y - fx.lh * 4; width: fx.tg.w + fx.lh * 6; height: fx.tg.h + fx.lh * 8; color: "#ffffff"; opacity: (fx.flash ? 0.45 : 0) * fx.hlAlpha }
  Canvas {
    id: bolt
    anchors.fill: parent
    visible: fx.flash
    renderTarget: Canvas.Image
    onPaint: {
      var c = getContext("2d"); c.clearRect(0, 0, width, height)
      if (!fx.flash) return
      var x = fx.tg.x + fx.tg.w * (fx.f1 ? 0.35 : 0.68), y = fx.tg.y - fx.lh * 4, ty = fx.tg.y + fx.tg.h * 0.4, seg = 9
      c.strokeStyle = "#f4f7ff"; c.lineWidth = Math.max(2, fx.lh * 0.16); c.shadowColor = "#9db8ff"; c.shadowBlur = 14; c.beginPath(); c.moveTo(x, y)
      for (var i = 1; i <= seg; i++) { x += (fx.hash(i, fx.f1 ? 1 : 2) - 0.5) * fx.lh * 1.4; y += (ty - y) / (seg - i + 1); c.lineTo(x, y) }
      c.stroke()
    }
  }
}
