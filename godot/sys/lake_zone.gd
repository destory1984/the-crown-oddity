# South lake: Mulgyeol, the turtle, the lower pond, the water grotto and crab.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const SOUTH_YARD_X := 292.5  # east of the grate
const SOUTH_SWIM := 3.0      # Mulgyeol's swim, tiles a second
const SOUTH_HOLD_MAX := 20.0 # he lets go if Sora does not go in

func _init(main: Main) -> void:
	m = main

func enter_lake() -> void:
	m.in_village = false
	m.in_lake = true
	m.player.x = m.lake.marks.S.x
	m.player.z = m.lake.marks.S.y + 1.2
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G])
	m.ui.zone_name.text = "남쪽 호수"
	m.ui.zone_sub.text = "굳은 물가"
	if m.lake_q < 3:
		if m.lake_npc == null:
			m.lake_npc = m.folk_sprite("mulgyeol")
			m.add_child(m.lake_npc)
		m.lake_npc.position = Vector3(m.lake.marks.P.x + 1.0, 0, m.lake.marks.P.y)
		m.lake_npc.visible = true
	if m.lake_q == 0:
		m.lake_q = 1
		m.show_story("", Main.STORY.LAKE_IN)
		m.set_quest("수문의 벽돌을 팔찌로 풀자 (E)")
	elif m.lake_q == 2 and Main.Ko.plain(m.ui.quest.text) == m.touch_words(tr(Main.LAKE_RETRY_QUEST)):
		m.set_quest("부두의 물결에게 말을 걸자 (E)")
	m.save_game()

func leave_lake() -> void:
	clear_south_job()
	m.in_lake = false
	m.in_village = true
	m.player.x = m.village.marks.K.x
	m.player.z = m.village.marks.K.y - 1.2
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.village.map_tex(Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W)
	m.ui.zone_name.text = "등불 마을"
	m.ui.zone_sub.text = "남쪽 문"
	m.ui.boss.visible = false
	m.save_game()

# E at the lake: unwind the sluice, ask Mulgyeol for the boat, or row back from the island
func lake_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if m.lake_q == 1 and me.distance_to(m.lake.marks.D) < 1.6:
		if m.spend_pips(m.unbrick_cost()):
			m.lake.thaw()
			m.lake_q = 2
			m.burst(Vector3(m.lake.marks.D.x, 0.6, m.lake.marks.D.y), Color("#9fd4ff"), 40, 4.0)
			m.shake = 0.3
			m.sfx(196, 0.6, "triangle", 0.3, -60)
			m.ui.mini.map_tex = m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G])
			m.show_story("", Main.STORY.LAKE_THAW)
			m.set_quest("부두의 물결에게 말을 걸자 (E)")
			m.save_game()
		return true
	if m.lake_q == 2 and m.lake_npc != null and me.distance_to(Vector2(m.lake_npc.position.x, m.lake_npc.position.z)) < 1.6:
		m.fade_then(row_to_island)
		return true
	if m.lake_q >= 4 and me.distance_to(m.lake.marks.Q) < 1.6:
		m.fade_then(func():
			m.player.x = m.lake.marks.P.x
			m.player.z = m.lake.marks.P.y - 1.0
			m.snap_mate())
		return true
	if m.lake_q >= 4 and me.distance_to(m.lake.marks.P) < 1.6:
		m.fade_then(func():
			m.player.x = m.lake.marks.Q.x
			m.player.z = m.lake.marks.Q.y + 1.0
			m.snap_mate())
		return true
	return false

func row_to_island() -> void:
	m.lake_q = 3
	m.lake_npc.visible = false
	m.join_mate()
	m.player.x = m.lake.marks.Q.x
	m.player.z = m.lake.marks.Q.y + 1.0
	m.snap_mate()
	m.show_story("", Main.STORY.BOAT)
	m.after_story = spawn_turtle
	m.set_quest("섬의 벽돌 거북을 물리치자")
	m.save_game()

