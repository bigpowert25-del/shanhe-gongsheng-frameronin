extends Control

const SAVE_PATH := "user://inkbound_evolution_save.json"
const ExplorationScript := preload("res://scripts/exploration.gd")
const PortraitScript := preload("res://scripts/portrait.gd")
const AtmosphereScript := preload("res://scripts/atmosphere.gd")
const InkTransitionScript := preload("res://scripts/ink_transition.gd")
const GameContent := preload("res://scripts/game_content.gd")
const MobileJoystickScript := preload("res://scripts/mobile_joystick.gd")

var serif_font: Font
var sans_font: Font
var holder: Control
var transition: Control
var transition_busy := false
var chapter_index := 0
var legacy_stats := {"ink": 45, "heart": 45, "fate": 55, "hero": 0, "people": 0}
var selected_traits: Array[String] = []
var memory_fragments: Array[String] = []
var total_kills := 0
var dialogue_index := 0
var stage: Control
var hud_layer: Control
var hud_visible := true
var hud_nodes: Dictionary = {}
var quest_labels: Dictionary = {}
var toast_label: Label
var trait_buttons: Dictionary = {}
var lab_start_button: Button
var last_report: Dictionary = {}
var save_enabled := true
var mobile_mode := false

var traits: Array = GameContent.traits()
var chapters: Array = GameContent.chapters()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	mobile_mode = OS.has_feature("mobile") or OS.has_feature("web") or "--mobile-ui" in args
	serif_font = load("res://assets/fonts/NotoSerifSC-Variable.ttf")
	sans_font = load("res://assets/fonts/NotoSansSC-Variable.ttf")
	save_enabled = not "--no-save" in args
	holder = Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	transition = InkTransitionScript.new()
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.z_index = 200
	transition.visible = false
	add_child(transition)
	_build_title()
	_apply_preview()
	_capture_if_requested.call_deferred()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB and is_instance_valid(hud_layer):
		_toggle_hud()
		get_viewport().set_input_as_handled()


func _toggle_hud() -> void:
	if not is_instance_valid(hud_layer): return
	hud_visible = not hud_visible
	hud_layer.visible = hud_visible


func _clear() -> void:
	for child in holder.get_children(): child.queue_free()
	hud_nodes.clear()
	quest_labels.clear()
	trait_buttons.clear()
	stage = null
	hud_layer = null


func _switch(builder: Callable) -> void:
	if transition_busy: return
	transition_busy = true
	transition.visible = true
	transition.progress = 0.0
	var cover := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	cover.tween_property(transition, "progress", 1.0, 0.35)
	await cover.finished
	_clear()
	builder.call()
	await get_tree().process_frame
	var reveal := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	reveal.tween_property(transition, "progress", 0.0, 0.52)
	await reveal.finished
	transition.visible = false
	transition_busy = false


func _build_title() -> void:
	_art("res://assets/backgrounds/cover.jpg", Color("c9c1af"))
	_gradient([Color(0.015, 0.03, 0.03, 0.96), Color(0.015, 0.03, 0.03, 0.52), Color(0.015, 0.03, 0.03, 0.12)], Vector2(0, 0.5), Vector2(0.82, 0.5))
	_gradient([Color(0, 0, 0, 0), Color(0.005, 0.012, 0.012, 0.82)], Vector2(0.5, 0.28), Vector2(0.5, 1.0))
	_add_atmosphere("dust", Color("e4c677"))
	var badge := _label("叙事 · 装配 · 探索 · 战斗", 14, Color("d7b66d"), sans_font)
	badge.position = Vector2(68, 82)
	badge.size = Vector2(400, 25)
	holder.add_child(badge)
	var title := _label("画境装配局", 61, Color("f3eddf"), serif_font)
	title.position = Vector2(62, 132)
	title.size = Vector2(650, 80)
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.02, 0.6))
	holder.add_child(title)
	var subtitle := _label("山 河 共 生", 23, Color("d8ad66"), serif_font)
	subtitle.position = Vector2(68, 220)
	subtitle.size = Vector2(400, 38)
	holder.add_child(subtitle)
	var intro := _label("装配两种动物能力，进入六幅残损古画。\n与 NPC 交谈、执行任务、挥动墨刃、击败守卷首领，\n再用你的选择决定：修复世界，还是重写世界。", 18, Color("ddd9d0"), sans_font)
	intro.position = Vector2(68, 298)
	intro.size = Vector2(610, 112)
	intro.add_theme_constant_override("line_spacing", 8)
	holder.add_child(intro)
	var start := _button("新建守卷人  →", true, Color("d3ae66"))
	start.position = Vector2(68, 458)
	start.size = Vector2(236, 58)
	start.pressed.connect(_new_game)
	holder.add_child(start)
	if _has_save():
		var resume := _button("继续第%s卷" % _cn(chapter_index_from_save() + 1), false, Color("d3ae66"))
		resume.position = Vector2(320, 458)
		resume.size = Vector2(210, 58)
		resume.pressed.connect(_continue_game)
		holder.add_child(resume)
	var controls_hint := "左侧摇杆移动  ·  右侧触控：墨刃 / 闪避 / 共鸣 / 交互  ·  建议横屏" if mobile_mode else "WASD 移动  ·  左键/空格攻击  ·  Shift 闪避  ·  Q 共鸣  ·  E 交互"
	var keys := _label(controls_hint, 13, Color("aaa89f"), sans_font)
	keys.position = Vector2(68, 636)
	keys.size = Vector2(720, 24)
	holder.add_child(keys)

	var dossier := PanelContainer.new()
	dossier.position = Vector2(888, 96)
	dossier.size = Vector2(320, 500)
	dossier.add_theme_stylebox_override("panel", _style(Color(0.02, 0.04, 0.04, 0.86), Color(0.84, 0.70, 0.42, 0.38), 1, 10))
	holder.add_child(dossier)
	var dm := _margin(27, 25, 27, 25)
	dossier.add_child(dm)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	dm.add_child(box)
	var dt := _label("守 卷 任 务 档 案", 18, Color("e9d6a8"), serif_font)
	dt.custom_minimum_size.y = 32
	box.add_child(dt)
	box.add_child(_rule(Color(0.8, 0.67, 0.39, 0.35)))
	for item in [["06", "剧情章节"], ["18", "关键抉择"], ["30+", "战斗敌人"], ["06", "章节首领"], ["05", "主要人物"], ["03", "最终结局"]]:
		var row := HBoxContainer.new()
		var number := _label(item[0], 24, Color("d2a85f"), serif_font)
		number.custom_minimum_size = Vector2(72, 42)
		row.add_child(number)
		var name := _label(item[1], 16, Color("ddd9cf"), sans_font)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		box.add_child(row)


func _new_game() -> void:
	chapter_index = 0
	legacy_stats = {"ink": 45, "heart": 45, "fate": 55, "hero": 0, "people": 0}
	selected_traits.clear()
	memory_fragments.clear()
	total_kills = 0
	_delete_save()
	_switch(_build_lab)


