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
			if room.cam_center_x >= 0.0 and p.global_position.x > room.cam_center_from:
				cam.position.x = lerpf(cam.position.x, room.cam_center_x, clampf(_d * 4.0, 0.0, 1.0))
			else:
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
	if id == "t7":
		_run_ending()
		return
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


# ---------------------------------------------------------------- ending: the robot on the ledge
func _play_dialogue(file: String) -> void:
	dlg = preload("res://scenes/dialogue_box.tscn").instantiate()
	dlg.dialogue_file = file
	add_child(dlg)
	await dlg.finished
	dlg.queue_free()
	await get_tree().create_timer(0.2).timeout

func _run_ending() -> void:
	var p = room.player
	p.set_physics_process(false)
	p.sitting = true
	p.velocity = Vector2.ZERO
	p.global_position = room.spawn
	hud.text = ""
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(1280, 720)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var tw := create_tween()
	tw.tween_property(black, "modulate:a", 0.0, 2.0)
	await tw.finished
	await get_tree().create_timer(1.5).timeout
	await _play_dialogue("res://narrative/dialogue/ending_1_ledge.json")
	# --- flashback: warm house at dusk, shown over the roof
	var fb := Control.new()
	fb.modulate.a = 0.0
	fb.size = Vector2(1280, 720)
	fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fb)
	var parts := [
		[Rect2(0, 0, 1280, 720), Color("3a2a4d")],
		[Rect2(0, 0, 1280, 300), Color("6b3a63")],
		[Rect2(0, 300, 1280, 160), Color("c9704f")],
		[Rect2(0, 460, 1280, 260), Color("2a1f2e")],
		[Rect2(440, 330, 400, 260), Color("7a4a38")],
		[Rect2(400, 300, 480, 50), Color("4a2a2a")],
		[Rect2(560, 400, 90, 190), Color("2b1c14")],
		[Rect2(700, 400, 90, 80), Color("ffd98a")],
		[Rect2(440, 590, 400, 14), Color("5a3a28")],
		[Rect2(850, 420, 8, 180), Color("3a2a1e")],
	]
	for pr in parts:
		var cr := ColorRect.new()
		cr.position = (pr[0] as Rect2).position
		cr.size = (pr[0] as Rect2).size
		cr.color = pr[1]
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fb.add_child(cr)
	var boy := ColorRect.new()
	boy.color = Color("e8c9a0")
	boy.size = Vector2(26, 54)
	boy.position = Vector2(500, 536)
	fb.add_child(boy)
	var tw2 := create_tween()
	tw2.tween_property(fb, "modulate:a", 1.0, 1.6)
	await tw2.finished
	await _play_dialogue("res://narrative/dialogue/ending_2_flashback.json")
	var tw3 := create_tween()
	tw3.tween_property(fb, "modulate:a", 0.0, 1.6)
	await tw3.finished
	room.city_lights_on(6.0)
	await get_tree().create_timer(2.0).timeout
	await _play_dialogue("res://narrative/dialogue/ending_3_lights.json")
	await get_tree().create_timer(1.0).timeout
	var tw4 := create_tween()
	tw4.tween_property(black, "modulate:a", 1.0, 2.5)
	await tw4.finished
	var title := Label.new()
	title.text = "TOMMY"
	title.add_theme_font_size_override("font_size", 96)
	title.position = Vector2(0, 280)
	title.size = Vector2(1280, 140)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(title)
