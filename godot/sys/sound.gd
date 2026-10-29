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

# a raindrop landing: a soft low plip on bare ground, a bright two-note tink in the tin pail (delight idea 34)
func rain_drip(tin: bool) -> void:
	if tin:
		sfx(1568, 0.07, "triangle", 0.06)
		m.get_tree().create_timer(0.04).timeout.connect(func(): sfx(2093, 0.09, "triangle", 0.04))
	else:
		sfx(170, 0.08, "sine", 0.08, -50.0)

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
			if wave == "babble_old": # an old voice wavers: 5.5 Hz, 4% either way
				f *= 1.0 + 0.04 * sin(TAU * 5.5 * i / rate)
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
				"babble_deep", "babble_old": # a grown man's or an old voice: more 2nd and 3rd harmonics, so a low pitch still carries
					v = (sin(phase * TAU) + 0.6 * sin(phase * TAU * 2.0) + 0.35 * sin(phase * TAU * 3.0)) * 0.7 * minf(1.0, k * (8.0 if wave == "babble_old" else 12.0))
					if wave == "babble_old": # and a little breath
						lp = lerpf(lp, randf_range(-1.0, 1.0), 0.3)
						v += lp * 0.12
				"noise":
					lp = lerpf(lp, randf_range(-1.0, 1.0), 0.18) # one-pole low-pass takes the hiss off
					v = lp * 2.2 * (0.6 + 0.4 * sin(phase * TAU))
				_: v = sin(phase * TAU)
			v *= vol * pow(0.0001 if not (wave == "step" or wave.begins_with("babble")) else (0.01 if wave == "step" else 0.08), k) # exponential fade like the web version; a syllable keeps its body
			data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
		stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = data
		m.sfx_cache[key] = stream
	return stream

# a voice under the typing, a blip for every other Hangul syllable, pitched by who speaks and by the syllable's vowel
# (the owner, 2026-10-29: "자막이 흐를 때에 동숲처럼 말소리 비슷한게 나오게"); narration stays quiet
# each voice: [pitch Hz, syllable s, timbre, a blip every n syllables] (the owner, 2026-10-29: "사람마다 목소리 톤이 좀
# 달라야지.. 심지 할아버지는 나이도 많고 & 남자이니까 약간 저음으로"): kids high and quick, grown men low and chesty,
# the old ones low, wavering and slower
const VOICE := {"소라": [640.0, 0.08, "babble", 2], "콩알": [720.0, 0.07, "babble", 2], "토리": [700.0, 0.07, "babble", 2],
	"노을": [330.0, 0.08, "babble", 2], "여울": [560.0, 0.08, "babble", 2], "물결": [430.0, 0.08, "babble", 2],
	"새참": [380.0, 0.09, "babble", 2], "도란": [300.0, 0.09, "babble", 2], "차돌": [260.0, 0.09, "babble_deep", 2],
	"두솔": [190.0, 0.10, "babble_deep", 2], "한결": [300.0, 0.09, "babble", 2],
	"심지": [150.0, 0.12, "babble_old", 3], "보리": [330.0, 0.11, "babble_old", 3], "다래": [350.0, 0.11, "babble_old", 3]}
const VOICE_ANY := [480.0, 0.08, "babble", 2]
# semitones by vowel (jungseong order ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ): open vowels low, ㅣ ㅔ high
const VOWEL_STEP := [0, 3, 2, 4, -1, 4, 1, 4, -3, 0, 2, 2, -2, -4, -2, 2, 3, -3, -1, 4, 6]
var babble_n := 0

func babble(from: int, to: int) -> void:
	var who: String = m.ui.story_who.text
	if who == "" or to <= from or not bool(m.cfg.get("voice", true)):
		return
	var voice: Array = VOICE.get(who.get_slice(" ", 0), VOICE_ANY)
	var text: String = m.ui.story_text.text
	for i in range(maxi(from, 0), mini(to, text.length())):
		var c := text.unicode_at(i)
		if c < 0xAC00 or c > 0xD7A3:
			continue
		babble_n += 1
		if babble_n % int(voice[3]) != 1 % int(voice[3]):
			continue
		var step: int = VOWEL_STEP[((c - 0xAC00) / 28) % 21] + randi_range(-1, 1)
		sfx(snappedf(float(voice[0]) * pow(2.0, step / 12.0), 1.0), float(voice[1]), String(voice[2]), 0.32 if voice[2] == "babble" else 0.36) # 0.09 for 0.055 s was lost under the music (the owner, 2026-10-29: "소리가 너무 작아")

func footstep() -> void:
	if m.t - m.last_step < STEP_GAP:
		return
	m.last_step = m.t
	var v := m.rnd(0.045, 0.07)
	if m.tile_at(m.player.x, m.player.z) == Main.BRIDGE:
		sfx(m.rnd(130.0, 170.0), 0.05, "triangle", v * 1.6, -40.0)
	else:
		sfx(m.rnd(70.0, 120.0), 0.09, "step", v)
