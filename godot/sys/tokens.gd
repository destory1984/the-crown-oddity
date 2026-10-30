# Moonkeeper tokens (달지기 보석): six side deeds that open the way, counted per round (the owner, 2026-10-28: the story
# took 30 minutes, the aim is 3 hours; "side quests become gates on the main path, collecting tokens opens the way").
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
#
# v0.1.68 (the owner, 2026-10-29: "3 hours" - GPT's lap-3 estimate was 47 minutes): five gates also ask for a side activity that
# was optional before. The pearl also needs the lower pond's water clock before the forest; the squirrels also need the south
# valley before the hill; the castle needs BOTH the sparrow mill and the moon trial; the moon door to the knight needs the deep
# workshop's cradle; the moon stairs need the quarters' tin doorkeeper seen to his bunk. These deeds are not tokens: each is read
# from a progress flag that a new round already resets (south_q, hollow_q, mill_q, trial_won, work_q, quarters_q).
#
# A new round keeps the pearl, the ring and the bookmark (errands.NG_KEEP), so a token is NOT read from those flags: it is
# its own flag in m.tokens, saved with the game, and a new round starts with none. A save from before v0.1.62 has no
# "tokens" key: they are worked out once from the flags, as if earned.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const FLY := 0
const RING := 1
const PEARL := 2
const SQUIRRELS := 3
const HILL := 4
const LIBRARY := 5

const NAMES := ["반딧불 병", "울림 수정 반지", "물빛 진주", "다람쥐 다섯", "언덕의 바람", "서재의 달지기 책"]
const HOW := [
	"밤의 늪에서 반딧불 다섯을 병에 담아 콩알에게 주자",
	"동굴의 울림 수정을 낮은 소리부터 울려 상자를 열자",
	"섬 밑 물빛 동굴의 게를 물리치고 상자를 열자",
	"굳은 숲의 다람쥐 우리 다섯을 모두 열자",
	"참새 방앗간을 되살리거나 달빛 시련을 마치자",
	"성 서재의 달지기 책 다섯 권을 모두 읽자",
]
const STAIRS_NEED := 4 # the moon stairs' top door asks for this many of the six

# the quest lines that name a gate's need (the next-area line takes their place once the token is in)
const NEED_LEADS := ["숲으로 가기 전에", "언덕으로 가기 전에", "성으로 가기 전에", "정원 문 앞에", "옥좌의 방으로 가기 전에", "달의 계단을 오르기 전에"]

func _init(main: Main) -> void:
	m = main

func count() -> int:
	return m.tokens.count(true)

# an old save, or one from before the tokens: every deed already done counts, as if earned
func derive() -> Array:
	var books_all: bool = m.castle.books.all(func(b): return b.read)
	return [m.fly_q >= 3, m.has_ring, m.has_pearl, m.forest.freed.all(func(f): return f),
		m.mill_q >= 5 or m.trial_best > 0.0, m.has_bookmark or books_all]

func load_tokens(d: Dictionary) -> void:
	var t = d.get("tokens", null)
	if t is Array and t.size() == m.tokens.size():
		m.tokens = t.map(func(v): return bool(v))
	else:
		m.tokens = derive()
	# the crystal puzzle and its chest belong to this round's ring token, not to the kept ring (a new round plays it again)
	m.crystal_done = bool(d.get("crystal_done", false)) or (m.has_ring and m.tokens[RING])
	m.crystal_chest.visible = m.crystal_done and not m.tokens[RING]

# a deed is done: the gem lights, a toast and a burst, and a gate line that waited for it goes back to the road
func earn(i: int) -> void:
	if m.tokens[i]:
		return
	m.tokens[i] = true
	m.burst(Vector3(m.player.x, 1.6, m.player.z), Color("#ffd84a"), 30, 3.0)
	m.sfx(988, 0.3, "triangle", 0.22)
	m.toast(tr("달지기 보석을 얻었다 (%d/6)") % count())
	refresh_quest()
	m.save_game()

# the side activities the gates also ask for (v0.1.68), each worked out from a flag a new round resets
func pond_done() -> bool: # the lower pond: weir, chains, stones, grate, and the water clockwork wound
	return m.south_q >= 4

func valley_done() -> bool: # the south valley: three memory lamps, the empty cloak, Noeul's hollow opened
	return m.hollow_q >= 3

