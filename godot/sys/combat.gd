# Combat: damage, xp, attacks, dash/charged slashes, skills, potions, dodge.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const LV_MOVES := {
	2: "새 기술: 4타 연속기 (J를 네 번, 넷째 타는 한 바퀴 베기)",
	3: "새 기술: 달려 베기 (Shift로 달리며 J)",
	4: "새 기술: 모아 베기 (L로 막으며 1초 모은 뒤 J)",
	6: "새 기술: 5타 마무리 (다섯째 타는 땅 내려찍기)",
	8: "새 기술: 빛 칼날 (연속기 마지막 타가 빛 칼날을 날린다)",
	10: "가벼운 발: 구르기 기력 25 → 18, 섬광 피하기 틈 0.15 → 0.2초",
	15: "달빛 숨: 기술을 다시 쓰기까지 20% 빨라진다",
	20: "세 갈래 빛 칼날: 마지막 타의 빛 칼날이 셋으로 갈라진다",
	25: "든든한 약: 회복약이 30% 더 채운다",
	30: "꺼지지 않는 기세: 때리지 않아도 기세가 줄지 않는다",
}
# short names for the journal's "익힌 기술" list
const LV_NAMES := {2: "4타 연속기", 3: "달려 베기", 4: "모아 베기", 6: "5타 마무리", 8: "빛 칼날",
	10: "가벼운 발", 15: "달빛 숨", 20: "세 갈래 빛 칼날", 25: "든든한 약", 30: "꺼지지 않는 기세"}
const SKILL_MP := [30, 15, 60]

func _init(main: Main) -> void:
	m = main

