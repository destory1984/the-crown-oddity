# HUD: panels, labels, bars, build_hud, mate bars, moon pips, touch layer, gold keys.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

func _init(main: Main) -> void:
	m = main

# the signpost by the east bridge: the only way from the marsh to the village
# Built after the map, props, plants and monsters so the random draws that place them are the same as before.
func village_sign() -> void:
	# a short deck over the east edge water to the village road
	for bx in [46, 47]:
		for bz in [20, 21]:
			m.map[m.idx(bx, bz)] = Main.BRIDGE
			m.hgt[m.idx(bx, bz)] = 0.08
	m.world_build.lego_deck(46, 46, 20)
	var g := Node3D.new()
	var wood: Material = m.mat_color(Color("#6a4a2e"))
	var pole: MeshInstance3D = m.box(Vector3(0.14, 1.5, 0.14), wood)
	pole.position = Vector3(0, 0.75, 0)
	g.add_child(pole)
	var board: MeshInstance3D = m.box(Vector3(1.9, 0.42, 0.08), m.mat_color(Color("#c8a46a")))
	board.position = Vector3(0, 1.3, 0.08)
	g.add_child(board)
	var t := m.sign_icon("village", 0.5)
	t.position = Vector3(0, 1.3, 0.14)
	g.add_child(t)
	var glow := m.box(Vector3(0.2, 0.26, 0.2), m.glow_mat(Color("#ffc46a"), 1.6))
	glow.position = Vector3(0, 1.62, 0)
	g.add_child(glow)
	g.position = Vector3(43.6, m.height_at(43.6, 18.6), 18.6)
	m.add_child(g)
	m.rocks.append({"x": 43.6, "z": 18.6, "r": 0.25})

const MATES_TOP := 162.0 # lap 6: the first companion row sits below the gem row (its gems end at y 152); the name label starts 2 px above
const STATUS_H := 158.0 # the bars, the moon gauge and the gem row end here (gems y 146 + 6, 6 px air)

# 3. companions' status under Sora's bars: portrait, name and a bar that fills as their next blow comes ready
func build_mate_hud(root: Control) -> void:
	m.ui.mate_rows = []
	for i in 2:
		var row := Control.new()
		row.position = Vector2(140, MATES_TOP + i * 34) # layout_top moves the rows beside the big portrait ring; they start under the token gems (hud.gd token_spots, y 146 + 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(row)
		var face := TextureRect.new()
		face.texture = load("res://art/portrait/%s.png" % ["mulgyeol", "jae"][i])
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.size = Vector2(28, 28)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		label(row, ["물결", "노을"][i], Vector2(34, -2), 16, Color("#f6d27a")) # 13 -> 15 -> 16, the state 11 -> 13 -> 14 (the owner, 2026-10-27/28)
		var back := ColorRect.new()
		back.color = Color(0.1, 0.1, 0.15, 0.8)
		back.position = Vector2(34, 21)
		back.size = Vector2(110, 6)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(back)
		var fill := ColorRect.new()
		fill.color = Color("#7ac8ff") if i == 0 else Color("#c8c8d0")
		fill.position = Vector2(34, 21)
		fill.size = Vector2(110, 6)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(fill)
		var act := label(row, "", Vector2(84, 0), 14, Color("#c9bfa6"))
		act.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.visible = false
		m.ui.mate_rows.append({"row": row, "fill": fill, "act": act})

func update_mate_hud() -> void:
	var data := [[m.mate, m.mate_cd, 1.0], [m.mate2, m.mate2_cd, 1.4]]
	for i in 2:
		var r: Dictionary = m.ui.mate_rows[i]
		var node: Node3D = data[i][0]
		r.row.visible = node != null and not m.intro and not m.in_cave and not m.ui.get("picture", false)
		if not r.row.visible:
			continue
		var id: String = ["mulgyeol", "noeul"][i]
		var frac: float = clampf(m.mates.mate_health(id) / m.mate_max(), 0.0, 1.0)
		r.fill.size.x = 110.0 * frac
		r.fill.color = Color("#e05a4a") if frac < 0.3 else Color("#6ad07a")
		var fighting: bool = m.enemies.any(func(e): return not e.dead and not e.get("prop", false) and Vector2(e.x - node.position.x, e.z - node.position.z).length() < 5.0)
		if m.mate_down[id] > 0.0:
			r.act.text = tr("쉬는 중 %d초") % int(ceil(m.mate_down[id]))
		else:
			r.act.text = tr("싸우는 중") if fighting else tr("따라가는 중")

# ---- phones: the touch layer over the HUD, and the four menu keys two by two left of the minimap (the stick takes
# the bottom left); the zoom keys stand in a column left of them, clear of the boss bar and the quest line
func enable_touch() -> void:
	m.touch_ui = true
	m.keys_last = false
	if m.touch_layer == null:
		m.touch_layer = Control.new()
		m.touch_layer.set_script(load("res://touch.gd"))
		m.touch_layer.main = m
		m.ui.root.add_child(m.touch_layer)
	var col := [m.ui.hint, m.ui.sound_btn, m.ui.journal_btn, m.ui.settings_btn] # two by two, 60 px like the zoom coins and the skills, 8 px apart, left of the minimap
	for i in col.size():
		place(col[i], Control.PRESET_TOP_RIGHT, Vector2(-194 - 8 - 60 - (1 - i % 2) * 68, 8 + (i / 2) * 68), Vector2(60, 60))
	use_touch_help(true)
	m.cfg.text = maxi(int(m.cfg.text), 2) # text a size up on a small screen
	m.apply_settings()
	await m.get_tree().process_frame # the sheets know their size a frame later
	for sheet in [m.ui.ways, m.ui.help]:
		fit_sheet(sheet)
	fit_journal()
	m.ui.set_card.pivot_offset = m.ui.set_card.size / 2.0
	m.ui.set_card.scale = Vector2.ONE * minf(1.0, (m.get_viewport().get_visible_rect().size.y - 16.0) / m.ui.set_card.size.y)
	m.menus.size_back_keys(m.ui.set_card)
	m.fit_shop()

# the controls sheet and the settings' Help page show the touch keys on phones, the keyboard and mouse elsewhere
func use_touch_help(on: bool) -> void:
	for r in m.ui.help_keys_rows:
		for c in r:
			c.visible = not on
	for r in m.ui.help_touch_rows:
		for c in r:
			c.visible = on
	m.ui.help_rows = m.ui.help_touch_rows if on else m.ui.help_keys_rows
	for r in m.ui.set_help_keys:
		r[0].visible = not on
		r[1].get_parent().visible = not on
		if r[2] != null:
			(r[2] as Control).visible = not on
	for r in m.ui.set_help_touch:
		r[0].visible = on
		r[1].get_parent().visible = on
		if r[2] != null:
			(r[2] as Control).visible = on
	m.ui.set_stacks[1] = m.ui.set_help_touch if on else m.ui.set_help_keys

