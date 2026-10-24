# Companions: following, trails, health, Noeul sitting, update_mate.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const MATE_OFF := {"mulgyeol": Vector3(-1.3, 0, -0.6), "noeul": Vector3(1.3, 0, -0.6)}
const MATE_BACK := {"mulgyeol": 1.3, "noeul": 2.5}
const MATE_REST := 10.0

func _init(main: Main) -> void:
	m = main

# ---- Mulgyeol, the companion: trots after Sora and pokes the nearest enemy with his pole
func join_mate() -> void:
	if m.mate != null:
		return
	m.mate = Node3D.new()
	m.mate.add_child(m.folk_sprite("mulgyeol"))
	m.add_child(m.mate)
	if m.village.folk_node.has("mulgyeol"):
		m.village.folk_node.mulgyeol.visible = false
		var at: Vector2 = m.village.folk_pos.mulgyeol
		m.rocks = m.rocks.filter(func(r): return r.get("folk", "") != "mulgyeol" and Vector2(r.x, r.z).distance_to(at) > 0.1)
	snap_mate()

func snap_mate() -> void:
	if m.mate != null:
		m.mate.position = mate_goal("mulgyeol")

func snap_mates() -> void:
	m.mate_trail.clear()
	m.mate_spot.clear()
	snap_mate()
	if m.mate2 != null:
		m.mate2.position = mate_goal("noeul")

func note_trail(dt: float) -> void:
	var me := Vector3(m.player.x, 0, m.player.z)
	if not m.mate_trail.is_empty() and (m.mate_trail[0] as Vector3).distance_to(me) > 3.0:
		m.mate_trail.clear() # a jump (a door, a load): old footsteps lead nowhere
	if m.mate_trail.is_empty() or (m.mate_trail[0] as Vector3).distance_to(me) > 0.3:
		m.mate_trail.push_front(me)
		if m.mate_trail.size() > 24:
			m.mate_trail.pop_back()
		m.mate_idle = 0.0
	else:
		m.mate_idle += dt

# the point `back` tiles behind Sora along her footsteps, or null when she has not walked that far
func trail_spot(back: float):
	var prev := Vector3(m.player.x, 0, m.player.z)
	var left := back
	for p in m.mate_trail:
		var d: float = prev.distance_to(p)
		if d >= left and d > 0.0:
			return prev.lerp(p, left / d)
		left -= d
		prev = p
	return null

func mate_way(a: Vector3, b: Vector3) -> bool:
	for k in [0.35, 0.7, 1.0]:
		var p := a.lerp(b, k)
		if not m.walkable(p.x, p.z):
			return false
	return true

# whether walking straight from `from` to `to` goes through Sora
func passes_her(from_at: Vector3, to: Vector3, me: Vector3) -> bool:
	var seg := to - from_at
	var k := clampf((me - from_at).dot(seg) / maxf(seg.length_squared(), 0.0001), 0.0, 1.0)
	return (from_at + seg * k).distance_to(me) < 0.55

# the nearest open spot around Sora, turning out from the companion's usual side (kept while she stays put)
func open_spot(id: String, avoid) -> Vector3:
	var me := Vector3(m.player.x, 0, m.player.z)
	var c: Array = m.mate_spot.get(id, [])
	if not c.is_empty() and (c[0] as Vector3).distance_to(me) < 0.3 and (avoid == null or (c[1] as Vector3).distance_to(avoid) >= 1.0):
		return c[1]
	var off: Vector3 = MATE_OFF[id]
	var spot := me
	var found := false
	var view := Vector3(-sin(Main.CAM_YAW), 0, -cos(Main.CAM_YAW)) # straight behind or before her on screen hides one of them
	for strict in [true, false]:
		for r in [1.4, 2.0, 2.6]:
			for k in 8:
				var a := int((k + 1) / 2.0) * (PI / 4.0) * (1.0 if k % 2 == 0 else -1.0) # 0, -45, 45, -90, 90 ... degrees
				var dir := off.normalized().rotated(Vector3.UP, a)
				var p := me + dir * float(r)
				if strict and absf(dir.dot(view)) > 0.8:
					continue
				if mate_way(me, p) and (avoid == null or p.distance_to(avoid) >= 1.0):
					spot = p
					found = true
					break
			if found:
				break
		if found:
			break
	m.mate_spot[id] = [me, spot]
	return spot

func mate_goal(id: String) -> Vector3:
	var me := Vector3(m.player.x, 0, m.player.z)
	var node := mate_node(id)
	var avoid = m.mate_aim.get("mulgyeol") if id == "noeul" and m.mate != null else null
	var goal := me + (MATE_OFF[id] as Vector3)
	var side_ok := mate_way(me, goal) and (avoid == null or goal.distance_to(avoid) >= 1.0)
	if side_ok and node != null and m.mate_idle < 0.6 and passes_her(node.position, goal, me):
		side_ok = false # behind her in a corridor: no squeezing past
	if not side_ok:
		var back_at = trail_spot(MATE_BACK[id]) if m.mate_idle < 0.6 else null
		goal = back_at if back_at != null else open_spot(id, avoid)
	m.mate_aim[id] = goal
	return goal

