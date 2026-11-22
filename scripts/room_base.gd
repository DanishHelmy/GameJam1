class_name RoomBase
extends Node2D
## Base for single-screen rooms (1280x720). Subclasses override build().
## Helpers: block, hook, plate+door, spring pad, data log, exit.

signal exited
signal log_found(dialogue_file: String)

var player
var spawn := Vector2(100, 600)
var tint := Color("3b4656")
var bg_color := Color("14181f")
var exit_area: Area2D
var door: StaticBody2D
var door_shape: CollisionShape2D
var plate_count := 0
var xray_nodes: Array = []   # [{node, body, hook}]
var xray_overlay: ColorRect

var room_id := ""
var height := 720.0   # room height in px; taller rooms scroll vertically
var cam_zoom := 1.0   # >1 = camera closer
var cam_locked := false          # true while an escalator ride runs: camera stops following
var tier_starts: Array = []       # child index where each tier begins (tiered rooms like the subway)
var tier_floors: Array = []
var tier_spawns: Array = []      # respawn point for each tier
var riding := false              # true during an escalator ride (deaths are ignored)
var active_tier := 0
var cam_center_x := -1.0         # >=0: once the player passes cam_center_from, the camera locks to this x
var cam_center_from := 0.0
var cam_snap := Vector2.INF      # set to cut the camera to a new spot
var fall_death := 0.0  # >0: landing after falling farther than this many px kills you
var floor_y := 640.0  # street floor top (taller rooms move it down)
var width := 1280.0   # room width in px; wider rooms scroll with the camera

func build() -> void:
	Rooms.build(self, room_id)

## Call at the start of each tier while building: everything added after it belongs to that tier.
func tier_mark() -> void:
	tier_starts.append(get_child_count())

func _tier_of(i: int, c: Node) -> int:
	if c.has_meta("tier"):
		return c.get_meta("tier")
	var t := -1
	for k in tier_starts.size():
		if i >= tier_starts[k]:
			t = k
	return t

func _tag_tiers() -> void:
	var i := 0
	for c in get_children():
		var ct := _tier_of(i, c)
		if ct >= 0 and not c.has_meta("tier"):
			c.set_meta("tier", ct)
		i += 1

## Show only the nodes of tier t, so you only ever see one layer.
func set_tier(t: int) -> void:
	active_tier = t
	if player != null and t < tier_spawns.size():
		player.spawn_point = tier_spawns[t]
	for c in get_children():
		if c.has_meta("tier") and c is CanvasItem:
			(c as CanvasItem).visible = (int(c.get_meta("tier")) == t)

## Which tier a plate at height y belongs to.
func active_tier_for(y: float) -> int:
	var t := 0
	for k in tier_floors.size():
		if y >= tier_floors[k] - 40.0:
			t = k
	return t

func _ready() -> void:
	RenderingServer.set_default_clear_color(bg_color)
	build()
	if tier_starts.size() > 0:
		_tag_tiers()
		set_tier(0)
	_border()
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = spawn
	add_child(player)
	Progress.apply(player)
	var layer := CanvasLayer.new()
	layer.layer = 5
	xray_overlay = ColorRect.new()
	xray_overlay.color = Color(0.1, 0.9, 0.8, 0.12)
	xray_overlay.size = Vector2(1280, 720)
	xray_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xray_overlay.visible = false
	layer.add_child(xray_overlay)
	add_child(layer)

func _border() -> void:
	block(Rect2(-40, -40, width + 80, 40))
	block(Rect2(-40, 0, 40, height + 40))
	block(Rect2(width, 0, 40, height + 40))

func block(rect: Rect2) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	b.add_child(s)
	var v := ColorRect.new()
	v.color = tint
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	add_child(b)

func hook(pos: Vector2) -> void:
	var h := Node2D.new()
	h.position = pos
	h.add_to_group("hook")
	var v := ColorRect.new()
	v.color = Color("6bd36b")
	v.size = Vector2(16, 16)
	v.position = Vector2(-8, -8)
	h.add_child(v)
	add_child(h)

func spring(rect: Rect2, power := -900.0) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 8
	a.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	a.add_child(s)
	var v := ColorRect.new()
	v.color = Color("e8c547")
	v.size = rect.size
	v.position = -rect.size / 2
	a.add_child(v)
	a.body_entered.connect(func(b):
		if b == player:
			player.velocity.y = power)
	add_child(a)

