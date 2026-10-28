# Monsters: goblins, wolves, bats, hedgehogs, the boss, enemy update loop, thrown bricks.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- mob behaviour: roles, telegraphs
# The plain goblins and the wolves list themselves while the loop runs; the next frame's roles are worked out from
# that list (e.role, e.spot, e.spot_ok for goblins; wolf_att and wolf_circler for wolves).
var next_gid := 0
var pack: Array = []        # plain goblins seen last frame
var pack_next: Array = []
var pack_cd := 0.0          # no goblin swing starts for this long after another goblin's swing
var pack_busy := 0          # gid of the goblin in a wind-up or lunge, 0 when none
var pack_att := 0           # gid of the pack's attacker
var wolf_pack: Array = []
var wolf_next: Array = []
var wolf_gap := 0.0         # no charge starts for this long after another one ends
var wolf_att := 0           # gid of the wolf that goes now
var wolf_circler := 0       # gid of the wolf circling to the far side, next to go

func gid_of(e: Dictionary) -> int:
	if not e.has("gid"):
		next_gid += 1
		e.gid = next_gid
	return e.gid

func foe_dist(e: Dictionary) -> float:
	return Vector2(e.x - m.player.x, e.z - m.player.z).length()

# a lane on the ground from `from` along `dir`: where a lunge, charge, swoop, roll or shot is going
func warn_path(from: Vector2, dir: Vector2, length: float, width: float, life: float) -> MeshInstance3D:
	var mat := m.glow_mat(Color("#ff4a3a"), 2.0)
	var mm := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.04, length)
	mm.mesh = bm
	mm.material_override = mat
	mm.set_meta("mat", mat)
	path_set(mm, from, dir, length)
	m.add_fx(mm, life, func(_n: Node3D, k: float, _dt: float):
		mat.albedo_color.a = 0.35 + 0.65 * absf(sin(k * PI * 4.0)))
	return mm

func path_set(mm: MeshInstance3D, from: Vector2, dir: Vector2, length: float) -> void:
	mm.rotation.y = atan2(dir.x, dir.y)
	mm.position = Vector3(from.x + dir.x * length / 2.0, m.height_at(from.x, from.y) + 0.1, from.y + dir.y * length / 2.0)

func path_tint(mm: MeshInstance3D, c: Color) -> void:
	var mat: StandardMaterial3D = mm.get_meta("mat")
	mat.albedo_color = Color(c.r, c.g, c.b, mat.albedo_color.a)
	mat.emission = c

# a fan on the ground (the lunge's cut): `arc` wide, `reach` long, pointing along `dir`
func warn_fan(pos: Vector2, dir: Vector2, reach: float, arc: float, life: float) -> MeshInstance3D:
	var mat := m.glow_mat(Color("#ff4a3a"), 1.6)
	var mm := MeshInstance3D.new()
	mm.mesh = m.ring_mesh(0.0, reach, atan2(dir.y, dir.x) - arc / 2.0, arc, 10)
	mm.material_override = mat
	mm.position = Vector3(pos.x, m.height_at(pos.x, pos.y) + 0.09, pos.y)
	m.add_fx(mm, life, func(_n: Node3D, k: float, _dt: float):
		mat.albedo_color.a = 0.25 + 0.4 * absf(sin(k * PI * 4.0)))
	return mm

# hide the telegraph a foe was showing (its fx frees the node by itself when the time is up)
func tele_clear(e: Dictionary) -> void:
	var t = e.get("tele", null)
	if t != null and is_instance_valid(t):
		t.visible = false
	e.tele = null

func goblin_ready(e: Dictionary) -> bool:
	return e.atk_cd <= 0.0 and e.hurt <= 0.0 and e.get("stun", 0.0) <= 0.0 and e.get("lrec", 0.0) <= 0.0

func wolf_ready(e: Dictionary) -> bool:
	return e.atk_cd <= 0.0 and e.hurt <= 0.0 and e.get("stun", 0.0) <= 0.0 and e.rest <= 0.0

