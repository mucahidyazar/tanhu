class_name EncyclopediaPage
extends Control
## Destan Kitabı'nın ansiklopedi düzenindeki sayfası: «Gök ve Yer» ile Kişiler (godot.md §3.8; K85, K86).
## Düzen sitenin kitabıdır (docs-app/src/components/encyclopedia/book.tsx), açık parşömen üstünde mürekkep:
##   üst   simgeli altı bölüm sekmesi: Tanrılar ve Ruhlar (güneş), Mete ve Soyu (yay), Hun Ordası (yurt),
##         Komşu Halklar (at), Ç'in ve Han (kule), Yoldaşlar (kişiler). «Gök ve Yer» ilkini, Kişiler öteki
##         beşini açar; öteki sayfanın sekmesine basmak kitabı o sayfaya çevirir (page_requested).
##   sol   arama kutusu ve portreli dizin (yuvarlak 128 px küçük resim, ad ve san), «n / N açıldı»
##   orta  tam boy görsel, altında PROFİL, ART ve 3B ya da T-POZ küçük resimleri; görseli olmayan kayıtta
##         baş harf ve «Görsel henüz üretilmedi.»; 3B kişinin var olan modelidir (EncyclopediaModelView)
##   sağ   ad ve san, hoparlör (tanıtım sesi), numaralı bölümler, çağ rozetleri, bilgi satırı, soy bağları
##         (portreli kartlar; açılmamış kişi adsız keçe siluettir, basılmaz) ve kaynak notu
## Tuşlar: Q / E bölüm (GameMenu sorar: turn_section; sınırda kitabın komşu sayfası), ↑ / ↓ kişi, ← / → görsel
## (döngüyle), Enter büyüt, Esc geri (back: büyütme, sonra arama, sonra kitap kapanır), Boşluk ya da oyun
## kolunda Y tanıtım (book_intro). Oyun kolunda yön tuşları kişi ve görsel, A büyüt, B geri, LB / RB bölüm.
## Arama kutusu odaktayken harfler (Q ve E dahil) kutuya yazılır.
##
## Görseller seçili kişi ve dizindeki iki komşusu için arka planda yüklenir (load_threaded_request); öteki
## kişilerin görselleri bırakılır, sayfa kapanınca hepsi bırakılır (kişi başına ≈2,1 MiB, kamp satırının doku
## belleğine sayılır). Tanıtım aynı anda tek dosyadır: hoparlöre basınca yüklenir, AudioManager.play_voice_stream
## ile Voice yolunda ana söz olarak çalar (müzik ve ortam kısılır, K78), altyazısı tuş satırının üstündedir
## (SubtitleBar; Türkçe, İngilizce arayüzde İngilizce). Yeniden basmak, kişi değiştirmek ya da kitabı kapatmak susturur.

## Kitabın başka bir sayfasının bölümü ya da kaydı istendi (sekme, soy kartı).
signal page_requested(chapter: String, section: String, entry_id: String)
## Sağda bir kayıt açıldı ("" = boş sayfa).
signal entry_shown(id: String)

## Panelin içi (çerçeve dışarıda kalır), 1080 satırlık arayüzde piksel.
const PANEL_SIZE := Vector2(1786, 796)
const INDEX_W := 372.0
const VIEWER_W := 548.0
const ROW_H := 74.0
const THUMB_D := 58.0
const STRIP_H := 124.0
## Parşömenin renkleri: zemin UIKit.PARCHMENT, yazı UIKit.INK.
const PAPER := Color("#efe2c4")
const INK := Color("#090c12")
const INK_SOFT := Color(0.035, 0.047, 0.07, 0.68)
const RULE := Color(0.49, 0.384, 0.212, 0.8)
const ACCENT := Color("#8a3b1e")
const SELECT := Color(0.49, 0.384, 0.212, 0.22)
const HOVER := Color(0.49, 0.384, 0.212, 0.1)
const FELT := Color(0.18, 0.15, 0.13)

## Görsel yuvaları: profil, art, üçüncüsü modeli olan kişide 3B, olmayanda T-poz.
const SLOT_COUNT := 3
const SLOT_LABELS := {"profile": "PROFİL", "art": "ART", "pose": "T-POZ", "model": "3B"}
const EMPTY_IMAGE_TEXT := "Görsel henüz üretilmedi."
const EMPTY_LIST_TEXT := "Bu sayfalar henüz boş."
const SEARCH_HINT := "Ad, öteki ad ya da san ara"
const COVER_SUB := "Göğün, yerin ve Mete'nin çağının kişileri"
const ERA_LABELS := {"mit": "Mit", "tarih": "Tarih", "kurgu": "Kurgu"}
const LINEAGE_TITLE := "Soy Bağları"
## Tuş satırı (GameMenu'nün alt şeridinde) ve hoparlörün ipucu.
const KEY_HINT := "Q E bölüm · ↑ ↓ kişi · ← → görsel · Enter büyüt · Esc geri"
const SPEAKER_KEY := "Boşluk"
## Altyazının son sözcükten sonraki payı (sn).
const SUBTITLE_TAIL := 0.4

## Görseller arka planda mı yüklenir? Başsız koşuda (sınamalar, araçlar) Godot'nun sahte çizicisi dokuları
## birden çok iş parçacığından güvenle kuramaz; o zaman görsel istendiği anda doğrudan yüklenir.
static var threaded_loads := DisplayServer.get_name() != "headless"

var embedded := true
## "gok_yer" ya da "kisiler".
var chapter := "kisiler"
var flags: Dictionary = {}
## Tanıtımı çalan ses yöneticisi (boşsa /root/AudioManager; testler kendi örneğini verir).
var audio: Node

var _sections: Array[String] = []
var _section := ""
var _all: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _listed: Array[Dictionary] = []
var _selected := ""
var _slot := 1
var _zoom := false
var _query := ""
var _start_section := ""
var _start_entry := ""

var _tex: Dictionary = {}               # yol → Texture2D (seçili kişi ve komşuları)
var _pending: Dictionary = {}           # yol → true (arka planda yükleniyor)
var _thumbs: Dictionary = {}            # yol → Texture2D (dizin ve soy kartlarının küçük resimleri)
var _thumb_pending: Dictionary = {}

var _intro_stream: AudioStream
var _intro_id := ""
var _intro_elapsed := 0.0
var _intro_length := 0.0
var _subtitle: SubtitleBar

var _panel: Control
var _tabs: Array[SectionTab] = []
var _search: LineEdit
var _count: Label
var _index_scroll: ScrollContainer
var _index_list: VBoxContainer
var _rows: Array[IndexRow] = []
var _stage: Stage
var _slots: Array[SlotButton] = []
var _pager: Label
var _model_view: EncyclopediaModelView
var _content_scroll: ScrollContainer
var _content: VBoxContainer
var _speaker: SpeakerButton
var _intro_label: RichTextLabel
var _lineage_cards: Array[LineageCard] = []
var _zoom_layer: Control
var _zoom_rect: TextureRect


func _init(p_chapter: String = "kisiler", p_flags: Dictionary = {}) -> void:
	chapter = p_chapter
	flags = p_flags


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_sections = DestanKitabi.sections_of(chapter)
	if _sections.is_empty():
		_sections = DestanKitabi.sections_of("kisiler")
	_collect()
	var root := VBoxContainer.new()
	root.custom_minimum_size = PANEL_SIZE
	root.add_theme_constant_override("separation", 6)
	_panel = OrnateFrame.wrap(root, 26.0, true, 30.0, UIKit.GOLD_DIM, PAPER)
	add_child(_panel)
	root.add_child(_build_tabs())
	root.add_child(Rule.new())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_index())
	body.add_child(_vrule())
	body.add_child(_build_viewer())
	body.add_child(_vrule())
	body.add_child(_build_content())
	_build_zoom()
	_subtitle = SubtitleBar.new()
	_subtitle.name = "Subtitle"
	add_child(_subtitle)
	_dress_subtitle()
	UIKit.center_in_parent(_panel)
	_set_section(_start_section if _start_section in _sections else first_open_section())
	if not _start_entry.is_empty():
		open_entry(_start_entry)


