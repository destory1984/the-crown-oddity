# Moon waystones: the list of reached stones and travel between hubs.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

func _init(main: Main) -> void:
	m = main

func way_spot(i: int) -> Vector2:
	match i:
		0: return Vector2(m.shop_pos.x + 2.5, m.shop_pos.z + 1.5)
		1: return m.village.marks.M + Vector2(3.0, -2.5)
		2: return m.lake.marks.P + Vector2(4.0, -1.5)
		3: return m.forest.marks.S + Vector2(2.5, -1.5)
		4: return m.hill.marks.S + Vector2(2.0, -1.5)
		5: return m.castle.marks.S + Vector2(2.5, 1.5)
		6: return m.garden.road_marks.Y
		7: return m.workshop_zone.way_spot() # the deepest awake floor stone under the castle
	return Vector2.ZERO

func way_known(i: int) -> bool:
	match i:
		0: return m.story_step >= 3
		1: return m.story_step >= 8
		2: return m.lake_q >= 1
		3: return m.forest_q >= 1
		4: return m.hill_q >= 1
		5: return m.castle_q >= 1
		6: return m.road_q >= 1
		7: return m.workshop_zone.deepest_way() >= 0
	return false

func build_ways() -> void:
	var stone: Material = m.mat_color(Color("#8a8a94"))
	var moon: Material = m.glow_mat(Color("#bcd6ff"), 0.9)
	for i in Main.WAY_NAMES.size():
		if i == 7: # the workshop's stones stand on its floors (workshop.gd builds them)
			continue
		var at := way_spot(i)
		var g := Node3D.new()
		var b := m.box(Vector3(0.5, 1.2, 0.4), stone)
		b.position = Vector3(0, 0.6, 0)
		g.add_child(b)
		var mm := m.box(Vector3(0.3, 0.3, 0.06), moon)
		mm.position = Vector3(0, 0.9, 0.22)
		g.add_child(mm)
		g.position = Vector3(at.x, m.height_at(at.x, at.y), at.y)
		m.add_child(g)
		m.way_nodes.append(g)
		m.rocks.append({"x": at.x, "z": at.y, "r": 0.35})

func way_near() -> int:
	for i in Main.WAY_NAMES.size():
		if i != 7 and Vector2(m.player.x, m.player.z).distance_to(way_spot(i)) < 1.4:
			return i
	if m.workshop_zone.near_stone():
		return 7
	return -1

func way_key() -> bool:
	if m.way_open:
		toggle_ways(false)
		return true
	if way_near() < 0:
		return false
	toggle_ways(true)
	return true

func toggle_ways(show: bool) -> void:
	m.way_open = show
	m.ui.ways.visible = show
	if show:
		var lines: Array = [tr("달빛 길돌: 숫자 키로 건너가기 (Esc 닫기)"), ""]
		for i in Main.WAY_NAMES.size():
			lines.append("%d   %s" % [i + 1, tr(Main.WAY_NAMES[i]) if way_known(i) else tr("(아직 찾지 못한 길돌)")])
		m.ui.ways_text.text = "\n".join(lines)
		if not m.touch_ui: # the sheet grows with the text size, its bottom kept 8 px over the keys
			var wt: Label = m.ui.ways_text
			var need := wt.get_minimum_size()
			wt.size = need
			m.ui.ways.offset_right = m.ui.ways.offset_left + maxf(400.0, need.x + 32.0)
			m.ui.ways.offset_top = m.ui.ways.offset_bottom - maxf(300.0, need.y + 24.0)

func travel(i: int) -> void:
	toggle_ways(false)
	if not way_known(i) or way_near() == i:
		return
	m.sfx(988, 0.4, "sine", 0.2, -300)
	m.fade_then(func():
		m.gust_dir = Vector2.ZERO
		if m.lake_q == 3: # left the turtle fight: it starts over from the pier
			m.lake_zone.turtle_retry()
		m.in_cave = false
		m.in_village = false
		m.in_forest = false
		m.in_lake = false
		m.in_hill = false
		m.in_garden = false
		m.in_house = -1
		match i:
			0:
				if m.ui.has("outside_map"):
					m.ui.mini.map_tex = m.ui.outside_map
				m.ui.zone_name.text = "갈대늪"
				m.ui.zone_sub.text = "보리 할머니의 오두막"
			1:
				var e0 := m.errand
				m.errand = maxi(m.errand, 1) # no arrival scene again
				m.enter_village()
				m.errand = e0
			2: m.enter_lake()
			3: m.enter_forest()
			4: m.enter_hill()
			5: m.enter_castle()
			6: m.enter_garden()
			7: m.workshop_zone.travel_in()
		var to := way_spot(i) + Vector2(0, 1.2)
		m.player.x = to.x
		m.player.z = to.y
		m.ground_y = m.height_at(to.x, to.y)
		m.snap_mates()
		m.save_game())
