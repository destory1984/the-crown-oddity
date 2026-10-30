# Moon-watch observatory (v0.1.120; the owner chose "1안: 물길·관측원" on 2026-10-29, the design is shots/plans/option1_design.md with the
# ordeal of shots/plans/hero_journey_fix.md B): four rooms up from the hill's stair O, required before the castle.
# Noeul keeps Sora's hand steady at a post; the last room has three mirrors, a break (Sora signals alone and the bracelets go dark),
# a relay with Noeul, a brick moth and the answer stand. Maps and props are in observatory.gd (m.obs); state is on the main node (observatory_q, obs_*).
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const NEAR := 1.6          # E reaches the nearest device within this
const TURN := 2.0          # the platform turns for 2 s
const POST_SPEED := 4.0
const HAND_T := 0.8        # Noeul's hand under Sora's: the signal waits this long
const MOTH_HP := 2400
const FAN_REACH := 8.0
const FAN_SPREAD := 0.38   # the three lines of the fan, radians either side
const FAN_DMG := 24
const SLAM_DMG := 32
const CROSS_X := 13.0      # the cross's arms from the boss spot: east-west and north-south
const CROSS_Z := 9.5

var trans := {}            # the platform turning: {"room", "to", "t"}
var spawned := [false, false, false, false]
var post_room := -1        # Noeul is assigned to this room's post
var group_active := -1     # the last room: which mirror's fight is on
var boss_made := false
var lights_t := -1.0       # the answer lamps coming on
var lamps_told := false
var s_toast_t := 0.0
var quest_t := 0.0
var busy_t := 0.0          # Noeul's hand held under Sora's before a signal goes up
var rekindling := false
var gust_prev := false
var relay_told := false    # the first relay line was said this ordeal
var dark := false          # the bracelets are dark (after the break, until the test signal is up)

func _init(main: Main) -> void:
	m = main

func in_observatory() -> bool:
	return m.in_hill and m.player.x >= Main.OBS.OBS_X - 0.5

func room() -> int:
	return m.obs.room_of(m.player.x)

func sec(r: int) -> Dictionary:
	return m.obs_sec[r]

func fresh_sections() -> Array:
	return [{"record_read": false, "wind": false, "angle": 0, "mirror_dir": 2, "fixed": false},
		{"wind": false, "angle": 0, "mirror_dir": 2, "lamp_lit": false, "fixed": false},
		{"wind": false, "angle": 0, "mirror_dir": 2, "gust_seen": false, "fixed": false},
		{"record_read": false, "wind": false, "dirs": [2, 2, 2], "sent": false}]

func done() -> bool:
	return m.observatory_q >= 6

# the section a quest step belongs to: q1 the first floor, q2 the second, q3 the third, q4 and on the top
func work_room() -> int:
	return clampi(m.observatory_q - 1, 0, 3)

# ---- the way in (hill stair O): the hawk, the sparrow mill, the moon trial
func can_enter() -> bool:
	return m.hill_q >= 3 and m.mill_q >= 5 and m.trial_won

func gate_note() -> void:
	if m.toast_t > 0.0:
		return
	if m.hill_q < 3:
		m.toast("벽돌 매가 하늘을 지키고 있다")
	elif m.mill_q < 5:
		m.toast("먼저 참새 방앗간을 되살리자")
	elif not m.trial_won:
		m.toast("먼저 달빛 시련을 마치자")
	else:
		m.toast("아직 달맞이 관측원으로 오를 수 없다")

var hill_label: Label3D # 달맞이 관측원 over the hill stair

func hill_steps() -> void: # the stair on the hill, a pale lamp over it, and its name floating above
	var g: Node3D = m.lake_zone.stair_frame(m.hill.marks.O, 0.0, 0.0, Color("#ffe6a8"), true)
	hill_label = Label3D.new()
	hill_label.font = m.ui_font
	hill_label.text = "달맞이 관측원"
	hill_label.font_size = 40
	hill_label.pixel_size = 0.012
	hill_label.outline_size = 12
	hill_label.modulate = Color("#fff0d0")
	hill_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hill_label.position = Vector3(0, 2.4, -0.4)
	g.add_child(hill_label)

func enter_observatory() -> void:
	enter_room(0, false)
	if m.observatory_q == 0:
		m.observatory_q = 1
		m.show_story("", Main.STORY.OBS_IN)
	refresh_quest()
	m.save_game()

# arrive in room r beside its stair S, or (back) beside the door N
func enter_room(r: int, back: bool) -> void:
	clear_job()
	var at: Vector2 = m.obs.at(r, "N") + Vector2(-1.0, 0.0) if back else m.obs.at(r, "S") + Vector2(1.0, 0.0)
	m.player.x = at.x
	m.player.z = at.y
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.obs_check = r
	m.ui.mini.map_tex = map()
	m.ui.zone_name.text = "달맞이 관측원"
	m.ui.zone_sub.text = Main.OBS.NAMES[r]
	m.ui.boss.visible = false
	m.snap_mates()
	settle(r)
	refresh_quest()
	if r < 3 and not spawned[r] and m.observatory_q < 2 + r:
		spawned[r] = true
		for f in m.obs.spots[r].get("e", []):
			m.brick_foes.spawn_scalebird(f)
			m.enemies[m.enemies.size() - 1].cave_room = r
			m.burst(Vector3(f.x, 0.5, f.y), Color("#ffe48a"), 10, 1.6)
		refresh_quest() # the birds are up: the line says so

func leave_observatory() -> void:
	clear_job()
	var o: Vector2 = m.hill.marks.O
	m.player.x = o.x
	m.player.z = o.y + 1.3
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
	m.ui.zone_name.text = "바람 언덕"
	m.ui.zone_sub.text = "언덕 꼭대기"
	m.ui.boss.visible = false
	m.snap_mates()
	m.monsters.refill_field("hill")
	m.set_quest(m.main_road_quest())
	m.save_game()

# the minimap of all four rooms, with the stairs marked (gold up at each S, violet down at each door N)
func map() -> ImageTexture:
	var tex: ImageTexture = m.obs.map_tex(Main.OBS.OBS_X + Main.OBS.GAP * 3 + Main.OBS.W)
	var ups: Array = []
	var downs: Array = []
	for r in 4:
		ups.append(m.obs.at(r, "S"))
		if r < 3:
			downs.append(m.obs.at(r, "N"))
	return m.with_stair_marks(m.with_up_marks(tex, ups), downs)

func refresh_map() -> void:
	if in_observatory():
		m.ui.mini.map_tex = map()

# load: the saved room's stair, beside the friends
func restore_at(r: int) -> void:
	clear_fight()
	enter_room(r, false)
	refresh_quest()

# ---- saved state
func save_data() -> Dictionary:
	return {"observatory_q": m.observatory_q, "observatory_section_state": m.obs_sec, "observatory_core_bits": m.obs_bits,
		"observatory_reward_claimed": m.obs_reward, "observatory_checkpoint": m.obs_check, "observatory_boss_told": m.obs_told,
		"observatory_top_tested": m.obs_top_tested, "observatory_ordeal_started": m.obs_ordeal, "observatory_relay_bits": m.obs_relay}

