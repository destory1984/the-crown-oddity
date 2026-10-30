# Companions: following, trails, health, Noeul sitting, update_mate.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const MATE_OFF := {"mulgyeol": Vector3(-1.3, 0, -0.6), "noeul": Vector3(1.3, 0, -0.6)}
const MATE_BACK := {"mulgyeol": 1.3, "noeul": 2.5}
const MATE_REST := 10.0
# breathing while they stand (the owner, 2026-10-28, showing a pixel fighter's idle: "가만히 있을 때에도 조금씩 숨을
# 헐떡이면서 움직이잖아", tried on Noeul and Mulgyeol first): art/folk/<id>_breath.png holds four frames of the standing
# picture with the head eased down 0, 2, 3, 2 px and the chest between (tools/breath.py); a frame every 0.25 s
const BREATH_STEP := 0.25
var breath_tex := {}  # id -> its breathing sheet
const SIT_BREATH_STEP := 0.35 # sitting breathes slower than standing
var breath_keep := {} # id -> [texture, hframes] put back when he moves

var scenic_dir := Vector2.ZERO # world direction of a view Sora has stopped to take in: resting companions face it (hill_zone.update_scenic, delight idea 16)
const REVIVE_DIP_R := 6.0 # a companion who gets up within this many tiles of Sora bows to her
var revive_dips := 0 # bows made (autoplay d59_revive_bow)
var trailing := {} # id -> following on her footsteps because she walks along his side spot's line

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

# Mulgyeol goes back to waiting (the turtle fight left before it was won): the companion goes,
# and the villager in the square and his spot come back as before he joined
func leave_mate() -> void:
	if m.mate == null:
		return
	mulgyeol_sit(false)
	end_quirk()
	m.mate.queue_free()
	m.mate = null
	m.mate_spot.erase("mulgyeol")
	m.mate_aim.erase("mulgyeol")
	if m.village.folk_node.has("mulgyeol"):
		m.village.folk_node.mulgyeol.visible = true
		var at: Vector2 = m.village.folk_pos.mulgyeol
		m.rocks.append({"x": at.x, "z": at.y, "r": 0.45, "folk": "mulgyeol"})

func snap_mate() -> void:
	if m.mate != null:
		m.mate.position = mate_goal("mulgyeol")

func snap_mates() -> void:
	m.mate_trail.clear()
	m.mate_spot.clear()
	snap_mate()
	if m.mate2 != null:
		m.mate2.position = mate_goal("noeul")

# companions that fell in behind her in a narrow way and are still some way off; when Sora waits and the last of them
# comes up beside her, he makes a quiet two-tone, once per arrival (delight idea 20)
var lagging := {} # id -> true while he is trailing 2.6+ tiles behind
var arrive_acks := 0 # acknowledgements made (autoplay d20_arrive)
const ARRIVE_NEAR := 1.8

func update_arrival() -> void:
	var me := Vector3(m.player.x, 0, m.player.z)
	var ds := {}
	for id in ["mulgyeol", "noeul"]:
		var node := mate_node(id)
		if node == null or not node.visible:
			lagging[id] = false
			continue
		ds[id] = node.position.distance_to(me)
		if ds[id] > 2.6 and trailing.get(id, false):
			lagging[id] = true
	for id in ds:
		if not lagging.get(id, false) or ds[id] > ARRIVE_NEAR:
			continue
		lagging[id] = false
		var other_back := false
		for o in ds:
			other_back = other_back or (o != id and (lagging.get(o, false) or ds[o] > 3.0))
		var calm: bool = not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - me.x, e.z - me.z).length() < 7.0)
		if m.mate_idle >= 0.8 and not other_back and calm and not m.story_open and not m.intro:
			arrive_acks += 1
			m.sfx(660, 0.08, "sine", 0.08)
			m.get_tree().create_timer(0.1).timeout.connect(func(): m.sfx(880, 0.12, "sine", 0.08))

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
	# walking along the line of his side spot (east or west: the spot is ahead of her or behind her), he falls in behind
	# on her footsteps instead; the side spot flipped him from side to side to behind every few steps (the owner,
	# 2026-10-25). Once behind he stays there until her heading turns well across it, or she stops.
	var back1 = trail_spot(1.0) if m.mate_idle < 0.6 else null
	var along := false
	if back1 != null and (me - back1).length() > 0.01:
		var lim := 0.35 if trailing.get(id, false) else 0.55
		along = absf((MATE_OFF[id] as Vector3).normalized().dot((me - back1).normalized())) > lim
	trailing[id] = along
	if along:
		side_ok = false
	if not side_ok:
		var back_at = trail_spot(MATE_BACK[id]) if m.mate_idle < 0.6 else null
		goal = back_at if back_at != null else open_spot(id, avoid)
	m.mate_aim[id] = goal
	return goal

