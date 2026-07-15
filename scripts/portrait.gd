extends Control

const CHARACTER_TEXTURES := {
	"you": preload("res://assets/characters/you.png"),
	"ayan": preload("res://assets/characters/ayan.png"),
	"shenjin": preload("res://assets/characters/shenjin.png"),
	"qiaosheng": preload("res://assets/characters/qiaosheng.png"),
	"moyan": preload("res://assets/enemies/boss_06.png")
}

var character_id := "ayan"
var accent := Color("d7b36b")
var pose := "idle"
var motion_time := 0.0


func configure(id: String, color: Color) -> void:
	character_id = id
	accent = color
	queue_redraw()


func set_pose(value: String) -> void:
	pose = value
	motion_time = 0.0
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	motion_time += delta
	queue_redraw()


func _draw() -> void:
	if CHARACTER_TEXTURES.has(character_id):
		_draw_cinematic_texture(CHARACTER_TEXTURES[character_id])
		return
	var scale_value := minf(size.x / 320.0, size.y / 500.0)
	var origin := Vector2(size.x * 0.5, size.y - 9.0)
	draw_set_transform(origin, 0.0, Vector2(scale_value, scale_value))
	_draw_ink_backdrop()
	match character_id:
		"ayan": _draw_ayan()
		"shenjin": _draw_shenjin()
		"qiaosheng": _draw_qiaosheng()
		"moyan": _draw_moyan()
		"you": _draw_keeper()
		_: _draw_keeper()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_cinematic_texture(texture: Texture2D) -> void:
	var texture_size := texture.get_size()
	var target_aspect := size.x / maxf(size.y, 1.0)
	var source_aspect := texture_size.x / texture_size.y
	var source_rect := Rect2(Vector2.ZERO, texture_size)
	if source_aspect > target_aspect:
		var cropped_width := texture_size.y * target_aspect
		source_rect.position.x = (texture_size.x - cropped_width) * 0.5
		source_rect.size.x = cropped_width
	else:
		var cropped_height := texture_size.x / target_aspect
		source_rect.position.y = (texture_size.y - cropped_height) * 0.5
		source_rect.size.y = cropped_height
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, size), source_rect)
	draw_rect(Rect2(Vector2.ZERO, size), Color(accent, 0.48), false, 1.0)


func _draw_ink_backdrop() -> void:
	var breath := sin(motion_time * 1.2) * 3.0
	for i in 5:
		var a := float(i) / 5.0 * TAU + 0.4
		var p := Vector2.from_angle(a) * Vector2(116, 182) + Vector2(0, -232 + breath)
		draw_circle(p, 34.0 + i * 8.0, Color(0.01, 0.025, 0.024, 0.08))
	for i in 8:
		var x := -136.0 + i * 37.0
		draw_line(Vector2(x, -430), Vector2(x - 24, -55), Color(accent, 0.025 + (i % 3) * 0.012), 1.0)
	var ground := PackedVector2Array([Vector2(-138, -12), Vector2(-92, -24), Vector2(-24, -18), Vector2(36, -28), Vector2(130, -9)])
	for i in ground.size() - 1:
		draw_line(ground[i], ground[i + 1], Color(accent, 0.30), 2.0)


func _body_offsets() -> Dictionary:
	var breath := sin(motion_time * 1.55) * 2.2
	var speak := sin(minf(motion_time * 2.2, PI)) * 7.0 if pose == "speak" else 0.0
	var ready := 8.0 if pose == "ready" else 0.0
	return {"breath": breath, "hand": speak, "ready": ready}


