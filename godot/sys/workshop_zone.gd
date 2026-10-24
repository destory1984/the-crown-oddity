# Deep workshop (side story "끝내지 못한 등불"): the door in the castle's great hall, three floors, the cradle finale,
# the lantern for Simji and the village repair bench. Maps are in workshop.gd (one per floor, m.wfloors).
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const WORK_HP := 10       # max HP, given once (a new round keeps work_hp and gives gold instead)
const FRAG_GAP := 1.3     # B3 hall: a fragment is marked every 1.3 s while Sora stands under the cracked ceiling
const FRAG_WARN := 1.0    # the red ring shows 1 s before it lands
const ARM_WARN := 1.0     # the cradle: the floor glows red 1 s before an arm sweeps
const ARM_SWEEP := 0.6
const ARM_REST := 0.8
const ARM_HALF := PI / 3.0 # each arm sweeps 120 degrees around the cradle
const LAMP_WAKE := [[Vector2(2, -1), "g"], [Vector2(3, 0), "a"]] # bricks that wake beside a lit work lamp (x mirrored east)
const CLAMP_AMBUSH := [[Vector2(23, 7), "s"], [Vector2(23, 8), "a"], [Vector2(12, 8), "g"]] # B3, after the first clamp

var frags: Array = []     # [{"at": Vector2, "t": float}]
var frag_t := 0.0
var arm_i := -1
var arm_phase := ""       # "" or "rest", "warn", "sweep"
var arm_t := 0.0
var arm_hit := false
var door_node: Node3D
var door_bricks: Node3D
var door_closed: Node3D
var door_open_look: Node3D
var bench: Node3D

func _init(main: Main) -> void:
	m = main

func fl(i: int):
	return m.wfloors[i]

func in_workshop() -> bool:
	return m.in_hill and m.player.x >= Main.WORK.WORK_X - 0.5

func floor_here() -> int:
	return Main.WORK.floor_of(m.player.x)

# GPT's conditions (chapter 7): the knight beaten, Noeul and Mulgyeol along, the unbricking learned
func door_ready() -> bool:
	return m.story_step >= 10 and m.castle_q >= 3 and m.forest_q >= 3 and m.lake_q >= 4 and m.has_unbrick

# ---- the door in the great hall's north-east corner: bricked until the knight falls, then a cracked maintenance door
# with two hands carved on one handle; open, a dark doorway with steps going down
func build() -> void:
	for f in m.wfloors:
		f.build(m)
	var at: Vector2 = Main.WORK_DOOR
	door_node = Node3D.new()
	door_node.position = Vector3(at.x, 0, at.y - 0.5)
	m.add_child(door_node)
	door_bricks = Node3D.new()
	for row in 4:
		for k in 2:
			var b: MeshInstance3D = m.box(Vector3(0.46, 0.34, 0.2), m.mat_color(Color("#a8322a") if (row + k) % 2 == 0 else Color("#8a8a90")))
			b.position = Vector3(-0.24 + k * 0.48, 0.2 + row * 0.36, 0.05)
			door_bricks.add_child(b)
	door_node.add_child(door_bricks)
	var frame: Material = m.mat_color(Color("#6a6070"))
	for side in [-0.55, 0.55]:
		var post: MeshInstance3D = m.box(Vector3(0.16, 1.7, 0.3), frame)
		post.position = Vector3(side, 0.85, 0.05)
		door_node.add_child(post)
	var lintel: MeshInstance3D = m.box(Vector3(1.26, 0.18, 0.3), frame)
	lintel.position = Vector3(0, 1.75, 0.05)
	door_node.add_child(lintel)
	door_closed = Node3D.new()
	var slab: MeshInstance3D = m.box(Vector3(0.94, 1.6, 0.14), m.mat_color(Color("#7a6a58")))
	slab.position = Vector3(0, 0.8, 0.1)
	door_closed.add_child(slab)
	var crack: MeshInstance3D = m.box(Vector3(0.05, 1.2, 0.02), m.mat_color(Color("#2a2228")))
	crack.position = Vector3(0.2, 0.9, 0.18)
	crack.rotation.z = 0.25
	door_closed.add_child(crack)
	var carve: Material = m.glow_mat(Color("#ffd27a"), 0.8)
	var bar: MeshInstance3D = m.box(Vector3(0.5, 0.06, 0.02), carve) # one handle, two hands on it
	bar.position = Vector3(0, 0.95, 0.19)
	door_closed.add_child(bar)
	for side in [-0.2, 0.2]:
		var hand: MeshInstance3D = m.box(Vector3(0.14, 0.18, 0.02), carve)
		hand.position = Vector3(side, 1.05, 0.19)
		door_closed.add_child(hand)
	door_node.add_child(door_closed)
	door_open_look = Node3D.new()
	var dark: MeshInstance3D = m.box(Vector3(0.94, 1.6, 0.06), m.mat_color(Color("#120e16")))
	dark.position = Vector3(0, 0.8, 0.02)
	door_open_look.add_child(dark)
	for k in 3:
		var st: MeshInstance3D = m.box(Vector3(0.8, 0.05, 0.22), m.mat_color(Color("#b8b4c4").darkened(k * 0.25)))
		st.position = Vector3(0, 0.04 - k * 0.01, 0.6 - k * 0.24)
		door_open_look.add_child(st)
	door_node.add_child(door_open_look)
	door_look()
	build_bench()

