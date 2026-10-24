# Hardened forest: walls, grove, squirrel cages, south valley, the squirrel oak.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const OAK_HP := 10

func _init(main: Main) -> void:
	m = main

# ---- the hardened forest (story step 10)
func enter_forest() -> void:
	m.in_village = false
	m.in_forest = true
	m.story_step = maxi(m.story_step, 10)
	m.player.x = m.forest.marks.S.x + 1.2
	m.player.z = m.forest.marks.S.y
	m.ground_y = 0.0
	if not m.ui.has("outside_map"):
		m.ui.outside_map = m.ui.mini.map_tex
	m.ui.mini.map_tex = m.forest.map_tex(Main.FOREST.FOREST_X + Main.FOREST.W)
	m.ui.zone_name.text = "굳은 숲"
	m.ui.zone_sub.text = "회색 오솔길"
	if m.forest_q == 0:
		m.forest_q = 1
		for g in m.forest.goblins:
			m.spawn_enemy(g)
			m.enemies[m.enemies.size() - 1].cave = true
		for w in m.forest.wolves:
			m.spawn_wolf(w)
		m.show_story("", Main.STORY.FOREST_IN)
	spawn_cages()
	place_big_squirrel()
	if m.hollow_q == 1:
		spawn_hollow()
	if m.forest_q == 2: # the walls are open; the duel waits (GPT playtests 2 -> 9)
		m.set_quest("노을과 다시 겨루자")
	elif m.forest_q < 3:
		m.set_quest("벽돌 벽을 팔찌로 풀며 숲 동쪽 끝의 노을에게 가자 (E)")
	m.save_game()

func leave_forest() -> void:
	m.in_forest = false
	m.in_village = true
	m.player.x = m.village.marks.F.x - 1.2
	m.player.z = m.village.marks.F.y
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.village.map_tex(Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W)
	m.ui.zone_name.text = "등불 마을"
	m.ui.zone_sub.text = "동쪽 문"
	m.save_game()

func unbrick_cost() -> int:
	return 2 if m.is_night() else 3 # the crown is weaker by day

# E next to a closed brick wall: the crown turns it back into soil, and the noise wakes nearby bricks
func try_unbrick() -> bool:
	for w in m.forest.walls:
		if not w.open and Vector2(m.player.x, m.player.z).distance_to(w.pos) < 1.6:
			if not m.spend_pips(unbrick_cost()):
				return true
			m.forest.open_wall(w)
			m.burst(Vector3(w.pos.x, 0.7, w.pos.y), Color("#8a6a4a"), 36, 3.5)
			m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
			m.shake = 0.25
			m.sfx(196, 0.5, "triangle", 0.3, -60)
			m.toast("벽돌 벽이 흙으로 풀렸다")
			m.save_game()
			return true
	return false

# the moon-stone grove in the forest's north-west: E turns a stone to the next phase, reads the tablet,
# or opens the niche chest once the stones read crescent to full from east to west
func grove_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if m.forest.solved and not m.forest.chest_open and me.distance_to(m.forest.marks.c) < 1.6:
		open_grove_chest()
		return true
	var near = null # the closest stone within reach
	for st in m.forest.stones:
		if me.distance_to(st.pos) < 1.3 and (near == null or me.distance_to(st.pos) < me.distance_to(near.pos)):
			near = st
	var tablet_d := me.distance_to(m.forest.marks.t)
	if tablet_d < 1.6 and (near == null or tablet_d < me.distance_to(near.pos)):
		m.show_story("", Main.STORY.GROVE_TABLET)
		return true
	if near == null:
		return false
	near.phase = (near.phase + 1) % 4
	m.forest.show_phase(near)
	m.sfx(392 + near.phase * 98, 0.15, "triangle", 0.2)
	m.burst(Vector3(near.pos.x, 1.3, near.pos.y), Color("#dfe8ff"), 8, 1.0)
	if not m.forest.solved and m.forest.is_solved():
		m.forest.open_gate()
		m.burst(Vector3(m.forest.marks.V.x, 0.7, m.forest.marks.V.y), Color("#8a6a4a"), 36, 3.5)
		m.shake = 0.25
		m.sfx(196, 0.5, "triangle", 0.3, -60)
		m.show_story("", Main.STORY.GROVE_OPEN)
	m.save_game()
	return true