# old saves: no key means q0, except a save already past the castle's door (castle_q >= 1), which is past the observatory too
func load_data(d: Dictionary) -> void:
	m.observatory_q = clampi(int(d.get("observatory_q", 6 if int(d.get("castle_q", 0)) >= 1 else 0)), 0, 6)
	m.obs_sec = fresh_sections()
	var saved = d.get("observatory_section_state", null)
	if saved is Array:
		for r in mini(saved.size(), 4):
			if saved[r] is Dictionary:
				mend_section(r, saved[r])
	m.obs_bits = clampi(int(d.get("observatory_core_bits", 0)), 0, 7)
	if m.obs_bits != 0 and m.obs_bits != 1 and m.obs_bits != 3 and m.obs_bits != 7:
		m.obs_bits = 0 # only the west-to-east orders 001, 011, 111 exist
	m.obs_relay = clampi(int(d.get("observatory_relay_bits", 0)), 0, 7)
	if m.obs_relay != 0 and m.obs_relay != 1 and m.obs_relay != 3 and m.obs_relay != 7:
		m.obs_relay = 0
	m.obs_reward = bool(d.get("observatory_reward_claimed", false))
	m.obs_check = clampi(int(d.get("observatory_checkpoint", 0)), 0, 3)
	m.obs_told = bool(d.get("observatory_boss_told", false))
	m.obs_top_tested = bool(d.get("observatory_top_tested", false))
	m.obs_ordeal = bool(d.get("observatory_ordeal_started", false))
	trans = {}
	group_active = -1
	post_room = -1
	relay_told = m.obs_relay > 0
	repair()
	apply_state()

# one saved room dictionary: only its own keys, each of its own kind; a value outside the legal ones goes back to the start
func mend_section(r: int, saved: Dictionary) -> void:
	var s: Dictionary = m.obs_sec[r]
	for k in s:
		if not saved.has(k):
			continue
		var v = saved[k]
		if k == "angle":
			s[k] = int(v) if ((v is int or v is float) and int(v) in [0, 1]) else 0
		elif k == "mirror_dir":
			s[k] = int(v) if ((v is int or v is float) and int(v) in [0, 1, 2, 3]) else 2
		elif k == "dirs":
			if v is Array and v.size() == 3:
				for i in 3:
					s[k][i] = int(v[i]) if ((v[i] is int or v[i] is float) and int(v[i]) in [0, 1, 2, 3]) else 2
		elif s[k] is bool:
			s[k] = bool(v) if v is bool else false

# a value outside the legal states goes back to the start (the design: out-of-range device values are fixed on load)
func repair() -> void:
	var q: int = m.observatory_q
	for r in 3:
		var s: Dictionary = sec(r)
		if q >= 2 + r: # the section is over: its signal stays fixed, the platform bridges, the mirror stays true
			s.fixed = true
			s.angle = 1
			s.mirror_dir = 0
			s.wind = true
			if r == 1:
				s.lamp_lit = true
			if r == 2:
				s.gust_seen = true
		elif s.fixed:
			s.fixed = false
	if q >= 2:
		sec(0).record_read = true # the work past a note was done, so it was read
	if q >= 5:
		m.obs_top_tested = true # an old save past the moth, or past the test signal, has nothing left to mend (v0.1.120)
	if q < 4:
		m.obs_bits = 0
		m.obs_top_tested = false
		m.obs_ordeal = false
		m.obs_relay = 0
		sec(3).dirs = [2, 2, 2]
	else:
		if m.obs_top_tested:
			m.obs_ordeal = true
			m.obs_bits = 7
			m.obs_relay = 7
		if m.obs_ordeal:
			m.obs_bits = 7 # the break comes after the three fights
		if m.obs_bits > 0 or m.obs_ordeal or m.obs_top_tested or sec(3).wind:
			sec(3).record_read = true
			sec(3).wind = true
		if not m.obs_ordeal:
			m.obs_relay = 0
		var d3: Array = sec(3).dirs
		for i in 3:
			var set_i: bool = (m.obs_relay & (1 << i)) != 0 if (m.obs_ordeal and not m.obs_top_tested) else ((m.obs_bits & (1 << i)) != 0 or m.obs_top_tested)
			d3[i] = Main.OBS.ANS_TOP[i] if set_i else 2
	if q >= 5:
		m.obs_reward = true # the scale is dropped with the moth, in the same save as q5
		m.obs_bits = 7
		sec(3).record_read = true
		sec(3).wind = true
	if q >= 6:
		sec(3).sent = true

func apply_state() -> void:
	var c = m.obs
	for r in 3:
		var s: Dictionary = sec(r)
		c.set_gate(r, m.observatory_q >= 2 + r)
		c.set_plat(r, int(s.angle))
		c.set_wind(r, bool(s.wind))
		c.set_mirror(r, 0, int(s.mirror_dir), bool(s.fixed))
		c.set_plate(r, bool(s.get("record_read", false)))
		refresh_light(r)
	c.set_lamp(bool(sec(1).lamp_lit))
	c.set_plate(3, bool(sec(3).record_read))
	c.set_wind(3, bool(sec(3).wind))
	for l in c.stand_lamps:
		l.emission_energy_multiplier = 2.6 if bool(sec(3).sent) else 0.15
	if c.stand_jar != null:
		c.stand_jar.emission_energy_multiplier = 2.4 if bool(sec(3).sent) else 0.3
	c.set_shortcut(m.observatory_q >= 6)
	dark = m.obs_ordeal and not m.obs_top_tested and m.observatory_q == 4
	for i in 3:
		c.set_mirror(3, i, int(sec(3).dirs[i]), top_set(i))
	refresh_light(3)

# a top mirror is set: its fight is under way or won, or in the relay it was joined again, or the test signal is up
func top_set(i: int) -> bool:
	if m.obs_top_tested or m.observatory_q >= 5:
		return true
	if m.obs_ordeal:
		return (m.obs_relay & (1 << i)) != 0
	return (m.obs_bits & (1 << i)) != 0 or group_active == i

# the runs of light and the receiver of room r
func refresh_light(r: int) -> void:
	var c = m.obs
	if r < 3:
		var s: Dictionary = sec(r)
		var src_on: bool = r != 1 or bool(s.lamp_lit)
		var reach: bool = src_on and int(s.mirror_dir) == 0
		c.set_run(r, 0, src_on)
		c.set_run(r, 1, reach)
		if r == 1:
			c.set_run(1, 2, bool(s.lamp_lit))
		c.set_q(r, 2 if bool(s.fixed) else (1 if reach else 0))
		return
	var s3: Dictionary = sec(3)
	var src3: bool = bool(s3.wind) and (not dark or post_room == 3)
	c.set_run(3, 0, src3)
	for i in 3:
		c.set_run(3, i + 1, src3 and top_set(i))
	var all_set: bool = top_set(0) and top_set(1) and top_set(2)
	c.set_q(3, 2 if (m.obs_top_tested and not dark) else (1 if (all_set and src3) else 0))
	if c.room_lights.size() > 3:
		c.room_lights[3].light_energy = 0.5 if dark else 1.4

# ---- the quest line and the gold "!"
func bits_count() -> int:
	var n := 0
	for i in 3:
		if (m.obs_bits & (1 << i)) != 0:
			n += 1
	return n

func relay_count() -> int:
	var n := 0
	for i in 3:
		if (m.obs_relay & (1 << i)) != 0:
			n += 1
	return n

