# Feats, Doran's letters, festival, new round, hint villagers and errands.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const NG_KEEP := ["lv", "xp", "max_hp", "atk", "gold", "pots", "has_pearl", "has_feather", "has_acorn", "has_ring", "has_shoes",
	"has_armour", "has_tea", "has_shard", "has_bookmark", "has_lamp", "has_medal", "has_oar_ring", "has_whistle", "has_oil", "has_cushion", "has_bait", "has_buckler", "has_sprout", "work_hp", "skill_up", "stats", "feats", "trial_best", "race_best", "fish", "pip_max", "pip_awards"]
const OAR_AT := Vector2(9.0, 11.0) # middle of the north-west marsh pond, reachable only by water skip

func _init(main: Main) -> void:
	m = main

func play_time_text() -> String:
	var mm := int(m.play_secs) / 60
	return tr("%d시간 %d분") % [mm / 60, mm % 60]

func bosses_beaten() -> int:
	var king := m.story_step >= 5
	return int(king) + int(m.has_skip) + int(m.night_q >= 4) + int(m.forest_q >= 3) + int(m.lake_q >= 4) + int(m.grotto_q >= 3) \
		+ int(m.hill_q >= 3) + int(m.cloud_q >= 3) + int(m.castle_q >= 3) + int(m.garden_q >= 5)

func feat_value(key: String) -> int:
	match key:
		"bosses": return bosses_beaten()
		"level": return m.player.lv
	return int(m.stats.get(key, 0))

func check_feats() -> void:
	for i in Main.FEATS.size():
		if not m.feats_done[i] and feat_value(Main.FEATS[i][1]) >= Main.FEATS[i][2]:
			m.feats_done[i] = true
			m.player.gold += 50
			m.toast(tr("도전 과제: %s (금화 +50)") % tr(Main.FEATS[i][0]))
			m.sfx(784, 0.15, "triangle", 0.22)
			m.get_tree().create_timer(0.15).timeout.connect(func(): m.sfx(1046, 0.25, "triangle", 0.22))
			m.save_game()
			return # one at a time, so each toast is seen

# the garden is wound again: the ending played or its last winding is done
func garden_wound() -> bool:
	return m.garden_q >= 5 or m.story_step >= 12

func mail_errand() -> bool:
	if m.mail_q == 0:
		m.mail_q = 1
		m.show_story("", Main.STORY.MAIL_ASK)
		m.save_game()
		return true
	if m.mail_q == 1 and m.mail_got.count(true) == 3:
		m.mail_q = 2
		m.player.gold += 150
		m.player.max_hp += 10
		m.player.hp = float(m.player.max_hp)
		var mail_lines: Array = Main.STORY.MAIL_DONE.duplicate()
		if garden_wound(): # before the ending Doran thanks her for the letters, not for the garden (GPT playtest 5)
			mail_lines[1] = Main.STORY.MAIL_DONE_WOUND
		m.show_story("", mail_lines)
		m.save_game()
		return true
	if m.mail_q == 1:
		m.show_story("", Main.STORY.FOLK_AGAIN.doran_mail)
		return true
	return false

func deliver(i: int, lines: Array) -> bool:
	if m.mail_q != 1 or m.mail_got[i]:
		return false
	m.mail_got[i] = true
	m.show_story("", lines)
	m.sfx(660, 0.15, "triangle", 0.2)
	if m.mail_got.count(true) == 3:
		m.toast("편지를 모두 전했다. 도란에게 알리자")
	m.save_game()
	return true

func festival_now() -> bool:
	return m.mail_got[1] and m.in_village and m.in_house < 0 and m.is_night() and m.moon_phase().x >= 0.95

func update_festival(dt: float) -> void:
	if not festival_now() or m.story_open:
		return
	if not m.fest_seen:
		m.fest_seen = true
		m.toast("보름달 아래 등불 축제가 열렸다")
	m.fest_t -= dt
	if m.fest_t > 0.0:
		return
	m.fest_t = 0.5
	var at := Vector3(Main.VILLAGE.VILLAGE_X + m.rnd(3, 45), m.rnd(0.5, 1.5), m.rnd(3, 33))
	var lamp := m.box(Vector3(0.24, 0.32, 0.24), m.glow_mat(Color("#ff9a3a"), 0.7)) # low glow keeps the orange under bloom
	lamp.position = at
	m.add_fx(lamp, 9.0, func(n: Node3D, k: float, d: float):
		n.position.y += d * 0.7
		n.position.x += sin(k * 9.0) * d * 0.2
		n.scale = Vector3.ONE * (1.0 - k * 0.6))

