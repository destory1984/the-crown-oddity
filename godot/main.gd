# The Crown Oddity: Godot 4 port of the browser demo.
# Everything (world, actors, HUD) is built from code so the scene file stays tiny.
#
# Layout: main.gd keeps the shared state (every var, and the consts that more than one file uses), _ready,
# _process, _input, crown_key and interact (the E key), tile/height helpers, toast and set_quest. Each system is
# a RefCounted in sys/<name>.gd, made once below as `var <name>` with this node as `m`: its code reaches the
# state as m.x, main's consts as Main.X and other systems as m.<name>.f(). Funcs that other scripts call on this
# node (tools/autoplay.gd, hud.gd, the area scripts) or that three or more files use keep a one-line forwarder
# here, so main.f() still works. File map:
#   sys/scenes.gd         Test scenes: the SCENES table and apply_test_args (dev.py shot/test start states).
#   sys/sound.gd          Sound: sfx() synthesises every effect in code, footsteps.
#   sys/effects.gd        Particles and effects: motes, bursts, rings, sword-swing drafts, slash fx, damage numbers.
#   sys/world_build.gd    World build: environment, island map, bridges, terrain, vegetation, grass drafts, props, lights, cottage.
#   sys/shop.gd           Bori's shop: open/close, prices, buying.
#   sys/sora.gd           Sora: build, sprite frames, idle moves, getting hit, falling, fainting.
#   sys/combat.gd         Combat: damage, xp, attacks, dash/charged slashes, skills, potions, dodge.
#   sys/monsters.gd       Monsters: goblins, wolves, bats, hedgehogs, the boss, enemy update loop, thrown bricks.
#   sys/daynight.gd       Day and night: hour, moon phase, skipping time, sun and sky light.
#   sys/hud_build.gd      HUD: panels, labels, bars, build_hud, mate bars, moon pips, touch layer, gold keys.
#   sys/story.gd          Story: illustrated story scenes, opening beats, show_story and its lines.
#   sys/save.gd           Save and load (user://save.json), old-save repair, reset.
#   sys/menus.gd          Menus: Space Oddity look, settings, help, sound toggle, journal.
#   sys/chatter.gd        Talk balloons: companions' chat and villagers' chatter.
#   sys/minigames.gd      Side games: the moon trial, the pinwheel race, fishing.
#   sys/folk.gd           Villagers: house rooms, sleeping at night, day routines and paths, cupboards.
#   sys/errands.gd        Feats, Doran's letters, festival, new round, hint villagers and errands.
#   sys/waystones.gd      Moon waystones: the list of reached stones and travel between hubs.
#   sys/village_life.gd   Village: entering/leaving, lamp cost, moon gauge pips, the lantern night, Kongal's kid, lamps.
#   sys/market.gd         Market: honesty-box stalls, target yard, inn, bottles, the magpie thief.
#   sys/cave.gd           Cave: build, props, shrine, singing crystals, the post tunnel, entering/leaving, the cart-mole.
#   sys/shore.gd          Waking shore (chapter 1): the reed basket, floats, snag, shore foes, Bori's lines.
#   sys/forest_zone.gd    Hardened forest: walls, grove, squirrel cages, south valley, the squirrel oak.
#   sys/lake_zone.gd      South lake: Mulgyeol, the turtle, the lower pond, the water grotto and crab.
#   sys/hill_zone.gd      Wind hills: cloud mound, gusts, scarecrow, the sparrows' mill, wind run, the hawk.
#   sys/castle_zone.gd    Sunken castle: hall, knight, quarters and doll, moon stairs, the undercroft.
#   sys/mates.gd          Companions: following, trails, health, Noeul sitting, update_mate.
#   sys/garden_zone.gd    Garden: the heart, Hangyeol's road, the mold boss, the clock room, workers, winding.
#   sys/workshop_zone.gd  Deep workshop: the great hall's door, three floors under the castle, the cradle, Simji's bench.
extends Node3D

# The systems: one object per sys/*.gd file (see the file map above), each holding this node as `m`.
var scenes := preload("res://sys/scenes.gd").new(self)
var sound := preload("res://sys/sound.gd").new(self)
var effects := preload("res://sys/effects.gd").new(self)
var world_build := preload("res://sys/world_build.gd").new(self)
var dressing := preload("res://sys/ground_dressing.gd").new(self)
var shop := preload("res://sys/shop.gd").new(self)
var sora := preload("res://sys/sora.gd").new(self)
var combat := preload("res://sys/combat.gd").new(self)
var monsters := preload("res://sys/monsters.gd").new(self)
var daynight := preload("res://sys/daynight.gd").new(self)
var hud_build := preload("res://sys/hud_build.gd").new(self)
var story := preload("res://sys/story.gd").new(self)
var save := preload("res://sys/save.gd").new(self)
var menus := preload("res://sys/menus.gd").new(self)
var chatter := preload("res://sys/chatter.gd").new(self)
var minigames := preload("res://sys/minigames.gd").new(self)
var folk := preload("res://sys/folk.gd").new(self)
var music := preload("res://sys/music.gd").new(self)
var errands := preload("res://sys/errands.gd").new(self)
var waystones := preload("res://sys/waystones.gd").new(self)
var village_life := preload("res://sys/village_life.gd").new(self)
var market := preload("res://sys/market.gd").new(self)
var cave := preload("res://sys/cave.gd").new(self)
var shore := preload("res://sys/shore.gd").new(self)
var forest_zone := preload("res://sys/forest_zone.gd").new(self)
var lake_zone := preload("res://sys/lake_zone.gd").new(self)
var hill_zone := preload("res://sys/hill_zone.gd").new(self)
var castle_zone := preload("res://sys/castle_zone.gd").new(self)
var mates := preload("res://sys/mates.gd").new(self)
var garden_zone := preload("res://sys/garden_zone.gd").new(self)
var workshop_zone := preload("res://sys/workshop_zone.gd").new(self)
var quest_marks := preload("res://sys/quest_marks.gd").new(self)

const N := 48
const WATER := 0
const GRASS := 1
const SAND := 2
const BRIDGE := 3
const START := Vector2(15, 20)
const CAM_ROTATE := false # camera rotation (Q/E) is switched off for now

var rng := RandomNumberGenerator.new()
var map := PackedByteArray()
var hgt := PackedFloat32Array()
var rocks: Array = []        # blockers: {x, z, r}
var bridges: Array = []

var player := {}
var enemies: Array = []
var chests: Array = []
var projectiles: Array = []
var fx: Array = []           # {node, life, t, update: Callable}

const CAM_YAW := 0.55
var cam_yaw := CAM_YAW
var cam_dist := 18.0
var shake := 0.0
var intro := true
var raining := false
var t := 0.0
var ground_y := 0.0         # smoothed ground height under the player, so 0.18 steps don't jolt the camera
var muted := false
var music_on := true # background music (the B key, the settings header button); saved beside `muted`
# Ys-style combat feel: hit-stop, flash dodge (slow-mo), guard and flash guard (counter)
var hitstop := 0.0          # seconds the whole game stays frozen after a hit
var slowmo := 0.0           # seconds enemies run at SLOWMO speed after a flash dodge
const SLOWMO := 0.25
var flash_cd := 0.0
var dodge_start := -9.0
var guarding := false
var guard_since := -9.0
var counter_t := 0.0        # first slash in this window is a guaranteed x2.5 critical
var last_hit_t := -9.0      # last time a slash connected; momentum drains after 4 s without one
var fake_keys := {}           # keys held down by the autoplay tests
# phones (the user asked, 2026-10-24): touch.gd's stick and keys; on Android and iOS browsers, or TOUCH_UI=1
var touch_ui := false
var touch_move := Vector2.ZERO # the stick, x right and y down on screen, length 0 to 1
var touch_keys := {}          # keys held through the touch keys (guard, run)
var touch_layer: Control

func key_down(k: int) -> bool:
	return fake_keys.has(k) or touch_keys.has(k) or Input.is_key_pressed(k)

var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var hero: Sprite3D
var hero_shadow: MeshInstance3D
var hero_tex := {}           # name -> [texture, row]
var rain: CPUParticles3D
var motes: CPUParticles3D

var ui_font: Font
var title_font: SystemFont
var hud: CanvasLayer
var ui := {}
var toast_t := 0.0
var banner_t := 0.0

# ---------------------------------------------------------------- helpers
func rnd(a := 0.0, b := 1.0) -> float:
	return rng.randf_range(a, b)

func idx(x: int, z: int) -> int:
	return x + z * N

# ---------------------------------------------------------------- cave (story steps 6 and 7)
# The underground cave is a 32x24 grid built far east of the marsh (x >= CAVE_X).
const CAVE_X := 100
var cave_grid: Array = []   # rows of characters
var in_cave := false
var cave_door_open := false
var cave_marks := {}        # letter -> world Vector2 (S, P, K, D, B, E; 1 2 3 the shrine's stones)

func tile_at(x: float, z: float) -> int:
	if x >= WORK.WORK_X - 0.5:
		return WATER if wfloors[WORK.floor_of(x)].blocked(x, z) else GRASS
	if x >= VILLAGE.VILLAGE_X - 0.5:
		return WATER if village.blocked(x, z) else (SAND if village.char_at(x, z) in "=:P" else GRASS)
	if x >= UNDER.UNDER_X - 0.5 and x < VILLAGE.VILLAGE_X - 0.5:
		return WATER if under.blocked(x, z, castle_zone.under_shut()) else GRASS
	if x >= STAIRS.STAIRS_X - 0.5:
		return WATER if stairs.blocked(x, z) else GRASS
	if x >= HOUSE_X - 0.5:
		return WATER if folk.house_char(x, z) == "#" else GRASS
	if x >= CASTLE.CASTLE_X - 0.5:
		return WATER if castle.blocked(x, z) else GRASS
	if x >= CLOUD.CLOUD_X - 0.5:
		return WATER if cloud.blocked(x, z) else GRASS
	if x >= GROTTO.GROTTO_X - 0.5:
		return WATER if grotto.blocked(x, z) else GRASS
	if x >= HILL.HILL_X - 0.5:
		return WATER if hill.blocked(x, z) else (SAND if hill.char_at(x, z) == "=" else GRASS)
	if x >= LAKE.LAKE_X - 0.5:
		return WATER if lake.blocked(x, z) else (SAND if lake.char_at(x, z) in "=PQ" else GRASS)
	if x >= GARDEN.GARDEN_X - 0.5:
		return WATER if garden.blocked(x, z) else (SAND if garden.char_at(x, z) == "=" else GRASS)
	if x >= FOREST.FOREST_X - 0.5:
		return WATER if forest.blocked(x, z) else (SAND if forest.char_at(x, z) == "=" else GRASS)
	if x >= CAVE_X - 0.5:
		var c := cave_char(x, z)
		return WATER if c == "#" or c == "D" or c in "~GTM" else (SAND if c == "w" else GRASS)
	var tx := int(round(x))
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= N or tz >= N:
		return WATER
	return map[idx(tx, tz)]

func height_at(x: float, z: float) -> float:
	if x >= CAVE_X - 0.5:
		return 0.0
	var tx := int(round(x))
	var tz := int(round(z))
	if tx < 0 or tz < 0 or tx >= N or tz >= N:
		return -1.0
	return hgt[idx(tx, tz)]

func walkable(x: float, z: float) -> bool:
	if tile_at(x, z) == WATER:
		return false
	for r in rocks:
		if not r.has("bush") and Vector2(r.x - x, r.z - z).length() < r.r:
			return false
	return true

# a straight line between two spots with no wall between them (open river water does not count as a wall: shots cross it).
# Resting counts only the monsters that can see her this way (GPT lap 6: one behind a wall 6 tiles off blocked the lamp)
func line_clear(a: Vector2, b: Vector2) -> bool:
	var n := maxi(1, int(ceil(a.distance_to(b) / 0.4)))
	for i in range(1, n):
		var p := a.lerp(b, float(i) / n)
		if tile_at(p.x, p.y) == WATER and not skip_water(p.x, p.y):
			return false
	return true

# one rule for every enemy and every attack: a closed brick wall (the forest) or the locked cave door lies between two spots,
# so a blow, dash, ring or shot cannot cross it (GPT lap 8: the forest duel was fought through a shut wall). The duel
# clearing counts as walled in while its wall is shut, since its other sides are trees.
func sealed_between(a: Vector2, b: Vector2) -> bool:
	if in_forest:
		for w in forest.walls:
			if w.open:
				continue
			var n := maxi(1, int(ceil(a.distance_to(b) / 0.2)))
			for i in range(0, n + 1):
				var p := a.lerp(b, float(i) / n)
				if absf(p.x - w.pos.x) < 0.5 and absf(p.y - w.pos.y) < 0.5:
					return true
			if w.pos.is_equal_approx(Vector2(FOREST.FOREST_X + 28, 15)) and forest_arena(a) != forest_arena(b):
				return true
	elif in_cave and not cave_door_open:
		var dx: float = cave_marks.D.x + 0.5
		return (a.x < dx) != (b.x < dx)
	return false

func forest_arena(p: Vector2) -> bool:
	return p.x > FOREST.FOREST_X + 22.5 and p.y > 15.5 and p.y < 21.0

var rest_said := false # the "cannot rest, a monster is near" toast shows once per stay by the lamp

# the nearest open spot to where Sora stands: first every 0.1 tile in rings up to 1.5 tiles round her (so a small overlap
# moves her a hair, not to the next tile centre), then the old search over tile centres up to 11 tiles away
func find_free_spot() -> Vector2:
	var here := Vector2(player.x, player.z)
	if player_can(here.x, here.y):
		return here
	for r in range(1, 16):
		for a in 16:
			var p := here + Vector2.from_angle(a * TAU / 16.0) * (r * 0.1)
			if player_can(p.x, p.y):
				return p
	var best := here
	var found := false
	for r in range(1, 12):
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := Vector2(round(player.x) + dx, round(player.z) + dz)
				if player_can(c.x, c.y):
					if not found or c.distance_to(here) < best.distance_to(here):
						best = c
						found = true
		if found:
			break
	return best

# every rescue is logged (the user, 2026-10-25: Sora "warps" in fights): autoplay "mash" reads this
var unstick_log: Array = []
func log_unstick(reason: String, from_at: Vector2, to_at: Vector2) -> void:
	unstick_log.append({"t": snappedf(t, 0.01), "from": from_at, "to": to_at, "reason": reason, "skipping": skipping, "dodge": player.dodge > 0.0,
		"atk_cd": snappedf(player.atk_cd, 0.01), "dash": not dash.is_empty(), "x": snappedf(player.x, 0.1)})
	if OS.is_debug_build() and OS.get_environment("UNSTICK_LOG") == "1":
		print("UNSTICK ", unstick_log[unstick_log.size() - 1])

# at once (loads, tests)
func unstick(reason := "stuck") -> void:
	var best := find_free_spot()
	log_unstick(reason, Vector2(player.x, player.z), best)
	player.x = best.x
	player.z = best.y

# in play: the same spot, reached by a 0.12 s glide instead of a one-frame hop
var rescue_glide := {}
func rescue(reason: String) -> void:
	var best := find_free_spot()
	var here := Vector2(player.x, player.z)
	if best.distance_to(here) < 0.01:
		return
	log_unstick(reason, here, best)
	rescue_glide = {"from": here, "to": best, "t": 0.0, "dur": 0.12}

