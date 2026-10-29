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

# a small moon plaque on a post by the shore path, south of the entry: at night the water-grey board shows tonight's moon
# as a little pixel picture, the whole disc when the moon is full and only the lit part otherwise. A decoration; nothing
# asks for it (delight idea 38)
const PLAQUE_AT := Vector2(279.0, 3.0) # LAKE_X + 9
const PLAQUE_PX := 24
var plaque: Sprite3D
var plaque_key := -1 # moon day * 2 + night, the picture last drawn
var plaque_lit := 0 # lit pixels in the picture on the board (autoplay d38_moon_plaque)

# the lit pixels of the moon seen with `phase` (x: how much is lit 0.15 to 1, y: 1 waxing, -1 waning) in an n by n picture
func moon_mask(phase: Vector2, n: int) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var k := 1.0 - 2.0 * phase.x # -1 full .. 0.7 thin: where the shadow's edge cuts each row
	for py in n:
		for px in n:
			var x := (px + 0.5) / n * 2.0 - 1.0
			var y := (py + 0.5) / n * 2.0 - 1.0
			if x * x + y * y > 1.0:
				continue
			if x * phase.y >= k * sqrt(1.0 - y * y):
				img.set_pixel(px, py, Color("#d6e6ff"))
	return img

func build_moon_plaque() -> void:
	var g := Node3D.new()
	g.position = Vector3(PLAQUE_AT.x, 0, PLAQUE_AT.y)
	m.add_child(g)
	var pole: MeshInstance3D = m.box(Vector3(0.12, 0.9, 0.12), m.mat_color(Color("#4a3a2a")))
	pole.position = Vector3(0, 0.45, 0)
	g.add_child(pole)
	var board: MeshInstance3D = m.box(Vector3(0.62, 0.62, 0.07), m.mat_color(Color("#3c4a5c")))
	board.position = Vector3(0, 1.1, 0)
	g.add_child(board)
	plaque = Sprite3D.new()
	plaque.pixel_size = 0.5 / PLAQUE_PX
	plaque.shaded = false
	plaque.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	plaque.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	plaque.position = Vector3(0, 1.1, 0.045)
	plaque.visible = false
	g.add_child(plaque)
	m.rocks.append({"x": PLAQUE_AT.x, "z": PLAQUE_AT.y, "r": 0.25})

# a height ruler by the door of Mulgyeol's island hut, tick marks every 0.1 tile; once he has joined and comes back to the hut
# with Sora, a gold line fades in on it at the length of his pole. Looking at it is only a line of text (delight idea 72)
const RULER_PX := Vector2i(8, 40)
const RULER_STEP := 0.025 # tiles a pixel
const POLE_Y := 0.85      # the pole's mark, tiles above the ground
var ruler: Sprite3D
var ruler_mark: Sprite3D
var ruler_at := Vector2(-1, -1)
var ruler_shown := false
var ruler_a := 0.0

func ruler_tex() -> ImageTexture:
	return m.make_tex(RULER_PX.x, RULER_PX.y, func(img: Image):
		m.px(img, 0, 0, RULER_PX.x, RULER_PX.y, Color("#c9a86a"))
		m.px(img, 0, 0, 1, RULER_PX.y, Color("#7a5a34"))
		m.px(img, RULER_PX.x - 1, 0, 1, RULER_PX.y, Color("#7a5a34"))
		for k in 10: # a tick for every 0.1 tile, a long one every fifth
			var y := RULER_PX.y - 1 - k * 4
			m.px(img, 1, y, 5 if k % 5 == 0 else 3, 1, Color("#4a3320")))

