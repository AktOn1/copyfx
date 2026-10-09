import QtQuick
import "../.."

// Test twin of the by-image effects: the cut-out letters frozen for 8 s, to compare pixel for pixel with the original.
SpriteText {
  id: fx
  autoRun: false
  SequentialAnimation { running: true; onFinished: fx.finished(); PauseAnimation { duration: 8000 } }
}
