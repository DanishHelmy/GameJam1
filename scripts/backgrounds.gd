class_name Backgrounds
## Concept-art backdrops for the rooms. Purely visual: no collision, drawn behind everything.
## The concept images are 4:3 with a caption bar along the bottom, so we crop the bar off
## and take a 16:9 window (bottom-aligned, so the ground stays in view) to fit a 1280x720 room.

const DIR := "res://assets/concept/"
const BY_CHAPTER := {
	"c0": "Gemini_Generated_Image_dxsdwhdxsdwhdxsd.jpg",  # Level 1: Laboratory
	"c1": "Gemini_Generated_Image_3bgdvj3bgdvj3bgd.jpg",  # Level 2: Urban dystopian city
	"c2": "Gemini_Generated_Image_5qgymw5qgymw5qgy.jpg",  # Level 3: Underground subway
	"c3": "Gemini_Generated_Image_pcf4aepcf4aepcf4 (1).jpg",  # Level 5: Skyway
	"c4": "Gemini_Generated_Image_pcf4aepcf4aepcf4.jpg",  # Level 4: Skyscraper (the tower)
}
const CAPTION_FRACTION := 0.131   # share of the image height taken by the caption bar
const DIM := Color(0.72, 0.72, 0.78)  # calm the art so platforms and hazards stay readable

static func make(room_id: String) -> Sprite2D:
	var file: String = BY_CHAPTER.get(room_id.substr(0, 2), "")
	var path := DIR + file
	if file == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var size := tex.get_size()
	var art_h := size.y * (1.0 - CAPTION_FRACTION)
	var crop_h := minf(size.x * 9.0 / 16.0, art_h)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.region_enabled = true
	s.region_rect = Rect2(0, art_h - crop_h, size.x, crop_h)
	s.scale = Vector2(1280.0 / size.x, 720.0 / crop_h)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.modulate = DIM
	s.z_index = -100
	s.name = "Background"
	return s
