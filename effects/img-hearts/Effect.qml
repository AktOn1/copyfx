import QtQuick
import "../.."

// Little hearts float up from the real text and the letters swell gently, like a warm hug.
SpriteText {
  id: fx
  total: 1500
  readonly property real env: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  scaleFn: function(u) { return 1 + 0.14 * fx.env * (0.5 + 0.5 * Math.sin(fx.t / 110 + u.i * 0.6)) }
  tintFn: function() { return fx.env > 0.08 ? 12 : 0 }
  Repeater {
    model: 16
    delegate: Text { textFormat: Text.PlainText;
      required property int index
      readonly property real p: Math.max(0, Math.min(1, fx.t / fx.total * 1.5 - fx.hash(index, 2) * 0.5))
      text: "♥"
      color: Qt.lighter(fx.theme.magenta, 1 + 0.22 * (index % 3))
      font.pixelSize: fx.lh * (0.7 + fx.hash(index, 3) * 0.7)
      x: fx.tg.x + fx.tg.w * fx.hash(index, 1) + Math.sin(p * 7 + index) * fx.lh * 0.5 - width / 2
      y: fx.tg.y - p * fx.lh * 3.4
      opacity: p <= 0 ? 0 : (1 - p) * 0.95 * fx.hlAlpha
    }
  }
}
