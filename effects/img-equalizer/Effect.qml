import QtQuick
import "../.."

// Every real letter bounces like a bar of a music equalizer with coloured level bars underneath.
SpriteText {
  id: fx
  total: 1500
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  function lvl(i) { return 0.25 + 0.75 * Math.abs(Math.sin(fx.t / 95 + fx.hash(i, 1) * 6.28)) * (0.6 + 0.4 * Math.sin(fx.t / 260 + i)) }
  dyFn: function(u) { return -fx.lh * 0.45 * fx.lvl(u.i) * fx.env }
  tintFn: function(u) { return fx.env > 0.05 ? 5 + Math.min(4, Math.floor(fx.lvl(u.i) * 5)) : 0 }
  Repeater {
    model: fx.units
    delegate: Rectangle {
      required property var modelData
      readonly property real l: fx.lvl(modelData.i) * fx.env
      x: modelData.x + modelData.w * 0.1; width: Math.max(2, modelData.w * 0.8)
      height: Math.max(1, fx.lh * 1.4 * l); y: modelData.y + modelData.h + fx.lh * 0.25
      color: l > 0.75 ? fx.theme.red : l > 0.45 ? fx.theme.yellow : fx.theme.green; opacity: fx.hlAlpha
    }
  }
}
