import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 14 : Math.round(fx.fontSize * 1.25)
  property real flick: 1
  property real jit: 0
  property real sweep: 0

  Item {
    id: holo
    width: label.width
    height: label.height
    x: fx.boxX(width) + fx.jit
    y: fx.boxY(height + 46 * fx.u)

    Canvas {            // projector cone: from the ring up to the text
      x: -width * 0.15 + label.width * 0.07
      y: label.height
      width: label.width * 1.3
      height: 46 * fx.u
      renderTarget: Canvas.Image
      opacity: fx.flick
      onWidthChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.clearRect(0, 0, width, height)
        var g = c.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, "rgba(0,229,255,0.02)"); g.addColorStop(1, "rgba(0,229,255,0.3)")
        c.fillStyle = g
        c.beginPath()
        c.moveTo(width * 0.12, 0); c.lineTo(width * 0.88, 0); c.lineTo(width * 0.7, height); c.lineTo(width * 0.3, height)
        c.closePath(); c.fill()
      }
    }
    Rectangle {         // the projector ring
      x: -label.width * 0.05
      y: label.height + 46 * fx.u - height / 2
      width: label.width * 1.1
      height: 12 * fx.u + 3
      radius: height / 2
      color: "transparent"
      border.color: "#00e5ff"
      border.width: 2
      opacity: fx.flick
    }

    Item {
      id: layer
      width: label.width
      height: label.height
      opacity: fx.flick
      clip: true

      FxText { textFormat: Text.PlainText; y: -2; text: fx.text; color: "#00e5ff"; opacity: 0.3; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: Math.min(fx.width * 0.6, 760); maxLines: 8 }
      FxText { textFormat: Text.PlainText; y: 2; text: fx.text; color: "#00e5ff"; opacity: 0.3; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: Math.min(fx.width * 0.6, 760); maxLines: 8 }
      FxText { textFormat: Text.PlainText; id: label; text: fx.text; color: "#a8fcff"; opacity: 0.92; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fs; maxWidth: Math.min(fx.width * 0.6, 760); maxLines: 8 }
      Scanlines { anchors.fill: parent; strength: 0.45; gap: 3 }
      Rectangle {       // a bright beam sweeping up through the text
        width: parent.width
        height: 10 * fx.u + 2
        y: (1 - fx.sweep) * (parent.height + height) - height
        color: "#00e5ff"
        opacity: 0.25
      }
    }
  }

  Timer {
    interval: 70
    repeat: true
    running: true
    onTriggered: {
      fx.flick = Math.random() < 0.07 ? 0.35 : 0.86 + Math.random() * 0.14
      fx.jit = Math.random() < 0.1 ? (Math.random() - 0.5) * 8 * fx.u : 0
    }
  }
  NumberAnimation on sweep { from: 0; to: 1; duration: 1100; loops: Animation.Infinite }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 500 + fx.readMs }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 380 }
  }
}
