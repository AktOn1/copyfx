import QtQuick

// The rounded text panel most small effects share. It is placed by the effect base (fx.boxX / fx.boxY = where the
// copied text was), sized from the full text, and can show only part of it (`shown`, for typing effects).
Rectangle {
  id: p
  property var fx
  property string shown: fx.text
  property color textColor: fx.fg
  property color fill: Qt.rgba(fx.bg.r, fx.bg.g, fx.bg.b, 0.92)
  property color stroke: fx.accent
  property real fsize: fx.fontSize
  property string family: fx.fontFamily
  property bool bold: false
  property real padX: fsize * 0.9
  property real padY: fsize * 0.5
  property real maxW: fx.width * 0.6
  property int lines: fx.compact ? 2 : 8
  readonly property alias label: lbl

  x: fx.boxX(width)
  y: fx.boxY(height)
  width: sizer.width + padX * 2
  height: sizer.height + padY * 2
  radius: Math.min(12, height / 2)
  color: fill
  border.color: stroke
  border.width: 2

  FxText { textFormat: Text.PlainText;
    id: sizer
    visible: false
    text: fx.text
    font.family: p.family
    font.pixelSize: p.fsize
    font.bold: p.bold
    maxWidth: p.maxW
    maxLines: p.lines
  }
  FxText { textFormat: Text.PlainText;
    id: lbl
    x: p.padX
    y: p.padY
    text: p.shown
    color: p.textColor
    font.family: p.family
    font.pixelSize: p.fsize
    font.bold: p.bold
    width: sizer.width
    maxWidth: p.maxW
    maxLines: p.lines
  }
}
