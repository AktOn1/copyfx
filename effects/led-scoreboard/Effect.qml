import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real cell: fx.compact ? 5 : 9
  readonly property int nrows: 11
  readonly property int limitCols: Math.max(12, Math.floor(Math.min(fx.width * (fx.compact ? 0.86 : 0.6), 760) / fx.cell))
  property var colBits: []            // per source column: bitmask of the lit rows
  property real shift: 0          // columns scrolled so far
  property bool sampled: false
  readonly property int ncols: Math.min(Math.max(1, colBits.length + 2), fx.limitCols)
  readonly property real maxShift: Math.max(0, colBits.length + 2 - ncols)

  TextMetrics { id: tm; text: fx.text; font.family: "monospace"; font.bold: true; font.pixelSize: 9 }

  // The text is rendered once at 9px into an invisible canvas and read back pixel by pixel: those pixels become the LEDs.
  Canvas {
    id: src
    x: 0; y: 0; z: -1
    opacity: 0.01
    property bool reading: false
    readonly property int needW: Math.ceil(tm.advanceWidth) + 4
    width: needW
    height: 12
    renderTarget: Canvas.Image
    onWidthChanged: if (width > 8) requestPaint()
    onPaint: {
      var c = getContext("2d")
      c.clearRect(0, 0, width, height)
      c.fillStyle = "#ffffff"
      c.font = "bold 9px monospace"
      c.fillText(fx.text, 1, 9)
    }
    onPainted: {
      // getImageData() repaints synchronously and would re-enter this handler forever: guard it.
      if (fx.sampled || reading || width !== needW || width <= 8) return
      reading = true
      var c = getContext("2d"), img = c.getImageData(0, 0, width, height), out = []
      for (var x = 0; x < width; x++) {
        var m = 0
        for (var y = 0; y < fx.nrows; y++) if (img.data[(y * width + x) * 4 + 3] > 110) m |= (1 << y)
        out.push(m)
      }
      fx.colBits = out
      fx.sampled = true
      reading = false
      seq.start()
    }
  }

  Rectangle {
    id: panel
    width: fx.ncols * fx.cell + fx.cell * 1.6
    height: fx.nrows * fx.cell + fx.cell * 1.6
    x: fx.boxX(width)
    y: fx.boxY(height)
    color: "#050300"
    border.color: "#3a3a3a"
    border.width: 3
    radius: 6

    Canvas {
      id: dots
      x: fx.cell * 0.8; y: fx.cell * 0.8
      width: fx.ncols * fx.cell
      height: fx.nrows * fx.cell
      renderTarget: Canvas.Image
      property real sc: Math.floor(fx.shift)
      onScChanged: requestPaint()
      Connections { target: fx; function onSampledChanged() { dots.requestPaint() } function onColBitsChanged() { dots.requestPaint() } }
      onPaint: {
        var c = getContext("2d"), cs = fx.cell
        c.clearRect(0, 0, width, height)
        var lead = fx.colBits.length + 2 <= fx.ncols ? 1 : 0        // short text sits one column in from the edge
        for (var col = 0; col < fx.ncols; col++) {
          var s = col + sc - lead, m = (fx.sampled && s >= 0 && s < fx.colBits.length) ? fx.colBits[s] : 0
          for (var row = 0; row < fx.nrows; row++) {
            var lit = (m >> row) & 1
            c.beginPath()
            c.arc(col * cs + cs / 2, row * cs + cs / 2, cs * (lit ? 0.38 : 0.28), 0, Math.PI * 2)
            if (lit) { c.shadowColor = "#ffb000"; c.shadowBlur = cs * 0.9; c.fillStyle = "#ffc733" }
            else { c.shadowBlur = 0; c.fillStyle = "#2a1a00" }
            c.fill()
          }
        }
        c.shadowBlur = 0
      }
    }
  }

  SequentialAnimation {
    id: seq
    running: false
    onFinished: fx.finished()
    PauseAnimation { duration: 250 }
    NumberAnimation { target: fx; property: "shift"; from: 0; to: fx.maxShift; duration: Math.max(1, Math.min(3800, fx.maxShift * 55)) }
    PauseAnimation { duration: Math.max(300, fx.readMs * 0.5) }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 300 }
  }
}