func plate_and_door(plate: Rect2, door_rect: Rect2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2   # only the detached arm
	a.position = plate.position + plate.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = plate.size
	s.shape = r
	a.add_child(s)
	var v := ColorRect.new()
	v.color = Color("e67e22")
	v.size = plate.size
	v.position = -plate.size / 2
	a.add_child(v)
	a.area_entered.connect(func(_a):
		plate_count += 1
		_update_door())
	a.area_exited.connect(func(_a):
		plate_count -= 1
		_update_door())
	add_child(a)

	door = StaticBody2D.new()
	door.collision_layer = 1
	door_shape = CollisionShape2D.new()
	var dr := RectangleShape2D.new()
	dr.size = door_rect.size
	door_shape.shape = dr
	door.add_child(door_shape)
	door.position = door_rect.position + door_rect.size / 2
	var dv := ColorRect.new()
	dv.color = Color("c0392b")
	dv.size = door_rect.size
	dv.position = -door_rect.size / 2
	door.add_child(dv)
	add_child(door)

func _update_door() -> void:
	var open := plate_count > 0
	door_shape.set_deferred("disabled", open)
	door.modulate.a = 0.2 if open else 1.0

func data_log(pos: Vector2, dialogue_file: String) -> void:
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 8
	c.position = pos
	var cs := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(22, 22)
	cs.shape = cr
	c.add_child(cs)
	var cv := ColorRect.new()
	cv.color = Color("f1c40f")
	cv.size = Vector2(22, 22)
	cv.position = Vector2(-11, -11)
	c.add_child(cv)
	c.body_entered.connect(func(b):
		if b == player:
			c.queue_free()
			log_found.emit(dialogue_file))
	add_child(c)

func exit_zone(rect: Rect2) -> void:
	exit_area = Area2D.new()
	exit_area.collision_layer = 0
	exit_area.collision_mask = 8
	exit_area.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	exit_area.add_child(s)
	var v := ColorRect.new()
	v.color = Color(0.9, 1.0, 0.5, 0.45)
	v.size = rect.size
	v.position = -rect.size / 2
	exit_area.add_child(v)
	exit_area.body_entered.connect(func(b):
		if b == player:
			exited.emit())
	add_child(exit_area)

## A recovered body part. kind: leg, arm, grapple, dash
func pickup(pos: Vector2, kind: String) -> void:
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 8
	c.position = pos
	var cs := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(26, 26)
	cs.shape = cr
	c.add_child(cs)
	var cv := ColorRect.new()
	cv.color = Color("4fd1c5")
	cv.size = Vector2(26, 26)
	cv.position = Vector2(-13, -13)
	c.add_child(cv)
	c.body_entered.connect(func(b):
		if b != player:
			return
		match kind:
			"leg": Progress.has_leg = true
			"arm": Progress.has_arm = true
			"grapple": Progress.has_grapple = true
			"dash": Progress.has_dash = true
			"xray": Progress.has_xray = true
		Progress.apply(player)
		c.queue_free())
	add_child(c)

func _process(_d: float) -> void:
	var on: bool = player != null and is_instance_valid(player) and player.xray_on and player.has_xray
	if xray_overlay:
		xray_overlay.visible = on
	for e in xray_nodes:
		var in_tier: bool = not e.node.has_meta("tier") or int(e.node.get_meta("tier")) == active_tier
		e.node.visible = on and in_tier
		if e.body:
			for c in e.node.get_children():
				if c is CollisionShape2D:
					c.set_deferred("disabled", not on)
		if e.hook:
			if on and not e.node.is_in_group("hook"):
				e.node.add_to_group("hook")
			elif not on and e.node.is_in_group("hook"):
				e.node.remove_from_group("hook")

## Solid only while x-ray eyes are on.
func hidden_block(rect: Rect2) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	s.disabled = true
	b.add_child(s)
	var v := ColorRect.new()
	v.color = Color("4fd1c5")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	b.visible = false
	add_child(b)
	xray_nodes.append({"node": b, "body": true, "hook": false})

## Grapple hook that exists only while x-ray eyes are on.
func hidden_hook(pos: Vector2) -> void:
	var h := Node2D.new()
	h.position = pos
	var v := ColorRect.new()
	v.color = Color("4fd1c5")
	v.size = Vector2(16, 16)
	v.position = Vector2(-8, -8)
	h.add_child(v)
	h.visible = false
	add_child(h)
	xray_nodes.append({"node": h, "body": false, "hook": true})

# ---------------------------------------------------------------- traps
func _kill_zone(area: Area2D) -> void:
	area.collision_layer = 0
	area.collision_mask = 8
	area.body_entered.connect(func(b):
		if b == player:
			player.call_deferred("_respawn"))

## Row of spikes filling rect (touching them respawns you).
func spikes(rect: Rect2) -> void:
	var a := Area2D.new()
	a.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(rect.size.x, rect.size.y * 0.7)
	s.shape = r
	s.position.y = rect.size.y * 0.15
	a.add_child(s)
	var n := maxi(1, int(rect.size.x / 14.0))
	var w := rect.size.x / n
	for i in n:
		var t := Polygon2D.new()
		var x := -rect.size.x / 2 + i * w
		t.polygon = PackedVector2Array([Vector2(x, rect.size.y / 2), Vector2(x + w / 2, -rect.size.y / 2), Vector2(x + w, rect.size.y / 2)])
		t.color = Color("d9534f")
		a.add_child(t)
	_kill_zone(a)
	add_child(a)

## Saw that patrols between two points.
func saw(from: Vector2, to: Vector2, seconds := 2.0) -> void:
	var a := Area2D.new()
	a.position = from
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 15.0
	s.shape = c
	a.add_child(s)
	var pts := PackedVector2Array()
	for i in 12:
		var ang := TAU * i / 12.0
		var rad := 18.0 if i % 2 == 0 else 11.0
		pts.append(Vector2(cos(ang), sin(ang)) * rad)
	var v := Polygon2D.new()
	v.polygon = pts
	v.color = Color("e0524d")
	a.add_child(v)
	_kill_zone(a)
	add_child(a)
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "position", to, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_property(a, "position", from, seconds).set_trans(Tween.TRANS_SINE)

## Platform that shakes, then drops when stood on, and comes back later.
func crumble(rect: Rect2, respawn := 1.8) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	b.add_child(s)
	var v := ColorRect.new()
	v.color = Color("8a6d4b")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	var sense := Area2D.new()
	sense.collision_layer = 0
	sense.collision_mask = 8
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(rect.size.x, 10)
	ss.shape = sr
	ss.position.y = -rect.size.y / 2 - 5
	sense.add_child(ss)
	b.add_child(sense)
	var state := {"busy": false}
	sense.body_entered.connect(func(body):
		if body != player or state.busy:
			return
		state.busy = true
		var tw := b.create_tween()
		tw.tween_property(v, "position:x", -rect.size.x / 2 + 3, 0.04).set_loops(8)
		await get_tree().create_timer(0.4).timeout
		tw.kill()
		v.position.x = -rect.size.x / 2
		s.set_deferred("disabled", true)
		b.visible = false
		await get_tree().create_timer(respawn).timeout
		s.set_deferred("disabled", false)
		b.visible = true
		state.busy = false)
	add_child(b)
	return b

## Steel beam spanning from one structure to another, with rivets. Hanging platforms attach to it.
func hang_bar(x1: float, x2: float, y: float) -> void:
	deco(Rect2(x1, y, x2 - x1, 14), Color("56616f"), -2)
	deco(Rect2(x1, y + 14, x2 - x1, 4), Color("2a323c"), -2)
	for bx in range(int(x1) + 20, int(x2), 60):
		deco(Rect2(bx, y + 4, 5, 5), Color("2a323c"), -1)
	for bx in range(int(x1), int(x2), 180):
		deco(Rect2(bx, y + 18, 8, 26), Color("56616f"), -2)          # hanger lugs

## Rickety plank platform hanging from the bar at `bar_y` by two chains. kind: "crumble" or "mover".
func hanging(x: float, y: float, w: float, bar_y: float, kind := "crumble") -> void:
	var rect := Rect2(x, y, w, 14)
	var body: Node2D
	if kind == "mover":
		body = mover(rect, Vector2(0, -50), 2.2)
	elif kind == "fragile":
		body = crumble(rect, 4.5)          # breaks fast, stays gone ~5s
		(body.get_child(1) as ColorRect).color = Color("6e4f35")
	else:
		body = crumble(rect)
	var top := bar_y + 18.0
	for cx in [10.0, w - 12.0]:
		var n := int((y - top) / 14.0)
		for i in n:
			var link := ColorRect.new()
			link.color = Color("8794a3") if i % 2 == 0 else Color("5e6978")
			link.size = Vector2(3, 10)
			link.position = Vector2(cx - w / 2.0, -7.0 - (i + 1) * 14.0 + 14.0 - 7.0 * 0)
			link.mouse_filter = Control.MOUSE_FILTER_IGNORE
			link.z_index = -2
			body.add_child(link)
	for i in 3:                                                      # plank seams
		var seam := ColorRect.new()
		seam.color = Color("3d3226")
		seam.size = Vector2(2, 14)
		seam.position = Vector2(-w / 2.0 + (i + 1) * w / 4.0, -7.0)
		seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(seam)

# ---------------------------------------------------------------- sketch-level helpers
var winds: Array = []   # [{rect, accel}]

## Platform that slides by `delta` and back. Carries the player.
func mover(rect: Rect2, delta: Vector2, seconds := 2.5) -> AnimatableBody2D:
	var b := AnimatableBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	b.add_child(s)
	var v := ColorRect.new()
	v.color = Color("6f86d6")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	add_child(b)
	b.set_meta("delta", delta)
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "position", b.position + delta, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "position", b.position, seconds).set_trans(Tween.TRANS_SINE)
	return b

## Spinning cross hazard (two arms), kills on touch.
func spinner(center: Vector2, arm_len := 60.0, seconds := 3.0) -> void:
	var a := Area2D.new()
	a.position = center
	for k in 2:
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(arm_len * 2.0, 10.0)
		s.shape = r
		s.rotation = k * PI / 2.0
		a.add_child(s)
		var v := ColorRect.new()
		v.color = Color("e0524d")
		v.size = r.size
		v.position = -r.size / 2
		v.rotation = k * PI / 2.0
		v.pivot_offset = r.size / 2
		v.position = -r.size / 2
		a.add_child(v)
	_kill_zone(a)
	add_child(a)
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "rotation", TAU, seconds).from(0.0)

## Zone that pushes the player (px/s^2) while airborne inside it.
func wind(rect: Rect2, accel: Vector2) -> void:
	winds.append({"rect": rect, "accel": accel})
	var v := ColorRect.new()
	v.color = Color(0.7, 0.9, 1.0, 0.10)
	v.position = rect.position
	v.size = rect.size
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.z_index = -1
	add_child(v)

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_update_key_buttons()
	_update_divers(delta)
	if player.is_on_floor():
		return
	for w in winds:
		if (w.rect as Rect2).has_point(player.global_position):
			player.velocity += (w.accel as Vector2) * delta

# ---------------------------------------------------------------- birds, ladder, piston
## Ladder-style exit (drawn as rungs) that leads to the next level.
func ladder_exit(rect: Rect2) -> void:
	exit_zone(rect)
	for i in int(rect.size.y / 14.0):
		var rung := ColorRect.new()
		rung.color = Color("d9d2a0")
		rung.size = Vector2(rect.size.x, 3)
		rung.position = rect.position + Vector2(0, 6 + i * 14.0)
		add_child(rung)

## Piston that rises and retracts in a column. Deadly when extended into you.
func piston(base: Vector2, height: float, seconds := 1.6) -> void:
	var a := Area2D.new()
	a.position = base
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(36, 24)
	s.shape = r
	a.add_child(s)
	var v := ColorRect.new()
	v.color = Color("9aa4b2")
	v.size = Vector2(36, 24)
	v.position = Vector2(-18, -12)
	a.add_child(v)
	_kill_zone(a)
	add_child(a)
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "position:y", base.y - height, seconds).set_trans(Tween.TRANS_SINE)
	tw.tween_property(a, "position:y", base.y, seconds).set_trans(Tween.TRANS_SINE)

## Non-colliding background rectangle (buildings, tree trunks, wheels).
func deco(rect: Rect2, color: Color, z := -5) -> void:
	var v := ColorRect.new()
	v.color = color
	v.position = rect.position
	v.size = rect.size
	v.z_index = z
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