# ---- Mulgyeol's small doings (delight ideas 11, 13, 15, 17): a short walk along points checked walkable, a hold, then the
# ordinary following takes him back. Only while it is calm (no job, no fight, no story, not down) and no sooner than QUIRK_GAP
# after the last one; her stepping off ends it at once. The loop of idea 13 is her own walking, so that one ends when she leaves
# the ground she circled instead. Nothing here touches a gate, a hit or a reward.
const QUIRK_GAP := 6.0
const QUIRK_SPEED := 4.0
var quirk := {} # kind, path (Array of Vector3), i, hold, wait, free, stay (Vector2), ring
var quirk_t := -100.0
var quirks_made := {} # kind -> times started (autoplay d11, d13, d17)

func quirk_calm() -> bool:
	if m.mate == null or not m.mate.visible or m.mate_down["mulgyeol"] > 0.0 or not m.mate_job.is_empty() or m.story_open or m.intro or m.in_house >= 0:
		return false
	if m.garden_zone.clock_hold():
		return false
	var me := Vector2(m.player.x, m.player.z)
	var him := Vector2(m.mate.position.x, m.mate.position.z)
	return not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and (Vector2(e.x, e.z).distance_to(me) < 7.0 or Vector2(e.x, e.z).distance_to(him) < 8.0))

# `path` keeps only the points he can walk to in a straight line from the one before; false when none is left or he is busy
func start_quirk(kind: String, path: Array, hold: float, free := false, centre := Vector2.ZERO) -> bool:
	if not quirk.is_empty() or m.t - quirk_t < QUIRK_GAP or not quirk_calm():
		return false
	var ok: Array = []
	var from: Vector3 = m.mate.position
	for p in path:
		if m.walkable(p.x, p.z) and mate_way(from, p):
			ok.append(p)
			from = p
	if ok.is_empty() or (kind == "loop" and ok.size() < 8):
		return false
	quirk_t = m.t
	quirks_made[kind] = int(quirks_made.get(kind, 0)) + 1
	mulgyeol_sit(false)
	quirk = {"kind": kind, "path": ok, "i": 0, "hold": hold, "wait": 0.0, "free": free, "stay": centre, "ring": null}
	return true

func end_quirk() -> void:
	if quirk.get("ring") != null and is_instance_valid(quirk.ring):
		quirk.ring.queue_free()
	quirk = {}

# true while the quirk drives him this frame
func update_quirk(dt: float) -> bool:
	if quirk.is_empty():
		return false
	var moving: bool = Vector2(m.player.vx, m.player.vz).length() > 0.4
	var away: bool = quirk.free and Vector2(m.player.x, m.player.z).distance_to(quirk.stay) > 4.5
	var far: bool = m.mate.position.distance_to(Vector3(m.player.x, 0, m.player.z)) > 8.0
	if (moving and not quirk.free) or away or far or not quirk_calm():
		end_quirk()
		return false
	var spr: Sprite3D = m.mate.get_child(0)
	var to: Vector3 = (quirk.path[quirk.i] as Vector3) - m.mate.position
	to.y = 0.0
	if to.length() > 0.08:
		m.mate.position = mate_step(m.mate.position, to.normalized() * minf(to.length(), dt * QUIRK_SPEED))
		m.mate.position.y = 0.0
		spr.flip_h = not m.screen_left(Vector2(to.x, to.z))
		breathe("mulgyeol", spr, false)
		spr.frame = 1
		return true
	if quirk.i < quirk.path.size() - 1:
		quirk.i += 1
		return true
	quirk.wait += dt
	breathe("mulgyeol", spr, true)
	if quirk.kind == "loop":
		if quirk.ring == null:
			var ring := MeshInstance3D.new() # dizzy: a thin ring over his head, turning
			ring.mesh = m.effects.ring_mesh(0.22, 0.3, 0.0, TAU, 16)
			ring.material_override = m.glow_mat(Color("#ffe8a0"), 1.6)
			m.mate.add_child(ring)
			quirk.ring = ring
		quirk.ring.position = Vector3(0, 1.75, 0)
		quirk.ring.rotation = Vector3(0.35, quirk.wait * 6.0, 0)
	if quirk.wait >= quirk.hold:
		end_quirk()
	return true

