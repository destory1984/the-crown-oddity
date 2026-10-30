# Particles and effects: motes, bursts, rings, sword-swing drafts, slash fx, damage numbers.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main
var armour_ring: MeshInstance3D = null # the silver ring at Sora's feet once she has bought armour

# what Bori's shop gear looks like (the owner, 2026-10-26: bought blades and armour never showed): tier 0 none,
# 1 for one or two bought, 2 for three or four, 3 for five or more
const BLADE_TINT := [Color(1, 1, 1), Color("#bfe6ff"), Color("#7cc8ff"), Color("#ffd86a")]
const BLADE_SPARK := [Color("#ffb21a"), Color("#9fd8ff"), Color("#4aa8ff"), Color("#ffcf3a")]
const ARMOUR_TINT := [Color(1, 1, 1), Color("#cfdcec"), Color("#e6f0ff"), Color("#ffe6a8")]

func gear_tier(i: int) -> int:
	var n: int = m.shop_bought[i]
	return 0 if n <= 0 else (1 if n <= 2 else (2 if n <= 4 else 3))

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- particles
func build_particles() -> void:
	m.motes = CPUParticles3D.new()
	m.motes.amount = 60
	m.motes.lifetime = 6.0
	m.motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	m.motes.emission_box_extents = Vector3(14, 1, 14)
	m.motes.gravity = Vector3(0, 0.05, 0)
	m.motes.initial_velocity_min = 0.1
	m.motes.initial_velocity_max = 0.3
	m.motes.direction = Vector3(0, 1, 0)
	m.motes.spread = 180.0
	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	q.material = m.glow_mat(Color("#fff0a8"), 6.0)
	q.material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.motes.mesh = q
	m.add_child(m.motes)

	m.rain = CPUParticles3D.new()
	m.rain.amount = 1200
	m.rain.lifetime = 0.6
	m.rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	m.rain.emission_box_extents = Vector3(14, 0.5, 14)
	m.rain.gravity = Vector3(0, -30, 0)
	m.rain.direction = Vector3(0, -1, 0)
	m.rain.initial_velocity_min = 8.0
	m.rain.initial_velocity_max = 10.0
	var rq := BoxMesh.new()
	rq.size = Vector3(0.02, 0.45, 0.02)
	rq.material = m.mat_color(Color(0.72, 0.8, 0.88, 0.5))
	rq.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.rain.mesh = rq
	m.rain.emitting = false
	m.add_child(m.rain)

