import QtQuick
import "../.."

// The original letters scramble into katakana and decode back, first to last.
SourceText {
  id: fx

  property real t: 0                                                 // ms
  readonly property int n: fx.chars.length
  readonly property real step: Math.max(6, Math.min(50, 600 / Math.max(1, fx.n)))
  readonly property var tg: fx.target
  readonly property real lh: fx.hasSel ? fx.lineH : fx.fbSize * 1.3
  function hash(a, b) { var x = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453; return x - Math.floor(x) }
  readonly property real total: fx.n * fx.step + 900
  readonly property string glyphs: "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789"
  function done(i) { return fx.t > 250 + i * fx.step }
  hlColor: "#000a03"
  textFn: function(i, c) { return c === " " || fx.done(i) ? c : fx.glyphs.charAt(Math.floor(fx.hash(i, Math.floor(fx.t / 60)) * fx.glyphs.length)) }
  colorFn: function(i) { return fx.done(i) ? (fx.t < 250 + i * fx.step + 200 ? "#eafff0" : "#00ff41") : "#008f22" }

  SequentialAnimation {
    running: true
    onFinished: fx.finished()
    NumberAnimation { target: fx; property: "t"; from: 0; to: fx.total; duration: fx.runMs }
    NumberAnimation { target: fx; property: "hlAlpha"; to: 0; duration: 1 }
  }
}
