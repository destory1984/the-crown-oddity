# Ground dressing: the marsh's look for the other maps, each in its own colours (the owner, 2026-10-26: players love
# the first marsh for its looks and the other maps have none of it; plan in DESIGN.md, section 다른 지역도 늪만큼 보기 좋게).
# The marsh gets its look from speckled block tops over earth sides (shaders/block.gdshader) and wind-combed grass
# tufts with a few flowers (shaders/grass.gdshader); a map hands its floor blocks and grass tiles here.
# Uses its own random stream, so the maps built after it keep their props where they were.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main
var rng := RandomNumberGenerator.new()

func _init(main: Main) -> void:
	m = main
	rng.seed = 2610

func rnd(a: float, b: float) -> float:
	return rng.randf_range(a, b)

# a 16x16 top picture from a few shades, picked at random per pixel (like world_build.noise_tex)
func speckle_tex(cols: Array) -> ImageTexture:
	return m.make_tex(16, 16, func(img: Image):
		for y in 16:
			for x in 16:
				img.set_pixel(x, y, cols[mini(cols.size() - 1, int(rng.randf() * cols.size()))]))

# floor blocks ([Transform3D, tint] like add_chunks takes) drawn with the speckled top and earth sides; the tint
# should be near white, the picture brings the colour. Split into 6x6 chunks so each sees only nearby lights.
func ground_blocks(blocks: Array, origin_x: int, top: Texture2D, side := Color(0.54, 0.42, 0.24)) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/block.gdshader")
	sm.set_shader_parameter("top_tex", top)
	sm.set_shader_parameter("side_color", side)
	var chunks := {}
	for bl in blocks:
		var o: Vector3 = bl[0].origin
		var key := Vector2i(int(o.x - origin_x) / 6, int(o.z) / 6)
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
			mm.set_instance_color(i, (list[i][1] as Color).srgb_to_linear())
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = sm
		m.add_child(mmi)

# a near-white tint for one floor block: a little hue and brightness wander, as the marsh's blocks have
func tint(hue: float, sat := 0.14, lo := 0.86, hi := 1.0) -> Color:
	return Color.from_hsv(hue + rnd(-0.02, 0.02), sat, rnd(lo, hi))

# one grass tuft picture: blades from root to tip along `ramp`, leaning by `lean` (0 straight, 1 hard over), with
# `flowers` small blossoms from `blooms`
func tuft_tex(ramp: Array, lean: float, flowers: int, blooms: Array) -> ImageTexture:
	return m.make_tex(48, 48, func(img: Image):
		for i in 46:
			var x := 6.0 + rng.randf() * 36.0
			var h := 12.0 + rng.randf() * 30.0
			var bend := (rng.randf() * 0.4 + lean) * 0.6
			for y in int(h):
				var k := y / h
				var ci := mini(ramp.size() - 1, int(floor(k * (ramp.size() - 0.2) + rng.randf() * 0.6)))
				m.px(img, x, 47 - y, 2 if k < 0.55 else 1, 1, Color(ramp[ci]))
				x += bend * (0.4 + k)
		for i in flowers:
			var x := 6.0 + rng.randf() * 34.0
			var y := 12.0 + rng.randf() * 16.0
			var c := Color(blooms[rng.randi() % blooms.size()])
			m.px(img, x - 1, y, 3, 1, c)
			m.px(img, x, y - 1, 1, 3, c)
			m.px(img, x, y, 1, 1, Color("#ffb030")))

# tufts at spots (Vector4 x, ground y, z, scale), swaying with the grass shader; phones draw half, as in the marsh.
# They join m.veg_meshes, so story.clear_vegetation can clear them like the marsh's.
func grass(tex: Texture2D, w: float, h: float, spots: Array, strength: float) -> void:
	if m.touch_ui:
		spots = spots.filter(func(sp): return int(sp.x * 7.0 + sp.z * 13.0) % 2 == 0)
	if spots.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = m.world_build.cross_mesh(w, h)
	mm.instance_count = spots.size()
	for i in spots.size():
		var s: Vector4 = spots[i]
		var b := Basis(Vector3.UP, rnd(0, PI)).scaled(Vector3(s.w, s.w * rnd(0.8, 1.2), s.w))
		mm.set_instance_transform(i, Transform3D(b, Vector3(s.x, s.y, s.z)))
		mm.set_instance_color(i, Color.from_hsv(0.2, 0.06, rnd(0.88, 1.0)).srgb_to_linear())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	m.veg_meshes.append(mm)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/grass.gdshader")
	sm.set_shader_parameter("tex", tex)
	sm.set_shader_parameter("strength", strength)
	mmi.material_override = sm
	m.add_child(mmi)

