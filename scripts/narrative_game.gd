extends Node2D
## Runs all 6 levels. Levels live in levels_data.gd (ASCII maps), story in narrative/dialogue/*.json.
## Art is placeholder rectangles drawn in _draw(); replace with sprites later.
## Keys: A/D or arrows move, Space (or Z) jump (needs leg), E throw arm (hold Up = throw up),
## hold X = x-ray (needs eye), F grapple (needs grapple arm), Shift dash (needs jet legs),
## R restart level, Enter/Space advances dialogue.

const TILE := 32
const MAP_W := 40
const MAP_H := 20
const PW := 20.0
const PH := 30.0
const Y_OFFSET := 40.0
const LevelsData := preload("res://scripts/levels_data.gd")
const DialogueScene := preload("res://scenes/dialogue_box.tscn")
const ENDING_DIALOGUE := "res://narrative/dialogue/ending_memory.json"
const MEMORY_IMAGE := "res://assets/sprites/memory_house.png"

var level_i := 0
var map: Array = []
var owned := {}
var spawn := Vector2.ZERO
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var facing := 1
var coyote := 0.0
var on_ground := false
var doors_open := {"S": false, "T": false}
var weak_left := 0
var arm_on := false
var arm_pos := Vector2.ZERO
var arm_dir := Vector2.RIGHT
var arm_dist := 0.0
var arm_cooldown := 0.0
var grapple_to: Variant = null
var dash_t := 0.0
var dash_used := false
var xray := false
var talking := false
var finished_game := false
var toast_text := ""
var toast_t := 0.0
var flash_t := 0.0
var _jump_prev := false
var _arm_prev := false
var _grap_prev := false
var _dash_prev := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	load_level(0)


const LEVEL_BG := [
	"res://assets/backgrounds/lvl1_lab.png",
	"res://assets/backgrounds/lvl2_city.png",
	"res://assets/backgrounds/lvl3_subway.png",
	"res://assets/backgrounds/lvl4_skyway.png",
	"res://assets/backgrounds/lvl5_tower.png",
	"res://assets/backgrounds/lvl6_roof.png",
]
var bg_layer: CanvasLayer
var plat_tex: Texture2D
var limb_tex := {}

func _limb_texture(name: String) -> Texture2D:
	if not limb_tex.has(name):
		var path := "res://assets/sprites/limbs/clean/%s.png" % name
		limb_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return limb_tex[name]

## Draw a limb sprite fitted inside a box of size px, centred on c.
func _draw_limb(name: String, c: Vector2, px: float, tint := Color.WHITE) -> bool:
	var t := _limb_texture(name)
	if t == null:
		return false
	var s := t.get_size()
	var k := px / maxf(s.x, s.y)
	var sz := s * k
	draw_texture_rect(t, Rect2(c - sz / 2.0, sz), false, tint)
	return true

func _set_background(i: int) -> void:
	if bg_layer:
		bg_layer.queue_free()
		bg_layer = null
	var bg := Backgrounds.make_from_file(LEVEL_BG[i], func(): return pos)
	if bg == null:
		return
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	bg_layer.add_child(bg)
	add_child(bg_layer)

func load_level(i: int) -> void:
	_set_background(i)
	level_i = i
	var data: Dictionary = LevelsData.LEVELS[i]
	map = (data["map"] as Array).duplicate()
	plat_tex = PlatformTiles.build(map, i)
	doors_open = {"S": false, "T": false}
	weak_left = 0
	for j in range(i):
		var l: String = LevelsData.LEVELS[j]["limb"]
		if l != "":
			owned[l] = true
	for r in range(MAP_H):
		for c in range(MAP_W):
			var ch := tile(c, r)
			if ch == "P":
				spawn = Vector2(c * TILE + TILE / 2.0, (r + 1) * TILE)
				set_tile(c, r, ".")
			elif ch == "W":
				weak_left += 1
	arm_on = false
	respawn()
	play_dialogue(data["dialogue"])
	queue_redraw()


func respawn() -> void:
	pos = spawn
	vel = Vector2.ZERO
	grapple_to = null
	dash_t = 0.0
	arm_on = false
	flash_t = 0.25


func play_dialogue(path: String) -> void:
	talking = true
	var box := DialogueScene.instantiate()
	box.dialogue_file = path
	box.finished.connect(func():
		talking = false
		box.queue_free())
	add_child(box)


