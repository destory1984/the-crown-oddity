# Story: illustrated story scenes, opening beats, show_story and its lines.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const TOUCH_WORDS := [["Shift를 누르고 달리면", "막대를 끝까지 밀어 달리면"], ["Shift를 누르고", "막대를 끝까지 밀고"],
	["Shift를 누른 채", "막대를 끝까지 민 채"], ["Shift로 달리며 J", "막대를 끝까지 밀며 칼 단추"], ["Shift로", "막대를 끝까지 밀어"],
	["회복약은 4 키로 마신다", "회복약은 초록 하트로 마신다"], ["Space", "팔찌 단추"], ["손 단추", "팔찌 단추"]]
const STORY_MARGIN := 28.0

var small_pic := false # the open story's picture is the small corner one

func _init(main: Main) -> void:
	m = main

# the lantern nearest the start begins dark; touching the crown lights it
func darken_first_lamp() -> void:
	var best: OmniLight3D = null
	for l in m.lanterns:
		if not l.has_meta("glass") or l.position.x > 100.0: # marsh street lanterns only
			continue
		if best == null or Vector2(l.position.x, l.position.z).distance_to(Main.START) < Vector2(best.position.x, best.position.z).distance_to(Main.START):
			best = l
	m.dark_lamp = best
	var glass: MeshInstance3D = best.get_meta("glass")
	m.dark_glass_mat = glass.material_override
	glass.material_override = m.mat_color(Color("#3a3428"))

func begin_opening() -> void:
	m.story_step = 1
	m.set_quest("팔목의 팔찌를 만져 보자 (E)")

func touch_crown() -> void:
	if m.story_step != 1 or m.dark_lamp == null:
		return
	var l := m.dark_lamp
	m.dark_lamp = null
	var glass: MeshInstance3D = l.get_meta("glass")
	glass.material_override = m.dark_glass_mat
	m.burst(l.position, Color("#ffc46a"), 24, 2.5)
	m.burst(Vector3(m.player.x, m.ground_y + 1.6, m.player.z), Color("#9fd4ff"), 14, 1.5)
	m.sfx(523, 0.4, "sine", 0.3, 300)
	m.story_step = 2
	m.crown_pips = maxi(0, m.crown_pips - 1)
	m.pip_flash = 0.3
	m.set_quest("")
	m.save_game()
	show_story("res://art/story/02_lantern.jpg", Main.STORY.LANTERN)
	# a second later the brick pile beside the lamp stands up
	m.get_tree().create_timer(1.0).timeout.connect(func():
		m.spawn_enemy()
		var g: Dictionary = m.enemies[m.enemies.size() - 1]
		g.x = l.position.x + 1.2
		g.z = l.position.z + 0.8
		g.atk_cd = 1.5
		m.burst(Vector3(g.x, m.height_at(g.x, g.z) + 0.4, g.z), Color("#c9a066"), 20, 2.0)
		m.pop_num(Vector3(g.x, m.height_at(g.x, g.z) + 1.3, g.z), "!", Color("#ff5a4a"))
		m.sfx(110, 0.25, "square", 0.25, 80)
		m.get_tree().create_timer(4.0).timeout.connect(lantern_quest_late))

func lantern_quest_late() -> void: # met Bori within these 5 s: her quest stays (GPT playtests 2 -> 9)
	if m.story_step == 2:
		m.set_quest("쪽지에 적힌 서쪽 오두막을 찾아가자")

func meet_bori() -> void:
	m.story_step = 3
	m.save_game()
	m.set_quest(Main.BORI_QUEST)
	show_story("", Main.STORY.BORI)

# clear grass and reeds inside a circle (e.g. around the cave mouth)
func clear_vegetation(at: Vector2, r: float) -> void:
	for mm in m.veg_meshes:
		for i in mm.instance_count:
			var o: Vector3 = mm.get_instance_transform(i).origin
			if Vector2(o.x, o.z).distance_to(at) < r:
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.001), o))

