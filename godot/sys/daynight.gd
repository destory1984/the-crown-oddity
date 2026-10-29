# Day and night: hour, moon phase, skipping time, sun and sky light.
# Moved out of main.gd; `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const KEY_HOURS := [ # a summer day: the sun sets late and rises early, so night runs only 21:00 - 04:00
	{"h": 0.0, "sun": "#6a7cc8", "si": 0.25, "amb": "#2a3460", "ai": 0.55, "fog": "#141a30", "el": 0.9, "night": 1.0, "beams": 0.0},
	{"h": 4.0, "sun": "#6a7cc8", "si": 0.25, "amb": "#2a3460", "ai": 0.55, "fog": "#141a30", "el": 0.1, "night": 1.0, "beams": 0.0},
	{"h": 5.5, "sun": "#ff9a6a", "si": 0.9, "amb": "#b08aa0", "ai": 0.8, "fog": "#d8a08a", "el": 0.2, "night": 0.4, "beams": 0.6},
	{"h": 8.0, "sun": "#fff0d0", "si": 1.5, "amb": "#e8eef8", "ai": 1.0, "fog": "#cfe0e8", "el": 0.7, "night": 0.0, "beams": 0.3},
	{"h": 13.0, "sun": "#fff4e0", "si": 1.7, "amb": "#eaf4ff", "ai": 1.05, "fog": "#cfe2ee", "el": 1.1, "night": 0.0, "beams": 0.2},
	{"h": 17.5, "sun": "#ffc06a", "si": 1.5, "amb": "#fff0d0", "ai": 0.95, "fog": "#e8c98a", "el": 0.55, "night": 0.1, "beams": 1.0},
	{"h": 19.5, "sun": "#ff7a4a", "si": 0.9, "amb": "#9a7aa8", "ai": 0.7, "fog": "#b07a80", "el": 0.2, "night": 0.6, "beams": 0.5},
	{"h": 21.0, "sun": "#6a7cc8", "si": 0.3, "amb": "#2a3460", "ai": 0.55, "fog": "#141a30", "el": 0.6, "night": 1.0, "beams": 0.0},
	{"h": 24.0, "sun": "#6a7cc8", "si": 0.25, "amb": "#2a3460", "ai": 0.55, "fog": "#141a30", "el": 0.9, "night": 1.0, "beams": 0.0},
]
const MOON_DAYS := 8

func _init(main: Main) -> void:
	m = main

# night for game rules (fireflies, moonflowers, crown costs, resting, the lantern night): 21:00 - 04:00
func is_night() -> bool:
	return m.hour >= 21.0 or m.hour < 4.0

# 0 = thin crescent .. 1 = full; waxing for the first half of the cycle
func moon_phase() -> Vector2:
	var p := float(m.day % MOON_DAYS) / MOON_DAYS
	return Vector2(0.15 + 0.85 * (1.0 - absf(2.0 * p - 1.0)), 1.0 if p < 0.5 else -1.0)

func skip_time(hours: float) -> void:
	if m.hour < 12.0 and m.hour + hours >= 12.0 or m.hour + hours >= 36.0:
		m.day += 1
	m.hour = fmod(m.hour + hours, 24.0)
	m.toast(tr("%02d시") % int(m.hour))

func update_daylight(dt: float) -> void:
	m.env.tonemap_exposure = 0.9
	if m.in_grotto() or m.in_corridor() or m.in_under() or m.in_clock() or m.in_workshop(): # underground: the same soft blue light at any hour, a lamp on Sora (the clock waits, as in the cave)
		m.sun.light_energy = 0.35
		m.env.ambient_light_color = Color("#9ab4d8")
		if m.in_workshop(): # the deep workshop: amber on B1, wet blue on B2, pale clay on B3
			m.env.ambient_light_color = Color(["#d8b890", "#9ab4d8", "#d8d0bc"][m.workshop_zone.floor_here()])
		if m.in_corridor(): # each corridor room its own tint (v0.1.84): slate, moss, brass, pale
			m.env.ambient_light_color = Color(Main.CORR.AMBIENT_COL[m.corridor.room_of(m.player.x)])
		m.env.ambient_light_energy = 1.4
		m.env.glow_intensity = 0.6
		m.env.glow_bloom = 0.05
		m.env.fog_light_color = Color("#0a1a2e")
		m.env.background_color = Color("#06101c")
		m.cave_light.light_energy = 2.4
		m.cave_light.position = Vector3(m.player.x, 1.8, m.player.z)
		m.motes.emitting = false
		m.motes.visible = false
		return
	if m.in_cave:
		m.sun.light_energy = 0.0
		m.env.ambient_light_color = Color("#4a6aa0")
		m.env.ambient_light_energy = 0.9
		m.env.glow_intensity = 0.6
		m.env.glow_bloom = 0.05
		m.env.fog_light_color = Color("#081426")
		m.env.background_color = Color("#050a14")
		m.cave_light.light_energy = 2.2
		m.cave_light.position = Vector3(m.player.x, 1.6, m.player.z)
		m.motes.emitting = false
		m.motes.visible = false
		return
	m.cave_light.light_energy = 0.0
	m.env.glow_intensity = 0.8
	m.env.glow_bloom = 0.05
	var before := m.hour
	m.hour = fmod(m.hour + dt / Main.DAY_SPEED, 24.0)
	if before < 12.0 and m.hour >= 12.0:
		m.day += 1
	var i := 0
	while KEY_HOURS[i + 1].h <= m.hour:
		i += 1
	var a: Dictionary = KEY_HOURS[i]
	var b: Dictionary = KEY_HOURS[i + 1]
	var k := smoothstep(0.0, 1.0, (m.hour - a.h) / (b.h - a.h))
	m.sun.light_color = Color(a.sun).lerp(Color(b.sun), k)
	m.night = lerpf(a.night, b.night, k)
	# night is brighter than it was (the user asked twice): more moonlight and about 3.8x the ambient at full night (asked three times)
	m.sun.light_energy = lerpf(a.si, b.si, k) * 1.1 * lerpf(1.0, 1.4 + 1.0 * moon_phase().x, m.night) # fuller moon, brighter night
	m.env.ambient_light_color = Color(a.amb).lerp(Color(b.amb), k)
	m.env.ambient_light_energy = lerpf(a.ai, b.ai, k) * 0.4 * lerpf(1.0, 3.8, m.night)
	m.env.tonemap_exposure = lerpf(0.9, 1.4, m.night) # and the eye opens up a little in the dark
	var fog := Color(a.fog).lerp(Color(b.fog), k)
	m.env.fog_light_color = fog
	m.env.background_color = fog
	m.sun_el = lerpf(a.el, b.el, k)
	m.night = lerpf(a.night, b.night, k)
	m.beams = lerpf(a.beams, b.beams, k)
	m.motes.emitting = m.night > 0.3 # fireflies only come out after dusk
	m.motes.visible = m.night > 0.3   # and vanish at once in daylight instead of lingering
