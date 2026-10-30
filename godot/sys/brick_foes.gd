# Four brick field foes, one per area, each with ONE telegraph and an answer the game already has:
#   bird (벽돌 딱따기새, marsh): lifts its beak 0.6 s over a thin red line, pecks it once, neck seam open 0.9 s.
#   moth (벽돌 등나방, lantern village by night): belly swells 0.7 s over a ring, one light burst; leave and come back.
#   hopper (벽돌 씨앗통, Hangyeol's road): lid open 0.8 s over three lines (+-25 degrees), fires seed bricks along all three.
#   pendulum (벽돌 추시계병, castle and stairs): pendulum up 0.8 s over a front half circle, one sweep, back seam open 1 s later.
# Numbers are the plain goblin's (30 + 14 per foe level hp, 9 + foe_hit a blow) times the factors in each spawn and attack.
# `m` is the main node (main.gd); update_enemies in monsters.gd calls update_bird and the others.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main
var moths_out := false # the village moths are up (lantern village, at night)

# outer-alley tiles of the village, each 6+ tiles from every villager, stall, the inn door and every lantern (rest spots)
const MOTH_SPOTS := [Vector2i(27, 2), Vector2i(2, 2), Vector2i(2, 18), Vector2i(46, 30), Vector2i(41, 34)]
# the road clearing below the garden's arena (garden.gd ROAD_ROWS), clear of the camp, the waystone and the arena gate
const HOPPER_SPOTS := [Vector2i(13, 36), Vector2i(6, 36)]
# dry corridors of the castle (the east strip of the great hall, the entry hall) and wide landings of the stairs
const CASTLE_SPOTS := [Vector2i(19, 16), Vector2i(5, 15)]
const STAIRS_SPOTS := [Vector2i(10, 15), Vector2i(5, 19)]

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- shared bits
func foe_hp(k: float) -> int:
	return int(round(k * (30 + m.foe_lv() * 14)))

func foe_dmg(k: float) -> int:
	return int(round(k * (9 + m.foe_hit())))

func cyl(g: Node3D, mats: Array, r: float, h: float, pos: Vector3, color: Color, rot := Vector3.ZERO) -> void:
	var mm := StandardMaterial3D.new()
	mm.albedo_color = color
	mm.roughness = 0.32
	mats.append(mm)
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	var n := MeshInstance3D.new()
	n.mesh = c
	n.material_override = mm
	n.position = pos
	n.rotation = rot
	g.add_child(n)

# a glowing yellow-white box (a seam, a belly): not in mats, so the hurt flash leaves it alone
func glow_box(g: Node3D, size: Vector3, pos: Vector3, color: Color, energy := 3.0) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	var b := m.box(size, mat)
	b.position = pos
	g.add_child(b)
	return b

func base_entry(node: Node3D, at: Vector2, hp: int, blob_r: float, extra: Dictionary) -> Dictionary:
	m.add_child(node)
	var e := {"x": at.x, "z": at.y, "hp": float(hp), "max_hp": hp, "node": node, "shadow": m.blob(blob_r), "t": m.rnd(0, 5),
		"atk_cd": m.rnd(0.4, 1.2), "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 0.0,
		"cave": true, "tele_t": 0.0, "seam": 0.0, "stun": 0.0, "dizzy": 0.0, "face": Vector2(0, 1)}
	e.merge(extra, true)
	m.enemies.append(e)
	return e

func tick(e: Dictionary, dt: float) -> void:
	e.stun = e.get("stun", 0.0) - dt
	e.seam = e.get("seam", 0.0) - dt
	e.dizzy = e.get("dizzy", 0.0) - dt

func free_to_act(e: Dictionary) -> bool:
	return e.atk_cd <= 0.0 and e.hurt <= 0.0 and e.stun <= 0.0 and not m.intro

# a point is inside the lane from `from` along `dir`: `len` long, `half_w` either side
func in_lane(from: Vector2, dir: Vector2, len: float, half_w: float, p: Vector2) -> bool:
	var rel := p - from
	return rel.dot(dir) >= -0.2 and rel.dot(dir) <= len and absf(rel.cross(dir)) <= half_w

func mate_hit(at: Vector2, r: float, dmg: int) -> void:
	var mid: String = m.mates.mate_near(at, r)
	if mid != "":
		m.hurt_mate(mid, dmg)

# walk, shed knockback, place the node and the shadow; `lift` is a hover height
func finish(e: Dictionary, v: Vector2, dt: float, lift := 0.0) -> void:
	e.kx *= pow(0.002, dt)
	e.kz *= pow(0.002, dt)
	var nx: float = e.x + v.x * dt
	var nz: float = e.z + v.y * dt
	if m.walkable(nx, e.z): e.x = nx
	if m.walkable(e.x, nz): e.z = nz
	var ey := m.height_at(e.x, e.z)
	var node: Node3D = e.node
	node.position = Vector3(e.x, ey + lift, e.z)
	e.shadow.position = Vector3(e.x, ey + 0.02, e.z)

