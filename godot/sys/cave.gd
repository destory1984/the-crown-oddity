# Cave: build, props, shrine, singing crystals, the post tunnel, entering/leaving, the cart-mole.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const CAVE_W := 32
const CAVE_H := 40 # rows 21 - 39: the stream's end below the mole's hall (DESIGN.md, chapter 2)
const CAVE_ROWS := """################################
#......###........###..........#
#......###...P....###..........#
#.S............................#
#......###........###.......K..#
#......###........###..........#
#......###........###..........#
###..###########################
###..###########################
###..###########################
#........###........##.........#
#........###........##.........#
#........###..wwww..##.........#
#....................D.........#
#........###..wwww..##.........#
#........###........##....B....#
#........###........##.........#
####..################.........#
#.............########.........E
#.............########.........#
#...1...2...3.########.........#
#.............###########~~~####
#########################~~~####
##################~~~~~~~~~~####
##################~~~~~~~~~~####
##################~~~###########
##################~~~###########
#~~~~~~~~~~..#.................#
#~..~~~~..~....................#
#~..~~~~..~....................#
#~~~~~~~~~~..................T.#
#~~~~~..~~~....................#
#~..~~..~~~..###################
#~..~~~~~~~..###################
##GG############################
#........#######################
#........#######################
#.....M..#######################
#........#######################
################################"""
const CAVE_SPAWNS := [ # [x, z, archer] in cave tiles
	[13, 4, false], [15, 2, false],
	[24, 2, false], [26, 5, false], [29, 3, true],
	[3, 11, false], [6, 14, false], [4, 16, false],
	[13, 11, true], [18, 15, true],
]
const CRYSTAL_AT := [Vector2(2, 18), Vector2(6, 18), Vector2(10, 18), Vector2(13, 19)] # cave tiles
const NOTES := [262.0, 330.0, 392.0, 523.0]

var gate_told := false # the grate's hint was shown while she stands by it

# the line under the quest while she is down the stream with the grate still shut
func post_side() -> String:
	if not m.in_cave or m.story_open or m.post_q != 1 or m.player.z < 20.5:
		return ""
	return tr("섬 수정 넷을 낮은 소리부터 울리자 %d/4") % m.post_run
const POST_CRYSTALS := [Vector2(2, 28), Vector2(9, 28), Vector2(7, 31), Vector2(2, 32)] # cave tiles, on the islands
const POST_SPAWNS := [[17, 28, false], [22, 30, false], [28, 28, true]] # cave tiles, archer?
const POST_AMBUSH := [[12, 28, false], [12, 32, false], [16, 30, true]]
const POST_BATS := [Vector2(120, 29), Vector2(126, 30)]

func _init(main: Main) -> void:
	m = main

func cave_char(x: float, z: float) -> String:
	var tx := int(round(x)) - Main.CAVE_X
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= CAVE_W or tz >= CAVE_H:
		return "#"
	var c: String = m.cave_grid[tz][tx]
	if c == "D" and m.cave_door_open:
		return "."
	if c == "G" and m.post_q >= 2:
		return "."
	return c

# a floor tile in a gap at most two tiles across between walls: the ways from room to room
func cave_doorway(w: Vector2) -> bool:
	var across := 1
	var along := 1
	for d in [1, -1]:
		for k in range(1, 3):
			if cave_char(w.x + d * k, w.y) == "#":
				break
			across += 1
		for k in range(1, 3):
			if cave_char(w.x, w.y + d * k) == "#":
				break
			along += 1
	return across <= 2 or along <= 2

