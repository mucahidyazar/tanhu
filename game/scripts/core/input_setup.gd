class_name InputSetup
extends RefCounted
## Oyun eylemlerini (WASD, koşma, kamera döndürme...) kodla kaydeder ve oyuncunun tuş atamasını uygular.
## project.godot'u elle düzenlemeye gerek kalmaz; Main açılışta ensure_actions() çağırır.
## Fiziksel tuşlar kullanılır: klavye düzeni (Türkçe Q, F...) ne olursa olsun aynı yerdeki tuşlar çalışır; tuşun ekrandaki adı
## dizilişten okunur (ControlsPage.event_name, DisplayServer.keyboard_get_label_from_physical).
##
## Boşluk iki eylemindir, bağlamları ayrıdır (CONTEXTS): oyunda zıplama (jump; oyuncu denetleyicisi yalnız oyuncu etkinken okur),
## menüde Destan Kitabı'nın tanıtımı (book_intro; kitap yalnız duraklatmada ve açılış ekranında açıktır, oyuncu o an durur). İkisi
## aynı anda dinlenmez: kitap açıkken dünya duraklatılmıştır, oyundayken kitap ağaçta değildir. Oyun kolunda da öyle: A oyunda zıplar,
## menüde seçer (ui_accept). I oyun içi HUD'un Envanter'ini açar, J ve M yolculuğun kitabını GÖREVLER ve HARİTA sayfasında açar
## (GameplayHud, GameMenu); ikisi de açıkken oyun durur.
##
## Kamera (K27, K39; godot.md §5.3): Q / E ile , / . birlikte döndürür (geçiş dönemi: Q ve E act-1-p3'te varsayılandan çıkar), ; ve '
## kamerayı yükseltir ve alçaltır (eğim), - ve = yaklaştırır ve uzaklaştırır, / varsayılana döndürür (Türkçe Q'da Ş, İ, *, -, nokta).
##
## Tuş ataması (K39, godot.md §5.6): oyuncunun değiştirdiği eylemlerin olay listesi GameSettings'in [input] bölümünde düz sözlük olarak
## durur ({"type": "key", "physical": 87}, {"type": "mouse", "button": 8}, {"type": "joy_button", "index": 0}); apply_bindings() açılışta
## varsayılanın üstüne yazar, bilinmeyen eylem ya da bozuk satır sessizce atlanır. rebind() tuşu başka bir eylemden alırsa o eylem
## değiştirilen eski tuşu alır (takas): eski eylem boş kalmaz. reset_bindings() bütün atamayı siler. Esc (pause, undo) atanmaz: geri
## dönüşün tuşu her zaman yerindedir.

