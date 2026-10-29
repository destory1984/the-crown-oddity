# Water corridor (v0.1.84; the owner chose "1안: 물길·관측원" on 2026-10-29, the design is shots/plans/option1_design.md): four rooms
# under the lake island, entered from the stair V after the pearl and the lower pond, required before the forest.
# Mulgyeol keeps a sluice alone, then Sora keeps it and he rides the cart; the last room has three wheels, a brick sluice-keeper
# and the answer stand. Maps and props are in corridor.gd (m.corridor); state is on the main node (corridor_q, corr_*).
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const NEAR := 1.6          # E reaches the nearest device within this
const WARN := 1.0          # the lever pulses 1 s, then the level moves for 1 s
const MOVE := 1.0
const RIDE_SPEED := 2.0    # the cart, tiles a second
const MATE_SPEED := 3.0    # Mulgyeol on the great cart: the whole crossing is under 8 s
const MATE_RUN := 6.0      # and the run to the post first
const POST_SPEED := 4.0
const GATE_HP := 2000
const GATE_REACH := 8.0
const GATE_SWAT := 30      # the two arms, base damage
const GATE_WAVE := 22

var trans := {}            # the level moving: {"room", "to", "t", "done"}
var ride := {}             # Sora on the cart: {"from", "to", "t", "dur"}
var arrived := false       # the third room's cart stands at R
var spawned := [false, false, false, false]
var post_room := -1        # Mulgyeol stands on this room's post
var group_active := -1     # the last room: which wheel's fight is on
var boss_made := false
var lights_t := -1.0       # the answer lamps coming on
var s_toast_t := 0.0

func _init(main: Main) -> void:
	m = main

func in_corridor() -> bool:
	return m.in_lake and m.player.x >= Main.CORR.CORR_X - 0.5

func room() -> int:
	return m.corridor.room_of(m.player.x)

func sec(r: int) -> Dictionary:
	return m.corr_sec[r]

func fresh_sections() -> Array:
	return [{"record_read": false, "water_high": false, "latch_fixed": false},
		{"water_high": false, "drained": false, "latch_fixed": false},
		{"water_high": false, "docked": false, "latch_fixed": false},
		{"record_read": false, "water_high": false, "latch_fixed": false, "sent": false}]

func done() -> bool:
	return m.corridor_q >= 6

# the section a quest step belongs to: q1 the first room, q2 the second, q3 the third, q4 and on the last
func work_room() -> int:
	return clampi(m.corridor_q - 1, 0, 3)

# ---- the way in (lake stair V): the pearl, the lower pond's water clock
func can_enter() -> bool:
	return m.lake_q >= 4 and m.tokens[m.moon_tokens.PEARL] and m.south_q >= 4

func gate_note() -> void:
	if m.toast_t > 0.0:
		return
	if not m.tokens[m.moon_tokens.PEARL]:
		m.toast("먼저 물빛 동굴의 진주를 얻자")
	elif m.south_q < 4:
		m.toast("먼저 아랫못의 물시계를 되살리자")
	else:
		m.toast("아직 물길 회랑으로 내려갈 수 없다")

func lake_steps() -> void: # the stair on the island, a teal lamp over it
	m.lake_zone.stair_frame(m.lake.marks.V, 0.0, 0.0, Color("#a8f0c8"))

func enter_corridor() -> void:
	enter_room(0, false)
	if m.corridor_q == 0:
		m.corridor_q = 1
		m.show_story("", Main.STORY.CORR_IN)
	refresh_quest()
	m.save_game()

# arrive in room r beside its stair S, or (back) beside the door N
func enter_room(r: int, back: bool) -> void:
	clear_job()
	var at: Vector2 = m.corridor.at(r, "N") + Vector2(-1.0, 0.0) if back else m.corridor.at(r, "S") + Vector2(1.0, 0.0)
	m.player.x = at.x
	m.player.z = at.y
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.corr_check = r
	m.ui.mini.map_tex = map()
	m.ui.zone_name.text = "물길 회랑"
	m.ui.zone_sub.text = Main.CORR.NAMES[r]
	m.ui.boss.visible = false
	m.snap_mates()
	refresh_quest()
	if r < 3 and not spawned[r] and m.corridor_q < 2 + r:
		spawned[r] = true
		for f in m.corridor.spots[r].get("e", []):
			m.brick_foes.spawn_bucket(f)
			m.enemies[m.enemies.size() - 1].cave_room = r
			m.burst(Vector3(f.x, 0.5, f.y), Color("#9fd8ff"), 10, 1.6)

func leave_corridor() -> void:
	clear_job()
	var v: Vector2 = m.lake.marks.V
	m.player.x = v.x
	m.player.z = v.y - 1.2
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.lake_zone.lake_map()
	m.ui.zone_name.text = "남쪽 호수"
	m.ui.zone_sub.text = "물결의 섬"
	m.ui.boss.visible = false
	m.snap_mates()
	m.monsters.refill_field("lake")
	m.set_quest(m.moon_tokens.lake_line())
	m.save_game()

# the minimap of all four rooms, with the stairs marked (gold up at each S, violet down at each door N)
func map() -> ImageTexture:
	var tex: ImageTexture = m.corridor.map_tex(Main.CORR.CORR_X + Main.CORR.GAP * 3 + Main.CORR.W)
	var ups: Array = []
	var downs: Array = []
	for r in 4:
		ups.append(m.corridor.at(r, "S"))
		if r < 3:
			downs.append(m.corridor.at(r, "N"))
	return m.with_stair_marks(m.with_up_marks(tex, ups), downs)