func quest_line() -> String:
	var q: int = m.observatory_q
	if q >= 6:
		if in_observatory() and room() == 3:
			return "입구 계단이 언덕으로 이어졌다. 계단으로 돌아가자"
		return m.moon_tokens.hill_line()
	if q == 5:
		if not sec(3).sent: return "물과 바람이 닿은 응답등을 보자 (E)"
		if lights_t >= 0.0 and lights_t < 1.8: return "응답등이 켜지는 중이다"
		return "응답등이 켜졌다. 응답대에서 E로 응답을 확인하자"
	var r := work_room()
	var s: Dictionary = sec(r)
	if r < 3:
		if r == 0 and not s.record_read: return "노을과 안전쇠의 쪽지를 읽자"
		if not s.wind: return "풍차를 감아 바람구멍을 깨우자 (E)"
		if r == 1:
			if foes_alive(1): return "빛을 가리는 벽돌을 치우자"
			if not s.lamp_lit: return "등을 켜고 끊긴 빛을 잇자 (E)"
		if r == 2:
			if not s.gust_seen: return "꼭대기로 갈 신호를 맞추자 (E)"
			if post_room != 2: return "노을에게 흔들리는 손을 맡기자 (E)"
			return "수신등에 신호를 올리자 (E)"
		if int(s.angle) == 0 or post_room != r: return "발판을 돌리고 노을에게 맡기자 (E)"
		return "반사경 빛을 수신등에 잇자 (E)"
	if not s.record_read: return "꼭대기의 쪽지를 읽자"
	if not s.wind: return "풍차를 감아 신호 바람을 일으키자 (E)"
	if m.obs_top_tested: return "노을과 벽돌 달나방의 신호를 풀자"
	if m.obs_ordeal:
		if post_room != 3: return "노을에게 손을 맡기자 (E)"
		if m.obs_relay < 7: return tr("서쪽부터 반사경을 다시 맞추자 (E) %d/3") % relay_count()
		return "수신등에 신호를 다시 올리자 (E)"
	if m.obs_bits < 7:
		if foes_alive(3): return "빛을 가리는 박쥐를 치우자"
		return tr("세 반사경을 신호 홈에 맞추자 (E) %d/3") % bits_count()
	return "노을과 시험 신호를 올리자 (E)"

func refresh_quest() -> void:
	if in_observatory():
		m.set_quest(quest_line())

# a room as a save, a faint or a new visit leaves it: no turn or hand is under way, and in the ordeal Noeul waits at his post
func settle(r: int) -> void:
	busy_t = 0.0
	rekindling = false
	lights_t = lights_t if m.observatory_q == 5 else -1.0
	if r == 3 and m.obs_ordeal and not m.obs_top_tested and m.mate2 != null:
		var p: Vector2 = m.obs.at(3, "P") # Noeul waits at his post for the hand to be asked of him again
		m.mate2.position = Vector3(p.x, 0.0, p.y)
		m.mate2_job = {"kind": "obs_post", "to": p, "t": 0.0}
		post_room = -1
	apply_state()

func foes_alive(r: int) -> bool:
	for e in m.enemies:
		if e.dead:
			continue
		if r < 3 and e.get("scalebird", false) and e.get("cave_room", -1) == r:
			return true
		if r == 3 and e.get("obs_prep", false):
			return true
	return false

func nearest_foe() -> Vector2:
	var me := Vector2(m.player.x, m.player.z)
	var best := Vector2.INF
	for e in m.enemies:
		if not e.dead and (e.get("scalebird", false) or e.get("obs_prep", false)):
			var p := Vector2(e.x, e.z)
			if best == Vector2.INF or me.distance_to(p) < me.distance_to(best):
				best = p
	return best

# where the line leads next; the first unfinished condition only, the living foes in a fight, the doors when the work is in another room
func next_spot() -> Vector3:
	if m.intro or m.story_open or m.in_house >= 0:
		return Vector3.INF
	var c = m.obs
	var r := room()
	var me := Vector2(m.player.x, m.player.z)
	var q: int = m.observatory_q
	var at := Vector2.INF
	var moth = moth_alive()
	if moth != null:
		if moth.assist > 0.0:
			at = c.at(3, "Q")
		else:
			return Vector3.INF # in the boss fight the arena is the mark
	elif q >= 6:
		at = c.at(r, "S")
	else:
		var wr := work_room()
		if r != wr:
			at = c.at(r, "N") if r < wr else c.at(r, "S")
		else:
			at = step_spot(r, me)
	if at == Vector2.INF:
		return Vector3.INF
	return m.quest_marks.over(at, 2.2)

func step_spot(r: int, me: Vector2) -> Vector2:
	var c = m.obs
	var s: Dictionary = sec(r)
	var q: int = m.observatory_q
	if r < 3 and q >= 2 + r:
		return c.at(r, "N")
	match r:
		0:
			if not s.record_read: return c.at(0, "H")
			if not s.wind: return c.at(0, "M")
			if int(s.angle) == 0: return c.at(0, "T") if me.x > c.origin(0) + 10.5 else c.at(0, "O")
			if post_room != 0: return c.at(0, "P")
			if int(s.mirror_dir) != 0: return c.at(0, "R")
			return c.at(0, "Q")
		1:
			if not s.wind: return c.at(1, "M")
			var foe := nearest_foe() if foes_alive(1) else Vector2.INF
			if foe != Vector2.INF:
				return foe if me.x > c.origin(1) + 10.5 else c.at(1, "O")
			if not s.lamp_lit: return c.at(1, "L", 1) if me.x > c.origin(1) + 10.5 else c.at(1, "O")
			if int(s.angle) == 0: return c.at(1, "T")
			if post_room != 1: return c.at(1, "P")
			if int(s.mirror_dir) != 0: return c.at(1, "R")
			return c.at(1, "Q")
		2:
			if not s.wind: return c.at(2, "M")
			if int(s.angle) == 0: return c.at(2, "T") if me.x > c.origin(2) + 10.5 else c.at(2, "O")
			if int(s.mirror_dir) != 0: return c.at(2, "R")
			if not s.gust_seen: return c.at(2, "Q")
			if post_room != 2: return c.at(2, "P")
			return c.at(2, "Q")
	# the top room
	if not s.record_read: return c.at(3, "H")
	if not s.wind: return c.at(3, "M")
	if m.obs_top_tested: return c.at(3, "B")
	if m.obs_ordeal:
		if post_room != 3: return c.at(3, "P")
		if m.obs_relay < 7: return c.at(3, "R", relay_count())
		return c.at(3, "Q")
	if m.obs_bits < 7:
		var foe3 := nearest_foe()
		if foe3 != Vector2.INF:
			return foe3
		return c.at(3, "R", bits_count())
	return c.at(3, "Q")

# ---- E
func observatory_key() -> bool:
	if m.story_open or busy_t > 0.0:
		return false
	var c = m.obs
	var r := room()
	var me := Vector2(m.player.x, m.player.z)
	var best := ""
	var best_i := 0
	var best_d := NEAR
	for letter in ["H", "M", "T", "P", "R", "Q", "L", "C"]:
		var list: Array = c.spots[r].get(letter, [])
		for i in list.size():
			if letter == "L" and not (r == 1 and i == 1): # only the second floor's power lantern is a device
				continue
			var d := me.distance_to(list[i])
			if d < best_d:
				best_d = d
				best = letter
				best_i = i
	if best == "":
		return false
	match best:
		"H": key_h(r)
		"M": key_m(r)
		"T": key_t(r)
		"P": key_p(r)
		"R": key_r(r, best_i)
		"Q": key_q(r)
		"L": key_l()
		"C": key_c(r)
	return true