## Sayfa açılınca gösterilen bölüm: açık kaydı olan ilk bölüm (hiçbirinde yoksa ilki).
func first_open_section() -> String:
	for s in _sections:
		for e in _all:
			if str(e["section"]) == s:
				return s
	return _sections[0]


func _exit_tree() -> void:
	stop_intro()
	_release_images()


# --- Kayıtlar ve bölümler ------------------------------------------------------------------------

## İki ansiklopedi sayfasının açık kayıtları (arama ikisinde de arar, soy kartları ikisine de gider).
func _collect() -> void:
	_all.clear()
	_by_id.clear()
	for c in DestanKitabi.ENCYCLOPEDIA_CHAPTERS:
		for e in DestanKitabi.entries(c, flags):
			_all.append(e)
			_by_id[str(e["id"])] = e


## Bu sayfanın site bölümleri, sekme sırasıyla.
func get_sections() -> Array[String]:
	return _sections


## Açık bölüm.
func get_section() -> String:
	return _section


## Bölümü açar (bu sayfanın değilse kitaptan o sayfayı ister). Kurulmadan önce çağrılırsa açılışta uygulanır.
func open_section(section: String) -> void:
	if _search == null:
		_start_section = section
		return
	if section in _sections:
		_set_section(section)
	elif DestanKitabi.SECTION_PAGES.has(section):
		page_requested.emit(str(DestanKitabi.SECTION_PAGES[section]), section, "")


## Q / E: bölümü dir kadar çevirir; bölüm sınırındaysa false (kitap komşu sayfaya geçer). Arama açıksa kapanır.
func turn_section(dir: int) -> bool:
	var i := _sections.find(_section) + dir
	if i < 0 or i >= _sections.size():
		return false
	_set_section(_sections[i])
	MenuStyle.play_ui(self, &"page_turn", -12.0)
	return true


## Kitap bu sayfaya dir yönünde çevrilince: geri gelindiyse son bölüm açılır, ileri gelindiyse ilki.
func enter_from(dir: int) -> void:
	if dir < 0 and not _sections.is_empty():
		open_section(_sections[_sections.size() - 1])


## Esc: önce büyütülmüş görsel, sonra arama kapanır; ikisi de yoksa false (kitap kapanır).
func back() -> bool:
	if _zoom:
		set_zoom(false)
		return true
	if (_search and _search.has_focus()) or not _query.is_empty():
		clear_search()
		return true
	return false


## Arama kutusu odakta mı? (O sırada Q / E harf yazar.)
func wants_text_input() -> bool:
	return _search != null and _search.has_focus()


func _set_section(section: String) -> void:
	_section = section
	if not _query.is_empty():
		_query = ""
		_search.text = ""
	_refresh_list()
	_select_after_refresh()


func _refresh_list() -> void:
	_listed.clear()
	if _query.is_empty():
		for e in _all:
			if str(e["section"]) == _section:
				_listed.append(e)
	else:
		_listed = DestanKitabi.search(_query, _all)
	for c in _index_list.get_children():
		_index_list.remove_child(c)
		c.queue_free()
	_rows.clear()
	var group := ""
	for e in _listed:
		if _query.is_empty() and str(e["group"]) != group:
			group = str(e["group"])
			if group != "":
				var g := _ink(DestanKitabi.upper_tr(group), 14, "Cinzel", 700, Color(ACCENT, 0.85), 2)
				g.custom_minimum_size = Vector2(0, 30)
				g.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
				_index_list.add_child(g)
		var row := IndexRow.new(str(e["id"]), str(e["title"]), str(e["sub"]))
		row.thumb_path = _thumb_path(e)
		row.texture = _thumbs.get(row.thumb_path)
		row.pressed.connect(show_entry.bind(str(e["id"])))
		_index_list.add_child(row)
		_rows.append(row)
		_want_thumb(row.thumb_path)
	if _listed.is_empty():
		var empty := _ink(EMPTY_LIST_TEXT, 19, "Alegreya-Italic", 400, INK_SOFT)
		empty.custom_minimum_size = Vector2(0, 48)
		_index_list.add_child(empty)
	_update_count()
	for t in _tabs:
		t.active = _query.is_empty() and t.section == _section
		t.queue_redraw()


## Listede seçili kişi kalıyorsa o, kalmıyorsa ilki açılır; liste boşsa boş sayfa.
func _select_after_refresh() -> void:
	for e in _listed:
		if str(e["id"]) == _selected:
			_mark_rows()
			_scroll_to_selected()
			return
	if _listed.is_empty():
		_show_none()
	else:
		show_entry(str(_listed[0]["id"]))


func _update_count() -> void:
	if not _query.is_empty():
		_count.text = "Arama · %d kayıt" % _listed.size()
		return
	var total := 0
	for p in DestanKitabi.all_entries(str(DestanKitabi.SECTION_PAGES.get(_section, chapter))):
		if p is Dictionary and str(p.get("section", "")) == _section:
			total += 1
	_count.text = "%s · %d / %d açıldı" % [str(DestanKitabi.section_info(_section).get("title", _section)), _listed.size(), total]


## Dizinde görünen kayıtların kimlikleri, sırasıyla.
func get_listed_ids() -> Array[String]:
	var out: Array[String] = []
	for e in _listed:
		out.append(str(e["id"]))
	return out


## Sayaç yazısı («Hun Ordası · 5 / 31 açıldı», aramada «Arama · 2 kayıt»).
func get_count_text() -> String:
	return _count.text


# --- Arama -------------------------------------------------------------------------------------

## Aramayı verilen metinle çalıştırır (kutuya yazmak gibi).
func set_query(text: String) -> void:
	_search.text = text
	_on_query(text)


## Aramayı kapatır: kutu boşalır, odak bırakılır, dizin bölüme döner.
func clear_search() -> void:
	_search.text = ""
	if _search.has_focus():
		_search.release_focus()
	_on_query("")


func get_query() -> String:
	return _query


func get_search_box() -> LineEdit:
	return _search


func _on_query(text: String) -> void:
	var q := text.strip_edges()
	if q == _query:
		return
	_query = q
	if _query.is_empty() and not _selected.is_empty() and _by_id.has(_selected):
		# Aramadan bölüme dönerken açık kişinin bölümü açılır.
		var s := str(_by_id[_selected]["section"])
		if s in _sections:
			_section = s
	_refresh_list()
	_select_after_refresh()


# --- Seçim ----------------------------------------------------------------------------------------

## Kimliği verilen kaydı açar. Açık değilse false. Bölümü öteki sayfadaysa kitaptan o sayfayı ister.
func open_entry(id: String) -> bool:
	if _search == null:
		_start_entry = id
		return true
	if not _by_id.has(id):
		return false
	var e: Dictionary = _by_id[id]
	var s := str(e["section"])
	if not (s in _sections):
		if page_requested.get_connections().is_empty():
			# Kitapsız (sınamada): kayıt bu sayfada açılır.
			_section = s
			if not _query.is_empty():
				_query = ""
				_search.text = ""
			_refresh_list()
			show_entry(id)
			return true
		page_requested.emit(str(DestanKitabi.SECTION_PAGES.get(s, chapter)), s, id)
		return true
	var listed := false
	for x in _listed:
		listed = listed or str(x["id"]) == id
	if not listed:
		_section = s
		if not _query.is_empty():
			_query = ""
			_search.text = ""
		_refresh_list()
	show_entry(id)
	return true