func refresh_map() -> void:
	if in_corridor():
		m.ui.mini.map_tex = map()

# load: the saved room's stair, beside the friends
func restore_at(r: int) -> void:
	clear_fight()
	enter_room(r, false)
	refresh_quest()

# ---- saved state
func save_data() -> Dictionary:
	return {"corridor_q": m.corridor_q, "corridor_section_state": m.corr_sec, "corridor_core_bits": m.corr_bits,
		"corridor_reward_claimed": m.corr_reward, "corridor_checkpoint": m.corr_check, "corridor_boss_told": m.corr_told}

# old saves: no key means q0, except a save already past the forest, which is past the corridor too (forest_q >= 1)
func load_data(d: Dictionary) -> void:
	m.corridor_q = clampi(int(d.get("corridor_q", 6 if m.forest_q >= 1 else 0)), 0, 6)
	m.corr_sec = fresh_sections()
	var saved = d.get("corridor_section_state", null)
	if saved is Array:
		for r in mini(saved.size(), 4):
			if saved[r] is Dictionary:
				for k in m.corr_sec[r]:
					m.corr_sec[r][k] = bool(saved[r].get(k, false))
	m.corr_bits = clampi(int(d.get("corridor_core_bits", 0)), 0, 7)
	if m.corr_bits != 0 and m.corr_bits != 1 and m.corr_bits != 3 and m.corr_bits != 7:
		m.corr_bits = 0 # only the west-to-east orders 001, 011, 111 exist
	m.corr_reward = bool(d.get("corridor_reward_claimed", false))
	m.corr_check = clampi(int(d.get("corridor_checkpoint", 0)), 0, 3)
	m.corr_told = bool(d.get("corridor_boss_told", false))
	if m.corridor_q >= 5:
		m.corr_reward = true # the knot is dropped with the keeper, in the same save as q5
		m.corr_bits = 7
	if m.corridor_q >= 6:
		m.corr_bits = 7
		m.corr_sec[3].sent = true
	repair()
	apply_state()

# a value outside the legal states goes back to the start (the design: out-of-range device values are fixed on load)
func repair() -> void:
	var q: int = m.corridor_q
	for r in 3:
		var s: Dictionary = sec(r)
		if q >= 2 + r: # the section is over: its latch stays fixed, the water rests low
			s.latch_fixed = true
			s.water_high = false
		elif s.latch_fixed:
			s.latch_fixed = false
	if q < 4:
		m.corr_bits = 0
		sec(3).latch_fixed = false
		sec(3).water_high = false
	if q < 2:
		sec(1).drained = false
	if q < 3:
		sec(2).docked = false
	if q >= 4:
		sec(2).docked = true
	if q >= 5:
		sec(3).water_high = true
		sec(3).latch_fixed = true

func apply_state() -> void:
	var c = m.corridor
	for r in 3:
		var s: Dictionary = sec(r)
		c.set_water(r, bool(s.water_high))
		c.set_gate(r, m.corridor_q >= 2 + r)
		c.set_wheel(r, 0, bool(s.latch_fixed) or (r == 1 and bool(s.drained)))
		c.set_plate(r, bool(s.get("record_read", false)))
	c.set_plate(3, bool(sec(3).record_read))
	c.set_lever(3, bool(sec(3).water_high))
	for i in 3:
		c.set_wheel(3, i, (m.corr_bits & (1 << i)) != 0)
	for l in c.stand_lamps:
		l.emission_energy_multiplier = 2.6 if bool(sec(3).sent) else 0.15
	if c.stand_jar != null:
		c.stand_jar.emission_energy_multiplier = 2.4 if bool(sec(3).sent) else 0.3

# ---- the quest line and the gold "!"
func quest_line() -> String:
	var q: int = m.corridor_q
	if q >= 6:
		return m.moon_tokens.lake_line()
	if q == 5:
		return "회랑 끝 응답등을 확인하자 (E)"
	var r := work_room()
	var s: Dictionary = sec(r)
	match r:
		0:
			if not s.record_read: return "물결과 한결의 잠금판을 읽자"
			if post_room != 0: return "물결에게 수문을 맡기자 (E)"
			return "물을 높이고 걸쇠를 풀자 (E)"
		1:
			if foes_alive(1) or (not s.drained and not s.water_high): return "물 건너 벽돌을 치우자"
			if not s.drained: return "반대편 물레에서 물을 빼자 (E)"
			return "입구 손잡이로 물길을 고정하자 (E)"
		2:
			if not s.docked and (post_room != 2 or not m.corridor.high[2]) and not arrived: return "물결과 운반대를 띄우자 (E)"
			if not s.docked: return "운반대를 건너편에 묶자 (E)"
			return "둘이 물레를 잇자 (E)"
	if not s.record_read: return "물레 방의 잠금판을 읽자"
	if not s.water_high or not s.latch_fixed: return "내가 수문을 잡고 물결을 보내자 (E)"
	if m.corr_bits < 7: return "물결의 신호에 물레 셋을 잇자 (E)"
	return "물결과 벽돌 수문지기를 멈추자"

func refresh_quest() -> void:
	if in_corridor():
		m.set_quest(quest_line())