# `per_tile` tuft spots on each world tile in `tiles` (Vector2 of tile centres), at ground height `y`
func spots_on(tiles: Array, y: float, per_tile: int, lo := 0.7, hi := 1.15) -> Array:
	var out: Array = []
	for t in tiles:
		for k in per_tile:
			out.append(Vector4(t.x + rnd(-0.5, 0.5), y, t.y + rnd(-0.5, 0.5), rnd(lo, hi)))
	return out

# ---------------------------------------------------------------- the marsh's far banks
# Past the marsh's border water there was nothing: from the east bank the village side was an empty purple void
# (the owner, 2026-10-26, with a picture). A ring of far land, 10 tiles wide, now stands beyond the water on all four
# sides: speckled grass with low tufts and voxel trees, and on the east bank, across the river, the roofs and warm
# windows of the village (Sora sees its lights from the cave exit). None of it is walkable: the marsh map ends at N.
const FAR := 10

func marsh_backdrop() -> void:
	var n: int = Main.N
	var ground: Array = []
	var tiles: Array = []
	var boxes: Array = [] # [Transform3D, Color] for trunks, leaves, walls and roofs
	var windows: Array = []
	for z in range(-FAR, n + FAR):
		for x in range(-FAR, n + FAR):
			if x >= 0 and x < n and z >= 0 and z < n:
				continue
			var top := 0.15 + 0.1 * sin(x * 0.4) * cos(z * 0.3)
			ground.append([Transform3D(Basis().scaled(Vector3(1, 1.2, 1)), Vector3(x, top - 0.6, z)), tint(0.24, 0.2, 0.8, 1.0)])
			tiles.append(Vector3(x, top, z))
	ground_blocks(ground, -FAR, speckle_tex([Color("#5e8f30"), Color("#6b9c36"), Color("#6b9c36"), Color("#7dab3e")]))
	# the village across the river: six small houses up the east bank, between the trees
	var houses: Array = []
	for i in 6:
		houses.append(Vector2(n + 3.5 + rnd(0, 4.5), 6.0 + i * 6.5 + rnd(-1.5, 1.5)))
	var near_house := func(x: float, z: float) -> bool:
		for h in houses:
			if Vector2(x, z).distance_to(h) < 2.6:
				return true
		return false
	var spots: Array = []
	for t in tiles:
		if near_house.call(t.x, t.z):
			continue
		for k in 3:
			spots.append(Vector4(t.x + rnd(-0.5, 0.5), t.y, t.z + rnd(-0.5, 0.5), rnd(0.7, 1.1)))
		if rng.randf() < 0.07: # a tree: a trunk and two or three leaf cubes
			var y: float = t.y
			var sc := rnd(0.8, 1.2)
			var th := rnd(1.2, 1.9) * sc
			boxes.append([Transform3D(Basis().scaled(Vector3(0.3, th, 0.3) * Vector3(sc, 1, sc)), Vector3(t.x, y + th / 2.0, t.z)), Color("#5a3a22")])
			var leaf := Color("#3f7a2a").lerp(Color("#6aa83a"), rng.randf())
			for k in 2 + rng.randi() % 2:
				var s := rnd(0.9, 1.4) * sc
				boxes.append([Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(t.x + rnd(-0.3, 0.3), y + th + s * 0.3 + k * 0.5 * sc, t.z + rnd(-0.3, 0.3))), leaf])
	grass(tuft_tex(["#5e9a34", "#68a636", "#6eaa36", "#82ba3e", "#9ccb48", "#b8dc62", "#d8ee90"], 0.3, 2, ["#fff6d8", "#ffd24a"]), 0.8, 0.5, spots, 0.12)
	for h in houses:
		var y := 0.2
		var wall := Color("#e6d6b0").lerp(Color("#c9b48a"), rng.randf())
		var roof: Color = [Color("#b8503a"), Color("#8a5a3a"), Color("#5a6a8a")][rng.randi() % 3]
		boxes.append([Transform3D(Basis().scaled(Vector3(2.0, 1.4, 1.6)), Vector3(h.x, y + 0.7, h.y)), wall])
		boxes.append([Transform3D(Basis().scaled(Vector3(2.3, 0.35, 1.9)), Vector3(h.x, y + 1.55, h.y)), roof])
		boxes.append([Transform3D(Basis().scaled(Vector3(1.6, 0.35, 1.3)), Vector3(h.x, y + 1.9, h.y)), roof])
		windows.append(Vector3(h.x - 1.01, y + 0.85, h.y + rnd(-0.3, 0.3))) # on the west wall, facing the marsh
	m.add_chunks(boxes, -FAR)
	var glass: Material = m.glow_mat(Color("#ffc46a"), 2.0)
	for w in windows:
		var win: MeshInstance3D = m.box(Vector3(0.06, 0.4, 0.4), glass)
		win.position = w
		m.add_child(win)
