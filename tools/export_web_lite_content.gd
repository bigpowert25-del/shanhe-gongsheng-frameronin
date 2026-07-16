extends SceneTree

const GameContent := preload("res://scripts/game_content.gd")


func _init() -> void:
	var output := {
		"traits": _clean(GameContent.traits()),
		"chapters": _clean(GameContent.chapters())
	}
	var directory := ProjectSettings.globalize_path("res://web_lite")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open("res://web_lite/content.json", FileAccess.WRITE)
	if file == null:
		push_error("无法创建 web_lite/content.json")
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t", false))
	print("WEB_LITE_CONTENT_PASS chapters=%d traits=%d" % [output.chapters.size(), output.traits.size()])
	quit()


func _clean(value: Variant) -> Variant:
	match typeof(value):
		TYPE_ARRAY:
			var result: Array = []
			for item in value:
				result.append(_clean(item))
			return result
		TYPE_DICTIONARY:
			var result := {}
			for key in value:
				result[str(key)] = _clean(value[key])
			return result
		TYPE_COLOR:
			var color: Color = value
			return "#" + color.to_html(false)
		TYPE_VECTOR2:
			var point: Vector2 = value
			return {"x": point.x, "y": point.y}
		_:
			return value