func note_needed(r: int) -> bool:
	if (r == 0 or r == 3) and not bool(sec(r).record_read):
		m.toast("먼저 한결의 쪽지를 읽자 (H)")
		return true
	return false

func key_h(r: int) -> void:
	var s: Dictionary = sec(r)
	if s.record_read:
		m.toast("안전쇠에는 한결의 쪽지가 감겨 있다" if r == 0 else "쪽지 뒷장에는 거울 셋의 순서가 적혀 있다")
		return
	s.record_read = true
	m.obs.set_plate(r, true)
	m.sfx(520, 0.2, "triangle", 0.2)
	m.burst(Vector3(m.obs.at(r, "H").x, 0.5, m.obs.at(r, "H").y), Color("#ffd27a"), 14, 1.8)
	m.show_story("", Main.STORY.OBS_RECORD if r == 0 else Main.STORY.OBS_TOP_NOTE)
	refresh_quest()
	m.save_game()

func key_m(r: int) -> void:
	var s: Dictionary = sec(r)
	if s.wind:
		m.toast("풍차는 이미 돌고 있다")
		return
	if note_needed(r):
		return
	s.wind = true
	m.obs.set_wind(r, true)
	m.sfx(330, 0.5, "sine", 0.25, 200)
	var mm: Vector2 = m.obs.at(r, "M")
	m.burst(Vector3(mm.x, 1.6, mm.y), Color("#f2ead8"), 24, 2.6)
	m.toast("풍차가 돌기 시작했다. 바람구멍이 깨어났다" if r < 3 else "풍차가 돌고 신호의 바람이 일었다")
	refresh_light(r)
	refresh_quest()
	m.save_game()

# the platform: E turns it a quarter, 2 s; nobody may stand on it, and from the far bank it cannot be cut off behind Sora
func platform_occupied(r: int) -> bool:
	var c = m.obs
	var pts: Array = [Vector2(m.player.x, m.player.z)]
	if m.mate != null:
		pts.append(Vector2(m.mate.position.x, m.mate.position.z))
	if m.mate2 != null:
		pts.append(Vector2(m.mate2.position.x, m.mate2.position.z))
	for p in pts:
		if c.on_gap(r, p, 0.3):
			return true
	return false

func key_t(r: int) -> void:
	if r > 2:
		return
	if not trans.is_empty():
		m.toast("발판이 도는 중이다")
		return
	var s: Dictionary = sec(r)
	var to: int = 1 - int(s.angle)
	if platform_occupied(r):
		m.toast("발판 위에 누가 서 있어 돌릴 수 없다")
		return
	if to == 0 and m.player.x > m.obs.origin(r) + 10.5:
		m.toast("건너편에서 발판을 끊으면 돌아갈 길이 없다")
		return
	start_turn(r, to)

func start_turn(r: int, to: int) -> void:
	trans = {"room": r, "to": to, "t": 0.0}
	m.obs.plat_goal[r] = to
	if to == 0:
		sec(r).angle = 0
		m.obs.plat_open[r] = false
		m.obs.set_wind(r, bool(sec(r).wind))
	m.sfx(200, 0.4, "triangle", 0.15, 80)
	m.toast("발판이 돌기 시작했다")

func finish_turn() -> void:
	var r: int = trans.room
	var to: int = trans.to
	trans = {}
	sec(r).angle = to
	m.obs.set_plat(r, to, false)
	m.obs.set_wind(r, bool(sec(r).wind))
	m.sfx(160, 0.5, "noise", 0.1, -60)
	m.toast("발판이 길을 이었다" if to == 1 else "발판이 길을 끊었다")
	refresh_quest()
	refresh_light(r)
	m.save_game()

func key_p(r: int) -> void:
	if m.mate2 == null or m.mate_down.noeul > 0.0:
		m.toast("노을이 일어날 때까지 기다리자")
		return
	if moth_alive() != null:
		m.toast("노을이 신호를 지키고 있다")
		return
	if post_room != r and note_needed(r):
		return
	if post_room == r:
		release_post()
		m.toast("노을이 곁으로 돌아왔다")
	else:
		place_post(r)
		m.toast("노을이 흔들리는 손을 받쳤다" if r == 3 and m.obs_ordeal else "노을이 자리를 잡았다")
		if r == 3 and m.obs_ordeal and not m.obs_top_tested and not relay_told:
			relay_told = true
			say_relay(0)
	refresh_light(r)
	refresh_quest()

# the relay's two lines, each in a balloon over the one who says it: line 0 Noeul, line 1 Sora
func say_relay(i: int) -> void:
	var line: String = Main.STORY.OBS_RELAY[i]
	var text: String = line.get_slice("|", 2)
	if i == 0 and m.mate2 != null:
		m.say_bubble(m.mate2, tr(text), 3.0)
	elif i == 1:
		m.say_bubble(m.hero, tr(text), 3.0)

func place_post(r: int) -> void:
	post_room = r
	m.mate2_job = {"kind": "obs_post", "to": m.obs.at(r, "P"), "t": 0.0}
	m.obs.set_post(r, true)

func release_post() -> void:
	if post_room >= 0:
		m.obs.set_post(post_room, false)
	post_room = -1
	if m.mate2_job.get("kind", "") == "obs_post":
		m.mate2_job = {}

func key_l() -> void:
	var s: Dictionary = sec(1)
	if s.lamp_lit:
		m.toast("등이 켜져 있다. 빛이 아래로 이어진다")
		return
	s.lamp_lit = true
	m.obs.set_lamp(true)
	m.sfx(523, 0.2, "triangle", 0.25)
	var lp: Vector2 = m.obs.at(1, "L", 1)
	m.burst(Vector3(lp.x, 1.4, lp.y), Color("#ffd27a"), 18, 2.0)
	m.toast("등이 켜졌다. 끊긴 빛이 이어진다")
	refresh_light(1)
	refresh_quest()
	m.save_game()

func key_r(r: int, i: int) -> void:
	if r == 3:
		key_r_top(i)
		return
	var s: Dictionary = sec(r)
	if s.fixed:
		m.toast("반사경은 이미 고정됐다")
		return
	if note_needed(r):
		return
	s.mirror_dir = (int(s.mirror_dir) + 1) % 4
	m.obs.set_mirror(r, 0, int(s.mirror_dir), false)
	m.sfx(440, 0.1, "triangle", 0.15)
	if int(s.mirror_dir) == 0:
		m.toast("반사경 빛이 수신등으로 향했다")
	refresh_light(r)
	refresh_quest()
	m.save_game()