func bits_count() -> int:
	var n := 0
	for i in 3:
		if (m.corr_bits & (1 << i)) != 0:
			n += 1
	return n

func foes_alive(r: int) -> bool:
	for e in m.enemies:
		if not e.dead and e.get("bucket", false) and e.get("cave_room", -1) == r:
			return true
	return false

func nearest_foe() -> Vector2:
	var me := Vector2(m.player.x, m.player.z)
	var best := Vector2.INF
	for e in m.enemies:
		if not e.dead and (e.get("bucket", false) or e.get("corr_prep", false)):
			var p := Vector2(e.x, e.z)
			if best == Vector2.INF or me.distance_to(p) < me.distance_to(best):
				best = p
	return best

# where the line leads next; the first unfinished condition only (A before F, T before R), the living foes in a fight, the
# doors when the work is in another room
func next_spot() -> Vector3:
	if m.intro or m.story_open or m.in_house >= 0:
		return Vector3.INF
	var c = m.corridor
	var r := room()
	var me := Vector2(m.player.x, m.player.z)
	var q: int = m.corridor_q
	var at := Vector2.INF
	var boss_alive := gate_alive() != null
	if boss_alive:
		var gk = gate_alive()
		if gk.assist > 0.0:
			at = c.at(3, "A")
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
	var c = m.corridor
	var s: Dictionary = sec(r)
	var q: int = m.corridor_q
	var d_open: bool = q >= 2 + r and r < 3
	if d_open:
		return c.at(r, "N")
	match r:
		0:
			if not s.record_read: return c.at(0, "H")
			if post_room != 0: return c.at(0, "P")
			if not c.high[0]: return c.at(0, "A")
			return c.at(0, "F")
		1:
			var foe := nearest_foe() if foes_alive(1) else Vector2.INF
			if s.drained:
				return c.at(1, "A")
			if foe != Vector2.INF:
				if not c.high[1] and me.x < c.origin(1) + 8.0:
					return c.at(1, "A")
				return foe
			return c.at(1, "F") if c.high[1] else c.at(1, "A")
		2:
			if s.docked: return c.at(2, "F")
			if arrived: return c.at(2, "R")
			if post_room != 2: return c.at(2, "P")
			if not c.high[2]: return c.at(2, "A")
			return c.at(2, "T")
	# the last room
	if q >= 5:
		return c.at(3, "C")
	if not s.record_read: return c.at(3, "H")
	if not s.water_high: return c.at(3, "A")
	if not s.latch_fixed: return c.at(3, "P")
	if m.corr_bits < 7:
		var foe := nearest_foe()
		if foe != Vector2.INF:
			return foe
		return c.at(3, "F", bits_count())
	return c.at(3, "B")

# ---- E
func corridor_key() -> bool:
	if m.story_open or not ride.is_empty():
		return false
	var c = m.corridor
	var r := room()
	var me := Vector2(m.player.x, m.player.z)
	var best := ""
	var best_i := 0
	var best_d := NEAR
	for letter in ["H", "A", "P", "T", "R", "F", "C"]:
		var list: Array = c.spots[r].get(letter, [])
		for i in list.size():
			var d := me.distance_to(list[i])
			if d < best_d:
				best_d = d
				best = letter
				best_i = i
	if best == "":
		return false
	match best:
		"H": key_h(r)
		"A": key_a(r)
		"P": key_p(r)
		"T": key_t(r)
		"R": key_r(r)
		"F": key_f(r, best_i)
		"C": key_c(r)
	return true

func key_h(r: int) -> void:
	var s: Dictionary = sec(r)
	if s.record_read:
		m.toast("잠금판에는 손바닥 자국이 겹쳐 있다" if r == 0 else "잠금판에 손바닥 둘이 올릴 자리가 새겨져 있다")
		return
	s.record_read = true
	m.corridor.set_plate(r, true)
	m.sfx(520, 0.2, "triangle", 0.2)
	m.burst(Vector3(m.corridor.at(r, "H").x, 0.5, m.corridor.at(r, "H").y), Color("#ffd27a"), 14, 1.8)
	if r == 0:
		m.show_story("", Main.STORY.CORR_PLATE)
	else:
		m.toast("잠금판에 손바닥 둘이 올릴 자리가 새겨져 있다")
	refresh_quest()
	m.save_game()

func key_a(r: int) -> void:
	var c = m.corridor
	var me := Vector2(m.player.x, m.player.z)
	if r == 3:
		var gk = gate_alive()
		if gk != null:
			if gk.assist > 0.0:
				gk.assist = 0.0
				gk.expo += 5.0
				if m.mate != null:
					m.say_bubble(m.mate, tr("물이 옆으로 간다!"), 1.8)
				m.toast("옆문으로 물을 뺐다. 수문지기의 축이 5초 더 드러난다")
				m.sfx(330, 0.3, "sine", 0.22, 160)
				m.burst(Vector3(c.at(3, "A").x, 0.6, c.at(3, "A").y), Color("#9fd4ff"), 20, 2.5)
			else:
				m.toast("지금은 수문을 열 때가 아니다")
			return
		var s3: Dictionary = sec(3)
		if s3.water_high:
			m.toast("수문은 소라가 잡고 있다")
			return
		s3.water_high = true
		c.set_lever(3, true)
		m.sfx(330, 0.3, "sine", 0.22, 160)
		m.toast("수문을 소라가 잡았다. 물결을 보내자 (P에서 E)")
		refresh_quest()
		m.save_game()
		return
	var s: Dictionary = sec(r)
	if r == 1 and s.drained and not s.latch_fixed:
		s.latch_fixed = true
		m.corridor_q = maxi(m.corridor_q, 3)
		c.set_gate(1, true)
		c.set_wheel(1, 0, true)
		m.sfx(196, 0.5, "triangle", 0.3, -60)
		m.toast("물길을 고정했다. 문이 열렸다")
		m.corr_check = 1
		refresh_quest()
		refresh_map()
		m.save_game()
		return
	if not trans.is_empty():
		m.toast("수위가 바뀌는 중이다")
		return
	if c.in_channel(r, me, 0.8):
		m.toast("수로 위에서는 수위를 바꿀 수 없다")
		return
	start_water(r, not c.high[r])