func spawn_turtle() -> void:
	if m.enemies.any(func(e): return e.get("turtle", false) and not e.dead):
		return
	var at: Vector2 = m.lake.marks.T
	var root := Node3D.new()
	var shell: Material = m.mat_color(Color("#5f7a52"))
	var stud: Material = m.mat_color(Color("#7a9a62"))
	var skin: Material = m.mat_color(Color("#8a8a70"))
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	for part in [[Vector3(2.0, 0.9, 2.4), Vector3(0, 0.75, 0), shell], [Vector3(1.6, 0.4, 2.0), Vector3(0, 1.35, 0), shell],
			[Vector3(0.7, 0.6, 0.8), Vector3(0, 0.6, 1.5), skin],
			[Vector3(0.5, 0.5, 0.5), Vector3(-0.9, 0.25, 0.9), skin], [Vector3(0.5, 0.5, 0.5), Vector3(0.9, 0.25, 0.9), skin],
			[Vector3(0.5, 0.5, 0.5), Vector3(-0.9, 0.25, -0.9), skin], [Vector3(0.5, 0.5, 0.5), Vector3(0.9, 0.25, -0.9), skin]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		body.add_child(b)
	for k in 4: # studs on the shell
		var s := m.box(Vector3(0.3, 0.16, 0.3), stud)
		s.position = Vector3(-0.4 + (k % 2) * 0.8, 1.6, -0.4 + (k / 2) * 0.8)
		body.add_child(s)
	for side in [-0.18, 0.18]:
		var eye := m.box(Vector3(0.12, 0.12, 0.05), m.glow_mat(Color("#ffb040"), 2.0))
		eye.position = Vector3(side, 0.75, 1.92)
		body.add_child(eye)
	m.add_child(root)
	m.enemies.append({"x": at.x, "z": at.y, "hp": 900.0, "max_hp": 900, "node": root, "shadow": m.blob(1.6), "t": 0.0,
		"atk_cd": 2.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"turtle": true, "cave": true, "wind": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "stun": 0.0, "next": "stomp", "spins": 0})

# the brick turtle: a stomp ring around itself, then a spinning shell charge (twice below half HP);
# hitting the island's edge leaves it stunned for a moment
func update_turtle(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var body: Node3D = node.get_node("body")
	m.ui.boss.visible = d < 12.0
	m.ui.boss_name.text = "벽돌 거북"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	body.scale = Vector3.ONE * (1.06 if e.hurt > 0.0 else 1.0)
	if e.dash > 0.0:
		e.dash -= dt
		body.rotation.y += dt * 14.0
		var nx: float = e.x + e.dir.x * 7.5 * dt
		var nz: float = e.z + e.dir.y * 7.5 * dt
		if m.walkable(nx, nz):
			e.x = nx
			e.z = nz
			if Vector2(m.player.x - e.x, m.player.z - e.z).length() < 1.4:
				m.player_hit(22, Vector2(e.x, e.z) - e.dir, e)
		else:
			e.dash = 0.0
			e.stun = 1.6
			m.shake = 0.3
			m.sfx(80, 0.3, "square", 0.3, -40)
			m.burst(Vector3(e.x, 0.6, e.z), Color("#7a9a62"), 20, 3.0)
		if e.dash <= 0.0 and e.spins > 0:
			e.spins -= 1
			e.wind = 0.5
			e.dir = to / maxf(d, 0.01)
	elif e.stun > 0.0:
		pass
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			if e.next == "stomp":
				m.burst(Vector3(e.x, 0.3, e.z), Color("#8a8a70"), 30, 3.5)
				if d < 2.6:
					m.player_hit(18, Vector2(e.x, e.z), e)
				m.shake = 0.25
				m.sfx(70, 0.3, "square", 0.25, -30)
				e.next = "spin"
			else:
				e.dash = 1.1
				e.next = "stomp"
			e.atk_cd = 1.6
	elif d < 10.0:
		e.atk_cd -= dt
		if e.atk_cd <= 0.0:
			if e.next == "stomp":
				e.wind = 0.9
				m.warn_ring(Vector3(e.x, 0.0, e.z), 2.6, 0.9)
			else:
				e.wind = 0.8
				e.dir = to / maxf(d, 0.01)
				e.spins = 1 if e.hp < e.max_hp / 2.0 else 0
				m.pop_num(Vector3(e.x, 2.4, e.z), "!", Color("#ff5a4a"))
				m.sfx(140, 0.5, "sawtooth", 0.2, 120)
		elif d > 1.8:
			var nx: float = e.x + to.x / d * 1.0 * dt
			var nz: float = e.z + to.y / d * 1.0 * dt
			if m.walkable(nx, e.z): e.x = nx
			if m.walkable(e.x, nz): e.z = nz
			body.rotation.y = lerp_angle(body.rotation.y, atan2(to.x, to.y), dt * 3.0)
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func lake_map() -> ImageTexture:
	return m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G])