func open_grove_chest() -> void:
	m.forest.open_chest_look()
	m.player.max_hp += 15
	m.player.hp = float(m.player.max_hp)
	m.player.pots += 2
	m.player.gold += 120
	m.burst(Vector3(m.forest.marks.c.x, 0.8, m.forest.marks.c.y), Color("#e8d27a"), 40, 3.0)
	m.sfx(784, 0.12, "triangle", 0.25)
	m.show_story("", Main.STORY.GROVE_CHEST)
	m.toast("최대 체력 +15, 회복약 2개, 금화 120")
	m.save_game()

func spawn_cages() -> void:
	if m.cages_spawned:
		return
	m.cages_spawned = true
	for i in Main.FOREST.CAGES.size():
		if m.forest.freed[i]:
			continue
		var at: Vector2 = Main.FOREST.CAGES[i] + Vector2(Main.FOREST.FOREST_X, 0)
		var root := Node3D.new()
		var g := Node3D.new()
		root.add_child(g)
		var mats: Array = []
		m.brick(g, mats, Vector3(0.8, 0.1, 0.8), Vector3(0, 0.05, 0), Color("#8a8a90"))
		m.brick(g, mats, Vector3(0.8, 0.1, 0.8), Vector3(0, 0.85, 0), Color("#a8322a"))
		for k in 4: # bars at the corners
			m.brick(g, mats, Vector3(0.1, 0.7, 0.1), Vector3(-0.35 + (k % 2) * 0.7, 0.45, -0.35 + (k / 2) * 0.7), Color("#8a8a90"), false)
		g.add_child(squirrel_model(1.0)) # the squirrel inside, sitting up with its tail curled
		m.add_child(root)
		root.position = Vector3(at.x, 0, at.y)
		m.enemies.append({"x": at.x, "z": at.y, "hp": 3.0, "max_hp": 3, "node": root, "shadow": m.blob(0.6), "t": 0.0,
			"atk_cd": 99.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
			"cage": i, "cave": true, "prop": true})
		root.set_meta("mats", mats)
		root.set_meta("body", g)

func cage_hit(e: Dictionary) -> void:
	e.hp -= 1.0
	e.hurt = 0.12
	m.burst(Vector3(e.x, 0.6, e.z), Color("#a8322a"), 8, 2.0)
	m.sfx(500, 0.06, "square", 0.15, -200)
	(e.node.get_meta("body") as Node3D).rotation.y = m.rnd(-0.2, 0.2)
	if e.hp > 0.0:
		return
	e.dead = true
	e.node.queue_free()
	e.shadow.queue_free()
	m.forest.freed[int(e.cage)] = true
	m.burst(Vector3(e.x, 0.6, e.z), Color("#c8783a"), 20, 2.5)
	m.sfx(880, 0.15, "triangle", 0.2)
	var n: int = m.forest.freed.filter(func(f): return f).size()
	if n >= m.forest.freed.size():
		m.has_acorn = true
		place_big_squirrel()
		m.show_story("", Main.STORY.SQUIRRELS_DONE)
	else:
		m.toast(tr("다람쥐를 구했다 %d/5") % n)
	m.save_game()

func update_forest() -> void:
	m.forest.update_looks(Vector2(m.player.x, m.player.z), m.is_night())
	update_hollow()
	update_oak()
	if m.forest_q == 1 and not m.story_open and Vector2(m.player.x, m.player.z).distance_to(m.forest.marks.N) < 6.0:
		m.forest_q = 2
		m.show_story("", Main.STORY.NOEUL_DUEL2)
		m.after_story = m.village_life.spawn_noeul_duel.bind(true)
		m.set_quest("노을과 다시 겨루자")
		m.save_game()