## Abandoned car: solid body + cabin with wheels. x is the left edge, sitting on the floor (y=640).
func car(x: float) -> void:
	var f := floor_y
	block(Rect2(x, f - 36, 190, 36))
	block(Rect2(x + 40, f - 70, 100, 34))
	deco(Rect2(x + 52, f - 64, 34, 22), Color("9fc3d6"), 1)
	deco(Rect2(x + 94, f - 64, 34, 22), Color("9fc3d6"), 1)
	deco(Rect2(x + 24, f - 14, 30, 14), Color("1b1b1b"), 2)
	deco(Rect2(x + 136, f - 14, 30, 14), Color("1b1b1b"), 2)

## Platform parked at `rect` until the thrown arm hits the button at `button_pos`; then it shuttles by
## `delta` and back forever (a bridge across a gap too wide to jump).
func arm_mover(rect: Rect2, delta: Vector2, seconds: float, button_pos: Vector2) -> AnimatableBody2D:
	var b := AnimatableBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	cs.shape = rs
	b.add_child(cs)
	var v := ColorRect.new()
	v.color = Color("e08a2e")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	for i in int(rect.size.x / 24.0):
		var st := ColorRect.new()
		st.color = Color("3a2a10")
		st.size = Vector2(8, rect.size.y)
		st.position = Vector2(-rect.size.x / 2 + 6 + i * 24.0, -rect.size.y / 2)
		b.add_child(st)
	add_child(b)
	b.set_meta("delta", delta)
	b.set_meta("arm_mover", true)
	var start := b.position
	shoot_button(button_pos, func():
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "position", start + delta, seconds).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "position", start, seconds).set_trans(Tween.TRANS_SINE))
	return b

## Dress the ground as a proper street: asphalt road with dashed centre line, kerbs, sidewalks along the
## building line, a crosswalk, lamp posts and hydrants. Purely visual (the floor block is separate).
func street_ground(x1: float, x2: float, sidewalk_to: float = 0.0) -> void:
	var f := floor_y
	deco(Rect2(x1, f, x2 - x1, 80), Color("2b2f36"), 1)                          # asphalt body
	deco(Rect2(x1, f, x2 - x1, 5), Color("3a3f48"), 2)                           # road surface edge
	for dx in range(int(x1) + 20, int(x2), 120):
		deco(Rect2(dx, f + 38, 60, 6), Color("e8c547"), 2)                       # dashed centre line
	deco(Rect2(x1, f + 74, x2 - x1, 6), Color("1c1f24"), 2)                      # lower edge
	# sidewalk strip along the base of the buildings (raised kerb look, drawn on the floor line)
	if sidewalk_to > x1:
		deco(Rect2(x1, f - 6, sidewalk_to - x1, 6), Color("8a8f98"), 2)
		deco(Rect2(x1, f - 6, sidewalk_to - x1, 2), Color("b5bac2"), 3)
	# crosswalk
	for i in 8:
		deco(Rect2(x1 + 330 + i * 18, f, 10, 34), Color("d8dbe0"), 2)
	# lamp posts and hydrants
	for lx in range(int(x1) + 140, int(x2), 420):
		deco(Rect2(lx, f - 150, 5, 150), Color("3c434d"), 0)
		deco(Rect2(lx, f - 150, 34, 5), Color("3c434d"), 0)
		deco(Rect2(lx + 26, f - 145, 14, 8), Color("f4e3a0"), 1)
	for hx in range(int(x1) + 300, int(x2), 640):
		deco(Rect2(hx, f - 22, 14, 22), Color("b03a2e"), 1)
		deco(Rect2(hx - 3, f - 18, 20, 5), Color("b03a2e"), 1)

## Solid platform with a colour strip on top so a climbing route reads clearly (tower paths).
func path_platform(rect: Rect2, color: Color) -> void:
	block(rect)
	deco(Rect2(rect.position.x, rect.position.y, rect.size.x, 5), color, 3)

## Mover tinted in a route colour.
func path_mover(rect: Rect2, delta: Vector2, seconds: float, color: Color) -> void:
	var b := mover(rect, delta, seconds)
	(b.get_child(1) as ColorRect).color = color

## Brown wooden plank: stand on it and after `seconds` it breaks (shaking for the last second), then returns
## after `back` seconds. Step off before it breaks and the timer resets.
func timed_plank(rect: Rect2, seconds := 5.0, back := 4.0) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	cs.shape = rs
	b.add_child(cs)
	var v := ColorRect.new()
	v.color = Color("8a5a2b")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	for i in 3:
		var seam := ColorRect.new()
		seam.color = Color("4a2f14")
		seam.size = Vector2(2, rect.size.y)
		seam.position = Vector2(-rect.size.x / 2 + (i + 1) * rect.size.x / 4.0, -rect.size.y / 2)
		b.add_child(seam)
	var sense := Area2D.new()
	sense.collision_layer = 0
	sense.collision_mask = 8
	sense.position = Vector2(0, -rect.size.y / 2 - 6)
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(rect.size.x - 6, 12)
	ss.shape = sr
	sense.add_child(ss)
	b.add_child(sense)
	add_child(b)
	var st := {"t": 0.0, "gone": false}
	var tmr := Timer.new()
	tmr.wait_time = 0.05
	tmr.autostart = true
	tmr.timeout.connect(func():
		if st.gone:
			return
		if sense.overlaps_body(player):
			st.t += 0.05
			if st.t > seconds - 1.0:
				v.position.x = -rect.size.x / 2 + sin(st.t * 60.0) * 2.5
			if st.t >= seconds:
				st.gone = true
				v.position.x = -rect.size.x / 2
				cs.set_deferred("disabled", true)
				b.visible = false
				await get_tree().create_timer(back).timeout
				cs.set_deferred("disabled", false)
				b.visible = true
				st.t = 0.0
				st.gone = false
		else:
			st.t = maxf(st.t - 0.1, 0.0))
	b.add_child(tmr)

## Distant city skyline for the ending: lit windows come on one by one when you call city_lights_on().
var city_windows: Array = []
func city_backdrop(rect: Rect2) -> void:
	deco(rect, Color("2e1f4d"), -20)
	var cols := [Color("2e1f4d"), Color("5b2a6e"), Color("a33a74"), Color("e0575d"), Color("f2894f"), Color("f7b955")]
	var n := 12
	for i in n:
		var t := float(i) / (n - 1)
		var idx := t * (cols.size() - 1)
		var c: Color = (cols[int(floor(idx))] as Color).lerp(cols[mini(int(floor(idx)) + 1, cols.size() - 1)], idx - floor(idx))
		deco(Rect2(rect.position.x, rect.position.y + rect.size.y * t * 0.8, rect.size.x, rect.size.y * 0.8 / n + 1), c, -19)
	deco(Rect2(rect.position.x + rect.size.x * 0.62 - 50, rect.position.y + rect.size.y * 0.62 - 50, 100, 100), Color("fff0b0"), -18)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var x := rect.position.x
	while x < rect.end.x:
		var bw := rng.randf_range(60.0, 130.0)
		var bh := rng.randf_range(120.0, 330.0)
		var top := rect.end.y - bh
		deco(Rect2(x, top, bw, bh), Color("160f22"), -17)
		for wy in range(int(top) + 14, int(rect.end.y) - 10, 28):
			for wx in range(int(x) + 10, int(x + bw) - 12, 22):
				if rng.randf() < 0.55:
					var wv := ColorRect.new()
					wv.color = Color("f4d27a")
					wv.size = Vector2(10, 14)
					wv.position = Vector2(wx, wy)
					wv.z_index = -16
					wv.modulate.a = 0.0
					wv.mouse_filter = Control.MOUSE_FILTER_IGNORE
					add_child(wv)
					city_windows.append(wv)
		x += bw + rng.randf_range(4.0, 18.0)

func city_lights_on(total_time := 5.0) -> void:
	city_windows.shuffle()
	var n := city_windows.size()
	for i in n:
		var wv: ColorRect = city_windows[i]
		var tw := create_tween()
		tw.tween_interval(total_time * float(i) / float(maxi(n, 1)))
		tw.tween_property(wv, "modulate:a", 1.0, 0.6)

