class_name CharacterCreator
extends Control
## Oluşturucu «Yola Hazırlan» (K36; story.md §6): Köprü 1'den sonra, rehin verilme kararının ardından Mete 20
## yaşındadır. Oyuncu görünüşünü, kökenini, zorluğu ve pelerin boyasını seçer; önizleme rehine kılığını gösterir:
## Kışlak Kaftanı ve Kışlak Pelerini (CharacterOptions.start_outfit, start_cape; CharacterAvatar). Oluşturucu saat okumaz.
##
## Solda karakterin canlı 3B önizlemesi (CreatorTurntable), sağda parşömen kâğıdı üzerinde her
## seçenek için bir satır (CreatorRow) bulunur: önce görünüş, bir mürekkep ayraçtan sonra yolun satırları
## (köken, zorluk, boya; köken ve zorluğun altında sözü ve etkisi, boyada kumaş örnekleri). Ekran bir
## CharacterProfile kopyası üzerinde çalışır: her değişiklik profili günceller ve önizlemedeki karaktere
## anında uygulanır (boya değişince pelerin aynı karede değişir). Modelin yüzüne çizili özelliklerin satırları
## (sakal, bıyık, göz biçimi) Meshy modelinde gizlidir; parşömen görünen satırlara göre boylanır.
##
## Kullanım:
##   var creator := preload("res://scenes/ui/character_creator.tscn").instantiate()
##   add_child(creator)
##   creator.open(profil)               # null → kayıtlı profil ya da varsayılan
##   creator.accepted.connect(func(p): p.save(); ...)
##   creator.cancelled.connect(...)     # Geri Al'a geri alınacak bir şey kalmadan basılınca
##
## Klavye: ↑/↓ (W/S) satır seçer, ←/→ (A/D) değeri değiştirir, E/Enter (sayısal tuş takımındaki
## Enter da) onaylar, Esc geri alır, Tab kamerayı tam boy / yakın plan arasında değiştirir (fare
## tekerleği ya da dokunmatik yüzeyde iki parmakla kaydırma da aynı işi görür).
## Oyun kolu: yön tuşları / sol çubuk (her itiş bir adım), A onaylar, B geri alır.
## Geri alınacak değişiklik kalmamışken Esc'ye basmak ekrandan çıkmak (cancelled) demektir.
## Başlık bandı, parşömen panel ve ipucu yazısı arayüz ölçeğinde (UIKit.ui_k) çizilir: çapalandıkları köşe
## ya da kenar yerinde kalır, yüksek çözünürlükte küçülürler; 3B önizleme ekranla birlikte kalır.

## Oyuncu "Onayla"ya bastı. Profil, düzenlenen profilin bağımsız bir kopyasıdır; kaydetmek çağıranın işidir.
signal accepted(profile: CharacterProfile)
## Oyuncu geri alınacak bir şey yokken "Geri Al"a bastı (ekrandan çıkmak istiyor).
signal cancelled

## Geri alma geçmişinin en fazla kaç adım tutacağı.
const MAX_HISTORY := 64
## Başlık ve alt yazı: Mete'nin yaşı ve rehin verilme kararının tarihi (Dailin, 10 Eylül MÖ 213; story.md §6).
const TITLE_TEXT := "YOLA HAZIRLAN"
const SUBTITLE_TEXT := "Mete · 20 yaşında · 10 Eylül MÖ 213"
## Parşömenin yerleşimi (yerel piksel): satırların üstü, satırlarla düğmeler arası, düğmenin boyu, düğmelerin altı.
## Parşömenin alt kenarı sahnedeki yerinde kalır, boyu görünen satırlara göre yukarı doğru uzar.
const ROWS_TOP := 26.0
const BUTTON_GAP := 28.0
const BUTTON_HEIGHT := 62.0
const PANEL_BOTTOM_PAD := 56.0
## İki "üzerine gelme" sesi arasındaki en kısa süre (ms). Fare yeni bir satırın okuna girince hem
## satır hem ok ses ister; bu süre içindeki ikinci ses çalınmaz.
const HOVER_SOUND_GAP_MS := 60

