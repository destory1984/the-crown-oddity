# Test scenes: the SCENES table and apply_test_args (dev.py shot/test start states).
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const SCENES := {
	"title": {},
	"start": {"play": true},
	"night": {"play": true, "hour": 23.0, "day": 4},
	"dusk": {"play": true, "hour": 19.5},
	"noon": {"play": true, "hour": 13.0},
	"cottage": {"play": true, "at": "cottage"},
	"shop": {"play": true, "at": "shop", "gold": 120, "shop": true},
	"boss": {"play": true, "at": Vector2(16, 11)},
	"bridge": {"play": true, "at": Vector2(19, 26)},
	"faint": {"play": true, "faint": 2.5},
	"opening": {"play": true, "opening": true},
	"cave": {"play": true, "cave": true},
	"cave_in": {"play": true, "cave_in": true},
	"talk": {"play": true, "talk": true},
	"mole": {"play": true, "mole": true},
	"scene": {"play": true, "scene": true},
	"village": {"play": true, "village": true},
	"village_night": {"play": true, "village": true, "hour": 22.0},
	"market": {"play": true, "village": true, "vat": Vector2(38, 6), "hour": 14.0},
	"house_designs": {"play": true, "village": true, "house_designs": true, "hour": 14.0},
	"swing_designs": {"play": true, "village": true, "swing_designs": true, "hour": 14.0},
	"swing": {"play": true, "village": true, "swing": true, "hour": 14.0},
	"far": {"play": true, "village": true, "far": true, "hour": 14.0},
	"pier": {"play": true, "village": true, "vat": Vector2(32, 29), "hour": 14.0},
	"inn": {"play": true, "village": true, "vat": Vector2(8, 30), "hour": 14.0},
	"forest": {"play": true, "village": true, "forest": true, "hour": 16.0},
	"forest_night": {"play": true, "village": true, "forest": true, "hour": 22.0},
	"mold": {"play": true, "village": true, "mold": true, "hour": 21.0},
	"turtle": {"play": true, "village": true, "turtle": true, "hour": 15.0},
	"hill": {"play": true, "village": true, "hill": true, "hour": 10.0},
	"kid": {"play": true, "village": true, "kid": true, "hour": 20.5},
	"grove": {"play": true, "village": true, "forest": true, "grove": true, "hour": 15.0},
	"hollow": {"play": true, "village": true, "forest": true, "hollow": true, "hour": 21.0},
	"road": {"play": true, "village": true, "road": true, "hour": 14.0},
	"post": {"play": true, "post": true, "hour": 14.0},
	"lake_south": {"play": true, "village": true, "lake_south": true, "hour": 15.0},
	"lake_pond": {"play": true, "village": true, "lake_south": true, "pond": true, "hour": 15.0},
	"lake_spring": {"play": true, "village": true, "lake_south": true, "spring": true, "hour": 21.0},
	"mill": {"play": true, "village": true, "mill": true, "hour": 15.0},
	"mill_water": {"play": true, "village": true, "mill": true, "water": true, "hour": 15.0},
	"road_echo": {"play": true, "village": true, "road": true, "echo": true, "hour": 14.0},
	"clock": {"play": true, "village": true, "clock": true, "hour": 21.0},
	"clock_wind": {"play": true, "village": true, "clock": true, "wind": true, "hour": 21.0},
	"flies": {"play": true, "at": Vector2(8, 23), "hour": 22.5, "flies": true},
	"crab": {"play": true, "village": true, "crab": true, "hour": 14.0},
	"grotto_in": {"play": true, "village": true, "crab": true, "grotto_in": true, "hour": 21.0},
	"grotto_steps": {"play": true, "village": true, "turtle": true, "steps": true, "hour": 15.0},
	"cloud": {"play": true, "village": true, "cloud": true, "hour": 11.0},
	"scarecrow": {"play": true, "village": true, "cloud": true, "scare": true, "hour": 16.0},
	"castle": {"play": true, "village": true, "castle": true, "hour": 15.0},
	"knight": {"play": true, "village": true, "castle": true, "knight": true, "hour": 15.0},
	"shrine": {"play": true, "shrine": true},
	"journal": {"play": true, "journal": true},
	"wolves": {"play": true, "village": true, "forest": true, "wolves": true, "hour": 16.5},
	"trial": {"play": true, "village": true, "trial": true, "hour": 21.0},
	"cage": {"play": true, "village": true, "forest": true, "cage": true, "hour": 14.0},
	"race": {"play": true, "village": true, "hill": true, "race": true, "hour": 10.0},
	"moonflower": {"play": true, "at": Vector2(37.0, 24.5), "hour": 22.5, "day": 4},
	"house": {"play": true, "village": true, "house": true, "hour": 15.0},
	"sleep": {"play": true, "village": true, "sleep": true, "hour": 23.0, "day": 4}, # Doran asleep in his house
	"sleep_drafts": {"play": true, "village": true, "sleep_drafts": 0, "hour": 23.0, "day": 4}, # five sleeping-villager drafts (sys/sleep_drafts.gd)
	"sleep_draft1": {"play": true, "village": true, "sleep_drafts": 1, "hour": 23.0, "day": 4},
	"sleep_draft2": {"play": true, "village": true, "sleep_drafts": 2, "hour": 23.0, "day": 4},
	"sleep_draft3": {"play": true, "village": true, "sleep_drafts": 3, "hour": 23.0, "day": 4},
	"sleep_draft4": {"play": true, "village": true, "sleep_drafts": 4, "hour": 23.0, "day": 4},
	"sleep_draft5": {"play": true, "village": true, "sleep_drafts": 5, "hour": 23.0, "day": 4},
	"folk6": {"play": true, "village": true, "vat": Vector2(38, 18), "folk6": true, "hour": 14.0}, # the six working villagers by day
	"folk_day": {"play": true, "village": true, "vat": Vector2(38, 18), "folk6": true, "folk_day": true, "hour": 14.0}, # out on their rounds
	"festival": {"play": true, "village": true, "festival": true, "hour": 22.0, "day": 4},
	"cloudpath": {"play": true, "village": true, "cloud": true, "path": true, "hour": 11.0},
	"ways": {"play": true, "ways": true, "hour": 16.0},
	"walk_dr": {"play": true, "walk_dr": true, "at": Vector2(12, 14), "hour": 12.0},
	"settings": {"play": true, "settings": true},
	"controls_big": {"play": true, "controls": true, "text": 3},
	"settings_big": {"play": true, "settings": true, "text": 3},
	"settings_news": {"play": true, "settings": true, "set_tab": 2}, # the Changes tab
	"settings_help": {"play": true, "settings": true, "set_tab": 1},                       # the Help tab with the music row
	"settings_off": {"play": true, "settings": true, "set_tab": 1, "sound_off": true, "music_off": true}, # both header buttons in the off state
	"hush": {"play": true, "village": true, "hush": true, "hour": 14.0},
	"east": {"play": true, "at": Vector2(42.0, 21.5), "hour": 12.0},
	"fall": {"play": true, "fall": 2.5, "at": Vector2(20, 22)},
	"chat": {"play": true, "chat": true, "at": Vector2(20, 22), "hour": 13.0},
	"noeul_sit": {"play": true, "noeul_sit": true, "at": Vector2(20, 30), "hour": 13.0}, # Noeul sits while Sora rests
	"folk_talk": {"play": true, "village": true, "folk_talk": true, "hour": 14.0},           # a villager's chatter balloon
	"quest_narrow": {"play": true, "quest_narrow": true, "at": Vector2(20, 22), "hour": 13.0}, # 645 px wide, two companions, a long quest line
	"story_pad": {"play": true, "story_pad": true, "at": Vector2(20, 22), "hour": 13.0}, # 645 px wide, a narration line in the story box
	"folk_line": {"play": true, "village": true, "folk_line": true, "hour": 13.0}, # Sora, Noeul, Mulgyeol and the villagers in a row, names under them
	"pips12": {"play": true, "pips12": true, "at": Vector2(20, 22), "hour": 13.0},          # the moon gauge grown to 12
	"stairs": {"play": true, "village": true, "castle": true, "stairs": true, "hour": 16.0},
	"stairs_foot": {"play": true, "village": true, "castle": true, "stairs": true, "stairs_at": 0, "hour": 16.0},
	"stairs_drop": {"play": true, "village": true, "castle": true, "stairs": true, "stairs_at": 2, "hour": 16.0},
	"under": {"play": true, "village": true, "castle": true, "under": true, "hour": 16.0},
	"under_in": {"play": true, "village": true, "castle": true, "under_in": true, "hour": 16.0},
	"workshop1": {"play": true, "village": true, "castle": true, "workshop": 1, "hour": 16.0}, # 달지기 작업장 B1: both lamps lit, the planks shown
	"workshop2": {"play": true, "village": true, "castle": true, "workshop": 2, "hour": 16.0}, # B2: the lid lifted, the stopper bare
	"workshop3": {"play": true, "village": true, "castle": true, "workshop": 3, "hour": 16.0}, # B3: the work pit, one latch wound
	"stairs_top": {"play": true, "village": true, "castle": true, "stairs": true, "stairs_at": 3, "hour": 16.0},
	"scrap": {"play": true, "at": Vector2(42.5, 5.5), "hour": 17.0},
	"shore": {"play": true, "shore": 1, "at": Vector2(18.5, 19.5), "hour": 15.0},              # the basket in the mud by day
	"shore_float": {"play": true, "shore": 3, "at": Vector2(17.2, 23.0), "hour": 22.0},        # the lantern held at the first snag
	"quarters": {"play": true, "village": true, "castle": true, "quarters": 2, "hour": 21.0},      # 달지기 숙소: the dining hall's bricks up
	"quarters_doll": {"play": true, "village": true, "castle": true, "quarters": 3, "hour": 21.0}, # the doorkeeper walking, three bits at him
	"quarters_rest": {"play": true, "village": true, "castle": true, "quarters": 5, "hour": 21.0}, # he rests in his chair, the ledger signed
	"oak": {"play": true, "village": true, "forest": true, "oak": 1, "hour": 14.0},       # 다람쥐 나무: the clearing open, the west knot loose
	"oak_green": {"play": true, "village": true, "forest": true, "oak": 2, "hour": 14.0}, # the oak green again, five squirrels in it
}
const SWING_DRAFTS := ["초승달 베기", "잔상 세 줄", "금빛 별가루", "셀 애니 붓 자국", "장난감 벽돌 조각"]