func door_look() -> void:
	if door_node == null:
		return
	door_bricks.visible = m.castle_q < 3
	door_closed.visible = m.castle_q >= 3 and not m.work_door
	door_open_look.visible = m.work_door

# the castle minimap marks the door with the violet stair once the knight has uncovered it
func castle_spots() -> Array:
	return [Main.UNDER_STAIR, Main.WORK_DOOR] if m.castle_q >= 3 else [Main.UNDER_STAIR]

func door_key() -> bool:
	if m.work_door or Vector2(m.player.x, m.player.z).distance_to(Main.WORK_DOOR) > 1.5:
		return false
	if m.castle_q < 3:
		m.toast("벽돌로 메운 자리다. 안쪽에서 무언가가 붙들고 있다")
		return true
	if not door_ready():
		m.toast("손 둘이 새겨진 문이다. 혼자 밀어서는 꿈쩍도 않는다")
		return true
	m.work_door = true
	m.work_seen = true
	door_look()
	m.burst(Vector3(Main.WORK_DOOR.x, 1.0, Main.WORK_DOOR.y - 0.3), Color("#ffd27a"), 20, 2.0)
	m.sfx(220, 0.5, "triangle", 0.25, -40)
	m.show_story("", m.cast_lines(Main.STORY.WORK_DOOR_OPEN))
	m.ui.mini.map_tex = m.castle_zone.castle_map()
	m.save_game()
	return true

# in the castle: the door's first look after the knight, then the door as a way down
func update_castle() -> void:
	if m.story_open or m.fade_rect.color.a > 0.0 or m.gust_dir != Vector2.ZERO:
		return
	var d := Vector2(m.player.x, m.player.z).distance_to(Main.WORK_DOOR)
	if m.castle_q >= 3 and not m.work_seen and d < 6.0:
		m.work_seen = true
		m.show_story("", m.cast_lines(Main.STORY.WORK_DOOR_SEEN))
		m.save_game()
		return
	if m.work_door and d < 0.6:
		m.fade_then(enter_floor.bind(0, "A"))

# ---- the floors
func floor_map(i: int) -> ImageTexture:
	var f = fl(i)
	var tex: ImageTexture = f.map_tex(Main.WORK.FLOOR_X[i] + Main.WORK.FLOOR_W[i])
	if f.marks.has("V"):
		tex = m.with_stair_marks(tex, [f.marks.V])
	return m.with_up_marks(tex, [f.marks.S])

func refresh_map() -> void:
	if in_workshop():
		m.ui.mini.map_tex = floor_map(floor_here())