func festival_key() -> bool:
	if not festival_now() or Vector2(m.player.x, m.player.z).distance_to(m.village.marks.M) > 1.8:
		return false
	if m.fest_gift:
		m.show_story("", Main.STORY.FEST_AGAIN)
		return true
	m.fest_gift = true
	m.player.pots += 3
	var fest_lines: Array = Main.STORY.FESTIVAL.duplicate()
	if garden_wound():
		fest_lines[1] = Main.STORY.FESTIVAL_WOUND
	m.show_story("", fest_lines)
	m.save_game()
	return true

func ng_mult() -> float:
	return 1.0 + 0.5 * m.ng

func ng_key() -> bool:
	if not m.in_garden or m.garden_q < 5 or Vector2(m.player.x, m.player.z).distance_to(m.garden.marks.C) > 3.0:
		return false
	if m.ng_armed <= 0.0:
		m.ng_armed = 10.0
		m.show_story("", new_round_lines())
		return true
	new_round()
	return true

# the notice with the next round's multiplier, 1 + 0.5 x (ng + 1)
func new_round_lines() -> Array:
	var mm := ("%.1f" % (1.0 + 0.5 * (m.ng + 1))).trim_suffix(".0")
	return Main.STORY.NEW_ROUND_ASK.map(func(l): return ("||" + tr(l.substr(2)) % mm) if "%s" in l else l)

func new_round() -> void:
	write_new_round()
	m.get_tree().reload_current_scene()

# the save a new round starts from: only what carries over, story back to 0
func write_new_round() -> void:
	m.save_game()
	var d = JSON.parse_string(FileAccess.get_file_as_string(m.SAVE_PATH))
	var keep := {"ng": m.ng + 1, "story": 0}
	for k in NG_KEEP:
		if d.has(k):
			keep[k] = d[k]
	keep["hp"] = keep.get("max_hp", 100)
	var f := FileAccess.open(m.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(keep))
	f.close()

func hf_milestone(key: String) -> bool:
	match key:
		"cave": return m.story_step >= 5 # the Brick King is down and the cave open
		"lamps": return m.errand >= 3    # the village lamps relit and Simji thanked
		"lake": return m.lake_q >= 4
		"forest": return m.forest_q >= 3
		"hill": return m.hill_q >= 3
		"castle": return m.castle_q >= 3
		"ending": return m.garden_q >= 5
	return false

# the side quest a hint points at can be done now (its zone open) and is not finished; the same tests as the journal
func hint_open(key: String) -> bool:
	match key:
		# the marsh and the village
		"scraps": return m.story_step >= 2 and not m.marsh.chest_open
		"moonflowers": return m.story_step >= 3 and not m.has_tea
		"fireflies": return m.kid_q >= 3 and m.doran_q >= 3 and m.fly_q < 3
		"shore": return m.story_step >= 3 and m.shore_q < 2
		"fishing": return m.fish_kinds.count(true) < Main.FISH.size() # the village pier is always open
		"target": return not m.has_medal
		"magpie": return m.magpie_q < 3
		"bottles": return m.village.bottles_got() < m.village.bottles.size()
		"inn": return m.inn_nights == 0
		"cupboards": return not m.house_seen[4] # only the last house's picture is worth a look
		"errands": return int(m.errand >= 3) + int(m.kid_q >= 3) + int(m.doran_q >= 3) + int(m.mul_q >= 3) + int(m.fly_q >= 3) < 5
		"festival": return m.mail_got[1] and not m.fest_gift
		"mail": return m.doran_q >= 3 and m.lake_q >= 4 and m.mail_q < 2
		# the cave (open once the Brick King is down)
		"crystals": return m.story_step >= 6 and not m.has_ring
		"shrine": return m.story_step >= 6 and m.skill_up < 0
		"post": return m.has_skip and m.post_q < 3
		# the lake (open after the night chase)
		"grotto": return m.lake_q >= 4 and m.grotto_q < 4
		"south": return m.lake_q >= 4 and m.south_q < 5
		# the forest (open once Mulgyeol joins)
		"squirrels": return m.lake_q >= 4 and not m.has_acorn
		"grove": return m.lake_q >= 4 and not m.forest.chest_open
		"hollow": return m.forest_q >= 3 and m.hollow_q < 4
		# the wind hills (open once Noeul turns) and the clouds above
		"race": return m.forest_q >= 3 and m.race_best <= 0.0
		"mill": return m.hill_q >= 3 and m.mill_q < 5
		"cloud": return m.hill_q >= 3 and m.cloud_q < 3
		"cloud_path": return m.cloud_q >= 1 and not m.has_shard
		"trial": return m.hill_q >= 3 and m.trial_best <= 0.0
		# the castle, its stairs and the garden
		"pages": return m.castle_q >= 1 and m.castle.pages_read() < 3
		"books": return m.castle_q >= 1 and not m.has_bookmark
		"vault": return m.castle_q >= 1 and not m.castle.vault_open
		"under": return m.castle_q >= 1 and not m.under_chest_open
		"stairs": return m.castle_q >= 3 and not m.stairs.door_open
		"clock": return m.garden_q >= 5 and not m.clock_box
		"quarters": return m.castle_q >= 3 and m.quarters_q < 5
		"oak": return m.forest_zone.oak_ready() and m.oak_q < 2
	return false

