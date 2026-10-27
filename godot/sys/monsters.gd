# Monsters: goblins, wolves, bats, hedgehogs, the boss, enemy update loop, thrown bricks.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- enemies
# LEGO-style brick goblin: plastic boxes with studs on top faces
func brick(g: Node3D, mats: Array, size: Vector3, pos: Vector3, color: Color, studs := true, glow := false) -> void:
	var mm := StandardMaterial3D.new()
	mm.albedo_color = color
	mm.roughness = 0.32
	if glow:
		mm.emission_enabled = true
		mm.emission = Color("#ff9a1a")
		mm.emission_energy_multiplier = 3.0
	else:
		mats.append(mm)
	var b := m.box(size, mm)
	b.position = pos
	g.add_child(b)
	if studs:
		var nx := maxi(1, int(round(size.x / 0.2)))
		var nz := maxi(1, int(round(size.z / 0.2)))
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.075
		cyl.bottom_radius = 0.075
		cyl.height = 0.06
		cyl.radial_segments = 12
		for i in nx:
			for k in nz:
				var st := MeshInstance3D.new()
				st.mesh = cyl
				st.material_override = mm
				st.position = pos + Vector3(-size.x / 2.0 + (i + 0.5) * size.x / nx, size.y / 2.0 + 0.03, -size.z / 2.0 + (k + 0.5) * size.z / nz)
				g.add_child(st)

func make_monster(boss := false) -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	var body := Color("#5a2a8a") if boss else Color("#b4231e")
	var dark := Color("#2e2a30")
	var head := Color("#1e1e2a") if boss else Color("#2f5fb8")
	brick(g, mats, Vector3(0.14, 0.16, 0.16), Vector3(-0.13, 0.08, 0), dark, false)
	brick(g, mats, Vector3(0.14, 0.16, 0.16), Vector3(0.13, 0.08, 0), dark, false)
	brick(g, mats, Vector3(0.5, 0.3, 0.36), Vector3(0, 0.31, 0), body)
	brick(g, mats, Vector3(0.12, 0.2, 0.14), Vector3(-0.32, 0.34, 0), body, false)
	brick(g, mats, Vector3(0.12, 0.2, 0.14), Vector3(0.32, 0.34, 0), body, false)
	brick(g, mats, Vector3(0.42, 0.32, 0.38), Vector3(0, 0.64, 0), head)
	brick(g, mats, Vector3(0.1, 0.1, 0.04), Vector3(-0.1, 0.68, 0.2), Color("#ffc23a"), false, true)
	brick(g, mats, Vector3(0.1, 0.1, 0.04), Vector3(0.1, 0.68, 0.2), Color("#ffc23a"), false, true)
	brick(g, mats, Vector3(0.22, 0.04, 0.04), Vector3(0, 0.55, 0.2), dark, false)
	brick(g, mats, Vector3(0.08, 0.18, 0.08), Vector3(-0.16, 0.9, 0), Color("#e8dcc0"), false)
	brick(g, mats, Vector3(0.08, 0.18, 0.08), Vector3(0.16, 0.9, 0), Color("#e8dcc0"), false)
	if boss: # gold crown of studded bricks and a cape plate
		brick(g, mats, Vector3(0.46, 0.08, 0.42), Vector3(0, 0.84, 0), Color("#e8b018"))
		for cx in [-0.16, 0.0, 0.16]:
			brick(g, mats, Vector3(0.08, 0.14, 0.08), Vector3(cx, 0.95, 0.15), Color("#e8b018"), false)
		brick(g, mats, Vector3(0.56, 0.4, 0.06), Vector3(0, 0.36, -0.22), Color("#8a1a1a"), false)
	root.scale = Vector3.ONE * (3.2 if boss else 1.3)
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	return root

func spawn_enemy(at := Vector2(-1, -1), archer := false) -> void:
	var x := at.x
	var z := at.y
	var tries := 0
	while at.x < 0:
		x = m.rnd(4, Main.N - 4)
		z = m.rnd(4, Main.N - 4)
		tries += 1
		if (m.walkable(x, z) and Vector2(x - m.player.x, z - m.player.z).length() >= 9) or tries > 1000:
			break
	var node := make_monster()
	m.add_child(node)
	var hp: int = (20 + m.foe_lv() * 8) if archer else (30 + m.foe_lv() * 10)
	if archer: # brick archer: green body, mustard head
		var mats: Array = node.get_meta("mats")
		mats[2].albedo_color = Color("#3f8a3a")
		mats[5].albedo_color = Color("#d9b03a")
	m.enemies.append({"x": x, "z": z, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(0.8), "t": m.rnd(0, 5),
		"atk_cd": 1.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": x, "wz": z, "dead": false, "respawn": 0.0,
		"archer": archer, "cave": at.x >= Main.CAVE_X - 0.5})

