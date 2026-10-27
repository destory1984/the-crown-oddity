# Garden: the heart, Hangyeol's road, the mold boss, the clock room, workers, winding.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const CLOCK_BEAT := 1.2       # seconds a beat ring takes to close from 3.0 to 0.6 tiles
const CLOCK_WINDOW := 1.1     # E counts while the ring is inside this radius (its last 0.25 s)

func _init(main: Main) -> void:
	m = main

func enter_garden() -> void:
	m.in_forest = false
	m.in_hill = false
	m.in_garden = true
	m.story_step = maxi(m.story_step, 11)
	if m.garden_q >= 1 or m.road_q >= 4: # the arena reached before, or Hangyeol's yard behind her: the yard stays open
		m.garden.open_roots()
		m.garden.open_gate()
		m.garden.reveal(true)
	elif m.road_q >= 2:
		m.garden.open_roots()
	m.ground_y = 0.0
	m.garden.clock_view(false)
	m.ui.mini.map_tex = garden_map()
	if m.garden_q == 0 and m.road_q < 4: # in at the yard below, by the stairs' top
		m.player.x = m.garden.road_marks.A.x + 1.5
		m.player.z = m.garden.road_marks.A.y
		m.ui.zone_name.text = "한결의 마지막 길"
		m.ui.zone_sub.text = "무너진 뜰"
		spawn_road()
		m.monsters.refill_field("garden") # a later visit: the yard's beaten foes are back
		if m.road_q == 0:
			m.road_q = 1
			m.show_story("", Main.STORY.ROAD_IN)
		m.set_quest(road_quest())
		m.save_game()
		return
	m.player.x = m.garden.marks.S.x + 1.5
	m.player.z = m.garden.marks.S.y
	m.ui.zone_name.text = "정원 한가운데"
	m.ui.zone_sub.text = "굳은달 빈터" # the arrival scene now comes in update_garden, the first time she stands in the arena
	if m.garden_q >= 1 and m.garden_q < 5:
		if m.garden.seals_open() < m.garden.seals.size():
			m.set_quest(tr("거푸집 둘레의 벽돌 봉인을 풀자 (E) %d/3") % m.garden.seals_open())
		else:
			m.set_quest("굳은달 거푸집의 심장을 노리자")
	if m.garden_q >= 5:
		m.garden.set_posts(8)
	m.monsters.refill_field("garden")
	m.save_game()

# after the ending: the clock room first, step by step, then the second round (the owner, 2026-10-28)
func clock_quest() -> String:
	match m.clock_q:
		0, 1: return "이야기 끝 · 정원 한가운데 구멍으로 내려가 시계방에 가 보자"
		2: return tr("시계방의 굳은 톱니를 팔찌로 풀자 (E) %d/3") % m.clock_gears.count(true)
		3: return "태엽 열쇠 한가운데에 팔찌를 대자 (E)"
		4: return "한결의 손잡이에서 박자에 맞춰 다 같이 밀자 (E)"
	return "이야기 끝 · 정원을 마음껏 둘러보자 (정원 한가운데 태엽에서 E 두 번: 2회차)"

func road_quest() -> String:
	match m.road_q:
		1: return "뿌리 벽돌을 팔찌로 풀자 (E)"
		2: return "한결의 야영터를 살펴보자"
		3: return "깊은 틈 위 한결의 발자국을 따라가자 (E로 비추기)"
	return "회색 문을 지나 빈터로 가자"

func spawn_road() -> void:
	if m.road_spawned or m.road_q >= 4:
		return
	m.road_spawned = true
	m.monsters.refill_field("garden")

func road_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if me.y < Main.GARDEN.ROAD_Z - 0.5:
		return false
	if not m.garden.roots_open:
		for r in m.garden.roots:
			if me.distance_to(r[0]) < 1.6:
				if not m.spend_pips(m.unbrick_cost()):
					return true
				m.garden.open_roots()
				m.ui.mini.map_tex = garden_map()
				m.burst(Vector3(r[0].x, 0.7, r[0].y), Color("#9a4ad8"), 36, 3.5)
				m.shake = 0.25
				m.sfx(196, 0.5, "triangle", 0.3, -60)
				for k in 2: # like a seal: two goblins break out of the roots
					m.spawn_enemy(r[0] + Vector2(m.rnd(1.0, 2.0), m.rnd(-1.0, 1.0)))
				m.road_q = maxi(m.road_q, 2)
				m.set_quest(road_quest())
				m.toast("뿌리 벽돌이 흙으로 풀렸다")
				m.save_game()
				return true
	if me.distance_to(m.garden.road_marks.k) < 1.6:
		m.show_story("", Main.STORY.ROAD_HOOK13 if m.hollow_q >= 3 else Main.STORY.ROAD_HOOK)
		return true
	if me.distance_to(m.garden.road_marks.j) < 1.6:
		m.show_story("", m.road_page_lines())
		if m.road_q < 3:
			m.road_q = 3
			m.set_quest(road_quest())
			m.save_game()
		return true
	if not m.road_box and me.distance_to(m.garden.road_marks.c) < 1.6:
		m.road_box = true
		m.garden.blanket_look()
		m.player.pots += 2
		m.player.max_hp += 10
		m.player.hp = float(m.player.max_hp)
		m.burst(Vector3(m.garden.road_marks.c.x, 0.6, m.garden.road_marks.c.y), Color("#e8d27a"), 30, 2.5)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.show_story("", Main.STORY.ROAD_BLANKET)
		m.save_game()
		return true
	if me.x > Main.GARDEN.GARDEN_X + 11.5 and me.x < Main.GARDEN.GARDEN_X + 21.5 and me.y > 26.5 and me.y < 32.5: # by the gap: the crown shows his steps for 3 s
		m.garden.reveal_t = 3.0
		m.garden.reveal(true)
		m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#bfe6ff"), 14, 1.5)
		m.sfx(988, 0.3, "sine", 0.18)
		return true
	return false

