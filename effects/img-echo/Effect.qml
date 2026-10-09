import QtQuick
import "../.."

// A ring pulses on the real text and the selection flashes in the accent colour.
SpriteText {
  id: fx
  total: 900
  Rectangle {
    x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; radius: 3
    color: fx.accent; opacity: fx.t < 120 ? fx.t / 120 * 0.4 : Math.max(0, 0.4 * (1 - (fx.t - 120) / 500))
  }
  Rectangle {
    readonly property real p: Math.min(1, fx.t / 520)
    readonly property real d: 20 + p * Math.max(fx.tg.w, 90)
    x: fx.tg.x + fx.tg.w / 2 - d / 2; y: fx.tg.y + fx.tg.h / 2 - d / 2; width: d; height: d; radius: d / 2
    color: "transparent"; border.color: fx.accent; border.width: 2
    opacity: fx.t <= 0 ? 0 : 0.9 * (1 - p)
  }
}
