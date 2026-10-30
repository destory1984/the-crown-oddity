# The phone's home bar and camera hole (delight idea 95): the screen's safe area turned into canvas pixels, so the touch keys,
# the HUD corners and the corner text stay clear of them. DisplayServer.get_display_safe_area() is in screen pixels; the canvas
# (content scale, expand) is smaller or bigger than the window by one factor. A window that does not cover its screen (a desktop
# window, a browser tab) has no such areas: everything stays where it was.
extends RefCounted

const Main := preload("res://main.gd")

const MAX_INSET := 120.0 # canvas px; a bigger one is a reading error
var m: Main
var held := false # the autoplay tests set the insets by hand
var check_t := 0.0

func _init(main: Main) -> void:
	m = main

# left, top, right, bottom in canvas pixels; zero when the window is not the whole screen or the safe area is the whole screen
static func canvas_insets(screen: Vector2i, safe: Rect2i, window: Vector2i, canvas: Vector2) -> Vector4:
	if screen.x <= 0 or screen.y <= 0 or window.x <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	if absi(window.x - screen.x) > 2 or absi(window.y - screen.y) > 2:
		return Vector4.ZERO
	var k := canvas.x / float(window.x)
	var out := Vector4(safe.position.x, safe.position.y, screen.x - safe.end.x, screen.y - safe.end.y)
	for i in 4:
		out[i] = clampf(roundf(maxf(0.0, out[i]) * k), 0.0, MAX_INSET)
	return out

# read the display now; the HUD moves only when the numbers changed
func refresh() -> void:
	if held:
		return
	var s := Vector4.ZERO
	if m.touch_ui:
		s = canvas_insets(DisplayServer.screen_get_size(), DisplayServer.get_display_safe_area(), DisplayServer.window_get_size(), m.get_viewport().get_visible_rect().size)
	apply(s)

func apply(s: Vector4) -> void:
	if s == m.safe:
		return
	m.safe = s
	m.hud_build.apply_safe()

# called from the touch layer's frame; looks again once a second (a turned phone has other insets)
func update(dt: float) -> void:
	check_t -= dt
	if check_t <= 0.0:
		check_t = 1.0
		refresh()
