extends Control

signal direction_changed(direction: Vector2)

var active_touch := -1
var mouse_dragging := false
var direction := Vector2.ZERO
var knob_offset := Vector2.ZERO
var base_radius := 70.0
var knob_radius := 29.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch < 0:
			active_touch = event.index
			_update_direction(event.position - get_global_rect().position)
			accept_event()
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			_reset_direction()
			accept_event()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_direction(event.position - get_global_rect().position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_dragging = event.pressed
		if mouse_dragging:
			_update_direction(get_local_mouse_position())
		else:
			_reset_direction()
		accept_event()
	elif event is InputEventMouseMotion and mouse_dragging:
		_update_direction(get_local_mouse_position())
		accept_event()


func _update_direction(local_position: Vector2) -> void:
	var center := size * 0.5
	var raw := local_position - center
	var strength := minf(raw.length() / base_radius, 1.0)
	direction = raw.normalized() * strength if raw.length_squared() > 1.0 else Vector2.ZERO
	if direction.length() < 0.12:
		direction = Vector2.ZERO
	knob_offset = direction * base_radius
	direction_changed.emit(direction)
	queue_redraw()


func _reset_direction() -> void:
	direction = Vector2.ZERO
	knob_offset = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius + 12.0, Color(0.01, 0.025, 0.024, 0.46))
	draw_circle(center, base_radius, Color(0.07, 0.13, 0.12, 0.58))
	draw_arc(center, base_radius, 0.0, TAU, 64, Color(0.66, 0.82, 0.74, 0.52), 2.0)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var inner := center + Vector2.from_angle(angle) * (base_radius - 15.0)
		var outer := center + Vector2.from_angle(angle) * (base_radius - 7.0)
		draw_line(inner, outer, Color(0.76, 0.84, 0.77, 0.42), 2.0)
	var knob_center := center + knob_offset
	draw_circle(knob_center, knob_radius + 5.0, Color(0.01, 0.02, 0.02, 0.56))
	draw_circle(knob_center, knob_radius, Color(0.67, 0.82, 0.73, 0.82))
	draw_arc(knob_center, knob_radius, 0.0, TAU, 40, Color(0.92, 0.88, 0.70, 0.78), 2.0)
