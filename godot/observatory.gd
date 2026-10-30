# 달맞이 관측원 (v0.1.120, the owner chose "1안: 물길·관측원" 2026-10-29; design in shots/plans/option1_design.md and hero_journey_fix.md B):
# four rooms of 30x22 at x = 900, 940, 980, 1020 (z 0..21), entered from the hill's stair O (beside the castle road X), before the castle.
# Noeul keeps Sora's hand steady at the post; Sora counts as "on the hill" up here; the observatory is told apart by x
# (sys/observatory_zone.gd in_observatory).
# Letters: # wall, . floor, _ gap (a dark drop; the swivel platform T bridges cols 8..10 rows 9..11), S stair back, N door to the next
# room, D gate (opens by progress), L lantern, H Hangyeol's note, C the answer stand, B the boss spot, e a brick scale-bird,
# M windmill (E turns on the fixed east wind), O the wind hole (carries Sora over the gap while the wind blows), T swivel platform,
# P Noeul's post, R mirror (E turns it north, east, south, west), Q receiver lamp.
extends RefCounted

const OBS_X := 900
const GAP := 40
const W := 30
const H := 22
const ROOMS := 4
const ROWS_1 := """##############################
#.......___.........#........#
#.......___.........#........#
#.......___.........#........#
#...L...___.....L...#........#
#.......___.........#........#
#.......___....e....#........#
#.......___....Q....#........#
#.......___.........#........#
#.......___.........#........#
#.S.M..O___.T..R....D......N.#
#.......___.........#........#
#....P..___.........#........#
#.......___.........#........#
#.......___......e..#........#
#.......___.........#........#
#.......___.........#........#
#...H...___.........#....L...#
#.......___.........#........#
#.......___.........#........#
#.......___.........#........#
##############################"""
const ROWS_2 := """##############################
#.......___.........#........#
#.......___.........#........#
#.......___.........#........#
#...L...___.....L...#........#
#.......___.........#........#
#.......___....e....#........#
#.......___....Q....#........#
#.......___.........#........#
#.......___.........#........#
#.S.M..O___.T..R....D......N.#
#.......___.........#........#
#....P..___.........#........#
#.......___.........#........#
#.......___......e..#........#
#.......___.........#........#
#.......___.........#........#
#...L...___.........#....L...#
#.......___.........#........#
#.......___.........#........#
#.......___.........#........#
##############################"""
const ROWS_4 := """##############################
#............................#
#............................#
#............................#
#...L........................#
#.........R....R....R........#
#............................#
#............................#
#............................#
#............................#
#.S.M..........B...........C.#
#............................#
#....P.......................#
#............................#
#............................#
#.................Q..........#
#............................#
#...H....................L...#
#............................#
#............................#
#............................#
##############################"""
const NAMES := ["관측원 · 바람 길", "관측원 · 꺼진 빛", "관측원 · 떨리는 손", "관측원 · 신호"]
# each room its own look: dusk lilac, cold blue, warm amber, the night-blue top with its stars
const FLOOR_COL := ["#b4a8c0", "#98a8c4", "#c4b08c", "#8a92b8"]
const WALL_COL := ["#4a4260", "#34425e", "#5c4a34", "#2a3050"]
const GAP_COL := ["#14101e", "#0c1220", "#1c140c", "#080a18"]
const LIGHT_COL := ["#d8c4ff", "#a8d0ff", "#ffe0a8", "#b8c8ff"]
const AMBIENT_COL := ["#b4a4d8", "#9ab4e0", "#dcc49a", "#8a9ad8"]
const DIRS := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)] # mirror dir 0 north, 1 east, 2 south, 3 west
const ANS_TOP := [1, 1, 2] # the top room's mirrors, west to east
const GAP_ROWS := [9, 10, 11] # the swivel platform fills cols 8..10 of these rows

