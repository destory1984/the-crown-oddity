# World build: environment, island map, bridges, terrain, vegetation, grass drafts, props, lights, cottage.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const LEGO_COLS := [Color("#c8322a"), Color("#e8b018"), Color("#2f5fb8"), Color("#3f8a3a")]
const SIGN_SVG := {
	"shop": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20 11h8M21.5 11v7l-7 9a8 8 0 0 0 6.5 12h6a8 8 0 0 0 6.5-12l-7-9v-7"/><path d="M17 30h14"/></g></svg>',
	"village": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M15 12v3M11 15h8v13h-8zM11 28l1 3h6l1-3"/><path d="M15 19v5"/><path d="M25 24h13M33 19l5 5-5 5"/></g></svg>',
	"apple": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M24 17c-5-4-13-1-13 8 0 7 5 14 9 14 2 0 3-1 4-1s2 1 4 1c4 0 9-7 9-14 0-9-8-12-13-8z"/><path d="M24 17c0-3 1-5 3-7"/><path d="M27 12c3-1 6 0 7 2-3 1-6 0-7-2z"/></g></svg>',
	"moon": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M27 11a13 13 0 1 0 9 22 11 11 0 1 1-9-22z"/><path d="M35 13v4M33 15h4M14 33v3M12.5 34.5h3"/></g></svg>',
	"tea": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M11 22h21v6a8 8 0 0 1-8 8h-5a8 8 0 0 1-8-8z"/><path d="M32 24h2a4 4 0 0 1 0 8h-3"/><path d="M17 11c-2 2 2 4 0 7M24 11c-2 2 2 4 0 7"/><path d="M9 40h25"/></g></svg>',
	"lake": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18c4-4 7-4 10 0s6 4 10 0 6-4 10 0"/><path d="M9 26c4-4 7-4 10 0s6 4 10 0 6-4 10 0"/><path d="M9 34c4-4 7-4 10 0s6 4 10 0 6-4 10 0"/></g></svg>',
	"garden": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M24 38V22"/><path d="M24 26c-8 0-11-6-11-11 7 0 11 4 11 11z"/><path d="M24 22c0-6 4-9 11-9 0 6-4 9-11 9z"/><path d="M15 38h18"/></g></svg>',
	"inn": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><circle cx="24" cy="24" r="21" fill="#f2ead8" stroke="#3a2414" stroke-width="2"/><g fill="none" stroke="#3a2414" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M9 35V14M9 29h30v6M39 35v-9a3 3 0 0 0-3-3H20v6"/><circle cx="14.5" cy="24.5" r="3"/></g></svg>',
}

func _init(main: Main) -> void:
	m = main

func build_environment() -> void:
	m.env = Environment.new()
	m.env.background_mode = Environment.BG_COLOR
	m.env.background_color = Color("#e8c98a")
	m.env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	m.env.ambient_light_color = Color("#fff0d0")
	m.env.ambient_light_energy = 0.9
	m.env.tonemap_mode = Environment.TONE_MAPPER_ACES
	m.env.tonemap_exposure = 0.9
	m.env.glow_enabled = true
	m.env.glow_intensity = 0.8
	m.env.glow_bloom = 0.05
	m.env.glow_hdr_threshold = 0.9
	m.env.fog_enabled = true
	m.env.fog_mode = Environment.FOG_MODE_DEPTH
	m.env.fog_light_color = Color("#e8c98a")
	m.env.fog_depth_begin = 18.0
	m.env.fog_depth_end = 46.0
	var we := WorldEnvironment.new()
	we.environment = m.env
	m.add_child(we)

	m.sun = DirectionalLight3D.new()
	m.sun.light_color = Color("#ffc06a")
	m.sun.light_energy = 1.6
	m.sun.shadow_enabled = not m.touch_ui # phones: no shadows, for speed
	m.sun.directional_shadow_max_distance = 40.0
	m.add_child(m.sun)

	m.camera = Camera3D.new()
	m.camera.fov = 32.0
	m.camera.far = 200.0
	m.add_child(m.camera)

	# tilt-shift + grade as a full-screen pass under the HUD
	var post := CanvasLayer.new()
	post.layer = 0
	m.add_child(post)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/tiltshift.gdshader")
	rect.material = sm
	post.add_child(rect)
	m.tilt_rect = rect

# layout: a winding river from the north feeds a southern lake with an island;
# a raised meadow in the north-east, a small pond in the north-west
func build_map() -> void:
	m.map.resize(Main.N * Main.N)
	m.hgt.resize(Main.N * Main.N)
	for z in Main.N:
		for x in Main.N:
			var lake := Vector2((x - 24) * 0.8, z - 39).length() < 6.5 and Vector2(x - 24, z - 39).length() > 2.2
			var river := z < 35 and absf(x - (24.0 + sin(z * 0.18) * 5.0)) < 2.2
			var pond := Vector2(x - 9, z - 11).length() < 3.2
			var w := lake or river or pond or x < 2 or z < 2 or x > Main.N - 3 or z > Main.N - 3
			var plateau := x > 31 and z < 17
			m.map[m.idx(x, z)] = Main.WATER if w else Main.GRASS
			m.hgt[m.idx(x, z)] = -0.45 if w else (0.6 if plateau else (0.18 if m.rng.randf() < 0.12 else 0.0))
	# sand banks next to water
	for z in range(1, Main.N - 1):
		for x in range(1, Main.N - 1):
			if m.map[m.idx(x, z)] != Main.GRASS:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if m.map[m.idx(x + d.x, z + d.y)] == Main.WATER and m.rng.randf() < 0.55:
					m.map[m.idx(x, z)] = Main.SAND
					m.hgt[m.idx(x, z)] = -0.12
					break
	bridge_line(12, 36, 9)
	bridge_line(10, 34, 25)
	bridge_line(12, 36, 39)

func bridge_line(x0: int, x1: int, z: int) -> void:
	var run = null
	for i in range(x0, x1 + 1):
		if m.map[m.idx(i, z)] == Main.WATER:
			m.map[m.idx(i, z)] = Main.BRIDGE
			m.hgt[m.idx(i, z)] = 0.08
			if m.map[m.idx(i, z + 1)] == Main.WATER:
				m.map[m.idx(i, z + 1)] = Main.BRIDGE
				m.hgt[m.idx(i, z + 1)] = 0.08
			if run == null:
				run = {"a": i, "z": z}
			run.b = i
		elif run != null:
			m.bridges.append(run)
			run = null
	# the deck is two tiles wide and overhangs each end; any water left under it
	# (e.g. the lower row at a bank) would be an invisible wall, so pave it all
	for b in m.bridges:
		if b.z != z:
			continue
		for i in range(b.a - 1, b.b + 2):
			for zz in [z, z + 1]:
				if m.map[m.idx(i, zz)] == Main.WATER:
					m.map[m.idx(i, zz)] = Main.BRIDGE
					m.hgt[m.idx(i, zz)] = 0.08