# once a frame, before the foes move: who swings, who flanks, who hangs back; which wolf goes and which circles
func pack_prepare(dt: float) -> void:
	pack_cd -= dt
	wolf_gap -= dt
	var p := Vector2(m.player.x, m.player.z)
	# goblins: one attacker within 6 tiles, up to two flankers 2.2 tiles from Sora at +-70 degrees, the rest 3.5 tiles out
	pack = pack_next.filter(func(e): return not e.dead and is_instance_valid(e.node))
	pack_next = []
	pack_busy = 0
	var near: Array = []
	for e in pack:
		e.role = "back"
		e.spot_ok = false
		if e.get("wind", 0.0) > 0.0 or e.get("lwind", 0.0) > 0.0 or e.get("ldash", 0.0) > 0.0:
			pack_busy = e.gid
		if foe_dist(e) < 6.0:
			near.append(e)
	var att = null
	for e in near:
		if pack_busy == e.gid or (e.gid == pack_att and goblin_ready(e)):
			att = e
			break
	if att == null:
		var bd := 99.0
		for e in near:
			var de := foe_dist(e)
			if goblin_ready(e) and de < bd:
				bd = de
				att = e
	pack_att = att.gid if att != null else 0
	if att != null:
		att.role = "att"
	if not near.is_empty():
		var ref: Dictionary = att if att != null else near[0]
		if att == null:
			for e in near:
				if foe_dist(e) < foe_dist(ref):
					ref = e
		var theta := atan2(ref.z - p.y, ref.x - p.x)
		var rest: Array = near.filter(func(e): return e.gid != pack_att)
		rest.sort_custom(func(a, b): return foe_dist(a) < foe_dist(b))
		var side := 0.0
		for k in mini(2, rest.size()):
			var e: Dictionary = rest[k]
			var ang := wrapf(atan2(e.z - p.y, e.x - p.x) - theta, -PI, PI)
			var sg := 1.0 if ang >= 0.0 else -1.0
			if sg == side:
				sg = -sg # the second flanker takes the other side
			side = sg
			var sp := p + Vector2.RIGHT.rotated(theta + sg * deg_to_rad(70.0)) * 2.2
			e.role = "flank"
			e.spot = sp
			e.spot_ok = m.walkable(sp.x, sp.y) # a spot inside a wall is dropped: that goblin waits
	# wolves: of those within 7 tiles one goes, one circles to the far side to go next
	wolf_pack = wolf_next.filter(func(e): return not e.dead and is_instance_valid(e.node))
	wolf_next = []
	var wnear: Array = wolf_pack.filter(func(e): return foe_dist(e) < 7.0)
	var wa = null
	for e in wnear:
		e.role = "ring"
		if e.wind > 0.0 or e.dash > 0.0:
			wa = e
	if wa == null:
		for e in wnear:
			if e.gid == wolf_att and wolf_ready(e):
				wa = e
	if wa == null:
		for e in wnear:
			if e.gid == wolf_circler and wolf_ready(e):
				wa = e # the one that circled to the far side goes next
	if wa == null:
		var bw := 99.0
		for e in wnear:
			if wolf_ready(e) and foe_dist(e) < bw:
				wa = e
				bw = foe_dist(e)
	wolf_att = wa.gid if wa != null else 0
	wolf_circler = 0
	if wa != null:
		wa.role = "att"
		var wc = null
		for e in wnear:
			if e.gid != wolf_att and (wc == null or e.atk_cd < wc.atk_cd):
				wc = e
		if wc != null:
			wolf_circler = wc.gid
			var wth := atan2(wa.z - p.y, wa.x - p.x)
			var wang := wrapf(atan2(wc.z - p.y, wc.x - p.x) - wth, -PI, PI)
			wc.role = "circ"
			wc.spot = p + Vector2.RIGHT.rotated(wth + (PI / 2.0 if wang >= 0.0 else -PI / 2.0)) * 3.0
			wc.spot_ok = m.walkable(wc.spot.x, wc.spot.y)

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
	var hp: int = (20 + m.foe_lv() * 11) if archer else (30 + m.foe_lv() * 14)
	if archer: # brick archer: green body, mustard head
		var mats: Array = node.get_meta("mats")
		mats[2].albedo_color = Color("#3f8a3a")
		mats[5].albedo_color = Color("#d9b03a")
	m.enemies.append({"x": x, "z": z, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(0.8), "t": m.rnd(0, 5),
		"atk_cd": 1.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": x, "wz": z, "dead": false, "respawn": 0.0,
		"archer": archer, "cave": at.x >= Main.CAVE_X - 0.5})

