import QtQuick
import "../.."

// The real text is struck out in red as removed, then comes back green with a plus in the gutter.
SpriteText {
  id: fx
  total: 1400
  readonly property bool removed: fx.t < fx.total * 0.45
  tintFn: function() { return fx.t < fx.total * 0.12 ? 0 : (fx.removed ? 1 : 5) }
  Repeater {
    model: fx.hasSprite ? fx.rects : []
    delegate: Item {
      required property var modelData
      x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h; opacity: fx.hlAlpha
      Rectangle { anchors.fill: parent; color: fx.removed ? fx.theme.red : "#34c759"; opacity: fx.t < fx.total * 0.12 ? 0 : 0.22 }
      Rectangle { visible: fx.removed && fx.t > fx.total * 0.12; x: 0; y: parent.height / 2; width: parent.width * Math.min(1, (fx.t - fx.total * 0.12) / (fx.total * 0.2)); height: 2; color: fx.theme.red }
      Text { textFormat: Text.PlainText; x: -fx.lh * 1.1; height: parent.height; verticalAlignment: Text.AlignVCenter; text: fx.removed ? "-" : "+"; color: fx.removed ? fx.theme.red : fx.theme.green; font.family: "monospace"; font.bold: true; font.pixelSize: fx.lh * 0.95; visible: fx.t > fx.total * 0.12 }
    }
  }
}
