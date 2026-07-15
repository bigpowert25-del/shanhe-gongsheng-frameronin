extends Control

var progress := 0.0:
	set(value):
		progress = clamp(value, 0.0, 1.0)
		queue_redraw()

var blot_positions := [
	Vector2(0.08, 0.18), Vector2(0.30, 0.72), Vector2(0.54, 0.34),
	Vector2(0.79, 0.78), Vector2(0.94, 0.22), Vector2(0.62, 0.92),
	Vector2(0.18, 0.46), Vector2(0.44, 0.10), Vector2(0.84, 0.49)
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	if progress <= 0.001:
		return
	var ink := Color("080d0d")
	var max_dim: float = maxf(size.x, size.y)
	for i in blot_positions.size():
		var local_progress: float = clampf(progress * 1.42 - float(i % 4) * 0.075, 0.0, 1.0)
		var radius: float = max_dim * local_progress * (0.18 + float((i * 17) % 8) * 0.012)
		draw_circle(blot_positions[i] * size, radius, ink)
	if progress > 0.72:
		ink.a = smoothstep(0.72, 1.0, progress)
		draw_rect(Rect2(Vector2.ZERO, size), ink)
