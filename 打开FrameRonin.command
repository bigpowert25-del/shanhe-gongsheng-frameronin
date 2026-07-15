#!/bin/zsh
set -e
HERE="${0:A:h}"
URL="http://127.0.0.1:4173/"
SIBLING="$HERE/../22-frameronin/启动本地试玩.command"

if curl -fsSI --max-time 2 "$URL" >/dev/null 2>&1; then
  open "$URL"
elif [[ -f "$SIBLING" ]]; then
  open "$SIBLING"
else
  echo "没有找到本机 FrameRonin。"
  echo "请先部署到相邻目录 22-frameronin，或手动打开 $URL。"
  read -k 1 "?按任意键关闭…"
fi
