# Sunken castle: hall, knight, quarters and doll, moon stairs, the undercroft.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const QUARTERS_HP := 10

func _init(main: Main) -> void:
	m = main

# ---- 달의 계단 (between the castle and the garden): four landings, four powers of the crown
func enter_stairs() -> void:
	clear_quarters_job()
	m.in_hill = true
	m.in_garden = false
	m.player.x = m.stairs.marks.S.x
	m.player.z = m.stairs.marks.S.y - 1.3
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = m.stairs.map_tex(Main.STAIRS.STAIRS_X + Main.STAIRS.W)
	m.ui.zone_name.text = "달의 계단"
	m.ui.zone_sub.text = "정원으로 오르는 길"
	m.snap_mates()
	if m.garden_q >= 1 and not m.stairs.door_open: # an older save already past this way
		open_stairs()
	if not m.stairs_spawned:
		m.stairs_spawned = true
		for f in m.stairs.foes:
			match f[1]:
				"w": m.spawn_wolf(f[0])
				"b": m.spawn_bat(f[0])
				_:
					m.spawn_enemy(f[0], f[1] == "a")
					m.enemies[m.enemies.size() - 1].cave = true
					if f[1] == "s":
						m.give_shield(m.enemies[m.enemies.size() - 1])
		if not m.stairs.door_open:
			m.show_story("", Main.STORY.STAIRS_IN)
	if not m.stairs.door_open:
		m.set_quest(stairs_quest())
	m.save_game()

func stairs_quest() -> String:
	if not m.stairs.wall_open:
		return "계단을 막은 벽돌 벽을 팔찌로 풀자 (E)"
	# past the wall the line follows the landing she stands on (a playtest found it pointing back at the open wall)
	if in_stairs() and m.player.z > 15.0:
		return "깊은 물길은 Shift를 누른 채 물수제비 걸음으로 건너자"
	if in_stairs() and m.player.z > 6.0:
		return "무너진 틈은 빛나는 바람구멍을 밟아 넘자"
	return tr("꼭대기 계단참의 등불 셋을 팔찌로 켜자 (E) %d/3") % m.stairs.lamps_lit()

func open_stairs() -> void:
	m.stairs.open_wall()
	for l in m.stairs.lamps:
		m.stairs.light_lamp(l)
	m.stairs.open_door()

func leave_stairs() -> void:
	m.player.x = m.castle.marks.E.x - 1.2
	m.player.z = m.castle.marks.E.y
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = castle_map()
	m.ui.zone_name.text = "가라앉은 달지기 성"
	m.ui.zone_sub.text = "옥좌의 방"
	m.snap_mates()
	m.save_game()

func stairs_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if not m.stairs.wall_open:
		for n in m.stairs.wall_nodes:
			if me.distance_to(Vector2(n.position.x, n.position.z)) < 1.6:
				if not m.spend_pips(1):
					return true
				m.stairs.open_wall()
				m.burst(Vector3(n.position.x, 0.7, n.position.z), Color("#8a6a4a"), 36, 3.5)
				m.shake = 0.25
				m.sfx(196, 0.5, "triangle", 0.3, -60)
				m.toast("계단의 벽돌 벽이 흙으로 풀렸다")
				m.ui.mini.map_tex = m.stairs.map_tex(Main.STAIRS.STAIRS_X + Main.STAIRS.W)
				m.set_quest(stairs_quest())
				m.save_game()
				return true
	for l in m.stairs.lamps:
		if not l.lit and me.distance_to(l.pos) < 1.6:
			if not m.spend_pips(1):
				return true
			m.stairs.light_lamp(l)
			m.burst(Vector3(l.pos.x, 1.8, l.pos.y), Color("#dfe8ff"), 20, 2.0)
			m.sfx(523 + m.stairs.lamps_lit() * 120, 0.25, "triangle", 0.22)
			if m.stairs.lamps_lit() == m.stairs.lamps.size():
				m.stairs.open_door()
				m.shake = 0.3
				m.ui.mini.map_tex = m.stairs.map_tex(Main.STAIRS.STAIRS_X + Main.STAIRS.W)
				m.show_story("", Main.STORY.STAIRS_TOP)
				m.set_quest(Main.STAIRS_DONE_QUEST) # the mold's heart comes only after the garden's seals (GPT playtest 5)
			else:
				m.set_quest(stairs_quest())
			m.save_game()
			return true
	return false

# ---- 가라앉은 달지기 성 (chapter 7) between the hill and the garden: the bricked gate, the flooded hall,
# the broken floor with vents, Hangyeol's three diary pages, the moon door and the brick knight
func in_castle() -> bool:
	return m.in_hill and m.player.x >= Main.CASTLE.CASTLE_X - 0.5 and m.player.x < Main.HOUSE_X - 0.5

func in_stairs() -> bool:
	return m.in_hill and m.player.x >= Main.STAIRS.STAIRS_X - 0.5 and m.player.x < Main.UNDER.UNDER_X - 0.5

func enter_castle() -> void:
	m.in_hill = true
	m.in_garden = false
	m.story_step = maxi(m.story_step, 10)
	m.player.x = m.castle.marks.S.x + 1.2
	m.player.z = m.castle.marks.S.y
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = castle_map()
	m.ui.zone_name.text = "가라앉은 달지기 성"
	m.ui.zone_sub.text = "굳은 성문"
	m.snap_mates()
	if not m.castle_spawned:
		m.castle_spawned = true
		for f in m.castle.foes:
			m.spawn_enemy(f[0], f[1] == "a")
			if f[1] == "s":
				m.give_shield(m.enemies[m.enemies.size() - 1])
		for b in Main.BAT_SPOTS:
			if b.x >= Main.CASTLE.CASTLE_X:
				m.spawn_bat(b)
	if m.castle_q == 0:
		m.castle_q = 1
		m.show_story("", Main.STORY.CASTLE_IN)
	if m.castle_q < 3:
		m.set_quest(castle_quest())
	m.save_game()

func castle_quest() -> String:
	if not m.castle.gate_open:
		return "성문의 벽돌을 팔찌로 풀자 (E)"
	if not m.castle.door_open:
		return tr("성 안에 흩어진 한결의 일기를 찾자 (E) %d/3") % m.castle.pages_read()
	return "옥좌의 방으로 가자"