func face_to(e: Dictionary, dir: Vector2, dt: float, snap := false) -> void:
	var node: Node3D = e.node
	if snap:
		node.rotation.y = atan2(dir.x, dir.y)
	else:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(dir.x, dir.y), minf(1.0, dt * 8.0))

# the hurt flash and the red glow of a telegraph on every brick that can take it
func flash(e: Dictionary, red: bool) -> void:
	for mm in e.node.get_meta("mats"):
		mm.emission_enabled = e.hurt > 0.0 or red
		mm.emission = Color("#ff3a2a") if red and e.hurt <= 0.0 else Color.WHITE
		mm.emission_energy_multiplier = 0.9

func wander(e: Dictionary) -> Vector2:
	if Vector2(e.wx - e.x, e.wz - e.z).length() < 0.3 or m.rng.randf() < 0.005:
		e.wx = e.x + m.rnd(-3, 3)
		e.wz = e.z + m.rnd(-3, 3)
	var w := Vector2(e.wx - e.x, e.wz - e.z)
	return w.normalized() * 0.8 if w.length() > 0.01 else Vector2.ZERO

func seam_for(e: Dictionary, secs: float) -> void:
	m.monsters.open_seam(e)
	e.seam = secs

# ---------------------------------------------------------------- 벽돌 딱따기새 (marsh)
# hp 0.8x, speed 1.5, blow 0.9x. Within 2.7 tiles: beak up 0.6 s over a 2.5 tile red line locked at that moment, one peck
# along it, then the neck seam is open 0.9 s (the bird stands stuck). 2.4 s from one beak lift to the next.
func make_bird() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	var body := Color("#6a6e8a")
	cyl(g, mats, 0.04, 0.3, Vector3(-0.1, 0.15, 0.0), Color("#c89a3a"))
	cyl(g, mats, 0.04, 0.3, Vector3(0.1, 0.15, 0.0), Color("#c89a3a"))
	m.brick(g, mats, Vector3(0.4, 0.3, 0.5), Vector3(0, 0.45, -0.02), body)
	m.brick(g, mats, Vector3(0.24, 0.1, 0.3), Vector3(0, 0.62, -0.32), Color("#4a4e6a"), false) # tail
	m.brick(g, mats, Vector3(0.14, 0.3, 0.14), Vector3(0, 0.74, 0.14), body, false) # neck
	m.brick(g, mats, Vector3(0.26, 0.24, 0.26), Vector3(0, 0.98, 0.2), Color("#b4231e"))
	m.brick(g, mats, Vector3(0.05, 0.06, 0.03), Vector3(-0.1, 1.02, 0.34), Color("#ffc23a"), false, true)
	m.brick(g, mats, Vector3(0.05, 0.06, 0.03), Vector3(0.1, 1.02, 0.34), Color("#ffc23a"), false, true)
	var pivot := Node3D.new() # the beak turns at the head
	pivot.position = Vector3(0, 0.96, 0.32)
	g.add_child(pivot)
	m.brick(pivot, mats, Vector3(0.08, 0.08, 0.56), Vector3(0, 0, 0.28), Color("#e8dcc0"), false)
	var seam := glow_box(g, Vector3(0.18, 0.05, 0.18), Vector3(0, 0.8, 0.14), Color("#ffd84a"))
	seam.visible = false
	root.scale = Vector3.ONE * 1.3
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	root.set_meta("beak", pivot)
	root.set_meta("seam", seam)
	return root

func spawn_bird(at: Vector2) -> Dictionary:
	return base_entry(make_bird(), at, foe_hp(0.8), 0.7, {"bird": true, "cave": false})

# a clear dry spot (all eight neighbours 2 tiles out walkable), 9+ tiles from Sora and 8+ from Bori's cottage
func spawn_bird_random() -> void:
	for tries in 600:
		var x := m.rnd(4, 44)
		var z := m.rnd(4, Main.N - 4)
		var open := true
		for k in 8:
			var a := k * TAU / 8.0
			if not m.walkable(x + cos(a) * 2.0, z + sin(a) * 2.0):
				open = false
		if open and m.walkable(x, z) and Vector2(x - m.player.x, z - m.player.z).length() >= 9.0 \
				and (m.cottage_at.x < 0.0 or Vector2(x, z).distance_to(m.cottage_at) >= 8.0):
			spawn_bird(Vector2(x, z))
			return