## Kimliği verilen kaydı sağda açar (dizinde olmasa da).
func show_entry(id: String) -> void:
	if not _by_id.has(id):
		return
	if id != _selected:
		stop_intro()
	_selected = id
	var e: Dictionary = _by_id[id]
	_slot = default_slot(e)
	_set_zoom_state(false)
	_mark_rows()
	_update_viewer()
	_update_content(e)
	_want_images()
	_scroll_to_selected()
	entry_shown.emit(id)


## ↑ / ↓: dizinde bir sonraki ya da önceki kişi (uçlarda durur).
func move_selection(d: int) -> void:
	if _listed.is_empty():
		return
	var i := -1
	for k in _listed.size():
		if str(_listed[k]["id"]) == _selected:
			i = k
	var j := clampi(i + d, 0, _listed.size() - 1) if i >= 0 else 0
	if j != i:
		show_entry(str(_listed[j]["id"]))
		MenuStyle.play_ui(self, &"hover", -14.0)


## Seçili kaydın kimliği ("" = boş sayfa).
func get_selected_id() -> String:
	return _selected


## Seçili kayıt (yoksa boş).
func get_selected() -> Dictionary:
	return _by_id.get(_selected, {})


func _show_none() -> void:
	stop_intro()
	_selected = ""
	_set_zoom_state(false)
	_mark_rows()
	_update_viewer()
	_update_content({})
	_want_images()
	entry_shown.emit("")


func _mark_rows() -> void:
	for r in _rows:
		r.selected = r.entry_id == _selected
		r.queue_redraw()


## Seçili satırı dizinin görünen yerine kaydırır (kap yeni boyunu bir kare sonra alır).
func _scroll_to_selected() -> void:
	var row: IndexRow = null
	for r in _rows:
		if r.selected:
			row = r
	if row == null or not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(row) and row.is_inside_tree() and is_instance_valid(_index_scroll):
		_index_scroll.ensure_control_visible(row)


# --- Görseller ve yuvalar ----------------------------------------------------------------------------

## Kaydın üç yuvasının türleri: ["profile", "art", "model"] ya da ["profile", "art", "pose"].
static func slot_kinds(e: Dictionary) -> Array[String]:
	var third := "model" if not EncyclopediaModelView.model_path(str(e.get("model", ""))).is_empty() else "pose"
	var out: Array[String] = ["profile", "art", third]
	return out


## Yuvanın görsel yolu (3B ve görseli olmayan yuvada boş).
static func slot_path(e: Dictionary, kind: String) -> String:
	var images: Dictionary = e.get("images", {}) if e.get("images") is Dictionary else {}
	match kind:
		"profile":
			return str(images.get("portrait", ""))
		"art":
			return str(images.get("art", ""))
		"pose":
			return str(images.get("pose", ""))
	return ""


## Açılışta gösterilen yuva: tam boy art; yoksa ilk görseli olan; hiçbiri yoksa profil (sitenin kitabı gibi).
static func default_slot(e: Dictionary) -> int:
	var kinds := slot_kinds(e)
	if not slot_path(e, "art").is_empty():
		return 1
	for i in kinds.size():
		if kinds[i] == "model" or not slot_path(e, kinds[i]).is_empty():
			return i
	return 0


## Yuvanın görseli var mı (3B'de model var mı)?
static func slot_available(e: Dictionary, kind: String) -> bool:
	return kind == "model" or not slot_path(e, kind).is_empty()


## ← / →: yuvayı döngüyle çevirir (PROFİL → ART → 3B ya da T-POZ → PROFİL).
func cycle_slot(d: int) -> void:
	if _selected.is_empty():
		return
	set_slot(posmod(_slot + d, SLOT_COUNT))
	MenuStyle.play_ui(self, &"hover", -14.0)


func set_slot(i: int) -> void:
	if _selected.is_empty():
		return
	_slot = clampi(i, 0, SLOT_COUNT - 1)
	var e := get_selected()
	if _zoom and not _zoomable(e):
		_set_zoom_state(false)
	_update_viewer()
	if _zoom:
		_zoom_rect.texture = _tex.get(slot_path(e, current_kind()))


func get_slot() -> int:
	return _slot


## Açık yuvanın türü ("profile", "art", "pose", "model"; kayıt yoksa "").
func current_kind() -> String:
	if _selected.is_empty():
		return ""
	return slot_kinds(get_selected())[_slot]


## Görsel alanının yazısı: görsel yoksa «Görsel henüz üretilmedi.», 3B yüklenirken onun yazısı, yoksa "".
func get_stage_text() -> String:
	if _model_view and is_instance_valid(_model_view):
		return _model_view.get_status_text()
	return _stage.message if _stage.texture == null else ""


func get_model_view() -> EncyclopediaModelView:
	return _model_view if _model_view and is_instance_valid(_model_view) else null


## Enter: görseli büyütür ya da küçültür (görseli olan yuvada).
func toggle_zoom() -> void:
	set_zoom(not _zoom)


func set_zoom(on: bool) -> void:
	if on and not _zoomable(get_selected()):
		return
	_set_zoom_state(on)
	if on:
		_zoom_rect.texture = _tex.get(slot_path(get_selected(), current_kind()))
	MenuStyle.play_ui(self, &"page_turn", -12.0)


func is_zoomed() -> bool:
	return _zoom


func _zoomable(e: Dictionary) -> bool:
	if e.is_empty():
		return false
	var kind := slot_kinds(e)[_slot]
	return kind != "model" and not slot_path(e, kind).is_empty()


func _set_zoom_state(on: bool) -> void:
	_zoom = on
	if _zoom_layer:
		_zoom_layer.visible = on


## Seçili kişinin ve dizindeki iki komşusunun görselleri istenir; öteki kişilerinki bırakılır.
func _want_images() -> void:
	var wanted := {}
	var i := -1
	for k in _listed.size():
		if str(_listed[k]["id"]) == _selected:
			i = k
	var people: Array[Dictionary] = []
	if _by_id.has(_selected):
		people.append(_by_id[_selected])
	if i >= 0:
		for j in [i - 1, i + 1]:
			if j >= 0 and j < _listed.size():
				people.append(_listed[j])
	for e in people:
		for kind in ["profile", "art", "pose"]:
			var path := slot_path(e, kind)
			if not path.is_empty() and ResourceLoader.exists(path):
				wanted[path] = true
	for path: String in _tex.keys():
		if not wanted.has(path):
			_tex.erase(path)
	for path: String in wanted:
		if _tex.has(path) or _pending.has(path):
			continue
		if not threaded_loads:
			var tex := load(path) as Texture2D
			if tex:
				_tex[path] = tex
		elif ResourceLoader.load_threaded_request(path, "Texture2D") == OK:
			_pending[path] = true


func _want_thumb(path: String) -> void:
	if path.is_empty() or _thumbs.has(path) or _thumb_pending.has(path) or not ResourceLoader.exists(path):
		return
	if not threaded_loads:
		var tex := load(path) as Texture2D
		if tex:
			_thumbs[path] = tex
	elif ResourceLoader.load_threaded_request(path, "Texture2D") == OK:
		_thumb_pending[path] = true


## Dizin ve soy kartının küçük resmi: thumb, yoksa boş (baş harf çizilir).
static func _thumb_path(e: Dictionary) -> String:
	var images: Dictionary = e.get("images", {}) if e.get("images") is Dictionary else {}
	return str(images.get("thumb", ""))


## Sayfanın tuttuğu görsel yolları (yüklü olanlar).
func cached_paths() -> Array:
	return _tex.keys()


## Arka planda yüklenen görsel yolları.
func pending_paths() -> Array:
	return _pending.keys() + _thumb_pending.keys()


