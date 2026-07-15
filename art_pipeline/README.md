# FrameRonin 美术接口

FrameRonin 在本项目中只负责离线制作动作素材，不进入 Godot 运行包，也不复制其源码。

## 约定

- 每名角色输出一张透明 PNG Sprite Sheet。
- 固定为 4 列 × 4 行，每帧 192 × 288 像素，整图 768 × 1152 像素。
- 第 1～4 行依次为：`idle`、`walk`、`attack`、`hurt`。
- 文件名使用 `manifest.json` 中的角色 ID，例如 `you.png`、`boss_01.png`。
- 将 FrameRonin 导出的图片放入 `art_pipeline/inbox/`，再运行项目根目录的“更新动作素材”。

如果 inbox 中没有对应图片，构建工具会用原始透明立绘生成可运行的基础动作表。它是开发兜底，也让仓库在没有 FrameRonin 的电脑上仍可完整重建。只要放入同规格的 FrameRonin 成品，下次构建就会自动覆盖兜底版本。

## 入口

- macOS：双击 `更新动作素材.command`
- Windows：双击 `更新动作素材.bat`
- 命令行：`python3 tools/build_motion_sheets.py`

生成结果位于 `assets/generated/`，运行时配置位于 `assets/generated/actors.json`。