## Train that pulls into the station at the start of the level: it slides in from off-screen left carrying the
## player, brakes, and stops at `rect`. Input is locked until it has stopped.
func train_arrival(rect: Rect2) -> void:
	var start_x := rect.position.x - 1100.0
	var tb := AnimatableBody2D.new()
	tb.collision_layer = 1
	tb.position = Vector2(start_x + rect.size.x / 2.0, rect.end.y + 4.0)      # floor of the train is level with the ground
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(rect.size.x, 12)
	cs.shape = rs
	tb.add_child(cs)
	var body := ColorRect.new()
	body.color = Color("5d6d7e")
	body.size = Vector2(rect.size.x, rect.size.y)
	body.position = Vector2(-rect.size.x / 2.0, -rect.size.y - 4.0)
	body.z_index = -2
	tb.add_child(body)
	var stripe := ColorRect.new()
	stripe.color = Color("e74c3c")
	stripe.size = Vector2(rect.size.x, 8)
	stripe.position = Vector2(-rect.size.x / 2.0, -28)
	stripe.z_index = -2
	tb.add_child(stripe)
	var wx := 20.0
	while wx < rect.size.x - 60.0:
		var w := ColorRect.new()
		w.color = Color("f7dc6f")
		w.size = Vector2(46, 34)
		w.position = Vector2(-rect.size.x / 2.0 + wx, -rect.size.y + 14.0)
		w.z_index = -1
		tb.add_child(w)
		wx += 80.0
	var lamp := ColorRect.new()
	lamp.color = Color("fff2a8")
	lamp.size = Vector2(10, 14)
	lamp.position = Vector2(rect.size.x / 2.0 - 12.0, -56)
	lamp.z_index = -1
	tb.add_child(lamp)
	for wxx in [30.0, rect.size.x - 60.0, rect.size.x / 2.0 - 15.0]:
		var wh := ColorRect.new()
		wh.color = Color("1b1b1b")
		wh.size = Vector2(30, 12)
		wh.position = Vector2(-rect.size.x / 2.0 + wxx, -10)
		wh.z_index = -1
		tb.add_child(wh)
	add_child(tb)
	deco(Rect2(rect.position.x - 1200.0, rect.end.y, rect.size.x + 1300.0, 5), Color("39424e"), 2)   # rails
	call_deferred("_run_train_arrival", tb, start_x, rect)

func _run_train_arrival(tb: AnimatableBody2D, start_x: float, rect: Rect2) -> void:
	var off := Vector2(rect.size.x * 0.45, -28.0)
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.global_position = tb.position + off
	var tw := create_tween()
	tw.tween_method(func(v: float):
		tb.position.x = v
		player.global_position = tb.position + off,
		start_x + rect.size.x / 2.0, rect.position.x + rect.size.x / 2.0, 4.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.5).timeout
	player.spawn_point = Vector2(rect.position.x + rect.size.x * 0.55, rect.end.y - 30.0)
	player.set_physics_process(true)

## Wall-mounted launcher: every `interval` seconds it fires a spike across the room in direction dir (+1/-1).
func spike_spawner(pos: Vector2, dir: int, interval := 3.2, speed := 170.0, travel := 640.0) -> void:
	deco(Rect2(pos.x - 14, pos.y - 18, 28, 36), Color("5d6d7e"), 2)
	deco(Rect2(pos.x - 14 + (22 if dir > 0 else 0), pos.y - 10, 6, 20), Color("3c434d"), 3)   # barrel facing the room
	deco(Rect2(pos.x - 5 + dir * 4, pos.y - 7, 10, 14), Color("c0392b"), 3)
	var t := Timer.new()
	t.wait_time = interval
	t.one_shot = false
	t.autostart = true
	t.timeout.connect(func():
		var a := Area2D.new()
		a.position = pos + Vector2(dir * 26.0, 0)
		var sh := CollisionShape2D.new()
		var rc := RectangleShape2D.new()
		rc.size = Vector2(24, 14)
		sh.shape = rc
		a.add_child(sh)
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(-12 * dir, -8), Vector2(12 * dir, 0), Vector2(-12 * dir, 8)])
		poly.color = Color("d9534f")
		a.add_child(poly)
		_kill_zone(a)
		add_child(a)
		var tw := a.create_tween()
		tw.tween_property(a, "position:x", pos.x + dir * travel, travel / speed)
		tw.tween_callback(a.queue_free))
	add_child(t)

## Tall solid building with window grid. Balconies attach to its faces.
func tower_building(rect: Rect2, color := Color("2e3744")) -> void:
	block(rect)
	deco(rect, color, 0)
	for wy in range(int(rect.position.y) + 30, int(rect.end.y) - 50, 70):
		for wx in range(int(rect.position.x) + 28, int(rect.end.x) - 40, 60):
			deco(Rect2(wx, wy, 28, 36), Color("4b5d75") if (wx + wy) % 3 != 0 else Color("e8d98a"), 1)
	deco(Rect2(rect.position.x - 6, rect.position.y - 8, rect.size.x + 12, 8), Color("1b222c"), 2)

## Stack of balconies bolted to a building face. side=-1: sticks out left of x_face, +1: right.
## Runs from y_from (low) up to y_to (high) in steps of `step` (<=75 so every hop is a jump).
func balcony_stack(x_face: float, side: int, y_from: float, y_to: float, w := 90.0, step := 70.0) -> void:
	# Even steps so the LAST balcony sits exactly at y_to (one jump below the roof).
	var n := int(ceil((y_from - y_to) / step))
	var st := (y_from - y_to) / float(maxi(n, 1))
	for i in range(n + 1):
		var y := y_from - st * i
		var ww := w if i % 2 == 0 else w * 0.75
		balcony(x_face - ww if side < 0 else x_face, y, ww)

## Balcony stuck to a building face: slab (solid), railing, and support brackets underneath.
func balcony(x: float, y: float, w: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(x + w / 2.0, y + 7.0)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w, 14)
	cs.shape = rs
	cs.one_way_collision = true            # jump up through it from below, like a real balcony
	body.add_child(cs)
	var v := ColorRect.new()
	v.color = Color("7d8794")
	v.size = Vector2(w, 14)
	v.position = Vector2(-w / 2.0, -7.0)
	body.add_child(v)
	add_child(body)
	deco(Rect2(x - 2, y + 14, w + 4, 4), Color("1f2630"), -1)                    # underside lip
	deco(Rect2(x, y - 30, w, 3), Color("6b7787"), -1)                            # top rail
	for px in range(int(x), int(x + w) + 1, 16):
		deco(Rect2(px, y - 28, 3, 28), Color("525c6b"), -1)                      # railing posts
	for bx in [x + 10.0, x + w - 22.0]:
		var br := Polygon2D.new()                                                # brackets
		br.polygon = PackedVector2Array([Vector2(bx, y + 18), Vector2(bx + 12, y + 18), Vector2(bx + 12, y + 40)])
		br.color = Color("1f2630")
		br.z_index = -1
		add_child(br)

## Wall across the tier with a small door at its foot. The arm-shot button is mounted on the wall face
## (left side), so throw the arm at the wall to open the door. `wall` bottom edge is the floor.
func wall_door(wall: Rect2, door_h := 100.0) -> void:
	var floor_y := wall.end.y
	block(Rect2(wall.position.x, wall.position.y, wall.size.x, wall.size.y - door_h))   # wall above the door
	var open := gate(Rect2(wall.position.x + 4, floor_y - door_h, wall.size.x - 8, door_h))
	deco(Rect2(wall.position.x, floor_y - door_h - 4, wall.size.x, 4), Color("0d141b"), 3)   # door frame lintel
	# button panel bolted to the wall face
	var bx := wall.position.x
	deco(Rect2(bx - 14, floor_y - door_h - 62, 14, 44), Color("5d6d7e"), 2)
	shoot_button(Vector2(bx - 22, floor_y - door_h - 40), open)

## Building you can walk through: solid slabs with open horizontal corridors (bands [top_y, bottom_y]).
## rect bottom edge is the floor. Corridors run through from side to side.
func walk_building(rect: Rect2, corridors: Array, body_color := Color("2e3744")) -> void:
	var cs := corridors.duplicate()
	cs.sort_custom(func(p, q): return p[0] < q[0])
	var y := rect.position.y
	var slabs: Array = []
	for c in cs:
		if c[0] > y:
			slabs.append(Rect2(rect.position.x, y, rect.size.x, c[0] - y))
		y = c[1]
	if y < rect.end.y:
		slabs.append(Rect2(rect.position.x, y, rect.size.x, rect.end.y - y))
	for sl in slabs:
		block(sl)
		deco(sl, body_color, 0)
		for wy in range(int(sl.position.y) + 14, int(sl.end.y) - 30, 56):
			for wx in range(int(sl.position.x) + 20, int(sl.end.x) - 40, 56):
				deco(Rect2(wx, wy, 26, 30), Color("4b5d75"), 1)
	for c in cs:
		deco(Rect2(rect.position.x, c[0], rect.size.x, c[1] - c[0]), Color("12171e"), -3)   # dark interior
		for lx in range(int(rect.position.x) + 50, int(rect.end.x) - 20, 100):
			deco(Rect2(lx, c[0] + 6, 30, 5), Color("e8d98a"), -2)                         # ceiling lights
	deco(Rect2(rect.position.x - 6, rect.position.y - 8, rect.size.x + 12, 8), Color("1b222c"), 2)   # roof lip

