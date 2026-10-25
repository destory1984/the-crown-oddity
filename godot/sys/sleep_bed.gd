# The sleeping villagers' beds (draft 5 of the 10-25 sleep drafts, picked by the owner): a voxel bed with a tall
# headboard and a bedside table, the head picture cut from the sleeper art laid back on the pillow, a stepped
# patchwork quilt that breathes, a lit amber lamp and a faint z Z.
# Everything is built in "bed space": x = across the screen, z = toward the camera (the head is at -z), y = up; the
# caller turns the bed node by CAM_YAW so it stands square to the fixed camera.
# frame() is the furniture (also the room's empty bed by day); sleeper() is the person, the quilt and the lit lamp.
extends RefCounted

const Main := preload("res://main.gd")

const LEAN := 1.2       # radians the head picture leans back from upright (about 21 degrees above the bed)
const WOOD := Color("#6a4a2e")
const CREAM := Color("#e8dcc0")
const LAMP := Vector3(0.78, 0.53, -0.55) # the lamp glass on the bedside table

var m: Main
var sheets: Array = []
var side_col := Color.WHITE # the solid colour of the last quilt built

func _init(main: Node) -> void:
	m = main
	sheets = [load("res://art/folk/sleepers.png"), load("res://art/folk/sleepers2.png")]

