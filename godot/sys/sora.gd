# Sora: build, sprite frames, idle moves, getting hit, falling, fainting.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const IDLE_ACTS := [
	"cheer-big", "hot-wipe", "rest-bubble", "rest-cheer", "rest-clap", "rest-comb", "rest-count", "rest-crane",
	"rest-draw", "rest-float", "rest-gum", "rest-hop", "rest-juggle", "rest-knit", "rest-letter", "rest-look",
	"rest-map", "rest-music", "rest-nod", "rest-note", "rest-photo", "rest-pinwheel", "rest-plush", "rest-ribbon",
	"rest-rope", "rest-scope", "rest-sit", "rest-sleep", "rest-snack", "rest-socks", "rest-spin", "rest-star",
	"rest-stretch", "rest-string", "rest-sway", "rest-tea", "rest-tilt", "rest-umbrella", "rest-water",
	"rest-wave", "rest-wave2", "rest-yawn", "rest-yoyo", "see-aurora", "see-hush", "see-point", "see-snap",
	"see-up", "see-wow", "idle" # "idle": the old standing loop (blink, look aside, wink) as one of the acts
]
const IDLE_LONG := ["rest-snack", "rest-tea", "rest-water", "rest-nod", "rest-sleep", "rest-yoyo", "rest-juggle", "rest-knit", "rest-draw", "rest-music", "rest-string"] # these play twice as long
const BUCKLER_GUARD := 0.16   # the flash guard window with the buckler (0.12 without)
const DOWN_TIME := 3.0

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- player
func blob(r: float) -> MeshInstance3D:
	var mm := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = Vector2(r, r * 0.7)
	mm.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = m.make_tex(16, 16, func(img: Image):
		for y in 16:
			for x in 16:
				var d := Vector2(x - 7.5, y - 7.5).length() / 8.0
				img.set_pixel(x, y, Color(0, 0, 0, clampf(0.55 * (1.0 - d), 0.0, 1.0))))
	mm.material_override = mat
	mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(mm)
	return mm

# a flat dark patch with soft edges (the sleepers' contact shadows)
func soft_patch(w: float, d: float, a: float) -> MeshInstance3D:
	var mm := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = Vector2(w, d)
	mm.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = m.make_tex(16, 16, func(img: Image):
		for y in 16:
			for x in 16:
				var e := minf(minf(x + 0.5, 15.5 - x), minf(y + 0.5, 15.5 - y)) / 2.5 # 0 at the rim, 1 a little in
				img.set_pixel(x, y, Color(0, 0, 0, a * clampf(e, 0.0, 1.0))))
	mm.material_override = mat
	mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mm

func build_player() -> void:
	m.player = {
		"x": Main.START.x, "z": Main.START.y, "vx": 0.0, "vz": 0.0, "face": Vector2(0, 1), "dir": "down", "anim": 0.0,
		"lv": 1, "xp": 0, "hp": 100.0, "max_hp": 100, "mp": 0.0, "max_mp": 100, "sp": 100.0, "atk": 10, "gold": 0, "pots": 3,
		"atk_cd": 0.0, "combo": 0, "combo_t": 0.0, "dodge": 0.0, "dvx": 0.0, "dvz": 0.0, "inv": 0.0, "cds": [0.0, 0.0, 0.0, 0.0], "hurt_t": 0.0,
	}
	m.hero = Sprite3D.new()
	m.hero.region_enabled = true
	# stand upright (a fully camera-facing quad leans back and sinks its feet into the ground and grass)
	# and stretch it by 1/cos(camera pitch) so it still reads at its true proportions
	m.hero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.hero.scale = Vector3(1, 1.0 / cos(0.78), 1)
	m.hero.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.hero.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	m.hero.shaded = false
	load_sora_art()
	m.add_child(m.hero)
	# a faint see-through copy drawn over everything, so Sora stays readable behind roofs and trees
	m.hero_ghost = Sprite3D.new()
	m.hero_ghost.region_enabled = true
	m.hero_ghost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.hero_ghost.shaded = false
	m.hero_ghost.no_depth_test = true
	m.hero_ghost.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	m.hero_ghost.modulate = Color(0.75, 0.82, 1.0, 0.35)
	m.hero_ghost.render_priority = -1
	m.hero_ghost.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.hero.add_child(m.hero_ghost)
	m.hero_shadow = blob(0.9)
	set_hero_frame("down", 0)

