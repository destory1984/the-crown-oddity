# Moonkeeper tokens (달지기 표식): six side deeds that open the way, counted per round (the owner, 2026-10-28: the story
# took 30 minutes, the aim is 3 hours; "side quests become gates on the main path, collecting tokens opens the way").
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
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
const NEED_LEADS := ["숲으로 가기 전에", "언덕으로 가기 전에", "성으로 가기 전에", "정원 문 앞에"]

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
	m.toast(tr("달지기 표식을 얻었다 (%d/6)") % count())
	refresh_quest()
	m.save_game()

# does the way into this area still hold? Only for an area not yet entered: a save already past never gets locked again.
func holds(area: String) -> bool:
	match area:
		"forest": return m.forest_q < 1 and not m.tokens[PEARL]
		"hill": return m.hill_q < 1 and not m.tokens[SQUIRRELS]
		"castle": return m.castle_q < 1 and not m.tokens[HILL]
		"garden": return m.road_q == 0 and m.garden_q == 0 and count() < STAIRS_NEED
	return false

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
	m.set_quest(need_line(area)) # the gold "!" and the minimap leave the shut gate for the deed that opens it
	m.show_story("", Main.STORY.GATE[area])
	return false

# ---- the quest line: what the road says next, with the need named while the way holds

func squirrels_freed() -> int:
	return m.forest.freed.count(true)

func lake_line() -> String:
	if holds("forest"):
		return "숲으로 가기 전에: 물빛 동굴의 게를 물리치고 진주를 얻자"
	return "물결과 함께 마을 동쪽 문으로, 굳은 숲에 가자"

# with_walls: the line right after Noeul turns also names a brick wall still shut (east_quest); the saved road line does not
func forest_line(with_walls := false) -> String:
	if holds("hill"):
		return tr("언덕으로 가기 전에: 숲의 다람쥐 우리 다섯을 열자 %d/5") % squirrels_freed()
	return m.forest_zone.east_quest() if with_walls else "숲 동쪽 끝 길로, 바람 언덕에 가자"

func hill_line() -> String:
	if holds("castle"):
		return "성으로 가기 전에: 참새 방앗간을 되살리거나 달빛 시련을 마치자"
	return "언덕 동쪽 끝 길로, 달지기들의 성에 가자"

func stairs_line(otherwise: String) -> String:
	if holds("garden") and m.stairs.door_open:
		return garden_need_line()
	return otherwise

func garden_need_line() -> String:
	return tr("정원 문 앞에서: 달지기 표식 %d/4를 밝히자 (일지 Q)") % mini(count(), STAIRS_NEED)

# the line that names what a held gate wants
func need_line(area: String) -> String:
	match area:
		"forest": return lake_line()
		"hill": return forest_line()
		"castle": return hill_line()
	return garden_need_line()

# a quest line that still points at a gate that holds (an old save, or one made before the tokens) is swapped for its need line
func mend_quest() -> void:
	var goal: String = m.quest_marks.road_goal(m.quest_raw)
	if goal in ["forest", "hill", "castle", "garden"] and holds(goal):
		m.set_quest(need_line(goal))

# the tokens' count on the stairs line moves with each new token, and a need line that no longer holds goes back to the road
func refresh_quest() -> void:
	var q: String = m.quest_raw
	for lead in NEED_LEADS:
		if q.begins_with(lead) or q.begins_with(tr(lead)):
			m.set_quest(forest_line(true) if lead == NEED_LEADS[1] else m.main_road_quest())
			return

# ---- the journal and the HUD

func journal_lines() -> Array:
	var out: Array = [tr("달지기 표식 %d/6") % count()]
	for i in NAMES.size():
		out.append("  · " + tr(NAMES[i]) + "  —  " + (tr("끝") if m.tokens[i] else tr(HOW[i])))
	return out
