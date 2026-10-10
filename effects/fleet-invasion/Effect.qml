import QtQuick
import "../.."

EffectBase {
  id: fx

  readonly property var chars: Array.from(fx.text)
  readonly property real fpx: fx.compact ? 11 : Math.round(fx.fontSize * 1.05)
  readonly property real maxW: Math.min(fx.width * (fx.compact ? 0.7 : 0.5), 640)
  readonly property real shotMs: Math.max(30, Math.min(120, 1800 / Math.max(1, chars.length)))
  property var glyphs: []
  property var alive: []
  property bool marching: true
  property int steps: 0

  TextMetrics { id: tm; text: "M"; font.family: "monospace"; font.bold: true; font.pixelSize: fx.fpx }

  function register(it) { fx.glyphs.push(it); if (it.text !== " ") fx.alive.push(it) }

  function shoot() {
    if (fx.alive.length === 0) { shooter.stop(); endTimer.start(); return }
    var i = Math.floor(Math.random() * fx.alive.length), g = fx.alive[i]
    var p = g.mapToItem(fx, g.width / 2, g.height / 2)
    cannon.x = p.x - cannon.width / 2
    bullet.x = p.x - bullet.width / 2
    bullet.y = cannon.y
    bullet.visible = true
    bulletAnim.stop()
    bulletAnim.from = cannon.y
    bulletAnim.to = p.y
    bulletAnim.victim = g
    bulletAnim.start()
    fx.alive.splice(i, 1)
  }

  Item {
    id: fleet
    property real baseX: fx.boxX(width)
    property real baseY: fx.boxY(height + 70 * fx.u)
    property real offX: 0
    property real offY: 0
    x: baseX + offX
    y: baseY + offY
    width: flow.width
    height: flow.height

    Flow {
      id: flow
      width: Math.max(tm.advanceWidth, Math.min(fx.chars.length * tm.advanceWidth, Math.floor(fx.maxW / tm.advanceWidth) * tm.advanceWidth))
      Repeater {
        model: fx.chars
        delegate: Text { textFormat: Text.PlainText;
          id: g
          required property string modelData
          required property int index
          property bool dead: false
          text: modelData
          color: index % 2 ? "#7CFC00" : "#b6ff5c"
          font.family: "monospace"
          font.bold: true
          font.pixelSize: fx.fpx
          opacity: dead ? 0 : 1
          Component.onCompleted: fx.register(this)

          Item {           // little explosion: 8 sparks flying outwards
            id: boom
            property real t: 0
            visible: g.dead
            x: g.width / 2
            y: g.height / 2
            NumberAnimation on t { id: tAnim; running: false; from: 0; to: 1; duration: 300 }
            Repeater {
              model: 8
              delegate: Rectangle {
                required property int index
                width: 3 * fx.u + 1; height: width
                color: index % 2 ? "#ffeb3b" : "#ff7043"
                x: Math.cos(index * Math.PI / 4) * fx.fpx * 1.4 * boom.t
                y: Math.sin(index * Math.PI / 4) * fx.fpx * 1.4 * boom.t
                opacity: 1 - boom.t
              }
            }
          }
          onDeadChanged: if (dead) tAnim.start()
        }
      }
    }

    // The fleet sways side to side and steps down at each end.
    SequentialAnimation {
      running: fx.marching
      loops: Animation.Infinite
      NumberAnimation { target: fleet; property: "offX"; to: 26 * fx.u; duration: 800 }
      ScriptAction { script: fleet.offY += 7 * fx.u }
      NumberAnimation { target: fleet; property: "offX"; to: -26 * fx.u; duration: 1600 }
      ScriptAction { script: fleet.offY += 7 * fx.u }
      NumberAnimation { target: fleet; property: "offX"; to: 0; duration: 800 }
    }
  }

  Item {                 // laser cannon, pixel-art style
    id: cannon
    width: 30 * fx.u + 6
    height: 12 * fx.u + 4
    y: fleet.baseY + fleet.height + 64 * fx.u
    x: fleet.baseX + fleet.width / 2
    z: 3
    Behavior on x { NumberAnimation { duration: 60 } }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.height * 0.55; color: "#00e5ff" }
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 0; width: parent.width * 0.2; height: parent.height * 0.55; color: "#00e5ff" }
  }

  Rectangle {
    id: bullet
    visible: false
    width: 2 * fx.u + 1
    height: 10 * fx.u + 3
    color: "#ffffff"
    z: 4
  }
  NumberAnimation {
    id: bulletAnim
    property var victim: null
    target: bullet
    property: "y"
    duration: 70
    onFinished: { bullet.visible = false; if (victim) victim.dead = true }
  }

  Timer { id: startTimer; interval: 350; running: true; onTriggered: shooter.start() }
  Timer { id: shooter; interval: fx.shotMs; repeat: true; onTriggered: fx.shoot() }
  Timer { id: endTimer; interval: 400; onTriggered: { fx.marching = false; fx.finished() } }
}