func cell_image(who: Array) -> Image:
	var img: Image = (sheets[who[0]] as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	return img.get_region(Rect2i(who[1] * 256, 0, 256, 256))

# a patchwork cut from a sleeper picture: the three cells of its quilt row, trimmed of their stitching, laid in a
# 3 x 4 grid (every other cell mirrored) with thin dark seams
func quilt_tex(who: Array) -> ImageTexture:
	var src := cell_image(who)
	var cells: Array = []
	for c in 3:
		cells.append(src.get_region(Rect2i(10 + c * 78 + 9, 186, 60, 54)))
	var seam: Color = cells[0].get_pixel(30, 27).darkened(0.55)
	var out := Image.create(3 * 60 + 4 * 3, 4 * 54 + 5 * 3, false, Image.FORMAT_RGBA8)
	out.fill(seam)
	for r in 4:
		for c in 3:
			var cell: Image = (cells[(r * 2 + c) % 3] as Image).duplicate()
			if (r + c) % 2 == 1:
				cell.flip_x()
			out.blit_rect(cell, Rect2i(0, 0, 60, 54), Vector2i(3 + c * 63, 3 + r * 57))
	return ImageTexture.create_from_image(out)

func add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var b := m.box(size, mat)
	b.position = pos
	parent.add_child(b)
	return b

func col_box(parent: Node3D, size: Vector3, pos: Vector3, col: Color) -> MeshInstance3D:
	return add_box(parent, size, pos, m.mat_color(col))

# the slow breathing: only this node rises 0.015 over 4 s, each bed on its own phase
func breathe(n: Node3D, phase: float) -> void:
	var base := n.position.y
	var start := func() -> void:
		var tw := n.create_tween().set_loops()
		tw.tween_property(n, "position:y", base + 0.015, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(n, "position:y", base, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	m.get_tree().create_timer(maxf(phase, 0.01)).timeout.connect(start)

# the bed itself: frame, mattress, pillow, headboard with posts, bedside table with the unlit lamp, floor shadow
func frame(parent: Node3D) -> void:
	col_box(parent, Vector3(0.80, 0.20, 1.50), Vector3(0, 0.10, 0), WOOD)
	col_box(parent, Vector3(0.72, 0.12, 1.40), Vector3(0, 0.26, 0), CREAM)
	col_box(parent, Vector3(0.62, 0.08, 0.40), Vector3(0, 0.36, -0.50), Color("#f4f0e8"))
	col_box(parent, Vector3(0.84, 0.70, 0.08), Vector3(0, 0.45, -0.79), WOOD)
	for sx in [-0.42, 0.42]:
		col_box(parent, Vector3(0.09, 0.95, 0.09), Vector3(sx, 0.475, -0.79), WOOD.darkened(0.15))
	col_box(parent, Vector3(0.38, 0.40, 0.34), Vector3(LAMP.x, 0.20, LAMP.z), WOOD.lightened(0.1))
	col_box(parent, Vector3(0.14, 0.04, 0.14), Vector3(LAMP.x, 0.42, LAMP.z), Color("#2a2a2e"))
	col_box(parent, Vector3(0.12, 0.18, 0.12), LAMP, Color("#8a6a48")) # the lamp glass, dark until someone sleeps
	var sh: MeshInstance3D = m.sora.soft_patch(1.15, 1.8, 0.5)
	sh.position = Vector3(0, 0.004, 0.02)
	parent.add_child(sh)

# the sleeper on a frame(): head picture, breathing quilt, the lamp lit (glass and light) and the drifting z Z
func sleeper(parent: Node3D, who: Array, phase: float) -> void:
	var spr := Sprite3D.new() # the head and pillow cut from the picture; its lower edge ends under the quilt
	spr.texture = sheets[who[0]]
	spr.region_enabled = true
	spr.region_rect = Rect2(who[1] * 256, 0, 256, 150)
	spr.pixel_size = 0.70 / 256.0
	spr.offset = Vector2(0, 75)
	spr.rotation.x = -LEAN
	spr.scale = Vector3(1, 1.0 / cos(0.78 - LEAN), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	spr.modulate = Color(0.86, 0.84, 0.95) # a little dimmed for the night
	spr.position = Vector3(0, 0.40, -0.24)
	parent.add_child(spr)
	breathe(quilt(parent, who, -0.18, 0.88, 0.68, 0.32, 0.18), phase)
	add_box(parent, Vector3(0.125, 0.185, 0.125), LAMP, m.glow_mat(Color("#ffb868"), 1.2))
	var l := OmniLight3D.new()
	l.light_color = Color("#ffb060")
	l.light_energy = 1.2
	l.omni_range = 2.6
	l.position = Vector3(LAMP.x, 0.75, -0.45)
	parent.add_child(l)
	var z := Label3D.new()
	z.text = "z Z"
	z.font = m.ui_font
	z.font_size = 28
	z.pixel_size = 0.0045
	z.modulate = Color("#eef3ff")
	z.modulate.a = 0.55
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.position = Vector3(-0.55, 0.95, -0.4)
	parent.add_child(z)
	var tw := z.create_tween().set_loops()
	tw.tween_property(z, "position:y", 1.3, 2.4).from(0.95)
	tw.parallel().tween_property(z, "modulate:a", 0.0, 2.4).from(0.55)

# a stepped quilt mound: a wide low block and a narrower one on it, solid sides and the patchwork on each top
func quilt(parent: Node3D, who: Array, z0: float, len: float, w: float, y0: float, h: float) -> Node3D:
	var q := Node3D.new()
	q.position = Vector3(0, 0, z0 + len / 2.0)
	parent.add_child(q)
	var tex := quilt_tex(who)
	var avg := tex.get_image().duplicate()
	avg.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	side_col = avg.get_pixel(0, 0).darkened(0.12)
	var side := m.mat_color(side_col)
	var top := m.mat_color(Color.WHITE, 0.95)
	top.albedo_texture = tex
	top.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var low := h * 0.62
	var steps := [[Vector3(w, low, len), y0, 0.0], [Vector3(w * 0.86, h - low, len * 0.84), y0 + low, -len * 0.02]]
	for st in steps:
		var sz: Vector3 = st[0]
		add_box(q, sz, Vector3(0, st[1] + sz.y / 2.0, st[2]), side)
		var pl := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(sz.x - 0.02, sz.z - 0.02)
		pl.mesh = pm
		pl.material_override = top
		pl.position = Vector3(0, st[1] + sz.y + 0.002, st[2])
		q.add_child(pl)
	return q
