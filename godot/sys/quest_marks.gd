# The gold "!" for the quest line and the side step under it (the owner, 2026-10-26: "게임 진행에 꼭 필요한 것들은
# 미니맵에 표시하고, 느낌표 표시!"): the fixed thing or place in the area Sora stands in that the line sends her to next.
# castle_zone.step_target asks here after its own marks; minimap.gd draws the same spot, so the two never disagree.
# Moving fights (shore packs, mold shards) and lines with no place (rest at night, the wind run) get none.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const VILLAGE_WAY := Vector2(47.0, 20.5) # where the marsh's east bank walks into the village
# the main road's lines and the area each one heads for, in the order the road runs east
const ROAD_GOALS := [["물결과 함께 남쪽 호수를 풀자", "lake"], ["마을 남쪽 문으로 호수에", "lake"],
	["물결과 함께 마을 동쪽 문으로", "forest"], ["숲 동쪽 끝 길로", "hill"], ["언덕 동쪽 끝 길로", "castle"],
	["동쪽 문을 지나 정원 한가운데로", "garden"], ["꼭대기 문을 지나 정원으로", "garden"], ["정원 한가운데로 돌아가", "garden"]]

func _init(main: Main) -> void:
	m = main

func quest_target() -> Vector3:
	if m.intro or m.story_open or m.in_house >= 0:
		return Vector3.INF
	var at := line_target(m.quest_raw)
	if at == Vector3.INF:
		at = side_target()
	return at

# a line built from a translated pattern ("... %d/3") begins with the pattern's words in any language
func led(raw: String, pattern: String) -> bool:
	return raw.begins_with(pattern.split("%")[0]) or raw.begins_with(tr(pattern).split("%")[0])

func over(p: Vector2, h := 2.2) -> Vector3:
	return Vector3(p.x, m.height_at(p.x, p.y) + h, p.y)

func nearest(spots: Array) -> Vector2:
	var me := Vector2(m.player.x, m.player.z)
	var best := Vector2.INF
	for p: Vector2 in spots:
		if best == Vector2.INF or me.distance_to(p) < me.distance_to(best):
			best = p
	return best

func foe_at(key: String) -> Vector2:
	for e in m.enemies:
		if not e.dead and e.get(key, false):
			return Vector2(e.x, e.z)
	return Vector2.INF

func either(p: Vector2, fallback: Vector2, h := 2.2) -> Vector3:
	var at := p if p != Vector2.INF else fallback
	return Vector3.INF if at == Vector2.INF else over(at, h)

func road_goal(raw: String) -> String:
	for g in ROAD_GOALS:
		if raw.begins_with(g[0]):
			return g[1]
	return ""

func here() -> String:
	if m.in_cave: return "cave"
	if m.in_village: return "village"
	if m.in_forest: return "forest"
	if m.in_garden: return "clock" if m.garden_zone.in_clock() else "garden"
	if m.in_lake: return "grotto" if m.in_grotto() else "lake"
	if m.in_hill:
		if m.in_castle(): return "castle"
		if m.in_stairs(): return "stairs"
		if m.in_cloud() or m.in_under() or m.in_workshop(): return ""
		return "hill"
	return "marsh"

# the way out of this area toward the road's goal
func road_way(goal: String) -> Vector3:
	var east := ["forest", "hill", "castle", "garden"]
	match here():
		"marsh":
			return over(VILLAGE_WAY) if m.story_step >= 7 else Vector3.INF
		"village":
			return over(m.village.marks.K if goal == "lake" else m.village.marks.F)
		"lake":
			return Vector3.INF if goal == "lake" else over(m.lake.marks.S)
		"forest":
			return over(m.forest.marks.E) if goal in east.slice(1) else Vector3.INF
		"hill":
			return over(m.hill.marks.X) if goal in east.slice(2) else Vector3.INF
		"castle":
			return over(m.castle.marks.E) if goal == "garden" else Vector3.INF
		"stairs":
			return over(m.stairs.marks.N) if goal == "garden" else Vector3.INF
		"garden":
			return over(m.garden.marks.C) if goal == "garden" and m.garden_q >= 1 else Vector3.INF
	return Vector3.INF

func line_target(raw: String) -> Vector3:
	if raw == "":
		return Vector3.INF
	var at := Vector3.INF
	match here():
		"marsh": at = marsh_target(raw)
		"cave": at = cave_target(raw)
		"village": at = village_target(raw)
		"lake": at = lake_target(raw)
		"forest": at = forest_target(raw)
		"hill": at = hill_target(raw)
		"castle": at = castle_target(raw)
		"stairs": at = stairs_target(raw)
		"garden": at = garden_target(raw)
		"clock": at = clock_target(raw)
	if at == Vector3.INF and road_goal(raw) != "":
		at = road_way(road_goal(raw))
	return at