func tile(c: int, r: int) -> String:
	if c < 0 or r < 0 or c >= MAP_W or r >= MAP_H:
		return "#"
	return (map[r] as String)[c]


func set_tile(c: int, r: int, ch: String) -> void:
	var row: String = map[r]
	map[r] = row.substr(0, c) + ch + row.substr(c + 1)


func is_solid(c: int, r: int) -> bool:
	match tile(c, r):
		"#":
			return true
		"H":
			return xray
		"D":
			return not doors_open["S"]
		"F":
			return not doors_open["T"]
	return false


func box_hits(p: Vector2) -> bool:
	var c1 := int(floor((p.x - PW / 2.0) / TILE))
	var c2 := int(floor((p.x + PW / 2.0 - 0.01) / TILE))
	var r1 := int(floor((p.y - PH) / TILE))
	var r2 := int(floor((p.y - 0.01) / TILE))
	for r in range(r1, r2 + 1):
		for c in range(c1, c2 + 1):
			if is_solid(c, r):
				return true
	return false


func key(k: Key) -> bool:
	return Input.is_physical_key_pressed(k)


func tile_center(c: int, r: int) -> Vector2:
	return Vector2(c * TILE + TILE / 2.0, r * TILE + TILE / 2.0)


func toast(t: String) -> void:
	toast_text = t
	toast_t = 3.0


func _physics_process(dt: float) -> void:
	toast_t = max(0.0, toast_t - dt)
	flash_t = max(0.0, flash_t - dt)
	if key(KEY_R) and not talking and not finished_game:
		respawn()
	if talking or finished_game:
		queue_redraw()
		return

	xray = owned.has("eye") and key(KEY_X)
	var left := key(KEY_A) or key(KEY_LEFT)
	var right := key(KEY_D) or key(KEY_RIGHT)
	var up := key(KEY_W) or key(KEY_UP)
	var jump_now := key(KEY_SPACE) or key(KEY_Z)
	var jump_pressed := jump_now and not _jump_prev
	_jump_prev = jump_now
	var dir := int(right) - int(left)
	if dir != 0:
		facing = dir

	# Grapple: pull straight toward the anchor
	var grap_now := key(KEY_F)
	if grap_now and not _grap_prev and owned.has("grapple") and grapple_to == null:
		grapple_to = nearest_anchor()
		if grapple_to == null:
			toast("No anchor in range")
	_grap_prev = grap_now
	if grapple_to != null:
		var target: Vector2 = (grapple_to as Vector2) + Vector2(0, PH / 2.0)
		var to := target - pos
		if to.length() < 12.0 or jump_pressed:
			vel = to.normalized() * 300.0 if jump_pressed else Vector2.ZERO
			grapple_to = null
		else:
			vel = to.normalized() * 520.0
			var before := pos
			pos += vel * dt
			if box_hits(pos):
				pos = before
				grapple_to = null
				vel = Vector2.ZERO
			after_move()
			queue_redraw()
			return

	# Dash
	var dash_now := key(KEY_SHIFT)
	if dash_now and not _dash_prev and owned.has("jet") and not dash_used and dash_t <= 0.0:
		dash_t = 0.18
		dash_used = true
	_dash_prev = dash_now

	if dash_t > 0.0:
		dash_t -= dt
		vel = Vector2(facing * 650.0, 0.0)
	else:
		vel.x = move_toward(vel.x, dir * 220.0, 1800.0 * dt)
		vel.y = min(vel.y + 1500.0 * dt, 700.0)

	coyote = 0.1 if on_ground else max(0.0, coyote - dt)
	if jump_pressed and owned.has("leg") and coyote > 0.0:
		vel.y = -560.0
		coyote = 0.0

	# Arm
	var arm_now := key(KEY_E)
	if arm_now and not _arm_prev and owned.has("arm") and not arm_on and arm_cooldown <= 0.0:
		arm_on = true
		arm_dist = 0.0
		arm_dir = Vector2.UP if up else Vector2(facing, 0)
		arm_pos = pos + Vector2(0, -PH / 2.0)
	_arm_prev = arm_now
	arm_cooldown = max(0.0, arm_cooldown - dt)
	if arm_on:
		step_arm(dt)

	move_and_collide_axes(dt)
	after_move()
	queue_redraw()