# ---- the top-centre blocks laid out from real rects (the user, 2026-10-25: the quest line ran over the companions' rows)
# The status panel, the dial with the zone name and the companions' rows are fixed boxes in hud.gd and build_mate_hud;
# the minimap, the menu keys, the zoom keys and the boss bar are read off their controls.
# the portrait ring is as big as the minimap (186 px, the owner 2026-10-27, again 10-28: it stayed small on the
# owner's screen); only a window under 760 px keeps the old 126 px ring, as the bars (to x 548) would meet the minimap
func big_portrait() -> bool:
	return m.get_viewport().get_visible_rect().size.x >= 760.0

# the four bars with their numbers and the moon gauge
func status_rect() -> Rect2:
	var half := 109.0 if m.touch_ui else 0.0 # phones draw the bars half as long (hud.gd bar_w)
	return Rect2(0, 0, 548 - half, STATUS_H) if big_portrait() else Rect2(0, 0, 472 - half, STATUS_H)

# sun and moon dial, zone name and sub-line, 60 px lower under the big ring
func dial_rect() -> Rect2:
	return Rect2(0, 228, 240, 112) if big_portrait() else Rect2(0, 168, 240, 112)
const QUEST_PAD := 14.0 # the gold ornaments reach this far past the text sideways, 12 px up and down
var quest_deco := Rect2() # the ornaments' box around the quest text, drawn by hud.gd
var side_label: Label = null # the running side step, a small dim line under the quest
var side_want := false # a side step is running; shown unless the layout drops it
var side_off := false # the layout dropped the side line: no room for it beside the other boxes
var side_h := 0.0 # its height with the gap, counted into the ornament box
var quest_big := true # the bigger quest text (a screen 700 px tall or more): lines 30 px, side 26 px
var quest_lines := 0 # lines the quest text wraps to (autoplay quest_layout)

func mates_rect() -> Rect2:
	var out := Rect2()
	var first := true
	for r in m.ui.mate_rows:
		if r.row.visible:
			var rc := Rect2(r.row.position, Vector2(146, 28))
			out = rc if first else out.merge(rc)
			first = false
	return out

func boss_rect() -> Rect2:
	var b: Control = m.ui.boss
	return Rect2(b.global_position, b.size * b.scale)

# the middle of the screen where Sora stands: 240 x 180 px round her (the user's lap 6 report: on a 645x480 screen the quest
# line sat over her and her companions)
func player_rect() -> Rect2:
	if m.camera == null or m.intro or m.touch_ui: # the touch layout keeps its own bands
		return Rect2()
	var at := Vector3(m.player.x, m.ground_y + 0.8, m.player.z)
	if m.camera.is_position_behind(at):
		return Rect2()
	return Rect2(m.camera.unproject_position(at) - Vector2(120.0, 90.0), Vector2(240.0, 180.0))

# every HUD box the quest line has to stay clear of
func quest_blocks(with_player := true) -> Array:
	var out: Array = [status_rect(), dial_rect()]
	var pr := player_rect()
	if with_player and pr.size != Vector2.ZERO:
		out.append(pr)
	if not m.touch_ui:
		var vs0 := m.get_viewport().get_visible_rect().size
		out.append(Rect2(vs0.x - 304.0, vs0.y - 104.0, 296.0, 100.0)) # the skill slots
		out.append(Rect2(vs0.x - 80.0, vs0.y - 130.0, 66.0, 30.0)) # the gold box
	if mates_rect().size != Vector2.ZERO:
		out.append(mates_rect())
	if m.ui.boss.visible:
		out.append(boss_rect())
	out.append(m.ui.mini.get_parent().get_global_rect())
	for b in [m.ui.hint, m.ui.sound_btn, m.ui.journal_btn, m.ui.settings_btn]:
		if (b as Control).visible:
			out.append((b as Control).get_global_rect())
	if m.touch_layer != null:
		out.append_array(touch_rects())
	return out

# the drawn box of every touch key (touch.gd keys(): centre and radius): zoom coins, bracelet, guard, dodge, attack and the skill icons
func touch_rects() -> Array:
	var out: Array = []
	if m.touch_layer == null:
		return out
	var tk: Dictionary = m.touch_layer.keys()
	for n in tk:
		out.append(Rect2(tk[n][0] - Vector2.ONE * tk[n][1], Vector2.ONE * tk[n][1] * 2.0))
	return out

func update_side() -> void:
	if side_label == null:
		side_label = label(m.ui.quest, "", Vector2.ZERO, 17, Color(0.95, 0.9, 0.78, 0.92)) # 14 px at 72% was too small to read (the owner, 2026-10-26)
		side_label.add_theme_constant_override("outline_size", 4)
		side_label.add_theme_color_override("font_outline_color", Color("#02040b"))
		side_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var s: String = m.shore.side_step() if m.ui.quest.visible and not m.intro else ""
	if m.ui.quest.visible and not m.intro and m.shore_wave < 0 and m.shore_float.is_empty() and m.errands.letter_side_line() != "":
		s = m.errands.letter_side_line() # a running shore fight keeps the line; waiting shore steps give way to the letter
	if s == "" and m.ui.quest.visible and not m.intro:
		s = m.cave.post_side()
	var shown := m.touch_words(tr(s)) if s != "" else ""
	if side_label.text != shown:
		side_label.text = shown
	side_want = shown != ""
	side_label.visible = side_want and not side_off
	var want := m.quest_shown(m.quest_raw) # the prep hint follows potions and gold
	if (m.quest_raw.begins_with(Main.BORI_QUEST) or m.errands.QUEST_FOLK.any(func(q): return m.quest_raw.contains(q[0]))) and m.ui.quest.text != want:
		m.ui.quest.text = want