func start_water(r: int, to_high: bool) -> void:
	trans = {"room": r, "to": to_high, "t": 0.0, "done": false}
	var o: int = m.corridor.origin(r)
	var fx := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.0, 0.04, 20.0)
	fx.mesh = bm
	var mat: StandardMaterial3D = m.glow_mat(Color("#7fd0ff"), 1.6)
	fx.material_override = mat
	fx.position = Vector3(o + 9.0, 0.03, 10.5)
	m.add_fx(fx, WARN, func(_n: Node3D, k: float, _dt: float): mat.albedo_color.a = 0.25 + 0.5 * absf(sin(k * PI * 3.0)))
	m.sfx(200, 0.4, "triangle", 0.15, 80)

func key_p(r: int) -> void:
	if m.mate == null or m.mate_down.mulgyeol > 0.0:
		m.toast("물결이 일어날 때까지 기다리자")
		return
	if r < 3:
		if post_room == r:
			release_post()
			m.toast("물결이 수문에서 돌아왔다")
		else:
			place_post(r)
			m.toast("물결이 수문을 잡았다")
		refresh_quest()
		return
	var s: Dictionary = sec(3)
	if gate_alive() != null:
		m.toast("물결이 옆문을 지키고 있다")
	elif not s.water_high:
		m.toast("먼저 입구 손잡이로 수문을 잡자 (A)")
	elif s.latch_fixed or m.mate_job.get("kind", "") == "corr_cart":
		m.toast("물결은 이미 물레 건너편으로 갔다")
	else:
		var p: Vector2 = m.corridor.at(3, "P")
		var t: Vector2 = m.corridor.at(3, "T")
		var rr: Vector2 = m.corridor.at(3, "R")
		m.mate_job = {"kind": "corr_cart", "route": [p, t, rr], "i": 0, "t": 0.0}
		post_room = -1
		m.toast("물결이 수조의 운반대로 건너간다")
		refresh_quest()

func place_post(r: int) -> void:
	post_room = r
	m.mate_job = {"kind": "corr_post", "to": m.corridor.at(r, "P"), "t": 0.0}
	m.corridor.set_post(r, true)

func release_post() -> void:
	if post_room >= 0:
		m.corridor.set_post(post_room, false)
	post_room = -1
	if m.mate_job.get("kind", "") in ["corr_post", "corr_cart"]:
		m.mate_job = {}
	if m.mate != null:
		m.mate.position.y = 0.0

func key_t(r: int) -> void:
	if r != 2:
		return
	var s: Dictionary = sec(2)
	if s.docked or arrived:
		m.toast("운반대는 건너편에 묶여 있다")
	elif post_room != 2:
		m.toast("물결에게 수문을 맡기자 (P에서 E)")
	elif not m.corridor.high[2]:
		m.toast("물이 낮아 운반대가 움직이지 않는다. 입구 손잡이로 물을 높이자 (A)")
	else:
		var t: Vector2 = m.corridor.at(2, "T")
		var rr: Vector2 = m.corridor.at(2, "R")
		ride = {"from": t, "to": rr, "t": 0.0, "dur": t.distance_to(rr) / RIDE_SPEED}
		m.player.x = t.x
		m.player.z = t.y
		m.toast("운반대에 올랐다")
		m.sfx(160, 0.5, "square", 0.12, 40)

func key_r(r: int) -> void:
	if r != 2:
		m.toast("물결이 서는 정박점이다")
		return
	var s: Dictionary = sec(2)
	if s.docked:
		m.toast("줄은 이미 묶여 있다")
	elif arrived:
		s.docked = true
		release_post()
		m.sfx(392, 0.2, "triangle", 0.22)
		m.toast("줄을 묶었다. 물결이 곁으로 돌아온다")
		m.snap_mate()
		refresh_quest()
		m.save_game()
	else:
		m.toast("운반대를 타고 건너오자 (T에서 E)")