func step_arm(dt: float) -> void:
	var step := 600.0 * dt
	arm_pos += arm_dir * step
	arm_dist += step
	var c := int(floor(arm_pos.x / TILE))
	var r := int(floor(arm_pos.y / TILE))
	var ch := tile(c, r)
	if (ch == "S" or ch == "T") and not doors_open[ch]:
		doors_open[ch] = true
		toast("Click. A door opened.")
		arm_on = false
		arm_cooldown = 0.4
	elif is_solid(c, r) or arm_dist > 320.0:
		arm_on = false
		arm_cooldown = 0.4


func move_and_collide_axes(dt: float) -> void:
	pos.x += vel.x * dt
	if box_hits(pos):
		var s := signf(vel.x)
		for i in range(40):
			pos.x -= s * 0.5
			if not box_hits(pos):
				break
		vel.x = 0.0
	pos.y += vel.y * dt
	on_ground = false
	if box_hits(pos):
		var s := signf(vel.y)
		for i in range(80):
			pos.y -= s * 0.5
			if not box_hits(pos):
				break
		if vel.y > 0.0:
			on_ground = true
			dash_used = false
		vel.y = 0.0


func nearest_anchor() -> Variant:
	var best: Variant = null
	var best_d := 450.0
	for r in range(MAP_H):
		for c in range(MAP_W):
			var ch := tile(c, r)
			if ch == "A" or (ch == "a" and xray):
				var p := tile_center(c, r)
				var d := p.distance_to(pos + Vector2(0, -PH / 2.0))
				if d > 40.0 and d < best_d:
					best_d = d
					best = p
	return best


func after_move() -> void:
	var center := pos + Vector2(0, -PH / 2.0)
	var c1 := int(floor((pos.x - PW / 2.0) / TILE))
	var c2 := int(floor((pos.x + PW / 2.0) / TILE))
	var r1 := int(floor((pos.y - PH) / TILE))
	var r2 := int(floor((pos.y - 0.01) / TILE))
	for r in range(r1, r2 + 1):
		for c in range(c1, c2 + 1):
			if tile(c, r) == "^":
				die()
				return
	if pos.y > MAP_H * TILE + 60:
		die()
		return
	# Pickups, exit, weak points
	for r in range(MAP_H):
		for c in range(MAP_W):
			var ch := tile(c, r)
			if ch == "L" or ch == "E" or ch == "W":
				var d := tile_center(c, r).distance_to(center)
				if ch == "L" and d < 28.0:
					var limb: String = LevelsData.LEVELS[level_i]["limb"]
					owned[limb] = true
					set_tile(c, r, ".")
					toast("New limb: " + limb.to_upper())
				elif ch == "W" and d < 40.0:
					set_tile(c, r, ".")
					weak_left -= 1
					flash_t = 0.3
					toast("Weak point destroyed. " + str(weak_left) + " left.")
					if weak_left <= 0:
						win()
						return
				elif ch == "E" and d < 28.0:
					var need: String = LevelsData.LEVELS[level_i]["limb"]
					if need == "" or owned.has(need):
						load_level(level_i + 1)
						return
					toast("Find the limb first.")


func die() -> void:
	respawn()


func win() -> void:
	finished_game = true
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	if ResourceLoader.exists(MEMORY_IMAGE):
		var tr := TextureRect.new()
		tr.texture = load(MEMORY_IMAGE)
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.add_child(tr)
	var box := DialogueScene.instantiate()
	box.dialogue_file = ENDING_DIALOGUE
	box.finished.connect(func():
		box.queue_free()
		var title := Label.new()
		title.text = "TOMMY"
		title.add_theme_font_size_override("font_size", 96)
		title.set_anchors_preset(Control.PRESET_CENTER)
		title.position = Vector2(540, 300)
		title.add_theme_color_override("font_shadow_color", Color.BLACK)
		title.add_theme_constant_override("shadow_offset_x", 4)
		title.add_theme_constant_override("shadow_offset_y", 4)
		layer.add_child(title))
	add_child(box)


# ---------------- drawing (placeholder art) ----------------

func level_tint() -> Color:
	var t := float(level_i) / 5.0
	return Color(0.12 + 0.20 * t, 0.14 + 0.10 * t, 0.18 - 0.02 * t)