# Sora's sheets: the drawn 192x256 cells, or the Aseprite test (the owner, 2026-10-28): the same sheets shrunk to
# 72x96 pixel art on one 24-colour palette (art/sora/px96, made in C:/_c/test1/aseprite with scripts/pack.lua).
# Settings > 도트 소라 switches between them.
func load_sora_art() -> void:
	var px: bool = bool(m.cfg.get("sora_px", true))
	var dir := "res://art/sora/px96/" if px else "res://art/sora/"
	# walk sheets: 4 frames per row; straight rows front, left, right, away; diagonal rows dl, dr, ul, ur
	var straight: Texture2D = load(dir + "sora-v3-walk.png")
	var diag: Texture2D = load(dir + "sora-v3-diag.png")
	for d in [["down", 0], ["left", 1], ["side", 2], ["up", 3]]:
		m.hero_tex[d[0]] = [straight, d[1]]
	for d in [["downleft", 0], ["downright", 1], ["upleft", 2], ["upright", 3]]:
		m.hero_tex[d[0]] = [diag, d[1]]
	m.idle_tex.clear()
	# she stands about 244 px tall in a 256 px cell, feet 7 px above its bottom; the 96 px cells are 0.375 of that
	var k := 96.0 / 256.0 if px else 1.0
	m.walk_px = 1.58 / 244.0 / k
	m.walk_off = Vector2(0, 121) * k
	m.hero.texture = straight
	m.hero.pixel_size = m.walk_px
	m.hero.offset = m.walk_off

func sync_ghost() -> void:
	m.hero_ghost.texture = m.hero.texture
	m.hero_ghost.region_rect = m.hero.region_rect
	m.hero_ghost.pixel_size = m.hero.pixel_size
	m.hero_ghost.offset = m.hero.offset
	m.hero_ghost.flip_h = m.hero.flip_h

func set_hero_frame(dir: String, frame: int) -> void:
	m.hero.flip_h = false
	var e: Array = m.hero_tex[dir]
	var tex: Texture2D = e[0]
	var cw := tex.get_width() / 4.0
	var ch := tex.get_height() / 4.0
	m.hero.texture = tex
	m.hero.region_rect = Rect2(frame * cw, e[1] * ch, cw, ch)
	m.hero.pixel_size = m.walk_px
	m.hero.offset = m.walk_off

func set_hero_idle(name: String, frame: int) -> void:
	if not m.idle_tex.has(name):
		var px: bool = bool(m.cfg.get("sora_px", true)) and ResourceLoader.exists("res://art/sora/px96/%s.png" % name)
		m.idle_tex[name] = load(("res://art/sora/px96/%s.png" if px else "res://art/sora/idle/%s.png") % name)
	var tex: Texture2D = m.idle_tex[name]
	m.hero.texture = tex
	m.hero.flip_h = false
	var cw := tex.get_width() / 4.0
	m.hero.region_rect = Rect2(frame * cw, 0, cw, tex.get_height())
	m.hero.pixel_size = m.walk_px # same cell size and scale as the walk sheets
	m.hero.offset = m.walk_off

# the act she picks after waiting: at Bori's cottage she sips tea once a visit, beside a turning small windmill she takes
# out her pinwheel once a visit (delight ideas 61 and 62); anywhere else a random one
var tea_visit := false
var wheel_visit := false
var place_acts := 0 # tea and pinwheel acts chosen by the place (autoplay idle_places)