func build_cave() -> void:
	m.cave_grid = []
	for line in CAVE_ROWS.split("\n"):
		m.cave_grid.append(line)
	var floors: Array = []
	var walls: Array = []
	for z in CAVE_H:
		for x in CAVE_W:
			var c: String = m.cave_grid[z][x]
			var w := Vector2(Main.CAVE_X + x, z)
			if c in "SPKDBE123GMT":
				m.cave_marks[c] = w
			if c == "#":
				# only walls that touch the floor get built, to keep the count small
				var edge := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + d.x
					var nz: int = z + d.y
					if nx >= 0 and nz >= 0 and nx < CAVE_W and nz < CAVE_H and m.cave_grid[nz][nx] != "#":
						edge = true
				if edge:
					walls.append(w)
			else:
				floors.append(w)
	# Concept E, second pass (art direction from GPT, 2026-10-23).
	# Walls on the camera side of a floor stay low so they never hide Sora; the rest stand tall
	# with irregular protrusions. Everything uses a world-space slate shader, built in 6x6 chunks
	# because the web renderer lights each mesh with at most 8 lights.
	var pool_tiles: Array = floors.filter(func(f): return cave_char(f.x, f.y) == "w")
	var deep_tiles: Array = floors.filter(func(f): return cave_char(f.x, f.y) == "~")
	floors = floors.filter(func(f): return cave_char(f.x, f.y) != "w" and cave_char(f.x, f.y) != "~")
	var blocks: Array = [] # [Transform3D, Color]
	for w in floors:
		var lit := Color(1.7, 1.75, 1.95) if cave_doorway(w) else Color(1.15, 1.15, 1.2)
		blocks.append([Transform3D(Basis().scaled(Vector3(1, 0.4, 1)), Vector3(w.x, -0.2, w.y)), lit])
	for w in walls:
		var camera_side := cave_char(w.x, w.y - 1) != "#" or cave_char(w.x, w.y - 2) != "#" # floor within two tiles north: this wall is in front
		var h := 0.35 if camera_side else m.rnd(2.4, 3.0)
		blocks.append([Transform3D(Basis().scaled(Vector3(1, h, 1)), Vector3(w.x, h / 2.0, w.y)), Color(1, 1, 1)])
		if not camera_side and m.rng.randf() < 0.6: # a jutting stone on the face
			var j := m.rnd(0.4, 0.6)
			var off := Vector3(m.rnd(-0.25, 0.25), m.rnd(0.3, h - 0.4), m.rnd(-0.25, 0.25))
			for d in [Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]:
				if cave_char(w.x + d.x, w.y + d.y) != "#":
					off += Vector3(d.x, 0, d.y) * 0.5
					break
			blocks.append([Transform3D(Basis(Vector3.UP, m.rnd(0, 0.6)).scaled(Vector3(j, j, j)), Vector3(w.x, 0, w.y) + off), Color(1.1, 1.1, 1.1)])
	var stone := ShaderMaterial.new()
	stone.shader = load("res://shaders/cave_stone.gdshader")
	var chunks := {}
	for bl in blocks:
		var o: Vector3 = bl[0].origin
		var key := Vector2i(int(o.x - Main.CAVE_X) / 6, int(o.z) / 6)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(bl)
	for key in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = BoxMesh.new()
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i][0])
			mm.set_instance_color(i, list[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = stone
		m.add_child(mmi)
	# glowing pools, sunk 0.15 below the floor
	var pool := ShaderMaterial.new()
	pool.shader = load("res://shaders/cave_pool.gdshader")
	for t2 in pool_tiles:
		var pb := m.box(Vector3(1, 0.1, 1), pool)
		pb.position = Vector3(t2.x, -0.2, t2.y)
		m.add_child(pb)
	for t2 in deep_tiles: # the deep stream and the ringing pool below the mole's hall, a little lower
		var db := m.box(Vector3(1, 0.1, 1), pool)
		db.position = Vector3(t2.x, -0.3, t2.y)
		m.add_child(db)
	for at in [Vector2(122, 24), Vector2(106, 30)]:
		var dl := OmniLight3D.new()
		dl.light_color = Color("#25dce8")
		dl.light_energy = 1.2
		dl.omni_range = 4.5
		dl.position = Vector3(at.x, 0.5, at.y)
		m.add_child(dl)
	build_post_props()
	if not pool_tiles.is_empty():
		var c := Vector2.ZERO
		for t2 in pool_tiles:
			c += t2
		c /= pool_tiles.size()
		var pl := OmniLight3D.new()
		pl.light_color = Color("#25dce8")
		pl.light_energy = 1.6
		pl.omni_range = 4.5
		pl.position = Vector3(c.x, 0.5, c.y)
		m.add_child(pl)
	# crystals: five-sided cones in clusters of three at the foot of the back walls; violet mushrooms in pairs
	var wall_feet: Array = floors.filter(func(f): return cave_char(f.x, f.y - 1) == "#" or cave_char(f.x - 1, f.y) == "#" or cave_char(f.x + 1, f.y) == "#")
	wall_feet.shuffle()
	var teal := StandardMaterial3D.new()
	teal.albedo_color = Color("#55efff")
	teal.emission_enabled = true
	teal.emission = Color("#55efff")
	teal.emission_energy_multiplier = 2.5
	var violet := teal.duplicate()
	violet.albedo_color = Color("#c35beb")
	violet.emission = Color("#c35beb")
	violet.emission_energy_multiplier = 1.5
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.12
	cone.height = 0.7
	cone.radial_segments = 5
	cone.rings = 1
	for i in mini(14, wall_feet.size()):
		var w: Vector2 = wall_feet[i]
		var cl := Node3D.new()
		cl.position = Vector3(w.x + m.rnd(-0.2, 0.2), 0.0, w.y + m.rnd(-0.2, 0.2))
		m.add_child(cl)
		for k in 3:
			var sc := m.rnd(0.6, 1.2)
			var sh := MeshInstance3D.new()
			sh.mesh = cone
			sh.material_override = teal
			sh.scale = Vector3.ONE * sc
			sh.position = Vector3(m.rnd(-0.18, 0.18), 0.35 * sc, m.rnd(-0.18, 0.18))
			sh.rotation = Vector3(m.rnd(-0.35, 0.35), m.rnd(0, TAU), m.rnd(-0.35, 0.35))
			cl.add_child(sh)
		var cll := OmniLight3D.new()
		cll.light_color = Color("#55efff")
		cll.light_energy = 1.2
		cll.omni_range = 3.0
		cll.position = Vector3(0, 0.6, 0)
		cl.add_child(cll)
	for i in range(14, mini(30, wall_feet.size())):
		var w: Vector2 = wall_feet[i]
		for k in 2:
			var at := Vector3(w.x + m.rnd(-0.3, 0.3), 0, w.y + m.rnd(-0.3, 0.3))
			var stem := m.box(Vector3(0.05, 0.16, 0.05), m.mat_color(Color("#d8d0e8")))
			stem.position = at + Vector3(0, 0.08, 0)
			m.add_child(stem)
			var capm := m.box(Vector3(0.2, 0.07, 0.2), violet)
			capm.position = at + Vector3(0, 0.18, 0)
			m.add_child(capm)
		if i % 4 == 0:
			var vl := OmniLight3D.new()
			vl.light_color = Color("#c35beb")
			vl.light_energy = 0.6
			vl.omni_range = 2.0
			vl.position = Vector3(w.x, 0.4, w.y)
			m.add_child(vl)
	# rubble along the walls gives a sense of scale
	var rubble_mat := ShaderMaterial.new()
	rubble_mat.shader = load("res://shaders/cave_stone.gdshader")
	rubble_mat.set_shader_parameter("lift", 2.2)
	for i in 50:
		var w: Vector2 = wall_feet[m.rng.randi() % wall_feet.size()]
		var r := m.rnd(0.12, 0.3)
		var rb := m.box(Vector3(r, r * 0.7, r), rubble_mat)
		rb.position = Vector3(w.x + m.rnd(-0.35, 0.35), r * 0.35, w.y + m.rnd(-0.35, 0.35))
		rb.rotation.y = m.rnd(0, PI)
		m.add_child(rb)
	# low mist drifting over the floor
	var mist := CPUParticles3D.new()
	mist.amount = 60
	mist.lifetime = 8.0
	mist.preprocess = 8.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(CAVE_W / 2.0, 0.1, CAVE_H / 2.0)
	mist.position = Vector3(Main.CAVE_X + CAVE_W / 2.0, 0.25, CAVE_H / 2.0)
	mist.direction = Vector3(1, 0, 0)
	mist.spread = 30.0
	mist.initial_velocity_min = 0.05
	mist.initial_velocity_max = 0.2
	mist.gravity = Vector3.ZERO
	mist.scale_amount_min = 3.0
	mist.scale_amount_max = 5.0
	var mq := QuadMesh.new()
	mq.size = Vector2(1, 1)
	var mm2 := StandardMaterial3D.new()
	mm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm2.albedo_color = Color(0.55, 0.75, 1.0, 0.06)
	mm2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mq.material = mm2
	mist.mesh = mq
	m.add_child(mist)
	# exit light at E
	var e: Vector2 = m.cave_marks.E
	var l := OmniLight3D.new()
	l.light_color = Color("#ffe0a0")
	l.light_energy = 3.0
	l.omni_range = 5.0
	l.position = Vector3(e.x - 0.5, 1.0, e.y)
	m.add_child(l)
	m.cave_light = OmniLight3D.new()
	m.cave_light.light_color = Color("#a8c8ff")
	m.cave_light.omni_range = 9.0
	m.cave_light.light_energy = 0.0
	m.add_child(m.cave_light)

# parchment map of the cave, drawn at its world offset so the minimap math stays the same
func cave_map_tex() -> ImageTexture:
	var img := Image.create(Main.CAVE_X + CAVE_W, CAVE_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for z in CAVE_H:
		for x in CAVE_W:
			var c: String = m.cave_grid[z][x]
			var col := Color(0, 0, 0, 0) if c == "#" else (Color("#3fe0e0") if c == "w" else Color("#2a5a8a"))
			if c == "D" and not m.cave_door_open:
				col = Color("#c8962a")
			if c == "E":
				col = Color("#ffd060")
			if c == "S":
				col = Color("#bfe6ff")
			if c == "K" and not m.has_key:
				col = Color("#ff9f5a")
			if c == "~":
				col = Color("#2f78b8")
			if c == "G" and m.post_q < 2:
				col = Color("#9fe0ff")
			if c == "M" and m.post_q < 3:
				col = Color("#ff9f5a")
			if c == "T":
				col = Color("#7a4a24")
			img.set_pixel(Main.CAVE_X + x, z, col)
	return m.with_up_marks(ImageTexture.create_from_image(img), [m.cave_marks.S, m.cave_marks.E])

# key chest, locked door and the wall painting with the rival's first appearance
func build_cave_props() -> void:
	# 솔이끼 at the wall feet, every third such tile (the owner, 2026-10-28; GPT's pick); its own random stream
	var dr = m.dressing
	dr.begin(1101)
	dr.plant({"stems": 7, "lo": 3, "hi": 8, "stem": "#487464", "leaf": "#263f3b", "leaves": "needle", "head": "moss",
		"petals": ["#8cb997", "#d0dda3"]}, 0.6, 0.25, dr.wall_feet(m.cave_grid, Main.CAVE_X, ".", "#", 3), 1, 0.05)
	dr.end()
	var k: Vector2 = m.cave_marks.K
	m.key_chest = Sprite3D.new()
	m.key_chest.texture = m.chest_open_tex if m.has_key else m.chest_shut_tex
	m.key_chest.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.key_chest.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.key_chest.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	m.key_chest.shaded = false
	m.key_chest.pixel_size = 0.05
	m.key_chest.offset = Vector2(0, 7)
	m.key_chest.scale = Vector3(1, 1.0 / cos(0.78), 1)
	m.key_chest.modulate = Color.WHITE if m.has_key else Color("#9fd4ff")
	m.key_chest.position = Vector3(k.x, 0.0, k.y)
	m.add_child(m.key_chest)
	var d: Vector2 = m.cave_marks.D
	m.door_node = Node3D.new()
	m.door_node.position = Vector3(d.x, 0, d.y)
	m.add_child(m.door_node)
	var wood := m.mat_color(Color("#7a4a24"))
	for i in 3:
		var plank := m.box(Vector3(0.3, 1.4, 0.9), wood)
		plank.position = Vector3(-0.32 + i * 0.32, 0.7, 0)
		m.door_node.add_child(plank)
	var lock := m.box(Vector3(0.2, 0.25, 0.95), m.mat_color(Color("#d9b04a")))
	lock.position = Vector3(0, 0.8, 0)
	m.door_node.add_child(lock)
	if m.cave_door_open: # opened before this load
		m.door_node.queue_free()
	var p: Vector2 = m.cave_marks.P
	var wall := m.box(Vector3(2.4, 1.2, 0.06), m.glow_mat(Color("#3a6aa8"), 1.2))
	wall.position = Vector3(p.x, 0.9, p.y - 1.45)
	m.add_child(wall)

# the altars: three stones under the first cave's west hall, but only the blue one wakes its skill there (whirl); the
# orange and yellow ones sleep and say where their light wakes: the ember in the castle's workshop (B1), the nova in
# the water-light grotto, each on an altar of its own. E or Space by an altar.
const ALTAR_COLS := [Color("#3a9cff"), Color("#ff7a1a"), Color("#ffd23a")] # whirl, ember, nova
const GROTTO_ALTAR := Vector2(8, 17)  # grotto tile, in the crab's room
const WORK_ALTAR := Vector2(5, 4)     # workshop B1 tile, in the first room

var altar_said: Array = [] # what a sleeping altar said last (autoplay shrine)

func build_shrine() -> void:
	for i in 3:
		build_altar(m.cave_marks[str(i + 1)], i, i == 0)
	build_altar(Vector2(m.grotto.GROTTO_X, 0) + GROTTO_ALTAR, 2, true)
	build_altar(Vector2(Main.WORK.FLOOR_X[0], 0) + WORK_ALTAR, 1, true)

func build_altar(at: Vector2, i: int, home: bool) -> void:
	var stone: Material = m.mat_color(Color("#6a6a74"))
	var cols := ALTAR_COLS
	var g := Node3D.new()
	g.set_meta("skill", i)
	g.set_meta("home", home)
	var post := m.box(Vector3(0.7, 0.8, 0.7), stone)
	post.position = Vector3(0, 0.4, 0)
	g.add_child(post)
	var gm := StandardMaterial3D.new() # flat unshaded colour: an additive glow would bloom to white in the cave
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = cols[i]
	var gem := m.box(Vector3(0.32, 0.32, 0.32), gm)
	gem.name = "gem"
	gem.position = Vector3(0, 1.15, 0)
	g.add_child(gem)
	g.position = Vector3(at.x, 0, at.y)
	m.add_child(g)
	m.shrine_nodes.append(g)
	m.rocks.append({"x": at.x, "z": at.y, "r": 0.5})

func update_shrine(dt: float) -> void:
	for c in m.crystals:
		c.hurt -= dt
	for i in m.shrine_nodes.size():
		var gem: Node3D = m.shrine_nodes[i].get_node("gem")
		var k: int = m.shrine_nodes[i].get_meta("skill")
		var lit: bool = m.woke[k]
		var asleep: bool = not lit and not m.shrine_nodes[i].get_meta("home") # a sleeping altar: a small, still gem
		gem.rotation.y += dt * (2.5 if lit else (0.0 if asleep else 0.6))
		gem.scale = Vector3.ONE * (1.4 + sin(m.t * 3.0) * 0.1 if lit else (0.6 if asleep else 1.0))
	if m.in_cave and not m.shrine_seen and m.player.z > 17.6 and not m.story_open:
		m.shrine_seen = true
		m.show_story("", Main.STORY.SHRINE_IN)
		m.save_game()

func spawn_crystals() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#9fe0ff")
	for i in CRYSTAL_AT.size():
		var at: Vector2 = CRYSTAL_AT[i] + Vector2(Main.CAVE_X, 0)
		var root := Node3D.new()
		var g := Node3D.new()
		root.add_child(g)
		var h: float = 1.8 - Main.CRYSTAL_NOTE[i] * 0.45 # tallest sings lowest
		var c := m.box(Vector3(0.36, h, 0.36), mat)
		c.position = Vector3(0, h / 2.0, 0)
		c.rotation.y = 0.6
		g.add_child(c)
		var c2 := m.box(Vector3(0.2, h * 0.6, 0.2), mat)
		c2.position = Vector3(0.24, h * 0.3, 0.1)
		c2.rotation = Vector3(0, 0.3, -0.3)
		g.add_child(c2)
		root.position = Vector3(at.x, 0, at.y)
		m.add_child(root)
		root.set_meta("body", g)
		m.crystals.append({"x": at.x, "z": at.y, "node": root, "crystal": i, "hurt": 0.0})
	for i in POST_CRYSTALS.size(): # the stream's end: one on each island, the same notes, a set of their own
		var at: Vector2 = POST_CRYSTALS[i] + Vector2(Main.CAVE_X, 0)
		var root := Node3D.new()
		var g := Node3D.new()
		root.add_child(g)
		var h: float = 1.8 - Main.CRYSTAL_NOTE[i] * 0.45
		var c := m.box(Vector3(0.36, h, 0.36), mat)
		c.position = Vector3(0, h / 2.0, 0)
		c.rotation.y = 0.6
		g.add_child(c)
		root.position = Vector3(at.x, 0, at.y)
		m.add_child(root)
		root.set_meta("body", g)
		m.crystals.append({"x": at.x, "z": at.y, "node": root, "crystal": i, "hurt": 0.0, "set": 1})

func build_crystal_chest() -> void:
	m.crystal_chest = Node3D.new()
	for part in [[Vector3(0.8, 0.45, 0.55), Vector3(0, 0.22, 0), m.mat_color(Color("#3a5a7a"))], [Vector3(0.84, 0.1, 0.59), Vector3(0, 0.5, 0), m.glow_mat(Color("#9fe0ff"), 1.0)]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		m.crystal_chest.add_child(b)
	m.crystal_chest.position = Vector3(Main.CAVE_X + 7.0, 0, 21.0)
	m.crystal_chest.visible = m.crystal_done and not m.has_ring
	m.add_child(m.crystal_chest)

# a ringing crystal shows its rank as dots above it (1 for the lowest note → 4), so the order can be read with the sound off
# (delight idea 88). Drawn on the same hit as the note; the puzzle rules do not look at them.
const DOT_STAY := 0.9
var dot_cues: Array = [] # ranks shown, in order (autoplay d88_dots)

func dot_cue(e: Dictionary, rank: int) -> void:
	var old = e.get("dots") # may be an instance already freed
	if is_instance_valid(old):
		old.queue_free()
	var row := Node3D.new()
	var mat: StandardMaterial3D = m.glow_mat(Color("#d8f4ff"), 1.0)
	for k in rank + 1:
		var d := m.box(Vector3(0.1, 0.1, 0.1), mat)
		d.position = Vector3((k - rank * 0.5) * 0.2, 0, 0)
		row.add_child(d)
	row.position = Vector3(e.x, 2.15, e.z)
	m.add_child(row)
	e["dots"] = row
	dot_cues.append(rank)
	m.get_tree().create_timer(DOT_STAY).timeout.connect(func(): if is_instance_valid(row): row.queue_free())

func crystal_hit(e: Dictionary) -> void:
	if e.hurt > 0.0:
		return # one sword swing rings it once
	e.hurt = 0.25
	var rank: int = Main.CRYSTAL_NOTE[int(e.crystal)]
	m.sfx(NOTES[rank], 0.5, "sine", 0.3)
	dot_cue(e, rank)
	m.burst(Vector3(e.x, 1.0, e.z), Color("#9fe0ff"), 8, 1.5)
	(e.node.get_meta("body") as Node3D).scale = Vector3.ONE * 1.12
	m.get_tree().create_timer(0.15).timeout.connect(func(): if is_instance_valid(e.node): (e.node.get_meta("body") as Node3D).scale = Vector3.ONE)
	if e.get("set", 0) == 1:
		post_crystal(rank)
		return
	if m.crystal_done:
		return
	if not m.crystal_told:
		m.crystal_told = true
		m.toast("수정이 맑게 운다. 낮은 소리부터 차례로 울려 볼까?")
	if rank == m.crystal_run:
		m.crystal_run += 1
		if m.crystal_run == NOTES.size():
			m.crystal_done = true
			m.crystal_chest.visible = true
			m.burst(m.crystal_chest.position + Vector3(0, 0.6, 0), Color("#9fe0ff"), 30, 3.0)
			for k in 4:
				m.get_tree().create_timer(0.12 * k).timeout.connect(func(): m.sfx(NOTES[k] * 2.0, 0.3, "sine", 0.2))
			m.toast("수정들이 함께 울리자 상자가 솟아올랐다")
			m.save_game()
	else:
		m.crystal_run = 1 if rank == 0 else 0
		m.get_tree().create_timer(0.2).timeout.connect(func(): m.sfx(110, 0.25, "square", 0.15))

func crystal_chest_key() -> bool:
	if not m.crystal_done or m.tokens[1] or Vector2(m.player.x, m.player.z).distance_to(Vector2(m.crystal_chest.position.x, m.crystal_chest.position.z)) > 1.6:
		return false
	var first: bool = not m.has_ring # a new round keeps the ring: the chest only lights this round's token
	m.has_ring = true
	for b in m.crystal_chest.get_children():
		b.transparency = 0.45
	m.burst(m.crystal_chest.position + Vector3(0, 0.8, 0), Color("#9fe0ff"), 40, 3.0)
	m.sfx(784, 0.12, "triangle", 0.25)
	if first:
		m.show_story("", Main.STORY.CRYSTAL_RING)
	m.moon_tokens.earn(m.moon_tokens.RING)
	m.save_game()
	return true

func shrine_key() -> bool:
	if crystal_chest_key():
		return true
	var me := Vector2(m.player.x, m.player.z)
	for g in m.shrine_nodes:
		var at := Vector2(g.position.x, g.position.z)
		if me.distance_to(at) < 1.4:
			var i: int = g.get_meta("skill")
			if not g.get_meta("home"):
				altar_said = Main.STORY.SHRINE_ASLEEP[i - 1]
				m.show_story("", altar_said)
				return true
			if m.woke[i]:
				m.toast("이미 깨어난 기술이다")
				return true
			m.woke[i] = true
			if m.in_cave and m.has_skip and not m.cave_exit_seen:
				exit_quest()
			m.burst(Vector3(at.x, 1.2, at.y), [Color("#9fd4ff"), Color("#ff8a2a"), Color("#fff1a0")][i], 30, 3.0)
			m.sfx(523, 0.15, "triangle", 0.22)
			m.get_tree().create_timer(0.12).timeout.connect(func(): m.sfx(784, 0.25, "triangle", 0.22))
			m.show_story("", [Main.STORY.SHRINE_WHIRL, Main.STORY.SHRINE_EMBER, Main.STORY.SHRINE_NOVA][i])
			m.save_game()
			return true
	return false

func build_post_props() -> void:
	m.post_gate = Node3D.new()
	var bar: Material = m.glow_mat(Color("#9fe0ff"), 1.2)
	for k in 5:
		var b := m.box(Vector3(0.12, 1.3, 0.12), bar)
		b.position = Vector3(-0.85 + k * 0.42, 0.65, 0)
		m.post_gate.add_child(b)
	var top := m.box(Vector3(2.0, 0.14, 0.16), m.mat_color(Color("#4a5a6a")))
	top.position = Vector3(0, 1.32, 0)
	m.post_gate.add_child(top)
	m.post_gate.position = Vector3(m.cave_marks.G.x + 0.5, 0, m.cave_marks.G.y)
	m.add_child(m.post_gate)
	var crates := Node3D.new()
	for part in [[Vector3(0.7, 0.5, 0.6), Vector3(0, 0.25, 0), Color("#7a4a24")], [Vector3(0.5, 0.4, 0.5), Vector3(0.45, 0.2, 0.4), Color("#8a5a32")], [Vector3(0.5, 0.3, 0.5), Vector3(-0.1, 0.65, 0.05), Color("#a07a4a")]]:
		var cb := m.box(part[0], m.mat_color(part[2]))
		cb.position = part[1]
		crates.add_child(cb)
	crates.position = Vector3(m.cave_marks.T.x, 0, m.cave_marks.T.y)
	m.add_child(crates)
	m.post_pile = Node3D.new()
	for part in [[Vector3(0.9, 0.3, 0.7), Vector3(0, 0.15, 0), m.mat_color(Color("#6a5a4a"))], [Vector3(0.5, 0.25, 0.5), Vector3(0.2, 0.42, 0.1), m.mat_color(Color("#8a6a4a"))], [Vector3(0.32, 0.03, 0.22), Vector3(-0.1, 0.33, -0.1), m.glow_mat(Color("#f2ead8"), 1.0)]]:
		var pb := m.box(part[0], part[2])
		pb.position = part[1]
		m.post_pile.add_child(pb)
	m.post_pile.position = Vector3(m.cave_marks.M.x, 0, m.cave_marks.M.y)
	m.post_pile.set_meta("card", m.post_pile.get_child(2))
	m.add_child(m.post_pile)

func post_crystal(rank: int) -> void:
	if m.post_q >= 2:
		return
	if not m.post_told:
		m.post_told = true
		m.toast("섬마다 수정이 하나씩. 여기서도 낮은 소리부터일까?")
	if rank == m.post_run:
		m.post_run += 1
		if m.post_run == NOTES.size():
			post_gate_open()
	else:
		m.post_run = 1 if rank == 0 else 0
		m.get_tree().create_timer(0.2).timeout.connect(func(): m.sfx(110, 0.25, "square", 0.15))

func post_gate_open() -> void:
	m.post_q = 2
	for k in 4:
		m.get_tree().create_timer(0.12 * k).timeout.connect(func(): m.sfx(NOTES[k] * 2.0, 0.3, "sine", 0.2))
	var tw := m.create_tween()
	tw.tween_property(m.post_gate, "position:y", -1.5, 1.0)
	tw.tween_callback(func(): m.post_gate.visible = false)
	m.burst(m.post_gate.position + Vector3(0, 0.6, 0), Color("#9fe0ff"), 30, 3.0)
	for f in POST_AMBUSH:
		m.spawn_enemy(Vector2(Main.CAVE_X + f[0], f[1]), f[2])
	m.show_story("", Main.STORY.POST_GATE)
	m.ui.mini.map_tex = cave_map_tex()
	m.save_game()

func post_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if me.y < 20.5:
		return false
	if me.distance_to(m.cave_marks.T) < 1.5:
		m.show_story("", Main.STORY.POST_CART)
		return true
	if m.post_q == 2 and me.distance_to(m.cave_marks.M) < 1.6:
		m.post_q = 3
		m.player.max_hp += 10
		m.player.hp = float(m.player.max_hp)
		m.player.pots += 2
		(m.post_pile.get_meta("card") as Node3D).visible = false
		m.burst(m.post_pile.position + Vector3(0, 0.6, 0), Color("#f2ead8"), 24, 2.5)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.show_story("", post_card_lines())
		m.ui.mini.map_tex = cave_map_tex()
		m.save_game()
		return true
	return false

# after BORI_LETTER (doran_q >= 3) Sora knows who Hangyeol was (GPT playtest 5)
func post_card_lines() -> Array:
	var lines: Array = Main.STORY.POST_CARD.duplicate()
	if m.doran_q >= 3:
		lines[4] = Main.STORY.POST_CARD_KNOWN
	return lines

func update_post() -> void:
	var me := Vector2(m.player.x, m.player.z)
	var sub := "물길 끝 굴" if me.y > 20.5 else "벽 그림이 있는 동굴"
	if m.ui.zone_sub.text != sub and (m.ui.zone_sub.text == "물길 끝 굴" or m.ui.zone_sub.text == "벽 그림이 있는 동굴"):
		m.ui.zone_sub.text = sub
	if m.story_open:
		return
	# by the shut grate of the south room: say what opens it, once per visit to it (the owner, 2026-10-25: the room
	# looked like one that could not be entered at all)
	var at_gate := m.post_q < 2 and me.distance_to(m.cave_marks.G + Vector2(0.5, 0)) < 2.2
	if at_gate and not gate_told:
		if m.has_skip:
			m.toast("창살이 잠겨 있다. 물웅덩이 섬의 수정 넷을 낮은 소리부터 울리면 열릴 것 같다")
			if m.post_q == 0:
				m.post_q = 1 # the journal and the line under the quest pick it up
				m.save_game()
		else:
			m.toast("창살이 잠겨 있다. 물 위 섬에 건너갈 걸음부터 찾자 (수레두더지 너머)")
	gate_told = at_gate or (gate_told and me.distance_to(m.cave_marks.G + Vector2(0.5, 0)) < 3.5)
	if m.has_skip and m.post_q == 0 and me.distance_to(Vector2(Main.CAVE_X + 26, 20)) < 2.0:
		m.post_q = 1
		m.show_story("", Main.STORY.POST_STREAM)
		m.save_game()
		return
	if m.post_q == 1 and me.y > 26.5 and not m.post_spawned:
		m.post_spawned = true
		for f in POST_SPAWNS:
			m.spawn_enemy(Vector2(Main.CAVE_X + f[0], f[1]), f[2])
		for b in POST_BATS:
			m.spawn_bat(b)

func cave_interact() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	if shrine_key():
		return true
	# the mural again, once its scene has played: the picture alone with one line (the owner, 2026-10-27)
	if m.saw_painting and me.distance_to(m.cave_marks.P) < 2.0:
		m.show_story(Main.MURAL_PICTURE, [Main.STORY.MURAL_AGAIN])
		return true
	if not m.has_key and me.distance_to(m.cave_marks.K) < 1.5:
		m.has_key = true
		m.key_chest.texture = m.chest_open_tex
		m.key_chest.modulate = Color.WHITE
		m.burst(m.key_chest.position + Vector3(0, 0.6, 0), Color("#ffd84a"), 24, 2.5)
		m.sfx(784, 0.12, "triangle", 0.25)
		m.toast("녹슨 열쇠를 얻었다")
		if not m.has_skip and m.quest_raw.begins_with("열쇠를 찾아"): # painting first, then the chest: the line moves on to the door
			m.set_quest("얻은 열쇠로 잠긴 문을 열자")
		m.ui.mini.map_tex = cave_map_tex()
		m.save_game() # kept at once: a reload used to put the key back in the chest (the owner, 2026-10-25)
		return true
	if not m.cave_door_open and me.distance_to(m.cave_marks.D) < 1.6:
		if m.has_key:
			m.cave_door_open = true
			m.door_node.queue_free()
			m.sfx(330, 0.3, "square", 0.2, 200)
			m.toast("문이 열렸다")
			m.ui.mini.map_tex = cave_map_tex()
			if not m.has_skip: # the painting's "find the key" line used to stay up past the open door (GPT playtest 5)
				m.set_quest(Main.CAVE_DOOR_QUEST)
			m.save_game() # always: with the mole already beaten the open door was never saved and locked again on a reload
		else:
			m.toast("잠겨 있다. 열쇠가 필요하다")
		return true
	return false

func check_painting() -> void:
	if m.saw_painting or Vector2(m.player.x, m.player.z).distance_to(m.cave_marks.P) > 2.0:
		return
	m.saw_painting = true
	if m.night_q >= 1: # Noeul has already come for the crown: his first meeting would come twice (the owner, 2026-10-25)
		m.show_story(Main.MURAL_PICTURE, Main.STORY.PAINTING_LATE + (Main.STORY.PAINTING_WITH_NOEUL if m.mate2 != null else []))
	else:
		m.show_story(Main.MURAL_PICTURE, Main.STORY.PAINTING)
	if m.has_skip and not m.cave_exit_seen: # seen after the mole: the way-out line moves on (v0.1.46)
		exit_quest()
	elif m.has_skip: # seen on a later visit: the quest she has stays (GPT playtests 2 -> 9)
		pass
	elif m.cave_door_open:
		m.set_quest(Main.CAVE_DOOR_QUEST)
	elif m.has_key:
		m.set_quest("얻은 열쇠로 잠긴 문을 열자")
	else:
		m.set_quest("열쇠를 찾아 잠긴 문을 열자")
	m.save_game()

func enter_cave() -> void:
	m.in_cave = true
	if not m.cave_spawned:
		m.cave_spawned = true
		build_cave_props()
		if not m.has_skip: # beaten in an earlier run (GPT playtests 2 -> 9)
			spawn_mole()
		for c in CAVE_SPAWNS:
			m.spawn_enemy(Vector2(Main.CAVE_X + c[0], c[1]), c[2])
		for b in Main.BAT_SPOTS:
			if b.x < Main.CASTLE.CASTLE_X:
				m.spawn_bat(b)

	m.story_step = maxi(m.story_step, 6)
	var sp: Vector2 = m.cave_marks.S
	m.player.x = sp.x
	m.player.z = sp.y
	m.ground_y = 0.0
	m.snap_mates() # companions come down with her
	if m.story_step <= 7:
		m.quest_before_cave = ""
	elif m.ui.quest.text != "" or m.quest_before_cave == "": # after a faint inside the line was empty (GPT playtests 2 -> 9)
		m.quest_before_cave = m.quest_raw
	m.set_quest("동굴 깊은 곳으로" if m.story_step <= 7 else "")
	m.ui.outside_map = m.ui.mini.map_tex
	m.ui.mini.map_tex = cave_map_tex()
	m.ui.zone_name.text = "지하 동굴"
	m.ui.zone_sub.text = "벽 그림이 있는 동굴"
	m.save_game()

var exit_built := false

func exit_mouth_pos() -> Vector2:
	for c in [Vector2(36, 18.2), Vector2(34.2, 20), Vector2(37.8, 20), Vector2(36, 21.8)]:
		if m.walkable(c.x, c.y):
			return c
	return Vector2(36, 18.2)

func build_exit_mouth() -> void:
	if exit_built:
		return
	exit_built = true
	var at := exit_mouth_pos()
	m.story.clear_vegetation(at, 1.8)
	var g := Node3D.new()
	g.position = Vector3(at.x, m.height_at(at.x, at.y), at.y)
	m.add_child(g)
	var pit := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 0.9
	cyl.height = 0.05
	pit.mesh = cyl
	pit.material_override = m.mat_color(Color("#07070c"))
	pit.position = Vector3(0, 0.03, 0)
	g.add_child(pit)
	var stone := m.mat_color(Color("#6a6e7a"))
	for k in 10:
		var a := TAU * k / 10.0
		var b := m.box(Vector3(0.42, 0.3, 0.42), stone)
		b.position = Vector3(cos(a) * 1.1, 0.15, sin(a) * 1.1)
		b.rotation.y = -a
		g.add_child(b)
	for k in 3:
		var st := m.box(Vector3(0.7, 0.06, 0.24), m.mat_color(Color("#4a4e5a").darkened(k * 0.25)))
		st.position = Vector3(0, 0.06 - k * 0.02, 0.55 - k * 0.27)
		g.add_child(st)
	var glow := OmniLight3D.new()
	glow.light_color = Color("#6aa8ff")
	glow.light_energy = 1.2
	glow.omni_range = 2.5
	glow.position = Vector3(0, 0.3, 0)
	g.add_child(glow)
	var outside: ImageTexture = m.ui.outside_map if m.ui.has("outside_map") else m.ui.mini.map_tex
	if outside != null and (m.ui.has("outside_map") or not m.in_cave):
		outside.set_image(m.with_stair_marks(outside, [at]).get_image())

# walking onto the stair outside: back down at the cave's far end, a little inside from the way out
func enter_from_exit() -> void:
	m.enter_cave()
	var e: Vector2 = m.cave_marks.E
	var inward: Vector2 = (m.cave_marks.S - e).normalized()
	m.player.x = e.x + inward.x * 2.2
	m.player.z = e.y + inward.y * 2.2
	m.snap_mates()

# what still keeps her in on the first way out ("" = free to go)
func exit_blocker() -> String:
	if not m.has_skip:
		return "바깥 빛이 보인다. 하지만 수레두더지가 길을 막고 있다"
	if m.cave_exit_seen:
		return ""
	var left: Array = []
	if not m.saw_painting:
		left.append(tr("벽 그림 보기"))
	if not m.woke[0]:
		left.append(tr("서쪽 푸른 돌단에서 회오리 깨우기"))
	if left.is_empty():
		return ""
	return tr("아직 나갈 수 없다. 동굴에서 남은 일: %s") % ", ".join(left)

func leave_cave() -> void:
	m.in_cave = false
	var first_time := m.story_step <= 7
	m.story_step = maxi(m.story_step, 7) # a later visit must not wind the story back
	m.player.x = 36.0 # east marsh shore
	m.player.z = 20.0
	m.ground_y = m.height_at(m.player.x, m.player.z)
	m.snap_mates()
	var back := m.quest_before_cave if m.quest_before_cave != "" else m.main_road_quest() # older saves kept no quest
	m.set_quest("동쪽 강을 물수제비 걸음으로 건너, 마을 불빛을 찾아라" if first_time else back)
	if not first_time:
		m.moon_tokens.refresh_quest() # a token earned inside (the crystal ring) skipped its refresh: the kept line may be stale
	if m.ui.has("outside_map"):
		m.ui.mini.map_tex = m.ui.outside_map
	m.ui.zone_name.text = "갈대늪"
	m.ui.zone_sub.text = "동쪽 물가"
	m.save_game()
	var first := not m.cave_exit_seen
	m.cave_exit_seen = true
	build_exit_mouth()
	if first:
		m.show_story("", Main.STORY.CAVE_EXIT)
	else:
		exit_motes()

# stepping out of the cave on an ordinary visit, two grains of cave dust cling to her clothes, brighten in the daylight for
# a third of a second, then drop and fade (delight idea 36). Not on the first way out, which has its story.
var exit_motes_made := 0 # grains made (autoplay d36_cave_dust)

func exit_motes() -> void:
	for k in 2:
		exit_motes_made += 1
		var grain: MeshInstance3D = m.box(Vector3(0.05, 0.05, 0.05), m.glow_mat(Color("#d8c8a8"), 1.5))
		var cling := Vector3(-0.2 + 0.4 * k, 0.75 + 0.2 * k, 0.08)
		var at := Vector3(m.player.x, m.ground_y, m.player.z) + cling
		grain.position = at
		grain.set_meta("at", at)
		m.effects.add_fx(grain, 1.5, func(node: Node3D, f: float, _dt: float):
			var mat := (node as MeshInstance3D).material_override as StandardMaterial3D
			if f < 0.35: # clinging to her: moves with her, glowing up
				node.position = Vector3(m.player.x, m.ground_y, m.player.z) + cling
				node.set_meta("at", node.position)
				mat.albedo_color.a = 0.25 + f / 0.35 * 0.75
			else: # shaken loose: falls, fades
				var g := (f - 0.35) / 0.65
				node.position = (node.get_meta("at") as Vector3) + Vector3(0, -g * g * 0.7, 0)
				mat.albedo_color.a = 1.0 - g)

# ---------------------------------------------------------------- 굴파기 수레두더지 (cave mid-boss)
# Charge: 1.0 s wind-up, then a straight dash at 9 tiles/s until it hits a wall (stuck 1.5 s, takes x1.5).
# Dirt: a 0.7 s red ring under Sora, then earth bursts up (two rings below half health).
func spawn_mole() -> void:
	var b: Vector2 = m.cave_marks.B
	var node := m.monsters.make_monster(true)
	var mats: Array = node.get_meta("mats")
	mats[2].albedo_color = Color("#6a4a2a") # brown body
	mats[5].albedo_color = Color("#3a2a20") # dark snout head
	node.scale = Vector3.ONE * 2.2
	var g: Node3D = node.get_meta("body")
	for side in [-0.32, 0.32]: # cart wheels
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.16
		cyl.bottom_radius = 0.16
		cyl.height = 0.08
		wheel.mesh = cyl
		wheel.material_override = m.mat_color(Color("#c8962a"))
		wheel.rotation.z = PI / 2
		wheel.position = Vector3(side, 0.12, 0.18)
		g.add_child(wheel)
	m.add_child(node)
	m.enemies.append({"x": b.x, "z": b.y, "hp": 1430.0, "max_hp": 1430, "node": node, "shadow": m.blob(1.8), "t": 0.0,
		"atk_cd": 2.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": b.x, "wz": b.y, "dead": false, "respawn": 0.0,
		"mole": true, "cave": true, "wind": 0.0, "dash": 0.0, "dir": Vector2.ZERO, "stun": 0.0, "next": "charge", "rings": []})

# the mole's room is shut while the door is locked: nothing crosses it either way (GPT lap 7: hits through the door killed it)
func mole_shut_out() -> bool:
	return not m.cave_door_open and m.in_cave and m.player.x < m.cave_marks.D.x + 0.5

func update_mole(e: Dictionary, dt: float, d: float, to: Vector2) -> void:
	var node: Node3D = e.node
	if d < 9.5 and not mole_shut_out(): # its page, just before it wakes at 8 tiles; not through the locked door
		m.story.boss_intro("cart_mole")
	var awake := d < 8.0 and not mole_shut_out()
	if not m.cave_door_open: # leashed inside: never nearer than 1.6 tiles to the door
		e.x = maxf(e.x, m.cave_marks.D.x + 1.6)
	m.ui.boss.visible = awake or (m.ui.boss.visible and d < 12.0)
	m.ui.boss_name.text = "굴파기 수레두더지"
	m.ui.boss_bar.size.x = 420.0 * maxf(0.0, e.hp) / e.max_hp
	e.t += dt
	e.hurt -= dt
	e.stun -= dt
	var me := Vector2(e.x, e.z)
	if e.dash > 0.0:
		e.dash -= dt
		var nx: float = e.x + e.dir.x * 11.0 * dt
		var nz: float = e.z + e.dir.y * 11.0 * dt
		if m.walkable(nx, nz):
			e.x = nx
			e.z = nz
			if Vector2(m.player.x - e.x, m.player.z - e.z).length() < 1.1:
				m.player_hit(34 + m.boss_extra(), me - e.dir, e)
		else: # crashed into the wall; hurt, it turns and charges once more before it reels
			e.dash = 0.0
			if e.hp < e.max_hp / 2.0 and not e.get("again", false):
				e.again = true
				e.wind = 0.45
				e.dir = to / maxf(d, 0.01)
				e.next = "charge"
				m.pop_num(Vector3(e.x, 2.6, e.z), "!", Color("#ff5a4a"))
			else:
				e.again = false
				e.stun = 1.1
			m.shake = 0.35
			m.sfx(80, 0.3, "square", 0.3, -40)
			m.burst(Vector3(e.x, 0.6, e.z), Color("#8a7a6a"), 20, 3.0)
	elif e.stun > 0.0:
		pass
	elif e.wind > 0.0:
		e.wind -= dt
		if e.wind <= 0.0:
			if e.next == "charge":
				e.dash = 1.2
				e.next = "burrow" if e.hp < e.max_hp / 2.0 and not e.get("again", false) else "dirt"
			elif e.next == "burrow": # up from under the ring it hid beneath
				var r: Vector2 = e.rings[0]
				e.x = r.x
				e.z = r.y
				node.visible = true
				e.shadow.visible = true
				m.burst(Vector3(r.x, 0.3, r.y), Color("#8a6a4a"), 30, 4.5)
				m.shake = 0.4
				m.sfx(60, 0.3, "square", 0.3, -20)
				if Vector2(m.player.x, m.player.z).distance_to(r) < 1.4:
					m.player_hit(30 + m.boss_extra(), r, e)
				e.next = "dirt"
			else:
				for r in e.rings:
					m.burst(Vector3(r.x, 0.3, r.y), Color("#8a6a4a"), 18, 3.5)
					if Vector2(m.player.x, m.player.z).distance_to(r) < 1.2:
						m.player_hit(24 + m.boss_extra(), r, e)
				m.sfx(70, 0.25, "square", 0.25, -30)
				e.next = "charge"
			e.atk_cd = 0.8 if e.hp < e.max_hp / 2.0 else 1.1
	elif awake:
		e.atk_cd -= dt
		if e.atk_cd <= 0.0:
			if e.next == "charge":
				e.wind = 1.0
				e.dir = to / maxf(d, 0.01)
				m.pop_num(Vector3(e.x, 2.6, e.z), "!", Color("#ff5a4a"))
				m.sfx(120, 0.5, "sawtooth", 0.2, 120)
			elif e.next == "burrow": # dives into the earth; a ring marks where it will come up
				e.wind = 0.9
				e.rings = [Vector2(m.player.x, m.player.z)]
				node.visible = false
				e.shadow.visible = false
				m.burst(Vector3(e.x, 0.3, e.z), Color("#8a6a4a"), 20, 3.0)
				m.warn_ring(Vector3(m.player.x, 0.0, m.player.z), 1.4, 0.9)
			else:
				e.wind = 0.7
				var me2 := Vector2(m.player.x, m.player.z)
				e.rings = [me2]
				for k in (4 if e.hp < e.max_hp / 2.0 else 2): # around her, so a dodge must pick its way out
					var a := TAU * k / (4.0 if e.hp < e.max_hp / 2.0 else 2.0) + m.rnd(0.0, 1.0)
					e.rings.append(me2 + Vector2(cos(a), sin(a)) * m.rnd(1.8, 2.6))
				for r in e.rings:
					m.warn_ring(Vector3(r.x, 0.0, r.y), 1.2, 0.7)
		elif d > 2.0: # trundle toward Sora
			var nx: float = e.x + to.x / d * 1.8 * dt
			var nz: float = e.z + to.y / d * 1.8 * dt
			if m.walkable(nx, e.z): e.x = nx
			if m.walkable(e.x, nz): e.z = nz
	node.position = Vector3(e.x, absf(sin(e.t * (12.0 if e.dash > 0 else 3.0))) * 0.08, e.z)
	var face: Vector2 = e.dir if e.dash > 0.0 or e.wind > 0.0 else to
	if face.length() > 0.1:
		node.rotation.y = atan2(face.x, face.y)
	var glowing: bool = e.hurt > 0 or e.wind > 0.0 or e.stun > 0.0
	for mm in node.get_meta("mats"):
		mm.emission_enabled = glowing
		mm.emission = Color("#ff3a2a") if e.wind > 0.0 else (Color("#9fd4ff") if e.stun > 0.0 else Color.WHITE)
		mm.emission_energy_multiplier = 0.9
	e.shadow.position = Vector3(e.x, 0.02, e.z)

func mole_defeated() -> void:
	m.ui.boss.visible = false
	if m.has_skip: # the first win's lines, quest and skip only once
		return
	m.has_skip = true
	m.ui.boss.visible = false
	exit_quest()
	m.save_game()
	m.show_story("res://art/story/07_water_skip.jpg", Main.STORY.WATER_SKIP)

# after the mole: what is still left before the first way out, or the way out itself
func exit_quest() -> void:
	if not m.saw_painting and not m.woke[0]:
		m.set_quest("나가기 전에 벽 그림을 보고, 서쪽 푸른 돌단에서 회오리를 깨우자 (E)")
	elif not m.saw_painting:
		m.set_quest("나가기 전에 동굴 깊은 곳의 벽 그림을 보자")
	elif not m.woke[0]:
		m.set_quest("나가기 전에 서쪽 푸른 돌단에서 회오리를 깨우자 (E)")
	else:
		m.set_quest("동쪽 출구로 나가자 (Shift를 누르고 물 위를 달릴 수 있다)")
