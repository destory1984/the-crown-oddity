# Korean particles: "X을(를)", "X이(가)", "X은(는)", "X과(와)", "X으로(로)" in a finished sentence become the one that
# fits the last syllable of X (a final consonant or not). A number is read the Korean way: 5 (o) -> reeul, 10 (sip) -> eul.
# The tokens are written with escapes so this file adds no Korean text to the translation table.
extends RefCounted

# [with a final consonant, without, token written in the text]
const PAIRS := [
	["은", "는", "은(는)"],
	["이", "가", "이(가)"],
	["을", "를", "을(를)"],
	["과", "와", "과(와)"],
	["으로", "로", "으로(로)"],
]

# [has a final consonant, that consonant is rieul] for the last syllable of a word or the reading of a number
static func final_of(token: String) -> Array:
	if token.is_valid_int():
		var d := int(token.right(1))
		if d != 0:
			return [d in [1, 3, 6, 7, 8], d in [1, 7, 8]]
		var zeros := token.length() - token.rstrip("0").length()
		if zeros >= token.length():
			return [true, false] # 0 is "yeong", it ends in a consonant
		return [true, false] # sip, baek, cheon, man, eok: all end in a consonant that is not rieul
	var c := token.unicode_at(token.length() - 1)
	if c >= 0xAC00 and c <= 0xD7A3:
		var f := (c - 0xAC00) % 28
		return [f != 0, f == 8]
	return [false, false]

static func josa(s: String) -> String:
	if not (s.contains("(")):
		return s
	var out := s
	for p in PAIRS:
		var tok: String = p[2]
		var guard := 0
		while out.contains(tok) and guard < 32:
			guard += 1
			var at := out.find(tok)
			var j := at
			while j > 0 and out.unicode_at(j - 1) >= 48 and out.unicode_at(j - 1) <= 57:
				j -= 1
			var word := out.substr(j, at - j) if j < at else out.substr(maxi(at - 1, 0), 1)
			var fin := final_of(word) if word != "" else [false, false]
			var pick: String
			if p[2].begins_with("으"):
				pick = p[0] if (fin[0] and not fin[1]) else p[1]
			else:
				pick = p[0] if fin[0] else p[1]
			out = out.substr(0, at) + pick + out.substr(at + tok.length())
	return out

# Godot may break Korean between any two syllables, so wrapped help text split words ("dol|jin"), which read like
# stray line breaks (the owner, 2026-10-26). A word joiner (U+2060, drawn as nothing) between the letters of each
# word leaves the spaces as the only places a line can break.
static func keep_words(text: String) -> String:
	var out := ""
	for i in text.length():
		var c := text[i]
		out += c
		# not after a line's first letter: Godot dropped that letter when a joiner followed it ("금까지", the owner 2026-10-27)
		var first := i == 0 or text[i - 1] == "\n"
		if i + 1 < text.length() and not first and c != " " and c != "\n" and text[i + 1] != " " and text[i + 1] != "\n":
			out += char(0x2060)
	return out

# the text as written, without the joiners keep_words put in: for code that reads a shown line back
static func plain(text: String) -> String:
	return text.replace(char(0x2060), "")
