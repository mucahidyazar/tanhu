class_name MainMenu
extends Control
## Açılış ekranı (Tanhu 1'in başlık ekranı, canlı gece kampının üstünde): sol üstte altın TANHU logosu,
## süs çizgisi ve "BİR BOZKIR DESTANI", altında düğüm butonları sütunu (YENİ OYUN, DEVAM ET, YÜKLE,
## DESTAN KİTABI, AYARLAR, ÇIKIŞ), okunurluk için soldan açılan koyu bir gölge, DEVAM ET seçiliyken
## yanında son kaydın kartı, sağ altta kulaklık önerisi ve sürüm; sağ altta ayrıca SERBEST GEZ.
## Her şey ekranın tuvalinden yerleşir: 16:9, 16:10 ve 21:9 ekranlar aynı düzeni görür (21:9'da başlık
## ve sütun ortadaki 16:9 alanda kalır). Oyun açılışında atlanabilir bir giriş oynar (play_intro).
##
## Menü oyunun akışını yönetmez, sinyal yayar (bkz. main.gd):
##   start_requested      YENİ OYUN (kayıt varsa önce sorulur)
##   continue_requested   DEVAM ET (son kayıt; kayıt yoksa buton pasiftir)
##   load_requested(slot) YÜKLE panelinden seçilen yuva
##   free_roam_requested  SERBEST GEZ
##   quit_requested       ÇIKIŞ (web ve mobilde yoktur)
## AYARLAR, YÜKLE ve DESTAN KİTABI sayfalarını menü kendisi açar ve kapatır.
## Klavye / fare / oyun kolu: yukarı / aşağı yalnızca basılabilen butonlarda başa sararak gezer
## (pasif butonlar odak almaz), sağ SERBEST GEZ'e geçer, Enter / Boşluk / A seçer.
##
## Bu düğüm 3B sahnenin ve boyalı ekran efektinin (PainterlyOverlay, katman 1) ÜSTÜNDEKİ bir
## CanvasLayer'da durmalıdır.

signal start_requested
signal continue_requested
signal load_requested(slot: int)
signal quit_requested
signal free_roam_requested
## show_menu() / hide_menu() / play_intro() geçişi bittiğinde yayılır (await için).
signal transition_finished

## Menünün geçiş durumu: gizli → açılıyor → açık → kayboluyor → gizli.
enum State { HIDDEN, SHOWING, SHOWN, HIDING }

const LOGO_PATH := "res://assets/title/logo.png"
const SUBTITLE := "BİR BOZKIR DESTANI"
const HINT_TEXT := "Kulaklıkla oynaman önerilir"
const FREE_ROAM_TEXT := "SERBEST GEZ"
const FREE_ROAM_HINT := "Kampta dolaş"
const CARD_HEAD := "SON KAYIT"
## Yeni Oyun'un akışı kayıt yazmaz (K99): kayıtlar ve «Devam Et» yerinde kalır.
const CONFIRM_NEW := "Yeni bir yolculuk başlayacak. Kayıtların yerinde kalır; «Devam Et» son kaydı açar. Emin misin?"
const LOAD_FAILED := "Bu kayıt açılamadı."
## Sütun, yukarıdan aşağı: anahtar ve yazı.
const ITEMS := [
	["new", "YENİ OYUN"],
	["continue", "DEVAM ET"],
	["load", "YÜKLE"],
	["book", "DESTAN KİTABI"],
	["settings", "AYARLAR"],
	["quit", "ÇIKIŞ"],
]
## 1080 satırlık tuvalde sütun ölçüleri (arayüz ölçeğiyle çarpılır).
const MENU_W := 520.0
const BUTTON_H := 80.0
## Butonlar arası boşluk: vurgu parıltısı komşu butona taşmasın diye geniş tutulur.
const BUTTON_GAP := 28.0
const SLIDE_FROM := -56.0
const TOP_MARGIN := 64.0
const BOTTOM_MARGIN := 70.0
## Soldaki gölgenin koyuluğu (Tanhu 1'in varsayılan tablosunda 0,42-0,62; canlı kampta okunur kalsın).
const SHADE_ALPHA := 0.62
## Pasif butonun saydamlığı.
const DISABLED_ALPHA := 0.6
## Giriş (saniye): perde kalkar, logo belirir, alt yazı, butonlar sırayla soldan kayarak gelir.
const CURTAIN_TIME := 2.0
const LOGO_DELAY := 1.1
const LOGO_TIME := 1.8
const SUB_DELAY := 1.9
const SUB_TIME := 1.3
const BUTTONS_DELAY := 2.3
const BUTTON_STAGGER := 0.1
## Oyundan menüye dönüşte kısa giriş (perdesiz).
const RETURN_BUTTONS_DELAY := 0.35
const RETURN_STAGGER := 0.06
const OUTRO_TIME := 0.5
## Kaybolurken yeniden açılırsa her şeyin olduğu yerden tam görünüme dönme süresi.
const RETURN_TIME := 0.35

## Sahne açılınca menü kendiliğinden (perdesiz) görünsün mü? Kapalıysa gizli başlar; ana akış
## play_intro() ya da show_menu() çağırır.
@export var auto_show := true
## Animasyon hız çarpanı (1 = normal). Testler hızlandırmak için büyütür.
@export var transition_speed := 1.0