# 11: Sora's blow reached the fountain; if he stands within 3 tiles of her he steps a tile back from the water, a beat before the drops fall
var fountain_steps := 0
func fountain_back(fountain: Vector2) -> bool:
	if m.mate == null:
		return false
	var him := Vector2(m.mate.position.x, m.mate.position.z)
	if him.distance_to(Vector2(m.player.x, m.player.z)) > 3.0 or him.distance_to(fountain) > 4.5:
		return false
	var away := (him - fountain).normalized() if him.distance_to(fountain) > 0.1 else Vector2(0, 1)
	var back := him + away * 1.0
	if start_quirk("fountain", [Vector3(back.x, 0, back.y)], 1.2):
		fountain_steps += 1
		return true
	return false

# 17: she looked into an opened chest again; he comes up beside it, looks in, and goes back with nothing
var chest_looks := 0
func chest_look(chest: Vector2) -> bool:
	if m.mate == null:
		return false
	var him := Vector2(m.mate.position.x, m.mate.position.z)
	var side := chest + (him - chest).normalized() * 0.9 if him.distance_to(chest) > 0.1 else chest + Vector2(0, 0.9)
	if start_quirk("chest", [Vector3(side.x, 0, side.y)], 1.0):
		chest_looks += 1
		return true
	return false

# 13: three turns of a small circle by the water; he runs one round of it and stops dizzy. A turn is counted from the changes of her
# heading every 0.1 s; standing still for 0.8 s, wandering off the spot or taking over 16 s starts the count again
const LOOP_TURNS := 3
const LOOP_FAR := 3.2
var loop_turn := 0.0
var loop_pts: Array = []
var loop_last := Vector2.ZERO
var loop_head := 0.0
var loop_has_head := false
var loop_clock := 0.0
var loop_idle := 0.0
var loop_age := 0.0

func loop_reset() -> void:
	loop_turn = 0.0
	loop_pts.clear()
	loop_has_head = false
	loop_idle = 0.0
	loop_age = 0.0

func loop_centre() -> Vector2:
	var c := Vector2.ZERO
	for p in loop_pts:
		c += p
	return c / maxf(loop_pts.size(), 1)

# open water, not a fence or a wall (which the tile map also calls water): the marsh's, the lake's, the village pond
func is_water(x: float, z: float) -> bool:
	if m.tile_at(x, z) != Main.WATER:
		return false
	if x < Main.CAVE_X - 0.5:
		return true
	if x >= Main.VILLAGE.VILLAGE_X - 0.5 and x < Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W:
		return m.village.char_at(x, z) in "~B"
	if x >= Main.LAKE.LAKE_X - 0.5 and x < Main.LAKE.LAKE_X + Main.LAKE.W:
		return m.lake.char_at(x, z) in "X-o"
	return false

func near_water(c: Vector2) -> bool:
	for r in [1.5, 2.5, 3.5]:
		for k in 8:
			var a := TAU * k / 8.0
			if is_water(c.x + cos(a) * r, c.y + sin(a) * r):
				return true
	return false

