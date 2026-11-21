extends Node2D
## Level 1 (Surface). Collision traced over assets/concept/level1_surface.png.
## Coordinates below are in the painting's 1024px space; K scales them to the world.

const K := 1.25
var player
var hud: Label
var goal: Area2D
var cleared := false

func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/concept/level1_surface.png")
	bg.centered = false
	bg.scale = Vector2(K, K)
	bg.z_index = -10
	add_child(bg)

	# Left ground, right ground, pit floor, outer walls
	_block(Rect2(0, 740, 380, 300))
	_block(Rect2(560, 795, 464, 245))
	_block(Rect2(380, 1000, 180, 40))
	_block(Rect2(-40, -200, 40, 1400))
	_block(Rect2(1024, -200, 40, 1400))
	_block(Rect2(0, -40, 1024, 40))
	# Floating vine platforms: stepping stones up the middle
	_block(Rect2(355, 700, 160, 14))
	_block(Rect2(590, 545, 160, 14))
	_block(Rect2(355, 405, 165, 14))
	_block(Rect2(640, 375, 110, 14))
	# Grapple hooks over the gap
	_hook(Vector2(470, 520))
	_hook(Vector2(560, 300))

	goal = Area2D.new()
	goal.position = _p(Vector2(700, 340))
	var gs := CollisionShape2D.new()
	var gr := RectangleShape2D.new()
	gr.size = Vector2(60, 60)
	gs.shape = gr
	goal.add_child(gs)
	var gv := ColorRect.new()
	gv.color = Color(0.9, 1.0, 0.5, 0.6)
	gv.size = Vector2(60, 60)
	gv.position = Vector2(-30, -30)
	goal.add_child(gv)
	goal.body_entered.connect(func(b):
		if b == player:
			cleared = true)
	add_child(goal)

	player = preload("res://scenes/player.tscn").instantiate()
	player.position = _p(Vector2(90, 700))
	add_child(player)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_right = int(1024 * K)
	cam.limit_top = 0
	cam.limit_bottom = int(1040 * K)
	player.add_child(cam)

	# Chapter 0 intro dialogue (teammates' dialogue box); player is frozen until it ends
	var dlg = preload("res://scenes/dialogue_box.tscn").instantiate()
	player.set_physics_process(false)
	dlg.finished.connect(func(): player.set_physics_process(true))
	add_child(dlg)

	var layer := CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(12, 8)
	layer.add_child(hud)
	add_child(layer)

func _process(_d: float) -> void:
	if player:
		hud.text = "A/D move  Space jump  Shift dash  Click/E grapple  Q throw/recall arm  R respawn\ndash: %s   grapple: %s   arm: %s" % [
			"ready" if player.can_dash else "spent", "ready" if player.can_grapple else "spent",
			"detached" if player.arm else "attached"]
		if cleared:
			hud.text += "\nLEVEL CLEAR"

func _p(v: Vector2) -> Vector2:
	return v * K

func _block(rect: Rect2) -> void:
	var r2 := Rect2(rect.position * K, rect.size * K)
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = r2.position + r2.size / 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = r2.size
	s.shape = r
	b.add_child(s)
	add_child(b)

func _hook(pos: Vector2) -> void:
	var h := Node2D.new()
	h.position = _p(pos)
	h.add_to_group("hook")
	var v := ColorRect.new()
	v.color = Color("6bd36b")
	v.size = Vector2(16, 16)
	v.position = Vector2(-8, -8)
	h.add_child(v)
	add_child(h)
