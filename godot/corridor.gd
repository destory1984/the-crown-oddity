# 물길 회랑 (v0.1.84, the owner chose "1안: 물길·관측원", 2026-10-29; design in shots/plans/option1_design.md): four rooms of 30x22
# at x = 740, 780, 820, 860 (z 0..21), entered from the lake island's stair V after the pearl and the lower pond, before the forest.
# Mulgyeol keeps a sluice alone; at the end Sora keeps it and he rides the cart. Sora counts as "in the lake" down here;
# the corridor is told apart by x (sys/corridor_zone.gd in_corridor).
# Letters: # wall, . floor, S stair back, N door to the next room, D gate (opens by progress), L lantern, H Hangyeol's lock plate,
# C the answer stand, B the boss spot, e a brick bucket-foe, = the channel (low water: stone bed, high water: deep water that
# only the water skip crosses; the last room's tank is always high), A the water-level lever, P Mulgyeol's post,
# T cart, R mooring post, F wheel or latch.
extends RefCounted

const CORR_X := 740
const GAP := 40
const W := 30
const H := 22
const ROOMS := 4
const ROWS_1 := """##############################
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
#...L...===.........#........#
#.......===.........#........#
#.......===....e....#........#
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
#.S.A...===....F....D......N.#
#.......===.........#........#
#....P..===.........#........#
#.......===.........#........#
#.......===......e..#........#
#.......===.........#........#
#.......===.........#........#
#...H...===.........#....L...#
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
##############################"""
const ROWS_2 := """##############################
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
#...L...===.........#........#
#.......===.........#........#
#.......===....e....#........#
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
#.S.A...===....F....D......N.#
#.......===.........#........#
#....P..===.........#........#
#.......===.........#........#
#.......===......e..#........#
#.......===.........#........#
#.......===.........#........#
#...L...===.........#....L...#
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
##############################"""
const ROWS_3 := """##############################
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
#...L...===.........#........#
#.......===.........#........#
#.......===....e....#........#
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
#.S.A..T===....F.R..D......N.#
#.......===.........#........#
#....P..===.........#........#
#.......===.........#........#
#.......===......e..#........#
#.......===.........#........#
#.......===.........#........#
#...L...===.........#....L...#
#.......===.........#........#
#.......===.........#........#
#.......===.........#........#
##############################"""
const ROWS_4 := """##############################
#............................#
#............................#
#............................#
#...L........................#
#.........F....F....F........#
#............................#
#............................#
#............................#
#............................#
#.S.A..........B...........C.#
#............................#
#....P.......................#
#............................#
#.......==============.......#
#.......T============R.......#
#.......==============.......#
#...H....................L...#
#............................#
#............................#
#............................#
##############################"""
const NAMES := ["회랑 · 잠금판", "회랑 · 되돌리는 물", "회랑 · 건네는 줄", "회랑 · 물레"]
# each room its own look: slate and cold light, mossy green, brass and warm lamps, the pale wheel hall
const FLOOR_COL := ["#8896a8", "#7a9a86", "#9c9482", "#a4b4bc"]
const WALL_COL := ["#3c4658", "#34503e", "#5a4a34", "#46566a"]
const BED_COL := ["#4a6070", "#3a5a48", "#6a5c40", "#50707c"]
const LIGHT_COL := ["#bcd4ff", "#a8f0c8", "#ffe2b8", "#d8f6ff"]
const AMBIENT_COL := ["#9ab4d8", "#9ad4b8", "#d8c49a", "#b8d8e4"]

var grids: Array = []      # [room][row] strings
var spots: Array = []      # [room] letter -> Array of world Vector2
var high: Array = [false, false, false, true] # [room] the channel is deep water now (the last room's tank always is)
var gate_open: Array = [false, false, false, false] # [room] the gate D stands open
var water_nodes: Array = [] # [room] MeshInstance3D of the deep water
var gate_nodes: Array = []  # [room] the brick gate at D
var lever_arms: Array = []  # [room] the lever handle
var lever_lamps: Array = [] # [room] its lamp material
var post_pads: Array = []   # [room] the glow of Mulgyeol's post
var wheels: Array = []      # [room] Array of {"node", "mat", "on"}
var carts: Array = []       # [room] the cart
var plates: Array = []      # [room] the lock plate's glow material
var stand_lamps: Array = [] # the answer stand's three lamps (materials)
var stand_jar: StandardMaterial3D
var room_lights: Array = []
var sediment: Array = []    # [room] the silt and junk on the channel bed, shown while the channel is dry (v0.1.91)
var plates2: Array = []     # [room] the second handprint's glow (the wheel hall's plate shows two hands)
var pipe_mats: Array = []   # the wheel hall's pipes: three from the wheels to the tank, one on to the answer stand
var side_panel: Node3D      # the side sluice by the entrance lever (the keeper's side door)
var side_mat: StandardMaterial3D
var groove_mat: StandardMaterial3D
var side_open := false
var side_hint: Label3D
var link: MeshInstance3D    # the line from the lever to Mulgyeol
var shortcut: Node3D        # the lake sign by the wheel hall's stair, once the answer is sent

