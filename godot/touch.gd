# On-screen touch controls for phones in landscape (the user asked for phone play, 2026-10-24).
# Every finger is read on its own (InputEventScreenTouch/Drag by index), so Sora can walk with the left thumb while
# the right one swings or dodges. A finger on the left of the screen grabs a stick that appears under it; pushed to
# the rim she runs. The keys call the same functions as the keyboard; guard and run are held through main.touch_keys.
# The keys are drawn here, not made of Buttons: the mouse the browser makes out of a touch follows one finger only.
extends Control

var main: Node
var pad_idx := -1          # the finger on the stick, -1 for none
var pad_origin := Vector2.ZERO
var pad_at := Vector2.ZERO
var held := {}             # finger index -> key name, for the keys that act while held (guard)
const PAD_R := 80.0        # how far the knob goes
const RUN_AT := 0.92       # pushed this far the stick runs
const RUN_OFF := 0.84      # and it keeps running until it falls below this (a wobbling thumb at the edge no longer flips walk and run; delight idea 93)

static func run_state(len: float, was_running: bool) -> bool:
	return len >= RUN_AT or (was_running and len >= RUN_OFF)

# Where the play keys sit, one table for what is drawn and what a finger hits: key -> [distance from the right edge, from the
# bottom edge, radius], one row per size (delight idea 97): radii 10% and 24% bigger. The bigger sizes also move the keys apart,
# so the coins keep a gap of 10 px or more from each other and 12 px from the skill coins, and the top one stays under the
# minimap (186 px). The run key is there only with the one-hand setting (idea 90). The mirrored layout (idea 91) reads the
# same table from the left edge.
const GEOM := [
	{"attack": [80.0, 196.0, 58.0], "dodge": [196.0, 158.0, 42.0], "guard": [176.0, 270.0, 42.0], "crown": [64.0, 300.0, 42.0], "run": [310.0, 170.0, 42.0]},
	{"attack": [78.0, 164.0, 64.0], "dodge": [203.0, 162.0, 46.0], "guard": [194.0, 275.0, 46.0], "crown": [68.0, 293.0, 46.0], "run": [317.0, 173.0, 46.0]},
	{"attack": [78.0, 198.0, 72.0], "dodge": [277.0, 159.0, 52.0], "guard": [211.0, 293.0, 52.0], "crown": [330.0, 285.0, 52.0], "run": [399.0, 188.0, 52.0]},
]
const GUARD_SLACK := 36.0   # a thumb that slides this far past the guard key's rim still holds it (idea 94)
const FADE_AFTER := 8.0     # seconds with no finger down and no foe near, then the combat keys go faint (idea 100)
const FADE_TO := 0.3        # how faint
const SAY_FOR := 1.3        # the word over the bracelet key stays this long (idea 92)

var tex := {}
var guard_latch := false   # one-hand setting: a tap on the shield key holds it until the next tap (idea 90)
var run_latch := false     # and a tap on the run key runs until the next tap
var crown_say := ""        # the word for what the bracelet key does here, shown over it for a moment
var crown_say_t := 0.0
var idle_t := 0.0          # seconds of safe quiet; the combat keys fade after FADE_AFTER
var dim := 0.0             # 0 full, 1 faint

func lefty() -> bool:
	return bool(main.cfg.get("lefty", false))

func one_hand() -> bool:
	return bool(main.cfg.get("hold", false))

func size_level() -> int:
	return clampi(int(main.cfg.get("keysize", 0)), 0, GEOM.size() - 1)

# the left thumb's side: where a finger grabs the stick
func pad_side(x: float) -> bool:
	var w := get_viewport_rect().size.x
	return x > w * 0.55 if lefty() else x < w * 0.45

func latch_text() -> String:
	var out: Array = []
	if guard_latch:
		out.append(tr("막기 켜짐"))
	if run_latch:
		out.append(tr("달리기 켜짐"))
	return " / ".join(out)

func clear_latches() -> void:
	if guard_latch and not held.values().has("guard"):
		main.touch_keys.erase(KEY_L)
	if run_latch and pad_idx < 0:
		main.touch_keys.erase(KEY_SHIFT)
	guard_latch = false
	run_latch = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		clear_latches()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for n in ["attack", "dodge", "guard", "crown", "stick_base", "stick_knob"]:
		tex[n] = load("res://art/ui/touch_%s.png" % n)
	for n in ["zoom_in", "zoom_out"]: # the menu keys' round coins (art/ui/key_*.png)
		tex[n] = load("res://art/ui/key_%s.png" % n)

