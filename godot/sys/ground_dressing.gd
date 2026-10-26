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
