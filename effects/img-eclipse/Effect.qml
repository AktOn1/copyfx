import QtQuick
import "../.."

// A dark moon slides across the real text, hiding the letters and lighting a golden corona at its edge.
SpriteText {
  id: fx
  total: 1500
  readonly property real mx: fx.tg.x - fx.lh * 2 + Math.min(1, fx.t / fx.total) * (fx.tg.w + fx.lh * 4)
  readonly property real rad: Math.max(fx.lh * 1.5, fx.tg.h * 0.75)
  function d(u) { return Math.abs(u.cx - fx.mx) }
  alphaFn: function(u) { return fx.d(u) < fx.rad * 0.9 ? 0 : 1 }
  tintFn: function(u) { var d = fx.d(u); return d >= fx.rad * 0.9 && d < fx.rad * 1.6 ? 16 : 0 }
  scaleFn: function(u) { var d = fx.d(u); return d >= fx.rad * 0.9 && d < fx.rad * 1.6 ? 1.25 : 1 }
  Rectangle {
    readonly property real dd: fx.rad * 2
    x: fx.mx - dd / 2; y: fx.tg.y + fx.tg.h / 2 - dd / 2; width: dd; height: dd; radius: dd / 2
    color: "#05050a"; border.color: fx.theme.yellow; border.width: Math.max(2, fx.lh * 0.16); opacity: fx.hlAlpha
  }
  Rectangle {
    readonly property real dd: fx.rad * 2.7
    x: fx.mx - dd / 2; y: fx.tg.y + fx.tg.h / 2 - dd / 2; width: dd; height: dd; radius: dd / 2
    color: "transparent"; border.color: "#66ffb347"; border.width: Math.max(3, fx.lh * 0.3); opacity: 0.8 * fx.hlAlpha
  }
}
