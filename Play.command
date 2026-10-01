#!/bin/zsh
set -euo pipefail
cd -- "$(dirname -- "$0")"

for godot_runtime in /Applications/Godot.app/Contents/MacOS/Godot /private/tmp/fire-emblem-godot-runtime/Godot.app/Contents/MacOS/Godot; do
  if [[ -x "$godot_runtime" ]]; then
    exec "$godot_runtime" --path "$PWD"
  fi
done

if command -v godot >/dev/null 2>&1; then
  exec godot --path "$PWD"
fi
if command -v godot4 >/dev/null 2>&1; then
  exec godot4 --path "$PWD"
fi

print 'Godot was not found. Open project.godot with Godot 4.7.2 or later.'
read '?Press Return to close.'