# ---------------------------------------------------------------- combat
func damage_enemy(e: Dictionary, amt: float, from: Vector2, kb := 4.0, force_crit := false, stop := 0.05) -> void:
	if e.get("locked", false) or e.get("air", false):
		return # the mold at its last sliver only breaks to the wind; the hawk is out of reach in the air
	if e.get("curl", 0.0) > 0.0: # a curled brick hedgehog: every side is spikes
		m.pop_num(Vector3(e.x, 1.2, e.z), "막음", Color("#c8c8d0"))
		m.burst(Vector3(e.x, 0.5, e.z), Color("#8a8a90"), 6, 2.0)
		m.sound.brick_clack(e)
		return
	if e.get("dizzy", 0.0) > 0.0:
		amt *= 1.3
	if e.get("seam", 0.0) > 0.0 and not e.get("boss", false):
		amt *= 1.5
		e.pins = int(e.get("pins", 3)) - 1
		m.burst(Vector3(e.x, 0.9, e.z), Color("#ffd84a"), 5, 2.4)
		m.sfx(1300, 0.04, "square", 0.14, 200)
		if e.pins <= 0: # the last pin: it comes loose
			e.pins = 3
			e.seam = 0.0
			e.stun = 1.6
			e.dizzy = 1.6
			m.pop_num(Vector3(e.x, 1.7, e.z), "풀림!", Color("#ffd84a"))
			m.player.mp = minf(m.player.max_mp, m.player.mp + 10.0)
			m.shake = maxf(m.shake, 0.12)
	if e.get("shield", 0) > 0 and e.get("wind", 0.0) <= 0.0:
		e.shield -= 1
		m.pop_num(Vector3(e.x, 1.4, e.z), "막음", Color("#c8c8d0"))
		m.burst(Vector3(e.x, 0.6, e.z), Color("#c8962a"), 8, 2.0)
		m.sound.brick_clack(e)
		if e.shield <= 0:
			e.shield_node.queue_free()
			m.toast("방패가 깨졌다")
		return
	if e.dead or e.get("roar", 0.0) > 0.0:
		return
	if m.sealed_between(from, Vector2(e.x, e.z)):
		m.pop_num(Vector3(e.x, 1.6, e.z), "닫힌 벽", Color("#c8c8d0"))
		m.sfx(700, 0.06, "square", 0.15, -300)
		return
	if e.get("mole", false) and m.cave.mole_shut_out():
		m.pop_num(Vector3(e.x, 1.6, e.z), "닫힌 문", Color("#c8c8d0"))
		m.sfx(700, 0.06, "square", 0.15, -300)
		return
	if e.has("cage"):
		m.forest_zone.cage_hit(e)
		return
	if e.has("practice"):
		m.market.target_hit(e)
		return
	if e.get("knight", false) and e.stun <= 0.0 and e.tired <= 0.0 and e.dash <= 0.0:
		var from_dir := (from - Vector2(e.x, e.z)).normalized()
		if from_dir.dot(e.face) > 0.34: # within about 70 degrees either side of where the shield points
			m.pop_num(Vector3(e.x, 2.2, e.z), "막음", Color("#c8c8d0"))
			m.burst(Vector3(e.x + e.face.x * 0.6, 1.2, e.z + e.face.y * 0.6), Color("#c8962a"), 6, 2.0)
			m.sound.brick_clack(e)
			return
	var crit := force_crit or m.rng.randf() < (0.25 if m.has_ring else 0.15)
	if crit:
		m.stats.crits += 1
	if (e.get("boss", false) or e.get("mole", false)) and e.get("stun", 0.0) > 0.0:
		amt *= 1.5
	if e.get("gatekeeper", false) and e.expo <= 0.0:
		amt *= 0.5 # the sluice-keeper takes full blows only while its axis lies open (v0.1.84)
	var dmg := int(round(amt / m.ng_mult() * m.rnd(0.85, 1.15) * (1.0 if force_crit else (m.market.crit_mult() if crit else 1.0))))
	m.hitstop = maxf(m.hitstop, 0.09 if crit and stop < 0.09 else stop)
	if e.get("wind", 0.0) > 0.0 and not e.get("boss", false):
		e.wind = 0.0 # a hit interrupts a goblin's wind-up
		e.atk_cd = 1.6
	e.hp -= dmg
	if e.get("mold", false) and m.garden_q == 2:
		e.hp = maxf(e.hp, 1.0) # a big blow cannot skip the lock at 12% (the mold died like a goblin and the ending never came)
	e.hurt = 0.12
	var d := Vector2(e.x - from.x, e.z - from.y)
	if d.length() < 0.01:
		d = Vector2(0, 1)
	d = d.normalized() * (kb * 0.15 if e.get("boss", false) else kb)
	e.kx = d.x
	e.kz = d.y
	var y := m.height_at(e.x, e.z)
	m.pop_num(Vector3(e.x, y + 1.2, e.z), str(dmg) + ("!" if crit else ""))
	m.burst(Vector3(e.x, y + 0.5, e.z), Color("#ffd28a"), 8, 2.0)
	m.shake = maxf(m.shake, 0.18 if crit else 0.08)
	m.sfx(520.0 if crit else 300.0, 0.08, "square", 0.2, -200.0)
	if e.hp <= 0:
		e.dead = true
		e.respawn = 8.0
		m.stats.kills += 1
		e.node.queue_free()
		e.shadow.queue_free()
		m.burst(Vector3(e.x, y + 0.4, e.z), Color("#ff9a4a"), 26, 3.5)
		if e.get("cloak", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.forest_zone.cloak_beaten)
		elif e.get("noeul", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.forest_zone.noeul_turned if e.get("second", false) else m.village_life.noeul_beaten)
		elif e.get("turtle", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.turtle_beaten)
		elif e.get("crab", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.lake_zone.crab_beaten)
		elif e.get("scare", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.hill_zone.scarecrow_beaten)
		elif e.get("mill_guard", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.hill_zone.mill_guard_beaten)
		elif e.get("echo", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.garden_zone.echo_beaten)
		elif e.get("knight", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.knight_beaten)
		elif e.get("hawk", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.hill_zone.hawk_beaten)
		elif e.get("gatekeeper", false):
			m.get_tree().create_timer(1.0).timeout.connect(m.corridor_zone.boss_beaten)
		elif e.get("corr_prep", false):
			pass # the wheel hall's groups pay once when the whole group is down (corridor_zone.finish_group)
		elif e.get("mole", false):
			m.player.gold += 150
			gain_xp(120)
			m.get_tree().create_timer(1.2).timeout.connect(m.mole_defeated)
		elif e.get("boss", false):
			m.player.gold += 300
			m.toast("벽돌왕을 쓰러뜨렸다! 금화 +300")
			m.get_tree().create_timer(1.5).timeout.connect(m.open_cave.bind(Vector2(e.x, e.z)))
			m.ui.boss.visible = false
			m.shake = 0.6
			for k in 4:
				m.burst(Vector3(e.x + m.rnd(-1, 1), y + m.rnd(0.5, 2.5), e.z + m.rnd(-1, 1)), Color("#e8b018"), 30, 5.0)
			gain_xp(200)
		elif e.get("trial", false) and m.trial_best > 0.0:
			pass # once the trial is cleared it is for the record only: its foes give no gold or XP, so hunting stays worth it
		else:
			var g := 3 + m.rng.randi() % 5
			m.player.gold += g
			m.toast(tr("금화 +%d") % g)
			gain_xp(12)