# the Brick King waits at the northern edge of the map; he does not respawn
# ---- brick wolves: quick pack hunters in the forest and on the hill. A wolf circles Sora about 3 tiles out. They take
# turns: of the wolves within 7 tiles one charges, one circles to the far side (+-90 degrees, 3 tiles) and goes next,
# not before 0.4 s after the charge ends. A charge is a 0.45 s crouch ("!", the last 0.25 s with the direction locked and
# a red path), 8 tiles/s for 0.4 s (10 + level, once), then 0.8 s to catch its breath and 1.6 s before it goes again.
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
	var hp: int = 25 + m.foe_lv() * 10
	m.enemies.append({"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(0.7), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(1.0, 2.5), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"wolf": true, "cave": true, "wind": 0.0, "stun": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "rest": 0.0, "hit_done": false,
		"side": 1.0 if m.rng.randf() < 0.5 else -1.0})

func update_wolf(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	gid_of(e)
	wolf_next.append(e)
	e.t += dt
	e.atk_cd -= dt
	e.hurt -= dt
	e.rest -= dt
	e.stun = e.get("stun", 0.0) - dt
	var dirn: Vector2 = to / maxf(d, 0.01)
	var v := Vector2.ZERO
	if e.hurt > 0.0 or e.stun > 0.0:
		if e.dash > 0.0 or e.get("locked", false):
			wolf_gap = maxf(wolf_gap, 0.4) # a charge cut short still counts as ended
		e.dash = 0.0
		e.wind = 0.0
		e.locked = false
		tele_clear(e)
		v = Vector2(e.kx, e.kz)
	elif e.dash > 0.0:
		e.dash -= dt
		v = e.dir * 8.0
		if not e.hit_done and d < 1.0:
			e.hit_done = true
			m.player_hit(10 + m.foe_hit(), Vector2(e.x, e.z), e)
		if e.dash <= 0.0:
			e.rest = 0.8
			wolf_gap = 0.4
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind > 0.25:
			e.dir = dirn # it still follows her
		elif not e.get("locked", false): # the last 0.25 s: the line is set and shown
			e.locked = true
			e.dir = dirn
			e.tele = warn_path(Vector2(e.x, e.z), e.dir, 3.2, 0.9, 0.25)
		if e.wind <= 0.0:
			e.dash = 0.4
			e.hit_done = false
			e.locked = false
			e.atk_cd = 1.6
	elif e.rest > 0.0:
		pass
	elif d < 9.0 and not m.intro:
		if e.gid == wolf_att and wolf_gap <= 0.0 and e.atk_cd <= 0.0 and d < 4.0:
			e.wind = 0.45
			e.dir = dirn
			e.locked = false
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.1, e.z), "!", Color("#ff5a4a"))
		elif e.get("role", "ring") == "circ" and e.get("spot_ok", false):
			var w: Vector2 = e.spot - Vector2(e.x, e.z) # to the far side, where it waits for its turn
			if w.length() > 0.25:
				v = w.normalized() * 3.2
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
	if e.dash > 0.0 or e.get("locked", false):
		node.rotation.y = atan2(e.dir.x, e.dir.y)
	elif e.wind > 0.0:
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
	var hp: int = 15 + m.foe_lv() * 7
	m.enemies.append({"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": root, "shadow": m.blob(0.4), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(1.5, 3.0), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"bat": true, "cave": true, "wind": 0.0, "stun": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "hit_done": false,
		"rest": 0.0, "swoops": 0, "landed": false})

# a swoop's wind-up: 0.45 s with the line locked from the start and drawn in red on the ground
func bat_wind(e: Dictionary, dirn: Vector2) -> void:
	e.wind = 0.45
	e.dir = dirn
	e.tele = warn_path(Vector2(e.x, e.z), dirn, 2.8, 0.7, 0.45)
	m.pop_num(Vector3(e.x, 2.0, e.z), "!", Color("#ff5a4a"))

