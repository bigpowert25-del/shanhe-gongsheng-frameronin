#!/bin/zsh
set -e
HERE="${0:A:h}"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
cd "$HERE"

if [[ ! -x "$GODOT" ]]; then
  echo "没有找到 Godot.app，请先安装 Godot 4.7。"
  exit 1
fi

python3 tools/install_export_templates.py
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/smoke_test.gd
mkdir -p builds/web
"$GODOT" --headless --path . --export-release "Web Mobile" "builds/web/index.html"

echo
echo "网页试玩版已生成：builds/web/index.html"
echo "请通过本地网页服务器或静态网站访问。"
read -k 1 "?按任意键关闭…"