## Bütün başvurular bırakılır; bekleyen yüklemeler teslim alınıp atılır (alınmazsa bellekte kalır).
func _release_images() -> void:
	for path: String in _pending.keys() + _thumb_pending.keys():
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(path)
	_pending.clear()
	_thumb_pending.clear()
	_tex.clear()
	_thumbs.clear()
	for r in _rows:
		r.texture = null
	if _stage:
		_stage.texture = null
	if _zoom_rect:
		_zoom_rect.texture = null


func _process(delta: float) -> void:
	_poll_loads()
	if not _intro_id.is_empty():
		_intro_elapsed += delta
		_subtitle.show_at(_intro_elapsed)
		var am := _audio()
		var gone := am == null or not am.has_method(&"current_line") or str(am.call(&"current_line")) != _intro_id
		if _intro_elapsed > _intro_length + 1.0 and gone:
			_end_intro()


func _poll_loads() -> void:
	var refresh := false
	for path: String in _pending.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var tex := ResourceLoader.load_threaded_get(path) as Texture2D
			if tex:
				_tex[path] = tex
				refresh = true
	if refresh:
		_want_images()
		_update_viewer()
		if _zoom:
			_zoom_rect.texture = _tex.get(slot_path(get_selected(), current_kind()))
	var thumbs := false
	for path: String in _thumb_pending.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_thumb_pending.erase(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var tex := ResourceLoader.load_threaded_get(path) as Texture2D
			if tex:
				_thumbs[path] = tex
				thumbs = true
	if thumbs:
		for r in _rows:
			if r.texture == null and _thumbs.has(r.thumb_path):
				r.texture = _thumbs[r.thumb_path]
				r.queue_redraw()
		for c in _lineage_cards:
			if is_instance_valid(c) and c.texture == null and _thumbs.has(c.thumb_path):
				c.texture = _thumbs[c.thumb_path]
				c.queue_redraw()


## Seçili kaydın görsel alanını, yuva şeridini ve sayfa sayısını kurar.
func _update_viewer() -> void:
	if _stage == null:
		return
	var e := get_selected()
	_stage.cover = e.is_empty()
	_stage.initial = str(e.get("title", "")).left(1)
	var kinds: Array[String] = ["profile", "art", "pose"]
	if not e.is_empty():
		kinds = slot_kinds(e)
	var kind := kinds[_slot] if not e.is_empty() else ""
	var path := slot_path(e, kind) if not e.is_empty() else ""
	_stage.texture = _tex.get(path) if not path.is_empty() else null
	# 3B yuvasında ve görsel yüklenirken alanın ortası boş kalır (model saydam zeminin üstünde döner).
	_stage.waiting = kind == "model" or (not path.is_empty() and _stage.texture == null)
	_stage.message = "" if e.is_empty() or kind == "model" else (EMPTY_IMAGE_TEXT if path.is_empty() else "")
	_stage.queue_redraw()
	if kind == "model":
		var id := str(e.get("model", ""))
		if _model_view == null or not is_instance_valid(_model_view) or _model_view.model_id != id:
			_free_model_view()
			_model_view = EncyclopediaModelView.new(id)
			_model_view.name = "ModelView"
			UIKit.full_rect(_model_view)
			_stage.add_child(_model_view)
	else:
		_free_model_view()
	for i in _slots.size():
		var s := _slots[i]
		s.visible = not e.is_empty()
		if e.is_empty():
			continue
		s.kind = kinds[i]
		s.active = i == _slot
		s.available = slot_available(e, kinds[i])
		match kinds[i]:
			"profile":
				s.texture = _tex.get(slot_path(e, "profile"), _thumbs.get(_thumb_path(e)))
			"model":
				s.texture = _tex.get(slot_path(e, "art"), _tex.get(slot_path(e, "pose")))
			_:
				s.texture = _tex.get(slot_path(e, kinds[i]))
		s.queue_redraw()
	_pager.text = "◆  %d / %d  ◆" % [_slot + 1, SLOT_COUNT] if not e.is_empty() else ""


func _free_model_view() -> void:
	if _model_view and is_instance_valid(_model_view):
		_model_view.get_parent().remove_child(_model_view)
		_model_view.queue_free()
	_model_view = null


# --- Tanıtım sesi (K86) ---------------------------------------------------------------------------------

## Seçili kişinin hoparlörü var mı? (Dosyası olan ve oyunda konuşan kişide.)
func has_speaker() -> bool:
	return _speaker != null and is_instance_valid(_speaker)


## Hoparlör yokken tanıtımın iki cümlesi sayfada yazıyla mı duruyor?
func has_intro_text() -> bool:
	return _intro_label != null and is_instance_valid(_intro_label)


func get_speaker() -> SpeakerButton:
	return _speaker if has_speaker() else null


## Hoparlör: tanıtım çalmıyorsa başlatır, çalıyorsa susturur.
func toggle_intro() -> void:
	if is_intro_playing():
		stop_intro()
	else:
		play_intro()


func is_intro_playing() -> bool:
	return not _intro_id.is_empty()


## Tanıtımın sinyal kimliği ("ency.<kimlik>"; çalmıyorsa boş).
func get_intro_id() -> String:
	return _intro_id


## Seçili kişinin tanıtımını çalar: dosya o an yüklenir (kitap aynı anda tek tanıtım tutar).
func play_intro() -> void:
	var e := get_selected()
	if e.is_empty() or not has_speaker():
		return
	var path := str(e.get("intro_audio", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	stop_intro()
	_intro_stream = load(path) as AudioStream
	if _intro_stream == null:
		return
	_intro_id = "ency.%s" % _selected
	_intro_elapsed = 0.0
	_intro_length = _intro_stream.get_length()
	var am := _audio()
	if am and am.has_method(&"play_voice_stream"):
		if am.has_signal(&"line_finished") and not am.is_connected(&"line_finished", _on_line_finished):
			am.connect(&"line_finished", _on_line_finished)
		_intro_length = float(am.call(&"play_voice_stream", _intro_stream, {"id": _intro_id}))
	var intro: Dictionary = e.get("intro", {})
	var lang := SubtitleBar.ui_lang()
	var text := str(intro.get(lang, intro.get("tr", "")))
	var t1 := DuckTable.PREROLL + _intro_length + SUBTITLE_TAIL
	_subtitle.set_windows([{"id": _intro_id, "t0": 0.0, "t1": t1, "text": text}])
	_subtitle.show_at(0.0)
	_speaker.playing = true
	_speaker.queue_redraw()


## Çalan tanıtımı susturur (yoksa bir şey yapmaz).
func stop_intro() -> void:
	if _intro_id.is_empty():
		return
	var am := _audio()
	var id := _intro_id
	_end_intro()
	if am and am.has_method(&"current_line") and str(am.call(&"current_line")) == id:
		am.call(&"stop_line", 0.15)


## Gösterilen altyazı (yoksa "").
func get_subtitle_text() -> String:
	return _subtitle.current_text() if _subtitle else ""


func _on_line_finished(id: String) -> void:
	if id == _intro_id:
		_end_intro()


func _end_intro() -> void:
	_intro_id = ""
	_intro_stream = null
	if _subtitle:
		_subtitle.clear()
	if has_speaker():
		_speaker.playing = false
		_speaker.queue_redraw()


func _audio() -> Node:
	if audio and is_instance_valid(audio):
		return audio
	return get_node_or_null(^"/root/AudioManager")


## Altyazı parşömenin üstüne düşer: kutusunun arkasına koyu, yarı saydam bir şerit konur.
func _dress_subtitle() -> void:
	var box := _subtitle.get_node_or_null(^"Box") as Control
	if box == null:
		return
	var band := Panel.new()
	band.name = "Band"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.025, 0.04, 0.78)
	sb.set_corner_radius_all(6)
	sb.border_color = Color(UIKit.GOLD, 0.35)
	sb.set_border_width_all(1)
	band.add_theme_stylebox_override("panel", sb)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(band)
	box.add_child(band)
	box.move_child(band, 0)


# --- Girdi ---------------------------------------------------------------------------------------------
## Q / E ve Esc'i GameMenu okur (sayfaya turn_section ve back ile sorar); kalan tuşlar burada.

func _input(e: InputEvent) -> void:
	if not is_visible_in_tree() or _blocked():
		return
	var typing := _search != null and _search.has_focus()
	if e is InputEventKey and e.pressed:
		var key := e as InputEventKey
		match key.physical_keycode:
			KEY_UP, KEY_DOWN:
				get_viewport().set_input_as_handled()
				move_selection(-1 if key.physical_keycode == KEY_UP else 1)
				return
			KEY_LEFT, KEY_RIGHT:
				if typing or key.echo:
					return
				get_viewport().set_input_as_handled()
				cycle_slot(-1 if key.physical_keycode == KEY_LEFT else 1)
				return
			KEY_ENTER, KEY_KP_ENTER:
				if typing or key.echo:
					return
				get_viewport().set_input_as_handled()
				toggle_zoom()
				return
	if e is InputEventJoypadButton and e.pressed:
		match (e as InputEventJoypadButton).button_index:
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
				get_viewport().set_input_as_handled()
				move_selection(-1 if (e as InputEventJoypadButton).button_index == JOY_BUTTON_DPAD_UP else 1)
				return
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				get_viewport().set_input_as_handled()
				cycle_slot(-1 if (e as InputEventJoypadButton).button_index == JOY_BUTTON_DPAD_LEFT else 1)
				return
			JOY_BUTTON_A:
				get_viewport().set_input_as_handled()
				toggle_zoom()
				return
	if not typing and _is_intro_event(e):
		get_viewport().set_input_as_handled()
		toggle_intro()


## Hoparlörün tuşu: book_intro eylemi (Boşluk, oyun kolunda Y); eylem kayıtlı değilse aynı tuşlar.
static func _is_intro_event(e: InputEvent) -> bool:
	if e is InputEventKey and (e as InputEventKey).echo:
		return false
	if InputMap.has_action(&"book_intro"):
		return e.is_action_pressed(&"book_intro")
	if e is InputEventKey and e.pressed:
		return (e as InputEventKey).physical_keycode == KEY_SPACE
	return e is InputEventJoypadButton and e.pressed and (e as InputEventJoypadButton).button_index == JOY_BUTTON_Y


## Kitabın üstünde bir pencere (soru, kayıt yuvaları) açıksa sayfa tuş almaz.
func _blocked() -> bool:
	var n := get_parent()
	while n:
		if n is GameMenu:
			return (n as GameMenu).has_overlay()
		n = n.get_parent()
	return false


# --- Kuruluş -------------------------------------------------------------------------------------------

func _build_tabs() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.custom_minimum_size = Vector2(0, 66)
	row.add_child(KeyCap.new("Q"))
	for s in DestanKitabi.SECTIONS:
		var info := DestanKitabi.section_info(s)
		var t := SectionTab.new(s, str(info.get("icon", "")), str(info.get("title", s)), s in _sections)
		t.pressed.connect(open_section.bind(s))
		row.add_child(t)
		_tabs.append(t)
	row.add_child(KeyCap.new("E"))
	return row


func _build_index() -> Control:
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(INDEX_W, 0)
	side.add_theme_constant_override("separation", 6)
	_search = LineEdit.new()
	_search.name = "Search"
	_search.placeholder_text = SEARCH_HINT
	_search.custom_minimum_size = Vector2(INDEX_W, 44)
	_search.clear_button_enabled = true
	_search.add_theme_font_override("font", UIKit.font("Alegreya"))
	_search.add_theme_font_size_override("font_size", 19)
	_search.add_theme_color_override("font_color", INK)
	_search.add_theme_color_override("font_placeholder_color", Color(INK, 0.45))
	_search.add_theme_color_override("caret_color", ACCENT)
	_search.add_theme_color_override("clear_button_color", INK_SOFT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.35)
	sb.border_color = RULE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 10
	var focus := sb.duplicate() as StyleBoxFlat
	focus.border_color = ACCENT
	focus.set_border_width_all(2)
	_search.add_theme_stylebox_override("normal", sb)
	_search.add_theme_stylebox_override("focus", focus)
	_search.text_changed.connect(_on_query)
	_search.text_submitted.connect(func(_t: String) -> void: _search.release_focus())
	side.add_child(_search)
	_count = _ink("", 17, "Alegreya-Italic", 400, INK_SOFT)
	_count.custom_minimum_size = Vector2(0, 28)
	side.add_child(_count)
	_index_scroll = ScrollContainer.new()
	_index_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_index_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(_index_scroll)
	_index_list = VBoxContainer.new()
	_index_list.add_theme_constant_override("separation", 2)
	_index_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_index_scroll.add_child(_index_list)
	return side


func _build_viewer() -> Control:
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(VIEWER_W, 0)
	mid.add_theme_constant_override("separation", 8)
	_stage = Stage.new()
	_stage.name = "Stage"
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clicked.connect(_on_stage_clicked)
	mid.add_child(_stage)
	var strip := HBoxContainer.new()
	strip.custom_minimum_size = Vector2(0, STRIP_H)
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 12)
	var left := Arrow.new(-1)
	left.pressed.connect(cycle_slot.bind(-1))
	strip.add_child(left)
	for i in SLOT_COUNT:
		var s := SlotButton.new()
		s.pressed.connect(set_slot.bind(i))
		strip.add_child(s)
		_slots.append(s)
	var right := Arrow.new(1)
	right.pressed.connect(cycle_slot.bind(1))
	strip.add_child(right)
	mid.add_child(strip)
	_pager = _ink("", 16, "Cinzel", 700, Color(ACCENT, 0.85), 2)
	_pager.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(_pager)
	return mid


func _on_stage_clicked() -> void:
	if not _zoom:
		set_zoom(true)


func _build_content() -> Control:
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	_content_scroll.add_child(_content)
	return _content_scroll


func _build_zoom() -> void:
	_zoom_layer = Control.new()
	_zoom_layer.name = "Zoom"
	UIKit.full_rect(_zoom_layer)
	_zoom_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_zoom_layer.visible = false
	var back := ColorRect.new()
	back.color = Color(0.01, 0.012, 0.02, 0.88)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(back)
	_zoom_layer.add_child(back)
	_zoom_rect = TextureRect.new()
	_zoom_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_zoom_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_zoom_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_zoom_rect)
	_zoom_rect.offset_top = 18.0
	_zoom_rect.offset_bottom = -54.0
	_zoom_layer.add_child(_zoom_rect)
	var hint := UIKit.label("Kapat · Esc", 19, "AlegreyaSC-Regular", 400, UIKit.PARCHMENT)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -46.0
	hint.offset_bottom = -12.0
	hint.offset_left = -120.0
	hint.offset_right = 120.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_layer.add_child(hint)
	_zoom_layer.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			set_zoom(false)
			_zoom_layer.accept_event())
	add_child(_zoom_layer)