func in_south_yard(p: Vector2) -> bool:
	return p.x > SOUTH_YARD_X and p.y > 26.5 and p.y < 37.5

# E in the lower pond (and at the weir from the island's south tip)
func south_key() -> bool:
	if m.lake_q < 4:
		return false
	var me := Vector2(m.player.x, m.player.z)
	if not m.lake.weir_open and me.distance_to(m.lake.marks.Y) < 1.6:
		if not m.spend_pips(m.unbrick_cost()):
			return true
		m.lake.open_weir()
		m.south_q = maxi(m.south_q, 1)
		m.burst(Vector3(m.lake.marks.Y.x, 0.7, m.lake.marks.Y.y), Color("#8a6a4a"), 36, 3.5)
		m.shake = 0.25
		m.sfx(196, 0.5, "triangle", 0.3, -60)
		m.ui.mini.map_tex = lake_map()
		m.show_story("", Main.STORY.SOUTH_WEIR)
		spawn_south_foes()
		m.save_game()
		return true
	if me.y < Main.LAKE.SOUTH_Z + 0.5:
		return false
	if me.distance_to(m.lake.marks.B) < 1.8:
		m.south_shed_seen = true
		m.show_story("", Main.STORY.SOUTH_SHED)
		return true
	for i in m.lake.ropes.size():
		if me.distance_to(m.lake.ropes[i]) < 1.6 and m.south_q == i + 1:
			if not m.mate_job.is_empty():
				return true
			if m.mate == null or m.mate_down.mulgyeol > 0.0:
				m.toast("물결이 일어날 때까지 기다리자")
				return true
			var chain: Vector2 = m.lake.chains[i]
			var home: Vector2 = m.lake.ropes[i] + Vector2(-1.0, 0)
			m.show_story("", Main.STORY.SOUTH_ROPE1 if i == 0 else Main.STORY.SOUTH_ROPE2)
			m.after_story = func(): send_mate(chain, "pull" if i == 0 else "hold", home)
			return true
	if m.south_q == 3 and me.distance_to(m.lake.marks.K) < 1.6:
		if not m.spend_pips(2):
			return true
		m.lake.turn_spring()
		m.south_q = 4
		m.burst(Vector3(m.lake.marks.K.x, 1.2, m.lake.marks.K.y), Color("#e8c84a"), 30, 3.0)
		m.burst(Vector3(m.lake.marks.W.x, 0.5, m.lake.marks.W.y), Color("#9fd4ff"), 36, 3.5)
		m.shake = 0.2
		m.sfx(330, 0.5, "sine", 0.25, 200)
		m.ui.mini.map_tex = lake_map()
		m.show_story("", Main.STORY.SOUTH_SPRING)
		m.save_game()
		return true
	if m.south_q == 4 and me.distance_to(m.lake.marks.c) < 1.6:
		m.south_q = 5
		m.lake.tin_look()
		var rest: Array = []
		if not m.south_shed_seen:
			rest.append(Main.STORY.SOUTH_BOX_KEEPER)
		rest.append(Main.STORY.SOUTH_BOX_GOT if m.mail_got[2] else Main.STORY.SOUTH_BOX_NOT)
		rest.append_array(Main.STORY.SOUTH_BOX_END)
		if not m.has_whistle:
			m.has_whistle = true
			m.player.max_hp += 10
			m.player.hp = float(m.player.max_hp)
			m.player.pots += 1
		else: # a new round: the whistle came along
			rest.pop_back()
			m.player.gold += 40
			m.player.pots += 1
			m.toast("금화 40, 회복약 1")
		m.burst(Vector3(m.lake.marks.c.x, 0.6, m.lake.marks.c.y), Color("#9fb4c8"), 30, 2.5)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.ui.mini.map_tex = lake_map()
		m.show_story("", Main.STORY.SOUTH_BOX)
		# after the keeper's last page, a moment of running water before Mulgyeol speaks (GPT's note)
		m.after_story = func():
			for k in 4:
				m.get_tree().create_timer(0.3 * k).timeout.connect(func(): m.sfx(260 - k * 30, 0.4, "noise", 0.05, -80))
			m.get_tree().create_timer(1.6).timeout.connect(func(): if not m.story_open: m.show_story("", rest))
		m.save_game()
		return true
	return false

