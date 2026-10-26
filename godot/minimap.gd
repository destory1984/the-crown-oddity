# Quarter-view parchment minimap: rotated with the camera and squashed like the
# ground on screen, centred on the player. Drawn inside a circular mask.
extends Control

const ZOOM := 3.2
const SQUASH := 0.62

var main: Node
var map_tex: Texture2D
const MARSH := preload("res://marsh.gd")
var sora_icon: Texture2D = preload("res://art/ui/portrait.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR # a smooth painted map, not pixel blocks

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if main == null:
		return
	var s := size.x / 96.0
	var c := Vector2(size.x / 2.0, size.y * 0.54)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.09, 0.85))
	var p: Vector2 = Vector2(main.player.x, main.player.z)
	var xf := Transform2D(0.0, c) \
		* Transform2D(0.0, Vector2(1.0, SQUASH), 0.0, Vector2.ZERO) \
		* Transform2D(main.cam_yaw, Vector2.ZERO) \
		* Transform2D(0.0, Vector2(ZOOM * s, ZOOM * s), 0.0, Vector2.ZERO) \
		* Transform2D(0.0, -p - Vector2(0.5, 0.5))
	draw_set_transform_matrix(xf)
	draw_texture(map_tex, Vector2.ZERO)
	for e in main.enemies:
		if not e.dead and e.get("boss", false):
			draw_rect(Rect2(e.x - 0.9, e.z - 0.9, 2.8, 2.8), Color("#1e1e2a"))
			draw_rect(Rect2(e.x - 0.5, e.z - 0.5, 2.0, 2.0), Color("#9a4ad8"))
		elif not e.dead:
			draw_rect(Rect2(e.x - 0.2, e.z - 0.2, 1.4, 1.4), Color("#3a1a10"))
			draw_rect(Rect2(e.x + 0.1, e.z + 0.1, 0.8, 0.8), Color("#d8402a"))
	for ch in main.chests:
		if not ch.open:
			draw_rect(Rect2(ch.x - 0.2, ch.z + 0.3, 1.4, 0.5), Color("#b07a12"))
			draw_rect(Rect2(ch.x + 0.25, ch.z - 0.2, 0.5, 1.4), Color("#b07a12"))
	var mc: Vector2 = MARSH.CHEST_AT
	if main.marsh.chest.visible and not main.marsh.chest_open: # the moonkeeper chest, a pale blue cross
		draw_rect(Rect2(mc.x - 0.4, mc.y + 0.2, 1.8, 0.6), Color("#bcd6ff"))
		draw_rect(Rect2(mc.x + 0.2, mc.y - 0.4, 0.6, 1.8), Color("#bcd6ff"))
	if main.story_step >= 3 and main.shore_q < 2: # 깨어난 물가: the basket in the mud
		var b: Vector2 = MARSH.BASKET_AT
		draw_rect(Rect2(b.x - 0.1, b.y - 0.1, 1.2, 1.2), Color("#c8a060"))
	if main.marsh.float_node.visible: # Bori's lantern, floating or off the island
		var lp: Vector3 = main.marsh.float_node.position
		draw_rect(Rect2(lp.x - 0.1, lp.z - 0.1, 1.2, 1.2), Color("#ffd060"))
	if main.in_castle() and main.castle_q >= 3: # 달지기 숙소: the knight's spring, then the doorkeeper
		if main.castle.spring_node.visible:
			var sp: Vector3 = main.castle.spring_node.position
			draw_rect(Rect2(sp.x - 0.1, sp.z - 0.1, 1.2, 1.2), Color("#ffc46a"))
		if main.quarters_q >= 3:
			var dp: Vector3 = main.castle.doll.position
			draw_rect(Rect2(dp.x - 0.2, dp.z - 0.2, 1.4, 1.4), Color("#263440"))
			draw_rect(Rect2(dp.x + 0.05, dp.z + 0.05, 0.9, 0.9), Color("#9fb4c8"))
	if main.in_hill and main.mill_q == 2: # the wind post, until the first run is won
		var wp: Vector2 = main.hill.south_marks.P
		draw_rect(Rect2(wp.x - 0.3, wp.y - 0.3, 1.6, 1.6), Color(0.02, 0.04, 0.09))
		draw_rect(Rect2(wp.x, wp.y - 0.1, 1.2, 0.8), Color("#7ac8e8"))
	draw_set_transform_matrix(Transform2D())
	# the ways down (violet) and up (gold) as small upright stairs of three steps, drawn on screen over their tile
	# Bori's cottage (her shop) as a small upright house with a red roof (the owner, 2026-10-26: it was not on the map)
	if main.cottage_at.x >= 0.0:
		draw_house(xf * (main.cottage_at + Vector2(0.5, 0.5)), s)
	for st: Array in map_tex.get_meta("stairs", []):
		draw_stairs(xf * (st[0] + Vector2(0.5, 0.5)), st[1], s)
	if main.in_workshop(): # the deep workshop's floor, B1 to B3, on a small dark tab at the top
		var tag := "B%d" % (main.workshop_zone.floor_here() + 1)
		var tp := Vector2(size.x / 2.0, 22.0)
		draw_rect(Rect2(tp - Vector2(16, 12), Vector2(32, 18)), Color(0.04, 0.03, 0.08, 0.9))
		draw_rect(Rect2(tp - Vector2(16, 12), Vector2(32, 18)), Color("#b45cff"), false, 1.0)
		draw_string(main.ui_font, tp + Vector2(-9, 2), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f2e6ff"))
	# Sora's face in a small round badge marks the player
	var u := c
	draw_circle(u, 5.0 * s, Color("#183070"))
	draw_circle(u, 4.3 * s, Color("#f8f0e0"))
	draw_texture_rect(sora_icon, Rect2(u - Vector2(4, 4) * s, Vector2(8, 8) * s), false)
	# the rim, the N plate and the compass studs are minimap_bezel.gd, drawn over this clip (v0.0.104)

# three steps climbing to the right (up) or going down to the right (down) on a dark round back
func draw_house(at: Vector2, s: float) -> void:
	draw_circle(at, 6.5 * s, Color(0.04, 0.03, 0.08, 0.9))
	draw_arc(at, 6.5 * s, 0.0, TAU, 24, Color("#f0a24a"), 1.0, true)
	var w := 7.0 * s
	var body := Rect2(at.x - w / 2.0, at.y - 0.4 * s, w, 3.6 * s)
	draw_rect(body, Color("#f2e2b0"))
	draw_rect(Rect2(at.x - 0.8 * s, at.y + 0.9 * s, 1.6 * s, 2.3 * s), Color("#6a4024")) # the door
	draw_colored_polygon(PackedVector2Array([Vector2(at.x - w / 2.0 - 0.8 * s, at.y - 0.4 * s), Vector2(at.x + w / 2.0 + 0.8 * s, at.y - 0.4 * s),
		Vector2(at.x, at.y - 4.2 * s)]), Color("#c8503a"))

func draw_stairs(at: Vector2, up: bool, s: float) -> void:
	var step := Color("#ffc23a") if up else Color("#b45cff")
	var tread := Color("#fff4c8") if up else Color("#f2e6ff")
	draw_circle(at, 6.5 * s, Color(0.04, 0.03, 0.08, 0.9))
	draw_arc(at, 6.5 * s, 0.0, TAU, 24, step, 1.0, true)
	var w := 2.6 * s
	for k in 3:
		var h := (k + 1) * 2.6 * s
		var x := at.x - 1.5 * w + (k if up else 2 - k) * w
		var bottom := at.y + 1.5 * 2.6 * s
		draw_rect(Rect2(x, bottom - h, w, h), step)
		draw_rect(Rect2(x, bottom - h, w, maxf(1.0, 0.6 * s)), tread)
