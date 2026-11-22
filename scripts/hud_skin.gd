class_name HudSkin
## Sci-fi "limb sync" panel for the top-right of the screen. Drawn in screen space onto the
## game node. Purely visual: it only reads which limbs are owned.

const LIMBS := ["leg", "arm", "eye", "grapple", "jet"]
const SHORT := {"leg": "LEG", "arm": "ARM", "eye": "EYE", "grapple": "GRAPPLE", "jet": "JET"}
const SLOT := Vector2(78, 84)
const GAP := 8.0
const ICON := 58.0
const CUT := 9.0
const CYAN := Color("3df0ff")
const CYAN_DIM := Color("1a5a6e")
const PANEL := Color(0.02, 0.06, 0.10, 0.80)
const LOCK := Color("5a7280")

static var _seen := {}
static var _last_level := -1

static func _chamfer(r: Rect2, c: float) -> PackedVector2Array:
	var p := r.position
	var e := r.end
	return PackedVector2Array([
		Vector2(p.x + c, p.y), Vector2(e.x - c, p.y), Vector2(e.x, p.y + c), Vector2(e.x, e.y - c),
		Vector2(e.x - c, e.y), Vector2(p.x + c, e.y), Vector2(p.x, e.y - c), Vector2(p.x, p.y + c)])

static func _outline(g: CanvasItem, poly: PackedVector2Array, col: Color, w: float) -> void:
	var closed := poly.duplicate()
	closed.append(poly[0])
	g.draw_polyline(closed, col, w)

## Little L-shaped brackets hugging the corners of r.
static func _brackets(g: CanvasItem, r: Rect2, col: Color, len := 8.0) -> void:
	var p := r.position
	var e := r.end
	g.draw_line(Vector2(p.x, p.y + len), Vector2(p.x, p.y), col, 2.0)
	g.draw_line(Vector2(p.x, p.y), Vector2(p.x + len, p.y), col, 2.0)
	g.draw_line(Vector2(e.x - len, p.y), Vector2(e.x, p.y), col, 2.0)
	g.draw_line(Vector2(e.x, p.y), Vector2(e.x, p.y + len), col, 2.0)
	g.draw_line(Vector2(p.x, e.y - len), Vector2(p.x, e.y), col, 2.0)
	g.draw_line(Vector2(p.x, e.y), Vector2(p.x + len, e.y), col, 2.0)
	g.draw_line(Vector2(e.x - len, e.y), Vector2(e.x, e.y), col, 2.0)
	g.draw_line(Vector2(e.x, e.y - len), Vector2(e.x, e.y), col, 2.0)

