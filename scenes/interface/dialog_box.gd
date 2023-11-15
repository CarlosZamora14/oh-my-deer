extends Control

var lines: Array[String] = ["This is a test", "Pretty sick"]
var timings: Array[float] = [1.2, 1.9]
var line_index: int = 0
var read_window: float = 0.5

@onready var text_label: RichTextLabel = $NinePatchRect/MarginContainer/RichTextLabel

func _ready():
	load_dialog()

func load_dialog():
	if line_index < lines.size():
		text_label.bbcode_text = lines[line_index]
		text_label.visible_ratio = 0
		var tween = get_tree().create_tween()
		tween.tween_property(text_label, "visible_ratio", 1, max(timings[line_index] - read_window, 0))
		await get_tree().create_timer(timings[line_index]).timeout
		line_index += 1
		load_dialog()
	else:
		queue_free()
