# Sound: sfx() synthesises every effect in code, footsteps.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const STEP_GAP := 0.42  # at most ~2.4 steps a second, even when running

func _init(main: Main) -> void:
	m = main

func sfx(freq: float, dur := 0.1, wave := "square", vol := 0.25, slide := 0.0) -> void:
	m.sfx_log.append("%s:%d" % [wave, int(freq)])
	if m.muted:
		return
	var pl := AudioStreamPlayer.new()
	pl.stream = sfx_stream(freq, dur, wave, vol, slide)
	m.add_child(pl)
	pl.play()
	pl.finished.connect(pl.queue_free)

func sfx_stream(freq: float, dur := 0.1, wave := "square", vol := 0.25, slide := 0.0) -> AudioStreamWAV:
	var key := "%s|%s|%s|%s|%s" % [freq, dur, wave, vol, slide]
	var stream: AudioStreamWAV = m.sfx_cache.get(key)
	if stream == null:
		var rate := 22050
		var n := int(rate * dur)
		var data := PackedByteArray()
		data.resize(n * 2)
		var phase := 0.0
		var lp := 0.0
		for i in n:
			var k := float(i) / n
			var f := freq * pow(maxf(30.0, freq + slide) / freq, k) if slide != 0.0 else freq
			phase += f / rate
			var x := fmod(phase, 1.0)
			var v: float
			match wave:
				"square": v = 1.0 if x < 0.5 else -1.0
				"sawtooth": v = x * 2.0 - 1.0
				"triangle": v = 1.0 - 4.0 * absf(x - 0.5)
				"step": # brushed grass: filtered noise that swells in, then fades
					lp = lerpf(lp, randf_range(-1.0, 1.0), 0.12)
					v = lp * 2.4 * minf(1.0, k * 6.0)
				"noise":
					lp = lerpf(lp, randf_range(-1.0, 1.0), 0.18) # one-pole low-pass takes the hiss off
					v = lp * 2.2 * (0.6 + 0.4 * sin(phase * TAU))
				_: v = sin(phase * TAU)
			v *= vol * pow(0.0001 if wave != "step" else 0.01, k) # exponential fade like the web version
			data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
		stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = data
		m.sfx_cache[key] = stream
	return stream

func footstep() -> void:
	if m.t - m.last_step < STEP_GAP:
		return
	m.last_step = m.t
	var v := m.rnd(0.045, 0.07)
	if m.tile_at(m.player.x, m.player.z) == Main.BRIDGE:
		sfx(m.rnd(130.0, 170.0), 0.05, "triangle", v * 1.6, -40.0)
	else:
		sfx(m.rnd(70.0, 120.0), 0.09, "step", v)
