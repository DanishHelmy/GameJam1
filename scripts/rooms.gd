class_name Rooms
## Room layouts, one function per room. Rooms are 1280x720, floor top at y=640.
## Built from docs/design.md (chapter 0 room list) and narrative/game-brief.md (show, test, twist).

const ORDER_OLD := ["c0r1", "c0r2", "c0r3", "c0r4", "c1r1", "c1r2", "c1r3", "c2r1", "c2r2", "c2r3", "c3r1", "c3r2", "c3r3", "c4r1"]

const ORDER := ["t1", "t2", "t3", "t4", "t5", "t6"]

const INTRO := {
	"t1": "res://narrative/dialogue/chapter_0_lab.json",
	"t2": "res://narrative/dialogue/chapter_1_street.json",
	"t3": "res://narrative/dialogue/chapter_2_subway.json",
	"t5": "res://narrative/dialogue/chapter_3_skyway.json",
	"s1": "res://narrative/dialogue/chapter_0_lab.json",
	"s2": "res://narrative/dialogue/chapter_1_street.json",
	"s3": "res://narrative/dialogue/chapter_2_subway.json",
	"s5": "res://narrative/dialogue/chapter_3_skyway.json",
	"c0r1": "res://narrative/dialogue/chapter_0_lab.json",
	"c1r1": "res://narrative/dialogue/chapter_1_street.json",
	"c2r1": "res://narrative/dialogue/chapter_2_subway.json",
	"c3r1": "res://narrative/dialogue/chapter_3_skyway.json",
}

static func title(id: String) -> String:
	return {
		"t1": "Level 1: Lab",
		"t2": "Level 2: Street",
		"t3": "Level 3: Subway",
		"t4": "Level 4: Tower",
		"t5": "Level 5: Skyway",
		"t6": "Level 6: Roof",
		"s1": "Level 1: Lab (get the leg)",
		"s2": "Level 2: Street (throw the arm)",
		"s3": "Level 3: Subway (x-ray)",
		"s4": "Level 4: Tower (dash)",
		"s5": "Level 5: Skyway (grapple, wind)",
		"s6": "Level 6: Roof (everything)",
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
		"t1": _t1(r)
		"t2": _t2(r)
		"t3": _t3(r)
		"t4": _t4(r)
		"t5": _t5(r)
		"t6": _t6(r)
		"s1": _s1(r)
		"s2": _s2(r)
		"s3": _s3(r)
		"s4": _s4(r)
		"s5": _s5(r)
		"s6": _s6(r)
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

# ============================================================ sketch levels (from the hand-drawn level sheets)
# Lab: leg pickup, then stepped pillars and spike pits to a high exit.
static func _s1(r: RoomBase) -> void:
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.pickup(Vector2(380, 612), "leg")
	r.block(Rect2(640, 550, 90, 90))
	r.spikes(Rect2(730, 626, 110, 14))
	r.block(Rect2(840, 480, 90, 160))
	r.spikes(Rect2(930, 626, 110, 14))
	r.block(Rect2(1040, 410, 240, 230))
	r.exit_zone(Rect2(1190, 330, 60, 80))

# Street: car, balcony climb, pile of cars. Throw the arm onto the plate to open the door.
static func _s2(r: RoomBase) -> void:
	r.tint = Color("4a5560")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 1280, 80))
	r.pickup(Vector2(260, 612), "arm")
	r.block(Rect2(380, 600, 150, 40))                    # abandoned car
	r.spikes(Rect2(560, 626, 70, 14))
	r.block(Rect2(660, 560, 200, 80))                    # pile of cars
	r.block(Rect2(700, 460, 100, 16))                    # balconies
	r.block(Rect2(560, 370, 100, 16))
	r.plate_and_door(Rect2(940, 630, 100, 10), Rect2(1100, 340, 30, 300))
	r.exit_zone(Rect2(1190, 560, 60, 80))

# Subway: x-ray eyes reveal stepping stones over spikes; moving platform; plate opens the door.
static func _s3(r: RoomBase) -> void:
	r.tint = Color("2f4150")
	r.bg_color = Color("0d141b")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 300, 80))
	r.block(Rect2(980, 640, 300, 80))
	r.pickup(Vector2(180, 612), "xray")
	r.plate_and_door(Rect2(220, 630, 70, 10), Rect2(1120, 340, 30, 300))
	r.spikes(Rect2(300, 686, 680, 14))
	r.hidden_block(Rect2(340, 560, 100, 20))
	r.mover(Rect2(480, 540, 110, 18), Vector2(100, 0), 2.2)
	r.hidden_block(Rect2(760, 540, 100, 20))
	r.saw(Vector2(380, 450), Vector2(900, 450), 2.0)
	r.exit_zone(Rect2(1200, 560, 60, 80))