func open_cave(at: Vector2, with_story := true) -> void:
	m.story_step = maxi(m.story_step, 5) # loading a later save rebuilds the cave mouth too: never wind the story back
	m.cave_pos = at + Vector2(0, -1.5)
	var marsh_tex: ImageTexture = m.ui.mini.map_tex if not m.ui.has("outside_map") or m.ui.mini.map_tex == m.ui.outside_map else m.ui.outside_map
	if marsh_tex != null:
		marsh_tex.set_image(m.with_stair_marks(marsh_tex, [m.cave_pos]).get_image())
	clear_vegetation(m.cave_pos, 2.2)
	var g := Node3D.new()
	g.position = Vector3(m.cave_pos.x, m.height_at(m.cave_pos.x, m.cave_pos.y), m.cave_pos.y)
	m.add_child(g)
	# seen from above: a dark pit in the ground ringed by stone blocks, with steps going down
	var pit := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.3
	cyl.height = 0.05
	pit.mesh = cyl
	pit.material_override = m.mat_color(Color("#07070c"))
	pit.position = Vector3(0, 0.03, 0)
	g.add_child(pit)
	var stone := m.mat_color(Color("#6a6e7a"))
	for k in 12:
		var a := TAU * k / 12.0
		var b := m.box(Vector3(0.55, 0.35, 0.55), stone)
		b.position = Vector3(cos(a) * 1.55, 0.17, sin(a) * 1.55)
		b.rotation.y = -a
		g.add_child(b)
	for k in 3:
		var st := m.box(Vector3(0.9, 0.06, 0.3), m.mat_color(Color("#4a4e5a").darkened(k * 0.25)))
		st.position = Vector3(0, 0.06 - k * 0.02, 0.8 - k * 0.35)
		g.add_child(st)
	var glow := OmniLight3D.new()
	glow.light_color = Color("#6aa8ff")
	glow.light_energy = 1.5
	glow.omni_range = 3.0
	glow.position = Vector3(0, 0.3, 0)
	g.add_child(glow)
	if not with_story:
		return
	m.burst(g.position + Vector3(0, 1, 0), Color("#9fd4ff"), 40, 4.0)
	m.sfx(196, 0.8, "sine", 0.3, 200)
	m.shake = 0.4
	m.save_game()
	show_story("res://art/story/05_brick_king.jpg", Main.STORY.BOSS_FALLS)
	m.set_quest(Main.CAVE_QUEST)

func touch_words(t: String) -> String:
	if not m.touch_ui or m.keys_last:
		return t
	for w in TOUCH_WORDS:
		t = t.replace(w[0], w[1])
	return m.touch_e.sub(t, "팔찌 단추", true)

# small: the picture sits small in the corner above the box and the game stays in view, as in a talk scene
# (the old painting in the last house's cupboard; the owner, 2026-10-25)
# clicks that were meant for the fight ran on into a story box that opened meanwhile and skipped it (the owner,
# 2026-10-28: the ending "클릭을 잘못했는데, 휙하고 지나가버렸어"): a click is not taken for 0.6 s after the box opens and
# 0.25 s after a new line (main.gd _input); keys stay as they were
const CLICK_OPEN_WAIT := 0.6
const CLICK_LINE_WAIT := 0.25
var opened_at := -10.0
var line_at := -10.0

func click_too_soon() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	return now - opened_at < CLICK_OPEN_WAIT or now - line_at < CLICK_LINE_WAIT

func show_story(path: String, lines: Array, small := false) -> void:
	opened_at = Time.get_ticks_msec() / 1000.0
	small_pic = small
	fit_story()
	m.story_lines = lines.duplicate()
	var tex: Texture2D = load(path) if path != "" else null
	m.ui.story_img.texture = tex
	m.ui.story_frame.visible = tex != null
	m.talk_mode = path == "" or small
	m.ui.story.color = Color(0.008, 0.016, 0.043, 0.35 if m.talk_mode else 0.6) # the game stays visible behind
	for side in ["left", "right"]:
		m.ui["por_" + side].texture = null
	m.ui.story.modulate.a = 0.0
	m.ui.story.visible = true
	m.story_open = true
	show_line(m.story_lines.pop_front())
	m.create_tween().tween_property(m.ui.story, "modulate:a", 1.0, 0.6)