## Wall from ceiling to floor with an elevator door at its foot (opened by the arm-shot button on its face).
func elevator_wall(x: float, w: float, door_h := 110.0) -> void:
	var f := floor_y
	var open := gate(Rect2(x + 3, f - door_h, w - 6, door_h))
	block(Rect2(x, 0, w, f - door_h))
	block(Rect2(x, f - door_h - 1, w, 1))
	deco(Rect2(x, 0, w, f - door_h), Color("3a4452"), 0)
	deco(Rect2(x - 5, f - door_h - 8, w + 10, 8), Color("e8c547"), 3)
	deco(Rect2(x + w / 2 - 14, f - door_h - 40, 28, 24), Color("1b222c"), 3)         # floor indicator
	deco(Rect2(x + w / 2 - 8, f - door_h - 34, 16, 12), Color("e8c547"), 4)
	deco(Rect2(x - 14, f - door_h - 62, 14, 44), Color("5d6d7e"), 2)                 # button panel
	shoot_button(Vector2(x - 22, f - door_h - 40), open)

## Elevator cab: stepping in closes the doors and it descends, then the next level loads.
func elevator_exit(rect: Rect2) -> void:
	deco(Rect2(rect.position.x - 20, rect.position.y - 60, rect.size.x + 40, rect.size.y + 60), Color("2b3138"), -3)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 8
	area.position = rect.position + rect.size / 2
	var sh := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	sh.shape = rs
	area.add_child(sh)
	add_child(area)
	var label := _make_prompt(area, Vector2(-70, -rect.size.y / 2 - 34))
	label.text = "Press [Enter] to go down"
	elev = {"inside": false, "busy": false, "label": label, "rect": rect}

var elev := {}

func _elevator_go() -> void:
	elev.busy = true
	elev.label.visible = false
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(player, "global_position:y", player.global_position.y + 160.0, 1.4)
	await get_tree().create_timer(0.4).timeout
	await _fade_to(1.0, 0.9)
	exited.emit()

# ---------------------------------------------------------------- keyed buttons, gates, train
const KEY_POOL := [KEY_G, KEY_H, KEY_J, KEY_K, KEY_L, KEY_U, KEY_I, KEY_O, KEY_P, KEY_B, KEY_N, KEY_M, KEY_T, KEY_Y]
var _free_keys: Array = []
var kbuttons: Array = []
var train_power := 0
var train_needed := 0
var train_root: Node2D
var train_zone: Area2D
var train_label: Label
var train_key := 0
var train_inside := false
var train_going := false

func _take_key() -> int:
	if _free_keys.is_empty():
		_free_keys = KEY_POOL.duplicate()
		_free_keys.shuffle()
	return _free_keys.pop_back()

func _make_prompt(parent: Node2D, at: Vector2) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color("ffe08a"))
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.visible = false
	parent.add_child(l)
	return l

## Floor button: stand on it and press its (random) key to trigger `cb`.
func key_button(pos: Vector2, cb: Callable, color := Color("e67e22"), fixed_key := -1, on_wall := false) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 8
	a.position = pos
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(70, 50)
	s.shape = r
	a.add_child(s)
	var v := ColorRect.new()
	v.color = color
	v.size = Vector2(44, 10)
	v.position = Vector2(-22, 20)
	if on_wall:
		# panel mounted on the background wall behind the player
		var plate := ColorRect.new()
		plate.color = Color("2a323c")
		plate.size = Vector2(40, 56)
		plate.position = Vector2(-20, -44)
		plate.z_index = -1
		a.add_child(plate)
		v.size = Vector2(24, 24)
		v.position = Vector2(-12, -34)
		v.z_index = 0
	a.add_child(v)
	var k: int = fixed_key if fixed_key >= 0 else _take_key()
	var l := _make_prompt(a, Vector2(-40, -34))
	l.text = "Press [%s]" % OS.get_keycode_string(k)
	var e := {"area": a, "key": k, "label": l, "visual": v, "inside": false, "done": false, "cb": cb}
	a.body_entered.connect(func(b):
		if b == player and not e.done:
			e.inside = true
			l.visible = true)
	a.body_exited.connect(func(b):
		if b == player:
			e.inside = false
			l.visible = false)
	add_child(a)
	kbuttons.append(e)

func _update_key_buttons() -> void:
	if not elev.is_empty() and not elev.busy:
		# only counts once the whole body is inside the cab
		var body := Rect2(player.global_position - Vector2(12, 22), Vector2(24, 44))
		elev.inside = (elev.rect as Rect2).encloses(body)
		elev.label.visible = elev.inside
		if elev.inside and Input.is_physical_key_pressed(KEY_ENTER):
			_elevator_go()
	for e in kbuttons:
		if e.inside and not e.done and Input.is_physical_key_pressed(e.key):
			e.done = true
			e.label.visible = false
			e.visual.color = Color("4cd964")
			e.cb.call()
	if train_zone != null and not train_going:
		if train_inside and train_power >= train_needed and Input.is_physical_key_pressed(train_key):
			_depart()

## Returns a callable that opens a solid door.
func gate(rect: Rect2) -> Callable:
	var d := StaticBody2D.new()
	d.collision_layer = 1
	d.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	d.add_child(s)
	var v := ColorRect.new()
	v.color = Color("c0392b")
	v.size = rect.size
	v.position = -rect.size / 2
	d.add_child(v)
	for i in int(rect.size.y / 30.0):
		var bar := ColorRect.new()
		bar.color = Color("7b241c")
		bar.size = Vector2(rect.size.x, 4)
		bar.position = Vector2(0, 14 + i * 30.0)
		v.add_child(bar)
	v.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(d)
	return func():
		s.set_deferred("disabled", true)
		var tw := d.create_tween()   # door retracts upward: closed -> open
		tw.tween_property(v, "size:y", 0.0, 0.7).set_trans(Tween.TRANS_QUAD)

## Button that powers the train. All `train_needed` of them must be pressed.
var tier_unlocked := {}      # tier index -> true once that tier's O button was pressed

func train_button(pos: Vector2) -> void:
	train_needed += 1
	var t := maxi(tier_starts.size() - 1, 0)
	key_button(pos, func():
		train_power += 1
		tier_unlocked[t] = true
		_refresh_train_label(), Color("3498db"), KEY_O, true)

func _refresh_train_label() -> void:
	if train_label == null:
		return
	if train_power >= train_needed:
		train_label.text = "Train ready! Press [%s]" % OS.get_keycode_string(train_key)
	else:
		train_label.text = "Train offline (%d/%d)" % [train_power, train_needed]

## Train standing at a platform. Enter it, press its key and it rides off to the right.
func train(rect: Rect2) -> void:
	train_root = Node2D.new()
	train_root.position = rect.position
	add_child(train_root)
	var body := ColorRect.new()
	body.color = Color("5d6d7e")
	body.size = rect.size
	body.z_index = -2
	train_root.add_child(body)
	var stripe := ColorRect.new()
	stripe.color = Color("e74c3c")
	stripe.size = Vector2(rect.size.x, 8)
	stripe.position = Vector2(0, rect.size.y - 24)
	stripe.z_index = -2
	train_root.add_child(stripe)
	var wx := 20.0
	while wx < rect.size.x - 60:
		var w := ColorRect.new()
		w.color = Color("f7dc6f")
		w.size = Vector2(46, 30)
		w.position = Vector2(wx, 16)
		w.z_index = -1
		train_root.add_child(w)
		wx += 80.0
	for wheel_x in [30.0, rect.size.x - 60.0]:
		var wh := ColorRect.new()
		wh.color = Color("1b1b1b")
		wh.size = Vector2(30, 14)
		wh.position = Vector2(wheel_x, rect.size.y - 10)
		train_root.add_child(wh)
	train_key = KEY_ENTER
	train_zone = Area2D.new()
	train_zone.collision_layer = 0
	train_zone.collision_mask = 8
	train_zone.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	train_zone.add_child(s)
	train_label = _make_prompt(train_zone, Vector2(-100, -rect.size.y / 2 - 30))
	train_label.visible = true
	_refresh_train_label()
	train_zone.body_entered.connect(func(b):
		if b == player: train_inside = true)
	train_zone.body_exited.connect(func(b):
		if b == player: train_inside = false)
	add_child(train_zone)