static func limb_bar(g: Node2D, owned: Dictionary, level_i: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	# limbs already owned when a level loads shouldn't flash; only newly collected ones do
	if level_i != _last_level:
		_seen.clear()
		for l in owned:
			_seen[l] = -100.0
		_last_level = level_i
	for l in owned:
		if not _seen.has(l):
			_seen[l] = now

	var font := ThemeDB.fallback_font
	var count := 0
	for l in LIMBS:
		if owned.has(l):
			count += 1

	var inner_w := LIMBS.size() * SLOT.x + (LIMBS.size() - 1) * GAP
	var panel := Rect2(1280.0 - 14.0 - (inner_w + 24.0), 6.0, inner_w + 24.0, SLOT.y + 40.0)

	# backing panel: dark glass, cut corners, cyan rim, scanlines
	var pp := _chamfer(panel, 14.0)
	g.draw_colored_polygon(pp, PANEL)
	var y := panel.position.y + 3.0
	while y < panel.end.y - 3.0:
		g.draw_line(Vector2(panel.position.x + 6, y), Vector2(panel.end.x - 6, y), Color(0.3, 0.9, 1.0, 0.05), 1.0)
		y += 4.0
	_outline(g, pp, Color(CYAN.r, CYAN.g, CYAN.b, 0.35), 3.0)
	_outline(g, pp, CYAN, 1.5)

	# header
	var hx := panel.position.x + 14.0
	var hy := panel.position.y + 17.0
	g.draw_rect(Rect2(hx, hy - 9, 3, 11), CYAN)
	g.draw_string(font, Vector2(hx + 9, hy), "LIMB SYNC", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CYAN)
	var sync := "%d / %d" % [count, LIMBS.size()]
	g.draw_string(font, Vector2(panel.end.x - 14.0 - 52.0, hy), sync, HORIZONTAL_ALIGNMENT_RIGHT, 52, 14, Color.WHITE if count == LIMBS.size() else CYAN)
	# progress ticks along the header line
	for i in LIMBS.size():
		var tx := hx + 112.0 + i * 20.0
		var on := i < count
		g.draw_rect(Rect2(tx, hy - 8, 16, 6), CYAN if on else Color(CYAN_DIM.r, CYAN_DIM.g, CYAN_DIM.b, 0.8))
	g.draw_line(Vector2(panel.position.x + 12, hy + 6), Vector2(panel.end.x - 12, hy + 6), Color(CYAN.r, CYAN.g, CYAN.b, 0.25), 1.0)

	# slots
	var sx := panel.position.x + 12.0
	var sy := panel.position.y + 30.0
	for l in LIMBS:
		var have: bool = owned.has(l)
		var r := Rect2(sx, sy, SLOT.x, SLOT.y)
		var poly := _chamfer(r, CUT)
		var pulse := 0.5 + 0.5 * sin(now * 3.0 + sx * 0.05)
		var age: float = now - float(_seen.get(l, -100.0))
		var flash := clampf(1.0 - age / 1.3, 0.0, 1.0)

		if have:
			g.draw_colored_polygon(poly, Color(0.04, 0.22, 0.30, 0.95))
			# glow bloom behind the icon
			g.draw_circle(r.get_center() + Vector2(0, -4), 34.0, Color(CYAN.r, CYAN.g, CYAN.b, 0.10 + 0.07 * pulse))
			g.draw_circle(r.get_center() + Vector2(0, -4), 22.0, Color(CYAN.r, CYAN.g, CYAN.b, 0.10 + 0.06 * pulse))
		else:
			g.draw_colored_polygon(poly, Color(0.03, 0.07, 0.10, 0.92))

		# scanlines inside the slot
		var ly := r.position.y + 3.0
		while ly < r.end.y - 3.0:
			g.draw_line(Vector2(r.position.x + 4, ly), Vector2(r.end.x - 4, ly), Color(0.3, 0.9, 1.0, 0.06 if have else 0.03), 1.0)
			ly += 4.0
		# moving sweep on collected slots
		if have:
			var sweep := fmod(now * 38.0 + sx, SLOT.y)
			g.draw_line(Vector2(r.position.x + 5, r.position.y + sweep), Vector2(r.end.x - 5, r.position.y + sweep), Color(0.7, 1.0, 1.0, 0.22), 2.0)

		# the limb itself
		var icon_c := r.get_center() + Vector2(0, -6)
		if have:
			g.call("_draw_limb", l, icon_c, ICON, Color.WHITE)
		else:
			g.call("_draw_limb", l, icon_c, ICON, Color(0.10, 0.16, 0.20, 0.85))
			# small padlock mark so "empty" reads as "not found yet"
			var lc := icon_c
			g.draw_rect(Rect2(lc + Vector2(-5, -1), Vector2(10, 8)), LOCK)
			g.draw_arc(lc + Vector2(0, -1), 4.0, PI, TAU, 8, LOCK, 2.0)

		# frame + brackets
		var rim := CYAN if have else Color(LOCK.r, LOCK.g, LOCK.b, 0.55)
		_outline(g, poly, Color(rim.r, rim.g, rim.b, 0.30 if have else 0.15), 3.0)
		_outline(g, poly, rim, 1.5)
		_brackets(g, r.grow(-3), rim if have else Color(LOCK.r, LOCK.g, LOCK.b, 0.35))

		# label plate
		var plate := Rect2(r.position.x + 8, r.end.y - 18, r.size.x - 16, 13)
		g.draw_rect(plate, Color(0, 0, 0, 0.45))
		g.draw_string(font, Vector2(plate.position.x, plate.end.y - 2.5), SHORT[l], HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 10, Color.WHITE if have else Color(LOCK.r, LOCK.g, LOCK.b, 0.7))

		# just-collected flash
		if flash > 0.0:
			g.draw_colored_polygon(poly, Color(1, 1, 1, 0.45 * flash))
			var ring := (1.0 - flash) * 30.0
			g.draw_arc(r.get_center(), 14.0 + ring, 0, TAU, 32, Color(CYAN.r, CYAN.g, CYAN.b, flash), 3.0)
			_outline(g, poly, Color(1, 1, 1, flash), 3.0)
		sx += SLOT.x + GAP
