class_name LimbGlow
extends Node2D
## Pulsing blue glow behind a limb pickup. Uses additive blending, so it needs its own
## nodes (a node can't change blend mode part-way through its own _draw).
## Sits behind the game's drawing (show_behind_parent) and hides once the limb is taken.

const TILE := 32.0
var game: Node
var cell := Vector2i.ZERO
var _halo: Sprite2D
var _core: Sprite2D
var _t := 0.0

static var _tex: GradientTexture2D

static func _radial() -> GradientTexture2D:
	if _tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
		g.colors = PackedColorArray([
			Color(0.40, 0.70, 1.0, 0.70),
			Color(0.22, 0.52, 1.0, 0.75),
			Color(0.12, 0.40, 1.0, 0.38),
			Color(0.05, 0.20, 1.0, 0.0)])
		_tex = GradientTexture2D.new()
		_tex.gradient = g
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = 128
		_tex.height = 128
	return _tex

func _make_layer() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _radial()
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	add_child(s)
	return s

func _ready() -> void:
	show_behind_parent = true
	_halo = _make_layer()
	_core = _make_layer()
	_t = randf() * TAU

func _process(dt: float) -> void:
	_t += dt
	if game != null and game.tile(cell.x, cell.y) != "L":
		visible = false
		return
	visible = true
	# slow breathing halo, faster smaller core on a different phase
	var a := 0.5 + 0.5 * sin(_t * 2.4)
	var b := 0.5 + 0.5 * sin(_t * 4.6 + 1.3)
	_halo.scale = Vector2.ONE * lerpf(0.85, 1.2, a) * (170.0 / 128.0)
	_halo.modulate = Color(1, 1, 1, lerpf(0.7, 1.0, a))
	_core.scale = Vector2.ONE * lerpf(0.55, 0.8, b) * (110.0 / 128.0)
	_core.modulate = Color(1, 1, 1, lerpf(0.6, 1.0, b))
	# follow the sprite's bob
	position.y = (cell.y + 0.5) * TILE + game.Y_OFFSET + sin(Time.get_ticks_msec() / 260.0) * 3.0