func update_bird(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	tick(e, dt)
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	var beak: Node3D = e.node.get_meta("beak")
	if e.tele_t > 0.0:
		e.tele_t -= dt
		e.kx = 0.0
		e.kz = 0.0
		if e.tele_t <= 0.0:
			peck(e)
	elif e.hurt > 0.0 or e.stun > 0.0:
		v = Vector2(e.kx, e.kz)
	elif e.seam > 0.0:
		pass # the beak is stuck in the brick
	elif d < 7.0 and not m.intro:
		if e.atk_cd <= 0.0 and d <= 2.7:
			e.tele_t = 0.6
			e.atk_cd = 2.4
			e.face = dirn
			e.tele = m.monsters.warn_path(from, dirn, 2.5, 0.3, 0.6)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.7, e.z), "!", Color("#ff5a4a"))
		elif d > 2.0:
			v = dirn * 1.5
	elif d >= 7.0:
		v = wander(e)
	var lifted: bool = e.tele_t > 0.0
	if lifted:
		face_to(e, e.face, dt, true)
	elif v.length() > 0.1:
		face_to(e, v, dt)
	finish(e, v, dt, absf(sin(e.t * 7.0)) * 0.08 if v.length() > 0.1 else 0.0)
	beak.rotation.x = -0.75 if lifted else (0.5 if e.seam > 0.0 else 0.0)
	e.node.get_meta("seam").visible = e.seam > 0.0
	flash(e, lifted)

func peck(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	var dir: Vector2 = e.face
	var dmg := foe_dmg(0.9)
	m.monsters.tele_clear(e)
	var tip := from + dir * 2.3
	m.burst(Vector3(tip.x, m.height_at(tip.x, tip.y) + 0.2, tip.y), Color("#c9a066"), 10, 2.5)
	m.sfx(220, 0.08, "square", 0.2, -120)
	if in_lane(from, dir, 2.5, 0.3, Vector2(m.player.x, m.player.z)):
		m.player_hit(dmg, from, e)
	for t in [0.6, 1.2, 1.8, 2.4]:
		mate_hit(from + dir * t, 0.5, dmg)
	seam_for(e, 0.9) # the neck seam shows once the beak is out

# ---------------------------------------------------------------- 벽돌 등나방 (lantern village, night)
# hp 0.6x, speed 1.4, blow 0.8x. Within 2.8 tiles: the belly swells 0.7 s over a 1.8 tile ring on its own spot, then one
# burst of light there. It rests 0.8 s after, dim; 2.8 s from one swell to the next.
func make_moth() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	var body := Color("#5a4a7a")
	m.brick(g, mats, Vector3(0.22, 0.2, 0.42), Vector3(0, 0.5, 0), body)
	m.brick(g, mats, Vector3(0.18, 0.16, 0.16), Vector3(0, 0.54, 0.28), Color("#3a2e52"), false)
	m.brick(g, mats, Vector3(0.04, 0.2, 0.04), Vector3(-0.06, 0.74, 0.3), Color("#e8dcc0"), false)
	m.brick(g, mats, Vector3(0.04, 0.2, 0.04), Vector3(0.06, 0.74, 0.3), Color("#e8dcc0"), false)
	var wl := Node3D.new() # wings hinge at the body
	wl.position = Vector3(-0.11, 0.56, 0.0)
	g.add_child(wl)
	m.brick(wl, mats, Vector3(0.5, 0.04, 0.36), Vector3(-0.25, 0, 0), Color("#8a6ac8"), false)
	var wr := Node3D.new()
	wr.position = Vector3(0.11, 0.56, 0.0)
	g.add_child(wr)
	m.brick(wr, mats, Vector3(0.5, 0.04, 0.36), Vector3(0.25, 0, 0), Color("#8a6ac8"), false)
	var belly_mat := StandardMaterial3D.new()
	belly_mat.albedo_color = Color("#ffe48a")
	belly_mat.emission_enabled = true
	belly_mat.emission = Color("#ffd84a")
	belly_mat.emission_energy_multiplier = 1.2
	var c := CylinderMesh.new()
	c.top_radius = 0.12
	c.bottom_radius = 0.1
	c.height = 0.3
	c.radial_segments = 12
	var belly := MeshInstance3D.new()
	belly.mesh = c
	belly.material_override = belly_mat
	belly.rotation.x = PI / 2.0
	belly.position = Vector3(0, 0.46, -0.3)
	g.add_child(belly)
	root.scale = Vector3.ONE * 1.3
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	root.set_meta("wings", [wl, wr])
	root.set_meta("belly", belly)
	root.set_meta("belly_mat", belly_mat)
	return root

func spawn_moth(at: Vector2) -> Dictionary:
	return base_entry(make_moth(), at, foe_hp(0.6), 0.6, {"moth": true, "rest": 0.0})

# the lantern village keeps its moths up only on a night Sora is in it: spots with no living moth get one, the rest are freed by day
# the village is safe by night too (the owner, 2026-10-29: "마을에 몹이 왜 나타나지?" -> "마을에서 없애라"): the moths stay
# away; this still clears any left over from an older build. The moth itself lives on in spawn_demo.
const VILLAGE_MOTHS := false

func village_moths() -> void:
	var want: bool = VILLAGE_MOTHS and m.in_village and m.in_house < 0 and m.is_night() and not m.intro
	if want and not moths_out:
		moths_out = true
		for p in MOTH_SPOTS:
			spawn_moth(Vector2(Main.VILLAGE.VILLAGE_X + p.x, p.y))
	elif not want and moths_out:
		moths_out = false
		for e in m.enemies.duplicate():
			if e.get("moth", false):
				if is_instance_valid(e.node): e.node.queue_free()
				if is_instance_valid(e.shadow): e.shadow.queue_free()
				m.enemies.erase(e)

func update_moth(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	tick(e, dt)
	e.rest = e.get("rest", 0.0) - dt
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	var swell := 0.0
	if e.tele_t > 0.0:
		e.tele_t -= dt
		e.kx = 0.0
		e.kz = 0.0
		swell = 1.0 - e.tele_t / 0.7
		if e.tele_t <= 0.0:
			light_burst(e)
	elif e.hurt > 0.0 or e.stun > 0.0:
		v = Vector2(e.kx, e.kz)
	elif e.rest > 0.0:
		pass # dim, spent
	elif d < 6.0 and not m.intro:
		if e.atk_cd <= 0.0 and d <= 2.8:
			e.tele_t = 0.7
			e.atk_cd = 2.8
			m.monsters.warn_ring(Vector3(e.x, m.height_at(e.x, e.z), e.z), 1.8, 0.7)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.5, e.z), "!", Color("#ff5a4a"))
		elif d > 1.6:
			v = dirn * 1.4
	elif d >= 6.0:
		v = wander(e)
	if v.length() > 0.1:
		face_to(e, v, dt)
	finish(e, v, dt, 0.45 + sin(e.t * 3.0) * 0.12)
	var node: Node3D = e.node
	var flap := sin(e.t * (22.0 if e.tele_t > 0.0 else 12.0)) * 0.5
	var wings: Array = node.get_meta("wings")
	wings[0].rotation.z = flap
	wings[1].rotation.z = -flap
	var belly: MeshInstance3D = node.get_meta("belly")
	var bm: StandardMaterial3D = node.get_meta("belly_mat")
	var s := 1.0 + swell * 1.2
	belly.scale = Vector3(s, 1.0, s)
	bm.emission_energy_multiplier = 1.2 + swell * 4.0 if e.rest <= 0.0 else 0.3
	flash(e, false)

