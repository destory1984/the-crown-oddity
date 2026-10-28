# Menus: Space Oddity look, settings, help, sound toggle, journal.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")
const Combat := preload("res://sys/combat.gd")

var m: Main

const SETTINGS_PATH := "user://settings.json"
const MENU_GOLD := Color("#f6b951")
const ODD_INK := Color("#e3efff")
const ODD_MUTED := Color("#b6cbe0")
const SOURCE_URL := "https://github.com/destory1984/the-crown-oddity" # the public site repo holds the source too
const ICON_SVG := {
	"help": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path stroke-width="2.4" d="M8.5 9a3.5 3.5 0 1 1 5.3 3c-1.1.7-1.8 1.4-1.8 2.8"/><circle cx="12" cy="18.6" r="0.6" stroke-width="1.6"/></svg>',
	"journal": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 4h11a1.5 1.5 0 0 1 1.5 1.5V20H7a2 2 0 0 1 0-4h11.5"/><path d="M5 18V6a2 2 0 0 1 2-2"/><path d="M13 4v6l-1.8-1.3L9.4 10V4"/></svg>',
	"gear": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5.6"/><circle cx="12" cy="12" r="1.9"/><path d="M12 3.2v3.2M12 17.6v3.2M3.2 12h3.2M17.6 12h3.2M5.8 5.8L8 8M16 16l2.2 2.2M5.8 18.2L8 16M16 8l2.2-2.2"/></svg>',
	"sound": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9.5h3l4.5-3.8v12.6L7 14.5H4z"/><path d="M15 9.2a4 4 0 0 1 0 5.6"/><path d="M17.6 6.6a7.6 7.6 0 0 1 0 10.8"/></svg>',
	"mute": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9.5h3l4.5-3.8v12.6L7 14.5H4z"/><path d="M15.5 9.5l5 5M20.5 9.5l-5 5"/></svg>',
	"music": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 17V6.5l9-2V15"/><path d="M9.5 9.5l9-2"/><circle cx="7" cy="17.4" r="2.5"/><circle cx="16" cy="15.4" r="2.5"/></svg>',
	"music_off": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#eef3ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 17V6.5l9-2V15"/><path d="M9.5 9.5l9-2"/><circle cx="7" cy="17.4" r="2.5"/><circle cx="16" cy="15.4" r="2.5"/><path d="M4 4l16 16"/></svg>',
	"back": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><g transform="translate(0.25 -2.25)"><path d="M9 7L4.5 11.5 9 16"/><path d="M5 11.5h9a5 5 0 0 1 0 10h-2"/></g></svg>',
}
const JOURNAL_HEADS := ["지금 할 일", "곁이야기", "도전 과제", "지닌 것", "익힌 기술"]

func _init(main: Main) -> void:
	m = main

