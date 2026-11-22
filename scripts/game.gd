extends Node
## Runs the rooms in order: intro dialogue, HUD, data-log popups, end of demo.

var room: RoomBase
var hud: Label
var hud_layer: CanvasLayer
var dlg: CanvasLayer
var busy := false

func _ready() -> void:
	Progress.reset()
	hud_layer = CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(12, 8)
	hud_layer.add_child(hud)
	add_child(hud_layer)
	_load_room()

func _process(_d: float) -> void:
	if room == null or room.player == null or not is_instance_valid(room.player):
		return
	var p = room.player
	var t := "%s   (room %d/%d, logs %d)\n" % [Rooms.title(room.room_id), Progress.room_index + 1, Rooms.ORDER.size(), Progress.logs]
	t += "A/D move  Space jump  R respawn"
	if p.has_dash: t += "  Shift dash"
	if p.has_grapple: t += "  Click/E grapple"
	if p.has_arm: t += "  Right-click/Q throw/recall arm"
	if p.has_xray: t += "  F x-ray eyes"
	hud.text = t

func _load_room() -> void:
	if room:
		room.queue_free()
		await room.tree_exited
	if Progress.room_index >= Rooms.ORDER.size():
		hud.text = "END OF DEMO\nThanks for playing."
		return
	var id: String = Rooms.ORDER[Progress.room_index]
	room = RoomBase.new()
	room.room_id = id
	room.exited.connect(_next_room)
	room.log_found.connect(_show_dialogue_then_resume)
	add_child(room)
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	room.add_child(cam)
	if Rooms.INTRO.has(id):
		_show_dialogue_then_resume(Rooms.INTRO[id])

func _next_room() -> void:
	if busy:
		return
	busy = true
	Progress.room_index += 1
	await get_tree().create_timer(0.2).timeout
	busy = false
	_load_room()

func _show_dialogue_then_resume(file: String) -> void:
	if file.contains("_log"):
		Progress.logs += 1
	var p = room.player
	p.set_physics_process(false)
	dlg = preload("res://scenes/dialogue_box.tscn").instantiate()
	dlg.dialogue_file = file
	dlg.finished.connect(func():
		dlg.queue_free()
		# short delay so the click that closed the dialogue doesn't also fire the grapple
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(p):
			p.set_physics_process(true))
	add_child(dlg)

# DEBUG: F1-F5 jump to the first room of each chapter (and unlock every ability). Remove before shipping.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var chapter := {KEY_F1: "c0r1", KEY_F2: "c1r1", KEY_F3: "c2r1", KEY_F4: "c3r1", KEY_F5: "c4r1"}
	if not chapter.has(event.keycode):
		return
	Progress.has_leg = true
	Progress.has_arm = true
	Progress.has_grapple = true
	Progress.has_dash = true
	Progress.has_xray = true
	Progress.room_index = Rooms.ORDER.find(chapter[event.keycode])
	_load_room()
