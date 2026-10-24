# 달지기 작업장 (side story "끝내지 못한 등불", DESIGN.md 깊은 작업장): three floors under the castle's great hall,
# each its own map at its own x (B1 x >= 620, B2 x >= 660, B3 x >= 700). One instance per floor: WORK.new(0..2).
# Shared letters:
#   S stair up, A arrival from above, U arrival from below (beside V), V stair down, Y the floor's return waystone,
#   L rest lantern, B work bench, t / k a note to read, W brick (plug, stopper or clamp; one group per touching run),
#   g goblin, a archer, s shield goblin, b bat, q hedgehog.
# B1 짝등 작업장: o the two work lamps; _ the pit; p planks that show only when both lamps burn.
# B2 엇갈린 물길: ~ troughs; r the flooded channel (dry once the stopper is unbricked); P the chain post; G the iron lid
#   over the stopper (Mulgyeol's pull lifts it); c the delivery cradle.
# B3 남겨 둔 손잡이: f the hall where fragments fall, n safe alcoves; D the door to the work pit (both clamps open it);
#   O the repair cradle, l its three latches.
# Sora counts as "on the hill" down here.
extends RefCounted

const WORK_X := 620
const FLOOR_X := [620, 660, 700]
const FLOOR_W := [28, 30, 26]
const FLOOR_H := [22, 24, 24]
const NAMES := ["지하 1층 · 짝등 작업장", "지하 2층 · 엇갈린 물길", "지하 3층 · 남겨 둔 손잡이"]
const ROWS_1 := """############################
#S.A...#..........#.......L#
#......#..B...B...#..B...B.#
#..L.......g..........a....#
#......#..B...B...#..B...B.#
#......#..........#........#
###.#######....#######..####
#..........................#
#.o.........g...........o..#
#___________p______________#
#___________p______________#
#___________pppp___________#
#______________p___________#
#______________p___________#
#L.................t......L#
##############WW############
#..........................#
#..B..B.........Y..........#
#...........g..........UV..#
#..L.....................L.#
#..........................#
############################"""
const ROWS_2 := """##############################
#S.A...........b...........L.#
#......#.~~~~~~~~~~~~~~~.#...#
#..L...#.~~~~~~~~~~~~~~~.#.t.#
#......#.~~~~~~~~~~~~~~~.#...#
#......#.~~~~~~~~~~~~~~~.#...#
#.........q.......b..........#
########################..####
#............................#
#.L..P.................q...L.#
#.....GG.....................#
#rrrrrWWrrrrrrrrrrrrrrrrrrrrr#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrr#
#rrrrrrrrrrrrrrrrrrrrrrrrrrrr#
#............................#
#..L.........c.........Y.....#
#...............b............#
#.....B..B..................L#
#.....................UV.....#
#..........q.................#
#..L.........................#
#............................#
#............................#
##############################"""
const ROWS_3 := """##########################
#S.A...####n####n####n####
#......fffffffffffffffff.#
#..L...fffffffffffffffff.#
#......fffffffffffffffff.#
#......####n####n####n...#
#####################k#..#
#W...................s...#
#W.......................#
#.....L........L........W#
#.........g.....a...Y...W#
#......a.........s.......#
###########DD#############
#........................#
#..L.................L...#
#........................#
#........l.......l.......#
#............O...........#
#........................#
#........................#
#........................#
#............l...........#
#..L.................L...#
##########################"""
const ROWS := [ROWS_1, ROWS_2, ROWS_3]
# floor, wall and accent colours per floor: amber workshop, wet blue stone, dry pale clay
const FLOOR_COL := ["#7a6858", "#5e7088", "#b8a88e"]
const WALL_COL := ["#4e4038", "#3c4a5e", "#8a7a64"]
const ARM_R := 6.2 # the cradle's arms reach this far from O

var f := 0
var ox := 0
var w := 0
var h := 0
var grid: Array = []
var marks := {}          # S A U V Y P O t k -> world Vector2
var foes: Array = []     # [world Vector2, kind]
var lamps: Array = []    # B1: [{"pos", "lit", "glass", "light", "lit_mat"}]
var groups: Array = []   # W runs: [{"tiles": [Vector2i], "nodes": [Node3D], "open": bool, "at": Vector2}]
var open_tiles := {}     # Vector2i -> true for unbricked W tiles
var planks_shown := false
var lid_open := false
var drained := false
var door_open := false
var latches: Array = []  # B3: [{"pos", "wound", "glow": StandardMaterial3D, "angle"}] in the order south, west, east
var arms: Array = []     # B3: Node3D pivots at O, one per latch
var plank_nodes: Array = []
var lid_nodes: Array = []
var chain_nodes: Array = []
var door_nodes: Array = []
var flood: MeshInstance3D
var cradle_lantern: Node3D
var stone_glow: StandardMaterial3D
var stone_light: OmniLight3D
var cradle2: Node3D