func _init() -> void:
	for r in ROOMS:
		var g: Array = []
		for line in [ROWS_1, ROWS_2, ROWS_3, ROWS_4][r].split("\n"):
			g.append(line)
		grids.append(g)
		spots.append({})
		wheels.append([])
		carts.append(null)
		water_nodes.append(null)
		gate_nodes.append(null)
		lever_arms.append(null)
		lever_lamps.append(null)
		post_pads.append(null)
		plates.append(null)
		plates2.append(null)
		sediment.append([])
		for z in H:
			for x in W:
				var c: String = g[z][x]
				if c != "#" and c != "." and c != "=":
					if not spots[r].has(c):
						spots[r][c] = []
					spots[r][c].append(Vector2(origin(r) + x, z))

func origin(r: int) -> int:
	return CORR_X + GAP * r

func room_of(x: float) -> int:
	return clampi(floori((x - (CORR_X - 0.5)) / GAP), 0, ROOMS - 1)

func at(r: int, c: String, i := 0) -> Vector2:
	return spots[r][c][i] if spots[r].has(c) and spots[r][c].size() > i else Vector2.INF

func char_at(x: float, z: float) -> String:
	var r := room_of(x)
	var tx := int(round(x)) - origin(r)
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= W or tz >= H:
		return "#"
	return grids[r][tz][tx]

# walls, a shut gate, and the channel while it is deep water
func blocked(x: float, z: float) -> bool:
	var c := char_at(x, z)
	if c == "#":
		return true
	if c == "D":
		return not gate_open[room_of(x)]
	if c == "=":
		return high[room_of(x)]
	return false

# deep water the skip crosses
func deep(x: float, z: float) -> bool:
	return char_at(x, z) == "=" and high[room_of(x)]

# a spot on, or within `pad` of, a channel tile
func in_channel(r: int, p: Vector2, pad := 0.0) -> bool:
	for dz in [-pad, 0.0, pad]:
		for dx in [-pad, 0.0, pad]:
			if grids[r][clampi(int(round(p.y + dz)), 0, H - 1)][clampi(int(round(p.x + dx)) - origin(r), 0, W - 1)] == "=":
				return true
	return false

func build(m: Node) -> void:
	for r in ROOMS:
		build_room(m, r)

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
				"=":
					col = Color(BED_COL[r])
					hgt = 0.15 # the channel bed lies lower than the floor; the water box rises over it
			if c == "L":
				lamp_spots.append(w)
			col = col.lightened(m.rnd(0, 0.07))
			if c != "#" and (x + z) % 2 == 0:
				col = col.darkened(0.05) # a faint checker, so the long floors read as stone slabs
			blocks.append([Transform3D(Basis().scaled(Vector3(1, hgt, 1)), Vector3(w.x, hgt / 2.0 - 0.4, w.y)), col])
			if c == "#" and (x * 7 + z * 3 + r) % 11 == 0 and x > 0 and x < W - 1 and z > 0 and z < H - 1:
				blocks.append([Transform3D(Basis().scaled(Vector3(0.9, 0.9, 0.2)), Vector3(w.x, 0.75, w.y + 0.45)), Color("#6a6a74")]) # a bricked old valve in the wall
	m.add_chunks(blocks, CORR_X)
	# the channel's water: one box over the bed, shown while the level is high
	var wmat: StandardMaterial3D = m.mat_color(Color("#2a64a0"), 0.15)
	wmat.metallic_specular = 0.8
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.albedo_color.a = 0.86
	var wbox: MeshInstance3D
	if r < 3:
		wbox = m.box(Vector3(3.0, 0.4, 20.0), wmat)
		wbox.position = Vector3(o + 9.0, -0.22, 10.5)
	else:
		wbox = m.box(Vector3(14.0, 0.4, 3.0), wmat)
		wbox.position = Vector3(o + 14.5, -0.22, 15.0)
	wbox.visible = high[r]
	m.add_child(wbox)
	water_nodes[r] = wbox
	if r < 3: # a few pale stripes on the dry bed, so a low channel reads as a drained run
		for k in 5:
			var s: MeshInstance3D = m.box(Vector3(2.6, 0.02, 0.1), m.mat_color(Color(BED_COL[r]).lightened(0.25)))
			s.position = Vector3(o + 9.0, -0.24, 2.5 + k * 4.0)
			m.add_child(s)
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
	build_dress(m, r)

