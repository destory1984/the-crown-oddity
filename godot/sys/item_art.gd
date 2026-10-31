# A picture of what Sora just got (the owner, 2026-10-31: "이럴 때에도 진주 사진이 그려져야지", then "24가지 모두 넣어라").
# A talk that hands an item over shows it from the line in AT_LINE to the end of the talk, a fight that drops one calls pop(),
# and the bag uses the same pictures. The talks' lines stay as they are: they are only looked up here.
# `m` is the main node (main.gd), its state and helpers are reached as m.x.
extends RefCounted

const Main := preload("res://main.gd")

var m: Main

const SIZE := 208.0     # the card, a side
const PIC := 168.0      # the picture in it
const Y := -318.0       # the card's top from the screen's middle, clear of the story box and the toast
const POP_T := 2.6      # how long pop() leaves it up

const ART := ["firefly", "pearl", "feather", "acorn", "sprout", "lantern13", "ring", "shoes",
	"oar_ring", "whistle", "knot", "dial", "oil", "bori_lamp", "cushion", "bait",
	"cog", "buckler", "postcard", "armour", "tea", "cloud", "bookmark", "lamp", "medal"]

# the line of a talk that shows the item (the sentence, without "who|face|")
const AT_LINE := {
	"병 속에서 반딧불 다섯 마리가 천천히 돌며 빛났다. 꼬마 고블린이 작은 벽돌 손으로 손뼉을 쳤다.": "firefly",
	"상자 안에 푸르게 빛나는 진주가 하나 들어 있다. 손에 쥐자 숨이 고르게 가라앉았다.": "pearl",
	"허수아비가 무너지자, 벽돌 속에서 하얀 깃털 하나가 바람을 타고 내려왔다.": "feather",
	"가장 큰 다람쥐가 소라의 발치에 반짝이는 도토리 하나를 내려놓았다.": "acorn",
	"봐, 주머니 속 도토리에 싹이 났어!": "sprout",
	"작은 나무굴. 이끼 위에 굳은 등불 하나와 접힌 편지가 놓여 있다.": "lantern13",
	"상자 안에는 푸른 수정이 박힌 작은 반지가 들어 있다. 끼자 손끝에서 맑은 소리가 났다.": "ring",
	"바람 신발을 얻었다. 달릴 때 빠르기가 6.2에서 7.0으로 오른다.": "shoes",
	"방앗간지기의 궤짝. 낡은 삿대 고리와 약병 하나가 들어 있다.": "oar_ring",
	"열쇠 기둥에 묶인 작은 깡통. 일지 마지막 장과 낡은 호루라기가 들어 있다.": "whistle",
	"열쇠 북쪽의 작은 궤짝. 감는 날 쓰던 기름병과 금화가 들어 있다.": "oil",
	"할머니는 선반 맨 위에서 먼지 앉은 등불 하나를 내렸다. 한 번도 켠 적 없는 등불이다.": "bori_lamp",
	"할머니는 남은 갈대로 작은 방석을 엮어 건넸다.": "cushion",
	"미끼 주머니를 얻었다. 물고기가 30% 더 빨리 문다.": "bait",
	"기사가 무릎 꿇었던 자리에 녹슨 태엽 하나가 남아 있다. 손바닥만 하다.": "cog",
	"문지기가 제 의자로 가 앉더니, 팔에 달린 작은 놋 방패를 떼어 소라에게 내밀었다.": "buckler",
	"물길 끝 마른 바닥에 쓸려 온 물건이 쌓여 있다. 맨 위에 젖었다 마른 엽서 한 장.": "postcard",
	"보물고 깊은 곳의 상자 안에 달빛처럼 은은한 가벼운 갑옷이 접혀 있다.": "armour",
	"할머니는 달꽃을 주전자에 띄우고 오래 우렸다. 은은한 단내가 오두막에 퍼졌다.": "tea",
	"작은 섬의 상자 안에 구름이 굳어 생긴 듯한 하얀 조각이 들어 있다. 쥐자 바람이 손끝을 맴돌았다.": "cloud",
	"다섯 권을 다 읽자, 마지막 책 사이에서 달 모양 책갈피 하나가 미끄러져 나왔다.": "bookmark",
	"상자 안에는 작은 놋쇠 등잔이 들어 있다. 기름도 없는데 희미하게 따뜻하다.": "lamp",
	"과녁 기둥에 매달린 작은 종이 딸랑 울렸다. 기둥 밑 상자에서 놋쇠 메달이 굴러 나온다.": "medal",
}

var card: PanelContainer
var pic: TextureRect
var tw: Tween
var shown := ""        # the item on the card, "" when it is hidden

func _init(main: Main) -> void:
	m = main

static func path(id: String) -> String:
	return "res://art/items/%s.png" % id

func ensure_card() -> void:
	if card != null:
		return
	card = PanelContainer.new()
	card.custom_minimum_size = Vector2(SIZE, SIZE)
	card.size = Vector2(SIZE, SIZE)
	card.pivot_offset = Vector2(SIZE, SIZE) / 2.0
	card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -SIZE / 2.0
	card.offset_right = SIZE / 2.0
	card.offset_top = Y
	card.offset_bottom = Y + SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", m.menus.flat(Color("#0d1a3ae6"), Color("#f6b951"), 2, 14, 14.0))
	card.visible = false
	var parent: Node = m.ui.story.get_parent()
	parent.add_child(card)
	pic = TextureRect.new()
	pic.custom_minimum_size = Vector2(PIC, PIC)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pic)

func show_item(id: String) -> void:
	ensure_card()
	if tw != null and tw.is_valid():
		tw.kill()
	shown = id
	pic.texture = load(path(id))
	card.get_parent().move_child(card, -1)
	card.visible = true
	card.modulate.a = 0.0
	card.scale = Vector2.ONE * 0.7
	tw = card.create_tween().set_parallel()
	tw.tween_property(card, "modulate:a", 1.0, 0.18)
	tw.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_item() -> void:
	if shown == "":
		return
	if tw != null and tw.is_valid():
		tw.kill()
	shown = ""
	card.visible = false

# a line of a talk was shown
func on_line(text: String) -> void:
	if AT_LINE.has(text):
		show_item(AT_LINE[text])

# no talk comes with this one: the card stays up a moment, the game runs on
func pop(id: String) -> void:
	show_item(id)
	tw.chain().tween_interval(POP_T)
	tw.chain().tween_property(card, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(hide_item)