func idle_pick() -> String:
	var p := Vector2(m.player.x, m.player.z)
	if not m.in_village and not m.in_cave and not m.in_lake and not m.in_forest and not m.in_hill and not m.in_garden and p.distance_to(Vector2(m.shop_pos.x, m.shop_pos.z)) < 2.6:
		if not tea_visit:
			tea_visit = true
			place_acts += 1
			return "rest-tea"
	else:
		tea_visit = false
	var at_mill: bool = m.in_hill and m.hill.mills.any(func(mm): return mm.turning and p.distance_to(mm.pos) < 3.0)
	if at_mill:
		if not wheel_visit:
			wheel_visit = true
			place_acts += 1
			return "rest-pinwheel"
	else:
		wheel_visit = false
	var spot := spot_pick()
	if spot != "":
		return spot
	if map_due and not m.story_open and junction_near(Vector2(m.player.x, m.player.z), JUNCTION_R * 1.5) >= 0:
		map_due = false # the third return to the same crossing: she opens the map and reads where she is (idea 65)
		map_acts += 1
		idle_cause = "map"
		return "rest-map"
	if m.market.inn_fresh and not m.story_open: # the first rest after the inn is a stretch (idea 69)
		m.market.inn_fresh = false
		idle_cause = "inn"
		return "rest-stretch"
	if run_thirst and m.t - run_thirst_t < RUN_THIRST_KEEP and m.player.hp >= m.player.max_hp and not m.story_open:
		run_thirst = false
		idle_cause = "run"
		return "rest-water" # a long run at full health ends in a drink and a bottle cap (idea 70)
	return IDLE_ACTS.pick_random()

# Acts chosen by where she rests (delight ideas 63 64 66 67 68): each place offers its act once a visit and the visit
# ends when she is away from it. They run only through the normal safe idle delay (10 s still, no foe within 7).
const SPOT_R := 1.7
const SPOT_ACTS := {"hush": "see-hush", "pond": "rest-water", "moon": "see-up", "photo": "rest-photo", "shelter": "rest-umbrella"}
const SPOT_ORDER := ["hush", "pond", "moon", "photo", "shelter"]
const SHELTER_PEEK := 1.0 # the umbrella act lasts one look at the eave
var idle_cause := "" # why the act now playing was chosen: "" random, hush pond moon photo shelter inn run
var spot_visit := {} # spot key -> the index of the spot she is resting at, kept while she stays
var spot_acts := 0 # acts chosen by a spot, the inn or a run (autoplay d63..d70)
var run_t := 0.0 # seconds of unbroken running
var run_thirst := false # a run of RUN_LONG seconds has just ended at full health
var run_thirst_t := -100.0
const RUN_LONG := 3.0
const RUN_THIRST_KEEP := 40.0

func track_run(running: bool, dt: float) -> void:
	if running:
		run_t += dt
		return
	if run_t >= RUN_LONG and m.player.hp >= m.player.max_hp:
		run_thirst = true
		run_thirst_t = m.t
	run_t = 0.0

# The crossings of the village lanes (tagged cells of village.gd's map: the road meets the plaza lane and the west lane). The
# third time she comes back to one after leaving it (6 tiles away), her next safe rest is the map act and a toast names only
# the region she is in (delight idea 65). Nothing about unexplored routes is said.
const JUNCTION_CELLS := [Vector2(25, 10), Vector2(15, 5)] # village map columns and rows
const JUNCTION_R := 2.0
const JUNCTION_AWAY := 6.0
const JUNCTION_TIMES := 3
var junction_at := -1 # the crossing she stands at, kept until she is JUNCTION_AWAY from it
var junction_count: Array = [0, 0]
var map_due := false
var map_acts := 0 # map rests chosen this way (autoplay d65_map_back)

func junction_near(me: Vector2, r: float) -> int:
	if not m.in_village or m.in_house >= 0:
		return -1
	for i in JUNCTION_CELLS.size():
		if me.distance_to(JUNCTION_CELLS[i] + Vector2(Main.VILLAGE.VILLAGE_X, 0)) < r:
			return i
	return -1

func track_junction() -> void:
	var me := Vector2(m.player.x, m.player.z)
	if junction_at >= 0:
		if not m.in_village or me.distance_to(JUNCTION_CELLS[junction_at] + Vector2(Main.VILLAGE.VILLAGE_X, 0)) > JUNCTION_AWAY:
			junction_at = -1
		return
	var i := junction_near(me, JUNCTION_R)
	if i < 0:
		return
	junction_at = i
	junction_count[i] += 1
	if junction_count[i] >= JUNCTION_TIMES:
		junction_count[i] = 0
		map_due = true