func send_mate(at: Vector2, kind: String, home: Vector2) -> void:
	if m.mate == null or m.mate_down.mulgyeol > 0.0:
		m.toast("물결이 일어날 때까지 기다리자")
		return
	m.mate_job = {"state": "swim", "kind": kind, "to": at, "home": home, "t": 0.0, "fx": 0.0, "inside": 0.0}

func mate_job_state() -> String:
	return m.mate_job.get("state", "")

# Mulgyeol on a job: he swims straight (3 tiles a second, half under water) and does not follow or fight
func update_mate_job(dt: float) -> void:
	var spr: Sprite3D = m.mate.get_child(0)
	var at := Vector2(m.mate.position.x, m.mate.position.z)
	var to: Vector2 = m.mate_job.to
	var st: String = m.mate_job.state
	var wet: bool = m.lake.char_at(at.x, at.y) in "Xo-"
	m.mate_job.t += dt
	m.mate_job.fx += dt
	if st == "swim" or st == "back" or st == "wait":
		var d := to - at
		if d.length() > 0.05:
			at += d.normalized() * minf(d.length(), dt * SOUTH_SWIM)
			spr.flip_h = not m.screen_left(d)
			if wet and m.mate_job.fx > 0.2:
				m.mate_job.fx = 0.0
				m.burst(Vector3(at.x, 0.0, at.y), Color("#9fd4ff"), 4, 0.8)
		elif st == "swim":
			m.mate_job.state = "pull" if m.mate_job.kind == "pull" else "hold"
			m.mate_job.t = 0.0
			if m.mate_job.kind == "hold":
				m.lake.grate_held = true
				m.lake.set_grate(m, true)
				m.ui.mini.map_tex = lake_map()
				m.sfx(240, 0.4, "triangle", 0.2, 120)
		elif st == "back":
			m.mate_job = {}
		elif st == "wait": # by the post, hauling on the rope again and again
			var ph := fmod(m.mate_job.t, 2.0)
			at = to + Vector2(-0.18 if ph < 0.35 else 0.0, 0)
			if ph < dt * 1.5:
				var ch: Node3D = m.lake.chain_nodes[1]
				var tw := m.create_tween()
				tw.tween_property(ch, "position:y", -0.1, 0.12)
				tw.tween_property(ch, "position:y", -0.25, 0.2)
				if int(m.mate_job.t / 2.0) % 3 == 1:
					m.say_bubble(m.mate, tr("끄응, 한 번만 더……!"), 1.8)
	elif st == "pull" or st == "hold":
		m.mate.position.y = -0.25 + sin(m.t * 9.0) * 0.04
		if st == "pull" and m.mate_job.t >= 1.0:
			m.lake.raise_stones(m)
			m.south_q = maxi(m.south_q, 2)
			m.burst(Vector3(m.lake.stones[1].x + 0.5, 0.2, m.lake.stones[1].y), Color("#9fd4ff"), 30, 3.0)
			m.sfx(392, 0.3, "triangle", 0.2, 120)
			m.toast("물밑에서 디딤돌 넷이 떠올랐다")
			m.ui.mini.map_tex = lake_map()
			m.mate_job = {"state": "back", "to": m.mate_job.home, "home": m.mate_job.home, "t": 0.0, "fx": 0.0}
			m.save_game()
		elif st == "hold":
			if in_south_yard(Vector2(m.player.x, m.player.z)):
				m.mate_job.inside += dt
			else:
				m.mate_job.inside = 0.0
			var on_grate: bool = Vector2(m.player.x, m.player.z).distance_to(m.lake.marks.H) < 0.9 # never drop it on her
			if m.mate_job.inside >= 1.0 or (m.mate_job.t >= SOUTH_HOLD_MAX and not on_grate):
				south_let_go(m.mate_job.inside >= 1.0)
		m.mate.position.x = at.x
		m.mate.position.z = at.y
		return
	m.mate.position = Vector3(at.x, -0.25 if wet else 0.0, at.y)

