extends Node2D
## Movement test room. Built in code so it never conflicts with teammates' scenes.

var door: StaticBody2D
var door_shape: CollisionShape2D
var plate_count := 0
var hud: Label
var player

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("14181f"))
	# Ground, gap in the middle, steps, high ledge (needs jet legs)
	_block(Rect2(0, 660, 900, 60))
	_block(Rect2(1200, 660, 1100, 60))
	_block(Rect2(-40, -400, 40, 1200))
	_block(Rect2(2300, -400, 40, 1200))
	_block(Rect2(350, 570, 140, 20))
	_block(Rect2(580, 480, 140, 20))
	_block(Rect2(2000, 400, 220, 20))     # high ledge: grapple the wall, then dash/jump onto it
	_block(Rect2(1900, 150, 40, 510))     # tall wall to grapple onto
	_hook(Vector2(1050, 400))             # grapple across the gap

	# Switch + door: throw the right arm onto the plate
	_plate(Rect2(1500, 650, 70, 10))
	door = StaticBody2D.new()
	door.collision_layer = 1
	door_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, 300)
	door_shape.shape = r
	door.add_child(door_shape)
	door.position = Vector2(1750, 510)
	var dv := ColorRect.new()
	dv.color = Color("c0392b")
	dv.size = Vector2(24, 300)
	dv.position = Vector2(-12, -150)
	door.add_child(dv)
	add_child(door)

	# Secret collectible on the ledge
	var c := Area2D.new()
	c.position = Vector2(2110, 370)
	var cs := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(20, 20)
	cs.shape = cr
	c.add_child(cs)
	var cv := ColorRect.new()
	cv.color = Color("f1c40f")
	cv.size = Vector2(20, 20)
	cv.position = Vector2(-10, -10)
	c.add_child(cv)
	c.body_entered.connect(func(b):
		if b == player:
			c.queue_free()
			found_log = true)
	add_child(c)

	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector2(100, 620)
	add_child(player)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	player.add_child(cam)

	var layer := CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(12, 8)
	layer.add_child(hud)
	add_child(layer)

var found_log := false

func _process(_d: float) -> void:
	if player:
		hud.text = "A/D move  Space jump  Shift dash  E grapple (aim with keys)  Q throw/recall arm (Down+Q drop)  R respawn\ndash: %s   grapple: %s   arm: %s" % [
			"ready" if player.can_dash else "spent", "ready" if player.can_grapple else "spent",
			"detached" if player.arm else "attached"]
		if found_log:
			hud.text += "\n[Secret data log found!]"

func _block(rect: Rect2) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	b.add_child(s)
	var v := ColorRect.new()
	v.color = Color("3b4656")
	v.size = rect.size
	v.position = -rect.size / 2
	b.add_child(v)
	add_child(b)

func _hook(pos: Vector2) -> void:
	var h := Node2D.new()
	h.position = pos
	h.add_to_group("hook")
	var v := ColorRect.new()
	v.color = Color("6bd36b")
	v.size = Vector2(16, 16)
	v.position = Vector2(-8, -8)
	h.add_child(v)
	add_child(h)

func _plate(rect: Rect2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2   # only the detached arm
	a.position = rect.position + rect.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	s.shape = r
	a.add_child(s)
	var v := ColorRect.new()
	v.color = Color("e67e22")
	v.size = rect.size
	v.position = -rect.size / 2
	a.add_child(v)
	a.area_entered.connect(func(_a):
		plate_count += 1
		_update_door())
	a.area_exited.connect(func(_a):
		plate_count -= 1
		_update_door())
	add_child(a)

func _update_door() -> void:
	var open := plate_count > 0
	door_shape.set_deferred("disabled", open)
	door.modulate.a = 0.2 if open else 1.0
