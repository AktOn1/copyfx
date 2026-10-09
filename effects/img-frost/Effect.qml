import QtQuick
import "../.."

// Ice crystals grow on the real text and the letters shiver; colder weather, more frost.
SpriteText {
  id: fx
  total: 1700
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  readonly property real cold: Math.max(0.25, Math.min(1, (6 - fx.weather.temp) / 22 + 0.3))
  dxFn: function(u) { return (fx.hash(u.i, Math.floor(fx.t / 45)) - 0.5) * fx.lh * 0.09 * fx.cold * fx.env }
  tintFn: function() { return fx.env > 0.08 ? 19 : 0 }
  Rectangle { x: fx.tg.x - 2; y: fx.tg.y - 2; width: fx.tg.w * Math.min(1, fx.t / 500) + 4; height: 3; color: "#d8f4ff"; opacity: 0.7 * fx.env * fx.hlAlpha }
  Rectangle { x: fx.tg.x - 2; y: fx.tg.y + fx.tg.h - 1; width: fx.tg.w * Math.min(1, fx.t / 500) + 4; height: 3; color: "#d8f4ff"; opacity: 0.7 * fx.env * fx.hlAlpha }
  Repeater {
    model: fx.units
    delegate: Text { textFormat: Text.PlainText;
      required property var modelData
      readonly property real k: Math.max(0, Math.min(1, (fx.t - 100 - fx.hash(modelData.i, 1) * 700) / 420))
      visible: modelData.i % Math.max(1, Math.round(3 - 2 * fx.cold)) === 0 && k > 0
      text: modelData.i % 3 === 0 ? "❄" : modelData.i % 3 === 1 ? "❅" : "❆"
      color: "#e9f9ff"; font.pixelSize: fx.lh * 0.85
      scale: k; rotation: k * 90
      x: modelData.cx - width / 2; y: (modelData.i % 2 ? modelData.y - height * 0.55 : modelData.y + modelData.h - height * 0.45)
      opacity: fx.env * fx.hlAlpha
    }
  }
}
