# Side games: the moon trial, the pinwheel race, fishing.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const TRIAL_WAVES := [
	["g", "g", "g", "g"],
	["g", "g", "g", "a", "a"],
	["w", "w", "w"],
	["s", "s", "a", "a", "g"],
	["W", "w", "w"], # W: the trial warden, a big goblin
]
const RACE_TIME := 25.0

func _init(main: Main) -> void:
	m = main

func build_trial() -> void:
	var at: Vector2 = m.hill.marks.R
	m.trial_stone = Node3D.new()
	var stone: Material = m.mat_color(Color("#8a8a94"))
	var core: MeshInstance3D = m.box(Vector3(0.7, 1.3, 0.7), stone)
	core.position = Vector3(0, 0.65, 0)
	m.trial_stone.add_child(core)
	var moon: MeshInstance3D = m.box(Vector3(0.4, 0.4, 0.08), m.glow_mat(Color("#dfe8ff"), 1.2))
	moon.position = Vector3(0, 1.05, 0.36)
	m.trial_stone.add_child(moon)
	for k in 6: # the ring of low standing stones
		var a := k * TAU / 6.0
		var post: MeshInstance3D = m.box(Vector3(0.3, 0.6, 0.3), stone)
		post.position = Vector3(cos(a) * 2.2, 0.3, sin(a) * 2.2)
		m.trial_stone.add_child(post)
	var glow := OmniLight3D.new() # a pale moonlight over the ring
	glow.light_color = Color("#bcd6ff")
	glow.light_energy = 1.8
	glow.omni_range = 7.0
	glow.position = Vector3(0, 2.2, 0)
	m.trial_stone.add_child(glow)
	m.trial_stone.position = Vector3(at.x, 0, at.y)
	m.add_child(m.trial_stone)
	m.rocks.append({"x": at.x, "z": at.y, "r": 0.45})

func trial_key() -> bool:
	if m.trial_stone == null or Vector2(m.player.x, m.player.z).distance_to(m.hill.marks.R) > 1.6:
		return false
	if m.hill_q < 3:
		m.toast("시련의 돌은 아직 잠들어 있다")
		return true
	if m.trial_wave > 0:
		return true
	m.trial_wave = 1
	m.trial_wait = 1.5
	m.trial_start = m.t
	m.show_story("", Main.STORY.TRIAL_IN)
	return true

func trial_foes() -> Array:
	return m.enemies.filter(func(e): return e.get("trial", false) and not e.dead)

func spawn_trial_wave() -> void:
	var c: Vector2 = m.hill.marks.R
	var list: Array = TRIAL_WAVES[m.trial_wave - 1]
	for i in list.size():
		var at := c + Vector2(1.5, 0)
		for tries in 30:
			var a := m.rnd(0, TAU)
			var cand := c + Vector2(cos(a), sin(a)) * m.rnd(4.0, 5.5)
			if m.walkable(cand.x, cand.y):
				at = cand
				break
		var kind: String = list[i]
		if kind == "w":
			m.spawn_wolf(at)
		else:
			m.spawn_enemy(at, kind == "a")
		var e: Dictionary = m.enemies[m.enemies.size() - 1]
		e.trial = true
		e.cave = true
		if kind == "s":
			m.give_shield(e)
		if kind == "W":
			e.hp = 300.0 + m.foe_lv() * 30
			e.max_hp = int(e.hp)
			e.size_k = 1.7 # update_enemies sets the scale every frame, so the warden's size goes through this
			var mats: Array = e.node.get_meta("mats")
			mats[2].albedo_color = Color("#6a6a78")
			mats[5].albedo_color = Color("#dfe8ff")
		m.burst(Vector3(at.x, 0.6, at.y), Color("#dfe8ff"), 12, 2.0)
	m.toast(tr("달빛 시련 %d/5") % m.trial_wave)
	m.sfx(330 + m.trial_wave * 60, 0.3, "triangle", 0.2)

func update_trial(dt: float) -> void:
	if m.trial_wave == 0:
		return
	if not m.in_hill or Vector2(m.player.x, m.player.z).distance_to(m.hill.marks.R) > 9.0:
		end_trial("선돌에서 멀어져 시련이 끝났다")
		return
	if m.story_open:
		return
	if m.trial_wait > 0.0:
		m.trial_wait -= dt
		if m.trial_wait <= 0.0:
			spawn_trial_wave()
		return
	if trial_foes().is_empty():
		if m.trial_wave >= TRIAL_WAVES.size():
			clear_trial()
		else:
			m.trial_wave += 1
			m.trial_wait = 2.5