## Eylem adı → fiziksel tuşlar (varsayılan).
const KEY_ACTIONS := {
	&"move_forward": [KEY_W, KEY_UP],
	&"move_back": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"sprint": [KEY_SHIFT],
	&"camera_left": [KEY_Q, KEY_COMMA],
	&"camera_right": [KEY_E, KEY_PERIOD],
	# Eğim (K39): basılı tutuldukça 40°/sn; «yükselt» kamerayı tepeye doğru diker, «alçalt» ufka doğru yatırır.
	&"camera_pitch_up": [KEY_SEMICOLON],
	&"camera_pitch_down": [KEY_APOSTROPHE],
	# Uzaklık (K39): - yaklaştırır, = uzaklaştırır (14–40 m; K98).
	&"camera_zoom_in": [KEY_MINUS],
	&"camera_zoom_out": [KEY_EQUAL],
	# Kısa basış: kuzey, oturum eğimi 0, başlangıç uzaklığı (28 m, çocukta 22 m), 0,5 sn'de (godot.md §5.2).
	&"camera_reset": [KEY_SLASH],
	&"accept": [KEY_E, KEY_ENTER],
	&"undo": [KEY_ESCAPE],
	&"pause": [KEY_ESCAPE],
	&"toggle_fullscreen": [KEY_F11],
	# Destan Kitabı'nda kişinin tanıtımını çalar ya da susturur (hoparlör; godot.md §3.8, K86). Yalnız menüde.
	&"book_intro": [KEY_SPACE],
	# Oyunda zıplama (hareket; oyuncu denetleyicisi okur). Yalnız oyunda.
	&"jump": [KEY_SPACE],
	# Oyun içi HUD'un sayfaları (GameplayHud).
	&"inventory": [KEY_I],
	&"journal": [KEY_J],
	&"map": [KEY_M],
	# Bekle tekeri (WaitWheel; time.md §7.1) ve basılı G «Yükü Bırak» (0,6 sn; kısa basış ileride Ku'ya «Bak»; economy.md §4.2).
	&"wait": [KEY_T],
	&"drop_load": [KEY_G],
	# Ateş (survival.md §2.3, K45): Y ateşin 3 m içinde yakıt ekler (basılı 0,5 sn'de bir), uzakta yer seçer; F kısa basışta sapan, ateşte
	# basılı söndürür (1 sn) ya da Kor'da Küle Yatır (2 sn; K35).
	&"fire": [KEY_Y],
	&"sling": [KEY_F],
}
## Eylem adı → oyun kolu düğmeleri (varsayılan; kolun bütün ataması Yol Haritası'nın release-p2 fazındadır).
const JOY_ACTIONS := {
	&"book_intro": [JOY_BUTTON_Y],
	&"jump": [JOY_BUTTON_A],
	&"map": [JOY_BUTTON_BACK],
}
## Eylemin dinlendiği bağlam: "game" (oyuncu etkinken), "menu" (kitaplar, açılış ekranı), "any". Aynı tuşu paylaşan iki eylemin
## bağlamı ayrı olmalıdır (tests/unit/test_input_setup.gd sınar).
const CONTEXTS := {
	&"move_forward": "game", &"move_back": "game", &"move_left": "game", &"move_right": "game",
	&"sprint": "game", &"camera_left": "game", &"camera_right": "game", &"camera_pitch_up": "game", &"camera_pitch_down": "game",
	&"camera_zoom_in": "game", &"camera_zoom_out": "game", &"camera_reset": "game", &"accept": "any", &"undo": "menu",
	&"pause": "game", &"toggle_fullscreen": "any", &"book_intro": "menu", &"jump": "game",
	&"inventory": "game", &"journal": "game", &"map": "game", &"wait": "game", &"drop_load": "game",
	&"fire": "game", &"sling": "game",
}
## Bilerek aynı tuşu paylaşan eylem çiftleri: E'nin kamera ve onay işi (godot.md §5.3: E'nin işi varken kamera dönmez), Esc'in geri al ve
## duraklat işi. Atamada da çakışma sayılmaz.
const ALLOWED_PAIRS := [[&"camera_right", &"accept"], [&"undo", &"pause"]]
## Eylemin oyuncuya görünen adı (Tuşlar sayfası, çakışma sorusu «Şuna da bağlı: {eylem}»).
const LABELS := {
	&"move_forward": "İleri yürü", &"move_back": "Geri yürü", &"move_left": "Sola yürü", &"move_right": "Sağa yürü",
	&"sprint": "Koş", &"jump": "Zıpla", &"accept": "Kullan · onayla",
	&"inventory": "Envanter", &"journal": "Görevler", &"map": "Harita", &"wait": "Bekle", &"drop_load": "Yükü bırak (basılı)",
	&"fire": "Ateş · yakıt ekle", &"sling": "Sapan · ateşi söndür (basılı)",
	&"camera_left": "Kamerayı sola döndür", &"camera_right": "Kamerayı sağa döndür",
	&"camera_pitch_up": "Kamerayı yükselt", &"camera_pitch_down": "Kamerayı alçalt",
	&"camera_zoom_in": "Yaklaş", &"camera_zoom_out": "Uzaklaş", &"camera_reset": "Kamerayı varsayılana döndür",
	&"toggle_fullscreen": "Tam ekran", &"book_intro": "Destan Kitabı'nda tanıtım",
	&"pause": "Oyun menüsü", &"undo": "Geri al",
}
## Tuşlar sayfasının «Atama» görünümünde değiştirilebilen eylemler, gruplarıyla ve sırasıyla.
const REBIND_GROUPS := [
	["YÜRÜRKEN", [&"move_forward", &"move_back", &"move_left", &"move_right", &"sprint", &"jump", &"accept", &"inventory", &"journal", &"map",
		&"wait", &"drop_load"]],
	["KAMERA", [&"camera_left", &"camera_right", &"camera_pitch_up", &"camera_pitch_down", &"camera_zoom_in", &"camera_zoom_out", &"camera_reset"]],
	["MENÜ", [&"toggle_fullscreen", &"book_intro"]],
]
## Kayıtta kabul edilen fare düğmeleri: sol, sağ, orta ve yan düğmeler (tekerlek olayı eylem olmaz).
const MOUSE_BUTTONS := [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]