func burst(pos: Vector3, color: Color, n := 14, spd := 3.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.6
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.initial_velocity_min = spd * 0.5
	p.initial_velocity_max = spd * 1.5
	p.gravity = Vector3(0, -9, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	q.material = m.glow_mat(color, 2.5)
	q.material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p.mesh = q
	p.position = pos
	m.add_child(p)
	p.emitting = true
	m.get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func add_fx(node: Node3D, life: float, update: Callable) -> void:
	m.add_child(node)
	m.fx.append({"node": node, "life": life, "t": 0.0, "update": update})

func ring_mesh(r0: float, r1: float, a0: float, arc: float, seg := 24) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in seg:
		var a := a0 + arc * i / seg
		var b := a0 + arc * (i + 1) / seg
		var p := [Vector3(cos(a) * r0, 0, sin(a) * r0), Vector3(cos(a) * r1, 0, sin(a) * r1), Vector3(cos(b) * r1, 0, sin(b) * r1), Vector3(cos(b) * r0, 0, sin(b) * r0)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(p[k])
	return st.commit()

# a strip along an arc whose inner and outer radius and colour change along it (u 0 at the tail, 1 at the edge)
func arc_strip(arc: float, seg: int, shape: Callable) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in seg:
		var rows := []
		for j in 2:
			var u := float(i + j) / seg
			var a := arc * u
			var r: Array = shape.call(u) # [inner, outer, inner colour, outer colour]
			rows.append([Vector3(cos(a) * r[0], 0, sin(a) * r[0]), Vector3(cos(a) * r[1], 0, sin(a) * r[1]), r[2], r[3]])
		var q := [[rows[0][0], rows[0][2]], [rows[0][1], rows[0][3]], [rows[1][1], rows[1][3]], [rows[1][0], rows[1][2]]]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(q[k][1])
			st.add_vertex(q[k][0])
	return st.commit()

func strip_mat(glow: float) -> StandardMaterial3D:
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.vertex_color_use_as_albedo = true
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mm.albedo_color = Color(glow, glow, glow) # above 1 it blooms
	return mm

func swing_draft(k: int, prog: float, span: float) -> Node3D:
	var g := Node3D.new()
	var arc := span * prog
	var add_strip := func(shape: Callable, glow: float, y := 0.0):
		var mi := MeshInstance3D.new()
		mi.mesh = arc_strip(arc, 28, shape)
		mi.material_override = strip_mat(glow)
		mi.position.y = y
		g.add_child(mi)
	match k:
		0: # a crescent: thick in the middle, sharp at both tips, white at the cutting edge fading to blue inside
			add_strip.call(func(u: float) -> Array:
				var w := pow(sin(PI * u), 0.8) * 0.55
				return [1.4 - w, 1.4, Color(0.55, 0.85, 1.0, 0.0), Color(1, 1, 1, 0.95)], 2.2)
		1: # three thin after-image lines, the outer one longest
			for i in 3:
				var r := 0.85 + i * 0.25
				var cut := 0.35 - i * 0.12
				add_strip.call(func(u: float) -> Array:
					var a := 0.0 if u < cut else (1.0 - i * 0.25) * minf(1.0, (u - cut) * 4.0)
					return [r - 0.035, r + 0.035, Color(0.75, 0.92, 1.0, a), Color(1, 1, 1, a)], 2.0, 0.01 * i)
		2: # a thin gold line with diamond sparks flying off its outer side
			add_strip.call(func(u: float) -> Array:
				return [1.15, 1.25, Color(1.0, 0.66, 0.1, u), Color(1.0, 0.8, 0.3, u)], 1.1)
			for i in 9:
				var u := (i + 0.5) / 9.0
				var a := arc * u
				var r := 1.3 + 0.35 * fmod(i * 0.618, 1.0)
				var d := m.box(Vector3.ONE * (0.07 + 0.07 * u), m.glow_mat(Color("#ffb21a") if i % 2 == 0 else Color("#ffe9a8"), 1.0))
				d.position = Vector3(cos(a) * r, 0.05, sin(a) * r)
				d.rotation = Vector3(PI / 4.0, a, PI / 4.0)
				g.add_child(d)
		3: # a cel-anime smear: a hard navy outline under a flat white blade of colour, no glow
			add_strip.call(func(u: float) -> Array:
				var w := pow(u, 0.6) * 0.95
				return [1.48 - w, 1.48, Color("#1d2a6e"), Color("#1d2a6e")], 1.0)
			add_strip.call(func(u: float) -> Array:
				var w := pow(u, 0.6) * 0.75
				return [1.38 - w, 1.38, Color.WHITE, Color.WHITE], 1.0, 0.02)
		4: # little studded toy bricks popping out along the swing, red, yellow, blue, green
			add_strip.call(func(u: float) -> Array:
				return [1.0, 1.06, Color(1, 1, 1, u * 0.6), Color(1, 1, 1, u * 0.6)], 1.6)
			var cols := [Color("#d8322a"), Color("#f2c230"), Color("#2f6fd8"), Color("#3aa84a")]
			for i in 7:
				var u := (i + 0.5) / 7.0
				var a := arc * u
				var bk := Node3D.new()
				var mats: Array = []
				m.brick(bk, mats, Vector3(0.26, 0.14, 0.16), Vector3.ZERO, cols[i % 4])
				bk.position = Vector3(cos(a) * 1.2, 0.05 + u * 0.15, sin(a) * 1.2)
				bk.rotation = Vector3(0.3 * i, -a, 0.2 * i)
				bk.scale = Vector3.ONE * (0.6 + 0.6 * u)
				g.add_child(bk)
	return g

func swing_line(arc: float, r: float) -> ArrayMesh:
	var key := "%.2f/%.2f" % [arc, r]
	if not m.swing_line_cache.has(key):
		m.swing_line_cache[key] = arc_strip(arc, 28, func(u: float) -> Array:
			var a := pow(u, 1.4) if arc < TAU - 0.01 else 1.0
			return [r - 0.06, r + 0.06, Color(1.0, 0.66, 0.1, a), Color(1.0, 0.82, 0.32, a)])
	return m.swing_line_cache[key]

# gear: one of Sora's own swings, drawn in the colour of the blades she has bought (tier 1 to 3 also a little wider
# and with more sparks; only the picture grows, not the reach)
func slash_fx(pos: Vector3, ang: float, big: bool, span := 1.8, gear := false) -> void:
	if m.spark_mats.is_empty():
		m.spark_mats = [m.glow_mat(Color("#ffb21a"), 1.6), m.glow_mat(Color("#ffe9a8"), 1.6)]
	var tier := gear_tier(2) if gear else 0
	var sparks: Array = m.spark_mats if tier == 0 else [m.glow_mat(BLADE_SPARK[tier], 1.8), m.glow_mat(BLADE_TINT[tier], 1.8)]
	var tint: Color = BLADE_TINT[tier] * 1.6
	ang += (1.8 - span) / 2.0 # keep the arc centred where the 1.8-rad arc was
	var arc := TAU if big else span
	var r := (1.66 if big else 1.2) * (1.0 + 0.06 * tier)
	var mm := MeshInstance3D.new()
	mm.mesh = swing_line(arc, r)
	var mat := strip_mat(1.6)
	mm.material_override = mat
	mm.position = pos + Vector3(0, 0.5, 0)
	var sweep := 0.0 if big else span * 0.6 # the head travels the last of the arc while the line shows
	mm.rotation.y = ang - sweep
	add_fx(mm, 0.3, func(n: Node3D, k: float, _dt: float):
		n.rotation.y = ang - sweep * maxf(0.0, 1.0 - k * 3.0)
		mat.albedo_color = Color(tint.r, tint.g, tint.b, clampf(k * 8.0, 0.0, 1.0) * (1.0 - maxf(0.0, k - 0.35) / 0.65))
		if big:
			n.scale = Vector3.ONE * (1.0 + k * 0.3))
	var count := (14 if big else 7) + 3 * tier
	for i in count:
		var u := (i + 0.5) / count
		var a := arc * u - ang # a point at angle a on the strip sits at world angle a - rotation.y
		var dir := Vector3(cos(a), 0, sin(a))
		var d := m.box(Vector3.ONE * (0.07 + 0.06 * u), sparks[i % 2])
		d.position = mm.position + dir * (r + 0.1)
		d.rotation = Vector3(PI / 4.0, m.rnd(0, TAU), PI / 4.0)
		var speed := m.rnd(1.6, 2.8)
		var delay := 0.0 if big else u * 0.08 # sparks leave along the sweep, tail first
		d.visible = delay <= 0.0
		add_fx(d, 0.32 + delay, func(n: Node3D, k: float, dt: float):
			var life := (0.32 + delay) * k
			n.visible = life >= delay
			if life < delay:
				return
			n.position += dir * speed * dt
			n.position.y += dt * 0.6
			n.rotation.y += dt * 9.0
			n.scale = Vector3.ONE * maxf(0.05, 1.0 - (life - delay) / 0.32))

# a stud knocked off a brick by a blocked blow: it drops in front of Sora, spins like a top and lies still (delight idea 51)
const STUD_COLORS := [Color("#d8322a"), Color("#f2c230"), Color("#2f6fd8")]
var studs_made := 0
var last_stud: Node3D

func stud_spin(at: Vector3) -> Node3D:
	var g := Node3D.new()
	last_stud = g
	m.brick(g, [], Vector3(0.2, 0.12, 0.2), Vector3.ZERO, STUD_COLORS[studs_made % 3])
	studs_made += 1
	var y0 := at.y
	g.position = at + Vector3(0, 0.9, 0)
	add_fx(g, 1.6, func(n: Node3D, k: float, dt: float):
		var t := k * 1.6
		n.position.y = y0 + 0.06 + 0.84 * maxf(0.0, 1.0 - pow(t / 0.3, 2.0)) # a quick drop, then it lies on the ground
		var rest := clampf((t - 0.3) / 0.7, 0.0, 1.0) # the spin dies away over 0.7 s
		n.rotation.y += dt * 22.0 * (1.0 - rest) * (1.0 if t >= 0.3 else 0.4)
		n.rotation.z = 0.35 * (1.0 - rest) * (1.0 if t >= 0.3 else 0.0)
		n.scale = Vector3.ONE * clampf((1.6 - t) / 0.3, 0.0, 1.0))
	return g

# a charge stopped by a wall: three grains of dust shake loose from the wall side and sift down, pushed back the way
# the force came from (delight idea 52)
var wall_dusts := 0

func wall_dust(at: Vector3, dir: Vector2) -> void:
	wall_dusts += 1
	for i in 3:
		var d := m.box(Vector3.ONE * 0.09, m.mat_color(Color("#b8a888")))
		var side := (i - 1) * 0.22
		var from := at + Vector3(dir.x * 0.35 - dir.y * side, 1.1 + 0.15 * i, dir.y * 0.35 + dir.x * side)
		d.position = from
		var drift := Vector3(-dir.x, 0, -dir.y) * 0.6
		add_fx(d, 0.7, func(n: Node3D, k: float, _dt: float):
			n.position = from + drift * k + Vector3(0, -(from.y - at.y - 0.05) * k * k, 0)
			n.rotation.y = k * 3.0
			n.scale = Vector3.ONE * (1.0 - maxf(0.0, k - 0.6) / 0.4))

# the release of a charged cut: the dust at her feet is shoved outward before the light follows (delight idea 54)
var release_dusts := 0

func release_dust(at: Vector3) -> void:
	release_dusts += 1
	for i in 8:
		var a := TAU * i / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var d := m.box(Vector3.ONE * 0.1, m.mat_color(Color("#d8c8a0")))
		d.position = at + dir * 0.3 + Vector3(0, 0.08, 0)
		var from := d.position
		add_fx(d, 0.5, func(n: Node3D, k: float, _dt: float):
			n.position = from + dir * (1.4 * sqrt(k)) + Vector3(0, 0.25 * sin(k * PI), 0)
			n.scale = Vector3.ONE * (1.0 - k))

# the last foe near her has fallen: the floating motes settle, a little gravity for 3 s (never touches a warning mark)
var calm_tw: Tween
var calms := 0

func settle_motes() -> void:
	calms += 1
	if calm_tw != null and calm_tw.is_valid():
		calm_tw.kill()
	var rest := Vector3(0, 0.05, 0)
	calm_tw = m.create_tween()
	calm_tw.tween_property(m.motes, "gravity", Vector3(0, -0.5, 0), 0.4)
	calm_tw.tween_interval(1.4)
	calm_tw.tween_property(m.motes, "gravity", rest, 1.2)

func pillar(pos: Vector3) -> void:
	var mm := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.35
	c.bottom_radius = 0.35
	c.height = 8.0
	mm.mesh = c
	var mat := m.glow_mat(Color("#fff1c0"), 2.0)
	mm.material_override = mat
	mm.position = pos + Vector3(0, 4, 0)
	add_fx(mm, 1.6, func(n: Node3D, k: float, _dt: float):
		mat.albedo_color.a = sin(k * PI) * 0.9
		n.scale = Vector3(1.0 + k, 1.0, 1.0 + k))

func pop_num(pos: Vector3, text: String, color := Color.WHITE) -> void:
	if not bool(m.cfg.nums) and text != "!" and text != "막음": # numbers can be switched off in the settings; warnings stay
		return
	var l := Label3D.new()
	l.text = text
	l.font = m.ui_font
	l.font_size = 64
	l.outline_size = 12
	l.pixel_size = 0.006
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos + Vector3(m.rnd(-0.2, 0.2), 0, 0)
	add_fx(l, 1.0, func(n: Node3D, k: float, dt: float):
		n.position.y += dt * 1.2
		(n as Label3D).modulate.a = 1.0 - maxf(0.0, k - 0.5) * 2.0)

# after the rain stops a few drops still fall from the eaves near her, one by one, each gap longer, until they stop (delight
# idea 31): the roof edges of the village houses and Bori's cottage, six at most, three drops each
var eave_drips := 0 # drops started (autoplay eave_drips)

func eave_points() -> Array:
	var out: Array = []
	for d in m.village.doors: # the roof edge sits a little in front of the wall, either side of the door
		out.append(Vector3(d.x - 0.9, 1.75, d.y - 0.7))
		out.append(Vector3(d.x + 1.0, 1.75, d.y - 0.7))
	out.append(Vector3(m.shop_pos.x - 1.2, 1.9, m.shop_pos.z - 0.1))
	out.append(Vector3(m.shop_pos.x + 1.2, 1.9, m.shop_pos.z - 0.1))
	return out

func eaves_drip() -> void:
	var me := Vector3(m.player.x, 0, m.player.z)
	var near: Array = eave_points().filter(func(p): return Vector2(p.x - me.x, p.z - me.z).length() < 16.0)
	near.sort_custom(func(a, b): return Vector2(a.x - me.x, a.z - me.z).length() < Vector2(b.x - me.x, b.z - me.z).length())
	for p in near.slice(0, 6):
		var t: float = m.rnd(0.3, 1.0)
		for k in 3:
			var at: float = t
			m.get_tree().create_timer(at).timeout.connect(func(): eave_drop(p))
			t += m.rnd(0.9, 1.5) * (1.0 + k * 0.9)

func eave_drop(p: Vector3) -> void:
	eave_drips += 1
	var drop: MeshInstance3D = m.box(Vector3(0.04, 0.1, 0.04), m.glow_mat(Color("#bfe6ff"), 1.4))
	drop.position = p
	m.add_child(drop)
	var tw := drop.create_tween()
	tw.tween_property(drop, "position:y", 0.05, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		burst(Vector3(p.x, 0.1, p.z), Color("#bfe6ff"), 3, 0.8)
		drop.queue_free())

# in the rain, under the eaves she is near, a drop now and then lands with its own small sound: the left eave of Bori's cottage
# and of the first village house drips on bare ground, the right one into a tin pail (delight idea 34). Only the nearest of
# the four sounds, and no faster than every DRIP_GAP_MIN to DRIP_GAP_MAX seconds. Nothing indoors, in a story or with a monster near.
const DRIP_NEAR := 8.0
const DRIP_GAP_MIN := 1.2
const DRIP_GAP_MAX := 2.0
var drip_anchors: Array = [] # [{"at": Vector3, "tin": bool}]
var drip_t := 0.0
var rain_drips := 0 # drops started in the rain (autoplay d34_drip_timbre)

func build_drip_anchors() -> void:
	var sites: Array = [[Vector3(m.shop_pos.x - 1.2, 1.9, m.shop_pos.z - 0.1), Vector3(m.shop_pos.x + 1.2, 1.9, m.shop_pos.z - 0.1)]]
	if m.village != null and not m.village.doors.is_empty():
		var d: Vector2 = m.village.doors[0]
		sites.append([Vector3(d.x - 0.9, 1.75, d.y - 0.7), Vector3(d.x + 1.0, 1.75, d.y - 0.7)])
	for site in sites:
		drip_anchors.append({"at": site[0], "tin": false})
		drip_anchors.append({"at": site[1], "tin": true})
		var pail: MeshInstance3D = m.box(Vector3(0.24, 0.22, 0.24), m.mat_color(Color("#8d949c")))
		pail.position = Vector3(site[1].x, 0.11, site[1].z)
		m.add_child(pail)
		var inside: MeshInstance3D = m.box(Vector3(0.17, 0.02, 0.17), m.mat_color(Color("#2c3036")))
		inside.position = Vector3(site[1].x, 0.225, site[1].z)
		m.add_child(inside)

func update_rain_drips(dt: float) -> void:
	drip_t -= dt
	if drip_t > 0.0 or not m.raining or m.in_house >= 0 or m.story_open or m.intro or drip_anchors.is_empty():
		return
	var me := Vector2(m.player.x, m.player.z)
	var best = null
	for a in drip_anchors:
		var d: float = Vector2(a.at.x, a.at.z).distance_to(me)
		if d < DRIP_NEAR and (best == null or d < Vector2(best.at.x, best.at.z).distance_to(me)):
			best = a
	if best == null or m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x, e.z).distance_to(me) < 7.0):
		return
	drip_t = m.rnd(DRIP_GAP_MIN, DRIP_GAP_MAX)
	rain_drips += 1
	var tin: bool = best.tin
	var drop: MeshInstance3D = m.box(Vector3(0.04, 0.1, 0.04), m.glow_mat(Color("#bfe6ff"), 1.4))
	drop.position = best.at
	m.add_child(drop)
	var tw := drop.create_tween()
	tw.tween_property(drop, "position:y", 0.24 if tin else 0.05, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		m.sound.rain_drip(tin)
		drop.queue_free())

func fade_then(fn: Callable) -> void:
	var tw := m.create_tween()
	tw.tween_property(m.fade_rect, "color:a", 1.0, 0.4)
	tw.tween_callback(fn)
	tw.tween_property(m.fade_rect, "color:a", 0.0, 0.4)

# the armour ring: a thin glowing ring round Sora's shadow that brightens with each tier, breathing slowly
func update_armour_ring(pos: Vector3, shown: bool) -> void:
	var tier := gear_tier(3)
	if tier == 0:
		if armour_ring != null:
			armour_ring.visible = false
		return
	if armour_ring == null:
		armour_ring = MeshInstance3D.new()
		armour_ring.mesh = m.ring_mesh(0.46, 0.54, 0.0, TAU, 32)
		armour_ring.material_override = m.glow_mat(Color.WHITE, 1.2)
		armour_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(armour_ring)
	armour_ring.visible = shown
	armour_ring.position = pos + Vector3(0, 0.03, 0)
	var c: Color = ARMOUR_TINT[tier]
	c.a = [0.0, 0.3, 0.45, 0.6][tier] * (0.8 + 0.2 * sin(m.t * 2.0))
	(armour_ring.material_override as StandardMaterial3D).albedo_color = c

# a blow on armour: a few silver (tier 3: gold) flakes off her shoulders
func armour_shimmer(pos: Vector3) -> void:
	var tier := gear_tier(3)
	if tier > 0:
		m.burst(pos + Vector3(0, 0.9, 0), ARMOUR_TINT[tier], 4 + 4 * tier, 2.0)

# a screw jumps from the seam of a brick foe whose blow she flash-guarded and is drawn back into its body (delight idea 58).
# One at a time; no loot, no weakness, no damage.
var screws := 0
var screw_t := -10.0
var last_screw: Node3D

func screw_pull(e: Dictionary) -> void:
	if m.t - screw_t < 1.0:
		return
	screw_t = m.t
	screws += 1
	var g := Node3D.new()
	last_screw = g
	var steel := m.mat_color(Color("#a8aeb8"))
	var shaft: MeshInstance3D = m.box(Vector3(0.04, 0.16, 0.04), steel)
	shaft.position.y = -0.05
	g.add_child(shaft)
	var head: MeshInstance3D = m.box(Vector3(0.11, 0.03, 0.11), steel)
	head.position.y = 0.05
	g.add_child(head)
	var body := Vector3(e.x, m.height_at(e.x, e.z) + 0.7, e.z)
	var away := Vector3(m.player.x - e.x, 0, m.player.z - e.z)
	away = away.normalized() if away.length() > 0.01 else Vector3(0, 0, 1)
	var out := body + away * 0.55 + Vector3(0, 0.1, 0)
	g.position = body
	add_fx(g, 0.9, func(n: Node3D, k: float, _dt: float):
		var now := Vector3(e.x, m.height_at(e.x, e.z) + 0.7, e.z) # it follows the body if the foe is shoved
		if k < 0.5:
			var u := k / 0.5
			n.position = now + (out - body) * u + Vector3(0, 0.5 * sin(u * PI), 0)
			n.rotation.y = u * 9.0
		else:
			var u := (k - 0.5) / 0.5
			n.position = (out - body + now).lerp(now, u * u)
			n.rotation.y = 9.0 + u * 9.0
			n.scale = Vector3.ONE * (1.0 - 0.6 * u))

# the last drop of the pond water falls at her feet when she has finished drinking (delight idea 67)
var pond_drops := 0
var last_drop: Node3D

func pond_drop(at: Vector3) -> void:
	pond_drops += 1
	var mat := m.glow_mat(Color("#bfe6ff"), 1.4)
	var d: MeshInstance3D = m.box(Vector3(0.05, 0.12, 0.05), mat)
	d.position = at + Vector3(0.18, 0.7, 0.1)
	last_drop = d
	var from := d.position
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh(0.05, 0.09, 0.0, TAU, 16)
	var rmat := m.glow_mat(Color("#bfe6ff"), 1.2)
	ring.material_override = rmat
	ring.position = at + Vector3(0.18, 0.03, 0.1)
	ring.visible = false
	m.add_child(ring)
	add_fx(d, 0.55, func(n: Node3D, k: float, _dt: float):
		var t := k * 0.55
		if t < 0.25:
			n.position.y = from.y - (from.y - at.y - 0.05) * pow(t / 0.25, 2.0)
		else:
			n.visible = false
			ring.visible = true
			var u := (t - 0.25) / 0.3
			ring.scale = Vector3.ONE * (1.0 + 3.0 * u)
			rmat.albedo_color.a = 1.0 - u
		if k >= 0.98:
			ring.queue_free())

# a thin pale ring floats over her crown while she looks up at the moon stairs (delight idea 68); it only shines, it lights nothing
var moon_rings := 0
var last_moon_ring: Node3D

func moon_ring() -> void:
	moon_rings += 1
	var mat := m.glow_mat(Color("#e8f0ff"), 1.6)
	var mm := MeshInstance3D.new()
	mm.mesh = ring_mesh(0.26, 0.32, 0.0, TAU, 20)
	mm.material_override = mat
	mm.rotation.x = 0.3
	last_moon_ring = mm
	mm.position = Vector3(m.player.x, m.ground_y + 2.1, m.player.z)
	add_fx(mm, 3.6, func(n: Node3D, k: float, _dt: float):
		n.position = Vector3(m.player.x, m.ground_y + 2.1 + 0.03 * sin(k * 9.0), m.player.z)
		mat.albedo_color.a = clampf(k * 6.0, 0.0, 1.0) * (1.0 - maxf(0.0, k - 0.8) / 0.2) * 0.85
		n.rotation.y = k * 2.0)

# the six steps after she climbs out of skipped water leave a dark wet print each on dry ground, every one fainter than the last, each
# drying away in 5 s (delight idea 2). Flat boxes only: none on water, a bridge, indoors, or in a story.
const PRINT_STEPS := 6
const PRINT_LIFE := 5.0
var print_left := 0
var prints_made := 0
var last_print: MeshInstance3D
var last_print_alpha := 0.0

func wet_landed() -> void:
	print_left = PRINT_STEPS

func wet_print() -> void:
	if print_left <= 0:
		return
	var at := Vector2(m.player.x, m.player.z)
	var tile: int = m.tile_at(at.x, at.y)
	if tile == Main.WATER or tile == Main.BRIDGE or m.in_house >= 0 or m.story_open:
		return
	var nth := PRINT_STEPS - print_left # 0 for the first
	print_left -= 1
	prints_made += 1
	var alpha := 0.62 * (1.0 - nth / float(PRINT_STEPS))
	var side := 1.0 if nth % 2 == 0 else -1.0 # left foot, right foot
	var face: Vector2 = m.player.face
	var pos := Vector3(at.x - face.y * 0.12 * side, m.height_at(at.x, at.y) + 0.02, at.y + face.x * 0.12 * side)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.1, 0.09, 0.08, alpha)
	var pr: MeshInstance3D = m.box(Vector3(0.14, 0.01, 0.24), mat)
	pr.position = pos
	pr.rotation.y = atan2(face.x, face.y)
	last_print = pr
	last_print_alpha = alpha
	add_fx(pr, PRINT_LIFE, func(_n: Node3D, k: float, _dt: float):
		mat.albedo_color.a = alpha * (1.0 - maxf(0.0, k - 0.4) / 0.6))