func key_f(r: int, i: int) -> void:
	var c = m.corridor
	var s: Dictionary = sec(r)
	if r == 0:
		if s.latch_fixed:
			m.toast("걸쇠는 이미 풀렸다")
		elif post_room != 0:
			m.toast("물결에게 수문을 맡기자 (P에서 E)")
		elif not c.high[0]:
			m.toast("물이 낮아 걸쇠가 꿈쩍 않는다. 입구 손잡이로 물을 높이자 (A)")
		else:
			s.latch_fixed = true
			m.corridor_q = maxi(m.corridor_q, 2)
			finish_latch(0)
	elif r == 1:
		if s.drained:
			m.toast("물은 이미 뺐다. 입구 손잡이로 물길을 고정하자 (A)")
		elif foes_alive(1):
			m.toast("건너편의 벽돌 물받이를 먼저 치우자")
		elif not c.high[1]:
			m.toast("물이 낮다. 입구 손잡이로 물을 높이자 (A)")
		else:
			s.drained = true
			c.set_wheel(1, 0, true)
			start_water(1, false)
			m.sfx(160, 0.5, "noise", 0.12, -60)
			m.toast("물이 빠진다. 입구 손잡이로 돌아가 물길을 고정하자 (A)")
			refresh_quest()
			m.save_game()
	elif r == 2:
		if s.latch_fixed:
			m.toast("물레는 이미 이어졌다")
		elif not s.docked:
			m.toast("먼저 운반대를 건너편에 묶자")
		else:
			s.latch_fixed = true
			m.corridor_q = maxi(m.corridor_q, 4)
			finish_latch(2)
			m.show_story("", Main.STORY.CORR_SHARE)
	else:
		key_wheel(i)

# a room's latch is fixed: the gate opens, the water settles low so both banks stay open, a checkpoint
func finish_latch(r: int) -> void:
	var c = m.corridor
	c.set_gate(r, true)
	c.set_wheel(r, 0, true)
	release_post()
	if c.high[r]:
		start_water(r, false)
	m.corr_check = r
	m.sfx(196, 0.5, "triangle", 0.3, -60)
	m.shake = 0.2
	m.burst(Vector3(c.at(r, "D").x, 0.8, c.at(r, "D").y), Color("#9fd4ff"), 26, 3.0)
	m.toast("걸쇠가 풀렸다. 앞문이 열렸다")
	refresh_quest()
	refresh_map()
	m.save_game()

func key_wheel(i: int) -> void:
	var s: Dictionary = sec(3)
	if m.corridor_q >= 5:
		m.toast("물레는 모두 이어져 있다")
	elif not s.water_high:
		m.toast("먼저 입구 손잡이로 수문을 잡자 (A)")
	elif not s.latch_fixed:
		m.toast("물결이 건너편에 닿은 뒤에 이을 수 있다")
	elif (m.corr_bits & (1 << i)) != 0:
		m.toast("이미 이어진 물레다")
	elif bits_count() != i:
		m.toast("서쪽 물레부터 차례로 잇자")
	elif group_active >= 0:
		m.toast("물레 둘레의 벽돌을 먼저 물리치자")
	else:
		start_group(i)

# 고블린 2 + 궁수 1 around the wheel (the design's "기존 고블린2+궁수1 한 조")
func start_group(i: int) -> void:
	var f: Vector2 = m.corridor.at(3, "F", i)
	group_active = i
	var spots := [Vector2(f.x - 3.0, f.y + 3.5), Vector2(f.x + 3.0, f.y + 3.5), Vector2(f.x, f.y + 5.5)]
	for k in 3:
		m.spawn_enemy(spots[k], k == 2)
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.cave = true
		e.corr_prep = true
		e.group = i
		m.burst(Vector3(spots[k].x, 0.5, spots[k].y), Color("#9fd8ff"), 14, 2.0)
	m.sfx(120, 0.3, "square", 0.2, -40)
	m.toast("물레 둘레에 벽돌이 일어섰다")
	refresh_quest()

func group_alive() -> bool:
	for e in m.enemies:
		if not e.dead and e.get("corr_prep", false):
			return true
	return false

func finish_group() -> void:
	var i := group_active
	group_active = -1
	m.corr_bits |= (1 << i)
	m.corridor.set_wheel(3, i, true)
	m.player.gold += 20
	m.gain_xp(40) # the group pays once, when it is over (its bricks give nothing one by one)
	m.sfx(523, 0.2, "triangle", 0.25)
	m.toast(tr("물레 하나가 이어졌다 (%d/3)") % bits_count())
	m.corr_check = 3
	refresh_quest()
	m.save_game()

func key_c(r: int) -> void:
	if r != 3:
		return
	var s: Dictionary = sec(3)
	var q: int = m.corridor_q
	if q >= 6:
		m.toast("정원 쪽 응답등이 켜져 있다. 물이 흐르고 있다")
	elif q < 5:
		m.toast("응답대다. 수문지기를 멈춘 뒤에 쓰자")
	elif not s.sent:
		s.sent = true
		lights_t = 0.0
		m.sfx(392, 0.4, "sine", 0.22, 200)
		m.toast("물이 정원으로 흘러간다")
		m.save_game()
	elif lights_t >= 0.0 and lights_t < 1.8:
		m.toast("응답등이 켜지기를 기다리자")
	else:
		m.corridor_q = 6
		m.corr_bits = 7
		m.corr_check = 3
		m.show_story("", Main.STORY.CORR_DONE)
		m.set_quest(m.moon_tokens.lake_line())
		m.save_game()

# ---- the cart, Mulgyeol's jobs, the level
func clear_job() -> void:
	trans = {}
	ride = {}
	release_post()
	if m.mate_job.get("kind", "") in ["corr_post", "corr_cart"]:
		m.mate_job = {}