func mill_done() -> bool:
	return m.mill_q >= 5

func trial_done() -> bool: # cleared this round (the best time is kept across rounds, this flag is not)
	return m.trial_won

func corridor_done() -> bool: # the water corridor's answer lamps lit (v0.1.84, the owner's "1안"): the forest asks for it too
	return m.corridor_q >= 6

func observatory_done() -> bool: # the moon-watch observatory's answer lamps lit (v0.1.120, the same "1안"): the castle asks for it too
	return m.observatory_q >= 6

func workshop_done() -> bool: # the deep workshop's cradle let go
	return m.work_q >= 5

func quarters_done() -> bool: # the tin doorkeeper walked to his bunk and sat down
	return m.quarters_q >= 5

# does the way into this area still hold? Only for an area not yet entered: a save already past never gets locked again.
# "knight" is the moon door to the throne room (past it once it is open or the fight began); "stairs" is the castle's east gate.
func holds(area: String) -> bool:
	match area:
		"forest": return m.forest_q < 1 and not (m.tokens[PEARL] and pond_done() and corridor_done())
		"hill": return m.hill_q < 1 and not (m.tokens[SQUIRRELS] and valley_done())
		"castle": return m.castle_q < 1 and not (mill_done() and trial_done() and observatory_done())
		"knight": return m.castle_q < 2 and not m.castle.door_open and not workshop_done()
		"stairs": return m.castle_q >= 3 and m.garden_q == 0 and not m.stairs_seen and not quarters_done()
		"garden": return m.road_q == 0 and m.garden_q == 0 and count() < STAIRS_NEED
	return false

# which need the story and the line name for a gate: the first one still missing
func missing(area: String) -> String:
	match area:
		"forest": return "pearl" if not m.tokens[PEARL] else ("pond" if not pond_done() else "corridor")
		"hill": return "squirrels" if not m.tokens[SQUIRRELS] else "valley"
		"castle":
			if not mill_done() and not trial_done(): return "both"
			if not mill_done(): return "mill"
			if not trial_done(): return "trial"
			return "observatory"
	return area

# a gate: true lets her through. Held, it sets Sora back a step from the mark and opens the story box.
func gate(area: String, at: Vector2) -> bool:
	if not holds(area):
		return true
	if m.story_open:
		return false
	var me := Vector2(m.player.x, m.player.z)
	var away := (me - at).normalized() if me.distance_to(at) > 0.01 else Vector2(-1, 0)
	for back in [1.8, 1.4, 1.1]:
		var to: Vector2 = at + away * back
		if m.walkable(to.x, to.y):
			m.player.x = to.x
			m.player.z = to.y
			break
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.snap_mates()
	hold_note(area)
	return false

# the story box and the need line of a held gate (the moon door has no mark to be pushed back from: castle_zone calls this alone)
func hold_note(area: String) -> void:
	m.set_quest(need_line(area)) # the gold "!" and the minimap leave the shut gate for the deed that opens it
	var key := area + "_" + missing(area)
	m.show_story("", Main.STORY.GATE[key if Main.STORY.GATE.has(key) else area])

# ---- the quest line: what the road says next, with the need named while the way holds

func squirrels_freed() -> int:
	return m.forest.freed.count(true)

func lake_line() -> String:
	if holds("forest"):
		if missing("forest") == "pond":
			return "숲으로 가기 전에: 아랫못의 물시계를 되살리자"
		if missing("forest") == "corridor":
			return "숲으로 가기 전에: 물길 회랑에서 정원으로 물을 보내자"
		return "숲으로 가기 전에: 물빛 동굴의 게를 물리치고 진주를 얻자"
	return "물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"

# with_walls: the line right after Noeul turns also names a brick wall still shut (east_quest); the saved road line does not
func forest_line(with_walls := false) -> String:
	if holds("hill"):
		if missing("hill") == "valley":
			return "언덕으로 가기 전에: 숲 남쪽 골짜기의 기억을 되살리자"
		return tr("언덕으로 가기 전에: 숲의 다람쥐 우리 다섯을 열자 %d/5") % squirrels_freed()
	return m.forest_zone.east_quest() if with_walls else "숲 동쪽 끝 길로, 바람 언덕에 가자"

