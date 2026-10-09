import QtQuick
import "../.."

// The real letters jump to lightspeed: stars streak out from the middle and the text stretches apart and snaps back.
SpriteText {
  id: fx
  total: 1200
  readonly property real ph: Math.sin(Math.PI * Math.min(1, fx.t / fx.total))
  readonly property real cx: fx.tg.x + fx.tg.w / 2
  readonly property real cy: fx.tg.y + fx.tg.h / 2
  hlColor: "#03040f"
  dxFn: function(u) { return (u.cx - fx.cx) * 0.22 * fx.ph }
  scaleFn: function() { return 1 + 0.25 * fx.ph }
  tintFn: function() { return fx.ph > 0.1 ? 14 : 0 }
  Repeater {
    model: 46
    delegate: Rectangle {
      required property int index
      readonly property real ang: fx.hash(index, 1) * Math.PI * 2
      readonly property real r0: fx.lh * (0.6 + fx.hash(index, 2) * 1.5)
      readonly property real len: fx.lh * (0.5 + 5 * fx.ph * (0.4 + fx.hash(index, 3)))
      readonly property real dist: r0 + fx.ph * fx.lh * (3 + fx.hash(index, 4) * 6)
      width: len; height: Math.max(1.5, fx.lh * 0.07)
      x: fx.cx + Math.cos(ang) * dist - width / 2; y: fx.cy + Math.sin(ang) * dist * 0.7 - height / 2
      rotation: ang * 180 / Math.PI
      color: index % 3 === 0 ? fx.theme.cyan : "#ffffff"; opacity: 0.9 * fx.ph * fx.hlAlpha
    }
  }
}
