extends SceneTree
## Checks the street's roof birds (cap, dive, climb back) and the stand lift (waits, then descends).

func _initialize() -> void:
	Progress.reset()
	Progress.has_leg = true
	var r := RoomBase.new()
	r.room_id = "t2"
	root.add_child(r)
	await physics_frame
	await physics_frame
	var p = r.player
	# --- lift
	var lift: AnimatableBody2D = null
	for c in r.get_children():
		if c.has_meta("stand_lift"):
			lift = c
	var top_y := lift.position.y
	await physics_frame
	for i in 120:
		await physics_frame
	print("lift idle (nobody on it): moved ", lift.position.y - top_y)
	p.global_position = Vector2(lift.position.x, lift.position.y - 40.0)
	p.spawn_point = p.global_position
	p.velocity = Vector2.ZERO
	for i in 90:
		await physics_frame
	print("lift after player stands 1.5s: moved ", lift.position.y - top_y)
	for i in 200:
		await physics_frame
	print("lift after 3.8s: moved ", lift.position.y - top_y, "  player y ", p.global_position.y)
	# --- birds: park the player on roof B so the birds dive
	p.global_position = Vector2(1300, 260.0 + 40.0 - 30.0)
	p.spawn_point = p.global_position
	var max_birds := 0
	var dives := 0
	var rises := 0
	var seen_dive := false
	for i in 60 * 70:
		await physics_frame
		p.velocity = Vector2.ZERO if p.global_position.y < 400 else p.velocity
		var alive := 0
		for e in r.roof_birds:
			if is_instance_valid(e.node):
				alive += 1
				if e.state == 1 and not seen_dive:
					seen_dive = true
					dives += 1
				if e.state == 2:
					rises += 1
		max_birds = maxi(max_birds, alive)
		if i % 600 == 0:
			print("t=", i / 60, "s roof birds alive: ", alive)
	print("max roof birds at once: ", max_birds, " (cap 5)")
	print("dive seen: ", seen_dive, "  rise frames: ", rises)
	quit()
