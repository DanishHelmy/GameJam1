extends SceneTree
## Renders a room and saves screenshots. Args after --: room id, output prefix, then x,y,zoom triples.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var id: String = args[0]
	var out: String = args[1]
	Progress.reset()
	Progress.has_leg = true
	Progress.has_xray = true
	var r := RoomBase.new()
	r.room_id = id
	root.add_child(r)
	var cam := Camera2D.new()
	r.add_child(cam)
	await process_frame
	await process_frame
	r.player.set_physics_process(false)
	r.player.visible = false
	var xr: bool = args.size() > 2 and args[2] == "xray"
	if xr:
		r.player.xray_on = true
	var i := 3
	var n := 0
	while i + 2 < args.size():
		cam.position = Vector2(float(args[i]), float(args[i + 1]))
		cam.zoom = Vector2.ONE * float(args[i + 2])
		for k in 8:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png(out + str(n) + ".png")
		n += 1
		i += 3
	quit()
