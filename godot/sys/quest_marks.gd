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
	["동쪽 문을 지나 정원 한가운데로", "garden"], ["꼭대기 문을 지나 정원으로", "garden"], ["정원 한가운데로 돌아가", "garden"],
	["숲으로 가기 전에", "lake"], ["언덕으로 가기 전에", "forest"], ["성으로 가기 전에", "hill"],
	["옥좌의 방으로 가기 전에", "castle"], ["달의 계단을 오르기 전에", "castle"]] # the moonkeeper tokens' gate lines (sys/tokens.gd)

func _init(main: Main) -> void:
	m = main

func quest_target() -> Vector3:
	if m.intro or m.story_open or m.in_house >= 0:
		return Vector3.INF
	if m.in_corridor(): # the water corridor reads its own devices (v0.1.84): the first unfinished condition, not the line's words
		return m.corridor_zone.next_spot()
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
	if m.in_lake: return "corridor" if m.in_corridor() else ("grotto" if m.in_grotto() else "lake")
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
		"grotto": # the pearl is in and the line moved on to the east gate: out of the grotto first
			return over(m.grotto.marks.S)
		"forest":
			return over(m.forest.marks.E) if goal in east.slice(1) else Vector3.INF
		"hill":
			return over(m.hill.marks.X) if goal in east.slice(2) else Vector3.INF
		"castle":
			return over(m.castle.marks.E) if goal == "garden" else Vector3.INF
		"stairs":
			if goal == "castle": # the castle's quarters gate line: back down
				return over(m.stairs.marks.S)
			return over(m.stairs.marks.N) if goal == "garden" else Vector3.INF
		"garden":
			return over(m.garden.marks.C) if goal == "garden" and m.garden_q >= 1 else Vector3.INF
	return Vector3.INF

# a separate area with no line of its own (the cloud mound, the workshop floors; the undercroft keeps its own quiet lamp marks): the line leads out of it, so mark
# its exit; the grotto and the clock room do the same in their own target functions
func back_way() -> Vector3:
	if m.in_workshop():
		return over(m.workshop_zone.fl(m.workshop_zone.floor_here()).marks.S, 2.0)
	if m.in_cloud():
		return over(m.cloud.marks.S)
	return Vector3.INF

func line_target(raw: String) -> Vector3:
	if raw == "":
		return Vector3.INF
	var at := Vector3.INF
	if m.in_workshop(): # the deep workshop is no area of the road: its own steps for the moon door's gate, else the way up and out
		if raw.begins_with("옥좌의 방으로 가기 전에") and not m.moon_tokens.workshop_done():
			return m.workshop_zone.next_spot()
		if m.moon_tokens.holds("knight") and not m.moon_tokens.workshop_done(): # in early by the diary's discovery line: the work lamps, whatever the main line says
			return m.workshop_zone.next_spot()
		return back_way()
	match here():
		"marsh": at = marsh_target(raw)
		"cave": at = cave_target(raw)
		"village": at = village_target(raw)
		"lake": at = lake_target(raw)
		"grotto": at = grotto_target(raw)
		"corridor": at = m.corridor_zone.next_spot()
		"forest": at = forest_target(raw)
		"hill": at = hill_target(raw)
		"castle": at = castle_target(raw)
		"stairs": at = stairs_target(raw)
		"garden": at = garden_target(raw)
		"clock": at = clock_target(raw)
	if at == Vector3.INF and road_goal(raw) != "":
		at = road_way(road_goal(raw))
	if at == Vector3.INF and here() == "":
		at = back_way()
	if at == Vector3.INF and led(raw, "정원 문 앞에서: 달지기 표식 %d/4를 밝히자 (일지 Q)"):
		at = token_target()
	return at

# ---- the stairs' door line "정원 문 앞에서: ... n/4": the nearest missing token's deed, or the way out toward it
const TOKEN_AREA := {5: "castle", 4: "hill", 3: "forest", 2: "lake"} # library, hill deed, squirrels, pearl (the fly jar and the ring have no spot on this road)
const TOKEN_CHAIN := ["lake", "forest", "hill", "castle"] # the road's areas, west to east

