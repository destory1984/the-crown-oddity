# Reed-marsh toys (the owner chose items 1, 2, 3, 5 and 6 of shots/plans/marsh_plan.md, 2026-10-30): the wind-up duck on the
# NW pond, three frogs on its bank, three ripe cattails that shed their fluff, the reed pipe rack and Bori's mat by the
# cottage. Boxes, planes and code-made sounds only: no light (the marsh ground takes 8 at most), no collision, no reward.
# Every spot is searched at build time on free ground and kept off the opening walk from the start to Bori's door.
# Moved by update(dt), so the world waiting (a story, the shop, the settings) stops them too.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const POND := Vector2(9, 11)       # the NW pond's middle, water out to 3.2 tiles
const WATER_Y := -0.22
const COTTAGE_YAW := 0.2           # world_build.build_cottage turns the cottage by this
const LANE_CLEAR := 2.5            # tiles kept clear of the walk from the start to Bori's door
const USE_R := 1.4                 # E reaches this far from a toy
const DUCK_LOOP := 6.0
const DUCK_COOL := 3.0
const DUCK_R := 1.9                # the duck's circle round the pond's middle
const FROG_FLEE := 2.0
const FROG_STILL := 3.0
const FROG_HOP := 0.35
const FLUFF_NEAR := 0.9
const FLUFF_DRIFT := 2.5
const FLUFF_RESET := 20.0
const PIPE_COOL := 8.0
const PIPE_NOTES := [[0.0, 523.0], [0.22, 659.0], [0.44, 587.0]] # [seconds after E, Hz] of the three breathy notes
const PIPE_ANSWER := [[0.8, 988.0], [1.08, 784.0]]                # the far answer in the reeds, quieter
const FLUFF_PUFFS := [Vector3(0.0, 0.0, 0.0), Vector3(0.12, 0.08, -0.1), Vector3(-0.1, 0.04, 0.12), Vector3(0.06, 0.12, 0.1)]

var taken: Array = []       # [Vector2, radius] of what is placed, so the toys keep clear of one another
var mats := {}
var pads: Array = []        # [Vector2, radius] where the grass is cleared for a toy

# the wind-up duck
var duck: Node3D
var duck_body: Node3D
var duck_key: Node3D
var duck_feet: Array = []
var crank: Node3D
var duck_handle := Vector2(-1, -1)
var duck_a0 := 0.0
var duck_state := "rest"    # rest, run, cool
var duck_t := 0.0
var duck_cool_t := 0.0
var duck_runs := 0          # times it was wound (autoplay marsh_duck)

# the frogs
var frogs: Array = []       # {perch, land, node, state sit/out/gone/back, t}
var frog_me := Vector2(-99, -99)
var frog_still := 0.0
var frog_flees := 0
var frog_returns := 0

# the cattails and their fluff
var cattails: Array = []    # {pos, node, top, fuzz, ready, reset_t, sway}
var fluff: Array = []       # twelve pooled quads: {node, t, p0, v, phase}
var fluff_puffs := 0

# the pipe rack
var rack: Node3D
var rack_at := Vector2(-1, -1)
var pipes: Array = []
var pipe_ready_t := 0.0     # m.t when it can be played again
var pipe_t := -1.0          # seconds since E while the notes play, -1 when quiet
var pipe_next := 0          # the next note or answer to sound
var pipe_times: Array = []  # m.t at each sound it made (autoplay marsh_pipe)
var pipe_plays := 0

# Bori's mat
var mat_at := Vector2(-1, -1)
var mat_node: Node3D

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- finding free ground
func lane_dist(p: Vector2) -> float: # distance to the opening walk, the start to Bori's door
	var a := Main.START
	var ab := Vector2(m.shop_pos.x, m.shop_pos.z) - a
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0))

func spot_ok(p: Vector2, clear: float) -> bool:
	if p.x < 3.0 or p.y < 3.0 or p.x > Main.N - 4.0 or p.y > Main.N - 4.0:
		return false
	for d in [Vector2.ZERO, Vector2(clear, 0), Vector2(-clear, 0), Vector2(0, clear), Vector2(0, -clear)]:
		if m.tile_at(p.x + d.x, p.y + d.y) == Main.WATER:
			return false
	for r in m.rocks: # trees, lamps, the cottage, bushes (a bush is drawn wider than its blocker)
		if Vector2(r.x, r.z).distance_to(p) < r.r + clear + (0.4 if r.has("bush") else 0.0):
			return false
	if lane_dist(p) < LANE_CLEAR or p.distance_to(Vector2(m.shop_pos.x, m.shop_pos.z)) < 2.8 or p.distance_to(Main.START) < 5.0:
		return false
	for tk in taken:
		if p.distance_to(tk[0]) < tk[1] + clear:
			return false
	return true