# the Brick King waits at the northern edge of the map; he does not respawn
# ---- brick wolves: quick pack hunters in the forest and on the hill. A wolf circles Sora about 3 tiles out,
# then a 0.35 s crouch ("!") and a straight lunge (7 tiles/s for 0.35 s); after it, 0.8 s to catch its breath.
func make_wolf() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	var fur := Color("#7a6a5a")
	var dark := Color("#3a3230")
	brick(g, mats, Vector3(0.36, 0.3, 0.8), Vector3(0, 0.38, 0), fur)          # body
	brick(g, mats, Vector3(0.32, 0.3, 0.34), Vector3(0, 0.55, 0.5), fur)       # head
	brick(g, mats, Vector3(0.2, 0.14, 0.2), Vector3(0, 0.48, 0.74), dark, false) # snout
	brick(g, mats, Vector3(0.08, 0.14, 0.06), Vector3(-0.1, 0.76, 0.46), dark, false) # ears
	brick(g, mats, Vector3(0.08, 0.14, 0.06), Vector3(0.1, 0.76, 0.46), dark, false)
	brick(g, mats, Vector3(0.07, 0.07, 0.03), Vector3(-0.08, 0.6, 0.67), Color("#ffc23a"), false, true) # eyes
	brick(g, mats, Vector3(0.07, 0.07, 0.03), Vector3(0.08, 0.6, 0.67), Color("#ffc23a"), false, true)
	for leg in [Vector3(-0.12, 0.12, 0.28), Vector3(0.12, 0.12, 0.28), Vector3(-0.12, 0.12, -0.28), Vector3(0.12, 0.12, -0.28)]:
		brick(g, mats, Vector3(0.1, 0.24, 0.1), leg, dark, false)
	brick(g, mats, Vector3(0.08, 0.08, 0.36), Vector3(0, 0.48, -0.52), fur, false) # tail
	root.scale = Vector3.ONE * 1.3
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	return root

func spawn_wolf(at: Vector2) -> void:
	var node := make_wolf()
	m.add_child(node)
	var hp: int = 25 + m.foe_lv() * 7
	m.enemies.append({"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(0.7), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(1.0, 2.5), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"wolf": true, "cave": true, "wind": 0.0, "stun": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "rest": 0.0, "hit_done": false,
		"side": 1.0 if m.rng.randf() < 0.5 else -1.0})

func update_wolf(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	e.t += dt
	e.atk_cd -= dt
	e.hurt -= dt
	e.rest -= dt
	e.stun = e.get("stun", 0.0) - dt
	var dirn: Vector2 = to / maxf(d, 0.01)
	var v := Vector2.ZERO
	if e.hurt > 0.0 or e.stun > 0.0:
		e.dash = 0.0
		e.wind = 0.0
		v = Vector2(e.kx, e.kz)
	elif e.dash > 0.0:
		e.dash -= dt
		v = e.dir * 7.0
		if not e.hit_done and d < 1.0:
			e.hit_done = true
			m.player_hit(int(round(m.rnd(7, 10) + m.foe_lv())), Vector2(e.x, e.z), e)
		if e.dash <= 0.0:
			e.rest = 0.8
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			e.dash = 0.35
			e.dir = dirn
			e.hit_done = false
			e.atk_cd = m.rnd(1.6, 2.4)
	elif e.rest > 0.0:
		pass
	elif d < 9.0 and not m.intro:
		if e.atk_cd <= 0.0 and d < 4.0:
			e.wind = 0.35
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.1, e.z), "!", Color("#ff5a4a"))
		else: # circle her about 3 tiles out, sliding in or out to keep the ring
			v = dirn.rotated(PI / 2.0 * e.side) * 3.2 + dirn * clampf(d - 3.0, -1.0, 1.0) * 2.5
	else:
		if Vector2(e.wx - e.x, e.wz - e.z).length() < 0.3 or m.rng.randf() < 0.005:
			e.wx = e.x + m.rnd(-3, 3)
			e.wz = e.z + m.rnd(-3, 3)
		var w := Vector2(e.wx - e.x, e.wz - e.z)
		if w.length() > 0.01:
			v = w.normalized() * 1.2
	e.kx *= pow(0.002, dt)
	e.kz *= pow(0.002, dt)
	var nx: float = e.x + v.x * dt
	var nz: float = e.z + v.y * dt
	if m.walkable(nx, e.z): e.x = nx
	else: e.side = -e.side # a wall: circle the other way
	if m.walkable(e.x, nz): e.z = nz
	var node: Node3D = e.node
	var y := m.height_at(e.x, e.z)
	var run := absf(sin(e.t * 14.0)) if v.length() > 0.5 else 0.0
	node.position = Vector3(e.x, y + run * 0.08, e.z)
	if e.wind > 0.0 or e.dash > 0.0:
		node.rotation.y = atan2(dirn.x, dirn.y)
	elif v.length() > 0.1:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(v.x, v.y), minf(1.0, dt * 10.0))
	var body: Node3D = node.get_meta("body")
	body.scale = Vector3(1.0, 0.85 if e.wind > 0.0 else 1.0, 1.0) # crouches before the lunge
	for mm in node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0 or e.wind > 0.0
		mm.emission = Color("#ff3a2a") if e.wind > 0.0 and e.hurt <= 0 else Color.WHITE
		mm.emission_energy_multiplier = 0.9
	e.shadow.position = Vector3(e.x, y + 0.02, e.z)