# ---------------------------------------------------------------- terrain
func noise_tex(cols: Array) -> ImageTexture:
	return m.make_tex(16, 16, func(img: Image):
		for y in 16:
			for x in 16:
				var v := m.rng.randf()
				var c: Color = cols[0]
				for k in range(1, cols.size()):
					if v > float(k) / cols.size():
						c = cols[k]
				img.set_pixel(x, y, c))

func block_layer(type: int, tex: Texture2D, tint: Callable) -> void:
	var list: Array = []
	for z in Main.N:
		for x in Main.N:
			if m.map[m.idx(x, z)] == type:
				list.append(Vector2i(x, z))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = list.size()
	for i in list.size():
		var p: Vector2i = list[i]
		var h := m.hgt[m.idx(p.x, p.y)]
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, 1.2, 1)), Vector3(p.x, h - 0.6, p.y)))
		mm.set_instance_color(i, (tint.call() as Color).srgb_to_linear())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/block.gdshader")
	sm.set_shader_parameter("top_tex", tex)
	mmi.material_override = sm
	m.add_child(mmi)

func build_terrain() -> void:
	var grass_top := noise_tex([Color("#5e8f30"), Color("#6b9c36"), Color("#6b9c36"), Color("#7dab3e")])
	var sand_top := noise_tex([Color("#c99a62"), Color("#ddb479"), Color("#ddb479"), Color("#efcf97")])
	block_layer(Main.GRASS, grass_top, func(): return Color.from_hsv(0.24 + m.rnd(-0.02, 0.02), 0.25, m.rnd(0.82, 1.0)))
	block_layer(Main.SAND, sand_top, func(): return Color(1, 1, 1) * m.rnd(0.9, 1.05))

	var bed := MeshInstance3D.new()
	var bp := PlaneMesh.new()
	bp.size = Vector2(Main.N, Main.N)
	bed.mesh = bp
	bed.material_override = m.mat_color(Color("#29475e"))
	bed.position = Vector3(Main.N / 2.0 - 0.5, -0.7, Main.N / 2.0 - 0.5)
	m.add_child(bed)

	var water_tex := m.make_tex(32, 32, func(img: Image):
		img.fill(Color("#3d6f9a"))
		for i in 40:
			m.px(img, m.rnd(0, 32), m.rnd(0, 32), m.rnd(2, 6), 1, Color("#5f93bf") if m.rng.randf() < 0.5 else Color("#2f5c86"))
		for i in 6:
			m.px(img, m.rnd(0, 32), m.rnd(0, 32), 2, 1, Color("#cfe8ff")))
	var water := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(Main.N, Main.N)
	water.mesh = wp
	var wm := ShaderMaterial.new()
	wm.shader = load("res://shaders/water.gdshader")
	wm.set_shader_parameter("tex", water_tex)
	water.material_override = wm
	water.position = Vector3(Main.N / 2.0 - 0.5, -0.22, Main.N / 2.0 - 0.5)
	m.add_child(water)

	# bridges: planks and rails
	var plank_tex := m.make_tex(16, 16, func(img: Image):
		var cols := [Color("#8a5a32"), Color("#9d6a3c"), Color("#7d4f2b"), Color("#a87443")]
		for k in 4:
			m.px(img, k * 4, 0, 4, 16, cols[k])
			m.px(img, k * 4 + 3, 0, 1, 16, Color("#3d2614")))
	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_texture = plank_tex
	plank_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	plank_mat.uv1_scale = Vector3(4, 1, 1)
	var post_mat := m.mat_color(Color("#3b2a1e"))
	for b in m.bridges:
		lego_deck(b.a, b.b, b.z)
		bridge_ropes(b)

# cosmetic rope strips hung along each deck's outer sides; they dip a little when Sora steps on an end of the deck and
# swing back (delight idea 9). The deck, its walls and the tiles stay as they were.
const ROPE_SEGS := 8
var ropes: Array = [] # [{"b": bridge, "segs": [MeshInstance3D], "inside": bool, "tween": Tween}]
var rope_dips := 0 # dips started (autoplay d9_rope)

func bridge_ropes(b: Dictionary) -> void:
	var length := float(b.b - b.a + 3)
	var mat := m.mat_color(Color("#b89a62"))
	var segs: Array = []
	for side in [-1.12, 1.12]:
		for i in ROPE_SEGS:
			var w := length / ROPE_SEGS
			var seg := box(Vector3(w, 0.04, 0.04), mat)
			seg.position = Vector3((b.a + b.b) / 2.0 - length / 2.0 + w * (i + 0.5), 0.0, b.z + 0.5 + side)
			seg.set_meta("frac", (i + 0.5) / ROPE_SEGS)
			m.add_child(seg)
			segs.append(seg)
	var r := {"b": b, "segs": segs, "inside": false, "tween": null, "sag": 0.0}
	ropes.append(r)
	rope_set(r, 0.0)

func rope_set(r: Dictionary, k: float) -> void: # k 0 = hanging as built, 1 = dipped
	r.sag = k
	for seg in r.segs:
		var f: float = seg.get_meta("frac")
		seg.position.y = 0.66 - sin(f * PI) * (0.05 + 0.09 * k)

