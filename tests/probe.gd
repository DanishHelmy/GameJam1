extends SceneTree
## Probe: does scripted input drive the real player, and how fast can we step physics?

func _initialize() -> void:
	Progress.reset()
	Progress.has_leg = true
	Progress.has_dash = true
	var r := RoomBase.new()
	r.room_id = "t1"
	root.add_child(r)
	await physics_frame
	await physics_frame
	var p = r.player
	p.spawn_point = Vector2(-9999, -9999)
	print("start pos ", p.global_position, " on_floor ", p.is_on_floor())
	for i in 20:
		await physics_frame
	print("settled ", p.global_position, " on_floor ", p.is_on_floor())
	var y0: float = p.global_position.y
	Input.action_press("jump")
	var apex := y0
	for i in 60:
		await physics_frame
		apex = minf(apex, p.global_position.y)
		if i == 2:
			Input.action_release("jump")
	print("jump rise (short tap) = ", y0 - apex)
	for i in 40:
		await physics_frame
	y0 = p.global_position.y
	apex = y0
	Input.action_press("jump")
	for i in 70:
		await physics_frame
		apex = minf(apex, p.global_position.y)
	Input.action_release("jump")
	print("jump rise (held) = ", y0 - apex)
	for i in 40:
		await physics_frame
	var x0: float = p.global_position.x
	Input.action_press("right")
	for i in 30:
		await physics_frame
	Input.action_release("right")
	print("walk 30 frames dx = ", p.global_position.x - x0)
	var t0 := Time.get_ticks_msec()
	for i in 600:
		await physics_frame
	print("600 frames took ms: ", Time.get_ticks_msec() - t0)
	# mouse position as seen by the player
	var ev := InputEventMouseMotion.new()
	ev.position = Vector2(321, 123)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	await physics_frame
	await physics_frame
	print("mouse seen by player: ", p.get_global_mouse_position())
	quit()