# the first free spot at or round a candidate (rings of 0.4 tiles out to `reach`), or (-1, -1)
func find_spot(cands: Array, clear: float, reach := 2.0, pred := Callable()) -> Vector2:
	for c: Vector2 in cands:
		var r := 0.0
		while r <= reach:
			var n := 1 if r == 0.0 else int(r * 12.0)
			for k in n:
				var p := c + Vector2.from_angle(TAU * k / n) * r
				if spot_ok(p, clear) and (not pred.is_valid() or pred.call(p)):
					return p
			r += 0.4
	return Vector2(-1, -1)

func cot(local: Vector2) -> Vector2: # a spot in the cottage's own frame, in the world
	return m.cottage_at + Vector2(local.x * cos(COTTAGE_YAW) + local.y * sin(COTTAGE_YAW), -local.x * sin(COTTAGE_YAW) + local.y * cos(COTTAGE_YAW))

func mat(hex: String) -> StandardMaterial3D:
	if not mats.has(hex):
		mats[hex] = m.mat_color(Color(hex))
	return mats[hex]

func part(parent: Node3D, size: Vector3, pos: Vector3, hex: String) -> MeshInstance3D:
	var b: MeshInstance3D = m.box(size, mat(hex))
	b.position = pos
	parent.add_child(b)
	return b

func put(node: Node3D, at: Vector2, pad: float) -> void: # stand a toy on the ground and clear the grass round it
	node.position = Vector3(at.x, m.height_at(at.x, at.y), at.y)
	m.add_child(node)
	taken.append([at, pad])
	pads.append([at, pad])

# ---------------------------------------------------------------- build
func build() -> void:
	build_duck()
	build_frogs()
	build_cattails()
	build_rack()
	build_mat()
	clear_pads()

func clear_pads() -> void: # one pass over the grass for every pad
	for mm in m.veg_meshes:
		for i in mm.instance_count:
			var o: Vector3 = mm.get_instance_transform(i).origin
			for pd in pads:
				if Vector2(o.x, o.z).distance_to(pd[0]) < pd[1]:
					mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.001), o))
					break

func build_duck() -> void:
	duck_handle = find_spot([Vector2(9, 15), Vector2(10.5, 14.6), Vector2(7.5, 14.8), Vector2(11.5, 13.5)], 0.4, 1.2,
		func(p: Vector2): return p.distance_to(POND) > 3.3 and p.distance_to(POND) < 5.2)
	if duck_handle.x < 0.0:
		return
	var post := Node3D.new() # a post with a brass crank: E turns it and the spring is wound
	part(post, Vector3(0.14, 0.5, 0.14), Vector3(0, 0.25, 0), "#8a5a32")
	part(post, Vector3(0.22, 0.05, 0.22), Vector3(0, 0.52, 0), "#d9b04a")
	crank = Node3D.new()
	crank.position = Vector3(0, 0.58, 0)
	post.add_child(crank)
	part(crank, Vector3(0.34, 0.04, 0.05), Vector3(0.14, 0, 0), "#d9b04a")
	part(crank, Vector3(0.08, 0.1, 0.08), Vector3(0.3, 0.04, 0), "#c8562e")
	put(post, duck_handle, 0.5)
	var dir := (duck_handle - POND).normalized()
	duck_a0 = atan2(dir.y, dir.x)
	duck = Node3D.new() # the duck faces +z; 0.6 tile from tail to beak
	duck_body = Node3D.new()
	duck.add_child(duck_body)
	part(duck_body, Vector3(0.28, 0.15, 0.4), Vector3(0, 0.1, 0), "#f2c640")        # body
	part(duck_body, Vector3(0.16, 0.12, 0.12), Vector3(0, 0.14, -0.22), "#e0b030")  # tail
	part(duck_body, Vector3(0.18, 0.17, 0.18), Vector3(0, 0.26, 0.16), "#f2c640")   # head
	part(duck_body, Vector3(0.12, 0.05, 0.11), Vector3(0, 0.24, 0.28), "#e8873a")   # beak
	for s in [-1.0, 1.0]:
		part(duck_body, Vector3(0.04, 0.04, 0.03), Vector3(0.07 * s, 0.31, 0.24), "#3a3228") # eyes
		part(duck_body, Vector3(0.04, 0.1, 0.26), Vector3(0.15 * s, 0.12, -0.02), "#e0b030") # wings
	duck_key = Node3D.new() # the wind-up key on its back
	duck_key.position = Vector3(0, 0.19, -0.06)
	duck_body.add_child(duck_key)
	part(duck_key, Vector3(0.03, 0.1, 0.03), Vector3(0, 0.05, 0), "#d9b04a")
	part(duck_key, Vector3(0.18, 0.03, 0.06), Vector3(0, 0.1, 0), "#d9b04a")
	for s in [-1.0, 1.0]:
		var foot: MeshInstance3D = part(duck, Vector3(0.07, 0.03, 0.12), Vector3(0.07 * s, 0.03, 0.0), "#e8873a")
		duck_feet.append(foot)
	m.add_child(duck)
	place_duck(duck_a0, 0.0)

