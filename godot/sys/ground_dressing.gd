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

# a clump of cosmos (the owner, 2026-10-28: flowers that sway in the wind, in the village): four or five thin stems
# twice the grass's height with feathery leaves, each topped by an eight-petal flower in pink, magenta or white
# around a yellow middle; drawn tall so the grass shader (sway grows with height) rocks the heads the most
func cosmos_tex(petals: Array) -> ImageTexture:
	return m.make_tex(48, 96, func(img: Image):
		var stem := Color("#4f8a34")
		var leaf := Color("#6aa646")
		for i in 4 + rng.randi() % 2:
			var x := 8.0 + rng.randf() * 32.0
			var h := 56.0 + rng.randf() * 34.0
			var bend := rng.randf_range(-0.12, 0.12)
			for y in int(h):
				m.px(img, x, 95 - y, 1, 1, stem)
				if y > 10 and y < h - 12 and y % 9 == 0: # feathery leaves: short thin sprigs either side
					var side := 1.0 if (y / 9) % 2 == 0 else -1.0
					for k in 4:
						m.px(img, x + side * (k + 1), 95 - y - k * 0.6, 1, 1, leaf)
				x += bend
			var cx := x
			var cy := 95.0 - h
			var c := Color(petals[rng.randi() % petals.size()])
			for a in 8: # petals 2 px wide out to 7 px, the tips a shade lighter so the head reads in warm light
				var ang := a * TAU / 8.0 + rng.randf() * 0.2
				for r in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]:
					m.px(img, cx + cos(ang) * r, cy + sin(ang) * r * 0.8, 2, 2, c.lightened(0.25) if r >= 6.0 else c)
			m.px(img, cx - 1, cy - 1, 3, 3, Color("#ffcf3a")))

# wind anemones (바람꽃, the owner 2026-10-28, round the wind hill's rest lanterns): three to five hair-thin stems
# about twice the grass's height, a pair of cut leaves low down, and one small five-petal head each, white or pale
# lilac with a yellow eye; light heads on long stems so they nod the most in the wind
func anemone_tex(petals: Array) -> ImageTexture:
	return m.make_tex(48, 80, func(img: Image):
		for i in 3 + rng.randi() % 3:
			var x := 8.0 + rng.randf() * 32.0
			var h := 40.0 + rng.randf() * 30.0
			var bend := rng.randf_range(-0.15, 0.15)
			for k in 3: # the leaves at the foot
				m.px(img, x - 3 + k * 2, 76 - k, 2, 1, Color("#5e9a3e"))
			for y in int(h):
				m.px(img, x, 79 - y, 1, 1, Color("#5a8a3a"))
				x += bend
			var c := Color(petals[rng.randi() % petals.size()])
			var cy := 79.0 - h
			for a in 5:
				var ang := a * TAU / 5.0 - PI / 2.0
				for r in [1.5, 2.5, 3.5]:
					m.px(img, x + cos(ang) * r, cy + sin(ang) * r * 0.8, 2, 2, c)
			m.px(img, x, cy, 1, 1, Color("#ffd23a")))

# silver grass (억새, along the wind hill's slopes): a fountain of long blades bending one way, each with a pale
# feathery plume at its tip; drawn tall so it waves like a field
func plume_tex() -> ImageTexture:
	return m.make_tex(48, 96, func(img: Image):
		for i in 14:
			var x := 10.0 + rng.randf() * 28.0
			var h := 50.0 + rng.randf() * 40.0
			var bend := 0.25 + rng.randf() * 0.25
			for y in int(h):
				var k := y / h
				m.px(img, x, 95 - y, 1, 1, Color("#7a9a4a").lerp(Color("#b8b088"), k))
				x += bend * k
			if i % 2 == 0: # a plume on every other blade: silver, a little pink at the root
				for p in 12:
					m.px(img, x - p * 0.35 + rng.randf(), 95 - h + p, 1, 1, Color("#f2eee4") if p > 3 else Color("#e6c8c0")))

# one picture for each place's signature plant (the owner, 2026-10-28: "다른 장소에도 각각에 맞는 식물"; the picks and
# colours are GPT's, scratchpad plants/codex.log). `o` keys: h (px, 48 or 96), stems, lo/hi (stem px), stem, leaf,
# leaves ("pair", "blade", "needle", "round", "none"), head ("star", "spike", "bells", "pom", "umbrella", "iris",
# "nod", "moss"), petals (colours), centre, n (petals), r (head radius px)
func bloom_tex(o: Dictionary) -> ImageTexture:
	var hh: int = o.get("h", 48)
	return m.make_tex(48, hh, func(img: Image): _bloom_draw(img, o, hh))