func _build_lab() -> void:
	_art("res://assets/backgrounds/chapter_06.jpg", Color("c8c5b8"))
	_gradient([Color(0.01, 0.025, 0.025, 0.93), Color(0.01, 0.025, 0.025, 0.57), Color(0.01, 0.025, 0.025, 0.78)], Vector2(0, 0.5), Vector2(1, 0.5))
	_add_atmosphere("petals", Color("e1bdcd"))
	var eyebrow := _label("序章任务 · 装配画灵", 14, Color("d3ad69"), sans_font)
	eyebrow.position = Vector2(58, 38)
	eyebrow.size = Vector2(320, 24)
	holder.add_child(eyebrow)
	var title := _label("选择两种共生能力", 36, Color("f0eadf"), serif_font)
	title.position = Vector2(54, 65)
	title.size = Vector2(520, 52)
	holder.add_child(title)
	var help := _label("能力会直接改变移动、墨刃、闪避、吸血、防御与阵眼修复。\n选定后仍可在任务失败时返回这里重组。", 15, Color("c9c7c0"), sans_font)
	help.position = Vector2(58, 120)
	help.size = Vector2(640, 58)
	help.add_theme_constant_override("line_spacing", 5)
	holder.add_child(help)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(54, 198)
	grid.size = Vector2(760, 420)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	holder.add_child(grid)
	for trait_data in traits:
		var card := _trait_card(trait_data)
		grid.add_child(card)
		trait_buttons[trait_data.id] = card

	var loadout := PanelContainer.new()
	loadout.position = Vector2(846, 176)
	loadout.size = Vector2(370, 388)
	loadout.add_theme_stylebox_override("panel", _style(Color(0.02, 0.04, 0.04, 0.89), Color(0.83, 0.69, 0.41, 0.36), 1, 9))
	holder.add_child(loadout)
	var lm := _margin(27, 26, 27, 25)
	loadout.add_child(lm)
	var lb := VBoxContainer.new()
	lb.add_theme_constant_override("separation", 17)
	lm.add_child(lb)
	var lt := _label("共 生 体 档 案", 18, Color("ead6a5"), serif_font)
	lt.custom_minimum_size.y = 32
	lb.add_child(lt)
	lb.add_child(_rule(Color(0.83, 0.69, 0.41, 0.34)))
	var slot1 := _label("Ⅰ   尚未装配", 17, Color("8b8d87"), serif_font)
	slot1.name = "Slot1"
	slot1.custom_minimum_size.y = 47
	slot1.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.075, 0.75), Color(1, 1, 1, 0.10), 1, 5, 14))
	lb.add_child(slot1)
	var slot2 := _label("Ⅱ   尚未装配", 17, Color("8b8d87"), serif_font)
	slot2.name = "Slot2"
	slot2.custom_minimum_size.y = 47
	slot2.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.075, 0.75), Color(1, 1, 1, 0.10), 1, 5, 14))
	lb.add_child(slot2)
	var synergy := _label("装配两项能力后生成共生评估。", 14, Color("aaa9a2"), sans_font)
	synergy.name = "Synergy"
	synergy.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	synergy.custom_minimum_size.y = 70
	lb.add_child(synergy)
	lab_start_button = _button("确认装配，进入第一卷  →", true, Color("d3ae66"))
	lab_start_button.disabled = true
	lab_start_button.custom_minimum_size.y = 54
	lab_start_button.pressed.connect(_begin_chapter_story)
	lb.add_child(lab_start_button)
	loadout.set_meta("box", lb)
	loadout.name = "Loadout"
	_update_lab()


func _toggle_trait(id: String) -> void:
	if selected_traits.has(id):
		selected_traits.erase(id)
	elif selected_traits.size() < 2:
		selected_traits.append(id)
	else:
		# A third choice replaces the oldest one. This keeps the visible loadout and
		# the underlying state in lockstep, even during rapid mouse input.
		selected_traits.pop_front()
		selected_traits.append(id)
		var note := _label("已替换第一项能力", 13, Color("e4cf9b"), sans_font)
		note.position = Vector2(846, 580)
		note.size = Vector2(370, 28)
		holder.add_child(note)
		create_tween().tween_property(note, "modulate:a", 0.0, 1.4).set_delay(0.8)
	_update_lab()


func _update_lab() -> void:
	for id in trait_buttons:
		var card: PanelContainer = trait_buttons[id]
		var data := _trait(id)
		var selected := selected_traits.has(id)
		card.add_theme_stylebox_override("panel", _style(Color(data.color, 0.28) if selected else Color(0.025, 0.05, 0.05, 0.84), Color(data.color, 0.92) if selected else Color(0.8, 0.8, 0.7, 0.22), 2 if selected else 1, 8, 18))
	var loadout := holder.get_node_or_null("Loadout") as PanelContainer
	if not loadout: return
	var box: VBoxContainer = loadout.get_meta("box")
	var slot1 := box.get_node("Slot1") as Label
	var slot2 := box.get_node("Slot2") as Label
	var synergy := box.get_node("Synergy") as Label
	slot1.text = "Ⅰ   %s" % (_trait(selected_traits[0]).name if selected_traits.size() > 0 else "尚未装配")
	slot2.text = "Ⅱ   %s" % (_trait(selected_traits[1]).name if selected_traits.size() > 1 else "尚未装配")
	slot1.add_theme_color_override("font_color", Color("ead7b0") if selected_traits.size() > 0 else Color("8b8d87"))
	slot2.add_theme_color_override("font_color", Color("ead7b0") if selected_traits.size() > 1 else Color("8b8d87"))
	if selected_traits.size() == 2:
		synergy.text = "共生已稳定：%s × %s\n战斗与任务能力将在六卷中持续成长。" % [_trait(selected_traits[0]).origin, _trait(selected_traits[1]).origin]
	else:
		synergy.text = "装配两项能力后生成共生评估。"
	lab_start_button.disabled = selected_traits.size() != 2


func _begin_chapter_story() -> void:
	dialogue_index = 0
	_switch(_build_dialogue)


