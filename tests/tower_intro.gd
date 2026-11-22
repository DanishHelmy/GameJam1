extends SceneTree
func _initialize() -> void:
	Progress.reset()
	Progress.has_leg = true
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await physics_frame
	Progress.room_index = 3
	g._load_room()
	for i in 20:
		await physics_frame
	var p = g.room.player
	print("t=0.3s  player ", p.global_position, " physics on: ", p.is_physics_processing())
	for i in 60 * 6:
		await physics_frame
	print("t=6.3s  player ", p.global_position, " physics on: ", p.is_physics_processing(), " on_floor: ", p.is_on_floor())
	# walk into the tower and check the camera locks to the shaft centre
	Input.action_press("right")
	for i in 60 * 4:
		await physics_frame
	Input.action_release("right")
	print("after walking: player ", p.global_position, " cam x ", g.cam.position.x, " (locks to 760 inside)")
	quit()