# a run past a street leaf pushes it on the way she runs, up to LEAF_PUSH tiles in 0.5 s, and it stops where the stone path ends
# (a street or square tile it would leave, or a wall); a walk does nothing (delight idea 6)
const LEAF_RUN := 5.0
const LEAF_PUSH := 1.4
const LEAF_TOUCH := 0.8
var leaf_pushes := 0

func leaf_ground_ok(p: Vector2) -> bool:
	return m.village.char_at(p.x, p.y) in "=o" and not m.village.blocked(p.x, p.y)

# where a leaf at `from` ends up when shoved along `dir`: 0.1 tile steps, as far as the stone goes
func leaf_slide_end(from: Vector2, dir: Vector2) -> Vector2:
	var p := from
	for i in int(LEAF_PUSH / 0.1):
		var n := p + dir * 0.1
		if not leaf_ground_ok(n):
			break
		p = n
	return p

func update_street_leaves() -> void:
	if not m.in_village or m.in_house >= 0 or m.story_open:
		return
	var v := Vector2(m.player.vx, m.player.vz)
	if v.length() < LEAF_RUN:
		return
	var me := Vector2(m.player.x, m.player.z)
	for lf in m.dressing.street_leaves:
		var at := Vector2(lf.node.position.x, lf.node.position.z)
		if lf.moving or at.distance_to(me) > LEAF_TOUCH:
			continue
		var to := leaf_slide_end(at, v.normalized())
		if to.distance_to(at) < 0.05:
			continue
		lf.moving = true
		leaf_pushes += 1
		var node: MeshInstance3D = lf.node
		var tw := node.create_tween()
		tw.tween_property(node, "position", Vector3(to.x, 0.012, to.y), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(node, "rotation:y", node.rotation.y + v.x * 0.4, 0.5)
		tw.tween_callback(func(): lf.moving = false)

# in the rain, little rings open on the marsh water near her, on open water only: a tile a bridge deck covers (world_build.deck_tiles)
# gets none, so the stream runs on dotted either side of a bridge and plain under it (delight idea 32)
const RAIN_RING_GAP := 0.07
const RAIN_RING_CAP := 24
const RAIN_RING_REACH := 9
var rain_ring_t := 0.0
var rain_rings := 0 # rings opened (autoplay d32_rain_rings)
var rain_ring_live := 0
var last_rain_ring := Vector2i(-1, -1) # the tile of the latest one

func update_rain_rings(dt: float) -> void:
	rain_ring_t -= dt
	if rain_ring_t > 0.0 or not m.raining or m.intro or m.in_house >= 0 or not m.in_marsh():
		return
	rain_ring_t = RAIN_RING_GAP
	if rain_ring_live >= RAIN_RING_CAP:
		return
	for tries in 4:
		var tx := int(round(m.player.x)) + m.rng.randi_range(-RAIN_RING_REACH, RAIN_RING_REACH)
		var tz := int(round(m.player.z)) + m.rng.randi_range(-RAIN_RING_REACH, RAIN_RING_REACH)
		if tx < 1 or tz < 1 or tx >= Main.N - 1 or tz >= Main.N - 1 or m.map[m.idx(tx, tz)] != Main.WATER:
			continue
		if m.world_build.deck_tiles.has(Vector2i(tx, tz)):
			continue
		rain_ring_at(Vector3(tx + m.rnd(-0.15, 0.15), -0.19, tz + m.rnd(-0.15, 0.15)), Vector2i(tx, tz))
		return

func rain_ring_at(pos: Vector3, tile: Vector2i) -> void:
	rain_rings += 1
	rain_ring_live += 1
	last_rain_ring = tile
	var mat := m.glow_mat(Color(0.8, 0.92, 1.0, 0.5), 1.0)
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh(0.8, 1.0, 0.0, TAU, 12)
	ring.material_override = mat
	ring.position = pos
	ring.scale = Vector3.ONE * 0.08
	m.add_child(ring)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * 0.28, 0.9)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.9)
	tw.chain().tween_callback(func():
		rain_ring_live -= 1
		ring.queue_free())

