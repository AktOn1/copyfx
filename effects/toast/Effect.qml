import QtQuick
import "../.."

// A plain notification card: level colour bar, icon, optional title, text. Slides in from the nearest screen edge.
EffectBase {
  id: fx

  readonly property real fs: fx.compact ? 10 : Math.round(fx.fontSize * 0.62)
  readonly property real maxW: Math.min(fx.width * (fx.compact ? 0.8 : 0.28), 420)
  readonly property color lc: fx.level === "success" ? "#5af78e" : fx.level === "warn" ? "#ffcc4d" : fx.level === "error" ? "#ff5c57" : "#5aa9ff"
  readonly property string glyph: fx.icon !== "" ? fx.icon : (fx.level === "success" ? "✓" : fx.level === "warn" ? "⚠" : fx.level === "error" ? "✖" : "●")
  property real slide: 1        // 1 = off to the side, 0 = in place
  readonly property real dir: fx.posName.indexOf("left") >= 0 ? -1 : 1

  Rectangle {
    id: card
    width: content.width + fx.fs * 3.2
    height: content.height + fx.fs * 1.6
    x: fx.boxX(width) + fx.slide * fx.dir * fx.fs * 3
    y: fx.boxY(height)
    opacity: 1 - fx.slide
    radius: fx.fs * 0.7
    color: Qt.rgba(fx.bg.r, fx.bg.g, fx.bg.b, 0.96)
    border.color: Qt.rgba(fx.lc.r, fx.lc.g, fx.lc.b, 0.55)
    border.width: 1

    Rectangle { x: 0; y: fx.fs * 0.5; width: fx.fs * 0.28; height: parent.height - fx.fs; radius: width / 2; color: fx.lc }
    Row {
      id: content
      x: fx.fs * 1.1
      y: fx.fs * 0.8
      spacing: fx.fs * 0.8
      Text { textFormat: Text.PlainText; text: fx.glyph; color: fx.lc; font.pixelSize: fx.fs * 1.5; font.family: fx.fontFamily; anchors.verticalCenter: parent.verticalCenter }
      Column {
        spacing: fx.fs * 0.15
        FxText { textFormat: Text.PlainText; visible: fx.title !== ""; text: fx.title; color: fx.fg; font.family: fx.fontFamily; font.bold: true; font.pixelSize: fx.fs * 1.05; maxWidth: fx.maxW; maxLines: 2 }
        FxText { textFormat: Text.PlainText; text: fx.text; color: Qt.rgba(fx.fg.r, fx.fg.g, fx.fg.b, fx.title !== "" ? 0.82 : 1); font.family: fx.fontFamily; font.pixelSize: fx.fs; maxWidth: fx.maxW; maxLines: 6 }
      }
    }
  }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "slide"; from: 1; to: 0; duration: 180; easing.type: Easing.OutCubic }
    PauseAnimation { duration: fx.durationMs > 0 ? fx.durationMs : fx.holdMs }
    NumberAnimation { target: fx; property: "slide"; to: 1; duration: 200; easing.type: Easing.InCubic }
  }
}