func end_trial(msg: String) -> void:
	for e in trial_foes():
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
	m.trial_wave = 0
	m.trial_wait = 0.0
	m.toast(msg)

func clear_trial() -> void:
	var secs := m.t - m.trial_start
	var first := m.trial_best <= 0.0
	m.trial_wave = 0
	if first:
		m.player.max_hp += 20
		m.player.atk += 3
		m.player.gold += 300
		m.show_story("", Main.STORY.TRIAL_DONE)
	else:
		m.player.gold += 80
	m.player.hp = float(m.player.max_hp)
	if first or secs < m.trial_best:
		m.trial_best = secs
	m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#dfe8ff"), 40, 4.0)
	m.sfx(784, 0.3, "triangle", 0.25)
	m.toast(tr("달빛 시련을 마쳤다: %d분 %02d초") % [int(secs) / 60, int(secs) % 60] + ("" if first else tr(" (금화 +80)")))
	m.trial_won = true
	m.moon_tokens.earn(m.moon_tokens.HILL) # the hill deed (also in a new round, when the best time was kept)
	m.moon_tokens.refresh_quest() # the castle gate asks for the mill too: the line moves on (earn does it only for a new token)
	m.save_game()

func build_race() -> void:
	var hx := float(Main.HILL.HILL_X)
	var post := Node3D.new()
	var wood: Material = m.mat_color(Color("#7a5a3a"))
	var pole: MeshInstance3D = m.box(Vector3(0.18, 1.6, 0.18), wood)
	pole.position = Vector3(0, 0.8, 0)
	post.add_child(pole)
	var flag: MeshInstance3D = m.box(Vector3(0.7, 0.4, 0.06), m.mat_color(Color("#e8b018")))
	flag.position = Vector3(0.38, 1.4, 0)
	post.add_child(flag)
	post.position = Vector3(hx + Main.RACE_POST.x, 0, Main.RACE_POST.y)
	m.add_child(post)
	m.rocks.append({"x": hx + Main.RACE_POST.x, "z": Main.RACE_POST.y, "r": 0.3})
	var cols := [Color("#e84a4a"), Color("#4a8ae8"), Color("#e8c84a"), Color("#4ac87a")]
	for p in Main.RACE_WHEELS:
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
		g.position = Vector3(hx + p.x, 0, p.y)
		g.visible = false
		m.add_child(g)
		m.race_nodes.append(g)

func race_key() -> bool:
	if m.race_on or Vector2(m.player.x, m.player.z).distance_to(Vector2(Main.HILL.HILL_X + Main.RACE_POST.x, Main.RACE_POST.y)) > 1.6:
		return false
	m.race_on = true
	m.race_left = RACE_TIME
	m.race_got = []
	m.race_quest = m.quest_raw
	for g in m.race_nodes:
		g.visible = true
	m.sfx(523, 0.12, "triangle", 0.2)
	m.get_tree().create_timer(0.15).timeout.connect(func(): m.sfx(784, 0.2, "triangle", 0.2))
	m.toast("바람개비 다섯 개를 지나자!")
	return true

func update_race(dt: float) -> void:
	for g in m.race_nodes:
		if g.visible:
			g.get_node("hub").rotation.z += dt * 6.0
	if not m.race_on:
		return
	if not m.in_hill or m.in_cloud() or m.in_castle():
		end_race("경주를 그만두었다")
		return
	m.race_left -= dt
	for i in m.race_nodes.size():
		if i in m.race_got:
			continue
		var w := Vector2(Main.HILL.HILL_X + Main.RACE_WHEELS[i].x, Main.RACE_WHEELS[i].y)
		if Vector2(m.player.x, m.player.z).distance_to(w) < 1.0:
			m.race_got.append(i)
			m.race_nodes[i].visible = false
			m.burst(Vector3(w.x, 1.3, w.y), Color("#f2ead8"), 14, 2.0)
			m.sfx(660 + m.race_got.size() * 80, 0.12, "triangle", 0.2)
	m.set_quest(tr("바람개비 경주 %d/5 · %d초") % [m.race_got.size(), int(ceil(m.race_left))])
	if m.race_got.size() == Main.RACE_WHEELS.size():
		var secs := RACE_TIME - m.race_left
		var first := not m.has_shoes
		end_race(tr("바람개비 경주 성공! %.1f초") % secs)
		if first:
			m.has_shoes = true
			m.show_story("", Main.STORY.RACE_WIN)
		else:
			m.player.gold += 30
		if m.race_best <= 0.0 or secs < m.race_best:
			m.race_best = secs
		m.save_game()
	elif m.race_left <= 0.0:
		end_race("시간이 다 됐다. 깃대에서 다시 해 보자")

