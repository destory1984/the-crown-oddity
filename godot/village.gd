# 등불 마을 (story step 8): a separate 48x36 area at x >= VILLAGE_X, built from blocks like the cave.
# Holds the map, its build, the lamplighter Simji, the three dark lanterns and the first errand.
# The first 32x24 is the old village; the market (three honesty-box stalls 1 2 3, the target yard Q) lies east,
# the inn (I, door N) and the pond with its pier (P, fishing spot f, three drifting bottles B) south.
# It moved from x 140 to x 560 when it grew, because the forest starts at x 180.
extends RefCounted

const VILLAGE_X := 560
const OLD_X := 140 # where it stood before it grew (old saves are moved over)
const W := 48
const H := 36
const ROWS := """################################################
#..HHH.......HHH.......HHH.....................#
#..HHH...L...HHH...L...HHH........TT..TT..TT..L#
#....=.........=.........=........1...2...3....#
#....=.........=.........=.......:::::::::::::.#
#....===========.........=.......:::::::::::::.#
#..........oooooooooo....=.......::::::::::::L.#
#.........LooooooooooL...=.......:::::::::::::.#
#..........oooooooooo....=.......:::::::::::::.#
#L..M......ooooUUoooo....=.....................#
G=S========ooooUUoooo==========================F
#L.........oooooooooo....=.....................#
#.........LooooooooooL...=........##########...#
#..........oooooooooo....=........#........#...#
#..HHH.........=.......b.=.b......#........#...#
#..HHH...L.....=.......d.=.d......#...Q....#.L.#
#....=.........=.........=........#........#...#
#....===========.........=........#........#...#
#..........HHH...........=........####..####...#
#..........HHH.......b...=.....................#
#....................d...=..............L......#
#..............................................#
#..............................................#
#...............=..............................#
#...............=.......L......................#
#..IIIII........=.........~~~~~~~~~~~~~~~~~~~~.#
#..IIIII....L...=.........~~~~~~~~~~~~~~~B~~~~.#
#..IIIII........=.........~~~~~~~~~~~~~~~~~~~~.#
#....N..........=.........~~~~~~~~~~~~~~~~~~~~.#
#....============......PPPPPPPPPPPPPf~~~~~~~~~.#
#...............=.........~~~~~~~~~~~~~~~~~~~~.#
#.........L.....=....L....~~~~~~~~~~~~~~~~~~~~.#
#...............=.........~~~~~~~~~~~~~~~~~B~~.#
#..L............=.........~~~~~B~~~~~~~~~~~~~~.#
#...............=..............................#
################K###############################"""

var grid: Array = []
var marks := {}          # S, G, M, F, K, R (the moon-trial stone), Q the target post, N the inn door, f the pier's end, 1 2 3 stalls -> world Vector2
var bottles: Array = []  # [{"pos": Vector2, "node": Node3D, "got": bool}]
var stall_names := {"1": "과일 가판대", "2": "달빛 가루 가판대", "3": "찻집 가판대"}
var dark: Array = []     # [{"pos": Vector2, "light": OmniLight3D, "glass": MeshInstance3D, "lit": bool, "brick": Vector2}]
var simji_node: Node3D
# villagers you can talk to with E: id and tile in the village grid
const FOLK := [
	{"id": "doran", "at": Vector2i(14, 3)},
	{"id": "kongal", "at": Vector2i(10, 15)},
	{"id": "mulgyeol", "at": Vector2i(28, 21)},
	# six working villagers who give hints (v0.0.35), each by his work
	{"id": "dusol", "at": Vector2i(43, 11)},   # woodcutter, on the east road to the forest
	{"id": "chadol", "at": Vector2i(45, 20)},  # miner, east field with his ore cart
	{"id": "saecham", "at": Vector2i(38, 21)}, # farmer, by his hardened field
	{"id": "yeoul", "at": Vector2i(32, 24)},   # fisher, on the pond's north edge
	{"id": "darae", "at": Vector2i(36, 7)},    # weaver, market floor with her baskets
	{"id": "tori", "at": Vector2i(41, 7)},     # market kid with his handcart
]
const FIELD := Rect2i(32, 20, 5, 3) # the farmer's hardened field (tiles, walkable)
var folk_pos := {}
var doors: Array = []    # world Vector2 in front of each house door, in build order
var folk_node := {}

func _init() -> void:
	for line in ROWS.split("\n"):
		grid.append(line)

func char_at(x: float, z: float) -> String:
	var tx := int(round(x)) - VILLAGE_X
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= W or tz >= H:
		return "#"
	return grid[tz][tx]

# fence and houses block; everything else is walkable ground
func blocked(x: float, z: float) -> bool:
	var c := char_at(x, z)
	return c in "#HTI~BU"

# the marsh's look in the village's own colours (DESIGN.md, section 다른 지역도 늪만큼 보기 좋게): a tidy lawn over
# speckled tops, warm cobbled streets, short mown grass and flowerbeds round the square and the houses. Nothing
# grows on or next to a street, the square, a door, a stall, the pier, a lantern, a mark or a villager's spot.
const GRASS_CLEAR := "=o#H:123TIPf~BLdbSGMFKQNU"
const BED_NEAR := "oH" # tiles two steps from the square or a house get flowers instead of plain grass
const YARD := Rect2i(34, 12, 10, 7) # the target yard, fence and all: the throwing game needs its floor bare
var grass_tiles: Array = [] # world tiles that got mown grass
var bed_tiles: Array = []   # world tiles that got a flowerbed
var dress_meshes: Array = [] # the tuft MultiMeshes (the tests count them)
var cosmos_tiles: Array = [] # the flower-bed and flower-field tiles, four cosmos clumps each
var path_flowers: Array = [] # lawn tiles beside a street, in runs of three with three bare between, three clumps each
var cosmos_spots := 0 # clumps planted (the tests count them)
# open lawns sown solid with cosmos in rows of one colour (the owner, 2026-10-28: "마을은 꽃밭과 꽃길을 만들어줘",
# not flowers dotted about; then "마을에 꽃이 너무 많아, 절제해서"): only the inn's back lawn is a field now
const FLOWER_FIELDS := [Rect2i(2, 30, 10, 4)]

# local tiles that are used but have no char of their own: villagers' spots, the kid goblin and its guards, the
# hardened field, the work props, the target yard
func keep_tiles(m: Node) -> Array:
	var out: Array = []
	for f in FOLK:
		out.append(f.at)
	var routes: Dictionary = m.FOLK_ROUTES
	for id in routes:
		for st in routes[id]:
			if st[1]:
				out.append(Vector2i(st[0]))
	out.append(KID_AT)
	out.append_array(KID_GUARDS)
	for r in [FIELD, YARD]:
		for z in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				out.append(Vector2i(x, z))
	for p in [Vector2i(44, 11), Vector2i(44, 12), Vector2i(46, 21), Vector2i(31, 24), Vector2i(33, 24), Vector2i(35, 7), Vector2i(42, 7)]:
		out.append(p)
	return out