func chain_pos() -> float:
	match here():
		"lake", "grotto", "corridor": return 0.0
		"village": return 0.5
		"forest": return 1.0
		"hill": return 2.0
		"castle": return 3.0
		"stairs": return 3.5
		"garden", "clock": return 4.0
	return -1.0

func token_target() -> Vector3:
	var cur := chain_pos()
	var best := -1
	var best_d := 99.0
	for i in [5, 4, 3, 2]: # ties go to the one further east
		if not m.tokens[i] and absf(TOKEN_CHAIN.find(TOKEN_AREA[i]) - cur) < best_d:
			best = i
			best_d = absf(TOKEN_CHAIN.find(TOKEN_AREA[i]) - cur)
	if best < 0:
		return Vector3.INF
	var goal := TOKEN_CHAIN.find(TOKEN_AREA[best])
	if absf(goal - cur) > 0.01:
		return token_exit(goal)
	match best:
		5:
			var unread: Array = []
			for bk in m.castle.books:
				if not bk.read:
					unread.append(bk.pos)
			return either(nearest(unread), Vector2.INF, 1.9)
		4: return hill_deed_target()
		3: return cage_target()
	return grotto_pearl() if here() == "grotto" else over(m.lake.marks.G, 2.6)

# the exit of this area toward the area at chain index `goal`
func token_exit(goal: int) -> Vector3:
	var east := goal > chain_pos()
	match here():
		"village": return over(m.village.marks.K if goal == 0 else m.village.marks.F)
		"lake": return over(m.lake.marks.S)
		"grotto": return over(m.grotto.marks.S)
		"forest": return over(m.forest.marks.E if east else m.forest.marks.S)
		"hill": return over(m.hill.marks.X if east else m.hill.marks.S)
		"castle": return over(m.castle.marks.E if east else m.castle.marks.S)
		"stairs": return over(m.stairs.marks.S)
	return Vector3.INF

func marsh_target(raw: String) -> Vector3:
	if raw.contains("오두막") and m.cottage_at.x >= 0.0:
		return over(m.cottage_at, 3.2)
	if raw.begins_with(Main.BORI_QUEST) or raw.contains("벽돌왕이"):
		return either(foe_at("boss"), Vector2.INF, 4.6)
	if raw.contains("노를 건져") and m.oar_node != null and m.oar_node.visible:
		return over(m.errands.OAR_AT, 1.6)
	if raw.begins_with("동쪽 강을"):
		return over(VILLAGE_WAY)
	for name in m.castle_zone.MARK_FOLK: # a line that sends her back to a villager (the letter delivered, the oar fetched): the village entrance first
		if raw.contains(name + "에게"):
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
	if raw.begins_with("나가기 전에") or raw.begins_with("동쪽 출구로"): # an old save's way-out line too
		if not m.saw_painting:
			return over(cm.P)
		if not m.woke[0]:
			return over(cm["1"], 1.8)
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
	if raw.begins_with("숲으로 가기 전에"): # the grotto's steps on the island for the pearl, then the lower pond's next step
		if not m.tokens[m.moon_tokens.PEARL]:
			return over(m.lake.marks.G, 2.6)
		return pond_target() if m.south_q < 4 else over(m.lake.marks.V, 2.6) # the water corridor's stair once the pond is done
	return Vector3.INF

# the lower pond: the weir, the two rope posts (Mulgyeol swims down their chains), the water clockwork's key
func pond_target() -> Vector3:
	match m.south_q:
		0: return over(m.lake.marks.Y, 2.2)
		1: return over(m.lake.ropes[0], 2.2)
		2:
			var me := Vector2(m.player.x, m.player.z)
			if m.south_ambush_on or m.lake_zone.in_south_yard(me): # shut in the yard: the fight, then the latch
				var spots: Array = []
				for e in m.enemies:
					if e.get("south_ambush", false) and not e.dead:
						spots.append(Vector2(e.x, e.z))
				return either(nearest(spots), m.lake.marks.l, 2.6)
			return over(m.lake.ropes[1], 2.2)
		3: return over(m.lake.marks.K, 2.2)
	return Vector3.INF

