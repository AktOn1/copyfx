import QtQuick
import "../.."

// The real letters are pulled toward your mouse pointer and snap back.
SpriteText {
  id: fx
  total: 1000
  readonly property real ph: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  function pull(u) {
    var dx = fx.origin.x - u.cx, dy = fx.origin.y - u.cy, d = Math.max(1, Math.sqrt(dx * dx + dy * dy)), k = Math.min(1, 260 / d)
    return { x: dx * k * fx.ph * 0.9, y: dy * k * fx.ph * 0.9 }
  }
  dxFn: function(u) { return fx.pull(u).x }
  dyFn: function(u) { return fx.pull(u).y }
  scaleFn: function() { return 1 - 0.35 * fx.ph }
  tintFn: function() { return fx.ph > 0.05 ? 9 : 0 }

}