func near_spot(me: Vector2, spots: Array) -> int: # the index of the spot she stands at, -1 for none
	for i in spots.size():
		if me.distance_to(spots[i]) < SPOT_R:
			return i
	return -1

func pond_spots() -> Array:
	var out: Array = []
	if m.in_village and m.in_house < 0:
		out.append(m.village.marks.f)
	if m.in_lake and m.lake.marks.has("f"):
		out.append(m.lake.marks.f)
	return out

func scenic_spots() -> Array:
	var out: Array = []
	if m.in_hill and not m.in_stairs() and not m.in_castle():
		if m.in_cloud():
			out.append(m.cloud.marks.c)
		else:
			for s in m.hill_zone.SCENIC:
				out.append(s.at)
	return out

func landing_spots() -> Array:
	var out: Array = []
	if m.in_stairs():
		for z in [5.0, 13.0, 21.0, 27.0]: # beside the four landing lanterns
			out.append(Vector2(Main.STAIRS.STAIRS_X + 4.0, z))
			out.append(Vector2(Main.STAIRS.STAIRS_X + 19.0, z))
	return out

func shelter_spots() -> Array:
	var out: Array = []
	if not m.raining:
		return out
	if m.in_village and m.in_house < 0:
		for key in m.market.STALLS:
			out.append(m.village.marks[key])
	elif m.in_marsh():
		out.append(Vector2(m.shop_pos.x, m.shop_pos.z))
	return out

func spot_pick() -> String:
	if m.story_open or m.intro:
		return ""
	var me := Vector2(m.player.x, m.player.z)
	var here := {
		"hush": 0 if m.folk.sleeper_near(me) else -1,
		"pond": near_spot(me, pond_spots()),
		"moon": near_spot(me, landing_spots()),
		"photo": near_spot(me, scenic_spots()),
		"shelter": near_spot(me, shelter_spots())}
	for k in SPOT_ORDER:
		if here[k] < 0:
			spot_visit.erase(k)
	for k in SPOT_ORDER:
		if here[k] >= 0 and spot_visit.get(k, -1) != here[k]:
			spot_visit[k] = here[k] # a different view or stall is a new visit
			spot_acts += 1
			idle_cause = k
			return SPOT_ACTS[k]
	return ""

# what the chosen act adds when it starts (idea 64 the shutter, 68 the moon ring, 70 the cap, 63 one look only)
func idle_begin() -> void:
	match idle_cause:
		"photo":
			m.sound.shutter()
		"moon":
			m.effects.moon_ring()
		"run":
			m.sound.bottle_cap()
		"map":
			m.toast(m.ui.zone_name.text) # only the name of the region she is in
		"shelter":
			m.idle_left = SHELTER_PEEK

# and when it runs to its end (idea 67: the last drop of the pond water)
func idle_end() -> void:
	if idle_cause == "pond" and m.idle_name == "rest-water":
		m.effects.pond_drop(Vector3(m.player.x, m.ground_y, m.player.z))

func update_idle(dt: float) -> void:
	# just stopped: breathe, facing the viewer, the head and shoulders easing 1-2 px down and up a frame every 0.25 s
	# (art/sora/*/breath.png; the owner, 2026-10-28: "가만히 있을 때에도 조금씩 숨을 헐떡이면서 움직이잖아", Noeul and
	# Mulgyeol first)
	if m.idle_name == "":
		m.idle_name = "breath"
		m.idle_k = 0.0
		m.idle_left = m.rnd(3.0, 6.0)
	m.idle_k += dt * (4.0 if m.idle_name == "breath" else (1.4 if m.idle_name == "idle" else 1.8)) # breathing 4 frames a second, the old loop 1.4, actions 1.8
	m.idle_left -= dt
	if m.idle_left <= 0.0:
		var calm: bool = m.combat.nearest_enemy(7.0) == null
		if m.idle_name == "breath" and calm and m.t - m.last_input_t >= 10.0:
			idle_cause = ""
			m.idle_name = idle_pick()
			m.idle_left = 8.9 if m.idle_name in IDLE_LONG else 4.45 # two or four loops of four frames
			idle_begin()
		else:
			idle_end()
			idle_cause = ""
			m.idle_name = "breath"
			m.idle_left = m.rnd(2.0, 4.0)
		m.idle_k = 0.0
	var frame := int(m.idle_k) % 4
	if m.idle_name == "see-hush":
		frame = mini(int(m.idle_k * 1.2), 3) # the hush plays once and holds
	elif idle_cause == "shelter" and m.idle_name == "rest-umbrella":
		frame = 0 # only the first frame: she sees the eave and does not open it
	set_hero_idle(m.idle_name, frame)

