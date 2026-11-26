class_name HudItemIcon
extends RefCounted
## Eşyanın simgesi (Envanter ve aktarma paneli): satırın atlas simgesi (items.json icon; assets/ui/hud/) varsa o, yoksa kitabın
## sekme işaretleri gibi çizgiyle çizilen bir işaret (koyu dolgu, krem çizgi, altın vurgu). İşaret satırdan seçilir: yuva, araç türü,
## etiket, kademe (glyph_of). Boş kuşam yuvasının soluk işareti de buradadır (draw_slot). Görsel üretimi gelince atlas simgesi
## kendiliğinden öne geçer (yalnız items.json'a icon yazılır).

const INK := Color(0.05, 0.05, 0.07, 0.9)
const LINE := Color("#efe2c4")
const ACCENT := Color("#d9b56c")


## Simgeyi kutuya sığdırır (box: kutunun kenarı, px).
static func draw(ci: CanvasItem, item_id: String, center: Vector2, box: float, modulate := Color.WHITE) -> void:
	var icon := ItemCatalog.icon_of(item_id)
	if not icon.is_empty() and HudKit.tex(icon):
		HudKit.draw_icon(ci, icon, center, box, modulate)
		return
	draw_glyph(ci, glyph_of(item_id), center, box * 0.5, modulate, false, int(ItemCatalog.row(item_id).get("notches", TALLY_NOTCHES)))


## Boş kuşam yuvasının soluk işareti (yuvanın eşyası gibi; atlas simgesi varsa o).
static func draw_slot(ci: CanvasItem, slot: String, center: Vector2, box: float, modulate: Color) -> void:
	var atlas := {"bow": "icon_bow", "blade": "icon_sword", "feet": "icon_boot", "belt": "icon_bag"}
	if atlas.has(slot) and HudKit.tex(str(atlas[slot])):
		HudKit.draw_icon(ci, str(atlas[slot]), center, box, modulate)
		return
	draw_glyph(ci, SLOT_GLYPHS.get(slot, "pouch"), center, box * 0.5, modulate, true)


const SLOT_GLYPHS := {"head": "cap", "neck": "pendant", "body": "coat", "cape": "cape", "hands": "glove", "belt": "belt", "feet": "boot",
	"blade": "sword", "bow": "bow", "quiver": "quiver", "saddle": "saddle", "bridle": "bridle", "hoof": "hoof", "blanket": "blanket"}
const TOOL_GLYPHS := {"axe": "axe", "pick": "pick", "net": "net", "fire": "flint", "sling": "sling", "sled": "sled", "site": "wedge"}
## Etiketi olmayan (ya da etiketi yanıltan) eşyanın işareti.
const ID_GLYPHS := {"rope": "rope", "felt": "felt", "felt_white": "felt", "leather": "felt", "hide_small": "pelt", "sinew": "cord",
	"snare": "cord", "bandage": "cord", "halter": "cord", "bone": "bone", "horn": "horn", "antler": "horn", "fat": "drop", "lamp_oil": "drop",
	"glue": "pot", "dye": "pot", "dye_blue": "pot", "pot": "pot", "cauldron": "pot", "ember_pot": "pot", "torch": "torch", "pole": "shaft",
	"iron_pin": "ingot", "copper_bit": "ingot", "bark_willow": "leaf", "mushroom": "leaf", "salt": "block", "spoiled": "meat",
	"burnt": "bowl", "chiy": "sheaf", "kerege_set": "parts", "uuk_set": "shaft", "yurt_crown": "pendant", "crown_great": "pendant",
	"qurt_gift": "pouch"}
## Çetelenin çentikleri (satırın notches'ı yoksa; Hereka'nın çetelesi yedi).
const TALLY_NOTCHES := 5