# arrive: "A" from above (the arrival beside the way up), "U" from below (beside the way down), "Y" at the waystone
func enter_floor(i: int, arrive := "A") -> void:
	m.clear_quarters_job()
	m.in_cave = false
	m.in_village = false
	m.in_forest = false
	m.in_lake = false
	m.in_garden = false
	m.in_house = -1
	m.in_hill = true
	frags.clear()
	arm_i = -1
	arm_phase = ""
	arm_t = 0.0
	var f = fl(i)
	var at: Vector2 = f.marks.get(arrive, f.marks.A)
	if arrive == "Y":
		at = f.marks.Y + Vector2(0, 1.2)
	m.player.x = at.x
	m.player.z = at.y
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.boss.visible = false
	m.ui.mini.map_tex = floor_map(i)
	m.ui.zone_name.text = "달지기 작업장"
	m.ui.zone_sub.text = Main.WORK.NAMES[i]
	m.snap_mates()
	var first: bool = m.work_floor < i + 1
	m.work_floor = maxi(m.work_floor, i + 1)
	if i == 0:
		m.work_q = maxi(m.work_q, 1)
	if not m.work_spawned[i]:
		m.work_spawned[i] = true
		for fo in f.foes:
			spawn_foe(fo[0], fo[1], i)
	if first:
		m.show_story("", m.cast_lines([Main.STORY.WORK_B1_IN, Main.STORY.WORK_B2_IN, Main.STORY.WORK_B3_IN][i]))
		m.after_story = goal_toast.bind(i)
	m.save_game()

func spawn_foe(at: Vector2, kind: String, i: int) -> void:
	match kind:
		"b": m.spawn_bat(at)
		"q": m.monsters.spawn_hog(at)
		_:
			m.spawn_enemy(at, kind == "a")
			if kind == "s":
				m.give_shield(m.enemies[m.enemies.size() - 1])
	var e: Dictionary = m.enemies[m.enemies.size() - 1]
	e.cave = true # no respawn
	e.work = i

# side stories keep the quest line on the main road: each floor says its goal in a longer toast
func goal_toast(i: int) -> void:
	m.toast(["작업등 둘을 팔찌로 켜자 (E). 두 빛이 겹치는 곳에 길이 있다", "사슬 기둥 곁에서 E: 물결이 쇠 뚜껑을 당긴다. 그 밑 마개를 팔찌로", "벽의 죔쇠 둘을 팔찌로 풀자 (E). 빨간 동그라미가 뜨면 벽 틈으로"][i])
	m.toast_t = 4.5

func leave_up(i: int) -> void:
	if i > 0:
		enter_floor(i - 1, "U")
		return
	frags.clear()
	m.player.x = Main.WORK_DOOR.x - 1.2
	m.player.z = Main.WORK_DOOR.y + 0.9
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = m.castle_zone.castle_map()
	m.ui.zone_name.text = "가라앉은 달지기 성"
	m.ui.zone_sub.text = "큰 방"
	m.snap_mates()
	m.save_game()

func on_faint() -> void:
	frags.clear()
	arm_i = -1
	arm_phase = ""
	if m.mate_job.get("kind", "") == "work":
		m.mate_job = {}

# every frame on a floor: the stairs, B3's falling fragments and the cradle
func update_work(dt: float) -> void:
	var i := floor_here()
	var f = fl(i)
	var me := Vector2(m.player.x, m.player.z)
	if m.gust_dir == Vector2.ZERO and me.distance_to(f.marks.S) < 0.6:
		m.fade_then(leave_up.bind(i))
		return
	if f.marks.has("V") and m.work_q >= i + 2 and me.distance_to(f.marks.V) < 0.6:
		m.fade_then(enter_floor.bind(i + 1, "A"))
		return
	if i == 2:
		update_frags(dt, f, me)
		update_cradle(dt, f, me)