func spawn_bat(at: Vector2) -> void:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	brick(g, mats, Vector3(0.3, 0.26, 0.3), Vector3(0, 0, 0), Color("#4a3a5a"))
	brick(g, mats, Vector3(0.06, 0.06, 0.03), Vector3(-0.07, 0.04, 0.16), Color("#ff6a4a"), false, true)
	brick(g, mats, Vector3(0.06, 0.06, 0.03), Vector3(0.07, 0.04, 0.16), Color("#ff6a4a"), false, true)
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.name = "wl" if side < 0 else "wr"
		wing.position = Vector3(side * 0.15, 0.05, 0)
		g.add_child(wing)
		var w := m.box(Vector3(0.42, 0.04, 0.26), m.mat_color(Color("#3a2e48")))
		w.position = Vector3(side * 0.21, 0, 0)
		wing.add_child(w)
	root.scale = Vector3.ONE * 1.3
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	m.add_child(root)
	var hp: int = 15 + m.foe_lv() * 5
	m.enemies.append({"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": root, "shadow": m.blob(0.4), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(1.5, 3.0), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"bat": true, "cave": true, "wind": 0.0, "stun": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "hit_done": false})

func update_bat(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	e.t += dt
	e.atk_cd -= dt
	e.hurt -= dt
	e.stun = e.get("stun", 0.0) - dt
	var dirn: Vector2 = to / maxf(d, 0.01)
	var v := Vector2.ZERO
	if e.hurt > 0.0 or e.stun > 0.0:
		e.dash = 0.0
		e.wind = 0.0
		v = Vector2(e.kx, e.kz)
	elif e.dash > 0.0:
		e.dash -= dt
		v = e.dir * 8.0
		if not e.hit_done and d < 0.8:
			e.hit_done = true
			m.player_hit(int(round(m.rnd(6, 9) + m.foe_lv())), Vector2(e.x, e.z), e)
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			e.dash = 0.5
			e.dir = dirn
			e.hit_done = false
			e.atk_cd = m.rnd(2.0, 3.0)
	elif d < 8.0 and not m.intro:
		if e.atk_cd <= 0.0 and d < 4.0:
			e.wind = 0.4
			m.pop_num(Vector3(e.x, 2.0, e.z), "!", Color("#ff5a4a"))
		else: # a jittery ring around her
			v = dirn.rotated(PI / 2.0) * (2.5 + sin(e.t * 3.0) * 1.5) + dirn * clampf(d - 2.5, -1.0, 1.0) * 2.0
	else:
		v = Vector2(sin(e.t * 1.3), cos(e.t * 0.9)) * 1.0
	e.kx *= pow(0.002, dt)
	e.kz *= pow(0.002, dt)
	var nx: float = e.x + v.x * dt
	var nz: float = e.z + v.y * dt
	if m.walkable(nx, e.z): e.x = nx
	if m.walkable(e.x, nz): e.z = nz
	var node: Node3D = e.node
	var body: Node3D = node.get_meta("body")
	var flap := sin(e.t * (30.0 if e.wind > 0.0 else 18.0)) * 0.7
	body.get_node("wl").rotation.z = flap
	body.get_node("wr").rotation.z = -flap
	node.position = Vector3(e.x, 1.1 + sin(e.t * 4.0) * 0.12 - (0.5 if e.dash > 0.0 else 0.0), e.z)
	node.rotation.y = atan2(dirn.x, dirn.y)
	for mm in node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0 or e.wind > 0.0
		mm.emission = Color("#ff3a2a") if e.wind > 0.0 and e.hurt <= 0 else Color.WHITE
		mm.emission_energy_multiplier = 0.9
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func spawn_boss() -> void:
	var spot := Vector2(16, 4)
	for tries in 40:
		if m.walkable(spot.x, spot.y):
			break
		spot = Vector2(m.rnd(6, 20), m.rnd(3, 6))
	var node := make_monster(true)
	m.add_child(node)
	var hp := 950
	m.enemies.append({"x": spot.x, "z": spot.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(2.4), "t": 0.0,
		"atk_cd": 2.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": spot.x, "wz": spot.y, "dead": false, "respawn": 0.0,
		"boss": true, "home": spot, "stomp": 0.0, "swing": 0.0, "stun": 0.0, "phase": 1, "roar": 0.0, "wave_r": -1.0, "face": Vector2(0, 1)})

# ---- brick hedgehog ("방패 괴물"): a round toy with brick spikes. Within 2.4 tiles it curls for 1.0 s and
# turns every blow (a warning ring the last 0.6 s), then bursts its spikes (1.8 tiles, 8 + level) and is
# dizzy for 1.4 s, taking x1.3. Companions bounce off it too: Sora has to wait for the opening.
func make_hog() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	var body := Color("#8a6a4a")
	var spike := Color("#8a8a90")
	brick(g, mats, Vector3(0.56, 0.4, 0.62), Vector3(0, 0.28, 0), body)              # body
	brick(g, mats, Vector3(0.26, 0.22, 0.2), Vector3(0, 0.24, 0.38), Color("#c8a07a")) # face
	brick(g, mats, Vector3(0.08, 0.08, 0.06), Vector3(0, 0.22, 0.5), Color("#2a2420"), false) # nose
	brick(g, mats, Vector3(0.06, 0.06, 0.03), Vector3(-0.07, 0.3, 0.48), Color("#ffc23a"), false, true) # eyes
	brick(g, mats, Vector3(0.06, 0.06, 0.03), Vector3(0.07, 0.3, 0.48), Color("#ffc23a"), false, true)
	for k in 7: # spikes along the back
		var a := -1.2 + k * 0.4
		brick(g, mats, Vector3(0.12, 0.2, 0.12), Vector3(sin(a) * 0.24, 0.5 + cos(a) * 0.04, -0.1 + cos(a) * 0.12 - absf(a) * 0.08), spike, false)
	for k in 3:
		brick(g, mats, Vector3(0.12, 0.18, 0.12), Vector3(-0.2 + k * 0.2, 0.46, -0.3), spike, false)
	root.scale = Vector3.ONE * 1.3
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	return root

func spawn_hog(at: Vector2) -> void:
	var node := make_hog()
	m.add_child(node)
	var hp: int = 40 + m.foe_lv() * 9
	m.enemies.append({"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(0.7), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(0.5, 1.5), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"hog": true, "cave": true, "curl": 0.0, "dizzy": 0.0, "warned": false})

func update_hog(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var v := Vector2.ZERO
	var body: Node3D = e.node.get_meta("body")
	if e.curl > 0.0:
		e.curl -= dt
		if e.curl <= 0.6 and not e.warned:
			e.warned = true
			warn_ring(Vector3(e.x, 0.0, e.z), 1.8, 0.6)
		if e.curl <= 0.0: # the spikes burst
			e.curl = 0.0
			m.burst(Vector3(e.x, 0.4, e.z), Color("#8a8a90"), 24, 4.0)
			m.sfx(140, 0.2, "square", 0.2, -60)
			if d < 1.8:
				m.player_hit(8 + m.foe_lv(), Vector2(e.x, e.z), e)
			e.dizzy = 1.4
			e.atk_cd = 2.4
	elif e.dizzy > 0.0:
		e.dizzy -= dt
		v = Vector2(e.kx, e.kz)
	elif e.hurt > 0.0:
		v = Vector2(e.kx, e.kz)
	elif d < 2.4 and e.atk_cd <= 0.0 and not m.intro:
		e.curl = 1.0
		e.warned = false
	elif d < 7.0 and not m.intro:
		v = to / maxf(d, 0.01) * 1.2
	e.kx *= pow(0.002, dt)
	e.kz *= pow(0.002, dt)
	var nx: float = e.x + v.x * dt
	var nz: float = e.z + v.y * dt
	if m.walkable(nx, e.z): e.x = nx
	if m.walkable(e.x, nz): e.z = nz
	var node: Node3D = e.node
	node.position = Vector3(e.x, m.height_at(e.x, e.z), e.z)
	if e.dizzy > 0.0:
		node.rotation.y += dt * 9.0 # spins on the spot
	elif v.length() > 0.1:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(v.x, v.y), minf(1.0, dt * 8.0))
	var rolled: bool = e.curl > 0.0
	body.scale = Vector3(1.1, 0.75, 1.0) if rolled else Vector3.ONE # a tight ball while curled
	for mm in node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0.0 or (rolled and e.warned)
		mm.emission = Color("#ff3a2a") if rolled and e.hurt <= 0.0 else Color.WHITE
		mm.emission_energy_multiplier = 0.9
	e.shadow.position = Vector3(e.x, 0.02, e.z)

# 이음새: the gold sparks at its joints say "hit now"
func open_seam(e: Dictionary) -> void:
	if e.get("boss", false):
		return
	e.seam = 1.4
	if not e.has("pins"):
		e.pins = 3
	var y := m.height_at(e.x, e.z)
	for k in 3:
		m.burst(Vector3(e.x + cos(k * TAU / 3.0) * 0.35, y + 0.7, e.z + sin(k * TAU / 3.0) * 0.35), Color("#ffd84a"), 3, 0.8)
	m.pop_num(Vector3(e.x, y + 1.5, e.z), "틈!", Color("#ffd84a"))

# ---- field monsters of the open areas: they come back at their own spots when Sora walks into the area again
# (not while she stands there; the marsh keeps its 8 s respawn). Bosses, story fights, ambushes and the foes a
# quest counts are never in these lists, so they stay down.
func field_spots(area: String) -> Array:
	match area:
		"forest":
			if m.forest_q < 1:
				return []
			var out: Array = []
			for g in m.forest.goblins:
				out.append([g, "g"])
			for w in m.forest.wolves:
				out.append([w, "w"])
			return out
		"hill":
			return m.hill.foes if m.hill_q >= 1 else []
		"stairs":
			return m.stairs.foes if m.stairs_spawned else []
		"garden": # the yard below the arena; not while the mold fight holds the garden
			if not m.road_spawned or m.garden_q == 2 or m.garden_q == 3:
				return []
			return m.garden.road_foes
		"lake": # the guards below the weir, without the yard's ambush (x >= 296)
			if not m.south_spawned:
				return []
			return m.lake.south_foes.filter(func(f): return f[0].x < 296.0)
	return []

func spawn_field(area: String, i: int, f: Array) -> void:
	var at: Vector2 = f[0]
	match f[1]:
		"w": spawn_wolf(at)
		"b": spawn_bat(at)
		"j": spawn_hog(at)
		_:
			spawn_enemy(at, f[1] == "a")
			if f[1] == "s":
				m.give_shield(m.enemies[m.enemies.size() - 1])
	var e: Dictionary = m.enemies[m.enemies.size() - 1]
	e.cave = true # no 8 s respawn: they wait for the next visit
	e.field = area
	e.slot = i

# every spot of the area without a living foe gets a fresh one; the first visit spawns them all this way
func refill_field(area: String) -> void:
	var spots := field_spots(area)
	for i in spots.size():
		var alive := false
		for e in m.enemies.duplicate():
			if e.get("field", "") != area or e.get("slot", -1) != i:
				continue
			if not e.dead:
				alive = true
				continue
			if is_instance_valid(e.node): # the mold hides the garden's foes without freeing them
				e.node.queue_free()
			if is_instance_valid(e.shadow):
				e.shadow.queue_free()
			m.enemies.erase(e)
		if not alive:
			spawn_field(area, i, spots[i])

func update_enemies(dt: float, gy: float) -> void:
	for e in m.enemies.duplicate():
		if e.dead and e.get("boss", false):
			continue
		if e.dead and e.get("cave", false):
			continue
		if e.dead:
			e.respawn -= dt
			if e.respawn <= 0:
				m.enemies.erase(e)
				spawn_enemy(Vector2(-1, -1), e.get("archer", false))
			continue
		var to := Vector2(m.player.x - e.x, m.player.z - e.z)
		var d := to.length()
		var ev := Vector2.ZERO
		var boss: bool = e.get("boss", false)
		if boss:
			update_boss(e, dt, d, to, gy)
			continue
		if e.get("mole", false):
			m.cave.update_mole(e, dt, d, to)
			continue
		if e.get("noeul", false):
			m.village_life.update_noeul(e, dt, d, to)
			continue
		if e.get("mold", false):
			m.garden_zone.update_mold(e, dt, d, to)
			continue
		if e.get("turtle", false):
			m.lake_zone.update_turtle(e, dt, d, to)
			continue
		if e.get("crab", false):
			m.lake_zone.update_crab(e, dt, d, to)
			continue
		if e.get("scare", false):
			m.hill_zone.update_scarecrow(e, dt, d, to)
			continue
		if e.get("knight", false):
			m.castle_zone.update_knight(e, dt, d, to)
			continue
		if e.get("shard", false):
			m.garden_zone.update_shard(e, dt)
			continue
		if e.get("wolf", false):
			update_wolf(e, dt, d, to)
			continue
		if e.get("bat", false):
			update_bat(e, dt, d, to)
			continue
		if e.get("hawk", false):
			m.hill_zone.update_hawk(e, dt, d, to)
			continue
		# the kinds above tick their own clocks; ticking here too ran them at double speed
		e.t += dt
		e.atk_cd -= dt
		e.hurt -= dt
		if e.get("hog", false):
			update_hog(e, dt, d, to)
			continue
		if e.get("prop", false):
			e.shadow.position = Vector3(e.x, 0.02, e.z)
			continue
		if d < 7 and not m.intro and e.get("archer", false):
			if d < 4.0:
				ev = -to / maxf(d, 0.01) * 1.6
			elif d > 5.5:
				ev = to / d * 1.6
		elif d < 7 and not m.intro:
			if d > 0.9:
				ev = to / d * 2.3
		else:
			if Vector2(e.wx - e.x, e.wz - e.z).length() < 0.3 or m.rng.randf() < 0.005:
				e.wx = e.x + m.rnd(-3, 3)
				e.wz = e.z + m.rnd(-3, 3)
			var w := Vector2(e.wx - e.x, e.wz - e.z)
			if w.length() > 0.01:
				ev = w.normalized()
		ev += Vector2(e.kx, e.kz)
		e.kx *= pow(0.002, dt)
		e.kz *= pow(0.002, dt)
		if e.hurt > 0 or e.get("stun", 0.0) > 0.0 or e.get("wind", 0.0) > 0.0:
			ev = Vector2(e.kx, e.kz)
		e.stun = e.get("stun", 0.0) - dt
		e.seam = e.get("seam", 0.0) - dt
		e.dizzy = e.get("dizzy", 0.0) - dt
		var nx: float = e.x + ev.x * dt
		var nz: float = e.z + ev.y * dt
		if m.walkable(nx, e.z): e.x = nx
		if m.walkable(e.x, nz): e.z = nz
		if e.get("archer", false):
			if e.get("wind", 0.0) > 0.0:
				e.wind -= dt
				if e.wind <= 0.0:
					e.atk_cd = 2.5
					throw_brick(Vector2(e.x, e.z), to / maxf(d, 0.01), e)
			elif not m.intro and d < 6.0 and e.atk_cd <= 0 and e.hurt <= 0 and e.get("stun", 0.0) <= 0.0:
				e.wind = 0.6
				m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.3, e.z), "!", Color("#ffd84a"))
		# wind-up 0.45 s (glows red, puffs up, "!"), then strike if Sora is still within 1.3
		if e.get("wind", 0.0) > 0.0 and not e.get("archer", false):
			e.wind -= dt
			if e.wind <= 0.0:
				e.atk_cd = 1.6
				var hitd := int(round(m.rnd(5, 9) + m.foe_lv()))
				var whiff := true
				if d < 1.3:
					whiff = m.player_hit(hitd, Vector2(e.x, e.z), e) in ["flash_dodge", "flash_guard", "none"]
				else:
					var mid := m.mates.mate_near(Vector2(e.x, e.z), 1.3)
					if mid != "":
						m.hurt_mate(mid, hitd)
						whiff = false
				if whiff: # a miss leaves its joints open (이음새)
					open_seam(e)
		elif not e.get("archer", false) and not m.intro and (d < 1.1 or m.mates.mate_near(Vector2(e.x, e.z), 1.1) != "") and e.atk_cd <= 0 and e.hurt <= 0 and e.get("stun", 0.0) <= 0.0:
			e.wind = 0.45
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.3, e.z), "!", Color("#ff5a4a"))
		var ey := m.height_at(e.x, e.z)
		var hop := absf(sin(e.t * 6.0))
		var node: Node3D = e.node
		node.position = Vector3(e.x, ey + hop * 0.14, e.z)
		node.get_meta("body").scale = Vector3(1 + (1 - hop) * 0.08, 1 - (1 - hop) * 0.1, 1 + (1 - hop) * 0.08)
		if ev.length() > 0.1:
			node.rotation.y = atan2(ev.x, ev.y)
		var wind_now: bool = e.get("wind", 0.0) > 0.0
		node.scale = Vector3.ONE * (1.3 * e.get("size_k", 1.0) * (1.15 if wind_now else 1.0))
		for mm in node.get_meta("mats"):
			mm.emission_enabled = e.hurt > 0 or wind_now
			mm.emission = Color("#ff3a2a") if wind_now and e.hurt <= 0 else Color.WHITE
			mm.emission_energy_multiplier = 0.9
		e.shadow.position = Vector3(e.x, ey + 0.02, e.z)

