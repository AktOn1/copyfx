import QtQuick
import "../.."

// Little paw prints trot along under the real text, and the letters hop as they pass.
SpriteText {
  id: fx
  total: 1500
  readonly property int steps: Math.max(4, Math.min(14, Math.floor(fx.tg.w / (fx.lh * 1.7))))
  readonly property real pawX: fx.tg.x + Math.min(1, fx.t / (fx.total * 0.8)) * fx.tg.w
  function bump(u) { return Math.max(0, 1 - Math.abs(u.cx - fx.pawX) / (fx.lh * 1.4)) }
  dyFn: function(u) { return -fx.lh * 0.25 * fx.bump(u) }
  tintFn: function(u) { return fx.bump(u) > 0.2 ? 2 : 0 }
  Repeater {
    model: fx.steps
    delegate: Item {
      required property int index
      readonly property real px: fx.tg.x + (index + 0.5) / fx.steps * fx.tg.w
      readonly property real shown: fx.pawX > px ? Math.min(1, (fx.pawX - px) / (fx.lh * 0.8)) : 0
      x: px; y: fx.tg.y + fx.tg.h + fx.lh * (0.5 + (index % 2) * 0.7)
      rotation: 12 * (index % 2 ? 1 : -1)
      opacity: shown * (fx.t > fx.total * 0.8 ? Math.max(0, 1 - (fx.t - fx.total * 0.8) / (fx.total * 0.2)) : 1) * fx.hlAlpha
      Rectangle { x: -fx.lh * 0.45; y: 0; width: fx.lh * 0.9; height: fx.lh * 0.75; radius: fx.lh * 0.38; color: "#c99a72" }
      Repeater {
        model: 4
        delegate: Rectangle {
          required property int index
          width: fx.lh * 0.3; height: fx.lh * 0.36; radius: width / 2; color: "#c99a72"
          x: -fx.lh * 0.66 + index * fx.lh * 0.4; y: -fx.lh * (index === 1 || index === 2 ? 0.5 : 0.22)
        }
      }
    }
  }
}
