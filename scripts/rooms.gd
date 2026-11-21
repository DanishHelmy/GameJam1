class_name Rooms
## Room layouts, one function per room. Rooms are 1280x720, floor top at y=640.
## Built from docs/design.md (chapter 0 room list) and narrative/game-brief.md (show, test, twist).

const ORDER := ["c0r1", "c0r2", "c0r3", "c0r4", "c1r1", "c1r2", "c1r3", "c2r1", "c2r2", "c2r3", "c3r1", "c3r2", "c3r3", "c4r1"]

const INTRO := {
	"c0r1": "res://narrative/dialogue/chapter_0_lab.json",
	"c1r1": "res://narrative/dialogue/chapter_1_street.json",
	"c2r1": "res://narrative/dialogue/chapter_2_subway.json",
	"c3r1": "res://narrative/dialogue/chapter_3_skyway.json",
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
		"c3r1": "Skyway 1: crumbling bridge",
		"c3r2": "Skyway 2: saw alley",
		"c3r3": "Skyway 3: the long way up",
		"c4r1": "Tower: everything at once",
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
		"c3r1": _c3r1(r)
		"c3r2": _c3r2(r)
		"c3r3": _c3r3(r)
		"c4r1": _c4r1(r)

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
	r.spikes(Rect2(1010, 626, 70, 14))
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
	r.spikes(Rect2(220, 626, 90, 14))
	r.spikes(Rect2(1000, 436, 100, 14))
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
	r.saw(Vector2(560, 610), Vector2(800, 610), 1.6)
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
	r.spikes(Rect2(420, 686, 400, 14))
	r.saw(Vector2(500, 520), Vector2(780, 520), 1.4)
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
	r.spikes(Rect2(300, 686, 680, 14))
	r.saw(Vector2(380, 470), Vector2(820, 470), 1.8)
	r.hidden_block(Rect2(340, 540, 100, 20))
	r.hidden_block(Rect2(540, 540, 100, 20))
	r.hidden_block(Rect2(740, 540, 100, 20))
	r.exit_zone(Rect2(1180, 560, 60, 80))

# ------------------------------------------------------------ chapter 3: broken skyway
# Crumbling bridge over a pit: grapple hooks to rest, dash to cross the wide gaps.
static func _c3r1(r: RoomBase) -> void:
	r.tint = Color("3a4a63")
	r.bg_color = Color("101826")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 240, 80))
	r.block(Rect2(1040, 640, 240, 80))
	r.crumble(Rect2(320, 600, 110, 18))
	r.crumble(Rect2(520, 560, 110, 18))
	r.crumble(Rect2(720, 520, 110, 18))
	r.crumble(Rect2(900, 580, 110, 18))
	r.hook(Vector2(620, 340))
	r.spikes(Rect2(240, 696, 800, 14))
	r.exit_zone(Rect2(1180, 560, 60, 80))

# Saw alley: two saws on offset timing and a dash-only gap.
static func _c3r2(r: RoomBase) -> void:
	r.tint = Color("3a4a63")
	r.bg_color = Color("101826")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 380, 80))
	r.block(Rect2(640, 640, 640, 80))
	r.spikes(Rect2(380, 696, 260, 14))
	r.saw(Vector2(760, 590), Vector2(1080, 590), 1.2)
	r.saw(Vector2(900, 470), Vector2(1100, 470), 1.0)
	r.block(Rect2(800, 520, 120, 18))
	r.spikes(Rect2(1090, 626, 60, 14))
	r.exit_zone(Rect2(1190, 560, 60, 80))

# Long climb: hidden hook, crumbling steps, saw guarding the top.
static func _c3r3(r: RoomBase) -> void:
	r.tint = Color("3a4a63")
	r.bg_color = Color("101826")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 260, 80))
	r.crumble(Rect2(340, 560, 100, 18))
	r.crumble(Rect2(520, 480, 100, 18))
	r.hidden_hook(Vector2(760, 380))
	r.block(Rect2(860, 300, 200, 18))
	r.saw(Vector2(900, 250), Vector2(1040, 250), 0.9)
	r.spikes(Rect2(260, 696, 1020, 14))
	r.block(Rect2(1100, 200, 180, 18))
	r.exit_zone(Rect2(1200, 120, 60, 80))

# The tower: arm switch, grapple, dash, x-ray and saws all in one room.
static func _c4r1(r: RoomBase) -> void:
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 300, 80))
	r.plate_and_door(Rect2(150, 630, 100, 10), Rect2(560, 300, 30, 400))
	r.spikes(Rect2(300, 696, 980, 14))
	r.block(Rect2(640, 640, 140, 80))
	r.hidden_block(Rect2(860, 560, 100, 18))
	r.crumble(Rect2(1040, 500, 100, 18))
	r.saw(Vector2(660, 540), Vector2(1060, 540), 1.3)
	r.hook(Vector2(960, 300))
	r.block(Rect2(1140, 340, 140, 18))
	r.exit_zone(Rect2(1200, 260, 60, 80))
