#!/bin/zsh
set -e
HERE="${0:A:h}"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
cd "$HERE"

if [[ ! -x "$GODOT" ]]; then
  echo "没有找到 Godot.app，请先安装 Godot 4.7。"
  exit 1
fi

python3 tools/build_motion_sheets.py
python3 tools/test_motion_pipeline.py
python3 tools/install_export_templates.py
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/smoke_test.gd
mkdir -p builds/macos builds/windows
"$GODOT" --headless --path . --export-release "macOS" "builds/macos/山河共生-macOS.zip"
"$GODOT" --headless --path . --export-release "Windows x86_64" "builds/windows/山河共生-Windows.exe"

echo
echo "发布包已生成："
echo "  builds/macos/山河共生-macOS.zip"
echo "  builds/windows/山河共生-Windows.exe"
read -k 1 "?按任意键关闭…"