## Sağdaki metni kayda göre kurar (kayıt yoksa bölümün özeti ve boş sayfa yazısı).
func _update_content(e: Dictionary) -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_lineage_cards.clear()
	_speaker = null
	_intro_label = null
	_content_scroll.scroll_vertical = 0
	if e.is_empty():
		var info := DestanKitabi.section_info(_section)
		var t := _ink(str(info.get("title", "")), 38, "Cinzel", 700, INK, 1)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(t)
		_content.add_child(Rule.new())
		var body := _rich(20)
		body.text = "%s\n\n[i]%s[/i]" % [str(info.get("summary", "")), DestanKitabi.EMPTY_TEXT]
		_content.add_child(body)
		return
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var title := _ink(str(e["title"]), 40, "Cinzel", 700, INK, 1)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if _speaks(e) and not str(e.get("intro_audio", "")).is_empty():
		_speaker = SpeakerButton.new()
		_speaker.name = "Speaker"
		_speaker.pressed.connect(toggle_intro)
		head.add_child(_speaker)
	_content.add_child(head)
	if not str(e["sub"]).is_empty():
		var sub := _ink(str(e["sub"]), 22, "Alegreya-Italic", 400, INK_SOFT)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(sub)
	var era := _rich(17)
	var alt: Array = e.get("alt_names", [])
	var era_text := "[color=#%s]◆ %s[/color]" % [ACCENT.to_html(false), str(ERA_LABELS.get(str(e.get("era", "")), str(e.get("era", ""))))]
	if not alt.is_empty():
		era_text += "  ·  " + "  ·  ".join(PackedStringArray(alt))
	era.text = era_text
	_content.add_child(era)
	var intro: Dictionary = e.get("intro", {})
	if not intro.is_empty() and not has_speaker():
		# Sesi olmayan ya da oyunda konuşmayan kişi: iki cümle sayfada yazıdır (K86).
		_intro_label = _rich(19)
		_intro_label.name = "IntroText"
		_intro_label.text = "[i]«%s»[/i]\n[color=#%s]%s[/color]" % [str(intro.get("tr", "")), INK_SOFT.to_html(true), str(intro.get("en", ""))]
		_content.add_child(_intro_label)
	_content.add_child(Rule.new())
	var sections: Array = e.get("sections", [])
	for i in sections.size():
		var s: Variant = sections[i]
		if s is Dictionary:
			_content.add_child(_section_block(i + 1, str(s.get("title", "")), str(s.get("text", ""))))
	var badges: Array = e.get("badges", [])
	if not badges.is_empty():
		var seals := HFlowContainer.new()
		seals.name = "Badges"
		seals.add_theme_constant_override("h_separation", 10)
		for b: Variant in badges:
			seals.add_child(BadgeSeal.new(str(b)))
		_content.add_child(seals)
	# Bilgi satırı (Gelenek / Alanı / Motifler ya da Halkı / Dönemi / Rolü) ve perdeler (sitenin kitabı gibi).
	var lines := PackedStringArray()
	for f: Variant in e.get("facts", []):
		if f is Dictionary:
			lines.append("[b]%s:[/b] %s" % [str(f.get("label", "")), str(f.get("value", ""))])
	var acts: Array = e.get("acts", [])
	if not acts.is_empty():
		lines.append("[b]Perdeler:[/b] %s" % ", ".join(PackedStringArray(acts)))
	if not lines.is_empty():
		var fl := _rich(18)
		fl.name = "Facts"
		fl.text = "\n".join(lines)
		_content.add_child(fl)
		_content.add_child(Rule.new())
	_add_lineage(e)
	var notes := PackedStringArray()
	if not str(e.get("source_note", "")).is_empty():
		notes.append(str(e["source_note"]))
	if not str(e.get("era_note", "")).is_empty():
		notes.append("Çağı: " + str(e["era_note"]))
	if not notes.is_empty():
		var src := _rich(15)
		src.name = "Source"
		src.add_theme_color_override("default_color", INK_SOFT)
		src.text = "[i]%s[/i]" % "\n".join(notes)
		_content.add_child(src)