# under a roof (world_build.roof_rects) the rain above her stops: the drops are sown in a ring round her, bare out to the roof's
# nearest edge, so the rain past the roof still falls (delight idea 33). Out in the open the rain is the whole box again.
var rain_cut := 0.0 # radius of the dry circle, 0 for none

func update_rain_shelter() -> void:
	if m.rain == null:
		return
	var cut := 0.0
	if m.raining and m.in_house < 0 and not m.intro:
		var me := Vector2(m.player.x, m.player.z)
		var i: int = m.world_build.roof_at(me)
		if i >= 0:
			cut = clampf(m.world_build.roof_edge(i, me) - 0.1, 0.25, 3.0)
	if absf(cut - rain_cut) < 0.05 and (cut > 0.0) == (rain_cut > 0.0):
		return
	rain_cut = cut
	if cut > 0.0:
		m.rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		m.rain.emission_ring_axis = Vector3.UP
		m.rain.emission_ring_height = 1.0
		m.rain.emission_ring_radius = 14.0
		m.rain.emission_ring_inner_radius = cut
	else:
		m.rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		m.rain.emission_box_extents = Vector3(14, 0.5, 14)

# a shot stopped at a village door does not vanish into the wood: a short stick stands in it a moment, shivers four times, drops to the
# ground and goes. Four sticks are made once and used over; the shot's damage and the wall stay as they were (delight idea 53).
const STICK_POOL := 4
const STICK_DOOR := 1.6 # tiles from a door's spot
var sticks: Array = []
var stick_next := 0
var stick_made := 0 # sticks shown (autoplay d53_door_stick)
var last_stick: Node3D