func layout_top() -> void:
	var vs := m.get_viewport().get_visible_rect().size
	var wide: bool = vs.x >= 1180.0 and not m.touch_ui
	for i in m.ui.mate_rows.size():
		m.ui.mate_rows[i].row.position.x = 206.0 if big_portrait() else 140.0
	var mates := mates_rect()
	var x0 := maxf(296.0, mates.end.x + 8.0) if m.touch_ui else (mates.end.x + 8.0 if mates.size != Vector2.ZERO else (210.0 if big_portrait() else 244.0)) # right of the left column
	# boss bar: top centre on a wide screen; else in the free band between the left column and the minimap, or under the
	# minimap and shrunk when that band is too narrow for its 440 px
	var b: Control = m.ui.boss
	b.pivot_offset = Vector2.ZERO
	var bx: float
	var by: float
	var bs := 1.0
	if wide:
		bx = maxf(vs.x / 2.0 - 220.0, status_rect().end.x + 8.0) # clear of the bars' numbers on a screen only just wide
		by = 14.0
	elif vs.x - 202.0 - x0 >= 440.0:
		bx = (x0 + vs.x - 202.0) / 2.0 - 220.0
		by = STATUS_H + 2.0 # under the gem row
	elif m.touch_ui and vs.x - 202.0 - x0 >= 220.0: # a phone: shrunk in the band beside the minimap, so the quest line keeps the rows under it clear of the shield and dodge keys
		bx = x0
		by = STATUS_H + 2.0
		bs = minf(1.0, (vs.x - 202.0 - x0) / 440.0)
	else:
		bx = x0
		by = 202.0
		bs = minf(1.0, (vs.x - 8.0 - x0) / 440.0)
	b.scale = Vector2.ONE * bs
	b.offset_left = bx - vs.x / 2.0
	b.offset_right = b.offset_left + 440.0
	b.offset_top = by
	b.offset_bottom = by + 40.0
	if not m.ui.quest.visible:
		quest_deco = Rect2()
		quest_lines = 0
		return
	# 20 px quest and 17 px side line on a big screen (the owner, 2026-10-26: too small); a small window or the
	# phones' smaller canvas keeps 17 / 15 so the line still finds a free band beside the bars and the boss bar
	var big := vs.y >= 700.0
	quest_big = big
	m.ui.quest.add_theme_font_size_override("font_size", 20 if big else 17)
	if side_label != null:
		side_label.add_theme_font_size_override("font_size", 17 if big else 14)
	var blocks := quest_blocks()
	var boss_end := boss_rect().end.y if b.visible else 0.0
	# candidates: [left limit, right limit, top, centre on the screen instead of the band]
	var cands: Array = []
	if wide:
		cands.append([status_rect().end.x + 8.0, vs.x - 202.0, 62.0, true])
		if b.visible:
			cands.append([status_rect().end.x + 8.0, vs.x - 202.0, boss_end + 16.0, true])
	var band_r := vs.x - 202.0 # the band's right edge: the minimap column; on touch also the shield key's left edge
	if m.touch_layer != null:
		band_r = minf(band_r, (m.touch_layer.keys().guard[0] as Vector2).x - (m.touch_layer.keys().guard[1] as float) - 8.0)
	cands.append([x0, band_r, STATUS_H + 12.0, false]) # its ornaments reach 12 px up: clear of the gem row's box
	if b.visible:
		cands.append([x0, band_r, boss_end + 12.0, false])
	var low := maxf(maxf(mates.end.y, boss_end), 194.0) + 14.0
	cands.append([dial_rect().end.x + 4.0, vs.x - 8.0, low, false])
	cands.append([8.0, vs.x - 8.0, dial_rect().end.y + 14.0, false])
	# a narrow screen has no free band at the top: the line goes under Sora, between her and the keys and skills
	var pr := player_rect()
	var gold_left := vs.x - 92.0 if not m.touch_ui else vs.x - 8.0
	if pr.size != Vector2.ZERO:
		cands.append([8.0, gold_left, pr.end.y + 14.0, true])
		cands.append([8.0, gold_left, pr.end.y + 2.0, true])
	# first with Sora's middle kept clear (and the side line shown; a screen with no room for the extra line shows the quest
	# alone), then the old way when a long text finds no such place (her middle may be crossed)
	var best: Dictionary = {}
	side_off = false
	best = _pick_quest(cands, [blocks], vs)
	if not best.ok and side_label != null and side_want:
		side_off = true
		best = _pick_quest(cands, [blocks], vs)
		if not best.ok:
			side_off = false
	if not best.ok:
		best = _pick_quest(cands, [blocks, quest_blocks(false)], vs)
	var final := _fit_quest(best.xl, best.xr, best.y, best.centre, vs) # leave the label as the chosen candidate
	quest_deco = final.deco
	quest_lines = final.lines
	if side_label != null:
		side_label.visible = side_want and not side_off

# the first candidate that fits with none of the given block lists crossed (else the best of the last list)
func _pick_quest(cands: Array, block_lists: Array, vs: Vector2) -> Dictionary:
	var best: Dictionary = {}
	for pass_blocks in block_lists:
		best = {}
		for c in cands:
			var fit := _fit_quest(c[0], c[1], c[2], c[3], vs)
			var ok: bool = fit.deco.position.x >= 0.0 and fit.deco.end.x <= vs.x and fit.deco.position.y >= 0.0 and fit.deco.end.y <= vs.y
			for r in pass_blocks:
				if fit.deco.intersects((r as Rect2).abs()):
					ok = false
			fit["ok"] = ok
			if ok and fit.lines <= 2:
				best = fit
				break
			if ok and (best.is_empty() or not best.ok or fit.lines < best.lines):
				best = fit
			elif best.is_empty():
				best = fit
		if best.ok:
			break
	return best

# put the quest label in one candidate band and return its ornament box and line count
func _fit_quest(xl: float, xr: float, y: float, centre: bool, vs: Vector2) -> Dictionary:
	var q: Label = m.ui.quest
	q.autowrap_mode = TextServer.AUTOWRAP_OFF
	q.size = Vector2.ZERO
	var tw := q.get_minimum_size().x + 2.0
	var w := maxf(40.0, minf(minf(tw, xr - xl - 2.0 * QUEST_PAD), 620.0)) # never negative in a tiny window
	var cx := vs.x / 2.0 if centre else (xl + xr) / 2.0
	cx = clampf(cx, xl + QUEST_PAD + w / 2.0, xr - QUEST_PAD - w / 2.0)
	if w < tw:
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.offset_left = cx - w / 2.0 - vs.x / 2.0
	q.offset_right = cx + w / 2.0 - vs.x / 2.0
	q.offset_top = y
	var lh := 30.0 if quest_big else 26.0
	q.offset_bottom = y + lh
	var lines := maxi(1, q.get_line_count())
	var h := maxf(lh, q.get_minimum_size().y) if w < tw else lh
	q.offset_bottom = y + h
	side_h = 0.0
	if side_label != null and side_want and not side_off:
		var sw := side_label.get_minimum_size().x + 2.0
		side_label.size = Vector2(sw, 24.0 if quest_big else 20.0)
		side_label.position = Vector2((w - sw) / 2.0, h + 2.0)
		side_h = 26.0 if quest_big else 22.0
	var half := maxf(w / 2.0 + QUEST_PAD, 60.0)
	return {"xl": xl, "xr": xr, "y": y, "centre": centre, "lines": lines, "deco": Rect2(cx - half, y - 12.0, half * 2.0, h + 24.0 + side_h)}

# a sheet in the middle of a small screen, shrunk to fit its height
func fit_sheet(c: Control) -> void:
	var vs := m.get_viewport().get_visible_rect().size
	var sz := c.size
	place(c, Control.PRESET_CENTER, -sz / 2.0, sz)
	c.pivot_offset = sz / 2.0
	c.scale = Vector2.ONE * minf(1.0, minf((vs.y - 16.0) / sz.y, (vs.x - 16.0) / sz.x))
	m.menus.size_back_keys(c)

# the journal keeps its bottom-left place beside the menu keys while the whole sheet fits above the bottom edge; on a small
# window or a touch screen it is centred and shrunk like the other sheets (lap 6: at 960x540 its top sat at y -128)
func fit_journal() -> void:
	var j: Control = m.ui.journal
	var vs := m.get_viewport().get_visible_rect().size
	if not m.touch_ui and vs.y - 668.0 >= 8.0 and vs.x >= 816.0:
		place(j, Control.PRESET_BOTTOM_LEFT, Vector2(8, -668), Vector2(800, 567))
		j.scale = Vector2.ONE
		j.pivot_offset = Vector2.ZERO
		m.menus.size_back_keys(j)
	else:
		place(j, Control.PRESET_CENTER, Vector2(-400, -283.5), Vector2(800, 567))
		fit_sheet(j)

