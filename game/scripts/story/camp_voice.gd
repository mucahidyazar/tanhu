class_name CampVoice
extends Node
## Serbest Gez'in kamp sözleri (E20/7; K61 B dilimi, yan görevin düğümü): ateşin başındakiler oyuncunun Çocuğuna seslenir. Satırlar vo_lines.json'da
## act0.camp.* (konuşan, metin ve ses oradan):
##   rise    Ana     Çocuk ateş başındaki kütükten ilk harekette kalkınca: «Uzağa gitme, kızım.»
##   bard    Ozan    Çocuk ozanın yanında durmaya başlayınca (ozanı dinlemenin sayacı işlerken): «Otur. Önce kopuz söylesin.»
##   stable  Baba    ahırın önüne varınca (JourneyFlags.STABLE yeni konunca): «Doru'nun arkasından geçme. Teper.»
## Her söz bir Serbest Gez inişinde bir kez söylenir (ahırınki yolculukta bir kez: işaret bir kez konar). Söz SceneVoice'la çalar; altyazı kendi
## StoryHud'ındadır (sade amaç bloğu kapalı). Yalnız Çocuk kamptayken ve oyun sürerken (active) işler; değilse altyazı silinir, çalan söz susar.
## main.gd kurar: begin(oyuncu, yolculuk, UI, perde, etkin_mi) Serbest Gez'e inerken, visited(yeni işaretler) yolculuğun her yoklamasında.

const PREFIX := "act0.camp."

var voice: SceneVoice
var hud: StoryHud
var player: PlayerController
var journey: Journey
## Etkin mi: func() -> bool (main.gd: oyun sürüyor, kamp, oyuncu Çocuk).
var active: Callable
var clock := 0.0
var lang := "tr"

var _said := {}
var _was_seated := false
var _was_active := false


## Serbest Gez'e iniş: sözler yeniden söylenebilir, altyazının düğümü below'un altına kurulur (altyazı SubtitleBar'ın kendi katmanında çizilir).
func begin(p_player: PlayerController, p_journey: Journey, ui_parent: Node, below: Node, p_active: Callable) -> void:
	player = p_player
	journey = p_journey
	active = p_active
	lang = SubtitleBar.ui_lang()
	_said.clear()
	_was_seated = player != null and player.is_seated()
	if voice == null:
		voice = SceneVoice.new()
		voice.prefix = PREFIX
		voice.show = _show_line
		voice.text_seconds = func(key: String) -> float: return StoryHud.line_seconds(VoLines.subtitle(PREFIX + key, lang))
	voice.audio = get_node_or_null(^"/root/AudioManager")
	if hud == null and ui_parent:
		hud = StoryHud.new()
		hud.name = "CampVoiceHud"
		hud.show_box = false
		ui_parent.add_child(hud)
		if below and below.get_parent() == ui_parent:
			ui_parent.move_child(hud, below.get_index())


## Yolculuğun yoklaması (main.gd): yeni konan işaretler.
func visited(fresh: PackedStringArray) -> void:
	if fresh.has(JourneyFlags.STABLE):
		_once("stable")


func _process(delta: float) -> void:
	var on := active.is_valid() and bool(active.call()) and is_instance_valid(player) and journey != null
	if not on:
		if _was_active:
			_was_active = false
			if voice:
				voice.stop()
			if hud:
				hud.clear()
		return
	_was_active = true
	clock += delta
	voice.tick(clock)
	if hud:
		hud.tick(clock)
	var seated := player.is_seated()
	if _was_seated and not seated:
		_once("rise")
	_was_seated = seated
	if journey.bard_listen_time() > 0.0 and not journey.has_flag(JourneyFlags.BARD_LISTEN):
		_once("bard")


## Söylenenler (sınama).
func said() -> PackedStringArray:
	return PackedStringArray(_said.keys())


func _once(key: String) -> void:
	if _said.has(key) or voice == null or not VoLines.has_line(PREFIX + key):
		return
	_said[key] = true
	voice.say(key)


func _show_line(key: String, seconds: float) -> void:
	if hud:
		hud.say(VoLines.speaker_name(PREFIX + key, lang), VoLines.subtitle(PREFIX + key, lang), seconds, clock)


func _exit_tree() -> void:
	if voice:
		voice.stop()
