# Five sleeping-villager design drafts for the shot scenes "sleep_drafts" and "sleep_draft1".."sleep_draft5".
# Used only by those scenes (sys/scenes.gd); the game's real sleepers (sys/folk.gd) are untouched. Once the owner
# picks a draft, its builder (bed_1 .. bed_5) can move into folk.gd as it is.
# Every draft is built in "bed space": x = across the screen, z = toward the camera (the head is at -z), y = up.
# The stage root is turned by cam_yaw, so the beds stand square to the fixed camera and show the face best.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const CAPTIONS := ["뼈대 침대와
머리 그림", "바닥
이불자리", "그림을 눕힌
손쉬운 고침", "통째로
블록 사람", "머리판과
등불 침대"]
# who sleeps in each draft: [sheet, cell] as in folk.gd SLEEP_ART (Doran, Kongal, Dusol, Yeoul, Tori)
const WHO := [[0, 0], [0, 1], [1, 0], [1, 3], [1, 5]]
const LEAN := 1.2       # radians a head picture leans back from upright (about 21 degrees above the bed)
const SPACING := 2.3
const WOOD := Color("#6a4a2e")
const CREAM := Color("#e8dcc0")

var stage: Node3D
var sheets: Array = []
var side_col := Color.WHITE # the solid colour of the last quilt built

func _init(main: Node) -> void:
	m = main

# ---- small helpers -----------------------------------------------------------------------------------------

func cell_image(who: Array) -> Image:
	var tex: Texture2D = sheets[who[0]]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	return img.get_region(Rect2i(who[1] * 256, 0, 256, 256))

