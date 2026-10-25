# Waking shore (chapter 1): the reed basket, floats, snag, shore foes, Bori's lines.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const SHORE_HP := 10

func _init(main: Main) -> void:
	m = main

func shore_foes_alive() -> bool:
	return m.enemies.any(func(e): return e.get("shore", false) and not e.dead)

# E within 1.4 tiles of the basket (story step 3 on)
func shore_key() -> bool:
	if Vector2(m.player.x, m.player.z).distance_to(Main.MARSH.BASKET_AT) >= 1.4:
		return false
	if m.shore_q <= 1:
		if m.shore_wave >= 0:
			return true
		m.shore_q = 1
		if not m.shore_seen:
			m.shore_seen = true
			m.show_story("", Main.STORY.SHORE_BASKET)
			m.after_story = func(): m.toast("팔찌를 대 보자 (E)")
			return true
		if not m.spend_pips(1):
			return true
		var b: Vector2 = Main.MARSH.BASKET_AT
		m.burst(Vector3(b.x, m.height_at(b.x, b.y) + 0.3, b.y), Color("#c9a066"), 20, 2.0)
		m.sfx(196, 0.3, "triangle", 0.25, -60)
		m.shore_wave = 0
		m.shore_up = false
		m.show_story("", Main.STORY.SHORE_WAKE)
		m.after_story = spawn_shore_wave.bind(0)
		return true
	if m.shore_q == 3 and m.shore_float.is_empty():
		if m.story_step < 5:
			m.toast("물길이 막혀 있다. 벽돌왕을 넘어뜨린 뒤에 띄우자")
			return true
		if not m.is_night():
			m.toast("등불 바구니는 밤에 띄우자 (21시 → 4시)")
			return true
		if not m.spend_pips(1):
			return true
		m.shore_float = {"d": 0.0, "snag": 0, "wait": false, "up": false, "t": 0.0, "lit": false, "stop": false, "wt": 0.0}
		m.marsh.set_float(m.marsh.path[0], false)
		m.sfx(330, 0.2, "triangle", 0.15)
		return true
	return false

func spawn_shore_foe(at: Vector2, archer: bool) -> void:
	m.spawn_enemy(at, archer)
	var e: Dictionary = m.enemies[m.enemies.size() - 1]
	e.cave = true # no respawn
	e.shore = true
	e.atk_cd = 1.5
	var y := m.height_at(at.x, at.y)
	m.burst(Vector3(at.x, y + 0.4, at.y), Color("#c9a066"), 20, 2.0)
	m.pop_num(Vector3(at.x, y + 1.3, at.y), "!", Color("#ff5a4a"))
	m.sfx(110, 0.25, "square", 0.25, 80)

func spawn_shore_wave(i: int) -> void:
	m.shore_wave = i
	m.shore_up = true
	m.shore_t = 0.0
	var spots: Array = Main.MARSH.SHORE_WAVES[i]
	for k in spots.size():
		spawn_shore_foe(spots[k], i == 1 and k == spots.size() - 1)

func spawn_snag(i: int) -> void:
	var spots: Array = Main.MARSH.SNAG_FOES[i]
	for k in spots.size():
		spawn_shore_foe(spots[k], i == 2 and k == spots.size() - 1)

# the second pack down: the basket comes out of the mud
func shore_basket_out() -> void:
	m.shore_wave = -1
	m.shore_up = false
	m.marsh.free_basket(m)
	m.shore_q = 2
	m.player.gold += 30
	m.player.pots += 1
	var b: Vector2 = Main.MARSH.BASKET_AT
	m.burst(Vector3(b.x, m.height_at(b.x, b.y) + 0.4, b.y), Color("#c9a066"), 24, 2.5)
	m.sfx(587, 0.25, "triangle", 0.2)
	m.show_story("", Main.STORY.SHORE_FREE)
	m.save_game()

# fainting, loading or leaving the marsh: the packs go and a floating basket is taken back (shore_q stays: E again)
func clear_shore_job() -> void:
	for e in m.enemies:
		if e.get("shore", false) and not e.dead:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
	m.shore_wave = -1
	m.shore_up = false
	m.shore_t = 0.0
	if not m.shore_float.is_empty():
		m.shore_float = {}
		m.marsh.hide_float()