# Mulgyeol on a job (mates.update_mate sends him here): to his post and stays, or across the great tank on the cart
func update_mate_job(dt: float) -> void:
	if m.mate == null:
		m.mate_job = {}
		return
	var job: Dictionary = m.mate_job
	var at := Vector2(m.mate.position.x, m.mate.position.z)
	var spr: Sprite3D = m.mate.get_child(0)
	if job.kind == "corr_post":
		var to: Vector2 = job.to
		var d := to - at
		if d.length() > 0.05:
			at += d.normalized() * minf(d.length(), dt * POST_SPEED)
			spr.flip_h = not m.screen_left(d)
		m.mate.position = Vector3(at.x, 0.0, at.y)
		return
	var route: Array = job.route
	var k: int = job.i
	if k >= route.size():
		m.mate_job = {}
		arrive_mate()
		return
	var tgt: Vector2 = route[k]
	var dv := tgt - at
	var wet: bool = m.corridor.char_at(at.x, at.y) == "=" or k >= 2
	if dv.length() > 0.05:
		at += dv.normalized() * minf(dv.length(), dt * (MATE_RUN if k == 0 else MATE_SPEED))
		spr.flip_h = not m.screen_left(dv)
	else:
		job.i = k + 1
	if k >= 2: # from the cart's start on, the cart goes with him
		var cart: Node3D = m.corridor.carts[3]
		if cart != null:
			cart.position.x = at.x
	m.mate.position = Vector3(at.x, -0.2 if wet else 0.0, at.y)
	if job.i >= route.size():
		m.mate_job = {}
		arrive_mate()

func arrive_mate() -> void:
	var s: Dictionary = sec(3)
	s.latch_fixed = true # he stands at the far mooring
	if m.mate != null:
		m.mate.position.y = 0.0
	var rr: Vector2 = m.corridor.at(3, "R")
	if m.mate != null:
		m.mate.position = Vector3(rr.x, 0.0, rr.y)
	m.sfx(392, 0.2, "triangle", 0.22)
	m.toast("물결이 건너편에 닿았다. 물레를 서쪽부터 잇자")
	m.mate_job = {"kind": "corr_post", "to": rr, "t": 0.0}
	post_room = -1
	m.corr_check = 3
	refresh_quest()
	m.save_game()

# every frame in the corridor
func update(dt: float) -> void:
	var c = m.corridor
	c.tick(dt)
	s_toast_t -= dt
	var r := room()
	var me := Vector2(m.player.x, m.player.z)
	# the level moving
	if not trans.is_empty():
		trans.t += dt
		var tr_r: int = trans.room
		if not trans.done and trans.t >= WARN:
			trans.done = true
			if trans.to and c.in_channel(tr_r, Vector2(m.player.x, m.player.z) if tr_r == r else Vector2(-99, -99), 0.55):
				m.toast("소라가 수로에 있어 물이 멈췄다")
				trans = {}
			else:
				c.set_water(tr_r, trans.to)
				sec(tr_r).water_high = trans.to
				m.sfx(130, 0.8, "noise", 0.1, -40)
				refresh_map()
				refresh_quest()
				m.save_game()
		elif trans.done and trans.t >= WARN + MOVE:
			trans = {}
	# Sora on the cart
	if not ride.is_empty():
		ride.t += dt
		var k: float = clampf(ride.t / ride.dur, 0.0, 1.0)
		var p: Vector2 = ride.from.lerp(ride.to, k)
		m.player.x = p.x
		m.player.z = p.y
		m.player.vx = 0.0
		m.player.vz = 0.0
		m.player.atk_cd = maxf(m.player.atk_cd, 0.3) # no blows from the cart
		m.player.dodge = 0.0
		var cart: Node3D = c.carts[2]
		if cart != null:
			cart.position.x = p.x
		if k >= 1.0:
			ride = {}
			arrived = true
			m.toast("운반대가 정박점에 닿았다. 줄을 묶자 (E)")
			refresh_quest()
	# the answer lamps
	if lights_t >= 0.0:
		lights_t += dt
		for k in c.stand_lamps.size():
			c.stand_lamps[k].emission_energy_multiplier = 2.6 if lights_t >= 0.5 + k * 0.5 else 0.15
		if c.stand_jar != null:
			c.stand_jar.emission_energy_multiplier = 2.4
		if lights_t > 3.0:
			lights_t = 3.0
	# the last room's fights
	if r == 3 and group_active >= 0 and not group_alive():
		finish_group()
	if r == 3 and m.corridor_q == 4 and m.corr_bits == 7 and not boss_made and gate_alive() == null and not m.story_open and not m.intro:
		var b: Vector2 = c.at(3, "B")
		if me.distance_to(b) < 9.0 and m.fade_rect.color.a == 0.0:
			boss_made = true
			if not m.corr_told:
				m.corr_told = true
				m.show_story("", Main.STORY.CORR_BOSS)
				m.after_story = spawn_gate
			else:
				spawn_gate()
	# stairs and doors, by walking onto them
	if m.fade_rect.color.a > 0.0 or m.gust_dir != Vector2.ZERO or not ride.is_empty() or m.story_open:
		return
	var s: Vector2 = c.at(r, "S")
	if me.distance_to(s) < 0.7:
		if r == 3 and gate_alive() != null:
			if s_toast_t <= 0.0:
				s_toast_t = 3.0
				m.toast("수문지기가 길을 막고 있다. 쓰러뜨려야 계단이 열린다")
			return
		if r == 0 or (r == 3 and done()):
			m.fade_then(leave_corridor)
		else:
			m.fade_then(enter_room.bind(r - 1, true))
		return
	if r < 3 and me.distance_to(c.at(r, "N")) < 0.7:
		m.fade_then(enter_room.bind(r + 1, false))