static func floor_of(x: float) -> int:
	if x < FLOOR_X[1] - 0.5:
		return 0
	if x < FLOOR_X[2] - 0.5:
		return 1
	return 2

func _init(fi: int) -> void:
	f = fi
	ox = FLOOR_X[fi]
	w = FLOOR_W[fi]
	h = FLOOR_H[fi]
	for line in String(ROWS[fi]).split("\n"):
		grid.append(line)
	for z in h:
		for x in w:
			var c: String = grid[z][x]
			var at := Vector2(ox + x, z)
			if c in "SAUVYPOtk":
				marks[c] = at
			if c in "gasbq":
				foes.append([at, c])

func char_at(x: float, z: float) -> String:
	var tx := int(round(x)) - ox
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= w or tz >= h:
		return "#"
	return grid[tz][tx]

func blocked(x: float, z: float) -> bool:
	var c := char_at(x, z)
	match c:
		"#", "_", "~", "o", "B", "P", "t", "k", "O", "l":
			return true
		"p":
			return not planks_shown
		"G":
			return not lid_open
		"r":
			return not drained
		"D":
			return not door_open
		"W":
			return not open_tiles.has(Vector2i(int(round(x)) - ox, int(round(z))))
	return false

func lamps_lit() -> int:
	return lamps.filter(func(l): return l.lit).size()

func latches_wound() -> int:
	return latches.filter(func(l): return l.wound).size()

func groups_open() -> int:
	return groups.filter(func(g): return g.open).size()

