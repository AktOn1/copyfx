import QtQuick
import "../.."

// Clouds drift across the real text and dim the letters as they pass; the sky cover follows the real cloudiness.
SpriteText {
  id: fx
  total: 2000
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  readonly property int count: 2 + Math.round(fx.weather.cloud / 34)
  function cx(i) { return fx.tg.x - fx.tg.w * 0.4 + ((fx.t / fx.total * (0.8 + 0.5 * fx.hash(i, 1)) + fx.hash(i, 2)) % 1) * (fx.tg.w * 1.8) }
  function shade(u) { var s = 0; for (var i = 0; i < fx.count; i++) { var w = fx.lh * (3 + 2 * fx.hash(i, 3)); if (Math.abs(u.cx - fx.cx(i)) < w * 0.6) s = 0.45; } return s * fx.env }
  alphaFn: function(u) { return 1 - fx.shade(u) }
  Repeater {
    model: fx.count
    delegate: Item {
      required property int index
      readonly property real w: fx.lh * (3 + 2 * fx.hash(index, 3))
      x: fx.cx(index) - w / 2; y: fx.tg.y + fx.tg.h * (0.1 + 0.6 * fx.hash(index, 4)) - fx.lh * 1.4
      opacity: 0.92 * fx.env * fx.hlAlpha
      Rectangle { x: 0; y: parent.w * 0.2; width: parent.w; height: parent.w * 0.3; radius: height / 2; color: "#f4f7fa" }
      Rectangle { x: parent.w * 0.15; y: parent.w * 0.06; width: parent.w * 0.38; height: parent.w * 0.38; radius: width / 2; color: "#ffffff" }
      Rectangle { x: parent.w * 0.42; y: 0; width: parent.w * 0.44; height: parent.w * 0.44; radius: width / 2; color: "#f9fbfc" }
      Rectangle { x: 0; y: parent.w * 0.38; width: parent.w; height: parent.w * 0.12; radius: height / 2; color: "#d3dce4" }
    }
  }
}