## Eşyanın işareti: yuva, araç, etiket ve kademe sırasıyla.
static func glyph_of(item_id: String) -> String:
	var by_id: Variant = ID_GLYPHS.get(ItemCatalog.base_id(item_id))
	if by_id != null:
		return str(by_id)
	var slot := ItemCatalog.slot_of(item_id)
	if not slot.is_empty():
		return str(SLOT_GLYPHS.get(slot, "pouch"))
	var t := ItemCatalog.tool_of(item_id)
	if not t.is_empty():
		return str(TOOL_GLYPHS.get(str(t.get("kind", "")), "axe"))
	var tags := ItemCatalog.tags(item_id)
	for pair: Array in [["key", "tally"], ["game", "bird"], ["wood", "log"], ["ore", "ore"], ["metal", "ingot"], ["arrow", "arrow"],
			["head", "arrowhead"], ["shaft", "shaft"], ["fletch", "feather"], ["fur", "pelt"], ["hide", "pelt"], ["meat", "meat"],
			["grain", "sack"], ["berry", "berries"], ["herb", "leaf"], ["food", "bowl"], ["fiber", "skein"], ["forage", "sheaf"],
			["gem", "gem"], ["valuable", "gem"], ["scrap", "ingot"], ["fuel", "twigs"], ["tinder", "twigs"], ["bulk", "block"]]:
		if tags.has(pair[0]):
			return str(pair[1])
	match ItemCatalog.tier(item_id):
		"bundle":
			return "bundle"
		"part":
			return "parts"
	return "pouch"


