# Market: honesty-box stalls, target yard, inn, bottles, the magpie thief.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const STALLS := {
	"1": {"price": 5, "what": "사과"},          # heals 40
	"2": {"price": 40, "what": "달빛 가루"},    # two crown pips
	"3": {"price": 15, "what": "따뜻한 차"},    # stamina full, momentum +50
}
const TARGET_TIME := 20.0
const TARGET_GOAL := 6
const STALL_DOES := {"1": "체력 40", "2": "팔찌 눈금 2칸", "3": "기력 가득, 기세 +50"}

func _init(main: Main) -> void:
	m = main

func market_key() -> bool:
	var me := Vector2(m.player.x, m.player.z)
	for key in STALLS:
		var at: Vector2 = m.village.marks[key]
		if me.distance_to(at) < 1.3:
			buy_stall(key)
			return true
	if me.distance_to(m.village.marks.Q) < 1.6:
		if not m.target_on:
			start_targets()
		return true
	if me.distance_to(m.village.marks.N) < 1.4:
		stay_inn()
		return true
	return false

func buy_stall(key: String) -> void:
	if m.magpie_q == 0:
		m.magpie_q = 1
		m.show_story("", cast_lines(Main.STORY.MARKET_NOTE))
		m.save_game()
		return
	var st: Dictionary = STALLS[key]
	var price: int = st.price
	if key == "2" and m.magpie_q >= 3:
		price = 25 # the magpie's thanks: moon dust for less
	if m.player.gold < price:
		m.toast(tr("%s: 금화 %d. 금화가 모자라다") % [tr(st.what), price])
		return
	match key:
		"1":
			if m.player.hp >= m.player.max_hp:
				m.toast("배가 부르다. 사과는 다치면 먹자")
				return
			m.player.hp = minf(m.player.max_hp, m.player.hp + 40.0)
			m.pop_num(Vector3(m.player.x, 1.8, m.player.z), "+40", Color("#7aff9a"))
		"2":
			if m.crown_pips >= m.pip_max:
				m.toast("팔찌 달빛이 이미 가득하다")
				return
			m.crown_pips = mini(m.pip_max, m.crown_pips + 2)
			m.pip_flash = 0.3
		"3":
			m.player.sp = 100.0
			m.player.mp = minf(m.player.max_mp, m.player.mp + 50.0)
	m.player.gold -= price
	m.sfx(880, 0.08, "triangle", 0.18)
	m.burst(Vector3(m.village.marks[key].x, 1.0, m.village.marks[key].y - 0.8), Color("#e8c050"), 10, 1.5)
	m.toast(tr("상자에 금화 %d을(를) 넣고 %s을(를) 집었다") % [price, tr(st.what)])
	m.save_game()

# the target yard: for 20 s a brick target stands up somewhere in the yard every 1.6 s and falls back after 2.4 s;
# one sword hit knocks it down. Six or more wins: the first time the target medal, later 20 gold
func start_targets() -> void:
	m.target_on = true
	m.target_left = TARGET_TIME
	m.target_hits = 0
	m.target_next = 0.6
	m.sfx(660, 0.2, "triangle", 0.2)
	m.toast(tr("과녁 맞히기! %d초 동안 일어서는 과녁을 베자") % int(TARGET_TIME))

func market_hint() -> void:
	var me := Vector2(m.player.x, m.player.z)
	var near := ""
	for key in STALLS:
		if me.distance_to(m.village.marks[key]) < 1.3:
			near = key
	if near == "" and me.distance_to(m.village.marks.N) < 1.4:
		near = "inn"
	if near == m.stall_seen:
		return
	m.stall_seen = near
	if near == "inn":
		m.toast("여관: 하룻밤 금화 10, 모두 회복 (E)")
	elif near != "":
		var price: int = 25 if near == "2" and m.magpie_q >= 3 else int(STALLS[near].price)
		m.toast(tr("%s(%s): 금화 %d을(를) 정직 상자에 넣고 가져간다 (E)") % [tr(STALLS[near].what), tr(STALL_DOES[near]), price])