func dress(m: Node, ground: Array, path: Array) -> void:
	var d = m.dressing
	d.begin(5601)
	var lawn: Array = []
	for xf in ground:
		lawn.append([xf, d.tint(0.24, 0.1, 0.86, 1.0)])
	var street: Array = []
	for xf in path:
		street.append([xf, d.tint(0.09, 0.06, 0.9, 1.0)])
	d.ground_blocks(lawn, VILLAGE_X, d.speckle_tex([Color("#6a9a3a"), Color("#74a442"), Color("#74a442"), Color("#82b04a")]))
	d.ground_blocks(street, VILLAGE_X, d.speckle_tex([Color("#a8987a"), Color("#b8a888"), Color("#b8a888"), Color("#cbbd9c")]))
	var at := func(x: int, z: int) -> String: return char_at(VILLAGE_X + x, z)
	var keep := keep_tiles(m)
	for t in d.pick_tiles(at, VILLAGE_X, W, 0, H, ".", GRASS_CLEAR, keep):
		if d.near_clear(at, int(t.x) - VILLAGE_X, int(t.y), BED_NEAR, [], 2):
			bed_tiles.append(t)
		else:
			grass_tiles.append(t)
	# no grass tufts in the village (the owner, 2026-10-28: "마을에서 풀은 빼줘") and no lone clumps either: cosmos grow
	# only in beds (round the square and the houses), in whole fields (FLOWER_FIELDS) and in a border down both sides of
	# every street; tall, so they rock more than grass did (strength 0.2)
	cosmos_tiles = bed_tiles.duplicate()
	for t in grass_tiles:
		var lt := Vector2i(int(t.x) - VILLAGE_X, int(t.y))
		if FLOWER_FIELDS.any(func(r): return r.has_point(lt)):
			cosmos_tiles.append(t)
	# the street borders: lawn tiles on the south or east side of a street (not on a corner only) with nothing else used
	# within one tile, in runs of three tiles with three left bare; their clumps stand in the half away from the street
	path_flowers = []
	var sides: Array = [] # per border tile, the unit step away from the street
	var near_used := GRASS_CLEAR.replace("=", "")
	for z in H:
		for x in W:
			if at.call(x, z) != ".":
				continue
			var away := Vector2.ZERO
			for st in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if at.call(x + st.x, z + st.y) == "=":
					away -= Vector2(st)
			if away == Vector2.ZERO or away.x + away.y < 0.0 or d.near_clear(at, x, z, near_used, keep):
				continue
			if (x + z) % 6 >= 3:
				continue
			path_flowers.append(Vector2(VILLAGE_X + x, z))
			sides.append(away.normalized())
	var pink: Texture2D = d.cosmos_tex(["#ffb8dc", "#ffa0cc", "#ffe4f2", "#ffffff"])
	var deep: Texture2D = d.cosmos_tex(["#ff7ab8", "#ffb8dc", "#ffffff", "#eaa0ff"])
	var white: Texture2D = d.cosmos_tex(["#ffffff", "#fff4fa", "#ffe4f2", "#ffd0e8"])
	var texs: Array = [pink, deep, white]
	var spots: Array = [[], [], []]
	# beds and fields: a row of one colour each (z), four clumps a tile
	for t in cosmos_tiles:
		spots[int(t.y) % 3].append_array(d.spots_on([t], 0.0, 4, 0.8, 1.1))
	# the borders: one colour a street side, clumps 0.1 - 0.45 tile off the tile centre away from the street
	for i in path_flowers.size():
		var t: Vector2 = path_flowers[i]
		var away: Vector2 = sides[i]
		var across := Vector2(-away.y, away.x)
		for k in 3:
			var p: Vector2 = t + away * d.rnd(0.1, 0.45) + across * (k - 1) * 0.3
			spots[(1 if away.x + away.y > 0.0 else 0)].append(Vector4(p.x, 0.0, p.y, d.rnd(0.75, 1.0)))
	cosmos_spots = 0
	for i in 3:
		cosmos_spots += spots[i].size()
		dress_meshes.append(d.grass(texs[i], 0.9, 1.1, spots[i], 0.2, false))
	d.end()

