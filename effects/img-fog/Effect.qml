import QtQuick
import "../.."

// Fog banks drift over the real text and the letters fade into the haze and back.
SpriteText {
  id: fx
  total: 1900
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  alphaFn: function() { return 1 - 0.62 * fx.env }
  dxFn: function(u) { return Math.sin(fx.t / 520 + u.i * 0.35) * fx.lh * 0.22 * fx.env }
  Rectangle {
    x: fx.tg.x - fx.lh; y: fx.tg.y - fx.lh * 0.6; width: fx.tg.w + fx.lh * 2; height: fx.tg.h + fx.lh * 1.2
    color: "#dfe7ec"; opacity: 0.22 * fx.env * fx.hlAlpha
  }
  Repeater {
    model: 5
    delegate: Rectangle {
      required property int index
      readonly property real w: fx.tg.w * (0.5 + 0.25 * fx.hash(index, 1))
      width: w; height: fx.lh * (1.5 + fx.hash(index, 2)); radius: height / 2
      x: fx.tg.x - w + ((fx.t / fx.total * (0.7 + 0.5 * fx.hash(index, 3)) + fx.hash(index, 4)) % 1) * (fx.tg.w + w * 2)
      y: fx.tg.y + fx.tg.h * (fx.hash(index, 5) - 0.5) - fx.lh * 0.3
      color: "#eef3f6"; opacity: 0.32 * fx.env * fx.hlAlpha
    }
  }
}