# the grate's chain gets away from Mulgyeol: with Sora in the yard it snaps out of his hands and the bricks rise
func south_let_go(inside: bool) -> void:
	m.lake.grate_held = false
	m.lake.set_grate(m, false)
	m.ui.mini.map_tex = lake_map()
	var ch: Node3D = m.lake.chain_nodes[1]
	var tw := m.create_tween() # a short jerk as it gets away
	tw.tween_property(ch, "position:y", 0.15, 0.08)
	tw.tween_property(ch, "position:y", -0.25, 0.25)
	m.burst(Vector3(ch.position.x, 0.2, ch.position.z), Color("#9fd4ff"), 20, 2.5)
	m.sfx(90, 0.35, "square", 0.25, -30)
	if inside:
		m.shake = 0.3
		m.mate_job = {"state": "wait", "to": m.mate_job.home, "home": m.mate_job.home, "t": 0.0, "fx": 0.0}
		if m.mate2 != null:
			m.mate2.position = Vector3(m.mate_job.home.x, 0, m.mate_job.home.y - 1.0)
		spawn_south_ambush()
		m.show_story("", Main.STORY.SOUTH_SHUT)
	else:
		m.toast("물결이 사슬을 놓고 돌아왔다. 말뚝에서 다시 E")
		m.mate_job = {"state": "back", "to": m.mate_job.home, "home": m.mate_job.home, "t": 0.0, "fx": 0.0}

func spawn_south_foes() -> void:
	if m.south_spawned or m.south_q < 1 or m.south_q > 2:
		return
	m.south_spawned = true
	for f in m.lake.south_foes:
		var w: Vector2 = f[0]
		if w.x >= 296.0: # the yard's ambush waits for the grate
			continue
		m.spawn_enemy(w, f[1] == "a")
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.cave = true
		if f[1] == "s":
			m.give_shield(e)

func spawn_south_ambush() -> void:
	clear_south_ambush()
	for f in m.lake.south_foes:
		var w: Vector2 = f[0]
		if w.x < 296.0:
			continue
		m.spawn_enemy(w, f[1] == "a")
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.cave = true
		e.south_ambush = true
		m.burst(Vector3(w.x, 0.5, w.y), Color("#8a8a90"), 14, 2.0)
	m.south_ambush_on = true

func clear_south_ambush() -> void:
	for e in m.enemies:
		if e.get("south_ambush", false) and not e.dead:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
	m.south_ambush_on = false

# Sora faints or leaves: the ambush goes, Mulgyeol comes back to her side and the grate drops
func clear_south_job() -> void:
	clear_south_ambush()
	m.south_latch_t = -1.0
	if not m.mate_job.is_empty():
		m.mate_job = {}
		if m.mate != null:
			m.mate.position.y = 0.0
	if m.lake.grate_held:
		m.lake.grate_held = false
		m.lake.grate.position.y = 0.0

func south_latch() -> void:
	m.south_ambush_on = false
	m.lake.break_latch(m)
	m.south_q = maxi(m.south_q, 3)
	m.mate_job = {}
	if m.mate != null:
		m.mate.position.y = 0.0
	m.burst(Vector3(m.lake.marks.l.x, 0.4, m.lake.marks.l.y), Color("#8a8a90"), 24, 2.5)
	m.sfx(196, 0.4, "triangle", 0.25, -60)
	m.ui.mini.map_tex = lake_map()
	m.show_story("", Main.STORY.SOUTH_LATCH)
	m.save_game()

