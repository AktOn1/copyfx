import QtQuick
import "../.."

// With a detected selection Pac-Man runs along each line of the ORIGINAL text (the letters are redrawn exactly over it) and
// eats it; without one it runs through the small maze pill below.
SourceText {
  id: fx
  fallbackPanel: false
  property real t: 0                      // line progress: whole part = line index, fraction = position along it
  readonly property int nLines: fx.rects.length
  readonly property int li: Math.min(fx.nLines - 1, Math.floor(fx.t))
  readonly property var cur: fx.rects[Math.max(0, fx.li)]
  readonly property real pacX: fx.cur.x + Math.min(1, fx.t - fx.li) * fx.cur.w
  readonly property real pacR: Math.max(6, fx.cur.h * 0.5)
  alphaFn: function(line, cx, cy) { return line < fx.li || (line === fx.li && cx < fx.pacX) ? 0 : 1 }
  readonly property real fs: fx.compact ? 10 : Math.round(fx.fontSize * 0.62)
  readonly property real maxW: Math.min(fx.width * (fx.compact ? 0.85 : 0.3), 420)
  readonly property string line: fx.text.length > 34 ? fx.text.slice(0, 33) + "…" : fx.text
  readonly property real r: fx.fs * 0.75
  property real dist: -fx.r * 2
  property real mouth: 0.7
  TextMetrics { id: tm; text: "M"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs }

  Rectangle {
    id: pill
    visible: !fx.hasSel
    width: row.width + fx.r * 5
    height: fx.r * 3.4
    x: fx.boxX(width); y: fx.boxY(height)
    radius: height / 2
    color: "#000"
    border.color: "#2121de"
    border.width: 2
    Row {
      id: row
      x: fx.r * 2.5
      anchors.verticalCenter: parent.verticalCenter
      Repeater {
        model: Array.from(fx.line)
        delegate: Text { textFormat: Text.PlainText;
          required property string modelData
          text: modelData
          color: "#ffe9f7"
          font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs
          opacity: fx.dist > x + width / 2 ? 0 : 1        // eaten once Pac-Man has passed
        }
      }
    }
    Canvas {
      width: fx.r * 2; height: fx.r * 2
      x: row.x + fx.dist - fx.r; y: (pill.height - height) / 2
      property real m: fx.mouth
      onMChanged: requestPaint()
      onPaint: { var c = getContext("2d"); c.clearRect(0, 0, width, height); c.fillStyle = "#ffe600"; c.beginPath(); c.moveTo(width / 2, height / 2); c.arc(width / 2, height / 2, width / 2 - 1, m, Math.PI * 2 - m); c.closePath(); c.fill() }
    }
    Rectangle {           // a frightened ghost a few cells ahead
      width: fx.r * 1.7; height: width * 1.05
      radius: width / 2
      x: row.x + fx.dist + fx.r * 3; y: (pill.height - height) / 2
      color: "#2121de"
      visible: fx.dist + fx.r * 3 < row.width
    }
  }
  Canvas {
    visible: fx.hasSel
    width: fx.pacR * 2; height: fx.pacR * 2
    x: fx.pacX - fx.pacR
    y: fx.cur.y + fx.cur.h / 2 - fx.pacR
    property real m: fx.mouth
    onMChanged: requestPaint()
    onPaint: { var c = getContext("2d"); c.clearRect(0, 0, width, height); c.fillStyle = "#ffe600"; c.beginPath(); c.moveTo(width / 2, height / 2); c.arc(width / 2, height / 2, width / 2 - 1, m, Math.PI * 2 - m); c.closePath(); c.fill() }
  }
  SequentialAnimation { running: true; loops: Animation.Infinite
    NumberAnimation { target: fx; property: "mouth"; to: 0.06; duration: 40 }
    NumberAnimation { target: fx; property: "mouth"; to: 0.75; duration: 40 } }
  SequentialAnimation {
    running: fx.hasSel
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.nLines; duration: fx.runMs }
    ScriptAction { script: fx.hlAlpha = 0 }
  }
  SequentialAnimation {
    running: !fx.hasSel
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "dist"; to: row.width + fx.r * 3; duration: fx.runMs }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 1 }
  }
}
