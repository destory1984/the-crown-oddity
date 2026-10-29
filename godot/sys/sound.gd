# Sound: sfx() synthesises every effect in code, footsteps.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const SFX_LOG_MAX := 200
const STEP_GAP := 0.42  # at most ~2.4 steps a second, even when running

func _init(main: Main) -> void:
	m = main

func sfx(freq: float, dur := 0.1, wave := "square", vol := 0.25, slide := 0.0) -> void:
	m.sfx_log.append("%s:%d" % [wave, int(freq)])
	if m.sfx_log.size() > SFX_LOG_MAX: # only the recent ones are read, and the babble adds ~20 a second
		m.sfx_log.pop_front()
	if m.muted:
		return
	var pl := AudioStreamPlayer.new()
	pl.stream = sfx_stream(freq, dur, wave, vol, slide)
	pl.bus = "Sfx"
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
				"splash": # water slapping: a bright hiss that dies fast over a falling bloop (the fountain struck)
					lp = lerpf(lp, randf_range(-1.0, 1.0), 0.55)
					v = lp * 1.8 * pow(1.0 - k, 3.0) + 0.6 * sin(phase * TAU) * minf(1.0, k * 20.0)
				"babble": # a spoken syllable: a round tone with its octave, quick in, quick out
					v = (sin(phase * TAU) + 0.35 * sin(phase * TAU * 2.0)) * minf(1.0, k * 12.0)
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

# a voice under the typing, a blip for every other Hangul syllable, pitched by who speaks and by the syllable's vowel
# (the owner, 2026-10-29: "자막이 흐를 때에 동숲처럼 말소리 비슷한게 나오게"); narration stays quiet
const VOICE := {"소라": 640.0, "콩알": 720.0, "토리": 700.0, "여울": 560.0, "다래": 420.0, "심지": 520.0, "물결": 430.0,
	"노을": 330.0, "도란": 300.0, "두솔": 280.0, "차돌": 260.0, "새참": 380.0, "보리": 400.0, "한결": 300.0}
# semitones by vowel (jungseong order ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ): open vowels low, ㅣ ㅔ high
const VOWEL_STEP := [0, 3, 2, 4, -1, 4, 1, 4, -3, 0, 2, 2, -2, -4, -2, 2, 3, -3, -1, 4, 6]
var babble_n := 0

func babble(from: int, to: int) -> void:
	var who: String = m.ui.story_who.text
	if who == "" or to <= from or not bool(m.cfg.get("voice", true)):
		return
	var base: float = VOICE.get(who.get_slice(" ", 0), 480.0)
	var text: String = m.ui.story_text.text
	for i in range(maxi(from, 0), mini(to, text.length())):
		var c := text.unicode_at(i)
		if c < 0xAC00 or c > 0xD7A3:
			continue
		babble_n += 1
		if babble_n % 2 == 0:
			continue
		var step: int = VOWEL_STEP[((c - 0xAC00) / 28) % 21] + randi_range(-1, 1)
		sfx(snappedf(base * pow(2.0, step / 12.0), 1.0), 0.055, "babble", 0.09)

func footstep() -> void:
	if m.t - m.last_step < STEP_GAP:
		return
	m.last_step = m.t
	var v := m.rnd(0.045, 0.07)
	if m.tile_at(m.player.x, m.player.z) == Main.BRIDGE:
		sfx(m.rnd(130.0, 170.0), 0.05, "triangle", v * 1.6, -40.0)
	else:
		sfx(m.rnd(70.0, 120.0), 0.09, "step", v)
