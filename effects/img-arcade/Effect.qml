import QtQuick
import "../.."

// A yellow/red arcade blink on the real text and a +score pops up.
SpriteText {
  id: fx
  total: 1200
  hlColor: "#000000"
  tintFn: function() { return Math.floor(fx.t / 120) % 2 === 0 ? 3 : 1 }
  Text { textFormat: Text.PlainText;
    x: fx.tg.x + fx.tg.w / 2 - width / 2; y: fx.tg.y - fx.lh * 1.1 - Math.min(1, fx.t / 700) * fx.lh
    text: "+" + fx.text.length * 10
    color: fx.theme.orange; font.family: "monospace"; font.bold: true; font.pixelSize: Math.max(11, fx.lh * 0.9)
    opacity: fx.t < 900 ? 1 : Math.max(0, 1 - (fx.t - 900) / 300)
  }
}
