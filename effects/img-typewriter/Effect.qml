import QtQuick
import "../.."

// The real letters are typed out one by one with a blinking caret.
SpriteText {
  id: fx
  readonly property real per: Math.max(6, Math.min(30, 800 / Math.max(1, fx.n)))
  readonly property int k: Math.floor(fx.t / fx.per)
  total: fx.n * fx.per + 450
  alphaFn: function(u) { return u.i < fx.k ? 1 : 0 }
  Rectangle {
    readonly property var u: fx.units[Math.min(fx.k, fx.n - 1)]
    visible: !!u && (Math.floor(fx.t / 350) % 2 === 0 || fx.k < fx.n)
    x: u ? u.x + (fx.k >= fx.n ? u.w : 0) : 0; y: u ? u.y + u.h * 0.1 : 0
    width: 2; height: u ? u.h * 0.8 : 0
    color: fx.srcFg
  }
}