func _init(main: Main) -> void:
	m = main

func apply_test_args(args: PackedStringArray) -> void:
	var opt := {}
	for a in args:
		if a.begins_with("--") and "=" in a:
			opt[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
		elif a.begins_with("--"):
			opt[a.substr(2)] = ""
	if not opt.has("scene") and not opt.has("test") and not opt.has("sounds"):
		return
	var scene_name: String = opt.get("scene", "title")
	var sc: Dictionary = SCENES.get(scene_name, {})
	if sc.is_empty() and scene_name != "title":
		push_error("unknown scene: %s (known: %s)" % [scene_name, ", ".join(SCENES.keys())])
	if sc.get("play", false):
		m.start_game(false)
	var at = sc.get("at", null)
	if at is String and at == "cottage":
		at = Vector2(m.shop_pos.x + 1.5, m.shop_pos.z + 2.5)
	elif at is String and at == "shop":
		at = Vector2(m.shop_pos.x, m.shop_pos.z)
	if at is Vector2:
		m.player.x = at.x
		m.player.z = at.y
		m.ground_y = m.height_at(at.x, at.y)
	if sc.has("flies"): # night fireflies over the marsh, and the lent jar already glowing
		m.fly_q = 1
		m.marsh.flies_on = true
		m.build_jar()
	if sc.has("gold"):
		m.player.gold = sc.gold
	if sc.get("shop", false):
		m.story_step = 3
		m.toggle_shop(true)
	if sc.has("shore"): # 깨어난 물가 (DESIGN.md): 1 the basket by day, 3 Bori's lantern floating, held at the first snag
		m.story_step = 3
		m.shore_q = 1
		m.shore_seen = true
		if int(sc.shore) == 3:
			m.story_step = 5
			m.shore_q = 3
			m.marsh.free_basket(m)
			var sd: float = m.marsh.snag_d[0]
			m.shore_float = {"d": sd, "snag": 0, "wait": true, "up": false, "t": 1.0, "lit": true, "stop": false, "wt": 0.0}
			m.marsh.set_float(m.marsh.float_at(sd), true)
			m.player.inv = 99.0
	if sc.get("village", false):
		m.story_step = 7
		m.errand = 1
		m.enter_village()
		m.player.x = m.village.marks.M.x - 2.0
		m.player.z = m.village.marks.M.y + 1.0
		if sc.get("house_designs", false): # five house drafts in a row across the screen, in the village's east field
			var right := Vector2(cos(m.cam_yaw), -sin(m.cam_yaw))
			var c := Vector2(Main.VILLAGE.VILLAGE_X + 33.0, 20.0)
			for k in 5:
				var hp := c + right * (k - 2) * 4.6
				m.village.house_draft(m, Vector3(hp.x, 0, hp.y), k)
			m.player.x = c.x + 1.0
			m.player.z = c.y + 3.5
			m.cam_dist = 22.0
		if sc.get("swing_designs", false): # five sword-swing drafts frozen mid-swing in a row, same field as the houses
			var right := Vector2(cos(m.cam_yaw), -sin(m.cam_yaw))
			var c: Vector2 = m.village.marks.M + Vector2(0, -1.0)
			for k in 5:
				var sp := c + right * (k - 2.3) * 2.8
				var g := m.effects.swing_draft(k, 0.85, 1.8)
				g.position = Vector3(sp.x, 0.5, sp.y)
				g.rotation.y = m.cam_yaw + 0.4 # the arc sweeps across the view
				m.add_child(g)
				var t := Label3D.new()
				t.text = "%d  %s" % [k + 1, tr(SWING_DRAFTS[k])]
				t.font = m.ui_font
				t.font_size = 40
				t.pixel_size = 0.008
				t.modulate = Color("#3a2414")
				t.outline_size = 10
				t.outline_modulate = Color("#f2ead8")
				t.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
				t.no_depth_test = true
				t.position = Vector3(sp.x, 1.9, sp.y)
				m.add_child(t)
			m.player.x = c.x
			m.player.z = c.y + 2.6
			m.cam_dist = 17.0
			m.cfg.tilt = false # no blur: the drafts sit at the edge of the sharp band
			m.apply_settings()
		if sc.has("vat"): # a spot in village tiles
			m.player.x = Main.VILLAGE.VILLAGE_X + sc.vat.x
			m.player.z = sc.vat.y
		if sc.get("forest", false): # the hardened forest, first wall ahead
			m.night_q = 4
			m.forest_q = 1
			m.enter_forest()
			m.player.x = m.forest.walls[0].pos.x - 2.5
			m.player.z = m.forest.walls[0].pos.y
			if sc.has("wolves"):
				m.player.x = Main.FOREST.FOREST_X + 25.0
				m.player.z = 18.0
				m.close_story()
				m.spawn_wolf(Vector2(m.player.x + 2.5, m.player.z + 0.5))
				m.spawn_wolf(Vector2(m.player.x + 1.0, m.player.z + 2.0))
			if sc.has("cage"):
				m.player.x = Main.FOREST.FOREST_X + 13.5
				m.player.z = 5.0
				m.close_story()
			if sc.has("grove"):
				m.player.x = m.forest.marks.t.x + 2.0
				m.player.z = m.forest.marks.t.y
				m.close_story()
			if sc.has("hollow"): # the south valley open, its lamps lit, Sora west of the cloak's yard
				m.close_story()
				m.forest_q = 3
				m.join_noeul()
				m.hollow_q = 1
				m.forest.open_gate_look()
				for l in m.forest.mem_lamps:
					m.forest.light_mem(l)
				m.forest_zone.spawn_hollow()
				m.player.x = m.forest.marks.C.x - 3.0
				m.player.z = m.forest.marks.C.y + 1.0
			if sc.has("oak"): # 다람쥐 나무 (DESIGN.md): 1 the gap open and the west knot loose, 2 the oak green
				m.close_story()
				m.lake_q = 4
				m.forest_q = 3
				m.join_mate()
				m.join_noeul()
				m.hollow_q = 1
				m.forest.open_gate_look()
				for e in m.enemies.filter(func(c): return c.has("cage") and not c.dead):
					e.dead = true
					e.node.queue_free()
					e.shadow.queue_free()
				for i in m.forest.freed.size():
					m.forest.freed[i] = true
				m.has_acorn = true
				m.load_oak({"oak_q": int(sc.oak), "oak_knots": [true, false, false]})
				m.oak_told = true
				m.squirrel_seen = true
				m.player.x = 198.4 # a step north-west of (199, 12) so the big squirrel by the knot shows
				m.player.z = 11.4
				m.snap_mates()
		if sc.get("mill", false): # the sparrows' mill below the wind hills, the big windmill wound
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.hill_q = 3
			m.join_mate()
			m.join_noeul()
			m.enter_hill()
			m.close_story()
			m.hill.raise_bridge()
			m.hill.open_wall()
			m.mill_q = 2
			m.mill_in_told = true
			m.hill.wind_mill4(m)
			m.player.x = m.hill.south_marks.P.x + 1.0
			m.player.z = m.hill.south_marks.P.y
			if sc.has("water"):
				m.mill_q = 4
				m.hill.fill()
				m.player.x = Main.HILL.HILL_X + 20.0
				m.player.z = 32.0
			m.snap_mates()
		if sc.get("road", false): # Hangyeol's yard below the garden, at his camp, the roots unwound
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.hill_q = 3
			m.castle_q = 3
			m.hollow_q = 4
			m.join_mate()
			m.join_noeul()
			m.road_q = 2
			m.enter_garden()
			m.close_story()
			m.player.x = m.garden.road_marks.k.x - 2.0
			m.player.z = m.garden.road_marks.k.y + 1.0
			m.garden.reveal(true)
			if sc.has("echo"): # the brick Hangyeol risen in his yard
				m.road_q = 3
				m.spawn_knight(true)
				m.player.x = m.garden.road_marks.X.x - 1.0
				m.player.z = m.garden.road_marks.X.y + 3.0
			m.snap_mates()
		if sc.get("clock", false): # the clock room after the ending, gears still hard; "wind": the crown in, all at a spoke
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.hill_q = 3
			m.castle_q = 3
			m.hollow_q = 4
			m.road_q = 4
			m.join_mate()
			m.join_noeul()
			m.garden_q = 5
			m.story_step = 12
			m.clock_q = 2
			if sc.has("wind"):
				m.clock_q = 4
				m.clock_gears = [true, true, true]
			m.enter_garden()
			m.close_story()
			m.garden.clock_look(m.clock_q, m.clock_gears, m.clock_box)
			m.player.x = 243.0
			m.player.z = 58.0
			m.garden_zone.clock_zone()
			if sc.has("wind"):
				var j := m.hand_spot(0)
				m.player.x = j.x
				m.player.z = j.y
			m.snap_mates()
		if sc.get("mold", false): # the last boss in the heart of the garden
			m.night_q = 4
			m.forest_q = 3
			m.garden_q = 1
			m.enter_garden()
			m.garden_q = 2
			m.garden_zone.spawn_mold()
			m.player.x = m.garden.marks.C.x - 4.5
			m.player.z = m.garden.marks.C.y + 1.5
		if sc.get("turtle", false): # Sora and Mulgyeol against the brick turtle on the island
			m.night_q = 4
			m.lake_q = 1
			m.enter_lake()
			m.lake.thaw()
			m.lake_q = 2
			m.lake_zone.row_to_island()
			m.close_story()
			m.lake_zone.spawn_turtle()
			m.player.x = m.lake.marks.T.x + 2.5
			m.player.z = m.lake.marks.T.y + 1.0
			m.snap_mate()
			if sc.has("steps"):
				for e in m.enemies:
					if e.get("turtle", false):
						e.dead = true
						e.node.visible = false
						e.shadow.visible = false
				m.ui.boss.visible = false
				m.player.x = m.lake.marks.G.x + 1.5
				m.player.z = m.lake.marks.G.y - 1.5
		if sc.get("lake_south", false): # the island's south tip, the weir ahead; "pond": the stones up, by R2; "spring": the yard
			m.night_q = 4
			m.lake_q = 4
			m.enter_lake()
			m.lake.thaw()
			m.join_mate()
			m.close_story()
			m.south_hint_seen = true
			m.player.x = 284.0
			m.player.z = 22.0
			if sc.has("pond"):
				m.south_q = 2
				m.player.x = 286.0
				m.player.z = 31.0
			if sc.has("spring"):
				m.south_q = 3
				m.player.x = 294.0
				m.player.z = 33.0
			m.lake.south_look(m.south_q)
			m.ui.mini.map_tex = m.lake_zone.lake_map()
			m.snap_mate()
		if sc.get("crab", false): # the brick crab in the grotto under the island, Mulgyeol along
			m.night_q = 4
			m.lake_q = 4
			m.enter_lake()
			m.lake.thaw()
			m.join_mate()
			m.has_skip = true
			m.enter_grotto()
			m.close_story()
			m.grotto_q = 2
			m.lake_zone.spawn_crab()
			m.player.x = m.grotto.marks.C.x + 4.0
			m.player.z = m.grotto.marks.C.y + 1.5
			if sc.has("grotto_in"): # the entry room, at night, by the steps up
				for e in m.enemies:
					if e.get("crab", false):
						e.dead = true
						e.node.visible = false
						e.shadow.visible = false
				m.ui.boss.visible = false
				m.player.x = m.grotto.marks.S.x + 2.0
				m.player.z = m.grotto.marks.S.y + 1.0
			m.snap_mate()
		if sc.get("hill", false): # the wind hills, one mill turning, Mulgyeol and Noeul along
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.join_mate()
			m.join_noeul()
			m.enter_hill()
			m.close_story()
			m.hill.wind_mill(m.hill.mills[0], m)
			m.player.x = m.hill.mills[0].pos.x + 2.5
			m.player.z = m.hill.mills[0].pos.y + 2.0
			m.snap_mates()
			if sc.has("race"):
				m.player.x = Main.HILL.HILL_X + Main.RACE_POST.x + 1.0
				m.player.z = Main.RACE_POST.y
				m.minigames.race_key()
				m.player.x = Main.HILL.HILL_X + 6.0
				m.player.z = 16.5
				m.snap_mates()
		if sc.get("cloud", false): # the cloud mound above the hill, mates along; with "scare" the scarecrow is up
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.hill_q = 3
			m.join_mate()
			m.join_noeul()
			m.enter_hill()
			m.close_story()
			m.enter_cloud()
			m.close_story()
			m.player.x = Main.CLOUD.CLOUD_X + 3.0
			m.player.z = 10.0
			if sc.has("path"):
				m.player.z = 12.0
				m.cloud.reveal_t = 30.0
				m.cloud.reveal(true)
			if sc.has("scare"):
				m.cloud_q = 2
				m.hill_zone.spawn_scarecrow()
				m.player.x = m.cloud.marks.K.x - 3.0
				m.player.z = m.cloud.marks.K.y + 1.5
			m.snap_mates()
		if sc.get("castle", false): # the sunken castle's great hall; with "knight" the throne room fight
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.hill_q = 3
			m.has_skip = true
			m.join_mate()
			m.join_noeul()
			m.enter_castle()
			m.close_story()
			m.castle.open_gate()
			m.player.x = Main.CASTLE.CASTLE_X + 18.0
			m.player.z = 12.0
			if sc.has("knight"):
				for pg in m.castle.pages:
					pg.read = true
				m.castle.open_door()
				m.castle_q = 2
				m.spawn_knight()
				m.player.x = m.castle.marks.K.x - 3.5
				m.player.z = m.castle.marks.K.y + 1.0
			m.set_quest(m.castle_zone.castle_quest())
			if sc.has("quarters"): # 달지기 숙소 (DESIGN.md): 2 the dining hall, 3 the doorkeeper walking, 5 he rests
				m.castle_q = 3
				for pg in m.castle.pages:
					pg.read = true
				m.castle.open_door()
				m.load_quarters({"quarters_q": int(sc.quarters)})
				m.quarters_spawned = true
				m.set_quest("동쪽 문을 지나 정원 한가운데로 가자")
				m.player.x = 452.0
				m.player.z = 30.0
				if m.quarters_q == 2:
					m.castle_zone.spawn_quarter_foes()
				elif m.quarters_q == 3: # held still for the shot: the doorkeeper in the dining hall, the bits on their way
					m.doll_at = Vector2(458.5, 31.7)
					m.doll_i = 6
					m.doll_shed = true
					m.castle.doll_place(m.doll_at, Vector2(1, 0.4))
					m.castle_zone.shed_doll_bits()
					for e in m.doll_bits():
						e.x = lerpf(e.x, m.doll_at.x, 0.45)
						e.z = lerpf(e.z, m.doll_at.y, 0.45)
						e.stun = 99.0
					m.player.x = 456.0
					m.player.z = 32.5
					m.player.inv = 99.0
				elif m.quarters_q >= 5:
					m.player.x = 460.6
					m.player.z = 36.6
			if sc.has("under_in"): # just down the stair: the way back up beside her
				m.castle_q = 3
				m.enter_under()
				m.close_story()
			if sc.has("workshop"): # 달지기 작업장: a floor in the state named in SCENES
				var wi: int = int(sc.workshop) - 1
				m.castle_q = 3
				m.has_unbrick = true
				m.work_door = true
				m.work_seen = true
				var wd: Dictionary = [{"work_q": 1, "work_lamps": [true, true]},
					{"work_q": 2, "work_pulled": true, "work_ways": [true, false, false]},
					{"work_q": 4, "work_cradle": true, "work_ways": [true, true, true], "work_latch": [true, false, false]}][wi]
				wd["work_floor"] = wi + 1
				m.workshop_zone.load_work(wd)
				m.workshop_zone.enter_floor(wi, "A")
				m.close_story()
				var wx: float = Main.WORK.FLOOR_X[wi]
				m.player.x = wx + [18.0, 8.0, 10.0][wi]
				m.player.z = [7.6, 9.0, 14.0][wi]
				m.snap_mates()
			if sc.has("under"): # the lamp hall below the castle, the plug pulled
				m.castle_q = 3
				m.has_unbrick = true
				m.enter_under()
				m.close_story()
				m.under.drain()
				m.castle_zone.under_goal_toast(8.0)
				m.player.x = Main.UNDER.UNDER_X + 6.0
				m.player.z = 16.5
			if sc.has("stairs"):
				m.castle_q = 3
				m.enter_stairs()
				m.close_story()
				# stairs_at picks the landing to stand on: 0 the foot (wall shut), 1 the channel, 2 the drop, 3 the top
				var land: int = int(sc.get("stairs_at", 1))
				if land >= 1:
					m.stairs.open_wall()
				m.player.x = Main.STAIRS.STAIRS_X + 9.0
				m.player.z = [26.5, 20.5, 12.5, 4.5][land]
				m.set_quest(m.castle_zone.stairs_quest())
			m.snap_mates()
		if sc.get("trial", false): # the moon trial's third wave, wolves around the stone ring on the wind hills
			m.night_q = 4
			m.lake_q = 4
			m.forest_q = 3
			m.hill_q = 3
			m.enter_hill()
			m.close_story()
			m.player.x = m.hill.marks.R.x + 1.5
			m.player.z = m.hill.marks.R.y - 0.5
			m.trial_wave = 3
			m.trial_start = m.t
			m.minigames.spawn_trial_wave()
		if sc.get("sleep", false): # after dark: the villagers have gone in; Doran sleeps in his house
			m.update_folk_sleep(0.0)
			m.enter_house(m.folk_home("doran"))
			m.player.x = Main.HOUSE_X + 3.6
			m.player.z = 2.8
			m.update_folk_sleep(0.0)
		if sc.has("sleep_drafts"): # a night room with five sleeper drafts in a row; 1..5 is a close shot of one of them
			var sd := preload("res://sys/sleep_drafts.gd").new(m)
			var focus: int = int(sc.sleep_drafts) - 1
			var look: Vector3 = sd.build(Vector2(Main.HOUSE_X + 70.0, 60.0), focus)
			m.player.x = look.x
			m.player.z = look.z
			m.ground_y = 0.0
			m.cam_dist = 14.0 if focus < 0 else 7.5
			m.hero.visible = false
			m.hero_shadow.visible = false
			m.cfg.tilt = false # no blur: the drafts sit at the edge of the sharp band
			m.apply_settings()
			m.close_story()
		if sc.get("house", false): # inside the last village house
			m.enter_house(4)
			m.player.x = Main.HOUSE_X + 5.5
			m.player.z = 2.5
		if sc.get("festival", false): # the lantern festival on a full-moon night
			m.mail_got = [true, true, true]
			m.errand = 3
		if sc.get("kid", false): # Kongal's kid goblin trotting after Sora in the south field
			m.errand = 3
			m.player.x = Main.VILLAGE.VILLAGE_X + 9.0
			m.player.z = 19.0
			m.kid_q = 2
			m.place_kid()
	if sc.get("scene", false):
		m.show_story("res://art/story/06_cave_rival.jpg", Main.STORY.PAINTING)
		for k in 6:
			m.story.next_story()
	if sc.get("mole", false):
		m.story_step = 5
		m.enter_cave()
		m.player.x = m.cave_marks.B.x - 4.0
		m.player.z = m.cave_marks.B.y
	if sc.get("talk", false):
		m.story_step = 3
		m.show_story("", Main.STORY.BORI)
		for k in 2: # stop on a spoken line (Bori knows the crown) so her portrait is lit, not a narration line that dims both
			m.story.next_story()
			m.story.next_story()
	if sc.get("cave_in", false):
		m.story_step = 5
		m.enter_cave()
		m.player.x += 2.0
	if sc.get("post", false): # the stream's end below the mole's hall, the islands' pool ahead
		m.story_step = 7
		m.has_skip = true
		m.enter_cave()
		m.close_story()
		m.post_q = 1
		m.post_spawned = true
		m.player.x = Main.CAVE_X + 12.0
		m.player.z = 30.0
	if sc.get("cave", false):
		for e in m.enemies:
			if e.get("boss", false):
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
				m.ui.boss.visible = false
				m.open_cave(Vector2(e.x, e.z))
				m.player.x = e.x
				m.player.z = e.z + 3.5
		m.close_story()
	if sc.get("shrine", false): # the shrine of three stones under the cave, the whirl woken
		m.enter_cave()
		m.close_story()
		m.shrine_seen = true
		m.skill_up = 0
		m.player.x = Main.CAVE_X + 8.0
		m.player.z = 18.6
	if sc.get("journal", false): # the journal mid-game: two map scraps, the firefly errand on, the whirl woken
		m.story_step = 8
		m.errand = 3
		m.kid_q = 3
		m.doran_q = 3
		m.fly_q = 1
		m.has_skip = true
		m.shrine_seen = true
		m.skill_up = 0
		m.marsh.found = [true, false, true]
		m.set_quest(Main.NIGHT_REST_QUEST)
		m.toggle_journal(true)
	if sc.get("ways", false): # the waystone list by Bori's cottage
		m.story_step = 9
		m.lake_q = 1
		var w0 := m.way_spot(0)
		m.player.x = w0.x + 0.8
		m.player.z = w0.y + 1.4
		m.waystones.toggle_ways(true)
	if sc.get("walk_dr", false): # walking toward the bottom right of the screen (5 o'clock)
		m.fake_keys[KEY_S] = true
		m.fake_keys[KEY_D] = true
	if sc.has("text"): # a text size step (0 - 3)
		m.cfg.text = int(sc.text)
		m.apply_settings()
	if sc.get("controls", false):
		m.toggle_help(true)
	if sc.get("settings", false):
		m.toggle_settings(true)
		if sc.has("set_tab"):
			m.show_set_tab(int(sc.set_tab))
		if sc.has("sound_off"):
			m.muted = true
		if sc.has("music_off"):
			m.music_on = false
		m.apply_settings()
	if sc.get("far", false): # zoomed all the way out, to judge the haze
		m.cam_dist = 26.0
	if sc.get("folk6", false): # far enough out to see all six
		m.cam_dist = 24.0
	if sc.get("folk_day", false): # 30 s into their day rounds
		for id in Main.FOLK_ROUTES:
			m.folk_route_state(id).wait = randf_range(0.0, 4.0)
		for k in 300:
			m.update_folk_sleep(0.1)
	if sc.get("swing", false): # a swing caught mid-sweep, just before the picture at 4 s
		m.cam_dist = 11.0
		m.player.face = Vector2(1, 0)
		m.get_tree().create_timer(3.86).timeout.connect(func(): m.player.atk_cd = 0.0; m.attack())
	if sc.get("hush", false): # the sound switched off: a finger to her lips, held for the picture
		m.get_tree().create_timer(1.5).timeout.connect(func():
			m.muted = false
			m.toggle_sound()
			m.idle_left = 60.0)
	if sc.get("opening", false):
		m.begin_opening()
	if sc.has("fall"):
		m.get_tree().create_timer(sc.fall).timeout.connect(func(): m.player.inv = 0.0; m.hurt_player(9999, m.ground_y))
	if sc.has("chat"): # companions trading a line in balloons
		m.join_mate()
		m.join_noeul()
		m.snap_mates()
		m.get_tree().create_timer(1.0).timeout.connect(func(): m.say_bubble(m.mate, "다리 아파. 좀 쉬었다 가자."); m.say_bubble(m.mate2, "……뭘 봐. 그냥 쉬는 거야."))
	if sc.has("noeul_sit"):
		m.join_noeul()
		m.join_mate()
		m.snap_mates()
		m.last_input_t = -100.0
		for e in m.enemies: # no monster within 7 tiles, or he would not sit
			if not e.get("boss", false) and not e.get("prop", false):
				e.x = 2.0
				e.z = 2.0
	if sc.has("folk_talk"):
		var dp := m.folk_chat_at("doran")
		m.player.x = dp.x + 1.6
		m.player.z = dp.y + 0.8
		m.get_tree().create_timer(2.0).timeout.connect(func(): m.chatter.folk_say("doran", "문 앞에선 발소리부터 줄이는 법이오."))
	if sc.has("folk_line"): # the heights side by side: fresh sprites from the same maker as the villagers' (folk_sprite)
		var vx := float(Main.VILLAGE.VILLAGE_X)
		m.join_noeul()
		var ids := ["noeul", "mulgyeol", "doran", "kongal", "dusol", "chadol", "saecham", "yeoul", "darae", "tori", "simji", "kid"]
		var names := {"noeul": "노을", "mulgyeol": "물결", "doran": "도란", "kongal": "콩알", "dusol": "두솔", "chadol": "차돌", "saecham": "새참", "yeoul": "여울", "darae": "다래", "tori": "토리", "simji": "심지", "kid": "꼬마"}
		var right := Vector2(cos(m.cam_yaw), -sin(m.cam_yaw)) # along the screen's horizontal, so the row reads level
		var o := Vector2(vx + 19.0, 10.5) - right * 0.95 * ids.size() / 2.0
		var sora_at := o + right * 0.95 * (ids.size() / 2.0 + 0.5) + Vector2(sin(m.cam_yaw), cos(m.cam_yaw)) * 1.5 # in the middle, a step nearer the camera
		m.player.x = sora_at.x
		m.player.z = sora_at.y
		m.mate2.position = Vector3(-50, 0, -50) # Noeul stands in the row below instead of by her side
		for i in ids.size():
			var spr: Sprite3D
			if ids[i] == "noeul":
				spr = m.village_life.noeul_sprite()
			else:
				spr = m.folk_sprite(ids[i])
			var sp := o + right * 0.95 * (i + 1)
			spr.position = Vector3(sp.x, 0, sp.y)
			spr.flip_h = true
			m.add_child(spr)
			var nm := Label3D.new()
			nm.text = names[ids[i]]
			nm.font = m.ui_font
			nm.font_size = 36
			nm.pixel_size = 0.008
			nm.outline_size = 12
			nm.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			nm.no_depth_test = true
			nm.position = Vector3(sp.x, -0.1, sp.y)
			m.add_child(nm)
	if sc.has("quest_narrow"):
		m.join_mate()
		m.join_noeul()
		m.snap_mates()
		var root: Window = m.get_tree().root
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(645, 480)
		m.set_quest("동쪽 출구로 나가자 (E). 길을 막은 회색 나무는 팔찌로 하나씩 풀 수 있다")
	if sc.has("story_pad"):
		var root: Window = m.get_tree().root
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(645, 480)
		m.get_tree().create_timer(1.0).timeout.connect(func(): m.show_story("", ["|-|달지기 책 1/5"]); m.ui.story_text.visible_characters = -1)
	if sc.has("pips12"):
		m.pip_max = 12
		m.crown_pips = 10
	if sc.has("faint"):
		m.get_tree().create_timer(sc.faint).timeout.connect(m.faint)
	m.hour = float(opt.get("hour", sc.get("hour", m.hour)))
	m.day = int(opt.get("day", sc.get("day", m.day)))
	if opt.has("test"):
		var runner := Node.new()
		runner.set_script(load("res://tools/autoplay.gd"))
		runner.main = m
		runner.only = opt.test
		m.add_child(runner)
	if opt.has("sounds"):
		load("res://tools/autoplay.gd").sound_report(m, opt.sounds)
		m.get_tree().quit()
	if opt.has("shot"):
		var path: String = opt.shot if opt.shot != "" else "res://shot.png"
		m.get_tree().create_timer(float(opt.get("wait", "4"))).timeout.connect(func():
			m.get_viewport().get_texture().get_image().save_png(path)
			print("SHOT ", path)
			m.get_tree().quit())
