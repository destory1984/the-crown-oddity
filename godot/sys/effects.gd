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