## Sahne tek başına açılınca (ör. ekran görüntüsü alırken) kendiliğinden open() çağrılsın mı?
@export var auto_open := true

@onready var _turntable: CreatorTurntable = %Turntable
@onready var _rows_box: VBoxContainer = %Rows
@onready var _undo_button: CreatorBrushButton = %UndoButton
@onready var _accept_button: CreatorBrushButton = %AcceptButton
@onready var _panel_content: Control = %Content
@onready var _title_banner: Control = %TitleBanner
@onready var _panel: Control = %Panel
@onready var _preview_area: Control = %PreviewArea
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _hint: Label = %Hint

var _profile: CharacterProfile
var _history: Array[CharacterProfile] = []
var _rows: Array[CreatorRow] = []
var _focus := 0
var _active := false
var _intro_tween: Tween
var _hint_tween: Tween
## Analog çubuğun her ekseni için son komut (eksen → &"up" / &"down" / ... / &"").
var _stick_commands := {}
var _last_hover_sound_ms := -HOVER_SOUND_GAP_MS
## Görünen satır sayısı (parşömen buna göre boylanır).
var _shown_rows := -1


func _ready() -> void:
	InputSetup.ensure_actions()
	_build_rows()
	_undo_button.pressed.connect(_on_undo_pressed)
	_accept_button.pressed.connect(_on_accept_pressed)
	for button: CreatorBrushButton in [_undo_button, _accept_button]:
		button.mouse_entered.connect(_on_control_hovered)
	_turntable.view_changed.connect(_on_view_changed)
	_title.text = TITLE_TEXT
	_subtitle.text = SUBTITLE_TEXT
	UIKit.on_ui_scale_changed(self, _apply_ui_scale)
	_apply_ui_scale()
	if _profile:
		_release_other_focus()
		_apply_profile()
		_play_intro()
	elif auto_open:
		open()


## Ekran gizliyken açılıp sonra gösterilirse açılış animasyonu görünür olduğu anda oynasın.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and _active and is_visible_in_tree():
		_play_intro()


# --- Genel arayüz -------------------------------------------------------------------

## Düzenlemeyi başlatır. profile null ise kayıtlı profil (yoksa varsayılan) kullanılır.
## Verilen profil değiştirilmez; ekran bir kopyası üzerinde çalışır. Geri alma geçmişi sıfırlanır,
## kamera tam boy ve açılış açısına döner.
func open(profile: CharacterProfile = null) -> void:
	# Kurulum bitene kadar ekran etkin sayılmaz: kamera sıfırlanırken ses çalınmaz, yazılar anında değişir.
	_active = false
	_profile = (profile if profile else CharacterProfile.load_or_default()).copy()
	_history.clear()
	_stick_commands.clear()
	_focus = 0
	if is_node_ready():
		_release_other_focus()
		_reset_view()
		_apply_profile()
		_play_intro()
	_active = true


## Alanı bir adım ileri (+1) ya da geri (-1) çevirir (◀ ▶ okları, ←/→ tuşları). Bu karakterde
## ayarlanamayan alan (ör. Meshy modelinin yüzüne çizili sakal) değişmez.
func change(field: StringName, step: int) -> void:
	if _profile == null or step == 0 or not field in CharacterOptions.FIELDS or not is_adjustable(field):
		return
	var before := _profile.copy()
	_profile.cycle(field, step)
	_commit(before, field, signi(step))


## Renk alanında belirli bir rengi seçer (renk örneğine tıklama). Listede olmayan bir indeks
## (ör. -1 ya da renk sayısından büyük) yok sayılır; başa/sona sarılıp başka bir renk seçilmez.
func select_color(field: StringName, index: int) -> void:
	if _profile == null or not field in CharacterOptions.COLOR_FIELDS:
		return
	if index < 0 or index >= CharacterOptions.count(field, _profile.body_type):
		return
	var before := _profile.copy()
	_profile.set_value(field, index)
	_commit(before, field, signi(index - before.get_value(field)))