func _draw_face(center: Vector2, skin: Color, hair: Color, stern := false) -> void:
	draw_circle(center, 29.0, skin)
	draw_polygon(PackedVector2Array([
		center + Vector2(-30, -4), center + Vector2(-24, -31), center + Vector2(0, -48),
		center + Vector2(28, -28), center + Vector2(31, 2), center + Vector2(19, -13), center + Vector2(-19, -13)
	]), PackedColorArray([hair]))
	var eye_y := center.y - 2.0
	draw_line(Vector2(center.x - 15, eye_y), Vector2(center.x - 5, eye_y + (2 if stern else 0)), Color("272b29"), 2.0)
	draw_line(Vector2(center.x + 5, eye_y + (2 if stern else 0)), Vector2(center.x + 15, eye_y), Color("272b29"), 2.0)
	draw_line(center + Vector2(-1, 1), center + Vector2(-3, 10), Color("9e7865"), 1.5)
	draw_line(center + Vector2(-7, 17), center + Vector2(7, 17 if stern else 18), Color("88564d"), 1.5)


func _draw_robe(base: Color, outer: Color, belt: Color, offsets: Dictionary, wide_sleeves := true) -> void:
	var b := float(offsets.breath)
	var h := float(offsets.hand)
	var r := float(offsets.ready)
	# Rear coat and long skirt create a readable period silhouette.
	draw_polygon(PackedVector2Array([
		Vector2(-48, -318 + b), Vector2(45, -318 + b), Vector2(78, -38),
		Vector2(28, -9), Vector2(0, -42), Vector2(-28, -9), Vector2(-82, -38)
	]), PackedColorArray([base]))
	draw_polygon(PackedVector2Array([
		Vector2(-43, -302 + b), Vector2(-6, -320 + b), Vector2(-14, -72), Vector2(-69, -32)
	]), PackedColorArray([outer]))
	if wide_sleeves:
		draw_polygon(PackedVector2Array([
			Vector2(-40, -294 + b), Vector2(-78, -273 + b), Vector2(-120, -176 + h),
			Vector2(-82, -154 + h), Vector2(-36, -240 + b)
		]), PackedColorArray([outer.darkened(0.04)]))
		draw_polygon(PackedVector2Array([
			Vector2(39, -291 + b), Vector2(75, -267 + b), Vector2(105 + r, -181 - h),
			Vector2(71 + r, -163 - h), Vector2(34, -239 + b)
		]), PackedColorArray([outer.lightened(0.03)]))
	else:
		draw_polygon(PackedVector2Array([Vector2(-40, -291 + b), Vector2(-70, -269 + b), Vector2(-70, -166), Vector2(-42, -169)]), PackedColorArray([outer]))
		draw_polygon(PackedVector2Array([Vector2(38, -291 + b), Vector2(65, -268 + b), Vector2(76 + r, -163), Vector2(45, -165)]), PackedColorArray([outer]))
	draw_rect(Rect2(-48, -238 + b, 96, 14), belt, true)
	draw_line(Vector2(-11, -224), Vector2(-16, -74), Color(belt, 0.50), 2.0)
	draw_line(Vector2(15, -224), Vector2(23, -72), Color(belt, 0.45), 2.0)
	draw_polygon(PackedVector2Array([Vector2(-24, -13), Vector2(-4, -6), Vector2(-1, 0), Vector2(-35, 0)]), PackedColorArray([Color("171b1a")]))
	draw_polygon(PackedVector2Array([Vector2(24, -13), Vector2(4, -6), Vector2(1, 0), Vector2(35, 0)]), PackedColorArray([Color("171b1a")]))


func _draw_keeper() -> void:
	var o := _body_offsets()
	_draw_robe(Color("d5c9aa"), Color("263b35"), Color("8e3f34"), o, false)
	var head := Vector2(0, -356 + float(o.breath))
	_draw_face(head, Color("d5b493"), Color("192321"), true)
	draw_circle(head + Vector2(0, -43), 13, Color("192321"))
	draw_line(Vector2(54, -261), Vector2(97, -80), Color("c8b07a"), 5.0)
	draw_line(Vector2(57, -258), Vector2(101, -74), Color("f0e1b9"), 1.5)
	draw_line(Vector2(44, -234), Vector2(69, -241), Color("7d352d"), 5.0)