# swoops: 0.45 s wind-up (line locked from the start), 8 tiles/s for 0.35 s. If the first one misses and Sora is within
# 4 tiles the bat turns and tries ONE more; a hit, a flash guard or a blow on the bat calls the second off.
# After the last: 0.7 s of rest and 2.4 s before it starts again.
func update_bat(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
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
		e.swoops = 1 # no second swoop after this
		tele_clear(e)
		v = Vector2(e.kx, e.kz)
	elif e.dash > 0.0:
		e.dash -= dt
		v = e.dir * 8.0
		if not e.hit_done and d < 0.8:
			e.hit_done = true
			e.landed = not (m.player_hit(9 + m.foe_hit(), Vector2(e.x, e.z), e) in ["flash_dodge", "flash_guard", "none"])
		if e.dash <= 0.0:
			if not e.landed and e.swoops == 0 and d < 4.0 and e.stun <= 0.0 and not m.intro:
				e.swoops = 1 # it stops, turns and goes once more
				bat_wind(e, dirn)
			else:
				e.rest = 0.7
				e.atk_cd = 2.4
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			e.dash = 0.35
			e.hit_done = false
			e.landed = false
	elif e.rest > 0.0:
		pass
	elif d < 8.0 and not m.intro:
		if e.atk_cd <= 0.0 and d < 4.0:
			e.swoops = 0
			bat_wind(e, dirn)
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
	var face: Vector2 = e.dir if (e.wind > 0.0 or e.dash > 0.0) else dirn
	node.rotation.y = atan2(face.x, face.y)
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
	var hp := 1235 # was 950; x1.3 (the owner, 2026-10-28: "30분이 걸렸다, 3시간 목표" - bosses tougher)
	m.enemies.append({"x": spot.x, "z": spot.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(2.4), "t": 0.0,
		"atk_cd": 2.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": spot.x, "wz": spot.y, "dead": false, "respawn": 0.0,
		"boss": true, "home": spot, "stomp": 0.0, "swing": 0.0, "stun": 0.0, "phase": 1, "roar": 0.0, "wave_r": -1.0, "face": Vector2(0, 1)})

# ---- brick hedgehog ("방패 괴물"): a round toy with brick spikes. Within 2 tiles it curls for 1.0 s and
# turns every blow (a warning ring the last 0.6 s), then bursts its spikes (1.8 tiles, 8 + level) and is
# dizzy for 1.4 s, taking x1.3. At 2-4 tiles it rolls in first: 0.55 s curled with the line locked toward where Sora
# stood (the path and the burst circle drawn), 5 tiles/s for 0.3 s (touching hurts nobody), then the full 0.6 s warning
# at the real stop. Companions bounce off it too: Sora has to wait for the opening.
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
	var hp: int = 40 + m.foe_lv() * 13
	m.enemies.append({"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(0.7), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(0.5, 1.5), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"hog": true, "cave": true, "curl": 0.0, "dizzy": 0.0, "warned": false, "rolling": false, "rdir": Vector2.ZERO})

# where a roll from `from` along `dir` ends: 1.5 tiles, or short of a wall
func roll_stop(from: Vector2, dir: Vector2) -> Vector2:
	var at := from
	for k in 15:
		var nx := from + dir * (0.1 * (k + 1))
		if not m.walkable(nx.x, nx.y):
			break
		at = nx
	return at

func update_hog(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var v := Vector2.ZERO
	var body: Node3D = e.node.get_meta("body")
	if e.curl > 0.0:
		e.curl -= dt
		if e.rolling and e.curl > 0.6 and e.curl <= 0.9: # the roll: 5 tiles/s for 0.3 s, no damage
			v = e.rdir * 5.0
			var step: Vector2 = e.rdir * 5.0 * dt
			if not m.walkable(e.x + step.x, e.z + step.y):
				e.curl = 0.6 # a wall: it stops here and the warning below is drawn at this spot
				v = Vector2.ZERO
		if e.curl <= 0.6 and not e.warned:
			e.warned = true
			warn_ring(Vector3(e.x, 0.0, e.z), 1.8, 0.6)
		if e.curl <= 0.0: # the spikes burst
			e.curl = 0.0
			e.rolling = false
			m.burst(Vector3(e.x, 0.4, e.z), Color("#8a8a90"), 24, 4.0)
			m.sfx(140, 0.2, "square", 0.2, -60)
			if d < 1.8:
				m.player_hit(8 + m.foe_hit(), Vector2(e.x, e.z), e)
			e.dizzy = 1.4
			e.atk_cd = 2.4
	elif e.dizzy > 0.0:
		e.dizzy -= dt
		v = Vector2(e.kx, e.kz)
	elif e.hurt > 0.0:
		v = Vector2(e.kx, e.kz)
	elif d < 2.0 and e.atk_cd <= 0.0 and not m.intro:
		e.curl = 1.0
		e.warned = false
	elif d <= 4.0 and e.atk_cd <= 0.0 and not m.intro: # rolls in toward where Sora stands now
		var dirn: Vector2 = to / maxf(d, 0.01)
		var stop := roll_stop(Vector2(e.x, e.z), dirn)
		e.rolling = true
		e.rdir = dirn
		e.curl = 1.45 # 0.55 wind-up + 0.3 roll + 0.6 warning
		e.warned = false
		warn_path(Vector2(e.x, e.z), dirn, Vector2(e.x, e.z).distance_to(stop), 0.5, 0.55)
		warn_ring(Vector3(stop.x, 0.0, stop.y), 1.8, 0.55)
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
	elif e.rolling and e.curl > 0.6:
		node.rotation.y = atan2(e.rdir.x, e.rdir.y)
	elif v.length() > 0.1:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(v.x, v.y), minf(1.0, dt * 8.0))
	var rolled: bool = e.curl > 0.0
	body.scale = Vector3(1.1, 0.75, 1.0) if rolled else Vector3.ONE # a tight ball while curled
	for mm in node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0.0 or (rolled and (e.warned or e.rolling))
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
			return (m.stairs.foes + m.brick_foes.spots("stairs")) if m.stairs_spawned else []
		"castle": # the castle's dry corridors: pendulum sentries only
			return m.brick_foes.spots("castle") if m.castle_spawned else []
		"garden": # the yard below the arena; not while the mold fight holds the garden
			if not m.road_spawned or m.garden_q == 2 or m.garden_q == 3:
				return []
			return m.garden.road_foes + m.brick_foes.spots("garden")
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
		"h": m.brick_foes.spawn_hopper(at)
		"p": m.brick_foes.spawn_pendulum(at)
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

# v0.1.72: a boss or mini-boss counts as "in a fight" from the moment she comes within 12 tiles or hurts it, until it dies
# or she is 40 tiles away, so resting cannot heal her just by stepping out of the bar's range (the owner chose "bosses get
# tougher", 2026-10-28; boss7 review)
const FIGHT_KEYS := ["boss", "noeul", "turtle", "crab", "hawk", "knight", "mole", "mold", "mill_guard"]
func mark_fight(e: Dictionary, d: float) -> void:
	for k in FIGHT_KEYS:
		if e.get(k, false):
			if d >= 40.0:
				e.fight = false
			elif d < 12.0 or e.hp < e.max_hp:
				e.fight = true
			return

func boss_fight_on(px: float, pz: float) -> bool:
	for e in m.enemies:
		if not e.dead and e.get("fight", false) and Vector2(e.x - px, e.z - pz).length() < 40.0:
			return true
	return false

func update_enemies(dt: float, gy: float) -> void:
	pack_prepare(dt)
	m.brick_foes.village_moths()
	for e in m.enemies.duplicate():
		if e.dead and e.get("boss", false):
			continue
		if e.dead and e.get("cave", false):
			continue
		if e.dead and e.get("bird", false): # the marsh keeps its 8 s respawn, a bird comes back as a bird
			e.respawn -= dt
			if e.respawn <= 0:
				m.enemies.erase(e)
				m.brick_foes.spawn_bird_random()
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
		mark_fight(e, d)
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
		if e.get("bird", false):
			m.brick_foes.update_bird(e, dt, d, to)
			continue
		if e.get("moth", false):
			m.brick_foes.update_moth(e, dt, d, to)
			continue
		if e.get("hopper", false):
			m.brick_foes.update_hopper(e, dt, d, to)
			continue
		if e.get("pendulum", false):
			m.brick_foes.update_pendulum(e, dt, d, to)
			continue
		if e.get("prop", false):
			e.shadow.position = Vector3(e.x, 0.02, e.z)
			continue
		var archer: bool = e.get("archer", false)
		if archer:
			e.hop_cd = e.get("hop_cd", 0.0) - dt
		else:
			gid_of(e)
			pack_next.append(e)
		var hidden: bool = m.lamp_safe and not boss # resting by a lit lantern at night: not noticed (hud_build.update_pips)
		if d < 7 and not m.intro and archer and not hidden:
			if e.get("hop", 0.0) > 0.0: # the hop back: 1.2 tiles in 0.3 s, no damage
				e.hop -= dt
				ev = e.hop_dir * 4.0
			elif d < 2.0 and e.get("wind", 0.0) <= 0.0 and e.hop_cd <= 0.0 and e.hurt <= 0.0 and e.get("stun", 0.0) <= 0.0:
				var away: Vector2 = -to / maxf(d, 0.01)
				if m.walkable(e.x + away.x * 0.6, e.z + away.y * 0.6) and m.walkable(e.x + away.x * 1.2, e.z + away.y * 1.2):
					e.hop = 0.3
					e.hop_dir = away
					e.hop_cd = 3.0
					ev = away * 4.0
			elif d < 4.0:
				ev = -to / maxf(d, 0.01) * 1.6
			elif d > 5.5:
				ev = to / d * 1.6
		elif d < 7 and not m.intro and not hidden:
			ev = pack_move(e, d, to)
		else:
			if hidden and d < 4.0: # wandering near the lantern's light: it drifts off the other way
				e.wx = e.x - to.x / maxf(d, 0.01) * 3.0
				e.wz = e.z - to.y / maxf(d, 0.01) * 3.0
			elif Vector2(e.wx - e.x, e.wz - e.z).length() < 0.3 or m.rng.randf() < 0.005:
				e.wx = e.x + m.rnd(-3, 3)
				e.wz = e.z + m.rnd(-3, 3)
			var w := Vector2(e.wx - e.x, e.wz - e.z)
			if w.length() > 0.01:
				ev = w.normalized()
		ev += Vector2(e.kx, e.kz)
		e.kx *= pow(0.002, dt)
		e.kz *= pow(0.002, dt)
		if e.hurt > 0 or e.get("stun", 0.0) > 0.0 or e.get("wind", 0.0) > 0.0 or e.get("lwind", 0.0) > 0.0 or e.get("lrec", 0.0) > 0.0:
			ev = Vector2(e.kx, e.kz)
		elif e.get("ldash", 0.0) > 0.0:
			ev = e.ldir * 4.0 # the lunge's dash: 0.6 tile in 0.15 s
		e.stun = e.get("stun", 0.0) - dt
		e.seam = e.get("seam", 0.0) - dt
		e.dizzy = e.get("dizzy", 0.0) - dt
		var nx: float = e.x + ev.x * dt
		var nz: float = e.z + ev.y * dt
		if m.walkable(nx, e.z): e.x = nx
		if m.walkable(e.x, nz): e.z = nz
		if archer:
			archer_aim(e, dt, d, to)
		else:
			goblin_attack(e, dt, d, to)
		var ey := m.height_at(e.x, e.z)
		var hop := absf(sin(e.t * 6.0))
		var node: Node3D = e.node
		node.position = Vector3(e.x, ey + hop * 0.14, e.z)
		node.get_meta("body").scale = Vector3(1 + (1 - hop) * 0.08, 1 - (1 - hop) * 0.1, 1 + (1 - hop) * 0.08)
		if e.get("lwind", 0.0) > 0.0:
			node.rotation.y = atan2(e.ldir.x, e.ldir.y) # the lunge's direction is locked
		elif ev.length() > 0.1:
			node.rotation.y = atan2(ev.x, ev.y)
		var wind_now: bool = e.get("wind", 0.0) > 0.0 or e.get("lwind", 0.0) > 0.0
		node.scale = Vector3.ONE * (1.3 * e.get("size_k", 1.0) * (1.15 if wind_now else 1.0))
		for mm in node.get_meta("mats"):
			mm.emission_enabled = e.hurt > 0 or wind_now
			mm.emission = Color("#ff3a2a") if wind_now and e.hurt <= 0 else Color.WHITE
			mm.emission_energy_multiplier = 0.9
		e.shadow.position = Vector3(e.x, ey + 0.02, e.z)

# where a plain goblin goes: the attacker closes in, flankers take their spots, the rest hang back
func pack_move(e: Dictionary, d: float, to: Vector2) -> Vector2:
	var role: String = e.get("role", "back")
	if d >= 6.0 or role == "att":
		return to / d * 2.3 if d > 0.9 else Vector2.ZERO
	if role == "flank":
		if not e.get("spot_ok", false):
			return Vector2.ZERO # the spot is in a wall: it waits
		var w: Vector2 = e.spot - Vector2(e.x, e.z)
		return w.normalized() * 2.3 if w.length() > 0.15 else Vector2.ZERO
	return to / maxf(d, 0.01) * clampf(d - 3.5, -1.0, 1.0) * 2.3

# The plain goblin's blows. Only the pack's attacker starts one, and never within 0.9 s of another goblin's swing.
# Close in (under 1.1 tiles): a 0.45 s wind-up, then a cut at reach 1.3 for 9 + level. From 1.1 to 2.2 tiles it may
# lunge: 0.55 s wind-up with the direction locked (the fan is drawn), a 0.6 tile dash in 0.15 s and one cut over a
# 100 degree fan. Either way 1.6 s before its next blow; a lunge that misses leaves it 0.65 s open and shows its seams.
func goblin_attack(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var gid := gid_of(e)
	e.lrec = e.get("lrec", 0.0) - dt
	if d > 2.6:
		e.lpick = 0
	if e.hurt > 0.0 or e.get("stun", 0.0) > 0.0: # a blow or a flash guard calls the lunge off
		e.lwind = 0.0
		e.ldash = 0.0
		tele_clear(e)
	if e.get("lwind", 0.0) > 0.0:
		e.lwind -= dt
		if e.lwind <= 0.0:
			e.ldash = 0.15
			tele_clear(e)
	elif e.get("ldash", 0.0) > 0.0:
		e.ldash -= dt
		if e.ldash <= 0.0:
			lunge_cut(e)
	elif e.get("wind", 0.0) > 0.0:
		# wind-up 0.45 s (glows red, puffs up, "!"), then strike if Sora is still within 1.3
		e.wind -= dt
		if e.wind <= 0.0:
			e.atk_cd = 1.6
			pack_cd = 0.9
			var hitd := 9 + m.foe_hit()
			var whiff := true
			if d < 1.3:
				whiff = m.player_hit(hitd, from, e) in ["flash_dodge", "flash_guard", "none"]
			else:
				var mid := m.mates.mate_near(from, 1.3)
				if mid != "":
					m.hurt_mate(mid, hitd)
					whiff = false
			if whiff: # a miss leaves its joints open (이음새)
				open_seam(e)
	elif not m.intro and goblin_ready(e) and pack_cd <= 0.0 and (pack_busy == 0 or pack_busy == gid):
		var role: String = e.get("role", "back")
		var mate_close: bool = m.mates.mate_near(from, 1.1) != ""
		if (role == "att" and d < 1.1) or mate_close:
			e.wind = 0.45
			pack_busy = gid
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.3, e.z), "!", Color("#ff5a4a"))
		elif role == "att" and d >= 1.1 and d <= 2.2:
			if e.get("lpick", 0) == 0:
				e.lpick = 1 if m.rng.randf() < 0.5 else -1 # a coin toss once per approach
			if e.lpick == 1:
				e.lwind = 0.55
				e.ldir = dirn
				e.lpick = 0
				pack_busy = gid
				e.tele = warn_fan(from + dirn * 0.6, dirn, 1.3, deg_to_rad(100.0), 0.55)
				m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.3, e.z), "!", Color("#ff5a4a"))