func light_burst(e: Dictionary) -> void:
	var at := Vector3(e.x, m.height_at(e.x, e.z), e.z)
	var dmg := foe_dmg(0.8)
	var mm := MeshInstance3D.new()
	mm.mesh = m.ring_mesh(0.0, 1.8, 0.0, TAU)
	var mat: StandardMaterial3D = m.glow_mat(Color("#fff2b0"), 2.5)
	mm.material_override = mat
	mm.position = at + Vector3(0, 0.2, 0)
	m.add_fx(mm, 0.3, func(_n: Node3D, k: float, _dt: float): mat.albedo_color.a = 0.9 * (1.0 - k))
	m.burst(at + Vector3(0, 0.6, 0), Color("#fff2b0"), 26, 3.5)
	m.sfx(900, 0.18, "triangle", 0.2, -500)
	if Vector2(e.x - m.player.x, e.z - m.player.z).length() < 1.8:
		m.player_hit(dmg, Vector2(e.x, e.z), e)
	mate_hit(Vector2(e.x, e.z), 1.8, dmg)
	e.rest = 0.8

# ---------------------------------------------------------------- 벽돌 씨앗통 (Hangyeol's road)
# hp 1.0x, speed 1.0, seed 0.8x at 4.0 tiles/s. From 1.5 to 6 tiles: the lid opens 0.8 s over three red lines (aim at Sora,
# +-25 degrees, locked), then a seed brick goes along each. Keeps 3.5 to 5 tiles off. 3 s from one lid to the next.
func make_hopper() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	m.brick(g, mats, Vector3(0.5, 0.42, 0.5), Vector3(0, 0.36, 0), Color("#7a5a3a"))
	m.brick(g, mats, Vector3(0.54, 0.06, 0.04), Vector3(0, 0.3, 0.27), Color("#c8a07a"), false)
	m.brick(g, mats, Vector3(0.07, 0.07, 0.03), Vector3(-0.1, 0.4, 0.26), Color("#ffc23a"), false, true)
	m.brick(g, mats, Vector3(0.07, 0.07, 0.03), Vector3(0.1, 0.4, 0.26), Color("#ffc23a"), false, true)
	cyl(g, mats, 0.14, 0.08, Vector3(-0.3, 0.14, 0.0), Color("#2e2a30"), Vector3(0, 0, PI / 2.0))
	cyl(g, mats, 0.14, 0.08, Vector3(0.3, 0.14, 0.0), Color("#2e2a30"), Vector3(0, 0, PI / 2.0))
	var lid := Node3D.new() # hinged at the back top edge
	lid.position = Vector3(0, 0.58, -0.25)
	g.add_child(lid)
	m.brick(lid, mats, Vector3(0.54, 0.06, 0.54), Vector3(0, 0, 0.27), Color("#b4231e"))
	var seeds := glow_box(g, Vector3(0.36, 0.04, 0.36), Vector3(0, 0.56, 0.0), Color("#ffc23a"), 2.0) # seeds in the open bin
	seeds.visible = false
	root.scale = Vector3.ONE * 1.3
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	root.set_meta("lid", lid)
	root.set_meta("seeds", seeds)
	return root

