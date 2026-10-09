import QtQuick
import "../.."

// Coloured spotlights swing over the real text and the letters change colour on every beat.
SpriteText {
  id: fx
  total: 1600
  readonly property real beat: Math.floor(fx.t / 130)
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  hlColor: "#0b0616"
  tintFn: function(u) { return fx.env > 0.03 ? 1 + ((fx.beat + u.i) % 12) : 0 }
  scaleFn: function() { return 1 + 0.08 * fx.env * (fx.beat % 2) }
  Repeater {
    model: 3
    delegate: Rectangle {
      required property int index
      readonly property real d: fx.lh * 3.2
      x: fx.tg.x + (fx.tg.w) * (0.5 + 0.5 * Math.sin(fx.t / 260 + index * 2.1)) - d / 2
      y: fx.tg.y + fx.tg.h / 2 - d / 2 + Math.sin(fx.t / 190 + index) * fx.lh * 0.6
      width: d; height: d; radius: d / 2
      color: index === 0 ? "#55ff3b9a" : index === 1 ? "#5533c8ff" : "#55ffe14d"; opacity: fx.env * fx.hlAlpha
    }
  }
  Repeater {                                                  // glitter
    model: 12
    delegate: Rectangle {
      required property int index
      width: Math.max(2, fx.lh * 0.14); height: width; rotation: 45; color: "#ffffff"
      x: fx.tg.x + fx.tg.w * fx.hash(index, 1); y: fx.tg.y + fx.tg.h * fx.hash(index, 2)
      opacity: Math.floor(fx.t / 90 + index) % 3 === 0 ? fx.env * fx.hlAlpha : 0
    }
  }
}
