extends Control

const RIFT_WALKER_TEXTURE := preload("res://assets/enemies/rift_walker.png")
const BOSS_01_TEXTURE := preload("res://assets/enemies/boss_01.png")
const BOSS_02_TEXTURE := preload("res://assets/enemies/boss_02.png")
const BOSS_03_TEXTURE := preload("res://assets/enemies/boss_03.png")
const BOSS_04_TEXTURE := preload("res://assets/enemies/boss_04.png")
const BOSS_05_TEXTURE := preload("res://assets/enemies/boss_05.png")
const BOSS_06_TEXTURE := preload("res://assets/enemies/boss_06.png")
const PLAYER_TEXTURE := preload("res://assets/characters/you_sprite.png")
const AYAN_SPRITE := preload("res://assets/characters/ayan_sprite.png")
const SHENJIN_SPRITE := preload("res://assets/characters/shenjin_sprite.png")
const QIAOSHENG_SPRITE := preload("res://assets/characters/qiaosheng_sprite.png")

signal hud_changed(data: Dictionary)
signal toast(message: String)
signal npc_requested(data: Dictionary)
signal lore_requested(data: Dictionary)
signal chapter_completed(report: Dictionary)
signal chapter_failed(reason: String)
signal shake_requested(strength: float)

const TOP := 66.0
const BOTTOM := 704.0
const LEFT := 24.0
const RIGHT := 1256.0

var chapter: Dictionary = {}
var chapter_index := 0
var trait_ids: Array[String] = []
var legacy_stats: Dictionary = {}
var effects: Dictionary = {}
var player_pos := Vector2(160, 560)
var aim_pos := Vector2(500, 360)
var move_dir := Vector2.RIGHT
var dash_velocity := Vector2.ZERO
var trail: Array[Vector2] = []
var health := 100.0
var max_health := 100.0
var energy := 100.0
var max_energy := 100.0
var time_left := 95.0
var elapsed := 0.0
var fragments_found := 0
var nodes_restored := 0
var enemies_defeated := 0
var lore_found := 0
var npc_talked := false
var boss_spawned := false
var boss_defeated := false
var portal_open := false
var finished := false
var paused_game := false
var attack_cooldown := 0.0
var attack_anim := 0.0
var hurt_anim := 0.0
var step_phase := 0.0
var movement_strength := 0.0
var dash_cooldown := 0.0
var dash_time := 0.0
var burst_cooldown := 0.0
var reveal_time := 0.0
var damage_cooldown := 0.0
var message_cooldown := 0.0
var fragments: Array[Dictionary] = []
var nodes: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var lore_points: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	rng.seed = 20260714
	set_process(false)


func start_chapter(data: Dictionary, traits: Array[String], stats: Dictionary, index: int) -> void:
	chapter = data
	chapter_index = index
	trait_ids = traits.duplicate()
	legacy_stats = stats.duplicate(true)
	_calculate_effects()
	health = max_health
	energy = max_energy
	time_left = 88.0 + float(stats.get("fate", 45)) * 0.16
	player_pos = Vector2(150, 570)
	aim_pos = player_pos + Vector2.RIGHT * 180.0
	_build_world()
	set_process(true)
	grab_focus()
	_emit_hud()
	toast.emit("任务开始 · 先寻找画中人物，再完成修复与讨伐")
	queue_redraw()


func _calculate_effects() -> void:
	effects = {
		"speed": 205.0, "attack": 26.0, "range": 96.0, "armor": 0.0,
		"crit": 0.08, "lifesteal": 0.0, "repair": 1.0,
		"dash_cd": 2.6, "pulse_cost": 35.0, "max_health": 100.0, "max_energy": 100.0
	}
	for id in trait_ids:
		match id:
			"tiger":
				effects.attack += 11.0
				effects.dash_cd -= 0.75
			"eagle":
				effects.range += 34.0
				effects.crit += 0.20
			"bear":
				effects.armor += 0.36
				effects.max_health += 34.0
			"wolf":
				effects.lifesteal += 0.16
				effects.speed += 16.0
			"chimp":
				effects.repair += 0.72
				effects.pulse_cost -= 9.0
			"horse":
				effects.speed += 48.0
				effects.max_energy += 32.0
	effects.attack += maxf(0.0, float(legacy_stats.get("ink", 45)) - 45.0) * 0.14
	effects.max_health += maxf(0.0, float(legacy_stats.get("heart", 45)) - 45.0) * 0.38
	max_health = float(effects.max_health)
	max_energy = float(effects.max_energy)


