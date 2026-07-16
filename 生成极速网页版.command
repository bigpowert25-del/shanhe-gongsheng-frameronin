#!/bin/zsh
set -e
HERE="${0:A:h}"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
cd "$HERE"

if [[ ! -x "$GODOT" ]]; then
  echo "没有找到 Godot.app，请先安装 Godot 4.7。"
  exit 1
fi

"$GODOT" --headless --path . --script res://tools/export_web_lite_content.gd
python3 tools/build_web_lite_assets.py
node --check web_lite/game.js
node --check web_lite/service-worker.js
node --check web_lite/index.service.worker.js
python3 -m json.tool web_lite/content.json >/dev/null

echo
echo "极速网页版已生成：web_lite/index.html"
echo "首次打开约 140 KB，章节资源会在进入该卷时加载。"
echo "请通过本地网页服务器或静态网站访问。"
read -k 1 "?按任意键关闭…"
