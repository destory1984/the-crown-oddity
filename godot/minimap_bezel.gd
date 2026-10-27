# The minimap's brass bezel (draft 1 of five, the owner's pick 2026-10-27): a 28-tooth brass gear with a thin gold inner
# ring drawn over the round map, the N plate and the E/S/W studs riding its band at the true compass points. The N plate
# turns to face north, so at the usual camera the letter leans about 45 degrees (the owner: "N자는 45도 기울여").
extends Control

const SQUASH := 0.62 # as minimap.gd
const BAND := 79.1   # px from the centre to the middle of the band (the ring drawn in the old 186 px box)
const PLATE_PX := 31.6
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
	for w in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]: # E, S, W
		var p: Vector2 = c + _dir(w) * BAND
		draw_texture_rect(STUD, Rect2(p - Vector2(5.5, 5.5), Vector2(11, 11)), false)
	var n := _dir(Vector2.UP)
	var h := Vector2(PLATE_PX, PLATE_PX) / 2.0
	draw_set_transform(c + n * BAND, n.angle() + PI / 2.0, Vector2.ONE)
	draw_texture_rect(PLATE, Rect2(-h, h * 2.0), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
