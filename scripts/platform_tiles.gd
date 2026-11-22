class_name PlatformTiles
## Pixel-art skin for the solid '#' tiles. Rendered once per level into a texture
## (8x8 art pixels per 32px tile) so drawing stays cheap. Purely visual.

# Per-level look. style: 0 panel, 1 brick, 2 girder, 3 slab
const LOOK := [
	{ # 1 Lab: rusty olive metal panels, moss on top
		"style": 0, "base": "4a4d38", "dark": "393b2a", "light": "5d6045", "accent": "7a4a28",
		"edge": "7d8a52", "edge2": "5f6b3c", "moss": "5f8a3a", "moss_chance": 38, "line": "2a2c20"},
	{ # 2 City: cracked blue-grey concrete and brick, weeds on top
		"style": 1, "base": "59626b", "dark": "444c55", "light": "6f7982", "accent": "7b4b30",
		"edge": "8a949c", "edge2": "6a747c", "moss": "5f8f3a", "moss_chance": 30, "line": "3a4149"},
	{ # 3 Subway: dark teal tile, worn platform edge, cyan glints
		"style": 1, "base": "33474a", "dark": "26373a", "light": "45605f", "accent": "5ad0d0",
		"edge": "9a8650", "edge2": "6b5d38", "moss": "3f6a4a", "moss_chance": 10, "line": "1c2a2d"},
	{ # 4 Skyway: rusted steel girder plating, vines hanging
		"style": 2, "base": "6a4a38", "dark": "4f3629", "light": "835c45", "accent": "a65a2a",
		"edge": "9a6a48", "edge2": "744f3a", "moss": "5f8a3a", "moss_chance": 22, "line": "3a271d"},
	{ # 5 Tower: dark blue-grey concrete with rust
		"style": 0, "base": "3f464f", "dark": "2f353d", "light": "535c66", "accent": "7a4a30",
		"edge": "6a737d", "edge2": "4c555f", "moss": "4f7a3a", "moss_chance": 22, "line": "232830"},
	{ # 6 Roof: weathered slab, moss and puddle-orange sunset highlight
		"style": 3, "base": "625c62", "dark": "4b464c", "light": "7a727a", "accent": "b0703c",
		"edge": "c08a58", "edge2": "7a6a6a", "moss": "5f8f3a", "moss_chance": 42, "line": "383439"},
]

static func _h(x: int, y: int, seed_v: int) -> int:
	var n: int = x * 374761393 + y * 668265263 + seed_v * 1442695041
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return absi(n) % 100

static func _solid(map: Array, c: int, r: int) -> bool:
	if r < 0 or r >= map.size() or c < 0 or c >= (map[0] as String).length():
		return true
	return (map[r] as String)[c] == "#"

static func build(map: Array, level_i: int) -> ImageTexture:
	var look: Dictionary = LOOK[clampi(level_i, 0, LOOK.size() - 1)]
	var cols: int = (map[0] as String).length()
	var rows: int = map.size()
	var img := Image.create(cols * 8, rows * 8, false, Image.FORMAT_RGBA8)
	var base := Color(look.base)
	var dark := Color(look.dark)
	var light := Color(look.light)
	var accent := Color(look.accent)
	var edge := Color(look.edge)
	var edge2 := Color(look.edge2)
	var moss := Color(look.moss)
	var line := Color(look.line)
	var style: int = look.style
	for r in rows:
		for c in cols:
			if (map[r] as String)[c] != "#":
				continue
			var up := not _solid(map, c, r - 1)
			var down := not _solid(map, c, r + 1)
			var left := not _solid(map, c - 1, r)
			var right := not _solid(map, c + 1, r)
			for py in 8:
				for px in 8:
					var gx := c * 8 + px
					var gy := r * 8 + py
					var n := _h(gx, gy, level_i)
					var col := base
					if n < 18:
						col = dark
					elif n < 30:
						col = light
					elif n < 33:
						col = accent
					# structure
					match style:
						0:  # panels: seams on tile borders, rivets in the corners
							if px == 0 or py == 0:
								col = line if n < 70 else dark
							elif (px == 1 or px == 6) and (py == 1 or py == 6):
								col = light
						1:  # brick: staggered mortar lines
							var row := py / 4
							if py % 4 == 3:
								col = line
							elif px == ((row % 2) * 4 + (c % 2) * 2) % 8:
								col = line
						2:  # girder: horizontal plates with rivet dots
							if py == 0 or py == 4:
								col = line
							elif py == 1 or py == 5:
								col = light if n < 60 else base
							elif (px == 1 or px == 6) and (py == 2):
								col = light
						3:  # slab: big paving joints, cracks
							if px == 0 or py == 0:
								col = line if n < 75 else dark
							elif n > 94:
								col = line
					# lit / shaded edges
					if left and px == 0:
						col = light
					if right and px == 7:
						col = dark
					if down and py == 7:
						col = line
					if up:
						if py == 0:
							col = edge
						elif py == 1:
							col = edge2 if n < 80 else edge
						if py <= 2 and _h(gx, c, level_i + 7) < int(look.moss_chance):
							col = moss
						if py == 0 and _h(gx, 99, level_i + 3) < int(look.moss_chance) / 2:
							col = moss.lightened(0.15)
					img.set_pixel(gx, gy, col)
	return ImageTexture.create_from_image(img)
