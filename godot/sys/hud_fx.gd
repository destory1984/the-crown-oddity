# What the screen says back (the owner, 2026-10-31: "세 가지 넣어라", from the video on visual feedback): gold flies from Sora to
# the gold pill and the number climbs as it lands, and below a quarter of her HP the screen's edge beats red. The size of the
# effect follows the size of the event: a few coins are one diamond, a chest is eight. The third of the three is in touch.gd.
# Every gold line in the game stays as it is: the gain is read here from the change in player.gold.
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const COIN := 26.0        # a flying diamond, a side
const SPREAD := 0.24      # seconds out from Sora
const FLY := 0.42         # seconds to the pill
const STAGGER := 0.05
const POP_FALL := 3.0     # the pill's pop dies in a third of a second
const LOW_AT := 0.25      # of her HP
const VERY_LOW := 0.1
const EDGE_IN := 2.0      # the red comes in and goes out in half a second
const TICK_HZ := [1320.0, 1480.0, 1760.0]

var seen := -1            # player.gold at the last look, -1 until the first look
var shown := 0            # the number on the pill
var flying := 0
var gold_pop := 0.0       # 1 on a landing, falls to 0; hud.gd draws the pill bigger by it
var flown := 0            # diamonds sent (autoplay hud_fx)
var edge: TextureRect
var low := false
var beats := 0            # times she fell below LOW_AT (autoplay hud_fx)

func _init(main: Main) -> void:
	m = main

func busy() -> bool:
	return m.intro or m.story_open or m.shop_open or m.settings_open or m.ui.journal.visible or m.ui.bag.visible

# a load or a test set the purse: nothing to celebrate
func sync() -> void:
	seen = -1

func update(dt: float) -> void:
	gold_pop = maxf(0.0, gold_pop - dt * POP_FALL)
	update_gold()
	update_edge(dt)

func update_gold() -> void:
	var g: int = m.player.gold
	if seen < 0 or g < seen or m.camera == null:
		seen = g
		shown = mini(shown, g) if flying > 0 else g
		return
	if g > seen and not busy(): # a gain inside a talk waits for the talk to end
		fly(g - seen)
		seen = g
	if flying == 0:
		shown = seen

func coins_for(gain: int) -> int:
	if gain < 10:
		return 1
	if gain < 50:
		return 3
	return 5 if gain < 200 else 8

func fly(gain: int) -> void:
	var from := m.camera.unproject_position(Vector3(m.player.x, m.ground_y + 1.2, m.player.z))
	var vs := m.get_viewport().get_visible_rect().size
	var to := Vector2(vs.x - 139.0 + 24.0, vs.y - 129.0 + 14.0) # the pill's diamond, hud.gd
	var n := coins_for(gain)
	var step := ceili(float(gain) / n)
	var parent: Node = m.ui.story.get_parent()
	for i in n:
		var coin := TextureRect.new()
		coin.texture = m.menus.diamond_tex()
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.size = Vector2(COIN, COIN)
		coin.pivot_offset = coin.size / 2.0
		coin.position = from - coin.size / 2.0
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.modulate.a = 0.0
		parent.add_child(coin)
		flying += 1
		flown += 1
		var out := from + Vector2.from_angle(TAU * (float(i) + randf()) / n) * randf_range(36.0, 64.0) - coin.size / 2.0
		var tw := coin.create_tween()
		tw.tween_interval(STAGGER * i)
		tw.tween_property(coin, "modulate:a", 1.0, 0.0)
		tw.tween_property(coin, "position", out, SPREAD).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(coin, "position", to - coin.size / 2.0, FLY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(coin, "scale", Vector2.ONE * 0.6, FLY)
		tw.tween_callback(func():
			landed(step)
			coin.queue_free())

func landed(step: int) -> void:
	flying -= 1
	shown = mini(seen, shown + step)
	gold_pop = 1.0
	m.sfx(TICK_HZ.pick_random(), 0.06, "triangle", 0.1)

func ensure_edge() -> void:
	if edge != null:
		return
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	grad.colors = PackedColorArray([Color(0.7, 0.05, 0.08, 0.0), Color(0.7, 0.05, 0.08, 0.0), Color(0.75, 0.05, 0.08, 1.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	edge = TextureRect.new()
	edge.texture = tex
	edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.modulate.a = 0.0
	edge.visible = false
	var parent: Node = m.ui.story.get_parent()
	parent.add_child(edge)
	parent.move_child(edge, 0) # under the HUD: it never covers a number

func hp_frac() -> float:
	return float(m.player.hp) / float(m.player.max_hp)

func update_edge(dt: float) -> void:
	ensure_edge()
	var f := hp_frac()
	var now: bool = f > 0.0 and f <= LOW_AT and not m.intro and not m.story_open
	if now and not low:
		beats += 1
		m.sfx(90.0, 0.28, "sine", 0.22)
	low = now
	var want := 0.0
	if low:
		var beat := 5.0 if f <= VERY_LOW else 3.2
		want = 0.32 + (0.22 * absf(sin(m.t * beat)) if bool(m.cfg.get("shake", true)) else 0.1)
	edge.modulate.a = move_toward(edge.modulate.a, want, dt * EDGE_IN)
	edge.visible = edge.modulate.a > 0.0