# the top room's mirrors, west to east: E turns one a quarter; a mirror that is true is set (the fight's group, or in the relay the joined light)
func key_r_top(i: int) -> void:
	var s: Dictionary = sec(3)
	if not s.record_read:
		note_needed(3)
		return
	if not s.wind:
		m.toast("먼저 풍차를 감아 신호 바람을 일으키자 (M)")
		return
	if m.observatory_q >= 5 or m.obs_top_tested:
		m.toast("반사경은 모두 고정되어 있다")
		return
	var relay: bool = m.obs_ordeal
	if relay:
		if post_room != 3:
			m.toast("노을에게 손을 맡기자 (P에서 E)")
			return
		if (m.obs_relay & (1 << i)) != 0:
			m.toast("이 반사경은 이미 이어졌다")
			return
		if relay_count() != i:
			m.toast("서쪽 반사경부터 다시 잇자")
			return
	else:
		if (m.obs_bits & (1 << i)) != 0:
			m.toast("이 반사경은 이미 맞췄다")
			return
		if bits_count() != i:
			m.toast("서쪽 반사경부터 차례로 맞추자")
			return
		if group_active >= 0:
			m.toast("빛을 가리는 박쥐를 먼저 물리치자")
			return
	var ans: int = Main.OBS.ANS_TOP[i]
	var dirs: Array = s.dirs
	if int(dirs[i]) != ans:
		dirs[i] = (int(dirs[i]) + 1) % 4
	if int(dirs[i]) != ans:
		m.obs.set_mirror(3, i, int(dirs[i]), false)
		m.sfx(440, 0.1, "triangle", 0.15)
		return
	m.obs.set_mirror(3, i, ans, true)
	m.sfx(523, 0.2, "triangle", 0.25)
	if relay:
		m.obs_relay |= (1 << i)
		m.toast(tr("반사경 하나가 이어졌다 (%d/3)") % relay_count())
		if i == 0:
			say_relay(1)
		refresh_light(3)
		refresh_quest()
		m.save_game()
	else:
		start_group(i)
		refresh_light(3)

# 박쥐 2 + 궁수 1 around the mirror (the design's "기존 박쥐2+궁수1 한 조")
func start_group(i: int) -> void:
	var f: Vector2 = m.obs.at(3, "R", i)
	group_active = i
	var pts := [Vector2(f.x - 2.5, f.y + 4.0), Vector2(f.x + 2.5, f.y + 4.0), Vector2(f.x, f.y + 7.0)]
	for k in 3:
		if k == 2:
			m.spawn_enemy(pts[k], true)
		else:
			m.spawn_bat(pts[k])
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.cave = true
		e.obs_prep = true
		e.group = i
		m.burst(Vector3(pts[k].x, 0.5, pts[k].y), Color("#d8c4ff"), 14, 2.0)
	m.sfx(120, 0.3, "square", 0.2, -40)
	m.toast("거울 둘레에 벽돌이 일어섰다")
	refresh_quest()

func group_alive() -> bool:
	for e in m.enemies:
		if not e.dead and e.get("obs_prep", false):
			return true
	return false

func finish_group() -> void:
	var i := group_active
	group_active = -1
	m.obs_bits |= (1 << i)
	m.player.gold += 20
	m.gain_xp(40) # the group pays once, when it is over (its bricks give nothing one by one)
	m.sfx(523, 0.2, "triangle", 0.25)
	m.toast(tr("반사경 하나를 맞췄다 (%d/3)") % bits_count())
	m.obs_check = 3
	refresh_light(3)
	refresh_quest()
	m.save_game()

func key_q(r: int) -> void:
	if r == 3:
		key_q_top()
		return
	var s: Dictionary = sec(r)
	if s.fixed:
		m.toast("수신등은 이미 고정됐다")
		return
	if note_needed(r):
		return
	if r == 1:
		if foes_alive(1):
			m.toast("빛을 가리는 벽돌을 먼저 치우자")
			return
		if not s.lamp_lit:
			m.toast("위층 등을 먼저 켜자")
			return
	if int(s.mirror_dir) != 0:
		m.toast("빛이 수신등에 닿지 않는다. 반사경을 돌리자 (E)")
		return
	if r == 2 and not s.gust_seen and post_room != 2:
		s.gust_seen = true # the first gust shakes the hand once and is not told again
		m.shake = 0.25
		m.sfx(150, 0.4, "noise", 0.15, 200)
		m.burst(Vector3(m.player.x, 0.8, m.player.z), Color("#ffffff"), 20, 3.0)
		m.toast("강풍이 불어 신호가 흔들렸다. 노을에게 손을 맡기자 (P에서 E)")
		refresh_quest()
		m.save_game()
		return
	if post_room != r:
		m.toast("노을에게 손을 맡기자 (P에서 E)")
		return
	if r == 2:
		sec(2).gust_seen = true
	fix_q(r)

func fix_q(r: int) -> void:
	var c = m.obs
	var s: Dictionary = sec(r)
	s.fixed = true
	s.angle = 1
	m.observatory_q = maxi(m.observatory_q, 2 + r)
	c.set_gate(r, true)
	c.set_plat(r, 1, false)
	c.set_mirror(r, 0, 0, true)
	release_post()
	m.obs_check = r
	m.sfx(196, 0.5, "triangle", 0.3, -60)
	m.shake = 0.2
	m.burst(Vector3(c.at(r, "D").x, 0.8, c.at(r, "D").y), Color("#d8c4ff"), 26, 3.0)
	m.toast("수신등이 켜졌다. 앞문이 열렸다")
	refresh_light(r)
	refresh_quest()
	refresh_map()
	if r == 2:
		m.show_story("", Main.STORY.OBS_PRACTICE)
	m.save_game()

# the top receiver: before the break, the first signal is Sora's alone; then the hand asked for again, the three mirrors, the signal
func key_q_top() -> void:
	var s: Dictionary = sec(3)
	var moth = moth_alive()
	if moth != null:
		if moth.assist > 0.0:
			begin_hand(moth)
		else:
			m.toast("지금은 신호를 받쳐 줄 때가 아니다")
		return
	var q: int = m.observatory_q
	if q >= 5:
		m.toast("수신등은 이미 켜져 있다")
		return
	if q < 4:
		m.toast("수신등이다. 아직 쓸 수 없다")
		return
	if m.obs_top_tested:
		m.toast("시험 신호가 올라가 있다. 벽돌 달나방을 멈추자")
		return
	if not s.record_read:
		note_needed(3)
		return
	if not s.wind:
		m.toast("먼저 풍차를 감아 신호 바람을 일으키자 (M)")
		return
	if m.obs_bits < 7:
		m.toast("먼저 반사경 셋을 맞추자")
		return
	if not m.obs_ordeal:
		start_break()
		return
	if post_room != 3:
		m.toast("노을에게 손을 맡기자 (P에서 E)")
		return
	if m.obs_relay < 7:
		m.toast("남은 반사경부터 다시 맞추자")
		return
	busy_t = HAND_T # Noeul's hand under hers, then the light
	rekindling = true
	if m.mate2 != null:
		m.say_bubble(m.mate2, tr("내가 받칠게."), 1.4)
	m.sfx(330, 0.6, "sine", 0.2, 120)

# Sora signals alone: the light fails, the bracelets go dark, the mirrors turn back (only their directions are lost; no resource is touched)
func start_break() -> void:
	m.obs_ordeal = true
	m.obs_relay = 0
	relay_told = false
	sec(3).dirs = [2, 2, 2]
	release_post()
	m.sfx(120, 0.8, "sawtooth", 0.2, -200)
	m.shake = 0.3
	m.toast("팔찌의 푸른빛이 꺼졌다")
	for i in 3:
		m.obs.set_mirror(3, i, 2, false)
	apply_state()
	m.show_story("", Main.STORY.OBS_BREAK)
	m.after_story = after_break
	refresh_quest()
	m.save_game()

func after_break() -> void:
	if not in_observatory():
		return
	if m.mate2 != null:
		var p: Vector2 = m.obs.at(3, "P")
		m.mate2_job = {"kind": "obs_post", "to": p, "t": 0.0}
	refresh_light(3)
	refresh_quest()

