# Bori's shop: open/close, prices, buying.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const SHOP_GREET := ["어서 오렴. 천천히 골라 보거라.", "오늘은 뭐가 필요하니?", "늪이 험하지? 약은 넉넉히 챙기렴.", "늪 구석구석에 달지기들의 옛 지도 조각이 흩어져 있다더구나."]

func _init(main: Main) -> void:
	m = main

# Bori's three empty cups behind the cottage (delight idea 71): looked at left to right they are only empty, but the last one
# of the three, reached in that order, still steams a little. Nothing is given and nothing is told; a wrong order starts over
const CUP_REACH := 0.9
const CUP_STEAM := 6.0
const STEAM_X := 0.5  # the last cup's place on the plank and its rim: world_build.gd TEA_GAP and TEA_TOP (a constant read across
const STEAM_Y := 0.36 # the two files would make them wait for each other to compile)
var cup_next := 0      # the cup the order expects next
var cup_steam_t := 0.0 # seconds the last cup still steams
var cup_looks := 0     # cups looked at (autoplay d71_tea_cups)
var cup_steams := 0    # times the last cup steamed

func cup_look_near() -> int: # the nearest cup within reach, or -1
	if m.story_step < 3:
		return -1
	var best := -1
	var bd := CUP_REACH
	for i in m.world_build.tea_at.size():
		var d: float = Vector2(m.player.x, m.player.z).distance_to(m.world_build.tea_at[i])
		if d < bd:
			bd = d
			best = i
	return best

func cup_key() -> bool:
	var i := cup_look_near()
	if i < 0:
		return false
	cup_looks += 1
	m.sfx(1320.0 + i * 110.0, 0.05, "triangle", 0.06)
	if i == cup_next:
		cup_next += 1
	else:
		cup_next = 1 if i == 0 else 0
	if cup_next >= 3: # the last of the three, in order
		cup_next = 0
		cup_steam_t = CUP_STEAM
		cup_steams += 1
		m.toast(tr("마지막 잔에서만 김이 난다"))
	else:
		m.toast(tr("찻잔 셋 곁에 넷째 잔이 놓였다. 소라의 잔이다") if m.marsh_toys.home_done() else tr("빈 찻잔이다"))
	return true

func update_cups(dt: float) -> void:
	if m.world_build.tea_fourth != null:
		m.world_build.tea_fourth.visible = m.marsh_toys.home_done()
	var steam: Array = m.world_build.tea_steam
	if steam.is_empty():
		return
	cup_steam_t = maxf(0.0, cup_steam_t - dt)
	var on := cup_steam_t > 0.0
	for s in steam:
		var q: MeshInstance3D = s[0]
		q.visible = on
		if not on:
			continue
		var k: float = fmod(m.t * 0.4 + s[1], 1.0)
		q.position.y = STEAM_Y + k * 0.4
		q.position.x = STEAM_X + sin(k * 6.0 + s[1] * 4.0) * 0.03
		q.scale = Vector3.ONE * (0.7 + k * 0.8)
		(q.material_override as StandardMaterial3D).albedo_color.a = sin(k * PI) * 0.4 * minf(1.0, cup_steam_t / 0.5)

func near_shop() -> bool:
	return Vector2(m.player.x - m.shop_pos.x, m.player.z - m.shop_pos.z).length() < 1.6

# Bori has heard what Sora has been up to: a line for each keepsake or deed, mixed in with her usual greetings
func bori_news() -> Array:
	var out: Array = []
	if m.marsh.chest_open: out.append("지도 조각을 다 맞췄다며? 달지기들 솜씨는 여전하구나.")
	if m.fly_q >= 3: out.append("반딧불 병이구나. 밤길이 덜 무섭겠어.")
	if m.has_pearl: out.append("물빛 진주라니. 물결네 할아버지가 아끼던 거란다.")
	if m.has_feather: out.append("바람 깃털을 지녔구나. 걸음이 한결 가벼워 보인다.")
	if m.has_acorn: out.append("다람쥐들이 고맙다고 도토리를 줬다고? 귀엽기도 하지.")
	if m.has_ring: out.append("그 반지 소리가 맑구나. 동굴 수정이지?")
	if m.castle.pages_read() >= 3: out.append("한결의 일기를 읽었다고…… 그 녀석, 끝까지 혼자 짊어졌구나.")
	if m.trial_best > 0.0: out.append("심지가 그러던데, 달빛 시련을 마쳤다며? 대단하구나.")
	if m.has_armour: out.append("달지기 갑옷이 잘 어울리는구나. 이제야 마음이 놓인다.")
	if not m.has_tea and m.marsh.picked_count() == 0 and m.story_step >= 5: out.append("달이 반 넘게 찬 밤이면 늪에 달꽃이 핀단다. 세 송이만 가져오면 차를 끓여 주마.")
	if m.story_step >= 3 and m.shore_q == 0: out.append("네가 깨어났다는 물가, 한번 다시 가 보렴. 물은 늘 무언가를 실어 오거든.")
	if m.shore_q == 3 and m.story_step >= 5: out.append("물길이 흐르니, 밤에 그 등불을 띄워 주렴.")
	if m.quarters_q >= 5: out.append("성 숙소 바구니 방이라…… 그 불빛을 기다리던 밤이 생각나는구나.")
	return out