func update_frags(dt: float, f, me: Vector2) -> void:
	for fr in frags.duplicate():
		fr.t -= dt
		if fr.t <= 0.0:
			frags.erase(fr)
			var at: Vector2 = fr.at
			m.burst(Vector3(at.x, 0.4, at.y), Color("#d8ccb4"), 14, 2.0)
			m.sfx(120, 0.15, "noise", 0.12, -40)
			if Vector2(m.player.x, m.player.z).distance_to(at) < 0.85 and f.char_at(m.player.x, m.player.z) != "n":
				m.player_hit(10 + m.player.lv, at, {})
	if m.story_open or m.work_q >= 5:
		return
	frag_t -= dt
	if frag_t <= 0.0 and f.char_at(me.x, me.y) == "f":
		frag_t = FRAG_GAP
		var spots: Array = [Vector2(round(me.x), round(me.y))]
		for tries in 8: # and one more on the cracked floor nearby
			var p := Vector2(round(me.x + m.rnd(-3, 3)), round(me.y + m.rnd(-1.5, 1.5)))
			if f.char_at(p.x, p.y) == "f" and p.distance_to(spots[0]) > 1.5:
				spots.append(p)
				break
		for p: Vector2 in spots:
			m.warn_ring(Vector3(p.x, 0.0, p.y), 0.8, FRAG_WARN)
			frags.append({"at": p, "t": FRAG_WARN})

func in_sector(p: Vector2, f, k: int) -> bool:
	var d: Vector2 = p - f.marks.O
	if d.length() < 0.5 or d.length() > Main.WORK.ARM_R:
		return false
	return absf(wrapf(atan2(d.y, d.x) - float(f.latches[k].angle), -PI, PI)) <= ARM_HALF

func in_pit(me: Vector2) -> bool:
	return floor_here() == 2 and me.y > 12.6

# the cradle (work_q 4): the arms take turns, each warned 1 s ahead by a red sector on the floor. A hit costs HP only:
# no latch comes undone and nothing costs pips again (GPT: no timing failure, no full reset)
func update_cradle(dt: float, f, me: Vector2) -> void:
	if m.work_q != 4 or not in_pit(me):
		return
	var o: Vector2 = f.marks.O
	if not m.work_cradle_seen:
		if me.distance_to(o) < 7.5 and not m.story_open:
			m.work_cradle_seen = true
			m.show_story("", m.cast_lines(Main.STORY.WORK_CRADLE_IN))
			m.after_story = func():
				m.toast(tr("팔이 지나간 뒤 걸쇠 셋을 팔찌로 감자 (E) %d/3") % f.latches_wound())
				m.toast_t = 4.5
			m.save_game()
		return
	if m.story_open or f.latches_wound() >= 3:
		return
	arm_t -= dt
	match arm_phase:
		"warn":
			if arm_t <= 0.0:
				arm_phase = "sweep"
				arm_t = ARM_SWEEP
				arm_hit = false
				m.sfx(150, 0.35, "sawtooth", 0.15, 120)
		"sweep":
			var k := clampf(1.0 - arm_t / ARM_SWEEP, 0.0, 1.0)
			var a: float = float(f.latches[arm_i].angle) - ARM_HALF + 2.0 * ARM_HALF * k
			(f.arms[arm_i] as Node3D).rotation.y = -a
			if not arm_hit and in_sector(me, f, arm_i):
				arm_hit = true
				m.player_hit(12 + m.player.lv, o, {})
			if arm_t <= 0.0:
				(f.arms[arm_i] as Node3D).rotation.y = -float(f.latches[arm_i].angle)
				arm_phase = "rest"
				arm_t = ARM_REST
		_:
			if arm_t <= 0.0:
				for step in 3:
					var n: int = (arm_i + 1 + step) % 3
					if not f.latches[n].wound:
						arm_i = n
						break
				arm_phase = "warn"
				arm_t = ARM_WARN
				var a0: float = float(f.latches[arm_i].angle) - ARM_HALF
				var mm := MeshInstance3D.new()
				mm.mesh = m.ring_mesh(0.7, Main.WORK.ARM_R, a0, 2.0 * ARM_HALF, 20)
				var mat: StandardMaterial3D = m.glow_mat(Color("#ff4a3a"), 1.6)
				mm.material_override = mat
				mm.position = Vector3(o.x, 0.06, o.y)
				m.add_fx(mm, ARM_WARN, func(_n: Node3D, kk: float, _dt: float): mat.albedo_color.a = 0.2 + 0.4 * absf(sin(kk * PI * 3.0)))

