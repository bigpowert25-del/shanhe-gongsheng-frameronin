#!/bin/zsh
set -e
HERE="${0:A:h}"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$GODOT" ]]; then
  echo "没有找到 /Applications/Godot.app，请先安装 Godot 4.7。"
  read -k 1 "?按任意键关闭……"
  exit 1
fi

exec "$GODOT" --path "$HERE"