# Every attack on Sora comes through here: flash dodge, flash guard, guard, or a plain hit.
# Returns what happened; a flash guard staggers the attacker.
func player_hit(dmg: int, src: Vector2, attacker: Dictionary) -> String:
	var gy := m.ground_y
	var here := Vector3(m.player.x, gy, m.player.z)
	var me2 := Vector2(m.player.x, m.player.z)
	if m.sealed_between(src, me2) or (attacker.has("x") and m.sealed_between(Vector2(attacker.x, attacker.z), me2)):
		return "none" # a shut wall or locked door stops every blow, ring and shot
	if m.player.dodge > 0.0 and m.t - m.dodge_start <= (0.2 if m.player.lv >= 10 else 0.15) and m.flash_cd <= 0.0:
		m.slowmo = 2.0
		m.flash_cd = 3.0
		m.player.mp = minf(m.player.max_mp, m.player.mp + 20.0)
		m.player.sp = minf(100.0, m.player.sp + 25.0)
		m.burst(here + Vector3(0, 0.8, 0), Color("#9fe0ff"), 20, 2.5)
		m.sfx(880, 0.3, "sine", 0.3)
		m.toast("섬광 피하기!")
		m.stats.dodges += 1
		return "flash_dodge"
	if m.player.inv > 0.0:
		return "none"
	var to_src := (src - Vector2(m.player.x, m.player.z)).normalized()
	if m.guarding and to_src.dot(m.player.face) > 0.5: # attack from the front 120 degrees
		if m.t - m.guard_since <= (BUCKLER_GUARD if m.has_buckler else 0.12):
			m.player.mp = minf(m.player.max_mp, m.player.mp + 25.0)
			m.counter_t = 1.5
			if not attacker.is_empty():
				attacker.stun = 2.0 if attacker.get("boss", false) else 1.0
				attacker.wind = 0.0
				attacker.swing = 0.0
			var mm := MeshInstance3D.new()
			mm.mesh = m.ring_mesh(0.7, 0.95, -PI / 2.0 - 0.9, 1.8)
			var mat := m.glow_mat(Color.WHITE, 3.0)
			mm.material_override = mat
			mm.position = here + Vector3(0, 0.6, 0)
			mm.rotation.y = -atan2(m.player.face.y, m.player.face.x) - PI / 2.0
			m.add_fx(mm, 0.2, func(_n: Node3D, k: float, _dt: float): mat.albedo_color.a = 1.0 - k)
			m.sfx(1200, 0.15, "square", 0.2)
			m.shake = maxf(m.shake, 0.15)
			m.toast("섬광 막기! 반격하라")
			m.stats.guards += 1
			if attacker.has("x") and attacker.has("z") and not attacker.get("dead", false):
				m.effects.screw_pull(attacker) # a screw hops out of the foe's seam and goes back (idea 58)
			return "flash_guard"
		m.player.sp = maxf(0.0, m.player.sp - 15.0)
		m.sfx(520, 0.05, "triangle", 0.1, -80) # blocked: a light tick
		m.effects.stud_spin(here + Vector3(m.player.face.x * 0.9, 0.0, m.player.face.y * 0.9)) # a stud falls and spins (idea 51)
		hurt_player(int(ceil(dmg * 0.3)), gy)
		return "guard"
	hurt_player(dmg, gy)
	return "hit"

# every blow on Sora lands 1.6 times as hard (the owner, 2026-10-29: "게임이 쉽게 느껴지는건, 소라의 체력 대비 몹들의
# 공격력이 약해서야"): a field goblin took about 10 of her hits' worth of HP at every level; now about 6
const FOE_DMG_K := 1.6