# where each key sits (centre, radius) for the screen as it is now; the skills are the HUD's own icons
func keys() -> Dictionary:
	var vs := get_viewport_rect().size
	var k := {}
	var g: Dictionary = GEOM[size_level()]
	# guard, dodge and the bracelet one size (the owner, 2026-10-28: "이 3개 아이콘도 크기 통일"; the bracelet was 38)
	for n in ["attack", "dodge", "guard", "crown"] + (["run"] if one_hand() else []):
		var a: Array = g[n]
		k[n] = [Vector2(a[0] if lefty() else vs.x - a[0], vs.y - a[1]), a[2]]
	# round coins like the menu keys, 60 px, a column left of them level with their two rows: clear of the boss bar
	# and the quest line under them
	k["zoom_in"] = [Vector2(vs.x - 368, 38), 30.0]
	k["zoom_out"] = [Vector2(vs.x - 368, 106), 30.0]
	for i in 4: # the skill icons hud.gd draws (U I O and the potion)
		k["skill%d" % i] = [main.ui.hud.skill_spot(i), main.ui.hud.skill_size() / 2.0 + 2.0]
	return k

# the keys are for play only: a story, the shop, a sheet or the settings take taps as clicks
func playing() -> bool:
	return not main.intro and not main.story_open and not main.shop_open and not main.settings_open \
		and not main.ui.journal.visible and not main.ui.help.visible and not main.ui.bag.visible and not main.way_open and main.down_t <= 0.0

func key_at(p: Vector2) -> String:
	var k := keys()
	for n in k:
		if p.distance_to(k[n][0]) <= k[n][1] + 6.0:
			return n
	return ""

var asked_full := false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventKey:
		idle_t = 0.0 # the first touch after a quiet spell acts as usual and brings the keys back at once
		dim = 0.0
	if event is InputEventScreenTouch:
		if event.pressed and not asked_full and OS.has_feature("web_android"):
			asked_full = true # Android browsers go full screen on a touch (iOS Safari cannot)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if event.pressed:
			if not playing():
				return
			var n := key_at(event.position)
			if n != "":
				press(n, event.index)
				get_viewport().set_input_as_handled()
			elif pad_side(event.position.x) and pad_idx < 0:
				pad_idx = event.index
				pad_origin = event.position
				pad_at = event.position
				get_viewport().set_input_as_handled()
		else:
			if event.index == pad_idx:
				pad_idx = -1
				main.touch_move = Vector2.ZERO
				if not run_latch:
					main.touch_keys.erase(KEY_SHIFT)
			if held.has(event.index):
				main.touch_keys.erase(KEY_L)
				held.erase(event.index)
	elif event is InputEventScreenDrag and held.has(event.index):
		# a thumb on the shield key may wander a little; past the rim and the slack it has let go (idea 94)
		var gk: Array = keys().get(held[event.index], [])
		if not gk.is_empty() and event.position.distance_to(gk[0]) > gk[1] + GUARD_SLACK:
			main.touch_keys.erase(KEY_L)
			held.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == pad_idx:
		pad_at = event.position
		var v: Vector2 = (pad_at - pad_origin) / PAD_R
		if v.length() > 1.0:
			pad_origin = pad_at - v.normalized() * PAD_R # the stick follows a thumb that slides past the rim
			v = v.normalized()
		main.touch_move = v if v.length() > 0.15 else Vector2.ZERO
		if run_latch or run_state(v.length(), main.touch_keys.has(KEY_SHIFT)):
			main.touch_keys[KEY_SHIFT] = true
		else:
			main.touch_keys.erase(KEY_SHIFT)
		get_viewport().set_input_as_handled()

func press(n: String, idx: int) -> void:
	match n:
		"attack": main.attack()
		"dodge": main.dodge()
		"guard":
			if one_hand(): # a tap holds the shield, the next tap lets go
				guard_latch = not guard_latch
				if guard_latch:
					main.touch_keys[KEY_L] = true
				else:
					main.touch_keys.erase(KEY_L)
			else:
				main.touch_keys[KEY_L] = true
				held[idx] = n
		"run":
			run_latch = not run_latch
			if not run_latch and pad_idx < 0:
				main.touch_keys.erase(KEY_SHIFT)
		"crown":
			crown_say = main.crown_label() # asked before the key acts: the word is what it was about to do
			crown_say_t = SAY_FOR if crown_say != "" else 0.0
			main.crown_key()
		"zoom_in": main.cam_dist = clampf(main.cam_dist - 2.4, 8, 26)
		"zoom_out": main.cam_dist = clampf(main.cam_dist + 2.4, 8, 26)
		"skill0", "skill1", "skill2": main.use_skill(int(n.right(1)))
		"skill3": main.drink_potion()

# the menu keys and the minimap step aside while a story, the shop, a sheet or the settings are up
func step_aside() -> void:
	var up: bool = main.intro or main.story_open or main.shop_open or main.settings_open or main.ui.journal.visible or main.ui.help.visible or main.ui.bag.visible
	for c in [main.ui.hint, main.ui.sound_btn, main.ui.journal_btn, main.ui.settings_btn, main.ui.bag_btn, main.ui.mini.get_parent()]:
		c.visible = not up

