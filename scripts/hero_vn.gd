class_name HeroVN
extends Control
## The robot from character_conceptv2, standing for visual-novel dialogue. The sprite itself
## is untouched; idle = slow bob + breathing, blinking, and expressions are tiny eye/mouth
## overlays drawn on top of the original face.

const TEX := preload("res://assets/sprites/character/hero_vn.png")
const SKIN := Color("7ea5c3")
const MOUTH := Color("1b2733")
const EYE_L := Rect2(117, 115, 31, 38)
const EYE_R := Rect2(211, 115, 34, 38)
const MOUTH_C := Vector2(179, 162)

var expr := "neutral"
var sc := 0.78
var _t := 0.0
var _blink_at := 2.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _blinking() -> bool:
	if _t >= _blink_at + 0.14:
		_blink_at = _t + randf_range(2.2, 4.5)
	return _t >= _blink_at and _t < _blink_at + 0.14

func _draw() -> void:
	var bob := sin(_t * 1.7) * 3.0
	var breathe := 1.0 + 0.012 * sin(_t * 1.7 + 0.6)
	var size := TEX.get_size() * sc
	# scale from the feet so breathing doesn't float the robot
	var base := Vector2(0, size.y * (1.0 - breathe) + bob)
	var s := Vector2(sc, sc * breathe)
	draw_set_transform(base, 0.0, s)
	draw_texture(TEX, Vector2.ZERO)
	_face()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _lid(r: Rect2, frac: float) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * frac)), SKIN)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * frac - 2, r.size.x, 3), MOUTH)

func _face() -> void:
	if _blinking():
		for r in [EYE_L, EYE_R]:
			draw_rect(r, SKIN)
			draw_rect(Rect2(r.position.x, r.get_center().y - 1.5, r.size.x, 3), MOUTH)
		return
	match expr:
		"sad", "worried":
			_lid(EYE_L, 0.28)
			_lid(EYE_R, 0.28)
			draw_rect(Rect2(MOUTH_C - Vector2(13, 4), Vector2(26, 12)), SKIN)
			draw_polyline(PackedVector2Array([MOUTH_C + Vector2(-9, 4), MOUTH_C + Vector2(0, 0), MOUTH_C + Vector2(9, 4)]), MOUTH, 3.0)
		"surprised":
			draw_rect(Rect2(MOUTH_C - Vector2(13, 4), Vector2(26, 12)), SKIN)
			draw_circle(MOUTH_C + Vector2(0, 2), 5.5, MOUTH)
		"determined":
			_lid(EYE_L, 0.22)
			_lid(EYE_R, 0.22)
		"tired":
			_lid(EYE_L, 0.45)
			_lid(EYE_R, 0.45)
		_:
			pass
