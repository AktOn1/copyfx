import QtQuick
import "../.."

// Eight LEDs count up in binary as the real letters light up in amber, one per tick.
SpriteText {
  id: fx
  total: 1400
  readonly property int cnt: Math.min(fx.n, Math.floor(fx.t / (fx.total * 0.8) * fx.n))
  hlColor: "#120c02"
  tintFn: function(u) { return u.i < fx.cnt ? 16 : 0 }
  alphaFn: function(u) { return u.i < fx.cnt ? 1 : 0.28 }
  Row {
    x: fx.tg.x; y: fx.tg.y - fx.lh * 1.5; spacing: fx.lh * 0.35
    opacity: Math.min(1, fx.t / 100) * fx.hlAlpha
    Repeater {
      model: 8
      delegate: Rectangle {
        required property int index
        readonly property bool on: ((fx.cnt >> (7 - index)) & 1) === 1
        width: fx.lh * 0.7; height: width; radius: width / 2
        color: on ? fx.theme.red : "#3a1512"; border.color: "#5a2a26"; border.width: 1
      }
    }
    Text { textFormat: Text.PlainText; text: "0x" + ("0" + fx.cnt.toString(16)).slice(-2); color: "#ffb000"; font.family: "monospace"; font.pixelSize: fx.lh * 0.8; leftPadding: fx.lh * 0.4 }
  }
}