func build(m: Node) -> void:
	var blocks: Array = []
	var floor_c := Color(FLOOR_COL[f])
	var wall_c := Color(WALL_COL[f])
	var wood: Material = m.mat_color(Color("#6a4a30"))
	var chalk: Material = m.mat_color(Color("#ece6d8"))
	for z in h:
		for x in w:
			var c: String = grid[z][x]
			var at := Vector2(ox + x, z)
			match c:
				"#":
					var near := false
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx: int = x + d.x
						var nz: int = z + d.y
						if nx >= 0 and nz >= 0 and nx < w and nz < h and grid[nz][nx] != "#":
							near = true
					if near:
						blocks.append([Transform3D(Basis().scaled(Vector3(1, 1.3, 1)), Vector3(at.x, 0.25, at.y)), wall_c.lightened(m.rnd(0, 0.07))])
				"_":
					pass
				"~":
					blocks.append([Transform3D(Basis().scaled(Vector3(1, 0.05, 1)), Vector3(at.x, -0.36, at.y)), Color("#1f4a78").lightened(m.rnd(0, 0.06))])
				_:
					var col := floor_c
					if (x + z) % 2 == 0:
						col = col.darkened(0.06)
					if c == "f": # cracked, a shade darker where the ceiling sheds
						col = col.darkened(0.12)
					elif c == "n":
						col = col.lightened(0.1)
					blocks.append([Transform3D(Basis().scaled(Vector3(1, 0.4, 1)), Vector3(at.x, -0.2, at.y)), col.lightened(m.rnd(0, 0.04))])
			if c == "B": # a long work bench with two chalk handprints on its top
				var top: MeshInstance3D = m.box(Vector3(0.95, 0.12, 0.8), wood)
				top.position = Vector3(at.x, 0.72, at.y)
				m.add_child(top)
				for k in 2:
					var leg: MeshInstance3D = m.box(Vector3(0.12, 0.66, 0.6), wood)
					leg.position = Vector3(at.x - 0.36 + k * 0.72, 0.33, at.y)
					m.add_child(leg)
					var hand: MeshInstance3D = m.box(Vector3(0.18, 0.02, 0.24), chalk)
					hand.position = Vector3(at.x - 0.2 + k * 0.4, 0.79, at.y)
					m.add_child(hand)
	m.add_chunks(blocks, ox)
	var post_mat: Material = m.mat_color(Color("#3b2a1e"))
	var glass: Material = m.glow_mat(Color("#ffc46a"), 2.6)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	for z in h:
		for x in w:
			var c: String = grid[z][x]
			var at := Vector2(ox + x, z)
			match c:
				"L":
					m.lantern(at.x - 0.3, at.y, post_mat, glass)
				"o": # an amber work lamp, dark until the crown lights it
					var l: Dictionary = m.stairs.moon_lamp(m, at)
					(l.light as OmniLight3D).light_color = Color("#ffb45a")
					l.lit_mat = m.glow_mat(Color("#ffc46a"), 2.4)
					lamps.append(l)
				"p":
					var pl: MeshInstance3D = m.box(Vector3(0.9, 0.08, 0.96), m.mat_color(Color("#8a6038").lightened(m.rnd(0, 0.08))))
					pl.position = Vector3(at.x, -0.04, at.y)
					pl.visible = false
					m.add_child(pl)
					plank_nodes.append(pl)
				"G": # the iron lid over the stopper
					var lid: MeshInstance3D = m.box(Vector3(0.98, 0.16, 0.98), m.mat_color(Color("#4a4e58")))
					lid.position = Vector3(at.x, 0.08, at.y)
					m.add_child(lid)
					lid_nodes.append(lid)
				"P": # the chain post: a dark post, a wheel and a chain down to the lid
					var post: MeshInstance3D = m.box(Vector3(0.3, 1.5, 0.3), m.mat_color(Color("#3a3440")))
					post.position = Vector3(at.x, 0.75, at.y)
					m.add_child(post)
					var wheel: MeshInstance3D = m.box(Vector3(0.6, 0.6, 0.1), m.mat_color(Color("#8a7a5a")))
					wheel.position = Vector3(at.x, 1.3, at.y + 0.2)
					m.add_child(wheel)
					for k in 4:
						var link: MeshInstance3D = m.box(Vector3(0.1, 0.1, 0.1), m.mat_color(Color("#9a9aa2")))
						link.position = Vector3(at.x + 0.3 + k * 0.2, 1.1 - k * 0.25, at.y + 0.3)
						m.add_child(link)
						chain_nodes.append(link)
				"D":
					var slab: MeshInstance3D = m.box(Vector3(1.0, 1.6, 0.4), m.mat_color(Color("#a0885a")))
					slab.position = Vector3(at.x, 0.8, at.y)
					m.add_child(slab)
					door_nodes.append(slab)
				"t", "k": # a note: a crate with a pale label (t), a scratched plaque on the wall (k)
					var crate: MeshInstance3D = m.box(Vector3(0.7, 0.6, 0.6), wood)
					crate.position = Vector3(at.x, 0.3, at.y)
					m.add_child(crate)
					var label: MeshInstance3D = m.box(Vector3(0.36, 0.26, 0.04), m.glow_mat(Color("#f2ead8"), 1.0))
					label.position = Vector3(at.x, 0.45, at.y + 0.32)
					m.add_child(label)
				"V": # the way down: a dark square with three pale steps
					var hole: MeshInstance3D = m.box(Vector3(1.0, 0.04, 1.0), m.mat_color(Color("#16121e")))
					hole.position = Vector3(at.x, 0.01, at.y)
					m.add_child(hole)
					for k in 3:
						var st: MeshInstance3D = m.box(Vector3(0.8, 0.05, 0.22), m.mat_color(Color("#b8b4c4").darkened(k * 0.25)))
						st.position = Vector3(at.x, 0.04 - k * 0.01, at.y - 0.3 + k * 0.26)
						m.add_child(st)
				"Y": # the return waystone: grey, its moon dark until the floor is cleared
					var g := Node3D.new()
					var b: MeshInstance3D = m.box(Vector3(0.5, 1.2, 0.4), m.mat_color(Color("#8a8a94")))
					b.position = Vector3(0, 0.6, 0)
					g.add_child(b)
					stone_glow = m.mat_color(Color("#3a3a48"))
					var mm: MeshInstance3D = m.box(Vector3(0.3, 0.3, 0.06), stone_glow)
					mm.position = Vector3(0, 0.9, 0.22)
					g.add_child(mm)
					stone_light = OmniLight3D.new()
					stone_light.light_color = Color("#bcd6ff")
					stone_light.light_energy = 1.2
					stone_light.omni_range = 3.0
					stone_light.position = Vector3(0, 1.2, 0.4)
					stone_light.visible = false
					g.add_child(stone_light)
					g.position = Vector3(at.x, 0, at.y)
					m.add_child(g)
					m.rocks.append({"x": at.x, "z": at.y, "r": 0.35})
	m.grotto.exit_steps(m, marks.S)
	build_groups(m)
	match f:
		0:
			# the pit: a dark floor far below; a broken delivery cradle lying by the shaft
			var deep: MeshInstance3D = m.box(Vector3(26.0, 0.1, 5.0), m.mat_color(Color("#120f18")))
			deep.position = Vector3(ox + 13.5, -2.6, 11.0)
			m.add_child(deep)
			broken_cradle(m, marks.V + Vector2(1.6, -1.2), 0.5)
		1:
			var wet: Material = m.glow_mat(Color("#2f78b8"), 0.6)
			wet.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			wet.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			flood = m.box(Vector3(28.0, 0.05, 3.0), wet)
			flood.position = Vector3(ox + 14.5, 0.05, 12.0)
			m.add_child(flood)
			for x in w:
				for z in h:
					if grid[z][x] == "c":
						cradle2 = broken_cradle(m, Vector2(ox + x, 12.0), 0.0)
		2:
			build_pit(m)