func track_loop(dt: float) -> void:
	loop_clock += dt
	if loop_clock < 0.1:
		return
	var span := loop_clock
	loop_clock = 0.0
	var p := Vector2(m.player.x, m.player.z)
	if m.mate == null or not quirk.is_empty():
		loop_reset()
		loop_last = p
		return
	var d := p - loop_last
	if d.length() < 0.1:
		loop_idle += span
		if loop_idle > 0.8:
			loop_reset()
		return
	loop_idle = 0.0
	loop_last = p
	var head := d.angle()
	if loop_has_head:
		loop_turn += angle_difference(loop_head, head)
	loop_head = head
	loop_has_head = true
	loop_age += span
	loop_pts.append(p)
	if loop_pts.size() > 160:
		loop_pts.pop_front()
	var c := loop_centre()
	if loop_age > 16.0 or p.distance_to(c) > LOOP_FAR:
		loop_reset()
		return
	if absf(loop_turn) < LOOP_TURNS * TAU - 0.6 or not near_water(c):
		return
	var dir := 1.0 if loop_turn > 0.0 else -1.0
	loop_reset()
	var him := Vector2(m.mate.position.x, m.mate.position.z)
	var a0 := (him - c).angle() if him.distance_to(c) > 0.3 else 0.0
	var path: Array = []
	for k in 13:
		var a := a0 + dir * TAU * k / 12.0
		path.append(Vector3(c.x + cos(a) * 1.5, 0, c.y + sin(a) * 1.5))
	start_quirk("loop", path, 1.6, true, c)

# 15: she skipped over the water and is on the bank; within 3 s of the landing, once she turns to face back along her way, he makes one
# more ring on the last water tile she crossed. Only a mark on the water: how far she may skip does not change.
const LOOK_BACK_T := 3.0
var skip_on := false
var skip_last := Vector2.ZERO
var look_t := 0.0
var look_at := Vector2.ZERO
var water_rings := 0
var last_water_ring: Node3D

func skip_watch(on_skip_water: bool, dt: float) -> void:
	var me := Vector2(m.player.x, m.player.z)
	if on_skip_water:
		skip_on = true
		skip_last = Vector2(roundf(me.x), roundf(me.y)) # the middle of the tile
		look_t = 0.0
		return
	if skip_on:
		skip_on = false
		look_t = LOOK_BACK_T
		look_at = skip_last
		return
	if look_t <= 0.0:
		return
	look_t -= dt
	if look_t <= 0.0 or m.mate == null or not m.mate.visible or m.story_open or m.tile_at(me.x, me.y) == Main.WATER:
		return
	var to := look_at - me
	if to.length() < 1.0 or to.length() > 9.0 or to.normalized().dot(m.player.face) < 0.8:
		return
	look_t = 0.0
	water_rings += 1
	var mat := m.glow_mat(Color("#bfe6ff"), 1.2)
	var ring := MeshInstance3D.new()
	ring.mesh = m.effects.ring_mesh(0.1, 0.16, 0.0, TAU, 16)
	ring.material_override = mat
	ring.position = Vector3(look_at.x, -0.2, look_at.y)
	last_water_ring = ring
	m.effects.add_fx(ring, 1.4, func(n: Node3D, k: float, _dt: float):
		n.scale = Vector3.ONE * (1.0 + 4.0 * k)
		mat.albedo_color.a = (1.0 - k) * 0.8)
	m.sfx(520, 0.1, "splash", 0.05, -200.0)

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
		if id == "mulgyeol" and m.mate_job.get("kind", "") in ["corr_post", "corr_cart"]:
			continue # at work at a sluice: out of the fight (v0.1.91; a blow on him there stopped the work and he never got up)
		if id == "noeul" and m.mate2_job.get("kind", "") == "obs_post":
			continue # at his post, steadying her hand: out of the fight
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
			if Vector2(m.player.x - node.position.x, m.player.z - node.position.z).length() < REVIVE_DIP_R and not m.story_open:
				m.folk.nod_t[id] = m.folk.NOD_T # a small bow towards Sora before the first step (delight idea 59)
				revive_dips += 1
		return m.mate_down[id] > 0.0
	if m.folk.nod_t.get(id, 0.0) > 0.0 and Vector2(m.player.vx, m.player.vz).length() > 0.4:
		m.folk.nod_t[id] = 0.0 # her stepping off ends it at once
	var calm := not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - node.position.x, e.z - node.position.z).length() < 8.0)
	if calm:
		m.mate_hp[id] = minf(mate_max(), mate_health(id) + 4.0 * dt)
	return false