func hint_folk_talk(id: String) -> void:
	var f: Dictionary = Main.STORY.HINT_FOLK[id]
	if not m.met.has(id):
		m.met[id] = true
		m.show_story("", f.first)
		m.save_game()
		return
	var seen: Array = m.hf_seen.get(id, [])
	var beats: Array = f.beats
	for i in beats.size():
		if not seen.has(i) and hf_milestone(beats[i][0]):
			seen.append(i)
			m.hf_seen[id] = seen
			var lines: Array = (beats[i][1] as Array).duplicate()
			if i == beats.size() - 1: # the last beat comes with a gift
				hf_gift(f.gift)
				lines.append(Main.STORY.HF_GIFT[f.gift])
			m.show_story("", lines)
			m.save_game()
			return
	var topics: Array = f.hints.keys().filter(func(k): return hint_open(k))
	if not topics.is_empty():
		var n: int = m.hf_turn.get(id, 0)
		m.hf_turn[id] = n + 1
		m.show_story("", f.hints[topics[n % topics.size()]])
		return
	m.show_story("", [f.idle[m.rng.randi() % f.idle.size()]])

func hf_gift(kind: String) -> void:
	match kind:
		"pots": m.player.pots += 1
		"gold": m.player.gold += 30
		"bait": m.has_bait = true

# the one short line under the quest for errands that are not the shore's: Hangyeol's letter still has to go back to Doran
func letter_side_line() -> String:
	if m.doran_q >= 3 and not m.letter_back and not m.story_open:
		return "도란에게 한결의 편지를 돌려주자"
	return ""

# a quest line that names a villager who is asleep indoors says so instead (GPT lap 8: "Kongal is crying" at midnight)
const QUEST_FOLK := [["콩알이 울고", "kongal"], ["콩알에게", "kongal"], ["도란에게", "doran"], ["물결에게", "mulgyeol"]]

func quest_sleeper(raw: String) -> String:
	for q in QUEST_FOLK:
		if raw.contains(q[0]):
			var id: String = q[1]
			if m.folk_state.get(id, "out") == "in" and m.folk_awake_here(id):
				return id
			return ""
	return ""

func sleeping_quest(id: String) -> String:
	return tr("%s은(는) 지금 집에서 잔다. 집에 들어가 침대 곁에서 E (아니면 아침에)") % tr(m.folk.FOLK_NAME[id])

# errand 2: Kongal's kid goblin was dragged to the south field by three goblins
func kongal_errand() -> void:
	if m.kid_q == 0:
		m.kid_q = 1
		m.show_story("", Main.STORY.KONGAL_LOST)
		m.set_quest("남쪽 들판에서 꼬마 고블린을 찾자")
		m.place_kid()
	elif m.kid_q == 2:
		m.kid_q = 3
		m.player.gold += 40
		m.player.pots += 1
		m.show_story("", Main.STORY.KONGAL_DONE)
		m.set_quest("우편배달부 도란에게 말을 걸어 보자 (E)")
		m.place_kid()
	elif m.kid_q >= 3 and m.doran_q >= 3 and m.fly_q == 0:
		m.fly_q = 1
		m.marsh.flies_on = true
		m.show_story("", Main.STORY.FLY_ASK)
	elif m.fly_q == 1:
		m.show_story("", Main.STORY.FOLK_AGAIN.kongal_fly)
	elif m.fly_q == 2:
		m.fly_q = 3
		m.player.gold += 30
		m.show_story("", Main.STORY.FLY_DONE)
		m.build_jar()
	else:
		folk_talk("kongal")
	m.save_game()

# first meeting: the long introduction; afterwards a short line that follows their errand
func folk_talk(id: String) -> void:
	var q := {"doran": m.doran_q, "kongal": m.kid_q, "mulgyeol": m.mul_q}.get(id, 0) as int
	if not m.met.has(id) and q == 0: # once his errand has begun, the lines follow it (GPT playtests 2 -> 9)
		m.show_story("", Main.STORY.FOLK[id])
		return
	if id == "doran" and q >= 3 and not m.letter_back:
		m.letter_back = true
		m.show_story("", Main.STORY.DORAN_LETTER_BACK)
		return
	var key := id + ("_done" if q >= 3 else ("_carry" if id == "doran" and q == 2 else ("_search" if q == 1 and id != "doran" else "_wait")))
	m.show_story("", Main.STORY.FOLK_AGAIN[key])