func _build_dialogue() -> void:
	var data: Dictionary = chapters[chapter_index]
	_art(data.image, data.accent.lightened(0.12))
	_gradient([Color(0.01, 0.02, 0.02, 0.28), Color(0.01, 0.02, 0.02, 0.02), Color(0.01, 0.02, 0.02, 0.30)], Vector2(0, 0.5), Vector2(1, 0.5))
	_gradient([Color(0, 0, 0, 0), Color(0.005, 0.012, 0.012, 0.58)], Vector2(0.5, 0.54), Vector2(0.5, 1.0))
	_add_atmosphere(data.mode, data.accent)
	var chapter_tag := _label("剧情 · 第%s卷" % _cn(chapter_index + 1), 14, data.accent, sans_font)
	chapter_tag.position = Vector2(52, 34)
	chapter_tag.size = Vector2(260, 24)
	holder.add_child(chapter_tag)
	var chapter_title := _label(data.title, 31, Color("f0eadf"), serif_font)
	chapter_title.position = Vector2(48, 58)
	chapter_title.size = Vector2(430, 50)
	holder.add_child(chapter_title)
	var objective_text := _label("交谈 · 搜集 · 修复 · 讨伐", 12, Color(data.accent, 0.88), sans_font)
	objective_text.position = Vector2(970, 44)
	objective_text.size = Vector2(250, 26)
	objective_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	holder.add_child(objective_text)

	# The figure occupies one side of the shot instead of sitting inside a UI card.
	var portrait := PortraitScript.new()
	portrait.name = "CinematicPortrait"
	portrait.position = Vector2(872, 112)
	portrait.size = Vector2(330, 520)
	portrait.modulate.a = 0.0
	holder.add_child(portrait)

	var dialog_panel := PanelContainer.new()
	dialog_panel.name = "DialogBack"
	dialog_panel.position = Vector2(48, 492)
	dialog_panel.size = Vector2(748, 164)
	dialog_panel.add_theme_stylebox_override("panel", _style(Color(0.012, 0.028, 0.028, 0.84), Color(data.accent, 0.48), 1, 8))
	holder.add_child(dialog_panel)
	var dialog_canvas := Control.new()
	dialog_canvas.name = "DialogPanel"
	dialog_panel.add_child(dialog_canvas)
	var speaker := _label("", 20, data.accent, serif_font)
	speaker.name = "Speaker"
	speaker.position = Vector2(24, 16)
	speaker.size = Vector2(520, 30)
	dialog_canvas.add_child(speaker)
	var dialogue := _paragraph("", 17, Color("e7e2d8"), sans_font)
	dialogue.name = "Dialogue"
	dialogue.position = Vector2(24, 52)
	dialogue.size = Vector2(560, 76)
	dialogue.add_theme_constant_override("line_separation", 6)
	dialog_canvas.add_child(dialogue)
	var next := _button("继续", true, data.accent)
	next.name = "Next"
	next.position = Vector2(590, 94)
	next.size = Vector2(132, 44)
	next.pressed.connect(_next_dialogue)
	dialog_canvas.add_child(next)
	var count := _label("", 12, Color("999b96"), sans_font)
	count.name = "Count"
	count.position = Vector2(24, 130)
	count.size = Vector2(200, 20)
	dialog_canvas.add_child(count)
	_update_dialogue()


func _update_dialogue() -> void:
	var data: Dictionary = chapters[chapter_index]
	var lines: Array = data.intro
	var line: Dictionary = lines[dialogue_index]
	var panel := holder.get_node("DialogBack/DialogPanel") as Control
	var portrait := holder.get_node("CinematicPortrait")
	portrait.configure(line.id, _character_color(line.id, data.accent))
	portrait.set_pose("speak" if line.id != "moyan" else "ready")
	var speaker := panel.get_node("Speaker") as Label
	var text_label := panel.get_node("Dialogue") as RichTextLabel
	var count := panel.get_node("Count") as Label
	var next := panel.get_node("Next") as Button
	speaker.text = line.speaker
	speaker.add_theme_color_override("font_color", _character_color(line.id, data.accent))
	text_label.text = line.text
	count.text = "%02d / %02d" % [dialogue_index + 1, lines.size()]
	next.text = "接受任务  →" if dialogue_index == lines.size() - 1 else "继续  →"
	text_label.modulate.a = 0.0
	text_label.position.x = 36
	portrait.modulate.a = 0.0
	portrait.position.x = 900 if dialogue_index % 2 == 0 else 852
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(text_label, "modulate:a", 1.0, 0.28)
	tween.tween_property(text_label, "position:x", 24.0, 0.32)
	tween.tween_property(portrait, "modulate:a", 1.0, 0.32)
	tween.tween_property(portrait, "position:x", 872.0, 0.42)


func _next_dialogue() -> void:
	var lines: Array = chapters[chapter_index].intro
	if dialogue_index < lines.size() - 1:
		dialogue_index += 1
		_update_dialogue()
	else:
		_switch(_build_exploration)


func _build_exploration() -> void:
	var data: Dictionary = chapters[chapter_index]
	_art(data.image, data.accent.lightened(0.08))
	_gradient([Color(0.01, 0.02, 0.02, 0.16), Color(0.01, 0.02, 0.02, 0.0), Color(0.01, 0.02, 0.02, 0.14)], Vector2(0, 0.5), Vector2(1, 0.5))
	stage = ExplorationScript.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(stage)
	stage.hud_changed.connect(_update_hud)
	stage.toast.connect(_show_toast)
	stage.npc_requested.connect(_show_npc_modal)
	stage.lore_requested.connect(_show_lore_modal)
	stage.chapter_completed.connect(_chapter_complete)
	stage.chapter_failed.connect(_chapter_failed)
	stage.shake_requested.connect(_shake)
	stage.set_mobile_mode(mobile_mode)
	hud_visible = true
	hud_layer = Control.new()
	hud_layer.name = "HudLayer"
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(hud_layer)

	var top := PanelContainer.new()
	top.position = Vector2(26, 18)
	top.size = Vector2(842, 52)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", _style(Color(0.012, 0.028, 0.028, 0.72), Color(data.accent, 0.26), 1, 6))
	hud_layer.add_child(top)
	var tm := _margin(15, 6, 15, 6)
	top.add_child(tm)
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 15)
	tm.add_child(tr)
	var chapter_name := _label("第%s卷 · %s" % [_cn(chapter_index + 1), data.title], 16, Color("f0eadf"), serif_font)
	chapter_name.custom_minimum_size.x = 205
	tr.add_child(chapter_name)
	_add_hud_bar(tr, "health", "生命", Color("d98572"))
	_add_hud_bar(tr, "energy", "共鸣", Color("d5b75e"))
	var timer_box := VBoxContainer.new()
	timer_box.custom_minimum_size = Vector2(82, 38)
	var timer_value := _label("00:00", 18, Color("e9ddc0"), sans_font)
	timer_value.name = "Timer"
	timer_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_box.add_child(timer_value)
	hud_nodes["timer"] = timer_value
	tr.add_child(timer_box)

	var quest := PanelContainer.new()
	quest.position = Vector2(26, 84)
	quest.size = Vector2(210, 204)
	quest.add_theme_stylebox_override("panel", _style(Color(0.012, 0.028, 0.028, 0.62), Color(data.accent, 0.24), 1, 6))
	hud_layer.add_child(quest)
	var qm := _margin(14, 11, 14, 10)
	quest.add_child(qm)
	var qb := VBoxContainer.new()
	qb.add_theme_constant_override("separation", 4)
	qm.add_child(qb)
	var qt := _label("本卷任务", 13, data.accent, serif_font)
	qt.custom_minimum_size.y = 24
	qb.add_child(qt)
	for item in [["npc", "与画中人物交谈"], ["fragments", "寻找记忆残片"], ["nodes", "修复两处阵眼"], ["kills", "清除三只裂墨"], ["boss", "击败守卷首领"], ["lore", "可选：人文见闻"]]:
		var ql := _label("○  %s" % item[1], 11, Color("c5c4bd"), sans_font)
		ql.custom_minimum_size.y = 23
		qb.add_child(ql)
		quest_labels[item[0]] = ql

	toast_label = _label("靠近人物或阵眼使用交互", 12, Color("f0e7d6"), sans_font)
	toast_label.position = Vector2(270, 666) if mobile_mode else Vector2(28, 666)
	toast_label.size = Vector2(430, 30)
	toast_label.add_theme_stylebox_override("normal", _style(Color(0.01, 0.025, 0.025, 0.62), Color(1, 1, 1, 0.08), 1, 5, 10))
	hud_layer.add_child(toast_label)

	if mobile_mode:
		_add_mobile_controls(data)
	else:
		var actions := HBoxContainer.new()
		actions.position = Vector2(778, 654)
		actions.size = Vector2(468, 44)
		actions.add_theme_constant_override("separation", 6)
		hud_layer.add_child(actions)
		var attack := _action_button("墨刃", "空格", data.accent)
		attack.pressed.connect(func(): if stage: stage.basic_attack())
		actions.add_child(attack)
		var dash_button := _action_button("闪避", "Shift", Color("8eb8c2"))
		dash_button.pressed.connect(func(): if stage: stage.dash())
		actions.add_child(dash_button)
		var burst_button := _action_button("共鸣", "Q", Color("d8b65f"))
		burst_button.pressed.connect(func(): if stage: stage.burst())
		actions.add_child(burst_button)
		var interact := _action_button("交互", "E", Color("91c7b3"))
		interact.pressed.connect(func(): if stage: stage.interact_action())
		actions.add_child(interact)
	var toggle := _button("界面" if mobile_mode else "界面  Tab", false, data.accent)
	toggle.position = Vector2(1138, 18)
	toggle.size = Vector2(106, 38)
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.pressed.connect(_toggle_hud)
	holder.add_child(toggle)
	stage.start_chapter.call_deferred(data, selected_traits, legacy_stats, chapter_index)