var grids: Array = []       # [room][row] strings
var spots: Array = []       # [room] letter -> Array of world Vector2
var gate_open: Array = [false, false, false, false]
var plat_open: Array = [false, false, false, false] # [room] the platform bridges the gap now
var plat_goal: Array = [0, 0, 0, 0] # [room] the angle its boards are turning to (open is set when the turn is over)
var gate_nodes: Array = []  # [room] the brick gate at D
var plat_nodes: Array = []  # [room] the swivel platform's pivot
var plat_vis: Array = [PI / 2.0, PI / 2.0, PI / 2.0, PI / 2.0] # [room] its yaw now (0 bridging, PI/2 across the gap)
var plat_lamps: Array = []  # [room] the console lamp
var mill_blades: Array = [] # [room] the windmill's rotor
var wind_on: Array = [false, false, false, false]
var hole_nodes: Array = []  # [room] the wind hole's whirl
var hole_mats: Array = []
var mirrors: Array = []     # [room] Array of {"node": pointer pivot, "mat", "pos": Vector2}
var grooves: Array = []     # [room] Array of StandardMaterial3D, one per light run
var arrows: Array = []      # [room] Array of the answer arrows (materials follow the runs)
var q_mats: Array = []      # [room] the receiver's crystal
var post_pads: Array = []   # [room] the glow of Noeul's post
var plates: Array = []      # [room] the note's glow
var lamp_mat: StandardMaterial3D # the second floor's power lantern
var stand_lamps: Array = [] # the answer stand's three lamps (materials)
var stand_jar: StandardMaterial3D
var room_lights: Array = []
var shortcut: Node3D        # the hill sign by the top room's stair, once the answer is sent
var bracelet: Node3D        # the little blue light at Sora's wrist
var bracelet_mat: StandardMaterial3D

func _init() -> void:
	for r in ROOMS:
		var g: Array = []
		var src: String = [ROWS_1, ROWS_2, ROWS_2, ROWS_4][r]
		for line in src.split("\n"):
			g.append(line)
		grids.append(g)
		spots.append({})
		gate_nodes.append(null)
		plat_nodes.append(null)
		plat_lamps.append(null)
		mill_blades.append(null)
		hole_nodes.append(null)
		hole_mats.append(null)
		mirrors.append([])
		grooves.append([])
		arrows.append([])
		q_mats.append(null)
		post_pads.append(null)
		plates.append(null)
		for z in H:
			for x in W:
				var c: String = g[z][x]
				if c != "#" and c != "." and c != "_":
					if not spots[r].has(c):
						spots[r][c] = []
					spots[r][c].append(Vector2(origin(r) + x, z))

func origin(r: int) -> int:
	return OBS_X + GAP * r

func room_of(x: float) -> int:
	return clampi(floori((x - (OBS_X - 0.5)) / GAP), 0, ROOMS - 1)

func at(r: int, c: String, i := 0) -> Vector2:
	return spots[r][c][i] if spots[r].has(c) and spots[r][c].size() > i else Vector2.INF

func char_at(x: float, z: float) -> String:
	var r := room_of(x)
	var tx := int(round(x)) - origin(r)
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= W or tz >= H:
		return "#"
	return grids[r][tz][tx]

# walls, a shut gate, and the gap unless the platform bridges its three rows
func blocked(x: float, z: float) -> bool:
	var c := char_at(x, z)
	if c == "#":
		return true
	if c == "D":
		return not gate_open[room_of(x)]
	if c == "_":
		return not (plat_open[room_of(x)] and int(round(z)) in GAP_ROWS)
	return false

# the gap's tiles, for the platform and the gust
func on_gap(r: int, p: Vector2, pad := 0.0) -> bool:
	var lx := p.x - origin(r)
	return lx > 7.5 - pad and lx < 10.5 + pad and p.y > 8.5 - pad and p.y < 11.5 + pad

func dir_vec(d: int) -> Vector2:
	return DIRS[posmod(d, 4)]

func build(m: Node) -> void:
	for r in ROOMS:
		build_room(m, r)
	bracelet = Node3D.new()
	bracelet_mat = m.glow_mat(Color("#7fd0ff"), 2.4)
	for k in 2:
		var b: MeshInstance3D = m.box(Vector3(0.07, 0.07, 0.07), bracelet_mat)
		b.position = Vector3(0.0, 0.0, k * 0.1)
		bracelet.add_child(b)
	bracelet.visible = false
	m.add_child(bracelet)

