# Wind hills: cloud mound, gusts, scarecrow, the sparrows' mill, wind run, the hawk.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const WINDRUN_TIME := 12.0
const WINDRUN_STEP := 2.0 # each missed run adds this many seconds to the next, at most to WINDRUN_MAX
const WINDRUN_MAX := 18.0
const GLIDE_TIME := 0.6 # the gust that carries Sora back to the wind post (the user, 2026-10-25: he did not know how to try again)
var post_flag: Node3D
var post_mark: Label3D

func _init(main: Main) -> void:
	m = main

# ---- 구름 둔덕 above the hill (after the hawk): wind vents across open sky, the brick scarecrow, the wind feather
func in_cloud() -> bool:
	return m.in_hill and m.player.x >= Main.CLOUD.CLOUD_X - 0.5 and m.player.x < Main.CASTLE.CASTLE_X - 0.5

# wind vents exist on the cloud mound and on the castle's broken floor
func vent_here(x: float, z: float) -> Vector2:
	if m.in_under():
		return m.under.vent_at(x, z)
	if m.in_stairs():
		return m.stairs.vent_at(x, z)
	if m.in_castle():
		return m.castle.vent_at(x, z)
	if in_cloud():
		return m.cloud.vent_at(x, z)
	return Vector2.ZERO

func gust_char(x: float, z: float) -> String:
	if x >= Main.UNDER.UNDER_X - 0.5:
		return m.under.char_at(x, z)
	if x >= Main.STAIRS.STAIRS_X - 0.5:
		return m.stairs.char_at(x, z)
	return m.castle.char_at(x, z) if x >= Main.CASTLE.CASTLE_X - 0.5 else m.cloud.char_at(x, z)

func enter_cloud() -> void:
	m.player.x = m.cloud.marks.S.x + 1.2
	m.player.z = m.cloud.marks.S.y
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = m.cloud.map_tex(Main.CLOUD.CLOUD_X + Main.CLOUD.W)
	m.ui.zone_name.text = "구름 둔덕"
	m.ui.zone_sub.text = "바람구멍 섬들"
	m.snap_mates()
	if not m.cloud_spawned:
		m.cloud_spawned = true
		for f in m.cloud.foes:
			m.spawn_enemy(f[0], f[1])
	if m.cloud_q == 0:
		m.cloud_q = 1
		m.show_story("", Main.STORY.CLOUD_IN)
	m.save_game()

func leave_cloud() -> void:
	m.player.x = m.hill.marks.U.x
	m.player.z = m.hill.marks.U.y + 1.3
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
	m.ui.zone_name.text = "바람 언덕"
	m.ui.zone_sub.text = "언덕 꼭대기"
	m.ui.boss.visible = false
	m.snap_mates()
	m.save_game()

# stepping onto a vent from plain ground starts a gust: Sora flies 8 tiles/s the way it points, over the gap,
# and lands 0.6 tiles onto the next island. Normal walking is off while she flies.
func start_gust(dir: Vector2) -> void:
	m.gust_dir = dir
	m.gust_t = 0.0
	m.gust_gap = false
	m.gust_solid = 0.0
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.sfx(260, 0.45, "noise", 0.1, 500)
	m.burst(Vector3(m.player.x, 0.4, m.player.z), Color("#ffffff"), 16, 2.0)

func update_gust(dt: float) -> void:
	m.gust_t += dt
	var step := m.gust_dir * 8.0 * dt
	var np := Vector2(m.player.x, m.player.z) + step
	if gust_char(np.x, np.y) == "#" or m.gust_t > 3.0:
		m.gust_dir = Vector2.ZERO
		return
	m.player.x = np.x
	m.player.z = np.y
	if gust_char(np.x, np.y) == "_":
		m.gust_gap = true
	elif m.gust_gap:
		m.gust_solid += step.length()
		if m.gust_solid >= 0.6 and m.walkable(np.x, np.y):
			m.gust_dir = Vector2.ZERO
	if int(m.gust_t * 10.0) != int((m.gust_t - dt) * 10.0):
		m.burst(Vector3(m.player.x, 0.5, m.player.z), Color("#ffffff"), 3, 0.8)