# ---- the sluice-keeper (벽돌 수문지기): a pillar with two door-leaf arms and a blue axis at its back
func gate_alive():
	for e in m.enemies:
		if not e.dead and e.get("gatekeeper", false):
			return e
	return null

func make_gate() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var stone: Material = m.mat_color(Color("#4a5a74"))
	var cap: Material = m.mat_color(Color("#6a7a94"))
	var leaf: Material = m.mat_color(Color("#7a6a52"))
	var bolt: Material = m.mat_color(Color("#c8962a"))
	var pillar: MeshInstance3D = m.box(Vector3(1.4, 2.6, 1.4), stone)
	pillar.position = Vector3(0, 1.3, 0)
	body.add_child(pillar)
	var top: MeshInstance3D = m.box(Vector3(1.8, 0.4, 1.8), cap)
	top.position = Vector3(0, 2.8, 0)
	body.add_child(top)
	for k in 3: # courses of brick seams
		var seam: MeshInstance3D = m.box(Vector3(1.44, 0.06, 1.44), cap)
		seam.position = Vector3(0, 0.6 + k * 0.8, 0)
		body.add_child(seam)
	var arms: Array = []
	for sx in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(sx * 0.95, 2.2, 0.0)
		var door: MeshInstance3D = m.box(Vector3(0.36, 1.9, 1.3), leaf)
		door.position = Vector3(0, -0.9, 0.5)
		pivot.add_child(door)
		for k in 3:
			var b: MeshInstance3D = m.box(Vector3(0.42, 0.14, 0.14), bolt)
			b.position = Vector3(0, -0.3 - k * 0.6, 1.1)
			pivot.add_child(b)
		body.add_child(pivot)
		arms.append(pivot)
	var axis_mat: StandardMaterial3D = m.glow_mat(Color("#5ab4ff"), 0.4)
	var axis: MeshInstance3D = m.box(Vector3(0.3, 1.8, 0.3), axis_mat)
	axis.position = Vector3(0, 1.6, -0.9)
	body.add_child(axis)
	var eye_mat: Material = m.glow_mat(Color("#ffb040"), 2.0)
	for sx in [-0.3, 0.3]:
		var eye: MeshInstance3D = m.box(Vector3(0.2, 0.14, 0.06), eye_mat)
		eye.position = Vector3(sx, 2.2, 0.72)
		body.add_child(eye)
	root.set_meta("body", body)
	root.set_meta("arms", arms)
	root.set_meta("axis", axis_mat)
	return root

func spawn_gate() -> void:
	if gate_alive() != null or m.corridor_q != 4:
		return
	var at: Vector2 = m.corridor.at(3, "B")
	var node := make_gate()
	var e: Dictionary = m.brick_foes.base_entry(node, at, GATE_HP, 1.5, {"gatekeeper": true, "st": "idle", "st_t": 1.5, "pats": 0,
		"expo": 0.0, "assist": 0.0, "dir": Vector2(-1, 0), "ph2": false, "struck": false, "fight": true})
	e.atk_cd = 0.0
	node.position = Vector3(at.x, 0, at.y)
	place_post(3) # Mulgyeol keeps the sluice at his post
	m.sfx(70, 0.5, "square", 0.3, -30)
	m.shake = 0.3
	m.burst(Vector3(at.x, 0.6, at.y), Color("#9fd8ff"), 30, 3.5)
	m.corr_check = 3

