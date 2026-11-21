extends Node
## Runs the rooms in order: intro dialogue, HUD, data-log popups, end of demo.

var room: RoomBase
var hud: Label
var hud_layer: CanvasLayer
var dlg: CanvasLayer
var busy := false
var cam: Camera2D

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
	if cam and is_instance_valid(cam):
		if room.cam_snap != Vector2.INF:
			cam.position = _cam_goal(room.cam_snap)   # hard cut to the next tier
			room.cam_snap = Vector2.INF
		elif not room.cam_locked:
			var goal := _cam_goal(p.global_position)
			cam.position.x = goal.x
			cam.position.y = lerpf(cam.position.y, goal.y, clampf(_d * 7.0, 0.0, 1.0))
	var t := "%s   (room %d/%d, logs %d)\n" % [Rooms.title(room.room_id), Progress.room_index + 1, Rooms.ORDER.size(), Progress.logs]
	t += "A/D move  Space jump  R respawn"
	if p.has_dash: t += "  Shift dash"
	if p.has_grapple: t += "  Click/E grapple"
	if p.has_arm: t += "  Q throw/recall arm (Down+Q drop)"
	if p.has_xray: t += "  F x-ray eyes"
	hud.text = t

func _cam_goal(pp: Vector2) -> Vector2:
	var z: float = room.cam_zoom
	var hw := 640.0 / z
	var hh := 360.0 / z
	return Vector2(clampf(pp.x, hw, maxf(room.width - hw, hw)), clampf(pp.y, hh, maxf(room.height - hh, hh)))


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
	cam = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	cam.zoom = Vector2.ONE * room.cam_zoom
	room.add_child(cam)
	cam.position = _cam_goal(room.spawn)
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
