# 달의 계단 (chapter 8, before the heart of the garden): a 24x30 climb at x >= STAIRS_X from the castle's east gate (S)
# up to the garden (N). Four landings, each asking for a different power of the crown: a brick wall (W) to unwind,
# a deep channel (~) for the water skip, a broken drop (_) crossed by the vent (^, and v back down), and a moon door (D)
# that opens once the three lanterns (o) on the top landing are lit. Sora counts as "on the hill" here.
extends RefCounted

const STAIRS_X := 500
const W := 24
const H := 30
const ROWS := """###########NN###########
##########....##########
##########DDDD##########
###..................###
###..o............o..###
###L..s....o..v.s...L###
###..................###
###__________________###
###__________________###
###__________________###
###__________________###
###........^.........###
###...............a..###
###L.a..............L###
###.........g........###
###..................###
###~~~~~~~~~~~~~~~~~~###
###~~~~~~~~~~~~~~~~~~###
###~~~~~~~~~~~~~~~~~~###
###..................###
###............w.....###
###L..w.............L###
###......b.......w...###
###..................###
##########WWWW##########
###..................###
###...........g......###
###L................L###
###..................###
###########SS###########"""
const VENTS := {"^": Vector2(0, -1), "v": Vector2(0, 1)}

var grid: Array = []
var marks := {}          # S foot (from the castle), N top (to the garden) -> world Vector2
var foes: Array = []     # [world Vector2, kind]
var wall_open := false
var lamps: Array = []    # [{"pos": Vector2, "lit": bool, "glass": MeshInstance3D, "light": OmniLight3D}]
var door_open := false
var wall_nodes: Array = []
var door: Node3D

func _init() -> void:
	for line in ROWS.split("\n"):
		grid.append(line)

func char_at(x: float, z: float) -> String:
	var tx := int(round(x)) - STAIRS_X
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= W or tz >= H:
		return "#"
	return grid[tz][tx]

func vent_at(x: float, z: float) -> Vector2:
	return VENTS.get(char_at(x, z), Vector2.ZERO)

func blocked(x: float, z: float) -> bool:
	var c := char_at(x, z)
	if c == "W":
		return not wall_open
	if c == "D":
		return not door_open
	return c == "#" or c == "~" or c == "_" or c == "o"

func lamps_lit() -> int:
	return lamps.filter(func(l): return l.lit).size()

# the marsh's look on the moon stairs (DESIGN.md, section 다른 지역도 늪만큼 보기 좋게): the pale steps get a worn,
# speckled top over grey stone sides, and a fringe of silver-green moon grass with small pale flowers grows only
# along the side walls. Nothing grows on or next to the brick wall, the moon door, the channel, the drop, a vent, a
# lamp, a lantern or the stairs in and out, and the middle of each landing stays bare.
const GRASS_CLEAR := "WD~_o^vNSL"
var grass_tiles: Array = [] # world tiles that got moon grass (all next to a side wall)
var dress_meshes: Array = []

func dress(m: Node, ground: Array) -> void:
	var d = m.dressing
	d.begin(5001)
	var tops: Array = []
	for g in ground: # the step's own moonlit shade, a little lighter: the picture's greys darken it back
		tops.append([g[0], (g[1] as Color).lightened(0.1)])
	d.ground_blocks(tops, STAIRS_X, d.speckle_tex([Color("#d0d0dc"), Color("#e2e2ec"), Color("#e2e2ec"), Color("#f2f2f8")]), Color(0.42, 0.4, 0.48))
	var at := func(x: int, z: int) -> String: return char_at(STAIRS_X + x, z)
	for t in d.pick_tiles(at, STAIRS_X, W, 0, H, ".wagsb", GRASS_CLEAR, []):
		if d.near_clear(at, int(t.x) - STAIRS_X, int(t.y), "#", []):
			grass_tiles.append(t)
	var tuft: Texture2D = d.tuft_tex(["#4e6a5e", "#5a7868", "#668672", "#76947e", "#8aa690", "#a4bcaa", "#c8dacc"], 0.25, 3,
		["#f4f0ff", "#d8ccff", "#fff6d8"])
	dress_meshes.append(d.grass(tuft, 0.7, 0.38, d.spots_on(grass_tiles, 0.0, 3, 0.65, 1.0), 0.1, false))
	# 솜다리 by the stair walls, every other moon-grass tile (the owner, 2026-10-28; GPT's pick)
	var edel: Array = grass_tiles.filter(func(t): return int(t.x + t.y) % 2 == 0)
	d.plant({"stems": 3, "lo": 8, "hi": 16, "stem": "#92a49a", "leaf": "#526b65", "leaves": "needle", "head": "star", "n": 6, "r": 3,
		"petals": ["#f7f0d9", "#d9ddd4", "#ffffff"], "centre": "#e6d48a"}, 0.65, 0.42, edel, 1, 0.09)
	d.end()

