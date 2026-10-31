# Autoplay tests: drive the real game with injected input and check the outcome.
# Run with `-- --test=all` (or one name). Each test prints one line:
#   TEST name PASS|FAIL detail
# and the run ends with `TESTS n passed, m failed` and exit code m.
extends Node

const MARSH := preload("res://marsh.gd")
const STORY := preload("res://story_lines.gd")
var main: Node
var only := "all"
var results: Array = []

const TESTS := ["title_music", "boss_intro", "start_click", "story_opens", "story_closes", "opening", "meet_bori", "boss_opens_cave", "save_load", "story_kept", "cave_enter", "cave_layout", "archer_telegraph", "key_door", "rival_scene", "cave_save_load", "painting_once", "unstick", "mole_charge", "key_unstick", "mole_grants_skip", "cave_faint", "cave_exit", "water_skip", "water_skip_letgo", "village_enter", "village_layout", "simji_talk", "lamp_cost_night", "lamp_cost_day", "lamp_no_pips", "pip_rest", "errand_done", "kongal_errand", "doran_errand", "mulgyeol_errand", "lantern_night", "folk_again", "lake", "forest", "hill", "garden_end", "village_exit", "marsh_scraps", "forest_grove", "firefly_errand", "grotto", "cloud", "castle", "shrine", "journal", "esc_sheets", "news_more", "touch_controls", "quest_layout", "bgm", "mash", "folk_height", "folk_hop", "windrun_retry", "story_pad", "folk_sleep", "folk_routine", "hint_folk", "wolf", "trial", "squirrels", "crystals", "race", "vault", "save_tonight", "fishing", "bat", "moonflowers", "houses", "one_key", "feats", "mail", "festival", "new_round", "shop_price", "cloud_path", "waystones", "stuck_fixes", "story_fixes", "bracelet", "playtest5", "laps", "books", "bori_e", "moon_stairs", "undercroft", "workshop", "hollow", "hush", "trial_repeat", "road", "mill", "post", "lake_south", "clock", "shore", "quarters", "oak", "village_market", "mate_facing", "settings", "mate_chat", "pips", "folk_chat", "noeul_rest", "east_bridge", "fall_down", "mate_hp", "start_key", "bridges", "shop_buy", "shop_click", "footsteps", "boss_survive", "faint_resets", "lap6", "lap7", "lap8",
	"flash_dodge", "late_dodge", "flash_guard", "guard_block", "guard_back", "momentum", "level_moves", "level_perks", "gear_look", "hill_dressing", "village_dressing", "fountain", "mate_breath", "exit_marks", "pip_hint", "reset_ask", "plant_shake", "sora_breath", "rest_why", "hawk_unstick", "camp_diary", "click_guard", "round_badge", "tree_shake", "rest_heal", "story_moves_sora", "babble", "trial_count", "toy_bricks", "hud_plates", "credits", "lake_dressing", "forest_dressing", "stairs_dressing", "garden_dressing", "folk_mark", "island_landing", "bori_away", "bus_layout", "area_steps", "tree_chop", "chain_cut", "stage_noeul", "seam_pins", "lantern_toggle", "ending_replay", "mural_split", "skill_cost", "goblin_telegraph", "boss_phase2",
	"hawk_leash", "mold_leash", "mold_no_skip", "king_calm", "faint_banner", "windrun_faint", "mate_skips_air", "kid_reload", "race_save",
	"bug_boss_tick", "bug_mill_pile", "bug_mold_faint", "bug_mul_twice", "quest_marks", "field_respawn", "pack_turns", "goblin_lunge", "archer_backoff", "wolf_turns", "bat_double", "hog_roll", "new_foes", "token_gates", "token_stairs", "token_ui", "token_old_save", "token_new_round", "token_fix", "token_fix2", "gate_pond", "gate_valley", "gate_castle", "gate_knight", "gate_quarters", "gate_new_round", "gate_fix4", "gate_fix5", "lap6_ui", "boss_hp7", "review_fixes", "corridor_enter", "corridor_s1", "corridor_s2", "corridor_s3", "corridor_core", "corridor_boss", "corridor_save", "corridor_fix", "corridor_gate", "corridor_round", "bag", "refusal", "stairs_fx", "lake_stair", "picture_hud", "toy_taps", "idle_places", "folk_nod", "potion_kept", "eave_drips", "full_chime", "run_hold", "sign_tease", "sign_read", "foe_pace", "doodles", "pinwheels", "door_bell", "marsh_duck", "marsh_frogs", "marsh_frog_call", "marsh_fluff", "marsh_pipe", "marsh_mat", "d1_leaves", "d4_sign_sway", "d7_shop_flag", "d8_palm", "d9_rope", "d10_empty_chest", "d14_rest_more", "d16_scenic", "d18_noeul_bow", "d19_listened", "toy_fence", "football_kick", "football_bounce", "football_goal", "football_save", "football_quiet", "football_cheer", "football_north", "pitch_marks", "ending_home", "pinwheel_hit", "bori_pinwheel", "d20_arrive", "d21_cup", "d26_shelter", "d27_sleep_z", "d30_kid_shoes", "d34_drip_timbre", "d36_cave_dust", "d37_tag", "d38_moon_plaque", "d39_ribbons", "d40_windows", "d41_wet_steps", "d42_chest_knock", "d44_mill_creak", "d49_clack", "d51_stud", "d52_wall_dust", "d54_release_dust", "d55_calm", "d57_air_whiff", "d58_screw", "d59_revive_bow", "d60_breath_word", "d63_umbrella", "d64_photo", "d66_hush", "d67_pond_drop", "d68_moon_ring", "d69_inn_stretch", "d70_run_water", "d71_tea_cups", "d72_height_ruler", "d74_wall_chair", "d77_acorn_husk", "d80_start_reeds", "d82_pip_gap", "d86_last_bottle", "d99_ready_rim", "d2_wet_prints", "d5_reed_drops", "d6_street_leaves", "d11_fountain_step", "d13_loop_dizzy", "d15_look_back", "d17_chest_look", "d22_letter", "d23_twirl", "d24_can", "d25_chalk", "d28_inn_cup", "d32_rain_rings", "d33_roof_rain", "d35_lamp_moths", "d43_room_echo", "d46_fountain_quiet", "d48_story_hush", "d50_rain_house", "d53_door_stick", "d65_map_back", "d73_bell_answer", "d75_fold", "d79_four_blocks", "d81_recap", "d83_potion_preview", "d84_folk_detail", "d85_resume", "d87_save_gear", "d88_dots", "d89_read_pace", "d90_one_hand", "d91_lefty", "d92_crown_word", "d94_guard_slip", "d97_key_size", "d98_edge_bubble", "d100_fade_keys", "d95_safe_area", "d96_back_button", "obs_enter", "obs_s1", "obs_s2", "obs_s3", "obs_top", "obs_boss", "obs_save", "obs_gate", "obs_round", "pip_rest_far"] # pip_rest_far walks through four areas: last

# these count frames or hit narrow windows, and flake at the 4x clock dev.py runs the suite at: each runs at 1x
const REAL_SPEED := ["corridor_boss", "football_kick", "hog_roll", "mash", "new_foes", "obs_boss", "obs_s1", "shore", "archer_backoff", "corridor_s2", "marsh_duck", "marsh_fluff", "marsh_pipe", "cloud", "corridor_core", "corridor_fix", "corridor_s3", "marsh_frogs", "undercroft", "football_cheer", "bat_double", "pack_turns", "obs_s2", "door_bell"]

func _ready() -> void:
	run.call_deferred()

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

# seconds on the game's clock: dev.py runs the suite at --time-scale 4, where the wall clock runs slow against the game
func gsec() -> float:
	return Time.get_ticks_msec() / 1000.0 * Engine.time_scale

# a test that presses a settings row writes user://settings.json; the file as it was goes back afterwards, so the next run starts the same
func settings_keep() -> String:
	return FileAccess.get_file_as_string("user://settings.json") if FileAccess.file_exists("user://settings.json") else ""

func settings_back(kept: String) -> void:
	if kept != "":
		var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
		f.store_string(kept)

# a shown line without the word joiners Ko.keep_words puts in (story box, journal, quest line)
func plain(s: String) -> String:
	return s.replace(char(0x2060), "")

func check(name: String, ok: bool, detail := "") -> void:
	results.append(ok)
	print("TEST %s %s %s" % [name, "PASS" if ok else "FAIL", detail])

func click() -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = get_viewport().get_visible_rect().size / 2.0
	if main.intro: # the headless window is 64 px, so its centre lies on the title's music key: click below it
		e.position.y = get_viewport().get_visible_rect().size.y - 2.0
	Input.parse_input_event(e)
	var up := e.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

# a picture of the window for the builder's eyes (windowed runs only; the headless renderer has none)
func shot_png(n: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/%s.png" % n))

func tap(key: int) -> void:
	var e := InputEventKey.new()
	e.keycode = key
	e.physical_keycode = key
	e.pressed = true
	Input.parse_input_event(e)
	var up := e.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

# hold a direction given in world x/z: pick the screen keys that move that way
func hold_world(dir: Vector2) -> void:
	var fwd := Vector2(-sin(main.cam_yaw), -cos(main.cam_yaw))
	var right := Vector2(cos(main.cam_yaw), -sin(main.cam_yaw))
	main.fake_keys.clear()
	var f := dir.dot(fwd)
	var r := dir.dot(right)
	if f > 0.38: main.fake_keys[KEY_W] = true
	if f < -0.38: main.fake_keys[KEY_S] = true
	if r > 0.38: main.fake_keys[KEY_D] = true
	if r < -0.38: main.fake_keys[KEY_A] = true

func release() -> void:
	main.fake_keys.clear()

# ---- the village football tests (v0.1.109): Sora on the south lawn, foes parked, the ball put down at rest
func fb_start() -> Array:
	var was: Array = [main.in_village, main.in_house, main.player.x, main.player.z]
	main.close_story()
	main.in_village = true
	main.in_house = -1
	calm_enemies(true)
	return was

func fb_end(was: Array) -> void:
	main.in_village = was[0]
	main.in_house = was[1]
	main.football.state = "play"
	main.football.vel = Vector2.ZERO
	main.football.p = main.football.spot
	main.football.ball.position = Vector3(main.football.p.x, 0, main.football.p.y)
	calm_enemies(false)
	reset_to(Vector2(was[2], was[3]))

# the ball at a village tile at rest, Sora at another facing a way, nothing in her hands
func fb_put(ball: Vector2, sora: Vector2, face: Vector2) -> void:
	var vx: float = main.village.VILLAGE_X
	var fb: Object = main.football
	fb.p = Vector2(vx + ball.x, ball.y)
	fb.vel = Vector2.ZERO
	fb.state = "play"
	fb.away_t = 0.0
	fb.ball.position = Vector3(fb.p.x, 0, fb.p.y)
	reset_to(Vector2(vx + sora.x, sora.y))
	main.player.vx = 0.0
	main.player.vz = 0.0
	main.player.face = face
	main.player.atk_cd = 0.0
	main.player.combo_t = 0.0
	main.player.dodge = 0.0
	main.dash = {}

func reset_to(p: Vector2) -> void:
	main.player.x = p.x
	main.player.z = p.y
	main.player.hp = float(main.player.max_hp)
	main.player.inv = 0.0
	main.ground_y = main.height_at(p.x, p.y)

# companions out of a test whose numbers they would muddle (their hits stop a wolf's lunge, their kills add gold)
var parked: Array = []
func park_mates(on: bool) -> void:
	if on:
		parked = [main.mate, main.mate2]
		for m in parked:
			if m != null:
				m.visible = false
		main.mate = null
		main.mate2 = null
	elif parked.size() == 2:
		main.mate = parked[0]
		main.mate2 = parked[1]
		parked = []
		main.snap_mates()

# a clear patch of marsh for the foe-behaviour tests: every tile within 5.5 of the centre walkable (the pond near (20, 30) is not)
var open_spot := Vector2(-1, -1)
func open_field() -> Vector2:
	if open_spot.x >= 0.0:
		return open_spot
	for gz in range(12, 56, 2):
		for gx in range(10, 44, 2):
			var clear := true
			for dz in range(-5, 6):
				for dx in range(-5, 6):
					if Vector2(dx, dz).length() <= 5.5 and not main.walkable(gx + 0.5 + dx, gz + 0.5 + dz):
						clear = false
			if clear:
				open_spot = Vector2(gx + 0.5, gz + 0.5)
				return open_spot
	open_spot = Vector2(32.5, 22.5)
	return open_spot

func calm_enemies(on: bool) -> void:
	for e in main.enemies:
		if not e.get("boss", false) and not e.get("mole", false) and not e.get("prop", false) and is_instance_valid(e.node):
			e.node.visible = not on
			if on:
				e.x = 2.0 # parked in the corner water, out of the way
				e.z = 2.0

# 깨어난 물가: the bricks risen by the basket or a snag
# companions hit as hard as Sora's level allows and foes only grow with half of it, so late in a full run they
# downed fresh packs before a test could count them
func hold_mates() -> void:
	main.mate_cd = 9.0
	main.mate2_cd = 9.0

func shore_foes() -> Array:
	return main.enemies.filter(func(e): return e.get("shore", false) and not e.dead)

func knock_shore() -> void: # down without gold or XP, so level-ups do not muddle the max HP check
	for e in shore_foes():
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()

# 달지기 숙소: the six bricks in the dining hall and the basket room, and the heaps' bits
func quarter_foes() -> Array:
	return main.enemies.filter(func(e): return e.get("quarters", false) and not e.dead)

func knock_quarters() -> void: # down without gold or XP
	for e in quarter_foes() + main.doll_bits():
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()

func wait_for(cond: Callable, sec: float) -> bool:
	var t := 0.0
	while t < sec:
		if cond.call():
			return true
		await wait(0.1)
		t += 0.1
	return cond.call()

# ---- 갈대늪 장난감 tests (v0.1.106): the world as the marsh has it once Sora has met Bori
func marsh_world() -> void:
	main.story_step = maxi(main.story_step, 3)
	main.close_story()
	main.in_village = false
	main.in_hill = false
	main.in_lake = false
	main.in_forest = false
	main.in_garden = false
	main.in_cave = false
	main.shop_open = false
	calm_enemies(true)

# ground a toy may stand on: dry, off the opening walk, clear of Bori's door, not in a tree, a lamp or the cottage
func marsh_ground_ok(p: Vector2) -> bool:
	var free := true
	for r in main.rocks:
		if not r.has("bush") and Vector2(r.x, r.z).distance_to(p) < r.r:
			free = false
	var door := Vector2(main.shop_pos.x, main.shop_pos.z)
	return main.tile_at(p.x, p.y) != main.WATER and free and main.marsh_toys.lane_dist(p) >= 2.5 and p.distance_to(door) >= 2.8 and p.distance_to(main.START) >= 5.0

# one living foe to a spot, for the "nothing during a fight" checks (calm_enemies parks it again)
func marsh_foe(at: Vector2) -> bool:
	hold_mates() # a companion's blow can drop the foe before the check reads it
	for e in main.enemies:
		if not e.dead and not e.get("boss", false) and not e.get("mole", false) and not e.get("prop", false) and is_instance_valid(e.node):
			e.x = at.x
			e.z = at.y
			return true
	return false

# ---- 물길 회랑 tests (v0.1.84): the world around the corridor, a room with the state of quest step q, a press of E at a device
func corr_world() -> void:
	main.close_story()
	main.in_village = false
	main.in_forest = false
	main.in_hill = false
	main.in_garden = false
	main.in_cave = false
	main.in_lake = true
	main.night_q = 4
	main.lake_q = 4
	main.south_q = 4
	main.tokens[2] = true
	main.has_pearl = true
	main.has_skip = true
	main.join_mate()

func corr_prep(q: int, r: int) -> void:
	corr_world()
	corr_kill(corr_foes()) # the last test's bricks are gone
	main.corr_sec = main.corridor_zone.fresh_sections()
	main.corr_bits = 0
	main.corr_reward = false
	main.corr_told = false
	main.corridor_q = q
	main.corridor_zone.clear_fight()
	main.corridor_zone.clear_job()
	main.corridor_zone.spawned = [false, false, false, false]
	main.corridor_zone.arrived = false
	main.corridor_zone.lights_t = -1.0
	main.corridor_zone.repair()
	main.corridor_zone.apply_state()
	main.corridor_zone.enter_room(r, false)
	main.close_story()
	main.player.hp = float(main.player.max_hp)

# stand beside a device and press E; the story box a device opens stays for the test to read
func corr_press(letter: String, r: int, i := 0, off := Vector2(0.9, 0)) -> void:
	var p: Vector2 = main.corridor.at(r, letter, i)
	reset_to(p + off)
	tap(KEY_E)
	await wait(0.25)

func corr_foes() -> Array:
	return main.enemies.filter(func(e): return not e.dead and (e.get("bucket", false) or e.get("corr_prep", false)))

func corr_kill(list: Array) -> void:
	for e in list:
		main.damage_enemy(e, 99999.0, Vector2(e.x, e.z - 1.0), 0.0, true)

# ---- 달맞이 관측원 tests (v0.1.120): the world around the observatory, a room with the state of quest step q, a press of E at a device
func obs_world() -> void:
	main.close_story()
	main.in_village = false
	main.in_forest = false
	main.in_lake = false
	main.in_garden = false
	main.in_cave = false
	main.in_hill = true
	main.night_q = 4
	main.lake_q = 4
	main.forest_q = 3
	main.hill_q = 3
	main.mill_q = 5
	main.trial_won = true
	main.has_skip = true
	main.join_mate()
	main.join_noeul()
	main.mate_down["mulgyeol"] = 0.0
	main.mate_down["noeul"] = 0.0

func obs_foes() -> Array:
	return main.enemies.filter(func(e): return not e.dead and (e.get("scalebird", false) or e.get("obs_prep", false) or e.get("moth_boss", false)))

func obs_kill(list: Array) -> void:
	for e in list:
		main.damage_enemy(e, 99999.0, Vector2(e.x, e.z - 1.0), 0.0, true)

func obs_prep(q: int, r: int) -> void:
	obs_world()
	obs_kill(obs_foes()) # the last test's bricks are gone
	main.obs_sec = main.observatory_zone.fresh_sections()
	main.obs_bits = 0
	main.obs_reward = false
	main.obs_told = false
	main.obs_top_tested = false
	main.obs_ordeal = false
	main.obs_relay = 0
	main.observatory_q = q
	var Z = main.observatory_zone
	Z.clear_fight()
	Z.clear_job()
	Z.spawned = [false, false, false, false]
	Z.lights_t = -1.0
	Z.relay_told = false
	Z.repair()
	Z.apply_state()
	Z.enter_room(r, false)
	main.close_story()
	main.player.hp = float(main.player.max_hp)

# stand beside a device and press E; the story box a device opens stays for the test to read
func obs_press(letter: String, r: int, i := 0, off := Vector2(0.9, 0)) -> void:
	var p: Vector2 = main.obs.at(r, letter, i)
	reset_to(p + off)
	tap(KEY_E)
	await wait(0.25)

func run() -> void:
	var speed: float = Engine.time_scale
	var want := func(n):
		Engine.time_scale = 1.0 if n in REAL_SPEED else speed
		main.max_dt = maxf(0.05, 0.025 * Engine.time_scale)
		return only == "all" or n in only.split(",")
	main.sleep_off = true # the villagers stay out at night here; folk_sleep turns their sleep back on
	main.routine_off = true # and on their spots by day; folk_routine turns their rounds on
	main.folk_chat_off = true # and quiet; folk_chat lets them talk
	main.away_ui.off = true # a window that loses focus under a test does not pause it; d96_back_button calls leave() itself
	main.shore_q = 1 # the shore hint does not open over tests that wake Sora at the start; shore sets it itself
	if only == "title_space": # the user's web save, then Space at the title, twice
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string('{"atk":37,"boss_dead":true,"chests":[true,true,true,true,true],"day":3,"door_open":false,"gold":786,"has_key":false,"hour":2.13,"hp":208.0,"in_cave":false,"lv":10,"max_hp":208,"pots":7,"saw_painting":false,"story":5,"x":14.65,"z":20.15}')
		f.close()
		main.load_game()
		print("intro before=", main.intro)
		tap(KEY_SPACE)
		await wait(1.0)
		print("after 1st space intro=", main.intro, " story_open=", main.story_open, " title valid=", is_instance_valid(main.ui.title))
		tap(KEY_SPACE)
		await wait(1.0)
		print("after 2nd space intro=", main.intro, " pos=", main.player.x, ",", main.player.z, " in_cave=", main.in_cave)
		get_tree().quit(0)
		return
	if want.call("title_music") and main.intro:
		# the title's music key: B and a click on the corner button flip the tune without leaving the title
		await wait(1.0)
		var was: bool = main.music_on
		tap(KEY_B)
		await wait(0.3)
		var by_key: bool = main.music_on != was and main.intro
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = true
		e.position = main.ui.title_music.get_global_rect().get_center()
		Input.parse_input_event(e)
		var up := e.duplicate()
		up.pressed = false
		Input.parse_input_event(up)
		await wait(0.2)
		check("title_music", by_key and main.music_on == was and main.intro and main.ui.title_music.visible, "B flipped=%s, click back=%s, title up=%s" % [by_key, main.music_on == was, main.intro])
	if want.call("start_click"):
		await wait(1.0) # let the title orbit drift the camera first
		click()
		await wait(0.3)
		check("start_click", not main.intro and absf(main.cam_yaw - main.CAM_YAW) < 0.001, "title closes on a mouse click, camera back to the fixed angle (yaw %.3f)" % main.cam_yaw)
		check("story_opens", main.story_open, "opening illustration shows after the title")
		var lines_seen := 0
		var refusal_seen := false
		for k in 500: # the 다음 button shows once a line has typed out; E presses it (v0.1.74); the WAKE's ten lines, then the refusal's seven (v0.1.100)
			if not main.story_open:
				break
			if plain(main.ui.story_text.text).contains("집에 가고 싶어"):
				refusal_seen = true
			if main.ui.story_more.visible:
				lines_seen += 1
				tap(KEY_E)
			await wait(0.1)
		await wait(0.7)
		check("story_closes", not main.story_open and not main.ui.story.visible and refusal_seen and main.story_step == 1, "pages through the first scene and the refusal after it, then closes (%d presses, refusal seen %s, step %d)" % [lines_seen, refusal_seen, main.story_step])
	if main.intro:
		main.start_game(false)
	if main.story_open:
		main.close_story()
		await wait(0.6)
	if want.call("start_key"):
		# the intro is over by now, so check that keys still reach the game: H toggles help
		var before: bool = main.ui.help.visible
		tap(KEY_H)
		await wait(0.2)
		check("start_key", main.ui.help.visible != before, "keys reach the game after the title")
		tap(KEY_H)
	calm_enemies(true)
	if want.call("bridges"):
		calm_enemies(true) # only the decks are under test; a goblin parked at a bridge end would block the walk
		for b in main.bridges:
			var z: float = b.z + 0.5
			reset_to(Vector2(b.a - 2.0, z))
			hold_world(Vector2(1, 0))
			var t := 0.0
			var goal: float = minf(b.b + 2.0, 47.4) # the east deck ends at the map edge, where the village begins
			while t < 8.0 and main.player.x < goal:
				# steer back onto the deck's centre line
				hold_world(Vector2(1, clampf((z - main.player.z) * 2.0, -1, 1)).normalized())
				await wait(0.1)
				t += 0.1
			release()
			check("bridges", main.player.x >= goal, "bridge at z=%d: reached x=%.1f of %.1f" % [b.z, main.player.x, goal])
		calm_enemies(false)
	if want.call("shop_buy"):
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.story_step = 3
		main.player.gold = 100
		var pots: int = main.player.pots
		tap(KEY_SPACE)
		await wait(0.2)
		var opened: bool = main.shop_open
		var h0: float = main.hour
		await wait(1.0)
		var frozen: bool = main.hour == h0
		tap(KEY_1)
		await wait(0.2)
		tap(KEY_ESCAPE)
		await wait(0.2)
		check("shop_buy", frozen and opened and main.player.pots == pots + 1 and main.player.gold == 70 and not main.shop_open,
			"clock frozen=%s opened=%s pots %d->%d gold 100->%d closed=%s" % [frozen, opened, pots, main.player.pots, main.player.gold, not main.shop_open])
	if want.call("shop_click"):
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.story_step = 3
		main.player.gold = 100
		var p0: int = main.player.pots
		main.toggle_shop(true)
		await wait(0.3)
		var btn: Button = main.ui.shop_btns[0]
		var at: Vector2 = btn.get_parent().get_global_rect().get_center()
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = at
		e.global_position = at
		e.pressed = true
		Input.parse_input_event(e)
		var u := e.duplicate()
		u.pressed = false
		Input.parse_input_event(u)
		await wait(0.3)
		check("shop_click", main.player.pots == p0 + 1, "clicking the first card's button buys it: pots %d->%d, button at %s disabled=%s" % [p0, main.player.pots, at, btn.disabled])
		main.toggle_shop(false)
		await wait(0.2)
	if want.call("footsteps"):
		reset_to(main.START)
		main.sfx_log.clear()
		hold_world(Vector2(0, 1))
		await wait(2.0) # a slow machine walks fewer frames
		release()
		var steps: int = main.sfx_log.filter(func(k): return k.begins_with("step") or k.begins_with("triangle:1")).size()
		check("footsteps", steps >= 3, "%d steps in 2 s of walking" % steps)
	if want.call("boss_survive"):
		var boss = main.enemies.filter(func(e): return e.get("boss", false))
		if boss.is_empty() or boss[0].dead:
			check("boss_survive", false, "no boss on the map")
		else:
			var b0: Dictionary = boss[0]
			calm_enemies(true) # the boss alone: a marsh archer that happens to stand nearby would add its own hits
			reset_to(Vector2(b0.x, b0.z + 2.0))
			main.player.max_hp = 100
			main.player.hp = 100.0
			var faints := [0]
			var start: Vector2 = main.START
			for i in 120: # 12 s standing next to the awake boss, doing nothing
				await wait(0.1)
				if Vector2(main.player.x, main.player.z).distance_to(start) < 0.5:
					faints[0] += 1
					break
			calm_enemies(false)
			check("boss_survive", faints[0] == 0, "level 1 Sora standing still beside the boss for 12 s: hp %d" % int(main.player.hp))
	if want.call("faint_resets"):
		var boss = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)
		if not boss.is_empty():
			boss[0].hp = 100.0
		reset_to(Vector2(30, 30))
		main.faint()
		await wait(0.2)
		var at_start: bool = Vector2(main.player.x, main.player.z).distance_to(main.START) < 0.1
		var boss_full: bool = boss.is_empty() or boss[0].hp == boss[0].max_hp
		check("faint_resets", at_start and boss_full and main.ui.banner.modulate.a > 0.5,
			"at start=%s boss healed=%s banner shown=%s" % [at_start, boss_full, main.ui.banner.modulate.a > 0.5])
	# ---- story: the first minute and the first cottage visit
	if want.call("opening"):
		calm_enemies(true)
		reset_to(main.START)
		main.story_step = 0
		main.begin_opening()
		var lamp: OmniLight3D = main.dark_lamp
		var asked: bool = main.ui.quest.visible and plain(main.ui.quest.text).contains("E")
		var n_before: int = main.enemies.size()
		tap(KEY_E)
		await wait(0.2)
		var lit: bool = main.dark_lamp == null
		await wait(1.2)
		var g: Dictionary = main.enemies[main.enemies.size() - 1]
		var near: bool = lamp != null and Vector2(g.x, g.z).distance_to(Vector2(lamp.position.x, lamp.position.z)) < 3.0 # it rises at 1.4 tiles, then walks toward Sora
		check("opening", asked and lit and main.enemies.size() == n_before + 1 and near and main.story_step == 2,
			"prompt=%s lamp lit=%s goblin rose beside it=%s step=%d (goblin %.1f,%.1f lamp %.1f,%.1f n %d->%d)" % [asked, lit, near, main.story_step, g.x, g.z, lamp.position.x, lamp.position.z, n_before, main.enemies.size()])
		g.x = 2.0
		g.z = 2.0
		g.node.visible = false
		check("lantern_scene", main.story_open, "touching the crown shows the lantern scene")
		main.close_story()
		await wait(0.6)
	if want.call("meet_bori"):
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.story_step = 2
		tap(KEY_SPACE)
		await wait(0.2)
		var talking: bool = main.story_open and not main.shop_open
		for k in 600: # each line types out before its 다음 button shows; Space presses it (v0.1.74)
			if not main.story_open:
				break
			if main.ui.story_more.visible:
				tap(KEY_SPACE)
			await wait(0.1)
		await wait(0.6)
		tap(KEY_SPACE)
		await wait(0.2)
		check("meet_bori", talking and main.story_step == 3 and main.shop_open,
			"first visit talks first=%s then the shop opens=%s" % [talking, main.shop_open])
		tap(KEY_ESCAPE)
		await wait(0.2)

	# ---- Ys-style combat (DESIGN.md milestone 1)
	var dummy := {}
	if want.call("flash_dodge"):
		reset_to(Vector2(30, 30))
		main.flash_cd = 0.0
		main.player.mp = 0.0
		main.dodge()
		var r: String = main.player_hit(10, Vector2(main.player.x + 1, main.player.z), dummy)
		check("flash_dodge", r == "flash_dodge" and main.player.hp == main.player.max_hp and main.slowmo > 1.5 and main.player.mp == 20.0,
			"result=%s hp=%d slowmo=%.1f momentum=%d" % [r, int(main.player.hp), main.slowmo, int(main.player.mp)])
		await wait(2.2)
	if want.call("late_dodge"):
		reset_to(Vector2(30, 30))
		main.slowmo = 0.0 # the slow-mo of the flash dodge just before can still be running on a slow machine
		main.flash_cd = 0.0
		main.dodge()
		await wait(0.25) # past the 0.15 s window but still rolling: i-frames, no slow-mo
		var r: String = main.player_hit(10, Vector2(main.player.x + 1, main.player.z), dummy)
		check("late_dodge", r == "none" and main.slowmo <= 0.0, "result=%s" % r)
		await wait(0.5)
	if want.call("flash_guard"):
		reset_to(Vector2(30, 30))
		main.player.face = Vector2(1, 0)
		var foe := {"stun": 0.0}
		main.fake_keys[KEY_L] = true
		await wait(0.05)
		var r: String = main.player_hit(10, Vector2(main.player.x + 1, main.player.z), foe)
		release()
		check("flash_guard", r == "flash_guard" and main.player.hp == main.player.max_hp and main.counter_t > 1.0 and foe.stun == 1.0,
			"result=%s hp=%d counter=%.1f stun=%.1f" % [r, int(main.player.hp), main.counter_t, foe.stun])
		await wait(0.2)
	if want.call("guard_block"):
		reset_to(Vector2(30, 30))
		main.player.face = Vector2(1, 0)
		main.player.sp = 100.0
		main.fake_keys[KEY_L] = true
		await wait(0.4) # held too long for a flash guard: a plain block
		var r: String = main.player_hit(10, Vector2(main.player.x + 1, main.player.z), dummy)
		release()
		check("guard_block", r == "guard" and main.player.hp == main.player.max_hp - 5 and main.player.sp <= 85.5,
			"result=%s hp lost %d (want 5) stamina %d" % [r, int(main.player.max_hp - main.player.hp), int(main.player.sp)])
		await wait(1.0)
	if want.call("guard_back"):
		reset_to(Vector2(30, 30))
		main.player.face = Vector2(1, 0)
		main.fake_keys[KEY_L] = true
		await wait(0.4)
		var r: String = main.player_hit(10, Vector2(main.player.x - 1, main.player.z), dummy)
		release()
		check("guard_back", r == "hit", "attack from behind is not blocked: %s" % r)
		await wait(1.0)
	if want.call("momentum"):
		calm_enemies(false)
		var gob = main.enemies.filter(func(e): return not e.get("boss", false) and not e.get("prop", false) and not e.dead)[0]
		calm_enemies(true)
		gob.node.visible = true
		reset_to(Vector2(30, 30))
		gob.x = 31.0
		gob.z = 30.0
		gob.atk_cd = 9.0
		main.player.mp = 0.0
		main.player.atk_cd = 0.0
		main.player.face = Vector2(1, 0)
		main.attack()
		await wait(0.3)
		check("momentum", main.player.mp >= 4.9, "one slash on one goblin: momentum %.1f (want 5)" % main.player.mp)
		gob.x = 2.0
		gob.z = 2.0
		gob.node.visible = false
	if want.call("level_moves"):
		calm_enemies(false)
		var gob = main.enemies.filter(func(e): return not e.get("boss", false) and not e.get("prop", false) and not e.dead and e.x < 50.0)[0]
		calm_enemies(true)
		gob.node.visible = true
		var lv0: int = main.player.lv
		var ghp0: float = gob.hp
		main.player.combo_t = 0.0
		# five-hit chain at Lv6: the fifth swing is the slam
		main.player.lv = 6
		reset_to(Vector2(30, 30))
		gob.x = 31.0
		gob.z = 30.0
		gob.hp = 99999.0
		gob.atk_cd = 99.0
		var combos: Array = []
		for k in 5:
			main.player.atk_cd = 0.0
			main.player.face = Vector2(1, 0)
			main.attack()
			combos.append(main.player.combo)
			await wait(0.1)
		var chain: bool = combos == [0, 1, 2, 3, 4]
		# dash slash at Lv3: running with Shift
		main.player.lv = 3
		reset_to(Vector2(26, 30))
		gob.x = 27.5
		gob.z = 30.0
		var hp1: float = gob.hp
		main.player.sp = 100.0
		main.player.face = Vector2(1, 0)
		main.player.vx = 6.0
		main.player.vz = 0.0
		main.player.atk_cd = 0.0
		main.fake_keys[KEY_SHIFT] = true
		main.attack()
		main.fake_keys.clear()
		await wait_for(func(): return main.dash.is_empty(), 3.0) # the dash is a 0.14 s slide now
		var dashed: bool = main.player.x > 27.5 and gob.hp < hp1
		# charged slash at Lv4: guard a second, then J
		main.player.lv = 4
		reset_to(Vector2(30, 30))
		gob.x = 31.2
		gob.z = 30.0
		main.player.face = Vector2(1, 0)
		main.fake_keys[KEY_L] = true
		await wait(1.5) # the cut needs 1 s of guard in game time; a slow machine runs behind
		var hp2: float = gob.hp
		main.player.atk_cd = 0.0
		main.guard_since = main.t - 2.0 # held long enough whatever the game clock did on a busy machine
		gob.x = 31.2 # a goblin on cooldown now backs away from her while she waits; put it back in reach for the cut
		gob.z = 30.0
		main.attack()
		main.fake_keys.clear()
		var charged: bool = hp2 - gob.hp >= main.player.atk * 2.5
		check("level_moves", chain and dashed and charged, "5-hit chain=%s %s dash moved and hit=%s charged cut=%.0f" % [chain, str(combos), dashed, hp2 - gob.hp])
		main.player.lv = lv0
		gob.hp = ghp0
		gob.atk_cd = 1.0
		gob.stun = 0.0
		gob.wind = 0.0
		gob.kx = 0.0
		gob.kz = 0.0
		gob.x = 2.0
		gob.z = 2.0
		gob.node.visible = false
	if want.call("level_perks"):
		var lv0: int = main.player.lv
		var foes: Array = []
		for lv in [1, 10, 28]:
			main.player.lv = lv
			foes.append(main.foe_lv())
		# Lv15: skills come back 20% sooner; Lv10: a roll costs 7 less stamina
		reset_to(Vector2(30, 30)) # the whirl only reaches close by; a fire bolt flew off and killed the next test's goblin
		main.player.lv = 15
		main.player.mp = 100.0
		main.player.cds = [0.0, 0.0, 0.0, 0.0]
		main.use_skill(0)
		var cd15: float = main.player.cds[0]
		main.player.lv = 1
		main.player.mp = 100.0
		main.player.cds = [0.0, 0.0, 0.0, 0.0]
		main.use_skill(0)
		var cd1: float = main.player.cds[0]
		var quick: bool = absf(cd15 - cd1 * 0.8) < 0.01
		main.player.lv = lv0
		main.player.cds = [0.0, 0.0, 0.0, 0.0]
		check("level_perks", foes == [0, 5, 14] and quick, "foe levels in the marsh %s (want [0, 5, 14]: half of Sora's level, area step 0) skill cd Lv15 %.2f vs Lv1 %.2f" % [str(foes), cd15, cd1])
	if want.call("gear_look"):
		# bought blades tint the swing, bought armour rings her feet: tiers at 0, 1-2, 3-4, 5+
		var sb0: Array = main.shop_bought.duplicate()
		var tiers: Array = []
		for n in [0, 1, 3, 5]:
			main.shop_bought[2] = n
			tiers.append(main.effects.gear_tier(2))
		main.shop_bought[3] = 0
		await wait(0.1)
		var no_ring: bool = main.effects.armour_ring == null or not main.effects.armour_ring.visible
		main.shop_bought[3] = 5
		await wait(0.1)
		var ring_on: bool = main.effects.armour_ring != null and main.effects.armour_ring.visible
		var gold: bool = ring_on and (main.effects.armour_ring.material_override as StandardMaterial3D).albedo_color.b < 0.8
		main.shop_bought = sb0
		await wait(0.1)
		check("gear_look", tiers == [0, 1, 2, 3] and no_ring and ring_on and gold, "blade tiers %s none->no ring=%s five armours ring=%s gold=%s" % [str(tiers), no_ring, ring_on, gold])
	if want.call("hill_dressing"):
		# the hill's wind grass: hundreds of tiles get six tufts each, none on or next to the path, the gorge or a used
		# spot (windmill, lamp, marks); a headless run cannot read tuft positions back, so this checks the tiles
		var tiles: Array = main.hill.grass_tiles
		var near_clear := 0
		for t in tiles:
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					if main.hill.char_at(t.x + dx, t.y + dz) in main.hill.GRASS_CLEAR:
						near_clear += 1
		# no grass tufts since v0.1.54, flowers in patches instead
		var mesh: bool = not main.veg_meshes.any(func(mm): return mm.instance_count == tiles.size() * 6)
		var flowers: int = main.hill.flower_spots
		check("hill_dressing", tiles.size() > 400 and near_clear == 0 and mesh and flowers >= 600, "hill grass tiles %d, next to the path or a used spot %d, no tuft mesh=%s, flower clumps %d (patch tiles %d)" % [tiles.size(), near_clear, mesh, flowers, main.hill.bloom_tiles.size()])
	# the other maps' ground dressing: no planted tile on or next to a path, a mark or a used spot, some tiles in
	# every map, the tuft meshes hold exactly their tiles' tufts, and the whole map stays inside its tuft budget
	for area in [["village_dressing", main.village, main.village.VILLAGE_X, 250, 3600], ["lake_dressing", main.lake, main.lake.LAKE_X, 150, 2600],
			["forest_dressing", main.forest, main.forest.FOREST_X, 150, 2600], ["stairs_dressing", main.stairs, main.stairs.STAIRS_X, 30, 600],
			["garden_dressing", main.garden, main.garden.GARDEN_X, 30, 600]]:
		if not want.call(area[0]):
			continue
		var zone = area[1]
		var ox: int = area[2]
		var keep: Array = []
		if zone == main.village:
			keep = zone.keep_tiles(main)
		elif zone == main.forest:
			keep = zone.keep_tiles()
		var planted: Array = []
		for key in ["grass_tiles", "bed_tiles", "weed_tiles"]:
			if key in zone:
				planted.append_array(zone.get(key))
		var bad := 0
		var dup := {}
		for t in planted:
			dup[t] = true
			var tx: int = int(t.x) - ox
			var tz: int = int(t.y)
			if zone.blocked(t.x, t.y):
				bad += 1
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					if zone.char_at(t.x + dx, t.y + dz) in zone.GRASS_CLEAR or keep.has(Vector2i(tx + dx, tz + dz)):
						bad += 1
		var tufts := 0
		var meshes_ok := true
		for mm in zone.dress_meshes:
			if mm == null:
				meshes_ok = false
				continue
			tufts += mm.instance_count
		var per: Array = {"village_dressing": [3, 3], "lake_dressing": [5, 3], "forest_dressing": [4, 0], "stairs_dressing": [3, 0], "garden_dressing": [3, 0]}[area[0]]
		var want_tufts: int = zone.grass_tiles.size() * per[0]
		if zone == main.village: # cosmos only (no grass since v0.1.29): beds, fields and street borders (v0.1.34)
			want_tufts = zone.cosmos_spots
		elif zone == main.lake:
			want_tufts += zone.weed_tiles.size() * per[1]
		elif zone == main.forest:
			want_tufts += zone.fern_tiles.size() + zone.shroom_tiles.size()
		var lo: int = area[3]
		var budget: int = area[4]
		check(area[0], planted.size() >= lo and bad == 0 and dup.size() == planted.size() and meshes_ok and tufts == want_tufts and tufts <= budget,
			"planted tiles %d (at least %d), on a blocked tile or next to a path/mark/used spot %d, tufts %d of %d expected, budget %d" % [planted.size(), lo, bad, tufts, want_tufts, budget])
	if want.call("fountain"):
		# the moonkeepers' fountain (v0.1.38, flowing low from the start v0.1.41): its four tiles block, E beside it reads
		# the seven-stream lines, and once the land is wound (story_step 12) the full water shows and the lines change
		var v0: bool = main.in_village
		var s0: int = main.story_step
		main.close_story()
		main.in_village = true
		var fa: Vector2 = main.village.fountain_at()
		var blocks: bool = main.village.blocked(fa.x - 0.5, fa.y - 0.5) and main.village.blocked(fa.x + 0.5, fa.y + 0.5)
		var road_round: bool = not main.village.blocked(fa.x - 0.5, fa.y - 1.5) and not main.village.blocked(fa.x + 0.5, fa.y + 1.5)
		reset_to(fa + Vector2(0, 1.6))
		main.story_step = 0
		main.village.fountain_set(false)
		main.village.fountain_said = []
		main.crown_key()
		# v0.1.76: the water moves: drops from the hands, trickles over the upper lip and the welling are particles that emit
		var drops: Array = main.village.fountain_low.find_children("*", "CPUParticles3D", true, false)
		var flowing: bool = drops.size() >= 5 and drops.all(func(p): return p.emitting)
		var dry_ok: bool = flowing and main.story_open and "일곱 손" in str(main.village.fountain_said) and main.village.fountain_low.visible and not main.village.fountain_full.visible
		main.close_story()
		main.story_step = 12
		await get_tree().create_timer(1.2).timeout
		var wet_ok: bool = main.village.fountain_full.visible and not main.village.fountain_low.visible
		main.crown_key()
		var wet_line: bool = main.story_open and "시원해" in str(main.village.fountain_said)
		main.close_story()
		# a blow facing the basin splashes it and rocks the water (v0.1.76)
		var h0: int = main.village.fountain_hits
		main.player.x = fa.x
		main.player.z = fa.y + 1.6
		main.village.fountain_hit(main, 1.4, Vector2(0, -1), 0.3, false)
		await get_tree().create_timer(0.1).timeout
		var splashed: bool = main.village.fountain_hits == h0 + 1 and main.village.fountain_splash.emitting and absf(main.village.fountain_water.position.y - 0.35) > 0.001 			and main.sfx_log.any(func(s): return String(s).begins_with("splash:")) # and the water slaps (v0.1.81)
		main.village.fountain_hit(main, 1.4, Vector2(0, 1), 0.3, false) # facing away: nothing
		var away_dry: bool = main.village.fountain_hits == h0 + 1
		# the square's lantern stands within resting reach of the basin's south-east side (v0.1.76)
		var lamp_by: bool = main.lanterns.any(func(l): return Vector2(l.position.x, l.position.z).distance_to(fa + main.village.FOUNTAIN_LAMP) < 0.5)
		away_dry = away_dry and lamp_by
		wet_line = wet_line and splashed and away_dry
		main.story_step = s0
		main.village.fountain_set(s0 >= 12)
		main.in_village = v0
		check("fountain", blocks and road_round and dry_ok and wet_ok and wet_line,
			"blocks %s, road round it %s, seven streams and their lines %s, full water after the winding %s, wet line %s" % [blocks, road_round, dry_ok, wet_ok, wet_line])
	if want.call("mate_breath"):
		# Noeul and Mulgyeol breathe while they stand (v0.1.39): the breathing sheet with four frames that turn over,
		# and their own picture back the moment they move
		var spr := Sprite3D.new()
		spr.texture = load("res://art/folk/noeul.png")
		spr.hframes = 3
		var t0: float = main.t
		main.mates.breathe("noeul", spr, true)
		var on_sheet: bool = spr.texture.resource_path.ends_with("noeul_breath.png") and spr.hframes == 4
		var seen := {}
		for k in 4:
			main.t = t0 + k * main.mates.BREATH_STEP + 0.01
			main.mates.breathe("noeul", spr, true)
			seen[spr.frame] = true
		main.t = t0
		main.mates.breathe("noeul", spr, false)
		var back: bool = spr.texture.resource_path.ends_with("noeul.png") and spr.hframes == 3
		spr.free()
		check("mate_breath", on_sheet and seen.size() == 4 and back,
			"breathing sheet %s, frames seen %d of 4, own picture back %s" % [on_sheet, seen.size(), back])
	if want.call("exit_marks"):
		# the forest's ways out (v0.1.42): a pad and name at S and E, green arrows on the minimap; and a waystone found
		# shows on the minimap of its own area only (v0.1.43)
		var mini = main.ui.mini
		var tex0: Texture2D = mini.map_tex
		var q0: int = main.forest_q
		var p0 := Vector2(main.player.x, main.player.z)
		var signs: int = main.forest.exit_signs.size()
		mini.map_tex = main.forest.map_tex(main.forest.FOREST_X + main.forest.W)
		var exits: int = mini.map_tex.get_meta("exits", []).size()
		main.forest_q = 1
		main.player.x = main.forest.marks.S.x + 2.0
		main.player.z = main.forest.marks.S.y
		await get_tree().process_frame
		await get_tree().process_frame
		var forest_way: bool = 3 in mini.ways_drawn
		var only_here: bool = not (1 in mini.ways_drawn) and not (2 in mini.ways_drawn)
		main.forest_q = q0
		mini.map_tex = tex0
		main.player.x = p0.x
		main.player.z = p0.y
		check("exit_marks", signs == 2 and exits == 2 and forest_way and only_here,
			"signs %d of 2, map arrows %d of 2, forest waystone drawn %s, other areas' stones left off %s" % [signs, exits, forest_way, only_here])
	if want.call("pip_hint"):
		# too little moon light for a bracelet use shows the lantern + moon card for 4 s (v0.1.44)
		var pips0: int = main.crown_pips
		main.crown_pips = 0
		var refused: bool = not main.spend_pips(1)
		var shown: bool = main.ui.hud.pip_hint_t > 3.5
		await get_tree().create_timer(4.2).timeout
		var gone: bool = main.ui.hud.pip_hint_t == 0.0
		main.crown_pips = pips0
		check("pip_hint", refused and shown and gone, "refused %s, card shown %s, gone after 4 s %s" % [refused, shown, gone])
	if want.call("reset_ask"):
		# F9 asks first (v0.1.45): one press opens the ask with the difficulty line and keeps the save
		main.save_game()
		main.close_story()
		main.save.reset_asked_at = -100.0
		main.save.ask_reset()
		var asked: bool = main.story_open and FileAccess.file_exists(main.SAVE_PATH)
		var said := str(main.save.reset_lines())
		var lines_ok: bool = "레벨" in said and "회차" in said and "F9" in said and not "배" in said # plain lines (2026-10-29)
		main.close_story()
		main.save.reset_asked_at = -100.0
		check("reset_ask", asked and lines_ok, "ask shown and save kept %s, difficulty and key lines %s" % [asked, lines_ok])
	if want.call("plant_shake"):
		# a blow near tall plants shakes them (v0.1.51): the tall plants' materials get the blow, grass tufts do not
		var tall: int = main.plant_mats.size()
		main.combat.plants_hit(Vector2(main.player.x, main.player.z), 2.0)
		await get_tree().process_frame
		await get_tree().process_frame
		var told: bool = tall > 0 and (main.plant_mats[0] as ShaderMaterial).get_shader_parameter("hit").z < 1.0
		main.combat.update_plants(1.5) # by hand: in a full run another test's slash could restart the shake meanwhile
		var settled: bool = main.combat.plant_hit.z > 1.3
		check("plant_shake", told and settled, "tall plant materials %d, blow passed on %s, settled after 1.5 s %s" % [tall, told, settled])
	if want.call("lap6_ui"):
		# GPT lap 6 (v0.1.71): the late-game journal scrolls and fits a 960x540 window, the token gems clear the companion rows,
		# and the quest line keeps off the gems and every touch key
		if main.intro:
			main.start_game(false)
		main.close_story()
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(960, 540)
		var keep := {}
		for k in main.scenes.LATE:
			keep[k] = main.get(k).duplicate() if main.get(k) is Array else main.get(k)
		var keep_woke: bool = main.woke[0]
		var rows: Array = []
		var all_ok := true
		for touch in [false, true]:
			if touch:
				await main.enable_touch()
			await wait(0.1)
			var vs: Vector2 = main.get_viewport().get_visible_rect().size
			main.scenes.scene_late(main)
			main.toggle_journal(true)
			await wait(0.1)
			var j: Control = main.ui.journal
			var jr: Rect2 = j.get_global_transform() * Rect2(Vector2.ZERO, j.size)
			var j_in: bool = jr.position.x >= -0.5 and jr.position.y >= -0.5 and jr.end.x <= vs.x + 0.5 and jr.end.y <= vs.y + 0.5
			var scrolls := true
			var dragged := true
			var tail_ok := true
			var heights := []
			for c in [main.ui.journal_text, main.ui.journal_text2]:
				var rt: RichTextLabel = c
				var vb: VScrollBar = rt.get_v_scroll_bar()
				var content: float = rt.get_content_height()
				heights.append("%d/%d" % [int(content), int(rt.size.y)])
				scrolls = scrolls and rt.scroll_active and rt.mouse_filter == Control.MOUSE_FILTER_STOP
				if content > rt.size.y + 1.0: # the long column: a drag moves it, and the end of the text can be reached
					var ev := InputEventMouseMotion.new()
					ev.button_mask = MOUSE_BUTTON_MASK_LEFT
					ev.relative = Vector2(0, -40)
					var v0: float = vb.value
					rt.gui_input.emit(ev)
					dragged = dragged and vb.value > v0
					vb.value = vb.max_value
					tail_ok = tail_ok and vb.value + vb.page >= content - 2.0
			# the late journal's long column really is longer than its box, so it needs the scroll
			var long_col: bool = main.ui.journal_text.get_content_height() > main.ui.journal_text.size.y
			main.toggle_journal(false)
			# HUD: gems, companion rows, status box, touch keys
			for i in 2:
				main.ui.mate_rows[i].row.visible = true
			main.hud_build.layout_top()
			var gem_box := Rect2()
			var first := true
			for g in main.ui.hud.token_spots():
				var gr := Rect2(g - Vector2(6, 6), Vector2(12, 12))
				gem_box = gr if first else gem_box.merge(gr)
				first = false
			var mr: Rect2 = main.hud_build.mates_rect()
			var name_r := Rect2()
			for i in 2:
				var lab: Control = main.ui.mate_rows[i].row.get_child(1)
				var lr := Rect2(lab.global_position, lab.get_combined_minimum_size())
				name_r = lr if i == 0 else name_r.merge(lr)
			var clear: bool = not gem_box.intersects(mr) and not gem_box.intersects(name_r)
			var in_status: bool = main.hud_build.status_rect().encloses(gem_box)
			var blocks: Array = main.hud_build.quest_blocks(false)
			var missed := 0
			var keyn := 0
			if main.touch_layer != null:
				for kr in main.hud_build.touch_rects():
					keyn += 1
					if not blocks.any(func(b): return (b as Rect2).encloses(kr)):
						missed += 1
			var ok: bool = j_in and scrolls and dragged and tail_ok and long_col and clear and in_status and missed == 0 and (keyn >= 6 or not touch)
			all_ok = all_ok and ok
			rows.append("%s: journal %s in %s, column content/box %s, scroll+drag+end %s/%s/%s; gems y %d-%d, mates y %d (name y %d), clear %s; status ends y %d, gem box %s inside %s; touch keys %d, %d outside the avoid list" % [
				"touch" if touch else "keys", jr, vs, heights, scrolls, dragged, tail_ok, int(gem_box.position.y), int(gem_box.end.y), int(mr.position.y), int(name_r.position.y), clear, int(main.hud_build.status_rect().end.y), gem_box, in_status, keyn, missed])
		main.disable_touch()
		for i in 2:
			main.ui.mate_rows[i].row.visible = false
		for k in keep:
			main.set(k, keep[k])
		main.woke[0] = keep_woke
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		await wait(0.1)
		check("lap6_ui", all_ok, " | ".join(rows))
	if want.call("boss_hp7"):
		# v0.1.72 (the owner chose "bosses get tougher", 2026-10-28; boss7 review): moderate HP raises, and resting is
		# blocked all through a boss fight, not just inside the bar's range
		var rows := []
		var all_ok := true
		var want_hp := {"turtle": 1600, "crab": 1500, "hawk": 1500, "knight": 2200}
		main.lake_zone.spawn_turtle()
		main.lake_zone.spawn_crab()
		main.hill_zone.spawn_hawk()
		main.castle_zone.spawn_knight(false)
		var kn_echo_hp := 0
		main.castle_zone.spawn_knight(true) # the first knight is alive, so this returns early: the echo is checked below
		for k in want_hp:
			var f: Array = main.enemies.filter(func(e): return e.get(k, false) and not e.dead)
			var ok: bool = f.size() == 1 and f[0].max_hp == want_hp[k] and f[0].hp == float(want_hp[k])
			all_ok = all_ok and ok
			rows.append("%s %s" % [k, f[0].max_hp if f.size() == 1 else -1])
			for e in f:
				main.enemies.erase(e)
				if is_instance_valid(e.node):
					e.node.queue_free()
		main.castle_zone.spawn_knight(true)
		var ec: Array = main.enemies.filter(func(e): return e.get("echo", false) and not e.dead)
		all_ok = all_ok and ec.size() == 1 and ec[0].max_hp == 2200
		rows.append("echo %d" % (ec[0].max_hp if ec.size() == 1 else -1))
		for e in ec:
			main.enemies.erase(e)
			if is_instance_valid(e.node):
				e.node.queue_free()
		for sc in [[false, false, 1100], [true, false, 2000], [false, true, 2200]]:
			main.village_life.spawn_noeul_duel(sc[0], sc[1])
			var nf: Array = main.enemies.filter(func(e): return e.get("noeul", false) and not e.dead)
			all_ok = all_ok and nf.size() == 1 and nf[0].max_hp == sc[2]
			rows.append("noeul %d" % (nf[0].max_hp if nf.size() == 1 else -1))
			for e in nf:
				main.enemies.erase(e)
				if is_instance_valid(e.node):
					e.node.queue_free()
		# the mill guardian: 300 + 45 per foe level
		main.hill_zone.spawn_mill_guard()
		var mg: Array = main.enemies.filter(func(e): return e.get("mill_guard", false) and not e.dead)
		var mg_ok: bool = mg.size() == 1 and mg[0].max_hp == int(300.0 + main.foe_lv() * 45)
		all_ok = all_ok and mg_ok
		rows.append("mill %d" % (mg[0].max_hp if mg.size() == 1 else -1))
		for e in mg:
			main.enemies.erase(e)
			if is_instance_valid(e.node):
				e.node.queue_free()
		# rest healing: nothing 12 tiles from an awake boss, normal once it is beaten
		calm_enemies(true)
		main.village_life.spawn_noeul_duel(false, false)
		var nb: Dictionary = main.enemies.filter(func(e): return e.get("noeul", false) and not e.dead)[0]
		reset_to(Vector2(nb.x + 12.0, nb.z))
		main.ui.boss.visible = false
		main.story_open = false
		main.monsters.mark_fight(nb, 5.0) # she came close once and woke it
		main.monsters.mark_fight(nb, 12.0)
		main.player.hp = main.player.max_hp * 0.5
		main.idle_t = 10.0
		var h0: float = main.player.hp
		main.combat.rest_heal(1.0)
		var blocked: bool = main.player.hp == h0
		nb.dead = true
		main.combat.rest_heal(1.0)
		var healed: bool = main.player.hp > h0
		all_ok = all_ok and blocked and healed
		rows.append("rest 12 tiles from awake boss blocked=%s, after it is beaten healed=%s" % [blocked, healed])
		main.enemies.erase(nb)
		if is_instance_valid(nb.node):
			nb.node.queue_free()
		check("boss_hp7", all_ok, " | ".join(rows))
	if want.call("review_fixes"):
		# GPT review 2026-10-29 (v0.1.83): a story opened right after a close stays open; a story closes the sheets under
		# it; sfx_log and the splash sounds stay bounded; the fountain stops when Sora is away
		main.close_story()
		await wait(0.7)
		main.show_story("", ["||첫째 줄"])
		await wait(0.8) # past the old close fade
		var kept: bool = main.story_open and main.ui.story.visible and main.ui.story.modulate.a > 0.9
		main.close_story()
		main.show_story("", ["||F9 뒤의 확인"]) # as save.ask_reset does: the close fade must not hide the new box
		await wait(0.8)
		kept = kept and main.story_open and main.ui.story.visible and main.ui.story.modulate.a > 0.9
		main.close_story()
		await wait(0.7)
		main.toggle_settings(true)
		main.show_story("", ["||여관 첫 밤"])
		var no_settings: bool = not main.settings_open and not main.ui.settings.visible
		main.close_story()
		main.toggle_journal(true)
		main.show_story("", ["||여관 첫 밤"])
		var no_journal: bool = not main.ui.journal.visible
		main.close_story()
		main.toggle_help(true)
		main.show_story("", ["||여관 첫 밤"])
		var no_help: bool = not main.ui.help.visible and main.ui.hint.visible
		main.close_story()
		await wait(0.7)
		for i in 500:
			main.sfx(300.0 + i, 0.01, "square", 0.0)
		var log_ok: bool = main.sfx_log.size() <= 200 and main.sfx_log.back() == "square:799"
		var fa2: Vector2 = main.village.fountain_at()
		var v1: bool = main.in_village
		main.in_village = true
		reset_to(fa2 + Vector2(0, 3.0))
		main.village.fountain_set(main.village.fountain_wet)
		var live_on: bool = main.village.fountain_emitters.any(func(p): return p.emitting) and main.village.fountain_rings.all(func(tw): return tw.is_running())
		main.player.x = fa2.x + 40.0
		main.village.fountain_set(main.village.fountain_wet)
		var live_off: bool = not main.village.fountain_emitters.any(func(p): return p.emitting) and not main.village.fountain_rings.any(func(tw): return tw.is_running())
		main.player.x = fa2.x
		main.village.fountain_set(main.village.fountain_wet)
		main.in_village = v1
		var pitches: bool = main.village.SLAP_PITCHES.size() == 4
		check("review_fixes", kept and no_settings and no_journal and no_help and log_ok and live_on and live_off and pitches,
			"story kept after a close %s, settings closed %s, journal %s, help %s, log capped %s, fountain live near %s, still when away %s, 4 slap pitches %s" % [kept, no_settings, no_journal, no_help, log_ok, live_on, live_off, pitches])
	if want.call("pip_rest_far"):
		# resting by a lit lantern fills the moon light in every area, not just the village (v0.1.53): a monster 4.5 tiles
		# off does not notice her while she rests there, and the pips still come in
		# it walks into four areas, which marks them visited: put the progress and the test save back afterwards, or the
		# next run loads story step 10 from it
		var keep_q := [main.story_step, main.forest_q, main.lake_q, main.hill_q]
		var keep_save: String = FileAccess.get_file_as_string(main.SAVE_PATH) if FileAccess.file_exists(main.SAVE_PATH) else ""
		var rows := []
		var all_ok := true
		for z in [["marsh", -1.0, 100.0], ["forest", 180.0, 216.0], ["lake", 270.0, 310.0], ["hill", 310.0, 350.0]]:
			match z[0]:
				"forest": main.enter_forest()
				"lake": main.enter_lake()
				"hill": main.enter_hill()
			main.close_story()
			var lamps: Array = main.lanterns.filter(func(l): return l.position.x > z[1] and l.position.x < z[2] and not l.get_meta("dark", false))
			if lamps.is_empty():
				rows.append("%s: no lamp" % z[0])
				all_ok = false
				continue
			var lamp = lamps[0]
			calm_enemies(true)
			main.hour = 23.0
			main.crown_pips = 0
			reset_to(Vector2(lamp.position.x + 0.4, lamp.position.z + 1.0))
			main.last_input_t = main.t - 5.0
			main.spawn_enemy(Vector2(main.player.x + 4.5, main.player.z))
			var gob: Dictionary = main.enemies[main.enemies.size() - 1]
			var closest := 99.0
			for k in 32:
				await wait(0.25)
				closest = minf(closest, Vector2(gob.x - main.player.x, gob.z - main.player.z).length())
			var got: int = main.crown_pips
			var ok: bool = got >= 2 and closest > 2.5
			all_ok = all_ok and ok
			rows.append("%s lamp (%.0f, %.0f): pips %d in 8 s, goblin came within %.1f" % [z[0], lamp.position.x, lamp.position.z, got, closest])
			gob.dead = true
			gob.respawn = 9999.0
			if is_instance_valid(gob.node):
				gob.node.visible = false
		main.return_to_start()
		main.story_step = keep_q[0]
		main.forest_q = keep_q[1]
		main.lake_q = keep_q[2]
		main.hill_q = keep_q[3]
		if keep_save != "":
			var sf := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
			sf.store_string(keep_save)
			sf.close()
		check("pip_rest_far", all_ok, " | ".join(rows))
	if want.call("sora_breath"):
		# standing still Sora breathes (v0.1.54): the breath sheet, four frames turning over in a second
		main.idle_name = ""
		var seen := {}
		var on_sheet := false
		for k in 5:
			main.sora.update_idle(0.25)
			on_sheet = main.hero.texture.resource_path.get_file() == "breath.png"
			seen[int(main.hero.region_rect.position.x / (main.hero.texture.get_width() / 4.0))] = true
		main.idle_name = ""
		check("sora_breath", on_sheet and seen.size() == 4, "breath sheet %s, frames seen %d of 4" % [on_sheet, seen.size()])
	if want.call("rest_why"):
		# by day, standing by a lit lantern says why the moon light does not fill (v0.1.55)
		var h0: float = main.hour
		var lamp = main.lanterns.filter(func(l): return l.position.x < 100.0 and not l.get_meta("dark", false) and l != main.dark_lamp) # the marsh, where she starts
		var said := false
		if not lamp.is_empty():
			calm_enemies(true)
			main.hour = 12.0
			main.crown_pips = 0
			main.rest_why_said = false
			main.toast_t = 0.0
			reset_to(Vector2(lamp[0].position.x + 0.4, lamp[0].position.z + 1.0))
			await wait(1.8)
			said = main.rest_why_said and "낮에는" in main.ui.toast.text
		main.hour = h0
		main.crown_pips = main.pip_max
		check("rest_why", said, "marsh lamps lit %d, day reason said %s" % [lamp.size(), said])
	if want.call("hawk_unstick"):
		# a downed hawk whose win never landed is counted as beaten after 2 s, so the hill does not stall (v0.1.56)
		var q0: int = main.hill_q
		var qr: String = main.quest_raw
		var keep := [main.player.gold, main.player.xp, main.player.lv]
		main.hill_q = 2
		var stale := {"hawk": true, "dead": true, "cave": true, "x": main.hill.marks.B.x, "z": main.hill.marks.B.y}
		main.enemies.append(stale)
		for k in 30:
			main.hill_zone.hawk_unstick(0.1)
		var moved_on: bool = main.hill_q == 3 and not main.enemies.has(stale)
		main.close_story()
		main.hill_q = q0
		main.set_quest(qr)
		main.player.gold = keep[0]
		main.player.xp = keep[1]
		main.player.lv = keep[2]
		check("hawk_unstick", moved_on, "hill_q after 3 s with only a downed hawk: %d, stale entry gone %s" % [3 if moved_on else 2, not main.enemies.has(stale)])
	if want.call("camp_diary"):
		# Hangyeol's camp: E between the hook and the diary reads the diary while the quest is on it (v0.1.59)
		var q0: int = main.road_q
		var qr: String = main.quest_raw
		var k: Vector2 = main.garden.road_marks.k
		var j: Vector2 = main.garden.road_marks.j
		main.road_q = 2
		main.player.x = (k.x + j.x) / 2.0
		main.player.z = (k.y + j.y) / 2.0
		main.close_story()
		main.garden_zone.road_key()
		var moved_on: bool = main.road_q == 3
		main.close_story()
		main.road_q = q0
		main.set_quest(qr)
		check("camp_diary", moved_on, "standing between the hook and the diary, E with the quest on the diary: road_q %d (want 3)" % (3 if moved_on else 2))
	if want.call("click_guard"):
		# a click right as a story box opens does not skip its first line; one a moment later does (v0.1.60)
		main.close_story()
		await wait(0.6)
		# v0.1.74: a click anywhere never pages it on; the 다음 button waits for the line to type out, then E or the button does
		main.show_story("", ["||첫째 줄은 조금 길게 써서 글자가 찍히는 동안을 잰다", "||둘째 줄"])
		await wait(0.1)
		var hidden_typing: bool = not main.ui.story_more.visible
		tap(KEY_E)
		await wait(0.05)
		var key_kept: bool = main.story_lines.size() == 1
		main.ui.story_text.visible_characters = -1
		await wait(0.7)
		click()
		await wait(0.05)
		var click_kept: bool = main.story_open and main.story_lines.size() == 1
		var shown: bool = main.ui.story_more.visible
		main.ui.story_more.pressed.emit()
		await wait(0.05)
		var moved: bool = main.story_lines.is_empty()
		main.close_story()
		check("click_guard", hidden_typing and key_kept and click_kept and shown and moved, "button hidden while typing %s, E kept the line %s, a click elsewhere kept it %s, button shown after %s, button moved on %s" % [hidden_typing, key_kept, click_kept, shown, moved])
	if want.call("round_badge"):
		# from the second round the HUD says the round and its difficulty, and a banner opens it (v0.1.61)
		var ng0: int = main.ng
		main.ng = 1
		var badge: String = main.errands.round_badge()
		main.errands.round_banner()
		var banner: bool = main.ui.banner_title.text == "2회차 시작" and "1.5" in main.ui.banner_sub.text
		main.ng = ng0
		main.banner_t = 0.0
		check("round_badge", badge == "★ 2회차 · 난이도 ×1.5" and banner, "badge '%s', banner %s" % [badge, banner])
	if want.call("tree_shake"):
		# a cut that does not fell the tree rocks it, crown and trunk, and it settles back where it stood (v0.1.64)
		var wb = main.world_build
		var ok := false
		var info := "no standing marsh tree"
		for t in wb.marsh_trees:
			if t.down:
				continue
			var leaf0: Transform3D = wb.tree_mm.get_instance_transform(t.first)
			var trunk0: Transform3D = (t.trunk as Node3D).transform
			wb.shake_tree(t, Vector2(1, 0))
			var tw: Tween = t.tw
			tw.custom_step(0.12) # stepped by hand: the test's world may stand paused
			# the headless test renderer keeps no MultiMesh transforms (all identity): the leaves are judged only where it does
			var leaf_moved: bool = leaf0 == Transform3D() or not wb.tree_mm.get_instance_transform(t.first).is_equal_approx(leaf0)
			var trunk_moved: bool = not (t.trunk as Node3D).transform.is_equal_approx(trunk0)
			tw.custom_step(wb.TREE_SHAKE_T)
			var back: bool = wb.tree_mm.get_instance_transform(t.first).origin.distance_to(leaf0.origin) < 0.02 \
				and (t.trunk as Node3D).transform.origin.distance_to(trunk0.origin) < 0.02
			ok = leaf_moved and trunk_moved and back and t.hits == 0 and not t.down
			info = "leaves moved %s, trunk moved %s, back in place %s, hits %d" % [leaf_moved, trunk_moved, back, t.hits]
			break
		check("tree_shake", ok, info)
	if want.call("rest_heal"):
		# standing still with no monster near mends 2% of max HP a second after 3 s; not before, not with one near (v0.1.65)
		main.close_story()
		var keep_e: Array = main.enemies.duplicate()
		var hp0: float = main.player.hp
		var boss0: bool = main.ui.boss.visible
		main.ui.boss.visible = false
		main.enemies.clear()
		var mx: float = float(main.player.max_hp)
		main.player.hp = mx * 0.5
		main.idle_t = 1.0
		main.combat.rest_heal(1.0)
		var early: bool = is_equal_approx(main.player.hp, mx * 0.5)
		main.idle_t = 4.0
		main.combat.rest_heal(1.0)
		var healed: float = main.player.hp - mx * 0.5
		main.enemies.append_array(keep_e)
		main.ui.boss.visible = boss0
		main.player.hp = hp0
		check("rest_heal", early and absf(healed - mx * 0.02) < 0.01, "nothing at 1 s=%s, healed %.2f at 4 s (want %.2f)" % [early, healed, mx * 0.02])
	if want.call("story_moves_sora"):
		# a story that puts Sora elsewhere shows her there at once, not after the box closes (v0.1.77)
		main.close_story()
		await wait(0.6)
		main.show_story("", ["||첫째 줄", "||둘째 줄"])
		main.player.x += 6.0
		await wait(0.2)
		var at_once: bool = Vector2(main.hero.position.x - main.player.x, main.hero.position.z - main.player.z).length() < 0.1
		main.close_story()
		main.player.x -= 6.0
		await wait(0.3)
		check("story_moves_sora", at_once, "her picture moved with her while the box was open: %s" % at_once)
	if want.call("babble"):
		# a speaker's line babbles while it types, higher for Sora than for Noeul; narration is quiet (v0.1.82)
		main.close_story()
		await wait(0.6)
		main.sfx_log.clear()
		main.show_story("", ["소라||가나다라마바사아자차카타파하", "노을||가나다라마바사아자차카타파하", "||가나다라마바사아자차카타파하"])
		await wait(0.7)
		var sora_b: Array = main.sfx_log.filter(func(s): return String(s).begins_with("babble:"))
		main.ui.story_text.visible_characters = -1
		await wait(0.4)
		main.story.next_button()
		main.sfx_log.clear()
		await wait(0.7)
		var noeul_b: Array = main.sfx_log.filter(func(s): return String(s).begins_with("babble:"))
		main.ui.story_text.visible_characters = -1
		await wait(0.4)
		main.story.next_button()
		main.sfx_log.clear()
		await wait(0.7)
		var quiet: bool = not main.sfx_log.any(func(s): return String(s).begins_with("babble:"))
		main.close_story()
		var avg := func(a: Array) -> float:
			var t := 0.0
			for s in a:
				t += float(String(s).get_slice(":", 1))
			return t / maxf(1.0, a.size())
		check("babble", sora_b.size() >= 4 and noeul_b.size() >= 4 and avg.call(sora_b) > avg.call(noeul_b) and quiet,
			"Sora %d blips avg %.0f Hz, Noeul %d avg %.0f Hz, narration quiet %s" % [sora_b.size(), avg.call(sora_b), noeul_b.size(), avg.call(noeul_b), quiet])
	if want.call("trial_count"):
		# the moon trial shows its wave and the foes left on the quest line, and the real line comes back (v0.1.85)
		var qr0: String = main.quest_raw
		var h0: bool = main.in_hill
		var px: float = main.player.x
		var pz: float = main.player.z
		main.in_hill = true
		main.player.x = main.hill.marks.R.x + 2.0
		main.player.z = main.hill.marks.R.y
		main.trial_wave = 2
		main.trial_wait = 0.0
		main.minigames.update_trial(0.0)
		var during: String = plain(main.ui.quest.text)
		var shows: bool = "2/3" in during and "남은 괴물" in during and main.quest_raw == qr0
		main.minigames.end_trial("시험")
		var back: bool = plain(main.ui.quest.text) == plain(main.quest_shown(qr0))
		main.in_hill = h0
		main.player.x = px
		main.player.z = pz
		check("trial_count", shows and back, "during '%s', real line kept %s, back after %s" % [during, main.quest_raw == qr0, back])
	if want.call("toy_fence"):
		# struck again and again towards the fence, a brick never rolls off the village (the owner, 2026-10-30)
		var vg: Object = main.village
		var b1: MeshInstance3D = vg.toy_bricks[0]
		var keep_b: Vector3 = b1.position
		var px1: float = main.player.x
		var pz1: float = main.player.z
		var open_z: float = 0.0
		while vg.blocked(b1.position.x, open_z) and open_z < 20.0: # the first open row south of the north fence
			open_z += 1.0
		b1.position = Vector3(b1.position.x, 0.1, open_z) # right against the fence
		var out := false
		for k in 12:
			main.player.x = b1.position.x
			main.player.z = b1.position.z + 0.7
			vg.bricks_hit(main, 1.4, Vector2(0, -1), 0.3, false)
			await wait(1.3)
			out = out or vg.blocked(b1.position.x, b1.position.z)
		check("toy_fence", not out and open_z < 20.0, "12 blows at the north fence, brick on open ground every time (z %.2f)" % b1.position.z)
		b1.position = keep_b
		main.player.x = px1
		main.player.z = pz1
	if want.call("football_kick"):
		# a swing sends the ball along her facing at 7 tiles/s, it slows to a stop in about 1.5 s and turns as it goes; walking into it nudges it at 2.5
		var was_k: Array = fb_start()
		var fk: Object = main.football
		fb_put(Vector2(19.0, 23.0), Vector2(17.7, 23.0), Vector2(1, 0))
		var k0: int = fk.kicks
		var r0k: float = fk.rolled
		var x0k: float = fk.p.x
		main.attack()
		var sp0: float = fk.vel.length()
		var along: bool = fk.vel.normalized().dot(Vector2(1, 0)) > 0.99
		var thump: bool = main.sfx_log.any(func(sn): return String(sn) == "sine:150")
		var t_stop := 0.0
		while fk.vel.length() > 0.01 and t_stop < 3.0:
			await wait(0.05)
			t_stop += 0.05
		var went: float = fk.p.x - x0k
		var turned: float = fk.rolled - r0k
		var spun: bool = absf(turned - went) < 0.3 and fk.ball_mesh.basis.get_euler().length() > 0.01
		fb_put(Vector2(20.0, 23.0), Vector2(19.5, 23.0), Vector2(1, 0))
		main.player.vx = 3.6
		main.player.vz = 0.0
		fk.update(0.016)
		var nudge: float = fk.vel.length()
		var one_kick: bool = fk.kicks == k0 + 1
		var timing: bool = t_stop > 1.0 and t_stop < 2.0
		check("football_kick", one_kick and absf(sp0 - 7.0) < 0.01 and along and thump and timing and went > 2.5 and went < 4.0 and spun and nudge > 2.3 and nudge < 2.55,
			"one kick %s, speed %.2f along her facing %s, thump %s, stopped after %.2f s (1 to 2) after %.2f tiles, rolled %.2f (turned like the way %s), walked into it %.2f tiles/s" % [one_kick, sp0, along, thump, t_stop, went, turned, spun, nudge])
		fb_end(was_k)
	if want.call("football_bounce"):
		# it bounces off the pitch's edge, a post and the lamp losing 40%, stays on the pitch, and a stuck or strayed ball rolls back
		var was_b: Array = fb_start()
		var fbn: Object = main.football
		var vxb: float = main.village.VILLAGE_X
		fb_put(Vector2(24.6, 23.0), Vector2(40.0, 20.0), Vector2(1, 0))
		fbn.vel = Vector2(7.0, 0)
		var b0: int = fbn.bounces
		var inside := true
		var vmax := 0.0
		for i in 24:
			await wait(0.05)
			inside = inside and fbn.bounds.has_point(fbn.p)
			if i < 12 and fbn.bounces > b0:
				vmax = maxf(vmax, absf(fbn.vel.x))
		var edge_ok: bool = fbn.bounces > b0 and inside and vmax < 7.0 * 0.62 and vmax > 7.0 * 0.3
		var b1: int = fbn.bounces
		var g_b: int = fbn.goals
		fb_put(Vector2(22.1, 25.4), Vector2(40.0, 20.0), Vector2(0, 1))
		fbn.vel = Vector2(0, 6.0)
		await wait(0.9)
		var post_ok: bool = fbn.bounces > b1 and fbn.vel.y <= 0.0 and fbn.p.y < fbn.goal_z and fbn.goals == g_b and fbn.state == "play"
		var b2: int = fbn.bounces
		fb_put(Vector2(25.0, 22.8), Vector2(40.0, 20.0), Vector2(0, -1)) # up the line into the corner flag
		fbn.vel = Vector2(0, -6.0)
		await wait(0.9)
		var basin_ok: bool = fbn.bounces > b2 and fbn.p.distance_to(Vector2(vxb + 25.0, 21.8)) >= 0.25 and fbn.vel.y >= 0.0
		fb_put(Vector2(17.2, 28.0), Vector2(40.0, 20.0), Vector2(1, 0))
		fbn.away_t = fbn.HOME_AFTER - 0.5
		await wait(0.9)
		var rolling_home: bool = fbn.state == "home"
		await wait(1.5)
		var back_stuck: bool = fbn.state == "play" and fbn.p.distance_to(fbn.spot) < 0.05
		fb_put(Vector2(28.0, 22.0), Vector2(40.0, 20.0), Vector2(1, 0))
		await wait(2.2)
		var back_out: bool = fbn.state == "play" and fbn.p.distance_to(fbn.spot) < 0.05
		var near_sora: bool = true # a ball near Sora is left where it lies
		fb_put(Vector2(17.2, 28.0), Vector2(18.2, 27.2), Vector2(1, 0))
		fbn.away_t = fbn.HOME_AFTER - 0.5
		await wait(1.0)
		near_sora = fbn.state == "play" and fbn.p.distance_to(Vector2(vxb + 17.2, 28.0)) < 0.05
		check("football_bounce", edge_ok and post_ok and basin_ok and rolling_home and back_stuck and back_out and near_sora,
			"edge bounce keeps 40-60%% and stays inside %s (kept %.1f of 7), post %s, lamp %s, stuck ball rolls home after 10 s away %s then rests on its spot %s, one off the pitch comes home %s, one beside her stays %s" % [edge_ok, vmax, post_ok, basin_ok, rolling_home, back_stuck, back_out, near_sora])
		fb_end(was_b)
	if want.call("football_goal"):
		# swings drive it in from in front of the goal: the screen flashes three times, the banner shows the count, goals +1 once only,
		# the ball pops back to its spot about 1.4 s later
		var was_g: Array = fb_start()
		var fg: Object = main.football
		var keep_save: String = FileAccess.get_file_as_string(main.SAVE_PATH)
		fb_put(Vector2(21.0, 26.0), Vector2(21.0, 24.8), Vector2(0, 1))
		var g0: int = fg.goals
		var fl0: int = fg.flashes
		main.attack()
		var got: bool = await wait_for(func(): return fg.goals > g0, 1.5)
		var t_goal := gsec()
		await wait(0.12)
		var flash_on: bool = fg.flash != null and fg.flash.color.a > 0.05
		var banner_on: bool = fg.banner != null and fg.banner.visible and "골" in fg.banner.text and fg.banner.text.ends_with(" %d" % (g0 + 1))
		var in_net: bool = fg.state == "net" and fg.p.y > fg.goal_z and fg.p.x > fg.goal_x0 and fg.p.x < fg.goal_x1
		main.player.atk_cd = 0.0
		main.attack() # a swing at the ball in the net counts for nothing
		await wait(0.9)
		var three: bool = fg.flashes == 3
		var once: bool = fg.goals == g0 + 1
		await wait_for(func(): return fg.state == "play", 2.0)
		var t_back: float = gsec() - t_goal
		var at_spot: bool = fg.p.distance_to(fg.spot) < 0.05 and fg.vel.length() < 0.01
		await wait(1.3)
		var faded: bool = fg.banner != null and not fg.banner.visible
		var saved = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var in_save: bool = typeof(saved) == TYPE_DICTIONARY and int(saved.get("goals", -1)) == g0 + 1
		var f2 := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f2.store_string(keep_save)
		f2.close()
		check("football_goal", got and flash_on and banner_on and in_net and three and once and t_back > 1.0 and t_back < 1.8 and at_spot and faded and in_save,
			"scored %s, flash on %s x%d (%d before), banner '%s' %s, ball in the net %s, goals %d -> %d once only %s, back on its spot after %.2f s %s, banner gone %s, goals in the save %s" % [got, flash_on, fg.flashes, fl0, fg.banner.text if fg.banner != null else "", banner_on, in_net, g0, fg.goals, once, t_back, at_spot, faded, in_save])
		fg.goals = g0
		fb_end(was_g)
	if want.call("football_cheer"):
		# a goal with Noeul and Mulgyeol near: both jump twice and shout, Mulgyeol 0.35 s after Noeul; far off, nobody cheers
		var was_c: Array = fb_start()
		var fc: Object = main.football
		var keep_c: String = FileAccess.get_file_as_string(main.SAVE_PATH)
		var gc: int = fc.goals
		main.join_mate()
		main.join_noeul()
		fb_put(Vector2(21.0, 26.0), Vector2(21.0, 24.8), Vector2(0, 1))
		main.snap_mates()
		var said0: int = main.bubbles_said
		main.attack()
		var scored: bool = await wait_for(func(): return fc.goals > gc, 1.5)
		var two: bool = fc.cheers == 2 and main.folk.cheer_t.get("noeul", 0.0) > 0.0 and main.folk.cheer_t.get("mulgyeol", 0.0) > 0.0
		var y0: float = main.mate2.get_child(0).position.y
		await wait(0.25)
		var jumped: bool = main.mate2.get_child(0).position.y > y0 + 0.2
		var first: bool = main.bubbles_said == said0 + 1
		await wait(0.3)
		var both: bool = main.bubbles_said == said0 + 2
		await wait(1.6)
		fc.cheer() # far off: nobody
		reset_to(Vector2(main.village.VILLAGE_X + 40.0, 20.0))
		main.mate.position = Vector3(main.player.x + 30.0, 0, main.player.z)
		main.mate2.position = Vector3(main.player.x + 30.0, 0, main.player.z)
		fc.cheer()
		var far_quiet: bool = fc.cheers == 0
		main.snap_mates()
		var f4 := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f4.store_string(keep_c)
		f4.close()
		fc.goals = gc
		check("football_cheer", scored and two and jumped and first and both and far_quiet,
			"scored %s, both cheer %s (%d), Noeul jumped %s, Noeul's line first %s, then Mulgyeol's %s, far off nobody %s" % [scored, two, fc.cheers, jumped, first, both, far_quiet])
		fb_end(was_c)
	if want.call("football_save"):
		# the goal count is kept in the save and over a new round, and an old save without it starts at 0
		var was_s: Array = fb_start()
		var fs: Object = main.football
		var keep_s: String = FileAccess.get_file_as_string(main.SAVE_PATH)
		var g_s: int = fs.goals
		fs.goals = 7
		main.save_game()
		var d1 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var saved1: bool = typeof(d1) == TYPE_DICTIONARY and int(d1.get("goals", -1)) == 7
		fs.goals = 0
		main.load_game()
		var loaded: bool = fs.goals == 7
		fs.load_data({})
		var old_ok: bool = fs.goals == 0
		fs.goals = 7
		main.write_new_round()
		var d2 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var round_ok: bool = typeof(d2) == TYPE_DICTIONARY and int(d2.get("goals", -1)) == 7 and int(d2.get("story", -1)) == 0
		var f3 := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f3.store_string(keep_s)
		f3.close()
		fs.goals = g_s
		check("football_save", saved1 and loaded and old_ok and round_ok, "saved %s, loaded back %s, an old save reads 0 %s, a new round keeps it %s" % [saved1, loaded, old_ok, round_ok])
		fb_end(was_s)
	if want.call("football_north"):
		# the second goal: a ball over the north line scores just as the south one does, and the board keeps count
		var wn: Array = fb_start()
		var fn: Object = main.football
		var gn: int = fn.goals
		fb_put(Vector2(21.0, 22.6), Vector2(21.0, 23.8), Vector2(0, -1))
		main.attack()
		var in_n: bool = await wait_for(func(): return fn.state == "net", 3.0)
		var over: bool = fn.p.y < fn.goal_n and fn.goals == gn + 1
		var told: bool = str(gn + 1) in fn.board.text
		await wait_for(func(): return fn.state == "play", 3.0)
		var at_spot: bool = fn.p.distance_to(fn.spot) < 0.05
		# wide of the post: a bounce, not a goal
		var gb: int = fn.goals
		fb_put(Vector2(19.0, 22.2), Vector2(19.0, 23.4), Vector2(0, -1))
		main.attack()
		await wait(0.8)
		var wide: bool = fn.goals == gb
		fb_end(wn)
		check("football_north", in_n and over and told and at_spot and wide, "in the north net %s, counted %s, board '%s' %s, back on the centre spot %s, wide of the post no goal %s" % [in_n, over, fn.board.text, told, at_spot, wide])
	if want.call("pitch_marks"):
		# two goals face each other across the centre spot, the ball lies midway, the goals stay on the lawn
		var fp: Object = main.football
		var mid_z: float = (fp.goal_z + fp.goal_n) / 2.0
		var centred: bool = absf(fp.spot.y - mid_z) < 0.01 and absf(fp.spot.x - (fp.goal_x0 + fp.goal_x1) / 2.0) < 0.01
		var inside: bool = fp.goal_n - fp.GOAL_DEPTH >= fp.bounds.position.y and fp.goal_z + fp.GOAL_DEPTH <= fp.bounds.end.y
		check("pitch_marks", centred and inside and fp.board != null, "ball on the centre %s, goals inside the lawn %s, board %s" % [centred, inside, fp.board != null])
	if want.call("ending_home"):
		# from the ending on Sora's shoes are on Bori's mat, a fourth cup on the plank, and the mat says so
		marsh_world()
		var mt2: Object = main.marsh_toys
		var wb2: Object = main.world_build
		var s0h: int = main.story_step
		var n0h: int = main.ng
		main.story_step = 5
		main.ng = 0
		await wait(0.2)
		var before_home: bool = not mt2.mat_shoes.visible and not wb2.tea_fourth.visible
		main.story_step = 12
		await wait(0.2)
		var after_home: bool = mt2.mat_shoes.visible and wb2.tea_fourth.visible
		reset_to(mt2.mat_at + Vector2(0.3, 0.3))
		main.crown_key()
		var mat_says: bool = main.story_open and "소라의 신" in "\n".join(PackedStringArray(main.story_lines))
		main.close_story()
		var e_lines: Array = main.STORY.ENDING
		var ends: bool = "소라|laugh|……네. 여기요." in e_lines and e_lines.any(func(l): return "처음 온 날에도" in String(l))
		main.story_step = 0
		main.ng = 1
		await wait(0.2)
		var new_round: bool = mt2.mat_shoes.visible
		main.story_step = s0h
		main.ng = n0h
		check("ending_home", before_home and after_home and mat_says and ends and new_round, "nothing before the ending %s, shoes and cup after %s, the mat says so %s, ending lines %s, kept in a new round %s" % [before_home, after_home, mat_says, ends, new_round])
	if want.call("football_quiet"):
		# no kick, nudge or push during a story, with the bag open or with a foe within 8 tiles; the same swing kicks it otherwise
		var was_q: Array = fb_start()
		var fq: Object = main.football
		fb_put(Vector2(19.0, 23.0), Vector2(17.7, 23.0), Vector2(1, 0))
		var kq: int = fq.kicks
		main.story_open = true
		main.attack()
		var story_still: bool = fq.kicks == kq and fq.vel.length() < 0.01
		main.story_open = false
		fb_put(Vector2(19.0, 23.0), Vector2(17.7, 23.0), Vector2(1, 0))
		main.ui.bag.visible = true
		main.attack()
		var bag_still: bool = fq.kicks == kq and fq.vel.length() < 0.01
		main.ui.bag.visible = false
		fb_put(Vector2(19.0, 23.0), Vector2(17.7, 23.0), Vector2(1, 0))
		var vq: float = main.village.VILLAGE_X
		var foe := marsh_foe(Vector2(vq + 17.7, 15.7)) # 7.3 tiles north of her
		main.attack()
		var foe_still: bool = foe and fq.kicks == kq and fq.vel.length() < 0.01
		main.player.vx = 3.6
		fq.p = Vector2(vq + 18.2, 23.0) # touching her, but a foe is near
		fq.update(0.016)
		foe_still = foe_still and fq.vel.length() < 0.01
		calm_enemies(true)
		fb_put(Vector2(19.0, 23.0), Vector2(17.7, 23.0), Vector2(1, 0))
		main.attack()
		var control: bool = fq.kicks == kq + 1 and fq.vel.length() > 6.0
		check("football_quiet", story_still and bag_still and foe_still and control, "still in a story %s, with the bag open %s, with a foe 7.3 tiles off %s (foe placed %s); the same swing kicks it when all is calm %s" % [story_still, bag_still, foe_still, foe, control])
		fb_end(was_q)
	if want.call("bori_pinwheel"):
		# a pinwheel stands in front of Bori's door and turns slowly in the marsh breeze; a real swing whirls it, then it eases back
		var mt: Object = main.marsh_toys
		var built: bool = mt.pin_hub != null and mt.pin_at.distance_to(main.cottage_at) < 3.2
		var was_in: Array = [main.in_village, main.in_forest, main.in_lake, main.in_hill, main.in_garden, main.in_cave]
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		main.close_story()
		calm_enemies(true)
		var turns := false
		var whirled := false
		var eased := false
		var far_quiet := false
		if built:
			# waits on the turn itself, not a fixed time: late in a full run the game clock can lag the timer
			var r0: float = mt.pin_hub.rotation.z
			turns = await wait_for(func(): return absf(mt.pin_hub.rotation.z - r0) > 0.8, 3.0) # about 2.5 rad/s
			var h0: int = mt.pin_hits
			reset_to(mt.pin_at + Vector2(-1.1, 0.0))
			main.player.face = Vector2(1, 0)
			main.player.atk_cd = 0.0
			main.attack()
			whirled = mt.pin_hits == h0 + 1 and mt.pin_spin > 2.0
			var r1: float = mt.pin_hub.rotation.z
			var s1: float = mt.pin_spin
			await wait_for(func(): return s1 - mt.pin_spin >= 0.2, 2.0) # 0.2 s of game time
			whirled = whirled and absf(mt.pin_hub.rotation.z - r1) > 2.0 # near 20 rad/s
			eased = await wait_for(func(): return mt.pin_spin == 0.0, 8.0)
			reset_to(mt.pin_at + Vector2(-6.0, 0.0))
			main.player.atk_cd = 0.0
			main.attack()
			far_quiet = mt.pin_hits == h0 + 1
		calm_enemies(false)
		main.in_village = was_in[0]
		main.in_forest = was_in[1]
		main.in_lake = was_in[2]
		main.in_hill = was_in[3]
		main.in_garden = was_in[4]
		main.in_cave = was_in[5]
		check("bori_pinwheel", built and turns and whirled and eased and far_quiet,
			"by Bori's door %s (at %s), turns in the breeze %s, a swing whirls it %s, eases back %s, a swing 6 tiles off does nothing %s" % [built, mt.pin_at, turns, whirled, eased, far_quiet])
	if want.call("pinwheel_hit"):
		# a swing that reaches a pinwheel spins it at about 20 rad/s and it eases down over 2.5 s: to still when its windmill is not mended, to its usual turn when it is
		var was_p: Array = fb_start()
		var vp: Object = main.village
		var mills_p: Array = main.hill.mills.map(func(mm): return mm.turning)
		var mq_p: int = main.mill_q
		for mm in main.hill.mills:
			mm.turning = false
		main.mill_q = 0
		var h0p: int = vp.pinwheel_hits
		fb_put(Vector2(15.0, 12.0), Vector2(7.5, 3.8), Vector2(0, -1))
		main.attack()
		var hit_one: bool = vp.pinwheel_hits == h0p + 1 and absf(vp.pinwheels[0].spin - 2.5) < 0.01 and vp.pinwheels[1].spin == 0.0
		var rot_a: float = vp.pinwheels[0].hub.rotation.z
		vp.life_update(main, 0.1)
		var fast: float = (rot_a - vp.pinwheels[0].hub.rotation.z) / 0.1
		for i in 12:
			vp.life_update(main, 0.1)
		var rot_m: float = vp.pinwheels[0].hub.rotation.z
		vp.life_update(main, 0.1)
		var mid: float = (rot_m - vp.pinwheels[0].hub.rotation.z) / 0.1
		for i in 14:
			vp.life_update(main, 0.1)
		var rot_z: float = vp.pinwheels[0].hub.rotation.z
		vp.life_update(main, 0.5)
		var still_now: bool = absf(vp.pinwheels[0].hub.rotation.z - rot_z) < 0.0001
		var whirr: bool = main.sfx_log.any(func(sn): return String(sn) == "noise:520")
		main.hill.mills[1].turning = true # a mended windmill: its pinwheel turns at 4.6 already
		fb_put(Vector2(15.0, 12.0), Vector2(17.5, 3.8), Vector2(0, -1))
		vp.life_update(main, 0.1)
		main.attack()
		var rot_b: float = vp.pinwheels[1].hub.rotation.z
		vp.life_update(main, 0.1)
		var fast_b: float = (rot_b - vp.pinwheels[1].hub.rotation.z) / 0.1
		for i in 26:
			vp.life_update(main, 0.1)
		var rot_c: float = vp.pinwheels[1].hub.rotation.z
		vp.life_update(main, 0.1)
		var usual: float = (rot_c - vp.pinwheels[1].hub.rotation.z) / 0.1
		for i in main.hill.mills.size():
			main.hill.mills[i].turning = mills_p[i]
		main.mill_q = mq_p
		check("pinwheel_hit", hit_one and fast > 17.0 and fast < 20.5 and mid > 6.0 and mid < 14.0 and still_now and whirr and fast_b > 17.0 and absf(usual - 4.6) < 0.1,
			"one pinwheel hit %s, spin right after %.1f rad/s (20), at 1.3 s %.1f, still after 2.5 s %s, whirr %s; a turning one %.1f then back to %.2f (4.6)" % [hit_one, fast, mid, still_now, whirr, fast_b, usual])
		fb_end(was_p)
	if want.call("toy_bricks"):
		# a blow at a village brick pile sends its bricks rolling apart, each its own way, and they settle (v0.1.87)
		var bs: Array = main.village.toy_bricks
		var ok := false
		var info := "no toy bricks"
		if not bs.is_empty():
			var b0: MeshInstance3D = bs[0]
			var px: float = main.player.x
			var pz: float = main.player.z
			main.player.x = b0.position.x - 0.8
			main.player.z = b0.position.z
			var before: Array = bs.map(func(b): return b.position)
			var r0: int = main.village.toy_rolls
			main.village.bricks_hit(main, 1.4, Vector2(1, 0), 0.3, true)
			await wait(1.5)
			var moved := 0
			var flat := true
			for i in bs.size():
				var b: MeshInstance3D = bs[i]
				if b.position.distance_to(before[i]) > 0.5:
					moved += 1
					flat = flat and not b.has_meta("rolling") and absf(b.position.y - 0.1) < 0.01
			ok = main.village.toy_rolls - r0 >= 3 and moved >= 3 and flat
			info = "rolled %d, moved %d, settled flat %s" % [main.village.toy_rolls - r0, moved, flat]
			main.player.x = px
			main.player.z = pz
		check("toy_bricks", ok, info)
	if want.call("hud_plates"):
		# the place's name, the status bars and the quest line sit on navy plates that hold all their letters (v0.1.92)
		main.set_quest("옥좌의 방으로 가자")
		await wait(0.3)
		var h = main.ui.hud
		var zone_ok: bool = h.zone_plate_rect.size.x > 40.0 and h.zone_plate_rect.size.y > 30.0
		var status_ok: bool = h.status_plate_rect.size.x > h.bar_w() + 52.0
		var quest_ok: bool = h.quest_plate_rect.size.x >= main.hud_build.quest_deco.size.x
		check("hud_plates", zone_ok and status_ok and quest_ok, "zone %s status %s quest %s" % [h.zone_plate_rect, h.status_plate_rect, h.quest_plate_rect])
	if want.call("credits"):
		# the ending's last line opens the credits; they roll up, a key after 1.5 s skips them, and the hint follows
		main.close_story()
		await wait(0.6)
		var hinted := [false]
		main.garden_zone.credits_in_tests = true
		main.garden_zone.roll_credits(func(): hinted[0] = true)
		await wait(2.0)
		var cr = main.garden_zone.credits
		var up: bool = cr != null and is_instance_valid(cr) and main.story_open
		var y0: float = cr.col.position.y if up else 0.0
		await wait(1.0)
		var rolls: bool = up and cr.col.position.y < y0 - 20.0
		tap(KEY_SPACE)
		await wait(1.0)
		main.garden_zone.credits_in_tests = false
		check("credits", up and rolls and hinted[0] and not main.story_open and main.garden_zone.credits == null, "up %s rolls %s ended and handed on %s" % [up, rolls, hinted[0]])
	if want.call("folk_mark"):
		# the gold "!" over the villager the quest names (in the village) and over Bori's cottage (in the marsh)
		var q0: String = main.quest_raw
		var v0: bool = main.in_village
		var mate0 = main.mate
		main.close_story()
		main.in_village = true
		main.mate = null
		main.quest_raw = "마을의 뱃사공 물결에게 가 보자 (E)"
		var mp: Vector2 = main.folk.folk_talk_at("mulgyeol")
		reset_to(mp + Vector2(4, 0))
		var at: Vector3 = main.castle_zone.folk_target()
		var over_mul: bool = at != Vector3.INF and Vector2(at.x, at.z).distance_to(mp) < 0.1 and at.y > 2.0
		main.quest_raw = "숲에 가자"
		var none: bool = main.castle_zone.folk_target() == Vector3.INF
		main.in_village = false
		main.mate = mate0
		reset_to(main.cottage_at + Vector2(3, 0))
		main.quest_raw = q0
		main.quest_raw = "서쪽 오두막의 보리 할머니에게 가 보자"
		var at2: Vector3 = main.castle_zone.folk_target()
		var over_cot: bool = at2 != Vector3.INF and Vector2(at2.x, at2.z).distance_to(main.cottage_at) < 0.1
		main.quest_raw = q0
		main.in_village = v0
		check("folk_mark", over_mul and none and over_cot, "over Mulgyeol=%s none for a quest naming nobody=%s over Bori's cottage=%s" % [over_mul, none, over_cot])
	if want.call("island_landing"):
		# on the island after the turtle: the gold "!" over the north landing, and the shore says where the boat leaves
		var keep := [main.in_lake, main.lake_q, main.quest_raw, main.player.x, main.player.z, main.player.face, main.in_village]
		main.close_story()
		main.in_village = false
		main.in_lake = true
		main.lake_q = 4
		main.quest_raw = "물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"
		main.player.x = main.LAKE.LAKE_X + 12.0
		main.player.z = 18.0
		var tg: Vector3 = main.step_target()
		var over_q: bool = tg != Vector3.INF and Vector2(tg.x, tg.z).distance_to(main.lake.marks.Q) < 0.5
		main.player.x = main.LAKE.LAKE_X + 7.0
		main.player.z = 17.0
		main.player.face = Vector2(-1, 0)
		main.lake_zone.at_shore = false
		main.toast_t = 0.0
		main.ui.toast.text = ""
		main.lake_zone.shore_hint(Vector2(main.player.x, main.player.z))
		var said: bool = main.ui.toast.text.contains("나루")
		main.quest_raw = "굳은 숲으로"
		var gone: bool = main.step_target() == Vector3.INF
		check("island_landing", over_q and said and gone, "! over the landing=%s shore toast=%s ('%s') none on another quest=%s" % [over_q, said, main.ui.toast.text, gone])
		main.in_lake = keep[0]
		main.lake_q = keep[1]
		main.quest_raw = keep[2]
		main.player.x = keep[3]
		main.player.z = keep[4]
		main.player.face = keep[5]
		main.in_village = keep[6]
		main.lake_zone.at_shore = false
		main.ui.toast.text = ""
	if want.call("bori_away"):
		# Bori has no figure outside her shop: scenes where she is not standing give her no face line
		var faced := []
		for name in ["CLOCK_HUB", "CLOCK_LATE", "CLOCK_WOUND", "FINAL_SHORT"]:
			for line in main.STORY.get(name):
				if String(line).contains("|bori"):
					faced.append(name)
		check("bori_away", faced.is_empty(), "Bori face lines where she is not: %s" % [faced])
	if want.call("bus_layout"):
		# the web build's sample playback only reaches the speakers through buses that exist when the engine starts
		# (made at runtime they stayed silent: the owner heard nothing until v0.0.87), so the layout file holds them
		var lay = load("res://default_bus_layout.tres")
		var names: Array = []
		if lay != null:
			for k in [1, 2]:
				names.append(str(lay.get("bus/%d/name" % k)))
		check("bus_layout", names == ["Sfx", "Music"], "buses in default_bus_layout.tres: %s" % [names])
	if want.call("ending_replay"):
		# the journal's 엔딩 다시 보기: hidden before the ending, after it the festival picture and lines again, nothing paid
		var keep_step: int = main.story_step
		var keep_ng: int = main.ng
		main.close_story()
		main.story_step = 11
		main.ng = 0
		main.toggle_journal(true)
		var hidden_before: bool = not main.ui.ending_btn.visible
		main.garden_zone.replay_ending()
		var none_before: bool = not main.story_open
		main.toggle_journal(false)
		main.story_step = 12
		main.toggle_journal(true)
		var shown_after: bool = main.ui.ending_btn.visible
		var gold0: int = main.player.gold
		main.ui.ending_btn.pressed.emit()
		var pic: bool = main.story_open and main.ui.story_img.texture != null and main.ui.story_img.texture.resource_path == main.garden_zone.ENDING_PICTURE
		var closed: bool = not main.ui.journal.visible
		main.close_story()
		var unpaid: bool = main.player.gold == gold0 and main.story_step == 12
		main.story_step = keep_step
		main.ng = keep_ng
		check("ending_replay", hidden_before and none_before and shown_after and pic and closed and unpaid,
			"hidden before=%s nothing before=%s shown after=%s ending picture=%s journal closed=%s unpaid=%s" % [hidden_before, none_before, shown_after, pic, closed, unpaid])
	if want.call("mural_split"):
		# the cave painting: the mural alone first, Noeul's picture from his first line on
		main.close_story()
		main.show_story(main.MURAL_PICTURE, main.STORY.PAINTING)
		var first: String = main.ui.story_img.texture.resource_path
		var seen := ""
		for k in 8:
			main.ui.story_text.visible_characters = -1
			main.story.next_story()
			if main.ui.story_who.text == "???":
				seen = main.ui.story_img.texture.resource_path
				break
		main.close_story()
		# E at the mural afterwards: the picture alone, one line, no Noeul
		var keep_seen: bool = main.saw_painting
		var keep_cave: bool = main.in_cave
		main.saw_painting = true
		main.in_cave = true
		main.player.x = main.cave_marks.P.x
		main.player.z = main.cave_marks.P.y
		var again: bool = main.cave_interact() and main.story_open and main.ui.story_img.texture.resource_path.ends_with("06_cave_mural.jpg") and main.story_lines.is_empty()
		main.close_story()
		main.saw_painting = keep_seen
		main.in_cave = keep_cave
		main.return_to_start()
		check("mural_split", first.ends_with("06_cave_mural.jpg") and seen.ends_with("06_cave_rival.jpg") and again, "first %s, at Noeul's line %s, again=%s" % [first.get_file(), seen.get_file(), again])
	if want.call("area_steps"):
		# monsters grow with the land: at one level, the forest's foe level is above the marsh's, the garden's above both
		var keep_x: float = main.player.x
		main.player.x = 20.0
		var marsh: int = main.foe_lv()
		main.player.x = 190.0
		var forest: int = main.foe_lv()
		main.player.x = 240.0
		var garden: int = main.foe_lv()
		main.player.x = keep_x
		check("area_steps", marsh < forest and forest < garden, "foe level marsh %d < forest %d < garden %d" % [marsh, forest, garden])
	if want.call("tree_chop"):
		# a marsh tree falls after three sword hits, lets Sora through and is gone a moment later
		main.close_story()
		calm_enemies(true)
		var t: Dictionary = main.world_build.marsh_trees.filter(func(tt): return not tt.down)[0]
		reset_to(Vector2(t.x - 1.2, t.z))
		main.player.face = Vector2(1, 0)
		var rocks0: int = main.rocks.size()
		for k in 3:
			main.player.atk_cd = 0.0
			main.player.combo_t = 0.0
			main.player.face = Vector2(1, 0)
			main.attack()
			await wait(0.1)
		var fell: bool = t.down and main.rocks.size() == rocks0 - 1
		await wait(2.4)
		var gone: bool = not (t.trunk as Node3D).visible
		calm_enemies(false)
		main.return_to_start()
		check("tree_chop", fell and gone, "three hits fell it and freed its tile=%s gone after 2.4 s=%s (hits %d)" % [fell, gone, t.hits])
	if want.call("lantern_toggle"):
		# E beside a lit lantern puts it out and lights it again; one the story keeps dark is left alone
		main.close_story()
		var lit: Array = main.lanterns.filter(func(l): return l.has_meta("glass") and not l.get_meta("dark", false) and l != main.dark_lamp and l.position.x < 100.0)
		var l: OmniLight3D = lit[0]
		main.player.x = l.position.x - 0.3
		main.player.z = l.position.z + 0.6
		var off: bool = main.toggle_lantern() and l.get_meta("dark", false)
		var on: bool = main.toggle_lantern() and not l.get_meta("dark", false)
		var kept := true
		if main.dark_lamp != null:
			main.player.x = main.dark_lamp.position.x - 0.3
			main.player.z = main.dark_lamp.position.z + 0.6
			kept = not main.toggle_lantern() or main.dark_lamp.get_meta("dark", false) == false
		main.return_to_start()
		check("lantern_toggle", off and on, "off=%s on again=%s story lamp left alone=%s" % [off, on, kept])
	if want.call("chain_cut"):
		# a J pressed in a swing's last moment is kept and swung as soon as it ends; a landed swing recovers faster
		main.close_story()
		main.combat.last_hit_t = -9.0
		main.player.atk_cd = 0.1
		main.combat.buffer_t = 0.0
		main.attack() # too early: kept, not swung
		var kept: bool = main.combat.buffer_t > 0.0
		main.player.combo_t = 0.0
		await wait(0.2)
		var swung: bool = main.combat.buffer_t <= 0.0 and main.player.atk_cd > 0.0
		main.player.atk_cd = 0.5
		main.combat.buffer_t = 0.0
		main.attack() # far too early: dropped
		var dropped: bool = main.combat.buffer_t <= 0.0
		main.player.atk_cd = 0.0
		check("chain_cut", kept and swung and dropped, "kept a late press=%s swung when the swing ended=%s an early press dropped=%s" % [kept, swung, dropped])
	if want.call("seam_pins"):
		# a goblin whose swing misses shows its seams: three cuts then pop its pins and it comes loose
		main.close_story()
		calm_enemies(false)
		var gob = main.enemies.filter(func(e): return not e.get("boss", false) and not e.get("prop", false) and not e.dead and not e.get("archer", false))[0]
		main.monsters.open_seam(gob)
		var open: bool = gob.seam > 0.0 and gob.pins == 3
		gob.hp = 9999.0
		var hp0: float = gob.hp
		main.player.inv = 5.0
		for k in 3:
			main.damage_enemy(gob, 10.0, Vector2(gob.x - 1.0, gob.z), 0.0)
		var loose: bool = gob.get("stun", 0.0) > 1.0 and gob.pins == 3 and gob.seam <= 0.0
		var harder: bool = hp0 - gob.hp > 30.0 * 1.2 # three cuts at 1.5x
		gob.stun = 0.0
		gob.seam = 0.0
		check("seam_pins", open and loose and harder, "seam opened=%s three cuts unpinned it=%s cuts hit harder=%s (%.0f)" % [open, loose, harder, hp0 - gob.hp])
	if want.call("skill_cost"):
		main.player.mp = 20.0
		main.player.cds = [0.0, 0.0, 0.0, 0.0]
		main.use_skill(0)
		var spent_none: bool = main.player.mp == 20.0
		main.player.mp = 40.0
		main.use_skill(0)
		check("skill_cost", spent_none and main.player.mp == 10.0, "whirl needs 30 momentum: at 20 nothing, at 40 left %d" % int(main.player.mp))
	if want.call("goblin_telegraph"):
		main.mate_cd = 9.0 # companions (from the lake and forest tests) would hit it and cut the wind-up short
		main.mate2_cd = 9.0
		calm_enemies(false)
		var gob = main.enemies.filter(func(e): return not e.get("boss", false) and not e.get("prop", false) and not e.dead)[0]
		calm_enemies(true)
		gob.node.visible = true
		reset_to(Vector2(30, 30))
		gob.x = 30.8
		gob.z = 30.0
		gob.hurt = 0.0
		gob.kx = 0.0
		gob.kz = 0.0
		gob.atk_cd = 0.0
		gob.wind = 0.0
		await wait(0.25)
		var during: float = main.player.hp
		var winding: bool = gob.get("wind", 0.0) > 0.0
		await wait(0.6)
		check("goblin_telegraph", winding and during == main.player.max_hp and main.player.hp < main.player.max_hp,
			"winding=%s hp during wind-up %d, after %d" % [winding, int(during), int(main.player.hp)])
		gob.x = 2.0
		gob.z = 2.0
		gob.node.visible = false
	if want.call("boss_phase2"):
		var boss = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)
		if boss.is_empty():
			check("boss_phase2", false, "no boss")
		else:
			var b0: Dictionary = boss[0]
			b0.hp = float(b0.max_hp) * 0.5 + 1.0
			reset_to(Vector2(b0.x, b0.z + 3.0))
			main.player.inv = 5.0
			main.damage_enemy(b0, 10.0, Vector2(main.player.x, main.player.z))
			await wait(0.3)
			var hp_now: float = b0.hp
			main.damage_enemy(b0, 50.0, Vector2(main.player.x, main.player.z))
			check("boss_phase2", b0.phase == 2 and b0.roar > 0.0 and b0.hp == hp_now,
				"phase=%d roaring=%s, hit during roar ignored=%s" % [b0.phase, b0.roar > 0.0, b0.hp == hp_now])
	if want.call("boss_opens_cave"):
		var boss = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)
		if boss.is_empty():
			check("boss_opens_cave", false, "no boss")
		else:
			main.close_story()
			main.story_step = 4 # an earlier test can leave the story further on, and open_cave never winds it back
			boss[0].hp = 1.0
			boss[0].roar = 0.0
			boss[0].phase = 2
			main.damage_enemy(boss[0], 50.0, Vector2(main.player.x, main.player.z))
			await wait(2.0)
			var ok: bool = main.story_step == 5 and main.story_open and main.cave_pos.x > 0
			main.close_story()
			await wait(0.6)
			var quest: String = plain(main.ui.quest.text)
			var said: bool = quest == main.CAVE_QUEST and not quest.contains("다음 장에서 계속")
			var mark: bool = main.quarters_mark != null and main.quarters_mark.visible and Vector2(main.step_target().x, main.step_target().z).distance_to(main.cave_pos) < 1.0
			# an old save still holding the demo's text loads with the new line
			main.save_game()
			var sv = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
			var old_ok := false
			if sv != null:
				sv["quest"] = "땅 아래로 가는 동굴이 열렸다 (다음 장에서 계속)"
				var fw := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
				fw.store_string(JSON.stringify(sv))
				fw.close()
				main.load_game()
				old_ok = plain(main.ui.quest.text) == main.CAVE_QUEST
			check("boss_opens_cave", ok and said and mark and old_ok, "boss down -> story step %d, cave at %s, quest=%s mark over the cave=%s old save -> new line=%s" % [main.story_step, main.cave_pos, quest, mark, old_ok])

	if want.call("save_load"):
		main.player.lv = 4
		main.player.xp = 33
		main.player.gold = 77
		main.story_step = 3
		main.save_game()
		main.player.lv = 1
		main.player.xp = 0
		main.player.gold = 0
		main.story_step = 0
		main.load_game()
		check("save_load", main.player.lv == 4 and main.player.xp == 33 and main.player.gold == 77 and main.story_step == 3,
			"after reload: lv %d xp %d gold %d story %d" % [main.player.lv, main.player.xp, main.player.gold, main.story_step])
	if want.call("story_kept"):
		# loading a save with the Brick King down rebuilt the cave mouth and wound the story back to step 5
		var st0: int = main.story_step
		var fq0: int = main.forest_q
		var nq0: int = main.night_q
		var cave0: Vector2 = main.cave_pos
		main.story_step = 10
		main.open_cave(Vector2(16, 3), false)
		main.cave_pos = cave0
		var kept: bool = main.story_step == 10
		main.story_step = 5
		main.night_q = 4
		main.forest_q = 3
		main.repair_story_step({})
		var repaired: bool = main.story_step == 10
		var tk0: Array = main.tokens.duplicate()
		main.tokens[3] = true # the squirrels token, or the line names the cages (v0.1.62)
		main.hollow_q = 3 # and the south valley (v0.1.68)
		var road: String = main.main_road_quest()
		main.hollow_q = 0
		main.tokens = tk0
		main.story_step = st0
		main.forest_q = fq0
		main.night_q = nq0
		check("story_kept", kept and repaired and road.begins_with("숲 동쪽 끝 길로"), "cave mouth keeps step 10=%s a wound-back save comes back to 10=%s quest=%s" % [kept, repaired, road])
	if want.call("cave_enter"):
		main.story_step = 5
		if main.cave_pos.x < 0:
			main.cave_pos = Vector2(16, 3)
		reset_to(main.cave_pos + Vector2(0, 0.5))
		await wait(1.2)
		check("cave_enter", main.in_cave and main.story_step == 6 and main.walkable(main.player.x, main.player.z),
			"stepping on the cave mouth: in cave=%s step=%d at %.1f,%.1f" % [main.in_cave, main.story_step, main.player.x, main.player.z])
	if want.call("cave_layout"):
		var ok: bool = main.cave_marks.size() == 12 and not main.walkable(main.cave_marks.D.x, main.cave_marks.D.y) and main.walkable(main.cave_marks.K.x, main.cave_marks.K.y)
		# the locked door must be the only way to the mole's hall (a playtest found a way round it)
		var seen: Dictionary = {}
		var todo: Array = [Vector2i(int(main.cave_marks.S.x), int(main.cave_marks.S.y))]
		while not todo.is_empty():
			var at: Vector2i = todo.pop_back()
			if seen.has(at) or main.cave_char(at.x, at.y) in ["#", "D", "w"]:
				continue
			seen[at] = true
			for dv: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				todo.append(at + dv)
		var mole_at := Vector2i(int(main.cave_marks.B.x), int(main.cave_marks.B.y))
		ok = ok and seen.has(Vector2i(int(main.cave_marks.K.x), int(main.cave_marks.K.y))) and not seen.has(mole_at)
		check("cave_layout", ok, "marks %s, locked door blocks, key spot open" % [main.cave_marks.keys()])
	if want.call("archer_telegraph"):
		var ar = main.enemies.filter(func(e): return e.get("archer", false) and not e.dead)
		if ar.is_empty():
			check("archer_telegraph", false, "no archers in the cave")
		else:
			var a0: Dictionary = ar[0]
			reset_to(Vector2(a0.x - 4.5, a0.z))
			a0.atk_cd = 0.0
			a0.wind = 0.0
			await wait(0.3)
			var winding: bool = a0.get("wind", 0.0) > 0.0
			var hp0: float = main.player.hp
			await wait(2.0)
			check("archer_telegraph", winding and main.player.hp < hp0, "winds up=%s, brick hit for %d" % [winding, int(hp0 - main.player.hp)])
	if want.call("key_door"):
		reset_to(main.cave_marks.D + Vector2(-1.0, 0))
		tap(KEY_SPACE)
		await wait(0.2)
		var locked: bool = not main.cave_door_open
		reset_to(main.cave_marks.K)
		tap(KEY_SPACE)
		await wait(0.2)
		reset_to(main.cave_marks.D + Vector2(-1.0, 0))
		tap(KEY_SPACE)
		await wait(0.2)
		check("key_door", locked and main.has_key and main.cave_door_open and main.walkable(main.cave_marks.D.x, main.cave_marks.D.y),
			"locked first=%s key=%s open=%s" % [locked, main.has_key, main.cave_door_open])
	if want.call("rival_scene"):
		reset_to(main.cave_marks.P + Vector2(0, 0.5))
		await wait(0.3)
		var shown: bool = main.story_open
		main.close_story()
		await wait(0.6)
		check("rival_scene", shown and main.saw_painting, "painting scene with the rival shows once=%s" % shown)
		# seen only after Noeul came for the lamps: the painting without his first meeting
		var nq0: int = main.night_q
		main.saw_painting = false
		main.night_q = 1
		reset_to(main.cave_marks.P + Vector2(0, 0.5))
		await wait(0.3)
		var late_open: bool = main.story_open
		var no_intro: bool = not "내 이름은 노을" in "
".join(main.story_lines) and main.ui.story_img.texture != null and main.ui.story_img.texture.resource_path.ends_with("06_cave_mural.jpg") # the mural alone (v0.0.92)
		main.close_story()
		main.night_q = nq0
		await wait(0.3)
		check("painting_late", late_open and no_intro and main.saw_painting, "late painting shown=%s no first meeting=%s" % [late_open, no_intro])
	if want.call("cave_save_load"):
		main.in_cave = true
		reset_to(main.cave_marks.S + Vector2(3, 0))
		main.save_game()
		main.in_cave = false
		main.player.x = 15.0
		main.load_game()
		await wait(0.3)
		check("cave_save_load", main.in_cave and main.player.x > 100.0 and main.hero.visible and main.cave_door_open,
			"reloaded underground: in cave=%s x=%.1f sora visible=%s door stays open=%s" % [main.in_cave, main.player.x, main.hero.visible, main.cave_door_open])
	if want.call("painting_once"):
		# saved OUTSIDE the cave after the painting scene, the key and the door: a reload keeps all three, and going
		# down again does not replay the first meeting with Noeul (the user found it replaying, 2026-10-24)
		main.in_cave = false
		main.saw_painting = true
		main.has_key = true
		main.cave_door_open = true
		main.save_game()
		main.saw_painting = false
		main.has_key = false
		main.cave_door_open = false
		main.load_game()
		await wait(0.3)
		var kept: bool = main.saw_painting and main.has_key and main.cave_door_open
		main.close_story()
		main.in_cave = true
		reset_to(main.cave_marks.P)
		await wait(0.4)
		var no_scene: bool = not main.story_open
		main.close_story()
		check("painting_once", kept and no_scene, "saved outside: painting/key/door kept=%s no painting scene at the wall=%s" % [kept, no_scene])
	if want.call("unstick"):
		main.in_cave = true
		main.player.x = main.cave_marks.S.x - 1.4 # inside the wall left of the start
		main.player.z = main.cave_marks.S.y + 2.0
		await wait(0.3)
		var x0: float = main.player.x
		hold_world(Vector2(1, 0))
		await wait(0.6)
		release()
		check("unstick", main.player_can(main.player.x, main.player.z) and main.player.x > x0, "freed from the wall and walking: x %.1f -> %.1f" % [x0, main.player.x])
	if want.call("mole_charge"):
		var mo = main.enemies.filter(func(e): return e.get("mole", false) and not e.dead)
		if mo.is_empty():
			check("mole_charge", false, "no mole in the cave")
		else:
			var m0: Dictionary = mo[0]
			m0.x = main.cave_marks.B.x
			m0.z = main.cave_marks.B.y
			main.player.max_hp = 200
			reset_to(main.cave_marks.B - Vector2(3.0, 0))
			main.player.hp = 200.0
			m0.atk_cd = 0.0
			m0.next = "charge"
			m0.dash = 0.0
			m0.stun = 0.0
			m0.wind = 0.0
			calm_enemies(true)
			hold_mates() # late in a full run a companion's blow broke the wind-up (combat.gd), so the charge never came
			var winding: bool = await wait_for(func(): return m0.wind > 0.0, 2.0)
			var hp_wind: float = main.player.hp
			await wait_for(func(): return main.player.hp < 200.0, 4.0) # the charge, however slow the game clock runs late in a full run
			check("mole_charge", winding and hp_wind == 200.0 and main.player.hp < 200.0,
				"winds up=%s, no damage during wind-up=%s, charge hit for %d (mole %.1f,%.1f wind %.2f dash %.2f stun %.2f next %s; Sora %.1f,%.1f; B %s; time_scale %.2f)" % [winding, hp_wind == 200.0, int(200.0 - main.player.hp), m0.x, m0.z, m0.wind, m0.dash, m0.stun, m0.next, main.player.x, main.player.z, main.cave_marks.B, Engine.time_scale])
	if want.call("key_unstick"):
		# a key held when focus leaves counts as let go, as its key-up may never come; it counts again from its next press; a key-up with another keycode still lets go
		var press := func(down: bool, code := KEY_W) -> void:
			var e := InputEventKey.new()
			e.keycode = code
			e.physical_keycode = KEY_W
			e.pressed = down
			Input.parse_input_event(e)
			Input.flush_buffered_events()
		var keep_lost: bool = main.keys_lost
		press.call(true)
		var held: bool = main.key_down(KEY_W)
		main._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		var let_go: bool = not main.key_down(KEY_W)
		press.call(true)
		var again: bool = main.key_down(KEY_W)
		press.call(false, KEY_P)
		var up: bool = not main.key_down(KEY_W)
		press.call(true)
		var after: bool = main.key_down(KEY_W)
		press.call(false)
		main.keys_lost = keep_lost
		check("key_unstick", held and let_go and again and up and after, "held %s, a focus loss lets go %s, pressed again %s, a key-up with another keycode lets go %s, the next press counts %s" % [held, let_go, again, up, after])
	if want.call("mole_grants_skip"):
		var mo = main.enemies.filter(func(e): return e.get("mole", false) and not e.dead)
		if not mo.is_empty():
			mo[0].hp = 1.0
			mo[0].stun = 0.0
			main.damage_enemy(mo[0], 50.0, Vector2(main.player.x, main.player.z))
		await wait(1.6)
		var shown: bool = main.story_open
		main.close_story()
		await wait(0.6)
		check("mole_grants_skip", main.has_skip and shown, "mole down -> water skip=%s, scene shown=%s" % [main.has_skip, shown])
	if want.call("cave_faint"):
		main.in_cave = true
		reset_to(main.cave_marks.B - Vector2(3, 0))
		main.faint()
		await wait(0.3)
		check("cave_faint", not main.in_cave and main.ui.zone_name.text == "갈대늪" and main.player.x < 100.0,
			"fainting underground wakes outside with outside state: in cave=%s zone=%s" % [main.in_cave, main.ui.zone_name.text])
	if want.call("cave_exit"):
		main.has_skip = true
		main.cave_exit_seen = false
		main.in_cave = true
		# the first way out waits for the cave's errands and says which are left
		var keep_saw: bool = main.saw_painting
		var keep_up: Array = main.woke.duplicate()
		main.saw_painting = true
		main.woke = [false, false, false]
		main.toast_t = 0.0
		reset_to(main.cave_marks.E + Vector2(-0.5, 0))
		await wait(0.8)
		var held: bool = main.in_cave and main.ui.toast.text.contains("회오리")
		main.woke = [true, keep_up[1], keep_up[2]]
		var talk := false
		for k in 12: # the fade out, then the way-out story (close whatever opens on the way)
			await wait(0.3)
			if main.story_open:
				talk = talk or main.ui.story_text.text.contains("밤")
				main.close_story()
		await wait(0.3)
		# outside, the stone stair stays beside her and leads back down
		var stair: bool = main.cave.exit_built and not main.in_cave
		main.woke = keep_up
		main.saw_painting = keep_saw
		check("cave_exit", held and talk and not main.in_cave and main.story_step == 7 and stair, "held inside with a skill left=%s exit -> outside=%s step=%d stair kept=%s" % [held, not main.in_cave, main.story_step, stair])
	if want.call("water_skip"):
		main.in_cave = false
		main.has_skip = true
		reset_to(Vector2(19.0, 15.0)) # west bank of the river
		main.player.sp = 100.0
		main.fake_keys[KEY_SHIFT] = true
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait_for(func(): return main.player.x > 27.0, 3.0) # was a fixed 1.6 s, short by 0.2 tiles on a slow frame
		release()
		await wait(0.2)
		check("water_skip", main.player.x > 27.0, "with Shift held Sora runs across the river: x 19.0 -> %.1f" % main.player.x)
	if want.call("water_skip_letgo"):
		main.has_skip = true
		reset_to(Vector2(19.0, 15.0))
		main.player.sp = 15.0 # nearly out of stamina
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait(0.5)
		main.fake_keys.erase(KEY_SHIFT) # lets go of Shift for a moment mid-river
		await wait(0.3)
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.2)
		release()
		await wait(0.2)
		check("water_skip_letgo", main.player.x > 27.0, "low stamina and a short Shift let-go still cross: x 19.0 -> %.1f" % main.player.x)
	# ---- village (story step 8)
	if want.call("village_enter"):
		main.in_cave = false
		main.in_village = false
		main.story_step = 7
		main.errand = 0
		main.has_skip = true
		reset_to(Vector2(43.0, 20.0)) # east shore, then skip over the edge water with Shift
		main.player.sp = 100.0
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.6)
		release()
		await wait(0.6)
		var talk: bool = main.story_open
		main.close_story()
		await wait(0.6)
		check("village_enter", main.in_village and main.story_step == 8 and talk, "east edge -> village=%s step=%d arrival talk=%s" % [main.in_village, main.story_step, talk])
	if want.call("village_layout"):
		var lamps: int = main.village_lamps().size()
		var want_lamps := 0
		for row: String in main.village.grid:
			want_lamps += row.count("L") + row.count("d")
		want_lamps += 1 # the square's lantern beside the fountain (v0.1.76)
		check("village_layout", lamps == want_lamps and main.village.dark.size() == 3 and main.walkable(main.village.marks.M.x - 1.5, main.village.marks.M.y),
			"%d lanterns (%d), 3 dark (%d), square walkable" % [want_lamps, lamps, main.village.dark.size()])
	if want.call("simji_talk"):
		main.in_village = true
		main.errand = 0
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
		tap(KEY_E)
		await wait(0.3)
		var talk: bool = main.story_open
		main.close_story()
		await wait(0.6)
		check("simji_talk", talk and main.errand == 1 and plain(main.ui.quest.text).contains("0/3"), "talk=%s errand=%d quest=%s" % [talk, main.errand, plain(main.ui.quest.text)])
	if want.call("lamp_cost_night"):
		main.hour = 23.0
		main.crown_pips = 7
		var d0: Dictionary = main.village.dark[0]
		var no_moth := func(): return main.enemies.filter(func(e): return not e.get("moth", false)).size() # the night moths come and go
		var n0: int = no_moth.call()
		reset_to(d0.pos + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(1.3)
		check("lamp_cost_night", d0.lit and main.crown_pips == 6 and no_moth.call() == n0 + 1, "lit=%s pips 7->%d goblin woke=%s" % [d0.lit, main.crown_pips, no_moth.call() == n0 + 1])
	if want.call("lamp_cost_day"):
		main.hour = 13.0
		main.crown_pips = 6
		var d1: Dictionary = main.village.dark[1]
		reset_to(d1.pos + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		check("lamp_cost_day", d1.lit and main.crown_pips == 4, "by day a lantern costs 2: pips 6->%d" % main.crown_pips)
	if want.call("lamp_no_pips"):
		main.crown_pips = 0
		var d2: Dictionary = main.village.dark[2]
		reset_to(d2.pos + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		check("lamp_no_pips", not d2.lit and main.crown_pips == 0, "with no pips the lantern stays dark=%s" % (not d2.lit))
	if want.call("pip_rest"):
		calm_enemies(true)
		for e in main.enemies:
			if e.get("cave", false) and not e.get("mole", false):
				e.x = 2.0
				e.z = 2.0
		main.hour = 23.0
		main.crown_pips = 0
		for e in main.enemies.filter(func(e): return e.get("moth", false)): # night moths fly back over the parked corner and break the rest
			e.dead = true
			e.hp = 0.0
			e.respawn = 9999.0 # and came back at 23:00 within the 15 s (full runs: "M" from the fourth second)
		var lit_lamp = main.lanterns.filter(func(l): return l.position.x > 130.0 and not l.get_meta("dark", false))[0]
		reset_to(Vector2(lit_lamp.position.x + 0.4, lit_lamp.position.z + 1.0))
		var trace := [] # each second: pips, rest timer, speed, and "M" when a monster near stopped the rest
		for k in 15:
			await wait(1.0)
			for e in main.enemies: # anything that wandered in meanwhile is sent off, so the rate is what is measured
				if not e.dead and not e.get("boss", false) and Vector2(e.x - main.player.x, e.z - main.player.z).length() < 7.0:
					trace.append("sent off %s" % e.get("kind", "foe"))
					e.dead = true
					e.hp = 0.0
					e.respawn = 9999.0
					if is_instance_valid(e.node):
						e.node.visible = false
			trace.append("%d/%.1f/%.1f%s" % [main.crown_pips, main.rest_t, Vector2(main.player.vx, main.player.vz).length(), "M" if main.rest_said else ""])
		check("pip_rest", main.crown_pips >= 4, "15 s resting by a lit lantern at night (3 s a pip): pips 0->%d [%s]" % [main.crown_pips, " ".join(trace)])
	if want.call("errand_done"):
		main.crown_pips = 3
		main.hour = 23.0
		var d2: Dictionary = main.village.dark[2]
		reset_to(d2.pos + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		var g0: int = main.player.gold
		var p0: int = main.player.pots
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		await wait(0.6)
		check("errand_done", main.errand == 3 and main.crown_pips == 8 and main.player.gold == g0 + 60 and main.player.pots == p0 + 1,
			"errand=%d pips=%d gold +%d pots +%d" % [main.errand, main.crown_pips, main.player.gold - g0, main.player.pots - p0])
	if want.call("kongal_errand"):
		main.errand = 3
		main.kid_q = 0
		var kp: Vector2 = main.village.folk_pos.kongal
		reset_to(kp + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		var guards: Array = main.enemies.filter(func(e): return not e.dead and e.x > 130.0)
		var asked: bool = main.kid_q == 1 and guards.size() >= 3
		var kid: Vector3 = main.kid_node.position
		reset_to(Vector2(kid.x + 0.6, kid.z))
		main.player.inv = 5.0
		await wait(0.3)
		var held: bool = main.kid_q == 1 # guards still up: the kid stays
		for e in guards:
			e.dead = true
			e.node.visible = false
		await wait(0.3)
		var freed: bool = main.kid_q == 2
		reset_to(kp + Vector2(1.0, 0))
		await wait(2.5) # the kid trots after her at 5 m/s
		var follows: bool = main.kid_node.position.distance_to(Vector3(main.player.x, 0, main.player.z)) < 1.6
		var g0: int = main.player.gold
		var p0: int = main.player.pots
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		check("kongal_errand", asked and held and freed and follows and main.kid_q == 3 and main.player.gold == g0 + 40 and main.player.pots == p0 + 1,
			"asked=%s guards=%d held=%s freed=%s follows=%s kid_q=%d gold +%d pots +%d" % [asked, guards.size(), held, freed, follows, main.kid_q, main.player.gold - g0, main.player.pots - p0])
	if want.call("doran_errand"):
		main.kid_q = 3
		main.doran_q = 0
		main.hour = 23.0
		main.crown_pips = 8
		var dp: Vector2 = main.village.folk_pos.doran
		reset_to(dp + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		var asked: bool = main.doran_q == 1
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		var read: bool = main.doran_q == 2 and main.crown_pips == 7
		main.in_village = false
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		var hp0: int = main.player.max_hp
		main.crown_pips = 2
		tap(KEY_SPACE)
		await wait(0.3)
		var no_shop: bool = not main.shop_open
		main.close_story()
		# v0.0.47: the letter wakes a ninth pip in place of max HP +10, and fills the gauge
		check("doran_errand", asked and read and no_shop and main.doran_q == 3 and main.pip_max == 9 and main.crown_pips == 9 and main.player.max_hp == hp0,
			"asked=%s read=%s delivered(no shop)=%s doran_q=%d pips=%d/%d max_hp +%d" % [asked, read, no_shop, main.doran_q, main.crown_pips, main.pip_max, main.player.max_hp - hp0])
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
	if want.call("mulgyeol_errand"):
		main.doran_q = 3
		main.mul_q = 0
		var mp: Vector2 = main.village.folk_pos.mulgyeol
		reset_to(mp + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		var asked: bool = main.mul_q == 1 and main.oar_node != null
		main.in_village = false
		main.has_skip = true
		reset_to(Vector2(13.6, 12.0)) # east shore of the pond: run west over the water to the oar
		main.player.inv = 5.0
		main.player.sp = 100.0
		hold_world(Vector2(-1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.0)
		release()
		await wait(0.4)
		var got: bool = main.mul_q == 2 and not main.oar_node.visible
		main.in_village = true
		reset_to(mp + Vector2(-1.0, 0))
		var g0: int = main.player.gold
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		check("mulgyeol_errand", asked and got and main.mul_q == 3 and main.player.gold == g0 + 50,
			"asked=%s got oar=%s mul_q=%d gold +%d cave=%s" % [asked, got, main.mul_q, main.player.gold - g0, main.in_cave])
		for e in main.enemies.filter(func(e): return not e.dead and e.x < 20.0 and e.z < 20.0):
			e.dead = true
			e.node.visible = false
	if want.call("lantern_night"):
		main.mul_q = 3
		main.night_q = 0
		main.hour = 22.0
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
		await wait(0.3)
		var dark: int = main.village_lamps().filter(func(l): return not l.visible).size()
		var started: bool = main.night_q == 1 and dark == main.village_lamps().size()
		main.close_story()
		await wait(0.2)
		for i in 80: # stay just behind Noeul until he turns at the end of his path
			if main.night_q != 1:
				break
			var np: Vector3 = main.noeul_node.position
			reset_to(Vector2(np.x - 1.2, np.z))
			main.player.inv = 5.0
			await wait(0.1)
		var fell: bool = main.night_q == 2
		main.close_story()
		await wait(0.3)
		var lit: int = main.village_lamps().filter(func(l): return l.visible).size()
		var rose: bool = main.night_q == 3 and lit == main.village_lamps().size()
		main.close_story()
		await wait(0.3)
		var duel: Array = main.enemies.filter(func(e): return e.get("noeul", false) and not e.dead)
		var spawned: bool = duel.size() == 1
		if spawned:
			var e: Dictionary = duel[0]
			reset_to(Vector2(e.x - 1.5, e.z))
			main.player.inv = 9.0
			await wait(0.5)
			main.damage_enemy(e, 10000.0, Vector2(main.player.x, main.player.z))
			await wait(1.4)
		main.close_story()
		check("lantern_night", started and fell and rose and spawned and main.night_q == 4 and main.has_unbrick,
			"started=%s (dark %d) fell=%s rose=%s (lit %d) duel=%s night_q=%d unbrick=%s" % [started, dark, fell, rose, lit, spawned, main.night_q, main.has_unbrick])
		main.hour = 12.0
	if want.call("folk_again"):
		main.met["doran"] = true
		main.doran_q = 3
		reset_to(main.village.folk_pos.doran + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		var said: String = plain(main.ui.story_text.text)
		main.close_story()
		check("folk_again", said.contains("배달을 마쳤"), "Doran after the letter: %s" % said.left(30))
	if want.call("lake"):
		main.night_q = 4
		main.lake_q = 0
		main.hour = 22.0
		reset_to(main.village.marks.K + Vector2(0, -0.3))
		await wait(1.5)
		var entered: bool = main.in_lake and main.lake_q == 1
		main.close_story()
		main.crown_pips = 8
		reset_to(main.lake.marks.D + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		var thawed: bool = main.lake_q == 2 and main.lake.thawed and main.crown_pips == 6
		main.close_story()
		reset_to(Vector2(main.lake_npc.position.x - 1.0, main.lake_npc.position.z))
		tap(KEY_E)
		await wait(1.5)
		var rowed: bool = main.lake_q == 3 and main.mate != null and main.player.z > 13.0
		main.close_story()
		await wait(0.3)
		var turtle: Array = main.enemies.filter(func(e): return e.get("turtle", false) and not e.dead)
		if turtle.size() == 1:
			main.player.inv = 9.0
			main.damage_enemy(turtle[0], 10000.0, Vector2(main.player.x, main.player.z))
			await wait(1.4)
		var joined: bool = main.lake_q == 4
		main.close_story()
		reset_to(main.lake.marks.Q + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(1.5)
		var back: bool = main.player.z < 5.0
		check("lake", entered and thawed and rowed and turtle.size() == 1 and joined and back,
			"entered=%s thawed=%s rowed=%s turtle=%d joined=%s rowed back=%s" % [entered, thawed, rowed, turtle.size(), joined, back])
		reset_to(main.lake.marks.S + Vector2(0, 0.3))
		await wait(1.5)
	if want.call("forest"):
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 0
		main.tokens[2] = true # the road to the forest asks for the pearl token (v0.1.62)
		main.south_q = 4 # and the lower pond's water clock (v0.1.68)
		main.corridor_q = 6 # and the water corridor (v0.1.84)
		main.hour = 22.0
		reset_to(main.village.marks.F + Vector2(-0.3, 0))
		await wait(1.5)
		var entered: bool = main.in_forest and main.forest_q == 1
		main.south_q = 0 # the pond deed was only for the gate
		main.close_story()
		await wait(0.2)
		var w0: Dictionary = main.forest.walls[0]
		var shut: bool = not main.walkable(w0.pos.x, w0.pos.y)
		var edges: bool = w0.glow.visible and w0.glow.get_child_count() >= 4
		main.crown_pips = 8
		reset_to(w0.pos + Vector2(-1.0, 0))
		main.player.inv = 9.0
		tap(KEY_E)
		await wait(0.2)
		var opened: bool = w0.open and main.walkable(w0.pos.x, w0.pos.y) and main.crown_pips == 6
		var edges_gone: bool = not w0.glow.visible
		reset_to(main.forest.marks.N + Vector2(-4.0, 0))
		main.player.inv = 9.0
		await wait(0.3)
		var met: bool = main.forest_q == 2
		main.close_story()
		await wait(0.3)
		var duel: Array = main.enemies.filter(func(e): return e.get("second", false) and not e.dead)
		if duel.size() == 1:
			main.damage_enemy(duel[0], 10000.0, Vector2(main.player.x, main.player.z))
			await wait(1.4)
		main.close_story()
		check("forest", entered and shut and opened and met and duel.size() == 1 and main.forest_q == 3 and edges and edges_gone,
			"entered=%s wall shut=%s opened=%s met Noeul=%s duel=%d forest_q=%d night edges at the wall=%s gone once open=%s" % [entered, shut, opened, met, duel.size(), main.forest_q, edges, edges_gone])
		for e in main.enemies.filter(func(e): return not e.dead and e.x > 170.0):
			e.dead = true
			e.node.visible = false
		reset_to(main.forest.marks.S + Vector2(0.3, 0))
		await wait(1.5)
		main.hour = 12.0
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
	if want.call("hill"):
		main.forest_q = 3
		main.hill_q = 0
		main.tokens[3] = true # the way east out of the forest asks for the squirrels token (v0.1.62)
		main.hollow_q = 3 # and the south valley (v0.1.68)
		main.in_village = false
		main.in_forest = true
		main.hour = 22.0
		reset_to(main.forest.marks.E + Vector2(-0.3, 0))
		await wait(1.5)
		var shields: Array = main.enemies.filter(func(e): return not e.dead and e.get("shield", 0) > 0)
		var entered: bool = main.in_hill and main.hill_q == 1 and shields.size() == 3 and main.mate2 != null
		main.hollow_q = 0 # the valley deed was only for the gate
		main.close_story()
		var sg: Dictionary = shields[0] if shields.size() > 0 else {}
		var hp0: float = sg.get("hp", 0.0)
		if not sg.is_empty():
			main.damage_enemy(sg, 50.0, Vector2(sg.x - 1.0, sg.z))
		var blocked: bool = not sg.is_empty() and sg.shield == 2 and sg.hp == hp0
		main.crown_pips = 8
		for mill in main.hill.mills:
			reset_to(mill.pos + Vector2(1.3, 0))
			main.player.inv = 9.0
			tap(KEY_E)
			await wait(0.2)
		var bridged: bool = main.hill_q == 2 and main.hill.bridged and main.walkable(main.hill.HILL_X + 20, 12) and main.crown_pips == 5
		main.close_story()
		reset_to(main.hill.marks.B + Vector2(-4.5, 0))
		main.player.inv = 30.0
		await wait(0.3)
		main.close_story()
		await wait(0.3)
		var hawk: Array = main.enemies.filter(func(e): return e.get("hawk", false) and not e.dead)
		var out_of_reach := false
		if hawk.size() == 1:
			var h0: float = hawk[0].hp
			main.damage_enemy(hawk[0], 100.0, Vector2(main.player.x, main.player.z))
			out_of_reach = hawk[0].hp == h0
			hawk[0].air = false
			main.damage_enemy(hawk[0], 10000.0, Vector2(main.player.x, main.player.z))
			await wait(1.4)
		main.close_story()
		check("hill", entered and blocked and bridged and hawk.size() == 1 and out_of_reach and main.hill_q == 3,
			"entered=%s shield blocked=%s bridge=%s hawk=%d air-proof=%s hill_q=%d" % [entered, blocked, bridged, hawk.size(), out_of_reach, main.hill_q])
		for e in main.enemies.filter(func(e): return not e.dead and e.x > 300.0):
			e.dead = true
			e.node.visible = false
		reset_to(main.hill.marks.S + Vector2(0.3, 0))
		await wait(1.5)
		main.in_forest = false
		main.in_village = true
		main.hour = 12.0
	if want.call("garden_end"):
		main.forest_q = 3
		main.hill_q = 3
		main.garden_q = 0
		main.road_q = 4 # Hangyeol's yard behind her: the stairs' top leads straight to the arena
		main.in_village = false
		main.in_hill = true
		main.castle_q = 3
		main.open_stairs()
		reset_to(main.stairs.marks.N + Vector2(0, 0.3))
		await wait(1.5)
		var entered: bool = main.in_garden and main.garden_q == 1
		main.close_story()
		reset_to(main.garden.marks.C + Vector2(-6.0, 0))
		await wait(0.3)
		var asleep: bool = main.garden_q == 1 # seals still shut
		main.crown_pips = 8
		for sl in main.garden.seals:
			reset_to(sl.pos + (main.garden.marks.C - sl.pos).normalized() * -1.2)
			tap(KEY_E)
			await wait(0.1)
		var seal_quest: bool = plain(main.ui.quest.text) == main.tr("굳은달 거푸집의 심장을 노리자") # not left at 2/3
		var seals_ok: bool = asleep and main.garden.seals_open() == 3 and seal_quest
		for e in main.enemies.filter(func(e): return not e.dead and e.x > main.GARDEN.GARDEN_X and not e.get("mold", false)):
			e.dead = true
			e.node.visible = false
			e.shadow.visible = false
		reset_to(main.garden.marks.C + Vector2(-6.0, 0))
		main.player.inv = 30.0
		await wait(0.3)
		var mold: Array = main.enemies.filter(func(e): return e.get("mold", false) and not e.dead)
		var fought: bool = main.garden_q == 2 and mold.size() == 1
		if fought:
			mold[0].hp = mold[0].max_hp * 0.125 # just over the 12% lock; the blow below must carry it under (the mold has 2720 HP since v0.1.62)
			main.damage_enemy(mold[0], 30.0, Vector2(main.player.x, main.player.z))
			await wait(0.3)
		var locked: bool = main.garden_q == 3 and mold.size() == 1 and mold[0].locked and main.crown_pips == 0
		main.close_story()
		await wait(0.2)
		var shards_came: bool = main.enemies.any(func(e): return e.get("shard", false) and not e.dead)
		var snuffed := false
		if shards_came: # let one pair reach its post once: the post must start over
			var sh: Array = main.enemies.filter(func(e): return e.get("shard", false) and not e.dead)
			sh[0].x = sh[0].post.x
			sh[0].z = sh[0].post.y
			await wait(0.1)
			snuffed = main.ring_k == 0 and main.enemies.filter(func(e): return e.get("shard", false) and not e.dead).size() == 2
		for i in 80: # then cut the shards down as they come
			if main.garden_q == 4:
				break
			for e in main.enemies.filter(func(e): return e.get("shard", false) and not e.dead):
				main.damage_enemy(e, 999.0, Vector2(main.player.x, main.player.z))
			await wait(0.3)
		var ready: bool = main.garden_q == 4 and main.crown_pips == 8 and shards_came and snuffed
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		await wait(0.4)
		var ended: bool = main.story_step == 12 and main.garden_q == 5 and mold[0].dead
		main.close_story()
		check("garden_end", entered and seals_ok and fought and locked and ready and ended,
			"entered=%s seals=%s (quest to the mold=%s) fought=%s locked at 12%%=%s lights filled=%s ended=%s step=%d" % [entered, seals_ok, seal_quest, fought, locked, ready, ended, main.story_step])
		reset_to(main.garden.marks.S + Vector2(0.3, 0))
		await wait(1.5)
		main.in_hill = false
		main.in_forest = false
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
	if want.call("village_exit"):
		reset_to(main.village.marks.G + Vector2(0.6, 0))
		main.player.x = main.village.marks.G.x + 0.3
		await wait(1.2)
		check("village_exit", not main.in_village and main.player.x < 48.0, "west gate -> outside=%s x=%.1f" % [not main.in_village, main.player.x])
	if want.call("marsh_scraps"):
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_hill = false
		main.in_garden = false
		calm_enemies(true)
		var walk_ok := true
		for p in MARSH.SCRAPS + [MARSH.CHEST_AT]:
			walk_ok = walk_ok and main.player_can(p.x, p.y)
		for i in 3:
			reset_to(MARSH.SCRAPS[i])
			await wait(0.2)
			main.close_story()
		var whole: bool = main.marsh.count() == 3 and main.marsh.chest.visible
		var atk0: int = main.player.atk
		var hp0: int = main.player.max_hp
		reset_to(MARSH.CHEST_AT + Vector2(0.8, 0))
		tap(KEY_SPACE)
		await wait(0.2)
		main.close_story()
		var opened: bool = main.marsh.chest_open and main.player.atk == atk0 + 4 and main.player.max_hp == hp0 + 20
		main.save_game()
		main.marsh.found = [false, false, false]
		main.marsh.chest_open = false
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		main.marsh.restore(sd.get("scraps", []), bool(sd.get("moon_chest", false)))
		var kept: bool = main.marsh.count() == 3 and main.marsh.chest_open and not main.marsh.nodes[0].visible
		calm_enemies(false)
		check("marsh_scraps", walk_ok and whole and opened and kept, "spots walkable=%s whole map=%s opened=%s (atk +%d) kept after load=%s" % [walk_ok, whole, opened, main.player.atk - atk0, kept])
	if want.call("forest_grove"):
		main.in_village = false
		main.in_lake = false
		main.in_hill = false
		main.in_garden = false
		main.in_forest = true
		calm_enemies(true)
		var fx0: int = main.FOREST.FOREST_X
		var shut: bool = not main.player_can(main.forest.marks.V.x, main.forest.marks.V.y)
		reset_to(Vector2(fx0 + 2, 5)) # by the tablet
		await wait(0.6)
		var faded: bool = main.forest.fade_groups[0].a < 0.5
		tap(KEY_E)
		await wait(0.2)
		var read: bool = main.story_open
		main.close_story()
		for k in 4:
			var st: Dictionary = main.forest.stones[k]
			reset_to(st.pos + Vector2(-1.0 if k == 0 else 0.0, 0.0 if k == 0 else 1.0))
			for n in (3 - k - st.phase + 8) % 4:
				tap(KEY_E)
				await wait(0.15)
		await wait(0.2)
		main.close_story()
		var solved: bool = main.forest.solved and main.player_can(main.forest.marks.V.x, main.forest.marks.V.y)
		var hp0: int = main.player.max_hp
		reset_to(main.forest.marks.c + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var opened: bool = main.forest.chest_open and main.player.max_hp == hp0 + 15
		reset_to(Vector2(fx0 + 15, 4)) # out of the grove the crowns come back
		await wait(0.8)
		var back: bool = main.forest.fade_groups[0].a >= 1.0
		main.in_forest = false
		calm_enemies(false)
		check("forest_grove", shut and read and solved and opened and faded and back, "wall shut=%s tablet read=%s solved=%s phases=%s chest=%s south crowns faded by the tablet=%s back outside=%s" % [shut, read, solved, main.forest.stones.map(func(s): return s.phase), opened, faded, back])
	if want.call("firefly_errand"):
		main.errand = 3
		main.kid_q = 3
		main.doran_q = 3
		main.fly_q = 0
		main.tokens[0] = false # the jar is lent again in this test: the firefly token comes with it (v0.1.62)
		main.met["kongal"] = true
		main.in_village = true
		main.in_forest = false
		calm_enemies(true)
		var kp: Vector2 = main.village.folk_pos.kongal
		reset_to(kp + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		var asked: bool = main.fly_q == 1
		main.in_village = false
		main.hour = 13.0
		await wait(0.2)
		var hidden_by_day: bool = not main.marsh.flies[0].node.visible
		main.hour = 22.0
		await wait(0.2)
		var walk_ok := true
		for f in main.marsh.flies:
			walk_ok = walk_ok and main.player_can(f.home.x, f.home.y)
		for i in 5:
			var n: Node3D = main.marsh.flies[i].node
			reset_to(Vector2(n.position.x, n.position.z))
			await wait(0.15)
		var full: bool = main.fly_q == 2
		main.in_village = true
		var g0: int = main.player.gold
		reset_to(kp + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.3)
		main.close_story()
		var lent: bool = main.fly_q == 3 and main.jar_node != null and main.player.gold == g0 + 30 and main.tokens[0]
		main.in_village = false
		calm_enemies(false)
		check("firefly_errand", asked and hidden_by_day and walk_ok and full and lent, "asked=%s hidden by day=%s spots walkable=%s caught=%d lent jar=%s" % [asked, hidden_by_day, walk_ok, main.marsh.caught(), lent])
	if want.call("grotto"):
		main.tokens[2] = false # the pearl comes with its token (v0.1.62)
		main.in_village = false
		main.in_forest = false
		main.in_hill = false
		main.in_garden = false
		main.in_lake = true
		main.lake_q = 4
		main.grotto_q = 0
		main.story_step = maxi(main.story_step, 10)
		main.has_skip = true
		var gx: float = main.GROTTO.GROTTO_X
		reset_to(main.lake.marks.G + Vector2(0, -0.3))
		await wait(1.0)
		var entered: bool = main.in_grotto() and main.grotto_q == 1
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		reset_to(Vector2(gx + 7.6, 4))
		hold_world(Vector2(1, 0))
		await wait(1.0)
		release()
		var no_skip: bool = main.player.x < gx + 9.0
		reset_to(Vector2(gx + 7.6, 4))
		main.player.sp = 100.0
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.0)
		release()
		var crossed: bool = main.player.x > gx + 12.0
		reset_to(Vector2(gx + 16, 9.5))
		main.player.sp = 100.0
		hold_world(Vector2(0, 1))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.0)
		release()
		await wait(0.2)
		var met_crab: bool = main.grotto_q == 2
		main.close_story()
		await wait(0.2)
		var crabs: Array = main.enemies.filter(func(e): return e.get("crab", false) and not e.dead)
		var spat := false
		if crabs.size() == 1:
			var c: Dictionary = crabs[0]
			park_mates(true) # late in a full run a companion stood in the bricks' way and caught them
			main.player.inv = 99.0
			for i in 40:
				reset_to(Vector2(c.x + 6.0, c.z)) # keep backing off: from afar the crab spits
				main.player.inv = 99.0
				await wait(0.1)
				if main.enemy_shots.size() >= 3:
					spat = true
					break
			park_mates(false)
			main.player.inv = 0.0
			c.hp = 1.0
			main.damage_enemy(c, 50.0, Vector2(c.x, c.z - 1.0))
		await wait(1.3)
		main.close_story()
		var beaten: bool = main.grotto_q == 3 and main.grotto.chest.visible
		reset_to(main.grotto.marks.c + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var pearl: bool = main.has_pearl and main.grotto_q == 4 and main.tokens[2]
		var g0: int = main.player.gold
		reset_to(main.grotto.marks.p + Vector2(0, 1.0))
		tap(KEY_SPACE)
		await wait(0.2)
		var side: bool = main.grotto_side and main.player.gold == g0 + 60
		main.in_lake = false
		calm_enemies(false)
		check("grotto", entered and no_skip and crossed and met_crab and spat and beaten and pearl and side,
			"entered=%s walk stops at water=%s skip crossed=%s crab woke=%s spat bricks=%s beaten=%s pearl=%s side chest=%s" % [entered, no_skip, crossed, met_crab, spat, beaten, pearl, side])
	if want.call("cloud"):
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_hill = true
		main.hill_q = 3
		main.cloud_q = 0
		main.story_step = maxi(main.story_step, 10)
		var cx: float = main.CLOUD.CLOUD_X
		reset_to(main.hill.marks.U + Vector2(0, 0.3))
		await wait(1.0)
		var entered: bool = main.in_cloud() and main.cloud_q == 1
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		var hops := []
		for leg in [[Vector2(cx + 3.6, 10), Vector2(1, 0)], [Vector2(cx + 12, 8.4), Vector2(0, -1)]]:
			reset_to(leg[0])
			hold_world(leg[1])
			await wait(1.4)
			release()
			await wait(0.1)
			hops.append(Vector2(main.player.x - cx, main.player.z))
		var flew: bool = hops[0].x > 10.2 and hops[0].x < 13.0 and hops[1].y < 3.5 and hops[1].y > 0.5 and main.gust_dir == Vector2.ZERO
		reset_to(main.cloud.marks.c + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		var chest: bool = main.cloud_chest
		reset_to(Vector2(cx + 13.6, 10))
		hold_world(Vector2(1, 0))
		await wait(1.4)
		release()
		await wait(0.2)
		var woke: bool = main.cloud_q == 2 and main.player.x > cx + 20.0
		main.close_story()
		await wait(0.2)
		var foes: Array = main.enemies.filter(func(e): return e.get("scare", false) and not e.dead)
		var flung := false
		if foes.size() == 1:
			var k: Dictionary = foes[0]
			for i in 40:
				reset_to(Vector2(cx + 20.5, 14.0)) # stay off to the side: from afar it flings bricks four ways
				main.player.inv = 99.0
				await wait(0.1)
				if main.enemy_shots.size() >= 4:
					flung = true
					break
			main.player.inv = 0.0
			k.hp = 1.0
			main.damage_enemy(k, 50.0, Vector2(k.x, k.z - 1.0))
		await wait(1.3)
		main.close_story()
		main.player.sp = 100.0
		main.player.dodge = 0.0
		tap(KEY_K)
		await wait(0.05)
		var cheap_roll: bool = main.has_feather and main.player.sp > 80.0
		main.in_hill = false
		calm_enemies(false)
		check("cloud", entered and flew and chest and woke and flung and cheap_roll,
			"entered=%s hops=%s chest=%s scarecrow woke=%s flung bricks=%s feather roll=%s (sp %.0f)" % [entered, hops, chest, woke, flung, cheap_roll, main.player.sp])
	if want.call("castle"):
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_hill = true
		main.hill_q = 3
		main.castle_q = 0
		main.tokens[4] = true # the way to the castle asks for the hill deed (v0.1.62)
		main.mill_q = 5 # both the mill and the trial since v0.1.68
		main.trial_won = true
		main.observatory_q = 6 # and the observatory since v0.1.120
		main.work_q = 5 # and the moon door opens only after the deep workshop (v0.1.68)
		main.work_seen = true # the workshop door's first look (a story box within 6 tiles of it) would stop the vent crossing
		main.has_unbrick = true
		main.has_skip = true
		main.crown_pips = 8
		main.hour = 22.0
		main.story_step = maxi(main.story_step, 10)
		var cx: float = main.CASTLE.CASTLE_X
		main.castle.gate_open = false # an earlier test may have walked out of the garden, which opens the way west
		for n in main.castle.gate_nodes:
			n.visible = true
		main.castle.door_open = false
		main.castle.door.visible = true
		for pg in main.castle.pages:
			pg.read = false
		reset_to(main.hill.marks.X + Vector2(-0.3, 0))
		await wait(1.0)
		var entered: bool = main.in_castle() and main.castle_q == 1
		main.mill_q = 0 # the mill and the trial were only for the gate
		main.trial_won = false
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		var shut: bool = not main.player_can(cx + 9, 13)
		reset_to(Vector2(cx + 7.8, 13.5))
		tap(KEY_E)
		await wait(0.2)
		var gate: bool = main.castle.gate_open and main.player_can(cx + 9, 13)
		reset_to(Vector2(cx + 11.6, 13.5))
		main.player.sp = 100.0
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		for i in 20: # up to 2 s: a slow frame rate under load must not fail the run across the river
			await wait(0.1)
			if main.player.x > cx + 16.0:
				break
		release()
		var skipped: bool = main.player.x > cx + 16.0
		reset_to(Vector2(cx + 21.6, 13))
		hold_world(Vector2(1, 0))
		await wait(1.4)
		release()
		await wait(0.1)
		var vented: bool = main.player.x > cx + 27.0 and main.gust_dir == Vector2.ZERO
		var shut_door: bool = not main.player_can(cx + 31, 13)
		for pg in main.castle.pages:
			reset_to(pg.pos + Vector2(1.0, 0))
			tap(KEY_E)
			await wait(0.2)
			main.close_story()
			await wait(0.1)
		var door: bool = main.castle.pages_read() == 3 and main.castle.door_open and main.player_can(cx + 31, 13)
		main.work_q = 0 # set only to let the moon door open (v0.1.68); a later test hands the lantern to Simji at work_q 5
		reset_to(main.castle.marks.K + Vector2(-4.0, 0))
		await wait(0.3)
		var woke: bool = main.castle_q == 2
		main.close_story()
		await wait(0.2)
		var ks: Array = main.enemies.filter(func(e): return e.get("knight", false) and not e.dead)
		var shield := false
		var flank := false
		var guard_opens := false
		if ks.size() == 1:
			var k: Dictionary = ks[0]
			k.atk_cd = 99.0
			var front: Vector2 = Vector2(k.x, k.z) + k.face * 1.5
			var hp0: float = k.hp
			main.damage_enemy(k, 40.0, front)
			shield = k.hp == hp0
			main.damage_enemy(k, 40.0, Vector2(k.x, k.z) - k.face * 1.5)
			flank = k.hp < hp0
			reset_to(front)
			main.player.face = -k.face
			main.guarding = true
			main.guard_since = main.t
			var res: String = main.player_hit(10, Vector2(k.x, k.z), k)
			main.guarding = false
			var hp1: float = k.hp
			main.damage_enemy(k, 40.0, front)
			guard_opens = res == "flash_guard" and k.hp < hp1
			k.hp = 1.0
			k.stun = 1.0
			main.damage_enemy(k, 40.0, front)
		await wait(1.3)
		main.close_story()
		var beaten: bool = main.castle_q == 3
		reset_to(main.castle.marks.E + Vector2(-0.3, 0))
		await wait(1.5)
		var to_garden: bool = main.in_stairs()
		main.close_story()
		main.open_stairs()
		reset_to(main.stairs.marks.S + Vector2(0, -0.3))
		await wait(1.5)
		var back: bool = main.in_castle()
		main.in_hill = false
		calm_enemies(false)
		check("castle", entered and shut and gate and skipped and vented and shut_door and door and woke and shield and flank and guard_opens and beaten and to_garden and back,
			"entered=%s gate shut/open=%s/%s skip=%s vent=%s door shut=%s pages open door=%s knight woke=%s front blocked=%s flank hits=%s flash guard opens=%s beaten=%s to garden=%s back=%s" % [entered, shut, gate, skipped, vented, shut_door, door, woke, shield, flank, guard_opens, beaten, to_garden, back])
	if want.call("shrine"):
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_hill = false
		main.woke = [false, false, false]
		main.shrine_seen = false
		main.story_step = maxi(main.story_step, 6)
		main.enter_cave()
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		var cx: float = main.CAVE_X
		var reach: bool = main.player_can(cx + 4, 17) and main.player_can(cx + 4, 19)
		reset_to(Vector2(cx + 4, 18.5))
		await wait(0.3)
		var seen: bool = main.shrine_seen and main.story_open
		main.close_story()
		reset_to(main.cave_marks["1"] + Vector2(0, -1.0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var whirl: bool = main.woke[0]
		reset_to(main.cave_marks["3"] + Vector2(0, -1.0)) # the yellow altar sleeps here: it tells where, wakes nothing
		tap(KEY_SPACE)
		await wait(0.2)
		var asleep: bool = main.story_open and "물빛 동굴" in str(main.cave.altar_said) and not main.woke[2]
		main.close_story()
		main.woke[2] = true # its own altar is in the grotto
		var nova: bool = asleep and main.skill_cost(2) == 45
		main.player.hp = 50.0
		main.player.mp = 100.0
		main.player.cds[2] = 0.0
		tap(KEY_O)
		await wait(0.1)
		var healed: bool = main.player.hp > 50.0 and main.player.mp < 60.0 # 45 spent, a little drained by idling
		main.leave_cave()
		await wait(0.2)
		calm_enemies(false)
		check("shrine", reach and seen and whirl and nova and healed, "room reachable=%s shrine scene=%s whirl woke=%s nova woke (cost 45)=%s nova heals=%s (hp %.0f, mp %.0f)" % [reach, seen, whirl, nova, healed, main.player.hp, main.player.mp])
	if want.call("journal"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.1)
		main.story_step = maxi(main.story_step, 6)
		tap(KEY_Q)
		await wait(0.1)
		var shown: bool = main.ui.journal.visible
		var txt: String = plain(main.ui.journal_text.text) + plain(main.ui.journal_text2.text)
		var has: bool = "지금 할 일" in txt and "늪의 옛 지도 조각" in txt and "곁이야기" in txt and "지닌 것" in txt
		# the learnt moves: at Lv4 the first three and Lv6 next
		main.toggle_journal(false)
		var lv0: int = main.player.lv
		main.player.lv = 4
		main.toggle_journal(true)
		var txt4: String = plain(main.ui.journal_text2.text)
		var moves: bool = "익힌 기술" in txt4 and "4타 연속기, 달려 베기, 모아 베기" in txt4 and "다음: Lv6 5타 마무리" in txt4 and not "빛 칼날" in txt4
		main.player.lv = 30
		main.toggle_journal(true)
		var txt30: String = plain(main.ui.journal_text2.text)
		moves = moves and "꺼지지 않는 기세" in txt30 and not "다음:" in txt30
		main.player.lv = lv0
		tap(KEY_H)
		await wait(0.1)
		var swapped: bool = main.ui.help.visible and not main.ui.journal.visible
		main.toggle_help(false)
		check("journal", shown and has and swapped and moves, "opens with Q=%s lists quest, side stories, keepsakes=%s help swaps it out=%s learnt moves Lv4/Lv30=%s" % [shown, has, swapped, moves])
	if want.call("wolf"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		reset_to(Vector2(20, 30))
		main.spawn_wolf(Vector2(24, 30))
		var w: Dictionary = main.enemies[main.enemies.size() - 1]
		w.atk_cd = 2.0
		w.hp = 99999.0 # companions join in during the full run; keep it alive long enough to watch
		var hp0: float = main.player.hp
		var circled := false
		var lunged := false
		var start_ang := atan2(w.z - 30.0, w.x - 20.0)
		for i in 60:
			reset_to(Vector2(20, 30))
			main.player.hp = hp0
			await wait(0.1)
			if absf(wrapf(atan2(w.z - 30.0, w.x - 20.0) - start_ang, -PI, PI)) > 0.4:
				circled = true
			if w.dash > 0.0:
				lunged = true
		var spawned_forest: bool = main.forest.wolves.size() == 3
		if not w.dead:
			w.dead = true
			w.node.queue_free()
			w.shadow.queue_free()
		calm_enemies(false)
		park_mates(false)
		check("wolf", circled and lunged and spawned_forest, "circles=%s lunges=%s forest pack=%d" % [circled, lunged, main.forest.wolves.size()])
	if want.call("trial"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		main.in_village = false
		main.in_forest = false
		main.in_hill = true
		main.in_lake = false
		main.in_garden = false
		main.night_q = 4
		main.hill_q = 3
		main.trial_best = 0.0
		main.tokens[4] = false # the first clear gives the hill token (v0.1.62)
		calm_enemies(true)
		var stones: Vector2 = main.hill.marks.R
		reset_to(stones + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		reset_to(stones + Vector2(0, 9.6)) # walking off the stones ends a run
		await wait(0.2)
		var walked_off: bool = main.trial_wave == 0
		reset_to(stones + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.2)
		var began: bool = main.trial_wave == 1 and walked_off
		main.close_story()
		var g0: int = main.player.gold
		var lv0: int = main.player.lv
		var hp0: int = main.player.max_hp
		var waves := 0
		for i in 120:
			main.player.inv = 9.0
			var foes: Array = main.trial_foes()
			if not foes.is_empty():
				waves = maxi(waves, main.trial_wave)
				for e in foes:
					main.damage_enemy(e, 99999.0, Vector2(main.player.x, main.player.z))
			if main.trial_wave == 0:
				break
			await wait(0.3)
		main.close_story()
		var cleared: bool = main.trial_best > 0.0 and main.tokens[4] and main.player.gold >= g0 + 300 and main.player.max_hp == hp0 + 20 + 12 * (main.player.lv - lv0) # kills level her up too
		calm_enemies(false)
		check("trial", began and waves == 3 and cleared, "began=%s waves seen=%d cleared=%s best %.1f s" % [began, waves, cleared, main.trial_best])
	if want.call("squirrels"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		main.in_village = false
		main.in_forest = true
		main.forest_q = maxi(main.forest_q, 1)
		main.forest.freed = [false, false, false, false, false]
		main.has_acorn = false
		main.tokens[3] = false # the fifth cage gives the squirrels token (v0.1.62)
		main.cages_spawned = false
		main.spawn_cages()
		var cages: Array = main.enemies.filter(func(e): return e.has("cage") and not e.dead)
		var spots := true
		for c in cages:
			spots = spots and main.walkable(c.x + 1.0, c.z) or main.walkable(c.x - 1.0, c.z) or main.walkable(c.x, c.z + 1.0)
		var first: Dictionary = cages[0] if cages.size() > 0 else {}
		var two_hits := false
		if not first.is_empty():
			main.damage_enemy(first, 10.0, Vector2(first.x - 1.0, first.z))
			main.damage_enemy(first, 10.0, Vector2(first.x - 1.0, first.z))
			two_hits = not first.dead
		for c in cages:
			for k in 3:
				main.damage_enemy(c, 10.0, Vector2(c.x - 1.0, c.z))
		await wait(0.2)
		main.close_story()
		main.player.hp = 10.0
		main.player.pots = 1
		main.player.cds[3] = 0.0
		tap(KEY_4)
		await wait(0.1)
		var acorn: bool = main.has_acorn and main.tokens[3] and main.player.hp >= 75.0 - 0.5
		main.in_forest = false
		check("squirrels", cages.size() == 5 and spots and two_hits and acorn, "cages=%d reachable=%s still shut after 2 hits=%s acorn heals 65=%s (hp %.0f)" % [cages.size(), spots, two_hits, acorn, main.player.hp])
	if want.call("crystals"):
		main.story_step = maxi(main.story_step, 6)
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.1)
		var cr: Array = main.crystals.filter(func(e): return e.get("set", 0) == 0) # the stream's end has a set of its own
		main.crystal_done = false
		main.crystal_run = 0
		main.has_ring = false
		main.tokens[1] = false # the chest gives the ring token (v0.1.62)
		var by_rank := {}
		for e in cr:
			by_rank[main.CRYSTAL_NOTE[int(e.crystal)]] = e
		var ring := func(rank: int):
			var e: Dictionary = by_rank[rank]
			e.hurt = 0.0
			main.crystal_hit(e)
		var low: Dictionary = by_rank[0]
		main.in_cave = true
		reset_to(Vector2(low.x - 1.0, low.z))
		main.player.face = Vector2(1, 0)
		main.player.atk_cd = 0.0
		main.attack() # a real sword swing rings the lowest crystal
		var sword_rings: bool = main.crystal_run == 1
		main.in_cave = false
		main.crystal_run = 0
		await wait(0.3)
		ring.call(0)
		ring.call(2) # wrong: back to the start
		var reset: bool = main.crystal_run == 0
		for k in 4:
			ring.call(k)
		var done: bool = main.crystal_done and main.crystal_chest.visible
		var reach: bool = main.walkable(main.crystal_chest.position.x - 1.0, main.crystal_chest.position.z)
		main.in_cave = true
		reset_to(Vector2(main.crystal_chest.position.x - 1.0, main.crystal_chest.position.z))
		tap(KEY_SPACE)
		await wait(0.2)
		main.close_story()
		main.in_cave = false
		check("crystals", cr.size() == 4 and sword_rings and reset and done and reach and main.has_ring and main.tokens[1], "crystals=%d sword rings=%s wrong note resets=%s solved=%s chest reachable=%s ring=%s" % [cr.size(), sword_rings, reset, done, reach, main.has_ring])
	if want.call("esc_sheets"):
		# Esc on the journal or the controls sheet closes it and goes back to the game, not to the settings (the user asked)
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.1)
		tap(KEY_Q)
		await wait(0.1)
		var j_open: bool = main.ui.journal.visible
		tap(KEY_ESCAPE)
		await wait(0.1)
		var j_shut: bool = not main.ui.journal.visible and not main.settings_open
		tap(KEY_H)
		await wait(0.1)
		var h_open: bool = main.ui.help.visible
		tap(KEY_ESCAPE)
		await wait(0.1)
		var h_shut: bool = not main.ui.help.visible and not main.settings_open
		tap(KEY_ESCAPE)
		await wait(0.1)
		var set_open: bool = main.settings_open
		tap(KEY_ESCAPE)
		await wait(0.1)
		check("esc_sheets", j_open and j_shut and h_open and h_shut and set_open and not main.settings_open,
			"journal open/closed by Esc=%s/%s help open/closed=%s/%s Esc on the game opens the settings=%s" % [j_open, j_shut, h_open, h_shut, set_open])
	if want.call("news_more"):
		# 바뀐 것 shows CHANGES_PAGE lines; the 더 읽기 button is there only past that and brings the rest
		var n: int = main.CHANGES.size()
		var first: int = main.ui.news.text.split("\n", false).size() # an empty line now stands between entries (v0.0.90)
		var btn_ok: bool = main.ui.news_more.visible == (n > main.CHANGES_PAGE)
		main.ui.news_more.pressed.emit()
		await wait(0.1)
		var after: int = main.ui.news.text.split("\n", false).size()
		check("news_more", first == main.menus.news_text(main.CHANGES_PAGE).split("\n", false).size() and btn_ok and after == main.menus.news_text(2 * main.CHANGES_PAGE).split("\n", false).size(),
			"lines %d (want %d) of %d at first, button only past %d=%s, after 더 읽기 %d (want %d)" % [first, main.menus.news_text(main.CHANGES_PAGE).split("\n", false).size(), n, main.CHANGES_PAGE, btn_ok, after, main.menus.news_text(2 * main.CHANGES_PAGE).split("\n", false).size()])
	if want.call("touch_controls"):
		# phones: a finger on the left grabs the stick and walks her (pushed to the rim she runs), another finger on the
		# sword key swings at the same time, the shield key guards while held; taps on the world do not swing
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		main.enable_touch()
		await wait(0.2)
		var vs: Vector2 = main.get_viewport().get_visible_rect().size
		reset_to(main.START)
		await wait(0.2)
		var at0 := Vector2(main.player.x, main.player.z)
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = Vector2(vs.x * 0.1, vs.y * 0.8) # the test window is small: the left part of it
		Input.parse_input_event(down)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = down.position - Vector2(0, 90)
		Input.parse_input_event(drag)
		await wait(0.1)
		var runs: bool = main.key_down(KEY_SHIFT)
		var sword := InputEventScreenTouch.new() # a second finger on the sword key while walking
		sword.index = 1
		sword.pressed = true
		sword.position = main.touch_layer.keys()["attack"][0]
		main.player.atk_cd = 0.0
		var combo0: int = main.player.combo
		Input.parse_input_event(sword)
		await wait(0.05)
		var swung: bool = main.player.combo != combo0 or main.player.atk_cd > 0.0
		var up := sword.duplicate()
		up.pressed = false
		Input.parse_input_event(up)
		await wait(0.6)
		var moved: float = Vector2(main.player.x, main.player.z).distance_to(at0)
		var lift := down.duplicate()
		lift.pressed = false
		Input.parse_input_event(lift)
		await wait(0.1)
		var stopped: bool = main.touch_move == Vector2.ZERO and not main.key_down(KEY_SHIFT)
		var shield := InputEventScreenTouch.new()
		shield.index = 2
		shield.pressed = true
		shield.position = main.touch_layer.keys()["guard"][0]
		Input.parse_input_event(shield)
		await wait(0.05)
		var guards: bool = main.key_down(KEY_L)
		var off := shield.duplicate()
		off.pressed = false
		Input.parse_input_event(off)
		await wait(0.05)
		var unguards: bool = not main.key_down(KEY_L)
		main.player.atk_cd = 0.0
		var combo1: int = main.player.combo
		var click := InputEventMouseButton.new() # the browser's mouse made from a tap on the world
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = vs / 2.0
		Input.parse_input_event(click)
		var click_up := click.duplicate()
		click_up.pressed = false
		Input.parse_input_event(click_up)
		await wait(0.05)
		var no_swing: bool = main.player.combo == combo1 and main.player.atk_cd <= 0.0
		# the phone layout (GPT's third playtest): the zoom keys clear of the boss bar and a long quest line, the quest
		# line clear of the companions' rows and the menu keys, sheet back keys at least 56 px on screen, touch help in
		# the controls sheet, and the shop with the menu keys and minimap stepped aside and its board on the screen; laid
		# out on a phone's 960x540 canvas (the headless window is tiny), put back afterwards
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(960, 540)
		main.enable_touch()
		await wait(0.2)
		vs = main.get_viewport().get_visible_rect().size
		var quest0: String = plain(main.ui.quest.text)
		var boss0: bool = main.ui.boss.visible
		main.ui.boss.visible = true
		main.set_quest("벽돌 벽을 팔찌로 풀며 숲 동쪽 끝의 노을에게 가자. 길을 막은 회색 나무는 팔찌로 하나씩 풀 수 있다")
		await wait(0.1)
		var tk: Dictionary = main.touch_layer.keys()
		var boss_r: Rect2 = main.ui.boss.get_global_rect()
		var quest_r: Rect2 = main.ui.quest.get_global_rect()
		var mates_r := Rect2(140, 150, 146, 64) # the companions' two rows (build_mate_hud)
		var clear: bool = not quest_r.intersects(mates_r) and not boss_r.intersects(mates_r) and (quest_r.end.x <= vs.x - 194.0 or quest_r.position.y >= 202.0) and main.ui.quest.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		for n in ["zoom_in", "zoom_out"]:
			var zr := Rect2(tk[n][0] - Vector2.ONE * tk[n][1], Vector2.ONE * tk[n][1] * 2.0)
			clear = clear and not zr.intersects(boss_r) and not zr.intersects(quest_r)
			for b in [main.ui.hint, main.ui.sound_btn, main.ui.journal_btn, main.ui.settings_btn]:
				clear = clear and not zr.intersects((b as Control).get_global_rect())
		for b in [main.ui.hint, main.ui.sound_btn, main.ui.journal_btn, main.ui.settings_btn]:
			clear = clear and not (b as Control).get_global_rect().intersects(quest_r) and not (b as Control).get_global_rect().intersects(boss_r)
		main.ui.boss.visible = boss0
		main.set_quest(quest0)
		var backs := true
		for sheet in [main.ui.help, main.ui.journal, main.ui.set_card, main.ui.shop]:
			for c in sheet.get_children():
				if c.has_meta("back"):
					backs = backs and (c as Control).get_global_rect().size.x >= 55.9
		var touch_help: bool = main.ui.help_rows == main.ui.help_touch_rows and main.ui.help_touch_rows[0][0].visible and not main.ui.help_keys_rows[0][0].visible \
			and main.ui.set_stacks[1] == main.ui.set_help_touch
		main.shop_open = true
		main.ui.shop.visible = true
		main.fit_shop()
		main.touch_layer.step_aside()
		var board_r: Rect2 = main.ui.shop_board.get_global_rect()
		var shop_ok: bool = not main.ui.hint.visible and not main.ui.settings_btn.visible and not main.ui.mini.get_parent().visible \
			and board_r.position.y >= 17.0 and board_r.end.y <= main.ui.shop_line.get_global_rect().position.y - 17.0 and board_r.end.x <= vs.x and main.ui.shop_back.visible
		main.shop_open = false
		main.ui.shop.visible = false
		main.touch_layer.step_aside()
		var keys_back: bool = main.ui.hint.visible and main.ui.mini.get_parent().visible
		main.disable_touch()
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		await wait(0.1)
		var desk: bool = main.ui.help_rows == main.ui.help_keys_rows \
			and not main.ui.shop_back.visible and main.ui.shop_board.scale == Vector2.ONE and main.ui.hint.visible
		var q0: String = plain(main.ui.quest.text)
		main.touch_ui = true # on phones the keyboard words read as the touch keys
		main.set_quest("벽돌 벽을 풀자 (E)")
		var words_ok: bool = "팔찌 단추" in plain(main.ui.quest.text) and not "(E)" in plain(main.ui.quest.text)
		main.touch_ui = false
		main.ui.quest.text = q0
		calm_enemies(false)
		check("touch_controls", words_ok and moved > 1.5 and runs and swung and stopped and guards and unguards and no_swing and clear and backs and touch_help and shop_ok and keys_back and desk,
			"stick walked %.1f tiles, runs at the rim=%s sword while walking=%s let go stops=%s shield held/let go=%s/%s a tap on the world does not swing=%s; layout clear=%s (quest %s boss %s vs %s) back keys 56=%s touch help=%s shop fits, keys aside=%s back after=%s desktop again=%s" % [moved, runs, swung, stopped, guards, unguards, no_swing, clear, quest_r, boss_r, [vs, mates_r, quest_r.intersects(mates_r), boss_r.intersects(mates_r), main.ui.quest.autowrap_mode], backs, touch_help, shop_ok, keys_back, desk])
	if want.call("quest_layout"):
		# the quest line is laid out from real rects: at every window size, with 0 - 2 companions and the boss bar on or
		# off, its ornament box stays on screen and clear of the status panel, the dial, the companions' rows, the boss
		# bar, the minimap and the menu keys (the user, 2026-10-25: it ran over the companions); the wording follows the
		# input used last
		if main.intro:
			main.start_game(false)
		main.close_story()
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		var quest0: String = main.quest_raw
		var texts := ["동쪽 출구로 나가자 (E)", "벽돌 벽을 팔찌로 풀며 숲 동쪽 끝의 노을에게 가자. 길을 막은 회색 나무는 팔찌로 하나씩 풀 수 있다"]
		var sizes := [Vector2i(645, 480), Vector2i(900, 600), Vector2i(1179, 700), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(960, 540)]
		var bad: Array = []
		var cases := 0
		var wrapped_long := true
		for touch in [false, true]:
			if touch:
				main.enable_touch()
			for sz in sizes:
				if touch and sz != Vector2i(960, 540):
					continue
				root.content_scale_size = sz
				await wait(0.1)
				var vs: Vector2 = main.get_viewport().get_visible_rect().size
				for n_mates in [0, 1, 2]:
					for boss in [false, true]:
						for ti in 2:
							main.ui.boss.visible = boss
							for i in 2:
								main.ui.mate_rows[i].row.visible = i < n_mates
							main.set_quest(texts[ti])
							main.hud_build.layout_top()
							var d: Rect2 = main.hud_build.quest_deco
							var qr: Rect2 = main.ui.quest.get_global_rect()
							var ok: bool = d.position.x >= 0.0 and d.end.x <= vs.x and d.position.y >= 0.0 and d.end.y <= vs.y and d.encloses(qr.grow(-0.5))
							var why := ""
							for r in main.hud_build.quest_blocks(false):
								if d.intersects(r):
									ok = false
									why = str(r)
							if boss:
								var br: Rect2 = main.hud_build.boss_rect()
								for r in [main.hud_build.status_rect(), main.hud_build.dial_rect(), main.hud_build.mates_rect(), main.ui.mini.get_parent().get_global_rect()]:
									if br.intersects(r) and (r as Rect2).size != Vector2.ZERO:
										ok = false
										why = "boss " + str(r)
							cases += 1
							if not ok:
								bad.append("%s %s mates %d boss %s text %d deco %s qr %s %s" % [touch, vs, n_mates, boss, ti, d, qr, why])
				main.ui.boss.visible = false
		var blocks_n: int = main.hud_build.quest_blocks(false).size()
		main.disable_touch()
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		# wording: a touch layout says the touch names until a key is pressed, then the key names, and back after a touch
		main.enable_touch()
		main.set_quest("벽돌 벽을 풀자 (E)")
		var w_touch: bool = "팔찌 단추" in plain(main.ui.quest.text)
		var kev := InputEventKey.new()
		kev.keycode = KEY_W
		kev.pressed = true
		main._input(kev)
		var w_key: bool = "(E)" in plain(main.ui.quest.text) and main.quest_raw == "벽돌 벽을 풀자 (E)"
		var tev := InputEventScreenTouch.new()
		tev.pressed = true
		main._input(tev)
		var w_back: bool = "팔찌 단추" in plain(main.ui.quest.text)
		main.disable_touch()
		main.set_quest(quest0)
		await wait(0.1)
		check("quest_layout", bad.is_empty() and blocks_n >= 6 and w_touch and w_key and w_back,
			"%d layouts, %d bad %s; blocks %d; wording touch/key/touch again=%s/%s/%s" % [cases, bad.size(), bad.slice(0, 3), blocks_n, w_touch, w_key, w_back])
	if want.call("story_pad"):
		# the story box: the space above the first text line equals the space below the last, on one-line and three-line
		# narration and on a named line, at 645, 900 and 1600 px and in the touch layout (the user, 2026-10-25)
		if main.intro:
			main.start_game(false)
		main.close_story()
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		var lines := ["|-|달지기 책 1/5", "|-|바람이 잦아든 방에는 오래된 책장이 줄지어 서 있고, 그 사이로 먼지가 천천히 내려앉는다. 소라는 숨을 죽인 채 한 걸음씩 안으로 들어갔다. 책장 끝에서 낡은 책 한 권이 희미하게 빛나고 있었다.", "소라|calm|여기서 잠깐 쉬었다 가자."]
		var bad: Array = []
		var worst := 0.0
		var cases := 0
		for touch in [false, true]:
			if touch:
				main.enable_touch()
			for w in [645, 900, 1600]:
				if touch and w != 900:
					continue
				root.content_scale_size = Vector2i(w, 480) if not touch else Vector2i(960, 540)
				await wait(0.1)
				var vs: Vector2 = main.get_viewport().get_visible_rect().size
				for l in lines:
					main.show_story("", [l])
					main.fit_story()
					var cap: Control = main.ui.story_cap
					var tx: Control = main.ui.story_text
					var box_h: float = cap.offset_bottom - cap.offset_top
					var top: float = tx.position.y
					var bot: float = box_h - (tx.position.y + tx.size.y)
					var r: Rect2 = cap.get_global_rect()
					# fit_story lifts the block by 0.8 x the font descent (Hangul has no descenders; owner 2026-10-29)
					var lift2: float = 2.0 * 0.8 * main.ui_font.get_descent(tx.get_theme_font_size("font_size"))
					worst = maxf(worst, absf(top - bot + lift2))
					cases += 1
					if absf(top - bot + lift2) > 2.0 or r.position.x < 0.0 or r.end.x > vs.x + 0.5 or r.position.y < 0.0 or r.end.y > vs.y + 0.5:
						bad.append("%s %d %s top %.1f bottom %.1f box %s" % [touch, w, l.substr(0, 6), top, bot, r])
		main.close_story()
		main.disable_touch()
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		await wait(0.1)
		check("story_pad", bad.is_empty(), "%d boxes, worst top/bottom gap %.2f px, bad %s" % [cases, worst, bad.slice(0, 3)])
	if want.call("folk_hop"):
		# walkers hop (the user, 2026-10-25): up to 0.12 within one hop distance of walking, back on the ground between
		# hops, settled within 0.2 s of stopping, and the node (so a balloon anchored to it) never leaves the ground
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var holder := Node3D.new()
		main.add_child(holder)
		var hopper := Sprite3D.new()
		hopper.texture = load("res://art/folk/tori.png")
		hopper.hframes = 2
		holder.add_child(hopper)
		var fdt := 1.0 / 60.0
		var peak := 0.0
		var peak_first := 0.0
		var lows := 0
		var below := true
		var walked := 0.0
		for i in 150: # 2.5 s at 3.6 tiles a second
			holder.position.x += 3.6 * fdt
			walked += 3.6 * fdt
			main.folk.hop("test", hopper, fdt)
			peak = maxf(peak, hopper.position.y)
			if walked <= main.folk.HOP_STEP:
				peak_first = maxf(peak_first, hopper.position.y)
			if hopper.position.y < 0.02 and not below:
				lows += 1
			below = hopper.position.y < 0.02
		var stopped_t := -1.0
		for i in 30:
			main.folk.hop("test", hopper, fdt)
			if hopper.position.y < 0.001 and stopped_t < 0.0:
				stopped_t = (i + 1) * fdt
		var settled: bool = stopped_t >= 0.0 and stopped_t <= 0.2 and hopper.position.y < 0.001 and absf(hopper.scale.y - 1.0 / cos(0.78)) < 0.0001 or (stopped_t >= 0.0 and stopped_t <= 0.2 and hopper.position.y < 0.001)
		var node_flat: bool = holder.position.y == 0.0
		holder.queue_free()
		# the companion: Mulgyeol hops while he follows Sora, and the node he stands in stays on the ground
		park_mates(false)
		main.join_mate()
		main.snap_mates()
		var mspr: Sprite3D = main.mate.get_child(0)
		var mpeak := 0.0
		var mnode := 0.0
		reset_to(Vector2(main.player.x, main.player.z))
		main.fake_keys[KEY_D] = true
		main.fake_keys[KEY_SHIFT] = true
		for i in 40:
			await get_tree().process_frame
			mpeak = maxf(mpeak, mspr.position.y)
			mnode = maxf(mnode, absf(main.mate.position.y))
		release()
		calm_enemies(true) # the pack goblins now hang back nearby, and a companion who sees one keeps going
		var mrest := false
		var still := 0
		var mwhy := ""
		for i in 50: # he walks up to Sora first (late in a full run he may trail further), then stands still for 0.4 s
			calm_enemies(true) # parked foes walk back (pack goblins since v0.1.8), and he would chase them
			await wait(0.1)
			var md := Vector2(main.mate.position.x - main.player.x, main.mate.position.z - main.player.z).length()
			still = still + 1 if mspr.position.y < 0.001 and md < 2.5 else 0
			var near: int = main.enemies.filter(func(e): return not e.dead and not e.get("prop", false) and not e.get("air", false) and Vector2(e.x, e.z).distance_to(Vector2(main.mate.position.x, main.mate.position.z)) < 5.0).size()
			mwhy = "dist %.2f y %.3f idle %.1f goal %s at %s job %s foes<5 %d" % [md, mspr.position.y, main.mate_idle, main.mate_aim.get("mulgyeol"), main.mate.position, main.mate_job, near]
			if still >= 4:
				mrest = true
				break
		calm_enemies(false)
		check("folk_hop", peak > 0.1 and peak <= 0.1201 and peak_first > 0.1 and lows >= 4 and settled and node_flat and mpeak > 0.1 and mpeak <= 0.1201 and mnode < 0.001 and mrest,
			"peak %.3f (first hop %.3f), landed %d times, settled in %.2f s, node on the ground=%s; Mulgyeol peak %.3f node %.3f, rests %s%s" % [peak, peak_first, lows, stopped_t, node_flat, mpeak, mnode, mrest, "" if mrest else " (" + mwhy + ")"])
	if want.call("folk_height"):
		# the villagers' heights come from one table (the user, 2026-10-25: the children looked big next to Noeul)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var bad: Array = []
		var tallest := 0.0
		var noeul_h := 1.8
		for id in main.village.folk_node:
			var vs: Sprite3D = main.village.folk_node[id]
			var h: float = vs.pixel_size * vs.texture.get_height()
			tallest = maxf(tallest, h)
			if absf(h - main.folk_height(id)) > 0.01:
				bad.append("%s village %.3f vs %.3f" % [id, h, main.folk_height(id)])
			var fs: Sprite3D = main.folk_sprite(id)
			var fh: float = fs.pixel_size * fs.texture.get_height()
			if absf(fh - main.folk_height(id)) > 0.01 or absf(fs.offset.y - fs.texture.get_height() / 2.0) > 0.01:
				bad.append("%s folk_sprite %.3f" % [id, fh])
			fs.free()
		var sj: Sprite3D = main.village.simji_node.get_child(0)
		var sj_h: float = sj.pixel_size * sj.texture.get_height()
		var kid_h: float = main.folk_height("kid")
		var shorter: bool = main.folk_height("tori") < noeul_h - 0.3 and main.folk_height("kongal") < noeul_h - 0.3
		var simji_top: bool = absf(sj_h - 2.1) < 0.01 and tallest <= sj_h + 0.001 and kid_h < main.folk_height("kongal")
		var balloon: bool = main.folk_bubble_y("simji") > main.folk_bubble_y("doran") and main.folk_bubble_y("tori") < main.folk_bubble_y("doran")
		check("folk_height", bad.is_empty() and shorter and simji_top and balloon,
			"%d villagers, off the table %s; Tori %.2f / Kongal %.2f under Noeul %.2f=%s; Simji %.2f tallest=%s; balloons follow=%s" % [main.village.folk_node.size(), bad, main.folk_height("tori"), main.folk_height("kongal"), noeul_h, shorter, sj_h, simji_top, balloon])
	if want.call("mash"):
		# keys mashed in a fight (the user, 2026-10-25: Sora "warps"): attack, dodge, guard, skills, Shift, random directions
		# changing every 0.1 - 0.3 s, with the water skip off and on, in the open and on a shore. No rescue hop may
		# fire (a real water stop on the shore excepted) and no frame may move her over 1.0 unit unless a scripted slide
		# (dash slash, rescue glide) is running.
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		for z in ["in_village", "in_forest", "in_lake", "in_garden", "in_cave", "in_hill"]:
			main.set(z, false)
		park_mates(true)
		calm_enemies(true) # a foe's blow (the marsh's clapper birds roam at random) may knock her into the water: that rescue is not the keys' doing
		var shore := Vector2(20, 30)
		var field := Vector2(20, 30)
		var fld := false
		var nb := false
		for sz in range(4, 44):
			for sx in range(4, 44):
				if not fld:
					var clear := true
					for ox in range(-3, 4):
						for oz in range(-3, 4):
							clear = clear and main.tile_at(sx + ox, sz + oz) != main.WATER and main.player_can(sx + ox, sz + oz)
					if clear:
						field = Vector2(sx, sz)
						fld = true
				if nb:
					continue
				if main.tile_at(sx, sz) != main.WATER and main.player_can(sx, sz) and (main.tile_at(sx + 1, sz) == main.WATER or main.tile_at(sx, sz + 1) == main.WATER) and main.player_can(sx - 1.0, sz - 1.0):
					shore = Vector2(sx, sz)
					nb = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261025
		var skip0: bool = main.has_skip
		var lv0: int = main.player.lv
		var report: Array = []
		var stuck_hops := 0
		var big_jumps := 0
		var dashes := 0
		var worst := 0.0
		var runs := [[field, false], [field, true], [shore, false], [shore, true]]
		for run in runs:
			main.has_skip = run[1]
			main.player.lv = 5
			main.player.max_hp = 5000
			reset_to(run[0])
			calm_enemies(true)
			for k in 3:
				main.spawn_enemy(run[0] + Vector2(2.5 + k, -1.0 + k))
			main.unstick_log.clear()
			var last := Vector2(main.player.x, main.player.z)
			var dir_t := 0.0
			var t_end := 12.0
			var el := 0.0
			var shore_run: bool = run[0] == shore and nb
			while el < t_end:
				var step_t := rng.randf_range(0.1, 0.3)
				main.fake_keys.clear()
				var dirs := [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2.ZERO]
				hold_world(dirs[rng.randi() % dirs.size()])
				if rng.randf() < 0.6:
					main.fake_keys[KEY_SHIFT] = true
				if rng.randf() < 0.2:
					main.fake_keys[KEY_L] = true
				main.player.hp = float(main.player.max_hp)
				main.player.sp = maxf(main.player.sp, 40.0)
				for key in [KEY_J, KEY_J, KEY_J, KEY_K, KEY_U, KEY_I, KEY_O, KEY_4]:
					if rng.randf() < 0.45:
						tap(key)
				var t_in := 0.0
				while t_in < step_t:
					await get_tree().process_frame
					t_in += 0.016
					el += 0.016
					var now := Vector2(main.player.x, main.player.z)
					var jump := now.distance_to(last)
					worst = maxf(worst, jump)
					if jump > 1.0 and jump < 20.0 and main.dash.is_empty() and main.rescue_glide.is_empty() and main.windrun_glide.is_empty() and main.gust_dir == Vector2.ZERO and main.down_t <= 0.0:
						big_jumps += 1
						report.append("jump %.2f at %s" % [jump, now])
					if not main.dash.is_empty():
						dashes += 1
					last = now
			release()
			for e in main.unstick_log:
				if e.reason == "stuck" or (e.reason == "water" and not shore_run):
					stuck_hops += 1
					report.append(str(e))
			calm_enemies(false)
		main.has_skip = skip0
		main.player.lv = lv0
		main.dash = {}
		main.rescue_glide = {}
		release()
		park_mates(false)
		main.return_to_start()
		check("mash", stuck_hops == 0 and big_jumps == 0 and dashes > 0, "4 runs of 12 s mashed (field %s, shore %s): %d rescue hops, %d jumps over 1.0 (worst frame %.2f), dash frames %d %s" % [field, shore, stuck_hops, big_jumps, worst, dashes, report.slice(0, 3)])
	if want.call("bgm"):
		# background music: which tune the place calls for, the switch, the buses, the header buttons, the nine loops
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var keep := {}
		for k in ["intro", "in_village", "in_forest", "in_lake", "in_garden", "in_cave", "in_hill", "in_house", "garden_q", "hour", "day", "ending_due"]:
			keep[k] = main.get(k)
		var keep_x: float = main.player.x
		var keep_boss: bool = main.ui.boss.visible
		var keep_mail: Array = main.mail_got.duplicate()
		var bad: Array = []
		var base := func():
			for k in ["intro", "in_village", "in_forest", "in_lake", "in_garden", "in_cave", "in_hill", "ending_due"]:
				main.set(k, false)
			main.in_house = -1
			main.garden_q = 0
			main.hour = 12.0
			main.ui.boss.visible = false
			main.player.x = 20.0
			main.mail_got = [false, false, false]
		var expect := func(label: String, want_tune: String):
			var got: String = main.music.pick()
			if got != want_tune:
				bad.append("%s: %s, wanted %s" % [label, got, want_tune])
		base.call()
		main.intro = true
		expect.call("title", "title")
		base.call()
		main.in_village = true
		expect.call("village by day", "village")
		main.hour = 23.0
		expect.call("village by night", "village")
		main.in_house = 0
		expect.call("a house at night", "village")
		base.call()
		expect.call("marsh", "field_marsh")
		main.in_lake = true
		expect.call("lake", "field_marsh")
		base.call()
		main.in_forest = true
		expect.call("forest", "field_wild")
		main.hour = 23.0
		expect.call("forest at night", "field_wild")
		base.call()
		main.in_cave = true
		expect.call("cave", "dungeon")
		main.hour = 23.0
		expect.call("cave at night", "dungeon")
		base.call()
		main.in_hill = true
		main.player.x = main.CASTLE.CASTLE_X + 5.0
		expect.call("castle", "dungeon")
		base.call()
		main.in_forest = true
		main.ui.boss.visible = true
		expect.call("a boss awake", "boss")
		base.call()
		main.in_garden = true
		main.garden_q = 2
		main.ui.boss.visible = true
		expect.call("the mold", "boss_final")
		base.call()
		main.in_garden = true
		main.garden_q = 5
		expect.call("the clock room after the winding", "ending")
		base.call()
		main.in_village = true
		main.mail_got = [true, true, true]
		var fest := false
		for d in 40:
			main.day = d
			main.hour = 23.0
			if main.festival_now():
				fest = true
				break
		if fest:
			expect.call("the festival", "ending")
		else:
			bad.append("no festival night found")
		# the switch: flips, saves, aims the Music bus; and back
		var on0: bool = main.music_on
		main.music.toggle_music()
		var off_ok: bool = main.music_on != on0 and main.music.bus_target == main.music.OFF_DB and bool(JSON.parse_string(FileAccess.get_file_as_string(main.menus.SETTINGS_PATH)).get("music", true)) == main.music_on
		main.music.toggle_music()
		var on_ok: bool = main.music_on == on0 and main.music.bus_target == main.music.MUSIC_DB
		# buses, and the effects play on the Sfx one
		var buses: bool = AudioServer.get_bus_index("Sfx") >= 0 and AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_send(AudioServer.get_bus_index("Music")) == &"Master"
		var sfx_bus := false
		var n0: int = main.get_child_count()
		main.sfx(440.0, 0.05)
		for c in main.get_children():
			if c is AudioStreamPlayer and c.bus == &"Sfx":
				sfx_bus = true
		# the settings header: four buttons, 44 x 40, 8 px apart, inside the 640 px column
		var hb: Array = [main.ui.set_sound, main.ui.set_music, main.ui.set_minus, main.ui.set_plus]
		var header := true
		for i in hb.size():
			var b: Control = hb[i]
			header = header and b.size == Vector2(44, 40) and b.position.x + b.size.x <= 640.0
			if i > 0:
				header = header and absf(b.position.x - (hb[i - 1].position.x + hb[i - 1].size.x) - 8.0) < 0.01
		# the nine places' five loops each, and a place's next tune after ROTATE seconds
		var loops := true
		for n in main.music.TUNES:
			for k in main.music.VARIANTS:
				var fname: String = n if k == 0 else "%s_%d" % [n, k + 1]
				if fname in main.music.DROPPED:
					loops = loops and not FileAccess.file_exists("res://audio/bgm/%s.ogg" % fname)
					continue
				var st = load("res://audio/bgm/%s.ogg" % fname)
				loops = loops and st is AudioStreamOggVorbis and st.loop
		main.music.play("village")
		var f0: String = main.music.cur_file
		# past ROTATE the tune is not cut in the middle of a loop; at the loop's end the next one comes
		main.music.played = main.music.ROTATE + 1.0
		main.music.play("village")
		var kept: bool = main.music.cur_file == f0
		main.music.due = true
		main.music.play("village")
		loops = loops and kept and main.music.cur_file != f0 and main.music.cur_file.begins_with(main.music.cur)
		# put the state back
		for k in keep:
			main.set(k, keep[k])
		main.player.x = keep_x
		main.ui.boss.visible = keep_boss
		main.mail_got = keep_mail
		check("bgm", bad.is_empty() and off_ok and on_ok and buses and sfx_bus and header and loops,
			"picks %s; switch off/on=%s/%s; buses=%s effects on Sfx=%s; header buttons=%s %s; nine loops=%s" % [str(bad), off_ok, on_ok, buses, sfx_bus, header, str(hb.map(func(b): return [b.position, b.size])), loops])
	if want.call("folk_sleep"):
		# after dark the villagers walk home and go in (Simji stays out); in his house Doran sleeps and E still talks to
		# him; in the morning they come back out (the user asked, 2026-10-24)
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.1)
		var h0: float = main.hour
		var m1: bool = main.mail_got[1]
		main.mail_got[1] = false # no festival tonight
		main.sleep_off = false
		main.hour = 12.0 # start by day with everyone out
		main.in_village = true
		main.in_house = -1
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		main.in_village = true
		main.in_lake = false
		main.in_forest = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		reset_to(main.village.marks.M + Vector2(0, 2))
		main.hour = 23.0
		main.update_folk_sleep(0.0)
		var walks: bool = main.folk_state.get("doran", "") == "going"
		main.update_folk_sleep(30.0)
		var spr: Sprite3D = main.village.folk_node.doran
		var gone: bool = main.folk_state.doran == "in" and not spr.visible and main.folk_talk_at("doran") == Vector2.INF
		var simji_out: bool = main.village.simji_node.visible
		main.enter_house(main.folk_home("doran"))
		main.update_folk_sleep(0.0)
		var in_bed: bool = main.sleeper_nodes.doran.visible
		reset_to(Vector2(main.HOUSE_X + 3.0, 2.0))
		var errands := [main.doran_q, main.kid_q, main.mul_q, main.errand, main.mail_q, main.met.duplicate()]
		main.crown_key()
		await wait(0.1)
		var talks: bool = main.story_open
		main.close_story()
		# waking him may start one of his errands: put them back, the later tests count on them
		main.doran_q = errands[0]
		main.kid_q = errands[1]
		main.mul_q = errands[2]
		main.errand = errands[3]
		main.mail_q = errands[4]
		main.met = errands[5]
		await wait(0.1)
		main.leave_house()
		main.hour = 9.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		var back: bool = main.folk_state.doran == "out" and spr.visible and Vector2(spr.position.x, spr.position.z).distance_to(main.village.folk_pos.doran) < 0.1
		reset_to(main.village.folk_pos.kongal + Vector2(-2.0, 0)) # back out at night: E on Kongal's empty spot says where she is
		main.hour = 23.0
		main.update_folk_sleep(30.0)
		reset_to(main.village.folk_pos.kongal + Vector2(1.0, 0))
		main.toast_t = 0.0
		var hinted: bool = main.asleep_hint(Vector2(main.player.x, main.player.z))
		main.hour = 12.0
		main.update_folk_sleep(30.0)
		main.sleep_off = true
		main.hour = h0
		main.mail_got[1] = m1
		main.in_village = false
		back = back and hinted
		check("folk_sleep", walks and gone and simji_out and in_bed and talks and back,
			"at night walks home=%s gone in=%s Simji stays out=%s asleep in his house=%s E talks to him there=%s back out by day=%s" % [walks, gone, simji_out, in_bed, talks, back])
	if want.call("folk_routine"):
		# by day the villagers walk their rounds (the user, 2026-10-24): every leg is on open ground clear of doors,
		# stalls and the others' spots; Tori leaves his spot and comes back, E talks to him mid-way, and at dusk he
		# walks home from where he is
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.1)
		var keep := {"hour": main.hour, "fest": main.mail_got[1], "met": main.met.duplicate(), "seen": main.hf_seen.duplicate(true),
			"turn": main.hf_turn.duplicate(), "gold": main.player.gold, "pots": main.player.pots, "bait": main.has_bait,
			"px": main.player.x, "pz": main.player.z}
		main.in_village = true
		main.in_house = -1
		main.in_lake = false
		main.in_forest = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		main.hour = 12.0
		main.mail_got[1] = false # no festival tonight
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		# every leg: walkable (his own rock aside), 0.9 tiles clear of doors, stalls, the yard post and the others' spots
		var vx := float(main.VILLAGE.VILLAGE_X)
		var avoid: Array = main.village.doors.duplicate()
		for key in ["1", "2", "3", "Q", "N", "f", "F", "M"]:
			avoid.append(main.village.marks[key])
		var bad := ""
		for id in main.FOLK_ROUTES:
			var pts: Array = main.FOLK_ROUTES[id]
			var home: Vector2 = main.village.folk_pos[id]
			if main.route_at(id, 0) != home:
				bad += "%s starts off his spot; " % id
			var own: Dictionary = main.folk_rocks[id]
			var r0: float = own.r
			own.r = 0.0
			var others: Array = avoid.duplicate()
			for o in main.FOLK_ROUTES:
				if o != id:
					others.append(main.village.folk_pos[o])
			for i in pts.size():
				var a: Vector2 = main.route_at(id, i)
				var b: Vector2 = main.route_at(id, (i + 1) % pts.size())
				var steps := int(a.distance_to(b) / 0.1) + 1
				for s in steps + 1:
					var p := a.lerp(b, float(s) / steps)
					if not main.walkable(p.x, p.y):
						bad += "%s blocked at %.1f,%.1f; " % [id, p.x - vx, p.y]
						break
					if p.distance_to(home) > 1.0 and others.any(func(q): return p.distance_to(q) < 0.9):
						bad += "%s too near something at %.1f,%.1f; " % [id, p.x - vx, p.y]
						break
			own.r = r0
		var legs_ok := bad == ""
		main.routine_off = false
		reset_to(main.village.marks.M + Vector2(0, 2)) # on the square, off everyone's way
		var spr: Sprite3D = main.village.folk_node.tori
		var home_t: Vector2 = main.village.folk_pos.tori
		var r: Dictionary = main.folk_route_state("tori")
		r.wait = 0.0
		var left := false
		for k in 200: # 20 s
			main.update_folk_sleep(0.1)
			if (r.pos as Vector2).distance_to(home_t) > 4.0:
				left = true
				break
		var sprite_follows: bool = Vector2(spr.position.x, spr.position.z).distance_to(r.pos) < 0.01
		# E mid-way: Sora a tile behind him; the walk stops while the talk is up
		var mid: Vector2 = r.pos
		var talk_at: bool = main.folk_talk_at("tori") == mid
		reset_to(mid + Vector2(1.0, 0))
		main.crown_key()
		var talks: bool = main.story_open and main.ui.story_who.text.begins_with("토리")
		await wait(0.3)
		var held: bool = (r.pos as Vector2) == mid
		main.close_story()
		await wait(0.1)
		reset_to(main.village.marks.M + Vector2(0, 2))
		var came_back := false
		for k in 2400: # up to 240 s round the loop
			main.update_folk_sleep(0.1)
			if r.i == 0 and (r.pos as Vector2).distance_to(home_t) < 0.01:
				came_back = true
				break
		# dusk while he is out on his round: he walks back along it, then home to his door
		r.wait = 0.0
		for k in 200:
			main.update_folk_sleep(0.1)
			if (r.pos as Vector2).distance_to(home_t) > 4.0:
				break
		var out_at: Vector2 = r.pos
		main.sleep_off = false
		main.hour = 23.0
		main.update_folk_sleep(0.0)
		var going: bool = main.folk_state.tori == "going"
		main.update_folk_sleep(0.5)
		var from_there: bool = Vector2(spr.position.x, spr.position.z).distance_to(out_at) < 1.0 and (r.pos as Vector2).distance_to(home_t) < out_at.distance_to(home_t)
		var gone_in := false
		for k in 1200:
			main.update_folk_sleep(0.1)
			if main.folk_state.tori == "in":
				gone_in = true
				break
		var walks_home: bool = going and from_there and gone_in and main.route_home("tori")
		# put everything back: morning, everyone on his spot, the routines off again
		main.hour = 12.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		main.routine_off = true
		for k in 3000:
			main.update_folk_sleep(0.1)
			if main.FOLK_ROUTES.keys().all(func(id): return main.route_home(id)):
				break
		var all_home: bool = main.FOLK_ROUTES.keys().all(func(id): return main.route_home(id))
		main.sleep_off = true
		main.hour = keep.hour
		main.mail_got[1] = keep.fest
		main.met = keep.met
		main.hf_seen = keep.seen
		main.hf_turn = keep.turn
		main.player.gold = keep.gold
		main.player.pots = keep.pots
		main.has_bait = keep.bait
		reset_to(Vector2(keep.px, keep.pz))
		main.in_village = false
		check("folk_routine", legs_ok and left and sprite_follows and talk_at and talks and held and came_back and walks_home and all_home,
			"legs clear=%s %s left his spot=%s sprite on him=%s talk where he is=%s E mid-way=%s stops while talked to=%s came back=%s walks home at dusk from his round=%s (going=%s from there=%s in=%s) all back on their spots=%s" % [legs_ok, bad, left, sprite_follows, talk_at, talks, held, came_back, walks_home, going, from_there, gone_in, all_home])
	if want.call("hint_folk"):
		# the six working villagers (v0.0.35): first lines, the last beat with its gift, a hint that follows an unfinished
		# side quest and a different one on the next talk, and at night three to a house with E waking one
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.1)
		var keep := {"met": main.met.duplicate(), "seen": main.hf_seen.duplicate(true), "turn": main.hf_turn.duplicate(),
			"garden_q": main.garden_q, "pots": main.player.pots, "gold": main.player.gold, "bait": main.has_bait,
			"medal": main.has_medal, "magpie": main.magpie_q, "hour": main.hour, "fest": main.mail_got[1]}
		main.in_village = true
		main.in_house = -1
		main.in_lake = false
		main.in_forest = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		main.hour = 12.0
		var said := func() -> String:
			var s: String = main.ui.story_who.text + ": " + plain(main.ui.story_text.text)
			main.close_story()
			return s
		# first meeting
		main.met.erase("yeoul")
		main.hf_seen.erase("yeoul")
		reset_to(main.village.folk_pos.yeoul + Vector2(1.0, 0))
		main.crown_key()
		var first: String = said.call()
		var first_ok: bool = first.contains("여울이야") and main.met.has("yeoul")
		# the ending beat gives the bait pouch; Chadol's gives 30 gold
		main.hf_seen["yeoul"] = [0, 1]
		main.has_bait = false
		main.garden_q = 5
		main.crown_key()
		var bait_said: String = plain(main.ui.story_text.text)
		var bait_ok: bool = main.has_bait and main.story_lines.back() == STORY.HF_GIFT.bait and bait_said.contains("그물이 부드러워졌어")
		main.close_story()
		main.met["chadol"] = true
		main.hf_seen["chadol"] = [0, 1]
		var g0: int = main.player.gold
		reset_to(main.village.folk_pos.chadol + Vector2(-1.0, 0))
		main.crown_key()
		main.close_story()
		var gold_ok: bool = main.player.gold == g0 + 30 and main.hf_seen.chadol.has(2)
		main.garden_q = keep.garden_q
		# hints: the target is won, so Darae points at the magpie first, then at another unfinished one
		main.met["darae"] = true
		main.hf_seen["darae"] = [0, 1, 2]
		main.hf_turn.erase("darae")
		main.has_medal = true
		main.magpie_q = 0
		reset_to(main.village.folk_pos.darae + Vector2(0, 1.0))
		main.crown_key()
		var hint1: String = said.call()
		main.crown_key()
		var hint2: String = said.call()
		var hint_ok: bool = hint1.contains("반짝이 도둑") and hint2 != hint1 and not hint2.contains("과녁")
		main.has_medal = keep.medal
		main.magpie_q = keep.magpie
		# night: everyone goes in, no two on one spot, Darae and Tori share a house with a third, E wakes Tori
		var m1: bool = main.mail_got[1]
		main.mail_got[1] = false
		main.sleep_off = false
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		reset_to(main.village.marks.M + Vector2(0, 2))
		main.hour = 23.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		var all_in: bool = main.SLEEP_IDS.all(func(id): return id == "mulgyeol" and not main.folk_awake_here(id) or main.folk_state.get(id, "") == "in")
		var spots := {}
		for id in main.SLEEP_IDS + ["kid"]:
			spots[str(main.folk_bed(id))] = true
		var no_overlap: bool = spots.size() == main.SLEEP_IDS.size() + 1
		var home: int = main.folk_home("tori")
		var mates: Array = main.SLEEP_IDS.filter(func(id): return main.folk_home(id) == home)
		main.enter_house(home)
		main.update_folk_sleep(0.0)
		var shown: Array = mates.filter(func(id): return main.sleeper_nodes[id].visible)
		var shared: bool = main.folk_home("darae") == home and mates.size() == 3 and shown.size() == 3
		reset_to(main.bed_spot("tori") + Vector2(0.9, 0))
		main.crown_key()
		var woke: String = said.call()
		var wakes: bool = woke.begins_with("토리")
		main.leave_house()
		main.hour = 12.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		var out: bool = main.folk_state.tori == "out" and main.village.folk_node.tori.visible
		main.sleep_off = true
		main.mail_got[1] = m1
		main.hour = keep.hour
		main.met = keep.met
		main.hf_seen = keep.seen
		main.hf_turn = keep.turn
		main.player.pots = keep.pots
		main.player.gold = keep.gold
		main.has_bait = keep.bait
		main.in_village = false
		check("hint_folk", first_ok and bait_ok and gold_ok and hint_ok and all_in and no_overlap and shared and wakes and out,
			"first=%s bait gift=%s gold gift=%s hints=%s / %s all in=%s no overlap=%s shared house %d=%s E wakes Tori=%s (%s) out by day=%s" % [first_ok, bait_ok, gold_ok, hint1.left(24), hint2.left(24), all_in, no_overlap, home, mates, wakes, woke.left(20), out])
	if want.call("race"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		main.close_story()
		main.in_village = false
		main.in_hill = true
		main.hill_q = maxi(main.hill_q, 1)
		main.has_shoes = false
		main.race_best = 0.0
		calm_enemies(true)
		await wait(0.2)
		main.close_story()
		var hx: float = main.HILL.HILL_X
		var spots := true
		for p in main.RACE_WHEELS + [main.RACE_POST + Vector2(1, 0)]:
			spots = spots and main.walkable(hx + p.x, p.y)
		reset_to(Vector2(hx + main.RACE_POST.x + 1.0, main.RACE_POST.y))
		tap(KEY_E)
		await wait(0.1)
		var started: bool = main.race_on
		for p in main.RACE_WHEELS:
			reset_to(Vector2(hx + p.x, p.y))
			await wait(0.1)
		await wait(0.2)
		main.close_story()
		var won: bool = not main.race_on and main.has_shoes and main.race_best > 0.0
		reset_to(Vector2(hx + main.RACE_POST.x + 1.0, main.RACE_POST.y))
		tap(KEY_E)
		await wait(0.1)
		main.race_left = 0.05
		await wait(0.2)
		var timed_out: bool = not main.race_on
		main.in_hill = false
		calm_enemies(false)
		check("race", spots and started and won and timed_out, "spots walkable=%s started=%s won shoes=%s (best %.1f s) runs out of time=%s" % [spots, started, won, main.race_best, timed_out])
	if want.call("vault"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = true
		main.has_armour = false
		var cx: float = main.CASTLE.CASTLE_X
		var shut: bool = not main.player_can(cx + 22, 23)
		for i in [0, 1, 2]: # all three: gates 1 and 3 open, gate 2 flipped twice
			reset_to(main.castle.levers[i].pos + Vector2(0, 1.0))
			tap(KEY_E)
			await wait(0.1)
		var wrong: bool = not main.castle.vault_solved()
		reset_to(main.castle.levers[1].pos + Vector2(0, 1.0))
		tap(KEY_E) # back off the middle lever: levers 1 and 3 alone open everything
		await wait(0.1)
		var solved: bool = main.castle.vault_solved() and main.player_can(cx + 22, 23)
		reset_to(Vector2(cx + 27, 23))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var hp0: float = main.player.hp
		main.player.inv = 0.0
		main.hurt_player(20, 0.0)
		var want_hit: float = float(maxi(1, int(round(round(20 * main.sora.FOE_DMG_K) * 0.85))))
		var less: bool = main.has_armour and absf((hp0 - main.player.hp) - want_hit) < 0.01
		main.player.hp = float(main.player.max_hp)
		main.in_hill = false
		check("vault", shut and wrong and solved and less, "gates shut=%s all three levers wrong=%s levers 1+3 open=%s armour takes 20 as %d=%s" % [shut, wrong, solved, int(want_hit), less])
	if want.call("save_tonight"):
		main.in_village = false
		main.in_forest = false
		main.in_hill = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		reset_to(Vector2(20, 30))
		main.marsh.found = [true, true, true]
		main.marsh.chest_open = true
		main.fly_q = 3
		main.has_pearl = true
		main.grotto_q = 4
		main.cloud_q = 3
		main.has_feather = true
		main.woke = [false, true, false]
		main.crystal_done = true
		main.has_ring = true
		main.trial_best = 77.0
		main.race_best = 12.5
		main.has_shoes = true
		main.forest.freed = [true, true, true, true, true]
		main.has_acorn = true
		main.has_armour = true
		main.castle_q = 3
		main.save_game()
		for k in ["has_pearl", "has_feather", "has_ring", "has_shoes", "has_acorn", "has_armour", "crystal_done"]:
			main.set(k, false)
		main.fly_q = 0
		main.grotto_q = 0
		main.cloud_q = 0
		main.woke = [false, false, false]
		main.trial_best = 0.0
		main.race_best = 0.0
		main.castle_q = 0
		main.load_game()
		var ok: bool = main.has_pearl and main.has_feather and main.has_ring and main.has_shoes and main.has_acorn and main.has_armour 			and main.crystal_done and main.fly_q == 3 and main.grotto_q == 4 and main.cloud_q == 3 and main.woke == [false, true, false] 			and main.trial_best == 77.0 and main.race_best == 12.5 and main.castle_q == 3 and main.marsh.chest_open and main.forest.freed.count(true) == 5
		check("save_tonight", ok, "keepsakes, side stories and records survive save and load=%s" % ok)
	if want.call("fishing"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = true
		main.lake_q = maxi(main.lake_q, 2)
		main.fish_kinds = [false, false, false, false, false]
		reset_to(main.lake.marks.f)
		var reach: bool = main.walkable(main.lake.marks.f.x, main.lake.marks.f.y)
		calm_enemies(true) # once in a full run (cloud, 2026-10-25) the first cast did not happen: no foe, story, sheet or line left from before
		main.fish_state = ""
		if main.way_open:
			main.waystones.toggle_ways(false)
		await wait(0.1)
		main.close_story()
		var why := "story=%s down=%.1f ways=%s shop=%s settings=%s" % [main.story_open, main.down_t, main.way_open, main.shop_open, main.settings_open]
		# every step waits on the line's state, not on a fixed time: a slow frame on the cloud box used to let
		# the 0.7 s bite run out, or the cast land after fish_t was zeroed, and the fish roll is seeded
		main.rng.seed = 1984
		tap(KEY_E)
		var cast: bool = await wait_for(func(): return main.fish_state == "wait", 1.0)
		if not cast: # the first press is sometimes lost late in a full run (twice now); the casts below re-press too
			main.close_story()
			reset_to(main.lake.marks.f)
			tap(KEY_E)
			cast = await wait_for(func(): return main.fish_state == "wait", 1.0)
		tap(KEY_E) # too early
		var early: bool = await wait_for(func(): return main.fish_state == "", 1.0)
		var landed := 0
		for i in 40:
			if main.fish_kinds.count(true) == 5:
				break
			reset_to(main.lake.marks.f)
			tap(KEY_E)
			if not await wait_for(func(): return main.fish_state == "wait", 1.0):
				main.close_story()
				continue
			main.fish_t = 0.0
			if await wait_for(func(): return main.fish_state == "bite", 1.0):
				main.fish_t = 60.0 # the bite holds until the pull is read
				var g0: int = main.player.gold
				tap(KEY_E)
				if await wait_for(func(): return main.fish_state == "" and main.player.gold > g0, 1.0):
					landed += 1
			main.close_story()
		main.in_lake = false
		check("fishing", reach and cast and early and landed > 0, "spot reachable=%s cast=%s early pull loses it=%s landed=%d kinds=%d%s" % [reach, cast, early, landed, main.fish_kinds.count(true), "" if cast else " (before the cast: %s)" % why])
	if want.call("bat"):
		var ok_spots := true
		for b in main.BAT_SPOTS:
			ok_spots = ok_spots and main.walkable(b.x, b.y)
		calm_enemies(true)
		park_mates(true) # their pokes keep it flinching: with its clocks ticking once a frame, it never got to swoop
		reset_to(Vector2(20, 30))
		main.spawn_bat(Vector2(23, 30))
		var b0: Dictionary = main.enemies[main.enemies.size() - 1]
		b0.hp = 99999.0
		b0.atk_cd = 1.0
		var swooped := false
		var hurt_seen := 0.0
		var hp0: float = main.player.hp
		var top := 0.0 # the highest seen: a swoop brings it low, so one last sample can land on the ground
		for i in 50:
			reset_to(Vector2(20, 30))
			main.player.hp = hp0
			await wait(0.1)
			if b0.dash > 0.0:
				swooped = true
			hurt_seen = maxf(hurt_seen, b0.hurt)
			top = maxf(top, b0.node.position.y)
		var flies: bool = top > 0.5
		if not b0.dead:
			b0.dead = true
			b0.node.queue_free()
			b0.shadow.queue_free()
		calm_enemies(false)
		park_mates(false)
		check("bat", ok_spots and swooped and flies, "spots open=%s swoops=%s flies above ground=%s (flinched=%s)" % [ok_spots, swooped, flies, hurt_seen > 0.0])
	if want.call("moonflowers"):
		main.story_step = maxi(main.story_step, 6)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_cave = false
		main.in_garden = false
		main.marsh.picked = [false, false, false]
		main.has_tea = false
		calm_enemies(true)
		var spots := true
		for p in main.MARSH.FLOWERS:
			spots = spots and main.player_can(p.x, p.y)
		main.hour = 22.0
		main.day = 0 # new moon: closed
		await wait(0.2)
		var shut: bool = not main.marsh.flowers[0].visible
		main.day = 4 # full moon
		await wait(0.2)
		var open_: bool = main.marsh.flowers[0].visible
		for p in main.MARSH.FLOWERS:
			reset_to(p)
			await wait(0.15)
			main.close_story() # the first flower explains itself
		var three: bool = main.marsh.picked_count() == 3
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		tap(KEY_SPACE)
		await wait(0.2)
		main.close_story()
		if main.shop_open:
			main.toggle_shop(false)
		main.hour = 12.0
		calm_enemies(false)
		check("moonflowers", spots and shut and open_ and three and main.has_tea, "spots=%s closed at new moon=%s open at full moon=%s picked 3=%s tea=%s" % [spots, shut, open_, three, main.has_tea])
	if want.call("houses"):
		main.story_step = maxi(main.story_step, 8)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = true
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.house_seen = [false, false, false, false, false]
		calm_enemies(true)
		var doors_ok: bool = main.village.doors.size() == 5
		for d in main.village.doors:
			doors_ok = doors_ok and main.walkable(d.x, d.y)
		reset_to(main.village.doors[4])
		tap(KEY_SPACE)
		await wait(1.0)
		var inside: bool = main.in_house == 4 and main.player.x >= main.HOUSE_X
		reset_to(Vector2(main.cupboard.position.x, main.cupboard.position.z + 1.0))
		tap(KEY_SPACE)
		await wait(0.2)
		var picture: bool = main.story_open and main.house_seen[4] and main.story.small_pic and main.ui.story_frame.visible # the small corner picture
		main.close_story()
		reset_to(Vector2(main.HOUSE_X + 4, 6))
		await wait(1.0)
		var out: bool = main.in_house == -1 and main.player.x >= main.VILLAGE.VILLAGE_X - 0.5 and main.in_village
		calm_enemies(false)
		check("houses", doors_ok and inside and picture and out, "5 doors reachable=%s went in=%s picture in the last house=%s came out=%s" % [doors_ok, inside, picture, out])
	if want.call("one_key"):
		# v0.0.48: E is the one action key (the user: "동일성 있게 해줘"): it enters a house, leaves it, opens a field
		# chest and a cupboard, still talks to Bori (her shop), and by a villager standing at a door it talks rather than
		# enters; Space still works but no shown help or touch text names it
		main.story_step = maxi(main.story_step, 8)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		calm_enemies(true)
		main.hour = 12.0
		main.in_village = true
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		var seen0: Array = main.house_seen.duplicate()
		main.house_seen = [false, false, false, false, false]
		reset_to(main.village.doors[2])
		tap(KEY_E)
		await wait(1.0)
		var e_in: bool = main.in_house == 2 and main.player.x >= main.HOUSE_X
		reset_to(Vector2(main.cupboard.position.x, main.cupboard.position.z + 1.0))
		var g0: int = main.player.gold
		var p0: int = main.player.pots
		tap(KEY_E)
		await wait(0.2)
		var e_cup: bool = main.house_seen[2] and main.player.gold == g0 and main.player.pots == p0 # looked, took nothing
		main.close_story()
		reset_to(main.HOUSE_EXIT + Vector2(0, -0.85)) # beside the doorway, not on it
		await wait(0.3)
		var stayed: bool = main.in_house == 2
		tap(KEY_E)
		await wait(1.0)
		var e_out: bool = stayed and main.in_house == -1 and main.in_village and main.player.x >= main.VILLAGE.VILLAGE_X - 0.5
		# Space still goes in (the old habit)
		reset_to(main.village.doors[2])
		tap(KEY_SPACE)
		await wait(1.0)
		var space_in: bool = main.in_house == 2
		reset_to(main.HOUSE_EXIT)
		await wait(1.0)
		# a villager standing at a door: E talks to him, Sora stays outside
		var fid := ""
		for id in main.village.folk_pos:
			if main.folk_awake_here(id) and main.folk_state.get(id, "out") == "out" and not main.STORY.HINT_FOLK.has(id):
				fid = id
				break
		var talked := false
		if fid != "":
			var d: Vector2 = main.village.doors[3]
			var pos0: Vector2 = main.village.folk_pos[fid]
			var route0 = main.folk_route[fid].pos if main.folk_route.has(fid) else null
			main.village.folk_pos[fid] = d + Vector2(0.6, 0)
			if main.folk_route.has(fid):
				main.folk_route[fid].pos = d + Vector2(0.6, 0)
			reset_to(d)
			main.crown_key()
			await wait(1.0)
			talked = main.in_house == -1 and main.story_open
			main.close_story()
			await wait(0.2)
			main.close_story()
			main.village.folk_pos[fid] = pos0
			if route0 != null:
				main.folk_route[fid].pos = route0
		main.house_seen = seen0
		main.player.gold = g0
		main.player.pots = p0
		# a field chest on the marsh
		main.in_village = false
		var c: Dictionary = main.chests[0]
		var open0: bool = c.open
		c.open = false
		reset_to(Vector2(c.x + 0.6, c.z))
		var gc: int = main.player.gold
		tap(KEY_E)
		await wait(0.2)
		var e_chest: bool = c.open and main.player.gold > gc
		c.open = open0
		main.player.gold = gc
		# Bori still answers to E (nothing else waiting: her shop)
		var tea0: bool = main.has_tea
		var dq0: int = main.doran_q
		var mq0: int = main.mail_q
		main.has_tea = true
		main.doran_q = maxi(3, main.doran_q)
		main.mail_q = maxi(2, main.mail_q)
		main.story_step = maxi(main.story_step, 3)
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.crown_key()
		await wait(0.2)
		var bori: bool = main.shop_open
		main.toggle_shop(false)
		main.has_tea = tea0
		main.doran_q = dq0
		main.mail_q = mq0
		# no help row, shop line or touch key names Space or the hand key any more
		var texts: Array = [main.ui.shop_keys.text]
		for r in main.ui.help_keys_rows + main.ui.help_touch_rows + main.ui.set_help_keys + main.ui.set_help_touch:
			texts.append((r[0] as Label).text)
			texts.append((r[1] as Label).text)
		main.touch_ui = true
		texts.append(main.touch_words("상자 앞에서 Space를 누르자"))
		texts.append(main.touch_words(String(main.STORY.HINT_FOLK.tori.hints.cupboards[1])))
		main.touch_ui = false
		var quiet := true
		for tx in texts:
			quiet = quiet and not "Space" in String(tx) and not "손 단추" in String(tx) and not "손 (" in String(tx)
		var no_hand: bool = not main.touch_layer.keys().has("open") if main.touch_layer != null else true
		calm_enemies(false)
		check("one_key", e_in and e_cup and e_out and space_in and talked and e_chest and bori and quiet and no_hand,
			"E enters=%s E opens the cupboard=%s E leaves at the door=%s Space still enters=%s E by %s at a door talks=%s E opens a field chest=%s E by Bori opens the shop=%s no Space in shown texts=%s no hand key=%s" % [e_in, e_cup, e_out, space_in, fid, talked, e_chest, bori, quiet, no_hand])
	if want.call("feats"):
		main.feats_done = [false, false, false, false, false, false]
		var g0: int = main.player.gold
		main.stats.crits = 49
		main.player.inv = 0.0
		calm_enemies(true)
		reset_to(Vector2(20, 30))
		main.spawn_enemy(Vector2(21, 30))
		var e: Dictionary = main.enemies[main.enemies.size() - 1]
		var k0: int = main.stats.kills
		main.damage_enemy(e, 99999.0, Vector2(20, 30), 4.0, true)
		main.stats.crits = maxi(main.stats.crits, 50)
		main.check_feats()
		var done: bool = main.feats_done[2] and main.stats.kills == k0 + 1 and main.player.gold >= g0 + 50
		var listed: bool = "도전 과제" in "\n".join(main.journal_lines())
		calm_enemies(false)
		check("feats", done and listed, "crit feat at 50=%s kill counted, journal lists feats=%s" % [done, listed])
	if want.call("mail"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.doran_q = 3
		main.kid_q = 3
		main.lake_q = 4
		main.mail_q = 0
		main.mail_got = [false, false, false]
		main.met["doran"] = true
		calm_enemies(true)
		main.in_village = true
		main.in_lake = false
		var dp: Vector2 = main.village.folk_pos.doran
		reset_to(dp + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var asked: bool = main.mail_q == 1
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		tap(KEY_SPACE)
		await wait(0.2)
		main.close_story()
		if main.shop_open:
			main.toggle_shop(false)
		main.in_lake = true
		reset_to(main.lake.marks.h + Vector2(0, 1.2))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var all3: bool = main.mail_got.count(true) == 3
		main.in_lake = false
		main.in_village = true
		var hp0: int = main.player.max_hp
		reset_to(dp + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var paid: bool = main.mail_q == 2 and main.player.max_hp == hp0 + 10
		main.in_village = false
		calm_enemies(false)
		check("mail", asked and all3 and paid, "asked=%s delivered=%s paid=%s" % [asked, main.mail_got, paid])
	if want.call("festival"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.mail_got = [true, true, true]
		main.fest_gift = false
		main.errand = 3
		main.in_village = true
		main.in_house = -1
		calm_enemies(true)
		main.hour = 22.0
		main.day = 1 # a thin moon: no festival
		await wait(0.2)
		var quiet: bool = not main.festival_now()
		main.day = 4
		await wait(1.2)
		var on: bool = main.festival_now()
		var p0: int = main.player.pots
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var gift: bool = main.fest_gift and main.player.pots == p0 + 3
		main.hour = 12.0
		main.in_village = false
		calm_enemies(false)
		check("festival", quiet and on and gift, "no festival on a thin moon=%s full moon festival=%s rice cakes=%s" % [quiet, on, gift])
	if want.call("new_round"):
		var said: bool = "1.5배" in main.new_round_lines()[2] # round 0 -> 1
		main.ng = 1
		said = said and "2배" in main.new_round_lines()[2] and not "1.5" in main.new_round_lines()[2] # round 1 -> 2
		var m: float = main.ng_mult()
		calm_enemies(true)
		reset_to(Vector2(20, 30))
		main.spawn_enemy(Vector2(21, 30))
		var e: Dictionary = main.enemies[main.enemies.size() - 1]
		e.hp = 1000.0
		main.damage_enemy(e, 100.0, Vector2(20, 30), 0.0, true)
		var tougher: bool = e.hp > 1000.0 - 100.0 / m * 1.2 and e.hp < 1000.0 - 100.0 / m * 0.8
		main.player.hp = 100.0
		main.player.inv = 0.0
		var armour: bool = main.has_armour
		main.has_armour = false
		main.hurt_player(10, 0.0)
		var harder: bool = absf(main.player.hp - (100.0 - round(10 * main.sora.FOE_DMG_K * m))) < 0.01
		main.has_armour = armour
		main.player.hp = float(main.player.max_hp)
		main.ng = 0
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
		calm_enemies(false)
		main.has_pearl = true
		main.woke = [false, false, true]
		var lv0: int = main.player.lv
		main.write_new_round()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = int(sd.get("story", -1)) == 0 and int(sd.get("ng", 0)) == 1 and int(sd.get("lv", 0)) == lv0 			and bool(sd.get("has_pearl", false)) and sd.get("woke", []) == [false, false, true] and not sd.has("lake_q") and not sd.has("chests")
		check("new_round", tougher and harder and kept and said, "round 1: monsters take 1/1.5 damage=%s and deal 1.5x=%s, new-round save keeps level and keepsakes only=%s, notice says 1.5x then 2x=%s" % [tougher, harder, kept, said])
	if want.call("shop_price"):
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.shop_bought = [0, 0, 0, 0]
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.story_step = maxi(main.story_step, 3)
		main.player.gold = 300
		main.toggle_shop(true)
		await wait(0.1)
		main.buy(2)
		main.buy(2)
		var paid: bool = main.player.gold == 300 - 80 - 120 and main.shop_bought[2] == 2 and "160" in main.ui.shop_btns[2].text
		main.toggle_shop(false)
		check("shop_price", paid, "two blades cost 80 then 120, next shows 160=%s (gold %d)" % [paid, main.player.gold])
	if want.call("cloud_path"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = true
		main.cloud_q = maxi(main.cloud_q, 1)
		main.has_shard = false
		calm_enemies(true)
		var cx: float = main.CLOUD.CLOUD_X
		reset_to(Vector2(cx + 2, 12.0))
		tap(KEY_E)
		await wait(0.1)
		var shown: bool = main.cloud.path_nodes[0].visible
		reset_to(Vector2(cx + 3, 13.0)) # off the path
		await wait(0.2)
		var fell: bool = main.player.z < 12.0
		var walked := true
		for w in main.cloud.path_tiles:
			walked = walked and main.walkable(w.x, w.y)
		reset_to(main.cloud.marks.q + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		main.player.cds[1] = 0.0
		main.player.mp = 100.0
		tap(KEY_I)
		await wait(0.05)
		var faster: bool = main.has_shard and main.player.cds[1] < main.SKILL_CD[1] * 0.85
		main.in_hill = false
		calm_enemies(false)
		check("cloud_path", shown and fell and walked and faster, "E shows the path=%s step off falls back=%s path walkable=%s shard cuts cooldowns=%s" % [shown, fell, walked, faster])
	if want.call("waystones"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.lake_q = maxi(main.lake_q, 1)
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		calm_enemies(true)
		var ok_spots := true
		for i in main.WAY_NAMES.size():
			if i == 7: # the deep workshop: one stone per floor, checked below
				continue
			var w: Vector2 = main.way_spot(i) + Vector2(0, 1.2)
			ok_spots = ok_spots and main.walkable(w.x, w.y)
		for fw in main.wfloors:
			var wy: Vector2 = fw.marks.Y + Vector2(0, 1.2)
			ok_spots = ok_spots and main.walkable(wy.x, wy.y)
		var w0: Vector2 = main.way_spot(0)
		reset_to(w0 + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.1)
		var opened: bool = main.way_open and main.ui.ways.visible and main.WAY_NAMES.size() == 10 and "0   " in main.ui.ways_text.text
		tap(KEY_3)
		await wait(1.2)
		var at_lake: bool = main.in_lake and Vector2(main.player.x, main.player.z).distance_to(main.way_spot(2)) < 2.0
		reset_to(main.way_spot(2) + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.1)
		tap(KEY_1)
		await wait(1.2)
		var home: bool = not main.in_lake and main.in_marsh() and Vector2(main.player.x, main.player.z).distance_to(main.way_spot(0)) < 2.0
		calm_enemies(false)
		check("waystones", ok_spots and opened and at_lake and home, "stones reachable=%s list opens=%s marsh -> lake=%s lake -> marsh=%s" % [ok_spots, opened, at_lake, home])
	if want.call("stuck_fixes"):
		# an old save: garden reached, castle never seen; leaving the garden must open the way west
		main.castle.door_open = false
		main.castle.door.visible = true
		main.in_village = false
		main.in_hill = false
		main.in_garden = true
		main.leave_garden()
		var west: bool = main.castle.door_open and main.player_can(main.CASTLE.CASTLE_X + 31, 13)
		# F8 inside the castle: every zone flag goes, so the marsh works again
		main.return_to_start()
		var marsh_ok: bool = main.in_marsh() and not main.in_hill and main.in_house == -1
		# a save made on the island mid-turtle-fight loads at the pier
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		var isl: Vector2 = main.lake.marks.T + Vector2(2, 0)
		f.store_string(JSON.stringify({"story": 10, "night_q": 4, "lake_q": 3, "in_lake": true, "x": isl.x, "z": isl.y, "quest": "섬의 벽돌 거북을 물리치자"}))
		f.close()
		main.load_game()
		var pier: bool = main.lake_q == 2 and Vector2(main.player.x, main.player.z).distance_to(main.lake.marks.P) < 2.0 \
			and plain(main.ui.quest.text) == main.tr("부두의 물결에게 말을 걸자 (E)") # not the island fight
		main.return_to_start()
		check("stuck_fixes", west and marsh_ok and pier, "old save leaves the garden westward=%s F8 clears zones=%s turtle-fight save loads at the pier=%s" % [west, marsh_ok, pier])
	if want.call("story_fixes"):
		# GPT's fourth playtest (whole story): the state before is saved and loaded back at the end
		calm_enemies(true)
		main.save_game()
		var before: String = FileAccess.get_file_as_string(main.SAVE_PATH)
		var cfg_text: int = int(main.cfg.text)
		# 1. saved during the last winding lines: the load plays the ending and pays once
		var g: Vector2 = main.garden.marks.C + Vector2(-2.0, 0)
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify({"story": 11, "garden_q": 5, "in_garden": true, "x": g.x, "z": g.y, "gold": 100, "quest": "왕관을 높이 들어 마지막으로 감자 (E)"}))
		f.close()
		main.load_game()
		var ending: bool = main.story_open and main.story_step == 12 and main.player.gold == 600 and main.clock_q >= 1 and not main.ending_due
		main.close_story()
		await wait(0.3)
		main.load_game() # the save the ending wrote: nothing paid again
		var once: bool = main.player.gold == 600 and main.story_step == 12 and not main.story_open
		main.return_to_start()
		# 2. a later cave visit saved inside: the quest from before comes back on the way out
		var q := "물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"
		main.story_step = 10
		main.cave_exit_seen = true
		main.set_quest(q)
		main.enter_cave()
		main.save_game()
		main.quest_before_cave = "" # a fresh start knows nothing but the save
		main.load_game()
		main.leave_cave()
		var cave_q: bool = plain(main.ui.quest.text) == main.tr(q)
		main.enter_cave()
		main.quest_before_cave = "" # an older save without it: the main road's step instead
		var road0 := [main.forest_q, main.hill_q, main.castle_q, main.garden_q]
		main.forest_q = 3
		main.hill_q = 0
		main.castle_q = 0
		main.garden_q = 0
		var tk1: Array = main.tokens.duplicate()
		main.tokens[3] = true # the squirrels token, or the line names the cages (v0.1.62)
		main.hollow_q = 3 # and the south valley (v0.1.68)
		main.leave_cave()
		main.tokens = tk1
		main.hollow_q = 0
		cave_q = cave_q and plain(main.ui.quest.text) == main.tr("숲 동쪽 끝 길로, 바람 언덕에 가자")
		main.forest_q = road0[0]
		main.hill_q = road0[1]
		main.castle_q = road0[2]
		main.garden_q = road0[3]
		main.return_to_start()
		# 11. every story line stays inside the box at 720x540 with the biggest text, the box inside the screen
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(720, 540)
		main.cfg.text = main.TEXT_SIZES.size() - 1
		main.apply_settings()
		await wait(0.2)
		var lines: Array = []
		var consts: Dictionary = main.STORY.get_script_constant_map()
		for k in consts:
			var v = consts[k]
			if v is String and v.count("|") >= 2:
				lines.append(v)
			var lists: Array = v.values() if v is Dictionary else [v]
			for arr in lists:
				if arr is Array:
					for l in arr:
						if l is String and l.count("|") >= 2:
							lines.append(l)
		lines.append_array(main.new_round_lines())
		var over := 0
		var grew := 0
		var worst := ""
		for path in ["res://art/story/01_wake.jpg", ""]: # with a face beside the text (narrowest) and in talk scenes
			main.show_story(path, ["||"])
			for l in lines:
				main.show_line(l)
				main.fit_story()
				var box_h: float = main.ui.story_cap.offset_bottom - main.ui.story_cap.offset_top
				var cap_r: Rect2 = main.ui.story_cap.get_global_rect()
				var bottom: float = main.ui.story_text.position.y + main.ui.story_text.get_minimum_size().y
				if box_h > main.STORY_BOX_H:
					grew += 1
				if bottom > box_h - 8.0 or cap_r.position.y < 0.0 or cap_r.end.y > 540.5:
					over += 1
					worst = l
		var nr: Array = main.new_round_lines()
		var pages: bool = nr.size() == 4 and not "배" in nr[1] and "배" in nr[2]
		main.close_story()
		main.cfg.text = cfg_text
		main.apply_settings()
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		await wait(0.6)
		main.show_line("||")
		main.fit_story()
		var box_back: bool = main.ui.story_cap.offset_bottom - main.ui.story_cap.offset_top == main.STORY_BOX_H
		# put the state from before back
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(before)
		f.close()
		main.load_game()
		if main.story_open:
			main.close_story()
		calm_enemies(false)
		check("story_fixes", ending and once and cave_q and over == 0 and pages and box_back,
			"winding-lines save plays the ending on load, +500 gold, step 12=%s paid once=%s cave quest back after a reload=%s lines over the box at 720x540 biggest text=%d of %d (%d grew the box)%s new-round notice on two pages=%s box back to 144=%s"
			% [ending, once, cave_q, over, lines.size() * 2, grew, (" worst: " + worst.left(40)) if over > 0 else "", pages, box_back])
	if want.call("bracelet"):
		# v0.0.45 story change (the user's choice): Sora keeps the crown on her head and the sleeve cuffs are the winding
		# bracelets. No story line may still have her hold the crown in her hands, and on phones and tablets no hint may
		# show a bare E key (the user saw "E  보리 할머니의 상점" on an Android tablet)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var all_text: Array = []
		var walk := func(v, me: Callable) -> void:
			if v is String:
				all_text.append(v)
			elif v is Array:
				for x in v:
					me.call(x, me)
			elif v is Dictionary:
				for x in v.values():
					me.call(x, me)
		var consts: Dictionary = main.STORY.get_script_constant_map()
		for k in consts:
			walk.call(consts[k], walk)
		var held: Array = []
		for s in all_text:
			for bad in ["왕관을 쥐", "손에 쥐는", "쥐는 거", "두 손으로 쥐", "왕관을 들", "왕관을 두 손", "쥐고 있던 왕관", "왕관을 받쳐"]:
				if bad in String(s):
					held.append(String(s).left(30))
		var bare_e := RegEx.create_from_string("(?<![A-Za-z])E(?![A-Za-z])")
		var touch0: bool = main.touch_ui
		var q0: String = plain(main.ui.quest.text)
		main.touch_ui = true
		var shown: Array = []
		await wait(0.15) # the shop hint is rewritten every frame
		shown.append(main.ui.shop_hint.text)
		var dq: int = main.doran_q
		main.doran_q = 2
		await wait(0.15)
		shown.append(main.ui.shop_hint.text)
		main.doran_q = dq
		for q in ["팔목의 팔찌를 만져 보자 (E)", "도란의 편지에 팔찌를 대 보자 (E, 달빛 눈금 사용)", "이야기 끝 · 정원 한가운데 구멍으로 내려가 시계방에 가 보자", "깊은 틈 위 한결의 발자국을 따라가자 (E로 비추기)"]:
			main.set_quest(q)
			shown.append(plain(main.ui.quest.text))
		shown.append(main.touch_words(main.tr("낚싯줄을 던졌다. 찌가 흔들리면 E!")))
		shown.append(main.touch_words(main.tr("태엽이 튕겨 나왔다. 문지기 곁에서 E")))
		for s in all_text: # every story line as show_line words it
			if String(s).count("|") >= 2:
				shown.append(main.touch_words(main.tr(String(s).split("|", true, 2)[2])))
		main.toggle_journal(true)
		shown.append(plain(main.ui.journal_text.text))
		main.toggle_journal(false)
		var bare: Array = []
		for s in shown:
			if bare_e.search(String(s)) != null:
				bare.append(String(s).left(30))
		var tablet_shop: bool = "팔찌 단추" in String(shown[0]) and "팔찌 단추" in String(shown[1])
		main.touch_ui = touch0
		main.set_quest(q0)
		# an old save's quest still in the old words reads with the bracelet
		var old_q: String = main.old_quest_words("동쪽 끝 꺼진 등불을 왕관으로 켜자 (E) 1/3")
		var old_ok: bool = old_q == "동쪽 끝 꺼진 등불을 팔찌로 켜자 (E) 1/3" and main.old_quest_words("왕관을 높이 들어 다 같이 땅을 감자 (E)").begins_with("두 팔을")
		check("bracelet", held.is_empty() and bare.is_empty() and tablet_shop and old_ok,
			"story lines with the crown held in hand=%d %s; touch texts with a bare E=%d %s; shop hint on a tablet=%s; old save quest words=%s (%d story strings looked at)"
			% [held.size(), held, bare.size(), bare, shown.slice(0, 2), old_ok, all_text.size()])
	if want.call("playtest5"):
		# GPT's fifth playtest (main road): quest lines after the cave door, the village arrival save, the stairs top and
		# a day-loaded chase save; lines that must fit what Sora knows and holds. The state before comes back at the end.
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		calm_enemies(true)
		main.save_game()
		var before: String = FileAccess.get_file_as_string(main.SAVE_PATH)
		# 1. the cave door opens: the quest points on to the cart-mole's room
		var keep := [main.has_key, main.cave_door_open, main.has_skip, null, main.story_step]
		if is_instance_valid(main.door_node): # an earlier test may have opened (and freed) the real door
			keep[3] = main.door_node
		main.door_node = Node3D.new() # a stand-in, so the real door (open or shut) is untouched
		main.add_child(main.door_node)
		main.has_key = true
		main.cave_door_open = false
		main.has_skip = false
		main.set_quest("열쇠를 찾아 잠긴 문을 열자")
		reset_to(main.cave_marks.D + Vector2(0.8, 0))
		main.cave_interact()
		var door_q: bool = main.cave_door_open and plain(main.ui.quest.text) == main.tr(main.CAVE_DOOR_QUEST)
		main.has_key = keep[0]
		main.cave_door_open = keep[1]
		main.has_skip = keep[2]
		if keep[3] != null:
			main.door_node = keep[3]
		main.story_step = keep[4]
		main.return_to_start()
		# 2. the save made on reaching the village loads with Simji's quest, and so does an older one with the river line
		var e0: int = main.errand
		main.errand = 0
		main.story_step = maxi(main.story_step, 7)
		main.set_quest("동쪽 강을 물수제비 걸음으로 건너, 마을 불빛을 찾아라")
		main.enter_village()
		main.close_story()
		main.set_quest("") # a fresh start knows nothing but the save
		main.load_game()
		var arrive_q: bool = main.in_village and plain(main.ui.quest.text) == main.tr(main.SIMJI_QUEST)
		main.return_to_start()
		var m: Vector2 = main.village.marks.M
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify({"story": 8, "errand": 0, "in_village": true, "has_skip": true, "x": m.x - 3.0, "z": m.y, "quest": "동쪽 강을 물수제비 걸음으로 건너, 마을 불빛을 찾아라"}))
		f.close()
		main.load_game()
		arrive_q = arrive_q and plain(main.ui.quest.text) == main.tr(main.SIMJI_QUEST)
		main.return_to_start()
		main.errand = e0
		# 7. a chase save loaded by day: no Noeul to chase, so the quest says to rest in the village till night
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify({"story": 9, "errand": 3, "kid_q": 3, "doran_q": 3, "mul_q": 3, "night_q": 1, "in_village": true, "has_skip": true,
			"hour": 12.0, "x": m.x + 4.0, "z": m.y + 1.0, "quest": "등불을 끈 노을을 쫓자 (Shift로 달리기)"}))
		f.close()
		main.load_game()
		await wait(0.4)
		var chase_q: bool = main.night_q == 0 and not main.is_night() and plain(main.ui.quest.text) == main.tr(main.NIGHT_REST_QUEST)
		main.return_to_start()
		# 6. the postcard: after Bori's letter (doran_q 3) Sora knows who Hangyeol was
		var dq0: int = main.doran_q
		main.doran_q = 2
		var card_before: bool = "몰라도" in String(main.post_card_lines()[4])
		main.doran_q = 3
		var card_after: bool = main.post_card_lines()[4] == main.STORY.POST_CARD_KNOWN and not "몰라도" in String(main.post_card_lines()[4])
		main.doran_q = dq0
		# 8. the brick Hangyeol: the house painting is recalled only if she opened it
		var hs0: bool = main.house_seen[4]
		main.house_seen[4] = false
		var echo_first: bool = main.road_echo_lines()[1] == main.STORY.ROAD_ECHO_FIRST
		main.house_seen[4] = true
		var echo_seen: bool = "그림" in String(main.road_echo_lines()[1])
		main.house_seen[4] = hs0
		# 5. Doran's thanks before the ending speak of letters; after it, of the garden
		main.mail_q = 1
		for i in main.mail_got.size():
			main.mail_got[i] = true
		main.garden_q = 0
		main.story_step = 10
		main.mail_errand()
		var mail_pre: bool = main.story_open and not "정원" in "".join(main.story_lines)
		main.close_story()
		main.mail_q = 1
		main.garden_q = 5
		main.story_step = 12
		main.mail_errand()
		var mail_end: bool = main.story_open and main.STORY.MAIL_DONE_WOUND in main.story_lines
		main.close_story()
		var fest: bool = not "정원" in String(main.STORY.FESTIVAL[1]) and "정원" in main.STORY.FESTIVAL_WOUND
		# put the state from before back
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(before)
		f.close()
		main.return_to_start()
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(before)
		f.close()
		main.load_game()
		if main.story_open:
			main.close_story()
		calm_enemies(false)
		check("playtest5", door_q and arrive_q and chase_q and card_before and card_after and echo_first and echo_seen and mail_pre and mail_end and fest,
			"cave door quest=%s village arrival save quest=%s day chase save quest=%s postcard before/after the letter=%s/%s road echo unseen/seen painting=%s/%s mail thanks before/after the ending=%s/%s festival=%s"
			% [door_q, arrive_q, chase_q, card_before, card_after, echo_first, echo_seen, mail_pre, mail_end, fest])
	if want.call("laps"):
		# GPT's story playtests, laps 2 -> 9 (shots/plans/laps2to9_findings.md): one check for each finding fixed.
		# The state before comes back at the end.
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		calm_enemies(true)
		main.save_game()
		var before: String = FileAccess.get_file_as_string(main.SAVE_PATH)
		var bad: Array = []
		var f: FileAccess
		# 1. no save while she lies fallen (hp 0); an older hp 0 save wakes healed
		main.player.hp = float(main.player.max_hp)
		main.save_game()
		main.down_t = 3.0
		main.player.hp = 0.0
		main.save_game()
		var sd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var hp_saved: float = float(sd.get("hp", 0.0))
		main.down_t = 0.0
		main.player.hp = float(main.player.max_hp)
		sd["hp"] = 0.0
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(sd))
		f.close()
		main.load_game()
		if main.story_open:
			main.close_story()
		if not (hp_saved > 0.0 and main.player.hp == float(main.player.max_hp)):
			bad.append("1 fallen save hp=%s, hp 0 save loads hp=%s" % [hp_saved, main.player.hp])
		main.return_to_start()
		# 2. Chadol's round keeps off the east gate, and stopped mid-leg for Sora he does not block her
		var gate: Vector2 = main.village.marks.F
		var pts: Array = main.FOLK_ROUTES["chadol"]
		var gate_near := 99.0
		for i in pts.size():
			var a: Vector2 = main.route_at("chadol", i)
			var b: Vector2 = main.route_at("chadol", (i + 1) % pts.size())
			for s in 11:
				gate_near = minf(gate_near, a.lerp(b, s / 10.0).distance_to(gate))
		main.routine_off = false
		var cr: Dictionary = main.folk_route_state("chadol")
		cr.i = 2
		cr.back = false
		var mid: Vector2 = main.route_at("chadol", 2) + Vector2(0, 5)
		cr.pos = mid
		main.player.x = mid.x
		main.player.z = mid.y - 0.5
		main.update_folk_sleep(0.05)
		var rock_r: float = float(main.folk_rocks["chadol"].r) if main.folk_rocks.has("chadol") else -1.0
		var waited: bool = (cr.pos as Vector2).distance_to(mid) < 0.01
		main.route_reset("chadol")
		main.routine_off = true
		main.update_folk_sleep(0.0)
		if not (gate_near >= 1.9 and rock_r == 0.0 and waited):
			bad.append("2 chadol gate distance=%.1f rock while waiting=%s waited=%s" % [gate_near, rock_r, waited])
		main.return_to_start()
		# 3. a save made mid-fight in the garden (garden_q 3) loads with the go-back-to-the-centre quest
		var gs: Vector2 = main.garden.marks.S
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify({"story": 11, "garden_q": 3, "road_q": 4, "in_garden": true, "has_skip": true, "errand": 4,
			"x": gs.x + 1.5, "z": gs.y, "quest": "마을 사람들이 등불을 켜는 동안 거푸집 조각을 막자 2/8"}))
		f.close()
		main.load_game()
		if main.story_open:
			main.close_story()
		if not (main.garden_q == 1 and plain(main.ui.quest.text) == main.tr(main.GARDEN_RETRY_QUEST)):
			bad.append("3 garden save quest=%s" % plain(main.ui.quest.text))
		main.return_to_start()
		# 4. the mill run: the save keeps the quest from before the run; an older save with the timer loads without it
		main.windrun_on = true
		main.windrun_quest = "언덕 동쪽 끝 길로, 달지기들의 성에 가자"
		main.set_quest(main.tr("바람 부르기 %d/4 · %d초") % [1, 9])
		main.save_game()
		var mq: String = String(JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH)).get("quest", ""))
		main.windrun_on = false
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify({"story": 10, "has_skip": true, "errand": 4, "quest": "바람 부르기 2/4 · 5초"})) # mill_q 0: a mill_q save would open the hill wall for good and spoil the mill test
		f.close()
		main.load_game()
		if main.story_open:
			main.close_story()
		if not (mq == main.windrun_quest and not plain(main.ui.quest.text).begins_with(main.windrun_prefix())):
			bad.append("4 mill saved quest=%s old save quest=%s" % [mq, plain(main.ui.quest.text)])
		main.return_to_start()
		# 5. the cave revisited from the village: a faint inside gives the quest back, an empty line never replaces it
		var st0: int = main.story_step
		main.story_step = maxi(main.story_step, 8)
		main.set_quest("콩알의 꼬마 고블린을 찾자")
		main.enter_cave()
		main.faint()
		var cave_back: bool = plain(main.ui.quest.text) == main.tr("콩알의 꼬마 고블린을 찾자")
		main.set_quest("")
		main.enter_cave()
		main.leave_cave()
		if main.story_open:
			main.close_story()
		cave_back = cave_back and plain(main.ui.quest.text) == main.tr("콩알의 꼬마 고블린을 찾자")
		if not cave_back:
			bad.append("5 cave quest after faint and re-entry=%s" % plain(main.ui.quest.text))
		main.return_to_start()
		# 6. beaten by the turtle: back in the village the quest says how to row out again; at the lake, talk at the pier
		main.in_village = false
		main.in_lake = true
		main.lake_q = 3
		main.faint()
		var lake_ok: bool = main.lake_q == 2 and plain(main.ui.quest.text) == main.tr(main.LAKE_RETRY_QUEST)
		main.enter_lake()
		if main.story_open:
			main.close_story()
		lake_ok = lake_ok and plain(main.ui.quest.text) == main.tr("부두의 물결에게 말을 걸자 (E)")
		if not lake_ok:
			bad.append("6 turtle faint quest=%s" % plain(main.ui.quest.text))
		main.return_to_start()
		# 7. the hedgehogs: a fight cut by a load comes back at the last knot, which waits until both are down
		var oak0: Array = [main.oak_q, main.oak_hogs_beaten, main.oak_hogs_up, main.crown_pips]
		main.in_village = false
		main.in_forest = true
		main.oak_q = 1
		main.oak_hogs_beaten = false
		main.oak_hogs_up = false
		main.forest.oak_look(true, [true, true, false], false)
		main.crown_pips = 8
		main.untie_knot(2)
		var hogs: int = main.oak_hogs_alive().size()
		var knot_shut: bool = not main.forest.knots[2].open
		for e in main.oak_hogs_alive():
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
		main.update_oak()
		var hogs_beaten: bool = main.oak_hogs_beaten
		main.oak_q = oak0[0]
		main.oak_hogs_beaten = oak0[1]
		main.oak_hogs_up = oak0[2]
		main.crown_pips = oak0[3]
		if not (hogs == 2 and knot_shut and hogs_beaten):
			bad.append("7 oak hogs out=%d last knot shut=%s beaten=%s" % [hogs, knot_shut, hogs_beaten])
		main.return_to_start()
		# 8. a second cart-mole win changes nothing
		var sk0: bool = main.has_skip
		main.has_skip = true
		main.set_quest("물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자")
		main.mole_defeated()
		if main.story_open or plain(main.ui.quest.text) != main.tr("물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"):
			bad.append("8 second mole win story=%s quest=%s" % [main.story_open, plain(main.ui.quest.text)])
		main.close_story()
		main.has_skip = sk0
		# 9. the late hint after the first lamp leaves Bori's quest alone once she has been met
		main.story_step = 3
		main.set_quest("북쪽 벽돌왕을 쓰러뜨려 물길을 열어라 (상점에서 약을 챙기자)") # an old save's line
		main.lantern_quest_late()
		var late_ok: bool = plain(main.ui.quest.text) == plain(main.quest_shown(main.BORI_QUEST)) and plain(main.ui.quest.text).begins_with(main.tr(main.BORI_QUEST))
		main.story_step = 2
		main.lantern_quest_late()
		late_ok = late_ok and plain(main.ui.quest.text) == main.tr("쪽지에 적힌 서쪽 오두막을 찾아가자")
		main.story_step = maxi(st0, 8)
		if not late_ok:
			bad.append("9 late lamp hint")
		# 10. the painting first seen late: the quest fits the key, the door and the skip
		var pk: Array = [main.saw_painting, main.has_key, main.cave_door_open, main.has_skip]
		var pq: Array = []
		for c in [[true, false, false], [true, true, false], [true, true, true]]:
			main.saw_painting = false
			main.has_key = c[0]
			main.cave_door_open = c[1]
			main.has_skip = c[2]
			main.set_quest("동굴 다음 길")
			reset_to(main.cave_marks.P)
			main.check_painting()
			main.close_story()
			pq.append(plain(main.ui.quest.text))
		main.saw_painting = pk[0]
		main.has_key = pk[1]
		main.cave_door_open = pk[2]
		main.has_skip = pk[3]
		if pq != [main.tr("얻은 열쇠로 잠긴 문을 열자"), main.tr(main.CAVE_DOOR_QUEST), main.tr("동굴 다음 길")]:
			bad.append("10 painting quests=%s" % [pq])
		main.return_to_start()
		# 11. back in the forest after losing the duel, the duel is the quest
		var fq0: int = main.forest_q
		main.forest_q = 2
		main.enter_forest()
		if main.story_open:
			main.close_story()
		if plain(main.ui.quest.text) != main.tr("노을과 다시 겨루자"):
			bad.append("11 forest re-entry quest=%s" % plain(main.ui.quest.text))
		main.forest_q = fq0
		main.return_to_start()
		# 13. village side lines before Mulgyeol and Noeul join: neither speaks; with Mulgyeol alone only he does
		park_mates(true)
		var sets: Array = [main.inn_first_lines(), main.cast_lines(STORY.MARKET_NOTE), main.bottle_lines(1), main.magpie_nest_lines(), main.magpie_done_lines()]
		var cast_bad := 0
		for ls in sets:
			for l in ls:
				if String(l).begins_with("노을|") or String(l).begins_with("물결|"):
					cast_bad += 1
		var price_kept: bool = "40 → 25" in "".join(main.magpie_done_lines())
		var mul_only := true
		if parked.size() == 2 and parked[0] != null:
			main.mate = parked[0]
			var il: Array = main.inn_first_lines()
			mul_only = il.has(STORY.INN_FIRST_MUL) and not "".join(il).contains("노을|")
			main.mate = null
		park_mates(false)
		if not (cast_bad == 0 and price_kept and mul_only):
			bad.append("13 lines by companions not yet joined=%d price line=%s mulgyeol-only inn=%s" % [cast_bad, price_kept, mul_only])
		# 14, 15. Doran after the letter: no first-meeting lines once his errand began; the letter goes back once
		var dm0: bool = main.met.has("doran")
		var dq0: int = main.doran_q
		var lb0: bool = main.letter_back
		main.met.erase("doran")
		main.doran_q = 3
		main.letter_back = false
		main.folk_talk("doran")
		var give: bool = main.story_open and main.story_lines == STORY.DORAN_LETTER_BACK.slice(1) # the first line is on screen
		main.close_story()
		main.folk_talk("doran")
		var after: bool = main.story_open and main.story_lines == (STORY.FOLK_AGAIN["doran_done"] as Array).slice(1) and main.letter_back
		main.close_story()
		main.letter_back = false
		var rl: Array = main.rise_lines()
		var rise_give: bool = rl.has(STORY.DORAN_LETTER_BACK[0]) and main.letter_back and not main.rise_lines().has(STORY.DORAN_LETTER_BACK[0])
		main.doran_q = dq0
		main.letter_back = lb0
		if dm0:
			main.met["doran"] = true
		if not (give and after and rise_give):
			bad.append("14/15 doran letter back=%s then thanks=%s on the lantern night=%s" % [give, after, rise_give])
		# 16. the guardians wake only in Hangyeol's room, not in the east drain
		var ux := float(main.UNDER.UNDER_X)
		if not (main.in_hangyeol_room(Vector2(ux + 4, 10)) and not main.in_hangyeol_room(Vector2(ux + 23.5, 11.5)) and not main.in_hangyeol_room(Vector2(ux + 18, 9))):
			bad.append("16 hangyeol room bounds")
		# 17. the villagers' ways home cross no house, fence or water
		var through: Array = []
		for id in main.SLEEP_IDS:
			var way: Array = main.folk_way(id)
			for s in 61:
				var p: Vector2 = main.way_at(way, s / 60.0)
				if main.village.blocked(p.x, p.y):
					through.append(id)
					break
		if not through.is_empty():
			bad.append("17 ways through walls: %s" % [through])
		# 18 - 21. lines that fit what was done
		var cq0: int = main.clock_q
		main.clock_q = 5
		var clock_ok: bool = not "먼지가 소복" in "".join(main.clock_worn_lines())
		main.clock_q = cq0
		var garden_in_ok: bool = not "성의 동쪽 문" in String(STORY.GARDEN_IN[0])
		var island_ok: bool = not "섬 밖" in "".join(STORY.INN_FIRST)
		for t in STORY.REST_TALK_STORY:
			if t[0] == "mul_new":
				island_ok = island_ok and not "섬 밖" in str(t[1])
		var fr0: Array = main.forest.freed.duplicate()
		for i in main.forest.freed.size():
			main.forest.freed[i] = false
		var hollow_ok: bool = not "꺼내 준" in "".join(main.hollow_squirrel_lines())
		main.forest.freed[0] = true
		hollow_ok = hollow_ok and "꺼내 준" in "".join(main.hollow_squirrel_lines())
		for i in fr0.size():
			main.forest.freed[i] = fr0[i]
		var pr0: Array = main.castle.pages.map(func(pg): return pg.read)
		for pg in main.castle.pages:
			pg.read = false
		var diary_ok: bool = not "세 장" in "".join(main.under_diary_lines())
		for i in pr0.size():
			main.castle.pages[i].read = pr0[i]
		if not (clock_ok and garden_in_ok and island_ok and hollow_ok and diary_ok):
			bad.append("18-21 clock=%s garden arrival=%s mulgyeol island=%s squirrel store=%s diary=%s" % [clock_ok, garden_in_ok, island_ok, hollow_ok, diary_ok])
		main.story_step = st0
		# put the state from before back
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(before)
		f.close()
		main.return_to_start()
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(before)
		f.close()
		main.load_game()
		if main.story_open:
			main.close_story()
		calm_enemies(false)
		check("laps", bad.is_empty(), "GPT story playtests 2 -> 9, 20 findings checked; failing: %s" % [bad])
	if want.call("books"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = true
		main.has_bookmark = false
		main.tokens[5] = false # the fifth book gives the library token (v0.1.62)
		for bk in main.castle.books:
			bk.read = false
		var reach := true
		for bk in main.castle.books:
			var stand: Vector2 = bk.pos + (Vector2(0, 1.0) if bk.pos.y < 4 else Vector2(0.0, -0.9))
			reach = reach and main.walkable(stand.x, stand.y)
			reset_to(stand)
			tap(KEY_E)
			await wait(0.15)
			main.close_story()
			await wait(0.15)
			main.close_story()
		var xp0: int = main.player.xp
		var lv0: int = main.player.lv
		main.gain_xp(10)
		var more: bool = main.player.lv > lv0 or main.player.xp == xp0 + 12
		main.in_hill = false
		check("books", reach and main.has_bookmark and main.tokens[5] and more, "shelves reachable=%s bookmark=%s xp x1.2=%s" % [reach, main.has_bookmark, more])
	if want.call("bori_e"):
		await wait(0.2)
		main.close_story() # the books test leaves the bookmark scene queued
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.story_step = maxi(main.story_step, 3)
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.doran_q = 3
		main.mail_q = 2
		main.has_tea = true # nothing else waiting for Bori: E goes straight to the shop
		main.crown_key() # what E does in the world
		await wait(0.2)
		var opened: bool = main.shop_open
		tap(KEY_E)
		await wait(0.2)
		check("bori_e", opened and not main.shop_open, "E opens Bori's shop=%s and E closes it=%s" % [opened, not main.shop_open])
	if want.call("mate_facing"):
		var right := Vector2(cos(main.cam_yaw), -sin(main.cam_yaw))
		var ok: bool = main.screen_left(-right) and not main.screen_left(right) and main.screen_left(Vector2(0, 1)) == (Vector2(0, 1).dot(right) < 0.0)
		check("mate_facing", ok, "companions turn by screen direction, not world x=%s" % ok)
	if want.call("settings"):
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		tap(KEY_ESCAPE)
		await wait(0.1)
		var opened: bool = main.settings_open and main.ui.settings.visible
		var h0: float = main.hour
		await wait(0.5)
		var paused: bool = main.hour == h0
		var tilt_off: bool = main.ui.set_rows.keys().slice(0, 2) == ["sora_px", "voice"] and main.cfg.tilt and main.cfg.shake and main.cfg.nums \
			and main.ui.now_tune.text.begins_with("♪") and not main.ui.now_tune.editable
		main.ui.set_plus.emit_signal("pressed")
		var bigger: bool = main.ui.story_text.get_theme_font_size("font_size") > 20
		main.ui.set_minus.emit_signal("pressed")
		var hidden_nums := true
		main.show_set_tab(2)
		var tab_ok: bool = main.ui.set_pages[2].visible and not main.ui.set_pages[0].visible
		tap(KEY_ESCAPE)
		await wait(0.1)
		var closed: bool = not main.settings_open
		check("settings", opened and paused and tilt_off and bigger and hidden_nums and tab_ok and closed,
			"Esc opens=%s world waits=%s blur off=%s bigger text=%s numbers off=%s tabs=%s Esc closes=%s" % [opened, paused, tilt_off, bigger, hidden_nums, tab_ok, closed])
	if want.call("mate_chat"):
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.join_mate()
		main.join_noeul()
		calm_enemies(true)
		# goblins downed by earlier tests rise again 8 s later somewhere 9+ tiles off and walk in, and one inside 8 tiles
		# hushes the talk (the full run once counted 1 balloon of 4): hold their rising until this test is done
		var risers: Array = main.enemies.filter(func(e): return e.dead and not e.get("cave", false) and not e.get("boss", false))
		for e in risers:
			e.respawn = 9999.0
		reset_to(Vector2(20, 30))
		main.snap_mates()
		main.chat_t = 9.5
		main.chat_cd = 0.0
		await wait(0.2)
		var talked: bool = main.bubbles_said > 0
		await wait(11.0) # let a talk the rest started run out
		var said0: int = main.bubbles_said
		main.chat_cd = 30.0 # no talk of its own may start over this one
		main.rest_talk(main.STORY.REST_TALK[0]) # Sora, Mulgyeol, Noeul, Mulgyeol: all three talk
		await wait(8.0)
		var said: int = main.bubbles_said - said0
		var three: bool = said == 4
		await wait(11.0)
		var said1: int = main.bubbles_said
		main.rest_talk(main.STORY.REST_TALK[0])
		await wait(0.3)
		main.spawn_enemy(Vector2(main.player.x + 3.0, main.player.z)) # a goblin turns up: the talk stops
		main.enemies[main.enemies.size() - 1].hp = 99999.0 # it must stay up while the talk is checked
		await wait(5.5)
		var hushed: bool = main.bubbles_said - said1 == 1 and main.talk_bubbles.is_empty()
		var chat_gob: Dictionary = main.enemies[main.enemies.size() - 1]
		if not chat_gob.dead: # the companions may have beaten it already
			chat_gob.dead = true
			chat_gob.node.queue_free()
			chat_gob.shadow.queue_free()
		chat_gob.respawn = 9999.0 # nor may it rise again beside her while the story talk is checked
		risers.append(chat_gob)
		# a talk about where the story stands comes first, once
		main.talks_heard = {}
		var fq0: int = main.forest_q
		var hq0: int = main.hill_q
		main.forest_q = 3
		main.hill_q = 0
		main.player.vx = 0.0 # the goblin's last hit may have pushed her, and moving resets the rest clock
		main.player.vz = 0.0
		main.chat_t = 9.5
		main.chat_cd = 0.0
		for k in 20: # a busy machine may need a few frames more
			if not main.talks_heard.is_empty():
				break
			main.player.vx = 0.0
			main.player.vz = 0.0
			main.chat_t = maxf(main.chat_t, 9.5)
			await wait(0.1)
		var story_first: bool = main.talks_heard.has("noeul_new")
		main.forest_q = fq0
		main.hill_q = hq0
		for e in risers:
			e.respawn = 8.0
		calm_enemies(false)
		check("mate_chat", talked and three and hushed and story_first and main.chat_cd > 10.0, "a balloon after standing still=%s a four-line talk among all three=%s (%d balloons) a monster stops it=%s story talk first=%s %s" % [talked, three, said, hushed, story_first, main.talks_heard.keys()])
	if want.call("pips"):
		# v0.0.47: the moon gauge grows 8 -> 12, one pip at the letter, the turtle, the thirteenth lantern and the knight
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var th0: Node3D = main.thirteenth # the lantern scene hangs the thirteenth lantern; taken down again after
		var kept0: Array = [main.pip_max, main.pip_awards.duplicate(), main.crown_pips, main.doran_q, main.lake_q, main.hollow_q, main.castle_q, main.post_q, main.player.gold, plain(main.ui.quest.text)]
		main.pip_max = 8
		main.pip_awards = {}
		main.crown_pips = 3
		main.post_q = 0
		var steps: Array = []
		var hp_same := true
		var hp0: int = main.player.max_hp
		main.deliver_letter()
		var letter_line: bool = main.story_lines.any(func(l): return "최대 9칸" in String(l))
		main.close_story()
		steps.append([main.pip_max, main.crown_pips])
		hp_same = hp_same and main.player.max_hp == hp0
		main.turtle_beaten()
		main.close_story()
		steps.append([main.pip_max, main.crown_pips])
		hp0 = main.player.max_hp # the turtle's XP may level her up
		main.simji_lantern()
		main.close_story()
		steps.append([main.pip_max, main.crown_pips])
		hp_same = hp_same and main.player.max_hp == hp0
		main.knight_beaten()
		main.close_story()
		steps.append([main.pip_max, main.crown_pips])
		var grew: bool = str(steps) == str([[9, 9], [10, 10], [11, 11], [12, 12]])
		main.deliver_letter() # each place gives its pip once
		var no_line: bool = not main.story_lines.any(func(l): return "깨어났다" in String(l))
		main.close_story()
		main.knight_beaten()
		main.close_story()
		var once: bool = main.pip_max == 12 and main.pip_awards.size() == 4 and no_line
		# the HUD draws one diamond per pip, all inside the 400 px bars
		await wait(0.2)
		var spots: Array = main.ui.hud.pip_spots()
		var hud_ok: bool = spots.size() == 12 and (spots[11] as Vector2).x + 6.0 <= main.ui.hud.bars_end() and main.ui.hud.pips_drawn == 12
		# save and load keep the gauge
		main.crown_pips = 5
		main.save_game()
		var sd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		main.pip_max = 8
		main.pip_awards = {}
		main.load_pips(sd)
		var saved: bool = main.pip_max == 12 and main.pip_awards.size() == 4 and main.crown_pips == 5
		# a new round keeps both, and starts full
		main.write_new_round()
		var nd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		main.load_pips(nd)
		var round_ok: bool = int(nd.get("pip_max", 0)) == 12 and (nd.get("pip_awards", []) as Array).size() == 4 and main.crown_pips == 12
		main.pip_note = "" # an earlier test may have loaded an old save and left its note
		main.old_save_pips(nd) # a save that has pip_max: nothing given back
		round_ok = round_ok and main.pip_max == 12 and main.pip_note == ""
		var round_info := "(%s %s pips %d/%d)" % [str(nd.get("pip_max")), str(nd.get("pip_awards")), main.crown_pips, main.pip_max]
		# an old save (no pip_max) past the letter, the turtle and the knight: three pips back, once
		main.doran_q = 3
		main.lake_q = 4
		main.hollow_q = 1
		main.castle_q = 3
		var od := {"pips": 6}
		main.load_pips(od)
		var old8: bool = main.pip_max == 8 and main.crown_pips == 6
		main.old_save_pips(od)
		var old_ok: bool = old8 and main.pip_max == 11 and main.crown_pips == 9 and "11" in main.pip_note and not main.pip_awards.has("lantern")
		main.pip_note = ""
		main.save_game()
		var od2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		main.load_pips(od2)
		main.old_save_pips(od2)
		old_ok = old_ok and main.pip_max == 11 and main.pip_note == ""
		main.pip_max = int(kept0[0])
		main.pip_awards = kept0[1]
		main.crown_pips = int(kept0[2])
		main.doran_q = int(kept0[3])
		main.lake_q = int(kept0[4])
		main.hollow_q = int(kept0[5])
		main.castle_q = int(kept0[6])
		main.post_q = int(kept0[7])
		main.player.gold = int(kept0[8])
		main.set_quest(String(kept0[9]))
		if th0 == null and main.thirteenth != null: # the hollow test hangs it for real later
			main.lanterns.erase(main.thirteenth)
			(main.thirteenth.get_meta("glass") as Node).queue_free()
			main.thirteenth.queue_free()
			main.thirteenth = null
		main.save_game()
		check("pips", grew and once and hp_same and letter_line and hud_ok and saved and round_ok and old_ok,
			"one pip at each place %s=%s once=%s max HP no longer grows=%s letter says max 9=%s HUD 12 under the bars=%s (%d drawn) save/load=%s new round keeps and fills=%s %s old save gets 3 back once=%s" % [str(steps), grew, once, hp_same, letter_line, hud_ok, main.ui.hud.pips_drawn, saved, round_ok, round_info, old_ok])
	if want.call("folk_chat"):
		# villagers chatter: a line whose tags all fit, from someone within 4 tiles, never from someone asleep
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var st0: Array = [main.story_step, main.night_q, main.lake_q, main.kid_q, main.hour, main.raining, main.errand, main.doran_q, main.mul_q, main.mail_got[1]]
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		if not main.in_village:
			main.enter_village()
		await wait(0.3)
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		var chat_cd0: float = main.chat_cd
		main.chat_cd = 1.0e9 # companions' random chatter must not touch the count this test reads
		main.chatter.hush_talk() # and a talk left running by the test before (its timers) is cancelled
		main.story_step = 8
		main.night_q = 0
		main.lake_q = 0
		main.kid_q = 0
		main.errand = 3
		main.doran_q = 0
		main.mul_q = 3
		main.mail_got[1] = false
		main.raining = false
		main.hour = 12.0
		# by day before the ending: no morning, dusk, rain, festival, errand or later-story line
		var tags_ok := true
		for id in main.STORY.FOLK_CHAT:
			for l in main.folk_chat_lines(id):
				for pair in main.STORY.FOLK_CHAT[id]:
					if pair[1] == l:
						var tg: String = pair[0]
						for bad in ["after_ending", "after_lake", "after_night", "morning", "dusk", "rain", "festival", "errand"]:
							if bad in tg:
								tags_ok = false
		main.story_step = 12
		main.night_q = 4
		var end_line: bool = main.folk_chat_lines("doran").has("이젠 새 소식 담을 봉투도 필요하겠소.")
		main.story_step = 8
		main.night_q = 0
		var kid_hidden: bool = not main.folk_chat_at("kid").is_finite() # not before he is home with Kongal
		var pair_far: bool = not main.folk_tag_ok("simji", "pair:tori") # a pair line only with the other one near
		# Sora beside Doran by day: someone speaks within a few seconds, with a line that fits
		var dp: Vector2 = main.folk_chat_at("doran")
		reset_to(dp + Vector2(1.5, 0))
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.folk_chat_off = false
		main.folk_chat_cd = {}
		main.folk_chat_gap = 0.0
		main.folk_said = []
		var said0: int = main.bubbles_said
		for k in 80:
			if not main.folk_said.is_empty():
				break
			await wait(0.1)
		var spoke: bool = not main.folk_said.is_empty()
		var line_fits := false
		if spoke:
			var who: String = main.folk_said[0][0]
			for pair in main.STORY.FOLK_CHAT[who]:
				if pair[1] == main.folk_said[0][1]:
					line_fits = Array(String(pair[0]).split(",")).all(func(tg): return main.folk_tag_ok(who, String(tg)))
		var no_mate_count: bool = main.bubbles_said == said0
		var n1: int = main.folk_said.size()
		await wait(3.5) # one balloon at a time: nothing more for the next 3.5 s
		var gap_ok: bool = main.folk_said.size() == n1
		# asleep at night: no sleeper speaks
		main.sleep_off = false
		main.hour = 23.0
		for k in 100:
			main.update_folk_sleep(0.5)
		main.folk_chat_cd = {}
		main.folk_chat_gap = 0.0
		var n2: int = main.folk_said.size()
		var asleep: bool = main.folk_state.get("doran", "out") == "in" and not main.folk_chat_at("doran").is_finite()
		await wait(6.0)
		var quiet_night: bool = main.folk_said.slice(n2).all(func(p): return p[0] == "simji")
		main.sleep_off = true
		main.hour = 12.0
		for k in 100:
			main.update_folk_sleep(0.5)
		# the kid goblin speaks once he is home
		main.kid_q = 3
		main.place_kid()
		main.update_folk_sleep(0.1)
		var kid_back: bool = main.folk_chat_at("kid").is_finite()
		main.folk_chat_off = true
		main.kid_q = int(st0[3])
		if main.kid_node != null:
			main.kid_node.visible = false
		main.story_step = int(st0[0])
		main.night_q = int(st0[1])
		main.lake_q = int(st0[2])
		main.hour = float(st0[4])
		main.raining = bool(st0[5])
		main.errand = int(st0[6])
		main.doran_q = int(st0[7])
		main.mul_q = int(st0[8])
		main.mail_got[1] = bool(st0[9])
		main.chat_cd = chat_cd0
		park_mates(false)
		calm_enemies(false)
		check("folk_chat", tags_ok and end_line and kid_hidden and pair_far and spoke and line_fits and no_mate_count and gap_ok and asleep and quiet_night and kid_back,
			"by day before the ending only fitting lines=%s after the ending Doran's ending line=%s kid quiet before home=%s pair line needs the other=%s someone spoke beside Sora=%s %s its tags fit=%s companions' count untouched=%s one balloon at a time=%s Doran asleep at 23=%s no sleeper spoke=%s kid speaks once home=%s" % [tags_ok, end_line, kid_hidden, pair_far, spoke, str(main.folk_said.slice(0, 2)), line_fits, no_mate_count, gap_ok, asleep, quiet_night, kid_back])
	if want.call("noeul_rest"):
		# Noeul sits down (art/folk/noeul_rest.png) while Sora rests, and stands again when she moves or a monster comes
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.join_noeul()
		main.join_mate()
		calm_enemies(true)
		var risers: Array = main.enemies.filter(func(e): return e.dead and not e.get("cave", false) and not e.get("boss", false))
		for e in risers:
			e.respawn = 9999.0
		reset_to(Vector2(20, 30))
		main.snap_mates()
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.last_input_t = main.t
		var spr: Sprite3D = main.mate2.get_child(0)
		var mspr: Sprite3D = main.mate.get_child(0)
		await wait(1.5)
		var standing: bool = not main.noeul_sitting and spr.hframes in [3, 4] and not main.mulgyeol_sitting and mspr.hframes in [2, 4] # 4: the breathing sheet (v0.1.39)
		main.last_input_t = main.t - 20.0 # no key for 20 s
		await wait(1.0)
		var sat: bool = main.noeul_sitting and spr.hframes == 4 and spr.texture.resource_path.ends_with("noeul_rest_breath.png")
		var mframes := {}
		var nframes := {}
		for i in 12: # sitting, both breathe: their frames turn (v0.1.92)
			mframes[mspr.frame] = true
			nframes[spr.frame] = true
			await wait(0.12)
		sat = sat and nframes.size() >= 3
		var msat: bool = mframes.size() >= 3 and main.mulgyeol_sitting and mspr.hframes == 4 and mspr.texture.resource_path.ends_with("mulgyeol_rest_breath.png") and absf(mspr.offset.y - 90.0) < 0.1 			and Vector2(main.mate.position.x - main.mate2.position.x, main.mate.position.z - main.mate2.position.z).length() >= 0.9
		hold_world(Vector2(1, 0))
		main.last_input_t = main.t
		await wait(0.4)
		release()
		var up: bool = not main.noeul_sitting and spr.texture.resource_path.get_file() in ["noeul.png", "noeul_breath.png"] and not main.mulgyeol_sitting and mspr.texture.resource_path.get_file() in ["mulgyeol.png", "mulgyeol_breath.png"] and absf(mspr.offset.y - 85.0) < 0.1
		main.player.vx = 0.0
		main.player.vz = 0.0
		await wait(1.0)
		main.last_input_t = main.t - 20.0
		hold_mates() # late in a full run the companions downed or knocked the goblin out of reach within the half second
		main.spawn_enemy(Vector2(main.player.x + 4.0, main.player.z)) # a monster near: he does not sit
		var gob: Dictionary = main.enemies[main.enemies.size() - 1]
		gob.hp = 99999.0 # late in a full run the companions would beat it inside the half second
		await wait(0.5)
		var fight_up: bool = not main.noeul_sitting and not main.mulgyeol_sitting
		var gob_seen := "goblin dead=%s %.1f tiles off" % [gob.dead, Vector2(gob.x - main.player.x, gob.z - main.player.z).length()]
		if not gob.dead:
			gob.dead = true
			gob.node.queue_free()
			gob.shadow.queue_free()
		gob.respawn = 9999.0
		for e in risers:
			e.respawn = 8.0
		main.last_input_t = main.t
		calm_enemies(false)
		check("noeul_rest", standing and sat and msat and up and fight_up, "standing at first=%s Noeul sits on the rest picture while Sora rests=%s Mulgyeol too, apart from him=%s both stand when she moves=%s both stay up with a monster near=%s (%s)" % [standing, sat, msat, up, fight_up, gob_seen])
	if want.call("east_bridge"):
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.has_skip = false # even without the water skip
		main.story_step = maxi(main.story_step, 7)
		calm_enemies(true)
		reset_to(Vector2(43.5, 20.5))
		hold_world(Vector2(1, 0))
		await wait(1.6)
		release()
		await wait(0.3)
		var inside: bool = main.in_village
		main.has_skip = true
		main.in_village = false
		calm_enemies(false)
		check("east_bridge", inside, "walking east over the new bridge reaches the village without the water skip=%s" % inside)
	if want.call("fall_down"):
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		calm_enemies(true)
		reset_to(Vector2(30, 30))
		main.player.inv = 0.0
		main.player.hp = 5.0
		main.hurt_player(50, 0.0)
		await wait(1.0)
		var lying: bool = main.down_t > 0.0 and absf(main.hero.rotation.z) > 1.2 and Vector2(main.player.x, main.player.z).distance_to(Vector2(30, 30)) < 0.2
		await wait(2.4)
		var woke := false
		for i in 20: # a slow machine runs the game clock behind the wall clock: give it up to 4 s more
			main.close_story()
			woke = main.down_t == 0.0 and Vector2(main.player.x, main.player.z).distance_to(main.START) < 0.5 and main.hero.rotation.z == 0.0 and main.player.hp > 0.0
			if woke:
				break
			await wait(0.2)
		calm_enemies(false)
		check("fall_down", lying and woke, "falls where she stands=%s wakes at the start after 3 s=%s" % [lying, woke])
	if want.call("mate_hp"):
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.join_mate()
		calm_enemies(true)
		reset_to(Vector2(20, 30))
		main.snap_mates()
		main.mate_hp.mulgyeol = 20.0
		main.hurt_mate("mulgyeol", 30)
		var down: bool = main.mate_down.mulgyeol > 0.0
		main.mate_down.mulgyeol = 0.05
		await wait(0.2)
		var up: bool = main.mate_down.mulgyeol == 0.0 and absf(main.mate_hp.mulgyeol - main.mate_max() * 0.5) < 5.0
		calm_enemies(false)
		check("mate_hp", down and up, "a companion at 0 HP sits out=%s and gets up with half health=%s" % [down, up])
	if want.call("road"):
		# Hangyeol's last road: the yard below the garden between the stairs' top and the arena
		main.story_step = maxi(main.story_step, 11)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_cave = false
		main.in_hill = true
		main.forest_q = 3
		main.hill_q = 3
		main.castle_q = 3
		main.tokens = [true, true, true, true, true, true] # the stairs' top door asks for four (v0.1.62)
		main.hollow_q = 4
		main.garden_q = 0
		main.road_q = 0
		main.open_stairs()
		main.garden.roots_open = false # an earlier test opened the yard: shut it again
		main.garden.gate_open = false
		main.garden.reveal(false)
		for r in main.garden.roots:
			r[1].visible = true
		reset_to(main.stairs.marks.N + Vector2(0, 0.3))
		await wait(1.5)
		var gx: float = main.GARDEN.GARDEN_X
		var arrived: bool = main.in_garden and main.road_q == 1 and main.garden_q == 0 and Vector2(main.player.x, main.player.z).distance_to(main.garden.road_marks.A) < 2.5
		main.close_story()
		calm_enemies(true)
		var shut: bool = not main.player_can(gx + 16, 35)
		main.hour = 12.0
		main.crown_pips = 3
		var foes0: int = main.enemies.filter(func(e): return not e.dead and e.x > gx).size()
		reset_to(Vector2(gx + 15, 35))
		tap(KEY_E)
		await wait(0.15)
		var roots: bool = main.garden.roots_open and main.crown_pips == 0 and main.road_q == 2 and main.player_can(gx + 16, 35) \
			and main.enemies.filter(func(e): return not e.dead and e.x > gx).size() == foes0 + 2
		calm_enemies(true)
		reset_to(Vector2(gx + 23, 34))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var page: bool = main.road_q == 3
		reset_to(Vector2(gx + 20, 33))
		tap(KEY_E)
		await wait(0.15)
		var hook: bool = main.story_open
		main.close_story()
		reset_to(Vector2(gx + 10, 30)) # off his steps: down the gap and back up at the camp's edge
		await wait(0.2)
		var fell: bool = absf(main.player.x - (gx + 19)) < 0.6 and absf(main.player.z - 32.0) < 0.6 and main.player.hp == main.player.max_hp - (maxi(1, int(round(round(8 * main.sora.FOE_DMG_K * main.ng_mult()) * 0.85))) if main.has_armour else int(round(8 * main.sora.FOE_DMG_K * main.ng_mult())))
		reset_to(Vector2(gx + 17, 29)) # on a footprint: she stays
		await wait(0.2)
		var stood: bool = absf(main.player.x - (gx + 17)) < 0.3 and absf(main.player.z - 29.0) < 0.3
		var g0: int = main.player.gold
		reset_to(Vector2(gx + 13, 25))
		main.player.inv = 9.0
		await wait(0.3)
		main.close_story()
		await wait(0.2)
		var echoes: Array = main.enemies.filter(func(e): return e.get("echo", false) and not e.dead)
		var rose: bool = echoes.size() == 1 and echoes[0].max_hp == 2200
		if echoes.size() == 1:
			var ec: Dictionary = echoes[0]
			main.damage_enemy(ec, 100000.0, Vector2(ec.x, ec.z) - ec.face) # from behind: his shield keeps his front
			await wait(1.4)
		main.close_story()
		var beaten: bool = main.road_q == 4 and main.player.gold == g0 + 100 and main.player_can(gx + 14, 21)
		reset_to(Vector2(gx + 14, 19))
		await wait(0.3)
		var arena: bool = main.garden_q == 1
		main.close_story()
		var saved = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = saved != null and int(saved.get("road_q", 0)) == 4 and main.way_known(6)
		calm_enemies(false)
		main.in_garden = false
		check("road", arrived and shut and roots and page and hook and fell and stood and rose and beaten and arena and kept,
			"arrived at the yard=%s roots shut/unwound=%s/%s fifth page=%s hook=%s fell off and back=%s footprint holds=%s brick Hangyeol 2200=%s beaten opens the gate=%s arena=%s saved and waystone=%s" % [arrived, shut, roots, page, hook, fell, stood, rose, beaten, arena, kept])
	if want.call("mill"):
		# the sparrows' mill below the wind hills' south fence
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.forest_q = 3
		main.hill_q = 3
		main.mill_q = 0
		main.mill_hint_told = true
		main.mill_in_told = true
		main.hill.raise_bridge()
		var hx: float = main.HILL.HILL_X
		var sm: Dictionary = main.hill.south_marks
		var shut: bool = not main.player_can(sm.G.x, sm.G.y)
		var foes0: int = main.hill.foes.size()
		main.hour = 12.0
		main.crown_pips = 4
		reset_to(sm.G + Vector2(0, -1.0))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var wall: bool = main.mill_q == 1 and main.player_can(sm.G.x, sm.G.y) and main.crown_pips == 4 - main.unbrick_cost() and main.hill.foes.size() == foes0
		calm_enemies(true)
		main.crown_pips = 1
		reset_to(sm.Q + Vector2(1.5, 0))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var wound: bool = main.mill_q == 2 and main.hill.mills.size() == 3 and main.crown_pips == 0
		main.skipping = true
		var dry: bool = not main.player_can(hx + 20, 33.5)
		main.skipping = false
		reset_to(sm.P + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.1)
		var began: bool = main.windrun_on
		for w in main.hill.wheels:
			reset_to(w)
			await wait(0.1)
		main.close_story()
		await wait(0.3)
		main.close_story()
		await wait(0.2)
		var called: bool = began and main.mill_q == 3 and main.hill.filled and not main.windrun_on
		main.skipping = true
		var wet: bool = main.player_can(hx + 20, 33.5)
		main.skipping = false
		var guards: Array = main.enemies.filter(func(e): return e.get("mill_guard", false) and not e.dead)
		var guard_ok: bool = guards.size() == 1 and guards[0].max_hp == 300 + main.foe_lv() * 45
		park_mates(true)
		var g0: int = main.player.gold
		if guards.size() == 1:
			main.damage_enemy(guards[0], 100000.0, Vector2(guards[0].x - 1.0, guards[0].z))
			await wait(1.4)
		main.close_story()
		var down: bool = main.mill_q == 4 and main.player.gold == g0 + 60
		park_mates(false)
		var hp0: int = main.player.max_hp
		main.has_oar_ring = false
		main.tokens[4] = false # the chest gives the hill token (v0.1.62)
		reset_to(sm.c + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var chest: bool = main.mill_q == 5 and main.has_oar_ring and main.tokens[4] and main.player.max_hp == hp0 + 10 and main.mate_power() == 0.3
		var saved = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = saved != null and int(saved.get("mill_q", 0)) == 5 and bool(saved.get("has_oar_ring", false))
		calm_enemies(false)
		main.in_hill = false
		check("mill", shut and wall and wound and dry and called and wet and guard_ok and down and chest and kept,
			"wall shut/unwound=%s/%s windmill wound=%s channel dry=%s wind called and water in=%s skip crosses=%s guardian=%s down=%s chest oar ring=%s saved=%s" % [shut, wall, wound, dry, called, wet, guard_ok, down, chest, kept])
	if want.call("windrun_retry"):
		# a missed pinwheel run: a gust carries Sora to the wind post in under a second without a jump, the quest line says
		# to press E there again, each miss makes the next run 2 s longer (12, 14, 16, at most 18), leaving the hollow
		# mid-run gives the same line without moving her, a win starts the next lap at 12 s again (the user, 2026-10-25)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		var keep := [main.in_hill, main.forest_q, main.hill_q, main.mill_q, main.mill_hint_told, main.mill_in_told, main.windrun_quest]
		main.in_hill = true
		main.forest_q = 3
		main.hill_q = 3
		main.mill_q = 2
		main.mill_hint_told = true
		main.mill_in_told = true
		main.hill.raise_bridge()
		main.windrun_tries = 0
		calm_enemies(true)
		park_mates(true)
		var sm: Dictionary = main.hill.south_marks
		var w0: Vector2 = main.hill.wheels[0]
		var bad: Array = []
		var times: Array = []
		var biggest := 0.0
		for tryno in 3:
			reset_to(sm.P + Vector2(1.0, 0))
			tap(KEY_E)
			await wait(0.1)
			if not main.windrun_on:
				bad.append("run %d did not start" % tryno)
				break
			times.append(snappedf(main.windrun_left, 0.5))
			reset_to(w0 + Vector2(0, 2.0)) # away from the post, in the hollow
			main.windrun_left = 0.05
			var last := Vector2(main.player.x, main.player.z)
			var frames := 0
			await get_tree().process_frame
			while frames < 120 and (main.windrun_on or not main.windrun_glide.is_empty() or frames < 3):
				await get_tree().process_frame
				var now := Vector2(main.player.x, main.player.z)
				biggest = maxf(biggest, now.distance_to(last))
				last = now
				frames += 1
			var d: float = last.distance_to(sm.P)
			var line_ok: bool = plain(main.ui.quest.text).begins_with(main.hill_zone.retry_prefix()) and ("%d번째" % (tryno + 2)) in plain(main.ui.quest.text)
			if not (d < 1.2 and line_ok and not main.windrun_on and main.windrun_tries == tryno + 1):
				bad.append("miss %d: %.2f tiles from the post, quest '%s', tries %d" % [tryno, d, plain(main.ui.quest.text), main.windrun_tries])
		# leaving the hollow mid-run: the same line, no gust, and the run after it is 18 s (the cap)
		reset_to(sm.P + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.1)
		times.append(snappedf(main.windrun_left, 0.5))
		reset_to(Vector2(sm.P.x, float(main.HILL.MILL_Z) - 3.0))
		await wait(0.15)
		var left_at := Vector2(main.player.x, main.player.z)
		var stayed: bool = left_at.distance_to(Vector2(sm.P.x, float(main.HILL.MILL_Z) - 3.0)) < 0.3 and main.windrun_glide.is_empty()
		var left_line: bool = not main.windrun_on and plain(main.ui.quest.text).begins_with(main.hill_zone.retry_prefix()) and main.windrun_tries == 4
		reset_to(sm.P + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.1)
		times.append(snappedf(main.windrun_left, 0.5))
		# a win: every pinwheel, then the next lap starts at 12 s again
		for w in main.hill.wheels:
			reset_to(w)
			await wait(0.1)
		main.close_story()
		await wait(0.3)
		main.close_story()
		await wait(0.2)
		var won: bool = main.mill_q == 3 and main.windrun_tries == 0 and not main.windrun_on
		reset_to(sm.P + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.1)
		times.append(snappedf(main.windrun_left, 0.5))
		main.windrun_on = false
		main.in_hill = keep[0]
		main.forest_q = keep[1]
		main.hill_q = keep[2]
		main.mill_q = keep[3]
		main.mill_hint_told = keep[4]
		main.mill_in_told = keep[5]
		main.windrun_quest = keep[6]
		main.windrun_tries = 0
		for e in main.enemies:
			if e.get("mill_guard", false):
				e.dead = true
		calm_enemies(false)
		park_mates(false)
		main.return_to_start()
		check("windrun_retry", bad.is_empty() and biggest <= 1.0 and stayed and left_line and won and times == [12.0, 14.0, 16.0, 18.0, 18.0, 12.0],
			"misses %s, biggest step %.2f, leaving stayed=%s retry line=%s, win resets=%s, run times %s" % [bad, biggest, stayed, left_line, won, times])
	if want.call("post"):
		# the stream's end below the mole's hall: skip in, ring the islands' crystals, Bori's postcard
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		park_mates(true) # a companion's hit can fell a woken brick before it is counted
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_hill = false
		main.story_step = maxi(main.story_step, 7)
		main.post_q = 0
		main.post_spawned = false
		main.has_skip = false
		main.enter_cave()
		main.close_story()
		calm_enemies(true)
		var cx: float = main.CAVE_X
		main.skipping = false
		var dry: bool = not main.player_can(cx + 26, 21)
		main.has_skip = true
		main.skipping = true
		var wet: bool = main.player_can(cx + 26, 21) and main.skip_water(cx + 26, 21) and not main.skip_water(cx + 15, 12)
		main.skipping = false
		reset_to(Vector2(cx + 26, 20))
		await wait(0.3)
		if main.post_q == 0: # the mole hall's own scene came first
			main.close_story()
			reset_to(Vector2(cx + 26, 20))
			await wait(0.3)
		var told: bool = main.post_q == 1
		main.close_story()
		var foes0: int = main.enemies.filter(func(e): return not e.dead and e.x > cx and e.x < cx + 32 and e.z > 26.0).size()
		reset_to(Vector2(cx + 20, 29))
		await wait(0.3)
		var woke: int = main.enemies.filter(func(e): return not e.dead and e.x > cx and e.x < cx + 32 and e.z > 26.0).size() - foes0
		calm_enemies(true)
		var set1: Array = main.crystals.filter(func(c): return c.get("set", 0) == 1)
		var shut: bool = not main.player_can(cx + 2, 34)
		var ring_ok := set1.size() == 4
		if ring_ok:
			main.crystal_hit(set1[0]) # A first: wrong, the run stays at the start
			var wrong: bool = main.post_run == 0
			for i in [1, 3, 0, 2]: # B D A C: lowest note first
				set1[i].hurt = 0.0
				main.crystal_hit(set1[i])
			ring_ok = wrong
		await wait(0.2)
		main.close_story()
		var gate: bool = ring_ok and main.post_q == 2 and main.player_can(cx + 2, 34) and shut
		var hp0: int = main.player.max_hp
		var pots0: int = main.player.pots
		reset_to(Vector2(cx + 6, 36))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var card: bool = main.post_q == 3 and main.player.max_hp == hp0 + 10 and main.player.pots == pots0 + 2
		var pots1: int = main.player.pots
		var dq: int = main.doran_q
		main.deliver_letter()
		main.close_story()
		var bori: bool = main.post_q == 4 and main.player.pots == pots1 + 2
		var saved = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = saved != null and int(saved.get("post_q", 0)) == 4
		main.doran_q = dq
		calm_enemies(false)
		main.in_cave = false
		park_mates(false)
		check("post", dry and wet and told and woke == 5 and gate and card and bori and kept,
			"no skip, no way=%s skip crosses (not the shallow pool)=%s by the stream=%s woke=%d of 5 crystals lowest first sink the grate=%s postcard=%s Bori gets it=%s saved=%s" % [dry, wet, told, woke, gate, card, bori, kept])
	if want.call("lake_south"):
		# the water keeper's lower pond below Mulgyeol's island (DESIGN.md "물지기의 아랫못"); state is set directly
		# and waits poll, so a slow machine does not flake
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_forest = false
		main.in_garden = false
		main.in_hill = false
		main.in_cave = false
		main.in_lake = true
		main.night_q = 4
		main.lake_q = 4
		main.lake.thaw()
		main.join_mate()
		main.south_q = 0
		main.south_spawned = false
		main.south_hint_seen = true
		main.south_shed_seen = false
		main.has_whistle = false
		main.lake.south_look(0)
		main.clear_south_job()
		main.mate_down.mulgyeol = 0.0
		calm_enemies(true)
		reset_to(Vector2(284, 22))
		main.player.inv = 120.0
		main.snap_mates()
		var shut: bool = not main.player_can(284, 23)
		main.hour = 12.0
		main.crown_pips = 3
		var n0: int = main.enemies.size()
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var foes: Array = main.enemies.slice(n0)
		var weir: bool = shut and main.south_q == 1 and main.crown_pips == 0 and main.player_can(284, 23) \
			and foes.size() == 5 and foes.all(func(e): return e.cave)
		calm_enemies(true)
		main.skipping = true
		var sunk: bool = not main.player_can(280, 33) and not main.skip_water(280, 30)
		main.skipping = false
		sunk = sunk and not main.player_can(280, 33)
		# R1: Mulgyeol swims to the first chain and the stones come up
		reset_to(Vector2(277, 32))
		main.player.inv = 120.0
		main.snap_mates()
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		await wait(0.2)
		var swam: bool = main.mate_job_state() in ["swim", "pull"]
		for i in 80:
			if main.south_q == 2:
				break
			await wait(0.1)
		var stones: bool = swam and main.south_q == 2 and main.player_can(280, 33)
		for i in 60:
			if main.mate_job.is_empty():
				break
			await wait(0.1)
		stones = stones and main.mate_job.is_empty()
		# R2: he holds the grate up; Sora goes in alone, the chain snaps away, three bricks rise
		reset_to(Vector2(287, 32))
		main.player.inv = 120.0
		main.snap_mates()
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		for i in 80:
			if main.player_can(292, 31):
				break
			await wait(0.1)
		var held: bool = main.player_can(292, 31)
		reset_to(Vector2(294, 31))
		main.player.inv = 120.0
		for i in 60:
			if not main.player_can(292, 31):
				break
			await wait(0.1)
		main.close_story()
		var amb: Array = main.enemies.filter(func(e): return e.get("south_ambush", false) and not e.dead)
		var mp := Vector2(main.mate.position.x, main.mate.position.z)
		var alone: bool = held and not main.player_can(292, 31) and amb.size() == 3 and mp.x < 292.0 \
			and absf(mp.x - 288.0) <= 2.5 and absf(mp.y - 32.0) <= 3.5 and main.mate_job_state() == "wait"
		for e in amb:
			main.damage_enemy(e, 100000.0, Vector2(e.x - 1.0, e.z))
		for i in 60:
			if main.south_q == 3:
				break
			await wait(0.1)
		main.close_story()
		var latch: bool = main.south_q == 3 and main.player_can(292, 31) and main.mate_job.is_empty()
		# the water clockwork, then the keeper's tin
		main.crown_pips = 2
		reset_to(Vector2(295, 34))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var spring: bool = main.south_q == 4 and main.crown_pips == 0 and main.fish_weight(4) == 15 and main.fish_weight(0) == 40
		var hp0: int = main.player.max_hp
		var pots0: int = main.player.pots
		reset_to(Vector2(297, 33))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		await wait(2.0)
		main.close_story()
		var tin: bool = main.south_q == 5 and main.has_whistle and main.player.max_hp == hp0 + 10 and main.player.pots == pots0 + 1
		main.mate_hp.mulgyeol = 1.0
		main.hurt_mate("mulgyeol", 30)
		var quick: bool = main.mate_down.mulgyeol == 5.0
		main.mate_down.mulgyeol = 0.05
		await wait(0.2)
		quick = quick and main.mate_down.mulgyeol == 0.0
		# saves keep it; a save inside the yard mid-ambush wakes outside the grate with no ambush
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = sd != null and int(sd.get("south_q", 0)) == 5 and bool(sd.get("has_whistle", false))
		main.south_q = 2
		reset_to(Vector2(295, 30))
		main.save_game()
		main.spawn_south_ambush()
		var grey: bool = main.forest.gate_open # a load opens what earlier tests left in the save (the forest's grey gate)
		main.load_game()
		await wait(0.2)
		main.close_story()
		main.forest.gate_open = grey
		main.forest.grey_gate.visible = not grey
		var live: int = main.enemies.filter(func(e): return e.get("south_ambush", false) and not e.dead).size()
		var outside: bool = main.south_q == 2 and absf(main.player.x - 289.0) < 0.1 and absf(main.player.z - 31.0) < 0.1 and live == 0 \
			and main.lake.weir_open and main.lake.stones_up and not main.lake.latch_open and not main.player_can(292, 31)
		main.south_q = 5
		main.has_whistle = true
		main.write_new_round()
		var ng = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var round_ok: bool = ng != null and int(ng.get("south_q", 0)) == 0 and bool(ng.get("has_whistle", false))
		# leave it as it was for the other tests
		for e in foes:
			if not e.dead:
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
		main.clear_south_job()
		main.south_q = 0
		main.has_whistle = false
		main.south_spawned = false
		main.lake.south_look(0)
		main.save_game()
		calm_enemies(false)
		main.in_lake = false
		check("lake_south", weir and sunk and stones and alone and latch and spring and tin and quick and kept and outside and round_ok,
			"weir unwound, 5 foes=%s stones sunk, no skip=%s R1 raises them=%s R2 grate, alone, 3 bricks, Mulgyeol outside=%s latch=%s clockwork, carp 15=%s tin whistle=%s up in 5 s=%s saved=%s yard load outside=%s new round=%s" % [weir, sunk, stones, alone, latch, spring, tin, quick, kept, outside, round_ok])
	if want.call("clock"):
		# the clock room under the arena after the ending (DESIGN.md "큰 태엽 방"); the ending still comes when the
		# mold breaks and the room is a side story after it. State is set directly and waits poll (slow machines)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		var q0: int = main.clock_q
		var gears0: Array = main.clock_gears.duplicate()
		var box0: bool = main.clock_box
		var oil0: bool = main.has_oil
		var gq0: int = main.garden_q
		var step0: int = main.story_step
		var scraps := func(): return main.enemies.filter(func(e): return e.has("gear") and not e.dead)
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_hill = false
		main.in_cave = false
		main.in_house = -1
		main.forest_q = 3
		main.hill_q = 3
		main.castle_q = 3
		main.road_q = 4
		main.join_mate()
		main.join_noeul()
		main.garden_q = 4
		main.clock_q = 0
		main.clock_gears = [false, false, false]
		main.clock_box = false
		main.has_oil = false
		main.garden.clock_look(0, main.clock_gears, false)
		main.enter_garden()
		main.close_story()
		calm_enemies(true)
		main.mate_down.mulgyeol = 999.0 # the mates sit this one out, so they do not cut the scraps down for us
		main.mate_down.noeul = 999.0
		reset_to(main.garden.marks.C + Vector2(-5.0, 0))
		main.player.inv = 120.0
		# 1. the last wind: the ending as before, then the hole and the creak below
		main.final_wind()
		main.close_story()
		await wait(0.3)
		var ending: bool = main.story_open and main.ui.story_frame.visible and main.story_step == 12 and main.garden_q == 5 \
			and main.clock_q == 1 and main.garden.char_at(244, 11) == "." and main.garden.hatch.visible
		main.close_story()
		for i in 30:
			if main.story_open:
				break
			await wait(0.1)
		var hint: bool = main.story_open and plain(main.ui.story_text.text) == tr("땅 밑 깊은 곳에서 톱니 소리가 아직 삐걱거린다.")
		main.close_story()
		await wait(0.6)
		# 2. down the hole
		reset_to(main.garden.marks.C)
		for i in 40:
			if main.in_clock():
				break
			await wait(0.1)
		await wait(0.5)
		var down: bool = main.in_clock() and Vector2(main.player.x, main.player.z).distance_to(main.garden.clock_marks.U) < 2.0 \
			and main.clock_q == 2 and main.garden.clock_screen.visible and plain(main.ui.quest.text).begins_with("시계방의 굳은 톱니")
		main.close_story()
		# 3. one gear at a time; a scrap that reaches its gear hardens it again
		var hard: bool = not main.player_can(236, 53)
		main.crown_pips = 8
		var g0: Vector2 = main.garden.gears[0].pos
		reset_to(g0 + Vector2(1.2, 0))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.1)
		var pip1: bool = main.crown_pips == 7 and main.garden.gears[0].open
		for i in 30:
			if not scraps.call().is_empty():
				break
			await wait(0.1)
		var first: Array = scraps.call()
		var two: bool = first.size() == 2 and first.all(func(e): return e.get("shard", false) and e.cave and int(e.gear) == 0)
		reset_to(main.garden.gears[1].pos + Vector2(-1.2, 0))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.1)
		var one_at_a_time: bool = main.crown_pips == 7 and not main.garden.gears[1].open
		if not first.is_empty():
			first[0].x = first[0].post.x
			first[0].z = first[0].post.y
		await wait(0.15)
		var lost: bool = not main.garden.gears[0].open and not main.clock_gears[0] and scraps.call().is_empty()
		# 4 - 5. free all three: packs of 2, 3, 4; two workers rise for each
		var counts: Array = []
		for gi in [0, 1, 2]:
			var gp: Vector2 = main.garden.gears[gi].pos
			reset_to(gp + (main.garden.clock_marks.O - gp).normalized() * 1.2)
			main.player.inv = 120.0
			tap(KEY_E)
			for i in 30:
				if not scraps.call().is_empty():
					break
				await wait(0.1)
			var pack: Array = scraps.call()
			counts.append(pack.size())
			for e in pack:
				main.damage_enemy(e, 999999.0, Vector2(e.x - 1.0, e.z))
			for i in 40:
				if main.clock_gears[gi]:
					break
				await wait(0.1)
			for i in 40: # the workers' line (first gear) and the slot's line (last) come a moment later
				if gi == 1 or main.story_open:
					break
				await wait(0.1)
			main.close_story()
		var tending: int = main.workers.filter(func(w): return w.job >= 0 and w.job <= 2).size()
		var gears_ok: bool = counts == [2, 3, 4] and main.clock_gears == [true, true, true] and main.clock_q == 3 \
			and main.crown_pips == 4 and tending == 6 and plain(main.ui.quest.text).begins_with("태엽 열쇠 한가운데")
		# 6. the crown into the key: Sora at Hangyeol's spoke, everyone at one
		reset_to(Vector2(243, 56))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		await wait(0.3)
		var mp := Vector2(main.mate.position.x, main.mate.position.z)
		var hub: bool = main.clock_q == 4 and Vector2(main.player.x, main.player.z).distance_to(main.garden.clock_marks.J) < 0.35 \
			and absf(mp.x - 241.0) <= 1.0 and absf(mp.y - 55.0) <= 1.0 and main.garden.crown_rim.visible and main.clock_folk.size() == 4 and plain(main.ui.quest.text).begins_with("한결의 손잡이")
		# 7. eight pushes on the beat (the ring is set directly); an early press does not count
		for i in 20:
			if not main.beat.is_empty():
				break
			await wait(0.1)
		main.beat.r = 1.5
		main.beat.hit = false
		tap(KEY_E)
		await wait(0.05)
		var early: bool = not main.beat.is_empty() and main.beat.n == 0
		for k in 8:
			if main.beat.is_empty():
				break
			main.beat.r = 0.9
			main.beat.hit = false
			tap(KEY_E)
			await wait(0.08)
		var wound: bool = main.clock_q == 5 and plain(main.ui.quest.text).begins_with("이야기 끝 · 정원을 마음껏") and main.story_open and main.ui.story_frame.visible and main.beat.is_empty()
		main.close_story()
		await wait(1.0)
		var hush: bool = not main.story_open # 1.6 s of only the gears' sound
		for i in 30:
			if main.story_open:
				break
			await wait(0.1)
		var late: bool = main.story_open and plain(main.ui.story_text.text) == tr("닳은 손잡이 양옆 손잡이에도 물결과 노을이 손을 얹은 채 숨을 고른다.")
		main.close_story()
		await wait(0.2)
		late = late and not main.clock_still and main.garden.wound
		# 8. the chest: the oil, and a potion also gives 20 momentum
		var hp0: int = main.player.max_hp
		var pots0: int = main.player.pots
		var gold0: int = main.player.gold
		reset_to(main.garden.clock_marks.c + Vector2(-1.0, 0))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var box: bool = main.clock_box and main.has_oil and main.player.max_hp == hp0 + 20 and main.player.pots == pots0 + 2 \
			and main.player.gold == gold0 + 200
		main.player.mp = 0.0
		main.player.cds[3] = 0.0
		main.drink_potion()
		var oil: bool = absf(main.player.mp - 20.0) < 0.01
		# 9. up the stairs to the arena
		reset_to(main.garden.clock_marks.U)
		for i in 40:
			if not main.in_clock():
				break
			await wait(0.1)
		await wait(0.5)
		var up: bool = not main.in_clock() and Vector2(main.player.x, main.player.z).distance_to(Vector2(244, 13.5)) < 0.5 \
			and not main.garden.clock_screen.visible
		# 10. saves keep it; an old save past the ending finds the hole open; a new round keeps only the oil
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = sd != null and int(sd.get("clock_q", 0)) == 5 and Array(sd.get("clock_gears", [])) == [true, true, true] \
			and bool(sd.get("clock_box", false)) and bool(sd.get("has_oil", false))
		main.load_clock({"garden_q": 5})
		var old: bool = main.clock_q == 1 and main.clock_late and main.clock_gears == [false, false, false] and not main.clock_box \
			and main.garden.hatch.visible and not main.garden.wound
		if sd != null:
			main.load_clock(sd)
		var back: bool = main.clock_q == 5 and main.clock_gears == [true, true, true] and main.clock_box and main.garden.wound
		main.write_new_round()
		var ng = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var round_ok: bool = ng != null and not ng.has("clock_q") and bool(ng.get("has_oil", false))
		# leave it as it was for the other tests
		main.clock_q = q0
		main.clock_gears = gears0
		main.clock_box = box0
		main.has_oil = oil0
		main.clock_late = false
		main.clear_clock_wave()
		main.beat_clear()
		main.clock_still = false
		main.garden.clock_look(q0, gears0, box0)
		main.place_workers()
		for id in main.clock_folk:
			main.clock_folk[id].visible = false
		main.garden_q = gq0
		main.story_step = step0
		main.mate_down.mulgyeol = 0.001
		main.mate_down.noeul = 0.001
		main.garden.clock_view(false)
		main.in_garden = false
		calm_enemies(false)
		main.save_game()
		check("clock", ending and hint and down and hard and pip1 and two and one_at_a_time and lost and gears_ok and hub and early and wound and hush and late and box and oil and up and kept and old and back and round_ok,
			"ending then hole=%s hint=%s down=%s gear hard=%s 1 pip=%s 2 scraps=%s one at a time=%s rehardened=%s packs %s, 6 workers=%s crown, all at spokes=%s early E=%s wound with picture=%s hush=%s Bori=%s chest=%s oil +20=%s up=%s saved=%s old save=%s load=%s new round=%s" % [ending, hint, down, hard, pip1, two, one_at_a_time, lost, str(counts), gears_ok, hub, early, wound, hush, late, box, oil, up, kept, old, back, round_ok])
	if want.call("shore"):
		# 깨어난 물가 (DESIGN.md): the basket where Sora woke and Bori's lantern floated down to the island. State is set
		# directly and waits poll (slow machines); everything changed here is put back at the end
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		var q0: int = main.shore_q
		var cush0: bool = main.has_cushion
		var step0: int = main.story_step
		var hour0: float = main.hour
		var max0: int = main.player.max_hp
		var pips0: int = main.crown_pips
		var dq0: int = main.doran_q
		var pq0: int = main.post_q
		var mq0: int = main.mail_q
		var tea0: bool = main.has_tea
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_hill = false
		main.in_cave = false
		main.in_garden = false
		main.in_house = -1
		main.doran_q = 3 # nothing else waiting at Bori's door
		main.post_q = 0
		main.mail_q = 2
		main.has_tea = true
		main.has_cushion = false
		calm_enemies(true)
		knock_shore()
		main.clear_shore_job()
		main.shore_q = 0
		main.shore_seen = false
		main.marsh.shore_look(main, 0)
		var b: Vector2 = MARSH.BASKET_AT
		var by_b := b + Vector2(-0.8, 0.6)
		# 1. before Bori nothing happens where she woke
		main.story_step = 2
		reset_to(main.START)
		await wait(1.0)
		var quiet: bool = main.shore_q == 0 and not main.story_open
		# 2. after Bori the hint opens there; the basket blocks its spot only
		main.story_step = 3
		var hint: bool = await wait_for(func(): return main.story_open, 2.0)
		hint = hint and main.shore_q == 1 and plain(main.ui.story_text.text) == tr(String(STORY.SHORE_HINT[0]).split("|")[2])
		var blocks: bool = not main.player_can(b.x, b.y) and main.player_can(19, 19)
		main.close_story()
		await wait(0.6)
		# 3. E at the basket: its lines, then 1 pip and two packs (2 goblins, then a goblin and an archer), once
		main.crown_pips = 7
		reset_to(by_b)
		main.player.inv = 120.0
		main.crown_key()
		await wait(0.2)
		var seen: bool = main.story_open and main.crown_pips == 7 and plain(main.ui.story_text.text) == tr(String(STORY.SHORE_BASKET[0]).split("|")[2])
		main.close_story()
		await wait(0.4)
		main.crown_key()
		await wait(0.2)
		var woke: bool = main.story_open and main.crown_pips == 6
		main.close_story()
		hold_mates()
		await wait_for(func(): return shore_foes().size() == 2, 2.0)
		var p1: Array = shore_foes()
		var pack1: bool = p1.size() == 2 and p1.all(func(e): return e.cave and not e.archer)
		var gold0: int = main.player.gold
		var pots0: int = main.player.pots
		main.player.inv = 120.0
		knock_shore()
		hold_mates()
		await wait_for(func(): return shore_foes().size() == 2, 3.0)
		var p2: Array = shore_foes()
		var pack2: bool = p2.size() == 2 and p2.filter(func(e): return e.archer).size() == 1 and p2.all(func(e): return e.cave)
		main.player.inv = 120.0
		knock_shore()
		await wait_for(func(): return main.shore_q == 2, 3.0)
		var out: bool = main.shore_q == 2 and main.player.gold == gold0 + 30 and main.player.pots == pots0 + 1 \
			and not main.marsh.basket.visible and main.player_can(b.x, b.y)
		main.close_story()
		await wait(8.5)
		var once: bool = shore_foes().is_empty()
		# 4. Bori knows the basket: her lantern and a potion, not the shop; before the Brick King she says to wait
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		pots0 = main.player.pots
		main.crown_key()
		await wait(0.2)
		var bori: bool = main.shore_q == 3 and main.player.pots == pots0 + 1 and not main.shop_open and main.story_open \
			and main.story_lines.has(STORY.SHORE_BORI_DAM)
		main.close_story()
		await wait(0.6)
		# 5. floating only after the Brick King and only at night
		reset_to(by_b)
		main.crown_pips = 8
		main.hour = 22.0
		main.crown_key()
		await wait(0.1)
		var dam: bool = main.shore_q == 3 and main.crown_pips == 8 and main.shore_float.is_empty()
		main.story_step = 5
		main.hour = 13.0
		main.crown_key()
		await wait(0.1)
		var day: bool = main.crown_pips == 8 and main.shore_float.is_empty()
		main.hour = 22.0
		main.crown_key()
		await wait(0.1)
		var floated: bool = main.crown_pips == 7 and not main.shore_float.is_empty()
		await wait_for(func(): return main.story_open, 3.0)
		var lit: bool = main.story_open and main.marsh.float_glass.material_override == main.marsh.glass_lit
		main.close_story()
		await wait(3.0)
		var flows: bool = not main.shore_float.is_empty() and float(main.shore_float.d) > 2.0
		# 6. a snag holds it; its bricks rise; when they are down it floats on
		var snags_ok := true
		var held := true
		var counts: Array = []
		var near: Array = [Vector2(16.6, 22.4), Vector2(16.4, 27.4), Vector2(17.4, 32.2)]
		for i in 3:
			reset_to(near[i])
			main.player.inv = 120.0
			hold_mates()
			main.shore_float.d = float(main.marsh.snag_d[i]) - 0.05
			await wait_for(func(): return shore_foes().size() == 2, 3.0)
			var pk: Array = shore_foes()
			counts.append(pk.size())
			snags_ok = snags_ok and pk.size() == 2 and (pk.filter(func(e): return e.archer).size() == (1 if i == 2 else 0))
			var d1: float = main.shore_float.d
			await wait(1.0)
			held = held and bool(main.shore_float.wait) and absf(float(main.shore_float.d) - d1) < 0.01
			main.player.inv = 120.0
			knock_shore()
			await wait_for(func(): return int(main.shore_float.snag) == i + 1, 3.0)
			snags_ok = snags_ok and int(main.shore_float.snag) == i + 1 and not bool(main.shore_float.wait)
			if i == 0:
				# 7. too far behind and it waits
				await wait(0.5)
				var moving: bool = float(main.shore_float.d) > float(main.marsh.snag_d[0]) + 0.1
				reset_to(Vector2(8, 17))
				await wait(0.2)
				var d2: float = main.shore_float.d
				await wait(2.0)
				held = held and moving and absf(float(main.shore_float.d) - d2) < 0.01
		var hushed: bool = main.enemy_shots.is_empty()
		# 8. off the island it stops; the reward and the way back come after a hush; Bori gives the cushion
		main.shore_float.d = main.marsh.path_len() - 0.35
		reset_to(Vector2(24, 37))
		await wait_for(func(): return main.shore_q == 4, 3.0)
		var landed: bool = main.shore_q == 4 and main.player.max_hp == max0 + 10 and main.story_open and main.marsh.landed \
			and main.marsh.float_node.visible
		main.close_story()
		await wait(0.8)
		var silent: bool = not main.ui.toast.text.begins_with("최대 체력")
		await wait(2.0)
		var after: bool = main.ui.toast.text.begins_with("최대 체력")
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.crown_key()
		await wait(0.2)
		var cushion: bool = main.shore_q == 5 and main.has_cushion and main.story_open
		main.close_story()
		await wait(0.6)
		# lines picked up elsewhere: chapter 9's diary page and chapter 3's postcard
		var page: bool = main.road_page_lines().has(STORY.ROAD_PAGE_BASKET)
		var card: bool = main.post_bori_lines().has(STORY.POST_BORI_LAMP)
		# 9. the cushion: 4 HP a second resting at night by a lit lantern, full crown or not; nothing by day
		var lamp = main.lanterns.filter(func(l): return l.position.x < 48.0 and not l.get_meta("dark", false) and l != main.dark_lamp)[0]
		reset_to(Vector2(lamp.position.x + 0.5, lamp.position.z + 0.8))
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.crown_pips = 8
		main.hour = 22.0
		main.player.hp = 50.0
		main.idle_t = 0.0 # the 2 s stay under REST_HEAL_WAIT (3 s), so only the cushion mends
		await wait(2.0)
		var hp_night: float = main.player.hp
		var rested: bool = hp_night >= 56.5 and hp_night <= 59.5
		var near_foe := 99.0
		for e in main.enemies:
			if not e.dead:
				near_foe = minf(near_foe, Vector2(e.x - main.player.x, e.z - main.player.z).length())
		main.hour = 13.0
		main.player.hp = 50.0
		main.idle_t = 0.0
		await wait(1.0)
		var by_day: bool = main.player.hp == 50.0
		# 10. saves keep it (the shore part of a load, so other places stay as they are); a save made while floating
		# takes the basket back; a new round keeps only the cushion
		main.save_game()
		main.load_shore(JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH)))
		await wait(0.2)
		var kept: bool = main.shore_q == 5 and main.has_cushion and not main.marsh.basket.visible and main.marsh.landed
		main.shore_q = 3
		main.marsh.shore_look(main, 3)
		main.shore_float = {"d": 3.0, "snag": 0, "wait": false, "up": false, "t": 1.0, "lit": true, "stop": false, "wt": 0.0}
		main.marsh.set_float(main.marsh.float_at(3.0), true)
		main.save_game()
		main.load_shore(JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH)))
		await wait(0.2)
		var taken: bool = main.shore_q == 3 and main.shore_float.is_empty() and not main.marsh.float_node.visible and shore_foes().is_empty()
		main.shore_q = 5
		main.write_new_round()
		var ng = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var round_ok: bool = ng != null and not ng.has("shore_q") and bool(ng.get("has_cushion", false))
		main.shore_q = 4
		main.has_cushion = true
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		var g1: int = main.player.gold
		var pt1: int = main.player.pots
		main.crown_key()
		await wait(0.2)
		round_ok = round_ok and main.shore_q == 5 and main.player.gold == g1 + 40 and main.player.pots == pt1 + 1
		main.close_story()
		await wait(0.6)
		# leave it as it was for the other tests
		knock_shore()
		main.clear_shore_job()
		main.shore_q = q0
		main.has_cushion = cush0
		main.marsh.shore_look(main, q0)
		main.story_step = step0
		main.hour = hour0
		main.player.max_hp = max0
		main.player.hp = float(max0)
		main.crown_pips = pips0
		main.doran_q = dq0
		main.post_q = pq0
		main.mail_q = mq0
		main.has_tea = tea0
		calm_enemies(false)
		main.save_game()
		check("shore", quiet and hint and blocks and seen and woke and pack1 and pack2 and out and once and bori and dam and day and floated and lit and flows and snags_ok and held and hushed and landed and silent and after and cushion and page and card and rested and by_day and kept and taken and round_ok,
			"quiet before Bori=%s hint=%s blocks=%s basket lines=%s woke 1 pip=%s pack 2=%s pack 1+archer=%s out +30 +1=%s once=%s Bori lamp+pot=%s dam=%s day=%s floated 1 pip=%s lit=%s flows=%s snags=%s %s held/waits=%s shots gone=%s landed +10=%s hush=%s then toast=%s cushion=%s page=%s card=%s rest hp %.1f=%s (nearest foe %.1f, Lv%d) by day=%s saved=%s float taken back=%s new round=%s" % [quiet, hint, blocks, seen, woke, pack1, pack2, out, once, bori, dam, day, floated, lit, flows, snags_ok, str(counts), held, hushed, landed, silent, after, cushion, page, card, hp_night, rested, near_foe, main.player.lv, by_day, kept, taken, round_ok])
	if want.call("quarters"):
		# 달지기 숙소 (DESIGN.md): the knight's spring, the clockwork door, the six bricks once, the doorkeeper wound and
		# seen to the bunk room past the heaps' bits, the ledger, the buckler's wider flash guard, the chest, saves and a
		# new round. State is set directly and waits poll (slow machines); everything changed here is put back at the end
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		var keep := {"castle_q": main.castle_q, "hill_q": main.hill_q, "step": main.story_step, "hour": main.hour,
			"pips": main.crown_pips, "max": main.player.max_hp, "q": main.quarters_q, "box": main.quarters_box,
			"buckler": main.has_buckler, "again": main.quarters_again, "tally": main.tally_seen}
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_house = -1
		main.hill_q = 3
		main.castle_q = 3
		main.hour = 13.0 # by day: resting by the quarters' lamps fills no pips here
		main.story_step = maxi(main.story_step, 10)
		main.enter_castle()
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		knock_quarters()
		main.load_quarters({})
		main.quarters_spawned = false
		main.stand_seen = false
		main.tally_seen = false
		var at_mark := func(p: Vector2) -> bool: # the gold "!" over p, shown
			var tg: Vector3 = main.quarters_target()
			return tg != Vector3.INF and Vector2(tg.x, tg.z).distance_to(p) < 0.1 and main.quarters_mark != null and main.quarters_mark.visible
		var no_mark := func() -> bool:
			return main.quarters_target() == Vector3.INF and (main.quarters_mark == null or not main.quarters_mark.visible)
		var mark_none0: bool = no_mark.call()
		# 1. the door shut, the castle's own foes as before, the spring where the knight knelt
		reset_to(Vector2(465, 14))
		await wait(0.1)
		var shut: bool = main.castle.char_at(465, 22) == "Q" and not main.player_can(465, 22) and main.castle.foes.size() == 8 \
			and quarter_foes().is_empty() and main.castle.spring_node.visible
		# 2. E at the door: only a toast; E at the spring; then the door opens
		reset_to(Vector2(465, 21))
		main.crown_key()
		await wait(0.1)
		var toast_only: bool = main.quarters_q == 0 and not main.story_open and not main.player_can(465, 22)
		reset_to(main.castle.marks.K + Vector2(0.5, 0.6))
		main.crown_key()
		await wait(0.1)
		var spring: bool = main.quarters_q == 1 and main.story_open and not main.castle.spring_node.visible
		main.close_story()
		await wait(0.3)
		reset_to(Vector2(465, 21))
		main.crown_key()
		await wait(0.1)
		var opened: bool = main.quarters_q == 2 and main.player_can(465, 22) and main.player_can(465, 24)
		main.close_story()
		await wait(0.6)
		# 3. into the dining hall: six bricks (2 goblins, a shield goblin, an archer, 2 bats), once
		reset_to(Vector2(465, 28))
		main.player.inv = 120.0
		hold_mates()
		await wait_for(func(): return quarter_foes().size() == 6, 2.0)
		var qf: Array = quarter_foes()
		var six: bool = qf.size() == 6 and qf.all(func(e): return e.cave) and qf.filter(func(e): return e.get("bat", false)).size() == 2 \
			and qf.filter(func(e): return e.get("archer", false)).size() == 1 and qf.filter(func(e): return e.has("shield")).size() == 1
		var told: bool = main.story_open
		main.close_story()
		await wait(0.3)
		reset_to(Vector2(465, 21))
		await wait(0.3)
		reset_to(Vector2(465, 28))
		main.player.inv = 120.0
		hold_mates()
		await wait(0.5)
		var once: bool = quarter_foes().size() == 6
		var left_q: int = quarter_foes().size()
		knock_quarters()
		# the "!" (GPT playtest): the tally board until read, then the stand
		var mkq: Dictionary = main.castle.marks
		var mark_board: bool = at_mark.call(mkq.m)
		reset_to(mkq.m + Vector2(0, 0.8))
		main.crown_key()
		await wait(0.1)
		var mark_read: bool = main.story_open and main.tally_seen
		main.close_story()
		await wait(0.3)
		var mark_stand: bool = at_mark.call(mkq.k)
		# 4. the stand: its lines, then the crown winds him (1 pip); with no pip nothing changes
		main.crown_pips = 0
		reset_to(Vector2(447, 36))
		main.crown_key()
		await wait(0.1)
		var stand: bool = main.story_open and main.stand_seen
		main.close_story()
		await wait(0.3)
		var no_pip: bool = main.quarters_q == 2 and not main.doll_walk
		main.crown_pips = 1
		main.crown_key()
		await wait(0.1)
		var wound: bool = main.quarters_q == 3 and main.crown_pips == 0 and main.doll_walk and main.story_open
		main.close_story()
		await wait(1.0)
		var walks: bool = main.doll_at.distance_to(main.CASTLE.DOLL_PATH[0]) > 0.5
		var mark_walk: bool = at_mark.call(main.doll_at) # the gold ! follows him while he walks (v0.1.69)
		# 5. in the dining hall the heaps' three bits run at him; one that reaches him knocks his spring out
		main.doll_at = Vector2(456.3, 30.1)
		main.doll_i = 5
		reset_to(Vector2(457, 33))
		main.player.inv = 120.0
		await wait_for(func(): return main.doll_bits().size() == 3, 2.0)
		var bits: Array = main.doll_bits()
		var three: bool = bits.size() == 3 and bits.all(func(e): return e.shard and e.cave)
		if not bits.is_empty():
			bits[0].x = main.doll_at.x
			bits[0].z = main.doll_at.y
		await wait_for(func(): return not main.doll_walk, 1.0)
		var knocked: bool = not main.doll_walk and main.doll_bits().is_empty() and main.castle.doll_drop != null and main.castle.doll_drop.visible
		await wait(0.1)
		var mark_doll: bool = at_mark.call(main.doll_at)
		var pips_k: int = main.crown_pips
		reset_to(main.doll_at + Vector2(0.8, 0.6))
		main.player.inv = 120.0
		main.crown_key()
		await wait_for(func(): return main.doll_bits().size() == 3, 2.0)
		var rewalk: bool = main.doll_walk and main.crown_pips == pips_k and main.doll_bits().size() == 3
		knock_quarters()
		# 6. too far behind and he waits; beside him he walks to the bunk room door and it opens
		reset_to(Vector2(445, 28))
		await wait(0.3)
		var d0: Vector2 = main.doll_at
		await wait(1.0)
		var waits: bool = main.doll_wait and main.doll_at.distance_to(d0) < 0.01
		reset_to(main.doll_at + Vector2(1.0, 1.0))
		main.player.inv = 120.0
		await wait_for(func(): return main.quarters_q == 4, 25.0)
		var bunk: bool = main.quarters_q == 4 and main.player_can(462, 34) and main.story_open
		main.close_story()
		await wait(2.0)
		var mark_log: bool = at_mark.call(mkq.o)
		# 7. the ledger and her name are one beat, then he sits and gives the buckler; the toast comes after a hush
		reset_to(Vector2(461, 36))
		main.crown_key()
		await wait(0.1)
		var signed: bool = main.story_open and main.story_lines == STORY.QUARTERS_LOG.slice(1)
		main.close_story()
		await wait_for(func(): return main.quarters_q == 5, 1.0)
		var sat: bool = main.quarters_q == 5 and main.has_buckler and main.castle.ledger_name.visible \
			and not main.castle.doll.get_node("body/buckler").visible and main.story_open
		main.close_story()
		await wait(0.8)
		var hushed: bool = not main.ui.toast.text.begins_with("작은 놋 방패")
		var mark_done: bool = no_mark.call()
		var marks_ok: bool = mark_none0 and mark_board and mark_read and mark_stand and mark_walk and mark_doll and mark_log and mark_done
		if not marks_ok:
			print("TEST note quarters marker: none=%s board=%s read=%s stand=%s walking=%s doll=%s ledger=%s done=%s" % [mark_none0, mark_board, mark_read, mark_stand, mark_walk, mark_doll, mark_log, mark_done])
		await wait(1.4)
		var toasted: bool = main.ui.toast.text.begins_with("작은 놋 방패")
		# the buckler: a flash guard 0.15 s after raising the guard counts with it, and is a plain block without it
		var foe := {"stun": 0.0}
		reset_to(Vector2(461, 36))
		main.player.face = Vector2(1, 0)
		main.guarding = true
		main.guard_since = main.t - 0.15
		var r1: String = main.player_hit(10, Vector2(main.player.x + 1, main.player.z), foe)
		main.player.inv = 0.0
		main.has_buckler = false
		main.guard_since = main.t - 0.15
		var r2: String = main.player_hit(10, Vector2(main.player.x + 1, main.player.z), foe)
		main.guarding = false
		main.has_buckler = true
		var guard_ok: bool = r1 == "flash_guard" and r2 == "guard"
		await wait(0.3)
		# 8. the chest: max HP +10, 2 potions, 80 gold
		var mx: int = main.player.max_hp
		var pots: int = main.player.pots
		var gold: int = main.player.gold
		reset_to(Vector2(467, 37))
		main.crown_key()
		await wait(0.1)
		var chest: bool = main.quarters_box and main.player.max_hp == mx + 10 and main.player.pots == pots + 2 and main.player.gold == gold + 80
		main.close_story()
		await wait(0.3)
		# 9. saves keep it; a save made mid-walk loads with him by his stand; a new round keeps only the buckler
		main.save_game()
		main.load_quarters(JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH)))
		await wait(0.1)
		var kept: bool = main.quarters_q == 5 and main.quarters_box and main.castle.quarters_open and main.castle.bunk_open and main.has_buckler
		main.quarters_q = 3
		main.doll_walk = true
		main.doll_at = Vector2(458, 31)
		main.save_game()
		reset_to(Vector2(460, 31))
		main.load_quarters(JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH)))
		await wait(0.3)
		var mid: bool = main.quarters_q == 3 and not main.doll_walk and main.doll_at == Vector2(458, 31) \
			and main.doll_bits().is_empty() and not main.castle.bunk_open
		main.write_new_round()
		var ng = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var round_ok: bool = ng != null and not ng.has("quarters_q") and bool(ng.get("has_buckler", false))
		main.load_quarters(ng)
		await wait(0.1)
		round_ok = round_ok and main.quarters_q == 0 and not main.castle.quarters_open and main.castle.spring_node.visible and main.has_buckler and main.quarters_again
		main.quarters_q = 4 # next round in his chair: a wave of the key hand, and he keeps his buckler
		main.doll_at = Vector2(463, 36)
		reset_to(Vector2(461, 36))
		main.crown_key()
		await wait(0.1)
		main.close_story()
		await wait_for(func(): return main.quarters_q == 5, 1.0)
		round_ok = round_ok and plain(main.ui.story_text.text) == tr(String(STORY.QUARTERS_REST_AGAIN).split("|")[2]) \
			and main.castle.doll.get_node("body/buckler").visible
		main.close_story()
		await wait(1.8)
		# leave it as it was for the other tests
		knock_quarters()
		main.clear_quarters_job()
		main.load_quarters({"quarters_q": keep.q, "quarters_box": keep.box, "has_buckler": keep.buckler, "quarters_again": keep.again})
		main.quarters_spawned = false
		main.tally_seen = keep.tally
		main.castle_q = keep.castle_q
		main.castle.set_spring(keep.castle_q >= 3 and keep.q == 0)
		main.hill_q = keep.hill_q
		main.story_step = keep.step
		main.hour = keep.hour
		main.crown_pips = keep.pips
		main.player.max_hp = keep.max
		main.player.hp = float(keep.max)
		main.in_hill = false
		calm_enemies(false)
		main.save_game()
		check("quarters", shut and toast_only and spring and opened and six and told and once and marks_ok and stand and no_pip and wound and walks and three and knocked and rewalk and waits and bunk and signed and sat and hushed and toasted and guard_ok and chest and kept and mid and round_ok,
			"shut=%s toast only=%s spring=%s opened=%s six=%s told=%s once=%s (%d left, Lv%d) marker=%s stand=%s no pip=%s wound 1 pip=%s walks=%s bits 3=%s knocked=%s E walks on=%s waits=%s bunk open=%s ledger=%s sat+buckler=%s hush=%s toast=%s guard %s/%s=%s chest=%s saved=%s mid-walk load=%s new round=%s" % [shut, toast_only, spring, opened, six, told, once, left_q, main.player.lv, marks_ok, stand, no_pip, wound, walks, three, knocked, rewalk, waits, bunk, signed, sat, hushed, toasted, r1, r2, guard_ok, chest, kept, mid, round_ok])
	if want.call("oak"):
		# 다람쥐 나무 (DESIGN.md): the big squirrel by the gap once the squirrels are free and the gate is open, the gap,
		# the clearing's lines once, resting by the oak by day, three knots (1 pip each, the hedgehogs after the second),
		# the 1.5 s hush, the sprout's 75, saves and a new round. Everything changed here is put back at the end
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		var keep := {"night_q": main.night_q, "lake_q": main.lake_q, "forest_q": main.forest_q, "hollow_q": main.hollow_q,
			"acorn": main.has_acorn, "q": main.oak_q, "knots": main.forest.knots.map(func(k): return k.open), "sprout": main.has_sprout,
			"hour": main.hour, "pips": main.crown_pips, "tea": main.has_tea, "lv": main.player.lv, "xp": main.player.xp,
			"atk": main.player.atk, "max": main.player.max_hp, "gold": main.player.gold, "pots": main.player.pots,
			"v": main.in_village, "f": main.in_forest, "l": main.in_lake, "h": main.in_hill, "g": main.in_garden, "c": main.in_cave,
			"x": main.player.x, "z": main.player.z}
		main.in_village = false
		main.in_lake = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		main.in_house = -1
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 3
		main.hollow_q = 0 # entering with the gate shut keeps the valley asleep for the hollow test
		main.has_acorn = false
		main.has_tea = false
		main.hour = 12.0
		main.load_oak({})
		main.enter_forest()
		main.hollow_q = 1
		await wait(0.2)
		main.close_story()
		calm_enemies(true)
		# 1. no acorn: no big squirrel; with it, he sits by the shut gap
		var none: bool = main.big_squirrel == null or not main.big_squirrel.visible
		main.has_acorn = true
		main.place_big_squirrel()
		var sq: Node3D = main.big_squirrel
		var waits: bool = sq != null and sq.visible and Vector2(sq.position.x, sq.position.z).distance_to(Vector2(195, 12)) < 0.1 \
			and not main.player_can(196, 12) and main.hint_open("oak")
		# 2. E beside him: his lines, then the gap opens
		reset_to(Vector2(195.5, 12))
		main.crown_key()
		await wait(0.1)
		var call: bool = main.story_open and main.story_lines == STORY.OAK_CALL.slice(1)
		main.close_story()
		await wait_for(func(): return main.oak_q == 1, 1.0)
		var gap: bool = main.oak_q == 1 and main.walkable(196, 12) and main.forest.oak_open
		# 3. into the clearing: its lines once
		reset_to(Vector2(198, 12))
		await wait_for(func(): return main.story_open, 1.0)
		var told: bool = main.story_open and main.story_lines == STORY.OAK_IN.slice(1)
		main.close_story()
		await wait(0.3)
		reset_to(Vector2(196, 12))
		await wait(0.3)
		reset_to(Vector2(198, 12))
		await wait(0.5)
		var once: bool = not main.story_open
		main.close_story()
		# 3b. the companions through the gap (GPT playtest): behind her in single file, then apart in the clearing
		main.join_mate()
		main.join_noeul()
		reset_to(Vector2(192, 12))
		main.snap_mates()
		await wait(0.4)
		var file_ok := false
		var file_seen := false
		var walk_t := 0.0
		while main.player.x < 199.0 and walk_t < 6.0:
			var dt := get_process_delta_time()
			walk_t += dt
			main.player.x = minf(199.0, main.player.x + 4.0 * dt)
			if not file_seen and main.player.x >= 197.6:
				file_seen = true
				file_ok = main.mate.position.x < main.player.x - 0.5 and main.mate2.position.x < main.player.x - 0.5
			await get_tree().process_frame
		await wait(1.5)
		var me3 := Vector3(main.player.x, 0, main.player.z)
		var m1: Vector3 = main.mate.position
		var m2: Vector3 = main.mate2.position
		var d1 := Vector2(m1.x - me3.x, m1.z - me3.z).length()
		var d2 := Vector2(m2.x - me3.x, m2.z - me3.z).length()
		var d12 := Vector2(m1.x - m2.x, m1.z - m2.z).length()
		var apart: bool = file_ok and d1 >= 0.8 and d2 >= 0.8 and d12 >= 0.8 and m1.x > 195.5 and m2.x > 195.5
		if not apart:
			print("TEST note oak follow: file=%s d1=%.2f d2=%.2f d12=%.2f m1=%s m2=%s me=%s" % [file_ok, d1, d2, d12, m1, m2, me3])
		# 4. noon, no pips: by the oak a pip in 3.5 s; by the clearing's lantern (3.5 tiles off) none by day
		main.hour = 12.0
		main.crown_pips = 0
		release()
		reset_to(Vector2(199, 12))
		main.rest_t = 0.0
		await wait(3.5)
		var warm: bool = main.crown_pips >= 1 # 2 when an earlier test left the moonflower tea (1.8 s a pip)
		reset_to(Vector2(204, 12.4))
		main.rest_t = 0.0
		await wait(3.5)
		var lamp_day: bool = main.crown_pips >= 1
		# 5. the west knot (1 pip), the east one (the hedgehogs roll out), the south one waits for them
		main.crown_pips = 8
		main.player.inv = 99.0
		var kn: Array = main.forest.knots
		reset_to(kn[0].pos + Vector2(-0.9, 0))
		main.player.inv = 99.0
		main.crown_key()
		await wait(0.1)
		var west: bool = main.crown_pips == 7 and kn[0].open and main.walkable(199, 10) and main.oak_hogs_alive().is_empty() and main.story_lines == STORY.OAK_KNOT1.slice(1)
		main.close_story()
		await wait(0.2)
		reset_to(kn[1].pos + Vector2(0.9, 0))
		main.player.inv = 99.0
		hold_mates()
		main.crown_key()
		await wait(0.1)
		main.close_story()
		await wait_for(func(): return main.oak_hogs_alive().size() == 2, 2.0)
		var hogs: Array = main.oak_hogs_alive()
		var east: bool = main.crown_pips == 6 and kn[1].open and hogs.size() == 2 and hogs.all(func(e): return e.hog and e.cave)
		reset_to(kn[2].pos + Vector2(0, 0.9))
		main.player.inv = 99.0
		main.crown_key()
		await wait(0.1)
		var held: bool = main.crown_pips == 6 and not kn[2].open and main.oak_q == 1
		# 6. the hedgehogs down: the last knot, the hush, then the lines with the sprout
		for e in hogs:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
		var mx: int = main.player.max_hp
		var gold: int = main.player.gold
		var lv0: int = main.player.lv
		main.crown_key()
		await wait(0.1)
		var green: bool = main.crown_pips == 5 and main.oak_q == 2 and main.has_sprout and main.player.gold == gold + 60 \
			and main.player.max_hp == mx + 10 + 12 * (main.player.lv - lv0)
		await wait(0.6)
		var hushed: bool = not main.story_open and not main.forest.oak_green
		await wait_for(func(): return main.story_open, 2.0)
		var lines: bool = main.story_open and main.story_lines == STORY.OAK_GREEN.slice(1) and main.forest.oak_green \
			and main.oak_kin.all(func(s): return s.visible)
		main.close_story()
		await wait(0.3)
		# 7. a potion heals 75 now
		main.player.hp = float(main.player.max_hp - 100)
		main.player.pots = maxi(main.player.pots, 1)
		main.player.cds[3] = 0.0
		main.drink_potion()
		var pot: bool = absf(main.player.hp - float(main.player.max_hp - 25)) < 0.5
		# 8. saves keep it; a new round keeps only the sprout
		main.save_game()
		main.load_oak(JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH)))
		await wait(0.1)
		var kept: bool = main.oak_q == 2 and main.forest.knots.all(func(k): return k.open) and main.has_sprout and main.walkable(196, 12) and main.forest.oak_green
		main.write_new_round()
		var ng = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var round_ok: bool = ng != null and not ng.has("oak_q") and bool(ng.get("has_sprout", false))
		main.load_oak(ng)
		await wait(0.1)
		round_ok = round_ok and main.oak_q == 0 and main.forest.knots.all(func(k): return not k.open) and main.has_sprout \
			and not main.walkable(196, 12) and not main.forest.oak_green
		# leave it as it was for the other tests
		main.night_q = keep.night_q
		main.lake_q = keep.lake_q
		main.forest_q = keep.forest_q
		main.hollow_q = keep.hollow_q
		main.has_acorn = keep.acorn
		main.load_oak({"oak_q": keep.q, "oak_knots": keep.knots, "has_sprout": keep.sprout})
		main.hour = keep.hour
		main.crown_pips = keep.pips
		main.has_tea = keep.tea
		main.player.lv = keep.lv
		main.player.xp = keep.xp
		main.player.atk = keep.atk
		main.player.max_hp = keep.max
		main.player.hp = float(keep.max)
		main.player.gold = keep.gold
		main.player.pots = keep.pots
		main.in_village = keep.v
		main.in_forest = keep.f
		main.in_lake = keep.l
		main.in_hill = keep.h
		main.in_garden = keep.g
		main.in_cave = keep.c
		reset_to(Vector2(keep.x, keep.z))
		calm_enemies(false)
		main.save_game()
		check("oak", none and waits and call and gap and told and once and apart and warm and lamp_day and west and east and held and green and hushed and lines and pot and kept and round_ok,
			"no acorn=%s waits by the gap=%s call=%s gap open=%s clearing told=%s once=%s mates apart=%s rests by day=%s lantern by day=%s west 1 pip=%s east+hogs=%s south held=%s green+sprout=%s hush=%s lines=%s potion 75=%s saved=%s new round=%s" % [none, waits, call, gap, told, once, apart, warm, lamp_day, west, east, held, green, hushed, lines, pot, kept, round_ok])
	if want.call("trial_repeat"):
		# after the first clear, the trial's foes give nothing (the field is where gold and XP come from)
		var best0: float = main.trial_best
		main.trial_best = 0.0
		main.spawn_enemy(Vector2(main.player.x + 3.0, main.player.z))
		var e1: Dictionary = main.enemies[main.enemies.size() - 1]
		e1.trial = true
		var g0: int = main.player.gold
		main.damage_enemy(e1, 99999.0, Vector2(e1.x - 1.0, e1.z))
		var first_pays: bool = main.player.gold > g0
		main.trial_best = 95.0
		main.spawn_enemy(Vector2(main.player.x + 3.0, main.player.z))
		var e2: Dictionary = main.enemies[main.enemies.size() - 1]
		e2.trial = true
		var g1: int = main.player.gold
		var xp1: int = main.player.xp
		var lv1: int = main.player.lv
		main.damage_enemy(e2, 99999.0, Vector2(e2.x - 1.0, e2.z))
		var later_free: bool = main.player.gold == g1 and main.player.xp == xp1 and main.player.lv == lv1
		main.trial_best = best0
		check("trial_repeat", first_pays and later_free, "before the first clear a trial foe pays=%s after it pays nothing=%s" % [first_pays, later_free])
	if want.call("hush"):
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.muted = false
		release()
		await wait(0.8)
		var said0: int = main.bubbles_said
		main.toggle_sound()
		await wait(0.3)
		var hushing: bool = main.muted and main.idle_name == "see-hush" and main.bubbles_said == said0 + 1
		main.idle_k = 5.0 # well past the fourth drawing, whatever the game clock did on a busy machine
		await wait(0.1)
		var held: bool = main.hero.region_rect.position.x == 3 * main.hero.region_rect.size.x
		main.toggle_sound()
		await wait(0.2)
		var quiet_on: bool = not main.muted and main.bubbles_said == said0 + 1
		check("hush", hushing and held and quiet_on, "sound off: finger to lips and a bubble=%s held on the last frame=%s sound on: no bubble=%s" % [hushing, held, quiet_on])
	if want.call("hollow"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_lake = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 3
		main.hollow_q = 0
		main.has_skip = true
		main.has_unbrick = true
		main.stream_told = true
		main.hour = 12.0
		main.crown_pips = 8
		main.enter_forest()
		main.join_noeul()
		main.close_story()
		calm_enemies(true)
		var fm = main.forest
		var g: Vector2 = fm.marks.G
		var shut: bool = not main.player_can(g.x, g.y)
		var north0: int = main.enemies.filter(func(e): return not e.dead and e.x > 170.0 and e.x < 230.0 and e.z < 21.5).size()
		reset_to(g + Vector2(0, -1.0))
		hold_mates()
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var opened: bool = main.hollow_q == 1 and main.player_can(g.x, g.y)
		var woke: int = main.enemies.filter(func(e): return not e.dead and e.x > 170.0 and e.x < 230.0 and e.z > 21.5).size()
		var north1: int = main.enemies.filter(func(e): return not e.dead and e.x > 170.0 and e.x < 230.0 and e.z < 21.5).size()
		var hogs: Array = main.enemies.filter(func(e): return e.get("hog", false) and not e.dead and e.x > 170.0 and e.x < 230.0) # the forest's own
		calm_enemies(true)
		main.skipping = false
		var dry: bool = not main.player_can(198, 28.5)
		main.skipping = true
		var wet: bool = main.player_can(198, 28.5)
		main.skipping = false
		for l in fm.mem_lamps:
			reset_to(l.pos + Vector2(1.0, 0))
			tap(KEY_E)
			await wait(0.15)
			main.close_story()
		var lit: bool = fm.mem_lamps.all(func(l): return l.lit) and main.crown_pips == 5
		reset_to(fm.marks.C + Vector2(-2.0, 0))
		main.player.inv = 9.0
		await wait(0.3)
		main.close_story()
		await wait(0.2)
		var cloaks: Array = main.enemies.filter(func(e): return e.get("cloak", false) and not e.dead)
		var big: bool = cloaks.size() == 1 and cloaks[0].max_hp == 2200
		if cloaks.size() == 1:
			main.damage_enemy(cloaks[0], 100000.0, Vector2(main.player.x, main.player.z))
			await wait(1.4)
		main.close_story()
		var beaten: bool = main.hollow_q == 2
		var curled := false
		var hit := false
		if hogs.size() > 0:
			var h: Dictionary = hogs[0]
			h.curl = 0.5
			var hp0: float = h.hp
			main.damage_enemy(h, 30.0, Vector2(h.x - 1.0, h.z))
			curled = h.hp == hp0
			h.curl = 0.0
			main.damage_enemy(h, 30.0, Vector2(h.x - 1.0, h.z))
			hit = h.hp < hp0
		main.crown_pips = 8
		var d1: Dictionary = fm.doors[1]
		reset_to(d1.pos + Vector2(0, -1.0))
		tap(KEY_E)
		await wait(0.15)
		var door: bool = d1.open and main.player_can(d1.pos.x, d1.pos.y) and main.crown_pips == 8 - main.unbrick_cost()
		reset_to(d1.pos + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var lantern: bool = main.hollow_q == 3 and fm.boxes[1].open
		var saved = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = saved != null and int(saved.get("hollow_q", 0)) == 3 and saved.get("mem_lit", []) == [true, true, true] and saved.get("hollow_doors", []) == [false, true, false]
		calm_enemies(false)
		main.in_forest = false
		main.in_village = true
		var hp1: int = main.player.max_hp
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var given: bool = main.hollow_q == 4 and main.player.max_hp == hp1 and main.pip_awards.has("lantern") and main.thirteenth != null and not main.thirteenth.get_meta("dark", false) # v0.0.47: a pip in place of max HP +15
		check("hollow", shut and opened and woke == fm.south.size() and north1 == north0 and hogs.size() == 2 and dry and wet and lit and big and beaten and curled and hit and door and lantern and kept and given,
			"gate shut/opened=%s/%s woke=%d of %d north unchanged=%s hogs=%d stream dry/skip=%s/%s three memories (pips 5)=%s cloak 2200=%s beaten=%s curled blocks=%s dizzy hits=%s sunset door=%s lantern=%s saved=%s Simji=%s (hollow_q %d, max HP %d -> %d, awards %s)" % [shut, opened, woke, fm.south.size(), north1 == north0, hogs.size(), dry, wet, lit, big, beaten, curled, hit, door, lantern, kept, given, main.hollow_q, hp1, main.player.max_hp, str(main.pip_awards.keys())])
		main.hour = 12.0
		reset_to(main.village.marks.M + Vector2(-1.2, 0))
	if want.call("undercroft"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.castle_q = 3
		main.has_skip = true
		main.has_unbrick = true
		main.hour = 12.0
		main.crown_pips = 8
		main.enter_castle()
		main.close_story()
		reset_to(main.UNDER_STAIR + Vector2(1.0, 0)) # walk onto the stair in the great hall
		hold_world(Vector2(-1, 0))
		await wait(0.4)
		release()
		await wait(1.2)
		main.close_story()
		var down_in: bool = main.in_under()
		calm_enemies(true)
		var ux: float = main.UNDER.UNDER_X
		var flooded: bool = not main.player_can(ux + 15, 9)
		reset_to(Vector2(ux + 7.6, 4.0)) # skip east over the channel
		main.player.sp = 100.0
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.4) # room for a busy machine
		release()
		var skipped: bool = main.player.x > ux + 11.6
		reset_to(Vector2(ux + 22.4, 17.0)) # onto the vent, which blows west over the drop
		hold_world(Vector2(-1, 0))
		await wait(1.8)
		release()
		await wait(0.1)
		var blown: bool = main.player.x < ux + 12.6 and main.gust_dir == Vector2.ZERO
		reset_to(Vector2(ux + 19.5, 2.3))
		var pips0: int = main.crown_pips
		tap(KEY_E)
		await wait(0.1)
		var drained: bool = main.under.drained and main.player_can(ux + 15, 9) and main.crown_pips == pips0 - main.unbrick_cost()
		var told: bool = main.ui.toast.text.contains("8초")
		var tg: Vector3 = main.step_target()
		var marked: bool = tg != Vector3.INF and main.quarters_mark != null and main.quarters_mark.visible and main.under.lamps.any(func(l): return not l.lit and Vector2(tg.x, tg.z).distance_to(l.pos) < 0.1)
		var l0: Dictionary = main.under.lamps[0]
		reset_to(l0.pos + Vector2(0, 1.2))
		tap(KEY_E)
		await wait(0.1)
		var one: bool = main.under.lamps_lit() == 1
		main.under.lamp_clock = 0.05
		await wait(0.2)
		var out: bool = one and main.under.lamps_lit() == 0
		for l in main.under.lamps:
			reset_to(l.pos + Vector2(0, 1.2))
			tap(KEY_E)
			await wait(0.1)
		var door: bool = main.under.door_open and main.player_can(ux + 4.5, 13)
		var unmarked: bool = main.step_target() == Vector3.INF and not main.quarters_mark.visible
		reset_to(Vector2(ux + 4.5, 11.0))
		await wait(0.3)
		var guards: bool = main.under_guards.size() == 2 and not main.player_can(ux + 4.5, 13)
		for e in main.under_guards.duplicate():
			main.damage_enemy(e, 99999.0, Vector2(e.x, e.z + 1.0))
		await wait(0.3)
		var won: bool = main.under_guards_done and main.player_can(ux + 4.5, 13)
		var hp0: int = main.player.max_hp
		var atk0: int = main.player.atk
		reset_to(main.under.marks.c + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.1)
		main.close_story()
		var chest: bool = main.has_lamp and main.player.max_hp == hp0 + 20 and main.player.atk == atk0 + 3
		var saved = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = saved != null and bool(saved.get("under_chest", false)) and bool(saved.get("under_drained", false))
		reset_to(main.under.marks.U + Vector2(0.8, 0))
		hold_world(Vector2(-1, 0))
		await wait(0.3)
		release()
		await wait(1.2)
		var back: bool = main.in_castle()
		calm_enemies(false)
		check("undercroft", skipped and blown and down_in and flooded and drained and out and door and guards and won and chest and kept and back and told and marked and unmarked,
			"skip=%s vent=%s stair down=%s flooded/drained=%s/%s lamps go out after 8 s=%s four lamps open the door=%s guardians shut it=%s beaten=%s chest +20/+3=%s saved=%s way back up=%s goal toast=%s ! over an unlit lamp=%s gone with the door=%s" % [skipped, blown, down_in, flooded, drained, out, door, guards, won, chest, kept, back, told, marked, unmarked])
	if want.call("village_market"):
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.in_house = -1
		main.in_village = true
		main.errand = maxi(main.errand, 1)
		calm_enemies(true)
		var vx: float = main.VILLAGE.VILLAGE_X
		var big: bool = main.VILLAGE.W == 48 and main.VILLAGE.H == 36 and main.walkable(vx + 40, 10) and main.walkable(vx + 16, 30) and not main.walkable(vx + 30, 27)
		main.player.gold = 200
		main.magpie_q = 0
		reset_to(main.village.marks["1"] + Vector2(0, 0.6))
		main.player.hp = 20.0 # reset_to heals her
		tap(KEY_E) # the first E at a stall reads the market's note instead
		await wait(0.1)
		var note: bool = main.story_open and main.magpie_q == 1
		main.close_story()
		await wait(0.1)
		tap(KEY_E)
		await wait(0.1)
		var apple: bool = main.player.hp >= 59.0 and main.player.gold == 195
		var apple_note := "hp %.0f gold %d at %s" % [main.player.hp, main.player.gold, str(Vector2(main.player.x - vx, main.player.z))]
		reset_to(main.village.marks.Q + Vector2(0, 1.2))
		tap(KEY_E)
		await wait(0.1)
		var started: bool = main.target_on
		for i in 6:
			main.spawn_target()
			var tg: Dictionary = main.enemies[main.enemies.size() - 1]
			main.damage_enemy(tg, 10.0, Vector2(tg.x, tg.z + 1.0))
		main.target_left = 0.05
		await wait(0.3)
		main.close_story()
		var medal: bool = started and not main.target_on and main.has_medal and main.target_best >= 6
		main.hour = 22.0
		reset_to(main.village.marks.N + Vector2(0, 0.6))
		main.player.hp = 30.0
		tap(KEY_E)
		await wait(1.4)
		main.close_story()
		var slept: bool = absf(main.hour - 7.0) < 0.2 and main.player.hp >= main.player.max_hp and main.player.gold == 185
		var g0: int = main.player.gold
		for b in main.village.bottles:
			main.pick_bottle(b)
			main.close_story()
		await wait(0.3)
		var letters: bool = main.village.bottles_got() == 3 and main.player.gold == g0 + 120
		reset_to(main.village.marks.f)
		tap(KEY_E)
		await wait(0.1)
		var fishing: bool = main.fish_state == "wait"
		tap(KEY_E)
		calm_enemies(false)
		# the magpie: at night it flies ahead perch by perch, to its nest on the pond; the moon lantern ends it
		main.hour = 22.0
		main.magpie_at = 0
		main.place_magpie()
		var perches: Array = main.magpie_perches()
		for k in 3:
			var pp: Vector3 = perches[k]
			reset_to([Vector2(pp.x, pp.y + 1.5), Vector2(pp.x, pp.y - 1.5), main.village.marks.f][k])
			await wait(1.6)
		var flew: bool = main.magpie_at == 3
		var np: Vector3 = perches[3]
		main.player.x = np.x - 0.8 # out on the water, as if she skipped there
		main.player.z = np.y
		main.update_magpie(0.01)
		await wait(0.1)
		var nest: bool = main.magpie_q == 2
		main.close_story()
		reset_to(main.village.marks.f)
		main.crown_pips = 8
		var g1: int = main.player.gold
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var lamp: bool = main.magpie_q == 3 and main.player.gold == g1 + 100 and main.crown_pips == 6
		check("village_market", note and flew and nest and lamp and big and apple and medal and slept and letters and fishing,
			"note=%s magpie flew to its nest=%s found it=%s moon lantern=%s 48x36=%s apple stall=%s target medal=%s inn night=%s three bottles=%s pier fishing=%s (%s)" % [note, flew, nest, lamp, big, apple, medal, slept, letters, fishing, apple_note])
	if want.call("moon_stairs"):
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.castle_q = 3
		main.garden_q = 0
		main.has_skip = true
		main.crown_pips = 8
		main.stairs.wall_open = false
		for n in main.stairs.wall_nodes:
			n.visible = true
		main.stairs.door_open = false
		main.stairs.door.visible = true
		for l in main.stairs.lamps:
			l.lit = false
		main.enter_stairs()
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		var sx: float = main.STAIRS.STAIRS_X
		var shut: bool = not main.player_can(sx + 11, 24)
		reset_to(Vector2(sx + 11.5, 25.4))
		tap(KEY_E)
		await wait(0.1)
		var wall: bool = main.stairs.wall_open and main.player_can(sx + 11, 24)
		reset_to(Vector2(sx + 11.5, 19.6)) # skip north over the channel
		main.player.sp = 100.0
		hold_world(Vector2(0, -1))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.4) # room for a busy machine
		release()
		var skipped: bool = main.player.z < 15.6
		reset_to(Vector2(sx + 11, 12.4)) # onto the vent, which blows north over the drop
		hold_world(Vector2(0, -1))
		await wait(1.6)
		release()
		await wait(0.1)
		var blown: bool = main.player.z < 6.6 and main.gust_dir == Vector2.ZERO
		for l in main.stairs.lamps:
			reset_to(l.pos + Vector2(0, 1.2))
			tap(KEY_E)
			await wait(0.1)
		main.close_story()
		var door: bool = main.stairs.door_open and main.player_can(sx + 11, 2) \
			and plain(main.ui.quest.text) == main.tr(main.STAIRS_DONE_QUEST) # the top door, not the mold's heart yet
		main.road_q = 4
		reset_to(main.stairs.marks.N + Vector2(0, 0.3))
		await wait(1.5)
		var garden: bool = main.in_garden
		main.close_story()
		main.in_garden = false
		main.in_hill = false
		calm_enemies(false)
		check("moon_stairs", shut and wall and skipped and blown and door and garden, "wall shut/opened=%s/%s skipped the channel=%s vent carried her up=%s three lamps open the door=%s top leads to the garden=%s" % [shut, wall, skipped, blown, door, garden])
	if want.call("workshop"):
		# 달지기 작업장 (DESIGN.md 깊은 작업장): the door, three floors, their puzzles, the waystones, the cradle, Simji, save/load
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		main.in_house = -1
		main.in_hill = true
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 3
		main.hill_q = 3
		main.join_mate()
		main.join_noeul()
		main.has_skip = true
		main.has_unbrick = true
		main.hour = 12.0
		main.castle_q = 2 # the knight still stands
		main.enter_castle()
		main.close_story()
		calm_enemies(true)
		var ws = main.workshop_zone
		var door: Vector2 = main.WORK_DOOR
		main.castle_q = 0 # v0.1.68: bricked only before the castle was entered; after that the door answers, knight or not
		ws.door_look()
		reset_to(door + Vector2(0, 0.9))
		tap(KEY_E)
		await wait(0.1)
		reset_to(door)
		await wait(0.6)
		var shut: bool = not main.work_door and not main.in_workshop()
		main.castle_q = 3
		ws.door_look()
		reset_to(door + Vector2(-2.5, 2.0))
		await wait(0.3)
		var seen: bool = main.work_seen and main.story_open
		main.close_story()
		reset_to(door + Vector2(0, 0.9))
		main.crown_pips = 8
		tap(KEY_E)
		await wait(0.1)
		var opened: bool = main.work_door and main.crown_pips == 8
		main.close_story()
		reset_to(door)
		var down: bool = await wait_for(func(): return main.in_workshop(), 3.0)
		await wait(0.2)
		var b1 = main.wfloors[0]
		down = down and Vector2(main.player.x, main.player.z).distance_to(b1.marks.A) < 0.3 and main.work_q == 1
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		# B1: two work lamps (1 pip each, each wakes two bricks), the planks, the plug
		var ox0: float = main.WORK.FLOOR_X[0]
		var planks_shut: bool = not main.player_can(ox0 + 12, 10)
		var n0: int = main.enemies.size()
		var l0: Dictionary = b1.lamps[0]
		main.crown_pips = 8
		reset_to(l0.pos + Vector2(1.0, -1.0))
		tap(KEY_E)
		await wait(0.1)
		var lamp1: bool = b1.lamps_lit() == 1 and main.crown_pips == 7 and main.enemies.size() == n0 + 2 and not main.player_can(ox0 + 12, 10)
		calm_enemies(true)
		var l1: Dictionary = b1.lamps[1]
		reset_to(l1.pos + Vector2(-1.0, -1.0))
		tap(KEY_E)
		await wait(0.1)
		var planks: bool = planks_shut and b1.lamps_lit() == 2 and main.player_can(ox0 + 12, 10) and main.player_can(ox0 + 15, 13)
		calm_enemies(true)
		main.crown_pips = 8
		reset_to(Vector2(ox0 + 15, 14))
		tap(KEY_E)
		await wait(0.1)
		var plug: bool = main.work_q == 2 and main.work_ways[0] and main.player_can(ox0 + 15, 16) and main.crown_pips == 8 - main.unbrick_cost()
		reset_to(Vector2(ox0 + 18, 14))
		tap(KEY_E)
		await wait(0.1)
		var tag: bool = main.work_reads[0] and main.story_open
		main.close_story()
		reset_to(b1.marks.V)
		var to2: bool = await wait_for(func(): return main.in_workshop() and ws.floor_here() == 1, 3.0)
		await wait(0.2)
		var b2 = main.wfloors[1]
		to2 = to2 and Vector2(main.player.x, main.player.z).distance_to(b2.marks.A) < 0.3
		main.close_story()
		await wait(0.1)
		reset_to(b2.marks.S) # up again: beside B1's way down
		var up1: bool = await wait_for(func(): return main.in_workshop() and ws.floor_here() == 0, 3.0)
		await wait(0.2)
		up1 = up1 and Vector2(main.player.x, main.player.z).distance_to(b1.marks.U) < 0.3
		reset_to(b1.marks.V)
		await wait_for(func(): return main.in_workshop() and ws.floor_here() == 1, 3.0)
		await wait(0.2)
		main.close_story()
		calm_enemies(true)
		# B2: the lid covers the stopper until Mulgyeol pulls the chain; the stopper drains the channel
		var ox1: float = main.WORK.FLOOR_X[1]
		var flooded: bool = not main.player_can(ox1 + 10, 12)
		main.crown_pips = 8
		reset_to(Vector2(ox1 + 8, 10))
		tap(KEY_E)
		await wait(0.1)
		var covered: bool = main.crown_pips == 8 and not b2.drained
		reset_to(Vector2(ox1 + 6, 9))
		tap(KEY_E)
		await wait(0.1)
		var pulling: bool = main.mate_job.get("kind", "") == "work"
		var lid: bool = await wait_for(func(): return main.work_pulled, 6.0)
		lid = lid and main.player_can(ox1 + 6, 10)
		reset_to(Vector2(ox1 + 6, 10))
		main.crown_pips = 8
		tap(KEY_E)
		await wait(0.1)
		var drained: bool = flooded and main.work_q == 3 and main.player_can(ox1 + 10, 12) and main.work_ways[1]
		reset_to(Vector2(ox1 + 27, 4))
		tap(KEY_E)
		await wait(0.1)
		var handle: bool = main.work_reads[1]
		main.close_story()
		reset_to(b2.marks.V)
		var to3: bool = await wait_for(func(): return main.in_workshop() and ws.floor_here() == 2, 3.0)
		await wait(0.2)
		var b3 = main.wfloors[2]
		to3 = to3 and Vector2(main.player.x, main.player.z).distance_to(b3.marks.A) < 0.3
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		# B3: a fragment is marked where she stands in the cracked hall; two clamps open the pit door
		var ox2: float = main.WORK.FLOOR_X[2]
		var shut3: bool = not main.player_can(ox2 + 11, 12)
		reset_to(Vector2(ox2 + 10, 3))
		ws.frag_t = 0.0
		await wait(0.15)
		var frag: bool = not ws.frags.is_empty()
		ws.frags.clear()
		main.crown_pips = 8
		reset_to(Vector2(ox2 + 2, 7.5))
		tap(KEY_E)
		await wait(0.1)
		var clamp1: bool = b3.groups_open() == 1 and not main.player_can(ox2 + 11, 12)
		calm_enemies(true)
		main.crown_pips = 8
		reset_to(Vector2(ox2 + 23, 9.5))
		tap(KEY_E)
		await wait(0.1)
		var clamps: bool = shut3 and b3.groups_open() == 2 and main.player_can(ox2 + 11, 12) and main.work_q == 4 and main.work_ways[2]
		calm_enemies(true)
		reset_to(Vector2(ox2 + 21, 5))
		tap(KEY_E)
		await wait(0.1)
		var scratch: bool = main.work_reads[2]
		main.close_story()
		# the waystones: B3's stone to the castle gate, the gate's stone back to B3
		reset_to(b3.marks.Y + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.1)
		var listed: bool = main.way_open
		tap(KEY_6)
		var out_castle: bool = await wait_for(func(): return main.in_castle(), 3.0)
		await wait(0.2)
		reset_to(main.way_spot(5) + Vector2(0, 1.0))
		tap(KEY_E)
		await wait(0.1)
		tap(KEY_8)
		var back3: bool = await wait_for(func(): return main.in_workshop(), 3.0)
		await wait(0.2)
		back3 = back3 and ws.floor_here() == 2 and Vector2(main.player.x, main.player.z).distance_to(b3.marks.Y + Vector2(0, 1.2)) < 0.3
		calm_enemies(true)
		# the cradle: its story, a latch, a sweep that hurts but undoes nothing, the other two latches, the release
		var o: Vector2 = b3.marks.O
		reset_to(o + Vector2(0, -4.0))
		await wait(0.2)
		var cradle_in: bool = main.work_cradle_seen and main.story_open
		main.close_story()
		await wait(0.1)
		main.crown_pips = 8
		var lp0: Vector2 = b3.latches[0].pos
		reset_to(lp0 + (o - lp0).normalized() * 1.0)
		ws.arm_i = 1
		ws.arm_phase = "rest"
		ws.arm_t = 5.0
		tap(KEY_E)
		await wait(0.1)
		var latch1: bool = main.work_latch[0] and main.crown_pips == 7
		var lp1: Vector2 = b3.latches[1].pos
		reset_to(o + (lp1 - o).normalized() * 3.0)
		var hp0: float = main.player.hp
		ws.arm_i = 0
		ws.arm_phase = "rest"
		ws.arm_t = 0.01
		await wait(2.0)
		var swept: bool = main.player.hp < hp0 and main.work_latch[0] and b3.latches_wound() == 1 and main.work_q == 4
		var swept_note := "hp %.0f -> %.0f" % [hp0, main.player.hp]
		for k in [1, 2]:
			var lp: Vector2 = b3.latches[k].pos
			reset_to(lp + (o - lp).normalized() * 1.0)
			ws.arm_i = (k + 1) % 3
			ws.arm_phase = "rest"
			ws.arm_t = 5.0
			main.crown_pips = 8
			tap(KEY_E)
			await wait(0.1)
		var latches: bool = b3.latches_wound() == 3
		var max0: int = main.player.max_hp
		reset_to(o + Vector2(0, -1.5))
		tap(KEY_E)
		await wait(0.1)
		var released: bool = main.work_q == 5 and main.player.max_hp == max0 + 10
		main.close_story()
		await wait(0.1)
		var once: bool = not ws.give_reward() and main.player.max_hp == max0 + 10
		# Simji takes the lantern; the bench and the villagers' new lines
		main.in_hill = false
		main.errand = maxi(main.errand, 1)
		if main.hollow_q == 3:
			main.hollow_q = 4
		main.enter_village()
		main.close_story()
		calm_enemies(true)
		reset_to(main.village.marks.M + Vector2(0, 1.2))
		tap(KEY_E)
		await wait(0.1)
		var simji: bool = main.work_q == 6 and ws.bench.visible
		main.close_story()
		var chat_n := 0
		for id in ["simji", "doran", "kongal", "darae"]:
			if main.chatter.folk_chat_lines(id).any(func(l): return String(l).begins_with("수리대")):
				chat_n += 1
		var chat: bool = chat_n >= 3
		# save and load on every floor: back at that floor's arrival tile, companions beside her
		var loads_ok := true
		var load_note := ""
		for i in 3:
			ws.enter_floor(i, "A")
			main.close_story()
			var fi = main.wfloors[i]
			reset_to(fi.marks.A + Vector2(2.0, 1.0))
			main.save_game()
			main.in_hill = false
			main.player.x = 15.0
			main.player.z = 15.0
			main.load_game()
			await wait(0.3)
			main.close_story()
			var me3 := Vector3(main.player.x, 0, main.player.z)
			var ok_i: bool = main.in_workshop() and ws.floor_here() == i and Vector2(me3.x, me3.z).distance_to(fi.marks.A) < 0.3 \
				and main.mate != null and main.mate.position.distance_to(me3) < 3.0
			loads_ok = loads_ok and ok_i
			load_note += " B%d=%s" % [i + 1, ok_i]
		var kept: bool = main.work_q == 6 and main.work_latch[2] and b2.drained and b1.planks_shown and main.work_hp
		# no companion line before they join; the door waits for Mulgyeol
		park_mates(true)
		var cast: Array = main.cast_lines(STORY.WORK_B1_IN + STORY.WORK_HANDLE + STORY.WORK_CRADLE_IN)
		var no_mates: bool = not cast.any(func(l): return String(l).begins_with("노을|") or String(l).begins_with("물결|"))
		park_mates(false)
		main.lake_q = 3
		var waits: bool = not ws.door_ready()
		main.lake_q = 4
		main.in_hill = false
		main.in_village = false
		calm_enemies(false)
		check("workshop", shut and seen and opened and down and lamp1 and planks and plug and tag and to2 and up1 and covered and pulling and lid and drained and handle and to3 and frag and clamp1 and clamps and scratch and listed and out_castle and back3 and cradle_in and latch1 and swept and latches and released and once and simji and chat and loads_ok and kept and no_mates and waits,
			"door shut before the knight=%s first look=%s opens=%s down to B1 arrival=%s lamp 1 pip+2 bricks=%s planks=%s plug=%s tag=%s B2 arrival=%s up to B1=%s lid covers=%s pull=%s/%s drained=%s handle=%s B3 arrival=%s fragment=%s clamp1=%s clamps open the door=%s scratch=%s list=%s to castle=%s back to B3=%s cradle story=%s latch=%s sweep keeps the latch=%s (%s) three latches=%s released +10=%s once=%s simji bench=%s chatter=%d loads:%s kept=%s no early lines=%s door waits=%s" % [shut, seen, opened, down, lamp1, planks, plug, tag, to2, up1, covered, pulling, lid, drained, handle, to3, frag, clamp1, clamps, scratch, listed, out_castle, back3, cradle_in, latch1, swept, swept_note, latches, released, once, simji, chat_n, load_note, kept, no_mates, waits])
	calm_enemies(false)
	if want.call("lap6"):
		# GPT hand-played lap 6: the Help page is as tall as its rows, portraits fit a small screen, the quest line keeps off
		# Sora, no rescue hop at the castle's river edge, resting counts only monsters that can see her
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		# 1. the Help page: a stale 6000 px box height (what the web build showed) must not stretch the page
		main.toggle_settings(true)
		var help_ok := true
		var help_note := ""
		for touch in [false, true]:
			if touch:
				await main.enable_touch()
			main.show_set_tab(1)
			await wait(0.3)
			var first_row: Array = main.ui.set_stacks[1][0]
			var stale_box: Control = (first_row[1] as Label).get_parent()
			stale_box.size = Vector2(504, 6000)
			(first_row[1] as Label).size.y = 6000.0
			main.menus.layout_settings()
			await wait(0.5)
			var page: Control = main.ui.set_pages[1]
			var nbtn: Button = main.ui.music_rows[1 if touch else 0][2]
			var bottom: float = nbtn.position.y + nbtn.size.y
			help_ok = help_ok and page.custom_minimum_size.y < 1600.0 and bottom < 800.0
			help_note += " %s page %.0f px, next-tune button bottom %.0f;" % ["touch" if touch else "keys", page.custom_minimum_size.y, bottom]
		main.disable_touch()
		main.toggle_settings(false)
		check("help_height", help_ok, "Help page height under 1600 px with the music row inside 2 screens (800 px):" + help_note)
		# 2 + 3. small screens: the standing portrait and the quest line
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		var por_bad: Array = []
		var quest_bad: Array = []
		var quest0: String = main.quest_raw
		for sz in [Vector2i(645, 480), Vector2i(900, 600), Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900)]:
			root.content_scale_size = sz
			await wait(0.4)
			main.show_story("", ["심지|simji|등불을 켜 주었구나.", "소라|calm|네."])
			await wait(0.3)
			var vs: Vector2 = main.get_viewport().get_visible_rect().size
			var pr: TextureRect = main.ui.por_right
			var tex: Texture2D = pr.texture
			var rc: Rect2 = pr.get_global_rect()
			var k: float = minf(rc.size.x / tex.get_width(), rc.size.y / tex.get_height()) # the picture sits in its box, centred, aspect kept
			var dh: float = tex.get_height() * k
			var top: float = rc.position.y + (rc.size.y - dh) / 2.0
			var cap_top: float = (main.ui.story_cap as Control).get_global_rect().position.y
			if sz == Vector2i(645, 480):
				print("TEST LAP6 portrait 645x480: box %s picture top %.0f height %.0f story box top %.0f" % [rc, top, dh, cap_top])
			if top < 0.0 or top + 0.35 * dh > cap_top:
				por_bad.append("%s top %.0f face to %.0f box at %.0f" % [vs, top, top + 0.35 * dh, cap_top])
			if sz == Vector2i(645, 480):
				await shot_png("lap6_story_645")
			main.close_story()
			await wait(0.7)
			for text in ["광장의 등불지기에게 말을 걸자 (E)", "우편배달부 도란에게 말을 걸어 보자 (E)"]:
				main.set_quest(text)
				await wait(0.2)
				var d: Rect2 = main.hud_build.quest_deco
				var pl: Rect2 = main.hud_build.player_rect()
				if sz == Vector2i(645, 480):
					print("TEST LAP6 quest 645x480: deco %s lines %d player %s" % [d, main.hud_build.quest_lines, pl])
					await shot_png("lap6_quest_645_%d" % text.length())
				if d.intersects(pl) or d.position.y < 0.0 or d.end.y > vs.y or d.end.x > vs.x or d.position.x < 0.0:
					quest_bad.append("%s deco %s player %s" % [vs, d, pl])
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		main.set_quest(quest0)
		check("portrait_fits", por_bad.is_empty(), "the speaker's picture starts on screen and its face (top 35%) ends above the story box at 645x480 to 1600x900: " + str(por_bad.slice(0, 3)))
		check("quest_off_sora", quest_bad.is_empty(), "the quest line stays off Sora's 240x180 middle at 5 sizes, the usual quest lines: " + str(quest_bad.slice(0, 3)))
		# 4. the castle hall's river edge: a skipper who lets go of Shift beside the water is not "stuck"
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.castle_q = maxi(main.castle_q, 3)
		var skip0: bool = main.has_skip
		main.has_skip = true
		var edge := Vector2(445.657, 8.907)
		main.skipping = false
		var can_edge: bool = main.player_can(edge.x, edge.y)
		main.has_skip = false
		var cannot_plain: bool = not main.player_can(edge.x, edge.y) # without the skip the 0.35 margin still holds
		main.has_skip = true
		calm_enemies(true)
		reset_to(edge)
		main.unstick_log.clear()
		await wait(0.5)
		var edge_hops: int = main.unstick_log.size()
		# walk and cut about that corner for 8 s
		var rng6 := RandomNumberGenerator.new()
		rng6.seed = 61025
		reset_to(Vector2(447.0, 11.0))
		main.player.lv = maxi(main.player.lv, 5)
		main.player.max_hp = maxi(main.player.max_hp, 500)
		var el6 := 0.0
		while el6 < 8.0:
			main.fake_keys.clear()
			hold_world([Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(-1, -1), Vector2(-1, 1), Vector2.ZERO][rng6.randi() % 7])
			if rng6.randf() < 0.5:
				main.fake_keys[KEY_SHIFT] = true
			if rng6.randf() < 0.4:
				tap(KEY_J)
			main.player.hp = float(main.player.max_hp)
			var step6: float = rng6.randf_range(0.1, 0.4)
			await wait(step6)
			el6 += step6
		release()
		var stuck6 := 0
		for e in main.unstick_log:
			if e.reason == "stuck":
				stuck6 += 1
		main.has_skip = skip0
		calm_enemies(false)
		check("castle_edge", can_edge and cannot_plain and edge_hops == 0 and stuck6 == 0,
			"river edge spot (445.66, 8.91) is open to a skipper=%s, shut without the skip=%s; %d rescue hops standing, %d while mashing 8 s beside it" % [can_edge, cannot_plain, edge_hops, stuck6])
		# 5. resting: a monster behind a wall does not stop the lamp, one in the room does and says so once
		main.hour = 23.0
		main.has_tea = false
		main.fly_q = mini(main.fly_q, 2)
		var away: Array = []
		for e in main.enemies:
			if not e.dead and Vector2(e.x - 441.4, e.z - 6.0).length() < 9.0:
				away.append([e, e.z])
				e.z += 60.0
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(441.4, 0.0, 6.0)
		lamp.set_meta("dark", false)
		main.add_child(lamp)
		main.lanterns.append(lamp)
		main.spawn_enemy(Vector2(441.0, 8.5)) # one room south, the wall row 7 between
		var behind: Dictionary = main.enemies[main.enemies.size() - 1]
		calm_enemies(true)
		main.crown_pips = 0
		park_mates(true) # Mulgyeol would cut the monster down
		reset_to(Vector2(441.4, 6.4))
		await wait(8.5)
		var pips_wall: int = main.crown_pips
		var sees_through_wall: bool = main.line_clear(Vector2(441.4, 6.4), Vector2(441.0, 8.5))
		behind.x = 442.2 # now in her own hall, 1.3 tiles off: by a lantern only one this near stops the rest (v0.1.53)
		behind.z = 5.4
		main.crown_pips = 0
		main.rest_said = false
		main.ui.toast.modulate.a = 0.0
		reset_to(Vector2(441.4, 6.4))
		await wait(1.0)
		var said_once: bool = main.rest_said and "쉴 수 없다" in main.ui.toast.text
		for pin in 14: # hold the monster in the hall while she tries to rest
			behind.x = 442.2
			behind.z = 5.4
			await wait(0.5)
		var pips_room: int = main.crown_pips
		var clear_room: bool = main.line_clear(Vector2(441.4, 6.4), Vector2(442.2, 5.4))
		main.lanterns.erase(lamp)
		lamp.queue_free()
		var behind_note := "monster dead=%s at %s" % [behind.dead, Vector2(behind.x, behind.z)]
		behind.dead = true
		for a in away:
			a[0].z = a[1]
		calm_enemies(false)
		park_mates(false)
		main.crown_pips = main.pip_max
		check("rest_wall", pips_wall >= 1 and not sees_through_wall and pips_room == 0 and clear_room and said_once,
			"lamp rest 8.5 s with a monster behind a wall: pips 0->%d (sight through the wall=%s); with one in the room: pips %d, line clear=%s, reason toast said once=%s (%s)" % [pips_wall, sees_through_wall, pips_room, clear_room, said_once, behind_note])
		main.return_to_start()
	if want.call("lap7"):
		# GPT hand-played lap 7: a locked door shuts the mole in, the journal pauses the world, the cave mouth is one place
		# across a reload, a running side step shows under the quest, the prep hint follows potions and gold
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		park_mates(true)
		var bad7: Array = []
		# 1. the mole behind the locked door
		var keep_skip: bool = main.has_skip
		var keep_open: bool = main.cave_door_open
		var keep_key: bool = main.has_key
		main.has_skip = false
		main.cave_door_open = false
		main.has_key = false
		if not main.in_cave:
			main.enter_cave()
			await wait(0.3)
		var moles: Array = main.enemies.filter(func(e): return e.get("mole", false) and not e.dead)
		if moles.is_empty():
			main.cave.spawn_mole()
			moles = main.enemies.filter(func(e): return e.get("mole", false) and not e.dead)
		var mo7: Dictionary = moles[0]
		var door: Vector2 = main.cave_marks.D
		mo7.hp = float(mo7.max_hp)
		mo7.x = door.x + 0.5
		mo7.z = door.y - 0.4
		reset_to(Vector2(door.x - 0.9, door.y))
		main.damage_enemy(mo7, 9999.0, Vector2(main.player.x, main.player.z))
		var hp_shut: float = mo7.hp
		calm_enemies(false)
		mo7.atk_cd = 0.0
		mo7.next = "charge"
		await wait(2.5)
		var held: bool = mo7.x >= door.x + 1.55 and not mo7.dead and mo7.wind <= 0.0 and mo7.dash <= 0.0
		var hp_in: float = float(main.player.hp)
		main.cave_door_open = true # opened: the same hit lands
		main.damage_enemy(mo7, 10.0, Vector2(main.player.x, main.player.z))
		var hit_open: bool = mo7.hp < hp_shut
		main.cave_door_open = false
		main.saw_painting = false
		reset_to(main.cave_marks.P)
		main.cave.check_painting()
		main.close_story()
		var painting_q: String = plain(main.ui.quest.text)
		if hp_shut != float(mo7.max_hp) or not held or not hit_open or not painting_q.begins_with(main.tr("열쇠를 찾아")):
			bad7.append("1 mole shut hp %s held=%s (x %.2f door %.2f, hp %s) open hit=%s quest=%s" % [hp_shut, held, mo7.x, door.x, hp_in, hit_open, painting_q])
		mo7.hp = float(mo7.max_hp)
		main.has_skip = keep_skip
		main.cave_door_open = keep_open
		main.has_key = keep_key
		main.return_to_start()
		await wait(0.3)
		main.close_story()
		calm_enemies(true)
		# 2. the journal pauses the world
		main.spawn_enemy(Vector2(main.player.x + 3.0, main.player.z))
		var foe7: Dictionary = main.enemies[main.enemies.size() - 1]
		var t0: float = main.t
		var f0 := Vector2(foe7.x, foe7.z)
		calm_enemies(false)
		main.toggle_journal(true)
		await wait(0.8)
		var paused: bool = absf(main.t - t0) < 0.001 and Vector2(foe7.x, foe7.z).distance_to(f0) < 0.001
		main.toggle_journal(false)
		await wait(0.5)
		var runs: bool = main.t - t0 > 0.3
		foe7.dead = true
		foe7.node.queue_free()
		foe7.shadow.queue_free()
		if not paused or not runs:
			bad7.append("2 journal pauses=%s resumes=%s" % [paused, runs])
		# 3. the cave mouth keeps its place across save and reload
		calm_enemies(true)
		var st7: int = main.story_step
		main.story_step = 5
		main.cave_pos = Vector2(-99, -99)
		main.open_cave(Vector2(15.0, 8.88), false)
		var mouth: Vector2 = main.cave_pos
		var fake_node := Node3D.new() # a fallen Brick King that has not been cleared away yet: the load finds and removes it
		var fake_shadow := Node3D.new()
		main.add_child(fake_node)
		main.add_child(fake_shadow)
		var fake_boss := {"boss": true, "dead": true, "node": fake_node, "shadow": fake_shadow, "x": 22.0, "z": 3.0}
		main.enemies.append(fake_boss)
		main.save_game()
		main.cave_pos = Vector2(-99, -99)
		main.load_game()
		main.enemies.erase(fake_boss)
		var mouth2: Vector2 = main.cave_pos
		if mouth.distance_to(mouth2) > 0.01 or mouth.x < 0.0:
			bad7.append("3 cave mouth %s -> %s" % [mouth, mouth2])
		main.story_step = maxi(st7, 5)
		main.return_to_start()
		await wait(0.3)
		main.close_story()
		# 4. a running side step shows under the quest, inside the ornament box, clear of the HUD
		var sq7: String = main.quest_raw
		var keep_q: int = main.shore_q
		var keep_seen: bool = main.shore_seen
		main.set_quest(main.BORI_QUEST)
		main.shore_seen = true
		main.shore_q = 1
		await wait(0.3)
		var root7: Window = main.get_tree().root
		var scale7 := [root7.content_scale_mode, root7.content_scale_aspect, root7.content_scale_size]
		root7.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root7.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		var side_bad: Array = []
		for sz in [Vector2i(645, 480), Vector2i(960, 540), Vector2i(1600, 900)]:
			root7.content_scale_size = sz
			main.shore_wave = -1
			main.shore_q = 1
			await wait(0.4)
			var sl: Label = main.hud_build.side_label
			var dropped: bool = sz.x < 700 and not sl.visible and main.hud_build.side_want # a tiny screen may have no room: the quest alone
			var vis1: bool = sl != null and (sl.visible or dropped) and "팔찌를 대" in sl.text
			var box: Rect2 = main.hud_build.quest_deco
			var vs7: Vector2 = main.get_viewport().get_visible_rect().size
			var inside: bool = (dropped or box.encloses(sl.get_global_rect())) and Rect2(Vector2.ZERO, vs7).encloses(box) and box.encloses(main.ui.quest.get_global_rect().grow(-0.5))
			var clear := true
			for r in main.hud_build.quest_blocks(false):
				if box.intersects((r as Rect2).abs()):
					clear = false
			main.shore_q = 3 # waiting, nothing running now
			await wait(0.2)
			var gone: bool = not sl.visible
			main.shore_wave = 0
			main.shore_q = 1
			await wait(0.2)
			var fight: bool = (sl.visible or (sz.x < 700 and main.hud_build.side_want)) and "괴물" in sl.text
			main.shore_wave = -1
			if not (vis1 and inside and clear and gone and fight):
				side_bad.append("%s shown=%s inside=%s clear=%s gone=%s fight=%s box %s label %s" % [sz, vis1, inside, clear, gone, fight, box, sl.get_global_rect()])
		root7.content_scale_mode = scale7[0]
		root7.content_scale_aspect = scale7[1]
		root7.content_scale_size = scale7[2]
		await wait(0.2)
		if not side_bad.is_empty():
			bad7.append("4 side line: " + " | ".join(side_bad))
		main.shore_q = keep_q
		main.shore_seen = keep_seen
		# 5. the prep hint follows potions and gold
		var pots0: int = main.player.pots
		var gold0: int = main.player.gold
		main.player.pots = 3
		main.player.gold = 10
		await wait(0.2)
		var h1: String = plain(main.ui.quest.text)
		main.player.pots = 0
		await wait(0.2)
		var h2: String = plain(main.ui.quest.text)
		main.player.gold = 50
		await wait(0.2)
		var h3: String = plain(main.ui.quest.text)
		main.player.pots = 3
		var tk: bool = main.touch_ui
		var tw: bool = main.keys_last
		main.touch_ui = true
		main.keys_last = false
		var h4: String = plain(main.quest_shown(main.BORI_QUEST))
		main.touch_ui = tk
		main.keys_last = tw
		if not ("4 키로" in h1 and "(3개)" in h1 and "금화는" in h2 and "상점에서 약을" in h3 and "초록 하트" in h4 and not "상점에서 약을" in h1):
			bad7.append("5 hints: [%s] [%s] [%s] [%s]" % [h1, h2, h3, h4])
		main.player.pots = pots0
		main.player.gold = gold0
		main.set_quest(sq7)
		calm_enemies(false)
		park_mates(false)
		check("lap7", bad7.is_empty(), "locked door holds the mole, journal pause, cave mouth after reload, side line, prep hint" if bad7.is_empty() else "; ".join(bad7))
		main.return_to_start()
	if want.call("lap8"):
		# GPT hand-played lap 8: a shut forest wall stops the duel and every blow, villagers asleep are not "crying",
		# Korean particles follow the word, Mulgyeol's first meeting, Doran's letter line
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		await wait(0.1)
		calm_enemies(true)
		park_mates(true)
		var bad8: Array = []
		# 1. the forest: walls 1 and 2 open, the third (the duel clearing's) shut
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 0
		main.return_to_start()
		main.forest_zone.enter_forest()
		await wait(0.3)
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		var walls8: Array = main.forest.walls
		var last8: Dictionary = walls8[0]
		for w in walls8:
			if w.pos.x > last8.pos.x or last8.pos.x == w.pos.x and w.pos.y > last8.pos.y:
				last8 = w
		for w in walls8:
			if w != last8 and not w.open:
				main.forest.open_wall(w)
		var was_open: bool = last8.open
		last8.open = false
		reset_to(Vector2(last8.pos.x + 0.24, last8.pos.y - 2.3))
		main.player.inv = 0.0
		await wait(0.4)
		var q_before: int = main.forest_q
		main.close_story()
		for old in main.enemies:
			if old.get("noeul", false) and not old.dead:
				old.dead = true # one left by an earlier test would keep the duel from spawning
		main.village_life.spawn_noeul_duel(true)
		var nl8: Dictionary = main.enemies.filter(func(e): return e.get("noeul", false) and not e.dead)[0]
		nl8.hp = float(nl8.max_hp)
		reset_to(Vector2(last8.pos.x + 0.77, last8.pos.y - 0.85))
		main.damage_enemy(nl8, 500.0, Vector2(main.player.x, main.player.z))
		var hp_n: float = nl8.hp
		var hp_s0: float = float(main.player.hp)
		var res: String = main.player_hit(20, Vector2(nl8.x, nl8.z), nl8)
		var res2: String = main.player_hit(20, Vector2(nl8.x, nl8.z), {})
		var hp_s1: float = float(main.player.hp)
		await wait(2.5)
		var still_shut: bool = hp_n == nl8.hp and hp_s1 == hp_s0 and res == "none" and res2 == "none" and float(main.player.hp) == hp_s0
		reset_to(Vector2(last8.pos.x, last8.pos.y + 2.0)) # inside the clearing: blows land as before
		main.damage_enemy(nl8, 10.0, Vector2(main.player.x, main.player.z))
		var inside_hit: bool = nl8.hp < hp_n
		var east_shut: String = main.forest_zone.east_quest()
		last8.open = true
		var east_open: String = main.forest_zone.east_quest()
		last8.open = was_open
		if q_before != 1 or not still_shut or not inside_hit or not east_shut.begins_with("닫힌 벽돌 벽") or east_open.begins_with("닫힌"):
			bad8.append("1 forest q=%d shut holds=%s (npc hp %s->%s, hit %s/%s) inside hit=%s quests [%s] [%s]" % [q_before, still_shut, hp_n, nl8.hp, res, res2, inside_hit, east_shut, east_open])
		nl8.dead = true
		nl8.node.queue_free()
		nl8.shadow.queue_free()
		main.ui.boss.visible = false
		main.forest_q = 3
		main.return_to_start()
		await wait(0.3)
		main.close_story()
		calm_enemies(true)
		# 2. Kongal asleep at midnight
		var raw8 := "광장 서쪽의 콩알이 울고 있다. 말을 걸어 보자 (E)"
		var fs8: String = main.folk_state.get("kongal", "out")
		main.folk_state["kongal"] = "in"
		main.set_quest(raw8) # read at once: by day the sleep update would send her out again
		var asleep_q: String = plain(main.ui.quest.text)
		var asleep_j: String = ""
		for l in main.menus.journal_lines():
			if "잔다" in String(l):
				asleep_j = String(l)
		var night_other: String = plain(main.quest_shown("우편배달부 도란에게 말을 걸어 보자 (E)"))
		main.folk_state["kongal"] = "out"
		var awake_q: String = plain(main.quest_shown(raw8))
		main.folk_state["kongal"] = fs8
		if not ("콩알은" in asleep_q and "잔다" in asleep_q and "울고" not in asleep_q) or asleep_j == "" or not ("잔다" in night_other or "도란" in night_other) or not ("울고" in awake_q):
			bad8.append("2 quest asleep [%s] journal [%s] awake [%s]" % [asleep_q, asleep_j, awake_q])
		main.set_quest("")
		# 3. particles
		var ko: GDScript = main.Ko
		var cases := [["사과을(를)", "사과를"], ["금화 5을(를)", "금화 5를"], ["금화 10을(를)", "금화 10을"], ["금화 1을(를)", "금화 1을"], ["금화 2을(를)", "금화 2를"], ["금화 7을(를)", "금화 7을"], ["금화 9을(를)", "금화 9를"], ["금화 100을(를)", "금화 100을"], ["붕어을(를)", "붕어를"], ["잉어을(를)", "잉어를"], ["메기을(를)", "메기를"], ["송어이(가)", "송어가"], ["콩알이(가)", "콩알이"], ["물결이(가)", "물결이"], ["노을이(가)", "노을이"], ["소라은(는)", "소라는"], ["도란은(는)", "도란은"], ["사과과(와)", "사과와"], ["책과(와)", "책과"], ["마을으로(로)", "마을로"], ["집으로(로)", "집으로"], ["금화 3으로(로)", "금화 3으로"], ["금화 5으로(로)", "금화 5로"], ["문에 해 지는 그림이(가) 있다", "문에 해 지는 그림이 있다"], ["다람쥐 꼬리 그림이(가) 있다", "다람쥐 꼬리 그림이 있다"], ["초승달 그림이(가) 있다", "초승달 그림이 있다"], ["평범한 글", "평범한 글"]]
		var bad_p: Array = []
		for c in cases:
			var got: String = ko.josa(c[0])
			if got != c[1]:
				bad_p.append("%s -> %s (want %s)" % [c[0], got, c[1]])
		main.toast(main.tr("상자에 금화 %d을(를) 넣고 %s을(를) 집었다") % [5, main.tr("사과")])
		var shown_t: String = main.ui.toast.text
		if not ("금화 5를 넣고" in shown_t and "사과를 집었다" in shown_t):
			bad_p.append("toast [%s]" % shown_t)
		if not bad_p.is_empty():
			bad8.append("3 particles " + "; ".join(bad_p))
		# 4. Mulgyeol's first meeting
		var dq8: int = main.doran_q
		var mq8: int = main.mul_q
		main.doran_q = 3
		main.mul_q = 0
		main.errands.mulgyeol_errand(true)
		var first_line: String = plain(main.ui.story_text.text)
		main.close_story()
		main.mul_q = 0
		main.errands.mulgyeol_errand(false)
		var again_line: String = plain(main.ui.story_text.text)
		main.close_story()
		main.doran_q = dq8
		main.mul_q = mq8
		if "또 왔어" in first_line or not ("처음" in first_line) or not ("또 왔어" in again_line):
			bad8.append("4 Mulgyeol first [%s] again [%s]" % [first_line, again_line])
		# 5. Doran's letter
		var lb8: bool = main.letter_back
		main.doran_q = 3
		main.letter_back = false
		var side_a: String = main.errands.letter_side_line()
		main.letter_back = true
		var side_b: String = main.errands.letter_side_line()
		main.letter_back = lb8
		main.doran_q = dq8
		if not side_a.begins_with("도란에게") or side_b != "":
			bad8.append("5 letter line [%s] after [%s]" % [side_a, side_b])
		main.close_story()
		calm_enemies(false)
		park_mates(false)
		check("lap8", bad8.is_empty(), "shut wall holds duel and blows, sleeping villager line, particles, Mulgyeol first line, letter line" if bad8.is_empty() else "; ".join(bad8))
		main.return_to_start()
	# ---- cloud bug hunt (2026-10-25): bosses that followed her out of their zones, fights a faint left half reset,
	# a big blow past the mold's lock, Mulgyeol under the hawk, the kid goblin lost on a reload, the race on the quest line
	if want.call("hawk_leash") or want.call("mold_leash") or want.call("mold_no_skip") or want.call("king_calm") \
			or want.call("faint_banner") or want.call("windrun_faint") or want.call("mate_skips_air") or want.call("kid_reload") or want.call("race_save"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.2)
		calm_enemies(true)
	if want.call("hawk_leash"):
		# the hawk is alive (she fainted on the hill and woke in the village): it must not dive on her there
		main.hill_zone.spawn_hawk()
		var hk: Dictionary = main.enemies.filter(func(e): return e.get("hawk", false) and not e.dead)[0]
		main.in_hill = false
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(-1.5, 1.5))
		main.ui.boss.visible = false
		hk.atk_cd = 0.0
		await wait(2.5)
		var calm_hawk: bool = hk.air and hk.wind <= 0.0 and hk.dash <= 0.0
		check("hawk_leash", calm_hawk and not main.ui.boss.visible,
			"hawk stays on its ledge=%s (air=%s wind=%.1f dash=%.1f) boss bar hidden=%s" % [calm_hawk, hk.air, hk.wind, hk.dash, not main.ui.boss.visible])
		hk.dead = true
		hk.node.queue_free()
		hk.shadow.queue_free()
	if want.call("mold_leash") or want.call("mold_no_skip"):
		var gq0: int = main.garden_q
		main.garden_q = 2
		main.garden_zone.spawn_mold()
		var mo: Dictionary = main.enemies.filter(func(e): return e.get("mold", false) and not e.dead)[0]
		if want.call("mold_leash"):
			# she walked out of the garden mid-fight: the mold must not slam rings at her feet on the stairs
			main.in_garden = false
			main.in_hill = true
			reset_to(main.stairs.marks.N + Vector2(0, 1.3))
			main.ui.boss.visible = false
			mo.atk_cd = 0.0
			await wait(1.5)
			check("mold_leash", (mo.rings as Array).is_empty() and mo.wind <= 0.0 and not main.ui.boss.visible,
				"rings=%d wind=%.1f boss bar hidden=%s" % [(mo.rings as Array).size(), mo.wind, not main.ui.boss.visible])
		if want.call("mold_no_skip"):
			# one blow bigger than the last 12%: the mold must stop at 1 HP and lock, not die like a goblin
			mo.hp = 300.0
			main.damage_enemy(mo, 5000.0, Vector2(mo.x + 1.0, mo.z), 4.0, true)
			check("mold_no_skip", not mo.dead and mo.hp >= 1.0 and main.garden_q == 2, "dead=%s hp=%.0f garden_q=%d" % [mo.dead, mo.hp, main.garden_q])
		if not mo.dead:
			mo.dead = true
			mo.node.queue_free()
			mo.shadow.queue_free()
		main.garden_q = gq0
		main.ui.boss.visible = false
	if want.call("king_calm"):
		# fainting to the enraged Brick King: the rematch starts in phase 1 with the bar back to purple
		var kings: Array = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)
		var spawned := kings.is_empty()
		if spawned:
			main.monsters.spawn_boss()
			kings = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)
		var kb: Dictionary = kings[0]
		kb.phase = 2
		kb.hp = 10.0
		main.ui.boss_bar.color = Color("#d84a6a")
		for f in ["in_village", "in_hill", "in_lake", "in_forest", "in_garden", "in_cave"]:
			main.set(f, false) # a marsh faint
		main.faint()
		await wait(0.1)
		check("king_calm", kb.phase == 1 and kb.hp == float(kb.max_hp) and main.ui.boss_bar.color == Color("#9a4ad8"),
			"phase=%d hp=%.0f/%d bar=%s" % [kb.phase, kb.hp, kb.max_hp, main.ui.boss_bar.color.to_html(false)])
		if spawned:
			main.enemies.erase(kb)
			kb.node.queue_free()
			kb.shadow.queue_free()
		main.ui.boss.visible = false
	if want.call("faint_banner"):
		# a faint that wakes her on the village square holds the banner as long as the marsh one
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(3, 3))
		main.banner_t = 0.0
		main.faint()
		await wait(1.2)
		check("faint_banner", main.ui.banner.modulate.a > 0.5, "banner alpha after 1.2 s=%.2f" % main.ui.banner.modulate.a)
	if want.call("windrun_faint"):
		# a faint during the wind run: the run ends and its countdown leaves the quest line
		var mq0: int = main.mill_q
		main.mill_q = 2
		main.in_village = false
		main.in_hill = true
		main.windrun_on = true
		main.windrun_quest = main.quest_raw
		main.set_quest(tr("바람 부르기 %d/4 · %d초") % [1, 5])
		main.faint()
		await wait(0.2)
		var q: String = main.ui.quest.text
		check("windrun_faint", not main.windrun_on and not q.begins_with(main.windrun_prefix()), "run on=%s quest=%s" % [main.windrun_on, q])
		main.windrun_on = false
		main.windrun_tries = 0
		main.mill_q = mq0
		main.set_quest(main.windrun_quest)
	if want.call("mate_skips_air"):
		# Mulgyeol does not run off under the hawk circling out of reach
		if main.mate == null:
			main.join_mate()
		main.in_hill = false
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(-1.5, 1.5))
		main.snap_mates()
		main.mate_cd = 0.0
		main.hill_zone.spawn_hawk()
		var ah: Dictionary = main.enemies.filter(func(e): return e.get("hawk", false) and not e.dead)[0]
		var far := 0.0
		for k in 20:
			ah.x = main.mate.position.x + 3.0
			ah.z = main.mate.position.z
			ah.air = true
			ah.wind = 5.0 # held in its wind-up, so it hangs where it is put
			await wait(0.05)
			far = maxf(far, Vector2(main.mate.position.x, main.mate.position.z).distance_to(Vector2(main.player.x, main.player.z)))
		check("mate_skips_air", far < 1.8, "Mulgyeol's farthest from Sora with the hawk overhead=%.1f" % far)
		ah.dead = true
		ah.node.queue_free()
		ah.shadow.queue_free()
		main.ui.boss.visible = false
	if want.call("kid_reload"):
		# a save made outside the village while the kid goblin is lost: on loading, the kid and its guards are in the field
		var kq0: int = main.kid_q
		main.in_village = false
		main.in_hill = false
		main.in_lake = false
		main.in_forest = false
		main.in_garden = false
		main.in_cave = false
		reset_to(main.START)
		main.save_game()
		var sv = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		sv["kid_q"] = 1
		var fw := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		fw.store_string(JSON.stringify(sv))
		fw.close()
		if main.kid_node != null:
			main.kid_node.queue_free()
			main.kid_node = null
		var n0: int = main.enemies.size()
		main.load_game()
		var kid_there: bool = main.kid_node != null and main.kid_q == 1
		var field := Vector2(main.VILLAGE.VILLAGE_X + main.village.KID_AT.x, main.village.KID_AT.y)
		var guards: Array = main.enemies.slice(n0).filter(func(e): return not e.dead and Vector2(e.x, e.z).distance_to(field) < 4.0)
		check("kid_reload", kid_there and guards.size() == 3, "kid placed=%s guards=%d" % [kid_there, guards.size()])
		for e in guards:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
		main.kid_q = kq0
		if main.kid_node != null:
			main.kid_node.queue_free()
			main.kid_node = null
		if kq0 > 0:
			main.place_kid()
		main.save_game()
	if want.call("race_save"):
		# a save made during the pinwheel race keeps the quest line from before it, not the race's countdown
		main.race_quest = main.quest_raw
		main.race_on = true
		main.set_quest(tr("바람개비 경주 %d/5 · %d초") % [2, 13])
		main.save_game()
		var rs = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		main.race_on = false
		main.set_quest(main.race_quest)
		check("race_save", rs != null and String(rs.get("quest", "")) == main.race_quest, "saved quest=%s before=%s" % [rs.get("quest", "") if rs != null else "", main.race_quest])
		main.save_game()
	# ---- GPT bug hunt (2026-10-26): boss clocks ticked twice a frame, mill escorts piled up over faints,
	# a faint left the mold's shock ring and the posts' pips behind, Mulgyeol stood on the pier and at her side
	if want.call("bug_boss_tick") or want.call("bug_mill_pile") or want.call("bug_mold_faint") or want.call("bug_mul_twice"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.2)
		calm_enemies(true)
	if want.call("bug_boss_tick"):
		# one 0.1 s step of the enemy loop takes 0.1 s off each clock, for the kinds with their own update
		# (a common foe's wait falls at monsters.FOE_PACE, since v0.1.125; the king keeps his own clock)
		# (king, wolf, bat) as for those that lean on the shared one (hedgehog)
		var kings: Array = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)
		var made: Array = []
		if kings.is_empty():
			main.monsters.spawn_boss()
			made.append(main.enemies[main.enemies.size() - 1])
		var kb: Dictionary = main.enemies.filter(func(e): return e.get("boss", false) and not e.dead)[0]
		reset_to(Vector2(kb.x + 6.0, kb.z))
		main.spawn_wolf(Vector2(kb.x + 9.0, kb.z + 3.0))
		made.append(main.enemies[main.enemies.size() - 1])
		main.spawn_bat(Vector2(kb.x + 9.0, kb.z - 3.0))
		made.append(main.enemies[main.enemies.size() - 1])
		main.monsters.spawn_hog(Vector2(kb.x + 12.0, kb.z))
		made.append(main.enemies[main.enemies.size() - 1])
		var who: Array = [kb] + made.filter(func(e): return e != kb)
		for e in who:
			e.atk_cd = 2.0
			e.hurt = 0.5
		main.monsters.update_enemies(0.1, main.ground_y)
		var bad_tick: Array = []
		for e in who:
			var kind: String = "king" if e.get("boss", false) else ("wolf" if e.get("wolf", false) else ("bat" if e.get("bat", false) else "hog"))
			var want_cd: float = 1.9 if e.get("boss", false) else 2.0 - 0.1 * main.monsters.FOE_PACE
			if absf(e.atk_cd - want_cd) > 0.001 or absf(e.hurt - 0.4) > 0.001:
				bad_tick.append("%s atk_cd=%.2f hurt=%.2f" % [kind, e.atk_cd, e.hurt])
		check("bug_boss_tick", bad_tick.is_empty(), "each clock down 0.1 after one 0.1 s step" if bad_tick.is_empty() else "; ".join(bad_tick))
		for e in made:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
			if e.get("boss", false):
				main.enemies.erase(e)
		main.ui.boss.visible = false
	if want.call("bug_mill_pile"):
		# a faint by the channel's guardian and a walk back in: one guardian and two goblins, not two more each time
		var mq1: int = main.mill_q
		main.mill_q = 3
		var n1: int = main.enemies.size()
		var piles: Array = []
		for k in 3:
			main.in_village = false
			main.in_hill = true
			main.hill_zone.spawn_mill_guard()
			piles.append(main.enemies.slice(n1).filter(func(e): return not e.dead and not e.get("moth", false)).size()) # the faint wakes Sora in the village, where night moths come up
			main.faint()
			await wait(0.1)
		check("bug_mill_pile", piles == [3, 3, 3], "foes at the channel on each return=%s" % [piles])
		for e in main.enemies.slice(n1).filter(func(e): return not e.dead):
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
		main.mill_q = mq1
		main.in_hill = false
		main.in_village = true
	if want.call("bug_mold_faint"):
		# a faint while the villagers light the ring: the fight starts over clean (no frozen shock ring, no posts' pips)
		var gq1: int = main.garden_q
		var pips1: int = main.crown_pips
		main.in_village = false
		main.in_hill = false
		main.in_garden = true
		main.garden_q = 2
		main.garden_zone.spawn_mold()
		var mo1: Dictionary = main.enemies.filter(func(e): return e.get("mold", false) and not e.dead)[0]
		mo1.locked = true
		main.garden_q = 3
		main.garden.set_posts(3)
		main.ring_k = 3
		main.crown_pips = 3
		main.garden_zone.shed_shards()
		main.garden_zone.start_mold_wave(mo1)
		main.faint()
		await wait(0.1)
		var lit: int = main.garden.posts.filter(func(l): return l.visible).size()
		var left: int = main.enemies.filter(func(e): return not e.dead and (e.get("mold", false) or e.get("shard", false))).size()
		check("bug_mold_faint", main.garden_q == 1 and main.ring_k == -1 and lit == 0 and left == 0 and main.mold_wave.is_empty() and main.crown_pips == 0,
			"garden_q=%d ring_k=%d posts lit=%d mold/shards left=%d shock ring gone=%s pips=%d" % [main.garden_q, main.ring_k, lit, left, main.mold_wave.is_empty(), main.crown_pips])
		if not main.mold_wave.is_empty():
			main.mold_wave.node.queue_free()
			main.mold_wave = {}
		main.garden_q = gq1
		main.crown_pips = pips1
		main.garden.set_posts(8 if gq1 >= 5 else 0)
		main.ui.boss.visible = false
	if want.call("bug_mul_twice"):
		# fainting in the turtle fight sends it back to the pier: Mulgyeol stands there, and only there
		var lq1: int = main.lake_q
		var mate1: Node3D = main.mate
		var mate2_1: Node3D = main.mate2
		for mt in [mate1, mate2_1]:
			if mt != null:
				mt.visible = false
		main.mate = null
		main.mate2 = null
		main.lake_q = 2
		main.lake_zone.enter_lake()
		main.close_story()
		main.lake_zone.row_to_island()
		main.close_story()
		await wait(0.2)
		var joined: bool = main.mate != null and not main.lake_npc.visible
		main.faint()
		await wait(0.2)
		var shown: int = int(main.mate != null and main.mate.visible) + int(main.lake_npc != null and main.lake_npc.visible)
		check("bug_mul_twice", joined and main.lake_q == 2 and shown == 1 and main.lake_npc.visible,
			"joined on rowing=%s lake_q=%d Mulgyeols shown=%d on the pier=%s" % [joined, main.lake_q, shown, main.lake_npc.visible])
		for e in main.enemies.filter(func(e): return e.get("turtle", false) and not e.dead):
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
		if main.mate != null: # back as the run had him
			main.mate.queue_free()
			main.mate = null
		main.village.folk_node.mulgyeol.visible = mate1 == null
		if mate1 != null:
			main.mate = mate1
			mate1.visible = true
			main.rocks = main.rocks.filter(func(r): return r.get("folk", "") != "mulgyeol")
		if mate2_1 != null:
			main.mate2 = mate2_1
			mate2_1.visible = true
		main.snap_mates()
		main.lake_q = lq1
		main.lake_npc.visible = lq1 < 3
		main.in_lake = false
		main.in_village = true
		reset_to(main.village.marks.M + Vector2(-1.5, 1.5))
	if want.call("quest_marks"):
		# every main-quest step aimed at a fixed thing in the area she stands in has the gold "!" in the world and the
		# same spot on the minimap (the owner, 2026-10-26); the shore's side step too, and none while a story box is open
		main.close_story()
		park_mates(true)
		var keep := {"story": main.story_step, "q": main.quest_raw, "gq": main.garden_q, "lq": main.lake_q, "shq": main.shore_q, "seen": main.shore_seen, "shrine": main.shrine_seen}
		var keep_woke: Array = main.woke.duplicate()
		var keep_saw: bool = main.saw_painting
		main.woke[0] = true # the cave's way out points at the exit once the whirl is woken and the mural seen (v0.1.46)
		main.saw_painting = true
		var go := func(flag: String, at: Vector2) -> void:
			for f in ["in_cave", "in_village", "in_forest", "in_lake", "in_hill", "in_garden"]:
				main.set(f, f == flag)
			main.in_house = -1
			reset_to(at)
		var cases := [
			["marsh", "", main.START, "서쪽 오두막으로 가 보자", main.cottage_at],
			["marsh", "", Vector2(40, 20), "동쪽 강을 물수제비 걸음으로 건너, 마을 불빛을 찾아라", main.quest_marks.VILLAGE_WAY],
			["marsh", "", main.MARSH.BASKET_AT + Vector2(3, 0), "도란의 편지에 팔찌를 대 보자 (E, 달빛 눈금 사용)", main.MARSH.BASKET_AT],
			["cave", "in_cave", main.cave_marks.E + Vector2(-4, 0), "동쪽 출구로 나가자 (Shift를 누르고 물 위를 달릴 수 있다)", main.cave_marks.E],
			["village", "in_village", main.village.marks.M + Vector2(3.0, -2.5), main.SIMJI_QUEST, main.village.marks.M],
			["village", "in_village", main.village.marks.M + Vector2(3.0, -2.5), "광장 서쪽의 콩알이 울고 있다. 말을 걸어 보자 (E)", Vector2.INF],
			["village", "in_village", main.village.marks.M + Vector2(3.0, -2.5), "물결과 함께 남쪽 호수를 풀자 (마을 남쪽 문)", main.village.marks.K],
			["lake", "in_lake", main.lake.marks.D + Vector2(1.0, 0), "수문의 벽돌을 팔찌로 풀자 (E)", main.lake.marks.D],
			["forest", "in_forest", main.forest.marks.S + Vector2(2.5, -1.5), "숲 동쪽 끝 길로, 바람 언덕에 가자", main.forest.marks.E],
			["hill", "in_hill", main.hill.marks.S + Vector2(2.0, -1.5), "언덕 동쪽 끝 길로, 달지기들의 성에 가자", main.hill.marks.X],
			["castle", "in_hill", main.castle.marks.S + Vector2(2.5, 1.5), "옥좌의 방으로 가자", Vector2.INF],
			["stairs", "in_hill", main.stairs.marks.S + Vector2(0, -1.3), main.STAIRS_DONE_QUEST, Vector2.INF],
			["garden", "in_garden", main.garden.marks.S + Vector2(1.5, 0), "이야기 끝 · 정원 한가운데 구멍으로 내려가 시계방에 가 보자", main.garden.marks.C]]
		var bad_q: Array = []
		var rim_ok := false
		for c in cases:
			main.close_story()
			go.call(c[1], c[2])
			main.story_step = maxi(keep.story, 7)
			main.lake_q = 1 if c[0] == "lake" else keep.lq
			main.garden_q = 5 if c[0] == "garden" else keep.gq
			main.shore_q = 1
			main.shore_seen = false
			main.shrine_seen = true # the shrine's first words open by the cave's south half
			main.quest_raw = c[3]
			var tg: Vector3 = main.step_target()
			main.castle_zone.update_quarters_mark()
			main.set_process(false) # the game holds still while the map draws: no gate or stair may carry her off
			await get_tree().process_frame
			await get_tree().process_frame
			main.set_process(true)
			var want_at: Vector2 = c[4]
			var spot_ok: bool = tg != Vector3.INF and (want_at == Vector2.INF or Vector2(tg.x, tg.z).distance_to(want_at) < 0.6)
			var on_map: bool = main.ui.mini.quest_at != Vector2.INF and main.quarters_mark != null and main.quarters_mark.visible
			if not spot_ok or not on_map or main.story_open:
				bad_q.append("%s [%s] target=%s then %s minimap=%s story=%s quest=%s lake_q=%d at=%.1f,%.1f" % [c[0], c[3].left(14), tg, main.step_target(), main.ui.mini.quest_at, main.story_lines.slice(0, 1), main.quest_raw.left(10), main.lake_q, main.player.x, main.player.z])
				main.close_story()
			if c[3].begins_with("도란의 편지"): # 3 tiles off: drawn inside the round map, not pushed to its rim
				var mid: Vector2 = main.ui.mini.size / 2.0
				rim_ok = main.ui.mini.quest_at != Vector2.INF and main.ui.mini.quest_at.distance_to(mid) < main.ui.mini.size.x / 2.0 - 20.0
				main.show_story("", ["||시험"])
				main.castle_zone.update_quarters_mark()
				main.set_process(false)
				await get_tree().process_frame
				await get_tree().process_frame
				main.set_process(true)
				if main.ui.mini.quest_at != Vector2.INF or main.step_target() != Vector3.INF:
					bad_q.append("marks shown under a story box")
				main.close_story()
		main.story_step = keep.story
		main.garden_q = keep.gq
		main.lake_q = keep.lq
		main.shore_q = keep.shq
		main.shore_seen = keep.seen
		main.shrine_seen = keep.shrine
		main.woke = keep_woke
		main.saw_painting = keep_saw
		main.return_to_start()
		main.set_quest(keep.q)
		park_mates(false)
		check("quest_marks", bad_q.is_empty() and rim_ok, "%d quest steps with a gold ! and a minimap mark, a near one inside the rim=%s %s" % [cases.size(), rim_ok, "; ".join(bad_q)])
	if want.call("field_respawn"):
		# the hill's and the forest's field foes stay down while she is there and come back at their spots when she
		# walks in again; a foe outside the field lists (a quest's or a story fight's) stays down
		main.close_story()
		park_mates(true)
		var kq := [main.hill_q, main.forest_q, main.quest_raw]
		main.hill_q = maxi(main.hill_q, 1)
		main.forest_q = maxi(main.forest_q, 3)
		main.in_village = false
		main.in_forest = true
		reset_to(main.forest.marks.E + Vector2(-1.2, 0))
		main.enter_hill()
		main.close_story()
		var spots: Array = main.monsters.field_spots("hill")
		var field := func(): return main.enemies.filter(func(e): return e.get("field", "") == "hill" and not e.dead)
		var full: bool = field.call().size() == spots.size() and spots.size() > 0
		if not full:
			check("field_respawn", false, "hill foes on entering %d/%d" % [field.call().size(), spots.size()])
		else:
			var plain_foes: Array = field.call().filter(func(e): return int(e.get("shield", 0)) <= 0 and not e.get("wolf", false))
			var e0: Dictionary = plain_foes[0] if not plain_foes.is_empty() else field.call()[0] # a shield would take the blow
			var slot: int = e0.slot
			main.damage_enemy(e0, 99999.0, Vector2(e0.x, e0.z + 1.0))
			main.spawn_enemy(main.hill.marks.S + Vector2(3, 3))
			var story_foe: Dictionary = main.enemies[main.enemies.size() - 1]
			story_foe.cave = true
			main.damage_enemy(story_foe, 99999.0, Vector2(story_foe.x, story_foe.z + 1.0))
			await wait(1.0)
			var stays: bool = field.call().size() == spots.size() - 1
			main.hill_zone.leave_hill()
			var forest_n: int = main.enemies.filter(func(e): return e.get("field", "") == "forest" and not e.dead).size()
			main.enter_hill()
			main.close_story()
			var back: Array = field.call().filter(func(e): return e.slot == slot)
			var at_spot: bool = back.size() == 1 and Vector2(back[0].x, back[0].z).distance_to(spots[slot][0]) < 0.3
			var refilled: bool = field.call().size() == spots.size()
			var kept_down: bool = story_foe.dead and main.enemies.has(story_foe)
			check("field_respawn", stays and at_spot and refilled and kept_down and forest_n == main.monsters.field_spots("forest").size(),
				"hill foes %d, one down stays down while there=%s, back at its spot on the next visit=%s, all back=%s, a foe off the lists stays down=%s, forest refilled on the way %d/%d" \
				% [spots.size(), stays, at_spot, refilled, kept_down, forest_n, main.monsters.field_spots("forest").size()])
		for e in main.enemies:
			if e.get("field", "") != "" and not e.dead:
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
		main.hill_q = kq[0]
		main.forest_q = kq[1]
		main.return_to_start()
		main.set_quest(kq[2])
		park_mates(false)
	if want.call("pack_turns"):
		var C := open_field()
		# four goblins round Sora: one attacker at a time, the others flank (about 2.2 tiles) or hang back (about 3.5),
		# never two wind-ups at once and at least about 0.9 s between two swings (0.45 s of wait at FOE_PACE, 0.45 s of wind-up)
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		reset_to(C)
		main.monsters.pack_cd = 0.0
		var gobs: Array = []
		for a in [0.3, 1.9, 3.5, 5.1]:
			main.spawn_enemy(C + Vector2(4.5, 0).rotated(a))
			var g: Dictionary = main.enemies[main.enemies.size() - 1]
			g.cave = true # no respawn when it is cleared away
			g.hp = 99999.0
			g.atk_cd = 0.0
			gobs.append(g)
		var prev_cd: Array = [0.0, 0.0, 0.0, 0.0]
		var swings: Array = []
		var two_at_once := false
		var flank_seen := false
		var back_seen := false
		for i in 160:
			reset_to(C)
			var winding := 0
			for k in 4:
				var g: Dictionary = gobs[k]
				if g.get("wind", 0.0) > 0.0 or g.get("lwind", 0.0) > 0.0 or g.get("ldash", 0.0) > 0.0:
					winding += 1
				if g.atk_cd > prev_cd[k] + 0.5:
					swings.append(gsec())
				prev_cd[k] = g.atk_cd
				var gd: float = Vector2(g.x - C.x, g.z - C.y).length()
				if i > 40 and gd > 1.9 and gd < 2.7:
					flank_seen = true
				if i > 40 and gd > 3.0 and gd < 4.2:
					back_seen = true
			if winding > 1:
				two_at_once = true
			await wait(0.05)
		var min_gap := 99.0
		for k in range(1, swings.size()):
			min_gap = minf(min_gap, swings[k] - swings[k - 1])
		for g in gobs:
			g.dead = true
			g.node.queue_free()
			g.shadow.queue_free()
		calm_enemies(false)
		park_mates(false)
		check("pack_turns", not two_at_once and swings.size() >= 2 and min_gap >= 0.85 and flank_seen and back_seen,
			"never two wind-ups at once=%s, swings=%d, shortest gap %.2f s, a flanker near 2.2 tiles=%s, one hanging back near 3.5=%s" % [not two_at_once, swings.size(), min_gap, flank_seen, back_seen])
	if want.call("goblin_lunge"):
		var C := open_field()
		# from 1.6 tiles the attacker lunges: 0.55 s wind-up with the direction locked and a fan shown, a short dash, one cut
		# that hurts when she stays and misses (0.65 s open, seams showing) when she steps out of the locked line
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		var lunge_ok: Array = []
		var lunge_why: Array = []
		for trial in 2:
			reset_to(C)
			main.player.inv = 0.0
			main.monsters.pack_cd = 0.0
			main.spawn_enemy(C + Vector2(1.6, 0))
			var g: Dictionary = main.enemies[main.enemies.size() - 1]
			g.cave = true
			g.hp = 99999.0
			g.atk_cd = 0.0
			g.lpick = 1
			var hp0: float = main.player.hp
			var t_wind := -1.0
			var wind_len := 0.0
			var dir_ok := false
			var fan_shown := false
			var hp_in_wind := true
			var dashed := false
			var x0: float = g.x
			var moved := 0.0
			var open_seen := false
			var rec_seen := false
			var stepped := false
			for i in 50:
				await wait(0.05)
				var now := gsec()
				if g.get("lwind", 0.0) > 0.0:
					if t_wind < 0.0:
						t_wind = now
						dir_ok = g.ldir.x < -0.9
						var tl = g.get("tele", null)
						fan_shown = tl != null and is_instance_valid(tl) and tl.visible
					if main.player.hp < hp0:
						hp_in_wind = false
					if trial == 1 and not stepped:
						stepped = true
						reset_to(C + Vector2(0, 3.5)) # out of the locked line
				if g.get("ldash", 0.0) > 0.0:
					if wind_len == 0.0:
						wind_len = now - t_wind
					dashed = true
				if dashed:
					moved = maxf(moved, x0 - g.x)
				if g.get("seam", 0.0) > 0.0:
					open_seen = true
				if g.get("lrec", 0.0) > 0.0:
					rec_seen = true
				if dashed and g.get("ldash", 0.0) <= 0.0 and now - t_wind > 1.0:
					break
			var hurt: bool = main.player.hp < hp0
			var good: bool = t_wind > 0.0 and dir_ok and fan_shown and hp_in_wind and dashed and wind_len > 0.45 and wind_len < 0.75 and moved > 0.3
			if trial == 0:
				good = good and hurt
			else:
				good = good and not hurt and open_seen and rec_seen
			lunge_ok.append(good)
			lunge_why.append("trial %d: winds up=%s locked=%s fan=%s no hurt in the wind-up=%s wind-up %.2f s dash %.2f tiles hurt=%s seam=%s rest=%s" % [trial, t_wind > 0.0, dir_ok, fan_shown, hp_in_wind, wind_len, moved, hurt, open_seen, rec_seen])
			g.dead = true
			g.node.queue_free()
			g.shadow.queue_free()
		reset_to(C)
		calm_enemies(false)
		park_mates(false)
		check("goblin_lunge", lunge_ok[0] and lunge_ok[1], " | ".join(lunge_why))
	if want.call("archer_backoff"):
		var C := open_field()
		# an archer with Sora inside 2 tiles hops back 1.2 tiles (once in 3 s, no damage); from further out it aims 0.65 s,
		# the line turns white for the last 0.25 s and the brick (6 tiles/s, 1.2 s, 10 + level) follows the locked line
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		reset_to(C)
		main.spawn_enemy(C + Vector2(1.5, 0), true)
		var ar: Dictionary = main.enemies[main.enemies.size() - 1]
		ar.cave = true
		ar.hp = 99999.0
		ar.atk_cd = 9.0
		ar.hop_cd = 0.0
		var hp0: float = main.player.hp
		var ax0: float = ar.x
		var hopped := false
		for i in 12:
			await wait(0.05)
			if ar.get("hop", 0.0) > 0.0:
				hopped = true
		var back_off: float = ar.x - ax0
		var cooled: bool = ar.hop_cd > 2.0
		reset_to(Vector2(ar.x - 1.5, ar.z)) # inside 2 tiles again straight away
		var twice := false
		for i in 12:
			await wait(0.05)
			if ar.get("hop", 0.0) > 0.0:
				twice = true
		var calm_hop: bool = main.player.hp == hp0
		# the aim
		ar.x = C.x + 4.5
		ar.z = C.y
		ar.hop_cd = 20.0
		ar.atk_cd = 0.0
		ar.wind = 0.0
		ar.hurt = 0.0
		reset_to(C)
		main.enemy_shots.clear()
		var t_wind := -1.0
		var t_lock := -1.0
		var red_before := false
		var white_at_lock := false
		var t_shot := -1.0
		var shot_ok := false
		var shot_why := ""
		for i in 60:
			await wait(0.05)
			var now := gsec()
			var tl = ar.get("tele", null)
			if ar.get("wind", 0.0) > 0.0 and t_wind < 0.0:
				t_wind = now
			if t_wind > 0.0 and ar.get("aim_locked", false) and t_lock < 0.0:
				t_lock = now
				reset_to(C + Vector2(0, 3)) # steps aside once the line is locked
				if tl != null and is_instance_valid(tl):
					var c: Color = tl.get_meta("mat").albedo_color
					white_at_lock = c.g > 0.9 and c.b > 0.9
			if t_wind > 0.0 and t_lock < 0.0 and tl != null and is_instance_valid(tl) and now - t_wind > 0.1:
				var c2: Color = tl.get_meta("mat").albedo_color
				red_before = c2.g < 0.5
			if not main.enemy_shots.is_empty() and t_shot < 0.0:
				t_shot = now
				var sh: Dictionary = main.enemy_shots[0]
				shot_ok = absf(sh.v.length() - 6.0) < 0.01 and sh.v.x < -5.8 and absf(sh.v.y) < 0.4 and absf(sh.life - 1.2) < 0.15 and sh.dmg == 10 + main.foe_hit()
				shot_why = "v %s life %.2f dmg %d" % [sh.v, sh.life, sh.dmg]
				break
		var aim_len: float = t_shot - t_wind
		var lock_at: float = t_lock - t_wind
		for e in main.enemy_shots:
			e.node.queue_free()
		main.enemy_shots.clear()
		ar.dead = true
		ar.node.queue_free()
		ar.shadow.queue_free()
		calm_enemies(false)
		park_mates(false)
		check("archer_backoff", hopped and back_off > 0.9 and cooled and not twice and calm_hop and t_shot > 0.0 and aim_len > 0.55 and aim_len < 0.85 and lock_at > 0.3 and lock_at < 0.5 and red_before and white_at_lock and shot_ok,
			"hopped=%s back %.2f tiles cooldown=%s no second hop=%s no damage=%s | aim %.2f s locked at %.2f s red before=%s white at lock=%s shot %s (%s)" % [hopped, back_off, cooled, not twice, calm_hop, aim_len, lock_at, red_before, white_at_lock, shot_ok, shot_why])
	if want.call("wolf_turns"):
		var C := open_field()
		# three wolves: never two charging at once, a charge starts at least 0.4 s after the last one ends, more than one
		# wolf gets a turn, and while one charges another waits on the far side
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		reset_to(C)
		main.monsters.wolf_gap = 0.0
		var wl: Array = []
		for a in [0.4, 2.5, 4.6]:
			main.spawn_wolf(C + Vector2(4.0, 0).rotated(a))
			var w: Dictionary = main.enemies[main.enemies.size() - 1]
			w.hp = 99999.0
			w.atk_cd = 0.0
			wl.append(w)
		var hp_full: float = main.player.hp
		var overlap := false
		var charged: Dictionary = {}
		var last_end := -9.0
		var last_active := false
		var short_gap := false
		var far_side := false
		var starts: Array = []
		for i in 190:
			reset_to(C)
			main.player.hp = hp_full
			var act: Array = wl.filter(func(e): return e.wind > 0.0 or e.dash > 0.0)
			var now := gsec()
			if act.size() > 1:
				overlap = true
			if act.size() == 1:
				if not last_active and now - last_end < 0.1: # 0.2 s of gap at FOE_PACE, sampled every step
					short_gap = true
				if act[0].dash > 0.0:
					charged[act[0].gid] = true
				var ang_a: float = atan2(act[0].z - C.y, act[0].x - C.x)
				for w in wl:
					if w.gid == main.monsters.wolf_circler and w.gid != act[0].gid:
						var off: float = absf(wrapf(atan2(w.z - C.y, w.x - C.x) - ang_a, -PI, PI))
						if off > deg_to_rad(55.0) and off < deg_to_rad(125.0):
							far_side = true
			elif last_active:
				last_end = now
			last_active = act.size() == 1
			await wait(0.05)
		for w in wl:
			w.dead = true
			w.node.queue_free()
			w.shadow.queue_free()
		calm_enemies(false)
		park_mates(false)
		check("wolf_turns", not overlap and not short_gap and charged.size() >= 2 and far_side,
			"never two at once=%s, 0.4 s gap kept=%s, wolves that charged=%d, a second wolf on the far side meanwhile=%s" % [not overlap, not short_gap, charged.size(), far_side])
	if want.call("bat_double"):
		var C := open_field()
		# a swoop that misses is followed by one more (turned round); a swoop that hits is not; a blow on the bat during
		# the second wind-up calls it off
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		reset_to(C)
		main.spawn_bat(C + Vector2(3, 0))
		var bt: Dictionary = main.enemies[main.enemies.size() - 1]
		bt.hp = 99999.0
		var res: Array = []
		var why: Array = []
		for trial in 3:
			reset_to(C)
			main.player.hp = float(main.player.max_hp)
			main.player.inv = 5.0 if trial != 1 else 0.0 # a trial that hits and two that miss
			bt.x = C.x + 1.8 # close enough that the dash carries it past her: the second swoop comes back the other way
			bt.z = C.y
			bt.wind = 0.0
			bt.dash = 0.0
			bt.rest = 0.0
			bt.hurt = 0.0
			bt.stun = 0.0
			bt.swoops = 0
			bt.landed = false
			bt.atk_cd = 0.0
			var dashes := 0
			var was_dash := false
			var dirs: Array = []
			var wind_dir_ok := true
			var rest_after := false
			var cd_after := 0.0
			var cut := false
			var cut_left := 0
			var shown := false
			var hp0: float = main.player.hp
			for i in 70:
				if trial != 1:
					main.player.inv = 5.0
				await wait(0.05)
				if bt.wind > 0.0:
					var tl = bt.get("tele", null)
					shown = shown or (tl != null and is_instance_valid(tl) and tl.visible)
					if trial == 2 and bt.swoops == 1 and not cut:
						cut = true
						main.damage_enemy(bt, 1.0, Vector2(bt.x - 1.0, bt.z), 0.0) # a blow on the second wind-up
				if bt.dash > 0.0 and not was_dash:
					dashes += 1
					dirs.append(bt.dir)
				was_dash = bt.dash > 0.0
				if dashes == (1 if trial == 1 else 2) and bt.rest > 0.0:
					rest_after = true
					cd_after = bt.atk_cd
					break
				if cut and bt.dash <= 0.0 and bt.wind <= 0.0 and i > 0:
					cut_left += 1
					if cut_left > 12:
						break # half a second after the blow: the bat has not swooped again
			var turned: bool = dirs.size() == 2 and dirs[0].dot(dirs[1]) < 0.0
			var hurt: bool = main.player.hp < hp0
			if trial == 0:
				res.append(dashes == 2 and turned and rest_after and cd_after > 2.0 and shown)
			elif trial == 1:
				res.append(dashes == 1 and hurt and rest_after)
			else:
				res.append(dashes == 1 and cut)
			why.append("trial %d dashes=%d turned=%s rest=%s cd=%.1f hurt=%s line=%s" % [trial, dashes, turned, rest_after, cd_after, hurt, shown])
		main.player.inv = 0.0
		bt.dead = true
		bt.node.queue_free()
		bt.shadow.queue_free()
		calm_enemies(false)
		park_mates(false)
		check("bat_double", res[0] and res[1] and res[2], " | ".join(why))
	if want.call("hog_roll"):
		var C := open_field()
		# a hedgehog 3 tiles away rolls toward where she stood (path and burst circle shown, no damage on the way), stops,
		# warns 0.6 s at the real stop and then bursts; with a wall in the way it stops short and still warns the full 0.6 s
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		var rolls: Array = []
		var rwhy: Array = []
		# a spot with a wall 0.8 tiles ahead and open ground 3 tiles ahead, found on the marsh grid
		var wall_at := Vector2(-1, -1)
		for gx in range(6, 44):
			for gz in range(6, 60):
				var px := float(gx) + 0.5
				var pz := float(gz) + 0.5
				if main.walkable(px, pz) and main.walkable(px - 1.0, pz) and not main.walkable(px + 0.8, pz) and main.walkable(px + 3.0, pz) and wall_at.x < 0.0:
					wall_at = Vector2(px, pz)
		for trial in 2:
			if trial == 1 and wall_at.x < 0.0:
				rolls.append(true)
				rwhy.append("trial 1: no wall spot found on the marsh grid, skipped")
				continue
			var from_p := C + Vector2(3.0, 0.0) if trial == 0 else wall_at
			var sora_p := C if trial == 0 else wall_at + Vector2(3.0, 0.0)
			reset_to(sora_p)
			main.player.inv = 0.0
			main.monsters.spawn_hog(from_p)
			var h: Dictionary = main.enemies[main.enemies.size() - 1]
			h.hp = 99999.0
			h.atk_cd = 0.0
			var hp0: float = main.player.hp
			var t_roll := -1.0
			var t_stop := -1.0
			var t_burst := -1.0
			var locked := true
			var safe_en_route := true
			var rd := Vector2.ZERO
			for i in 60:
				await wait(0.05)
				var now := gsec()
				if h.rolling and t_roll < 0.0:
					t_roll = now
					rd = h.rdir
					if trial == 0:
						reset_to(C) # stays put: the burst should reach her
				if h.rolling and h.rdir != rd:
					locked = false
				if h.rolling and h.curl > 0.6 and main.player.hp < hp0:
					safe_en_route = false
				if t_roll > 0.0 and t_stop < 0.0 and h.curl <= 0.6 and h.curl > 0.0:
					t_stop = now
				if t_stop > 0.0 and t_burst < 0.0 and h.dizzy > 0.0:
					t_burst = now
					break
			var moved: float = Vector2(h.x, h.z).distance_to(from_p)
			var warn: float = t_burst - t_stop
			var hit: bool = main.player.hp < hp0
			var good: bool = t_roll > 0.0 and locked and safe_en_route and warn > 0.5 and warn < 0.8 and h.atk_cd > 2.0
			if trial == 0:
				good = good and moved > 1.2 and moved < 1.6 and hit
			else:
				good = good and moved < 1.0 and not hit
			rolls.append(good)
			rwhy.append("trial %d rolled=%s locked=%s no damage on the way=%s travelled %.2f warning %.2f s hit=%s" % [trial, t_roll > 0.0, locked, safe_en_route, moved, warn, hit])
			h.dead = true
			h.node.queue_free()
			h.shadow.queue_free()
		reset_to(C)
		calm_enemies(false)
		park_mates(false)
		check("hog_roll", rolls[0] and rolls[1], " | ".join(rwhy))
	if want.call("new_foes"):
		# the four brick field foes (벽돌 딱따기새, 등나방, 씨앗통, 추시계병): each telegraphs, strikes where it warned and nowhere
		# else, and shows its opening where specified; hp/damage scale from the goblin's; their spots lie on open floor
		main.close_story()
		calm_enemies(true)
		park_mates(true)
		var C := open_field()
		var res: Array = []
		var why: Array = []
		var lv: int = main.foe_lv()
		var hp_k := {"bird": 0.8, "moth": 0.6, "hopper": 1.0, "pendulum": 1.2}
		var ok_all := true
		for kind in ["bird", "moth", "hopper", "pendulum"]:
			var hit_in := false
			var hit_out := true
			var line := ""
			for inside in [true, false]:
				var r: Dictionary = await nf_trial(kind, inside, C)
				lv = main.foe_lv() # by Sora's x (area_step): read where the trial stood her, not where she was before
				var good: bool = r.tele > 0.0 and r.hp == int(round(hp_k[kind] * (30 + lv * 14)))
				if inside:
					good = good and r.hit
					hit_in = r.hit
				else:
					good = good and not r.hit
					hit_out = r.hit
				match kind:
					"bird": good = good and r.seam > 0.0 and r.seam_len > 0.8 and r.seam_len < 0.95 and r.seam_at > 0.45 and r.seam_at < 0.85
					"moth": good = good and r.rest > 0.0 and r.burst_at > 0.55 and r.burst_at < 0.95
					"hopper": good = good and r.shots >= 3 and r.fire_at > 0.65 and r.fire_at < 1.1 # 0.8 s lid plus frames; 1.01 in a loaded full run
					"pendulum": good = good and r.sweep > 0.0 and r.seam_gap > 0.8 and r.seam_gap < 1.35 and r.seam_len > 0.9 and r.seam_len < 1.05
				ok_all = ok_all and good
				line += "%s hit=%s tele=%.2f " % ["in" if inside else "out", r.hit, r.tele]
				if inside:
					line += "[hp %d (want %d) seam %.2f at %.2f len %.2f rest %.2f burst %.2f shots %d fire %.2f sweep %.2f gap %.2f] " % [r.hp, int(round(hp_k[kind] * (30 + lv * 14))), r.seam, r.seam_at, r.seam_len, r.rest, r.burst_at, r.shots, r.fire_at, r.sweep, r.seam_gap]
			why.append("%s: %s" % [kind, line.strip_edges()])
		# where they live: every spot on open floor, the village moths 6+ tiles from villagers, stalls and lanterns, no sentry near a diary page
		var spots_ok := true
		var bad: Array = []
		for area in ["castle", "stairs", "garden"]:
			for f in main.brick_foes.spots(area):
				var at: Vector2 = f[0]
				var c: String = {"castle": main.castle, "stairs": main.stairs, "garden": main.garden}[area].char_at(at.x, at.y)
				if not main.walkable(at.x, at.y) or c not in ".,":
					spots_ok = false
					bad.append("%s %s '%s'" % [area, at, c])
				if area == "castle":
					for pg in main.castle.pages:
						if pg.pos.distance_to(at) < 4.0:
							spots_ok = false
							bad.append("page near %s" % at)
		var folk_tiles: Array = []
		for fk in main.village.FOLK:
			folk_tiles.append(Vector2(fk.at.x, fk.at.y))
		for z in main.village.grid.size():
			for x in main.village.grid[z].length():
				if main.village.grid[z][x] in "Ld123NM":
					folk_tiles.append(Vector2(x, z))
		for p in main.brick_foes.MOTH_SPOTS:
			var tile := Vector2(p.x, p.y)
			if main.village.grid[p.y][p.x] not in ".=" or folk_tiles.any(func(q): return q.distance_to(tile) < 6.0):
				spots_ok = false
				bad.append("moth %s" % tile)
		# no moths in the village, night or day (v0.1.80; they were up at night from v0.1.33)
		var moths_night := 0
		var moths_day := 0
		var was_v: bool = main.in_village
		var was_h: float = main.hour
		main.in_village = true
		main.hour = 22.0
		main.brick_foes.village_moths()
		moths_night = main.enemies.filter(func(e): return e.get("moth", false) and not e.dead).size()
		main.hour = 12.0
		main.brick_foes.village_moths()
		moths_day = main.enemies.filter(func(e): return e.get("moth", false)).size()
		main.in_village = was_v
		main.hour = was_h
		var marsh_birds: int = main.enemies.filter(func(e): return e.get("bird", false)).size()
		check("new_foes", ok_all and spots_ok and moths_night == 0 and moths_day == 0 and marsh_birds >= 2,
			"%s | spots ok=%s %s | moths night %d day %d | marsh birds %d" % [" | ".join(why), spots_ok, bad, moths_night, moths_day, marsh_birds])
		reset_to(C)
		calm_enemies(false)
		park_mates(false)
	if want.call("stage_noeul"):
		# ?stage=noeul: the preset save puts Sora in the village on the lantern night, and Noeul comes for the lamps
		main.close_story()
		var keep_nq: int = main.night_q
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(main.STAGES["noeul"]))
		f.close()
		main.load_game()
		main.close_story()
		var began := false
		for k in 12:
			await wait(0.25)
			if main.night_q == 1:
				began = true
				break
		main.close_story()
		check("stage_noeul", began and main.in_village, "in the village=%s Noeul's chase began=%s (night_q %d, hour %.1f)" % [main.in_village, began, main.night_q, main.hour])
		main.night_q = keep_nq
		main.return_to_start() # last: the loaded stage is left behind
	if want.call("token_gates"):
		# the moonkeeper tokens (v0.1.62): the road to the forest, the hill and the castle holds until its token is in, then
		# opens; an area already entered is never locked again; the gate's need is named in the quest line, and the gold "!" shows it
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		calm_enemies(true)
		main.tokens = [false, false, false, false, false, false]
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.garden_q = 0 # an earlier test left the ending done: the road line would be the clock room's
		var why: Array = []
		var vf: Vector2 = main.village.marks.F
		# 1. the village's east gate: the pearl token
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 0
		main.hill_q = 0
		main.castle_q = 0
		main.in_forest = false
		main.in_hill = false
		main.in_village = true
		reset_to(vf + Vector2(-0.3, 0))
		await wait(1.0)
		var g1: bool = main.in_village and not main.in_forest and main.forest_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "진주" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(vf) > 1.0
		main.close_story()
		var q1: bool = main.main_road_quest().begins_with("숲으로 가기 전에")
		main.tokens[2] = true
		main.south_q = 4
		main.corridor_q = 6 # and the water corridor (v0.1.84)
		reset_to(vf + Vector2(-0.3, 0))
		await wait(1.5)
		var o1: bool = main.in_forest and main.forest_q == 1
		main.close_story()
		if not (g1 and q1 and o1):
			why.append("forest gate held=%s quest=%s opened=%s" % [g1, q1, o1])
		# 2. the forest's east end: the squirrels token
		main.forest.freed = [false, false, false, false, false] # the squirrels test left them freed
		main.forest_q = 3
		main.hill_q = 0
		var fe: Vector2 = main.forest.marks.E
		reset_to(fe + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.0)
		var g2: bool = main.in_forest and not main.in_hill and main.hill_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "다섯 우리" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(fe) > 1.0
		main.close_story()
		var q2: bool = main.main_road_quest().begins_with("언덕으로 가기 전에") and main.main_road_quest().ends_with("0/5")
		main.set_quest(main.main_road_quest())
		var mark2: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var cage_near := Vector2.INF
		for cg in main.FOREST.CAGES:
			var cp: Vector2 = cg + Vector2(main.FOREST.FOREST_X, 0)
			if cage_near == Vector2.INF or Vector2(main.player.x, main.player.z).distance_to(cp) < Vector2(main.player.x, main.player.z).distance_to(cage_near):
				cage_near = cp
		var m2: bool = mark2 != Vector3.INF and Vector2(mark2.x, mark2.z).distance_to(cage_near) < 0.1
		main.forest.freed = [true, true, true, false, false]
		var q2b: bool = main.main_road_quest().ends_with("3/5")
		main.forest.freed = [false, false, false, false, false]
		main.tokens[3] = true
		main.hollow_q = 3
		reset_to(fe + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.5)
		var o2: bool = main.in_hill and main.hill_q == 1
		main.close_story()
		if not (g2 and q2 and m2 and q2b and o2):
			why.append("hill gate held=%s quest=%s mark=%s count=%s opened=%s" % [g2, q2, m2, q2b, o2])
		# 3. the hill's east end: the hill deed
		main.hill_q = 3
		main.castle_q = 0
		var hx: Vector2 = main.hill.marks.X
		reset_to(hx + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.0)
		var g3: bool = main.in_hill and not main.in_castle() and main.castle_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "참새 풍차" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(hx) > 1.0
		main.close_story()
		var q3: bool = main.main_road_quest().begins_with("성으로 가기 전에")
		main.set_quest(main.main_road_quest())
		reset_to(main.hill.marks.S + Vector2(2, 0))
		var mark3: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var m3: bool = mark3 != Vector3.INF and (Vector2(mark3.x, mark3.z).distance_to(main.hill.south_marks.G) < 0.1 or Vector2(mark3.x, mark3.z).distance_to(main.hill.marks.R) < 0.1)
		main.moon_tokens.earn(4) # the deed done: the need line goes back to the road
		main.mill_q = 5 # both the mill and the trial (v0.1.68)
		main.trial_won = true
		main.observatory_q = 6 # and the observatory (v0.1.120)
		main.moon_tokens.refresh_quest()
		var back3: bool = main.quest_raw == "언덕 동쪽 끝 길로, 달지기들의 성에 가자"
		reset_to(hx + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.5)
		var o3: bool = main.in_castle() and main.castle_q == 1
		main.close_story()
		if not (g3 and q3 and m3 and back3 and o3):
			why.append("castle gate held=%s quest=%s mark=%s back to the road=%s opened=%s" % [g3, q3, m3, back3, o3])
		# 4. the lake: the line points at the grotto; an area already entered is never locked again
		main.tokens = [false, false, false, false, false, false]
		main.forest_q = 0
		main.hill_q = 0
		main.castle_q = 0
		main.in_hill = false
		main.in_lake = true
		main.in_village = false
		reset_to(main.lake.marks.P)
		main.set_quest(main.main_road_quest())
		var mark4: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var m4: bool = mark4 != Vector3.INF and Vector2(mark4.x, mark4.z).distance_to(main.lake.marks.G) < 0.1
		var holds_all: bool = main.moon_tokens.holds("forest")
		main.forest_q = 1
		main.hill_q = 1
		main.castle_q = 1
		var never: bool = not main.moon_tokens.holds("forest") and not main.moon_tokens.holds("hill") and not main.moon_tokens.holds("castle")
		main.forest_q = 0
		main.south_q = 4
		main.corridor_q = 6 # and the water corridor (v0.1.84)
		main.moon_tokens.earn(2) # the pearl: the line goes back to the road
		var back4: bool = not main.quest_raw.begins_with("숲으로 가기 전에")
		if not (m4 and holds_all and never and back4):
			why.append("lake mark=%s holds=%s never relocked=%s back=%s" % [m4, holds_all, never, back4])
		# 5. a waystone lists only the stones reached, so none skips a gate
		main.forest_q = 0
		main.hill_q = 0
		main.castle_q = 0
		main.road_q = 0
		var skip: bool = not main.way_known(3) and not main.way_known(4) and not main.way_known(5) and not main.way_known(6)
		if not skip:
			why.append("a waystone known before its area was entered")
		main.in_lake = false
		main.return_to_start()
		calm_enemies(false)
		check("token_gates", why.is_empty(), "the pearl, squirrels and hill-deed gates hold, push Sora back with the story and open with the token; never re-lock; quest lines and marks: %s" % ("; ".join(why) if not why.is_empty() else "ok"))
	if want.call("token_stairs"):
		# the moon stairs' top door asks for 4 of the 6 tokens while the yard below was never entered (v0.1.62)
		main.story_step = maxi(main.story_step, 11)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_cave = false
		main.in_garden = false
		main.in_hill = true
		main.forest_q = 3
		main.hill_q = 3
		main.castle_q = 3
		main.hollow_q = 4
		main.garden_q = 0
		main.road_q = 0
		main.quarters_q = 5 # the castle gate asks for the quarters (v0.1.68)
		main.open_stairs()
		main.garden.roots_open = false
		main.garden.gate_open = false
		main.garden.reveal(false)
		for r in main.garden.roots:
			r[1].visible = true
		main.tokens = [true, true, true, false, false, false]
		var sn: Vector2 = main.stairs.marks.N
		reset_to(sn + Vector2(0, 0.3))
		main.player.inv = 99.0
		await wait(1.0)
		var held: bool = main.in_stairs() and not main.in_garden and main.road_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "넷" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(sn) > 1.0
		main.close_story()
		var line: String = main.main_road_quest()
		var named: bool = line.begins_with("정원 문 앞에서") and "3/4" in line
		main.tokens[3] = true # the fourth: open
		var line2: String = main.moon_tokens.stairs_line(main.STAIRS_DONE_QUEST)
		reset_to(sn + Vector2(0, 0.3))
		main.player.inv = 99.0
		await wait(1.5)
		var opened: bool = main.in_garden and main.road_q == 1
		main.close_story()
		# not while road_q is past 0, nor once the arena was reached
		main.tokens = [false, false, false, false, false, false]
		main.road_q = 1
		var free1: bool = not main.moon_tokens.holds("garden")
		main.road_q = 0
		main.garden_q = 1
		var free2: bool = not main.moon_tokens.holds("garden")
		main.garden_q = 0
		var shut0: bool = main.moon_tokens.holds("garden")
		check("token_stairs", held and named and line2 == main.STAIRS_DONE_QUEST and opened and free1 and free2 and shut0,
			"3 of 6 holds the door with the story=%s, quest names 3/4=%s, 4 of 6 opens=%s (road_q %d), road_q 1 free=%s garden_q 1 free=%s, none holds=%s" % [held, named, opened, main.road_q, free1, free2, shut0])
		main.road_q = 0
		main.return_to_start()
	if want.call("token_ui"):
		# the HUD row of six gems, the journal's count and its six lines, and the toast and burst when one is earned (v0.1.62)
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.tokens = [true, false, true, false, false, false]
		await wait(0.4)
		var hud: Control = main.ui.hud
		var hud_ok: bool = hud.tokens_drawn == 6 and hud.tokens_lit == 2 and hud.token_spots().size() == 6
		var spots: Array = hud.token_spots()
		var under: bool = (spots[0] as Vector2).y > (hud.pip_spots()[0] as Vector2).y and (spots[5] as Vector2).x + 6.0 <= hud.bars_end()
		var jl: String = "\n".join(PackedStringArray(main.journal_lines()))
		var jour: bool = "달지기 보석 2/6" in jl
		for nm in main.moon_tokens.NAMES:
			jour = jour and plain(nm) in jl
		main.tokens[0] = false
		main.tokens[2] = false
		main.toast_t = 0.0
		var n0: int = main.tokens.count(true)
		main.moon_tokens.earn(3)
		var toast: bool = "(1/6)" in main.ui.toast.text and main.tokens[3] and main.toast_t > 0.0
		main.moon_tokens.earn(3) # twice counts once
		var once: bool = main.moon_tokens.count() == n0 + 1
		await wait(0.3)
		var hud2: bool = hud.tokens_lit == 1
		var jour2: bool = "달지기 보석 1/6" in "\n".join(PackedStringArray(main.journal_lines()))
		check("token_ui", hud_ok and under and jour and toast and once and hud2 and jour2,
			"HUD six gems, two lit=%s under the moon gauge inside the bars=%s, journal 2/6 with the six names=%s, earning toasts (1/6)=%s counts once=%s, HUD lit 1=%s, journal 1/6=%s" % [hud_ok, under, jour, toast, once, hud2, jour2])
		main.tokens = [false, false, false, false, false, false]
	if want.call("token_old_save"):
		# a save from before the tokens has no "tokens" key: they come from the flags once, as if earned (v0.1.62)
		main.return_to_start()
		main.tokens = [false, false, false, false, false, false]
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		sd.erase("tokens")
		sd["fly_q"] = 3
		sd["has_ring"] = true
		sd["has_pearl"] = true
		sd["freed"] = [true, true, true, true, true]
		sd["mill_q"] = 5
		sd["books"] = [true, true, true, false, false]
		sd["has_bookmark"] = false
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(sd))
		f.close()
		main.load_game()
		var a: Array = main.tokens.duplicate()
		var all_but_library: bool = a == [true, true, true, true, true, false] and main.crystal_done and not main.crystal_chest.visible
		# only the moon trial and the five books: the hill deed and the library
		sd["fly_q"] = 0
		sd["has_ring"] = false
		sd["has_pearl"] = false
		sd["freed"] = [false, false, true, false, false]
		sd["mill_q"] = 0
		sd["trial_best"] = 91.5
		sd["books"] = [true, true, true, true, true]
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(sd))
		f.close()
		main.load_game()
		var b: Array = main.tokens.duplicate()
		var trial_books: bool = b == [false, false, false, false, true, true]
		# a save with the key keeps exactly what it says, whatever the flags are
		sd["tokens"] = [false, true, false, false, false, false]
		f = FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(sd))
		f.close()
		main.load_game()
		var c: Array = main.tokens.duplicate()
		var as_saved: bool = c == [false, true, false, false, false, false]
		check("token_old_save", all_but_library and trial_books and as_saved,
			"flags with no key give %s (ring chest shut and done=%s), trial + five books give %s, a saved key is kept %s" % [str(a), all_but_library, str(b), str(c)])
	if want.call("token_new_round"):
		# a new round keeps the pearl, ring and bookmark but starts with no tokens, so the gates hold again (v0.1.62)
		main.return_to_start()
		main.has_pearl = true
		main.has_ring = true
		main.has_bookmark = true
		main.tokens = [true, true, true, true, true, true]
		var ng_before: int = main.ng
		main.write_new_round()
		var nd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var file_ok: bool = nd.get("tokens", []) == [false, false, false, false, false, false] and bool(nd.get("has_pearl", false)) and bool(nd.get("has_ring", false)) and bool(nd.get("has_bookmark", false)) and int(nd.get("ng", 0)) == ng_before + 1
		main.load_game()
		var none: bool = main.tokens == [false, false, false, false, false, false] and main.moon_tokens.count() == 0
		var kept: bool = main.has_pearl and main.has_ring and main.has_bookmark
		var gates: bool = main.forest_q == 0 and main.moon_tokens.holds("forest") and main.moon_tokens.holds("hill") and main.moon_tokens.holds("castle") and main.moon_tokens.holds("garden")
		var ring_again: bool = not main.crystal_done and not main.crystal_chest.visible # the ring puzzle plays again for this round's token
		check("token_new_round", file_ok and none and kept and gates and ring_again,
			"new-round file has six empty tokens and the keepsakes=%s, loaded with no tokens=%s keeping pearl/ring/bookmark=%s, the four gates hold=%s, crystals open again=%s" % [file_ok, none, kept, gates, ring_again])
		main.ng = 0
	if want.call("token_fix"):
		# GPT report on v0.1.62/65: a held gate renames the quest (also on load), the stairs line has a mark, this round's
		# cages decide the squirrel journal and hint, and a squirrel cage (prop) does not stop resting
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.tokens = [false, false, false, false, false, false]
		main.has_pearl = false
		main.lake_q = 4
		main.forest_q = 0
		main.hill_q = 0
		main.castle_q = 0
		main.road_q = 0
		main.garden_q = 0
		var old_line := "물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"
		main.set_quest(old_line)
		main.save_game()
		main.load_game() # an old save at lake_q 4, forest_q 0, no pearl: the gate line, not the shut east gate
		var load_ok: bool = main.quest_raw.begins_with("숲으로 가기 전에")
		main.set_quest(old_line)
		main.story_open = false
		main.moon_tokens.gate("forest", main.village.marks.F)
		var gate_ok: bool = main.quest_raw.begins_with("숲으로 가기 전에")
		main.close_story()
		main.set_quest("언덕 동쪽 끝 길로, 달지기들의 성에 가자") # the hill gate: the squirrel line
		main.forest_q = 3
		main.story_open = false
		main.moon_tokens.gate("hill", main.forest.marks.E)
		var gate2_ok: bool = main.quest_raw.begins_with("언덕으로 가기 전에")
		main.close_story()
		# the stairs line (3 required tokens, the library missing) has a mark: out of the stairs, then the unread book
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_cave = false
		main.in_garden = false
		main.in_hill = true
		main.hill_q = 3
		main.castle_q = 3
		var wall0: bool = main.stairs.wall_open
		var door0: bool = main.stairs.door_open
		main.stairs.wall_open = true
		main.stairs.door_open = true
		main.tokens = [false, false, true, true, true, false]
		main.set_quest(main.moon_tokens.garden_need_line())
		reset_to(main.stairs.marks.N + Vector2(0, 0.3))
		var t1: Vector3 = main.quest_marks.quest_target()
		var s_ok: bool = main.in_stairs() and t1 != Vector3.INF and Vector2(t1.x, t1.z).distance_to(main.stairs.marks.S) < 0.5
		var read0: Array = main.castle.books.map(func(b): return b.read) # earlier tests may have read them
		main.castle.books[0].read = false
		var unread: Array = main.castle.books.filter(func(b): return not b.read).map(func(b): return b.pos)
		reset_to(main.castle.marks.S + Vector2(2.0, 0.0))
		var t2: Vector3 = main.quest_marks.quest_target()
		var c_ok: bool = main.in_castle() and t2 != Vector3.INF and not unread.is_empty() and unread.any(func(p): return Vector2(t2.x, t2.z).distance_to(p) < 0.5)
		for i in main.castle.books.size():
			main.castle.books[i].read = read0[i]
		main.tokens = [false, false, true, true, false, true] # the hill deed missing instead: out of the castle, then the hill's deed
		var t3: Vector3 = main.quest_marks.quest_target()
		var w_ok: bool = t3 != Vector3.INF and Vector2(t3.x, t3.z).distance_to(main.castle.marks.S) < 0.5
		reset_to(main.hill.marks.S + Vector2(2.0, 0.0))
		var t4: Vector3 = main.quest_marks.quest_target()
		var h_ok: bool = not main.in_castle() and not main.in_stairs() and t4 != Vector3.INF and Vector2(t4.x, t4.z).distance_to(main.castle.marks.S) > 30.0
		# the squirrels: the kept acorn does not finish this round's cages
		main.tokens = [false, false, false, false, false, false]
		main.has_acorn = true
		main.forest_q = 1
		main.lake_q = 4
		main.forest.freed = [false, false, false, false, false]
		var jl1: String = "
".join(PackedStringArray(main.journal_lines()))
		var open1: bool = main.errands.hint_open("squirrels")
		var j_open: bool = "0/5 구함" in jl1 and open1
		main.tokens[3] = true
		var jl2: String = "
".join(PackedStringArray(main.journal_lines()))
		var j_done: bool = not main.errands.hint_open("squirrels") and "0/5 구함" not in jl2
		main.tokens = [false, false, false, false, false, false]
		main.has_acorn = false
		# resting beside a cage
		var keep_e: Array = main.enemies.duplicate()
		var boss1: bool = main.ui.boss.visible
		main.ui.boss.visible = false
		main.story_open = false
		main.enemies.clear()
		var mx: float = float(main.player.max_hp)
		main.player.hp = mx * 0.5
		main.idle_t = 4.0
		main.enemies.append({"x": main.player.x + 1.5, "z": main.player.z, "dead": false, "prop": true})
		main.combat.rest_heal(1.0)
		var by_cage: float = main.player.hp - mx * 0.5
		main.player.hp = mx * 0.5
		main.enemies[0]["prop"] = false
		main.combat.rest_heal(1.0)
		var by_foe: float = main.player.hp - mx * 0.5
		main.enemies.clear()
		main.enemies.append_array(keep_e)
		main.ui.boss.visible = boss1
		main.player.hp = mx
		check("token_fix", load_ok and gate_ok and gate2_ok and s_ok and c_ok and w_ok and h_ok and j_open and j_done and absf(by_cage - mx * 0.02) < 0.01 and by_foe == 0.0,
			"old save loads on the pearl line=%s, forest gate renames=%s, hill gate renames=%s, stairs mark leads out=%s, castle mark on an unread book=%s, castle exit toward the hill deed=%s, hill mark=%s, squirrel journal open + hint with the acorn kept=%s, done with the token=%s, rest by a cage healed %.2f (want %.2f), by a real foe %.2f" % [load_ok, gate_ok, gate2_ok, s_ok, c_ok, w_ok, h_ok, j_open, j_done, by_cage, mx * 0.02, by_foe])
		main.tokens = [false, false, false, false, false, false]
		main.stairs.wall_open = wall0
		main.stairs.door_open = door0
		main.return_to_start()
	if want.call("token_fix2"):
		# GPT report 2 on v0.1.66: the ring earned in the cave refreshes the kept stairs line on leaving, the grotto has a mark
		# out after the first pearl, and a new round judges the trial by this round's hill token (the best time is kept)
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		var old_best: float = main.trial_best
		var door0: bool = main.stairs.door_open
		main.stairs.door_open = true
		main.tokens = [false, false, true, true, true, false]
		main.road_q = 0
		main.garden_q = 0
		main.in_cave = true
		main.quest_before_cave = main.moon_tokens.garden_need_line() # 3/4, kept from before the cave
		main.moon_tokens.earn(main.moon_tokens.RING) # the fourth token, earned inside
		main.leave_cave()
		var cave_ok: bool = main.moon_tokens.count() == 4 and not main.quest_raw.begins_with("정원 문 앞에")
		# the grotto: the pearl is in, the line is the east gate; the mark leads out of the grotto
		main.in_cave = false
		main.in_village = false
		main.in_forest = false
		main.in_garden = false
		main.in_hill = false
		main.in_lake = true
		main.lake_q = 4
		main.grotto_q = 4
		main.set_quest("물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자")
		reset_to(main.grotto.marks.C)
		main.close_story() # entering the grotto opens its story
		main.story_open = false
		var g1: Vector3 = main.quest_marks.quest_target()
		var grotto_ok: bool = main.in_grotto() and g1 != Vector3.INF and Vector2(g1.x, g1.z).distance_to(main.grotto.marks.S) < 0.5
		# a new round: the trial best is kept, the hill token is not
		main.trial_best = 95.0
		main.hill_q = 3
		main.tokens = [false, false, false, false, false, false]
		main.trial_won = false
		var jl1: String = "
".join(PackedStringArray(main.journal_lines()))
		var t_open: bool = main.errands.hint_open("trial") and "이번 회차" in jl1 and "최고 기록 1분 35초" in jl1
		main.tokens[main.moon_tokens.HILL] = true
		main.trial_won = true
		var jl2: String = "
".join(PackedStringArray(main.journal_lines()))
		var t_done: bool = not main.errands.hint_open("trial") and "이번 회차" not in jl2 and "최고 기록 1분 35초" in jl2
		check("token_fix2", cave_ok and grotto_ok and t_open and t_done,
			"ring earned in the cave leaves the stairs line fresh=%s, the grotto mark leads to its exit=%s, trial hint + journal open with a kept best and no hill token=%s, done with the token=%s" % [cave_ok, grotto_ok, t_open, t_done])
		main.trial_best = old_best
		main.stairs.door_open = door0
		main.tokens = [false, false, false, false, false, false]
		main.return_to_start()
	if want.call("gate_pond"):
		# v0.1.68 (the owner, 2026-10-29): after the pearl, the lower pond's water clock must be wound before the village east gate opens
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.tokens = [false, false, true, false, false, false]
		main.night_q = 4
		main.lake_q = 4
		main.forest_q = 0
		main.hill_q = 0
		main.castle_q = 0
		main.south_q = 0
		main.garden_q = 0
		main.in_forest = false
		main.in_hill = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_village = true
		var vf: Vector2 = main.village.marks.F
		reset_to(vf + Vector2(-0.3, 0))
		await wait(1.0)
		var held: bool = main.in_village and not main.in_forest and main.forest_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "아랫못" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(vf) > 1.0
		main.close_story()
		var line: String = main.main_road_quest()
		var named: bool = line == "숲으로 가기 전에: 아랫못의 물시계를 되살리자"
		var jl: String = "\n".join(PackedStringArray(main.journal_lines()))
		var jour: bool = "아랫못의 물시계 아직" in plain(jl) and "물빛 진주 끝" in plain(jl)
		# the gold "!" in the lake follows the pond's steps
		main.in_village = false
		main.in_lake = true
		reset_to(main.lake.marks.P)
		main.set_quest(line)
		var spots: Array = [main.lake.marks.Y, main.lake.ropes[0], main.lake.ropes[1], main.lake.marks.K]
		var marks_ok := true
		for q in 4:
			main.south_q = q
			var t: Vector3 = main.quest_marks.line_target(main.quest_raw)
			marks_ok = marks_ok and t != Vector3.INF and Vector2(t.x, t.z).distance_to(spots[q]) < 0.1
		# from the village the mark leads to the south gate
		main.in_lake = false
		main.in_village = true
		reset_to(vf + Vector2(-3, 0))
		var mv: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var from_village: bool = mv != Vector3.INF and Vector2(mv.x, mv.z).distance_to(main.village.marks.K) < 0.1
		# the clockwork wound: the line goes back to the road and the gate opens
		main.south_q = 3
		main.lake_zone.south_key() # not near the spring: nothing
		main.south_q = 4
		main.corridor_q = 6 # and the water corridor (v0.1.84)
		main.moon_tokens.refresh_quest()
		var back: bool = main.quest_raw == "물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"
		reset_to(vf + Vector2(-0.3, 0))
		await wait(1.5)
		var opened: bool = main.in_forest and main.forest_q == 1
		main.close_story()
		# the pond alone does not open it without the pearl, and a save already in the forest is never locked again
		main.tokens[2] = false
		main.forest_q = 0
		var needs_pearl: bool = main.moon_tokens.holds("forest")
		main.forest_q = 1
		var never: bool = not main.moon_tokens.holds("forest")
		main.forest_q = 0
		main.south_q = 0
		check("gate_pond", held and named and jour and marks_ok and from_village and back and opened and needs_pearl and never,
			"east gate held with the pond story=%s, line names the water clock=%s, journal=%s, marks on weir/ropes/spring=%s, from the village=%s, wound: line back=%s opens=%s, pearl still needed=%s, never re-locked=%s" % [held, named, jour, marks_ok, from_village, back, opened, needs_pearl, never])
		main.return_to_start()
	if want.call("gate_valley"):
		# after the second Noeul duel and the five squirrels, the south valley (lamps, cloak, hollow) opens the forest's east end
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.tokens = [false, false, true, true, false, false]
		main.forest.freed = [true, true, true, true, true]
		main.forest_q = 3
		main.hill_q = 0
		main.castle_q = 0
		main.hollow_q = 0
		main.garden_q = 0
		main.in_village = false
		main.in_lake = false
		main.in_hill = false
		main.in_garden = false
		main.in_cave = false
		main.in_forest = true
		var fe: Vector2 = main.forest.marks.E
		reset_to(fe + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.0)
		var held: bool = main.in_forest and not main.in_hill and main.hill_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "골짜기" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(fe) > 1.0
		main.close_story()
		var line: String = main.main_road_quest()
		var named: bool = line == "언덕으로 가기 전에: 숲 남쪽 골짜기의 기억을 되살리자"
		main.set_quest(line)
		reset_to(main.forest.marks.N)
		var marks_ok := true
		for l in main.forest.mem_lamps:
			l.lit = false # earlier tests may have lit them
		main.hollow_q = 0
		var t0: Vector3 = main.quest_marks.line_target(main.quest_raw)
		marks_ok = marks_ok and t0 != Vector3.INF and Vector2(t0.x, t0.z).distance_to(main.forest.marks.G) < 0.1
		main.hollow_q = 1
		var t1: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var lamp_ok := false
		for l in main.forest.mem_lamps:
			if not l.lit and Vector2(t1.x, t1.z).distance_to(l.pos) < 0.1:
				lamp_ok = true
		marks_ok = marks_ok and lamp_ok
		main.hollow_q = 2
		var t2: Vector3 = main.quest_marks.line_target(main.quest_raw)
		marks_ok = marks_ok and t2 != Vector3.INF
		var jl: String = plain("\n".join(PackedStringArray(main.journal_lines())))
		var jour: bool = "남쪽 골짜기의 기억 아직" in jl and "다람쥐 다섯 끝" in jl
		main.hollow_q = 3
		main.moon_tokens.refresh_quest()
		var back: bool = main.quest_raw == "숲 동쪽 끝 길로, 바람 언덕에 가자" or main.quest_raw == main.forest_zone.east_quest()
		reset_to(fe + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.5)
		var opened: bool = main.in_hill and main.hill_q == 1
		main.close_story()
		main.hill_q = 0
		main.hollow_q = 0
		main.tokens[3] = false
		var needs_sq: bool = main.moon_tokens.holds("hill")
		main.tokens[3] = true
		main.hill_q = 1
		var never: bool = not main.moon_tokens.holds("hill")
		main.hill_q = 0
		check("gate_valley", held and named and marks_ok and jour and back and opened and needs_sq and never,
			"east end held with the valley story=%s, line=%s, marks on gate/lamp/door=%s, journal=%s, hollow opened: line back=%s opens=%s, squirrels still needed=%s, never re-locked=%s" % [held, named, marks_ok, jour, back, opened, needs_sq, never])
		main.return_to_start()
	if want.call("gate_castle"):
		# the hill -> castle gate needs BOTH the sparrow mill and the moon trial (v0.1.68; it was either)
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.tokens = [false, false, false, false, false, false]
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.hill_q = 3
		main.castle_q = 0
		main.mill_q = 0
		main.trial_won = false
		var hx: Vector2 = main.hill.marks.X
		reset_to(hx + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.0)
		var held: bool = main.in_hill and not main.in_castle() and main.castle_q == 0 and main.story_open and main.story_lines.size() == 1 \
			and "풍차" in main.story_lines[0] and "시험" in main.story_lines[0]
		main.close_story()
		var both: bool = main.main_road_quest() == "성으로 가기 전에: 참새 방앗간을 되살리고 달빛 시련을 마치자"
		# only the trial done (the old rule opened here)
		main.trial_won = true
		main.moon_tokens.earn(main.moon_tokens.HILL)
		var only_trial: bool = main.moon_tokens.holds("castle") and main.main_road_quest() == "성으로 가기 전에: 참새 방앗간을 되살리자"
		main.set_quest(main.main_road_quest())
		reset_to(main.hill.marks.S + Vector2(2, 0))
		var mt: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var mark_mill: bool = mt != Vector3.INF and Vector2(mt.x, mt.z).distance_to(main.hill.south_marks.G) < 0.1
		reset_to(hx + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.0)
		var held2: bool = main.in_hill and main.castle_q == 0 and main.story_open and "풍차" in main.story_lines[0]
		main.close_story()
		# only the mill done
		main.trial_won = false
		main.mill_q = 5
		var only_mill: bool = main.moon_tokens.holds("castle") and main.main_road_quest() == "성으로 가기 전에: 달빛 시련을 마치자"
		main.set_quest(main.main_road_quest())
		reset_to(main.hill.marks.S + Vector2(2, 0))
		var mt2: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var mark_trial: bool = mt2 != Vector3.INF and Vector2(mt2.x, mt2.z).distance_to(main.hill.marks.R) < 0.1
		var jl: String = plain("\n".join(PackedStringArray(main.journal_lines())))
		var jour: bool = "참새 방앗간 끝" in jl and "달빛 시련 아직" in jl
		# both: the line goes back to the road and the gate opens (with the observatory answered, v0.1.120)
		main.trial_won = true
		main.observatory_q = 6
		main.moon_tokens.refresh_quest()
		var back: bool = main.quest_raw == "언덕 동쪽 끝 길로, 달지기들의 성에 가자"
		reset_to(hx + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.5)
		var opened: bool = main.in_castle() and main.castle_q == 1
		main.close_story()
		# the trial hint and the journal follow this round's clear; a save already in the castle is never locked again
		main.trial_won = false
		main.castle_q = 1
		var never: bool = not main.moon_tokens.holds("castle")
		main.castle_q = 0
		var hint: bool = main.errands.hint_open("trial")
		main.mill_q = 0
		main.trial_won = false
		check("gate_castle", held and both and only_trial and mark_mill and held2 and only_mill and mark_trial and jour and back and opened and never and hint,
			"castle gate held with both needs=%s, line both=%s, trial only holds + line=%s mark on the mill=%s held again=%s, mill only holds + line=%s mark on the trial stone=%s, journal=%s, both: line back=%s opens=%s, never re-locked=%s, trial hint open=%s" % [held, both, only_trial, mark_mill, held2, only_mill, mark_trial, jour, back, opened, never, hint])
		main.return_to_start()
	if want.call("gate_knight"):
		# the throne room's moon door stays shut after the third page until the deep workshop's cradle is let go (v0.1.68)
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.forest_q = 3
		main.lake_q = 4
		main.hill_q = 3
		main.castle_q = 1
		main.garden_q = 0
		main.work_q = 0
		main.work_door = false
		main.has_unbrick = true
		main.castle.open_gate()
		main.castle.door_open = false
		main.castle.door.visible = true
		for pg in main.castle.pages:
			pg.read = false
		main.castle.pages[0].read = true
		main.castle.pages[1].read = true
		var cx: float = main.CASTLE.CASTLE_X
		calm_enemies(true)
		# the workshop's door opens before the knight (the loosened start condition)
		var ready: bool = main.workshop_zone.door_ready()
		main.castle_q = 0
		var not_before_castle: bool = not main.workshop_zone.door_ready()
		main.castle_q = 1
		# the third page
		reset_to(main.castle.pages[2].pos + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		await wait(0.2)
		var gate_story: bool = main.story_open and main.story_lines.size() >= 1 and "수리 요람" in main.story_lines[main.story_lines.size() - 1]
		main.close_story()
		var shut: bool = main.castle.pages_read() == 3 and not main.castle.door_open and not main.player_can(cx + 31, 13)
		var named: bool = main.quest_raw == "옥좌의 방으로 가기 전에: 작업장 깊은 곳의 수리 요람을 풀자"
		reset_to(main.castle.marks.S + Vector2(3, 0))
		var mk: Vector3 = main.quest_marks.quest_target()
		var mark_door: bool = mk != Vector3.INF and Vector2(mk.x, mk.z).distance_to(main.WORK_DOOR) < 0.1
		var jl: String = plain("\n".join(PackedStringArray(main.journal_lines())))
		var jour: bool = "작업장의 수리 요람 아직" in jl
		main.save_game() # a held door is saved shut, so a load keeps it shut
		var held_save = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var new_shut: bool = held_save.get("moon_door", true) == false and main.moon_tokens.holds("knight")
		# inside the workshop the mark follows the floor's devices
		main.work_door = true
		for l in main.wfloors[0].lamps:
			l.lit = false # earlier tests may have lit them
		main.wfloors[0].groups[0].open = false
		main.workshop_zone.enter_floor(0, "A")
		main.set_quest(main.moon_tokens.knight_need_line())
		await wait(0.3)
		main.close_story()
		var wk: Vector3 = main.quest_marks.quest_target()
		var mark_work: bool = main.in_workshop() and wk != Vector3.INF
		main.workshop_zone.leave_up(0)
		await wait(0.2)
		# the cradle let go: the door gives when she is back in the castle
		main.work_q = 5
		main.moon_tokens.refresh_quest()
		reset_to(main.castle.pages[2].pos)
		for k in 3: # the door's first look after the leave-up may be open: close it, the door gives after
			main.close_story()
			await wait(0.3)
		var opened: bool = main.castle.door_open and main.player_can(cx + 31, 13)
		var back: bool = main.quest_raw == "옥좌의 방으로 가자"
		# old saves: pages all read with no "moon_door" key are past the gate; a new save that says shut stays shut
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		sd["castle_pages"] = [true, true, true]
		sd["work_q"] = 0
		sd["castle_q"] = 1
		sd.erase("moon_door")
		var f := FileAccess.open(main.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(sd))
		f.close()
		main.load_game()
		var old_open: bool = main.castle.door_open and not main.moon_tokens.holds("knight")
		main.castle_q = 2
		var never: bool = not main.moon_tokens.holds("knight")
		check("gate_knight", ready and not_before_castle and gate_story and shut and named and mark_door and jour and mark_work and opened and back and old_open and new_shut and never,
			"workshop door ready before the knight=%s (not before the castle=%s), third page: gate story=%s door shut=%s line=%s mark on the workshop door=%s journal=%s mark inside=%s, cradle let go: door opens=%s line back=%s, old save open=%s, new save shut=%s, fight begun never locks=%s" % [ready, not_before_castle, gate_story, shut, named, mark_door, jour, mark_work, opened, back, old_open, new_shut, never])
		main.castle.door_open = false
		main.return_to_start()
	if want.call("gate_quarters"):
		# after the knight, the quarters (tin doorkeeper walked to his bunk) must be done before the castle's east gate opens the moon stairs
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.forest_q = 3
		main.hill_q = 3
		main.castle_q = 3
		main.garden_q = 0
		main.quarters_q = 0
		main.stairs_seen = false
		var stairs_door0: bool = main.stairs.door_open
		main.stairs.door_open = false # earlier tests may have opened it
		main.castle.open_gate()
		calm_enemies(true)
		var ce: Vector2 = main.castle.marks.E
		reset_to(ce + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.0)
		var held: bool = main.in_castle() and not main.in_stairs() and main.story_open and main.story_lines.size() == 1 \
			and "깡통" in main.story_lines[0] and Vector2(main.player.x, main.player.z).distance_to(ce) > 1.0
		main.close_story()
		var named: bool = main.quest_raw == "달의 계단을 오르기 전에: 숙소의 깡통 문지기를 침방까지 모시자"
		var jl: String = plain("\n".join(PackedStringArray(main.journal_lines())))
		var jour: bool = "숙소의 깡통 문지기 아직" in jl
		var marks_ok := true
		main.quarters_q = 0
		var t0: Vector3 = main.quest_marks.quest_target()
		marks_ok = marks_ok and t0 != Vector3.INF and Vector2(t0.x, t0.z).distance_to(main.castle.marks.K) < 0.1
		main.quarters_q = 1
		var t1: Vector3 = main.quest_marks.quest_target()
		marks_ok = marks_ok and t1 != Vector3.INF and Vector2(t1.x, t1.z).distance_to(main.castle.marks.Q) < 0.1
		main.quarters_q = 2
		var t2: Vector3 = main.quest_marks.quest_target()
		marks_ok = marks_ok and t2 != Vector3.INF
		# the resume states are untouched: quarters_q 3 is still the walk, 4 the ledger
		var resume: bool = main.moon_tokens.holds("stairs") and not main.moon_tokens.quarters_done()
		main.quarters_q = 5
		main.moon_tokens.refresh_quest()
		var back: bool = main.quest_raw == "동쪽 문을 지나 정원 한가운데로 가자"
		reset_to(ce + Vector2(-0.3, 0))
		main.player.inv = 99.0
		await wait(1.5)
		var opened: bool = main.in_stairs()
		main.close_story()
		# once the stairs were entered, or the garden reached, the gate never shuts again (a new round resets stairs_seen)
		main.quarters_q = 0
		var seen: bool = main.stairs_seen and not main.moon_tokens.holds("stairs")
		main.stairs_seen = false
		main.garden_q = 1
		var past: bool = not main.moon_tokens.holds("stairs")
		main.garden_q = 0
		var shut0: bool = main.moon_tokens.holds("stairs")
		check("gate_quarters", held and named and jour and marks_ok and resume and back and opened and seen and past and shut0,
			"east gate held with the quarters story=%s, line=%s, journal=%s, marks on spring/door/doll=%s, partial quarters still hold=%s, done: line back=%s opens=%s, entered stairs never relocks=%s, garden reached=%s, none holds=%s" % [held, named, jour, marks_ok, resume, back, opened, seen, past, shut0])
		main.stairs_seen = false
		main.stairs.door_open = stairs_door0
		main.return_to_start()
	if want.call("gate_new_round"):
		# a new round resets the deeds the gates ask for, so every gate holds again (v0.1.68)
		main.return_to_start()
		main.south_q = 5
		main.hollow_q = 4
		main.mill_q = 5
		main.trial_won = true
		main.work_q = 6
		main.quarters_q = 5
		main.trial_best = 80.0
		main.write_new_round()
		main.castle.door_open = false # the castle node outlives a load in this process; a real new round builds it again
		for pg in main.castle.pages:
			pg.read = false
		var nd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var keys_gone := true
		for k in ["south_q", "hollow_q", "mill_q", "work_q", "quarters_q"]:
			keys_gone = keys_gone and int(nd.get(k, 0)) == 0 and not main.errands.NG_KEEP.has(k)
		var file_ok: bool = keys_gone and nd.get("trial_won", true) == false and float(nd.get("trial_best", 0.0)) == 80.0
		main.load_game()
		var all_hold: bool = main.moon_tokens.holds("forest") and main.moon_tokens.holds("hill") and main.moon_tokens.holds("castle") and main.moon_tokens.holds("knight")
		var hold_txt := "%s %s %s %s (castle_q %d, door %s, work_q %d)" % [main.moon_tokens.holds("forest"), main.moon_tokens.holds("hill"), main.moon_tokens.holds("castle"), main.moon_tokens.holds("knight"), main.castle_q, main.castle.door_open, main.work_q]
		var trial_again: bool = not main.trial_won and main.trial_best == 80.0 and main.errands.hint_open("trial") == (main.hill_q >= 3)
		check("gate_new_round", file_ok and all_hold and trial_again,
			"new-round file drops the pond, valley, mill, trial, workshop and quarters flags and keeps the best time=%s, the gates hold again=%s (%s), trial must be cleared again=%s" % [file_ok, all_hold, hold_txt, trial_again])
		main.ng = 0
		main.trial_best = 0.0
	if want.call("gate_fix4"):
		# GPT lap 4 on the v0.1.68 gates: the doorkeeper's walk is saved, exits are marked in the separate areas, the pond yard fight
		# is marked, the workshop journal opens early, the third diary page only says the door opens when it does
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.forest_q = 3
		main.lake_q = 4
		main.hill_q = 3
		main.castle_q = 1
		main.garden_q = 0
		main.work_q = 0
		main.work_seen = false
		main.work_door = false
		main.has_unbrick = true
		main.castle.open_gate()
		main.castle.door_open = false
		main.castle.door.visible = true
		for pg in main.castle.pages:
			pg.read = false
		main.castle.pages[0].read = true
		main.castle.pages[1].read = true
		calm_enemies(true)
		# 6. the third page while the cradle holds the door: no "opens" line; once the cradle is let go it does open
		reset_to(main.castle.pages[2].pos + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		var shut_txt := plain(" ".join(PackedStringArray(main.story_lines.map(func(l): return str(l)))))
		var page_shut: bool = main.story_open and "닫힌 채" in shut_txt and not "열렸다" in shut_txt and not main.castle.door_open
		main.close_story()
		await wait(0.2)
		main.close_story()
		# 3. the journal shows the workshop lines: the gate held
		var jl: String = plain("\n".join(PackedStringArray(main.journal_lines())))
		var jour_held: bool = "끝내지 못한 등불" in jl
		main.castle.pages[2].read = false # two pages read, the door not found yet: nothing
		var hide: bool = not main.workshop_zone.journal_shown()
		main.work_seen = true # found
		var jour_seen: bool = main.workshop_zone.journal_shown()
		main.work_seen = false
		main.castle_q = 0
		var never_early: bool = not main.workshop_zone.journal_shown()
		main.castle_q = 1
		main.work_q = 5
		main.castle.door_open = false
		reset_to(main.castle.pages[2].pos + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.2)
		var open_txt := plain(" ".join(PackedStringArray(main.story_lines.map(func(l): return str(l)))))
		var page_open: bool = "열렸다" in open_txt and main.castle.door_open
		main.close_story()
		await wait(0.2)
		main.close_story()
		# 2. after the cradle, every workshop floor marks its way up and out
		main.work_door = true
		main.set_quest("옥좌의 방으로 가자")
		var exits_ok := true
		for i in 3:
			main.workshop_zone.enter_floor(i, "A")
			main.work_q = 5
			main.close_story()
			var wt: Vector3 = main.quest_marks.quest_target()
			exits_ok = exits_ok and main.in_workshop() and wt != Vector3.INF and Vector2(wt.x, wt.z).distance_to(main.workshop_zone.fl(i).marks.S) < 0.1
		main.workshop_zone.leave_up(0)
		await wait(0.2)
		main.close_story()
		# 7. the cloud mound: a line for the hill marks the cloud's exit
		main.enter_cloud()
		main.close_story()
		main.set_quest("성으로 가기 전에: 참새 방앗간을 되살리자")
		var ct: Vector3 = main.quest_marks.quest_target()
		var cloud_exit: bool = main.in_cloud() and ct != Vector3.INF and Vector2(ct.x, ct.z).distance_to(main.cloud.marks.S) < 0.1
		main.enter_hill()
		main.close_story()
		# 4. the lower pond's second chain: shut in the yard the mark is the yard fight, then the water clock's key
		main.in_hill = false
		main.in_lake = true
		main.tokens[2] = true
		main.south_q = 2
		main.south_ambush_on = true
		main.set_quest("숲으로 가기 전에: 아랫못의 물시계를 되살리자")
		reset_to(Vector2(300.0, 31.0))
		var yt: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var yard_ok: bool = main.lake_zone.in_south_yard(Vector2(300.0, 31.0)) and yt != Vector3.INF and Vector2(yt.x, yt.z).distance_to(main.lake.marks.l) < 0.1
		main.south_ambush_on = false
		reset_to(main.lake.marks.P)
		var pt: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var out_ok: bool = pt != Vector3.INF and Vector2(pt.x, pt.z).distance_to(main.lake.ropes[1]) < 0.1
		main.south_q = 3
		var kt: Vector3 = main.quest_marks.line_target(main.quest_raw)
		var key_ok: bool = kt != Vector3.INF and Vector2(kt.x, kt.z).distance_to(main.lake.marks.K) < 0.1
		main.south_q = 0
		main.in_lake = false
		main.in_hill = true
		# 5. + 1. the doorkeeper: the mark follows him walking, waiting or stopped; a save mid-escort resumes from where he stood
		main.castle_q = 3
		main.quarters_q = 3
		main.castle.open_gate()
		reset_to(main.castle.marks.S + Vector2(3, 0))
		main.close_story()
		main.doll_at = Vector2(458.0, 31.0)
		main.doll_i = 6
		main.doll_shed = true
		var follow := true
		for st in [[true, false], [true, true], [false, false]]:
			main.doll_walk = st[0]
			main.doll_wait = st[1]
			var dq: Vector3 = main.quest_marks.line_target("달의 계단을 오르기 전에: 숙소의 깡통 문지기를 침방까지 모시자")
			var dst: Vector3 = main.castle_zone.quarters_target()
			follow = follow and dq != Vector3.INF and Vector2(dq.x, dq.z).distance_to(main.doll_at) < 0.1 and dst != Vector3.INF
		main.save_game()
		var sv = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		main.doll_at = main.CASTLE.DOLL_PATH[0]
		main.doll_i = 1
		main.doll_shed = false
		main.load_quarters(sv)
		await wait(0.1)
		var resumed: bool = main.quarters_q == 3 and main.doll_at == Vector2(458.0, 31.0) and main.doll_i == 6 and not main.doll_walk \
			and absf(main.castle.doll.position.x - 458.0) < 0.01 and main.doll_keep_shed
		main.castle_zone.doll_resume()
		var walks_on: bool = main.doll_walk and main.doll_shed and main.doll_at == Vector2(458.0, 31.0)
		sv.erase("doll_at") # an older save: back at the stand
		main.load_quarters(sv)
		var old_ok: bool = main.doll_at == main.CASTLE.DOLL_PATH[0] and main.doll_i == 1 and not main.doll_keep_shed
		main.castle_zone.doll_resume()
		var reraid: bool = not main.doll_shed
		main.quarters_q = 0
		main.load_quarters({})
		main.castle.door_open = false
		check("gate_fix4", page_shut and jour_held and hide and jour_seen and never_early and page_open and exits_ok and cloud_exit and yard_ok and out_ok and key_ok and follow and resumed and walks_on and old_ok and reraid,
			"third page while held: no door-opens line=%s, once done it opens=%s; workshop journal held=%s hidden early=%s found=%s not before the castle=%s; every workshop floor marks its exit=%s; cloud exit=%s; pond yard fight=%s, outside post=%s, key after the latch=%s; doorkeeper marked walking, waiting, stopped=%s; save mid-escort resumes=%s keeps the raid=%s, old save at the stand=%s raids again=%s" % [page_shut, page_open, jour_held, hide, jour_seen, never_early, exits_ok, cloud_exit, yard_ok, out_ok, key_ok, follow, resumed, walks_on, old_ok, reraid])
		main.return_to_start()
	if want.call("gate_fix5"):
		# GPT lap 5: the work lamps are marked in the deep workshop on the diary's line, the key chest moves the cave line to the door,
		# the marsh steps back to a villager are marked at the village entrance, a beaten raid survives a restart before E resumes
		main.return_to_start()
		if main.intro:
			main.start_game(false)
		await wait(0.2)
		main.close_story()
		main.story_step = maxi(main.story_step, 11)
		calm_enemies(true)
		# 8. in the workshop early by the diary's discovery line: next_spot, not the exit
		main.in_village = false
		main.in_forest = false
		main.in_lake = false
		main.in_garden = false
		main.in_cave = false
		main.in_hill = true
		main.castle_q = 1
		main.work_q = 0
		main.castle.door_open = false
		main.set_quest("성 일기를 더 찾아 읽자")
		main.workshop_zone.enter_floor(0, "A")
		main.close_story()
		var w8: Vector3 = main.quest_marks.quest_target()
		var w8n: Vector3 = main.workshop_zone.next_spot()
		var lamps_ok: bool = main.in_workshop() and w8 != Vector3.INF and w8n != Vector3.INF and Vector2(w8.x, w8.z).distance_to(Vector2(w8n.x, w8n.z)) < 0.1 			and Vector2(w8.x, w8.z).distance_to(main.workshop_zone.fl(0).marks.S) > 0.5
		main.workshop_zone.leave_up(0)
		await wait(0.2)
		main.close_story()
		# 9. the painting first, then the key chest: the line moves on to the door and still has a mark
		main.in_hill = false
		main.saw_painting = true
		main.has_key = false
		main.has_skip = false
		main.cave_door_open = false
		main.enter_cave()
		main.close_story()
		main.set_quest("열쇠를 찾아 잠긴 문을 열자")
		reset_to(main.cave_marks.K)
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		var key_line: bool = main.has_key and main.quest_raw.begins_with("얻은 열쇠로")
		var ct9: Vector3 = main.quest_marks.quest_target()
		var door_mark: bool = ct9 != Vector3.INF and Vector2(ct9.x, ct9.z).distance_to(main.cave_marks.D) < 0.1
		main.leave_cave()
		main.close_story()
		main.has_key = false
		# 10. the marsh: the letter delivered, the oar fetched: the village entrance
		var mt: Array = []
		for ql in ["마을의 뱃사공 물결에게 가 보자 (E)", "노를 마을의 물결에게 가져가자 (E)"]:
			main.set_quest(ql)
			var t10: Vector3 = main.quest_marks.quest_target()
			mt.append(t10 != Vector3.INF and Vector2(t10.x, t10.z).distance_to(main.quest_marks.VILLAGE_WAY) < 0.1)
		var marsh_ok: bool = mt[0] and mt[1]
		# 11. a beaten raid not yet resumed is saved again as beaten
		main.in_hill = true
		main.quarters_q = 3
		main.doll_shed = false
		main.doll_keep_shed = true
		main.save_game()
		var sv11 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = bool(sv11.get("doll_raid", false))
		main.doll_keep_shed = false
		main.doll_shed = true
		main.save_game()
		var sv12 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var raid_open: bool = bool(sv12.get("doll_raid", false)) == main.doll_bits().is_empty()
		main.doll_shed = false
		main.save_game()
		var sv13 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var fresh: bool = not bool(sv13.get("doll_raid", false))
		main.quarters_q = 0
		main.load_quarters({})
		main.in_hill = false
		check("gate_fix5", lamps_ok and key_line and door_mark and marsh_ok and kept and raid_open and fresh,
			"early in the workshop marks the work lamps=%s; key chest after the painting: line to the door=%s, mark on the door=%s; marsh steps back to a villager marked at the village entrance=%s; beaten raid kept across the entry autosave=%s, shed-and-beaten saved=%s, not shed not saved=%s" % [lamps_ok, key_line, door_mark, marsh_ok, kept, raid_open, fresh])
		main.return_to_start()
	# ---- 물길 회랑 (v0.1.84, the owner's "1안" 2026-10-29): the lake island's stair, four rooms, the keeper, the answer stand
	if want.call("corridor_enter"):
		calm_enemies(true)
		corr_world()
		main.tokens[2] = false
		main.south_q = 4
		main.corridor_q = 0
		main.forest_q = 0
		reset_to(main.lake.marks.V + Vector2(0, 0.3))
		main.toast_t = 0.0
		await wait(0.7)
		var no_pearl: bool = not main.in_corridor() and main.corridor_q == 0
		main.tokens[2] = true
		main.south_q = 3
		reset_to(main.lake.marks.V + Vector2(0, 0.3))
		main.toast_t = 0.0
		await wait(0.7)
		var no_pond: bool = not main.in_corridor() and main.corridor_q == 0
		main.south_q = 4
		reset_to(main.lake.marks.V + Vector2(0, 0.3))
		await wait(1.5)
		var inside: bool = main.in_corridor() and main.corridor_q == 1 and main.story_open and not main.in_grotto() and main.in_lake and not main.in_lake_main()
		main.close_story()
		var at_s: bool = main.corridor.room_of(main.player.x) == 0 and Vector2(main.player.x, main.player.z).distance_to(main.corridor.at(0, "S") + Vector2(1, 0)) < 0.6
		var zone: bool = main.ui.zone_name.text == "물길 회랑"
		# eight maps in four rooms: 30 x 22, a wall all round, origins 740/780/820/860, no other area's test fits there, and S reaches D reaches N or C
		var dims := true
		var reach := true
		for r in 4:
			var g: Array = main.corridor.grids[r]
			dims = dims and g.size() == 22 and g.all(func(row): return row.length() == 30 and row[0] == "#" and row[29] == "#") and g[0] == "#".repeat(30) and g[21] == "#".repeat(30)
			dims = dims and main.corridor.origin(r) == 740 + 40 * r
			var goal: String = "N" if r < 3 else "C"
			reach = reach and main.corridor.at(r, "S") != Vector2.INF and main.corridor.at(r, goal) != Vector2.INF
			if r < 3:
				var d: Vector2 = main.corridor.at(r, "D")
				reach = reach and d != Vector2.INF and main.corridor.at(r, "S").x < d.x and d.x < main.corridor.at(r, "N").x and d.y == main.corridor.at(r, "S").y
				for z in 22:
					if z != int(d.y):
						reach = reach and main.corridor.grids[r][z][20] == "#" # the wall of D is solid but for D
		var apart: bool = not main.in_castle() and not main.in_workshop() and not main.in_cloud() and not main.in_stairs() and not main.in_under()
		var wall_water: bool = main.tile_at(740.0, 0.0) == main.WATER and main.tile_at(main.corridor.at(0, "S").x + 1.0, 10.0) == main.GRASS
		# the grotto's test does not catch the corridor, nor the corridor the grotto
		var keep_x: float = main.player.x
		main.player.x = main.GROTTO.GROTTO_X + 3.0
		var grotto_ok: bool = main.in_grotto() and not main.in_corridor()
		main.player.x = keep_x
		# the stair out: back on the island by V
		reset_to(main.corridor.at(0, "S") + Vector2(0.3, 0))
		await wait(1.5)
		var out: bool = not main.in_corridor() and main.in_lake_main() and Vector2(main.player.x, main.player.z).distance_to(main.lake.marks.V) < 2.0
		check("corridor_enter", no_pearl and no_pond and inside and at_s and zone and dims and reach and apart and wall_water and grotto_ok and out,
			"V shut without the pearl=%s or the pond=%s; entered q1 with the talk=%s beside S=%s, zone=%s; maps 30x22 walled, origins, S to D to N/C=%s/%s, no clash=%s, wall=%s, grotto apart=%s, stair out=%s" % [no_pearl, no_pond, inside, at_s, zone, dims, reach, apart, wall_water, grotto_ok, out])
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6

	if want.call("corridor_s1"):
		# room 1: the plate, Mulgyeol's post, the lever (a refusal in the channel), the water skip, the latch, the gate, the next room
		calm_enemies(true)
		await corr_prep(1, 0)
		corr_kill(corr_foes())
		var C = main.corridor
		var Z = main.corridor_zone
		var o: int = C.origin(0)
		var D: Vector2 = C.at(0, "D")
		var shut: bool = not main.walkable(D.x, D.y) and main.tile_at(D.x, D.y) == main.WATER
		await corr_press("H", 0)
		var read: bool = main.corr_sec[0].record_read and main.story_open
		main.close_story()
		await corr_press("F", 0, 0, Vector2(-0.8, 0))
		var early_no: bool = not main.corr_sec[0].latch_fixed and main.corridor_q == 1
		await corr_press("A", 0)
		await wait(2.3)
		var high: bool = C.high[0] and main.corr_sec[0].water_high and main.tile_at(o + 9.0, 10.0) == main.WATER and main.skip_water(o + 9.0, 10.0)
		# the water skip crosses the deep channel, walking does not
		reset_to(Vector2(o + 6.6, 5.0))
		hold_world(Vector2(1, 0))
		await wait(1.0)
		release()
		var walk_stops: bool = main.player.x < o + 8.0
		reset_to(Vector2(o + 6.6, 5.0))
		main.player.sp = 100.0
		hold_world(Vector2(1, 0))
		main.fake_keys[KEY_SHIFT] = true
		await wait(1.2)
		release()
		var skipped: bool = main.player.x > o + 11.0
		main.player.vx = 0.0
		main.player.vz = 0.0
		await corr_press("A", 0)
		await wait(2.3)
		var low: bool = not C.high[0] and main.corr_sec[0].water_high == false and main.tile_at(o + 9.0, 10.0) != main.WATER
		# the lever starts and Sora steps into the channel before the level moves: it stops, she is never walled in
		await corr_press("A", 0)
		reset_to(Vector2(o + 9.0, 10.0))
		await wait(1.4)
		var refused: bool = not C.high[0] and Z.trans.is_empty() and main.tile_at(o + 9.0, 10.0) != main.WATER
		await wait(1.2)
		# Mulgyeol takes the post
		await corr_press("P", 0)
		await wait(1.6)
		var posted: bool = Z.post_room == 0 and not main.mate_job.is_empty() and Vector2(main.mate.position.x, main.mate.position.z).distance_to(C.at(0, "P")) < 0.4
		await corr_press("F", 0, 0, Vector2(-0.8, 0))
		var low_no: bool = not main.corr_sec[0].latch_fixed
		await corr_press("A", 0)
		await wait(2.3)
		await corr_press("F", 0, 0, Vector2(-0.8, 0))
		await wait(0.3)
		var fixed: bool = main.corr_sec[0].latch_fixed and main.corridor_q == 2 and C.gate_open[0] and main.walkable(D.x, D.y) and Z.post_room == -1 and main.mate_job.is_empty()
		await wait(2.3)
		var settled: bool = not C.high[0] and not main.corr_sec[0].water_high
		# the door N leads on
		reset_to(C.at(0, "N") + Vector2(-0.5, 0))
		await wait(1.5)
		var onward: bool = main.corridor.room_of(main.player.x) == 1 and main.ui.zone_sub.text == "회랑 · 되돌리는 물"
		check("corridor_s1", shut and read and early_no and high and walk_stops and skipped and low and refused and posted and low_no and fixed and settled and onward,
			"D shut=%s; plate read=%s; latch refused early=%s; lever raises=%s; walking stops=%s, skip crosses=%s; lowers=%s; stepping in cancels=%s; post=%s; latch needs high water=%s; fixed, gate open, post freed=%s; water settles=%s; next room=%s" % [shut, read, early_no, high, walk_stops, skipped, low, refused, posted, low_no, fixed, settled, onward])
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6

	if want.call("corridor_s2"):
		# room 2: a bucket's lane and spray, the far-bank bricks, the drain, the lever that fixes the channel
		calm_enemies(true)
		await corr_prep(2, 1)
		hold_mates()
		var C = main.corridor
		var Z = main.corridor_zone
		var o: int = C.origin(1)
		var bs: Array = main.enemies.filter(func(e): return not e.dead and e.get("bucket", false))
		var two: bool = bs.size() == 2 and Z.foes_alive(1)
		var b: Dictionary = bs[0]
		var lv: int = main.foe_lv()
		var stats: bool = b.max_hp == 40 + lv * 13
		bs[1].dead = true
		bs[1].node.queue_free()
		bs[1].shadow.queue_free()
		# the lane: warned 0.9 s, hits the lane only; then the head bows 1.8 s with the seams open
		var seen_tele := false
		var bowed := false
		var hurt_early := false
		var in_hit := false
		var out_hit := false
		for trial in 2:
			b.x = o + 12.0
			b.z = 6.0
			b.atk_cd = 0.0
			b.tele_t = 0.0
			b.bow = 0.0
			b.seam = 0.0
			b.spray_t = 0.0
			var stand := Vector2(b.x + 2.5, b.z)
			reset_to(stand)
			main.player.inv = 0.0
			var hp0: float = main.player.hp
			var t := 0.0
			var moved := false
			while t < 2.0:
				hold_mates()
				main.player.x = stand.x
				main.player.z = stand.y
				if b.tele_t > 0.0:
					seen_tele = true
					hurt_early = hurt_early or main.player.hp < hp0 - 0.01
					if trial == 1 and not moved: # the lane is locked: step beside it
						moved = true
						var f: Vector2 = b.face
						stand = Vector2(b.x, b.z) + f * 2.0 + Vector2(-f.y, f.x) * 1.8
				if b.seam > 0.0 and b.bow > 0.0:
					bowed = true
				await wait(0.05)
				t += 0.05
			if trial == 0:
				in_hit = main.player.hp < hp0 - 0.01
			else:
				out_hit = main.player.hp < hp0 - 0.01
		var lane_ok: bool = seen_tele and bowed and in_hit and not out_hit and not hurt_early
		corr_kill([b])
		await wait(0.1)
		# the far-bank work: raise, (foes dead already here), F drains
		main.corr_sec[1].water_high = false
		await corr_press("A", 1)
		await wait(2.3)
		var raised: bool = C.high[1]
		await corr_press("F", 1, 0, Vector2(-0.8, 0))
		await wait(0.3)
		var drained: bool = main.corr_sec[1].drained and main.corridor_q == 2
		await wait(2.3)
		var low: bool = not C.high[1] and not main.corr_sec[1].water_high
		var a_not_yet: bool = not C.gate_open[1]
		await corr_press("A", 1)
		await wait(0.3)
		var fixed: bool = main.corr_sec[1].latch_fixed and main.corridor_q == 3 and C.gate_open[1]
		# live bricks hold F
		Z.spawned[1] = false
		main.corridor_q = 2
		main.corr_sec[1] = {"water_high": true, "drained": false, "latch_fixed": false}
		C.set_gate(1, false)
		C.set_water(1, true)
		Z.enter_room(1, false)
		await corr_press("F", 1, 0, Vector2(-0.8, 0))
		var held: bool = not main.corr_sec[1].drained and Z.foes_alive(1)
		check("corridor_s2", two and stats and lane_ok and raised and drained and low and a_not_yet and fixed and held,
			"two buckets=%s, hp 40+13/lv=%s; lane warned then hit once and only in the lane, then bowed=%s (tele %s bow %s in %s out %s early %s); raised=%s drains=%s settles=%s fixes q3=%s; live bricks hold the drain=%s" % [two, stats, lane_ok, seen_tele, bowed, in_hit, out_hit, hurt_early, raised, drained, low, fixed, held])
		corr_kill(corr_foes())
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6

	if want.call("corridor_s3"):
		# room 3: the post, the lever, the cart (no blows aboard, 2 tiles a second), the mooring, the wheel, Mulgyeol back
		calm_enemies(true)
		await corr_prep(3, 2)
		var C = main.corridor
		var Z = main.corridor_zone
		var o: int = C.origin(2)
		await corr_press("T", 2, 0, Vector2(-0.4, 0))
		var no_ride: bool = Z.ride.is_empty() and not Z.arrived
		await corr_press("P", 2)
		await wait(1.5)
		await corr_press("T", 2, 0, Vector2(-0.4, 0))
		var low_stops: bool = Z.ride.is_empty() # the water is low: the cart waits
		await corr_press("A", 2)
		await wait(2.3)
		await corr_press("T", 2, 0, Vector2(-0.4, 0))
		var riding: bool = not Z.ride.is_empty()
		var west_start: bool = C.at(2, "T").x < o + 8.0 and C.at(2, "R").x > o + 11.0 # the cart really crosses the channel (v0.1.91)
		var t0 := gsec()
		await wait(0.5)
		var no_blows: bool = main.player.atk_cd >= 0.25
		await wait_for(func(): return Z.arrived, 5.0)
		var secs: float = gsec() - t0
		var rr: Vector2 = C.at(2, "R")
		var on_r: bool = Z.arrived and Vector2(main.player.x, main.player.z).distance_to(rr) < 0.3
		var pace: bool = secs > 4.2 and secs < 6.2 # 10 tiles at 2 a second
		var cart_at_r: bool = absf(C.carts[2].position.x - rr.x) < 0.3
		await corr_press("F", 2, 0, Vector2(-0.8, -0.5))
		var moor_first: bool = not main.corr_sec[2].latch_fixed # the wheel waits for the mooring
		await corr_press("R", 2, 0, Vector2(-0.5, 0))
		var docked: bool = main.corr_sec[2].docked and Z.post_room == -1 and main.mate_job.is_empty()
		await corr_press("F", 2, 0, Vector2(-0.8, -0.5))
		await wait(0.3)
		var done: bool = main.corr_sec[2].latch_fixed and main.corridor_q == 4 and C.gate_open[2] and main.story_open
		main.close_story()
		check("corridor_s3", no_ride and low_stops and riding and west_start and cart_at_r and no_blows and on_r and pace and moor_first and docked and done,
			"cart needs post and high water=%s/%s; rides=%s, no blows=%s, reaches R=%s in %.1f s (%s); wheel waits for the mooring=%s; moored, post freed=%s; wheel fixed, q4, gate open, talk=%s" % [no_ride, low_stops, riding, no_blows, on_r, secs, pace, moor_first, docked, done])
		corr_kill(corr_foes())
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6

	if want.call("corridor_core"):
		# the wheel hall: plate, sluice, Mulgyeol across the tank, three wheels west to east each with a group of three, then the talk and the keeper
		calm_enemies(true)
		await corr_prep(4, 3)
		var C = main.corridor
		var Z = main.corridor_zone
		await corr_press("F", 3, 0, Vector2(0.0, 1.0))
		var none0: bool = Z.group_active < 0 and main.corr_bits == 0 and corr_foes().is_empty()
		await corr_press("H", 3)
		var read: bool = main.corr_sec[3].record_read and main.story_open
		main.close_story()
		await corr_press("A", 3)
		var held: bool = main.corr_sec[3].water_high
		await corr_press("F", 3, 0, Vector2(0.0, 1.0))
		var none1: bool = Z.group_active < 0 and corr_foes().is_empty() # Mulgyeol has not crossed yet
		await corr_press("P", 3)
		var started: bool = main.mate_job.get("kind", "") == "corr_cart"
		var t0 := gsec()
		await wait_for(func(): return main.corr_sec[3].latch_fixed, 9.0)
		var secs: float = gsec() - t0
		var crossed: bool = main.corr_sec[3].latch_fixed and secs < 8.5 and Vector2(main.mate.position.x, main.mate.position.z).distance_to(C.at(3, "R")) < 0.8
		await corr_press("F", 3, 1, Vector2(0.0, 1.0))
		var order: bool = Z.group_active < 0 and corr_foes().is_empty() and main.corr_bits == 0
		var gold0: int = main.player.gold
		var groups := true
		var why := ""
		for i in 3:
			await corr_press("F", 3, i, Vector2(0.0, 1.0))
			var fs: Array = corr_foes().filter(func(e): return e.get("corr_prep", false))
			var shape: bool = fs.size() == 3 and fs.filter(func(e): return e.archer).size() == 1 and Z.group_active == i
			await corr_press("F", 3, i, Vector2(0.0, 1.0)) # again while it fights: refused
			var still: bool = corr_foes().size() == 3
			var g1: int = main.player.gold
			corr_kill(fs)
			await wait(0.5)
			var paid: bool = main.player.gold == g1 + 20 and main.corr_bits == [1, 3, 7][i] and Z.group_active < 0
			groups = groups and shape and still and paid
			why += "[%d n=%d arch=%d act=%d shape %s still %s paid %s] " % [i, fs.size(), fs.filter(func(e): return e.archer).size(), Z.group_active, shape, still, paid]
		main.player.hp = float(main.player.max_hp)
		# near the keeper: the talk, then the keeper stands (2000 hp), Mulgyeol on his post
		reset_to(C.at(3, "B") + Vector2(-7.0, 0))
		await wait(0.5)
		var talk: bool = main.story_open and main.corr_told
		main.close_story()
		await wait(0.3)
		var gk = Z.gate_alive()
		var stands: bool = gk != null and gk.max_hp == 2000 and Z.post_room == 3
		check("corridor_core", none0 and read and held and none1 and started and crossed and order and groups and talk and stands,
			"no group early=%s/%s; plate=%s; sluice held=%s; Mulgyeol crosses in %.1f s=%s; east wheel first refused=%s; groups of 3 (one archer), pay 20 once, bits 001/011/111=%s %s; talk=%s; keeper 2000 hp, post kept=%s" % [none0, none1, read, held, secs, crossed, order, groups, why, talk, stands])
		Z.clear_fight()
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6

	if want.call("corridor_boss"):
		# the sluice-keeper: lane warned 1.2 s then one blow, the ring below 60 %, half damage unless the axis lies open, the side door,
		# faint resets it, one reward
		calm_enemies(true)
		await corr_prep(4, 3)
		main.corr_bits = 7
		main.corr_told = true
		main.corr_sec[3] = {"record_read": true, "water_high": true, "latch_fixed": true, "sent": false}
		main.corridor_zone.apply_state()
		var C = main.corridor
		var Z = main.corridor_zone
		var B: Vector2 = C.at(3, "B")
		Z.spawn_gate()
		var e: Dictionary = Z.gate_alive()
		var lone: bool = e != null and e.hp == 2000.0
		main.join_mate()
		# a lane aimed from the east: stand in it, then stand out of it
		var lane_hits := 0
		var warned := false
		for trial in 2:
			e.st = "idle"
			e.st_t = 0.0
			e.hp = 2000.0
			reset_to(B + Vector2(5.0, 0))
			main.player.inv = 0.0
			var hp0: float = main.player.hp
			await wait(0.15)
			warned = warned or (e.st == "warn" and e.get("tele", null) != null)
			var dir0: Vector2 = e.dir
			if trial == 1:
				main.player.x = B.x
				main.player.z = B.y + 3.5 # off the lane, inside the ring's radius but this is the first phase: no ring
			await wait_for(func(): return e.st == "strike", 2.0)
			main.player.inv = 0.0
			await wait(0.2)
			var took: bool = main.player.hp < hp0 - 0.01
			lane_hits += (1 if took else 0) if trial == 0 else (100 if took else 0)
			e.st = "idle"
			e.st_t = 9.0
			e.expo = 0.0
			main.player.hp = float(main.player.max_hp)
		var lane_ok: bool = warned and lane_hits == 1
		# closed it takes half, open the full blow
		var closed := 0.0
		var open := 0.0
		for k in 6:
			e.expo = 0.0
			var h0: float = e.hp
			main.damage_enemy(e, 100.0, B + Vector2(2, 0), 0.0, true)
			closed += h0 - e.hp
			e.expo = 3.0
			h0 = e.hp
			main.damage_enemy(e, 100.0, B + Vector2(2, 0), 0.0, true)
			open += h0 - e.hp
			e.hp = 2000.0
		var ratio: float = open / maxf(closed, 0.01)
		var halves: bool = ratio > 1.7 and ratio < 2.3
		# phase two (below 60 %): the ring after the lane, its blow once, only inside 4 tiles
		e.hp = 1100.0
		e.st = "idle"
		e.st_t = 0.0
		e.expo = 0.0
		reset_to(B + Vector2(6.0, 0))
		main.player.inv = 0.0
		await wait(0.15)
		var ph2: bool = e.ph2
		main.player.x = B.x
		main.player.z = B.y + 3.0
		await wait_for(func(): return e.st == "ring", 3.0)
		var ringed: bool = e.st == "ring"
		var hpr: float = main.player.hp
		main.player.inv = 0.0
		await wait_for(func(): return e.st == "wave", 2.0)
		await wait(0.1)
		var wave_hit: bool = main.player.hp < hpr - 0.01
		e.st = "idle"
		e.st_t = 99.0
		# every second pattern the side door shows, 6 s; the lever then adds 5 s of the open axis
		e.pats = 1
		e.st = "rest"
		e.st_t = 0.01
		e.expo = 0.0
		await wait(0.2)
		var assist: bool = e.assist > 5.0 and Z.next_spot() != Vector3.INF
		var mark_at_a: bool = absf(Z.next_spot().x - C.at(3, "A").x) < 0.01
		await corr_press("A", 3)
		var side_door: bool = e.assist <= 0.0 and e.expo > 4.0
		e.st = "idle"
		e.st_t = 99.0
		# the stairs are shut while it stands; a faint wakes her at the stair with the keeper starting over
		reset_to(C.at(3, "S") + Vector2(0.3, 0))
		await wait(0.6)
		var shut: bool = main.in_corridor() and main.corridor.room_of(main.player.x) == 3
		main.sora.faint()
		await wait(0.2)
		var woke: bool = main.in_corridor() and Z.gate_alive() == null and main.corridor_q == 4 and main.corr_bits == 7 and main.player.hp == float(main.player.max_hp) and Vector2(main.player.x, main.player.z).distance_to(C.at(3, "S") + Vector2(1, 0)) < 0.6 and not main.ui.boss.visible
		Z.spawn_gate()
		e = Z.gate_alive()
		var again: bool = e != null and e.hp == 2000.0
		# the kill: q5, the knot, two potions, gold once
		var g0: int = main.player.gold
		var p0: int = main.player.pots
		e.st_t = 99.0
		e.hp = 1.0
		main.damage_enemy(e, 100.0, B + Vector2(2, 0), 0.0, true)
		await wait(1.6)
		var beaten: bool = main.corridor_q == 5 and main.corr_reward and main.player.pots == p0 + 2 and main.player.gold == g0 + 260 and not main.ui.boss.visible
		Z.boss_beaten()
		var once: bool = main.player.gold == g0 + 260 and main.player.pots == p0 + 2
		# the answer stand: the water goes (lamps), then the answer closes it
		var tokens0: int = main.moon_tokens.count()
		await corr_press("C", 3)
		var sent: bool = main.corr_sec[3].sent and main.corridor_q == 5
		await corr_press("C", 3)
		var wait_lamps: bool = main.corridor_q == 5
		await wait(3.2)
		await corr_press("C", 3)
		var closed_q: bool = main.corridor_q == 6 and main.story_open
		main.close_story()
		var opened: bool = not main.moon_tokens.holds("forest") or main.forest_q >= 1
		var not_token: bool = main.moon_tokens.count() == tokens0 and main.tokens.size() == 6 and main.moon_tokens.STAIRS_NEED == 4
		check("corridor_boss", lone and lane_ok and halves and ph2 and ringed and wave_hit and assist and mark_at_a and side_door and shut and woke and again and beaten and once and sent and wait_lamps and closed_q and opened and not_token,
			"keeper 2000=%s; lane warned and hit once, none off it=%s; half closed (x%.2f)=%s; phase 2 ring %s/%s hit %s; side door %s on the lever %s, +5 s=%s; faint wakes at the stair, keeper reset=%s %s; kill once: q5 knot 2 potions gold=%s/%s; stand: sent=%s, waits=%s, answer q6=%s, forest opens=%s; no token=%s" % [lone, lane_ok, ratio, halves, ph2, ringed, wave_hit, assist, mark_at_a, side_door, woke, again, beaten, once, sent, wait_lamps, closed_q, opened, not_token])
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6

	if want.call("corridor_save"):
		# saved mid-way: q, the three room dictionaries, the wheel bits, the knot and the checkpoint come back; the room starts at its stair;
		# a fight cut short is cleared and the wheels already joined stay; old and odd saves are mended
		calm_enemies(true)
		await corr_prep(2, 1)
		var Z = main.corridor_zone
		var C = main.corridor
		main.corr_sec[0].record_read = true
		main.corr_sec[0].latch_fixed = true
		main.corr_sec[1].water_high = true
		main.corr_sec[1].drained = false
		C.set_gate(0, true)
		C.set_water(1, true)
		main.corr_check = 1
		reset_to(Vector2(C.origin(1) + 14.0, 8.0))
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var keys: bool = int(sd.get("corridor_q", -1)) == 2 and sd.get("corridor_section_state", []).size() == 4 and sd.has("corridor_core_bits") and sd.has("corridor_reward_claimed") and sd.has("corridor_checkpoint")
		# wipe, then load
		main.corr_sec = Z.fresh_sections()
		main.corridor_q = 0
		main.corr_bits = 0
		C.set_gate(0, false)
		C.set_water(1, false)
		main.load_game()
		await wait(0.4)
		main.close_story()
		var back: bool = main.in_corridor() and main.corridor_q == 2 and main.corr_sec[0].record_read and main.corr_sec[0].latch_fixed and main.corr_sec[1].water_high and C.high[1] and C.gate_open[0] and not C.gate_open[1]
		var at_stair: bool = Vector2(main.player.x, main.player.z).distance_to(C.at(1, "S") + Vector2(1, 0)) < 0.6
		# the wheel hall cut mid-group: bits kept, the bricks of the group gone, the keeper not there
		await corr_prep(4, 3)
		main.corr_bits = 1
		main.corr_sec[3] = {"record_read": true, "water_high": true, "latch_fixed": true, "sent": false}
		Z.apply_state()
		await corr_press("F", 3, 1, Vector2(0.0, 1.0))
		var fighting: bool = Z.group_active == 1 and corr_foes().size() == 3
		main.save_game()
		main.corr_bits = 0
		main.load_game()
		await wait(0.4)
		main.close_story()
		var cut: bool = main.corr_bits == 1 and Z.group_active < 0 and corr_foes().is_empty() and Z.gate_alive() == null and C.wheels[3][0].on and not C.wheels[3][1].on
		# old saves: no key is q0, or q6 when the save is already past the forest; odd values are mended
		main.forest_q = 0
		Z.load_data({})
		var old0: bool = main.corridor_q == 0 and main.corr_sec[0].latch_fixed == false
		main.forest_q = 1
		Z.load_data({})
		var old6: bool = main.corridor_q == 6 and main.corr_sec[2].latch_fixed and main.corr_bits == 7
		main.forest_q = 0
		Z.load_data({"corridor_q": 9, "corridor_section_state": [1, "x", {"water_high": 5, "latch_fixed": true}], "corridor_core_bits": 5, "corridor_checkpoint": 9})
		var odd: bool = main.corridor_q == 6 and main.corr_check == 3 and main.corr_bits == 7
		Z.load_data({"corridor_q": 1, "corridor_section_state": [{"latch_fixed": true, "water_high": true}], "corridor_core_bits": 5})
		var mended: bool = main.corridor_q == 1 and main.corr_bits == 0 and not main.corr_sec[0].latch_fixed and main.corr_sec[0].water_high
		Z.load_data({"corridor_q": 5, "corridor_section_state": [], "corridor_core_bits": 0})
		var q5: bool = main.corr_reward and main.corr_bits == 7 and main.corr_sec[3].latch_fixed
		check("corridor_save", keys and back and at_stair and fighting and cut and old0 and old6 and odd and mended and q5,
			"save keys=%s; reload mid-way=%s at the stair=%s; group cut: fighting=%s, bits kept and bricks gone=%s; old save q0=%s, past the forest q6=%s; odd values=%s, mended=%s, q5 keeps the knot=%s" % [keys, back, at_stair, fighting, cut, old0, old6, odd, mended, q5])
		calm_enemies(false)
		main.in_lake = false
		main.forest_q = maxi(main.forest_q, 0)
		main.corridor_q = 6
		Z.load_data({"corridor_q": 6})

	if want.call("corridor_fix"):
		# v0.1.91 (GPT's corridor report 1): a drain cut by a save or a faint stays drained; the cart and the role swap come back
		# right; a friend at work cannot be hit; a finished room's lever stays; the plates are read first; the keeper's side door
		# stops its attack; the line, the "!" and the journal tell the next step
		calm_enemies(true)
		var Z = main.corridor_zone
		var C = main.corridor
		# 1. drain: F, then a save or a room change inside its first second
		await corr_prep(2, 1)
		corr_kill(corr_foes())
		main.corr_sec[1].water_high = true
		C.set_water(1, true)
		await corr_press("F", 1, 0, Vector2(-0.8, 0))
		var f_now: bool = main.corr_sec[1].drained and not main.corr_sec[1].water_high
		Z.clear_job() # a room change inside the drain's second
		var cut_low: bool = not C.high[1]
		C.set_water(1, true) # as a save from that second used to load: drained and still high
		main.corr_sec[1].water_high = true
		Z.repair()
		Z.apply_state()
		var repaired: bool = not C.high[1] and not main.corr_sec[1].water_high
		await corr_press("A", 1)
		var fixed_low: bool = main.corr_sec[1].latch_fixed and main.corridor_q == 3 and not C.high[1] and Z.trans.is_empty()
		var a_done: bool = fixed_low
		# 2. a finished room's lever does not undo it
		await corr_press("A", 1)
		await wait(1.4)
		var stays_low: bool = not C.high[1] and Z.trans.is_empty() and main.corr_sec[1].latch_fixed
		await corr_prep(2, 0)
		await corr_press("A", 0)
		await wait(1.4)
		var r0_low: bool = not C.high[0] and Z.trans.is_empty() and not main.corr_sec[0].water_high
		# 3. the cart: a faint or a new visit puts it back on the west bank with nothing under way; moored it stays at R
		await corr_prep(3, 2)
		var T: Vector2 = C.at(2, "T")
		var R: Vector2 = C.at(2, "R")
		Z.arrived = true
		C.carts[2].position.x = R.x
		Z.on_faint()
		var cart_back: bool = not Z.arrived and absf(C.carts[2].position.x - T.x) < 0.1 and Z.ride.is_empty()
		await corr_press("P", 2)
		await wait(1.2)
		await corr_press("A", 2)
		await wait(2.3)
		await corr_press("T", 2, 0, Vector2(-0.4, 0))
		var rides_again: bool = not Z.ride.is_empty()
		Z.clear_job()
		main.corr_sec[2].docked = true
		Z.apply_state()
		var cart_moored: bool = absf(C.carts[2].position.x - R.x) < 0.1
		main.corr_sec[2].docked = false
		Z.apply_state()
		# 4. Mulgyeol at a post is out of the fight, and a knock-down frees the post
		await corr_prep(1, 0)
		main.corr_sec[0].record_read = true
		var P: Vector2 = C.at(0, "P")
		Z.place_post(0)
		main.mate.position = Vector3(P.x, 0.0, P.y)
		var safe: bool = main.mates.mate_near(P, 1.0) == "" and main.mate_down["mulgyeol"] <= 0.0
		Z.release_post()
		main.mate.position = Vector3(P.x, 0.0, P.y)
		var hit_free: bool = main.mates.mate_near(P, 1.0) == "mulgyeol"
		Z.place_post(0)
		await wait(0.3)
		main.mate_down["mulgyeol"] = 2.0
		await wait(0.3)
		var freed: bool = Z.post_room == -1 and main.mate_job.is_empty()
		main.mate_down["mulgyeol"] = 0.0
		# 5. the last room's role swap comes back after a faint and a load: Mulgyeol at the far post, the line from the lever
		await corr_prep(4, 3)
		main.corr_sec[3] = {"record_read": true, "water_high": true, "latch_fixed": true, "sent": false}
		Z.apply_state()
		Z.enter_room(3, false)
		var R3: Vector2 = C.at(3, "R")
		var swap_in: bool = main.mate_job.get("kind", "") == "corr_post" and Vector2(main.mate.position.x, main.mate.position.z).distance_to(R3) < 0.3 and C.link.visible and absf(C.carts[3].position.x - R3.x) < 0.1
		main.mate.position = Vector3(C.at(3, "S").x + 1.0, 0.0, C.at(3, "S").y)
		Z.on_faint()
		var swap_faint: bool = main.mate_job.get("kind", "") == "corr_post" and Vector2(main.mate.position.x, main.mate.position.z).distance_to(R3) < 0.3
		main.corr_check = 3
		main.save_game()
		main.mate_job = {}
		main.mate.position = Vector3(0, 0, 0)
		main.load_game()
		await wait(0.4)
		main.close_story()
		var swap_load: bool = main.mate_job.get("kind", "") == "corr_post" and Vector2(main.mate.position.x, main.mate.position.z).distance_to(R3) < 0.5 and main.corr_sec[3].latch_fixed
		# the other rooms' carts: unstarted ones stand at T
		var carts_t: bool = absf(C.carts[3].position.x - R3.x) < 0.1
		# 6. the plates come first: no device works before its plate is read
		await corr_prep(1, 0)
		await corr_press("P", 0)
		var no_post: bool = Z.post_room == -1
		await corr_press("A", 0)
		await wait(1.5)
		var no_lever: bool = not C.high[0] and Z.trans.is_empty()
		await corr_prep(4, 3)
		await corr_press("A", 3)
		var no_hold: bool = not main.corr_sec[3].water_high
		await corr_press("H", 3)
		var two_hands: bool = main.corr_sec[3].record_read and main.story_open
		main.close_story()
		await corr_press("A", 3)
		var holds_now: bool = main.corr_sec[3].water_high
		# 7. the keeper: the side door cancels the warning (and the ring) and stretches the open axis
		await corr_prep(4, 3)
		main.corr_bits = 7
		main.corr_told = true
		main.corr_sec[3] = {"record_read": true, "water_high": true, "latch_fixed": true, "sent": false}
		Z.apply_state()
		Z.spawn_gate()
		var e: Dictionary = Z.gate_alive()
		var A3: Vector2 = C.at(3, "A")
		e.x = A3.x + 5.5
		e.z = A3.y
		reset_to(A3 + Vector2(0.9, 0))
		main.player.inv = 0.0
		main.player.hp = float(main.player.max_hp)
		e.st = "idle"
		e.st_t = 0.0
		await wait_for(func(): return e.st == "warn", 1.5)
		var warned: bool = e.st == "warn" and e.tele != null
		e.assist = 6.0
		tap(KEY_E)
		await wait(0.15)
		var arm_cut: bool = e.st == "expose" and e.expo > 4.4 and e.tele == null and C.side_open
		await wait(1.6) # the blow would have landed by now
		var arm_safe: bool = main.player.hp == float(main.player.max_hp) and e.st == "expose"
		e.st = "idle"
		e.st_t = 99.0
		e.expo = 0.0
		e.hp = 1100.0
		e.x = A3.x + 3.0
		e.st = "ring"
		e.st_t = 1.0
		Z.ring_warn(e, 1.0)
		var ring_up: bool = e.ring_nodes.size() == 2
		e.assist = 6.0
		reset_to(A3 + Vector2(0.9, 0))
		tap(KEY_E)
		await wait(0.15)
		var ring_cut: bool = e.st == "expose" and e.ring_nodes.is_empty() and e.expo > 4.4
		await wait(1.4)
		var ring_safe: bool = main.player.hp == float(main.player.max_hp)
		var told: bool = e.told_axis
		var front: bool = e.node.get_meta("body").get_child_count() > 10
		e.expo = 2.0 # an exposure under way is lengthened, not replaced
		e.st = "expose"
		e.st_t = 2.0
		e.assist = 6.0
		tap(KEY_E)
		await wait(0.15)
		var longer: bool = e.expo > 6.5 and e.st_t > 6.5
		Z.clear_fight()
		# 8. the line, the answer stand's two presses, the shortcut sign, the journal
		await corr_prep(2, 1)
		var l2: bool = main.quest_raw.contains("Shift")
		await corr_prep(3, 2)
		var l3: bool = main.quest_raw.contains("맡기자") and C.at(2, "T").x < C.origin(2) + 8.0
		await corr_prep(5, 3)
		main.corr_sec[3] = {"record_read": true, "water_high": true, "latch_fixed": true, "sent": false}
		Z.apply_state()
		Z.refresh_quest()
		var l5a: bool = main.quest_raw.contains("물을 보내자")
		await corr_press("C", 3)
		var l5b: bool = main.quest_raw.contains("켜지는")
		await wait(2.2)
		var l5c: bool = main.quest_raw.contains("응답을 확인")
		await corr_prep(6, 3)
		Z.refresh_quest()
		var l6: bool = main.quest_raw.contains("호수 섬") and C.shortcut.visible
		await corr_prep(4, 2)
		var jr: String = Z.journal()
		var jr_ok: bool = jr.contains(" · ") and jr.contains(main.quest_raw)
		main.corridor_q = 0
		main.tokens[2] = false
		var j0: bool = Z.journal().contains("진주")
		main.tokens[2] = true
		main.south_q = 0
		var j0b: bool = Z.journal().contains("물시계")
		main.south_q = 4
		check("corridor_fix", f_now and cut_low and repaired and a_done and stays_low and r0_low and cart_back and rides_again and cart_moored and safe and hit_free and freed and swap_in and swap_faint and swap_load and carts_t and no_post and no_lever and no_hold and two_hands and holds_now and warned and arm_cut and arm_safe and ring_up and ring_cut and ring_safe and told and front and longer and l2 and l3 and l5a and l5b and l5c and l6 and jr_ok and j0 and j0b,
			"drain: saved low at once=%s, a room change finishes it=%s, a loaded drained+high mends=%s, fixing leaves low=%s; done room's lever stays=%s/%s; cart back at T after a faint=%s, rides again=%s, moored at R=%s; friend at a post cannot be hit=%s, can when free=%s, knocked down frees it=%s; role swap kept on entry=%s, faint=%s, load=%s, cart at R=%s; plates first: post=%s lever=%s sluice=%s, two hands talk=%s then holds=%s; keeper: warn %s, side door cuts the arm=%s safe=%s; ring up=%s cut=%s safe=%s; axis told=%s, front mark=%s, exposure lengthens=%s; lines: room2=%s room3=%s stand=%s/%s/%s shortcut=%s; journal=%s/%s/%s" % [f_now, cut_low, repaired, fixed_low, stays_low, r0_low, cart_back, rides_again, cart_moored, safe, hit_free, freed, swap_in, swap_faint, swap_load, carts_t, no_post, no_lever, no_hold, two_hands, holds_now, warned, arm_cut, arm_safe, ring_up, ring_cut, ring_safe, told, front, longer, l2, l3, l5a, l5b, l5c, l6, jr_ok, j0, j0b])
		corr_kill(corr_foes())
		calm_enemies(false)
		main.in_lake = false
		main.corridor_q = 6
		Z.load_data({"corridor_q": 6})

	if want.call("corridor_gate"):
		# the forest gate: the pearl, the pond and the corridor, each missing holds it; all three or a save already past it do not;
		# the waystones do not reach the forest early; the quest line and the gold "!" lead the way in and back
		main.close_story()
		var truth := true
		var rows := ""
		main.forest_q = 0
		for bits in 8:
			main.tokens[2] = (bits & 1) != 0
			main.south_q = 4 if (bits & 2) != 0 else 0
			main.corridor_q = 6 if (bits & 4) != 0 else 0
			var want_hold: bool = bits != 7
			var held: bool = main.moon_tokens.holds("forest")
			truth = truth and held == want_hold
			rows += "%d%s " % [bits, "H" if held else "-"]
		main.tokens[2] = true
		main.south_q = 4
		main.corridor_q = 0
		var miss: String = main.moon_tokens.missing("forest")
		main.tokens[2] = false
		var miss_pearl: String = main.moon_tokens.missing("forest")
		main.tokens[2] = true
		main.south_q = 0
		var miss_pond: String = main.moon_tokens.missing("forest")
		var order: bool = miss == "corridor" and miss_pearl == "pearl" and miss_pond == "pond"
		main.south_q = 4
		main.forest_q = 1
		main.tokens[2] = false
		main.corridor_q = 0
		var past: bool = not main.moon_tokens.holds("forest") # a save already in the forest is never held again
		main.forest_q = 0
		main.tokens[2] = true
		# the held gate says the corridor line and sets the need
		main.in_village = true
		main.in_lake = false
		reset_to(main.village.marks.F + Vector2(-0.3, 0))
		var pass1: bool = main.moon_tokens.gate("forest", main.village.marks.F)
		var said: bool = (not pass1) and main.story_open and main.quest_raw == "숲으로 가기 전에: 물길 회랑에서 정원으로 물을 보내자"
		main.close_story()
		var story_ok: bool = main.STORY.GATE.has("forest_corridor") and main.STORY.GATE["forest_corridor"][0].begins_with("||진주와 물시계는 깨어났으나")
		main.corridor_q = 6
		var pass2: bool = main.moon_tokens.gate("forest", main.village.marks.F)
		var journal: bool = true
		main.corridor_q = 0
		journal = main.moon_tokens.gate_lines().any(func(l): return l.contains("물길 회랑") and l.contains("아직"))
		main.corridor_q = 6
		journal = journal and not main.moon_tokens.gate_lines().any(func(l): return l.contains("물길 회랑"))
		# waystones: the forest and the later stones stay unknown (and untravelled) until they were reached
		var keep_q: Array = [main.hill_q, main.castle_q]
		main.forest_q = 0
		main.hill_q = 0
		main.castle_q = 0
		main.corridor_q = 0
		var unknown: bool = not main.way_known(3) and not main.way_known(4) and not main.way_known(5)
		var ix: float = main.player.x
		main.waystones.travel(3)
		await wait(0.6)
		var stays: bool = not main.in_forest and absf(main.player.x - ix) < 1.0
		# the line and the "!" in the lake lead to the stair, then through the rooms, then home
		main.in_village = false
		corr_world()
		main.corridor_q = 0
		main.tokens[2] = true
		main.set_quest(main.moon_tokens.lake_line())
		reset_to(main.lake.marks.V + Vector2(3.0, -2.0))
		main.ui.mini.map_tex = main.lake_zone.lake_map()
		var mark_v: Vector3 = main.quest_marks.quest_target()
		var lead: bool = absf(mark_v.x - main.lake.marks.V.x) < 0.01 and absf(mark_v.z - main.lake.marks.V.y) < 0.01
		await corr_prep(1, 0)
		var m0: Vector3 = main.quest_marks.quest_target()
		var at_h: bool = absf(m0.x - main.corridor.at(0, "H").x) < 0.01
		await corr_prep(3, 0)
		var m1: Vector3 = main.quest_marks.quest_target()
		var at_n: bool = absf(m1.x - main.corridor.at(0, "N").x) < 0.01 # the work is two rooms on: the door N
		await corr_prep(6, 3)
		var m2: Vector3 = main.quest_marks.quest_target()
		var at_s: bool = absf(m2.x - main.corridor.at(3, "S").x) < 0.01 and main.quest_raw != "" # done: the stair, the line is the road's
		main.in_lake = false
		main.corridor_q = 6
		main.hill_q = keep_q[0]
		main.castle_q = keep_q[1]
		check("corridor_gate", truth and order and past and said and story_ok and pass2 and journal and unknown and stays and lead and at_h and at_n and at_s,
			"forest gate table (bits pearl/pond/corridor, H=held) %s=%s; missing order corridor/pearl/pond=%s; past forest never held=%s; held says the line and the talk=%s/%s; opens=%s; journal=%s; waystones unknown=%s stay=%s; ! at V=%s, at plate=%s, at door=%s, at stair=%s" % [rows, truth, order, past, said, story_ok, pass2, journal, unknown, stays, lead, at_h, at_n, at_s])

	if want.call("corridor_round"):
		# a new round: the corridor starts again (nothing of it is kept), and the knot is not a token
		main.forest_q = 0
		main.corridor_q = 6
		main.corr_reward = true
		main.corr_bits = 7
		main.corr_sec[2].latch_fixed = true
		main.write_new_round()
		var sd2 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var dropped: bool = not sd2.has("corridor_q") and not sd2.has("corridor_section_state") and not sd2.has("corridor_core_bits") and not sd2.has("corridor_reward_claimed")
		main.corridor_zone.load_data(sd2)
		var fresh: bool = main.corridor_q == 0 and not main.corr_reward and main.corr_bits == 0 and not main.corr_sec[2].latch_fixed and not main.corridor.gate_open[0]
		check("corridor_round", dropped and fresh, "new-round save has no corridor keys=%s; loading it starts at q0 with no knot and shut gates=%s" % [dropped, fresh])
		main.corridor_zone.load_data({"corridor_q": 6})
		main.return_to_start()

	# ---- 달맞이 관측원 (v0.1.120, the owner's "1안" 2026-10-29): the hill's stair, four rooms, the ordeal, the moth, the answer stand
	if want.call("obs_enter"):
		calm_enemies(true)
		obs_world()
		var keep_q: Array = [main.hill_q, main.mill_q, main.trial_won, main.castle_q]
		main.observatory_q = 0
		main.castle_q = 0
		main.hill_q = 1 # (2 would call the hawk's talk: the perch is 4 tiles off)
		reset_to(main.hill.marks.O + Vector2(0, 0.3))
		main.toast_t = 0.0
		await wait(0.7)
		var no_hawk: bool = not main.in_observatory() and main.observatory_q == 0
		main.hill_q = 3
		main.mill_q = 4
		reset_to(main.hill.marks.O + Vector2(0, 0.3))
		main.toast_t = 0.0
		await wait(0.7)
		var no_mill: bool = not main.in_observatory() and main.observatory_q == 0
		main.mill_q = 5
		main.trial_won = false
		reset_to(main.hill.marks.O + Vector2(0, 0.3))
		main.toast_t = 0.0
		await wait(0.7)
		var no_trial: bool = not main.in_observatory() and main.observatory_q == 0
		main.trial_won = true
		reset_to(main.hill.marks.O + Vector2(0, 0.3))
		await wait(1.5)
		var inside: bool = main.in_observatory() and main.observatory_q == 1 and main.story_open and main.in_hill and not main.in_corridor() and not main.in_lake
		main.close_story()
		var at_s: bool = main.obs.room_of(main.player.x) == 0 and Vector2(main.player.x, main.player.z).distance_to(main.obs.at(0, "S") + Vector2(1, 0)) < 0.6
		var zone: bool = main.ui.zone_name.text == "달맞이 관측원"
		# eight maps in four rooms: 30 x 22, a wall all round, origins 900/940/980/1020, the gap in cols 8..10, and S reaches D reaches N or C
		var dims := true
		var reach := true
		var gaps := true
		for r in 4:
			var g: Array = main.obs.grids[r]
			dims = dims and g.size() == 22 and g.all(func(row): return row.length() == 30 and row[0] == "#" and row[29] == "#") and g[0] == "#".repeat(30) and g[21] == "#".repeat(30)
			dims = dims and main.obs.origin(r) == 900 + 40 * r
			var goal: String = "N" if r < 3 else "C"
			reach = reach and main.obs.at(r, "S") != Vector2.INF and main.obs.at(r, goal) != Vector2.INF
			if r < 3:
				var d: Vector2 = main.obs.at(r, "D")
				reach = reach and d != Vector2.INF and main.obs.at(r, "S").x < d.x and d.x < main.obs.at(r, "N").x and d.y == main.obs.at(r, "S").y
				for z in 22:
					if z != int(d.y):
						reach = reach and main.obs.grids[r][z][20] == "#"
					if z > 0 and z < 21:
						gaps = gaps and g[z].substr(8, 3) == "___"
				gaps = gaps and main.obs.at(r, "O").x == main.obs.origin(r) + 7 and main.obs.at(r, "T").x == main.obs.origin(r) + 12 and main.obs.at(r, "Q").y == main.obs.at(r, "R").y - 3
		# no other area's test fits where the rooms are, and the corridor stops where they begin
		var apart := true
		for px in [900.0, 940.0, 980.0, 1020.0, 1049.0]:
			var keep_x: float = main.player.x
			main.player.x = px
			apart = apart and main.in_observatory() and not main.in_corridor() and not main.in_castle() and not main.in_workshop() and not main.in_cloud() and not main.in_stairs() and not main.in_under() and not main.in_grotto()
			main.player.x = keep_x
		var keep_hill: bool = main.in_hill
		main.in_hill = false
		main.in_lake = true
		var keep_px: float = main.player.x
		main.player.x = 899.0
		var last_corr: bool = main.in_corridor() and not main.in_observatory()
		main.player.x = 900.0
		var first_obs: bool = not main.in_corridor()
		main.player.x = keep_px
		main.in_lake = false
		main.in_hill = keep_hill
		var wall_water: bool = main.tile_at(900.0, 0.0) == main.WATER and main.tile_at(main.obs.at(0, "S").x + 1.0, 10.0) == main.GRASS and main.tile_at(909.0, 10.0) == main.WATER
		# the stair out: back on the hill by O
		reset_to(main.obs.at(0, "S") + Vector2(0.3, 0))
		await wait(1.5)
		var out: bool = not main.in_observatory() and main.in_hill and Vector2(main.player.x, main.player.z).distance_to(main.hill.marks.O) < 2.0
		check("obs_enter", no_hawk and no_mill and no_trial and inside and at_s and zone and dims and reach and gaps and apart and last_corr and first_obs and wall_water and out,
			"O shut without the hawk=%s, the mill=%s, the trial=%s; entered q1 with the talk=%s beside S=%s, zone=%s; maps 30x22 walled, origins, gap, S to D to N/C=%s/%s/%s, no clash=%s, the corridor ends at 899=%s/%s, wall=%s, stair out=%s" % [no_hawk, no_mill, no_trial, inside, at_s, zone, dims, reach, gaps, apart, last_corr, first_obs, wall_water, out])
		calm_enemies(false)
		main.hill_q = keep_q[0]
		main.mill_q = keep_q[1]
		main.trial_won = keep_q[2]
		main.castle_q = keep_q[3]
		main.in_hill = false
		main.observatory_q = 6

	if want.call("obs_s1"):
		# floor 1: the note, the windmill, the wind hole's gust over the gap, the swivel platform, Noeul's post, the mirror, the receiver
		calm_enemies(true)
		await obs_prep(1, 0)
		obs_kill(obs_foes())
		var C = main.obs
		var Z = main.observatory_zone
		var o: int = C.origin(0)
		var D: Vector2 = C.at(0, "D")
		var shut: bool = not main.walkable(D.x, D.y) and main.tile_at(D.x, D.y) == main.WATER
		await obs_press("M", 0)
		var note_first: bool = not main.obs_sec[0].wind
		await obs_press("H", 0)
		var read: bool = main.obs_sec[0].record_read and main.story_open
		main.close_story()
		# walking does not cross the gap, and the hole sleeps until the windmill turns
		reset_to(Vector2(o + 6.0, 5.0))
		hold_world(Vector2(1, 0))
		await wait(1.0)
		release()
		var walk_stops: bool = main.player.x < o + 8.0
		var dormant: bool = Z.vent_at(o + 7.0, 10.0) == Vector2.ZERO
		await obs_press("M", 0)
		var wind: bool = main.obs_sec[0].wind and Z.vent_at(o + 7.0, 10.0) == Vector2(1, 0) and C.wind_on[0]
		# the hole carries her across: 8 tiles a second over the three tiles of gap, onto the far bank
		reset_to(Vector2(o + 5.5, 10.0))
		# waits on where she is, not a fixed time: late in a full run the game clock can lag the timer
		hold_world(Vector2(1, 0))
		await wait_for(func(): return main.gust_dir != Vector2.ZERO, 3.0)
		release()
		var crossed: bool = await wait_for(func(): return main.player.x > o + 11.0 and main.gust_dir == Vector2.ZERO, 4.0)
		var landed: Vector2 = Vector2(main.player.x - o, main.player.z)
		crossed = crossed and main.player.x < o + 13.0 and absf(main.player.z - 10.0) < 0.6
		var mates_land: bool = Vector2(main.mate.position.x, main.mate.position.z).distance_to(Vector2(main.player.x, main.player.z)) < 4.0 and Vector2(main.mate2.position.x, main.mate2.position.z).distance_to(Vector2(main.player.x, main.player.z)) < 4.0
		# the swivel platform: 2 s to turn, then rows 9..11 of cols 8..10 are floor; nobody on it, and not cut off from the far bank
		await obs_press("T", 0, 0, Vector2(0.9, 0))
		var turning: bool = not Z.trans.is_empty() and not C.plat_open[0] and not main.walkable(o + 9.0, 10.0)
		await wait(2.4)
		var bridged: bool = main.obs_sec[0].angle == 1 and C.plat_open[0] and main.walkable(o + 9.0, 10.0) and main.walkable(o + 8.0, 9.0) and main.walkable(o + 10.0, 11.0) and not main.walkable(o + 9.0, 12.0) and not main.walkable(o + 9.0, 8.0) and Z.vent_at(o + 7.0, 10.0) == Vector2.ZERO
		reset_to(Vector2(o + 9.0, 10.0))
		Z.key_t(0)
		var on_it: bool = Z.trans.is_empty() and main.obs_sec[0].angle == 1
		reset_to(Vector2(o + 11.5, 10.0))
		Z.key_t(0)
		var cut_off: bool = Z.trans.is_empty() and main.obs_sec[0].angle == 1
		reset_to(Vector2(o + 6.0, 10.0))
		hold_world(Vector2(1, 0))
		var walks_over: bool = await wait_for(func(): return main.player.x > o + 11.0, 5.0)
		release()
		walks_over = walks_over and main.gust_dir == Vector2.ZERO
		reset_to(Vector2(o + 11.5, 10.0))
		hold_world(Vector2(-1, 0))
		var walks_back: bool = await wait_for(func(): return main.player.x < o + 8.0, 5.0)
		release()
		walks_back = walks_back and main.gust_dir == Vector2.ZERO
		# Noeul's post, then the mirror (two quarter turns from south to north) and the receiver
		await obs_press("P", 0)
		await wait(1.8)
		var posted: bool = Z.post_room == 0 and main.mate2_job.get("kind", "") == "obs_post" and Vector2(main.mate2.position.x, main.mate2.position.z).distance_to(C.at(0, "P")) < 0.4
		await obs_press("Q", 0)
		var q_dark: bool = main.observatory_q == 1 and not main.obs_sec[0].fixed
		await obs_press("R", 0)
		await obs_press("R", 0)
		var true_mirror: bool = main.obs_sec[0].mirror_dir == 0 and C.grooves[0][1].emission_energy_multiplier > 1.0
		Z.release_post()
		await obs_press("Q", 0)
		var needs_hand: bool = main.observatory_q == 1
		await obs_press("P", 0)
		await wait(0.4)
		await obs_press("Q", 0)
		var fixed: bool = main.obs_sec[0].fixed and main.observatory_q == 2 and C.gate_open[0] and main.walkable(D.x, D.y) and Z.post_room == -1 and main.mate2_job.is_empty()
		reset_to(C.at(0, "N") + Vector2(-0.5, 0))
		await wait(1.5)
		var onward: bool = main.obs.room_of(main.player.x) == 1 and main.ui.zone_sub.text == "관측원 · 꺼진 빛"
		check("obs_s1", shut and note_first and read and walk_stops and dormant and wind and crossed and mates_land and turning and bridged and on_it and cut_off and walks_over and walks_back and posted and q_dark and true_mirror and needs_hand and fixed and onward,
			"D shut=%s; M waits for the note=%s, note read=%s; walking stops=%s, hole sleeps=%s then blows=%s, gust crosses=%s (landed %s), friends land=%s; platform turns=%s, bridges=%s, refuses on it=%s and from the far bank=%s, walk over=%s and back=%s; post=%s; receiver dark=%s, mirror true=%s, needs the hand=%s; fixed, gate open, post freed=%s; next floor=%s" % [shut, note_first, read, walk_stops, dormant, wind, crossed, landed, mates_land, turning, bridged, on_it, cut_off, walks_over, walks_back, posted, q_dark, true_mirror, needs_hand, fixed, onward])
		calm_enemies(false)
		main.in_hill = false
		main.observatory_q = 6

	if want.call("obs_s2"):
		# floor 2: the scale-birds (stats, one lane then one brick, folded wings, no knockback, no crossing), the lantern, the mirror, the hand
		calm_enemies(true)
		await obs_prep(2, 1)
		hold_mates()
		var C = main.obs
		var Z = main.observatory_zone
		var o: int = C.origin(1)
		main.mate_down["mulgyeol"] = 999.0 # friends down, so no brick stops on one of them in the lane
		main.mate_down["noeul"] = 999.0
		var birds: Array = obs_foes()
		var two: bool = birds.size() == 2 and birds.all(func(e): return e.get("scalebird", false) and e.max_hp == 30 + main.foe_lv() * 14)
		var b: Dictionary = birds[0]
		var b2: Dictionary = birds[1]
		b2.atk_cd = 99.0
		b2.x = o + 2.0
		b2.z = 19.0
		b.x = o + 15.0
		b.z = 6.0
		# standing in its line 4 tiles off: 1.1 s of warning, then one brick, then the wings fold 2 s with the seams open
		b.atk_cd = 0.0
		b.fold = 0.0
		reset_to(Vector2(o + 19.0, 6.0))
		main.player.inv = 0.0
		var hp0: float = main.player.hp
		await wait(0.4)
		var warned: bool = b.tele_t > 0.0 and b.get("tele", null) != null and absf(b.face.x) > 0.9
		await wait_for(func(): return b.fold > 1.0, 2.0)
		var shot: bool = b.fold > 1.0 and b.seam > 1.0
		main.player.inv = 0.0
		await wait(1.2)
		var lane_hit: bool = main.player.hp < hp0 - 0.01
		# the same line, Sora steps out of it during the warning: nothing lands
		b.atk_cd = 0.0
		b.fold = 0.0
		b.seam = 0.0
		b.x = o + 15.0
		b.z = 6.0
		reset_to(Vector2(o + 19.0, 6.0))
		main.player.inv = 0.0
		var hp1: float = main.player.hp
		await wait(0.3)
		main.player.z = 9.0
		await wait(2.2)
		var lane_miss: bool = main.player.hp >= hp1 - 0.01
		main.damage_enemy(b, 1.0, Vector2(b.x - 1.0, b.z), 5.0)
		await wait(0.1)
		var no_kb: bool = absf(b.kx) + absf(b.kz) < 0.01
		# it does not come over the gap after her
		b.x = o + 11.5
		b.z = 10.0
		b.fold = 0.0
		b.seam = 0.0
		b.atk_cd = 99.0
		reset_to(Vector2(o + 5.0, 10.0))
		await wait(1.5)
		var stays: bool = b.x > o + 10.4
		obs_kill([b, b2])
		# the lantern, the hand and the mirror: the receiver shows the missing piece each time
		await obs_prep(2, 1)
		hold_mates()
		var live: Array = obs_foes()
		for e in live:
			e.atk_cd = 99.0
		main.obs_sec[1].wind = true
		main.obs_sec[1].mirror_dir = 0
		Z.apply_state()
		Z.place_post(1)
		await obs_press("Q", 1)
		var birds_block: bool = main.observatory_q == 2
		obs_kill(obs_foes())
		await obs_press("Q", 1)
		var lamp_first: bool = main.observatory_q == 2
		var dark_run: bool = C.grooves[1][2].emission_energy_multiplier < 0.5
		await obs_press("L", 1, 1)
		var lit: bool = main.obs_sec[1].lamp_lit and C.grooves[1][2].emission_energy_multiplier > 1.0 and C.grooves[1][0].emission_energy_multiplier > 1.0
		Z.release_post()
		await obs_press("Q", 1)
		var hand_first: bool = main.observatory_q == 2
		await obs_press("P", 1)
		await wait(0.4)
		await obs_press("Q", 1)
		var fixed: bool = main.obs_sec[1].fixed and main.observatory_q == 3 and C.gate_open[1] and main.mate2_job.is_empty()
		check("obs_s2", two and warned and shot and lane_hit and lane_miss and no_kb and stays and birds_block and lamp_first and dark_run and lit and hand_first and fixed,
			"two scale-birds, hp 30+14 a level=%s; lane warned=%s, one brick then folded=%s, hit in the lane=%s, miss out of it=%s; no knockback=%s; stays on its bank=%s; living birds block the receiver=%s; the lantern first=%s (run dark=%s), lit=%s; the hand first=%s; fixed q3=%s" % [two, warned, shot, lane_hit, lane_miss, no_kb, stays, birds_block, lamp_first, dark_run, lit, hand_first, fixed])
		calm_enemies(false)
		main.in_hill = false
		main.observatory_q = 6

	if want.call("obs_s3"):
		# floor 3: the first gust shakes the signal once, then Noeul's hand holds it
		calm_enemies(true)
		await obs_prep(3, 2)
		obs_kill(obs_foes())
		var C = main.obs
		var Z = main.observatory_zone
		var o: int = C.origin(2)
		await obs_press("M", 2)
		var wind: bool = main.obs_sec[2].wind
		await obs_press("R", 2)
		await obs_press("R", 2)
		var mirror: bool = main.obs_sec[2].mirror_dir == 0
		await obs_press("Q", 2)
		var gust: bool = main.obs_sec[2].gust_seen and main.observatory_q == 3 and not main.obs_sec[2].fixed and not main.story_open
		var line: bool = plain(main.quest_raw) == "노을에게 흔들리는 손을 맡기자 (E)"
		await obs_press("Q", 2)
		var again_no: bool = main.observatory_q == 3 and not main.obs_sec[2].fixed
		await obs_press("P", 2)
		await wait(0.4)
		await obs_press("Q", 2)
		var done: bool = main.obs_sec[2].fixed and main.observatory_q == 4 and C.gate_open[2] and main.story_open
		main.close_story()
		check("obs_s3", wind and mirror and gust and line and again_no and done,
			"wind on=%s, mirror north=%s; first signal shaken once, no talk=%s, the line asks for the hand=%s, still not without the hand=%s; with the hand q4 and the talk=%s" % [wind, mirror, gust, line, again_no, done])
		calm_enemies(false)
		main.in_hill = false
		main.observatory_q = 6

	if want.call("obs_top"):
		# the top room: the note, the wind, three mirrors west to east with a group each, the break (Sora alone), the relay with Noeul, the test signal
		calm_enemies(true)
		await obs_prep(4, 3)
		var C = main.obs
		var Z = main.observatory_zone
		var o: int = C.origin(3)
		var mark_h: bool = absf(Z.next_spot().x - C.at(3, "H").x) < 0.01
		await obs_press("R", 3, 0, Vector2(0.0, 0.9))
		var note_first: bool = main.obs_sec[3].dirs[0] == 2
		await obs_press("H", 3)
		var read: bool = main.obs_sec[3].record_read and main.story_open
		main.close_story()
		var mark_m: bool = absf(Z.next_spot().x - C.at(3, "M").x) < 0.01
		await obs_press("R", 3, 0, Vector2(0.0, 0.9))
		var wind_first: bool = main.obs_sec[3].dirs[0] == 2
		await obs_press("M", 3)
		var wind: bool = main.obs_sec[3].wind and C.grooves[3][0].emission_energy_multiplier > 1.0
		var mark_r: bool = absf(Z.next_spot().x - C.at(3, "R", 0).x) < 0.01
		await obs_press("R", 3, 1, Vector2(0.0, 0.9))
		var order: bool = main.obs_sec[3].dirs[1] == 2 and Z.group_active < 0
		var gold0: int = main.player.gold
		var groups := true
		for i in 3:
			var presses: int = 3 if i < 2 else 1 # west and middle turn south to east in three quarter turns, the east one is true already
			for k in presses:
				await obs_press("R", 3, i, Vector2(0.0, 0.9))
			var fs: Array = obs_foes()
			var comp: bool = Z.group_active == i and fs.size() == 3 and fs.filter(func(e): return e.get("bat", false)).size() == 2 and fs.filter(func(e): return e.get("archer", false)).size() == 1
			await obs_press("R", 3, i, Vector2(0.0, 0.9)) # again while the group fights: refused
			var still: bool = obs_foes().size() == 3 and main.obs_bits == [0, 1, 3][i]
			var mark_foe: bool = Z.next_spot() != Vector3.INF
			obs_kill(fs)
			await wait(0.4)
			groups = groups and comp and still and mark_foe and main.obs_bits == [1, 3, 7][i] and Z.group_active < 0 and main.player.gold == gold0 + 20 * (i + 1)
		var dirs_ok: bool = main.obs_sec[3].dirs == [1, 1, 2]
		var mark_q: bool = absf(Z.next_spot().x - C.at(3, "Q").x) < 0.01
		# the first signal: Sora alone, the bracelets go dark, the mirrors turn back; no gauge, hp or purse is touched
		var pips0: int = main.crown_pips
		var hp0: float = main.player.hp
		var pots0: int = main.player.pots
		var gold1: int = main.player.gold
		await obs_press("Q", 3)
		var broke: bool = main.obs_ordeal and main.story_open and not main.obs_top_tested and main.obs_sec[3].dirs == [2, 2, 2] and main.obs_bits == 7 and Z.dark
		var nothing_lost: bool = main.crown_pips == pips0 and main.player.hp == hp0 and main.player.pots == pots0 and main.player.gold == gold1
		main.close_story()
		await wait_for(func(): return Vector2(main.mate2.position.x, main.mate2.position.z).distance_to(C.at(3, "P")) < 0.6, 7.0)
		var gone_dark: bool = not C.bracelet.visible and Z.dark
		var waits_at_p: bool = main.mate2_job.get("kind", "") == "obs_post" and Z.post_room == -1 and Vector2(main.mate2.position.x, main.mate2.position.z).distance_to(C.at(3, "P")) < 0.6
		var mark_p: bool = absf(Z.next_spot().x - C.at(3, "P").x) < 0.01
		# the relay: nothing works without the hand; then west to east again, saved at each mirror
		await obs_press("Q", 3)
		var q_no: bool = not main.obs_top_tested and Z.busy_t == 0.0
		await obs_press("R", 3, 0, Vector2(0.0, 0.9))
		var r_no: bool = main.obs_sec[3].dirs[0] == 2 and main.obs_relay == 0
		var bubbles0: int = main.bubbles_said
		await obs_press("P", 3)
		var placed: bool = Z.post_room == 3 and Z.relay_told and main.bubbles_said >= bubbles0 + 1
		await obs_press("R", 3, 1, Vector2(0.0, 0.9))
		var west_first: bool = main.obs_relay == 0 and main.obs_sec[3].dirs[1] == 2
		var no_new_foes: bool = obs_foes().is_empty()
		for k in 3:
			await obs_press("R", 3, 0, Vector2(0.0, 0.9))
		var one: bool = main.obs_relay == 1 and main.obs_sec[3].dirs[0] == 1 and main.bubbles_said >= bubbles0 + 2
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var saved1: bool = int(sd.get("observatory_relay_bits", -1)) == 1 and bool(sd.get("observatory_ordeal_started", false)) and not bool(sd.get("observatory_top_tested", true))
		await obs_press("Q", 3)
		var early_q: bool = not main.obs_top_tested and Z.busy_t == 0.0
		for k in 3:
			await obs_press("R", 3, 1, Vector2(0.0, 0.9))
		await obs_press("R", 3, 2, Vector2(0.0, 0.9)) # the east mirror is true already: E sets it
		var all_three: bool = main.obs_relay == 7 and main.obs_sec[3].dirs == [1, 1, 2] and main.obs_bits == 7 and no_new_foes and obs_foes().is_empty()
		var mark_q2: bool = absf(Z.next_spot().x - C.at(3, "Q").x) < 0.01
		await obs_press("Q", 3)
		var hand_held: bool = Z.busy_t > 0.0 and not main.obs_top_tested
		await wait(1.3)
		var rekindled: bool = main.obs_top_tested and main.story_open and not Z.dark and main.observatory_q == 4
		reset_to(Vector2(o + 3.0, 16.0)) # away from the moth's spot, so its talk does not start yet
		main.close_story()
		await wait(0.3)
		var glow_back: bool = C.bracelet.visible
		var mark_b: bool = absf(Z.next_spot().x - C.at(3, "B").x) < 0.01
		check("obs_top", mark_h and note_first and read and mark_m and wind_first and wind and mark_r and order and groups and dirs_ok and mark_q and broke and nothing_lost and gone_dark and waits_at_p and mark_p and q_no and r_no and placed and west_first and one and saved1 and early_q and all_three and mark_q2 and hand_held and rekindled and glow_back and mark_b,
			"note first=%s/%s, read=%s; wind first=%s, blows=%s; marks H/M/R/Q=%s/%s/%s/%s; order=%s; three groups bat2+archer1 once each=%s, dirs 1,1,2=%s; the break: %s, nothing lost=%s; Noeul waits at P=%s (mark %s); without the hand: Q=%s, R=%s; post=%s; west first=%s; mirror one joined, saved=%s/%s; early Q=%s; all three joined, no new foes=%s, mark Q=%s; hand held=%s; test signal up with the talk=%s; mark B=%s" % [mark_h, note_first, read, wind_first, wind, mark_m, mark_r, mark_q, mark_q2, order, groups, dirs_ok, broke, nothing_lost, waits_at_p, mark_p, q_no, r_no, placed, west_first, one, saved1, early_q, all_three, mark_q2, hand_held, rekindled, mark_b])
		calm_enemies(false)
		main.in_hill = false
		main.observatory_q = 6

	if want.call("obs_boss"):
		# the brick moth: three lines warned 1.3 s then one brick each, the cross below 60 %, half damage unless it rests, the window and the hand,
		# the failed window reopens, a kill with no help, faint resets it, one reward, then the answer stand
		calm_enemies(true)
		await obs_prep(4, 3)
		main.obs_bits = 7
		main.obs_told = true
		main.obs_ordeal = true
		main.obs_top_tested = true
		main.obs_relay = 7
		main.obs_sec[3] = {"record_read": true, "wind": true, "dirs": [1, 1, 2], "sent": false}
		var C = main.obs
		var Z = main.observatory_zone
		Z.repair()
		Z.apply_state()
		var B: Vector2 = C.at(3, "B")
		Z.spawn_moth()
		var e: Dictionary = Z.moth_alive()
		var lone: bool = e != null and e.hp == 2400.0 and Z.post_room == 3 and main.mate2_job.get("kind", "") == "obs_post"
		hold_mates()
		main.mate_down["mulgyeol"] = 999.0 # Mulgyeol down, so no brick stops on him in the lane
		# the fan is aimed when its warning starts: stand in the middle line, then (second time) leave it
		var lane_hits := 0
		var warned := false
		for trial in 2:
			e.st = "idle"
			e.st_t = 0.0
			e.hp = 2400.0
			e.expo = 0.0
			reset_to(B + Vector2(5.0, 0))
			main.player.inv = 0.0
			var hpa: float = main.player.hp
			await wait(0.15)
			warned = warned or (e.st == "warn" and e.tele_nodes.size() == 3)
			if trial == 1:
				main.player.x = B.x - 3.0
				main.player.z = B.y + 6.0
			await wait_for(func(): return e.st == "land", 3.0)
			main.player.inv = 0.0
			await wait(1.4)
			var took: bool = main.player.hp < hpa - 0.01
			lane_hits += (1 if took else 0) if trial == 0 else (100 if took else 0)
			e.st = "idle"
			e.st_t = 99.0
			e.expo = 0.0
			main.player.hp = float(main.player.max_hp)
		var fan_ok: bool = warned and lane_hits == 1
		# aloft or just up it takes half, resting with the axis open the full blow
		var closed := 0.0
		var open := 0.0
		for k in 6:
			e.expo = 0.0
			var h0: float = e.hp
			main.damage_enemy(e, 100.0, B + Vector2(2, 0), 0.0, true)
			closed += h0 - e.hp
			e.expo = 3.0
			h0 = e.hp
			main.damage_enemy(e, 100.0, B + Vector2(2, 0), 0.0, true)
			open += h0 - e.hp
			e.hp = 2400.0
		var ratio: float = open / maxf(closed, 0.01)
		var halves: bool = ratio > 1.7 and ratio < 2.3
		# below 60 %: after the bricks a cross over its spot (arms 2 wide), the corners of the room are safe
		var cross_hits := 0
		var cross_seen := false
		for trial in 2:
			e.hp = 1100.0
			e.st = "idle"
			e.st_t = 0.0
			e.expo = 0.0
			reset_to(B + Vector2(6.0, 0))
			main.player.inv = 0.0
			await wait(0.15)
			var ph2: bool = e.ph2
			main.player.x = B.x - 12.0 if trial == 0 else B.x
			main.player.z = B.y - 8.0 if trial == 0 else B.y + 3.0
			await wait_for(func(): return e.st == "cross", 4.0)
			cross_seen = (e.st == "cross" and e.tele_nodes.size() == 2 and ph2) if trial == 0 else cross_seen and e.st == "cross"
			var hpc: float = main.player.hp
			main.player.inv = 0.0
			await wait_for(func(): return e.st == "slam", 2.5)
			await wait(0.1)
			var tookc: bool = main.player.hp < hpc - 0.01
			cross_hits += (100 if tookc else 0) if trial == 0 else (1 if tookc else 0)
			e.st = "idle"
			e.st_t = 99.0
			main.player.hp = float(main.player.max_hp)
		var cross_ok: bool = cross_seen and cross_hits == 1
		# every second pattern the window shows 6 s at the receiver; the hand stops the moth's clock 0.8 s, then it lands with the axis open 5 s
		e.hp = 2400.0
		e.pats = 1
		e.st = "land"
		e.st_t = 0.01
		e.expo = 0.0
		await wait(0.2)
		var window: bool = e.assist > 5.0 and Z.next_spot() != Vector3.INF and absf(Z.next_spot().x - C.at(3, "Q").x) < 0.01
		e.st = "warn"
		e.st_t = 50.0
		e.dir = Vector2(1, 0)
		await obs_press("Q", 3)
		await wait(0.4)
		var clock_stands: bool = e.hand_t > 0.0 and e.st_t > 49.0 and e.st == "warn"
		await wait(0.6)
		var landed: bool = e.st == "land" and e.expo > 4.0 and e.hand_t <= 0.0 and e.assist <= 0.0
		# a window that was not used opens again two patterns later, and the moth falls with no help at all
		e.pats = 3
		e.st = "land"
		e.st_t = 0.01
		e.expo = 0.0
		await wait(0.2)
		var reopens: bool = e.assist > 5.0
		e.st = "idle"
		e.st_t = 99.0
		e.assist = 0.0
		# the stair is shut while it stands; a faint wakes her at the stair with the moth starting over
		reset_to(C.at(3, "S") + Vector2(0.3, 0))
		await wait(0.6)
		var shut: bool = main.in_observatory() and main.obs.room_of(main.player.x) == 3
		main.sora.faint()
		await wait(0.2)
		var woke: bool = main.in_observatory() and Z.moth_alive() == null and main.observatory_q == 4 and main.obs_top_tested and main.obs_bits == 7 and main.player.hp == float(main.player.max_hp) and Vector2(main.player.x, main.player.z).distance_to(C.at(3, "S") + Vector2(1, 0)) < 0.6 and not main.ui.boss.visible
		Z.spawn_moth()
		e = Z.moth_alive()
		var again: bool = e != null and e.hp == 2400.0
		# the kill: q5, the scale, two potions, gold once
		var g0: int = main.player.gold
		var p0: int = main.player.pots
		e.st_t = 99.0
		e.hp = 1.0
		main.damage_enemy(e, 100.0, B + Vector2(2, 0), 0.0, true)
		await wait(1.6)
		var beaten: bool = main.observatory_q == 5 and main.obs_reward and main.player.pots == p0 + 2 and main.player.gold >= g0 + 300 and main.player.gold <= g0 + 330 and not main.ui.boss.visible
		var g1: int = main.player.gold
		Z.boss_beaten()
		var once: bool = main.player.gold == g1 and main.player.pots == p0 + 2
		# the answer stand: the corridor's lamps first; then the hand's talk, the lamps, and the answer closes it
		var tokens0: int = main.moon_tokens.count()
		var keep_cq: int = main.corridor_q
		main.corridor_q = 0
		await obs_press("C", 3)
		var corr_first: bool = not main.obs_sec[3].sent and main.observatory_q == 5
		main.corridor_q = 6
		await obs_press("C", 3)
		var sent: bool = main.obs_sec[3].sent and main.observatory_q == 5 and main.story_open
		main.close_story()
		await obs_press("C", 3)
		var wait_lamps: bool = main.observatory_q == 5
		await wait(3.2)
		await obs_press("C", 3)
		var closed_q: bool = main.observatory_q == 6 and C.shortcut.visible
		var opened: bool = not main.moon_tokens.holds("castle") or main.castle_q >= 1
		var not_token: bool = main.moon_tokens.count() == tokens0 and main.tokens.size() == 6 and main.moon_tokens.STAIRS_NEED == 4
		reset_to(C.at(3, "S") + Vector2(0.3, 0))
		await wait(1.5)
		var home: bool = not main.in_observatory() and main.in_hill and Vector2(main.player.x, main.player.z).distance_to(main.hill.marks.O) < 2.0
		main.corridor_q = keep_cq
		check("obs_boss", lone and fan_ok and halves and cross_ok and window and clock_stands and landed and reopens and shut and woke and again and beaten and once and corr_first and sent and wait_lamps and closed_q and opened and not_token and home,
			"moth 2400=%s; fan warned and hit once, none off it=%s; half aloft (x%.2f)=%s; cross seen and only on the arms=%s; window at Q=%s, the hand stops its clock=%s then it lands open 5 s=%s; unused window reopens=%s; faint wakes at the stair, moth reset=%s %s; kill once: q5 scale 2 potions gold=%s/%s; stand: needs the corridor=%s, sent=%s, waits=%s, answer q6=%s, castle opens=%s; no token=%s; stair home=%s" % [lone, fan_ok, ratio, halves, cross_ok, window, clock_stands, landed, reopens, woke, again, beaten, once, corr_first, sent, wait_lamps, closed_q, opened, not_token, home])
		calm_enemies(false)
		main.in_hill = false
		main.observatory_q = 6

	if want.call("obs_save"):
		# saved mid-ordeal: q, the four room dictionaries, the bits, the relay and the checkpoint come back; the room starts at its stair with Noeul at his post;
		# a fight cut short is cleared and the mirrors already set stay; old and odd saves are mended
		calm_enemies(true)
		await obs_prep(4, 3)
		var Z = main.observatory_zone
		var C = main.obs
		main.obs_bits = 7
		main.obs_ordeal = true
		main.obs_relay = 1
		main.obs_sec[3].record_read = true
		main.obs_sec[3].wind = true
		main.obs_sec[0].record_read = true
		main.obs_sec[0].fixed = true
		main.obs_sec[0].angle = 1
		main.obs_sec[0].mirror_dir = 0
		main.obs_sec[0].wind = true
		main.obs_check = 3
		Z.repair()
		Z.apply_state()
		reset_to(Vector2(C.origin(3) + 14.0, 8.0))
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var keys: bool = int(sd.get("observatory_q", -1)) == 4 and sd.get("observatory_section_state", []).size() == 4 and sd.has("observatory_core_bits") and sd.has("observatory_reward_claimed") and sd.has("observatory_checkpoint") and sd.has("observatory_top_tested") and bool(sd.get("observatory_ordeal_started", false)) and int(sd.get("observatory_relay_bits", -1)) == 1
		main.obs_sec = Z.fresh_sections()
		main.observatory_q = 0
		main.obs_bits = 0
		main.obs_relay = 0
		main.obs_ordeal = false
		main.load_game()
		await wait(0.4)
		main.close_story()
		var back: bool = main.in_observatory() and main.observatory_q == 4 and main.obs_ordeal and main.obs_relay == 1 and main.obs_bits == 7 and not main.obs_top_tested and main.obs_sec[3].dirs == [1, 2, 2] and Z.dark and main.obs_sec[0].fixed and C.gate_open[0]
		var at_stair: bool = Vector2(main.player.x, main.player.z).distance_to(C.at(3, "S") + Vector2(1, 0)) < 0.6
		var noeul_waits: bool = main.mate2_job.get("kind", "") == "obs_post" and Z.post_room == -1 and Vector2(main.mate2.position.x, main.mate2.position.z).distance_to(C.at(3, "P")) < 0.6
		await obs_press("P", 3)
		var repost: bool = Z.post_room == 3
		# the first group cut mid-fight: the mirror set before it stays, the bricks of the group go
		await obs_prep(4, 3)
		main.obs_bits = 1
		main.obs_sec[3].record_read = true
		main.obs_sec[3].wind = true
		Z.repair()
		Z.apply_state()
		for k in 3:
			await obs_press("R", 3, 1, Vector2(0.0, 0.9))
		var fighting: bool = Z.group_active == 1 and obs_foes().size() == 3
		main.save_game()
		main.obs_bits = 0
		main.load_game()
		await wait(0.4)
		main.close_story()
		var cut: bool = main.obs_bits == 1 and Z.group_active < 0 and obs_foes().is_empty() and Z.moth_alive() == null and main.obs_sec[3].dirs == [1, 2, 2]
		# old saves: no key is q0, or q6 when the save is already past the castle's door; odd values are mended; a present key is never migrated
		Z.load_data({})
		var old0: bool = main.observatory_q == 0 and main.obs_sec[0].fixed == false
		Z.load_data({"castle_q": 1})
		var old6: bool = main.observatory_q == 6 and main.obs_sec[2].fixed and main.obs_bits == 7 and main.obs_top_tested and main.obs_sec[3].dirs == [1, 1, 2] and main.obs_sec[3].sent
		Z.load_data({"observatory_q": 0, "castle_q": 3})
		var no_migrate: bool = main.observatory_q == 0
		Z.load_data({"observatory_q": 9, "observatory_section_state": [1, "x", {"angle": 5, "wind": true}], "observatory_core_bits": 5, "observatory_checkpoint": 9})
		var odd: bool = main.observatory_q == 6 and main.obs_check == 3 and main.obs_bits == 7
		Z.load_data({"observatory_q": 1, "observatory_section_state": [{"fixed": true, "angle": 1, "mirror_dir": 7, "wind": true}], "observatory_core_bits": 5})
		var mended: bool = main.observatory_q == 1 and main.obs_bits == 0 and not main.obs_sec[0].fixed and main.obs_sec[0].mirror_dir == 2 and main.obs_sec[0].angle == 1 and main.obs_sec[0].wind
		Z.load_data({"observatory_q": 5})
		var q5: bool = main.obs_reward and main.obs_bits == 7 and main.obs_top_tested and main.obs_sec[3].wind
		Z.load_data({"observatory_q": 4, "observatory_top_tested": true})
		var tested: bool = main.obs_ordeal and main.obs_relay == 7 and main.obs_bits == 7 and main.obs_sec[3].dirs == [1, 1, 2]
		Z.load_data({"observatory_q": 4, "observatory_ordeal_started": true})
		var ordeal_only: bool = main.obs_ordeal and main.obs_bits == 7 and main.obs_relay == 0 and not main.obs_top_tested and main.obs_sec[3].dirs == [2, 2, 2]
		check("obs_save", keys and back and at_stair and noeul_waits and repost and fighting and cut and old0 and old6 and no_migrate and odd and mended and q5 and tested and ordeal_only,
			"save keys=%s; reload mid-ordeal=%s at the stair=%s, Noeul at his post=%s, asked again=%s; group cut: fighting=%s, kept and bricks gone=%s; old save q0=%s, past the castle q6=%s, key present never migrated=%s; odd values=%s, mended=%s, q5 keeps the scale=%s; tested=%s, ordeal alone=%s" % [keys, back, at_stair, noeul_waits, repost, fighting, cut, old0, old6, no_migrate, odd, mended, q5, tested, ordeal_only])
		calm_enemies(false)
		main.in_hill = false
		Z.load_data({"observatory_q": 6})
		main.obs_check = 0

	if want.call("obs_gate"):
		# the castle gate: the sparrow mill, the moon trial and the observatory, each missing holds it; all three or a save already past it do not;
		# the quest line and the gold "!" lead the way in and back; the six tokens stay six
		main.close_story()
		var keep_s: Array = [main.mill_q, main.trial_won, main.observatory_q, main.castle_q, main.hill_q]
		main.castle_q = 0
		var truth := true
		var rows := ""
		for bits in 8:
			main.mill_q = 5 if (bits & 1) != 0 else 0
			main.trial_won = (bits & 2) != 0
			main.observatory_q = 6 if (bits & 4) != 0 else 0
			var want_hold: bool = bits != 7
			var held: bool = main.moon_tokens.holds("castle")
			truth = truth and held == want_hold
			rows += "%d%s " % [bits, "H" if held else "-"]
		main.mill_q = 5
		main.trial_won = true
		main.observatory_q = 0
		var miss: String = main.moon_tokens.missing("castle")
		main.mill_q = 0
		var miss_mill: String = main.moon_tokens.missing("castle")
		main.mill_q = 5
		main.trial_won = false
		var miss_trial: String = main.moon_tokens.missing("castle")
		main.mill_q = 0
		var miss_both: String = main.moon_tokens.missing("castle")
		var order: bool = miss == "observatory" and miss_mill == "mill" and miss_trial == "trial" and miss_both == "both"
		main.mill_q = 5
		main.trial_won = true
		main.castle_q = 1
		var past: bool = not main.moon_tokens.holds("castle") # a save already in the castle is never held again
		main.castle_q = 0
		# the held gate says the observatory line and the talk
		main.in_village = false
		main.in_hill = true
		main.hill_q = 3
		reset_to(main.hill.marks.X + Vector2(-0.3, 0))
		var pass1: bool = main.moon_tokens.gate("castle", main.hill.marks.X)
		var said: bool = (not pass1) and main.story_open and main.quest_raw == "성으로 가기 전에: 달맞이 관측원에서 바람 신호를 보내자"
		var story_ok: bool = main.STORY.GATE.has("castle_observatory") and main.STORY.GATE["castle_observatory"][0].begins_with("||언덕의 바람은 모였으나")
		main.close_story()
		var hold_line: bool = main.moon_tokens.hill_line() == "성으로 가기 전에: 달맞이 관측원에서 바람 신호를 보내자"
		var journal: bool = main.moon_tokens.gate_lines().any(func(l): return l.contains("달맞이 관측원") and l.contains("아직"))
		main.observatory_q = 6
		var pass2: bool = main.moon_tokens.gate("castle", main.hill.marks.X)
		journal = journal and not main.moon_tokens.gate_lines().any(func(l): return l.contains("달맞이 관측원"))
		var six: bool = main.tokens.size() == 6 and main.moon_tokens.STAIRS_NEED == 4 and main.moon_tokens.NAMES.size() == 6
		# the line and the "!" lead to the stair on the hill, through the floors, then home
		main.observatory_q = 0
		main.set_quest(main.moon_tokens.hill_line())
		reset_to(main.hill.marks.O + Vector2(-3.0, 2.0))
		var mark_o: Vector3 = main.quest_marks.quest_target()
		var lead: bool = absf(mark_o.x - main.hill.marks.O.x) < 0.01 and absf(mark_o.z - main.hill.marks.O.y) < 0.01
		await obs_prep(1, 0)
		var m0: Vector3 = main.quest_marks.quest_target()
		var at_h: bool = absf(m0.x - main.obs.at(0, "H").x) < 0.01
		await obs_prep(3, 0)
		var m1: Vector3 = main.quest_marks.quest_target()
		var at_n: bool = absf(m1.x - main.obs.at(0, "N").x) < 0.01 # the work is two floors on: the door N
		await obs_prep(6, 3)
		var m2: Vector3 = main.quest_marks.quest_target()
		var at_s: bool = absf(m2.x - main.obs.at(3, "S").x) < 0.01 and main.quest_raw != ""
		main.in_hill = false
		main.observatory_q = 6
		main.mill_q = keep_s[0]
		main.trial_won = keep_s[1]
		main.castle_q = keep_s[3]
		main.hill_q = keep_s[4]
		check("obs_gate", truth and order and past and said and story_ok and hold_line and pass2 and journal and six and lead and at_h and at_n and at_s,
			"castle gate table (bits mill/trial/observatory, H=held) %s=%s; missing order observatory/mill/trial/both=%s; past castle never held=%s; held says the line and the talk=%s/%s, line=%s; opens=%s; journal=%s; six tokens=%s; ! at O=%s, at note=%s, at door=%s, at stair=%s" % [rows, truth, order, past, said, story_ok, hold_line, pass2, journal, six, lead, at_h, at_n, at_s])

	if want.call("obs_round"):
		# a new round: the observatory starts again (nothing of it is kept), and the scale is not a token
		main.castle_q = 0
		main.observatory_q = 6
		main.obs_reward = true
		main.obs_bits = 7
		main.obs_top_tested = true
		main.obs_ordeal = true
		main.obs_relay = 7
		main.obs_sec[2].fixed = true
		main.write_new_round()
		var sd2 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var dropped: bool = not sd2.has("observatory_q") and not sd2.has("observatory_section_state") and not sd2.has("observatory_core_bits") and not sd2.has("observatory_reward_claimed") and not sd2.has("observatory_relay_bits") and not sd2.has("observatory_ordeal_started")
		main.observatory_zone.load_data(sd2)
		var fresh: bool = main.observatory_q == 0 and not main.obs_reward and main.obs_bits == 0 and main.obs_relay == 0 and not main.obs_ordeal and not main.obs_top_tested and not main.obs_sec[2].fixed and not main.obs.gate_open[0] and not main.obs.plat_open[0]
		check("obs_round", dropped and fresh, "new-round save has no observatory keys=%s; loading it starts at q0 with no scale, no ordeal and shut gates=%s" % [dropped, fresh])
		main.observatory_zone.load_data({"observatory_q": 6})
		main.return_to_start()

	if want.call("bag"):
		# the bag (Tab, v0.1.99; the owner, 2026-10-29: inventory command): a sheet of cards for equipment, keepsakes, what she
		# spends and the six tokens; Tab, Esc or its back key close it, the world waits while it is open, phones get a key
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.2)
		var keep := [main.has_armour, main.has_buckler, main.has_ring, main.has_oil, main.shop_bought[2], main.player.pots, main.tokens.duplicate()]
		main.has_armour = true
		main.has_buckler = true
		main.has_ring = true
		main.has_oil = true
		main.shop_bought[2] = 2
		main.player.pots = 3
		main.tokens = [true, false, true, false, false, false]
		tap(KEY_TAB)
		await wait(0.3)
		var opened: bool = main.ui.bag.visible and not main.ui.journal.visible and not main.ui.help.visible
		var t1: float = main.t
		await wait(0.5)
		var waits: bool = is_equal_approx(main.t, t1)
		var secs: Array = main.menus.bag_sections()
		var names_of := func(i: int) -> Array: return secs[i][1].map(func(e): return String(e.name))
		var gear: Array = names_of.call(0)
		var items: Array = names_of.call(1)
		var gear_ok: bool = gear.size() == 3 and "작은 놋 방패" in gear and "달지기 갑옷" in gear and gear[0].contains("2") and not ("작은 놋 방패" in items) and "수정 반지" in items and "왕관" in items
		var uses: Array = names_of.call(2)
		var use_ok: bool = uses.size() == 2 and "3" in uses[0] and String(secs[2][1][0].effect).contains("45")
		var toks: Array = secs[3][1]
		var tok_ok: bool = toks.size() == 6 and not toks[0].get("dim", false) and toks[1].get("dim", false) and String(secs[3][0]).ends_with("2/6")
		var shown: int = 0
		for g in main.ui.bag_box.get_children():
			if g is GridContainer:
				shown += g.get_child_count()
		var cards: bool = shown == gear.size() + items.size() + uses.size() + toks.size() and main.ui.bag_box.get_child_count() == 8
		var jl: Array = main.menus.journal_lines()
		var jl_keep: String = String(jl[jl.find(tr("지닌 것")) + 1])
		var same_names: bool = jl_keep.contains("수정 반지") and jl_keep.contains("작은 놋 방패") and jl_keep.contains("달지기 갑옷")
		var every: bool = main.menus.keepsakes().all(func(k): return String(k[1]) != "")
		tap(KEY_TAB)
		await wait(0.2)
		var tab_closes: bool = not main.ui.bag.visible
		tap(KEY_TAB)
		await wait(0.2)
		tap(KEY_ESCAPE)
		await wait(0.2)
		var esc_closes: bool = not main.ui.bag.visible and not main.settings_open
		tap(KEY_TAB)
		await wait(0.2)
		tap(KEY_Q)
		await wait(0.2)
		var swaps: bool = main.ui.journal.visible and not main.ui.bag.visible
		tap(KEY_TAB)
		await wait(0.2)
		var swaps_back: bool = main.ui.bag.visible and not main.ui.journal.visible
		(main.ui.bag.find_children("*", "Button", true, false)[0] as Button).pressed.emit() # the back key
		await wait(0.1)
		var back_closes: bool = not main.ui.bag.visible
		main.has_armour = keep[0]
		main.has_buckler = keep[1]
		main.has_ring = keep[2]
		main.has_oil = keep[3]
		main.shop_bought[2] = keep[4]
		main.player.pots = keep[5]
		main.tokens = keep[6]
		# phones: the bag key is the fifth key, left of the zoom coins with the same 8 px gap, level with the first row
		var root: Window = main.get_tree().root
		var scale0 := [root.content_scale_mode, root.content_scale_aspect, root.content_scale_size]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(960, 540)
		await wait(0.1)
		main.enable_touch()
		await wait(0.3)
		var hb: Rect2 = main.ui.hint.get_global_rect()
		var jb: Rect2 = main.ui.journal_btn.get_global_rect()
		var bb: Rect2 = main.ui.bag_btn.get_global_rect()
		var vs: Vector2 = main.get_viewport().get_visible_rect().size
		var zi: Array = main.touch_layer.keys()["zoom_in"]
		var key_ok: bool = main.ui.bag_btn.visible and bb.size == jb.size and absf(bb.end.x + 8.0 - (zi[0].x - zi[1])) < 0.5 and absf(bb.position.y - hb.position.y) < 0.5 			and Rect2(Vector2.ZERO, vs).encloses(bb) and not bb.intersects(main.ui.settings_btn.get_global_rect()) and not bb.intersects(main.ui.hint.get_global_rect()) and not bb.intersects(main.ui.mini.get_parent().get_global_rect()) and hb.size.x == 60.0
		main.ui.bag_btn.pressed.emit()
		await wait(0.2)
		var tap_opens: bool = main.ui.bag.visible
		main.menus.toggle_bag(false)
		main.disable_touch()
		root.content_scale_mode = scale0[0]
		root.content_scale_aspect = scale0[1]
		root.content_scale_size = scale0[2]
		await wait(0.2)
		check("bag", opened and waits and gear_ok and use_ok and tok_ok and cards and same_names and every and tab_closes and esc_closes and swaps and swaps_back and back_closes and key_ok and tap_opens,
			"Tab opens=%s world waits=%s gear cards=%s spend cards=%s token cards=%s all cards shown=%s journal lists the same names=%s every keepsake has an effect=%s Tab closes=%s Esc closes=%s Q swaps=%s Tab swaps back=%s back key=%s phone key beside the zoom coins with 8 px=%s (%s %s %s %s) key opens=%s" % [opened, waits, gear_ok, use_ok, tok_ok, cards, same_names, every, tab_closes, esc_closes, swaps, swaps_back, back_closes, key_ok, hb, jb, bb, vs, tap_opens])

	if want.call("refusal"):
		# the refusal of the call (v0.1.100; Hero's Journey stage 3): seven lines after the first WAKE, once, before the first lamp;
		# a load or a later story never plays it
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.2)
		var lines: Array = main.STORY.REFUSAL
		var faces_ok: bool = lines.size() == 7
		for l in lines:
			var parts: PackedStringArray = String(l).split("|", true, 2)
			if parts[0] == "소라":
				faces_ok = faces_ok and ResourceLoader.exists("res://art/ui/face_sora_%s.png" % parts[1])
		var step0: int = main.story_step
		var lamp0 = main.dark_lamp
		main.story_step = 0
		main.story.refusal_due = true
		main.show_story("res://art/story/01_wake.jpg", main.STORY.WAKE)
		var started := false
		for k in 400: # page the WAKE: each line types out before the 다음 button shows
			await wait(0.1)
			if plain(main.ui.story_text.text).contains("집에 가고 싶어"):
				started = main.story_open and main.story_step == 1
				break
			if not main.story_open:
				break
			if main.ui.story_text.visible_characters == -1 and main.ui.story_more.visible:
				main.story.next_story()
		await wait(0.9)
		started = started and main.ui.story.modulate.a > 0.5
		var said := 0
		for k in 600:
			if not main.story_open:
				break
			await wait(0.1)
			if main.ui.story_text.visible_characters == -1 and main.ui.story_more.visible:
				said += 1
				main.story.next_story()
				await wait(0.05)
		await wait(0.3)
		var seven: bool = said == 7
		var once: bool = not main.story_open and not main.story.refusal_due and main.story_step == 1
		# a story closing later (or a load: story_step 1, flag off) does not play it again
		main.show_story("", ["||그저 한 줄."])
		main.close_story()
		await wait(0.5)
		var not_again: bool = not main.story_open
		main.story_step = 1
		main.save_game()
		main.load_game()
		await wait(0.5)
		var not_on_load: bool = not main.story_open and not main.story.refusal_due
		main.story_step = step0
		main.dark_lamp = lamp0
		check("refusal", faces_ok and started and seven and once and not_again and not_on_load,
			"7 lines with existing faces=%s opens after the WAKE at step 1=%s paged %d lines=%s closes once=%s later story no repeat=%s a load no repeat=%s" % [faces_ok, started, said, seven, once, not_again, not_on_load])

	if want.call("stairs_fx"):
		# the moon stairs' lovely things (v0.1.101): steps she stood on keep a pale blue edge, paper lanterns and petals run only
		# on the stairs, a big moon behind the top door, chimes ring once as she comes by
		if main.intro:
			main.start_game(false)
		main.close_story()
		main.castle_q = 3
		main.enter_stairs()
		main.close_story()
		main.stairs.open_wall()
		var sx: int = main.STAIRS.STAIRS_X
		var n0: int = main.stairs.lit_tiles.size()
		var top_new: int = 0 if main.stairs.lit_tiles.has(Vector2i(sx + 12, 6)) else 1 # an earlier test may have climbed past it
		for tile in [Vector2(8, 20), Vector2(9, 20), Vector2(9, 19)]:
			reset_to(Vector2(sx + tile.x, tile.y))
			await wait(0.15)
		var lit3: bool = main.stairs.lit_tiles.size() == n0 + 3 and main.stairs.lit_tiles.has(Vector2i(sx + 9, 19))
		reset_to(Vector2(sx + 9, 19))
		await wait(0.15)
		var no_dup: bool = main.stairs.lit_tiles.size() == n0 + 3 # the same step twice lights one edge
		reset_to(Vector2(sx + 12, 6)) # far up the climb, on a plain step: the earlier edges stay
		await wait(0.2)
		var stays: bool = (main.stairs.lit_tiles[Vector2i(sx + 8, 20)] as MeshInstance3D).transparency < 0.05 and main.stairs.lit_tiles.size() == n0 + 3 + top_new and main.stairs.lit_tiles.has(Vector2i(sx + 12, 6))
		var e: MeshInstance3D = main.stairs.lit_tiles[Vector2i(sx + 8, 20)]
		var flat: bool = absf(e.position.y - 0.015) < 0.001 and (e.mesh as PlaneMesh).size.x < 1.0
		var water: bool = main.stairs.lit_tiles.has(Vector2i(sx + 9, 17)) == false # the channel is not a step
		var on: bool = main.stairs.lantern_fx.size() == 2 and main.stairs.lantern_fx.all(func(p): return p.emitting) and main.stairs.petal_fx.emitting
		var moon: bool = main.stairs.moon_disc != null and main.stairs.moon_disc.position.z < 0.0 and main.stairs.moon_disc.position.y > 3.0 \
			and main.stairs.moon_disc.texture.get_width() * main.stairs.moon_disc.pixel_size >= 8.0
		# the chimes: a post at (sx + 2.8, 17); she comes by, it rings once; she stays, no more; she goes off and returns, again
		var posts: bool = main.stairs.chimes.size() == 6
		var r0: int = main.stairs.chime_rings
		reset_to(Vector2(sx + 5.0, 17.0))
		await wait(0.2)
		var rang: bool = main.stairs.chime_rings == r0 + 1
		await wait(0.3)
		var once: bool = main.stairs.chime_rings == r0 + 1
		var swing: bool = (main.stairs.chimes[1].hang as Node3D).rotation.length() > 0.0
		reset_to(Vector2(sx + 11.0, 17.0))
		await wait(0.2)
		reset_to(Vector2(sx + 5.0, 17.0))
		await wait(0.2)
		var again: bool = main.stairs.chime_rings >= r0 + 2
		# off the stairs the particles stop
		main.castle_zone.leave_stairs()
		await wait(0.3)
		var off: bool = not main.stairs.lantern_fx.any(func(p): return p.emitting) and not main.stairs.petal_fx.emitting
		check("stairs_fx", lit3 and no_dup and stays and flat and water and on and moon and posts and rang and once and swing and again and off,
			"three new steps lit=%s no double=%s earlier edge stays lit=%s flat on the step=%s water not lit=%s lanterns and petals on=%s big moon behind the door=%s 6 chime posts=%s rings on coming by=%s only once=%s rods swing=%s rings again=%s particles off away=%s" % [lit3, no_dup, stays, flat, water, on, moon, posts, rang, once, swing, again, off])
		main.return_to_start()

	if want.call("lake_stair"):
		# the lake's stair to the water corridor (v0.1.102): a name floats over it like the forest exits, and six treads go darker
		# and lower so it reads as steps going down
		var lab: Label3D = main.corridor_zone.lake_label
		var stair: Node3D = lab.get_parent() as Node3D
		var vmark: Vector2 = main.lake.marks.V
		var named: bool = lab.text == "물길 회랑" and lab.billboard == BaseMaterial3D.BILLBOARD_ENABLED and lab.font_size >= 40
		var placed: bool = Vector2(stair.position.x, stair.position.z).distance_to(vmark) < 0.01 and lab.global_position.y > 1.5
		var treads: Array = []
		for c in stair.get_children():
			if c is MeshInstance3D and c.mesh is BoxMesh and absf((c.mesh as BoxMesh).size.x - 1.4) < 0.01 and absf((c.mesh as BoxMesh).size.y - 0.07) < 0.01:
				treads.append(c)
		var six: bool = treads.size() == 6
		var lower := true
		var darker := true
		for i in range(1, treads.size()):
			lower = lower and treads[i].position.y < treads[i - 1].position.y and treads[i].position.z < treads[i - 1].position.z
			darker = darker and ((treads[i].material_override.albedo_color as Color).v < (treads[i - 1].material_override.albedo_color as Color).v)
		check("lake_stair", named and placed and six and lower and darker,
			"name over the stair=%s on the lake's V mark=%s six treads=%s each lower and further=%s each darker=%s" % [named, placed, six, lower, darker])

	if want.call("picture_hud"):
		# a big story picture hides the companions' rows (v0.1.103; the owner: they were drawn on top of the picture) and nothing
		# else sits above it but the story's own parts and the fade and the title
		if main.intro:
			main.start_game(false)
		main.close_story()
		await wait(0.2)
		var rows: Array = main.ui.mate_rows
		var node0 = main.mate
		var node1 = main.mate2
		main.join_mate()
		main.join_noeul()
		await wait(0.3)
		var shown_before: bool = rows[0].row.visible and rows[1].row.visible
		main.show_story("res://art/story/01_wake.jpg", ["||그림이 떠 있다."])
		await wait(0.8)
		var hidden: bool = not rows[0].row.visible and not rows[1].row.visible
		var root: Control = main.ui.root
		var above: Array = []
		var after_story := false
		for c in root.get_children():
			if c == main.ui.story:
				after_story = true
			elif after_story and c is CanvasItem and c.visible and c.modulate.a > 0.0 and c != main.ui.title:
				above.append(c.name)
		var clean: bool = above.is_empty()
		main.close_story()
		await wait(1.0)
		var back: bool = rows[0].row.visible and rows[1].row.visible
		# a small corner picture (the old painting) and a talk-only story keep the rows
		main.show_story("res://art/story/01_wake.jpg", ["||작은 그림."], true)
		await wait(0.6)
		var small_keeps: bool = rows[0].row.visible
		main.close_story()
		await wait(0.6)
		main.show_story("", ["||그림 없는 이야기."])
		await wait(0.6)
		var talk_keeps: bool = rows[0].row.visible
		main.close_story()
		if node0 == null:
			main.mates.leave_mate()
		if node1 == null:
			main.mate2.queue_free()
			main.mate2 = null
		check("picture_hud", shown_before and hidden and clean and back and small_keeps and talk_keeps,
			"rows on before=%s hidden under the big picture=%s nothing else above it (%s)=%s back after=%s small picture keeps them=%s a talk story keeps them=%s" % [shown_before, hidden, above, clean, back, small_keeps, talk_keeps])

	# ---- v0.1.104: small delights from shots/plans/delight100.md (ideas 47, 61, 29, 56, 31, 45, 93, 12, 76, 62, 78, 3)
	if want.call("toy_taps"):
		# a rolling toy brick taps the ground three times as it lands, each tap smaller and lower (idea 47)
		var bs2: Array = main.village.toy_bricks
		var ok2 := false
		var info2 := "no toy bricks"
		if not bs2.is_empty():
			var b2: MeshInstance3D = bs2[0]
			for i in mini(4, bs2.size()): # toy_bricks scattered the pile just before: gather four back so they are all in reach
				(bs2[i] as MeshInstance3D).position = b2.position + Vector3(0.15 * (i % 2), 0.0, 0.15 * (i / 2))
			var px2: float = main.player.x
			var pz2: float = main.player.z
			main.player.x = b2.position.x - 0.8
			main.player.z = b2.position.z
			var r2: int = main.village.toy_rolls
			var t2: int = main.village.toy_taps
			main.village.bricks_hit(main, 1.4, Vector2(1, 0), 0.3, true)
			await wait(1.8)
			var rolled: int = main.village.toy_rolls - r2
			var taps: int = main.village.toy_taps - t2
			var tp: Array = main.village.TOY_TAPS
			var falling: bool = tp.size() == 3 and tp[0][0] > tp[1][0] and tp[1][0] > tp[2][0] and tp[0][1] > tp[1][1] and tp[1][1] > tp[2][1]
			ok2 = rolled >= 3 and taps == rolled * 3 and falling and main.village.toy_tap_last == 2
			info2 = "%d bricks rolled, %d taps (3 each)=%s, each tap lower and softer=%s" % [rolled, taps, taps == rolled * 3, falling]
			main.player.x = px2
			main.player.z = pz2
		check("toy_taps", ok2, info2)
	if want.call("idle_places"):
		# the act she picks after waiting: tea once a visit at Bori's cottage, her pinwheel beside a turning small windmill (ideas 61, 62)
		main.in_village = false
		main.in_hill = false
		var in_m: bool = main.in_marsh()
		var s: Object = main.sora
		s.tea_visit = false
		s.wheel_visit = false
		var a0: int = s.place_acts
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z + 1.2))
		var first: String = s.idle_pick()
		var second_n: int = s.place_acts
		s.idle_pick()
		var once_tea: bool = first == "rest-tea" and second_n == a0 + 1 and s.place_acts == a0 + 1
		reset_to(Vector2(20, 30))
		s.idle_pick() # away: the visit is over
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z + 1.2))
		var again: String = s.idle_pick()
		var tea_again: bool = again == "rest-tea" and s.place_acts == a0 + 2
		var was_turning: bool = main.hill.mills[0].turning
		main.in_hill = true
		main.hill.mills[0].turning = true
		var mp: Vector2 = main.hill.mills[0].pos
		reset_to(mp + Vector2(1.5, 0))
		var wheel: String = s.idle_pick()
		var wheel_ok: bool = wheel == "rest-pinwheel" and s.place_acts == a0 + 3
		s.idle_pick()
		var wheel_once: bool = s.place_acts == a0 + 3
		main.hill.mills[0].turning = false # a stopped mill brings no wheel out
		reset_to(mp + Vector2(40, 0))
		s.idle_pick()
		reset_to(mp + Vector2(1.5, 0))
		s.idle_pick()
		var stopped: bool = s.place_acts == a0 + 3
		main.hill.mills[0].turning = was_turning
		main.in_hill = false
		var files: bool = ResourceLoader.exists("res://art/sora/px96/rest-tea.png") and ResourceLoader.exists("res://art/sora/px96/rest-pinwheel.png")
		check("idle_places", in_m and once_tea and tea_again and wheel_ok and wheel_once and stopped and files,
			"tea once at Bori's=%s again on a new visit=%s pinwheel at a turning mill=%s once=%s none at a stopped mill=%s pictures exist=%s" % [once_tea, tea_again, wheel_ok, wheel_once, stopped, files])
	if want.call("folk_nod"):
		# a villager who waited for Sora nods once when the way is clear; a brush past brings no nod (idea 29)
		var id := "doran"
		var f: Object = main.folk
		var rs: Dictionary = f.folk_route_state(id)
		rs.i = 1
		rs.pos = f.route_at(id, 0)
		rs.wait = 0.0
		rs.back = false
		rs.stalled = 0.0
		var dir: Vector2 = (f.route_at(id, 1) - rs.pos).normalized()
		var spot: Vector2 = rs.pos + dir * 0.5
		reset_to(spot)
		var n0: int = f.folk_nods
		for k in 12:
			f.route_update(id, 0.1, false, 1.4)
		var waiting: bool = f.folk_nods == n0 and rs.stalled > 1.1 and rs.pos.distance_to(f.route_at(id, 0)) < 0.01
		reset_to(spot + Vector2(5, 5))
		f.route_update(id, 0.1, false, 1.4)
		var nodded: bool = f.folk_nods == n0 + 1 and f.nod_t.get("folk_" + id, 0.0) > 0.0
		f.route_update(id, 0.1, false, 1.4)
		var only_once: bool = f.folk_nods == n0 + 1
		var spr: Sprite3D = main.village.folk_node[id]
		for k in 4:
			f.hop("folk_" + id, spr, 0.15)
		var settled: bool = f.nod_t.get("folk_" + id, 0.0) <= 0.0
		rs.pos = f.route_at(id, 0)
		reset_to(spot) # a brush past: 0.3 s
		for k in 3:
			f.route_update(id, 0.1, false, 1.4)
		reset_to(spot + Vector2(5, 5))
		f.route_update(id, 0.1, false, 1.4)
		var brush: bool = f.folk_nods == n0 + 1
		f.route_reset(id)
		check("folk_nod", waiting and nodded and only_once and settled and brush,
			"stood in his way 1.2 s, no nod yet=%s nod when the way is clear=%s only one=%s the dip ends=%s a brush past gives none=%s" % [waiting, nodded, only_once, settled, brush])
	if want.call("potion_kept"):
		# the potion button at full strength keeps the bottle (idea 56)
		var pots0: int = main.player.pots
		var hp0b: float = main.player.hp
		var oil0: bool = main.has_oil
		var mp0: float = main.player.mp
		main.has_oil = false
		main.player.pots = 3
		main.player.hp = float(main.player.max_hp)
		main.player.cds[3] = 0.0
		var k0: int = main.combat.potion_kept
		main.drink_potion()
		var kept: bool = main.player.pots == 3 and main.combat.potion_kept == k0 + 1
		main.player.cds[3] = 0.0
		main.player.hp = float(main.player.max_hp) - 30.0
		main.drink_potion()
		var drunk: bool = main.player.pots == 2 and main.player.hp > float(main.player.max_hp) - 30.0
		main.has_oil = true # the oil bottle's mana counts: low mana makes a drink worth it
		main.player.cds[3] = 0.0
		main.player.hp = float(main.player.max_hp)
		main.player.mp = 10.0
		main.drink_potion()
		var oil_drinks: bool = main.player.pots == 1
		main.player.cds[3] = 0.0
		main.player.hp = float(main.player.max_hp)
		main.player.mp = float(main.player.max_mp)
		main.drink_potion()
		var oil_kept: bool = main.player.pots == 1
		main.player.cds[3] = 0.0
		main.player.pots = 0
		main.drink_potion()
		var none: bool = main.player.pots == 0
		main.player.pots = pots0
		main.player.hp = hp0b
		main.player.mp = mp0
		main.has_oil = oil0
		main.player.cds[3] = 0.0
		check("potion_kept", kept and drunk and oil_drinks and oil_kept and none,
			"full strength keeps the bottle=%s hurt drinks=%s full HP but low mana drinks with the oil=%s all full keeps=%s no potion left still says so=%s" % [kept, drunk, oil_drinks, oil_kept, none])
	if want.call("eave_drips"):
		# after the rain stops a few drops fall from the eaves near her, one by one, and stop (idea 31)
		main.in_village = true
		main.in_house = -1
		main.raining = false
		main.rain.emitting = false
		var d0: Vector2 = main.village.doors[0]
		reset_to(d0 + Vector2(0, 0.6))
		var near: int = main.effects.eave_points().filter(func(p): return Vector2(p.x - d0.x, p.z - d0.y).length() < 16.0).size()
		var want_drops: int = 3 * mini(6, near)
		var n1: int = main.effects.eave_drips
		tap(KEY_R) # rain on: no drips
		await wait(0.2)
		var rain_on: bool = main.raining
		var quiet: bool = main.effects.eave_drips == n1
		tap(KEY_R) # rain off: the eaves drip
		await wait(0.3)
		var off: bool = not main.raining
		await wait(6.5)
		var made: int = main.effects.eave_drips - n1
		check("eave_drips", rain_on and quiet and off and made == want_drops and made >= 6,
			"rain on makes no drip=%s rain stops=%s drops %d of %d (3 for each of %d eaves near her, six at most)" % [quiet, off, made, want_drops, mini(6, near)])
		main.in_village = false
	if want.call("full_chime"):
		# the moon light filling by rest leaves a low soft tone after the last blip; the earlier blips do not (idea 45)
		calm_enemies(true)
		for e in main.enemies:
			if e.get("cave", false) and not e.get("mole", false):
				e.x = 2.0
				e.z = 2.0
		for e in main.enemies.filter(func(e): return e.get("moth", false)):
			e.dead = true
			e.hp = 0.0
			e.respawn = 9999.0
		main.hour = 23.0
		var lamp2 = main.lanterns.filter(func(l): return l.position.x > 130.0 and not l.get_meta("dark", false))[0]
		reset_to(Vector2(lamp2.position.x + 0.4, lamp2.position.z + 1.0))
		main.crown_pips = 0
		main.rest_t = 100.0
		var c0: int = main.hud_build.full_chimes
		await wait(0.4)
		var blip_only: bool = main.crown_pips >= 1 and main.hud_build.full_chimes == c0 and main.crown_pips < main.pip_max
		main.crown_pips = main.pip_max - 1
		main.rest_t = 100.0
		main.sfx_log.clear()
		await wait(0.6)
		var filled: bool = main.crown_pips == main.pip_max and main.hud_build.full_chimes == c0 + 1
		var low_tone: bool = main.sfx_log.has("sine:330") and main.sfx_log.has("sine:880")
		calm_enemies(false)
		check("full_chime", blip_only and filled and low_tone, "an ordinary blip has no chime=%s the last one chimes once=%s with the low 330 Hz tone after the 880 Hz blip=%s" % [blip_only, filled, low_tone])
	if want.call("run_hold"):
		# the stick's run does not flicker at the rim: it starts at 0.92 and holds until 0.84 (idea 93)
		var T: GDScript = load("res://touch.gd")
		var seq := [0.5, 0.9, 0.93, 0.9, 0.88, 0.93, 0.86, 0.9, 0.8, 0.7]
		var run := false
		var changes := 0
		var old := false
		var old_changes := 0
		for v in seq:
			var nr: bool = T.run_state(v, run)
			if nr != run:
				changes += 1
			run = nr
			var no: bool = v >= 0.92
			if no != old:
				old_changes += 1
			old = no
		var steady: bool = changes == 2 and old_changes == 4 and T.run_state(0.9, false) == false and T.run_state(0.9, true) == true and T.run_state(0.83, true) == false
		# the same through real finger events
		var root2: Window = main.get_tree().root
		var sc2 := [root2.content_scale_mode, root2.content_scale_aspect, root2.content_scale_size]
		root2.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root2.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root2.content_scale_size = Vector2i(960, 540)
		await wait(0.1)
		main.enable_touch()
		await wait(0.3)
		var tl: Control = main.touch_layer
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = Vector2(150, 400)
		tl._input(down)
		var shifts: Array = []
		for v in seq:
			var dr := InputEventScreenDrag.new()
			dr.index = 0
			dr.position = Vector2(150, 400) + Vector2(tl.PAD_R * v, 0)
			tl._input(dr)
			shifts.append(main.touch_keys.has(KEY_SHIFT))
		var flips := 0
		for i in range(1, shifts.size()):
			if shifts[i] != shifts[i - 1]:
				flips += 1
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = Vector2(150, 400)
		tl._input(up)
		main.disable_touch()
		root2.content_scale_mode = sc2[0]
		root2.content_scale_aspect = sc2[1]
		root2.content_scale_size = sc2[2]
		await wait(0.1)
		check("run_hold", steady and flips == 2, "state changes over a wobbling thumb %d (the single threshold changed %d)=%s, through finger events %d flips=%s" % [changes, old_changes, steady, flips, flips == 2])
	if want.call("boss_intro"):
		# the Brick King's page: not at 13.5 tiles, once at 12, the world waits under it, never again, kept in the save and
		# across rounds. A full run has already felled him, so a stand-in is called up and put away again.
		main.close_story()
		var was_v2: bool = main.in_village
		main.in_village = false
		calm_enemies(true)
		main.boss_intro_off = false
		main.boss_seen = []
		var alive: Callable = func(e): return e.get("boss", false) and not e.dead
		var stand_in: bool = main.enemies.filter(alive).is_empty()
		if stand_in:
			main.monsters.spawn_boss()
		var bk: Dictionary = main.enemies.filter(alive)[0]
		var home: Vector2 = Vector2(bk.x, bk.z)
		reset_to(home + Vector2(0, 13.5))
		await wait(0.3)
		var far_shut: bool = not main.story_open
		reset_to(home + Vector2(0, 12.0))
		await wait(0.3)
		var opened: bool = main.story_open and main.ui.story_who.text == "벽돌왕" and main.ui.story_img.texture != null and main.ui.story_text.text.count("
") == 2
		var moved0: float = bk.x + bk.z
		await wait(0.5)
		var held: bool = bk.x + bk.z == moved0
		main.ui.story_text.visible_characters = -1
		main.story.next_story()
		await wait(0.3)
		var one_page: bool = not main.story_open
		var seen: bool = "brick_king" in main.boss_seen
		reset_to(home + Vector2(0, 13.5))
		await wait(0.2)
		reset_to(home + Vector2(0, 12.0))
		await wait(0.3)
		var not_twice: bool = not main.story_open
		main.save_game()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = "brick_king" in sd.get("boss_seen", []) and "boss_seen" in main.errands.NG_KEEP
		main.boss_intro_off = true
		if stand_in:
			bk.dead = true
			bk.node.visible = false
			bk.shadow.visible = false
		calm_enemies(false)
		main.in_village = was_v2
		check("boss_intro", far_shut and opened and held and one_page and seen and not_twice and kept,
			"shut at 13.5 tiles %s, page at 12 %s, world held %s, one page %s, marked %s, not twice %s, kept %s" % [far_shut, opened, held, one_page, seen, not_twice, kept])
	if want.call("sign_read"):
		# E beside the east signpost says where it points, in the marsh only; nothing beyond its reach
		main.close_story()
		var was_v: bool = main.in_village
		main.in_village = false
		var sa: Vector2 = main.hud_build.SIGN_AT
		main.toast_t = 0.0
		main.ui.toast.text = ""
		reset_to(sa + Vector2(0, 2.6))
		main.crown_key()
		var far_quiet: bool = not "표지판" in main.ui.toast.text
		main.close_story()
		reset_to(sa + Vector2(0, 0.8))
		main.crown_key()
		var says: bool = "등불 마을로 가는 표지판" in main.ui.toast.text and not main.story_open
		reset_to(sa + Vector2(0, 2.6))
		main.in_village = was_v
		check("sign_read", far_quiet and says, "out of reach quiet %s, beside it says the village %s (%s)" % [far_quiet, says, main.ui.toast.text])
	if want.call("foe_pace"):
		# a field foe's wait between blows runs at twice the clock; a boss's own clock is left alone
		main.close_story()
		var fp: Array = main.enemies.filter(func(e): return not e.dead and not e.get("boss", false) and not e.get("mole", false) and not e.get("prop", false) and not e.get("mold", false) and is_instance_valid(e.node) and e.node.visible)
		var ratio := 0.0
		if not fp.is_empty():
			var fe: Dictionary = fp[0]
			fe.atk_cd = 50.0
			var t0: float = fe.t
			await wait(0.6)
			ratio = (50.0 - fe.atk_cd) / maxf(fe.t - t0, 0.001)
		check("foe_pace", absf(ratio - 2.0) < 0.05, "foes %d, atk_cd falls %.2f s per second of the foe's clock" % [fp.size(), ratio])
	if want.call("sign_tease"):
		# reading the same sign three times in a row makes Noeul offer to memorise it, once for each sign (idea 12)
		main.join_noeul()
		var ch: Object = main.chatter
		ch.sign_looks.clear()
		ch.sign_teased.clear()
		var si: int = main.sign_spots.find(Vector2(43.6, 18.6)) # the signpost by the east bridge
		var sp: Vector2 = main.sign_spots[si]
		reset_to(sp + Vector2(0, 0.8))
		var tz0: int = ch.sign_teases
		var b0: int = main.bubbles_said
		main.crown_key() # the real key counts as a look
		await wait(0.1)
		main.close_story() # after other tests the same key may also open a talk; the count is what this test is about
		await wait(0.2)
		b0 = main.bubbles_said # that talk may have said a bubble of its own
		var counted: bool = ch.sign_looks.has(si) and ch.sign_looks[si][0] == 1
		ch.sign_look()
		var before: bool = ch.sign_teases == tz0
		ch.sign_look()
		var teased: bool = ch.sign_teases == tz0 + 1 and main.bubbles_said == b0 + 1
		ch.sign_look()
		ch.sign_look()
		var once_only: bool = ch.sign_teases == tz0 + 1
		var gap_ok := true # a long pause starts the count again
		ch.sign_teased.clear()
		ch.sign_looks[si] = [2, main.t - 100.0]
		ch.sign_look()
		gap_ok = ch.sign_looks[si][0] == 1 and ch.sign_teases == tz0 + 1
		var sp2: Vector2 = main.sign_spots[1 if si == 0 else 0] # another sign has its own count
		reset_to(sp2 + Vector2(0, 0.5))
		for k in 3:
			ch.sign_look()
		var second: bool = ch.sign_teases == tz0 + 2
		var alone := true # without Noeul nobody teases
		var mate2_keep = main.mate2
		main.mate2 = null
		ch.sign_teased.clear()
		ch.sign_looks.clear()
		for k in 3:
			ch.sign_look()
		alone = ch.sign_teases == tz0 + 2
		main.mate2 = mate2_keep
		var spots: bool = main.sign_spots.size() >= 5 # the signpost, three stalls and the inn
		check("sign_tease", counted and before and teased and once_only and gap_ok and second and alone and spots,
			"E at the signpost counts=%s quiet before the third=%s Noeul teases on the third=%s once=%s a long pause resets=%s a second sign has its own count=%s no tease without Noeul=%s 5 sign spots=%s" % [counted, before, teased, once_only, gap_ok, second, alone, spots])
	if want.call("doodles"):
		# Kongal's chalk figures: the crowned one after his kid goblin is home, the otter once Mulgyeol is known (idea 76)
		var v2: Object = main.village
		park_mates(true)
		var kid0: int = main.kid_q
		var mul0: int = main.mul_q
		main.kid_q = 0
		main.mul_q = 0
		v2.life_update(main, 0.0)
		var none2: bool = not v2.doodle_crown.visible and not v2.doodle_otter.visible
		main.kid_q = 3
		v2.life_update(main, 0.0)
		var crown_only: bool = v2.doodle_crown.visible and not v2.doodle_otter.visible
		main.mul_q = 1
		v2.life_update(main, 0.0)
		var both: bool = v2.doodle_crown.visible and v2.doodle_otter.visible
		main.kid_q = 0
		v2.life_update(main, 0.0)
		var otter_only: bool = not v2.doodle_crown.visible and v2.doodle_otter.visible
		var chalk := [0, 0]
		for i in 2:
			var img: Image = v2.doodle_tex(["crown", "otter"][i]).get_image()
			for y in img.get_height():
				for x in img.get_width():
					if img.get_pixel(x, y).a > 0.3:
						chalk[i] += 1
		var drawn: bool = chalk[0] > 80 and chalk[1] > 80
		var k2: Vector2 = v2.folk_pos["kongal"]
		var near_k: bool = Vector2(v2.doodle_crown.position.x, v2.doodle_crown.position.z).distance_to(k2) < 5.0 and Vector2(v2.doodle_otter.position.x, v2.doodle_otter.position.z).distance_to(k2) < 5.0 and v2.doodle_crown.position.y < 0.05
		main.kid_q = kid0
		main.mul_q = mul0
		park_mates(false)
		check("doodles", none2 and crown_only and both and otter_only and drawn and near_k,
			"nothing at the start=%s crown after the rescue=%s both once Mulgyeol is known=%s otter alone=%s chalk pixels %s=%s flat by Kongal=%s" % [none2, crown_only, both, otter_only, chalk, drawn, near_k])
	if want.call("pinwheels"):
		# four small village pinwheels turn with the hill's windmills: the first three with the small ones, the fourth with the big one (idea 78)
		var v3: Object = main.village
		var mills0: Array = main.hill.mills.map(func(mm): return mm.turning)
		var mq0: int = main.mill_q
		for mm in main.hill.mills:
			mm.turning = false
		main.mill_q = 0
		var rot0: Array = v3.pinwheels.map(func(p): return p.hub.rotation.z)
		v3.life_update(main, 0.5)
		var still: bool = v3.pinwheels.size() == 4 and v3.pinwheels.all(func(p): return not p.turning) and absf(v3.pinwheels[0].hub.rotation.z - rot0[0]) < 0.0001
		main.hill.mills[1].turning = true
		var r1: float = v3.pinwheels[1].hub.rotation.z
		var r0b: float = v3.pinwheels[0].hub.rotation.z
		v3.life_update(main, 0.5)
		var second_only: bool = absf(v3.pinwheels[1].hub.rotation.z - r1) > 0.5 and absf(v3.pinwheels[0].hub.rotation.z - r0b) < 0.0001 and not v3.pinwheels[3].turning
		main.mill_q = 3
		var r3: float = v3.pinwheels[3].hub.rotation.z
		v3.life_update(main, 0.5)
		var big: bool = absf(v3.pinwheels[3].hub.rotation.z - r3) > 0.5
		var open_ground := true # each stands on open ground, clear of walls
		for t in v3.PINWHEEL_TILES:
			open_ground = open_ground and not v3.blocked(v3.VILLAGE_X + t.x, t.y)
		for i in main.hill.mills.size():
			main.hill.mills[i].turning = mills0[i]
		main.mill_q = mq0
		check("pinwheels", still and second_only and big and open_ground,
			"all still while the windmills are stopped=%s only the second turns with the second windmill=%s the fourth with the big one=%s on open ground=%s" % [still, second_only, big, open_ground])
	if want.call("door_bell"):
		# the doorway bell inside a house rings a beat after she steps in, swinging twice, with its small sound at the end (idea 3)
		main.in_village = true
		main.in_house = -1
		reset_to(main.village.doors[0] + Vector2(0, 0.4))
		var f2: Object = main.folk
		var br0: int = f2.bell_rings
		main.sfx_log.clear()
		main.enter_house(0)
		var t_in: float = main.t
		var early: bool = f2.bell_rings == br0
		var peak := 0.0
		var first_at := -1.0
		for k in 30:
			await wait(0.05)
			peak = maxf(peak, absf(f2.bell.rotation.z))
			if first_at < 0.0 and f2.bell_rings > br0:
				first_at = k * 0.05
		await wait(0.9)
		var rang: bool = f2.bell_rings == br0 + 1 and first_at >= 0.3 and peak > 0.3 and absf(f2.bell.rotation.z) < 0.05
		var tone: bool = main.sfx_log.has("sine:1760")
		var swings: bool = f2.bell.get_parent() != null and f2.bell.position.y > 1.5
		main.leave_house() # a quick way out before the beat: no ring
		var br1: int = f2.bell_rings
		main.enter_house(1)
		main.leave_house()
		await wait(1.0)
		var skipped: bool = f2.bell_rings == br1
		main.in_village = false
		check("door_bell", early and rang and tone and swings and skipped,
			"no ring at the moment she steps in=%s rings later (%.2f s) and swings=%s the small sound at the end=%s hangs over the doorway=%s no ring if she left first=%s" % [early, first_at, rang, tone, swings, skipped])

	if want.call("marsh_duck"):
		# the wind-up duck (v0.1.106): E at the crank on the NW pond's south bank winds it, it swims one circle in 6 s, then
		# nothing answers for 3 s; never during a story, a fight, or before the crown has been touched
		marsh_world()
		var mt: Object = main.marsh_toys
		var h: Vector2 = mt.duck_handle
		var rest_at: Vector2 = mt.POND + Vector2.from_angle(mt.duck_a0) * mt.DUCK_R
		var on_ground: bool = mt.duck != null and h.x >= 0.0 and marsh_ground_ok(h) and h.distance_to(mt.POND) > 3.3 and main.tile_at(rest_at.x, rest_at.y) == main.WATER
		var runs0: int = mt.duck_runs
		reset_to(h)
		main.show_story("", ["||test"])
		tap(KEY_E)
		await wait(0.2)
		var quiet_story: bool = mt.duck_runs == runs0 and mt.hint() == ""
		main.close_story()
		var foe_set: bool = marsh_foe(h + Vector2(2.0, 0.0))
		tap(KEY_E)
		await wait(0.2)
		var quiet_fight: bool = foe_set and mt.duck_runs == runs0 and not mt.usable()
		calm_enemies(true)
		main.story_step = 1
		tap(KEY_E)
		await wait(0.2)
		var quiet_early: bool = mt.duck_runs == runs0
		main.close_story() # E at step 1 touches the crown
		main.story_step = 3
		reset_to(h)
		await wait(0.2)
		var hint_shown: bool = mt.hint() != "" and main.ui.shop_hint.visible and plain(main.ui.shop_hint.text) == mt.hint()
		main.sfx_log.clear()
		var t0: float = main.t
		tap(KEY_E)
		await wait(0.4)
		var clicks: int = main.sfx_log.filter(func(s): return s in ["square:1100", "square:1190", "square:1280"]).size()
		var started: bool = mt.duck_state == "run" and mt.duck_runs == runs0 + 1
		await wait_for(func(): return mt.duck_t >= 3.0, 5.0)
		var mid: Vector3 = mt.duck.position
		var across: float = Vector2(mid.x, mid.z).distance_to(rest_at)
		tap(KEY_E)
		await wait(0.1)
		var busy_ignored: bool = mt.duck_runs == runs0 + 1
		await wait_for(func(): return mt.duck_state == "cool", 6.0)
		var loop_s: float = main.t - t0
		var t_cool: float = main.t
		var home: float = Vector2(mt.duck.position.x, mt.duck.position.z).distance_to(rest_at)
		tap(KEY_E)
		await wait(0.1)
		var cool_ignored: bool = mt.duck_runs == runs0 + 1 and mt.duck_state == "cool"
		await wait_for(func(): return mt.duck_state == "rest", 5.0)
		var cool_s: float = main.t - t_cool
		calm_enemies(true) # the parked foes walk back toward her in ten seconds
		tap(KEY_E)
		await wait(0.2)
		var again: bool = mt.duck_runs == runs0 + 2
		check("marsh_duck", on_ground and quiet_story and quiet_fight and quiet_early and hint_shown and clicks == 3 and started and across > 2.5 and busy_ignored \
			and loop_s > 5.9 and loop_s < 6.4 and home < 0.1 and cool_ignored and cool_s > 2.8 and cool_s < 3.3 and again,
			"crank at (%.1f, %.1f) on dry free ground off the lane=%s, no run in a story=%s / a fight=%s / before the crown=%s, E hint=%s, crank clicks %d, duck %.1f tiles across at half time, E while running ignored=%s, loop %.2f s, back home %.2f tiles, E in the cooldown ignored=%s, cooldown %.2f s, wound again=%s" \
			% [h.x, h.y, on_ground, quiet_story, quiet_fight, quiet_early, hint_shown, clicks, across, busy_ignored, loop_s, home, cool_ignored, cool_s, again])
	if want.call("marsh_frog_call"):
		# a sitting frog croaks twice near the pond, says so the first time, and is quiet beyond 12 tiles
		marsh_world()
		var mt: Object = main.marsh_toys
		mt.frog_named = false
		var c0: int = mt.frog_calls
		var away: Vector2 = (mt.frogs[0].perch - mt.POND).normalized()
		reset_to(mt.POND + away * 8.0)
		var b0: int = mt.frog_said
		var called: bool = await wait_for(func(): return mt.frog_calls > c0, 12.0)
		var low: bool = main.sfx_log.any(func(s): return String(s) == "croak:165")
		await wait(0.3)
		var second: bool = main.sfx_log.any(func(s): return String(s) == "croak:130")
		# the rasp: the call is broken by silent gaps, about 36 a second, not one steady tone
		var pcm: PackedByteArray = main.sound.sfx_stream(165.0, 0.2, "croak", 0.24, 60.0).data
		var gaps := 0
		var quiet_run := 0
		for i in pcm.size() / 2:
			quiet_run = quiet_run + 1 if absi(pcm.decode_s16(i * 2)) < 60 else 0
			gaps += 1 if quiet_run == 40 else 0
		var rasp: bool = gaps >= 5 and gaps <= 8
		var named: bool = mt.frog_said == b0 + 1
		var c1: int = mt.frog_calls
		var again: bool = await wait_for(func(): return mt.frog_calls > c1, 12.0)
		var once: bool = mt.frog_said == b0 + 1
		reset_to(mt.POND + Vector2(13.5, 0.0)) # dry ground to the east
		main.player.vx = 0.0
		var c2: int = mt.frog_calls
		await wait(6.0)
		var far_d: float = Vector2(main.player.x, main.player.z).distance_to(mt.POND)
		var far_quiet: bool = mt.frog_calls == c2 and far_d > mt.FROG_CALL_D
		check("marsh_frog_call", called and low and second and rasp and named and again and once and far_quiet,
			"croaks near the pond %s, two notes %s/%s, %d gaps in the rasp %s, says so once %s/%s, croaks again %s, quiet at %.1f tiles %s" % [called, low, second, gaps, rasp, named, once, again, far_d, far_quiet])
	if want.call("marsh_frogs"):
		# three frogs on the pond's bank (v0.1.106): each flees alone when Sora is 2 tiles off (a 0.35 s hop, one after another),
		# and after 3 s of standing still one peeks back
		marsh_world()
		var mt: Object = main.marsh_toys
		var fr: Array = mt.frogs
		var grounded: bool = fr.size() == 3
		var tiny := true
		for f in fr:
			grounded = grounded and marsh_ground_ok(f.perch) and main.tile_at(f.land.x, f.land.y) == main.WATER and f.perch.distance_to(mt.POND) < 4.6 and f.perch.distance_to(mt.duck_handle) > 3.0
			var bx: BoxMesh = f.node.get_child(0).mesh
			tiny = tiny and f.node.get_child_count() == 3 and is_equal_approx(bx.size.z, 0.25)
		var f0: Dictionary = fr[0]
		var out0: Vector2 = (f0.perch - mt.POND).normalized()
		var flees0: int = mt.frog_flees
		reset_to(f0.perch + out0 * 3.0)
		await wait(0.4)
		var calm: bool = f0.state == "sit" and mt.frog_flees == flees0
		reset_to(f0.perch + out0 * 1.9)
		var t_out := -1.0
		var t_gone := -1.0
		for k in 120:
			await get_tree().process_frame
			if t_out < 0.0 and f0.state == "out":
				t_out = main.t
			if f0.state == "gone":
				t_gone = main.t
				break
		var hop_s: float = t_gone - t_out
		var alone: bool = fr[1].state == "sit" and fr[2].state == "sit" and not f0.node.visible and mt.frog_flees == flees0 + 1
		var ret0: int = mt.frog_returns
		reset_to(f0.perch + out0 * 3.0)
		var t_s: float = main.t
		await wait(2.3)
		var none_early: bool = mt.frog_returns == ret0 and f0.state == "gone"
		await wait_for(func(): return mt.frog_returns == ret0 + 1, 1.5)
		var still_s: float = main.t - t_s
		await wait(0.6)
		var back: bool = f0.state == "sit" and f0.node.visible and Vector2(f0.node.position.x, f0.node.position.z).distance_to(f0.perch) < 0.05
		# two at once: Sora between the first two, who go one after another; then one comes back per three still seconds
		var mid: Vector2 = (fr[0].perch + fr[1].perch) / 2.0
		var both: bool = mid.distance_to(fr[0].perch) < 2.0 and mid.distance_to(fr[1].perch) < 2.0
		reset_to(mid)
		var g1 := -1.0
		var g2 := -1.0
		for k in 120:
			await get_tree().process_frame
			if g1 < 0.0 and fr[0].state == "gone":
				g1 = main.t
			if g2 < 0.0 and fr[1].state == "gone":
				g2 = main.t
				break
		var in_turn: bool = g1 > 0.0 and g2 - g1 > 0.08
		var ret1: int = mt.frog_returns
		reset_to(mid + (mid - mt.POND).normalized() * 3.2)
		await wait(2.5)
		var held: bool = mt.frog_returns == ret1
		await wait_for(func(): return mt.frog_returns == ret1 + 1, 1.5)
		var one_gone: bool = fr.filter(func(f): return f.state == "gone").size() == 1
		await wait(2.0)
		var one_only: bool = mt.frog_returns == ret1 + 1
		await wait_for(func(): return mt.frog_returns == ret1 + 2, 2.0)
		reset_to(main.START)
		check("marsh_frogs", grounded and tiny and calm and hop_s > 0.3 and hop_s < 0.45 and alone and none_early and still_s > 2.9 and still_s < 3.4 and back \
			and both and in_turn and held and one_gone and one_only and mt.frog_returns == ret1 + 2,
			"3 frogs 0.25 long on free bank ground=%s/%s, no flight at 3 tiles=%s, hop %.2f s, the others stay=%s, nothing back before 3 s=%s, a frog back after %.2f s onto its perch=%s, two flee in turn (%.2f s apart)=%s, held=%s, one back per still spell=%s/%s, the second later=%s" \
			% [grounded, tiny, calm, hop_s, alone, none_early, still_s, back, g2 - g1, in_turn, held, one_gone, one_only, mt.frog_returns == ret1 + 2])
	if want.call("marsh_fluff"):
		# three ripe cattail heads off the opening walk (v0.1.106): passing one sheds four of twelve pooled white quads that drift
		# 2.5 s; the head is ripe again after 20 s
		marsh_world()
		var mt: Object = main.marsh_toys
		var cs: Array = mt.cattails
		var spot_ok: bool = cs.size() == 3 and mt.fluff.size() == 12
		var centre := Vector2.ZERO
		for c in cs:
			spot_ok = spot_ok and marsh_ground_ok(c.pos)
			centre += c.pos / 3.0
		var white := true
		for q in mt.fluff:
			var fm: StandardMaterial3D = q.node.material_override
			white = white and fm.albedo_color.r > 0.95 and fm.albedo_color.g > 0.95 and q.node.mesh is QuadMesh and not q.node.visible
		var puffs0: int = mt.fluff_puffs
		reset_to(Vector2(11.5, 20.0)) # on the opening walk
		await wait(0.3)
		var lane_quiet: bool = mt.fluff_puffs == puffs0
		var c0: Dictionary = cs[0]
		var out0: Vector2 = (c0.pos - centre).normalized()
		reset_to(c0.pos + out0 * 1.6)
		await wait(0.3)
		var far_quiet: bool = mt.fluff_puffs == puffs0
		reset_to(c0.pos + out0 * 0.8)
		var t_trig: float = main.t
		var t_on := -1.0
		var t_off := -1.0
		var peak := 0
		for k in 400:
			await get_tree().process_frame
			var live: int = mt.fluff.filter(func(q): return q.t >= 0.0).size()
			peak = maxi(peak, live)
			if t_on < 0.0 and live > 0:
				t_on = main.t
			if t_on >= 0.0 and live == 0:
				t_off = main.t
				break
		var drift_s: float = t_off - t_on
		var one_head: bool = mt.fluff_puffs == puffs0 + 1 and not c0.ready and cs[1].ready and cs[2].ready and peak == 4
		reset_to(main.START)
		await wait_for(func(): return c0.ready, 22.0)
		var reset_s: float = main.t - t_trig
		check("marsh_fluff", spot_ok and white and lane_quiet and far_quiet and one_head and drift_s > 2.4 and drift_s < 2.65 and reset_s > 19.8 and reset_s < 20.5,
			"3 heads on free ground off the lane=%s, 12 white quads=%s, nothing on the lane=%s / 1.6 tiles off=%s, one pass sheds one head's 4 quads (peak %d)=%s, drift %.2f s, ripe again after %.2f s" \
			% [spot_ok, white, lane_quiet, far_quiet, peak, one_head, drift_s, reset_s])
	if want.call("marsh_pipe"):
		# the reed pipe rack by Bori's cottage (v0.1.106): E plays three breathy notes (the tones cached), a far answer comes
		# 0.8 s after the first, then 8 s of cooldown; never during a story, a fight, or before the crown has been touched
		marsh_world()
		var mt: Object = main.marsh_toys
		var rk: Vector2 = mt.rack_at
		var bar: BoxMesh = mt.rack.get_child(2).mesh if mt.rack != null else null
		var built: bool = mt.rack != null and marsh_ground_ok(rk) and rk.distance_to(main.cottage_at) < 4.5 and is_equal_approx(bar.size.x, 0.7) and mt.pipes.size() == 5
		var plays0: int = mt.pipe_plays
		reset_to(rk)
		main.show_story("", ["||test"])
		tap(KEY_E)
		await wait(0.2)
		var quiet_story: bool = mt.pipe_plays == plays0
		main.close_story()
		var foe_set: bool = marsh_foe(rk + Vector2(2.0, 0.0))
		tap(KEY_E)
		await wait(0.2)
		var quiet_fight: bool = foe_set and mt.pipe_plays == plays0 and not mt.usable()
		calm_enemies(true)
		main.story_step = 1
		tap(KEY_E)
		await wait(0.2)
		var quiet_early: bool = mt.pipe_plays == plays0
		main.close_story() # E at step 1 touches the crown
		main.story_step = 3
		reset_to(rk)
		await wait(0.2)
		var hint_shown: bool = mt.hint() != "" and main.ui.shop_hint.visible and plain(main.ui.shop_hint.text) == mt.hint()
		main.sfx_log.clear()
		var t0: float = main.t
		tap(KEY_E)
		await wait(1.8)
		var tm: Array = mt.pipe_times
		var order: bool = tm.size() == 5
		var gap: float = tm[3] - tm[0] if order else -1.0
		var notes: bool = main.sfx_log.has("sine:523") and main.sfx_log.has("sine:659") and main.sfx_log.has("sine:587") and main.sfx_log.has("sine:988") and main.sfx_log.any(func(s): return s.begins_with("step:"))
		var played: bool = mt.pipe_plays == plays0 + 1
		var cached: int = main.sfx_cache.size()
		var cool_s: float = mt.pipe_ready_t - t0
		tap(KEY_E)
		await wait(0.2)
		var cool_ignored: bool = mt.pipe_plays == plays0 + 1 and mt.hint() == ""
		await wait_for(func(): return main.t >= t0 + 7.6, 8.0)
		calm_enemies(true)
		tap(KEY_E)
		await wait(0.2)
		var early_ignored: bool = mt.pipe_plays == plays0 + 1
		await wait_for(func(): return main.t >= t0 + 8.1, 2.0)
		calm_enemies(true)
		tap(KEY_E)
		await wait(1.8)
		var again: bool = mt.pipe_plays == plays0 + 2 and main.sfx_cache.size() >= cached and main.sound.sfx_stream(523.0, 0.3, "sine", 0.14) == main.sound.sfx_stream(523.0, 0.3, "sine", 0.14)
		check("marsh_pipe", built and quiet_story and quiet_fight and quiet_early and hint_shown and order and gap > 0.7 and gap < 0.95 and notes and played and cool_s > 7.95 and cool_s < 8.1 \
			and cool_ignored and early_ignored and again,
			"rack at (%.1f, %.1f) 0.7 wide, 5 pipes, on free ground by the cottage=%s, no play in a story=%s / a fight=%s / before the crown=%s, E hint=%s, 5 sounds=%s, answer %.2f s after the first note, tones as asked=%s, cooldown %.2f s, E at 3 s ignored=%s, at 7.6 s ignored=%s, played again with the tones cached=%s" \
			% [rk.x, rk.y, built, quiet_story, quiet_fight, quiet_early, hint_shown, order, gap, notes, cool_s, cool_ignored, early_ignored, again])
	if want.call("marsh_mat"):
		# Bori's mat beside the cottage (v0.1.106): E gives her two short lines about the moonkeepers' wet shoes, only once Sora has
		# met her (story step 3); nothing during another story
		marsh_world()
		var mt: Object = main.marsh_toys
		var at: Vector2 = mt.mat_at
		var strips := 0
		var needles := 0
		if mt.mat_node != null:
			for b in mt.mat_node.get_children():
				if b == mt.mat_shoes: # Sora's pair, shown from the ending on
					continue
				var bs: Vector3 = (b.mesh as BoxMesh).size
				if is_equal_approx(bs.x, 0.7) and is_equal_approx(bs.z, 0.12):
					strips += 1
				if is_equal_approx(bs.z, 0.26):
					needles += 1
		var built: bool = strips == 8 and needles == 1 and marsh_ground_ok(at) and at.distance_to(main.cottage_at) < 4.5
		var lines: Array = main.STORY.MARSH_MAT
		var bori_lines: bool = lines.size() == 2 and lines.all(func(l): return String(l).begins_with("보리 할머니|bori|") and String(l).length() < 60) and String(lines[0]).contains("젖은 신")
		main.story_step = 2
		reset_to(at)
		var hint_early: String = mt.hint()
		tap(KEY_E)
		await wait(0.3)
		var quiet_early: bool = not main.story_open and hint_early == ""
		main.story_step = 3
		reset_to(at + Vector2(-2.5, 0.0))
		tap(KEY_E)
		await wait(0.3)
		var quiet_far: bool = not main.story_open
		reset_to(at)
		await wait(0.2)
		var hint_shown: bool = mt.hint() != "" and main.ui.shop_hint.visible
		tap(KEY_E)
		await wait(0.3)
		var told: bool = main.story_open and main.ui.story_who.text == "보리 할머니" and main.story_lines.size() == 1 and plain(main.ui.story_text.text).begins_with("그 깔개")
		var quiet_story: bool = not mt.key() and mt.hint() == ""
		main.close_story()
		check("marsh_mat", built and bori_lines and quiet_early and quiet_far and hint_shown and told and quiet_story,
			"mat at (%.1f, %.1f): 8 strips and 1 needle on free ground beside the cottage=%s, two Bori lines under 60 characters=%s, nothing at step 2=%s / 3 tiles off=%s, E hint=%s, E gives the lines=%s, nothing during a story=%s" \
			% [at.x, at.y, built, bori_lines, quiet_early, quiet_far, hint_shown, told, quiet_story])

	# ---- v0.1.107: small delights from shots/plans/delight100.md (ideas 1, 4, 7, 8, 9, 10, 14, 16, 18, 19)
	if want.call("d1_leaves"):
		# the leaves in the low basin follow Sora round it a beat late, the same way; far away or in the full basin they stay (idea 1)
		var v1: Object = main.village
		var was_in: bool = main.in_village
		var was_wet: bool = v1.fountain_wet
		main.in_village = true
		main.close_story()
		v1.fountain_set(false)
		var fa1: Vector2 = v1.fountain_at()
		var goal0: float = v1.leaf_goal
		reset_to(fa1 + Vector2(8.0, 0.0))
		v1.life_update(main, 0.05)
		v1.life_update(main, 0.05)
		var far_quiet: bool = is_equal_approx(v1.leaf_goal, goal0)
		reset_to(fa1 + Vector2(2.0, 0.0))
		v1.life_update(main, 0.05) # her angle is noted
		var spin0: float = v1.leaf_spin
		var l0: Dictionary = v1.leaves[0]
		var ang_before: float = Vector2(l0.node.position.x, l0.node.position.z).angle()
		for k in range(1, 21): # a turn of one radian round the basin
			reset_to(fa1 + Vector2(cos(k * 0.05), sin(k * 0.05)) * 2.0)
			v1.life_update(main, 0.05)
		var gone: float = v1.leaf_goal - goal0
		var late: bool = v1.leaf_spin > spin0 and v1.leaf_spin < v1.leaf_goal - 0.1 # moving, but behind her
		for k in 40:
			v1.life_update(main, 0.1)
		var caught: bool = absf(v1.leaf_spin - v1.leaf_goal) < 0.02
		var ang_after: float = Vector2(l0.node.position.x, l0.node.position.z).angle()
		var same_way: bool = absf(angle_difference(ang_before, ang_after) - gone) < 0.05 and gone > 0.8
		var g1: float = v1.leaf_goal
		v1.fountain_set(true) # the full basin has no leaves to move
		reset_to(fa1 + Vector2(2.0, 0.0))
		v1.life_update(main, 0.05)
		reset_to(fa1 + Vector2(cos(0.5), sin(0.5)) * 2.0)
		v1.life_update(main, 0.05)
		var full_quiet: bool = is_equal_approx(v1.leaf_goal, g1)
		v1.fountain_set(was_wet)
		main.in_village = was_in
		check("d1_leaves", far_quiet and late and caught and same_way and full_quiet and v1.leaves.size() == 3,
			"far from the basin no change=%s she goes round %.2f rad, the leaves follow behind=%s catch up=%s they turn the same way=%s full basin no change=%s 3 leaves=%s" % [far_quiet, gone, late, caught, same_way, full_quiet, v1.leaves.size() == 3])
	if want.call("d4_sign_sway"):
		# the east signpost's board sways in the wind and calms to a fifth while Sora stands still before it facing it (idea 4)
		var hb4: Object = main.hud_build
		main.close_story()
		var at4: Vector2 = hb4.SIGN_AT
		reset_to(at4 + Vector2(6.0, 0.0))
		main.idle_t = 5.0
		main.player.face = Vector2(0, 1)
		for k in 30:
			hb4.update_sign(0.1)
		var far_full: bool = is_equal_approx(hb4.sign_sway, 1.0)
		var peak_far := 0.0
		for k in 60:
			main.t += 0.1
			hb4.update_sign(0.1)
			peak_far = maxf(peak_far, absf(hb4.sign_pivot.rotation.z))
		reset_to(at4 + Vector2(0.0, 1.4))
		main.player.face = Vector2(0, -1) # towards the board
		for k in 30:
			hb4.update_sign(0.1)
		var calmed: bool = hb4.sign_sway < 0.25
		var peak_near := 0.0
		for k in 60:
			main.t += 0.1
			hb4.update_sign(0.1)
			peak_near = maxf(peak_near, absf(hb4.sign_pivot.rotation.z))
		main.player.face = Vector2(0, 1) # turned away: the sway comes back
		for k in 30:
			hb4.update_sign(0.1)
		var back_away: bool = hb4.sign_sway > 0.95
		main.player.face = Vector2(0, -1)
		main.idle_t = 0.0 # walking: no calming
		for k in 30:
			hb4.update_sign(0.1)
		var walking: bool = hb4.sign_sway > 0.95
		check("d4_sign_sway", far_full and calmed and back_away and walking and peak_far > 0.08 and peak_near < peak_far * 0.3,
			"full sway far away=%s calmed facing it still=%s sways again when turned away=%s and when walking=%s peak far %.3f near %.3f rad" % [far_full, calmed, back_away, walking, peak_far, peak_near])
	if want.call("d7_shop_flag"):
		# the miller's flag by the big windmill is still until the windmill has turned for 1.2 s, then ripples (idea 7)
		var hz7: Object = main.hill_zone
		var mq7: int = main.mill_q
		var segs7: Array = hz7.shop_flag.get_children()
		var wave := func() -> float:
			var w := 0.0
			for sg in segs7:
				w = maxf(w, absf(sg.position.z))
			return w
		main.mill_q = 0
		hz7.shop_flag_t = 0.0
		hz7.update_shop_flag(1.0)
		var idle7: bool = wave.call() == 0.0
		main.mill_q = 3
		hz7.update_shop_flag(0.5)
		var early7: bool = wave.call() == 0.0 and hz7.shop_flag_t < hz7.SHOP_FLAG_LAG
		main.t = 0.5
		hz7.update_shop_flag(1.0)
		var w7: float = wave.call()
		var waves: bool = w7 > 0.01 and segs7.size() == 4 and absf(segs7[3].position.z) != absf(segs7[0].position.z)
		main.mill_q = 2 # the windmill stands again: still at once, and the timer starts over
		hz7.update_shop_flag(0.1)
		var stops: bool = wave.call() == 0.0 and hz7.shop_flag_t == 0.0
		var fp: Vector3 = hz7.shop_flag.get_parent().position
		var beside: bool = Vector2(fp.x, fp.z).distance_to(main.hill.south_marks.Q) < 3.0 and main.walkable(fp.x, fp.z)
		main.mill_q = mq7
		check("d7_shop_flag", idle7 and early7 and waves and stops and beside,
			"still while the windmill is stopped=%s still for the first 0.5 s of turning=%s ripples after 1.5 s (%.3f)=%s stops with it=%s beside the windmill on free ground=%s" % [idle7, early7, w7, waves, stops, beside])
	if want.call("d8_palm"):
		# a lantern lit by the bracelet leaves a palm print on the glass face towards Sora for two seconds; putting a lamp out leaves none (idea 8)
		var wb8: Object = main.world_build
		var lamp8: OmniLight3D = main.lanterns.filter(func(l): return l.has_meta("glass") and not l.get_meta("dark", false) and l != main.dark_lamp and l.position.x < 50.0)[0]
		var glass8: MeshInstance3D = lamp8.get_meta("glass")
		main.close_story()
		reset_to(Vector2(lamp8.position.x - 0.3, lamp8.position.z + 1.0))
		var pm0: int = wb8.palm_marks
		main.toggle_lantern() # out
		var none_off: bool = wb8.palm_marks == pm0
		main.toggle_lantern() # lit again
		var one_on: bool = wb8.palm_marks == pm0 + 1
		var pr: Node3D = wb8.palm_last
		var on_glass: bool = pr.get_parent() == glass8 and absf(pr.position.z - 0.113) < 0.001 and absf(pr.position.x) < 0.001 # the south face, towards her
		var boxes: Array = pr.get_children()
		var faint: bool = boxes.size() == 6 and (boxes[0].material_override as StandardMaterial3D).albedo_color.a < 0.6
		await wait(1.0)
		var still_there: bool = is_instance_valid(pr)
		await wait(1.4)
		var gone: bool = not is_instance_valid(pr)
		var vl: OmniLight3D = main.village_lamps()[0]
		wb8.palm_mark(vl.get_meta("glass"))
		var village_ok: bool = wb8.palm_marks == pm0 + 2 and wb8.palm_last.get_parent() == vl.get_meta("glass")
		wb8.palm_last.queue_free()
		check("d8_palm", none_off and one_on and on_glass and faint and still_there and gone and village_ok,
			"no print when a lamp goes out=%s one when lit=%s on the glass face towards her=%s 6 faint boxes=%s there at 1 s=%s gone by 2.4 s=%s a village lamp too=%s" % [none_off, one_on, on_glass, faint, still_there, gone, village_ok])
	if want.call("d9_rope"):
		# the rope strips along each bridge dip a little when Sora steps onto a deck end and swing back; nothing in the middle, nothing near a monster (idea 9)
		var wb9: Object = main.world_build
		var b9: Dictionary = main.bridges[0]
		var rp: Dictionary = wb9.ropes[0]
		var mid: Node3D = rp.segs[3]
		var base_y: float = mid.position.y
		var keep9: Array = main.enemies
		main.enemies = []
		main.close_story()
		var d0: int = wb9.rope_dips
		reset_to(Vector2((b9.a + b9.b) / 2.0, b9.z + 0.5))
		wb9.update_ropes()
		var mid_quiet: bool = wb9.rope_dips == d0
		reset_to(Vector2(b9.a, b9.z + 0.5))
		wb9.update_ropes()
		wb9.update_ropes() # standing on it: one dip, not two
		var one: bool = wb9.rope_dips == d0 + 1
		await wait(0.3)
		var dipped: bool = mid.position.y < base_y - 0.03
		await wait(1.2)
		var back: bool = absf(mid.position.y - base_y) < 0.005
		var deck_fixed: bool = main.walkable(b9.a + 0.5, b9.z + 0.5)
		reset_to(Vector2(b9.a - 3.0, b9.z + 0.5))
		wb9.update_ropes()
		main.enemies = [{"x": float(b9.b), "z": b9.z + 0.5, "dead": false}]
		reset_to(Vector2(b9.b, b9.z + 0.5))
		wb9.update_ropes()
		var foe_quiet: bool = wb9.rope_dips == d0 + 1
		main.enemies = []
		reset_to(Vector2(b9.b - 3.0, b9.z + 0.5))
		wb9.update_ropes()
		reset_to(Vector2(b9.b, b9.z + 0.5))
		wb9.update_ropes()
		var other_end: bool = wb9.rope_dips == d0 + 2
		main.enemies = keep9
		await wait(1.2)
		check("d9_rope", mid_quiet and one and dipped and back and deck_fixed and foe_quiet and other_end and wb9.ropes.size() >= 3,
			"nothing mid-deck=%s one dip at the end=%s rope sags=%s back=%s deck still walkable=%s nothing with a monster near=%s the other end dips=%s ropes on %d bridges" % [mid_quiet, one, dipped, back, deck_fixed, foe_quiet, other_end, wb9.ropes.size()])
	if want.call("d10_empty_chest"):
		# E at a chest already opened only stirs dust and shows the empty floor: no gold, no potion, the chest stays open, a 1.5 s pause between (idea 10)
		var wb10: Object = main.world_build
		var c10: Dictionary = main.chests[0]
		var open0: bool = c10.open
		main.close_story()
		c10.open = true
		var gold0: int = main.player.gold
		var pots0: int = main.player.pots
		reset_to(Vector2(c10.x, c10.z))
		wb10.chest_peek_t = -10.0
		var p0: int = wb10.chest_peeks
		main.interact() # the end of the E key
		var peeked: bool = wb10.chest_peeks == p0 + 1
		var nothing: bool = main.player.gold == gold0 and main.player.pots == pots0 and c10.open
		main.interact()
		var paused: bool = wb10.chest_peeks == p0 + 1
		wb10.chest_peek_t = -10.0
		reset_to(Vector2(c10.x + 4.0, c10.z))
		var far10: bool = not wb10.chest_peek() and wb10.chest_peeks == p0 + 1
		c10.open = false # a shut chest is not a peek
		reset_to(Vector2(c10.x, c10.z + 3.0))
		var shut: bool = not wb10.chest_peek()
		c10.open = open0
		check("d10_empty_chest", peeked and nothing and paused and far10 and shut,
			"E at an opened chest peeks once=%s no gold or potion, still open=%s a second E within 1.5 s is quiet=%s far away=%s a shut chest is no peek=%s" % [peeked, nothing, paused, far10, shut])
	if want.call("d14_rest_more"):
		# 3 s after the moon light fills, still by the lantern with Mulgyeol, he says it is full but to rest a little longer; moving, a monster, no Mulgyeol or leaving the lantern stops it (idea 14)
		var hb14: Object = main.hud_build
		main.join_mate()
		main.close_story()
		var lamp14 = main.lanterns.filter(func(l): return l.position.x > 130.0 and not l.get_meta("dark", false))[0]
		var keep14: Array = main.enemies
		main.enemies = []
		reset_to(Vector2(lamp14.position.x + 0.4, lamp14.position.z + 1.0))
		main.player.vx = 0.0
		main.player.vz = 0.0
		var s0: int = hb14.full_says
		var b14: int = main.bubbles_said
		hb14.full_say_t = hb14.FULL_SAY_DELAY
		hb14.update_full_say(1.0)
		hb14.update_full_say(1.0)
		var early14: bool = hb14.full_says == s0
		hb14.update_full_say(1.5)
		var said: bool = hb14.full_says == s0 + 1 and main.bubbles_said == b14 + 1
		hb14.update_full_say(5.0)
		var once14: bool = hb14.full_says == s0 + 1
		hb14.full_say_t = 3.0 # she walks off
		main.player.vx = 2.0
		hb14.update_full_say(5.0)
		main.player.vx = 0.0
		var moved14: bool = hb14.full_says == s0 + 1 and hb14.full_say_t < 0.0
		hb14.full_say_t = 3.0 # a monster comes
		main.enemies = [{"x": main.player.x + 2.0, "z": main.player.z, "dead": false}]
		hb14.update_full_say(5.0)
		var foe14: bool = hb14.full_says == s0 + 1
		main.enemies = []
		var mate14 = main.mate
		main.mate = null
		hb14.full_say_t = 3.0
		hb14.update_full_say(5.0)
		main.mate = mate14
		var alone14: bool = hb14.full_says == s0 + 1
		reset_to(Vector2(lamp14.position.x + 6.0, lamp14.position.z + 1.0)) # away from the lantern
		hb14.full_say_t = 3.0
		hb14.update_full_say(5.0)
		var away14: bool = hb14.full_says == s0 + 1
		main.enemies = keep14
		check("d14_rest_more", early14 and said and once14 and moved14 and foe14 and alone14 and away14,
			"quiet for the first 2 s=%s says it once at 3 s=%s not again=%s moving cancels=%s a monster cancels=%s without Mulgyeol=%s away from the lantern=%s" % [early14, said, once14, moved14, foe14, alone14, away14])
	if want.call("d16_scenic"):
		# stopping at a hill view for the first time turns both companions to face it; it ends when she moves and does not return at the same view (idea 16)
		var hz16: Object = main.hill_zone
		var was_hill: bool = main.in_hill
		main.in_hill = true
		main.join_mate()
		main.join_noeul()
		main.close_story()
		calm_enemies(true)
		hz16.scenic_seen.clear()
		hz16.scenic_at = -1
		main.mate_job = {} # an earlier test can leave him on a job or a quirk walk
		main.mates.end_quirk()
		var view: Dictionary = hz16.SCENIC[0]
		reset_to(view.at + Vector2(0.0, 0.5))
		main.snap_mates()
		var left16: bool = main.screen_left(view.look)
		await wait_for(func(): return hz16.scenic_at == 0 and main.mate2.get_child(0).flip_h == left16 and main.mate.get_child(0).flip_h == (not left16), 4.0) # the faces can already match before the view is taken
		var took: bool = hz16.scenic_at == 0 and main.mates.scenic_dir == view.look
		var n_face: bool = main.mate2.get_child(0).flip_h == left16
		var m_face: bool = main.mate.get_child(0).flip_h == (not left16)
		reset_to(view.at + Vector2(4.0, 0.0))
		await wait(0.3)
		var ended: bool = hz16.scenic_at == -1 and main.mates.scenic_dir == Vector2.ZERO
		reset_to(view.at)
		await wait(2.0)
		var not_again: bool = hz16.scenic_at == -1 and main.mates.scenic_dir == Vector2.ZERO
		var view2: Dictionary = hz16.SCENIC[1]
		reset_to(view2.at)
		await wait(2.0)
		var second: bool = hz16.scenic_at == 1 and main.mates.scenic_dir == view2.look
		reset_to(Vector2(view2.at.x + 4.0, view2.at.y - 4.0))
		await wait(0.3)
		hz16.scenic_seen.clear() # a monster close by: no view is taken in
		main.spawn_enemy(view.at + Vector2(2.0, 0.0))
		var foe_e: Dictionary = main.enemies[main.enemies.size() - 1]
		reset_to(view.at)
		await wait(1.5)
		var foe16: bool = hz16.scenic_at == -1
		foe_e.node.queue_free()
		main.enemies.erase(foe_e)
		calm_enemies(false)
		reset_to(view.at + Vector2(5.0, 5.0))
		await wait(0.3)
		main.in_hill = was_hill
		check("d16_scenic", took and n_face and m_face and ended and not_again and second and foe16,
			"the first stop takes the view in=%s Noeul faces it=%s Mulgyeol faces it=%s ends when she moves=%s not again at the same view=%s the second view works=%s no monster near=%s" % [took, n_face, m_face, ended, not_again, second, foe16])
	if want.call("d18_noeul_bow"):
		# once Noeul has joined, the first slow walk over the old clearing makes him bow his head (a 14 px dip and back); running, standing, far off, a monster near, or before he joins for good: nothing (idea 18)
		var fz: Object = main.forest_zone
		var fq: int = main.forest_q
		main.join_noeul()
		main.forest_q = 3
		main.close_story()
		main.intro = false
		var keep18: Array = main.enemies
		main.enemies = []
		var N: Vector2 = main.forest.marks.N
		reset_to(N)
		main.mate2.visible = true
		main.mate2.position = Vector3(N.x + 0.8, 0.0, N.y)
		var spr18: Sprite3D = main.mate2.get_child(0)
		var y18: float = spr18.offset.y
		var n0: int = fz.noeul_nods
		fz.noeul_bowed = false
		main.player.vx = 6.0 # running
		fz.noeul_bow()
		var run_quiet: bool = fz.noeul_nods == n0
		main.player.vx = 0.0 # standing
		fz.noeul_bow()
		var stand_quiet: bool = fz.noeul_nods == n0
		main.player.vx = 3.6
		reset_to(N + Vector2(5.0, 0.0))
		main.mate2.position = Vector3(N.x + 5.8, 0.0, N.y)
		fz.noeul_bow()
		var far_quiet18: bool = fz.noeul_nods == n0
		reset_to(N)
		main.mate2.position = Vector3(N.x + 0.8, 0.0, N.y)
		main.enemies = [{"x": N.x + 3.0, "z": N.y, "dead": false}]
		fz.noeul_bow()
		var foe18: bool = fz.noeul_nods == n0
		main.enemies = []
		main.forest_q = 2 # before he has joined for good
		fz.noeul_bow()
		var early18: bool = fz.noeul_nods == n0
		main.forest_q = 3
		fz.noeul_bow()
		var bowed: bool = fz.noeul_nods == n0 + 1
		fz.noeul_bow() # only once
		var once18: bool = fz.noeul_nods == n0 + 1
		await wait(0.3)
		var dip: bool = spr18.offset.y < y18 - 10.0
		await wait(1.0)
		var up: bool = is_equal_approx(spr18.offset.y, y18)
		main.enemies = keep18
		main.forest_q = fq
		main.player.vx = 0.0
		check("d18_noeul_bow", run_quiet and stand_quiet and far_quiet18 and foe18 and early18 and bowed and once18 and dip and up,
			"running=%s standing=%s far off=%s monster near=%s before he joined for good=%s bows on a slow walk=%s once=%s dips 14 px=%s and comes up=%s" % [run_quiet, stand_quiet, far_quiet18, foe18, early18, bowed, once18, dip, up])
	if want.call("d19_listened"):
		# standing quite still through a light rest talk earns Mulgyeol a small thanks after the last line, once in 120 s; moving, a story talk or a hush earn none (idea 19)
		var ch19: Object = main.chatter
		main.join_mate()
		main.close_story()
		main.in_house = -1
		calm_enemies(true)
		main.player.vx = 0.0
		main.player.vz = 0.0
		var talk19: Array = [["mulgyeol", "잠깐 쉬자."]]
		await wait(0.5)
		ch19.listen_last = -1000.0
		var th0: int = ch19.listen_thanks
		var bb0: int = main.bubbles_said
		ch19.rest_talk(talk19, true)
		await wait(3.4)
		var thanked: bool = ch19.listen_thanks == th0 + 1 and main.bubbles_said == bb0 + 2
		ch19.rest_talk(talk19, true) # within the 120 s
		await wait(3.4)
		var gap_ok: bool = ch19.listen_thanks == th0 + 1
		ch19.listen_last = -1000.0
		ch19.rest_talk(talk19, true)
		await wait(1.0)
		main.chat_t = 0.0 # she stirred meanwhile
		await wait(2.6)
		var moved19: bool = ch19.listen_thanks == th0 + 1
		await wait(0.2)
		ch19.listen_last = -1000.0
		ch19.rest_talk(talk19) # a story talk is not light
		await wait(3.4)
		var story19: bool = ch19.listen_thanks == th0 + 1
		ch19.rest_talk(talk19, true)
		await wait(1.0)
		ch19.hush_talk() # a monster hushed it
		await wait(2.6)
		var hush19: bool = ch19.listen_thanks == th0 + 1
		calm_enemies(false)
		check("d19_listened", thanked and gap_ok and moved19 and story19 and hush19,
			"thanks after a still light talk=%s not again within 120 s=%s none if she stirred=%s none after a story talk=%s none if hushed=%s" % [thanked, gap_ok, moved19, story19, hush19])

	if want.call("d20_arrive"):
		# a companion who trailed her through a narrow way and comes up beside her while she waits makes one quiet two-tone, only if he is the last one still coming; moving on, a monster near or a story: none (idea 20)
		var ma: Object = main.mates
		main.join_mate()
		main.join_noeul()
		main.close_story()
		main.intro = false
		main.in_house = -1
		calm_enemies(true)
		var me20 := Vector3(main.player.x, 0, main.player.z)
		main.mate2.visible = true
		main.mate2.position = me20 + Vector3(0.8, 0, 0)
		ma.lagging.clear()
		ma.trailing["mulgyeol"] = true
		ma.trailing["noeul"] = true
		main.mate_idle = 1.5
		var a0: int = ma.arrive_acks
		main.mate.position = me20 + Vector3(3.4, 0, 0)
		ma.update_arrival()
		var far_quiet: bool = ma.arrive_acks == a0 and ma.lagging.get("mulgyeol", false)
		main.mate_idle = 0.3 # she is still walking when he catches up
		main.mate.position = me20 + Vector3(1.2, 0, 0)
		ma.update_arrival()
		var walk_quiet: bool = ma.arrive_acks == a0 and not ma.lagging.get("mulgyeol", false)
		main.mate_idle = 1.5
		ma.lagging["mulgyeol"] = true
		main.enemies = [{"x": me20.x + 3.0, "z": me20.z, "dead": false}]
		ma.update_arrival()
		var foe_quiet: bool = ma.arrive_acks == a0
		main.enemies = []
		ma.lagging["mulgyeol"] = true
		main.show_story("", ["x"])
		ma.update_arrival()
		var story_quiet: bool = ma.arrive_acks == a0
		main.close_story()
		ma.lagging["mulgyeol"] = true # the other is still behind: he is not the last
		main.mate2.position = me20 + Vector3(3.8, 0, 0)
		ma.update_arrival()
		var not_last: bool = ma.arrive_acks == a0
		main.mate2.position = me20 + Vector3(0.8, 0, 0)
		ma.lagging["mulgyeol"] = true
		main.sfx_log.clear()
		ma.update_arrival()
		var acked: bool = ma.arrive_acks == a0 + 1 and main.sfx_log.has("sine:660")
		ma.update_arrival() # the arrival is spent
		var once20: bool = ma.arrive_acks == a0 + 1
		await wait(0.3)
		var two_tone: bool = main.sfx_log.has("sine:880")
		ma.lagging.clear()
		ma.trailing.clear()
		check("d20_arrive", far_quiet and walk_quiet and foe_quiet and story_quiet and not_last and acked and once20 and two_tone,
			"nothing while he is still far=%s nor while she walks=%s nor with a monster near=%s nor in a story=%s nor while the other is behind=%s; one two-tone when the last one comes up (660 then 880)=%s/%s, once=%s" % [far_quiet, walk_quiet, foe_quiet, story_quiet, not_last, acked, two_tone, once20])
		calm_enemies(false)
	if want.call("d21_cup"):
		# the cup beside Bori's door gives off two puffs of steam that rise and fade in turn; it goes on whether the shop is open or shut (idea 21)
		marsh_world()
		main.intro = false
		var wb: Object = main.world_build
		var built21: bool = wb.cup_steam.size() == 2 and wb.cup_top > 0.3 and wb.cup_steam[0][1] != wb.cup_steam[1][1]
		reset_to(main.cottage_at + Vector2(4.0, 4.0))
		await wait(0.2)
		var y_a: float = wb.cup_steam[0][0].position.y
		await wait(0.5)
		var y_b: float = wb.cup_steam[0][0].position.y
		var rises: bool = absf(y_b - y_a) > 0.03
		var in_range: bool = wb.cup_steam.all(func(s): return s[0].position.y >= wb.cup_top - 0.001 and s[0].position.y <= wb.cup_top + 0.5001 and s[0].material_override.albedo_color.a <= 0.46)
		main.story_step = 3
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z))
		main.toggle_shop(true)
		await wait(0.3)
		var open_goes: bool = main.shop_open and wb.cup_steam.all(func(q): return q[0].is_visible_in_tree()) # the whole world waits while she shops, steam included
		main.toggle_shop(false) # out with nothing bought
		reset_to(main.cottage_at + Vector2(6.0, 6.0))
		var yc_a: float = wb.cup_steam[1][0].position.y
		await wait(0.5)
		var yc_b: float = wb.cup_steam[1][0].position.y
		var out_goes: bool = absf(yc_b - yc_a) > 0.03
		check("d21_cup", built21 and rises and in_range and open_goes and out_goes,
			"cup and two steam planes in different phases=%s steam moves=%s stays within 0.5 above the rim=%s still there with the shop open=%s and goes on after leaving it=%s" % [built21, rises, in_range, open_goes, out_goes])
	if want.call("d26_shelter"):
		# in rain, standing under a stall's awning makes the seller pull the spare crate in by 0.35; dry, in a story, or away from it: no move; it goes back out when she leaves or the rain stops (idea 26)
		var mk: Object = main.market
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		calm_enemies(true)
		var at26: Vector2 = main.village.marks["1"]
		var c26: Dictionary = mk.crates[0]
		var z_out: float = at26.y - 1.0 + mk.CRATE_OUT
		var z_in: float = at26.y - 1.0 + mk.CRATE_IN
		var built26: bool = mk.crates.size() == 3 and is_equal_approx(c26.node.position.z, z_out)
		var p0: int = mk.crate_pulls
		main.raining = false
		reset_to(at26)
		await wait(0.9)
		var dry: bool = mk.crate_pulls == p0 and is_equal_approx(c26.node.position.z, z_out)
		main.raining = true
		main.show_story("", ["x"])
		await wait(0.9)
		var story26: bool = mk.crate_pulls == p0 and is_equal_approx(c26.node.position.z, z_out)
		main.close_story()
		reset_to(at26 + Vector2(0.0, 5.0))
		await wait(0.9)
		var away: bool = mk.crate_pulls == p0 and is_equal_approx(c26.node.position.z, z_out)
		reset_to(at26)
		await wait(1.0)
		var pulled: bool = mk.crate_pulls == p0 + 1 and is_equal_approx(c26.node.position.z, z_in)
		reset_to(at26 + Vector2(0.0, 5.0))
		await wait(1.0)
		var back_out: bool = is_equal_approx(c26.node.position.z, z_out)
		reset_to(at26)
		await wait(1.0)
		main.raining = false
		await wait(1.0)
		var rain_stop: bool = is_equal_approx(c26.node.position.z, z_out)
		check("d26_shelter", built26 and dry and story26 and away and pulled and back_out and rain_stop,
			"3 crates=%s dry: none=%s story: none=%s away: none=%s under the awning in rain: 0.8 to 0.45=%s goes back when she leaves=%s and when the rain stops=%s" % [built26, dry, story26, away, pulled, back_out, rain_stop])
		main.in_village = false
		calm_enemies(false)
	if want.call("d27_sleep_z"):
		# stopping after a run within 6 tiles of a house with a sleeper makes the z's bob slow to 0.4 for 2.5 s; walking, standing far off, or no sleeper shown: no change (idea 27)
		var fk: Object = main.folk
		var h27: float = main.hour
		main.hour = 23.0
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		calm_enemies(true)
		await wait(0.5)
		var zs: Array = main.door_z.values()
		var made27: bool = not zs.is_empty()
		var dz27: Label3D = zs[0]
		var near27 := Vector2(dz27.position.x, dz27.position.z + 2.0)
		main.player.x = near27.x
		main.player.z = near27.y
		dz27.visible = true
		fk.z_slow_left = 0.0
		fk.z_rate = 1.0
		var s0: int = fk.z_slows
		main.player.vx = 3.0 # walking: no slow
		fk.update_z_slow(0.016)
		main.player.vx = 0.0
		fk.update_z_slow(0.016)
		var walk27: bool = fk.z_slows == s0
		main.player.vx = 6.0 # a run ...
		fk.update_z_slow(0.016)
		main.player.vx = 0.0 # ... and a stop
		fk.update_z_slow(0.016)
		var slowed: bool = fk.z_slows == s0 + 1 and fk.z_slow_left > 2.4
		for k in 15:
			fk.update_z_slow(0.1)
		var rate_low: bool = fk.z_rate < 0.45
		for k in 30:
			fk.update_z_slow(0.1)
		var rate_back: bool = fk.z_rate > 0.95 and fk.z_slow_left == 0.0
		var s1: int = fk.z_slows
		main.player.x = near27.x + 20.0 # far off
		main.player.vx = 6.0
		fk.update_z_slow(0.016)
		main.player.vx = 0.0
		fk.update_z_slow(0.016)
		var far27: bool = fk.z_slows == s1
		main.player.x = near27.x
		dz27.visible = false # nobody asleep there
		main.player.vx = 6.0
		fk.update_z_slow(0.016)
		main.player.vx = 0.0
		fk.update_z_slow(0.016)
		var none27: bool = fk.z_slows == s1
		main.hour = h27
		main.in_village = false
		calm_enemies(false)
		check("d27_sleep_z", made27 and walk27 and slowed and rate_low and rate_back and far27 and none27,
			"z labels exist=%s walking: none=%s run then stop: slow for 2.5 s=%s rate falls to 0.4 (%.2f)=%s and recovers=%s far off: none=%s no sleeper shown: none=%s" % [made27, walk27, slowed, fk.z_rate, rate_low, rate_back, far27, none27])
	if want.call("d30_kid_shoes"):
		# two toy-brick shoes (a box with a stud each) lie at the side of the kid goblin's bed with their toes towards it; they show only with her bed, which shows only after Kongal's errand (idea 30)
		var fk30: Object = main.folk
		var shoes: Node3D = fk30.kid_shoes
		var bed30: Node3D = main.sleeper_nodes.get("kid")
		var built30: bool = shoes != null and bed30 != null and shoes.get_parent() == bed30 and shoes.get_child_count() == 2
		var toes: bool = built30 and shoes.get_children().all(func(s): return s.get_child_count() == 1 and s.get_child(0).position.x > 0.0) and shoes.position.x < -0.45
		var kq: int = main.kid_q
		main.kid_q = 0 # not rescued yet
		await wait(0.2)
		var hidden30: bool = built30 and not shoes.is_visible_in_tree()
		fk30.place_sleeper("kid", true)
		var shown30: bool = shoes.is_visible_in_tree() # her bed is shown: so are the shoes
		fk30.place_sleeper("kid", false)
		var gone30: bool = not shoes.is_visible_in_tree()
		var lane30: bool = absf(shoes.position.x) > 0.5 # beside the frame, not on the walk past its foot
		main.kid_q = kq
		check("d30_kid_shoes", built30 and toes and hidden30 and shown30 and gone30 and lane30,
			"two shoes with studs on her bed node=%s toes towards the bed=%s hidden before the rescue=%s shown with her bed=%s hidden with it=%s beside the frame=%s" % [built30, toes, hidden30, shown30, gone30, lane30])
	if want.call("d34_drip_timbre"):
		# in rain, near an eave, a drop lands every 1.2 to 2 s with the nearest anchor's own timbre: bare ground sine 170, tin pail triangle 1568 then 2093; dry, indoors, far, in a story or with a monster near: none (idea 34)
		var ef: Object = main.effects
		marsh_world()
		main.intro = false
		main.in_house = -1
		var tins: Array = ef.drip_anchors.filter(func(a): return a.tin)
		var dirts: Array = ef.drip_anchors.filter(func(a): return not a.tin)
		var built34: bool = tins.size() >= 2 and dirts.size() >= 2
		var tin_at := Vector2(ef.drip_anchors[1].at.x, ef.drip_anchors[1].at.z)
		var dirt_at := Vector2(ef.drip_anchors[0].at.x, ef.drip_anchors[0].at.z)
		main.raining = false
		reset_to(tin_at + Vector2(0.0, 1.5))
		ef.drip_t = 0.0
		var d0: int = ef.rain_drips
		ef.update_rain_drips(0.01)
		var dry34: bool = ef.rain_drips == d0
		main.raining = true
		reset_to(tin_at + Vector2(30.0, 1.5))
		ef.drip_t = 0.0
		ef.update_rain_drips(0.01)
		var far34: bool = ef.rain_drips == d0
		reset_to(tin_at + Vector2(0.0, 1.5))
		main.in_house = 0
		ef.drip_t = 0.0
		ef.update_rain_drips(0.01)
		var in34: bool = ef.rain_drips == d0
		main.in_house = -1
		main.show_story("", ["x"])
		ef.drip_t = 0.0
		ef.update_rain_drips(0.01)
		var story34: bool = ef.rain_drips == d0
		main.close_story()
		main.enemies = [{"x": tin_at.x + 3.0, "z": tin_at.y, "dead": false}]
		ef.drip_t = 0.0
		ef.update_rain_drips(0.01)
		var foe34: bool = ef.rain_drips == d0
		main.enemies = []
		main.sfx_log.clear()
		ef.drip_t = 0.0
		ef.update_rain_drips(0.01)
		var one34: bool = ef.rain_drips == d0 + 1
		ef.update_rain_drips(0.01) # the gap has not passed
		var capped: bool = ef.rain_drips == d0 + 1 and ef.drip_t >= ef.DRIP_GAP_MIN - 0.02
		await wait(0.7)
		var tin_sound: bool = main.sfx_log.has("triangle:1568") and not main.sfx_log.has("sine:170")
		main.raining = false # let the drops in the air land
		await wait(0.6)
		main.raining = true
		reset_to(dirt_at + Vector2(0.0, 1.5))
		main.sfx_log.clear()
		ef.drip_t = 0.0
		ef.update_rain_drips(0.01)
		await wait(0.7)
		var dirt_sound: bool = main.sfx_log.has("sine:170") and not main.sfx_log.has("triangle:1568")
		main.raining = false
		check("d34_drip_timbre", built34 and dry34 and far34 and in34 and story34 and foe34 and one34 and capped and tin_sound and dirt_sound,
			"2 bare and 2 tin anchors=%s none dry=%s far=%s indoors=%s in a story=%s monster near=%s; one drop at a time=%s capped=%s near the pail: tin tone=%s near the bare eave: ground tone=%s" % [built34, dry34, far34, in34, story34, foe34, one34, capped, tin_sound, dirt_sound])
	if want.call("d36_cave_dust"):
		# an ordinary way out of the cave puts two cube grains on her clothes: they brighten for 0.5 s, then fall and are gone by 1.5 s; the first way out (with its story) has none (idea 36)
		var cv: Object = main.cave
		var seen0: bool = main.cave_exit_seen
		var step0: int = main.story_step
		main.close_story()
		main.cave_exit_seen = false
		var g0: int = cv.exit_motes_made
		main.leave_cave()
		var first_quiet: bool = cv.exit_motes_made == g0
		main.close_story()
		main.cave_exit_seen = true
		main.leave_cave()
		var made36: bool = cv.exit_motes_made == g0 + 2
		var grains: Array = main.fx.filter(func(e): return e.node is MeshInstance3D and (e.node.mesh as BoxMesh).size.is_equal_approx(Vector3(0.05, 0.05, 0.05)))
		var count36: bool = grains.size() == 2
		await wait(0.4)
		var near36: bool = grains.size() == 2 and grains.all(func(e): return is_instance_valid(e.node) and Vector2(e.node.position.x - main.player.x, e.node.position.z - main.player.z).length() < 0.6 and e.node.material_override.albedo_color.a > 0.7)
		var y36: float = grains[0].node.position.y if is_instance_valid(grains[0].node) else 0.0
		await wait(0.5)
		var fall36: bool = is_instance_valid(grains[0].node) and grains[0].node.position.y < y36 - 0.05
		await wait(0.8)
		var gone36: bool = not is_instance_valid(grains[0].node) or grains[0].node.is_queued_for_deletion()
		main.cave_exit_seen = seen0
		main.story_step = step0
		check("d36_cave_dust", first_quiet and made36 and count36 and near36 and fall36 and gone36,
			"none on the first way out=%s two grains on a later one=%s/%s bright and on her at 0.4 s=%s falling at 0.9 s=%s gone by 1.7 s=%s" % [first_quiet, made36, count36, near36, fall36, gone36])
	if want.call("d37_tag"):
		# the blank paper tag on the moon-dust stall curls to 0.7 rad and 0.6 height when rain starts and opens again when it stops; each change once; the stalls' buying is not touched (idea 37)
		var mk37: Object = main.market
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		reset_to(main.village.marks["1"] + Vector2(0.0, 6.0))
		main.raining = false
		await wait(1.2)
		var c0: int = mk37.tag_curls
		var flat: bool = mk37.tag != null and is_equal_approx(mk37.tag.rotation.x, 0.0) and is_equal_approx(mk37.tag.scale.y, 1.0)
		main.raining = true
		await wait(1.3)
		var curled: bool = mk37.tag_curls == c0 + 1 and absf(mk37.tag.rotation.x - 0.7) < 0.02 and absf(mk37.tag.scale.y - 0.6) < 0.02
		await wait(1.2)
		var steady: bool = mk37.tag_curls == c0 + 1
		main.raining = false
		await wait(1.3)
		var opened: bool = mk37.tag_curls == c0 + 2 and absf(mk37.tag.rotation.x) < 0.02 and absf(mk37.tag.scale.y - 1.0) < 0.02
		var price_ok: bool = mk37.STALLS["2"].price == 40 and mk37.STALLS["1"].price == 5
		check("d37_tag", flat and curled and steady and opened and price_ok,
			"tag flat when dry=%s curls with rain=%s once=%s opens when it stops=%s prices untouched=%s" % [flat, curled, steady, opened, price_ok])
		main.in_village = false
	if want.call("d38_moon_plaque"):
		# the moon plaque's picture follows the moon: the whole disc when it is full, a smaller lit part otherwise, the waning side flipped; nothing by day (idea 38)
		var lz: Object = main.lake_zone
		var n38: int = lz.PLAQUE_PX
		var full_px := 0
		for py in n38:
			for px in n38:
				var x38 := (px + 0.5) / n38 * 2.0 - 1.0
				var y38 := (py + 0.5) / n38 * 2.0 - 1.0
				if x38 * x38 + y38 * y38 <= 1.0:
					full_px += 1
		var lit := func(img: Image, left: bool) -> int:
			var c := 0
			var x0 := 0 if left else n38 / 2
			var x1 := n38 / 2 if left else n38
			for py in n38:
				for px in range(x0, x1):
					if img.get_pixel(px, py).a > 0.0:
						c += 1
			return c
		var full_img: Image = lz.moon_mask(Vector2(1.0, 1.0), n38)
		var full_ok: bool = lit.call(full_img, true) + lit.call(full_img, false) == full_px
		var half_img: Image = lz.moon_mask(Vector2(0.5, 1.0), n38)
		var half_n: int = lit.call(half_img, true) + lit.call(half_img, false)
		var half_ok: bool = absi(half_n - full_px / 2) < full_px / 8 and lit.call(half_img, false) > lit.call(half_img, true) * 4
		var thin_img: Image = lz.moon_mask(Vector2(0.15, -1.0), n38)
		var thin_n: int = lit.call(thin_img, true) + lit.call(thin_img, false)
		var thin_ok: bool = thin_n > 0 and thin_n < full_px / 4 and lit.call(thin_img, true) > lit.call(thin_img, false) * 4 # waning: the left side
		var h38: float = main.hour
		var d38: int = main.day
		main.hour = 23.0
		main.day = 4 # the full moon (day 4 of 8)
		lz.update_moon_plaque()
		var night_full: bool = lz.plaque.visible and lz.plaque_lit == full_px and main.moon_phase().x == 1.0
		main.day = 2 # waxing
		lz.update_moon_plaque()
		var wax_img: Image = lz.moon_mask(main.moon_phase(), n38)
		var waxing: bool = lz.plaque_lit > 0 and lz.plaque_lit < full_px and lz.plaque_lit == lit.call(wax_img, true) + lit.call(wax_img, false)
		main.hour = 12.0
		lz.update_moon_plaque()
		var day_none: bool = not lz.plaque.visible
		main.hour = h38
		main.day = d38
		check("d38_moon_plaque", full_ok and half_ok and thin_ok and night_full and waxing and day_none,
			"full moon draws all %d pixels=%s half moon about half, on the right=%s thin waning crescent on the left=%s plaque at night on day 4 shows the disc (%d)=%s waxing shows part=%s hidden by day=%s" % [full_px, full_ok, half_ok, thin_ok, lz.plaque_lit, night_full, waxing, day_none])
	if want.call("d39_ribbons"):
		# the ten cloth strips on the wind bridge lift in turn, 0.5 s apart along it, up to 1.1 rad, not together; they stay still while the bridge is not raised; the bridge itself is untouched (idea 39)
		var hz: Object = main.hill_zone
		var built39: bool = hz.ribbons.size() == 10
		var peaks: Array = []
		for i in 5:
			var best_t := 0.0
			var best_a := -1.0
			for k in 320:
				var a: float = hz.ribbon_angle(i, k * 0.01)
				if a > best_a:
					best_a = a
					best_t = k * 0.01
			peaks.append([best_t, best_a])
		var order: bool = true
		for i in range(1, 5):
			order = order and absf(peaks[i][0] - peaks[i - 1][0] - hz.RIBBON_LAG) < 0.03
		var height: bool = peaks.all(func(p): return absf(p[1] - 1.1) < 0.02)
		var apart: bool = hz.ribbon_angle(0, peaks[0][0]) > 1.0 and hz.ribbon_angle(4, peaks[0][0]) == 0.0
		var rails: bool = hz.ribbon_angle(0, 1.7) == hz.ribbon_angle(5, 1.7)
		var vis0: bool = main.hill.bridge.visible
		var bridged0: bool = main.hill.bridged
		var planks0: int = main.hill.bridge.get_child_count()
		main.hill.bridge.visible = false
		for r in hz.ribbons:
			r.rotation.z = 0.0
		hz.update_bridge_ribbons()
		var still: bool = hz.ribbons.all(func(r): return r.rotation.z == 0.0)
		main.hill.bridge.visible = true
		hz.update_bridge_ribbons()
		var moving: bool = hz.ribbons.size() == 10 and absf(hz.ribbons[3].rotation.z - hz.ribbon_angle(3, main.t)) < 0.0001
		main.hill.bridge.visible = vis0
		for r in hz.ribbons:
			r.rotation.z = 0.0
		var untouched: bool = main.hill.bridged == bridged0 and main.hill.bridge.get_child_count() == planks0
		check("d39_ribbons", built39 and order and height and apart and rails and still and moving and untouched,
			"10 strips=%s peaks 0.5 s apart along the bridge=%s each lifts 1.1 rad=%s not together=%s both rails alike=%s still while the bridge is down=%s move once it is up=%s bridge unchanged=%s" % [built39, order, height, apart, rails, still, moving, untouched])
	if want.call("d40_windows"):
		# when a villager has come home at night his house's window pane burns down to 0.25 over 2.6 to 5.0 s (a little different per house); the others stay at 1.5; by day it comes back up (idea 40)
		var vl40: Object = main.village
		var keep40 := {"hour": main.hour, "sleep": main.sleep_off, "mail": main.mail_got[1], "village": main.in_village, "house": main.in_house}
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_village = true
		main.in_house = -1
		main.sleep_off = false
		main.mail_got[1] = false
		main.hour = 12.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		for i in vl40.house_panes.size():
			vl40.pane_set(main, i, true)
		await wait(1.2)
		var panes40: Array = vl40.house_panes
		var built40: bool = not panes40.is_empty() and panes40.size() == vl40.doors.size() and panes40.all(func(p): return is_equal_approx(p.emission_energy_multiplier, 1.5))
		var homes40 := {}
		for id in main.SLEEP_IDS:
			if main.folk_awake_here(id):
				homes40[main.folk_home(id)] = true
		main.hour = 23.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		await wait(0.6)
		var dimming: bool = homes40.keys().all(func(i): return panes40[i].emission_energy_multiplier < 1.45 and panes40[i].emission_energy_multiplier > 0.26)
		var others := true
		for i in panes40.size():
			if not homes40.has(i) and not is_equal_approx(panes40[i].emission_energy_multiplier, 1.5):
				others = false
		var secs := {}
		for i in homes40.keys():
			secs[vl40.pane_dim_secs(i)] = true
		var differ: bool = homes40.size() >= 2 and secs.size() >= 2 and secs.keys().all(func(s): return s >= 2.6 and s <= 5.0)
		await wait(6.0)
		var settled: bool = homes40.keys().all(func(i): return is_equal_approx(panes40[i].emission_energy_multiplier, 0.25))
		main.hour = 12.0
		main.update_folk_sleep(0.0)
		main.update_folk_sleep(30.0)
		await wait(1.3)
		var back40: bool = panes40.all(func(p): return is_equal_approx(p.emission_energy_multiplier, 1.5))
		main.hour = keep40.hour
		main.sleep_off = keep40.sleep
		main.mail_got[1] = keep40.mail
		main.in_village = keep40.village
		main.in_house = keep40.house
		calm_enemies(false)
		check("d40_windows", built40 and dimming and others and differ and settled and back40,
			"one pane per house, all lit=%s homes dim in progress=%s other houses stay lit=%s dim times differ (2.6 to 5.0 s)=%s settle at 0.25=%s lit again by day=%s" % [built40, dimming, others, differ, settled, back40])
	if want.call("d41_wet_steps"):
		# landing from a water skip wets the next three footsteps: splash tones 1000, 880, 760 Hz and ever quieter, then dry again; no landing, no drops (idea 41)
		var sd41: Object = main.sound
		sd41.wet_steps = 0
		sd41.skip_was = false
		sd41.skip_track(false)
		sd41.skip_track(false)
		var dry41: bool = sd41.wet_steps == 0
		sd41.skip_track(true) # skipping over the water ...
		sd41.skip_track(true)
		var still_on: bool = sd41.wet_steps == 0
		sd41.skip_track(false) # ... and onto the bank
		var landed: bool = sd41.wet_steps == 3
		main.sfx_log.clear()
		var seq: Array = []
		for i in 4:
			main.last_step = -10.0
			sd41.footstep()
			seq.append(main.sfx_log.filter(func(s): return s.begins_with("splash:")).size())
		var drops: bool = seq == [1, 2, 3, 3]
		var order41: bool = main.sfx_log.filter(func(s): return s.begins_with("splash:")) == ["splash:1000", "splash:880", "splash:760"]
		var quieter: bool = sd41.WET_VOL[3] > sd41.WET_VOL[2] and sd41.WET_VOL[2] > sd41.WET_VOL[1] and sd41.WET_VOL[1] > 0.0
		check("d41_wet_steps", dry41 and still_on and landed and drops and order41 and quieter and sd41.wet_steps == 0,
			"no drops without a skip=%s none while still skipping=%s landing wets 3 steps=%s three drops, a fourth step dry=%s in order 1000/880/760=%s each quieter=%s" % [dry41, still_on, landed, drops, order41, quieter])
	if want.call("d42_chest_knock"):
		# a chest's lid knocks deep (147 then 220) for loot and higher (262 then 392) when little is left; the field chest, which always holds gold and a potion, knocks deep (idea 42)
		var sd42: Object = main.sound
		main.sfx_log.clear()
		sd42.chest_knock(true)
		await wait(0.2)
		var deep: bool = main.sfx_log.has("triangle:147") and main.sfx_log.has("triangle:220") and not main.sfx_log.has("triangle:262")
		main.sfx_log.clear()
		sd42.chest_knock(false)
		await wait(0.2)
		var light: bool = main.sfx_log.has("triangle:262") and main.sfx_log.has("triangle:392") and not main.sfx_log.has("triangle:147")
		marsh_world()
		main.intro = false
		var c42: Dictionary = main.chests[0]
		var open42: bool = c42.open
		var gold42: int = main.player.gold
		var pots42: int = main.player.pots
		c42.open = false
		reset_to(Vector2(c42.x, c42.z))
		main.sfx_log.clear()
		main.interact()
		await wait(0.2)
		var field: bool = c42.open and main.player.gold > gold42 and main.player.pots == pots42 + 1 and main.sfx_log.has("triangle:147") and main.sfx_log.has("triangle:220")
		c42.open = open42
		if not open42:
			c42.node.texture = main.chest_shut_tex
		main.player.gold = gold42
		main.player.pots = pots42
		calm_enemies(false)
		check("d42_chest_knock", deep and light and field,
			"loot knock 147/220=%s thin knock 262/392=%s the field chest opens with the deep one=%s" % [deep, light, field])
	if want.call("d44_mill_creak"):
		# the moment the sails stop, with her at the mill, the shaft creaks once: two falling triangle tones; still turning, far from the mill, or already stopped: nothing (idea 44)
		var hz44: Object = main.hill_zone
		var sd44: Object = main.sound
		hz44.mill_was_turning = false
		var n0: int = sd44.mill_creaks
		hz44.mill_edge(true, true)
		hz44.mill_edge(true, true)
		var turning_quiet: bool = sd44.mill_creaks == n0
		hz44.mill_edge(false, false) # stopped while she is away
		var far_quiet: bool = sd44.mill_creaks == n0 and not hz44.mill_was_turning
		hz44.mill_edge(true, true)
		main.sfx_log.clear()
		hz44.mill_edge(false, true)
		var creaked: bool = sd44.mill_creaks == n0 + 1 and main.sfx_log.has("triangle:210")
		await wait(0.25)
		var second: bool = main.sfx_log.has("triangle:168")
		hz44.mill_edge(false, true) # already stopped
		var once44: bool = sd44.mill_creaks == n0 + 1
		check("d44_mill_creak", turning_quiet and far_quiet and creaked and second and once44,
			"turning: none=%s stopped while away: none=%s stops at the mill: one creak (210)=%s then 168=%s only once=%s" % [turning_quiet, far_quiet, creaked, second, once44])
	if want.call("d49_clack"):
		# a struck brick clacks 620, 740, 880, 620 Hz in turn, nothing twice inside 0.06 s, each target counting for itself (idea 49)
		main.close_story()
		main.intro = false
		reset_to(Vector2(30, 30))
		var curl49 := {"curl": 5.0, "x": 31.0, "z": 30.0}
		var shield49 := {"shield": 9, "x": 33.0, "z": 30.0}
		main.sfx_log.clear()
		for i in 4:
			main.damage_enemy(curl49, 5.0, Vector2(30, 30))
			if i == 0:
				main.damage_enemy(curl49, 5.0, Vector2(30, 30)) # the same frame: swallowed
			await wait(0.1)
		var sq: Array = main.sfx_log.filter(func(s): return s in ["square:620", "square:740", "square:880"])
		var cycle: bool = sq == ["square:620", "square:740", "square:880", "square:620"]
		main.sfx_log.clear()
		main.damage_enemy(shield49, 5.0, Vector2(30, 30))
		var own: bool = main.sfx_log.has("square:620") and shield49.shield == 8
		var old_gone: bool = not main.sfx_log.has("square:700")
		check("d49_clack", cycle and own and old_gone,
			"four blows ring 620/740/880/620 with the same-frame one swallowed=%s another brick starts at 620=%s the old single 700 is gone=%s (%s)" % [cycle, own, old_gone, sq])
	if want.call("d51_stud"):
		# a plain block (not a flash guard, not a hit from behind) drops one stud in front of her: it falls, spins like a top until about 1 s, lies still and is gone by 1.6 s; no loot, no new foe (idea 51)
		main.close_story()
		main.intro = false
		calm_enemies(true)
		var fx51: Object = main.effects
		var gold51: int = main.player.gold
		var pots51: int = main.player.pots
		var foes51: int = main.enemies.size()
		reset_to(Vector2(30, 30))
		var y51: float = main.ground_y
		main.player.face = Vector2(1, 0)
		main.player.sp = 100.0
		main.flash_cd = 0.0
		main.guarding = true
		main.guard_since = main.t - 1.0
		var s0: int = fx51.studs_made
		var r51: String = main.player_hit(10, Vector2(31, 30), dummy)
		var made: bool = r51 == "guard" and fx51.studs_made == s0 + 1
		var stud: Node3D = fx51.last_stud
		var ahead: bool = absf(stud.position.x - 30.9) < 0.05 and absf(stud.position.z - 30.0) < 0.05 and stud.position.y > y51 + 0.8
		reset_to(Vector2(30, 30)) # a flash guard, a hit from behind and no guard at all: no stud
		main.guarding = true
		main.guard_since = main.t
		var rf: String = main.player_hit(10, Vector2(31, 30), dummy)
		reset_to(Vector2(30, 30))
		main.guarding = true
		main.guard_since = main.t - 1.0
		var rb: String = main.player_hit(10, Vector2(29, 30), dummy)
		reset_to(Vector2(30, 30))
		main.guarding = false
		var rn: String = main.player_hit(10, Vector2(31, 30), dummy)
		var quiet51: bool = rf == "flash_guard" and rb == "hit" and rn == "hit" and fx51.studs_made == s0 + 1
		await wait(0.5)
		var low: bool = stud.position.y < y51 + 0.2
		var y_a: float = stud.rotation.y
		await wait(0.1)
		var spins: bool = absf(stud.rotation.y - y_a) > 0.3
		await wait(0.7)
		var y_b: float = stud.rotation.y
		await wait(0.1)
		var rests: bool = is_equal_approx(stud.rotation.y, y_b) and stud.position.y < y51 + 0.2
		await wait(0.6)
		var gone: bool = not is_instance_valid(stud)
		var nothing: bool = main.player.gold == gold51 and main.player.pots == pots51 and main.enemies.size() == foes51
		calm_enemies(false)
		check("d51_stud", made and ahead and quiet51 and low and spins and rests and gone and nothing,
			"plain block drops one stud=%s (%s) in front of her=%s flash guard / behind / unguarded: none=%s on the ground by 0.5 s=%s spinning then=%s still at 1.3 s=%s gone by 1.9 s=%s no loot or foe=%s" % [made, r51, ahead, quiet51, low, spins, rests, gone, nothing])
	if want.call("d52_wall_dust"):
		# a goblin's lunge stopped by a wall shakes three grains of dust loose from it, once per lunge; a lunge into open ground makes none (idea 52)
		var fx52: Object = main.effects
		main.close_story()
		main.intro = false
		calm_enemies(true)
		park_mates(true)
		var C52 := open_field()
		reset_to(C52)
		var wall := Vector2(-1, -1)
		for gz in range(12, 56):
			for gx in range(8, 46):
				var p := Vector2(gx + 0.5, gz + 0.5)
				if wall.x < 0.0 and main.walkable(p.x, p.y) and not main.walkable(p.x + 1.0, p.y) and not main.walkable(p.x + 1.0, p.y + 0.3) and not main.walkable(p.x + 1.0, p.y - 0.3):
					var x := p.x
					while main.walkable(x + 0.05, p.y):
						x += 0.05
					wall = Vector2(x, p.y)
		var found: bool = wall.x >= 0.0
		var blocked_dust := 0
		var open_dust := 0
		if found:
			for trial in 2:
				reset_to(C52 + Vector2(0, 7.0)) # Sora is well away from the cut
				var at52: Vector2 = wall if trial == 0 else C52
				main.spawn_enemy(at52)
				var g: Dictionary = main.enemies[main.enemies.size() - 1]
				g.cave = true
				g.hp = 99999.0
				g.atk_cd = 99.0
				g.x = at52.x
				g.z = at52.y
				g.ldir = Vector2(1, 0)
				g.ldash = 0.15
				var w0: int = fx52.wall_dusts
				await wait(0.5)
				if trial == 0:
					blocked_dust = fx52.wall_dusts - w0
				else:
					open_dust = fx52.wall_dusts - w0
				g.dead = true
				g.node.queue_free()
				g.shadow.queue_free()
		reset_to(C52)
		calm_enemies(false)
		park_mates(false)
		check("d52_wall_dust", found and blocked_dust == 1 and open_dust == 0,
			"a wall edge found=%s a lunge into it makes one burst of dust (%d)=%s a lunge over open ground makes none (%d)" % [found, blocked_dust, blocked_dust == 1, open_dust])
	if want.call("d54_release_dust"):
		# letting go of a charged cut shoves eight grains of dust outward from her feet at once, and the light follows 0.06 s later (idea 54)
		var fx54: Object = main.effects
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_village = false
		reset_to(Vector2(30, 30))
		main.player.face = Vector2(1, 0)
		var r0: int = fx54.release_dusts
		var n54: int = main.fx.size()
		main.combat.charged_slash()
		var dust_now: bool = fx54.release_dusts == r0 + 1 and main.fx.size() == n54 + 8
		var grains: Array = main.fx.slice(n54, n54 + 8).map(func(f): return f.node)
		await wait(0.3)
		var out54: bool = grains.all(func(g): return is_instance_valid(g) and Vector2(g.position.x - 30.0, g.position.z - 30.0).length() > 0.9)
		await wait(1.0) # all of it has faded
		main.player.atk_cd = 0.0
		var f0: int = main.fx.size()
		main.combat.charged_slash()
		var only_dust: bool = main.fx.size() == f0 + 8
		await wait(0.12)
		var light_after: bool = main.fx.size() > f0 + 8
		calm_enemies(false)
		check("d54_release_dust", dust_now and out54 and only_dust and light_after,
			"eight grains of dust appear with the release=%s gone out past 0.9 tiles by 0.3 s=%s right after it only the dust is there=%s the light joins within 0.12 s=%s" % [dust_now, out54, only_dust, light_after])
	if want.call("d55_calm"):
		# the last foe within 12 tiles falls: the motes' gravity drops to -0.5 and returns to 0.05 by 3 s; a foe left near, walking off, or nothing killed: no change (idea 55)
		var mo: Object = main.monsters
		var fx55: Object = main.effects
		main.close_story()
		main.intro = false
		reset_to(Vector2(30, 30))
		var saved55: Array = main.enemies
		var foe := {"x": 33.0, "z": 30.0, "dead": false}
		var foe2 := {"x": 34.0, "z": 31.0, "dead": false}
		var c0: int = fx55.calms
		var k0: int = main.stats.kills
		mo.kills_prev = k0
		mo.kill_seen_t = -10.0
		main.enemies = [foe, foe2]
		mo.foes_near_prev = false
		mo.update_calm()
		foe.x = 60.0 # both walk off, nothing killed
		foe2.x = 60.0
		mo.update_calm()
		var walked: bool = fx55.calms == c0
		foe.x = 33.0
		foe2.x = 34.0
		mo.update_calm()
		foe.dead = true # one of two falls: one is still near
		main.stats.kills += 1
		mo.update_calm()
		var two: bool = fx55.calms == c0
		foe2.dead = true # the last falls
		main.stats.kills += 1
		mo.update_calm()
		var settled55: bool = fx55.calms == c0 + 1
		main.enemies = saved55
		main.stats.kills = k0
		mo.kills_prev = k0
		mo.foes_near_prev = false
		await wait(0.7)
		var low55: bool = main.motes.gravity.y < -0.3
		await wait(3.0)
		var back55: bool = is_equal_approx(main.motes.gravity.y, 0.05)
		check("d55_calm", walked and two and settled55 and low55 and back55,
			"both walk off: none=%s one of two falls: none=%s the last falls: settles=%s gravity low=%s (%.2f) back to 0.05=%s" % [walked, two, settled55, low55, main.motes.gravity.y, back55])
	if want.call("d57_air_whiff"):
		# swinging twice in a row (within 3 s) at a foe that is in reach but in the air shows the hint once; a third swing, a cut that lands on a low foe, or an air foe out of reach: none (idea 57)
		var cb: Object = main.combat
		main.close_story()
		main.intro = false
		main.in_village = false
		main.guarding = false
		calm_enemies(true)
		reset_to(Vector2(30, 30))
		var saved57: Array = main.enemies
		var hawk := {"x": 31.0, "z": 30.0, "dead": false, "air": true}
		var low57 := {"x": 31.0, "z": 30.0, "dead": false, "shield": 99}
		main.enemies = [hawk]
		cb.air_whiffs = 0
		cb.air_whiff_t = -10.0
		cb.air_hint_t = -10.0
		var h0: int = cb.air_hints
		var swing := func():
			main.player.atk_cd = 0.0
			main.player.face = Vector2(1, 0)
			main.player.combo_t = 0.0
			main.attack()
		main.ui.toast.text = ""
		swing.call()
		var first: bool = cb.air_hints == h0 and main.ui.toast.text == ""
		swing.call()
		var second: bool = cb.air_hints == h0 + 1 and plain(main.ui.toast.text).contains("높이")
		main.ui.toast.text = ""
		swing.call()
		var third: bool = cb.air_hints == h0 + 1 and main.ui.toast.text == ""
		cb.air_whiffs = 0 # a low foe stands there too: the cut lands, so it is no whiff
		cb.air_hint_t = -10.0
		main.enemies = [hawk, low57]
		swing.call()
		swing.call()
		var landed: bool = cb.air_hints == h0 + 1 and cb.air_whiffs == 0
		hawk.x = 36.0 # in the air but out of reach
		main.enemies = [hawk]
		swing.call()
		swing.call()
		var far57: bool = cb.air_hints == h0 + 1
		main.enemies = saved57
		main.ui.toast.text = ""
		calm_enemies(false)
		check("d57_air_whiff", first and second and third and landed and far57,
			"first miss silent=%s second shows the hint=%s third silent=%s a cut that lands resets=%s out of reach: none=%s" % [first, second, third, landed, far57])

	# ---- delight100 batch S4 (items 58 59 60 63 64 66 67 68 69 70)
	if want.call("d58_screw"):
		# a flash guard against a foe lets one screw hop out of its seam and come back (gone by 0.9 s); a plain block, a second flash guard inside 1 s, and a source that is no foe: none; nothing else changes (idea 58)
		main.close_story()
		main.intro = false
		calm_enemies(true)
		var fx58: Object = main.effects
		var gold58: int = main.player.gold
		var pots58: int = main.player.pots
		reset_to(Vector2(30, 30))
		main.player.face = Vector2(1, 0)
		main.player.sp = 100.0
		main.flash_cd = 0.0
		var foe58 := {"x": 31.0, "z": 30.0, "dead": false}
		main.guarding = true
		main.guard_since = main.t - 1.0
		var s0: int = fx58.screws
		var plain58: String = main.player_hit(10, Vector2(31, 30), foe58)
		var no_plain: bool = plain58 == "guard" and fx58.screws == s0
		reset_to(Vector2(30, 30))
		main.guarding = true
		main.guard_since = main.t
		fx58.screw_t = -10.0
		var r58: String = main.player_hit(10, Vector2(31, 30), foe58)
		var made58: bool = r58 == "flash_guard" and fx58.screws == s0 + 1
		var screw: Node3D = fx58.last_screw
		var base_y: float = main.height_at(31.0, 30.0) + 0.7
		await wait(0.35)
		var out_d: float = Vector2(screw.position.x - 31.0, screw.position.z - 30.0).length()
		var jumped: bool = out_d > 0.25 and screw.position.y > base_y
		await wait(0.6)
		var returned: bool = not is_instance_valid(screw) or screw.is_queued_for_deletion() or Vector3(screw.position.x - 31.0, screw.position.y - base_y, screw.position.z - 30.0).length() < 0.4
		reset_to(Vector2(30, 30)) # a second flash guard 0.1 s after: still one screw
		main.guarding = true
		main.guard_since = main.t
		fx58.screw_t = main.t - 0.1
		var second58: String = main.player_hit(10, Vector2(31, 30), foe58)
		var once58: bool = second58 == "flash_guard" and fx58.screws == s0 + 1
		reset_to(Vector2(30, 30)) # the source is no foe
		main.guarding = true
		main.guard_since = main.t
		fx58.screw_t = -10.0
		var third58: String = main.player_hit(10, Vector2(31, 30), dummy)
		var nofoe: bool = third58 == "flash_guard" and fx58.screws == s0 + 1
		var untouched58: bool = main.player.gold == gold58 and main.player.pots == pots58 and not foe58.has("hp")
		main.guarding = false
		calm_enemies(false)
		check("d58_screw", no_plain and made58 and jumped and returned and once58 and nofoe and untouched58,
			"a plain block: none=%s flash guard: one screw=%s it leaves the seam (%.2f out, above the belt)=%s it is back or gone by 0.9 s=%s a second one inside 1 s: none=%s no foe: none=%s no loot or damage change=%s" % [no_plain, made58, out_d, jumped, returned, once58, nofoe, untouched58])
	if want.call("d59_revive_bow"):
		# a companion who gets up within 6 tiles of Sora bows once (0.45 s); far away, or with a story open: no bow; her stepping off ends it at once (idea 59)
		var mt59: Object = main.mates
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.join_mate()
		main.join_noeul()
		reset_to(Vector2(30, 30))
		main.snap_mates()
		main.mate2.position = Vector3(32, 0, 30)
		main.mate2.visible = true
		var b0: int = mt59.revive_dips
		main.folk.nod_t["noeul"] = 0.0
		main.mate_down["noeul"] = 0.05
		mt59.mate_tick("noeul", 0.1)
		var bowed: bool = mt59.revive_dips == b0 + 1 and is_equal_approx(main.folk.nod_t["noeul"], main.folk.NOD_T)
		main.player.vx = 3.0
		mt59.mate_tick("noeul", 0.1)
		var cancelled: bool = main.folk.nod_t["noeul"] <= 0.0
		main.player.vx = 0.0
		main.mate2.position = Vector3(45, 0, 30) # far away
		main.mate_down["noeul"] = 0.05
		mt59.mate_tick("noeul", 0.1)
		var far59: bool = mt59.revive_dips == b0 + 1 and main.folk.nod_t["noeul"] <= 0.0
		main.mate2.position = Vector3(32, 0, 30)
		main.show_story("", ["x"])
		main.mate_down["noeul"] = 0.05
		mt59.mate_tick("noeul", 0.1)
		var story59: bool = mt59.revive_dips == b0 + 1 and main.folk.nod_t["noeul"] <= 0.0
		main.close_story()
		main.mate_down["noeul"] = 0.0
		calm_enemies(false)
		check("d59_revive_bow", bowed and cancelled and far59 and story59,
			"gets up near her: one bow of %.2f s=%s she steps off: it ends=%s far away: none=%s story open: none=%s" % [main.folk.NOD_T, bowed, cancelled, far59, story59])
	if want.call("d60_breath_word"):
		# the last foe falling opens one 'breathe first' line; the first villager she speaks to says it before the normal answer (the answer still comes); a second talk, or one after 45 s: nothing (idea 60)
		var ch60: Object = main.chatter
		var mo60: Object = main.monsters
		main.close_story()
		main.intro = false
		main.in_village = true
		main.in_house = -1
		calm_enemies(true)
		var saved60: Array = main.enemies
		reset_to(Vector2(30, 30))
		var foe60 := {"x": 33.0, "z": 30.0, "dead": false}
		var k60: int = main.stats.kills
		mo60.kills_prev = k60
		mo60.kill_seen_t = -10.0
		mo60.foes_near_prev = false
		ch60.breath_open = false
		main.enemies = [foe60]
		mo60.update_calm()
		foe60.dead = true
		main.stats.kills += 1
		mo60.update_calm()
		var opened: bool = ch60.breath_open
		main.enemies = saved60
		main.stats.kills = k60
		mo60.kills_prev = k60
		mo60.foes_near_prev = false
		var id60 := "tori"
		var keep60 := {"hour": main.hour, "state": main.folk_state.get(id60, "out")}
		main.hour = 12.0
		main.folk_state[id60] = "out"
		var met60: bool = main.met.has(id60)
		var n60: int = ch60.breath_says
		reset_to(main.folk_talk_at(id60))
		main.crown_key()
		var said: bool = ch60.breath_says == n60 + 1 and not ch60.breath_open and main.folk_said.back()[0] == id60 and plain(str(main.folk_said.back()[1])).contains("숨부터")
		var answered: bool = main.story_open
		main.close_story()
		main.crown_key()
		var once60: bool = ch60.breath_says == n60 + 1
		main.close_story()
		ch60.fight_ended() # 50 s later: too old
		ch60.fight_end_t = main.t - 50.0
		main.crown_key()
		var stale: bool = ch60.breath_says == n60 + 1 and not ch60.breath_open
		main.close_story()
		main.hour = keep60.hour
		main.folk_state[id60] = keep60.state
		if not met60:
			main.met.erase(id60)
		main.in_village = false
		calm_enemies(false)
		check("d60_breath_word", opened and said and answered and once60 and stale,
			"a fight ends: the line is open=%s the first villager says it=%s his normal answer still comes=%s only once=%s too late (50 s): not said=%s" % [opened, said, answered, once60, stale])
	if want.call("d63_umbrella"):
		# resting under a stall's awning in rain, she starts the umbrella act, shows only its first frame for 1 s and goes back to breathing; dry, away, in a story, or the second rest of the same visit: none (idea 63)
		var s63: Object = main.sora
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_village = true
		main.in_house = -1
		main.raining = true
		s63.spot_visit.clear()
		s63.idle_cause = ""
		var at63: Vector2 = main.village.marks["1"]
		reset_to(at63)
		main.last_input_t = main.t - 20.0
		var n63: int = s63.spot_acts
		main.idle_name = "breath"
		main.idle_left = 0.0
		s63.update_idle(0.01)
		var started: bool = main.idle_name == "rest-umbrella" and s63.idle_cause == "shelter" and s63.spot_acts == n63 + 1 and is_equal_approx(main.idle_left, 1.0)
		s63.update_idle(0.6)
		var frame0: bool = main.hero.region_rect.position.x == 0.0 and main.idle_name == "rest-umbrella"
		s63.update_idle(0.5)
		var back63: bool = main.idle_name == "breath" and s63.idle_cause == ""
		var again: bool = s63.spot_pick() == "" and s63.spot_acts == n63 + 1
		reset_to(at63 + Vector2(6.0, 6.0))
		s63.spot_pick()
		main.raining = false
		reset_to(at63)
		var dry63: bool = s63.spot_pick() == "" and s63.spot_acts == n63 + 1
		main.raining = true
		reset_to(at63 + Vector2(6.0, 6.0))
		s63.spot_pick()
		main.show_story("", ["x"])
		reset_to(at63)
		var story63: bool = s63.spot_pick() == "" and s63.spot_acts == n63 + 1
		main.close_story()
		reset_to(at63 + Vector2(6.0, 6.0))
		var away63: bool = s63.spot_pick() == "" and s63.spot_acts == n63 + 1
		main.raining = false
		main.in_village = false
		main.idle_name = ""
		s63.idle_cause = ""
		calm_enemies(false)
		check("d63_umbrella", started and frame0 and back63 and again and dry63 and story63 and away63,
			"under the awning in rain: umbrella act, 1 s=%s only its first frame=%s then breathing=%s not twice in a visit=%s dry: none=%s story: none=%s away: none=%s" % [started, frame0, back63, again, dry63, story63, away63])
	if want.call("d64_photo"):
		# at a hill view (and on the cloud mound) she picks the photo act once a visit with one shutter cue (two clicks); away, or on the plain hill: none (idea 64)
		var s64: Object = main.sora
		var sd64: Object = main.sound
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_hill = true
		main.in_village = false
		s64.spot_visit.clear()
		var view64: Vector2 = main.hill_zone.SCENIC[0].at
		reset_to(view64 + Vector2(0.5, 0.0))
		main.last_input_t = main.t - 20.0
		var n64: int = s64.spot_acts
		var c64: int = sd64.shutters
		main.sfx_log.clear()
		main.idle_name = "breath"
		main.idle_left = 0.0
		s64.update_idle(0.01)
		var picked: bool = main.idle_name == "rest-photo" and s64.idle_cause == "photo" and s64.spot_acts == n64 + 1
		var cue: bool = sd64.shutters == c64 + 1 and main.sfx_log.has("square:2600")
		main.idle_left = 0.0
		s64.update_idle(0.01) # the act ends, breathing again
		main.idle_left = 0.0
		s64.update_idle(0.01)
		var once64: bool = s64.spot_acts == n64 + 1 and sd64.shutters == c64 + 1
		reset_to(view64 + Vector2(8.0, 0.0))
		s64.spot_pick()
		reset_to(view64)
		var again64: bool = s64.spot_pick() == "rest-photo"
		var view2: Vector2 = main.hill_zone.SCENIC[1].at
		reset_to(view2)
		var second64: bool = s64.spot_pick() == "rest-photo"
		reset_to(Vector2(view64.x - 12.0, view64.y + 6.0))
		var plain64: bool = s64.spot_pick() == ""
		reset_to(main.cloud.marks.c)
		var cloud64: bool = main.in_cloud() and s64.spot_pick() == "rest-photo"
		main.in_hill = false
		reset_to(view64)
		var nohill: bool = s64.spot_pick() == ""
		main.idle_name = ""
		s64.idle_cause = ""
		calm_enemies(false)
		check("d64_photo", picked and cue and once64 and again64 and second64 and plain64 and cloud64 and nohill,
			"at the view: photo act=%s one shutter cue=%s once a visit=%s again on a new visit=%s the second view=%s the plain hill: none=%s the cloud mound=%s off the hill: none=%s" % [picked, cue, once64, again64, second64, plain64, cloud64, nohill])
	if want.call("d66_hush"):
		# beside a sleeping villager's bed in his house she picks the hush act once a visit; he awake, outside the house, 3.5 tiles off, or a story open: none (idea 66)
		var s66: Object = main.sora
		main.close_story()
		main.intro = false
		calm_enemies(true)
		var keep66 := {"village": main.in_village, "house": main.in_house, "state": main.folk_state.get("doran", "out")}
		main.in_village = true
		var home66: int = main.folk.folk_home("doran")
		main.in_house = home66
		main.folk_state["doran"] = "in"
		s66.spot_visit.clear()
		var bed66: Vector2 = main.folk.bed_spot("doran")
		reset_to(bed66 + Vector2(0.8, 0.0))
		main.last_input_t = main.t - 20.0
		var n66: int = s66.spot_acts
		main.idle_name = "breath"
		main.idle_left = 0.0
		s66.update_idle(0.01)
		var hushed: bool = main.idle_name == "see-hush" and s66.idle_cause == "hush" and s66.spot_acts == n66 + 1
		var once66: bool = s66.spot_pick() == "" and s66.spot_acts == n66 + 1
		reset_to(bed66 + Vector2(3.5, 0.0))
		var far66: bool = s66.spot_pick() == "" and not main.folk.sleeper_near(Vector2(main.player.x, main.player.z))
		reset_to(bed66 + Vector2(0.8, 0.0))
		main.folk_state["doran"] = "out"
		var awake: bool = s66.spot_pick() == ""
		main.folk_state["doran"] = "in"
		main.in_house = -1
		var outside: bool = s66.spot_pick() == ""
		main.in_house = home66
		s66.spot_visit.clear()
		main.show_story("", ["x"])
		var story66: bool = s66.spot_pick() == ""
		main.close_story()
		var back66: bool = s66.spot_pick() == "see-hush"
		main.folk_state["doran"] = keep66.state
		main.in_village = keep66.village
		main.in_house = keep66.house
		main.idle_name = ""
		s66.idle_cause = ""
		calm_enemies(false)
		check("d66_hush", hushed and once66 and far66 and awake and outside and story66 and back66,
			"beside the sleeper: hush act=%s once a visit=%s 3.5 tiles off: none=%s he awake: none=%s outside the house: none=%s story: none=%s and back again=%s" % [hushed, once66, far66, awake, outside, story66, back66])
	if want.call("d67_pond_drop"):
		# at the village pier she drinks (rest-water); when the act runs to its end one drop falls at her feet; a move before the end leaves none; away from the pond: none (idea 67)
		var s67: Object = main.sora
		var fx67: Object = main.effects
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_village = true
		main.in_house = -1
		s67.spot_visit.clear()
		var pier: Vector2 = main.village.marks.f
		reset_to(pier)
		main.last_input_t = main.t - 20.0
		var n67: int = s67.spot_acts
		var d0: int = fx67.pond_drops
		main.idle_name = "breath"
		main.idle_left = 0.0
		s67.update_idle(0.01)
		var drinking: bool = main.idle_name == "rest-water" and s67.idle_cause == "pond" and s67.spot_acts == n67 + 1
		s67.update_idle(5.0)
		var not_yet: bool = fx67.pond_drops == d0 and main.idle_name == "rest-water"
		s67.update_idle(5.0)
		var dropped: bool = fx67.pond_drops == d0 + 1 and main.idle_name == "breath"
		var drop: Node3D = fx67.last_drop
		var at_feet: bool = absf(drop.position.x - main.player.x) < 0.5 and absf(drop.position.z - main.player.z) < 0.5 and drop.position.y > main.ground_y + 0.3
		await wait(0.4)
		var landed: bool = not is_instance_valid(drop) or drop.is_queued_for_deletion() or not drop.visible or drop.position.y < main.ground_y + 0.15
		reset_to(pier + Vector2(8.0, 0.0)) # a new visit, cut short by a step
		s67.spot_pick()
		reset_to(pier)
		main.idle_name = "breath"
		main.idle_left = 0.0
		s67.update_idle(0.01)
		var again67: bool = main.idle_name == "rest-water"
		s67.update_idle(3.0)
		main.idle_name = "" # she moved: update_idle is not called any more
		var cut: bool = fx67.pond_drops == d0 + 1
		reset_to(pier + Vector2(8.0, 0.0))
		var away67: bool = s67.spot_pick() == ""
		main.in_village = false
		main.idle_name = ""
		s67.idle_cause = ""
		calm_enemies(false)
		check("d67_pond_drop", drinking and not_yet and dropped and at_feet and landed and again67 and cut and away67,
			"at the pier: drinking=%s no drop mid-act=%s one drop at the end=%s at her feet, falling=%s it lands=%s again on a new visit=%s cut short: no drop=%s away: none=%s" % [drinking, not_yet, dropped, at_feet, landed, again67, cut, away67])
	if want.call("d68_moon_ring"):
		# at a moon-stairs landing she looks up (see-up) and a thin ring floats over her crown for 3.6 s, with no light; elsewhere on the stairs or outside them: none (idea 68)
		var s68: Object = main.sora
		var fx68: Object = main.effects
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_hill = true
		main.in_village = false
		s68.spot_visit.clear()
		var sx: float = main.STAIRS.STAIRS_X
		reset_to(Vector2(sx + 4.0, 13.0))
		main.last_input_t = main.t - 20.0
		var n68: int = s68.spot_acts
		var r0: int = fx68.moon_rings
		main.idle_name = "breath"
		main.idle_left = 0.0
		s68.update_idle(0.01)
		var up: bool = main.idle_name == "see-up" and s68.idle_cause == "moon" and s68.spot_acts == n68 + 1
		var ring: Node3D = fx68.last_moon_ring
		await wait(0.3)
		var floats: bool = fx68.moon_rings == r0 + 1 and absf(ring.position.y - (main.ground_y + 2.1)) < 0.1 and absf(ring.position.x - main.player.x) < 0.05
		var dark: bool = ring is MeshInstance3D and ring.get_child_count() == 0
		await wait(3.7)
		var gone: bool = not is_instance_valid(ring) or ring.is_queued_for_deletion()
		reset_to(Vector2(sx + 11.0, 9.0))
		var mid68: bool = s68.spot_pick() == ""
		reset_to(Vector2(sx + 19.0, 21.0)) # the other side of another landing
		var other: bool = s68.spot_pick() == "see-up"
		main.in_hill = false
		reset_to(Vector2(30, 30))
		var out68: bool = s68.spot_pick() == ""
		main.idle_name = ""
		s68.idle_cause = ""
		calm_enemies(false)
		check("d68_moon_ring", up and floats and dark and gone and mid68 and other and out68,
			"at a landing: look up=%s ring 2.1 above her=%s no light=%s gone after 3.6 s=%s mid-landing: none=%s another landing=%s outside the stairs: none=%s" % [up, floats, dark, gone, mid68, other, out68])
	if want.call("d69_inn_stretch"):
		# coming out of the inn marks one stretch: her first safe rest after it is rest-stretch (only once); the marker is set by a night at the inn (idea 69)
		var s69: Object = main.sora
		var mk69: Object = main.market
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_village = true
		main.in_house = -1
		mk69.inn_fresh = false
		var keep69 := {"gold": main.player.gold, "hour": main.hour, "day": main.day, "nights": main.inn_nights}
		main.player.gold = 30
		main.inn_nights = 2 # not the first night: no talk
		reset_to(main.village.marks.N + Vector2(0.0, 1.5))
		mk69.stay_inn()
		await wait(0.8)
		var marked: bool = mk69.inn_fresh
		s69.spot_visit.clear()
		var spot_n: int = s69.spot_acts
		reset_to(Vector2(30, 30))
		var pick: String = s69.idle_pick()
		var stretch: bool = pick == "rest-stretch" and s69.idle_cause == "inn" and not mk69.inn_fresh and s69.spot_acts == spot_n
		s69.idle_cause = "" # update_idle clears it before each pick
		var later: String = s69.idle_pick() # back to the random pool
		var pool: bool = s69.idle_cause == "" and not mk69.inn_fresh and later != ""
		mk69.inn_fresh = true # a story is open: the marker is kept
		main.show_story("", ["x"])
		s69.idle_pick()
		var story69: bool = mk69.inn_fresh
		main.close_story()
		mk69.inn_fresh = false
		main.player.gold = keep69.gold
		main.hour = keep69.hour
		main.day = keep69.day
		main.inn_nights = keep69.nights
		main.in_village = false
		s69.idle_cause = ""
		calm_enemies(false)
		check("d69_inn_stretch", marked and stretch and pool and story69,
			"a night at the inn marks it=%s the first rest after: stretch=%s then the random pool=%s a story keeps the marker=%s" % [marked, stretch, pool, story69])
	if want.call("d70_run_water"):
		# a run of 3 s or more that ends at full health makes her next rest (within 40 s) a drink with one bottle-cap cue; a short run, a hurt Sora, or a stale thirst: none; no stat changes (idea 70)
		var s70: Object = main.sora
		var sd70: Object = main.sound
		main.close_story()
		main.intro = false
		calm_enemies(true)
		main.in_village = false
		main.in_hill = false
		s70.spot_visit.clear()
		reset_to(Vector2(30, 30))
		s70.run_t = 0.0
		s70.run_thirst = false
		for i in 20: # 2 s: too short
			s70.track_run(true, 0.1)
		s70.track_run(false, 0.1)
		var short70: bool = not s70.run_thirst
		for i in 35: # 3.5 s
			s70.track_run(true, 0.1)
		s70.track_run(false, 0.1)
		var thirsty: bool = s70.run_thirst
		var hp70: float = main.player.hp
		var sp70: float = main.player.sp
		var mp70: float = main.player.mp
		var caps: int = sd70.bottle_caps
		main.last_input_t = main.t - 20.0
		main.sfx_log.clear()
		main.idle_name = "breath"
		main.idle_left = 0.0
		s70.update_idle(0.01)
		var drink: bool = main.idle_name == "rest-water" and s70.idle_cause == "run" and not s70.run_thirst
		var cue: bool = sd70.bottle_caps == caps + 1 and main.sfx_log.has("triangle:1320")
		var same: bool = main.player.hp == hp70 and main.player.sp == sp70 and main.player.mp == mp70
		s70.update_idle(10.0)
		s70.idle_cause = ""
		s70.idle_pick()
		var once70: bool = s70.idle_cause == ""
		for i in 35: # hurt at the end of the run
			s70.track_run(true, 0.1)
		main.player.hp = float(main.player.max_hp) - 5.0
		s70.track_run(false, 0.1)
		var hurt: bool = not s70.run_thirst
		main.player.hp = float(main.player.max_hp)
		for i in 35: # stale: the next rest comes 60 s later
			s70.track_run(true, 0.1)
		s70.track_run(false, 0.1)
		s70.run_thirst_t = main.t - 60.0
		s70.idle_pick()
		var stale70: bool = s70.idle_cause == ""
		main.idle_name = ""
		s70.run_thirst = false
		calm_enemies(false)
		check("d70_run_water", short70 and thirsty and drink and cue and same and once70 and hurt and stale70,
			"a 2 s run: none=%s a 3.5 s run: thirst=%s the next rest: drink=%s one cap cue=%s hp/sp/mp unchanged=%s used up=%s hurt at the end: none=%s stale: none=%s" % [short70, thirsty, drink, cue, same, once70, hurt, stale70])

	if want.call("d71_tea_cups"):
		# three empty cups on a plank behind Bori's cottage: looked at left to right the last one steams for 6 s; any other order starts over; nothing is given; quiet before step 3, during a story and out of reach (idea 71)
		marsh_world()
		var wb71: Object = main.world_build
		var sh71: Object = main.shop
		var mt71: Object = main.marsh_toys
		var cups: Array = wb71.tea_at
		var built71: bool = cups.size() == 3 and wb71.tea_steam.size() == 2 and cups.all(func(c): return marsh_ground_ok(c) and c.distance_to(main.cottage_at) < 5.0)
		var spaced: bool = built71 and is_equal_approx(cups[0].distance_to(cups[1]), 0.5) and is_equal_approx(cups[1].distance_to(cups[2]), 0.5)
		var gold71: int = main.player.gold
		var pots71: int = main.player.pots
		var hp71: float = main.player.hp
		var look := func(i: int) -> bool:
			reset_to(cups[i])
			return mt71.key()
		sh71.cup_next = 0
		sh71.cup_steam_t = 0.0
		var s0: int = sh71.cup_steams
		var first: bool = look.call(0) and look.call(1) and sh71.cup_steams == s0 and sh71.cup_steam_t == 0.0
		var done: bool = look.call(2) and sh71.cup_steams == s0 + 1 and is_equal_approx(sh71.cup_steam_t, 6.0)
		sh71.update_cups(0.1)
		var puffs: bool = wb71.tea_steam.all(func(q): return q[0].visible and absf(q[0].position.x - 0.5) < 0.05 and q[0].position.y > 0.36)
		sh71.update_cups(6.0)
		var ends: bool = wb71.tea_steam.all(func(q): return not q[0].visible)
		look.call(2)
		look.call(1)
		look.call(0)
		var backwards: bool = sh71.cup_steams == s0 + 1 and sh71.cup_steam_t == 0.0
		look.call(0)
		look.call(2) # skipped the middle one: starts over
		look.call(1)
		var skipped: bool = sh71.cup_steams == s0 + 1
		sh71.cup_next = 0
		look.call(0)
		look.call(1)
		look.call(0) # back to the first: the order restarts from it
		look.call(1)
		look.call(2)
		var again: bool = sh71.cup_steams == s0 + 2
		var plain71: bool = main.player.gold == gold71 and main.player.pots == pots71 and main.player.hp == hp71
		sh71.cup_steam_t = 0.0
		sh71.update_cups(0.1)
		sh71.cup_next = 2
		reset_to(cups[2] + Vector2(3.0, 0.0))
		var far71: bool = sh71.cup_look_near() == -1 and not sh71.cup_key() and sh71.cup_next == 2 and not mt71.hint().contains("찻잔")
		reset_to(cups[1])
		var hint71: bool = mt71.hint() != ""
		main.story_open = true
		var story71: bool = not mt71.key() and mt71.hint() == "" and sh71.cup_next == 2
		main.story_open = false
		main.story_step = 2
		var early71: bool = not mt71.key() and sh71.cup_look_near() == -1
		main.story_step = 3
		sh71.cup_next = 0
		sh71.cup_steam_t = 0.0
		calm_enemies(false)
		check("d71_tea_cups", built71 and spaced and first and done and puffs and ends and backwards and skipped and again and plain71 and far71 and hint71 and story71 and early71,
			"3 cups 0.5 apart on dry ground behind the cottage, 2 puffs=%s/%s in order: no steam for two=%s the third steams 6 s=%s puffs rise from the last cup=%s end=%s backwards none=%s skipping none=%s a restart works=%s no gold/potion/hp change=%s far=%s hint near=%s story=%s step 2=%s" \
			% [built71, spaced, first, done, puffs, ends, backwards, skipped, again, plain71, far71, hint71, story71, early71])
	if want.call("d72_height_ruler"):
		# a height ruler by the island hut's door; the gold pole line fades in (1 s) only once Mulgyeol has joined and both are near the hut; E at it says one line (idea 72)
		var lz72: Object = main.lake_zone
		var q72: int = main.lake_q
		var had_mate: bool = main.mate != null
		var at72: Vector2 = lz72.ruler_at
		var img72: Image = lz72.ruler.texture.get_image()
		var ticks := 0
		for y in img72.get_height():
			if img72.get_pixel(1, y).is_equal_approx(Color("#4a3320")):
				ticks += 1
		var hut72: Vector2 = main.lake.marks.h
		var built72: bool = ticks == 10 and absf(at72.x - hut72.x - 0.55) < 0.01 and at72.y > hut72.y and not lz72.ruler_mark.visible and is_equal_approx(lz72.ruler_mark.position.y, 0.85)
		lz72.ruler_shown = false
		lz72.ruler_a = 0.0
		lz72.ruler_mark.visible = false
		main.lake_q = 3
		main.join_mate()
		main.mate.position = Vector3(at72.x + 1.0, 0.0, at72.y + 1.0)
		reset_to(at72 + Vector2(0.0, 1.0))
		lz72.update_height_ruler(0.1)
		var before: bool = not lz72.ruler_shown and not lz72.ruler_key()
		main.lake_q = 4
		reset_to(at72 + Vector2(6.0, 1.0)) # Sora far
		lz72.update_height_ruler(0.1)
		var far_s: bool = not lz72.ruler_shown
		reset_to(at72 + Vector2(0.0, 1.0))
		main.mate.position = Vector3(at72.x + 9.0, 0.0, at72.y) # Mulgyeol far
		lz72.update_height_ruler(0.1)
		var far_m: bool = not lz72.ruler_shown
		main.mate.position = Vector3(at72.x + 1.0, 0.0, at72.y + 1.0)
		lz72.update_height_ruler(0.1)
		var shown: bool = lz72.ruler_shown and lz72.ruler_mark.visible and lz72.ruler_mark.modulate.a < 0.5
		lz72.update_height_ruler(1.0)
		var full: bool = is_equal_approx(lz72.ruler_mark.modulate.a, 1.0)
		var talks: bool = lz72.ruler_key()
		reset_to(at72 + Vector2(3.0, 1.0))
		var quiet72: bool = not lz72.ruler_key()
		lz72.ruler_shown = false
		lz72.ruler_a = 0.0
		lz72.ruler_mark.visible = false
		main.lake_q = q72
		if not had_mate:
			main.mates.leave_mate()
		check("d72_height_ruler", built72 and before and far_s and far_m and shown and full and talks and quiet72,
			"ruler with 10 ticks beside the hut door, pole line at 0.85 hidden=%s before he joins: none=%s Sora far=%s he is far=%s both near: fades in=%s full after 1 s=%s E says the line=%s E 3 tiles off is quiet=%s" \
			% [built72, before, far_s, far_m, shown, full, talks, quiet72])
	if want.call("d74_wall_chair"):
		# an open wall she has seen from close, left (10+ tiles) and come back to gets two stacked bricks like a small chair on a free corner tile; no blocker, the wall stays open; a shut wall gets none (idea 74)
		var fz74: Object = main.forest_zone
		var w74: Dictionary = main.forest.walls[0]
		var shut74: Dictionary = main.forest.walls[1]
		var open0: bool = w74.open
		var shut0: bool = shut74.open
		w74.open = true
		w74.ph = 0
		shut74.open = false
		shut74.ph = 0
		var rocks0: int = main.rocks.size()
		var n0: int = fz74.chairs.size()
		var near74: Vector2 = w74.pos + Vector2(2.0, 0.0)
		var far74: Vector2 = w74.pos + Vector2(14.0, 0.0)
		fz74.update_wall_chairs(far74)
		var s_a: bool = w74.ph == 0
		fz74.update_wall_chairs(near74)
		var s_b: bool = w74.ph == 1 and fz74.chairs.size() == n0 # seen, nothing yet
		fz74.update_wall_chairs(near74)
		var s_c: bool = fz74.chairs.size() == n0
		fz74.update_wall_chairs(w74.pos + Vector2(7.0, 0.0)) # not yet far enough
		var s_d: bool = w74.ph == 1
		fz74.update_wall_chairs(far74)
		var s_e: bool = w74.ph == 2 and fz74.chairs.size() == n0
		fz74.update_wall_chairs(near74)
		var s_f: bool = w74.ph == 3 and fz74.chairs.size() == n0 + 1
		var chair: Node3D = fz74.chairs[fz74.chairs.size() - 1]
		var cp := Vector2(chair.position.x, chair.position.z)
		var corner: bool = absf(cp.distance_to(w74.pos) - sqrt(2.0)) < 0.01 and main.forest.char_at(cp.x, cp.y) == "." and chair.get_child_count() == 2
		fz74.update_wall_chairs(far74)
		fz74.update_wall_chairs(near74)
		var once74: bool = fz74.chairs.size() == n0 + 1
		var open74: bool = w74.open and not main.forest.blocked(w74.pos.x, w74.pos.y) and main.rocks.size() == rocks0
		fz74.update_wall_chairs(shut74.pos + Vector2(2.0, 0.0))
		fz74.update_wall_chairs(shut74.pos + Vector2(14.0, 0.0))
		fz74.update_wall_chairs(shut74.pos + Vector2(2.0, 0.0))
		var shut_ok: bool = shut74.get("ph", 0) == 0 and fz74.chairs.size() == n0 + 1
		chair.queue_free()
		fz74.chairs.pop_back()
		w74.open = open0
		shut74.open = shut0
		w74.ph = 0
		shut74.ph = 0
		check("d74_wall_chair", s_a and s_b and s_c and s_d and s_e and s_f and corner and once74 and open74 and shut_ok,
			"far first: nothing=%s seen close=%s again close=%s 7 tiles is not left=%s left=%s back: one chair=%s on a free diagonal tile with 2 bricks=%s only once=%s wall still open, no blocker=%s a shut wall gets none=%s" \
			% [s_a, s_b, s_c, s_d, s_e, s_f, corner, once74, open74, shut_ok])
	if want.call("d77_acorn_husk"):
		# E at a cage already freed rolls one acorn husk out and away (0.7 tiles), gone after about 3 s; 4 s between; nothing given, the rescue not counted again; an unfreed cage, a far spot, a foe or a story: none (idea 77)
		var fz77: Object = main.forest_zone
		var cage77: Vector2 = main.FOREST.CAGES[0] + Vector2(main.FOREST.FOREST_X, 0)
		var freed0: Array = main.forest.freed.duplicate()
		var acorn0: bool = main.has_acorn
		main.close_story()
		main.intro = false
		calm_enemies(true)
		for i77 in main.forest.freed.size(): # earlier tests may have freed others
			main.forest.freed[i77] = i77 == 0
		fz77.husk_t = -10.0
		var gold77: int = main.player.gold
		var pots77: int = main.player.pots
		var n77: int = fz77.husks
		reset_to(cage77 + Vector2(-0.8, 0.0))
		var rolled: bool = fz77.husk_key() and fz77.husks == n77 + 1 and fz77.husk_node != null
		var husk: Node3D = fz77.husk_node
		var same: bool = fz77.husk_key() == false and fz77.husks == n77 + 1
		await wait(1.0)
		var hd: float = Vector2(husk.position.x, husk.position.z).distance_to(cage77)
		var moved: bool = hd < 0.8
		await wait(2.6)
		var gone: bool = not is_instance_valid(husk) or husk.is_queued_for_deletion()
		var plain77: bool = main.player.gold == gold77 and main.player.pots == pots77 and main.forest.freed[0] and main.has_acorn == acorn0 and main.forest.freed.filter(func(f): return f).size() == 1
		fz77.husk_t = -10.0
		reset_to(main.FOREST.CAGES[1] + Vector2(main.FOREST.FOREST_X, 0) + Vector2(-0.8, 0.0))
		var unfreed: bool = not fz77.husk_key() # cage 1 is still shut
		reset_to(cage77 + Vector2(3.0, 0.0))
		var far77: bool = not fz77.husk_key()
		reset_to(cage77 + Vector2(-0.8, 0.0))
		main.story_open = true
		var story77: bool = not fz77.husk_key()
		main.story_open = false
		calm_enemies(false)
		main.spawn_enemy(cage77 + Vector2(2.0, 0.0)) # late in a full run every foe may be down
		var foe_e77: Dictionary = main.enemies[main.enemies.size() - 1]
		var foe77: bool = not fz77.husk_key()
		foe_e77.node.queue_free()
		main.enemies.erase(foe_e77)
		main.forest.freed = freed0
		main.has_acorn = acorn0
		calm_enemies(true)
		calm_enemies(false)
		check("d77_acorn_husk", rolled and same and moved and gone and plain77 and unfreed and far77 and story77 and foe77,
			"E at a freed cage rolls one husk=%s a second E at once is quiet=%s it rolled to %.2f tiles from the cage (under 0.8)=%s gone after 3.6 s=%s nothing given, rescue count same=%s unfreed cage=%s far=%s story=%s a foe within 6 tiles=%s" \
			% [rolled, same, hd, moved, gone, plain77, unfreed, far77, story77, foe77])
	if want.call("d80_start_reeds"):
		# nine reeds in Sora's shape where she woke: flat before story step 3, upright after; they rise in 8 s if she is within 9 tiles, at once if she is far; the awakening is untouched (idea 80)
		var wb80: Object = main.world_build
		var step80: int = main.story_step
		var reeds: Array = wb80.start_reeds
		var near_start: bool = reeds.size() == 9 and reeds.all(func(r): return Vector2(r.position.x, r.position.z).distance_to(main.START) < 1.0)
		main.story_step = 2
		reset_to(main.START + Vector2(20.0, 0.0))
		wb80.update_start_reeds(0.1)
		var flat: bool = reeds.all(func(r): return r.rotation.x < -1.2)
		main.story_step = 3
		wb80.update_start_reeds(0.1) # far away: at once
		var up_far: bool = reeds.all(func(r): return absf(r.rotation.x) < 0.06)
		main.story_step = 2
		wb80.update_start_reeds(0.1)
		var again80: bool = reeds.all(func(r): return r.rotation.x < -1.2)
		reset_to(main.START + Vector2(2.0, 0.0))
		main.story_step = 3
		wb80.update_start_reeds(0.1)
		wb80.update_start_reeds(3.9) # half way
		var mid: bool = reeds.all(func(r): return r.rotation.x < -0.3 and r.rotation.x > -1.0)
		wb80.update_start_reeds(4.1)
		var up_near: bool = reeds.all(func(r): return absf(r.rotation.x) < 0.06)
		var still: bool = wb80.reeds_t == 0.0
		main.story_step = step80
		wb80.update_start_reeds(0.1)
		check("d80_start_reeds", near_start and flat and up_far and again80 and mid and up_near and still,
			"9 reeds within a tile of the start=%s flat before step 3=%s up at once when she is far=%s pressed again at step 2=%s half risen after 4 s near=%s upright after 8 s=%s settled=%s" \
			% [near_start, flat, up_far, again80, mid, up_near, still])
	if want.call("d82_pip_gap"):
		# a refused use of the bracelet shows the pips it asks and the pips she holds side by side under the moon-light card; no cost changes, no pip spent (idea 82)
		var hud82: Control = main.ui.hud
		main.close_story()
		main.intro = false
		var pips82: int = main.crown_pips
		main.crown_pips = 1
		hud82.pip_need = 0
		hud82.pip_hint_t = 0.0
		var refused82: bool = not main.spend_pips(3) and main.crown_pips == 1 and hud82.pip_need == 3
		await wait(0.3)
		var row82: bool = hud82.pip_hint_t > 3.0 and hud82.pip_need_drawn == 3 and hud82.pip_have_drawn == 1
		main.crown_pips = 0
		hud82.pip_hint_t = 4.0
		await wait(0.2)
		var none82: bool = hud82.pip_need_drawn == 3 and hud82.pip_have_drawn == 0
		main.crown_pips = 2
		var paid82: bool = main.spend_pips(2) and main.crown_pips == 0
		hud82.pip_need = 0
		hud82.pip_hint_t = 4.0
		await wait(0.2)
		var quiet82: bool = hud82.pip_need_drawn == 0 and hud82.pip_have_drawn == 0
		hud82.pip_hint_t = 0.0
		main.crown_pips = pips82
		check("d82_pip_gap", refused82 and row82 and none82 and paid82 and quiet82,
			"refused with 1 of 3 held, nothing spent=%s card row shows 3 asked and 1 held=%s with none held=%s a paid use spends as before=%s no row when nothing is asked=%s" % [refused82, row82, none82, paid82, quiet82])
	if want.call("d86_last_bottle"):
		# with exactly one potion left a bottle outline is drawn beside the count; two or none: no outline (idea 86)
		var hud86: Control = main.ui.hud
		main.close_story()
		main.intro = false
		var pots86: int = main.player.pots
		main.player.pots = 1
		await wait(0.2)
		var one86: bool = hud86.bottle_drawn
		await wait(0.5)
		var steady: bool = hud86.bottle_drawn # no blinking
		main.player.pots = 2
		await wait(0.2)
		var two86: bool = not hud86.bottle_drawn
		main.player.pots = 0
		await wait(0.2)
		var none86: bool = not hud86.bottle_drawn
		main.player.pots = pots86
		check("d86_last_bottle", one86 and steady and two86 and none86,
			"one potion: bottle=%s still there 0.5 s on=%s two: none=%s zero: none=%s" % [one86, steady, two86, none86])
	if want.call("d99_ready_rim"):
		# when a wait ends (above 0 to 0) a 16-notch rim shows on that coin for 2 s, steady, then eases out in 0.5 s; a coin that was never waiting has none (idea 99)
		var hud99: Control = main.ui.hud
		main.close_story()
		main.intro = false
		var cds99: Array = main.player.cds
		var keep99: Array = cds99.duplicate()
		for i in 4:
			cds99[i] = 0.0
		await wait(0.2)
		hud99.rim_t = [0.0, 0.0, 0.0, 0.0]
		cds99[1] = 5.0
		hud99.update_rims(0.05)
		var waiting: bool = hud99.rim_t[1] == 0.0
		cds99[1] = 0.0
		hud99.update_rims(0.05)
		var lit: bool = is_equal_approx(hud99.rim_t[1], 2.0) and hud99.rim_t[0] == 0.0 and hud99.rim_t[2] == 0.0 and hud99.rim_t[3] == 0.0
		await wait(0.2)
		var notches: bool = hud99.rim_drawn == 16 and hud99.rim_points(Vector2.ZERO, 34.0).size() == 16
		hud99.update_rims(1.0)
		await wait(0.2)
		var held: bool = hud99.rim_t[1] > 0.5 and hud99.rim_drawn == 16 # steady, not blinking
		hud99.update_rims(1.5)
		await wait(0.2)
		var gone99: bool = hud99.rim_t[1] == 0.0 and hud99.rim_drawn == 0
		hud99.update_rims(0.1)
		var never: bool = hud99.rim_t[0] == 0.0 and hud99.rim_t[2] == 0.0
		for i in 4:
			cds99[i] = keep99[i]
		hud99.rim_t = [0.0, 0.0, 0.0, 0.0]
		check("d99_ready_rim", waiting and lit and notches and held and gone99 and never,
			"no rim while waiting=%s the wait ends: 2 s on that coin only=%s 16 notches drawn=%s steady at 1 s=%s gone after 2.5 s=%s others never=%s" % [waiting, lit, notches, held, gone99, never])

	if want.call("d2_wet_prints"):
		# the first six footsteps after a water skip leave a flat dark print on dry ground, each fainter than the last, each drying away; none without a landing, on water, or in a story; skipping again clears the count (idea 2)
		var ef2: Object = main.effects
		var sd2: Object = main.sound
		marsh_world()
		main.intro = false
		main.in_house = -1
		var spot2: Vector2 = open_field()
		reset_to(spot2)
		main.player.face = Vector2(1, 0)
		ef2.print_left = 0
		sd2.skip_was = false
		sd2.skip_track(false)
		var made0: int = ef2.prints_made
		for i in 2:
			main.last_step = -10.0
			sd2.footstep()
		var quiet2: bool = ef2.prints_made == made0
		sd2.skip_track(true)
		sd2.skip_track(true)
		sd2.skip_track(false) # onto the bank
		var armed2: bool = ef2.print_left == 6
		var alphas: Array = []
		var firsts: Array = []
		for i in 8:
			reset_to(spot2 + Vector2(0.4 * i, 0.0))
			main.last_step = -10.0
			var n0: int = ef2.prints_made
			sd2.footstep()
			if ef2.prints_made > n0:
				alphas.append(ef2.last_print_alpha)
				firsts.append(ef2.last_print)
		var six2: bool = alphas.size() == 6 and ef2.print_left == 0
		var fading2: bool = true
		for i in range(1, alphas.size()):
			fading2 = fading2 and alphas[i] < alphas[i - 1]
		var strong2: bool = alphas.size() > 0 and alphas[0] > 0.5 and alphas[alphas.size() - 1] > 0.0
		var flat2: bool = firsts.size() > 0 and is_instance_valid(firsts[0]) and (firsts[0].mesh as BoxMesh).size.y < 0.02 and firsts[0].get_parent() != null
		var dries2: bool = false
		for e in main.fx:
			if e.node == firsts[0]:
				var a_before: float = (firsts[0].material_override as StandardMaterial3D).albedo_color.a
				e.update.call(e.node, 0.9, 0.0)
				dries2 = (firsts[0].material_override as StandardMaterial3D).albedo_color.a < a_before * 0.5
		var pond2 := Vector2(2, 2)
		for gz in range(3, 44):
			for gx in range(3, 44):
				if pond2 == Vector2(2, 2) and main.tile_at(gx, gz) == main.WATER:
					pond2 = Vector2(gx, gz)
		reset_to(pond2)
		ef2.print_left = 3
		var w0: int = ef2.prints_made
		main.last_step = -10.0
		sd2.footstep()
		var water2: bool = ef2.prints_made == w0 and ef2.print_left == 3
		reset_to(spot2)
		main.show_story("", ["x"])
		main.last_step = -10.0
		sd2.footstep()
		var story2: bool = ef2.prints_made == w0 and ef2.print_left == 3
		main.close_story()
		sd2.skip_track(true) # skipping again: the count is cleared
		var cleared2: bool = ef2.print_left == 0
		sd2.skip_track(false)
		sd2.wet_steps = 0
		ef2.print_left = 0
		check("d2_wet_prints", quiet2 and armed2 and six2 and fading2 and strong2 and flat2 and dries2 and water2 and story2 and cleared2,
			"no landing, no print=%s a landing arms six=%s exactly six prints=%s each fainter=%s the first strong, the last still there=%s flat box=%s they dry away=%s none on water=%s none in a story=%s skipping again clears=%s" % [quiet2, armed2, six2, fading2, strong2, flat2, dries2, water2, story2, cleared2])
	if want.call("d5_reed_drops"):
		# a reed clump on the lake shore arms when she brushes past it moving, and three drops fall (1320, 1180, 1050 Hz, 0.5 s apart) once she is 2 tiles off; resting 20 s, a story, standing still or the 6-drop cap: none (idea 5)
		var lz5: Object = main.lake_zone
		main.close_story()
		main.intro = false
		var lake5: bool = main.in_lake
		main.in_lake = true
		var built5: bool = lz5.reeds.size() >= 3 and lz5.reeds.size() <= 6 and lz5.reeds.all(func(r): return main.lake.char_at(r.at.x, r.at.y) in ".igas")
		var r5: Dictionary = lz5.reeds[0]
		r5.armed = false
		r5.used = -100.0
		reset_to(r5.at + Vector2(0.5, 0.0))
		main.player.vx = 0.0
		main.player.vz = 0.0
		lz5.update_reed_tips()
		var still5: bool = not r5.armed # standing still brushes nothing
		main.player.vx = 3.0
		main.show_story("", ["x"])
		lz5.update_reed_tips()
		var story5: bool = not r5.armed
		main.close_story()
		lz5.update_reed_tips()
		var armed5: bool = r5.armed
		var d0: int = lz5.reed_drops
		reset_to(r5.at + Vector2(1.5, 0.0)) # not yet 2 tiles off
		lz5.update_reed_tips()
		var holds5: bool = r5.armed and lz5.reed_drops == d0
		main.sfx_log.clear()
		reset_to(r5.at + Vector2(0.0, 3.0))
		main.player.vx = 0.0
		lz5.update_reed_tips()
		var let_go: bool = not r5.armed and is_equal_approx(r5.used, main.t)
		await wait(0.65)
		var first5: bool = lz5.reed_drops == d0 + 1
		await wait(1.65)
		var plinks: Array = main.sfx_log.filter(func(s): return s in ["sine:1320", "sine:1180", "sine:1050"])
		var three5: bool = lz5.reed_drops == d0 + 3 and plinks == ["sine:1320", "sine:1180", "sine:1050"] and lz5.reed_live == 0
		reset_to(r5.at + Vector2(0.5, 0.0)) # brushing it again at once: it rests
		main.player.vx = 3.0
		lz5.update_reed_tips()
		var rests5: bool = not r5.armed
		main.player.vx = 0.0
		lz5.reed_live = lz5.REED_CAP
		var d1: int = lz5.reed_drops
		lz5.reed_drop(r5.tip, 0)
		var capped5: bool = lz5.reed_drops == d1
		lz5.reed_live = 0
		r5.used = -100.0
		main.in_lake = lake5
		check("d5_reed_drops", built5 and still5 and story5 and armed5 and holds5 and let_go and first5 and three5 and rests5 and capped5,
			"3 to 6 clumps on the shore=%s standing still arms none=%s a story none=%s brushing past arms=%s held until 2 tiles=%s armed one lets go=%s first drop by 0.65 s=%s three plinks in order=%s rests 20 s=%s the cap of 6 holds=%s" % [built5, still5, story5, armed5, holds5, let_go, first5, three5, rests5, capped5])
	if want.call("d6_street_leaves"):
		# up to eight leaves lie on the village's stone streets 3 tiles apart; a run (5+ tiles a second) past one shoves it along her way for at most 1.4 tiles and never off the stones; a walk, a story or indoors: nothing (idea 6)
		var dr6: Object = main.dressing
		var ef6: Object = main.effects
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var ls6: Array = dr6.street_leaves
		var built6: bool = ls6.size() >= 4 and ls6.size() <= 8
		var apart6: bool = true
		var onstone6: bool = true
		for i in ls6.size():
			onstone6 = onstone6 and main.village.char_at(ls6[i].home.x, ls6[i].home.y) == "="
			for j in range(i + 1, ls6.size()):
				apart6 = apart6 and ls6[i].home.distance_to(ls6[j].home) >= 3.0
		var stones6: bool = true # whatever the way, the end of a shove lies on the stones and within 1.4 tiles
		var pick: Array = []
		var clipped6: bool = false
		for lf in ls6:
			var at6: Vector2 = Vector2(lf.node.position.x, lf.node.position.z)
			for dir in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				var to6: Vector2 = ef6.leaf_slide_end(at6, dir)
				stones6 = stones6 and ef6.leaf_ground_ok(to6) and to6.distance_to(at6) <= 1.41
				clipped6 = clipped6 or to6.distance_to(at6) < 1.3
				if pick.is_empty() and to6.distance_to(at6) > 0.8:
					pick = [lf, at6, dir, to6]
		var found6: bool = not pick.is_empty()
		var lf6: Dictionary = pick[0] if found6 else ls6[0]
		var at0: Vector2 = pick[1] if found6 else Vector2.ZERO
		var dir6: Vector2 = pick[2] if found6 else Vector2(1, 0)
		var to0: Vector2 = pick[3] if found6 else Vector2.ZERO
		var others: Array = ls6.map(func(l): return l.node.position)
		reset_to(at0 - dir6 * 0.3)
		var p0: int = ef6.leaf_pushes
		main.player.vx = dir6.x * 3.6
		main.player.vz = dir6.y * 3.6
		ef6.update_street_leaves()
		var walk6: bool = ef6.leaf_pushes == p0
		main.player.vx = dir6.x * 6.2
		main.player.vz = dir6.y * 6.2
		main.show_story("", ["x"])
		ef6.update_street_leaves()
		var story6: bool = ef6.leaf_pushes == p0
		main.close_story()
		main.in_house = 0
		ef6.update_street_leaves()
		var indoors6: bool = ef6.leaf_pushes == p0
		main.in_house = -1
		ef6.update_street_leaves()
		var pushed6: bool = ef6.leaf_pushes == p0 + 1 and lf6.moving
		main.player.vx = 0.0
		main.player.vz = 0.0
		await wait(0.7)
		var end6: Vector2 = Vector2(lf6.node.position.x, lf6.node.position.z)
		var slid6: bool = found6 and end6.distance_to(to0) < 0.05 and not lf6.moving
		var others_still: bool = true
		for i in ls6.size():
			if ls6[i] != lf6 and not (ls6[i].node.position as Vector3).is_equal_approx(others[i]):
				others_still = false
		lf6.node.position = Vector3(lf6.home.x, 0.012, lf6.home.y)
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.in_village = false
		check("d6_street_leaves", built6 and apart6 and onstone6 and stones6 and clipped6 and found6 and walk6 and story6 and indoors6 and pushed6 and slid6 and others_still,
			"4 to 8 leaves=%s 3 tiles apart=%s on the stones=%s every shove ends on stone within 1.4=%s a street end cuts one short=%s walking, a story, indoors: none=%s/%s/%s a run shoves it=%s it slid to the computed end=%s the rest stay=%s" % [built6, apart6, onstone6, stones6, clipped6, walk6, story6, indoors6, pushed6, slid6, others_still])
	if want.call("d11_fountain_step"):
		# her blow on the fountain makes Mulgyeol, if he is within 3 tiles of her, step 1 tile back from the water and hold 1.2 s; far from her, in a story, near a foe, while she walks, or within 6 s of the last: nothing (idea 11)
		var ma11: Object = main.mates
		main.join_mate()
		main.close_story()
		main.intro = false
		main.in_house = -1
		main.in_village = true
		calm_enemies(true)
		var keep11: Array = main.enemies.duplicate()
		main.enemies = []
		var f11: Vector2 = main.village.fountain_at()
		var spot11 := Vector2(f11.x, f11.y + 2.0)
		reset_to(spot11)
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.mate_job = {}
		ma11.end_quirk()
		ma11.quirk_t = -100.0
		main.mate.position = Vector3(f11.x + 0.6, 0, f11.y + 2.4)
		var s0: int = ma11.fountain_steps
		var d_start: float = Vector2(main.mate.position.x, main.mate.position.z).distance_to(f11)
		main.village.fountain_hit(main, 3.0, Vector2(0, -1), 0.3, true)
		var begun: bool = ma11.fountain_steps == s0 + 1 and ma11.quirk.get("kind", "") == "fountain"
		for i in 20:
			ma11.update_quirk(0.05)
		var d_now: float = Vector2(main.mate.position.x, main.mate.position.z).distance_to(f11)
		var stepped: bool = d_now > d_start + 0.9 and d_now < d_start + 1.1
		var holding: bool = not ma11.quirk.is_empty()
		for i in 30:
			ma11.update_quirk(0.05)
		var ended: bool = ma11.quirk.is_empty()
		var soon: bool = not ma11.fountain_back(f11) # within the 6 s
		ma11.quirk_t = -100.0
		main.mate.position = Vector3(f11.x + 0.6, 0, f11.y + 2.4)
		main.player.x = f11.x + 7.0 # far from him
		var far11: bool = not ma11.fountain_back(f11)
		reset_to(spot11)
		main.show_story("", ["x"])
		var story11: bool = not ma11.fountain_back(f11)
		main.close_story()
		main.enemies = [{"x": spot11.x + 3.0, "z": spot11.y, "dead": false}]
		var foe11: bool = not ma11.fountain_back(f11)
		main.enemies = []
		var walk_ok: bool = ma11.fountain_back(f11)
		main.player.vx = 3.0
		ma11.update_quirk(0.05) # she steps off: it ends at once
		var walked11: bool = walk_ok and ma11.quirk.is_empty()
		main.player.vx = 0.0
		ma11.end_quirk()
		main.enemies = keep11
		calm_enemies(false)
		main.in_village = false
		check("d11_fountain_step", begun and stepped and holding and ended and soon and far11 and story11 and foe11 and walked11,
			"a blow starts it=%s he ends 1 tile farther from the water=%s he holds there=%s it ends after 1.2 s=%s inside 6 s: none=%s far from her: none=%s story: none=%s foe near: none=%s her step ends it=%s" % [begun, stepped, holding, ended, soon, far11, story11, foe11, walked11])
	if want.call("d13_loop_dizzy"):
		# three turns of a small circle by the water send Mulgyeol once round the same circle (13 points, 1.5 tiles out) and leave him with a turning ring for 1.6 s; two turns, a dry place, a wide circle, standing still or a story: none; walking away ends it (idea 13)
		var ma13: Object = main.mates
		marsh_world()
		main.join_mate()
		main.intro = false
		main.in_house = -1
		var keep13: Array = main.enemies.duplicate()
		main.enemies = []
		var c13 := Vector2(-1, -1)
		for gz in range(5, 44):
			for gx in range(5, 44):
				var cc := Vector2(gx, gz)
				if c13.x >= 0.0 or not ma13.near_water(cc) or not main.walkable(cc.x, cc.y):
					continue
				var okp := 0
				for k in 12:
					var a13 := TAU * k / 12.0
					if main.walkable(cc.x + cos(a13) * 1.5, cc.y + sin(a13) * 1.5) and main.walkable(cc.x + cos(a13) * 1.2, cc.y + sin(a13) * 1.2):
						okp += 1
				if okp == 12 and ma13.mate_way(Vector3(cc.x + 1.5, 0, cc.y), Vector3(cc.x, 0, cc.y)):
					c13 = cc
		var found13: bool = c13.x >= 0.0
		if not found13:
			c13 = open_field()
		var wet13: bool = ma13.near_water(c13)
		var dry13: Vector2 = open_field()
		main.mate_job = {}
		ma13.end_quirk()
		ma13.quirk_t = -100.0
		var circle := func(c: Vector2, r: float, laps: float, from_a := 0.0) -> void:
			var steps: int = int(laps * 36.0)
			for i in steps:
				var a: float = from_a + TAU * i / 36.0
				main.player.x = c.x + cos(a) * r
				main.player.z = c.y + sin(a) * r
				ma13.track_loop(0.11)
		main.mate.position = Vector3(c13.x + 1.5, 0, c13.y)
		main.player.vx = 3.0
		ma13.loop_reset()
		ma13.loop_last = Vector2(c13.x + 1.2, c13.y)
		circle.call(c13, 1.2, 2.0)
		var two13: bool = ma13.quirk.is_empty()
		circle.call(c13, 1.2, 1.4)
		var started: bool = wet13 and ma13.quirk.get("kind", "") == "loop" and ma13.quirk.path.size() >= 8
		var q13: int = int(ma13.quirks_made.get("loop", 0))
		var far_ring: bool = true
		var rings: int = 0
		for i in 120:
			ma13.update_quirk(0.05)
			var him13 := Vector2(main.mate.position.x, main.mate.position.z)
			if not ma13.quirk.is_empty() and ma13.quirk.i >= 3:
				far_ring = far_ring and absf(him13.distance_to(c13) - 1.5) < 0.35
			if not ma13.quirk.is_empty() and ma13.quirk.ring != null:
				rings += 1
		var dizzy13: bool = rings > 5 and ma13.quirk.is_empty()
		# a second round straight away is too soon, a dry shore does not count, a wide circle does not count
		ma13.loop_reset()
		circle.call(c13, 1.2, 3.4)
		var soon13: bool = ma13.quirk.is_empty()
		ma13.quirk_t = -100.0
		ma13.loop_reset()
		circle.call(dry13, 1.2, 3.4)
		var dry_none: bool = ma13.quirk.is_empty() and not ma13.near_water(dry13)
		ma13.loop_reset()
		circle.call(c13, 4.5, 3.4)
		var wide13: bool = ma13.quirk.is_empty()
		ma13.loop_reset()
		main.show_story("", ["x"])
		circle.call(c13, 1.2, 3.4)
		var story13: bool = ma13.quirk.is_empty()
		main.close_story()
		ma13.loop_reset()
		main.player.x = c13.x + 1.2
		main.player.z = c13.y
		for i in 40: # standing still
			ma13.track_loop(0.11)
		var still13: bool = ma13.quirk.is_empty() and absf(ma13.loop_turn) < 0.01
		# walking off the spot ends a started one
		ma13.loop_reset()
		circle.call(c13, 1.2, 3.4)
		var again13: bool = not ma13.quirk.is_empty() and found13
		main.player.x = c13.x + 12.0
		ma13.update_quirk(0.05)
		var left13: bool = ma13.quirk.is_empty()
		ma13.end_quirk()
		ma13.loop_reset()
		main.player.vx = 0.0
		main.enemies = keep13
		check("d13_loop_dizzy", found13 and two13 and started and q13 >= 1 and far_ring and dizzy13 and soon13 and dry_none and wide13 and story13 and still13 and again13 and left13,
			"a ring spot by the water found=%s two turns: none=%s three turns start it=%s round the circle, 1.5 out=%s dizzy ring held then gone=%s a second round at once: none=%s dry shore: none=%s wide circle: none=%s story: none=%s still: none=%s a later round starts again=%s leaving ends it=%s" % [found13, two13, started, far_ring, dizzy13, soon13, dry_none, wide13, story13, still13, again13, left13])
	if want.call("d15_look_back"):
		# after a water skip lands her on the bank, turning to face the last water tile within 3 s makes one ring there (and a soft plink); facing away, nobody to see it, too late, or too close: none; no second ring (idea 15)
		var ma15: Object = main.mates
		marsh_world()
		main.join_mate()
		main.intro = false
		main.in_house = -1
		var w15 := Vector2(-1, -1)
		var l15 := Vector2.ZERO
		for gz in range(6, 42):
			for gx in range(6, 38):
				if w15.x < 0.0 and main.tile_at(gx, gz) == main.WATER and main.walkable(gx + 3.0, gz) and main.walkable(gx + 2.0, gz) and main.tile_at(gx + 1.0, gz) != main.WATER:
					w15 = Vector2(gx, gz)
					l15 = Vector2(gx + 3.0, gz)
		var found15: bool = w15.x >= 0.0
		var r0: int = ma15.water_rings
		reset_to(w15 if found15 else Vector2(2, 2))
		ma15.skip_watch(true, 0.1)
		reset_to(l15)
		ma15.skip_watch(false, 0.1)
		var armed15: bool = ma15.look_t > 2.5 and ma15.look_at == Vector2(roundf(w15.x), roundf(w15.y))
		main.player.face = Vector2(1, 0) # facing away
		ma15.skip_watch(false, 0.1)
		var away15: bool = ma15.water_rings == r0
		main.sfx_log.clear()
		main.player.face = Vector2(-1, 0) # turned back to the water
		ma15.skip_watch(false, 0.1)
		var ring15: bool = ma15.water_rings == r0 + 1 and ma15.last_water_ring != null and absf(ma15.last_water_ring.position.x - ma15.look_at.x) < 0.01 and ma15.last_water_ring.position.y < 0.0 and main.sfx_log.has("splash:520")
		ma15.skip_watch(false, 0.1)
		var once15: bool = ma15.water_rings == r0 + 1 and ma15.look_t == 0.0
		# too late
		reset_to(w15 if found15 else Vector2(2, 2))
		ma15.skip_watch(true, 0.1)
		reset_to(l15)
		ma15.skip_watch(false, 0.1)
		ma15.look_t = 0.05
		ma15.skip_watch(false, 0.1)
		main.player.face = Vector2(-1, 0)
		ma15.skip_watch(false, 0.1)
		var late15: bool = ma15.water_rings == r0 + 1
		# no companion
		var mate15: Node3D = main.mate
		reset_to(w15 if found15 else Vector2(2, 2))
		ma15.skip_watch(true, 0.1)
		reset_to(l15)
		ma15.skip_watch(false, 0.1)
		main.mate = null
		ma15.skip_watch(false, 0.1)
		var alone15: bool = ma15.water_rings == r0 + 1
		main.mate = mate15
		# too close to the water: standing on its edge
		reset_to(w15 + Vector2(0.6, 0.0) if found15 else Vector2(2, 2))
		main.player.face = Vector2(-1, 0)
		ma15.skip_watch(false, 0.1)
		var close15: bool = ma15.water_rings == r0 + 1
		ma15.look_t = 0.0
		check("d15_look_back", found15 and armed15 and away15 and ring15 and once15 and late15 and alone15 and close15,
			"a bank with water 3 tiles off found=%s the landing opens a 3 s look back=%s facing away: none=%s turning back makes one ring on the last water tile=%s only once=%s too late: none=%s no companion: none=%s on the edge: none=%s" % [found15, armed15, away15, ring15, once15, late15, alone15, close15])
	if want.call("d17_chest_look"):
		# E at a chest she has already opened sends Mulgyeol up to its side (0.9 tiles from it) for 1 s and then the ordinary following takes him back; a shut chest, him busy or her walking: none; the chest stays open and nothing is taken (idea 17)
		var ma17: Object = main.mates
		var wb17: Object = main.world_build
		marsh_world()
		main.join_mate()
		main.intro = false
		main.in_house = -1
		var keep17: Array = main.enemies.duplicate()
		main.enemies = []
		var c17: Dictionary = main.chests[0]
		var open17: bool = c17.open
		c17.open = true
		var gold17: int = main.player.gold
		var pots17: int = main.player.pots
		var at17 := Vector2(c17.x, c17.z)
		reset_to(at17)
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.mate_job = {}
		var started17: bool = false
		var used17 := Vector3(2.2, 0, 0)
		for dir in [Vector3(2.2, 0, 0), Vector3(-2.2, 0, 0), Vector3(0, 0, 2.2), Vector3(0, 0, -2.2)]:
			ma17.end_quirk()
			ma17.quirk_t = -100.0
			main.mate.position = Vector3(at17.x, 0, at17.y) + dir
			wb17.chest_peek_t = -10.0
			var l0: int = ma17.chest_looks
			if wb17.chest_peek():
				started17 = ma17.chest_looks == l0 + 1 and ma17.quirk.get("kind", "") == "chest"
				if started17:
					used17 = dir
					break
		for i in 60:
			ma17.update_quirk(0.05)
			if ma17.quirk.get("wait", 0.0) > 0.2:
				break
		var him17 := Vector2(main.mate.position.x, main.mate.position.z)
		var beside17: bool = started17 and absf(him17.distance_to(at17) - 0.9) < 0.1
		var empty17: bool = main.player.gold == gold17 and main.player.pots == pots17 and c17.open
		for i in 30:
			ma17.update_quirk(0.05)
		var done17: bool = ma17.quirk.is_empty()
		# a shut chest is no look, her walking ends one, a busy companion does none
		ma17.quirk_t = -100.0
		c17.open = false
		wb17.chest_peek_t = -10.0
		var shut17: bool = not wb17.chest_peek() and ma17.quirk.is_empty()
		c17.open = true
		main.mate.position = Vector3(at17.x, 0, at17.y) + used17
		wb17.chest_peek_t = -10.0
		ma17.quirk_t = -100.0
		var l1: int = ma17.chest_looks
		wb17.chest_peek()
		var restart17: bool = ma17.chest_looks == l1 + 1 or not started17
		main.player.vx = 3.0
		ma17.update_quirk(0.05)
		var stepped17: bool = ma17.quirk.is_empty()
		main.player.vx = 0.0
		ma17.quirk_t = -100.0
		main.mate_job = {"kind": "work", "home": Vector2.ZERO}
		var busy17: bool = not ma17.chest_look(at17)
		main.mate_job = {}
		c17.open = open17
		if not open17:
			c17.node.texture = main.chest_shut_tex
		main.enemies = keep17
		ma17.end_quirk()
		check("d17_chest_look", started17 and beside17 and empty17 and done17 and shut17 and restart17 and stepped17 and busy17,
			"E at an opened chest starts a look=%s he stands 0.9 tiles from it=%s nothing taken, chest stays open=%s it ends after 1 s=%s shut chest: none=%s a later look starts again=%s her step ends it=%s busy: none=%s" % [started17, beside17, empty17, done17, shut17, restart17, stepped17, busy17])
	if want.call("d22_letter"):
		# Doran reads a letter at each stop of his round (a paper before his chest); when she comes within 3.2 tiles, or a story opens, the paper hides and he turns to her; it comes back when she is 3.6+ tiles off and the story is shut; walking, a pass-through point or asleep: no paper (idea 22)
		var fk22: Object = main.folk
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var dspr: Sprite3D = main.village.folk_node.doran
		var home22: Vector2 = main.village.folk_pos.doran
		var keep_state: String = main.folk_state.get("doran", "out")
		var keep_route = main.folk_route.get("doran")
		var keep_vis: bool = dspr.visible
		var keep_pos: Vector3 = dspr.position
		var keep_flip: bool = dspr.flip_h
		main.folk_state["doran"] = "out"
		main.folk_route.erase("doran")
		dspr.visible = true
		dspr.position = Vector3(home22.x, 0, home22.y)
		fk22.letter_folded = false
		reset_to(home22 + Vector2(9.0, 0.0))
		fk22.update_letter()
		var built22: bool = fk22.letter != null and fk22.letter.get_parent() == dspr
		var reading22: bool = built22 and fk22.letter.visible
		var t0: int = fk22.letter_turns
		reset_to(home22 + Vector2(2.0, 0.0))
		fk22.update_letter()
		var folded22: bool = not fk22.letter.visible and fk22.letter_turns == t0 + 1
		var faces22: bool = dspr.flip_h == main.screen_left(Vector2(2.0, 0.0))
		fk22.update_letter()
		var once22: bool = fk22.letter_turns == t0 + 1
		main.show_story("", ["x"])
		reset_to(home22 + Vector2(3.4, 0.0)) # past the near line, but a story is open
		fk22.update_letter()
		var story22: bool = not fk22.letter.visible
		main.close_story()
		fk22.update_letter()
		var holds22: bool = not fk22.letter.visible # 3.4 is inside the 3.6 hysteresis
		reset_to(home22 + Vector2(5.0, 0.0))
		fk22.update_letter()
		var back22: bool = fk22.letter.visible
		# walking between stops, and a point he only passes
		main.folk_route["doran"] = {"i": 0, "wait": 5.0, "pos": home22 + Vector2(0.5, 0.0), "back": false, "dir": 1}
		fk22.update_letter()
		var walking22: bool = not fk22.letter.visible
		main.folk_route["doran"] = {"i": 1, "wait": 0.0, "pos": main.folk.route_at("doran", 1), "back": false, "dir": 1}
		fk22.update_letter()
		var passing22: bool = not fk22.letter.visible
		main.folk_route["doran"] = {"i": 0, "wait": 5.0, "pos": home22, "back": false, "dir": 1}
		fk22.update_letter()
		var stop22: bool = fk22.letter.visible
		main.folk_state["doran"] = "in"
		fk22.update_letter()
		var asleep22: bool = not fk22.letter.visible
		main.folk_state["doran"] = keep_state
		if keep_route == null:
			main.folk_route.erase("doran")
		else:
			main.folk_route["doran"] = keep_route
		dspr.visible = keep_vis
		dspr.position = keep_pos
		dspr.flip_h = keep_flip
		fk22.letter_folded = false
		main.in_village = false
		check("d22_letter", built22 and reading22 and folded22 and faces22 and once22 and story22 and holds22 and back22 and walking22 and passing22 and stop22 and asleep22,
			"a paper on his sprite=%s shown while he reads=%s she comes close: folded, one turn=%s he faces her=%s one turn only=%s story: folded=%s holds inside 3.6=%s she steps back: it returns=%s walking: none=%s pass-through point: none=%s at a stop: shown=%s asleep: none=%s" % [built22, reading22, folded22, faces22, once22, story22, holds22, back22, walking22, passing22, stop22, asleep22])
	if want.call("d23_twirl"):
		# once Kongal and the kid are home on their spots, one lap round them within 3.2 tiles makes them face opposite ways five times in turn (0.35 s each) and then as before; half a lap, a wide lap, a foe, a story, or one of them walking: none; 20 s between (idea 23)
		var vl23: Object = main.village_life
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var keep_kq: int = main.kid_q
		main.kid_q = 3
		main.place_kid()
		var kspr: Sprite3D = main.village.folk_node.kongal
		var home23: Vector2 = main.village.folk_pos.kongal
		var keep_state23: String = main.folk_state.get("kongal", "out")
		var keep_route23 = main.folk_route.get("kongal")
		var keep_vis23: bool = kspr.visible
		var keep_pos23: Vector3 = kspr.position
		var keep_flip23: bool = kspr.flip_h
		main.folk_state["kongal"] = "out"
		main.folk_route.erase("kongal")
		kspr.visible = true
		kspr.position = Vector3(home23.x, 0, home23.y)
		main.kid_node.visible = true
		main.kid_node.position = Vector3(home23.x + 0.7, 0, home23.y + 0.3)
		var kid_spr: Sprite3D = main.kid_node.get_meta("spr")
		var keep_kid_flip: bool = kid_spr.flip_h
		kspr.flip_h = false
		kid_spr.flip_h = false
		var keep_e23: Array = main.enemies.duplicate()
		main.enemies = []
		var mid23 := Vector2(home23.x + 0.35, home23.y + 0.15)
		var lap := func(r: float, laps: float) -> int:
			var n: int = int(laps * 40.0)
			for i in n:
				var a: float = TAU * i / 40.0
				main.player.x = mid23.x + cos(a) * r
				main.player.z = mid23.y + sin(a) * r
				vl23.update_twirl(0.1)
				if not vl23.twirl.is_empty():
					return i
			return -1
		vl23.twirl = {}
		vl23.twirl_acc = 0.0
		vl23.twirl_prev = INF
		vl23.twirl_age = 0.0
		vl23.twirl_done = -100.0
		var t23: int = vl23.twirls
		var half23: bool = lap.call(1.6, 0.5) == -1
		vl23.twirl_acc = 0.0
		vl23.twirl_prev = INF
		var wide23: bool = lap.call(5.0, 1.5) == -1
		main.show_story("", ["x"])
		var story23: bool = lap.call(1.6, 1.5) == -1
		main.close_story()
		main.enemies = [{"x": mid23.x + 3.0, "z": mid23.y, "dead": false}]
		var foe23: bool = lap.call(1.6, 1.5) == -1
		main.enemies = []
		main.folk_route["kongal"] = {"i": 0, "wait": 5.0, "pos": home23 + Vector2(0.4, 0.0), "back": false, "dir": 1}
		var walking23: bool = lap.call(1.6, 1.5) == -1
		main.folk_route.erase("kongal")
		vl23.twirl_acc = 0.0
		vl23.twirl_prev = INF
		var at_step: int = lap.call(1.6, 1.5)
		var began23: bool = at_step >= 25 and vl23.twirls == t23 + 1 and vl23.twirl.step == 0
		var opposite := true
		var seen: Array = []
		for k in vl23.TWIRL_TURNS:
			if k > 0:
				vl23.update_twirl(vl23.TWIRL_STEP + 0.01)
			if not vl23.twirl.is_empty():
				opposite = opposite and kspr.flip_h != kid_spr.flip_h
				seen.append(kspr.flip_h)
		var alternates: bool = seen == [true, false, true, false, true]
		vl23.update_twirl(vl23.TWIRL_STEP + 0.01)
		var restored23: bool = vl23.twirl.is_empty() and not kspr.flip_h and not kid_spr.flip_h
		var again23: int = lap.call(1.6, 1.5) # 20 s between
		var gap23: bool = again23 == -1 and vl23.twirls == t23 + 1
		main.enemies = keep_e23
		main.folk_state["kongal"] = keep_state23
		if keep_route23 != null:
			main.folk_route["kongal"] = keep_route23
		kspr.visible = keep_vis23
		kspr.position = keep_pos23
		kspr.flip_h = keep_flip23
		kid_spr.flip_h = keep_kid_flip
		main.kid_q = keep_kq
		main.in_village = false
		check("d23_twirl", half23 and wide23 and story23 and foe23 and walking23 and began23 and opposite and alternates and restored23 and gap23,
			"half a lap: none=%s wide lap: none=%s story: none=%s foe near: none=%s Kongal walking: none=%s a lap starts it (after %d steps)=%s they face opposite ways=%s five turns alternate=%s facing restored=%s 20 s between=%s" % [half23, wide23, story23, foe23, walking23, at_step, began23, opposite, alternates, restored23, gap23])
	if want.call("d24_can"):
		# in the target game a cut that strikes no target but reaches a can on the bench behind rattles it (four rocks, two clinks 1480 and 1180 Hz) and the keeper laughs once a round; the score does not move; a hit target, a closed game, facing away, too far or within 0.6 s: nothing (idea 24)
		var mk24: Object = main.market
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		calm_enemies(true)
		var built24: bool = mk24.cans.size() == 3 and mk24.can_anchor != null
		var can24: Dictionary = mk24.cans[1]
		var at24: Vector2 = can24.at
		reset_to(at24 + Vector2(0.0, 1.2))
		var keep_on: bool = main.target_on
		var keep_hits: int = main.target_hits
		main.target_on = false
		mk24.can_laughed = false
		var h0: int = mk24.can_hits
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, false)
		var closed24: bool = mk24.can_hits == h0
		main.target_on = true
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, true)
		var hit_target: bool = mk24.can_hits == h0
		mk24.can_hit(1.5, Vector2(0, 1), 0.3, false, false)
		var away24: bool = mk24.can_hits == h0
		reset_to(at24 + Vector2(0.0, 4.0))
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, false)
		var far24: bool = mk24.can_hits == h0
		reset_to(at24 + Vector2(0.0, 1.2))
		main.sfx_log.clear()
		var n_bub: int = main.bubbles_said
		var kids0: int = mk24.can_anchor.get_child_count()
		mk24.can_t = -10.0
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, false)
		var rattled: bool = mk24.can_hits == h0 + 1 and mk24.can_laughs >= 1 and main.sfx_log.has("triangle:1480") and mk24.can_anchor.get_child_count() == kids0 + 1 and main.bubbles_said == n_bub
		var score_same: bool = main.target_hits == keep_hits
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, false) # within 0.6 s of the last one
		var quick24: bool = mk24.can_hits == h0 + 1
		main.target_on = false # no frames of the game run with the game on: it would stand targets up
		await wait(0.15)
		var rocking: bool = absf(can24.node.rotation.z) > 0.01 and main.sfx_log.has("triangle:1180")
		await wait(0.7)
		var settled: bool = absf(can24.node.rotation.z) < 0.01 and is_equal_approx(can24.node.position.y, 0.56)
		main.target_on = true
		var laughs: int = mk24.can_laughs
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, false) # a second cut, same round: rattles, no second laugh
		var again24: bool = mk24.can_hits == h0 + 2 and mk24.can_laughs == laughs
		mk24.start_targets() # a new round laughs again
		main.target_on = true
		mk24.can_t = -10.0
		mk24.can_hit(1.5, Vector2(0, -1), 0.3, false, false)
		var next_round: bool = mk24.can_laughs == laughs + 1
		main.target_on = keep_on
		main.target_hits = keep_hits
		main.target_left = 0.0
		calm_enemies(false)
		main.in_village = false
		check("d24_can", built24 and closed24 and hit_target and away24 and far24 and rattled and rocking and score_same and quick24 and settled and again24 and next_round,
			"3 cans and a keeper's spot=%s game closed: none=%s a hit target: none=%s facing away: none=%s too far: none=%s a miss reaching a can rattles it, clinks, one bubble=%s it rocks=%s score unchanged=%s within 0.6 s: none=%s it settles=%s second cut rattles without a second laugh=%s a new round laughs again=%s" % [built24, closed24, hit_target, away24, far24, rattled, rocking, score_same, quick24, settled, again24, next_round])

	if want.call("d25_chalk"):
		# a villager who settles at a stop beside a lit lamp scratches one chalk dot at the lamp's foot (up to 5 a lamp), none beside a dark lamp, far from any lamp or out of the village; a new game day rubs them out; the lamps are not touched (idea 25)
		var fk25: Object = main.folk
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var lamps25: Array = main.village_life.village_lamps().filter(func(l): return not l.get_meta("dark", false) and l != main.dark_lamp)
		var built25: bool = lamps25.size() >= 2
		var lamp25: OmniLight3D = lamps25[0]
		var post25 := Vector2(lamp25.position.x - 0.3, lamp25.position.z)
		var count25: int = main.lanterns.size()
		var keep_day25: int = main.day
		main.day = 40
		fk25.update_chalk()
		var clean25: bool = fk25.chalk.is_empty() and fk25.chalk_day == 40
		var n0: int = fk25.chalk_made
		fk25.chalk_stop("dusol", post25 + Vector2(1.5, 0.0))
		var one25: bool = fk25.chalk_made == n0 + 1 and fk25.chalk.get(lamp25, []).size() == 1
		var dot25: MeshInstance3D = fk25.last_chalk
		var foot25: bool = Vector2(dot25.position.x, dot25.position.z).distance_to(post25) < 0.4 and dot25.position.y < 0.2
		await wait(0.4)
		var grown25: bool = dot25.scale.x > 0.95
		for i in 8:
			fk25.chalk_stop("dusol", post25 + Vector2(1.0, 0.5))
		var capped25: bool = fk25.chalk.get(lamp25, []).size() == fk25.CHALK_MAX
		var made_far: int = fk25.chalk_made
		fk25.chalk_stop("dusol", post25 + Vector2(30.0, 30.0))
		var far25: bool = fk25.chalk_made == made_far
		var other25: OmniLight3D = lamps25[1]
		var post_o := Vector2(other25.position.x - 0.3, other25.position.z)
		other25.set_meta("dark", true)
		fk25.chalk_stop("dusol", post_o)
		other25.set_meta("dark", false)
		var dark25: bool = fk25.chalk_made == made_far
		main.in_village = false
		fk25.chalk_stop("dusol", post_o)
		main.in_village = true
		var out25: bool = fk25.chalk_made == made_far
		# a real round: kongal reaches the stop at (10, 15), which stands 1.3 tiles from a lit lamp
		var hook_at: Vector2 = fk25.route_at("kongal", 0)
		var keep_route = main.folk_route.get("kongal")
		reset_to(hook_at + Vector2(12.0, 0.0))
		main.folk_route["kongal"] = {"i": 0, "wait": 0.0, "pos": hook_at - Vector2(0.02, 0.0), "back": false, "dir": 1}
		fk25.route_update("kongal", 0.1, false, 1.0)
		var hook25: bool = fk25.chalk_made > made_far or fk25.chalk.values().any(func(a): return a.size() == fk25.CHALK_MAX)
		if keep_route == null:
			main.folk_route.erase("kongal")
		else:
			main.folk_route["kongal"] = keep_route
		var old25: Array = []
		for dots in fk25.chalk.values():
			old25.append_array(dots)
		main.day = 41
		fk25.update_chalk()
		var rubbed25: bool = fk25.chalk.is_empty() and fk25.chalk_day == 41
		await wait(0.15)
		var gone25: bool = old25.all(func(d): return not is_instance_valid(d))
		var lamps_same: bool = main.lanterns.size() == count25 and not lamp25.get_meta("dark", false)
		main.day = keep_day25
		fk25.chalk_day = -1
		main.in_village = false
		check("d25_chalk", built25 and clean25 and one25 and foot25 and grown25 and capped25 and far25 and dark25 and out25 and hook25 and rubbed25 and gone25 and lamps_same,
			"2 lit lamps=%s a new day starts clean=%s a stop by a lamp: one dot=%s at its foot=%s it grows=%s capped at 5=%s far from lamps: none=%s dark lamp: none=%s outside the village: none=%s a real stop makes one=%s a new day rubs them out=%s freed=%s lamps unchanged=%s" % [built25, clean25, one25, foot25, grown25, capped25, far25, dark25, out25, hook25, rubbed25, gone25, lamps_same])
	if want.call("d28_inn_cup"):
		# two stays in a row from the same side of the inn's door set a cup of tea on that side (x offset 0.9, z 0.4 before the mark); another side starts over; too little gold changes nothing; both numbers are saved (idea 28)
		var mk28: Object = main.market
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		calm_enemies(true)
		var keep28 := {"gold": main.player.gold, "hour": main.hour, "day": main.day, "nights": main.inn_nights, "side": mk28.inn_side, "streak": mk28.inn_streak, "fresh": mk28.inn_fresh}
		var n28: Vector2 = main.village.marks.N
		main.player.gold = 100
		main.inn_nights = 2 # not the first night: no talk
		mk28.inn_side = 0
		mk28.inn_streak = 0
		mk28.inn_cup_show()
		var built28: bool = mk28.inn_cup != null and not mk28.inn_cup.visible
		var sides28: bool = mk28.inn_side_of(n28.x + 0.6) == 1 and mk28.inn_side_of(n28.x - 0.6) == -1 and mk28.inn_side_of(n28.x + 0.1) == 0
		reset_to(n28 + Vector2(0.6, 1.0))
		mk28.stay_inn()
		await wait(0.95)
		var first28: bool = mk28.inn_streak == 1 and mk28.inn_side == 1 and not mk28.inn_cup.visible
		reset_to(n28 + Vector2(0.5, 1.0))
		mk28.stay_inn()
		await wait(0.95)
		var cup28: bool = mk28.inn_streak == 2 and mk28.inn_cup.visible and is_equal_approx(mk28.inn_cup.position.x, n28.x + 0.9) and is_equal_approx(mk28.inn_cup.position.z, n28.y - 0.4)
		var saved28 := {}
		var f28 := FileAccess.open(main.SAVE_PATH, FileAccess.READ)
		if f28 != null:
			var parsed28: Variant = JSON.parse_string(f28.get_as_text())
			if parsed28 is Dictionary:
				saved28 = parsed28
			f28.close()
		var save28: bool = saved28.get("inn_side", -9) == 1 and saved28.get("inn_streak", -9) == 2
		reset_to(n28 + Vector2(-0.7, 1.0))
		mk28.stay_inn()
		await wait(0.95)
		var other28: bool = mk28.inn_streak == 1 and mk28.inn_side == -1 and not mk28.inn_cup.visible
		reset_to(n28 + Vector2(-0.4, 1.0))
		mk28.stay_inn()
		await wait(0.95)
		var left28: bool = mk28.inn_streak == 2 and mk28.inn_cup.visible and is_equal_approx(mk28.inn_cup.position.x, n28.x - 0.9)
		main.player.gold = 5
		reset_to(n28 + Vector2(0.9, 1.0))
		var nights28: int = main.inn_nights
		mk28.stay_inn()
		await wait(0.2)
		var poor28: bool = mk28.inn_streak == 2 and mk28.inn_side == -1 and main.inn_nights == nights28
		mk28.inn_side = keep28.side
		mk28.inn_streak = keep28.streak
		mk28.inn_fresh = keep28.fresh
		mk28.inn_cup_show()
		main.player.gold = keep28.gold
		main.hour = keep28.hour
		main.day = keep28.day
		main.inn_nights = keep28.nights
		main.in_village = false
		calm_enemies(false)
		check("d28_inn_cup", built28 and sides28 and first28 and cup28 and save28 and other28 and left28 and poor28,
			"a hidden cup is built=%s side from x=%s first stay: no cup=%s second stay from the same side: cup on that side=%s both numbers saved=%s another side starts over=%s two on the left: cup on the left=%s too poor: unchanged=%s" % [built28, sides28, first28, cup28, save28, other28, left28, poor28])
	if want.call("d32_rain_rings"):
		# in the rain rings open on the marsh water within 9 tiles of her, at most 24 at once, never on a tile a bridge deck covers; dry, indoors or out of the marsh: none (idea 32)
		var ef32: Object = main.effects
		marsh_world()
		main.intro = false
		main.in_house = -1
		var wb32: Object = main.world_build
		var b32: Dictionary = main.bridges[0]
		var cover32: bool = wb32.deck_tiles.has(Vector2i(int((b32.a + b32.b) / 2), b32.z)) and wb32.deck_tiles.has(Vector2i(b32.a - 1, b32.z + 1)) and wb32.deck_tiles.has(Vector2i(b32.b + 1, b32.z))
		reset_to(Vector2((b32.a + b32.b) / 2.0, b32.z + 0.5))
		main.raining = false
		var r0: int = ef32.rain_rings
		ef32.rain_ring_t = 0.0
		ef32.update_rain_rings(0.01)
		var dry32: bool = ef32.rain_rings == r0
		main.raining = true
		main.in_house = 0
		ef32.rain_ring_t = 0.0
		ef32.update_rain_rings(0.01)
		var in32: bool = ef32.rain_rings == r0
		main.in_house = -1
		main.in_village = true
		ef32.rain_ring_t = 0.0
		ef32.update_rain_rings(0.01)
		var out32: bool = ef32.rain_rings == r0
		main.in_village = false
		var on_water := true
		var off_deck := true
		var near32 := true
		for i in 300: # no frame runs in this loop, so the rings stay open: the 24th is the last
			ef32.rain_ring_t = 0.0
			var before: int = ef32.rain_rings
			ef32.update_rain_rings(0.01)
			if ef32.rain_rings > before:
				var tl: Vector2i = ef32.last_rain_ring
				on_water = on_water and main.map[main.idx(tl.x, tl.y)] == main.WATER
				off_deck = off_deck and not wb32.deck_tiles.has(tl)
				near32 = near32 and absi(tl.x - int(round(main.player.x))) <= 9 and absi(tl.y - int(round(main.player.z))) <= 9
		var made32: bool = ef32.rain_rings == r0 + 24
		var cap32: bool = ef32.rain_ring_live == ef32.RAIN_RING_CAP
		main.raining = false # or the next frames open more
		await wait(1.1)
		var done32: bool = ef32.rain_ring_live == 0
		main.raining = false
		ef32.rain_ring_t = 0.0
		calm_enemies(false)
		check("d32_rain_rings", cover32 and dry32 and in32 and out32 and on_water and off_deck and near32 and made32 and cap32 and done32,
			"deck tiles marked=%s dry: none=%s indoors: none=%s out of the marsh: none=%s rings on water=%s never on a deck tile=%s within 9 tiles=%s many made=%s at most 24 at once=%s all gone in a second=%s" % [cover32, dry32, in32, out32, on_water, off_deck, near32, made32, cap32, done32])
	if want.call("d33_roof_rain"):
		# under a roof (cottage porch, a stall's awning, the inn's eave, a house door's eave) the rain is sown in a ring bare out to the roof's nearest edge; in the open, dry, or indoors it is the whole box; the weather itself is untouched (idea 33)
		var ef33: Object = main.effects
		var wb33: Object = main.world_build
		main.close_story()
		main.intro = false
		main.in_house = -1
		main.in_village = true
		var built33: bool = wb33.roof_rects.size() >= 5 + main.village.doors.size()
		var at33: Vector2 = main.village.marks["1"]
		main.raining = true
		main.rain.emitting = true
		reset_to(at33 + Vector2(0.5, -0.6))
		ef33.update_rain_shelter()
		var i33: int = wb33.roof_at(Vector2(main.player.x, main.player.z))
		var under33: bool = i33 >= 0 and ef33.rain_cut > 0.0 and main.rain.emission_shape == CPUParticles3D.EMISSION_SHAPE_RING and is_equal_approx(main.rain.emission_ring_inner_radius, ef33.rain_cut)
		var inside33: bool = under33 and ef33.rain_cut <= wb33.roof_edge(i33, Vector2(main.player.x, main.player.z))
		var open_pt: Vector2 = at33
		for off in [Vector2(0, 4), Vector2(4, 4), Vector2(-4, 4), Vector2(0, -4), Vector2(4, 0), Vector2(-4, 0)]:
			if wb33.roof_at(at33 + off) < 0:
				open_pt = at33 + off
				break
		reset_to(open_pt)
		ef33.update_rain_shelter()
		var open33: bool = ef33.rain_cut == 0.0 and main.rain.emission_shape == CPUParticles3D.EMISSION_SHAPE_BOX and is_equal_approx(main.rain.emission_box_extents.x, 14.0)
		var edge_pt: Vector2 = at33 + Vector2(-0.76, -0.6) # just past the awning's end
		reset_to(edge_pt)
		ef33.update_rain_shelter()
		var beside33: bool = wb33.roof_at(edge_pt) >= 0 or (ef33.rain_cut == 0.0 and main.rain.emission_shape == CPUParticles3D.EMISSION_SHAPE_BOX)
		reset_to(at33 + Vector2(0.5, -0.6))
		main.raining = false
		ef33.update_rain_shelter()
		var dry33: bool = ef33.rain_cut == 0.0 and main.rain.emission_shape == CPUParticles3D.EMISSION_SHAPE_BOX
		main.raining = true
		main.in_house = 0
		ef33.update_rain_shelter()
		var in33: bool = ef33.rain_cut == 0.0
		main.in_house = -1
		var n33: Vector2 = main.village.marks.N
		reset_to(n33 + Vector2(0.0, -0.4))
		ef33.update_rain_shelter()
		var inn33: bool = ef33.rain_cut > 0.0
		var d33: Vector2 = main.village.doors[0]
		reset_to(d33 + Vector2(0.0, -1.0))
		ef33.update_rain_shelter()
		var door33: bool = ef33.rain_cut > 0.0
		reset_to(Vector2(main.shop_pos.x, main.shop_pos.z - 0.5))
		main.in_village = false
		ef33.update_rain_shelter()
		var porch33: bool = ef33.rain_cut > 0.0
		var weather33: bool = main.raining and main.rain.emitting
		main.raining = false
		main.rain.emitting = false
		ef33.update_rain_shelter()
		check("d33_roof_rain", built33 and under33 and inside33 and open33 and beside33 and dry33 and in33 and inn33 and door33 and porch33 and weather33,
			"roof rectangles built=%s under an awning: a ring=%s bare no further than the edge=%s open sky: the whole box=%s past the awning's end: whole=%s dry: whole=%s indoors: whole=%s inn eave=%s a door's eave=%s the cottage porch=%s the weather untouched=%s" % [built33, under33, inside33, open33, beside33, dry33, in33, inn33, door33, porch33, weather33])
	if want.call("d35_lamp_moths"):
		# three small dark-winged moths gather round the nearest lit lamp as evening comes (night 0.35 to 0.7), tight at night (within 0.34 + 0.1), and open out again at dawn until they are gone; none by day, none at a dark lamp, none far from every lamp; no foes, no sounds (idea 35)
		var wb35: Object = main.world_build
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var lamp35: OmniLight3D = main.village_life.village_lamps().filter(func(l): return not l.get_meta("dark", false) and l != main.dark_lamp)[0]
		var keep_night: float = main.night
		var foes35: int = main.enemies.size()
		var log35: int = main.sfx_log.size()
		var built35: bool = wb35.moths.size() == 3
		reset_to(Vector2(lamp35.position.x + 2.0, lamp35.position.z))
		wb35.moth_lamp = null
		wb35.moth_seek_t = 0.0
		main.night = 0.1
		wb35.update_lamp_moths(0.05)
		var day35: bool = wb35.moth_gather == 0.0 and wb35.moths.all(func(mo): return not mo.node.visible)
		main.night = 0.5
		wb35.moth_seek_t = 0.0
		wb35.update_lamp_moths(0.05)
		var dusk35: bool = is_equal_approx(wb35.moth_gather, smoothstep(0.35, 0.7, 0.5)) and wb35.moths.all(func(mo): return mo.node.visible) and wb35.moth_lamp != null
		var dusk_d: float = 0.0
		for mo in wb35.moths:
			dusk_d = maxf(dusk_d, Vector2(mo.node.position.x - wb35.moth_lamp.position.x, mo.node.position.z - wb35.moth_lamp.position.z).length())
		main.night = 1.0
		wb35.update_lamp_moths(0.05)
		var night_d: float = 0.0
		for mo in wb35.moths:
			night_d = maxf(night_d, Vector2(mo.node.position.x - wb35.moth_lamp.position.x, mo.node.position.z - wb35.moth_lamp.position.z).length())
		var tight35: bool = wb35.moth_gather == 1.0 and night_d < 0.34 + 0.1 + 0.01 and dusk_d > night_d
		var wide35: bool = true
		main.night = 0.4 # dawn: the ring opens again
		wb35.update_lamp_moths(0.05)
		var dawn_d: float = 0.0
		for mo in wb35.moths:
			dawn_d = maxf(dawn_d, Vector2(mo.node.position.x - wb35.moth_lamp.position.x, mo.node.position.z - wb35.moth_lamp.position.z).length())
		wide35 = dawn_d > dusk_d
		main.night = 0.2
		wb35.update_lamp_moths(0.05)
		var gone35: bool = wb35.moths.all(func(mo): return not mo.node.visible)
		var wing35: bool = absf(wb35.moths[0].wings[0].rotation.z + wb35.moths[0].wings[1].rotation.z) < 0.001
		main.night = 1.0
		lamp35.set_meta("dark", true)
		wb35.moth_seek_t = 0.0
		wb35.update_lamp_moths(0.05)
		var dark35: bool = wb35.moth_lamp != lamp35
		lamp35.set_meta("dark", false)
		reset_to(Vector2(-200.0, -200.0))
		wb35.moth_lamp = null
		wb35.moth_seek_t = 0.0
		wb35.update_lamp_moths(0.05)
		var far35: bool = wb35.moth_lamp == null and wb35.moths.all(func(mo): return not mo.node.visible)
		var quiet35: bool = main.enemies.size() == foes35 and main.sfx_log.size() == log35
		main.night = keep_night
		wb35.moth_lamp = null
		wb35.update_lamp_moths(0.0)
		main.in_village = false
		check("d35_lamp_moths", built35 and day35 and dusk35 and tight35 and wide35 and gone35 and wing35 and dark35 and far35 and quiet35,
			"3 moths=%s by day: none=%s dusk: all three round the nearest lamp=%s night: tight (%.2f)=%s dawn: opens again (%.2f > %.2f)=%s gone by morning=%s wings beat in turn=%s a dark lamp: not that one=%s far from lamps: none=%s no foes, no sound=%s" % [built35, day35, dusk35, night_d, tight35, dawn_d, dusk_d, wide35, gone35, wing35, dark35, far35, quiet35])
	if want.call("d43_room_echo"):
		# in the castle's treasury, the doorkeeper's stand room and the west guard room a footstep comes back once, 0.3 s later, as a quiet low tick (triangle 96) if no foe lives in the room and she is still in it; outside a room, a step out, a story or a newer step: none (idea 43)
		var cz43: Object = main.castle_zone
		var cx43: float = main.CASTLE.CASTLE_X
		var keep_en: Array = main.enemies
		main.enemies = []
		main.close_story()
		main.intro = false
		main.in_hill = true
		reset_to(Vector2(cx43 + 15.0, 3.0))
		var room1 := Vector2(cx43 + 26.5, 23.0)
		var room2 := Vector2(cx43 + 19.0, 36.0)
		var room3 := Vector2(cx43 + 4.0, 13.0)
		var hall := Vector2(cx43 + 15.0, 3.0)
		var tags43: bool = cz43.echo_room(room1) == 0 and cz43.echo_room(room2) == 1 and cz43.echo_room(room3) == 2 and cz43.echo_room(hall) == -1
		reset_to(room1)
		main.sfx_log.clear()
		var e0: int = cz43.echoes
		cz43.step_echo()
		await wait(0.5)
		var heard43: bool = cz43.echoes == e0 + 1 and main.sfx_log.has("triangle:96")
		await wait(0.4)
		var once43: bool = cz43.echoes == e0 + 1
		cz43.step_echo()
		reset_to(hall) # steps out of the room before the echo is due
		await wait(0.5)
		var left43: bool = cz43.echoes == e0 + 1
		reset_to(room1)
		cz43.step_echo()
		cz43.step_echo() # the newer step takes the wait
		await wait(0.5)
		var newer43: bool = cz43.echoes == e0 + 2
		reset_to(hall)
		cz43.step_echo()
		await wait(0.5)
		var open43: bool = cz43.echoes == e0 + 2
		reset_to(room3)
		main.enemies = [{"x": room3.x + 1.0, "z": room3.y, "dead": false}]
		var foe43: bool = cz43.echo_room(room3) == -1
		main.enemies = [{"x": room3.x + 1.0, "z": room3.y, "dead": true}, {"x": room3.x + 1.0, "z": room3.y, "dead": false, "prop": true}]
		var live43: bool = cz43.echo_room(room3) == 2
		main.enemies = []
		main.show_story("", ["x"])
		cz43.step_echo()
		await wait(0.5)
		var story43: bool = cz43.echoes == e0 + 2
		main.close_story()
		main.in_hill = false
		var land43: bool = cz43.echo_room(room1) == -1
		main.enemies = keep_en
		check("d43_room_echo", tags43 and heard43 and once43 and left43 and newer43 and open43 and foe43 and live43 and story43 and land43,
			"three rooms tagged, the hall not=%s a step in a room echoes once, quietly=%s only once=%s stepping out first: none=%s a newer step takes the wait=%s outside a room: none=%s a live foe in the room: none=%s a dead foe or a prop: still echoes=%s a story open: none=%s out of the castle: none=%s" % [tags43, heard43, once43, left43, newer43, open43, foe43, live43, story43, land43])
	if want.call("d46_fountain_quiet"):
		# the fountain makes no sound of its own (the owner, 2026-10-31: "광장 분수대 소리는 없애"): beside the full basin, running, no loop plays; a blow still slaps the water (fountain_splash)
		var am46: Object = main.ambience
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var keep46 := {"wet": main.village.fountain_wet, "x": main.player.x, "z": main.player.z}
		main.village.fountain_wet = true
		reset_to(main.village.fountain_at() + Vector2(1.0, 0.0))
		var before46: int = am46.players.size()
		for i in 12:
			am46.update(0.1)
		var none46: bool = not am46.gains.has("water") and not am46.players.has("water") and am46.players.size() == before46
		main.village.fountain_wet = keep46.wet
		reset_to(Vector2(keep46.x, keep46.z))
		main.in_village = false
		check("d46_fountain_quiet", none46, "at the running basin no loop plays: %s" % none46)
	if want.call("d48_story_hush"):
		# a picture scene (not a talk) shuts the ambience loops fast (4 a second); after it closes they stay shut 0.5 s, then come back over 1.5 s without a jump (step under 0.1 per 0.1 s); a talk does nothing; the music and the sound switch are not touched (idea 48)
		var am48: Object = main.ambience
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var keep48 := {"raining": main.raining, "music_on": main.music_on, "muted": main.muted, "bus": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), "target": main.music.bus_target}
		main.raining = true
		am48.gains["rain"] = 1.0
		am48.duck = 1.0
		am48.duck_hold = 0.0
		main.show_story("", ["x"]) # a talk
		for i in 6:
			am48.update(0.1)
		var talk48: bool = am48.duck == 1.0 and is_equal_approx(am48.heard("rain"), 1.0) and am48.players["rain"].playing
		main.close_story()
		main.show_story("res://art/story/02_lantern.jpg", ["x"]) # a picture scene
		am48.update(0.1)
		var closing48: bool = is_equal_approx(am48.duck, 0.6) and am48.heard("rain") < 1.0 and am48.players["rain"].playing
		for i in 6:
			am48.update(0.1)
		var shut48: bool = am48.duck == 0.0 and am48.heard("rain") == 0.0 and not am48.players["rain"].playing
		main.close_story()
		am48.update(0.3)
		am48.update(0.1)
		var gap48: bool = am48.duck == 0.0 and not am48.players["rain"].playing
		var last48: float = 0.0
		var smooth48 := true
		var up48 := true
		var back_at := -1.0
		for i in 40:
			am48.update(0.1)
			var h: float = am48.heard("rain")
			smooth48 = smooth48 and h - last48 < 0.12
			up48 = up48 and h >= last48 - 0.0001
			if back_at < 0.0 and am48.duck >= 1.0:
				back_at = 0.1 * (i + 1)
			last48 = h
		var back48: bool = is_equal_approx(am48.duck, 1.0) and is_equal_approx(am48.heard("rain"), 1.0) and back_at > 1.2 and back_at < 2.0
		var music48: bool = main.music_on == keep48.music_on and main.muted == keep48.muted and main.music.bus_target == keep48.target and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), keep48.bus)
		main.muted = true
		am48.update(0.0)
		var muted48: bool = not am48.players["rain"].playing
		main.muted = keep48.muted
		main.raining = keep48.raining
		am48.gains["rain"] = 0.0
		am48.duck = 1.0
		am48.update(0.0)
		main.in_village = false
		check("d48_story_hush", talk48 and closing48 and shut48 and gap48 and smooth48 and up48 and back48 and music48 and muted48,
			"a talk leaves the loops=%s a picture scene starts to shut them=%s shut within 0.6 s=%s still shut 0.4 s after it closes=%s the return is smooth=%s and only upward=%s back to full in 1.2 to 2 s (%.1f)=%s the music and the sound switch untouched=%s a muted game stays silent=%s" % [talk48, closing48, shut48, gap48, smooth48, up48, back_at, back48, music48, muted48])
	if want.call("d50_rain_house"):
		# in the rain the open-air loop is 1.0 outdoors and 0.2 inside a house while the eave's round taps take over (0.8); the two cross over at 1.2 a second; dry: both none; the weather state is not changed (idea 50)
		var am50: Object = main.ambience
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var keep50 := {"raining": main.raining, "emitting": main.rain.emitting, "duck": am50.duck}
		am50.duck = 1.0
		am50.duck_hold = 0.0
		main.raining = true
		var out50: bool = am50.rain_target() == 1.0 and am50.eave_target() == 0.0
		main.in_house = 0
		var in50: bool = is_equal_approx(am50.rain_target(), 0.2) and is_equal_approx(am50.eave_target(), 0.8) and am50.eave_target() > am50.rain_target()
		main.in_house = -1
		am50.gains["rain"] = 1.0
		am50.gains["eave"] = 0.0
		am50.update(0.0)
		var loud50: bool = am50.players["rain"].playing and not (am50.players.has("eave") and am50.players["eave"].playing)
		main.in_house = 0
		am50.update(0.1)
		var cross50: bool = is_equal_approx(am50.gains["rain"], 0.88) and is_equal_approx(am50.gains["eave"], 0.12) and am50.players["eave"].playing
		for i in 8:
			am50.update(0.1)
		var inside50: bool = is_equal_approx(am50.gains["rain"], 0.2) and is_equal_approx(am50.gains["eave"], 0.8) and am50.players["eave"].playing and am50.players["rain"].playing and am50.players["eave"].volume_db > am50.players["rain"].volume_db
		main.in_house = -1
		for i in 8:
			am50.update(0.1)
		var back50: bool = is_equal_approx(am50.gains["rain"], 1.0) and is_equal_approx(am50.gains["eave"], 0.0) and not am50.players["eave"].playing
		var taps50: bool = am50.make_loop("eave").loop_end == int(am50.RATE * am50.LOOP_SECS) and am50.make_loop("eave").loop_mode == AudioStreamWAV.LOOP_FORWARD
		var weather50: bool = main.raining and main.rain.emitting == keep50.emitting
		main.raining = false
		main.in_house = 0
		var dry50: bool = am50.rain_target() == 0.0 and am50.eave_target() == 0.0
		main.in_house = -1
		main.raining = keep50.raining
		am50.gains["rain"] = 0.0
		am50.gains["eave"] = 0.0
		am50.duck = keep50.duck
		am50.update(0.0)
		main.in_village = false
		check("d50_rain_house", out50 and in50 and loud50 and cross50 and inside50 and back50 and taps50 and weather50 and dry50,
			"outdoors the open rain=%s indoors a murmur and the taps=%s the taps are off outdoors=%s a step in: crossing at 1.2 a second=%s settled inside=%s back out: the taps stop=%s a two second tap loop=%s the weather untouched=%s dry: both none=%s" % [out50, in50, loud50, cross50, inside50, back50, taps50, weather50, dry50])
	if want.call("d53_door_stick"):
		# a shot stopped by a village house's wall at its door leaves a short stick that shivers, drops and goes in 1.2 s (4 sticks reused); damage and the wall are as before; a shot that runs out, hits her, is far from a door, or flies outside the village leaves none (idea 53)
		var ef53: Object = main.effects
		main.in_village = true
		main.in_house = -1
		main.intro = false
		main.close_story()
		var d53: Vector2 = main.village.doors[0]
		reset_to(d53 + Vector2(8.0, 6.0))
		var keep_shots: Array = main.enemy_shots.duplicate()
		main.enemy_shots.clear()
		var wall53: bool = not main.walkable(d53.x, d53.y - 0.7)
		var hp53: float = main.player.hp
		var s0: int = ef53.stick_made
		var shot53: MeshInstance3D = main.box(Vector3(0.3, 0.2, 0.2), main.mat_color(Color("#c0522a")))
		shot53.position = Vector3(d53.x, 0.6, d53.y - 0.1)
		main.add_child(shot53)
		main.enemy_shots.append({"node": shot53, "v": Vector2(0, -6), "life": 1.2, "owner": {}, "dmg": 10})
		main.monsters.update_enemy_shots(0.1)
		var made53: bool = ef53.stick_made == s0 + 1 and main.enemy_shots.is_empty() and ef53.last_stick.visible and main.player.hp == hp53
		var stick53: Node3D = ef53.last_stick
		var faces53: bool = absf(stick53.rotation.y - atan2(0.0, -1.0)) < 0.01 and Vector2(stick53.position.x, stick53.position.z).distance_to(d53) < 1.2
		await wait(0.02)
		var y_first: float = stick53.position.y
		var shiver: float = absf(stick53.rotation.z)
		for i in 8:
			await wait(0.015)
			shiver = maxf(shiver, absf(stick53.rotation.z))
		var shiver53: bool = shiver > 0.02 and y_first > 0.3
		await wait(0.4)
		var down53: bool = stick53.position.y < 0.1 and stick53.visible
		await wait(0.8)
		var gone53: bool = not stick53.visible
		# a shot that runs out of life beside the door, one that hits her, and one flying away from every door
		var s1: int = ef53.stick_made
		var late53: MeshInstance3D = main.box(Vector3(0.3, 0.2, 0.2), main.mat_color(Color("#c0522a")))
		late53.position = Vector3(d53.x, 0.6, d53.y - 0.1)
		main.add_child(late53)
		main.enemy_shots.append({"node": late53, "v": Vector2(0, -6), "life": 0.05, "owner": {}, "dmg": 10})
		main.monsters.update_enemy_shots(0.1)
		var spent53: bool = ef53.stick_made == s1
		var far_pt: Vector2 = d53 + Vector2(12.0, 0.0)
		for off in [Vector2(12, 0), Vector2(-12, 0), Vector2(0, 12), Vector2(0, -12), Vector2(12, 12)]:
			if main.village.doors.all(func(dd): return dd.distance_to(d53 + off) > 3.0):
				far_pt = d53 + off
				break
		ef53.arrow_stick(Vector3(far_pt.x, 0.6, far_pt.y), Vector2(0, -1))
		var far53: bool = ef53.stick_made == s1
		main.in_village = false
		ef53.arrow_stick(Vector3(d53.x, 0.6, d53.y - 0.7), Vector2(0, -1))
		var out53: bool = ef53.stick_made == s1
		main.in_village = true
		main.in_house = 0
		ef53.arrow_stick(Vector3(d53.x, 0.6, d53.y - 0.7), Vector2(0, -1))
		var in53: bool = ef53.stick_made == s1
		main.in_house = -1
		for i in 6:
			ef53.arrow_stick(Vector3(d53.x, 0.6, d53.y - 0.7), Vector2(0, -1))
		var pool53: bool = ef53.sticks.size() == 4 and ef53.stick_made == s1 + 6
		await wait(1.4)
		var hidden53: bool = ef53.sticks.all(func(s): return not s.visible)
		main.enemy_shots = keep_shots
		main.in_village = false
		check("d53_door_stick", wall53 and made53 and faces53 and shiver53 and down53 and gone53 and spent53 and far53 and out53 and in53 and pool53 and hidden53,
			"the wall stops a shot at the door=%s one stick, no damage=%s it points along the shot=%s it shivers=%s it drops=%s and goes=%s a spent shot: none=%s far from a door: none=%s outside the village: none=%s indoors: none=%s four sticks reused=%s all hidden again=%s" % [wall53, made53, faces53, shiver53, down53, gone53, spent53, far53, out53, in53, pool53, hidden53])

	if want.call("d65_map_back"):
		# the third return to the same crossing (after leaving it 6 tiles) makes her next safe rest the map act and names only the region (idea 65)
		var was65: Array = fb_start()
		var s65: Object = main.sora
		var vx65: float = main.village.VILLAGE_X
		var j65 := Vector2(vx65 + 25.0, 10.0)
		s65.junction_at = -1
		s65.junction_count = [0, 0]
		s65.map_due = false
		var acts65: int = s65.map_acts
		reset_to(j65)
		s65.track_junction()
		var first65: bool = s65.junction_count[0] == 1 and not s65.map_due
		reset_to(j65 + Vector2(4.0, 0.0)) # a short step away is not a leaving
		s65.track_junction()
		reset_to(j65)
		s65.track_junction()
		var jitter65: bool = s65.junction_count[0] == 1
		reset_to(j65 + Vector2(8.0, 0.0))
		s65.track_junction()
		reset_to(j65)
		s65.track_junction()
		var second65: bool = s65.junction_count[0] == 2 and not s65.map_due
		reset_to(j65 + Vector2(8.0, 0.0))
		s65.track_junction()
		reset_to(j65)
		s65.track_junction()
		var third65: bool = s65.map_due and s65.junction_count[0] == 0
		reset_to(j65 + Vector2(8.0, 0.0)) # resting away from the crossing: not yet
		s65.idle_pick()
		var away65: bool = s65.map_acts == acts65 and s65.map_due
		reset_to(j65)
		main.story_open = true
		s65.idle_pick()
		var story65: bool = s65.map_acts == acts65 and s65.map_due
		main.story_open = false
		main.ui.zone_name.text = "등불 마을"
		var pick65: String = s65.idle_pick()
		s65.idle_begin()
		var map65: bool = pick65 == "rest-map" and s65.map_acts == acts65 + 1 and s65.idle_cause == "map" and not s65.map_due
		var named65: bool = main.ui.toast.text.contains("등불 마을")
		s65.idle_pick()
		var once65: bool = s65.map_acts == acts65 + 1
		s65.idle_cause = ""
		fb_end(was65)
		check("d65_map_back", first65 and jitter65 and second65 and third65 and away65 and story65 and map65 and named65 and once65,
			"first visit counted=%s a short step is no leaving=%s second=%s third arms the map=%s away: not yet=%s a story open: not yet=%s the map act=%s names the region=%s once=%s" % [first65, jitter65, second65, third65, away65, story65, map65, named65, once65])
	if want.call("d73_bell_answer"):
		# three bells struck lowest note first (post 2, post 1, post 3), the far bell rings the three notes back 0.7 s later; a wrong order or a slow one is not answered; nothing is given (idea 73)
		var was73: Array = fb_start()
		var v73: Object = main.village
		var gold73: int = main.player.gold
		var pots73: int = main.player.pots
		var xp73: int = main.player.xp
		var pips73: int = main.crown_pips
		var strike73 := func(i: int):
			var pv: Node3D = v73.bells[i].pivot
			fb_put(Vector2(20.0, 15.0), Vector2(pv.global_position.x - v73.VILLAGE_X, pv.global_position.z + 1.0), Vector2(0, -1))
			v73.bells_update(main, 1.0)
			main.attack()
		var far73: bool = v73.bell_far != null and v73.bell_far.global_position.distance_to(v73.bells[0].pivot.global_position) > 25.0 and v73.bells.size() == 3
		var order73: bool = v73.bells[1].note < v73.bells[0].note and v73.bells[0].note < v73.bells[2].note # the lowest note is post 2
		var h0: int = v73.bell_hits
		strike73.call(0) # a wrong order: middle, highest
		strike73.call(2)
		strike73.call(1)
		var wrong73: bool = v73.bell_hits == h0 + 3 and v73.bell_answers == 0
		await wait(1.2)
		var silent73: bool = v73.bell_far_rings == 0
		strike73.call(1) # right: lowest, middle, highest
		strike73.call(0)
		var gap73: bool = v73.bell_answers == 0
		strike73.call(2)
		var asked73: bool = v73.bell_answers == 1 and v73.bell_far_rings == 0 # not before the beat
		var peak73 := 0.0
		for i in 40:
			await wait(0.05)
			peak73 = maxf(peak73, absf(v73.bell_far.rotation.z))
		var rang73: bool = v73.bell_far_rings >= 1 and peak73 > 0.05
		await wait(0.6)
		var three73: bool = v73.bell_far_rings == 3
		var notes73: bool = main.sfx_log.size() >= 3 and main.sfx_log.slice(main.sfx_log.size() - 3) == ["sine:523", "sine:659", "sine:784"]
		strike73.call(1) # too slow: the next bell comes after the gap
		v73.bell_last = main.t - 10.0
		strike73.call(0)
		strike73.call(2)
		await wait(1.6)
		var slow73: bool = v73.bell_answers == 1 and v73.bell_far_rings == 3
		var plain73: bool = main.player.gold == gold73 and main.player.pots == pots73 and main.player.xp == xp73 and main.crown_pips == pips73
		fb_end(was73)
		check("d73_bell_answer", far73 and order73 and wrong73 and silent73 and gap73 and asked73 and rang73 and three73 and notes73 and slow73 and plain73,
			"a far bell, three posts=%s post 2 is lowest=%s wrong order=%s unanswered=%s two right bells=%s the third asks=%s (none before the beat) the far bell swings=%s three notes=%s low, mid, high=%s a slow try=%s nothing given=%s" % [far73, order73, wrong73, silent73, gap73, asked73, rang73, three73, notes73, slow73, plain73])
	if want.call("d75_fold"):
		# a re-read book wears a folded corner on the page where she stopped (its last, the page she shut it on); the first reading and other talks show none; the page is saved (idea 75)
		main.story_step = maxi(main.story_step, 10)
		if main.intro:
			main.start_game(false)
		main.close_story()
		main.in_village = false
		main.in_hill = true
		var bk75: Dictionary = main.castle.books[0]
		var read75: bool = bk75.read
		var other_bk: Dictionary = main.castle.books[1] # one more shelf unread, so this is not the last one (no bookmark scene)
		var other_read: bool = other_bk.read
		other_bk.read = false
		bk75.read = false
		bk75.page = 0
		var stand75: Vector2 = bk75.pos + (Vector2(0, 1.0) if bk75.pos.y < 4 else Vector2(0.0, -0.9))
		reset_to(stand75)
		tap(KEY_E)
		await wait(0.2)
		var pages75: int = main.STORY.BOOKS[0].size()
		var first75: bool = main.story_open and not main.ui.story_fold.visible and main.story.fold_page == 0 and bk75.page == pages75
		for i in 8:
			if main.story_lines.is_empty():
				break
			main.story.next_story()
			main.story.next_story()
		var firstlast75: bool = not main.ui.story_fold.visible
		main.close_story()
		await wait(0.3)
		tap(KEY_E) # again
		await wait(0.2)
		var again75: bool = main.story_open and main.story.fold_page == pages75
		var early75: bool = pages75 < 2 or not main.ui.story_fold.visible # the first page of a longer book: no corner yet
		for i in 8:
			if main.story_lines.is_empty():
				break
			main.story.next_story()
			main.story.next_story()
		var folded75: bool = main.ui.story_fold.visible
		main.close_story()
		await wait(0.3)
		var other75: bool = true
		main.show_story("", ["||하나.", "||둘."])
		other75 = not main.ui.story_fold.visible and main.story.fold_page == 0
		main.close_story()
		main.save_game()
		var d75 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var saved75: bool = typeof(d75) == TYPE_DICTIONARY and d75.get("book_pages", [0])[0] == pages75
		bk75.read = read75
		other_bk.read = other_read
		main.in_hill = false
		check("d75_fold", first75 and firstlast75 and again75 and early75 and folded75 and other75 and saved75,
			"the first reading has no corner and keeps the page=%s still none on its last page=%s a re-read marks page %d=%s the first page of a longer book is clean=%s folded corner on the page=%s another talk has none=%s saved=%s" % [first75, firstlast75, pages75, again75, early75, folded75, other75, saved75])
	if want.call("d79_four_blocks"):
		# a blow turns the nearest of four blocks to the way she faces; all four alike and a flower rises from the gap, one turned away and it sinks; nothing is given (idea 79)
		var was79: Array = fb_start()
		var v79: Object = main.village
		var gold79: int = main.player.gold
		var pots79: int = main.player.pots
		var dirs79 := func() -> Array: return v79.turn_blocks.map(func(b): return b.dir)
		var start79: bool = dirs79.call() == [0, 1, 2, 3] and not v79.turn_up and not v79.turn_flower.visible
		var strike79 := func(i: int, q: int):
			var f: Vector2 = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)][q]
			var nd: Node3D = v79.turn_blocks[i].node
			var at := Vector2(nd.global_position.x, nd.global_position.z) - f * 0.8
			fb_put(Vector2(20.0, 15.0), at - Vector2(v79.VILLAGE_X, 0), f)
			v79.bells_update(main, 1.0)
			main.attack()
		var far79: bool = true
		fb_put(Vector2(20.0, 15.0), Vector2(5.0, 5.0), Vector2(1, 0)) # a swing far from the blocks
		main.attack()
		far79 = dirs79.call() == [0, 1, 2, 3]
		var t0_79: int = v79.turn_hits
		strike79.call(1, 0)
		var one79: bool = dirs79.call() == [0, 0, 2, 3] and v79.turn_hits == t0_79 + 1 # one block for one blow
		strike79.call(1, 0)
		var same79: bool = v79.turn_hits == t0_79 + 1
		strike79.call(2, 0)
		var three79: bool = dirs79.call() == [0, 0, 0, 3] and not v79.turn_up
		strike79.call(3, 0)
		var all79: bool = dirs79.call() == [0, 0, 0, 0] and v79.turn_up
		await wait(1.0)
		var rose79: bool = v79.turn_flower.visible and v79.turn_flower.scale.y > 0.95
		strike79.call(0, 2) # one turned away
		var away79: bool = dirs79.call() == [2, 0, 0, 0] and not v79.turn_up
		await wait(0.6)
		var sank79: bool = not v79.turn_flower.visible
		var plain79: bool = main.player.gold == gold79 and main.player.pots == pots79 and v79.blocked(v79.VILLAGE_X + v79.TURN_AT.x, v79.TURN_AT.y) == false
		for i in 4: # back as built
			v79.turn_blocks[i].dir = [0, 1, 2, 3][i]
			v79.turn_blocks[i].node.rotation.y = -[0, 1, 2, 3][i] * PI / 2.0
		fb_end(was79)
		check("d79_four_blocks", start79 and far79 and one79 and same79 and three79 and all79 and rose79 and away79 and sank79 and plain79,
			"built unlike=%s a far swing turns none=%s one blow one block=%s the same way again is quiet=%s three alike no flower=%s four alike=%s the flower is up=%s one turned away=%s it sinks=%s nothing given, no wall=%s" % [start79, far79, one79, same79, three79, all79, rose79, away79, sank79, plain79])
	if want.call("d81_recap"):
		# after a break of 3 days or more the first journal shows only the last deed finished and the place to go, the next opening shows everything (idea 81)
		var m81: Object = main.menus
		var b81 := [main.marsh.chest_open, main.tokens[1], main.has_tea, main.fly_q, main.mail_q, main.fest_gift, main.fish_kinds.duplicate(), main.grotto_q,
			main.forest.chest_open, main.mill_q, main.cloud_q, main.stairs.door_open, main.tokens[5], main.castle.vault_open, main.ui.quest.text]
		main.marsh.chest_open = false
		main.tokens[1] = false
		main.has_tea = false
		main.fly_q = 0
		main.mail_q = 0
		main.fest_gift = false
		main.fish_kinds = [false, false, false, false, false]
		main.grotto_q = 0
		main.forest.chest_open = false
		main.mill_q = 0
		main.cloud_q = 0
		main.stairs.door_open = false
		main.tokens[5] = false
		main.castle.vault_open = false
		main.ui.quest.text = "시험 길로 가자"
		var none81: bool = m81.last_deed() == "" and plain(m81.recap_lines()[1]).contains("아직 없다")
		main.tokens[1] = true
		var one81: bool = m81.last_deed() == "울림 수정"
		main.has_tea = true
		main.marsh.chest_open = true # an earlier deed done later does not move the mark back
		var far81: bool = m81.last_deed() == "늪의 달꽃"
		var lines81: Array = m81.recap_lines()
		var text81: bool = plain(lines81[1]).contains("늪의 달꽃") and plain(lines81[2]).contains("시험 길로 가자") and lines81.size() <= 5
		var now81: float = Time.get_unix_time_from_system()
		m81.recap_from_save(now81 - 86400.0)
		var short81: bool = not m81.recap_due
		m81.recap_from_save(0.0)
		var nosave81: bool = not m81.recap_due
		m81.recap_from_save(now81 - 4.0 * 86400.0)
		var long81: bool = m81.recap_due
		var r0: int = m81.recaps
		m81.toggle_journal(true)
		var recap81: bool = plain(main.ui.journal_text.text).contains("마지막으로 끝낸 일") and plain(main.ui.journal_text.text).contains("늪의 달꽃") and not plain(main.ui.journal_text.text).contains("곁이야기") and main.ui.journal_text2.text == "" and not m81.recap_due and m81.recaps == r0 + 1
		m81.toggle_journal(false)
		m81.toggle_journal(true)
		var full81: bool = plain(main.ui.journal_text.text).contains("곁이야기") and m81.recaps == r0 + 1
		m81.toggle_journal(false)
		main.marsh.chest_open = b81[0]
		main.tokens[1] = b81[1]
		main.has_tea = b81[2]
		main.fly_q = b81[3]
		main.mail_q = b81[4]
		main.fest_gift = b81[5]
		main.fish_kinds = b81[6]
		main.grotto_q = b81[7]
		main.forest.chest_open = b81[8]
		main.mill_q = b81[9]
		main.cloud_q = b81[10]
		main.stairs.door_open = b81[11]
		main.tokens[5] = b81[12]
		main.castle.vault_open = b81[13]
		main.ui.quest.text = b81[14]
		check("d81_recap", none81 and one81 and far81 and text81 and short81 and nosave81 and long81 and recap81 and full81,
			"no deed yet=%s one deed=%s the furthest deed wins=%s the two lines=%s one day away: none=%s no save time: none=%s four days: recap=%s the first journal is only the recap=%s the second is whole=%s" % [none81, one81, far81, text81, short81, nosave81, long81, recap81, full81])
	if want.call("d83_potion_preview"):
		# the shop shows what one potion would mend at her HP, with the keepsakes and level counted, and the drink mends exactly that; buying nothing consumes nothing (idea 83)
		var p83: Dictionary = main.player
		var b83 := [p83.hp, p83.max_hp, p83.lv, p83.pots, main.has_sprout, main.has_acorn, p83.cds[3]]
		main.close_story()
		p83.max_hp = 100
		p83.lv = 1
		main.has_sprout = false
		main.has_acorn = false
		p83.cds[3] = 0.0
		p83.hp = 70.0
		var cb83: Object = main.combat
		var pots83: int = p83.pots
		var near83: bool = absf(cb83.heal_preview() - 30.0) < 0.01 and p83.pots == pots83 and p83.hp == 70.0
		main.shop.refresh_shop()
		var line83: bool = main.ui.shop_preview.text.contains("+30")
		p83.hp = 20.0
		var base83: bool = absf(cb83.heal_preview() - 45.0) < 0.01
		main.has_acorn = true
		var acorn83: bool = absf(cb83.heal_preview() - 65.0) < 0.01
		main.has_sprout = true
		var sprout83: bool = absf(cb83.heal_preview() - 75.0) < 0.01
		main.has_sprout = false
		main.has_acorn = false
		p83.lv = 25
		var lv83: bool = absf(cb83.heal_preview() - 58.5) < 0.01
		p83.lv = 1
		main.shop.refresh_shop()
		var line2_83: bool = main.ui.shop_preview.text.contains("+45")
		p83.pots = 2
		var said83: float = cb83.heal_preview()
		main.drink_potion()
		var drank83: bool = absf(p83.hp - (20.0 + said83)) < 0.01 and p83.pots == 1
		p83.hp = float(p83.max_hp)
		main.shop.refresh_shop()
		var full83: bool = cb83.heal_preview() == 0.0 and main.ui.shop_preview.text.contains("가득")
		p83.hp = b83[0]
		p83.max_hp = b83[1]
		p83.lv = b83[2]
		p83.pots = b83[3]
		main.has_sprout = b83[4]
		main.has_acorn = b83[5]
		p83.cds[3] = b83[6]
		check("d83_potion_preview", near83 and line83 and base83 and acorn83 and sprout83 and lv83 and line2_83 and drank83 and full83,
			"30 mended from 70 of 100 and nothing used=%s the shop line=%s base 45=%s acorn 65=%s sprout 75=%s Lv25 58.5=%s line follows=%s the drink mends what was said=%s at full strength: none=%s" % [near83, line83, base83, acorn83, sprout83, lv83, line2_83, drank83, full83])
	if want.call("d84_folk_detail"):
		# a villager's name in the journal's list opens her house and when she can be met, a second tap closes it; unmet ones are not listed (idea 84)
		var m84: Object = main.menus
		var met84: Dictionary = main.met.duplicate()
		var fs84: Dictionary = main.folk_state.duplicate()
		var mate84 = main.mate
		main.met = {"doran": true, "kongal": true, "tori": true}
		main.mate = null
		m84.recap_due = false
		m84.journal_folk = ""
		main.folk_state["doran"] = "out"
		m84.toggle_journal(true)
		var t84: String = plain(main.ui.journal_text2.text)
		var list84: bool = t84.contains("마을 사람") and t84.contains("[url=doran]") and t84.contains("[url=tori]") and not t84.contains("[url=yeoul]") and not t84.contains("집:")
		var n0: int = m84.folk_picks
		m84.journal_pick("doran")
		t84 = plain(main.ui.journal_text2.text)
		var open84: bool = m84.folk_picks == n0 + 1 and m84.journal_folk == "doran" and t84.contains("번 집") and t84.contains("낮:") and t84.contains("밤:") and not t84.contains("지금: 집에서")
		main.folk_state["doran"] = "in"
		m84.journal_pick("kongal")
		m84.journal_pick("doran")
		t84 = plain(main.ui.journal_text2.text)
		var asleep84: bool = t84.contains("지금: 집에서 자고 있다") and t84.contains("▸ 도란")
		m84.journal_pick("doran") # a second tap closes it
		t84 = plain(main.ui.journal_text2.text)
		var shut84: bool = m84.journal_folk == "" and not t84.contains("낮:")
		m84.toggle_journal(false)
		var n1: int = m84.folk_picks
		m84.journal_pick("doran") # the journal is shut: nothing happens
		var closed84: bool = m84.folk_picks == n1 and m84.journal_folk == ""
		main.met = met84
		main.folk_state = fs84
		main.mate = mate84
		check("d84_folk_detail", list84 and open84 and asleep84 and shut84 and closed84,
			"met names are links, unmet are not=%s the details show house, day, night=%s a sleeper says so=%s a second tap closes=%s a shut journal ignores=%s" % [list84, open84, asleep84, shut84, closed84])
	if want.call("d85_resume"):
		# a plain talk of three lines or more closed on its last line within 2 s and opened again within 6 s begins at that last line; slower, other, short or follow-up talks start over (idea 85)
		var st85: Object = main.story
		main.close_story()
		main.after_story = Callable()
		var talk85: Array = ["||하나.", "||둘.", "||셋.", "||넷."]
		var read85 := func():
			for i in 12:
				if main.story_lines.is_empty() and main.ui.story_text.visible_characters == -1:
					break
				st85.next_story()
		var r0_85: int = st85.story_resumes
		main.show_story("", talk85)
		read85.call()
		var onlast85: bool = main.story_lines.is_empty() and plain(main.ui.story_text.text) == "넷."
		main.close_story()
		var kept85: bool = st85.cp_key == talk85.hash()
		main.show_story("", talk85)
		var resumed85: bool = main.story_lines.is_empty() and plain(main.ui.story_text.text) == "넷." and st85.story_resumes == r0_85 + 1 and st85.cp_key == 0
		main.close_story()
		main.show_story("", ["||다른.", "||이야기.", "||입니다."]) # another talk starts at its first line
		var other85: bool = main.story_lines.size() == 2 and st85.story_resumes == r0_85 + 1
		main.close_story()
		main.show_story("", talk85) # nothing was kept for it any more
		var fresh85: bool = main.story_lines.size() == 3
		read85.call()
		await wait(2.4) # closed too slowly: not a slip
		main.close_story()
		main.show_story("", talk85)
		var slow85: bool = main.story_lines.size() == 3 and st85.story_resumes == r0_85 + 1
		read85.call()
		main.close_story()
		st85.cp_at -= 10.0 # opened again too late
		main.show_story("", talk85)
		var late85: bool = main.story_lines.size() == 3 and st85.story_resumes == r0_85 + 1
		read85.call()
		main.after_story = func(): pass # a talk with a follow-up waiting is never kept
		main.close_story()
		main.after_story = Callable()
		main.show_story("", talk85)
		var reward85: bool = main.story_lines.size() == 3 and st85.cp_key == 0
		main.close_story()
		var short85: Array = ["||하나.", "||둘."]
		main.show_story("", short85)
		read85.call()
		main.close_story()
		main.show_story("", short85)
		var short_ok85: bool = main.story_lines.size() == 1 and st85.story_resumes == r0_85 + 1
		main.close_story()
		main.after_story = Callable()
		check("d85_resume", onlast85 and kept85 and resumed85 and other85 and fresh85 and slow85 and late85 and reward85 and short_ok85,
			"read to the last line=%s kept=%s opened again: only the last line=%s another talk from its start=%s used once=%s slow close=%s late reopen=%s a follow-up waiting=%s a two-line talk=%s" % [onlast85, kept85, resumed85, other85, fresh85, slow85, late85, reward85, short_ok85])
	if want.call("d87_save_gear"):
		# the gear turns once only after a write that ended without an error and the time is kept for the journal; a failed write shows a plain message and no gear (idea 87)
		var sv87: Object = main.save
		main.close_story()
		var intro87: bool = main.intro
		main.intro = false
		main.down_t = 0.0
		main.player.hp = maxf(main.player.hp, 10.0)
		var gear87: Control = main.ui.save_gear
		var saved_t87: float = main.save_t
		main.save_t = -1000.0 # the 5 s autosave would turn the gear again
		gear87.modulate.a = 0.0
		var n87: int = sv87.save_turns
		var f87: int = sv87.save_fails
		main.save_game()
		var turned87: bool = sv87.save_turns == n87 + 1 and sv87.save_fails == f87 and gear87.modulate.a > 0.5
		var time87: bool = sv87.last_save_text.length() == 5 and sv87.last_save_text[2] == ":"
		await wait(0.4)
		var spins87: bool = gear87.rotation > 0.5
		var d87 = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var stamp87: bool = typeof(d87) == TYPE_DICTIONARY and absf(float(d87.get("saved_at", 0.0)) - Time.get_unix_time_from_system()) < 30.0
		var line87: bool = main.menus.journal_lines().any(func(l): return String(l).contains(sv87.last_save_text) and String(l).contains("마지막 저장"))
		await wait(3.2)
		var faded87: bool = gear87.modulate.a < 0.01
		var t87: String = sv87.last_save_text
		sv87.save_done(false)
		var failed87: bool = sv87.save_fails == f87 + 1 and sv87.save_turns == n87 + 1 and gear87.modulate.a < 0.01 and sv87.last_save_text == t87 and main.ui.toast.text.contains("저장하지 못했다")
		main.intro = true # no save before the game starts, so no gear
		main.save_game()
		var quiet87: bool = sv87.save_turns == n87 + 1
		main.intro = intro87
		main.save_t = saved_t87
		check("d87_save_gear", turned87 and time87 and spins87 and stamp87 and line87 and faded87 and failed87 and quiet87,
			"a good write turns the gear=%s time kept=%s it spins=%s saved_at stamped=%s journal line=%s fades=%s a failed write: message, no gear=%s no save at the title=%s" % [turned87, time87, spins87, stamp87, line87, faded87, failed87, quiet87])
	if want.call("d88_dots"):
		# a ringing crystal shows its rank (1 for the lowest note to 4) as that many dots above it at the same hit, then they go; the puzzle's rules are unchanged (idea 88)
		var cv88: Object = main.cave
		var run88: int = main.crystal_run
		var done88: bool = main.crystal_done
		var told88: bool = main.crystal_told
		main.crystal_told = true
		main.crystal_done = false # an earlier test may have solved them
		var rings: Array = main.crystals.filter(func(c): return not c.has("set"))
		var counts88 := true
		var c0: int = cv88.dot_cues.size()
		var order88 := []
		for e in rings:
			e.hurt = 0.0
			main.crystal_run = 0
			cv88.crystal_hit(e)
			var rank: int = main.CRYSTAL_NOTE[int(e.crystal)]
			order88.append(rank)
			var row = e.get("dots")
			counts88 = counts88 and is_instance_valid(row) and row.get_child_count() == rank + 1 and absf(row.position.y - 2.15) < 0.01 and absf(row.position.x - e.x) < 0.01
		var seen88: bool = rings.size() == 4 and cv88.dot_cues.size() == c0 + 4 and cv88.dot_cues.slice(c0) == order88
		var twice88: bool = true
		var e0: Dictionary = rings[0]
		e0.hurt = 0.0
		cv88.crystal_hit(e0)
		var n_a: int = cv88.dot_cues.size()
		cv88.crystal_hit(e0) # one swing rings it once
		twice88 = cv88.dot_cues.size() == n_a
		var low88: Dictionary = rings.filter(func(c): return main.CRYSTAL_NOTE[int(c.crystal)] == 0)[0]
		low88.hurt = 0.0
		main.crystal_run = 0
		var done0: bool = main.crystal_done
		cv88.crystal_hit(low88)
		var rules88: bool = main.crystal_run == 1 and main.crystal_done == done0
		await wait(cv88.DOT_STAY + 0.3)
		var gone88: bool = rings.all(func(c): return not is_instance_valid(c.get("dots")) or not c.get("dots").is_inside_tree())
		main.crystal_run = run88
		main.crystal_done = done88
		main.crystal_told = told88
		check("d88_dots", counts88 and seen88 and twice88 and rules88 and gone88,
			"dots = rank + 1 above each crystal=%s cues in ring order=%s one swing once=%s the order rule still counts=%s dots go=%s" % [counts88, seen88, twice88, rules88, gone88])

	if want.call("d89_read_pace"):
		# a slower reading pace keeps a long balloon up longer (and the next talk line / chat waits for it); the default changes nothing (idea 89)
		if main.intro:
			main.start_game(false)
		main.close_story()
		var ch89: Object = main.chatter
		var read89: int = main.cfg.read
		var kept89 := settings_keep()
		var long89 := "이 길은 달빛이 닿는 곳까지 이어진다고 들었어. 끝까지 가 보자."
		var need89: float = 0.9 + 0.1 * long89.length()
		main.cfg.read = 0
		var life0: float = ch89.bubble_life(long89, 3.0)
		var gap0: float = ch89.line_gap(long89, 2.2)
		main.cfg.read = 1
		var life1: float = ch89.bubble_life(long89, 3.0)
		var short1: float = ch89.bubble_life("응", 3.0)
		var gap1: float = ch89.line_gap(long89, 2.2)
		main.cfg.read = 2
		var life2: float = ch89.bubble_life(long89, 3.0)
		var nums89: bool = is_equal_approx(life0, 3.0) and is_equal_approx(gap0, 2.4) and is_equal_approx(life1, maxf(3.0, need89) * 1.5) \
			and is_equal_approx(short1, 4.5) and is_equal_approx(gap1, maxf(2.4, life1 + 0.5)) and is_equal_approx(life2, maxf(3.0, need89) * 2.0) and life2 > life1 and life1 > life0
		var anchor89 := Node3D.new()
		main.add_child(anchor89)
		anchor89.position = Vector3(main.player.x, main.ground_y, main.player.z)
		main.cfg.read = 0
		var until0: float = ch89.bubble_until
		ch89.say_bubble(anchor89, long89, 3.0)
		var plain89: bool = ch89.bubble_until == until0 # the default pace keeps no waiting time
		main.cfg.read = 2
		ch89.say_bubble(anchor89, long89, 3.0)
		var keeps89: bool = ch89.bubble_until - main.t >= life2
		# the next chat waits for the balloon; once it is gone the chat may start
		if main.mate == null:
			main.join_mate()
		calm_enemies(true)
		main.snap_mates()
		var risers89: Array = main.enemies.filter(func(e): return e.dead and not e.get("cave", false) and not e.get("boss", false))
		for e in risers89:
			e.respawn = 9999.0
		main.player.vx = 0.0
		main.player.vz = 0.0
		main.chat_t = 20.0
		main.chat_cd = 0.0
		ch89.bubble_until = main.t + 100.0
		ch89.update_chat(0.0)
		var waits89: bool = main.chat_cd == 0.0
		ch89.bubble_until = main.t - 1.0
		main.chat_t = 20.0
		ch89.update_chat(0.0)
		var goes89: bool = main.chat_cd > 0.0
		# the settings row cycles normal → slow → very slow → normal and saves
		main.cfg.read = 0
		var row89: Button = main.ui.set_rows.read
		row89.emit_signal("pressed")
		var one89: bool = main.cfg.read == 1
		row89.emit_signal("pressed")
		row89.emit_signal("pressed")
		var cycle89: bool = one89 and main.cfg.read == 0
		main.cfg.read = read89
		settings_back(kept89)
		anchor89.queue_free()
		main.chat_cd = 30.0
		check("d89_read_pace", nums89 and plain89 and keeps89 and waits89 and goes89 and cycle89,
			"life normal/slow/very slow %.2f/%.2f/%.2f (long line %d chars), short slow %.2f, line gap %.2f/%.2f, numbers=%s default keeps no wait=%s slow balloon waits %.1f s=%s chat held back while a balloon is up=%s starts after=%s row cycles=%s" % [life0, life1, life2, long89.length(), short1, gap0, gap1, nums89, plain89, ch89.bubble_until - main.t, keeps89, waits89, goes89, cycle89])
	if want.call("d90_one_hand"):
		# with the one-hand setting a tap on the shield key and on the run key hold them until the next tap; the words stay on the screen;
		# a sheet, the loss of focus or a fall lets them go; without the setting the shield is held only while the finger is down (idea 90)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		var hold90: bool = main.cfg.hold
		main.cfg.hold = true
		await main.enable_touch()
		await wait(0.2)
		var tl90: Control = main.touch_layer
		var tap90 := func(n: String):
			var d := InputEventScreenTouch.new()
			d.index = 4
			d.pressed = true
			d.position = tl90.keys()[n][0]
			Input.parse_input_event(d)
			await wait(0.1)
			var u := d.duplicate()
			u.pressed = false
			Input.parse_input_event(u)
			await wait(0.1)
		var has_run90: bool = tl90.keys().has("run")
		await tap90.call("run")
		var run_on90: bool = tl90.run_latch and main.key_down(KEY_SHIFT) and tl90.latch_text().contains(tr("달리기 켜짐"))
		await wait(0.2)
		var run_kept90: bool = main.key_down(KEY_SHIFT)
		await tap90.call("guard")
		var both90: bool = tl90.guard_latch and main.key_down(KEY_L) and tl90.held.is_empty() and tl90.latch_text().contains(tr("막기 켜짐"))
		await tap90.call("run")
		var run_off90: bool = not tl90.run_latch and not main.key_down(KEY_SHIFT) and tl90.guard_latch and main.key_down(KEY_L)
		await tap90.call("guard")
		var guard_off90: bool = not tl90.guard_latch and not main.key_down(KEY_L) and tl90.latch_text() == ""
		# let go on a sheet, on lost focus, on a fall
		await tap90.call("run")
		await tap90.call("guard")
		main.story_open = true
		await wait(0.15)
		var sheet90: bool = not tl90.run_latch and not tl90.guard_latch and not main.key_down(KEY_SHIFT) and not main.key_down(KEY_L)
		main.story_open = false
		await wait(0.1)
		await tap90.call("run")
		tl90._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		var focus90: bool = not tl90.run_latch and not main.key_down(KEY_SHIFT)
		await tap90.call("guard")
		main.down_t = 1.0
		await wait(0.15)
		var fall90: bool = not tl90.guard_latch and not main.key_down(KEY_L)
		main.down_t = 0.0
		# the setting off: no run key, the shield is held only while the finger is down
		main.cfg.hold = false
		await wait(0.1)
		var no_run90: bool = not tl90.keys().has("run")
		var d90 := InputEventScreenTouch.new()
		d90.index = 4
		d90.pressed = true
		d90.position = tl90.keys()["guard"][0]
		Input.parse_input_event(d90)
		await wait(0.1)
		var down90: bool = main.key_down(KEY_L) and not tl90.guard_latch
		var u90 := d90.duplicate()
		u90.pressed = false
		Input.parse_input_event(u90)
		await wait(0.1)
		var up90: bool = not main.key_down(KEY_L)
		main.cfg.hold = hold90
		main.disable_touch()
		calm_enemies(false)
		check("d90_one_hand", has_run90 and run_on90 and run_kept90 and both90 and run_off90 and guard_off90 and sheet90 and focus90 and fall90 and no_run90 and down90 and up90,
			"run key there=%s run on+word=%s kept=%s shield on beside it=%s run off=%s shield off, words gone=%s sheet lets go=%s focus lost=%s fall=%s setting off: no run key=%s held while down=%s let go after=%s" % [has_run90, run_on90, run_kept90, both90, run_off90, guard_off90, sheet90, focus90, fall90, no_run90, down90, up90])
	if want.call("d91_lefty"):
		# the mirrored layout: the stick, the play keys and the skill coins swap sides; the menu keys, zoom coins stay (idea 91)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		var root91 := get_tree().root # a phone's canvas, 960 x 540, as the layout tests
		var scale91 := [root91.content_scale_mode, root91.content_scale_aspect, root91.content_scale_size]
		root91.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root91.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root91.content_scale_size = Vector2i(960, 540)
		var lefty91: bool = main.cfg.lefty
		main.cfg.lefty = false
		await main.enable_touch()
		await wait(0.2)
		var tl91: Control = main.touch_layer
		var vs91: Vector2 = main.get_viewport().get_visible_rect().size
		var right91: Dictionary = tl91.keys().duplicate(true)
		var skill_r91: Vector2 = main.ui.hud.skill_spot(0)
		var menu91: Array = [main.ui.journal_btn.position, main.ui.hint.position, main.ui.settings_btn.position, main.ui.sound_btn.position]
		var rt91: Array = main.hud_build.touch_rects() # the first one is the bracelet or the attack key's box on the right
		main.cfg.lefty = true
		await wait(0.1)
		var left91: Dictionary = tl91.keys()
		var mirrored91 := true
		for n in ["attack", "dodge", "guard", "crown"]:
			mirrored91 = mirrored91 and is_equal_approx(left91[n][0].x, vs91.x - right91[n][0].x) and is_equal_approx(left91[n][0].y, right91[n][0].y) and left91[n][1] == right91[n][1]
		var stayed91: bool = left91.zoom_in[0] == right91.zoom_in[0] and left91.zoom_out[0] == right91.zoom_out[0]
		var skills91: bool = is_equal_approx(main.ui.hud.skill_spot(0).x, vs91.x - skill_r91.x) and main.ui.hud.skill_spot(0).y == skill_r91.y
		var menu_same91: bool = menu91 == [main.ui.journal_btn.position, main.ui.hint.position, main.ui.settings_btn.position, main.ui.sound_btn.position]
		var rects91: bool = main.hud_build.touch_rects().has(Rect2(left91.attack[0] - Vector2.ONE * left91.attack[1], Vector2.ONE * left91.attack[1] * 2.0)) and not main.hud_build.touch_rects().has(rt91[0])
		# the stick: a finger on the right side grabs it now, one on the left side does not; the keys answer where they are drawn now
		var f91 := InputEventScreenTouch.new()
		f91.index = 2
		f91.pressed = true
		f91.position = Vector2(vs91.x * 0.1, vs91.y * 0.8)
		tl91._input(f91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		var left_no91: bool = tl91.pad_idx < 0
		var g91 := f91.duplicate()
		g91.pressed = false
		tl91._input(g91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		var h91 := f91.duplicate()
		h91.position = Vector2(vs91.x * 0.9, vs91.y * 0.8)
		tl91._input(h91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		var right_yes91: bool = tl91.pad_idx == 2
		var drag91 := InputEventScreenDrag.new()
		drag91.index = 2
		drag91.position = h91.position - Vector2(0, 60)
		tl91._input(drag91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		var walks91: bool = main.touch_move.y < -0.5
		var l91 := h91.duplicate()
		l91.pressed = false
		tl91._input(l91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		var sw91 := InputEventScreenTouch.new()
		sw91.index = 3
		sw91.pressed = true
		sw91.position = left91.attack[0]
		main.player.atk_cd = 0.0
		var combo91: int = main.player.combo
		tl91._input(sw91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		var swing91: bool = main.player.combo != combo91 or main.player.atk_cd > 0.0
		var su91 := sw91.duplicate()
		su91.pressed = false
		tl91._input(su91) # straight to the layer: the window is smaller than the canvas, so a parsed event would be scaled
		await wait(0.1)
		main.cfg.lefty = lefty91
		main.disable_touch()
		root91.content_scale_mode = scale91[0]
		root91.content_scale_aspect = scale91[1]
		root91.content_scale_size = scale91[2]
		calm_enemies(false)
		check("d91_lefty", mirrored91 and stayed91 and skills91 and menu_same91 and rects91 and left_no91 and right_yes91 and walks91 and swing91,
			"play keys mirrored=%s zoom coins stay=%s skills mirrored=%s menu keys stay=%s avoid list follows=%s left finger no stick=%s right finger grabs it=%s walks=%s sword key where drawn=%s" % [mirrored91, stayed91, skills91, menu_same91, rects91, left_no91, right_yes91, walks91, swing91])
	if want.call("d92_crown_word"):
		# a press on the bracelet key shows what it is about to do over the key; the question changes nothing and the key acts once (idea 92)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		await main.enable_touch()
		await wait(0.2)
		var tl92: Control = main.touch_layer
		var lamp92: OmniLight3D = main.dark_lamp # the opening beat takes the key before a chest does
		main.dark_lamp = null
		var chest92: Dictionary = {}
		for c in main.chests:
			if not c.open:
				chest92 = c
				break
		var got92 := not chest92.is_empty()
		var label92 := ""
		var gold92: int = main.player.gold
		var pots92: int = main.player.pots
		var quiet92 := false
		var acted92 := false
		var once92 := false
		var shown92 := false
		var gone92 := false
		var blank92 := false
		if got92:
			reset_to(Vector2(chest92.x, chest92.z))
			label92 = main.crown_label()
			main.crown_label()
			main.crown_label()
			quiet92 = not chest92.open and main.player.gold == gold92 and main.player.pots == pots92 # asking does nothing
			var cd92 := InputEventScreenTouch.new()
			cd92.index = 5
			cd92.pressed = true
			cd92.position = tl92.keys().crown[0]
			Input.parse_input_event(cd92)
			await wait(0.1)
			var cu92 := cd92.duplicate()
			cu92.pressed = false
			Input.parse_input_event(cu92)
			shown92 = tl92.crown_say == label92 and tl92.crown_say_t > 0.5 and label92 == tr("상자 열기")
			acted92 = chest92.open
			once92 = main.player.gold > gold92 and main.player.gold <= gold92 + 29 and main.player.pots == pots92 + 1
			await wait(1.5)
			gone92 = tl92.crown_say_t == 0.0
			for gx in range(5, 45, 5):
				for gz in range(5, 45, 5):
					if not blank92:
						reset_to(Vector2(gx, gz))
						blank92 = main.crown_label() == ""
			if blank92:
				tl92.crown_say = "x"
				cd92.pressed = true
				cd92.position = tl92.keys().crown[0]
				Input.parse_input_event(cd92)
				await wait(0.1)
				cu92.position = cd92.position
				Input.parse_input_event(cu92)
				blank92 = tl92.crown_say == "" and tl92.crown_say_t == 0.0
		main.dark_lamp = lamp92
		main.disable_touch()
		calm_enemies(false)
		check("d92_crown_word", got92 and label92 == tr("상자 열기") and quiet92 and shown92 and acted92 and once92 and gone92 and blank92,
			"a closed chest found=%s the word '%s' asking changes nothing=%s shown over the key=%s the chest opened=%s once (gold +%d, pots +%d)=%s word fades=%s no word where it does nothing=%s" % [got92, label92, quiet92, shown92, acted92, main.player.gold - gold92, main.player.pots - pots92, once92, gone92, blank92])
	if want.call("d94_guard_slip"):
		# a thumb that drifts off the shield key keeps it inside the rim plus 36 px and has let go past that; held and latched look different (idea 94)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		main.cfg.hold = false
		await main.enable_touch()
		await wait(0.2)
		var tl94: Control = main.touch_layer
		var c94: Vector2 = tl94.keys().guard[0]
		var r94: float = tl94.keys().guard[1]
		var d94 := InputEventScreenTouch.new()
		d94.index = 6
		d94.pressed = true
		d94.position = c94
		Input.parse_input_event(d94)
		await wait(0.1)
		var held94: bool = main.key_down(KEY_L) and tl94.held.values().has("guard")
		var s94 := InputEventScreenDrag.new()
		s94.index = 6
		s94.position = c94 + Vector2(r94 + 20.0, 0.0) # past the rim, inside the slack
		Input.parse_input_event(s94)
		await wait(0.1)
		var kept94: bool = main.key_down(KEY_L) and tl94.held.values().has("guard")
		s94.position = c94 + Vector2(r94 + 20.0 + 30.0, 0.0) # 50 px past: let go
		Input.parse_input_event(s94)
		await wait(0.1)
		var let94: bool = not main.key_down(KEY_L) and tl94.held.is_empty()
		var u94 := d94.duplicate()
		u94.pressed = false
		Input.parse_input_event(u94)
		await wait(0.1)
		var after94: bool = not main.key_down(KEY_L)
		# held (a finger on it) is not latched (one-hand): different state, so they are drawn differently
		d94.position = c94
		Input.parse_input_event(d94)
		await wait(0.1)
		var held_look94: bool = tl94.held.values().has("guard") and not tl94.guard_latch and tl94.latch_text() == ""
		Input.parse_input_event(u94)
		await wait(0.1)
		main.cfg.hold = true
		await wait(0.1)
		Input.parse_input_event(d94)
		await wait(0.1)
		Input.parse_input_event(u94)
		await wait(0.1)
		var latch_look94: bool = tl94.guard_latch and tl94.held.is_empty() and tl94.latch_text() != ""
		main.cfg.hold = false
		await wait(0.1)
		main.disable_touch()
		calm_enemies(false)
		check("d94_guard_slip", held94 and kept94 and let94 and after94 and held_look94 and latch_look94,
			"held on touch=%s 20 px past the rim still held=%s 50 px past let go=%s lift after=%s held look (finger, no word)=%s latched look (word, no finger)=%s" % [held94, kept94, let94, after94, held_look94, latch_look94])
	if want.call("d97_key_size"):
		# three sizes of the play keys from one table: the radii grow by 10% and 24%, the gaps stay at 10 px or more, nothing meets a skill coin
		# or the minimap; the hit radius and the avoid list follow (idea 97)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		var root97 := get_tree().root # a phone's canvas, 960 x 540, as the layout tests
		var scale97 := [root97.content_scale_mode, root97.content_scale_aspect, root97.content_scale_size]
		root97.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root97.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root97.content_scale_size = Vector2i(960, 540)
		var size97: int = main.cfg.keysize
		var text97: int = main.cfg.text # a phone layout raises it a size; the settings file must not keep that
		var kept97 := settings_keep()
		var hold97: bool = main.cfg.hold
		var lefty97: bool = main.cfg.lefty
		main.cfg.hold = true
		main.cfg.lefty = false
		await main.enable_touch()
		await wait(0.2)
		var tl97: Control = main.touch_layer
		var vs97: Vector2 = main.get_viewport().get_visible_rect().size
		var radii97: Array = []
		var gaps97: Array = []
		var fits97 := true
		var hits97 := true
		var rects97 := true
		var old97 := true
		for lv in 3:
			for lf in [false, true]:
				main.cfg.keysize = lv
				main.cfg.lefty = lf
				await wait(0.05)
				var k: Dictionary = tl97.keys()
				var names: Array = ["attack", "dodge", "guard", "crown", "run", "skill0", "skill1", "skill2", "skill3"]
				var gap_min := 1000.0
				for i in 5: # the play keys against each other and against the skill coins (the coins' own 4 px gap is the HUD's)
					for j in range(i + 1, names.size()):
						gap_min = minf(gap_min, (k[names[i]][0] as Vector2).distance_to(k[names[j]][0]) - float(k[names[i]][1]) - float(k[names[j]][1]))
				for n in ["attack", "dodge", "guard", "crown", "run"]:
					var c: Vector2 = k[n][0]
					var r: float = k[n][1]
					fits97 = fits97 and c.x - r >= 0.0 and c.x + r <= vs97.x and c.y - r >= vs97.y - 346.0 and c.y + r <= vs97.y
					hits97 = hits97 and tl97.key_at(c) == n and tl97.key_at(c + Vector2(r - 1.0, 0.0)) == n
					rects97 = rects97 and main.hud_build.touch_rects().has(Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0))
				if not lf:
					radii97.append(k.attack[1])
					gaps97.append(gap_min)
					if lv == 0: # the first size is the old layout, number for number
						old97 = old97 and k.attack[0] == Vector2(vs97.x - 80.0, vs97.y - 196.0) and k.dodge[0] == Vector2(vs97.x - 196.0, vs97.y - 158.0) \
							and k.guard[0] == Vector2(vs97.x - 176.0, vs97.y - 270.0) and k.crown[0] == Vector2(vs97.x - 64.0, vs97.y - 300.0) and k.crown[1] == 42.0 and k.attack[1] == 58.0
				else:
					gaps97.append(gap_min)
		var bigger97: bool = radii97[1] >= radii97[0] * 1.09 and radii97[2] >= radii97[0] * 1.23
		var gap_ok97: bool = gaps97[2] >= 10.0 and gaps97[4] >= 10.0 and gaps97[3] >= 10.0 and gaps97[5] >= 10.0 and gaps97[2] > gaps97[0] and gaps97[4] > gaps97[0] # [lv0, lv0 left, lv1, lv1 left, lv2, lv2 left]
		# the settings row cycles
		main.cfg.keysize = 0
		var row97: Button = main.ui.set_rows.keysize
		row97.emit_signal("pressed")
		var cyc97: bool = main.cfg.keysize == 1
		main.cfg.keysize = size97
		main.cfg.text = text97
		main.cfg.hold = hold97
		root97.content_scale_mode = scale97[0]
		root97.content_scale_aspect = scale97[1]
		root97.content_scale_size = scale97[2]
		main.cfg.lefty = lefty97
		settings_back(kept97)
		main.disable_touch()
		calm_enemies(false)
		check("d97_key_size", bigger97 and gap_ok97 and fits97 and hits97 and rects97 and old97 and cyc97,
			"attack radius %s bigger by 10/24%%=%s smallest gaps %s (10 px at the two bigger sizes, 12 px off the skill coins)=%s all inside the screen and under the minimap=%s hit radius=%s avoid list=%s first size is the old layout=%s row cycles=%s" % [radii97, bigger97, gaps97, gap_ok97, fits97, hits97, rects97, old97, cyc97])
	if want.call("d98_edge_bubble"):
		# a balloon at the screen's side slides in and its tail still points at the speaker; one in the middle is as before (idea 98)
		if main.intro:
			main.start_game(false)
		main.close_story()
		var root98 := get_tree().root # a phone's canvas, 960 x 540, as the layout tests
		var scale98 := [root98.content_scale_mode, root98.content_scale_aspect, root98.content_scale_size]
		root98.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root98.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root98.content_scale_size = Vector2i(960, 540)
		await wait(0.1)
		var ch98: Object = main.chatter
		var vs98: Vector2 = main.get_viewport().get_visible_rect().size
		var cam98: Camera3D = main.camera
		var out98 := {}
		for side in ["left", "mid", "right"]:
			var sx: float = 100.0 if side == "left" else (vs98.x * 0.5 if side == "mid" else vs98.x - 100.0) # the balloon sits above the speaker, nearer the camera, so its x lands a little further out
			var anchor := Node3D.new()
			main.add_child(anchor)
			anchor.global_position = cam98.project_position(Vector2(sx, vs98.y * 0.55), 14.0)
			ch98.say_bubble(anchor, "달빛이 닿는 데까지 가 보자!", 3.0)
			var e: Dictionary = ch98.edge_bubbles.back()
			var b: Node3D = e.b
			b.scale = Vector3.ONE # full size at once, and fitted in this very frame while the camera stands where the speaker was placed
			ch98.edge_fit(e, vs98)
			var p0 := cam98.unproject_position(b.global_position)
			var spw: float = cam98.unproject_position(b.global_position + cam98.global_transform.basis.x).x - p0.x
			var tex_px: float = ch98.PIXEL * b.scale.x * spw
			var cx: float = cam98.unproject_position((e.card as Sprite3D).global_position).x
			var half: float = float(e.w) * 0.5 * tex_px
			var tail_x: float = cx + float(e.tx) * tex_px
			out98[side] = {"left": cx - half, "right": cx + half, "tx": int(e.tx), "tail": tail_x, "anchor": p0.x, "pos": (e.card as Sprite3D).position, "plain": (e.card as Sprite3D).texture == ch98.balloon_tex(int(e.w))}
			anchor.queue_free()
		root98.content_scale_mode = scale98[0]
		root98.content_scale_aspect = scale98[1]
		root98.content_scale_size = scale98[2]
		var l98: Dictionary = out98.left
		var m98: Dictionary = out98.mid
		var r98: Dictionary = out98.right
		var inside98: bool = l98.left >= 7.0 and r98.right <= vs98.x - 7.0 and m98.left >= 0.0 and m98.right <= vs98.x
		var tails98: bool = l98.tx < 0 and r98.tx > 0 and absf(l98.tail - l98.anchor) <= 10.0 and absf(r98.tail - r98.anchor) <= 10.0 and not l98.plain and not r98.plain
		var mid98: bool = m98.tx == 0 and m98.plain and (m98.pos as Vector3).length() < 0.001
		check("d98_edge_bubble", inside98 and tails98 and mid98,
			"left balloon spans %.0f to %.0f, right %.0f to %.0f of %.0f px=%s tail shifts %d/%d px, tail ends %.0f vs speaker %.0f, %.0f vs %.0f=%s middle one untouched=%s" % [l98.left, l98.right, r98.left, r98.right, vs98.x, inside98, l98.tx, r98.tx, l98.tail, l98.anchor, r98.tail, r98.anchor, tails98, mid98])
	if want.call("d100_fade_keys"):
		# after 8 s with no finger down and no foe within 10 tiles the combat keys fade to 30%; the hit areas stay, the first touch acts at once and
		# brings them back; the bracelet key and the zoom coins keep their look (idea 100)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		await main.enable_touch()
		await wait(0.2)
		var tl100: Control = main.touch_layer
		reset_to(main.START)
		tl100.idle_t = 0.0
		tl100.dim = 0.0
		tl100._process(tl100.FADE_AFTER - 1.0)
		var early100: bool = tl100.dim == 0.0
		tl100._process(1.2)
		tl100._process(1.3)
		var faint100: bool = tl100.dim == 1.0 and is_equal_approx(1.0 - tl100.dim * (1.0 - tl100.FADE_TO), 0.3)
		var hit100: bool = tl100.key_at(tl100.keys().attack[0]) == "attack" and tl100.key_at(tl100.keys().guard[0]) == "guard"
		# a finger down, a sheet or a foe near keeps them full
		tl100.idle_t = 0.0
		tl100.dim = 0.0
		tl100.pad_idx = 7
		tl100._process(10.0)
		var finger100: bool = tl100.idle_t == 0.0 and tl100.dim == 0.0
		tl100.pad_idx = -1
		main.story_open = true
		tl100._process(10.0)
		var sheet100: bool = tl100.idle_t == 0.0 and tl100.dim == 0.0
		main.story_open = false
		var foe100: Dictionary = {}
		for e in main.enemies:
			if not e.get("boss", false) and not e.get("mole", false) and not e.get("prop", false) and is_instance_valid(e.node):
				foe100 = e
				break
		var foe_ok100 := true
		if not foe100.is_empty():
			var was100 := [foe100.x, foe100.z, foe100.dead]
			foe100.dead = false
			foe100.x = main.player.x + 4.0
			foe100.z = main.player.z
			tl100._process(10.0)
			foe_ok100 = tl100.idle_t == 0.0 and tl100.dim == 0.0
			foe100.x = was100[0]
			foe100.z = was100[1]
			foe100.dead = was100[2]
		# faint again, then a first touch on the sword key swings at once and the keys are back
		tl100.idle_t = 20.0
		tl100.dim = 1.0
		var sw100 := InputEventScreenTouch.new()
		sw100.index = 8
		sw100.pressed = true
		sw100.position = tl100.keys().attack[0]
		main.player.atk_cd = 0.0
		var combo100: int = main.player.combo
		Input.parse_input_event(sw100)
		await wait(0.05)
		var swung100: bool = main.player.combo != combo100 or main.player.atk_cd > 0.0
		var back100: bool = tl100.dim == 0.0 and tl100.idle_t < 0.5
		var su100 := sw100.duplicate()
		su100.pressed = false
		Input.parse_input_event(su100)
		await wait(0.1)
		main.disable_touch()
		calm_enemies(false)
		check("d100_fade_keys", early100 and faint100 and hit100 and finger100 and sheet100 and foe_ok100 and swung100 and back100,
			"not faint after 7 s=%s faint after 8 s (30%%)=%s hit areas stay=%s a finger down keeps them=%s a sheet=%s a foe near=%s first touch swings=%s keys back at once=%s" % [early100, faint100, hit100, finger100, sheet100, foe_ok100, swung100, back100])

	if want.call("d95_safe_area"):
		# the phone's home bar and camera hole: the safe area in canvas px keeps the touch keys, the skills, the minimap, the menu keys, the
		# status block and the quest line inside it; with no unsafe edge (a desktop window, a whole-screen safe area) not one number moves (idea 95)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		var root95 := get_tree().root # a phone's canvas, 960 x 540 (the headless window is 64 px)
		var scale95 := [root95.content_scale_mode, root95.content_scale_aspect, root95.content_scale_size]
		root95.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root95.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root95.content_scale_size = Vector2i(960, 540)
		var SA95 = load("res://sys/safe_area.gd")
		var conv95: Vector4 = SA95.canvas_insets(Vector2i(2400, 1080), Rect2i(100, 0, 2200, 1050), Vector2i(2400, 1080), Vector2(960, 540))
		var conv_ok95: bool = conv95 == Vector4(40, 0, 40, 12)
		var whole95: bool = SA95.canvas_insets(Vector2i(2400, 1080), Rect2i(0, 0, 2400, 1080), Vector2i(2400, 1080), Vector2(960, 540)) == Vector4.ZERO
		var window95: bool = SA95.canvas_insets(Vector2i(2400, 1080), Rect2i(100, 0, 2200, 1050), Vector2i(1280, 720), Vector2(960, 540)) == Vector4.ZERO
		var big95: Vector4 = SA95.canvas_insets(Vector2i(2400, 1080), Rect2i(1200, 0, 1200, 1080), Vector2i(2400, 1080), Vector2(960, 540))
		var clamp95: bool = big95.x == SA95.MAX_INSET
		# the desktop: no touch keys, the real display read leaves the margins at zero
		main.safe_area.held = false
		main.safe_area.refresh()
		var desk95: bool = main.safe == Vector4.ZERO
		var spot_d95: Vector2 = main.ui.hud.skill_spot(0)
		var status_d95: Rect2 = main.hud_build.status_rect()
		await main.enable_touch()
		await wait(0.2)
		var tl95: Control = main.touch_layer
		var vs95: Vector2 = get_viewport().get_visible_rect().size
		var base95: Dictionary = tl95.keys().duplicate(true)
		var skill_b95: Vector2 = main.ui.hud.skill_spot(3)
		var mini_b95: Rect2 = main.ui.mini.get_parent().get_global_rect()
		var menu_b95: Rect2 = main.ui.journal_btn.get_global_rect()
		var status_b95: Rect2 = main.hud_build.status_rect()
		var zero95: bool = main.safe == Vector4.ZERO
		main.safe_area.held = true
		main.safe_area.apply(Vector4(40, 10, 40, 12))
		main.quest_raw = "달빛이 닿는 데까지 가 보자"
		main.ui.quest.text = main.quest_shown(main.quest_raw)
		main.ui.quest.visible = true
		main.hud_build.layout_top()
		await wait(0.2)
		var safe95 := Rect2(40, 10, vs95.x - 80.0, vs95.y - 22.0)
		var keys95: Dictionary = tl95.keys()
		var moved95: bool = is_equal_approx(keys95.attack[0].x, base95.attack[0].x - 40.0) and is_equal_approx(keys95.attack[0].y, base95.attack[0].y - 12.0) \
			and is_equal_approx(keys95.zoom_in[0].y, base95.zoom_in[0].y + 10.0) and is_equal_approx(keys95.zoom_in[0].x, base95.zoom_in[0].x - 40.0) \
			and is_equal_approx(keys95.skill3[0].x, base95.skill3[0].x - 40.0) and is_equal_approx(keys95.skill3[0].y, base95.skill3[0].y - 12.0) \
			and is_equal_approx(main.ui.hud.skill_spot(3).x, skill_b95.x - 40.0) and is_equal_approx(main.ui.hud.skill_spot(3).y, skill_b95.y - 12.0)
		var inside95 := true
		for n in keys95:
			var rc95 := Rect2(keys95[n][0] - Vector2.ONE * keys95[n][1], Vector2.ONE * keys95[n][1] * 2.0)
			if not safe95.encloses(rc95):
				inside95 = false
		var corner95: bool = safe95.encloses(main.ui.mini.get_parent().get_global_rect()) and safe95.encloses(main.ui.journal_btn.get_global_rect()) \
			and safe95.encloses(main.ui.bag_btn.get_global_rect()) and is_equal_approx(main.ui.mini.get_parent().get_global_rect().end.x, mini_b95.end.x - 40.0) \
			and is_equal_approx(main.ui.journal_btn.get_global_rect().position.y, menu_b95.position.y + 10.0)
		var status95: Rect2 = main.hud_build.status_rect()
		var block95: bool = status95.position == Vector2(40, 10) and status95.size == status_b95.size
		var quest95: Rect2 = main.hud_build.quest_deco
		var line95: bool = quest95.size != Vector2.ZERO and quest95.position.x >= 40.0 and quest95.end.x <= vs95.x - 40.0
		# a finger on a key at its new place hits it
		var hit95: bool = tl95.key_at(keys95.attack[0]) == "attack" and tl95.key_at(keys95.attack[0] + Vector2(0, 150)) != "attack"
		# the mirrored layout reads the left margin
		main.cfg.lefty = true
		var left95: Dictionary = tl95.keys()
		main.cfg.lefty = false
		var mirror95: bool = left95.attack[0].x >= 40.0 + left95.attack[1] and is_equal_approx(left95.attack[0].x, tl95.GEOM[tl95.size_level()].attack[0] + 40.0)
		# the margins go: every number is back where it was
		main.safe_area.apply(Vector4.ZERO)
		main.hud_build.layout_top()
		await wait(0.1)
		var back_keys95: Dictionary = tl95.keys()
		var back95: bool = true
		for n in base95:
			if back_keys95[n][0] != base95[n][0] or back_keys95[n][1] != base95[n][1]:
				back95 = false
		back95 = back95 and main.ui.hud.skill_spot(3) == skill_b95 and main.ui.mini.get_parent().get_global_rect() == mini_b95 \
			and main.ui.journal_btn.get_global_rect() == menu_b95 and main.hud_build.status_rect() == status_b95
		main.safe_area.held = false
		main.disable_touch()
		calm_enemies(false)
		var desk_back95: bool = main.safe == Vector4.ZERO and main.ui.hud.skill_spot(0) == spot_d95 and main.hud_build.status_rect() == status_d95
		root95.content_scale_mode = scale95[0]
		root95.content_scale_aspect = scale95[1]
		root95.content_scale_size = scale95[2]
		check("d95_safe_area", conv_ok95 and whole95 and window95 and clamp95 and desk95 and zero95 and moved95 and inside95 and corner95 and block95 and line95 and hit95 and mirror95 and back95 and desk_back95,
			"converts %s (40 0 40 12)=%s whole-screen safe area gives zero=%s a smaller window gives zero=%s clamp %d=%s desktop zero=%s phone zero first=%s keys, skills and zoom move in=%s all inside the safe box=%s minimap and menu keys=%s status block=%s quest line %s=%s key hit at the new place=%s mirrored reads the left margin=%s margins gone, nothing moved=%s desktop unchanged=%s" % [conv95, conv_ok95, whole95, window95, int(big95.x), clamp95, desk95, zero95, moved95, inside95, corner95, block95, quest95, line95, hit95, mirror95, back95, desk_back95])
	if want.call("d96_back_button"):
		# losing the window's focus on a phone (or with the touch keys on) pauses the game under a centred 돌아왔다 key; the stick and held keys let go,
		# the world and the clock wait, an open story keeps its line, and play goes on only after the key is pressed (idea 96)
		if main.intro:
			main.start_game(false)
		main.close_story()
		calm_enemies(true)
		var root96 := get_tree().root # a phone's canvas, 960 x 540 (the headless window is 64 px)
		var scale96 := [root96.content_scale_mode, root96.content_scale_aspect, root96.content_scale_size]
		root96.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root96.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root96.content_scale_size = Vector2i(960, 540)
		var au96 = main.away_ui
		# the tests keep it off, and a desktop without touch keys never fires
		au96.notify(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		var off96: bool = not main.away and not main.get_tree().paused
		au96.off = false
		au96.notify(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		var desk96: bool = not main.away and not main.get_tree().paused
		await main.enable_touch()
		await wait(0.2)
		var tl96: Control = main.touch_layer
		reset_to(main.START)
		main.show_story("", ["||첫째 줄", "||둘째 줄"])
		await wait(0.3)
		var line96: String = main.ui.story_text.text
		tl96.pad_idx = 5
		tl96.held[6] = "guard"
		main.touch_keys[KEY_L] = true
		main.touch_move = Vector2(1, 0)
		var t0: float = main.t
		au96.notify(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await wait(0.4)
		var paused96: bool = main.away and main.get_tree().paused and au96.layer.visible
		var still96: bool = is_equal_approx(main.t, t0)
		var let_go96: bool = tl96.pad_idx == -1 and tl96.held.is_empty() and main.touch_keys.is_empty() and main.touch_move == Vector2.ZERO
		var vs96: Vector2 = get_viewport().get_visible_rect().size
		var bc96: Vector2 = au96.button.get_global_rect().get_center()
		var centred96: bool = bc96.distance_to(vs96 / 2.0) < 2.0 and au96.button.text == tr("돌아왔다")
		var story_kept96: bool = main.story_open and main.ui.story_text.text == line96
		# a key press or a tap beside the key does not bring play back
		tap(KEY_W)
		var beside := InputEventMouseButton.new()
		beside.button_index = MOUSE_BUTTON_LEFT
		beside.position = Vector2(3, 3)
		beside.pressed = true
		Input.parse_input_event(beside)
		var beside_up := beside.duplicate()
		beside_up.pressed = false
		Input.parse_input_event(beside_up)
		await wait(0.3)
		var waits96: bool = main.away and main.get_tree().paused and is_equal_approx(main.t, t0) and main.story_open
		# the key itself, pressed like a finger would
		au96.button.pressed.emit() # the key as a finger presses it
		await wait(0.5)
		var back96: bool = not main.away and not main.get_tree().paused and not au96.layer.visible and main.t > t0 + 0.2
		var story_back96: bool = main.story_open and main.ui.story_text.text == line96
		main.close_story()
		# a second loss of focus works again; the paused call is the phone's
		au96.notify(Node.NOTIFICATION_APPLICATION_PAUSED)
		var again96: bool = main.away and main.get_tree().paused
		au96.back()
		var done96: bool = not main.away and not main.get_tree().paused
		au96.off = true
		main.disable_touch()
		root96.content_scale_mode = scale96[0]
		root96.content_scale_aspect = scale96[1]
		root96.content_scale_size = scale96[2]
		calm_enemies(false)
		check("d96_back_button", off96 and desk96 and paused96 and still96 and let_go96 and centred96 and story_kept96 and waits96 and back96 and story_back96 and again96 and done96,
			"tests keep it off=%s desktop without touch keys=%s paused=%s clock stands=%s stick and keys let go=%s key centred=%s story line kept=%s a key press and a tap beside do nothing=%s the key brings play back=%s story still on its line=%s paused call works=%s ends=%s" % [off96, desk96, paused96, still96, let_go96, centred96, story_kept96, waits96, back96, story_back96, again96, done96])

	var failed := results.count(false)
	print("TESTS %d passed, %d failed" % [results.size() - failed, failed])
	get_tree().quit(failed)

# one telegraph of a new brick foe: Sora stays put (inside) or steps out of the warned area once the telegraph shows
func nf_trial(kind: String, inside: bool, C: Vector2) -> Dictionary:
	var gap: float = {"bird": 2.0, "moth": 1.5, "hopper": 4.0 if inside else 5.5, "pendulum": 1.6}[kind]
	var home := C + Vector2(gap, 0.0)
	var away: Vector2 = {"bird": C + Vector2(0.0, 1.6), "moth": C + Vector2(-3.0, 0.0),
		"hopper": home + Vector2(-cos(deg_to_rad(12.5)), sin(deg_to_rad(12.5))) * 5.0, "pendulum": home + Vector2(1.2, 0.0)}[kind]
	reset_to(C)
	main.player.inv = 0.0
	var e: Dictionary = main.brick_foes.spawn_demo(kind, home)
	var r := {"hp": e.max_hp, "hit": false, "tele": 0.0, "seam": 0.0, "seam_at": 0.0, "seam_len": 0.0, "rest": 0.0, "burst_at": 0.0,
		"shots": 0, "fire_at": 0.0, "sweep": 0.0, "seam_gap": 0.0}
	e.hp = 99999.0
	var hp0: float = main.player.hp
	var t0 := gsec()
	var moved := false
	for i in {"bird": 44, "moth": 50, "hopper": 50, "pendulum": 52}[kind]: # just short of its second telegraph
		await wait(0.05)
		var now := gsec() - t0
		if e.tele_t > 0.0 and r.tele == 0.0:
			r.tele = now
		if e.tele_t > 0.0 and not inside and not moved:
			moved = true
			reset_to(away)
		if main.player.hp < hp0:
			r.hit = true
		if kind == "bird" and e.seam > 0.0 and r.seam == 0.0:
			r.seam = e.seam
			r.seam_at = now
		r.seam_len = maxf(r.seam_len, e.seam) # the seam's longest remaining time seen: its length to within a frame
		if kind == "moth" and e.rest > 0.0 and r.rest == 0.0:
			r.rest = e.rest
			r.burst_at = now
		if kind == "hopper":
			if main.enemy_shots.size() >= 3 and r.shots == 0:
				r.shots = main.enemy_shots.size()
				r.fire_at = now
		if kind == "pendulum":
			if e.sweep_t > 0.0 and r.sweep == 0.0:
				r.sweep = now
			if e.seam > 0.0 and r.seam == 0.0:
				r.seam = e.seam
				r.seam_gap = now - r.sweep
				r.seam_at = now
	e.dead = true
	e.node.queue_free()
	e.shadow.queue_free()
	main.enemies.erase(e)
	for sh in main.enemy_shots:
		sh.node.queue_free()
	main.enemy_shots.clear()
	reset_to(C)
	return r

# Writes each named sound to DIR/name.wav and prints its shape:
#   SOUND name dur=0.06s peak=0.31 rms=0.09 zcr=0.21
# zcr is zero crossings per sample: higher means brighter / more hiss (a pure 100 Hz tone is about 0.009).
static func sound_report(m: Node, dir: String) -> void:
	var sounds := {
		"step_grass": [100.0, 0.06, "noise", 0.12, 0.0],
		"step_bridge": [150.0, 0.07, "triangle", 0.22, -60.0],
		"hit": [300.0, 0.08, "square", 0.2, -200.0],
		"hurt": [320.0, 0.09, "triangle", 0.13, -140.0],
		"hurt_body": [160.0, 0.12, "step", 0.08, 0.0],
		"hurt_old": [90.0, 0.15, "square", 0.25, -40.0],
		"swing": [180.0, 0.07, "sawtooth", 0.12, 300.0],
		"stomp": [55.0, 0.5, "square", 0.35, -30.0],
		"buy": [880.0, 0.08, "square", 0.15, 0.0],
	}
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	for name in sounds:
		var a: Array = sounds[name]
		var st: AudioStreamWAV = m.sfx_stream(a[0], a[1], a[2], a[3], a[4])
		var d := st.data
		var n := d.size() / 2
		var peak := 0.0
		var sum := 0.0
		var cross := 0
		var prev := 0.0
		for i in n:
			var v := d.decode_s16(i * 2) / 32768.0
			peak = maxf(peak, absf(v))
			sum += v * v
			if i > 0 and signf(v) != signf(prev):
				cross += 1
			prev = v
		if dir != "":
			st.save_to_wav(dir.path_join(name + ".wav"))
		print("SOUND %s dur=%.2fs peak=%.2f rms=%.3f zcr=%.3f" % [name, float(n) / st.mix_rate, peak, sqrt(sum / maxi(1, n)), float(cross) / maxi(1, n)])
