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

func build() -> void:
	Rooms.build(self, room_id)

func _ready() -> void:
	RenderingServer.set_default_clear_color(bg_color)
	var bg := Backgrounds.make(room_id)
	if bg:
		add_child(bg)
	_border()
	build()
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
	block(Rect2(-40, -40, 1360, 40))
	block(Rect2(-40, 0, 40, 760))
	block(Rect2(1280, 0, 40, 760))

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
		var tw := b.create_tween().set_loops(8)
		tw.tween_property(v, "position:x", -rect.size.x / 2 + 3, 0.04)
		tw.tween_property(v, "position:x", -rect.size.x / 2 - 3, 0.04)
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