# the autoplay test turns the touch layer off again, and the menu keys go back to the bottom left
func disable_touch() -> void:
	m.touch_ui = false
	m.touch_move = Vector2.ZERO
	m.touch_keys.clear()
	if m.touch_layer != null:
		m.touch_layer.queue_free()
		m.touch_layer = null
	var col := [m.ui.hint, m.ui.sound_btn, m.ui.journal_btn, m.ui.settings_btn]
	for i in col.size():
		place(col[i], Control.PRESET_BOTTOM_LEFT, Vector2(8 + i * 76, -93), Vector2(68, 68))
	for sheet in [m.ui.journal, m.ui.ways, m.ui.help, m.ui.set_card]:
		sheet.scale = Vector2.ONE
		m.menus.size_back_keys(sheet)
	fit_journal()
	place(m.ui.ways, Control.PRESET_BOTTOM_LEFT, Vector2(8, -401), Vector2(400, 300))
	use_touch_help(false)
	for c in [m.ui.hint, m.ui.sound_btn, m.ui.journal_btn, m.ui.settings_btn, m.ui.mini.get_parent()]: # the touch layer hid them under sheets
		c.visible = not m.intro
	m.ui.hint.visible = not m.intro and not m.ui.help.visible
	m.fit_shop()
	m.menus.layout_help()
	m.menus.layout_settings()

# ---- the bottom-left buttons: gold diamond keys in the skills' family (draft 4 of five, double gold rim with a thin
# line symbol, the user's pick 2026-10-24), 68 px like the skills and 8 px apart, their centres on the skills' line
# (59 px over the bottom edge; the owner, 2026-10-25); the key is in the tooltip
func key_tex(kind: String) -> Texture2D:
	return load("res://art/ui/key_%s.png" % kind)

func icon_button(root: Control, kind: String, key: String, tip: String, x: float, fn: Callable) -> Button:
	var b := Button.new()
	b.icon = key_tex(kind)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = tr(tip) + " (" + key + ")"
	b.focus_mode = Control.FOCUS_NONE
	b.theme = m.menus.get_menu_theme()
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_color_override("icon_normal_color", Color(0.9, 0.9, 0.9))
	b.add_theme_color_override("icon_hover_color", Color.WHITE)
	b.add_theme_color_override("icon_pressed_color", Color(0.75, 0.75, 0.75))
	place(b, Control.PRESET_BOTTOM_LEFT, Vector2(x, -93), Vector2(68, 68)) # the skills' size, centres on their line (the owner, 2026-10-25)
	b.pressed.connect(fn)
	root.add_child(b)
	return b

# ---------------------------------------------------------------- HUD
func panel(parent: Control, pos: Vector2, size: Vector2, anchor := Control.PRESET_TOP_LEFT) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.063, 0.078, 0.133, 0.86)
	sb.border_color = Color(0.725, 0.635, 0.45, 0.55)
	sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	place(p, anchor, pos, size)
	return p

# pin a control to a corner/edge: pos is the offset from that anchor point
func place(c: Control, anchor: int, pos: Vector2, size: Vector2) -> void:
	c.set_anchors_preset(anchor)
	c.offset_left = pos.x
	c.offset_top = pos.y
	c.offset_right = pos.x + size.x
	c.offset_bottom = pos.y + size.y