func hurt_player(dmg: int, gy: float) -> void:
	dmg = int(round(dmg * FOE_DMG_K * m.ng_mult()))
	if m.has_armour:
		dmg = maxi(1, int(round(dmg * 0.85)))
	m.player.hp -= dmg
	m.effects.armour_shimmer(Vector3(m.player.x, gy, m.player.z))
	m.player.hurt_t = 0.2
	m.player.inv = 0.8
	m.shake = maxf(m.shake, 0.2)
	m.pop_num(Vector3(m.player.x, gy + 1.9, m.player.z), str(dmg), Color("#ff7a6a"))
	# getting hit: a short soft "oof" (two quiet tones) instead of a loud buzzing square thud
	m.sfx(m.rnd(300.0, 340.0), 0.09, "triangle", 0.13, -140.0)
	m.sfx(160.0, 0.12, "step", 0.08)
	if m.player.hp <= 0 and m.down_t <= 0.0:
		start_fall()

func start_fall() -> void:
	m.down_t = DOWN_TIME
	m.player.hp = 0.0
	m.player.inv = 99.0
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.player.dodge = 0.0
	m.guarding = false
	m.idle_name = ""
	set_hero_frame(m.player.dir, 0)
	m.sfx(330, 0.25, "triangle", 0.2, -200)
	m.get_tree().create_timer(0.3).timeout.connect(func(): m.sfx(150, 0.4, "triangle", 0.18, -60))
	m.burst(Vector3(m.player.x, m.ground_y + 0.4, m.player.z), Color("#d8c8a0"), 16, 1.5)

func update_fall(dt: float) -> void:
	m.down_t -= dt
	var k := clampf((DOWN_TIME - m.down_t) / 0.45, 0.0, 1.0) # tips over in 0.45 s, then lies still
	var side := -1.0 if m.player.face.dot(Vector2(cos(m.cam_yaw), -sin(m.cam_yaw))) < 0.0 else 1.0
	m.hero.billboard = BaseMaterial3D.BILLBOARD_DISABLED # a billboard ignores the node's tilt, so face the camera by hand
	m.hero.no_depth_test = true # lying low she would sink into the tall grass
	m.hero.rotation = Vector3(0, m.cam_yaw, -side * (PI / 2.0) * (1.0 - pow(1.0 - k, 3.0)))
	m.hero.position = Vector3(m.player.x, m.ground_y + 0.35 * k, m.player.z) # lifted a little so the grass does not swallow her
	var dim := clampf(1.0 - (DOWN_TIME - m.down_t - 2.0) / 1.0, 0.5, 1.0)
	m.hero.modulate = Color(dim, dim, dim)
	if m.hero_ghost != null:
		m.hero_ghost.visible = false
	if m.down_t <= 0.0:
		m.down_t = 0.0
		m.hero.rotation = Vector3.ZERO
		m.hero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.hero.no_depth_test = false
		if m.hero_ghost != null:
			m.hero_ghost.visible = true
		m.hero.modulate = Color.WHITE
		m.player.inv = 0.8
		faint()

