# 《画境装配局：山河共生》

把《万物装配局》的能力构筑与《画境山河》的多章节古画叙事融合成一款人文探索战斗冒险。本分支加入 FrameRonin 离线美术接口、11 名角色动作表、可重建素材管线，以及桌面端和手机网页端发布流程。

![标题画面](preview_title.png)

![探索战斗](preview_explore.png)

![电影式对话](preview_dialogue.png)

![终章首领战](preview_boss.png)

![FrameRonin 动作表整合实机](integration_preview.png)

![手机横屏探索与战斗](mobile_preview.png)

## 直接游玩

macOS 双击 `开始游戏.command`。也可以用 Godot 4.7 打开 `project.godot` 后运行。

手机无需安装，直接打开[阿里云极速网页版](https://www.bigpower.ccwu.cc/shanhe/)。它不加载 Godot/WASM，首次打开约 140 KB，进入章节后再按需加载该卷约 0.7 MB 的场景与人物资源。手机建议横屏，并允许浏览器全屏显示。

电脑可打开[完整 Godot 画质版](https://www.bigpower.ccwu.cc/shanhe-godot/)，也可使用 [GitHub Pages 备用入口](https://bigpowert25-del.github.io/shanhe-gongsheng-frameronin/)。阿里云当前位于美国弗吉尼亚，极速版能显著降低启动等待，但服务器跨境线路本身仍可能有波动。

需要制作角色动作时，双击 `打开FrameRonin.command`；本机已部署的 FrameRonin 会在 `http://127.0.0.1:4173/` 打开。

已经导出的成品位于：

- `builds/macos/山河共生-macOS.zip`
- `builds/windows/山河共生-Windows.exe`
- `builds/web/index.html`
- `web_lite/index.html`（手机极速网页版）

## 一卷的完整循环

1. 在装配局选择两种动物共生能力。
2. 观看章节剧情，认识阿砚、沈烬、乔生与墨魇。
3. 进入古画地图，与 NPC 交谈并领取任务。
4. 探索三枚记忆残片、两处阵眼和两条可选人文见闻。
5. 使用墨刃战斗，清除裂墨并击败章节首领。
6. 战斗结束后处理这一卷的人与历史；选择会改变墨韵、心火、命数、英雄气和民声。

## 操作

- `WASD` / 方向键：移动
- 鼠标左键 / `空格` / `J`：墨刃攻击
- 鼠标右键 / `Shift` / `K`：闪避
- `Q`：画灵共鸣，范围伤害并显形目标
- `E`：和 NPC 交谈、调查见闻、修复阵眼
- `Tab`：隐藏 / 显示 HUD，让古画场景完整露出

画面右下角也提供了可点击操作按钮。

手机网页端使用左侧虚拟摇杆移动；右侧依次提供墨刃、闪避、共鸣和交互。触控区域按横屏安全区重新排布，不遮挡主角、NPC和主要任务目标。

## 电影式视觉与动作

- 探索 HUD 改为窄顶栏与轻量任务条；剧情、NPC、见闻和选择不再使用满屏大面板。
- 长段中文使用段落排版组件，按中文标点自然换行。
- 守卷人使用 4×4 动作表，并拥有待机、行走、突进、挥砍、闪避残影与受击反馈。
- 阿砚、沈烬、乔生、墨魇与守卷人具有一致的剧情立绘与场景人物形象，不再使用几何占位。
- 普通裂墨与六章首领均拥有独立动作表；碑甲墨兽、钟魇、纸傀、青兽、司书和初代守卷人各有明确的材料与文化母题。
- 视觉方向采用原创的古典武侠电影意境：空镜、竹影、雨雾、戏曲式停顿与克制色彩。

## FrameRonin 工作方式

FrameRonin 是外部美术生产工具，不嵌入游戏，也不复制它的网页源码。项目约定每名角色输出一张 4 列 × 4 行透明 PNG：四行依次为 `idle`、`walk`、`attack`、`hurt`。

把成品放入 `art_pipeline/inbox/`，文件名使用 `you.png`、`ayan.png`、`boss_01.png` 等角色 ID，再双击 `更新动作素材.command`。没有 FrameRonin 成品时，工具会从原始透明立绘生成开发用基础动作，保证工程始终能运行和发布。详细规则见 `art_pipeline/README.md`。

## 内容规模

- 六个剧情章节与六个首领
- 五名主要角色，24段章节对话
- 六种能力，形成15种双能力组合
- 18个关键抉择
- 12条普通人的人文见闻
- 三类结局
- 自动存档与失败后重组能力

## 叙事原则

本作沿用 OpenClaw 人文历史项目的基调：英雄气为主调，人民重量为底色，不喊口号。

“英雄气”不由击杀数增长，而来自明知代价仍选择不逃、对有能力伤害的人选择不伤害、以及把退路交给值得信任的人。“民声”则来自驿卒、车夫、桥匠、守林人、花农等普通人的可选见闻。

详细的来源转化说明见 `DESIGN_SOURCES.md`，古画署名见 `CREDITS.md`。

## 自动测试

```bash
python3 tools/test_motion_pipeline.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/smoke_test.gd
```

通过时输出：

```text
PIPELINE_TEST_PASS actors=11 animations=4 grid=4x4
SMOKE_TEST_PASS chapters=6 combat=ok bosses=6 lore=12 choices=18 endings=3 actors=11
```

## 重新生成发布包

macOS 双击 `生成发布包.command`。它会依次重建动作素材、安装缺失的 Godot 4.7 官方平台模板、运行测试，并生成 macOS Universal、Windows x86_64 和 Web/PWA 三种成品。只需要电脑完整网页版时，双击 `生成网页试玩版.command`；只需要手机极速网页版时，双击 `生成极速网页版.command`。发布细节见 `BUILDING.md`。