func build_room(m: Node, r: int) -> void:
	var blocks: Array = []
	var o := origin(r)
	var g: Array = grids[r]
	var lamp_spots: Array = []
	for z in H:
		for x in W:
			var c: String = g[z][x]
			var w := Vector2(o + x, z)
			var col := Color(FLOOR_COL[r])
			var hgt := 0.4
			match c:
				"#":
					col = Color(WALL_COL[r])
					hgt = 0.9
				"_":
					col = Color(GAP_COL[r])
					hgt = 0.04 # the gap lies far lower than the floor
			if c == "L" and not (r == 1 and w.y == 4 and x == 16):
				lamp_spots.append(w)
			col = col.lightened(m.rnd(0, 0.07))
			if c != "#" and c != "_" and (x + z) % 2 == 0:
				col = col.darkened(0.05) # a faint checker, so the long floors read as stone slabs
			blocks.append([Transform3D(Basis().scaled(Vector3(1, hgt, 1)), Vector3(w.x, hgt / 2.0 - 0.4, w.y)), col])
			if c == "#" and (x * 7 + z * 3 + r) % 11 == 0 and x > 0 and x < W - 1 and z > 0 and z < H - 1:
				blocks.append([Transform3D(Basis().scaled(Vector3(0.9, 0.9, 0.2)), Vector3(w.x, 0.75, w.y + 0.45)), Color("#6a6674")]) # a bricked-up old window
	m.add_chunks(blocks, OBS_X)
	var post_mat: Material = m.mat_color(Color("#3b2a1e"))
	var glass: Material = m.glow_mat(Color(LIGHT_COL[r]), 3.5)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	for w in lamp_spots:
		m.lantern(w.x - 0.3, w.y, post_mat, glass)
	var l := OmniLight3D.new()
	l.light_color = Color(LIGHT_COL[r])
	l.light_energy = 1.4
	l.omni_range = 11.0
	l.position = Vector3(o + 14.0, 3.2, 10.0)
	m.add_child(l)
	room_lights.append(l)
	build_props(m, r)
	build_light(m, r)
	build_dress(m, r)

# ---- the light runs: thin glowing boxes in the floor, a lit run is bright, a dark one barely shows
func run_box(m: Node, a: Vector2, b: Vector2, mat: Material) -> void:
	var d := b - a
	var bx: MeshInstance3D = m.box(Vector3(absf(d.x) + 0.14, 0.03, absf(d.y) + 0.14), mat)
	bx.position = Vector3((a.x + b.x) / 2.0, 0.02, (a.y + b.y) / 2.0)
	m.add_child(bx)