func show_line(line: String) -> void:
	line_at = Time.get_ticks_msec() / 1000.0
	if line.begins_with("@"): # "@res://art/story/x.jpg": the picture changes here, then the next line shows
		m.ui.story_img.texture = load(line.substr(1))
		show_line(m.story_lines.pop_front())
		return
	var parts := line.split("|", true, 2)
	if parts.size() < 3:
		parts = PackedStringArray(["", "", line])
	m.ui.story_who.text = parts[0]
	var f := parts[1]
	if f == "-": # narration that also sends the other speaker off stage
		f = ""
		m.ui.por_right.texture = null
	var is_sora := parts[0] == "소라"
	var path := "res://art/ui/face_sora_%s.png" % f if is_sora else "res://art/ui/face_%s.png" % f
	m.ui.story_face.texture = load(path) if f != "" and ResourceLoader.exists(path) else null
	if m.talk_mode:
		# speaker's standing portrait lights up; the listener dims; narration dims both
		var por := "res://art/portrait/sora_%s.png" % f if is_sora else "res://art/portrait/%s.png" % f
		var side := "left" if is_sora else "right"
		if f != "" and ResourceLoader.exists(por):
			m.ui["por_" + side].texture = load(por)
			m.ui["por_" + side].set_meta("scale", POR_SCALE.get(f.get_slice("_", 0), 1.0))
		for sd in ["left", "right"]:
			var lit: bool = f != "" and sd == side
			m.ui["por_" + sd].modulate = Color(1, 1, 1) if lit else Color(0.45, 0.45, 0.55)
			set_por_top(sd, lit)
		m.ui.story_face.texture = null # the portrait already shows who is talking
	m.ui.story_text.position.x = 140.0 if m.ui.story_face.texture else 40.0
	if m.ui.story_cap.size.x > 0.0: # the width follows the start, so a centred line sits in the middle of the box
		m.ui.story_text.size.x = m.ui.story_cap.size.x - m.ui.story_text.position.x - 40.0
	m.ui.story_tab.visible = parts[0] != ""
	# translated here so the typewriter counts the shown text; lines wrap only at spaces (Ko.keep_words)
	var said := touch_words(tr(parts[2]))
	m.ui.story_text.text = Main.Ko.keep_words(said)
	m.ui.story_text.visible_characters = 0
	m.typing_k = float(m.ui.story_text.text.length()) / maxf(1.0, float(said.length()))
	m.typing = 0.0

func next_story() -> void:
	if m.ui.story_text.visible_characters != -1 and m.ui.story_text.visible_characters < m.ui.story_text.text.length():
		m.ui.story_text.visible_characters = -1 # first press finishes the line
		return
	if not m.story_lines.is_empty():
		show_line(m.story_lines.pop_front())
		m.sfx(660, 0.05, "triangle", 0.1)
		return
	close_story()

func close_story() -> void:
	m.story_open = false
	if m.after_story.is_valid():
		var f := m.after_story
		m.after_story = Callable()
		f.call_deferred()
	if m.story_step == 0 and not m.intro:
		begin_opening()
	var tw := m.create_tween()
	tw.tween_property(m.ui.story, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): m.ui.story.visible = false)

