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
var cam_snap := Vector2.INF      # set to cut the camera to a new spot
var width := 1280.0   # room width in px; wider rooms scroll with the camera

func build() -> void:
	Rooms.build(self, room_id)

func _ready() -> void:
	RenderingServer.set_default_clear_color(bg_color)
	build()
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
		e.node.visible = on
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
func crumble(rect: Rect2) -> void:
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
		await get_tree().create_timer(1.8).timeout
		s.set_deferred("disabled", false)
		b.visible = true
		state.busy = false)
	add_child(b)

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
	block(Rect2(x, 604, 190, 36))
	block(Rect2(x + 40, 570, 100, 34))
	deco(Rect2(x + 52, 576, 34, 22), Color("9fc3d6"), 1)
	deco(Rect2(x + 94, 576, 34, 22), Color("9fc3d6"), 1)
	deco(Rect2(x + 24, 626, 30, 14), Color("1b1b1b"), 2)
	deco(Rect2(x + 136, 626, 30, 14), Color("1b1b1b"), 2)

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
func key_button(pos: Vector2, cb: Callable, color := Color("e67e22"), fixed_key := -1) -> void:
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
func train_button(pos: Vector2) -> void:
	train_needed += 1
	key_button(pos, func():
		train_power += 1
		_refresh_train_label(), Color("3498db"), KEY_O)

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
func rat(from: Vector2, to: Vector2, seconds := 2.5) -> void:
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
	var tw := a.create_tween().set_loops()
	tw.tween_property(a, "position", to, seconds)
	tw.tween_callback(func(): a.scale.x = -1.0)
	tw.tween_property(a, "position", from, seconds)
	tw.tween_callback(func(): a.scale.x = 1.0)

## Bird: flies back and forth along a wavy path.
func bird(from: Vector2, to: Vector2, seconds := 3.0, wave := 40.0) -> void:
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
	var base_y := from.y
	var tw := a.create_tween().set_loops()
	tw.tween_method(func(t: float):
		a.position = Vector2(lerpf(from.x, to.x, t), base_y + sin(t * TAU * 2.0) * wave), 0.0, 1.0, seconds)
	tw.tween_callback(func(): a.scale.x = -1.0)
	tw.tween_method(func(t: float):
		a.position = Vector2(lerpf(to.x, from.x, t), base_y + sin(t * TAU * 2.0) * wave), 0.0, 1.0, seconds)
	tw.tween_callback(func(): a.scale.x = 1.0)

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

## Open escalator shaft above the arrival spot (you slide in from out of frame).
func arrival_shaft(rect: Rect2) -> void:
	_stripes(rect)

## Escalator plate flush with the floor. Step on it: the camera freezes, you ride straight down out of
## the bottom of the frame, the camera cuts to the next tier, and you slide in from above its left side.
func escalator(plate: Rect2, dest_x: float, dest_floor_y: float) -> void:
	var shaft := _stripes(Rect2(plate.position.x, plate.position.y, plate.size.x, 120), -4)
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
	sensor.body_entered.connect(func(b):
		if b != player or st.busy:
			return
		st.busy = true
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
		cam_locked = true
		cs.set_deferred("disabled", true)
		body.visible = false
		var cx := plate.position.x + plate.size.x / 2
		var tw := create_tween()
		tw.tween_property(player, "global_position", Vector2(cx, plate.position.y + 330.0), 1.3).set_trans(Tween.TRANS_LINEAR)
		await tw.finished
		# --- cut: next tier. The camera jumps while you are out of frame.
		player.global_position = Vector2(dest_x, dest_floor_y - 345.0)
		player.spawn_point = Vector2(dest_x, dest_floor_y - 40.0)
		cam_snap = Vector2(dest_x, dest_floor_y - 40.0)
		await get_tree().process_frame
		await get_tree().process_frame
		var tw2 := create_tween()
		tw2.tween_property(player, "global_position", Vector2(dest_x, dest_floor_y - 22.0), 1.1).set_trans(Tween.TRANS_LINEAR)
		await tw2.finished
		cam_locked = false
		player.velocity = Vector2.ZERO
		player.set_physics_process(true)
		cs.set_deferred("disabled", false)
		body.visible = true
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
