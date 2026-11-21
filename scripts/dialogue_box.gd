extends CanvasLayer
## Plays a dialogue JSON from res://narrative/dialogue/. Press Enter, Space or left click to advance.
## Writers edit the JSON only; no code changes needed.

signal finished

@export_file("*.json") var dialogue_file := "res://narrative/dialogue/chapter_0_lab.json"

var _lines: Array = []
var _index := 0

@onready var _speaker: Label = $Panel/Margin/VBox/Speaker
@onready var _text: Label = $Panel/Margin/VBox/Text

func _ready() -> void:
	var f := FileAccess.open(dialogue_file, FileAccess.READ)
	if f == null:
		push_error("Cannot open " + dialogue_file)
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		_lines = data.get("lines", [])
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	var click := event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if visible and (event.is_action_pressed("ui_accept") or click):
		get_viewport().set_input_as_handled()
		_index += 1
		_show_line()

func _show_line() -> void:
	if _index >= _lines.size():
		hide()
		finished.emit()
		return
	_speaker.text = _lines[_index].get("speaker", "")
	_text.text = _lines[_index].get("text", "")
