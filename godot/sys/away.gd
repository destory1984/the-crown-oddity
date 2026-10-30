# Coming back from a call or another window (delight idea 96): when the app loses focus on a phone (or a desktop with the touch
# keys on) Sora stands still, the scene dims and one key, 돌아왔다, waits in the middle. Play goes on only after it is pressed. The
# tree is paused, so the monsters, the clock and a story's typing all wait where they were; the key's layer keeps running.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main
var off := false # the autoplay tests turn it off; the ones for this idea call leave() themselves
var layer: CanvasLayer
var button: Button

func _init(main: Main) -> void:
	m = main

func notify(what: int) -> void:
	if what == Node.NOTIFICATION_APPLICATION_FOCUS_OUT or what == Node.NOTIFICATION_APPLICATION_PAUSED:
		if not off and m.touch_ui and not m.intro:
			leave()

func leave() -> void:
	if m.away:
		return
	m.away = true
	m.touch_move = Vector2.ZERO # no finger is down any more: the stick, the held keys and the latches let go
	m.touch_keys.clear()
	m.fake_keys.clear()
	if m.touch_layer != null:
		m.touch_layer.pad_idx = -1
		m.touch_layer.held.clear()
		m.touch_layer.clear_latches()
	if layer == null:
		build()
	layer.visible = true
	m.get_tree().paused = true
	button.grab_focus()

func back() -> void:
	if not m.away:
		return
	m.away = false
	layer.visible = false
	m.get_tree().paused = false

func build() -> void:
	layer = CanvasLayer.new()
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	m.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.008, 0.016, 0.043, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP # a tap beside the key does nothing
	layer.add_child(dim)
	button = Button.new()
	button.text = tr_back()
	button.theme = m.menus.get_menu_theme()
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_font_override("font", m.ui_font)
	button.set_anchors_preset(Control.PRESET_CENTER)
	button.offset_left = -130.0
	button.offset_right = 130.0
	button.offset_top = -40.0
	button.offset_bottom = 40.0
	button.pressed.connect(back)
	dim.add_child(button)

func tr_back() -> String:
	return m.tr("돌아왔다")
