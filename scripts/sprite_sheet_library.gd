extends RefCounted

const CATALOG_PATH := "res://assets/generated/actors.json"

var frame_size := Vector2i(192, 288)
var grid := Vector2i(4, 4)
var animations: Dictionary = {}
var actors: Dictionary = {}
var textures: Dictionary = {}
var catalog_valid := false


func _init() -> void:
	reload()


func reload() -> bool:
	catalog_valid = false
	animations.clear()
	actors.clear()
	textures.clear()
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("动作素材目录不存在，请先运行“更新动作素材”")
		return false
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("动作素材目录格式无效")
		return false
	var data: Dictionary = parsed
	var raw_size: Array = data.get("frame_size", [192, 288])
	var raw_grid: Array = data.get("grid", [4, 4])
	if raw_size.size() != 2 or raw_grid.size() != 2:
		return false
	frame_size = Vector2i(int(raw_size[0]), int(raw_size[1]))
	grid = Vector2i(int(raw_grid[0]), int(raw_grid[1]))
	animations = data.get("animations", {})
	actors = data.get("actors", {})
	catalog_valid = frame_size.x > 0 and frame_size.y > 0 and not actors.is_empty()
	return catalog_valid


func actor_count() -> int:
	return actors.size()


func has_actor(actor_id: String) -> bool:
	return actors.has(actor_id)


func provider_for(actor_id: String) -> String:
	if not actors.has(actor_id):
		return "missing"
	return str(Dictionary(actors[actor_id]).get("provider", "unknown"))


func frame_for(actor_id: String, animation_name: String, animation_time: float) -> Dictionary:
	if not catalog_valid or not actors.has(actor_id):
		return {}
	var actor: Dictionary = actors[actor_id]
	var path := str(actor.get("texture", ""))
	if path.is_empty():
		return {}
	var texture: Texture2D = textures.get(path)
	if texture == null:
		texture = load(path) as Texture2D
		if texture == null:
			return {}
		textures[path] = texture
	var animation: Dictionary = animations.get(animation_name, animations.get("idle", {}))
	if animation.is_empty():
		return {}
	var fps := maxf(0.01, float(animation.get("fps", 6.0)))
	var raw_frame := maxi(0, int(floor(animation_time * fps)))
	var column := raw_frame % grid.x if bool(animation.get("loop", true)) else mini(raw_frame, grid.x - 1)
	var row := clampi(int(animation.get("row", 0)), 0, grid.y - 1)
	return {
		"texture": texture,
		"region": Rect2(column * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y),
		"provider": actor.get("provider", "unknown")
	}
