# Villagers: house rooms, sleeping at night, day routines and paths, cupboards.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const HOUSE_ROWS := ["#########", "#.......#", "#.......#", "#.......#", "#.......#", "#.......#", "####S####"]
# what each house keeps in its cupboard, in build order: Sora only looks (taking from a neighbour's cupboard would be
# stealing; the owner, 2026-10-25), and the last house keeps the old moonkeeper picture
const HOUSE_CUPBOARD := ["찬장에 이 집 사람의 찻잔과 그릇이 가지런히 놓여 있다. 소라는 문을 도로 닫았다.",
	"찬장에 말린 약초 다발이 걸려 있다. 남의 살림이니 소라는 손대지 않았다.",
	"찬장에 아이가 그린 등불 그림이 꽂혀 있다. 소라는 웃으며 문을 닫았다.",
	"찬장에 꿀단지와 빵 바구니가 있다. 소라는 문을 살며시 닫았다.", ""]
const HOUSE_WALLS := [Color("#e4dccc"), Color("#d8c8a8"), Color("#c8d8c8"), Color("#e0c8c0"), Color("#c8c8dc")]
const SLEEP_ART := {"doran": [0, 0], "kongal": [0, 1], "mulgyeol": [0, 2], "kid": [0, 3], # [sheet, cell]
	"dusol": [1, 0], "chadol": [1, 1], "saecham": [1, 2], "yeoul": [1, 3], "darae": [1, 4], "tori": [1, 5]}
const FOLK_WALK := 1.8      # tiles a second on the way home
const FOLK_NAME := {"doran": "도란", "kongal": "콩알", "mulgyeol": "물결", "dusol": "두솔", "chadol": "차돌", "saecham": "새참", "yeoul": "여울", "darae": "다래", "tori": "토리"}
const ROUTE_WALK := 1.4     # tiles a second by day

func _init(main: Main) -> void:
	m = main

# ---- hopping walkers (the user, 2026-10-25: "통통통 튀어서 걷도록"): every NPC that moves without a walk sheet hops
# in small arcs, one hop per HOP_STEP tiles walked, with a squash on landing and a stretch at the top; when it stops it
# finishes the hop in the air and settles. The sprite hops, never the node, so balloons (anchored to the node or to the
# ground spot) stay put. `key` names the walker, `base_y` is the sprite's resting height, `alt` alternates frames 0 and 1.
const HOP_H := 0.12 # a hop's height in world units (Mulgyeol's old 0.06 doubled)
const HOP_STEP := 0.9 # tiles walked per hop (the user, 2026-10-25: 0.45 → 0.9, "npc들 뛰는 인터벌 지금의 2배로")
const MATE_HOP_STEP := 1.8 # the companions run at Sora's pace, so they hop half as often as villagers (the user, 2026-10-25: "너무 폴짝거리네", "인터벌 4배로")
const HOP_SQUASH_T := 0.06
var hops := {} # key -> {last, p, base, scale, squash, n}
var nod_t := {} # key -> seconds left of a nod (delight idea 29)
var folk_nods := 0 # nods given (autoplay folk_nod)
const NOD_T := 0.45

func hop(key: String, spr: Sprite3D, dt: float, base_y := 0.0, height := HOP_H, alt := false, step := HOP_STEP) -> void:
	var g := Vector2(spr.global_position.x, spr.global_position.z)
	if not hops.has(key) or not is_instance_valid(hops[key].get("spr")) or hops[key].spr != spr:
		hops[key] = {"last": g, "p": 0.0, "scale": spr.scale, "squash": 0.0, "n": 0, "spr": spr}
	var s: Dictionary = hops[key]
	var d: float = g.distance_to(s.last)
	s.last = g
	if d > 1.5: # moved by a snap or a door: not a step
		d = 0.0
	var p: float = s.p
	if d > 0.002:
		p += d / step
	elif p > 0.0:
		p += dt * 6.0 # settles at about a walking pace
	if p >= 1.0:
		p = fmod(p, 1.0) if d > 0.002 else 0.0
		s.squash = HOP_SQUASH_T
		s.n += 1
		if alt and spr.hframes > 1:
			spr.frame = s.n % 2
	s.p = p
	var arc := sin(PI * p)
	spr.position.y = base_y + arc * height
	var sq: float = s.squash
	var bs: Vector3 = s.scale
	if sq > 0.0:
		s.squash = sq - dt
		spr.scale = Vector3(bs.x * 1.08, bs.y * 0.9, bs.z)
	else:
		spr.scale = Vector3(bs.x * (1.0 - 0.03 * arc), bs.y * (1.0 + 0.05 * arc), bs.z)
	var nt: float = nod_t.get(key, 0.0)
	if nt > 0.0: # a small dip of the head: lower and a little squashed, once
		nod_t[key] = nt - dt
		var dip := sin(PI * (1.0 - nt / NOD_T))
		spr.position.y -= dip * 0.08
		spr.scale.y *= 1.0 - dip * 0.07