func _process(dt: float) -> void:
	step_aside()
	if not playing():
		if pad_idx >= 0: # a story or a sheet opened under the thumb: let go of everything
			pad_idx = -1
			main.touch_move = Vector2.ZERO
			main.touch_keys.clear()
			held.clear()
		clear_latches() # a sheet, a story, a fall: the latches are let go too
	elif (guard_latch or run_latch) and not one_hand():
		clear_latches()
	else:
		if guard_latch:
			main.touch_keys[KEY_L] = true
		if run_latch:
			main.touch_keys[KEY_SHIFT] = true
	crown_say_t = maxf(0.0, crown_say_t - dt)
	# safe quiet: no finger down, nothing hunting her; then the combat keys fade, the touch itself brings them back (idea 100)
	var calm: bool = playing() and pad_idx < 0 and held.is_empty() and not main.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - main.player.x, e.z - main.player.z).length() < 10.0)
	idle_t = idle_t + dt if calm else 0.0
	dim = move_toward(dim, 1.0 if idle_t >= FADE_AFTER else 0.0, dt / 1.2)
	queue_redraw()

func _draw() -> void:
	var vs := get_viewport_rect().size
	if vs.y > vs.x: # held upright: ask for landscape
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.04, 0.09, 0.92))
		var msg: String = tr("가로로 돌려 주세요")
		var f: Font = main.ui_font
		var w := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(f, Vector2((vs.x - w) / 2.0, vs.y / 2.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#eef3ff"))
		return
	if not playing():
		return
	# the stick: under the thumb while held, a faint one at rest where the left thumb usually lies
	var fade := 1.0 - dim * (1.0 - FADE_TO) # the combat keys and the resting stick only
	var base := pad_origin if pad_idx >= 0 else Vector2(vs.x - 150 if lefty() else 150, vs.y - 160)
	var knob := pad_at if pad_idx >= 0 else base
	var a := 0.95 if pad_idx >= 0 else 0.45 * fade
	draw_texture_rect(tex.stick_base, Rect2(base - Vector2(96, 96), Vector2(192, 192)), false, Color(1, 1, 1, a))
	draw_texture_rect(tex.stick_knob, Rect2(knob - Vector2(40, 40), Vector2(80, 80)), false, Color(1, 1, 1, a))
	var k := keys()
	var f: Font = main.ui_font
	for n in ["attack", "dodge", "guard", "crown", "run", "zoom_in", "zoom_out"]:
		if not k.has(n):
			continue
		var c: Vector2 = k[n][0]
		var r: float = k[n][1]
		var lit := held.values().has(n)
		var latched: bool = (n == "guard" and guard_latch) or (n == "run" and run_latch)
		var al := 0.9 * (fade if n in ["attack", "dodge", "guard", "run"] and not lit and not latched else 1.0)
		if n == "run": # no picture of its own: a navy coin with a gold word, a gold rim while it is on
			draw_circle(c, r, Color(0.05, 0.1, 0.22, 0.75 * al / 0.9))
			draw_arc(c, r, 0.0, TAU, 40, Color("#ffd86a") if latched else Color(0.62, 0.71, 1.0, 0.6 * al / 0.9), 3.0 if latched else 2.0)
			var rw := f.get_string_size(tr("달리기"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			draw_string(f, c + Vector2(-rw / 2.0, 6.0), tr("달리기"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.93, 0.7, al / 0.9))
			if latched:
				draw_circle(c + Vector2(r * 0.7, -r * 0.7), 6.0, Color("#ffd86a"))
			continue
		var sc := 1.0 if n.begins_with("zoom") else 1.1 # the coins are drawn at their own size, the diamonds a little over it
		draw_texture_rect(tex[n], Rect2(c - Vector2(r, r) * sc, Vector2(r, r) * 2.0 * sc), false, Color(1.2, 1.2, 1.2) if lit else Color(1, 1, 1, al))
		if lit and n == "guard": # held: the rim a thumb may drift to before it lets go
			draw_arc(c, r + GUARD_SLACK, 0.0, TAU, 48, Color(1, 0.93, 0.7, 0.35), 2.0)
		if latched: # latched: a gold dot on the key
			draw_circle(c + Vector2(r * 0.7, -r * 0.7), 6.0, Color("#ffd86a"))
	# the latches stay told in words under the keys while they are on (idea 90)
	var lt := latch_text()
	if lt != "":
		var lw := f.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var lc: Vector2 = k["attack"][0]
		var ly: float = lc.y + (k["attack"][1] as float) + 20.0
		draw_string(f, Vector2(clampf(lc.x - lw / 2.0, 6.0, vs.x - lw - 6.0), ly), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffd86a"))
	if crown_say_t > 0.0 and crown_say != "": # what the bracelet key is about to do, above the key the finger hides (idea 92)
		var cc: Vector2 = k["crown"][0]
		var cw := f.get_string_size(crown_say, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var bx := clampf(cc.x - cw / 2.0 - 8.0, 4.0, vs.x - cw - 20.0)
		var by: float = cc.y - (k["crown"][1] as float) * 1.1 - 38.0
		var ca := clampf(crown_say_t / 0.4, 0.0, 1.0)
		draw_rect(Rect2(bx, by, cw + 16.0, 32.0), Color(0.02, 0.04, 0.09, 0.82 * ca))
		draw_string(f, Vector2(bx + 8.0, by + 24.0), crown_say, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.93, 0.7, ca))
