extends SceneTree
func _initialize() -> void:
	Progress.reset()
	Progress.has_leg = true
	Progress.has_grapple = true
	var r := RoomBase.new()
	r.room_id = "t5"
	root.add_child(r)
	await physics_frame
	await physics_frame
	var p = r.player
	p.has_grapple = true
	for i in 30:
		await physics_frame
	# swing from the first hook, then check the cooldown before the next one is allowed
	var hook = get_nodes_in_group("hook")[0]
	p.global_position = hook.global_position + Vector2(-140, 120)
	p.velocity = Vector2.ZERO
	p.anchor_pos = hook.global_position
	p.anchor_node = hook
	p.swinging = true
	p.rope_len = 190.0
	p.can_grapple = false
	for i in 20:
		await physics_frame
	p._end_swing()
	var t := 0.0
	var first_ok := -1.0
	for i in 90:
		await physics_frame
		t += 1.0 / 60.0
		if p.can_grapple and first_ok < 0.0:
			first_ok = t
	print("grapple available again after ", snappedf(first_ok, 0.01), "s (expect ~0.5, in mid-air: ", not p.is_on_floor(), ")")
	quit()
