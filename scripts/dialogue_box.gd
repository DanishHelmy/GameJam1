extends CanvasLayer
## Plays a dialogue JSON from res://narrative/dialogue/ as a visual-novel box.
## Enter, Space or left click: finish the typing, then advance. Writers edit the JSON only.
## Optional per-line key "expression": neutral | sad | surprised | determined | tired.
## The robot shows only on the hero's lines (empty speaker = the robot's own thoughts).

signal finished

@export_file("*.json") var dialogue_file := "res://narrative/dialogue/chapter_0_lab.json"

const CYAN := Color("3df0ff")
const HERO_NAME := "UNIT-7"
const PANEL := Rect2(40, 530, 1200, 160)
const CPS := 55.0

var _lines: Array = []
var _index := 0
var _shown := 0.0
var _hero_in := 0.0
var _hero_want := false
var _name := ""
var _text := ""
var _t := 0.0
var _hero: HeroVN
var _ui: Control
var _font: Font

func _ready() -> void:
	layer = 50
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_font = sf
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.draw.connect(_draw_ui)
	add_child(_ui)
	_hero = HeroVN.new()
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.size = Vector2(320, 360)
	_hero.show_behind_parent = true
	_ui.add_child(_hero)
	var f := FileAccess.open(dialogue_file, FileAccess.READ)
	if f == null:
		push_error("Cannot open " + dialogue_file)
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		_lines = data.get("lines", [])
	_show_line()

func _process(delta: float) -> void:
	_t += delta
	_shown += delta * CPS
	_hero_in = move_toward(_hero_in, 1.0 if _hero_want else 0.0, delta * 3.5)
	var e := 1.0 - pow(1.0 - _hero_in, 3.0)
	_hero.visible = _hero_in > 0.0
	_hero.position = Vector2(lerpf(-260.0, 36.0, e), PANEL.position.y - _hero.size.y + 40.0)
	_hero.modulate.a = e
	_ui.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var click := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		click = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if visible and (event.is_action_pressed("ui_accept") or click):
		get_viewport().set_input_as_handled()
		if _shown < _text.length():
			_shown = _text.length()
			return
		_index += 1
		_show_line()

func _expression_for(line: Dictionary) -> String:
	if line.has("expression"):
		return str(line["expression"])
	var t := str(line.get("text", "")).to_lower()
	for w in ["cold", "dark", "alone", "nobody", "silence", "empty", "dead", "gone", "rejected", "failed", "nothing", "forgot", "lost"]:
		if t.contains(w):
			return "sad"
	if t.begins_with("...") or t.contains("tired") or t.contains("slow"):
		return "tired"
	if t.contains("?"):
		return "surprised"
	for w in ["get up", "move", "go ", "run", "must", "jump", "climb", "fight", "again"]:
		if t.contains(w):
			return "determined"
	return "neutral"

func _show_line() -> void:
	if _index >= _lines.size():
		hide()
		finished.emit()
		return
	var line: Dictionary = _lines[_index]
	var spk := str(line.get("speaker", ""))
	_hero_want = spk == ""
	_name = HERO_NAME if spk == "" else spk
	_text = str(line.get("text", ""))
	_shown = 0.0
	_hero.expr = _expression_for(line)

func _draw_ui() -> void:
	var p := PANEL
	var cut := 16.0
	var poly := PackedVector2Array([
		p.position + Vector2(cut, 0), Vector2(p.end.x - cut, p.position.y), Vector2(p.end.x, p.position.y + cut),
		Vector2(p.end.x, p.end.y - cut), Vector2(p.end.x - cut, p.end.y), Vector2(p.position.x + cut, p.end.y),
		Vector2(p.position.x, p.end.y - cut), Vector2(p.position.x, p.position.y + cut)])
	_ui.draw_colored_polygon(poly, Color(0.02, 0.07, 0.11, 0.88))
	var y := p.position.y + 4.0
	while y < p.end.y - 3.0:
		_ui.draw_line(Vector2(p.position.x + 8, y), Vector2(p.end.x - 8, y), Color(0.3, 0.9, 1.0, 0.045), 1.0)
		y += 4.0
	var closed := poly.duplicate()
	closed.append(poly[0])
	_ui.draw_polyline(closed, Color(CYAN.r, CYAN.g, CYAN.b, 0.3), 5.0)
	_ui.draw_polyline(closed, CYAN, 2.0)

	# angled speaker tab
	var tab_x := 380.0
	var tw := _font.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 56.0
	var tab := PackedVector2Array([
		Vector2(tab_x, p.position.y), Vector2(tab_x + 18, p.position.y - 36), Vector2(tab_x + tw, p.position.y - 36),
		Vector2(tab_x + tw + 18, p.position.y)])
	_ui.draw_colored_polygon(tab, Color(0.03, 0.14, 0.2, 0.95))
	var tc := tab.duplicate()
	_ui.draw_polyline(tc, CYAN, 2.0)
	_ui.draw_string(_font, Vector2(tab_x + 30, p.position.y - 10), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, CYAN)

	# typed text
	var n := mini(int(_shown), _text.length())
	var shown := _text.substr(0, n)
	var tx := 400.0 if _hero_want else 80.0
	_ui.draw_multiline_string(_font, Vector2(tx, p.position.y + 52), shown, HORIZONTAL_ALIGNMENT_LEFT, p.end.x - tx - 60.0, 26, -1, Color("b8f6ff"))

	# advance arrow
	if n >= _text.length():
		var a := 0.5 + 0.5 * sin(_t * 6.0)
		var ax := p.end.x - 50.0 + a * 4.0
		var ay := p.end.y - 30.0
		var c := Color(CYAN.r, CYAN.g, CYAN.b, 0.5 + 0.5 * a)
		_ui.draw_polyline(PackedVector2Array([Vector2(ax, ay - 9), Vector2(ax + 9, ay), Vector2(ax, ay + 9)]), c, 3.0)
		_ui.draw_polyline(PackedVector2Array([Vector2(ax - 11, ay - 9), Vector2(ax - 2, ay), Vector2(ax - 11, ay + 9)]), c, 3.0)