func build_height_ruler() -> void:
	ruler_at = m.lake.marks.h + Vector2(0.55, 0.34)
	ruler = Sprite3D.new()
	ruler.texture = ruler_tex()
	ruler.pixel_size = RULER_STEP
	ruler.shaded = false
	ruler.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ruler.position = Vector3(ruler_at.x, RULER_PX.y * RULER_STEP / 2.0, ruler_at.y)
	m.add_child(ruler)
	ruler_mark = Sprite3D.new() # the pole's length, three pixels of gold across the ruler and a little past it
	ruler_mark.texture = m.make_tex(RULER_PX.x + 4, 3, func(img: Image):
		m.px(img, 0, 0, RULER_PX.x + 4, 3, Color("#ffd84a"))
		m.px(img, 0, 2, RULER_PX.x + 4, 1, Color("#b8861a")))
	ruler_mark.pixel_size = RULER_STEP
	ruler_mark.shaded = false
	ruler_mark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ruler_mark.position = Vector3(ruler_at.x, POLE_Y, ruler_at.y + 0.004)
	ruler_mark.visible = false
	m.add_child(ruler_mark)

func update_height_ruler(dt: float) -> void:
	if ruler == null:
		return
	if not ruler_shown:
		var me := Vector2(m.player.x, m.player.z)
		if m.lake_q >= 4 and m.mate != null and me.distance_to(ruler_at) < 4.0 				and Vector2(m.mate.position.x, m.mate.position.z).distance_to(ruler_at) < 4.5:
			ruler_shown = true
			ruler_mark.visible = true
	if ruler_shown and ruler_a < 1.0:
		ruler_a = minf(1.0, ruler_a + dt)
		ruler_mark.modulate.a = ruler_a

# E at the ruler once the line is on it
func ruler_key() -> bool:
	if not ruler_shown or Vector2(m.player.x, m.player.z).distance_to(ruler_at) > 1.2:
		return false
	m.toast(tr("물결의 장대가 이 금까지 온다"))
	return true

func update_moon_plaque() -> void:
	if plaque == null:
		return
	var night: bool = m.is_night()
	plaque.visible = night
	var key: int = (m.day % m.daynight.MOON_DAYS) * 2 + (1 if night else 0)
	if night and key != plaque_key:
		plaque_key = key
		var img := moon_mask(m.moon_phase(), PLAQUE_PX)
		plaque.texture = ImageTexture.create_from_image(img)
		plaque_lit = 0
		for py in PLAQUE_PX:
			for px in PLAQUE_PX:
				if img.get_pixel(px, py).a > 0.0:
					plaque_lit += 1

func enter_lake() -> void:
	m.in_village = false
	m.in_lake = true
	m.player.x = m.lake.marks.S.x
	m.player.z = m.lake.marks.S.y + 1.2
	m.ground_y = 0.0
	m.ui.mini.map_tex = m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G, m.lake.marks.V])
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
	m.monsters.refill_field("lake")
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
			m.ui.mini.map_tex = m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G, m.lake.marks.V])
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
	return ruler_key()

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

# she left the turtle fight (fainted or took a way stone): it starts over from the pier, where Mulgyeol
# waits again; he used to stay her companion too, so he stood on the pier and at her side at once
func turtle_retry() -> void:
	m.lake_q = 2
	m.mates.leave_mate()
	if m.lake_npc != null:
		m.lake_npc.visible = true
	for e in m.enemies:
		if e.get("turtle", false) and not e.dead:
			e.hp = float(e.max_hp)
			e.x = e.wx
			e.z = e.wz

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
	m.enemies.append({"x": at.x, "z": at.y, "hp": 1600.0, "max_hp": 1600, "node": root, "shadow": m.blob(1.6), "t": 0.0,
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
				m.player_hit(22 + m.boss_extra(), Vector2(e.x, e.z) - e.dir, e)
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
					m.player_hit(18 + m.boss_extra(), Vector2(e.x, e.z), e)
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
	return m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G, m.lake.marks.V])

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
		m.moon_tokens.refresh_quest() # the forest gate asked for the water clock
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
	m.monsters.refill_field("lake") # the yard's ambush (x >= 296) waits for the grate

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
	update_moon_plaque()
	update_height_ruler(dt)
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
	return m.in_lake_main() and m.lake_q >= 4 and me.y > 12.0 and me.y < Main.LAKE.SOUTH_Z

