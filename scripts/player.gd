extends CharacterBody2D
## Prototype player: spring legs, jet dash, left-arm grapple (pulls you), right-arm detach.
##
## Controls
##   A/D move          Space/Z jump
##   Shift/X dash      (8 directions, one charge, refills on landing)
##   Left click grapple (aims at the mouse cursor)
##   Right click throw/recall the arm toward the cursor (kills enemies)
##   E/V grapple       (aim with direction keys; hits walls, hooks and the thrown arm; pulls you in)
##   Q/C arm           (throw in aim direction; press again to recall; hold Down + Q to drop it)
##   F x-ray eyes (toggle; reveals hidden mechanisms)
##   R respawn

const SPEED := 230.0
const ACCEL := 1600.0
const AIR_ACCEL := 1100.0
const GRAVITY := 1400.0
const JUMP_VELOCITY := -560.0   # spring legs: big jump
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

const DASH_SPEED := 560.0
const DASH_TIME := 0.16
const DASH_END_SPEED := 240.0

const GRAPPLE_RANGE := 560.0
const GRAPPLE_ASSIST_ANGLE := 0.35      # radians; snaps to hooks/arm near your aim
const PULL_SPEED := 820.0
const PULL_MAX_TIME := 0.7
const PULL_STOP_DIST := 30.0
const PULL_EXIT_KEEP := 0.7             # fraction of pull speed kept on arrival
const GRAPPLE_JUMP_GRACE := 0.18        # can jump just after a pull ends

const ARM_THROW_SPEED := 620.0

var facing := 1
var coyote := 0.0
var buffer := 0.0
var spawn_point := Vector2.ZERO

var can_dash := true
var dashing := false
var dash_left := 0.0
var dash_dir := Vector2.RIGHT

var can_grapple := true
var pulling := false
var pull_time := 0.0
var anchor_pos := Vector2.ZERO
var anchor_node: Node2D = null
var grapple_grace := 0.0

var grapple_by_mouse := false
var arm_by_mouse := false

# Ability gating (the game script unlocks these as the story progresses)
var has_dash := true
var has_grapple := true
var has_arm := true
var has_xray := true
var xray_on := false
var speed_mult := 1.0
var jump_mult := 1.0
var arm: Area2D = null

var jet_fx: CPUParticles2D

func _ready() -> void:
	spawn_point = global_position
	_setup_input()
	_setup_fx()