func build(m: Node) -> void:
	var blocks: Array = []
	var ground: Array = [] # [Transform3D, Color] of the steps, drawn by dress
	var lamp_spots: Array = []
	for z in H:
		for x in W:
			var c: String = grid[z][x]
			var w := Vector2(STAIRS_X + x, z)
			if c == "S" or c == "N":
				if not marks.has(c):
					marks[c] = w + Vector2(0.5, 0)
			if c in "wagsb":
				foes.append([w, c])
			if c == "L":
				lamp_spots.append(w)
			match c:
				"#":
					var near := false
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx: int = x + d.x
						var nz: int = z + d.y
						if nx >= 0 and nz >= 0 and nx < W and nz < H and grid[nz][nx] != "#":
							near = true
					if near:
						blocks.append([Transform3D(Basis().scaled(Vector3(1, 1.0, 1)), Vector3(w.x, 0.1, w.y)), Color("#6e6a78").lightened(m.rnd(0, 0.06))])
				"~":
					blocks.append([Transform3D(Basis().scaled(Vector3(1, 0.05, 1)), Vector3(w.x, -0.38, w.y)), Color("#2a5a8a").lightened(m.rnd(0, 0.06))])
				"_":
					if m.rng.randf() < 0.25:
						blocks.append([Transform3D(Basis().scaled(Vector3(0.8, 0.3, 0.8)), Vector3(w.x, -2.4, w.y)), Color("#3a3646")])
				_:
					# pale stone steps that grow lighter, as if moonlit, toward the top
					var up := 1.0 - z / float(H)
					var col := Color("#8a8494").lerp(Color("#c8c4d8"), up)
					if (x + z) % 2 == 0:
						col = col.darkened(0.05)
					ground.append([Transform3D(Basis().scaled(Vector3(1, 0.4, 1)), Vector3(w.x, -0.2, w.y)), col.lightened(m.rnd(0, 0.04))])
					if VENTS.has(c):
						vent_pad(m, w, VENTS[c])
	m.add_chunks(blocks, STAIRS_X)
	dress(m, ground)
	# the channel's face glows a little, so it reads as water (for the skip) and not as a step down
	var wet: Material = m.glow_mat(Color("#2f78b8"), 0.6)
	wet.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	wet.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	# the broken drop has a dark floor far below, so in daylight it reads as a fall and not as more floor
	var deep: MeshInstance3D = m.box(Vector3(20.0, 0.1, 16.0), m.mat_color(Color("#16121e")))
	deep.position = Vector3(STAIRS_X + 11.5, -2.6, 3.0) # wide to the north: the camera looks down through the gap at a slant
	m.add_child(deep)
	var face: MeshInstance3D = m.box(Vector3(18.0, 0.02, 3.0), wet)
	face.position = Vector3(STAIRS_X + 11.5, -0.3, 17)
	m.add_child(face)
	# a stair of three steps at the foot and the top of each landing's way through
	var step: Material = m.mat_color(Color("#b8b4c4"))
	for at in [Vector2(STAIRS_X + 11.5, 28.6), Vector2(STAIRS_X + 11.5, 1.4)]:
		for k in 3:
			var st: MeshInstance3D = m.box(Vector3(2.2, 0.08 + k * 0.08, 0.3), step)
			st.position = Vector3(at.x, (0.08 + k * 0.08) / 2.0, at.y - 0.3 + k * 0.3 * (1 if at.y > 10 else -1))
			m.add_child(st)
	var post_mat: Material = m.mat_color(Color("#3b2a1e"))
	var glass: Material = m.glow_mat(Color("#ffc46a"), 4.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	for w in lamp_spots:
		m.lantern(w.x - 0.3, w.y, post_mat, glass)
	for z in H:
		for x in W:
			if grid[z][x] == "W":
				wall_nodes.append(m.forest.brick_wall(m, Vector2(STAIRS_X + x, z)))
			if grid[z][x] == "o":
				lamps.append(moon_lamp(m, Vector2(STAIRS_X + x, z)))
	door = Node3D.new()
	var slab: MeshInstance3D = m.box(Vector3(4.0, 1.8, 0.5), m.mat_color(Color("#5a5a66")))
	slab.position = Vector3(0, 0.9, 0)
	door.add_child(slab)
	var moon: MeshInstance3D = m.box(Vector3(0.6, 0.6, 0.1), m.glow_mat(Color("#dfe8ff"), 1.2))
	moon.position = Vector3(0, 1.2, 0.28)
	door.add_child(moon)
	door.position = Vector3(STAIRS_X + 11.5, 0, 2)
	m.add_child(door)
	fx_build(m)

# a tall dark lantern post for the top landing; E lights it
func moon_lamp(m: Node, at: Vector2) -> Dictionary:
	var g := Node3D.new()
	var post: MeshInstance3D = m.box(Vector3(0.3, 1.6, 0.3), m.mat_color(Color("#5a5060")))
	post.position = Vector3(0, 0.8, 0)
	g.add_child(post)
	var glass: MeshInstance3D = m.box(Vector3(0.45, 0.45, 0.45), m.mat_color(Color("#2a2838")))
	glass.position = Vector3(0, 1.8, 0)
	g.add_child(glass)
	var light := OmniLight3D.new()
	light.light_color = Color("#bcd6ff")
	light.light_energy = 2.0
	light.omni_range = 5.0
	light.position = Vector3(0, 2.0, 0)
	light.visible = false
	g.add_child(light)
	g.position = Vector3(at.x, 0, at.y)
	m.add_child(g)
	return {"pos": at, "lit": false, "glass": glass, "light": light, "lit_mat": m.glow_mat(Color("#dfe8ff"), 2.0)}

func light_lamp(l: Dictionary) -> void:
	l.lit = true
	(l.glass as MeshInstance3D).material_override = l.lit_mat
	(l.light as OmniLight3D).visible = true

func vent_pad(m: Node, w: Vector2, d: Vector2) -> void:
	var pad: MeshInstance3D = m.box(Vector3(0.9, 0.06, 0.9), m.glow_mat(Color("#8fc8f0"), 0.5))
	pad.position = Vector3(w.x, 0.03, w.y)
	m.add_child(pad)
	var ink: Material = m.mat_color(Color("#1e3a66"))
	var tip := w + d * 0.3
	for part in [[w - d * 0.05, d, 0.55], [tip + d.rotated(2.36) * 0.14, d.rotated(2.36), 0.3], [tip + d.rotated(-2.36) * 0.14, d.rotated(-2.36), 0.3]]:
		var at: Vector2 = part[0]
		var dir: Vector2 = part[1]
		var bar: MeshInstance3D = m.box(Vector3(part[2], 0.05, 0.1), ink)
		bar.position = Vector3(at.x, 0.08, at.y)
		bar.rotation.y = atan2(-dir.y, dir.x)
		m.add_child(bar)

func open_wall() -> void:
	wall_open = true
	for n in wall_nodes:
		n.visible = false

func open_door() -> void:
	door_open = true
	door.visible = false

func map_tex(width: int) -> ImageTexture:
	var img := Image.create(width, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for z in H:
		for x in W:
			var c: String = grid[z][x]
			var col := Color("#4a4658")
			match c:
				"#", "_": col = Color(0, 0, 0, 0)
				"~": col = Color("#2c5a8a")
				"^", "v": col = Color("#bfe6ff")
				"W": col = Color("#4a4658") if wall_open else Color("#c8322a")
				"D": col = Color("#4a4658") if door_open else Color("#dfe8ff")
				"o": col = Color("#ffd27a")
				"N", "S": col = Color("#ffd27a")
				"L": col = Color("#ffd060")
			img.set_pixel(STAIRS_X + x, z, col)
	return ImageTexture.create_from_image(img)

# ---- the moon stairs made lovely (the owner, 2026-10-29: "달의계단에도 와~ 이쁘다, 할만한 요소 넣어줘"): each step's edge
# lights pale blue when Sora stands on it and stays lit, so the climbed path glows; paper lanterns rise slowly along both
# walls; moon-petals drift down the whole climb; a big moon stands behind the top door; wind chimes on posts ring (code
# sound) as she passes. Boxes, CPUParticles3D and Sprite3D only; the particles run only while she is on the stairs.
var lit_tiles := {}          # Vector2i(x, z) of the climbed steps -> their glowing edge
var lantern_fx: Array = []   # the two lantern emitters
var petal_fx: CPUParticles3D
var moon_disc: Sprite3D
var chimes: Array = []       # [{"pos": Vector2, "hang": Node3D, "near": bool}]
var chime_rings := 0
var fx_on := false
var edge_mesh: PlaneMesh
var edge_mat: StandardMaterial3D
var fx_root: Node3D
const CHIME_NEAR := 3.0      # the chime rings when she comes this close, and again once she has been 4.2 away
const CHIME_POSTS := [Vector2(2.8, 9.0), Vector2(2.8, 17.0), Vector2(2.8, 24.0), Vector2(20.2, 9.0), Vector2(20.2, 17.0), Vector2(20.2, 24.0)]

func edge_tex() -> ImageTexture: # a soft pale-blue frame, clear in the middle
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d: float = minf(minf(x, y), minf(63 - x, 63 - y))
			var a: float = clampf(1.0 - absf(d - 3.0) / 3.2, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(0.62, 0.84, 1.0, a))
	return ImageTexture.create_from_image(img)

func moon_tex() -> ImageTexture: # a pale disc with a few soft seas and a wide halo
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var seas := [[Vector2(-0.12, -0.06), 0.16], [Vector2(0.1, 0.12), 0.11], [Vector2(0.14, -0.14), 0.07], [Vector2(-0.06, 0.18), 0.06]]
	for y in n:
		for x in n:
			var p := Vector2(x / float(n) - 0.5, y / float(n) - 0.5)
			var r := p.length()
			var col := Color(0.9, 0.94, 1.0, 0.0)
			if r < 0.4:
				var k := clampf((0.4 - r) / 0.012, 0.0, 1.0)
				var shade := 0.0
				for s in seas:
					shade = maxf(shade, clampf(1.0 - (p - s[0]).length() / s[1], 0.0, 1.0))
				col = Color(0.96, 0.97, 1.0, k).lerp(Color(0.74, 0.8, 0.94, k), shade * 0.55)
			elif r < 0.5:
				col = Color(0.8, 0.88, 1.0, 0.32 * pow(1.0 - (r - 0.4) / 0.1, 2.0))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func fx_build(m: Node) -> void:
	fx_root = Node3D.new()
	m.add_child(fx_root)
	edge_mesh = PlaneMesh.new()
	edge_mesh.size = Vector2(0.96, 0.96)
	edge_mat = StandardMaterial3D.new()
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	edge_mat.albedo_texture = edge_tex()
	edge_mat.albedo_color = Color(1, 1, 1, 0.9)
	edge_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	edge_mesh.material = edge_mat
	# paper lanterns rise from both walls: warm paper boxes that fade in and out
	var paper := BoxMesh.new()
	paper.size = Vector3(0.22, 0.3, 0.22)
	var pm: StandardMaterial3D = m.glow_mat(Color("#ff9c4a"), 1.4)
	pm.vertex_color_use_as_albedo = true
	paper.material = pm
	for x in [1.2, W - 1.2]:
		var p := CPUParticles3D.new()
		p.mesh = paper
		p.amount = 12
		p.lifetime = 12.0
		p.preprocess = 12.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(0.6, 0.1, 13.0)
		p.direction = Vector3(0.08 if x < 5.0 else -0.08, 1, 0)
		p.spread = 6.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.35
		p.initial_velocity_max = 0.6
		p.scale_amount_min = 0.7
		p.scale_amount_max = 1.3
		p.color_ramp = fade_ramp()
		p.position = Vector3(STAIRS_X + x, 0.4, 15.0)
		p.emitting = false
		fx_root.add_child(p)
		lantern_fx.append(p)
	# moon-petals: small pale blue-white flakes that sink slowly over the whole climb
	var petal := QuadMesh.new()
	petal.size = Vector2(0.09, 0.14)
	var ptm: StandardMaterial3D = m.glow_mat(Color("#cfe4ff"), 2.0)
	ptm.vertex_color_use_as_albedo = true
	ptm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	petal.material = ptm
	petal_fx = CPUParticles3D.new()
	petal_fx.mesh = petal
	petal_fx.amount = 56
	petal_fx.lifetime = 12.0
	petal_fx.preprocess = 12.0
	petal_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	petal_fx.emission_box_extents = Vector3(10.0, 0.3, 14.0)
	petal_fx.direction = Vector3(0.3, -1, 0.1)
	petal_fx.spread = 40.0
	petal_fx.gravity = Vector3(0.1, -0.3, 0.0)
	petal_fx.initial_velocity_min = 0.05
	petal_fx.initial_velocity_max = 0.25
	petal_fx.damping_min = 0.4
	petal_fx.damping_max = 0.9
	petal_fx.angle_min = -180.0
	petal_fx.angle_max = 180.0
	petal_fx.angular_velocity_min = -60.0
	petal_fx.angular_velocity_max = 60.0
	petal_fx.scale_amount_min = 0.6
	petal_fx.scale_amount_max = 1.4
	petal_fx.color_ramp = fade_ramp()
	petal_fx.position = Vector3(STAIRS_X + 11.5, 4.2, 15.0)
	petal_fx.emitting = false
	fx_root.add_child(petal_fx)
	# a large moon behind the top door, over the dark beyond the stairs
	moon_disc = Sprite3D.new()
	moon_disc.texture = moon_tex()
	moon_disc.pixel_size = 0.04 # 256 px: 10 units across with its halo, the disc 8
	moon_disc.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	moon_disc.shaded = false
	moon_disc.transparent = true
	moon_disc.position = Vector3(STAIRS_X + 11.5, 5.4, -3.5)
	fx_root.add_child(moon_disc)
	# wind chimes on slim posts along both walls
	var wood: Material = m.mat_color(Color("#3b2a1e"))
	var metal: Material = m.glow_mat(Color("#cfe3ff"), 0.9)
	for cp in CHIME_POSTS:
		var g := Node3D.new()
		g.position = Vector3(STAIRS_X + cp.x, 0, cp.y)
		var post: MeshInstance3D = m.box(Vector3(0.08, 1.7, 0.08), wood)
		post.position = Vector3(0, 0.85, 0)
		g.add_child(post)
		var bar: MeshInstance3D = m.box(Vector3(0.5, 0.05, 0.05), wood)
		bar.position = Vector3(0, 1.68, 0)
		g.add_child(bar)
		var hang := Node3D.new()
		hang.position = Vector3(0, 1.66, 0)
		for k in 4:
			var len: float = [0.55, 0.42, 0.7, 0.34][k]
			var rod: MeshInstance3D = m.box(Vector3(0.035, len, 0.035), metal)
			rod.position = Vector3(-0.18 + k * 0.12, -len / 2.0, 0)
			hang.add_child(rod)
		g.add_child(hang)
		fx_root.add_child(g)
		chimes.append({"pos": Vector2(STAIRS_X + cp.x, cp.y), "hang": hang, "near": false})

func fade_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	return g

# every frame she is on the stairs (main._process): the step under her lights, the chimes listen; the particles run only here
func update(m: Node, _dt: float, on: bool) -> void:
	if on != fx_on:
		fx_on = on
		for p in lantern_fx:
			(p as CPUParticles3D).emitting = on
			if on:
				(p as CPUParticles3D).restart()
		petal_fx.emitting = on
		if on:
			petal_fx.restart()
	if not on:
		return
	var me := Vector2(m.player.x, m.player.z)
	var tile := Vector2i(int(round(me.x)), int(round(me.y)))
	if not blocked(me.x, me.y) and char_at(me.x, me.y) != "#" and not lit_tiles.has(tile):
		var e := MeshInstance3D.new()
		e.mesh = edge_mesh
		e.position = Vector3(tile.x, 0.015, tile.y)
		e.transparency = 1.0
		fx_root.add_child(e)
		lit_tiles[tile] = e
		var tw := e.create_tween()
		tw.tween_property(e, "transparency", 0.0, 0.5)
		m.burst(Vector3(tile.x, 0.2, tile.y), Color("#9fd4ff"), 3, 0.7)
	for c in chimes:
		var d: float = me.distance_to(c.pos)
		if d < CHIME_NEAR and not c.near:
			c.near = true
			ring_chime(m, c)
		elif d > CHIME_NEAR + 1.2:
			c.near = false

# the hanging rods swing and die away; three bell tones, code sound, a little apart
func ring_chime(m: Node, c: Dictionary) -> void:
	chime_rings += 1
	var hang: Node3D = c.hang
	var tw := hang.create_tween()
	tw.tween_method(func(k: float):
		hang.rotation = Vector3(sin(k * PI * 9.0) * 0.28 * (1.0 - k), 0, sin(k * PI * 7.0 + 1.0) * 0.32 * (1.0 - k)), 0.0, 1.0, 2.4)
	var base: float = [1568.0, 1760.0, 1319.0, 1976.0][chime_rings % 4]
	for i in 3:
		m.get_tree().create_timer(0.11 * i).timeout.connect(func(): m.sfx(base * [1.0, 1.26, 1.5][i], 0.9, "sine", 0.05))