func shore_hint(me: Vector2) -> void:
	var ahead: Vector2 = me + Vector2(m.player.face).normalized() * 0.8
	var near := on_island(me) and m.lake.char_at(ahead.x, ahead.y) == "X"
	if near and not at_shore:
		m.toast("섬 북쪽 나루에서 E를 누르면 물결이 배를 저어 준다")
	at_shore = near

# ---- 물빛 동굴 under the island (after the turtle): water-skip runs, archers, the brick crab and the water pearl
func in_grotto() -> bool:
	return m.in_lake and m.player.x >= Main.GROTTO.GROTTO_X - 0.5 and m.player.x < Main.CORR.CORR_X - 0.5

# steps going down on the island's south shore, at the lake's G: a stone frame over a stair that sinks step by step
# into a dark opening, with a lamp on top, so it reads as a way down from far off
func grotto_steps() -> void:
	stair_frame(m.lake.marks.G)

func stair_frame(at: Vector2, turn := 0.0, shade := 0.0, lamp_col := Color("#9fd8ff"), deep := false) -> Node3D:
	var g := Node3D.new()
	if deep: # six treads, each darker than the last, between long side walls: it reads as steps going down, not as an arrow
		return deep_stair(g, at, turn, shade, lamp_col)
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

# the water corridor's stair at the lake's V (the owner, 2026-10-29: "이건 어디로 가는 화살표야"): wider and longer than the grotto's,
# six treads that go darker and a little lower with every step, a near tread with a lit lip, a dark mouth at the end
func deep_stair(g: Node3D, at: Vector2, turn: float, shade: float, lamp_col: Color) -> Node3D:
	var frame: Material = m.mat_color(Color("#7a7468").darkened(shade))
	var mouth: MeshInstance3D = m.box(Vector3(1.5, 0.05, 0.5), m.mat_color(Color("#06090c")))
	mouth.position = Vector3(0, 0.02, -1.45)
	g.add_child(mouth)
	for k in 6:
		var tread: MeshInstance3D = m.box(Vector3(1.4, 0.07, 0.34), m.mat_color(Color("#cfcabd").darkened(shade + k * 0.13)))
		tread.position = Vector3(0, 0.09 - k * 0.012, 0.95 - k * 0.38)
		g.add_child(tread)
		var riser: MeshInstance3D = m.box(Vector3(1.4, 0.05, 0.05), m.mat_color(Color("#f2eee0") if k == 0 else Color("#3c3a36").darkened(k * 0.1)))
		riser.position = Vector3(0, 0.1 - k * 0.012, 1.1 - k * 0.38)
		g.add_child(riser)
	for side in [-0.82, 0.82]: # low side walls that lean in toward the dark end
		var w: MeshInstance3D = m.box(Vector3(0.18, 0.42, 2.8), frame)
		w.position = Vector3(side, 0.21, -0.2)
		g.add_child(w)
	var back: MeshInstance3D = m.box(Vector3(1.8, 0.95, 0.18), frame)
	back.position = Vector3(0, 0.47, -1.65)
	g.add_child(back)
	var lamp: MeshInstance3D = m.box(Vector3(0.22, 0.26, 0.22), m.glow_mat(lamp_col, 1.4))
	lamp.position = Vector3(0, 1.1, -1.65)
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
	m.ui.mini.map_tex = m.with_stair_marks(m.lake.map_tex(Main.LAKE.LAKE_X + Main.LAKE.W), [m.lake.marks.G, m.lake.marks.V])
	m.ui.zone_name.text = "남쪽 호수"
	m.ui.zone_sub.text = "물결의 섬"
	m.ui.boss.visible = false
	m.snap_mate()
	m.monsters.refill_field("lake")
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
		m.moon_tokens.earn(m.moon_tokens.PEARL)
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
	m.enemies.append({"x": at.x, "z": at.y, "hp": 1500.0, "max_hp": 1500, "node": root, "shadow": m.blob(1.5), "t": 0.0,
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
					m.player_hit(18 + m.foe_hit(), Vector2(e.x, e.z), e)
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
	m.set_quest(m.moon_tokens.lake_line()) # the pearl token first, if it is missing
	m.save_game()