func house_char(x: float, z: float) -> String:
	var tx := int(round(x)) - Main.HOUSE_X
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tz >= HOUSE_ROWS.size() or tx >= HOUSE_ROWS[0].length():
		return "#"
	return HOUSE_ROWS[tz][tx]

func build_house_room() -> void:
	var floor_mat: Material = m.mat_color(Color("#a07a52"))
	m.house_wall_mat = m.mat_color(HOUSE_WALLS[0])
	for z in HOUSE_ROWS.size():
		for x in HOUSE_ROWS[0].length():
			var c: String = HOUSE_ROWS[z][x]
			var b: MeshInstance3D
			if c == "#":
				b = m.box(Vector3(1, 1.2 if z == 0 else 0.3, 1), m.house_wall_mat) # the back wall stands, the rest stay low
				b.position = Vector3(Main.HOUSE_X + x, (0.6 if z == 0 else 0.15) - 0.0, z)
			else:
				b = m.box(Vector3(1, 0.4, 1), floor_mat)
				b.position = Vector3(Main.HOUSE_X + x, -0.2, z)
			m.add_child(b)
	var wood: Material = m.mat_color(Color("#6a4a2e"))
	var sb := preload("res://sys/sleep_bed.gd").new(m)
	var room_bed := Node3D.new() # the house's own bed on the first spot (empty by day; a sleeper there adds only himself)
	room_bed.position = Vector3(Main.HOUSE_X + Main.HOUSE_SPOTS[0].x, 0, Main.HOUSE_SPOTS[0].y)
	room_bed.rotation.y = Main.CAM_YAW
	sb.frame(room_bed)
	m.add_child(room_bed)
	for part in [[Vector3(1.2, 0.6, 0.8), Vector3(Main.HOUSE_X + 5.0, 0.3, 3.5), wood], [Vector3(0.9, 0.06, 0.9), Vector3(Main.HOUSE_X + 5.0, 0.62, 3.5), m.mat_color(Color("#e8dcc0"))]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		m.add_child(b)
	m.rocks.append({"x": Main.HOUSE_X + 1.8, "z": 1.6, "r": 0.8})
	m.rocks.append({"x": Main.HOUSE_X + 5.0, "z": 3.5, "r": 0.6})
	m.cupboard = Node3D.new()
	var cb := m.box(Vector3(1.0, 1.4, 0.5), wood)
	cb.position = Vector3(0, 0.7, 0)
	m.cupboard.add_child(cb)
	var knob := m.box(Vector3(0.1, 0.1, 0.06), m.mat_color(Color("#e8b018")))
	knob.position = Vector3(0.2, 0.8, 0.27)
	m.cupboard.add_child(knob)
	m.cupboard.position = Vector3(Main.HOUSE_X + 6.5, 0, 1.3)
	m.add_child(m.cupboard)
	m.rocks.append({"x": Main.HOUSE_X + 6.5, "z": 1.3, "r": 0.5})
	build_door_bell()
	var hearth := OmniLight3D.new()
	hearth.light_color = Color("#ffc890")
	hearth.light_energy = 2.0
	hearth.omni_range = 8.0
	hearth.position = Vector3(Main.HOUSE_X + 4.0, 2.5, 3.0)
	m.add_child(hearth)
	# the sleepers: one per villager, shown in his house at night, in the bed the owner picked (draft 5 of
	# 2026-10-25, sys/sleep_bed.gd): head picture cut from the GPT pixel art (art/folk/sleepers.png for the first four,
	# sleepers2.png for the six working villagers), patchwork quilt from the same picture, headboard and a lit lamp.
	# The first spot is the room's own bed; the other two get a bed of their own ("frame") while someone sleeps there.
	var phase := 0.0
	for id in SLEEP_ART:
		var bed := Node3D.new()
		var fr := Node3D.new()
		fr.name = "frame"
		sb.frame(fr)
		bed.add_child(fr)
		sb.sleeper(bed, SLEEP_ART[id], phase)
		if id == "kid":
			kid_shoes = build_kid_shoes(bed)
		phase += 0.7
		bed.visible = false
		m.add_child(bed)
		m.sleeper_nodes[id] = bed
	for k in range(1, Main.HOUSE_SPOTS.size()): # a bedroll blocks the way only while someone sleeps on it
		m.rocks.append({"x": Main.HOUSE_X + Main.HOUSE_SPOTS[k].x, "z": Main.HOUSE_SPOTS[k].y, "r": 0.0, "spot": k})

# the kid goblin's little toy-brick shoes, taken off and left at the side of her bed with the toes towards it (delight idea 30).
# They are children of her bed, so they show only while she sleeps there (after Kongal's errand, kid_q 3), and they stand
# beside the frame, off the lane the bedroll blocks.
var kid_shoes: Node3D

func build_kid_shoes(bed: Node3D) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(-0.62, 0, 0.3)
	bed.add_child(g)
	for k in 2:
		var shoe: MeshInstance3D = m.box(Vector3(0.2, 0.09, 0.1), m.mat_color(Color("#c8523a") if k == 0 else Color("#e0b040")))
		shoe.position = Vector3(0, 0.045, k * 0.2)
		shoe.rotation.y = 0.12 * (1.0 if k == 0 else -1.0)
		g.add_child(shoe)
		var stud: MeshInstance3D = m.box(Vector3(0.05, 0.03, 0.05), m.mat_color(Color("#c8523a") if k == 0 else Color("#e0b040")))
		stud.position = Vector3(0.05, 0.06, 0)
		shoe.add_child(stud)
	return g

func folk_should_sleep() -> bool:
	return m.is_night() and not (m.mail_got[1] and m.moon_phase().x >= 0.95) and not m.sleep_off

# E where a sleeper stands by day: say where he is (the firefly and moonflower errands come at night)
func asleep_hint(me: Vector2) -> bool:
	for id in Main.SLEEP_IDS:
		if m.folk_state.get(id, "out") == "in" and folk_awake_here(id) and m.in_house < 0 and me.distance_to(m.village.folk_pos[id]) < 1.6:
			m.toast(tr("%s은(는) 집에 들어가 자고 있다. 집에 들어가 깨워 보자") % tr(FOLK_NAME[id]))
			return true
	return false

func folk_home(id: String) -> int: # the house nearest to where he stands by day that has a spot left
	return folk_bed(id)[0]

func folk_bed(id: String) -> Array:
	if m.folk_bed_at.is_empty():
		var used: Array = []
		used.resize(m.village.doors.size())
		used.fill(0)
		for sid in Main.SLEEP_IDS:
			var need := 2 if sid == "kongal" else 1 # Kongal's kid goblin sleeps beside her
			var at: Vector2 = m.village.folk_pos[sid]
			var best := -1
			for i in m.village.doors.size():
				if used[i] + need <= Main.HOUSE_SPOTS.size() and (best < 0 or at.distance_to(m.village.doors[i]) < at.distance_to(m.village.doors[best])):
					best = i
			m.folk_bed_at[sid] = [best, used[best]]
			used[best] += 1
			if sid == "kongal":
				m.folk_bed_at["kid"] = [best, used[best]]
				used[best] += 1
	return m.folk_bed_at[id]

func bed_spot(id: String) -> Vector2:
	return Vector2(Main.HOUSE_X, 0) + Main.HOUSE_SPOTS[folk_bed(id)[1]]

# show or hide one sleeper on his spot; returns whether he lies on a bedroll in this room
func place_sleeper(id: String, on: bool) -> bool:
	var bed: Node3D = m.sleeper_nodes[id]
	var k: int = folk_bed(id)[1]
	var at := bed_spot(id)
	bed.position = Vector3(at.x, 0, at.y)
	bed.rotation.y = Main.CAM_YAW # square to the fixed camera
	bed.get_node("frame").visible = k > 0 # the first spot is the room's own bed
	bed.visible = on
	return on and k > 0

func folk_awake_here(id: String) -> bool:
	return id != "mulgyeol" or m.mate == null # Mulgyeol travels with Sora once he joins

func folk_talk_at(id: String) -> Vector2:
	if not folk_awake_here(id):
		return m.village.folk_pos[id]
	match m.folk_state.get(id, "out"):
		"in":
			return bed_spot(id) if m.in_house == folk_home(id) else Vector2.INF
		"going", "coming":
			var spr: Sprite3D = m.village.folk_node[id]
			return Vector2(spr.position.x, spr.position.z)
	if Main.FOLK_ROUTES.has(id) and m.folk_route.has(id): # by day wherever his round has taken him
		return m.folk_route[id].pos
	return m.village.folk_pos[id]

func route_at(id: String, i: int) -> Vector2:
	var p: Vector2 = Main.FOLK_ROUTES[id][i][0]
	return Vector2(Main.VILLAGE.VILLAGE_X + p.x, p.y)

func folk_route_state(id: String) -> Dictionary:
	if not m.folk_route.has(id):
		m.folk_route[id] = {"i": 0, "wait": randf_range(6.0, 14.0), "pos": m.village.folk_pos[id], "back": false, "dir": 1}
	return m.folk_route[id]

func route_reset(id: String) -> void:
	if Main.FOLK_ROUTES.has(id):
		var r := folk_route_state(id)
		r.i = 0
		r.pos = m.village.folk_pos[id]
		r.back = false
		r.wait = randf_range(6.0, 14.0)

func folk_on_point(id: String) -> bool:
	if not Main.FOLK_ROUTES.has(id) or not m.folk_route.has(id):
		return true
	var r: Dictionary = m.folk_route[id]
	return (r.pos as Vector2).distance_to(route_at(id, r.i)) < 0.01

func route_home(id: String) -> bool:
	return not Main.FOLK_ROUTES.has(id) or (folk_route_state(id).pos as Vector2).distance_to(m.village.folk_pos[id]) < 0.01

# an errand or a story waits for him on his spot
func folk_busy(id: String) -> bool:
	match id:
		"kongal": return m.errand >= 3 and m.kid_q < 3        # crying for her kid goblin until he is home
		"doran": return m.kid_q >= 3 and m.doran_q < 2        # the letter the crown should read
		"mulgyeol": return m.doran_q >= 3 and m.mul_q < 3     # waiting for his oar
	return false

# head back to his spot by the shorter way round the loop
func route_turn_home(id: String, r: Dictionary) -> void:
	var n: int = Main.FOLK_ROUTES[id].size()
	r.back = true
	r.dir = 1
	if r.i == 0:
		return
	var on_point: bool = (r.pos as Vector2).distance_to(route_at(id, r.i)) < 0.01
	if n - r.i <= r.i:
		if on_point:
			r.i = (r.i + 1) % n
	else:
		r.dir = -1
		r.i -= 1

# one step of his day; home_only walks him back to his spot (dusk, an errand, the tests). Returns whether he moved.
func route_update(id: String, dt: float, home_only: bool, speed: float) -> bool:
	var r := folk_route_state(id)
	var pts: Array = Main.FOLK_ROUTES[id]
	var n := pts.size()
	if home_only and not r.back and not route_home(id):
		route_turn_home(id, r)
	var to := route_at(id, r.i)
	if (r.pos as Vector2).distance_to(to) < 0.01: # on a point
		if r.back:
			if r.i == 0:
				r.back = false
				r.wait = randf_range(6.0, 14.0)
			else:
				r.i = (r.i + r.dir + n) % n
		elif home_only:
			pass
		elif pts[r.i][1] and r.wait > 0.0:
			r.wait -= dt
		else:
			r.i = (r.i + 1) % n
		return false
	var d: Vector2 = to - r.pos
	var dir := d.normalized()
	if Vector2(m.player.x, m.player.z).distance_to(r.pos + dir * 0.5) < 0.9: # Sora is in the way: let her pass
		r.stalled = r.get("stalled", 0.0) + dt
		return false
	if r.get("stalled", 0.0) >= 1.0: # a real wait is over (not a brush past): a small nod of thanks
		folk_nods += 1
		nod_t["folk_" + id] = NOD_T
	r.stalled = 0.0
	r.pos = (r.pos as Vector2) + dir * minf(dt * speed, d.length())
	(m.village.folk_node[id] as Sprite3D).flip_h = m.screen_left(dir)
	if (r.pos as Vector2).distance_to(to) < 0.01:
		r.pos = to
		if pts[r.i][1] and not r.back:
			r.wait = randf_range(6.0, 14.0)
	return true

# stopping after a run in front of a sleeper's house, the little z over its door bobs more slowly for a moment (delight idea 27);
# nobody wakes and nothing about the sleepers changes
const Z_SLOW_TIME := 2.5
const Z_SLOW_RATE := 0.4
const Z_NEAR := 6.0
var z_clock := 0.0 # the z's bob phase, advancing at z_rate per second
var z_rate := 1.0
var z_slow_left := 0.0
var z_run_t := -100.0 # when she last ran
var z_slows := 0 # slow-downs started (autoplay d27_sleep_z)

func update_z_slow(dt: float) -> void:
	var spd := Vector2(m.player.vx, m.player.vz).length()
	var near := false
	if m.in_village and m.in_house < 0 and not m.story_open:
		for id in m.door_z:
			var dz: Label3D = m.door_z[id]
			near = near or (dz.visible and Vector2(dz.position.x - m.player.x, dz.position.z - m.player.z).length() < Z_NEAR)
	if spd > 4.2:
		z_run_t = m.t
	elif spd < 0.3 and m.t - z_run_t < 0.8:
		z_run_t = -100.0
		if near:
			z_slow_left = Z_SLOW_TIME
			z_slows += 1
	z_slow_left = maxf(0.0, z_slow_left - dt)
	z_rate = move_toward(z_rate, Z_SLOW_RATE if z_slow_left > 0.0 and near else 1.0, dt * 3.0)
	z_clock += dt * z_rate

func update_folk_sleep(dt: float) -> void:
	if m.village == null or m.village.doors.is_empty():
		return
	update_z_slow(dt)
	var night := folk_should_sleep()
	var watching := m.in_village and m.in_house < 0 # walking home is only worth showing when she is on the street
	var rolls := {} # bedroll spots taken in the room she is in
	if m.folk_rocks.is_empty(): # the rocks this touches every frame, found once
		for r in m.rocks:
			if r.has("folk"):
				m.folk_rocks[r.folk] = r
			elif r.has("spot"):
				m.folk_rocks["spot%d" % r.spot] = r
	for id in Main.SLEEP_IDS:
		if not m.village.folk_node.has(id) or not folk_awake_here(id):
			continue
		var spr: Sprite3D = m.village.folk_node[id]
		var home: Vector2 = m.village.folk_pos[id]
		var door: Vector2 = m.village.doors[folk_home(id)]
		var st: String = m.folk_state.get(id, "out")
		var k: float = m.folk_walk_t.get(id, 0.0)
		if night and st in ["out", "coming"]:
			st = "going" if watching else "in"
			if st == "in":
				k = 1.0
				route_reset(id)
		elif not night and st in ["in", "going"]:
			st = "coming" if watching else "out"
			if st == "out":
				k = 0.0
				route_reset(id)
		var way := folk_way(id)
		var step := dt * FOLK_WALK / maxf(1.0, way_length(way))
		var roam := false # on his day round (or walking it back to his spot at dusk)
		if st == "going" and not route_home(id): # dusk caught him out on his round: back along it first
			roam = route_update(id, dt, true, FOLK_WALK)
		elif st == "going":
			k = minf(1.0, k + step)
			if k >= 1.0:
				st = "in"
				route_reset(id)
				if watching:
					m.sfx(180, 0.15, "square", 0.08, -60) # the door shuts
		elif st == "coming":
			k = maxf(0.0, k - step)
			if k <= 0.0:
				st = "out"
		elif st == "out" and Main.FOLK_ROUTES.has(id):
			roam = route_update(id, dt, m.routine_off or folk_busy(id) or m.is_night(), ROUTE_WALK)
		var at := way_at(way, k)
		if Main.FOLK_ROUTES.has(id) and k <= 0.0 and st in ["out", "going"]:
			at = folk_route_state(id).pos
		spr.position = Vector3(at.x, 0.0, at.y)
		hop("folk_" + id, spr, dt, 0.0, HOP_H * folk_hop_scale(id), true)
		spr.visible = st != "in"
		if st in ["going", "coming"] and not roam:
			var ahead := way_at(way, clampf(k + (0.02 if st == "going" else -0.02), 0.0, 1.0))
			if ahead.distance_to(at) > 0.001:
				spr.flip_h = m.screen_left(ahead - at)
		if m.folk_rocks.has(id): # he blocks the way where he stands, only while he is out and not on his way between
			# two points (stopped mid-leg to let Sora pass he used to block her too: both stood still, GPT playtests 2 -> 9)
			m.folk_rocks[id].r = 0.45 if st == "out" and folk_on_point(id) else 0.0
			m.folk_rocks[id].x = at.x
			m.folk_rocks[id].z = at.y
		m.folk_state[id] = st
		m.folk_walk_t[id] = k
		if m.sleeper_nodes.has(id) and place_sleeper(id, st == "in" and m.in_house == folk_home(id)):
			rolls[folk_bed(id)[1]] = true
		if not m.door_z.has(id):
			var z := Label3D.new()
			z.text = "z"
			z.font = m.ui_font
			z.font_size = 64
			z.modulate = Color("#eef3ff")
			z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			m.add_child(z)
			m.door_z[id] = z
		var dz: Label3D = m.door_z[id]
		dz.visible = st == "in" and m.in_village and m.in_house < 0
		dz.position = Vector3(door.x + 0.35 * float(folk_bed(id)[1] - 1), 2.6 + 0.15 * sin(z_clock * 2.0 + Main.SLEEP_IDS.find(id)), door.y - 0.4)
	# Kongal's kid goblin stays at her side, and sleeps in her house
	if m.kid_node != null and m.kid_q == 3:
		var kst: String = m.folk_state.get("kongal", "out")
		m.kid_node.visible = kst != "in"
		var ks: Sprite3D = m.village.folk_node.kongal
		m.kid_node.position = Vector3(ks.position.x + 0.7, 0, ks.position.z + 0.3)
		hop("kid", m.kid_node.get_meta("spr"), dt, 0.0, HOP_H * 0.75)
		if m.sleeper_nodes.has("kid") and place_sleeper("kid", kst == "in" and m.in_house == folk_home("kongal")):
			rolls[folk_bed("kid")[1]] = true
	elif m.sleeper_nodes.has("kid"):
		m.sleeper_nodes.kid.visible = false
	for k in range(1, Main.HOUSE_SPOTS.size()):
		if m.folk_rocks.has("spot%d" % k):
			m.folk_rocks["spot%d" % k].r = 0.8 if rolls.has(k) else 0.0

func folk_hop_scale(id: String) -> float: # the hop follows the walker's height
	return 0.85 if id in ["tori", "kongal"] else 1.0

func folk_way(id: String) -> Array:
	if m.folk_ways.has(id):
		return m.folk_ways[id]
	var home: Vector2 = m.village.folk_pos[id]
	var door: Vector2 = m.village.doors[folk_home(id)]
	var vx := float(Main.VILLAGE.VILLAGE_X)
	var from := Vector2i(int(round(home.x - vx)), int(round(home.y)))
	var goal := Vector2i(int(round(door.x - vx)), int(round(door.y)))
	var prev := {from: from}
	var todo: Array = [from]
	while not todo.is_empty() and not prev.has(goal):
		var c: Vector2i = todo.pop_front()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + dv
			if prev.has(n) or n.x < 0 or n.y < 0 or n.x >= Main.VILLAGE.W or n.y >= Main.VILLAGE.H or m.village.blocked(vx + n.x, n.y):
				continue
			prev[n] = c
			todo.append(n)
	var way: Array = [door]
	if prev.has(goal):
		var c: Vector2i = prev[goal]
		while c != from:
			way.push_front(Vector2(vx + c.x, c.y))
			c = prev[c]
	way.push_front(home)
	m.folk_ways[id] = way
	return way

func way_length(way: Array) -> float:
	var n := 0.0
	for i in range(1, way.size()):
		n += (way[i] as Vector2).distance_to(way[i - 1])
	return n

func way_at(way: Array, k: float) -> Vector2: # k 0 at his spot, 1 at his door
	var left := way_length(way) * clampf(k, 0.0, 1.0)
	for i in range(1, way.size()):
		var a: Vector2 = way[i - 1]
		var b: Vector2 = way[i]
		var d := a.distance_to(b)
		if left <= d:
			return a.lerp(b, left / maxf(d, 0.0001))
		left -= d
	return way[way.size() - 1]

func house_door_near() -> int:
	for i in m.village.doors.size():
		if Vector2(m.player.x, m.player.z).distance_to(m.village.doors[i]) < 0.9:
			return i
	return -1

# a little bell over the doorway inside every house: it rings a beat after she steps in, swinging twice, the small sound
# only at the end of the second swing (delight idea 3)
var bell: Node3D
var bell_rings := 0 # times it has rung (autoplay door_bell)

func build_door_bell() -> void:
	var wood: Material = m.mat_color(Color("#6a4a2e"))
	var at := Vector3(Main.HOUSE_EXIT.x, 0, Main.HOUSE_EXIT.y - 0.15)
	for sx in [-0.6, 0.6]:
		var post: MeshInstance3D = m.box(Vector3(0.08, 1.8, 0.08), wood)
		post.position = Vector3(at.x + sx, 0.9, at.z)
		m.add_child(post)
	var bar: MeshInstance3D = m.box(Vector3(1.3, 0.07, 0.07), wood)
	bar.position = Vector3(at.x, 1.8, at.z)
	m.add_child(bar)
	bell = Node3D.new()
	bell.position = Vector3(at.x, 1.78, at.z)
	var loop: MeshInstance3D = m.box(Vector3(0.02, 0.16, 0.02), m.mat_color(Color("#3a2a1a")))
	loop.position = Vector3(0, -0.08, 0)
	bell.add_child(loop)
	var body: MeshInstance3D = m.box(Vector3(0.13, 0.15, 0.13), m.mat_color(Color("#e8b018")))
	body.position = Vector3(0, -0.24, 0)
	bell.add_child(body)
	var clap: MeshInstance3D = m.box(Vector3(0.05, 0.05, 0.05), m.mat_color(Color("#8a6a1a")))
	clap.position = Vector3(0, -0.34, 0)
	bell.add_child(clap)
	m.add_child(bell)

func ring_door_bell() -> void:
	if m.in_house < 0 or bell == null:
		return
	bell_rings += 1
	var tw := bell.create_tween()
	tw.tween_property(bell, "rotation:z", 0.5, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bell, "rotation:z", -0.4, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bell, "rotation:z", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): m.sfx(1760, 0.45, "sine", 0.07))