func build_props(m: Node, r: int) -> void:
	var iron: Material = m.mat_color(Color("#5a5a64"))
	var brass: Material = m.mat_color(Color("#c8962a"))
	var stone: Material = m.mat_color(Color("#c8ccd4"))
	m.grotto.exit_steps(m, at(r, "S")) # the way back: pale steps and a warm lamp, as in the grotto
	if r < 3:
		m.lake_zone.stair_frame(at(r, "N"), -PI / 2.0, 0.0, Color(LIGHT_COL[r])) # on to the next room
		build_gate(m, r)
	# A: the water-level lever
	var a := at(r, "A")
	if a != Vector2.INF:
		var g := Node3D.new()
		var base: MeshInstance3D = m.box(Vector3(0.55, 0.3, 0.55), iron)
		base.position = Vector3(0, 0.15, 0)
		g.add_child(base)
		var post: MeshInstance3D = m.box(Vector3(0.12, 0.8, 0.12), brass)
		post.position = Vector3(0, 0.7, 0)
		g.add_child(post)
		var arm := Node3D.new()
		arm.position = Vector3(0, 1.0, 0)
		var handle: MeshInstance3D = m.box(Vector3(0.6, 0.1, 0.1), brass)
		arm.add_child(handle)
		var knob: MeshInstance3D = m.box(Vector3(0.16, 0.16, 0.16), m.glow_mat(Color("#7fd0ff"), 1.8))
		knob.position = Vector3(0.3, 0, 0)
		arm.add_child(knob)
		g.add_child(arm)
		var lamp_mat: StandardMaterial3D = m.glow_mat(Color("#7fd0ff"), 0.4)
		var lamp: MeshInstance3D = m.box(Vector3(0.18, 0.18, 0.18), lamp_mat)
		lamp.position = Vector3(0, 1.35, 0)
		g.add_child(lamp)
		g.position = Vector3(a.x, 0, a.y)
		m.add_child(g)
		lever_arms[r] = arm
		lever_lamps[r] = lamp_mat
		set_lever(r, high[r] and r < 3)
	# P: Mulgyeol's post, a teal pad with a low stone rim on the floor
	var p := at(r, "P")
	if p != Vector2.INF:
		var pm: StandardMaterial3D = m.glow_mat(Color("#58b8b0"), 0.7)
		var pad: MeshInstance3D = m.box(Vector3(0.95, 0.05, 0.95), pm)
		pad.position = Vector3(p.x, 0.03, p.y)
		m.add_child(pad)
		for side in [-0.5, 0.5]:
			var rim: MeshInstance3D = m.box(Vector3(0.08, 0.12, 1.08), stone)
			rim.position = Vector3(p.x + side, 0.06, p.y)
			m.add_child(rim)
		post_pads[r] = pm
	# T and R: the cart on its rail, and the mooring post at the far end
	var t := at(r, "T")
	var rr := at(r, "R")
	if t != Vector2.INF and rr != Vector2.INF:
		var rail: MeshInstance3D = m.box(Vector3(absf(rr.x - t.x), 0.04, 0.1), iron)
		rail.position = Vector3((t.x + rr.x) / 2.0, 0.02, t.y - 0.3)
		m.add_child(rail)
		var rail2: MeshInstance3D = m.box(Vector3(absf(rr.x - t.x), 0.04, 0.1), iron)
		rail2.position = Vector3((t.x + rr.x) / 2.0, 0.02, t.y + 0.3)
		m.add_child(rail2)
		var cart := Node3D.new()
		var bed: MeshInstance3D = m.box(Vector3(1.2, 0.14, 0.9), brass)
		bed.position = Vector3(0, 0.12, 0)
		cart.add_child(bed)
		for sx in [-0.5, 0.5]:
			var wheel: MeshInstance3D = m.box(Vector3(0.16, 0.2, 0.96), iron)
			wheel.position = Vector3(sx, 0.08, 0)
			cart.add_child(wheel)
		if r == 2: # the bricks the old gate is waiting for
			for k in 3:
				var rb: MeshInstance3D = m.box(Vector3(0.34, 0.16, 0.22), m.mat_color(Color("#c0522a")))
				rb.position = Vector3(-0.25 + (k % 2) * 0.5, 0.27 + (0.17 if k == 2 else 0.0), -0.1 + (k % 2) * 0.12)
				cart.add_child(rb)
		cart.position = Vector3(t.x, 0, t.y)
		m.add_child(cart)
		carts[r] = cart
		var post: MeshInstance3D = m.box(Vector3(0.18, 0.8, 0.18), m.mat_color(Color("#5a3a26")))
		post.position = Vector3(rr.x, 0.4, rr.y)
		m.add_child(post)
		var ring: MeshInstance3D = m.box(Vector3(0.34, 0.08, 0.34), m.mat_color(Color("#d8c08a")))
		ring.position = Vector3(rr.x, 0.7, rr.y)
		m.add_child(ring)
		var rl: MeshInstance3D = m.box(Vector3(0.14, 0.14, 0.14), m.glow_mat(Color("#ffc46a"), 1.6))
		rl.position = Vector3(rr.x, 0.98, rr.y)
		m.add_child(rl)
	# F: the wheels (a latch in the first three rooms, three great wheels in the last)
	var big := r == 3
	for i in (spots[r]["F"].size() if spots[r].has("F") else 0):
		var f: Vector2 = spots[r]["F"][i]
		var fg := Node3D.new()
		var stand: MeshInstance3D = m.box(Vector3(0.22, 0.9 if big else 0.7, 0.22), iron)
		stand.position = Vector3(0, 0.45 if big else 0.35, 0)
		fg.add_child(stand)
		var wheel := Node3D.new()
		wheel.position = Vector3(0, 0.95 if big else 0.8, 0.0)
		var rad := 0.7 if big else 0.45
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = rad
		cyl.bottom_radius = rad
		cyl.height = 0.16
		disc.mesh = cyl
		disc.material_override = iron
		disc.rotation.x = PI / 2.0
		wheel.add_child(disc)
		var wmat: StandardMaterial3D = m.glow_mat(Color("#58b8b0"), 0.2)
		for k in 2:
			var pdl: MeshInstance3D = m.box(Vector3(rad * 2.1, 0.12, 0.2), wmat)
			pdl.rotation.z = k * PI / 2.0
			pdl.position = Vector3(0, 0, 0.1)
			wheel.add_child(pdl)
		fg.add_child(wheel)
		fg.position = Vector3(f.x, 0, f.y - (0.5 if r == 2 else 0.0)) # the third room's wheel stands off the cart's rail
		m.add_child(fg)
		wheels[r].append({"node": wheel, "mat": wmat, "on": false})
	# H: Hangyeol's lock plate with the handprints
	var h := at(r, "H")
	if h != Vector2.INF:
		var slab: MeshInstance3D = m.box(Vector3(0.95, 0.14, 0.75), m.mat_color(Color("#d8d4c8")))
		slab.position = Vector3(h.x, 0.07, h.y)
		m.add_child(slab)
		var pm: StandardMaterial3D = m.glow_mat(Color("#ffd27a"), 0.5)
		if r == 3: # two different hands, side by side: a large gold one and a smaller teal one
			var pm2: StandardMaterial3D = m.glow_mat(Color("#58b8b0"), 0.5)
			var big_hand: MeshInstance3D = m.box(Vector3(0.24, 0.03, 0.32), pm)
			big_hand.position = Vector3(h.x - 0.3, 0.16, h.y)
			m.add_child(big_hand)
			var small_hand: MeshInstance3D = m.box(Vector3(0.17, 0.03, 0.23), pm2)
			small_hand.position = Vector3(h.x + 0.28, 0.16, h.y + 0.04)
			small_hand.rotation.y = 0.3
			m.add_child(small_hand)
			plates2[r] = pm2
		else: # one person's hand, printed over itself again and again
			for sx in [-0.2, 0.15]:
				var hand: MeshInstance3D = m.box(Vector3(0.2, 0.03, 0.28), pm)
				hand.position = Vector3(h.x + sx, 0.16, h.y)
				m.add_child(hand)
		plates[r] = pm
	# C: the answer stand with its three lamps
	var c := at(r, "C")
	if c != Vector2.INF:
		var ped: MeshInstance3D = m.box(Vector3(0.8, 0.6, 0.8), m.mat_color(Color("#c8ccd4")))
		ped.position = Vector3(c.x, 0.3, c.y)
		m.add_child(ped)
		stand_jar = m.glow_mat(Color("#9fd8ff"), 0.3)
		var jar: MeshInstance3D = m.box(Vector3(0.34, 0.4, 0.34), stand_jar)
		jar.position = Vector3(c.x, 0.82, c.y)
		m.add_child(jar)
		for k in 3:
			var lm: StandardMaterial3D = m.glow_mat(Color("#ffd27a"), 0.15)
			var lp: MeshInstance3D = m.box(Vector3(0.2, 0.2, 0.2), lm)
			lp.position = Vector3(c.x - 0.9 + k * 0.9, 2.4, c.y - 1.2)
			m.add_child(lp)
			var post: MeshInstance3D = m.box(Vector3(0.08, 1.6, 0.08), iron)
			post.position = Vector3(c.x - 0.9 + k * 0.9, 1.2, c.y - 1.2)
			m.add_child(post)
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