func _build_world() -> void:
	fragments_found = 0
	nodes_restored = 0
	enemies_defeated = 0
	lore_found = 0
	npc_talked = false
	boss_spawned = false
	boss_defeated = false
	portal_open = false
	finished = false
	var layouts := [
		[Vector2(236, 246), Vector2(650, 518), Vector2(1080, 300)],
		[Vector2(302, 540), Vector2(702, 226), Vector2(1120, 554)],
		[Vector2(250, 320), Vector2(750, 570), Vector2(1038, 230)]
	]
	fragments.clear()
	for p in layouts[chapter_index % layouts.size()]:
		fragments.append({"pos": p, "active": true, "phase": rng.randf_range(0.0, TAU)})
	nodes = [
		{"pos": Vector2(386 + (chapter_index % 2) * 70, 590), "progress": 0.0, "done": false},
		{"pos": Vector2(922 - (chapter_index % 2) * 82, 224), "progress": 0.0, "done": false}
	]
	lore_points.clear()
	var lore_positions := [Vector2(560, 182), Vector2(820, 590)]
	var lore_data: Array = chapter.get("lore", [])
	for i in mini(2, lore_data.size()):
		var entry: Dictionary = lore_data[i].duplicate(true)
		entry["pos"] = lore_positions[(i + chapter_index) % 2]
		entry["found"] = false
		lore_points.append(entry)
	hazards = [
		{"pos": Vector2(510, 342), "radius": 67.0 + chapter_index * 3.0},
		{"pos": Vector2(872, 506), "radius": 60.0 + chapter_index * 4.0}
	]
	enemies.clear()
	var enemy_positions := [Vector2(360, 250), Vector2(700, 430), Vector2(1010, 360), Vector2(1130, 600)]
	for i in enemy_positions.size():
		_add_enemy(enemy_positions[i], false, i)
	trail.clear()
	particles.clear()


func _add_enemy(pos: Vector2, boss: bool, seed_offset: int) -> void:
	var scale := 1.0 + float(chapter_index) * 0.13
	var hp := (250.0 + chapter_index * 42.0) if boss else (62.0 + chapter_index * 10.0)
	enemies.append({
		"pos": pos, "hp": hp, "max_hp": hp, "speed": (74.0 + chapter_index * 5.0) * (0.76 if boss else 1.0),
		"damage": (17.0 + chapter_index * 2.0) * scale, "radius": 31.0 if boss else 18.0,
		"boss": boss, "alive": true, "attack_cd": rng.randf_range(0.2, 0.9),
		"phase": float(seed_offset) * 1.71, "flash": 0.0
	})


func _process(delta: float) -> void:
	if paused_game or finished:
		return
	elapsed += delta
	time_left = maxf(0.0, time_left - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_anim = maxf(0.0, attack_anim - delta)
	hurt_anim = maxf(0.0, hurt_anim - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_time = maxf(0.0, dash_time - delta)
	burst_cooldown = maxf(0.0, burst_cooldown - delta)
	reveal_time = maxf(0.0, reveal_time - delta)
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	message_cooldown = maxf(0.0, message_cooldown - delta)
	energy = minf(max_energy, energy + (6.2 if trait_ids.has("horse") else 4.5) * delta)
	_handle_actions()
	_update_movement(delta)
	_update_collectibles()
	_update_nodes(delta)
	_update_enemies(delta)
	_update_particles(delta)
	_check_boss_and_portal()
	_emit_hud()
	queue_redraw()
	if health <= 0.0:
		_fail("画灵被裂墨击溃")
	elif time_left <= 0.0:
		_fail("卷页在时限内彻底褪色")


func _handle_actions() -> void:
	if Input.is_key_pressed(KEY_E):
		if not _try_npc(): _try_lore()
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J):
		basic_attack()
	if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_K):
		dash()
	if Input.is_key_pressed(KEY_Q):
		burst()