## Son değişikliği geri alır. Geri alınacak bir şey yoksa cancelled yayar ve false döner.
## Geri alınan alanın satırı odaklanır ve değeri kısa bir kaymayla değişir; oyuncu neyin geri
## alındığını görür.
func undo() -> bool:
	if _history.is_empty():
		_play_ui(&"click")
		_active = false
		cancelled.emit()
		return false
	var undone := _profile
	_profile = _history.pop_back()
	_apply_profile()
	var field := CharacterCreator.first_changed_field(undone, _profile)
	var row := get_row(field)
	if row:
		row.bump(signi(_profile.get_value(field) - undone.get_value(field)))
		_set_focus(_nearest_adjustable(_rows.find(row)), false)
	_play_ui(&"click")
	return true


## Seçimleri onaylar: accepted sinyaliyle profilin bir kopyasını gönderir.
func accept() -> void:
	if _profile == null:
		return
	_active = false
	_play_ui(&"whoosh")
	accepted.emit(_profile.copy())


## Düzenlenen profil (canlı nesne; değiştirmek için change / select_color kullanın).
func get_profile() -> CharacterProfile:
	return _profile


## Önizlemedeki karakter.
func get_avatar() -> CharacterAvatar:
	return _turntable.get_avatar() if _turntable else null


func get_turntable() -> CreatorTurntable:
	return _turntable


## Seçenek satırı sayısı (CharacterOptions.FIELDS ile aynı).
func get_row_count() -> int:
	return _rows.size()


## Seçenek satırları (FIELDS sırasıyla).
func get_rows() -> Array[CreatorRow]:
	return _rows


## Alanın satırı (yoksa null).
func get_row(field: StringName) -> CreatorRow:
	for row in _rows:
		if row.field == field:
			return row
	return null


## Klavye odağındaki satırın indeksi.
func get_focus_index() -> int:
	return _focus


## Geri alınabilecek adım sayısı.
func get_history_size() -> int:
	return _history.size()


## Ekran şu an girdi kabul ediyor mu? (open() ile açılır; onay/çıkıştan sonra kapanır.)
func is_active() -> bool:
	return _active


## Klavye odağını step satır kaydırır (başa/sona sarar); ayarlanamayan satırlar atlanır.
func move_focus(step: int) -> void:
	_set_focus(CharacterCreator.step_focus(_focus, step, _adjustable_flags()))


## Alan önizlemedeki karakterde ayarlanabilir mi? (Meshy modellerinde yüze çizili özellikler ayarlanamaz; pelerini
## olmayan modelde boya ayarlanamaz.)
func is_adjustable(field: StringName) -> bool:
	var avatar := get_avatar()
	return CharacterOptions.is_adjustable(field, avatar != null and avatar.has_meshy_model(), avatar == null or avatar.has_cape())


# --- Saf yardımcılar (test edilebilir) ----------------------------------------------

## Odak indeksini step kadar kaydırır; listenin sonundan başına (ve tersi) sarar.
static func wrap_focus(current: int, step: int, count: int) -> int:
	if count <= 0:
		return 0
	return wrapi(current + step, 0, count)


## Odağı step satır kaydırır ama kapalı (enabled[i] = false) satırları atlar; başa/sona sarar.
## Hiçbir satır açık değilse ya da step 0 ise odak yerinde kalır.
static func step_focus(current: int, step: int, enabled: Array[bool]) -> int:
	var count := enabled.size()
	if count <= 0:
		return 0
	var index := clampi(current, 0, count - 1)
	if step == 0 or not enabled.has(true):
		return index
	for i in absi(step):
		index = wrapi(index + signi(step), 0, count)
		while not enabled[index]:
			index = wrapi(index + signi(step), 0, count)
	return index


