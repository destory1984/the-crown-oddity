# Talk balloons: companions' chat and villagers' chatter.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const FOLK_CHAT_R := 4.0

func _init(main: Main) -> void:
	m = main

func balloon_tex(w: int) -> ImageTexture:
	if m.balloon_cache.has(w):
		return m.balloon_cache[w]
	var h := 52
	var tail := 14
	var img := Image.create(w, h + tail, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rim := Color("#5a3a22")
	var fill := Color("#fff8e8")
	var r := 16
	for y in h:
		for x in w:
			var cx := clampi(x, r, w - 1 - r)
			var cy := clampi(y, r, h - 1 - r)
			var d := Vector2(x - cx, y - cy).length()
			if d <= r:
				img.set_pixel(x, y, rim if d > r - 3 else fill)
	for k in tail: # the tail: a small triangle under the middle
		var half := int((tail - k) * 0.8)
		for x in range(w / 2 - half, w / 2 + half + 1):
			var edge := x <= w / 2 - half + 2 or x >= w / 2 + half - 2 or k == tail - 1
			img.set_pixel(x, h - 3 + k, rim if edge else fill)
	var tex := ImageTexture.create_from_image(img)
	m.balloon_cache[w] = tex
	return tex

# E beside the same sign three times within 45 s: Noeul offers to memorise it, once for each sign (delight idea 12)
var sign_looks := {} # sign index -> [looks in a row, time of the last]
var sign_teased := {} # sign index -> true
var sign_teases := 0 # teases said (autoplay sign_tease)

func sign_look() -> void:
	if m.intro or m.story_open or m.in_house >= 0:
		return
	var me := Vector2(m.player.x, m.player.z)
	var best := -1
	var best_d := 1.9
	for i in m.sign_spots.size():
		var d: float = me.distance_to(m.sign_spots[i])
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		return
	m.sfx(784, 0.06, "triangle", 0.06) # a tick as she reads it
	var rec: Array = sign_looks.get(best, [0, -100.0])
	rec = [1 if m.t - float(rec[1]) > 45.0 else int(rec[0]) + 1, m.t]
	sign_looks[best] = rec
	if rec[0] >= 3 and not sign_teased.has(best) and m.mate2 != null:
		sign_teased[best] = true
		sign_teases += 1
		say_bubble(m.mate2, tr("이번엔 내가 외울게."), 3.0)

# the first villager she speaks to after a fight sees the dust on her blade and says so once (delight idea 60). It comes
# before the normal answer and never replaces it.
const BREATH_WINDOW := 45.0
var fight_end_t := -1000.0
var breath_open := false # a fight ended and nobody has said it yet
var breath_says := 0

func fight_ended() -> void:
	fight_end_t = m.t
	breath_open = true

func breath_word(id: String) -> void:
	if not breath_open:
		return
	breath_open = false
	if m.t - fight_end_t > BREATH_WINDOW or not m.village.folk_node.has(id):
		return
	breath_says += 1
	folk_say(id, "먼저 숨부터 돌려.")

func say_bubble(who: Node3D, text: String, dur := 3.5) -> void:
	m.bubbles_said += 1
	var b := Node3D.new()
	var w := 40 + text.length() * 26
	w = int(ceil(w / 16.0)) * 16 # a few widths only, so the cache stays small
	var card := Sprite3D.new()
	card.texture = balloon_tex(w)
	card.pixel_size = 0.0065
	card.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	card.no_depth_test = true
	card.shaded = false
	card.render_priority = 1
	card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	b.add_child(card)
	var l := Label3D.new()
	l.text = text
	l.font = m.ui_font
	l.font_size = 30
	l.pixel_size = 0.0065
	l.modulate = Color("#3a2414")
	l.outline_size = 0
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 2
	l.position = Vector3(0, 0.045, 0) # centred on the card, above the tail
	b.add_child(l)
	b.position = Vector3(0, 2.45, 0)
	var big := 1.4 if m.touch_ui else 1.0 # phones: bigger text, and a second longer to read it
	b.scale = Vector3.ONE * 0.2 * big
	who.add_child(b)
	var tw := b.create_tween() # pops up, then fades away
	tw.tween_property(b, "scale", Vector3.ONE * big, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur + (1.0 if m.touch_ui else 0.0))
	tw.tween_property(card, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(b.queue_free)

func chat_lines(id: String) -> Array:
	var lines: Array = Main.STORY.MATE_CHAT[id].duplicate()
	var place := ""
	if m.in_lake: place = "lake"
	elif m.in_village: place = "village"
	elif m.in_castle(): place = "castle"
	elif m.in_cloud(): place = "cloud"
	elif m.in_hill: place = "hill"
	elif m.in_forest: place = "forest"
	elif m.in_marsh(): place = "marsh"
	var key := id + "_" + place
	if Main.STORY.MATE_CHAT.has(key):
		lines.append_array(Main.STORY.MATE_CHAT[key])
		lines.append_array(Main.STORY.MATE_CHAT[key]) # a place line is twice as likely
	if m.is_night() and Main.STORY.MATE_CHAT.has(id + "_night"):
		lines.append_array(Main.STORY.MATE_CHAT[id + "_night"])
	return lines

func update_chat(dt: float) -> void:
	m.chat_cd -= dt
	if not m.talk_bubbles.is_empty() and m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 8.0):
		hush_talk()
	var still: bool = Vector2(m.player.vx, m.player.vz).length() < 0.3 and not m.story_open and not m.intro and m.in_house < 0
	m.chat_t = m.chat_t + dt if still else 0.0
	if m.chat_t < 9.0 or m.chat_cd > 0.0:
		return
	if m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 8.0):
		return
	var who: Array = []
	if m.mate != null and m.mate.visible: who.append(["mulgyeol", m.mate])
	if m.mate2 != null and m.mate2.visible: who.append(["noeul", m.mate2])
	if who.is_empty():
		return
	m.chat_cd = m.rnd(14.0, 24.0)
	# most rests are a little talk with Sora in it (the user asked for all three to chat, not only the two)
	var here: Array = ["sora"]
	for pair in who:
		here.append(pair[0])
	# a talk about where the story stands comes first, once each (the user asked for talk that follows the game)
	for st in Main.STORY.REST_TALK_STORY:
		var key: String = st[0]
		var talk: Array = st[1]
		if not m.talks_heard.has(key) and story_talk_ok(key) and talk.all(func(ln): return ln[0] in here):
			m.talks_heard[key] = true
			rest_talk(talk)
			return
	var pool: Array = Main.STORY.REST_TALK.duplicate()
	# cave, garden and rain got talks of their own with the 500 talks (2026-10-24)
	var place := "night" if m.is_night() and m.rng.randf() < 0.5 else ("rain" if m.raining and m.rng.randf() < 0.5 else ("village" if m.in_village else ("lake" if m.in_lake else ("forest" if m.in_forest else ("castle" if m.in_castle() else ("garden" if m.in_garden else ("hill" if m.in_hill else ("cave" if m.in_cave else ("marsh" if m.in_marsh() else "")))))))))
	for w in Main.STORY.REST_TALK_WHERE:
		if w[0] == place:
			pool.append(w[1])
			pool.append(w[1]) # a talk for the place is twice as likely
	var talks: Array = pool.filter(func(tk): return tk.all(func(ln): return ln[0] in here))
	if not talks.is_empty() and m.rng.randf() < 0.65:
		rest_talk(talks[m.rng.randi() % talks.size()], true)
		return
	if who.size() == 2 and m.rng.randf() < 0.3: # the two of them trade a line
		var pair: Array = Main.STORY.MATE_BANTER[m.rng.randi() % Main.STORY.MATE_BANTER.size()]
		var first: Node3D = m.mate if pair[0] == "mulgyeol" else m.mate2
		var second: Node3D = m.mate2 if pair[0] == "mulgyeol" else m.mate
		say_bubble(first, tr(pair[1]))
		m.get_tree().create_timer(2.2).timeout.connect(func(): if is_instance_valid(second): say_bubble(second, tr(pair[2])))
		return
	var pick: Array = who[m.rng.randi() % who.size()]
	var lines := chat_lines(pick[0])
	say_bubble(pick[1], tr(lines[m.rng.randi() % lines.size()]))