# a delivery cradle: a brass basket with two handles; tilt in radians (B1's lies broken on its side)
func broken_cradle(m: Node, at: Vector2, tilt: float) -> Node3D:
	var g := Node3D.new()
	var brass: Material = m.mat_color(Color("#b08a3a"))
	var dark: Material = m.mat_color(Color("#4a3a28"))
	var base: MeshInstance3D = m.box(Vector3(0.9, 0.35, 0.7), dark)
	base.position = Vector3(0, 0.2, 0)
	g.add_child(base)
	for side in [-1.0, 1.0]:
		var rail: MeshInstance3D = m.box(Vector3(0.08, 0.5, 0.08), brass)
		rail.position = Vector3(side * 0.42, 0.55, 0)
		g.add_child(rail)
	var bar: MeshInstance3D = m.box(Vector3(0.92, 0.08, 0.08), brass)
	bar.position = Vector3(0, 0.82, 0)
	g.add_child(bar)
	g.rotation.z = tilt
	g.position = Vector3(at.x, 0, at.y)
	m.add_child(g)
	return g

# B3's work pit: the brass repair ring, the cradle holding the lantern, three arms and three latches
func build_pit(m: Node) -> void:
	var o: Vector2 = marks.O
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = m.ring_mesh(ARM_R - 0.18, ARM_R, 0.0, TAU, 48)
	var brass: StandardMaterial3D = m.mat_color(Color("#c8962a"))
	brass.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = brass
	ring.position = Vector3(o.x, 0.02, o.y)
	m.add_child(ring)
	var hub: MeshInstance3D = m.box(Vector3(1.1, 0.5, 1.1), m.mat_color(Color("#6a5a44")))
	hub.position = Vector3(o.x, 0.25, o.y)
	m.add_child(hub)
	for side in [-1.0, 1.0]:
		var claw: MeshInstance3D = m.box(Vector3(0.12, 1.4, 0.12), m.mat_color(Color("#a8322a")))
		claw.position = Vector3(o.x + side * 0.35, 1.0, o.y)
		m.add_child(claw)
	cradle_lantern = Node3D.new()
	var lglass: MeshInstance3D = m.box(Vector3(0.36, 0.42, 0.36), m.glow_mat(Color("#ffd27a"), 1.6))
	lglass.position = Vector3(0, 0, 0)
	cradle_lantern.add_child(lglass)
	for side in [-1.0, 1.0]: # the two handles
		var hd: MeshInstance3D = m.box(Vector3(0.06, 0.06, 0.3), m.mat_color(Color("#8a6038")))
		hd.position = Vector3(side * 0.24, 0.24, 0)
		cradle_lantern.add_child(hd)
	cradle_lantern.position = Vector3(o.x, 1.2, o.y)
	m.add_child(cradle_lantern)
	var spots: Array = []
	for z in h:
		for x in w:
			if grid[z][x] == "l":
				spots.append(Vector2(ox + x, z))
	spots.sort_custom(func(a, b): return a.y > b.y if absf(a.y - b.y) > 0.5 else a.x < b.x) # south first, then west, east
	for sp: Vector2 in spots:
		var post: MeshInstance3D = m.box(Vector3(0.3, 1.0, 0.3), m.mat_color(Color("#5a4632")))
		post.position = Vector3(sp.x, 0.5, sp.y)
		m.add_child(post)
		var glow: StandardMaterial3D = m.mat_color(Color("#6e5a3a"))
		var wheel: MeshInstance3D = m.box(Vector3(0.5, 0.5, 0.12), glow)
		wheel.position = Vector3(sp.x, 1.05, sp.y + 0.2)
		m.add_child(wheel)
		var a := atan2(sp.y - o.y, sp.x - o.x)
		latches.append({"pos": sp, "wound": false, "glow": glow, "angle": a})
		var pivot := Node3D.new()
		var arm: MeshInstance3D = m.box(Vector3(ARM_R - 0.8, 0.35, 0.4), m.mat_color(Color("#a8322a")))
		arm.position = Vector3((ARM_R - 0.8) / 2.0 + 0.5, 1.45, 0) # at chest height, over the latch posts
		pivot.add_child(arm)
		pivot.position = Vector3(o.x, 0, o.y)
		pivot.rotation.y = -a
		m.add_child(pivot)
		arms.append(pivot)