func _add_mobile_controls(data: Dictionary) -> void:
	var joystick := MobileJoystickScript.new()
	joystick.name = "MobileJoystick"
	joystick.position = Vector2(30, 486)
	joystick.size = Vector2(210, 210)
	joystick.z_index = 20
	joystick.direction_changed.connect(func(direction: Vector2): if stage: stage.set_virtual_move(direction))
	hud_layer.add_child(joystick)

	var move_label := _label("移动", 11, Color("d7d2c6"), sans_font)
	move_label.position = Vector2(110, 470)
	move_label.size = Vector2(60, 20)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(move_label)

	var attack := _mobile_action_button("墨刃", data.accent, Vector2(1120, 570), Vector2(112, 112))
	attack.pressed.connect(func(): if stage: stage.mobile_attack())
	hud_layer.add_child(attack)
	var dash_button := _mobile_action_button("闪避", Color("8eb8c2"), Vector2(1008, 606), Vector2(96, 78))
	dash_button.pressed.connect(func(): if stage: stage.dash())
	hud_layer.add_child(dash_button)
	var burst_button := _mobile_action_button("共鸣", Color("d8b65f"), Vector2(1018, 506), Vector2(96, 78))
	burst_button.pressed.connect(func(): if stage: stage.burst())
	hud_layer.add_child(burst_button)
	var interact := _mobile_action_button("交互", Color("91c7b3"), Vector2(1120, 472), Vector2(112, 78))
	interact.button_down.connect(func(): if stage: stage.set_virtual_interact(true))
	interact.button_up.connect(func(): if stage: stage.set_virtual_interact(false))
	hud_layer.add_child(interact)


func _mobile_action_button(text_value: String, accent: Color, button_position: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = button_position
	button.size = button_size
	button.add_theme_font_override("font", sans_font)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("f2eee4"))
	button.add_theme_stylebox_override("normal", _style(Color(0.01, 0.03, 0.03, 0.68), Color(accent, 0.58), 2, 34, 8))
	button.add_theme_stylebox_override("hover", _style(Color(accent, 0.22), Color(accent, 0.88), 2, 34, 8))
	button.add_theme_stylebox_override("pressed", _style(Color(accent, 0.72), accent.lightened(0.18), 3, 34, 8))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _add_hud_bar(parent: Container, key: String, title: String, color: Color) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(152, 38)
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var name := _label(title, 10, Color("aaa9a2"), sans_font)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var value := _label("100", 10, color, sans_font)
	value.custom_minimum_size.x = 34
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(152, 5)
	bar.add_theme_stylebox_override("background", _style(Color(0.06, 0.08, 0.08, 0.85), Color(1, 1, 1, 0.08), 0, 4))
	bar.add_theme_stylebox_override("fill", _style(color, color, 0, 4))
	box.add_child(bar)
	hud_nodes[key] = {"bar": bar, "value": value}


func _update_hud(data: Dictionary) -> void:
	if hud_nodes.is_empty(): return
	for key in ["health", "energy"]:
		var entry: Dictionary = hud_nodes[key]
		var maximum := float(data["max_%s" % key])
		entry.bar.max_value = maximum
		entry.bar.value = float(data[key])
		entry.value.text = "%d" % int(data[key])
	var seconds := maxi(0, int(data.time))
	var timer := hud_nodes.timer as Label
	timer.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	timer.add_theme_color_override("font_color", Color("e79a83") if seconds < 20 else Color("e9ddc0"))
	_set_quest("npc", bool(data.npc), "与画中人物交谈")
	_set_quest("fragments", int(data.fragments) >= 3, "记忆残片  %d / 3" % int(data.fragments))
	_set_quest("nodes", int(data.nodes) >= 2, "修复阵眼  %d / 2" % int(data.nodes))
	_set_quest("kills", int(data.kills) >= 3, "清除裂墨  %d / 3" % int(data.kills))
	_set_quest("boss", bool(data.boss), "%s%s" % ["击败" if bool(data.boss_spawned) else "等待", "守卷首领"])
	_set_quest("lore", int(data.lore) >= 2, "人文见闻  %d / 2" % int(data.lore), true)


func _set_quest(key: String, done: bool, text_value: String, optional := false) -> void:
	if not quest_labels.has(key): return
	var label := quest_labels[key] as Label
	label.text = "%s  %s" % ["✓" if done else ("◇" if optional else "○"), text_value]
	label.add_theme_color_override("font_color", Color("9bd0b7") if done else (Color("d4b86f") if optional else Color("c5c4bd")))


func _show_toast(message: String) -> void:
	if not is_instance_valid(toast_label): return
	toast_label.text = message
	toast_label.modulate.a = 1.0
	toast_label.position.x = 18
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(toast_label, "position:x", 28.0, 0.24)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.65).set_delay(2.1)