func gain_xp(n: int) -> void:
	if m.has_bookmark:
		n = int(round(n * 1.2))
	m.player.xp += n
	while m.player.xp >= m.player.lv * 25:
		m.player.xp -= m.player.lv * 25
		m.player.lv += 1
		m.player.max_hp += 12
		m.player.atk += 3
		m.player.hp = float(m.player.max_hp)
		m.ui.banner_title.text = tr("레벨 %d") % m.player.lv
		m.ui.banner_sub.text = LV_MOVES.get(m.player.lv, "최대 체력 +12 · 공격력 +3")
		m.ui.banner.modulate.a = 1.0
		m.banner_t = 2.5
		m.effects.pillar(Vector3(m.player.x, m.height_at(m.player.x, m.player.z), m.player.z))
		m.sfx(523, 0.15, "triangle", 0.3)
		m.get_tree().create_timer(0.12).timeout.connect(func(): m.sfx(659, 0.15, "triangle", 0.3))
		m.get_tree().create_timer(0.24).timeout.connect(func(): m.sfx(784, 0.3, "triangle", 0.3))

# the level monsters are built and hit at: half of Sora's (Lv1 1, Lv10 5, Lv28 14), so each level up still makes her
# stronger; at the full level a goblin took 4 cuts at Lv1 and still 4 at Lv28 (the owner, 2026-10-25)
# Monsters grow with the land, as in the Ys games (the owner, 2026-10-27: "서쪽 늪보다 동쪽 숲의 몹이 더 세다"): each
# area adds its own step on top of a smaller share of Sora's level, so an area she has outgrown gets easier and the
# next one is harder. Steps follow the story's road; the area is the one Sora stands in (monsters spawn near her).
const AREA_STEP := [[740, 5], [620, 9], [560, 2], [530, 8], [500, 8], [480, 2], [430, 7], [390, 6], [350, 5], [310, 5], [270, 3],
	[230, 9], [180, 4], [100, 1], [0, 0]] # x from: water corridor (before the forest, so the grotto's step), workshop, village, undercroft, stairs, houses, castle, cloud, grotto, hill, lake, garden, forest, cave, marsh

func area_step(x: float) -> int:
	for a in AREA_STEP:
		if x >= float(a[0]) - 0.5:
			return a[1]
	return 0

# the owner found the field too easy (2026-10-27): half of Sora's level (was 30%) on top of the area step
func foe_lv() -> int:
	return int(m.player.lv * 0.5) + area_step(m.player.x)

# what a monster's blow adds per foe level: 2 (was 1), so blows keep up with Sora's +12 max HP a level
func foe_hit() -> int:
	return foe_lv() * 2

# the boss attacks that ignore foe_hit() (the owner, 2026-10-28: bosses tougher) add half of it on a single hit
func boss_extra() -> int:
	return int(0.5 * foe_hit())

func nearest_enemy(range_: float):
	var best = null
	var bd := range_
	for e in m.enemies:
		if not e.dead:
			var d := Vector2(e.x - m.player.x, e.z - m.player.z).length()
			if d < bd:
				bd = d
				best = e
	return best

# the sword's arc widens as Sora grows: about 70 degrees at Lv1, 150 from Lv8; hits follow the arc
func slash_span() -> float:
	return clampf(1.2 + 0.2 * (m.player.lv - 1), 1.2, 2.6)

func combo_len() -> int:
	return 3 + (1 if m.player.lv >= 2 else 0) + (1 if m.player.lv >= 6 else 0)

