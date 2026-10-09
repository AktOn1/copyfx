import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 9 : Math.round(fx.fontSize * 0.72)
  readonly property color green: "#5af78e"
  readonly property color cyan: "#8be9fd"
  property int pct: 0
  property bool cur: true

  // A stable 256-bit-looking digest of the text (8 rounds of FNV-1a with different seeds).
  function digest(s) {
    var out = ""
    for (var k = 0; k < 8; k++) {
      var h = (0x811c9dc5 ^ Math.imul(k + 1, 0x9e3779b1)) >>> 0
      for (var i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 }
      out += ("00000000" + h.toString(16)).slice(-8)
    }
    return out
  }
  function bar(n) {
    var a = "", b = "", i
    for (i = 0; i < n; i++) a += "█"
    for (i = n; i < 24; i++) b += "░"
    return a + b
  }
  readonly property int bytes: unescape(encodeURIComponent(fx.text)).length
  readonly property int words: fx.text.trim().length ? fx.text.trim().split(/\s+/).length : 0

  Rectangle {
    id: win
    width: Math.min(fx.width * (fx.compact ? 0.95 : 0.55), 760)
    height: bar.height + col.height + fx.fs * 1.8
    x: fx.boxX(width)
    y: fx.boxY(height)
    radius: 8
    color: "#0c0f0c"
    border.color: fx.green
    border.width: 1
    clip: true

    Rectangle {
      id: bar
      width: parent.width
      height: fx.fs * 2.1
      color: "#1c1f24"
      Row {
        spacing: fx.fs * 0.5
        x: fx.fs * 0.8
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
          model: ["#ff5f56", "#ffbd2e", "#27c93f"]
          delegate: Rectangle { required property string modelData; width: fx.fs * 0.85; height: width; radius: width / 2; color: modelData }
        }
      }
      Text { textFormat: Text.PlainText;
        anchors.centerIn: parent
        text: "copy — zsh"
        color: "#8b949e"
        font.family: "monospace"
        font.pixelSize: fx.fs * 0.9
      }
    }

    Column {
      id: col
      x: fx.fs * 0.9
      y: bar.height + fx.fs * 0.7
      width: parent.width - fx.fs * 1.8
      spacing: fx.fs * 0.15

      FxText { textFormat: Text.PlainText; text: "$ echo \"" + fx.text + "\" | wl-copy"; color: "#f8f8f2"; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: col.width; maxLines: 8 }
      FxText { textFormat: Text.PlainText; text: "[ OK ] " + fx.bytes + " bytes → clipboard"; color: fx.green; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: col.width }
      FxText { textFormat: Text.PlainText; text: "[" + fx.bar(Math.round(fx.pct / 100 * 24)) + "] " + fx.pct + "%"; color: fx.green; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: col.width }
      FxText { textFormat: Text.PlainText; text: "sha256  " + fx.digest(fx.text).slice(0, fx.compact ? 20 : 40) + "…"; color: fx.cyan; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: col.width }
      FxText { textFormat: Text.PlainText; text: "words " + fx.words + "  chars " + fx.text.length + "  bytes " + fx.bytes; color: "#6272a4"; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: col.width }
      FxText { textFormat: Text.PlainText; text: "$ " + (fx.cur ? "█" : " "); color: "#f8f8f2"; font.family: "monospace"; font.pixelSize: fx.fs; maxWidth: col.width }
    }
    Scanlines { anchors.fill: parent; z: 5; strength: 0.1 }
  }

  Timer { interval: 400; repeat: true; running: true; onTriggered: fx.cur = !fx.cur }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "pct"; to: 100; duration: 380; easing.type: Easing.OutCubic }
    PauseAnimation { duration: fx.readMs }
    NumberAnimation { target: fx; property: "opacity"; to: 0; duration: 350 }
  }
}
