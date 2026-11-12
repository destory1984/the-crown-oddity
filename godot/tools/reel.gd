# Promo reel driver: plays a short clip with injected input so Godot's Movie Maker can record it.
# Run: Godot --write-movie out.png --fixed-fps 30 --path . -- --scene=boss --reel=parry
# Clips: rush (crowd fight), parry (flash guard on the Brick King), skills (the three skills), king_down, title.
# Only loaded when --reel is given (sys/scenes.gd); the game never runs it otherwise.
extends Node

var main: Node
var clip := "rush"
var t := 0.0
var guard_left := 0.0
var parries := 0
var seen_guards := 0

const LENGTH := {"rush": 8.0, "parry": 9.0, "skills": 8.0, "king_down": 7.0, "title": 4.0}

func _ready() -> void:
	# the game's music stays out of the recording: tools/shorts.py lays one tune under the whole reel
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	if clip == "title":
		return
	main.intro = false
	main.cam_dist = 13.0 # closer than play's 18: Sora reads at phone size in a 1080-wide frame
	if clip == "skills":
		main.player.mp = float(main.player.max_mp)
	if clip == "king_down":
		var k = boss()
		if k != null:
			k.hp = 70.0

func _process(dt: float) -> void:
	t += dt
	if t >= LENGTH.get(clip, 8.0) + 1.5: # the first 1.5 s (title fading out) is cut when the reel is put together
		main.fake_keys.clear()
		print("REEL %s guards=%d flash_guards=%d" % [clip, parries, main.stats.guards])
		get_tree().quit()
		return
	if clip == "title":
		return
	if main.stats.guards > seen_guards: # tools/shorts.py slows the reel around this moment
		seen_guards = main.stats.guards
		print("REEL_FLASH %.2f" % t)
	main.player.hp = maxf(main.player.hp, main.player.max_hp * 0.85) # the reel never shows Sora fainting
	main.close_story()
	if clip == "skills":
		main.player.mp = maxf(main.player.mp, 60.0)
		for k in 3:
			main.player.cds[k] = 0.0
		var at := [1.0, 3.2, 5.4]
		for k in 3:
			if t - dt < at[k] and t >= at[k]:
				aim(nearest())
				main.use_skill(k)
	fight(dt)

func boss():
	for e in main.enemies:
		if e.get("boss", false) and not e.dead:
			return e
	return null

func nearest():
	var best = null
	var bd := 1e9
	for e in main.enemies:
		if e.dead or e.get("prop", false) or not is_instance_valid(e.get("node", null)) or not e.node.visible:
			continue
		var d := Vector2(e.x - main.player.x, e.z - main.player.z).length()
		if d < bd:
			bd = d
			best = e
	return best

func aim(e) -> void:
	if e == null:
		return
	var v := Vector2(e.x - main.player.x, e.z - main.player.z)
	if v.length() > 0.01:
		main.player.face = v.normalized()

# walk at the nearest foe, hold J beside it; on the king's swing, guard 0.08 s before it lands
func fight(dt: float) -> void:
	var keys: Dictionary = main.fake_keys
	keys.clear()
	var e = boss() if clip in ["parry", "king_down"] else nearest()
	if e == null:
		return
	var v := Vector2(e.x - main.player.x, e.z - main.player.z)
	var d := v.length()
	guard_left -= dt
	if e.get("boss", false) and e.swing > 0.0 and e.swing < 0.1 and d < 2.4:
		guard_left = 0.25
		parries += 1
	if guard_left > 0.0:
		aim(e)
		keys[KEY_L] = true
		return
	var reach := 2.2 if e.get("boss", false) else 1.3
	if d > reach:
		hold_world(v / d)
	else:
		aim(e)
		keys[KEY_J] = true
	if clip == "rush" and fmod(t, 3.0) > 2.85 and fmod(t - dt, 3.0) <= 2.85:
		main.dodge()

func hold_world(dir: Vector2) -> void:
	var fwd := Vector2(-sin(main.cam_yaw), -cos(main.cam_yaw))
	var right := Vector2(cos(main.cam_yaw), -sin(main.cam_yaw))
	var f := dir.dot(fwd)
	var r := dir.dot(right)
	if f > 0.38: main.fake_keys[KEY_W] = true
	if f < -0.38: main.fake_keys[KEY_S] = true
	if r > 0.38: main.fake_keys[KEY_D] = true
	if r < -0.38: main.fake_keys[KEY_A] = true
