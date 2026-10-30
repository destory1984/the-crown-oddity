# A football on the village square (the owner, 2026-10-30: "마을 광장에 축구공 하나 놔주고, 구석에 축구 골대 하나 놔줘..
# 골대에 넣으면 화면에 번쩍번쩍하면서 점수를 표시해줘"). Sora strikes it with her normal attack and it rolls like the toy
# bricks do (village.gd bricks_hit), but along her facing and bouncing off the lamp, the goal posts and the pitch's edge;
# walking into it nudges it. It lies on the south lawn (moved there from the square, 05:31: "골대와 축구공은 마을 남쪽으로
# 옮기자"); the goal stands at the lawn's south end, its mouth to the north. A ball whose centre
# crosses the goal line between the posts flashes the screen, shows "골! N" and cheers; the count (goals) is kept in the save.
# Two goals facing each other and a marked pitch since v0.1.129 (the owner, 21:00: "맞은 편에 하나 더 만들어서, 축구장처럼 꾸며줘"):
# either goal counts, the ball lies on the centre spot.
# Moved by update(dt), so a story, the bag and the settings stop it too. Boxes, a sphere, generated textures and code-made sounds.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

# village tiles; the world position adds village.VILLAGE_X
const PITCH := Rect2(16.6, 20.6, 8.8, 8.0) # the south lawn (17 to 25, rows 21 to 28) between the inn street and the pond: the ball never leaves it
const SPOT := Vector2(21.0, 24.6)           # where the ball lies: the centre spot
const GOAL_X := 21.0                        # the middle of the mouth
const GOAL_LINE := 27.4                     # the south goal line (z); the mouth faces north, the net runs back to GOAL_LINE + GOAL_DEPTH
const GOAL_LINE_N := 21.8                   # the north goal line, its net runs back to GOAL_LINE_N - GOAL_DEPTH
const TOUCH_X := Vector2(17.0, 25.0)        # the painted side lines
const CIRCLE_R := 1.1
const BOX := Vector2(4.2, 1.3)              # the box before each goal: wide, deep
const LINE_W := 0.07
const FLAG_H := 0.85
const GOAL_W := 2.2
const GOAL_DEPTH := 0.8
const GOAL_H := 1.1
const POST_R := 0.07
const NET_DROP := 0.3        # the net's top slopes down this far from the crossbar to the back

const RADIUS := 0.22
const KICK := 7.0          # a swing, tiles a second
const KICK_FAR := 10.0     # a dash cut, a skill, the charged cut
const DRIBBLE := 2.5       # walked into
const CONTACT := 0.62      # Sora's middle to the ball's when her feet touch it
const FRICTION := Vector2(1.7, 0.8) # slowdown a second: this times speed, plus this (7 tiles/s stops in about 1.5 s)
const NET_DRAG := 6.0      # in the net it dies quickly
const KEEP := 0.6          # a bounce loses 40%
const NET_REST := 1.4      # seconds from the goal to the pop back (about 0.4 flying, 1.0 resting)
const HOME_AFTER := 10.0   # seconds away from Sora, off its spot, before it rolls back
const HOME_FAR := 7.0      # "away" is this far
const HOME_TIME := 0.9
const QUIET_FOE := 8.0     # a foe this near (tiles) and the ball sits still
const CHEER_NEAR := 12.0   # companions this near Sora cheer a goal

var ball: Node3D            # at ground level; the mesh child carries the roll
var ball_mesh: MeshInstance3D
var p := Vector2.ZERO       # world x, z of the ball's middle
var vel := Vector2.ZERO
var state := "play"         # play, net (a goal, resting), home (rolling back)
var spot := Vector2.ZERO
var bounds := Rect2()
var goal_x0 := 0.0          # the posts' x
var goal_x1 := 0.0
var goal_z := 0.0
var goal_n := 0.0           # the north goal line
var board: Label3D          # the goals on the side of the pitch
var circles: Array = []     # [Vector3(x, z, r)] the lamp, the posts
var segs: Array = []        # [Vector4(ax, az, bx, bz)] the net's sides and back

var goals := 0              # this save's goals (kept over a new round)
var kicks := 0              # strikes that sent it off (autoplay football_*)
var nudges := 0             # frames a walking Sora pushed it
var bounces := 0
var rolled := 0.0           # how far it has rolled, tiles
var net_t := 0.0
var away_t := 0.0
var home_t := 0.0
var home_from := Vector2.ZERO
var flashes := 0            # screen pulses shown (autoplay football_goal)
var cheers := 0             # companions who cheered the last goal (autoplay football_cheer)
var flash: ColorRect
var banner: Label
var flash_tw: Tween
var banner_tw: Tween
var ball_tex: ImageTexture
var net_tex: ImageTexture

