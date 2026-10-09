import QtQuick

// CRT scanlines: thin dark lines over whatever is below. Fill the item you want striped.
Canvas {
  id: c
  property real gap: 3
  property real strength: 0.18
  renderTarget: Canvas.Image
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onStrengthChanged: requestPaint()
  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    ctx.fillStyle = "rgba(0,0,0," + c.strength + ")"
    for (var y = 0; y < height; y += c.gap) ctx.fillRect(0, y, width, 1)
  }
}
