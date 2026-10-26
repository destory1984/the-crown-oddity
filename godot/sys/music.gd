# Background music: nine places, five looping tunes each, made by tools/bgm.py; two buses (Sfx, Music), a 1 s crossfade,
# the music switch. A place's tunes take turns: after ROTATE seconds the next of its five fades in.
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const TUNES := ["title", "field_marsh", "field_wild", "dungeon", "boss", "boss_final", "village", "night", "ending"]
const TUNE_NAMES := {"title": "제목", "field_marsh": "늪과 호수", "field_wild": "바람 부는 들", "dungeon": "동굴과 성", "boss": "우두머리",
	"boss_final": "마지막 싸움", "village": "마을", "night": "밤", "ending": "끝맺음"}
const MUSIC_DB := -14.0 # the Music bus under the effects (Master stays at 0 dB)
const OFF_DB := -80.0
const FADE := 1.0 # the crossfade between two tunes, and the fade of the music switch
const VARIANTS := 5 # <name>.ogg, <name>_2.ogg .. <name>_5.ogg (the owner, 2026-10-27: 5 per place)
const ROTATE := 100.0 # about two loops of a tune, then the place's next one

var players: Array = []
var cur := "" # the tune that is playing (or being faded in)
var cur_i := 0 # which of the two players has it
var turn := {} # place -> which of its five tunes plays next
var cur_file := "" # the file playing, e.g. "village_3"
var played := 0.0 # seconds the current file has played
var forced := "" # "다음 곡": stays until the area's own pick changes
var forced_from := ""
var pending := false # a "다음 곡" is waiting for its 0.35 s gap
var pick_t := 0.0
var warm := 0.0
var help_t := 0.0
var cache := {}
var bus_target := MUSIC_DB # where the Music bus is heading (autoplay reads it)
var sfx_target := 0.0

func _init(main: Main) -> void:
	m = main

# the two buses and the two players; called once from main._ready
func setup() -> void:
	for n in ["Sfx", "Music"]:
		if AudioServer.get_bus_index(n) < 0:
			AudioServer.add_bus(AudioServer.bus_count)
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")
	for k in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = OFF_DB
		m.add_child(p)
		players.append(p)

# let go of the streams when the game closes, so the engine does not report them as leaked
func shutdown() -> void:
	for p in players:
		(p as AudioStreamPlayer).stop()
		(p as AudioStreamPlayer).stream = null
	cache.clear()

# at once, after the settings are read (a fade would start from the wrong place)
func apply_buses_now() -> void:
	bus_target = MUSIC_DB if m.music_on else OFF_DB
	sfx_target = OFF_DB if m.muted else 0.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), bus_target)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), sfx_target)