# when a story rest talk may come: each names a point in the game
func story_talk_ok(key: String) -> bool:
	match key:
		"mul_new": return m.lake_q >= 4 and m.forest_q < 3
		"noeul_new": return m.forest_q >= 3 and m.hill_q < 3
		"hawk": return m.hill_q >= 3 and m.cloud_q < 3
		"scare": return m.cloud_q >= 3
		"post_done": return m.post_q >= 4
		"south_hint": return m.lake_q >= 4 and m.south_q == 0
		"south_done": return m.south_q >= 5
		"clock_done": return m.clock_q >= 5
		"shore_done": return m.shore_q >= 4
		"quarters_done": return m.quarters_q >= 5
		"oak_done": return m.oak_q >= 2
		"mill_hint": return m.hill_q >= 3 and m.mill_q == 0
		"mill_done": return m.mill_q >= 5
		"pearl": return m.grotto_q >= 4
		"jar": return m.fly_q >= 3 and m.mate2 != null
		"castle_in": return m.castle_q >= 1 and m.castle_q < 3 and m.castle.pages_read() < 3
		"pages": return m.castle.pages_read() == 3 and m.castle_q < 3
		"knight": return m.castle_q >= 3 and m.garden_q == 0
		"lamp": return m.under_chest_open
		"magpie": return m.magpie_q >= 3
		"hollow_hint": return m.forest_q >= 3 and m.hollow_q == 0
		"hollow_done": return m.hollow_q >= 4
		"letters": return m.village.bottles_got() == m.village.bottles.size()
		"festival": return m.fest_gift
		"inn": return m.inn_nights >= 1
		"medal": return m.has_medal
		"trial": return m.trial_best > 0.0
		"tired": return m.crown_pips <= 1
		"hurt": return m.player.hp < m.player.max_hp * 0.4
		"end": return m.garden_q >= 5
		"round": return m.ng > 0
	return false

