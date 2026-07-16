# 构建与交付

## 开发环境

- Godot 4.7 stable（Standard，非 .NET）
- Python 3
- Pillow（用于从原始透明立绘生成开发用动作表）
- macOS 构建机可同时输出 macOS Universal、Windows x86_64 和 Web/PWA

## 一键构建

在 macOS 双击 `生成发布包.command`。脚本会：

1. 更新 11 名角色的 4×4 动作表。
2. 验证动作表尺寸、透明通道和角色清单。
3. 按需安装 macOS、Windows x64、Web no-threads 与中文 ICU 数据，不下载无关平台模板。
4. 让 Godot 完成素材导入并运行六章烟雾测试。
5. 输出三个发布成品到 `builds/`。

## 发布成品

- macOS：`builds/macos/山河共生-macOS.zip`，Universal 架构，兼容 Apple Silicon 与 Intel。
- Windows：`builds/windows/山河共生-Windows.exe`，x86_64，PCK 已嵌入单文件。
- Web/PWA：`builds/web/index.html`，适配手机横屏与桌面浏览器，可部署到 GitHub Pages 等静态网站服务。
- 手机极速版：`web_lite/index.html`，纯 HTML/CSS/Canvas，不依赖 Godot/WASM；首屏和六章资源分开加载。

只构建网页试玩版时，双击 `生成网页试玩版.command`。脚本会安装缺失模板、导入素材、运行烟雾测试，然后生成完整的离线 PWA 文件。由于浏览器安全限制，请通过本地网页服务器或静态网站访问，不要直接双击 `index.html`。

只构建手机极速版时，双击 `生成极速网页版.command`。脚本会从 `scripts/game_content.gd` 导出六章数据，并把原始场景、人物和怪物压成手机尺寸 WebP。输出目录可直接部署到任意静态网站；当前线上约定为 `/shanhe/`，完整 Godot 版保留在 `/shanhe-godot/`。

macOS 包使用开发测试用的 ad-hoc 签名，没有 Apple Developer ID 公证。自己试玩可直接解压运行；如果系统提示来自未知开发者，可在 Finder 中右键应用并选择“打开”。正式公开发布时，应改用 Developer ID 签名并完成 Apple notarization。

## 工程分层

- `scripts/game_content.gd`：六章剧情、NPC、见闻、选择与能力数据。
- `scripts/exploration.gd`：探索、战斗和动作状态切换。
- `scripts/mobile_joystick.gd`：触摸与鼠标均可测试的虚拟摇杆。
- `scripts/sprite_sheet_library.gd`：动作表运行时读取与逐帧选择。
- `art_pipeline/manifest.json`：FrameRonin 输入输出契约。
- `tools/build_motion_sheets.py`：外部成品接入及开发兜底生成器。
- `tools/export_web_lite_content.gd`：把 Godot 六章内容导出为极速网页版数据。
- `tools/build_web_lite_assets.py`：生成逐章加载的手机尺寸 WebP 素材。
- `assets/generated/`：Godot 实际使用的标准化动作素材。
- `web_lite/`：无需 WASM 的六章探索、任务、剧情与战斗客户端。
- `tests/smoke_test.gd`：六章、战斗、选择、结局与动作表整合测试。