func tex_of(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

# a patchwork cut from a sleeper picture: the three cells of its quilt row, trimmed of their stitching, laid in a
# 3 x 4 grid (every other cell mirrored) with thin dark seams
func quilt_tex(who: Array) -> ImageTexture:
	var src := cell_image(who)
	var cells: Array = []
	for c in 3:
		var cell := src.get_region(Rect2i(10 + c * 78 + 9, 186, 60, 54))
		cells.append(cell)
	var seam: Color = cells[0].get_pixel(30, 27).darkened(0.55)
	var out := Image.create(3 * 60 + 4 * 3, 4 * 54 + 5 * 3, false, Image.FORMAT_RGBA8)
	out.fill(seam)
	for r in 4:
		for c in 3:
			var cell: Image = (cells[(r * 2 + c) % 3] as Image).duplicate()
			if (r + c) % 2 == 1:
				cell.flip_x()
			out.blit_rect(cell, Rect2i(0, 0, 60, 54), Vector2i(3 + c * 63, 3 + r * 57))
	return tex_of(out)

func tex_mat(t: Texture2D) -> StandardMaterial3D:
	var mat := m.mat_color(Color.WHITE, 0.95)
	mat.albedo_texture = t
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat

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

func shadow(bed: Node3D, w: float, d: float) -> void:
	var sh: MeshInstance3D = m.sora.soft_patch(w, d, 0.5)
	sh.position = Vector3(0, 0.004, 0.02)
	bed.add_child(sh)

# the head and pillow cut from a sleeper picture, laid back onto the bed; its lower edge ends under the quilt
func head_sprite(who: Array, width: float, pos: Vector3, rows := 150) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = sheets[who[0]]
	spr.region_enabled = true
	spr.region_rect = Rect2(who[1] * 256, 0, 256, rows)
	spr.pixel_size = width / 256.0
	spr.offset = Vector2(0, rows / 2.0)
	spr.rotation.x = -LEAN
	spr.scale = Vector3(1, 1.0 / cos(0.78 - LEAN), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	spr.modulate = Color(0.86, 0.84, 0.95) # a little dimmed for the night
	spr.position = pos
	return spr

# a stepped quilt mound: a wide low block and a narrower one on it, solid sides and the patchwork on each top
func quilt(bed: Node3D, who: Array, z0: float, len: float, w: float, y0: float, h: float) -> Node3D:
	var q := Node3D.new()
	q.position = Vector3(0, 0, z0 + len / 2.0)
	bed.add_child(q)
	var tex := quilt_tex(who)
	var avg := tex.get_image().duplicate()
	avg.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	side_col = avg.get_pixel(0, 0).darkened(0.12)
	var side := m.mat_color(side_col)
	var top := tex_mat(tex)
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

func frame_and_mattress(bed: Node3D) -> void:
	col_box(bed, Vector3(0.80, 0.20, 1.50), Vector3(0, 0.10, 0), WOOD)
	col_box(bed, Vector3(0.72, 0.12, 1.40), Vector3(0, 0.26, 0), CREAM)

# ---- the five drafts ---------------------------------------------------------------------------------------

# 1  voxel bed, sprite head
func bed_1(bed: Node3D, who: Array, phase: float) -> void:
	frame_and_mattress(bed)
	col_box(bed, Vector3(0.62, 0.08, 0.40), Vector3(0, 0.36, -0.50), Color("#f4f0e8"))
	bed.add_child(head_sprite(who, 0.70, Vector3(0, 0.40, -0.24)))
	breathe(quilt(bed, who, -0.18, 0.88, 0.68, 0.32, 0.18), phase)
	shadow(bed, 1.15, 1.8)

# 2  floor futon: no frame, a light border round the mattress
func bed_2(bed: Node3D, who: Array, phase: float) -> void:
	col_box(bed, Vector3(0.85, 0.09, 1.45), Vector3(0, 0.045, 0), Color("#f0e8d4"))
	col_box(bed, Vector3(0.71, 0.02, 1.31), Vector3(0, 0.10, 0), Color("#6f86a8"))
	col_box(bed, Vector3(0.60, 0.08, 0.35), Vector3(0, 0.15, -0.5), Color("#f4f0e8"))
	bed.add_child(head_sprite(who, 0.62, Vector3(0, 0.15, -0.20)))
	breathe(quilt(bed, who, -0.16, 0.88, 0.78, 0.11, 0.16), phase)
	shadow(bed, 1.2, 1.8)

# 3  cheap fix: the whole picture laid back on a right-sized mattress, quilt carried on to the foot by a flat slab
func bed_3(bed: Node3D, who: Array, phase: float) -> void:
	frame_and_mattress(bed)
	var spr := Sprite3D.new()
	spr.texture = sheets[who[0]]
	spr.region_enabled = true
	spr.region_rect = Rect2(who[1] * 256, 0, 256, 256)
	spr.pixel_size = 0.72 / 256.0
	spr.offset = Vector2(0, 128)
	spr.rotation.x = -LEAN
	spr.scale = Vector3(1, 1.0 / cos(0.78 - LEAN), 1)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.shaded = false
	spr.modulate = Color(0.86, 0.84, 0.95)
	spr.position = Vector3(0, 0.34, 0.0)
	bed.add_child(spr)
	var slab := add_box(bed, Vector3(0.70, 0.04, 0.72), Vector3(0, 0.34, 0.36), tex_mat(quilt_tex(who)))
	breathe(spr, phase)
	slab.name = "foot_slab"
	shadow(bed, 1.15, 1.8)

# 4  fully voxel: a blocky head with the face picture on its top, stepped quilt with a rise at the feet
func bed_4(bed: Node3D, who: Array, phase: float) -> void:
	frame_and_mattress(bed)
	col_box(bed, Vector3(0.62, 0.08, 0.45), Vector3(0, 0.36, -0.45), Color("#f4f0e8"))
	var img := cell_image(who)
	var hair := img.get_pixel(128, 22)
	if hair.a < 0.5:
		hair = img.get_pixel(128, 40)
	col_box(bed, Vector3(0.38, 0.30, 0.34), Vector3(0, 0.55, -0.52), hair) # the head, on the pillow
	var face := Sprite3D.new() # the face picture on the head's camera-facing side
	face.texture = tex_of(img.get_region(Rect2i(46, 10, 164, 134)))
	face.pixel_size = 0.38 / 164.0
	face.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	face.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	face.shaded = false
	face.modulate = Color(0.86, 0.84, 0.95)
	face.position = Vector3(0, 0.55, -0.345)
	bed.add_child(face)
	var q := quilt(bed, who, -0.18, 0.88, 0.68, 0.32, 0.18)
	col_box(q, Vector3(0.44, 0.07, 0.26), Vector3(0, 0.535, 0.26), side_col.lightened(0.1)) # the feet make a small rise
	breathe(q, phase)
	shadow(bed, 1.15, 1.8)

# 5  draft 1 plus a tall headboard, a bedside table with a dim amber lamp, and a faint z Z with normal depth test
func bed_5(bed: Node3D, who: Array, phase: float) -> void:
	bed_1(bed, who, phase)
	col_box(bed, Vector3(0.84, 0.70, 0.08), Vector3(0, 0.45, -0.79), WOOD)
	for sx in [-0.42, 0.42]:
		col_box(bed, Vector3(0.09, 0.95, 0.09), Vector3(sx, 0.475, -0.79), WOOD.darkened(0.15))
	col_box(bed, Vector3(0.38, 0.40, 0.34), Vector3(0.78, 0.20, -0.55), WOOD.lightened(0.1))
	col_box(bed, Vector3(0.14, 0.04, 0.14), Vector3(0.78, 0.42, -0.55), Color("#2a2a2e"))
	var glass := m.glow_mat(Color("#ffb868"), 1.2)
	col_box(bed, Vector3(0.12, 0.18, 0.12), Vector3(0.78, 0.53, -0.55), Color("#ffb868")).material_override = glass
	var l := OmniLight3D.new()
	l.light_color = Color("#ffb060")
	l.light_energy = 1.2
	l.omni_range = 2.6
	l.position = Vector3(0.78, 0.75, -0.45)
	bed.add_child(l)
	var z := Label3D.new()
	z.text = "z Z"
	z.font = m.ui_font
	z.font_size = 28
	z.pixel_size = 0.0045
	z.modulate = Color("#eef3ff")
	z.modulate.a = 0.55
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.position = Vector3(-0.55, 0.95, -0.4)
	bed.add_child(z)
	var tw := z.create_tween().set_loops()
	tw.tween_property(z, "position:y", 1.3, 2.4).from(0.95)
	tw.parallel().tween_property(z, "modulate:a", 0.0, 2.4).from(0.55)

# ---- the stage -----------------------------------------------------------------------------------------------

# builds the room and the five beds at `at` (world x, z); returns the world position the camera should look at for
# draft `focus` (0..4), or for the whole row when focus is -1
func build(at: Vector2, focus: int) -> Vector3:
	sheets = [load("res://art/folk/sleepers.png"), load("res://art/folk/sleepers2.png")]
	stage = Node3D.new()
	stage.position = Vector3(at.x, 0, at.y)
	stage.rotation.y = m.cam_yaw
	m.add_child(stage)
	col_box(stage, Vector3(15.0, 0.4, 6.4), Vector3(0, -0.2, 0.5), Color("#7a5a3c"))
	col_box(stage, Vector3(15.0, 2.4, 0.3), Vector3(0, 1.2, -2.5), Color("#8a7a62"))
	var roomlight := OmniLight3D.new() # the room at night: one warm hearth glow, dim
	roomlight.light_color = Color("#ffc890")
	roomlight.light_energy = 0.85
	roomlight.omni_range = 14.0
	roomlight.position = Vector3(0, 3.2, 1.8)
	stage.add_child(roomlight)
	var standing := m.folk_sprite("doran") # a standing villager next to the beds, for the size
	standing.position = Vector3(-6.2, 0, 0.5)
	stage.add_child(standing)
	for k in 5:
		var bed := Node3D.new()
		bed.position = Vector3((k - 2) * SPACING, 0, 0)
		stage.add_child(bed)
		call("bed_%d" % (k + 1), bed, WHO[k], 0.7 * k)
		var num := Label3D.new()
		num.text = str(k + 1)
		num.font = m.ui_font
		num.font_size = 120
		num.pixel_size = 0.012
		num.modulate = Color("#fff3c8")
		num.outline_size = 24
		num.outline_modulate = Color("#3a2414")
		num.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		num.no_depth_test = true
		num.position = Vector3(bed.position.x, 1.75, -0.5)
		stage.add_child(num)
		var cap := Label3D.new()
		cap.text = tr(CAPTIONS[k])
		cap.font = m.ui_font
		cap.font_size = 38
		cap.pixel_size = 0.0075
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.modulate = Color("#fff3c8")
		cap.outline_size = 12
		cap.outline_modulate = Color("#3a2414")
		cap.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		cap.no_depth_test = true
		cap.position = Vector3(bed.position.x, 0.02, 1.55)
		stage.add_child(cap)
	var local := Vector3(0, 0, 0.3) if focus < 0 else Vector3((focus - 2) * SPACING, 0.35, 0.75)
	return stage.to_global(local)
