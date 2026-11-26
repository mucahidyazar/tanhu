class_name GeneralPage
extends Control
## "Genel" (Tanhu 1): oyun menüsünün duraklatma sayfası. Solda düğüm butonları (DEVAM ET, KAYDET,
## YÜKLE, AYARLAR, ANA MENÜ, MASAÜSTÜNE DÖN), sağda yolculuğun kartı: nerede olduğun, oynanan süre,
## Destan Kitabı'nda açılanlar. Butonlar yalnızca sorar ("chosen"); işi oyun menüsü yapar.

signal chosen(what: String)

## [ne, buton yazısı]
const ITEMS := [
	["resume", "DEVAM ET"],
	["save", "KAYDET"],
	["load", "YÜKLE"],
	["settings", "AYARLAR"],
	["main", "ANA MENÜ"],
	["quit", "MASAÜSTÜNE DÖN"],
]

## Oyun menüsü koyar: kaydetmek için sakin bir an gerekir.
var can_save := true
## Kaydın neden kapalı olduğu (boş değilse butonların altında küçük satır; K99).
var save_note := ""
## Yolculuk kartının yeri ve altındaki satır (boşsa kampın yeri ve gecesi).
var card_place := ""
var card_note := ""
var embedded := true
var journey: Journey
var saves: SaveSystem

var _buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if saves == null:
		saves = journey.saves if journey else SaveSystem.new()
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 64)
	center.add_child(hb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(col)
	var order: Array[KnotButton] = []
	for it in ITEMS:
		var b := KnotButton.new(str(it[1]), 30)
		b.custom_minimum_size = Vector2(560, 78)
		var what: String = it[0]
		b.pressed.connect(func() -> void: chosen.emit(what))
		col.add_child(b)
		_buttons[what] = b
		order.append(b)
	(_buttons["save"] as KnotButton).set_available(can_save and journey != null)
	(_buttons["load"] as KnotButton).set_available(saves.has_any_save())
	if not save_note.is_empty():
		var note := UIKit.label(save_note, 20, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
		note.name = "SaveNote"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(560, 0)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(note)
	_link_focus(order)
	hb.add_child(_journey_card())
	await get_tree().process_frame
	if is_instance_valid(self):
		(_buttons["resume"] as KnotButton).grab_focus_quietly()


## Butonun kendisi (ör. "save", testler için).
func get_button(what: String) -> KnotButton:
	return _buttons.get(what) as KnotButton


## Yukarı / aşağı yalnızca basılabilen butonlarda döner (Tanhu 1'in açılış menüsü gibi).
func _link_focus(order: Array[KnotButton]) -> void:
	var live: Array[KnotButton] = []
	for b in order:
		if not b.disabled:
			live.append(b)
	for i in live.size():
		var b := live[i]
		var prev := b.get_path_to(live[posmod(i - 1, live.size())])
		var nxt := b.get_path_to(live[posmod(i + 1, live.size())])
		b.focus_neighbor_top = prev
		b.focus_neighbor_bottom = nxt
		b.focus_previous = prev
		b.focus_next = nxt
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(b)


func _journey_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.panel_style(Color(0.022, 0.028, 0.042, 0.93), Color(UIKit.GOLD_DIM, 0.85), 1, 3, Color(0, 0, 0, 0.45), 14))
	card.custom_minimum_size = Vector2(560, 0)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 28)
	m.add_theme_constant_override("margin_top", 22)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)
	vb.add_child(UIKit.label("YOLCULUK", 18, "AlegreyaSC-Regular", 400, Color(UIKit.GOLD, 0.85), 3))
	var place_id := journey.place_id() if journey else ""
	var place := UIKit.label(card_place if not card_place.is_empty() else JourneyFlags.place_name(place_id), 30, "Cinzel", 700, UIKit.GOLD, 2)
	place.name = "Place"
	place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place.custom_minimum_size = Vector2(500, 0)
	vb.add_child(place)
	var sub := UIKit.label(card_note if not card_note.is_empty() else "%s  ·  Ay ışığında bir bozkır gecesi" % SaveData.CAMP_NAME, 20, "Alegreya-Italic", 400, UIKit.SKY)
	sub.name = "PlaceNote"
	vb.add_child(sub)
	var div := SaveLoadPanel.Divider.new()
	div.custom_minimum_size = Vector2(0, 24)
	vb.add_child(div)
	var facts := UIKit.rich(21, "Alegreya")
	facts.fit_content = true
	facts.scroll_active = false
	facts.custom_minimum_size = Vector2(500, 0)
	facts.text = "\n".join(journey_facts(journey))
	vb.add_child(facts)
	return card


## Kartın satırları (BBCode): oynanan süre ve Destan Kitabı'nda açılanlar.
static func journey_facts(p_journey: Journey) -> PackedStringArray:
	var dim := UIKit.TEXT_DIM.to_html(false)
	var rows := PackedStringArray()
	var flags: Dictionary = p_journey.flags if p_journey else {}
	rows.append("[color=#%s]Oynanan süre[/color]  %s" % [dim, SaveData.format_duration(p_journey.play_time if p_journey else 0.0)])
	for chapter in DestanKitabi.CHAPTERS:
		var opened := DestanKitabi.entries(chapter, flags).size()
		var total := DestanKitabi.total(chapter)
		rows.append("[color=#%s]%s[/color]  %d / %d" % [dim, DestanKitabi.chapter_title(chapter), opened, total])
	return rows