# Tower: dash boots, then a climb with a moving platform, a spinning cross and a dash-only gap.
static func _s4(r: RoomBase) -> void:
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 260, 80))
	r.pickup(Vector2(180, 612), "dash")
	r.spikes(Rect2(260, 696, 1020, 14))
	r.block(Rect2(300, 570, 100, 18))
	r.block(Rect2(470, 500, 100, 18))
	r.mover(Rect2(620, 430, 100, 18), Vector2(0, -60), 2.0)
	r.block(Rect2(800, 380, 100, 18))
	r.spinner(Vector2(700, 300), 55.0, 3.0)
	r.block(Rect2(1000, 330, 100, 18))
	r.block(Rect2(1140, 260, 140, 18))
	r.exit_zone(Rect2(1200, 180, 60, 80))

# Skyway: grapple hand across a windy gap with swaying platforms.
static func _s5(r: RoomBase) -> void:
	r.tint = Color("3a4a63")
	r.bg_color = Color("101826")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 240, 80))
	r.block(Rect2(1040, 640, 240, 80))
	r.pickup(Vector2(170, 612), "grapple")
	r.spikes(Rect2(240, 696, 800, 14))
	r.wind(Rect2(240, 0, 800, 700), Vector2(-250, 0))
	r.mover(Rect2(330, 580, 110, 18), Vector2(110, 0), 2.4)
	r.hook(Vector2(620, 340))
	r.mover(Rect2(660, 520, 110, 18), Vector2(110, 0), 2.8)
	r.hook(Vector2(900, 330))
	r.block(Rect2(960, 540, 90, 18))
	r.exit_zone(Rect2(1190, 560, 60, 80))

# Roof: every limb in one room. Arm on the plate, hidden stones, dash gap, grapple to the last ledge.
static func _s6(r: RoomBase) -> void:
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	r.spawn = Vector2(100, 600)
	r.block(Rect2(0, 640, 300, 80))
	r.plate_and_door(Rect2(150, 630, 100, 10), Rect2(520, 300, 30, 400))
	r.spikes(Rect2(300, 696, 980, 14))
	r.block(Rect2(600, 600, 120, 40))
	r.hidden_block(Rect2(820, 540, 100, 18))
	r.crumble(Rect2(1000, 480, 100, 18))
	r.saw(Vector2(620, 440), Vector2(1040, 440), 1.4)
	r.hook(Vector2(960, 300))
	r.block(Rect2(1140, 330, 140, 18))
	r.exit_zone(Rect2(1200, 250, 60, 80))   # HOME

# ============================================================ v2: precise layouts from the second set of sketches
# L1 Lab: Subject 0 on a box at far left, spring legs, three pillars with spike runs between, ladder up to next level.
static func _t1(r: RoomBase) -> void:
	r.spawn = Vector2(70, 570)
	r.block(Rect2(0, 640, 1280, 80))
	r.block(Rect2(20, 600, 100, 40))                    # the box Subject 0 stands on
	r.pickup(Vector2(290, 612), "leg")                  # spring legs
	r.block(Rect2(480, 570, 80, 70))                    # pillar 1 (low)
	r.spikes(Rect2(560, 626, 110, 14))
	r.block(Rect2(670, 480, 90, 160))                   # pillar 2 (medium)
	r.spikes(Rect2(760, 626, 110, 14))
	r.block(Rect2(870, 400, 410, 240))                  # pillar 3 (tall) with ledge to the ladder
	r.ladder_exit(Rect2(1180, 310, 50, 90))