func enter_house(i: int) -> void:
	m.get_tree().create_timer(0.55).timeout.connect(ring_door_bell) # a beat after she is in
	m.in_house = i
	m.house_wall_mat.albedo_color = HOUSE_WALLS[i % HOUSE_WALLS.size()]
	m.player.x = Main.HOUSE_X + 4.0
	m.player.z = 5.0
	m.ground_y = 0.0
	m.ui.zone_sub.text = tr("마을 집 %d") % (i + 1)
	var img := Image.create(Main.HOUSE_X + 9, 7, false, Image.FORMAT_RGBA8) # a tiny map of the room for the minimap
	img.fill(Color(0, 0, 0, 0))
	for z in HOUSE_ROWS.size():
		for x in HOUSE_ROWS[0].length():
			if HOUSE_ROWS[z][x] != "#":
				img.set_pixel(Main.HOUSE_X + x, z, Color("#6a5034"))
	m.ui.mini.map_tex = ImageTexture.create_from_image(img)
	m.snap_mates()
	m.save_game()

func leave_house() -> void:
	var d: Vector2 = m.village.doors[m.in_house]
	m.in_house = -1
	m.player.x = d.x
	m.player.z = d.y + 0.4
	m.ground_y = 0.0
	m.ui.zone_sub.text = "마을 거리"
	m.ui.mini.map_tex = m.village.map_tex(Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W)
	m.snap_mates()
	m.save_game()

func cupboard_key() -> bool:
	if m.in_house < 0 or Vector2(m.player.x, m.player.z).distance_to(Vector2(m.cupboard.position.x, m.cupboard.position.z)) > 1.5:
		return false
	m.house_seen[m.in_house] = true
	if m.in_house == HOUSE_CUPBOARD.size() - 1:
		m.show_story("res://art/story/15_old_picture.jpg", Main.STORY.HOUSE_PICTURE, true)
	else:
		m.toast(tr(HOUSE_CUPBOARD[m.in_house % HOUSE_CUPBOARD.size()]))
	m.sfx(784, 0.12, "triangle", 0.25)
	m.save_game()
	return true