func place_duck(a: float, k: float) -> void:
	var p := POND + Vector2(cos(a), sin(a)) * DUCK_R
	duck.position = Vector3(p.x, WATER_Y - 0.02 + sin(m.t * 3.0) * 0.012, p.y)
	duck.rotation.y = -a # forward is the way round the circle
	duck_body.rotation.z = sin(duck_t * 9.0) * 0.07 if duck_state == "run" else 0.0
	duck_key.rotation.y = -TAU * 3.0 * (1.0 - pow(1.0 - k, 2.0)) # the spring runs down
	var kick := sin(duck_t * 14.0) * 0.05 if duck_state == "run" else 0.0
	duck_feet[0].position.z = kick
	duck_feet[1].position.z = -kick

func build_frogs() -> void:
	if duck_handle.x < 0.0:
		return
	var cands: Array = []
	for deg in [225, 180, 270, 315, 135]: # the pond's west and north banks, away from the duck's south bank
		cands.append(POND + Vector2.from_angle(deg_to_rad(deg)) * 3.7)
	for c: Vector2 in cands:
		if frogs.size() >= 3:
			break
		var p := find_spot([c], 0.3, 0.8, func(q: Vector2): return q.distance_to(POND) > 3.3 and q.distance_to(POND) < 4.6 and q.distance_to(duck_handle) > 3.0)
		if p.x < 0.0:
			continue
		var dir := (POND - p).normalized()
		var node := Node3D.new() # three boxes, 0.25 tile long
		var yaw := atan2(dir.x, dir.y)
		part(node, Vector3(0.2, 0.1, 0.25), Vector3(0, 0.07, 0), "#4f8a34")
		part(node, Vector3(0.16, 0.08, 0.1), Vector3(0, 0.1, 0.14), "#5f9c3e")
		part(node, Vector3(0.2, 0.04, 0.05), Vector3(0, 0.17, 0.14), "#e8d86a")
		node.rotation.y = yaw
		put(node, p, 0.6)
		frogs.append({"perch": p, "land": POND + (p - POND).normalized() * 2.75, "node": node, "state": "sit", "t": 0.0, "yaw": yaw})