func hollow_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if m.hollow_q == 0 and me.distance_to(m.forest.marks.G) < 1.6:
		if m.forest_q < 3:
			m.toast("회색 벽돌 문. 팔찌로는 풀리지 않는다")
			return true
		m.hollow_q = 1
		m.forest.open_gate_look()
		m.burst(Vector3(m.forest.marks.G.x, 0.7, m.forest.marks.G.y), Color("#9a9aa0"), 40, 3.0)
		m.shake = 0.25
		m.sfx(220, 0.5, "triangle", 0.3, -80)
		m.show_story("", Main.STORY.HOLLOW_GATE)
		spawn_hollow()
		place_big_squirrel()
		m.save_game()
		return true
	for l in m.forest.mem_lamps:
		if not l.lit and me.distance_to(l.pos) < 1.6:
			if not m.spend_pips(1):
				return true
			m.forest.light_mem(l)
			m.burst(l.light.position, Color("#ffc46a"), 24, 2.5)
			m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
			m.sfx(523, 0.4, "sine", 0.3, 300)
			var n: int = m.forest.mem_lamps.filter(func(x): return x.lit).size()
			m.show_story("", [Main.STORY.HOLLOW_MEM1, Main.STORY.HOLLOW_MEM2, Main.STORY.HOLLOW_MEM3][n - 1])
			m.save_game()
			return true
	for dr in m.forest.doors:
		if not dr.open and me.distance_to(dr.pos) < 1.6:
			if not m.spend_pips(unbrick_cost()):
				return true
			m.forest.open_door(dr)
			m.burst(Vector3(dr.pos.x, 0.7, dr.pos.y), Color("#8a6a4a"), 36, 3.5)
			m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
			m.shake = 0.25
			m.sfx(196, 0.5, "triangle", 0.3, -60)
			m.toast(tr("%s 문이 흙으로 풀렸다") % tr(dr.pic))
			m.save_game()
			return true
	for i in m.forest.boxes.size():
		var b: Dictionary = m.forest.boxes[i]
		if not b.open and me.distance_to(b.pos) < 1.6:
			if i == 1 and m.hollow_q < 2:
				m.toast("굴 안이 회색 가루로 막혀 있다. 가운데 마당이 아직 술렁인다")
				return true
			open_hollow_box(i)
			return true
	return false

func hollow_squirrel_lines() -> Array:
	var sq: Array = Main.STORY.HOLLOW_SQUIRREL.duplicate()
	if not m.forest.freed.has(true): # no cage opened yet: no thanks for it (GPT playtests 2 -> 9)
		sq[sq.size() - 1] = Main.STORY.HOLLOW_SQUIRREL_NONE
	return sq

func open_hollow_box(i: int) -> void:
	var b: Dictionary = m.forest.boxes[i]
	m.forest.open_box_look(b)
	m.burst(Vector3(b.pos.x, 0.8, b.pos.y), Color("#e8d27a"), 40, 3.0)
	m.sfx(784, 0.12, "triangle", 0.25)
	match i:
		0: # the squirrels' winter store
			var n := 3 if m.has_acorn else 2
			m.player.pots += n
			m.player.gold += 40
			m.show_story("", hollow_squirrel_lines())
			m.toast(tr("회복약 %d개, 금화 40") % n)
		1: # Noeul's hollow
			m.hollow_q = 3
			m.show_story("", Main.STORY.HOLLOW_LETTER)
			m.toast("열셋째 등불 · 마을의 심지에게 가져가자")
		2: # Hangyeol's pack
			m.player.max_hp += 10
			m.player.hp = float(m.player.max_hp)
			m.player.gold += 80
			m.show_story("", Main.STORY.HOLLOW_MOON)
			m.toast("최대 체력 +10, 금화 80")
	m.save_game()

# the valley's monsters wake once the grey gate is open; they do not come back
func spawn_hollow() -> void:
	if m.hollow_spawned:
		return
	m.hollow_spawned = true
	for sp in m.forest.south:
		match sp.kind:
			"g", "s":
				m.spawn_enemy(sp.pos)
				if sp.kind == "s":
					m.give_shield(m.enemies[m.enemies.size() - 1])
			"a":
				m.spawn_enemy(sp.pos, true)
			"w":
				m.spawn_wolf(sp.pos)
			"j":
				m.monsters.spawn_hog(sp.pos)

func update_hollow() -> void:
	var me := Vector2(m.player.x, m.player.z)
	if m.hollow_q < 1 or m.player.z < 21.5:
		if m.ui.zone_sub.text == "잠든 골짜기":
			m.ui.zone_sub.text = "회색 오솔길"
		return
	if m.ui.zone_sub.text != "잠든 골짜기":
		m.ui.zone_sub.text = "잠든 골짜기"
	if m.story_open:
		return
	if not m.stream_told and m.player.z > 25.5:
		m.stream_told = true
		m.show_story("", Main.STORY.HOLLOW_STREAM)
		return
	if m.hollow_q == 1 and m.forest.mem_lamps.all(func(l): return l.lit) and me.distance_to(m.forest.marks.C) < 5.0 \
			and not m.enemies.any(func(e): return e.get("cloak", false) and not e.dead):
		m.show_story("", Main.STORY.HOLLOW_CLOAK)
		m.after_story = m.village_life.spawn_noeul_duel.bind(false, true)
		return
	var near := -1
	for i in m.forest.doors.size():
		if not m.forest.doors[i].open and me.distance_to(m.forest.doors[i].pos) < 1.6:
			near = i
	if near != m.door_seen:
		m.door_seen = near
		if near >= 0:
			m.toast(tr("문에 %s이 있다") % tr(m.forest.doors[near].pic))

