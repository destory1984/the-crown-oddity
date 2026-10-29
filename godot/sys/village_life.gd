# Village: entering/leaving, lamp cost, moon gauge pips, the lantern night, Kongal's kid, lamps.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const NOEUL_WAY := [Vector2(16, 6), Vector2(20, 6), Vector2(24, 7), Vector2(27, 10), Vector2(28, 15), Vector2(29, 18)]
const NOEUL_DUEL_AT := Vector2(28, 12)
const PIP_CAP := 12
const PIP_PLACES := ["letter", "turtle", "lantern", "knight"]

func _init(main: Main) -> void:
	m = main

func enter_village() -> void:
	m.in_village = true
	m.story_step = maxi(m.story_step, 8)
	var sp: Vector2 = m.village.marks.S
	m.player.x = sp.x
	m.player.z = sp.y
	m.ground_y = 0.0
	if not m.ui.has("outside_map"):
		m.ui.outside_map = m.ui.mini.map_tex
	m.ui.mini.map_tex = m.village.map_tex(Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W)
	m.ui.zone_name.text = "등불 마을"
	m.ui.zone_sub.text = "돌 광장"
	if m.errand == 0: # the quest goes in before the save, so a load right after arrival does not ask for the village again
		m.set_quest(Main.SIMJI_QUEST)
	m.save_game()
	if m.errand == 0:
		m.show_story("", Main.STORY.VILLAGE)

func leave_village() -> void:
	m.in_village = false
	m.player.x = 44.0
	m.player.z = 20.0
	m.ground_y = m.height_at(m.player.x, m.player.z)
	if m.ui.has("outside_map"):
		m.ui.mini.map_tex = m.ui.outside_map
	m.ui.zone_name.text = "갈대늪"
	m.ui.zone_sub.text = "동쪽 물가"
	m.save_game()

func lamp_cost() -> int:
	return 1 if m.is_night() else 2 # the crown is half as strong by day

func award_pip(key: String) -> Array:
	if m.pip_awards.has(key):
		return []
	m.pip_awards[key] = true
	if m.pip_max >= PIP_CAP:
		return []
	m.pip_max += 1
	m.crown_pips = mini(m.pip_max, m.crown_pips + 1)
	m.pip_flash = 0.5
	return ["||" + tr("달빛 눈금이 한 칸 깨어났다. 최대 %d칸.") % m.pip_max]

func load_pips(d: Dictionary) -> void:
	m.pip_max = clampi(int(d.get("pip_max", 8)), 8, PIP_CAP)
	m.pip_awards = {}
	for k in d.get("pip_awards", []):
		m.pip_awards[String(k)] = true
	m.crown_pips = clampi(int(d.get("pips", m.pip_max)), 0, m.pip_max) # a new round's save has no pips: full

# run once the progress values are loaded: a save from before v0.0.47 gets the pips of the places already done
func old_save_pips(d: Dictionary) -> void:
	if d.has("pip_max"):
		return
	var back := restore_pips()
	if back > 0:
		m.pip_note = tr("달빛 눈금 %d칸이 깨어났다. 최대 %d칸.") % [back, m.pip_max]

# a save from before the gauge grew: the places already done give their pips back (only the pips, no HP or gold again)
func restore_pips() -> int:
	var done := {"letter": m.doran_q >= 3, "turtle": m.lake_q >= 4, "lantern": m.hollow_q >= 4, "knight": m.castle_q >= 3}
	var n := 0
	for k in PIP_PLACES:
		if done[k] and not m.pip_awards.has(k):
			m.pip_awards[k] = true
			if m.pip_max < PIP_CAP:
				m.pip_max += 1
				n += 1
	m.crown_pips = mini(m.pip_max, m.crown_pips + n)
	return n

func spend_pips(n: int) -> bool:
	if m.crown_pips < n:
		m.ui.hud.pip_need = n # and under it, the pips asked beside the pips held (delight idea 82)
		m.ui.hud.pip_hint_t = 4.0 # a card with a lantern and the moon instead of a line that slips by (hud.gd)
		return false
	m.crown_pips -= n
	m.pip_flash = 0.3
	return true

# ---- the lantern night (story step 9)
# companions and Noeul are drawn facing screen-right; the camera is turned, so "left" must be judged on screen,
# not by world x (walking toward the bottom of the screen has a leftward screen component)
func screen_left(v: Vector2) -> bool:
	return v.dot(Vector2(cos(m.cam_yaw), -sin(m.cam_yaw))) < 0.0

