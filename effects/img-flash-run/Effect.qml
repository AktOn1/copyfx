import QtQuick
import "../.."

// The real letters flash red one after another, first to last.
SpriteText {
  id: fx
  total: fx.n * fx.step + 200
  tintFn: function(u) { var a = u.i * fx.step; return fx.t >= a && fx.t < a + 160 ? 1 : 0 }

}