func _bloom_draw(img: Image, o: Dictionary, hh: int) -> void:
	var petals: Array = o.petals
	for i in int(o.get("stems", 3)):
		var x := 8.0 + rng.randf() * 32.0
		var h := rnd(float(o.lo), float(o.hi))
		var bend := rnd(-0.12, 0.12)
		var leaf := Color(o.get("leaf", o.stem))
		match String(o.get("leaves", "pair")):
			"pair":
				for k in 3:
					m.px(img, x - 3 + k, hh - 4 - k, 1, 1, leaf)
					m.px(img, x + 1 + k, hh - 4 - k, 1, 1, leaf)
			"blade": # sword leaves from the foot, as tall as the stem
				for side in [-1.0, 1.0]:
					for y in int(h * 0.8):
						m.px(img, x + side * (1.0 + y * 0.06), hh - 1 - y, 1, 1, leaf)
			"needle":
				for k in 6:
					m.px(img, x + rnd(-4, 4), hh - 1 - rnd(0, 6), 1, 2, leaf)
			"round":
				m.px(img, x - 4, hh - 4, 3, 2, leaf)
				m.px(img, x + 2, hh - 5, 3, 2, leaf)
		for y in int(h):
			m.px(img, x, hh - 1 - y, 1, 1, Color(o.stem))
			x += bend
		var cy := float(hh - 1) - h
		var c := Color(petals[rng.randi() % petals.size()])
		var r: float = o.get("r", 3.0)
		match String(o.get("head", "star")):
			"star":
				var n: int = o.get("n", 5)
				for a in n:
					var ang := a * TAU / n - PI / 2.0
					for rr in range(1, int(r) + 1):
						m.px(img, x + cos(ang) * rr, cy + sin(ang) * rr * 0.8, 2, 2, c)
				m.px(img, x, cy, 2, 2, Color(o.get("centre", "#ffd23a")))
			"spike": # small florets stacked up the top of the stem
				for k in int(r * 3):
					m.px(img, x + (1 if k % 2 == 0 else -2), cy + k, 2, 1, Color(petals[k % petals.size()]))
			"bells": # an arching stalk with little hanging bells
				for k in 4:
					var bx := x + 1 + k * 2
					m.px(img, bx, cy + k, 1, 1, Color(o.stem))
					m.px(img, bx - 1, cy + k + 1, 3, 2, c)
			"nod": # one white flower hanging from a curled tip
				m.px(img, x + 1, cy, 2, 1, Color(o.stem))
				m.px(img, x + 2, cy + 1, 2, 4, c)
				m.px(img, x + 2, cy + 5, 2, 1, Color(o.get("centre", "#9ac89a")))
			"pom": # a round ball of tiny flowers
				for k in 10:
					m.px(img, x + rnd(-r, r), cy + rnd(-r, r) * 0.8, 2, 2, Color(petals[k % petals.size()]))
			"umbrella": # a flat glowing cap on a short stalk
				m.px(img, x - r, cy, r * 2 + 1, 2, c)
				m.px(img, x - r + 1, cy - 1, r * 2 - 1, 1, Color(o.get("centre", "#e0fff0")))
			"iris": # three falls and a standard
				m.px(img, x - 3, cy + 2, 3, 3, c)
				m.px(img, x + 1, cy + 2, 3, 3, c)
				m.px(img, x - 1, cy - 2, 2, 4, Color(petals[(rng.randi() + 1) % petals.size()]))
				m.px(img, x - 1, cy + 3, 2, 1, Color(o.get("centre", "#e4c96b")))
			"moss": # short star tips and two spore stalks
				m.px(img, x - 1, cy, 3, 1, c)

# floor tiles (chars in `floor`) with a char of `wall` beside them (4 ways), every `mod`th by a fixed hash, rows z0..z1:
# where the cave, grotto, castle and cloud plants grow
func wall_feet(grid: Array, origin_x: int, floor: String, wall: String, mod: int, z0 := 0, z1 := 999) -> Array:
	var out: Array = []
	for z in range(maxi(z0, 1), mini(z1, grid.size() - 1)):
		var row: String = grid[z]
		for x in range(1, row.length() - 1):
			if not row[x] in floor or (x * 7 + z * 13) % mod != 0:
				continue
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var zz: int = z + dd.y
				var xx: int = x + dd.x
				if zz >= 0 and zz < grid.size() and xx >= 0 and xx < String(grid[zz]).length() and String(grid[zz])[xx] in wall:
					out.append(Vector2(origin_x + x, z))
					break
	return out

# a place's plant on `tiles`: `per` clumps a tile, scaled lo..hi; never in the clearable vegetation, never counted
# with the grass tufts the dressing tests count
func plant(o: Dictionary, w: float, h: float, tiles: Array, per: int, sway: float, y := 0.0) -> MultiMesh:
	return grass(bloom_tex(o), w, h, spots_on(tiles, y, per, 0.75, 1.1), sway, false)