# one swing of the combo; the last swing of the chain is the finisher:
# 3 hits: a heavy cut; 4 hits: a full spin; 5 hits: a ground slam
const BUFFER := 0.18 # how early a J is kept before the swing it waits for ends
const CHAIN := 0.5   # a swing this soon after a landed hit is a chained one
var buffer_t := 0.0
var last_hit_t := -9.0

# tall plants near a blow are thrown aside and swing back (shaders/grass.gdshader "hit"); a new blow restarts it
var plant_hit := Vector4(0, 0, 99, 0)

func plants_hit(at: Vector2, r: float) -> void:
	plant_hit = Vector4(at.x, at.y, 0.0, r)

func update_plants(dt: float) -> void:
	if plant_hit.z > 1.3:
		return
	plant_hit.z += dt
	for sm: ShaderMaterial in m.plant_mats:
		sm.set_shader_parameter("hit", plant_hit)

func update_buffer(dt: float) -> void:
	update_plants(dt)
	if buffer_t <= 0.0:
		return
	buffer_t -= dt
	if m.player.atk_cd <= 0.0 and m.player.dodge <= 0.0:
		buffer_t = 0.0
		attack()

func attack() -> void:
	if m.player.dodge > 0:
		return
	if m.player.atk_cd > 0:
		if m.player.atk_cd <= BUFFER:
			buffer_t = BUFFER
		return
	if m.player.lv >= 4 and m.guarding and m.t - m.guard_since >= 1.0:
		charged_slash()
		return
	if m.player.lv >= 3 and m.key_down(KEY_SHIFT) and Vector2(m.player.vx, m.player.vz).length() > 4.0 and m.player.sp >= 15.0:
		dash_slash()
		return
	var tg = nearest_enemy(2.2)
	if tg != null:
		m.player.face = Vector2(tg.x - m.player.x, tg.z - m.player.z).normalized()
	var n := combo_len()
	m.player.combo = (m.player.combo + 1) % n if m.player.combo_t > 0 else 0
	m.player.combo_t = 0.6
	var last: bool = m.player.combo == n - 1
	var spin: bool = last and n == 4 or m.player.combo == 3 and n == 5
	var slam: bool = last and n == 5
	m.player.atk_cd = 0.38 if last else (0.3 if spin else 0.24)
	var f: Vector2 = m.player.face
	var here := Vector3(m.player.x, m.height_at(m.player.x, m.player.z), m.player.z)
	if spin or slam:
		m.effects.slash_fx(here, 0.0, true, 1.8, true)
	else:
		var ang := -atan2(f.y, f.x) - 0.9 * (-1.0 if m.player.combo == 1 else 1.0) + 0.9
		m.effects.slash_fx(Vector3(m.player.x + f.x * 0.5, here.y, m.player.z + f.y * 0.5), ang, false, slash_span(), true)
	var cone := cos(slash_span() / 2.0 + 0.45)
	var reach := 2.6 if slam else (2.0 if spin else 1.7)
	var mult: float = 2.4 if slam else (1.6 if spin else ([1.0, 1.15, 1.4][mini(m.player.combo, 2)] if not last else 1.8))
	var hit_any := false
	var air_in := false # a foe in the air lay inside the cut's reach (idea 57)
	var low_in := false
	for e in m.enemies:
		if e.dead:
			continue
		var d := Vector2(e.x - m.player.x, e.z - m.player.z)
		if d.length() < reach and (spin or slam or d.normalized().dot(f) > cone):
			if e.get("air", false):
				air_in = true
			else:
				low_in = true
			var countering := m.counter_t > 0.0
			damage_enemy(e, m.player.atk * (2.5 if countering else mult), Vector2(m.player.x, m.player.z), 7.0 if last else 3.0,
				countering, 0.14 if countering else (0.09 if last else 0.05))
			m.player.mp = minf(m.player.max_mp, m.player.mp + 5.0)
			m.last_hit_t = m.t
			hit_any = true
	air_whiff(air_in and not low_in)
	if hit_any and m.counter_t > 0.0:
		m.counter_t = 0.0
	if hit_any:
		if m.t - last_hit_t < CHAIN: # a chained cut: click, spark, a little momentum
			m.player.mp = minf(m.player.max_mp, m.player.mp + 3.0)
			m.burst(here + Vector3(f.x * reach * 0.8, 0.7, f.y * reach * 0.8), Color("#ffe28a"), 6, 1.6)
			m.sfx(1500, 0.03, "square", 0.12)
		last_hit_t = m.t
		m.player.atk_cd *= 0.7
	if m.in_cave:
		for c in m.crystals:
			var dc := Vector2(c.x - m.player.x, c.z - m.player.z)
			if dc.length() < reach + 0.3 and (spin or slam or dc.normalized().dot(f) > cone):
				m.crystal_hit(c)
	if m.in_marsh():
		m.world_build.chop_trees(reach, f, cone, spin or slam)
	if m.in_village and m.in_house < 0:
		m.village.fountain_hit(m, reach, f, cone, spin or slam)
		m.village.bricks_hit(m, reach, f, cone, spin or slam)
		m.village.pinwheels_hit(m, reach, f, cone, spin or slam)
		m.village.bells_hit(m, reach, f, cone, spin or slam)
		m.village.turn_blocks_hit(m, reach, f, cone, spin or slam)
		m.football.hit(reach, f, cone, spin or slam)
		m.market.can_hit(reach, f, cone, spin or slam, hit_any)
	var me := Vector2(m.player.x, m.player.z)
	plants_hit(me if spin or slam else me + f * reach * 0.6, reach + 0.4 if spin or slam else reach * 0.9)
	if slam:
		m.shake = maxf(m.shake, 0.3)
		m.burst(here + Vector3(0, 0.2, 0), Color("#d8c8a0"), 30, 3.5)
	if last and m.player.lv >= 8:
		light_blade(f)
		if m.player.lv >= 20: # two more, 25 degrees to each side
			light_blade(f.rotated(0.44))
			light_blade(f.rotated(-0.44))
	var lunge := 4.0 if last else 2.0
	var held := Vector2(m.player.vx, m.player.vz)
	var step := f
	if m.t - last_hit_t < CHAIN + 0.1 and held.length() > 1.5 and absf(held.normalized().dot(f)) < 0.7: # side-step cut
		step = held.normalized()
		lunge = 4.5
	m.player.vx += step.x * lunge
	m.player.vz += step.y * lunge
	m.sfx(180.0 + m.player.combo * 60.0, 0.07, "sawtooth", 0.12, 300.0)