func fade_bus(bus: String, to_db: float, dur: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	var tw := m.create_tween()
	tw.tween_method(func(v: float): AudioServer.set_bus_volume_db(i, v), AudioServer.get_bus_volume_db(i), to_db, dur)

# effects: the bus goes quiet in 0.05 s (sfx() also returns early while muted)
func sfx_switch() -> void:
	sfx_target = OFF_DB if m.muted else 0.0
	fade_bus("Sfx", sfx_target, 0.05)

func toggle_music() -> void:
	m.music_on = not m.music_on
	m.menus.save_settings()
	m.toast("배경 음악 켬" if m.music_on else "배경 음악 끔")
	bus_target = MUSIC_DB if m.music_on else OFF_DB
	fade_bus("Music", bus_target, FADE)
	m.menus.refresh_sound_btn()
	help_t = 0.0

# which tune the place calls for: the first line that holds wins
func pick() -> String:
	if m.intro:
		return "title"
	# the mold fight
	if m.in_garden and (m.garden_q == 2 or m.enemies.any(func(e): return e.get("mold", false) and not e.dead)):
		return "boss_final"
	# any other boss awake: the health bar is up (the Brick King, the turtle, the cart-mole, the knight, the oak duel, the hawk, Hangyeol's echo)
	if m.ui.boss.visible:
		return "boss"
	# the ending: the clock room once it is wound, the lantern festival, the ending story
	if (m.in_garden and m.garden_q >= 5) or m.festival_now() or m.ending_due:
		return "ending"
	var indoors: bool = m.in_cave or m.in_castle() or m.in_workshop() or m.in_house >= 0
	# each field keeps its own tune by night too (the owner, 2026-10-27: back from the village, the marsh tune again);
	# the night tune plays while Sora rests outdoors after dark
	if m.is_night() and not indoors and m.mates.sora_resting():
		return "night"
	if m.in_cave or m.in_castle() or m.in_workshop():
		return "dungeon"
	if m.in_village:
		return "village"
	if m.in_marsh() or m.in_lake or (m.in_hill and not m.in_castle()):
		return "field_marsh"
	return "field_wild"

func tune(name: String) -> AudioStream:
	if not cache.has(name):
		var s: AudioStream = load("res://audio/bgm/%s.ogg" % name)
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		cache[name] = s
	return cache[name]

# the next of the place's five files; the first visit starts at a random one
func file_for(name: String) -> String:
	var k: int = turn.get(name, randi() % VARIANTS)
	turn[name] = (k + 1) % VARIANTS
	return name if k == 0 else "%s_%d" % [name, k + 1]

# crossfade from the tune that is playing to `name` (not restarted when it already plays)
func play(name: String) -> void:
	if name == "" or (name == cur and played < ROTATE):
		return
	var old: AudioStreamPlayer = players[cur_i]
	cur_i = 1 - cur_i
	var nu: AudioStreamPlayer = players[cur_i]
	cur_file = file_for(name)
	nu.stream = tune(cur_file)
	played = 0.0
	nu.volume_db = -40.0
	nu.play()
	var tw := m.create_tween().set_parallel(true)
	tw.tween_property(nu, "volume_db", 0.0, FADE)
	if cur != "":
		tw.tween_property(old, "volume_db", -40.0, FADE)
		tw.chain().tween_callback(func(): if old != players[cur_i]: old.stop())
	cur = name

# "다음 곡": the tune drops in 0.12 s and the next of the nine starts 0.35 s later, until the area's pick changes
func next_tune() -> void:
	var idx := TUNES.find(cur)
	forced = TUNES[(idx + 1) % TUNES.size()]
	forced_from = pick()
	pending = true
	var old: AudioStreamPlayer = players[cur_i]
	var tw := m.create_tween()
	tw.tween_property(old, "volume_db", -40.0, 0.12)
	tw.tween_callback(old.stop)
	cur = ""
	m.get_tree().create_timer(0.35).timeout.connect(func():
		pending = false
		if forced != "":
			play(forced))
	help_t = 0.0

# every frame, before the world waits for a sheet or a story: the music keeps going
func update(dt: float) -> void:
	warm += dt
	played += dt
	if warm < 1.0:
		return # the first second is silent: a run that quits at once (the dev.py check) never leaves a stream in use
	pick_t -= dt
	if pick_t <= 0.0 and not pending:
		pick_t = 0.5
		var want := pick()
		if forced != "" and want != forced_from:
			forced = "" # the place changed: its own tune again
		play(forced if forced != "" else want)
	help_t -= dt
	if m.settings_open and help_t <= 0.0:
		help_t = 1.0
		refresh_help()

func tune_line() -> String:
	var name: String = cur if cur != "" else forced
	var line: String = "♪ " + tr(TUNE_NAMES.get(name, ""))
	if cur_file != "" and cur_file.begins_with(name) and name != "":
		var k := 1 if cur_file == name else int(cur_file.get_slice("_", cur_file.get_slice_count("_") - 1))
		line += " %d/%d  (%s)" % [k, VARIANTS, cur_file]
	if not m.music_on:
		line += " " + tr("(배경 음악이 꺼져 있습니다)")
	return line

func refresh_help() -> void:
	if not m.ui.has("music_rows"):
		return
	for r in m.ui.music_rows:
		(r[1] as Label).text = tune_line()
	if m.ui.has("now_tune") and (m.ui.now_tune as LineEdit).text != tune_line() and not (m.ui.now_tune as LineEdit).has_selection():
		(m.ui.now_tune as LineEdit).text = tune_line()
