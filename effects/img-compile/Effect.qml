import QtQuick
import "../.."

// A build progress bar fills above the real text; the letters get compiled in one by one.
SpriteText {
  id: fx
  total: 1400
  readonly property real prog: Math.min(1, fx.t / (fx.total * 0.8))
  hlColor: "#0d1117"
  tintFn: function(u) { return u.i < fx.prog * fx.n ? (u.i > fx.prog * fx.n - 2 ? 5 : 0) : 0 }
  alphaFn: function(u) { return u.i < fx.prog * fx.n ? 1 : 0.2 }
  Rectangle {
    x: fx.tg.x; y: fx.tg.y - fx.lh * 1.7; width: fx.tg.w; height: fx.lh * 1.4; radius: 3; color: "#0d1117"; border.color: "#30363d"; border.width: 1; opacity: fx.hlAlpha
    Rectangle { x: 3; y: 3; width: (parent.width - 6) * fx.prog; height: fx.lh * 0.35; radius: 2; color: "#3fb950" }
    Text { textFormat: Text.PlainText; x: 6; y: fx.lh * 0.5; text: "[" + Math.round(fx.prog * 100) + "%] CC copyfx/" + fx.text.slice(0, 16).replace(/\s/g, "_") + ".o"; color: "#8b949e"; font.family: "monospace"; font.pixelSize: fx.lh * 0.6 }
  }
}
