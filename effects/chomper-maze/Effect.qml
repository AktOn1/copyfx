import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property var chars: Array.from(fx.text)
  readonly property real fpx: fx.compact ? 11 : Math.round(fx.fontSize * 1.05)
  readonly property real r: fx.fpx * 0.72                 // Chomper radius
  readonly property real maxW: Math.min(fx.width * (fx.compact ? 0.8 : 0.6), 760)
  property var items: []                                    // the letter items, in reading order
  property var lines: []                                    // one entry per visual line: y, h, x0, x1, first, last, start, len
  property real dist: 0                                     // distance travelled along all lines
  property real total: 1
  property real mouth: 0.7
  property bool ready: false
  property int cursorLine: 0

  TextMetrics { id: tm; text: "M"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fpx }

  function register(it) { fx.items.push(it) }

  // Once the letters are laid out, read where every line sits and build the route.
  function layout() {
    var ls = [], cur = null
    for (var i = 0; i < fx.items.length; i++) {
      var it = fx.items[i], p = it.mapToItem(fx, 0, 0)
      it.cx = p.x + it.width / 2
      if (!cur || Math.abs(p.y - cur.y) > it.height * 0.5) {
        cur = { y: p.y, h: it.height, x0: p.x, x1: p.x + it.width, first: i, last: i }
        ls.push(cur)
      } else { cur.x1 = p.x + it.width; cur.last = i }
    }
    var tot = 0
    for (var l = 0; l < ls.length; l++) { ls[l].start = tot; ls[l].len = (ls[l].x1 - ls[l].x0) + fx.r * 4; tot += ls[l].len }
    fx.lines = ls
    fx.total = Math.max(1, tot)
    fx.ready = true
    seq.start()
  }

  function at(d) {
    var ls = fx.lines
    for (var l = 0; l < ls.length; l++) {
      if (d <= ls[l].start + ls[l].len || l === ls.length - 1) {
        return { x: ls[l].x0 - fx.r * 2 + Math.max(0, d - ls[l].start), y: ls[l].y + ls[l].h / 2, line: l }
      }
    }
    return { x: -100, y: -100, line: 0 }
  }
  readonly property var pos: fx.ready ? fx.at(fx.dist) : ({ x: -100, y: -100, line: 0 })
  readonly property var ghostPos: fx.ready ? fx.at(fx.dist + fx.r * 5) : ({ x: -100, y: -100, line: 0 })

  onDistChanged: {
    if (!fx.ready) return
    var p = fx.at(fx.dist), ln = fx.lines[p.line]
    for (var i = ln.first; i <= ln.last; i++) {
      var it = fx.items[i]
      if (!it.eaten && it.cx < p.x + fx.r * 0.3) it.eaten = true
    }
  }

  Item {
    id: block
    x: fx.boxX(width)
    y: fx.boxY(height)
    width: flow.width
    height: flow.height

    Rectangle {           // the maze wall
      anchors.fill: parent
      anchors.margins: -fx.r * 2.6
      radius: fx.r
      color: "#000000"
      border.color: "#2121de"
      border.width: 3
    }

    Flow {
      id: flow
      width: Math.max(tm.advanceWidth, Math.min(fx.chars.length * tm.advanceWidth, Math.floor(fx.maxW / tm.advanceWidth) * tm.advanceWidth))
      Repeater {
        model: fx.chars
        delegate: Text { textFormat: Text.PlainText;
          required property string modelData
          property bool eaten: false
          property real cx: 0
          text: modelData
          color: "#ffe9f7"
          font.family: "monospace"
          font.bold: true
          font.pixelSize: fx.fpx
          opacity: eaten ? 0 : 1
          Component.onCompleted: fx.register(this)
        }
      }
    }
  }

  Canvas {                  // Chomper
    id: pac
    visible: fx.ready
    width: fx.r * 2
    height: fx.r * 2
    x: fx.pos.x - fx.r
    y: fx.pos.y - fx.r
    z: 5
    property real m: fx.mouth
    onMChanged: requestPaint()
    onPaint: {
      var c = getContext("2d")
      c.clearRect(0, 0, width, height)
      c.fillStyle = "#ffe600"
      c.beginPath()
      c.moveTo(width / 2, height / 2)
      c.arc(width / 2, height / 2, width / 2 - 1, m, Math.PI * 2 - m)
      c.closePath()
      c.fill()
    }
  }

  Canvas {                  // a frightened ghost running ahead
    id: ghost
    visible: fx.ready && fx.dist + fx.r * 5 < fx.total
    width: fx.r * 2
    height: fx.r * 2
    x: fx.ghostPos.x - fx.r
    y: fx.ghostPos.y - fx.r
    z: 4
    property real wob: Math.floor(fx.dist / (fx.r * 0.6)) % 2
    onWobChanged: requestPaint()
    onPaint: {
      var c = getContext("2d"), w = width, h = height
      c.clearRect(0, 0, w, h)
      c.fillStyle = "#2121de"
      c.beginPath()
      c.arc(w / 2, h / 2, w / 2 - 1, Math.PI, 0)
      c.lineTo(w - 1, h - 1)
      for (var i = 4; i >= 0; i--) c.lineTo(1 + (w - 2) * i / 4, h - 1 - ((i + wob) % 2) * h * 0.14)
      c.closePath()
      c.fill()
      c.fillStyle = "#ffffff"
      c.fillRect(w * 0.28, h * 0.32, w * 0.12, h * 0.12)
      c.fillRect(w * 0.6, h * 0.32, w * 0.12, h * 0.12)
    }
  }

  Timer { interval: 40; running: true; onTriggered: fx.layout() }

  SequentialAnimation {
    running: true
    loops: Animation.Infinite
    NumberAnimation { target: fx; property: "mouth"; to: 0.06; duration: 110 }
    NumberAnimation { target: fx; property: "mouth"; to: 0.75; duration: 110 }
  }

  SequentialAnimation {
    id: seq
    running: false
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "dist"; from: 0; to: fx.total; duration: Math.max(700, Math.min(3000, fx.total / (fx.compact ? 0.2 : 0.5))) }
    PauseAnimation { duration: 250 }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 300 }
  }
}
