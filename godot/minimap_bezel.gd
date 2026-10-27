# The minimap's bezel (glass draft 3, the owner's pick 2026-10-27, after Time Oddity's night-sky glass dial): a band of
# deep-blue glass with star dust, a dashed gold path and a gold bevel drawn over the round map, with seven gold stars and
# the N plate riding the path at the eight true compass points (the eight moons). The N plate turns to face north, so at
# the usual camera the letter leans about 45 degrees (the owner: "N자는 45도 기울여").
extends Control

const SQUASH := 0.62 # as minimap.gd
const BAND := 83.0   # px from the centre to the dashed path the stars ride
const PLATE_PX := 48.0
const STAR_PX := 12.0
const RING := preload("res://art/ui/mm_ring.png")
const PLATE := preload("res://art/ui/mm_n_plate.png")
const STUD := preload("res://art/ui/mm_stud.png")
var main: Node
var mask: Control # the map's clip: the bezel shows and hides with it (the shop steps it aside)

func _process(_dt: float) -> void:
	visible = mask == null or mask.visible
	queue_redraw()

# a world direction as it lies on the squashed, turned map
func _dir(w: Vector2) -> Vector2:
	var r := w.rotated(main.cam_yaw)
	return Vector2(r.x, r.y * SQUASH).normalized()

func _draw() -> void:
	var c := size / 2.0
	draw_texture_rect(RING, Rect2(Vector2.ZERO, size), false)
	for k in range(1, 8): # NE round to NW: a star at each of the other seven compass points
		var p: Vector2 = c + _dir(Vector2.UP.rotated(k * PI / 4.0)) * BAND
		draw_texture_rect(STUD, Rect2(p - Vector2(STAR_PX, STAR_PX) / 2.0, Vector2(STAR_PX, STAR_PX)), false)
	var n := _dir(Vector2.UP)
	var h := Vector2(PLATE_PX, PLATE_PX) / 2.0
	draw_set_transform(c + n * BAND, n.angle() + PI / 2.0, Vector2.ONE)
	draw_texture_rect(PLATE, Rect2(-h, h * 2.0), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