func join_noeul() -> void:
	if m.mate2 != null:
		return
	m.mate2 = Node3D.new()
	m.mate2.add_child(m.village_life.noeul_sprite())
	m.add_child(m.mate2)
	snap_mates()

# Noeul keeps a step to Sora's right and throws brick dust at enemies within 4 m
# companions slide along walls, houses and rocks instead of walking into them (they used to stand inside roofs)
func mate_step(at: Vector3, d: Vector3) -> Vector3:
	var p := at
	if m.walkable(p.x + d.x, p.z) or not m.walkable(p.x, p.z): p.x += d.x
	if m.walkable(p.x, p.z + d.z) or not m.walkable(p.x, p.z): p.z += d.z
	return p

func mate_max() -> float:
	return 60.0 + m.player.lv * 6.0

func mate_node(id: String) -> Node3D:
	return m.mate if id == "mulgyeol" else m.mate2

func mate_health(id: String) -> float:
	if m.mate_hp[id] < 0.0:
		m.mate_hp[id] = mate_max()
	return m.mate_hp[id]

func hurt_mate(id: String, dmg: int) -> void:
	var node := mate_node(id)
	if node == null or m.mate_down[id] > 0.0:
		return
	m.mate_hp[id] = mate_health(id) - dmg
	m.pop_num(node.position + Vector3(0, 1.9, 0), str(dmg), Color("#ffb07a"))
	m.sfx(260, 0.08, "triangle", 0.1, -100)
	if m.mate_hp[id] <= 0.0:
		m.mate_hp[id] = 0.0
		m.mate_down[id] = 5.0 if id == "mulgyeol" and m.has_whistle else MATE_REST
		var spr: Sprite3D = node.get_child(0)
		spr.billboard = BaseMaterial3D.BILLBOARD_DISABLED # tilt by hand, as for Sora
		spr.rotation = Vector3(0, m.cam_yaw, PI / 2.0)
		spr.modulate = Color(0.6, 0.6, 0.65)
		spr.position.y = 0.3
		m.toast(tr("%s이(가) 쓰러져 잠시 쉰다") % tr("물결" if id == "mulgyeol" else "노을"))

# companions near a strike or a thrown brick take the hit as well
func mate_near(at: Vector2, r: float) -> String:
	for id in ["mulgyeol", "noeul"]:
		var node := mate_node(id)
		if node != null and node.visible and m.mate_down[id] <= 0.0 and Vector2(node.position.x, node.position.z).distance_to(at) < r:
			return id
	return ""

# returns true while the companion is down (its update should stop there)
func mate_tick(id: String, dt: float) -> bool:
	var node := mate_node(id)
	var spr: Sprite3D = node.get_child(0)
	if m.mate_down[id] > 0.0:
		m.mate_down[id] -= dt
		if m.mate_down[id] <= 0.0 or not node.visible:
			m.mate_down[id] = 0.0
			m.mate_hp[id] = mate_max() * 0.5
			spr.rotation = Vector3.ZERO
			spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			spr.modulate = Color.WHITE
			spr.position.y = 0.0
			m.burst(node.position + Vector3(0, 0.8, 0), Color("#9fe0ff"), 10, 1.2)
		return m.mate_down[id] > 0.0
	var calm := not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - node.position.x, e.z - node.position.z).length() < 8.0)
	if calm:
		m.mate_hp[id] = minf(mate_max(), mate_health(id) + 4.0 * dt)
	return false

func sora_resting() -> bool:
	if m.idle_t <= 0.6 or m.idle_name == "" or m.t - m.last_input_t < 10.0 or m.story_open:
		return false
	return not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 7.0)

func noeul_sit(on: bool) -> void:
	if on == m.noeul_sitting or m.mate2 == null:
		return
	m.noeul_sitting = on
	var spr: Sprite3D = m.mate2.get_child(0)
	if m.noeul_tex == null:
		m.noeul_tex = spr.texture
		m.noeul_rest_tex = load("res://art/folk/noeul_rest.png")
	spr.frame = 0
	spr.texture = m.noeul_rest_tex if on else m.noeul_tex
	spr.hframes = 1 if on else 3
	spr.frame = 0

