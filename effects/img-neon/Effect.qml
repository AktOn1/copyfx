import QtQuick
import "../.."

// The real text flickers on as a neon sign and settles into a pink glow.
SpriteText {
  id: fx
  total: 1500
  readonly property var fl: [1, 0.15, 1, 0.3, 0.3, 1, 0.6, 1, 1]
  readonly property real a: fx.t < 630 ? fx.fl[Math.floor(fx.t / 70)] : 1
  hlColor: "#0b0714"
  tintFn: function() { return 20 }
  alphaFn: function() { return fx.a }
  Rectangle { x: fx.tg.x - 6; y: fx.tg.y - 5; width: fx.tg.w + 12; height: fx.tg.h + 10; radius: 8; color: "transparent"; border.color: fx.theme.magenta; border.width: 2; opacity: fx.a * fx.hlAlpha }
  Rectangle { x: fx.tg.x - 11; y: fx.tg.y - 10; width: fx.tg.w + 22; height: fx.tg.h + 20; radius: 12; color: "transparent"; border.color: fx.theme.magenta; border.width: 2; opacity: 0.25 * fx.a * fx.hlAlpha }
}
