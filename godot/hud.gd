# HUD drawn in code after the GPT mock (art/concept/hud_concept.png): navy glass, thin gold line work.
# Top left: round portrait with level badge, slim HP / momentum / stamina bars, an XP hairline and a
# sun-and-moon dial. Top centre: quest ornaments. Bottom right: diamond skill slots and a gold pill.
extends Control

var main: Node
var portrait: Texture2D = preload("res://art/ui/portrait_bust.png") # head and shoulders (the owner, 2026-10-27)
var icons: Array = [preload("res://art/ui/skill_0.png"), preload("res://art/ui/skill_1.png"),
	preload("res://art/ui/skill_2.png"), preload("res://art/ui/skill_3.png")]

const GOLD := Color("#e8b018")
const GOLD_DIM := Color(0.91, 0.69, 0.09, 0.45)
const NAVY := Color(0.02, 0.04, 0.10, 0.78)
const TEXT := Color("#efe6cf")
const DIM := Color("#a99d84")

# the moon-light card: shown when a bracelet use finds too little moon light (the owner, 2026-10-28: "달빛 에너지가
# 다 닳은 상태에서 쓰려고 하면 어떻게 충전하는지 알려줘 (등불 + 달)"): a lantern + the moon -> a full pip, and the rule
# under it, 4 s above the toast line, the empty pips blinking meanwhile
var pip_hint_t := 0.0
const PIP_HINT := "밤에 켜진 등불 곁에서 가만히 쉬면 달빛이 찬다"
# under the card, the pips the use asked for beside the pips she holds (delight idea 82); 0 asked = no row
var pip_need := 0
var pip_need_drawn := 0 # diamonds drawn in the two rows at the last draw (autoplay d82_pip_gap)
var pip_have_drawn := 0

# a stilled notched rim round a coin whose wait just ended, for those who miss its colour or sound (delight idea 99):
# 16 notches, lit 2 s and eased out over the last 0.5 s, never blinking
const RIM_SHOW := 2.0
const RIM_NOTCHES := 16
var rim_prev := [0.0, 0.0, 0.0, 0.0] # each coin's wait at the last frame
var rim_t := [0.0, 0.0, 0.0, 0.0]    # seconds the rim is still shown
var rim_drawn := 0                   # notches drawn at the last draw (autoplay d99_ready_rim)
var bottle_drawn := false            # the one-bottle outline was drawn at the last draw (autoplay d86_last_bottle)

func _process(dt: float) -> void:
	pip_hint_t = maxf(0.0, pip_hint_t - dt)
	update_rims(dt)
	queue_redraw()

func update_rims(dt: float) -> void:
	var cds: Array = main.player.cds
	for i in 4:
		rim_t[i] = maxf(0.0, rim_t[i] - dt)
		if rim_prev[i] > 0.0 and cds[i] <= 0.0:
			rim_t[i] = RIM_SHOW
		rim_prev[i] = cds[i]