# ---- E on a floor
func work_key() -> bool:
	var i := floor_here()
	var f = fl(i)
	var me := Vector2(m.player.x, m.player.z)
	var note: String = "k" if i == 2 else "t"
	if f.marks.has(note) and me.distance_to(f.marks[note]) < 1.5:
		var first: bool = not m.work_reads[i]
		m.work_reads[i] = true
		m.show_story("", m.cast_lines([Main.STORY.WORK_TAG, Main.STORY.WORK_HANDLE, Main.STORY.WORK_SCRATCH][i]))
		if first:
			m.sfx(523, 0.15, "triangle", 0.18)
			m.save_game()
		return true
	match i:
		0:
			for l in f.lamps:
				if not l.lit and me.distance_to(l.pos) < 1.6:
					if not m.spend_pips(1):
						return true
					f.light(l)
					m.burst(Vector3(l.pos.x, 1.8, l.pos.y), Color("#ffc46a"), 20, 2.0)
					m.sfx(440 + f.lamps_lit() * 120, 0.25, "triangle", 0.22)
					var side := 1.0 if l.pos.x < Main.WORK.FLOOR_X[0] + 14 else -1.0
					for wk in LAMP_WAKE:
						var off: Vector2 = wk[0]
						spawn_foe(l.pos + Vector2(off.x * side, off.y), wk[1], 0)
					if f.lamps_lit() == f.lamps.size():
						f.show_planks()
						m.shake = 0.2
						m.toast("두 빛이 겹친 자리에 널빤지 길이 드러났다")
					else:
						m.toast("작업등 하나. 불빛에 벽돌이 깨어났다. 빛이 반쪽 길만 비춘다")
					refresh_map()
					m.save_game()
					return true
			if unbrick_near(f, me, 0):
				return true
		1:
			if not m.work_pulled and me.distance_to(f.marks.P) < 1.6:
				start_pull(f)
				return true
			for g in f.groups:
				if not g.open and near_group(g, me):
					if not m.work_pulled:
						m.toast("쇠 뚜껑이 마개를 덮고 있다. 사슬 기둥을 당겨야 한다")
						return true
					return unbrick_near(f, me, 1)
		2:
			if unbrick_near(f, me, 2):
				return true
			if m.work_q == 4:
				for k in f.latches.size():
					var l: Dictionary = f.latches[k]
					if not l.wound and me.distance_to(l.pos) < 1.5:
						if arm_i == k and (arm_phase == "warn" or arm_phase == "sweep"):
							m.toast("팔이 움직이는 중이다. 지나간 뒤에 감자")
							return true
						if not m.spend_pips(1):
							return true
						wind(f, k)
						return true
				if f.latches_wound() >= 3 and me.distance_to(f.marks.O) < 1.9:
					release(f)
					return true
	return false

func near_group(g: Dictionary, me: Vector2) -> bool:
	for n in g.nodes:
		if me.distance_to(Vector2(n.position.x, n.position.z)) < 1.8:
			return true
	return false