func _section_block(n: int, heading: String, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var num := NumberBadge.new("%02d" % n)
	row.add_child(num)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	var h := _ink(DestanKitabi.upper_tr(heading), 18, "Cinzel", 700, ACCENT, 1)
	col.add_child(h)
	var body := _rich(19)
	body.text = text.replace("\n\n", "\n")
	col.add_child(body)
	row.add_child(col)
	return row


func _add_lineage(e: Dictionary) -> void:
	var lineage: Dictionary = e.get("lineage", {})
	var groups: Array = []
	var has_kin := not (lineage.get("up", []) as Array).is_empty() or not (lineage.get("down", []) as Array).is_empty()
	for g: Array in [["up", "Üst soy"], ["down", "Alt soy"], ["side", "Yan bağlar" if has_kin else "Bağlar"]]:
		var rows: Variant = lineage.get(g[0], [])
		if rows is Array and not (rows as Array).is_empty():
			groups.append([g[1], rows])
	if groups.is_empty():
		return
	var title := _ink(DestanKitabi.upper_tr(LINEAGE_TITLE), 20, "Cinzel", 700, INK, 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)
	for g: Array in groups:
		var pill := _ink(str(g[0]), 16, "AlegreyaSC-Regular", 400, ACCENT)
		_content.add_child(pill)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		for rel: Variant in g[1]:
			if not rel is Dictionary:
				continue
			var id := str(rel.get("id", ""))
			var open := _by_id.has(id)
			var other: Dictionary = _by_id.get(id, {})
			var card := LineageCard.new(id, str(other.get("title", "")), str(rel.get("label", "")), not open)
			if open:
				card.thumb_path = _thumb_path(other)
				card.texture = _thumbs.get(card.thumb_path)
				_want_thumb(card.thumb_path)
				card.pressed.connect(func() -> void: open_entry(id))
			flow.add_child(card)
			_lineage_cards.append(card)
		_content.add_child(flow)
	if not str(lineage.get("note", "")).is_empty():
		var note := _rich(16)
		note.add_theme_color_override("default_color", INK_SOFT)
		note.text = "[i]%s[/i]" % str(lineage["note"])
		_content.add_child(note)
	_content.add_child(Rule.new())


## Soy kartları (sınama için).
func get_lineage_cards() -> Array[LineageCard]:
	return _lineage_cards


## Bölüm sekmeleri (sınama için).
func get_tabs() -> Array[SectionTab]:
	return _tabs


## Dizin satırları (sınama için).
func get_rows() -> Array[IndexRow]:
	return _rows


static func _speaks(e: Dictionary) -> bool:
	return e.get("speaks", true) != false


func _vrule() -> Control:
	var r := VRule.new()
	r.custom_minimum_size = Vector2(14, 0)
	return r


## Gölgesiz mürekkep yazısı (parşömenin üstünde gölge kirli görünür).
static func _ink(text: String, font_size: int, font_name: String, weight: int, color: Color, spacing: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UIKit.font(font_name, weight, spacing))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _rich(font_size: int) -> RichTextLabel:
	var r := UIKit.rich(font_size, "Alegreya")
	r.add_theme_color_override("default_color", INK)
	r.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	r.add_theme_constant_override("shadow_outline_size", 0)
	r.add_theme_constant_override("line_separation", 4)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


## Metni genişliğe sığdırır; taşarsa sonunu «…» ile keser.
static func fit_text(font: Font, text: String, width: float, font_size: int) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return text
	var t := text
	while t.length() > 1 and font.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		t = t.left(t.length() - 1)
	return t.strip_edges() + "…"


## Yuvarlak portre: küçük resim ortadan kesilip daireye çizilir; yoksa baş harf, açılmamış kişide keçe siluet.
static func draw_portrait(ci: CanvasItem, c: Vector2, r: float, tex: Texture2D, initial: String, locked: bool = false) -> void:
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var n := 40
	var tsize := tex.get_size() if tex else Vector2.ONE
	var side := minf(tsize.x, tsize.y)
	var uk := Vector2(side / tsize.x, side / tsize.y) * 0.5
	for i in n:
		var d := Vector2.from_angle(TAU * i / n)
		pts.append(c + d * r)
		uvs.append(Vector2(0.5, 0.5) + d * uk)
	if locked:
		ci.draw_colored_polygon(pts, EncyclopediaPage.FELT)
		var head := c + Vector2(0, -r * 0.22)
		ci.draw_circle(head, r * 0.3, EncyclopediaPage.FELT.lightened(0.18))
		ci.draw_arc(c + Vector2(0, r * 0.95), r * 0.62, PI, TAU, 16, EncyclopediaPage.FELT.lightened(0.18), r * 0.5)
	elif tex:
		ci.draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)
	else:
		ci.draw_colored_polygon(pts, EncyclopediaPage.PAPER.darkened(0.12))
		var f := UIKit.font("Cinzel", 700)
		var fs := int(r * 0.95)
		var w := f.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(f, c + Vector2(-w * 0.5, fs * 0.36), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(EncyclopediaPage.INK, 0.62))
	pts.append(pts[0])
	ci.draw_polyline(pts, EncyclopediaPage.RULE, 2.0, true)


