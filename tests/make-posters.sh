#!/bin/bash
# Renders a frozen mid-animation frame of every effect into posters/<id>.png (shown on the gallery cards).
# Uses the offscreen harness at the gallery preview size (264x130). Per-effect frame time: "posterMs" in effect.json (default 600).
#   tests/make-posters.sh            all effects
#   tests/make-posters.sh c64 tetris only those
dir=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$dir/posters"
ids=("$@"); [ ${#ids[@]} -eq 0 ] && ids=($(ls "$dir/effects"))
for id in "${ids[@]}"; do
  [ -f "$dir/effects/$id/Effect.qml" ] || continue     # meta effects (img-weather) have no QML of their own
  ms=$(jq -r '.posterMs // 600' "$dir/effects/$id/effect.json" 2>/dev/null || echo 600)
  txt="Copied!"; rects=""; srcmono=false
  if [ "$(jq -r '.size' "$dir/effects/$id/effect.json")" = "M" ]; then   # "on text" effects play on a fake selection
    txt="Copied to clipboard"; rects='[{x:32,y:56,w:200,h:18,il:2,ir:2,it:3,ib:3,gaps:[]}]'; srcmono=true
  fi
  sprite=null
  if [ "$(jq -r '.size' "$dir/effects/$id/effect.json")" = "IMG" ]; then   # "by image" effects play on the sample sprite
    [ -f "$dir/posters/sample-sprite.json" ] || python3 "$dir/tests/make-sample-sprite.py" >/dev/null
    txt="Copied to clipboard"; rects=$(jq -c .rects "$dir/posters/sample-sprite.json"); sprite=$(jq -c .sprite "$dir/posters/sample-sprite.json")
  fi
  out=$(SPRITE="$sprite" RECTS="$rects" SRCMONO=$srcmono LINES_MAX=3 "$dir/tests/run-effect.sh" "$id" "$txt" "$ms" "$dir/posters/$id.png" true 264 130 79 45 2>&1 | grep -v "saved true\|finished")
  [ -n "$out" ] && echo "[$id] $out"
done
echo "posters: $(ls "$dir/posters" | wc -l)"
