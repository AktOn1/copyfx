import QtQuick
import "../.."

// The real letters spin like slot reels and stop one after another, first to last.
SpriteText {
  id: fx
  total: fx.n * fx.step * 0.6 + 700
  function stopT(i) { return 250 + i * fx.step * 0.6 }
  function off(u) { return fx.t >= fx.stopT(u.i) ? 0 : (((fx.t / 90 + fx.hash(u.i, 1) * 7) % 1) * 2 - 1) * fx.lh * 1.1 }
  dyFn: function(u) { return fx.off(u) }
  alphaFn: function(u) { return fx.t >= fx.stopT(u.i) ? 1 : Math.max(0, 1 - Math.abs(fx.off(u)) / (fx.lh * 1.2)) }
  tintFn: function(u) { return fx.t >= fx.stopT(u.i) ? (fx.t < fx.stopT(u.i) + 120 ? 3 : 0) : 7 }

}