# swinging again at a foe too high to reach: the second miss in a row (within 3 s) says why, once per 8 s (delight idea 57)
var air_whiffs := 0
var air_whiff_t := -10.0
var air_hint_t := -10.0
var air_hints := 0

func air_whiff(missed_high: bool) -> void:
	if not missed_high:
		air_whiffs = 0
		return
	air_whiffs = air_whiffs + 1 if m.t - air_whiff_t < 3.0 else 1
	air_whiff_t = m.t
	if air_whiffs == 2 and m.t - air_hint_t > 8.0:
		air_hint_t = m.t
		air_hints += 1
		m.toast(tr("너무 높이 떠 있어 칼이 닿지 않는다. 내려앉을 때를 기다리자"))

# Lv3: running with Shift, J dashes 3 m ahead and cuts everything along the way
const DASH_TIME := 0.14 # the dash slash is a visible slide, not a blink (the user, 2026-10-25: Sora "warps" when keys are mashed)

func dash_slash() -> void:
	m.player.sp -= 15.0
	m.player.combo = 0
	m.player.combo_t = 0.0
	m.player.atk_cd = 0.4
	var f: Vector2 = m.player.face
	var start := Vector2(m.player.x, m.player.z)
	var end := start
	# stop short of walls and water; the water skip only counts while she is already on water, so letting go of
	# Shift never leaves her over a river the moment after
	var skip0: bool = m.skipping
	if not m.skip_water(start.x, start.y):
		m.skipping = false
	for k in 12:
		var nxt := start + f * (0.25 * (k + 1))
		if not m.player_can(nxt.x, nxt.y):
			break
		end = nxt
	m.skipping = skip0
	m.dash = {"from": start, "to": end, "t": 0.0, "f": f, "hit": {}, "ghosts": 0}
	m.player.inv = maxf(m.player.inv, DASH_TIME + 0.12)
	m.player.vx = 0.0
	m.player.vz = 0.0
	m.sfx(200, 0.16, "noise", 0.12, 900) # the whoosh
	m.sfx(260, 0.12, "sawtooth", 0.15, 600)
	m.burst(Vector3(start.x, 0.6, start.y), Color("#bfe7ff"), 10, 2.0)