func _draw() -> void:
	if bg_layer == null:
		draw_rect(Rect2(0, 0, 1280, 720), level_tint())
	draw_set_transform(Vector2(0, Y_OFFSET))
	for r in range(MAP_H):
		for c in range(MAP_W):
			var ch := tile(c, r)
			var rect := Rect2(c * TILE, r * TILE, TILE, TILE)
			match ch:
				"#":
					if plat_tex:
						draw_texture_rect_region(plat_tex, rect, Rect2(c * 8, r * 8, 8, 8))
					else:
						draw_rect(rect, Color(0.45, 0.47, 0.52))
				"H":
					draw_rect(rect, Color(0.3, 0.9, 1.0, 0.9) if xray else Color(0.3, 0.9, 1.0, 0.08), xray)
				"^":
					draw_colored_polygon(PackedVector2Array([rect.position + Vector2(0, TILE), rect.position + Vector2(TILE / 2.0, 4), rect.position + Vector2(TILE, TILE)]), Color(0.9, 0.2, 0.2))
				"D", "F":
					if is_solid(c, r):
						draw_rect(rect, Color(0.9, 0.7, 0.2))
				"S", "T":
					draw_rect(rect.grow(-6), Color(0.3, 1.0, 0.4) if doors_open[ch] else Color(1.0, 0.3, 0.3))
				"A":
					draw_arc(rect.get_center(), 11, 0, TAU, 20, Color(1, 0.8, 0.3), 3)
				"a":
					draw_arc(rect.get_center(), 11, 0, TAU, 20, Color(0.3, 0.9, 1.0, 0.9 if xray else 0.05), 3)
				"L":
					var lname: String = LevelsData.LEVELS[level_i]["limb"]
					var bob := sin(Time.get_ticks_msec() / 260.0) * 3.0
					draw_circle(rect.get_center(), 17, Color(1.0, 0.9, 0.4, 0.28))
					if not _draw_limb(lname, rect.get_center() + Vector2(0, bob), 30.0):
						draw_circle(rect.get_center(), 11, Color(1.0, 0.9, 0.4))
				"E":
					draw_rect(rect.grow(-4), Color(0.5, 1.0, 0.6))
				"W":
					draw_circle(rect.get_center(), 13, Color(1.0, 0.2, 0.8))
	if grapple_to != null:
		draw_line(pos + Vector2(0, -PH / 2.0), grapple_to as Vector2, Color(1, 0.8, 0.3), 2)
	if arm_on:
		draw_rect(Rect2(arm_pos - Vector2(8, 4), Vector2(16, 8)), Color(0.8, 0.8, 0.9))
	var body := Color(1, 1, 1) if flash_t > 0.0 else Color(0.75, 0.8, 0.9)
	draw_rect(Rect2(pos.x - PW / 2.0, pos.y - PH, PW, PH), body)
	draw_rect(Rect2(pos.x + facing * 4 - 2, pos.y - PH + 6, 4, 4), Color(0.1, 0.9, 1.0) if xray else Color(0.1, 0.1, 0.1))
	draw_set_transform(Vector2.ZERO)
	# HUD
	var font := ThemeDB.fallback_font
	var data: Dictionary = LevelsData.LEVELS[level_i]
	draw_string(font, Vector2(16, 24), "Level %d: %s" % [level_i + 1, data["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(font, Vector2(16, 700), data["hint"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 0.8))
	var x := 700.0
	for l in ["leg", "arm", "eye", "grapple", "jet"]:
		var have: bool = owned.has(l)
		draw_rect(Rect2(x - 4, 4, 40, 40), Color(0, 0, 0, 0.45))
		if not _draw_limb(l, Vector2(x + 16, 24), 32.0, Color.WHITE if have else Color(0.2, 0.2, 0.25, 0.7)):
			draw_string(font, Vector2(x, 24), l.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.4) if have else Color(0.4, 0.4, 0.4))
		x += 52.0
	if toast_t > 0.0:
		draw_string(font, Vector2(16, 60), toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.9, 0.4))


# DEBUG: F1-F6 jump to levels 1-6 (and unlock every limb). Remove before shipping.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var i: int = event.keycode - KEY_F1
	if i < 0 or i >= LevelsData.LEVELS.size():
		return
	load_level(i)