## Bir girdi olayını ekran komutuna çevirir: &"up", &"down", &"left", &"right", &"accept", &"undo",
## &"view" (kamera çerçevesi) ya da ilgisizse &"". Yön tuşları basılı tutulunca tekrarlar (echo);
## onay, geri alma ve çerçeve değiştirme tekrarlamaz.
static func command_for_event(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if _pressed(event, [&"undo", &"ui_cancel"], false):
		return &"undo"
	if _pressed(event, [&"accept"], false) or CharacterCreator._is_keypad_enter(event):
		return &"accept"
	# Oyun kolu: A onaylar, B geri alır (varsayılan ui_* eylemlerinde kol düğmeleri yok).
	if event is InputEventJoypadButton and event.pressed:
		match (event as InputEventJoypadButton).button_index:
			JOY_BUTTON_A:
				return &"accept"
			JOY_BUTTON_B:
				return &"undo"
	if _pressed(event, [&"ui_focus_next"], false):
		return &"view"
	if _pressed(event, [&"ui_up", &"move_forward"], true):
		return &"up"
	if _pressed(event, [&"ui_down", &"move_back"], true):
		return &"down"
	if _pressed(event, [&"ui_left", &"move_left"], true):
		return &"left"
	if _pressed(event, [&"ui_right", &"move_right"], true):
		return &"right"
	return &""


## Analog çubuk itili tutulurken her küçük kıpırtı yeni bir hareket olayı üretir. Aynı eksende
## bir önceki olayla aynı komutu veren olay tekrardır ve yok sayılmalıdır; çubuk bırakılınca
## (komut &"") ya da ters yöne itilince yeni bir adım atılır.
static func is_stick_repeat(previous: StringName, current: StringName) -> bool:
	return current != &"" and current == previous


## İki profil arasında değeri farklı olan ilk alan (FIELDS sırasıyla); fark yoksa &"".
static func first_changed_field(a: CharacterProfile, b: CharacterProfile) -> StringName:
	if a == null or b == null:
		return &""
	for field in CharacterOptions.FIELDS:
		if a.get_value(field) != b.get_value(field):
			return field
	return &""


## Bir "üzerine gelme" sesi şimdi çalınabilir mi? (Son sesten bu yana en az HOVER_SOUND_GAP_MS geçti mi?)
static func hover_sound_allowed(now_ms: int, last_ms: int) -> bool:
	return now_ms - last_ms >= HOVER_SOUND_GAP_MS


static func _pressed(event: InputEvent, actions: Array[StringName], allow_echo: bool) -> bool:
	for action in actions:
		if InputMap.has_action(action) and event.is_action_pressed(action, allow_echo):
			return true
	return false


## Sayısal tuş takımındaki Enter ("accept" eylemi yalnızca ana Enter'ı ve E'yi içerir).
static func _is_keypad_enter(event: InputEvent) -> bool:
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo \
		and (key.keycode == KEY_KP_ENTER or key.physical_keycode == KEY_KP_ENTER)


# --- Girdi ----------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _active or not is_visible_in_tree():
		return
	var command := CharacterCreator.command_for_event(event)
	if event is InputEventJoypadMotion:
		var axis := (event as InputEventJoypadMotion).axis
		var previous: StringName = _stick_commands.get(axis, &"")
		_stick_commands[axis] = command
		if CharacterCreator.is_stick_repeat(previous, command):
			get_viewport().set_input_as_handled()
			return
	if command == &"":
		return
	get_viewport().set_input_as_handled()
	match command:
		&"up":
			move_focus(-1)
		&"down":
			move_focus(1)
		&"left":
			_change_focused(-1)
		&"right":
			_change_focused(1)
		&"accept":
			_accept_button.pulse()
			accept()
		&"undo":
			_undo_button.pulse()
			undo()
		&"view":
			_turntable.set_close_up(not _turntable.is_close_up())


func _change_focused(step: int) -> void:
	if _rows.is_empty():
		return
	change(_rows[_focus].field, step)


func _on_undo_pressed() -> void:
	if _active:
		undo()


func _on_accept_pressed() -> void:
	if _active:
		accept()


# --- İç işler ---------------------------------------------------------------------------

## Her alan için bir satır kurar (FIELDS sırasıyla) ve sinyallerini bağlar.
func _build_rows() -> void:
	for child in _rows_box.get_children():
		child.queue_free()
	_rows.clear()
	for field in CharacterOptions.FIELDS:
		var row := CreatorRow.new()
		row.setup(field)
		row.step_requested.connect(_on_row_step)
		row.color_requested.connect(_on_row_color)
		row.hovered.connect(_on_row_hovered)
		_rows_box.add_child(row)
		_rows.append(row)
		var swatches := row.get_swatches()
		if swatches:
			swatches.swatch_hovered.connect(func(_i: int) -> void: _on_control_hovered())
		for arrow in row.get_arrows():
			arrow.mouse_entered.connect(_on_control_hovered)
	_set_focus(0, false)
	_layout_panel()


## Değişikliği geçmişe ekler ve uygular. Profil gerçekten değişmediyse hiçbir şey yapmaz.
func _commit(before: CharacterProfile, field: StringName, direction: int) -> void:
	if _profile.equals(before):
		return
	_history.append(before)
	while _history.size() > MAX_HISTORY:
		_history.pop_front()
	_apply_profile()
	var row := get_row(field)
	if row:
		row.bump(direction)
	_set_focus(_rows.find(row), false)
	_play_ui(&"click")


## Profili önizlemeye ve tüm satırlara uygular (saç adları vücut tipine bağlı olduğu için hepsi).
## Satırların ayarlanabilirliği gösterilen modele göre güncellenir; odak kapanan bir satırda kaldıysa
## sonraki açık satıra geçer.
func _apply_profile() -> void:
	if _profile == null:
		return
	var avatar := get_avatar()
	if avatar:
		avatar.apply_profile(_profile)
	var shown := 0
	for row in _rows:
		row.adjustable = is_adjustable(row.field)
		row.visible = row.adjustable or not CharacterOptions.hides_when_locked(row.field)
		row.refresh(_profile)
		shown += 1 if row.visible else 0
	_set_focus(_nearest_adjustable(_focus), false)
	if shown != _shown_rows:
		_layout_panel()


## Parşömeni görünen satırlara göre boylar: düğmeler satırların altına gelir, alt kenar yerinde kalır, üst kenar yukarı
## uzar (ya da kısalır). Arayüz ölçeğinin çapası yeni boya göre yeniden kurulur.
func _layout_panel() -> void:
	var rows_height := 0.0
	_shown_rows = 0
	for row in _rows:
		if row.visible:
			rows_height += row.custom_minimum_size.y
			_shown_rows += 1
	_rows_box.offset_top = ROWS_TOP
	_rows_box.offset_bottom = ROWS_TOP + rows_height
	var buttons_y := ROWS_TOP + rows_height + BUTTON_GAP
	for button: CreatorBrushButton in [_undo_button, _accept_button]:
		button.offset_top = buttons_y
		button.offset_bottom = buttons_y + BUTTON_HEIGHT
	_panel.offset_top = _panel.offset_bottom - (buttons_y + BUTTON_HEIGHT + PANEL_BOTTOM_PAD)
	_apply_ui_scale()


## Satırların ayarlanabilirlik listesi (FIELDS sırasıyla).
func _adjustable_flags() -> Array[bool]:
	var flags: Array[bool] = []
	for row in _rows:
		flags.append(row.adjustable)
	return flags


## index satırı ayarlanabiliyorsa kendisi, değilse ondan sonraki ilk ayarlanabilir satır.
func _nearest_adjustable(index: int) -> int:
	if index < 0 or index >= _rows.size() or _rows[index].adjustable:
		return index
	return CharacterCreator.step_focus(index, 1, _adjustable_flags())


func _set_focus(index: int, with_sound: bool = true) -> void:
	if _rows.is_empty() or index < 0:
		return
	var changed := index != _focus
	_focus = clampi(index, 0, _rows.size() - 1)
	for i in _rows.size():
		_rows[i].focused = i == _focus
	if changed and with_sound:
		_play_ui(&"hover")


func _on_row_step(field: StringName, step: int) -> void:
	if _active:
		change(field, step)


func _on_row_color(field: StringName, index: int) -> void:
	if _active:
		select_color(field, index)


## Kamera çerçevesi değişince ipucu yazısını günceller (alt yazı Mete'nin yaşı ve tarihidir, kadrajla değişmez).
## Oyuncu değiştirdiyse kısa bir geçiş ve ses olur; ekran etkin değilken (ör. open() kamerayı sıfırlarken) anında.
func _on_view_changed(close_up: bool) -> void:
	var animated := _active and is_visible_in_tree()
	if animated:
		_play_ui(&"hover")
	_show_hint(close_up, animated)


## Kamerayı tam boy ve açılış açısına döndürür; ipucu hemen buna uyar.
func _reset_view() -> void:
	_turntable.reset_rotation(true)
	_turntable.set_close_up(false, true)
	_show_hint(false, false)


## İpucu yazısını çerçeveye uydurur: yakın planda karakter alt köşeyi kaplar, ipucu o sırada gizlenir.
func _show_hint(close_up: bool, animated: bool) -> void:
	if _hint_tween:
		_hint_tween.kill()
	var hint_alpha := 0.0 if close_up else 1.0
	if not animated:
		_hint.modulate.a = hint_alpha
		return
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint, ^"modulate:a", hint_alpha, 0.3)