func door_near(p: Vector2) -> bool:
	return m.in_village and m.in_house < 0 and m.village != null and m.village.doors.any(func(d): return d.distance_to(p) < STICK_DOOR)

func arrow_stick(pos: Vector3, v: Vector2) -> void:
	if not door_near(Vector2(pos.x, pos.z)) or v.length() < 0.01:
		return
	if sticks.is_empty():
		for k in STICK_POOL:
			var piece := Node3D.new()
			var shaft: MeshInstance3D = m.box(Vector3(0.04, 0.04, 0.5), m.mat_color(Color("#8a6a42")))
			piece.add_child(shaft)
			var tip: MeshInstance3D = m.box(Vector3(0.05, 0.05, 0.08), m.mat_color(Color("#c8c2b0")))
			tip.position.z = 0.27
			piece.add_child(tip)
			piece.visible = false
			m.add_child(piece)
			sticks.append(piece)
	var st: Node3D = sticks[stick_next]
	stick_next = (stick_next + 1) % STICK_POOL
	if st.has_meta("tw") and (st.get_meta("tw") as Tween).is_valid():
		(st.get_meta("tw") as Tween).kill()
	var dir := v.normalized()
	st.position = Vector3(pos.x - dir.x * 0.15, maxf(pos.y, 0.5), pos.z - dir.y * 0.15)
	st.rotation = Vector3(0.0, atan2(dir.x, dir.y), 0.0)
	st.visible = true
	last_stick = st
	stick_made += 1
	m.sfx(210, 0.06, "triangle", 0.1, -60.0)
	var tw := st.create_tween()
	st.set_meta("tw", tw)
	for k in 4: # four shivers, each smaller
		tw.tween_property(st, "rotation:z", 0.14 * (1.0 - k / 4.0) * (1.0 if k % 2 == 0 else -1.0), 0.05)
	tw.tween_property(st, "rotation:z", 0.0, 0.04)
	tw.tween_property(st, "position:y", 0.04, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(st, "rotation:x", 1.2, 0.3)
	tw.tween_interval(0.6)
	tw.tween_callback(func(): st.visible = false)