func update_road(dt: float) -> void:
	var me := Vector2(m.player.x, m.player.z)
	if m.garden.reveal_t > 0.0:
		m.garden.reveal_t -= dt
		if m.garden.reveal_t <= 0.0 and not (m.road_q >= 4 or m.garden_q >= 1):
			m.garden.reveal(false)
	if m.garden_q == 0 and me.y < Main.GARDEN.ROAD_Z - 0.5 and not m.story_open: # first steps into the arena
		m.garden_q = 1
		m.show_story("", Main.STORY.GARDEN_IN)
		m.set_quest(tr("거푸집 둘레의 벽돌 봉인을 풀자 (E) %d/3") % m.garden.seals_open())
		m.ui.zone_name.text = "정원 한가운데"
		m.ui.zone_sub.text = "굳은달 빈터"
		m.save_game()
		return
	if me.y < Main.GARDEN.ROAD_Z - 0.5:
		return
	m.ui.zone_sub.text = "한결의 야영터" if me.x > Main.GARDEN.GARDEN_X + 16.5 else "무너진 뜰"
	if m.fade_rect.color.a == 0.0 and m.garden.char_at(me.x, me.y) == ",": # off his steps: down the gap and back up
		m.player.x = Main.GARDEN.GARDEN_X + 19.0
		m.player.z = 32.0
		m.hurt_player(8, 0.0)
		m.burst(Vector3(m.player.x, 0.5, m.player.z), Color("#ffffff"), 20, 2.5)
		m.toast("발을 헛디뎌 틈 아래로 떨어졌다가 기어 올라왔다")
		return
	if m.fade_rect.color.a == 0.0 and me.distance_to(m.garden.road_marks.A) < 0.9:
		m.fade_then(leave_garden)
		return
	if m.story_open:
		return
	if m.road_q == 2 and not m.road_camp_told and me.x > Main.GARDEN.GARDEN_X + 16.5:
		m.road_camp_told = true
		m.show_story("", Main.STORY.ROAD_CAMP)
		return
	if m.road_q == 3 and me.y > 21.5 and me.y < 26.5 and me.x > Main.GARDEN.GARDEN_X + 8.5 and me.x < Main.GARDEN.GARDEN_X + 18.5 \
			and not m.enemies.any(func(e): return e.get("echo", false)): # a downed one too, for the second before road_q moves on
		m.show_story("", road_echo_lines())
		m.after_story = m.spawn_knight.bind(true)

# Mulgyeol recalls the fifth house's painting only if she opened it (house_seen[4]); else a first look (GPT playtest 5)
func road_echo_lines() -> Array:
	var lines: Array = Main.STORY.ROAD_ECHO.duplicate()
	if not m.house_seen[4]:
		lines[1] = Main.STORY.ROAD_ECHO_FIRST
	return lines

func echo_beaten() -> void:
	m.road_q = 4
	m.garden.open_gate()
	m.garden.reveal(true)
	m.ui.mini.map_tex = garden_map()
	m.ui.boss.visible = false
	m.player.gold += 100
	m.gain_xp(200)
	m.show_story("", Main.STORY.ROAD_ECHO_DOWN)
	m.set_quest(road_quest())
	m.save_game()

func leave_garden() -> void:
	if not m.castle.door_open: # a save from before the castle: open the way back west
		for pg in m.castle.pages:
			pg.read = true
		m.castle.open_door()
		m.castle.open_gate()
	m.in_garden = false
	m.in_hill = true
	if not m.stairs.door_open: # an older save that went straight from the castle: the climb is already behind her
		m.open_stairs()
	m.player.x = m.stairs.marks.N.x
	m.player.z = m.stairs.marks.N.y + 1.3
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.stairs.map_tex(Main.STAIRS.STAIRS_X + Main.STAIRS.W)
	m.ui.zone_name.text = "달의 계단"
	m.ui.zone_sub.text = "꼭대기"
	m.snap_mates()
	m.ui.boss.visible = false
	m.monsters.refill_field("stairs")
	m.save_game()

func update_garden(dt: float) -> void:
	if in_clock():
		update_clock(dt)
		return
	m.garden.show_bloom(m.garden_q >= 5) # the garden turns again: grass and flowers on the arena
	var me := Vector2(m.player.x, m.player.z)
	if m.clock_q >= 1 and not m.story_open and m.fade_rect.color.a == 0.0 and me.distance_to(m.garden.marks.C) < 0.9:
		m.fade_then(enter_clock)
		return
	if m.clock_q == 1 and not m.clock_hint_told and not m.story_open and me.y < Main.GARDEN.ROAD_Z - 0.5:
		m.clock_hint_told = true
		m.toast("거푸집이 있던 자리에 둥근 구멍이 열려 있다")
	update_road(dt)
	if m.garden_q == 1 and not m.story_open and m.garden.seals_open() == m.garden.seals.size() and Vector2(m.player.x, m.player.z).distance_to(m.garden.marks.C) < 8.0:
		m.garden_q = 2
		spawn_mold()
		m.set_quest("굳은달 거푸집의 심장을 노리자")
	if not m.mold_wave.is_empty():
		update_mold_wave(dt)
	update_ring(dt)