# --- Parçalar ----------------------------------------------------------------------------------------

## Üstteki bölüm sekmesi: simge ve ad. Açık bölüm koyu mürekkep ve pas rengi çizgi; öteki sayfanın bölümü soluk.
class SectionTab extends Button:
	var section := ""
	var glyph := ""
	var text_label := ""
	var active := false
	var own := true

	func _init(p_section: String, p_glyph: String, p_label: String, p_own: bool) -> void:
		section = p_section
		glyph = p_glyph
		text_label = p_label
		own = p_own
		custom_minimum_size = Vector2(150, 64)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var hot := is_hovered()
		var ink := EncyclopediaPage.INK
		var col := ink if active else Color(ink, 0.82 if hot else (0.58 if own else 0.4))
		if active:
			draw_rect(Rect2(Vector2(4, 2), size - Vector2(8, 4)), EncyclopediaPage.SELECT, true)
		GameMenu.draw_glyph(self, glyph, Vector2(size.x * 0.5, 20.0), 10.0, col)
		var f := UIKit.font("Cinzel", 700, 1)
		var fs := 15
		var t := EncyclopediaPage.fit_text(f, DestanKitabi.upper_tr(text_label), size.x - 10.0, fs)
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2((size.x - w) * 0.5, 50.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if active:
			draw_line(Vector2(size.x * 0.5 - w * 0.5, 58.0), Vector2(size.x * 0.5 + w * 0.5, 58.0), EncyclopediaPage.ACCENT, 2.0)


## Q ya da E tuş kapağı (sekmelerin iki yanında; işi GameMenu yapar).
class KeyCap extends Control:
	var key := ""

	func _init(k: String) -> void:
		key = k
		custom_minimum_size = Vector2(44, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2(4, 16), Vector2(36, 32))
		draw_rect(r, Color(EncyclopediaPage.INK, 0.08), true)
		draw_rect(r, EncyclopediaPage.RULE, false, 1.5)
		var f := UIKit.font("Cinzel", 700)
		var w := f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(f, Vector2(r.get_center().x - w * 0.5, r.get_center().y + 6.0), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, EncyclopediaPage.INK)


## Dizinde bir kişi: yuvarlak portre (128 px küçük resimden), ad ve san; seçiliyken koyu şerit ve pas çubuk.
class IndexRow extends Button:
	var entry_id := ""
	var title := ""
	var sub := ""
	var thumb_path := ""
	var texture: Texture2D
	var selected := false

	func _init(id: String, p_title: String, p_sub: String) -> void:
		entry_id = id
		title = p_title
		sub = p_sub
		custom_minimum_size = Vector2(0, EncyclopediaPage.ROW_H)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if selected:
			draw_rect(r, EncyclopediaPage.SELECT, true)
			draw_rect(Rect2(Vector2.ZERO, Vector2(4, size.y)), EncyclopediaPage.ACCENT, true)
		elif is_hovered():
			draw_rect(r, EncyclopediaPage.HOVER, true)
		var rad := EncyclopediaPage.THUMB_D * 0.5
		var c := Vector2(14.0 + rad, size.y * 0.5)
		EncyclopediaPage.draw_portrait(self, c, rad, texture, title.left(1))
		var x := c.x + rad + 14.0
		var w := size.x - x - 8.0
		var bold := UIKit.font("Alegreya", 700)
		draw_string(bold, Vector2(x, size.y * 0.5 - 2.0), EncyclopediaPage.fit_text(bold, title, w, 21), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, EncyclopediaPage.INK)
		if sub != "":
			var it := UIKit.font("Alegreya-Italic")
			draw_string(it, Vector2(x, size.y * 0.5 + 21.0), EncyclopediaPage.fit_text(it, sub, w, 15), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, EncyclopediaPage.INK_SOFT)


## Ortadaki görsel alanı: görsel en-boy oranıyla sığdırılır. Görsel yoksa baş harf ve yazı, kayıt yoksa kapak.
class Stage extends Control:
	signal clicked

	var texture: Texture2D
	var initial := ""
	var message := ""
	var cover := false
	var waiting := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		resized.connect(queue_redraw)
		clip_contents = true

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and texture:
			clicked.emit()
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(EncyclopediaPage.INK, 0.05), true)
		draw_rect(r.grow(-1.0), EncyclopediaPage.RULE, false, 1.5)
		if texture:
			var ts := texture.get_size()
			var k := minf((size.x - 16.0) / ts.x, (size.y - 16.0) / ts.y)
			var ds := ts * k
			draw_texture_rect(texture, Rect2((size - ds) * 0.5, ds), false)
			return
		var c := size * 0.5
		var f := UIKit.font("Cinzel", 700)
		if cover:
			var title := DestanKitabi.upper_tr(DestanKitabi.TITLE)
			var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			draw_string(f, Vector2(c.x - w * 0.5, c.y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, EncyclopediaPage.INK)
			var it := UIKit.font("Alegreya-Italic")
			var sub := EncyclopediaPage.COVER_SUB
			var w2 := it.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
			draw_string(it, Vector2(c.x - w2 * 0.5, c.y + 36.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, EncyclopediaPage.INK_SOFT)
			for s: float in [-1.0, 0.0, 1.0]:
				var p := c + Vector2(s * 26.0, -66.0)
				draw_polyline(PackedVector2Array([p + Vector2(0, -10), p + Vector2(10, 0), p + Vector2(0, 10), p + Vector2(-10, 0), p + Vector2(0, -10)]), EncyclopediaPage.RULE, 2.0, true)
			return
		if waiting:
			return
		# Görsel yok: baş harf boş bir kutuda, altında yazı (sitenin kitabındaki gibi).
		var box := Rect2(c - Vector2(70, 110), Vector2(140, 140))
		draw_rect(box, Color(EncyclopediaPage.INK, 0.04), true)
		draw_rect(box, Color(EncyclopediaPage.INK, 0.3), false, 1.5)
		var w3 := f.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, 84).x
		draw_string(f, Vector2(c.x - w3 * 0.5, box.get_center().y + 30.0), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, 84, Color(EncyclopediaPage.INK, 0.45))
		if message != "":
			var it2 := UIKit.font("Alegreya-Italic")
			var w4 := it2.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(it2, Vector2(c.x - w4 * 0.5, box.end.y + 40.0), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, EncyclopediaPage.INK_SOFT)


## Görsel şeridindeki yuva: küçük görsel (yoksa «yok») ve adı; açık yuva pas renkli çerçeveli.
class SlotButton extends Button:
	var kind := "art"
	var texture: Texture2D
	var active := false
	var available := false

	func _init() -> void:
		custom_minimum_size = Vector2(112, 118)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var box := Rect2(Vector2(6, 2), Vector2(size.x - 12.0, size.y - 30.0))
		draw_rect(box, Color(EncyclopediaPage.INK, 0.06), true)
		if texture:
			# Kutuyu doldurur, taşanı ortadan keser.
			var ts := texture.get_size()
			var k := maxf(box.size.x / ts.x, box.size.y / ts.y)
			var src := Rect2((ts - box.size / k) * Vector2(0.5, 0.0), box.size / k)
			draw_texture_rect_region(texture, box, src)
		elif not available:
			var it := UIKit.font("Alegreya-Italic")
			var w := it.get_string_size("yok", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(it, Vector2(box.get_center().x - w * 0.5, box.get_center().y + 6.0), "yok", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, EncyclopediaPage.INK_SOFT)
		if kind == "model":
			GameMenu.draw_glyph(self, "cube", box.position + Vector2(18, 18), 9.0, EncyclopediaPage.ACCENT)
		draw_rect(box, EncyclopediaPage.ACCENT if active else (EncyclopediaPage.RULE if is_hovered() else Color(EncyclopediaPage.RULE, 0.5)), false, 3.0 if active else 1.5)
		var f := UIKit.font("Cinzel", 700, 1)
		var label := str(EncyclopediaPage.SLOT_LABELS.get(kind, kind))
		var w2 := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(f, Vector2((size.x - w2) * 0.5, size.y - 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, EncyclopediaPage.INK if active else EncyclopediaPage.INK_SOFT)


## Şeridin iki yanındaki ok (← →).
class Arrow extends Button:
	var dir := 1

	func _init(d: int) -> void:
		dir = d
		custom_minimum_size = Vector2(34, 96)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		var d := 8.0 * dir
		var col := EncyclopediaPage.ACCENT if is_hovered() else EncyclopediaPage.INK_SOFT
		draw_polyline(PackedVector2Array([c + Vector2(-d * 0.6, -10), c + Vector2(d * 0.6, 0), c + Vector2(-d * 0.6, 10)]), col, 2.5, true)


## Başlığın yanındaki hoparlör (K86); yanında tuşunun ipucu (Boşluk). Çalarken pas renkli dolar.
class SpeakerButton extends Button:
	var playing := false

	func _init() -> void:
		custom_minimum_size = Vector2(118, 48)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "Kendini tanıtsın"
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var c := Vector2(24, size.y * 0.5)
		var hot := is_hovered()
		draw_circle(c, 21.0, EncyclopediaPage.ACCENT if playing else Color(EncyclopediaPage.INK, 0.08 if not hot else 0.14))
		draw_arc(c, 21.0, 0, TAU, 32, EncyclopediaPage.ACCENT if (hot or playing) else EncyclopediaPage.RULE, 1.6, true)
		GameMenu.draw_glyph(self, "speaker", c + Vector2(1, 0), 10.0, EncyclopediaPage.PAPER if playing else EncyclopediaPage.INK)
		var f := UIKit.font("Cinzel", 700)
		var key := EncyclopediaPage.SPEAKER_KEY
		var w := f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var r := Rect2(Vector2(52, c.y - 12.0), Vector2(w + 14.0, 24))
		draw_rect(r, Color(EncyclopediaPage.INK, 0.06), true)
		draw_rect(r, EncyclopediaPage.RULE, false, 1.0)
		draw_string(f, Vector2(r.position.x + 7.0, c.y + 5.0), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, EncyclopediaPage.INK_SOFT)


## Soy bağının portreli kartı: basınca o kişiye gider. Açılmamış kişi adsız keçe siluettir, basılmaz.
class LineageCard extends Button:
	var target := ""
	var title := ""
	var relation := ""
	var locked := false
	var thumb_path := ""
	var texture: Texture2D

	func _init(id: String, p_title: String, p_relation: String, p_locked: bool) -> void:
		target = id
		title = p_title
		relation = p_relation
		locked = p_locked
		disabled = locked
		var f := UIKit.font("Alegreya", 700)
		var it := UIKit.font("Alegreya-Italic")
		var w := maxf(f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x, it.get_string_size(relation, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
		custom_minimum_size = Vector2(clampf(w + 70.0, 150.0, 300.0), 54)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, EncyclopediaPage.HOVER if is_hovered() and not locked else Color(EncyclopediaPage.INK, 0.04), true)
		draw_rect(r.grow(-0.5), Color(EncyclopediaPage.RULE, 0.6), false, 1.0)
		var c := Vector2(28, size.y * 0.5)
		EncyclopediaPage.draw_portrait(self, c, 20.0, texture, title.left(1), locked)
		var x := 56.0
		var w := size.x - x - 6.0
		var it := UIKit.font("Alegreya-Italic")
		if locked:
			draw_string(it, Vector2(x, c.y + 6.0), EncyclopediaPage.fit_text(it, relation, w, 14), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(EncyclopediaPage.INK, 0.42))
			return
		var f := UIKit.font("Alegreya", 700)
		draw_string(f, Vector2(x, c.y - 3.0), EncyclopediaPage.fit_text(f, title, w, 17), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, EncyclopediaPage.INK)
		draw_string(it, Vector2(x, c.y + 16.0), EncyclopediaPage.fit_text(it, relation, w, 14), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, EncyclopediaPage.INK_SOFT)


## Çağ rozeti (K35): pas mürekkepli yuvarlak mühür («YILLIKTAN», «TAŞTAN», «OZAN DER», «BİZİM»).
class BadgeSeal extends Control:
	var text := ""

	func _init(t: String) -> void:
		text = t
		var f := UIKit.font("Cinzel", 700, 1)
		var w := f.get_string_size(DestanKitabi.upper_tr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		custom_minimum_size = Vector2(w + 44.0, 46)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip_text = text

	func _draw() -> void:
		var col := EncyclopediaPage.ACCENT
		draw_set_transform(size * 0.5, -0.04, Vector2.ONE)
		var half := size * 0.5 - Vector2(2, 2)
		var r := Rect2(-half, half * 2.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col, 0.08)
		sb.border_color = col
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(int(half.y))
		draw_style_box(sb, r)
		var inner := StyleBoxFlat.new()
		inner.draw_center = false
		inner.border_color = Color(col, 0.6)
		inner.set_border_width_all(1)
		inner.set_corner_radius_all(int(half.y - 5.0))
		draw_style_box(inner, r.grow(-5.0))
		var f := UIKit.font("Cinzel", 700, 1)
		var t := DestanKitabi.upper_tr(text)
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(f, Vector2(-w * 0.5, 5.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Numaralı bölümün sayısı («01»): pas renkli küçük elmasın içinde.
class NumberBadge extends Control:
	var text := ""

	func _init(t: String) -> void:
		text = t
		custom_minimum_size = Vector2(46, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 20.0)
		var d := 19.0
		draw_polyline(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0), c + Vector2(0, -d)]), EncyclopediaPage.ACCENT, 1.6, true)
		var f := UIKit.font("Cinzel", 700)
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(f, Vector2(c.x - w * 0.5, c.y + 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, EncyclopediaPage.ACCENT)


## İnce yatay çizgi, ortasında küçük bir elmas.
class Rule extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(0, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var y := size.y * 0.5
		var cx := size.x * 0.5
		draw_line(Vector2(0, y), Vector2(cx - 10.0, y), EncyclopediaPage.RULE, 1.0)
		draw_line(Vector2(cx + 10.0, y), Vector2(size.x, y), EncyclopediaPage.RULE, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 5), Vector2(cx + 5, y), Vector2(cx, y + 5), Vector2(cx - 5, y)]), EncyclopediaPage.ACCENT)


## Sütunları ayıran dikey çizgi.
class VRule extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var x := size.x * 0.5
		draw_line(Vector2(x, 8), Vector2(x, size.y - 8), EncyclopediaPage.RULE, 1.0)
		var c := Vector2(x, size.y * 0.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(5, 0), c + Vector2(0, 5), c + Vector2(-5, 0)]), EncyclopediaPage.ACCENT)