# the W runs: touching W tiles make one plug (B1), stopper (B2) or clamp (B3)
func build_groups(m: Node) -> void:
	var seen := {}
	for z in h:
		for x in w:
			if grid[z][x] != "W" or seen.has(Vector2i(x, z)):
				continue
			var run: Array = []
			var todo: Array = [Vector2i(x, z)]
			seen[Vector2i(x, z)] = true
			while not todo.is_empty():
				var p: Vector2i = todo.pop_back()
				run.append(p)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and grid[q.y][q.x] == "W" and not seen.has(q):
						seen[q] = true
						todo.append(q)
			var nodes: Array = []
			var sum := Vector2.ZERO
			for p: Vector2i in run:
				var at := Vector2(ox + p.x, p.y)
				nodes.append(m.forest.brick_wall(m, at))
				sum += at
			groups.append({"tiles": run, "nodes": nodes, "open": false, "at": sum / run.size()})

func open_group(g: Dictionary) -> void:
	g.open = true
	for n in g.nodes:
		n.visible = false
	for p: Vector2i in g.tiles:
		open_tiles[p] = true

func show_planks() -> void:
	planks_shown = true
	for n in plank_nodes:
		n.visible = true

func light(l: Dictionary) -> void:
	l.lit = true
	(l.glass as MeshInstance3D).material_override = l.lit_mat
	(l.light as OmniLight3D).visible = true

func open_lid() -> void:
	lid_open = true
	for n in lid_nodes:
		n.visible = false
	for n in chain_nodes:
		n.position.y += 0.3

func drain() -> void:
	drained = true
	if flood != null:
		flood.visible = false
	if cradle2 != null: # the delivery cradle comes to rest on the dry channel floor
		cradle2.position.y = 0.0
		cradle2.rotation.z = 0.25

func open_door() -> void:
	door_open = true
	for n in door_nodes:
		n.visible = false

func light_stone() -> void:
	if stone_glow == null:
		return
	stone_glow.albedo_color = Color("#bcd6ff")
	stone_glow.emission_enabled = true
	stone_glow.emission = Color("#bcd6ff")
	stone_glow.emission_energy_multiplier = 0.9
	stone_light.visible = true

func wind_latch(k: int) -> void:
	var l: Dictionary = latches[k]
	l.wound = true
	var g: StandardMaterial3D = l.glow
	g.albedo_color = Color("#9fd4ff")
	g.emission_enabled = true
	g.emission = Color("#9fd4ff")
	g.emission_energy_multiplier = 1.2
	(arms[k] as Node3D).rotation.y = -float(l.angle) # held still where it rests

func release_look() -> void:
	if cradle_lantern != null:
		cradle_lantern.visible = false
	for a in arms:
		(a as Node3D).position.y = -0.3 # the arms sink back into the floor, at rest

func map_tex(width: int) -> ImageTexture:
	var img := Image.create(width, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Color(FLOOR_COL[f]).darkened(0.15)
	for z in h:
		for x in w:
			var c: String = grid[z][x]
			var col := base
			match c:
				"#", "_": col = Color(0, 0, 0, 0)
				"~": col = Color("#2c5a8a")
				"r": col = base if drained else Color("#2c5a8a")
				"p": col = Color("#8a6038") if planks_shown else Color(0, 0, 0, 0)
				"W": col = base if open_tiles.has(Vector2i(x, z)) else Color("#c8322a")
				"G": col = base if lid_open else Color("#5a5e68")
				"D": col = base if door_open else Color("#dfc890")
				"o": col = Color("#ffc46a")
				"B", "t", "k", "P", "l", "O": col = Color("#8a6a4a")
				"L": col = Color("#ffd060")
				"Y": col = Color("#bcd6ff")
			img.set_pixel(ox + x, z, col)
	return ImageTexture.create_from_image(img)