func spawn_hopper(at: Vector2) -> Dictionary:
	return base_entry(make_hopper(), at, foe_hp(1.0), 0.7, {"hopper": true, "aim": Vector2(0, 1)})

func update_hopper(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	tick(e, dt)
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	if e.tele_t > 0.0:
		e.tele_t -= dt
		e.kx = 0.0
		e.kz = 0.0
		if e.tele_t <= 0.0:
			fire_seeds(e)
	elif e.hurt > 0.0 or e.stun > 0.0:
		v = Vector2(e.kx, e.kz)
	elif d < 7.0 and not m.intro:
		if e.atk_cd <= 0.0 and d >= 1.5 and d <= 6.0:
			e.tele_t = 0.8
			e.atk_cd = 3.0
			e.aim = dirn
			for a in [-25.0, 0.0, 25.0]:
				var dir := dirn.rotated(deg_to_rad(a))
				m.monsters.warn_path(from, dir, 6.0, 0.2, 0.8)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 1.5, e.z), "!", Color("#ff5a4a"))
		elif d < 3.5:
			v = -dirn * 1.0
		elif d > 5.0:
			v = dirn * 1.0
	elif d >= 7.0:
		v = wander(e)
	var open: bool = e.tele_t > 0.0
	if open:
		face_to(e, e.aim, dt, true)
	elif d < 7.0:
		face_to(e, dirn, dt)
	var hop := absf(sin(e.t * 5.0)) * 0.1 if v.length() > 0.1 else 0.0
	finish(e, v, dt, hop)
	var lid: Node3D = e.node.get_meta("lid")
	lid.rotation.x = lerpf(lid.rotation.x, -1.3 if open else 0.0, minf(1.0, dt * 14.0))
	e.node.get_meta("seeds").visible = open
	flash(e, open)