func update_mate2(dt: float) -> void:
	if m.mate2 == null:
		return
	m.mate2.visible = true
	if not sora_resting() or m.mate_down["noeul"] > 0.0:
		noeul_sit(false)
	if m.garden_zone.clock_hold(): # at a spoke of the big key, pushing with everyone
		noeul_sit(false)
		var hs := m.hand_spot(Main.CLOCK_HANDS.find("noeul"))
		m.mate2.position = Vector3(hs.x, m.garden_zone.clock_hop_y(), hs.y)
		return
	if m.mate_job_state() == "wait": # waiting outside the grate by Mulgyeol, not at Sora's side
		noeul_sit(false)
		var post := Vector3(m.mate_job.home.x, 0, m.mate_job.home.y - 1.0)
		m.mate2.position = post if m.mate2.position.distance_to(post) > 3.0 else m.mate2.position.move_toward(post, dt * 5.5)
		return
	var me := Vector3(m.player.x, 0, m.player.z)
	if m.mate2.position.distance_to(me) > 8.0:
		m.mate2.position = mate_goal("noeul")
	var spr: Sprite3D = m.mate2.get_child(0)
	if mate_tick("noeul", dt):
		return
	m.mate2_cd -= dt
	var goal := mate_goal("noeul")
	var to := goal - m.mate2.position
	var sit := to.length() <= 0.45 and sora_resting() and m.mate2.position.distance_to(me) < 3.0
	noeul_sit(sit)
	if sit: # sitting by her: no monster is near, so nothing to throw dust at
		return
	if to.length() > 0.3:
		m.mate2.position = mate_step(m.mate2.position, to.normalized() * minf(to.length() - 0.3, dt * 5.5))
		spr.frame = 1
		spr.flip_h = m.screen_left(Vector2(to.x, to.z))
	else:
		spr.frame = 0
	m.folk.hop("noeul", spr, dt)
	if m.mate != null and m.mate.visible: # never on top of Mulgyeol
		var apart := Vector3(m.mate2.position.x - m.mate.position.x, 0, m.mate2.position.z - m.mate.position.z)
		if apart.length() < 0.7 and apart.length() > 0.01:
			m.mate2.position = mate_step(m.mate2.position, apart.normalized() * dt * 2.0)
	var target = null
	var best := 4.0
	for e in m.enemies:
		var dd := Vector2(e.x, e.z).distance_to(Vector2(m.mate2.position.x, m.mate2.position.z))
		if not e.dead and dd < best and not e.get("air", false) and not e.get("prop", false):
			best = dd
			target = e
	if target != null and m.mate2_cd <= 0.0 and not m.story_open:
		m.mate2_cd = 1.1 if m.hollow_q >= 4 else 1.4
		spr.frame = 2
		m.damage_enemy(target, m.player.atk * 0.7, Vector2(m.mate2.position.x, m.mate2.position.z), 2.0)
		m.burst(Vector3(target.x, 0.8, target.z), Color("#9a9a9a"), 12, 2.0)

func update_mate(dt: float) -> void:
	if m.mate == null:
		return
	m.mate.visible = true
	if not m.mate_job.is_empty():
		if m.in_lake and not m.in_grotto():
			m.lake_zone.update_mate_job(dt)
			return
		m.mate_job = {}
	if m.garden_zone.clock_hold():
		var hs := m.hand_spot(Main.CLOCK_HANDS.find("mulgyeol"))
		m.mate.position = Vector3(hs.x, m.garden_zone.clock_hop_y(), hs.y)
		return
	var me := Vector3(m.player.x, 0, m.player.z)
	if m.mate.position.distance_to(me) > 8.0:
		snap_mate()
	var spr: Sprite3D = m.mate.get_child(0)
	if mate_tick("mulgyeol", dt):
		return
	m.mate_cd -= dt
	var target = null
	var best := 5.0
	for e in m.enemies:
		if not e.dead and not e.get("prop", false) and Vector2(e.x, e.z).distance_to(Vector2(m.mate.position.x, m.mate.position.z)) < best:
			best = Vector2(e.x, e.z).distance_to(Vector2(m.mate.position.x, m.mate.position.z))
			target = e
	var goal := mate_goal("mulgyeol")
	if target != null:
		goal = Vector3(target.x, 0, target.z)
	var to := goal - m.mate.position
	var stop := 1.4 if target != null else 0.3
	if to.length() > stop:
		m.mate.position = mate_step(m.mate.position, to.normalized() * minf(to.length() - stop, dt * 5.5))
		spr.flip_h = not m.screen_left(Vector2(to.x, to.z)) # his picture faces left (Noeul's running frame faces right)
	else:
		m.mate.position.y = 0.0
	m.mate.position.y = 0.0
	m.folk.hop("mulgyeol", spr, dt)
	spr.frame = 1 if fmod(m.t, 3.0) < 0.3 else 0
	if target != null and best < 1.9 and m.mate_cd <= 0.0 and not m.story_open:
		m.mate_cd = 1.0
		m.damage_enemy(target, m.player.atk * m.mate_power(), Vector2(m.mate.position.x, m.mate.position.z), 3.0)
		m.burst(Vector3(target.x, 0.8, target.z), Color("#7fd8d0"), 8, 1.6)