# a label that always wraps at the given width: it sits in a box of that width, and the box sets its width
# (a bare Label in the settings sheet grew into one long line past the sheet's edge at 16 px)
func wrap_label(parent: Control, text: String, pos: Vector2, width: float, size: int, color: Color) -> Label:
	var box := VBoxContainer.new()
	box.position = pos
	box.size = Vector2(width, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	var l := label(box, Main.Ko.keep_words(m.tr(text)), Vector2.ZERO, size, color)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # translated here, before the words are joined
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func label(parent: Control, text: String, pos: Vector2, size := 16, color := Color("#efe6cf"), font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font if font else m.ui_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func bar(parent: Control, pos: Vector2, color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.13, 0.13)
	bg.position = pos
	bg.size = Vector2(200, 6)
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.color = color
	fg.size = Vector2(200, 6)
	bg.add_child(fg)
	return fg

func build_hud() -> void:
	m.hud = CanvasLayer.new()
	m.hud.layer = 1
	m.add_child(m.hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.hud.add_child(root)
	m.ui.root = root
	# the old boxy panels stay in a hidden holder (their labels still carry values); hud.gd draws the HUD
	var legacy := Control.new()
	legacy.set_anchors_preset(Control.PRESET_FULL_RECT)
	legacy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legacy.visible = false
	root.add_child(legacy)
	m.ui.legacy = legacy
	var deco := Control.new()
	deco.set_script(load("res://hud.gd"))
	deco.main = m
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(deco)
	m.ui.hud = deco

	var zone := panel(legacy, Vector2(14, 12), Vector2(190, 58))
	label(zone, "◆", Vector2(14, 16), 16, Color("#b9a273"))
	m.ui.zone_name = label(zone, "갈대늪", Vector2(42, 6), 19)
	m.ui.zone_sub = label(zone, "등불여울 건널목", Vector2(42, 32), 13, Color("#a99d84"))

	var stats := panel(legacy, Vector2(14, 72), Vector2(396, 92))
	label(stats, "레벨", Vector2(14, 8), 11, Color("#a99d84"))
	m.ui.lv = label(stats, "1", Vector2(18, 24), 30)
	for row in [["체력", 10, Color("#d83a44")], ["기세", 30, Color("#f08a2a")], ["기력", 50, Color("#e9d39a")]]:
		label(stats, row[0], Vector2(56, row[1] - 4), 11, Color("#a99d84"))
	m.ui.hp = bar(stats, Vector2(100, 10), Color("#d83a44"))
	m.ui.mp = bar(stats, Vector2(100, 30), Color("#f08a2a"))
	m.ui.sp = bar(stats, Vector2(100, 50), Color("#e9d39a"))
	label(stats, "경험", Vector2(56, 66), 11, Color("#a99d84"))
	m.ui.xp = bar(stats, Vector2(100, 70), Color("#8de07a"))
	m.ui.xpt = label(stats, "", Vector2(310, 63), 12, Color("#8de07a"))
	m.ui.spt = label(stats, "", Vector2(310, 43), 12)
	m.ui.hpt = label(stats, "", Vector2(310, 3), 12)
	m.ui.mpt = label(stats, "", Vector2(310, 23), 12)

	# shop screen: Bori standing on the left, a display board of item cards on the right,
	# her line at the bottom; the game stays visible, dimmed, behind
	var shop := ColorRect.new()
	shop.color = Color(0.008, 0.016, 0.043, 0.55)
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shop)
	var keeper := TextureRect.new()
	keeper.texture = load("res://art/portrait/bori.png")
	keeper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keeper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	keeper.flip_h = true # she faces the board
	keeper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop.add_child(keeper)
	place(keeper, Control.PRESET_CENTER_LEFT, Vector2(30, -30), Vector2(220, 300)) # a quarter of the old 440x600 (the user found it too big, 2026-10-23), feet where they were
	m.ui.shop_keeper = keeper
	var board := Control.new()
	board.set_script(load("res://frame.gd"))
	board.kind = "box"
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop.add_child(board)
	place(board, Control.PRESET_CENTER, Vector2(-160, -270), Vector2(620, 420))
	m.ui.shop_board = board
	var btab := Control.new()
	btab.set_script(load("res://frame.gd"))
	btab.kind = "tab"
	board.add_child(btab)
	btab.position = Vector2(40, -18)
	btab.size = Vector2(220, 32)
	var st := label(btab, "보리 할머니의 상점", Vector2(0, 4), 16, Color("#f6d27a"))
	st.size = Vector2(220, 24)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.ui.shop_gold = label(board, "", Vector2(400, 14), 16, Color("#ffd84a"))
	m.ui.shop_gold.size = Vector2(190, 22)
	m.ui.shop_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	m.ui.shop_btns = []
	for i in Main.SHOP.size():
		var it: Dictionary = Main.SHOP[i]
		var card := Control.new()
		card.set_script(load("res://frame.gd"))
		card.kind = "tab"
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.add_child(card)
		card.position = Vector2(30 + (i % 2) * 290, 52 + (i / 2) * 176)
		card.size = Vector2(270, 160)
		var icon := TextureRect.new()
		var ip := "res://art/ui/item_%d.png" % i
		icon.texture = load(ip) if ResourceLoader.exists(ip) else null
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(12, 12)
		icon.size = Vector2(96, 96)
		card.add_child(icon)
		label(card, "%d" % (i + 1), Vector2(10, 6), 12, Color("#a99d84"))
		label(card, it.name, Vector2(118, 18), 17)
		var dsc := label(card, Main.Ko.keep_words(m.tr(it.desc)), Vector2(118, 46), 13, Color("#a99d84"))
		dsc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # translated here, before the words are joined
		dsc.size = Vector2(140, 40)
		dsc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var b := Button.new()
		b.text = tr("◆ %d  사기") % it.price
		b.add_theme_font_override("font", m.ui_font)
		b.add_theme_font_size_override("font_size", 15)
		b.position = Vector2(118, 112)
		b.size = Vector2(138, 34)
		var idx_ := i
		b.pressed.connect(func(): m.buy(idx_))
		card.add_child(b)
		m.ui.shop_btns.append(b)
	var say := Control.new()
	say.set_script(load("res://frame.gd"))
	say.kind = "box"
	say.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop.add_child(say)
	place(say, Control.PRESET_CENTER_BOTTOM, Vector2(-470, -150), Vector2(940, 100))
	m.ui.shop_line = say
	var stab := Control.new()
	stab.set_script(load("res://frame.gd"))
	stab.kind = "tab"
	say.add_child(stab)
	stab.position = Vector2(40, -18)
	stab.size = Vector2(150, 32)
	var sn := label(stab, "보리 할머니", Vector2(0, 4), 16, Color("#f6d27a"))
	sn.size = Vector2(150, 24)
	sn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.ui.shop_say = label(say, "", Vector2(40, 32), 19)
	m.ui.shop_say.size = Vector2(860, 40)
	m.ui.shop_keys = label(say, "1 → 4 사기  ·  E / Esc 닫기", Vector2(680, 70), 12, Color("#a99d84"))
	m.ui.shop_back = m.menus.back_key(shop, func(): m.toggle_shop(false)) # phones only (fit_shop)
	m.ui.shop_back.visible = false
	shop.visible = false
	m.ui.shop = shop
	m.ui.shop_hint = label(root, "E  보리 할머니의 상점", Vector2.ZERO, 16, Color("#fff1c8"))
	place(m.ui.shop_hint, Control.PRESET_CENTER_BOTTOM, Vector2(-200, -260), Vector2(400, 24))
	m.ui.shop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.ui.shop_hint.add_theme_constant_override("outline_size", 6)
	m.ui.shop_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	m.ui.shop_hint.visible = false

	# boss health bar, top centre, shown while the Brick King is awake
	var bb := panel(root, Vector2(-220, 14), Vector2(440, 40), Control.PRESET_CENTER_TOP)
	var bn := label(bb, "벽돌왕", Vector2(0, 2), 13, Color("#f6b951"))
	m.ui.boss_name = bn
	bn.size = Vector2(440, 18)
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bbg := ColorRect.new()
	bbg.color = Color(0.13, 0.13, 0.13)
	bbg.position = Vector2(10, 24)
	bbg.size = Vector2(420, 8)
	bb.add_child(bbg)
	m.ui.boss_bar = ColorRect.new()
	m.ui.boss_bar.color = Color("#9a4ad8")
	m.ui.boss_bar.size = Vector2(420, 8)
	bbg.add_child(m.ui.boss_bar)
	bb.visible = false
	m.ui.boss = bb

	m.fade_rect = ColorRect.new()
	m.fade_rect.color = Color(0, 0, 0, 0)
	m.fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.hud.add_child(m.fade_rect)

	# quest line, top centre under the boss bar
	m.ui.quest = label(root, "", Vector2.ZERO, 20, Color("#fff1c8")) # 17 -> 20 px (the owner, 2026-10-26: too small)
	place(m.ui.quest, Control.PRESET_CENTER_TOP, Vector2(-300, 62), Vector2(600, 30))
	m.ui.quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.ui.quest.add_theme_constant_override("outline_size", 6)
	m.ui.quest.add_theme_color_override("font_outline_color", Color("#02040b"))
	m.ui.quest.visible = false

	# blue edge while a flash dodge slows the world
	var tint := ColorRect.new()
	tint.color = Color(0.35, 0.65, 1.0, 0.16)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.visible = false
	root.add_child(tint)
	root.move_child(tint, 0)
	m.ui.slowmo_tint = tint

	# sky dial under the stats: sun and moon travel the arc with the clock
	var sky := Control.new()
	sky.set_script(load("res://sky.gd"))
	sky.main = m
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.clip_contents = true
	legacy.add_child(sky)
	place(sky, Control.PRESET_TOP_LEFT, Vector2(14, 166), Vector2(190, 64))

	# circular minimap, top right
	var mask := TextureRect.new()
	var circle := Image.create(186, 186, false, Image.FORMAT_RGBA8)
	circle.fill(Color(0, 0, 0, 0))
	for y in 186:
		for x in 186:
			if Vector2(x - 92.5, y - 92.5).length() < 92:
				circle.set_pixel(x, y, Color.WHITE)
	mask.texture = ImageTexture.create_from_image(circle)
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	place(mask, Control.PRESET_TOP_RIGHT, Vector2(-194, 8), Vector2(186, 186)) # 8 px from the top and right edges
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mask)
	var mini := Control.new()
	mini.set_script(load("res://minimap.gd"))
	mini.size = Vector2(186, 186)
	mini.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mimg := Image.create(Main.N, Main.N, false, Image.FORMAT_RGBA8)
	var pal := [Color("#1d4f7c"), Color("#16302e"), Color("#2c4a48"), Color("#c8962a")]
	for z in Main.N:
		for x in Main.N:
			mimg.set_pixel(x, z, pal[m.map[m.idx(x, z)]])
	for z in range(1, Main.N - 1):
		for x in range(1, Main.N - 1):
			var w := m.map[m.idx(x, z)] == Main.WATER
			if not w:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if m.map[m.idx(x + d.x, z + d.y)] == Main.WATER:
						mimg.set_pixel(x, z, Color("#3fa0c8"))
				if m.hgt[m.idx(x, z)] > 0.5 and (x + z) % 3 == 0:
					mimg.set_pixel(x, z, Color("#23423e"))
	mini.map_tex = ImageTexture.create_from_image(mimg)
	m.ui.mini = mini
	mini.main = m
	mask.add_child(mini)

	# skills, bottom right
	var names := ["회오리", "불씨탄", "빛파동", "×3"]
	var keys_ := ["U", "I", "O", "4"]
	var icons := ["○", "●", "◇", "♥"]
	var icon_cols := [Color("#9fd4ff"), Color("#ff8a2a"), Color("#fff1a0"), Color("#8dff9a")]
	m.ui.cd = []
	for i in 4:
		var slot := panel(legacy, Vector2(-290 + i * 70, -86), Vector2(56, 48), Control.PRESET_BOTTOM_RIGHT)
		label(slot, keys_[i], Vector2(3, 1), 10, Color("#e9dfc4"))
		label(slot, icons[i], Vector2(18, 10), 22, icon_cols[i])
		var cd := ColorRect.new()
		cd.color = Color(0, 0, 0, 0.65)
		cd.size = Vector2(56, 0)
		slot.add_child(cd)
		m.ui.cd.append(cd)
		var n := label(legacy, names[i], Vector2(0, 0), 12)
		place(n, Control.PRESET_BOTTOM_RIGHT, Vector2(-290 + i * 70, -36), Vector2(56, 20))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i == 3:
			m.ui.pots = n
	var gold := panel(legacy, Vector2(-80, -130), Vector2(66, 30), Control.PRESET_BOTTOM_RIGHT)
	m.ui.gold = label(gold, "◆ 0", Vector2(10, 4), 14, Color("#ffd84a"))

	# controls help, starts hidden; H or the button toggles it
	var help := m.menus.menu_panel(root, Vector2(8, -588), Vector2(340, 487), Control.PRESET_BOTTOM_LEFT) # ends 8 px above the buttons
	help.mouse_filter = Control.MOUSE_FILTER_STOP
	var help_title := label(help, "조작법", Vector2(62, 20), 13, Color("#a99d84"))
	var rows := [["WASD / 방향키", "이동"], ["Shift", "달리기"], ["J / 왼쪽 클릭", "공격 (연속기)"], ["K / 오른쪽 클릭", "구르기 (때맞추면 섬광)"], ["L / 가운데 클릭", "막기 (때맞추면 반격, Lv4부터 1초 모아 J)"],
		["U I O / 1 2 3", "스킬 (기세 30·15·60)"], ["4", "회복약"], ["E", "말 걸기, 상자 열기, 들어가기, 팔찌 쓰기"], ["Z X / 휠", "확대·축소"], ["T R P", "3시간 뒤로 / 비 / 사진"], ["F8", "처음 자리로 (진행은 그대로)"], ["F9", "처음부터 (두 번 눌러 저장 지우기)"], ["Q", "일지 (할 일과 곁이야기)"], ["B", "배경 음악 켜기/끄기"], ["H", "조작법 숨기기"]]
	m.ui.help_rows = []
	for i in rows.size():
		var hk := label(help, rows[i][0], Vector2(14, 60 + i * 27), 13, Color("#e9dfc4"))
		var hv := label(help, rows[i][1], Vector2(150, 60 + i * 27), 15)
		m.menus.scale_text(hk)
		m.menus.scale_text(hv)
		m.ui.help_rows.append([hk, hv])
	m.ui.help_keys_rows = m.ui.help_rows
	# phones: the touch keys, each row with the key's own picture (use_touch_help swaps the two sets)
	var trows := [["touch_stick_base", "왼쪽 막대", "이동, 끝까지 밀면 달리기"], ["touch_attack", "칼", "공격 (연속기)"],
		["touch_dodge", "화살표", "구르기 (때맞추면 섬광)"], ["touch_guard", "방패 (누른 채)", "막기 (때맞추면 반격, Lv4부터 1초 모아 칼)"],
		["touch_crown", "팔찌 (E)", "말 걸기, 상자 열기, 들어가기, 팔찌 쓰기"],
		["skill_0", "기술 그림 셋", "회오리·불씨탄·빛파동 (기세 30·15·60)"], ["skill_3", "초록 물약 병", "회복약"],
		["key_zoom_in", "돋보기 둘", "확대·축소"], ["key_help", "물음표", "조작법"], ["key_sound", "스피커", "효과음 켜고 끄기"],
		["key_journal", "할 일 판", "일지 (할 일과 곁이야기)"], ["key_gear", "톱니바퀴", "설정"]]
	m.ui.help_touch_rows = []
	for r in trows:
		var ic := TextureRect.new()
		ic.texture = load("res://art/ui/%s.png" % r[0])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		help.add_child(ic)
		var tk := label(help, r[1], Vector2.ZERO, 13, Color("#e9dfc4"))
		var tv := label(help, r[2], Vector2.ZERO, 15)
		m.menus.scale_text(tk)
		m.menus.scale_text(tv)
		for c in [ic, tk, tv]:
			c.visible = false
		m.ui.help_touch_rows.append([tk, tv, ic])
	m.menus.back_key(help, func(): m.toggle_help(false)).set_meta("title", help_title)
	help.visible = false
	m.ui.help = help
	# the journal (Q): what to do now, the side stories found so far and the keepsakes Sora carries
	var journal := m.menus.menu_panel(root, Vector2(8, -668), Vector2(800, 567), Control.PRESET_BOTTOM_LEFT)
	journal.mouse_filter = Control.MOUSE_FILTER_STOP
	var journal_title := label(journal, "일지", Vector2(62, 20), 14, Color("#a99d84"))
	m.menus.menu_rule(journal, Vector2(14, 60), 772)
	m.ui.journal_text = m.menus.journal_column(journal, Vector2(14, 70), Vector2(420, 487))
	m.ui.journal_text2 = m.menus.journal_column(journal, Vector2(450, 70), Vector2(336, 437)) # the right column: feats and keepsakes; ends above the ending button (y 515)
	m.menus.back_key(journal, func(): m.toggle_journal(false)).set_meta("title", journal_title)
	m.ui.ending_btn = m.menus.set_button(journal, "엔딩 다시 보기", Vector2(626, 515), Vector2(160, 38), func(): m.garden_zone.replay_ending())
	journal.visible = false
	m.ui.journal = journal
	var ways := m.menus.menu_panel(root, Vector2(8, -401), Vector2(400, 300), Control.PRESET_BOTTOM_LEFT)
	var wt := label(ways, "", Vector2(16, 12), 18, Color("#e9dfc4")) # 15 was too small (the owner, 2026-10-25)
	wt.size = Vector2(368, 276)
	wt.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	m.ui.ways_text = wt
	ways.visible = false
	m.ui.ways = ways
	m.ui.hint = icon_button(root, "help", "H", "조작법", 8, func(): m.toggle_help(true)) # 68 px keys 8 px apart, centred on the skills' line
	m.ui.sound_btn = icon_button(root, "sound", "M", "효과음", 84, m.toggle_sound)
	m.menus.refresh_sound_btn()
	m.ui.journal_btn = icon_button(root, "journal", "Q", "일지", 160, func(): m.toggle_journal(not m.ui.journal.visible))
	m.ui.settings_btn = icon_button(root, "gear", "Esc", "설정", 236, func(): m.toggle_settings(not m.settings_open))
	m.menus.build_settings(root)
	if m.touch_ui:
		enable_touch()

	m.ui.toast = label(root, "", Vector2(0, 0), 20)
	place(m.ui.toast, Control.PRESET_CENTER_BOTTOM, Vector2(-300, -220), Vector2(600, 30))
	m.ui.toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.ui.toast.add_theme_constant_override("outline_size", 6)
	m.ui.toast.add_theme_color_override("font_outline_color", Color.BLACK)

	var banner := Control.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)
	m.ui.banner_title = label(banner, "레벨 2", Vector2(-200, 120), 40)
	m.ui.banner_title.size = Vector2(400, 50)
	m.ui.banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := label(banner, "최대 체력 +12 · 공격력 +3", Vector2(-300, 170), 18)
	m.ui.banner_sub = sub
	for l in [m.ui.banner_title, sub]:
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color("#02040b"))
	sub.size = Vector2(600, 30)
	m.ui.banner_title.size = Vector2(600, 50)
	m.ui.banner_title.position = Vector2(-300, 120)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate.a = 0.0
	m.ui.banner = banner

	# story illustration layer (above the HUD, below the title): the picture is shown whole over a
	# dimmed, enlarged copy of itself, with a dialogue box (face, name, typewriter text) at the bottom
	var story := ColorRect.new()
	story.color = Color(0.008, 0.016, 0.043, 1.0)
	story.set_anchors_preset(Control.PRESET_FULL_RECT)
	story.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(story)
	var back := TextureRect.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.modulate = Color(0.25, 0.28, 0.4)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story.add_child(back)
	# the illustration sits in a gold frame in the middle; the game stays visible, dimmed, around it
	var pic_frame := Control.new()
	pic_frame.set_script(load("res://frame.gd"))
	pic_frame.kind = "picture"
	pic_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story.add_child(pic_frame)
	place(pic_frame, Control.PRESET_CENTER, Vector2(-448, -330), Vector2(896, 504))
	var img := TextureRect.new()
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.clip_contents = true
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic_frame.add_child(img)
	# standing portraits for talk scenes (no big picture): Sora on the left, the other speaker on the right
	for side in ["left", "right"]:
		var pr := TextureRect.new()
		pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		story.add_child(pr)
		if side == "left":
			place(pr, Control.PRESET_BOTTOM_LEFT, Vector2(20, -640), Vector2(460, 560))
		else:
			place(pr, Control.PRESET_BOTTOM_RIGHT, Vector2(-480, -640), Vector2(460, 560))
		m.ui["por_" + side] = pr
	# ornate dialogue box with a name plate on its top edge
	var cap := Control.new()
	cap.set_script(load("res://frame.gd"))
	cap.kind = "box"
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story.add_child(cap)
	place(cap, Control.PRESET_CENTER_BOTTOM, Vector2(-470, -168), Vector2(940, 144))
	var tab := Control.new()
	tab.set_script(load("res://frame.gd"))
	tab.kind = "tab"
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(tab)
	tab.position = Vector2(40, -18)
	tab.size = Vector2(190, 32)
	var who := label(tab, "", Vector2(0, 4), 16, Color("#f6d27a"))
	who.size = Vector2(190, 24)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var face := TextureRect.new()
	face.position = Vector2(22, 26)
	face.size = Vector2(100, 100)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	cap.add_child(face)
	var cap_text := label(cap, "", Vector2(140, 34), 23) # the owner, 2026-10-25: a little bigger than 20
	cap_text.size = Vector2(760, 90)
	cap_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER # the owner, 2026-10-27: centre the lines in the box
	cap_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING # wrapped as the whole line, so fit_story sees every line while it types
	# the 다음 button, the box's only way on with the mouse or a finger: it shows once the line has finished typing and
	# sits on the box's bottom edge, clear of the text (the owner, 2026-10-29: "아무데나 클릭하게 하지말고, 버튼을 눌러서
	# 넘기게 하자 (전투하다가 클릭해서 넘어가는 일이 잦음)", "글자가 화면에 드르르륵 나타나고 -> 키가 생기고 -> 누르면 다음
	# 화면으로"); E, Space and Enter press it too (main.gd _input)
	var cap_hint := Button.new()
	cap_hint.text = "다음 ▶"
	cap_hint.add_theme_font_override("font", m.ui_font)
	cap_hint.add_theme_font_size_override("font_size", 16)
	for look in ["normal", "hover", "pressed"]:
		cap_hint.add_theme_stylebox_override(look, m.menus.flat(Color("#16304f") if look == "hover" else Color("#091627"), Color("#e8b018"), 2, 10, 4.0))
		cap_hint.add_theme_color_override("font_" + look + "_color" if look != "normal" else "font_color", Color("#f6d27a"))
	cap_hint.focus_mode = Control.FOCUS_NONE
	cap_hint.size = Vector2(Main.STORY_NEXT_W, 34)
	cap_hint.position = Vector2(940 - Main.STORY_NEXT_W - 30, 144 - 18)
	cap_hint.visible = false
	cap_hint.pressed.connect(func(): m.story.next_button())
	cap.add_child(cap_hint)
	m.ui.story_tab = tab
	m.ui.story_frame = pic_frame
	m.ui.story_cap = cap
	m.ui.story_hint = cap_hint
	story.visible = false
	m.ui.story = story
	m.ui.story_img = img
	cap_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	m.ui.story_text = cap_text
	m.ui.story_face = face
	m.ui.story_who = who
	m.ui.story_more = cap_hint

	# title screen in the house style: pixel lettering 20% from the top, gold subtitle, pale hint
	var title := ColorRect.new()
	title.color = Color(0.008, 0.016, 0.043, 0.5)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 20)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_child(col)
	col.anchor_left = 0.0
	col.anchor_right = 1.0
	col.anchor_top = 0.2
	col.anchor_bottom = 1.0
	var logo := TextureRect.new()
	logo.texture = load("res://art/title/title.png") # the pixel logo stays (the owner, 2026-10-27); only the words below take the serif
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR # GPT logo is drawn at high resolution
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 300)
	col.add_child(logo)
	var serif: FontFile = (load("res://fonts/jua/Jua-Regular.title.woff2") as FontFile).duplicate()
	serif.fallbacks = [m.ui_font] # the subtitle and hint in round Jua (title font draft 3, 2026-10-27), edged in the logo's navy; other letters (translations) fall back
	var tsub := label(col, "백 년의 정원이 당신을 기다린다", Vector2.ZERO, 29, Color("#fff5dc")) # the owner, 2026-10-29 (was "갈대 늪 너머, 이상한 것들이 깨어난다")
	tsub.add_theme_font_override("font", serif)
	tsub.add_theme_constant_override("outline_size", 9)
	tsub.add_theme_color_override("font_outline_color", Color("#1d2a6b"))
	tsub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var thint := label(col, "아무 키나 눌러 시작", Vector2.ZERO, 20, Color("#f6c64a"))
	thint.add_theme_font_override("font", serif)
	m.ui.title_hint = thint
	thint.add_theme_constant_override("outline_size", 7)
	thint.add_theme_color_override("font_outline_color", Color("#1d2a6b"))
	thint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var blink := thint.create_tween().set_loops()
	blink.tween_property(thint, "modulate:a", 0.3, 0.9)
	blink.tween_property(thint, "modulate:a", 1.0, 0.9)
	# music on/off in the title's top-right corner for now (the owner, 2026-10-27); B does the same here
	var tmus := m.menus.back_key(title, m.music.toggle_music)
	tmus.remove_meta("back")
	tmus.anchor_left = 1.0
	tmus.anchor_right = 1.0
	tmus.offset_left = -52
	tmus.offset_right = -8
	m.ui.title_music = tmus
	m.menus.refresh_sound_btn()
	m.ui.title = title
	for c in root.get_children():
		if c != title:
			c.visible = false
	m.ui.hidden_for_intro = root.get_children().filter(func(c): return c != title and c != m.ui.help and c != m.ui.journal and c != m.ui.ways and c != m.ui.settings and c != m.ui.boss and c != m.ui.shop and c != m.ui.shop_hint and c != m.ui.slowmo_tint and c != m.ui.story and c != m.ui.quest and c != m.ui.legacy)
	for k in ["zone", "stats"]:
		pass

