import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property var chars: Array.from(fx.text).filter(function(c) { return c !== " " })
  readonly property int n: fx.chars.length
  readonly property real cell: fx.compact ? 14 : Math.round(fx.fontSize * 1.55)
  readonly property int cols: Math.max(1, Math.min(fx.n, Math.floor(Math.min(fx.width * (fx.compact ? 0.8 : 0.5), 620) / fx.cell)))
  readonly property int rows: Math.max(1, Math.ceil(fx.n / fx.cols))
  readonly property real step: Math.max(8, Math.min(45, 1100 / Math.max(1, fx.n)))
  readonly property var palette: ["#00f0f0", "#f0f000", "#a000f0", "#00f000", "#f00000", "#0050f0", "#f0a000"]   // I O T S Z J L
  readonly property int landMs: 170
  readonly property real clearAt: fx.n * fx.step + fx.landMs + Math.max(200, fx.readMs * 0.5)

  Item {
    id: field
    width: fx.cols * fx.cell
    height: fx.rows * fx.cell
    x: fx.boxX(width)
    y: fx.boxY(height)

    Rectangle {
      anchors.fill: parent
      anchors.margins: -6
      color: "#0a0a14"
      border.color: "#6a6a9a"
      border.width: 3
      radius: 3
    }

    Repeater {
      model: fx.chars
      delegate: Rectangle {
        id: tile
        required property int index
        required property string modelData
        readonly property color base: fx.palette[(index * 3) % 7]
        readonly property real fy: Math.floor(index / fx.cols) * fx.cell
        readonly property int row: Math.floor(index / fx.cols)
        x: (index % fx.cols) * fx.cell
        y: fy
        width: fx.cell - 1
        height: fx.cell - 1
        color: base
        border.color: Qt.darker(base, 1.7)
        border.width: 1
        opacity: 0
        transformOrigin: Item.Center

        Rectangle { anchors.fill: parent; anchors.margins: fx.cell * 0.13; color: Qt.lighter(tile.base, 1.3); radius: 1 }
        Text { textFormat: Text.PlainText;
          anchors.centerIn: parent
          text: tile.modelData
          color: "#10101c"
          font.family: "monospace"
          font.bold: true
          font.pixelSize: fx.cell * 0.62
        }
        Rectangle { id: flash; anchors.fill: parent; color: "white"; opacity: 0 }

        SequentialAnimation {
          running: true
          PauseAnimation { duration: tile.index * fx.step }
          PropertyAction { target: tile; property: "opacity"; value: 1 }
          NumberAnimation { target: tile; property: "y"; from: -(field.y + fx.cell * 2); to: tile.fy; duration: fx.landMs; easing.type: Easing.InQuad }
          NumberAnimation { target: flash; property: "opacity"; from: 0.7; to: 0; duration: 130 }
        }
        SequentialAnimation {           // line clear
          running: true
          PauseAnimation { duration: fx.clearAt + tile.row * 70 }
          NumberAnimation { target: flash; property: "opacity"; to: 1; duration: 80 }
          ParallelAnimation {
            NumberAnimation { target: tile; property: "opacity"; to: 0; duration: 160 }
            NumberAnimation { target: tile; property: "scale"; to: 0.2; duration: 160 }
          }
        }
      }
    }
  }

  Timer { interval: fx.clearAt + fx.rows * 70 + 400; running: true; onTriggered: fx.finished() }
}