func update_ropes() -> void:
	var safe: bool = not m.story_open and not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 6.0)
	for r in ropes:
		var b: Dictionary = r.b
		var on_end: bool = m.player.z > b.z - 0.5 and m.player.z < b.z + 1.5 and (absf(m.player.x - b.a) < 0.9 or absf(m.player.x - b.b) < 0.9)
		if on_end and not r.inside and safe:
			rope_dips += 1
			if r.tween != null:
				r.tween.kill()
			var tw := m.create_tween()
			r.tween = tw
			tw.tween_method(func(k: float): rope_set(r, k), r.sag, 1.0, 0.3)
			tw.tween_method(func(k: float): rope_set(r, k), 1.0, 0.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		r.inside = on_end

func lego_brick(g: Node3D, size: Vector3, pos: Vector3, ci: int) -> void:
	if m.lego_mats.is_empty():
		for c in LEGO_COLS:
			var mm := StandardMaterial3D.new()
			mm.albedo_color = c
			mm.roughness = 0.3
			m.lego_mats.append(mm)
		m.stud_mesh = CylinderMesh.new()
		m.stud_mesh.top_radius = 0.11
		m.stud_mesh.bottom_radius = 0.11
		m.stud_mesh.height = 0.07
		m.stud_mesh.radial_segments = 10
	var mat: Material = m.lego_mats[ci % m.lego_mats.size()]
	var b := box(size - Vector3(0.03, 0, 0.03), mat) # a hair narrower, so the seams between bricks show
	b.position = pos
	g.add_child(b)
	for i in 2:
		for k in 2:
			var st := MeshInstance3D.new()
			st.mesh = m.stud_mesh
			st.material_override = mat
			st.position = pos + Vector3((i - 0.5) * size.x * 0.5, size.y / 2.0 + 0.035, (k - 0.5) * size.z * 0.5)
			g.add_child(st)

func lego_deck(a: int, b_: int, z: int) -> void:
	var length := b_ - a + 3
	var g := Node3D.new()
	var n := 0
	for row in 2: # two rows of bricks across the deck, the second shifted half a brick
		var x := -length / 2.0 + (0.5 if row == 1 else 0.0)
		while x < length / 2.0 - 0.01:
			var w := minf(1.0, length / 2.0 - x)
			lego_brick(g, Vector3(w, 0.2, 0.86), Vector3(x + w / 2.0, 0.02, -0.44 + row * 0.88), n)
			x += w
			n += 1
	for side in [-0.95, 0.95]: # the side walls
		var k := 0
		var x2 := -length / 2.0
		while x2 < length / 2.0 - 0.01:
			if k % 3 != 2:
				lego_brick(g, Vector3(0.9, 0.36, 0.22), Vector3(x2 + 0.45, 0.3, side), k + 1)
			x2 += 1.0
			k += 1
	g.position = Vector3((a + b_) / 2.0, 0, z + 0.5)
	m.add_child(g)

func box(size: Vector3, mm: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mm
	return mi

# ---------------------------------------------------------------- vegetation
func cross_mesh(w: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ang in [0.0, PI / 2.0, PI / 4.0]:
		var d := Vector3(cos(ang), 0, sin(ang)) * (w / 2.0)
		var v := [-d, d, d + Vector3(0, h, 0), -d + Vector3(0, h, 0)]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uv[k])
			st.add_vertex(v[k])
	return st.commit()

func vegetation(tex: Texture2D, w: float, h: float, spots: Array, strength: float) -> void:
	if m.touch_ui: # phones draw half the grass, for speed
		spots = spots.filter(func(sp): return int(sp.x * 7.0 + sp.z * 13.0) % 2 == 0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cross_mesh(w, h)
	mm.instance_count = spots.size()
	for i in spots.size():
		var s: Vector4 = spots[i]
		var b := Basis(Vector3.UP, m.rnd(0, PI)).scaled(Vector3(s.w, s.w * m.rnd(0.8, 1.2), s.w))
		mm.set_instance_transform(i, Transform3D(b, Vector3(s.x, s.y, s.z)))
		mm.set_instance_color(i, Color.from_hsv(0.22, 0.06, m.rnd(0.88, 1.0)).srgb_to_linear())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	m.veg_meshes.append(mm)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/grass.gdshader")
	sm.set_shader_parameter("tex", tex)
	sm.set_shader_parameter("strength", strength)
	if h >= 0.55: # tall plants shake when a blow lands near (ground_dressing.grass)
		sm.set_shader_parameter("hit_amp", 1.0)
		m.plant_mats.append(sm)
	mmi.material_override = sm
	m.add_child(mmi)

func build_vegetation() -> void:
	# tapered blades: light roots, sunlit tips, leaning in a shared breeze
	var tuft := m.make_tex(48, 48, func(img: Image):
		var ramp := ["#5e9a34", "#68a636", "#6eaa36", "#82ba3e", "#9ccb48", "#b8dc62", "#d8ee90"]
		for i in 46:
			var x := 6.0 + m.rng.randf() * 36.0
			var h := 14.0 + m.rng.randf() * 32.0
			var lean := (m.rng.randf() - 0.3) * 0.5
			for y in int(h):
				var k := y / h
				var ci := mini(ramp.size() - 1, int(floor(k * (ramp.size() - 0.2) + m.rng.randf() * 0.6)))
				m.px(img, x, 47 - y, 2 if k < 0.55 else 1, 1, Color(ramp[ci]))
				x += lean * (0.4 + k)
		for i in 4:
			var x := 6.0 + m.rng.randf() * 34.0
			var y := 10.0 + m.rng.randf() * 18.0
			var c := Color([("#fff6d8"), ("#ffd24a"), ("#8f9cff"), ("#ffb0cc")][m.rng.randi() % 4])
			m.px(img, x - 1, y, 3, 1, c)
			m.px(img, x, y - 1, 1, 3, c)
			m.px(img, x, y, 1, 1, Color("#ffb030")))
	var cattail := m.make_tex(16, 32, func(img: Image):
		for i in 5:
			var x := 2 + i * 3 + m.rng.randi() % 2
			var h := 18.0 + m.rng.randf() * 12.0
			m.px(img, x, 32 - h, 1, h, Color("#7aa63a") if i % 2 else Color("#a2b850"))
			# a slim dark-brown seed head (cattails are brown, not red) with a pale tip
			m.px(img, x - 1, 32 - h, 2, 5, Color("#5a4630"))
			m.px(img, x - 1, 32 - h, 1, 5, Color("#76603f"))
			m.px(img, x, 32 - h - 2, 1, 2, Color("#d8cf9a"))
		for i in 6:
			m.px(img, m.rng.randf() * 15, 20 + m.rng.randf() * 10, 1, 12, Color("#5d8a2a")))
	var grass_spots: Array = []
	var cattail_spots: Array = []
	for z in Main.N:
		for x in Main.N:
			var ty := m.map[m.idx(x, z)]
			var h := m.hgt[m.idx(x, z)]
			if ty == Main.GRASS:
				for k in 8:
					grass_spots.append(Vector4(x + m.rnd(-0.5, 0.5), h, z + m.rnd(-0.5, 0.5), m.rnd(0.7, 1.15)))
			if ty == Main.SAND and m.rng.randf() < 0.8:
				for k in 3:
					cattail_spots.append(Vector4(x + m.rnd(-0.5, 0.5), h, z + m.rnd(-0.5, 0.5), m.rnd(0.8, 1.2)))
			if ty == Main.WATER and m.rng.randf() < 0.07:
				cattail_spots.append(Vector4(x + m.rnd(-0.4, 0.4), -0.3, z + m.rnd(-0.4, 0.4), m.rnd(0.9, 1.2)))
	var gs := grass_style()
	if gs > 0: # a grass draft (env GRASS_STYLE): its own random stream, so the world after this stays where it was
		var made: Array = grass_draft(gs, grass_spots)
		vegetation(made[0], made[1], made[2], made[3], made[4])
	else:
		vegetation(tuft, 0.8, 0.55, grass_spots, 0.12)
	vegetation(cattail, 0.8, 1.7, cattail_spots, 0.07)
	marsh_flowers()

# 부처꽃 in small stands on the wet grass beside sand or water, one tile in four (the owner, 2026-10-28; GPT's pick);
# the dressing's own stream, so the marsh's grass and props stay where they were
func marsh_flowers() -> void:
	var d = m.dressing
	d.begin(1301)
	var spots: Array = []
	for z in range(1, Main.N - 1):
		for x in range(1, Main.N - 1):
			if m.map[m.idx(x, z)] != Main.GRASS or (x * 7 + z * 5) % 4 != 0:
				continue
			var wet := false
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var ty: int = m.map[m.idx(x + dd.x, z + dd.y)]
				if ty == Main.SAND or ty == Main.WATER:
					wet = true
			if wet:
				spots.append(Vector4(x + d.rnd(-0.4, 0.4), m.hgt[m.idx(x, z)], z + d.rnd(-0.4, 0.4), d.rnd(0.8, 1.1)))
	var tex: Texture2D = d.bloom_tex({"h": 96, "stems": 3, "lo": 40, "hi": 66, "stem": "#526b3c", "leaf": "#809a50", "leaves": "pair",
		"head": "spike", "r": 5, "petals": ["#a84e87", "#e8a5c7", "#c060a0"]})
	d.grass(tex, 0.8, 1.3, spots, 0.17, false)
	d.end()

# the ways down under the ground (the cave mouth, the island's stair to the grotto, the castle's stair to the
# undercroft) and the ways up out of an underground place show on the minimap as small upright stairs, violet going
# down, gold going up (the user could not find the undercroft's stair up, 2026-10-23, and asked for the marks to look
# like stairs, 2026-10-24). The map only keeps where they are, in its "stairs" meta: minimap.gd draws them on screen,
# so they stay sharp and upright while the map turns and stretches with the camera
func with_stair_marks(tex: ImageTexture, spots: Array) -> ImageTexture:
	return stair_marks(tex, spots, false)

func with_up_marks(tex: ImageTexture, spots: Array) -> ImageTexture:
	return stair_marks(tex, spots, true)

func stair_marks(tex: ImageTexture, spots: Array, up: bool) -> ImageTexture:
	var out := ImageTexture.create_from_image(tex.get_image())
	var list: Array = tex.get_meta("stairs", []).duplicate()
	for sp: Vector2 in spots:
		list.append([Vector2(round(sp.x), round(sp.y)), up])
	out.set_meta("stairs", list)
	return out

func under_map() -> ImageTexture:
	return with_up_marks(m.under.map_tex(Main.UNDER.UNDER_X + Main.UNDER.W), [m.under.marks.S])

# ---- five grass drafts for the user to choose from (python tools/dev.py shot with GRASS_STYLE=1..5)
# the user picked draft 5 (a low lawn with tall clumps) on 2026-10-23; GRASS_STYLE=0 shows the old tufts
func grass_style() -> int:
	return int(OS.get_environment("GRASS_STYLE")) if OS.get_environment("GRASS_STYLE") != "" else 5

# returns [texture, width, height, spots, sway]
func grass_draft(k: int, base: Array) -> Array:
	var vr := RandomNumberGenerator.new()
	vr.seed = 99
	var spots: Array = []
	var blade := func(img: Image, x0: float, h: float, lean: float, wide: float, ramp: Array) -> void:
		var x := x0
		for y in int(h):
			var t := y / h
			var w := maxi(1, int(round(wide * (1.0 - t))))
			var ci := mini(ramp.size() - 1, int(t * ramp.size()))
			m.px(img, x - w / 2.0, img.get_height() - 1 - y, w, 1, Color(ramp[ci]))
			x += lean * (0.3 + t)
	match k:
		1: # 가는 잎 촘촘히: many thin blades, darker roots, a few more per tile
			var tex := m.make_tex(48, 64, func(img: Image):
				for i in 90:
					blade.call(img, 4.0 + vr.randf() * 40.0, 22.0 + vr.randf() * 40.0, (vr.randf() - 0.5) * 0.5, 1.0,
						["#2f5a1e", "#3e7426", "#4f8a2c", "#62a034", "#7ab842", "#a6d064"]))
			for b in base:
				spots.append(b)
				if vr.randf() < 0.5:
					spots.append(Vector4(b.x + vr.randf_range(-0.3, 0.3), b.y, b.z + vr.randf_range(-0.3, 0.3), b.w))
			return [tex, 0.75, 0.75, spots, 0.14]
		2: # 굵은 잎 다발: broad pointed leaves in three greens, in clumps
			var tex := m.make_tex(48, 48, func(img: Image):
				for i in 22:
					var tone := vr.randi() % 3
					var ramp: Array = [["#3a6e22", "#4f8c2c", "#6aa83a", "#8cc452"], ["#447a26", "#5c9a32", "#7cb846", "#a2d066"], ["#356624", "#4a8030", "#5f9a38", "#7eb44a"]][tone]
					blade.call(img, 6.0 + vr.randf() * 36.0, 18.0 + vr.randf() * 26.0, (vr.randf() - 0.5) * 0.7, 4.0, ramp))
			for b in base:
				if vr.randf() < 0.7:
					spots.append(b)
			return [tex, 0.85, 0.6, spots, 0.1]
		3: # 바람결 풀밭: every blade leans the same way, pale tips, a stronger sway
			var tex := m.make_tex(48, 56, func(img: Image):
				for i in 60:
					blade.call(img, 2.0 + vr.randf() * 34.0, 24.0 + vr.randf() * 30.0, 0.35 + vr.randf() * 0.15, 2.0,
						["#3c7024", "#4e8a2c", "#66a436", "#86bc48", "#b4d878", "#e2f0b0"]))
			for b in base:
				spots.append(b)
			return [tex, 0.85, 0.7, spots, 0.22]
		4: # 들꽃 섞인 풀: the blades of now with clover leaves and many small flowers
			var tex := m.make_tex(48, 48, func(img: Image):
				for i in 50:
					blade.call(img, 4.0 + vr.randf() * 40.0, 14.0 + vr.randf() * 28.0, (vr.randf() - 0.4) * 0.5, 2.0,
						["#4e8a2c", "#62a034", "#76b23e", "#96c856", "#c2e07c"])
				for i in 10:
					var x := 6.0 + vr.randf() * 34.0
					var y := 6.0 + vr.randf() * 28.0
					var c := Color(["#fff6d8", "#ffd24a", "#8f9cff", "#ffb0cc", "#ff7a6a"][vr.randi() % 5])
					m.px(img, x - 1, y, 3, 1, c)
					m.px(img, x, y - 1, 1, 3, c)
					m.px(img, x, y, 1, 1, Color("#ffb030"))
				for i in 6:
					var x := 6.0 + vr.randf() * 34.0
					m.px(img, x - 2, 44, 2, 2, Color("#3e7a2a"))
					m.px(img, x + 1, 44, 2, 2, Color("#3e7a2a"))
					m.px(img, x, 42, 2, 2, Color("#4e8e32")))
			for b in base:
				spots.append(b)
			return [tex, 0.8, 0.55, spots, 0.12]
		5: # 짧은 잔디와 키 큰 무더기: a low even lawn everywhere, tall clumps here and there
			var tex := m.make_tex(48, 64, func(img: Image):
				for i in 70:
					blade.call(img, 2.0 + vr.randf() * 44.0, 6.0 + vr.randf() * 8.0, (vr.randf() - 0.5) * 0.4, 1.0,
						["#4a8a2a", "#5e9e34", "#78b444", "#9acc5c"])
				for i in 14:
					blade.call(img, 16.0 + vr.randf() * 16.0, 30.0 + vr.randf() * 32.0, (vr.randf() - 0.5) * 0.6, 2.0,
						["#3a6e22", "#4e8a2c", "#66a436", "#8cc452", "#b8dc7a"]))
			for b in base:
				spots.append(b)
			return [tex, 0.9, 0.85, spots, 0.12]
	return []

# ---------------------------------------------------------------- props
func build_props() -> void:
	var rock_mat := m.mat_color(Color("#6c6f78"))
	for i in 40:
		var x := m.rnd(3, Main.N - 3)
		var z := m.rnd(3, Main.N - 3)
		if m.tile_at(x, z) == Main.GRASS or m.tile_at(x, z) == Main.SAND:
			var r := m.rnd(0.12, 0.3)
			var m2 := box(Vector3(r * 1.6, r, r * 1.4), rock_mat)
			m2.position = Vector3(x, m.height_at(x, z) + r * 0.4, z)
			m2.rotation = Vector3(m.rnd(0, 0.4), m.rnd(0, 3), 0)
			m.add_child(m2)
	# bushes and voxel trees share one MultiMesh of tinted cubes
	var cubes: Array = [] # [Transform3D, Color]
	for i in 30:
		var x := m.rnd(3, Main.N - 3)
		var z := m.rnd(3, Main.N - 3)
		if m.tile_at(x, z) != Main.GRASS or Vector2(x, z).distance_to(Main.START) < 4:
			continue
		for k in 7:
			var s := m.rnd(0.35, 0.6)
			cubes.append([Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(x + m.rnd(-0.4, 0.4), m.height_at(x, z) + m.rnd(0.2, 0.7), z + m.rnd(-0.4, 0.4))),
				Color.from_hsv(0.25 + m.rnd(-0.03, 0.03), 0.55, m.rnd(0.58, 0.72))])
		m.rocks.append({"x": x, "z": z, "r": 0.6, "bush": true}) # Sora walks through low bushes (kept here so trees stay clear of them)
	var trunks: Array = []
	for i in 180:
		var x := m.rnd(3, Main.N - 3)
		var z := m.rnd(3, Main.N - 3)
		var forest := (x > 34 and z > 18) or (x < 13 and z > 28)
		if m.tile_at(x, z) != Main.GRASS or Vector2(x, z).distance_to(Main.START) < 5 or (not forest and m.rng.randf() < 0.8):
			continue
		var blocked := false
		for r in m.rocks:
			if Vector2(r.x - x, r.z - z).length() < 1.6:
				blocked = true
		if blocked:
			continue
		var v := m.rng.randf()
		var kind := "pine" if v < 0.4 else ("autumn" if v < 0.55 else "leafy")
		if Vector2(x, z).distance_to(Vector2(43.0, 21.5)) < 4.5: # the village gate's riverbank stays open (the owner, 2026-10-25:
			var gone: Array = [] # the trees there hid Sora); built and thrown away so the random draws after it stay the same
			voxel_tree(x, z, kind, [], gone)
			gone[0].free()
			m.rocks.pop_back()
			continue
		var first := cubes.size()
		voxel_tree(x, z, kind, cubes, trunks)
		marsh_trees.append({"x": x, "z": z, "trunk": trunks[-1], "first": first, "count": cubes.size() - first, "hits": 0, "rock": m.rocks[-1], "down": false})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = cubes.size()
	for i in cubes.size():
		mm.set_instance_transform(i, cubes[i][0])
		mm.set_instance_color(i, (cubes[i][1] as Color).srgb_to_linear())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.roughness = 0.9
	mmi.material_override = cm
	m.add_child(mmi)
	tree_mm = mm
	for tr in trunks:
		m.add_child(tr)

# ---- the marsh's trees can be cut down (the owner, 2026-10-27: "나무는 베어지고 -> 이내 사라진다"): three sword hits
# and a tree falls away from Sora, lies a moment, shrinks and is gone, and the way through it opens. They grow back
# when the game is loaded again.
var marsh_trees: Array = [] # {x, z, trunk, first, count (its cubes in tree_mm), hits, rock, down}
var tree_mm: MultiMesh
const TREE_HITS := 3

func chop_trees(reach: float, f: Vector2, cone: float, all_round: bool) -> void:
	for t in marsh_trees:
		if t.down:
			continue
		var d := Vector2(t.x - m.player.x, t.z - m.player.z)
		if d.length() > reach + 0.5 or not (all_round or d.normalized().dot(f) > cone):
			continue
		t.hits += 1
		var y := m.height_at(t.x, t.z)
		m.burst(Vector3(t.x, y + 0.7, t.z), Color("#a8743a"), 10, 2.2)
		m.sfx(140.0 + t.hits * 30.0, 0.08, "square", 0.18, -60.0)
		var away := d.normalized() if d.length() > 0.01 else f
		if t.hits >= TREE_HITS:
			fell_tree(t, away)
		else:
			shake_tree(t, away)

const TREE_SHAKE := 0.16 # radians of the first swing; it dies down over TREE_SHAKE_T
const TREE_SHAKE_T := 0.9

# a cut tree rocks about its foot, away from Sora first, three swings that die down, then stands as it was
func shake_tree(t: Dictionary, away: Vector2) -> void:
	if not t.has("rest"):
		var rest: Array = []
		for i in t.count:
			rest.append(tree_mm.get_instance_transform(t.first + i))
		t.rest = rest
		t.trunk_rest = (t.trunk as Node3D).transform
	if t.get("tw") is Tween and (t.tw as Tween).is_valid():
		(t.tw as Tween).kill()
	var pivot := Vector3(t.x, m.height_at(t.x, t.z), t.z)
	var axis := Vector3(away.y, 0, -away.x).normalized()
	var tw := m.create_tween()
	tw.tween_method(func(k: float): pose_tree(t, pivot, Basis(axis, -TREE_SHAKE * exp(-4.0 * k) * sin(k * TAU * 3.0))), 0.0, 1.0, TREE_SHAKE_T)
	t.tw = tw

# the tree turned by `rot` about its foot, from where it stood before the first cut
func pose_tree(t: Dictionary, pivot: Vector3, rot: Basis) -> void:
	for i in t.count:
		var o: Transform3D = t.rest[i]
		tree_mm.set_instance_transform(t.first + i, Transform3D(rot * o.basis, pivot + rot * (o.origin - pivot)))
	var tr0: Transform3D = t.trunk_rest
	(t.trunk as Node3D).transform = Transform3D(rot * tr0.basis, pivot + rot * (tr0.origin - pivot))

func fell_tree(t: Dictionary, away: Vector2) -> void:
	t.down = true
	if t.get("tw") is Tween and (t.tw as Tween).is_valid():
		(t.tw as Tween).kill() # still rocking from the last cut: it falls from where it stood
	if t.has("rest"):
		pose_tree(t, Vector3(t.x, m.height_at(t.x, t.z), t.z), Basis())
	m.rocks.erase(t.rock)
	var pivot := Vector3(t.x, m.height_at(t.x, t.z), t.z)
	var axis := Vector3(away.y, 0, -away.x).normalized() # falls away from Sora
	var start: Array = []
	for i in t.count:
		start.append(tree_mm.get_instance_transform(t.first + i))
	var trunk: Node3D = t.trunk
	var trunk0 := trunk.transform
	trunk0.basis = Basis().scaled(trunk.scale)
	var pose := func(p: float, shrink: float):
		var rot := Basis(axis, -p * PI * 0.47)
		for i in t.count:
			var o: Transform3D = start[i]
			tree_mm.set_instance_transform(t.first + i, Transform3D(rot * o.basis.scaled(Vector3.ONE * shrink), pivot + rot * (o.origin - pivot) * lerpf(1.0, 0.6, 1.0 - shrink)))
		trunk.transform = Transform3D(rot * trunk0.basis.scaled(Vector3.ONE * shrink), pivot + rot * (trunk0.origin - pivot))
	m.sfx(90, 0.4, "sawtooth", 0.22, -40)
	var tw := m.create_tween()
	tw.tween_method(func(p: float): pose.call(p * p, 1.0), 0.0, 1.0, 0.7) # slow at first, then down
	tw.tween_callback(func():
		m.shake = maxf(m.shake, 0.2)
		m.burst(pivot + Vector3(away.x * 1.6, 0.3, away.y * 1.6), Color("#8a9a5a"), 24, 3.0))
	tw.tween_interval(1.0)
	tw.tween_method(func(s: float): pose.call(1.0, s), 1.0, 0.0, 0.4)
	tw.tween_callback(func(): trunk.visible = false)

func voxel_tree(x: float, z: float, kind: String, cubes: Array, trunks: Array) -> void:
	var y0 := m.height_at(x, z)
	var sc := m.rnd(0.85, 1.15)
	var trunk_h := 1.0 if kind == "pine" else m.rnd(1.4, 2.0)
	var birch := kind == "leafy" and m.rng.randf() < 0.3
	var trunk := box(Vector3(0.32, trunk_h, 0.32) * sc, m.mat_color(Color("#e8e4d8") if birch else Color("#5a3a22")))
	trunk.position = Vector3(x, y0 + trunk_h * sc / 2.0, z)
	trunks.append(trunk)
	var hue := Vector2(0.06, 0.09) if kind == "autumn" else (Vector2(0.33, 0.37) if kind == "pine" else Vector2(0.22, 0.28))
	var add := func(s: float, p: Vector3):
		var c := Color.from_hsv(m.rnd(hue.x, hue.y), 0.85 if kind == "autumn" else 0.6, m.rnd(0.42, 0.55) if kind == "pine" else m.rnd(0.62, 0.85))
		cubes.append([Transform3D(Basis().scaled(Vector3.ONE * s * sc), Vector3(x, y0, z) + p * sc), c])
	if kind == "pine":
		for l in 5:
			var r := 1.3 - l * 0.25
			for k in 8:
				var a := k / 8.0 * TAU
				add.call(0.5, Vector3(cos(a) * r * 0.7, 1.0 + l * 0.6, sin(a) * r * 0.7))
		add.call(0.4, Vector3(0, 4.1, 0))
	else:
		for k in 26:
			var a := m.rnd(0, TAU)
			var r := m.rnd(0, 1.3)
			var h := m.rnd(-0.6, 0.8)
			add.call(m.rnd(0.45, 0.8), Vector3(cos(a) * r, trunk_h + 0.8 + h * (1.0 - r * 0.3), sin(a) * r))
	m.rocks.append({"x": x, "z": z, "r": 0.45})

# one MultiMesh of coloured boxes ([Transform3D, Color] pairs), lit by vertex colour
func multimesh_of(list: Array) -> MultiMeshInstance3D:
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.roughness = 0.9
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
	return mmi

# the same, split into 6x6 chunks so each sees only nearby lights (the web renderer lights a mesh with at most 8)
func add_chunks(blocks: Array, origin_x: int) -> void:
	var chunks := {}
	for bl in blocks:
		var o: Vector3 = bl[0].origin
		var key := Vector2i(int(o.x - origin_x) / 6, int(o.z) / 6)
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(bl)
	for key in chunks:
		multimesh_of(chunks[key])

func folk_sprite(id: String) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = load("res://art/folk/%s.png" % id)
	spr.hframes = 2
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.scale = Vector3(1, 1.0 / cos(0.78), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	var hpx := float(spr.texture.get_height())
	spr.pixel_size = m.folk_height(id) / hpx
	spr.offset = Vector2(0, hpx / 2.0)
	return spr

func lantern(x: float, z: float, post_mat: Material, glass: Material) -> void:
	var y := m.height_at(x, z)
	var pole := box(Vector3(0.12, 1.5, 0.12), post_mat)
	pole.position = Vector3(x, y + 0.75, z)
	m.add_child(pole)
	var arm := box(Vector3(0.4, 0.08, 0.08), post_mat)
	arm.position = Vector3(x + 0.15, y + 1.48, z)
	m.add_child(arm)
	var lamp := box(Vector3(0.22, 0.28, 0.22), glass)
	lamp.position = Vector3(x + 0.3, y + 1.3, z)
	m.add_child(lamp)
	var l := OmniLight3D.new()
	l.light_color = Color("#ffb45a")
	l.omni_range = 5.0
	l.omni_attenuation = 1.6
	l.position = lamp.position
	m.add_child(l)
	l.set_meta("glass", lamp)
	m.lanterns.append(l)

# a lantern lit with the bracelet leaves a faint palm print on the glass side facing Sora, for two seconds (delight idea 8)
var palm_marks := 0 # prints made (autoplay d8_palm)
var palm_last: Node3D # the latest print

func palm_mark(glass: MeshInstance3D) -> void:
	var to := Vector2(m.player.x - glass.position.x, m.player.z - glass.position.z)
	var out := Vector3(signf(to.x), 0, 0) if absf(to.x) >= absf(to.y) else Vector3(0, 0, signf(to.y)) # the glass face turned to her
	if out == Vector3.ZERO:
		out = Vector3(0, 0, 1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.92, 0.7, 0.55)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := Node3D.new()
	g.position = out * 0.113 + Vector3(0, -0.02, 0)
	g.rotation.y = atan2(out.x, out.z)
	var parts := [[Vector3(0.09, 0.1, 0.006), Vector3(0, -0.02, 0)], [Vector3(0.02, 0.06, 0.006), Vector3(-0.036, 0.06, 0)],
		[Vector3(0.02, 0.07, 0.006), Vector3(-0.012, 0.065, 0)], [Vector3(0.02, 0.07, 0.006), Vector3(0.012, 0.065, 0)],
		[Vector3(0.02, 0.06, 0.006), Vector3(0.036, 0.06, 0)], [Vector3(0.05, 0.02, 0.006), Vector3(0.06, -0.01, 0)]] # palm, four fingers, thumb
	for pt in parts:
		var b := box(pt[0], mat)
		b.position = pt[1]
		g.add_child(b)
	glass.add_child(g)
	palm_marks += 1
	palm_last = g
	var tw := g.create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tw.tween_callback(g.queue_free)

# a small cottage west of the start: plaster walls, shingled gable roof,
# stone chimney, wooden door, a warm window and a lantern by the door
func build_cottage() -> void:
	var spot := Vector2(8, 17)
	for tries in 30:
		if m.walkable(spot.x, spot.y) and m.walkable(spot.x - 1.5, spot.y) and m.walkable(spot.x + 1.5, spot.y) 				and spot.distance_to(Main.START) > 5.0:
			break
		spot = Vector2(m.rnd(5, 10), m.rnd(14, 22))
	m.cottage_at = spot
	var g := Node3D.new()
	g.position = Vector3(spot.x, m.height_at(spot.x, spot.y), spot.y)
	g.rotation.y = 0.2
	m.add_child(g)
	var wall := m.mat_color(Color("#e4dccc"))
	var trim := m.mat_color(Color("#4a3428"))
	var add := func(size: Vector3, pos: Vector3, mm: Material, rot := Vector3.ZERO) -> MeshInstance3D:
		var b := box(size, mm)
		b.position = pos
		b.rotation = rot
		g.add_child(b)
		return b
	add.call(Vector3(3.0, 1.8, 2.4), Vector3(0, 0.9, 0), wall)                 # walls
	add.call(Vector3(3.1, 0.12, 2.5), Vector3(0, 0.06, 0), trim)               # sill beam
	for x in [-1.5, 1.5]:
		add.call(Vector3(0.12, 1.8, 0.12), Vector3(x, 0.9, 1.2), trim)         # corner posts
	# gable ends: stacked shrinking plaster slabs
	for k in 5:
		add.call(Vector3(3.0, 0.2, 2.4 - k * 0.48), Vector3(0, 1.9 + k * 0.2, 0), wall)
	# roof: two slopes of shingle rows, alternating shades
	for side in [-1.0, 1.0]:
		for r in 6:
			var shade := Color("#3a3846") if r % 2 == 0 else Color("#2e2c38")
			add.call(Vector3(3.5, 0.1, 0.32), Vector3(0, 1.85 + r * 0.2, side * (1.45 - r * 0.24)), m.mat_color(shade), Vector3(side * 0.7, 0, 0))
	add.call(Vector3(3.6, 0.14, 0.2), Vector3(0, 3.05, 0), m.mat_color(Color("#24222c")))  # ridge
	var stone := m.mat_color(Color("#4a4e5e"))
	add.call(Vector3(0.45, 1.1, 0.45), Vector3(0.9, 3.0, -0.5), stone)      # chimney
	add.call(Vector3(0.55, 0.12, 0.55), Vector3(0.9, 3.58, -0.5), m.mat_color(Color("#2e3240")))
	# front: door, window with warm light, lantern
	add.call(Vector3(0.7, 1.25, 0.08), Vector3(-0.6, 0.65, 1.22), m.mat_color(Color("#5a3a26")))
	add.call(Vector3(0.08, 0.08, 0.1), Vector3(-0.35, 0.65, 1.28), m.mat_color(Color("#d9b04a")))
	add.call(Vector3(0.8, 0.7, 0.1), Vector3(0.65, 1.0, 1.22), trim)
	var pane := m.glow_mat(Color("#ffc46a"), 2.0)
	pane.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	pane.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	add.call(Vector3(0.62, 0.52, 0.1), Vector3(0.65, 1.0, 1.25), pane)
	add.call(Vector3(0.04, 0.52, 0.12), Vector3(0.65, 1.0, 1.27), trim)
	add.call(Vector3(0.62, 0.04, 0.12), Vector3(0.65, 1.0, 1.27), trim)
	var glass := m.glow_mat(Color("#ffc46a"), 4.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	add.call(Vector3(0.2, 0.26, 0.2), Vector3(-0.05, 1.4, 1.38), glass)
	add.call(Vector3(0.06, 0.06, 0.25), Vector3(-0.05, 1.58, 1.3), trim)
	var l := OmniLight3D.new()
	l.light_color = Color("#ffb45a")
	l.omni_range = 5.0
	l.omni_attenuation = 1.6
	l.position = Vector3(-0.05, 1.4, 1.6)
	g.add_child(l)
	m.lanterns.append(l)
	# chimney smoke
	var smoke := CPUParticles3D.new()
	smoke.amount = 14
	smoke.lifetime = 3.0
	smoke.direction = Vector3(0.3, 1, 0)
	smoke.spread = 12.0
	smoke.initial_velocity_min = 0.4
	smoke.initial_velocity_max = 0.7
	smoke.gravity = Vector3(0.15, 0.05, 0)
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 1.6
	var sq := QuadMesh.new()
	sq.size = Vector2(0.35, 0.35)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.85, 0.85, 0.9, 0.35)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sq.material = sm
	smoke.mesh = sq
	smoke.position = Vector3(0.9, 3.7, -0.5)
	g.add_child(smoke)
	m.shop_pos = g.transform * Vector3(-0.6, 0, 1.9)
	build_cup(g, add)
	# hanging sign over the door
	add.call(Vector3(0.7, 0.32, 0.06), Vector3(-0.6, 1.55, 1.32), m.mat_color(Color("#8a5a32")))
	var sign := sign_icon("shop", 0.4)
	sign.position = Vector3(-0.6, 1.55, 1.37)
	g.add_child(sign)
	# block the footprint
	for dx in [-1.0, 0.0, 1.0]:
		for dz in [-0.6, 0.6]:
			var w := g.transform * Vector3(dx, 0, dz)
			m.rocks.append({"x": w.x, "z": w.z, "r": 0.9})

# a teacup on a stool beside Bori's door with two puffs of steam rising and fading, round and round. It is all decoration
# and does not look at the shop at all: buying nothing, or leaving, changes nothing about it (delight idea 21)
var cup_steam: Array = [] # [MeshInstance3D, phase]
var cup_top := 0.0 # height of the cup's rim above the cottage floor

func build_cup(g: Node3D, add: Callable) -> void:
	add.call(Vector3(0.3, 0.3, 0.3), Vector3(-1.15, 0.15, 1.55), m.mat_color(Color("#6b4a30")))   # stool
	add.call(Vector3(0.14, 0.11, 0.14), Vector3(-1.15, 0.355, 1.55), m.mat_color(Color("#f0e8d8"))) # cup
	add.call(Vector3(0.05, 0.05, 0.03), Vector3(-1.07, 0.36, 1.55), m.mat_color(Color("#f0e8d8")))  # handle
	cup_top = 0.42
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1, 1, 1, 0.4)
	for k in 2:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.14, 0.14)
		q.mesh = qm
		q.material_override = mat.duplicate()
		q.position = Vector3(-1.15, cup_top, 1.55)
		g.add_child(q)
		cup_steam.append([q, k * 0.5])
	update_cup()

func update_cup() -> void:
	for s in cup_steam:
		var k: float = fmod(m.t * 0.45 + s[1], 1.0) # 0 at the rim, 1 gone
		var q: MeshInstance3D = s[0]
		q.position.y = cup_top + k * 0.5
		q.position.x = -1.15 + sin(k * 6.0 + s[1] * 4.0) * 0.04
		q.scale = Vector3.ONE * (0.7 + k * 0.9)
		(q.material_override as StandardMaterial3D).albedo_color.a = sin(k * PI) * 0.45

func ui_font_for_sign() -> Font:
	return m.ui_font

func sign_icon(kind: String, size := 0.5) -> Sprite3D:
	if not m.sign_cache.has(kind):
		var img := Image.new()
		img.load_svg_from_string(SIGN_SVG[kind], 4.0) # 192 px
		img.generate_mipmaps()
		m.sign_cache[kind] = ImageTexture.create_from_image(img)
	var sp := Sprite3D.new()
	sp.texture = m.sign_cache[kind]
	sp.pixel_size = size / 192.0
	sp.shaded = false
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	return sp

func build_lights() -> void:
	var post_mat := m.mat_color(Color("#3b2a1e"))
	var glass := m.glow_mat(Color("#ffc46a"), 4.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glass.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	# a lantern post at both ends of every bridge
	for br in m.bridges:
		for x in [br.a - 1.6, br.b + 1.6]:
			lantern(x, br.z - 0.6, post_mat, glass)
	# and a few more along the meadow: by the start, the lakeshore, the high meadow, the forest edges
	for p in [Vector2(13, 17), Vector2(18, 24), Vector2(17, 33), Vector2(31, 36), Vector2(33, 13),
			Vector2(39, 9), Vector2(34, 22), Vector2(9, 27)]:
		var spot: Vector2 = p
		for tries in 12: # nudge off water, bushes and trees
			if m.walkable(spot.x, spot.y) and m.tile_at(spot.x, spot.y) == Main.GRASS:
				break
			spot = p + Vector2(m.rnd(-2, 2), m.rnd(-2, 2))
		if m.walkable(spot.x, spot.y):
			lantern(spot.x, spot.y, post_mat, glass)
			m.rocks.append({"x": spot.x, "z": spot.y, "r": 0.25})
	# slanted sun shafts: long additive quads in a loose ring around the play area
	var shaft := m.make_tex(16, 64, func(img: Image):
		for y in 64:
			for x in 16:
				var a := sin(PI * x / 15.0) * (1.0 - y / 64.0)
				img.set_pixel(x, y, Color(1, 0.9, 0.65, a * 0.5)))
	for i in 14:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(m.rnd(1.2, 2.4), 14.0)
		q.mesh = qm
		var mm := StandardMaterial3D.new()
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mm.cull_mode = BaseMaterial3D.CULL_DISABLED
		mm.albedo_texture = shaft
		mm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		mm.no_depth_test = false
		q.material_override = mm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.position = Vector3(m.rnd(4, Main.N - 4), 6.0, m.rnd(4, Main.N - 4))
		q.rotation.z = 0.5 # lean with the sun
		m.add_child(q)
		m.sunbeams.append([q, mm, m.rnd(0, TAU)])

func update_lights() -> void:
	for l in m.lanterns:
		if l == m.dark_lamp or l.get_meta("dark", false):
			l.light_energy = 0.0
			continue
		l.light_energy = (0.6 + m.night * 2.4) * (1.0 + sin(m.t * 9.0 + l.position.x) * 0.05)
	for b in m.sunbeams:
		b[1].albedo_color = Color(1, 1, 1, m.beams * (0.55 + 0.45 * sin(m.t * 0.5 + b[2])))

# the field chests' shut and opened pictures, made before any map builds a chest from them (no random draws)
func chest_textures() -> void:
	var tex := m.make_tex(16, 14, func(img: Image):
		m.px(img, 1, 3, 14, 11, Color("#7a4a24"))
		m.px(img, 1, 3, 14, 4, Color("#9a6232"))
		m.px(img, 1, 7, 14, 1, Color("#3a2312"))
		m.px(img, 0, 3, 1, 11, Color("#d9b04a"))
		m.px(img, 15, 3, 1, 11, Color("#d9b04a"))
		m.px(img, 7, 6, 2, 3, Color("#ffd84a")))
	# opened, draft 5 of 5 (the owner, 2026-10-27: the tipped-back lid floated above the box): wide open, the lid fallen
	# back behind on two gold hinges, its gold rim on top, the inside dark under a lit back wall, the hasp hanging loose
	var open_tex := m.make_tex(16, 14, func(img: Image):
		m.px(img, 1, 0, 14, 3, Color("#5a3618")) # the lid's inner face
		m.px(img, 1, 0, 14, 1, Color("#d9b04a"))
		m.px(img, 3, 2, 2, 1, Color("#d9b04a")) # hinges
		m.px(img, 11, 2, 2, 1, Color("#d9b04a"))
		m.px(img, 1, 3, 14, 11, Color("#7a4a24"))
		m.px(img, 2, 3, 12, 1, Color("#9a6232"))
		m.px(img, 2, 4, 12, 5, Color("#1e120a")) # the empty inside
		m.px(img, 2, 4, 12, 1, Color("#4a2c16"))
		m.px(img, 1, 9, 14, 1, Color("#3a2312"))
		m.px(img, 0, 3, 1, 11, Color("#d9b04a"))
		m.px(img, 15, 3, 1, 11, Color("#d9b04a"))
		m.px(img, 7, 10, 2, 3, Color("#ffd84a")) # the hasp, hanging
		m.px(img, 7, 10, 2, 1, Color("#d9b04a")))
	m.chest_open_tex = open_tex
	m.chest_shut_tex = tex

# E at a chest she has already opened: only the dust in the lid stirs and the empty floor shows; no loot is rolled (delight idea 10)
var chest_peeks := 0 # peeks shown (autoplay d10_empty_chest)
var chest_peek_t := -10.0

func chest_peek() -> bool:
	if m.t - chest_peek_t < 1.5:
		return false
	for c in m.chests:
		if c.open and Vector2(c.x - m.player.x, c.z - m.player.z).length() < 1.5:
			chest_peek_t = m.t
			chest_peeks += 1
			m.burst(Vector3(c.x, m.height_at(c.x, c.z) + 0.5, c.z), Color("#c8b898"), 6, 0.6)
			m.sfx(196, 0.08, "triangle", 0.05, -40.0)
			m.toast(tr("뚜껑 안은 비었고 먼지만 날린다"))
			return true
	return false

func build_chests() -> void:
	var tex: Texture2D = m.chest_shut_tex
	for p in [Vector2(17, 21), Vector2(24, 39), Vector2(40, 8), Vector2(7, 40), Vector2(42, 30)]:
		if not m.walkable(p.x, p.y):
			continue
		var s := Sprite3D.new()
		s.texture = tex
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.scale = Vector3(1, 1.0 / cos(0.78), 1)
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.shaded = false
		s.pixel_size = 0.05
		s.offset = Vector2(0, 7)
		s.position = Vector3(p.x, m.height_at(p.x, p.y), p.y)
		m.add_child(s)
		m.blob(0.8).position = Vector3(p.x, m.height_at(p.x, p.y) + 0.02, p.y)
		m.chests.append({"x": p.x, "z": p.y, "node": s, "open": false})