func _on_row_hovered(field: StringName) -> void:
	var row := get_row(field)
	if row and row.adjustable and _active:
		_set_focus(_rows.find(row))


## Fare bir oka, renk örneğine ya da düğmeye geldi. Onaydan / çıkıştan sonra (ekran kararırken)
## ses çalınmaz; ekran open() ile yeniden açılana kadar tepki vermez.
func _on_control_hovered() -> void:
	if _active:
		_play_ui(&"hover")


## Açılış animasyonu: önizleme ve başlık belirir, kâğıt sağdan kayarak gelir.
func _play_intro() -> void:
	if _intro_tween:
		_intro_tween.kill()
	_panel_content.position.x = 56.0
	_panel_content.modulate.a = 0.0
	_title_banner.modulate.a = 0.0
	_preview_area.modulate.a = 0.0
	_intro_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(_preview_area, ^"modulate:a", 1.0, 0.7)
	_intro_tween.tween_property(_title_banner, ^"modulate:a", 1.0, 0.6).set_delay(0.1)
	_intro_tween.tween_property(_panel_content, ^"position:x", 0.0, 0.6).set_delay(0.08)
	_intro_tween.tween_property(_panel_content, ^"modulate:a", 1.0, 0.45).set_delay(0.08)


## Başlık bandını, paneli ve ipucu yazısını arayüz ölçeğinde, çapalarının çevresinde çizer. Parşömen o ölçekte ekrandan taşacaksa
## (K104'ün büyük ölçekleri: 1080 satırda en çok ≈%108 sığar) üçü birlikte parşömenin sığdığı ölçekte çizilir (UIKit.anchor_fit_k).
func _apply_ui_scale() -> void:
	var k := UIKit.anchor_fit_k(_panel, UIKit.ui_k())
	for c: Control in [_title_banner, _panel, _hint]:
		UIKit.scale_at_anchor(c, k)


## Ekranın arkasında klavye odağını tutan bir düğme kalmışsa (ör. hâlâ görünür olan ana menü)
## ok tuşları ve Enter önce ona gider, bu ekrana hiç ulaşmaz. Açılışta odak bırakılır; bu ekranın
## kendi denetimleri odak almaz (girdiyi _unhandled_input ile işler).
func _release_other_focus() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.gui_release_focus()


## Arayüz sesi (AudioManager yoksa, ör. testlerde, sessizce atlanır). Art arda gelen "üzerine
## gelme" seslerinden yalnızca ilki çalınır (bkz. HOVER_SOUND_GAP_MS).
func _play_ui(kind: StringName) -> void:
	if kind == &"hover":
		var now := Time.get_ticks_msec()
		if not CharacterCreator.hover_sound_allowed(now, _last_hover_sound_ms):
			return
		_last_hover_sound_ms = now
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		audio.play_ui(kind)