func _init(main: Main) -> void:
	m = main

func vx() -> float:
	return m.village.VILLAGE_X

func tile(v: Vector2) -> Vector2:
	return Vector2(vx() + v.x, v.y)

# ---------------------------------------------------------------- build
func build() -> void:
	spot = tile(SPOT)
	p = spot
	bounds = Rect2(vx() + PITCH.position.x, PITCH.position.y, PITCH.size.x, PITCH.size.y)
	var gx := vx() + GOAL_X
	goal_x0 = gx - GOAL_W / 2.0
	goal_x1 = gx + GOAL_W / 2.0
	goal_z = GOAL_LINE
	goal_n = GOAL_LINE_N
	for at in [[goal_z, 1.0], [goal_n, -1.0]]: # each goal: its line, and which way its net runs
		var z: float = at[0]
		var s: float = at[1]
		var back: float = z + GOAL_DEPTH * s
		circles.append(Vector3(goal_x0, z, POST_R))
		circles.append(Vector3(goal_x1, z, POST_R))
		segs.append(Vector4(goal_x0, z, goal_x0, back))
		segs.append(Vector4(goal_x1, z, goal_x1, back))
		segs.append(Vector4(goal_x0, back, goal_x1, back))
		for r in [Vector3(goal_x0, z, 0.12), Vector3(goal_x1, z, 0.12), Vector3(gx, back - 0.1 * s, 0.5)]: # Sora walks round it
			m.rocks.append({"x": r.x, "z": r.y, "r": r.z})
		build_goal(gx, z, PI if s > 0.0 else 0.0)
	build_marks()
	build_ball()

# the painted lines, the corner flags and a board with the goals; thin boxes just above the lawn
func build_marks() -> void:
	var white: Material = m.mat_color(Color("#f6f3ea"), 0.6)
	var line := func(at: Vector2, w: float, d: float, yaw := 0.0) -> void:
		var b: MeshInstance3D = m.box(Vector3(w, 0.012, d), white)
		b.position = Vector3(at.x, 0.03, at.y)
		b.rotation.y = yaw
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(b)
	var x0: float = vx() + TOUCH_X.x
	var x1: float = vx() + TOUCH_X.y
	var mx: float = vx() + GOAL_X
	var mz := (goal_z + goal_n) / 2.0
	var long := goal_z - goal_n
	for x in [x0, x1]:
		line.call(Vector2(x, mz), LINE_W, long + LINE_W)
	for z in [goal_z, goal_n, mz]:
		line.call(Vector2(mx, z), x1 - x0, LINE_W)
	for k in 32: # the centre circle
		var a := TAU * k / 32.0
		line.call(Vector2(mx + cos(a) * CIRCLE_R, mz + sin(a) * CIRCLE_R), LINE_W, TAU * CIRCLE_R / 32.0 + 0.01, -a)
	line.call(Vector2(mx, mz), 0.16, 0.16)
	for at in [[goal_z, -1.0], [goal_n, 1.0]]: # the box before each goal
		var z: float = at[0] + BOX.y * at[1]
		line.call(Vector2(mx, z), BOX.x, LINE_W)
		for s in [-1.0, 1.0]:
			line.call(Vector2(mx + s * BOX.x / 2.0, at[0] + BOX.y * at[1] / 2.0), LINE_W, BOX.y)
	var pole: Material = m.mat_color(Color("#f6f3ea"), 0.6)
	var cloth: Material = m.mat_color(Color("#e0452e"), 0.7)
	for x in [x0, x1]:
		for z in [goal_z, goal_n]:
			var f: MeshInstance3D = m.box(Vector3(0.05, FLAG_H, 0.05), pole)
			f.position = Vector3(x, FLAG_H / 2.0, z)
			m.add_child(f)
			var c: MeshInstance3D = m.box(Vector3(0.26, 0.17, 0.02), cloth)
			c.position = Vector3(x + (0.15 if x < mx else -0.15), FLAG_H - 0.1, z)
			m.add_child(c)
			circles.append(Vector3(x, z, 0.04))
			m.rocks.append({"x": x, "z": z, "r": 0.08})
	build_board(Vector2(x1 + 0.36, mz))