func _show_npc_modal(data: Dictionary) -> void:
	if stage: stage.pause_game(true)
	var modal := _modal_base(data.color, Vector2(48, 452), Vector2(760, 214), 0.12)
	var portrait := PortraitScript.new()
	portrait.position = Vector2(555, -230)
	portrait.size = Vector2(275, 430)
	portrait.configure(data.id, data.color)
	portrait.set_pose("speak")
	modal.add_child(portrait)
	var name := _label(data.name, 23, data.color, serif_font)
	name.position = Vector2(24, 16)
	name.size = Vector2(360, 34)
	modal.add_child(name)
	var role := _label(data.title, 12, Color("aaa9a2"), sans_font)
	role.position = Vector2(26, 48)
	role.size = Vector2(420, 20)
	modal.add_child(role)
	var text_value := "%s\n%s" % [data.lines[0], data.lines[1]]
	var text_label := _label(text_value, 15, Color("e3dfd6"), sans_font)
	text_label.position = Vector2(24, 75)
	text_label.size = Vector2(505, 100)
	text_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	text_label.add_theme_constant_override("line_spacing", 6)
	modal.add_child(text_label)
	var close := _button("记住了  →", true, data.color)
	close.position = Vector2(350, 145)
	close.size = Vector2(170, 44)
	close.pressed.connect(_close_modal.bind(modal))
	modal.add_child(close)


func _show_lore_modal(data: Dictionary) -> void:
	if stage: stage.pause_game(true)
	var accent := Color("d7b76d")
	var modal := _modal_base(accent, Vector2(696, 342), Vector2(526, 324), 0.10)
	var mark := _label("人\n间\n见\n闻", 20, Color("f0dfb5"), serif_font)
	mark.position = Vector2(24, 28)
	mark.size = Vector2(54, 172)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_theme_stylebox_override("normal", _style(Color("8d352e"), Color("c7796e"), 1, 5))
	modal.add_child(mark)
	var title := _label(data.title, 24, Color("f0e7d6"), serif_font)
	title.position = Vector2(104, 28)
	title.size = Vector2(380, 38)
	modal.add_child(title)
	var tag := _label("可选调查 · 民声并不写在功业榜上", 12, accent, sans_font)
	tag.position = Vector2(106, 69)
	tag.size = Vector2(360, 22)
	modal.add_child(tag)
	var text_label := _paragraph(data.text, 15, Color("ddd9cf"), sans_font)
	text_label.position = Vector2(104, 102)
	text_label.size = Vector2(380, 132)
	text_label.add_theme_constant_override("line_separation", 6)
	modal.add_child(text_label)
	var close := _button("收录进人间志  →", true, accent)
	close.position = Vector2(262, 250)
	close.size = Vector2(226, 44)
	close.pressed.connect(_close_modal.bind(modal))
	modal.add_child(close)


func _modal_base(accent: Color, modal_position := Vector2(190, 190), modal_size := Vector2(900, 320), shade_alpha := 0.18) -> Control:
	if is_instance_valid(hud_layer):
		hud_layer.visible = false
		hud_layer.modulate.a = 0.0
	var shade := ColorRect.new()
	shade.name = "ModalShade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.012, 0.012, shade_alpha)
	shade.z_index = 80
	holder.add_child(shade)
	var modal := PanelContainer.new()
	modal.position = modal_position
	modal.size = modal_size
	modal.add_theme_stylebox_override("panel", _style(Color(0.015, 0.032, 0.032, 0.91), Color(accent, 0.64), 1, 9))
	shade.add_child(modal)
	var canvas := Control.new()
	canvas.name = "Canvas"
	modal.add_child(canvas)
	modal.modulate.a = 0.0
	modal.scale = Vector2(0.97, 0.97)
	modal.pivot_offset = modal_size * 0.5
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "modulate:a", 1.0, 0.25)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.30)
	return canvas


func _close_modal(modal: Control) -> void:
	var shade := modal.get_parent().get_parent()
	shade.queue_free()
	if is_instance_valid(hud_layer):
		hud_layer.modulate.a = 1.0
		hud_layer.visible = hud_visible
	if stage: stage.pause_game(false)


func _shake(strength: float) -> void:
	holder.position = Vector2(randi_range(-int(strength), int(strength)), randi_range(-int(strength), int(strength)))
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "position", Vector2.ZERO, 0.24)


func _chapter_failed(reason: String) -> void:
	if stage: stage.pause_game(true)
	var modal := _modal_base(Color("cf6f5d"))
	var title := _label("任务失败 · 画心溃散", 28, Color("edb0a2"), serif_font)
	title.position = Vector2(50, 42)
	title.size = Vector2(600, 42)
	modal.add_child(title)
	var desc := _label("%s。\n失败不会抹去已经看见的人与事；你可以保留装配重试，或回实验室改变共生能力。" % reason, 17, Color("ddd9d0"), sans_font)
	desc.position = Vector2(52, 104)
	desc.size = Vector2(790, 86)
	desc.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	desc.add_theme_constant_override("line_spacing", 7)
	modal.add_child(desc)
	var retry := _button("保留装配，重试", true, Color("d4ad68"))
	retry.position = Vector2(52, 224)
	retry.size = Vector2(210, 50)
	retry.pressed.connect(func(): _switch(_build_exploration))
	modal.add_child(retry)
	var rebuild := _button("返回装配局", false, Color("d4ad68"))
	rebuild.position = Vector2(280, 224)
	rebuild.size = Vector2(190, 50)
	rebuild.pressed.connect(func(): _switch(_build_lab))
	modal.add_child(rebuild)


func _chapter_complete(report: Dictionary) -> void:
	last_report = report
	total_kills += int(report.kills)
	legacy_stats.people = int(legacy_stats.people) + int(report.lore) * 2
	_switch(_build_decision)


