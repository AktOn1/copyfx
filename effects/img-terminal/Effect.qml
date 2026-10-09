import QtQuick
import "../.."

// The real letters are typed out in green on black with a block cursor.
SpriteText {
  id: fx
  readonly property real per: Math.max(6, Math.min(30, 800 / Math.max(1, fx.n)))
  readonly property int k: Math.floor(fx.t / fx.per)
  total: fx.n * fx.per + 650
  hlColor: "#0b120b"
  tintFn: function() { return 18 }
  alphaFn: function(u) { return u.i < fx.k ? 1 : 0 }
  Rectangle {
    readonly property var u: fx.units[Math.min(fx.k, fx.n - 1)]
    visible: !!u && (Math.floor(fx.t / 300) % 2 === 0 || fx.k < fx.n)
    x: u ? u.x + (fx.k >= fx.n ? u.w : 0) : 0; y: u ? u.y + u.h * 0.1 : 0
    width: Math.max(4, fx.lh * 0.5); height: u ? u.h * 0.8 : 0
    color: "#33ff66"
  }
}