# light: an ordinary rest talk (not one that follows the story). If Sora then stands quite still through all of it, Mulgyeol
# adds a small thanks after the last line, at most once in LISTEN_GAP seconds (delight idea 19)
const LISTEN_GAP := 120.0
var listen_last := -1000.0
var listen_thanks := 0 # thanks said (autoplay d19_listened)

func rest_talk(talk: Array, light := false) -> void:
	m.chat_cd = maxf(m.chat_cd, talk.size() * 2.4 + 10.0)
	m.talk_id += 1
	var my_id := m.talk_id
	if light and m.mate != null:
		var still_since: float = m.t - m.chat_t # when this stillness began; moving and stopping again changes it
		m.get_tree().create_timer(talk.size() * 2.4 + 0.4).timeout.connect(func():
			if my_id != m.talk_id or m.story_open or m.intro or m.mate == null or not is_instance_valid(m.mate) or not m.mate.visible:
				return
			if absf((m.t - m.chat_t) - still_since) > 0.05 or m.t - listen_last < LISTEN_GAP:
				return
			if m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 8.0):
				return
			listen_last = m.t
			listen_thanks += 1
			say_bubble(m.mate, tr("들어 줬네."), 2.2))
	for i in talk.size():
		var ln: Array = talk[i]
		m.get_tree().create_timer(i * 2.4 + 0.01).timeout.connect(func():
			if m.story_open or my_id != m.talk_id:
				return
			var node: Node3D = null
			match ln[0]:
				"mulgyeol": node = m.mate
				"noeul": node = m.mate2
				"sora":
					node = Node3D.new()
					node.position = Vector3(m.player.x, m.ground_y, m.player.z)
					m.add_child(node)
					m.get_tree().create_timer(4.5).timeout.connect(node.queue_free)
			if node != null and is_instance_valid(node):
				say_bubble(node, tr(ln[1]), 2.2)
				m.talk_bubbles.append(node.get_child(node.get_child_count() - 1)))

# a monster within 8 tiles ends the chatter at once (the user asked)
func hush_talk() -> void:
	m.talk_id += 1
	for b in m.talk_bubbles:
		if is_instance_valid(b):
			b.queue_free()
	m.talk_bubbles = []

# where a villager who can chat now stands; Vector2.INF when he is not here, asleep or travelling with Sora
func folk_chat_at(id: String) -> Vector2:
	match id:
		"bori": # in her cottage on the marsh, by day
			if not m.in_marsh() or m.is_night() or m.story_step < 3:
				return Vector2.INF
			return Vector2(m.shop_pos.x, m.shop_pos.z)
		"simji": # the lamplighter keeps to the square day and night
			if not m.in_village or m.village.simji_node == null or not m.village.simji_node.visible:
				return Vector2.INF
			return Vector2(m.village.simji_node.position.x, m.village.simji_node.position.z)
		"kid": # Kongal's kid goblin, only once he is home with her
			if not m.in_village or m.kid_q != 3 or m.kid_node == null or not m.kid_node.visible:
				return Vector2.INF
			return Vector2(m.kid_node.position.x, m.kid_node.position.z)
	if not m.in_village or not m.village.folk_node.has(id) or not m.folk_awake_here(id) or m.folk_state.get(id, "out") == "in":
		return Vector2.INF
	var spr: Sprite3D = m.village.folk_node[id]
	if not spr.visible:
		return Vector2.INF
	return Vector2(spr.position.x, spr.position.z)