func _build_decision() -> void:
	var data: Dictionary = chapters[chapter_index]
	_art(data.image, data.accent.lightened(0.10))
	_gradient([Color(0.01, 0.02, 0.02, 0.48), Color(0.01, 0.02, 0.02, 0.03), Color(0.01, 0.02, 0.02, 0.24)], Vector2(0, 0.5), Vector2(1, 0.5))
	_gradient([Color(0, 0, 0, 0), Color(0.005, 0.012, 0.012, 0.68)], Vector2(0.5, 0.58), Vector2(0.5, 1.0))
	_add_atmosphere(data.mode, data.accent)
	var complete := _label("任务完成 · 第%s卷" % _cn(chapter_index + 1), 14, data.accent, sans_font)
	complete.position = Vector2(54, 34)
	complete.size = Vector2(320, 24)
	holder.add_child(complete)
	var title := _label("胜负之后，才是选择", 35, Color("f0eade"), serif_font)
	title.position = Vector2(50, 62)
	title.size = Vector2(570, 54)
	holder.add_child(title)
	var metrics := HBoxContainer.new()
	metrics.position = Vector2(52, 122)
	metrics.size = Vector2(620, 54)
	metrics.add_theme_constant_override("separation", 7)
	holder.add_child(metrics)
	for item in [["用时", "%d 秒" % int(last_report.time)], ["余命", "%d%%" % int(last_report.health)], ["击败", "%d" % int(last_report.kills)], ["见闻", "%d / 2" % int(last_report.lore)]]:
		var metric := _label("%s  %s" % [item[0], item[1]], 12, Color("d8d4ca"), sans_font)
		metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metric.custom_minimum_size = Vector2(142, 42)
		metric.add_theme_stylebox_override("normal", _style(Color(0.025, 0.05, 0.05, 0.62), Color(1, 1, 1, 0.09), 1, 5))
		metrics.add_child(metric)
	var hero_note := _label("英雄气不由击杀数决定。\n它只在你明知要付代价，仍选择不逃、信任或不伤害弱者时增长。", 15, Color("d9bf7d"), serif_font)
	hero_note.position = Vector2(52, 184)
	hero_note.size = Vector2(610, 70)
	hero_note.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	hero_note.add_theme_constant_override("line_spacing", 6)
	holder.add_child(hero_note)
	var scores := _label("英雄气 %d   ·   民声 %d" % [int(legacy_stats.hero), int(legacy_stats.people)], 13, Color("b6cfc4"), sans_font)
	scores.position = Vector2(52, 256)
	scores.size = Vector2(360, 28)
	holder.add_child(scores)

	var choices_panel := Control.new()
	choices_panel.name = "Choices"
	choices_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(choices_panel)
	var prompt := _label("战斗已经结束。你如何处理这一卷的人与历史？", 14, Color("d8d3c8"), sans_font)
	prompt.position = Vector2(52, 422)
	prompt.size = Vector2(600, 30)
	choices_panel.add_child(prompt)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 462)
	row.size = Vector2(1200, 190)
	row.add_theme_constant_override("separation", 12)
	choices_panel.add_child(row)
	for i in data.choices.size():
		var choice: Dictionary = data.choices[i]
		row.add_child(_choice_card(i, choice, data.accent))


func _choose_aftermath(index: int) -> void:
	var data: Dictionary = chapters[chapter_index]
	var choice: Dictionary = data.choices[index]
	for key in ["ink", "heart", "fate"]:
		legacy_stats[key] = clampi(int(legacy_stats[key]) + int(choice.delta.get(key, 0)), 0, 100)
	var fate_cost := maxi(0, -int(choice.delta.get("fate", 0)))
	var compassionate_risk := maxi(0, int(choice.delta.get("heart", 0)) - 8)
	var hero_gain := fate_cost + int(ceil(float(compassionate_risk) * 0.55))
	legacy_stats.hero = int(legacy_stats.hero) + hero_gain
	memory_fragments.append(choice.fragment)
	var panel := holder.get_node("Choices") as Control
	for child in panel.get_children(): child.queue_free()
	var result_panel := PanelContainer.new()
	result_panel.position = Vector2(650, 358)
	result_panel.size = Vector2(560, 292)
	result_panel.add_theme_stylebox_override("panel", _style(Color(0.012, 0.028, 0.028, 0.84), Color(data.accent, 0.52), 1, 8))
	panel.add_child(result_panel)
	var canvas := Control.new()
	result_panel.add_child(canvas)
	var tag := _label("抉择已写入山河", 12, data.accent, sans_font)
	tag.position = Vector2(22, 16)
	tag.size = Vector2(260, 24)
	canvas.add_child(tag)
	var title := _label(choice.title, 27, Color("f0eadf"), serif_font)
	title.position = Vector2(20, 45)
	title.size = Vector2(500, 42)
	canvas.add_child(title)
	var result := _label(choice.result, 17, Color("dcd8cf"), sans_font)
	result.position = Vector2(22, 90)
	result.size = Vector2(510, 68)
	result.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	result.add_theme_constant_override("line_spacing", 7)
	canvas.add_child(result)
	var fragment := _label("获得记忆印记 · %s" % choice.fragment, 15, Color("d8bd77"), serif_font)
	fragment.position = Vector2(22, 164)
	fragment.size = Vector2(500, 38)
	fragment.add_theme_stylebox_override("normal", _style(Color(0.08, 0.075, 0.05, 0.72), Color(0.82, 0.69, 0.38, 0.30), 1, 5, 14))
	canvas.add_child(fragment)
	var hero_text := "英雄气 +%d" % hero_gain if hero_gain > 0 else "这是一项务实选择 · 英雄气未改变"
	var change := _label("%s    民声累计 %d" % [hero_text, int(legacy_stats.people)], 14, Color("a9cdbd"), sans_font)
	change.position = Vector2(22, 207)
	change.size = Vector2(330, 34)
	canvas.add_child(change)
	var next_text := "进入终章  →" if chapter_index == chapters.size() - 1 else "前往第%s卷  →" % _cn(chapter_index + 2)
	var next := _button(next_text, true, data.accent)
	next.position = Vector2(356, 220)
	next.size = Vector2(178, 48)
	next.pressed.connect(_advance_story)
	canvas.add_child(next)


func _advance_story() -> void:
	if chapter_index >= chapters.size() - 1:
		_delete_save()
		_switch(_build_ending)
	else:
		chapter_index += 1
		dialogue_index = 0
		_save()
		_switch(_build_dialogue)


