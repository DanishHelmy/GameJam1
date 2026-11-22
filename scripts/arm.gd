extends Area2D
## Detached right arm.
## Flies in a short arc, stops where it hits a surface and stays there, working as
## a switch weight and a grapple anchor. Press the arm key again to recall it; it
## flies back to the player and re-attaches.

signal returned

enum State { FLYING, LANDED, RETURNING }

const GRAVITY := 900.0
const RETURN_SPEED := 1000.0
const MAX_FLIGHT_TIME := 2.0

var state := State.FLYING
var vel := Vector2.ZERO
var target: Node2D = null
var flight_time := 0.0

func _ready() -> void:
	add_to_group("arm")
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(18, 10)
	shape.shape = r
	add_child(shape)

func launch(pos: Vector2, v: Vector2) -> void:
	global_position = pos
	vel = v
	state = State.FLYING
	if v == Vector2.ZERO:
		state = State.LANDED   # dropped at the player's feet

func recall(who: Node2D) -> void:
	target = who
	state = State.RETURNING

func _physics_process(delta: float) -> void:
	match state:
		State.FLYING:
			flight_time += delta
			vel.y += GRAVITY * delta
			var from := global_position
			var to := from + vel * delta
			var q := PhysicsRayQueryParameters2D.create(from, to, 1)
			var hit := get_world_2d().direct_space_state.intersect_ray(q)
			if hit.is_empty():
				global_position = to
				rotation += 14.0 * delta
			else:
				global_position = hit.position + hit.normal * 5.0
				rotation = 0.0 if absf(hit.normal.y) > 0.5 else PI / 2.0
				state = State.LANDED
			var room_h := 720.0
			if get_parent() != null and get_parent().get("height") != null:
				room_h = get_parent().get("height")
			if flight_time > MAX_FLIGHT_TIME or global_position.y > room_h + 300.0:
				if target == null:
					var p := get_tree().get_first_node_in_group("player")
					if p:
						recall(p)
		State.RETURNING:
			if target == null or not is_instance_valid(target):
				queue_free()
				returned.emit()
				return
			var to_t: Vector2 = target.global_position - global_position
			if to_t.length() < 22.0:
				returned.emit()
				queue_free()
				return
			global_position += to_t.normalized() * minf(RETURN_SPEED * delta, to_t.length())
			rotation += 18.0 * delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-9, -5, 18, 10), Color("ffb347"))
	draw_rect(Rect2(5, -3, 4, 6), Color("ffe0a0"))
