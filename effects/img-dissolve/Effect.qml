import QtQuick
import "../.."

// The real letters break up into nothing at random and pull back together.
SpriteText {
  id: fx
  total: 1100
  function q(i) { var s = fx.hash(i, 1) * 350; return Math.max(0, Math.min(1, (fx.t - s) / 500)) }
  alphaFn: function(u) { return 1 - Math.sin(Math.PI * fx.q(u.i)) }
  dyFn: function(u) { return -fx.lh * 0.5 * Math.sin(Math.PI * fx.q(u.i)) }
  dxFn: function(u) { return (fx.hash(u.i, 2) - 0.5) * fx.lh * Math.sin(Math.PI * fx.q(u.i)) }
  tintFn: function(u) { var k = fx.q(u.i); return k > 0 && k < 1 ? 14 : 0 }

}
