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

const TESTS := ["start_click", "story_opens", "story_closes", "opening", "meet_bori", "boss_opens_cave", "save_load", "story_kept", "cave_enter", "cave_layout", "archer_telegraph", "key_door", "rival_scene", "cave_save_load", "painting_once", "unstick", "mole_charge", "mole_grants_skip", "cave_faint", "cave_exit", "water_skip", "water_skip_letgo", "village_enter", "village_layout", "simji_talk", "lamp_cost_night", "lamp_cost_day", "lamp_no_pips", "pip_rest", "errand_done", "kongal_errand", "doran_errand", "mulgyeol_errand", "lantern_night", "folk_again", "lake", "forest", "hill", "garden_end", "village_exit", "marsh_scraps", "forest_grove", "firefly_errand", "grotto", "cloud", "castle", "shrine", "journal", "esc_sheets", "news_more", "touch_controls", "quest_layout", "bgm", "mash", "folk_height", "folk_hop", "windrun_retry", "story_pad", "folk_sleep", "folk_routine", "hint_folk", "wolf", "trial", "squirrels", "crystals", "race", "vault", "save_tonight", "fishing", "bat", "moonflowers", "houses", "one_key", "feats", "mail", "festival", "new_round", "shop_price", "cloud_path", "waystones", "stuck_fixes", "story_fixes", "bracelet", "playtest5", "laps", "books", "bori_e", "moon_stairs", "undercroft", "workshop", "hollow", "hush", "trial_repeat", "road", "mill", "post", "lake_south", "clock", "shore", "quarters", "oak", "village_market", "mate_facing", "settings", "mate_chat", "pips", "folk_chat", "noeul_rest", "east_bridge", "fall_down", "mate_hp", "start_key", "bridges", "shop_buy", "shop_click", "footsteps", "boss_survive", "faint_resets", "lap6", "lap7", "lap8",
	"flash_dodge", "late_dodge", "flash_guard", "guard_block", "guard_back", "momentum", "level_moves", "level_perks", "gear_look", "hill_dressing", "folk_mark", "island_landing", "bori_away", "bus_layout", "area_steps", "tree_chop", "chain_cut", "stage_noeul", "seam_pins", "lantern_toggle", "ending_replay", "mural_split", "skill_cost", "goblin_telegraph", "boss_phase2",
	"hawk_leash", "mold_leash", "mold_no_skip", "king_calm", "faint_banner", "windrun_faint", "mate_skips_air", "kid_reload", "race_save"]

func _ready() -> void:
	run.call_deferred()

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

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