func complete_rekindle() -> void:
	rekindling = false
	m.obs_top_tested = true
	m.obs_check = 3
	apply_state()
	m.sfx(523, 0.4, "sine", 0.25, 300)
	var q: Vector2 = m.obs.at(3, "Q")
	m.burst(Vector3(q.x, 1.0, q.y), Color("#9fd8ff"), 32, 3.0)
	m.show_story("", Main.STORY.OBS_REKINDLE)
	refresh_quest()
	m.save_game()

func key_c(r: int) -> void:
	if r != 3:
		return
	var s: Dictionary = sec(3)
	var q: int = m.observatory_q
	if q >= 6:
		m.toast("물과 바람이 닿은 응답등이 켜져 있다")
	elif q < 5:
		m.toast("응답대다. 달나방을 멈춘 뒤에 쓰자")
	elif m.corridor_q < 6:
		m.toast("먼저 물길 회랑의 응답등을 켜자")
	elif not s.sent:
		s.sent = true
		lights_t = 0.0
		lamps_told = false
		m.sfx(392, 0.4, "sine", 0.22, 200)
		m.show_story("", Main.STORY.OBS_DONE)
		m.toast("신호가 아래로 간다. 응답등이 켜지면 E로 응답을 확인하자")
		refresh_quest()
		m.save_game()
	elif lights_t >= 0.0 and lights_t < 1.8:
		m.toast("응답등이 켜지기를 기다리자")
	else:
		m.observatory_q = 6
		m.obs_bits = 7
		m.obs_check = 3
		m.obs.set_shortcut(true)
		m.toast("응답을 확인했다. 입구 계단이 언덕으로 이어졌다")
		refresh_quest() # the line now says the entrance stair leads to the hill
		m.save_game()

# ---- Noeul's job, the platform, the bracelet light
func clear_job() -> void:
	if not trans.is_empty():
		var r: int = trans.room # a turn in progress is finished at once, so no load keeps a half-turned platform
		var to: int = trans.to
		sec(r).angle = to
		m.obs.set_plat(r, to, true)
		trans = {}
	busy_t = 0.0
	rekindling = false
	release_post()

# Noeul at work (mates.update_mate2 sends him here): to his post and stays
func update_mate2_job(dt: float) -> void:
	if m.mate2 == null:
		m.mate2_job = {}
		return
	var job: Dictionary = m.mate2_job
	var at := Vector2(m.mate2.position.x, m.mate2.position.z)
	var to: Vector2 = job.to
	var d := to - at
	var spr: Sprite3D = m.mate2.get_child(0)
	if d.length() > 0.05:
		at += d.normalized() * minf(d.length(), dt * POST_SPEED)
		spr.flip_h = m.screen_left(d)
		spr.frame = 1
	else:
		spr.frame = 0
	m.mate2.position = Vector3(at.x, 0.0, at.y)

# every frame in the observatory
func update(dt: float) -> void:
	var c = m.obs
	c.tick(dt)
	s_toast_t -= dt
	quest_t -= dt
	if quest_t <= 0.0:
		quest_t = 0.5
		if m.quest_raw != quest_line() and not m.story_open:
			refresh_quest()
	var r := room()
	var me := Vector2(m.player.x, m.player.z)
	# the bracelet's blue light follows Sora's wrist; dark after the break until the test signal is up
	c.bracelet.visible = not dark and not m.intro
	c.bracelet.position = Vector3(m.player.x + 0.25, m.ground_y + 0.5, m.player.z + 0.05)
	# the gust ended: friends land beside her
	var gusting: bool = m.gust_dir != Vector2.ZERO
	if gust_prev and not gusting:
		m.snap_mates()
		refresh_quest()
	gust_prev = gusting
	# the platform turning
	if not trans.is_empty():
		trans.t += dt
		if trans.t >= TURN:
			finish_turn()
	# the hand held before a signal
	if busy_t > 0.0 and not m.story_open:
		busy_t -= dt
		if busy_t <= 0.0:
			busy_t = 0.0
			if rekindling:
				complete_rekindle()
	# the answer lamps
	if lights_t >= 0.0:
		lights_t += dt
		if lights_t >= 1.8 and not lamps_told and m.observatory_q == 5:
			lamps_told = true
			m.toast("응답등이 켜졌다. 응답대에서 E로 응답을 확인하자")
			refresh_quest()
		for k in c.stand_lamps.size():
			c.stand_lamps[k].emission_energy_multiplier = 2.6 if lights_t >= 0.5 + k * 0.5 else 0.15
		if c.stand_jar != null:
			c.stand_jar.emission_energy_multiplier = 2.4
		if lights_t > 3.0:
			lights_t = 3.0
	# the top room's fights
	if r == 3 and group_active >= 0 and not group_alive():
		finish_group()
	if r == 3 and m.observatory_q == 4 and m.obs_top_tested and not boss_made and moth_alive() == null and not m.story_open and not m.intro:
		var b: Vector2 = c.at(3, "B")
		if me.distance_to(b) < 9.0 and m.fade_rect.color.a == 0.0:
			boss_made = true
			if not m.obs_told:
				m.obs_told = true
				m.show_story("", Main.STORY.OBS_BOSS)
				m.after_story = spawn_moth
			else:
				spawn_moth()
	# stairs and doors, by walking onto them
	if m.fade_rect.color.a > 0.0 or m.gust_dir != Vector2.ZERO or m.story_open:
		return
	var s: Vector2 = c.at(r, "S")
	if me.distance_to(s) < 0.7:
		if r == 3 and moth_alive() != null:
			if s_toast_t <= 0.0:
				s_toast_t = 3.0
				m.toast("달나방이 길을 막고 있다. 쓰러뜨려야 계단이 열린다")
			return
		if r == 0 or (r == 3 and done()):
			m.fade_then(leave_observatory)
		else:
			m.fade_then(enter_room.bind(r - 1, true))
		return
	if r < 3 and me.distance_to(c.at(r, "N")) < 0.7:
		m.fade_then(enter_room.bind(r + 1, false))

# the wind hole: a gust east while the wind blows and the platform has not bridged the gap
func vent_at(x: float, z: float) -> Vector2:
	var c = m.obs
	var r := c.room_of(x)
	if r < 3 and c.char_at(x, z) == "O" and bool(sec(r).wind) and not c.plat_open[r]:
		return Vector2(1, 0)
	return Vector2.ZERO

# ---- the brick moth (벽돌 달나방): flat box wings, a violet body and a gold scale axis; it flies while it signals and lands to rest
func moth_alive():
	for e in m.enemies:
		if not e.dead and e.get("moth_boss", false):
			return e
	return null