func set_water(r: int, on: bool) -> void:
	high[r] = on
	if water_nodes[r] != null:
		water_nodes[r].visible = on
	set_lever(r, on and r < 3)
	for n in sediment[r]:
		n.visible = not on

func set_lever(r: int, up: bool) -> void:
	if lever_arms[r] != null:
		lever_arms[r].rotation.z = 0.6 if up else -0.6
		lever_lamps[r].emission_energy_multiplier = 2.0 if up else 0.3

func set_wheel(r: int, i: int, on: bool) -> void:
	if i < wheels[r].size():
		wheels[r][i].on = on
		wheels[r][i].mat.emission_energy_multiplier = 2.2 if on else 0.2
	if r == 3 and i < pipe_mats.size(): # its pipe lights with the wheel; the last one lights the run to the answer stand too
		pipe_mats[i].emission_energy_multiplier = 1.8 if on else 0.15
		if i == 2 and pipe_mats.size() > 3:
			pipe_mats[3].emission_energy_multiplier = 1.8 if on else 0.15

func set_post(r: int, on: bool) -> void:
	if post_pads[r] != null:
		post_pads[r].emission_energy_multiplier = 2.4 if on else 0.7

func set_plate(r: int, read: bool) -> void:
	if plates[r] != null:
		plates[r].emission_energy_multiplier = 2.2 if read else 0.5
	if plates2[r] != null:
		plates2[r].emission_energy_multiplier = 2.2 if read else 0.5