func update_lake_south(dt: float) -> void:
	var me := Vector2(m.player.x, m.player.z)
	m.lake.tick(dt, m.t)
	if me.y > Main.LAKE.SOUTH_Z + 0.5:
		m.ui.zone_sub.text = "아랫못"
	elif m.ui.zone_sub.text == "아랫못":
		m.ui.zone_sub.text = "물결의 섬"
	if m.south_latch_t > 0.0:
		m.south_latch_t -= dt
		if m.south_latch_t <= 0.0:
			m.south_latch_t = -1.0
			south_latch()
	if m.story_open:
		return
	shore_hint(me)
	if m.lake_q >= 4 and m.south_q == 0 and not m.south_hint_seen and me.distance_to(m.lake.marks.Y) < 3.0:
		m.south_hint_seen = true
		m.show_story("", Main.STORY.SOUTH_HINT)
		return
	if m.south_q >= 1 and m.south_q <= 2:
		spawn_south_foes()
	if m.south_q == 2 and m.south_ambush_on and m.south_latch_t < 0.0 \
			and not m.enemies.any(func(e): return e.get("south_ambush", false) and not e.dead):
		m.south_latch_t = 1.2

# on the island after the turtle (the owner, 2026-10-26: stuck at the water's edge on "물결과 함께 마을 동쪽 문으로"):
# the lake does not take the water skip, so walking up to the island's shore says once per visit to the edge that
# the boat leaves from the north landing (Q); the gold "!" over the landing is in castle_zone.step_target
var at_shore := false

func on_island(me: Vector2) -> bool:
	return m.in_lake and not in_grotto() and m.lake_q >= 4 and me.y > 12.0 and me.y < Main.LAKE.SOUTH_Z

func shore_hint(me: Vector2) -> void:
	var ahead: Vector2 = me + Vector2(m.player.face).normalized() * 0.8
	var near := on_island(me) and m.lake.char_at(ahead.x, ahead.y) == "X"
	if near and not at_shore:
		m.toast("섬 북쪽 나루에서 E를 누르면 물결이 배를 저어 준다")
	at_shore = near

# ---- 물빛 동굴 under the island (after the turtle): water-skip runs, archers, the brick crab and the water pearl
func in_grotto() -> bool:
	return m.in_lake and m.player.x >= Main.GROTTO.GROTTO_X - 0.5

# steps going down on the island's south shore, at the lake's G: a stone frame over a stair that sinks step by step
# into a dark opening, with a lamp on top, so it reads as a way down from far off
func grotto_steps() -> void:
	stair_frame(m.lake.marks.G)

func stair_frame(at: Vector2, turn := 0.0, shade := 0.0, lamp_col := Color("#9fd8ff")) -> Node3D:
	var g := Node3D.new()
	var frame: Material = m.mat_color(Color("#7a7468").darkened(shade))
	var hole: MeshInstance3D = m.box(Vector3(1.1, 0.06, 1.2), m.mat_color(Color("#101418")))
	hole.position = Vector3(0, 0.03, 0)
	g.add_child(hole)
	for k in 4: # steps from the near edge going down and away, each darker
		var st: MeshInstance3D = m.box(Vector3(0.9, 0.08, 0.26), m.mat_color(Color("#a8a49a").darkened(shade + k * 0.2)))
		st.position = Vector3(0, 0.1 - k * 0.025, 0.42 - k * 0.27)
		g.add_child(st)
	for side in [-0.62, 0.62]: # low side walls
		var w: MeshInstance3D = m.box(Vector3(0.16, 0.4, 1.3), frame)
		w.position = Vector3(side, 0.2, 0)
		g.add_child(w)
	var back: MeshInstance3D = m.box(Vector3(1.4, 0.9, 0.16), frame) # the head wall at the far end
	back.position = Vector3(0, 0.45, -0.65)
	g.add_child(back)
	var lamp: MeshInstance3D = m.box(Vector3(0.22, 0.26, 0.22), m.glow_mat(lamp_col, 1.4))
	lamp.position = Vector3(0, 1.05, -0.65)
	g.add_child(lamp)
	g.rotation.y = turn
	g.position = Vector3(at.x, 0, at.y)
	m.add_child(g)
	return g