func fire_seeds(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	var dmg := foe_dmg(0.8)
	for a in [-25.0, 0.0, 25.0]:
		m.monsters.throw_brick(from, e.aim.rotated(deg_to_rad(a)), e, 4.0, 1.6, dmg)

# ---------------------------------------------------------------- 벽돌 추시계병 (castle, stairs)
# hp 1.2x, speed 1.3, blow 1.2x. Within 2.6 tiles: the pendulum goes up to one side 0.8 s over a front half circle (reach 2,
# locked), then sweeps once. Its back seam opens 1 s after the sweep and stays open 1 s: roll behind and cut. 2.8 s per cycle.
func make_pendulum() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	var body := Color("#5a6470")
	m.brick(g, mats, Vector3(0.16, 0.14, 0.2), Vector3(-0.12, 0.07, 0), Color("#2e2a30"), false)
	m.brick(g, mats, Vector3(0.16, 0.14, 0.2), Vector3(0.12, 0.07, 0), Color("#2e2a30"), false)
	m.brick(g, mats, Vector3(0.44, 0.5, 0.3), Vector3(0, 0.39, 0), body)
	m.brick(g, mats, Vector3(0.3, 0.28, 0.28), Vector3(0, 0.78, 0), Color("#bfe6ff"), false)
	m.brick(g, mats, Vector3(0.2, 0.2, 0.04), Vector3(0, 0.78, 0.15), Color("#e8dcc0"), false) # the clock face
	m.brick(g, mats, Vector3(0.06, 0.06, 0.03), Vector3(0, 0.78, 0.17), Color("#ffc23a"), false, true)
	cyl(g, mats, 0.06, 0.62, Vector3(0, 0.62, 0.0), Color("#c8962a"), Vector3(0, 0, PI / 2.0)) # the axle
	var swing := Node3D.new() # turns about the vertical axis: the side angle
	swing.position = Vector3(0, 0.62, 0)
	g.add_child(swing)
	var arm := Node3D.new() # tilts the arm from hanging down (PI/2) to level (0)
	arm.rotation.x = PI / 2.0
	swing.add_child(arm)
	m.brick(arm, mats, Vector3(0.07, 0.07, 1.1), Vector3(0, 0, 0.55), Color("#c8962a"), false)
	m.brick(arm, mats, Vector3(0.3, 0.3, 0.3), Vector3(0, 0, 1.12), Color("#b4231e"))
	var seam := glow_box(g, Vector3(0.3, 0.08, 0.05), Vector3(0, 0.46, -0.17), Color("#ffd84a"))
	seam.visible = false
	root.scale = Vector3.ONE * 1.5
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	root.set_meta("swing", swing)
	root.set_meta("arm", arm)
	root.set_meta("seam", seam)
	return root

func spawn_pendulum(at: Vector2) -> Dictionary:
	return base_entry(make_pendulum(), at, foe_hp(1.2), 0.9, {"pendulum": true, "side": 1.0, "sweep_t": 0.0, "seam_in": 0.0})

func update_pendulum(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	tick(e, dt)
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	e.sweep_t = e.get("sweep_t", 0.0) - dt
	var hold: bool = e.tele_t > 0.0 or e.sweep_t > 0.0 or e.seam_in > 0.0 or e.seam > 0.0
	if e.tele_t > 0.0:
		e.tele_t -= dt
		e.kx = 0.0
		e.kz = 0.0
		if e.tele_t <= 0.0:
			sweep(e)
	elif e.seam_in > 0.0:
		e.seam_in -= dt
		if e.seam_in <= 0.0:
			seam_for(e, 1.0) # the back seam
	elif e.hurt > 0.0 or e.stun > 0.0:
		v = Vector2(e.kx, e.kz)
	elif hold:
		pass
	elif d < 7.0 and not m.intro:
		if e.atk_cd <= 0.0 and d <= 2.6:
			e.tele_t = 0.8
			e.atk_cd = 2.8
			e.face = dirn
			e.side = 1.0 if m.rng.randf() < 0.5 else -1.0
			e.tele = m.monsters.warn_fan(from, dirn, 2.0, PI, 0.8)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 2.0, e.z), "!", Color("#ff5a4a"))
		elif d > 2.0:
			v = dirn * 1.3
	elif d >= 7.0:
		v = wander(e)
	var raised: bool = e.tele_t > 0.0
	if raised or e.sweep_t > 0.0 or e.seam_in > 0.0 or e.seam > 0.0:
		face_to(e, e.face, dt, true)
	elif v.length() > 0.1:
		face_to(e, v, dt)
	finish(e, v, dt, 0.0)
	var swing: Node3D = e.node.get_meta("swing")
	var arm: Node3D = e.node.get_meta("arm")
	if raised:
		swing.rotation.y = lerpf(swing.rotation.y, e.side * PI / 2.0, minf(1.0, dt * 14.0))
		arm.rotation.x = lerpf(arm.rotation.x, 0.0, minf(1.0, dt * 14.0))
	elif e.sweep_t > 0.0:
		var k: float = 1.0 - e.sweep_t / 0.25
		swing.rotation.y = lerpf(e.side * PI / 2.0, -e.side * PI / 2.0, clampf(k, 0.0, 1.0))
		arm.rotation.x = 0.0
	else:
		swing.rotation.y = lerpf(swing.rotation.y, 0.0, minf(1.0, dt * 10.0))
		arm.rotation.x = lerpf(arm.rotation.x, PI / 2.0, minf(1.0, dt * 10.0))
	e.node.get_meta("seam").visible = e.seam > 0.0
	flash(e, raised)