func _build_ending() -> void:
	_art("res://assets/backgrounds/epilogue.jpg", Color("cbc5b4"))
	_gradient([Color(0.01, 0.025, 0.025, 0.92), Color(0.01, 0.025, 0.025, 0.25), Color(0.01, 0.025, 0.025, 0.76)], Vector2(0, 0.5), Vector2(1, 0.5))
	_add_atmosphere("fireflies", Color("dfc371"))
	var ending := _resolve_ending()
	var tag := _label("终章 · 六卷任务结算", 14, Color("d5b567"), sans_font)
	tag.position = Vector2(64, 58)
	tag.size = Vector2(350, 25)
	holder.add_child(tag)
	var title := _label(ending.title, 54, Color("f1eadc"), serif_font)
	title.position = Vector2(58, 100)
	title.size = Vector2(650, 74)
	holder.add_child(title)
	var quote := _label("“%s”" % ending.quote, 18, Color("d8bd77"), serif_font)
	quote.position = Vector2(64, 184)
	quote.size = Vector2(680, 38)
	holder.add_child(quote)
	var desc := _paragraph(ending.desc, 17, Color("ded9d0"), sans_font)
	desc.position = Vector2(64, 244)
	desc.size = Vector2(600, 114)
	desc.add_theme_constant_override("line_separation", 7)
	holder.add_child(desc)
	var score := PanelContainer.new()
	score.position = Vector2(64, 398)
	score.size = Vector2(610, 142)
	score.add_theme_stylebox_override("panel", _style(Color(0.015, 0.032, 0.032, 0.86), Color(0.83, 0.70, 0.42, 0.36), 1, 8))
	holder.add_child(score)
	var sm := _margin(22, 18, 22, 18)
	score.add_child(sm)
	var sb := VBoxContainer.new()
	sb.add_theme_constant_override("separation", 14)
	sm.add_child(sb)
	sb.add_child(_label("你的守卷人档案", 13, Color("c9b67e"), sans_font))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	sb.add_child(row)
	for item in [["英雄气", legacy_stats.hero, Color("d9bd70")], ["民声", legacy_stats.people, Color("9bc7b5")], ["击败", total_kills, Color("d68e78")], ["印记", memory_fragments.size(), Color("a8bdd0")]]:
		var capsule := _label("%s\n%02d" % [item[0], item[1]], 14, item[2], sans_font)
		capsule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		capsule.custom_minimum_size = Vector2(132, 62)
		capsule.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.075, 0.74), Color(item[2], 0.28), 1, 5))
		row.add_child(capsule)
	var again := _button("重新装配  →", true, Color("d3ad66"))
	again.position = Vector2(64, 580)
	again.size = Vector2(210, 54)
	again.pressed.connect(_new_game)
	holder.add_child(again)
	var back := _button("返回卷首", false, Color("d3ad66"))
	back.position = Vector2(290, 580)
	back.size = Vector2(180, 54)
	back.pressed.connect(func(): _switch(_build_title))
	holder.add_child(back)

	var people_card := PanelContainer.new()
	people_card.position = Vector2(850, 118)
	people_card.size = Vector2(350, 432)
	people_card.add_theme_stylebox_override("panel", _style(Color(0.015, 0.032, 0.032, 0.76), Color(0.83, 0.70, 0.42, 0.32), 1, 8))
	holder.add_child(people_card)
	var pm := _margin(22, 21, 22, 20)
	people_card.add_child(pm)
	var pb := VBoxContainer.new()
	pb.add_theme_constant_override("separation", 10)
	pm.add_child(pb)
	var pt := _label("人 间 与 英 雄", 19, Color("ead7a8"), serif_font)
	pt.custom_minimum_size.y = 34
	pb.add_child(pt)
	pb.add_child(_rule(Color(0.83, 0.70, 0.42, 0.33)))
	var reflection := _label("英雄气不是勇猛，也不是赢。\n\n它是知道代价以后仍不逃，是已经有能力伤害时选择不伤害，是把退路交给一个值得信任的人。\n\n但若没有那些运粮、修桥、守灯、种花的普通人，英雄守住的便只剩一个空名字。", 14, Color("dcd8cf"), serif_font)
	reflection.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	reflection.custom_minimum_size.y = 240
	reflection.add_theme_constant_override("line_spacing", 6)
	pb.add_child(reflection)
	var final_note := _label("英雄气为锋，人民重量为底色。", 15, Color("d5b96f"), serif_font)
	final_note.custom_minimum_size.y = 44
	pb.add_child(final_note)


func _resolve_ending() -> Dictionary:
	var hero := int(legacy_stats.hero)
	var people := int(legacy_stats.people)
	if hero >= 28 and people >= 18:
		return {"title": "人间山河", "quote": "守住山河的从来不只是一位英雄，而是无数不肯熄灭的灯。", "desc": "画门开启后，阿砚与画中人没有涌向现实，而是先回去收拾桥、驿站与荒田。你终于明白：最好的结局不是英雄拯救众生，而是众生重新拥有自己的明天。"}
	if hero >= 24:
		return {"title": "孤胆留名", "quote": "有些仗不是因为能赢才打，而是因为不能不打。", "desc": "你用一次次不肯后退的选择劈开画门，成为新一代守卷人。后世记住了你的名字，却很少有人知道那些没被收进人间志的普通人。山河得救，重量仍不完整。"}
	return {"title": "务实新卷", "quote": "活下来不是怯懦，真正的问题是活下来以后要做什么。", "desc": "你避开最昂贵的牺牲，用稳定而克制的方法重建六卷。它没有传奇般的光，却留下了足够多的道路和粮食。阿砚说，也许英雄气只在少数时刻出现，而日子终究要靠普通人继续。"}


func _save() -> void:
	if not save_enabled: return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"chapter": chapter_index, "stats": legacy_stats, "traits": selected_traits,
			"fragments": memory_fragments, "kills": total_kills
		}))


func _continue_game() -> void:
	var data := _read_save()
	if data.is_empty():
		_new_game()
		return
	chapter_index = clampi(int(data.get("chapter", 0)), 0, chapters.size() - 1)
	var loaded: Dictionary = data.get("stats", {})
	legacy_stats = {
		"ink": int(loaded.get("ink", 45)), "heart": int(loaded.get("heart", 45)),
		"fate": int(loaded.get("fate", 55)), "hero": int(loaded.get("hero", 0)),
		"people": int(loaded.get("people", 0))
	}
	selected_traits.clear()
	for item in data.get("traits", []): selected_traits.append(str(item))
	if selected_traits.size() != 2:
		selected_traits = ["tiger", "wolf"]
	memory_fragments.clear()
	for item in data.get("fragments", []): memory_fragments.append(str(item))
	total_kills = int(data.get("kills", 0))
	dialogue_index = 0
	_switch(_build_dialogue)


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH): return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _has_save() -> bool:
	return not _read_save().is_empty()


func chapter_index_from_save() -> int:
	return clampi(int(_read_save().get("chapter", 0)), 0, chapters.size() - 1)


func _delete_save() -> void:
	if save_enabled and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _trait(id: String) -> Dictionary:
	for data in traits:
		if data.id == id: return data
	return traits[0]


func _character_color(id: String, fallback: Color) -> Color:
	match id:
		"ayan": return Color("d8b66d")
		"shenjin": return Color("c66d5d")
		"qiaosheng": return Color("93b6c6")
		"moyan": return Color("d09aad")
		"you": return Color("e4ded0")
		_: return fallback


func _delta_text(delta: Dictionary) -> String:
	var parts: Array[String] = []
	for item in [["ink", "墨韵"], ["heart", "心火"], ["fate", "命数"]]:
		var value := int(delta.get(item[0], 0))
		parts.append("%s %s%d" % [item[1], "+" if value >= 0 else "", value])
	return "  ·  ".join(parts)


func _trait_card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(368, 112)
	card.add_theme_stylebox_override("panel", _style(Color(0.025, 0.05, 0.05, 0.84), Color(0.8, 0.8, 0.7, 0.22), 1, 8, 18))
	var canvas := Control.new()
	card.add_child(canvas)
	var title := _label(data.name, 17, Color("f0e9dc"), serif_font)
	title.position = Vector2(18, 12)
	title.size = Vector2(205, 29)
	canvas.add_child(title)
	var origin := _label(data.origin, 12, Color(data.color), sans_font)
	origin.position = Vector2(236, 14)
	origin.size = Vector2(110, 25)
	origin.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(origin)
	var desc := _label(data.desc, 14, Color("d5d2ca"), sans_font)
	desc.position = Vector2(18, 52)
	desc.size = Vector2(328, 40)
	desc.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	canvas.add_child(desc)
	var hit := Button.new()
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", _style(Color(data.color, 0.08), Color(data.color, 0.36), 1, 8))
	hit.add_theme_stylebox_override("pressed", _style(Color(data.color, 0.18), Color(data.color, 0.65), 1, 8))
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(_toggle_trait.bind(data.id))
	canvas.add_child(hit)
	return card