# rain at the market (delight ideas 26, 37). All of it is decoration: no collision, and the stalls' buying does not look at it.
# 26: each stall keeps a spare crate just outside its awning; in rain, while Sora stands under the awning, the seller
#     pulls it in a hand's width, and it goes back out when she leaves or the rain stops.
# 37: a blank paper tag hangs from the moon-dust stall's post; in rain it curls in towards the post, and unfurls when the rain stops.
const CRATE_OUT := 0.8 # the crate's local z at rest and pulled in, on its stall's frame (the stall sits at its mark + (0.5, -1.0))
const CRATE_IN := 0.45
var crates: Array = [] # [{"node": MeshInstance3D, "key": "1", "in": false, "tween": Tween}]
var crate_pulls := 0 # pulls started (autoplay d26_shelter)
var tag: Node3D # the paper tag's pivot, hinged at its top edge
var tag_curled := false
var tag_curls := 0 # curls and unfurls started (autoplay d37_tag)

func build_rain_decor() -> void:
	var wood := m.mat_color(Color("#8a6a42"))
	for key in STALLS:
		var at: Vector2 = m.village.marks[key]
		var crate: MeshInstance3D = m.box(Vector3(0.34, 0.26, 0.28), wood)
		crate.position = Vector3(at.x + 0.5 + 1.15, 0.13, at.y - 1.0 + CRATE_OUT)
		m.add_child(crate)
		crates.append({"node": crate, "key": key, "in": false, "tween": null})
	var p: Vector2 = m.village.marks["2"]
	tag = Node3D.new()
	tag.position = Vector3(p.x + 0.5 - 0.85, 1.35, p.y - 1.0 + 0.38)
	m.add_child(tag)
	var paper: MeshInstance3D = m.box(Vector3(0.22, 0.3, 0.012), m.mat_color(Color("#f4ecd6")))
	paper.position = Vector3(0, -0.15, 0)
	tag.add_child(paper)

