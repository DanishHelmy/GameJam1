class_name SpikeTiles
## Pixel-art skin for the '^' hazard tiles, one look per level. Rendered once per level into
## a texture (16x16 art pixels per 32px tile, two spikes per tile). Purely visual: the
## kill zone is still the whole tile, handled in narrative_game.gd.

# kind: 0 = metal spikes, 1 = glowing crystal spikes
const LOOK := [
	{ # 1 Lab: rusty olive-iron spikes with hot orange tips
		"kind": 0, "body": "7a5a38", "lit": "a37a48", "shade": "4e3a26", "line": "261c14",
		"tip": "f0a040", "rust": "b0602a", "base": "3a3326", "base_lit": "5a4e38"},
	{ # 2 City: bent rusty rebar / fence spikes
		"kind": 0, "body": "8a5a3a", "lit": "b07a50", "shade": "5a3a28", "line": "2c1e18",
		"tip": "c8a070", "rust": "c06a30", "base": "3c3f46", "base_lit": "575c66"},
	{ # 3 Subway: glowing cyan crystal shards, matching the neon signs
		"kind": 1, "body": "2fb8c0", "lit": "8af4f4", "shade": "1b7a86", "line": "0d3a44",
		"tip": "e8ffff", "rust": "1b7a86", "base": "1d2e32", "base_lit": "2f4a4e"},
	{ # 4 Skyway: jagged rusted steel shards
		"kind": 0, "body": "8a5a3e", "lit": "b9835a", "shade": "5a3a2a", "line": "2a1b14",
		"tip": "d9b090", "rust": "d07a30", "base": "4a3a30", "base_lit": "6a5446"},
	{ # 5 Tower: cold blue-grey rebar and broken concrete shards
		"kind": 0, "body": "6a7480", "lit": "98a4b0", "shade": "424a54", "line": "1c2128",
		"tip": "c4ccd4", "rust": "9a5a34", "base": "30363e", "base_lit": "484f59"},
	{ # 6 Roof: weathered iron spikes catching the orange sunset
		"kind": 0, "body": "7a6a70", "lit": "d09060", "shade": "4a4048", "line": "2a2328",
		"tip": "f0b878", "rust": "b0683a", "base": "4a4248", "base_lit": "6a5f66"},
]

static func _h(x: int, y: int, s: int) -> int:
	var n: int = x * 374761393 + y * 668265263 + s * 1442695041
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return absi(n) % 100

static func build(map: Array, level_i: int) -> ImageTexture:
	var look: Dictionary = LOOK[clampi(level_i, 0, LOOK.size() - 1)]
	var cols: int = (map[0] as String).length()
	var rows: int = map.size()
	var img := Image.create(cols * 16, rows * 16, false, Image.FORMAT_RGBA8)
	var body := Color(look.body)
	var lit := Color(look.lit)
	var shade := Color(look.shade)
	var line := Color(look.line)
	var tip := Color(look.tip)
	var rust := Color(look.rust)
	var base := Color(look.base)
	var base_lit := Color(look.base_lit)
	var kind: int = look.kind
	for r in rows:
		for c in cols:
			if (map[r] as String)[c] != "^":
				continue
			for s in 2:
				# two spikes per tile, height varies per spike so a row doesn't look stamped
				var gx := c * 2 + s
				var cx := 4.0 + 8.0 * s
				var hh := 12 + (_h(gx, r, level_i) % 3)          # 12..14 px tall (above the base)
				var top := 14 - hh                                  # first spike row
				for py in range(top, 14):
					var frac := float(py - top + 1) / float(hh)
					var half := 4.2 * pow(frac, 0.7)
					var x0 := int(round(cx - half))
					var x1 := int(round(cx + half)) - 1
					x0 = maxi(x0, s * 8)
					x1 = mini(x1, s * 8 + 7)
					for px in range(x0, x1 + 1):
						var ax := c * 16 + s * 8 + (px - int(8.0 * s))
						var ay := r * 16 + py
						var n := _h(ax, ay, level_i + 5)
						var col := body
						if px < int(cx):
							col = lit if n < 70 else body
						else:
							col = shade if n < 75 else body
						if px == x0 or px == x1:
							col = line
						elif n > 93:
							col = rust
						if kind == 1:
							# crystal: bright core, hot near the tip
							if px == int(cx) - 1 or px == int(cx):
								col = lit if py > top + 3 else tip
						if py == top:
							col = tip
						if px >= 0 and px < 16:
							img.set_pixel(c * 16 + px + 0, ay, col)
			# base plate along the bottom two rows of the tile
			for px in 16:
				var ax2 := c * 16 + px
				img.set_pixel(ax2, r * 16 + 14, line)
				var b := base_lit if _h(ax2, r, level_i + 9) < 30 else base
				img.set_pixel(ax2, r * 16 + 15, b)
	return ImageTexture.create_from_image(img)