func build(m: Node) -> void:
	var blocks: Array = [] # [Transform3D, Color]
	var ground: Array = [] # Transform3D of lawn and street tiles, drawn by dress
	var path: Array = []
	var lamp_spots: Array = []
	var dark_spots: Array = []
	var bricks: Array = []
	for z in H:
		for x in W:
			var c: String = grid[z][x]
			var w := Vector2(VILLAGE_X + x, z)
			if c in "SGMFKRQNf123":
				marks[c] = w
			if c == "B":
				bottles.append({"pos": w, "node": null, "got": false})
			var col := Color("#5e8f30")
			match c:
				"=": col = Color("#b8a888")
				"o", "U": col = Color("#9a9a8e")
				"#": col = Color("#6a4a2c")
				"H": col = Color("#4a6a2c")
				":", "1", "2", "3": col = Color("#a89880")
				"P", "f": col = Color("#9a7448")
				"~", "B": col = Color("#2a5a8a")
			col = col.lightened(m.rnd(0, 0.08))
			var hgt := 0.4
			if c == "#":
				hgt = 0.9 # low fence blocks
			if c == "~" or c == "B":
				blocks.append([Transform3D(Basis().scaled(Vector3(1, 0.05, 1)), Vector3(w.x, -0.42, w.y)), col])
				continue
			if c == "P" or c == "f":
				hgt = 0.5 # pier boards stand a little above the ground
			var xf := Transform3D(Basis().scaled(Vector3(1, hgt, 1)), Vector3(w.x, hgt / 2.0 - 0.4, w.y))
			if c == "=":
				path.append(xf)
			elif not c in "oU#H:123Pf": # lawn: the speckled top brings the colour (dress)
				ground.append(xf)
			else:
				blocks.append([xf, col])
			if c == "L":
				lamp_spots.append(w)
			if c == "d":
				dark_spots.append(w)
			if c == "b":
				bricks.append(w)
	# chunked 6x6 so each chunk sees only its nearby lanterns (the web renderer lights a mesh with at most 8)
	var chunks := {}
	for bl in blocks:
		var o: Vector3 = bl[0].origin
		var key := Vector2i(int(o.x - VILLAGE_X) / 6, int(o.z) / 6)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(bl)
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.roughness = 0.9
	for key in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = BoxMesh.new()
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i][0])
			mm.set_instance_color(i, (list[i][1] as Color).srgb_to_linear())
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = cm
		m.add_child(mmi)
	dress(m, ground, path)
	# houses: one per 3x2 block of H, door facing south
	var seen := {}
	for z in H:
		for x in W:
			if grid[z][x] == "H" and not seen.has(Vector2i(x, z)):
				for dz in 2:
					for dx in 3:
						seen[Vector2i(x + dx, z + dz)] = true
				house(m, Vector3(VILLAGE_X + x + 1, 0, z + 0.5))
				doors.append(Vector2(VILLAGE_X + x + 0.4, z + 1.9)) # just in front of the door
	build_market(m)
	build_inn(m)
	build_pond(m)
	var post_mat: Material = m.mat_color(Color("#3b2a1e"))
	var glass: Material = m.glow_mat(Color("#ffc46a"), 4.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	for w in lamp_spots:
		m.lantern(w.x - 0.3, w.y, post_mat, glass)
	var fl: Vector2 = fountain_at() + FOUNTAIN_LAMP
	m.lantern(fl.x - 0.3, fl.y, post_mat, glass)
	for w in dark_spots:
		m.lantern(w.x - 0.3, w.y, post_mat, glass)
		var l: OmniLight3D = m.lanterns[m.lanterns.size() - 1]
		var g: MeshInstance3D = l.get_meta("glass")
		g.set_meta("lit_mat", g.material_override)
		g.material_override = m.mat_color(Color("#3a3428"))
		l.set_meta("dark", true)
		var brick: Vector2 = w + Vector2(0, -1)
		for b in bricks:
			if b.distance_to(w) < 1.5:
				brick = b
		dark.append({"pos": w, "light": l, "glass": g, "lit": false, "brick": brick})
	for b in bricks: # a little pile of toy bricks waiting to wake
		for k in 4:
			var bb: MeshInstance3D = m.box(Vector3(0.3, 0.2, 0.2), m.mat_color(Color("#b4231e") if k % 2 == 0 else Color("#2f5fb8")))
			bb.position = Vector3(b.x + m.rnd(-0.3, 0.3), 0.1 + (k / 2) * 0.2, b.y + m.rnd(-0.3, 0.3))
			m.add_child(bb)
			toy_bricks.append(bb)
	for f in FOLK:
		var w := Vector2(VILLAGE_X + f.at.x, f.at.y)
		folk_pos[f.id] = w
		# GPT pixel sprite, two idle frames side by side (art/folk/<id>.png)
		var spr := Sprite3D.new()
		spr.texture = load("res://art/folk/%s.png" % f.id)
		spr.hframes = 2
		spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		spr.scale = Vector3(1, 1.0 / cos(0.78), 1)
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		spr.shaded = false
		spr.pixel_size = m.folk_height(f.id) / 170.0 # main.gd FOLK_HEIGHT
		spr.offset = Vector2(0, 85)
		spr.position = Vector3(w.x, 0, w.y)
		m.add_child(spr)
		folk_node[f.id] = spr
		var tw := spr.create_tween().set_loops() # blink / idle beat every few seconds
		tw.tween_interval(2.4 + m.rnd(0, 1.2))
		tw.tween_callback(func(): spr.frame = 1)
		tw.tween_interval(0.35)
		tw.tween_callback(func(): spr.frame = 0)
		m.rocks.append({"x": w.x, "z": w.y, "r": 0.45, "folk": f.id}) # main.gd clears it while he sleeps
	build_work_props(m)
	build_fountain(m)
	simji_node = simji(m)
	simji_node.position = Vector3(marks.M.x, 0, marks.M.y)
	m.add_child(simji_node)
	var spr: Sprite3D = simji_node.get_child(0)
	var tw := spr.create_tween().set_loops() # he blinks now and then
	tw.tween_interval(3.0)
	tw.tween_callback(func(): spr.frame = 1)
	tw.tween_interval(0.35)
	tw.tween_callback(func(): spr.frame = 0)
	m.rocks.append({"x": marks.M.x, "z": marks.M.y, "r": 0.5})
	build_small_things(m)
	m.football.build()

# props by the six working villagers: a woodpile, an ore cart, the hardened field, a fish basket, reed baskets,
# crates by the kid's handcart. The field is only low furrows (walkable); the rest block like small rocks.
func build_work_props(m: Node) -> void:
	var add := func(size: Vector3, pos: Vector2, y: float, col: Color, rot := 0.0) -> MeshInstance3D:
		var b: MeshInstance3D = m.box(size, m.mat_color(col))
		b.position = Vector3(VILLAGE_X + pos.x, y, pos.y)
		b.rotation.y = rot
		m.add_child(b)
		return b
	# woodpile beside Dusol: split logs stacked three high
	for row in 3:
		for k in 3 - row:
			add.call(Vector3(0.8, 0.22, 0.22), Vector2(44.3, 11.45 - 0.25 + k * 0.25 + row * 0.12), 0.11 + row * 0.22, Color("#a0703c").darkened(0.08 * ((k + row) % 2)))
	add.call(Vector3(0.4, 0.3, 0.4), Vector2(44.2, 12.1), 0.15, Color("#6a4a2c")) # chopping block
	m.rocks.append({"x": VILLAGE_X + 44.3, "z": 11.5, "r": 0.4})
	# Chadol's ore cart: a box on four wheels, grey ore heaped in it
	add.call(Vector3(0.9, 0.4, 0.6), Vector2(46.0, 20.8), 0.42, Color("#6a4a2e"))
	for wx in [-0.32, 0.32]:
		for wz in [-0.32, 0.32]:
			add.call(Vector3(0.16, 0.24, 0.06), Vector2(46.0 + wx, 20.8 + wz), 0.12, Color("#2e2a26"))
	for k in 4:
		add.call(Vector3(0.24, 0.2, 0.24), Vector2(45.8 + (k % 2) * 0.35, 20.7 + (k / 2) * 0.2), 0.7, Color("#8a8a90").darkened(0.1 * (k % 2)), k * 0.5)
	m.rocks.append({"x": VILLAGE_X + 46.0, "z": 20.8, "r": 0.45})
	# the hardened field: furrows gone stiff like toy bricks, a few stud rows sticking up
	for z in range(FIELD.position.y, FIELD.end.y):
		add.call(Vector3(FIELD.size.x, 0.05, 0.9), Vector2(FIELD.position.x + (FIELD.size.x - 1) / 2.0, z), 0.025, Color("#5a3a26"))
		add.call(Vector3(FIELD.size.x - 0.2, 0.1, 0.32), Vector2(FIELD.position.x + (FIELD.size.x - 1) / 2.0, z), 0.07, Color("#8a3a26") if z % 2 == 0 else Color("#7a3222"))
		for x in range(FIELD.position.x, FIELD.end.x):
			add.call(Vector3(0.14, 0.08, 0.14), Vector2(x, z), 0.15, Color("#c8322a") if (x + z) % 2 == 0 else Color("#2f5fb8"))
	# Yeoul's fish basket and a net rolled up on the bank
	add.call(Vector3(0.45, 0.32, 0.45), Vector2(31.2, 24.2), 0.16, Color("#b89a5a"))
	add.call(Vector3(0.7, 0.14, 0.3), Vector2(32.9, 23.6), 0.07, Color("#4a8a8a"), 0.3)
	m.rocks.append({"x": VILLAGE_X + 31.2, "z": 24.2, "r": 0.3})
	# Darae's reed baskets, one half woven
	add.call(Vector3(0.45, 0.35, 0.45), Vector2(35.2, 7.3), 0.17, Color("#c8a46a"))
	add.call(Vector3(0.4, 0.2, 0.4), Vector2(35.4, 6.6), 0.1, Color("#b8945a"))
	add.call(Vector3(0.6, 0.08, 0.14), Vector2(35.3, 6.6), 0.26, Color("#d8c08a"), 0.6) # reed bundle
	m.rocks.append({"x": VILLAGE_X + 35.3, "z": 7.0, "r": 0.4})
	# crates by Tori's handcart
	add.call(Vector3(0.4, 0.36, 0.4), Vector2(42.0, 7.4), 0.18, Color("#9a6a3a"))
	add.call(Vector3(0.3, 0.26, 0.3), Vector2(42.05, 7.4), 0.49, Color("#c88a4a"))
	m.rocks.append({"x": VILLAGE_X + 42.0, "z": 7.4, "r": 0.3})

# Kongal's friend: a little green brick goblin with the red scarf she knitted (errand 2)
const KID_AT := Vector2i(6, 21)
const KID_GUARDS := [Vector2i(4, 20), Vector2i(8, 20), Vector2i(7, 22)]

func kid_goblin(m: Node) -> Node3D:
	var g := Node3D.new()
	var spr := Sprite3D.new() # GPT pixel sprite: frame 0 standing, frame 1 trotting
	spr.texture = load("res://art/folk/kid.png")
	spr.hframes = 2
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.scale = Vector3(1, 1.0 / cos(0.78), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	spr.pixel_size = m.folk_height("kid") / 110.0
	spr.offset = Vector2(0, 55)
	g.add_child(spr)
	g.set_meta("spr", spr)
	# it carries a little firefly jar, so it can be found in the dark south field
	var glow := OmniLight3D.new()
	glow.light_color = Color("#d8ffb0")
	glow.light_energy = 1.2
	glow.omni_range = 2.8
	glow.position = Vector3(0, 0.6, 0.4)
	g.add_child(glow)
	m.add_child(g)
	return g

# the village houses: the stilt house the user picked from five drafts (2026-10-23, draft 5)
func house(m: Node, at: Vector3) -> void:
	house_draft(m, at, 4, false)

# each house's window pane, in build order like doors: it burns down to a glimmer once someone has come home, over a
# time that is a little different from house to house, and comes back up when they go out (delight idea 40)
const PANE_LIT := 1.5
const PANE_DIM := 0.25
var house_panes: Array = []
var pane_tw: Dictionary = {}

func pane_dim_secs(i: int) -> float:
	return 2.6 + 0.4 * float((i * 3) % 7)

func pane_set(m: Node, i: int, lit: bool) -> void:
	if i < 0 or i >= house_panes.size():
		return
	var mat: StandardMaterial3D = house_panes[i]
	var goal := PANE_LIT if lit else PANE_DIM
	if is_equal_approx(mat.emission_energy_multiplier, goal) and not pane_tw.has(i):
		return
	if pane_tw.has(i) and pane_tw[i].is_valid():
		pane_tw[i].kill()
	var tw: Tween = m.create_tween()
	tw.tween_property(mat, "emission_energy_multiplier", goal, 1.0 if lit else pane_dim_secs(i))
	pane_tw[i] = tw

# the tall old lamplighter: GPT pixel sprite (two idle frames) and the glow of his own lamp
func simji(m: Node) -> Node3D:
	var g := Node3D.new()
	var spr := Sprite3D.new()
	spr.texture = load("res://art/folk/simji.png")
	spr.hframes = 2
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.scale = Vector3(1, 1.0 / cos(0.78), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	spr.pixel_size = m.folk_height("simji") / 200.0
	spr.offset = Vector2(0, 100)
	g.add_child(spr)
	var glow := OmniLight3D.new() # his own lamp lights him up at night
	glow.light_color = Color("#ffd8a0")
	glow.light_energy = 1.4
	glow.omni_range = 2.5
	glow.position = Vector3(-0.3, 1.9, 0.4)
	g.add_child(glow)
	return g

func map_tex(width: int) -> ImageTexture:
	var img := Image.create(width, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for z in H:
		for x in W:
			var c: String = grid[z][x]
			var col := Color("#16302e")
			match c:
				"#": col = Color(0, 0, 0, 0)
				"=": col = Color("#2c4a48")
				"o": col = Color("#3a5a6a")
				"H", "I", "T": col = Color("#c8962a")
				"L", "d": col = Color("#ffd060")
				":", "1", "2", "3": col = Color("#3a4a50")
				"~", "B": col = Color("#2c5a8a")
				"P", "f": col = Color("#6a5034")
				"Q", "N": col = Color("#ffd060")
				"U": col = Color("#70acb8")
			if FIELD.has_point(Vector2i(x, z)):
				col = Color("#5a3a2a")
			img.set_pixel(VILLAGE_X + x, z, col)
	return ImageTexture.create_from_image(img)

func lit_count() -> int:
	return dark.filter(func(d): return d.lit).size()

# three honesty-box stalls with striped awnings, each with a little sign; nobody minds them, the coins go in the box
func build_market(m: Node) -> void:
	var wood: Material = m.mat_color(Color("#7a5232"))
	var cloths := [Color("#c84a3a"), Color("#3a7ac8"), Color("#3aa86a")]
	var goods := [Color("#e84a4a"), Color("#bfe6ff"), Color("#c8a46a")]
	for k in 3:
		var key := str(k + 1)
		var at: Vector2 = marks[key]
		var g := Node3D.new()
		g.position = Vector3(at.x + 0.5, 0, at.y - 1.0)
		m.add_child(g)
		for side in [-0.85, 0.85]:
			var post: MeshInstance3D = m.box(Vector3(0.1, 1.6, 0.1), wood)
			post.position = Vector3(side, 0.8, 0.3)
			g.add_child(post)
		var counter: MeshInstance3D = m.box(Vector3(1.9, 0.7, 0.6), wood)
		counter.position = Vector3(0, 0.35, 0.1)
		g.add_child(counter)
		for st in 4: # striped awning
			var cloth: MeshInstance3D = m.box(Vector3(0.48, 0.06, 0.9), m.mat_color(cloths[k] if st % 2 == 0 else Color("#f2ead8")))
			cloth.position = Vector3(-0.72 + st * 0.48, 1.62, 0.2)
			cloth.rotation.x = 0.25
			g.add_child(cloth)
		for n in 5: # goods on the counter
			var item: MeshInstance3D = m.box(Vector3(0.18, 0.16, 0.18), m.mat_color(goods[k].darkened(0.1 * (n % 2))))
			item.position = Vector3(-0.7 + n * 0.35, 0.78, 0.1 + m.rnd(-0.1, 0.1))
			g.add_child(item)
		var box: MeshInstance3D = m.box(Vector3(0.26, 0.22, 0.2), m.mat_color(Color("#4a3a2a")))
		box.position = Vector3(0.7, 0.81, 0.36)
		g.add_child(box)
		m.sign_spots.append(Vector2(g.position.x, g.position.z + 0.9))
		var sign: Sprite3D = m.sign_icon({"1": "apple", "2": "moon", "3": "tea"}[key], 0.6)
		sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sign.position = Vector3(0, 2.0, 0.3)
		g.add_child(sign)
	# the target post in the fenced yard: a pole with a round red and white board
	var q: Vector2 = marks.Q
	var tg := Node3D.new()
	tg.position = Vector3(q.x, 0, q.y)
	m.add_child(tg)
	var pole: MeshInstance3D = m.box(Vector3(0.14, 1.4, 0.14), wood)
	pole.position = Vector3(0, 0.7, 0)
	tg.add_child(pole)
	for r in 3:
		var ring: MeshInstance3D = m.box(Vector3(0.7 - r * 0.2, 0.7 - r * 0.2, 0.06), m.mat_color(Color("#c8322a") if r % 2 == 0 else Color("#f2ead8")))
		ring.position = Vector3(0, 1.3, 0.1 + r * 0.02)
		tg.add_child(ring)
	m.rocks.append({"x": q.x, "z": q.y, "r": 0.3})

# the inn: a long two-storey house with a hanging sign
func build_inn(m: Node) -> void:
	var n: Vector2 = marks.N
	var g := Node3D.new()
	g.position = Vector3(n.x, 0, n.y - 2.0)
	m.add_child(g)
	var body: MeshInstance3D = m.box(Vector3(4.8, 2.4, 2.8), m.mat_color(Color("#e8dcc4")))
	body.position = Vector3(0, 1.2, 0)
	g.add_child(body)
	for side in [-1.0, 1.0]:
		var r: MeshInstance3D = m.box(Vector3(5.2, 0.14, 1.9), m.mat_color(Color("#3a5a7a")))
		r.position = Vector3(0, 2.8, side * 0.7)
		r.rotation.x = side * 0.6
		g.add_child(r)
	var door: MeshInstance3D = m.box(Vector3(0.7, 1.1, 0.06), m.mat_color(Color("#5a3a26")))
	door.position = Vector3(0, 0.55, 1.42)
	g.add_child(door)
	for wx in [-1.6, 1.6]:
		for wy in [0.9, 1.8]:
			var win: MeshInstance3D = m.box(Vector3(0.6, 0.45, 0.06), m.glow_mat(Color("#ffc46a"), 1.5))
			win.position = Vector3(wx, wy, 1.42)
			g.add_child(win)
	m.sign_spots.append(Vector2(n.x, n.y + 0.4))
	var sign: Sprite3D = m.sign_icon("inn", 0.9)
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.position = Vector3(0, 3.4, 1.4)
	g.add_child(sign)

# the pond: a water face, posts under the pier, and three glass bottles drifting with letters inside
func build_pond(m: Node) -> void:
	var wet: Material = m.glow_mat(Color("#2f78b8"), 0.6)
	wet.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	wet.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	var face: MeshInstance3D = m.box(Vector3(20.0, 0.02, 9.0), wet)
	face.position = Vector3(VILLAGE_X + 35.5, -0.34, 29)
	m.add_child(face)
	var wood: Material = m.mat_color(Color("#5a3e26"))
	for x in range(26, 37, 2):
		for dz in [-0.45, 0.45]:
			var post: MeshInstance3D = m.box(Vector3(0.12, 0.7, 0.12), wood)
			post.position = Vector3(VILLAGE_X + x, -0.15, 29 + dz)
			m.add_child(post)
	var glass: Material = m.glow_mat(Color("#bfe6c8"), 1.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	for b in bottles:
		var g := Node3D.new()
		var body: MeshInstance3D = m.box(Vector3(0.18, 0.32, 0.18), glass)
		body.position = Vector3(0, 0.1, 0)
		g.add_child(body)
		var cork: MeshInstance3D = m.box(Vector3(0.1, 0.1, 0.1), m.mat_color(Color("#8a6a44")))
		cork.position = Vector3(0, 0.31, 0)
		g.add_child(cork)
		g.rotation.z = 0.9
		g.position = Vector3(b.pos.x, -0.3, b.pos.y)
		m.add_child(g)
		b.node = g

func bottles_got() -> int:
	return bottles.filter(func(b): return b.got).size()

# ---- five house drafts for the user to pick from (scene "house_designs"); door faces south (+z) like house()
const HOUSE_DRAFTS := ["동화 초가집", "레고 벽돌집", "등불 목조집", "버섯 집", "물가 기둥집"]

func house_draft(m: Node, at: Vector3, k: int, labelled := true) -> void:
	var g := Node3D.new()
	g.position = at
	m.add_child(g)
	var add := func(size: Vector3, pos: Vector3, col: Color, rot := Vector3.ZERO, glow := false) -> MeshInstance3D:
		var b: MeshInstance3D = m.box(size, m.glow_mat(col, 1.5) if glow else m.mat_color(col))
		b.position = pos
		b.rotation = rot
		g.add_child(b)
		return b
	match k:
		0: # 동화 초가집: cream walls, a thick stepped straw roof, a round window and a flower box
			add.call(Vector3(2.6, 1.3, 1.8), Vector3(0, 0.65, 0), Color("#f2e6c8"))
			for s in 4:
				add.call(Vector3(3.2 - s * 0.6, 0.3, 2.3 - s * 0.45), Vector3(0, 1.45 + s * 0.28, 0), Color("#d8b25a").darkened(s * 0.05))
			add.call(Vector3(0.55, 0.9, 0.06), Vector3(-0.6, 0.45, 0.92), Color("#7a4a2a"))
			add.call(Vector3(0.45, 0.45, 0.06), Vector3(0.6, 0.85, 0.92), Color("#ffc46a"), Vector3(0, 0, PI / 4), true)
			add.call(Vector3(0.7, 0.16, 0.2), Vector3(0.6, 0.5, 1.0), Color("#8a5a32"))
			for f in 4:
				add.call(Vector3(0.12, 0.12, 0.12), Vector3(0.35 + f * 0.17, 0.64, 1.0), [Color("#e84a6a"), Color("#ffd23a"), Color("#e84a6a"), Color("#9a6ae8")][f])
		1: # 레고 벽돌집: walls stacked from studded toy bricks in four colours, a red studded roof
			var cols := [Color("#c8322a"), Color("#2f5fb8"), Color("#e8c23a"), Color("#3a9a4a")]
			for row in 4:
				for c in 4:
					add.call(Vector3(0.64, 0.32, 1.8), Vector3(-0.96 + c * 0.64 + (0.16 if row % 2 else 0.0), 0.16 + row * 0.32, 0), cols[(row + c) % 4])
			add.call(Vector3(2.9, 0.3, 2.1), Vector3(0, 1.43, 0), Color("#b4231e"))
			for sx in 4:
				for sz in 3:
					add.call(Vector3(0.18, 0.12, 0.18), Vector3(-1.05 + sx * 0.7, 1.64, -0.6 + sz * 0.6), Color("#d8342c"))
			add.call(Vector3(0.55, 0.9, 0.06), Vector3(-0.5, 0.45, 0.92), Color("#f2ead8"))
			add.call(Vector3(0.5, 0.4, 0.06), Vector3(0.6, 0.85, 0.92), Color("#bfe6ff"), Vector3.ZERO, true)
		2: # 등불 목조집: white plaster in dark timber frames, a slate roof, a lantern hung over the door
			add.call(Vector3(2.6, 1.5, 1.8), Vector3(0, 0.75, 0), Color("#efe8da"))
			for x in [-1.25, -0.4, 0.4, 1.25]:
				add.call(Vector3(0.12, 1.5, 0.05), Vector3(x, 0.75, 0.92), Color("#3a2618"))
			add.call(Vector3(2.62, 0.12, 0.05), Vector3(0, 0.8, 0.93), Color("#3a2618"))
			add.call(Vector3(1.2, 0.1, 0.05), Vector3(0.82, 0.8, 0.94), Color("#3a2618"), Vector3(0, 0, 0.55))
			for side in [-1.0, 1.0]:
				add.call(Vector3(3.0, 0.12, 1.3), Vector3(0, 1.85, side * 0.5), Color("#4a5468"), Vector3(side * 0.7, 0, 0))
			add.call(Vector3(0.55, 0.95, 0.06), Vector3(-0.15, 0.47, 0.95), Color("#5a3a26"))
			add.call(Vector3(0.22, 0.28, 0.22), Vector3(-0.15, 1.15, 1.15), Color("#ffc46a"), Vector3.ZERO, true)
			add.call(Vector3(0.5, 0.4, 0.06), Vector3(0.85, 1.05, 0.95), Color("#ffc46a"), Vector3.ZERO, true)
		3: # 버섯 집: a fat pale stem with a door and a big red cap with white spots
			add.call(Vector3(1.8, 1.4, 1.6), Vector3(0, 0.7, 0), Color("#efe2c8"))
			add.call(Vector3(3.0, 0.5, 2.6), Vector3(0, 1.6, 0), Color("#c83a32"))
			add.call(Vector3(2.2, 0.4, 1.9), Vector3(0, 2.0, 0), Color("#c83a32"))
			add.call(Vector3(1.2, 0.3, 1.0), Vector3(0, 2.3, 0), Color("#c83a32"))
			for sp in [Vector3(-0.9, 1.87, 0.9), Vector3(0.7, 1.87, 1.0), Vector3(0.2, 2.21, 0.75), Vector3(-0.5, 2.21, -0.3), Vector3(0.9, 1.87, -0.6)]:
				add.call(Vector3(0.28, 0.06, 0.28), sp, Color("#f8f4ea"))
			add.call(Vector3(0.5, 0.85, 0.06), Vector3(-0.3, 0.42, 0.82), Color("#6a4a2a"))
			add.call(Vector3(0.36, 0.36, 0.06), Vector3(0.45, 0.85, 0.82), Color("#ffc46a"), Vector3.ZERO, true)
		4: # 물가 기둥집: a blue-shuttered house on stilts with a porch, steps and a chimney under a tall roof
			for x in [-1.1, 1.1]:
				for z in [-0.7, 0.7]:
					add.call(Vector3(0.16, 0.6, 0.16), Vector3(x, 0.3, z), Color("#5a3e26"))
			add.call(Vector3(2.8, 0.12, 2.4), Vector3(0, 0.62, 0.2), Color("#9a7448"))
			add.call(Vector3(2.4, 1.2, 1.6), Vector3(0, 1.28, -0.1), Color("#e8e0cc"))
			for side in [-1.0, 1.0]:
				add.call(Vector3(2.8, 0.12, 1.25), Vector3(0, 2.25, -0.1 + side * 0.45), Color("#2f5a7a"), Vector3(side * 0.85, 0, 0))
			add.call(Vector3(0.3, 0.8, 0.3), Vector3(0.8, 2.5, -0.4), Color("#7a5a4a"))
			add.call(Vector3(0.5, 0.85, 0.06), Vector3(-0.5, 1.1, 0.72), Color("#5a3a26"))
			for sx in [0.35, 0.95]:
				add.call(Vector3(0.18, 0.45, 0.06), Vector3(sx, 1.35, 0.72), Color("#3a6ac8"))
			var pane: MeshInstance3D = add.call(Vector3(0.4, 0.45, 0.06), Vector3(0.65, 1.35, 0.71), Color("#ffc46a"), Vector3.ZERO, true)
			if not labelled:
				house_panes.append(pane.material_override) # a real village house: its window dims when its folk come home (idea 40)
			for st in 3:
				add.call(Vector3(0.6, 0.08, 0.25), Vector3(-0.5, 0.48 - st * 0.18, 1.5 + st * 0.25), Color("#9a7448"))
	if not labelled:
		return
	var t := Label3D.new()
	t.text = "%d  %s" % [k + 1, tr(HOUSE_DRAFTS[k])]
	t.font = m.ui_font
	t.font_size = 40
	t.pixel_size = 0.008
	t.modulate = Color("#3a2414")
	t.outline_size = 10
	t.outline_modulate = Color("#f2ead8")
	t.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	t.no_depth_test = true
	t.position = Vector3(0, 3.4, 0)
	g.add_child(t)

# ---- the moonkeepers' fountain (the owner, 2026-10-28: "마을 중앙에 광장을 만들고, 분수나 조형물 같은걸 세우자"; the square
# grew from 8x6 to 10x8, lore and lines talked over with GPT): an eight-sided stone basin on the four U tiles in the
# middle of the square, the main road splitting round it. Eight stone keepers stand on the rim holding hands, brass
# cuffs at their wrists (the winding bracelets); one joined hand is hardened to brick (Hangyeol's, who tried to wind
# the land alone). A low brass outlet with a crown relief in the middle. Water runs from the start (the owner,
# 2026-10-28: "평소에도 흐르게"), but only seven joined hands pour into the basin, the brick one dry, and the jet
# barely lifts; once the land is wound again (story_step 12) the eighth hand pours, the jet stands tall and a sheet
# of water falls from the upper bowl.
const FOUNTAIN := Vector2(15.5, 9.5) # village tiles, the middle of the four U tiles
const FOUNTAIN_LAMP := Vector2(2.0, 1.7) # the square's lantern, south-east of the basin (from its middle)
var fountain_full: Node3D # the eighth stream, the tall jet and the falling sheet, shown once the land is wound
var fountain_low: Node3D  # the low jet and a few floating leaves, hidden then
var fountain_wet := false
var fountain_said: Array = [] # the lines E by the basin showed last (autoplay fountain)
var fountain_water: MeshInstance3D # the basin's water face, sloshed by a blow
var fountain_splash: CPUParticles3D # the spray a blow throws up
var fountain_slosh: Tween
var fountain_emitters: Array = [] # the continuous drops: they stop when Sora is away from the village
var fountain_rings: Array = []    # the ring tweens, paused with them
var fountain_near := true
var fountain_main: Node
var fountain_half := false        # phones get half the drops
var fountain_hits := 0 # blows that reached it (autoplay fountain_splash)

func fountain_at() -> Vector2:
	return Vector2(VILLAGE_X + FOUNTAIN.x, FOUNTAIN.y)

func fountain_part(g: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	g.add_child(mi)
	return mi

func fountain_cyl(r: float, h: float, sides := 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = sides
	return c

func fountain_box(size: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = size
	return bm

func build_fountain(m: Node) -> void:
	fountain_half = m.touch_ui
	fountain_main = m
	var g := Node3D.new()
	g.position = Vector3(fountain_at().x, 0, fountain_at().y)
	m.add_child(g)
	var rim: Material = m.mat_color(Color("#c5baa0"))
	var stone: Material = m.mat_color(Color("#918b7d"))
	var base: Material = m.mat_color(Color("#7a7468")) # the basin's side, darker than the square's paving
	var dust: Material = m.mat_color(Color("#716857"))
	var brass: Material = m.mat_color(Color("#a58a50"), 0.45)
	var brick: Material = m.mat_color(Color("#986d58"))
	var leaf: Material = m.mat_color(Color("#8a5a2c"))
	var top := 0.32
	fountain_part(g, fountain_cyl(0.96, top - 0.05), base, Vector3(0, (top - 0.05) / 2.0, 0), PI / 8.0) # the basin
	fountain_part(g, fountain_cyl(0.98, 0.05), rim, Vector3(0, top - 0.025, 0), PI / 8.0) # its pale rim
	fountain_part(g, fountain_cyl(0.78, 0.02), dust, Vector3(0, top + 0.005, 0), PI / 8.0) # its floor
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("#70acb8", 0.85)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.1
	water.metallic_specular = 0.8
	var spout := StandardMaterial3D.new()
	spout.albedo_color = Color("#d8f0f4", 0.7)
	spout.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fountain_low = Node3D.new()
	g.add_child(fountain_low)
	fountain_full = Node3D.new()
	g.add_child(fountain_full)
	# the eight keepers on the rim, between their joined arms
	var rr := 0.86
	for k in 8:
		var ang := TAU * k / 8.0
		var p := Vector3(cos(ang) * rr, 0, sin(ang) * rr)
		fountain_part(g, fountain_box(Vector3(0.15, 0.28, 0.13)), stone, p + Vector3(0, top + 0.14, 0), -ang)
		fountain_part(g, fountain_cyl(0.075, 0.13, 8), stone, p + Vector3(0, top + 0.35, 0))
		# arms to the next keeper: a bar along the chord, brass cuffs at both wrists, Hangyeol's hand in brick
		var mid := ang + TAU / 16.0
		var chord := 2.0 * rr * sin(TAU / 16.0)
		var mp := Vector3(cos(mid), 0, sin(mid)) * rr * cos(TAU / 16.0) + Vector3(0, top + 0.19, 0)
		fountain_part(g, fountain_box(Vector3(chord, 0.05, 0.05)), brick if k == 0 else stone, mp, -mid - PI / 2.0)
		var along := Vector3(-sin(mid), 0, cos(mid))
		for side in [-1.0, 1.0]:
			fountain_part(g, fountain_box(Vector3(0.07, 0.07, 0.07)), brass, mp + along * side * chord * 0.3, -mid)
		# a thin stream from the joined hands into the basin; Hangyeol's brick hand pours only once the land is wound
		var drip := mp * Vector3(0.9, 1, 0.9) - Vector3(0, 0.08, 0)
		fountain_part(fountain_full if k == 0 else g, fountain_cyl(0.022, 0.16, 6), spout, drip)
	# the middle: a stone column with a small upper bowl, the outlet over it a brass cap with five crown points
	fountain_part(g, fountain_cyl(0.13, 0.78), stone, Vector3(0, top + 0.39, 0))
	fountain_part(g, fountain_cyl(0.36, 0.1), rim, Vector3(0, top + 0.8, 0), PI / 8.0)
	fountain_part(g, fountain_cyl(0.17, 0.08), brass, Vector3(0, top + 0.89, 0))
	for k in 5:
		var a := TAU * k / 5.0
		fountain_part(g, fountain_box(Vector3(0.05, 0.08, 0.05)), brass, Vector3(cos(a) * 0.14, top + 0.97, sin(a) * 0.14))
	for k in 3: # leaves floating while the water is low
		var a: float = m.rnd(0, TAU)
		var d: float = m.rnd(0.3, 0.6)
		var lf: MeshInstance3D = fountain_part(fountain_low, fountain_box(Vector3(0.12, 0.015, 0.07)), leaf, Vector3(cos(a) * d, top + 0.05, sin(a) * d), m.rnd(0, PI))
		leaves.append({"node": lf, "a": a, "d": d, "rot": lf.rotation.y})
	fountain_water = fountain_part(g, fountain_cyl(0.79, 0.03), water, Vector3(0, top + 0.03, 0), PI / 8.0) # the basin's water
	fountain_splash = fountain_drops(g, Vector3(0, top + 0.08, 0), Vector3.UP, 36, 2.2, 0.6, 0.03, 50.0)
	fountain_emitters.erase(fountain_splash) # a one-shot burst: nothing to stop
	fountain_splash.emitting = false
	fountain_splash.one_shot = true
	fountain_splash.explosiveness = 0.9
	fountain_part(g, fountain_cyl(0.33, 0.02), water, Vector3(0, top + 0.86, 0), PI / 8.0) # the upper bowl's
	var low := fountain_part(fountain_low, fountain_cyl(0.035, 0.08, 6), spout, Vector3(0, top + 1.0, 0)) # a weak welling
	var lw := low.create_tween().set_loops()
	lw.tween_property(low, "scale", Vector3(1.1, 1.3, 1.1), 0.9).set_trans(Tween.TRANS_SINE)
	lw.tween_property(low, "scale", Vector3(1, 0.8, 1), 0.9).set_trans(Tween.TRANS_SINE)
	var jet := fountain_part(fountain_full, fountain_cyl(0.05, 0.5, 6), spout, Vector3(0, top + 1.24, 0)) # the tall jet
	var fall := CylinderMesh.new() # a thin sheet of water from the upper bowl's lip into the basin
	fall.top_radius = 0.36
	fall.bottom_radius = 0.6
	fall.height = 0.76
	fall.radial_segments = 16
	fall.cap_top = false
	fall.cap_bottom = false
	var sheet := StandardMaterial3D.new()
	sheet.albedo_color = Color("#bfe4ea", 0.35)
	sheet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sheet.cull_mode = BaseMaterial3D.CULL_DISABLED
	fountain_part(fountain_full, fall, sheet, Vector3(0, top + 0.41, 0))
	var tw := jet.create_tween().set_loops() # the water wells up and settles
	tw.tween_property(jet, "scale", Vector3(1.2, 1.3, 1.2), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(jet, "scale", Vector3(1, 0.85, 1), 0.6).set_trans(Tween.TRANS_SINE)
	# moving water (the owner, 2026-10-29: "마을 분수에 물이 안 흐르네"): the streams and the welling above were still
	# shapes, so from the camera nothing moved. Now drops arc from the seven joined hands into the basin, four thin
	# trickles spill over the upper bowl's lip, the middle bubbles, and rings spread on the basin; once the land is wound
	# the eighth hand pours too and the jet sprays high.
	for k in 8:
		var mid := TAU * k / 8.0 + TAU / 16.0
		var hand := Vector3(cos(mid), 0, sin(mid)) * 0.86 * cos(TAU / 16.0) * 0.9 + Vector3(0, top + 0.14, 0)
		fountain_drops(fountain_full if k == 0 else g, hand, -Vector3(cos(mid), 0, sin(mid)) + Vector3(0, -0.4, 0), 14, 0.55, 0.45, 0.034)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		fountain_drops(fountain_low, Vector3(cos(a) * 0.35, top + 0.84, sin(a) * 0.35), Vector3(cos(a) * 0.3, -1, sin(a) * 0.3), 20, 0.3, 0.7, 0.032)
	fountain_drops(fountain_low, Vector3(0, top + 0.95, 0), Vector3.UP, 20, 1.2, 0.3, 0.04, 25.0) # the middle bubbles
	fountain_drops(fountain_full, Vector3(0, top + 1.0, 0), Vector3.UP, 40, 2.6, 0.75, 0.03, 12.0) # the jet sprays
	for k in 3: # rings spreading on the basin, one after another
		fountain_ring(g, top + 0.05, k * 0.8, water)
	m.rocks.append({"x": fountain_at().x, "z": fountain_at().y, "r": 1.0})
	var t := Timer.new() # the ending winds the land while Sora is elsewhere: look now and then
	t.wait_time = 1.0
	t.autostart = true
	g.add_child(t)
	t.timeout.connect(func(): fountain_set(m.story_step >= 12))
	fountain_set(m.story_step >= 12)

# falling water drops: `amount` small pale spheres a `life` seconds long from `at`, thrown along `dir` at `speed`
func fountain_drops(parent: Node3D, at: Vector3, dir: Vector3, amount: int, speed: float, life: float, size: float, spread := 8.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 2.0
	s.radial_segments = 6
	s.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#9fdcec", 0.95) # a little blue, so the drops show over the pale stone
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s.material = mat
	p.mesh = s
	p.amount = maxi(1, amount / 2) if fountain_half else amount
	p.lifetime = life
	p.direction = dir.normalized()
	p.spread = spread
	p.initial_velocity_min = speed * 0.8
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -6.0, 0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	p.position = at
	parent.add_child(p)
	fountain_emitters.append(p)
	return p

# a ring of water spreading from the middle of the basin and fading, every 2.4 s, `delay` seconds in
func fountain_ring(g: Node3D, y: float, delay: float, water: Material) -> void:
	var tor := TorusMesh.new()
	tor.inner_radius = 0.9
	tor.outer_radius = 1.0
	tor.rings = 24
	tor.ring_segments = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e6f8fb", 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ring := MeshInstance3D.new()
	ring.mesh = tor
	ring.material_override = mat
	ring.position = Vector3(0, y, 0)
	ring.scale = Vector3(0.2, 0.02, 0.2)
	g.add_child(ring)
	var tw := ring.create_tween().set_loops()
	fountain_rings.append(tw)
	tw.tween_interval(delay)
	tw.tween_callback(func():
		ring.scale = Vector3(0.2, 0.02, 0.2)
		mat.albedo_color.a = 0.6)
	tw.tween_property(ring, "scale", Vector3(0.74, 0.02, 0.74), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 2.4)
	tw.tween_interval(maxf(0.0, 2.4 - delay))

# Sora's blow reaching the basin (combat.gd swing): spray from the side she struck, the water face rocks and settles
const SLAP_PITCHES := [560.0, 620.0, 690.0, 760.0] # four fixed pitches, so the sound cache stays four streams per volume
func fountain_hit(m: Node, reach: float, f: Vector2, cone: float, all_round: bool) -> void:
	var d := fountain_at() - Vector2(m.player.x, m.player.z)
	if d.length() > reach + 1.0 or not (all_round or d.normalized().dot(f) > cone - 0.2):
		return
	fountain_hits += 1
	var side := -d.normalized() * 0.55 # the near edge of the basin
	fountain_splash.position = Vector3(side.x, fountain_splash.position.y, side.y)
	fountain_splash.restart()
	if fountain_slosh != null and fountain_slosh.is_valid():
		fountain_slosh.kill()
	var y0 := 0.35
	fountain_water.position.y = y0
	fountain_slosh = fountain_water.create_tween()
	for k in 4: # four swells, each smaller, each with its slap of water (the owner, 2026-10-29: "물 찰싹찰싹 소리 나게")
		var amp := 0.05 * (1.0 - k / 4.0)
		var slap_vol := 0.3 * (1.0 - k / 4.0)
		fountain_slosh.tween_callback(func(): m.sfx(SLAP_PITCHES[m.rng.randi() % SLAP_PITCHES.size()], 0.16, "splash", slap_vol, -420.0))
		fountain_slosh.tween_property(fountain_water, "position:y", y0 + amp, 0.12).set_trans(Tween.TRANS_SINE)
		fountain_slosh.parallel().tween_property(fountain_water, "rotation:x", amp * 1.4 * (1 if k % 2 == 0 else -1), 0.12)
		fountain_slosh.tween_property(fountain_water, "position:y", y0 - amp * 0.6, 0.12).set_trans(Tween.TRANS_SINE)
	fountain_slosh.tween_property(fountain_water, "position:y", y0, 0.15)
	fountain_slosh.parallel().tween_property(fountain_water, "rotation:x", 0.0, 0.15)

# ---- the toy brick piles by the dark lamps: a blow scatters them, each brick its own way, tumbling end over end
# along the ground and settling where it stops (the owner, 2026-10-29: "마을에 있는 이 오브젝트.. 공격하면, 따로따로
# 데굴데굴 굴러가게 해보자"). They lie where they fell until the village is built again (a load).
var toy_bricks: Array = []
var toy_rolls := 0 # bricks sent rolling (autoplay toy_bricks)
# a rolling brick taps the ground three times as it lands, each tap smaller and lower (delight idea 47, shots/plans/delight100.md)
const TOY_TAPS := [[440.0, 0.07], [330.0, 0.055], [247.0, 0.04]]
var toy_taps := 0 # taps heard (autoplay toy_taps)
var toy_tap_last := -1 # the number of the last tap

# how far a brick can roll from p along dir before it would touch a fence, a house, water or the map's edge (the owner,
# 2026-10-30: struck again and again, two bricks rolled off the village into the blank outside)
func roll_room(p: Vector2, dir: Vector2, want: float) -> float:
	var d := 0.0
	while d + 0.1 <= want:
		var q := p + dir * (d + 0.1)
		if blocked(q.x, q.y) or blocked(q.x + dir.x * 0.3, q.y + dir.y * 0.3):
			break
		d += 0.1
	return d

func bricks_hit(m: Node, reach: float, f: Vector2, cone: float, all_round: bool) -> void:
	var me := Vector2(m.player.x, m.player.z)
	var sent := 0
	for bb in toy_bricks:
		var b: MeshInstance3D = bb
		if b.has_meta("rolling"):
			continue
		var d := Vector2(b.position.x, b.position.z) - me
		if d.length() > reach + 0.6 or not (all_round or d.normalized().dot(f) > cone - 0.2):
			continue
		var away := (d.normalized() if d.length() > 0.05 else f).rotated(m.rnd(-0.6, 0.6))
		var dist: float = roll_room(Vector2(b.position.x, b.position.z), away, m.rnd(1.2, 2.6))
		if dist < 0.3: # against a fence or a wall: it bounces back the way the blow came
			away = -away
			dist = roll_room(Vector2(b.position.x, b.position.z), away, m.rnd(0.6, 1.2))
		var to := Vector2(b.position.x, b.position.z) + away * dist
		var t: float = 0.5 + dist * 0.25
		var axis := Vector3(away.y, 0, -away.x) # roll over the edge facing the way it goes
		var turns := dist / 0.2 # about one quarter turn for each 0.2 tiles, like a brick tipping over and over
		b.set_meta("rolling", true)
		toy_rolls += 1
		sent += 1
		var start := b.position
		var basis0 := b.basis
		var landed := [0]
		var tw := b.create_tween()
		tw.tween_method(func(k: float):
			var land := int(k * 3.0) # the hop is flat at a third and at two thirds: a landing each
			if land > landed[0] and land < 3:
				landed[0] = land
				toy_tap(m, land - 1)
			var e := 1.0 - pow(1.0 - k, 2.0) # fast off the blow, slowing down
			var pos := Vector2(start.x, start.z).lerp(to, e)
			var hop := absf(sin(k * PI * 3.0)) * 0.35 * (1.0 - k) # three hops, each lower
			b.position = Vector3(pos.x, 0.1 + hop, pos.y)
			b.basis = Basis(axis.normalized(), -e * turns * PI / 2.0) * basis0, 0.0, 1.0, t)
		tw.tween_callback(func():
			# settle flat on a face, keeping the way it ended up turned around the up axis
			var yaw := atan2(-b.basis.z.x, -b.basis.z.z)
			b.basis = Basis(Vector3.UP, yaw)
			b.position.y = 0.1
			toy_tap(m, 2)
			b.remove_meta("rolling"))
		m.burst(Vector3(b.position.x, 0.3, b.position.z), Color("#d8c8a8"), 4, 1.2)
	if sent > 0: # a clatter of toy bricks
		m.sfx(m.rnd(180.0, 220.0), 0.1, "square", 0.08, -60.0)

# ---- small things that answer what Sora has done (delight ideas 76 and 78, shots/plans/delight100.md): Kongal's chalk
# figures by his spot (a crowned stick figure once his kid goblin is home, a little otter once Mulgyeol is known) and four
# small pinwheels that turn as the hill's windmills do (the three small ones, then the big one)
const PINWHEEL_TILES := [Vector2(7.5, 2.6), Vector2(17.5, 2.6), Vector2(29.5, 2.6), Vector2(11.5, 13.6)]
var doodle_crown: MeshInstance3D
var doodle_otter: MeshInstance3D
var pinwheels: Array = [] # [{"hub": Node3D, "turning": bool, "spin": seconds of a blow's spin left}]
const PINWHEEL_SPIN := 20.0 # rad/s just after a blow, easing down to its usual turn over PINWHEEL_EASE seconds
const PINWHEEL_EASE := 2.5
var pinwheel_hits := 0 # blows that reached one (autoplay pinwheel_hit)

func chalk_line(img: Image, a: Vector2, b: Vector2) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		for dx in [0, 1, 2]: # three pixels wide, like chalk
			for dy in [0, 1]:
				var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
					img.set_pixelv(q, Color(1.0, 0.99, 0.94, 1.0))

func chalk_circle(img: Image, c: Vector2, r: float, sx := 1.0) -> void:
	var pts := 20
	for i in pts:
		var a0 := TAU * i / pts
		var a1 := TAU * (i + 1) / pts
		chalk_line(img, c + Vector2(cos(a0) * r * sx, sin(a0) * r), c + Vector2(cos(a1) * r * sx, sin(a1) * r))

func doodle_tex(kind: String) -> ImageTexture:
	var img := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if kind == "crown": # a stick figure with a zigzag crown, arms up
		chalk_circle(img, Vector2(48, 24), 7.0)
		chalk_line(img, Vector2(41, 17), Vector2(41, 9))
		chalk_line(img, Vector2(41, 9), Vector2(45, 14))
		chalk_line(img, Vector2(45, 14), Vector2(48, 8))
		chalk_line(img, Vector2(48, 8), Vector2(51, 14))
		chalk_line(img, Vector2(51, 14), Vector2(55, 9))
		chalk_line(img, Vector2(55, 9), Vector2(55, 17))
		chalk_line(img, Vector2(48, 31), Vector2(48, 46))
		chalk_line(img, Vector2(48, 35), Vector2(38, 28))
		chalk_line(img, Vector2(48, 35), Vector2(58, 28))
		chalk_line(img, Vector2(48, 46), Vector2(40, 58))
		chalk_line(img, Vector2(48, 46), Vector2(56, 58))
	else: # a small otter: round head with ears, a long body and a curled tail
		chalk_circle(img, Vector2(30, 28), 9.0)
		chalk_line(img, Vector2(24, 21), Vector2(22, 14))
		chalk_line(img, Vector2(22, 14), Vector2(28, 19))
		chalk_line(img, Vector2(36, 21), Vector2(40, 14))
		chalk_line(img, Vector2(40, 14), Vector2(38, 20))
		chalk_circle(img, Vector2(58, 38), 12.0, 1.7)
		chalk_line(img, Vector2(78, 42), Vector2(88, 38))
		chalk_line(img, Vector2(88, 38), Vector2(92, 30))
		chalk_line(img, Vector2(92, 30), Vector2(86, 26))
		chalk_line(img, Vector2(47, 49), Vector2(47, 58))
		chalk_line(img, Vector2(66, 49), Vector2(66, 58))
		img.set_pixel(27, 26, Color(0.96, 0.95, 0.88, 0.9))
		img.set_pixel(34, 26, Color(0.96, 0.95, 0.88, 0.9))
	return ImageTexture.create_from_image(img)

func chalk_plane(m: Node, kind: String, at: Vector2, yaw: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = Vector2(1.8, 1.2)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = doodle_tex(kind)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	q.material = mat
	mi.mesh = q
	mi.position = Vector3(at.x, 0.012, at.y)
	mi.rotation.y = yaw
	mi.visible = false
	m.add_child(mi)
	return mi

func build_small_things(m: Node) -> void:
	var k: Vector2 = folk_pos["kongal"]
	doodle_crown = chalk_plane(m, "crown", k + Vector2(1.5, -3.2), 0.2) # on the square's south edge, three tiles from his spot
	doodle_otter = chalk_plane(m, "otter", k + Vector2(3.5, -3.1), -0.15)
	var stick: Material = m.mat_color(Color("#7a5232"))
	var cols := [Color("#d8342c"), Color("#2f5fb8"), Color("#e8c23a"), Color("#3a9a4a")]
	for i in PINWHEEL_TILES.size():
		var t: Vector2 = PINWHEEL_TILES[i]
		var g := Node3D.new()
		g.position = Vector3(VILLAGE_X + t.x, 0, t.y)
		var pole: MeshInstance3D = m.box(Vector3(0.05, 0.9, 0.05), stick)
		pole.position = Vector3(0, 0.45, 0)
		g.add_child(pole)
		var hub := Node3D.new()
		hub.position = Vector3(0, 0.95, 0.05)
		for b in 4:
			var blade: MeshInstance3D = m.box(Vector3(0.3, 0.14, 0.02), m.mat_color(cols[(b + i) % 4]))
			blade.position = Vector3(0.15, 0.07, 0)
			var arm := Node3D.new()
			arm.rotation.z = b * PI / 2.0
			arm.add_child(blade)
			hub.add_child(arm)
		var cap: MeshInstance3D = m.box(Vector3(0.08, 0.08, 0.06), m.mat_color(Color("#f2ead8")))
		hub.add_child(cap)
		g.add_child(hub)
		m.add_child(g)
		pinwheels.append({"hub": hub, "turning": false, "spin": 0.0})

# which pinwheels turn: the first three with the hill's three small windmills, the fourth with the big one (mill_q 3)
func pinwheel_turning(m: Node, i: int) -> bool:
	if i < 3:
		return m.hill.mills.size() > i and bool(m.hill.mills[i].turning)
	return m.mill_q >= 3

# the floating leaves in the low basin drift round after Sora a beat late when she circles it (delight idea 1)
const LEAF_RING := Vector2(0.9, 3.2) # she must be this far from the middle to count as walking its edge
var leaves: Array = [] # [{"node", "a", "d", "rot"}]
var leaf_spin := 0.0 # how far the leaves have turned
var leaf_goal := 0.0 # how far Sora has gone round
var leaf_prev := INF # her angle round the fountain last frame

func leaves_update(m: Node, dt: float) -> void:
	var rel := Vector2(m.player.x, m.player.z) - fountain_at()
	var on_edge: bool = fountain_low.visible and rel.length() > LEAF_RING.x and rel.length() < LEAF_RING.y and not m.story_open
	if on_edge:
		var ang := rel.angle()
		if leaf_prev != INF:
			var dl := angle_difference(leaf_prev, ang)
			if absf(dl) < 0.6: # a real step round, not a jump
				leaf_goal += dl
		leaf_prev = ang
	else:
		leaf_prev = INF
	leaf_spin = lerpf(leaf_spin, leaf_goal, minf(1.0, dt * 2.2)) # the beat behind her
	for lf in leaves:
		var a: float = lf.a + leaf_spin
		var nd: MeshInstance3D = lf.node
		nd.position.x = cos(a) * lf.d
		nd.position.z = sin(a) * lf.d
		nd.rotation.y = lf.rot - leaf_spin

func life_update(m: Node, dt: float) -> void:
	leaves_update(m, dt)
	if doodle_crown != null:
		doodle_crown.visible = m.kid_q >= 3
		doodle_otter.visible = m.mul_q >= 1 or m.mate != null
	for i in pinwheels.size():
		var on: bool = pinwheel_turning(m, i)
		pinwheels[i].turning = on
		var speed := (4.0 + i * 0.6) if on else 0.0
		var spin: float = pinwheels[i].spin
		if spin > 0.0: # a blow: fast, easing down to its usual turn (still if its windmill is not mended)
			pinwheels[i].spin = maxf(0.0, spin - dt)
			speed = lerpf(speed, PINWHEEL_SPIN, spin / PINWHEEL_EASE)
		if speed > 0.0:
			(pinwheels[i].hub as Node3D).rotation.z -= dt * speed

# a blow that reaches a pinwheel sets it whirring (same reach test as the toy bricks)
func pinwheels_hit(m: Node, reach: float, f: Vector2, cone: float, all_round: bool) -> void:
	var me := Vector2(m.player.x, m.player.z)
	var sent := 0
	for pw in pinwheels:
		var hub: Node3D = pw.hub
		var d := Vector2(hub.global_position.x, hub.global_position.z) - me
		if d.length() > reach + 0.6 or not (all_round or d.normalized().dot(f) > cone - 0.2):
			continue
		pw.spin = PINWHEEL_EASE
		pinwheel_hits += 1
		sent += 1
	if sent > 0: # a light whirr
		m.sfx(520.0, 0.3, "noise", 0.1, 600.0)
		m.sfx(600.0, 0.25, "triangle", 0.06, 500.0)

func toy_tap(m: Node, n: int) -> void:
	toy_taps += 1
	toy_tap_last = n
	m.sfx(TOY_TAPS[n][0], 0.05, "triangle", TOY_TAPS[n][1], -30.0)

func fountain_set(wet: bool) -> void:
	fountain_wet = wet
	fountain_full.visible = wet
	fountain_low.visible = not wet
	fountain_look()

# drops and ring tweens run only while Sora is in the village and within FOUNTAIN_LIVE_RANGE tiles, and the drops only
# in the shown set (GPT review 2026-10-29: 15 emitters and 3 tweens ran everywhere, on phones too)
const FOUNTAIN_LIVE_RANGE := 25.0
func fountain_look() -> void:
	var near: bool = fountain_main.in_village and Vector2(fountain_main.player.x, fountain_main.player.z).distance_to(fountain_at()) < FOUNTAIN_LIVE_RANGE
	fountain_near = near
	for p in fountain_emitters:
		if is_instance_valid(p):
			p.emitting = near and p.get_parent().visible
	for tw in fountain_rings:
		if tw.is_valid():
			if near:
				tw.play()
			else:
				tw.pause()

# E beside the basin: Sora's look at it, seven streams or all eight
func fountain_key(m: Node, me: Vector2) -> bool:
	if me.distance_to(fountain_at()) > 1.9:
		return false
	fountain_said = m.STORY.FOUNTAIN_WET if fountain_wet else m.STORY.FOUNTAIN_LOW
	m.show_story("", fountain_said)
	return true
