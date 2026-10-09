import QtQuick
import "../.."

// All the real letters flash red once.
SpriteText {
  id: fx
  total: 400
  tintFn: function() { return fx.t < 170 ? 1 : 0 }

}