func marsh_target(raw: String) -> Vector3:
	if raw.contains("오두막") and m.cottage_at.x >= 0.0:
		return over(m.cottage_at, 3.2)
	if raw.begins_with(Main.BORI_QUEST) or raw.contains("벽돌왕이"):
		return either(foe_at("boss"), Vector2.INF, 4.6)
	if raw.contains("노를 건져") and m.oar_node != null and m.oar_node.visible:
		return over(m.errands.OAR_AT, 1.6)
	if raw.begins_with("동쪽 강을"):
		return over(VILLAGE_WAY)
	return Vector3.INF

func cave_target(raw: String) -> Vector3:
	var cm: Dictionary = m.cave_marks
	if raw.begins_with("동굴 깊은 곳") and not m.saw_painting:
		return over(cm.P)
	if raw.begins_with("열쇠를 찾아") and not m.has_key:
		return over(cm.K, 1.8)
	if raw.begins_with("얻은 열쇠로") and not m.cave_door_open:
		return over(cm.D)
	if raw == Main.CAVE_DOOR_QUEST:
		return either(foe_at("mole"), cm.B, 3.4)
	if raw.begins_with("동쪽 출구로"):
		return over(cm.E)
	return Vector3.INF

func folk_spot(id: String) -> Vector3:
	var p: Vector2 = m.folk.folk_talk_at(id)
	return Vector3.INF if p.x == INF else Vector3(p.x, m.folk_height(id) / cos(0.78) + 0.7, p.y)

func village_target(raw: String) -> Vector3:
	var vx := float(Main.VILLAGE.VILLAGE_X)
	if raw.contains("등불지기"):
		return over(m.village.marks.M, 2.9)
	if led(raw, "동쪽 끝 꺼진 등불을 팔찌로 켜자 (E) %d/3"):
		var dark: Array = []
		for d in m.village.dark:
			if not d.lit:
				dark.append(Vector2(d.light.position.x, d.light.position.z))
		return either(nearest(dark), Vector2.INF, 2.8)
	if raw.contains("콩알이 울고"):
		return folk_spot("kongal")
	if raw.begins_with("도란의 편지"):
		return folk_spot("doran")
	if raw.contains("꼬마 고블린을 찾자") and m.kid_node != null and m.kid_q == 1:
		return over(Vector2(m.kid_node.position.x, m.kid_node.position.z), 1.6)
	if raw.contains("노을을 쫓자") and m.noeul_node != null and m.noeul_node.visible:
		return over(Vector2(m.noeul_node.position.x, m.noeul_node.position.z), 2.9)
	if raw.contains("노을과 겨루자"):
		return either(foe_at("noeul"), m.village_life.NOEUL_DUEL_AT + Vector2(vx, 0), 2.9)
	return Vector3.INF

func lake_target(raw: String) -> Vector3:
	if raw.begins_with("수문의 벽돌") and m.lake_q == 1:
		return over(m.lake.marks.D)
	if raw.contains("물결에게 말을 걸자") and m.lake_npc != null and m.lake_npc.visible:
		return over(Vector2(m.lake_npc.position.x, m.lake_npc.position.z), 2.9)
	if raw.contains("벽돌 거북"):
		return either(foe_at("turtle"), m.lake.marks.T, 3.4)
	return Vector3.INF

# the next shut wall on the way east (the walls stand across the path, so the nearest one ahead is the next)
func forest_way(goal: Vector2) -> Vector3:
	var me := Vector2(m.player.x, m.player.z)
	var shut: Array = []
	for w in m.forest.walls:
		if not w.open and w.pos.x > me.x - 1.0 and w.pos.x < goal.x:
			shut.append(w.pos)
	return over(nearest(shut)) if not shut.is_empty() else over(goal, 2.9)

func forest_target(raw: String) -> Vector3:
	if raw.contains("노을에게 가자"):
		return forest_way(m.forest.marks.N)
	if raw.begins_with("닫힌 벽돌 벽을"):
		return forest_way(m.forest.marks.E)
	if raw.begins_with("노을과 다시 겨루자"):
		return either(foe_at("noeul"), m.forest.marks.N, 2.9)
	return Vector3.INF