func sora_resting() -> bool:
	if m.idle_t <= 0.6 or m.idle_name == "" or m.t - m.last_input_t < 10.0 or m.story_open:
		return false
	return not m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 7.0)

func breathe(id: String, spr: Sprite3D, on: bool) -> void:
	if not breath_tex.has(id):
		breath_tex[id] = load("res://art/folk/%s_breath.png" % id)
	if breath_keep.has(id) and spr.texture != breath_tex[id]: # a scene changed his picture meanwhile: keep that one
		breath_keep.erase(id)
	if on:
		if not breath_keep.has(id):
			breath_keep[id] = [spr.texture, spr.hframes]
			spr.texture = breath_tex[id]
			spr.hframes = 4
		spr.frame = int(m.t / BREATH_STEP) % 4
	elif breath_keep.has(id):
		spr.texture = breath_keep[id][0]
		spr.hframes = breath_keep[id][1]
		spr.frame = 0
		breath_keep.erase(id)

# at rest only: turn the picture to the view instead of the way last walked (Noeul's running frame faces right, Mulgyeol's picture left)
func scenic_face(spr: Sprite3D, noeul: bool) -> void:
	if scenic_dir != Vector2.ZERO and m.in_hill:
		var left: bool = m.screen_left(scenic_dir)
		spr.flip_h = left if noeul else not left

func noeul_sit(on: bool) -> void:
	if on == m.noeul_sitting or m.mate2 == null:
		return
	m.noeul_sitting = on
	var spr: Sprite3D = m.mate2.get_child(0)
	if m.noeul_tex == null:
		m.noeul_tex = spr.texture
		m.noeul_rest_tex = load("res://art/folk/noeul_rest_breath.png")
	spr.frame = 0
	spr.texture = m.noeul_rest_tex if on else m.noeul_tex
	spr.hframes = 4 if on else 3
	spr.frame = 0

func mulgyeol_sit(on: bool) -> void:
	if on == m.mulgyeol_sitting or m.mate == null:
		return
	m.mulgyeol_sitting = on
	var spr: Sprite3D = m.mate.get_child(0)
	if m.mulgyeol_tex == null:
		m.mulgyeol_tex = spr.texture
		m.mulgyeol_rest_tex = load("res://art/folk/mulgyeol_rest_breath.png")
	spr.texture = m.mulgyeol_rest_tex if on else m.mulgyeol_tex
	spr.hframes = 4 if on else 2
	spr.frame = 0
	spr.offset = Vector2(0, 90 if on else 85)

func update_mate2(dt: float) -> void:
	if m.mate2 == null:
		return
	m.mate2.visible = true
	if not sora_resting() or m.mate_down["noeul"] > 0.0:
		noeul_sit(false)
	if not m.mate2_job.is_empty(): # Noeul at a post in the observatory (v0.1.120)
		if m.in_observatory() and m.mate2_job.get("kind", "") == "obs_post":
			noeul_sit(false)
			if mate_tick("noeul", dt): # knocked down at his post: his rest runs, the work stops and the post is free
				m.observatory_zone.clear_job()
				return
			m.observatory_zone.update_mate2_job(dt)
			return
		m.mate2_job = {}
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
	if sit:
		breathe("noeul", spr, false)
	noeul_sit(sit)
	if sit: # sitting by her: no monster is near, so nothing to throw dust at
		spr.frame = int(m.t / SIT_BREATH_STEP) % 4 # breathing as he sits
		scenic_face(spr, true)
		return
	if to.length() > 0.3:
		m.mate2.position = mate_step(m.mate2.position, to.normalized() * minf(to.length() - 0.3, dt * 5.5))
		breathe("noeul", spr, false)
		spr.frame = 1
		spr.flip_h = m.screen_left(Vector2(to.x, to.z))
	else:
		breathe("noeul", spr, true)
		scenic_face(spr, true)
	m.folk.hop("noeul", spr, dt, 0.0, m.folk.HOP_H, false, m.folk.MATE_HOP_STEP)
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
		m.mate2_cd = 1.6 if m.hollow_q >= 4 else 2.0 # helpers, not the fighters (the owner, 2026-10-27): 1.4 -> 2.0 s
		breathe("noeul", spr, false)
		spr.frame = 2
		m.damage_enemy(target, m.player.atk * 0.25, Vector2(m.mate2.position.x, m.mate2.position.z), 2.0)
		m.burst(Vector3(target.x, 0.8, target.z), Color("#9a9a9a"), 12, 2.0)