func update_rain_decor() -> void:
	var me := Vector2(m.player.x, m.player.z)
	for c in crates:
		var under: bool = m.raining and not m.story_open and me.distance_to(m.village.marks[c.key]) < 1.6
		if under == c["in"]:
			continue
		c["in"] = under
		if c.tween != null:
			c.tween.kill()
		if under:
			crate_pulls += 1
		var at: Vector2 = m.village.marks[c.key]
		var tw := m.create_tween()
		c.tween = tw
		tw.tween_property(c.node, "position:z", at.y - 1.0 + (CRATE_IN if under else CRATE_OUT), 0.6).set_trans(Tween.TRANS_SINE)
	if tag != null and m.raining != tag_curled:
		tag_curled = m.raining
		tag_curls += 1
		var tw2 := m.create_tween().set_parallel(true)
		tw2.tween_property(tag, "rotation:x", 0.7 if tag_curled else 0.0, 0.9).set_trans(Tween.TRANS_SINE)
		tw2.tween_property(tag, "scale:y", 0.6 if tag_curled else 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func update_market(dt: float) -> void:
	market_hint()
	update_rain_decor()
	for b in m.village.bottles: # the bottles bob on the pond; she picks one up running over it on the water skip
		if b.got:
			continue
		b.node.position.y = -0.3 + sin(m.t * 2.0 + b.pos.x) * 0.05
		if Vector2(m.player.x, m.player.z).distance_to(b.pos) < 0.9:
			pick_bottle(b)
	if not m.target_on:
		return
	m.target_left -= dt
	m.target_next -= dt
	for e in m.enemies:
		if e.has("practice") and not e.dead:
			e.life -= dt
			if e.life <= 0.0:
				e.dead = true
				e.node.queue_free()
				e.shadow.queue_free()
	if m.target_next <= 0.0 and m.target_left > 1.0:
		m.target_next = 1.6
		spawn_target()
	if m.target_left <= 0.0 or Vector2(m.player.x, m.player.z).distance_to(m.village.marks.Q) > 9.0:
		end_targets()

func spawn_target() -> void:
	var q: Vector2 = m.village.marks.Q
	var at := q + Vector2(m.rnd(-3.0, 3.5), m.rnd(-2.0, 2.0))
	for tries in 10:
		if m.walkable(at.x, at.y) and at.distance_to(Vector2(m.player.x, m.player.z)) > 1.2 and at.distance_to(q) > 0.8:
			break
		at = q + Vector2(m.rnd(-3.0, 3.5), m.rnd(-2.0, 2.0))
	var root := Node3D.new()
	var mats: Array = []
	m.brick(root, mats, Vector3(0.5, 0.7, 0.2), Vector3(0, 0.35, 0), Color("#f2ead8"))
	m.brick(root, mats, Vector3(0.32, 0.32, 0.22), Vector3(0, 0.5, 0), Color("#c8322a"), false)
	m.add_child(root)
	root.position = Vector3(at.x, 0, at.y)
	root.scale = Vector3.ONE * 0.2
	root.create_tween().tween_property(root, "scale", Vector3.ONE, 0.15)
	m.enemies.append({"x": at.x, "z": at.y, "hp": 1.0, "max_hp": 1, "node": root, "shadow": m.blob(0.4), "t": 0.0,
		"atk_cd": 99.0, "hurt": 0.0, "kx": 0.0, "kz": 0.0, "wx": at.x, "wz": at.y, "dead": false, "respawn": 9999.0,
		"practice": true, "life": 2.4, "cave": true, "prop": true})
	root.set_meta("mats", mats)
	root.set_meta("body", root)

func target_hit(e: Dictionary) -> void:
	e.dead = true
	e.node.queue_free()
	e.shadow.queue_free()
	m.target_hits += 1
	m.burst(Vector3(e.x, 0.6, e.z), Color("#c8322a"), 14, 2.5)
	m.sfx(700 + m.target_hits * 40, 0.08, "triangle", 0.2)
	m.pop_num(Vector3(e.x, 1.2, e.z), str(m.target_hits), Color("#ffd84a"))

func end_targets() -> void:
	m.target_on = false
	for e in m.enemies:
		if e.has("practice") and not e.dead:
			e.dead = true
			e.node.queue_free()
			e.shadow.queue_free()
	m.target_best = maxi(m.target_best, m.target_hits)
	if m.target_hits >= TARGET_GOAL and not m.has_medal:
		m.has_medal = true
		m.show_story("", Main.STORY.TARGET_MEDAL)
	elif m.target_hits >= TARGET_GOAL:
		m.player.gold += 20
		m.toast(tr("과녁 %d개! 금화 +20") % m.target_hits)
	else:
		m.toast(tr("과녁 %d개. %d개를 맞히면 상이 있다") % [m.target_hits, TARGET_GOAL])
	m.save_game()

func crit_mult() -> float:
	return 2.0 if m.has_medal else 1.8

# the inn: 10 gold for a night. Everyone is healed, and she wakes at 7 the next morning (the first night, a short talk)
func stay_inn() -> void:
	if m.player.gold < 10:
		m.toast("하룻밤에 금화 10. 금화가 모자라다")
		return
	m.player.gold -= 10
	m.inn_nights += 1
	m.fade_then(func():
		m.player.hp = float(m.player.max_hp)
		m.player.sp = 100.0
		for id in ["mulgyeol", "noeul"]:
			m.mate_hp[id] = m.mate_max()
			m.mate_down[id] = 0.0
		if m.hour >= 7.0:
			m.day += 1
		m.hour = 7.0
		m.player.x = m.village.marks.N.x
		m.player.z = m.village.marks.N.y + 0.8
		m.snap_mates()
		m.save_game())
	if m.inn_nights == 1:
		m.get_tree().create_timer(0.9).timeout.connect(func(): m.show_story("", inn_first_lines()))
	else:
		m.toast("푹 자고 일어났다. 아침 7시")

# side-story lines in the village can come before Mulgyeol or Noeul has joined: their lines go (GPT playtests 2 -> 9)
func cast_lines(lines: Array) -> Array:
	return lines.filter(func(l): return not ((String(l).begins_with("노을|") and m.mate2 == null) or (String(l).begins_with("물결|") and m.mate == null)))

func swap_line(lines: Array, from: String, to: String) -> Array: # the line spoken by `from` becomes `to`
	var out: Array = lines.duplicate()
	for i in out.size():
		if String(out[i]).begins_with(from + "|"):
			out[i] = to
			break
	return out

func inn_first_lines() -> Array:
	var lines: Array = Main.STORY.INN_FIRST
	if m.mate == null and m.mate2 == null:
		lines = swap_line(lines, "소라", Main.STORY.INN_FIRST_ALONE)
		lines[lines.size() - 1] = Main.STORY.INN_FIRST_MORNING_ALONE
	elif m.mate2 == null:
		lines = swap_line(lines, "소라", Main.STORY.INN_FIRST_MUL)
	return cast_lines(lines)

func bottle_lines(i: int) -> Array:
	var lines: Array = Main.STORY.BOTTLES[i]
	if m.mate == null:
		lines = swap_line(lines, "물결", Main.STORY.BOTTLE_DORAN_ALONE)
	return cast_lines(lines)

func magpie_nest_lines() -> Array:
	var lines: Array = Main.STORY.MAGPIE_NEST
	if m.mate2 == null:
		lines = swap_line(lines, "노을", Main.STORY.MAGPIE_NEST_SIGN)
	return cast_lines(lines)

func magpie_done_lines() -> Array:
	var lines: Array = Main.STORY.MAGPIE_DONE
	if m.mate2 == null:
		lines = swap_line(lines, "노을", Main.STORY.MAGPIE_DONE_PRICE)
	return cast_lines(lines)

func pick_bottle(b: Dictionary) -> void:
	b.got = true
	b.node.visible = false
	var i: int = m.village.bottles.find(b)
	m.burst(Vector3(b.pos.x, 0.3, b.pos.y), Color("#bfe6c8"), 16, 2.0)
	m.sfx(880, 0.12, "triangle", 0.2)
	m.show_story("", bottle_lines(i))
	if m.village.bottles_got() == m.village.bottles.size():
		m.player.gold += 120
		m.player.max_hp += 10
		m.player.hp = float(m.player.max_hp)
		m.get_tree().create_timer(0.2).timeout.connect(func(): m.toast("유리병 편지 셋을 다 찾았다. 금화 +120, 최대 체력 +10"))
	m.save_game()

func magpie_perches() -> Array:
	var vx := float(Main.VILLAGE.VILLAGE_X)
	# [x, z, height]: the moon-dust stall's awning, the inn roof, the moon lantern at the pier's end, the nest on the pond
	return [Vector3(vx + 38.5, 2.0, 1.75), Vector3(vx + 5.0, 23.6, 3.2), Vector3(vx + 36.0, 28.2, 2.1), Vector3(vx + 41.0, 31.0, 0.15)]

func build_magpie() -> void:
	m.magpie = Node3D.new()
	var body := Node3D.new()
	m.magpie.add_child(body)
	var black := m.mat_color(Color("#1e2230"))
	var white := m.mat_color(Color("#eef3ff"))
	var blue := m.mat_color(Color("#3a6ac8"))
	for part in [[Vector3(0.34, 0.22, 0.2), Vector3(0, 0.2, 0), black], [Vector3(0.2, 0.14, 0.21), Vector3(0.02, 0.15, 0), white],
			[Vector3(0.16, 0.16, 0.16), Vector3(0.2, 0.32, 0), black], [Vector3(0.08, 0.04, 0.04), Vector3(0.31, 0.31, 0), m.mat_color(Color("#d9b04a"))],
			[Vector3(0.3, 0.06, 0.08), Vector3(-0.28, 0.26, 0), blue], [Vector3(0.22, 0.05, 0.24), Vector3(-0.04, 0.27, 0), blue]]:
		var b := m.box(part[0], part[2])
		b.position = part[1]
		body.add_child(b)
	m.magpie.set_meta("body", body)
	m.add_child(m.magpie)
	# the nest out on the pond: a ring of twigs with coins glinting in it
	var nest := Node3D.new()
	var twig := m.mat_color(Color("#6a4a2a"))
	for k in 6:
		var tw := m.box(Vector3(0.5, 0.1, 0.12), twig)
		tw.rotation.y = k * PI / 3.0
		tw.position = Vector3(cos(k * PI / 3.0) * 0.22, 0.0, sin(k * PI / 3.0) * 0.22)
		nest.add_child(tw)
	for k in 5:
		var coin := m.box(Vector3(0.1, 0.03, 0.1), m.glow_mat(Color("#ffd84a"), 1.2))
		coin.position = Vector3(m.rnd(-0.12, 0.12), 0.07 + k * 0.02, m.rnd(-0.12, 0.12))
		nest.add_child(coin)
	var np: Vector3 = magpie_perches()[3]
	nest.position = Vector3(np.x, -0.05, np.y)
	m.add_child(nest)
	# the old moon lantern at the end of the pier: a tall post, dark until the crown lights it
	m.moon_lamp_node = Node3D.new()
	var post := m.box(Vector3(0.16, 1.9, 0.16), m.mat_color(Color("#3b2a1e")))
	post.position = Vector3(0, 0.95, 0)
	m.moon_lamp_node.add_child(post)
	var glass := m.box(Vector3(0.36, 0.36, 0.36), m.mat_color(Color("#3a3428")))
	glass.position = Vector3(0, 1.95, 0)
	glass.name = "glass"
	m.moon_lamp_node.add_child(glass)
	var lp: Vector3 = magpie_perches()[2]
	m.moon_lamp_node.position = Vector3(lp.x, 0.1, lp.y)
	m.add_child(m.moon_lamp_node)
	m.magpie.visible = false

func light_moon_lamp() -> void:
	if m.magpie == null:
		return
	var glass: MeshInstance3D = m.moon_lamp_node.get_node("glass")
	glass.material_override = m.glow_mat(Color("#dfe8ff"), 3.0)
	if not m.moon_lamp_node.has_node("light"):
		var l := OmniLight3D.new()
		l.name = "light"
		l.light_color = Color("#cfe0ff")
		l.light_energy = 2.0
		l.omni_range = 6.0
		l.position = Vector3(0, 2.0, 0)
		m.moon_lamp_node.add_child(l)
	m.magpie_at = 2
	place_magpie()

func place_magpie() -> void:
	var p: Vector3 = magpie_perches()[m.magpie_at]
	m.magpie.position = Vector3(p.x, p.z, p.y)

func update_magpie(dt: float) -> void:
	if m.magpie == null:
		return
	var showing := m.magpie_q >= 3 or (m.magpie_q == 1 and m.is_night()) or m.magpie_q == 2
	m.magpie.visible = showing
	if not showing:
		if m.magpie_q == 1 and m.magpie_at != 0 and not m.magpie_flying: # the night ended mid-chase: back on the stall tomorrow
			m.magpie_at = 0
			place_magpie()
		return
	var body: Node3D = m.magpie.get_meta("body")
	body.position.y = sin(m.t * 3.0) * 0.03
	body.rotation.y = PI if m.player.x < m.magpie.position.x else 0.0
	if m.magpie_q != 1 or m.magpie_flying:
		return
	var me := Vector2(m.player.x, m.player.z)
	var here := Vector2(m.magpie.position.x, m.magpie.position.z)
	if m.magpie_at < 3 and me.distance_to(here) < 3.2:
		fly_magpie(m.magpie_at + 1)
	elif m.magpie_at == 3 and me.distance_to(here) < 1.4:
		m.magpie_q = 2
		m.show_story("", magpie_nest_lines())
		m.save_game()

func fly_magpie(to: int) -> void:
	m.magpie_flying = true
	var p: Vector3 = magpie_perches()[to]
	var goal := Vector3(p.x, p.z, p.y)
	var mid := (m.magpie.position + goal) / 2.0 + Vector3(0, 2.5, 0)
	m.sfx(1200, 0.12, "triangle", 0.12, 400)
	var tw := m.create_tween()
	tw.tween_property(m.magpie, "position", mid, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(m.magpie, "position", goal, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		m.magpie_at = to
		m.magpie_flying = false
		if to == 1:
			m.toast("까치가 여관 지붕으로 날아갔다")
		elif to == 2:
			m.toast("까치가 부두 끝 낡은 등불 위에 앉았다")
		elif to == 3:
			m.toast("까치가 연못 한가운데로 날아갔다. 물수제비 걸음으로 따라가자"))

func magpie_key() -> bool:
	if m.magpie_q != 2:
		return false
	var lp: Vector3 = magpie_perches()[2]
	if Vector2(m.player.x, m.player.z).distance_to(Vector2(lp.x, lp.y)) > 1.8:
		return false
	if not m.spend_pips(2):
		return true
	m.magpie_q = 3
	light_moon_lamp()
	m.burst(Vector3(lp.x, 2.0, lp.y), Color("#dfe8ff"), 30, 3.0)
	m.sfx(523, 0.5, "sine", 0.25, 300)
	m.player.gold += 100
	m.player.max_hp += 10
	m.player.hp = float(m.player.max_hp)
	m.show_story("", magpie_done_lines())
	m.save_game()
	return true
