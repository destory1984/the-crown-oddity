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

func _process(_dt: float) -> void:
	queue_redraw()

func diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)

func text(at: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	s = tr(s) # drawn text is not auto-translated like Labels are
	draw_string_outline(main.ui_font, at, s, align, width, size, 4, Color(0, 0, 0, 0.7))
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
	text(at + Vector2(-45, 10), label, 15, DIM) # 11 -> 14 -> 15 and the numbers 12 -> 14 -> 15 (the owner, 2026-10-27: too small, then +1)
	text(at + Vector2(w + 16, 11), value, 15, TEXT)

# where the bars start: past the portrait ring and its right diamond (182, or 250 beside the big ring)
func bars_x() -> float:
	return 250.0 if main.hud_build.big_portrait() else 182.0

# where the bars end, without their numbers
func bars_end() -> float:
	return bars_x() + 218.0

var pips_drawn := 0 # diamonds in the moon gauge at the last draw (autoplay pips)

# one diamond per pip of pip_max (8 - 12), 16 px apart from 4 px left of the bars: under the bars either way
func pip_x() -> float:
	return bars_x() - 4.0

func pip_spots() -> Array:
	var out: Array = []
	for i in main.pip_max:
		out.append(Vector2(pip_x() + i * 16, 124))
	return out

func _draw() -> void:
	if main == null or main.intro:
		return
	var p: Dictionary = main.player
	var vs := get_viewport_rect().size
	# ---- portrait and level
	# on a wide screen the ring is as big as the minimap's 186 px bezel (r 63 -> 93, the owner, 2026-10-27), 11 px lower
	# than the minimap so the crown point above it stays on screen; a narrow window keeps r 63 (hud_build.big_portrait)
	var big: bool = main.hud_build.big_portrait()
	var r := 93.0 if big else 63.0
	var c := Vector2(101, 112) if big else Vector2(71, 82)
	draw_circle(c, r - 1.0, NAVY)
	var ph_half := 83.0 if big else 56.0
	draw_texture_rect(portrait, Rect2(c - Vector2(ph_half, ph_half), Vector2(ph_half, ph_half) * 2.0), false)
	draw_arc(c, r - (6.0 if big else 5.0), 0, TAU, 96, GOLD, 3.0 if big else 2.5, true)
	draw_arc(c, r, 0, TAU, 96, GOLD_DIM, 1.0, true)
	for ang in [-PI / 2, 0.0, PI]:
		diamond(c + Vector2(cos(ang), sin(ang)) * r, 6 if big else 5, GOLD)
	diamond(c + Vector2(0, -r - 11.0), 8 if big else 7, GOLD) # crown point
	var lb := c + Vector2(0, 89 if big else 60)
	var lr := 16.0 if big else 14.0
	draw_circle(lb, lr, Color("#0b1530"))
	draw_arc(lb, lr, 0, TAU, 32, GOLD, 2.0, true)
	text(lb + Vector2(-20, 6), str(p.lv), 17 if big else 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 40)
	# ---- bars
	var x0 := bars_x()
	bar(Vector2(x0, 34), 218, p.hp / p.max_hp, Color("#e03a44"), "체력", "%d/%d" % [ceili(p.hp), p.max_hp])
	bar(Vector2(x0, 56), 218, p.mp / p.max_mp, Color("#f08a2a"), "기세", "%d/%d" % [int(p.mp), p.max_mp], p.mp >= 60.0)
	bar(Vector2(x0, 78), 218, p.sp / 100.0, Color("#f2e2b0"), "기력", "%d/100" % int(p.sp))
	var need: int = p.lv * 25
	bar(Vector2(x0, 100), 218, float(p.xp) / need, Color("#8de07a"), "경험", "%d/%d" % [p.xp, need])
	# the bracelets' moon gauge: pip_max small diamonds (8 at the start, up to 12; 12 end at x 354, under the 400 px bars)
	text(Vector2(x0 - 45, 130), "달빛", 15, DIM)
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
		else:
			draw_polyline(PackedVector2Array([pc + Vector2(0, -6), pc + Vector2(6, 0), pc + Vector2(0, 6), pc + Vector2(-6, 0), pc + Vector2(0, -6)]), Color("#6a6050"), 1.0)
	var grow: float = 6.0 * minf(1.0, main.rest_t / main.rest_need)
	if grow >= 0.5 and main.crown_pips < main.pip_max: # the next pip glows in while resting (too small a diamond cannot be drawn)
		diamond(Vector2(pip_x() + main.crown_pips * 16, 124), grow, Color("#9fd4ff"))
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
	# zone name, small, under the dial
	text(Vector2(10, 254 + low), main.ui.zone_name.text, 17, TEXT) # 14 / 11 -> 17 / 14 (the owner, 2026-10-27)
	text(Vector2(10, 275 + low), main.ui.zone_sub.text, 14, DIM)
	# ---- quest ornaments: from the box hud_build laid the quest text out in, so no line crosses the text
	if main.ui.quest.visible and main.hud_build.quest_deco.size != Vector2.ZERO:
		var d: Rect2 = main.hud_build.quest_deco
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
	for i in 4:
		var sc := Vector2(vs.x - 270 + i * 76, vs.y - 59) # 8 px apart, the last icon and the key tags 8 px from the right and bottom edges
		draw_texture_rect(icons[i], Rect2(sc - Vector2(34, 34), Vector2(68, 68)), false)
		var frac: float = cds[i] / cd_max[i]
		var cant: bool = i < 3 and p.mp < main.skill_cost(i)
		if frac > 0.0 or cant: # cooldown sweep, or dim when there is not enough momentum
			var pts := PackedVector2Array([sc])
			var sweep := TAU * (frac if frac > 0.0 else 1.0)
			for k in 25:
				var a1: float = -PI / 2 + sweep * k / 24.0
				pts.append(sc + Vector2(cos(a1), sin(a1)) * 31) # over the moon-stone coin's gem (v0.0.101)
			draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
		# under every coin its name, the key first on a keyboard (button draft 3, the owner 2026-10-27)
		var kb := sc + Vector2(0, 42)
		text(kb + Vector2(-38, 5), names[i] if main.touch_ui else keys[i] + " " + names[i], 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 76)
		if i == 3:
			text(sc + Vector2(14, 30), "×%d" % p.pots, 12, TEXT)
	# the bottom-left buttons' names, on the same line (the buttons are hud_build.icon_button, 68 px at x 8, 84, 160, 236)
	if main.ui.hint.visible:
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