func _setup_input() -> void:
	var map := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z], "dash": [KEY_SHIFT, KEY_X],
		"grapple": [KEY_E, KEY_V], "detach": [KEY_Q, KEY_C],
		"restart": [KEY_R], "xray": [KEY_F],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for k in map[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(action, ev)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("grapple", click)
	var rclick := InputEventMouseButton.new()
	rclick.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("detach", rclick)

func _input(event: InputEvent) -> void:
	# Remember whether the grapple press came from the mouse, so we aim at the cursor
	if event.is_action_pressed("grapple"):
		grapple_by_mouse = event is InputEventMouseButton
	if event.is_action_pressed("detach"):
		arm_by_mouse = event is InputEventMouseButton

func _setup_fx() -> void:
	jet_fx = CPUParticles2D.new()
	jet_fx.emitting = false
	jet_fx.amount = 30
	jet_fx.lifetime = 0.28
	jet_fx.local_coords = false          # trail stays behind in the world
	jet_fx.spread = 22.0
	jet_fx.gravity = Vector2.ZERO
	jet_fx.initial_velocity_min = 90.0
	jet_fx.initial_velocity_max = 220.0
	jet_fx.scale_amount_min = 4.0
	jet_fx.scale_amount_max = 8.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("fff2a8"), Color("ff7a1a"), Color(0.4, 0.1, 0.0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	jet_fx.color_ramp = g
	jet_fx.z_index = -1
	add_child(jet_fx)

func _aim() -> Vector2:
	var v := Input.get_vector("left", "right", "up", "down")
	if v == Vector2.ZERO:
		return Vector2(facing, 0)
	return v.normalized()

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("left", "right")
	if dir != 0.0:
		facing = int(signf(dir))

	var on_floor := is_on_floor()
	if on_floor:
		coyote = COYOTE_TIME
		if not dashing:
			can_dash = true
		if not pulling:
			can_grapple = true
	else:
		coyote = maxf(coyote - delta, 0.0)
	grapple_grace = maxf(grapple_grace - delta, 0.0)
	buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else maxf(buffer - delta, 0.0)

	if Input.is_action_just_pressed("restart"):
		_respawn()
		return
	if has_xray and Input.is_action_just_pressed("xray"):
		xray_on = not xray_on
	if has_arm and Input.is_action_just_pressed("detach"):
		_arm_action()
	if has_dash and Input.is_action_just_pressed("dash") and can_dash:
		_start_dash()
	if Input.is_action_just_pressed("grapple"):
		if pulling:
			_end_pull()
		elif has_grapple and can_grapple and not dashing:
			_try_grapple()

	if dashing:
		_dash_step(delta)
	elif pulling:
		_pull_step(delta)
	else:
		_walk(dir, delta)

	move_and_slide()

	if pulling and get_slide_collision_count() > 0:
		_end_pull()
	if global_position.y > 900.0:
		_respawn()
	queue_redraw()

# ---------------------------------------------------------------- walking
func _walk(dir: float, delta: float) -> void:
	var on_floor := is_on_floor()
	var accel := ACCEL if on_floor else AIR_ACCEL
	velocity.x = move_toward(velocity.x, dir * SPEED * speed_mult, accel * delta)

	if buffer > 0.0 and (coyote > 0.0 or grapple_grace > 0.0):
		velocity.y = JUMP_VELOCITY * jump_mult
		buffer = 0.0
		coyote = 0.0
		grapple_grace = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45
	velocity.y += GRAVITY * delta

# ---------------------------------------------------------------- dash
func _start_dash() -> void:
	if pulling:
		_end_pull(false)
	dash_dir = _aim()
	dashing = true
	can_dash = false
	dash_left = DASH_TIME
	jet_fx.direction = -dash_dir
	jet_fx.emitting = true

func _dash_step(delta: float) -> void:
	velocity = dash_dir * DASH_SPEED
	dash_left -= delta
	# Dash-jump: jump during a ground dash
	if buffer > 0.0 and coyote > 0.0:
		_end_dash()
		velocity.y = JUMP_VELOCITY * jump_mult
		velocity.x = dash_dir.x * DASH_SPEED * 0.9
		buffer = 0.0
		coyote = 0.0
		return
	if dash_left <= 0.0:
		_end_dash()
		velocity = dash_dir * DASH_END_SPEED

func _end_dash() -> void:
	dashing = false
	jet_fx.emitting = false

# ---------------------------------------------------------------- grapple
func _try_grapple() -> void:
	var aim := _aim()
	if grapple_by_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			aim = to_mouse.normalized()
	var space := get_world_2d().direct_space_state
	var target_pos := Vector2.ZERO
	var target_node: Node2D = null
	var found := false

	# 1) Aim assist: hooks and the thrown arm near the aim direction
	var best_angle := GRAPPLE_ASSIST_ANGLE
	var candidates := get_tree().get_nodes_in_group("hook") + get_tree().get_nodes_in_group("arm")
	for n in candidates:
		var to: Vector2 = n.global_position - global_position
		if to.length() > GRAPPLE_RANGE or to.length() < 20.0:
			continue
		var ang := absf(aim.angle_to(to))
		if ang >= best_angle:
			continue
		var q := PhysicsRayQueryParameters2D.create(global_position, n.global_position, 1, [get_rid()])
		if not space.intersect_ray(q).is_empty():
			continue
		best_angle = ang
		target_pos = n.global_position
		target_node = n
		found = true

	# 2) Otherwise whatever surface the aim ray hits (walls, floors, ceilings, doors)
	if not found:
		var q2 := PhysicsRayQueryParameters2D.create(global_position, global_position + aim * GRAPPLE_RANGE, 1, [get_rid()])
		var hit := space.intersect_ray(q2)
		if not hit.is_empty():
			target_pos = hit.position
			found = true

	if not found:
		return   # missed; no charge spent
	anchor_pos = target_pos
	anchor_node = target_node
	pulling = true
	pull_time = 0.0
	can_grapple = false
	dashing = false
	jet_fx.emitting = false

func _pull_step(delta: float) -> void:
	if anchor_node and is_instance_valid(anchor_node):
		anchor_pos = anchor_node.global_position
	elif anchor_node:
		_end_pull()
		return
	pull_time += delta
	var to := anchor_pos - global_position
	if to.length() <= PULL_STOP_DIST or pull_time > PULL_MAX_TIME:
		_end_pull()
		return
	velocity = to.normalized() * PULL_SPEED
	# Jump cancels the pull and keeps momentum
	if buffer > 0.0:
		_end_pull()
		velocity.y = minf(velocity.y, 0.0) + JUMP_VELOCITY * 0.7
		buffer = 0.0

func _end_pull(keep_momentum := true) -> void:
	if not pulling:
		return
	pulling = false
	grapple_grace = GRAPPLE_JUMP_GRACE
	if keep_momentum:
		velocity *= PULL_EXIT_KEEP
	anchor_node = null

# ---------------------------------------------------------------- right arm
func _arm_action() -> void:
	if arm and is_instance_valid(arm):
		if arm.state != arm.State.RETURNING:
			arm.recall(self)
			if anchor_node == arm:
				_end_pull()
		return
	arm = preload("res://scripts/arm.gd").new()
	get_parent().add_child(arm)
	arm.returned.connect(_on_arm_returned)
	var aim := _aim()
	if arm_by_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			aim = to_mouse.normalized()
	var drop := Input.is_action_pressed("down") and not arm_by_mouse
	if drop:
		arm.launch(global_position + Vector2(0, 14), Vector2.ZERO)
	else:
		arm.launch(global_position + aim * 18.0, aim * ARM_THROW_SPEED + Vector2(velocity.x * 0.25, -60.0))

func _on_arm_returned() -> void:
	arm = null

# ---------------------------------------------------------------- misc
func _respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	can_dash = true
	can_grapple = true
	pulling = false
	anchor_node = null
	_end_dash()

func _draw() -> void:
	var aim := _aim()
	# body
	draw_rect(Rect2(-12, -22, 24, 44), Color("5a6b7a") if can_dash else Color("3d4954"))
	draw_rect(Rect2(-8, -20, 16, 10), Color("9fe8ff"))
	# right arm (detachable): ghosted when thrown
	var arm_out := arm != null and is_instance_valid(arm)
	draw_rect(Rect2(facing * 10 - 3, -8, 6, 18), Color(1.0, 0.7, 0.28, 0.25 if arm_out else 1.0))
	# left arm (grapple): dim when spent
	draw_rect(Rect2(-facing * 10 - 3, -8, 6, 18), Color("6bd36b") if can_grapple else Color("3d6b3d"))
	# jet flames on the legs while dashing
	if dashing:
		var back := -dash_dir
		draw_rect(Rect2(-9 + back.x * 14, 20 + back.y * 14, 8, 10), Color("ff7a1a"))
		draw_rect(Rect2(1 + back.x * 14, 20 + back.y * 14, 8, 10), Color("ffd24a"))
	# aim pip
	draw_circle(aim * 34.0, 3.0, Color(1, 1, 1, 0.5))
	if pulling:
		draw_line(Vector2(-facing * 10, -4), to_local(anchor_pos), Color.WHITE, 2.0)
		draw_circle(to_local(anchor_pos), 5.0, Color("6bd36b"))