func build_cattails() -> void:
	var c := find_spot([Vector2(12, 23.4), Vector2(14, 24.5), Vector2(10, 24)], 0.6, 2.5)
	if c.x < 0.0:
		return
	for off in [Vector2(-0.55, 0.15), Vector2(0.1, -0.4), Vector2(0.6, 0.3)]:
		var p := find_spot([c + off], 0.25, 0.9)
		if p.x < 0.0:
			continue
		var node := Node3D.new() # a tall stalk with a brown head and pale seed fuzz on top
		part(node, Vector3(0.035, 1.1, 0.035), Vector3(0, 0.55, 0), "#7aa63a")
		var blade: MeshInstance3D = part(node, Vector3(0.05, 0.7, 0.02), Vector3(0.08, 0.35, 0), "#6a9a30")
		blade.rotation.z = -0.25
		var top := Node3D.new()
		top.position = Vector3(0, 0.95, 0)
		node.add_child(top)
		part(top, Vector3(0.09, 0.3, 0.09), Vector3(0, 0.15, 0), "#5a4630")
		var fz: MeshInstance3D = part(top, Vector3(0.13, 0.12, 0.13), Vector3(0, 0.36, 0), "#ece4bc")
		node.position = Vector3(p.x, m.height_at(p.x, p.y), p.y)
		m.add_child(node)
		taken.append([p, 0.3])
		cattails.append({"pos": p, "node": node, "top": top, "fuzz": fz, "ready": true, "reset_t": 0.0, "sway": 0.0})
	if cattails.is_empty():
		return
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8) # a soft round dot
	for y in 8:
		for x in 8:
			var d := Vector2(x - 3.5, y - 3.5).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d / 4.0, 0.0, 1.0)))
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.albedo_texture = ImageTexture.create_from_image(img)
	fm.albedo_color = Color("#fffbea")
	fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for i in 12:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.14, 0.14)
		q.mesh = qm
		q.material_override = fm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.visible = false
		m.add_child(q)
		fluff.append({"node": q, "t": -1.0, "p0": Vector3.ZERO, "v": Vector3.ZERO, "phase": i * 0.9})

func build_rack() -> void:
	rack_at = find_spot([cot(Vector2(2.5, 0.9)), cot(Vector2(2.5, -0.5)), cot(Vector2(-2.6, 1.2))], 0.4, 1.5)
	if rack_at.x < 0.0:
		return
	rack = Node3D.new() # two posts and a bar, 0.7 wide, five reed pipes hanging by length
	for s in [-1.0, 1.0]:
		part(rack, Vector3(0.06, 0.55, 0.06), Vector3(0.32 * s, 0.275, 0), "#8a5a32")
	part(rack, Vector3(0.7, 0.05, 0.07), Vector3(0, 0.5, 0), "#6a4424")
	for i in 5:
		var holder := Node3D.new() # swings from the bar
		holder.position = Vector3(-0.24 + i * 0.12, 0.48, 0.06)
		rack.add_child(holder)
		var ln := 0.42 - i * 0.05
		part(holder, Vector3(0.05, ln, 0.05), Vector3(0, -ln / 2.0, 0), "#d8cf8a" if i % 2 == 0 else "#c5b86a")
		part(holder, Vector3(0.055, 0.03, 0.055), Vector3(0, -ln + 0.02, 0), "#5a4630")
		pipes.append(holder)
	rack.rotation.y = COTTAGE_YAW
	put(rack, rack_at, 0.7)

func build_mat() -> void:
	mat_at = find_spot([cot(Vector2(-2.7, 0.3)), cot(Vector2(-2.7, -0.7)), cot(Vector2(2.6, -0.6))], 0.6, 1.5)
	if mat_at.x < 0.0:
		return
	mat_node = Node3D.new() # 1 x 0.7 tile: eight strips with a darker end band, a mended patch and Bori's needle
	for i in 8:
		part(mat_node, Vector3(0.7, 0.025, 0.12), Vector3(0, 0.0125, -0.4375 + i * 0.125), "#c9b36a" if i % 2 == 0 else "#b89f55")
	for s in [-1.0, 1.0]:
		part(mat_node, Vector3(0.05, 0.035, 1.0), Vector3(0.34 * s, 0.0175, 0), "#7a6038")
	part(mat_node, Vector3(0.24, 0.032, 0.2), Vector3(0.1, 0.016, 0.22), "#e0cf86")
	var needle := part(mat_node, Vector3(0.018, 0.018, 0.26), Vector3(-0.05, 0.05, 0.3), "#cfd3d8")
	needle.rotation = Vector3(0.0, 0.6, 0.12)
	part(mat_node, Vector3(0.05, 0.02, 0.02), Vector3(-0.12, 0.045, 0.2), "#c8562e") # a bit of red thread
	mat_node.rotation.y = COTTAGE_YAW
	put(mat_node, mat_at, 0.8)

# ---------------------------------------------------------------- E
# no toy answers during a story, the shop, a fall, a fade or a fight (a living foe within 6 tiles)
func usable() -> bool:
	if not m.in_marsh() or m.intro or m.story_open or m.shop_open or m.settings_open or m.down_t > 0.0 or m.fade_rect.color.a > 0.0:
		return false
	for e in m.enemies:
		if not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 6.0:
			return false
	return true

