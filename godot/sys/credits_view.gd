# The ending credits (the owner, 2026-10-29: "여기에서 다음을 누르면.. 엔딩 크레딧이 올라가도록 하자. 엔딩 크레딧은
# 적당히 써봐"): after the ending's last line a dark screen rolls the names up from the bottom at SPEED px a second
# over the ending tune. A key or a click after SKIP_AFTER seconds ends it at once; either way `then` runs.
# Built and started by garden_zone.roll_credits(); the world waits while it rolls (story_open stays true).
extends ColorRect

const SPEED := 55.0
const SKIP_AFTER := 1.5
const GOLD := Color("#f6d27a")
const INK := Color("#eef3ff")
const DIM := Color("#9fb0c8")

# [heading, lines...]: one block per role, a blank gap between blocks
const CREDITS := [
	["The Crown Oddity", "백 년의 정원이 당신을 기다린다"],
	["만든 사람", "우주 한량", "우주 토끼", "구스테 단톡방 사람들"],
	["등장인물", "소라 — 왕관을 쓰고 깨어난 아이", "노을 — 등불을 끄던 맞수, 손을 받쳐 준 동무", "물결 — 호수의 뱃사공",
		"보리 할머니 — 갈대늪 오두막", "도란 — 마을 우편배달부", "콩알 — 빵집 꼬마", "심지 — 등불지기", "한결 — 마지막 달지기"],
	["마을 사람들", "두솔, 차돌, 새참, 여울, 다래, 토리", "그리고 장난감처럼 하품하는 벽돌 고블린들"],
	["이야기와 설계", "우주 한량과 함께 GPT(OpenAI)와 상의해 지었다", "영웅의 여정 12단계를 뼈대로 삼았다"],
	["그림", "이야기 삽화, 초상, 걷기 그림: GPT 이미지 생성", "소라의 몸짓: Space Oddity에서 데려왔다", "땅과 집과 괴물: 코드로 쌓은 상자"],
	["코드", "Claude (Anthropic)", "엔진: Godot 4.7"],
	["음악과 소리", "곡과 효과음 모두 코드로 지었다 (tools/bgm.py)"],
	["글꼴", "Pretendard, Jua — SIL 오픈 폰트 라이선스 1.1"],
	["시험해 준 사람들", "Google Play 비공개 테스트에 함께해 준 분들", "GPT의 놀이 점검 수십 바퀴"],
	["고마운 사람", "끝까지 함께 태엽을 감아 준 당신"],
	["", "여덟 밤마다, 다시 만나요."],
]

var then: Callable
var col: VBoxContainer
var started := 0.0
var done := false

func _init(font: Font, after: Callable) -> void:
	then = after
	color = Color(0.02, 0.03, 0.07, 0.94)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	for block in CREDITS:
		for i in block.size():
			var l := Label.new()
			l.text = block[i]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.add_theme_font_override("font", font)
			var head: bool = i == 0
			var title: bool = block[0] == "The Crown Oddity"
			l.add_theme_font_size_override("font_size", 40 if title and head else (22 if head else 19))
			l.add_theme_color_override("font_color", GOLD if head else (INK if not title else DIM))
			l.add_theme_constant_override("outline_size", 4)
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
			col.add_child(l)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 46)
		col.add_child(gap)

func _ready() -> void:
	started = Time.get_ticks_msec() / 1000.0
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
	await get_tree().process_frame
	var vw := get_viewport_rect().size
	col.size.x = vw.x
	col.position = Vector2(0, vw.y)
	var h: float = col.get_combined_minimum_size().y
	var tw := create_tween()
	tw.tween_property(col, "position:y", -h, (vw.y + h) / SPEED)
	tw.tween_callback(finish)

# a key or a click (not mouse moves) after the first moments skips to the end
func _input(e: InputEvent) -> void:
	if done:
		return
	var press: bool = (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)
	if not press:
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() / 1000.0 - started >= SKIP_AFTER:
		finish()

func finish() -> void:
	if done:
		return
	done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		then.call()
		queue_free())