func cloud_key() -> bool:
	var cx := float(Main.CLOUD.CLOUD_X)
	var me := Vector2(m.player.x, m.player.z)
	if not m.cloud.shard_open and me.distance_to(m.cloud.marks.q) < 1.6:
		m.cloud.shard_look()
		m.has_shard = true
		m.burst(Vector3(m.cloud.marks.q.x, 0.8, m.cloud.marks.q.y), Color("#bfe6ff"), 40, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.show_story("", Main.STORY.CLOUD_SHARD)
		m.save_game()
		return true
	if me.x < cx + 7.0 and me.y > 10.5: # by the unseen path: hold up the crown and it shows for 3 s
		m.cloud.reveal_t = 3.0
		m.cloud.reveal(true)
		m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#bfe6ff"), 14, 1.5)
		m.sfx(988, 0.3, "sine", 0.18)
		return true
	if not m.cloud_chest and Vector2(m.player.x, m.player.z).distance_to(m.cloud.marks.c) < 1.6:
		m.cloud_chest = true
		m.cloud.opened_look()
		m.player.gold += 100
		m.player.pots += 1
		m.burst(Vector3(m.cloud.marks.c.x, 0.8, m.cloud.marks.c.y), Color("#f2ead8"), 30, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.toast("금화 100닢과 회복약을 찾았다")
		m.save_game()
		return true
	return false

func spawn_scarecrow() -> void:
	if m.enemies.any(func(e): return e.get("scare", false) and not e.dead):
		return
	var at: Vector2 = m.cloud.marks.K
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var wood: Material = m.mat_color(Color("#6a4a2a"))
	var straw: Material = m.mat_color(Color("#d8b04a"))
	var cloth: Material = m.mat_color(Color("#4a6a9a"))
	for part in [[Vector3(0.2, 1.6, 0.2), Vector3(0, 0.8, 0), wood], [Vector3(0.8, 0.8, 0.5), Vector3(0, 1.4, 0), cloth],
			[Vector3(0.6, 0.55, 0.55), Vector3(0, 2.1, 0), straw], [Vector3(0.9, 0.12, 0.9), Vector3(0, 2.45, 0), wood],
			[Vector3(0.45, 0.3, 0.45), Vector3(0, 2.65, 0), wood]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		body.add_child(b)
	for side in [-0.14, 0.14]:
		var eye := m.box(Vector3(0.1, 0.1, 0.05), m.glow_mat(Color("#ff8a30"), 2.0))
		eye.position = Vector3(side, 2.15, 0.29)
		body.add_child(eye)
	var arms := Node3D.new() # the cross-bar arms, which spin on the big attack
	arms.name = "arms"
	arms.position = Vector3(0, 1.55, 0)
	body.add_child(arms)
	var bar := m.box(Vector3(2.6, 0.18, 0.18), wood)
	arms.add_child(bar)
	for side in [-1.3, 1.3]:
		var tuft := m.box(Vector3(0.35, 0.35, 0.35), straw)
		tuft.position = Vector3(side, 0, 0)
		arms.add_child(tuft)
	m.add_child(root)
	m.enemies.append({"x": at.x, "z": at.y, "hp": 820.0, "max_hp": 820, "node": root, "shadow": m.blob(1.2), "t": 0.0,
		"atk_cd": 1.6, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"scare": true, "cave": true, "wind": 0.0, "stun": 0.0, "next": "", "spins": 0, "spin_t": 0.0})

# the brick scarecrow: close in, a 0.8 s wind-up (red ring) then a 2.6-tile arm spin (twice below half);
# farther out, a 0.6 s wind-up then straw bricks flung four ways (eight below half), turned a little each time
func update_scarecrow(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var body: Node3D = node.get_node("body")
	var arms: Node3D = body.get_node("arms")
	m.ui.boss.visible = d < 12.0
	m.ui.boss_name.text = "벽돌 허수아비"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	var angry: bool = e.hp < e.max_hp / 2.0
	body.rotation.z = sin(e.t * 2.0) * 0.06 # sways on its post
	if e.spin_t > 0.0:
		e.spin_t -= dt
		arms.rotation.y += dt * 18.0
	if e.stun > 0.0:
		pass
	elif e.wind > 0.0:
		e.wind -= dt
		arms.rotation.y += dt * (6.0 if e.next == "spin" else 0.0)
		if e.wind <= 0.0:
			if e.next == "spin":
				e.spin_t = 0.5
				m.burst(Vector3(e.x, 1.4, e.z), Color("#d8b04a"), 24, 4.0)
				m.sfx(200, 0.4, "noise", 0.15, 300)
				if d < 2.6:
					m.player_hit(20 + m.foe_lv(), Vector2(e.x, e.z), e)
				if e.spins > 0:
					e.spins -= 1
					e.wind = 0.5
					m.warn_ring(Vector3(e.x, 0.0, e.z), 2.6, 0.5)
					return
			else:
				var n := 8 if angry else 4
				var a0: float = e.t
				for k in n:
					m.monsters.throw_brick(Vector2(e.x, e.z), Vector2.RIGHT.rotated(a0 + k * TAU / n), e)
			e.atk_cd = 1.1 if angry else 1.6
	else:
		e.atk_cd -= dt
		if e.atk_cd <= 0.0 and d < 10.0:
			e.next = "spin" if d < 2.6 else "fling"
			if e.next == "spin":
				e.wind = 0.8
				e.spins = 1 if angry else 0
				m.warn_ring(Vector3(e.x, 0.0, e.z), 2.6, 0.8)
			else:
				e.wind = 0.6
			m.pop_num(Vector3(e.x, 3.0, e.z), "!", Color("#ff5a4a") if e.next == "spin" else Color("#ffd84a"))
		elif d > 3.0: # hops slowly after her on its post
			var nx: float = e.x + to.x / d * 0.8 * dt
			var nz: float = e.z + to.y / d * 0.8 * dt
			if m.walkable(nx, e.z): e.x = nx
			if m.walkable(e.x, nz): e.z = nz
	body.position.y = absf(sin(e.t * 4.0)) * 0.08
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func scarecrow_beaten() -> void:
	m.cloud_q = 3
	m.has_feather = true
	m.ui.boss.visible = false
	m.player.gold += 160
	m.gain_xp(240)
	m.show_story("", Main.STORY.SCARE_DOWN)
	m.save_game()

# ---- the wind hills (between the forest and the garden)
func enter_hill() -> void:
	m.windrun_tries = 0
	m.in_forest = false
	m.in_hill = true
	m.player.x = m.hill.marks.S.x + 1.2
	m.player.z = m.hill.marks.S.y
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
	m.ui.zone_name.text = "바람 언덕"
	m.ui.zone_sub.text = "멈춘 풍차들"
	m.snap_mates()
	if m.hill_q == 0:
		m.hill_q = 1
		for f in m.hill.foes:
			if f[1] == "w":
				m.spawn_wolf(f[0])
				continue
			m.spawn_enemy(f[0], f[1] == "a")
			var e: Dictionary = m.enemies[m.enemies.size() - 1]
			e.cave = true
			if f[1] == "s":
				give_shield(e)
		m.show_story("", Main.STORY.HILL_IN)
	if m.hill_q == 1:
		m.set_quest(tr("풍차를 팔찌로 감자 (E) %d/3") % m.hill.turning_count())
	elif m.hill_q == 2:
		m.set_quest("바람 다리를 건너 벽돌 매를 물리치자")
	m.save_game()

func leave_hill() -> void:
	m.windrun_tries = 0
	m.in_hill = false
	m.in_forest = true
	m.player.x = m.forest.marks.E.x - 1.2
	m.player.z = m.forest.marks.E.y
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.forest.map_tex(Main.FOREST.FOREST_X + Main.FOREST.W)
	m.ui.zone_name.text = "굳은 숲"
	m.ui.zone_sub.text = "노을의 빈터"
	m.ui.boss.visible = false
	m.snap_mates()
	m.save_game()

# a shield goblin: a round brick shield in front that takes three hits to break,
# and is lowered while the goblin winds up its own attack
func give_shield(e: Dictionary) -> void:
	e.shield = 3
	var sh := m.box(Vector3(0.7, 0.7, 0.12), m.mat_color(Color("#c8962a")))
	sh.position = Vector3(0, 0.5, 0.36)
	(e.node.get_meta("body") as Node3D).add_child(sh)
	e.shield_node = sh

func hill_key() -> bool:
	for mill in m.hill.mills:
		if not mill.turning and Vector2(m.player.x, m.player.z).distance_to(mill.pos) < 1.9:
			if not m.spend_pips(1):
				return true
			m.hill.wind_mill(mill, m)
			m.burst(Vector3(mill.pos.x, 3.0, mill.pos.y + 0.7), Color("#f2ead8"), 30, 3.0)
			m.sfx(330, 0.5, "sine", 0.25, 200)
			var n: int = m.hill.turning_count()
			if n >= 3:
				m.hill_q = 2
				m.hill.raise_bridge()
				m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
				m.show_story("", Main.STORY.WIND_BRIDGE)
				m.set_quest("바람 다리를 건너 벽돌 매를 물리치자")
			else:
				m.set_quest(tr("풍차를 팔찌로 감자 (E) %d/3") % n)
			m.save_game()
			return true
	return false

func mate_power() -> float:
	return 0.7 if m.has_oar_ring else 0.6

# the wind post (a sky-blue flag) and the four pinwheels in the hollow; they stand still until passed
func build_windrun() -> void:
	var post := Node3D.new()
	var wood: Material = m.mat_color(Color("#7a5a3a"))
	var pole: MeshInstance3D = m.box(Vector3(0.18, 1.6, 0.18), wood)
	pole.position = Vector3(0, 0.8, 0)
	post.add_child(pole)
	var flag: MeshInstance3D = m.box(Vector3(0.7, 0.4, 0.06), m.mat_color(Color("#7ac8e8")))
	flag.position = Vector3(0.38, 1.4, 0)
	post.add_child(flag)
	post_flag = flag
	post_mark = Label3D.new() # the key that starts the run, floating over the post while it is waiting
	post_mark.font = m.ui_font
	post_mark.font_size = 48
	post_mark.pixel_size = 0.012
	post_mark.outline_size = 14
	post_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	post_mark.no_depth_test = true
	post_mark.position = Vector3(0, 2.3, 0)
	post_mark.visible = false
	post.add_child(post_mark)
	var at: Vector2 = m.hill.south_marks.P
	post.position = Vector3(at.x, 0, at.y)
	m.add_child(post)
	m.rocks.append({"x": at.x, "z": at.y, "r": 0.3})
	var cols := [Color("#e84a4a"), Color("#4a8ae8"), Color("#e8c84a"), Color("#4ac87a")]
	for p in m.hill.wheels:
		var g := Node3D.new()
		var stick: MeshInstance3D = m.box(Vector3(0.1, 1.3, 0.1), wood)
		stick.position = Vector3(0, 0.65, 0)
		g.add_child(stick)
		var hub := Node3D.new()
		hub.name = "hub"
		hub.position = Vector3(0, 1.35, 0.08)
		g.add_child(hub)
		for k in 4:
			var blade: MeshInstance3D = m.box(Vector3(0.42, 0.16, 0.03), m.mat_color(cols[k]))
			blade.position = Vector3(cos(k * PI / 2.0) * 0.22, sin(k * PI / 2.0) * 0.22, 0)
			blade.rotation.z = k * PI / 2.0
			hub.add_child(blade)
		g.position = Vector3(p.x, 0, p.y)
		m.add_child(g)
		m.windrun_nodes.append(g)

func mill_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	var sm: Dictionary = m.hill.south_marks
	if not m.hill.gate_open and me.distance_to(sm.G) < 1.6:
		if m.hill_q < 3:
			m.toast("무너진 벽돌 담이다")
			return true
		if not m.spend_pips(m.unbrick_cost()):
			return true
		m.hill.open_wall()
		m.mill_q = maxi(m.mill_q, 1)
		m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
		m.burst(Vector3(sm.G.x, 0.7, sm.G.y), Color("#8a6a4a"), 36, 3.5)
		m.burst(Vector3(sm.G.x, 1.6, sm.G.y), Color("#8a6a4a"), 12, 2.5) # the sparrows fly down
		m.shake = 0.25
		m.sfx(196, 0.5, "triangle", 0.3, -60)
		m.show_story("", Main.STORY.MILL_GATE)
		spawn_mill_foes()
		m.save_game()
		return true
	if me.y < Main.HILL.MILL_Z - 0.5:
		return false
	if m.mill_q == 1 and me.distance_to(sm.Q) < 2.0:
		if not m.spend_pips(1):
			return true
		m.hill.wind_mill4(m)
		m.mill_q = 2
		m.burst(Vector3(sm.Q.x, 3.5, sm.Q.y + 0.9), Color("#f2ead8"), 30, 3.0)
		m.sfx(330, 0.5, "sine", 0.25, 200)
		m.show_story("", Main.STORY.MILL_STILL)
		m.save_game()
		return true
	if m.mill_q >= 2 and not m.windrun_on and m.windrun_glide.is_empty() and me.distance_to(sm.P) < 1.6:
		m.windrun_on = true
		m.windrun_left = windrun_time()
		m.windrun_got = []
		var cur: String = m.ui.quest.text
		if cur.begins_with(windrun_prefix()):
			m.windrun_quest = m.main_road_quest()
		elif cur.begins_with(retry_prefix()): # the line before the first try is kept through the retries
			m.windrun_quest = m.windrun_quest if m.windrun_quest != "" else m.main_road_quest()
		else:
			m.windrun_quest = m.quest_raw
		m.sfx(523, 0.12, "triangle", 0.2)
		m.toast(tr("%d초 안에 바람개비 넷을 지나자!") % int(m.windrun_left))
		return true
	if me.distance_to(sm.b) < 1.8:
		m.show_story("", Main.STORY.MILL_BOAT)
		return true
	if me.distance_to(sm.k) < 1.6:
		m.sfx(1175, 0.6, "sine", 0.25)
		m.show_story("", Main.STORY.MILL_BELL)
		return true
	if m.mill_q == 4 and me.distance_to(sm.c) < 1.6:
		m.mill_q = 5
		m.hill.chest_look()
		if not m.has_oar_ring:
			m.has_oar_ring = true
			m.player.max_hp += 10
			m.player.hp = float(m.player.max_hp)
			m.player.pots += 1
			m.show_story("", Main.STORY.MILL_CHEST)
		else: # a new round: the ring came along
			m.player.gold += 40
			m.player.pots += 1
			m.toast("금화 40, 회복약 1")
		m.burst(Vector3(sm.c.x, 0.8, sm.c.y), Color("#e8d27a"), 40, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.save_game()
		return true
	return false

func spawn_mill_foes() -> void:
	if m.mill_spawned or m.mill_q >= 4:
		return
	m.mill_spawned = true
	for f in m.hill.south_foes:
		match f[1]:
			"w":
				m.spawn_wolf(f[0])
			"j":
				m.monsters.spawn_hog(f[0])
			_:
				m.spawn_enemy(f[0], f[1] == "a")
				if f[1] == "s":
					give_shield(m.enemies[m.enemies.size() - 1])

# the big guardian at the channel's mouth (the undercroft guardians' look), with two goblins
func spawn_mill_guard() -> void:
	if m.enemies.any(func(e): return e.get("mill_guard", false) and not e.dead):
		return
	var at: Vector2 = m.hill.south_marks.K
	m.spawn_enemy(at)
	var e: Dictionary = m.enemies[m.enemies.size() - 1]
	e.hp = 300.0 + m.foe_lv() * 30
	e.max_hp = int(e.hp)
	e.size_k = 1.7
	e.mill_guard = true
	var mats: Array = e.node.get_meta("mats")
	mats[2].albedo_color = Color("#5a6470")
	mats[5].albedo_color = Color("#bfe6ff")
	e.atk_cd = 1.5
	for k in 2:
		m.spawn_enemy(at + Vector2(m.rnd(-2.0, 2.0), m.rnd(-1.5, -0.5)))
	m.burst(Vector3(at.x, 0.6, at.y), Color("#bfe6ff"), 20, 2.5)
	m.shake = 0.3
	m.sfx(110, 0.4, "square", 0.25, 60)

func mill_guard_beaten() -> void:
	m.mill_q = maxi(m.mill_q, 4)
	m.player.gold += 60
	m.gain_xp(120)
	m.show_story("", Main.STORY.MILL_GUARD_DOWN)
	m.save_game()

func update_mill(dt: float) -> void:
	var me := Vector2(m.player.x, m.player.z)
	var sm: Dictionary = m.hill.south_marks
	m.hill.sparrows.visible = m.hill_q >= 3 and not m.hill.gate_open
	if m.mill_q >= 3:
		m.hill.mill4.blades.rotation.z += dt * 1.2
	for i in m.windrun_nodes.size():
		if (m.windrun_on and i in m.windrun_got) or m.mill_q >= 3:
			m.windrun_nodes[i].get_node("hub").rotation.z += dt * 6.0
	if me.y > Main.HILL.MILL_Z - 0.5:
		m.ui.zone_sub.text = "참새 방앗간"
	elif m.ui.zone_sub.text == "참새 방앗간":
		m.ui.zone_sub.text = "멈춘 풍차들"
	if m.windrun_on:
		update_windrun(dt)
	update_post(me)
	if m.story_open:
		return
	if m.hill_q >= 3 and m.mill_q == 0 and not m.mill_hint_told and me.distance_to(sm.G) < 5.0:
		m.mill_hint_told = true
		m.show_story("", Main.STORY.MILL_HINT)
		return
	if m.mill_q >= 1 and m.mill_q < 4:
		spawn_mill_foes()
	if m.mill_q >= 1 and not m.mill_in_told and me.y > 27.5:
		m.mill_in_told = true
		m.show_story("", Main.STORY.MILL_IN)
		return
	if m.mill_q == 3 and me.y > 27.5:
		spawn_mill_guard()

# the post's flag flutters while the first run is still to be won, and the key floats over it when Sora is near
func update_post(me: Vector2) -> void:
	if post_flag == null:
		return
	var waiting: bool = m.mill_q == 2 and not m.windrun_on
	post_flag.rotation.y = sin(m.t * 6.0) * 0.4 if m.mill_q == 2 else 0.0
	var near: bool = waiting and me.distance_to(m.hill.south_marks.P) < 6.0 and m.windrun_glide.is_empty()
	post_mark.visible = near
	if near:
		post_mark.text = m.touch_words(tr("E"))
		post_mark.position.y = 2.3 + sin(m.t * 3.0) * 0.12

func windrun_time() -> float:
	return minf(WINDRUN_MAX, WINDRUN_TIME + WINDRUN_STEP * m.windrun_tries)

func retry_prefix() -> String: # "깃대에서 E: 바람 부르기 다시 " as the quest line shows it
	return m.touch_words(tr("깃대에서 E: 바람 부르기 다시 (%d번째)")).split("%")[0]

func retry_quest() -> String:
	return tr("깃대에서 E: 바람 부르기 다시 (%d번째)") % (m.windrun_tries + 1)

# a missed run: before the first win the quest line says where to press E again, the next run is 2 s longer and (when
# she is still in the hollow) a gust carries her back to the post
func miss_windrun(glide: bool) -> void:
	if m.mill_q != 2:
		end_windrun("바람이 흩어졌다. 깃대에서 다시 해 보자")
		return
	m.windrun_on = false
	m.windrun_tries += 1
	m.set_quest(retry_quest())
	m.toast(tr("바람이 흩어졌다. 다음엔 %d초") % int(windrun_time()))
	if glide:
		start_glide()

func start_glide() -> void:
	var post: Vector2 = m.hill.south_marks.P
	var first: Vector2 = m.hill.wheels[0]
	var to := post
	for off in [(first - post).normalized(), Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		if m.player_can(post.x + off.x, post.y + off.y):
			to = post + off
			break
	var from := Vector2(m.player.x, m.player.z)
	m.windrun_glide = {"from": from, "to": to, "t": 0.0, "dur": maxf(GLIDE_TIME, from.distance_to(to) / 14.0), "puff": 0.0}
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.sfx(260, 0.45, "noise", 0.1, 500)
	m.burst(Vector3(from.x, 0.4, from.y), Color("#ffffff"), 16, 2.0)

func update_glide(dt: float) -> void:
	var g: Dictionary = m.windrun_glide
	g.t += dt
	var k: float = clampf(g.t / g.dur, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var np: Vector2 = g.from.lerp(g.to, k)
	m.player.x = np.x
	m.player.z = np.y
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.player.inv = maxf(m.player.inv, 0.3)
	m.ground_y = m.height_at(np.x, np.y)
	g.puff -= dt
	if g.puff <= 0.0:
		g.puff = 0.05
		m.burst(Vector3(np.x, 0.5, np.y), Color("#ffffff"), 3, 0.8)
	if g.t >= g.dur:
		var look: Vector2 = (m.hill.wheels[0] - np).normalized() # lands facing the first pinwheel
		if look != Vector2.ZERO:
			m.player.face = look
		m.windrun_glide = {}
		m.burst(Vector3(np.x, 0.4, np.y), Color("#ffffff"), 10, 1.5)

func update_windrun(dt: float) -> void:
	if not m.in_hill or m.player.z < Main.HILL.MILL_Z - 0.5:
		miss_windrun(false)
		return
	m.windrun_left -= dt
	for i in m.hill.wheels.size():
		if i in m.windrun_got:
			continue
		var w: Vector2 = m.hill.wheels[i]
		if Vector2(m.player.x, m.player.z).distance_to(w) < 1.0:
			m.windrun_got.append(i)
			m.burst(Vector3(w.x, 1.3, w.y), Color("#f2ead8"), 14, 2.0)
			m.sfx(660 + m.windrun_got.size() * 80, 0.12, "triangle", 0.2)
	m.set_quest(tr("바람 부르기 %d/4 · %d초") % [m.windrun_got.size(), int(ceil(m.windrun_left))])
	if m.windrun_got.size() == m.hill.wheels.size():
		if m.mill_q == 2:
			m.windrun_tries = 0
			end_windrun("바람이 골로 내려왔다!")
			m.mill_q = 3
			m.hill.fill()
			m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
			m.show_story("", Main.STORY.MILL_WIND)
			m.after_story = spawn_mill_guard
			m.save_game()
		else:
			end_windrun("바람이 골을 한 바퀴 돌았다")
	elif m.windrun_left <= 0.0:
		miss_windrun(true)

func windrun_prefix() -> String: # "바람 부르기 " as the quest line shows it
	return m.touch_words(tr("바람 부르기 %d/4 · %d초")).split("%")[0]

func end_windrun(msg: String) -> void:
	m.windrun_on = false
	m.set_quest(m.windrun_quest)
	m.toast(msg)

func update_hill(dt: float) -> void:
	if m.player.x < Main.GROTTO.GROTTO_X - 0.5:
		update_mill(dt)
	for mill in m.hill.mills:
		if mill.turning:
			mill.blades.rotation.z += dt * 1.6
	if m.hill_q == 2 and not m.story_open and Vector2(m.player.x, m.player.z).distance_to(m.hill.marks.B) < 6.0 \
			and not m.enemies.any(func(e): return e.get("hawk", false) and not e.dead):
		m.show_story("", Main.STORY.HAWK_IN)
		m.after_story = spawn_hawk

func spawn_hawk() -> void:
	if m.enemies.any(func(e): return e.get("hawk", false) and not e.dead):
		return
	var at: Vector2 = m.hill.marks.B
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var brown: Material = m.mat_color(Color("#8a6a4a"))
	var grey: Material = m.mat_color(Color("#9a9aa2"))
	for part in [[Vector3(0.7, 0.6, 1.2), Vector3(0, 0, 0), brown], [Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0.75), grey],
			[Vector3(0.18, 0.14, 0.3), Vector3(0, 0.18, 1.1), m.mat_color(Color("#e8a020"))], [Vector3(0.5, 0.15, 0.6), Vector3(0, 0, -0.85), brown]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		body.add_child(b)
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "wing_l" if side < 0 else "wing_r"
		wing.position = Vector3(side * 0.35, 0.1, 0)
		body.add_child(wing)
		var w := m.box(Vector3(1.6, 0.1, 0.8), grey)
		w.position = Vector3(side * 0.8, 0, 0)
		wing.add_child(w)
	for side in [-0.14, 0.14]:
		var eye := m.box(Vector3(0.08, 0.08, 0.05), m.glow_mat(Color("#ffb040"), 2.0))
		eye.position = Vector3(side, 0.35, 1.0)
		body.add_child(eye)
	root.scale = Vector3.ONE * 1.4
	m.add_child(root)
	m.enemies.append({"x": at.x, "z": at.y, "hp": 780.0, "max_hp": 780, "node": root, "shadow": m.blob(1.2), "t": 0.0,
		"atk_cd": 2.5, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"hawk": true, "cave": true, "air": true, "y": 2.8, "wind": 0.0, "dash": 0.0, "dir": Vector2.ZERO,
		"stun": 0.0, "target": Vector2.ZERO, "egg_cd": 1.5, "eggs": []})

# the brick hawk circles out of reach (no damage while "air"); it marks Sora's spot, dives onto it,
# and sits stunned on the ground for 2 s. Below half HP it drops brick eggs while circling.
func update_hawk(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var body: Node3D = node.get_node("body")
	m.ui.boss.visible = true
	m.ui.boss_name.text = "벽돌 매"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	var flap := sin(e.t * (14.0 if e.air else 3.0)) * 0.5
	body.get_node("wing_l").rotation.z = flap
	body.get_node("wing_r").rotation.z = -flap
	var c: Vector2 = m.hill.marks.B
	if e.dash > 0.0: # diving onto the marked spot
		e.dash -= dt
		var k: float = 1.0 - e.dash / 0.5
		e.x = lerpf(e.wx, e.target.x, k)
		e.z = lerpf(e.wz, e.target.y, k)
		e.y = lerpf(2.8, 0.4, k)
		if e.dash <= 0.0:
			e.air = false
			e.stun = 2.0
			m.shake = 0.3
			m.burst(Vector3(e.x, 0.3, e.z), Color("#9a9aa2"), 24, 3.0)
			m.sfx(80, 0.3, "square", 0.3, -40)
			if Vector2(m.player.x, m.player.z).distance_to(e.target) < 1.4:
				m.player_hit(24, e.target, e)
	elif e.stun > 0.0:
		pass
	elif not e.air: # take off again
		e.y = minf(2.8, e.y + dt * 3.0)
		if e.y >= 2.8:
			e.air = true
			e.atk_cd = 2.3
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			e.dash = 0.5
			e.wx = e.x
			e.wz = e.z
	else:
		var a: float = e.t * 0.9
		var goal := c + Vector2(cos(a), sin(a)) * 3.0
		e.x = lerpf(e.x, goal.x, dt * 2.0)
		e.z = lerpf(e.z, goal.y, dt * 2.0)
		e.atk_cd -= dt
		if e.atk_cd <= 0.0:
			e.wind = 1.0
			e.target = Vector2(m.player.x, m.player.z)
			m.warn_ring(Vector3(e.target.x, 0.0, e.target.y), 1.4, 1.5)
			m.sfx(900, 0.4, "sawtooth", 0.15, -500)
		if e.hp < e.max_hp / 2.0:
			e.egg_cd -= dt
			if e.egg_cd <= 0.0:
				e.egg_cd = 1.3
				var p := Vector2(m.player.x, m.player.z) + Vector2(m.rnd(-2, 2), m.rnd(-2, 2))
				m.warn_ring(Vector3(p.x, 0.0, p.y), 1.0, 0.8)
				m.get_tree().create_timer(0.8).timeout.connect(func():
					m.burst(Vector3(p.x, 0.3, p.y), Color("#c8322a"), 14, 2.5)
					if Vector2(m.player.x, m.player.z).distance_to(p) < 1.0:
						m.player_hit(14, p, e))
	var face := Vector2(e.target.x - e.x, e.target.y - e.z) if e.wind > 0.0 or e.dash > 0.0 else Vector2(cos(e.t * 0.9 + PI / 2), sin(e.t * 0.9 + PI / 2))
	if face.length() > 0.1:
		node.rotation.y = atan2(face.x, face.y)
	node.position = Vector3(e.x, e.y, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func hawk_beaten() -> void:
	m.hill_q = 3
	m.ui.boss.visible = false
	m.player.gold += 250
	m.gain_xp(300)
	m.show_story("", Main.STORY.HAWK_DOWN)
	m.set_quest("언덕 동쪽 끝 길로, 달지기들의 성에 가자")
	m.save_game()
