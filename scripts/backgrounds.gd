class_name Backgrounds
extends Node2D
## Per-chapter parallax backdrop. Purely visual: no collision, drawn behind everything.
## The image is scaled larger than the 1280x720 room and slides opposite to the player,
## so it appears to move along with the character.

const FILES := {
	"c0": "res://assets/backgrounds/bg_lab.png",
	"c1": "res://assets/backgrounds/bg_street.png",
	"c2": "res://assets/backgrounds/bg_subway.png",
	"c3": "res://assets/backgrounds/bg_skyway.png",
	"c4": "res://assets/backgrounds/bg_tower.png",
}
const ROOM := Vector2(1280, 720)
const OVERSCAN := 1.2            # image width = room width * this (extra room to scroll)
const PARALLAX := Vector2(0.18, 0.10)   # how far the art slides per pixel the player moves
const DIM := Color(0.9, 0.9, 0.92)

var player: Node2D
var _sprite: Sprite2D
var _size := Vector2.ZERO

static func make(room_id: String, target: Node2D) -> Backgrounds:
	var path: String = FILES.get(room_id.substr(0, 2), "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var bg := Backgrounds.new()
	bg.player = target
	bg._setup(load(path))
	return bg

func _setup(tex: Texture2D) -> void:
	name = "Background"
	z_index = -100
	var k := ROOM.x * OVERSCAN / tex.get_width()
	_size = tex.get_size() * k
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.scale = Vector2(k, k)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.modulate = DIM
	add_child(_sprite)
	_update()

func _process(_d: float) -> void:
	_update()

func _update() -> void:
	var p := ROOM / 2.0
	if player != null and is_instance_valid(player):
		p = player.position
	var slack := _size - ROOM
	var off := (p - ROOM / 2.0) * PARALLAX
	# centred horizontally; vertically biased low so the ground area stays in view
	var x := -slack.x / 2.0 - off.x
	var y := -slack.y * 0.55 - off.y
	_sprite.position = Vector2(clampf(x, -slack.x, 0.0), clampf(y, -slack.y, 0.0))