# Brick King, two phases.
# Phase 1: stomp (1.2 s red ring, 3 tiles) every 3.2 s; a 0.6 s front swing when Sora is within 2.2.
# Phase 2 (below half): a 1.5 s roar (invulnerable, shoves Sora 4 tiles, calls two goblins),
# then stomps every 2.4 s with a 1.0 s wind-up and a shockwave ring that rolls out to 6 tiles.
func update_boss(e: Dictionary, dt: float, d: float, to: Vector2, gy: float) -> void:
	var node: Node3D = e.node
	var awake := d < 11.0 and not m.intro
	m.ui.boss.visible = awake or (m.ui.boss.visible and d < 16.0)
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	m.ui.boss_name.text = "벽돌왕"
	var me := Vector2(e.x, e.z)
	var ground := m.height_at(e.x, e.z)
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	var ev := Vector2.ZERO
	var stomp_wind := 1.2 if e.phase == 1 else 1.0
	if e.phase == 1 and e.hp < e.max_hp / 2.0:
		e.phase = 2
		e.roar = 1.5
		e.stomp = 0.0
		e.swing = 0.0
		m.ui.boss_bar.color = Color("#d84a6a")
		m.toast("벽돌왕이 성났다!")
		m.sfx(60, 1.2, "sawtooth", 0.35, -20)
		m.shake = 0.5
		if d < 5.0:
			var push := (Vector2(m.player.x, m.player.z) - me).normalized() * 4.0
			for k in 8: # slide back until something blocks
				var step := Vector2(m.player.x, m.player.z) + push / 8.0
				if m.walkable(step.x, step.y):
					m.player.x = step.x
					m.player.z = step.y
		spawn_enemy()
		spawn_enemy()
		for k in 2: # the two newcomers appear beside the king
			var g: Dictionary = m.enemies[m.enemies.size() - 1 - k]
			g.x = e.x + m.rnd(-2, 2)
			g.z = e.z + 2.0
	# shockwave ring rolling outwards (phase 2)
	if e.wave_r >= 0.0:
		var before: float = e.wave_r
		e.wave_r += 5.0 * dt
		if before < d and e.wave_r >= d and absf(d - e.wave_r) < 0.8:
			m.player_hit(int(8 + m.foe_lv()), me, e)
		if e.wave_r > 6.0:
			e.wave_r = -1.0
	if e.roar > 0.0:
		e.roar -= dt
		node.position = Vector3(e.x, ground + absf(sin(e.t * 30.0)) * 0.08, e.z)
	elif e.stun > 0.0:
		node.position = Vector3(e.x, ground, e.z)
	elif e.stomp > 0.0:
		e.stomp -= dt
		var k: float = 1.0 - e.stomp / stomp_wind
		node.position.y = ground + sin(k * PI) * 1.6
		if e.stomp <= 0.0:
			stomp_wave(Vector3(e.x, ground, e.z))
			if d < 3.0:
				m.player_hit(int(12 + m.foe_lv() * 2), me, e)
			if e.phase == 2:
				e.wave_r = 0.0
				ring_wave(Vector3(e.x, ground, e.z))
	elif e.swing > 0.0:
		e.swing -= dt
		if e.swing <= 0.0:
			m.effects.slash_fx(Vector3(e.x, ground + 0.4, e.z) + Vector3(e.face.x, 0, e.face.y) * 1.0, -atan2(e.face.y, e.face.x) - PI / 2.0 + 0.9, false)
			m.sfx(110, 0.12, "sawtooth", 0.25, 200)
			if d < 2.0 and (to / maxf(d, 0.01)).dot(e.face) > 0.5:
				m.player_hit(int(8 + m.foe_lv()), me, e)
	else:
		if awake and d > 1.8:
			ev = to / d * 1.4
		elif not awake:
			var back: Vector2 = e.home - me
			if back.length() > 0.5:
				ev = back.normalized() * 1.2
		ev += Vector2(e.kx, e.kz)
		e.kx *= pow(0.002, dt)
		e.kz *= pow(0.002, dt)
		var nx: float = e.x + ev.x * dt
		var nz: float = e.z + ev.y * dt
		if m.walkable(nx, e.z): e.x = nx
		if m.walkable(e.x, nz): e.z = nz
		e.atk_cd -= dt
		if awake and e.atk_cd <= 0.0:
			if e.phase == 1 and d < 2.2 and not e.get("swung", false): # swing and stomp take turns
				e.swung = true
				e.atk_cd = 1.6
				e.swing = 0.6
				e.face = to / maxf(d, 0.01)
				m.pop_num(Vector3(e.x, ground + 3.6, e.z), "!", Color.WHITE)
			else:
				e.swung = false
				e.atk_cd = stomp_wind + (3.2 if e.phase == 1 else 2.4)
				e.stomp = stomp_wind
				m.sfx(70, 0.4, "square", 0.25, 60)
				warn_ring(Vector3(e.x, ground, e.z), 3.0, stomp_wind)
		node.position = Vector3(e.x, ground + absf(sin(e.t * 3.0)) * 0.1, e.z)
	if ev.length() > 0.1:
		node.rotation.y = atan2(ev.x, ev.y)
	var swinging: bool = e.swing > 0.0
	for mm in node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0 or swinging or e.roar > 0.0 or e.stun > 0.0
		mm.emission = Color("#ff5a3a") if e.roar > 0.0 else (Color("#9fd4ff") if e.stun > 0.0 else Color.WHITE)
		mm.emission_energy_multiplier = 0.9
	e.shadow.position = Vector3(e.x, ground + 0.02, e.z)