## Kayıtlar (DEVAM ET / YÜKLE / kart / Destan Kitabı). Boşsa ilk kullanımda user:// açılır.
## Verilince butonların durumu hemen yenilenir.
var saves: SaveSystem:
	set(value):
		saves = value
		refresh_saves()
## Ayarlar sayfasının değiştirdiği ayarlar (boşsa GameSettings autoload'u).
var settings: Node

var _shade: TextureRect
var _logo_holder: VBoxContainer
var _logo: Control
var _ornament: OrnamentLine
var _sub: Label
var _menu_box: VBoxContainer
var _buttons: Array[KnotButton] = []
var _by_key: Dictionary = {}
var _free_box: VBoxContainer
var _free_button: KnotButton
var _free_hint: Label
var _card: SaveCard
var _card_on := false
var _card_tw: Tween
## Kartın sütundan kayarak gelişi (tuval pikseli).
var _card_slide := 0.0
var _hint: Label
var _ver: Label
var _toast: MenuToast
var _curtain: ColorRect
var _page: Control
var _page_open := false
var _tween: Tween
var _state := State.HIDDEN
var _intro_running := false
var _auto_show_pending := false
var _show_instantly_on_ready := false
## play_intro() sahneye eklenmeden önce istendi: eklenince oynar.
var _intro_on_ready := false
var _last_focused: KnotButton
var _transition_id := 0


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	MenuStyle.ensure_pad_actions()
	_build_left_shade()
	_build_logo()
	_build_menu()
	_build_free_roam()
	_card = SaveCard.new()
	add_child(_card)
	# Kartın kaydırılmış satırları bir kare geç yerleşir: butona ortalı kalsın.
	_card.resized.connect(_layout_card)
	_build_footer()
	_toast = MenuToast.new()
	add_child(_toast)
	_curtain = ColorRect.new()
	UIKit.full_rect(_curtain)
	_curtain.color = Color(0, 0, 0, 0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.visible = false
	add_child(_curtain)
	resized.connect(_layout)
	var s := _settings()
	if s and s.has_signal(&"changed"):
		s.changed.connect(_layout)
	refresh_saves()
	_layout()
	_layout.call_deferred()
	if _intro_on_ready:
		_finish_hide()
		play_intro.call_deferred()
	elif not auto_show:
		_finish_hide()
	elif _show_instantly_on_ready:
		show_menu(false)
	else:
		_apply_hidden_look()
		_set_interactive(false)
		_auto_show_pending = true
		_run_auto_show.call_deferred()


# --- Genel arayüz (ana akış ve testler kullanır) -------------------------------------------

## Sütundaki butonlar, yukarıdan aşağı (web ve mobilde ÇIKIŞ yoktur).
func get_main_buttons() -> Array[KnotButton]:
	return _buttons.duplicate()


## Anahtarıyla bir buton: "new", "continue", "load", "book", "settings", "quit" (yoksa null).
func get_button(key: String) -> KnotButton:
	return _by_key.get(key) as KnotButton


## Sağ alttaki SERBEST GEZ butonu.
func get_free_roam_button() -> KnotButton:
	return _free_button


## DEVAM ET'in yanındaki son kayıt kartı.
func get_card() -> SaveCard:
	return _card


## Kayıtlar değişince (ör. oyundan dönünce) DEVAM ET / YÜKLE'nin durumunu yeniler.
func refresh_saves() -> void:
	if not is_node_ready():
		return
	var saved := _saves().has_any_save()
	for key in ["continue", "load"]:
		var b := get_button(key)
		b.set_available(saved)
		b.set_interactive(is_accepting_input())
	_link_focus()
	for b in _buttons:
		if not _intro_running and _state != State.HIDDEN:
			b.modulate.a = button_alpha(b.disabled)
	if not saved:
		_show_card(false)


## Tanhu 1'in girişi: siyah perde kalkar, logo ve alt yazı belirir, butonlar sırayla soldan gelir.
## Herhangi bir tuş, tık ya da düğme girişi atlar (o basış yalnızca atlar, bir butona gitmez).
func play_intro() -> Signal:
	if not is_node_ready():
		auto_show = true
		_show_instantly_on_ready = false
		_intro_on_ready = true
		_next_transition()
		return transition_finished
	var id := _next_transition()
	_auto_show_pending = false
	_intro_on_ready = false
	_kill_tween()
	refresh_saves()
	_state = State.SHOWING
	visible = true
	modulate.a = 1.0
	_set_interactive(false)
	_intro_running = true
	_curtain.visible = true
	_curtain.color.a = 1.0
	_apply_hidden_look()
	_tween = _new_tween()
	_tween.tween_property(_curtain, "color:a", 0.0, CURTAIN_TIME).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_logo, "modulate:a", 1.0, LOGO_TIME).set_delay(LOGO_DELAY).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_sub, "modulate:a", 1.0, SUB_TIME).set_delay(SUB_DELAY)
	for i in _buttons.size():
		_tween_button_in(_tween, _buttons[i], BUTTONS_DELAY + i * BUTTON_STAGGER)
	var corner := BUTTONS_DELAY + _buttons.size() * BUTTON_STAGGER
	_tween.tween_property(_free_box, "modulate:a", 1.0, 0.6).set_delay(corner)
	_tween.tween_property(_hint, "modulate:a", 0.8, 0.8).set_delay(corner)
	_tween.tween_property(_ver, "modulate:a", 0.6, 0.8).set_delay(corner)
	_tween.chain().tween_callback(finish_intro.bind(id))
	# Giriş çoğu zaman ağır sahne kurulumunun hemen ardından başlar: animasyon atlanmasın.
	MenuStyle.play_when_settled(self, _tween)
	return transition_finished


