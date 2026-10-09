import QtQuick
import "../.."

// A glint of light sweeps across the real text.
SpriteText {
  id: fx
  total: 1000
  readonly property real sweep: -0.3 + 1.6 * Math.min(1, fx.t / fx.total)
  Item {
    x: fx.tg.x; y: fx.tg.y; width: fx.tg.w; height: fx.tg.h; clip: true
    Rectangle {
      width: fx.tg.h * 0.9; height: fx.tg.h * 2.4; y: -fx.tg.h * 0.7
      x: fx.sweep * (fx.tg.w + width) - width * 0.5
      rotation: 20; opacity: 0.55
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#00ffffff" }
        GradientStop { position: 0.5; color: "#ffffffff" }
        GradientStop { position: 1; color: "#00ffffff" }
      }
    }
  }
}