func end_race(msg: String) -> void:
	m.race_on = false
	for g in m.race_nodes:
		g.visible = false
	m.set_quest(m.race_quest)
	m.toast(msg)

func fish_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if m.in_lake_main() and m.lake_q >= 2 and me.distance_to(m.lake.marks.f) <= 1.5:
		m.fish_at = m.lake.marks.f
	elif m.in_village and m.in_house < 0 and me.distance_to(m.village.marks.f) <= 1.5:
		m.fish_at = m.village.marks.f
	elif m.fish_state == "":
		return false
	match m.fish_state:
		"":
			m.fish_state = "wait"
			m.fish_t = m.rnd(2.0, 5.0) * (0.7 if m.has_bait else 1.0) # Yeoul's bait pouch: a bite 30% sooner
			if m.bobber == null:
				m.bobber = Node3D.new()
				var b: MeshInstance3D = m.box(Vector3(0.14, 0.14, 0.14), m.mat_color(Color("#e84a4a")))
				m.bobber.add_child(b)
				m.add_child(m.bobber)
			m.bobber.visible = true
			var cast := Vector2(0, 2.0) if m.fish_at == m.lake.marks.f else Vector2(2.0, 0) # the pier looks east over the pond
			m.bobber.position = Vector3(m.fish_at.x + cast.x, -0.25, m.fish_at.y + cast.y)
			m.sfx(300, 0.15, "noise", 0.08, -100)
			if m.south_q >= 4 and not m.south_fish_told and m.fish_at == m.lake.marks.f:
				m.south_fish_told = true
				m.toast("다시 도는 물을 따라 바다 물고기가 올라온다")
			else:
				m.toast("낚싯줄을 던졌다. 찌가 흔들리면 E!")
		"wait":
			m.fish_state = ""
			m.bobber.visible = false
			m.toast("너무 일찍 당겼다")
		"bite":
			land_fish()
	return true

func land_fish() -> void:
	m.fish_state = ""
	m.bobber.visible = false
	var total := 0
	for i in Main.FISH.size():
		total += fish_weight(i)
	var roll := m.rng.randi() % total
	var k := 0
	for i in Main.FISH.size():
		roll -= fish_weight(i)
		if roll < 0:
			k = i
			break
	var fresh: bool = not m.fish_kinds[k]
	m.fish_kinds[k] = true
	var n: int = m.fish_kinds.count(true)
	m.player.gold += 5 + k * 5
	m.burst(Vector3(m.bobber.position.x, 0.4, m.bobber.position.z), Color("#9fd4ff"), 16, 2.0)
	m.sfx(660 + k * 80, 0.15, "triangle", 0.2)
	m.toast(tr("%s을(를) 낚았다! (%d/5 종류)") % [tr(Main.FISH[k][0]), n] if fresh else tr("%s을(를) 낚았다") % tr(Main.FISH[k][0]))
	if fresh and n == Main.FISH.size():
		m.player.gold += 100
		m.player.max_hp += 10
		m.player.hp = float(m.player.max_hp)
		m.show_story("", Main.STORY.FISH_ALL)
	m.save_game()

func update_fishing(dt: float) -> void:
	if m.fish_state == "":
		return
	if not (m.in_lake_main() or m.in_village) or Vector2(m.player.x, m.player.z).distance_to(m.fish_at) > 2.0:
		m.fish_state = ""
		m.bobber.visible = false
		return
	m.fish_t -= dt
	m.bobber.position.y = -0.25 + (sin(m.t * 30.0) * 0.06 if m.fish_state == "bite" else sin(m.t * 2.0) * 0.02)
	if m.fish_state == "wait" and m.fish_t <= 0.0:
		m.fish_state = "bite"
		m.fish_t = 0.7
		m.pop_num(m.bobber.position + Vector3(0, 0.8, 0), "!", Color("#ffd84a"))
		m.sfx(500, 0.1, "noise", 0.12, -300)
	elif m.fish_state == "bite" and m.fish_t <= 0.0:
		m.fish_state = ""
		m.bobber.visible = false
		m.toast("물고기가 미끼만 먹고 달아났다")

func fish_weight(i: int) -> int:
	return 15 if i == 4 and m.south_q >= 4 else int(Main.FISH[i][1])