func _depart() -> void:
	train_going = true
	train_label.text = "All aboard..."
	player.set_physics_process(false)
	var dx := 1500.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(train_root, "position:x", train_root.position.x + dx, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(player, "position:x", player.position.x + dx, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func(): exited.emit())

# ---------------------------------------------------------------- timed obstacles (tower)
## Laser/sliding barrier that sweeps horizontally across a corridor. Kills on touch.
## Dash through the gap between sweeps, or time a jump over it.
func sweeper(y: float, x1: float, x2: float, seconds := 1.6, phase := 0.0, thick := 14.0) -> void:
	var a := Area2D.new()
	a.position = Vector2(x1, y)
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(70, thick)
	s.shape = r
	a.add_child(s)
	var v := ColorRect.new()
	v.color = Color("ff5d5d")
	v.size = Vector2(70, thick)
	v.position = Vector2(-35, -thick / 2)
	a.add_child(v)
	_kill_zone(a)
	add_child(a)
	var tw := a.create_tween().set_loops()
	if phase > 0.0:
		tw.tween_interval(phase)
	tw.tween_property(a, "position:x", x2, seconds).set_trans(Tween.TRANS_LINEAR)
	tw.tween_property(a, "position:x", x1, seconds).set_trans(Tween.TRANS_LINEAR)

## Pulse gate: a wall that is deadly while "on" and harmless while "off", repeating.
## Dash through it in the off window. A warning flicker precedes each activation.
func pulse_gate(rect: Rect2, on_time := 1.0, off_time := 1.2, phase := 0.0) -> void:
	var a := Area2D.new()
	a.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	s.disabled = true
	a.add_child(s)
	var v := ColorRect.new()
	v.color = Color("ff5d5d")
	v.size = rect.size
	v.position = -rect.size / 2
	v.modulate.a = 0.15
	a.add_child(v)
	_kill_zone(a)
	add_child(a)
	var tw := a.create_tween().set_loops()
	if phase > 0.0:
		tw.tween_interval(phase)
	tw.tween_property(v, "modulate:a", 0.6, off_time * 0.35)     # warning glow
	tw.tween_callback(func():
		s.set_deferred("disabled", false)
		v.modulate.a = 1.0)
	tw.tween_interval(on_time)
	tw.tween_callback(func():
		s.set_deferred("disabled", true)
		v.modulate.a = 0.15)
	tw.tween_interval(off_time * 0.65)

## Window with a sunset behind it (decoration).
func sunset_window(rect: Rect2) -> void:
	deco(rect.grow(10), Color("2b2238"), -6)
	var n := 10
	var cols := [Color("2e1f4d"), Color("5b2a6e"), Color("a33a74"), Color("e0575d"), Color("f2894f"), Color("f7b955"), Color("fbd785")]
	for i in n:
		var t := float(i) / (n - 1)
		var idx := t * (cols.size() - 1)
		var c: Color = (cols[int(floor(idx))] as Color).lerp(cols[mini(int(floor(idx)) + 1, cols.size() - 1)], idx - floor(idx))
		deco(Rect2(rect.position.x, rect.position.y + rect.size.y * t, rect.size.x, rect.size.y / n + 1), c, -5)
	deco(Rect2(rect.position.x + rect.size.x * 0.62 - 40, rect.position.y + rect.size.y * 0.66 - 40, 80, 80), Color("fff0b0"), -4)
	for i in 4:
		deco(Rect2(rect.position.x + 20 + i * 130, rect.position.y + rect.size.y * (0.35 + 0.1 * (i % 2)), 100, 10), Color(0.35, 0.2, 0.4, 0.7), -4)
	deco(Rect2(rect.position.x, rect.position.y + rect.size.y * 0.86, rect.size.x, rect.size.y * 0.14), Color("1d1626"), -3)
	for mx in range(0, int(rect.size.x), 60):
		deco(Rect2(rect.position.x + mx, rect.position.y + rect.size.y * (0.78 + 0.05 * float((mx / 60) % 3)), 40, rect.size.y * 0.2), Color("1d1626"), -3)
	# window frame bars
	deco(Rect2(rect.position.x + rect.size.x / 2 - 4, rect.position.y, 8, rect.size.y), Color("120f1a"), -2)
	deco(Rect2(rect.position.x, rect.position.y + rect.size.y / 2 - 4, rect.size.x, 8), Color("120f1a"), -2)

# ---------------------------------------------------------------- enemies
## Touching an enemy respawns you. A thrown arm that is still flying kills it.
func _enemy_area(pos: Vector2, size: Vector2) -> Area2D:
	var a := Area2D.new()
	a.position = pos
	a.collision_layer = 0
	a.collision_mask = 8 | 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	s.shape = r
	a.add_child(s)
	a.body_entered.connect(func(b):
		if b == player:
			player.call_deferred("_respawn"))
	# Poll overlaps so a recalled arm also kills an enemy it is already touching
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(func():
		for other in a.get_overlapping_areas():
			if other.is_in_group("arm") and other.get("state") != 1:
				a.queue_free()
				return)
	a.add_child(t)
	add_child(a)
	return a

## Rat: scurries back and forth along the floor between two x positions.
func rat(from: Vector2, to: Vector2, seconds := 2.5, once := false, drop := 0.0) -> Area2D:
	var a := _enemy_area(from, Vector2(26, 16))
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-13, 8), Vector2(-10, -4), Vector2(2, -8), Vector2(12, -2), Vector2(14, 8)])
	body.color = Color("8d7f74")
	a.add_child(body)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(-13, 5), Vector2(-24, 2), Vector2(-24, 4), Vector2(-13, 8)])
	tail.color = Color("c9a7a0")
	a.add_child(tail)
	var eye := ColorRect.new()
	eye.color = Color("ff4040")
	eye.size = Vector2(3, 3)
	eye.position = Vector2(7, -4)
	a.add_child(eye)
	if once:
		if to.x < from.x:
			a.scale.x = -1.0
		var tw1 := a.create_tween()
		if drop > 0.0:
			# comes out of the sewer pipe in the background wall, drops to the floor, then runs
			a.z_index = -3
			a.modulate.a = 0.0
			a.position = from + Vector2(0, -drop)
			tw1.tween_property(a, "modulate:a", 1.0, 0.2)
			tw1.tween_property(a, "position:y", from.y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw1.tween_callback(func(): a.z_index = 0)
		tw1.tween_property(a, "position", to, seconds)
		tw1.tween_callback(a.queue_free)
		return a
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "position", to, seconds)
	tw.tween_callback(func(): a.scale.x = -1.0)
	tw.tween_property(a, "position", from, seconds)
	tw.tween_callback(func(): a.scale.x = 1.0)
	return a

## Bird: flies back and forth along a wavy path.
func bird(from: Vector2, to: Vector2, seconds := 3.0, wave := 40.0, once := false, manual := false) -> Area2D:
	var a := _enemy_area(from, Vector2(28, 18))
	var wing_l := Polygon2D.new()
	wing_l.polygon = PackedVector2Array([Vector2(0, 0), Vector2(-16, -10), Vector2(-6, 4)])
	wing_l.color = Color("5d6d7e")
	a.add_child(wing_l)
	var wing_r := Polygon2D.new()
	wing_r.polygon = PackedVector2Array([Vector2(0, 0), Vector2(16, -10), Vector2(6, 4)])
	wing_r.color = Color("5d6d7e")
	a.add_child(wing_r)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-8, 2), Vector2(0, -5), Vector2(8, 2), Vector2(0, 8)])
	body.color = Color("34495e")
	a.add_child(body)
	var beak := Polygon2D.new()
	beak.polygon = PackedVector2Array([Vector2(6, 0), Vector2(14, 2), Vector2(6, 4)])
	beak.color = Color("f0b429")
	a.add_child(beak)
	var flap := a.create_tween().set_loops()
	flap.tween_property(wing_l, "scale:y", -1.0, 0.18)
	flap.parallel().tween_property(wing_r, "scale:y", -1.0, 0.18)
	flap.tween_property(wing_l, "scale:y", 1.0, 0.18)
	flap.parallel().tween_property(wing_r, "scale:y", 1.0, 0.18)
	if manual:
		return a            # caller moves it (diving roof birds)
	var base_y := from.y
	if once:
		# one pass, then it is gone (used by spawners)
		if to.x < from.x:
			a.scale.x = -1.0
		var tw1 := a.create_tween()
		tw1.tween_method(func(t: float):
			a.position = Vector2(lerpf(from.x, to.x, t), base_y + sin(t * TAU * 2.0) * wave), 0.0, 1.0, seconds)
		tw1.tween_callback(a.queue_free)
		return a
	var tw := a.create_tween().set_loops()
	tw.tween_method(func(t: float):
		a.position = Vector2(lerpf(from.x, to.x, t), base_y + sin(t * TAU * 2.0) * wave), 0.0, 1.0, seconds)
	tw.tween_callback(func(): a.scale.x = -1.0)
	tw.tween_method(func(t: float):
		a.position = Vector2(lerpf(to.x, from.x, t), base_y + sin(t * TAU * 2.0) * wave), 0.0, 1.0, seconds)
	tw.tween_callback(func(): a.scale.x = 1.0)
	return a

