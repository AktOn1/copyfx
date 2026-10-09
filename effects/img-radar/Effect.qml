import QtQuick
import "../.."

// A ping ring spreads from the middle of the real text; each letter it touches lights up green and swells.
SpriteText {
  id: fx
  total: 1200
  readonly property real cx: fx.tg.x + fx.tg.w / 2
  readonly property real cy: fx.tg.y + fx.tg.h / 2
  readonly property real rad: Math.min(1, fx.t / (fx.total * 0.85)) * (fx.tg.w / 2 + fx.lh * 3)
  function band(u) { var d = Math.sqrt((u.cx - fx.cx) * (u.cx - fx.cx) + (u.cy - fx.cy) * (u.cy - fx.cy)); return Math.max(0, 1 - Math.abs(d - fx.rad) / (fx.lh * 1.6)) }
  scaleFn: function(u) { return 1 + 0.35 * fx.band(u) }
  tintFn: function(u) { return fx.band(u) > 0.1 ? 15 : 0 }
  Rectangle {
    x: fx.cx - fx.rad; y: fx.cy - fx.rad; width: fx.rad * 2; height: fx.rad * 2; radius: fx.rad
    color: "transparent"; border.color: "#00ff41"; border.width: 2
    opacity: fx.rad <= 0 ? 0 : 0.8 * (1 - fx.rad / (fx.tg.w / 2 + fx.lh * 3)) * fx.hlAlpha
  }
}
