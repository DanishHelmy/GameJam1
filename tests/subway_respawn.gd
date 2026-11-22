extends SceneTree
func _initialize() -> void:
	Progress.reset()
	Progress.has_leg = true
	var r := RoomBase.new()
	r.room_id = "t3"
	root.add_child(r)
	await physics_frame
	await physics_frame
	var p = r.player
	# 1) locked: standing on the escalator plate does nothing
	p.global_position = Vector2(1960, 360)
	for i in 60 * 3:
		await physics_frame
	print("LOCKED  tier ", r.active_tier, " pos ", p.global_position, " (expect tier 0, still on plate)")
	# 2) press O on the panel (simulate the key button) then ride
	r.tier_unlocked[0] = true
	p.global_position = Vector2(1900, 340)
	for i in 60 * 5:
		await physics_frame
	print("UNLOCKED ride: tier ", r.active_tier, " pos ", p.global_position, " spawn ", p.spawn_point)
	# 3) die in tier 2 -> stays in tier 2
	p._respawn()
	await physics_frame
	print("respawn in tier 2: pos ", p.global_position, " tier ", r.active_tier, " (expect tier 1, y~960)")
	# 4) die DURING the second ride (needs unlock of tier 1)
	r.tier_unlocked[1] = true
	p.global_position = Vector2(1960, 960)
	for i in 40:
		await physics_frame
	var mid: Vector2 = p.global_position
	p._respawn()
	await physics_frame
	print("died mid-ride: moved? ", p.global_position.distance_to(mid) < 40.0, " (expect true: ignored)")
	for i in 60 * 4:
		await physics_frame
	print("after ride 2: tier ", r.active_tier, " pos ", p.global_position)
	p._respawn()
	await physics_frame
	print("respawn in tier 3: pos ", p.global_position, " tier ", r.active_tier, " (expect tier 2, y~1560)")
	quit()