# L2 Street: two screens wide (2560px), camera pans. Max jump is ~110px, so steps stay <= 80px.
static func _t2(r: RoomBase) -> void:
	r.width = 2560.0
	r.tint = Color("4a5560")
	r.bg_color = Color("1a2029")
	r.spawn = Vector2(70, 600)
	r.block(Rect2(0, 640, 2560, 80))
	# --- background: tall buildings
	for b in [Rect2(120, 120, 220, 520), Rect2(520, 60, 260, 580), Rect2(1080, 100, 240, 540), Rect2(1900, 80, 300, 560)]:
		r.deco(b, Color("2a3340"))
		for wy in range(int(b.position.y) + 40, 600, 70):
			for wx in range(int(b.position.x) + 24, int(b.end.x) - 30, 54):
				r.deco(Rect2(wx, wy, 26, 36), Color("39475a"), -4)
	# --- screen 1
	r.car(250)                                              # abandoned car
	r.pickup(Vector2(520, 612), "arm")                      # throwable arm
	# balconies climbing the tall building to the wall top (steps of 75px)
	r.block(Rect2(580, 565, 100, 14))
	r.block(Rect2(450, 490, 100, 14))
	r.block(Rect2(580, 415, 100, 14))
	r.block(Rect2(450, 340, 100, 14))
	r.block(Rect2(580, 265, 140, 14))
	r.bird(Vector2(480 - 60, 470), Vector2(480 + 60, 470), 2.6, 18.0)                               # bird on balcony 2 (left end)
	r.block(Rect2(760, 265, 40, 375))                       # the tall wall (top at y=265)
	r.block(Rect2(720, 265, 80, 14))                        # walkway over the wall
	# --- car mountain (stepped, walkable)
	r.block(Rect2(860, 585, 120, 55))
	r.block(Rect2(920, 530, 120, 110))
	r.block(Rect2(980, 475, 120, 165))
	r.block(Rect2(1100, 530, 80, 110))
	r.block(Rect2(1160, 585, 80, 55))
	r.bird(Vector2(1040 - 60, 455), Vector2(1040 + 60, 455), 2.6, 18.0)                              # bird on top of the mountain
	# --- screen 2
	# tree: trunk + canopy platforms, reached from the mountain
	r.deco(Rect2(1560, 340, 36, 300), Color("5a3d28"))
	r.deco(Rect2(1440, 270, 300, 110), Color("2f5a38"), -3)
	r.block(Rect2(1300, 565, 90, 14))                       # steps up through the branches (75px each)
	r.block(Rect2(1410, 490, 90, 14))
	r.block(Rect2(1520, 415, 100, 14))
	r.block(Rect2(1630, 340, 110, 14))                      # canopy platform (top of tree)
	r.bird(Vector2(1700 - 60, 320), Vector2(1700 + 60, 320), 2.6, 18.0)
	r.block(Rect2(1760, 400, 90, 14))
	r.block(Rect2(1880, 470, 90, 14))
	r.spikes(Rect2(1760, 626, 220, 14))                     # glass and wreckage under the route
	# car pile near the elevator
	r.block(Rect2(2000, 585, 120, 55))
	r.block(Rect2(2060, 530, 100, 110))
	# elevator at the end: arm on the floor button opens the door
	r.deco(Rect2(2330, 420, 200, 220), Color("2b3138"))
	r.plate_and_door(Rect2(2200, 630, 90, 10), Rect2(2335, 530, 20, 110))
	r.block(Rect2(2330, 510, 200, 20))                      # elevator roof
	r.block(Rect2(2510, 510, 20, 130))                      # back wall
	r.exit_zone(Rect2(2380, 570, 110, 70))                  # elevator down to the subway