func draw_pip_hint() -> void:
	var vs := get_viewport_rect().size
	var a := minf(1.0, pip_hint_t / 0.4) # fades out over its last 0.4 s
	var box := Rect2(vs.x / 2.0 - 220.0, vs.y - 330.0, 440.0, 104.0)
	draw_rect(box, Color(NAVY, 0.9 * a))
	draw_rect(box, Color(GOLD, a), false, 1.5)
	var cy := box.position.y + 40.0
	var cx := vs.x / 2.0
	# the lantern: a post, a dark frame round warm glass, a cap, and its glow
	var lx := cx - 120.0
	draw_circle(Vector2(lx, cy), 22.0, Color(1.0, 0.77, 0.42, 0.18 * a))
	draw_rect(Rect2(lx - 2.0, cy + 12.0, 4.0, 16.0), Color(0.23, 0.16, 0.12, a))
	draw_rect(Rect2(lx - 10.0, cy - 12.0, 20.0, 24.0), Color(0.23, 0.16, 0.12, a))
	draw_rect(Rect2(lx - 7.0, cy - 9.0, 14.0, 18.0), Color(1.0, 0.77, 0.42, a))
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 13.0, cy - 12.0), Vector2(lx + 13.0, cy - 12.0), Vector2(lx, cy - 22.0)]), Color(0.23, 0.16, 0.12, a))
	text(Vector2(cx - 70.0, cy + 8.0), "+", 26, Color(TEXT, a), HORIZONTAL_ALIGNMENT_CENTER, 20.0)
	# the moon: a pale disc with the card's navy taken out of one side
	var mx := cx - 20.0
	draw_circle(Vector2(mx, cy), 17.0, Color(0.95, 0.9, 0.69, a))
	draw_circle(Vector2(mx + 8.0, cy - 5.0), 15.0, Color(0.03, 0.05, 0.11, a))
	text(Vector2(cx + 20.0, cy + 8.0), "→", 24, Color(TEXT, a), HORIZONTAL_ALIGNMENT_CENTER, 30.0)
	diamond(Vector2(cx + 100.0, cy), 15.0, Color(0.62, 0.83, 1.0, a))
	diamond(Vector2(cx + 100.0, cy), 7.0, Color(1, 1, 1, 0.6 * a))
	text(Vector2(box.position.x, box.position.y + 88.0), PIP_HINT, 18, Color(TEXT, a), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	pip_need_drawn = 0
	pip_have_drawn = 0
	if pip_need > 0: # what the use asks and what she holds, side by side
		var row := Rect2(box.position.x + 70.0, box.end.y + 6.0, 300.0, 30.0)
		draw_rect(row, Color(NAVY, 0.9 * a))
		draw_rect(row, Color(GOLD_DIM, a), false, 1.0)
		var need := mini(pip_need, 12)
		var have := mini(main.crown_pips, 12)
		var y := row.position.y + 15.0
		text(Vector2(row.position.x + 8.0, y + 6.0), "필요", 15, Color(TEXT, a))
		for k in need:
			diamond(Vector2(row.position.x + 62.0 + k * 16.0, y), 6.0, Color(GOLD, a))
			diamond(Vector2(row.position.x + 62.0 + k * 16.0, y), 3.5, Color(NAVY, a))
			pip_need_drawn += 1
		text(Vector2(row.position.x + 162.0, y + 6.0), "지금", 15, Color(TEXT, a))
		for k in have:
			diamond(Vector2(row.position.x + 216.0 + k * 16.0, y), 6.0, Color(0.62, 0.83, 1.0, a))
			pip_have_drawn += 1
		if have == 0:
			text(Vector2(row.position.x + 212.0, y + 6.0), "없음", 15, Color(DIM, a))

# a small bottle (neck, shoulders, body) with its top-left corner at `at`; a dark line under the pale one so it reads on any icon
func bottle_outline(at: Vector2) -> void:
	var pts := PackedVector2Array([at + Vector2(3, 0), at + Vector2(6, 0), at + Vector2(6, 4), at + Vector2(9, 7), at + Vector2(9, 15),
		at + Vector2(0, 15), at + Vector2(0, 7), at + Vector2(3, 4), at + Vector2(3, 0)])
	draw_polyline(pts, Color(0, 0, 0, 0.7), 3.5)
	draw_polyline(pts, TEXT, 1.5)
	bottle_drawn = true

func rim_points(c: Vector2, half: float) -> Array: # [from, to] of each notch, radial, just outside the cooldown sweep
	var out: Array = []
	for k in RIM_NOTCHES:
		var a1 := TAU * k / RIM_NOTCHES
		var d := Vector2(cos(a1), sin(a1))
		out.append([c + d * half * 0.93, c + d * half * 1.04])
	return out

func draw_rim(c: Vector2, half: float, a: float) -> void:
	draw_arc(c, half * 0.93, 0.0, TAU, 48, Color(GOLD, 0.8 * a), 1.5)
	for n in rim_points(c, half):
		draw_line(n[0], n[1], Color(GOLD, a), 3.0)
	rim_drawn += RIM_NOTCHES

func diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)