## A new bird flies across from `from` to `to` every `interval` seconds (first one right away).
func bird_spawner(from: Vector2, to: Vector2, seconds := 3.5, wave := 10.0, interval := 10.0) -> void:
	_spawner(func(): bird(from, to, seconds, wave, true), interval)

## A new rat runs from `from` to `to` every `interval` seconds (first one right away).
func rat_spawner(from: Vector2, to: Vector2, seconds := 4.0, interval := 10.0) -> void:
	var drop := 90.0
	var py := from.y - drop - 14.0
	# sewer pipe on the background wall: a rusty elbow with a dark mouth
	deco(Rect2(from.x - 60, py - 22, 90, 44), Color("3a4a55"), -4)
	deco(Rect2(from.x - 60, py - 22, 90, 6), Color("55687a"), -4)
	deco(Rect2(from.x - 28, py - 28, 56, 56), Color("4a5d6b"), -4)
	deco(Rect2(from.x - 20, py - 20, 40, 40), Color("0a0f14"), -4)
	deco(Rect2(from.x - 6, py + 20, 12, 8), Color("2f6b4a"), -4)           # slime drip
	_spawner(func(): rat(from, to, seconds, true, drop), interval)

func _spawner(spawn_fn: Callable, interval: float) -> void:
	var t := Timer.new()
	t.wait_time = interval
	t.one_shot = false
	t.autostart = true
	t.timeout.connect(spawn_fn)
	add_child(t)
	spawn_fn.call()

# ---------------------------------------------------------------- diving roof birds
var roof_birds: Array = []        # [{node, roof, state, t, target}]; state 0 track, 1 dive, 2 rise
const ROOF_BIRD_CAP := 5

## Every `interval` seconds a bird spawns high above `roof`. It tracks the player, dives at them, and if it
## misses it climbs back up (it never leaves by itself). At most ROOF_BIRD_CAP roof birds exist at once:
## when a new one spawns past the cap, the oldest goes away.
func roof_bird_spawner(roof: Rect2, interval := 10.0) -> void:
	_spawner(func(): _spawn_roof_bird(roof), interval)

func _spawn_roof_bird(roof: Rect2) -> void:
	roof_birds = roof_birds.filter(func(e): return is_instance_valid(e.node))
	while roof_birds.size() >= ROOF_BIRD_CAP:
		var old = roof_birds.pop_front()
		old.node.queue_free()
	var x := randf_range(roof.position.x + 30.0, roof.end.x - 30.0)
	var y := roof.position.y - 340.0
	var a := bird(Vector2(x, y), Vector2(x, y), 1.0, 0.0, false, true)
	roof_birds.append({"node": a, "roof": roof, "state": 0, "t": randf_range(1.2, 2.2), "target": Vector2.ZERO})

func _update_divers(delta: float) -> void:
	for e in roof_birds:
		var n: Area2D = e.node
		if not is_instance_valid(n):
			continue
		var roof: Rect2 = e.roof
		var hover_y := roof.position.y - 260.0
		var pp: Vector2 = player.global_position
		if e.state == 0:
			var tx := clampf(pp.x, roof.position.x - 60.0, roof.end.x + 60.0)
			n.position.x = move_toward(n.position.x, tx, 130.0 * delta)
			n.position.y = move_toward(n.position.y, hover_y, 200.0 * delta)
			if absf(tx - n.position.x) > 3.0:
				n.scale.x = 1.0 if tx > n.position.x else -1.0
			e.t -= delta
			if e.t <= 0.0:
				var near := absf(pp.x - n.position.x) < 260.0 and pp.y < roof.position.y + 40.0 and pp.y > hover_y - 100.0
				if near:
					e.state = 1
					e.target = Vector2(pp.x, minf(pp.y, roof.position.y + 10.0))
				else:
					e.t = 0.4
		elif e.state == 1:
			var to: Vector2 = (e.target as Vector2) - n.position
			n.rotation = to.angle() * 0.0
			if to.length() < 10.0:
				e.state = 2
			else:
				n.position += to.normalized() * minf(560.0 * delta, to.length())
		else:
			n.position.y = move_toward(n.position.y, hover_y, 220.0 * delta)
			if absf(n.position.y - hover_y) < 2.0:
				e.state = 0
				e.t = randf_range(0.8, 1.6)

# ---------------------------------------------------------------- lift that waits for you
## Platform at `rect` that stays put until the player is really standing on it, then carries them down by
## `drop`, waits, and returns to the top.
func stand_lift(rect: Rect2, drop: float, down_time := 3.0) -> void:
	var b := AnimatableBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	b.set_meta("stand_lift", true)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	cs.shape = rs
	b.add_child(cs)
	var v := ColorRect.new()
	v.color = Color("e08a2e")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	for i in int(rect.size.x / 24.0):
		var st2 := ColorRect.new()
		st2.color = Color("3a2a10")
		st2.size = Vector2(8, rect.size.y)
		st2.position = Vector2(-rect.size.x / 2 + 6 + i * 24.0, -rect.size.y / 2)
		b.add_child(st2)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 8
	sensor.position = Vector2(0, -rect.size.y / 2 - 14)
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(rect.size.x - 16, 28)
	ss.shape = sr
	sensor.add_child(ss)
	b.add_child(sensor)
	add_child(b)
	var top := b.position
	var st := {"busy": false}
	sensor.body_entered.connect(func(body):
		if body != player or st.busy:
			return
		st.busy = true
		var standing := false
		var waited := 0.0
		while waited < 0.8 and not standing:
			await get_tree().create_timer(0.05).timeout
			waited += 0.05
			if not sensor.overlaps_body(player):
				break
			standing = player.is_on_floor() and player.global_position.y < b.position.y \
				and absf(player.global_position.x - b.position.x) < rect.size.x / 2 - 8.0
		if not standing:
			st.busy = false
			return
		await get_tree().create_timer(0.35).timeout
		var tw := create_tween()
		tw.tween_property(b, "position", top + Vector2(0, drop), down_time).set_trans(Tween.TRANS_SINE)
		await tw.finished
		await get_tree().create_timer(2.0).timeout
		var tw2 := create_tween()
		tw2.tween_property(b, "position", top, down_time).set_trans(Tween.TRANS_SINE)
		await tw2.finished
		st.busy = false)

## Trap that is deadly all the time but only drawn while x-ray eyes are on.
func hidden_trap(rect: Rect2) -> void:
	var a := Area2D.new()
	a.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(rect.size.x, rect.size.y * 0.8)
	s.shape = r
	s.position.y = rect.size.y * 0.1
	a.add_child(s)
	var n := maxi(1, int(rect.size.x / 14.0))
	var w := rect.size.x / n
	for i in n:
		var t := Polygon2D.new()
		var x := -rect.size.x / 2 + i * w
		t.polygon = PackedVector2Array([Vector2(x, rect.size.y / 2), Vector2(x + w / 2, -rect.size.y / 2), Vector2(x + w, rect.size.y / 2)])
		t.color = Color("4fd1c5")
		a.add_child(t)
	_kill_zone(a)
	a.visible = false
	add_child(a)
	xray_nodes.append({"node": a, "body": false, "hook": false})

# ---------------------------------------------------------------- arm-shot button
var shoot_buttons: Array = []

## Button you trigger by hitting it with the thrown arm (right-click toward it, or Q). Calls `cb` once.
func shoot_button(pos: Vector2, cb: Callable) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2   # the thrown arm
	a.position = pos
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(110, 80)
	s.shape = r
	a.add_child(s)
	var post := ColorRect.new()
	post.color = Color("5d6d7e")
	post.size = Vector2(8, 36)
	post.position = Vector2(-4, 20)
	a.add_child(post)
	var v := ColorRect.new()
	v.color = Color("ff7a1a")
	v.size = Vector2(30, 30)
	v.position = Vector2(-15, -10)
	a.add_child(v)
	var ring := ColorRect.new()
	ring.color = Color("ffe08a")
	ring.size = Vector2(14, 14)
	ring.position = Vector2(-7, -2)
	a.add_child(ring)
	var hint := _make_prompt(a, Vector2(-62, -46))
	hint.text = "Right-click: throw arm"
	hint.add_theme_font_size_override("font_size", 15)
	hint.visible = true
	var e := {"area": a, "done": false}
	a.area_entered.connect(func(o):
		if e.done or not o.is_in_group("arm"):
			return
		e.done = true
		v.color = Color("4cd964")
		hint.visible = false
		cb.call())
	add_child(a)
	shoot_buttons.append(e)

