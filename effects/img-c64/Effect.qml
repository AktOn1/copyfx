import QtQuick
import "../.."

// A Commodore 64 screen around the real text: light-blue border, dark-blue screen, light-blue letters, blinking cursor.
SpriteText {
  id: fx
  total: 1350
  hlColor: "#40318d"
  tintFn: function() { return 17 }
  Rectangle {                                     // the light-blue border and the blue screen inside it (the C64's whole display)
    x: fx.tg.x - fx.lh * 2.4; y: fx.tg.y - fx.lh * 1.9; width: fx.tg.w + fx.lh * 4.8; height: fx.tg.h + fx.lh * 3.8
    color: "#887ecb"; radius: 4; z: -3; opacity: fx.hlAlpha
  }
  Rectangle {
    x: fx.tg.x - fx.lh * 1.0; y: fx.tg.y - fx.lh * 0.7; width: fx.tg.w + fx.lh * 2.0; height: fx.tg.h + fx.lh * 1.4
    color: "#40318d"; z: -2; opacity: fx.hlAlpha
    Scanlines { anchors.fill: parent; strength: 0.12 }
  }
  Rectangle {
    x: fx.tg.x + fx.tg.w + 2; y: fx.tg.y + fx.tg.h - fx.lh; width: fx.lh * 0.6; height: fx.lh
    color: "#887ecb"; visible: Math.floor(fx.t / 260) % 2 === 0
  }
}
