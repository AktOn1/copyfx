import QtQuick
import "../.."

// A magnifying glass glides over the real text and blows up the letters under it.
SpriteText {
  id: fx
  total: 1100
  readonly property real lensX: fx.tg.x - fx.lh * 2 + Math.min(1, fx.t / fx.total) * (fx.tg.w + fx.lh * 4)
  function near(u) { return Math.max(0, 1 - Math.abs(u.cx - fx.lensX) / (fx.lh * 2.2)) }
  scaleFn: function(u) { return 1 + 0.9 * fx.near(u) }
  dyFn: function(u) { return -fx.lh * 0.25 * fx.near(u) }
  tintFn: function(u) { return fx.near(u) > 0.15 ? 13 : 0 }
  Rectangle {                                                    // the lens
    readonly property real d: fx.lh * 3.4
    x: fx.lensX - d / 2; y: fx.tg.y + fx.tg.h / 2 - d / 2 - fx.lh * 0.3; width: d; height: d; radius: d / 2
    color: "#18ffffff"; border.color: fx.accent; border.width: Math.max(2, fx.lh * 0.14)
    opacity: fx.hlAlpha
  }
  Rectangle {
    readonly property real d: fx.lh * 3.4
    x: fx.lensX + d * 0.35; y: fx.tg.y + fx.tg.h / 2 + d * 0.38 - fx.lh * 0.3; width: d * 0.55; height: Math.max(3, fx.lh * 0.2); radius: height / 2
    rotation: 45; color: fx.accent; opacity: fx.hlAlpha
  }
}
