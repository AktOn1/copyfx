import QtQuick
import "../.."

// Follows your Omarchy theme: the real letters take the accent colour on the theme's own background inside an accent border.
SpriteText {
  id: fx
  total: 800
  hlColor: fx.bg
  readonly property real appear: Math.min(1, fx.t / 120)
  readonly property real fadeOut: fx.t > 600 ? Math.max(0, 1 - (fx.t - 600) / 200) : 1
  tintFn: function() { return 13 }
  alphaFn: function() { return 1 }
  Rectangle {
    x: fx.tg.x - 8; y: fx.tg.y - 6; width: fx.tg.w + 16; height: fx.tg.h + 12
    radius: 8; color: fx.bg; border.color: fx.accent; border.width: 2; z: -1
    opacity: fx.appear * fx.fadeOut * fx.hlAlpha
  }
  Rectangle {                                       // a thin accent underline that runs along under the text
    x: fx.tg.x; y: fx.tg.y + fx.tg.h + 4; width: fx.tg.w * Math.min(1, fx.t / 500); height: 2
    color: fx.accent; opacity: fx.fadeOut * fx.hlAlpha
  }
}