# phase 2 shockwave: an orange ring that rolls out at 5 tiles/s to 6 tiles; roll through it
func ring_wave(pos: Vector3) -> void:
	var mm := MeshInstance3D.new()
	mm.mesh = m.ring_mesh(0.85, 1.0, 0.0, TAU)
	var mat := m.glow_mat(Color("#ff8a3a"), 2.5)
	mm.material_override = mat
	mm.position = pos + Vector3(0, 0.2, 0)
	m.add_fx(mm, 1.2, func(n: Node3D, k: float, _dt: float):
		n.scale = Vector3.ONE * maxf(0.01, k * 6.0)
		mat.albedo_color.a = 1.0 - k * 0.6)

# red ring on the ground showing where the stomp will land: step out or roll
func warn_ring(pos: Vector3, r: float, life: float) -> void:
	var mm := MeshInstance3D.new()
	mm.mesh = m.ring_mesh(r - 0.12, r, 0.0, TAU)
	var mat := m.glow_mat(Color("#ff4a3a"), 2.0)
	mm.material_override = mat
	mm.position = pos + Vector3(0, 0.08, 0)
	m.add_fx(mm, life, func(_n: Node3D, k: float, _dt: float):
		mat.albedo_color.a = 0.35 + 0.65 * absf(sin(k * PI * 4.0)))