func make_moth() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var violet: Material = m.mat_color(Color("#6a3a9a"))
	var lilac: Material = m.mat_color(Color("#b89ae0"))
	var deep: Material = m.mat_color(Color("#3a2060"))
	var gold: Material = m.mat_color(Color("#d8a830"))
	var torso: MeshInstance3D = m.box(Vector3(0.9, 1.5, 0.8), violet)
	torso.position = Vector3(0, 1.1, 0)
	body.add_child(torso)
	var head: MeshInstance3D = m.box(Vector3(0.7, 0.5, 0.6), deep)
	head.position = Vector3(0, 2.1, 0.1)
	body.add_child(head)
	for sx in [-0.14, 0.14]: # feelers
		var fe: MeshInstance3D = m.box(Vector3(0.05, 0.5, 0.05), gold)
		fe.position = Vector3(sx * 2.0, 2.55, 0.1)
		fe.rotation.z = -sx * 1.5
		body.add_child(fe)
	var wings: Array = []
	for k in 4: # two big wings on top, two small below, each a flat box hinged at the body
		var side := -1.0 if k % 2 == 0 else 1.0
		var big := k < 2
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.45, 1.5 if big else 0.8, -0.1)
		var wing: MeshInstance3D = m.box(Vector3(2.2 if big else 1.5, 0.08, 1.3 if big else 0.9), lilac)
		wing.position = Vector3(side * (1.1 if big else 0.75), 0, 0)
		pivot.add_child(wing)
		for j in 3: # brick seams across the wing
			var seam: MeshInstance3D = m.box(Vector3(0.06, 0.1, 1.3 if big else 0.9), deep)
			seam.position = Vector3(side * (0.5 + j * 0.55) * (1.0 if big else 0.7), 0, 0)
			pivot.add_child(seam)
		body.add_child(pivot)
		wings.append(pivot)
	var axis_mat: StandardMaterial3D = m.glow_mat(Color("#ffd24a"), 0.4)
	var axis: MeshInstance3D = m.box(Vector3(0.14, 1.6, 0.14), axis_mat)
	axis.position = Vector3(0, 1.1, -0.5)
	body.add_child(axis)
	for k in 6: # the scale's marks up the axis
		var tick: MeshInstance3D = m.box(Vector3(0.3, 0.05, 0.05), axis_mat)
		tick.position = Vector3(0, 0.45 + k * 0.25, -0.5)
		body.add_child(tick)
	var front_mark: MeshInstance3D = m.box(Vector3(0.14, 1.0, 0.05), axis_mat) # the same gold on its front, so the open axis shows from any side
	front_mark.position = Vector3(0, 1.1, 0.42)
	body.add_child(front_mark)
	var eye_mat: Material = m.glow_mat(Color("#ff8a3a"), 2.0)
	for sx in [-0.2, 0.2]:
		var eye: MeshInstance3D = m.box(Vector3(0.14, 0.12, 0.06), eye_mat)
		eye.position = Vector3(sx, 2.15, 0.42)
		body.add_child(eye)
	root.set_meta("body", body)
	root.set_meta("wings", wings)
	root.set_meta("axis", axis_mat)
	return root

func spawn_moth() -> void:
	if moth_alive() != null or m.observatory_q != 4:
		return
	var at: Vector2 = m.obs.at(3, "B")
	var node := make_moth()
	var e: Dictionary = m.brick_foes.base_entry(node, at, MOTH_HP, 1.6, {"moth_boss": true, "st": "idle", "st_t": 1.5, "pats": 0,
		"expo": 0.0, "assist": 0.0, "hand_t": 0.0, "told_axis": false, "tele_nodes": [], "dir": Vector2(-1, 0), "ph2": false, "home": at, "fight": true})
	e.atk_cd = 0.0
	node.position = Vector3(at.x, 0, at.y)
	if m.mate2 != null and post_room != 3:
		place_post(3) # Noeul keeps the signal at his post
	m.sfx(70, 0.5, "square", 0.3, -30)
	m.shake = 0.3
	m.burst(Vector3(at.x, 0.6, at.y), Color("#d8c4ff"), 30, 3.5)
	m.obs_check = 3