func _choice_card(index: int, choice: Dictionary, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(392, 184)
	var normal_style := _style(Color(0.012, 0.03, 0.03, 0.80), Color(1, 1, 1, 0.14), 1, 7, 16)
	var hover_style := _style(Color(0.035, 0.065, 0.06, 0.93), Color(accent, 0.76), 1, 7, 16)
	card.add_theme_stylebox_override("panel", normal_style)
	var canvas := Control.new()
	card.add_child(canvas)
	var number := _label("0%d" % (index + 1), 12, Color(accent, 0.78), sans_font)
	number.position = Vector2(17, 12)
	number.size = Vector2(44, 22)
	canvas.add_child(number)
	var title := _label(choice.title, 18, Color("f0eadf"), serif_font)
	title.position = Vector2(17, 35)
	title.size = Vector2(350, 33)
	canvas.add_child(title)
	var desc := _label(choice.desc, 13, Color("d2cfc7"), sans_font)
	desc.position = Vector2(17, 73)
	desc.size = Vector2(350, 48)
	desc.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	canvas.add_child(desc)
	var delta := _label(_delta_text(choice.delta), 11, Color("b8cfc3"), sans_font)
	delta.position = Vector2(17, 133)
	delta.size = Vector2(350, 27)
	canvas.add_child(delta)
	var hit := Button.new()
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", hover_style))
	hit.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", normal_style))
	hit.pressed.connect(_choose_aftermath.bind(index))
	canvas.add_child(hit)
	return card


func _action_button(name: String, key: String, accent: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(112, 44)
	button.text = "%s\n%s" % [name, key]
	button.add_theme_font_override("font", sans_font)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("e8e3da"))
	button.add_theme_stylebox_override("normal", _style(Color(0.012, 0.03, 0.03, 0.90), Color(accent, 0.38), 1, 6))
	button.add_theme_stylebox_override("hover", _style(Color(accent, 0.24), Color(accent, 0.85), 1, 6))
	button.add_theme_stylebox_override("pressed", _style(accent, accent.lightened(0.12), 1, 6))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _art(path: String, tint: Color) -> TextureRect:
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = tint
	holder.add_child(art)
	art.pivot_offset = Vector2(640, 360)
	art.scale = Vector2(1.025, 1.025)
	var tween := art.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(art, "scale", Vector2(1.06, 1.06), 13.0)
	tween.tween_property(art, "scale", Vector2(1.025, 1.025), 13.0)
	return art


func _gradient(colors: Array[Color], from: Vector2, to: Vector2) -> TextureRect:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	if colors.size() == 3: gradient.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = from
	texture.fill_to = to
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(rect)
	return rect


func _add_atmosphere(mode: String, color: Color) -> void:
	var atmosphere := AtmosphereScript.new()
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(atmosphere)
	atmosphere.configure(mode, color)


func _label(text_value: String, size_value: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _paragraph(text_value: String, size_value: int, color: Color, font: Font) -> RichTextLabel:
	var paragraph := RichTextLabel.new()
	paragraph.text = text_value
	paragraph.bbcode_enabled = false
	paragraph.fit_content = false
	paragraph.scroll_active = false
	paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paragraph.add_theme_font_override("normal_font", font)
	paragraph.add_theme_font_size_override("normal_font_size", size_value)
	paragraph.add_theme_color_override("default_color", color)
	return paragraph


func _button(text_value: String, primary: bool, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_override("font", sans_font)
	button.add_theme_font_size_override("font_size", 15)
	if primary:
		button.add_theme_color_override("font_color", Color("15201e"))
		button.add_theme_stylebox_override("normal", _style(accent, accent.lightened(0.10), 1, 5))
		button.add_theme_stylebox_override("hover", _style(accent.lightened(0.13), Color("efd795"), 1, 5))
		button.add_theme_stylebox_override("pressed", _style(accent.darkened(0.12), accent, 1, 5))
	else:
		button.add_theme_color_override("font_color", Color("e5dfd3"))
		button.add_theme_stylebox_override("normal", _style(Color(0.02, 0.045, 0.045, 0.82), Color(accent, 0.52), 1, 5))
		button.add_theme_stylebox_override("hover", _style(Color(accent, 0.18), Color(accent, 0.90), 1, 5))
		button.add_theme_stylebox_override("pressed", _style(Color(accent, 0.30), accent, 1, 5))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _style(bg: Color, border: Color, width: int, radius: int, padding := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	if padding > 0:
		style.content_margin_left = padding
		style.content_margin_right = padding
		style.content_margin_top = 9
		style.content_margin_bottom = 9
	return style


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _rule(color: Color) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size.y = 1
	return rule


func _cn(value: int) -> String:
	return ["零", "一", "二", "三", "四", "五", "六"][clampi(value, 0, 6)]


func _apply_preview() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--preview="): continue
		var screen := arg.trim_prefix("--preview=")
		_clear()
		selected_traits = ["tiger", "wolf"]
		legacy_stats = {"ink": 67, "heart": 72, "fate": 56, "hero": 26, "people": 18}
		match screen:
			"lab": _build_lab()
			"dialogue":
				chapter_index = 3
				dialogue_index = 1
				_build_dialogue()
			"explore":
				chapter_index = 4
				_build_exploration()
			"npc":
				chapter_index = 4
				_build_exploration()
				_show_npc_modal.call_deferred(chapters[chapter_index].npc)
			"lore":
				chapter_index = 4
				_build_exploration()
				_show_lore_modal.call_deferred(chapters[chapter_index].lore[0])
			"boss":
				chapter_index = 5
				_build_exploration()
				_prepare_boss_preview.call_deferred()
			"decision":
				chapter_index = 2
				last_report = {"time": 52.0, "health": 68.0, "kills": 5, "lore": 2}
				_build_decision()
			"ending":
				memory_fragments = ["风尘朱印", "第十四声", "未干落款", "初代守卷印", "半命归途", "共生终笔"]
				total_kills = 30
				_build_ending()


func _capture_if_requested() -> void:
	var target := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): target = arg.trim_prefix("--capture=")
	if target.is_empty(): return
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(target))
	get_tree().quit()


func _prepare_boss_preview() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not stage: return
	stage.npc_talked = true
	stage.fragments_found = 3
	stage.nodes_restored = 2
	stage.enemies_defeated = 3
	stage.player_pos = Vector2(620, 455)
	stage.aim_pos = Vector2(690, 330)
	stage._check_boss_and_portal()
	stage.energy = stage.max_energy
	stage.burst()
	stage.basic_attack()