## Oyuncunun ataması: eylem → olaylar (yalnız varsayılandan ayrılan eylemler). ensure_actions() bunları korur.
static var _overrides: Dictionary = {}


## Eksik eylemleri ekler; tekrar çağrılması güvenlidir. Oyuncunun atadığı eylem atamasıyla kurulur (varsayılan tuşu geri gelmez);
## öteki eylemlerin eksik varsayılan tuşları geri eklenir, elle eklenmiş başka tuşlar korunur.
static func ensure_actions() -> void:
	for action in managed_actions():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if _overrides.has(action):
			_set_map_events(action, _overrides[action])
			continue
		for event in default_events(action):
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


## InputSetup'ın kurduğu bütün eylemler (klavye ve oyun kolu tablolarının birleşimi).
static func managed_actions() -> Array[StringName]:
	var out: Array[StringName] = []
	for action in KEY_ACTIONS:
		out.append(action)
	for action in JOY_ACTIONS:
		if not out.has(action):
			out.append(action)
	return out


## Atama görünümünde değiştirilebilen eylemler (sırayla).
static func rebindable_actions() -> Array[StringName]:
	var out: Array[StringName] = []
	for group: Array in REBIND_GROUPS:
		for action: StringName in group[1]:
			out.append(action)
	return out


static func is_rebindable(action: StringName) -> bool:
	return rebindable_actions().has(action)


## Eylemin varsayılan olayları: önce klavye tuşları, sonra oyun kolu düğmeleri.
static func default_events(action: StringName) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	for key in KEY_ACTIONS.get(action, []):
		out.append(key_event(key))
	for button in JOY_ACTIONS.get(action, []):
		var event := InputEventJoypadButton.new()
		event.button_index = button
		out.append(event)
	return out


## Eylemin şu anki olayları (tuş haritasından; eylem yoksa boş).
static func events_of(action: StringName) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	if InputMap.has_action(action):
		out.assign(InputMap.action_get_events(action))
	return out