# the keeper: two arms down a lane, then (below 60%) a shock ring, then the axis lies open (full damage); closed it takes half
func update_gate(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var arms: Array = node.get_meta("arms")
	var axis: StandardMaterial3D = node.get_meta("axis")
	m.ui.boss.visible = d < 16.0 or e.hp < e.max_hp
	m.ui.boss_name.text = "벽돌 수문지기"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.hurt -= dt
	if not (m.story_open or m.intro): # a story stops the keeper's clock
		e.expo = maxf(0.0, e.expo - dt)
		var was: float = e.assist
		e.assist = maxf(0.0, e.assist - dt)
		if was > 0.0 and e.assist <= 0.0:
			m.toast("옆문이 닫혔다")
		e.st_t -= dt
		match e.st:
			"idle":
				if e.st_t <= 0.0 and d < 18.0:
					begin_swat(e, to, d)
			"warn":
				if e.st_t <= 0.0:
					swat(e)
			"strike":
				if e.st_t <= 0.0:
					if e.ph2:
						e.st = "ring"
						e.st_t = 1.0
						m.warn_ring(Vector3(e.x, 0.0, e.z), 4.0, 1.0)
						m.sfx(140, 0.5, "sawtooth", 0.2, 120)
					else:
						expose(e, 3.0)
			"ring":
				if e.st_t <= 0.0:
					wave(e)
			"wave":
				if e.st_t <= 0.0:
					expose(e, 4.0)
			"expose":
				if e.st_t <= 0.0:
					e.st = "rest"
					e.st_t = 1.0
			"rest":
				if e.st_t <= 0.0:
					e.pats += 1
					e.st = "idle"
					e.st_t = 0.0
					if e.pats % 2 == 0: # after every second pattern the side door shows for 6 s
						e.assist = 6.0
						if m.mate != null:
							m.say_bubble(m.mate, tr("지금, 옆문!"), 2.4)
						m.toast("물결이 외친다. 입구 손잡이로 옆문을 열자 (E)")
	# looks: the arms raise over the lane and drop on the blow; the axis glows while it lies open
	var raised: bool = e.st == "warn" or e.st == "ring"
	var slam: bool = e.st == "strike" or e.st == "wave"
	for a in arms:
		a.rotation.x = lerpf(a.rotation.x, -1.3 if raised else (0.3 if slam else 0.0), minf(1.0, dt * 12.0))
	axis.emission_energy_multiplier = 2.6 if e.expo > 0.0 else 0.4
	node.get_meta("body").scale = Vector3.ONE * (1.04 if e.hurt > 0.0 else 1.0)
	node.rotation.y = lerp_angle(node.rotation.y, atan2(e.dir.x, e.dir.y), minf(1.0, dt * 4.0))
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func begin_swat(e: Dictionary, to: Vector2, d: float) -> void:
	e.dir = to / maxf(d, 0.01) # the lane is fixed when the warning starts
	e.ph2 = e.hp <= GATE_HP * 0.6
	e.st = "warn"
	e.st_t = 1.2
	e.tele = m.monsters.warn_path(Vector2(e.x, e.z), e.dir, GATE_REACH, 2.0, 1.2)
	m.pop_num(Vector3(e.x, 3.4, e.z), "!", Color("#ff5a4a"))
	m.sfx(140, 0.5, "sawtooth", 0.2, 120)

func swat(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	m.monsters.tele_clear(e)
	e.st = "strike"
	e.st_t = 0.3
	m.shake = 0.3
	m.sfx(70, 0.3, "square", 0.3, -40)
	for k in 4:
		m.burst(Vector3(e.x + e.dir.x * (1.5 + k * 2.0), 0.4, e.z + e.dir.y * (1.5 + k * 2.0)), Color("#c9a066"), 10, 3.0)
	if m.brick_foes.in_lane(from, e.dir, GATE_REACH, 1.0, Vector2(m.player.x, m.player.z)):
		m.player_hit(GATE_SWAT + m.boss_extra(), from, e)

func wave(e: Dictionary) -> void:
	e.st = "wave"
	e.st_t = 0.5
	m.monsters.stomp_wave(Vector3(e.x, 0.0, e.z))
	if Vector2(m.player.x - e.x, m.player.z - e.z).length() < 4.0:
		m.player_hit(GATE_WAVE + m.boss_extra(), Vector2(e.x, e.z), e)

func expose(e: Dictionary, secs: float) -> void:
	e.st = "expose"
	e.st_t = secs
	e.expo = maxf(e.expo, secs)
	m.pop_num(Vector3(e.x, 3.2, e.z), "축!", Color("#7fd0ff"))

# the keeper falls: the knot and two potions, the water for the answer stand, q5, all in one save
func boss_beaten() -> void:
	if m.corr_reward:
		return
	m.corr_reward = true
	m.corridor_q = maxi(m.corridor_q, 5)
	m.ui.boss.visible = false
	m.player.gold += 260
	m.gain_xp(300)
	m.player.pots += 2
	release_post()
	boss_made = false
	m.shake = 0.5
	m.sfx(330, 0.5, "sine", 0.25, 200)
	m.burst(Vector3(m.corridor.at(3, "B").x, 1.0, m.corridor.at(3, "B").y), Color("#9fd8ff"), 40, 4.0)
	m.toast("수문지기가 쓰러졌다. 회랑 물매듭과 회복약 2개를 얻었다")
	m.corr_check = 3
	refresh_quest()
	m.save_game()

# the wheel hall's fight starts over: the group's bricks and the keeper go, the wheels already joined stay
func clear_fight() -> void:
	group_active = -1
	for e in m.enemies:
		if not e.dead and (e.get("corr_prep", false) or e.get("gatekeeper", false)):
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
	boss_made = false

# Sora faints in the corridor: she wakes at the current room's stair, healed; the keeper and the fight's bricks start over,
# what was done stays (the design: death returns to S+(1,0) of the room, devices and the 111 bits are kept)
func on_faint() -> void:
	clear_job()
	var r := room()
	clear_fight()
	ride = {}
	m.mate_job = {}
	m.ui.boss.visible = false
	var s: Vector2 = m.corridor.at(r, "S")
	m.player.hp = float(m.player.max_hp)
	m.player.x = s.x + 1.0
	m.player.z = s.y
	m.player.inv = 2.0
	m.ground_y = 0.0
	m.snap_mates()
	m.ui.banner_title.text = "쓰러졌다"
	m.ui.banner_sub.text = "회랑 계단 곁에서 다시 눈을 떴다 · 금화와 레벨은 그대로"
	m.ui.banner.modulate.a = 1.0
	m.banner_t = 2.5
	m.sfx(330, 0.25, "triangle", 0.25, -150)
	refresh_quest()

func journal() -> String:
	var q: int = m.corridor_q
	if q >= 6:
		return tr("끝")
	return [tr("호수 섬의 계단으로"), tr("잠금판과 첫 수문"), tr("되돌리는 물"), tr("건네는 줄"), tr("물레 셋과 수문지기"), tr("응답대로")][clampi(q, 0, 5)]