# E beside a seal: one pip unwinds it (the heart is near, so the crown is strong), and two goblins break out
func seal_key() -> bool:
	for sl in m.garden.seals:
		if not sl.open and Vector2(m.player.x, m.player.z).distance_to(sl.pos) < 1.6:
			if not m.spend_pips(1):
				return true
			m.garden.open_seal(sl)
			m.burst(Vector3(sl.pos.x, 0.8, sl.pos.y), Color("#9a4ad8"), 30, 3.5)
			m.shake = 0.25
			m.sfx(150, 0.5, "triangle", 0.3, -40)
			for k in 2:
				m.spawn_enemy(sl.pos + Vector2(m.rnd(-1.5, 1.5), m.rnd(-1.5, 1.5)))
				m.enemies[m.enemies.size() - 1].cave = true
			var n: int = m.garden.seals_open()
			if n == m.garden.seals.size():
				m.toast("마지막 봉인이 풀렸다. 거푸집이 깨어난다")
				m.set_quest("굳은달 거푸집의 심장을 노리자")
			else:
				m.toast(tr("벽돌 봉인 %d/3") % n)
				m.set_quest(tr("거푸집 둘레의 벽돌 봉인을 풀자 (E) %d/3") % n)
			m.save_game()
			return true
	return false

func spawn_mold() -> void:
	if m.enemies.any(func(e): return e.get("mold", false) and not e.dead):
		return
	var c: Vector2 = m.garden.marks.C
	var node: Node3D = m.garden.mold(m)
	m.enemies.append({"x": c.x, "z": c.y, "hp": 1700.0, "max_hp": 1700, "node": node, "shadow": m.blob(2.2), "t": 0.0,
		"atk_cd": 2.5, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": c.x, "wz": c.y, "dead": false, "respawn": 0.0,
		"mold": true, "cave": true, "wind": 0.0, "stun": 0.0, "next": 0, "rings": [], "locked": false})

# a faint mid-fight: everything the fight left goes, so walking back in wakes a fresh mold and a dark ring.
# The shock ring and the posts' pips used to stay (the ring hung frozen and rolled on at her when she came back)
func mold_retry() -> void:
	if m.garden_q >= 3:
		m.crown_pips = 0 # the pips were the lit posts'
	m.garden_q = 1
	m.garden.set_posts(0)
	m.ring_k = -1
	m.ring_t = 0.0
	if not m.mold_wave.is_empty():
		m.mold_wave.node.queue_free()
		m.mold_wave = {}
	for e in m.enemies:
		if not e.dead and (e.get("mold", false) or e.get("shard", false) or e.get("echo", false) or (in_garden_x(e.x) and e.z < Main.GARDEN.ROAD_Z - 0.5 and e.get("cave", false))):
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()

func mold_phase(e: Dictionary) -> int:
	var f: float = e.hp / e.max_hp
	return 1 if f > 0.66 else (2 if f > 0.33 else 3)

