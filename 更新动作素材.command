#!/bin/zsh
set -e
HERE="${0:A:h}"
cd "$HERE"
python3 tools/build_motion_sheets.py
echo
echo "动作素材已更新，可以启动游戏。"
read -k 1 "?按任意键关闭…"
