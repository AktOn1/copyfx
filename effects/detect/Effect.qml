import QtQuick
import "../.."

// Debug view of find-selection: what was searched, what was found, or why not.
//   yellow  = search area (screenshot)        green  = focused window (only it is searched)
//   orange  = the flood-filled highlight block   red   = one box per detected line (what Bleed draws into)
//   cyan    = mouse, with the 44px first-pass radius
EffectBase {
  id: fx

  readonly property var d: fx.selDebug || ({})
  readonly property bool ok: !!d.found
  readonly property string title: fx.ok
    ? "FOUND  " + fx.selRects.length + " line" + (fx.selRects.length === 1 ? "" : "s") + "   lineH " + Math.round(fx.selLineH)
      + "   hl " + d.hl + "   text " + d.fg + "   pass " + d.pass + "   " + d.ms + " ms"
    : "NOT FOUND: " + (d.reason || "no debug info") + "   (" + (d.cands || 0) + " candidate colours, pass " + (d.pass || 0) + ", " + (d.ms || 0) + " ms)"

  component Box: Rectangle {
    property var b
    property color line: "yellow"
    property real fillA: 0
    visible: !!b
    x: b ? b.x : 0; y: b ? b.y : 0; width: b ? b.w : 0; height: b ? b.h : 0
    color: Qt.rgba(line.r, line.g, line.b, fillA)
    border.color: line
    border.width: 2
  }

  Box { b: fx.d.region; line: "#ffd400" }
  Box { b: fx.d.window; line: "#3ddc84" }
  Box { b: fx.d.block; line: "#ff9100" }
  Repeater {
    model: fx.selRects
    delegate: Box { required property var modelData; b: modelData; line: "#ff3b30"; fillA: 0.18 }
  }

  // Mouse: crosshair + first-pass radius.
  Item {
    visible: !!fx.d.mouse
    x: fx.d.mouse ? fx.d.mouse.x : 0
    y: fx.d.mouse ? fx.d.mouse.y : 0
    Rectangle { x: -44; y: -44; width: 88; height: 88; radius: 44; color: "transparent"; border.color: "#00e5ff"; border.width: 1 }
    Rectangle { x: -12; y: -1; width: 24; height: 2; color: "#00e5ff" }
    Rectangle { x: -1; y: -12; width: 2; height: 24; color: "#00e5ff" }
  }

  Rectangle {
    id: label
    readonly property var r: fx.d.region || { x: fx.origin.x, y: fx.origin.y, w: 400, h: 100 }
    x: Math.max(8, Math.min(r.x, fx.width - width - 8))
    y: Math.max(8, Math.min(r.y - height - 4, fx.height - height - 8))
    width: txt.width + 20
    height: txt.height + 14
    radius: 6
    color: Qt.rgba(0, 0, 0, 0.88)
    border.color: fx.ok ? "#3ddc84" : "#ff3b30"
    border.width: 2

    FxText { textFormat: Text.PlainText;
      id: txt
      anchors.centerIn: parent
      text: fx.title
      color: fx.ok ? "#b6ffd0" : "#ffb3ad"
      font.family: "monospace"
      font.pixelSize: 15
      maxWidth: fx.width * 0.8
      maxLines: 3
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    PauseAnimation { duration: 2800 }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 400 }
  }
}
