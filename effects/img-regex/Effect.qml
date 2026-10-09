import QtQuick
import "../.."

// Every word of the real text is caught in its own coloured capture group with a $n label.
SpriteText {
  id: fx
  total: 1500
  readonly property var words: {
    var byW = {}, out = []
    fx.units.forEach(function(u) {
      var k = u.line + ":" + u.word
      if (!byW[k]) { byW[k] = { x: u.x, y: u.y, x1: u.x + u.w, h: u.h, i: out.length }; out.push(byW[k]) }
      else byW[k].x1 = u.x + u.w
    })
    return out
  }
  readonly property var cols: [fx.theme.red, fx.theme.yellow, "#48dbfb", "#1dd1a1", fx.theme.magenta, "#a29bfe"]
  function on(i) { return fx.t > 150 + i * Math.min(90, 700 / Math.max(1, fx.words.length)) }
  tintFn: function(u) { var w = fx.words.length; return 0 }
  Repeater {
    model: fx.words
    delegate: Item {
      required property var modelData
      visible: fx.on(modelData.i)
      opacity: fx.hlAlpha
      Rectangle {
        x: modelData.x - 2; y: modelData.y - 1; width: modelData.x1 - modelData.x + 4; height: modelData.h + 2; radius: 3
        color: "transparent"; border.color: fx.cols[modelData.i % 6]; border.width: 2
        Rectangle { anchors.fill: parent; color: fx.cols[modelData.i % 6]; opacity: 0.16; radius: 3 }
      }
      Text { textFormat: Text.PlainText; x: modelData.x; y: modelData.y - fx.lh * 0.75; text: "$" + (modelData.i + 1); color: fx.cols[modelData.i % 6]; font.family: "monospace"; font.bold: true; font.pixelSize: fx.lh * 0.62 }
    }
  }
}