func toggle_shop(open: bool) -> void:
	if open and m.story_step < 3:
		m.story.meet_bori()
		return
	m.shop_open = open
	m.ui.shop.visible = open
	if open:
		var lines: Array = SHOP_GREET.duplicate()
		lines.append_array(bori_news())
		m.ui.shop_say.text = lines[m.rng.randi() % lines.size()]
		m.ui.shop_keeper.texture = load("res://art/portrait/bori.png")
		if m.touch_ui:
			fit_shop()
		refresh_shop()
		m.sfx(660, 0.12, "triangle", 0.2)

func shop_price(i: int) -> int:
	return Main.SHOP[i].price + (40 * m.shop_bought[i] if i >= 2 else 0)

func potion_preview_text() -> String: # the line under the potion card: what one drink mends at this HP
	var h := int(m.combat.heal_preview())
	return tr("지금 마시면 체력 +%d") % h if h > 0 else tr("체력이 가득하다")

func refresh_shop() -> void:
	m.ui.shop_gold.text = "◆ %d" % m.player.gold
	if m.ui.has("shop_preview"):
		m.ui.shop_preview.text = potion_preview_text()
	for i in Main.SHOP.size():
		m.ui.shop_btns[i].disabled = m.player.gold < shop_price(i)
		m.ui.shop_btns[i].text = tr("◆ %d  사기") % shop_price(i)

func buy(i: int) -> void:
	var it: Dictionary = Main.SHOP[i]
	if m.player.gold < shop_price(i):
		m.ui.shop_say.text = "금화가 조금 모자라구나. 늪을 한 바퀴 더 돌고 오렴."
		m.ui.shop_keeper.texture = load("res://art/portrait/bori_serious.png")
		return
	m.player.gold -= shop_price(i)
	m.shop_bought[i] += 1
	match i:
		0: m.player.pots += 1
		1: m.player.mp = minf(m.player.max_mp, m.player.mp + 50.0)
		2: m.player.atk += 3
		3:
			m.player.max_hp += 15
			m.player.hp += 15
	m.ui.shop_say.text = ["몸조심하렴. 아플 땐 아끼지 말고 마시고.", "달콤하지? 기운이 날 게다.", "날이 잘 섰다. 손 베이지 않게 조심해.", "든든할 게다. 이제 좀 마음이 놓이는구나."][i]
	m.ui.shop_keeper.texture = load("res://art/portrait/bori.png")
	m.sfx(880, 0.08, "square", 0.15)
	m.get_tree().create_timer(0.07).timeout.connect(func(): m.sfx(1320, 0.12, "square", 0.15))
	refresh_shop()

# the shop on a phone: the board shrunk to fit above Bori's line, the line along the bottom, a back key in the corner
# (the touch keys are hidden while it is open, so the key is the way out); elsewhere the desktop layout
func fit_shop() -> void:
	var board: Control = m.ui.shop_board
	var line: Control = m.ui.shop_line
	m.ui.shop_back.visible = m.touch_ui
	if not m.touch_ui:
		board.scale = Vector2.ONE
		m.place(board, Control.PRESET_CENTER, Vector2(-160, -270), Vector2(620, 420))
		m.place(line, Control.PRESET_CENTER_BOTTOM, Vector2(-470, -150), Vector2(940, 100))
		m.ui.shop_keys.text = "1 → 4 사기  ·  E / Esc 닫기"
		return
	var vs := m.get_viewport().get_visible_rect().size
	m.place(line, Control.PRESET_CENTER_BOTTOM, Vector2(-470, -108), Vector2(940, 100))
	var s := minf(1.0, (vs.y - 140.0) / 438.0) # the board and its tab (18 px) between 8 px from the top and the line's tab
	var x := (258.0 + vs.x - 8.0) / 2.0 - 310.0 * s # centred right of Bori
	m.place(board, Control.PRESET_TOP_LEFT, Vector2(x, 8.0 + 18.0 * s), Vector2(620, 420))
	board.scale = Vector2.ONE * s
	m.ui.shop_keys.text = "카드를 누르면 산다  ·  왼쪽 위 단추로 닫기"
	m.menus.size_back_keys(m.ui.shop)