# errand 3: the crown loosens the first line of Doran's century-old letter; it is for Bori
func doran_errand() -> void:
	if m.doran_q == 0:
		m.doran_q = 1
		m.show_story("", Main.STORY.DORAN_ASK)
		m.set_quest("도란의 편지에 팔찌를 대 보자 (E, 달빛 눈금 사용)")
	elif m.spend_pips(m.village_life.lamp_cost()):
		m.doran_q = 2
		m.burst(Vector3(m.player.x, 1.4, m.player.z), Color("#9fd4ff"), 18, 1.5)
		m.sfx(587, 0.4, "sine", 0.3, 300)
		m.show_story("", Main.STORY.DORAN_READ)
		m.set_quest("편지를 서쪽 늪 오두막의 보리 할머니께 전하자 (E)")
	else:
		return
	m.save_game()

func deliver_letter() -> void:
	m.doran_q = 3
	var pip_lines := m.award_pip("letter") # the pip took the place of max HP +10 (v0.0.47)
	if not pip_lines.is_empty():
		pip_lines.push_front(Main.STORY.BORI_LETTER_PIP)
	m.crown_pips = m.pip_max
	m.player.hp = float(m.player.max_hp)
	if m.post_q == 3: # the postcard from the stream's end goes with Hangyeol's letter
		m.post_q = 4
		m.player.pots += 2
		m.show_story("", Main.STORY.BORI_LETTER + pip_lines + m.post_bori_lines())
	else:
		m.show_story("", Main.STORY.BORI_LETTER + pip_lines)
	m.set_quest("마을의 뱃사공 물결에게 가 보자 (E)")
	m.save_game()

# errand 4: Mulgyeol's oar floats in the middle of the half-hardened NW pond
func mulgyeol_errand(first := false) -> void:
	if m.mul_q == 0:
		m.mul_q = 1
		m.show_story("", Main.STORY.MUL_ASK_FIRST if first else Main.STORY.MUL_ASK)
		m.set_quest("늪 북서쪽 연못 한가운데의 노를 건져 오자 (Shift로 물 위 달리기)")
		place_oar()
	elif m.mul_q == 2:
		m.mul_q = 3
		m.player.gold += 50
		m.show_story("", Main.STORY.MUL_DONE)
		m.set_quest(Main.NIGHT_REST_QUEST)
	else:
		folk_talk("mulgyeol")
	m.save_game()

func place_oar() -> void:
	if m.oar_node != null:
		return
	m.oar_node = Node3D.new()
	var wood: Material = m.mat_color(Color("#8a5a2e"))
	for part in [[Vector3(0.08, 0.08, 1.6), Vector3(0, 0, 0)], [Vector3(0.3, 0.06, 0.5), Vector3(0, 0, 0.95)]]:
		var b: MeshInstance3D = m.box(part[0], wood)
		b.position = part[1]
		m.oar_node.add_child(b)
	var glow := OmniLight3D.new() # a faint glint so it can be spotted from the shore
	glow.light_color = Color("#bfe6ff")
	glow.light_energy = 1.2
	glow.omni_range = 3.0
	glow.position = Vector3(0, 0.8, 0)
	m.oar_node.add_child(glow)
	m.oar_node.position = Vector3(OAR_AT.x, -0.15, OAR_AT.y)
	m.oar_node.rotation.y = 0.7
	m.add_child(m.oar_node)

func update_oar() -> void:
	if m.oar_node == null or not m.oar_node.visible:
		return
	m.oar_node.position.y = -0.15 + sin(m.t * 2.0) * 0.04
	if m.mul_q == 1 and not m.in_village and not m.in_cave and Vector2(m.player.x, m.player.z).distance_to(OAR_AT) < 1.4:
		m.mul_q = 2
		m.oar_node.visible = false
		m.burst(Vector3(m.player.x, 0.4, m.player.z), Color("#9fe0ff"), 18, 1.5)
		m.sfx(659, 0.3, "triangle", 0.25)
		m.toast("물결의 노를 건졌다")
		m.set_quest("노를 마을의 물결에게 가져가자 (E)")
		for at in [Vector2(6, 15), Vector2(12, 15)]: # the bricks on the shore wake up
			m.spawn_enemy(at)
		m.save_game()