func run() -> void:
	var want := func(n): return only == "all" or n in only.split(",")
	main.sleep_off = true # the villagers stay out at night here; folk_sleep turns their sleep back on
	main.routine_off = true # and on their spots by day; folk_routine turns their rounds on
	main.folk_chat_off = true # and quiet; folk_chat lets them talk
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
	if want.call("start_click"):
		await wait(1.0) # let the title orbit drift the camera first
		click()
		await wait(0.3)
		check("start_click", not main.intro and absf(main.cam_yaw - main.CAM_YAW) < 0.001, "title closes on a mouse click, camera back to the fixed angle (yaw %.3f)" % main.cam_yaw)
		check("story_opens", main.story_open, "opening illustration shows after the title")
		for k in 30:
			if not main.story_open:
				break
			click()
			await wait(0.05)
		await wait(0.7)
		check("story_closes", not main.story_open and not main.ui.story.visible, "two clicks page through and close it")
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
		for k in 40:
			if not main.story_open:
				break
			tap(KEY_SPACE)
			await wait(0.05)
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
		check("guard_block", r == "guard" and main.player.hp == main.player.max_hp - 3 and main.player.sp <= 85.5,
			"result=%s hp lost %d (want 3) stamina %d" % [r, int(main.player.max_hp - main.player.hp), int(main.player.sp)])
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
		check("level_perks", foes == [0, 3, 8] and quick, "foe levels in the marsh %s (want [0, 3, 8]: 30%% of the old level share, area step 0) skill cd Lv15 %.2f vs Lv1 %.2f" % [str(foes), cd15, cd1])
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
		var mesh: bool = main.veg_meshes.any(func(mm): return mm.instance_count == tiles.size() * 6)
		check("hill_dressing", tiles.size() > 400 and near_clear == 0 and mesh, "hill grass tiles %d, next to the path or a used spot %d, tuft mesh of six a tile=%s" % [tiles.size(), near_clear, mesh])
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
		var pic: bool = main.story_open and main.ui.story_img.texture != null and main.ui.story_img.texture.resource_path.ends_with("12_festival.jpg")
		var closed: bool = not main.ui.journal.visible
		main.close_story()
		var unpaid: bool = main.player.gold == gold0 and main.story_step == 12
		main.story_step = keep_step
		main.ng = keep_ng
		check("ending_replay", hidden_before and none_before and shown_after and pic and closed and unpaid,
			"hidden before=%s nothing before=%s shown after=%s festival picture=%s journal closed=%s unpaid=%s" % [hidden_before, none_before, shown_after, pic, closed, unpaid])
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
		var road: String = main.main_road_quest()
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
			await wait(0.4)
			var winding: bool = m0.wind > 0.0
			var hp_wind: float = main.player.hp
			await wait(1.5)
			check("mole_charge", winding and hp_wind == 200.0 and main.player.hp < 200.0,
				"winds up=%s, no damage during wind-up=%s, charge hit for %d" % [winding, hp_wind == 200.0, int(200.0 - main.player.hp)])
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
		var keep_up: int = main.skill_up
		main.saw_painting = true
		main.skill_up = -1
		main.toast_t = 0.0
		reset_to(main.cave_marks.E + Vector2(-0.5, 0))
		await wait(0.8)
		var held: bool = main.in_cave and main.ui.toast.text.contains("기술")
		main.skill_up = maxi(keep_up, 0)
		var talk := false
		for k in 12: # the fade out, then the way-out story (close whatever opens on the way)
			await wait(0.3)
			if main.story_open:
				talk = talk or main.ui.story_text.text.contains("밤")
				main.close_story()
		await wait(0.3)
		# outside, the stone stair stays beside her and leads back down
		var stair: bool = main.cave.exit_built and not main.in_cave
		main.skill_up = keep_up
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
		await wait(1.6)
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
		var n0: int = main.enemies.size()
		reset_to(d0.pos + Vector2(-1.0, 0))
		tap(KEY_E)
		await wait(1.3)
		check("lamp_cost_night", d0.lit and main.crown_pips == 6 and main.enemies.size() == n0 + 1, "lit=%s pips 7->%d goblin woke=%s" % [d0.lit, main.crown_pips, main.enemies.size() == n0 + 1])
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
		var lit_lamp = main.lanterns.filter(func(l): return l.position.x > 130.0 and not l.get_meta("dark", false))[0]
		reset_to(Vector2(lit_lamp.position.x + 0.4, lit_lamp.position.z + 1.0))
		await wait(15.0)
		check("pip_rest", main.crown_pips >= 4, "15 s resting by a lit lantern at night (3 s a pip): pips 0->%d" % main.crown_pips)
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
		main.hour = 22.0
		reset_to(main.village.marks.F + Vector2(-0.3, 0))
		await wait(1.5)
		var entered: bool = main.in_forest and main.forest_q == 1
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
		main.in_village = false
		main.in_forest = true
		main.hour = 22.0
		reset_to(main.forest.marks.E + Vector2(-0.3, 0))
		await wait(1.5)
		var shields: Array = main.enemies.filter(func(e): return not e.dead and e.get("shield", 0) > 0)
		var entered: bool = main.in_hill and main.hill_q == 1 and shields.size() == 3 and main.mate2 != null
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
			mold[0].hp = mold[0].max_hp * 0.13
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
		var lent: bool = main.fly_q == 3 and main.jar_node != null and main.player.gold == g0 + 30
		main.in_village = false
		calm_enemies(false)
		check("firefly_errand", asked and hidden_by_day and walk_ok and full and lent, "asked=%s hidden by day=%s spots walkable=%s caught=%d lent jar=%s" % [asked, hidden_by_day, walk_ok, main.marsh.caught(), lent])
	if want.call("grotto"):
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
			main.player.inv = 99.0
			for i in 40:
				reset_to(Vector2(c.x + 6.0, c.z)) # keep backing off: from afar the crab spits
				main.player.inv = 99.0
				await wait(0.1)
				if main.enemy_shots.size() >= 3:
					spat = true
					break
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
		var pearl: bool = main.has_pearl and main.grotto_q == 4
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
		main.skill_up = -1
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
		var whirl: bool = main.skill_up == 0
		reset_to(main.cave_marks["3"] + Vector2(0, -1.0))
		tap(KEY_SPACE)
		await wait(0.2)
		main.close_story()
		var nova: bool = main.skill_up == 2 and main.skill_cost(2) == 45
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
		var cleared: bool = main.trial_best > 0.0 and main.player.gold >= g0 + 300 and main.player.max_hp == hp0 + 20 + 12 * (main.player.lv - lv0) # kills level her up too
		calm_enemies(false)
		check("trial", began and waves == 5 and cleared, "began=%s waves seen=%d cleared=%s best %.1f s" % [began, waves, cleared, main.trial_best])
	if want.call("squirrels"):
		if main.intro:
			main.start_game(false)
		main.close_story()
		main.in_village = false
		main.in_forest = true
		main.forest_q = maxi(main.forest_q, 1)
		main.forest.freed = [false, false, false, false, false]
		main.has_acorn = false
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
		var acorn: bool = main.has_acorn and main.player.hp >= 75.0 - 0.5
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
		check("crystals", cr.size() == 4 and sword_rings and reset and done and reach and main.has_ring, "crystals=%d sword rings=%s wrong note resets=%s solved=%s chest reachable=%s ring=%s" % [cr.size(), sword_rings, reset, done, reach, main.has_ring])
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
		var clear: bool = not quest_r.intersects(mates_r) and not boss_r.intersects(mates_r) and quest_r.end.x <= vs.x - 194.0 and main.ui.quest.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
		for n in ["zoom_in", "zoom_out"]:
			var zr := Rect2(tk[n][0] - Vector2.ONE * tk[n][1] * 1.1, Vector2.ONE * tk[n][1] * 2.2)
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
								for r in [main.hud_build.STATUS_RECT, main.hud_build.DIAL_RECT, main.hud_build.mates_rect(), main.ui.mini.get_parent().get_global_rect()]:
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
					worst = maxf(worst, absf(top - bot))
					cases += 1
					if absf(top - bot) > 2.0 or r.position.x < 0.0 or r.end.x > vs.x + 0.5 or r.position.y < 0.0 or r.end.y > vs.y + 0.5:
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
		await wait(0.5)
		var mrest: bool = mspr.position.y < 0.001
		check("folk_hop", peak > 0.1 and peak <= 0.1201 and peak_first > 0.1 and lows >= 4 and settled and node_flat and mpeak > 0.1 and mpeak <= 0.1201 and mnode < 0.001 and mrest,
			"peak %.3f (first hop %.3f), landed %d times, settled in %.2f s, node on the ground=%s; Mulgyeol peak %.3f node %.3f, rests %s" % [peak, peak_first, lows, stopped_t, node_flat, mpeak, mnode, mrest])
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
				var st = load("res://audio/bgm/%s.ogg" % (n if k == 0 else "%s_%d" % [n, k + 1]))
				loops = loops and st is AudioStreamOggVorbis and st.loop
		main.music.play("village")
		var f0: String = main.music.cur_file
		main.music.played = main.music.ROTATE + 1.0
		main.music.play("village")
		loops = loops and main.music.cur_file != f0 and main.music.cur_file.begins_with(main.music.cur)
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
		var less: bool = main.has_armour and absf((hp0 - main.player.hp) - 17.0) < 0.01
		main.player.hp = float(main.player.max_hp)
		main.in_hill = false
		check("vault", shut and wrong and solved and less, "gates shut=%s all three levers wrong=%s levers 1+3 open=%s armour takes 20 as 17=%s" % [shut, wrong, solved, less])
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
		main.skill_up = 1
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
		main.skill_up = -1
		main.trial_best = 0.0
		main.race_best = 0.0
		main.castle_q = 0
		main.load_game()
		var ok: bool = main.has_pearl and main.has_feather and main.has_ring and main.has_shoes and main.has_acorn and main.has_armour 			and main.crystal_done and main.fly_q == 3 and main.grotto_q == 4 and main.cloud_q == 3 and main.skill_up == 1 			and main.trial_best == 77.0 and main.race_best == 12.5 and main.castle_q == 3 and main.marsh.chest_open and main.forest.freed.count(true) == 5
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
		tap(KEY_E)
		await wait(0.1)
		var cast: bool = main.fish_state == "wait"
		tap(KEY_E) # too early
		await wait(0.1)
		var early: bool = main.fish_state == ""
		var landed := 0
		for i in 40:
			if main.fish_kinds.count(true) == 5:
				break
			tap(KEY_E)
			await wait(0.05)
			main.fish_t = 0.0
			await wait(0.05)
			if main.fish_state == "bite":
				tap(KEY_E)
				await wait(0.05)
				landed += 1
			main.close_story()
		main.in_lake = false
		check("fishing", reach and cast and early and landed > 0, "spot reachable=%s cast=%s early pull loses it=%s landed=%d kinds=%d%s" % [reach, cast, early, landed, main.fish_kinds.count(true), "" if cast else " (before the cast: %s)" % why])
	if want.call("bat"):
		var ok_spots := true
		for b in main.BAT_SPOTS:
			ok_spots = ok_spots and main.walkable(b.x, b.y)
		calm_enemies(true)
		reset_to(Vector2(20, 30))
		main.spawn_bat(Vector2(23, 30))
		var b0: Dictionary = main.enemies[main.enemies.size() - 1]
		b0.hp = 99999.0
		b0.atk_cd = 1.0
		var swooped := false
		var hp0: float = main.player.hp
		for i in 50:
			reset_to(Vector2(20, 30))
			main.player.hp = hp0
			await wait(0.1)
			if b0.dash > 0.0:
				swooped = true
		var flies: bool = b0.node.position.y > 0.5
		if not b0.dead:
			b0.dead = true
			b0.node.queue_free()
			b0.shadow.queue_free()
		calm_enemies(false)
		check("bat", ok_spots and swooped and flies, "spots open=%s swoops=%s flies above ground=%s" % [ok_spots, swooped, flies])
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
		var harder: bool = absf(main.player.hp - 85.0) < 0.01
		main.has_armour = armour
		main.player.hp = float(main.player.max_hp)
		main.ng = 0
		e.dead = true
		e.node.queue_free()
		e.shadow.queue_free()
		calm_enemies(false)
		main.has_pearl = true
		main.skill_up = 2
		var lv0: int = main.player.lv
		main.write_new_round()
		var sd = JSON.parse_string(FileAccess.get_file_as_string(main.SAVE_PATH))
		var kept: bool = int(sd.get("story", -1)) == 0 and int(sd.get("ng", 0)) == 1 and int(sd.get("lv", 0)) == lv0 			and bool(sd.get("has_pearl", false)) and int(sd.get("skill_up", -1)) == 2 and not sd.has("lake_q") and not sd.has("chests")
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
		var opened: bool = main.way_open and main.ui.ways.visible
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
		main.leave_cave()
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
		for q in ["팔목의 팔찌를 만져 보자 (E)", "도란의 편지에 팔찌를 대 보자 (E, 달빛 눈금 사용)", "끝. 다시 돌기 시작한 정원을 거닐자 (정원 한가운데서 E 두 번: 새 바퀴)", "깊은 틈 위 한결의 발자국을 따라가자 (E로 비추기)"]:
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
		check("books", reach and main.has_bookmark and more, "shelves reachable=%s bookmark=%s xp x1.2=%s" % [reach, main.has_bookmark, more])
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
		var tilt_off: bool = main.ui.set_rows.keys() == ["sound"] and main.cfg.tilt and main.cfg.shake and main.cfg.nums \
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
		var hud_ok: bool = spots.size() == 12 and (spots[11] as Vector2).x + 6.0 <= 400.0 and main.ui.hud.pips_drawn == 12
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
			"one pip at each place %s=%s once=%s max HP no longer grows=%s letter says max 9=%s HUD 12 inside 400 px=%s (%d drawn) save/load=%s new round keeps and fills=%s %s old save gets 3 back once=%s" % [str(steps), grew, once, hp_same, letter_line, hud_ok, main.ui.hud.pips_drawn, saved, round_ok, round_info, old_ok])
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
		var standing: bool = not main.noeul_sitting and spr.hframes == 3 and not main.mulgyeol_sitting and mspr.hframes == 2
		main.last_input_t = main.t - 20.0 # no key for 20 s
		await wait(1.0)
		var sat: bool = main.noeul_sitting and spr.hframes == 1 and spr.texture.resource_path.ends_with("noeul_rest.png")
		var msat: bool = main.mulgyeol_sitting and mspr.hframes == 1 and mspr.texture.resource_path.ends_with("mulgyeol_rest.png") and absf(mspr.offset.y - 90.0) < 0.1 			and Vector2(main.mate.position.x - main.mate2.position.x, main.mate.position.z - main.mate2.position.z).length() >= 0.9
		hold_world(Vector2(1, 0))
		main.last_input_t = main.t
		await wait(0.4)
		release()
		var up: bool = not main.noeul_sitting and spr.hframes == 3 and spr.texture.resource_path.ends_with("noeul.png") and not main.mulgyeol_sitting and mspr.hframes == 2 and mspr.texture.resource_path.ends_with("mulgyeol.png") and absf(mspr.offset.y - 85.0) < 0.1
		main.player.vx = 0.0
		main.player.vz = 0.0
		await wait(1.0)
		main.last_input_t = main.t - 20.0
		main.spawn_enemy(Vector2(main.player.x + 4.0, main.player.z)) # a monster near: he does not sit
		var gob: Dictionary = main.enemies[main.enemies.size() - 1]
		await wait(0.5)
		var fight_up: bool = not main.noeul_sitting and not main.mulgyeol_sitting
		if not gob.dead:
			gob.dead = true
			gob.node.queue_free()
			gob.shadow.queue_free()
		gob.respawn = 9999.0
		for e in risers:
			e.respawn = 8.0
		main.last_input_t = main.t
		calm_enemies(false)
		check("noeul_rest", standing and sat and msat and up and fight_up, "standing at first=%s Noeul sits on the rest picture while Sora rests=%s Mulgyeol too, apart from him=%s both stand when she moves=%s both stay up with a monster near=%s" % [standing, sat, msat, up, fight_up])
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
		var fell: bool = absf(main.player.x - (gx + 19)) < 0.6 and absf(main.player.z - 32.0) < 0.6 and main.player.hp == main.player.max_hp - 8
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
		var rose: bool = echoes.size() == 1 and echoes[0].max_hp == 950
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
			"arrived at the yard=%s roots shut/unwound=%s/%s fifth page=%s hook=%s fell off and back=%s footprint holds=%s brick Hangyeol 950=%s beaten opens the gate=%s arena=%s saved and waystone=%s" % [arrived, shut, roots, page, hook, fell, stood, rose, beaten, arena, kept])
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
		var guard_ok: bool = guards.size() == 1 and guards[0].max_hp == 300 + main.foe_lv() * 30
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
		reset_to(sm.c + Vector2(1.0, 0))
		tap(KEY_E)
		await wait(0.15)
		main.close_story()
		var chest: bool = main.mill_q == 5 and main.has_oar_ring and main.player.max_hp == hp0 + 10 and main.mate_power() == 0.7
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
			and main.clock_q == 2 and main.garden.clock_screen.visible
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
			and main.crown_pips == 4 and tending == 6
		# 6. the crown into the key: Sora at Hangyeol's spoke, everyone at one
		reset_to(Vector2(243, 56))
		main.player.inv = 120.0
		tap(KEY_E)
		await wait(0.2)
		main.close_story()
		await wait(0.3)
		var mp := Vector2(main.mate.position.x, main.mate.position.z)
		var hub: bool = main.clock_q == 4 and Vector2(main.player.x, main.player.z).distance_to(main.garden.clock_marks.J) < 0.35 \
			and absf(mp.x - 241.0) <= 1.0 and absf(mp.y - 55.0) <= 1.0 and main.garden.crown_rim.visible and main.clock_folk.size() == 4
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
		var wound: bool = main.clock_q == 5 and main.story_open and main.ui.story_frame.visible and main.beat.is_empty()
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
		await wait(2.0)
		var hp_night: float = main.player.hp
		var rested: bool = hp_night >= 56.5 and hp_night <= 59.5
		var near_foe := 99.0
		for e in main.enemies:
			if not e.dead:
				near_foe = minf(near_foe, Vector2(e.x - main.player.x, e.z - main.player.z).length())
		main.hour = 13.0
		main.player.hp = 50.0
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
		var mark_walk: bool = no_mark.call()
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
		var mid: bool = main.quarters_q == 3 and not main.doll_walk and main.doll_at == main.CASTLE.DOLL_PATH[0] \
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
		var warm: bool = main.crown_pips == 1
		reset_to(Vector2(204, 12.4))
		main.rest_t = 0.0
		await wait(3.5)
		var lamp_day: bool = main.crown_pips == 1
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
		var held: bool = main.hero.region_rect.position.x == 3 * 192
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
		var big: bool = cloaks.size() == 1 and cloaks[0].max_hp == 1000
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
			"gate shut/opened=%s/%s woke=%d of %d north unchanged=%s hogs=%d stream dry/skip=%s/%s three memories (pips 5)=%s cloak 1000=%s beaten=%s curled blocks=%s dizzy hits=%s sunset door=%s lantern=%s saved=%s Simji=%s (hollow_q %d, max HP %d -> %d, awards %s)" % [shut, opened, woke, fm.south.size(), north1 == north0, hogs.size(), dry, wet, lit, big, beaten, curled, hit, door, lantern, kept, given, main.hollow_q, hp1, main.player.max_hp, str(main.pip_awards.keys())])
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
		behind.x = 444.0 # now in her own hall
		behind.z = 4.0
		main.crown_pips = 0
		main.rest_said = false
		main.ui.toast.modulate.a = 0.0
		reset_to(Vector2(441.4, 6.4))
		await wait(1.0)
		var said_once: bool = main.rest_said and "쉴 수 없다" in main.ui.toast.text
		for pin in 14: # hold the monster in the hall while she tries to rest
			behind.x = 444.0
			behind.z = 4.0
			await wait(0.5)
		var pips_room: int = main.crown_pips
		var clear_room: bool = main.line_clear(Vector2(441.4, 6.4), Vector2(444.0, 4.0))
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
	var failed := results.count(false)
	print("TESTS %d passed, %d failed" % [results.size() - failed, failed])
	get_tree().quit(failed)

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