func update_shore(dt: float) -> void:
	if m.intro or not m.in_marsh():
		if m.shore_wave >= 0 or not m.shore_float.is_empty():
			clear_shore_job()
		return
	var snags := 0 # snags still in the river, counted from the last
	if not m.shore_float.is_empty():
		snags = 3 - int(m.shore_float.snag)
	elif m.shore_q == 3 and m.story_step >= 5:
		snags = 3
	m.marsh.shore_tick(m, m.night, snags)
	if m.story_open:
		return
	var me := Vector2(m.player.x, m.player.z)
	if m.story_step >= 3 and m.shore_q == 0 and me.distance_to(Main.START) < 2.5:
		m.shore_q = 1
		m.show_story("", Main.STORY.SHORE_HINT)
		m.save_game()
		return
	if m.shore_wave >= 0 and m.shore_up and not shore_foes_alive():
		m.shore_t += dt
		if m.shore_t >= 1.0:
			if m.shore_wave == 0:
				spawn_shore_wave(1)
			else:
				shore_basket_out()
	if not m.shore_float.is_empty():
		update_float(dt, me)

# the lantern basket floats 1 tile a second; it waits while Sora is more than 12 tiles off (on again inside 8)
func update_float(dt: float, me: Vector2) -> void:
	var f := m.shore_float
	f.t += dt
	if not f.lit: # a moment of the dusty unlit glass, then the crown lights it
		if f.t >= 0.7:
			f.lit = true
			var p0: Vector2 = m.marsh.path[0]
			m.marsh.set_float(p0, true)
			m.burst(Vector3(p0.x, 0.2, p0.y), Color("#ffc46a"), 24, 2.0)
			m.burst(Vector3(m.player.x, m.ground_y + 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
			m.sfx(523, 0.4, "sine", 0.3, 300)
			m.show_story("", Main.STORY.SHORE_FLOAT)
		return
	var d: float = f.d
	var at: Vector2 = m.marsh.float_at(d)
	m.marsh.move_float(at)
	if f.wait: # held at a snag: its bricks rise 0.4 s after, and 1 s after the last falls it floats on
		f.wt += dt
		if not f.up:
			if f.wt >= 0.4:
				f.up = true
				f.wt = 0.0
				spawn_snag(int(f.snag))
		elif shore_foes_alive():
			f.wt = 0.0
		elif f.wt >= 1.0:
			snag_cleared()
		return
	var gap := me.distance_to(at)
	if gap > 12.0:
		f.stop = true
	elif gap < 8.0:
		f.stop = false
	if f.stop:
		return
	var s: int = f.snag
	if s < 3 and d >= float(m.marsh.snag_d[s]):
		f.d = float(m.marsh.snag_d[s])
		f.wait = true
		f.up = false
		f.wt = 0.0
		m.toast("바구니가 벽돌에 걸렸다")
		m.sfx(150, 0.2, "square", 0.15, -30)
		return
	var end: float = m.marsh.path_len()
	if d >= end - 0.3:
		if me.distance_to(Main.MARSH.FLOAT_END) < 10.0:
			shore_landed()
		return
	f.d = minf(d + dt, end)

func snag_cleared() -> void:
	var f := m.shore_float
	f.wait = false
	f.up = false
	f.snag = int(f.snag) + 1
	if int(f.snag) < 3:
		var sn: Node3D = m.marsh.snag_nodes[int(f.snag) - 1]
		m.burst(sn.position + Vector3(0, 0.3, 0), Color("#c9a066"), 18, 2.0)
		m.sfx(392, 0.2, "triangle", 0.15)
		m.toast("바구니가 다시 흐른다")
		return
	# the last snag: the fight's noise settles and only the water is left (GPT's note)
	for sh in m.enemy_shots:
		sh.node.queue_free()
	m.enemy_shots.clear()
	water_hush(4)

func water_hush(n: int) -> void:
	for k in n:
		m.get_tree().create_timer(0.45 * k).timeout.connect(func(): m.sfx(240 - k * 20, 0.5, "noise", 0.04, -60))

func shore_landed() -> void:
	m.shore_float = {}
	m.marsh.land_float()
	m.shore_q = 4
	m.player.max_hp += SHORE_HP
	m.player.hp = minf(float(m.player.max_hp), m.player.hp + SHORE_HP)
	m.show_story("", Main.STORY.SHORE_LAND)
	m.after_story = shore_hush
	m.save_game()

# after the lantern stops: 2 s of only water and the lantern, then the reward and the way back (GPT's note)
func shore_hush() -> void:
	water_hush(5)
	m.get_tree().create_timer(2.0).timeout.connect(func(): m.toast(tr("최대 체력 +%d. 오두막에 들러 보리 할머니께 알리자") % SHORE_HP))

# Bori and the basket (shore_q 2) and the lantern seen from her window (shore_q 4)
func shore_bori() -> bool:
	if m.shore_q == 2:
		m.shore_q = 3
		m.player.pots += 1
		m.show_story("", Main.STORY.SHORE_BORI + [Main.STORY.SHORE_BORI_DAM if m.story_step < 5 else Main.STORY.SHORE_BORI_FLOW] + Main.STORY.SHORE_BORI_END)
		m.save_game()
		return true
	if m.shore_q == 4:
		m.shore_q = 5
		var lines: Array = Main.STORY.SHORE_THANKS.duplicate()
		if m.has_cushion: # a new round: the cushion came along
			lines[lines.size() - 1] = Main.STORY.SHORE_THANKS_ROUND
			m.player.gold += 40
			m.player.pots += 1
		m.has_cushion = true
		m.show_story("", lines)
		m.save_game()
		return true
	return false

# load the shore's state (old saves: the basket is still in the mud); a fight or a float in progress starts over
func load_shore(d: Dictionary) -> void:
	m.shore_q = int(d.get("shore_q", 0))
	m.has_cushion = bool(d.get("has_cushion", false))
	clear_shore_job()
	m.marsh.shore_look(m, m.shore_q)

# chapter 9's diary page and chapter 3's postcard pick the basket and the lantern up
func road_page_lines() -> Array:
	var lines: Array = Main.STORY.ROAD_PAGE.duplicate()
	var i := lines.find("소라|surprised|늪…… 내가 깨어난 곳이야.")
	if m.shore_q >= 2 and i >= 0:
		lines.insert(i + 1, Main.STORY.ROAD_PAGE_BASKET)
	return lines

func post_bori_lines() -> Array:
	var lines: Array = Main.STORY.POST_BORI.duplicate()
	var i := lines.find("보리 할머니|bori|그 사람 편지는 도란이, 내 엽서는 네가. 둘 다 백 년이 걸렸구나.")
	if i >= 0 and m.shore_q >= 3:
		lines.insert(i + 1, Main.STORY.POST_BORI_LAMP if m.shore_q >= 4 else Main.STORY.POST_BORI_LAMP_HELD)
	return lines

# the side step that is running now, one short line under the quest (empty when none; the journal lists the waiting ones)
func side_step() -> String:
	if not m.in_marsh() or m.story_open:
		return ""
	if m.shore_wave >= 0:
		return "물가의 괴물을 물리치자"
	if not m.shore_float.is_empty():
		return tr("바구니를 따라가 걸림을 풀자 %d/3") % int(m.shore_float.snag)
	match m.shore_q:
		1: return "팔찌를 대 진흙을 풀자 (E)" if m.shore_seen else "물가에 걸린 것을 보자"
		2: return "보리 할머니께 바구니를"
		4: return "보리 할머니께 알리자"
	return ""

func shore_journal() -> String:
	match m.shore_q:
		1: return tr("팔찌를 대 진흙을 풀자 (E)") if m.shore_seen else tr("물가에 걸린 것을 보자")
		2: return tr("보리 할머니께 바구니를")
		3:
			if not m.shore_float.is_empty():
				return tr("바구니를 따라가 걸림을 풀자 %d/3") % int(m.shore_float.snag)
			return tr("물길이 다시 흐르면 밤에 띄우자") if m.story_step < 5 else tr("밤에 물가에서 등불 바구니를 띄우자 (E)")
		4: return tr("보리 할머니께 알리자")
	return tr("끝")
