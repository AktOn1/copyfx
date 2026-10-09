import QtQuick
import QtQuick.Shapes

// The CopyFX mark: a copy symbol (two sheets) with a sparkle. Drawn, so it follows the bar colour at any size.
Item {
  id: icon
  property real iconSize: 16
  property color color: "white"
  implicitWidth: iconSize
  implicitHeight: iconSize
  width: iconSize
  height: iconSize

  Item {
    width: 24
    height: 24
    scale: icon.iconSize / 24
    transformOrigin: Item.TopLeft

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: icon.color
        strokeWidth: 1.9
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: "M4.5 14.5 V6.5 A2 2 0 0 1 6.5 4.5 H11.5" }
      }
      ShapePath {
        strokeColor: icon.color
        strokeWidth: 1.9
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: "M11.5 9.5 H18.5 A2 2 0 0 1 20.5 11.5 V18.5 A2 2 0 0 1 18.5 20.5 H11.5 A2 2 0 0 1 9.5 18.5 V11.5 A2 2 0 0 1 11.5 9.5 Z" }
      }
      ShapePath {
        strokeColor: "transparent"
        strokeWidth: 0
        fillColor: icon.color
        PathSvg { path: "M18.5 0.8 L19.6 3.7 L22.5 4.8 L19.6 5.9 L18.5 8.8 L17.4 5.9 L14.5 4.8 L17.4 3.7 Z" }
      }
    }
  }
}
