import QtQuick
import "../.."

// The bytes of the copied text in hex above the real text, a highlight sweeping through byte by byte and lighting the matching letter.
SpriteText {
  id: fx
  total: 1300
  readonly property real cw: fx.lh * 0.62
  readonly property int count: Math.max(1, Math.min(Math.floor((fx.tg.w - fx.lh) / (fx.cw * 3)), 48, unescape(encodeURIComponent(fx.text)).length))
  readonly property string raw: unescape(encodeURIComponent(fx.text))
  readonly property real hi: Math.min(1, fx.t / (fx.total * 0.75)) * (fx.count - 1)
  readonly property int hb: Math.floor(fx.hi + 0.5)
  readonly property string hex: { var h = []; for (var i = 0; i < fx.count; i++) h.push(("0" + fx.raw.charCodeAt(i).toString(16)).slice(-2)); return h.join(" ") }
  readonly property string asc: { var a = ""; for (var i = 0; i < fx.count; i++) { var b = fx.raw.charCodeAt(i); a += (b >= 32 && b < 127) ? fx.raw.charAt(i) : "." } return a }
  hlColor: "#0b1020"
  tintFn: function(u) { return fx.n > 0 && u.i === Math.min(fx.n - 1, Math.floor(fx.hi / Math.max(1, fx.count - 1) * (fx.n - 1) + 0.5)) ? 13 : 21 }
  Rectangle {                                       // the dump panel above the text
    id: panel
    x: fx.tg.x - fx.lh * 0.4; y: fx.tg.y - fx.lh * 2.3; width: fx.tg.w + fx.lh * 0.8; height: fx.lh * 2.1
    color: "#0d1117"; border.color: "#30363d"; border.width: 1; radius: 4
    opacity: Math.min(1, fx.t / 120) * fx.hlAlpha
    Rectangle {                                     // the sweeping highlight, in the hex column and in the ASCII column
      x: fx.lh * 0.4 + fx.hb * fx.cw * 3 - fx.cw * 0.2; y: fx.lh * 0.15; width: fx.cw * 2.4; height: fx.lh * 0.85
      color: fx.theme.yellow; opacity: 0.4
    }
    Rectangle {
      x: fx.lh * 0.4 + fx.hb * fx.cw * 3 - fx.cw * 0.2; y: fx.lh * 1.1; width: fx.cw * 2.4; height: fx.lh * 0.85
      color: fx.theme.yellow; opacity: 0.4
    }
    Text { textFormat: Text.PlainText; x: fx.lh * 0.4; y: fx.lh * 0.15; height: fx.lh * 0.85; verticalAlignment: Text.AlignVCenter; text: fx.hex; color: fx.theme.blue; font.family: "monospace"; font.pixelSize: fx.lh * 0.7 }
    Text { textFormat: Text.PlainText; x: fx.lh * 0.4; y: fx.lh * 1.1; height: fx.lh * 0.85; verticalAlignment: Text.AlignVCenter; text: fx.asc.split("").join("  ") ; color: fx.theme.orange; font.family: "monospace"; font.pixelSize: fx.lh * 0.7 }
  }
}