func enter_grotto() -> void:
	m.player.x = m.grotto.marks.S.x + 1.2
	m.player.z = m.grotto.marks.S.y
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.with_up_marks(m.grotto.map_tex(Main.GROTTO.GROTTO_X + Main.GROTTO.W), [m.grotto.marks.S])
	m.ui.zone_name.text = "물빛 동굴"
	m.ui.zone_sub.text = "섬 밑 물길"
	m.snap_mate()
	if not m.grotto_spawned:
		m.grotto_spawned = true
		for f in m.grotto.foes:
			m.spawn_enemy(f[0], f[1])
	clear_south_job()
	if m.grotto_q == 0:
		m.grotto_q = 1
		m.grotto_turn_told = m.south_q >= 4
		m.show_story("", Main.STORY.GROTTO_IN_WOUND if m.south_q >= 4 else Main.STORY.GROTTO_IN)
	elif m.south_q >= 4 and not m.grotto_turn_told:
		m.grotto_turn_told = true
		m.toast("벽의 물레들이 천천히 돌고 있다")
	m.save_game()

func leave_grotto() -> void:
	m.player.x = m.lake.marks.G.x
	m.player.z = m.lake.marks.G.y - 1.2
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G])
	m.ui.zone_name.text = "남쪽 호수"
	m.ui.zone_sub.text = "물결의 섬"
	m.ui.boss.visible = false
	m.snap_mate()
	m.save_game()

