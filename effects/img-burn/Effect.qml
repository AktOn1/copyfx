import QtQuick
import "../.."

// Fire runs along the real text: the letters glow red, curl up and burn away, embers rising.
SpriteText {
  id: fx
  total: 1400
  readonly property real front: fx.tg.x + Math.min(1, fx.t / (fx.total * 0.8)) * (fx.tg.w + fx.lh * 3) - fx.lh * 1.5
  function heat(u) { return Math.max(0, Math.min(1, (fx.front - u.cx) / (fx.lh * 3))) }       // 0 before the flame, 1 well behind it
  alphaFn: function(u) { var h = fx.heat(u); return h > 0.55 ? Math.max(0, 1 - (h - 0.55) / 0.3) : 1 }
  dyFn: function(u) { return -fx.lh * 0.6 * fx.heat(u) }
  scaleFn: function(u) { return 1 - 0.25 * fx.heat(u) }
  tintFn: function(u) { var h = fx.heat(u); return h <= 0 ? 0 : h < 0.3 ? 1 : h < 0.6 ? 2 : 16 }
  Repeater {                                                     // embers
    model: 26
    delegate: Rectangle {
      required property int index
      readonly property real life: (fx.t / 700 + fx.hash(index, 1)) % 1
      x: fx.front - fx.hash(index, 2) * fx.lh * 3 + (fx.hash(index, 3) - 0.5) * fx.lh
      y: fx.tg.y + fx.tg.h * (0.2 + 0.6 * fx.hash(index, 4)) - life * fx.lh * 2.6
      width: Math.max(2, fx.lh * 0.12); height: width
      color: life < 0.5 ? "#ffb000" : fx.theme.orange
      opacity: fx.front > fx.tg.x && fx.front < fx.tg.x + fx.tg.w + fx.lh * 3 ? (1 - life) * 0.9 : 0
    }
  }
}