# the plate under the place's name, its sub-name and (from the second round) the round badge: as wide as the widest
# of them, from above the name's letters to below the last line
var zone_plate_rect := Rect2() # last drawn, for the tests
func zone_plate(low: float) -> void:
	var lines := [[main.ui.zone_name.text, 18], [main.ui.zone_sub.text, 15]]
	if main.ng > 0:
		lines.append([main.errands.round_badge(), 15])
	var w := 0.0
	for l in lines:
		w = maxf(w, main.ui_font.get_string_size(tr(l[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, l[1]).x)
	if w <= 0.0:
		zone_plate_rect = Rect2()
		return
	var bottom := (299.0 if main.ng > 0 else 276.0) + low + 8.0
	zone_plate_rect = Rect2(Vector2(2, 254 + low - 21), Vector2(w + 18, bottom - (254 + low - 21)))
	draw_style_box(navy_plate(), zone_plate_rect)

var status_plate_rect := Rect2() # last drawn, for the tests
var quest_plate_rect := Rect2()
var plate_box: StyleBoxFlat
# navy glass with a dim gold rim (#091627 at 72%, #e8b018 at 55%): the story box's colours, under HUD letters
func navy_plate() -> StyleBoxFlat:
	if plate_box == null:
		plate_box = StyleBoxFlat.new()
		plate_box.bg_color = Color(0.035, 0.086, 0.153, 0.72)
		plate_box.border_color = Color(0.91, 0.69, 0.09, 0.55)
		plate_box.set_border_width_all(1)
		plate_box.set_corner_radius_all(8)
	return plate_box

func text(at: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	s = tr(s) # drawn text is not auto-translated like Labels are
	draw_string_outline(main.ui_font, at, s, align, width, size, 4, Color(0, 0, 0, 0.7 * col.a)) # fades with the text
	draw_string(main.ui_font, at, s, align, width, size, col)

func bar(at: Vector2, w: float, frac: float, col: Color, label: String, value: String, blink := false) -> void:
	var h := 10.0
	draw_rect(Rect2(at, Vector2(w, h)), NAVY)
	var fw: float = w * clampf(frac, 0.0, 1.0)
	var a := 0.55 + 0.45 * absf(sin(main.t * 6.0)) if blink else 1.0
	draw_rect(Rect2(at, Vector2(fw, h)), Color(col, a))
	draw_rect(Rect2(at, Vector2(fw, h * 0.4)), Color(col.lightened(0.35), a * 0.8)) # glassy top
	draw_rect(Rect2(at - Vector2(1, 1), Vector2(w + 2, h + 2)), GOLD_DIM, false, 1.0)
	diamond(at + Vector2(-6, h / 2.0), 5, GOLD)
	diamond(at + Vector2(w + 6, h / 2.0), 5, GOLD)
	text(at + Vector2(-45, 10), label, 16, DIM) # 11 -> 14 -> 15 -> 16 and the numbers 12 -> 14 -> 15 -> 16 (the owner, 2026-10-27/28: too small, then +1, +1)
	text(at + Vector2(w + 16, 11), value, 16, TEXT)

# where the bars start: past the portrait ring and its right diamond (182, or 250 beside the big ring)
func bars_x() -> float:
	return 250.0 if main.hud_build.big_portrait() else 182.0

# the bars' length: half on phones (the owner, 2026-10-28, on a phone: "status들이 너무 크다. bar를 반으로 줄여")
func bar_w() -> float:
	return 109.0 if main.touch_ui else 218.0

# where the bars end, without their numbers
func bars_end() -> float:
	return bars_x() + bar_w()

# the four skill coins: 68 px, or 60 px on phones like the menu and zoom coins (the owner, 2026-10-28: "아이콘 크기 및
# 모양도 제각각이고.. 다 통일"); 8 px apart, the last 8 px from the right edge, centres 59 px over the bottom
func skill_size() -> float:
	return 60.0 if main.touch_ui else 68.0

func skill_spot(i: int) -> Vector2:
	var vs := get_viewport_rect().size
	var sz := skill_size()
	var x := vs.x - 8.0 - sz / 2.0 - (3 - i) * (sz + 8.0)
	var sf: Vector4 = main.safe # the home bar and the camera hole (idea 95)
	if main.touch_ui and bool(main.cfg.get("lefty", false)): # the mirrored layout (delight idea 91) puts the skills in the left corner
		x = vs.x - x + sf.x
	else:
		x -= sf.z
	return Vector2(x, vs.y - 59.0 - sf.w)

var pips_drawn := 0 # diamonds in the moon gauge at the last draw (autoplay pips)
var tokens_lit := 0 # lit gems in the token row at the last draw, and how many it drew (autoplay tokens)
var tokens_drawn := 0

# one diamond per pip of pip_max (8 - 12), 16 px apart from 4 px left of the bars: under the bars either way
func pip_x() -> float:
	return bars_x() - 4.0

func pip_spots() -> Array:
	var out: Array = []
	for i in main.pip_max:
		out.append(Vector2(pip_x() + i * 16, 124))
	return out

# the six moonkeeper tokens: a row of small gems under the moon gauge, 16 px apart, a lit one earned this round
func token_spots() -> Array:
	var out: Array = []
	for i in main.tokens.size():
		out.append(Vector2(pip_x() + i * 16, 146))
	return out

func _draw() -> void:
	if main == null or main.intro:
		return
	if pip_hint_t > 0.0: # centre-bottom, clear of the corners the rest is drawn in
		draw_pip_hint()
	var p: Dictionary = main.player
	var vs := get_viewport_rect().size
	draw_set_transform(Vector2(main.safe.x, main.safe.y)) # the top left cluster keeps clear of the camera hole (idea 95)
	# ---- portrait and level
	# on a wide screen the ring is as big as the minimap's 186 px bezel (r 63 -> 93, the owner, 2026-10-27) and level with
	# it, 8 px from the top like the minimap (the owner, 2026-10-28), the crown point sitting on the ring's top instead of
	# over it; a narrow window keeps r 63 and the crown point above (hud_build.big_portrait)
	var big: bool = main.hud_build.big_portrait()
	var r := 93.0 if big else 63.0
	var c := Vector2(101, 101) if big else Vector2(71, 82)
	draw_circle(c, r - 1.0, NAVY)
	var ph_half := 83.0 if big else 56.0
	draw_texture_rect(portrait, Rect2(c - Vector2(ph_half, ph_half), Vector2(ph_half, ph_half) * 2.0), false)
	draw_arc(c, r - (6.0 if big else 5.0), 0, TAU, 96, GOLD, 3.0 if big else 2.5, true)
	draw_arc(c, r, 0, TAU, 96, GOLD_DIM, 1.0, true)
	for ang in ([0.0, PI] if big else [-PI / 2, 0.0, PI]):
		diamond(c + Vector2(cos(ang), sin(ang)) * r, 6 if big else 5, GOLD)
	diamond(c + Vector2(0, -r if big else -r - 11.0), 8 if big else 7, GOLD) # crown point
	var lb := c + Vector2(0, 89 if big else 60)
	var lr := 16.0 if big else 14.0
	draw_circle(lb, lr, Color("#0b1530"))
	draw_arc(lb, lr, 0, TAU, 32, GOLD, 2.0, true)
	text(lb + Vector2(-20, 6), str(p.lv), 17 if big else 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 40)
	# ---- bars, on the navy plate (labels, bars, values, the moon gauge and the tokens)
	var x0 := bars_x()
	var vw := 0.0
	for v in ["%d/%d" % [ceili(p.hp), p.max_hp], "%d/%d" % [int(p.mp), p.max_mp], "%d/%d" % [p.xp, p.lv * 25]]:
		vw = maxf(vw, main.ui_font.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	status_plate_rect = Rect2(Vector2(x0 - 52, 22), Vector2(bar_w() + 52 + 16 + vw + 12, 142))
	draw_style_box(navy_plate(), status_plate_rect)
	bar(Vector2(x0, 34), bar_w(), p.hp / p.max_hp, Color("#e03a44"), "체력", "%d/%d" % [ceili(p.hp), p.max_hp])
	bar(Vector2(x0, 56), bar_w(), p.mp / p.max_mp, Color("#f08a2a"), "기세", "%d/%d" % [int(p.mp), p.max_mp], p.mp >= 60.0)
	bar(Vector2(x0, 78), bar_w(), p.sp / 100.0, Color("#f2e2b0"), "기력", "%d/100" % int(p.sp))
	var need: int = p.lv * 25
	bar(Vector2(x0, 100), bar_w(), float(p.xp) / need, Color("#8de07a"), "경험", "%d/%d" % [p.xp, need])
	# the bracelets' moon gauge: pip_max small diamonds (8 at the start, up to 12; 12 end at x 354, under the 400 px bars)
	text(Vector2(x0 - 45, 130), "달빛", 16, DIM)
	var spots := pip_spots()
	pips_drawn = spots.size()
	for i in spots.size():
		var pc: Vector2 = spots[i]
		var full: bool = i < main.crown_pips
		var flash: bool = main.pip_flash > 0.0 and i == main.crown_pips
		if full:
			diamond(pc, 6, Color("#9fd4ff"))
		elif flash:
			diamond(pc, 6, Color.WHITE)
		else: # empty; blinking gold while the moon-light card is up
			var ring := GOLD if pip_hint_t > 0.0 and fmod(main.t, 0.5) < 0.25 else Color("#6a6050")
			draw_polyline(PackedVector2Array([pc + Vector2(0, -6), pc + Vector2(6, 0), pc + Vector2(0, 6), pc + Vector2(-6, 0), pc + Vector2(0, -6)]), ring, 1.0)
	var grow: float = 6.0 * minf(1.0, main.rest_t / main.rest_need)
	if grow >= 0.5 and main.crown_pips < main.pip_max: # the next pip glows in while resting (too small a diamond cannot be drawn)
		diamond(Vector2(pip_x() + main.crown_pips * 16, 124), grow, Color("#9fd4ff"))
	# the moonkeeper tokens: six gems, gold when earned (the owner, 2026-10-28)
	text(Vector2(x0 - 45, 152), "표식", 16, DIM)
	var tspots := token_spots()
	tokens_drawn = tspots.size()
	tokens_lit = 0
	for i in tspots.size():
		var tc: Vector2 = tspots[i]
		if main.tokens[i]:
			tokens_lit += 1
			diamond(tc, 6, Color("#ffd84a"))
			diamond(tc, 2.5, Color(1, 1, 1, 0.7))
		else:
			draw_polyline(PackedVector2Array([tc + Vector2(0, -6), tc + Vector2(6, 0), tc + Vector2(0, 6), tc + Vector2(-6, 0), tc + Vector2(0, -6)]), Color("#6a6050"), 1.0)
	# ---- sun / moon dial hanging under the portrait (60 px lower under the big ring)
	var low := 60.0 if big else 0.0
	var dc := Vector2(89, 282) if big else Vector2(59, 222)
	for i in 14:
		var a0 := PI + PI * i / 14.0
		var pt := dc + Vector2(cos(a0) * 58, sin(a0) * 32)
		draw_circle(pt, 1.2, GOLD_DIM)
	var h: float = main.hour
	var day := h >= 6.0 and h < 18.0
	var prog := (h - 6.0) / 12.0 if day else fmod(h + 6.0, 24.0) / 12.0
	var ang := PI + PI * prog
	var sp := dc + Vector2(cos(ang) * 58, sin(ang) * 32)
	if day: # sun and moon twice the old size (the user found them too small, 2026-10-24)
		draw_circle(sp, 18, Color(1.0, 0.75, 0.3, 0.25))
		draw_circle(sp, 11, Color("#ffd25a"))
	else:
		draw_circle(sp, 16, Color(0.75, 0.8, 1.0, 0.2))
		draw_circle(sp, 11, Color("#e8ecff"))
		var ph: Vector2 = main.moon_phase()
		if ph.x < 0.98:
			draw_circle(sp + Vector2(11.0 * 2.0 * ph.x * ph.y, -1.0), 10.8, Color("#0b1530"))
	# zone name, small, under the dial, on a dark plate in the story box's navy and gold so it reads over any ground
	# (the owner, 2026-10-29: the round badge over a bright field, "잘 보이게, 뒷면에 .. 뭘 좀 넣어줘")
	zone_plate(low)
	text(Vector2(10, 254 + low), main.ui.zone_name.text, 18, TEXT) # 14 / 11 -> 17 / 14 -> 18 / 15 (the owner, 2026-10-27/28)
	text(Vector2(10, 276 + low), main.ui.zone_sub.text, 15, DIM)
	if main.ng > 0: # the round and how much tougher than the first the monsters are
		text(Vector2(10, 299 + low), main.errands.round_badge(), 15, GOLD)
	draw_set_transform(Vector2.ZERO)
	# ---- quest ornaments: from the box hud_build laid the quest text out in, so no line crosses the text
	if main.ui.quest.visible and main.hud_build.quest_deco.size != Vector2.ZERO:
		var d: Rect2 = main.hud_build.quest_deco
		quest_plate_rect = d.grow_individual(14, 0, 14, 0)
		draw_style_box(navy_plate(), quest_plate_rect)
		var cx := d.get_center().x
		var half := d.size.x / 2.0
		for y in [d.position.y + 4.0, d.end.y - 4.0]:
			draw_line(Vector2(cx - half, y), Vector2(cx - 10, y), GOLD_DIM, 1.0)
			draw_line(Vector2(cx + 10, y), Vector2(cx + half, y), GOLD_DIM, 1.0)
			diamond(Vector2(cx, y), 4, GOLD)
			diamond(Vector2(cx - half, y), 2.5, GOLD)
			diamond(Vector2(cx + half, y), 2.5, GOLD)
	# ---- skills
	var keys := ["U", "I", "O", "4"]
	var names := ["회오리", "불씨탄", "빛파동", "회복약"] # phones have no keys: the tag names the skill
	var cds: Array = p.cds
	var cd_max := [main.SKILL_CD[0], main.SKILL_CD[1], main.SKILL_CD[2], 2.0]
	rim_drawn = 0
	bottle_drawn = false
	for i in 4:
		var sc := skill_spot(i) # 8 px apart, the last icon and the key tags 8 px from the right and bottom edges
		var half := skill_size() / 2.0
		draw_texture_rect(icons[i], Rect2(sc - Vector2(half, half), Vector2(half, half) * 2.0), false)
		var frac: float = cds[i] / cd_max[i]
		var cant: bool = i < 3 and p.mp < main.skill_cost(i)
		if frac > 0.0 or cant: # cooldown sweep, or dim when there is not enough momentum
			var pts := PackedVector2Array([sc])
			var sweep := TAU * (frac if frac > 0.0 else 1.0)
			for k in 25:
				var a1: float = -PI / 2 + sweep * k / 24.0
				pts.append(sc + Vector2(cos(a1), sin(a1)) * half * 0.91) # over the moon-stone coin's gem (v0.0.101)
			draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
		# under every coin its name, the key first on a keyboard (button draft 3, the owner 2026-10-27)
		var kb := sc + Vector2(0, 42)
		text(kb + Vector2(-38, 5), names[i] if main.touch_ui else keys[i] + " " + names[i], 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 76)
		if i == 3:
			text(sc + Vector2(half * 0.41, half * 0.88), "×%d" % p.pots, 12, TEXT)
			if p.pots == 1: # one bottle left: its outline beside the count, steady (delight idea 86)
				bottle_outline(sc + Vector2(half * 0.41 - 12.0, half * 0.88 - 13.0))
		if rim_t[i] > 0.0: # the wait just ended: a stilled notched rim
			draw_rim(sc, half, minf(1.0, rim_t[i] / 0.5))
	# the bottom-left buttons' names, on the same line (the buttons are hud_build.icon_button, 68 px at x 8, 84, 160, 236)
	if main.ui.hint.visible and not main.touch_ui: # phones moved these keys up beside the minimap
		var left := [["H", "도움말"], ["M", "소리"], ["Q", "할 일"], ["Esc", "설정"]]
		for i in 4:
			var at := Vector2(8 + i * 76 + 34, vs.y - 17)
			text(at + Vector2(-38, 5), left[i][1] if main.touch_ui else left[i][0] + " " + left[i][1], 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 76)
	# ---- gold pill
	var gp := Rect2(Vector2(vs.x - 139, vs.y - 129), Vector2(126, 28)) # its end diamond 8 px from the edge, 8 px over the skills
	draw_rect(gp, NAVY)
	draw_rect(gp, GOLD_DIM, false, 1.0)
	diamond(gp.position + Vector2(0, 14), 5, GOLD)
	diamond(gp.position + Vector2(126, 14), 5, GOLD)
	diamond(gp.position + Vector2(24, 14), 6, Color("#ffd84a"))
	text(gp.position + Vector2(40, 20), str(p.gold), 15, TEXT)
