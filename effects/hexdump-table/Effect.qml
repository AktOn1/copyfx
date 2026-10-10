import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 8 : Math.round(fx.fontSize * 0.7)
  readonly property string raw: unescape(encodeURIComponent(fx.text))    // the UTF-8 bytes, one per character
  readonly property int n: fx.raw.length
  readonly property int rows: Math.max(1, Math.ceil(fx.n / 16))
  property real hi: 0

  readonly property var dump: {
    var off = [], hx = [], asc = []
    for (var r = 0; r < fx.rows; r++) {
      var o = ("00000000" + (r * 16).toString(16)).slice(-8) + ":", h = "", a = ""
      for (var c = 0; c < 16; c++) {
        var i = r * 16 + c
        if (i < fx.n) {
          var b = fx.raw.charCodeAt(i)
          h += ("0" + b.toString(16)).slice(-2)
          a += (b >= 32 && b < 127) ? fx.raw.charAt(i) : "."
        } else { h += "  "; a += " " }
        if (c % 2 === 1 && c < 15) h += " "
      }
      off.push(o); hx.push(h); asc.push(a)
    }
    return { off: off, hx: hx, asc: asc }
  }

  TextMetrics { id: tm; text: "0"; font.family: "monospace"; font.pixelSize: fx.fs }
  readonly property real cw: tm.advanceWidth

  Rectangle {
    id: win
    width: body.width + fx.fs * 3
    height: body.height + fx.fs * 5.2
    x: fx.boxX(width)
    y: fx.boxY(height)
    color: "#0d1117"
    border.color: "#30363d"
    border.width: 1
    radius: 6

    Text { textFormat: Text.PlainText; x: fx.fs * 1.2; y: fx.fs * 0.8; text: "$ xxd -g2 clipboard"; color: "#7ee787"; font.family: "monospace"; font.pixelSize: fx.fs }

    Item {
      id: body
      x: fx.fs * 1.2
      y: fx.fs * 2.6
      width: fx.cw * (9 + 2 + 39 + 2 + 16)
      height: offT.contentHeight

      Rectangle {       // the highlight follows the current byte in both columns
        readonly property int idx: Math.min(fx.n - 1, Math.floor(fx.hi))
        readonly property int row: Math.floor(idx / 16)
        readonly property int col: idx % 16
        visible: fx.n > 0
        x: hexT.x + (col * 2 + Math.floor(col / 2)) * fx.cw
        y: row * (offT.contentHeight / fx.rows)
        width: fx.cw * 2
        height: offT.contentHeight / fx.rows
        color: "#f2cc60"
        opacity: 0.35
      }
      Rectangle {
        readonly property int idx: Math.min(fx.n - 1, Math.floor(fx.hi))
        visible: fx.n > 0
        x: ascT.x + (idx % 16) * fx.cw
        y: Math.floor(idx / 16) * (offT.contentHeight / fx.rows)
        width: fx.cw
        height: offT.contentHeight / fx.rows
        color: "#f2cc60"
        opacity: 0.35
      }

      Text { textFormat: Text.PlainText; id: offT; text: fx.dump.off.join("\n"); color: "#6e7681"; font.family: "monospace"; font.pixelSize: fx.fs }
      Text { textFormat: Text.PlainText; id: hexT; x: fx.cw * 11; text: fx.dump.hx.join("\n"); color: "#79c0ff"; font.family: "monospace"; font.pixelSize: fx.fs }
      Text { textFormat: Text.PlainText; id: ascT; x: fx.cw * 52; text: fx.dump.asc.join("\n"); color: "#ffa657"; font.family: "monospace"; font.pixelSize: fx.fs }
    }

    Text { textFormat: Text.PlainText; x: fx.fs * 1.2; y: parent.height - fx.fs * 1.9; text: fx.n + " bytes"; color: "#8b949e"; font.family: "monospace"; font.pixelSize: fx.fs * 0.9 }
    Scanlines { anchors.fill: parent; z: 5; strength: 0.08 }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "hi"; from: 0; to: Math.max(1, fx.n); duration: Math.max(200, Math.min(1400, fx.n * 18)) }
    PauseAnimation { duration: Math.max(300, fx.readMs * 0.7) }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 350 }
  }
}
