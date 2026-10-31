# A goal brings the village out: everyone awake on the street runs to the pitch, lines up along its edges, claps for
# 5 s and walks back to where they were (the owner, 2026-10-31: "골을 넣으면, 마을 사람들이 모두 달려와서 축구장 근처에
# 늘어서서 박수 5초간 쳐주고 다시 자기 자리로"). While someone is in `crowd`, folk.gd draws them here and their day stands still.
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const RUN := 3.6       # tiles a second to the pitch
const RUN_MAX := 6.0   # the far ones run faster, so the line is full by then
const WALK := 2.4      # tiles a second back
const WALK_MAX := 8.0
const CLAP_T := 5.0
const CLAP_H := 0.1    # the little bounce of each clap
const SIDE_ROWS := [22, 23, 24, 25, 26, 27, 21, 28] # rows along the side lines, the middle first
const SIDE_X := [16, 26]                            # columns just outside the side lines

var phase := ""        # "", run, clap, home
var clap_t := 0.0
var run_t := 0.0
var sound_t := 0.0
var crowd := {}        # id -> {pos, home, seat, way, i, speed, beat}
var seats: Array = []  # world x, z of the free tiles beside the pitch
var floods := {}       # seat index -> {tile: next tile towards that seat}
var claps := 0         # clap sounds played (autoplay goal_crowd)

func _init(main: Main) -> void:
	m = main

func vx() -> float:
	return float(Main.VILLAGE.VILLAGE_X)

func watching() -> bool:
	return m.in_village and m.in_house < 0

func ensure_seats() -> void:
	if not seats.is_empty():
		return
	for z in SIDE_ROWS:
		for x in SIDE_X:
			if not m.village.blocked(vx() + x, z):
				seats.append(Vector2(vx() + x, z))

func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(int(round(p.x - vx())), int(round(p.y)))

# found once per seat: the village's walls do not move
func flood(seat: int) -> Dictionary:
	if floods.has(seat):
		return floods[seat]
	var from := tile_of(seats[seat])
	var next := {from: from}
	var todo: Array = [from]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_front()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + dv
			if next.has(n) or n.x < 0 or n.y < 0 or n.x >= Main.VILLAGE.W or n.y >= Main.VILLAGE.H or m.village.blocked(vx() + n.x, n.y):
				continue
			next[n] = c
			todo.append(n)
	floods[seat] = next
	return next

# the tiles from beside `from` to the seat
func path(from: Vector2, seat: int) -> Array:
	var fl := flood(seat)
	var c := tile_of(from)
	if not fl.has(c):
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if fl.has(c + dv):
				c += dv
				break
	if not fl.has(c):
		return [seats[seat]]
	var out: Array = []
	while true:
		out.append(Vector2(vx() + c.x, c.y))
		if fl[c] == c:
			break
		c = fl[c]
	return out

func set_way(e: Dictionary, way: Array, speed: float, most: float) -> void:
	var n := 0.0
	var at: Vector2 = e.pos
	for w in way:
		n += at.distance_to(w)
		at = w
	e.way = way
	e.i = 0
	e.speed = maxf(speed, n / most)

# a second goal while they are out sends them back to the line and starts the 5 s again
func start() -> void:
	if m.routine_off or m.village == null or m.is_night() or not watching():
		return
	ensure_seats()
	for id in Main.SLEEP_IDS:
		if crowd.has(id) or not m.village.folk_node.has(id) or not m.folk_awake_here(id) or m.folk_state.get(id, "out") != "out":
			continue
		var home: Vector2 = m.folk.folk_talk_at(id)
		crowd[id] = {"pos": home, "home": home, "seat": -1, "way": [], "i": 0, "speed": RUN, "beat": randf() * TAU}
	var taken := {}
	for id in crowd:
		if crowd[id].seat >= 0:
			taken[crowd[id].seat] = true
	for id in crowd:
		var e: Dictionary = crowd[id]
		if e.seat < 0:
			var best := -1
			for i in seats.size():
				if not taken.has(i) and (best < 0 or e.pos.distance_to(seats[i]) < e.pos.distance_to(seats[best])):
					best = i
			if best < 0:
				continue
			e.seat = best
			taken[best] = true
		set_way(e, path(e.pos, e.seat), RUN, RUN_MAX)
	for id in crowd.keys():
		if crowd[id].seat < 0: # more people than free tiles: they stay at their work
			crowd.erase(id)
	if not crowd.is_empty():
		phase = "run"
		run_t = 0.0

func walk(e: Dictionary, id: String, dt: float) -> bool:
	var left: float = e.speed * dt
	while left > 0.0 and e.i < e.way.size():
		var to: Vector2 = e.way[e.i]
		var d: float = e.pos.distance_to(to)
		if d <= left:
			e.pos = to
			left -= d
			e.i += 1
		else:
			var dir: Vector2 = (to - e.pos) / d
			e.pos += dir * left
			left = 0.0
			(m.village.folk_node[id] as Sprite3D).flip_h = m.screen_left(dir)
	return e.i >= e.way.size()

func update(dt: float) -> void:
	if phase == "":
		return
	if not watching(): # nobody sees the walk back
		crowd.clear()
		phase = ""
		return
	match phase:
		"run":
			run_t += dt
			var all_there := true
			for id in crowd:
				all_there = walk(crowd[id], id, dt) and all_there
			if all_there or run_t > RUN_MAX + 1.0:
				phase = "clap"
				clap_t = CLAP_T
				sound_t = 0.0
				var mid := Vector2(vx() + 21.0, 24.6)
				for id in crowd:
					(m.village.folk_node[id] as Sprite3D).flip_h = m.screen_left(mid - crowd[id].pos)
		"clap":
			clap_t -= dt
			sound_t -= dt
			if sound_t <= 0.0:
				sound_t = randf_range(0.06, 0.14)
				claps += 1
				m.sfx(randf_range(1400.0, 2600.0), 0.04, "noise", 0.07)
				var e: Dictionary = crowd[crowd.keys().pick_random()]
				m.burst(Vector3(e.pos.x, 1.3, e.pos.y), Color("#ffe08a"), 3, 1.2)
			if clap_t <= 0.0:
				phase = "home"
				for id in crowd:
					var e: Dictionary = crowd[id]
					var way := path(e.home, e.seat)
					way.reverse()
					way.append(e.home)
					set_way(e, way, WALK, WALK_MAX)
		"home":
			var all_back := true
			for id in crowd:
				all_back = walk(crowd[id], id, dt) and all_back
			if all_back:
				crowd.clear()
				phase = ""

# how high this clap lifts them
func lift(id: String) -> float:
	if phase != "clap":
		return 0.0
	return absf(sin(clap_t * 9.0 + crowd[id].beat)) * CLAP_H

# a scene shot: everyone already in line
func line_up() -> void:
	start()
	for id in crowd:
		crowd[id].pos = crowd[id].way.back()
		crowd[id].i = crowd[id].way.size()
