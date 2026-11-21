class_name Progress
## Run-wide state carried between rooms (what the hero has recovered so far).

static var has_leg := false      # false = slow hop, true = full spring jump
static var has_arm := false      # right arm (detach)
static var has_grapple := false  # left arm
static var has_dash := false     # jet legs
static var room_index := 0
static var logs := 0

static func reset() -> void:
	has_leg = false
	has_arm = false
	has_grapple = false
	has_dash = false
	room_index = 0
	logs = 0

static func apply(p) -> void:
	p.has_arm = has_arm
	p.has_grapple = has_grapple
	p.has_dash = has_dash
	p.jump_mult = 1.0 if has_leg else 0.6
	p.speed_mult = 1.0 if has_leg else 0.55