# ---------------------------------------------------------------- lift between stacked tiers
var _fade: ColorRect

func _fade_to(a: float, t: float) -> void:
	if _fade == null:
		var layer := CanvasLayer.new()
		layer.layer = 9
		_fade = ColorRect.new()
		_fade.color = Color.BLACK
		_fade.size = Vector2(4000, 3000)
		_fade.modulate.a = 0.0
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_fade)
		add_child(layer)
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", a, t)
	await tw.finished

## Elevator platform in a floor gap. Step on it: it sinks `drop` px, the screen fades, and you
## reappear at `dest` (left side of the next tier). Respawns then use `dest`.
func lift(rect: Rect2, drop: float, dest: Vector2) -> void:
	var b := AnimatableBody2D.new()
	b.collision_layer = 1
	b.sync_to_physics = true
	b.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	b.add_child(s)
	var v := ColorRect.new()
	v.color = Color("e8c547")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 8
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(rect.size.x - 10, 24)
	ss.shape = sr
	ss.position.y = -rect.size.y / 2 - 12
	sensor.add_child(ss)
	b.add_child(sensor)
	add_child(b)
	var start_y := b.position.y
	var st := {"busy": false}
	sensor.body_entered.connect(func(body):
		if body != player or st.busy:
			return
		st.busy = true
		await get_tree().create_timer(0.4).timeout
		var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_property(b, "position:y", start_y + drop, 1.8).set_trans(Tween.TRANS_SINE)
		await tw.finished
		await _fade_to(1.0, 0.35)
		player.global_position = dest
		player.velocity = Vector2.ZERO
		player.spawn_point = dest
		b.position.y = start_y
		await get_tree().create_timer(0.15).timeout
		await _fade_to(0.0, 0.35)
		st.busy = false)

# ---------------------------------------------------------------- escalator between stacked tiers
## Moving stripes inside a rect (escalator look). Dark panel, stripes scroll downward.
func _stripes(rect: Rect2, z := -3) -> Control:
	var panel := ColorRect.new()
	panel.color = Color("1a222c")
	panel.position = rect.position
	panel.size = rect.size
	panel.z_index = z
	panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var holder := Control.new()
	panel.add_child(holder)
	var n := int(rect.size.y / 28.0) + 3
	for i in n:
		var st := ColorRect.new()
		st.color = Color("3b4a5c")
		st.size = Vector2(rect.size.x, 8)
		st.position = Vector2(0, -28 + i * 28.0)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(st)
	var tw := holder.create_tween().set_loops()
	tw.tween_property(holder, "position:y", 28.0, 0.5)
	tw.tween_callback(func(): holder.position.y = 0.0)
	return panel

## Staircase going down-right from `a` to `b` (45 degrees): dark filled steps with lit treads.
func _diag_shaft(a: Vector2, b: Vector2) -> Array:
	var made: Array = []
	var step := 30.0
	var n := int(round((b.x - a.x) / step))
	var pts := PackedVector2Array()
	for i in n:
		pts.append(a + Vector2(i * step, i * step))
		pts.append(a + Vector2((i + 1) * step, i * step))
	pts.append(b)
	pts.append(Vector2(b.x, b.y + 36.0))
	pts.append(Vector2(a.x, a.y + 36.0))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = Color("1a222c")
	poly.z_index = -2
	add_child(poly)
	made.append(poly)
	for i in n:
		var t := ColorRect.new()
		t.color = Color("7d8fa6")
		t.position = a + Vector2(i * step, i * step)
		t.size = Vector2(step, 5)
		t.z_index = -1
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
		made.append(t)
		var r := ColorRect.new()
		r.color = Color("3b4a5c")
		r.position = a + Vector2((i + 1) * step - 4, i * step + 5)
		r.size = Vector2(4, step - 5)
		r.z_index = -1
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		made.append(r)
	return made

const ESC_DX := 330.0
const ESC_DY := 330.0

## Escalator plate flush with the floor. Step on it: the camera freezes and you ride diagonally down and to
## the right until you leave the frame. The camera then cuts to the next tier (not visible until now) and you
## slide in diagonally from out of frame at the upper left, down-right onto its floor.
func escalator(plate: Rect2, dest_x: float, dest_floor_y: float) -> void:
	var top := Vector2(plate.position.x + plate.size.x / 2, plate.position.y)
	_diag_shaft(top, top + Vector2(ESC_DX, ESC_DY))
	var land := Vector2(dest_x, dest_floor_y - 22.0)
	var arrival := _diag_shaft(Vector2(dest_x - ESC_DX, dest_floor_y - ESC_DY), Vector2(dest_x, dest_floor_y))   # arrival side
	var next_tier := active_tier_for(plate.position.y) + 1
	for n in arrival:
		n.set_meta("tier", next_tier)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = plate.position + plate.size / 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = plate.size
	cs.shape = r
	body.add_child(cs)
	var v := ColorRect.new()
	v.color = Color("e8c547")
	v.size = plate.size
	v.position = -plate.size / 2
	body.add_child(v)
	for i in int(plate.size.x / 20.0):
		var chev := ColorRect.new()
		chev.color = Color("9a7d1f")
		chev.size = Vector2(4, plate.size.y)
		chev.position = Vector2(-plate.size.x / 2 + 8 + i * 20.0, -plate.size.y / 2)
		body.add_child(chev)
	add_child(body)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 8
	sensor.position = plate.position + Vector2(plate.size.x / 2, -16)
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(plate.size.x - 24, 32)
	ss.shape = sr
	sensor.add_child(ss)
	add_child(sensor)
	var st := {"busy": false}
	var my_tier := active_tier_for(plate.position.y)
	var lock_label := _make_prompt(sensor, Vector2(-90, -52))
	lock_label.text = "Locked. Press [O] on the wall panel first"
	lock_label.add_theme_font_size_override("font_size", 15)
	v.color = Color("7a3b3b")                        # red until the O button unlocks it
	var lock_timer := Timer.new()
	lock_timer.wait_time = 0.1
	lock_timer.autostart = true
	lock_timer.timeout.connect(func():
		if tier_unlocked.get(my_tier, false):
			v.color = Color("e8c547")
			lock_label.visible = false
			lock_timer.queue_free())
	add_child(lock_timer)
	sensor.body_exited.connect(func(b):
		if b == player and not tier_unlocked.get(my_tier, false):
			lock_label.visible = false)
	sensor.body_entered.connect(func(b):
		if b != player or st.busy:
			return
		if not tier_unlocked.get(my_tier, false):
			lock_label.visible = true                # shown while you stand on it
			return
		st.busy = true
		riding = true
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
		cam_locked = true
		cs.set_deferred("disabled", true)
		body.visible = false
		var tw := create_tween()
		tw.tween_property(player, "global_position", top + Vector2(ESC_DX, ESC_DY + 18.0), 1.4).set_trans(Tween.TRANS_LINEAR)
		await tw.finished
		# --- cut: next tier. The camera jumps while you are out of frame.
		player.global_position = land - Vector2(ESC_DX, ESC_DY + 40.0)
		player.spawn_point = Vector2(dest_x, dest_floor_y - 40.0)
		cam_snap = Vector2(dest_x, dest_floor_y - 40.0)
		set_tier(next_tier)
		await get_tree().process_frame
		await get_tree().process_frame
		var tw2 := create_tween()
		tw2.tween_property(player, "global_position", land, 1.2).set_trans(Tween.TRANS_LINEAR)
		await tw2.finished
		cam_locked = false
		riding = false
		player.velocity = Vector2.ZERO
		player.set_physics_process(true)
		cs.set_deferred("disabled", false)
		body.visible = (active_tier == next_tier - 1)
		st.busy = false)

## Walk into it to set your respawn point (small flag).
func checkpoint(pos: Vector2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 8
	a.position = pos
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(60, 90)
	s.shape = r
	a.add_child(s)
	var pole := ColorRect.new()
	pole.color = Color("bdc3c7")
	pole.size = Vector2(4, 44)
	pole.position = Vector2(-2, -22)
	a.add_child(pole)
	var flag := ColorRect.new()
	flag.color = Color("7f8c8d")
	flag.size = Vector2(18, 12)
	flag.position = Vector2(2, -22)
	a.add_child(flag)
	a.body_entered.connect(func(b):
		if b == player:
			player.spawn_point = pos + Vector2(0, 20)
			flag.color = Color("4cd964"))
	add_child(a)