# the moth: a fan of three lines, then (below 60%) a cross over its spot, then it lands and the axis lies open (full damage); aloft it takes half
func update_moth(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var wings: Array = node.get_meta("wings")
	var axis: StandardMaterial3D = node.get_meta("axis")
	m.ui.boss.visible = d < 16.0 or e.hp < e.max_hp
	m.ui.boss_name.text = "벽돌 달나방"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.hurt -= dt
	if e.hand_t > 0.0 and not m.story_open:
		e.hand_t -= dt # Noeul's hand: the moth's clock stands still while it lasts
		if e.hand_t <= 0.0:
			help_moth(e)
	elif not (m.story_open or m.intro):
		e.expo = maxf(0.0, e.expo - dt)
		var was: float = e.assist
		e.assist = maxf(0.0, e.assist - dt)
		if was > 0.0 and e.assist <= 0.0:
			m.toast("신호를 받칠 틈이 닫혔다")
		e.st_t -= dt
		match e.st:
			"idle":
				if e.st_t <= 0.0 and d < 24.0:
					begin_fan(e, to, d)
			"warn":
				if e.st_t <= 0.0:
					fire_fan(e)
			"fire":
				if e.st_t <= 0.0:
					if e.ph2:
						begin_cross(e)
					else:
						land(e, 3.0)
			"cross":
				if e.st_t <= 0.0:
					slam(e)
			"slam":
				if e.st_t <= 0.0:
					land(e, 4.0)
			"land":
				if e.st_t <= 0.0:
					e.pats += 1
					e.st = "idle"
					e.st_t = 0.5
					if e.pats % 2 == 0: # after every second pattern the signal shows for 6 s
						e.assist = 6.0
						if m.mate2 != null:
							m.say_bubble(m.mate2, tr("지금, 신호!"), 2.4)
						m.toast("노을이 외친다. 수신등에서 E로 신호를 받치자")
	# looks: it hangs in the air while it signals, the wings beat; it settles and the axis glows while it rests
	var aloft: bool = e.st in ["warn", "fire", "cross", "slam"]
	var body: Node3D = node.get_meta("body")
	body.position.y = lerpf(body.position.y, 1.3 if aloft else 0.0, minf(1.0, dt * 6.0))
	var beat := sin(m.t * (14.0 if aloft else 3.0)) * (0.5 if aloft else 0.12)
	for k in wings.size():
		wings[k].rotation.z = beat * (1.0 if k % 2 == 1 else -1.0)
	axis.emission_energy_multiplier = 2.6 if e.expo > 0.0 else 0.4
	body.scale = Vector3.ONE * (1.04 if e.hurt > 0.0 else 1.0)
	node.rotation.y = lerp_angle(node.rotation.y, atan2(e.dir.x, e.dir.y), minf(1.0, dt * 4.0))
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func begin_fan(e: Dictionary, to: Vector2, d: float) -> void:
	e.dir = to / maxf(d, 0.01) # the three lines are fixed when the warning starts
	e.ph2 = e.hp <= MOTH_HP * 0.6
	e.st = "warn"
	e.st_t = 1.3
	var nodes: Array = []
	for a in [-FAN_SPREAD, 0.0, FAN_SPREAD]:
		nodes.append(lane_warn(Vector2(e.x, e.z), e.dir.rotated(a), FAN_REACH, 1.0, 1.3))
	e.tele_nodes = nodes
	m.pop_num(Vector3(e.x, 3.6, e.z), "!", Color("#ff5a4a"))
	m.sfx(140, 0.5, "sawtooth", 0.2, 120)

func fire_fan(e: Dictionary) -> void:
	clear_tele(e)
	e.st = "fire"
	e.st_t = 0.3
	var from := Vector2(e.x, e.z)
	for a in [-FAN_SPREAD, 0.0, FAN_SPREAD]:
		m.monsters.throw_brick(from, e.dir.rotated(a), e, 5.0, FAN_REACH / 5.0 + 0.2, FAN_DMG + m.boss_extra())
	m.shake = 0.15

func begin_cross(e: Dictionary) -> void:
	var home: Vector2 = e.home
	e.st = "cross"
	e.st_t = 1.5
	e.tele_nodes = [lane_warn(home + Vector2(-CROSS_X, 0), Vector2(1, 0), CROSS_X * 2.0, 2.0, 1.5),
		lane_warn(home + Vector2(0, -CROSS_Z), Vector2(0, 1), CROSS_Z * 2.0, 2.0, 1.5)]
	m.sfx(140, 0.5, "sawtooth", 0.2, 120)

func slam(e: Dictionary) -> void:
	clear_tele(e)
	e.st = "slam"
	e.st_t = 0.4
	var home: Vector2 = e.home
	m.shake = 0.35
	m.sfx(70, 0.3, "square", 0.3, -40)
	for k in 7:
		m.burst(Vector3(home.x - CROSS_X + k * 4.3, 0.4, home.y), Color("#c9a0ff"), 6, 2.5)
	for k in 5:
		m.burst(Vector3(home.x, 0.4, home.y - CROSS_Z + k * 4.7), Color("#c9a0ff"), 6, 2.5)
	var p := Vector2(m.player.x - home.x, m.player.z - home.y)
	if (absf(p.y) <= 1.0 and absf(p.x) <= CROSS_X) or (absf(p.x) <= 1.0 and absf(p.y) <= CROSS_Z):
		m.player_hit(SLAM_DMG + m.boss_extra(), home, e)

func land(e: Dictionary, secs: float) -> void:
	e.st = "land"
	e.st_t = secs
	e.expo = maxf(e.expo, secs)
	m.pop_num(Vector3(e.x, 3.2, e.z), "축! 피해 2배", Color("#ffd24a"))
	if not e.told_axis:
		e.told_axis = true
		m.toast("내려앉아 축이 빛날 때 피해 2배")

# a lane drawn as plain colour over the floor with a bright border, so the edge of the blow reads at 800 px
func solid(mat: StandardMaterial3D, c: Color) -> void:
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	mat.emission_enabled = false
	mat.albedo_color = Color(c.r, c.g, c.b, mat.albedo_color.a)

func lane_warn(from: Vector2, dir: Vector2, length: float, width: float, life: float) -> MeshInstance3D:
	var mm: MeshInstance3D = m.monsters.warn_path(from, dir, length, width, life)
	var lane_mat: StandardMaterial3D = mm.get_meta("mat")
	solid(lane_mat, Color("#e83a2a"))
	var edge: StandardMaterial3D = m.glow_mat(Color("#ffd23a"), 1.0)
	solid(edge, Color("#ffd23a"))
	for sx in [-1.0, 1.0]:
		var b: MeshInstance3D = m.box(Vector3(0.1, 0.07, length), edge)
		b.position = Vector3(sx * width / 2.0, 0.02, 0.0)
		mm.add_child(b)
	for sz in [-1.0, 1.0]:
		var b2: MeshInstance3D = m.box(Vector3(width + 0.1, 0.07, 0.1), edge)
		b2.position = Vector3(0.0, 0.02, sz * length / 2.0)
		mm.add_child(b2)
	return mm

func clear_tele(e: Dictionary) -> void:
	for n in e.tele_nodes:
		if is_instance_valid(n):
			n.visible = false
	e.tele_nodes = []

# Sora presses the receiver in the window: Noeul's hand 0.8 s, then the light reaches the axis
func begin_hand(e: Dictionary) -> void:
	e.hand_t = HAND_T
	e.assist = 0.0
	if m.mate2 != null:
		m.say_bubble(m.mate2, tr("내가 받칠게."), 1.4)
	m.toast("노을이 손을 받쳤다")
	m.sfx(330, 0.6, "sine", 0.2, 120)

# the hand is done: the warning and the blow in the air are gone, the moth lands and the axis lies open 5 s longer
func help_moth(e: Dictionary) -> void:
	clear_tele(e)
	e.expo = maxf(e.expo, 0.0) + 5.0
	e.st = "land"
	e.st_t = e.expo
	var q: Vector2 = m.obs.at(3, "Q")
	m.burst(Vector3(q.x, 1.0, q.y), Color("#9fd8ff"), 30, 3.0)
	m.burst(Vector3(e.x, 1.4, e.z), Color("#ffd24a"), 24, 3.0)
	m.sfx(523, 0.4, "sine", 0.25, 300)
	m.toast("축에 빛이 닿았다. 달나방이 내려앉고 축이 5초 더 드러난다")
	if not e.told_axis:
		e.told_axis = true

# the moth falls: the scale and two potions, q5, all in one save
func boss_beaten() -> void:
	if m.obs_reward:
		return
	m.obs_reward = true
	m.observatory_q = maxi(m.observatory_q, 5)
	m.ui.boss.visible = false
	m.player.gold += 300
	m.gain_xp(360)
	m.player.pots += 2
	release_post()
	boss_made = false
	m.shake = 0.5
	m.sfx(330, 0.5, "sine", 0.25, 200)
	m.burst(Vector3(m.obs.at(3, "B").x, 1.0, m.obs.at(3, "B").y), Color("#d8c4ff"), 40, 4.0)
	m.toast("달나방이 쓰러졌다. 달맞이 눈금판과 회복약 2개를 얻었다")
	m.obs_check = 3
	apply_state()
	refresh_quest()
	m.save_game()

# the top room's fight starts over: the group's bricks and the moth go, the mirrors already set stay
func clear_fight() -> void:
	group_active = -1
	for e in m.enemies:
		if not e.dead and (e.get("obs_prep", false) or e.get("moth_boss", false)):
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
	boss_made = false

# Sora faints in the observatory: she wakes at the current room's stair, healed; the moth and the fight's bricks start over,
# what was done stays (the design: death returns to S+(1,0) of the room, devices and the bits are kept)
func on_faint() -> void:
	clear_job()
	var r := room()
	clear_fight()
	m.mate2_job = {}
	m.ui.boss.visible = false
	var s: Vector2 = m.obs.at(r, "S")
	m.player.hp = float(m.player.max_hp)
	m.player.x = s.x + 1.0
	m.player.z = s.y
	m.player.inv = 2.0
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.snap_mates()
	settle(r)
	m.ui.banner_title.text = "쓰러졌다"
	m.ui.banner_sub.text = "관측원 계단 곁에서 다시 눈을 떴다 · 금화와 레벨은 그대로"
	m.ui.banner.modulate.a = 1.0
	m.banner_t = 2.5
	m.sfx(330, 0.25, "triangle", 0.25, -150)
	refresh_quest()

func journal() -> String:
	var q: int = m.observatory_q
	if q >= 6:
		return tr("끝")
	if q == 0: # the one missing condition for the stair
		if m.hill_q < 3:
			return tr("언덕 동쪽의 계단으로") + " · " + tr("먼저 벽돌 매를 물리치자")
		if m.mill_q < 5:
			return tr("언덕 동쪽의 계단으로") + " · " + tr("먼저 참새 방앗간을 되살리자")
		if not m.trial_won:
			return tr("언덕 동쪽의 계단으로") + " · " + tr("먼저 달빛 시련을 마치자")
		return tr("언덕 동쪽의 계단으로") + " · " + tr("언덕 동쪽 끝 계단으로 오르자")
	var step: String = [tr("언덕 동쪽의 계단으로"), tr("바람 길과 안전쇠"), tr("꺼진 빛"), tr("떨리는 손"), tr("꼭대기의 신호"), tr("응답대로")][clampi(q, 0, 5)]
	return step + " · " + tr(quest_line()) # the step and what to do now
