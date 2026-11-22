class_name Rooms
## Room layouts, one function per room. Rooms are 1280x720, floor top at y=640.
## Built from docs/design.md (chapter 0 room list) and narrative/game-brief.md (show, test, twist).

const ORDER_OLD := ["c0r1", "c0r2", "c0r3", "c0r4", "c1r1", "c1r2", "c1r3", "c2r1", "c2r2", "c2r3", "c3r1", "c3r2", "c3r3", "c4r1"]

const ORDER := ["t1", "t2", "t3", "t4", "t5", "t6", "t7"]

const INTRO := {
	"t1": "res://narrative/dialogue/chapter_0_lab.json",
	"t2": "res://narrative/dialogue/chapter_1_street.json",
	"t3": "res://narrative/dialogue/chapter_2_subway.json",
	"t4": "res://narrative/dialogue/chapter_4_tower.json",
	"t5": "res://narrative/dialogue/chapter_3_skyway.json",
	"t6": "res://narrative/dialogue/chapter_5_roof.json",
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
		"t7": "The Ledge",
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
		"t7": _t7(r)
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
	r.width = 3200.0
	r.height = 1300.0
	r.floor_y = 1220.0
	var F := 1220.0
	r.tint = Color("4a5560")
	r.bg_color = Color("1a2029")
	r.spawn = Vector2(70, F - 40)
	r.block(Rect2(0, F, 3200, 80))
	r.fall_death = 360.0                                       # a long fall off a building kills you
	r.street_ground(0, 3200, 0)
	for bx in range(0, 3200, 230):
		r.deco(Rect2(bx, 520 + (bx / 230 % 3) * 90, 150, 800), Color("1f2733"), -7)
	r.car(200)
	r.pickup(Vector2(470, F - 28), "arm")                     # throwable arm
	# Four tall buildings with 360px gaps (far past jump range). Only A can be climbed from the street.
	# Roofs B and C each have a button: throw the arm at it to start the platform to the next roof.
	var tops := 260.0
	var A := Rect2(560, tops, 260, F - tops)
	var B := Rect2(1180, tops + 40, 260, F - tops - 40)
	var C := Rect2(1800, tops - 20, 260, F - tops + 20)
	var D := Rect2(2420, tops + 50, 260, F - tops - 50)
	var bs := [A, B, C, D]
	for bd in bs:
		r.tower_building(bd)
	r.balcony_stack(A.position.x, -1, F - 70, A.position.y + 55)
	# birds in a line with A's balconies (same height as each balcony, patrolling its width)
	var n := int(ceil((F - 70 - (A.position.y + 55)) / 70.0))
	var st := (F - 70 - (A.position.y + 55)) / float(n)
	for i in [2, 4, 6]:
		if i <= n:
			r.bird(Vector2(A.position.x - 160, F - 70 - st * i - 45), Vector2(A.position.x - 60, F - 70 - st * i - 45), 2.0, 4.0)
	# bridges. Roof A has no button; roofs B, C and D each have the button for the platform that leads to them.
	var w := 100.0
	var mv: Array = []
	for i in 3:
		var from: Rect2 = bs[i]
		var to: Rect2 = bs[i + 1]
		var start := Rect2(from.end.x, from.position.y, w, 16)
		var delta := Vector2(to.position.x - w - from.end.x, to.position.y - from.position.y)
		# the button is on the DESTINATION roof: throw the arm across the gap to start the platform
		r.arm_mover(start, delta, 2.6, Vector2(to.position.x + 70.0, to.position.y - 50.0))
	# last roof: a lift that waits until you stand on it, then carries you down to the street
	r.stand_lift(Rect2(D.end.x, D.position.y, w, 16), F - D.position.y - 16)
	# roof birds: one spawns high above a roof every 10s, tracks you, dives, climbs back if it misses.
	# At most 5 at once (the oldest leaves when a sixth would spawn).
	for bd in bs:
		var rb: Rect2 = bd
		r.roof_bird_spawner(rb, 10.0)
	# ground: wrecked cars parked on the road
	r.car(870)
	r.car(1490)
	r.car(2110)
	# --- end: ceiling-to-floor wall with an elevator door; arm-shot button on its face
	r.elevator_wall(2870, 60)
	r.elevator_exit(Rect2(2960, F - 100, 120, 100))

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
	# Fair-play rules for this level: hidden traps always show a crack + vent slits on the floor (F reveals the
	# spikes), every hazard has a safe tile before it, hops are <=80px up / <=140px across, no checkpoints:
	# a death sends you back to the start of the tier, so each tier is short and readable.
	r.tier_floors = [Y1, Y2, Y3]
	r.tier_spawns = [Vector2(110, Y1 - 40), Vector2(330, Y2 - 40), Vector2(330, Y3 - 40)]
	# ============ TIER 1 (easy: learn x-ray, rats and the arm button) ============
	r.tier_mark()
	r.block(Rect2(0, Y1, 1900, 24))
	r.block(Rect2(2020, Y1, 580, 24))
	r.deco(Rect2(40, Y1 - 150, 120, 150), Color("2b3138"))           # the elevator you came down in
	r.pickup(Vector2(380, Y1 - 28), "xray")
	r.hidden_trap(Rect2(560, Y1 - 14, 50, 14))                        # crack on the floor = trap
	r.block(Rect2(760, Y1 - 70, 110, 14))                             # optional high route
	r.rat_spawner(Vector2(1600, Y1 - 16), Vector2(700, Y1 - 16), 6.0)  # a rat every 10s, from the door side
	r.hidden_trap(Rect2(1250, Y1 - 14, 50, 14))
	r.wall_door(Rect2(1690, Y1 - 420, 44, 420), 100.0)
	r.train_button(Vector2(1810, Y1 - 28))                            # behind the door, on the wall
	r.escalator(Rect2(1900, Y1, 120, 20), 330.0, Y2)
	# ============ TIER 2 (medium: spikes, a moving bridge, a saw you walk under) ============
	r.tier_mark()
	r.block(Rect2(0, Y2, 1900, 24))
	r.block(Rect2(2020, Y2, 580, 24))
	r.hidden_trap(Rect2(560, Y2 - 14, 50, 14))
	r.spikes(Rect2(700, Y2 - 14, 180, 14))                            # visible spike strip
	r.mover(Rect2(690, Y2 - 70, 90, 14), Vector2(110, 0), 2.2)       # the bridge over it (or jump 180px with dash)
	r.saw(Vector2(960, Y2 - 70), Vector2(1200, Y2 - 70), 1.8)        # walk under it, do not jump
	r.rat_spawner(Vector2(1640, Y2 - 16), Vector2(700, Y2 - 16), 5.0)
	r.hidden_trap(Rect2(1330, Y2 - 14, 50, 14))
	r.wall_door(Rect2(1690, Y2 - 420, 44, 420), 100.0)
	r.train_button(Vector2(1810, Y2 - 28))
	r.escalator(Rect2(1900, Y2, 120, 20), 330.0, Y3)
	# ============ TIER 3 (hard: timing, but every hazard has room to react) ============
	r.tier_mark()
	r.block(Rect2(0, Y3, 2600, 24))
	r.spikes(Rect2(520, Y3 - 14, 80, 14))
	r.rat_spawner(Vector2(1640, Y3 - 16), Vector2(700, Y3 - 16), 4.2)
	r.hidden_trap(Rect2(920, Y3 - 14, 50, 14))
	r.piston(Vector2(1080, Y3), 150, 1.5)                             # wait until it drops, then walk by
	r.saw(Vector2(1200, Y3 - 70), Vector2(1440, Y3 - 70), 1.5)       # walk under it
	r.wall_door(Rect2(1690, Y3 - 420, 44, 420), 100.0)
	r.train_button(Vector2(1810, Y3 - 28))
	r.train(Rect2(1950, Y3 - 140, 560, 140))                          # the train: all 3 blue buttons, then Enter
	r.exit_zone(Rect2(2595, -300, 4, 4))

# L4 Tower: tall climb, camera zoomed in. Every hop validated against the measured physics
# (jump 107 up / 161 across; +dash 215 across; +up-dash 214 up): jump hops rise<=80 gap<=100, dash gaps 140-175.
# Route: steps -> DASH1 -> cross wide saw platform A (right to left) -> zigzag -> vertical lift -> zigzag left ->
# DASH2 -> cross wide saw platform B (left to right) -> UP-DASH -> sideways moving bridge -> zigzag up -> top (saw C), window, door.
static func _t4(r: RoomBase) -> void:
	# Built from tower.jpeg as 30 lines, line 1 at the top and line 30 at the bottom. Outside on the left is the
	# train station and the tower door; the shaft is x 520..1000 and the camera locks to its centre inside.
	r.width = 1500.0
	r.height = 1500.0
	r.cam_zoom = 1.6
	r.cam_center_x = 760.0
	r.cam_center_from = 470.0
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	var F := 1400.0
	var L := 520.0
	var R := 1000.0
	r.spawn = Vector2(120, F - 60)
	# row heights: normal step 40px (two lines = 80), but 3-line stretches use 27px so every hop is <= 81px
	var tight := [25, 24, 23, 21, 20, 19, 6, 5, 4]
	var Y := {30: F}
	for n in range(30, 1, -1):
		Y[n - 1] = Y[n] - (27.0 if tight.has(n) else 40.0)
	# ground, train (sits on the ground), walls, door
	r.block(Rect2(0, F, 1500, 200))
	r.train_arrival(Rect2(40, F - 120, 300, 120))
	r.block(Rect2(L - 40, 0, 40, F - 130))
	r.block(Rect2(R, 0, 40, F))
	r.deco(Rect2(L, 0, R - L, F), Color("1d1828"), -8)
	for yy in range(0, int(F), 200):
		r.deco(Rect2(L, yy, R - L, 4), Color("2a2238"), -7)
	r.deco(Rect2(L - 90, F - 150, 90, 150), Color("5a4630"), -2)         # the door in
	r.deco(Rect2(L - 80, F - 140, 70, 140), Color("3a2c1c"), -1)
	r.pickup(Vector2(440, F - 28), "dash")                                # dash boots on the ground by the door
	# platform slots (all inside the shaft). x, width. xray platforms are wider so the spike leaves room to land.
	var LS := [520.0, 120.0]
	var MS := [700.0, 120.0]
	var RS := [880.0, 115.0]
	var LX := [520.0, 160.0]
	var MX := [680.0, 160.0]
	var RX := [835.0, 160.0]
	var plat := func(n: int, slot: Array) -> void:
		r.block(Rect2(slot[0], Y[n], slot[1], 14))
	var xray_plat := func(n: int, slot: Array) -> void:
		r.block(Rect2(slot[0], Y[n], slot[1], 14))
		r.hidden_trap(Rect2(slot[0] + slot[1] / 2.0 - 18.0, Y[n] - 14, 36, 14))   # invisible until x-ray
	# ---- line 29: 1 platform
	plat.call(29, MS)
	# ---- line 27: 1 with spike (x-ray) and 1 without
	xray_plat.call(27, RX)
	plat.call(27, LS)
	# ---- line 25: 1
	plat.call(25, MS)
	# ---- line 22: platform with the arm button that starts the moving platform on line 21
	plat.call(22, RS)
	# ---- line 21: platform moving left to right (waits for the arm button on line 22)
	r.arm_mover(Rect2(520, Y[21], 120, 14), Vector2(190, 0), 2.6, Vector2(R - 28.0, Y[22] - 52.0))
	# ---- line 19: spike spawner from the left wall (spike flies across, 60px above the line-21 platform)
	r.spike_spawner(Vector2(L + 14, Y[21] - 60.0), 1, 3.4, 170.0, 440.0)
	# ---- line 18: 1
	plat.call(18, MS)
	# ---- line 16: 1 with spike (x-ray) and 1 without
	xray_plat.call(16, LX)
	plat.call(16, RS)
	# ---- line 14: 1
	plat.call(14, MS)
	# ---- line 12: arm-detect button on the left wall (starts the up/down platform on line 10)
	# ---- line 10: platform that moves up and down (rises from line 13 to line 10) and 1 platform
	r.arm_mover(Rect2(880, Y[13], 115, 14), Vector2(0, Y[10] - Y[13]), 2.4, Vector2(L + 30.0, Y[12]))
	plat.call(10, LS)
	# ---- line 8: 1 with spike (x-ray)
	xray_plat.call(8, MX)
	# ---- line 6: 1
	plat.call(6, RS)
	# ---- line 5: spike spawner from the right wall (spike flies left, 60px above the line-6 platform)
	r.spike_spawner(Vector2(R - 14, Y[6] - 60.0), -1, 3.4, 170.0, 440.0)
	# ---- line 3: 1 with spike (x-ray)
	xray_plat.call(3, MX)
	# ---- line 1: 2 platforms, the exit door on the right one
	plat.call(1, LS)
	plat.call(1, RS)
	r.sunset_window(Rect2(L + 40, Y[1] - 250.0, 400, 140))
	r.deco(Rect2(RS[0] + 12, Y[1] - 110.0, 90, 110), Color("5a4630"), -2)
	r.exit_zone(Rect2(RS[0] + 24, Y[1] - 100.0, 66, 100))

# L5 Skyway: grapple hand at the start, spiked-edge platforms with fans, wind, side-to-side movers, ramp up to the roof.
static func _t5(r: RoomBase) -> void:
	r.width = 3840.0
	r.tint = Color("3a4a63")
	r.bg_color = Color("101826")
	r.spawn = Vector2(110, 360)
	for b in [Rect2(500, 450, 140, 300), Rect2(1100, 400, 160, 350), Rect2(1800, 470, 120, 300), Rect2(2500, 430, 170, 320), Rect2(3100, 460, 140, 300)]:
		r.deco(b, Color("1a2434"), -6)
	r.block(Rect2(0, 400, 270, 320))                         # tower top (start)
	r.block(Rect2(3490, 400, 350, 320))                      # roof of the other building (end)
	r.pickup(Vector2(190, 372), "grapple")                   # grapple hand
	r.spikes(Rect2(270, 696, 3220, 14))                      # fall = restart
	# Platforms with GAPS of 330-400px: farther than a jump (~160) or a dash jump (~215), so you must swing.
	# A green hook hangs above every gap; swing across, let go, land, and grapple again after the 0.5s delay.
	# BROWN planks break after 5s of standing on them; grey ones are solid.
	var x := 340.0
	var i := 0
	var ys := [400, 380, 350, 380, 410, 380]
	while i < 6:
		var y: float = float(ys[i % ys.size()])
		var w := 130.0
		if i % 2 == 1:
			r.timed_plank(Rect2(x, y, w, 14), 5.0, 4.0)
		else:
			r.block(Rect2(x, y, w, 14))
			r.deco(Rect2(x, y, w, 4), Color("8fa3bd"), 3)
		var gap := 330.0 + float((i * 23) % 4) * 25.0
		var next_y: float = float(ys[(i + 1) % ys.size()])
		var hx := x + w + gap / 2.0
		r.hook(Vector2(hx, minf(y, next_y) - 170.0))
		x += w + gap
		i += 1
	r.block(Rect2(x, 400, 130, 14))                          # last platform before the roof (3325..3455); the roof starts at 3490
	r.wind(Rect2(1300, 0, 900, 700), Vector2(-60, 0))
	r.exit_zone(Rect2(3700, 320, 70, 80))                    # into the roof level

# L6 Roof: six screens (7680px). Each section tests one skill; the last combines them. Ends at the door.
# 1 spring legs + x-ray   2 grapple swing (hooks)   3 dash   4 arm + pulse gate   5 everything   6 the door
static func _t6(r: RoomBase) -> void:
	r.width = 7680.0
	r.tint = Color("4b3f5a")
	r.bg_color = Color("120f1a")
	r.spawn = Vector2(70, 600)
	r.sunset_window(Rect2(120, 120, 520, 160))
	# ============ 1: spring legs + x-ray (0..1280) ============
	r.block(Rect2(0, 640, 520, 80))
	r.block(Rect2(300, 590, 90, 50))
	r.spikes(Rect2(520, 696, 760, 14))
	r.block(Rect2(600, 590, 110, 16))
	r.block(Rect2(770, 540, 100, 16))
	r.hidden_block(Rect2(930, 500, 90, 16))
	r.block(Rect2(960, 560, 320, 16))
	r.rat(Vector2(1000, 544), Vector2(1190, 544), 2.0)
	# ============ 2: grapple swing (1280..2560) ============
	r.block(Rect2(1280, 640, 140, 80))
	r.spikes(Rect2(1420, 696, 1120, 14))
	for k in 5:
		var hx := 1560.0 + k * 200.0
		var hy := 330.0 + float(k % 2) * 40.0
		r.hook(Vector2(hx, hy))
		r.deco(Rect2(hx - 1, 0, 3, hy), Color("8794a3"), -2)
	r.bird(Vector2(1700, 470), Vector2(2100, 470), 3.0, 12.0)
	r.block(Rect2(2540, 600, 160, 16))
	# ============ 3: dash (2560..3840) ============
	r.crumble(Rect2(2780, 580, 90, 16), 3.0)
	r.block(Rect2(3050, 540, 100, 16))                       # 180px gap: dash across
	r.saw(Vector2(3050, 440), Vector2(3250, 440), 1.7)
	r.crumble(Rect2(3250, 500, 90, 16), 3.0)
	r.mover(Rect2(3400, 480, 100, 16), Vector2(0, -110), 2.2)
	r.block(Rect2(3640, 420, 100, 16))                       # dash again
	r.spikes(Rect2(2700, 696, 1140, 14))
	r.block(Rect2(3760, 560, 120, 16))
	# ============ 4: arm + pulse gate (3840..5120) ============
	r.block(Rect2(3880, 640, 1240, 80))
	r.sweeper(610, 4000, 4120, 1.2)
	r.rat(Vector2(4200, 624), Vector2(4400, 624), 1.8)
	r.pulse_gate(Rect2(4500, 300, 24, 340), 1.0, 1.7)
	r.plate_and_door(Rect2(4300, 630, 80, 10), Rect2(4760, 300, 24, 340))
	r.hidden_trap(Rect2(4620, 626, 50, 14))
	# ============ 5: everything (5120..6400) ============
	r.block(Rect2(5120, 560, 120, 16))
	r.spikes(Rect2(5240, 696, 1160, 14))
	r.hook(Vector2(5420, 330))
	r.hook(Vector2(5620, 300))
	r.crumble(Rect2(5700, 520, 90, 16), 3.0)
	r.saw(Vector2(5700, 420), Vector2(5900, 420), 1.5)
	r.block(Rect2(5990, 500, 90, 16))                        # dash gap
	r.mover(Rect2(6180, 470, 100, 16), Vector2(0, -120), 2.0)
	r.bird(Vector2(5800, 300), Vector2(6100, 300), 2.4, 14.0)
	r.block(Rect2(6340, 380, 140, 16))
	# ============ 6: the door (6400..7680) ============
	r.block(Rect2(6480, 640, 1200, 80))
	r.deco(Rect2(7380, 520, 90, 120), Color("5a4630"), -2)
	r.exit_zone(Rect2(7390, 530, 70, 110))

# L7 The Ledge: the ending. The robot sits on the edge of the outside of the roof and watches the sunset.
static func _t7(r: RoomBase) -> void:
	r.width = 1280.0
	r.tint = Color("2a2036")
	r.bg_color = Color("2e1f4d")
	r.spawn = Vector2(640, 548)
	r.city_backdrop(Rect2(0, 0, 1280, 640))
	r.block(Rect2(0, 600, 1280, 120))
	r.block(Rect2(520, 560, 240, 40))                        # the ledge
