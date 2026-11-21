class_name Rooms
## Room layouts, one function per room. Rooms are 1280x720, floor top at y=640.
## Built from docs/design.md (chapter 0 room list) and narrative/game-brief.md (show, test, twist).

const ORDER := ["c0r1", "c0r2", "c0r3", "c0r4", "c1r1", "c1r2", "c1r3", "c2r1", "c2r2", "c2r3"]

const INTRO := {
	"c0r1": "res://narrative/dialogue/chapter_0_lab.json",
	"c1r1": "res://narrative/dialogue/chapter_1_street.json",
	"c2r1": "res://narrative/dialogue/chapter_2_subway.json",
}

static func title(id: String) -> String:
	return {
		"c0r1": "Lab 1: hop and drag",
		"c0r2": "Lab 2: the storage locker",
		"c0r3": "Lab 3: arm on the switch",
		"c0r4": "Lab 4: containment pod",
		"c1r1": "Street 1: spring pads",
		"c1r2": "Street 2: collapsed road",
		"c1r3": "Street 3: the tall wall",
		"c2r1": "Subway 1: first switch",
		"c2r2": "Subway 2: leave it behind (x-ray)",
		"c2r3": "Subway 3: unseen path (x-ray)",
	}.get(id, id)

static func build(r: RoomBase, id: String) -> void:
	match id:
		"c0r1": _c0r1(r)
		"c0r2": _c0r2(r)
		"c0r3": _c0r3(r)
		"c0r4": _c0r4(r)
		"c1r1": _c1r1(r)
		"c1r2": _c1r2(r)
		"c1r3": _c1r3(r)
		"c2r1": _c2r1(r)
		"c2r2": _c2r2(r)
		"c2r3": _c2r3(r)

# ------------------------------------------------------------ chapter 0: the lab
# Room 1: slow hop across a flat floor with one low step. Base movement only.
static func _c0r1(r: RoomBase) -> void:
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.block(Rect2(600, 610, 120, 30))      # low step, hoppable
	r.exit_zone(Rect2(1180, 560, 60, 80))

# Room 2: the missing leg sits in a locker behind a low step; the exit is on a ledge
# that only the full spring jump reaches.
static func _c0r2(r: RoomBase) -> void:
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.block(Rect2(380, 604, 140, 36))      # step in front of the locker
	r.block(Rect2(520, 520, 20, 120))      # locker back wall
	r.pickup(Vector2(470, 585), "leg")
	r.block(Rect2(860, 540, 420, 20))      # ledge: needs full jump (about 100px up)
	r.exit_zone(Rect2(1180, 460, 60, 80))

# Room 3: throw the arm onto the plate to open the door (the signature mechanic).
static func _c0r3(r: RoomBase) -> void:
	Progress.has_arm = true
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.plate_and_door(Rect2(300, 630, 120, 10), Rect2(860, 340, 30, 300))
	r.exit_zone(Rect2(1180, 560, 60, 80))

# Room 4: the grapple arm waits in a broken pod. A gap too wide to jump; swing to the exit.
static func _c0r4(r: RoomBase) -> void:
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 520, 80))
	r.block(Rect2(900, 640, 380, 80))
	r.block(Rect2(180, 560, 20, 80))       # pod wall
	r.pickup(Vector2(120, 610), "grapple")
	r.hook(Vector2(840, 400))
	r.exit_zone(Rect2(1180, 560, 60, 80))

# ------------------------------------------------------------ chapter 1: street level
static func _c1r1(r: RoomBase) -> void:
	r.tint = Color("4a5560")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 380, 80))
	r.block(Rect2(900, 640, 380, 80))
	r.spring(Rect2(330, 626, 50, 14), -980.0)
	r.block(Rect2(560, 330, 200, 20))
	r.pickup(Vector2(660, 300), "dash")
	r.hook(Vector2(840, 360))
	r.exit_zone(Rect2(1180, 560, 60, 80))

static func _c1r2(r: RoomBase) -> void:
	r.tint = Color("4a5560")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 300, 80))
	r.block(Rect2(980, 640, 300, 80))
	r.spring(Rect2(250, 626, 50, 14), -1000.0)
	r.block(Rect2(480, 400, 140, 20))
	r.block(Rect2(740, 400, 140, 20))
	r.exit_zone(Rect2(1180, 560, 60, 80))

static func _c1r3(r: RoomBase) -> void:
	r.tint = Color("4a5560")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.block(Rect2(700, 180, 40, 460))
	r.block(Rect2(740, 300, 200, 20))
	r.spring(Rect2(500, 626, 60, 14), -1050.0)
	r.data_log(Vector2(840, 270), "res://narrative/dialogue/chapter_1_log.json")
	r.block(Rect2(960, 450, 320, 20))
	r.exit_zone(Rect2(1180, 370, 60, 80))

# ------------------------------------------------------------ chapter 2: collapsed subway
static func _c2r1(r: RoomBase) -> void:
	r.tint = Color("2f4150")
	r.bg_color = Color("0d141b")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.plate_and_door(Rect2(330, 630, 120, 10), Rect2(900, 340, 30, 300))
	r.pickup(Vector2(180, 612), "xray")   # a dead subject's scanner eyes
	r.exit_zone(Rect2(1180, 560, 60, 80))

static func _c2r2(r: RoomBase) -> void:
	r.tint = Color("2f4150")
	r.bg_color = Color("0d141b")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 420, 80))
	r.block(Rect2(420, 700, 400, 20))      # flooded pit floor
	r.block(Rect2(820, 640, 460, 80))
	r.plate_and_door(Rect2(300, 630, 100, 10), Rect2(560, 300, 30, 400))
	r.hidden_hook(Vector2(700, 380))     # only visible with x-ray eyes (F)
	r.data_log(Vector2(1000, 600), "res://narrative/dialogue/chapter_2_log.json")
	r.exit_zone(Rect2(1180, 560, 60, 80))

static func _c2r3(r: RoomBase) -> void:
	r.tint = Color("2f4150")
	r.bg_color = Color("0d141b")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 300, 80))
	r.block(Rect2(980, 640, 300, 80))
	# Hidden stepping stones, solid only while x-ray eyes are on (press F)
	r.hidden_block(Rect2(340, 540, 100, 20))
	r.hidden_block(Rect2(540, 540, 100, 20))
	r.hidden_block(Rect2(740, 540, 100, 20))
	r.exit_zone(Rect2(1180, 560, 60, 80))