func _draw_ayan() -> void:
	var o := _body_offsets()
	_draw_robe(Color("e1d5b9"), Color("9bb6a5"), Color("a74438"), o, true)
	var head := Vector2(0, -356 + float(o.breath))
	_draw_face(head, Color("dfbea1"), Color("1d2a27"))
	draw_circle(head + Vector2(-15, -45), 14, Color("1d2a27"))
	draw_circle(head + Vector2(15, -45), 14, Color("1d2a27"))
	draw_rect(Rect2(12, head.y - 59, 10, 15), Color("a33c33"), true)
	# Folded manuscript leaf in the speaking hand.
	draw_polygon(PackedVector2Array([Vector2(-119, -179 + float(o.hand)), Vector2(-91, -188 + float(o.hand)), Vector2(-84, -154 + float(o.hand)), Vector2(-112, -145 + float(o.hand))]), PackedColorArray([Color("e7ddc7")]))
	draw_line(Vector2(-107, -174 + float(o.hand)), Vector2(-91, -168 + float(o.hand)), Color("8e5544"), 1.5)


func _draw_shenjin() -> void:
	var o := _body_offsets()
	_draw_robe(Color("2a2725"), Color("67362f"), Color("b27a53"), o, false)
	var head := Vector2(0, -356 + float(o.breath))
	_draw_face(head, Color("cda887"), Color("151c1b"), true)
	draw_polygon(PackedVector2Array([head + Vector2(-35, -29), head + Vector2(4, -58), head + Vector2(28, -29), head + Vector2(-2, -19)]), PackedColorArray([Color("151c1b")]))
	draw_line(head + Vector2(13, 7), head + Vector2(24, 20), Color("8d4b43"), 2.2)
	draw_line(Vector2(-77, -283), Vector2(92, -65), Color("c9c1aa"), 4.0)
	draw_line(Vector2(-81, -278), Vector2(95, -60), Color("594438"), 7.0)
	draw_line(Vector2(-67, -267), Vector2(-45, -287), Color("b68152"), 5.0)


func _draw_qiaosheng() -> void:
	var o := _body_offsets()
	_draw_robe(Color("777e78"), Color("585f5c"), Color("8d6f4f"), o, true)
	var head := Vector2(0, -350 + float(o.breath))
	_draw_face(head, Color("d0b18f"), Color("c8c4b8"))
	draw_arc(head + Vector2(0, -4), 30, PI * 0.08, PI * 0.92, 18, Color("d4d0c3"), 5.0)
	draw_line(head + Vector2(-8, 22), head + Vector2(-17, 55), Color("d4d0c3"), 3.0)
	draw_line(head + Vector2(8, 22), head + Vector2(17, 55), Color("d4d0c3"), 3.0)
	draw_line(Vector2(74, -288), Vector2(95, -70), Color("473c32"), 8.0)
	for i in 3: draw_line(Vector2(68 + i * 7, -283), Vector2(83 + i * 7, -74), Color("b08a58"), 2.0)


func _draw_moyan() -> void:
	var o := _body_offsets()
	_draw_robe(Color("101514"), Color("202827"), Color("573b36"), o, false)
	var head := Vector2(0, -358 + float(o.breath))
	draw_circle(head, 29, Color("b4967f"))
	draw_polygon(PackedVector2Array([head + Vector2(-31, -18), head + Vector2(0, -45), head + Vector2(31, -18), head + Vector2(19, 9), head + Vector2(-20, 9)]), PackedColorArray([Color("38312d")]))
	draw_line(head + Vector2(-24, -8), head + Vector2(19, 4), Color(accent, 0.62), 2.0)
	draw_line(head + Vector2(-12, -26), head + Vector2(9, 7), Color(accent, 0.40), 2.0)
	draw_circle(head + Vector2(-10, -7), 2.5, Color("d0a379"))
	draw_circle(head + Vector2(10, -7), 2.5, Color("d0a379"))
	draw_polygon(PackedVector2Array([head + Vector2(-34, -20), head + Vector2(-16, -58), head + Vector2(4, -65), head + Vector2(35, -18)]), PackedColorArray([Color("101514")]))
	draw_line(Vector2(-80, -274), Vector2(102, -68), Color("8c8a7d"), 6.0)
	draw_line(Vector2(-75, -279), Vector2(108, -71), Color("d2c8a7"), 1.5)
