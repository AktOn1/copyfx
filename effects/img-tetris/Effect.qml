import QtQuick
import "../.."

// The real letters drop into place like falling blocks in tetromino colours.
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.7 + 800
  readonly property var pal: [7, 3, 10, 5, 1, 9, 2]
  function p(i) { return Math.max(0, Math.min(1, (fx.t - i * fx.step * 0.7) / 380)) }
  dyFn: function(u) { var q = fx.p(u.i); return -(1 - q) * (1 - q) * fx.lh * 4 }
  alphaFn: function(u) { return fx.p(u.i) > 0 ? 1 : 0 }
  tintFn: function(u) { return fx.p(u.i) < 1 ? fx.pal[u.i % 7] : 0 }

}