func hill_line() -> String:
	if holds("castle"):
		match missing("castle"):
			"mill": return "성으로 가기 전에: 참새 방앗간을 되살리자"
			"trial": return "성으로 가기 전에: 달빛 시련을 마치자"
			"observatory": return "성으로 가기 전에: 달맞이 관측원에서 바람 신호를 보내자"
		return "성으로 가기 전에: 참새 방앗간을 되살리고 달빛 시련을 마치자"
	return "언덕 동쪽 끝 길로, 달지기들의 성에 가자"

func stairs_line(otherwise: String) -> String:
	if holds("stairs"):
		return stairs_need_line()
	if holds("garden") and m.stairs.door_open:
		return garden_need_line()
	return otherwise

func knight_need_line() -> String:
	return "옥좌의 방으로 가기 전에: 작업장 깊은 곳의 수리 요람을 풀자"

func stairs_need_line() -> String:
	return "달의 계단을 오르기 전에: 숙소의 깡통 문지기를 침방까지 모시자"

func garden_need_line() -> String:
	return tr("정원 문 앞에서: 달지기 보석 %d/4를 밝히자 (일지 Q)") % mini(count(), STAIRS_NEED)

# the line that names what a held gate wants
func need_line(area: String) -> String:
	match area:
		"forest": return lake_line()
		"hill": return forest_line()
		"castle": return hill_line()
		"knight": return knight_need_line()
		"stairs": return stairs_need_line()
	return garden_need_line()

# a quest line that still points at a gate that holds (an old save, or one made before the tokens) is swapped for its need line
func mend_quest() -> void:
	var goal: String = m.quest_marks.road_goal(m.quest_raw)
	if goal == "garden" and holds("stairs") and not m.quest_raw.begins_with("꼭대기"):
		m.set_quest(need_line("stairs"))
	elif goal in ["forest", "hill", "castle", "garden"] and holds(goal):
		m.set_quest(need_line(goal))
	elif holds("knight") and m.castle.pages_read() == 3 and (m.quest_raw.begins_with("옥좌의 방") or m.quest_raw.begins_with("성 안에 흩어진")):
		m.set_quest(knight_need_line())

# the tokens' count on the stairs line moves with each new token, and a need line that no longer holds goes back to the road
func refresh_quest() -> void:
	var q: String = m.quest_raw
	for lead in NEED_LEADS:
		if q.begins_with(lead) or q.begins_with(tr(lead)):
			m.set_quest(forest_line(true) if lead == NEED_LEADS[1] else m.main_road_quest())
			return

# ---- the journal: what each gate still ahead asks for, under the tokens
func gate_lines() -> Array:
	var rows := [
		["forest", m.lake_q >= 4, "숲으로 가는 문", [["물빛 진주", m.tokens[PEARL]], ["아랫못의 물시계", pond_done()], ["물길 회랑", corridor_done()]]],
		["hill", m.forest_q >= 3, "언덕으로 가는 문", [["다람쥐 다섯", m.tokens[SQUIRRELS]], ["남쪽 골짜기의 기억", valley_done()]]],
		["castle", m.hill_q >= 3, "성으로 가는 문", [["참새 방앗간", mill_done()], ["달빛 시련", trial_done()], ["달맞이 관측원", observatory_done()]]],
		["knight", m.castle_q >= 1, "옥좌의 방 달의 문", [["작업장의 수리 요람", workshop_done()]]],
		["stairs", m.castle_q >= 3, "달의 계단", [["숙소의 깡통 문지기", quarters_done()]]],
	]
	var out: Array = []
	for r in rows:
		if not r[1] or not holds(r[0]):
			continue
		var parts: Array = []
		for need in r[3]:
			parts.append(tr(need[0]) + " " + (tr("끝") if need[1] else tr("아직")))
		out.append("  · " + tr(r[2]) + "  —  " + "  ·  ".join(PackedStringArray(parts)))
	return out

# ---- the journal and the HUD

func journal_lines() -> Array:
	var out: Array = [tr("달지기 보석 %d/6") % count()]
	for i in NAMES.size():
		out.append("  · " + tr(NAMES[i]) + "  —  " + (tr("끝") if m.tokens[i] else tr(HOW[i])))
	var gates := gate_lines()
	if not gates.is_empty():
		out.append(tr("길목에 필요한 일"))
		out.append_array(gates)
	return out