# in the grotto the pearl line leads to the crab, then its chest, then back out
func grotto_target(raw: String) -> Vector3:
	if not raw.begins_with("숲으로 가기 전에"):
		return over(m.grotto.marks.S) # any other line is for the island outside
	return grotto_pearl()

func grotto_pearl() -> Vector3:
	if m.grotto_q == 3:
		return over(m.grotto.marks.c, 1.6)
	if m.grotto_q >= 4:
		return over(m.grotto.marks.S)
	return either(foe_at("crab"), m.grotto.marks.C, 3.0)

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
	if led(raw, "언덕으로 가기 전에: 숲의 다람쥐 우리 다섯을 열자 %d/5"):
		return cage_target()
	if raw.begins_with("언덕으로 가기 전에: 숲 남쪽 골짜기"):
		return valley_target()
	return Vector3.INF

# the south valley's next step: the grey gate, the memory lamps, the empty cloak, the sunset door, Noeul's hollow
func valley_target() -> Vector3:
	var f = m.forest
	match m.hollow_q:
		0: return over(f.marks.G, 2.4)
		1:
			var dark: Array = f.mem_lamps.filter(func(l): return not l.lit).map(func(l): return l.pos)
			if not dark.is_empty():
				return over(nearest(dark), 2.2)
			return either(foe_at("cloak"), f.marks.C, 2.9)
		2:
			if not f.doors[1].open:
				return over(f.doors[1].pos, 2.2)
			return over(f.boxes[1].pos, 1.8)
	return Vector3.INF
func cage_target() -> Vector3: # the nearest cage still shut
	var shut: Array = []
	for i in Main.FOREST.CAGES.size():
		if not m.forest.freed[i]:
			shut.append(Main.FOREST.CAGES[i] + Vector2(Main.FOREST.FOREST_X, 0))
	return either(nearest(shut), Vector2.INF, 1.8)

func hill_target(raw: String) -> Vector3:
	if led(raw, "풍차를 팔찌로 감자 (E) %d/3"):
		var still: Array = []
		for mill in m.hill.mills:
			if not mill.turning:
				still.append(mill.pos)
		return either(nearest(still), Vector2.INF, 4.2)
	if raw.contains("벽돌 매를"):
		return either(foe_at("hawk"), m.hill.marks.B, 4.4)
	if raw.begins_with("성으로 가기 전에"):
		return hill_deed_target()
	if led(raw, "깃대에서 E: 바람 부르기 다시 (%d번째)") and m.hill.south_marks.has("P"):
		return over(m.hill.south_marks.P, 2.6)
	return Vector3.INF

# the sparrow mill's next step, or the moon trial's stone: whichever is nearer
func hill_deed_target() -> Vector3:
	var sm: Dictionary = m.hill.south_marks
	var mill: Vector2 = [sm.G, sm.Q, sm.P, sm.K, sm.c, sm.c][clampi(m.mill_q, 0, 5)]
	var spots: Array = []
	if m.mill_q < 5:
		spots.append(mill)
	if not m.trial_won: # the castle gate asks for both since v0.1.68
		spots.append(m.hill.marks.R)
	return over(nearest(spots), 2.4) if not spots.is_empty() else Vector3.INF

func castle_target(raw: String) -> Vector3:
	if raw.begins_with("옥좌의 방으로 가기 전에"): # the deep workshop's door in the great hall's corner
		return over(Main.WORK_DOOR, 2.0)
	if raw.begins_with("달의 계단을 오르기 전에"): # the quarters: the knight's spring, the clockwork door, then its own marks
		var at: Vector3 = m.castle_zone.quarters_target()
		if at != Vector3.INF:
			return at
		return over(m.castle.marks.K if m.quarters_q == 0 else m.castle.marks.Q, 1.9)
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
	if road_goal(raw) != "": # a line for the road above: back up the ladder
		return over(cm.U)
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
