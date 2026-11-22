extends SceneTree
func _initialize() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await physics_frame
	await physics_frame
	Progress.room_index = 6
	g._load_room()
	for i in 60 * 6:
		await physics_frame
	print("ending running, dialogue up: ", g.dlg != null and is_instance_valid(g.dlg))
	for n in 12:
		if g.dlg != null and is_instance_valid(g.dlg):
			g.dlg._index += 1
			g.dlg._show_line()
		for i in 60 * 3:
			await physics_frame
	print("room id: ", g.room.room_id, " lights: ", g.room.city_windows.size())
	quit()