func build_board(at: Vector2) -> void:
	var g := Node3D.new()
	g.position = Vector3(at.x, 0, at.y)
	m.add_child(g)
	var wood: Material = m.mat_color(Color("#6a4a2e"))
	for s in [-1.0, 1.0]:
		var leg: MeshInstance3D = m.box(Vector3(0.06, 0.8, 0.06), wood)
		leg.position = Vector3(s * 0.3, 0.4, 0)
		g.add_child(leg)
	var plate: MeshInstance3D = m.box(Vector3(0.74, 0.42, 0.05), m.mat_color(Color("#c8a46a")))
	plate.position = Vector3(0, 0.82, 0)
	g.add_child(plate)
	board = Label3D.new()
	board.font = m.ui_font
	board.font_size = 40
	board.pixel_size = 0.0065
	board.modulate = Color("#3a2414")
	board.outline_size = 0
	board.position = Vector3(0, 0.82, 0.03)
	g.add_child(board)
	update_board()
	m.rocks.append({"x": at.x, "z": at.y, "r": 0.2})

func update_board() -> void:
	if board != null:
		board.text = tr("골") + " " + str(goals)

func build_goal(gx: float, z: float, yaw: float) -> void:
	var g := Node3D.new()
	g.position = Vector3(gx, 0, z)
	g.rotation.y = yaw # built with the net behind (-z); PI turns the mouth north
	m.add_child(g)
	var white: Material = m.mat_color(Color("#f6f3ea"), 0.6)
	var add := func(size: Vector3, pos: Vector3, mat: Material, rot_x := 0.0) -> MeshInstance3D:
		var b: MeshInstance3D = m.box(size, mat)
		b.position = pos
		b.rotation.x = rot_x
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(b)
		return b
	for s in [-1.0, 1.0]:
		add.call(Vector3(0.12, GOAL_H, 0.12), Vector3(s * GOAL_W / 2.0, GOAL_H / 2.0, 0), white)
	add.call(Vector3(GOAL_W + 0.12, 0.1, 0.1), Vector3(0, GOAL_H - 0.05, 0), white)
	if net_tex == null:
		net_tex = m.make_tex(16, 16, func(img: Image):
			for i in 16:
				for j in 16:
					var line: bool = i == 0 or j == 0
					img.set_pixel(i, j, Color(1, 1, 1, 0.85) if line else Color(1, 1, 1, 0.06)))
	var slope := Vector2(GOAL_DEPTH, NET_DROP).length()
	var top := GOAL_H - 0.05 # the crossbar's middle
	add.call(Vector3(GOAL_W, 0.01, slope), Vector3(0, top - NET_DROP / 2.0, -GOAL_DEPTH / 2.0), net_mat(GOAL_W, slope), -atan2(NET_DROP, GOAL_DEPTH))
	add.call(Vector3(GOAL_W, top - NET_DROP, 0.01), Vector3(0, (top - NET_DROP) / 2.0, -GOAL_DEPTH), net_mat(GOAL_W, top - NET_DROP))
	for s in [-1.0, 1.0]:
		net_side(g, s * GOAL_W / 2.0, top)