# L3 Subway (dark): three stacked tiers (600px apart), camera zoomed in so you only ever see one.
# Each tier: arrive at the far left -> run right past hidden traps/enemies -> tall wall with a DOOR.
# The orange button above the wall opens it when the thrown arm hits it (RIGHT-CLICK toward it).
# Behind the door: the tier's blue train button ([O]) and then the escalator down (tiers 1-2) or the train (tier 3).
# Escalator: camera freezes, you ride out of the bottom of the frame, camera cuts, you slide in from above
# at the left of the next tier. Respawn is R. Train key is Enter.
static func _t3(r: RoomBase) -> void:
	r.width = 2600.0
	r.height = 1900.0
	r.cam_zoom = 1.4
	r.tint = Color("2f4150")
	r.bg_color = Color("0d141b")
	var Y1 := 400.0
	var Y2 := 1000.0
	var Y3 := 1600.0
	r.spawn = Vector2(110, Y1 - 40)
	r.block(Rect2(0, 0, 30, 1900))
	r.block(Rect2(2570, 0, 30, 1900))
	r.block(Rect2(0, Y3 + 24, 2600, 300))
	for Y in [Y1, Y2, Y3]:
		for px in range(240, 2500, 300):
			r.deco(Rect2(px, Y - 330, 20, 330), Color("1b2733"))
	# ============ TIER 1 (easy) ============
	r.block(Rect2(0, Y1, 1900, 24))
	r.block(Rect2(2020, Y1, 580, 24))
	r.deco(Rect2(40, Y1 - 150, 120, 150), Color("2b3138"))           # the elevator you came down in
	r.pickup(Vector2(380, Y1 - 28), "xray")
	r.hidden_trap(Rect2(560, Y1 - 14, 50, 14))                        # jump it (or hold F to see it)
	r.block(Rect2(760, Y1 - 70, 110, 14))
	r.rat(Vector2(940, Y1 - 16), Vector2(1140, Y1 - 16), 2.6)
	r.hidden_trap(Rect2(1260, Y1 - 14, 50, 14))
	r.checkpoint(Vector2(1400, Y1 - 45))
	r.shoot_button(Vector2(1712, Y1 - 335), r.gate(Rect2(1700, Y1 - 300, 24, 300)))
	r.train_button(Vector2(1810, Y1 - 28))                            # behind the door
	r.escalator(Rect2(1900, Y1, 120, 20), 140.0, Y2)
	# ============ TIER 2 (medium) ============
	r.block(Rect2(0, Y2, 1900, 24))
	r.block(Rect2(2020, Y2, 580, 24))
	r.arrival_shaft(Rect2(80, Y2 - 420, 120, 420))
	r.hidden_trap(Rect2(520, Y2 - 14, 50, 14))
	r.mover(Rect2(640, Y2 - 120, 100, 14), Vector2(150, 0), 2.2)
	r.saw(Vector2(640, Y2 - 210), Vector2(900, Y2 - 210), 1.6)
	r.hidden_block(Rect2(860, Y2 - 90, 90, 14))
	r.bird(Vector2(560, Y2 - 170), Vector2(1000, Y2 - 170), 3.0, 26.0)
	r.rat(Vector2(1020, Y2 - 16), Vector2(1160, Y2 - 16), 1.8)
	r.hidden_trap(Rect2(1220, Y2 - 14, 50, 14))
	r.hidden_trap(Rect2(1400, Y2 - 14, 50, 14))
	r.checkpoint(Vector2(1500, Y2 - 45))
	r.shoot_button(Vector2(1712, Y2 - 335), r.gate(Rect2(1700, Y2 - 300, 24, 300)))
	r.train_button(Vector2(1810, Y2 - 28))
	r.escalator(Rect2(1900, Y2, 120, 20), 140.0, Y3)
	# ============ TIER 3 (hard) ============
	r.block(Rect2(0, Y3, 2600, 24))
	r.arrival_shaft(Rect2(80, Y3 - 420, 120, 420))
	r.spikes(Rect2(420, Y3 - 14, 90, 14))
	r.rat(Vector2(540, Y3 - 16), Vector2(640, Y3 - 16), 1.4)
	r.hidden_trap(Rect2(720, Y3 - 14, 50, 14))
	r.piston(Vector2(860, Y3), 150, 1.3)
	r.saw(Vector2(560, Y3 - 140), Vector2(940, Y3 - 140), 1.2)
	r.hidden_trap(Rect2(1010, Y3 - 14, 50, 14))
	r.rat(Vector2(1090, Y3 - 16), Vector2(1170, Y3 - 16), 1.0)
	r.bird(Vector2(1000, Y3 - 120), Vector2(1400, Y3 - 120), 2.2, 24.0)
	r.hidden_trap(Rect2(1300, Y3 - 14, 50, 14))
	r.checkpoint(Vector2(1500, Y3 - 45))
	r.shoot_button(Vector2(1712, Y3 - 335), r.gate(Rect2(1700, Y3 - 300, 24, 300)))
	r.train_button(Vector2(1810, Y3 - 28))
	r.train(Rect2(1950, Y3 - 140, 560, 140))                          # the train: all 3 blue buttons, then Enter
	r.exit_zone(Rect2(2595, -300, 4, 4))