# B1's plug, B2's stopper, B3's two clamps: the crown unwinds them at the usual unbricking cost
func unbrick_near(f, me: Vector2, i: int) -> bool:
	for g in f.groups:
		if g.open or not near_group(g, me):
			continue
		if not m.spend_pips(m.unbrick_cost()):
			return true
		f.open_group(g)
		var at: Vector2 = g.at
		m.burst(Vector3(at.x, 0.7, at.y), Color("#8a6a4a"), 36, 3.5)
		m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
		m.shake = 0.25
		m.sfx(196, 0.5, "triangle", 0.3, -60)
		match i:
			0:
				floor_cleared(0)
				m.toast("벽돌 마개가 흙으로 풀렸다. 배달 굴 너머로 계단이 보인다")
			1:
				f.drain()
				m.burst(Vector3(at.x + 8.0, 0.3, 12.0), Color("#9fd4ff"), 40, 4.0)
				m.sfx(150, 0.8, "noise", 0.2, -60)
				floor_cleared(1)
				m.toast("물길이 돌아 흐르고 남쪽 물길이 말랐다. 배달 바구니가 바닥에 내려앉았다")
			2:
				if f.groups_open() == 1:
					for am in CLAMP_AMBUSH:
						var off: Vector2 = am[0]
						spawn_foe(Vector2(Main.WORK.FLOOR_X[2] + off.x, off.y), am[1], 2)
					m.toast("죔쇠 하나가 풀렸다. 벽돌들이 몰려온다")
				else:
					f.open_door()
					floor_cleared(2)
					m.toast("죔쇠 둘이 풀리고 아래 문이 열렸다. 달빛 길돌이 깨어났다")
		m.toast_t = 3.5
		refresh_map()
		m.save_game()
		return true
	return false

# a floor's way down opens and its return waystone wakes
func floor_cleared(i: int) -> void:
	m.work_q = maxi(m.work_q, i + 2)
	m.work_ways[i] = true
	fl(i).light_stone()

func start_pull(f) -> void:
	if m.mate == null:
		m.toast("사슬이 무겁다. 혼자서는 꿈쩍도 않는다")
		return
	if not m.mate_job.is_empty():
		return
	var post: Vector2 = f.marks.P
	m.mate_job = {"state": "walk", "kind": "work", "to": post + Vector2(0.9, 0.0), "t": 0.0}
	m.say_bubble(m.mate, tr("내가 당길게. 뚜껑 잘 봐!"), 2.0)

# Mulgyeol walks to the chain post and hauls for 1.2 s (mates.update_mate hands him over while a "work" job runs)
func update_pull(dt: float) -> void:
	var spr: Sprite3D = m.mate.get_child(0)
	var at := Vector2(m.mate.position.x, m.mate.position.z)
	var to: Vector2 = m.mate_job.to
	m.mate_job.t += dt
	if m.mate_job.state == "walk":
		var d := to - at
		if d.length() > 0.05 and m.mate_job.t < 5.0:
			at += d.normalized() * minf(d.length(), dt * 5.0)
			spr.flip_h = not m.screen_left(d)
			m.mate.position = Vector3(at.x, 0, at.y)
		else:
			m.mate.position = Vector3(to.x, 0, to.y)
			m.mate_job.state = "pull"
			m.mate_job.t = 0.0
		return
	m.mate.position.x = to.x + (0.12 if fmod(m.mate_job.t, 0.4) < 0.2 else 0.0)
	m.mate.position.y = sin(m.t * 9.0) * 0.04
	if m.mate_job.t >= 1.2:
		m.mate.position.y = 0.0
		m.mate_job = {}
		var f = fl(1)
		f.open_lid()
		m.work_pulled = true
		m.say_bubble(m.mate, tr("끄응……! 됐다!"), 1.8)
		m.sfx(240, 0.4, "triangle", 0.2, 120)
		m.toast("쇠 뚜껑이 올라가고 벽돌 마개가 드러났다. 팔찌로 풀자 (E)")
		refresh_map()
		m.save_game()

# a latch wound: its arm stops; Noeul braces the first, Mulgyeol holds the chain of the second
func wind(f, k: int) -> void:
	f.wind_latch(k)
	m.work_latch[k] = true
	if arm_i == k:
		arm_phase = "rest"
		arm_t = ARM_REST
	var l: Dictionary = f.latches[k]
	m.burst(Vector3(l.pos.x, 1.1, l.pos.y), Color("#9fd4ff"), 18, 1.8)
	m.sfx(523 + f.latches_wound() * 120, 0.25, "triangle", 0.22)
	match f.latches_wound():
		1:
			if m.mate2 != null:
				m.say_bubble(m.mate2, tr("풀린 팔은 내가 붙들게!"), 2.2)
			m.toast("걸쇠 1/3")
		2:
			if m.mate != null:
				m.say_bubble(m.mate, tr("사슬 잡았어. 놓기 전에 말할게!"), 2.2)
			m.toast("걸쇠 2/3")
		_:
			m.toast("걸쇠 셋이 모두 감겼다. 셋이서 요람을 붙들자 (요람 앞에서 E)")
			m.toast_t = 4.0
			steady_mates(f)
	m.save_game()