# his own errand is running (the lines tagged "errand")
func folk_errand_on(id: String) -> bool:
	match id:
		"simji": return m.errand == 1                  # the three dark lanterns
		"doran": return m.doran_q == 1                 # the letter the bracelet should read
		"kongal": return m.kid_q == 1 or m.kid_q == 2    # her kid goblin lost
		"mulgyeol": return m.mul_q == 1 or m.mul_q == 2  # his oar in the NW pond
		"bori": return m.doran_q == 2                  # Hangyeol's letter on its way to her
	return false

func folk_tag_ok(id: String, tag: String) -> bool:
	if tag.begins_with("pair:"):
		var me := folk_chat_at(id)
		var other := folk_chat_at(tag.substr(5))
		return me.is_finite() and other.is_finite() and me.distance_to(other) < FOLK_CHAT_R
	match tag:
		"any": return true
		"morning": return m.hour >= 6.0 and m.hour < 10.0
		"day": return m.hour >= 10.0 and m.hour < 17.0
		"dusk": return m.hour >= 17.0 and m.hour < 20.0
		"night": return m.hour >= 20.0 or m.hour < 6.0
		"rain": return m.raining
		"before_night": return m.night_q < 4
		"after_night": return m.night_q >= 4
		"after_lake": return m.lake_q >= 4
		"after_ending": return m.story_step >= 12
		"after_workshop": return m.work_q >= 6 # the repair bench by the square
		"festival": return m.festival_now()
		"errand": return folk_errand_on(id)
	return false

# his lines that fit now; one tied to more than the hour (rain, the story, a friend nearby) is twice as likely
func folk_chat_lines(id: String) -> Array:
	var out: Array = []
	for pair in Main.STORY.FOLK_CHAT[id]:
		var tags: PackedStringArray = String(pair[0]).split(",")
		if not Array(tags).all(func(tg): return folk_tag_ok(id, String(tg).strip_edges())):
			continue
		var line: String = pair[1]
		if line == m.folk_chat_last.get(id, "") and Main.STORY.FOLK_CHAT[id].size() > 1:
			continue
		out.append(line)
		if not Array(tags).all(func(tg): return tg in ["any", "morning", "day", "dusk", "night"]):
			out.append(line)
	return out

func update_folk_chat(dt: float) -> void:
	for b in m.folk_bubbles.duplicate():
		b.t -= dt
		var anchor: Node3D = b.anchor
		var at := folk_chat_at(b.id)
		if b.t <= 0.0 or not at.is_finite():
			anchor.queue_free()
			m.folk_bubbles.erase(b)
			continue
		anchor.position = Vector3(at.x, anchor.position.y, at.y)
	m.folk_chat_gap -= dt
	for id in m.folk_chat_cd:
		m.folk_chat_cd[id] -= dt
	if m.folk_chat_off or m.intro or m.story_open or m.shop_open or m.way_open or m.settings_open or m.ui.journal.visible or m.in_house >= 0 or m.folk_chat_gap > 0.0:
		return
	if not m.in_village and not m.in_marsh():
		return
	var me := Vector2(m.player.x, m.player.z)
	if m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - me.x, e.z - me.y).length() < 8.0):
		return
	var near: Array = []
	for id in Main.STORY.FOLK_CHAT:
		var at := folk_chat_at(id)
		if not at.is_finite() or at.distance_to(me) >= FOLK_CHAT_R:
			continue
		if not m.folk_chat_cd.has(id): # just came near: a moment before he speaks
			m.folk_chat_cd[id] = m.rnd(1.0, 4.0)
		elif m.folk_chat_cd[id] <= 0.0:
			near.append(id)
	if near.is_empty():
		return
	var id: String = near[m.rng.randi() % near.size()]
	m.folk_chat_cd[id] = m.rnd(15.0, 25.0)
	var lines := folk_chat_lines(id)
	if lines.is_empty():
		return
	m.folk_chat_gap = 4.0
	folk_say(id, lines[m.rng.randi() % lines.size()])

func folk_say(id: String, line: String) -> void:
	var at := folk_chat_at(id)
	var anchor := Node3D.new()
	anchor.position = Vector3(at.x, m.shop_pos.y if id == "bori" else 0.0, at.y)
	m.add_child(anchor)
	var n0 := m.bubbles_said
	say_bubble(anchor, m.touch_words(tr(line)), 3.0)
	m.bubbles_said = n0 # the companions' count stays theirs
	(anchor.get_child(0) as Node3D).position.y = m.folk_bubble_y(id)
	m.folk_chat_last[id] = line
	m.folk_said.append([id, line])
	m.folk_bubbles.append({"anchor": anchor, "id": id, "t": 3.6 + (1.0 if m.touch_ui else 0.0)})