func stomp_wave(pos: Vector3) -> void:
	m.shake = 0.45
	m.sfx(55, 0.5, "square", 0.35, -30)
	var mm := MeshInstance3D.new()
	mm.mesh = m.ring_mesh(0.4, 0.9, 0.0, TAU)
	var mat := m.glow_mat(Color("#ffb45a"), 2.5)
	mm.material_override = mat
	mm.position = pos + Vector3(0, 0.15, 0)
	m.add_fx(mm, 0.6, func(n: Node3D, k: float, _dt: float):
		n.scale = Vector3.ONE * (1.0 + k * 4.5)
		mat.albedo_color.a = 1.0 - k)
	m.burst(pos + Vector3(0, 0.3, 0), Color("#c9a066"), 30, 4.0)

func throw_brick(from: Vector2, dir: Vector2, owner: Dictionary) -> void:
	var b := m.box(Vector3(0.3, 0.2, 0.2), m.mat_color(Color("#c0522a")))
	b.position = Vector3(from.x, m.height_at(from.x, from.y) + 0.6, from.y)
	m.add_child(b)
	m.enemy_shots.append({"node": b, "v": dir * 4.0, "life": 2.0, "owner": owner})
	m.sfx(260, 0.08, "square", 0.12, -100)

func update_enemy_shots(dt: float) -> void:
	for i in range(m.enemy_shots.size() - 1, -1, -1):
		var sh: Dictionary = m.enemy_shots[i]
		sh.life -= dt
		var n: Node3D = sh.node
		n.position += Vector3(sh.v.x, 0, sh.v.y) * dt
		n.rotation.y += dt * 8.0
		var hit := Vector2(n.position.x - m.player.x, n.position.z - m.player.z).length() < 0.6
		if hit:
			m.player_hit(12, Vector2(n.position.x, n.position.z) - sh.v.normalized(), sh.owner)
		else:
			var mid := m.mates.mate_near(Vector2(n.position.x, n.position.z), 0.6)
			if mid != "":
				m.hurt_mate(mid, 10)
				hit = true
		if hit or sh.life <= 0.0 or not m.walkable(n.position.x, n.position.z):
			n.queue_free()
			m.enemy_shots.remove_at(i)

func update_projectiles(dt: float) -> void:
	for i in range(m.projectiles.size() - 1, -1, -1):
		var p: Dictionary = m.projectiles[i]
		p.life -= dt
		var node: Node3D = p.node
		node.position += Vector3(p.v.x, 0, p.v.y) * dt
		var hit = null
		for e in m.enemies:
			if not e.dead and Vector2(e.x - node.position.x, e.z - node.position.z).length() < 0.7:
				hit = e
				break
		if hit != null:
			m.damage_enemy(hit, m.player.atk * 1.8, Vector2(node.position.x, node.position.z) - p.v * 0.05, 6.0)
			m.burst(node.position, Color("#ff9a4a"), 22, 3.0)
		if hit != null or p.life <= 0:
			node.queue_free()
			m.projectiles.remove_at(i)