func update_dash(dt: float) -> void:
	var d: Dictionary = m.dash
	d.t += dt
	var k: float = clampf(d.t / DASH_TIME, 0.0, 1.0)
	var np: Vector2 = d.from.lerp(d.to, k)
	m.player.x = np.x
	m.player.z = np.y
	m.player.inv = maxf(m.player.inv, 0.1)
	var f: Vector2 = d.f
	var reach: float = (d.from as Vector2).distance_to(np)
	for e in m.enemies: # cuts everything on the line as the slide passes it
		if e.dead:
			continue
		var eid: int = e.node.get_instance_id() # not the dictionary itself: its hash changes as it is hurt
		if d.hit.has(eid):
			continue
		var p := Vector2(e.x, e.z)
		var along := clampf((p - d.from).dot(f), 0.0, reach)
		if p.distance_to(d.from + f * along) < 1.1:
			d.hit[eid] = true
			damage_enemy(e, m.player.atk * 1.5, d.from, 5.0, false, 0.07)
			m.player.mp = minf(m.player.max_mp, m.player.mp + 5.0)
			m.last_hit_t = m.t
	if not d.hit.has("ball") and m.football.dash(np, f): # and the village football, once
		d.hit["ball"] = true
	while d.ghosts < 4 and k >= 0.2 * (d.ghosts + 1): # afterimages along the line
		d.ghosts += 1
		dash_ghost(d.from.lerp(d.to, 0.2 * d.ghosts))
	if int(d.t * 60.0) != int((d.t - dt) * 60.0):
		m.burst(Vector3(np.x, 0.5, np.y), Color("#e6f6ff"), 2, 1.2) # speed streak
	if k >= 1.0:
		var end: Vector2 = d.to
		m.player.vx = f.x * 3.0
		m.player.vz = f.y * 3.0
		m.dash = {}
		m.effects.slash_fx(Vector3(end.x, m.height_at(end.x, end.y), end.y), -atan2(f.y, f.x), false, 1.8, true)
		m.burst(Vector3((d.from.x + end.x) / 2.0, 0.6, (d.from.y + end.y) / 2.0), Color("#bfe7ff"), 16, 2.5)

# a fading copy of Sora's picture left where she passed
func dash_ghost(at: Vector2) -> void:
	var g := Sprite3D.new()
	g.texture = m.hero.texture
	g.region_enabled = true
	g.region_rect = m.hero.region_rect
	g.pixel_size = m.hero.pixel_size
	g.offset = m.hero.offset
	g.flip_h = m.hero.flip_h
	g.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	g.scale = m.hero.scale
	g.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	g.shaded = false
	g.modulate = Color(0.7, 0.9, 1.0, 0.55)
	g.position = Vector3(at.x, m.height_at(at.x, at.y), at.y)
	m.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)

# Lv4: guard for a second to gather light, then J: a wide, heavy cut in front
func charged_slash() -> void:
	m.guard_since = m.t
	m.player.combo = 0
	m.player.atk_cd = 0.5
	var f: Vector2 = m.player.face
	var here := Vector3(m.player.x, m.height_at(m.player.x, m.player.z), m.player.z)
	m.effects.release_dust(here) # the dust goes out first, the light follows 0.06 s behind (idea 54)
	var slash_at := here + Vector3(f.x * 0.8, 0, f.y * 0.8)
	var slash_ang := -atan2(f.y, f.x)
	m.get_tree().create_timer(0.06).timeout.connect(func(): m.effects.slash_fx(slash_at, slash_ang, true, 1.8, true))
	for e in m.enemies:
		if e.dead:
			continue
		var d := Vector2(e.x - m.player.x, e.z - m.player.z)
		if d.length() < 2.8 and d.normalized().dot(f) > 0.2:
			damage_enemy(e, m.player.atk * 3.0, Vector2(m.player.x, m.player.z), 10.0, true, 0.14)
			m.last_hit_t = m.t
	if m.in_village and m.in_house < 0:
		m.village.pinwheels_hit(m, 2.8, f, 0.2, false)
		m.football.hit(2.8, f, 0.2, false, m.football.KICK_FAR)
	m.shake = maxf(m.shake, 0.35)
	m.burst(here + Vector3(f.x, 0.8, f.y), Color("#fff1a0"), 30, 3.5)
	m.sfx(330, 0.3, "sawtooth", 0.25, -200)