func hill_target(raw: String) -> Vector3:
	if led(raw, "풍차를 팔찌로 감자 (E) %d/3"):
		var still: Array = []
		for mill in m.hill.mills:
			if not mill.turning:
				still.append(mill.pos)
		return either(nearest(still), Vector2.INF, 4.2)
	if raw.contains("벽돌 매를"):
		return either(foe_at("hawk"), m.hill.marks.B, 4.4)
	if led(raw, "깃대에서 E: 바람 부르기 다시 (%d번째)") and m.hill.south_marks.has("P"):
		return over(m.hill.south_marks.P, 2.6)
	return Vector3.INF

func castle_target(raw: String) -> Vector3:
	if raw.begins_with("성문의 벽돌") and not m.castle.gate_open:
		var gate: Array = m.castle.gate_nodes.map(func(n): return Vector2(n.position.x, n.position.z))
		return either(nearest(gate), Vector2.INF)
	if led(raw, "성 안에 흩어진 한결의 일기를 찾자 (E) %d/3"):
		var unread: Array = []
		for pg in m.castle.pages:
			if not pg.read:
				unread.append(pg.pos)
		return either(nearest(unread), Vector2.INF, 1.9)
	if raw.begins_with("옥좌의 방"):
		return either(foe_at("knight"), m.castle.marks.K, 3.2)
	return Vector3.INF

func stairs_target(raw: String) -> Vector3:
	if not m.stairs.wall_open:
		var wall: Array = m.stairs.wall_nodes.map(func(n): return Vector2(n.position.x, n.position.z))
		return either(nearest(wall), Vector2.INF)
	if not m.stairs.door_open: # past the wall every line climbs to the top landing's lamps
		var dark: Array = []
		for l in m.stairs.lamps:
			if not l.lit:
				dark.append(l.pos)
		return either(nearest(dark), Vector2.INF, 2.6)
	if road_goal(raw) == "garden":
		return over(m.stairs.marks.N)
	return Vector3.INF

func garden_target(raw: String) -> Vector3:
	var gm: Dictionary = m.garden.marks
	if raw.begins_with("뿌리 벽돌") and not m.garden.roots_open:
		return either(nearest(m.garden.roots.map(func(r): return r[0])), Vector2.INF)
	if raw.begins_with("한결의 야영터"):
		return over(m.garden.road_marks.j, 1.9)
	if raw.begins_with("깊은 틈 위"): # the far side of the gap, where his echo waits
		return over(Vector2(Main.GARDEN.GARDEN_X + 13.5, 24.0))
	if raw.begins_with("회색 문을 지나"):
		var gate: Array = m.garden.gate_nodes.map(func(n): return Vector2(n.position.x, n.position.z))
		return either(nearest(gate), gm.C)
	if led(raw, "거푸집 둘레의 벽돌 봉인을 풀자 (E) %d/3"):
		var shut: Array = []
		for sl in m.garden.seals:
			if not sl.open:
				shut.append(sl.pos)
		return either(nearest(shut), Vector2.INF)
	if raw.contains("거푸집의 심장"):
		return either(foe_at("mold"), gm.C, 4.6)
	if raw.begins_with("두 팔을 높이") or raw.begins_with("이야기 끝 · 정원 한가운데 구멍"): # the hole down to the clock room; the free-roam line has no mark
		return over(gm.C, 2.6)
	return Vector3.INF

# the clock room's steps: the nearest hard gear, the key, then Hangyeol's handle
func clock_target(raw: String) -> Vector3:
	var cm: Dictionary = m.garden.clock_marks
	if led(raw, "시계방의 굳은 톱니를 팔찌로 풀자 (E) %d/3"):
		var hard: Array = []
		for i in m.garden.gears.size():
			if not m.clock_gears[i]:
				hard.append(m.garden.gears[i].pos)
		return either(nearest(hard), Vector2.INF, 1.8)
	if raw.begins_with("태엽 열쇠 한가운데"):
		return over(cm.O, 2.4)
	if raw.begins_with("한결의 손잡이"):
		return over(cm.J, 1.9)
	return Vector3.INF

# the shore's side step under the quest (the owner hit "물가에 걸린 것을 보자" with nothing on the minimap)
func side_target() -> Vector3:
	var s: String = m.shore.side_step()
	if s == "":
		return Vector3.INF
	if s.begins_with("물가에 걸린") or s.contains("진흙을 풀자"):
		return over(Main.MARSH.BASKET_AT, 1.6)
	if s.begins_with("보리 할머니께") and m.cottage_at.x >= 0.0:
		return over(m.cottage_at, 3.2)
	if led(s, "바구니를 따라가 걸림을 풀자 %d/3") and m.marsh.float_node.visible:
		var p: Vector3 = m.marsh.float_node.position
		return over(Vector2(p.x, p.z), 1.6)
	return Vector3.INF
