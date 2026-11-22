extends SceneTree
func _initialize() -> void:
	for id in ["t1","t2","t3","t4","t5","t6","t7"]:
		var r := RoomBase.new()
		r.room_id = id
		root.add_child(r)
		await process_frame
		await process_frame
		print("built ", id, " children=", r.get_child_count(), " width=", r.width)
		r.queue_free()
		await process_frame
	quit()