# the lunge's cut, right after the dash: 100 degree fan, reach 1.3
func lunge_cut(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	var to := Vector2(m.player.x - e.x, m.player.z - e.z)
	e.atk_cd = 1.6
	pack_cd = 0.9
	var hitd := 9 + m.foe_hit()
	var whiff := true
	if to.length() < 1.3 and absf(e.ldir.angle_to(to)) <= deg_to_rad(50.0):
		whiff = m.player_hit(hitd, from, e) in ["flash_dodge", "flash_guard", "none"]
	else:
		var mid := m.mates.mate_near(from, 1.3)
		if mid != "":
			m.hurt_mate(mid, hitd)
			whiff = false
	m.burst(Vector3(e.x, m.height_at(e.x, e.z) + 0.6, e.z), Color("#ffd28a"), 5, 2.0)
	if whiff:
		e.lrec = 0.65
		open_seam(e)

# The archer: a 0.65 s aim with a red line on the ground that follows Sora and, for the last 0.25 s, stays put and
# turns white; then a brick (6 tiles/s, 1.2 s) along that locked line. 2 s before the next shot.
func archer_aim(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	if e.get("wind", 0.0) > 0.0:
		e.wind -= dt
		if e.wind > 0.25:
			e.aim = dirn
		elif not e.get("aim_locked", false):
			e.aim_locked = true
			if e.get("tele", null) != null and is_instance_valid(e.tele):
				path_tint(e.tele, Color.WHITE)
		if e.wind <= 0.0:
			e.atk_cd = 2.0
			e.aim_locked = false
			tele_clear(e)
			throw_brick(from, e.aim, e, 6.0, 1.2, 10 + m.foe_hit())
		elif not e.aim_locked and e.get("tele", null) != null and is_instance_valid(e.tele):
			path_set(e.tele, from, e.aim, 6.0)
	else:
		if e.get("tele", null) != null:
			tele_clear(e) # the aim was knocked off
		if not m.intro and d < 6.0 and e.atk_cd <= 0 and e.hurt <= 0 and e.get("stun", 0.0) <= 0.0 and e.get("hop", 0.0) <= 0.0:
			e.wind = 0.65
			e.aim = dirn
			e.aim_locked = false
			e.tele = warn_path(from, dirn, 6.0, 0.14, 0.7)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.3, e.z), "!", Color("#ffd84a"))

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
			m.player_hit(int(8 + m.foe_hit()), me, e)
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
				m.player_hit(int(12 + m.foe_hit() * 1.5), me, e)
			if e.phase == 2:
				e.wave_r = 0.0
				ring_wave(Vector3(e.x, ground, e.z))
	elif e.swing > 0.0:
		e.swing -= dt
		if e.swing <= 0.0:
			m.effects.slash_fx(Vector3(e.x, ground + 0.4, e.z) + Vector3(e.face.x, 0, e.face.y) * 1.0, -atan2(e.face.y, e.face.x) - PI / 2.0 + 0.9, false)
			m.sfx(110, 0.12, "sawtooth", 0.25, 200)
			if d < 2.0 and (to / maxf(d, 0.01)).dot(e.face) > 0.5:
				m.player_hit(int(8 + m.foe_hit()), me, e)
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

func throw_brick(from: Vector2, dir: Vector2, owner: Dictionary, speed := 4.0, life := 2.0, dmg := 12) -> void:
	var b := m.box(Vector3(0.3, 0.2, 0.2), m.mat_color(Color("#c0522a")))
	b.position = Vector3(from.x, m.height_at(from.x, from.y) + 0.6, from.y)
	m.add_child(b)
	m.enemy_shots.append({"node": b, "v": dir * speed, "life": life, "owner": owner, "dmg": dmg})
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
			m.player_hit(sh.dmg, Vector2(n.position.x, n.position.z) - sh.v.normalized(), sh.owner)
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