func tick(dt: float) -> void:
	for r in ROOMS:
		for w in wheels[r]:
			if w.on:
				w.node.rotation.z += dt * TAU * 0.35

# ---- set dressing (v0.1.91): each room reads as a water works with a story, built from boxes
func blk(m: Node, pos: Vector3, size: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var mi: MeshInstance3D = m.box(size, mat)
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	else:
		m.add_child(mi)
	return mi

# a thin box from a to b (one axis long)
func seg(m: Node, a: Vector3, b: Vector3, th: float, mat: Material) -> MeshInstance3D:
	return blk(m, (a + b) / 2.0, Vector3(absf(b.x - a.x) + th, absf(b.y - a.y) + th, absf(b.z - a.z) + th), mat)

# a pipe through the points, a brass collar at each corner
func pipe_run(m: Node, pts: Array, th: float, mat: Material, collar: Material) -> void:
	for i in pts.size() - 1:
		seg(m, pts[i], pts[i + 1], th, mat)
	for i in range(1, pts.size() - 1):
		blk(m, pts[i], Vector3(th * 1.7, th * 1.7, th * 1.7), collar)

# a bench: top on four legs
func bench(m: Node, at: Vector3, wood: Material, dark: Material) -> void:
	blk(m, at + Vector3(0, 0.55, 0), Vector3(1.4, 0.1, 0.7), wood)
	for sx in [-0.6, 0.6]:
		for sz in [-0.28, 0.28]:
			blk(m, at + Vector3(sx, 0.25, sz), Vector3(0.1, 0.5, 0.1), dark)

func crate(m: Node, at: Vector3, s: float, wood: Material, band: Material) -> void:
	blk(m, at + Vector3(0, s / 2.0, 0), Vector3(s, s, s), wood)
	blk(m, at + Vector3(0, s + 0.02, 0), Vector3(s + 0.06, 0.06, s + 0.06), band)

# tide lines on a wall face, low to high: green slime, a paler band, a mineral crust
func tide_lines(m: Node, x0: float, z0: float, x1: float, z1: float, face: Vector2) -> void:
	var cols := ["#4f7a52", "#7fa07a", "#d8e0d0"]
	var ys := [0.07, 0.24, 0.41]
	var hs := [0.12, 0.07, 0.05]
	for k in 3:
		var sx: float = absf(x1 - x0) if face.y != 0.0 else 0.05
		var sz: float = absf(z1 - z0) if face.x != 0.0 else 0.05
		blk(m, Vector3((x0 + x1) / 2.0 + face.x * 0.02, ys[k], (z0 + z1) / 2.0 + face.y * 0.02), Vector3(sx, hs[k], sz), m.mat_color(Color(cols[k])))

func build_dress(m: Node, r: int) -> void:
	var o := origin(r)
	var pipe: Material = m.mat_color(Color("#76828e"))
	var collar: Material = m.mat_color(Color("#c8962a"))
	var wood: Material = m.mat_color(Color("#8a6a42"))
	var dark: Material = m.mat_color(Color("#4a3322"))
	var stone: Material = m.mat_color(Color("#c8ccd4"))
	var iron: Material = m.mat_color(Color("#3a4048"))
	var rope: Material = m.mat_color(Color("#b89868"))
	match r:
		0: # one person's work: a single bench, a worn step, a pipe from the lever over the channel to the latch, the channel's head boarded shut
			pipe_run(m, [Vector3(o + 4, 0.2, 10.0), Vector3(o + 4, 0.2, 9.2), Vector3(o + 7.2, 0.2, 9.2), Vector3(o + 7.2, 1.5, 9.2),
				Vector3(o + 10.8, 1.5, 9.2), Vector3(o + 10.8, 0.2, 9.2), Vector3(o + 15, 0.2, 9.2), Vector3(o + 15, 0.2, 10.0)], 0.16, pipe, collar)
			blk(m, Vector3(o + 4, 0.06, 15.6), Vector3(1.5, 0.12, 0.9), stone) # the step before the plate, worn on the left foot's side only
			blk(m, Vector3(o + 3.65, 0.125, 15.6), Vector3(0.6, 0.03, 0.55), m.mat_color(Color("#6a7480")))
			bench(m, Vector3(o + 1.9, 0, 17.6), wood, dark)
			blk(m, Vector3(o + 1.9, 0.62, 17.6), Vector3(0.1, 0.05, 0.5), collar) # a wrench left on it
			blk(m, Vector3(o + 1.55, 0.2, 18.5), Vector3(0.4, 0.4, 0.4), dark) # one stool
			blk(m, Vector3(o + 5.6, 0.16, 17.6), Vector3(0.55, 0.32, 0.38), wood) # a repair box
			blk(m, Vector3(o + 5.6, 0.34, 17.6), Vector3(0.6, 0.06, 0.42), collar)
			blk(m, Vector3(o + 9, 0.55, 0.75), Vector3(3.3, 1.1, 0.3), dark) # the channel's head, boarded and padlocked
			blk(m, Vector3(o + 9, 0.35, 0.93), Vector3(3.4, 0.14, 0.08), wood)
			blk(m, Vector3(o + 9, 0.8, 0.93), Vector3(3.4, 0.14, 0.08), wood)
			blk(m, Vector3(o + 9, 0.58, 0.98), Vector3(0.22, 0.26, 0.1), collar)
		1: # the drain: tide lines on the walls, a grate under the latch, silt that shows when the channel runs dry
			tide_lines(m, o + 7.3, 0.5, o + 10.7, 0.5, Vector2(0, 1))
			tide_lines(m, o + 0.5, 2.0, o + 0.5, 19.0, Vector2(1, 0))
			tide_lines(m, o + 19.5, 1.0, o + 19.5, 9.0, Vector2(-1, 0))
			tide_lines(m, o + 19.5, 11.0, o + 19.5, 19.0, Vector2(-1, 0))
			blk(m, Vector3(o + 15, 0.02, 10.0), Vector3(1.7, 0.04, 1.7), iron)
			for k in 5:
				blk(m, Vector3(o + 14.4 + k * 0.3, 0.05, 10.0), Vector3(0.1, 0.04, 1.6), m.mat_color(Color("#8c98a4")))
			pipe_run(m, [Vector3(o + 15, 0.2, 9.0), Vector3(o + 15, 0.2, 7.6), Vector3(o + 11.2, 0.2, 7.6)], 0.14, pipe, collar) # the drain pipe's run to the channel
			var silt: Material = m.mat_color(Color("#8a7752"))
			var junk: Material = m.mat_color(Color("#4a4a3a"))
			var lumps := [[8.7, 3.0, 0.9, 0.7], [9.6, 6.2, 1.0, 0.8], [8.9, 9.4, 0.8, 1.1], [9.4, 12.5, 1.1, 0.8], [9.0, 16.0, 0.9, 0.9]]
			for lp in lumps:
				sediment[r].append(blk(m, Vector3(o + lp[0], -0.19, lp[1]), Vector3(lp[2], 0.1, lp[3]), silt))
			for jp in [Vector2(9.3, 4.4), Vector2(8.8, 14.2)]: # a rusted pot and a bent ring among the silt
				sediment[r].append(blk(m, Vector3(o + jp.x, -0.14, jp.y), Vector3(0.3, 0.2, 0.3), junk))
			sediment[r].append(blk(m, Vector3(o + 9.0, -0.15, 10.9), Vector3(0.4, 0.08, 0.4), collar))
			for n in sediment[r]:
				n.visible = not high[r]
		2: # the carrying: spare parts piled on the west bank, bricks on the cart, a snapped valve and a cut rope on the east
			crate(m, Vector3(o + 2.0, 0.0, 14.2), 0.7, wood, dark)
			crate(m, Vector3(o + 3.0, 0.0, 14.2), 0.7, wood, dark)
			crate(m, Vector3(o + 2.5, 0.0, 15.2), 0.7, wood, dark)
			crate(m, Vector3(o + 2.5, 0.78, 14.7), 0.55, wood, dark) # one on top
			blk(m, Vector3(o + 4.2, 0.08, 15.0), Vector3(0.7, 0.16, 0.7), m.mat_color(Color("#a08050"))) # a rope coil
			blk(m, Vector3(o + 4.2, 0.2, 15.0), Vector3(0.5, 0.1, 0.5), rope)
			for k in 3: # spare wheels leaning on the pile
				blk(m, Vector3(o + 1.4, 0.3 + k * 0.1, 15.6 + k * 0.15), Vector3(0.14, 0.5, 0.5), iron)
			blk(m, Vector3(o + 18.4, 0.45, 7.2), Vector3(0.2, 0.9, 0.2), pipe) # the broken valve: a stub, half a wheel, a cut rope
			blk(m, Vector3(o + 18.4, 0.92, 7.2), Vector3(0.5, 0.06, 0.16), iron)
			var half := blk(m, Vector3(o + 19.0, 0.04, 8.2), Vector3(0.3, 0.05, 0.16), iron)
			half.rotation.y = 0.6
			blk(m, Vector3(o + 18.0, 0.04, 8.9), Vector3(0.06, 0.05, 1.2), rope)
			blk(m, Vector3(o + 18.4, 0.4, 7.45), Vector3(0.05, 0.5, 0.05), rope) # the rope end hanging from the stub
			pipe_run(m, [Vector3(o + 15, 0.2, 9.0), Vector3(o + 15, 0.2, 7.2), Vector3(o + 17.4, 0.2, 7.2)], 0.14, pipe, collar) # the pipe that stops short of it
			tide_lines(m, o + 7.3, 0.5, o + 10.7, 0.5, Vector2(0, 1))
		3: # the wheel hall: three pipes from the wheels through the tank to the answer stand, two benches at the plate, a sign to the garden
			for i in 4:
				pipe_mats.append(m.glow_mat(Color("#58b8b0"), 0.15))
			for i in 3:
				var fx: float = at(3, "F", i).x
				seg(m, Vector3(fx, 0.14, 5.9), Vector3(fx, 0.14, 13.4), 0.2, pipe_mats[i])
				blk(m, Vector3(fx, 0.2, 13.2), Vector3(0.4, 0.4, 0.4), collar) # where it dives into the tank
			pipe_run(m, [Vector3(o + 21.8, 0.14, 15.0), Vector3(o + 27.0, 0.14, 15.0), Vector3(o + 27.0, 0.14, 10.8)], 0.2, pipe_mats[3], collar)
			bench(m, Vector3(o + 1.9, 0, 17.6), wood, dark) # two people's work: a bench each side of the plate
			bench(m, Vector3(o + 6.3, 0, 17.6), wood, dark)
			blk(m, Vector3(o + 1.9, 0.62, 17.6), Vector3(0.1, 0.05, 0.5), collar)
			blk(m, Vector3(o + 6.3, 0.62, 17.6), Vector3(0.1, 0.05, 0.5), m.glow_mat(Color("#58b8b0"), 0.8))
			blk(m, Vector3(o + 1.55, 0.2, 18.5), Vector3(0.4, 0.4, 0.4), dark)
			blk(m, Vector3(o + 6.65, 0.2, 18.5), Vector3(0.4, 0.4, 0.4), dark)
			blk(m, Vector3(o + 26.2, 0.7, 8.3), Vector3(0.1, 1.4, 0.1), dark) # a sign by the stand: the way to the garden
			blk(m, Vector3(o + 26.2, 1.45, 8.3), Vector3(0.7, 0.55, 0.06), wood)
			var gs: Sprite3D = m.sign_icon("garden", 0.4)
			gs.position = Vector3(o + 26.2, 1.45, 8.35)
			m.add_child(gs)
			# the side sluice by the entrance lever: shut, then raised and running when the keeper's side door opens
			var sa := at(3, "A")
			side_mat = m.glow_mat(Color("#5ab4ff"), 0.2)
			blk(m, Vector3(sa.x - 0.7, 0.65, 8.2), Vector3(0.18, 1.3, 0.2), stone)
			blk(m, Vector3(sa.x + 0.7, 0.65, 8.2), Vector3(0.18, 1.3, 0.2), stone)
			blk(m, Vector3(sa.x, 1.35, 8.2), Vector3(1.6, 0.16, 0.24), stone)
			side_panel = blk(m, Vector3(sa.x, 0.55, 8.2), Vector3(1.2, 0.9, 0.1), side_mat)
			groove_mat = m.glow_mat(Color("#5ab4ff"), 0.1)
			var trough: Material = m.mat_color(Color("#2a3440"))
			blk(m, Vector3(o + 6.6, 0.03, 8.2), Vector3(3.2, 0.04, 0.55), trough)
			blk(m, Vector3(o + 8.0, 0.03, 10.9), Vector3(0.55, 0.04, 5.6), trough)
			blk(m, Vector3(o + 6.6, 0.06, 8.2), Vector3(3.2, 0.03, 0.3), groove_mat)
			blk(m, Vector3(o + 8.0, 0.06, 10.9), Vector3(0.3, 0.03, 5.6), groove_mat)
			side_hint = Label3D.new() # "the entrance lever, E" over the lever while the side door is open
			side_hint.text = m.tr("입구 손잡이 E")
			side_hint.font = m.ui_font
			side_hint.font_size = 48
			side_hint.pixel_size = 0.012
			side_hint.outline_size = 14
			side_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			side_hint.no_depth_test = true
			side_hint.modulate = Color("#9fd4ff")
			side_hint.position = Vector3(sa.x, 2.3, sa.y)
			side_hint.visible = false
			m.add_child(side_hint)
			link = m.box(Vector3(0.07, 0.05, 1.0), m.glow_mat(Color("#7fd0ff"), 1.6)) # the line from the lever to where Mulgyeol stands
			link.visible = false
			m.add_child(link)
			# the entrance stair, once the answer is sent: a lake sign (the stair leads straight back to the island)
			var s := at(3, "S")
			shortcut = Node3D.new()
			shortcut.position = Vector3(s.x + 0.6, 0, s.y - 1.6)
			var sp: MeshInstance3D = m.box(Vector3(0.1, 1.4, 0.1), dark)
			sp.position = Vector3(0, 0.7, 0)
			shortcut.add_child(sp)
			var sb: MeshInstance3D = m.box(Vector3(0.7, 0.55, 0.06), wood)
			sb.position = Vector3(0, 1.45, 0)
			shortcut.add_child(sb)
			var ls: Sprite3D = m.sign_icon("lake", 0.4)
			ls.position = Vector3(0, 1.45, 0.05)
			shortcut.add_child(ls)
			shortcut.visible = false
			m.add_child(shortcut)

func set_side(open: bool) -> void:
	if side_panel == null or open == side_open:
		return
	side_open = open
	side_panel.position.y = 1.2 if open else 0.55
	side_mat.emission_energy_multiplier = 2.4 if open else 0.2
	groove_mat.emission_energy_multiplier = 2.2 if open else 0.1
	if side_hint != null:
		side_hint.visible = open

# the line from the entrance lever to the spot where Mulgyeol stands (shown while Sora keeps the sluice)
func set_link(show: bool, a: Vector2, b: Vector2) -> void:
	if link == null:
		return
	link.visible = show
	if show:
		var d := b - a
		link.position = Vector3((a.x + b.x) / 2.0, 0.12, (a.y + b.y) / 2.0)
		link.rotation.y = atan2(d.x, d.y)
		link.scale = Vector3(1.0, 1.0, maxf(d.length(), 0.1))

func set_shortcut(on: bool) -> void:
	if shortcut != null:
		shortcut.visible = on

func map_tex(width: int) -> ImageTexture:
	var img := Image.create(width, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for r in ROOMS:
		for z in H:
			for x in W:
				var c: String = grids[r][z][x]
				var col := Color("#1e2a34")
				match c:
					"#": col = Color(0, 0, 0, 0)
					"=": col = Color("#2c5a8a") if high[r] else Color("#3a4a54")
					"L": col = Color("#9fd8ff")
					"D": col = Color("#c8502a") if not gate_open[r] else Color("#1e2a34")
					"A", "P", "T", "R", "F", "H", "C": col = Color("#7fd0c0")
					"S", "N": col = Color("#ffd27a")
				img.set_pixel(origin(r) + x, z, col)
	return ImageTexture.create_from_image(img)