# tufts at spots (Vector4 x, ground y, z, scale), swaying with the grass shader; phones draw half, as in the marsh.
# With `clearable` they join m.veg_meshes, so story.clear_vegetation can clear them like the marsh's; the maps that
# never clear any stay out of it, so that loop does not walk thousands of tufts it will never move. Returns the mesh.
func grass(tex: Texture2D, w: float, h: float, spots: Array, strength: float, clearable := true) -> MultiMesh:
	if m.touch_ui:
		spots = spots.filter(func(sp): return int(sp.x * 7.0 + sp.z * 13.0) % 2 == 0)
	if spots.is_empty():
		return null
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
	if clearable:
		m.veg_meshes.append(mm)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/grass.gdshader")
	sm.set_shader_parameter("tex", tex)
	sm.set_shader_parameter("strength", strength)
	mmi.material_override = sm
	m.add_child(mmi)
	return mm

# `per_tile` tuft spots on each world tile in `tiles` (Vector2 of tile centres), at ground height `y`
func spots_on(tiles: Array, y: float, per_tile: int, lo := 0.7, hi := 1.15) -> Array:
	var out: Array = []
	for t in tiles:
		for k in per_tile:
			out.append(Vector4(t.x + rnd(-0.5, 0.5), y, t.y + rnd(-0.5, 0.5), rnd(lo, hi)))
	return out

# ---------------------------------------------------------------- the other maps (village, lake, forest, stairs, garden)
# Each map dresses itself from its own random stream (begin/end), so adding one never moves another map's tufts:
# the hill's stay exactly where they were.
var saved_state := 0

func begin(s: int) -> void:
	saved_state = rng.state
	rng.seed = s

func end() -> void:
	rng.state = saved_state

# is a used tile within `ring` tiles of local tile (x, z)? `at` is the map's char lookup in local tiles; `clear`
# lists the chars to keep clear (paths, doors, marks, water, walls that open); `keep` adds local Vector2i spots
# that have no char of their own (villagers' spots, props, cages)
func near_clear(at: Callable, x: int, z: int, clear: String, keep: Array, ring := 1) -> bool:
	for dz in range(-ring, ring + 1):
		for dx in range(-ring, ring + 1):
			if at.call(x + dx, z + dz) in clear:
				return true
	for k in keep:
		if absi(k.x - x) <= ring and absi(k.y - z) <= ring:
			return true
	return false

# the tiles of a map (rows z0 to z1) that may take plants: their char is in `open` and nothing used is near
func pick_tiles(at: Callable, origin_x: int, w: int, z0: int, z1: int, open: String, clear: String, keep: Array, ring := 1) -> Array:
	var out: Array = []
	for z in range(z0, z1):
		for x in w:
			if at.call(x, z) in open and not near_clear(at, x, z, clear, keep, ring):
				out.append(Vector2(origin_x + x, z))
	return out

# a fern: a few arching fronds from one root, each with little leaflets down both sides
func fern_tex(dark: Color, light: Color) -> ImageTexture:
	return m.make_tex(48, 48, func(img: Image):
		for f in 7:
			var ang := lerpf(-1.25, 1.25, f / 6.0) + rng.randf_range(-0.12, 0.12)
			var length := rng.randf_range(26.0, 40.0)
			var x := 24.0
			var y := 47.0
			for k in int(length):
				var t := k / length
				var a := ang * (0.3 + t * 1.1) # the frond bows outward as it grows
				x += sin(a) * 0.9
				y -= cos(a) * 0.9
				var c := dark.lerp(light, t)
				m.px(img, x, y, 1, 1, c)
				if k % 3 == 0 and t > 0.15:
					var leaf := 5.0 * (1.0 - t) + 1.0
					m.px(img, x - leaf, y, leaf, 1, c.darkened(0.08))
					m.px(img, x + 1, y, leaf, 1, c.lightened(0.05)))

# a few small mushrooms on a mossy foot: pale stems, round caps from `caps`, white spots on the red ones
func mushroom_tex(caps: Array) -> ImageTexture:
	return m.make_tex(48, 48, func(img: Image):
		for i in 9: # moss at the foot
			m.px(img, 8 + rng.randf() * 30.0, 44 + rng.randf() * 3.0, 4, 1, Color("#4f6a3a"))
		for k in 3:
			var x := 10.0 + k * 11.0 + rng.randf_range(-2.0, 2.0)
			var h := rng.randf_range(7.0, 14.0)
			var cw := rng.randf_range(7.0, 11.0)
			var cap := Color(caps[rng.randi() % caps.size()])
			m.px(img, x, 47 - h, 2, h, Color("#efe6d2"))
			m.px(img, x + 1 - cw / 2.0, 47 - h - 3, cw, 3, cap)
			m.px(img, x + 2 - cw / 2.0, 47 - h - 5, cw - 2, 2, cap.lightened(0.1))
			m.px(img, x + 1 - cw / 2.0, 47 - h, cw, 1, cap.darkened(0.3))
			if cap.r > cap.g * 1.6:
				m.px(img, x - 1, 47 - h - 4, 1, 1, Color.WHITE)
				m.px(img, x + 2, 47 - h - 2, 1, 1, Color.WHITE))

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