# L4 Tower: tall climb, camera zoomed in. Every hop validated against the measured physics
# (jump 107 up / 161 across; +dash 215 across; +up-dash 214 up): jump hops rise<=80 gap<=100, dash gaps 140-175.
# Route: steps -> DASH1 -> cross wide saw platform A (right to left) -> zigzag -> vertical lift -> zigzag left ->
# DASH2 -> cross wide saw platform B (left to right) -> UP-DASH -> sideways moving bridge -> zigzag up -> top (saw C), window, door.
static func _t4(r: RoomBase) -> void:
	r.width = 1280.0
	r.height = 2700.0
	r.cam_zoom = 1.5
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	var F := 2500.0
	r.spawn = Vector2(150, F - 40)
	r.block(Rect2(0, F, 1280, 100))
	r.block(Rect2(0, 0, 90, 2800.0))
	r.block(Rect2(1190, 0, 90, 2800.0))
	for yy in range(0, int(F), 220):
		r.deco(Rect2(90, yy, 1100, 6), Color("2a2238"))
	r.pickup(Vector2(230, F - 28), "dash")                  # dash boots
	r.block(Rect2(330, F - 70, 130, 14))
	r.block(Rect2(520, F - 140, 130, 14))
	r.block(Rect2(710, F - 210, 110, 14))
	r.block(Rect2(985, F - 210, 140, 14))
	r.block(Rect2(840, F - 290, 120, 14))
	r.block(Rect2(330, F - 370, 460, 14))
	r.block(Rect2(130, F - 450, 120, 14))
	r.block(Rect2(330, F - 530, 120, 14))
	r.block(Rect2(520, F - 610, 120, 14))
	r.block(Rect2(710, F - 690, 120, 14))
	r.block(Rect2(900, F - 770, 120, 14))
	r.block(Rect2(840, F - 1010, 120, 14))
	r.block(Rect2(660, F - 1090, 110, 14))
	r.block(Rect2(470, F - 1170, 110, 14))
	r.block(Rect2(290, F - 1250, 110, 14))
	r.block(Rect2(130, F - 1330, 110, 14))
	r.block(Rect2(410, F - 1330, 490, 14))
	r.block(Rect2(940, F - 1490, 110, 14))
	r.block(Rect2(250, F - 1490, 110, 14))
	r.block(Rect2(120, F - 1570, 110, 14))
	r.block(Rect2(300, F - 1650, 110, 14))
	r.block(Rect2(490, F - 1730, 110, 14))
	r.block(Rect2(680, F - 1810, 110, 14))
	r.block(Rect2(870, F - 1890, 110, 14))
	r.block(Rect2(700, F - 1970, 110, 14))
	r.block(Rect2(510, F - 2050, 110, 14))
	r.block(Rect2(130, F - 2130, 310, 14))
	r.mover(Rect2(1060, F - 770, 110, 14), Vector2(0, -240), 2.8)   # N
	r.mover(Rect2(790, F - 1490, 110, 14), Vector2(-360, 0), 3.2)   # Y
	r.saw(Vector2(350, F - 388), Vector2(770, F - 388), 2.6)          # saw A: cross platform g, time your jump
	r.saw(Vector2(390, F - 1348), Vector2(880, F - 1348), 2.4)        # saw B: cross platform u
	r.checkpoint(Vector2(190, F - 495))
	r.checkpoint(Vector2(900, F - 1055))
	r.checkpoint(Vector2(995, F - 1535))
	r.checkpoint(Vector2(175, F - 1615))
	r.sunset_window(Rect2(200, F - 2400, 560, 170))
	r.deco(Rect2(138, F - 2240, 90, 110), Color("5a4630"), -2)
	r.exit_zone(Rect2(150, F - 2230, 66, 100))             # door into the skyway

# L5 Skyway: grapple hand at the start, spiked-edge platforms with fans, wind, side-to-side movers, ramp up to the roof.
static func _t5(r: RoomBase) -> void:
	r.tint = Color("3a4a63")
	r.bg_color = Color("101826")
	r.spawn = Vector2(70, 600)
	r.block(Rect2(0, 640, 240, 80))
	r.pickup(Vector2(170, 612), "grapple")              # grapple hand
	r.spikes(Rect2(240, 696, 1040, 14))                 # fall down = restart
	r.wind(Rect2(240, 0, 760, 700), Vector2(-220, 0))
	r.mover(Rect2(300, 560, 120, 16), Vector2(120, 0), 2.4)   # moves side to side
	r.hook(Vector2(520, 340))
	r.mover(Rect2(560, 470, 120, 16), Vector2(120, 0), 2.8)
	r.hook(Vector2(800, 300))
	r.block(Rect2(860, 400, 110, 16))
	r.block(Rect2(1000, 330, 280, 16))                  # roof end, ramp up
	r.block(Rect2(1090, 300, 190, 16))
	r.exit_zone(Rect2(1200, 220, 60, 80))

# L6 Roof: rooftop finale using every limb to reach the last ledge: HOME.
static func _t6(r: RoomBase) -> void:
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	r.spawn = Vector2(70, 600)
	r.block(Rect2(0, 640, 300, 80))
	r.plate_and_door(Rect2(150, 630, 100, 10), Rect2(520, 300, 30, 400))   # arm
	r.spikes(Rect2(300, 696, 980, 14))
	r.block(Rect2(600, 600, 120, 40))
	r.hidden_block(Rect2(820, 540, 100, 18))            # x-ray
	r.crumble(Rect2(1000, 480, 100, 18))                # spring legs
	r.saw(Vector2(620, 440), Vector2(1040, 440), 1.4)
	r.hook(Vector2(960, 300))                           # grapple
	r.block(Rect2(1140, 330, 140, 18))                  # dash across the last gap
	r.exit_zone(Rect2(1200, 250, 60, 80))               # HOME