# E or Space beside a grotto chest
func grotto_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if not m.grotto_side and me.distance_to(m.grotto.marks.p) < 1.6:
		m.grotto_side = true
		m.grotto.opened_look(m.grotto.side_chest)
		m.player.pots += 2
		m.player.gold += 60
		m.burst(Vector3(m.grotto.marks.p.x, 0.8, m.grotto.marks.p.y), Color("#bfe6ff"), 30, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.toast("회복약 2개와 금화 60닢을 찾았다")
		m.save_game()
		return true
	if m.grotto_q == 3 and me.distance_to(m.grotto.marks.c) < 1.6:
		m.grotto_q = 4
		m.has_pearl = true
		m.grotto.opened_look(m.grotto.chest)
		m.burst(Vector3(m.grotto.marks.c.x, 0.8, m.grotto.marks.c.y), Color("#9fd8ff"), 40, 3.0)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.show_story("", Main.STORY.PEARL)
		m.save_game()
		return true
	return false

func spawn_crab() -> void:
	if m.enemies.any(func(e): return e.get("crab", false) and not e.dead):
		return
	var at: Vector2 = m.grotto.marks.C
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var shell: Material = m.mat_color(Color("#c8502a"))
	var dark: Material = m.mat_color(Color("#8a3018"))
	for part in [[Vector3(1.8, 0.6, 1.2), Vector3(0, 0.55, 0), shell], [Vector3(1.4, 0.25, 1.0), Vector3(0, 0.95, 0), dark],
			[Vector3(0.6, 0.5, 0.5), Vector3(-1.2, 0.6, 0.8), shell], [Vector3(0.6, 0.5, 0.5), Vector3(1.2, 0.6, 0.8), shell],
			[Vector3(0.25, 0.3, 0.6), Vector3(-1.2, 0.6, 1.2), dark], [Vector3(0.25, 0.3, 0.6), Vector3(1.2, 0.6, 1.2), dark]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		body.add_child(b)
	for k in 6: # three legs a side
		var leg := m.box(Vector3(0.5, 0.14, 0.14), dark)
		leg.position = Vector3(-1.05 if k < 3 else 1.05, 0.2, -0.4 + (k % 3) * 0.4)
		body.add_child(leg)
	for side in [-0.35, 0.35]: # eyes on stalks
		var stalk := m.box(Vector3(0.1, 0.35, 0.1), dark)
		stalk.position = Vector3(side, 1.15, 0.45)
		body.add_child(stalk)
		var eye := m.box(Vector3(0.18, 0.18, 0.18), m.glow_mat(Color("#ffd040"), 2.0))
		eye.position = Vector3(side, 1.38, 0.45)
		body.add_child(eye)
	m.add_child(root)
	m.enemies.append({"x": at.x, "z": at.y, "hp": 760.0, "max_hp": 760, "node": root, "shadow": m.blob(1.5), "t": 0.0,
		"atk_cd": 1.5, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"crab": true, "cave": true, "wind": 0.0, "stun": 0.0, "next": ""})

# the brick crab scuttles sideways to line up with Sora. Close in, a 0.6 s pinch (2.3 tiles);
# farther out, a 0.5 s wind-up then a fan of spat bricks (3, five below half health)
func update_crab(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var body: Node3D = node.get_node("body")
	m.ui.boss.visible = d < 12.0
	m.ui.boss_name.text = "벽돌 게"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	var angry: bool = e.hp < e.max_hp / 2.0
	body.scale = Vector3.ONE * (1.06 if e.hurt > 0.0 or e.wind > 0.0 else 1.0)
	if e.stun > 0.0:
		pass
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			if e.next == "pinch":
				m.burst(Vector3(e.x + to.x / maxf(d, 0.01) * 1.2, 0.6, e.z + to.y / maxf(d, 0.01) * 1.2), Color("#ffd28a"), 12, 2.5)
				m.sfx(900, 0.06, "square", 0.2, -400)
				if d < 2.3:
					m.player_hit(18 + m.foe_lv(), Vector2(e.x, e.z), e)
			else:
				var n := 5 if angry else 3
				for k in n:
					var a := (k - (n - 1) / 2.0) * 0.28
					m.monsters.throw_brick(Vector2(e.x, e.z), (to / maxf(d, 0.01)).rotated(a), e)
			e.atk_cd = 1.0 if angry else 1.5
	else:
		e.atk_cd -= dt
		if e.atk_cd <= 0.0 and d < 9.0:
			e.next = "pinch" if d < 2.2 else "spit"
			e.wind = 0.6 if e.next == "pinch" else 0.5
			m.pop_num(Vector3(e.x, 2.0, e.z), "!", Color("#ff5a4a") if e.next == "pinch" else Color("#ffd84a"))
		else:
			# sideways first: match Sora's x, then creep in on z
			var v := Vector2(clampf(to.x, -1.0, 1.0) * 2.4, clampf(to.y - signf(to.y) * 1.6, -1.0, 1.0) * 0.9)
			if d < 2.1:
				v = Vector2.ZERO # close enough to pinch (2.3); its wide shell would cover her any closer
			var nx: float = e.x + v.x * dt
			var nz: float = e.z + v.y * dt
			if m.walkable(nx, e.z): e.x = nx
			if m.walkable(e.x, nz): e.z = nz
			body.position.y = absf(sin(e.t * 10.0)) * 0.06 if v.length() > 0.3 else 0.0
	body.rotation.y = lerp_angle(body.rotation.y, atan2(to.x, to.y), dt * 4.0)
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func crab_beaten() -> void:
	m.grotto_q = 3
	m.ui.boss.visible = false
	m.grotto.chest.visible = true
	m.player.gold += 180
	m.gain_xp(220)
	m.show_story("", Main.STORY.CRAB_DOWN)
	m.save_game()

func turtle_beaten() -> void:
	m.lake_q = 4
	m.ui.boss.visible = false
	m.player.gold += 200
	m.gain_xp(200)
	var pip_lines := m.award_pip("turtle")
	if not pip_lines.is_empty():
		pip_lines.push_front(Main.STORY.ISLAND_PIP)
	m.show_story("", Main.STORY.ISLAND_HOME + pip_lines)
	m.set_quest("물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자")
	m.save_game()
