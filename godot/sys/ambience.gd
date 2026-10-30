# Ambience: three quiet loops made in code (the fountain's water, the rain in the open, the rain on the eaves) and the gain each one
# has (delight ideas 46, 48, 50). They play on the Sfx bus, so the sound switch silences them; the music is never touched.
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const RATE := 22050
const LOOP_SECS := 2.0
const FOLD := 2205 # the 0.1 s the loop's end is folded over its start, so the seam makes no click
const BASE_DB := -16.0 # a loop at full gain sits this far under the effects
const SLEW := 1.2 # a gain moves at most this much a second, so no change is a jump
# 46: the water is full strength within WATER_NEAR tiles of the fountain, fades out smoothly by WATER_FAR; a low jet is WATER_LOW as loud
const WATER_NEAR := 2.5
const WATER_FAR := 16.0
const WATER_LOW := 0.45
# 50: indoors the open rain stays as a murmur and the eave's round taps carry it
const RAIN_IN := 0.2
const EAVE_IN := 0.8
# 48: a picture scene silences the loops fast; after it shuts they wait STORY_GAP s, then come back over STORY_RAMP s
const STORY_DUCK := 4.0
const STORY_GAP := 0.5
const STORY_RAMP := 1.5

var players := {} # name -> AudioStreamPlayer, made the first time the loop is wanted
var gains := {"water": 0.0, "rain": 0.0, "eave": 0.0}
var duck := 1.0 # 1 open, 0 shut by a picture scene
var duck_hold := 0.0

func _init(main: Main) -> void:
	m = main

func shutdown() -> void:
	for p in players.values():
		(p as AudioStreamPlayer).stop()
		(p as AudioStreamPlayer).stream = null
	players.clear()

# where the fountain's water loop is heading: loud beside the basin, softer with every step away, none outside the village or indoors
func water_target() -> float:
	if m.intro or not m.in_village or m.in_house >= 0 or m.village == null:
		return 0.0
	var d := Vector2(m.player.x, m.player.z).distance_to(m.village.fountain_at())
	return (1.0 - smoothstep(WATER_NEAR, WATER_FAR, d)) * (1.0 if m.village.fountain_wet else WATER_LOW)

func rain_target() -> float:
	if not m.raining:
		return 0.0
	return RAIN_IN if m.in_house >= 0 else 1.0

func eave_target() -> float:
	return EAVE_IN if m.raining and m.in_house >= 0 else 0.0

func target_of(name: String) -> float:
	match name:
		"water": return water_target()
		"rain": return rain_target()
	return eave_target()

# the picture-scene duck: shut quickly while one is open, still for STORY_GAP s after it, then open over STORY_RAMP s
func update_duck(dt: float) -> void:
	if m.story_open and not m.talk_mode:
		duck = move_toward(duck, 0.0, STORY_DUCK * dt)
		duck_hold = STORY_GAP
	elif duck_hold > 0.0:
		duck_hold -= dt
	else:
		duck = move_toward(duck, 1.0, dt / STORY_RAMP)

# the gain the loop is heard at now
func heard(name: String) -> float:
	return gains[name] * smoothstep(0.0, 1.0, duck)

func update(dt: float) -> void:
	update_duck(dt)
	for name in gains:
		gains[name] = move_toward(gains[name], target_of(name), SLEW * dt)
		apply(name, 0.0 if m.muted else heard(name))

func apply(name: String, g: float) -> void:
	var p: AudioStreamPlayer = players.get(name)
	if g <= 0.001:
		if p != null and p.playing:
			p.stop()
		return
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = "Sfx"
		p.stream = make_loop(name)
		m.add_child(p)
		players[name] = p
	p.volume_db = BASE_DB + linear_to_db(g)
	if not p.playing:
		p.play()

# a two second loop of filtered noise ("water", "rain") or of soft round taps ("eave")
func make_loop(kind: String) -> AudioStreamWAV:
	var n := int(RATE * LOOP_SECS)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var buf := PackedFloat32Array()
	buf.resize(n + FOLD)
	var amp := 0.5
	if kind == "eave":
		amp = 0.7
		for i in n + FOLD:
			buf[i] = rng.randf_range(-1.0, 1.0) * 0.03 # a faint bed under the taps
		for t in 8: # taps spread over the loop, wrapping round its end
			var at := int(rng.randf() * n)
			var f := rng.randf_range(170.0, 230.0)
			var vol := rng.randf_range(0.5, 0.9)
			for j in 2200:
				var k := float(j) / 2200.0
				var v := sin(TAU * f * j / RATE) * vol * pow(0.002, k) * minf(1.0, j / 60.0)
				buf[(at + j) % n] += v
	else:
		var lo := 0.0
		var hi := 0.0
		for i in n + FOLD:
			var w := rng.randf_range(-1.0, 1.0)
			if kind == "water": # a band of noise that burbles: swelling twice and five times a loop
				lo = lerpf(lo, w, 0.25)
				hi = lerpf(hi, w, 0.04)
				buf[i] = (lo - hi) * 1.8 * (0.7 + 0.2 * sin(TAU * 5.0 * i / n) + 0.1 * sin(TAU * 2.0 * i / n))
			else: # rain: a soft hiss
				lo = lerpf(lo, w, 0.6)
				buf[i] = lo * 0.7
		amp = 0.5 if kind == "water" else 0.35
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := buf[i]
		if kind != "eave" and i < FOLD: # the tail of the noise fades in over its head
			var k := float(i) / FOLD
			v = buf[i] * k + buf[n + i] * (1.0 - k)
		data.encode_s16(i * 2, int(clampf(v * amp, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n
	return s
