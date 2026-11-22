class_name ExitGlow
extends Node2D
## Pulsing green glow behind the level exit. Same technique as LimbGlow: additive blending
## on its own nodes, drawn behind the game's own drawing. Identical on every level.
## Dim while the exit is locked (limb not found yet), bright once it is open.

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
			Color(0.55, 1.0, 0.65, 0.70),
			Color(0.20, 0.95, 0.40, 0.75),
			Color(0.08, 0.70, 0.25, 0.38),
			Color(0.02, 0.45, 0.15, 0.0)])
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
	var need: String = game.LevelsData.LEVELS[game.level_i]["limb"]
	var locked: bool = need != "" and not game.owned.has(need)
	var a := 0.5 + 0.5 * sin(_t * (1.6 if locked else 2.6))
	var b := 0.5 + 0.5 * sin(_t * (3.0 if locked else 4.8) + 1.1)
	var power := 0.38 if locked else 1.0
	_halo.scale = Vector2.ONE * lerpf(0.85, 1.2, a) * (150.0 / 128.0)
	_halo.modulate = Color(1, 1, 1, lerpf(0.65, 1.0, a) * power)
	_core.scale = Vector2.ONE * lerpf(0.55, 0.78, b) * (96.0 / 128.0)
	_core.modulate = Color(1, 1, 1, lerpf(0.55, 1.0, b) * power)
	position = Vector2((cell.x + 0.5) * TILE, (cell.y + 0.5) * TILE + game.Y_OFFSET)