# Sora faints: say so plainly, keep gold and level, heal the boss, and wake her at the start
func faint() -> void:
	m.clear_shore_job()
	m.clear_quarters_job()
	for id in ["mulgyeol", "noeul"]:
		if m.mate_down[id] > 0.0:
			m.mate_down[id] = 0.001 # gets up on the next tick
		m.mate_hp[id] = m.mate_max()
	if m.race_on:
		m.minigames.end_race("경주 중에 쓰러졌다")
	if m.trial_wave > 0:
		m.minigames.end_trial("시련에서 쓰러졌다")
	if m.in_corridor(): # the water corridor keeps her in the room she fell in (v0.1.84)
		m.corridor_zone.on_faint()
		return
	if m.in_garden:
		m.clear_clock_wave()
		m.beat_clear()
		m.clock_still = false
		m.garden.clock_view(false)
		m.ui.mini.map_tex = m.village.map_tex(Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W)
		m.in_garden = false
		m.in_village = true
		for e in m.enemies:
			if e.get("echo", false) and not e.dead:
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
		if m.garden_q >= 2 and m.garden_q < 5:
			m.garden_zone.mold_retry() # the fight starts over
			m.set_quest(Main.GARDEN_RETRY_QUEST)
	if m.in_lake:
		m.clear_south_job()
		m.in_lake = false
		m.in_village = true
		if m.grotto_q == 2:
			m.grotto_q = 1
			for e in m.enemies:
				if e.get("crab", false) and not e.dead:
					e.dead = true
					e.node.queue_free()
					e.shadow.queue_free()
		if m.lake_q == 3:
			m.lake_zone.turtle_retry() # row out again from the pier
			m.set_quest(Main.LAKE_RETRY_QUEST)
	if m.in_workshop():
		m.workshop_zone.on_faint() # the floors keep what was done; the cradle's latches stay wound
	if m.in_hill:
		m.in_hill = false
		m.in_village = true
		m.gust_dir = Vector2.ZERO
		if m.windrun_on: # the run counts as missed (its countdown stayed frozen on the quest line)
			m.hill_zone.miss_windrun(false)
		for e in m.enemies:
			if e.get("hawk", false) and not e.dead:
				e.hp = float(e.max_hp)
			if (e.get("scare", false) or e.get("knight", false) or e.get("mill_guard", false) or e.get("mill_escort", false)) and not e.dead:
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
		if m.cloud_q == 2:
			m.cloud_q = 1
		if m.castle_q == 2:
			m.castle_q = 1
	if m.in_village or m.in_forest:
		m.in_forest = false
		m.in_village = true
		m.ui.mini.map_tex = m.village.map_tex(Main.VILLAGE.VILLAGE_X + Main.VILLAGE.W)
		m.ui.zone_name.text = "등불 마을"
		m.ui.zone_sub.text = "돌 광장"
		m.ui.boss.visible = false
		for e in m.enemies:
			if e.get("noeul", false) and not e.dead:
				e.hp = float(e.max_hp)
				e.x = e.wx
				e.z = e.wz
				e.dash = 0.0
				e.wind = 0.0
		m.player.hp = float(m.player.max_hp)
		m.player.x = m.village.marks.M.x - 1.5
		m.player.z = m.village.marks.M.y + 1.5
		m.player.inv = 2.0
		m.ground_y = 0.0
		m.ui.banner_title.text = "쓰러졌다"
		m.ui.banner_sub.text = "광장에서 다시 눈을 떴다 · 금화와 레벨은 그대로"
		m.ui.banner.modulate.a = 1.0
		m.banner_t = 2.5 # held as long as the marsh's (it faded at once)
		return
	if m.in_cave: # wake outside: leave every bit of cave state behind
		m.in_cave = false
		if m.ui.has("outside_map"):
			m.ui.mini.map_tex = m.ui.outside_map
		m.ui.zone_name.text = "갈대늪"
		m.ui.zone_sub.text = "등불여울 건널목"
		m.ui.boss.visible = false
		for e in m.enemies:
			if e.get("mole", false) and not e.dead:
				e.hp = float(e.max_hp)
				e.x = m.cave_marks.B.x
				e.z = m.cave_marks.B.y
				e.dash = 0.0
				e.wind = 0.0
		if m.story_step > 7: # a later visit: the village's quest comes back with her
			m.set_quest(m.quest_before_cave if m.quest_before_cave != "" else m.main_road_quest())
			m.moon_tokens.refresh_quest()
	m.player.hp = float(m.player.max_hp)
	m.player.x = Main.START.x
	m.player.z = Main.START.y
	m.player.inv = 2.0
	m.ground_y = m.height_at(Main.START.x, Main.START.y)
	for e in m.enemies:
		if e.get("boss", false) and not e.dead:
			e.hp = float(e.max_hp)
			e.x = e.home.x
			e.z = e.home.y
			e.phase = 1 # the rematch starts calm and roars again at half (it stayed enraged at full HP)
			e.roar = 0.0
			m.ui.boss_bar.color = Color("#9a4ad8")
	m.ui.banner_title.text = "쓰러졌다"
	m.ui.banner_sub.text = "건널목에서 다시 눈을 떴다 · 금화와 레벨은 그대로"
	m.ui.banner.modulate.a = 1.0
	m.banner_t = 2.5
	m.sfx(330, 0.25, "triangle", 0.25, -150)
	m.get_tree().create_timer(0.25).timeout.connect(func(): m.sfx(220, 0.5, "triangle", 0.25, -100))