# the mold: drifts toward Sora; slams rings of brick (1, 3, 5 by phase), sends a shock ring out (phase 2+),
# and wakes goblins (every third move). At 12% it locks and the last wind begins.
func update_mold(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	if not m.in_garden: # she walked out mid-fight: it waits (it used to slam rings at her feet on the stairs)
		return
	m.ui.boss.visible = true
	m.ui.boss_name.text = "굳은달 거푸집"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	var crescent: Node3D = node.get_node("crescent")
	crescent.rotation.y += dt * (0.4 + 0.3 * mold_phase(e))
	var heart: MeshInstance3D = node.get_node("heart")
	heart.position.y = 1.0 + sin(e.t * 3.0) * 0.15
	heart.scale = Vector3.ONE * (1.3 if e.hurt > 0.0 else 1.0)
	if e.locked:
		node.position = Vector3(e.x, 0, e.z)
		return
	if e.hp <= e.max_hp * 0.12 and m.garden_q == 2:
		mold_locks(e)
		return
	var ph := mold_phase(e)
	if e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			for r in e.rings:
				m.burst(Vector3(r.x, 0.3, r.y), Color("#8a8a96"), 18, 3.0)
				if Vector2(m.player.x, m.player.z).distance_to(r) < 1.3:
					m.player_hit(18 + 4 * ph, r, e)
			m.shake = 0.2
			m.sfx(70, 0.3, "square", 0.25, -30)
			e.atk_cd = 2.0 - 0.4 * ph
	else:
		e.atk_cd -= dt
		if e.atk_cd <= 0.0:
			e.next = int(e.next) + 1
			if int(e.next) % 3 == 0 and m.enemies.filter(func(g): return not g.dead and in_garden_x(g.x) and not g.get("mold", false)).size() < 4:
				for k in 2: # wakes two goblins at the arena's edge
					var a := m.rnd(0, TAU)
					m.spawn_enemy(m.garden.marks.C + Vector2(cos(a), sin(a)) * 7.0)
					m.enemies[m.enemies.size() - 1].cave = true
				e.atk_cd = 1.5
			elif ph >= 2 and int(e.next) % 3 == 1 and m.mold_wave.is_empty():
				start_mold_wave(e)
				e.atk_cd = 2.4
			else:
				e.wind = 0.9
				e.rings = [Vector2(m.player.x, m.player.z)]
				for k in (ph - 1) * 2:
					e.rings.append(Vector2(m.player.x, m.player.z) + Vector2(m.rnd(-3, 3), m.rnd(-3, 3)))
				for r in e.rings:
					m.warn_ring(Vector3(r.x, 0.0, r.y), 1.3, 0.9)
		elif d > 1.3: # drifts after Sora, slowly
			var nx: float = e.x + to.x / d * 0.9 * dt
			var nz: float = e.z + to.y / d * 0.9 * dt
			if Vector2(nx, nz).distance_to(m.garden.marks.C) < 5.0:
				e.x = nx
				e.z = nz
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

# a ring of grey force rolls outward from the mold; dodge through it (the flash dodge works) or be hit
func start_mold_wave(e: Dictionary) -> void:
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.85
	tor.outer_radius = 1.0
	ring.mesh = tor
	ring.material_override = m.glow_mat(Color("#b48cff"), 2.0)
	ring.position = Vector3(e.x, 0.2, e.z)
	m.add_child(ring)
	m.mold_wave = {"r": 0.5, "node": ring, "c": Vector2(e.x, e.z), "hit": false}
	m.pop_num(Vector3(e.x, 3.0, e.z), "!", Color("#ff5a4a"))
	m.sfx(110, 0.6, "sawtooth", 0.25, 200)

func update_mold_wave(dt: float) -> void:
	m.mold_wave.r += dt * 5.0
	var ring: MeshInstance3D = m.mold_wave.node
	ring.scale = Vector3(m.mold_wave.r, 1.0, m.mold_wave.r)
	var pd: float = Vector2(m.player.x, m.player.z).distance_to(m.mold_wave.c)
	if not m.mold_wave.hit and absf(pd - m.mold_wave.r) < 0.45:
		m.mold_wave.hit = true
		var e: Dictionary = {} if m.enemies.is_empty() else m.enemies.filter(func(mm): return mm.get("mold", false))[0]
		m.player_hit(22, m.mold_wave.c, e)
	if m.mold_wave.r > 10.0:
		ring.queue_free()
		m.mold_wave = {}

func in_garden_x(x: float) -> bool:
	return x >= Main.GARDEN.GARDEN_X - 0.5 and x < Main.GARDEN.GARDEN_X + Main.GARDEN.W

func mold_locks(e: Dictionary) -> void:
	e.locked = true
	m.garden_q = 3
	m.crown_pips = 0
	m.pip_flash = 0.5
	for g in m.enemies:
		if not g.dead and in_garden_x(g.x) and not g.get("mold", false):
			g.dead = true
			g.node.visible = false
			g.shadow.visible = false
	m.show_story("", Main.STORY.FINAL_SHORT)
	m.after_story = light_ring
	m.save_game()

# the villagers light the ring posts one by one, each filling one pip. For every post the locked mold
# sheds two grey shards that run for that post; a shard that reaches it snuffs the flame and the post
# starts over. A post lights once its shards are cut down and at least 1.5 s have passed.
func light_ring() -> void:
	m.ring_k = 0
	m.ring_t = 0.0
	m.set_quest("마을 사람들이 등불을 켜는 동안 거푸집 조각을 막자 0/8")
	shed_shards()

func shed_shards() -> void:
	var c: Vector2 = m.garden.marks.C
	var l: OmniLight3D = m.garden.posts[m.ring_k]
	for k in 2:
		var at := c + Vector2(m.rnd(-1.5, 1.5), m.rnd(-1.5, 1.5))
		m.spawn_enemy(at)
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.shard = true
		e.cave = true # no respawn
		e.hp = 18.0 + m.foe_lv() * 4
		e.max_hp = int(e.hp)
		e.post = Vector2(l.position.x, l.position.z)
		var mats: Array = e.node.get_meta("mats")
		for mm in mats:
			mm.albedo_color = Color("#8a8a96").lightened(m.rnd(0, 0.15))
		m.burst(Vector3(at.x, 1.0, at.y), Color("#8a8a96"), 10, 2.0)
	m.sfx(110, 0.3, "square", 0.15, -30)

func update_ring(dt: float) -> void:
	if m.ring_k < 0 or m.garden_q != 3 or m.story_open:
		return
	m.ring_t += dt
	var alive := m.enemies.filter(func(e): return e.get("shard", false) and not e.dead)
	if alive.is_empty() and m.ring_t >= 1.5:
		m.garden.set_posts(m.ring_k + 1)
		m.crown_pips = m.ring_k + 1
		m.pip_flash = 0.3
		var l: OmniLight3D = m.garden.posts[m.ring_k]
		m.burst(l.position, Color("#ffc46a"), 16, 2.0)
		m.sfx(392 + 40 * m.ring_k, 0.25, "sine", 0.2)
		m.ring_k += 1
		m.ring_t = 0.0
		if m.ring_k >= 8:
			m.ring_k = -1
			m.garden_q = 4
			m.toast("여덟 등불이 모였다. 이제 함께 감자.") # the last winding opens at eight even with more pips
			m.set_quest("두 팔을 높이 들어 다 같이 땅을 감자 (E)")
			m.save_game()
		else:
			m.set_quest(tr("마을 사람들이 등불을 켜는 동안 거푸집 조각을 막자 %d/8") % m.ring_k)
			shed_shards()

# a shard ignores Sora and runs for its post; reaching it snuffs the flame being lit and two more come
func update_shard(e: Dictionary, dt: float) -> void:
	if e.has("doll"): # 달지기 숙소: the bits run at the walking doorkeeper
		e.post = m.doll_at
	var to: Vector2 = e.post - Vector2(e.x, e.z)
	var d := to.length()
	if e.hurt <= 0.0 and e.get("stun", 0.0) <= 0.0:
		e.x += to.x / maxf(d, 0.01) * 1.9 * dt
		e.z += to.y / maxf(d, 0.01) * 1.9 * dt
	e.t += dt
	e.hurt -= dt
	e.stun = e.get("stun", 0.0) - dt
	var node: Node3D = e.node
	var hop := absf(sin(e.t * 8.0))
	node.position = Vector3(e.x, hop * 0.12, e.z)
	node.rotation.y = atan2(to.x, to.y)
	for mm in node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0
		mm.emission = Color.WHITE
	e.shadow.position = Vector3(e.x, 0.02, e.z)
	if d < 0.8:
		if e.has("gear"): # in the clock room: it hardens its gear again (the lantern ring's rule does not apply)
			clock_gear_lost(int(e.gear))
			return
		if e.has("doll"): # in the quarters: his spring is knocked out
			m.castle_zone.doll_knocked()
			return
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
		m.burst(Vector3(e.post.x, 1.5, e.post.y), Color("#4a4652"), 24, 3.0)
		m.shake = 0.2
		m.sfx(90, 0.3, "square", 0.2, -40)
		m.toast("거푸집 조각이 등불을 덮쳤다!")
		for g in m.enemies:
			if g.get("shard", false) and not g.dead:
				g.dead = true
				g.node.queue_free()
				g.shadow.queue_free()
		m.ring_t = 0.0
		shed_shards()

func final_wind() -> void:
	m.garden_q = 5
	m.crown_pips = 0
	m.burst(Vector3(m.player.x, 2.0, m.player.z), Color("#fff1a0"), 60, 6.0)
	m.shake = 0.6
	m.show_story("res://art/story/11_final_mold.jpg", Main.STORY.FINAL_WIND)
	m.after_story = mold_breaks
	m.save_game()

func mold_breaks() -> void:
	m.ending_due = false
	for e in m.enemies:
		if e.get("mold", false) and not e.dead:
			e.dead = true
			for k in 6:
				m.burst(Vector3(e.x + m.rnd(-2, 2), m.rnd(0.5, 4.0), e.z + m.rnd(-2, 2)), Color("#8a8a96"), 30, 5.0)
			e.node.queue_free()
			e.shadow.queue_free()
	m.ui.boss.visible = false
	m.crown_pips = m.pip_max
	m.player.gold += 500
	m.gain_xp(400)
	m.story_step = 12
	m.show_story(ENDING_PICTURE, ending_lines())
	m.clock_q = maxi(m.clock_q, 1) # where the mold sat a hole opens down to the clock room (a side story after the end)
	m.set_quest(clock_quest())
	m.clock_hint_told = true
	m.garden.open_hatch()
	if m.in_garden:
		m.ui.mini.map_tex = garden_map()
	m.after_story = clock_hint
	m.save_game()

const ENDING_PICTURE := "res://art/story/12_festival.jpg"

# the ending's lines with the record of this run at the end
func ending_lines() -> Array:
	var record: String = tr("||여기까지 걸린 시간 %s, 물리친 괴물 %d마리, 이룬 도전 과제 %d/6.") % [m.errands.play_time_text(), m.stats.kills, m.feats_done.count(true)]
	var ending: Array = Main.STORY.ENDING.duplicate()
	if m.road_q >= 3: # before "그래서, 찾았니?"
		var at := ending.find("보리 할머니|bori|그래서, 찾았니?")
		ending.insert(at if at >= 0 else ending.size(), Main.STORY.ENDING_ROAD)
	return ending + [record]

# 엔딩 다시 보기 (the owner, 2026-10-27: "엔딩은 어떻게 보는거야?"): once the ending has played, the journal's button
# shows it again, the festival picture and the same lines with today's record; nothing is paid or saved
func ending_seen() -> bool:
	return m.story_step >= 12 or m.ng > 0

func replay_ending() -> void:
	if not ending_seen() or m.story_open:
		return
	m.toggle_journal(false)
	m.show_story(ENDING_PICTURE, ending_lines())

func in_clock() -> bool:
	return m.in_garden and m.player.z > Main.GARDEN.CLOCK_Z - 0.5

# the garden's map with the way down at the arena's middle and the way up in the room, once the hole is open
func garden_map() -> ImageTexture:
	var tex: ImageTexture = m.garden.map_tex(Main.GARDEN.GARDEN_X + Main.GARDEN.W)
	if m.clock_q >= 1:
		tex = m.with_up_marks(m.with_stair_marks(tex, [m.garden.marks.C]), [m.garden.clock_marks.U])
	return tex

# where the one pushing spoke k stands
func hand_spot(k: int) -> Vector2:
	var a := TAU * k / 8.0
	return m.garden.clock_marks.O + Vector2(sin(a), cos(a)) * 2.3

func clock_hold() -> bool:
	return (m.clock_q == 4 or m.clock_still) and in_clock()

func clock_hop_y() -> float:
	return 0.12 * sin(PI * m.clock_hop / 0.15) if m.clock_hop > 0.0 else 0.0

# after the ending: a creak far below and the hole where the mold sat
func clock_hint() -> void:
	m.get_tree().create_timer(0.8).timeout.connect(func():
		if m.in_garden and not in_clock() and not m.story_open and m.fade_rect.color.a == 0.0 and m.clock_q == 1:
			m.show_story("", Main.STORY.CLOCK_HINT))

func enter_clock() -> void:
	var u: Vector2 = m.garden.clock_marks.U
	m.player.x = u.x
	m.player.z = u.y - 1.3
	m.ground_y = 0.0
	clock_zone()
	m.snap_mates()
	if m.clock_q == 1:
		m.clock_q = 2
		m.set_quest(clock_quest())
		m.show_story("", Main.STORY.CLOCK_IN)
	m.save_game()

# the room's name, map and look, for a way in, a load or a scene
func clock_zone() -> void:
	m.ui.zone_name.text = "큰 태엽 방"
	m.ui.zone_sub.text = "정원 한가운데 아래"
	m.ui.mini.map_tex = garden_map()
	m.garden.clock_view(true)
	place_workers()
	place_clock_folk()
	m.daynight.update_daylight(0.0)

func leave_clock() -> void:
	clear_clock_wave()
	beat_clear()
	m.clock_still = false
	m.player.x = m.garden.marks.C.x
	m.player.z = m.garden.marks.C.y + 2.5
	m.ground_y = 0.0
	m.garden.clock_view(false)
	m.ui.zone_name.text = "정원 한가운데"
	m.ui.zone_sub.text = "굳은달 빈터"
	m.ui.mini.map_tex = garden_map()
	if m.clock_q >= 5: # wound: the villagers have gone home
		for id in m.clock_folk:
			(m.clock_folk[id] as Node3D).visible = false
	m.snap_mates()
	m.save_game()

# E in the clock room
func clock_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if m.clock_q == 4:
		if me.distance_to(m.garden.clock_marks.J) < 1.6:
			beat_key()
		else:
			m.toast("한결의 손잡이에서 박자에 맞춰 E")
		return true
	if not m.clock_box and m.clock_q >= 2 and me.distance_to(m.garden.clock_marks.c) < 1.6:
		open_clock_box()
		return true
	for i in m.garden.gears.size():
		var p: Vector2 = m.garden.gears[i].pos
		if not m.clock_gears[i] and me.distance_to(p) < 1.6:
			if not m.clock_wave.is_empty():
				m.toast("찌꺼기부터 막자")
				return true
			if not m.spend_pips(1): # like a seal: the heart is near, so the crown is strong, day or night
				return true
			m.garden.set_gear(i, true)
			m.clock_wave = {"gear": i, "t": 0.0, "spawned": false, "done": 0.0}
			m.burst(Vector3(p.x, 0.9, p.y), Color("#c8962a"), 30, 3.0)
			m.shake = 0.2
			m.sfx(150, 0.5, "triangle", 0.3, -40)
			return true
	if m.clock_q == 3 and me.distance_to(m.garden.clock_marks.O) < 3.1:
		crown_into_key()
		return true
	if me.distance_to(m.garden.clock_marks.J) < 1.6:
		m.show_story("", clock_worn_lines())
		return true
	return false

func clock_worn_lines() -> Array: # after the big spring was wound together, eight worn handles (GPT playtests 2 -> 9)
	if m.clock_q >= 5:
		return Main.STORY.CLOCK_WORN_DONE.duplicate()
	var lines: Array = Main.STORY.CLOCK_WORN.duplicate()
	if m.post_q >= 4:
		lines.append(Main.STORY.CLOCK_WORN_POST)
	return lines

# freeing a gear lets 2, 3 then 4 scraps out of the key; they run for that gear and do not hit Sora
func shed_clock_shards(i: int) -> void:
	m.clock_wave.spawned = true
	var c: Vector2 = m.garden.clock_marks.O
	var to: Vector2 = m.garden.gears[i].pos
	var dir := (to - c).normalized()
	var n: int = m.clock_gears.count(true) + 2
	for k in n:
		var at := c + dir.rotated((k - (n - 1) / 2.0) * 0.5) * m.rnd(1.5, 2.0)
		m.spawn_enemy(at)
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.shard = true
		e.cave = true # no respawn
		e.gear = i
		e.hp = 18.0 + m.foe_lv() * 4
		e.max_hp = int(e.hp)
		e.post = to
		for mm in e.node.get_meta("mats"):
			mm.albedo_color = Color("#8a8a96").lightened(m.rnd(0, 0.15))
		m.burst(Vector3(at.x, 1.0, at.y), Color("#8a8a96"), 10, 2.0)
	m.sfx(110, 0.3, "square", 0.15, -30)

func clock_scraps_alive() -> bool:
	return m.enemies.any(func(e): return e.has("gear") and not e.dead)

# a scrap reached its gear: the gear hardens again and the rest of its pack goes
func clock_gear_lost(i: int) -> void:
	for g in m.enemies:
		if g.has("gear") and not g.dead:
			g.dead = true
			g.node.queue_free()
			g.shadow.queue_free()
	m.clock_wave = {}
	m.garden.set_gear(i, false)
	m.ui.mini.map_tex = garden_map()
	var p: Vector2 = m.garden.gears[i].pos
	m.burst(Vector3(p.x, 1.0, p.y), Color("#9a4ad8"), 24, 3.0)
	m.shake = 0.2
	m.sfx(90, 0.3, "square", 0.2, -40)
	m.toast("거푸집 찌꺼기가 톱니를 다시 굳혔다")

# scraps left over (Sora went up, fainted or loaded): they go, and a gear they had not yet lost stays hardened
func clear_clock_wave() -> void:
	for e in m.enemies:
		if e.has("gear") and not e.dead:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
	if not m.clock_wave.is_empty() and not m.clock_gears[int(m.clock_wave.gear)]:
		m.garden.set_gear(int(m.clock_wave.gear), false)
	m.clock_wave = {}
	m.clock_say_t = -1.0

func clock_gear_freed(i: int) -> void:
	m.clock_wave = {}
	m.clock_gears[i] = true
	var n: int = m.clock_gears.count(true)
	workers_rise(i)
	m.ui.mini.map_tex = garden_map()
	m.sfx(392 + 60 * n, 0.3, "sine", 0.2)
	if n == 1: # two workers get up and tend the gear a moment before anyone says what they are (GPT's note)
		m.clock_say = Main.STORY.CLOCK_GEAR1
		m.clock_say_t = 2.4
	else:
		m.toast(tr("벽돌 일꾼 둘이 톱니에 붙었다 (%d/3)") % n)
	if n == 3:
		m.clock_q = maxi(m.clock_q, 3)
		m.clock_say = Main.STORY.CLOCK_GEARS
		m.clock_say_t = 2.0
	m.set_quest(clock_quest())
	m.save_game()

func crown_into_key() -> void:
	m.clock_q = 4
	m.set_quest(clock_quest())
	m.garden.crown_in(true)
	var o: Vector2 = m.garden.clock_marks.O
	m.burst(Vector3(o.x, 1.2, o.y), Color("#9fd4ff"), 40, 3.5)
	m.sfx(523, 0.6, "sine", 0.25, 200)
	var j := hand_spot(0)
	m.player.x = j.x
	m.player.z = j.y
	place_workers()
	place_clock_folk(true)
	m.snap_mates()
	m.show_story("", Main.STORY.CLOCK_HUB)
	m.save_game()

# ---- the brick workers: they sit by the walls like toys; two rise for each freed gear and the last takes a spoke
func place_workers() -> void:
	if m.workers.is_empty():
		for s in m.garden.seats:
			var node := m.monsters.make_monster()
			m.add_child(node)
			m.workers.append({"node": node, "seat": s, "job": -1, "side": 1.0})
	for w in m.workers:
		w.job = -1
	for i in 3:
		if m.clock_gears[i]:
			assign_workers(i)
	if m.clock_q >= 4:
		for w in m.workers:
			if w.job == -1:
				w.job = 3
				break
	for w in m.workers:
		var at := worker_spot(w)
		(w.node as Node3D).position = Vector3(at.x, 0, at.y)
		(w.node as Node3D).scale = Vector3(1, 0.8, 1) if w.job == -1 else Vector3.ONE

# the two nearest sitting workers take gear i
func assign_workers(i: int) -> Array:
	var p: Vector2 = m.garden.gears[i].pos
	var free := m.workers.filter(func(w): return w.job == -1)
	free.sort_custom(func(a, b): return (a.seat as Vector2).distance_to(p) < (b.seat as Vector2).distance_to(p))
	var got: Array = free.slice(0, 2)
	for k in got.size():
		got[k].job = i
		got[k].side = -1.0 if k == 0 else 1.0
	return got

func worker_spot(w: Dictionary) -> Vector2:
	var job: int = w.job
	if job == -1:
		return w.seat
	if job == 3:
		return hand_spot(3)
	var p: Vector2 = m.garden.gears[job].pos
	var dir: Vector2 = (p - m.garden.clock_marks.O).normalized()
	return p + Vector2(-dir.y, dir.x) * float(w.side) * 0.95

func workers_rise(i: int) -> void:
	for w in assign_workers(i):
		var node: Node3D = w.node
		var to := worker_spot(w)
		node.scale = Vector3.ONE
		var tw := m.create_tween()
		tw.tween_property(node, "position", Vector3(to.x, 0, to.y), clampf(Vector2(node.position.x, node.position.z).distance_to(to) / 2.0, 0.5, 3.0))
		m.burst(node.position + Vector3(0, 0.6, 0), Color("#c8962a"), 8, 1.2)

# sitting workers face the key; the ones at a gear rub its teeth, the one at a spoke pushes with the rest
func update_workers() -> void:
	var o: Vector2 = m.garden.clock_marks.O
	for w in m.workers:
		var node: Node3D = w.node
		var at := Vector2(node.position.x, node.position.z)
		var job: int = w.job
		var look: Vector2 = o - at
		if job >= 0 and job <= 2:
			look = (m.garden.gears[job].pos as Vector2) - at
		node.rotation.y = atan2(look.x, look.y) + (sin(m.t * 7.0 + float(w.side)) * 0.35 if job >= 0 and job <= 2 else 0.0)
		if job == 3:
			node.position.y = clock_hop_y()

# villagers come down the stairs to the spokes once the crown is in; after the winding they go home with Sora
func place_clock_folk(walk := false) -> void:
	if m.clock_q != 4:
		return
	var k := 0
	for id in ["simji", "kongal", "doran", "kid"]:
		if not m.clock_folk.has(id):
			var g := Node3D.new()
			var spr := m.folk_sprite(id)
			g.add_child(spr) # folk_sprite sizes it from main.gd FOLK_HEIGHT
			m.add_child(g)
			m.clock_folk[id] = g
		var g: Node3D = m.clock_folk[id]
		g.visible = true
		var to := hand_spot(Main.CLOCK_HANDS.find(id))
		if walk: # one after another down the stairs, round the key, to a spoke
			var u: Vector2 = m.garden.clock_marks.U
			var side: Vector2 = m.garden.clock_marks.O + Vector2(-3.3 if to.x <= m.garden.clock_marks.O.x else 3.3, 0.5)
			g.position = Vector3(u.x, 0, u.y)
			var tw := m.create_tween()
			tw.tween_interval(0.4 + k * 0.6)
			tw.tween_property(g, "position", Vector3(side.x, 0, side.y), 1.2)
			tw.tween_property(g, "position", Vector3(to.x, 0, to.y), 1.0)
		else:
			g.position = Vector3(to.x, 0, to.y)
		k += 1

# ---- winding together: a thin gold octagon closes on the key every 1.2 s; E while it is inside the brass rim
# (the last 0.25 s) is one push. Early or missed presses do nothing and the next ring comes; there is no losing.
func start_beat() -> void:
	var o: Vector2 = m.garden.clock_marks.O
	var at := Vector3(o.x, 0.98, o.y)
	var ring := MeshInstance3D.new()
	ring.mesh = m.ring_mesh(0.96, 1.0, PI / 8.0, TAU, 8)
	ring.material_override = m.glow_mat(Color("#ffd27a"), 2.4)
	ring.position = at
	m.add_child(ring)
	var thick := MeshInstance3D.new() # the same ring drawn thicker while E counts
	thick.mesh = m.ring_mesh(0.84, 1.0, PI / 8.0, TAU, 8)
	thick.material_override = m.glow_mat(Color("#ffd27a"), 4.0)
	thick.position = at
	thick.visible = false
	m.add_child(thick)
	var rim := MeshInstance3D.new() # the fixed rim it closes onto
	rim.mesh = m.ring_mesh(CLOCK_WINDOW - 0.05, CLOCK_WINDOW, PI / 8.0, TAU, 8)
	rim.material_override = m.glow_mat(Color("#c8962a"), 1.0)
	rim.position = at
	m.add_child(rim)
	m.beat = {"r": 3.0, "node": ring, "thick": thick, "rim": rim, "n": 0, "hit": false, "win": false}

func beat_clear() -> void:
	for k in ["node", "thick", "rim"]:
		if m.beat.has(k) and is_instance_valid(m.beat[k]):
			(m.beat[k] as Node).queue_free()
	m.beat = {}

func update_beat(dt: float) -> void:
	if m.story_open or m.fade_rect.color.a > 0.0:
		return
	if m.beat.is_empty():
		start_beat()
	m.beat.r -= dt * 2.4 / CLOCK_BEAT
	if m.beat.r < 0.6:
		m.beat.r = 3.0
		m.beat.hit = false
	var win: bool = m.beat.r < CLOCK_WINDOW and not m.beat.hit
	if win and not m.beat.win:
		m.sfx(784, 0.05, "sine", 0.06) # a soft tick as it meets the rim
	m.beat.win = win
	var ring: MeshInstance3D = m.beat.node
	var thick: MeshInstance3D = m.beat.thick
	ring.scale = Vector3(m.beat.r, 1.0, m.beat.r)
	thick.scale = ring.scale
	ring.visible = not win and not m.beat.hit
	thick.visible = win

func beat_key() -> void:
	if m.beat.is_empty() or m.beat.hit or m.beat.r >= CLOCK_WINDOW:
		return
	m.beat.hit = true
	m.beat.n += 1
	var n: int = m.beat.n
	m.garden.turn_key(m, 45.0)
	m.sfx(392 + 40 * (n - 1), 0.25, "sine", 0.2)
	var o: Vector2 = m.garden.clock_marks.O
	m.burst(Vector3(o.x, 1.0, o.y), Color("#ffd27a"), 16, 2.5)
	if n < 8:
		m.clock_hop = 0.15
		m.toast(tr("박자에 맞춰 다 같이 밀자 (E) %d/8") % n)
		return
	# the last push: no hop, hands stay on the spokes
	m.clock_q = 5
	m.clock_still = true
	beat_clear()
	m.shake = 0.3
	m.show_story("res://art/story/14_clock_together.jpg", Main.STORY.CLOCK_WOUND)
	m.set_quest(clock_quest()) # the side story is done too
	m.after_story = clock_hush
	m.save_game()

# after the last push: 1.6 s with only the gears' sound while the camera comes close on the worn handle and the two
# beside it, then Bori's line from the stairs (GPT's note)
func clock_hush() -> void:
	m.garden.wind_look(true)
	m.ui.mini.map_tex = garden_map()
	m.clock_cam = m.cam_dist
	m.create_tween().tween_property(m, "cam_dist", 11.0, 1.2)
	var grip: Vector2 = m.garden.clock_marks.O + Vector2(0, 1.95)
	m.burst(Vector3(grip.x, 0.8, grip.y), Color("#e8c060"), 12, 1.0)
	for k in 4:
		m.get_tree().create_timer(0.4 * k).timeout.connect(func(): m.sfx(180 - k * 10, 0.06, "triangle", 0.08))
	m.get_tree().create_timer(1.6).timeout.connect(func():
		if m.story_open:
			clock_cam_back()
			return
		m.show_story("", Main.STORY.CLOCK_LATE)
		m.after_story = clock_cam_back)

func clock_cam_back() -> void:
	m.clock_still = false
	if m.clock_cam > 0.0:
		m.create_tween().tween_property(m, "cam_dist", m.clock_cam, 0.8)
		m.clock_cam = 0.0
	m.save_game()

func open_clock_box() -> void:
	m.clock_box = true
	m.garden.chest_look(true)
	var lines: Array = Main.STORY.CLOCK_CHEST.duplicate()
	if not m.has_oil:
		m.has_oil = true
		m.player.max_hp += 20
		m.player.hp = float(m.player.max_hp)
		m.player.pots += 2
		m.player.gold += 200
	else: # a new round: the oil came along
		lines.pop_back()
		m.player.gold += 50
		m.player.pots += 1
		m.toast("금화 50, 회복약 1")
	var c: Vector2 = m.garden.clock_marks.c
	m.burst(Vector3(c.x, 0.6, c.y), Color("#f2ead8"), 30, 2.5)
	m.sfx(784, 0.12, "triangle", 0.25)
	m.ui.mini.map_tex = garden_map()
	m.show_story("", lines)
	m.save_game()

func update_clock(dt: float) -> void:
	m.garden.tick(dt)
	m.clock_hop = maxf(0.0, m.clock_hop - dt)
	update_workers()
	for id in m.clock_folk:
		var g: Node3D = m.clock_folk[id]
		if g.visible and m.clock_hop > 0.0:
			g.position.y = clock_hop_y()
	if m.fade_rect.color.a == 0.0 and not m.story_open and Vector2(m.player.x, m.player.z).distance_to(m.garden.clock_marks.U) < 0.9:
		m.fade_then(leave_clock)
		return
	if m.clock_say_t > 0.0:
		m.clock_say_t -= dt
		if m.clock_say_t <= 0.0:
			if m.story_open:
				m.clock_say_t = 0.3
			else:
				m.show_story("", m.clock_say)
	if not m.clock_wave.is_empty():
		m.clock_wave.t += dt
		if not m.clock_wave.spawned:
			if m.clock_wave.t >= 0.6:
				shed_clock_shards(int(m.clock_wave.gear))
		elif not clock_scraps_alive():
			m.clock_wave.done += dt
			if m.clock_wave.done >= 1.0:
				clock_gear_freed(int(m.clock_wave.gear))
	if m.clock_q == 4:
		update_beat(dt)
	elif not m.beat.is_empty():
		beat_clear()

# load the room's state (old saves without it: past the ending the hole is open)
func load_clock(d: Dictionary) -> void:
	if d.has("clock_q"):
		m.clock_q = int(d.clock_q)
		m.clock_late = bool(d.get("clock_late", false))
	else:
		m.clock_q = 1 if m.garden_q >= 5 else 0
		m.clock_late = m.garden_q >= 5
	var cg: Array = d.get("clock_gears", [])
	for i in 3:
		m.clock_gears[i] = i < cg.size() and bool(cg[i])
	m.clock_box = bool(d.get("clock_box", false))
	m.has_oil = bool(d.get("has_oil", false))
	clear_clock_wave()
	beat_clear()
	m.clock_still = false
	m.garden.clock_look(m.clock_q, m.clock_gears, m.clock_box)