func leave_castle() -> void:
	clear_quarters_job()
	m.player.x = m.hill.marks.X.x - 1.2
	m.player.z = m.hill.marks.X.y
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = m.hill.map_tex(Main.HILL.HILL_X + Main.HILL.W)
	m.ui.zone_name.text = "바람 언덕"
	m.ui.zone_sub.text = "매의 벼랑"
	m.ui.boss.visible = false
	m.snap_mates()
	m.save_game()

# E in the castle: unbrick the gate, or read a diary page; the third page opens the moon door
func castle_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if m.workshop_zone.door_key(): # the deep workshop's door in the great hall's north-east corner
		return true
	if not m.castle.gate_open:
		for n in m.castle.gate_nodes:
			if me.distance_to(Vector2(n.position.x, n.position.z)) < 1.6:
				if not m.spend_pips(m.unbrick_cost()):
					return true
				m.castle.open_gate()
				m.burst(Vector3(n.position.x, 0.7, n.position.z), Color("#8a6a4a"), 36, 3.5)
				m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
				m.shake = 0.25
				m.sfx(196, 0.5, "triangle", 0.3, -60)
				m.toast("성문의 벽돌이 흙으로 풀렸다")
				m.ui.mini.map_tex = castle_map()
				m.set_quest(castle_quest())
				m.save_game()
				return true
	if quarters_key():
		return true
	for i in m.castle.levers.size():
		if me.distance_to(m.castle.levers[i].pos) < 1.3:
			var was := m.castle.vault_solved()
			m.castle.flip_lever(i)
			m.sfx(220 + i * 60, 0.15, "square", 0.15, -60)
			m.burst(Vector3(m.castle.levers[i].pos.x, 0.9, m.castle.levers[i].pos.y), Color("#c8962a"), 6, 1.5)
			m.ui.mini.map_tex = castle_map()
			if m.castle.vault_solved() and not was:
				m.shake = 0.2
				m.sfx(330, 0.4, "triangle", 0.25, 200)
				m.toast("보물고의 창살 세 개가 모두 올라갔다")
			m.save_game()
			return true
	if not m.castle.vault_open and me.distance_to(Vector2(m.castle.vault_chest.position.x, m.castle.vault_chest.position.z)) < 1.6:
		m.castle.open_vault_look()
		m.has_armour = true
		m.player.gold += 150
		m.burst(m.castle.vault_chest.position + Vector3(0, 0.8, 0), Color("#e8c050"), 40, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.show_story("", Main.STORY.ARMOUR)
		m.save_game()
		return true
	var page_d := 99.0 # a diary page stand right beside a shelf wins when it is nearer
	for pg in m.castle.pages:
		page_d = minf(page_d, me.distance_to(pg.pos))
	var near_i := -1 # the nearest shelf within reach
	for i in m.castle.books.size():
		var d: float = me.distance_to(m.castle.books[i].pos)
		if d < 1.4 and d < page_d and (near_i < 0 or d < me.distance_to(m.castle.books[near_i].pos)):
			near_i = i
	for i in m.castle.books.size():
		var bk: Dictionary = m.castle.books[i]
		if i == near_i:
			var first: bool = not bk.read
			bk.read = true
			m.show_story("", Main.STORY.BOOKS[i])
			if first:
				m.sfx(523, 0.15, "triangle", 0.18)
				var n: int = m.castle.books.filter(func(b): return b.read).size()
				if n == m.castle.books.size():
					m.has_bookmark = true
					m.after_story = func(): m.show_story("", Main.STORY.BOOKMARK)
				else:
					m.toast(tr("달지기 책 %d/5") % n)
				m.save_game()
			return true
	for i in m.castle.pages.size():
		var p: Dictionary = m.castle.pages[i]
		if me.distance_to(p.pos) < 1.5:
			var first: bool = not p.read
			p.read = true
			m.show_story("", [Main.STORY.PAGE_1, Main.STORY.PAGE_2, Main.STORY.PAGE_3][m.castle.pages_read() - 1] if first else Main.STORY.PAGE_AGAIN)
			if first:
				m.sfx(660, 0.2, "triangle", 0.2)
				if m.castle.pages_read() == 3 and not m.castle.door_open:
					m.castle.open_door()
					m.shake = 0.3
					m.sfx(150, 0.6, "triangle", 0.3, -40)
					m.ui.mini.map_tex = castle_map()
				m.set_quest(castle_quest())
				m.save_game()
			return true
	return false

func spawn_knight(echo := false) -> void:
	if m.enemies.any(func(e): return e.get("knight", false) and not e.dead):
		return
	var at: Vector2 = m.garden.road_marks.X if echo else m.castle.marks.K
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var plate: Material = m.mat_color(Color("#8a8a90") if echo else Color("#7a7a86"))
	var dark: Material = m.mat_color(Color("#3a3a46"))
	var red: Material = m.mat_color(Color("#6e6c78") if echo else Color("#a8322a")) # the brick Hangyeol: grey where the knight is red
	for part in [[Vector3(0.3, 0.6, 0.3), Vector3(-0.22, 0.3, 0), dark], [Vector3(0.3, 0.6, 0.3), Vector3(0.22, 0.3, 0), dark],
			[Vector3(0.9, 0.8, 0.55), Vector3(0, 1.0, 0), plate], [Vector3(0.6, 0.55, 0.55), Vector3(0, 1.7, 0), plate],
			[Vector3(0.5, 0.08, 0.06), Vector3(0, 1.72, 0.29), dark], [Vector3(0.12, 0.35, 0.12), Vector3(0, 2.1, 0), red],
			[Vector3(1.0, 0.7, 0.12), Vector3(0, 0.75, -0.32), red]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		body.add_child(b)
	var shield := m.box(Vector3(0.9, 1.1, 0.14), m.mat_color(Color("#6a6672") if echo else Color("#c8962a"))) # the big shield, held in front
	if echo: # a brick crown on his head, its seams violet like the mold's
		var crown := m.box(Vector3(0.5, 0.25, 0.5), m.mat_color(Color("#6e6c78")))
		crown.position = Vector3(0, 2.1, 0)
		body.add_child(crown)
		var seam := m.box(Vector3(0.52, 0.05, 0.52), m.glow_mat(Color("#b48cff"), 1.6))
		seam.position = Vector3(0, 2.05, 0)
		body.add_child(seam)
	shield.position = Vector3(-0.35, 1.0, 0.45)
	body.add_child(shield)
	var sword := m.box(Vector3(0.12, 0.12, 1.3), m.mat_color(Color("#d8d8e0")))
	sword.name = "sword"
	sword.position = Vector3(0.62, 1.0, 0.5)
	body.add_child(sword)
	var eye := m.box(Vector3(0.3, 0.06, 0.05), m.glow_mat(Color("#ffb040"), 2.5))
	eye.position = Vector3(0, 1.74, 0.3)
	body.add_child(eye)
	root.scale = Vector3.ONE * 1.25
	m.add_child(root)
	var hp := 950.0 if echo else 1100.0
	m.enemies.append({"x": at.x, "z": at.y, "hp": hp, "max_hp": int(hp), "node": root, "shadow": m.blob(1.3), "t": 0.0, "echo": echo,
		"atk_cd": 1.5, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"knight": true, "cave": true, "wind": 0.0, "stun": 0.0, "tired": 0.0, "dash": 0.0, "dir": Vector2.ZERO,
		"next": "", "combo": 0, "slam_cd": 0.0, "hit_done": false, "face": Vector2(-1, 0)})

# the brick knight keeps his shield toward Sora: hits from his front 140 degrees are blocked unless he is
# stunned (flash guard: 2 s) or tired (1.2 s after a lunge, 0.6 s after his third slash).
# Close in: a three-slash combo (0.45 s wind-up each, 2.4-tile cone). From 2.4 to 8 tiles: a 0.7 s wind-up, then a lunge.
# Below half health: a 1.0 s ground slam (3-tile ring) every 6 s.
func update_knight(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var body: Node3D = node.get_node("body")
	var sword: Node3D = body.get_node("sword")
	m.ui.boss.visible = d < 13.0
	m.ui.boss_name.text = "벽돌 한결" if e.get("echo", false) else "벽돌 기사"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	e.tired -= dt
	e.slam_cd -= dt
	var angry: bool = e.hp < e.max_hp / 2.0
	var dirn: Vector2 = to / maxf(d, 0.01)
	body.rotation.x = 0.3 if (e.stun > 0.0 or e.tired > 0.0) else 0.0 # slumps forward while open
	sword.rotation.y = lerpf(sword.rotation.y, 0.0, dt * 8.0)
	if e.stun > 0.0 or e.tired > 0.0:
		e.dash = 0.0
		e.wind = 0.0
	elif e.dash > 0.0:
		e.dash -= dt
		var nx: float = e.x + e.dir.x * 10.0 * dt
		var nz: float = e.z + e.dir.y * 10.0 * dt
		if m.walkable(nx, nz):
			e.x = nx
			e.z = nz
		else:
			e.dash = 0.0
		if not e.hit_done and Vector2(m.player.x - e.x, m.player.z - e.z).length() < 1.3:
			e.hit_done = true
			if m.player_hit(22 + m.foe_lv(), Vector2(e.x, e.z) - e.dir, e) == "flash_guard":
				e.stun = 2.0
		if e.dash <= 0.0 and e.stun <= 0.0:
			e.tired = 1.2
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			match e.next:
				"slash":
					sword.rotation.y = -1.2
					m.burst(Vector3(e.x + e.face.x * 1.3, 1.0, e.z + e.face.y * 1.3), Color("#e8e8f0"), 10, 2.5)
					m.sfx(240, 0.08, "sawtooth", 0.15, 300)
					if d < 2.4 and dirn.dot(e.face) > 0.5:
						if m.player_hit(14 + m.foe_lv(), Vector2(e.x, e.z), e) == "flash_guard":
							e.stun = 2.0
					var sx: float = e.x + e.face.x * 0.5
					var sz: float = e.z + e.face.y * 0.5
					if m.walkable(sx, sz) and d > 1.2:
						e.x = sx
						e.z = sz
					e.combo -= 1
					if e.combo > 0 and e.stun <= 0.0:
						e.wind = 0.45
						e.face = dirn
						m.pop_num(Vector3(e.x, 2.9, e.z), "!", Color("#ff5a4a"))
					else:
						e.atk_cd = 1.0 if angry else 1.4
						if e.stun <= 0.0:
							e.tired = 0.6
				"lunge":
					e.dash = 0.45
					e.dir = e.face
					e.hit_done = false
					m.sfx(160, 0.3, "sawtooth", 0.2, 200)
				"slam":
					m.monsters.ring_wave(Vector3(e.x, 0.05, e.z))
					m.shake = 0.4
					m.sfx(60, 0.4, "square", 0.3, -30)
					m.burst(Vector3(e.x, 0.3, e.z), Color("#9a9284"), 30, 4.0)
					if d < 3.0:
						m.player_hit(24 + m.foe_lv(), Vector2(e.x, e.z), e)
					e.atk_cd = 1.2
	else:
		var want := atan2(dirn.y, dirn.x)
		var have := atan2(e.face.y, e.face.x)
		var turn := clampf(wrapf(want - have, -PI, PI), -3.0 * dt, 3.0 * dt) # slow to turn: get behind him
		e.face = e.face.rotated(turn)
		e.atk_cd -= dt
		if e.atk_cd <= 0.0 and d < 9.0:
			if angry and e.slam_cd <= 0.0 and d < 3.5:
				e.next = "slam"
				e.wind = 1.0
				e.slam_cd = 6.0
				m.warn_ring(Vector3(e.x, 0.0, e.z), 3.0, 1.0)
			elif d < 2.4:
				e.next = "slash"
				e.combo = 3
				e.wind = 0.45
				m.pop_num(Vector3(e.x, 2.9, e.z), "!", Color("#ff5a4a"))
			else:
				e.next = "lunge"
				e.wind = 0.7
				e.face = dirn
				m.pop_num(Vector3(e.x, 2.9, e.z), "!", Color("#ffd84a"))
		elif d > 2.0:
			var nx: float = e.x + dirn.x * 1.4 * dt
			var nz: float = e.z + dirn.y * 1.4 * dt
			if m.walkable(nx, e.z): e.x = nx
			if m.walkable(e.x, nz): e.z = nz
	node.rotation.y = atan2(e.face.x, e.face.y)
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func knight_beaten() -> void:
	m.castle_q = 3
	m.castle.set_spring(m.quarters_q == 0) # 달지기 숙소: what is left where he knelt
	m.ui.boss.visible = false
	m.player.gold += 250
	m.gain_xp(300)
	var lines: Array = Main.STORY.KNIGHT_DOWN.duplicate()
	var pip_lines := m.award_pip("knight")
	if not pip_lines.is_empty(): # after who he was, before Noeul asks about the garden
		lines = lines.slice(0, lines.size() - 1) + [Main.STORY.KNIGHT_PIP] + pip_lines + [lines[lines.size() - 1]]
	m.show_story("", lines)
	m.set_quest("동쪽 문을 지나 정원 한가운데로 가자")
	m.workshop_zone.door_look() # the bricks in the great hall's corner fall: the deep workshop's door
	m.ui.mini.map_tex = castle_map()
	m.save_game()

func castle_map() -> ImageTexture:
	return m.with_stair_marks(m.castle.map_tex(Main.CASTLE.CASTLE_X + Main.CASTLE.W), m.workshop_zone.castle_spots())

func doll_bits() -> Array:
	return m.enemies.filter(func(e): return e.has("doll") and not e.dead)

# E at the knight's spot and in the quarters (castle_key, before the levers and the pages)
func quarters_key() -> bool:
	if m.castle_q < 3:
		return false
	var me := Vector2(m.player.x, m.player.z)
	var mk: Dictionary = m.castle.marks
	if m.quarters_q == 0 and me.distance_to(mk.K) < 1.6:
		m.quarters_q = 1
		m.castle.set_spring(false)
		m.burst(Vector3(mk.K.x + 0.6, 0.3, mk.K.y + 0.5), Color("#ffc46a"), 12, 1.2)
		m.sfx(1400, 0.05, "square", 0.06)
		m.show_story("", Main.STORY.QUARTERS_SPRING)
		m.after_story = func(): m.toast("녹슨 태엽을 얻었다")
		m.save_game()
		return true
	if not m.castle.quarters_open and me.distance_to(mk.Q) < 1.6:
		if m.quarters_q == 0:
			m.toast("열쇠 무늬가 새겨진 작은 문이다. 꿈쩍도 하지 않는다")
			return true
		m.quarters_q = 2
		open_quarters_door()
		m.show_story("", Main.STORY.QUARTERS_DOOR)
		m.save_game()
		return true
	if m.quarters_q < 2:
		return false
	if m.quarters_q == 3 and not m.doll_walk and me.distance_to(m.doll_at) < 1.6:
		doll_resume()
		return true
	if m.quarters_q == 2 and me.distance_to(mk.k) < 1.6:
		if not m.stand_seen:
			m.stand_seen = true
			m.show_story("", Main.STORY.QUARTERS_STAND)
			m.after_story = wind_doll
		else:
			wind_doll()
		return true
	var near_r := 99.0
	for r in m.castle.racks:
		near_r = minf(near_r, me.distance_to(r))
	var near_m := me.distance_to(mk.m)
	if near_m < 1.4 and near_m <= near_r:
		m.tally_seen = true
		m.show_story("", Main.STORY.QUARTERS_TALLY + (Main.STORY.QUARTERS_TALLY_SHORE if m.shore_q >= 2 else Main.STORY.QUARTERS_TALLY_NOSHORE))
		return true
	if near_r < 1.4:
		var lines: Array = [Main.STORY.QUARTERS_BASKET[0]]
		if not m.basket_seen:
			m.basket_seen = true
			lines = Main.STORY.QUARTERS_BASKET + [Main.STORY.QUARTERS_BASKET_BORI if m.shore_q >= 3 else Main.STORY.QUARTERS_BASKET_SORA]
		m.show_story("", lines)
		return true
	if m.quarters_q >= 4 and not m.quarters_box and me.distance_to(mk.c) < 1.6:
		open_quarters_box()
		return true
	var at_log: bool = me.distance_to(mk.o) < 1.5
	var at_doll: bool = me.distance_to(m.doll_at) < 1.5 or me.distance_to(mk.h) < 1.5
	if m.quarters_q == 4 and (at_log or at_doll): # the last beat: the ledger, her name, then he sits (GPT's note)
		m.show_story("", Main.STORY.QUARTERS_LOG)
		m.after_story = quarters_sit
		return true
	if m.quarters_q >= 5 and at_log:
		m.show_story("", Main.STORY.QUARTERS_LOG_AGAIN)
		return true
	if m.quarters_q >= 5 and at_doll:
		m.show_story("", Main.STORY.QUARTERS_SEAT)
		return true
	return false

# the door's leaf slides 1 tile aside in 0.5 s and is gone
func open_quarters_door() -> void:
	m.castle.quarters_open = true
	var d: Node3D = m.castle.qdoor
	var tw := m.create_tween()
	tw.tween_property(d, "position:x", d.position.x + 1.0, 0.5)
	tw.tween_callback(func(): d.visible = false)
	m.burst(Vector3(d.position.x, 0.7, d.position.z), Color("#c8962a"), 16, 1.5)
	m.sfx(330, 0.4, "triangle", 0.2, -60)
	for k in 3:
		m.get_tree().create_timer(0.12 * k).timeout.connect(func(): m.sfx(1400, 0.03, "square", 0.05))
	m.ui.mini.map_tex = castle_map()

func spawn_quarter_foes() -> void:
	m.quarters_spawned = true
	for f in m.castle.quarter_foes:
		m.spawn_enemy(f[0], f[1] == "a")
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.cave = true # no respawn
		e.quarters = true
		if f[1] == "s":
			m.give_shield(e)
	for b in m.castle.quarter_bats:
		m.spawn_bat(b[0])
		m.enemies[m.enemies.size() - 1].quarters = true

# the crown winds him (1 pip): his eyes light and he steps down off the stand
func wind_doll() -> void:
	if m.quarters_q != 2 or not m.spend_pips(1):
		return
	m.quarters_q = 3
	m.castle.doll_wound(true)
	m.doll_at = Main.CASTLE.DOLL_PATH[0]
	m.doll_i = 1
	m.castle.doll_place(m.doll_at, Vector2(1, 0))
	m.doll_walk = true
	m.doll_wait = false
	m.doll_shed = false
	m.burst(Vector3(m.doll_at.x, 0.8, m.doll_at.y), Color("#9fd4ff"), 20, 2.0)
	m.burst(Vector3(m.player.x, m.ground_y + 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
	m.sfx(523, 0.3, "sine", 0.2, 200)
	m.show_story("", Main.STORY.QUARTERS_WAKE)
	m.after_story = func(): m.toast("깡통 문지기를 따라가자")
	m.save_game()

func doll_resume() -> void:
	m.doll_walk = true
	m.doll_wait = false
	m.doll_shed = false # the heaps rise again for this walk
	m.castle.doll_wound(true)
	if m.castle.doll_drop != null:
		m.castle.doll_drop.visible = false
	m.burst(Vector3(m.doll_at.x, 0.8, m.doll_at.y), Color("#9fd4ff"), 12, 1.5)
	m.sfx(1400, 0.05, "square", 0.06)
	m.toast("문지기가 다시 걷는다")

# three bits, one from each heap, run at him (the lantern ring's shards; they do not hit Sora)
func shed_doll_bits() -> void:
	for h in m.castle.heaps:
		m.spawn_enemy(h)
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.shard = true
		e.doll = true
		e.cave = true # no respawn
		e.hp = 18.0 + m.foe_lv() * 4
		e.max_hp = int(e.hp)
		e.post = m.doll_at
		for mm in e.node.get_meta("mats"):
			mm.albedo_color = Color("#a8322a").lightened(m.rnd(0, 0.15))
		m.burst(Vector3(h.x, 0.6, h.y), Color("#a8322a"), 10, 2.0)
	m.castle.show_heaps(false)
	m.sfx(110, 0.3, "square", 0.15, -30)
	m.toast("식당의 벽돌 더미가 문지기에게 달려든다")

# a bit reached him: his spring jumps out and lands at his feet; the rest of the bits crumble
func doll_knocked() -> void:
	m.doll_walk = false
	for e in doll_bits():
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
	m.castle.doll_wound(false)
	m.castle.doll.rotation.z = 0.0
	m.castle.show_heaps(true)
	if m.castle.doll_drop == null:
		m.castle.doll_drop = m.castle.key_mark(m, 0.4, m.mat_color(Color("#8a5a3a")))
		m.add_child(m.castle.doll_drop)
	var dr: Node3D = m.castle.doll_drop
	dr.visible = true
	dr.position = Vector3(m.doll_at.x, 0.6, m.doll_at.y)
	var tw := m.create_tween()
	tw.tween_property(dr, "position:y", 1.0, 0.2)
	tw.tween_property(dr, "position", Vector3(m.doll_at.x + 0.5, 0.04, m.doll_at.y + 0.3), 0.2)
	m.burst(Vector3(m.doll_at.x, 0.8, m.doll_at.y), Color("#a8322a"), 18, 2.5)
	m.shake = 0.15
	m.sfx(90, 0.3, "square", 0.2, -40)
	m.toast("태엽이 튕겨 나왔다. 문지기 곁에서 E")

# fainting, loading or leaving the castle: the bits go and he stops where he is (E beside him walks him on)
func clear_quarters_job() -> void:
	for e in doll_bits():
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
	m.doll_walk = false
	m.quarters_named = false
	if m.castle.doll != null:
		m.castle.doll.rotation.z = 0.0
	m.castle.show_heaps(true)

func update_quarters(dt: float) -> void:
	if m.castle.spring_node.visible: # the knight's spring glows faintly every 1.2 s
		m.castle.spring_glow.albedo_color.a = 0.25 + 0.6 * maxf(0.0, sin(m.t * TAU / 1.2))
	var me := Vector2(m.player.x, m.player.z)
	if me.y > 22.5 and not m.quarters_named:
		m.quarters_named = true
		m.ui.zone_sub.text = "달지기 숙소"
	elif me.y <= 22.5 and m.quarters_named:
		m.quarters_named = false
		m.ui.zone_sub.text = "옥좌의 방"
	if m.story_open or m.fade_rect.color.a > 0.0:
		return
	if me.y > 26.5 and not m.quarters_spawned:
		spawn_quarter_foes()
		if m.quarters_q <= 2:
			m.show_story("", Main.STORY.QUARTERS_IN)
		return
	if m.quarters_q == 3 and m.doll_walk:
		update_doll(dt, me)

# he walks his path at 1.5 tiles a second, swaying, a tick every 0.25 s
func update_doll(dt: float, me: Vector2) -> void:
	var gap := me.distance_to(m.doll_at)
	if gap > 12.0:
		m.doll_wait = true
	elif gap < 6.0:
		m.doll_wait = false
	if m.doll_wait:
		m.castle.doll.rotation.z = 0.0
		return
	if m.doll_at.x > 456.5 and not m.doll_shed:
		m.doll_shed = true
		shed_doll_bits()
	var path: Array = Main.CASTLE.DOLL_PATH
	if m.doll_i >= path.size():
		m.castle.doll.rotation.z = 0.0
		if doll_bits().is_empty():
			doll_at_door()
		return
	var to: Vector2 = path[m.doll_i] - m.doll_at
	var step := 1.5 * dt
	if to.length() <= step or (m.doll_i == path.size() - 1 and to.length() < 0.5): # stops at the door, not in it
		if m.doll_i < path.size() - 1:
			m.doll_at = path[m.doll_i]
		m.doll_i += 1
	else:
		m.doll_at += to / to.length() * step
	m.doll_t += dt
	if m.doll_t >= 0.25:
		m.doll_t = 0.0
		m.sfx(1400, 0.03, "square", 0.05)
	m.castle.doll_place(m.doll_at, to)
	m.castle.doll.rotation.z = 0.1 if fmod(m.t, 0.5) < 0.25 else -0.1

# the next step inside the quarters (GPT playtest 2026-10-24: the quest line stays on the main road, so it was hard to
# find): a gold "!" bobs over the tally board until read, the winding stand until wound, the doorkeeper while he stands
# stopped, the ledger once the bunk room is open; nothing before the door opens or after he rests
func quarters_target() -> Vector3:
	if m.castle == null or not in_castle():
		return Vector3.INF
	var mk: Dictionary = m.castle.marks
	match m.quarters_q:
		2:
			return Vector3(mk.k.x, 2.5, mk.k.y) if m.tally_seen else Vector3(mk.m.x, 2.3, mk.m.y)
		3:
			return Vector3.INF if m.doll_walk else Vector3(m.doll_at.x, 2.4, m.doll_at.y)
		4:
			return Vector3(mk.o.x, 1.9, mk.o.y)
	return Vector3.INF

# the shared gold "!": the quarters' steps, else the lamp hall's next lamp, else the cave mouth after the Brick King
func step_target() -> Vector3:
	var at := quarters_target()
	if at == Vector3.INF:
		at = under_target()
	if at == Vector3.INF and m.story_step == 5 and m.cave_pos.x > 0 and m.in_marsh() and not m.intro:
		at = Vector3(m.cave_pos.x, 1.5, m.cave_pos.y + 0.6) # over the steps, nearer the camera's focus
	if at == Vector3.INF:
		at = folk_target()
	return at

# who the quest line or the side line sends Sora to (the owner, 2026-10-26: "가져가야할 아이템이나 미션이 있으면 해당 물체
# 위에 느낌표", walking past Mulgyeol on "물결에게 가 보자"): the gold "!" over that villager in the village, or over
# Bori's cottage in the marsh; not while a story box is open, and only within 30 tiles
const MARK_FOLK := ["도란", "콩알", "물결", "두솔", "차돌", "새참", "여울", "다래", "토리"]

func folk_target() -> Vector3:
	if m.intro or m.story_open:
		return Vector3.INF
	var lines: String = m.quest_raw + " " + m.errands.letter_side_line()
	var me := Vector2(m.player.x, m.player.z)
	if m.in_village:
		for name in MARK_FOLK:
			if not lines.contains(name + "에게") and not lines.contains(name + "을") and not lines.contains(name + "를"):
				continue
			var id: String = m.folk.FOLK_NAME.find_key(name)
			var p: Vector2 = m.folk.folk_talk_at(id)
			if p.x != INF and p.distance_to(me) < 30.0:
				return Vector3(p.x, m.folk_height(id) / cos(0.78) + 0.7, p.y)
	if m.in_marsh() and lines.contains("보리") and m.cottage_at.x >= 0.0 and m.cottage_at.distance_to(me) < 30.0:
		return Vector3(m.cottage_at.x, 3.4, m.cottage_at.y)
	return Vector3.INF

func update_quarters_mark() -> void:
	var at := step_target()
	if at == Vector3.INF:
		if m.quarters_mark != null:
			m.quarters_mark.visible = false
		return
	if m.quarters_mark == null:
		m.quarters_mark = Label3D.new()
		m.quarters_mark.text = "!"
		m.quarters_mark.font = m.ui_font
		m.quarters_mark.font_size = 72
		m.quarters_mark.pixel_size = 0.012 # about 0.85 m tall, readable from the fixed camera
		m.quarters_mark.outline_size = 16
		m.quarters_mark.modulate = Color("#ffd84a")
		m.quarters_mark.outline_modulate = Color("#3a2a10")
		m.quarters_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.quarters_mark.no_depth_test = true
		m.add_child(m.quarters_mark)
	m.quarters_mark.visible = true
	m.quarters_mark.position = at + Vector3(0, sin(m.t * 3.0) * 0.12, 0)

# at the bunk room door: his key hand opens it and he walks to his chair
func doll_at_door() -> void:
	m.castle.open_bunk()
	m.quarters_q = 4
	m.doll_walk = false
	var n: Vector2 = m.castle.marks.n
	m.burst(Vector3(n.x, 0.7, n.y), Color("#c8962a"), 16, 1.5)
	m.sfx(392, 0.3, "triangle", 0.2)
	m.ui.mini.map_tex = castle_map()
	m.doll_at = Vector2(463, 36)
	m.show_story("", Main.STORY.QUARTERS_BUNK)
	m.after_story = func():
		var dl: Node3D = m.castle.doll
		var tw := m.create_tween()
		tw.tween_property(dl, "position", Vector3(n.x, 0, n.y + 1.0), 0.7)
		tw.tween_property(dl, "position", Vector3(463, 0, 36), 0.9)
		tw.tween_callback(func(): dl.rotation.y = 0.0)
		m.toast("문 곁 장부를 보자 (E)")
	m.save_game()

# after the ledger: he sits in his chair, the buckler held out (a new round: a wave of the key hand)
func quarters_sit() -> void:
	var give := not m.quarters_again
	m.castle.ledger_name.visible = true
	m.castle.doll_sit(give)
	m.doll_at = m.castle.marks.h
	m.quarters_q = 5
	m.has_buckler = true
	var lines: Array = Main.STORY.QUARTERS_REST.duplicate()
	if not give:
		lines[0] = Main.STORY.QUARTERS_REST_AGAIN
	m.show_story("", lines)
	m.after_story = quarters_hush.bind(give)
	m.save_game()

# 1.6 s of only the chair's creak and his slowing clockwork, then the buckler's numbers as a toast (GPT's note)
func quarters_hush(give: bool) -> void:
	m.castle.doll_rest_eye(m)
	m.sfx(200, 0.35, "triangle", 0.1, -60)
	for k in 4:
		m.get_tree().create_timer(0.3 + 0.35 * k).timeout.connect(func(): m.sfx(1300 - k * 150, 0.03, "square", 0.045 - k * 0.008))
	if give:
		m.get_tree().create_timer(1.6).timeout.connect(func(): m.toast("작은 놋 방패를 얻었다. 섬광 막기를 조금 늦게 눌러도 된다 (0.12초 → 0.16초)"))

func open_quarters_box() -> void:
	m.quarters_box = true
	m.castle.quarters_chest_look(true)
	if m.quarters_again: # a new round: the buckler came along
		m.player.pots += 1
		m.player.gold += 40
		m.show_story("", Main.STORY.QUARTERS_BOX_AGAIN)
	else:
		m.player.max_hp += QUARTERS_HP
		m.player.hp = minf(float(m.player.max_hp), m.player.hp + QUARTERS_HP)
		m.player.pots += 2
		m.player.gold += 80
		m.show_story("", Main.STORY.QUARTERS_BOX)
	var c: Vector2 = m.castle.marks.c
	m.burst(Vector3(c.x, 0.6, c.y), Color("#f2ead8"), 24, 2.0)
	m.sfx(784, 0.12, "triangle", 0.25)
	m.ui.mini.map_tex = castle_map()
	m.save_game()

func quarters_journal() -> String:
	match m.quarters_q:
		0: return tr("기사 자리의 녹슨 태엽 (E)")
		1: return tr("옥좌의 방 남쪽 태엽 문 (E)")
		2: return tr("일방의 태엽대")
		3: return tr("깡통 문지기를 침방까지")
		4: return tr("침방 문 곁의 장부 (E)")
	return tr("끝") if m.quarters_box else tr("침방 끝 궤짝")

# load the quarters (old saves: nothing done yet, the spring where the knight knelt); a walk in progress stops
func load_quarters(d: Dictionary) -> void:
	m.quarters_q = int(d.get("quarters_q", 0))
	m.quarters_box = bool(d.get("quarters_box", false))
	m.has_buckler = bool(d.get("has_buckler", false))
	m.quarters_again = bool(d.get("quarters_again", m.has_buckler and m.quarters_q < 5))
	clear_quarters_job()
	m.doll_at = Main.CASTLE.DOLL_PATH[0]
	m.doll_i = 1
	if m.quarters_q == 4:
		m.doll_at = Vector2(463, 36)
	elif m.quarters_q >= 5:
		m.doll_at = m.castle.marks.h
	m.castle.quarters_look(m.quarters_q, m.castle_q >= 3 and m.quarters_q == 0, m.quarters_box)

func in_under() -> bool:
	return m.in_hill and m.player.x >= Main.UNDER.UNDER_X - 0.5 and m.player.x < Main.VILLAGE.VILLAGE_X - 0.5

# the moon door shuts behind her while the guardians stand and she is in Hangyeol's room
func under_shut() -> bool:
	return not m.under_guards.is_empty() and m.player.z < 12.6 and m.player.x >= Main.UNDER.UNDER_X - 0.5

func chest_sprite(at: Vector2, tint: Color) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = m.chest_shut_tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.scale = Vector3(1, 1.0 / cos(0.78), 1)
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = false
	s.pixel_size = 0.05
	s.offset = Vector2(0, 7)
	s.modulate = tint
	s.position = Vector3(at.x, 0.0, at.y)
	m.add_child(s)
	return s

# a dark square in the great hall's floor with three pale steps going down
func build_under_stair() -> void:
	var hole := m.box(Vector3(1.0, 0.04, 1.0), m.mat_color(Color("#16121e")))
	hole.position = Vector3(Main.UNDER_STAIR.x, 0.01, Main.UNDER_STAIR.y)
	m.add_child(hole)
	for k in 3:
		var st := m.box(Vector3(0.8, 0.05, 0.22), m.mat_color(Color("#b8b4c4").darkened(k * 0.25)))
		st.position = Vector3(Main.UNDER_STAIR.x, 0.04 - k * 0.01, Main.UNDER_STAIR.y - 0.3 + k * 0.26)
		m.add_child(st)
	var rim := m.box(Vector3(1.2, 0.08, 0.12), m.mat_color(Color("#8a8494")))
	rim.position = Vector3(Main.UNDER_STAIR.x, 0.04, Main.UNDER_STAIR.y - 0.56)
	m.add_child(rim)

func enter_under() -> void:
	clear_quarters_job()
	m.in_hill = true
	m.in_garden = false
	m.player.x = m.under.marks.S.x + 1.2
	m.player.z = m.under.marks.S.y + 0.6
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = m.world_build.under_map()
	m.ui.zone_name.text = "성 아래 잠긴 층"
	m.ui.zone_sub.text = "물에 잠긴 옛 창고"
	m.snap_mates()
	if not m.under_spawned:
		m.under_spawned = true
		for f in m.under.foes:
			match f[1]:
				"w": m.spawn_wolf(f[0])
				"b": m.spawn_bat(f[0])
				_:
					m.spawn_enemy(f[0], f[1] == "a")
					m.enemies[m.enemies.size() - 1].cave = true
					if f[1] == "s":
						m.give_shield(m.enemies[m.enemies.size() - 1])
		if not m.under_chest_open:
			m.show_story("", Main.STORY.UNDER_IN)
	m.save_game()

func leave_under(to_castle := true) -> void:
	under_guards_clear()
	m.player.x = Main.UNDER_STAIR.x + 1.2
	m.player.z = Main.UNDER_STAIR.y
	m.ground_y = 0.0
	m.gust_dir = Vector2.ZERO
	m.ui.mini.map_tex = castle_map()
	m.ui.zone_name.text = "가라앉은 달지기 성"
	m.ui.zone_sub.text = "큰 방"
	m.snap_mates()
	m.save_game()

# side stories keep the quest line on the main road, so the lamp trial says its goal in a longer toast
func under_goal_toast(hold := 4.0) -> void:
	m.toast("마개가 풀리고 물이 빠졌다. 물빛 등불 넷을 8초 안에 켜자")
	m.toast_t = hold

# the gold "!" in the lamp hall: over the unlit lamp nearest Sora while the trial is open
func under_target() -> Vector3:
	if m.under == null or not in_under() or not m.under.drained or m.under.door_open:
		return Vector3.INF
	var me := Vector2(m.player.x, m.player.z)
	var best := Vector3.INF
	var bd := INF
	for l in m.under.lamps:
		if not l.lit and me.distance_to(l.pos) < bd:
			bd = me.distance_to(l.pos)
			best = Vector3(l.pos.x, 2.75, l.pos.y)
	return best

func under_journal() -> String:
	if m.under_chest_open:
		return tr("끝")
	if m.under_guards_done:
		return tr("한결의 상자를 열자")
	if m.under.door_open:
		return tr("한결의 방의 수호자 둘")
	if m.under.drained:
		return tr("물빛 등불 넷을 8초 안에 (%d/4)") % m.under.lamps_lit()
	return tr("큰 방 바닥의 계단으로. 북쪽 벽의 벽돌 마개")

# Hangyeol's room: west of the flooded hall (rows 8 - 11, columns 1 - 8); the east drain up to the hall is outside it
func in_hangyeol_room(p: Vector2) -> bool:
	return p.y < 12.4 and p.y > 7.5 and p.x < Main.UNDER.UNDER_X + 8.6

func under_diary_lines() -> Array:
	var dl: Array = Main.STORY.UNDER_DIARY.duplicate()
	if m.castle.pages_read() < 3: # the hand is compared with the castle's three pages only once they are read
		dl[0] = Main.STORY.UNDER_DIARY_FIRST
	return dl

func update_under(dt: float) -> void:
	var me := Vector2(m.player.x, m.player.z)
	if m.gust_dir == Vector2.ZERO and me.distance_to(m.under.marks.S) < 0.6:
		m.fade_then(leave_under)
		return
	if m.under_chest_open and m.gust_dir == Vector2.ZERO and me.distance_to(m.under.marks.U) < 0.6:
		m.fade_then(leave_under)
		return
	# the lamp clock: from the first lamp lit, the rest must burn within 8 s or all go out
	if not m.under.door_open and m.under.lamp_clock > 0.0:
		m.under.lamp_clock -= dt
		if m.under.lamp_clock <= 0.0:
			for l in m.under.lamps:
				m.under.put_out(l)
			m.sfx(180, 0.4, "triangle", 0.2, -80)
			m.toast("물빛 등불이 모두 꺼졌다. 첫 등불부터 8초 안에")
			m.ui.mini.map_tex = m.world_build.under_map()
	# Hangyeol's room: two big guardians rise when she steps in; the door shuts behind her until both fall
	if m.under.door_open and not m.under_guards_done and m.under_guards.is_empty() and in_hangyeol_room(me):
		for at in m.under.guard_spots:
			m.spawn_enemy(at)
			var e: Dictionary = m.enemies[m.enemies.size() - 1]
			e.cave = true
			e.hp = 300.0 + m.foe_lv() * 30
			e.max_hp = int(e.hp)
			e.size_k = 1.7
			var mats: Array = e.node.get_meta("mats")
			mats[2].albedo_color = Color("#5a6470")
			mats[5].albedo_color = Color("#bfe6ff")
			e.atk_cd = 1.5
			m.under_guards.append(e)
			m.burst(Vector3(at.x, 0.6, at.y), Color("#bfe6ff"), 20, 2.5)
		m.under.door.visible = true
		m.shake = 0.3
		m.sfx(110, 0.4, "square", 0.25, 60)
		m.toast("문이 닫히고, 큰 수호자 둘이 일어선다")
	if not m.under_guards.is_empty():
		if m.under_guards.all(func(e): return e.dead):
			m.under_guards = []
			m.under_guards_done = true
			m.under.door.visible = false
			m.player.gold += 200
			m.gain_xp(250)
			m.sfx(660, 0.4, "triangle", 0.25, 200)
			m.toast("수호자들이 무너졌다. 금화 +200")
			m.ui.mini.map_tex = m.world_build.under_map()
			m.save_game()
		elif me.y > 13.4: # she got out (a faint, a waystone): the guardians go back to sleep and the fight starts over
			under_guards_clear()

func under_guards_clear() -> void:
	for e in m.under_guards:
		if not e.dead:
			e.dead = true
			e.respawn = 9999.0
			e.node.queue_free()
			e.shadow.queue_free()
	m.under_guards = []
	if m.under.door_open:
		m.under.door.visible = false

func open_under_chest_look() -> void:
	m.under_chest_open = true
	m.under.chest.texture = m.chest_open_tex
	m.under.chest.modulate = Color.WHITE

func under_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if not m.under.drained:
		for n in m.under.plug_nodes:
			if me.distance_to(Vector2(n.position.x, n.position.z)) < 1.8:
				if not m.has_unbrick:
					m.toast("벽돌로 굳은 마개다. 아직 풀 힘이 없다")
					return true
				if not m.spend_pips(m.unbrick_cost()):
					return true
				m.under.drain()
				m.burst(Vector3(n.position.x, 0.7, n.position.z), Color("#8a6a4a"), 36, 3.5)
				m.burst(Vector3(Main.UNDER.UNDER_X + 19.5, 0.3, 9.5), Color("#9fd4ff"), 40, 4.0)
				m.shake = 0.3
				m.sfx(150, 0.8, "noise", 0.2, -60)
				under_goal_toast()
				m.ui.mini.map_tex = m.world_build.under_map()
				m.save_game()
				return true
	if not m.under.door_open:
		for l in m.under.lamps:
			if not l.lit and me.distance_to(l.pos) < 1.6:
				if m.under.lamps_lit() == 0:
					m.under.lamp_clock = Main.UNDER.LAMP_TIME
				m.under.light(l)
				m.burst(Vector3(l.pos.x, 1.8, l.pos.y), Color("#bfe6ff"), 20, 2.0)
				m.sfx(523 + m.under.lamps_lit() * 120, 0.25, "triangle", 0.22)
				if m.under.lamps_lit() == m.under.lamps.size():
					m.under.open_door()
					m.shake = 0.3
					m.toast("네 등불이 함께 타오르자, 달 문이 열렸다")
					m.ui.mini.map_tex = m.world_build.under_map()
					m.save_game()
				else:
					m.toast(tr("물빛 등불 %d/4 · %.0f초") % [m.under.lamps_lit(), maxf(m.under.lamp_clock, 0.0)])
				return true
	if not m.under_diary_read and me.distance_to(m.under.marks.j) < 1.4:
		m.under_diary_read = true
		m.show_story("", under_diary_lines())
		m.save_game()
		return true
	if not m.under_chest_open and me.distance_to(m.under.marks.c) < 1.5:
		if not m.under_guards_done:
			m.toast("수호자들이 상자를 지키고 있다")
			return true
		open_under_chest_look()
		m.has_lamp = true
		m.player.max_hp += 20
		m.player.hp = m.player.max_hp
		m.player.atk += 3
		m.burst(m.under.chest.position + Vector3(0, 0.8, 0), Color("#ffe6a0"), 40, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.show_story("", Main.STORY.UNDER_CHEST)
		m.save_game()
		return true
	if not m.under_side_open and me.distance_to(m.under.marks.p) < 1.5:
		m.under_side_open = true
		m.under.side_chest.texture = m.chest_open_tex
		m.under.side_chest.modulate = Color.WHITE
		m.player.pots += 2
		m.player.gold += 60
		m.burst(m.under.side_chest.position + Vector3(0, 0.8, 0), Color("#e8c050"), 24, 2.5)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.toast("회복약 2개와 금화 60을 찾았다")
		m.save_game()
		return true
	return false