func sweep(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	var dir: Vector2 = e.face
	var dmg := foe_dmg(1.2)
	m.monsters.tele_clear(e)
	e.sweep_t = 0.25
	e.seam_in = 1.0
	m.burst(Vector3(e.x + dir.x * 1.5, m.height_at(e.x, e.z) + 0.5, e.z + dir.y * 1.5), Color("#ffd28a"), 12, 3.0)
	m.sfx(160, 0.14, "sawtooth", 0.2, -80)
	var me := Vector2(m.player.x, m.player.z)
	if from.distance_to(me) < 2.0 and absf(dir.angle_to(me - from)) <= PI / 2.0:
		m.player_hit(dmg, from, e)
	for t in [0.8, 1.6]:
		for a in [-1.0, 0.0, 1.0]:
			mate_hit(from + dir.rotated(a * 0.9) * t, 0.5, dmg)

# ---------------------------------------------------------------- 벽돌 물받이 (water corridor, v0.1.84)
# The owner chose the corridor (2026-10-29, "1안: 물길·관측원"). hp 40 + 13 per foe level, blow 8 + 2 per level (shots/plans/option1_design.md).
# Within 4 tiles: a lane 1 wide and 4 long shows 0.9 s (locked), one spray 0.4 s, then the bucket head bows 1.8 s with its seams
# open (the opening to cut). At most two buckets show a lane at once; no knockback; a bucket only ever aims at Sora.
func make_bucket() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	m.brick(g, mats, Vector3(0.16, 0.2, 0.2), Vector3(-0.22, 0.1, 0), Color("#2e2a30"), false)
	m.brick(g, mats, Vector3(0.16, 0.2, 0.2), Vector3(0.22, 0.1, 0), Color("#2e2a30"), false)
	m.brick(g, mats, Vector3(0.9, 0.7, 0.7), Vector3(0, 0.55, 0), Color("#5c6a7c"))
	var head := Node3D.new()
	head.position = Vector3(0, 1.0, 0.0)
	g.add_child(head)
	m.brick(head, mats, Vector3(0.62, 0.4, 0.62), Vector3(0, 0.2, 0), Color("#3fb0b0"))
	m.brick(head, mats, Vector3(0.5, 0.08, 0.5), Vector3(0, 0.44, 0), Color("#2a7a80"), false)
	m.brick(head, mats, Vector3(0.22, 0.14, 0.3), Vector3(0, 0.12, 0.38), Color("#c8d4dc"), false) # the spout
	for sx in [-0.3, 0.3]: # the two white seams
		m.brick(g, mats, Vector3(0.06, 0.5, 0.04), Vector3(sx, 0.55, 0.36), Color("#f4f4ee"), false)
	root.scale = Vector3.ONE * 1.1
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	root.set_meta("head", head)
	return root

func spawn_bucket(at: Vector2) -> Dictionary:
	var e := base_entry(make_bucket(), at, 40 + m.foe_lv() * 13, 0.9, {"bucket": true, "spray_t": 0.0, "bow": 0.0})
	e.atk_cd = 0.8
	return e

func bucket_lanes() -> int:
	var n := 0
	for o in m.enemies:
		if not o.dead and o.get("bucket", false) and o.tele_t > 0.0:
			n += 1
	return n

func update_bucket(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	tick(e, dt)
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	var head: Node3D = e.node.get_meta("head")
	e.spray_t = e.get("spray_t", 0.0) - dt
	e.bow = e.get("bow", 0.0) - dt
	if e.tele_t > 0.0:
		e.tele_t -= dt
		e.kx = 0.0
		e.kz = 0.0
		if e.tele_t <= 0.0:
			spray(e)
	elif e.spray_t > 0.0:
		pass # the jet runs
	elif e.bow > 0.0 or e.seam > 0.0:
		pass # head down, seams open
	elif e.hurt > 0.0 or e.stun > 0.0:
		v = Vector2(e.kx, e.kz)
	elif d < 7.0 and not m.intro:
		if e.atk_cd <= 0.0 and d <= 4.0 and bucket_lanes() < 2:
			e.tele_t = 0.9
			e.atk_cd = 2.8
			e.face = dirn
			e.tele = m.monsters.warn_path(from, dirn, 4.0, 1.0, 0.9)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 2.0, e.z), "!", Color("#ff5a4a"))
		elif d > 3.0:
			v = dirn * 1.2
	elif d >= 7.0:
		v = wander(e)
	if e.tele_t > 0.0 or e.spray_t > 0.0:
		face_to(e, e.face, dt, true)
	elif v.length() > 0.1:
		face_to(e, v, dt)
	finish(e, v, dt, 0.0)
	var bowed: bool = e.bow > 0.0 or e.seam > 0.0
	head.rotation.x = lerpf(head.rotation.x, 0.9 if bowed else (-0.35 if e.tele_t > 0.0 else 0.0), minf(1.0, dt * 12.0))
	flash(e, e.tele_t > 0.0)

func spray(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	var dir: Vector2 = e.face
	var dmg: int = 8 + m.foe_lv() * 2
	m.monsters.tele_clear(e)
	e.spray_t = 0.4
	e.bow = 1.8
	seam_for(e, 1.8)
	for k in 4:
		m.burst(Vector3(e.x + dir.x * (0.8 + k), 0.5, e.z + dir.y * (0.8 + k)), Color("#9fd8ff"), 8, 2.4)
	m.sfx(300, 0.2, "noise", 0.12, -60)
	if in_lane(from, dir, 4.0, 0.5, Vector2(m.player.x, m.player.z)):
		m.player_hit(dmg, from, e)

# ---------------------------------------------------------------- 벽돌 눈금새 (moon-watch observatory, v0.1.120)
# hp 30 + 14 per foe level, blow 9 + 2 per level (shots/plans/option1_design.md). Within 6 tiles: a lane 1 wide and 6 long shows 1.1 s
# (locked), one brick leaves along it at 5 tiles a second, then the wings fold 2 s with the seams open (the opening to cut).
# It never follows her across the gap (its walk and its brick stop at the edge) and takes no knockback.
func make_scalebird() -> Node3D:
	var root := Node3D.new()
	var g := Node3D.new()
	root.add_child(g)
	var mats: Array = []
	m.brick(g, mats, Vector3(0.1, 0.3, 0.1), Vector3(-0.12, 0.15, 0), Color("#6a6a74"), false) # legs
	m.brick(g, mats, Vector3(0.1, 0.3, 0.1), Vector3(0.12, 0.15, 0), Color("#6a6a74"), false)
	m.brick(g, mats, Vector3(0.5, 0.9, 0.5), Vector3(0, 0.75, 0), Color("#6a5e8a")) # the box body
	m.brick(g, mats, Vector3(0.26, 0.26, 0.26), Vector3(0, 1.36, 0.18), Color("#8a8a96")) # the square grey beak
	m.brick(g, mats, Vector3(0.05, 0.06, 0.03), Vector3(-0.1, 1.16, 0.26), Color("#ffc23a"), false, true)
	m.brick(g, mats, Vector3(0.05, 0.06, 0.03), Vector3(0.1, 1.16, 0.26), Color("#ffc23a"), false, true)
	var wings: Array = []
	for side in [-1.0, 1.0]: # two yellow wings ruled like a scale
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.27, 0.95, 0)
		g.add_child(wing)
		m.brick(wing, mats, Vector3(0.1, 0.7, 0.44), Vector3(side * 0.05, -0.1, 0), Color("#e8c83a"), false)
		for k in 3:
			m.brick(wing, mats, Vector3(0.12, 0.05, 0.3), Vector3(side * 0.07, 0.08 - k * 0.2, 0), Color("#6a5a20"), false)
		wings.append(wing)
	var seam := glow_box(g, Vector3(0.3, 0.05, 0.3), Vector3(0, 1.22, 0), Color("#ffd84a"))
	seam.visible = false
	root.scale = Vector3.ONE * 1.1
	root.set_meta("mats", mats)
	root.set_meta("body", g)
	root.set_meta("wings", wings)
	root.set_meta("seam", seam)
	return root