func flat(bg: Color, rim: Color, rim_w := 1, radius := 8, pad := 6.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = rim
	sb.set_border_width_all(rim_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad + 6
	sb.content_margin_right = pad + 6
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	sb.anti_aliasing = true
	return sb

func glass_normal() -> StyleBoxFlat:
	return flat(Color("#0d1a3acc"), Color("#9fb4ff66"))

func glass_hover() -> StyleBoxFlat:
	return flat(Color("#26456199"), Color("#93d2ff88"))

func glass_chosen() -> StyleBoxFlat:
	return flat(Color("#0d1a3acc"), MENU_GOLD)

func get_menu_theme() -> Theme:
	if m.menu_theme != null:
		return m.menu_theme
	m.menu_theme = Theme.new()
	m.menu_theme.set_stylebox("normal", "Button", glass_normal())
	m.menu_theme.set_stylebox("hover", "Button", glass_hover())
	m.menu_theme.set_stylebox("pressed", "Button", glass_hover())
	m.menu_theme.set_stylebox("disabled", "Button", flat(Color("#0d1a3a73"), Color("#9fb4ff2a")))
	m.menu_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	m.menu_theme.set_color("font_color", "Button", ODD_INK)
	m.menu_theme.set_color("font_hover_color", "Button", Color.WHITE)
	m.menu_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	m.menu_theme.set_color("font_disabled_color", "Button", Color(0.89, 0.94, 1.0, 0.45))
	m.menu_theme.set_font("font", "Button", m.ui_font)
	m.menu_theme.set_font_size("font_size", "Button", 13)
	return m.menu_theme

func odd_icon(kind: String) -> ImageTexture:
	if m.icon_cache.has(kind):
		return m.icon_cache[kind]
	var img := Image.new()
	img.load_svg_from_string(ICON_SVG[kind], 2.0) # 48 px, drawn at 22 - 24 px on screen like Space Oddity's
	var tex := ImageTexture.create_from_image(img)
	m.icon_cache[kind] = tex
	return tex

# the corner key that leaves a sheet or card, as Space Oddity's .backKey: 44 x 44 at 8 px from the top-left corner,
# a 1 px #9fb4ff66 line, 12 px corners, #0b1630d9 fill, the return arrow drawn at 20 px
func back_key(parent: Control, fn: Callable) -> Button:
	var b := Button.new()
	b.icon = odd_icon("back")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tr("이전 화면으로")
	for st in ["normal", "hover", "pressed"]:
		var sb := flat(Color("#0b1630d9") if st == "normal" else Color("#26456199"), Color("#9fb4ff66") if st == "normal" else Color("#93d2ff88"), 1, 12, 0.0)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		b.add_theme_stylebox_override(st, sb)
	b.position = Vector2(8, 8)
	b.size = Vector2(44, 44)
	b.pressed.connect(fn)
	b.set_meta("back", true) # size_back_keys finds it
	parent.add_child(b)
	return b

# the corner back keys of a sheet: on phones at least 56 px on screen (the sheet's own shrink taken out), else 44 px;
# a title beside the key moves along
func size_back_keys(c: Control) -> void:
	for b in c.get_children():
		if not b.has_meta("back"):
			continue
		var s := ceilf(56.0 / c.scale.x) if m.touch_ui else 44.0
		b.position = Vector2(4, 2) if m.touch_ui else Vector2(8, 8)
		b.size = Vector2(s, s)
		var title: Label = b.get_meta("title") if b.has_meta("title") else null # a null default still errors
		if title != null:
			title.position.x = b.position.x + s + 8.0 if m.touch_ui else 62.0

func menu_panel(root: Control, pos: Vector2, size: Vector2, anchor: int) -> Panel:
	var p := m.hud_build.panel(root, pos, size, anchor)
	var sb := flat(Color("#091627"), Color("#53718b"), 1, 14, 0.0)
	sb.shadow_color = Color(0, 0, 0, 0.53)
	sb.shadow_size = 24
	sb.shadow_offset = Vector2(0, 12)
	p.add_theme_stylebox_override("panel", sb)
	p.theme = get_menu_theme()
	return p

# a thin pale rule
func menu_rule(parent: Control, pos: Vector2, width: float) -> void:
	var r := ColorRect.new()
	r.color = Color("#9fb4ff33")
	r.position = pos
	r.size = Vector2(width, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	for k in ["text", "sora_px"]: # shake, tilt and nums are no longer options: an old "off" in the file is ignored
		if d.has(k):
			m.cfg[k] = d[k]
	m.cfg.text = clampi(int(m.cfg.text), 0, Main.TEXT_SIZES.size() - 1)
	m.muted = bool(d.get("muted", m.muted))
	m.music_on = bool(d.get("music", true))

func save_settings() -> void:
	var d := m.cfg.duplicate()
	d["muted"] = m.muted
	d["music"] = m.music_on
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func apply_settings() -> void:
	if m.tilt_rect != null: # off on iPhone and iPad browsers: there the copy of the screen it blurs stuck on the first frame,
		# so the world stood still under a moving HUD (the user on an iPhone, 2026-10-24)
		m.tilt_rect.visible = bool(m.cfg.tilt) and not OS.has_feature("web_ios")
	var k: float = Main.TEXT_SIZES[int(m.cfg.text)]
	for tb in m.text_bases:
		var c: Control = tb[0]
		c.add_theme_font_size_override("normal_font_size" if c is RichTextLabel else "font_size", int(round(tb[1] * k)))
	refresh_sound_btn()
	if m.ui.has("help_rows"):
		layout_help()
	if m.ui.has("set_stacks"):
		layout_settings()
	if m.ui.has("set_rows"):
		for key in m.ui.set_rows:
			var b: Button = m.ui.set_rows[key]
			var on: bool = (not m.muted) if key == "sound" else bool(m.cfg[key])
			b.text = tr("켜짐") if on else tr("꺼짐")
			# Space Oddity: a pressed button gets a gold rim and gold text
			b.add_theme_stylebox_override("normal", glass_chosen() if on else glass_normal())
			b.add_theme_color_override("font_color", MENU_GOLD if on else ODD_INK)
		m.ui.set_minus.disabled = int(m.cfg.text) <= 0
		m.ui.set_plus.disabled = int(m.cfg.text) >= Main.TEXT_SIZES.size() - 1

# the controls sheet grows with the text size: the key column is as wide as its longest key, the sheet as wide
# as its longest line (the user, 2026-10-23: at a bigger size the lines ran out past the sheet's edge)
func layout_help() -> void:
	var k: float = Main.TEXT_SIZES[int(m.cfg.text)]
	var kw := 0.0
	var dw := 0.0
	for r in m.ui.help_rows:
		kw = maxf(kw, (r[0] as Label).get_minimum_size().x)
		dw = maxf(dw, (r[1] as Label).get_minimum_size().x)
	var step := 27.0 * k
	var top := 72.0 if m.touch_ui else 60.0 # phones: under the bigger back key
	var iw := 0.0
	if m.ui.help_rows[0].size() > 2: # the touch rows lead with the key's picture
		step = 31.0 * k
		iw = 28.0 * k + 8.0
	for i in m.ui.help_rows.size():
		if m.ui.help_rows[i].size() > 2:
			var ic: TextureRect = m.ui.help_rows[i][2]
			ic.position = Vector2(14, top + i * step - 2.0 * k)
			ic.size = Vector2.ONE * 28.0 * k
		(m.ui.help_rows[i][0] as Label).position = Vector2(14 + iw, top + i * step + 1)
		(m.ui.help_rows[i][1] as Label).position = Vector2(14 + iw + kw + 24, top + i * step)
	var w: float = maxf(340.0, 14 + iw + kw + 24 + dw + 22)
	var h: float = top + m.ui.help_rows.size() * step + 18
	m.place(m.ui.help, Control.PRESET_BOTTOM_LEFT, Vector2(8, -101 - h), Vector2(w, h)) # 8 px over the keys
	if m.touch_ui:
		m.hud_build.fit_sheet(m.ui.help)

# the settings pages stack their rows by the height the text wraps to, so a longer line or a bigger text size
# pushes the button and the next row down instead of running into them (waits a frame for the wrap)
func layout_settings() -> void:
	await m.get_tree().process_frame
	for k in m.ui.set_stacks.size():
		var stack: Array = m.ui.set_stacks[k]
		if stack.is_empty():
			continue
		var x := 122.0 # the text column starts past the widest title
		for row in stack:
			x = maxf(x, (row[0] as Label).get_minimum_size().x + 16.0)
		for row in stack:
			var box := (row[1] as Control).get_parent() as Control
			box.position.x = x
			box.size = Vector2(626.0 - x, 0.0) # a box never shrinks by itself: drop the height it took while the text was wrapped narrow
			(row[1] as Control).size.y = 0.0
			if row[2] != null:
				(row[2] as Control).position.x = x
		await m.get_tree().process_frame # the text wraps again at its new width
		var y := 0.0
		for row in stack:
			var title: Label = row[0]
			var text: Control = row[1]
			title.position.y = y
			(text.get_parent() as Control).position.y = y
			var h: float = maxf(title.get_minimum_size().y, text.get_minimum_size().y) # what the text needs, not a stale size (GPT lap 6: the Help page was 6012 px tall)
			if row[2] != null:
				(row[2] as Control).position.y = y + h + 6.0
				h += 6.0 + 34.0
			y += h + (18.0 if row[2] != null else 14.0)
		m.ui.set_pages[k].custom_minimum_size.y = maxf(400.0, y)

# the first n lines of 바뀐 것, each translated, wrapping only at spaces (Ko.keep_words); an empty line before every
# "· " entry that follows another line of text, so each fix stands apart (the owner, 2026-10-27)
func news_text(n: int) -> String:
	var out: Array = []
	for s in Main.CHANGES.slice(0, n):
		var line: String = tr(s)
		if line.begins_with("· ") and not out.is_empty() and out[-1] != "":
			out.append("")
		out.append(line)
		if out.size() == 1: # under the progress line: how many changes so far (the owner, 2026-10-27)
			out.append(tr("지금까지 고친 것: 모두 %d가지") % changes_count())
	return Main.Ko.keep_words("\n".join(out))

# every change listed: an entry with "    - " lines under it counts each of them, an entry without counts once
func changes_count() -> int:
	var total := 0
	var open := false
	var subs := 0
	for s in Main.CHANGES:
		if s.begins_with("· "):
			if open:
				total += maxi(subs, 1)
			open = true
			subs = 0
		elif open and s.begins_with("    - "):
			subs += 1
	if open:
		total += maxi(subs, 1)
	return total

func scale_text(l: Control) -> void:
	m.text_bases.append([l, l.get_theme_font_size("normal_font_size" if l is RichTextLabel else "font_size")])

func set_button(parent: Control, text: String, pos: Vector2, size: Vector2, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", m.ui_font)
	b.add_theme_font_size_override("font_size", 15)
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(fn)
	parent.add_child(b)
	return b

# the settings popup (the user wanted a popup of fitting size, not the whole screen): a dimmed backdrop that closes it
# when clicked, and a centred 688 x 584 card in Space Oddity's dialog look (#091627, #53718b line, 14 px corners) holding
# the corner back key and the 640 px column: the head (title at left, sound and 가- 가+ at right), four equal tabs,
# the page as label rows with the description beside and a small button under it, and the way back at the foot
# "v0.0.1 · 2026-10-23" from project.godot (application/config/version and .../updated, written by dev.py ship)
func version_text() -> String:
	var v := str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	var d := str(ProjectSettings.get_setting("application/config/updated", ""))
	return "v" + v + (" · " + d if d != "" else "")

func build_settings(root: Control) -> void:
	var sp := Panel.new() # the backdrop
	sp.set_anchors_preset(Control.PRESET_FULL_RECT)
	sp.add_theme_stylebox_override("panel", flat(Color(0.02, 0.04, 0.1, 0.55), Color(0, 0, 0, 0), 0, 0))
	sp.theme = get_menu_theme()
	sp.mouse_filter = Control.MOUSE_FILTER_STOP
	sp.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			toggle_settings(false))
	root.add_child(sp)
	var card := Panel.new()
	m.ui.set_card = card
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -344
	card.offset_right = 344
	card.offset_top = -292
	card.offset_bottom = 292
	var sb := flat(Color("#091627"), Color("#53718b"), 1, 14, 0.0)
	sb.shadow_color = Color(0, 0, 0, 0.53)
	sb.shadow_size = 24
	sb.shadow_offset = Vector2(0, 12)
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP # clicks on the card do not reach the backdrop
	sp.add_child(card)
	back_key(card, func(): toggle_settings(false))
	var col := Control.new() # the 640 px column
	col.position = Vector2(24, 12) # the head row shares its line with the back key
	col.size = Vector2(640, 556)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var h1 := m.hud_build.label(col, "설정", Vector2(48, 2), 24, ODD_INK)
	h1.size = Vector2(300, 40)
	# the version and the day it shipped, small beside the title on its baseline (the user moved it up from under the
	# title; dev.py ship raises it by one per feature)
	var title_w := m.ui_font.get_string_size("설정", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var ver := m.hud_build.label(col, version_text(), Vector2(48 + title_w + 10, 2 + m.ui_font.get_ascent(24) - m.ui_font.get_ascent(12)), 12, Color(ODD_MUTED, 0.6))
	ver.size = Vector2(300, 16)
	m.ui.set_sound = Button.new()
	m.ui.set_sound.icon = odd_icon("sound")
	m.ui.set_sound.expand_icon = true
	m.ui.set_sound.focus_mode = Control.FOCUS_NONE
	m.ui.set_sound.position = Vector2(640 - 44 * 4 - 24, 0) # four header buttons, 44 x 40 each, 8 px apart
	m.ui.set_sound.size = Vector2(44, 40)
	m.ui.set_sound.pressed.connect(func(): toggle_sound(); apply_settings())
	col.add_child(m.ui.set_sound)
	m.ui.set_music = Button.new()
	m.ui.set_music.icon = odd_icon("music")
	m.ui.set_music.expand_icon = true
	m.ui.set_music.focus_mode = Control.FOCUS_NONE
	m.ui.set_music.position = Vector2(640 - 44 * 3 - 16, 0)
	m.ui.set_music.size = Vector2(44, 40)
	m.ui.set_music.pressed.connect(func(): m.music.toggle_music(); apply_settings())
	col.add_child(m.ui.set_music)
	m.ui.set_minus = set_button(col, "가−", Vector2(640 - 44 * 2 - 8, 0), Vector2(44, 40), func(): m.cfg.text = maxi(0, int(m.cfg.text) - 1); save_settings(); apply_settings())
	m.ui.set_plus = set_button(col, "가+", Vector2(640 - 44, 0), Vector2(44, 40), func(): m.cfg.text = mini(Main.TEXT_SIZES.size() - 1, int(m.cfg.text) + 1); save_settings(); apply_settings())
	for tb in [m.ui.set_minus, m.ui.set_plus]: # tighter padding, so each header button is the 44 x 40 the row is laid out for
		tb.add_theme_stylebox_override("normal", flat(Color("#0d1a3acc"), Color("#9fb4ff66"), 1, 8, 2.0))
		tb.add_theme_stylebox_override("hover", flat(Color("#26456199"), Color("#93d2ff88"), 1, 8, 2.0))
		tb.add_theme_stylebox_override("pressed", flat(Color("#26456199"), Color("#93d2ff88"), 1, 8, 2.0))
		tb.add_theme_stylebox_override("disabled", flat(Color("#0d1a3a73"), Color("#9fb4ff2a"), 1, 8, 2.0))
		tb.size = Vector2(44, 40)
	# the four tab names stay English in every language (the user asked), so tr() never touches them
	var tabs := ["Settings", "Help", "Changes", "About"]
	m.ui.set_tabs = []
	m.ui.set_pages = []
	var tw := (640.0 - 8 * 3) / 4.0
	for i in tabs.size():
		var tb := set_button(col, tabs[i], Vector2(i * (tw + 8), 54), Vector2(tw, 38), func(): show_set_tab(i))
		tb.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		m.ui.set_tabs.append(tb)
		var holder := ScrollContainer.new() # a page taller than the sheet (big text) scrolls
		holder.position = Vector2(0, 106)
		holder.size = Vector2(640, 400)
		holder.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		col.add_child(holder)
		var page := Control.new()
		page.custom_minimum_size = Vector2(626, 400)
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(page)
		m.ui.set_pages.append(page)
	# 설정: rows of label (90 px) and description with a small button under it
	m.ui.set_rows = {}
	m.ui.set_stacks = [[], [], [], []] # per page: [title, wrapped text, button or null], laid out top to bottom by height
	# only the sound effects and the language are left here (the owner, 2026-10-27: the other options went; screen
	# shake, the miniature blur and the damage numbers stay on), and the tune that plays, in a box the mouse can copy
	# no sound row: the speaker key sits at the popup's top right (the owner, 2026-10-28)
	var rows := [["sora_px", "도트 소라", "시험: 소라를 96px 도트 그림으로 그린다(Aseprite로 줄임). 끄면 예전 매끈한 그림이다."]]
	for i in rows.size():
		var r: Array = rows[i]
		var y := i * 92
		var t := m.hud_build.label(m.ui.set_pages[0], r[1], Vector2(0, y), 18, Color("#eef3ff"))
		t.add_theme_font_override("font", m.ui_font)
		t.size = Vector2(112, 20)
		var dsc := m.hud_build.wrap_label(m.ui.set_pages[0], r[2], Vector2(122, y), 518, 18, ODD_MUTED)
		scale_text(dsc)
		scale_text(t)
		var key: String = r[0]
		m.ui.set_rows[key] = set_button(m.ui.set_pages[0], "켜짐", Vector2(122, y + 42), Vector2(74, 34), func():
			if key == "sound":
				toggle_sound()
			else:
				m.cfg[key] = not bool(m.cfg[key])
				if key == "sora_px":
					m.sora.load_sora_art()
					m.sora.set_hero_frame(m.player.dir, 0)
			save_settings()
			apply_settings())
		m.ui.set_stacks[0].append([t, dsc, m.ui.set_rows[key]])
	var lt := m.hud_build.label(m.ui.set_pages[0], "언어", Vector2(0, rows.size() * 92), 18, Color("#eef3ff"))
	lt.size = Vector2(112, 20)
	var lang := m.hud_build.wrap_label(m.ui.set_pages[0], "한국어. 영어, 일본어, 중국어는 번역 표만 준비되어 있다.", Vector2(122, rows.size() * 92), 518, 18, ODD_MUTED)
	scale_text(lt)
	scale_text(lang)
	m.ui.set_stacks[0].append([lt, lang, null])
	var nt := m.hud_build.label(m.ui.set_pages[0], "지금 음악", Vector2(0, (rows.size() + 1) * 92), 18, Color("#eef3ff"))
	nt.size = Vector2(112, 20)
	scale_text(nt)
	var now := LineEdit.new() # read-only but selectable: drag over it and Ctrl+C copies the tune's name
	now.editable = false
	now.selecting_enabled = true
	now.context_menu_enabled = true
	var now_box := Control.new() # the layout moves each row's box, as wrap_label's
	now_box.position = Vector2(122, (rows.size() + 1) * 92)
	now_box.mouse_filter = Control.MOUSE_FILTER_PASS
	m.ui.set_pages[0].add_child(now_box)
	now.custom_minimum_size = Vector2(0, 36)
	now.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	now.add_theme_font_override("font", m.ui_font)
	now.add_theme_font_size_override("font_size", 18)
	now.add_theme_color_override("font_uneditable_color", Color("#eef3ff"))
	now.add_theme_stylebox_override("read_only", flat(Color("#0d1a3a"), Color("#53718b"), 1, 8, 8.0))
	now.text = m.music.tune_line()
	now_box.add_child(now)
	m.ui.now_tune = now
	var tune_keys := Control.new() # 이전 곡 / 다음 곡 under the tune's name
	tune_keys.size = Vector2(200, 34)
	tune_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.ui.set_pages[0].add_child(tune_keys)
	m.ui.tune_prev = set_button(tune_keys, "이전 곡", Vector2(0, 0), Vector2(96, 34), func(): m.music.step_tune(-1))
	m.ui.tune_next = set_button(tune_keys, "다음 곡", Vector2(104, 0), Vector2(96, 34), func(): m.music.step_tune(1))
	m.ui.set_stacks[0].append([nt, now, tune_keys])
	# 도움말
	# the owner, 2026-10-25: more detail, so each row says what the key does, what it costs and when it opens up
	var tips := ["요령", "괴물은 때리기 직전에 빨갛게 부풀고 \"!\"가 뜬다. 그때 구르면 섬광 피하기(잠깐 세상이 느려진다), 막으면 섬광 막기. 쓰러지면 금화와 레벨은 그대로 두고 건널목이나 광장에서 다시 깬다"]
	var help_rows := [["이동", "WASD 또는 방향키. Shift를 누르고 있으면 달린다(기력이 준다). 물수제비 걸음을 얻으면 달려서 물 위도 건넌다"],
		["베기", "J 또는 왼쪽 클릭. 이어 누르면 연속 베기(Lv2 회전 베기, Lv6 내려찍기). 달리며 J는 돌진 베기(Lv3, 기력 15), L로 1초 막은 뒤 J는 모아 베기(Lv4). Lv8 빛 칼날, Lv20 세 갈래"],
		["구르기", "K 또는 오른쪽 클릭(기력 25, Lv10부터 18). 구르기를 시작하는 순간(0.15초 안, Lv10부터 0.2초)에 공격이 오면 섬광 피하기: 맞지 않고 기세 20, 기력 25를 얻는다"], ["막기", "L 또는 가운데 버튼을 누르고 있는 동안 막는다. 막으면 피해가 30%로 줄고 기력 15를 쓴다. 맞는 순간에 막기를 시작하면 섬광 막기"],
		["기술", "U 회오리(기세 30), I 불씨탄(기세 15), O 빛파동(기세 60). 1 2 3도 같다. 기세는 괴물을 때리면 차고 Lv30부터 줄지 않는다. Lv15부터 다시 쓰기가 20% 빠르다. 4는 회복약(체력 45, Lv25부터 30% 더)"],
		["팔찌 E", "말 걸기, 상자와 문 열기, 집 들어가기, 등불 켜기, 벽돌 풀기, 길돌, 낚시. 등불과 벽돌은 달빛 눈금을 쓴다(낮 2, 밤 1). 밤에 켜진 등불 곁에 서 있으면 3초에 한 눈금 찬다"],
		["메뉴", "Q 일지(할 일, 곁일, 모은 것), H 조작법, M 효과음, B 음악, T 시간 3시간 보내기, P 화면 글자 숨기기, Esc 이 창"],
		["화면", "Z X 또는 휠로 확대·축소. F8 처음 자리로 돌아가기, F9 처음부터 새로 하기(한 번 더 눌러야 저장이 지워진다)"], tips]
	for i in help_rows.size():
		var ht := m.hud_build.label(m.ui.set_pages[1], help_rows[i][0], Vector2(0, i * 48), 18, Color("#eef3ff"))
		ht.size = Vector2(112, 20)
		var hd := m.hud_build.wrap_label(m.ui.set_pages[1], help_rows[i][1], Vector2(122, i * 48), 518, 18, ODD_MUTED)
		scale_text(hd)
		scale_text(ht)
		m.ui.set_stacks[1].append([ht, hd, null])
	m.ui.set_help_keys = m.ui.set_stacks[1].duplicate()
	# phones: the same page for the touch keys (use_touch_help swaps the two)
	# the same detail as the keyboard rows (costs, flash windows, level moves), told with the touch keys
	var touch_rows := [["이동", "화면 왼쪽에 엄지를 대면 막대가 생긴다. 끝까지 밀면 달린다(기력이 준다). 물수제비 걸음을 얻으면 달려서 물 위도 건넌다"],
		["베기", "칼 단추. 이어 누르면 연속 베기(Lv2 회전 베기, Lv6 내려찍기). 달리며 칼은 돌진 베기(Lv3, 기력 15), 방패를 1초 누른 채 칼은 모아 베기(Lv4). Lv8 빛 칼날, Lv20 세 갈래"],
		["구르기", "화살표 단추(기력 25, Lv10부터 18). 구르기를 시작하는 순간(0.15초 안, Lv10부터 0.2초)에 공격이 오면 섬광 피하기: 맞지 않고 기세 20, 기력 25를 얻는다"],
		["막기", "방패 단추를 누르고 있는 동안 막는다. 막으면 피해가 30%로 줄고 기력 15를 쓴다. 맞는 순간에 막기를 시작하면 섬광 막기"],
		["기술", "오른쪽 아래 그림 셋: 회오리(기세 30), 불씨탄(기세 15), 빛파동(기세 60). 기세는 괴물을 때리면 차고 Lv30부터 줄지 않는다. Lv15부터 다시 쓰기가 20% 빠르다. 초록 하트는 회복약(체력 45, Lv25부터 30% 더)"],
		["팔찌", "팔찌 단추 (E): 말 걸기, 상자와 문 열기, 집 들어가기, 등불 켜기, 벽돌 풀기, 길돌, 낚시. 등불과 벽돌은 달빛 눈금을 쓴다(낮 2, 밤 1). 밤에 켜진 등불 곁에 서 있으면 3초에 한 눈금 찬다"],
		["화면", "돋보기 단추로 확대·축소. 미니맵 왼쪽 단추 넷: 조작법, 효과음, 일지, 설정"], tips]
	m.ui.set_help_touch = []
	for i in touch_rows.size():
		var tt := m.hud_build.label(m.ui.set_pages[1], touch_rows[i][0], Vector2(0, i * 48), 18, Color("#eef3ff"))
		tt.size = Vector2(112, 20)
		var td := m.hud_build.wrap_label(m.ui.set_pages[1], touch_rows[i][1], Vector2(122, i * 48), 518, 18, ODD_MUTED)
		scale_text(td)
		scale_text(tt)
		tt.visible = false
		td.get_parent().visible = false
		m.ui.set_help_touch.append([tt, td, null])
	# the tune that plays and the button for the next one: one row in the keyboard list and one in the touch list
	m.ui.music_rows = []
	for stack in [m.ui.set_help_keys, m.ui.set_help_touch]:
		var mt := m.hud_build.label(m.ui.set_pages[1], "음악", Vector2(0, stack.size() * 48), 18, Color("#eef3ff"))
		mt.size = Vector2(112, 20)
		var md := m.hud_build.wrap_label(m.ui.set_pages[1], m.music.tune_line(), Vector2(122, stack.size() * 48), 518, 18, ODD_MUTED)
		md.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		scale_text(md)
		scale_text(mt)
		var nb := set_button(m.ui.set_pages[1], "다음 곡", Vector2(122, stack.size() * 48 + 42), Vector2(96, 34), func(): m.music.next_tune())
		if stack == m.ui.set_help_touch:
			mt.visible = false
			md.get_parent().visible = false
			nb.visible = false
		stack.insert(0, [mt, md, nb]) # first: below eight longer help rows it sat past two screens
		m.ui.music_rows.append([mt, md, nb])
	m.ui.set_stacks[1] = m.ui.set_help_keys
	# 바뀐 것
	var scroll := ScrollContainer.new() # the list grows with every ship: it scrolls
	scroll.size = Vector2(640, 396)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.ui.set_pages[2].add_child(scroll)
	# past CHANGES_PAGE lines the older ones wait behind a "더 읽기" button that brings the next CHANGES_PAGE (the user asked)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	scroll.add_child(stack)
	var news := m.hud_build.label(stack, news_text(Main.CHANGES_PAGE), Vector2(0, 0), 18, ODD_MUTED)
	news.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED # news_text translates each line before joining its words
	news.custom_minimum_size = Vector2(620, 0)
	news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scale_text(news)
	var more := set_button(stack, "더 읽기", Vector2.ZERO, Vector2(160, 36), func(): pass)
	more.custom_minimum_size = Vector2(160, 36)
	more.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	more.visible = Main.CHANGES.size() > Main.CHANGES_PAGE
	more.pressed.connect(func():
		var shown: int = mini(int(news.get_meta("shown", Main.CHANGES_PAGE)) + Main.CHANGES_PAGE, Main.CHANGES.size())
		news.set_meta("shown", shown)
		news.text = news_text(shown)
		more.visible = shown < Main.CHANGES.size())
	m.ui.news = news
	m.ui.news_more = more
	# About
	# About as in Space Oddity (the owner, 2026-10-28): who made it, why, the code and a way to send a note; no Carl Sagan
	var about := [
		["만든 사람", "우주 한량, 우주 토끼, 구스테 단톡방 사람들", 0.0, "", ""], # the owner, 2026-10-27
		["만든 이유", "2026.10.22, Space Oddity 다음으로 손바닥만 한 태엽 정원을 걸어 다니는 RPG를 만들고 싶었다.", 56.0, "", ""],
		["만든 코드", "이 게임의 코드는 모두 공개되어 있다.", 140.0, "깃허브에서 보기", SOURCE_URL],
		["의견", "넣고 싶은 것, 틀린 곳을 알려 주세요 (깃허브 계정 필요).", 232.0, "의견 보내기", SOURCE_URL + "/issues"],
	]
	m.ui.about_links = []
	for r in about:
		var at := m.hud_build.label(m.ui.set_pages[3], r[0], Vector2(0, r[2]), 18, Color("#eef3ff"))
		at.size = Vector2(112, 20)
		var ad := m.hud_build.wrap_label(m.ui.set_pages[3], r[1], Vector2(122, r[2]), 518, 18, ODD_MUTED)
		scale_text(ad)
		if r[3] != "":
			var url: String = r[4]
			var lb := set_button(m.ui.set_pages[3], r[3], Vector2(122, r[2] + 38.0), Vector2(200, 36), func(): OS.shell_open(url))
			lb.set_meta("url", url)
			m.ui.about_links.append(lb)
	var foot := set_button(col, "놀이로 돌아가기", Vector2(0, 512), Vector2(640, 44), func(): toggle_settings(false))
	foot.add_theme_font_size_override("font_size", 15)
	foot.add_theme_color_override("font_color", Color("#eef3ff"))
	sp.visible = false
	m.ui.settings = sp
	show_set_tab(0)

func show_set_tab(i: int) -> void:
	m.set_tab = i
	for k in m.ui.set_pages.size():
		m.ui.set_pages[k].visible = k == i
		(m.ui.set_pages[k].get_parent() as Control).visible = k == i
		var tb: Button = m.ui.set_tabs[k]
		tb.add_theme_color_override("font_color", MENU_GOLD if k == i else ODD_INK) # aria-selected: gold rim, gold text
		tb.add_theme_stylebox_override("normal", glass_chosen() if k == i else glass_normal())

func toggle_settings(show: bool) -> void:
	m.settings_open = show
	m.ui.settings.visible = show
	if show:
		m.ui.settings.move_to_front() # above the companions' rows, built after it
		m.ui.help.visible = false
		m.ui.journal.visible = false
		show_set_tab(0)
		apply_settings()

func toggle_sound() -> void:
	m.muted = not m.muted
	save_settings()
	m.music.sfx_switch()
	m.toast("소리 끔" if m.muted else "소리 켬")
	refresh_sound_btn()
	if m.muted:
		hush()

# the sound switched off: a finger to her lips and "쉬잇~", as in Space Oddity (its see-hush drawings; the user,
# 2026-10-23: "음향 off할 때에 소라가 쉬잇하는 표정 넣어줘"). Played once over 3 s while she stands.
func hush() -> void:
	m.idle_t = maxf(m.idle_t, 0.61)
	m.idle_name = "see-hush"
	m.idle_k = 0.0
	m.idle_left = 3.0
	var node := Node3D.new()
	node.position = Vector3(m.player.x, m.ground_y, m.player.z)
	m.add_child(node)
	m.get_tree().create_timer(4.0).timeout.connect(node.queue_free)
	m.say_bubble(node, tr("쉬잇~"), 3.0)

func refresh_sound_btn() -> void:
	m.ui.sound_btn.icon = m.hud_build.key_tex("mute" if m.muted else "sound")
	m.ui.sound_btn.modulate = Color(1, 1, 1, 0.6) if m.muted else Color.WHITE # .soundKeys button.off { opacity:.6 }
	if m.ui.has("set_sound"):
		m.ui.set_sound.icon = odd_icon("mute" if m.muted else "sound")
		m.ui.set_sound.modulate = Color(1, 1, 1, 0.6) if m.muted else Color.WHITE
		m.ui.set_sound.tooltip_text = tr("효과음 꺼짐") + " (M)" if m.muted else tr("효과음 켜짐") + " (M)"
	if m.ui.has("set_music"):
		m.ui.set_music.icon = odd_icon("music" if m.music_on else "music_off")
		m.ui.set_music.modulate = Color.WHITE if m.music_on else Color(1, 1, 1, 0.6)
		m.ui.set_music.tooltip_text = (tr("배경 음악 켜짐") + " (B)") if m.music_on else (tr("배경 음악 꺼짐") + " (B)")
	if is_instance_valid(m.ui.get("title_music")): # gone with the title once the game starts
		m.ui.title_music.icon = odd_icon("music" if m.music_on else "music_off")
		m.ui.title_music.modulate = Color.WHITE if m.music_on else Color(1, 1, 1, 0.6)
		m.ui.title_music.tooltip_text = (tr("배경 음악 켜짐") + " (B)") if m.music_on else (tr("배경 음악 꺼짐") + " (B)")
	m.music.refresh_help()

func toggle_help(show: bool) -> void:
	if show:
		m.ui.journal.visible = false
	m.ui.help.visible = show
	m.ui.hint.visible = not show
	if show:
		m.ui.help.move_to_front()

# one journal column: rich text so headings can be gold; each line is translated as it is built
func journal_column(parent: Control, pos: Vector2, size: Vector2) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.position = pos
	r.size = size
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	r.add_theme_font_override("normal_font", m.ui_font)
	r.add_theme_font_size_override("normal_font_size", 15)
	r.add_theme_color_override("default_color", Color("#e9dfc4"))
	parent.add_child(r)
	return r

func journal_bbcode(lines: Array) -> String:
	var heads := JOURNAL_HEADS.map(func(h): return tr(h))
	var out: Array = []
	for l in lines:
		var line: String = Main.Ko.keep_words(m.touch_words(String(l))).replace("[", "[lb]") # wraps only at spaces
		if l in heads:
			out.append("[color=#f6d27a][font_size=17]%s[/font_size][/color]" % line)
		elif String(l).ends_with(tr("완료")) or String(l).ends_with(tr("끝")):
			out.append("[color=#9fd8a0]%s[/color]" % line)
		else:
			out.append(line)
	return "\n".join(out)

func toggle_journal(show: bool) -> void:
	if show:
		m.ui.help.visible = false
		var lines: Array = journal_lines()
		var cut: int = lines.find(tr("도전 과제"))
		m.ui.journal_text.text = journal_bbcode(lines.slice(0, cut))
		m.ui.journal_text2.text = journal_bbcode(lines.slice(cut))
		m.ui.ending_btn.visible = m.garden_zone.ending_seen()
	m.ui.journal.visible = show
	if show:
		m.ui.journal.move_to_front()

# one line per thing: the current quest, each side story once it has been found, and the keepsakes
func journal_lines() -> Array:
	var out: Array = []
	if m.ng > 0:
		out.append(tr("새 바퀴 %d (괴물이 %.1f배 단단하고 아프다)") % [m.ng, m.ng_mult()])
		out.append("")
	out.append(tr("지금 할 일"))
	out.append("  " + (tr(Main.Ko.plain(m.ui.quest.text)) if m.ui.quest.text != "" else tr("마음 가는 대로 둘러보자")))
	out.append("")
	out.append_array(m.moon_tokens.journal_lines()) # the six moonkeeper tokens and how each is earned
	out.append("")
	out.append(tr("곁이야기"))
	var side := func(name: String, state: String): out.append("  · " + tr(name) + "  —  " + state)
	if m.story_step >= 2:
		var n: int = m.marsh.count()
		side.call("늪의 옛 지도 조각", tr("끝") if m.marsh.chest_open else (tr("달지기 상자가 동쪽 둔덕에 솟았다") if n == 3 else tr("%d/3 찾음") % n))
	if m.shore_q >= 1:
		side.call("깨어난 물가", m.shore.shore_journal())
	if m.shrine_seen:
		side.call("울림 수정", tr("끝") if m.tokens[1] else (tr("상자를 열자") if m.crystal_done else tr("낮은 소리부터 차례로")))
	if m.story_step >= 6:
		side.call("동굴의 세 돌단", tr("아직 찾지 못했다") if not m.shrine_seen else (tr("깨운 기술: %s") % ", ".join(range(3).filter(func(k): return m.woke[k]).map(func(k): return tr(["회오리", "불씨탄", "빛파동"][k]))) if m.woke.has(true) else tr("푸른 돌단에서 회오리를 깨우자")))
	if m.forest_q >= 3:
		var ml: int = m.forest.mem_lamps.filter(func(l): return l.lit).size()
		side.call("노을의 열셋째 등불", [tr("숲 빈터 남쪽의 회색 문"), tr("기억 %d/3") % ml if ml < 3 else tr("가운데 마당으로"), tr("해 지는 그림 문을 찾자"), tr("마을의 심지에게 가져가자"), tr("끝")][m.hollow_q])
	if m.marsh.picked_count() > 0 or m.has_tea:
		side.call("늪의 달꽃", tr("끝") if m.has_tea else (tr("보리 할머니께 가져가자") if m.marsh.picked_count() == 3 else tr("%d/3 · 달이 반 넘게 찬 밤에만 핀다") % m.marsh.picked_count()))
	if m.errand >= 1:
		var done := int(m.errand >= 3) + int(m.kid_q >= 3) + int(m.doran_q >= 3) + int(m.mul_q >= 3) + int(m.fly_q >= 3)
		side.call("마을 심부름", tr("%d/5 마침") % done)
	if m.mail_got[1]:
		side.call("등불 축제", tr("끝") if m.fest_gift else tr("보름달 밤, 마을 광장의 심지에게"))
	if m.mail_q >= 1:
		side.call("도란의 편지 세 통", tr("끝") if m.mail_q >= 2 else (tr("도란에게 알리자") if m.mail_got.count(true) == 3 else tr("%d/3 전함 · 보리 할머니, 심지, 섬 오두막") % m.mail_got.count(true)))
	if m.fly_q >= 1:
		side.call("꼬마의 반딧불 병", tr("끝") if m.fly_q >= 3 else (tr("콩알에게 가져가자") if m.fly_q == 2 else tr("밤의 늪에서 %d/5") % m.marsh.caught()))
	if m.lake_q >= 2:
		side.call("호숫가 낚시", tr("끝") if m.fish_kinds.count(true) == 5 else tr("%d/5 종류") % m.fish_kinds.count(true))
	if m.lake_q >= 4:
		side.call("섬 밑 물빛 동굴", tr("끝") if m.grotto_q >= 4 else (tr("상자를 열자") if m.grotto_q == 3 else tr("섬 남쪽 계단으로")))
		side.call("아랫못 물지기", [tr("섬 남쪽 끝 둑"), tr("물속 사슬은 물결에게 (E)"), tr("창살 안 걸쇠"), tr("물 태엽 열쇠를 감자"), tr("열쇠 기둥의 깡통"), tr("끝")][m.south_q])
	if m.clock_q >= 1:
		side.call("큰 태엽 방", [tr(""), tr("빈터 한가운데 구멍으로"), tr("굳은 톱니 셋 %d/3") % m.clock_gears.count(true), tr("왕관 무늬에 팔찌를 대자"), tr("다 같이 밀자"), tr("끝") if m.clock_box else tr("열쇠 북쪽 궤짝")][m.clock_q])
	if m.forest_q >= 1:
		var nf: int = m.forest.freed.filter(func(f): return f).size()
		side.call("갇힌 다람쥐", tr("끝") if m.has_acorn else tr("%d/5 구함") % nf)
		if m.forest_zone.oak_ready():
			side.call("다람쥐 나무", m.forest_zone.oak_journal())
		side.call("숲의 달 순서 돌", tr("끝") if m.forest.chest_open else (tr("상자를 열자") if m.forest.solved else tr("숲 북서쪽 숲터")))
	if m.post_q >= 1:
		side.call("물길 끝 굴", [tr(""), tr("섬 수정을 낮은 소리부터"), tr("물길 끝의 쓸려 온 더미"), tr("보리 할머니께 엽서를") if m.doran_q >= 3 else tr("한결이 누구일까"), tr("끝")][m.post_q])
	if m.hill_q >= 3:
		side.call("참새 방앗간", [tr("언덕 남쪽 담 위의 참새"), tr("큰 풍차를 팔찌로 감자"), tr("깃대에서 바람개비 넷을 돌리자"), tr("물길 어귀의 벽돌"), tr("건너편 나루의 궤짝"), tr("끝")][m.mill_q])
	if m.hill_q >= 1:
		side.call("바람개비 경주", tr("최고 기록 %.1f초") % m.race_best if m.race_best > 0.0 else tr("언덕 남서쪽 깃대에서"))
	if m.cloud_q >= 1:
		side.call("보이지 않는 구름길", tr("끝") if m.has_shard else tr("첫 섬 남쪽에서 E로 길을 비춰 보자"))
	if m.hill_q >= 3:
		side.call("구름 둔덕", tr("끝") if m.cloud_q >= 3 else tr("언덕 북쪽 바람구멍으로"))
	if m.castle_q >= 3:
		side.call("달지기 숙소", m.castle_zone.quarters_journal())
	if m.castle_q >= 3:
		side.call("달의 계단", tr("끝") if m.stairs.door_open else (tr("등불 %d/3") % m.stairs.lamps_lit() if m.stairs.wall_open else tr("벽돌 벽을 풀자")))
	if m.castle_q >= 1:
		side.call("한결의 일기", tr("%d/3 읽음") % m.castle.pages_read())
		side.call("서재의 달지기 책", tr("끝") if m.tokens[5] else tr("%d/5 읽음") % m.castle.books.filter(func(b): return b.read).size())
		side.call("성의 보물고", tr("끝") if m.castle.vault_open else (tr("상자를 열자") if m.castle.vault_solved() else tr("경비실의 지렛대 셋")))
		side.call("성 아래 잠긴 층", m.castle_zone.under_journal())
	if m.castle_q >= 3:
		side.call("끝내지 못한 등불", m.workshop_zone.work_journal())
	if m.errand >= 1:
		side.call("장터 과녁", (tr("메달, 최고 %d개") % m.target_best) if m.has_medal else (tr("최고 %d개 / 6개면 메달") % m.target_best if m.target_best > 0 else tr("장터 울타리 안 과녁 기둥에서 E")))
		if m.magpie_q >= 1:
			side.call("장터의 반짝이 도둑", [tr(""), tr("밤에 장터를 지켜보자"), tr("부두 끝의 꺼진 달 등불을 켜자 (E)"), tr("끝")][m.magpie_q])
		side.call("유리병 편지", tr("끝") if m.village.bottles_got() == m.village.bottles.size() else tr("%d/3 · 연못에 떠 있다") % m.village.bottles_got())
	if m.hill_q >= 3 or m.trial_best > 0.0:
		side.call("달빛 시련", tr("최고 기록 %d분 %02d초") % [int(m.trial_best) / 60, int(m.trial_best) % 60] if m.trial_best > 0.0 else tr("바람 언덕 동쪽 선돌에서"))
	out.append("")
	out.append(tr("도전 과제"))
	for i in Main.FEATS.size():
		var v := mini(m.errands.feat_value(Main.FEATS[i][1]), Main.FEATS[i][2])
		out.append("  · " + tr(Main.FEATS[i][0]) + "  —  " + (tr("완료") if m.feats_done[i] else "%d/%d" % [v, Main.FEATS[i][2]]))
	out.append("")
	out.append(tr("놀이 시간 %s · 물리친 괴물 %d마리") % [m.errands.play_time_text(), m.stats.kills])
	out.append("")
	out.append(tr("지닌 것"))
	var keep: Array = []
	if m.has_skip: keep.append(tr("물수제비 걸음"))
	if m.has_unbrick: keep.append(tr("벽돌 풀기"))
	if m.fly_q >= 3: keep.append(tr("반딧불 병"))
	if m.has_pearl: keep.append(tr("물빛 진주"))
	if m.has_feather: keep.append(tr("바람 깃털"))
	if m.has_acorn: keep.append(tr("싹 튼 도토리") if m.has_sprout else tr("다람쥐 도토리"))
	if m.hollow_q == 3: keep.append(tr("열셋째 등불"))
	if m.has_ring: keep.append(tr("수정 반지"))
	if m.has_shoes: keep.append(tr("바람 신발"))
	if m.has_oar_ring: keep.append(tr("삿대 고리"))
	if m.has_whistle: keep.append(tr("물지기 호루라기"))
	if m.has_oil: keep.append(tr("달지기 기름병"))
	if m.shore_q == 3: keep.append(tr("보리의 등불"))
	if m.has_cushion: keep.append(tr("갈대 방석"))
	if m.has_bait: keep.append(tr("미끼 주머니"))
	if m.quarters_q == 1 or m.quarters_q == 2: keep.append(tr("녹슨 태엽"))
	if m.has_buckler: keep.append(tr("작은 놋 방패"))
	if m.post_q == 3: keep.append(tr("보리의 엽서"))
	if m.has_armour: keep.append(tr("달지기 갑옷"))
	if m.has_tea: keep.append(tr("달꽃 차"))
	if m.has_shard: keep.append(tr("구름 조각"))
	if m.has_bookmark: keep.append(tr("달지기 책갈피"))
	if m.has_lamp: keep.append(tr("한결의 등잔"))
	if m.has_medal: keep.append(tr("과녁 메달"))
	out.append("  " + (", ".join(keep) if not keep.is_empty() else tr("왕관과 태엽 팔찌")))
	# level moves so far and the next one (the owner asked for perks past Lv8, 2026-10-25)
	out.append("")
	out.append(tr("익힌 기술"))
	var learnt: Array = []
	var next_lv := 0
	for lv in Combat.LV_NAMES:
		if lv <= m.player.lv:
			learnt.append(tr(Combat.LV_NAMES[lv]))
		elif next_lv == 0:
			next_lv = lv
	out.append("  " + (", ".join(learnt) if not learnt.is_empty() else tr("베기, 구르기, 막기")))
	if next_lv > 0:
		out.append("  " + tr("다음: Lv%d %s") % [next_lv, tr(Combat.LV_NAMES[next_lv])])
	return out