func new_run(m: Node, r: int, pts: Array, col: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = m.glow_mat(col, 0.12)
	for i in pts.size() - 1:
		run_box(m, pts[i], pts[i + 1], mat)
	grooves[r].append(mat)
	return mat

# a small chevron on the floor where a run leaves a mirror: the answer direction
func chevron(m: Node, from: Vector2, dir: Vector2, mat: Material) -> void:
	var c: MeshInstance3D = m.box(Vector3(0.3, 0.04, 0.3), mat)
	c.position = Vector3(from.x + dir.x * 0.85, 0.03, from.y + dir.y * 0.85)
	c.rotation.y = PI / 4.0
	m.add_child(c)

func build_light(m: Node, r: int) -> void:
	var o := origin(r)
	var col := Color("#fff0b0")
	var lens_mat: StandardMaterial3D = m.glow_mat(Color("#ffe48a"), 2.0)
	var P := func(x: float, z: float) -> Vector2: return Vector2(o + x, z)
	if r < 3:
		var rm := at(r, "R")
		var q := at(r, "Q")
		var src := Vector2(o + 18, rm.y)
		var lens: MeshInstance3D = m.box(Vector3(0.5, 0.35, 0.5), lens_mat)
		lens.position = Vector3(src.x, 0.2, src.y)
		m.add_child(lens)
		new_run(m, r, [src, rm], col) # 0: the light into the mirror
		var out: StandardMaterial3D = new_run(m, r, [rm, q], col) # 1: the mirror's light to the receiver
		chevron(m, rm, Vector2(0, -1), out)
		if r == 1: # 2: the lantern's power down to the source
			new_run(m, r, [at(r, "L", 1), P.call(18, 4), src], Color("#ffd27a"))
	else:
		var q3 := at(3, "Q")
		var rs: Array = spots[3]["R"]
		var src3: Vector2 = P.call(6, 5)
		var lens3: MeshInstance3D = m.box(Vector3(0.5, 0.35, 0.5), lens_mat)
		lens3.position = Vector3(src3.x, 0.2, src3.y)
		m.add_child(lens3)
		var m0: StandardMaterial3D = new_run(m, 3, [src3, rs[0]], col) # 0: the light into the west mirror
		var m1: StandardMaterial3D = new_run(m, 3, [rs[0], rs[1]], col) # 1: west to middle
		var m2: StandardMaterial3D = new_run(m, 3, [rs[1], rs[2]], col) # 2: middle to east
		var m3: StandardMaterial3D = new_run(m, 3, [rs[2], P.call(20, 15), q3], col) # 3: east, down the wall and in to the receiver
		chevron(m, rs[0], Vector2(1, 0), m1)
		chevron(m, rs[1], Vector2(1, 0), m2)
		chevron(m, rs[2], Vector2(0, 1), m3)
		chevron(m, src3, Vector2(1, 0), m0)

func build_props(m: Node, r: int) -> void:
	var iron: Material = m.mat_color(Color("#5a5a64"))
	var brass: Material = m.mat_color(Color("#c8962a"))
	var stone: Material = m.mat_color(Color("#c8ccd4"))
	m.grotto.exit_steps(m, at(r, "S")) # the way back: pale steps and a warm lamp, as in the grotto
	if r < 3:
		m.lake_zone.stair_frame(at(r, "N"), -PI / 2.0, 0.0, Color(LIGHT_COL[r])) # on to the next room
		build_gate(m, r)
	# M: the windmill, a stone tower with four sails
	var mm := at(r, "M")
	if mm != Vector2.INF:
		var tw := Node3D.new()
		var base: MeshInstance3D = m.box(Vector3(0.7, 1.4, 0.7), m.mat_color(Color("#cfc8d8")))
		base.position = Vector3(0, 0.7, 0)
		tw.add_child(base)
		var cap: MeshInstance3D = m.box(Vector3(0.9, 0.2, 0.9), m.mat_color(Color("#6a5a7a")))
		cap.position = Vector3(0, 1.5, 0)
		tw.add_child(cap)
		var rotor := Node3D.new()
		rotor.position = Vector3(0, 1.15, 0.42)
		for k in 2:
			var sail: MeshInstance3D = m.box(Vector3(1.5, 0.16, 0.05), m.mat_color(Color("#f2ead8")))
			sail.rotation.z = k * PI / 2.0
			rotor.add_child(sail)
		var hub: MeshInstance3D = m.box(Vector3(0.14, 0.14, 0.1), brass)
		rotor.add_child(hub)
		tw.add_child(rotor)
		tw.position = Vector3(mm.x, 0, mm.y)
		m.add_child(tw)
		mill_blades[r] = rotor
	# O: the wind hole, a dark mouth with a ring of whirling streaks
	var oo := at(r, "O")
	if oo != Vector2.INF:
		var hmat: StandardMaterial3D = m.glow_mat(Color("#bfe6ff"), 0.15)
		var hole: MeshInstance3D = m.box(Vector3(0.95, 0.04, 0.95), m.mat_color(Color("#0a0e18")))
		hole.position = Vector3(oo.x, 0.03, oo.y)
		m.add_child(hole)
		for side in [-0.5, 0.5]:
			var rim: MeshInstance3D = m.box(Vector3(0.08, 0.05, 1.08), hmat)
			rim.position = Vector3(oo.x + side, 0.05, oo.y)
			m.add_child(rim)
			var rim2: MeshInstance3D = m.box(Vector3(1.08, 0.05, 0.08), hmat)
			rim2.position = Vector3(oo.x, 0.05, oo.y + side)
			m.add_child(rim2)
		var whirl := Node3D.new()
		whirl.position = Vector3(oo.x, 0.0, oo.y)
		for k in 3:
			var s: MeshInstance3D = m.box(Vector3(0.05, 0.9, 0.05), hmat)
			s.position = Vector3(cos(k * TAU / 3.0) * 0.3, 0.55, sin(k * TAU / 3.0) * 0.3)
			whirl.add_child(s)
		whirl.visible = false
		m.add_child(whirl)
		hole_nodes[r] = whirl
		hole_mats[r] = hmat
	# T: the swivel platform. Three boards pivot about the middle of the gap: E-W they bridge it, N-S they leave it open.
	var t := at(r, "T")
	if t != Vector2.INF:
		var pad: MeshInstance3D = m.box(Vector3(0.7, 0.2, 0.7), iron)
		pad.position = Vector3(t.x, 0.1, t.y)
		m.add_child(pad)
		var pl_mat: StandardMaterial3D = m.glow_mat(Color("#ffd27a"), 0.4)
		var lamp: MeshInstance3D = m.box(Vector3(0.2, 0.2, 0.2), pl_mat)
		lamp.position = Vector3(t.x, 0.45, t.y)
		m.add_child(lamp)
		plat_lamps[r] = pl_mat
		var piv := Node3D.new()
		piv.position = Vector3(origin(r) + 9.0, 0.0, 10.0)
		for k in 3:
			var board: MeshInstance3D = m.box(Vector3(3.0, 0.14, 0.62), m.mat_color(Color("#9a7a52")))
			board.position = Vector3(0, -0.02, (k - 1) * 1.0)
			piv.add_child(board)
			var stud: MeshInstance3D = m.box(Vector3(0.14, 0.05, 0.14), brass)
			stud.position = Vector3(0, 0.07, (k - 1) * 1.0)
			piv.add_child(stud)
		piv.rotation.y = plat_vis[r]
		m.add_child(piv)
		plat_nodes[r] = piv
	# P: Noeul's post, a gold pad with a low stone rim on the floor
	var p := at(r, "P")
	if p != Vector2.INF:
		var pm: StandardMaterial3D = m.glow_mat(Color("#ffc46a"), 0.7)
		var pad2: MeshInstance3D = m.box(Vector3(0.95, 0.05, 0.95), pm)
		pad2.position = Vector3(p.x, 0.03, p.y)
		m.add_child(pad2)
		for side in [-0.5, 0.5]:
			var rim: MeshInstance3D = m.box(Vector3(0.08, 0.12, 1.08), stone)
			rim.position = Vector3(p.x + side, 0.06, p.y)
			m.add_child(rim)
		post_pads[r] = pm
	# R: mirrors on short posts, a pointer arm showing the way each looks
	for i in (spots[r]["R"].size() if spots[r].has("R") else 0):
		var rp: Vector2 = spots[r]["R"][i]
		var piv2 := Node3D.new()
		piv2.position = Vector3(rp.x, 0, rp.y)
		var post: MeshInstance3D = m.box(Vector3(0.14, 0.7, 0.14), iron)
		post.position = Vector3(0, 0.35, 0)
		piv2.add_child(post)
		var disc: MeshInstance3D = m.box(Vector3(0.6, 0.1, 0.6), m.mat_color(Color("#d8e4f0")))
		disc.position = Vector3(0, 0.75, 0)
		piv2.add_child(disc)
		var amat: StandardMaterial3D = m.glow_mat(Color("#ffe48a"), 0.4)
		var arm := Node3D.new()
		arm.position = Vector3(0, 0.84, 0)
		var shaft: MeshInstance3D = m.box(Vector3(0.1, 0.08, 0.8), amat)
		shaft.position = Vector3(0, 0, 0.4)
		arm.add_child(shaft)
		var head: MeshInstance3D = m.box(Vector3(0.26, 0.08, 0.1), amat)
		head.position = Vector3(0, 0, 0.82)
		arm.add_child(head)
		piv2.add_child(arm)
		m.add_child(piv2)
		mirrors[r].append({"node": arm, "mat": amat, "pos": rp})
		arm.rotation.y = atan2(DIRS[2].x, DIRS[2].y)
	# Q: the receiver, a pedestal with a crystal
	var q := at(r, "Q")
	if q != Vector2.INF:
		var ped: MeshInstance3D = m.box(Vector3(0.6, 0.5, 0.6), m.mat_color(Color("#c8ccd4")))
		ped.position = Vector3(q.x, 0.25, q.y)
		m.add_child(ped)
		var qm: StandardMaterial3D = m.glow_mat(Color("#9fd8ff"), 0.2)
		var crys: MeshInstance3D = m.box(Vector3(0.28, 0.4, 0.28), qm)
		crys.position = Vector3(q.x, 0.72, q.y)
		crys.rotation.y = PI / 4.0
		m.add_child(crys)
		q_mats[r] = qm
	# the second floor's power lantern: a taller lantern with its own glass, lit by E
	if r == 1:
		var lp := at(1, "L", 1)
		lamp_mat = m.glow_mat(Color("#ffd27a"), 0.15)
		var stand: MeshInstance3D = m.box(Vector3(0.14, 1.2, 0.14), m.mat_color(Color("#3b2a1e")))
		stand.position = Vector3(lp.x, 0.6, lp.y)
		m.add_child(stand)
		var glass: MeshInstance3D = m.box(Vector3(0.36, 0.4, 0.36), lamp_mat)
		glass.position = Vector3(lp.x, 1.4, lp.y)
		m.add_child(glass)
	# H: Hangyeol's note on a safety latch
	var h := at(r, "H")
	if h != Vector2.INF:
		var slab: MeshInstance3D = m.box(Vector3(0.95, 0.14, 0.75), m.mat_color(Color("#d8d4c8")))
		slab.position = Vector3(h.x, 0.07, h.y)
		m.add_child(slab)
		var pm2: StandardMaterial3D = m.glow_mat(Color("#ffd27a"), 0.5)
		var note: MeshInstance3D = m.box(Vector3(0.4, 0.03, 0.3), pm2)
		note.position = Vector3(h.x, 0.16, h.y)
		note.rotation.y = 0.3
		m.add_child(note)
		plates[r] = pm2
	# C: the answer stand with its three lamps
	var c := at(r, "C")
	if c != Vector2.INF:
		var ped2: MeshInstance3D = m.box(Vector3(0.8, 0.6, 0.8), m.mat_color(Color("#c8ccd4")))
		ped2.position = Vector3(c.x, 0.3, c.y)
		m.add_child(ped2)
		stand_jar = m.glow_mat(Color("#d8c4ff"), 0.3)
		var jar: MeshInstance3D = m.box(Vector3(0.34, 0.4, 0.34), stand_jar)
		jar.position = Vector3(c.x, 0.82, c.y)
		m.add_child(jar)
		for k in 3:
			var lm: StandardMaterial3D = m.glow_mat(Color("#ffd27a"), 0.15)
			var lp2: MeshInstance3D = m.box(Vector3(0.2, 0.2, 0.2), lm)
			lp2.position = Vector3(c.x - 0.9 + k * 0.9, 2.4, c.y - 1.2)
			m.add_child(lp2)
			var post2: MeshInstance3D = m.box(Vector3(0.08, 1.6, 0.08), iron)
			post2.position = Vector3(c.x - 0.9 + k * 0.9, 1.2, c.y - 1.2)
			m.add_child(post2)
			stand_lamps.append(lm)

func build_gate(m: Node, r: int) -> void:
	var d := at(r, "D")
	var g := Node3D.new()
	var frame: Material = m.mat_color(Color("#5a5040"))
	for side in [-0.6, 0.6]:
		var post: MeshInstance3D = m.box(Vector3(0.2, 1.7, 0.2), frame)
		post.position = Vector3(0, 0.85, side)
		g.add_child(post)
	var beam: MeshInstance3D = m.box(Vector3(0.2, 0.2, 1.4), frame)
	beam.position = Vector3(0, 1.7, 0)
	g.add_child(beam)
	g.position = Vector3(d.x, 0, d.y)
	m.add_child(g)
	var brick: Node3D = m.lake.brick_sluice(m, d)
	gate_nodes[r] = brick
	brick.visible = not gate_open[r]

func set_gate(r: int, open: bool) -> void:
	gate_open[r] = open
	if gate_nodes[r] != null:
		gate_nodes[r].visible = not open

# the platform: plat_open says whether the three rows are walkable now; plat_goal is where the boards turn to (instant: no turn)
func set_plat(r: int, angle: int, instant := true) -> void:
	plat_open[r] = angle == 1
	plat_goal[r] = angle
	if instant:
		plat_vis[r] = 0.0 if angle == 1 else PI / 2.0
		if plat_nodes[r] != null:
			plat_nodes[r].rotation.y = plat_vis[r]
	if plat_lamps[r] != null:
		plat_lamps[r].emission_energy_multiplier = 2.2 if angle == 1 else 0.4

func set_wind(r: int, on: bool) -> void:
	wind_on[r] = on
	if hole_nodes[r] != null:
		hole_nodes[r].visible = on and not plat_open[r]
	if hole_mats[r] != null:
		hole_mats[r].emission_energy_multiplier = 1.8 if on and not plat_open[r] else 0.15

func set_mirror(r: int, i: int, dir: int, locked: bool) -> void:
	if i >= mirrors[r].size():
		return
	var v: Vector2 = dir_vec(dir)
	var mi: Dictionary = mirrors[r][i]
	mi.node.rotation.y = atan2(v.x, v.y)
	mi.mat.emission_energy_multiplier = 2.4 if locked else 0.6

# a run's brightness: lit or dark
func set_run(r: int, i: int, lit: bool) -> void:
	if i < grooves[r].size():
		grooves[r][i].emission_energy_multiplier = 2.2 if lit else 0.12

func set_q(r: int, level: int) -> void: # 0 dark, 1 the light reaches it, 2 fixed
	if q_mats[r] != null:
		q_mats[r].emission_energy_multiplier = [0.2, 1.2, 3.0][clampi(level, 0, 2)]

func set_lamp(on: bool) -> void:
	if lamp_mat != null:
		lamp_mat.emission_energy_multiplier = 2.6 if on else 0.15

func set_post(r: int, on: bool) -> void:
	if post_pads[r] != null:
		post_pads[r].emission_energy_multiplier = 2.4 if on else 0.7

func set_plate(r: int, read: bool) -> void:
	if plates[r] != null:
		plates[r].emission_energy_multiplier = 2.2 if read else 0.5

func set_shortcut(on: bool) -> void:
	if shortcut != null:
		shortcut.visible = on

func tick(dt: float) -> void:
	for r in ROOMS:
		if wind_on[r] and mill_blades[r] != null:
			mill_blades[r].rotation.z += dt * 2.4
		if hole_nodes[r] != null and hole_nodes[r].visible:
			hole_nodes[r].rotation.y += dt * 4.0
		var target: float = 0.0 if plat_goal[r] == 1 else PI / 2.0
		if plat_nodes[r] != null and not is_equal_approx(plat_vis[r], target):
			plat_vis[r] = move_toward(plat_vis[r], target, dt * (PI / 2.0) / 2.0) # a quarter turn in 2 s
			plat_nodes[r].rotation.y = plat_vis[r]

# ---- set dressing: each room reads as an observatory with a story, built from boxes
func blk(m: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = m.box(size, mat)
	mi.position = pos
	m.add_child(mi)
	return mi

func build_dress(m: Node, r: int) -> void:
	var o := origin(r)
	var wood: Material = m.mat_color(Color("#8a6a42"))
	var dark: Material = m.mat_color(Color("#4a3322"))
	var brass: Material = m.mat_color(Color("#c8962a"))
	var iron: Material = m.mat_color(Color("#3a4048"))
	var cloth: Material = m.mat_color(Color("#a05a7a"))
	match r:
		0: # the wind road: flags on the gap's near posts, a bench and a brass telescope by the stair
			for z in [8.4, 11.6]:
				blk(m, Vector3(o + 7.45, 0.7, z), Vector3(0.1, 1.4, 0.1), dark)
				blk(m, Vector3(o + 7.1, 1.25, z), Vector3(0.7, 0.3, 0.04), cloth) # a streamer blowing west
			blk(m, Vector3(o + 1.9, 0.55, 14.6), Vector3(1.4, 0.1, 0.7), wood)
			for sx in [-0.6, 0.6]:
				blk(m, Vector3(o + 1.9 + sx, 0.25, 14.6), Vector3(0.1, 0.5, 0.1), dark)
			blk(m, Vector3(o + 4.8, 0.45, 15.8), Vector3(0.12, 0.9, 0.12), iron) # the telescope's stand and tube
			var tube := blk(m, Vector3(o + 4.8, 1.0, 15.8), Vector3(0.18, 0.18, 0.9), brass)
			tube.rotation.x = -0.4
		1: # the dark floor: dead lanterns on the near wall, a ledger, a crate of spare mirrors
			for z in [3.0, 7.0, 14.0]:
				blk(m, Vector3(o + 0.8, 1.3, z), Vector3(0.3, 0.4, 0.3), iron)
			blk(m, Vector3(o + 3.0, 0.3, 14.6), Vector3(0.7, 0.6, 0.7), wood)
			blk(m, Vector3(o + 3.0, 0.62, 14.6), Vector3(0.76, 0.06, 0.76), dark)
			for k in 2:
				blk(m, Vector3(o + 4.0 + k * 0.4, 0.4, 14.4), Vector3(0.05, 0.6, 0.5), m.mat_color(Color("#d8e4f0")))
		2: # the shaking floor: hand-ropes along the gap, a sandbag at the post, a bent weather vane
			for z in [8.5, 11.5]:
				blk(m, Vector3(o + 7.4, 0.5, z), Vector3(0.1, 1.0, 0.1), dark)
				blk(m, Vector3(o + 10.6, 0.5, z), Vector3(0.1, 1.0, 0.1), dark)
			blk(m, Vector3(o + 4.2, 0.2, 13.4), Vector3(0.6, 0.4, 0.5), m.mat_color(Color("#b89868")))
			blk(m, Vector3(o + 18.4, 0.7, 4.0), Vector3(0.08, 1.4, 0.08), iron)
			var vane := blk(m, Vector3(o + 18.4, 1.45, 4.0), Vector3(0.7, 0.1, 0.1), iron)
			vane.rotation.y = 0.9
		3: # the top: a ring of brass marks round the boss spot, a star table, a moon disc on the north wall
			for k in 12:
				var a := k * TAU / 12.0
				blk(m, Vector3(o + 15.0 + cos(a) * 3.2, 0.03, 10.0 + sin(a) * 3.2), Vector3(0.3, 0.03, 0.3), brass)
			blk(m, Vector3(o + 2.0, 0.5, 15.0), Vector3(1.8, 0.1, 1.0), wood)
			for sx in [-0.8, 0.8]:
				blk(m, Vector3(o + 2.0 + sx, 0.25, 15.0), Vector3(0.1, 0.5, 0.1), dark)
			blk(m, Vector3(o + 15.0, 1.9, 0.62), Vector3(2.6, 2.6, 0.08), m.glow_mat(Color("#dfe6ff"), 0.9))
			blk(m, Vector3(o + 16.0, 1.9, 0.56), Vector3(2.2, 2.2, 0.08), m.mat_color(Color("#2a3050"))) # the moon's shadow bite
			# the sign by the stair: the way back to the hill
			var s := at(3, "S")
			shortcut = Node3D.new()
			shortcut.position = Vector3(s.x + 0.6, 0, s.y - 1.6)
			var sp: MeshInstance3D = m.box(Vector3(0.1, 1.4, 0.1), dark)
			sp.position = Vector3(0, 0.7, 0)
			shortcut.add_child(sp)
			var sb: MeshInstance3D = m.box(Vector3(0.7, 0.55, 0.06), wood)
			sb.position = Vector3(0, 1.45, 0)
			shortcut.add_child(sb)
			var hs: Sprite3D = m.sign_icon("moon", 0.4)
			hs.position = Vector3(0, 1.45, 0.05)
			shortcut.add_child(hs)
			shortcut.visible = false
			m.add_child(shortcut)

func map_tex(width: int) -> ImageTexture:
	var img := Image.create(width, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for r in ROOMS:
		for z in H:
			for x in W:
				var c: String = grids[r][z][x]
				var col := Color("#262238")
				match c:
					"#": col = Color(0, 0, 0, 0)
					"_": col = Color("#3a4a6a") if not plat_open[r] or z not in GAP_ROWS else Color("#262238")
					"L": col = Color("#ffe48a")
					"D": col = Color("#c8502a") if not gate_open[r] else Color("#262238")
					"M", "O", "T", "P", "R", "Q", "H", "C": col = Color("#c8b4f0")
					"S", "N": col = Color("#ffd27a")
				img.set_pixel(origin(r) + x, z, col)
	return ImageTexture.create_from_image(img)