func cloak_beaten() -> void:
	m.hollow_q = 2
	m.ui.boss.visible = false
	m.player.gold += 120
	m.gain_xp(200)
	m.show_story("", Main.STORY.HOLLOW_CLOAK_DONE)
	m.save_game()

func simji_lantern() -> void:
	m.hollow_q = 4
	var pip_lines := m.award_pip("lantern") # the pip took the place of max HP +15 (v0.0.47)
	if not pip_lines.is_empty():
		pip_lines.push_front(Main.STORY.SIMJI_LANTERN_PIP)
	m.player.hp = float(m.player.max_hp)
	m.player.gold += 150
	m.show_story("res://art/story/13_thirteenth_lamp.jpg", Main.STORY.SIMJI_LANTERN + pip_lines)
	hang_thirteenth()
	m.save_game()

# the thirteenth lantern on the post by the village's east gate: lit, so it is a rest spot at night
func hang_thirteenth() -> void:
	if m.thirteenth != null:
		return
	var glass: Material = m.glow_mat(Color("#ffc46a"), 4.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	var at: Vector2 = m.village.marks.F + Vector2(-1.0, -1.2)
	m.lantern(at.x, at.y, m.mat_color(Color("#3b2a1e")), glass)
	m.thirteenth = m.lanterns[m.lanterns.size() - 1]
	m.rocks.append({"x": at.x, "z": at.y, "r": 0.25})

func oak_ready() -> bool:
	return m.has_acorn and m.hollow_q >= 1

# by the old oak's warm roots Sora rests as by a lit lantern at night, day or night
func oak_warm() -> bool:
	return m.in_forest and m.oak_q >= 1 and Vector2(m.player.x, m.player.z).distance_to(Main.FOREST.OAK_C) < 3.2

func forest_map() -> ImageTexture:
	return m.forest.map_tex(Main.FOREST.FOREST_X + Main.FOREST.W)

func oak_hogs_alive() -> Array:
	return m.enemies.filter(func(e): return e.get("oak", false) and not e.dead)

func oak_loose() -> int:
	return m.forest.knots.filter(func(k): return k.open).size()

# a squirrel sitting up with its tail curled (the cages' one; x1.3 for the big one); "body" bobs as it breathes
func squirrel_model(s: float) -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	g.name = "body"
	root.add_child(g)
	var fur := m.mat_color(Color("#c8783a"))
	for part in [[Vector3(0.22, 0.26, 0.2), Vector3(0, 0.25, 0)], [Vector3(0.18, 0.16, 0.18), Vector3(0, 0.45, 0.04)], [Vector3(0.14, 0.34, 0.12), Vector3(0, 0.36, -0.18)]]:
		var b := m.box(part[0], fur)
		b.position = part[1]
		g.add_child(b)
	root.scale = Vector3.ONE * s
	return root

func oak_seat(i: int) -> Vector3:
	var s: Vector2 = Main.FOREST.OAK_SEATS[i]
	return Vector3(Main.FOREST.OAK_C.x + s.x, 2.6, Main.FOREST.OAK_C.y + s.y)

# where the squirrels are for oak_q: by the gap, by a knot, or all five in the green crown
func place_big_squirrel() -> void:
	if m.big_squirrel == null:
		m.big_squirrel = squirrel_model(1.3)
		m.add_child(m.big_squirrel)
		for k in 4:
			var s := squirrel_model(1.0)
			m.add_child(s)
			m.oak_kin.append(s)
	var on := oak_ready()
	m.big_squirrel.visible = on
	for s in m.oak_kin:
		s.visible = on and m.oak_q >= 2
	if not on:
		return
	match m.oak_q:
		0:
			m.big_squirrel.position = Vector3(Main.FOREST.SQUIRREL_AT.x, 0, Main.FOREST.SQUIRREL_AT.y)
			m.big_squirrel.rotation.y = PI / 2.0 # at the gap, its tail to the path
		1:
			m.big_squirrel.position = Vector3(199.5, 0, 12.5)
			m.big_squirrel.rotation.y = 0.6
		_:
			m.big_squirrel.position = oak_seat(0)
			m.big_squirrel.rotation.y = 0.0
			for k in 4:
				m.oak_kin[k].position = oak_seat(k + 1)
				m.oak_kin[k].rotation.y = 0.0

# E in the forest, before the valley's keys: the big squirrel, a root knot, or the green oak
func oak_key() -> bool:
	if not oak_ready():
		return false
	var me := Vector2(m.player.x, m.player.z)
	if m.oak_q == 0:
		if me.distance_to(Main.FOREST.SQUIRREL_AT) < 1.6:
			m.show_story("", Main.STORY.OAK_CALL)
			m.after_story = open_oak_gap
			return true
		return false
	var near := -1
	for i in m.forest.knots.size():
		var k: Dictionary = m.forest.knots[i]
		if not k.open and me.distance_to(k.pos) < 1.6 and (near < 0 or me.distance_to(k.pos) < me.distance_to(m.forest.knots[near].pos)):
			near = i
	if near >= 0:
		untie_knot(near)
		return true
	if m.oak_q >= 2 and not m.oak_hush and me.distance_to(Main.FOREST.OAK_C) < 2.8:
		m.show_story("", Main.STORY.OAK_AFTER)
		return true
	return false

# the squirrel slips into the gap and a hardened tree creaks aside (0.6 s); it runs on to sit by a knot
func open_oak_gap() -> void:
	if m.big_squirrel == null:
		place_big_squirrel()
	m.oak_q = 1
	m.forest.oak_open = true
	var gp: Node3D = m.forest.oak_gap
	var tw := m.create_tween().set_parallel()
	tw.tween_property(gp, "position", gp.position + Main.FOREST.GAP_SHIFT, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(gp, "rotation:x", Main.FOREST.GAP_TILT, 0.6).set_trans(Tween.TRANS_SINE)
	for s in m.forest.warm:
		s.visible = true
	m.burst(Vector3(gp.position.x, 0.8, gp.position.z), Color("#9a9aa0"), 16, 1.5)
	m.sfx(150, 0.5, "triangle", 0.18, -40)
	var sq := m.big_squirrel
	sq.rotation.y = PI / 2.0
	var run := m.create_tween()
	run.tween_property(sq, "position", Vector3(196.6, 0, 12), 0.5)
	run.tween_property(sq, "position", Vector3(199.5, 0, 12.5), 1.1)
	run.tween_callback(func(): sq.rotation.y = 0.6)
	m.ui.mini.map_tex = forest_map()
	m.toast("다람쥐를 따라 나무 틈 안쪽으로 가자")
	m.save_game()

# E by a tied knot: 1 pip, the bricks crumble to soil and the brown root draws in toward the trunk
func untie_knot(i: int) -> void:
	var done := oak_loose()
	if done == 2 and not m.oak_hogs_beaten and (not m.oak_hogs_up or not oak_hogs_alive().is_empty()):
		if not m.oak_hogs_up: # a fight cut short by a load: they roll out again (GPT playtests 2 -> 9)
			oak_hogs_out()
		m.toast("고슴도치부터 막자")
		return
	if not m.spend_pips(1):
		return
	var k: Dictionary = m.forest.knots[i]
	var root: MeshInstance3D = m.forest.untie(i)
	m.create_tween().tween_property(root, "position:z", Main.FOREST.ROOT_IN, 0.5).set_trans(Tween.TRANS_SINE)
	m.burst(Vector3(k.pos.x, 0.4, k.pos.y), Color("#8a6a4a"), 24, 2.5)
	m.burst(Vector3(k.pos.x, 0.3, k.pos.y), Color("#f2ead8"), 6, 0.9)
	m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 12, 1.5)
	m.sfx(330, 0.4, "sine", 0.3, 200)
	m.ui.mini.map_tex = forest_map()
	done += 1
	match done:
		1:
			m.forest.show_leaf()
			m.show_story("", Main.STORY.OAK_KNOT1)
			m.after_story = func(): m.toast(tr("벽돌 뿌리 매듭이 풀렸다 %d/3") % 1)
		2:
			m.show_story("", Main.STORY.OAK_HOGS)
			m.after_story = func(): m.toast(tr("벽돌 뿌리 매듭이 풀렸다 %d/3") % 2)
			m.get_tree().create_timer(0.8).timeout.connect(oak_hogs_out)
		_:
			oak_green()
	m.save_game()

# the two hedgehogs roll out from under the roots (once; they do not come back)
func oak_hogs_out() -> void:
	if not m.in_forest or m.oak_q != 1 or oak_loose() != 2 or not oak_hogs_alive().is_empty():
		return
	m.oak_hogs_up = true
	for at in m.forest.oak_hogs:
		m.monsters.spawn_hog(at)
		m.enemies[m.enemies.size() - 1].oak = true
		m.burst(Vector3(at.x, 0.4, at.y), Color("#8a6a4a"), 14, 2.0)
	m.sfx(140, 0.25, "square", 0.15, -40)

# the last knot: the reward is kept at once, the lines wait 1.5 s while the tree breathes (GPT's note)
func oak_green() -> void:
	m.oak_q = 2
	m.oak_hush = true
	var first := not m.has_sprout
	if first:
		m.has_sprout = true
		m.player.max_hp += OAK_HP
		m.player.hp = minf(float(m.player.max_hp), m.player.hp + OAK_HP)
	m.player.gold += 60
	m.gain_xp(60)
	var lines: Array = Main.STORY.OAK_GREEN.duplicate()
	if not first: # a new round: the sprout came along
		lines[lines.size() - 1] = Main.STORY.OAK_GREEN_ROUND
	oak_breathe()
	m.get_tree().create_timer(1.5).timeout.connect(oak_greened.bind(lines))

func oak_greened(lines: Array) -> void:
	m.oak_hush = false
	m.forest.set_green(true)
	m.burst(Vector3(Main.FOREST.OAK_C.x, 1.5, Main.FOREST.OAK_C.y + 1.0), Color("#8a6a4a"), 30, 2.5) # the grey bark falls as soil
	oak_kin_come()
	if m.in_forest:
		m.ui.mini.map_tex = forest_map()
		m.show_story("", lines)
		m.after_story = show_sprout

# one breath in and out: the crown lifts a little and settles, the low branch rises, its two leaves stir for the
# first time, one cream puff of steam from the roots; only a creak and a hush of water to hear
func oak_breathe() -> void:
	var crown: Node3D = m.forest.oak.get_meta("crown")
	var tw := m.create_tween()
	tw.tween_property(crown, "scale", Vector3(1.03, 1.14, 1.03), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(crown, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	var br: Node3D = m.forest.oak.get_meta("branch")
	m.create_tween().tween_property(br, "rotation:x", -0.12, 0.9).set_trans(Tween.TRANS_SINE)
	var twigs: Array = m.forest.oak.get_meta("twigs")
	for k in twigs.size():
		var tw2: MeshInstance3D = twigs[k]
		var st := m.create_tween()
		st.tween_interval(0.35 + 0.2 * k)
		st.tween_callback(func(): (tw2.material_override as StandardMaterial3D).albedo_color = m.forest.tree_col(Color("#9ad46a")))
		for a in [0.35, -0.3, 0.2, 0.0]:
			st.tween_property(tw2, "rotation:z", a if k == 0 else -a, 0.16)
	m.burst(Vector3(Main.FOREST.OAK_C.x, 0.15, Main.FOREST.OAK_C.y + 1.1), Color("#f2ead8"), 10, 1.2)
	m.sfx(120, 0.6, "triangle", 0.08, 30)
	m.shore.water_hush(3)

# the four other squirrels come back through the gap and climb up beside the big one
func oak_kin_come() -> void:
	if m.big_squirrel == null:
		place_big_squirrel()
	var bt := m.create_tween()
	bt.tween_property(m.big_squirrel, "position", oak_seat(0), 0.5)
	bt.tween_callback(func(): m.big_squirrel.rotation.y = 0.0)
	for k in m.oak_kin.size():
		var s: Node3D = m.oak_kin[k]
		s.visible = true
		s.position = Vector3(196.4, 0, 12)
		s.rotation.y = PI / 2.0
		var tw := m.create_tween()
		tw.tween_interval(0.25 * k)
		tw.tween_property(s, "position", Vector3(199.2, 0, 12.7), 0.7)
		tw.tween_property(s, "position", oak_seat(k + 1), 0.45)
		tw.tween_callback(func(): s.rotation.y = 0.0)

# the sprouted acorn held up over Sora for a moment: brown body, dark cap, a slanted stem, two flat leaves
func show_sprout() -> void:
	var g := Node3D.new()
	for p in [[Vector3(0.2, 0.24, 0.2), Vector3(0, 0, 0), m.mat_color(Color("#996039"))],
			[Vector3(0.26, 0.08, 0.26), Vector3(0, 0.15, 0), m.mat_color(Color("#5a4030"))],
			[Vector3(0.04, 0.2, 0.04), Vector3(0.03, 0.28, 0), m.mat_color(Color("#9ad46a"))],
			[Vector3(0.16, 0.03, 0.08), Vector3(-0.05, 0.37, 0), m.mat_color(Color("#9ad46a"))],
			[Vector3(0.16, 0.03, 0.08), Vector3(0.12, 0.4, 0), m.mat_color(Color("#9ad46a"))],
			[Vector3(0.05, 0.05, 0.05), Vector3(0.05, 0.4, 0), m.glow_mat(Color("#c8f09a"), 0.6)]]:
		var b := m.box(p[0], p[2])
		b.position = p[1]
		g.add_child(b)
	g.scale = Vector3.ONE * 1.6
	g.position = Vector3(m.player.x, m.ground_y + 2.3, m.player.z)
	m.add_child(g)
	var tw := m.create_tween()
	tw.tween_property(g, "position:y", g.position.y + 0.3, 2.0)
	tw.tween_callback(g.queue_free)

func update_oak() -> void:
	if m.oak_hogs_up and not m.oak_hogs_beaten and oak_hogs_alive().is_empty():
		m.oak_hogs_beaten = true
		m.save_game()
	if m.big_squirrel != null and m.big_squirrel.visible and m.oak_q < 2: # breathing, 0.04 up and down every 0.6 s
		(m.big_squirrel.get_node("body") as Node3D).position.y = 0.04 * absf(sin(m.t * PI / 0.6))
	if not oak_ready():
		return
	var me := Vector2(m.player.x, m.player.z)
	var inside: bool = me.x > 197.5 and me.x < 206.5 and me.y > 6.5 and me.y < 13.5
	m.forest.crown_fade(0.5 if inside and me.y < 9.5 else 0.0)
	if m.story_open or m.fade_rect.color.a > 0.0:
		return
	if m.oak_q == 0 and not m.squirrel_seen and me.distance_to(Main.FOREST.SQUIRREL_AT) < 6.0:
		m.squirrel_seen = true
		m.toast("큰 다람쥐가 회색 나무 틈을 앞발로 긁고 있다")
	if m.oak_q == 1 and inside and not m.oak_told and oak_loose() == 0:
		m.oak_told = true
		m.show_story("", Main.STORY.OAK_IN)
		m.after_story = func(): m.toast("나무 곁에서는 낮에도 눈금이 찬다")

func oak_journal() -> String:
	match m.oak_q:
		0: return tr("큰 다람쥐를 찾아서")
		1: return tr("뿌리 매듭 %d/3") % oak_loose()
	return tr("끝")

# load the clearing (old saves: the gap shut, the big squirrel by it if the gate is open); hogs left over go
func load_oak(d: Dictionary) -> void:
	m.oak_q = int(d.get("oak_q", 0))
	m.has_sprout = bool(d.get("has_sprout", false))
	m.oak_hogs_beaten = bool(d.get("oak_hogs", m.oak_q >= 2))
	m.oak_hogs_up = false
	var loose: Array = [false, false, false]
	var ks: Array = d.get("oak_knots", [])
	for i in mini(ks.size(), 3):
		loose[i] = bool(ks[i])
	if m.oak_q >= 2:
		loose = [true, true, true]
	elif m.oak_q == 0:
		loose = [false, false, false]
	m.oak_told = false
	m.squirrel_seen = false
	m.oak_hush = false
	for e in oak_hogs_alive():
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
	m.forest.oak_look(m.oak_q >= 1, loose, m.oak_q >= 2)
	place_big_squirrel()
	if m.in_forest:
		m.ui.mini.map_tex = forest_map()

func noeul_turned() -> void:
	m.forest_q = 3
	m.join_noeul()
	m.ui.boss.visible = false
	m.player.gold += 150
	m.gain_xp(250)
	m.show_story("res://art/story/10_jae_turns.jpg", Main.STORY.NOEUL_TURNS)
	m.set_quest("숲 동쪽 끝 길로, 바람 언덕에 가자")
	m.save_game()
