import QtQuick
import "../.."

// The real text flashes stamp-red with a shake, a border and a shockwave.
SpriteText {
  id: fx
  total: 900
  dxFn: function(u) { return fx.t < 240 ? (u.i % 2 ? 2 : -2) * (1 - fx.t / 240) : 0 }
  tintFn: function() { return fx.t < 520 ? 1 : 0 }
  Rectangle { x: fx.tg.x - 6; y: fx.tg.y - 4; width: fx.tg.w + 12; height: fx.tg.h + 8; radius: 6; color: "transparent"; border.color: fx.theme.red; border.width: 2; opacity: fx.t < 520 ? 1 : Math.max(0, 1 - (fx.t - 520) / 300) }
  Rectangle {
    readonly property real p: Math.min(1, fx.t / 550)
    readonly property real d: 30 + p * Math.max(fx.tg.w, 120)
    x: fx.tg.x + fx.tg.w / 2 - d / 2; y: fx.tg.y + fx.tg.h / 2 - d / 2; width: d; height: d; radius: d / 2
    color: "transparent"; border.color: fx.accent; border.width: 3; opacity: fx.t <= 0 ? 0 : 0.8 * (1 - p)
  }
}
