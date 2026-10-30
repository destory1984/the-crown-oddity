# Save and load (user://save.json), old-save repair, reset.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const OLD_CAVE_QUEST := "땅 아래로 가는 동굴이 열렸다"
const OLD_QUEST_WORDS := [["끝. 다시 돌기 시작한 정원을 거닐자 (정원 한가운데서 E 두 번: 새 바퀴)", "이야기 끝 · 정원을 마음껏 둘러보자"], ["왕관 단추", "팔찌 단추"], ["왕관을 만져 보자", "팔목의 팔찌를 만져 보자"], ["왕관으로", "팔찌로"], ["왕관을 대", "팔찌를 대"], ["왕관을 높이 들어", "두 팔을 높이 들어"]]

func _init(main: Main) -> void:
	m = main

func save_game() -> void:
	if m.intro or m.down_t > 0.0 or m.player.hp <= 0.0: # fallen: the faint puts her back first (GPT playtests 2 -> 9)
		return
	var boss_dead := false
	for e in m.enemies:
		if e.get("boss", false) and e.dead:
			boss_dead = true
	var d := {"lv": m.player.lv, "xp": m.player.xp, "max_hp": m.player.max_hp, "hp": m.player.hp, "atk": m.player.atk,
		"gold": m.player.gold, "pots": m.player.pots, "x": m.player.x, "z": m.player.z,
		"story": m.story_step, "quest": (m.hill_zone.retry_quest() if m.mill_q == 2 else m.windrun_quest) if m.windrun_on else (m.race_quest if m.race_on else m.quest_raw), "boss_dead": boss_dead, "in_cave": m.in_cave, "in_village": m.in_village, "met": m.met.keys(), "pips": m.crown_pips, "errand": m.errand, "kid_q": m.kid_q, "doran_q": m.doran_q, "mul_q": m.mul_q, "night_q": m.night_q, "in_forest": m.in_forest, "in_garden": m.in_garden, "in_hill": m.in_hill, "hill_q": m.hill_q, "mills": m.hill.mills.map(func(mm): return mm.turning), "in_lake": m.in_lake, "lake_q": m.lake_q, "garden_q": m.garden_q, "forest_q": m.forest_q, "walls": m.forest.walls.map(func(w): return w.open), "stones": m.forest.stones.map(func(st): return st.phase), "grove": m.forest.solved, "grove_chest": m.forest.chest_open, "has_unbrick": m.has_unbrick, "vlit": m.village.dark.map(func(d): return d.lit), "cave_exit_seen": m.cave_exit_seen, "has_skip": m.has_skip, "has_key": m.has_key, "cave_at": [m.cave_pos.x, m.cave_pos.y], "door_open": m.cave_door_open, "saw_painting": m.saw_painting, "hour": m.hour, "day": m.day,
		"chests": m.chests.map(func(c): return c.open), "scraps": m.marsh.found, "moon_chest": m.marsh.chest_open,
		"fly_q": m.fly_q, "flies": m.marsh.flies.map(func(f): return f.caught),
		"grotto_q": m.grotto_q, "grotto_side": m.grotto_side, "has_pearl": m.has_pearl,
		"cloud_q": m.cloud_q, "cloud_chest": m.cloud_chest, "has_feather": m.has_feather,
		"woke": m.woke, "crystal_done": m.crystal_done, "has_ring": m.has_ring, "freed": m.forest.freed, "has_acorn": m.has_acorn, "shrine_seen": m.shrine_seen, "trial_best": m.trial_best, "race_best": m.race_best, "books": m.castle.books.map(func(b): return b.read), "book_pages": m.castle.books.map(func(b): return int(b.get("page", 0))), "has_bookmark": m.has_bookmark, "has_shard": m.has_shard, "shop_bought": m.shop_bought, "play_secs": m.play_secs, "ng": m.ng, "fest_gift": m.fest_gift, "mail_q": m.mail_q, "mail_got": m.mail_got, "stats": m.stats, "feats": m.feats_done, "houses": m.house_seen, "flowers": m.marsh.picked, "has_tea": m.has_tea, "fish": m.fish_kinds, "has_shoes": m.has_shoes, "target_best": m.target_best, "has_medal": m.has_medal, "bottles": m.village.bottles.map(func(b): return b.got), "inn_nights": m.inn_nights, "inn_side": m.market.inn_side, "inn_streak": m.market.inn_streak, "magpie_q": m.magpie_q, "talks_heard": m.talks_heard.keys(),
		"road_q": m.road_q, "road_box": m.road_box, "mill_q": m.mill_q, "has_oar_ring": m.has_oar_ring, "post_q": m.post_q, "south_q": m.south_q, "has_whistle": m.has_whistle, "clock_q": m.clock_q, "clock_gears": m.clock_gears, "clock_box": m.clock_box, "clock_late": m.clock_late, "has_oil": m.has_oil, "shore_q": m.shore_q, "has_cushion": m.has_cushion, "hf_seen": m.hf_seen, "has_bait": m.has_bait, "hollow_q": m.hollow_q, "mem_lit": m.forest.mem_lamps.map(func(l): return l.lit), "hollow_doors": m.forest.doors.map(func(dr): return dr.open), "hollow_boxes": m.forest.boxes.map(func(b): return b.open),
		"seals": m.garden.seals.map(func(sl): return sl.open),
		"stairs_wall": m.stairs.wall_open, "stairs_lamps": m.stairs.lamps.map(func(l): return l.lit),
		"castle_q": m.castle_q, "bars": m.castle.bars, "levers": m.castle.levers.map(func(lv): return lv.up), "vault": m.castle.vault_open, "has_armour": m.has_armour, "castle_gate": m.castle.gate_open, "castle_pages": m.castle.pages.map(func(pg): return pg.read),
		"doll_at": [m.doll_at.x, m.doll_at.y], "doll_i": m.doll_i, "doll_raid": (m.doll_shed and m.doll_bits().is_empty()) or m.doll_keep_shed, # keep_shed: a loaded beaten raid not yet resumed
		"quarters_q": m.quarters_q, "quarters_box": m.quarters_box, "has_buckler": m.has_buckler, "quarters_again": m.quarters_again,
		"oak_q": m.oak_q, "oak_knots": m.forest.knots.map(func(k): return k.open), "has_sprout": m.has_sprout, "oak_hogs": m.oak_hogs_beaten, "letter_back": m.letter_back,
		"under_drained": m.under.drained, "under_door": m.under.door_open, "under_guards": m.under_guards_done, "under_chest": m.under_chest_open,
		"under_side": m.under_side_open, "under_diary": m.under_diary_read, "has_lamp": m.has_lamp, "cave_quest": m.quest_before_cave,
		"pip_max": m.pip_max, "pip_awards": m.pip_awards.keys(), "tokens": m.tokens, "trial_won": m.trial_won, "stairs_seen": m.stairs_seen, "moon_door": m.castle.door_open}
	d.merge(m.football.save_data())
	d.merge(m.workshop_zone.save_data())
	d.merge(m.corridor_zone.save_data())
	d["saved_at"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(m.SAVE_PATH, FileAccess.WRITE)
	var ok := false
	if f:
		ok = f.store_string(JSON.stringify(d))
		f.flush()
		ok = ok and f.get_error() == OK
		f.close()
	save_done(ok)

# The little gear at the screen's corner turns once only when the file was written without an error, and the time is kept
# for the journal's last line; a failed write says so plainly and shows no gear (delight idea 87).
var last_save_text := ""
var save_turns := 0 # gears turned (autoplay d87_save_gear)
var save_fails := 0
var gear_tw: Tween

func save_done(ok: bool) -> void:
	if not ok:
		save_fails += 1
		m.toast("저장하지 못했다")
		return
	var tm := Time.get_time_dict_from_system()
	last_save_text = "%02d:%02d" % [tm.hour, tm.minute]
	save_turns += 1
	var gear: Control = m.ui.get("save_gear")
	if gear == null:
		return
	if gear_tw != null and gear_tw.is_valid():
		gear_tw.kill() # a second save restarts the turn from the start
	gear.modulate.a = 0.9
	gear.rotation = 0.0
	gear_tw = gear.create_tween()
	gear_tw.tween_property(gear, "rotation", TAU, 0.7).set_trans(Tween.TRANS_SINE)
	gear_tw.tween_interval(1.5)
	gear_tw.tween_property(gear, "modulate:a", 0.0, 0.8)

func load_game() -> void:
	if not FileAccess.file_exists(m.SAVE_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(m.SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	m.loaded = true
	m.menus.recap_from_save(float(d.get("saved_at", 0.0))) # a long break brings the short recap first (idea 81)
	for k in ["lv", "xp", "max_hp", "atk", "gold", "pots"]:
		m.player[k] = int(d.get(k, m.player[k]))
	m.player.hp = float(d.get("hp", m.player.max_hp))
	if m.player.hp <= 0.0: # an older save made in the frame she fell: she wakes healed, as after a faint
		m.player.hp = float(m.player.max_hp)
	m.player.x = float(d.get("x", m.player.x))
	m.player.z = float(d.get("z", m.player.z))
	m.ground_y = m.height_at(m.player.x, m.player.z)
	m.hour = float(d.get("hour", m.hour))
	m.day = int(d.get("day", m.day))
	m.story_step = int(d.get("story", 0))
	var was_in_cave := bool(d.get("in_cave", false))
	m.load_pips(d)
	m.errand = int(d.get("errand", 0))
	m.kid_q = int(d.get("kid_q", 0))
	m.doran_q = int(d.get("doran_q", 0))
	m.mul_q = int(d.get("mul_q", 0))
	m.night_q = int(d.get("night_q", 0))
	m.letter_back = bool(d.get("letter_back", m.night_q >= 3)) # older saves past the lantern night: given then
	m.forest_q = int(d.get("forest_q", 0))
	m.hollow_q = int(d.get("hollow_q", 0))
	m.garden_q = int(d.get("garden_q", 0))
	m.hill_q = int(d.get("hill_q", 0))
	var ms: Array = d.get("mills", [])
	for i in mini(ms.size(), m.hill.mills.size()):
		if ms[i]:
			m.hill.wind_mill(m.hill.mills[i], m)
	if m.hill_q >= 2:
		m.hill.raise_bridge()
	if m.forest_q >= 3:
		m.join_noeul()
	m.lake_q = int(d.get("lake_q", 0))
	var turtle_cut := m.lake_q == 3
	if m.lake_q == 3:
		m.lake_q = 2 # the turtle fight starts over from the pier
	if m.lake_q >= 2:
		m.lake.thaw()
	m.south_q = int(d.get("south_q", 0)) # old saves: the weir is still shut
	m.has_whistle = bool(d.get("has_whistle", false))
	m.corridor_zone.load_data(d) # the water corridor (v0.1.84); an old save past the forest comes in as done
	m.lake.south_look(m.south_q)
	m.clear_south_job()
	if m.lake_q >= 4:
		m.join_mate()
	var garden_cut := m.garden_q >= 2 and m.garden_q < 5
	if garden_cut:
		m.garden_q = 1 # the mold fight starts over when she walks back in
	var ph: Array = d.get("stones", [])
	for i in mini(ph.size(), m.forest.stones.size()):
		m.forest.stones[i].phase = int(ph[i])
		m.forest.show_phase(m.forest.stones[i])
	if bool(d.get("grove", false)):
		m.forest.open_gate()
	if bool(d.get("grove_chest", false)):
		m.forest.open_chest_look()
	var wo: Array = d.get("walls", [])
	for i in mini(wo.size(), m.forest.walls.size()):
		if wo[i]:
			m.forest.open_wall(m.forest.walls[i])
	if m.hollow_q >= 1:
		m.forest.open_gate_look()
	var ml: Array = d.get("mem_lit", [])
	for i in mini(ml.size(), m.forest.mem_lamps.size()):
		if ml[i]:
			m.forest.light_mem(m.forest.mem_lamps[i])
	var hd: Array = d.get("hollow_doors", [])
	for i in mini(hd.size(), m.forest.doors.size()):
		if hd[i]:
			m.forest.open_door(m.forest.doors[i])
	var hb: Array = d.get("hollow_boxes", [])
	for i in mini(hb.size(), m.forest.boxes.size()):
		if hb[i]:
			m.forest.open_box_look(m.forest.boxes[i])
	if m.hollow_q >= 4:
		m.forest_zone.hang_thirteenth()
	if m.forest_q == 2:
		m.forest_q = 1 # the duel starts over when she walks back to the clearing
	m.has_unbrick = bool(d.get("has_unbrick", false))
	var chase_cut := m.night_q == 1 or m.night_q == 2
	if chase_cut:
		m.night_q = 0 # a chase cut short by quitting starts over the next night
	if m.night_q == 3:
		m.village_life.spawn_noeul_duel()
	if m.mul_q == 1:
		m.errands.place_oar()
	for id in d.get("met", []):
		m.met[id] = true
	m.hf_seen = {} # the six working villagers' beats told (old saves: none)
	var hfs: Dictionary = d.get("hf_seen", {})
	for id in hfs:
		m.hf_seen[id] = (hfs[id] as Array).map(func(v): return int(v))
	m.has_bait = bool(d.get("has_bait", false))
	var vlit: Array = d.get("vlit", [])
	for i in mini(vlit.size(), m.village.dark.size()):
		if vlit[i]:
			var vd: Dictionary = m.village.dark[i]
			vd.lit = true
			vd.light.set_meta("dark", false)
			vd.glass.material_override = vd.glass.get_meta("lit_mat")
	if bool(d.get("in_village", false)):
		var vx: float = m.player.x
		var vz: float = m.player.z
		if vx >= Main.VILLAGE.OLD_X - 0.5 and vx < Main.VILLAGE.OLD_X + 40.0:
			vx += Main.VILLAGE.VILLAGE_X - Main.VILLAGE.OLD_X
		if vx >= Main.HOUSE_X - 0.5 and vx < Main.HOUSE_X + 10.0: # saved inside a house: wake on the square instead
			vx = m.village.marks.M.x - 2.0
			vz = m.village.marks.M.y + 1.0
		var e0 := m.errand
		m.errand = maxi(m.errand, 1) # do not replay the arrival scene
		m.enter_village()
		m.errand = e0
		m.player.x = vx
		m.player.z = vz
		if m.kid_q > 0:
			m.place_kid()
	if m.kid_q > 0 and m.kid_node == null: # saved outside the village: the kid still waits there (it was gone, and Kongal's errand could not end)
		m.place_kid()
		if m.kid_q == 2:
			m.kid_node.position = Vector3(m.village.marks.S.x - 0.8, 0, m.village.marks.S.y + 0.4)
	m.grotto_q = int(d.get("grotto_q", 0))
	if m.grotto_q == 2:
		m.grotto_q = 1 # the crab fight starts over when she walks back into the last room
	m.has_pearl = bool(d.get("has_pearl", false))
	m.grotto_side = bool(d.get("grotto_side", false))
	if m.grotto_side:
		m.grotto.opened_look(m.grotto.side_chest)
	if m.grotto_q >= 3:
		m.grotto.chest.visible = true
	if m.grotto_q >= 4:
		m.grotto.opened_look(m.grotto.chest)
	if bool(d.get("in_lake", false)):
		var lx: float = m.player.x
		var lz: float = m.player.z
		m.enter_lake()
		if lx >= Main.CORR.CORR_X - 0.5: # saved in the water corridor: back at the last room's stair, friends beside her
			m.corridor_zone.restore_at(m.corr_check)
			lx = m.player.x
			lz = m.player.z
		elif lx >= Main.GROTTO.GROTTO_X - 0.5:
			m.enter_grotto()
		m.player.x = lx
		m.player.z = lz
		if m.south_q == 2 and m.lake_zone.in_south_yard(Vector2(lx, lz)): # saved in the yard mid-ambush: outside the grate again
			m.player.x = 289.0
			m.player.z = 31.0
		if turtle_cut: # saved on the island mid-fight: back to the pier, where Mulgyeol rows again
			m.player.x = m.lake.marks.P.x
			m.player.z = m.lake.marks.P.y - 1.0
		m.snap_mate()
		if m.in_corridor(): # the snap above took Mulgyeol off his far post: the corridor puts the work's roles back (v0.1.91)
			m.corridor_zone.settle(m.corridor.room_of(m.player.x))
	m.cloud_q = int(d.get("cloud_q", 0))
	if m.cloud_q == 2:
		m.cloud_q = 1 # the scarecrow fight starts over when she walks back onto its island
	m.cloud_chest = bool(d.get("cloud_chest", false))
	if m.cloud_chest:
		m.cloud.opened_look()
	m.has_feather = bool(d.get("has_feather", false))
	var wk = d.get("woke", null)
	if wk is Array and wk.size() == 3:
		m.woke = wk.map(func(v): return bool(v))
	else: # a save from before v0.1.46 kept one woken skill as an index
		var su := int(d.get("skill_up", -1))
		m.woke = [su == 0, su == 1, su == 2]
	m.crystal_done = bool(d.get("crystal_done", false))
	m.has_ring = bool(d.get("has_ring", false))
	m.crystal_chest.visible = m.crystal_done and not m.has_ring
	var fr: Array = d.get("freed", [])
	for i in mini(fr.size(), m.forest.freed.size()):
		m.forest.freed[i] = bool(fr[i])
	m.has_acorn = bool(d.get("has_acorn", false))
	m.trial_best = float(d.get("trial_best", 0.0))
	m.trial_won = bool(d.get("trial_won", m.trial_best > 0.0)) # a save from before v0.1.68: any clear counts (a new round writes false)
	m.stairs_seen = bool(d.get("stairs_seen", bool(d.get("stairs_wall", false)) or int(d.get("garden_q", 0)) >= 1))
	m.race_best = float(d.get("race_best", 0.0))
	var bks: Array = d.get("books", [])
	for i in mini(bks.size(), m.castle.books.size()):
		m.castle.books[i].read = bool(bks[i])
	var bpg: Array = d.get("book_pages", [])
	for i in mini(bpg.size(), m.castle.books.size()):
		m.castle.books[i].page = int(bpg[i])
	m.has_bookmark = bool(d.get("has_bookmark", false))
	m.has_shard = bool(d.get("has_shard", false))
	if m.has_shard:
		m.cloud.shard_look()
	var sb: Array = d.get("shop_bought", [])
	for i in mini(sb.size(), m.shop_bought.size()):
		m.shop_bought[i] = int(sb[i])
	m.play_secs = float(d.get("play_secs", 0.0))
	m.football.load_data(d)
	m.ng = int(d.get("ng", 0))
	m.fest_gift = bool(d.get("fest_gift", false))
	m.mail_q = int(d.get("mail_q", 0))
	var mg: Array = d.get("mail_got", [])
	for i in mini(mg.size(), m.mail_got.size()):
		m.mail_got[i] = bool(mg[i])
	var st: Dictionary = d.get("stats", {})
	for k in m.stats:
		m.stats[k] = int(st.get(k, 0))
	var fd: Array = d.get("feats", [])
	for i in mini(fd.size(), m.feats_done.size()):
		m.feats_done[i] = bool(fd[i])
	var hs: Array = d.get("houses", [])
	for i in mini(hs.size(), m.house_seen.size()):
		m.house_seen[i] = bool(hs[i])
	var fl: Array = d.get("flowers", [])
	for i in mini(fl.size(), m.marsh.picked.size()):
		m.marsh.picked[i] = bool(fl[i])
	m.has_tea = bool(d.get("has_tea", false))
	m.target_best = int(d.get("target_best", 0))
	m.has_medal = bool(d.get("has_medal", false))
	m.inn_nights = int(d.get("inn_nights", 0))
	m.market.inn_side = int(d.get("inn_side", 0))
	m.market.inn_streak = int(d.get("inn_streak", 0))
	m.market.inn_cup_show()
	m.magpie_q = int(d.get("magpie_q", 0))
	for k in d.get("talks_heard", []):
		m.talks_heard[String(k)] = true
	if m.magpie_q >= 3:
		m.market.light_moon_lamp()
	var bts: Array = d.get("bottles", [])
	for i in mini(bts.size(), m.village.bottles.size()):
		if bool(bts[i]):
			m.village.bottles[i].got = true
			m.village.bottles[i].node.visible = false
	for k in ["has_pearl", "has_feather", "has_acorn", "has_ring", "has_shoes", "has_armour", "has_tea", "has_shard", "has_bookmark"]:
		m.set(k, bool(d.get(k, m.get(k))))
	if bool(d.get("has_armour", false)) and not m.castle.vault_open: # a new round keeps the armour: the treasury stays empty
		m.castle.open_vault_look()
	var fk: Array = d.get("fish", [])
	for i in mini(fk.size(), m.fish_kinds.size()):
		m.fish_kinds[i] = bool(fk[i])
	m.has_shoes = bool(d.get("has_shoes", false))
	m.shrine_seen = bool(d.get("shrine_seen", false))
	m.castle_q = int(d.get("castle_q", 0))
	if m.castle_q == 2:
		m.castle_q = 1 # the knight fight starts over
	if bool(d.get("castle_gate", false)):
		m.castle.open_gate()
	m.load_quarters(d)
	m.workshop_zone.load_work(d)
	m.load_oak(d)
	m.road_q = int(d.get("road_q", 0))
	m.mill_q = int(d.get("mill_q", 0))
	m.post_q = int(d.get("post_q", 0))
	if m.post_q >= 2 and m.post_gate != null:
		m.post_gate.visible = false
	if m.post_q >= 3 and m.post_pile != null:
		(m.post_pile.get_meta("card") as Node3D).visible = false
	m.has_oar_ring = bool(d.get("has_oar_ring", false))
	if m.mill_q >= 1:
		m.hill.open_wall()
	if m.mill_q >= 2:
		m.hill.wind_mill4(m)
	if m.mill_q >= 3:
		m.hill.fill()
	if m.mill_q >= 5:
		m.hill.chest_look()
	m.road_box = bool(d.get("road_box", false))
	if m.road_box:
		m.garden.blanket_look()
	if m.road_q >= 2 or m.garden_q >= 1:
		m.garden.open_roots()
	if m.road_q >= 4 or m.garden_q >= 1:
		m.garden.open_gate()
		m.garden.reveal(true)
	var sls: Array = d.get("seals", [])
	for i in mini(sls.size(), m.garden.seals.size()):
		if bool(sls[i]):
			m.garden.open_seal(m.garden.seals[i])
	m.load_clock(d)
	if bool(d.get("under_drained", false)):
		m.under.drain()
	if bool(d.get("under_door", false)):
		m.under.open_door()
	m.under_guards_done = bool(d.get("under_guards", false))
	m.under_diary_read = bool(d.get("under_diary", false))
	m.has_lamp = bool(d.get("has_lamp", false))
	if bool(d.get("under_chest", false)) or m.has_lamp: # a new round keeps the lamp: Hangyeol's chest stays empty
		m.castle_zone.open_under_chest_look()
	if bool(d.get("under_side", false)):
		m.under_side_open = true
		m.under.side_chest.texture = m.chest_open_tex
		m.under.side_chest.modulate = Color.WHITE
	if bool(d.get("stairs_wall", false)):
		m.stairs.open_wall()
	var sl: Array = d.get("stairs_lamps", [])
	for i in mini(sl.size(), m.stairs.lamps.size()):
		if bool(sl[i]):
			m.stairs.light_lamp(m.stairs.lamps[i])
	if m.stairs.lamps_lit() == m.stairs.lamps.size():
		m.stairs.open_door()
	var lvs: Array = d.get("levers", [])
	for i in mini(lvs.size(), m.castle.levers.size()):
		if bool(lvs[i]):
			m.castle.flip_lever(i)
	if bool(d.get("vault", false)):
		m.castle.open_vault_look()
	m.has_armour = bool(d.get("has_armour", false))
	var cps: Array = d.get("castle_pages", [])
	for i in mini(cps.size(), m.castle.pages.size()):
		m.castle.pages[i].read = bool(cps[i])
	if m.castle.pages_read() == 3 and bool(d.get("moon_door", true)): # v0.1.68 holds the moon door for the workshop; an older save is past it
		m.castle.open_door()
	if bool(d.get("in_hill", false)):
		var hx: float = m.player.x
		var hz: float = m.player.z
		m.enter_hill()
		if hx >= Main.WORK.WORK_X - 0.5: # saved on a workshop floor: that floor's arrival tile, companions beside her
			m.workshop_zone.enter_floor(Main.WORK.floor_of(hx), "A")
			hx = m.player.x
			hz = m.player.z
		elif hx >= Main.UNDER.UNDER_X - 0.5:
			m.enter_under()
		elif hx >= Main.STAIRS.STAIRS_X - 0.5:
			m.enter_stairs()
		elif hx >= Main.CASTLE.CASTLE_X - 0.5:
			m.enter_castle()
		elif hx >= Main.CLOUD.CLOUD_X - 0.5:
			m.enter_cloud()
		m.player.x = hx
		m.player.z = hz
		m.snap_mates()
	if bool(d.get("in_garden", false)):
		var gx: float = m.player.x
		var gz: float = m.player.z
		m.enter_garden()
		m.player.x = gx
		m.player.z = gz
		if m.in_clock(): # saved in the clock room; with the crown in she wakes at Hangyeol's spoke and pushes from 0
			m.garden_zone.clock_zone()
			if m.clock_q == 4:
				var j := m.hand_spot(0)
				m.player.x = j.x
				m.player.z = j.y
			m.snap_mates()
	if bool(d.get("in_forest", false)):
		var fx: float = m.player.x
		var fz: float = m.player.z
		m.enter_forest()
		m.player.x = fx
		m.player.z = fz
	m.has_skip = bool(d.get("has_skip", false))
	m.cave_exit_seen = bool(d.get("cave_exit_seen", false))
	if m.cave_exit_seen:
		m.cave.build_exit_mouth()
	m.marsh.restore(d.get("scraps", []), bool(d.get("moon_chest", false)))
	m.load_shore(d)
	m.fly_q = int(d.get("fly_q", 0))
	var fc: Array = d.get("flies", [])
	for i in mini(fc.size(), m.marsh.flies.size()):
		m.marsh.flies[i].caught = bool(fc[i])
	m.marsh.flies_on = m.fly_q == 1
	if m.fly_q >= 3:
		m.build_jar()
	var opened: Array = d.get("chests", [])
	for i in mini(opened.size(), m.chests.size()):
		if opened[i]:
			m.chests[i].open = true
			m.chests[i].node.texture = m.chest_open_tex
	if m.story_step >= 2 and m.dark_lamp != null: # the first lamp was already lit
		var glass: MeshInstance3D = m.dark_lamp.get_meta("glass")
		glass.material_override = m.dark_glass_mat
		m.dark_lamp = null
	if d.get("boss_dead", false):
		for e in m.enemies:
			if e.get("boss", false) and is_instance_valid(e.node):
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
				var mouth := Vector2(e.x, e.z) # an old save kept no mouth: the boss's spot, as before
				var ca: Array = d.get("cave_at", [])
				if ca.size() == 2 and float(ca[0]) > 0.0: # the saved mouth is the one place (GPT lap 7: it moved from 15, 7.4 to 16, 2.5 on reload)
					mouth = Vector2(float(ca[0]), float(ca[1]) + 1.5) # open_cave puts the mouth 1.5 north of what it gets
				m.open_cave(mouth, false)
	# the key, the door and the painting scene come back wherever she saved: they used to come back only for a save made
	# inside the cave, so a save outside replayed the first meeting with Noeul at every visit (the user, 2026-10-24)
	m.has_key = bool(d.get("has_key", false))
	m.saw_painting = bool(d.get("saw_painting", false))
	m.cave_door_open = bool(d.get("door_open", false))
	if was_in_cave: # rebuild the cave state (build_cave_props reads the three above), then put Sora back where she saved
		var px: float = m.player.x
		var pz: float = m.player.z
		m.enter_cave()
		m.player.x = px
		m.player.z = pz
		m.ui.mini.map_tex = m.cave.cave_map_tex()
	m.quest_before_cave = old_quest_words(String(d.get("cave_quest", ""))) # enter_cave above overwrote it
	if is_instance_valid(m.ui.title_hint):
		m.ui.title_hint.text = "아무 키나 눌러 이어하기  ·  F9 처음부터"
	repair_story_step(d)
	m.old_save_pips(d)
	m.moon_tokens.load_tokens(d) # before the quest line below: main_road_quest names a gate's need
	if m.story_step >= 6: # later chapters: the quest line as it was saved (older saves keep what the zone set)
		if d.has("quest"):
			m.set_quest(old_quest_words(String(d.quest)))
		if m.garden_q >= 5 and m.story_step >= 12 and Main.Ko.plain(m.ui.quest.text).begins_with("이야기 끝"): # older ending lines
			m.set_quest(main_road_quest())
		if Main.Ko.plain(m.ui.quest.text).begins_with(OLD_CAVE_QUEST) or Main.Ko.plain(m.ui.quest.text) == Main.CAVE_QUEST: # written by the bug below: the main road's last step instead
			m.set_quest(main_road_quest())
	else:
		m.set_quest(["", "팔목의 팔찌를 만져 보자 (E)", "서쪽 오두막으로 가 보자", "북쪽 벽돌왕이 늪의 물길을 막고 있다", "", Main.CAVE_QUEST][clampi(m.story_step, 0, 5)])
	if m.story_step >= 6:
		m.moon_tokens.mend_quest() # a saved line that points at a gate which holds names its need instead
	if turtle_cut: # the fight starts over from the pier
		m.set_quest("부두의 물결에게 말을 걸자 (E)")
	if bool(d.get("in_village", false)) and m.errand == 0: # saved on arrival before the quest changed (GPT playtest 5)
		m.set_quest(Main.SIMJI_QUEST)
	if chase_cut: # Noeul is not here until the next night (by night in the village start_night begins it again at once)
		m.set_quest(Main.NIGHT_REST_QUEST)
	if garden_cut: # the saved quest spoke of the shards or the winding that start over (GPT playtests 2 -> 9)
		m.set_quest(Main.GARDEN_RETRY_QUEST)
	if Main.Ko.plain(m.ui.quest.text).begins_with(m.windrun_prefix()): # an older save made mid-run: the frozen timer goes
		m.set_quest(main_road_quest())
		if m.mill_q >= 2:
			m.toast("바람이 흩어졌다. 깃대에서 다시 해 보자")
	# saved during the last winding lines (garden_q 5, ending not yet played): the ending plays now, paid once
	m.ending_due = m.garden_q >= 5 and m.story_step < 12
	if m.ending_due and not m.intro:
		m.garden_zone.mold_breaks()

# Until v0.0.5 every load with the Brick King down rebuilt the cave mouth with story_step = 5, so the story and the
# quest line wound back to "the cave opened" (the user, 2026-10-23, level 21 at the cave mouth). The step comes
# back from what the save shows was done; the quest line from the furthest step of the main road.
func repair_story_step(d: Dictionary) -> void:
	var at := m.story_step
	if m.has_skip: at = maxi(at, 7)
	if m.errand >= 1: at = maxi(at, 8)
	if m.night_q >= 1: at = maxi(at, 9)
	if m.forest_q >= 1 or m.castle_q >= 1: at = maxi(at, 10)
	if m.garden_q >= 1: at = maxi(at, 11)
	m.story_step = at

func old_quest_words(q: String) -> String:
	for w in OLD_QUEST_WORDS:
		q = q.replace(w[0], w[1])
	return q

func main_road_quest() -> String:
	if m.garden_q >= 5: return m.garden_zone.clock_quest()
	if m.castle_q >= 3: return m.moon_tokens.stairs_line("동쪽 문을 지나 정원 한가운데로 가자")
	if m.castle_q >= 1 and m.hill_q >= 3: return m.castle_zone.castle_quest() # the pages, the moon door or the workshop it waits for
	if m.hill_q >= 3: return m.moon_tokens.hill_line()
	if m.forest_q >= 3: return m.moon_tokens.forest_line()
	if m.lake_q >= 4: return m.moon_tokens.lake_line()
	if m.night_q >= 4: return "물결과 함께 남쪽 호수를 풀자 (마을 남쪽 문)"
	return ""

# keep level, gold and story, but put Sora back at the starting crossing (F8)
func return_to_start() -> void:
	m.cam_yaw = Main.CAM_YAW
	if not m.in_marsh() and m.ui.has("outside_map"):
		m.ui.mini.map_tex = m.ui.outside_map
	m.in_cave = false
	m.in_village = false
	m.in_forest = false
	m.corridor_zone.clear_job()
	m.in_lake = false
	m.in_hill = false
	m.in_garden = false
	m.in_house = -1
	m.gust_dir = Vector2.ZERO
	m.ui.boss.visible = false
	m.player.x = Main.START.x
	m.player.z = Main.START.y
	m.ground_y = m.height_at(Main.START.x, Main.START.y)
	m.ui.zone_name.text = "갈대늪"
	m.ui.zone_sub.text = "등불여울 건널목"
	m.toast("건널목으로 돌아왔다")
	save_game()

# F9 asks before it wipes the save (the owner, 2026-10-28: "F9 눌러서 리셋하기 전에, 진짜로 리셋할지 물어본다"): the first
# press shows what is lost and what the difficulty becomes, a second F9 within 10 s wipes; on the title the hint line asks
var reset_asked_at := -100.0

func ask_reset() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - reset_asked_at < 10.0:
		reset_game()
		return
	reset_asked_at = now
	if m.intro:
		m.ui.title_hint.text = tr("F9를 한 번 더 누르면 저장을 지우고 처음부터 (10초 안에)")
		return
	m.close_story()
	m.show_story("", reset_lines())

# the ask: what goes, with this round and level filled in, and how to confirm
func reset_lines() -> Array:
	return [Main.STORY.RESET_ASK[0], "||" + tr(Main.STORY.RESET_ASK[1].substr(2)) % [m.ng + 1, m.player.lv], Main.STORY.RESET_ASK[2]]

func reset_game() -> void:
	if FileAccess.file_exists(m.SAVE_PATH):
		DirAccess.remove_absolute(m.SAVE_PATH)
	m.get_tree().reload_current_scene()