func spawn_scalebird(at: Vector2) -> Dictionary:
	var e := base_entry(make_scalebird(), at, 30 + m.foe_lv() * 14, 0.6, {"scalebird": true, "fold": 0.0})
	e.atk_cd = 1.0
	return e

func update_scalebird(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	tick(e, dt)
	var from := Vector2(e.x, e.z)
	var dirn := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	e.kx = 0.0 # no knockback
	e.kz = 0.0
	e.fold = e.get("fold", 0.0) - dt
	if e.tele_t > 0.0:
		e.tele_t -= dt
		if e.tele_t <= 0.0:
			shoot_scale(e)
	elif e.fold > 0.0 or e.seam > 0.0:
		pass # wings folded, the seams open
	elif e.hurt > 0.0 or e.stun > 0.0:
		pass
	elif d < 8.0 and not m.intro:
		if e.atk_cd <= 0.0 and d <= 6.0:
			e.tele_t = 1.1
			e.atk_cd = 4.2
			e.face = dirn
			e.tele = m.monsters.warn_path(from, dirn, 6.0, 1.0, 1.1)
			m.pop_num(Vector3(e.x, m.height_at(e.x, e.z) + 2.0, e.z), "!", Color("#ff5a4a"))
		elif d > 4.5:
			v = dirn * 1.3
		elif d < 2.5:
			v = -dirn * 1.0
	else:
		v = wander(e)
	if e.tele_t > 0.0:
		face_to(e, e.face, dt, true)
	elif v.length() > 0.1:
		face_to(e, v, dt)
	finish(e, v, dt, 0.0)
	var folded: bool = e.fold > 0.0 or e.seam > 0.0
	var wings: Array = e.node.get_meta("wings")
	for k in wings.size():
		var spread: float = 0.15 if folded else (0.9 if e.tele_t > 0.0 else 0.4)
		wings[k].rotation.z = lerpf(wings[k].rotation.z, (-1.0 if k == 0 else 1.0) * spread, minf(1.0, dt * 12.0))
	e.node.get_meta("seam").visible = e.seam > 0.0
	flash(e, e.tele_t > 0.0)

func shoot_scale(e: Dictionary) -> void:
	var from := Vector2(e.x, e.z)
	m.monsters.tele_clear(e)
	m.monsters.throw_brick(from, e.face, e, 5.0, 6.0 / 5.0 + 0.2, foe_dmg(1.0))
	e.fold = 2.0
	seam_for(e, 2.0)

# ---------------------------------------------------------------- where they live
# spots to hang on a field list: [world Vector2, letter] ("p" pendulum, "h" hopper)
func spots(area: String) -> Array:
	var out: Array = []
	match area:
		"castle":
			for p in CASTLE_SPOTS:
				out.append([Vector2(Main.CASTLE.CASTLE_X + p.x, p.y), "p"])
		"stairs":
			for p in STAIRS_SPOTS:
				out.append([Vector2(Main.STAIRS.STAIRS_X + p.x, p.y), "p"])
		"garden":
			for p in HOPPER_SPOTS:
				out.append([Vector2(Main.GARDEN.GARDEN_X + p.x, p.y), "h"])
	return out

# a scene or test foe: one of the four, 2.4 tiles east of Sora, ready to start its telegraph
func spawn_demo(kind: String, at: Vector2) -> Dictionary:
	var e: Dictionary
	match kind:
		"bird": e = spawn_bird(at)
		"moth": e = spawn_moth(at)
		"hopper": e = spawn_hopper(at)
		_: e = spawn_pendulum(at)
	e.atk_cd = 0.0
	return e
