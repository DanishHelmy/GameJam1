class_name PropSkins
## Pixel-art skins for the interactive props: doors, switches, grapple anchors, hidden
## (x-ray) platforms, the exit and the boss weak points. Drawn procedurally onto the game
## node on a 4px "art pixel" grid (8x8 per 32px tile) so they match the tiles and spikes.
## Purely visual: collisions and rules live in narrative_game.gd.
##
## Colour carries the meaning so the player always knows what to do:
##   orange  = switch S + its door D        violet = switch T + its door F
##   gold    = grapple anchor                cyan   = x-ray (hidden) things
##   green   = unlocked exit / pressed       red    = locked exit / unpressed button
##   magenta = boss weak point

const PX := 4.0
const PAIR_S := Color("ff8a30")
const PAIR_T := Color("a478ff")
const GOLD := Color("ffd24a")
const XRAY := Color("3df0e0")
const GO := Color("55e070")
const STOP := Color("e8503a")
const MAGENTA := Color("ff30c0")

static func pair_color(ch: String) -> Color:
	return PAIR_T if (ch == "T" or ch == "F") else PAIR_S

static func _t() -> float:
	return Time.get_ticks_msec() / 1000.0

## One art pixel block at tile-local pixel coords (x, y), size (w, h) in art pixels.
static func _p(g: CanvasItem, o: Vector2, x: int, y: int, w: int, h: int, col: Color) -> void:
	g.draw_rect(Rect2(o + Vector2(x, y) * PX, Vector2(w, h) * PX), col)

static func _look(level_i: int) -> Dictionary:
	var l: Dictionary = PlatformTiles.LOOK[clampi(level_i, 0, PlatformTiles.LOOK.size() - 1)]
	return {
		"base": Color(l.base), "dark": Color(l.dark), "light": Color(l.light),
		"line": Color(l.line), "edge": Color(l.edge), "accent": Color(l.accent),
	}

# ------------------------------------------------------------------ doors
## One tile of a door column. `top` = this tile is the top of the column (draws the lamp).
static func door(g: CanvasItem, rect: Rect2, level_i: int, ch: String, row: int, top: bool, open: bool) -> void:
	var o := rect.position
	var k := _look(level_i)
	var pc := pair_color(ch)
	if open:
		# faint ghost so you can still see where the door was
		_p(g, o, 3, 0, 2, 8, Color(pc.r, pc.g, pc.b, 0.10))
		return
	_p(g, o, 0, 0, 8, 8, k.base)
	_p(g, o, 0, 0, 1, 8, k.light)          # lit left edge
	_p(g, o, 7, 0, 1, 8, k.dark)           # shaded right edge
	_p(g, o, 0, 0, 8, 1, k.line)           # plate seam
	_p(g, o, 1, 1, 1, 1, k.light)          # rivets
	_p(g, o, 6, 1, 1, 1, k.light)
	_p(g, o, 1, 6, 1, 1, k.light)
	_p(g, o, 6, 6, 1, 1, k.light)
	# beacon strip in the pair colour: alternating blocks, scrolling slowly upward
	var shift := int(_t() * 3.0)
	for y in 8:
		var on := (((row * 8 + y + shift) / 2) % 2) == 0
		_p(g, o, 3, y, 2, 1, pc if on else k.dark)
	_p(g, o, 2, 0, 1, 8, k.line)
	_p(g, o, 5, 0, 1, 8, k.line)
	if top:
		var pulse := 0.65 + 0.35 * sin(_t() * 4.0)
		_p(g, o, 1, 0, 6, 2, k.line)
		_p(g, o, 2, 0, 4, 1, Color(pc.r, pc.g, pc.b, pulse))
		g.draw_circle(o + Vector2(16, 2), 9, Color(pc.r, pc.g, pc.b, 0.10 * pulse))

# ------------------------------------------------------------------ switches
static func switch_(g: CanvasItem, rect: Rect2, level_i: int, ch: String, pressed: bool) -> void:
	var o := rect.position
	var k := _look(level_i)
	var pc := pair_color(ch)
	var pulse := 0.5 + 0.5 * sin(_t() * 5.0)
	# wall plate
	_p(g, o, 1, 1, 6, 6, k.line)
	_p(g, o, 1, 1, 6, 1, k.light)
	_p(g, o, 2, 2, 4, 4, k.dark)
	# pair-coloured ring (matches the door)
	_p(g, o, 1, 1, 1, 1, pc)
	_p(g, o, 6, 1, 1, 1, pc)
	_p(g, o, 1, 6, 1, 1, pc)
	_p(g, o, 6, 6, 1, 1, pc)
	if pressed:
		_p(g, o, 2, 2, 4, 4, Color("1f6e34"))
		_p(g, o, 3, 3, 2, 2, GO)
		g.draw_circle(o + Vector2(16, 16), 13, Color(GO.r, GO.g, GO.b, 0.16))
	else:
		_p(g, o, 2, 2, 4, 4, Color("7a2418"))
		var c := STOP.lerp(Color("ff9a80"), pulse * 0.6)
		_p(g, o, 3, 3, 2, 2, c)
		_p(g, o, 3, 3, 1, 1, Color("ffd0c0"))
		g.draw_circle(o + Vector2(16, 16), 15, Color(STOP.r, STOP.g, STOP.b, 0.10 + 0.10 * pulse))