func near(at: Vector2) -> bool:
	return at.x >= 0.0 and Vector2(m.player.x, m.player.z).distance_to(at) < USE_R

# a toy under the hand? true takes the key; a wound duck or a pipe that is still sounding answers nothing but is not skipped over
func key() -> bool:
	if not usable():
		return false
	if m.story_step >= 3 and mat_node != null and near(mat_at):
		m.show_story("", Main.STORY.MARSH_MAT)
		return true
	if m.story_step < 2:
		return false
	if duck != null and near(duck_handle):
		if duck_state == "rest":
			wind_duck()
		return true
	if rack != null and near(rack_at):
		if m.t >= pipe_ready_t:
			play_pipe()
		return true
	return false

func hint() -> String:
	if not usable():
		return ""
	if m.story_step >= 3 and mat_node != null and near(mat_at):
		return m.tr("E  갈대 깔개 살펴보기")
	if m.story_step < 2:
		return ""
	if duck != null and near(duck_handle) and duck_state == "rest":
		return m.tr("E  태엽 감기")
	if rack != null and near(rack_at) and m.t >= pipe_ready_t:
		return m.tr("E  갈대피리 불기")
	return ""

func wind_duck() -> void:
	duck_state = "run"
	duck_t = 0.0
	duck_runs += 1
	for k in 3: # the crank clicks as it turns
		m.get_tree().create_timer(0.12 * k).timeout.connect(func(): m.sfx(1100.0 + k * 90.0, 0.025, "square", 0.07))

func play_pipe() -> void:
	pipe_ready_t = m.t + PIPE_COOL
	pipe_t = 0.0
	pipe_next = 0
	pipe_plays += 1
	pipe_times.clear()

# ---------------------------------------------------------------- every frame (in the marsh)
func update(dt: float) -> void:
	update_duck(dt)
	update_frogs(dt)
	update_cattails(dt)
	update_pipe(dt)

func update_duck(dt: float) -> void:
	if duck == null:
		return
	if duck_state == "run":
		duck_t += dt
		var k := clampf(duck_t / DUCK_LOOP, 0.0, 1.0)
		var e := 0.5 * k + 0.5 * k * k * (3.0 - 2.0 * k)
		place_duck(duck_a0 + TAU * e, k)
		crank.rotation.y = -TAU * clampf(duck_t / 0.5, 0.0, 1.0) if duck_t < 0.5 else 0.0
		if int(duck_t / 0.5) != int((duck_t - dt) / 0.5):
			m.sfx(1250.0, 0.012, "square", 0.045) # the spring ticks
		if duck_t >= DUCK_LOOP:
			duck_state = "cool"
			duck_cool_t = DUCK_COOL
			duck_t = 0.0
			place_duck(duck_a0, 1.0)
	else:
		place_duck(duck_a0, 0.0)
		if duck_state == "cool":
			duck_cool_t -= dt
			if duck_cool_t <= 0.0:
				duck_state = "rest"

func frog_pose(f: Dictionary, from: Vector2, to: Vector2, k: float, to_water: bool) -> void:
	var p := from.lerp(to, k)
	var ground := m.height_at(f.perch.x, f.perch.y)
	var y := lerpf(ground if to_water else WATER_Y, WATER_Y if to_water else ground, k) + sin(PI * k) * 0.3
	f.node.position = Vector3(p.x, y, p.y)

func update_frogs(dt: float) -> void:
	if frogs.is_empty():
		return
	var me := Vector2(m.player.x, m.player.z)
	frog_still = frog_still + dt if me.distance_to(frog_me) < 0.25 * dt else 0.0
	frog_me = me
	if me.distance_to(POND) > 16.0: # out of sight: they are all back on the bank when she returns
		for f in frogs:
			f.state = "sit"
			f.node.visible = true
			frog_pose(f, f.perch, f.perch, 0.0, true)
			f.node.rotation.y = f.yaw
		return
	var started := 0
	for f in frogs:
		match f.state:
			"sit":
				if me.distance_to(f.perch) < FROG_FLEE:
					f.state = "out"
					f.t = -0.12 * started # one after another
					started += 1
					frog_flees += 1
			"out":
				f.t += dt
				if f.t >= 0.0:
					frog_pose(f, f.perch, f.land, minf(f.t / FROG_HOP, 1.0), true)
					if f.t >= FROG_HOP:
						f.state = "gone"
						f.node.visible = false
						m.burst(Vector3(f.land.x, WATER_Y + 0.05, f.land.y), Color("#bfe6ff"), 6, 1.2)
						m.sfx(520.0, 0.07, "sine", 0.12, -240.0) # a small plop
			"back":
				f.t += dt
				frog_pose(f, f.land, f.perch, minf(f.t / FROG_HOP, 1.0), false)
				if f.t >= FROG_HOP:
					f.state = "sit"
					f.node.rotation.y = f.yaw
	if frog_still >= FROG_STILL: # she has stood still: the nearest frog that fled peeks back onto its bank
		var best = null
		for f in frogs:
			if f.state == "gone" and me.distance_to(f.perch) >= FROG_FLEE + 0.4 and (best == null or me.distance_to(f.perch) < me.distance_to(best.perch)):
				best = f
		if best != null:
			best.state = "back"
			best.t = 0.0
			best.node.visible = true
			best.node.rotation.y = best.yaw + PI
			frog_returns += 1
			frog_still = 0.0

