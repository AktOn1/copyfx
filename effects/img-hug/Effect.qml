import QtQuick
import "../.."

// The real letters lean in and squeeze together in a soft warm glow, then relax.
SpriteText {
  id: fx
  total: 1200
  readonly property real ph: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  dxFn: function(u) { return -(u.cx - (fx.tg.x + fx.tg.w / 2)) * 0.025 * fx.ph }
  scaleFn: function() { return 1 + 0.06 * fx.ph }
  tintFn: function() { return fx.ph > 0.05 ? 2 : 0 }
  Rectangle {                                        // the glow
    x: fx.tg.x - fx.lh; y: fx.tg.y - fx.lh * 0.6; width: fx.tg.w + fx.lh * 2; height: fx.tg.h + fx.lh * 1.2; radius: fx.lh
    color: fx.theme.orange; opacity: 0.32 * fx.ph * fx.hlAlpha; z: -1
  }
  Rectangle {
    x: fx.tg.x - fx.lh * 0.5; y: fx.tg.y - fx.lh * 0.3; width: fx.tg.w + fx.lh; height: fx.tg.h + fx.lh * 0.6; radius: fx.lh * 0.6
    color: "transparent"; border.color: "#ffd2a8"; border.width: 2; opacity: 0.7 * fx.ph * fx.hlAlpha
  }
}
