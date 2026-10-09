import QtQuick
import "../.."

// A gust bends the real letters over and blows them sideways, leaves and dust whipping past; direction and strength come from the real wind.
SpriteText {
  id: fx
  total: 1500
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  dxFn: function(u) { return fx.windSign * fx.lh * (0.5 + 2.4 * fx.windAmt) * fx.env * (0.6 + 0.4 * Math.sin(u.i * 0.5 - fx.t / 120)) }
  rotFn: function(u) { return fx.windSign * (6 + 16 * fx.windAmt) * fx.env * (0.7 + 0.3 * Math.sin(fx.t / 100 + u.i)) }
  Repeater {
    model: 26
    delegate: Rectangle {
      required property int index
      readonly property real span: fx.tg.w + fx.lh * 8
      readonly property real p: (fx.t / (700 - 300 * fx.windAmt) + fx.hash(index, 1)) % 1
      width: fx.lh * (1.4 + 3 * fx.windAmt) * (0.5 + fx.hash(index, 2)); height: Math.max(1.5, fx.lh * 0.07); color: "#e8eef2"
      x: fx.windSign > 0 ? fx.tg.x - fx.lh * 4 + p * span : fx.tg.x + fx.tg.w + fx.lh * 4 - p * span - width
      y: fx.tg.y - fx.lh * 1.2 + (fx.tg.h + fx.lh * 2.4) * fx.hash(index, 3)
      opacity: 0.5 * fx.env * fx.hlAlpha
    }
  }
  Repeater {
    model: 9
    delegate: Rectangle {                                       // leaves
      required property int index
      readonly property real span: fx.tg.w + fx.lh * 8
      readonly property real p: (fx.t / 900 + fx.hash(index, 7)) % 1
      width: fx.lh * 0.34; height: fx.lh * 0.2; radius: height / 2; color: index % 2 ? "#c8873c" : "#8a9b3a"
      rotation: p * 720
      x: fx.windSign > 0 ? fx.tg.x - fx.lh * 4 + p * span : fx.tg.x + fx.tg.w + fx.lh * 4 - p * span
      y: fx.tg.y - fx.lh + (fx.tg.h + fx.lh * 2) * fx.hash(index, 8) + Math.sin(p * 12 + index) * fx.lh * 0.5
      opacity: 0.85 * fx.env * fx.hlAlpha
    }
  }
}