# all three at the cradle: the companions take a side each
func steady_mates(f) -> void:
	var o: Vector2 = f.marks.O
	if m.mate != null:
		m.mate.position = Vector3(o.x - 1.2, 0, o.y + 0.4)
	if m.mate2 != null:
		m.mate2.position = Vector3(o.x + 1.2, 0, o.y + 0.4)

func release(f) -> void:
	m.work_q = 5
	f.release_look()
	var first := give_reward()
	var lines: Array = Main.STORY.WORK_RELEASE.duplicate()
	if not first:
		lines[lines.size() - 1] = Main.STORY.WORK_RELEASE_AGAIN
	var o: Vector2 = f.marks.O
	m.burst(Vector3(o.x, 1.4, o.y), Color("#ffd27a"), 40, 3.0)
	m.sfx(784, 0.3, "triangle", 0.25)
	m.show_story("", m.cast_lines(lines))
	m.after_story = func(): m.toast("손잡이 둘 달린 등불을 마을의 심지에게 가져가자")
	m.save_game()

# +10 max HP once; a later round (work_hp kept) gets 80 gold
func give_reward() -> bool:
	if m.work_hp:
		m.player.gold += 80
		return false
	m.work_hp = true
	m.player.max_hp += WORK_HP
	m.player.hp = minf(float(m.player.max_hp), m.player.hp + WORK_HP)
	return true

# ---- the village: Simji takes the lantern and the repair bench appears by the square
func simji_key() -> bool:
	if m.work_q != 5 or Vector2(m.player.x, m.player.z).distance_to(m.village.marks.M) > 1.8:
		return false
	m.work_q = 6
	bench_look()
	m.show_story("", m.cast_lines(Main.STORY.WORK_SIMJI))
	m.save_game()
	return true

func build_bench() -> void:
	var c: Vector2 = m.village.marks.M
	var spot := c + Vector2(2.0, -1.0)
	for r in range(2, 5): # the first open tile a little east of Simji, clear of walls
		var found := false
		for a in 8:
			var p := c + Vector2.from_angle(a * TAU / 8.0) * r
			p = Vector2(round(p.x), round(p.y))
			if m.walkable(p.x, p.y) and m.walkable(p.x + 1, p.y) and m.walkable(p.x - 1, p.y):
				spot = p
				found = true
				break
		if found:
			break
	bench = Node3D.new()
	var wood: Material = m.mat_color(Color("#7a5434"))
	var top: MeshInstance3D = m.box(Vector3(1.4, 0.12, 0.7), wood)
	top.position = Vector3(0, 0.75, 0)
	bench.add_child(top)
	for side in [-0.55, 0.55]:
		var leg: MeshInstance3D = m.box(Vector3(0.12, 0.7, 0.55), wood)
		leg.position = Vector3(side, 0.35, 0)
		bench.add_child(leg)
	var hook: MeshInstance3D = m.box(Vector3(0.08, 0.9, 0.08), m.mat_color(Color("#4a3a28")))
	hook.position = Vector3(0.5, 1.2, 0)
	bench.add_child(hook)
	var lamp: MeshInstance3D = m.box(Vector3(0.3, 0.34, 0.3), m.glow_mat(Color("#ffd27a"), 1.4))
	lamp.position = Vector3(0.5, 1.45, 0.15)
	bench.add_child(lamp)
	for side in [-0.15, 0.15]: # its two handles
		var hd: MeshInstance3D = m.box(Vector3(0.05, 0.05, 0.24), m.mat_color(Color("#8a6038")))
		hd.position = Vector3(0.5 + side * 1.4, 1.66, 0.15)
		bench.add_child(hd)
	bench.position = Vector3(spot.x, 0, spot.y)
	m.add_child(bench)
	bench_look()