# Lv8: the finisher sends a blade of light forward (it flies like the ember bolt)
func light_blade(f: Vector2) -> void:
	var b := MeshInstance3D.new()
	b.mesh = m.ring_mesh(0.3, 0.6, -0.9, 1.8)
	b.material_override = m.glow_mat(Color("#dff4ff"), 4.0)
	b.position = Vector3(m.player.x, m.height_at(m.player.x, m.player.z) + 0.6, m.player.z)
	b.rotation.y = atan2(f.x, f.y) + PI / 2
	m.add_child(b)
	m.projectiles.append({"node": b, "v": f * 12.0, "life": 0.7})

# a ring skill reaches the village's pinwheels and its football all round (the ball goes straight away from her)
func strike_village(reach: float) -> void:
	if m.in_village and m.in_house < 0:
		m.village.pinwheels_hit(m, reach, m.player.face, 0.0, true)
		m.football.hit(reach, m.player.face, 0.0, true, m.football.KICK_FAR)

func skill_cost(i: int) -> int:
	return 45 if i == 2 and m.woke[2] else SKILL_MP[i]

func use_skill(i: int) -> void:
	if m.player.cds[i] > 0:
		return
	if m.player.mp < skill_cost(i):
		m.toast("기세가 모자라다")
		return
	m.player.mp -= skill_cost(i)
	m.player.cds[i] = Main.SKILL_CD[i] * (0.8 if m.has_shard else 1.0) * (0.8 if m.player.lv >= 15 else 1.0)
	var here := Vector3(m.player.x, m.height_at(m.player.x, m.player.z), m.player.z)
	var me := Vector2(m.player.x, m.player.z)
	match i:
		0: # whirl (woken: wider and harder)
			var woke: bool = m.woke[0]
			m.sfx(140, 0.3, "sawtooth", 0.2, 400)
			m.effects.slash_fx(here, 0.0, true, 1.8, true)
			if woke: # the woken whirl throws a wider ring of wind
				m.burst(here + Vector3(0, 0.5, 0), Color("#9fd4ff"), 30, 5.0)
			for e in m.enemies:
				if not e.dead and Vector2(e.x, e.z).distance_to(me) < (3.4 if woke else 2.6):
					damage_enemy(e, m.player.atk * (1.9 if woke else 1.4), me, 6.0)
			strike_village(3.4 if woke else 2.6)
		1: # ember bolt
			m.sfx(400, 0.2, "triangle", 0.2, -250)
			var tg = nearest_enemy(12.0)
			var dir: Vector2 = (Vector2(tg.x, tg.z) - me).normalized() if tg != null else m.player.face
			for a in ([-0.22, 0.0, 0.22] if m.woke[1] else [0.0]): # woken: three bolts in a fan
				var b := MeshInstance3D.new()
				var sp := SphereMesh.new()
				sp.radius = 0.16
				sp.height = 0.32
				b.mesh = sp
				b.material_override = m.glow_mat(Color("#ff8a2a"), 4.0)
				if a == 0.0: # one light is enough; the web renderer lights a mesh with at most 8
					var l := OmniLight3D.new()
					l.light_color = Color("#ff8a3a")
					l.light_energy = 2.0
					l.omni_range = 4.0
					b.add_child(l)
				b.position = here + Vector3(0, 0.6, 0)
				m.add_child(b)
				m.projectiles.append({"node": b, "v": dir.rotated(a) * 14.0, "life": 1.2})
		2: # radiant nova
			var mm := MeshInstance3D.new()
			mm.mesh = m.ring_mesh(0.2, 0.6, 0.0, TAU)
			var mat := m.glow_mat(Color("#fff1a0"), 3.0)
			mm.material_override = mat
			mm.position = here + Vector3(0, 0.3, 0)
			m.add_fx(mm, 0.7, func(n: Node3D, k: float, _dt: float):
				n.scale = Vector3.ONE * (1.0 + k * 9.0)
				mat.albedo_color.a = 1.0 - k)
			m.burst(here + Vector3(0, 0.8, 0), Color("#fff1a0"), 40, 4.0)
			for e in m.enemies:
				if not e.dead and Vector2(e.x, e.z).distance_to(me) < 5:
					damage_enemy(e, m.player.atk * 2.2, me, 9.0)
			strike_village(5.0)
			m.shake = 0.3
			m.sfx(220, 0.6, "sine", 0.4, 600)
			if m.woke[2]: # woken: the light mends her too
				var heal := int(m.player.max_hp * 0.15)
				m.player.hp = minf(float(m.player.max_hp), m.player.hp + heal)
				m.pop_num(here + Vector3(0, 1.6, 0), "+" + str(heal), Color("#7aff8a"))