## Girişi atlar: her şey hemen tam görünür, odak ilk basılabilir butona gelir.
func finish_intro(id: int = -1) -> void:
	if not _intro_running:
		return
	if id >= 0 and id != _transition_id:
		return
	_intro_running = false
	_kill_tween()
	_curtain.color.a = 0.0
	_curtain.visible = false
	_apply_shown_look()
	_state = State.SHOWN
	_set_interactive(true)
	_focus_default()
	transition_finished.emit()


## Giriş sürüyor mu?
func is_intro_running() -> bool:
	return _intro_running


## Menüyü gösterir. animated=true ise logo belirir ve butonlar sırayla soldan kayarak gelir (perdesiz).
## Dönen sinyal geçiş bitince yayılır: await menu.show_menu()
## - Menü zaten açıksa animasyon baştan oynamaz (göz kırpmaz); sinyal yine de yayılır.
## - Kaybolurken çağrılırsa her şey olduğu yerden kısa sürede geri gelir.
func show_menu(animated: bool = true) -> Signal:
	if not is_node_ready():
		auto_show = true
		_show_instantly_on_ready = not animated
		_next_transition()
		return transition_finished
	_auto_show_pending = false
	if _intro_running:
		# Giriş sürüyor: o bitince sinyal kendiliğinden yayılır.
		return transition_finished
	if visible and _state == State.SHOWING and animated:
		return transition_finished
	var id := _next_transition()
	refresh_saves()
	if visible and _state == State.SHOWN:
		_ensure_focus()
		_finish_transition.call_deferred(id)
		return transition_finished
	var was_hiding := _state == State.HIDING
	var instant := not animated or not is_inside_tree()
	_kill_tween()
	_state = State.SHOWN if instant else State.SHOWING
	visible = true
	_set_interactive(true)
	if instant:
		modulate.a = 1.0
		_apply_shown_look()
		_focus_default()
		_finish_transition.call_deferred(id)
		return transition_finished
	_tween = _new_tween()
	if was_hiding:
		_tween.tween_property(self, "modulate:a", 1.0, RETURN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_to_shown(_tween, RETURN_TIME)
	else:
		modulate.a = 1.0
		_apply_hidden_look()
		_tween.tween_property(_logo, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
		_tween.tween_property(_sub, "modulate:a", 1.0, 0.6).set_delay(0.3)
		for i in _buttons.size():
			_tween_button_in(_tween, _buttons[i], RETURN_BUTTONS_DELAY + i * RETURN_STAGGER)
		var corner := RETURN_BUTTONS_DELAY + _buttons.size() * RETURN_STAGGER
		_tween.tween_property(_free_box, "modulate:a", 1.0, 0.45).set_delay(corner)
		_tween.tween_property(_hint, "modulate:a", 0.8, 0.5).set_delay(corner)
		_tween.tween_property(_ver, "modulate:a", 0.6, 0.5).set_delay(corner)
	_focus_default()
	_tween.chain().tween_callback(_on_show_finished.bind(id))
	MenuStyle.play_when_settled(self, _tween)
	return transition_finished


## Menüyü gizler. animated=true ise yumuşakça kaybolur. Kaybolma başladığı anda butonlar tepki
## vermez: sinyal yaymaz, fareyle üzerine gelinse bile parlamaz ve ses çalmaz.
func hide_menu(animated: bool = true) -> Signal:
	if not is_node_ready():
		auto_show = false
		_show_instantly_on_ready = false
		_finish_transition.call_deferred(_next_transition())
		return transition_finished
	_auto_show_pending = false
	if _state == State.HIDING and animated:
		return transition_finished
	var id := _next_transition()
	_kill_tween()
	_intro_running = false
	_curtain.visible = false
	_set_interactive(false)
	_show_card(false)
	if _state == State.HIDDEN or not visible or not animated or not is_inside_tree():
		_finish_hide()
		_finish_transition.call_deferred(id)
		return transition_finished
	_state = State.HIDING
	_tween = _new_tween()
	_tween.tween_property(self, "modulate:a", 0.0, OUTRO_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_on_hide_finished.bind(id))
	return transition_finished


## Sağ üstte kısa bir bildirim (ör. "Bu kayıt açılamadı.").
func show_toast(text: String, kind: String = "info") -> void:
	if _toast:
		_toast.show_text(text, kind)


## Ekrandaki bildirimlerin yazıları.
func toast_texts() -> PackedStringArray:
	return _toast.texts() if _toast else PackedStringArray()


## Menü şu an butonlara yanıt veriyor mu? (Açılırken ve açıkken; giriş ve alt sayfalar sürerken hayır.)
func is_accepting_input() -> bool:
	return visible and not _intro_running and not _page_open and (_state == State.SHOWING or _state == State.SHOWN)


## Bir alt sayfa (ayarlar, yükleme, Destan Kitabı, soru) açık mı?
func is_page_open() -> bool:
	return _page_open


## Açık alt sayfa (yoksa null).
func get_page() -> Control:
	return _page if is_instance_valid(_page) else null


## Pasif butonun saydamlığı (saf fonksiyon).
static func button_alpha(disabled: bool) -> float:
	return DISABLED_ALPHA if disabled else 1.0


## Sıralı bir dizide komşu indeks; uçlarda başa / sona sarar (saf fonksiyon).
static func neighbor_index(index: int, step: int, count: int) -> int:
	if count <= 0:
		return 0
	return posmod(index + step, count)


## Tanhu 1'in yerleşimi (saf fonksiyon): tuval boyu, arayüz ölçeği ve sütun / başlık yükseklikleri.
## Döner: {safe_x, logo_scale, logo_pos, menu_pos, shade_size}. Başlık, sütunun bıraktığı yüksekliği
## tam boyuna kadar alır (6 buton yer isterse biraz küçülür); 21:9'da başlık ve sütun ortadaki 16:9'da.
static func layout_for(canvas: Vector2, k: float, menu_h: float, logo_h: float) -> Dictionary:
	var safe_x := maxf(0.0, (canvas.x - canvas.y * 16.0 / 9.0) * 0.5)
	var menu_px := menu_h * k
	var gap := 40.0 * k
	var room := canvas.y - TOP_MARGIN - BOTTOM_MARGIN - menu_px - gap
	var lk := clampf(room / maxf(logo_h, 1.0), k * 0.7, k)
	var spare := maxf(0.0, room - logo_h * lk)
	var logo_pos := Vector2(safe_x + 120.0, TOP_MARGIN + spare * 0.35).round()
	var centre_x := logo_pos.x + 380.0 * lk
	var menu_pos := Vector2(centre_x - MENU_W * 0.5 * k, logo_pos.y + logo_h * lk + gap + spare * 0.25).round()
	return {"safe_x": safe_x, "logo_scale": lk, "logo_pos": logo_pos, "menu_pos": menu_pos,
		"shade_size": Vector2(safe_x + 1150.0, canvas.y)}


# --- Kurulum ---------------------------------------------------------------------------

## Logonun ve sütunun arkasında soldan sağa açılan koyu gölge (kampın açık renkli çimeni üstünde okunsun).
func _build_left_shade() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(0.0, 0.01, 0.02, 1.0), Color(0.0, 0.01, 0.02, 0.6), Color(0.0, 0.01, 0.02, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0.5)
	t.fill_to = Vector2(1, 0.5)
	_shade = TextureRect.new()
	_shade.texture = t
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.modulate.a = SHADE_ALPHA
	add_child(_shade)


func _build_logo() -> void:
	var holder := VBoxContainer.new()
	_logo_holder = holder
	holder.add_theme_constant_override("separation", 6)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	if ResourceLoader.exists(LOGO_PATH):
		var t := TextureRect.new()
		t.texture = load(LOGO_PATH)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		t.custom_minimum_size = Vector2(760, 300)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(t)
		_logo = t
	else:
		# Logo dosyası yoksa yazıyla "TANHU".
		var l := UIKit.label("TANHU", 190, "CinzelDecorative-Bold", 400, UIKit.GOLD, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(760, 300)
		holder.add_child(l)
		_logo = l
	_logo.name = "Logo"
	var orn := HBoxContainer.new()
	orn.add_theme_constant_override("separation", 16)
	orn.alignment = BoxContainer.ALIGNMENT_CENTER
	orn.custom_minimum_size = Vector2(760, 0)
	orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(orn)
	_ornament = OrnamentLine.new()
	_ornament.custom_minimum_size = Vector2(760, 30)
	orn.add_child(_ornament)
	_sub = UIKit.label(SUBTITLE, 34, "Cinzel", 600, UIKit.PARCHMENT, 9)
	_sub.name = "Subtitle"
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.custom_minimum_size = Vector2(760, 0)
	holder.add_child(_sub)


## Web ve mobilde ÇIKIŞ yoktur (Tanhu 1).
static func items() -> Array:
	var out: Array = []
	for it in ITEMS:
		if it[0] == "quit" and (OS.has_feature("web") or OS.has_feature("mobile")):
			continue
		out.append(it)
	return out


func _build_menu() -> void:
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", int(BUTTON_GAP))
	_menu_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_box)
	for it: Array in items():
		var key: String = it[0]
		# Buton taşıyıcısının içinde kayar; sütun taşıyıcıyı yerleştirir.
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(MENU_W, BUTTON_H)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_menu_box.add_child(holder)
		var b := KnotButton.new(str(it[1]), 38)
		b.name = "Button_" + key
		b.custom_minimum_size = Vector2(MENU_W, BUTTON_H)
		b.size = Vector2(MENU_W, BUTTON_H)
		b.brush_seed = 1.3 + _buttons.size() * 1.7
		b.set_meta("key", key)
		b.pressed.connect(_on_pressed.bind(key))
		b.focus_entered.connect(_on_button_focused.bind(b))
		holder.add_child(b)
		_buttons.append(b)
		_by_key[key] = b
	var cont := get_button("continue")
	cont.focus_entered.connect(_show_card.bind(true))
	cont.focus_exited.connect(_show_card.bind(false))


func _build_free_roam() -> void:
	_free_box = VBoxContainer.new()
	_free_box.add_theme_constant_override("separation", 6)
	_free_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_free_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_free_box)
	_free_button = KnotButton.new(FREE_ROAM_TEXT, 24)
	_free_button.name = "FreeRoamButton"
	_free_button.custom_minimum_size = Vector2(380, 62)
	_free_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_free_button.brush_seed = 7.7
	_free_button.pressed.connect(_on_pressed.bind("free"))
	_free_button.focus_entered.connect(_on_button_focused.bind(_free_button))
	_free_box.add_child(_free_button)
	_free_hint = UIKit.label(FREE_ROAM_HINT, 21, "Alegreya-Italic", 400, Color(UIKit.TEXT_DIM, 0.9))
	_free_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_free_box.add_child(_free_hint)


func _build_footer() -> void:
	_hint = UIKit.label(HINT_TEXT, 22, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.offset_left = -840
	_hint.offset_right = -140
	_hint.offset_top = -52
	_hint.offset_bottom = -22
	_hint.modulate.a = 0.8
	add_child(_hint)
	_ver = UIKit.label(version_text(), 20, "Alegreya", 400, UIKit.TEXT_DIM)
	_ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ver.offset_left = -100
	_ver.offset_right = -20
	_ver.offset_top = -49
	_ver.offset_bottom = -21
	_ver.modulate.a = 0.6
	add_child(_ver)


## Sağ alttaki sürüm yazısı ("v0.1.0", proje ayarlarından).
static func version_text() -> String:
	return "v" + str(ProjectSettings.get_setting("application/config/version", "0.1"))


# --- Yerleşim ---------------------------------------------------------------------------

## Her şey tuvalden yerleşir: gölge solda tam boy, başlık ve sütun ortadaki 16:9 alanda, kart DEVAM ET'in
## yanında, SERBEST GEZ sağ altta (kulaklık önerisinin üstünde).
func _layout() -> void:
	if not is_node_ready():
		return
	var cs := size if size.x > 0.0 else get_viewport_rect().size
	var k := _menu_k(cs)
	var lay := layout_for(cs, k, _menu_box.get_combined_minimum_size().y, _logo_holder.get_combined_minimum_size().y)
	_shade.position = Vector2.ZERO
	_shade.size = lay["shade_size"]
	var lk: float = lay["logo_scale"]
	_logo_holder.scale = Vector2(lk, lk)
	_logo_holder.position = lay["logo_pos"]
	_menu_box.scale = Vector2(k, k)
	_menu_box.position = lay["menu_pos"]
	_free_box.scale = Vector2(k, k)
	var fsize := _free_box.get_combined_minimum_size()
	_free_box.size = fsize
	_free_box.position = (Vector2(cs.x - 64.0 - fsize.x * k, cs.y - 78.0 - fsize.y * k)).round()
	_layout_card()


## Menünün ölçeği: oyuncunun arayüz ölçeği (UIKit.ui_k), ama sütun ve en küçük başlık tuvale sığacak kadar (fit_k; K104'ün büyük
## ölçeklerinde 1080 satırda sütun ekranın altından taşıyordu). %100'de 1080 satır sığar: ölçek değişmez (menü karesi referansı).
func _menu_k(cs: Vector2) -> float:
	return minf(UIKit.ui_k(), fit_k(cs.y, _menu_box.get_combined_minimum_size().y, _logo_holder.get_combined_minimum_size().y))


## Sütunun ve en küçük başlığın (layout_for'un 0,7 k'si) tuval yüksekliğine sığdığı en büyük ölçek (saf; boy yoksa INF).
static func fit_k(canvas_h: float, menu_h: float, logo_h: float) -> float:
	var need := menu_h + 40.0 + logo_h * 0.7
	return INF if need <= 0.0 else (canvas_h - TOP_MARGIN - BOTTOM_MARGIN) / need


func _layout_card() -> void:
	if _card == null or _menu_box == null:
		return
	var cs := size if size.x > 0.0 else get_viewport_rect().size
	var k := _menu_k(cs)
	var idx := _buttons.find(get_button("continue"))
	var y_mid := _menu_box.position.y + (idx * (BUTTON_H + BUTTON_GAP) + BUTTON_H * 0.5) * k
	_card.scale = Vector2(k, k)
	_card.size = _card.get_combined_minimum_size()
	var h := _card.size.y * k
	_card.position = Vector2(_menu_box.position.x + (MENU_W + 44.0 + _card_slide) * k, clampf(y_mid - h * 0.5, 40.0, maxf(40.0, cs.y - 40.0 - h))).round()


# --- Butonlar ve odak --------------------------------------------------------------------

func _on_pressed(key: String) -> void:
	if not is_accepting_input():
		return
	match key:
		"new":
			_on_new()
		"continue":
			continue_requested.emit()
		"load":
			_on_load()
		"book":
			_on_book()
		"settings":
			open_settings()
		"quit":
			quit_requested.emit()
		"free":
			free_roam_requested.emit()


func _on_new() -> void:
	if _saves().has_any_save():
		_page_open = true
		var dialog := ConfirmDialog.new()
		_page = dialog
		add_child(dialog)
		var ok: bool = await dialog.run(CONFIRM_NEW)
		_page = null
		_page_open = false
		if not ok:
			get_button("new").grab_focus_quietly()
			return
	start_requested.emit()


func _on_load() -> void:
	var p := SaveLoadPanel.new("load", false)
	p.saves = _saves()
	_open_page(p)
	p.load_requested.connect(func(slot: int) -> void:
		p.queue_free()
		_close_page(null)
		load_requested.emit(slot))
	p.closed.connect(func() -> void:
		if _page == p:
			_close_page(get_button("load")))


## Destan Kitabı: son kaydın işaretleriyle (kayıt yoksa yalnızca baştan açık olanlar).
func _on_book() -> void:
	var m := GameMenu.new()
	m.mode = "book"
	m.flags = latest_flags()
	m.settings = _settings()
	_open_page(m)
	m.show_page(DestanKitabi.CHAPTERS[0])
	await m.closed
	m.queue_free()
	_close_page(get_button("book"))


## Son kaydın işaretleri (kayıt yoksa boş).
func latest_flags() -> Dictionary:
	var slot := _saves().latest_slot()
	if slot < 0:
		return {}
	var flags: Variant = _saves().slot_info(slot).get("flags", {})
	return flags if flags is Dictionary else {}


## Ayarlar (ve tuşlar), oyundakiyle aynı tam ekran kitapta; burada yalnızca bu iki sayfa vardır.
func open_settings(page: String = "ayarlar") -> void:
	if _page_open:
		return
	var m := GameMenu.new()
	m.mode = "title"
	m.settings = _settings()
	_open_page(m)
	m.show_page(page)
	await m.closed
	m.queue_free()
	_close_page(get_button("settings"))


## Geliştirme ve ekran görüntüsü için bir alt sayfayı doğrudan açar: "ayarlar", "tuslar", "yukle",
## "destan", "gok_yer", "kisiler", "taslar", "onay" (YENİ OYUN sorusu), "kart" (DEVAM ET seçili, kart açık).
## "ayarlar:N" N. bölümü (0 Oyun … 3 Ses), "tuslar:N" N. görünümü (0 liste, 1 klavye, 2 oyun kolu) açar.
func open_dev_page(spec: String) -> void:
	var parts := spec.split(":")
	var page := parts[0]
	var sub := int(parts[1]) if parts.size() > 1 else -1
	match page:
		"ayarlar", "tuslar":
			open_settings(page)
			if sub >= 0:
				await get_tree().process_frame
				await get_tree().process_frame
				var book := _page as GameMenu
				if book and book.get_page() is SettingsPanel:
					(book.get_page() as SettingsPanel).show_section(sub)
				elif book and book.get_page() is ControlsPage:
					(book.get_page() as ControlsPage).show_view(sub)
		"yukle":
			_on_load()
		"destan", "gok_yer", "kisiler", "taslar":
			_on_book()
			await get_tree().process_frame
			if _page is GameMenu:
				(_page as GameMenu).show_page(page)
		"onay":
			_on_new()
		"kart":
			var cont := get_button("continue")
			if not cont.disabled:
				cont.grab_focus()


func _open_page(p: Control) -> void:
	_page_open = true
	_page = p
	_set_column_visible(false)
	add_child(p)


func _close_page(focus_to: KnotButton) -> void:
	_page = null
	_page_open = false
	if not is_inside_tree():
		return
	_set_column_visible(true)
	refresh_saves()
	if focus_to and not focus_to.disabled and is_accepting_input():
		focus_to.grab_focus_quietly()
	else:
		_ensure_focus()


func _set_column_visible(on: bool) -> void:
	_menu_box.visible = on
	_free_box.visible = on
	if not on:
		_show_card(false)
		_release_focus()


func _on_button_focused(button: KnotButton) -> void:
	_last_focused = button
	if button != _free_button:
		# SERBEST GEZ'den sola / yukarı basınca en son seçilen sütun butonuna dönülür.
		_free_button.focus_neighbor_left = _free_button.get_path_to(button)
		_free_button.focus_neighbor_top = _free_button.get_path_to(button)


## Yukarı / aşağı yalnızca basılabilen butonlarda döner; pasifler hiç odak almaz. Sağ SERBEST GEZ'e geçer.
func _link_focus() -> void:
	var live: Array[KnotButton] = []
	for b in _buttons:
		if not b.disabled:
			live.append(b)
	for i in live.size():
		var b := live[i]
		var prev := b.get_path_to(live[neighbor_index(i, -1, live.size())])
		var nxt := b.get_path_to(live[neighbor_index(i, 1, live.size())])
		b.focus_neighbor_top = prev
		b.focus_neighbor_bottom = nxt
		b.focus_previous = prev
		b.focus_next = nxt
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(_free_button)
	if live.is_empty():
		return
	var last := live[live.size() - 1]
	last.focus_next = last.get_path_to(_free_button)
	live[0].focus_previous = live[0].get_path_to(_free_button)
	var free := _free_button
	if free.focus_neighbor_left.is_empty() or not free.has_node(free.focus_neighbor_left) or (free.get_node(free.focus_neighbor_left) as KnotButton).disabled:
		free.focus_neighbor_left = free.get_path_to(live[0])
		free.focus_neighbor_top = free.get_path_to(live[0])
	free.focus_neighbor_right = free.get_path_to(free)
	free.focus_neighbor_bottom = free.get_path_to(free)
	free.focus_next = free.get_path_to(live[0])
	free.focus_previous = free.get_path_to(last)


func _first_button() -> KnotButton:
	var cont := get_button("continue")
	return cont if not cont.disabled else get_button("new")


func _focus_default() -> void:
	if _intro_running or _page_open:
		return
	_first_button().grab_focus_quietly()


func _ensure_focus() -> void:
	if not is_inside_tree() or _page_open:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not is_ancestor_of(focused):
		_focus_default()


func _set_interactive(on: bool) -> void:
	if not on:
		_release_focus()
	for b in _all_buttons():
		b.set_interactive(on)


func _release_focus() -> void:
	if not is_inside_tree():
		return
	var owner_control := get_viewport().gui_get_focus_owner()
	if owner_control and is_ancestor_of(owner_control):
		owner_control.release_focus()


func _all_buttons() -> Array[KnotButton]:
	var result: Array[KnotButton] = _buttons.duplicate()
	if _free_button:
		result.append(_free_button)
	return result


# --- Girdi -----------------------------------------------------------------------------------

static func _is_press(e: InputEvent) -> bool:
	if e is InputEventKey or e is InputEventMouseButton or e is InputEventJoypadButton or e is InputEventAction:
		return e.is_pressed() and not e.is_echo()
	return false


func _input(e: InputEvent) -> void:
	if _intro_running and visible and _is_press(e):
		# Basış yalnızca girişi atlar; bir butona ulaşmamalı.
		get_viewport().set_input_as_handled()
		finish_intro()


# Odak kaybolmuşsa (ör. boş bir yere tıklanınca) yön tuşları odağı geri getirir.
func _unhandled_input(event: InputEvent) -> void:
	if not is_accepting_input() or event is InputEventMouse:
		return
	if get_viewport().gui_get_focus_owner() != null:
		return
	for action in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev", &"ui_accept"]:
		if event.is_action_pressed(action):
			var target := _last_focused if is_instance_valid(_last_focused) and _last_focused.is_visible_in_tree() and not _last_focused.disabled else _first_button()
			target.grab_focus()
			get_viewport().set_input_as_handled()
			return


# --- Kart --------------------------------------------------------------------------------------

## DEVAM ET seçiliyken yanında son kayıt.
func _show_card(on: bool) -> void:
	on = on and _menu_box.visible and not _intro_running and not _page_open and _state != State.HIDDEN and _state != State.HIDING
	if on == _card_on:
		return
	if on:
		var slot := _saves().latest_slot()
		var info := _saves().slot_info(slot)
		if info.is_empty():
			return
		_card.show_save(info, slot, _saves().load_thumb(slot))
	_card_on = on
	if _card_tw and _card_tw.is_valid():
		_card_tw.kill()
	if not is_inside_tree():
		_card.visible = on
		_card.modulate.a = 1.0 if on else 0.0
		return
	_card_tw = _card.create_tween().set_parallel(true)
	if on:
		_card.visible = true
		_card_slide = -18.0
		_layout_card()
		_card_tw.tween_property(_card, "modulate:a", 1.0, 0.22)
		_card_tw.tween_method(func(v: float) -> void:
			_card_slide = v
			_layout_card(), -18.0, 0.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_card_tw.tween_property(_card, "modulate:a", 0.0, 0.16)
		_card_tw.chain().tween_callback(func() -> void: _card.visible = _card_on)


## Kart şu an gösteriliyor mu?
func is_card_shown() -> bool:
	return _card_on


# --- Animasyon durumları --------------------------------------------------------------------

func _tween_button_in(tween: Tween, b: KnotButton, delay: float) -> void:
	tween.tween_property(b, "modulate:a", button_alpha(b.disabled), 0.55).set_delay(delay)
	tween.tween_property(b, "position:x", 0.0, 0.6).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _tween_to_shown(tween: Tween, time: float) -> void:
	tween.tween_property(_logo, "modulate:a", 1.0, time)
	tween.tween_property(_sub, "modulate:a", 1.0, time)
	for b in _buttons:
		tween.tween_property(b, "modulate:a", button_alpha(b.disabled), time)
		tween.tween_property(b, "position:x", 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_free_box, "modulate:a", 1.0, time)
	tween.tween_property(_hint, "modulate:a", 0.8, time)
	tween.tween_property(_ver, "modulate:a", 0.6, time)


# Biri menüyü show_menu() yerine doğrudan "visible = true" ile açarsa da menü eksiksiz ve kullanılabilir olsun.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and _state == State.HIDDEN and is_node_ready():
		show_menu(false)
		_focus_if_open.call_deferred()


func _focus_if_open() -> void:
	if is_accepting_input():
		_ensure_focus()


func _run_auto_show() -> void:
	if _auto_show_pending:
		show_menu(true)


func _on_show_finished(id: int) -> void:
	if id != _transition_id:
		return
	_state = State.SHOWN
	transition_finished.emit()


func _on_hide_finished(id: int) -> void:
	if id != _transition_id:
		return
	_finish_hide()
	transition_finished.emit()


func _apply_hidden_look() -> void:
	_logo.modulate.a = 0.0
	_sub.modulate.a = 0.0
	for b in _buttons:
		b.modulate.a = 0.0
		b.position.x = SLIDE_FROM
	_free_box.modulate.a = 0.0
	_hint.modulate.a = 0.0
	_ver.modulate.a = 0.0


func _apply_shown_look() -> void:
	modulate.a = 1.0
	_logo.modulate.a = 1.0
	_sub.modulate.a = 1.0
	for b in _buttons:
		b.modulate.a = button_alpha(b.disabled)
		b.position.x = 0.0
	_free_box.modulate.a = 1.0
	_hint.modulate.a = 0.8
	_ver.modulate.a = 0.6


func _finish_hide() -> void:
	_state = State.HIDDEN
	_intro_running = false
	_set_interactive(false)
	visible = false
	if _curtain:
		_curtain.visible = false
	_show_card(false)
	if _toast:
		_toast.dismiss()
	# Gizliyken bile tam görünüm durumunda kalsın: biri doğrudan visible=true yaparsa menü eksiksiz görünür.
	_apply_shown_look()


func _new_tween() -> Tween:
	return create_tween().set_parallel(true).set_speed_scale(maxf(transition_speed, 0.01))


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _next_transition() -> int:
	_transition_id += 1
	return _transition_id


func _finish_transition(id: int) -> void:
	if id == _transition_id:
		transition_finished.emit()


func _saves() -> SaveSystem:
	if saves == null:
		saves = SaveSystem.new()
	return saves


func _settings() -> Node:
	return settings if settings else UIKit.settings_node()


## DEVAM ET'in yanındaki son kayıt (Tanhu 1): nerede, hangi kayıt, ne kadar sürdü ve ne zaman
## kaydedildi; kaydedildiği anın resminin üstünde.
class SaveCard extends PanelContainer:
	const THUMB := Vector2(352, 198)

	var _head: Label
	var _thumb: TextureRect
	var _empty_mark: Label
	var _place: Label
	var _title: Label
	var _meta: Label

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false
		modulate.a = 0.0
		var st := UIKit.panel_style(Color(0.03, 0.04, 0.06, 0.9), Color(UIKit.GOLD_DIM, 0.95), 2, 4, Color(0, 0, 0, 0.55), 24)
		st.content_margin_left = 22
		st.content_margin_right = 22
		st.content_margin_top = 16
		st.content_margin_bottom = 18
		add_theme_stylebox_override("panel", st)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		_head = UIKit.label("", 17, "Cinzel", 700, Color(UIKit.GOLD, 0.9), 5)
		box.add_child(_head)
		var frame := PanelContainer.new()
		var fs := StyleBoxFlat.new()
		fs.bg_color = Color(0, 0, 0, 0.6)
		fs.border_color = Color(UIKit.GOLD, 0.55)
		fs.set_border_width_all(1)
		fs.set_content_margin_all(1)
		frame.add_theme_stylebox_override("panel", fs)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(frame)
		_thumb = TextureRect.new()
		_thumb.custom_minimum_size = THUMB
		_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(_thumb)
		_empty_mark = UIKit.label("◇", 54, "Cinzel", 400, Color(UIKit.GOLD_DIM, 0.8))
		_empty_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_empty_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(_empty_mark)
		_place = UIKit.label("", 21, "Cinzel", 600, UIKit.GOLD, 1)
		_place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_place.custom_minimum_size = Vector2(THUMB.x, 0)
		box.add_child(_place)
		_title = UIKit.label("", 24, "Alegreya", 400, UIKit.PARCHMENT)
		_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_title.custom_minimum_size = Vector2(THUMB.x, 0)
		box.add_child(_title)
		_meta = UIKit.label("", 20, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
		box.add_child(_meta)

	func show_save(info: Dictionary, slot: int, thumb: Texture2D) -> void:
		_head.text = MainMenu.CARD_HEAD
		_place.text = SaveData.place_line(info)
		# Görevi olmayan bir kaydın başlığı yalnızca yeri tekrar ederdi: numarası yazılır.
		_title.text = "Otomatik kayıt" if slot == SaveSystem.AUTO_SLOT else "Kayıt #%d" % int(info.get("save_no", slot))
		_meta.text = SaveData.meta_line(info)
		_thumb.texture = thumb
		_empty_mark.visible = thumb == null
		reset_size()

	## Kartın satırları tek satırda (testler için).
	func summary() -> String:
		return "%s · %s · %s · %s" % [_place.text, _title.text, _meta.text, "resim" if _thumb.texture else "resimsiz"]
