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
