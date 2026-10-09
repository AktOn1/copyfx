import QtQuick
import "../.."

// The real letters, cut from the screen, hop one after another.
SpriteText {
  id: fx
  total: fx.n * fx.step + 700
  dyFn: function(u) { var a = fx.t - u.i * fx.step; return a < 0 || a > 520 ? 0 : -Math.sin(a / 520 * Math.PI) * fx.lh * 0.8 }
  tintFn: function(u) { var a = fx.t - u.i * fx.step; return a >= 0 && a < 520 ? 13 : 0 }

}