func start_game(with_story := true) -> void:
	if not m.intro:
		return
	m.intro = false
	if m.ng > 0 and m.story_step == 0:
		m.errands.round_banner()
	m.cam_yaw = Main.CAM_YAW # the title screen orbits the camera; play always starts from the same angle
	if m.pip_note != "": # an old save's pips came back: said once, when play starts
		var note := m.pip_note
		m.pip_note = ""
		m.get_tree().create_timer(1.2).timeout.connect(func(): m.toast(note))
	if with_story and (not m.loaded or m.story_step == 0): # a new round loads with the story back at 0
		show_story("res://art/story/01_wake.jpg", Main.STORY.WAKE)
	if m.ending_due:
		m.garden_zone.mold_breaks()
	m.sfx(392, 0.3, "triangle", 0.25)
	m.get_tree().create_timer(0.15).timeout.connect(func(): m.sfx(587, 0.5, "triangle", 0.25))
	for c in m.ui.hidden_for_intro:
		c.visible = true
	var tw := m.create_tween()
	tw.tween_property(m.ui.title, "modulate:a", 0.0, 1.2)
	tw.tween_callback(m.ui.title.queue_free)

const STORY_PAD := 20.0 # least space above and below the text block

# a standing portrait is as tall as the screen allows: 560 px at most, and never so tall that its head leaves the
# screen (645x480: 382 px). The speaker stands 10 px taller than the listener.
func por_height() -> float:
	var vh := m.get_viewport().get_visible_rect().size.y
	return clampf(vh - 80.0 - 10.0 - 8.0, 200.0, 560.0)

const POR_SCALE := {"kongal": 0.82} # portraits drawn smaller than Sora's height: the little ones

func set_por_top(side: String, lit: bool) -> void:
	var k: float = m.ui["por_" + side].get_meta("scale", 1.0)
	m.ui["por_" + side].offset_top = -80.0 - por_height() * k - (10.0 if lit else -10.0)

func fit_story() -> void:
	for sd in ["left", "right"]:
		set_por_top(sd, (m.ui["por_" + sd] as Control).modulate.r > 0.9)
	var vw := m.get_viewport().get_visible_rect().size.x
	var pw := minf(896.0, vw - 2.0 * (STORY_MARGIN + 12.0)) # the frame draws 10px outside its rect
	var ph := pw * 504.0 / 896.0
	m.ui.story_frame.offset_left = -pw / 2.0
	m.ui.story_frame.offset_right = pw / 2.0
	m.ui.story_frame.offset_top = -78.0 - ph / 2.0
	m.ui.story_frame.offset_bottom = -78.0 + ph / 2.0
	var cw := minf(940.0, vw - 2.0 * STORY_MARGIN)
	m.ui.story_cap.offset_left = -cw / 2.0
	m.ui.story_cap.offset_right = cw / 2.0
	m.ui.story_text.size.x = cw - m.ui.story_text.position.x - 40.0
	m.ui.story_hint.position.x = cw - 35.0
	# the box grows upward when the text needs more lines than its 144 px hold (big text on a small screen); the text
	# block (and the face beside it) sits in the middle, so the space above the first line equals the space below the last
	# (the user, 2026-10-25: the narration sat low in the box). The name tab hangs on the top edge and ends 14 px inside.
	var th: float = m.ui.story_text.get_minimum_size().y
	var ch := maxf(Main.STORY_BOX_H, th + 2.0 * STORY_PAD)
	m.ui.story_cap.offset_top = m.ui.story_cap.offset_bottom - ch
	m.ui.story_text.size.y = th
	m.ui.story_text.position.y = (ch - th) / 2.0
	m.ui.story_face.position.y = (ch - m.ui.story_face.size.y) / 2.0
	m.ui.story_hint.position.y = ch - 28.0
	if small_pic: # a square at the top right, between the minimap and the HUD bars, its right edge in line with the box
		var vh := m.get_viewport().get_visible_rect().size.y
		var top := 30.0
		var s := minf(vh * 0.45, vh + m.ui.story_cap.offset_top - 24.0 - top) # the owner: 268 px was too small, 540 too big; 405 px at 900 high
		var right := cw / 2.0 - 12.0
		m.ui.story_frame.offset_right = right
		m.ui.story_frame.offset_left = right - s
		m.ui.story_frame.offset_top = -vh / 2.0 + top
		m.ui.story_frame.offset_bottom = -vh / 2.0 + top + s
