import QtQuick
import "../.."

// A rainbow wave runs over the real letters.
SpriteText {
  id: fx
  total: fx.n * fx.step + 500
  tintFn: function(u) { var q = (fx.t - u.i * fx.step) / 450; return q >= 0 && q < 1 ? 1 + Math.floor(q * 12) : 0 }

}