func bench_look() -> void:
	if bench != null:
		bench.visible = m.work_q >= 6

# ---- journal, waystones, save
func work_journal() -> String:
	match m.work_q:
		0: return tr("큰 방 북동쪽 구석, 손 둘 새긴 문 (E)")
		1: return tr("지하 1층: 작업등 %d/2, 그다음 벽돌 마개") % fl(0).lamps_lit()
		2: return tr("지하 2층: 사슬 기둥과 물길 마개")
		3: return tr("지하 3층: 벽의 죔쇠 %d/2") % fl(2).groups_open()
		4: return tr("수리 요람의 걸쇠 %d/3") % fl(2).latches_wound()
		5: return tr("등불을 마을의 심지에게")
	return tr("끝")

func deepest_way() -> int:
	for i in [2, 1, 0]:
		if m.work_ways[i]:
			return i
	return -1

func way_spot() -> Vector2:
	var i := deepest_way()
	return fl(i).marks.Y if i >= 0 else Vector2.ZERO

# any lit floor stone counts as the workshop's waystone for opening the list
func near_stone() -> bool:
	for i in 3:
		if m.work_ways[i] and Vector2(m.player.x, m.player.z).distance_to(fl(i).marks.Y) < 1.4:
			return true
	return false

func travel_in() -> void:
	enter_floor(maxi(deepest_way(), 0), "Y")

func save_data() -> Dictionary:
	return {"work_q": m.work_q, "work_floor": m.work_floor, "work_door": m.work_door, "work_seen": m.work_seen,
		"work_pulled": m.work_pulled, "work_cradle": m.work_cradle_seen, "work_hp": m.work_hp,
		"work_reads": m.work_reads, "work_ways": m.work_ways, "work_latch": m.work_latch,
		"work_lamps": fl(0).lamps.map(func(l): return l.lit), "work_clamps": fl(2).groups.map(func(g): return g.open)}

# old saves: nothing done. A finale cut short keeps its latches (no reset)
func load_work(d: Dictionary) -> void:
	m.work_q = int(d.get("work_q", 0))
	m.work_floor = int(d.get("work_floor", 0))
	m.work_door = bool(d.get("work_door", false))
	m.work_seen = bool(d.get("work_seen", m.work_door))
	m.work_pulled = bool(d.get("work_pulled", false))
	m.work_cradle_seen = bool(d.get("work_cradle", false))
	m.work_hp = bool(d.get("work_hp", false))
	for k in ["work_reads", "work_ways", "work_latch"]:
		var src: Array = d.get(k, [])
		var dst: Array = m.get(k)
		for i in mini(src.size(), dst.size()):
			dst[i] = bool(src[i])
	var b1 = fl(0)
	var b2 = fl(1)
	var b3 = fl(2)
	var ls: Array = d.get("work_lamps", [])
	for i in mini(ls.size(), b1.lamps.size()):
		if bool(ls[i]) and not b1.lamps[i].lit:
			b1.light(b1.lamps[i])
	if b1.lamps_lit() == b1.lamps.size() and not b1.planks_shown:
		b1.show_planks()
	if m.work_q >= 2 and not b1.groups[0].open:
		b1.open_group(b1.groups[0])
	if m.work_pulled and not b2.lid_open:
		b2.open_lid()
	if m.work_q >= 3 and not b2.drained:
		b2.open_group(b2.groups[0])
		b2.drain()
	var cs: Array = d.get("work_clamps", [])
	for i in mini(cs.size(), b3.groups.size()):
		if (bool(cs[i]) or m.work_q >= 4) and not b3.groups[i].open:
			b3.open_group(b3.groups[i])
	if m.work_q >= 4 and not b3.door_open:
		b3.open_door()
	for k in b3.latches.size():
		if m.work_latch[k] and not b3.latches[k].wound:
			b3.wind_latch(k)
	if m.work_q >= 5:
		b3.release_look()
	for i in 3:
		if m.work_ways[i]:
			fl(i).light_stone()
	door_look()
	bench_look()