## Çizgiyle işaret (s: yarı boy). faint: boş yuvanın soluk işareti (dolgusuz, tek renk). notches: çetelenin çentikleri.
static func draw_glyph(ci: CanvasItem, kind: String, c: Vector2, s: float, modulate := Color.WHITE, faint := false, notches := TALLY_NOTCHES) -> void:
	var line := Color(LINE, LINE.a * modulate.a) * Color(modulate.r, modulate.g, modulate.b, 1.0)
	var acc := Color(ACCENT, ACCENT.a * modulate.a) * Color(modulate.r, modulate.g, modulate.b, 1.0)
	var fill := Color(INK, INK.a * modulate.a)
	if faint:
		line = modulate
		acc = modulate
		fill = Color(0, 0, 0, 0)
	var w := maxf(1.4, s * 0.075)
	match kind:
		"log":
			_poly(ci, [c + Vector2(-s * 0.85, -s * 0.2), c + Vector2(s * 0.55, -s * 0.2), c + Vector2(s * 0.55, s * 0.32), c + Vector2(-s * 0.85, s * 0.32)], fill, line, w)
			ci.draw_arc(c + Vector2(s * 0.55, s * 0.06), s * 0.3, 0, TAU, 20, line, w, true)
			ci.draw_arc(c + Vector2(s * 0.55, s * 0.06), s * 0.13, 0, TAU, 14, acc, w * 0.8, true)
			ci.draw_line(c + Vector2(-s * 0.6, -s * 0.02), c + Vector2(s * 0.1, -s * 0.02), Color(line, line.a * 0.5), w * 0.7)
		"block":
			_poly(ci, [c + Vector2(-s * 0.7, -s * 0.2), c + Vector2(-s * 0.2, -s * 0.55), c + Vector2(s * 0.7, -s * 0.4), c + Vector2(s * 0.75, s * 0.35),
				c + Vector2(s * 0.1, s * 0.6), c + Vector2(-s * 0.75, s * 0.4)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.2, -s * 0.55), c + Vector2(-s * 0.05, s * 0.0), Color(line, line.a * 0.55), w * 0.8)
			ci.draw_line(c + Vector2(-s * 0.05, s * 0.0), c + Vector2(s * 0.75, s * 0.35), Color(line, line.a * 0.55), w * 0.8)
		"ore":
			_poly(ci, [c + Vector2(-s * 0.75, s * 0.1), c + Vector2(-s * 0.3, -s * 0.55), c + Vector2(s * 0.45, -s * 0.5), c + Vector2(s * 0.75, s * 0.15),
				c + Vector2(s * 0.2, s * 0.6), c + Vector2(-s * 0.45, s * 0.5)], fill, line, w)
			for p: Vector2 in [Vector2(-0.2, -0.15), Vector2(0.25, 0.05), Vector2(-0.05, 0.3)]:
				ci.draw_circle(c + p * s, s * 0.09, acc)
		"ingot":
			_poly(ci, [c + Vector2(-s * 0.8, s * 0.35), c + Vector2(-s * 0.5, -s * 0.25), c + Vector2(s * 0.5, -s * 0.25), c + Vector2(s * 0.8, s * 0.35)], fill, acc, w)
			ci.draw_line(c + Vector2(-s * 0.45, -s * 0.05), c + Vector2(s * 0.45, -s * 0.05), Color(acc, acc.a * 0.5), w * 0.7)
		"arrow":
			ci.draw_line(c + Vector2(-s * 0.75, s * 0.75), c + Vector2(s * 0.6, -s * 0.6), line, w)
			_poly(ci, [c + Vector2(s * 0.8, -s * 0.8), c + Vector2(s * 0.42, -s * 0.62), c + Vector2(s * 0.62, -s * 0.42)], acc, acc, w)
			for k in 3:
				var b := c + Vector2(-s * 0.75, s * 0.75) + Vector2(s * 0.14, -s * 0.14) * k
				ci.draw_line(b, b + Vector2(-s * 0.18, -s * 0.02), line, w * 0.8)
				ci.draw_line(b, b + Vector2(s * 0.02, s * 0.18), line, w * 0.8)
		"arrowhead":
			_poly(ci, [c + Vector2(0, -s * 0.75), c + Vector2(s * 0.4, s * 0.25), c + Vector2(0, s * 0.05), c + Vector2(-s * 0.4, s * 0.25)], fill, acc, w)
			ci.draw_line(c + Vector2(0, s * 0.05), c + Vector2(0, s * 0.75), line, w)
		"shaft":
			for k in 3:
				var o := Vector2(s * (k - 1) * 0.28, 0)
				ci.draw_line(c + o + Vector2(-s * 0.3, s * 0.75), c + o + Vector2(s * 0.3, -s * 0.75), line, w)
		"feather":
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.75), c + Vector2(s * 0.55, -s * 0.7), line, w)
			_poly(ci, [c + Vector2(s * 0.55, -s * 0.7), c + Vector2(s * 0.1, -s * 0.45), c + Vector2(-s * 0.35, s * 0.35), c + Vector2(0.0, s * 0.1)], fill, acc, w)
		"pelt":
			_poly(ci, [c + Vector2(-s * 0.35, -s * 0.7), c + Vector2(s * 0.35, -s * 0.7), c + Vector2(s * 0.8, -s * 0.3), c + Vector2(s * 0.45, s * 0.1),
				c + Vector2(s * 0.7, s * 0.7), c + Vector2(-s * 0.7, s * 0.7), c + Vector2(-s * 0.45, s * 0.1), c + Vector2(-s * 0.8, -s * 0.3)], fill, line, w)
			ci.draw_line(c + Vector2(0, -s * 0.5), c + Vector2(0, s * 0.5), Color(acc, acc.a * 0.6), w * 0.7)
		"meat":
			_poly(ci, [c + Vector2(-s * 0.75, s * 0.15), c + Vector2(-s * 0.55, -s * 0.35), c + Vector2(-s * 0.1, -s * 0.5), c + Vector2(s * 0.25, -s * 0.3),
				c + Vector2(s * 0.3, s * 0.05), c + Vector2(-s * 0.05, s * 0.45), c + Vector2(-s * 0.5, s * 0.5)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.05), c + Vector2(-s * 0.05, -s * 0.2), Color(acc, acc.a * 0.7), w * 0.8)
			ci.draw_line(c + Vector2(s * 0.25, -s * 0.05), c + Vector2(s * 0.62, s * 0.42), line, w * 1.4)
			ci.draw_circle(c + Vector2(s * 0.66, s * 0.36), s * 0.1, line)
			ci.draw_circle(c + Vector2(s * 0.56, s * 0.48), s * 0.1, line)
		"sack":
			_poly(ci, [c + Vector2(-s * 0.35, -s * 0.45), c + Vector2(s * 0.35, -s * 0.45), c + Vector2(s * 0.65, s * 0.25), c + Vector2(s * 0.4, s * 0.72),
				c + Vector2(-s * 0.4, s * 0.72), c + Vector2(-s * 0.65, s * 0.25)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.4, -s * 0.45), c + Vector2(s * 0.4, -s * 0.45), acc, w * 1.2)
			ci.draw_line(c + Vector2(-s * 0.15, -s * 0.45), c + Vector2(-s * 0.3, -s * 0.78), line, w)
			ci.draw_line(c + Vector2(s * 0.15, -s * 0.45), c + Vector2(s * 0.3, -s * 0.78), line, w)
		"bowl":
			ci.draw_arc(c + Vector2(0, -s * 0.1), s * 0.72, 0.0, PI, 20, line, w, true)
			ci.draw_line(c + Vector2(-s * 0.72, -s * 0.1), c + Vector2(s * 0.72, -s * 0.1), line, w)
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.68), c + Vector2(s * 0.3, s * 0.68), line, w)
			for k in 3:
				var x := s * (k - 1) * 0.3
				ci.draw_arc(c + Vector2(x, -s * 0.45), s * 0.12, PI * 0.5, PI * 1.5, 6, Color(acc, acc.a * 0.8), w * 0.7, true)
		"leaf":
			_poly(ci, [c + Vector2(-s * 0.6, s * 0.65), c + Vector2(-s * 0.45, -s * 0.2), c + Vector2(s * 0.1, -s * 0.7), c + Vector2(s * 0.65, -s * 0.65),
				c + Vector2(s * 0.5, 0.0), c + Vector2(0.0, s * 0.45)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.65), c + Vector2(s * 0.5, -s * 0.5), acc, w * 0.8)
		"berries":
			for p: Vector2 in [Vector2(-0.3, 0.2), Vector2(0.25, 0.25), Vector2(0.0, -0.2), Vector2(0.45, -0.25)]:
				ci.draw_circle(c + p * s, s * 0.24, fill)
				ci.draw_arc(c + p * s, s * 0.24, 0, TAU, 14, acc, w, true)
			ci.draw_line(c + Vector2(0.0, -s * 0.44), c + Vector2(-s * 0.2, -s * 0.8), line, w)
		"skein":
			for k in 3:
				ci.draw_arc(c, s * (0.3 + k * 0.2), PI * 0.1, PI * 1.9, 18, line if k != 1 else acc, w, true)
		"sheaf":
			for k in 5:
				var x := s * (k - 2) * 0.18
				ci.draw_line(c + Vector2(x * 0.4, s * 0.75), c + Vector2(x * 1.6, -s * 0.75), line, w)
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.15), c + Vector2(s * 0.3, s * 0.15), acc, w * 1.4)
		"gem":
			_poly(ci, [c + Vector2(-s * 0.6, -s * 0.15), c + Vector2(-s * 0.3, -s * 0.55), c + Vector2(s * 0.3, -s * 0.55), c + Vector2(s * 0.6, -s * 0.15),
				c + Vector2(0, s * 0.7)], fill, acc, w)
			ci.draw_line(c + Vector2(-s * 0.6, -s * 0.15), c + Vector2(s * 0.6, -s * 0.15), Color(acc, acc.a * 0.6), w * 0.7)
		"twigs":
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.6), c + Vector2(s * 0.7, -s * 0.5), line, w)
			ci.draw_line(c + Vector2(-s * 0.7, -s * 0.4), c + Vector2(s * 0.6, s * 0.6), line, w)
			ci.draw_line(c + Vector2(s * 0.1, -s * 0.05), c + Vector2(s * 0.3, -s * 0.6), acc, w * 0.8)
		"tally":
			_poly(ci, [c + Vector2(-s * 0.18, -s * 0.8), c + Vector2(s * 0.18, -s * 0.8), c + Vector2(s * 0.18, s * 0.8), c + Vector2(-s * 0.18, s * 0.8)], fill, line, w)
			# Çentikler çubuğun boyuna eşit aralıkla (beşte eski aralık: 0,27).
			var n := maxi(notches, 1)
			var step := s * 1.08 / float(maxi(n - 1, 1)) if n > 1 else 0.0
			for k in n:
				var y := -s * 0.55 + k * step
				ci.draw_line(c + Vector2(-s * 0.18, y), c + Vector2(s * 0.05, y + s * 0.06), acc, w * (0.9 if n <= 5 else 0.75))
		"bird":
			_poly(ci, [c + Vector2(-s * 0.75, s * 0.1), c + Vector2(-s * 0.1, -s * 0.2), c + Vector2(s * 0.45, -s * 0.45), c + Vector2(s * 0.7, -s * 0.3),
				c + Vector2(s * 0.4, s * 0.1), c + Vector2(-s * 0.2, s * 0.35)], fill, line, w)
			ci.draw_circle(c + Vector2(s * 0.48, -s * 0.33), s * 0.05, acc)
		"rope":
			ci.draw_arc(c, s * 0.62, 0, TAU, 26, line, w * 1.3, true)
			ci.draw_arc(c, s * 0.38, 0, TAU, 20, line, w * 1.3, true)
			ci.draw_arc(c, s * 0.15, 0, TAU, 12, acc, w, true)
			ci.draw_line(c + Vector2(s * 0.6, s * 0.1), c + Vector2(s * 0.85, s * 0.7), line, w * 1.3)
		"felt":
			_poly(ci, [c + Vector2(-s * 0.8, -s * 0.25), c + Vector2(s * 0.45, -s * 0.25), c + Vector2(s * 0.45, s * 0.35), c + Vector2(-s * 0.8, s * 0.35)], fill, line, w)
			ci.draw_arc(c + Vector2(s * 0.45, s * 0.05), s * 0.3, 0, TAU, 18, line, w, true)
			ci.draw_arc(c + Vector2(s * 0.45, s * 0.05), s * 0.16, PI * 0.3, PI * 1.9, 12, acc, w * 0.8, true)
		"cord":
			for k in 3:
				var y := (k - 1) * s * 0.32
				ci.draw_arc(c + Vector2(-s * 0.35, y), s * 0.22, PI * 0.5, PI * 1.5, 8, line, w, true)
				ci.draw_arc(c + Vector2(s * 0.35, y), s * 0.22, -PI * 0.5, PI * 0.5, 8, line, w, true)
				ci.draw_line(c + Vector2(-s * 0.35, y - s * 0.22), c + Vector2(s * 0.35, y - s * 0.22), line, w)
			ci.draw_line(c + Vector2(-s * 0.1, -s * 0.75), c + Vector2(-s * 0.1, s * 0.75), acc, w)
		"bone":
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.45), c + Vector2(s * 0.45, -s * 0.45), line, w * 2.2)
			for p: Vector2 in [Vector2(-0.6, 0.38), Vector2(-0.38, 0.6), Vector2(0.6, -0.38), Vector2(0.38, -0.6)]:
				ci.draw_circle(c + p * s, s * 0.16, fill)
				ci.draw_arc(c + p * s, s * 0.16, 0, TAU, 12, line, w, true)
		"horn":
			ci.draw_arc(c + Vector2(s * 0.3, s * 0.35), s * 0.85, PI * 1.0, PI * 1.55, 16, line, w * 2.0, true)
			ci.draw_arc(c + Vector2(s * 0.3, s * 0.35), s * 0.85, PI * 1.0, PI * 1.12, 6, acc, w * 2.4, true)
		"drop":
			_poly(ci, [c + Vector2(0, -s * 0.75), c + Vector2(s * 0.45, s * 0.1), c + Vector2(s * 0.3, s * 0.55), c + Vector2(0, s * 0.7),
				c + Vector2(-s * 0.3, s * 0.55), c + Vector2(-s * 0.45, s * 0.1)], fill, acc, w)
		"pot":
			ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.6, 0.0, PI, 18, line, w, true)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.1), c + Vector2(s * 0.6, s * 0.1), line, w)
			ci.draw_line(c + Vector2(-s * 0.72, -s * 0.05), c + Vector2(s * 0.72, -s * 0.05), acc, w * 1.3)
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.55, PI * 1.1, PI * 1.9, 12, Color(line, line.a * 0.6), w * 0.8, true)
		"torch":
			ci.draw_line(c + Vector2(-s * 0.35, s * 0.75), c + Vector2(s * 0.15, -s * 0.2), line, w * 1.6)
			_poly(ci, [c + Vector2(s * 0.15, -s * 0.85), c + Vector2(s * 0.45, -s * 0.35), c + Vector2(s * 0.2, -s * 0.1), c + Vector2(-s * 0.05, -s * 0.35)], fill, acc, w)
		"bundle":
			_poly(ci, [c + Vector2(-s * 0.75, -s * 0.35), c + Vector2(s * 0.75, -s * 0.35), c + Vector2(s * 0.75, s * 0.45), c + Vector2(-s * 0.75, s * 0.45)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.25, -s * 0.35), c + Vector2(-s * 0.25, s * 0.45), acc, w * 1.2)
			ci.draw_line(c + Vector2(s * 0.25, -s * 0.35), c + Vector2(s * 0.25, s * 0.45), acc, w * 1.2)
		"parts":
			_poly(ci, [c + Vector2(-s * 0.7, -s * 0.6), c + Vector2(-s * 0.1, -s * 0.6), c + Vector2(-s * 0.1, s * 0.0), c + Vector2(-s * 0.7, s * 0.0)], fill, line, w)
			_poly(ci, [c + Vector2(s * 0.0, s * 0.1), c + Vector2(s * 0.7, s * 0.1), c + Vector2(s * 0.7, s * 0.7), c + Vector2(s * 0.0, s * 0.7)], fill, acc, w)
		"axe":
			ci.draw_line(c + Vector2(-s * 0.5, s * 0.75), c + Vector2(s * 0.25, -s * 0.6), line, w * 1.3)
			_poly(ci, [c + Vector2(s * 0.05, -s * 0.45), c + Vector2(s * 0.7, -s * 0.75), c + Vector2(s * 0.75, -s * 0.05), c + Vector2(s * 0.3, -s * 0.15)], fill, acc, w)
		"pick":
			ci.draw_line(c + Vector2(0, s * 0.8), c + Vector2(0, -s * 0.35), line, w * 1.3)
			ci.draw_arc(c + Vector2(0, s * 0.25), s * 0.75, PI * 1.2, PI * 1.8, 16, acc, w * 1.4, true)
		"net":
			for k in 4:
				var t := -s * 0.6 + k * s * 0.4
				ci.draw_line(c + Vector2(t, -s * 0.7), c + Vector2(t + s * 0.2, s * 0.7), line, w * 0.8)
				ci.draw_line(c + Vector2(-s * 0.7, t), c + Vector2(s * 0.7, t + s * 0.2), line, w * 0.8)
		"flint":
			_poly(ci, [c + Vector2(-s * 0.6, s * 0.2), c + Vector2(-s * 0.1, -s * 0.5), c + Vector2(s * 0.5, -s * 0.2), c + Vector2(s * 0.2, s * 0.5)], fill, line, w)
			for a in 3:
				var d := Vector2.from_angle(-PI * 0.2 - a * 0.35) * s * 0.35
				ci.draw_line(c + Vector2(s * 0.45, -s * 0.45), c + Vector2(s * 0.45, -s * 0.45) + d, acc, w * 0.8)
		"sling":
			ci.draw_arc(c + Vector2(0, s * 0.2), s * 0.32, 0, TAU, 16, acc, w, true)
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.1), c + Vector2(-s * 0.7, -s * 0.75), line, w)
			ci.draw_line(c + Vector2(s * 0.3, s * 0.1), c + Vector2(s * 0.7, -s * 0.75), line, w)
		"sled":
			_poly(ci, [c + Vector2(-s * 0.7, -s * 0.15), c + Vector2(s * 0.6, -s * 0.15), c + Vector2(s * 0.6, s * 0.25), c + Vector2(-s * 0.7, s * 0.25)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.8, s * 0.5), c + Vector2(s * 0.6, s * 0.5), acc, w * 1.2)
			ci.draw_arc(c + Vector2(s * 0.6, s * 0.3), s * 0.2, -PI * 0.5, PI * 0.5, 8, acc, w * 1.2, true)
		"wedge":
			_poly(ci, [c + Vector2(-s * 0.2, -s * 0.75), c + Vector2(s * 0.2, -s * 0.75), c + Vector2(0, s * 0.6)], fill, acc, w)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.75), c + Vector2(s * 0.6, s * 0.75), line, w)
		"cap":
			ci.draw_arc(c + Vector2(0, s * 0.25), s * 0.62, PI, TAU, 18, line, w, true)
			ci.draw_line(c + Vector2(-s * 0.78, s * 0.25), c + Vector2(s * 0.78, s * 0.25), acc, w * 1.4)
			ci.draw_line(c + Vector2(0, -s * 0.37), c + Vector2(0, -s * 0.7), line, w)
		"pendant":
			ci.draw_arc(c + Vector2(0, -s * 0.35), s * 0.6, PI * 0.15, PI * 0.85, 16, line, w, true)
			_poly(ci, [c + Vector2(0, s * 0.15), c + Vector2(s * 0.22, s * 0.45), c + Vector2(0, s * 0.75), c + Vector2(-s * 0.22, s * 0.45)], fill, acc, w)
		"coat":
			_poly(ci, [c + Vector2(-s * 0.3, -s * 0.7), c + Vector2(s * 0.3, -s * 0.7), c + Vector2(s * 0.75, -s * 0.35), c + Vector2(s * 0.55, s * 0.0),
				c + Vector2(s * 0.42, -s * 0.12), c + Vector2(s * 0.42, s * 0.75), c + Vector2(-s * 0.42, s * 0.75), c + Vector2(-s * 0.42, -s * 0.12),
				c + Vector2(-s * 0.55, s * 0.0), c + Vector2(-s * 0.75, -s * 0.35)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.7), c + Vector2(s * 0.15, s * 0.75), acc, w * 0.9)
		"cape":
			_poly(ci, [c + Vector2(-s * 0.25, -s * 0.7), c + Vector2(s * 0.25, -s * 0.7), c + Vector2(s * 0.7, s * 0.75), c + Vector2(-s * 0.7, s * 0.75)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.6), c + Vector2(s * 0.3, -s * 0.6), acc, w * 1.3)
		"glove":
			_poly(ci, [c + Vector2(-s * 0.35, s * 0.75), c + Vector2(-s * 0.4, -s * 0.2), c + Vector2(-s * 0.2, -s * 0.7), c + Vector2(s * 0.25, -s * 0.65),
				c + Vector2(s * 0.4, -s * 0.15), c + Vector2(s * 0.65, -s * 0.3), c + Vector2(s * 0.45, s * 0.2), c + Vector2(s * 0.35, s * 0.75)], fill, line, w)
			ci.draw_line(c + Vector2(-s * 0.38, s * 0.45), c + Vector2(s * 0.36, s * 0.45), acc, w)
		"belt":
			_poly(ci, [c + Vector2(-s * 0.8, -s * 0.18), c + Vector2(s * 0.8, -s * 0.18), c + Vector2(s * 0.8, s * 0.18), c + Vector2(-s * 0.8, s * 0.18)], fill, line, w)
			_poly(ci, [c + Vector2(-s * 0.22, -s * 0.32), c + Vector2(s * 0.22, -s * 0.32), c + Vector2(s * 0.22, s * 0.32), c + Vector2(-s * 0.22, s * 0.32)], fill, acc, w)
		"boot":
			_poly(ci, [c + Vector2(-s * 0.35, -s * 0.75), c + Vector2(s * 0.2, -s * 0.75), c + Vector2(s * 0.2, s * 0.2), c + Vector2(s * 0.75, s * 0.4),
				c + Vector2(s * 0.75, s * 0.7), c + Vector2(-s * 0.35, s * 0.7)], fill, line, w)
		"sword":
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.6), c + Vector2(s * 0.7, -s * 0.7), line, w * 1.4)
			ci.draw_line(c + Vector2(-s * 0.55, s * 0.25), c + Vector2(-s * 0.25, s * 0.55), acc, w * 1.4)
		"bow":
			ci.draw_arc(c + Vector2(-s * 0.35, 0), s * 0.85, -PI * 0.4, PI * 0.4, 18, line, w * 1.2, true)
			ci.draw_line(c + Vector2(s * 0.08, -s * 0.66), c + Vector2(s * 0.08, s * 0.66), acc, w * 0.7)
		"quiver":
			_poly(ci, [c + Vector2(-s * 0.3, -s * 0.35), c + Vector2(s * 0.3, -s * 0.35), c + Vector2(s * 0.25, s * 0.75), c + Vector2(-s * 0.25, s * 0.75)], fill, line, w)
			for k in 3:
				var x := s * (k - 1) * 0.18
				ci.draw_line(c + Vector2(x, -s * 0.35), c + Vector2(x + s * 0.05, -s * 0.78), acc, w * 0.8)
		"saddle":
			ci.draw_arc(c + Vector2(0, s * 0.55), s * 0.75, PI * 1.1, PI * 1.9, 16, line, w * 1.3, true)
			ci.draw_line(c + Vector2(-s * 0.2, s * 0.1), c + Vector2(-s * 0.2, s * 0.75), acc, w)
		"bridle", "hoof", "blanket":
			ci.draw_arc(c, s * 0.55, 0, TAU, 20, line, w, true)
			ci.draw_arc(c, s * 0.25, 0, TAU, 14, acc, w, true)
		_:
			# Kese: bağlı ağızlı torba (heybe işareti).
			HudInventoryScreen.draw_bag_glyph(ci, c, s * 0.9, line)


static func _poly(ci: CanvasItem, pts: Array, fill: Color, stroke: Color, w: float) -> void:
	var p := PackedVector2Array(pts)
	if fill.a > 0.0:
		ci.draw_colored_polygon(p, fill)
	p.append(p[0])
	ci.draw_polyline(p, stroke, w, true)
