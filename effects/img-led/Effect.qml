import QtQuick
import "../.."

// An amber LED display: amber letters flicker on a dark dotted block.
SpriteText {
  id: fx
  total: 1100
  hlColor: "#140a00"
  tintFn: function() { return 16 }
  alphaFn: function() { return fx.t < 500 && Math.floor(fx.t / 70) % 3 === 0 ? 0.5 : 1 }
  Scanlines { x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; gap: 3; strength: 0.45; opacity: fx.hlAlpha }
}