func update_cattails(dt: float) -> void:
	var me := Vector2(m.player.x, m.player.z)
	for c in cattails:
		if c.ready:
			if me.distance_to(c.pos) < FLUFF_NEAR:
				release_fluff(c)
		else:
			c.reset_t -= dt
			if c.reset_t <= 0.0:
				c.ready = true
				c.fuzz.visible = true
		c.sway = maxf(0.0, c.sway - dt * 1.4)
		c.top.rotation.z = sin(m.t * 28.0) * 0.22 * c.sway
	for q in fluff:
		if q.t < 0.0:
			continue
		q.t += dt
		var k: float = q.t / FLUFF_DRIFT
		if k >= 1.0:
			q.t = -1.0
			q.node.visible = false
			continue
		var rise := 1.0 - pow(1.0 - k, 2.0)
		q.node.position = q.p0 + q.v * k * FLUFF_DRIFT + Vector3(0, 0.5 * rise, 0) + Vector3(sin(k * 9.0 + q.phase) * 0.08, 0, cos(k * 7.0 + q.phase) * 0.06)
		q.node.transparency = clampf((k - 0.3) / 0.7, 0.0, 1.0)
		q.node.scale = Vector3.ONE * (1.0 + 0.8 * k)

func release_fluff(c: Dictionary) -> void:
	c.ready = false
	c.reset_t = FLUFF_RESET
	c.sway = 1.0
	c.fuzz.visible = false
	fluff_puffs += 1
	var i: int = cattails.find(c)
	var top: Vector3 = c.node.position + Vector3(0, 1.3, 0)
	for j in 4:
		var q: Dictionary = fluff[i * 4 + j]
		q.t = 0.0
		q.p0 = top + FLUFF_PUFFS[j]
		q.v = Vector3(0.28 + 0.1 * j, 0.0, 0.1 - 0.07 * j) # a light breeze from the west, each a little different
		q.node.position = q.p0
		q.node.visible = true
	m.sfx(900.0, 0.18, "step", 0.05)

func update_pipe(dt: float) -> void:
	for i in pipes.size(): # the pipes swing for a moment after a note
		var swing := clampf(1.0 - maxf(pipe_t, 0.0) / 0.9, 0.0, 1.0) if pipe_t >= 0.0 else 0.0
		pipes[i].rotation.z = sin(m.t * 22.0 + i) * 0.08 * swing
	if pipe_t < 0.0:
		return
	pipe_t += dt
	var all: Array = PIPE_NOTES + PIPE_ANSWER
	while pipe_next < all.size() and pipe_t >= all[pipe_next][0]:
		var hz: float = all[pipe_next][1]
		pipe_times.append(m.t)
		if pipe_next < PIPE_NOTES.size():
			m.sfx(hz, 0.3, "sine", 0.14)
			m.sfx(hz * 4.0, 0.22, "step", 0.05) # the breath over the tone
			m.burst(Vector3(rack_at.x, m.height_at(rack_at.x, rack_at.y) + 0.6, rack_at.y), Color("#e8f0b0"), 4, 0.8)
		else:
			m.sfx(hz, 0.34, "sine", 0.05) # the answer from far off in the reeds
			m.sfx(hz * 3.0, 0.3, "step", 0.012)
		pipe_next += 1
	if pipe_next >= all.size() and pipe_t > 1.5:
		pipe_t = -1.0