func update_rescue(dt: float) -> void:
	rescue_glide.t += dt
	var k: float = clampf(rescue_glide.t / rescue_glide.dur, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var np: Vector2 = rescue_glide.from.lerp(rescue_glide.to, k)
	player.x = np.x
	player.z = np.y
	player.vx = 0.0
	player.vz = 0.0
	if rescue_glide.t >= rescue_glide.dur:
		rescue_glide = {}

# running + J: the dash slash slides Sora forward in DASH_TIME (combat.gd update_dash); state here
var dash := {}

# Sora keeps a little room from cave walls so her sprite never sinks into one
var has_skip := false   # 물수제비 걸음 (story step 7 ability)
var skipping := false
var skip_grace := 0.0   # a short let-go of Shift or the arrows mid-river does not drop Sora in

# water the water skip can run over: the marsh rivers and ponds, and the deep runs in the grotto
func skip_water(x: float, z: float) -> bool:
	if x >= WORK.WORK_X - 0.5:
		return false
	if x >= VILLAGE.VILLAGE_X - 0.5:
		return village.char_at(x, z) in "~B"
	if x >= UNDER.UNDER_X - 0.5 and x < VILLAGE.VILLAGE_X - 0.5:
		return under.char_at(x, z) == "~"
	if x >= STAIRS.STAIRS_X - 0.5:
		return stairs.char_at(x, z) == "~"
	if x >= CASTLE.CASTLE_X - 0.5:
		return castle.char_at(x, z) == "~"
	if x >= GROTTO.GROTTO_X - 0.5:
		return grotto.char_at(x, z) == "~"
	if x >= HILL.HILL_X - 0.5 and x < GROTTO.GROTTO_X - 0.5:
		return hill.filled and hill.char_at(x, z) == "~"
	if x >= FOREST.FOREST_X - 0.5 and x < GARDEN.GARDEN_X - 0.5:
		return forest.char_at(x, z) == "~"
	if x >= CAVE_X - 0.5 and x < FOREST.FOREST_X - 0.5:
		return cave_char(x, z) == "~"
	return x < CAVE_X - 0.5 and tile_at(x, z) == WATER and x > 1.0 and z > 1.0 and z < N - 2.0 and (x < N - 2.0 or (z > 17.5 and z < 23.5 and x < N - 0.5))

func player_can(x: float, z: float) -> bool:
	if not walkable(x, z):
		return skipping and skip_water(x, z)
	if x >= CAVE_X - 0.5:
		for d in [Vector2(0.35, 0), Vector2(-0.35, 0), Vector2(0, 0.35), Vector2(0, -0.35)]:
			# a skipper's river edge counts as open on land too: Sora who runs along it and lets go of Shift stays where
			# she is instead of being "stuck" within 0.35 of the water (GPT lap 6, castle hall corner)
			if not walkable(x + d.x, z + d.y) and not ((skipping or has_skip) and skip_water(x + d.x, z + d.y)):
				return false
	return true

func make_tex(w: int, h: int, draw: Callable) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	draw.call(img)
	return ImageTexture.create_from_image(img)

func px(img: Image, x: float, y: float, w: float, h: float, c: Color) -> void:
	var x0 := int(round(x))
	var y0 := int(round(y))
	for yy in range(y0, y0 + int(round(h))):
		for xx in range(x0, x0 + int(round(w))):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				img.set_pixel(xx, yy, c)

func mat_color(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func glow_mat(c: Color, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

# ---------------------------------------------------------------- setup
func _exit_tree() -> void:
	music.shutdown()

func _ready() -> void:
	music.setup()
	if "--pseudo" in OS.get_cmdline_user_args():
		TranslationServer.pseudolocalization_enabled = true # shows which text goes through the translation table
	get_viewport().size_changed.connect(func(): if ui.has("story_cap"): fit_story())
	rng.seed = 7
	if not Array(OS.get_cmdline_user_args()).any(func(x): return x.begins_with("--test") or x.begins_with("--scene")):
		menus.load_settings() # tests and screenshots always run with the default settings
	music.apply_buses_now()
	# Pretendard ships as unicode-range pieces; chain them as fallbacks so web builds (no system fonts) get Hangul
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Pretendard", "Malgun Gothic", "Noto Sans KR", "Apple SD Gothic Neo", "sans-serif"])
	var pieces: Array[Font] = []
	for f in ResourceLoader.list_directory("res://fonts/pretendard"):
		if f.ends_with(".woff2"):
			pieces.append(load("res://fonts/pretendard/" + f))
	if pieces.is_empty():
		ui_font = sys
	else:
		ui_font = pieces[0]
		var rest: Array[Font] = pieces.slice(1)
		rest.append(sys)
		ui_font.fallbacks = rest
	title_font = SystemFont.new()
	title_font.font_names = PackedStringArray(["Cinzel", "Georgia", "Times New Roman", "serif"])
	title_font.fallbacks = [ui_font]
	title_font.font_weight = 700
	touch_ui = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")
	touch_ui = touch_ui or OS.get_environment("TOUCH_UI") == "1"
	var short_side := 400.0 # the screen's short side in CSS px, a phone's unless the browser says otherwise
	if OS.has_feature("web"):
		# iPadOS Safari calls itself a Mac: a touch screen with a coarse pointer is a phone or a tablet all the same
		if bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 1 && matchMedia('(pointer: coarse)').matches", true)):
			touch_ui = true
		short_side = float(JavaScriptBridge.eval("Math.min(screen.width, screen.height)", true))
	if touch_ui: # a smaller canvas than 1600x900, so keys and text come out bigger: 540 tall on phones, 640 on tablets
		# (the user found 640 too small on an iPhone, 2026-10-24)
		var ch := 640 if short_side >= 600.0 else 540
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		get_tree().root.content_scale_size = Vector2i(ch * 16 / 9, ch)
	world_build.chest_textures()
	world_build.build_environment()
	world_build.build_map()
	world_build.build_terrain()
	world_build.build_vegetation()
	world_build.build_props()
	world_build.build_lights()
	world_build.build_cottage()
	dressing.marsh_backdrop()
	story.darken_first_lamp()
	cave.build_cave()
	cave.build_shrine()
	cave.spawn_crystals()
	cave.build_crystal_chest()
	village.build(self)
	forest.build(self)
	garden.build(self)
	lake.build(self)
	hill.build(self)
	grotto.build(self)
	lake_zone.grotto_steps()
	cloud.build(self)
	cloud.build_updraft(self, hill.marks.U)
	castle.build(self)
	stairs.build(self)
	minigames.build_trial()
	waystones.build_ways()
	folk.build_house_room()
	minigames.build_race()
	hill_zone.build_windrun()
	sora.build_player()
	for i in 9:
		spawn_enemy(Vector2(-1, -1), i >= 6) # the last three are brick archers
	enemies[0].x = 12.0
	enemies[0].z = 24.0
	enemies[1].x = 30.0
	enemies[1].z = 22.0
	world_build.build_chests()
	marsh.build(self)
	hud_build.village_sign()
	monsters.spawn_boss()
	effects.build_particles()
	hud_build.build_hud()
	for l in [ui.story_text, ui.story_who, ui.journal_text, ui.journal_text2, ui.ways_text]:
		menus.scale_text(l)
	hud_build.build_mate_hud(ui.root)
	under.build(self)
	castle_zone.build_under_stair()
	workshop_zone.build()
	market.build_magpie()
	apply_settings()
	daynight.update_daylight(0.0)
	var targs := OS.get_cmdline_user_args()
	if targs.is_empty():
		var stage := stage_from_url()
		if STAGES.has(stage): # a stage to play again, in its own save so the real one is left as it was
			SAVE_PATH = "user://stage_%s.json" % stage
			var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
			f.store_string(JSON.stringify(STAGES[stage]))
			f.close()
		load_game()
	else: # tests and shots use their own save file and always start fresh
		SAVE_PATH = "user://test_save.json"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	scenes.apply_test_args(targs)

# ---- play a story stage again (the owner, 2026-10-27: "노을이 마을에서 도망갈 때, 게임에서 그 단계"): open the page with
# ?stage=NAME. It starts from a fixed state just before that stage, saved in user://stage_NAME.json, so the real save
# stays untouched; open the page without ?stage to go back to it.
const STAGES := {
	# the lantern night: after Mulgyeol's errand, at night in the village Noeul puts the lamps out and runs; Sora chases
	"noeul": {"story": 8, "in_village": true, "x": 576.0, "z": 12.0, "hour": 21.0, "day": 3, "lv": 8, "max_hp": 184, "atk": 18,
		"gold": 300, "pots": 3, "errand": 3, "kid_q": 3, "doran_q": 3, "mul_q": 3, "night_q": 0, "has_skip": true, "has_key": true,
		"door_open": true, "saw_painting": true, "cave_exit_seen": true, "quest": "마을 사람들과 등불 밤을 보내자"},
}

func stage_from_url() -> String:
	if not OS.has_feature("web"):
		return ""
	var v = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('stage') || ''", true)
	return str(v) if v != null else ""

# ---------------------------------------------------------------- test scenes
# Fixed starting states for screenshots and checks, picked with `-- --scene=NAME`.
# Extra flags: --hour=H --day=D --shot=PATH (save a PNG after --wait seconds, default 4, then quit).

# a bridge of toy bricks: a deck of staggered 2x2-stud bricks in red, yellow, blue and green,
# and a low brick wall along each side with gaps every third brick
var lego_mats: Array = []
var stud_mesh: CylinderMesh

# ---------------------------------------------------------------- lights
var shop_pos := Vector3.ZERO  # in front of the cottage door
var shop_open := false
var lanterns: Array = []     # OmniLight3D, brighter after dusk
var sunbeams: Array = []     # additive light shafts, strongest at golden hour

# Signs in the world are pictures, not words: Korean drawn by Label3D in the world broke up at a distance (the user,
# 2026-10-23: "한글 다 깨진다. 이런건 다 아이콘으로 해"). A round paper plaque with a brown line picture.
var sign_cache := {}

# ---------------------------------------------------------------- shop
const SHOP := [
	{"name": "회복약", "desc": "체력 45 회복", "price": 30},
	{"name": "기세 사탕", "desc": "기세 +50", "price": 20},
	{"name": "벼린 칼날", "desc": "공격력 +3", "price": 80},
	{"name": "튼튼한 갑옷", "desc": "최대 체력 +15", "price": 80},
]

# the blade and the armour cost 40 more each time one is bought (80, 120, 160, ...)
var shop_bought := [0, 0, 0, 0]

var hero_ghost: Sprite3D

# ---- standing still: Sora turns to the viewer, breathes, and now and then does something of her own
# (front-facing 4-frame loops from the Space Oddity sprites, 192x256 cells, art/sora/idle/<name>.png)
var walk_px := 0.0
var walk_off := Vector2.ZERO
var idle_t := 0.0
var idle_name := ""
var idle_k := 0.0
var idle_left := 0.0
var idle_tex := {}
var last_input_t := 0.0  # rest actions start only after 10 s without a key or click

# ---- 달빛 시련: the old moonkeepers' sparring stones east of the wind hills' gorge, open once the brick hawk is
# down (moved from the village on 2026-10-23: a monster ring had no place among the lanterns). Walking 9 tiles
# from the stones ends a run; after the first clear its foes give no gold or XP.
# E at the moon stone starts five waves; the next comes 2.5 s after the last one falls. Fainting or leaving
# the village ends the run. The first clear gives max HP +20, attack +3 and 300 gold; later clears 80 gold.
var trial_wave := 0          # 0 idle, 1..5 the wave being fought
var trial_wait := 0.0        # pause before the next wave
var trial_start := 0.0
var trial_best := 0.0        # best clear in seconds (0: never cleared)
var trial_stone: Node3D

# ---- the pinwheel race on the wind hills (west of the gorge): E at the race post starts a 25 s run;
# pass through all five pinwheels, in any order. The first win gives the wind shoes (running 6.2 -> 7.0
# tiles/s); later wins 30 gold. The best time shows in the journal.
const RACE_POST := Vector2(2, 21)  # hill tiles
const RACE_WHEELS := [Vector2(9, 4), Vector2(17, 2), Vector2(12, 9), Vector2(7, 15), Vector2(16, 21)]
var race_on := false
var race_left := 0.0
var race_got: Array = []
var race_nodes: Array = []
var race_best := 0.0
var race_quest := ""          # the quest line to put back after the race
var has_shoes := false

# ---- fishing at the south lake's east shore (after the sluice is unwound): E casts; after 2 - 5 s a fish
# bites ("!" and a plop) and E within 0.7 s lands it. Five kinds; landing all five gets 100 gold and max HP +10.
const FISH := [["붕어", 40], ["메기", 25], ["무지개송어", 18], ["벽돌 물고기", 12], ["황금 잉어", 5]] # name, weight
var fish_state := ""        # "", "wait" (line in the water), "bite"
var fish_t := 0.0
var fish_kinds := [false, false, false, false, false]
var bobber: Node3D

var fish_at := Vector2.ZERO # the spot she fishes from: the lake's east shore or the end of the village pier

# ---- brick bats in the cave and the castle library: they flutter in a loose ring about 2.5 tiles from Sora,
# then a 0.4 s shiver ("!") and a swoop straight through where she stood (8 tiles/s for 0.5 s)
const BAT_SPOTS := [Vector2(126, 3), Vector2(122, 12), Vector2(126, 14), Vector2(105, 12), Vector2(441, 3), Vector2(447, 5)]

# ---- inside the village houses: E (or the old Space) at a door goes in. One small room (x >= HOUSE_X) is dressed for whichever
# house it is; each of the five houses has a cupboard to look in once. The last house keeps an old picture of the moonkeepers with Hangyeol.
const HOUSE_X := 480
var in_house := -1
var house_seen := [false, false, false, false, false]
var house_wall_mat: StandardMaterial3D
var cupboard: Node3D

# ---- villagers sleep at home at night (the user asked, 2026-10-24): after dark Doran, Kongal, Mulgyeol (while he still
# lives in the village) and Kongal's kid goblin walk to the nearest house door and go in; in the morning they come out
# and walk back. Simji, the lamplighter, stays on the square, and on a festival night (full moon, Simji's letter) all
# stay out. In his house a sleeper lies in bed and E beside him wakes him for the same talk and errands as by day.
# v0.0.35: the six working villagers sleep too. A house sleeps three (HOUSE_SPOTS); each sleeper takes the nearest
# house with a spot left, in SLEEP_IDS order (Darae and her grandson Tori come before the rest, so they share).
const SLEEP_IDS := ["doran", "kongal", "mulgyeol", "darae", "tori", "dusol", "chadol", "saecham", "yeoul"]
const HOUSE_SPOTS := [Vector2(1.8, 1.6), Vector2(1.8, 4.3), Vector2(6.3, 4.5)] # room tiles: the bed, two bedrolls
var folk_bed_at := {}       # id -> [house, spot], filled on first use
var folk_rocks := {}        # id (or "spot1", "spot2" for the bedrolls) -> its entry in rocks
var folk_state := {}        # id -> "out", "going", "in", "coming"
var folk_walk_t := {}       # id -> 0..1 along the way between his spot and his door
var sleeper_nodes := {}     # id -> the bed in the room
var door_z := {}            # id -> the z over his door while he sleeps

var sleep_off := false      # the autoplay tests keep the villagers out (all but folk_sleep)

# ---- day routines (the user, 2026-10-24: the village still felt empty): by day each villager walks a short loop
# between two or three spots tied to his life, waiting 6 - 14 s at each. Points are village tiles, true = a stop;
# the first is his own spot and the loop closes back to it. Straight legs along walkable tiles (autoplay folk_routine).
const FOLK_ROUTES := {
	"doran": [[Vector2(14, 3), true], [Vector2(14, 4), false], [Vector2(21, 4), true], [Vector2(14, 4), false],
		[Vector2(7, 4), true], [Vector2(14, 4), false]], # the post along the north houses
	"kongal": [[Vector2(10, 15), true], [Vector2(12, 14), false], [Vector2(13, 12), true], [Vector2(12, 14), false]], # the square
	"mulgyeol": [[Vector2(28, 21), true], [Vector2(29, 24), true]], # a look at the pond
	"dusol": [[Vector2(43, 11), true], [Vector2(42, 9), true]], # woodpile and the forest road's edge
	"chadol": [[Vector2(45, 20), true], [Vector2(46, 19), false], [Vector2(46, 13), false], [Vector2(45, 12), false],
		[Vector2(45, 9), false], [Vector2(44, 8), true], [Vector2(45, 9), false], [Vector2(45, 12), false],
		[Vector2(46, 13), false], [Vector2(46, 19), false]], # ore cart and the market, crossing the east road off the gate
	"saecham": [[Vector2(38, 21), true], [Vector2(37, 23), false], [Vector2(35, 24), true], [Vector2(37, 23), false],
		[Vector2(38, 21), true], [Vector2(33, 19), false], [Vector2(33, 9), false], [Vector2(33, 8), true],
		[Vector2(33, 9), false], [Vector2(33, 19), false]], # field, pond edge, field, market
	"yeoul": [[Vector2(32, 24), true], [Vector2(32, 23), false], [Vector2(25, 23), false], [Vector2(24, 28), true],
		[Vector2(25, 23), false], [Vector2(32, 23), false]], # pond edge and the pier's foot
	"darae": [[Vector2(36, 7), true], [Vector2(36, 9), false], [Vector2(25, 9), false], [Vector2(25, 22), false],
		[Vector2(16, 22), false], [Vector2(16, 28), false], [Vector2(7, 28), true], [Vector2(16, 28), false],
		[Vector2(16, 22), false], [Vector2(25, 22), false], [Vector2(25, 9), false], [Vector2(36, 9), false]], # stall and the inn door
	"tori": [[Vector2(41, 7), true], [Vector2(39, 9), false], [Vector2(20, 9), false], [Vector2(19, 8), true],
		[Vector2(20, 9), false], [Vector2(25, 9), false], [Vector2(25, 22), false], [Vector2(31, 22), true],
		[Vector2(33, 19), false], [Vector2(33, 9), false], [Vector2(39, 9), false]], # market, square, the field
}
var routine_off := false    # the autoplay tests keep everyone on his spot (all but folk_routine)
var folk_route := {}        # id -> {"i": point he heads to or stands on, "wait": s left there, "pos": Vector2, "back": bool, "dir": int}

# the way from his spot to his door along open village tiles (a breadth-first search, found once): they used to
# walk the straight line through houses and fences (GPT playtests 2 -> 9)
var folk_ways := {}

const HOUSE_EXIT := Vector2(HOUSE_X + 4, 6) # the doorway inside a house: walking onto it or E beside it goes out

# ---- feats: six long goals listed in the journal; each gives 50 gold the moment it is reached
const FEATS := [["섬광 피하기 10번", "dodges", 10], ["섬광 막기 10번", "guards", 10], ["치명타 50번", "crits", 50],
	["괴물 100마리 물리치기", "kills", 100], ["보스 10마리 모두 물리치기", "bosses", 10], ["레벨 15", "level", 15]]
var stats := {"dodges": 0, "guards": 0, "crits": 0, "kills": 0}
var play_secs := 0.0         # time spent playing (not on the title, not in shops or talk scenes)

var feats_done := [false, false, false, false, false, false]
var feat_t := 0.0

# ---- Doran's three letters (after the island is home again): to Bori at the cottage, to Simji on the square,
# and to the mailbox of Mulgyeol's island hut. Bringing word back gets 150 gold and max HP +10.
var mail_q := 0             # 0 not asked, 1 carrying letters, 2 done
var mail_got := [false, false, false] # Bori, Simji, the island hut

# ---- the lantern festival: once Simji has his letter, on full-moon nights (moon at least 95% full) sky lanterns
# drift up over the village; Simji hands out festival rice cakes once (three potions)
var fest_gift := false
var fest_seen := false
var fest_t := 0.0

# ---- a new round (새 바퀴) after the ending: E twice at the garden's heart starts the story over, keeping level,
# attack, max HP, gold, potions, keepsakes, the woken skill, feats and records. Monsters then take
# 1/(1 + 0.5 x round) of the damage and deal (1 + 0.5 x round) times as much.
var ng := 0                 # how many rounds were finished before this one
var ng_armed := 0.0         # seconds left to confirm with a second E

# ---- moon waystones: a standing stone in each hub. E at one opens a list of the stones already reached;
# a number key (1 - 6) travels there. Esc or E closes the list.
const WAY_NAMES := ["늪 오두막", "마을 광장", "남쪽 호수 부두", "굳은 숲 입구", "바람 언덕", "달지기 성 문", "정원 앞 야영터", "달지기 작업장"]
var way_open := false
var way_nodes: Array = []

# ---- villager heights (the user, 2026-10-25: "아이들이 노을에 비해서 조금 커보이는데?"). The villagers are chibi
# drawings with big heads, so at Noeul's height their heads came out much bigger than his. Heads measured in frame 0
# (top of hair or hat to chin, px of the frame height) and how tall each head stands in the world after the change:
#   Noeul 69/180 at 1.80 = 0.69 | Sora 85/244 at 1.58 = 0.55 | Mulgyeol 57/170 at 1.75 = 0.59 | Simji 55/200 at 2.10 = 0.58
#   Tori 85/170 at 1.35 = 0.68 | Kongal 72/170 at 1.40 = 0.59 | Dusol 79/170 at 1.50 = 0.70 | Yeoul 79/170 at 1.50 = 0.70
#   Chadol 75/170 at 1.55 = 0.68 | Doran 74/170 at 1.55 = 0.67 | Darae 72/170 at 1.60 = 0.68 | Saecham 84/170 at 1.55 = 0.77
#   kid goblin 40/110 at 0.80 = 0.29 (Kongal's ratio 1.40 / 1.75)
# Saecham's head is mostly his wide straw hat; at 1.55 (the grown-ups' floor) it stays a little over Noeul's.
# Feet stay on the ground: the offset is half the frame height in px, only pixel_size changes. Before: 1.75 for all.
const FOLK_HEIGHT := {"tori": 1.35, "kongal": 1.4, "dusol": 1.5, "yeoul": 1.5, "chadol": 1.55, "doran": 1.55,
	"darae": 1.6, "saecham": 1.55, "simji": 2.1, "kid": 0.8}

func folk_height(id: String) -> float:
	return float(FOLK_HEIGHT.get(id, 1.75))

# a villager's balloon just over his head: the sprite stands 1/cos(camera pitch) taller than its height (2.7 at 1.75)
func folk_bubble_y(id: String) -> float:
	return 2.6 if id == "bori" else folk_height(id) / cos(0.78) + 0.23

const CHANGES_PAGE := 100 # lines of 바뀐 것 shown before the 더 읽기 button
const CHANGES := [
	"개발 상황: 놀 수 있는 분량 약 322분 / 목표 300분 (107%)",
	"",
	"2026-10-27 저녁",
	"· v0.1.16: 미니맵 테를 시간 한량(Time Oddity)의 '밤하늘 유리' 다이얼처럼 바꿨다(시안 3번). 28톱니 황동 테가 별가루가 든 짙은 남색 유리 테가 되었고, 금빛 모서리 두 겹과 점선 길을 둘렀다. 그 길 위 여덟 방위에 금빛 별 일곱과 N 단추가 서서 여덟 달을 뜻하고, 카메라를 돌리면 함께 돈다.",
	"· v0.1.15: 호수 섬 남쪽 물가의 내려가는 돌계단을 오른쪽으로 2칸 옮겼다. 작은 집 쪽에 너무 붙어 보였다.",
	"· v0.1.14: 예전 바뀐 것 줄에 남아 있던 '왕관으로 감다, 풀다, 비추다'를 '팔찌로'로 고쳤다. 감고 풀고 비추는 것은 v0.0.77부터 팔찌다.",
	"",
	"2026-10-27 낮",
	"· v0.1.13: 설정의 '정보' 탭에 적힌 만든 사람을 '우주한량'에서 '우주 한량, 우주 토끼, 구스테 단톡방 사람들'로 바꿨다.",
	"· v0.1.12: '다 같이 감기' 그림(14)을 그림 대신 게임 속 큰 태엽 방 장면으로 바꿨다. 그림 모델이 아홉 번을 그려도 여덟 사람이 바퀴를 같은 방향으로 미는 모습을 끝내 맞추지 못해서, 여덟이 저마다 바퀴살에 선 실제 장면을 화면 표시 없이 찍었다.",
	"· v0.1.11: 설정의 '바뀐 것' 맨 위 개발 상황 아래에 '지금까지 고친 것: 모두 N가지'가 뜬다. 한 판에 여러 가지를 고쳤으면 하나하나 센다.",
	"· v0.1.10: 기타 소리를 새로 만들었다. 잡음으로 줄을 흉내 내던 거친 소리(높은 음은 음정이 2%쯤 높았다)를 부드러운 나일론 줄 기타 소리로 바꿨다. 기타가 든 마을 곡 5곡과 끝맺음 곡 2곡을 다시 만들었다. 끝맺음 곡 ending, ending_4, ending_5는 지워서 끝맺음 곡은 2곡이다.",
	"· v0.1.9: 넓은 화면(가로 1,180px 이상)에서 왼쪽 위 소라 얼굴 원을 오른쪽 미니맵과 같은 지름 186px로 키웠다(124 → 186px). 막대, 동료 칸, 해와 달 시계, 지역 이름도 함께 옮겼다. 좁은 창과 휴대폰은 예전 크기 그대로다.",
	"· v0.1.8: 괴물이 더 영리하게 싸운다(GPT와 의논한 여섯 가지). 고블린 무리는 한 마리만 덤비고 둘은 옆으로 돌아 들어오며, 0.55초 예고 뒤 앞으로 뛰어들며 베기도 한다. 궁수는 소라가 2칸 안에 오면 뒤로 물러나 조준하고, 마지막 0.25초는 조준선이 하얗게 굳는다. 늑대는 한 마리씩 번갈아 반대편에서 달려들고, 박쥐는 처음 급강하가 빗나가면 한 번 더 내려온다. 고슴도치는 굴러와 멈춘 뒤 0.6초 뒤 가시를 터뜨린다. 모든 공격은 붉은 길이나 부채꼴로 미리 보인다.",
	"· v0.1.7: 동료 물결과 노을이 덜 싸운다. 공격력이 소라의 60 → 70%에서 35 → 40%로 줄고, 치는 간격은 물결 1.0 → 1.6초, 노을 1.4 → 2.0초로 길어졌다. 싸움은 소라가 하고 동료는 돕는다.",
	"· v0.1.6: 괴물이 세졌다. 괴물 레벨이 '소라 레벨 절반의 60% + 지역 단계'에서 '소라 레벨의 절반 + 지역 단계'로 오르고, 한 대의 피해는 괴물 레벨당 +1 → +2, 체력은 레벨당 약 40% 더 늘었다(고블린 10 → 14).",
	"· v0.1.5: 첫 화면 오른쪽 위에 배경 음악을 켜고 끄는 단추(44px)를 두었다. 누르거나 B를 눌러도 게임이 시작되지 않고 음악만 켜지고 꺼진다. 고른 값은 저장된다.",
	"· v0.1.4: 첫 화면의 부제와 '아무 키나 눌러' 글을 주아(Jua, 무료 OFL 글꼴, 한글 2,350자만 담아 351KB)로 바꿨다(시안 3번). 둥근 글씨에 로고와 같은 남색 테두리를 둘렀고, 부제는 20 → 29px 크림색, 아래 글은 14 → 20px 금색이다. 그림 로고는 그대로다.",
	"· v0.1.3: 미니맵에 금빛 '!' 표시가 뜬다. 지금 할 일이 가리키는 곳(사람, 물건, 길)에 깜빡이는 금 마름모가 서고, 멀면 지도 테두리에 붙어 방향을 알려 준다. 이야기 상자가 열려 있을 때는 숨는다. 숲, 바람 언덕, 달의 계단, 정원 마당, 호수 둑의 들판 괴물은 그 지역에 다시 들어오면 제자리에 돌아와 있다. 우두머리, 이야기 싸움, 매복, 할 일 괴물은 다시 나오지 않는다.",
	"· v0.1.2: 마을, 호수, 숲, 달의 계단, 정원 마당의 바닥을 꾸몄다. 땅 윗면에 늪처럼 얼룩 무늬를 넣고, 빈 칸에만 풀을 심었다. 마을은 잔디와 꽃밭(풀 981포기), 호수는 물가 풀과 청록 수초(1,133포기), 숲은 어두운 풀과 고사리와 버섯(805포기)이다. 길, 문, 사람 자리, 소품 곁 1칸은 비워 두었다. 휴대폰에서는 풀이 절반이다.",
	"· v0.1.1: GPT 시험 놀이꾼이 찾은 버그 다섯을 고쳤다. 우두머리들의 공격 간격과 맞은 빛이 한 틀에 두 번 줄어 적힌 값의 절반이던 것, 풍차 수문지기 곁 고블린이 쓰러질 때마다 둘씩 쌓이던 것(3, 5, 7마리), 정원 마지막 싸움에서 쓰러진 뒤 충격 고리와 채운 왕관 칸이 남던 것, 거북 재도전에서 물결이 둘 보이던 것, 가끔 실패하던 낚시 시험이다.",
	"",
	"2026-10-27 새벽",
	"· v0.1.0: 전투가 이스처럼 손에 붙는다(GPT와 의논한 다섯 안 가운데 1안과 2안). 딸깍 이어베기: 칼질이 끝나기 0.18초 전 안에 누른 J를 기억했다가 끝나자마자 이어 벤다. 맞힌 칼질은 굳는 틈이 30% 짧아지고, 0.5초 안에 이어 맞히면 '딸깍' 소리와 금빛 불티, 기세 +3. 맞힌 뒤 옆으로 방향키를 누르고 베면 그쪽으로 옆걸음 베기를 한다. 이음새 톡!: 벽돌 고블린이 헛치거나 섬광 피하기·섬광 막기를 당하면 1.4초 동안 관절의 이음새가 드러난다('틈!'). 그때 베면 1.5배로 들어가고 핀이 하나씩 빠지며, 세 번째 핀이 빠지면 1.6초 동안 풀려 서 있고 기세 +10. 왼쪽 위 소라 얼굴 원을 지름 100 → 124px로 키우고 어깨선까지 보이는 그림으로 바꿨다(막대는 12px 오른쪽으로). 주소 뒤에 ?stage=noeul을 붙여 열면 등불의 밤(노을이 등불을 끄고 달아나는 장면) 바로 앞에서 따로 된 연습 저장으로 시작한다. 진짜 저장은 그대로다.",
	"· v0.0.106: '다 같이 감기' 그림(14)을 다시 그렸다. 바퀴살이 물결, 소라, 벽돌 일꾼, 도란의 몸을 꿰뚫고 지나갔는데, 이제 위에서 내려다보는 그림에서 여덟이 모두 바퀴살 끝 T자 손잡이 곁에 서서 같은 쪽으로 민다.",
	"· v0.0.105: 늪(마을 밖)의 나무를 벨 수 있다. 칼로 세 번 치면 나무가 소라 반대쪽으로 쓰러지고, 1초 뒤 줄어들며 사라지고, 그 자리로 지나갈 수 있다. 게임을 다시 불러오면 나무가 다시 자라 있다.",
	"· v0.0.104: 미니맵 테를 바꿨다(시안 4번 바탕의 1안). 금빛 가는 테가 28개 톱니의 황동 태엽 테와 가는 금 안쪽 테가 되었다. N은 톱니판 위에 있고 실제 북쪽을 바라보도록 돌아, 보통 시점에서 45° 기운다. 동·남·서에는 마름모 징이 박힌다. 테가 지도 둘레를 덮어 지도 원은 반지름 92 → 73px로 조금 작아졌다.",
	"· v0.0.103: 등불을 끄고 켤 수 있다. 등불 곁에서 E를 누르면 꺼지고, 다시 누르면 켜진다. 끈 등불은 빛이 없고 그 곁에서 쉬어도 달빛이 차지 않는다. 이야기 때문에 꺼져 있는 등불(첫 등불, 마을 심부름 등불, 노을의 기억 등불, 정원 기둥)은 건드리지 않는다.",
	"· v0.0.102: 첫 화면의 부제와 '아무 키나 눌러 시작' 글이 본명조(Noto Serif KR, 무료 OFL 글꼴, 쓰는 글자만 담아 45KB)로 바뀌었다(시안 1번). 그림 로고는 그대로다.",
	"· v0.0.101: 화면 아래 단추 8개를 '달돌 동전'으로 바꿨다(시안 4번). 왼쪽 넷(도움말, 효과음, 일지, 설정)은 금 톱니 테에 오팔빛 흰 면, 오른쪽 넷(회오리, 불씨탄, 빛파동, 회복약)은 같은 테에 어두운 보석 알을 박았다. 회복약은 초록 하트 대신 병 그림이다.",
	"· v0.0.100: 괴물이 지역을 따라 세진다(이스 시리즈처럼). 괴물 단계가 '소라 레벨의 절반'이던 것을 '소라 레벨의 30% + 지역 단계'로 바꿨다. 지역 단계는 이야기 길을 따라 늪 0, 동굴 1, 마을 2, 호수 3, 숲 4, 바람 언덕과 물빛 동굴 5, 구름 6, 성 7, 계단과 지하 등불 회랑 8, 정원과 깊은 공방 9다. 같은 레벨이면 지난 지역은 쉬워지고 다음 지역은 더 세다.",
	"· v0.0.99: 동굴에서 늪으로 나온 자리에 굴로 내려가는 돌계단이 남는다(예전에는 '모래에 묻혀 닫혔다'며 사라졌다). 밟으면 동굴 출구 쪽으로 다시 들어가고, 미니맵에도 계단 표시가 뜬다. 처음 나갈 때는 동굴에서 할 일(수레두더지, 벽 그림 보기, 세 돌단에서 기술 깨우기)을 다 해야 나갈 수 있고, 남은 일이 있으면 출구에서 '아직 나갈 수 없다. 동굴에서 남은 일: …'이라고 알려 준다.",
	"· v0.0.98: 굴파기 수레두더지가 세졌다. 체력 650 → 1100, 돌진 속도 9 → 11칸/초, 돌진 피해 25 → 34, 흙 솟기 고리 1 → 3개(반피 아래 2 → 5개, 소라 둘레에 퍼진다), 흙 피해 18 → 24, 다음 공격까지 1.4 → 1.1초(반피 아래 0.8초). 반피 아래에서는 벽에 부딪힌 뒤 한 번 더 돌진하고, 땅속으로 숨었다가 소라 발밑에서 튀어나온다(피해 30, 빨간 고리로 미리 보인다).",
	"· v0.0.97: 콩알의 대화 그림을 소라의 82% 크기로 줄였다. 같은 크기라 콩알이 소라의 언니처럼 보였다.",
	"· v0.0.96: 심지 할아버지가 마을 광장 한가운데에서 서쪽 문 바로 안쪽(문에서 4칸)으로 옮겼다. 마을에 들어서자마자 보인다. 심지에게 말 거는 자리, 등불 축제, 곁의 달빛 길돌도 함께 옮겨졌다.",
	"· v0.0.95: 설정 창의 Settings 쪽에는 효과음과 언어만 남겼다. 화면 흔들림, 미니어처 흐림, 피해 숫자 옵션은 지우고 늘 켜 둔다(예전에 꺼 둔 값도 다시 켜진다). 그 아래 '지금 음악' 칸에 나오는 곡 이름이 '♪ 마을 3/5 (village_3)'처럼 보이고, 마우스로 긁어 복사할 수 있다.",
	"· v0.0.94: 배경 음악이 9곡 → 45곡이 되었다. 아홉 자리(늪과 호수, 바람 부는 들, 마을, 밤, 동굴과 성, 우두머리, 마지막 싸움, 제목, 끝맺음)마다 5곡이고, 한 곡을 100초쯤 들으면 그 자리의 다음 곡으로 넘어간다. 마을 5곡은 모두 새로 지은 '등불 마을' 곡이다(오르골 소리가 등불처럼 반짝이고 셋은 3박자). 옛 마을 곡은 지웠다. 밤에도 들판은 들판 곡, 마을은 마을 곡이 나오고, 밤 곡은 밤에 밖에서 쉴 때만 나온다. 곡은 모노 48kbps라 45곡이 12MB다.",
	"· v0.0.93: 왼쪽 위 막대 이름과 숫자, 달빛 글자를 14 → 15px로 키웠다.",
	"· v0.0.92: 늪 아래 동굴의 벽화 장면을 둘로 나눴다. 먼저 벽화만 크게 그린 새 그림(여덟 달과 손을 모은 달지기 여덟)이 나오고, 노을이 '그 팔찌, 네 것이 아니야' 하고 나타날 때 노을 그림으로 바뀐다. 장면을 본 뒤 벽화 앞에서 E를 누르면 벽화 그림만 다시 볼 수 있다.",
	"· v0.0.91: 열린 상자 그림을 다시 그렸다(시안 5번). 뚜껑이 상자 위에 떠 있던 것을, 금 경첩 둘로 붙은 채 뒤로 넘어간 뚜껑, 어두운 빈 속, 늘어진 걸쇠로 바꿨다.",
	"· v0.0.90: 달빛 길돌 창에서 아직 못 찾은 길돌이 '? ? ?'로 보여 글자가 깨진 것 같았다. 이제 '(아직 찾지 못한 길돌)'로 쓴다. 설정의 바뀐 것 목록은 항목마다 빈 줄을 하나씩 두어 읽기 쉽게 했다.",
	"· v0.0.89: 엔딩 다시 보기. 엔딩을 본 뒤에는 일지(Q) 오른쪽 아래의 '엔딩 다시 보기' 단추로 축제 그림과 엔딩 대사를 언제든 다시 본다. 보상은 다시 주지 않는다.",
	"· v0.0.88: 이야기 그림 두 장을 다시 그렸다. '다 같이 감기'(14)는 물결이 손잡이 밖에 떨어져 서 있고 앞 손잡이 하나가 비어 있었는데, 이제 바퀴살 8개에 소라, 노을, 물결, 심지, 콩알, 꼬마 고블린, 도란, 벽돌 일꾼이 하나씩 잡는다. 그 방에 없는 보리 할머니 대신 심지가 선다. 서랍장의 옛 그림(15)은 맨 앞 달지기의 몸을 나무 손잡이가 꿰뚫고 있었는데, 이제 바퀴살 8개가 모두 손잡이 끝까지 이어지고 나무가 몸을 지나지 않는다.",
	"· v0.0.87: 소리가 난다. 효과음과 배경 음악이 웹(크롬, 엣지)에서 전혀 들리지 않았다. 효과음 통로와 음악 통로를 게임이 켜진 뒤 코드로 만들었는데, 웹의 소리 재생 방식은 그렇게 뒤늦게 만든 통로를 스피커에 잇지 않는다. 두 통로를 설정 파일(default_bus_layout.tres)에 미리 두어, 스피커 앞에서 잰 소리가 0 → 0.23이 되었다.",
	"· v0.0.86: 벽돌 거북을 물리친 뒤 물결의 섬에서 돌아오는 길을 알려 준다. 호수 물은 물수제비 걸음으로 건널 수 없는데 그 말이 없어 섬 물가에서 막혔다. 이제 섬 북쪽 나루 위에 금빛 '!'가 뜨고('동쪽 문' 할 일이 있는 동안), 물가로 걸어가면 '섬 북쪽 나루에서 E를 누르면 물결이 배를 저어 준다'고 한 번 알려 준다. 보리 할머니가 없는 자리에서 할머니 얼굴로 말하던 세 줄을 고쳤다. 큰 태엽 방의 두 줄은 물결과 심지가 말하고(소라가 '늪의 보리 할머니께도 알려 드려야지' 한 줄을 더한다), 정원 마지막 싸움의 한 줄은 소라가 떠올리는 할머니의 말(얼굴 없는 해설)이 되었다.",
	"· v0.0.85: 왼쪽 위 글자를 키웠다. 막대 이름(체력, 기세, 기력, 경험, 달빛)과 숫자 11·12 → 14px, 왼쪽 지역 이름 14 → 17px과 그 아래 줄 11 → 14px, 동료 이름 13 → 15px과 상태 11 → 13px.",
	"· v0.0.84: 이야기 삽화 14장(01 깨어남 → 14 다 같이 감기)을 다시 그렸다. 장마다 2.5 → 5등신으로 제각각이던 아이들(소라, 노을, 콩알)을 3.5등신으로 맞췄고, 노을은 소라보다 10% 크고 콩알은 10% 작다. 소라는 원화의 옷 그대로다. 06 동굴 장면에서 노을은 이제 왕관이 아니라 소라의 팔찌로 손을 뻗는다.",
	"· v0.0.83: 이야기 상자의 글이 가운데 정렬된다. 얼굴 그림이 있던 줄 뒤의 해설 줄은 글 칸이 좁은 채 남아 왼쪽으로 쏠렸는데, 이제 줄마다 칸 너비를 다시 잡는다. 보리 할머니의 두 대사와 한결의 넷째 일기에서 '왕관을 썼다고 혼자 감는 건 아니란다'를 '팔찌를 찼다고 혼자 감는…'으로 고쳤다(감는 것은 팔찌라서).",
	"",
	"2026-10-26 저녁",
	"· v0.0.82: 벽돌 매를 쓰러뜨린 뒤 1초 안에 매 둘레에 서 있으면 등장 장면과 새 매가 다시 나오던 것을 고쳤다(노을의 숲 결투와 벽돌 한결도 같은 틈을 막았다). 구름 첫 섬 남쪽에서 떨어지면 '섬 남쪽 끝에서 E로 팔찌를 비추면 3초 동안 길이 보인다'고 알려 주고, 구름 조각을 찾기 전까지 그 자리에 금빛 '!'가 뜬다.",
	"· v0.0.81: 할 일 줄이나 그 아래 곁 단계 줄이 부르는 마을 사람(물결, 도란, 콩알, 두솔, 차돌, 새참, 여울, 다래, 토리) 머리 위에 금빛 '!'가 뜬다. 늪에서는 보리 할머니를 찾아갈 때 오두막 위에 뜬다. 30칸 안에 있을 때만, 이야기 창이 열린 동안은 숨는다.",
	"· v0.0.80: 달빛 눈금이 2배 빨리 찬다. 밤에 켜진 등불 곁에서 쉬면 6 → 3초에 1칸, 반딧불 병 곁은 12 → 6초에 1칸, 달꽃 차를 마시면 그 0.6배(2초, 4초).",
	"· v0.0.79: 화면 위 할 일 줄이 17 → 20px, 그 아래 곁 단계 줄이 14 → 17px로 커지고 더 밝아졌다(창 높이가 700px보다 작으면 예전 크기). 상자를 열면 뚜껑이 젖혀지고 속이 빈 그림으로 바뀐다(예전에는 같은 그림이 조금 어두워질 뿐이었다). 들판 상자, 동굴 열쇠 상자, 성 아래 상자 모두.",
	"· v0.0.78: 늪 둘레가 비어 보이지 않는다. 늪 가장자리 물 너머가 보랏빛 허공이었는데, 이제 네 둘레에 10칸 너비의 먼 둑(늪과 같은 얼룩 무늬 풀밭, 낮은 풀, 나무)이 있고, 동쪽 강 건너에는 마을 집 6채의 지붕과 불 켜진 창이 보인다(걸어서 갈 수는 없다). 미니맵에 보리 할머니 오두막이 빨간 지붕 집 표시로 나온다.",
	"· v0.0.77: 노을과 벽돌들, 굳은달 거푸집이 노리는 것이 왕관이 아니라 팔찌가 되었다. 왕관은 그대로 머리에 쓴 달지기 표식이고, 늪 아래 동굴에서 노을은 '그 팔찌, 네 것이 아니야' 하며 소라의 팔목으로 손을 뻗었다가 팔찌에 튕겨 나간다. 옛 명령은 '팔찌를 정원 한가운데로'이고, 한결은 팔찌를 왕관과 함께 갈대 바구니에 담아 늪으로 보냈다. 이야기 32줄을 고쳤다.",
	"· v0.0.76: 바람 언덕이 갈대늪처럼 보인다. 단색 판이던 바닥에 늪의 풀과 같은 방식으로 바람에 눕는 황록 풀이 638칸에 6포기씩 자라고(간간이 흰·노랑·보라 꽃), 블록 윗면에 얼룩 무늬가, 길에는 흙빛 무늬가 생겼다. 풀은 길, 골짜기, 물길, 풍차, 등불, 바람개비 둘레 1칸은 비운다. 휴대폰은 늪처럼 절반만 그린다. 다른 지역도 같은 바닥 꾸밈을 차례로 입힌다.",
	"· v0.0.75: 보리 할머니 가게에서 산 칼과 갑옷이 화면에 보인다. 벼린 칼날을 1 → 2개 사면 베기 줄이 옅은 하늘빛, 3 → 4개면 푸른빛, 5개부터 금빛이 되고, 단계마다 줄이 6%씩 커지고 불티가 3개씩 는다(닿는 거리는 그대로). 튼튼한 갑옷을 사면 소라 발밑에 은빛 고리가 생겨 단계마다 밝아지고(5개부터 금빛), 맞을 때 어깨에서 은빛 조각이 튄다.",
	"",
	"2026-10-26 아침",
	"· v0.0.74: 설정 창 말고도 이야기 상자, 일지, 할 일 줄, 상점 물건 설명, 바뀐 것 목록의 글이 띄어쓰기에서만 꺾인다(낱말 한가운데서 꺾이지 않는다). 도움말의 기술 줄을 4줄 → 3줄로 줄였다. 이야기 글은 그대로 1초에 40자씩 나온다.",
	"· v0.0.73: 클라우드에서 찾은 잘못 9개를 고쳤다(자동 시험 141 → 150개).",
	"    - 벽돌 매와 굳은달 거푸집이 제 자리를 벗어난 소라를 쫓아와, 마을과 달의 계단에서도 내리꽂기와 고리 공격(18 → 26)을 했다. 이제 매는 제 바위 14칸 안에서만, 거푸집은 정원 안에서만 싸운다.",
	"    - 거푸집 체력이 12%를 조금 넘을 때 큰 한 방을 넣으면 고블린처럼 죽어 끝 장면으로 가지 못했다. 이제 그 싸움 중에는 체력 1에서 멈추고 굳는다.",
	"    - 벽돌왕에게 쓰러진 뒤 다시 싸우면 성난 2단계 그대로였다. 이제 처음 단계와 보라 막대로 돌아간다. 광장에서 깨어날 때 '쓰러졌다'가 0.5초만 보이던 것을 2.5초로 늘렸다.",
	"    - 바람 부르기나 바람개비 경주 중에 쓰러지거나 저장하면 남은 초가 할 일 줄에 멈춘 채 남았다. 이제 놓친 것으로 치고 원래 할 일 줄로 돌아간다.",
	"    - 물결이 하늘에 뜬 매를 쫓아가 소라를 따라오지 않던 것을 고쳤다.",
	"    - 콩알의 꼬마 찾기 중 마을 밖에서 저장하고 불러오면 꼬마와 경비 셋이 사라져 큰길이 막혔다. 이제 어디서 불러와도 꼬마가 돌아온다.",
	"",
	"2026-10-26 새벽",
	"· v0.0.72: 설정 창의 글이 낱말 한가운데서 꺾여('돌 / 진 베기', '순 / 간') 엔터를 친 것처럼 보이던 것을 고쳤다. 이제 띄어쓰기에서만 줄이 꺾인다. 도움말의 베기 줄도 짧게 줄여 5줄 → 3줄이 되었다(키보드와 휴대폰 둘 다).",
	"· v0.0.71: 휴대폰의 설정 Help 쪽 도움말을 키보드 도움말만큼 자세히 고쳤다. 5줄 → 7줄. 베기(연속 베기, 돌진 베기, 방패를 1초 누른 채 모아 베기, 빛 칼날이 열리는 레벨), 구르기와 막기를 따로 나누어 기력과 섬광 피하기·막기 틈, 기술마다 드는 기세와 레벨 혜택, 팔찌의 달빛 눈금이 차는 법을 적었다.",
	"· v0.0.70: 일지(Q) 오른쪽 칸 맨 아래에 '익힌 기술'을 더했다. 지금 레벨까지 연 기술(4타 연속기, 달려 베기, 모아 베기 등 10가지 중)과 다음에 열릴 것(예: '다음: Lv6 5타 마무리')이 나온다. Lv2 전에는 '베기, 구르기, 막기'.",
	"",
	"2026-10-25 저녁",
	"· v0.0.69: 설정의 Help 쪽 도움말에 새 레벨 혜택을 적었다. 베기 줄에 Lv8 빛 칼날과 Lv20 세 갈래, 구르기 줄에 Lv10부터 기력 18과 섬광 피하기 틈 0.2초, 기술 줄에 Lv15부터 20% 빠른 대기, Lv25부터 회복약 30% 더, Lv30부터 줄지 않는 기세.",
	"· v0.0.68: 레벨이 오르면 실제로 강해진다.",
	"    - 괴물의 체력과 때리는 힘이 소라 레벨을 그대로 따라와, Lv1과 Lv28 모두 벽돌 고블린 하나에 4번 베고 11대쯤 버텼다. 이제 괴물은 소라 레벨의 절반(Lv28이면 Lv14)에 맞춰 세진다. Lv28 고블린은 체력 310 → 170, 한 대 36 → 22.",
	"    - Lv8 뒤로 새로 얻는 것이 없었다. Lv10 가벼운 발(구르기 기력 25 → 18, 섬광 피하기 틈 0.15 → 0.2초), Lv15 달빛 숨(기술 대기 20% 짧게), Lv20 세 갈래 빛 칼날, Lv25 든든한 약(회복약 30% 더), Lv30 꺼지지 않는 기세(때리지 않아도 기세가 줄지 않음)를 더했다. 이미 그 레벨을 넘었으면 바로 쓸 수 있다.",
	"    - README를 지금 게임에 맞게 고쳤다(분량 322분, E 하나로 하는 일, 새 레벨 표, 시험 140개).",
	"· v0.0.67: 동굴 남쪽 방 실마리와 더 자세한 조작 도움말.",
	"    - 동굴 맨 남쪽 방의 창살 곁에 가면 무엇으로 열리는지 알려 준다. 물수제비 걸음이 있으면 '물웅덩이 섬의 수정 넷을 낮은 소리부터', 없으면 '섬에 건너갈 걸음부터 찾자'. 물길 아래에 있는 동안 할 일 줄 밑에 '섬 수정 넷을 낮은 소리부터 울리자 0/4'가 뜬다.",
	"    - 설정의 Help 쪽 조작 도움말을 7줄에서 9줄로 늘리고 자세히 썼다. 베기(연속 베기, 돌진 베기, 모아 베기가 열리는 레벨), 구르기와 막기(기력, 섬광 피하기·섬광 막기가 되는 때), 기술마다 드는 기세, 팔찌의 달빛 눈금이 차는 법, 숨은 키(P, T, F8, F9). 음악 줄은 맨 위로 옮겼다.",
	"· v0.0.66: 동굴 열쇠와 문이 다시 잠기지 않는다.",
	"    - 녹슨 열쇠를 줍거나 잠긴 문을 열어도 곧바로 저장하지 않았다(수레두더지를 이미 쓰러뜨렸으면 문을 열어도 저장하지 않았다). 그 뒤 다시 불러오면 열쇠가 상자로 돌아가고 문이 도로 잠겼다. 이제 줍는 순간과 여는 순간에 저장한다.",
	"· v0.0.65: 달빛 길돌 글씨를 키우고, 노을 첫 등장이 두 번 나오지 않게 했다.",
	"    - 길돌 목록 글씨를 15 → 18로 키우고 창을 330×244 → 400×300으로 넓혔다. 가+로 글씨를 더 키우면 창도 따라 커진다.",
	"    - 노을을 이미 만난 뒤(마을 등불이 꺼진 밤 이후)에 동굴 벽화에 처음 가면 노을의 첫 등장('내 이름은 노을')이 또 나왔다. 이제 벽화만 보고, 노을이 함께 있으면 노을이 벽화 이야기를 한마디 한다.",
	"",
	"2026-10-25 낮",
	"· v0.0.64: 글씨를 키우고 아래 아이콘 줄을 맞췄다.",
	"    - 다섯째 집 옛 그림을 한 변 540 → 405픽셀(화면 높이의 45%)로 줄였다.",
	"    - 이야기 상자 글씨를 20 → 23, 설정 화면 글씨를 16 → 18로 키웠다(가+/가− 크기 조절은 그대로 곱해진다).",
	"    - 왼쪽 아래 단추 넷을 64 → 68픽셀로 키워 오른쪽 기술 아이콘과 크기를 맞추고, 두 줄의 가운데 높이를 바닥에서 59픽셀로 맞췄다. 아이콘 사이는 모두 8픽셀이다.",
	"    - 마을 문 앞 물가(갈대늪 동쪽)에서 소라를 가리던 나무들을 반지름 4.5칸만큼 치웠다.",
	"    - 소라가 동서(화면 좌우)로 걸을 때 물결과 노을이 옆자리와 뒷자리를 오가며 좌우로 크게 흔들렸다. 이제 그 방향으로 걸을 때는 소라 발자국을 따라 뒤에 줄지어 걷고, 멈추면 옆자리로 온다.",
	"· v0.0.63: 마을 집 찬장에서 물건을 가져가지 않고, 잠자리가 새 침대가 됐다.",
	"    - 남의 집 찬장에서 금화(30, 60닢)와 회복약(1, 2개)을 얻던 것을 없앴다. 남의 살림이라 소라는 들여다보기만 하고 문을 닫는다. 일지의 '마을 집 찬장 0/5' 줄도 뺐다.",
	"    - 다섯째 집 찬장의 옛 그림에 삽화를 넣었다. 화면 오른쪽 위에 화면 높이의 60% 크기로 뜨고 방은 그대로 보인다. 보름달 아래 달지기 여덟이 큰 태엽 열쇠를 함께 밀고, 맨 앞의 한결이 옆 사람과 손잡이 하나를 같이 잡고 있다.",
	"    - 토리의 실마리가 '찬장 다섯'에서 '맨 끝 집 찬장의 옛 그림'으로 바뀌었다.",
	"    - 밤에 자는 마을 사람이 5번 시안 침대에 눕는다: 나무 머리판, 머리맡 탁자와 켜진 등불, 그 사람 그림에서 떠 온 조각 이불(천천히 숨 쉰다), 옅은 z Z. 바닥 이부자리 둘도 같은 침대가 됐다.",
	"· v0.0.62: 마을 사람들도 덜 폴짝거린다.",
	"    - 마을 사람, 심지, 꼬마 고블린이 0.45칸에서 0.9칸마다 한 번 뛴다. 노을과 물결은 1.8칸에 한 번 그대로다.",
	"    - 성 시험 하나가 컴퓨터가 바쁠 때 가끔 실패하던 것을 고쳤다.",
	"· v0.0.61: 노을과 물결이 덜 폴짝거린다.",
	"    - 두 동료는 소라를 따라 빨리 달려 1초에 여러 번 뛰었다. 이제 1.8칸 걸을 때마다 한 번 뛴다.",
	"",
	"2026-10-25 아침",
	"· v0.0.60: GPT 손 시험 8바퀴에서 찾은 일곱 가지를 고쳤다.",
	"    - 벽돌 벽 셋 중 하나가 닫혀 있는데도 가까이 가기만 하면 노을의 재대결이 시작됐고, 벽 너머로 서로 맞아 소라 체력이 187 → 107이 됐다. 닫힌 벽이나 잠긴 문이 사이에 있으면 이제 모든 괴물의 공격(베기, 돌진, 먼지 고리, 날아오는 것)과 소라의 공격이 둘 다 닿지 않는다('닫힌 벽'이 뜬다).",
	"    - 재대결은 소라가 벽 안쪽 빈터에 들어와야 시작한다. 이긴 뒤에도 닫힌 벽이 남아 있으면 할 일 줄이 '닫힌 벽돌 벽을 팔찌로 풀며 동쪽 끝으로 가자 (벽 곁에서 E, 눈금이 모자라면 밤에 등불 곁에서 쉬자)'로 길을 알려 준다.",
	"    - 집에서 자는 콩알, 도란, 물결을 찾으라는 할 일 줄이 한밤중에도 '콩알이 울고 있다'였다. 그 사람이 집 안에서 자는 동안에는 '콩알은 지금 집에서 잔다. 집에 들어가 침대 곁에서 E (아니면 아침에)'로 바뀌고, 일지도 같은 줄을 보여 준다.",
	"    - '금화 5을 넣고 사과을(를) 집었다' 같은 글을 고쳤다. 낱말이나 숫자의 마지막 글자에 맞춰 을/를, 이/가, 은/는, 과/와, 으로/로가 정해진다(5 → 를, 10 → 을). 장터, 낚시, 문 그림, 동료 쓰러짐, 자는 사람 알림에 쓴다.",
	"    - 도란 편지를 풀고 처음 만난 물결이 '또 왔어?'로 시작했다. 만난 적이 없으면 '처음 보는 얼굴이네'로 시작하고, '또 왔어?'는 두 번째 이야기부터 나온다.",
	"    - 보리 할머니께 한결의 편지를 전한 뒤 '도란에게 돌려주자'가 어디에도 적혀 있지 않았다. 돌려줄 때까지 할 일 줄 아래 작은 줄로 '도란에게 한결의 편지를 돌려주자'가 붙는다(물가 괴물과 싸우는 동안은 그 줄이 우선한다).",
	"    - 가끔 실패하던 동료 잡담 시험(folk_chat)이 동료의 무작위 잡담에 흔들리지 않게 시험 동안 동료 잡담을 멈췄다. 자동 시험 lap8이 일곱 가지를 하나씩 확인한다(전체 138 → 139개). 놀 수 있는 분량은 약 322분 그대로다.",
	"· v0.0.59: GPT 손 시험 7바퀴에서 찾은 다섯 가지를 고쳤다.",
	"    - 열쇠 없이 잠긴 문 밖에서 친 공격이 문 안 수레두더지에게 닿아, 두더지가 쓰러지고 레벨 7 → 8과 물수제비를 얻었다. 문이 닫혀 있는 동안 두더지는 문에서 1.6칸 안으로 못 오고 맞지도 않는다('닫힌 문'이 뜬다).",
	"    - 문 밖에서는 두더지가 깨어나 덤비지도 않는다. 열쇠로 문을 열면 전처럼 싸운다.",
	"    - 일지(Q)를 열어도 세상이 멈추지 않아 읽는 동안 체력이 104 → 62로 깎였다. 이제 일지가 열려 있는 동안은 설정이나 상점처럼 시계와 괴물이 멈춘다.",
	"    - 벽돌왕을 쓰러뜨리고 저장한 뒤 불러오면 동굴 입구가 (15.0, 7.4) → (16.0, 2.5)로 옮겨 갔다. 입구 자리를 저장 파일에 적어 두고, 불러올 때 그 자리에 그대로 세운다. 입구 자리가 없는 옛 저장은 전처럼 계산한다.",
	"    - 보리 할머니와 이야기한 뒤 바구니와 물가 일이 벌어져도 할 일 줄에는 큰길만 있었다. 이제 지금 하는 곁 단계('팔찌를 대 진흙을 풀자', '물가의 괴물을 물리치자' 따위)가 할 일 줄 아래 작고 흐린 줄로 붙고, 그 단계가 끝나면 사라진다. 장식 상자도 한 줄 만큼 늘어 다른 칸과 겹치지 않는다.",
	"    - 첫 할 일 줄의 '(상점에서 약을 챙기자)'가 가진 것과 맞지 않았다(회복약 3개, 금화 10인데 약값은 30). 약이 있으면 '회복약은 4 키로 마신다 (n개)', 약이 없고 금화가 30 이상이면 '상점에서 약을 챙기자', 금화가 모자라면 '금화는 괴물을 잡으면 모인다. 약값은 30'이 뜬다. 터치 화면에서는 4 키 대신 초록 하트라고 쓴다.",
	"    - 자동 시험 lap7이 다섯 가지를 하나씩 확인한다(전체 137 → 138개). 놀 수 있는 분량은 약 322분 그대로다.",
	"· v0.0.58: GPT 손 시험 6바퀴에서 찾은 다섯 가지를 고쳤다.",
	"    - 설정의 Help 쪽이 6012px까지 늘어나 '다음 곡'이 휠 120번 아래에 있었다. 줄 높이를 글이 필요한 만큼으로 다시 재서 400px 안에 다 들어온다.",
	"    - 645x480 같은 작은 화면에서 말하는 사람의 그림이 화면 위로 잘렸다. 그림 높이를 화면 높이에 맞춰(560px → 392px) 머리와 어깨가 대화 상자 위에 다 보인다.",
	"    - 좁은 화면에서 할 일 줄이 소라와 동료 위에 놓였다. 소라 둘레 240x180px는 비우고, 자리가 없으면 소라 아래 키와 기술 칸 사이에 둔다. 창 크기가 바뀌면 다시 잰다.",
	"    - 물수제비 걸음을 가진 채 성 큰 방 강가를 달리다 Shift를 놓으면 0.2칸 순간이동(정체 해소)이 일어났다. 강가 0.35칸 안에서도 서 있을 수 있게 고쳤다.",
	"    - 벽 너머 6칸 안의 괴물 때문에 등불 곁 휴식이 막혔다. 이제 곧바로 볼 수 있는 괴물만 막고, 막히면 '가까이 괴물이 있어 쉴 수 없다'를 한 번 알린다.",
	"    - 자동 시험 lap6이 다섯 가지를 하나씩 확인한다(전체 132 → 137개). 놀 수 있는 분량은 약 322분 그대로다.",
	"· v0.0.57: 성 큰 방 밑에 지하 3층짜리 곁이야기 '끝내지 못한 등불'(달지기 작업장)이 생겼다.",
	"    - 기사를 쓰러뜨리면 큰 방 북동쪽 구석에 손 둘이 새겨진 정비 문이 드러난다. 노을과 물결이 함께 있으면 E로 열린다.",
	"    - 지하 1층 짝등 작업장에서는 작업등 둘을 다 켜야 겹친 빛 속에 널빤지 길이 드러난다. 건너편 벽돌 마개를 풀면 아래 계단이 열린다.",
	"    - 지하 2층 엇갈린 물길에서는 사슬 기둥 곁에서 E를 누르면 물결이 걸어가 쇠 뚜껑을 당긴다. 그 밑 마개를 풀면 남쪽 물길이 마른다.",
	"    - 지하 3층 남겨 둔 손잡이에서는 빨간 고리가 뜨고 1초 뒤 천장 조각이 떨어진다. 벽 틈은 안전하고, 벽의 죔쇠 둘을 풀면 일 구덩이가 열린다.",
	"    - 맨 아래 수리 요람과는 싸우지 않는다. 팔 셋이 바닥 경고 1초 뒤 차례로 휩쓸고, 그 틈에 걸쇠 셋을 감은 뒤 E로 등불을 푼다. 맞아도 감은 걸쇠는 그대로다.",
	"    - 보상은 최대 체력 +10이고 한 번만 준다. 등불을 심지에게 주면 광장 곁에 수리대가 생기고 마을 사람 넷의 잡담이 하나씩 는다.",
	"    - 층을 풀 때마다 그 층의 길돌이 깨어난다. 길돌 목록 8번 '달지기 작업장'이 가장 깊은 길돌로 데려간다.",
	"    - 미니맵 위에 층 꼬리표(B1, B2, B3)가 붙고, 성 미니맵에는 문 자리에 보라색 계단이 붙는다.",
	"    - 자동 시험 workshop이 문, 세 층의 장치, 길돌, 요람, 심지, 층마다 저장과 불러오기를 확인한다.",
	"    - 놀 수 있는 분량은 약 302분 → 322분이 되었다.",
	"",
	"2026-10-25 새벽",
	"· v0.0.56: 배경 음악이 생겼고, 설정 위쪽에 음악 단추가 생겼다.",
	"    - 음악은 모두 코드로 만든다(녹음 없음). 80년대 후반 PC 액션 RPG 같은 FM 록(들판, 동굴, 우두머리)과 느린 곡(제목, 마을, 밤, 끝맺음) 두 갈래로 모두 9곡이다.",
	"    - 곡은 제목, 늪과 호수, 바람 부는 들, 동굴과 성, 우두머리, 마지막 싸움, 마을, 밤, 끝맺음이다. 곳과 때에 따라 0.5초마다 골라서 1초 동안 겹쳐 바꾼다.",
	"    - 효과음 길과 음악 길을 따로 두었다. 음악은 효과음보다 14dB 낮아서 발소리, 타격, 줍는 소리가 늘 위에서 들린다.",
	"    - B 키와 설정 위쪽 단추(소리 단추 옆)가 음악을 켜고 끈다. 끄면 1초에 걸쳐 조용해지고 설정에 저장된다. 위쪽 단추 넷은 모두 44 x 40이고 8px씩 떨어져 있다.",
	"    - 설정의 Help 쪽에 '♪ 곡 이름'과 '다음 곡' 단추가 있다. 누르면 지금 곡이 0.12초에 사라지고 0.35초 뒤에 다음 곡이 나온다. 그 자리를 떠날 때까지 이어진다.",
	"    - 조작법 창에 'B 배경 음악 켜기/끄기' 줄이 생겼다(휴대폰 화면에는 키가 없어서 넣지 않았다).",
	"    - 곡을 다시 만들려면 python tools/bgm.py를 쓴다(numpy와 ffmpeg가 필요하다). 처음 1초는 조용하다.",
	"· v0.0.55: 싸우다 키를 마구 누르면 소라가 순간이동하던 것을 고쳤다.",
	"    - 원인은 달려 베기(Lv3, Shift를 누른 채 J)였다. 달리면서 공격을 연타하면 소라가 한 프레임에 3칸을 건너뛰었다. 이제 0.14초 동안 앞으로 미끄러지며 지나가는 적을 베고, 그동안 무적이며 잔상 네 개와 바람 소리가 남는다.",
	"    - 달려 베기의 도착점을 잴 때 물 걷기는 이미 물 위에 있을 때만 친다. 그래서 Shift를 놓은 순간 강 위에 떠서 물가로 던져지는 일이 없다.",
	"    - 그 밖의 한 프레임 이동은 없었다. 구르기와 밀려남은 속도로 움직이고, 기술은 소라를 옮기지 않는다.",
	"    - 벽이나 물에 끼었을 때의 구출은 먼저 소라 둘레 0.1칸 간격 1.5칸 안에서 가까운 빈자리를 찾고, 그다음에야 타일 가운데를 찾는다. 그리고 0.12초 동안 미끄러져 간다. 전에는 최대 11칸을 한 프레임에 건너뛰었다.",
	"    - 구출은 모두 기록에 남는다(때, 어디서 어디로, 까닭, 달리기와 구르기 상태). 환경변수 UNSTICK_LOG=1이면 화면에도 찍는다.",
	"    - 마구 누르기 시험 mash는 들판과 물가에서 물 걷기를 껐다 켜고 12초씩 공격, 구르기, 막기, 기술, Shift, 방향을 무작위로 누른다. 구출이 한 번도 없고 한 프레임에 1칸을 넘는 이동도 없어야 통과한다.",
	"    - 좁은 창에서 할 일 글귀 칸의 너비가 음수가 되던 오류도 막았다.",
	"· v0.0.54: 소라가 쉬면 물결도 노을처럼 앉아 쉰다.",
	"    - 소라가 10초 넘게 가만히 있고 7칸 안에 괴물이 없으면 곁에 선 물결이 앉은 그림(art/folk/mulgyeol_rest.png)으로 바뀐다. 노를 무릎에 가로로 얹은 모습이다.",
	"    - 앉은 그림은 서 있을 때와 같은 크기로 그려서 키가 그대로이고, 바닥에서 90px 올려 발이 땅에 닿게 했다.",
	"    - 소라가 움직이거나 괴물이 7칸 안에 오면 바로 일어난다. 노을도 함께 있으면 둘이 1칸 이상 떨어져 앉는다.",
	"    - 앉기 시험 noeul_rest가 이제 물결도 확인한다.",
	"· v0.0.53: 마을 아이들과 사람들의 키를 노을에 맞춰 줄였다.",
	"    - 마을 사람들의 그림은 머리가 큰 아이 모양이라 노을과 비슷한 키로 그리면 머리가 훨씬 커 보였다. 키 표 하나(FOLK_HEIGHT)에서 모두 정한다.",
	"    - 토리 1.75 → 1.35, 콩알 1.75 → 1.40, 두솔과 여울 1.75 → 1.50, 차돌과 도란과 새참 1.75 → 1.55, 다래 1.75 → 1.60이다. 심지는 2.10 그대로 가장 크고, 노을은 1.80이다.",
	"    - 콩알의 꼬마 고블린은 콩알 비율대로 1.00 → 0.80이 되었다. 물결은 1.75 그대로다.",
	"    - 발은 땅에 그대로 닿고, 그림 크기만 바뀐다. 말풍선 높이는 키에서 계산해 머리 바로 위에 뜬다.",
	"    - 시험 장면 folk_line은 소라, 노을, 물결과 마을 사람들을 한 줄로 세워 키를 나란히 보여 준다.",
	"· v0.0.52: 마을 사람들이 미끄러지듯 흐르지 않고 통통 튀며 걷는다.",
	"    - 걷는 사람은 0.45칸 걸을 때마다 0.12칸 높이로 한 번씩 튄다. 빨리 걸으면 더 빨리 튄다. 콩알과 토리는 조금 낮게(0.10칸), 콩알의 꼬마 고블린은 0.09칸 튄다.",
	"    - 내려앉을 때 잠깐 납작해지고(세로 0.9, 가로 1.08, 0.06초) 꼭대기에서는 살짝 길어진다. 튀는 사이에는 발이 땅에 닿는다.",
	"    - 서면 튀던 것을 마저 끝내고 0.2초 안에 땅에 선다. 튈 때마다 두 그림 칸을 번갈아 보여 몸이 걸음을 떼는 것처럼 보인다.",
	"    - 물결은 예전 0.06칸에서 0.12칸으로 두 배 높이 튄다. 같은 도우미를 쓰며 노을도 함께 튄다.",
	"    - 말풍선은 그림이 아니라 땅 위 자리에 달려 있어서 말하는 사람이 튀어도 글자가 흔들리지 않는다.",
	"· v0.0.51: 방앗간 바람개비 달리기를 놓치면 바람이 소라를 깃대로 데려다주고, 바로 E로 다시 할 수 있다.",
	"    - 시간이 다 되면 바람이 0.6초 동안 소라를 깃대 곁까지 실어 가고, 소라는 첫 바람개비를 보고 선다. 한 프레임에 1칸을 넘게 튀지 않는다.",
	"    - 할 일 줄이 '깃대에서 E: 바람 부르기 다시 (2번째)'로 바뀐다. 휴대폰에서는 E가 팔찌 단추로 나온다.",
	"    - 놓칠 때마다 다음 달리기가 2초씩 길어진다. 12초 → 14초 → 16초, 가장 길게 18초이고 토스트가 '다음엔 14초'처럼 알려 준다.",
	"    - 성공하거나 언덕을 떠났다 다시 오면 12초로 돌아간다.",
	"    - 첫 성공 전에는 깃대의 깃발이 펄럭이고, 6칸 안에 가면 그 위에 E 표시가 떠다니며, 미니맵에도 깃대가 보인다.",
	"    - 골 밖으로 걸어 나가 끝난 달리기는 소라를 옮기지 않고 같은 할 일 줄만 남긴다. 달리기 도중 저장하면 불러올 때 그 줄이 나온다.",
	"· v0.0.50: 이야기 글상자의 위아래 여백을 같게 맞췄다.",
	"    - 글 덩어리가 상자 가운데에 놓여서 첫 줄 위의 빈틈과 마지막 줄 아래의 빈틈이 같다. 전에는 위가 크고 아래가 14px뿐이었다.",
	"    - 글이 상자 기본 높이(144px)보다 짧으면 위에 붙이지 않고 가운데에 둔다. 얼굴 그림이 있는 줄은 얼굴도 같은 가운데에 맞춘다.",
	"    - 말하는 이 이름표는 상자 윗변에 걸려 있어 글 위 여백은 20px 아래로 내려가지 않는다. 다음 표시(▼)와 쪽 수 글은 제자리다.",
	"    - 645px, 900px, 1600px 창과 휴대폰 화면에서 한 줄, 세 줄, 이름 있는 줄의 위아래 여백 차이가 2px 안이고 상자가 화면 안에 있는지 시험한다.",
	"· v0.0.49: 할 일 글귀가 동료 줄과 겹치고 장식 줄이 글자를 가로지르던 것을 고쳤다.",
	"    - 할 일 글귀를 상태판, 해와 달 창, 동료 줄, 우두머리 막대, 미니맵, 메뉴 키의 실제 칸을 피해 놓는다.",
	"    - 창이 좁으면 동료 줄 오른쪽 빈 띠나 그 아래에 놓고, 긴 글귀는 두 줄까지 접는다.",
	"    - 금빛 장식 줄은 글귀가 놓인 칸에서 가운데, 너비, 높이를 받아서 어떤 크기에서도 글자를 가로지르지 않는다.",
	"    - 1180px보다 좁은 창에서 우두머리 막대가 동료 줄 위로 올라타던 것도 빈 띠로 옮겼다.",
	"    - 휴대폰 글귀(막대를 끝까지 밀고)가 컴퓨터에서 나오던 것을 막으려고 글귀가 마지막에 쓴 입력을 따른다. 키나 마우스를 누르면 키 이름, 화면을 만지면 터치 이름으로 바로 바뀐다.",
	"    - 저장은 터치 이름으로 바뀌기 전의 원래 글귀를 담는다.",
	"· v0.0.48: 집 들어가기와 상자 열기도 E 한 키로 한다.",
	"    - E는 먼저 말 걸기, 그다음 팔찌 쓰기(등불, 벽돌 풀기, 길돌, 낚시), 그다음 집 문, 들판 상자, 찬장, 동굴 열쇠 상자와 문을 연다.",
	"    - 문 앞에 마을 사람이 서 있으면 E는 집에 들어가지 않고 그 사람에게 말을 건다.",
	"    - 집 안에서는 문 0.95칸 안에서 E를 누르면 밖으로 나간다. 문 위로 걸어 나가는 길도 그대로다.",
	"    - Space도 예전처럼 열고 들어가지만 조작법, 도움말, 상점 줄 어디에도 더는 적지 않는다. 조작법은 15줄에서 14줄이 되었다.",
	"    - 휴대폰의 손 단추를 없앴다. 팔찌 단추 하나가 말 걸기, 열기, 들어가기를 모두 한다.",
	"    - 토리의 찬장 실마리도 'E를 눌러 봐'로 바꿨다.",
	"· v0.0.47: 달빛 눈금이 8칸에서 시작해 12칸까지 늘고, 마을 사람들이 잡담을 하며, 소라가 쉬면 노을도 앉아 쉰다.",
	"    - 눈금은 큰 일 네 곳을 처음 마칠 때 한 칸씩 깨어난다. 한결의 편지를 보리 할머니께 전할 때, 벽돌 거북을 물리칠 때, 열셋째 등불을 심지에게 건넬 때, 성의 기사를 물리칠 때다. 네 자리는 GPT가 골랐다.",
	"    - 편지의 최대 체력 +10과 열셋째 등불의 최대 체력 +15는 눈금 한 칸으로 바뀌었다. 칸이 깨어나면 대사 한 줄과 '최대 9칸'처럼 실제 칸 수를 알리는 줄이 나온다.",
	"    - 큰길만 따라가면 11칸, 곁이야기인 열셋째 등불까지 마치면 12칸이 된다.",
	"    - 쉬어서 채우기, 달가루, 의뢰 보상은 늘어난 칸까지 채운다. 화면 왼쪽 위 마름모도 칸 수만큼 16px 간격으로 그린다(12칸이면 x 178 → 354, 막대 끝 400 안).",
	"    - 새 바퀴에도 늘어난 칸과 받은 자리를 가져가고, 같은 자리에서 두 번 받지 않는다.",
	"    - 예전 저장은 이미 마친 자리의 칸을 한 번 돌려받는다. 체력과 금화는 다시 주지 않는다.",
	"    - 마지막 싸움은 칸이 12개여도 등불 8개가 켜지면 '여덟 등불이 모였다. 이제 함께 감자.'와 함께 마지막 감기가 열린다.",
	"    - 마을 사람 11명과 보리 할머니가 소라가 4칸 안을 지날 때 가끔 말풍선으로 잡담을 한다. 사람마다 10줄, 모두 120줄이며 GPT가 썼다.",
	"    - 줄은 아침(6 → 10시), 낮, 해 질 녘, 비, 등불 밤 전과 후, 호수를 푼 뒤, 엔딩 뒤, 등불 축제, 자기 의뢰 중, 짝이 되는 사람이 4칸 안에 있을 때처럼 지금 상황에 맞는 것만 고른다.",
	"    - 한 사람은 15 → 25초에 한 번 말하고, 말풍선은 4초에 하나만 뜬다. 이야기, 상점, 일지가 열렸을 때, 괴물이 8칸 안에 있을 때, 집 안에서는 말하지 않고, 자는 사람도 말하지 않는다.",
	"    - 콩알의 꼬마 고블린은 집에 돌아온 뒤에만, 물결은 동료가 되기 전 마을에 있을 때만, 보리 할머니는 낮에 오두막 앞에서만 말한다.",
	"    - 소라가 10초 넘게 손을 놓고 쉬는 동안 곁에 선 노을이 바닥에 앉아 쉰다. 앉은 그림은 GPT로 그렸고, 소라가 움직이거나 괴물이 7칸 안에 오면 바로 일어선다.",
	"",
	"2026-10-24 저녁",
	"· v0.0.46: GPT가 이야기 시험 놀이 2 → 9바퀴에서 찾은 21가지 가운데 20가지를 고쳤다.",
	"    - (1) 치명타를 맞은 그 순간 자동 저장이 되면 체력 0으로 이어했다. 쓰러져 있는 동안은 저장하지 않고, 체력 0으로 남은 예전 저장은 체력을 채워 연다.",
	"    - (2) 거북을 이긴 뒤 마을 동쪽 문 앞에서 광부 차돌과 소라가 서로 길을 막고 멈췄다. 차돌이 오가는 길을 문 바로 앞 칸에서 1 → 2칸 서쪽으로 옮기고, 주민이 소라를 기다리며 길 가운데 서 있을 때는 소라를 막지 않는다.",
	"    - (3) 정원 싸움 도중 저장을 불러오거나 정원에서 쓰러지면 없는 방어전이나 마지막 감기를 하라고 했다. 이제 '정원 한가운데로 돌아가 굳은달 거푸집에 다시 맞서자'가 뜬다.",
	"    - (4) 방앗간 바람 부르기 도중 저장하면 멈춘 초시계가 할 일 줄에 남았다. 저장에는 달리기 전 할 일 줄을 넣고, 예전 저장은 큰길 할 일로 바꾸며 깃대에서 다시 하라고 알린다.",
	"    - (5) 마을 의뢰 중 동굴에 다시 들어가 쓰러지면 할 일 줄이 사라졌다. 쓰러지면 들어가기 전 할 일 줄이 돌아오고, 빈 줄이 그것을 덮지 않는다.",
	"    - (6) 거북에게 지고 마을에서 깨어나도 섬의 거북을 물리치라고 했다. 이제 남쪽 문으로 호수에 나가 부두의 물결에게 말을 걸라고 하고, 호수에 들어서면 '부두의 물결에게 말을 걸자'가 된다.",
	"    - (7) 고슴도치 싸움 도중 이어하면 고슴도치가 사라져 마지막 뿌리를 바로 풀 수 있었다. 싸움을 마쳤는지 저장하고, 못 마쳤으면 마지막 매듭에서 고슴도치가 다시 나온다.",
	"    - (8) 수레두더지를 이긴 뒤 새로 켜면 두더지와 첫 보상이 다시 나왔다. 물수제비를 얻은 뒤에는 두더지가 나오지 않고, 두 번째 승리는 아무것도 바꾸지 않는다.",
	"    - (9) 첫 등불 뒤 5초 안에 보리 할머니를 만나면 할 일 줄이 이미 간 오두막으로 되돌아갔다.",
	"    - (10) 벽화를 늦게 처음 보면 이미 연 문의 열쇠를 찾으라 했다. 이제 열쇠, 문, 물수제비 상태에 맞는 줄이 뜬다.",
	"    - (11) 숲 결투에서 지고 다시 들어가면 이미 연 벽을 풀라고 했다. 이제 '노을과 다시 겨루자'가 뜬다.",
	"    - (12) 휴대폰의 'E를', 'E 두 번'은 v0.0.45에서 이미 '팔찌 단추'로 바뀌어 고칠 것이 없었다.",
	"    - (13) 노을과 물결이 동료가 되기 전에도 여관, 장터 쪽지, 유리병 편지, 까치 대사에 나왔다. 아직 함께하지 않는 동료의 대사는 빼고, 꼭 필요한 줄은 소라의 말이나 서술로 바꿨다. 까치 이야기의 '한결의 일기에 나왔어'는 '들은 적 있어'로 고쳤다.",
	"    - (14) 도란의 의뢰를 먼저 받으면 편지를 전한 뒤에도 처음 만난 인사를 했다. 의뢰를 시작하면 만난 것으로 친다.",
	"    - (15) 보리 할머니가 편지를 도란에게 돌려주라 했는데 돌려주는 장면이 없었다. 다음에 도란에게 말을 걸 때, 또는 등불 밤이 시작될 때 돌려준다.",
	"    - (16) 성 지하 동쪽 배수 통로에서도 한결의 방 수호자 싸움이 시작됐다. 이제 한결의 방 안(열 1 → 8)에서만 시작한다.",
	"    - (17) 주민이 자러 가고 일어날 때 집과 울타리를 뚫고 곧게 걸었다. 이제 마을 길을 찾아 집 문까지 걷는다.",
	"    - (18) 큰 태엽을 함께 감은 뒤에도 일곱 손잡이에 먼지가 소복하다고 했다. 이제 여덟 손잡이 모두에 새 손때가 묻었다고 한다.",
	"    - (19) 정원 도착 대사의 '성의 동쪽 문을 지나자'를 '회색 문을 지나자'로 고쳤다.",
	"    - (20) 백 년 동안 섬 밖에 살던 물결이 섬 밖은 처음이라고 했다. 친구들과 함께 자고 걷는 것이 처음이라는 말로 바꿨다.",
	"    - (21) 다람쥐를 구하지 않았는데 곳간 상자에서 구해 준 답례라 하고, 성의 일기 세 장을 다 읽지 않았는데 앞의 세 장과 글씨를 비교했다. 이제 구한 다람쥐와 읽은 장 수에 맞춰 말한다.",
	"    - 화면 왼쪽 위 하늘 시계의 해와 달도 두 배로 키웠다(반지름 5.5 → 11px).",
	"    - 3시 방향으로 걸을 때 머리 리본이 한 걸음마다 사라졌다 나타나던 것도 고쳤다(걷기 그림 둘째 칸에 리본을 그려 넣음).",
	"    - 설정의 바뀐 것 탭과 CHANGES.md가 이제 한 줄에 한 문장씩 보여 준다(판마다 첫 문장, 그 밑에 나머지 문장과 고친 것 하나씩).",
	"    - 놀 수 있는 분량은 약 302분 그대로다.",
	"· v0.0.45: 이야기 줄기를 사용자가 고른 안(태엽 팔찌, 함께 감는 손)으로 바꿨다.",
	"    - 소라는 왕관을 머리에 쓴 채 둔다.",
	"    - 왕관은 달지기의 표식이라 옛 장치와 벽돌이 알아보고 쫓는다.",
	"    - 힘을 쓰는 것은 소매 끝 파랑·금색 장식인 한 쌍의 태엽 팔찌다.",
	"    - 등불 켜기, 벽돌 풀기, 풍차 감기, 달빛 눈금 8칸이 모두 팔찌로 옮겨 갔다.",
	"    - 한결은 여덟 사람 몫을 혼자 감으려다 손이 굳었고, 보리 할머니의 말은 \"왕관을 썼다고 혼자 감는 건 아니란다. 옆 사람 손도 빌리렴.\"이 됐다.",
	"    - 이야기 대사 76줄, 할 일 줄과 알림과 조작법 26곳을 고쳤다.",
	"    - 큰 태엽 방의 왕관 모양 홈은 왕관 무늬가 새겨진 둥근 접점이 되어, 팔찌를 대면 테두리가 파랗게 빛난다(왕관이 둘 보이는 일은 없다).",
	"    - 이야기 그림 4장(02 등불, 06 동굴 벽화, 11 마지막 감기, 13 열셋째 등불)과 터치 팔찌 단추 그림을 GPT로 다시 그렸다.",
	"    - 휴대폰과 태블릿에서 \"E  보리 할머니의 상점\" 같은 글에 E가 그대로 남던 것을 고쳐, 상점 안내, 일지, 할 일 줄, 알림, 대사의 E를 모두 \"팔찌 단추\"로 보인다.",
	"    - 예전 저장의 할 일 줄도 불러오면 새 말로 바뀐다.",
	"    - 놀 수 있는 분량은 약 302분 그대로다.",
	"· v0.0.44: GPT가 이야기 큰길을 다시 따라가며 찾은 일곱 가지를 고쳤다.",
	"    - (1) 동굴 문을 연 뒤에도 할 일 줄이 '열쇠를 찾아 잠긴 문을 열자'로 남았다. 이제 문이 열리면 '열린 문 너머, 수레두더지가 있는 안쪽 방으로 가자'로 바뀐다.",
	"    - (2) 마을에 처음 닿은 순간의 저장을 이어하면 이미 온 마을을 찾으라고 했다. 이제 광장의 등불지기에게 말을 걸라는 줄이 나온다.",
	"    - (3) 달의 계단 마지막 등불을 켜면 아직 못 만난 거푸집의 심장을 노리라고 했다. 이제 '꼭대기 문을 지나 정원으로 가자'이고, 거푸집 줄은 정원 봉인 셋을 푼 뒤에 나온다.",
	"    - (4) 엔딩 전에 편지 세 통을 전하거나 보름달 축제를 보면 정원을 이미 감았다고 했다. 엔딩 전에는 묵은 편지와 꺼진 등불을 되살린 덕이라고 말하고, 정원 이야기는 엔딩 뒤에만 한다.",
	"    - (5) 보리 할머니에게 한결이 누군지 들은 뒤 엽서를 주워도 '한결이 누군지는 몰라도'라고 했다. 이제 마지막 달지기 한결에게 못 간 엽서라고 말한다.",
	"    - (6) 밤 추격 중에 낮까지 있다가 저장하고 이어하면 낮에는 없는 노을을 쫓으라고 했다. 이제 밤이 되면 마을에서 쉬자는 줄이 나온다.",
	"    - (7) 마을 다섯째 집 그림을 안 봤는데도 물결이 그 그림 속 한결과 닮았다고 했다. 그림을 안 봤으면 처음 보는 말을 한다.",
	"    - 전체 시험에서 가끔 실패하던 동료 수다 시험(말풍선 4개 → 1개)은 앞 시험에서 쓰러진 고블린이 8초 뒤 9칸 밖에서 다시 일어나 8칸 안으로 다가와 수다를 끊은 탓이라, 그 시험 동안은 되살아나지 않게 했다.",
	"",
	"2026-10-24 아침",
	"· v0.0.43: GPT가 처음부터 끝까지 이야기대로 따라가며 찾은 열한 가지를 고쳤다.",
	"    - 마지막 태엽 감기 대사 도중 저장하고 이어하면 엔딩, 금화 500, 경험치 400, 큰 태엽 방 구멍이 사라졌는데, 이제 이어하면 엔딩이 그대로 나오고 보상은 한 번만 받는다.",
	"    - 나중에 동굴을 다시 찾았다가 안에서 저장하면 나올 때 할 일 줄이 비던 것, 거북 전투 중 저장을 불러오면 부두로 돌아오는데 할 일 줄은 섬 전투로 남던 것, 마지막 봉인을 풀어도 할 일 줄이 2/3에 멈추던 것을 고쳤다.",
	"    - 동굴 출구의 '다음 장에서 이어진다'는 지금 강을 건너 마을로 가자는 말로, 심지의 등불 열두 개는 광장 둘레 등불로, 보리가 읽은 편지는 도란에게 돌려주라는 말로, 왕관을 머리에 쓰지 않는다는 말과 첫 만남 이야기는 실제 이야기에 맞게 고쳤다.",
	"    - 새 바퀴 안내는 다음 바퀴의 실제 배율(1.5배 → 2배 → 2.5배)을 보여 주고 두 쪽으로 나뉘며, 작은 화면에서 큰 글자로 긴 대사가 나오면 대화 상자가 위로 늘어난다.",
	"· v0.0.42: 마을 사람들이 낮에 저마다 두세 곳을 오간다.",
	"    - 나무꾼 두솔은 장작더미와 숲길 가, 광부 차돌은 광석 수레와 장터, 농부 새참은 밭과 연못가와 장터, 어부 여울은 연못가와 나루 머리, 다래는 장터 자리와 여관 문 앞, 토리는 장터와 광장과 새참의 밭, 도란은 북쪽 집들 앞, 콩알은 광장(꼬마 고블린도 따라간다), 마을에 있을 때의 물결은 연못가를 오간다.",
	"    - 한 곳에서 6 → 14초 머물고 1초에 1.4칸 걷는다.",
	"    - 걷는 도중에도 E로 말을 걸 수 있고, 말하는 동안은 멈춘다.",
	"    - 소라가 앞길 0.9칸 안에 서 있으면 기다린다.",
	"    - 해가 지면 있던 자리에서 길을 되짚어 집으로 간다.",
	"    - 심부름이 걸린 사람(울고 있는 콩알, 편지를 든 도란, 노를 기다리는 물결)과 등불지기 심지는 제자리에 있다.",
	"· v0.0.41: 휴대폰에서 할 일 줄, 알림, 대사에 남아 있던 키보드 말(Shift, (E), Space)을 터치 단추 이름(막대를 끝까지 밀어, 왕관 단추, 손 단추)으로 바꿔 보인다.",
	"    - 웹 판에서 나던 오류 하나(뒤로 단추 제목 찾기)도 고쳤다.",
	"· v0.0.40: 휴대폰 화면에서 GPT 시험 놀이꾼이 찾은 여덟 가지를 고쳤다.",
	"    - 상점이 화면 안에 줄어 들어가고 제목이 잘리지 않으며, 상점·일지·설정·조작법이 열리면 메뉴 단추와 미니맵이 비켜난다.",
	"    - 상점은 왼쪽 위 단추로 닫는다.",
	"    - 돋보기 단추는 메뉴 단추 왼쪽으로 옮겨 보스 체력 막대를 가리지 않는다.",
	"    - 긴 할 일 줄은 동료 상태와 오른쪽 단추 사이에서 두 줄로 접힌다.",
	"    - 휴대폰 조작법은 이동 막대와 터치 단추 그림으로 설명하고, 기술 그림 밑에 이름이 붙는다.",
	"    - 동료 말풍선이 1.4배로 커지고 1초 더 머문다.",
	"    - 창의 뒤로 단추가 56px 이상이 되었다.",
	"    - 달지기 숙소는 벽 윗면을 옅은 청회색으로 덮고 바닥을 조금 밝혀 밤에도 벽과 바닥이 구별된다.",
	"· v0.0.39: GPT 시험 놀이꾼이 두 번째로 찾은 네 가지를 고쳤다.",
	"    - 벽돌왕을 쓰러뜨린 뒤 할 일 줄이 '다음 장에서 계속' 대신 '열린 동굴 입구로 내려가자'를 보여 주고, 동굴 입구 위에 금빛 느낌표가 뜬다.",
	"    - 작은 돌숲에 들어서면 남쪽 나무들이 반쯤 비쳐 달 돌 앞 바닥과 안내판이 보인다.",
	"    - 밤 숲의 벽돌 벽 앞 바닥에 옅게 빛나는 테두리가 생겼다.",
	"    - 성 아래 등불 방은 물이 빠질 때 '물빛 등불 넷을 8초 안에 켜자'라고 알려 주고, 아직 꺼진 등불 위에 금빛 느낌표가 뜬다.",
	"· v0.0.38: GPT 시험 놀이꾼이 찾은 다섯 가지를 고쳤다.",
	"    - 좁은 틈에서는 물결과 노을이 소라 뒤에 한 줄로 따라오고, 소라가 멈추면 서로 떨어진 빈자리에 선다(다람쥐 나무 입구에서 셋이 겹쳐 보였다).",
	"    - 밤 아랫못의 열린 창살 길에 빛나는 다리 가장자리와 작은 등불을 달았다.",
	"    - 깨어난 물가에서 강가 길부터 다리 서쪽 끝까지 갈대를 걷어 한 칸 길을 냈다.",
	"    - 자는 주민이 깔개와 침대 위에 비스듬히 눕고 밑에 그림자가 생겼다.",
	"    - 달지기 숙소 안에서는 다음에 할 일(셈판, 작업대, 멈춘 문지기, 장부) 위에 금빛 느낌표가 뜬다.",
	"· v0.0.37: 5장에 다람쥐 나무(약 2분).",
	"    - 다람쥐 다섯을 구하고 회색 문을 연 뒤에는 숲 한가운데 회색 나무 틈 앞에 큰 다람쥐가 앉아 있다.",
	"    - 말을 걸면 굳은 나무 한 그루가 비켜서고, 안쪽 숨은 빈터에 숲에서 가장 늙은 도토리나무가 서 있다.",
	"    - 이 나무 뿌리가 아직 살아서 남쪽 골짜기 개울을 데우고 있었다.",
	"    - 나무 곁 3.2칸 안에서는 낮에도 켜진 등불 곁처럼 쉬어 눈금이 찬다(칸마다 6초).",
	"    - 뿌리를 묶은 벽돌 매듭 셋을 팔찌로 풀면(눈금 1칸씩) 뿌리가 하나씩 나무 쪽으로 당겨 붙고, 둘째 매듭 뒤에는 벽돌 고슴도치 2마리가 굴러 나온다.",
	"    - 마지막 매듭 뒤 1.5초 동안은 대사 없이 나무가 한 번 숨 쉬고 낮은 가지의 잎 둘이 처음 흔들린다.",
	"    - 그 뒤 나무가 초록이 되고, 구해 준 다람쥐 다섯이 돌아와 가지에 앉는다.",
	"    - 싹 튼 도토리(회복약 65 → 75, 새 바퀴에도 남는다), 최대 체력 +10, 금화 60을 받는다.",
	"    - 마을 나무꾼 두솔의 다람쥐 틈 실마리도 켰다.",
	"    - 대사와 소품은 GPT의 의견으로 다듬었다.",
	"· v0.0.36: 7장에 달지기 숙소(약 4분).",
	"    - 벽돌 기사를 쓰러뜨린 자리에 녹슨 태엽이 남고, 그 태엽으로 옥좌의 방 남쪽 벽의 태엽 문을 연다.",
	"    - 식당과 바구니 방에서 벽돌 6마리와 싸우고, 바구니 셈판에서 한결이 마지막으로 가져간 등불 바구니를 찾는다.",
	"    - 일방 태엽대의 깡통 문지기를 팔찌로 감으면(눈금 1칸) 침방까지 걸어가는데, 식당의 벽돌 더미 셋이 문지기에게 달려든다(닿으면 태엽이 튕겨 나와 곁에서 E로 다시 걷는다).",
	"    - 침방 장부의 한결 다음 칸에 소라의 이름을 적으면 문지기가 백 년 만에 제 의자에 앉아 작은 놋 방패를 건넨다(섬광 막기 0.12초 → 0.16초, 새 바퀴에도 남음).",
	"    - 궤짝에서 최대 체력 +10, 회복약 2, 금화 80.",
	"    - 대사와 소품은 GPT와 의논해 다듬었다.",
	"· v0.0.35: 마을에 일하는 사람 여섯이 생겼다.",
	"    - 나무꾼 두솔, 광부 차돌, 농부 새참, 낚시꾼 여울(두솔의 동생), 바구니 짜는 다래 할머니와 손자 토리.",
	"    - 저마다 일터(장작더미, 광석 수레, 굳은 밭, 연못가, 장터)에 서 있고, 말을 걸면 아직 못 끝낸 곁이야기의 실마리를 하나씩 들려준다.",
	"    - 이야기가 나아갈 때마다 하는 말이 바뀌고, 마지막 이야기에서 선물(회복약 1, 금화 30, 또는 물고기가 30% 빨리 무는 미끼 주머니)을 준다.",
	"    - 밤에는 집에 들어가 자며 한 집에 셋까지 잔다.",
	"    - 대사와 그림은 GPT와 함께 만들었다.",
	"· v0.0.34: 1장에 깨어난 물가(약 4분).",
	"    - 보리 할머니를 만난 뒤, 소라가 깨어난 자리에서 물가로 눌린 갈대 줄이 이어지고 그 끝 진흙에 갈대 바구니가 묻혀 있다.",
	"    - 팔찌로 진흙을 풀면(눈금 1칸) 벽돌 두 무리(고블린 2, 고블린 1과 활 1)가 일어나고, 바구니에서 금화 30과 회복약 1이 나온다.",
	"    - 보리 할머니는 달지기 등불 바구니를 알아보고 백 년 동안 켜지 않은 자기 등불과 회복약 1을 준다.",
	"    - 벽돌왕을 넘어뜨린 뒤 밤에 물가에서 등불 바구니를 띄우면(눈금 1칸) 물길 약 20칸을 따라 흘러가고, 벽돌 걸림 셋(고블린 2, 2, 고블린 1과 활 1)을 풀어 주면 늪 호수 섬 앞에 머문다(최대 체력 +10).",
	"    - 보리 할머니께 알리면 갈대 방석을 준다(밤에 켜진 등불 곁에서 쉬면 체력이 초당 4씩 찬다).",
	"    - 대사와 소품은 GPT와 의논해 다듬었다.",
	"· v0.0.33: 8 → 9장 끝 뒤에 큰 태엽 방(약 5분).",
	"    - 끝 장면은 그대로이고, 거푸집이 앉아 있던 자리에 구멍이 열린다.",
	"    - 내려가면 땅을 돌리는 큰 태엽 열쇠가 있다.",
	"    - 굳은 톱니 셋을 팔찌로 풀며(눈금 1칸씩) 열쇠에서 달려 나오는 거푸집 찌꺼기(2, 3, 4마리)를 막으면 벽돌 일꾼들이 일어나 톱니를 돌본다.",
	"    - 열쇠 한가운데에 왕관을 올리면 마을 사람들이 내려와 손잡이 여덟을 함께 잡고, 금빛 고리에 맞춰 E를 여덟 번 누르면 다 같이 감는다(그림 한 장).",
	"    - 궤짝에서 달지기 기름병(회복약을 마시면 기세 +20), 최대 체력 +20, 회복약 2, 금화 200.",
	"    - 대사와 소품은 GPT와 의논해 다듬었다.",
	"· v0.0.32: 밤이 되면 마을 사람들(도란, 콩알, 마을에 있을 때의 물결, 꼬마 고블린)이 저마다 가까운 집 문으로 걸어 들어가 자고, 아침이면 나와 제자리로 돌아간다.",
	"    - 등불지기 심지는 밤에도 광장에 남고, 보름달 축제 밤에는 모두 밖에 있다.",
	"    - 자는 사람의 집 문 위에 z가 뜨고, 그 집에 들어가면 침대에서 자는 모습(GPT 그림)이 보인다.",
	"    - 곁에서 E를 누르면 깨어 낮과 같은 이야기와 심부름을 하니 반딧불, 달꽃 같은 밤 심부름도 막히지 않는다.",
	"    - 낮에 서던 자리에서 E를 누르면 어디서 자는지 알려 준다.",
	"· v0.0.31: 아이폰과 아이패드에서 글자와 단추가 너무 작던 것을 키웠다.",
	"    - 휴대폰은 기준 화면을 640 → 540으로 줄여 모든 것이 약 1.2배 커지고 글자도 한 단계 커진다.",
	"    - 아이패드도 터치 화면으로 알아본다(전에는 사파리가 맥이라고 해서 데스크톱 화면이 나왔다).",
	"    - 메뉴 단추 넷은 미니맵 왼쪽에 2x2로 모이고, 설정과 일지 같은 큰 창은 화면에 맞게 줄어든다.",
	"· v0.0.30: 아이폰에서 미니맵은 움직이는데 화면 속 세상은 멈춰 있던 잘못을 고쳤다.",
	"    - 미니어처 흐림이 흐리게 하려고 복사한 화면이 아이폰 브라우저에서 첫 장면에 멈춰 있었다.",
	"    - 아이폰과 아이패드에서는 미니어처 흐림을 끄고, 다른 기기에서도 화면 복사에 밉맵을 쓰지 않는다.",
	"· v0.0.29: 휴대폰 가로 화면에서 놀 수 있다.",
	"    - 화면 왼쪽에 엄지를 대면 이동 막대가 생기고 끝까지 밀면 달린다.",
	"    - 오른쪽에 공격, 구르기, 막기, 왕관(E), 열기(Space) 단추가 있고 기술 그림을 누르면 기술을 쓴다.",
	"    - 손가락 여럿을 따로 읽어 걸으면서 벨 수 있다.",
	"    - 메뉴 단추는 미니맵 왼쪽, 확대·축소는 미니맵 아래로 옮긴다.",
	"    - 세로로 들면 가로로 돌려 달라고 한다.",
	"    - 휴대폰에서는 그림자를 끄고 풀을 절반만 그린다.",
	"· v0.0.28: 동료 수다를 107개에서 500개로 늘렸다(셋이 하는 대화 224, 곳과 때에 따른 대화 124, 이야기 진행 대화 27, 둘이 주고받는 말 50, 혼잣말 75).",
	"    - 동굴, 정원, 비 오는 때에도 그곳 수다가 나온다.",
	"    - 초안은 GPT가 쓰고 이야기 사실에 어긋나지 않는지 골랐다.",
	"· v0.0.27: 왼쪽 아래 단추 넷(조작법, 소리, 일지, 설정)을 오른쪽 기술 단추와 같은 금빛 마름모로 바꿨다.",
	"    - GPT가 그린 시안 다섯 가운데 4번(겹금테에 금빛 선 그림)이다.",
	"    - 단추는 56 → 64 px이고 8 px 간격은 그대로다.",
	"· v0.0.26: 동굴 밖에서 저장하고 다시 켜면 동굴에 내려갈 때마다 노을을 처음 만나는 벽화 장면이 다시 뜨던 잘못을 고쳤다.",
	"    - 열쇠와 연 문이 잊히던 것도 함께 고쳤다.",
	"· v0.0.25: 미니맵의 계단 표시를 네모에서 작은 계단 그림(세 단)으로 바꿨다.",
	"    - 올라가는 곳은 금빛, 내려가는 곳은 보라이고, 카메라를 돌려도 똑바로 선다.",
	"· v0.0.24: 설정 창의 네 쪽 이름을 Settings, Help, Changes, About으로 바꿨다.",
	"    - 어느 언어에서도 영어로 보인다.",
	"· v0.0.23: About 쪽에는 만든 사람(우주한량) 한 줄만 남기고 그림, 글꼴, 라이선스, 깃허브 단추를 뺐다.",
	"· v0.0.22: 바뀐 것 목록이 100줄을 넘으면 최근 100줄만 보이고, 더 읽기 단추로 100줄씩 더 불러온다.",
	"· v0.0.21: 일지(Q)와 조작법(H) 창에서 Esc를 누르면 창이 닫히고 놀이로 돌아간다.",
	"    - 전에는 아무 일도 없었다.",
	"· v0.0.20: 설정 창의 버전 글자를 제목 아래에서 제목 오른쪽 같은 줄로 옮겼다.",
	"· v0.0.19: 소라가 2시와 10시 쪽(오른쪽 위, 왼쪽 위)으로 걸을 때 머리가 흔들리고 안짱다리로 보이던 그림을 GPT에 다시 그리게 했다.",
	"    - 칸마다 머리 가운데를 맞춰 머리가 좌우로 1 px 넘게 움직이지 않는다.",
	"2026-10-24 새벽",
	"· v0.0.18: 4장에 물지기의 아랫못(약 5분).",
	"    - 거북을 물리친 뒤 섬 남쪽 끝 둑을 풀면 할아버지가 일하던 못이 나온다.",
	"    - 말뚝에서 E를 누르면 물결이 헤엄쳐 물밑 사슬을 당긴다.",
	"    - 디딤돌을 띄우고, 창살 마당에서 혼자 버티고, 물 태엽을 감으면 호수 물이 다시 한 바퀴 돈다.",
	"    - 깡통에서 일지 마지막 장과 물지기 호루라기(물결이 10 → 5초 만에 일어남, 최대 체력 +10).",
	"    - 황금 잉어가 5 → 15로 잘 잡힌다.",
	"· v0.0.17: 2장에 물길 끝 굴(약 7분).",
	"    - 두더지를 잡고 물수제비 걸음을 얻으면 두더지 방 남쪽 물길을 따라 내려간다.",
	"    - 섬 넷의 수정을 낮은 소리부터 울려 창살을 가라앉히고, 쓸려 온 물건 더미에서 보리 할머니가 한결에게 부친 \"혼자 가지 마\" 엽서를 찾는다.",
	"    - 3장에서 할머니께 건넨다.",
	"· v0.0.16: 6장에 참새 방앗간(약 9분).",
	"    - 벽돌 매를 물리친 뒤 언덕 남쪽 무너진 담을 풀면 바람 없는 골이 나온다.",
	"    - 큰 풍차를 감고, 깃대에서 12초 안에 바람개비 넷을 지나 바람을 불러 내리면 물길이 찬다.",
	"    - 어귀의 큰 수호자를 쓰러뜨리고 물수제비로 나루에 건너가면 가루 배, 종, 궤짝(삿대 고리: 물결의 장대 60 → 70%, 최대 체력 +10).",
	"    - 장터의 달빛 가루는 이 방앗간에서 빻던 것이다.",
	"· v0.0.15: 8 → 9장에 한결의 마지막 길(약 8분).",
	"    - 계단 꼭대기에서 정원 아래 무너진 뜰로 들어간다.",
	"    - 뿌리 벽돌을 풀고, 한결의 야영터에서 다섯째 일기와 빈 등불 고리를 찾고, 팔찌로 비춰야 보이는 발자국을 따라 깊은 틈을 건너, 거푸집이 떠 둔 벽돌 한결과 싸운다.",
	"    - 한결이 왕관을 늪으로 보낸 까닭이 밝혀진다.",
	"    - 일곱째 길돌 정원 앞 야영터.",
	"· v0.0.14: 우주 한량의 배치 규칙대로 화면의 단추와 판을 모두 가장자리에서 8px에 맞췄다(왼쪽 아래 단추, 왼쪽 위 초상, 미니맵, 기술 칸, 금화 칸).",
	"    - 단추 사이도 8px이다.",
	"· v0.0.13: 땅 밑에서 올라가는 곳을 지도에 금빛 네모로 표시한다(성 아래 잠긴 층, 물빛 동굴, 지하 동굴).",
	"    - 내려가는 곳은 보라색 그대로.",
	"    - 잠긴 층의 올라가는 계단에 틀과 등을 달았다.",
	"· v0.0.12: 멀리 보기(Z X, 휠)로 카메라를 물리면 땅이 뿌옇게 덮이던 안개를 약하게 했다.",
	"    - 안개가 카메라 거리만큼 뒤로 물러난다.",
	"",
	"2026-10-23 저녁",
	"· v0.0.11: 멀리서 깨지던 한글 간판을 그림으로 바꿨다(상점 물약병, 마을 표지판 등불과 화살표, 가판대 사과, 초승달, 찻잔, 여관 침대).",
	"    - 가판대와 여관 앞에 서면 무엇을 얼마에 파는지 알려 준다.",
	"· v0.0.10: 달빛 시련을 마을에서 바람 언덕 동쪽 선돌(옛 달지기들이 솜씨를 겨루던 돌)로 옮겼다.",
	"    - 벽돌 매를 물리친 뒤 열리고, 선돌에서 9칸 넘게 멀어지면 끝난다.",
	"    - 처음 깬 뒤에는 시련 괴물이 금화와 경험치를 주지 않는다.",
	"· v0.0.9: 달빛 눈금이 하룻밤에 다 차도록 빨라졌다.",
	"    - 등불 곁 10 → 6초, 반딧불 병 20 → 12초마다 한 칸.",
	"    - 밤은 105초라 등불 곁에서는 밤의 절반이면 8칸이 찬다.",
	"· v0.0.8: 칼 휘두르는 효과를 금빛 별가루로 바꿨다(시안 5개 중 3번).",
	"    - 가는 금빛 호가 칼끝을 따라 쓸고, 바깥으로 마름모 불티가 튄다.",
	"· v0.0.7: 심지가 열셋째 등불을 마을 동쪽 문에 거는 장면에 삽화를 붙였다.",
	"· v0.0.6: 벽돌왕을 쓰러뜨린 뒤의 저장을 불러오면 이야기가 동굴이 열린 때로 되돌아가고 할 일 줄이 \"땅 아래로 가는 동굴이 열렸다\"로 바뀌던 것을 고쳤다.",
	"    - 이미 되돌아간 저장은 한 일을 보고 제 단계로 되살린다.",
	"· v0.0.5: 상점의 보리 할머니 그림을 440x600 → 220x300(넓이 1/4)으로 줄였다.",
	"· v0.0.4: 설정 창 글자를 13 → 16px, 단추 글자를 13 → 15px로 키웠다.",
	"    - 긴 설명은 줄을 바꾸고, 글자를 키워 넘치면 굴려 본다.",
	"    - 조작법 창(H)이 글자 크기에 맞춰 넓어진다.",
	"· v0.0.3: 소리를 끄면 소라가 손가락을 입에 대고 \"쉬잇~\" 한다.",
	"    - 우주 한량의 그림을 가져왔다.",
	"· v0.0.2: 5장 숲 남쪽 잠든 골짜기(약 12분).",
	"    - 노을이 동료가 된 뒤 빈터 남쪽 회색 문으로 내려간다.",
	"    - 개울을 물수제비로 건너고, 기억 등불 셋으로 노을의 옛 기억을 찾고, 빈 망토(체력 1000)와 싸우고, 그림 문 셋 가운데 해 지는 그림 문에서 한결의 편지와 열셋째 등불을 찾는다.",
	"    - 심지에게 건네면 최대 체력 +15, 금화 150, 노을의 공격 간격 1.4 → 1.1초.",
	"    - 새 괴물 벽돌 고슴도치: 몸을 말면 모든 공격을 막고, 가시를 터뜨린 뒤 1.4초 어지러워 피해를 1.3배 받는다.",
	"· v0.0.1: 설정 창 제목 아래에 버전과 날짜를 작게 띄운다.",
	"    - 기능을 하나 더할 때마다 끝 숫자가 1씩 오른다.",
	"    - 넷째 칸 이름을 만든 이 → About으로 바꿨다.",
	"· v0.0.1: 설정 창 제목 아래에 버전과 날짜를 작게 띄운다.",
	"    - 기능을 하나 더할 때마다 끝 숫자가 1씩 오른다.",
	"    - 넷째 칸 이름을 만든 이 → About으로 바꿨다.",
	"· 마을을 32x24 → 48x36으로 넓혔다. 장터(정직 상자 가판대 3곳, 과녁 마당), 여관(금화 10, 하룻밤 회복), 낚시하는 부두.",
	"· 마을 이야기: 밤마다 장터 금화를 물어 가는 벽돌 까치를 쫓아 연못 둥지까지. 연못의 유리병 편지 셋(콩알, 도란, 한결).",
	"· 마을 집을 물가 기둥집으로, 풀을 짧은 잔디와 키 큰 무더기로 바꿨다(시안 5개 중 5번씩).",
	"· 쉬는 동안의 수다가 약 100가지가 됐다. 소라까지 셋이 말하고, 진행에 따라 새 대화 20가지가 한 번씩 나온다. 괴물이 오면 바로 멈춘다.",
	"· 설정을 화면 가운데의 팝업으로 바꿨다. 바깥을 누르면 닫힌다.",
	"· 돌아가기 단추를 우주 한량의 모양으로, 일지 글자를 13 → 15px, 왼쪽 아래 단추를 44 → 56px로 키웠다.",
	"· 밤을 더 밝게 했다(주변광 3.8배, 노출 0.9 → 1.4).",
	"· 지도에 땅 밑으로 내려가는 곳(동굴 입구, 물빛 동굴 계단, 성의 잠긴 층 계단)을 보라색으로 표시했다.",
	"· 낮은 수풀은 지나갈 수 있다. 물결이 뒤로 걷던 것을 고쳤다.",
	"",
	"2026-10-23 오후",
	"· 8장 달의 계단: 성 동문에서 정원까지 층계참 4곳(벽돌 벽, 물길, 무너진 틈, 등불 셋과 달 문).",
	"· 7장 곁지역 성 아래 잠긴 층: 물 빼기, 8초 안에 등불 넷, 큰 수호자 둘, 한결의 넷째 일기와 등잔.",
	"· Codex 시험 놀이꾼이 찾은 것: 동굴의 잠긴 문을 옆으로 돌아가던 길을 막고, 통로 바닥을 밝히고, 미니맵에 들어온 곳과 열쇠를 표시했다.",
	"· 물수제비로 다리 너머 빈 곳을 달리던 것, 동굴에서 동료가 사라지던 것, 동굴을 나오면 이야기가 되돌아가던 것을 고쳤다.",
	"",
	"2026-10-23 낮",
	"· 설정 창을 더했다 (Esc 또는 왼쪽 아래 설정 단추).",
	"· 밤이 여름처럼 짧아졌다: 21시에 어두워지고 4시면 밝아온다.",
	"· 밤에 소라가 너무 어둡던 것을 고쳤다. 등불 곁에서는 환해진다.",
	"· 보리 할머니도 E로 말을 건다. 5시 방향 걸음과 동료들의 방향을 바로잡았다.",
	"· 물빛 동굴이 밝아지고, 나가는 계단과 내려가는 계단이 잘 보인다.",
	"",
	"2026-10-23 밤",
	"· 새 지역: 섬 밑 물빛 동굴, 언덕 위 구름 둔덕, 가라앉은 달지기 성.",
	"· 새 보스: 벽돌 게, 벽돌 허수아비, 벽돌 기사. 새 괴물: 벽돌 늑대, 벽돌 박쥐.",
	"· 곁이야기: 지도 조각, 반딧불 병, 달 순서 돌, 다람쥐, 울림 수정, 바람개비 경주, 낚시, 달꽃, 집 안, 도란의 편지, 등불 축제, 서재의 책.",
	"· 달빛 시련, 세 돌단, 일지(Q), 달빛 길돌, 도전 과제, 새 바퀴.",
]

# ---- settings (modelled on Space Oddity's 설정): opened by the 설정 button or Esc, the world waits while it is open.
# Head: sound on/off and text size 가- / 가+. Tabs: Settings (comfort and display), Help (controls), Changes, About.
# Saved apart from the game in user://settings.json, so F9 (start over) keeps them.
const TEXT_SIZES := [0.85, 1.0, 1.15, 1.3]
var cfg := {"text": 1, "shake": true, "tilt": true, "nums": true}
var settings_open := false
var set_tab := 0
var tilt_rect: ColorRect
var text_bases: Array = [] # [Label, base size] scaled by the text size setting

# ---- the look shared by the menus, taken from Space Oddity's style.css (the user asked for its menus):
# navy glass buttons with a thin pale line that brighten under the mouse, gold for what is chosen,
# dialogs in #091627 with a #53718b line, 14 px corners and a deep shadow. Icons are its line drawings.
var menu_theme: Theme
var icon_cache := {}

# ---- companions talk now and then: when Sora has stood still about 9 s with no monster within 8 tiles,
# Mulgyeol or Noeul says a short line in a speech balloon (one fitting the place or the night when there is one);
# sometimes the other answers. 14 - 24 s between lines.
var chat_t := 0.0
var chat_cd := 6.0

# a speech balloon: a cream rounded card with a brown rim and a little tail pointing down at the speaker,
# drawn once per width and kept
var balloon_cache := {}

var bubbles_said := 0 # counted for the tests

# a short talk at rest: each line in its speaker's balloon, 2.4 s apart; Sora's balloon stands where she rests
var talk_id := 0          # bumped to cut a rest talk short
var talks_heard := {}     # story rest talks already told (saved)

var talk_bubbles: Array = [] # balloons of the talk now running

# ---- villagers chatter (the user, 2026-10-25: "NPC들도 잡담을 한다. 상황에 맞는 잡담을 각각 10개씩"; GPT wrote the
# 120 lines in STORY.FOLK_CHAT). With Sora within 4 tiles a villager now and then (15 - 25 s apart for each, one
# balloon at a time, 4 s apart) says a line whose tags all fit, in a balloon like the companions'. Never in a story,
# the shop, the journal, a menu or a house, near a monster, or from someone asleep.
var folk_chat_off := false    # the autoplay tests keep the villagers quiet (all but folk_chat)
var folk_chat_cd := {}        # id -> seconds until he may speak again
var folk_chat_gap := 0.0      # seconds until any villager may speak
var folk_chat_last := {}      # id -> his last line, not said twice running
var folk_said: Array = []     # [id, line] said, for the tests
var folk_bubbles: Array = []  # [{"anchor": Node3D, "id": String, "t": float}]: balloons that follow their speaker

var stairs_q_shown := ""

const STAIRS_DONE_QUEST := "꼭대기 문을 지나 정원으로 가자"

# ---- five drafts for a new sword swing (scene swing_designs), drawn as they look a little past mid-swing.
# prog 0 -> 1 runs the swing: the arc grows from its start and its tail thins out.

# the sword swing: a thin gold line sweeps along the arc, bright at its head and fading to nothing at its tail,
# and diamond sparks fly off its outer side (draft 3 "금빛 별가루", the user's pick of five on 2026-10-23).
# A spin or a slam draws the whole gold ring and throws sparks all round.
var swing_line_cache := {}
var spark_mats: Array = []

# ---------------------------------------------------------------- sound
# tiny synth: renders a short tone to a 16-bit WAV and plays it once
var sfx_cache := {}

var sfx_log: Array = []      # "wave:freq" of every sound played, read by tests

# footsteps: a grass rustle, or a hollow knock on bridge planks; a few cached variants
var step_frame := -1

# Footsteps: soft and varied so they sit under the music of the marsh, not on top of it.
# A grass step is a short brush of filtered noise with a gentle fade in; a bridge step is a quiet knock.
var last_step := -9.0

# moves that open with level (the banner names them when they arrive)

const SKILL_CD := [3.0, 1.2, 6.0]
var skill_up := -1           # the skill woken at the cave shrine: 0 whirl, 1 ember bolt, 2 radiant nova
var shrine_seen := false
var shrine_nodes: Array = []

func in_marsh() -> bool:
	return not (in_cave or in_village or in_forest or in_lake or in_hill or in_garden)

# Space (the old key, no longer shown anywhere) and the end of E: doors, chests, cupboards, the shop
func interact() -> void:
	if in_cave and cave_interact():
		return
	if in_village and in_house >= 0 and folk.cupboard_key():
		return
	if in_village and in_house >= 0 and Vector2(player.x, player.z).distance_to(HOUSE_EXIT) < 0.95 and fade_rect.color.a == 0.0:
		fade_then(leave_house) # E at the door inside goes out, as walking onto it does
		return
	if in_village and in_house < 0 and folk.house_door_near() >= 0 and fade_rect.color.a == 0.0:
		var hi := folk.house_door_near()
		fade_then(func(): enter_house(hi))
		return
	if shop.near_shop() and doran_q == 2 and not shop_open:
		deliver_letter()
		return
	if shop.near_shop() and post_q == 3 and doran_q >= 3 and not shop_open:
		post_q = 4
		player.pots += 2
		show_story("", post_bori_lines())
		save_game()
		return
	if shop.near_shop() and not shop_open and errands.deliver(0, STORY.MAIL_BORI):
		return
	if shop.near_shop() and marsh.picked_count() == 3 and not has_tea and not shop_open:
		has_tea = true
		show_story("", STORY.MOON_TEA)
		save_game()
		return
	if shop.near_shop() and not shop_open and shore.shore_bori():
		return
	if shop.near_shop():
		toggle_shop(not shop_open)
		return
	if in_grotto() and lake_zone.grotto_key():
		return
	if in_cloud() and hill_zone.cloud_key():
		return
	if in_forest and forest.solved and not forest.chest_open and Vector2(player.x, player.z).distance_to(forest.marks.c) < 1.6:
		forest_zone.open_grove_chest()
		return
	if in_marsh() and marsh.near_chest(self):
		marsh.open_chest(self)
		return
	for c in chests:
		if not c.open and Vector2(c.x - player.x, c.z - player.z).length() < 1.5:
			c.open = true
			c.node.texture = chest_open_tex
			var g := 15 + rng.randi() % 15
			player.gold += g
			player.pots += 1
			burst(Vector3(c.x, height_at(c.x, c.z) + 0.6, c.z), Color("#ffd84a"), 30, 3.0)
			toast(tr("금화 %d닢과 회복약을 찾았다") % g)
			sfx(784, 0.12, "triangle", 0.25)
			get_tree().create_timer(0.1).timeout.connect(func(): sfx(1046, 0.25, "triangle", 0.25))
			return
	toggle_lantern()

func toggle_lantern() -> bool:
	var best: OmniLight3D = null
	var bd := 1.5
	for l in lanterns:
		if l == dark_lamp or not l.has_meta("glass") or (l.get_meta("dark", false) and not l.get_meta("sora_off", false)):
			continue
		var d := Vector2(l.position.x - 0.3 - player.x, l.position.z - player.z).length() # the post stands 0.3 left of the lamp
		if d < bd:
			bd = d
			best = l
	if best == null:
		return false
	var g: MeshInstance3D = best.get_meta("glass")
	if not g.has_meta("lit_mat"):
		g.set_meta("lit_mat", g.material_override)
	var off: bool = not best.get_meta("sora_off", false)
	best.set_meta("sora_off", off)
	best.set_meta("dark", off)
	g.material_override = mat_color(Color("#3a3428")) if off else g.get_meta("lit_mat")
	sfx(330 if off else 660, 0.12, "triangle", 0.18)
	if not off:
		burst(best.position, Color("#ffd27a"), 12, 1.5)
	toast("등불을 껐다" if off else "등불을 켰다")
	return true

# ---------------------------------------------------------------- day and night
# The clock runs on its own: one in-game hour every DAY_SPEED seconds (a full day in 6 minutes).
# Light, fog and sky blend between these key hours; T skips ahead three hours.
const DAY_SPEED := 15.0

var hour := 16.5
var day := 0                 # counts noons; the moon runs an 8-night cycle

var sun_el := 0.55
var night := 0.1
var beams := 1.0

# ---------------------------------------------------------------- story illustrations
# A full-screen illustration with a caption box; any key or click turns the page, the last one closes it.
var story_open := false
# story progress: 0 = not started, 1 = touch the crown (E), 2 = go to the cottage, 3 = met Bori
var story_step := 0
var dark_lamp: OmniLight3D = null
var dark_glass_mat: Material = null

# story step 5: the Brick King falls, the blocked waterway breaks free and a cave mouth opens
var cave_pos := Vector2(-99, -99)
var veg_meshes: Array = []
var chest_shut_tex: Texture2D = null
var chest_open_tex: Texture2D = null # the field chests' opened picture (world_build.build_chests)
var cottage_at := Vector2(-1, -1) # Bori's cottage in the marsh, for its minimap mark

# the quest line after the Brick King (GPT playtest 2: the old demo's "next chapter" text made players stop at an
# open cave); saves holding the old text get the new one on load
const CAVE_QUEST := "열린 동굴 입구로 내려가자"
const MURAL_PICTURE := "res://art/story/06_cave_mural.jpg" # the cave wall's mural alone, before Noeul steps in

# ---------------------------------------------------------------- save
# Saved to user://save.json (on the web this lives in the browser's IndexedDB) every 5 s
# and at story beats. F9 wipes it and restarts.
var SAVE_PATH := "user://save.json"
var save_t := 0.0
var loaded := false

# v0.0.45: the bracelets wind, not the crown; quests saved before say 왕관

var cave_light: OmniLight3D

# ---------------------------------------------------------------- village (story step 8)
const VILLAGE := preload("res://village.gd")
var village = VILLAGE.new()
const FOREST := preload("res://forest.gd")
const Ko := preload("res://sys/korean.gd")
var forest = FOREST.new()
var in_forest := false
const HILL := preload("res://hill.gd")
var hill = HILL.new()
var in_hill := false
var hill_q := 0            # 0 never entered, 1 winding the mills, 2 bridge up, 3 hawk beaten
var mate2: Node3D          # Noeul as a second companion (after he turns in the forest)
var mate2_cd := 0.0
const LAKE := preload("res://lake.gd")
var lake = LAKE.new()
var in_lake := false
var lake_q := 0            # 0 not yet, 1 at the lake, 2 thawed, 3 on the island (turtle), 4 Mulgyeol joined
var lake_npc: Sprite3D     # Mulgyeol waiting on the pier before he joins
var mate: Node3D           # Mulgyeol as a companion
var mate_cd := 0.0
const GARDEN := preload("res://garden.gd")
const MARSH := preload("res://marsh.gd")
const GROTTO := preload("res://grotto.gd")
const CLOUD := preload("res://cloud.gd")
const CASTLE := preload("res://castle.gd")
const STAIRS := preload("res://stairs.gd")
var stairs = STAIRS.new()
const UNDER := preload("res://undercroft.gd")
var under = UNDER.new()     # 성 아래 잠긴 층, a side zone under the castle's great hall (Sora is still in_hill there)   # 달의 계단 from the castle's east gate up to the garden (Sora is still in_hill there)
var stairs_spawned := false
var castle = CASTLE.new()   # 가라앉은 달지기 성 between the hill and the garden (Sora is still in_hill in there)
var castle_q := 0           # 0 never entered, 1 inside, 2 fighting the knight, 3 knight beaten (east gate open)
var castle_spawned := false
var has_armour := false
var has_bookmark := false   # 달지기 책갈피 for reading all five library books: experience x1.2
var has_tea := false        # 달꽃 차 from Bori: resting fills a pip in 6 s by a lantern (12 s with the jar)     # 달지기 갑옷 from the castle treasury: damage taken x0.85
var cloud = CLOUD.new()     # 구름 둔덕 above the hill (Sora is still in_hill up there)
var cloud_q := 0            # 0 never entered, 1 inside, 2 fighting the scarecrow, 3 scarecrow beaten
var cloud_chest := false
var cloud_spawned := false
var has_feather := false    # 바람 깃털: a dodge costs 15 stamina instead of 25
var gust_dir := Vector2.ZERO # a wind vent is carrying Sora this way
var gust_t := 0.0
var gust_gap := false
var gust_solid := 0.0
var on_vent_prev := false
var grotto = GROTTO.new()   # 물빛 동굴 under Mulgyeol's island (Sora is still in_lake down there)
var grotto_q := 0           # 0 never entered, 1 inside, 2 fighting the crab, 3 crab beaten, 4 pearl taken
var grotto_side := false    # the side-room chest is open
var grotto_spawned := false
var has_pearl := false      # 물빛 진주: stamina refills 1.5 times as fast
var marsh = MARSH.new()     # the map scraps and the moonkeeper chest
var garden = GARDEN.new()
var in_garden := false
var garden_q := 0          # 0 never entered, 1 inside, 2 fighting the mold, 3 the villagers' lights are coming, 4 ready to wind, 5 wound (the end)
var mold_wave := {}        # the mold's expanding shock ring: {"r": radius, "node": MeshInstance3D}
var ring_k := -1           # the ring post the villagers are lighting now (-1: not lighting)
var ring_t := 0.0          # seconds spent on this post
var forest_q := 0          # 0 never entered, 1 walking the forest, 2 second duel, 3 Noeul turned
var in_village := false
var crown_pips := 8        # the bracelets' moon gauge, 0..pip_max
var pip_max := 8           # v0.0.47: 8 at the start, +1 at the letter, the turtle, the thirteenth lantern and the knight
var pip_awards := {}       # "letter", "turtle", "lantern", "knight": that place gave its pip (saved, kept into a new round)
var pip_note := ""         # an old save got its pips back: said once the title closes
var pip_flash := 0.0
var rest_t := 0.0
var met := {}               # villagers already greeted
var errand := 0            # 0 not given, 1 lighting lanterns, 2 lanterns done, 3 rewarded
var kid_q := 0             # Kongal's errand: 0 not given, 1 find the kid goblin, 2 it follows Sora, 3 home
var kid_node: Node3D
var fly_q := 0             # errand 5, the kid's firefly jar: 0 not given, 1 catching, 2 caught five, 3 jar lent to Sora
var jar_node: Node3D       # Sora's firefly jar, a little glow at her side after dark once fly_q is 3
var mul_q := 0             # Mulgyeol's oar: 0 not given, 1 fetch it from the NW pond, 2 carrying it, 3 returned
var oar_node: Node3D
var night_q := 0           # the lantern night: 0 not yet, 1 chasing Noeul, 2 fell, 3 duel, 4 won
var has_unbrick := false   # crown power 3 (벽돌 풀기), granted after the duel
var noeul_node: Node3D     # Noeul during the chase (the duel uses an enemy entry)
var noeul_way := 0
var after_story := Callable() # runs once when the current story closes
var doran_q := 0           # Doran's letter: 0 not given, 1 read it with the crown, 2 carry it to Bori, 3 delivered

const SIMJI_QUEST := "광장의 등불지기에게 말을 걸자 (E)"

# ---- the gauge grows (GPT chose the places, shots/plans/pips_plan.md): the first time each of the four is done
# a pip wakes, up to 12. Returns the narration line for the scene (none when the place gave its pip before).

# E key, the one action key (v0.0.48; the user: "아이템 사용하는건 보통 E 아닌가? ... 동일성 있게 해줘"): talk first,
# then the bracelet's uses (lamps, bricks, waystones, fishing), then whatever Space opens (houses, chests, cupboards)
func crown_key() -> void:
	var me := Vector2(player.x, player.z)
	if waystones.way_key():
		return
	if in_marsh() and shop.near_shop(): # Bori answers to E like every other villager (Space still works)
		interact()
		return
	if in_marsh() and story_step >= 3 and shore.shore_key():
		return
	if in_cave and cave.post_key():
		return
	if in_cave and cave.shrine_key():
		return
	if in_forest:
		if forest_zone.oak_key():
			return
		if forest_zone.hollow_key():
			return
		if forest_zone.grove_key():
			return
		if forest_zone.try_unbrick():
			return
	if in_clock() and garden_zone.clock_key():
		return
	if errands.ng_key():
		return
	if in_garden and garden_q == 4:
		final_wind()
		return
	if in_garden and not in_clock() and garden_zone.road_key():
		return
	if in_garden and garden_q == 1 and garden_zone.seal_key():
		return
	if in_grotto() and lake_zone.grotto_key():
		return
	if in_cloud() and hill_zone.cloud_key():
		return
	if in_workshop() and workshop_zone.work_key():
		return
	if in_stairs() and castle_zone.stairs_key():
		return
	if in_under() and castle_zone.under_key():
		return
	if in_castle() and castle_zone.castle_key():
		return
	if in_village and in_house < 0 and market.magpie_key():
		return
	if (in_lake and not in_grotto() or in_village) and minigames.fish_key():
		return
	if in_village and in_house < 0 and market.market_key():
		return
	if in_lake and not in_grotto() and Vector2(player.x, player.z).distance_to(lake.marks.h) < 2.0 and errands.deliver(2, STORY.MAIL_HUT):
		return
	if in_lake and not in_grotto() and lake_zone.south_key():
		return
	if in_lake and lake_zone.lake_key():
		return
	if in_hill and minigames.trial_key():
		return
	if in_hill and player.x < GROTTO.GROTTO_X - 0.5 and hill_zone.mill_key():
		return
	if in_hill and minigames.race_key():
		return
	if in_hill and hill_zone.hill_key():
		return
	if in_village:
		if folk.cupboard_key():
			return
		if hollow_q == 3 and me.distance_to(village.marks.M) < 1.8:
			simji_lantern()
			return
		if workshop_zone.simji_key():
			return
		if me.distance_to(village.marks.M) < 1.8 and errands.deliver(1, STORY.MAIL_SIMJI):
			return
		if errands.festival_key():
			return
		if me.distance_to(village.marks.M) < 1.8:
			if errand == 0:
				errand = 1
				show_story("", STORY.SIMJI)
				set_quest("동쪽 끝 꺼진 등불을 팔찌로 켜자 (E) 0/3")
			elif errand == 2:
				errand = 3
				crown_pips = pip_max
				player.gold += 60
				player.pots += 1
				show_story("", STORY.SIMJI_DONE)
				set_quest("광장 서쪽의 콩알이 울고 있다. 말을 걸어 보자 (E)")
			save_game()
			return
		if asleep_hint(me):
			return
		var near_id := ""
		for fid in village.folk_pos: # by day where they stand, by night in bed at home; the nearest one answers
			var dd := me.distance_to(folk_talk_at(fid))
			if dd < 1.6 and (near_id == "" or dd < me.distance_to(folk_talk_at(near_id))):
				near_id = fid
		for id in village.folk_pos:
			if id == near_id:
				if STORY.HINT_FOLK.has(id):
					errands.hint_folk_talk(id)
					return
				if id == "kongal" and errand >= 3 and kid_q != 1 and (kid_q != 3 or doran_q < 3 or fly_q < 3):
					met[id] = true
					errands.kongal_errand()
					return
				if id == "mulgyeol" and doran_q >= 3 and mul_q != 1:
					var first := not met.has(id)
					met[id] = true
					errands.mulgyeol_errand(first)
					return
				if id == "doran" and kid_q >= 3 and doran_q < 2:
					met[id] = true
					errands.doran_errand()
					return
				if id == "doran" and doran_q >= 3 and lake_q >= 4 and mail_q < 2 and mail_errand():
					met[id] = true
					return
				folk_talk(id)
				met[id] = true
				save_game()
				return
		if errand == 1:
			for d in village.dark:
				if not d.lit and me.distance_to(d.pos) < 1.6:
					if not spend_pips(village_life.lamp_cost()):
						return
					village_life.light_village_lamp(d)
					return
	if story_step == 1 and dark_lamp != null: # the opening: the first touch of the bracelet
		story.touch_crown()
		return
	interact() # nothing of the bracelet's own here: E also enters houses and opens chests and cupboards (v0.0.48)

# ---- six working villagers who drop hints (v0.0.35; the user: "마을이 너무 썰렁해", "실마리만 말해주는 npc"):
# woodcutter Dusol, miner Chadol, farmer Saecham, fisher Yeoul (Dusol's sister), weaver Darae and her grandson Tori.
# E: the first lines once; then a story beat whose milestone is reached and not yet told (the third gives a gift);
# otherwise a hint for a side quest that is open now and unfinished, a different one each talk; else an idle line.
var hf_seen := {}           # id -> beat indices already told (saved)
var hf_turn := {}           # id -> talks spent on hints, to cycle them
var has_bait := false       # 미끼 주머니 from Yeoul: fish bite 30% sooner, kept into a new round

var letter_back := false # Hangyeol's letter given back to Doran after Bori read it (saved)

const NIGHT_REST_QUEST := "마을 심부름을 모두 마쳤다. 밤이 되면 마을에서 쉬자"

# ---- five squirrels shut in brick cages around the forest: three sword hits break a cage.
# Freeing all five gets the acorn: potions heal 65 instead of 45. Companions leave the cages to Sora.
var cages_spawned := false
var has_acorn := false

# ---- the forest's south valley (chapter 5 side zone, DESIGN.md "숲 남쪽 잠든 골짜기"). After Noeul joins,
# her cloak scrap opens the grey gate under the clearing. Three memory lamps give back her story, the empty
# cloak rises in the middle yard, and of three picture doors the sunset (노을, her name) hides her hollow:
# Hangyeol's letter and the thirteenth lantern, which Simji hangs at the village's east gate.
var hollow_q := 0          # 0 gate shut, 1 open, 2 the empty cloak beaten, 3 holding the thirteenth lantern, 4 given to Simji
var hollow_spawned := false
var stream_told := false
var door_seen := -1        # the picture door last named in a toast
var thirteenth: Node3D = null

# ---- 다람쥐 나무 (chapter 5, DESIGN.md): with the five squirrels free and the grey gate open, the big squirrel
# scratches at a gap in the trees in the middle of the forest; E there and a tree steps aside onto a hidden clearing
# with the forest's oldest acorn oak. Its living roots warm the valley's stream, and Sora rests by it even by day.
# Three brick knots on its roots come loose with the crown (1 pip each, each root drawing in toward the trunk; two
# brick hedgehogs roll out after the second); after the last, 1.5 s with no lines while the tree breathes once, then
# it greens and the five squirrels come back to sit in it. Lines, props and colours reworked with GPT's notes.
var oak_q := 0                # 0 the gap shut, 1 open, 2 the oak green again
var has_sprout := false       # 싹 튼 도토리: potions heal 75, kept into a new round
var oak_told := false         # the clearing's lines this session (not saved)
var squirrel_seen := false    # the big squirrel's first toast this session (not saved)
var oak_hush := false         # the 1.5 s after the last knot
var oak_hogs_up := false      # the two hedgehogs rolled out this session (a load clears them)
var oak_hogs_beaten := false  # both down (saved): the last knot waits for this
var big_squirrel: Node3D = null
var oak_kin: Array = []       # the other four squirrels, in the crown once it is green
var steam_t := 0.0

# ---- the south lake and Mulgyeol joining (between the lantern night and the forest)
const LAKE_RETRY_QUEST := "마을 남쪽 문으로 호수에 나가, 부두의 물결에게 말을 걸자 (E)"

# ---- 물지기의 아랫못 (DESIGN.md, chapter 4): the water keeper's lower pond below Mulgyeol's island. Unwind the weir,
# then send Mulgyeol down the rope posts' chains (only the otter reaches them): the first raises four stepping
# stones, the second holds the yard's grate up while Sora goes in alone. The chain snaps out of his hands, the grate
# drops and three bricks rise; beating them breaks the bricked latch. Winding the water clockwork's key sets the
# lake's water running its whole round again (golden carp 5 -> 15); the keeper's tin holds his last page and the
# whistle (Mulgyeol gets up in 5 s, not 10). Eight foes, once.
var south_q := 0             # 0 shut, 1 weir unwound, 2 stones up, 3 latch broken (grate up), 4 clockwork wound, 5 tin
var has_whistle := false
var south_spawned := false
var south_hint_seen := false
var south_shed_seen := false
var south_fish_told := false
var grotto_turn_told := false
var south_ambush_on := false
var south_latch_t := -1.0
var mate_job := {}           # Mulgyeol sent down a chain: state swim / pull / hold / back / wait, "to", "home", "t"

var has_shard := false      # 구름 조각: skill cooldowns x0.8

# ---- 달지기 숙소 (chapter 7, DESIGN.md): the moonkeepers' quarters under the throne room. The knight's rusty spring
# opens the clockwork door; six bricks in the dining hall and the basket room (once a session); the tally board with
# Hangyeol's last basket and his note on the workshop stand; the crown winds the tin doorkeeper (1 pip) and Sora sees
# him to the bunk room while three brick bits from the heaps run at him (one that reaches him knocks his spring out;
# E beside him walks him on). In the bunk room reading the ledger and writing her name is one beat; then he sits and
# gives the small buckler (flash guard 0.12 -> 0.16 s). Lines and props reworked with GPT's notes.
var quarters_q := 0           # 0 not yet, 1 spring picked up, 2 door open, 3 doorkeeper wound, 4 bunk room open, 5 he rests
var quarters_box := false
var has_buckler := false      # 작은 놋 방패, kept into a new round
var quarters_again := false   # the buckler came from an earlier round: the chest and his greeting say less
var quarters_spawned := false # the six bricks this session (not saved)
var quarters_named := false   # the zone line says 달지기 숙소
var stand_seen := false       # the stand's lines seen this session (not saved)
var basket_seen := false
var doll_at := Vector2(447, 36)
var doll_i := 1               # the next point of CASTLE.DOLL_PATH
var doll_walk := false
var doll_wait := false        # Sora more than 12 tiles behind: he waits (on again inside 6)
var doll_shed := false        # the heaps' bits came for this walk
var doll_t := 0.0
var tally_seen := false       # the tally board read this session (not saved)
var quarters_mark: Label3D    # the gold "!" over the next thing to do in the quarters

# companions in narrow places (GPT playtest 2026-10-24: both stood on Sora in the oak's one-tile gap). The side step
# when it and the way to it are open; else single file on Sora's footsteps (Mulgyeol 1.3 tiles back, Noeul 2.5);
# when she stands still (or has no footsteps yet) the nearest open spot around her, 1 tile clear of the other.
var mate_trail: Array = []  # Sora's footsteps, newest first, 0.3 tiles apart
var mate_idle := 0.0        # seconds she has stood still
var mate_spot := {}         # id -> [where she stood, the open spot found there]
var mate_aim := {}          # id -> this frame's goal (Noeul keeps clear of Mulgyeol's)

# ---- companions' health: goblins and thrown bricks can hit Mulgyeol and Noeul too. At 0 a companion sits out
# for 10 s (lying down, no attacks), then gets up with half health; out of a fight they heal 4 HP a second.
var mate_hp := {"mulgyeol": -1.0, "noeul": -1.0}  # -1: not set yet (full)
var mate_down := {"mulgyeol": 0.0, "noeul": 0.0}

# ---- Noeul sits down while Sora rests (v0.0.47, picture drawn with GPT: art/folk/noeul_rest.png, one 172 x 180 cell
# with the feet line of noeul.png, so the same offset keeps his seat on the ground). Up again when she moves or a
# monster comes within 7 tiles.
var noeul_tex: Texture2D
var noeul_rest_tex: Texture2D
var noeul_sitting := false
# ... and Mulgyeol too (v0.0.54, art/folk/mulgyeol_rest.png, 172 x 180, drawn at the standing sprite's scale; the offset
# goes 85 -> 90 so the seat stays on the ground)
var mulgyeol_tex: Texture2D
var mulgyeol_rest_tex: Texture2D
var mulgyeol_sitting := false

# ---- 참새 방앗간 (DESIGN.md, chapter 6): below the wind hills' south fence, a windless hollow with an old mill.
# Unwind the broken wall (after the hawk), wind the big windmill, then run past four pinwheels within 12 s from the
# post to call the wind down: the mill fills its channel and a big guardian rises at the mouth. Over the water by
# the skip: the flour boat, the landing bell and the miller's chest (the oar ring: Mulgyeol hits 60 -> 70%).
# Seven foes and the guardian come once; calling the wind again pays nothing.
var mill_q := 0          # 0 shut, 1 wall unwound, 2 big windmill wound, 3 wind called (water in), 4 guardian down, 5 chest
var has_oar_ring := false
var mill_spawned := false
var mill_hint_told := false
var mill_in_told := false
var windrun_on := false
var windrun_left := 0.0
var windrun_got: Array = []
var windrun_nodes: Array = []
var windrun_quest := ""
var windrun_tries := 0 # missed runs since she came to the hill: each makes the next 2 s longer
var windrun_glide := {} # the gust back to the wind post after a missed run: from, to, t, dur

# ---- the heart of the garden (story steps 11 and 12)
const GARDEN_RETRY_QUEST := "정원 한가운데로 돌아가 굳은달 거푸집에 다시 맞서자"

# ---- 한결의 마지막 길 (DESIGN.md, chapter 8 to 9): the yard below the arena where Hangyeol camped the night
# before he went in. Root bricks, his camp (the empty hook for the thirteenth lantern, his fifth page, a blanket),
# his footprints over the deep gap that show for 3 s when the crown shines, and the brick Hangyeol the mold cast
# of him. Beating it opens the grey gate into the arena. Six foes, once; the echo pays 200 XP and 100 gold once.
var road_q := 0          # 0 not yet, 1 arrived, 2 roots unwound, 3 fifth page read, 4 the brick Hangyeol down
var road_box := false    # the blanket opened
var road_spawned := false
var road_camp_told := false

var ending_due := false # loaded a save made during the winding lines: the ending plays on start

# ---- 큰 태엽 방 (DESIGN.md, after the ending of chapter 8 to 9): the room of the land's big clockwork under the
# arena, a side story to visit after the end. The hole opens where the mold sat. Three gears the mold left hardened
# hold the key: the crown frees each (1 pip) while mold scraps (2, 3, 4) run from the key to harden it again; brick
# workers rise and tend the freed gears. The crown goes into the key's slot, the villagers come down, and eight push
# together on a gold beat ring (E eight times). The chest holds the moonkeeper's oil (a potion also gives 20
# momentum). Nine scraps, once per gear; nothing here hurts Sora. The ending itself stays where it was.
const CLOCK_HANDS := ["sora", "noeul", "doran", "worker", "simji", "kid", "kongal", "mulgyeol"] # spoke k from the south, turning east
var clock_q := 0              # 0 not yet, 1 the hole open, 2 down in the room, 3 gears freed, 4 crown in the key, 5 wound
var clock_gears := [false, false, false] # west, east, north freed (true only once their scraps are cut down)
var clock_box := false
var clock_late := false       # a save that saw the ending before the room was added
var has_oil := false          # 달지기 기름병: a potion also gives 20 momentum
var clock_hint_told := false
var clock_wave := {}          # the scraps let loose by freeing a gear: "gear", "t", "spawned", "done"
var clock_say_t := -1.0       # a story held back a moment (the workers tend the gear first)
var clock_say: Array = []
var beat := {}                # the gold ring closing on the key: "r", "node", "thick", "rim", "n", "hit", "win"
var clock_hop := 0.0          # everyone at a spoke hops once per push
var clock_still := false      # after the last push everyone stays at the spokes until Bori has spoken
var clock_cam := 0.0
var workers: Array = []       # [{"node", "seat", "job", "side"}] job -1 sitting, 0 - 2 the gear it tends, 3 at a spoke
var clock_folk := {}          # villagers at the spokes: id -> Node3D

# ---- 깨어난 물가 (chapter 1, DESIGN.md): where Sora woke, pressed reeds lead to a lantern basket stuck in the mud.
# The crown frees it (1 pip) and two packs of bricks rise (2 goblins, then a goblin and an archer); Bori knows the
# basket and gives her lantern, never lit in a hundred years. After the Brick King, on a night, the crown lights it
# (1 pip) and it floats about 20 tiles down the river to the lake's island; three brick snags hold it on the way
# (2, 2, then a goblin and an archer). Bori's reed cushion: resting at night by a lit lantern heals 4 HP a second.
var shore_q := 0              # 0 not yet, 1 hint seen, 2 basket out, 3 Bori's lantern, 4 floated to the island, 5 cushion
var has_cushion := false      # 갈대 방석, kept into a new round
var shore_seen := false       # the basket's lines seen this session (not saved)
var shore_wave := -1          # the pack fighting by the basket: 0 or 1, -1 none (not saved)
var shore_up := false         # that pack has risen
var shore_t := 0.0
var shore_float := {}         # floating (not saved): d along the path, next snag, wait held, up its foes, t, lit, stop, wt
var cushion_t := 0.0

# rest beside a lit lantern at night with no monster near: one pip every 6 s. A night is 105 s (21 -> 4 at 15 s an
# hour), so a full crown takes about half a night by a lantern and most of one with the jar alone (the user found
# 10 s and 20 s never filled it in one night, 2026-10-23)
var rest_need := 3.0         # seconds of rest for the next pip (lantern 3, jar 6, both x0.6 with the tea)

var fade_rect: ColorRect

var cave_spawned := false
var cave_exit_seen := false
var has_key := false
var saw_painting := false
var door_node: Node3D
var key_chest: Sprite3D

# ---- the singing crystals in the shrine room: each rings its own note when struck. Struck from the lowest note
# to the highest (the taller the crystal, the lower its note), a moonkeeper chest rises with the crystal ring:
# critical hits 15% -> 25%. A wrong note resets the run with a dull buzz.
const CRYSTAL_NOTE := [2, 0, 3, 1] # rank of each crystal's note, 0 the lowest
var crystal_run := 0         # how many notes in a row are right so far
var crystal_done := false
var has_ring := false
var crystal_chest: Node3D
var crystal_told := false

# the crystals live in their own list (not among the enemies): a sword swing in the cave checks them in attack()
var crystals: Array = []     # [{"x", "z", "node", "crystal": index, "hurt"}]

# ---- 물길 끝 굴 (DESIGN.md "옛 우편 굴", chapter 2, reworked: the cave was not a post road, the user kept only
# Bori's postcard). Below the mole's hall the stream runs on to where it washes things down from the marsh. With the
# water skip: a bend of deep water, a pool of four islands with ringing crystals (lowest note first, the shrine's
# rule) that sink a crystal grate, and a dry floor where Bori's "don't go alone" postcard to Hangyeol lies.
# Eight foes, once; the postcard goes to Bori in chapter 3.
var post_q := 0          # 0 not yet, 1 by the stream, 2 grate sunk, 3 postcard taken, 4 given to Bori
var post_run := 0
var post_told := false
var post_spawned := false
var post_gate: Node3D = null
var post_pile: Node3D = null

const CAVE_DOOR_QUEST := "열린 문 너머, 수레두더지가 있는 안쪽 방으로 가자"

var quest_before_cave := ""

# on phones the keyboard words in quest lines, toasts and story lines become the touch keys' names
var touch_e := RegEx.create_from_string("(?<![A-Za-z])E(?![A-Za-z])") # the E key alone: "(E)", "E로", "E를", "E  ", "E!"

var quest_raw := "" # the quest line as given, before the touch wording
var keys_last := false # on a touch layout: the last input was a key or a real mouse, so the words stay keyboard words

# the first road quest keeps its prep hint in step with what she carries (GPT lap 7: "buy potions" with 3 potions and 10 gold)
const BORI_QUEST := "북쪽 벽돌왕을 쓰러뜨려 물길을 열어라"

func prep_hint() -> String:
	if player.pots > 0:
		return tr("회복약은 4 키로 마신다 (%d개)") % player.pots
	if player.gold >= SHOP[0].price:
		return tr("상점에서 약을 챙기자")
	return tr("금화는 괴물을 잡으면 모인다. 약값은 %d") % SHOP[0].price

# a narrow window wraps the line: it breaks only at spaces (Ko.keep_words), so code reading it back uses Ko.plain
func quest_shown(raw: String) -> String:
	if raw.begins_with(BORI_QUEST): # old saves kept the line with its old fixed hint
		return Ko.keep_words(touch_words(tr(BORI_QUEST) + " (" + prep_hint() + ")"))
	var sleeper: String = errands.quest_sleeper(raw)
	if sleeper != "":
		return Ko.keep_words(touch_words(Ko.josa(errands.sleeping_quest(sleeper))))
	return Ko.keep_words(touch_words(Ko.josa(tr(raw))))

func set_quest(text: String) -> void:
	quest_raw = text
	ui.quest.text = quest_shown(text)
	ui.quest.visible = text != ""
var story_lines: Array = []

const STORY := preload("res://story_lines.gd")
var typing := 0.0 # characters shown so far, for the typewriter reveal
var typing_k := 1.0 # characters per letter in the shown line: the word joiners reveal with their letters, 40 letters a second
var talk_mode := false

func toast(msg: String) -> void:
	ui.toast.text = touch_words(Ko.josa(tr(msg)))
	ui.toast.modulate.a = 1.0
	toast_t = 2.2

# ---------------------------------------------------------------- input
# the title screen listens before any control can swallow the click or key
func _input(event: InputEvent) -> void:
	if touch_ui: # the words follow the input used last: touch names after a touch, key names after a key or a real mouse
		var kb: bool = (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION)
		var tc: bool = event is InputEventScreenTouch and event.pressed
		if (kb and not keys_last) or (tc and keys_last):
			keys_last = kb
			if quest_raw != "":
				ui.quest.text = quest_shown(quest_raw)
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		last_input_t = t
	# shop cards: a left click anywhere on a card buys it (handled here so no overlay can swallow it)
	if shop_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in ui.shop_btns.size():
			var card: Control = ui.shop_btns[i].get_parent()
			if card.get_global_rect().has_point(event.position):
				buy(i)
				get_viewport().set_input_as_handled()
				return
	# shop cards: a left click anywhere on a card buys it (handled here so no overlay can swallow it)
	if shop_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in ui.shop_btns.size():
			var card: Control = ui.shop_btns[i].get_parent()
			if card.get_global_rect().has_point(event.position):
				buy(i)
				get_viewport().set_input_as_handled()
				return
	if story_open and ((event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed)):
		story.next_story()
		get_viewport().set_input_as_handled()
		return
	if intro and event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		save.reset_game()
		return
	if intro and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		music.toggle_music() # the title's music key: B turns the tune off without starting
		get_viewport().set_input_as_handled()
		return
	if intro and event is InputEventMouseButton and is_instance_valid(ui.get("title_music")) and ui.title_music.get_global_rect().has_point(event.position):
		return # the button takes the click
	if intro and ((event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed)):
		start_game()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if intro or down_t > 0.0:
		return
	if shop_open:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_1, KEY_2, KEY_3, KEY_4: buy(event.keycode - KEY_1)
				KEY_SPACE, KEY_ESCAPE, KEY_E: toggle_shop(false)
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: if not touch_ui: attack() # on a phone a tap on the world is the browser's mouse; the keys act
			MOUSE_BUTTON_RIGHT: if not touch_ui: dodge()
			MOUSE_BUTTON_WHEEL_UP: cam_dist = clampf(cam_dist - 1.2, 8, 26)
			MOUSE_BUTTON_WHEEL_DOWN: cam_dist = clampf(cam_dist + 1.2, 8, 26)
	if settings_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			toggle_settings(false)
		return
	# Esc on the journal or the controls sheet closes it and goes back to the game (the user asked for this)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and (ui.journal.visible or ui.help.visible):
		toggle_journal(false)
		toggle_help(false)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not way_open:
		toggle_settings(true)
		return
	if way_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode < KEY_1 + WAY_NAMES.size():
			waystones.travel(event.keycode - KEY_1)
			return
		if event.keycode == KEY_ESCAPE:
			waystones.toggle_ways(false)
			return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J: attack()
			KEY_K: dodge()
			KEY_U, KEY_1: use_skill(0)
			KEY_I, KEY_2: use_skill(1)
			KEY_O, KEY_3: use_skill(2)
			KEY_4: drink_potion()
			KEY_SPACE: interact()
			KEY_T: daynight.skip_time(3.0)
			KEY_R:
				raining = not raining
				rain.emitting = raining
				toast("비가 내린다" if raining else "비가 그쳤다")
			KEY_P: ui.root.visible = not ui.root.visible
			KEY_H: toggle_help(not ui.help.visible)
			KEY_Q: toggle_journal(not ui.journal.visible)
			KEY_E: crown_key()
			KEY_F9: save.reset_game()
			KEY_F8: return_to_start()
			KEY_M: toggle_sound()
			KEY_B: music.toggle_music()

# ---------------------------------------------------------------- loop
func _process(dt: float) -> void:
	dt = minf(dt, 1.0 / 20.0)
	music.update(dt) # before the world waits for a sheet, a story or the shop: the tune plays on
	if hitstop > 0.0:
		hitstop -= dt
		return
	if shop_open: # the world waits while Sora shops: no clock, no monsters
		ui.shop_hint.visible = false
		return
	if settings_open: # and while the settings are open
		return
	if ui.journal.visible: # and while she reads the journal (GPT lap 7: 104 -> 62 HP over the guide)
		return
	if down_t > 0.0:
		t += dt
		sora.update_fall(dt)
		monsters.update_enemies(dt, ground_y)
		return
	if story_open:
		if ui.story_text.visible_characters != -1:
			typing += dt * 40.0 * typing_k
			ui.story_text.visible_characters = int(typing)
			if ui.story_text.visible_characters >= ui.story_text.text.length():
				ui.story_text.visible_characters = -1
		ui.story_more.modulate.a = 0.4 + 0.6 * absf(sin(t * 4.0))
		t += dt
		if not intro: # keep the camera on Sora behind the dimmed scene
			var tg := Vector3(player.x, ground_y + 0.6, player.z)
			camera.position = tg + Vector3(sin(cam_yaw) * cos(0.78) * cam_dist, sin(0.78) * cam_dist, cos(cam_yaw) * cos(0.78) * cam_dist)
			camera.look_at(tg)
		return
	t += dt
	if intro:
		cam_yaw += dt * 0.08
	if CAM_ROTATE:
		if key_down(KEY_Q): cam_yaw -= 1.6 * dt
		if key_down(KEY_E): cam_yaw += 1.6 * dt
	if key_down(KEY_Z): cam_dist = maxf(8, cam_dist - 12 * dt)
	if key_down(KEY_X): cam_dist = minf(26, cam_dist + 12 * dt)

	# movement relative to the camera
	var fwd := Vector2(-sin(cam_yaw), -cos(cam_yaw))
	var right := Vector2(cos(cam_yaw), -sin(cam_yaw))
	var mv := Vector2.ZERO
	if not intro and not shop_open:
		if key_down(KEY_W) or key_down(KEY_UP): mv += fwd
		if key_down(KEY_S) or key_down(KEY_DOWN): mv -= fwd
		if key_down(KEY_D) or key_down(KEY_RIGHT): mv += right
		if key_down(KEY_A) or key_down(KEY_LEFT): mv -= right
		if touch_move != Vector2.ZERO: # the touch stick, screen up is the camera's forward
			mv += fwd * -touch_move.y + right * touch_move.x
	var running: bool = key_down(KEY_SHIFT) and player.sp > 0 and mv.length() > 0
	var on_water: bool = tile_at(player.x, player.z) == WATER and (player.x < CAVE_X - 0.5 or skip_water(player.x, player.z))
	skip_grace = 0.6 if has_skip and running else skip_grace - dt
	skipping = has_skip and (running or (on_water and skip_grace > 0.0))
	if has_skip and not running and mv.length() > 0 and not on_water and toast_t <= 0.0:
		var ahead := Vector2(player.x, player.z) + mv.normalized() * 0.7
		if skip_water(ahead.x, ahead.y):
			toast("막대를 끝까지 밀어 달리면 물 위를 건넌다" if touch_ui else "Shift를 누른 채 달리면 물 위를 건넌다")
	if skipping and on_water:
		player.sp = maxf(1.0, player.sp - 6.0 * dt) # costs a little extra, but never runs dry mid-river
		if int(t * 8.0) != int((t - dt) * 8.0):
			burst(Vector3(player.x, -0.2, player.z), Color("#9fe0ff"), 4, 1.2)
	elif not running and on_water and not skipping:
		if rescue_glide.is_empty() and dash.is_empty():
			rescue("water") # stopped on open water: back to the nearest shore
	player.sp = maxf(0, player.sp - 22 * dt) if running else minf(100, player.sp + (27.0 if has_pearl else 18.0) * dt)
	if skipping and on_water:
		player.sp = maxf(player.sp, 1.0)
	var speed := (7.0 if has_shoes else 6.2) if running else 3.6
	var tv := Vector2.ZERO
	if mv.length() > 0:
		mv = mv.normalized()
		tv = mv * speed
		player.face = mv
	if skipping and on_water and not running: # let go for a moment: glide on in the same direction
		tv = player.face * 6.2
	if player.atk_cd > 0.1:
		tv *= 0.3
	if guarding:
		tv *= 0.4
	var blend := minf(1.0, dt * 14.0)
	player.vx += (tv.x - player.vx) * blend
	player.vz += (tv.y - player.vz) * blend
	var v := Vector2(player.vx, player.vz)
	if player.dodge > 0:
		v = Vector2(player.dvx, player.dvz)
		player.dodge -= dt
	var vent: Vector2 = hill_zone.vent_here(player.x, player.z)
	if gust_dir == Vector2.ZERO and vent != Vector2.ZERO and not on_vent_prev and player.dodge <= 0.0:
		hill_zone.start_gust(vent)
	on_vent_prev = vent != Vector2.ZERO
	if gust_dir != Vector2.ZERO:
		hill_zone.update_gust(dt)
		v = Vector2.ZERO
	if not windrun_glide.is_empty():
		hill_zone.update_glide(dt)
		v = Vector2.ZERO
	if not dash.is_empty():
		combat.update_dash(dt)
		v = Vector2.ZERO
	if not rescue_glide.is_empty():
		update_rescue(dt)
		v = Vector2.ZERO
	var nx: float = player.x + v.x * dt
	var nz: float = player.z + v.y * dt
	if gust_dir == Vector2.ZERO and windrun_glide.is_empty() and dash.is_empty() and rescue_glide.is_empty() and not player_can(player.x, player.z): # stuck in a wall (old save, knockback): glide to the nearest open floor
		rescue("stuck")
	if player_can(nx, player.z): player.x = nx
	if player_can(player.x, nz): player.z = nz

	player.atk_cd = maxf(0, player.atk_cd - dt)
	player.combo_t -= dt
	player.inv -= dt
	player.hurt_t -= dt
	for i in 4:
		player.cds[i] = maxf(0, player.cds[i] - dt)
	if t - last_hit_t > 4.0 and player.lv < 30: # from Lv30 momentum keeps
		player.mp = maxf(0.0, player.mp - 3.0 * dt)
	# guard: L or middle mouse held; remember when it started for the flash-guard window
	var g_now: bool = not intro and not shop_open and (key_down(KEY_L) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)) and player.dodge <= 0
	if g_now and not guarding:
		guard_since = t
	guarding = g_now
	if guarding and player.lv >= 4 and t - guard_since >= 1.0 and int(t * 10.0) != int((t - dt) * 10.0):
		burst(Vector3(player.x, 1.0, player.z), Color("#fff1a0"), 3, 1.0) # light gathered: J for a charged cut
	counter_t -= dt
	flash_cd -= dt
	slowmo -= dt
	ui.slowmo_tint.visible = slowmo > 0
	ui.shop_hint.visible = not intro and not shop_open and shop.near_shop()
	ui.shop_hint.text = touch_words(tr("E  편지 전하기") if doran_q == 2 else tr("E  보리 할머니의 상점"))
	if shop_open and not shop.near_shop():
		toggle_shop(false)
	if key_down(KEY_J) and player.atk_cd <= 0 and not intro and not shop_open:
		attack()
	combat.update_buffer(dt)

	# Sora: pick one of 8 screen directions
	var f: Vector2 = player.face
	var sx := f.dot(right)
	var sz := f.dot(fwd)
	const DIRS8 := ["up", "upright", "side", "downright", "down", "downleft", "left", "upleft"]
	player.dir = DIRS8[(int(round(atan2(sx, sz) / (PI / 4.0))) + 8) % 8]
	var moving := Vector2(player.vx, player.vz).length() > 0.4
	player.anim += dt * (12.0 if running else 8.0)
	var frame := int(player.anim) % 4 if moving else 0
	var still: bool = not moving and player.atk_cd <= 0.0 and player.dodge <= 0.0 and not guarding and player.hurt_t <= 0.0
	idle_t = idle_t + dt if still else 0.0
	if idle_t > 0.6:
		sora.update_idle(dt)
	else:
		idle_name = ""
		sora.set_hero_frame(player.dir, frame)
	sora.sync_ghost()
	# feet touch the ground on frames 0 and 2 of the walk cycle
	if moving and frame != step_frame and frame % 2 == 0 and player.dodge <= 0:
		sound.footstep()
	step_frame = frame
	ground_y = lerpf(ground_y, height_at(player.x, player.z), minf(1.0, dt * 10.0))
	var gy := ground_y
	var hop := sin((player.dodge / 0.32) * PI) * 0.35 if player.dodge > 0 else 0.0
	hero.position = Vector3(player.x, gy + hop, player.z)
	var blink: bool = player.inv > 0 and player.dodge <= 0 and sin(t * 40.0) < 0
	# Sora is unshaded, so tint her by hand to sit in the night light: a mild blue at night (the old 0.5 made her
	# much darker than her companions), warmed back to full by any lit lantern within 4 tiles
	var lit := Color(1, 1, 1).lerp(Color(0.8, 0.82, 0.95), night)
	var warm := 0.0
	for l in lanterns:
		if l.visible and not l.get_meta("dark", false):
			var ld := Vector2(l.position.x - player.x, l.position.z - player.z).length()
			warm = maxf(warm, clampf(1.0 - (ld - 1.5) / 2.5, 0.0, 1.0))
	if in_cave or in_grotto() or in_under() or in_workshop() or jar_node != null and jar_node.visible:
		warm = maxf(warm, 0.6) # the cave lamp on her, or the firefly jar at her side
	lit = lit.lerp(Color(1.0, 0.95, 0.86), warm * night)
	hero.modulate = Color(1, 0.5, 0.5) if player.hurt_t > 0 else Color(lit.r, lit.g, lit.b, 0.3 if blink else 1.0)
	hero_shadow.position = Vector3(player.x, gy + 0.02, player.z)
	effects.update_armour_ring(hero_shadow.position, hero_shadow.visible and hero.visible)

	monsters.update_enemies(dt * (SLOWMO if slowmo > 0 else 1.0), gy)
	if in_stairs() and not stairs.door_open and fade_rect.color.a == 0.0:
		var sq: String = castle_zone.stairs_quest()
		if sq != stairs_q_shown:
			stairs_q_shown = sq
			set_quest(sq)
	if not in_cave and story_step >= 5 and cave_pos.x > 0 and Vector2(player.x, player.z).distance_to(cave_pos) < 1.2 and fade_rect.color.a == 0.0:
		fade_then(enter_cave)
	if not in_cave and not in_village and story_step >= 7 and player.x > 46.5 and player.x < CAVE_X - 0.5 and player.z > 17.5 and player.z < 23.5 and fade_rect.color.a == 0.0:
		fade_then(enter_village)
	if in_village and Vector2(player.x, player.z).distance_to(village.marks.G) < 0.9 and fade_rect.color.a == 0.0:
		fade_then(village_life.leave_village)
	if in_village and Vector2(player.x, player.z).distance_to(village.marks.F) < 0.9 and fade_rect.color.a == 0.0:
		if lake_q >= 4:
			fade_then(enter_forest)
		elif toast_t <= 0.0:
			toast("동쪽 숲길은 회색 벽돌로 막혀 있다" if night_q < 4 else "물결 없이 혼자 가지 않기로 했다. 남쪽 호수로 가자")
	if in_forest and Vector2(player.x, player.z).distance_to(forest.marks.S) < 0.9 and fade_rect.color.a == 0.0:
		fade_then(forest_zone.leave_forest)
	if in_forest:
		forest_zone.update_forest()
	if in_forest and Vector2(player.x, player.z).distance_to(forest.marks.E) < 0.9 and fade_rect.color.a == 0.0:
		if forest_q >= 3:
			fade_then(enter_hill)
		elif toast_t <= 0.0:
			toast("노을이 길을 막고 있다")
	if in_hill and Vector2(player.x, player.z).distance_to(hill.marks.S) < 0.9 and fade_rect.color.a == 0.0:
		fade_then(hill_zone.leave_hill)
	if in_hill and Vector2(player.x, player.z).distance_to(hill.marks.X) < 0.9 and fade_rect.color.a == 0.0:
		if hill_q >= 3:
			fade_then(enter_castle)
		elif toast_t <= 0.0:
			toast("벽돌 매가 하늘을 지키고 있다")
	if in_hill and not in_cloud() and Vector2(player.x, player.z).distance_to(hill.marks.U) < 0.8 and fade_rect.color.a == 0.0:
		if hill_q >= 3:
			fade_then(enter_cloud)
		elif toast_t <= 0.0:
			toast("바람구멍에서 거센 바람이 솟는다. 벽돌 매가 하늘에 있는 동안은 위험하다")
	if in_cloud() and gust_dir == Vector2.ZERO and Vector2(player.x, player.z).distance_to(cloud.marks.S) < 0.7 and fade_rect.color.a == 0.0:
		fade_then(hill_zone.leave_cloud)
	if in_cloud() and cloud_q == 1 and not story_open and gust_dir == Vector2.ZERO and Vector2(player.x, player.z).distance_to(cloud.marks.K) < 6.0:
		cloud_q = 2
		show_story("", STORY.SCARE_IN)
		after_story = hill_zone.spawn_scarecrow
		save_game()
	if in_castle() and gust_dir == Vector2.ZERO and Vector2(player.x, player.z).distance_to(castle.marks.S) < 0.7 and fade_rect.color.a == 0.0:
		fade_then(castle_zone.leave_castle)
	if in_castle() and Vector2(player.x, player.z).distance_to(castle.marks.E) < 0.8 and fade_rect.color.a == 0.0:
		if castle_q >= 3 or garden_q >= 1:
			fade_then(enter_stairs)
		elif toast_t <= 0.0:
			toast("동쪽 문이 굳게 닫혀 있다")
	if in_castle() and gust_dir == Vector2.ZERO and Vector2(player.x, player.z).distance_to(UNDER_STAIR) < 0.6 and fade_rect.color.a == 0.0:
		fade_then(enter_under)
	if in_under() and fade_rect.color.a == 0.0:
		castle_zone.update_under(dt)
	if in_castle():
		workshop_zone.update_castle()
	if in_workshop() and fade_rect.color.a == 0.0:
		workshop_zone.update_work(dt)
	if in_stairs() and gust_dir == Vector2.ZERO and Vector2(player.x, player.z).distance_to(stairs.marks.S) < 0.8 and fade_rect.color.a == 0.0:
		fade_then(castle_zone.leave_stairs)
	if in_stairs() and Vector2(player.x, player.z).distance_to(stairs.marks.N) < 0.8 and fade_rect.color.a == 0.0:
		fade_then(enter_garden)
	if in_castle() and castle_q == 1 and castle.door_open and not story_open and gust_dir == Vector2.ZERO and Vector2(player.x, player.z).distance_to(castle.marks.K) < 5.0:
		castle_q = 2
		show_story("", STORY.KNIGHT_IN)
		after_story = spawn_knight
		save_game()
	if in_castle():
		castle_zone.update_quarters(dt)
	castle_zone.update_quarters_mark()
	if in_hill:
		hill_zone.update_hill(dt)
	if in_garden and Vector2(player.x, player.z).distance_to(garden.marks.S) < 0.9 and fade_rect.color.a == 0.0:
		fade_then(leave_garden)
	if in_garden:
		garden_zone.update_garden(dt)
	if in_village and Vector2(player.x, player.z).distance_to(village.marks.K) < 0.9 and fade_rect.color.a == 0.0:
		if night_q >= 4:
			fade_then(enter_lake)
		elif toast_t <= 0.0:
			toast("남쪽 호수는 굳어 있다. 아직 갈 수 없다")
	if in_lake and Vector2(player.x, player.z).distance_to(lake.marks.S) < 0.9 and fade_rect.color.a == 0.0:
		fade_then(lake_zone.leave_lake)
	if in_lake and lake_q >= 4 and Vector2(player.x, player.z).distance_to(lake.marks.G) < 0.8 and fade_rect.color.a == 0.0:
		fade_then(enter_grotto)
	if in_grotto() and Vector2(player.x, player.z).distance_to(grotto.marks.S) < 0.7 and fade_rect.color.a == 0.0:
		fade_then(lake_zone.leave_grotto)
	if in_lake and not in_grotto():
		lake_zone.update_lake_south(dt)
	if south_q >= 4:
		grotto.turn_wheels(dt)
	if in_grotto() and grotto_q == 1 and player.z > 13.6 and not story_open:
		grotto_q = 2
		show_story("", STORY.CRAB_IN)
		after_story = lake_zone.spawn_crab
		save_game()
	mates.note_trail(dt)
	mates.update_mate(dt)
	mates.update_mate2(dt)
	hud_build.update_pips(dt)
	village_life.update_kid(dt)
	errands.update_oar()
	if in_marsh() and not intro:
		marsh.update(self)
	shore.update_shore(dt)
	marsh.update_flies(self, in_marsh() and is_night())
	marsh.update_flowers(self, in_marsh() and not intro and is_night() and moon_phase().x >= 0.6)
	if jar_node != null:
		jar_node.visible = night > 0.5
		jar_node.position = Vector3(player.x + 0.35, ground_y + 0.55 + sin(t * 2.0) * 0.04, player.z + 0.1)
	village_life.update_night(dt)
	cave.update_shrine(dt)
	minigames.update_trial(dt)
	minigames.update_race(dt)
	minigames.update_fishing(dt)
	if in_village:
		market.update_market(dt)
		update_magpie(dt)
	chatter.update_chat(dt)
	chatter.update_folk_chat(dt)
	hud_build.update_mate_hud()
	if cloud.reveal_t > 0.0:
		cloud.reveal_t -= dt
		if cloud.reveal_t <= 0.0:
			cloud.reveal(false)
	if in_cloud() and gust_dir == Vector2.ZERO and cloud.char_at(player.x, player.z) == "," and fade_rect.color.a == 0.0:
		player.x = CLOUD.CLOUD_X + 3.0 # a step off the unseen path: back onto the entry island
		player.z = 11.0
		hurt_player(8, 0.0)
		burst(Vector3(player.x, 0.5, player.z), Color("#ffffff"), 20, 2.5)
		# a fall looked like a bug when nothing said the path is there to be lit (the owner, 2026-10-26)
		toast("발을 헛디뎌 구름 아래로 떨어졌다가 바람에 실려 돌아왔다" if has_shard else "발밑 구름길은 보이지 않는다. 섬 남쪽 끝에서 E로 팔찌를 비추면 3초 동안 길이 보인다")
	if not intro:
		play_secs += dt
	ng_armed -= dt
	errands.update_festival(dt)
	update_folk_sleep(dt)
	feat_t -= dt
	if feat_t <= 0.0 and not intro:
		feat_t = 1.0
		check_feats()
	if in_house >= 0 and Vector2(player.x, player.z).distance_to(HOUSE_EXIT) < 0.7 and fade_rect.color.a == 0.0:
		fade_then(leave_house)
	if in_cave:
		check_painting()
		cave.update_post()
	if in_cave and Vector2(player.x, player.z).distance_to(cave_marks.E) < 1.6:
		var held: String = cave.exit_blocker()
		if held != "" and toast_t <= 0.0:
			toast(held)
		elif held == "" and Vector2(player.x, player.z).distance_to(cave_marks.E) < 1.0 and fade_rect.color.a == 0.0:
			fade_then(leave_cave)
	if not in_cave and cave_exit_seen and cave.exit_built and Vector2(player.x, player.z).distance_to(cave.exit_mouth_pos()) < 0.8 and fade_rect.color.a == 0.0 and not intro:
		fade_then(cave.enter_from_exit)
	daynight.update_daylight(dt)
	world_build.update_lights()
	save_t += dt
	if save_t > 5.0:
		save_t = 0.0
		save_game()
	monsters.update_projectiles(dt)
	monsters.update_enemy_shots(dt * (SLOWMO if slowmo > 0 else 1.0))
	for i in range(fx.size() - 1, -1, -1):
		var e: Dictionary = fx[i]
		e.t += dt
		var k: float = e.t / e.life
		if k >= 1.0:
			e.node.queue_free()
			fx.remove_at(i)
			continue
		e.update.call(e.node, k, dt)

	# camera follow
	var pitch := 0.78
	var target := Vector3(26, 0, 30) if intro else Vector3(player.x, gy + 0.6, player.z)
	shake = maxf(0, shake - dt)
	camera.position = target + Vector3(sin(cam_yaw) * cos(pitch) * cam_dist + rnd(-1, 1) * shake * 0.4 * (1.0 if cfg.shake else 0.0),
		sin(pitch) * cam_dist + rnd(-1, 1) * shake * 0.4 * (1.0 if cfg.shake else 0.0), cos(cam_yaw) * cos(pitch) * cam_dist)
	camera.look_at(target)
	# the haze starts past the ground Sora stands on, however far the camera pulls back: at the default 18 it is as
	# before (18 -> 46), zoomed out to 26 it starts at 26 instead of hiding most of the ground (the user, 2026-10-23)
	if env != null:
		env.fog_depth_begin = cam_dist
		env.fog_depth_end = cam_dist + 28.0 + maxf(0.0, cam_dist - 18.0) * 2.0
	sun.global_transform = Transform3D(Basis(), target + Vector3(-12, 10 + sun_el * 14, -8)).looking_at(target)
	motes.position = target
	rain.position = target + Vector3(0, 8, 0)

	# HUD
	banner_t -= dt
	if banner_t <= 0: ui.banner.modulate.a = maxf(0, ui.banner.modulate.a - dt * 2)
	toast_t -= dt
	if toast_t <= 0: ui.toast.modulate.a = maxf(0, ui.toast.modulate.a - dt * 3)
	ui.lv.text = str(player.lv)
	if ui.story.visible:
		fit_story()
	hud_build.update_side() # the running side step under the quest, the prep hint in the quest
	hud_build.layout_top() # the quest line and the boss bar from real rects
	ui.hp.size.x = 200.0 * player.hp / player.max_hp
	ui.mp.size.x = 200.0 * player.mp / player.max_mp
	ui.mp.modulate.a = 0.45 + 0.55 * absf(sin(t * 6.0)) if player.mp >= 60.0 else 1.0 # enough for 빛파동
	ui.sp.size.x = 2.0 * player.sp
	ui.xp.size.x = 200.0 * player.xp / (player.lv * 25)
	ui.xpt.text = "%d/%d" % [player.xp, player.lv * 25]
	ui.spt.text = "%d/100" % int(player.sp)
	ui.hpt.text = "%d/%d" % [ceili(player.hp), player.max_hp]
	ui.mpt.text = "%d/%d" % [int(player.mp), player.max_mp]
	ui.gold.text = "◆ %d" % player.gold
	ui.pots.text = "×%d" % player.pots
	for i in 3:
		ui.cd[i].size.y = 48.0 * player.cds[i] / SKILL_CD[i]
	ui.cd[3].size.y = 48.0 * player.cds[3] / 2.0

# keep the story picture and dialogue box off the screen edges on narrow windows
const STORY_BOX_H := 144.0

# Sora falls where she stands; 3 s later she wakes at the start (faint)
var down_t := 0.0

var enemy_shots: Array = []

# ---- 성 아래 잠긴 층 (side zone under the castle's great hall): the channel, the plug that drains the flooded hall, the
# wind well, four water lamps lit within 8 s, Hangyeol's room with two big guardians, his fourth page and his chest
const UNDER_STAIR := Vector2(CASTLE.CASTLE_X + 10, 18) # the stair down, on the great hall's floor
var under_spawned := false
var under_guards: Array = []   # the two guardians while they stand
var under_guards_done := false
var under_chest_open := false
var under_side_open := false
var under_diary_read := false

# ---- 달지기 작업장 (side story "끝내지 못한 등불", DESIGN.md 깊은 작업장): three floors under the great hall, x >= 620.
# work_q: 0 not entered, 1 B1 (lamps, plug), 2 B1 cleared, 3 B2 cleared (stopper), 4 B3 clamps open (the cradle),
# 5 the lantern released, 6 given to Simji (the repair bench stands in the village)
const WORK := preload("res://workshop.gd")
var wfloors: Array = [WORK.new(0), WORK.new(1), WORK.new(2)]
const WORK_DOOR := Vector2(CASTLE.CASTLE_X + 21, 8) # the floor tile in front of the door in the great hall's north-east corner
var work_q := 0
var work_floor := 0          # deepest floor reached (1 - 3)
var work_door := false       # the door is open
var work_seen := false       # its first look after the knight was told
var work_pulled := false     # B2: Mulgyeol lifted the lid
var work_cradle_seen := false
var work_hp := false         # the +10 max HP was given (kept by a new round)
var work_reads := [false, false, false]  # the repair tag, the polished handle, the scratched correction
var work_ways := [false, false, false]   # each floor's return waystone awake
var work_latch := [false, false, false]  # the cradle's latches (south, west, east)
var work_spawned := [false, false, false]
var has_lamp := false          # 한결의 등잔, a keepsake

# ---- the bigger village (48x36): the market's honesty-box stalls and its target yard, the inn, and the pond's
# drifting bottles. Fishing from the pier's end goes through fish_key like the lake shore.
var target_on := false
var target_left := 0.0
var target_hits := 0
var target_next := 0.0
var target_best := 0
var has_medal := false        # 과녁 메달: crits deal x2.0 instead of x1.8 (see crit_mult)
var inn_nights := 0

# what a stall or the inn is, said once when Sora steps up to it (the signs are only pictures)
var stall_seen := ""

# ---- 장터의 반짝이 도둑 (the village's story thread): coins go missing from the market's honesty boxes. At night a
# brick magpie sits on the moon-dust stall; when Sora comes near it flies on (the inn roof, the dark moon lantern at
# the pier's end, then its nest out on the pond). At the nest she learns it was Hangyeol's lantern bird, piling up
# shiny coins as a small moon since the pier's moon lantern went dark. Lighting that lantern (2 pips) ends it: the
# coins go back, Sora gets 100 gold and max HP +10, and moon dust costs 25 from then on.
var magpie_q := 0             # 0 not started, 1 the note read (watch at night), 2 the nest found, 3 done
var magpie: Node3D
var magpie_at := 0            # the perch it sits on now
var magpie_flying := false
var moon_lamp_node: Node3D

# ---------------------------------------------------------------- forwarders
# One line per func that other scripts call on this node, or that three or more files use.
# sys/sound.gd
func sfx(freq: float, dur := 0.1, wave := "square", vol := 0.25, slide := 0.0) -> void: sound.sfx(freq, dur, wave, vol, slide)
func sfx_stream(freq: float, dur := 0.1, wave := "square", vol := 0.25, slide := 0.0) -> AudioStreamWAV: return sound.sfx_stream(freq, dur, wave, vol, slide)
# sys/effects.gd
func burst(pos: Vector3, color: Color, n := 14, spd := 3.0) -> void: effects.burst(pos, color, n, spd)
func add_fx(node: Node3D, life: float, update: Callable) -> void: effects.add_fx(node, life, update)
func ring_mesh(r0: float, r1: float, a0: float, arc: float, seg := 24) -> ArrayMesh: return effects.ring_mesh(r0, r1, a0, arc, seg)
func pop_num(pos: Vector3, text: String, color := Color.WHITE) -> void: effects.pop_num(pos, text, color)
func fade_then(fn: Callable) -> void: effects.fade_then(fn)
# sys/world_build.gd
func box(size: Vector3, m: Material) -> MeshInstance3D: return world_build.box(size, m)
func with_stair_marks(tex: ImageTexture, spots: Array) -> ImageTexture: return world_build.with_stair_marks(tex, spots)
func with_up_marks(tex: ImageTexture, spots: Array) -> ImageTexture: return world_build.with_up_marks(tex, spots)
func multimesh_of(list: Array) -> MultiMeshInstance3D: return world_build.multimesh_of(list)
func add_chunks(blocks: Array, origin_x: int) -> void: world_build.add_chunks(blocks, origin_x)
func folk_sprite(id: String) -> Sprite3D: return world_build.folk_sprite(id)
func lantern(x: float, z: float, post_mat: Material, glass: Material) -> void: world_build.lantern(x, z, post_mat, glass)
func sign_icon(kind: String, size := 0.5) -> Sprite3D: return world_build.sign_icon(kind, size)
# sys/shop.gd
func toggle_shop(open: bool) -> void: shop.toggle_shop(open)
func buy(i: int) -> void: shop.buy(i)
func fit_shop() -> void: shop.fit_shop()
# sys/sora.gd
func blob(r: float) -> MeshInstance3D: return sora.blob(r)
func player_hit(dmg: int, src: Vector2, attacker: Dictionary) -> String: return sora.player_hit(dmg, src, attacker)
func hurt_player(dmg: int, gy: float) -> void: sora.hurt_player(dmg, gy)
func faint() -> void: sora.faint()
# sys/combat.gd
func damage_enemy(e: Dictionary, amt: float, from: Vector2, kb := 4.0, force_crit := false, stop := 0.05) -> void: combat.damage_enemy(e, amt, from, kb, force_crit, stop)
func gain_xp(n: int) -> void: combat.gain_xp(n)
func foe_lv() -> int: return combat.foe_lv()
func foe_hit() -> int: return combat.foe_hit()
func attack() -> void: combat.attack()
func skill_cost(i: int) -> int: return combat.skill_cost(i)
func use_skill(i: int) -> void: combat.use_skill(i)
func drink_potion() -> void: combat.drink_potion()
func dodge() -> void: combat.dodge()
# sys/monsters.gd
func brick(g: Node3D, mats: Array, size: Vector3, pos: Vector3, color: Color, studs := true, glow := false) -> void: monsters.brick(g, mats, size, pos, color, studs, glow)
func spawn_enemy(at := Vector2(-1, -1), archer := false) -> void: monsters.spawn_enemy(at, archer)
func spawn_wolf(at: Vector2) -> void: monsters.spawn_wolf(at)
func spawn_bat(at: Vector2) -> void: monsters.spawn_bat(at)
func warn_ring(pos: Vector3, r: float, life: float) -> void: monsters.warn_ring(pos, r, life)
# sys/daynight.gd
func is_night() -> bool: return daynight.is_night()
func moon_phase() -> Vector2: return daynight.moon_phase()
# sys/hud_build.gd
func enable_touch() -> void: await hud_build.enable_touch()
func disable_touch() -> void: hud_build.disable_touch()
func place(c: Control, anchor: int, pos: Vector2, size: Vector2) -> void: hud_build.place(c, anchor, pos, size)
# sys/story.gd
func begin_opening() -> void: story.begin_opening()
func lantern_quest_late() -> void: story.lantern_quest_late()
func clear_vegetation(at: Vector2, r: float) -> void: story.clear_vegetation(at, r)
func open_cave(at: Vector2, with_story := true) -> void: story.open_cave(at, with_story)
func touch_words(t: String) -> String: return story.touch_words(t)
func show_story(path: String, lines: Array, small := false) -> void: story.show_story(path, lines, small)
func show_line(line: String) -> void: story.show_line(line)
func close_story() -> void: story.close_story()
func start_game(with_story := true) -> void: story.start_game(with_story)
func fit_story() -> void: story.fit_story()
# sys/save.gd
func save_game() -> void: save.save_game()
func load_game() -> void: save.load_game()
func repair_story_step(d: Dictionary) -> void: save.repair_story_step(d)
func old_quest_words(q: String) -> String: return save.old_quest_words(q)
func main_road_quest() -> String: return save.main_road_quest()
func return_to_start() -> void: save.return_to_start()
# sys/menus.gd
func apply_settings() -> void: menus.apply_settings()
func show_set_tab(i: int) -> void: menus.show_set_tab(i)
func toggle_settings(show: bool) -> void: menus.toggle_settings(show)
func toggle_sound() -> void: menus.toggle_sound()
func toggle_help(show: bool) -> void: menus.toggle_help(show)
func toggle_journal(show: bool) -> void: menus.toggle_journal(show)
func journal_lines() -> Array: return menus.journal_lines()
# sys/chatter.gd
func say_bubble(who: Node3D, text: String, dur := 3.5) -> void: chatter.say_bubble(who, text, dur)
func rest_talk(talk: Array) -> void: chatter.rest_talk(talk)
func folk_chat_at(id: String) -> Vector2: return chatter.folk_chat_at(id)
func folk_tag_ok(id: String, tag: String) -> bool: return chatter.folk_tag_ok(id, tag)
func folk_chat_lines(id: String) -> Array: return chatter.folk_chat_lines(id)
# sys/minigames.gd
func trial_foes() -> Array: return minigames.trial_foes()
func fish_weight(i: int) -> int: return minigames.fish_weight(i)
# sys/folk.gd
func asleep_hint(me: Vector2) -> bool: return folk.asleep_hint(me)
func folk_home(id: String) -> int: return folk.folk_home(id)
func folk_bed(id: String) -> Array: return folk.folk_bed(id)
func bed_spot(id: String) -> Vector2: return folk.bed_spot(id)
func folk_awake_here(id: String) -> bool: return folk.folk_awake_here(id)
func folk_talk_at(id: String) -> Vector2: return folk.folk_talk_at(id)
func route_at(id: String, i: int) -> Vector2: return folk.route_at(id, i)
func folk_route_state(id: String) -> Dictionary: return folk.folk_route_state(id)
func route_reset(id: String) -> void: folk.route_reset(id)
func route_home(id: String) -> bool: return folk.route_home(id)
func update_folk_sleep(dt: float) -> void: folk.update_folk_sleep(dt)
func folk_way(id: String) -> Array: return folk.folk_way(id)
func way_at(way: Array, k: float) -> Vector2: return folk.way_at(way, k)
func enter_house(i: int) -> void: folk.enter_house(i)
func leave_house() -> void: folk.leave_house()
# sys/errands.gd
func check_feats() -> void: errands.check_feats()
func mail_errand() -> bool: return errands.mail_errand()
func festival_now() -> bool: return errands.festival_now()
func ng_mult() -> float: return errands.ng_mult()
func new_round_lines() -> Array: return errands.new_round_lines()
func write_new_round() -> void: errands.write_new_round()
func hint_open(key: String) -> bool: return errands.hint_open(key)
func folk_talk(id: String) -> void: errands.folk_talk(id)
func deliver_letter() -> void: errands.deliver_letter()
# sys/waystones.gd
func way_spot(i: int) -> Vector2: return waystones.way_spot(i)
func way_known(i: int) -> bool: return waystones.way_known(i)
# sys/village_life.gd
func enter_village() -> void: village_life.enter_village()
func award_pip(key: String) -> Array: return village_life.award_pip(key)
func load_pips(d: Dictionary) -> void: village_life.load_pips(d)
func old_save_pips(d: Dictionary) -> void: village_life.old_save_pips(d)
func spend_pips(n: int) -> bool: return village_life.spend_pips(n)
func screen_left(v: Vector2) -> bool: return village_life.screen_left(v)
func village_lamps() -> Array: return village_life.village_lamps()
func rise_lines() -> Array: return village_life.rise_lines()
func place_kid() -> void: village_life.place_kid()
func build_jar() -> void: village_life.build_jar()
# sys/market.gd
func spawn_target() -> void: market.spawn_target()
func cast_lines(lines: Array) -> Array: return market.cast_lines(lines)
func inn_first_lines() -> Array: return market.inn_first_lines()
func bottle_lines(i: int) -> Array: return market.bottle_lines(i)
func magpie_nest_lines() -> Array: return market.magpie_nest_lines()
func magpie_done_lines() -> Array: return market.magpie_done_lines()
func pick_bottle(b: Dictionary) -> void: market.pick_bottle(b)
func magpie_perches() -> Array: return market.magpie_perches()
func place_magpie() -> void: market.place_magpie()
func update_magpie(dt: float) -> void: market.update_magpie(dt)
# sys/cave.gd
func cave_char(x: float, z: float) -> String: return cave.cave_char(x, z)
func crystal_hit(e: Dictionary) -> void: cave.crystal_hit(e)
func post_card_lines() -> Array: return cave.post_card_lines()
func cave_interact() -> bool: return cave.cave_interact()
func check_painting() -> void: cave.check_painting()
func enter_cave() -> void: cave.enter_cave()
func leave_cave() -> void: cave.leave_cave()
func mole_defeated() -> void: cave.mole_defeated()
# sys/shore.gd
func clear_shore_job() -> void: shore.clear_shore_job()
func load_shore(d: Dictionary) -> void: shore.load_shore(d)
func road_page_lines() -> Array: return shore.road_page_lines()
func post_bori_lines() -> Array: return shore.post_bori_lines()
# sys/forest_zone.gd
func enter_forest() -> void: forest_zone.enter_forest()
func unbrick_cost() -> int: return forest_zone.unbrick_cost()
func spawn_cages() -> void: forest_zone.spawn_cages()
func hollow_squirrel_lines() -> Array: return forest_zone.hollow_squirrel_lines()
func simji_lantern() -> void: forest_zone.simji_lantern()
func oak_hogs_alive() -> Array: return forest_zone.oak_hogs_alive()
func place_big_squirrel() -> void: forest_zone.place_big_squirrel()
func untie_knot(i: int) -> void: forest_zone.untie_knot(i)
func update_oak() -> void: forest_zone.update_oak()
func load_oak(d: Dictionary) -> void: forest_zone.load_oak(d)
# sys/lake_zone.gd
func enter_lake() -> void: lake_zone.enter_lake()
func mate_job_state() -> String: return lake_zone.mate_job_state()
func spawn_south_ambush() -> void: lake_zone.spawn_south_ambush()
func clear_south_job() -> void: lake_zone.clear_south_job()
func in_grotto() -> bool: return lake_zone.in_grotto()
func stair_frame(at: Vector2, turn := 0.0, shade := 0.0, lamp_col := Color("#9fd8ff")) -> Node3D: return lake_zone.stair_frame(at, turn, shade, lamp_col)
func enter_grotto() -> void: lake_zone.enter_grotto()
func turtle_beaten() -> void: lake_zone.turtle_beaten()
# sys/hill_zone.gd
func in_cloud() -> bool: return hill_zone.in_cloud()
func enter_cloud() -> void: hill_zone.enter_cloud()
func enter_hill() -> void: hill_zone.enter_hill()
func give_shield(e: Dictionary) -> void: hill_zone.give_shield(e)
func mate_power() -> float: return hill_zone.mate_power()
func windrun_prefix() -> String: return hill_zone.windrun_prefix()
# sys/castle_zone.gd
func enter_stairs() -> void: castle_zone.enter_stairs()
func open_stairs() -> void: castle_zone.open_stairs()
func in_castle() -> bool: return castle_zone.in_castle()
func in_stairs() -> bool: return castle_zone.in_stairs()
func enter_castle() -> void: castle_zone.enter_castle()
func spawn_knight(echo := false) -> void: castle_zone.spawn_knight(echo)
func knight_beaten() -> void: castle_zone.knight_beaten()
func doll_bits() -> Array: return castle_zone.doll_bits()
func clear_quarters_job() -> void: castle_zone.clear_quarters_job()
func quarters_target() -> Vector3: return castle_zone.quarters_target()
func step_target() -> Vector3: return castle_zone.step_target()
func load_quarters(d: Dictionary) -> void: castle_zone.load_quarters(d)
func in_under() -> bool: return castle_zone.in_under()
func in_workshop() -> bool: return workshop_zone.in_workshop()
func chest_sprite(at: Vector2, tint: Color) -> Sprite3D: return castle_zone.chest_sprite(at, tint)
func enter_under() -> void: castle_zone.enter_under()
func in_hangyeol_room(p: Vector2) -> bool: return castle_zone.in_hangyeol_room(p)
func under_diary_lines() -> Array: return castle_zone.under_diary_lines()
# sys/mates.gd
func join_mate() -> void: mates.join_mate()
func snap_mate() -> void: mates.snap_mate()
func snap_mates() -> void: mates.snap_mates()
func join_noeul() -> void: mates.join_noeul()
func mate_max() -> float: return mates.mate_max()
func hurt_mate(id: String, dmg: int) -> void: mates.hurt_mate(id, dmg)
# sys/garden_zone.gd
func enter_garden() -> void: garden_zone.enter_garden()
func road_echo_lines() -> Array: return garden_zone.road_echo_lines()
func leave_garden() -> void: garden_zone.leave_garden()
func final_wind() -> void: garden_zone.final_wind()
func in_clock() -> bool: return garden_zone.in_clock()
func hand_spot(k: int) -> Vector2: return garden_zone.hand_spot(k)
func clock_worn_lines() -> Array: return garden_zone.clock_worn_lines()
func clear_clock_wave() -> void: garden_zone.clear_clock_wave()
func place_workers() -> void: garden_zone.place_workers()
func beat_clear() -> void: garden_zone.beat_clear()
func load_clock(d: Dictionary) -> void: garden_zone.load_clock(d)