# standing still out of a fight mends her slowly (the owner, 2026-10-28: "체력은 가만히 있으면 다시 회복 안 되나?"):
# after REST_HEAL_WAIT seconds without moving, swinging, rolling or guarding, and with no monster within 6 tiles and
# no boss awake, REST_HEAL of her max HP a second. Slow enough that potions and the reed cushion still count.
const REST_HEAL_WAIT := 3.0
const REST_HEAL := 0.02
var rest_glow_t := 0.0

func rest_heal(dt: float) -> void:
	if m.idle_t < REST_HEAL_WAIT or m.player.hp <= 0.0 or m.player.hp >= m.player.max_hp or m.ui.boss.visible or m.story_open or m.monsters.boss_fight_on(m.player.x, m.player.z): # v0.1.72: any woken boss, bar or not
		return
	for e in m.enemies:
		if not e.dead and not e.get("prop", false) and Vector2(e.x - m.player.x, e.z - m.player.z).length() < 6.0: # props (squirrel cages) do not attack
			return
	m.player.hp = minf(float(m.player.max_hp), m.player.hp + m.player.max_hp * REST_HEAL * dt)
	rest_glow_t += dt
	if rest_glow_t >= 1.5:
		rest_glow_t = 0.0
		m.burst(Vector3(m.player.x, m.ground_y + 0.1, m.player.z), Color("#9fe07a"), 4, 0.6)

# what one potion would mend right now, from her HP and the keepsakes (the shop shows it before buying, delight idea 83)
func heal_preview() -> float:
	return minf(m.player.max_hp - m.player.hp, (75.0 if m.has_sprout else (65.0 if m.has_acorn else 45.0)) * (1.3 if m.player.lv >= 25 else 1.0))

var potion_kept := 0 # drinks refused at full strength (autoplay potion_kept)

func drink_potion() -> void:
	if m.player.pots <= 0:
		m.toast("회복약이 없다")
		return
	if m.player.cds[3] > 0:
		return
	if m.player.hp >= float(m.player.max_hp) and (not m.has_oil or m.player.mp >= m.player.max_mp): # nothing to mend: the cork squeaks and the potion stays (delight idea 56)
		m.player.cds[3] = 0.5
		potion_kept += 1
		m.sfx(300, 0.08, "triangle", 0.1, 180.0)
		m.toast("기운이 가득해서 약을 아꼈다")
		return
	m.player.pots -= 1
	m.player.cds[3] = 2.0
	var h := heal_preview()
	m.player.hp += h
	if m.has_oil:
		m.player.mp = minf(m.player.max_mp, m.player.mp + 20.0)
	var y := m.height_at(m.player.x, m.player.z)
	m.pop_num(Vector3(m.player.x, y + 1.9, m.player.z), "+%d" % int(h), Color("#8dff9a"))
	m.burst(Vector3(m.player.x, y + 0.6, m.player.z), Color("#8dff9a"), 20, 2.0)
	m.sfx(660, 0.25, "sine", 0.25, 300)

func dodge() -> void:
	if not m.dash.is_empty():
		return
	var cost := (15 if m.has_feather else 25) - (7 if m.player.lv >= 10 else 0)
	if m.player.dodge > 0 or m.player.sp < cost:
		return
	m.player.sp -= cost
	m.player.dodge = 0.32
	m.player.inv = 0.3
	m.dodge_start = m.t
	var d := Vector2(m.player.vx, m.player.vz)
	d = m.player.face if d.length() < 0.1 else d.normalized()
	m.player.dvx = d.x * 11.0
	m.player.dvz = d.y * 11.0
	m.sfx(120, 0.12, "triangle", 0.15, 80)