func _update_movement(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if direction.length_squared() > 0.0:
		move_dir = direction.normalized()
		step_phase += delta * (12.0 if dash_time <= 0.0 else 24.0)
		movement_strength = move_toward(movement_strength, 1.0, delta * 7.0)
	else:
		movement_strength = move_toward(movement_strength, 0.0, delta * 5.0)
	if dash_time > 0.0:
		player_pos += dash_velocity * delta
	elif attack_anim > 0.20:
		player_pos += move_dir * 150.0 * delta
	else:
		player_pos += direction.normalized() * float(effects.speed) * delta
	if chapter_index == 2:
		player_pos += Vector2(-13.0, 4.0) * delta
	player_pos.x = clampf(player_pos.x, LEFT + 22.0, RIGHT - 22.0)
	player_pos.y = clampf(player_pos.y, TOP + 26.0, BOTTOM - 24.0)
	if trail.is_empty() or trail.back().distance_to(player_pos) > 8.0:
		trail.append(player_pos)
		if trail.size() > 16: trail.pop_front()


func _update_collectibles() -> void:
	for item in fragments:
		if bool(item.active) and player_pos.distance_to(item.pos) < 28.0:
			item.active = false
			fragments_found += 1
			energy = minf(max_energy, energy + 16.0)
			_spawn_particles(item.pos, chapter.accent, 16)
			toast.emit("获得记忆残片 · %d / 3" % fragments_found)


func _update_nodes(delta: float) -> void:
	for node in nodes:
		if bool(node.done):
			continue
		if player_pos.distance_to(node.pos) < 48.0 and Input.is_key_pressed(KEY_E):
			node.progress = minf(1.0, float(node.progress) + delta * 0.66 * float(effects.repair))
			if float(node.progress) >= 1.0:
				node.done = true
				nodes_restored += 1
				health = minf(max_health, health + 18.0)
				_spawn_particles(node.pos, Color("e3c579"), 24)
				toast.emit("阵眼修复完成 · %d / 2" % nodes_restored)


func _update_enemies(delta: float) -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if not bool(enemy.alive):
			continue
		enemy.attack_cd = maxf(0.0, float(enemy.attack_cd) - delta)
		enemy.flash = maxf(0.0, float(enemy.flash) - delta)
		enemy.phase = float(enemy.phase) + delta
		var enemy_pos: Vector2 = enemy.pos
		var to_player := player_pos - enemy_pos
		var aggro := 620.0 if bool(enemy.boss) else 430.0
		if to_player.length() < aggro:
			enemy_pos += to_player.normalized() * float(enemy.speed) * delta
		else:
			enemy_pos += Vector2(cos(float(enemy.phase)), sin(float(enemy.phase) * 1.3)) * 16.0 * delta
		enemy.pos = enemy_pos
		var contact := float(enemy.radius) + 18.0
		if to_player.length() < contact and float(enemy.attack_cd) <= 0.0 and dash_time <= 0.0:
			enemy.attack_cd = 0.72 if bool(enemy.boss) else 1.05
			_take_damage(float(enemy.damage), to_player.normalized())
		enemies[i] = enemy
	for hazard in hazards:
		if player_pos.distance_to(hazard.pos) < float(hazard.radius) and dash_time <= 0.0:
			var multiplier := 1.65 if chapter_index == 4 else 1.0
			_take_damage(7.0 * multiplier * delta, Vector2.ZERO, false)


func basic_attack() -> void:
	if attack_cooldown > 0.0 or paused_game or finished:
		return
	attack_cooldown = 0.34 if trait_ids.has("tiger") else 0.46
	attack_anim = 0.36
	var direction := (aim_pos - player_pos).normalized()
	if direction.length_squared() < 0.1: direction = move_dir
	move_dir = direction
	player_pos += direction * 8.0
	var hit_any := false
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if not bool(enemy.alive): continue
		var offset: Vector2 = enemy.pos - player_pos
		if offset.length() <= float(effects.range) + float(enemy.radius) and direction.dot(offset.normalized()) > 0.18:
			var critical := rng.randf() < float(effects.crit)
			var damage := float(effects.attack) * (1.75 if critical else 1.0)
			_damage_enemy(i, damage, critical)
			hit_any = true
	if hit_any:
		energy = minf(max_energy, energy + 3.0)
	else:
		_spawn_particles(player_pos + direction * 58.0, Color(chapter.accent, 0.5), 4)


func dash() -> void:
	if dash_cooldown > 0.0 or energy < 8.0 or paused_game or finished:
		return
	dash_cooldown = float(effects.dash_cd)
	dash_time = 0.23
	energy -= 8.0
	var direction := move_dir
	if direction.length_squared() < 0.1: direction = (aim_pos - player_pos).normalized()
	dash_velocity = direction * (790.0 if trait_ids.has("tiger") else 660.0)
	_spawn_particles(player_pos, Color("d8bf82"), 10)


func burst() -> void:
	var cost := float(effects.pulse_cost)
	if burst_cooldown > 0.0 or energy < cost or paused_game or finished:
		return
	burst_cooldown = 7.0
	reveal_time = 4.0
	energy -= cost
	var pulse_damage := float(effects.attack) * 1.75 + float(legacy_stats.get("ink", 45)) * 0.20
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if bool(enemy.alive) and player_pos.distance_to(enemy.pos) < 218.0:
			_damage_enemy(i, pulse_damage, false)
	_spawn_particles(player_pos, Color("e5c978"), 42)
	shake_requested.emit(6.0)
	toast.emit("画灵共鸣 · 裂墨显形")


func interact_action() -> void:
	if _try_npc():
		return
	if _try_lore():
		return
	for node in nodes:
		if not bool(node.done) and player_pos.distance_to(node.pos) < 52.0:
			node.progress = minf(1.0, float(node.progress) + 0.28 * float(effects.repair))


func _try_npc() -> bool:
	if npc_talked or chapter.is_empty():
		return false
	var npc: Dictionary = chapter.npc
	if player_pos.distance_to(npc.pos) < 66.0:
		npc_talked = true
		npc_requested.emit(npc)
		return true
	return false


func _try_lore() -> bool:
	for lore in lore_points:
		if not bool(lore.found) and player_pos.distance_to(lore.pos) < 54.0:
			lore.found = true
			lore_found += 1
			lore_requested.emit(lore)
			return true
	return false


func _damage_enemy(index: int, damage: float, critical: bool) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	if not bool(enemy.alive): return
	enemy.hp = float(enemy.hp) - damage
	enemy.flash = 0.12
	_spawn_particles(enemy.pos, Color("d85d4b") if critical else Color("d4b26d"), 7 if critical else 4)
	var heal := damage * float(effects.lifesteal)
	if heal > 0.0: health = minf(max_health, health + heal)
	if float(enemy.hp) <= 0.0:
		enemy.alive = false
		if bool(enemy.boss):
			boss_defeated = true
			toast.emit("首领已击败 · 画境出口正在开启")
			_spawn_particles(enemy.pos, Color("f0d28a"), 38)
		else:
			enemies_defeated += 1
			energy = minf(max_energy, energy + 12.0)
			toast.emit("裂墨清除 · %d / 3" % mini(enemies_defeated, 3))
	enemies[index] = enemy


func _take_damage(raw_damage: float, direction: Vector2, respect_cooldown := true) -> void:
	if respect_cooldown and damage_cooldown > 0.0:
		return
	if respect_cooldown: damage_cooldown = 0.38
	var damage := raw_damage * (1.0 - float(effects.armor))
	health = maxf(0.0, health - damage)
	hurt_anim = 0.28
	if direction.length_squared() > 0.0:
		player_pos += direction.normalized() * 22.0
	_spawn_particles(player_pos, Color("d65a4b"), 8)
	shake_requested.emit(4.0 if respect_cooldown else 1.0)


func _check_boss_and_portal() -> void:
	if not boss_spawned and npc_talked and fragments_found >= 3 and nodes_restored >= 2 and enemies_defeated >= 3:
		boss_spawned = true
		_add_enemy(Vector2(690, 330), true, 99)
		toast.emit("首领降临 · %s" % chapter.boss)
		shake_requested.emit(8.0)
	if boss_spawned and boss_defeated and not portal_open:
		portal_open = true
		toast.emit("任务完成 · 进入中央画门")
	if portal_open and player_pos.distance_to(Vector2(640, 366)) < 48.0:
		_finish()


func _finish() -> void:
	if finished: return
	finished = true
	set_process(false)
	chapter_completed.emit({
		"time": elapsed, "health": health, "kills": enemies_defeated + 1,
		"fragments": fragments_found, "nodes": nodes_restored, "lore": lore_found
	})


func _fail(reason: String) -> void:
	if finished: return
	finished = true
	set_process(false)
	chapter_failed.emit(reason)


func pause_game(value: bool) -> void:
	paused_game = value


func _emit_hud() -> void:
	hud_changed.emit({
		"health": health, "max_health": max_health, "energy": energy, "max_energy": max_energy,
		"time": time_left, "fragments": fragments_found, "nodes": nodes_restored,
		"kills": mini(enemies_defeated, 3), "npc": npc_talked, "boss": boss_defeated,
		"lore": lore_found,
		"boss_spawned": boss_spawned, "dash_cd": dash_cooldown, "burst_cd": burst_cooldown
	})


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_pos = event.position
	elif event is InputEventMouseButton and event.pressed:
		aim_pos = event.position
		if event.button_index == MOUSE_BUTTON_LEFT: basic_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT: dash()


func _spawn_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in count:
		particles.append({
			"pos": pos, "vel": Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(38.0, 170.0),
			"life": rng.randf_range(0.32, 0.82), "max_life": 0.82, "color": color,
			"size": rng.randf_range(1.5, 4.5)
		})


func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.life = float(p.life) - delta
		if float(p.life) <= 0.0:
			particles.remove_at(i)
			continue
		p.pos = Vector2(p.pos) + Vector2(p.vel) * delta
		p.vel = Vector2(p.vel) * 0.92
		particles[i] = p


func force_complete_for_test() -> void:
	fragments_found = 3
	nodes_restored = 2
	enemies_defeated = 3
	npc_talked = true
	boss_spawned = true
	boss_defeated = true
	portal_open = true
	_finish()


func _draw() -> void:
	# Polluted ink pools.
	for hazard in hazards:
		var hc := Color("301b1a")
		hc.a = 0.25 + sin(elapsed * 2.0 + float(hazard.radius)) * 0.04
		draw_circle(hazard.pos, float(hazard.radius), hc)
		draw_arc(hazard.pos, float(hazard.radius), 0.0, TAU, 48, Color(0.76, 0.27, 0.20, 0.42), 2.0)
		draw_arc(hazard.pos, float(hazard.radius) * 0.72, elapsed, elapsed + PI * 1.4, 32, Color(0.12, 0.05, 0.04, 0.64), 4.0)
	# Restoration nodes.
	for node in nodes:
		var node_color := Color("e1c779") if bool(node.done) else Color("8bc8bd")
		draw_circle(node.pos, 28.0, Color(0.02, 0.05, 0.05, 0.72))
		draw_arc(node.pos, 26.0, 0.0, TAU, 32, Color(node_color, 0.7), 2.0)
		draw_arc(node.pos, 21.0, -PI / 2.0, -PI / 2.0 + TAU * float(node.progress), 32, node_color, 5.0)
		for k in 4:
			draw_line(node.pos + Vector2.from_angle(k * PI / 2.0) * 10.0, node.pos + Vector2.from_angle(k * PI / 2.0) * 17.0, node_color, 2.0)
	# Fragments.
	for item in fragments:
		if not bool(item.active): continue
		var distance := player_pos.distance_to(item.pos)
		var visible_strength := 1.0 if (reveal_time > 0.0 or trait_ids.has("eagle") or distance < 210.0) else 0.38
		var fp: Vector2 = item.pos
		var bob := sin(elapsed * 3.0 + float(item.phase)) * 5.0
		var diamond := PackedVector2Array([fp + Vector2(0, -13 + bob), fp + Vector2(10, bob), fp + Vector2(0, 13 + bob), fp + Vector2(-10, bob)])
		draw_polygon(diamond, PackedColorArray([Color(0.42, 0.82, 0.91, visible_strength)]))
		draw_arc(fp + Vector2(0, bob), 21.0 + sin(elapsed * 2.0) * 3.0, 0.0, TAU, 24, Color(0.55, 0.89, 0.94, visible_strength * 0.5), 2.0)
	# NPC.
	if not npc_talked and not chapter.is_empty():
		var npc: Dictionary = chapter.npc
		_draw_world_npc(npc)
	# Optional human stories.
	for lore in lore_points:
		if bool(lore.found): continue
		var lp: Vector2 = lore.pos
		draw_circle(lp, 18.0 + sin(elapsed * 2.2) * 2.0, Color(0.88, 0.76, 0.46, 0.16))
		draw_rect(Rect2(lp + Vector2(-10, -13), Vector2(20, 26)), Color("d8c69d"), true)
		draw_line(lp + Vector2(-6, -6), lp + Vector2(6, -6), Color("7e6048"), 2.0)
		draw_line(lp + Vector2(-6, 0), lp + Vector2(4, 0), Color("7e6048"), 2.0)
		draw_line(lp + Vector2(-6, 6), lp + Vector2(7, 6), Color("7e6048"), 2.0)
	# Enemies and boss.
	for enemy in enemies:
		if not bool(enemy.alive): continue
		_draw_ink_enemy(enemy)
	# Portal.
	if portal_open:
		var portal := Vector2(640, 366)
		for r in [46.0, 34.0, 22.0]:
			draw_arc(portal, r + sin(elapsed * 2.5 + r) * 3.0, elapsed * 0.5, elapsed * 0.5 + TAU * 0.82, 48, Color(0.92, 0.78, 0.46, 0.72), 3.0)
		draw_circle(portal, 13.0, Color(0.94, 0.84, 0.60, 0.72))
	# Trait tracking arrow.
	if trait_ids.has("wolf"):
		var target := _nearest_objective()
		if target != Vector2.ZERO:
			var dir := (target - player_pos).normalized()
			draw_line(player_pos + dir * 27.0, player_pos + dir * 49.0, Color(0.88, 0.74, 0.39, 0.82), 3.0)
			draw_circle(player_pos + dir * 52.0, 3.0, Color("e4c56e"))
	# Player ink trail and articulated wuxia figure.
	for i in trail.size():
		var alpha := float(i + 1) / float(maxi(trail.size(), 1)) * (0.28 if dash_time > 0.0 else 0.11)
		draw_circle(trail[i], 3.0 + float(i) * 0.28, Color(0.08, 0.12, 0.11, alpha))
	_draw_player_actor()
	# Particles.
	for particle in particles:
		var pc: Color = particle.color
		pc.a = clampf(float(particle.life) / float(particle.max_life), 0.0, 1.0)
		draw_circle(particle.pos, float(particle.size), pc)


func _draw_world_npc(npc: Dictionary) -> void:
	var p: Vector2 = npc.pos
	var c: Color = npc.color
	var sway := sin(elapsed * 1.35) * 1.8
	var texture := _npc_texture(str(npc.id))
	var height := 112.0
	var width := height * texture.get_width() / texture.get_height()
	var foot := p + Vector2(0, sway)
	draw_ellipse_shadow(foot, width * 0.38, 6.0, Color(0.01, 0.02, 0.02, 0.42))
	draw_circle(foot + Vector2(0, -48), 34.0 + sin(elapsed * 1.8) * 2.0, Color(c, 0.08))
	draw_texture_rect(texture, Rect2(foot - Vector2(width * 0.5, height), Vector2(width, height)), false)
	draw_circle(foot + Vector2(width * 0.38, -height + 12), 10.0, Color("a33931"))
	draw_string(ThemeDB.fallback_font, foot + Vector2(width * 0.38 - 3, -height + 17), "!", HORIZONTAL_ALIGNMENT_CENTER, 8.0, 15, Color.WHITE)


func _npc_texture(id: String) -> Texture2D:
	match id:
		"ayan": return AYAN_SPRITE
		"shenjin": return SHENJIN_SPRITE
		"qiaosheng": return QIAOSHENG_SPRITE
		_: return BOSS_06_TEXTURE


func _draw_player_actor() -> void:
	var facing := -1.0 if move_dir.x < -0.08 else 1.0
	var bob: float = absf(sin(step_phase)) * 2.8 * movement_strength
	var height := 98.0
	var width := height * PLAYER_TEXTURE.get_width() / PLAYER_TEXTURE.get_height()
	if dash_time > 0.0:
		for k in 3:
			var ghost_pos := player_pos - move_dir * float(16 + k * 15)
			draw_circle(ghost_pos + Vector2(0, -32), 19.0, Color(0.70, 0.82, 0.73, 0.08 - k * 0.018))
	draw_ellipse_shadow(player_pos + Vector2(0, 4), width * 0.40, 6.0, Color(0.01, 0.02, 0.02, 0.46))
	var lunge := 0.0
	var lean := 0.0
	var progress := 0.0
	if attack_anim > 0.0:
		progress = 1.0 - attack_anim / 0.36
		if progress < 0.26:
			lean = -0.07
		elif progress < 0.68:
			lean = 0.11
			lunge = 10.0
		else:
			lean = 0.025
			lunge = 4.0
	var actor_pos := player_pos + move_dir * lunge + Vector2(0, -bob)
	draw_set_transform(actor_pos, lean * facing, Vector2(facing, 1.0))
	var tint := Color(1.0, 0.60, 0.56, 1.0) if hurt_anim > 0.0 and int(hurt_anim * 40.0) % 2 == 0 else Color.WHITE
	draw_texture_rect(PLAYER_TEXTURE, Rect2(Vector2(-width * 0.5, -height + 5.0), Vector2(width, height)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if attack_anim > 0.0:
		var base_angle := move_dir.angle()
		draw_arc(player_pos + move_dir * 15.0, float(effects.range) * 0.70, base_angle - 1.05, base_angle + 0.42, 22, Color(0.96, 0.84, 0.58, sin(progress * PI) * 0.72), 4.0)


func _draw_ink_enemy(enemy: Dictionary) -> void:
	var p: Vector2 = enemy.pos
	var boss := bool(enemy.boss)
	var pulse := sin(float(enemy.phase) * 3.0)
	var flash := float(enemy.flash) > 0.0
	var texture: Texture2D = _boss_texture() if boss else RIFT_WALKER_TEXTURE
	var height := 160.0 if boss else 108.0
	var width := height * texture.get_width() / texture.get_height()
	var foot := p + Vector2(0, 13.0 if boss else 7.0)
	var rect := Rect2(foot - Vector2(width * 0.5, height), Vector2(width, height))
	draw_ellipse_shadow(foot, width * 0.42, 6.5 if boss else 4.5, Color(0.01, 0.01, 0.01, 0.52))
	var aura := Color("7d2520") if boss else Color("1a201e")
	draw_circle(p + Vector2(0, -22), (42.0 if boss else 25.0) + pulse * 2.0, Color(aura, 0.12))
	var tint := Color(1.0, 0.64, 0.52, 1.0) if flash else Color.WHITE
	draw_texture_rect(texture, rect, false, tint)
	# A short brush arc makes the photographic sprite participate in combat motion.
	if float(enemy.attack_cd) < 0.24:
		draw_arc(p + Vector2(0, -20), 42.0 if boss else 28.0, -0.9, 0.65, 20, Color(0.72, 0.22, 0.17, 0.58), 3.0)
	if boss:
		for k in 5:
			var a := float(k) / 5.0 * TAU + float(enemy.phase) * 0.4
			draw_line(p + Vector2.from_angle(a) * 19.0, p + Vector2.from_angle(a + 0.2) * 48.0, Color(0.55, 0.12, 0.10, 0.42), 3.0)
	var er := float(enemy.radius)
	var ratio := clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
	var bar_y := rect.position.y - 9.0
	draw_rect(Rect2(Vector2(p.x - er, bar_y), Vector2(er * 2.0, 4)), Color(0.03, 0.04, 0.04, 0.82))
	draw_rect(Rect2(Vector2(p.x - er, bar_y), Vector2(er * 2.0 * ratio, 4)), Color("d6664f") if boss else Color("d6ad67"))


func _boss_texture() -> Texture2D:
	match chapter_index:
		0: return BOSS_01_TEXTURE
		1: return BOSS_02_TEXTURE
		2: return BOSS_03_TEXTURE
		3: return BOSS_04_TEXTURE
		4: return BOSS_05_TEXTURE
		_: return BOSS_06_TEXTURE


func draw_ellipse_shadow(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := float(i) / 24.0 * TAU
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_polygon(points, PackedColorArray([color]))


func _nearest_objective() -> Vector2:
	if not npc_talked and not chapter.is_empty(): return chapter.npc.pos
	for item in fragments:
		if bool(item.active): return item.pos
	for node in nodes:
		if not bool(node.done): return node.pos
	if boss_spawned and not boss_defeated:
		for enemy in enemies:
			if bool(enemy.alive) and bool(enemy.boss): return enemy.pos
	if portal_open: return Vector2(640, 366)
	return Vector2.ZERO