# a side of the net: a four-cornered flat piece, tall at the mouth and lower at the back
func net_side(g: Node3D, x: float, top: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [Vector2(0, 0), Vector2(0, top), Vector2(-GOAL_DEPTH, top - NET_DROP), Vector2(-GOAL_DEPTH, 0)] # (z, y)
	for idx in [0, 1, 2, 0, 2, 3]:
		var q: Vector2 = pts[idx]
		st.set_uv(Vector2(-q.x, q.y) / 0.2)
		st.add_vertex(Vector3(0, q.y, q.x))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = net_mat(0.2, 0.2) # the uvs are in squares already
	mi.position = Vector3(x, 0, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(mi)

# the net's mesh: its squares are 0.2 tiles; a thin box shows the same grid on the faces that matter
func net_mat(w: float, h: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = net_tex
	mat.uv1_scale = Vector3(w / 0.2, h / 0.2, 1.0)
	return mat

# white with six dark pentagons (the dodecahedron's faces seen from the sides), painted onto an equirectangular sheet
func make_ball_tex() -> ImageTexture:
	var centres: Array = []
	for k in 3:
		centres.append(sphere_dir(TAU * k / 3.0, deg_to_rad(40.0)))
		centres.append(sphere_dir(TAU * k / 3.0 + PI / 3.0, deg_to_rad(-40.0)))
	var w := 128
	var h := 64
	return m.make_tex(w, h, func(img: Image):
		for y in h:
			for x in w:
				var d := sphere_dir(TAU * (x + 0.5) / w, PI * (0.5 - (y + 0.5) / h))
				var c := Color("#f4f1e8")
				for ctr in centres:
					if pentagon_has(ctr, d):
						c = Color("#23262e")
				img.set_pixel(x, y, c))

func sphere_dir(lon: float, lat: float) -> Vector3:
	return Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))

# is d (a unit vector) inside the pentagon of angular radius 0.5 around c?
func pentagon_has(c: Vector3, d: Vector3) -> bool:
	var ang := acos(clampf(c.dot(d), -1.0, 1.0))
	if ang > 0.5:
		return false
	var t1 := Vector3.UP.cross(c).normalized()
	var t2 := c.cross(t1)
	var th := atan2(d.dot(t2), d.dot(t1))
	var edge := 0.5 * cos(PI / 5.0) / cos(fposmod(th, TAU / 5.0) - PI / 5.0)
	return ang < edge

func build_ball() -> void:
	ball = Node3D.new()
	ball.position = Vector3(p.x, 0, p.y)
	m.add_child(ball)
	var sp := SphereMesh.new()
	sp.radius = RADIUS
	sp.height = RADIUS * 2.0
	sp.radial_segments = 24
	sp.rings = 12
	ball_mesh = MeshInstance3D.new()
	ball_mesh.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = make_ball_tex()
	mat.roughness = 0.55
	ball_mesh.material_override = mat
	ball_mesh.position = Vector3(0, RADIUS, 0)
	ball.add_child(ball_mesh)
	var shadow: MeshInstance3D = m.blob(0.75)
	shadow.reparent(ball, false) # blob() hangs it on the world
	shadow.position = Vector3(0, 0.02, 0)

# ---------------------------------------------------------------- striking
# anything that stops it: a story, a menu, the settings, the shop, a fall, or a foe within QUIET_FOE tiles of Sora
func quiet() -> bool:
	if m.story_open or m.ui.bag.visible or m.ui.journal.visible or m.settings_open or m.shop_open or m.down_t > 0.0:
		return true
	var me := Vector2(m.player.x, m.player.z)
	for e in m.enemies:
		if not e.dead and not e.get("prop", false) and Vector2(e.x, e.z).distance_to(me) < QUIET_FOE:
			return true
	return false

func in_square() -> bool:
	return ball != null and m.in_village and m.in_house < 0

# a blow in reach: the ball goes along her facing, or straight away from her when the blow goes all round
func hit(reach: float, f: Vector2, cone: float, all_round: bool, speed := KICK) -> void:
	if not in_square() or state != "play" or quiet():
		return
	var d := p - Vector2(m.player.x, m.player.z)
	if d.length() > reach + 0.4 or not (all_round or d.normalized().dot(f) > cone - 0.2):
		return
	kick((d.normalized() if d.length() > 0.05 else f) if all_round else f, speed)

# the dash cut passes the ball: it goes the way she is dashing
func dash(at: Vector2, f: Vector2) -> bool:
	if not in_square() or state != "play" or quiet() or p.distance_to(at) > 0.9:
		return false
	kick(f, KICK_FAR)
	return true

func kick(dir: Vector2, speed: float) -> void:
	vel = dir.normalized() * speed
	kicks += 1
	away_t = 0.0
	m.sfx(150.0, 0.1, "sine", 0.3, -90.0) # a soft thump
	m.burst(Vector3(p.x, 0.25, p.y), Color("#d8c8a8"), 4, 1.2)

# ---------------------------------------------------------------- moving
func update(dt: float) -> void:
	if ball == null:
		return
	var me := Vector2(m.player.x, m.player.z)
	if state == "home":
		update_home(dt)
	else:
		if state == "play" and not bounds.grow(0.4).has_point(p): # off the pitch (it should never be): back at once
			start_home()
			return
		if state == "play":
			dribble(me)
		var n := maxi(1, ceili(dt / 0.02))
		for i in n:
			step(dt / n)
		if state == "net":
			net_t += dt
			if net_t >= NET_REST:
				reset_ball()
		else:
			check_home(dt, me)
	ball.position = Vector3(p.x, 0, p.y)

# walking into it: it goes on ahead of her feet at DRIBBLE, never slower than that
func dribble(me: Vector2) -> void:
	var sv := Vector2(m.player.vx, m.player.vz)
	if sv.length() < 0.8 or m.dash.size() > 0 or quiet():
		return
	var to := p - me
	var d := to.length()
	if d > CONTACT:
		return
	var dir := sv.normalized()
	if d > 0.001 and dir.dot(to / d) < 0.3:
		return
	if vel.dot(dir) < DRIBBLE:
		vel = dir * DRIBBLE
		nudges += 1
	if d < 0.5:
		p = me + (to / d if d > 0.001 else dir) * 0.5

func step(h: float) -> void:
	var sp := vel.length()
	if sp > 0.0:
		var slow := (NET_DRAG * sp if state == "net" else FRICTION.x * sp + FRICTION.y) * h
		vel = vel * (maxf(0.0, sp - slow) / sp)
		if vel.length() < 0.12:
			vel = Vector2.ZERO
	var before := p
	p += vel * h
	collide()
	if state == "play" and p.x > goal_x0 and p.x < goal_x1 and ((before.y < goal_z and p.y >= goal_z) or (before.y > goal_n and p.y <= goal_n)):
		score()
	var moved := p - before
	if moved.length() > 0.0001:
		roll(moved)

func collide() -> void:
	var lo := bounds.position + Vector2(RADIUS, RADIUS)
	var hi := bounds.end - Vector2(RADIUS, RADIUS)
	if p.x < lo.x:
		p.x = lo.x
		bounce(Vector2(1, 0))
	elif p.x > hi.x:
		p.x = hi.x
		bounce(Vector2(-1, 0))
	if p.y < lo.y:
		p.y = lo.y
		bounce(Vector2(0, 1))
	elif p.y > hi.y:
		p.y = hi.y
		bounce(Vector2(0, -1))
	for c in circles:
		var at := Vector2(c.x, c.y)
		var reach: float = c.z + RADIUS
		var d := p - at
		if d.length_squared() < reach * reach:
			var n := d.normalized() if d.length() > 0.001 else Vector2(0, 1)
			p = at + n * reach
			bounce(n)
	for s in segs:
		var a := Vector2(s.x, s.y)
		var ab := Vector2(s.z, s.w) - a
		var q := a + ab * clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := p - q
		if d.length() < RADIUS:
			var n := d.normalized() if d.length() > 0.001 else Vector2(ab.y, -ab.x).normalized()
			p = q + n * RADIUS
			bounce(n)

# n points away from what it hit: the part going into it turns round, and 40% of the pace is lost
func bounce(n: Vector2) -> void:
	var into := vel.dot(n)
	if into >= 0.0:
		return
	vel = (vel - n * (2.0 * into)) * KEEP
	bounces += 1
	if -into > 0.8:
		m.sfx(300.0 + minf(-into, 7.0) * 12.0, 0.05, "triangle", 0.12, -90.0) # a tap

# it turns over by the distance it went, about the axis across its way
func roll(moved: Vector2) -> void:
	var dist := moved.length()
	rolled += dist
	var dir := moved / dist
	ball_mesh.basis = (Basis(Vector3(dir.y, 0, -dir.x), dist / RADIUS) * ball_mesh.basis).orthonormalized()

# ---------------------------------------------------------------- the goal
func score() -> void:
	state = "net"
	net_t = 0.0
	goals += 1
	update_board()
	m.save_game()
	goal_fx()

func goal_fx() -> void:
	ensure_fx()
	flashes = 0
	if flash_tw != null and flash_tw.is_valid():
		flash_tw.kill()
	flash_tw = flash.create_tween()
	for i in 3: # three pulses over 0.9 s, white then gold then white, each dying from 0.55
		flash_tw.tween_callback(func():
			flashes += 1
			flash.color = Color(1.0, 1.0, 0.94, 0.55) if i != 1 else Color(1.0, 0.82, 0.3, 0.55))
		flash_tw.tween_property(flash, "color:a", 0.0, 0.3)
	banner.text = tr("골!") + " " + str(goals)
	banner.visible = true
	banner.modulate.a = 1.0
	banner.scale = Vector2.ONE * 0.6
	if banner_tw != null and banner_tw.is_valid():
		banner_tw.kill()
	banner_tw = banner.create_tween()
	banner_tw.tween_property(banner, "scale", Vector2.ONE * 1.15, 0.25).set_trans(Tween.TRANS_SINE)
	banner_tw.tween_property(banner, "scale", Vector2.ONE, 0.15)
	banner_tw.tween_interval(1.6)
	banner_tw.tween_property(banner, "modulate:a", 0.0, 0.4)
	banner_tw.tween_callback(func(): banner.visible = false)
	if bool(m.cfg.get("shake", true)):
		m.shake = maxf(m.shake, 0.3)
	var net_at := Vector3(p.x, 0.5, goal_z + GOAL_DEPTH * 0.6 if p.y > spot.y else goal_n - GOAL_DEPTH * 0.6)
	m.burst(net_at, Color("#ffd24a"), 30, 3.5)
	m.burst(net_at + Vector3(0, 0.3, 0), Color("#fff1a0"), 20, 2.5)
	var notes := [523.0, 659.0, 784.0, 1047.0] # a short rising arpeggio
	for i in notes.size():
		var hz: float = notes[i]
		if i == 0:
			m.sfx(hz, 0.14, "triangle", 0.22)
		else:
			m.get_tree().create_timer(0.08 * i).timeout.connect(func(): m.sfx(hz, 0.14 if i < 3 else 0.3, "triangle", 0.22))
	cheer()

# Noeul and Mulgyeol, when they are with her and near, jump twice and shout (the owner, 14:17: "골인하면, 노을/물결이 환호해주는거 넣어줘")
func cheer() -> void:
	cheers = 0
	var me := Vector2(m.player.x, m.player.z)
	var who := [[m.mate2, "noeul", tr("골! 잘 찼어!"), 0.0], [m.mate, "mulgyeol", tr("우와, 들어갔다!"), 0.35]]
	for w in who:
		var node: Node3D = w[0]
		if node == null or not node.visible or Vector2(node.position.x, node.position.z).distance_to(me) > CHEER_NEAR:
			continue
		cheers += 1
		m.folk.cheer_t[w[1]] = m.folk.CHEER_T
		var line: String = w[2]
		if w[3] > 0.0: # one after the other, so the two balloons do not land at once
			m.get_tree().create_timer(w[3]).timeout.connect(func(): m.say_bubble(node, line, 2.2))
		else:
			m.say_bubble(node, line, 2.2)

func ensure_fx() -> void:
	if flash != null:
		return
	flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.94, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.hud.add_child(flash)
	banner = Label.new()
	banner.add_theme_font_override("font", m.ui_font)
	banner.add_theme_font_size_override("font_size", 64 if m.touch_ui else 96) # the banners' 40 px at 1600 wide, bigger: it is the prize
	banner.add_theme_color_override("font_color", Color("#ffd24a"))
	banner.add_theme_constant_override("outline_size", 14)
	banner.add_theme_color_override("font_outline_color", Color("#3a2204"))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.hud.add_child(banner)
	m.place(banner, Control.PRESET_CENTER, Vector2(-350, -170), Vector2(700, 140))
	banner.pivot_offset = Vector2(350, 70)
	banner.visible = false

# the ball pops back to its spot, small and growing
func reset_ball() -> void:
	state = "play"
	vel = Vector2.ZERO
	p = spot
	away_t = 0.0
	ball.position = Vector3(p.x, 0, p.y)
	ball.scale = Vector3.ONE * 0.2
	ball.create_tween().tween_property(ball, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	m.burst(Vector3(p.x, 0.3, p.y), Color("#ffd24a"), 8, 1.5)

# ---------------------------------------------------------------- home
# stuck, or left alone far from Sora for HOME_AFTER seconds: it rolls back to its spot
func check_home(dt: float, me: Vector2) -> void:
	if vel.length() > 0.3 or p.distance_to(spot) < 0.4 or me.distance_to(p) < HOME_FAR:
		away_t = 0.0
		return
	away_t += dt
	if away_t >= HOME_AFTER:
		start_home()

func start_home() -> void:
	state = "home"
	home_t = 0.0
	home_from = p
	vel = Vector2.ZERO

func update_home(dt: float) -> void:
	home_t += dt
	var k := clampf(home_t / HOME_TIME, 0.0, 1.0)
	var before := p
	p = home_from.lerp(spot, k * k * (3.0 - 2.0 * k))
	if (p - before).length() > 0.0001:
		roll(p - before)
	if k >= 1.0:
		state = "play"
		away_t = 0.0

# ---------------------------------------------------------------- save
func save_data() -> Dictionary:
	return {"goals": goals}

func load_data(d: Dictionary) -> void:
	goals = int(d.get("goals", 0))
	update_board()
