extends Control

var mode := "dust"
var tint := Color("d5b66f")
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 20260714
	_reset_particles()


func configure(new_mode: String, new_tint: Color) -> void:
	mode = new_mode
	tint = new_tint
	_reset_particles()


func _reset_particles() -> void:
	particles.clear()
	var count := 72
	if mode == "rain":
		count = 105
	elif mode == "mist":
		count = 28
	elif mode == "fireflies":
		count = 48
	elif mode == "leaves":
		count = 58
	elif mode == "petals":
		count = 64
	var area := size
	if area.x < 10.0:
		area = Vector2(1280, 720)
	for i in count:
		particles.append({
			"pos": Vector2(rng.randf_range(0.0, area.x), rng.randf_range(0.0, area.y)),
			"speed": rng.randf_range(0.3, 1.2),
			"phase": rng.randf_range(0.0, TAU),
			"size": rng.randf_range(1.0, 3.8),
			"alpha": rng.randf_range(0.22, 0.78)
		})
	queue_redraw()


func _process(delta: float) -> void:
	var area := size
	if area.x < 10.0:
		return
	for i in particles.size():
		var p := particles[i]
		p.phase += delta * p.speed
		match mode:
			"rain": p.pos += Vector2(-70.0, 250.0) * delta * p.speed
			"mist": p.pos += Vector2(13.0 + sin(p.phase) * 5.0, -1.5) * delta * p.speed
			"fireflies": p.pos += Vector2(sin(p.phase * 1.7) * 12.0, -8.0 + cos(p.phase) * 5.0) * delta * p.speed
			"leaves": p.pos += Vector2(-24.0 + sin(p.phase) * 18.0, 42.0) * delta * p.speed
			"petals": p.pos += Vector2(-12.0 + sin(p.phase * 1.4) * 26.0, 27.0) * delta * p.speed
			_: p.pos += Vector2(sin(p.phase) * 4.0, -10.0) * delta * p.speed
		if p.pos.y > area.y + 30.0:
			p.pos.y = -20.0
			p.pos.x = rng.randf_range(0.0, area.x)
		if p.pos.y < -40.0: p.pos.y = area.y + 20.0
		if p.pos.x < -60.0: p.pos.x = area.x + 30.0
		if p.pos.x > area.x + 60.0: p.pos.x = -30.0
		particles[i] = p
	queue_redraw()


func _draw() -> void:
	for p in particles:
		var c := tint
		var pulse: float = 0.74 + sin(p.phase * 2.0) * 0.22
		c.a = p.alpha * pulse
		match mode:
			"rain": draw_line(p.pos, p.pos + Vector2(-7.0, 24.0) * p.size, c, 1.0)
			"mist":
				c.a *= 0.16
				draw_circle(p.pos, 32.0 * p.size, c)
			"fireflies":
				draw_circle(p.pos, 2.4 * p.size, c)
				c.a *= 0.18
				draw_circle(p.pos, 7.5 * p.size, c)
			"leaves":
				draw_set_transform(p.pos, p.phase, Vector2.ONE)
				draw_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -2.4), Vector2(5, 0), Vector2(0, 2.4)]), PackedColorArray([c]))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"petals":
				draw_set_transform(p.pos, sin(p.phase) * 0.8, Vector2.ONE)
				draw_circle(Vector2.ZERO, 2.0 * p.size, c)
				draw_line(Vector2.ZERO, Vector2(4.0 * p.size, 0), c, 2.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_: draw_circle(p.pos, p.size, c)