func update_mate(dt: float) -> void:
	if m.mate == null:
		return
	m.mate.visible = true
	if m.mulgyeol_sitting and (not sora_resting() or m.mate_down["mulgyeol"] > 0.0 or not m.mate_job.is_empty() or m.garden_zone.clock_hold()):
		mulgyeol_sit(false)
	if not m.mate_job.is_empty():
		if m.in_corridor() and m.mate_job.get("kind", "") in ["corr_post", "corr_cart"]:
			if mate_tick("mulgyeol", dt): # knocked down at his post: his rest runs, the work stops and the post is free
				m.corridor_zone.clear_job()
				return
			m.corridor_zone.update_mate_job(dt)
			return
		if m.in_lake_main():
			m.lake_zone.update_mate_job(dt)
			return
		if m.in_workshop() and m.mate_job.get("kind", "") == "work": # B2's chain post
			m.workshop_zone.update_pull(dt)
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
		end_quirk()
		return
	if update_quirk(dt):
		return
	m.mate_cd -= dt
	var target = null
	var best := 5.0
	for e in m.enemies:
		if not e.dead and not e.get("prop", false) and not e.get("air", false) and Vector2(e.x, e.z).distance_to(Vector2(m.mate.position.x, m.mate.position.z)) < best:
			best = Vector2(e.x, e.z).distance_to(Vector2(m.mate.position.x, m.mate.position.z))
			target = e
	var goal := mate_goal("mulgyeol")
	if target != null:
		goal = Vector3(target.x, 0, target.z)
	var to := goal - m.mate.position
	var stop := 1.4 if target != null else 0.3
	var sit := target == null and to.length() <= 0.45 and sora_resting() and m.mate.position.distance_to(me) < 3.0
	if sit:
		breathe("mulgyeol", spr, false)
	mulgyeol_sit(sit)
	if sit: # sitting by her: nothing near, so nothing to fight
		spr.frame = int(m.t / SIT_BREATH_STEP + 2.0) % 4 # breathing as he sits, out of step with Noeul
		m.mate.position.y = 0.0
		m.folk.hop("mulgyeol", spr, dt, 0.0, m.folk.HOP_H, false, m.folk.MATE_HOP_STEP) # settles a hop that was still in the air
		scenic_face(spr, false)
		return
	if to.length() > stop:
		m.mate.position = mate_step(m.mate.position, to.normalized() * minf(to.length() - stop, dt * 5.5))
		spr.flip_h = not m.screen_left(Vector2(to.x, to.z)) # his picture faces left (Noeul's running frame faces right)
	else:
		m.mate.position.y = 0.0
		if target == null:
			scenic_face(spr, false)
	m.mate.position.y = 0.0
	m.folk.hop("mulgyeol", spr, dt, 0.0, m.folk.HOP_H, false, m.folk.MATE_HOP_STEP)
	if to.length() > stop or target != null:
		breathe("mulgyeol", spr, false)
		spr.frame = 1 if fmod(m.t, 3.0) < 0.3 else 0
	else:
		breathe("mulgyeol", spr, true)
	if target != null and best < 1.9 and m.mate_cd <= 0.0 and not m.story_open:
		m.mate_cd = 1.6 # 1.0 -> 1.6 s, so Sora does the fighting
		m.damage_enemy(target, m.player.atk * m.mate_power(), Vector2(m.mate.position.x, m.mate.position.z), 3.0)
		m.burst(Vector3(target.x, 0.8, target.z), Color("#7fd8d0"), 8, 1.6)