# ------------------------------------------------------------------ grapple anchors
static func anchor(g: CanvasItem, rect: Rect2, level_i: int, hidden: bool, xray: bool) -> void:
	var c := rect.get_center()
	var k := _look(level_i)
	var pulse := 0.5 + 0.5 * sin(_t() * 3.0)
	if hidden:
		var a := 0.95 if xray else 0.05
		g.draw_arc(c, 11, 0, TAU, 24, Color(XRAY.r, XRAY.g, XRAY.b, a), 3)
		if xray:
			g.draw_circle(c, 15, Color(XRAY.r, XRAY.g, XRAY.b, 0.10 + 0.08 * pulse))
		return
	g.draw_circle(c, 17, Color(GOLD.r, GOLD.g, GOLD.b, 0.08 + 0.08 * pulse))
	# metal mount + hanging ring
	g.draw_rect(Rect2(c + Vector2(-6, -17), Vector2(12, 6)), k.line)
	g.draw_rect(Rect2(c + Vector2(-4, -16), Vector2(8, 3)), k.light)
	g.draw_arc(c + Vector2(0, 1), 10, 0, TAU, 24, k.line, 6)
	g.draw_arc(c + Vector2(0, 1), 10, 0, TAU, 24, GOLD.lerp(Color.WHITE, pulse * 0.25), 3)
	g.draw_arc(c + Vector2(0, 1), 10, deg_to_rad(200), deg_to_rad(290), 8, Color("fff2b0"), 2)

# ------------------------------------------------------------------ hidden (x-ray) platforms
static func hidden_platform(g: CanvasItem, rect: Rect2, xray: bool) -> void:
	var o := rect.position
	if not xray:
		# just a faint trace so careful players can spot where one might be
		g.draw_rect(rect.grow(-1), Color(XRAY.r, XRAY.g, XRAY.b, 0.10), false, 1.0)
		return
	var scan := fmod(_t() * 40.0, 32.0)
	g.draw_rect(rect, Color(XRAY.r, XRAY.g, XRAY.b, 0.22))
	g.draw_rect(rect.grow(-1), Color(XRAY.r, XRAY.g, XRAY.b, 0.95), false, 2.0)
	for y in range(4, 32, 8):
		_p(g, o, 1, y / 4, 6, 1, Color(XRAY.r, XRAY.g, XRAY.b, 0.18))
	g.draw_rect(Rect2(o + Vector2(2, scan), Vector2(28, 2)), Color(1, 1, 1, 0.45))

# ------------------------------------------------------------------ exit
## One fixed design for every level. Green = go; dim + padlock = still locked.
static func exit_door(g: CanvasItem, rect: Rect2, _level_i: int, locked: bool) -> void:
	var o := rect.position
	var frame := Color("1b2a2c")
	var steel := Color("34484c")
	var steel_lit := Color("5e7a80")
	var pulse := 0.5 + 0.5 * sin(_t() * (1.6 if locked else 4.0))
	var green := GO if not locked else Color("2f8a48")
	g.draw_circle(rect.get_center(), 21, Color(GO.r, GO.g, GO.b, (0.05 if locked else 0.12) + 0.06 * pulse))
	# doorway frame
	_p(g, o, 0, 0, 8, 8, frame)
	_p(g, o, 1, 0, 6, 1, steel_lit)
	_p(g, o, 1, 1, 1, 7, steel)
	_p(g, o, 6, 1, 1, 7, steel)
	_p(g, o, 2, 1, 4, 7, Color(green.r * 0.30, green.g * 0.30, green.b * 0.30))
	_p(g, o, 2, 1, 4, 1, green)
	_p(g, o, 1, 0, 1, 1, green)
	_p(g, o, 6, 0, 1, 1, green)
	if locked:
		_p(g, o, 3, 3, 2, 1, Color("c0c8c8"))
		_p(g, o, 3, 4, 1, 1, Color("c0c8c8"))
		_p(g, o, 4, 4, 1, 1, Color("c0c8c8"))
		_p(g, o, 3, 5, 2, 2, green.lerp(Color.WHITE, 0.25 * pulse))
	else:
		var a := 0.65 + 0.35 * pulse
		var cc := Color(GO.r, GO.g, GO.b, a)
		_p(g, o, 3, 2, 1, 1, cc)
		_p(g, o, 4, 3, 1, 1, cc)
		_p(g, o, 5, 4, 1, 1, Color(1, 1, 1, a))
		_p(g, o, 4, 5, 1, 1, cc)
		_p(g, o, 3, 6, 1, 1, cc)

# ------------------------------------------------------------------ boss weak point
static func weak_point(g: CanvasItem, rect: Rect2, level_i: int) -> void:
	var c := rect.get_center()
	var k := _look(level_i)
	var pulse := 0.5 + 0.5 * sin(_t() * 5.5)
	g.draw_circle(c, 24, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.07 + 0.09 * pulse))
	g.draw_circle(c, 15, k.line)                       # casing outline
	g.draw_circle(c, 13, k.accent.darkened(0.2))       # rusty casing
	for a in [0.5, 2.2, 3.9, 5.4]:                     # casing bolts
		g.draw_rect(Rect2(c + Vector2.from_angle(a) * 10.0 - Vector2(1, 1), Vector2(3, 3)), k.light)
	g.draw_circle(c, 9, Color("3a0a30"))
	g.draw_circle(c, 7.5 + pulse * 1.5, MAGENTA.lerp(Color("ff9ae0"), pulse * 0.5))
	g.draw_circle(c, 3.5, Color(1, 1, 1, 0.65 + 0.35 * pulse))
	# cracks leaking light
	g.draw_line(c + Vector2(-11, -6), c + Vector2(-6, -2), k.line, 1.0)
	g.draw_line(c + Vector2(10, 5), c + Vector2(6, 1), k.line, 1.0)