## Fiziksel tuş olayı (klavye düzeninden bağımsız).
static func key_event(physical: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	return event


# --- Tuş ataması (K39, godot.md §5.6) -------------------------------------------------------------------

## Eylemin olaylarını değiştirir ve atamaya yazar; olaylar varsayılanla aynıysa atama kaydı silinir.
static func set_binding(action: StringName, events: Array) -> void:
	if not managed_actions().has(action):
		return
	var list: Array[InputEvent] = []
	for event in events:
		if event is InputEvent:
			list.append(event)
	if _same_events(list, default_events(action)):
		_overrides.erase(action)
	else:
		_overrides[action] = list
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	_set_map_events(action, list)


## Olayı eyleme bağlar: eylemin aynı türdeki (klavye, fare, oyun kolu) ilk olayının yerine geçer, yoksa eklenir. Olay aynı bağlamda başka
## eylemlere de bağlıysa onlardan alınır ve onlar değiştirilen eski olayı alır (takas; eski eylem boş kalmaz). Eski olay yoksa ve öteki eylem
## boş kalacaksa ona dokunulmaz (olay ikisinde de kalır). Döner: {"changed": bool, "old": eski olay ya da null, "swapped": [eylemler]}.
static func rebind(action: StringName, event: InputEvent) -> Dictionary:
	var result := {"changed": false, "old": null, "swapped": []}
	if event == null or not is_rebindable(action) or event_to_dict(event).is_empty():
		return result
	var events := events_of(action)
	for e in events:
		if same_event(e, event):
			return result
	var kind := event_kind(event)
	var slot := -1
	for i in events.size():
		if event_kind(events[i]) == kind:
			slot = i
			break
	var old: InputEvent = events[slot] if slot >= 0 else null
	if slot >= 0:
		events[slot] = event
	else:
		events.append(event)
	var swapped: Array[StringName] = []
	for other in conflicts_for(action, event):
		var theirs := events_of(other)
		var kept: Array[InputEvent] = []
		var at := -1
		for i in theirs.size():
			if same_event(theirs[i], event):
				if at < 0:
					at = kept.size()
			else:
				kept.append(theirs[i])
		if old != null:
			var has_old := false
			for e in kept:
				if same_event(e, old):
					has_old = true
			if not has_old:
				kept.insert(clampi(at, 0, kept.size()), old)
		if kept.is_empty():
			continue
		set_binding(other, kept)
		swapped.append(other)
	set_binding(action, events)
	result["changed"] = true
	result["old"] = old
	result["swapped"] = swapped
	return result


## Bütün atamayı siler: her eylem varsayılan olaylarına döner.
static func reset_bindings() -> void:
	_overrides.clear()
	for action in managed_actions():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_set_map_events(action, default_events(action))


## Oyuncunun ataması, kayda yazılacak düz sözlük olarak: {eylem adı: [olay sözlüğü, ...]} (yalnız varsayılandan ayrılanlar).
static func bindings() -> Dictionary:
	var out := {}
	for action: StringName in _overrides:
		var list: Array = []
		for event: InputEvent in _overrides[action]:
			var d := event_to_dict(event)
			if not d.is_empty():
				list.append(d)
		out[String(action)] = list
	return out


## Kayıttan gelen atamayı uygular (açılışta GameSettings çağırır): bilinmeyen eylem, değiştirilemeyen eylem (Esc), bozuk satır ve olayı
## kalmayan eylem sessizce atlanır. Sözlükte olmayan eylemlere dokunulmaz. Döner: uygulanan atamanın temizlenmiş hâli (bindings() biçiminde).
static func apply_bindings(data: Variant) -> Dictionary:
	var clean := sanitize_bindings(data)
	for action_name: String in clean:
		var events: Array[InputEvent] = []
		for d: Dictionary in clean[action_name]:
			events.append(event_from_dict(d))
		set_binding(StringName(action_name), events)
	ensure_actions()
	return bindings()


## Kayıttaki atamanın geçerli kısmı (saf): {eylem adı: [olay sözlüğü, ...]}; geçersiz her şey düşer.
static func sanitize_bindings(data: Variant) -> Dictionary:
	var out := {}
	if not data is Dictionary:
		return out
	var rebindable := rebindable_actions()
	for key: Variant in data:
		if not (key is String or key is StringName) or not rebindable.has(StringName(key)):
			continue
		var rows: Variant = data[key]
		if not rows is Array:
			continue
		var list: Array = []
		var seen: Array[InputEvent] = []
		for row: Variant in rows:
			var event := event_from_dict(row)
			if event == null:
				continue
			var dup := false
			for e in seen:
				if same_event(e, event):
					dup = true
			if dup:
				continue
			seen.append(event)
			list.append(event_to_dict(event))
		if not list.is_empty():
			out[String(key)] = list
	return out


## Olayı kayıt sözlüğüne çevirir (desteklenmeyen olay için boş sözlük).
static func event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var k := event as InputEventKey
		var code: int = k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
		return {"type": "key", "physical": code} if code != KEY_NONE else {}
	if event is InputEventMouseButton:
		var button := (event as InputEventMouseButton).button_index
		return {"type": "mouse", "button": int(button)} if MOUSE_BUTTONS.has(button) else {}
	if event is InputEventJoypadButton:
		var index := (event as InputEventJoypadButton).button_index
		return {"type": "joy_button", "index": int(index)} if index >= 0 and index < JOY_BUTTON_MAX else {}
	return {}


## Kayıt sözlüğünden olay (bozuksa null): tuş fiziksel koddur, fare düğmesi MOUSE_BUTTONS'tan, oyun kolu düğmesi 0..JOY_BUTTON_MAX-1.
static func event_from_dict(data: Variant) -> InputEvent:
	if not data is Dictionary:
		return null
	var d: Dictionary = data
	match str(d.get("type", "")):
		"key":
			var code: Variant = d.get("physical")
			if not (code is int or code is float) or int(code) <= 0 or OS.get_keycode_string(int(code)).is_empty():
				return null
			return key_event(int(code) as Key)
		"mouse":
			var button: Variant = d.get("button")
			if not (button is int or button is float) or not MOUSE_BUTTONS.has(int(button)):
				return null
			var mb := InputEventMouseButton.new()
			mb.button_index = int(button) as MouseButton
			return mb
		"joy_button":
			var index: Variant = d.get("index")
			if not (index is int or index is float) or int(index) < 0 or int(index) >= JOY_BUTTON_MAX:
				return null
			var jb := InputEventJoypadButton.new()
			jb.button_index = int(index) as JoyButton
			return jb
	return null


## Olayın türü: "key", "mouse", "joy_button" ya da "".
static func event_kind(event: InputEvent) -> String:
	return str(event_to_dict(event).get("type", ""))


## İki olay aynı tuş, düğme ya da kol düğmesi mi (basılı olup olmadıkları sayılmaz)?
static func same_event(a: InputEvent, b: InputEvent) -> bool:
	if a == null or b == null:
		return false
	var da := event_to_dict(a)
	return not da.is_empty() and da == event_to_dict(b)


# --- Çakışma ----------------------------------------------------------------------------------------------

## İki eylem aynı anda dinlenir mi? Aynı bağlam ya da biri "any"; bilerek paylaşılan çiftler (ALLOWED_PAIRS) sayılmaz.
static func contexts_clash(a: StringName, b: StringName) -> bool:
	if a == b or [a, b] in ALLOWED_PAIRS or [b, a] in ALLOWED_PAIRS:
		return false
	var ca := str(CONTEXTS.get(a, "any"))
	var cb := str(CONTEXTS.get(b, "any"))
	return ca == cb or ca == "any" or cb == "any"


## Olay eyleme bağlanırsa onunla aynı bağlamda aynı olayı dinleyen öteki eylemler («Şuna da bağlı: {eylem}»).
static func conflicts_for(action: StringName, event: InputEvent) -> Array[StringName]:
	var out: Array[StringName] = []
	for other in managed_actions():
		if other == action or not contexts_clash(action, other):
			continue
		for e in events_of(other):
			if same_event(e, event):
				out.append(other)
				break
	return out


## Aynı olayı paylaşan ve aynı bağlamda dinlenen eylem çiftleri (tuş haritasından; boş olmalı): [a, b, olayın adı]. "any" her
## bağlamla çakışır; E'nin kamera ve onay işi bilinçli olarak birliktedir (godot.md §5.3: E'nin işi varken kamera dönmez), Esc'in geri
## al ve duraklat işi de.
static func conflicts() -> Array:
	var actions := managed_actions()
	var out: Array = []
	for i in actions.size():
		for j in range(i + 1, actions.size()):
			var a: StringName = actions[i]
			var b: StringName = actions[j]
			if not contexts_clash(a, b):
				continue
			for e in events_of(a):
				var shared := false
				for f in events_of(b):
					if same_event(e, f):
						shared = true
				if shared:
					out.append([a, b, _event_string(e)])
	return out


## WASD girişi: x = sağ/sol, y = ileri(+)/geri(-). Uzunluğu en fazla 1'dir.
static func move_vector() -> Vector2:
	var v := Vector2(
		Input.get_action_strength(&"move_right") - Input.get_action_strength(&"move_left"),
		Input.get_action_strength(&"move_forward") - Input.get_action_strength(&"move_back"))
	return v.limit_length(1.0)


# --- İç işler ---------------------------------------------------------------------------------------------

static func _set_map_events(action: StringName, events: Array) -> void:
	InputMap.action_erase_events(action)
	for event in events:
		if event is InputEvent and not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


static func _same_events(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not same_event(a[i], b[i]):
			return false
	return true


## Olayın dizilişten bağımsız adı (çakışma listesi için; ekrandaki ad ControlsPage.event_name'dedir).
static func _event_string(event: InputEvent) -> String:
	var d := event_to_dict(event)
	match str(d.get("type", "")):
		"key":
			return OS.get_keycode_string(int(d["physical"]))
		"mouse":
			return "Mouse %d" % int(d["button"])
		"joy_button":
			return "Joy %d" % int(d["index"])
	return ""