func noeul_sprite() -> Sprite3D:
	var spr := Sprite3D.new() # GPT pixel sprite: 0 arms crossed, 1 running, 2 casting
	spr.texture = load("res://art/folk/noeul.png")
	spr.hframes = 3
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.scale = Vector3(1, 1.0 / cos(0.78), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	spr.pixel_size = 1.8 / 180.0
	spr.offset = Vector2(0, 90)
	return spr

func village_lamps() -> Array:
	return m.lanterns.filter(func(l): return l.position.x > Main.VILLAGE.VILLAGE_X - 1.0 and l.position.x < Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W + 1.0)

func set_village_lamps(on: bool) -> void:
	for l in village_lamps():
		var g: MeshInstance3D = l.get_meta("glass")
		if not g.has_meta("lit_mat"):
			g.set_meta("lit_mat", g.material_override)
		g.material_override = g.get_meta("lit_mat") if on else m.mat_color(Color("#3a3428"))
		l.visible = on
		l.set_meta("dark", not on)
	if on:
		for d in m.village.dark:
			d.lit = true

func start_night() -> void:
	m.night_q = 1
	m.story_step = maxi(m.story_step, 9)
	set_village_lamps(false)
	m.noeul_way = 0
	if m.noeul_node == null:
		m.noeul_node = Node3D.new()
		m.noeul_node.add_child(noeul_sprite())
		m.add_child(m.noeul_node)
	var p: Vector2 = NOEUL_WAY[0]
	m.noeul_node.position = Vector3(Main.VILLAGE.VILLAGE_X + p.x, 0, p.y)
	m.noeul_node.visible = true
	m.show_story("", Main.STORY.NOEUL_COMES)
	m.set_quest("등불을 끈 노을을 쫓자 (Shift로 달리기)")
	m.save_game()

# Noeul keeps a few steps ahead of Sora along the path; at the last point he turns and she falls
func update_night(dt: float) -> void:
	var night_now := m.is_night()
	if m.in_village and m.in_house < 0 and m.night_q == 0 and m.mul_q == 3 and night_now and not m.story_open and m.fade_rect.color.a == 0.0:
		start_night()
	if m.night_q != 1 or m.noeul_node == null or m.story_open:
		return
	var me := Vector2(m.player.x, m.player.z)
	var at := Vector2(m.noeul_node.position.x, m.noeul_node.position.z)
	var spr: Sprite3D = m.noeul_node.get_child(0)
	var last := m.noeul_way >= NOEUL_WAY.size() - 1
	if not last and me.distance_to(at) < 4.5:
		var w: Vector2 = NOEUL_WAY[m.noeul_way + 1] + Vector2(Main.VILLAGE.VILLAGE_X, 0)
		var step := w - at
		if step.length() < 0.2:
			m.noeul_way += 1
		else:
			at += step.normalized() * minf(step.length(), dt * 4.8)
		spr.frame = 1
		spr.flip_h = screen_left(Vector2(step.x, step.y))
	else:
		spr.frame = 0
	m.noeul_node.position = Vector3(at.x, 0, at.y)
	if last and me.distance_to(at) < 1.8:
		night_fall()

func night_fall() -> void:
	m.night_q = 2
	m.noeul_node.get_child(0).frame = 2
	m.burst(m.noeul_node.position + Vector3(0, 1.0, 0), Color("#8a8a8a"), 30, 3.0)
	m.shake = 0.3
	m.sfx(90, 0.5, "sawtooth", 0.25, -40)
	m.show_story("res://art/story/08_dark_night.jpg", Main.STORY.NIGHT_FALL)
	m.after_story = rise_together
	m.save_game()

# the letter Bori sent back with Sora: given to Doran on the first talk after, or here as the night begins
func rise_lines() -> Array:
	var lines: Array = Main.STORY.RISE_TOGETHER.duplicate()
	if not m.letter_back:
		m.letter_back = true
		for i in lines.size():
			if String(lines[i]).begins_with("도란|"):
				lines.insert(i, Main.STORY.DORAN_LETTER_BACK[0])
				break
	return lines

func rise_together() -> void:
	m.noeul_node.visible = false
	m.player.x = m.village.marks.M.x - 1.5
	m.player.z = m.village.marks.M.y + 1.5
	m.player.hp = float(m.player.max_hp)
	m.crown_pips = m.pip_max
	set_village_lamps(true)
	m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#ffc46a"), 40, 4.0)
	m.night_q = 3
	m.show_story("res://art/story/09_rise_together.jpg", rise_lines())
	m.after_story = spawn_noeul_duel
	m.set_quest("동쪽 들판의 노을과 겨루자")
	m.save_game()

func spawn_noeul_duel(second := false, cloak := false) -> void:
	if m.enemies.any(func(e): return e.get("noeul", false) and not e.dead):
		return
	var at: Vector2 = m.forest.marks.C if cloak else (m.forest.marks.N if second else NOEUL_DUEL_AT + Vector2(Main.VILLAGE.VILLAGE_X, 0))
	var node := Node3D.new()
	node.add_child(noeul_sprite())
	m.add_child(node)
	var hp := 2200.0 if cloak else (2000.0 if second else 1100.0) # v0.1.72: was 715 / 1328 / 1600 (the owner chose 'bosses get tougher' 2026-10-28; boss7 review, middle step)
	m.enemies.append({"x": at.x, "z": at.y, "hp": hp, "max_hp": int(hp), "node": node, "shadow": m.blob(0.8), "t": 0.0,
		"atk_cd": 2.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"noeul": true, "second": second or cloak, "cloak": cloak, "cave": true, "wind": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "stun": 0.0, "next": "dash", "rings": []})

# Noeul's duel: a quick telegraphed dash, then rings of brick dust around Sora; below half HP, three rings
func update_noeul(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	var spr: Sprite3D = node.get_child(0)
	var awake := d < 9.0 and not m.sealed_between(Vector2(e.x, e.z), Vector2(m.player.x, m.player.z))
	m.ui.boss.visible = awake or (m.ui.boss.visible and d < 13.0)
	var cloak: bool = e.get("cloak", false)
	m.ui.boss_name.text = "빈 망토" if cloak else "노을"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	var base := Color(0.6, 0.6, 0.65, 0.75) if cloak else Color.WHITE # the empty cloak: grey and see-through
	spr.modulate = Color(1.6, 1.4, 1.4, base.a) if e.hurt > 0.0 else base
	if e.dash > 0.0:
		e.dash -= dt
		var nx: float = e.x + e.dir.x * 11.0 * dt
		var nz: float = e.z + e.dir.y * 11.0 * dt
		if m.walkable(nx, nz):
			e.x = nx
			e.z = nz
			if Vector2(m.player.x - e.x, m.player.z - e.z).length() < 0.9:
				m.player_hit(20 + m.boss_extra(), Vector2(e.x, e.z) - e.dir, e)
		else:
			e.dash = 0.0
		spr.frame = 1
	elif e.stun > 0.0:
		spr.frame = 0
	elif e.wind > 0.0:
		e.wind -= dt
		spr.frame = 2 if e.next == "dust" else 1
		if e.wind <= 0.0:
			if e.next == "dash":
				e.dash = 0.45
				e.next = "dust"
			else:
				for r in e.rings:
					m.burst(Vector3(r.x, 0.3, r.y), Color("#9a9a9a"), 18, 3.0)
					if Vector2(m.player.x, m.player.z).distance_to(r) < 1.2:
						m.player_hit(16 + m.boss_extra(), r, e)
				m.sfx(110, 0.25, "square", 0.2, -40)
				e.next = "dash"
			e.atk_cd = 1.15
	elif awake:
		spr.frame = 0
		e.atk_cd -= dt
		if e.atk_cd <= 0.0:
			if e.next == "dash":
				e.wind = 0.55
				e.dir = to / maxf(d, 0.01)
				m.pop_num(Vector3(e.x, 2.4, e.z), "!", Color("#ff5a4a"))
				m.sfx(160, 0.4, "sawtooth", 0.2, 160)
			else:
				e.wind = 0.8
				e.rings = [Vector2(m.player.x, m.player.z)]
				if e.hp < e.max_hp / 2.0 or e.get("second", false):
					for k in (4 if e.get("second", false) and e.hp < e.max_hp / 2.0 else 2):
						e.rings.append(Vector2(m.player.x, m.player.z) + Vector2(m.rnd(-2.2, 2.2), m.rnd(-2.2, 2.2)))
				for r in e.rings:
					m.warn_ring(Vector3(r.x, 0.0, r.y), 1.2, 0.8)
		elif d < 3.0: # keeps his distance
			var nx: float = e.x - to.x / d * 2.0 * dt
			var nz: float = e.z - to.y / d * 2.0 * dt
			if m.walkable(nx, e.z): e.x = nx
			if m.walkable(e.x, nz): e.z = nz
	spr.flip_h = screen_left(e.dir if e.dash > 0.0 else to)
	node.position = Vector3(e.x, 0, e.z)
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func noeul_beaten() -> void:
	m.night_q = 4
	m.has_unbrick = true
	m.ui.boss.visible = false
	m.player.gold += 100
	m.gain_xp(150)
	m.set_quest("물결과 함께 남쪽 호수를 풀자 (마을 남쪽 문)")
	m.show_story("", Main.STORY.NOEUL_LOSES)
	m.save_game()

# put the kid goblin where kid_q says: in the field with guards, or beside Kongal
func place_kid() -> void:
	if m.kid_node == null:
		m.kid_node = m.village.kid_goblin(m)
	var vx := float(Main.VILLAGE.VILLAGE_X)
	match m.kid_q:
		1:
			m.kid_node.position = Vector3(vx + m.village.KID_AT.x, 0, m.village.KID_AT.y)
			for at in m.village.KID_GUARDS:
				m.spawn_enemy(Vector2(vx + at.x, at.y))
				m.enemies[m.enemies.size() - 1].cave = true # they do not come back
		2:
			m.kid_node.position = Vector3(m.player.x - 0.8, 0, m.player.z + 0.4)
		3:
			var k: Vector2 = m.village.folk_pos.kongal
			m.kid_node.position = Vector3(k.x + 0.7, 0, k.y + 0.3)

# the lent firefly jar glows at Sora's side after dark and works like a lantern for resting:
# at night the crown's pips refill anywhere calm, one every 20 s (10 s beside a real lantern).
# It has no OmniLight on purpose: the marsh ground is one mesh and the web renderer lights a mesh with at most 8.
func build_jar() -> void:
	if m.jar_node != null:
		return
	m.jar_node = Node3D.new()
	var glass: MeshInstance3D = m.box(Vector3(0.16, 0.2, 0.16), m.glow_mat(Color("#d8ff7a"), 3.0))
	m.jar_node.add_child(glass)
	var lid: MeshInstance3D = m.box(Vector3(0.18, 0.05, 0.18), m.mat_color(Color("#7a5a32")))
	lid.position = Vector3(0, 0.12, 0)
	m.jar_node.add_child(lid)
	m.add_child(m.jar_node)

func update_kid(dt: float) -> void:
	if m.kid_node == null or not m.in_village:
		return
	m.kid_node.visible = m.in_village
	var me := Vector3(m.player.x, 0, m.player.z)
	if m.kid_q == 1 and me.distance_to(m.kid_node.position) < 1.2:
		var near := m.enemies.filter(func(e): return not e.dead and Vector2(e.x, e.z).distance_to(Vector2(m.player.x, m.player.z)) < 7.0)
		if near.is_empty():
			m.kid_q = 2
			m.burst(m.kid_node.position + Vector3(0, 0.6, 0), Color("#8de07a"), 16, 1.5)
			m.sfx(784, 0.2, "triangle", 0.2)
			m.toast("꼬마 고블린이 소라를 따라온다")
			m.set_quest("꼬마 고블린을 콩알에게 데려다주자 (E)")
			m.save_game()
		elif m.toast_t <= 0.0:
			m.toast("큰 고블린들이 꼬마를 붙잡고 있다")
	if m.kid_q == 2: # trot after Sora, a step behind
		var to := me - m.kid_node.position
		if to.length() > 1.0:
			m.kid_node.position += to.normalized() * minf(to.length() - 1.0, dt * 5.0)
		var trot := to.length() > 1.05
		m.kid_node.position.y = absf(sin(m.t * 12.0)) * 0.08 if trot else 0.0
		m.kid_node.get_meta("spr").frame = (1 if sin(m.t * 12.0) > 0.0 else 0) if trot else 0

func light_village_lamp(d: Dictionary) -> void:
	d.lit = true
	d.light.set_meta("dark", false)
	d.glass.material_override = d.glass.get_meta("lit_mat")
	m.burst(d.light.position, Color("#ffc46a"), 24, 2.5)
	m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
	m.world_build.palm_mark(d.glass)
	m.sfx(523, 0.4, "sine", 0.3, 300)
	var n: int = m.village.lit_count()
	if n >= 3:
		m.errand = 2
		m.set_quest("등불지기 심지에게 돌아가자")
	else:
		m.set_quest(tr("동쪽 끝 꺼진 등불을 팔찌로 켜자 (E) %d/3") % n)
	var at: Vector2 = d.brick
	m.get_tree().create_timer(1.0).timeout.connect(func():
		m.spawn_enemy(at)
		var g: Dictionary = m.enemies[m.enemies.size() - 1]
		g.cave = true # village goblins do not come back
		m.burst(Vector3(at.x, 0.4, at.y), Color("#c9a066"), 20, 2.0)
		m.pop_num(Vector3(at.x, 1.3, at.y), "!", Color("#ff5a4a")))
	m.save_game()