# what keeps the moon light from filling where she stands still by a lantern, or "" when nothing does (or she is
# not by one): day by a lit lantern, or night by an unlit one
func rest_why(night_now: bool) -> String:
	if m.crown_pips >= m.pip_max or m.story_open or Vector2(m.player.vx, m.player.vz).length() >= 0.3 or m.fly_q >= 3:
		return ""
	var me := Vector2(m.player.x, m.player.z)
	var lit := false
	var dark := false
	for l in m.lanterns:
		if l != m.dark_lamp and Vector2(l.position.x - me.x, l.position.z - me.y).length() < 2.0:
			if l.get_meta("dark", false):
				dark = true
			else:
				lit = true
	if lit and not night_now:
		return "낮에는 달빛이 차지 않는다. 밤 9시부터 켜진 등불 곁에서 쉬자" + ("" if m.touch_ui else " (T: 3시간 뒤로)")
	if dark and not lit and night_now:
		return "꺼진 등불 곁에서는 달빛이 차지 않는다"
	return ""

func update_pips(dt: float) -> void:
	m.pip_flash -= dt
	m.lamp_safe = false
	var by_oak := m.forest_zone.oak_warm()
	var night_now := m.is_night() or m.in_clock() or m.in_workshop() or by_oak # underground the clock room and the deep workshop rest as at night, and by the old oak's warm roots
	var why := rest_why(night_now)
	m.rest_why_t = m.rest_why_t + dt if why != "" else 0.0
	if why == "":
		m.rest_why_said = false
	elif m.rest_why_t > 1.2 and not m.rest_why_said:
		m.rest_why_said = true
		m.toast(why)
	var heal: bool = m.has_cushion and night_now and m.player.hp < m.player.max_hp
	if (m.crown_pips >= m.pip_max or not night_now) and not heal:
		m.rest_t = 0.0
		return
	var me := Vector3(m.player.x, 0, m.player.z)
	var near_lamp := false
	for l in m.lanterns:
		if not l.get_meta("dark", false) and l != m.dark_lamp and Vector2(l.position.x - me.x, l.position.z - me.z).length() < 2.0:
			near_lamp = true
	near_lamp = near_lamp or by_oak
	var still := Vector2(m.player.vx, m.player.vz).length() < 0.3
	# by a lit lantern at night, standing still with no key for 0.8 s, monsters do not notice her (monsters.gd) and only
	# one right beside her (2.5 tiles) stops the rest (the owner, 2026-10-28: "마을에 있는 등불에서만 차는구나": out in
	# the fields a monster within 6 tiles always came for her)
	m.lamp_safe = near_lamp and night_now and still and m.t - m.last_input_t > 0.8
	var calm := true
	for e in m.enemies:
		if not e.dead and Vector2(e.x - me.x, e.z - me.z).length() < (2.5 if m.lamp_safe else 6.0) and m.line_clear(Vector2(me.x, me.z), Vector2(e.x, e.z)):
			calm = false # only a monster that can reach her sight counts, not one behind a wall
	var jar := m.fly_q >= 3
	if not calm and (near_lamp or jar) and still and m.crown_pips < m.pip_max:
		if not m.rest_said:
			m.rest_said = true
			m.toast("가까이 괴물이 있어 쉴 수 없다")
	else:
		m.rest_said = false
	# 갈대 방석: resting at night by a lit lantern (or with the jar) heals 4 HP a second, full crown or not
	if heal and (near_lamp or jar) and calm and still:
		m.player.hp = minf(float(m.player.max_hp), m.player.hp + 4.0 * dt)
		m.cushion_t += dt
		if m.cushion_t >= 1.0:
			m.cushion_t = 0.0
			m.burst(Vector3(m.player.x, m.ground_y + 0.1, m.player.z), Color("#9fe07a"), 6, 0.8)
	if m.crown_pips >= m.pip_max or not night_now:
		m.rest_t = 0.0
		return
	m.rest_need = (3.0 if near_lamp else 6.0) * (0.6 if m.has_tea else 1.0) # twice as fast as 6 / 12 (the owner, 2026-10-26)
	if (near_lamp or jar) and calm and still:
		m.rest_t += dt
		if m.in_hill and not m.in_cloud():
			m.hill_zone.rest_seeds(dt)
		if by_oak: # warm steam off the roots while she rests there
			m.steam_t += dt
			if m.steam_t >= 1.0:
				m.steam_t = 0.0
				m.burst(Vector3(Main.FOREST.OAK_C.x, 0.2, Main.FOREST.OAK_C.y + 1.3), Color("#f2ead8"), 4, 0.6)
		if m.rest_t >= m.rest_need:
			m.rest_t = 0.0
			m.crown_pips += 1
			m.burst(Vector3(m.player.x, m.ground_y + 1.6, m.player.z), Color("#9fd4ff"), 10, 1.2)
			m.sfx(880, 0.15, "sine", 0.15)
	else:
		m.rest_t = 0.0
