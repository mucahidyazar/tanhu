class_name GameplayHud
extends Control
## Oyun içi HUD (kullanıcının görseli: docs/media/review/hud_referans.webp; yan yana kanıt docs/media/review/hud_karsilastirma.jpg):
##   sol üst   HudPortrait     portre, seviye rozeti, can ve takat çubukları (Vitals), iki durum yuvası
##   sağ üst   HudMinimap      pişirilmiş dünyadan (WorldMap) yuvarlak mini harita, oyuncu oku, görev baklavası
##             HudQuestCard    görev kartı: başlık, sancak, amaç, ayrıntı
##   alt orta  HudHotbar       dokuz altıgen yuva ve XP çubuğu (çocukta yalnız oyuncak yay, 3. yuva)
##   sağ alt   HudMenuButtons  I (Envanter), J (Görevler), M (Harita)
##   alt orta  HudActionPrompt o an yapılabilecek («E Bin»), şeridin üstünde; tuş ipuçları (GameHud.hud_style) XP çubuğunun altında
##   ekran     HudPointer      görevin yönü: hedefin üstünde iğne ya da ekranın kenarında ok ve uzaklık
## I (InputSetup: inventory) Envanter'i açar (HudInventoryScreen; oyun durur, Esc, I ya da kapatma düğmesi kapatır). M ve J yolculuğun
## kitabını (duraklatma, GameMenu) HARİTA ve GÖREVLER sayfalarında açar: book_requested(sayfa) yayılır, main.gd kitabı açar; sayfaların
## verisi map_page_data() ve journal_quests()'tir. HUD yalnız live_check doğruyken görünür (main.gd: State.PLAYING; Çocukluk ve Serbest Gez); sinemada, menüde,
## oluşturucuda, duraklatmada ve köprülerde gizlidir. Gizlenmesi anlıktır (duraklatmanın küçük resmi arayüzsüz çekilir), belirmesi
## kısa bir solmayla. Görev kaynağı hud_quest() ve hud_target(oyuncunun_yeri) taşıyan bir nesnedir (ChildhoodScene, CampTour).
## Arayüz 1080 satıra çizilir, her parça kendi köşesinde UIKit.ui_k() × HudKit.HUD_SCALE (0,8; Ayarlar'ın tek «Arayüz ölçeği», %50–%150,
## menülerle birlikte ölçekler, K104) ile ölçeklenir (16:10'da, 2K/4K'de kenara yapışık kalır). Yuva şeridine basmak (1–4, Q, E ya da tıklamak) boş yuvada da kısa bir basılma efekti verir (HudHotbar).
## HUD görünürken oyuncunun ipucu panelinin (PlayerPrompt) yerine HUD'un dilindeki HudActionPrompt görünür (aynı çiftler,
## PlayerController.prompt_changed), tuş ipuçları XP çubuğunun altında ortalı şeride geçer, bildirim (MenuToast) üst ortaya: hiçbiri
## birbirinin ya da HUD'un üstüne binmez.
## Oturumla (Session; main.gd): heybe oturumun envanteridir (bag.set_inventory), seviye ve XP ilerlemeden (vitals.bind_progression);
## kayıtsız sahneler (Çocukluk, Serbest Gez'in Çocuğu, Yola Çıkış) bedeni begin_body ile baştan kurar, oturumlu yetişkin
## begin_body(true) ile heybesini korur. Yükün yürüyüşe etkisi (Inventory.move_mods) oyuncuya yazılır (hız, koşu, zıplama, koşunun
## takat gideri). Yetişkinin portresi görünüşünden pişer (HudPortrait.set_profile, PortraitBaker). G basılı 0,6 sn «Yükü Bırak»: Sırt
## sekmesi yer yığını olur (kısa basış ileride Ku'ya «Bak»); basılı tutuşun halkası şeridin üstünde (show_hold; ateş başında Dinlen de
## kullanır). E dünyadaki kabı (WorldSpots containers) ve yetişkinde yer yığınını Envanter'in aktarma sekmesinde açar (interaction,
## open_container).

signal screen_opened(kind: String)
signal screen_closed(kind: String)
## M / J ya da düğme: yolculuğun kitabı bu sayfada açılsın ("harita", "gorevler").
signal book_requested(page: String)

## Düğmenin ya da tuşun sayfası → kitabın sayfası (Envanter kendi ekranıdır).
const BOOK_PAGES := {"map": "harita", "journal": "gorevler"}

## Çocuğun yuvaları: yalnız 3. yuvada oyuncak yay (becerisi yok).
const CHILD_LOADOUT := {2: {"icon": "icon_toy_bow"}}
const SCREEN_LAYER := 100
const FADE_IN := 0.35
## Görev yazısının yoklama aralığı (sn).
const POLL := 0.2
## Tuş ipuçları şeridinin alt kenarının ekranın altına uzaklığı (1080 satır; XP çubuğunun altı).
const HINTS_BOTTOM := 12.0
## «Yükü Bırak»ın basılı süresi (sn; economy.md §4.2) ve yetişkinin yer yığınını açtığı erim (m).
const DROP_HOLD_S := 0.6
const PILE_REACH := 1.3
## Basılı tutuşun halkası: merkezi (alt ortaya göre, 1080 satır) ve yarıçapı.
## Basılı tutuşun halkası eylem şeridinin üst kenarının HOLD_GAP üstünde durur, adı halkanın üstündedir (1080 satır): şeride ve tuş
## ipuçlarına değmez.
const HOLD_GAP := 12.0
const HOLD_RADIUS := 22.0

var player: PlayerController
var camera: FollowCamera
var vitals := Vitals.new()
var bag := HudBag.new()
## Görev kaynağı (hud_quest, hud_target) ya da null.
var quest_source: Object
## Görevler sayfasındaki bitmiş görevler ({title, steps, done: true}).
var finished_quests: Array = []
var map: WorldMap
## HUD'un görünmesi gereken an (main.gd verir); yoksa hiç görünmez.
var live_check: Callable
## Şeridin üstüne kaldırılan ipucu (PlayerPrompt), tuş ipuçlarının paneli (GameHud, sol alt) ve üst ortaya geçen bildirim (MenuToast).
var prompt: Control
var hints: GameHud
var toast: MenuToast
## Dünyanın yerleri (main.gd): () -> WorldSpots; E'nin kapları buradan.
var spots_source: Callable

var portrait: HudPortrait
var minimap: HudMinimap
var quest_card: HudQuestCard
var hotbar: HudHotbar
var buttons: HudMenuButtons
var pointer: HudPointer
var action_prompt: HudActionPrompt

var _screen_layer: CanvasLayer
var _screen: HudScreen
var _shown := false
var _fade: Tween
var _poll_left := 0.0
var _quest: Dictionary = {}
var _prompt_pairs: Array = []
## Sayfa açıkken gizlenen ekran parçaları (tuş ipuçları, bildirim) ve önceki görünürlükleri.
var _hidden_for_screen: Array = []
## Basılı tutuşun halkası: yazısı ve doluluğu (0 gizli).
var _hold_label := ""
var _hold_p := 0.0
## G basıldı mı ve ne kadar basılı (sn).
var _g_down := false
var _g_hold := 0.0
## Aktarma sekmesinde açılan yer yığını (kapanınca boşsa kalkar).
var _open_pile: ItemContainer


func _ready() -> void:
	name = "GameplayHud" if name.is_empty() else name
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	UIKit.full_rect(self)
	pointer = HudPointer.new()
	pointer.name = "Pointer"
	add_child(pointer)
	portrait = HudPortrait.new()
	portrait.name = "Portrait"
	portrait.vitals = vitals
	add_child(portrait)
	minimap = HudMinimap.new()
	minimap.name = "Minimap"
	add_child(minimap)
	quest_card = HudQuestCard.new()
	quest_card.name = "QuestCard"
	quest_card.visible = false
	add_child(quest_card)
	hotbar = HudHotbar.new()
	hotbar.name = "Hotbar"
	add_child(hotbar)
	buttons = HudMenuButtons.new()
	buttons.name = "MenuButtons"
	buttons.pressed.connect(func(kind: String) -> void: open_page(kind))
	add_child(buttons)
	action_prompt = HudActionPrompt.new()
	action_prompt.name = "ActionPrompt"
	action_prompt.visible = false
	add_child(action_prompt)
	_screen_layer = CanvasLayer.new()
	_screen_layer.name = "Screens"
	_screen_layer.layer = SCREEN_LAYER
	_screen_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_screen_layer)
	UIKit.on_ui_scale_changed(self, _apply_scale)
	_apply_scale()
	visible = false
	if map:
		minimap.set_map(map)


## Oyuncuya ve kameraya bağlar (bir kez): yerden alınan av heybeye girer; heybe oyuncuyu bilir (yere bırakma, yakındaki atın terkisi),
## alınamayan eşya bildirimde yazar («Yük dolu»).
func bind(p_player: PlayerController, p_camera: FollowCamera) -> void:
	player = p_player
	camera = p_camera
	bag.player = p_player
	if not bag.refused.is_connected(_on_bag_refused):
		bag.refused.connect(_on_bag_refused)
	if player and not player.target_collected.is_connected(bag.on_collected):
		player.target_collected.connect(bag.on_collected)
	if player and not player.prompt_changed.is_connected(_on_prompt_changed):
		player.prompt_changed.connect(_on_prompt_changed)
	if not bag.changed.is_connected(_sync_move_mods):
		bag.changed.connect(_sync_move_mods)
	_sync_move_mods()


## Yükün yürüyüşe etkisi oyuncuya ve takate yazılır (Inventory.move_mods: hız, koşu, zıplama, koşunun takat gideri; economy.md §4.1).
func _sync_move_mods() -> void:
	if bag.inventory == null:
		return
	var mods := bag.inventory.move_mods()
	if player:
		player.move_mods = mods
	vitals.run_cost_k = float(mods.get("run_cost_k", 1.0))


func _on_bag_refused(text: String) -> void:
	if toast and is_instance_valid(toast) and _screen == null:
		toast.show_text(text, "warn")


## Oyuncunun o an yapabileceği (PlayerController.prompt_changed): HUD'un dilindeki şeritte gösterilir.
func _on_prompt_changed(pairs: Array) -> void:
	_prompt_pairs = pairs.duplicate()
	if action_prompt:
		action_prompt.set_pairs(_prompt_pairs)


## Yeni beden ya da yeni sahne: can, takat ve yuvalar baştan; portre kişinin. Heybe kayıtsız sahnede (Çocukluk, Serbest Gez'in Çocuğu,
## Yola Çıkış) bedenle baştan kurulur; keep_bag (oturumlu yetişkin: deneme haritası, kayıttan yükleme) heybeye dokunmaz.
func begin_body(keep_bag: bool = false) -> void:
	vitals.reset()
	var child := player != null and player.is_child()
	if not keep_bag:
		bag.reset(child)
	_refresh_portrait()
	if hotbar:
		hotbar.set_loadout(CHILD_LOADOUT if child else {})
	_poll_left = 0.0
	_sync_move_mods()


## Portre kişinin: çocukta boyalı portre, yetişkinde görünüşünden pişen portre.
func _refresh_portrait() -> void:
	if portrait == null:
		return
	portrait.set_person(player.person_id() if player else "")
	if player and not player.is_child() and player.get_avatar():
		var avatar := player.get_avatar()
		portrait.set_profile(avatar.get_profile(), avatar.worn_outfit(), avatar.worn_cape())


func set_world_map(p_map: WorldMap) -> void:
	map = p_map
	if minimap:
		minimap.set_map(map)


func set_quest_source(source: Object) -> void:
	quest_source = source
	_quest = {}
	_poll_left = 0.0


## HUD şu an görünüyor mu?
func is_shown() -> bool:
	return _shown


## Açık sayfa (yoksa null).
func screen() -> HudScreen:
	return _screen


func is_screen_open() -> bool:
	return _screen != null


## Görevin o anki yazıları (yoklanan; sınama).
func quest_info() -> Dictionary:
	return _quest


## Hemen gizler (duraklatmanın küçük resmi): bir sonraki karede live_check yeniden sorulur.
func hide_now() -> void:
	_set_shown(false)


func _is_live() -> bool:
	return _screen == null and live_check.is_valid() and bool(live_check.call())


func _process(delta: float) -> void:
	var live := _is_live()
	if live != _shown:
		_set_shown(live)
	if not _shown or get_tree().paused:
		return
	_tick(delta)


func _set_shown(on: bool) -> void:
	_shown = on
	if _fade and _fade.is_valid():
		_fade.kill()
	if not on:
		visible = false
		modulate.a = 0.0
		_lift_prompt(false)
		return
	visible = true
	if portrait and player:
		_refresh_portrait()
	_poll_left = 0.0
	_tick(0.0)
	_lift_prompt(true)
	modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(self, ^"modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE)


func _tick(delta: float) -> void:
	if player == null:
		return
	# Yüklü yürüyüşün hızları da yükle çarpılır: koşu eşiği gerçek koşunun ortasında kalır.
	var k := player.load_speed_k()
	vitals.tick(delta, player.get_speed(), player.is_riding(), player.walk_speed * k, player.run_speed * k)
	_tick_drop(delta)
	hotbar.set_xp(vitals.xp_ratio())
	var p := player.global_position if player.is_inside_tree() else player.position
	var target := _target(p)
	minimap.player_xz = Vector2(p.x, p.z)
	minimap.facing = player.get_facing_yaw()
	minimap.camera_yaw = camera.get_yaw() if camera else 0.0
	minimap.target_xz = Vector2(target.x, target.z) if target != Vector3.INF else Vector2.INF
	pointer.target = target
	pointer.player_pos = p
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = POLL
		_poll_quest()


func _target(from: Vector3) -> Vector3:
	if quest_source == null or not is_instance_valid(quest_source) or not quest_source.has_method(&"hud_target"):
		return Vector3.INF
	var t: Variant = quest_source.call(&"hud_target", from)
	return t if t is Vector3 else Vector3.INF


func _poll_quest() -> void:
	var q: Dictionary = {}
	if quest_source and is_instance_valid(quest_source) and quest_source.has_method(&"hud_quest"):
		q = quest_source.call(&"hud_quest")
	_quest = q
	quest_card.set_quest(str(q.get("title", "")), str(q.get("objective", "")), str(q.get("detail", "")))


func _unhandled_input(event: InputEvent) -> void:
	if not _shown or _screen != null or get_tree().paused:
		return
	if InputMap.has_action(&"drop_load") and event.is_action_pressed(&"drop_load") and not event.is_echo():
		_g_down = true
		_g_hold = 0.0
		get_viewport().set_input_as_handled()
		return
	for pair: Array in [[&"map", "map"], [&"inventory", "bag"], [&"journal", "journal"]]:
		if InputMap.has_action(pair[0]) and event.is_action_pressed(pair[0]):
			if open_page(str(pair[1])):
				get_viewport().set_input_as_handled()
			return


## G basılı: 0,6 sn'ye varınca Yükü Bırak; erken bırakılırsa kısa basıştır (ileride Ku'ya «Bak»; bugün bir şey yapmaz).
func _tick_drop(delta: float) -> void:
	if not _g_down:
		return
	if not Input.is_action_pressed(&"drop_load"):
		_g_down = false
		show_hold("", 0.0)
		return
	_g_hold += delta
	var lang := HudBag.lang()
	show_hold("Yükü Bırak" if lang != "en" else "Drop Load", _g_hold / DROP_HOLD_S)
	if _g_hold >= DROP_HOLD_S:
		_g_down = false
		show_hold("", 0.0)
		drop_load()


## Yükü Bırak (economy.md §4.2): Sırt sekmesi oyuncunun önünde yer yığını olur; bildirim ne bırakıldığını söyler. Döner: bırakılanlar.
func drop_load() -> Array:
	var lang := HudBag.lang()
	var dropped := bag.drop_back()
	if toast and is_instance_valid(toast):
		if dropped.is_empty():
			toast.show_text("Sırtında yük yok." if lang != "en" else "You carry nothing on your back.")
		else:
			var parts := PackedStringArray()
			for it: Dictionary in dropped:
				parts.append("%s × %d" % [ItemCatalog.name_of(str(it["id"]), lang), int(it["n"])])
			toast.show_text(("Yük bırakıldı: %s" if lang != "en" else "Load dropped: %s") % ", ".join(parts))
	return dropped


## Basılı tutuşun halkası (Yükü Bırak, ateş başında Dinlen): yazı ve doluluk (0..1); boş yazı ya da 0 gizler.
func show_hold(label: String, progress: float) -> void:
	var p := clampf(progress, 0.0, 1.0) if not label.is_empty() else 0.0
	if p == _hold_p and label == _hold_label:
		return
	_hold_label = label
	_hold_p = p
	queue_redraw()


## Halkanın o anki doluluğu (sınama).
func hold_progress() -> float:
	return _hold_p


func _draw() -> void:
	if _hold_p <= 0.0 or _hold_label.is_empty():
		return
	var k := UIKit.ui_k() * HudKit.hud_scale()
	var c := hold_center()
	var r := HOLD_RADIUS * k
	draw_circle(c, r + 6.0 * k, Color(HudKit.NAVY_DEEP, 0.78))
	draw_arc(c, r, 0.0, TAU, 48, Color(HudKit.SILVER, 0.35), 3.0 * k, true)
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * _hold_p, 48, HudKit.GOLD, 4.0 * k, true)
	HudKit.draw_text(self, HudKit.body_font(600), c - Vector2(0.0, r + 16.0 * k), _hold_label, int(round(20.0 * k)), HudKit.CREAM, 1,
		HudKit.SHADOW, 3)


## Halkanın merkezi (ekran pikseli): eylem şeridinin (HudActionPrompt) üst kenarından HOLD_GAP, halka ve hâlesi kadar yukarıda. Şerit
## HUD ölçeğiyle alt ortadan büyür; halka da aynı ölçekle onunla kalkar.
func hold_center() -> Vector2:
	var k := UIKit.ui_k() * HudKit.hud_scale()
	var lift := action_prompt.lift if action_prompt else 0.0
	var strip_top := (HudActionPrompt.BOTTOM + HudActionPrompt.HEIGHT - lift) * k
	return Vector2(size.x * 0.5, size.y - strip_top - (HOLD_GAP + HOLD_RADIUS + 6.0) * k)


## E'nin HUD işi (PlayerController.interaction_source üzerinden; main.gd): erimdeki kap (WorldSpots containers: Inventory'nin kabı, ör.
## Mete'nin sandığı) ya da yetişkinin erimindeki yer yığını; ikisi de Envanter'in aktarma sekmesinde açılır. Yoksa boş.
func interaction() -> Dictionary:
	if not _shown or _screen != null or player == null or not player.is_inside_tree():
		return {}
	var xz := Vector2(player.global_position.x, player.global_position.z)
	var lang := HudBag.lang()
	var open_label := "Aç" if lang != "en" else "Open"
	if spots_source.is_valid():
		var spots: Variant = spots_source.call()
		if spots is WorldSpots:
			var spot := (spots as WorldSpots).nearest("containers", xz)
			var store: Variant = bag.inventory.container(str(spot.get("store", ""))) if not spot.is_empty() else null
			if store is ItemContainer:
				var title := NewGameFlow.text(spot.get("title", {}), lang)
				return {"key": "E", "label": open_label, "run": func() -> void: open_container(store, title)}
	if not player.is_child():
		var near := bag.pile_near(xz, PILE_REACH)
		if not near.is_empty():
			var pile: ItemContainer = near["pile"]
			var pile_title := "YER YIĞINI" if lang != "en" else "GROUND PILE"
			return {"key": "E", "label": open_label, "run": func() -> void: open_pile(pile, pile_title)}
	return {}


## Yer yığınını aktarma sekmesinde açar; sekme kapanınca yığın boşaldıysa kalkar.
func open_pile(pile: ItemContainer, title_text: String) -> bool:
	if not open_container(pile, title_text):
		return false
	_open_pile = pile
	return true


## I, J, M ve düğmeler: "bag" Envanter'i açar, "map" ve "journal" kitabın HARİTA ve GÖREVLER sayfasını ister (book_requested).
## HUD görünmüyorsa ya da bir sayfa açıksa false.
func open_page(kind: String) -> bool:
	if not _shown or _screen != null:
		return false
	if BOOK_PAGES.has(kind):
		book_requested.emit(str(BOOK_PAGES[kind]))
		return true
	return open_screen(kind)


## Kitabın HARİTA sayfasının verisi: pişmiş harita, oyuncunun yeri ve bakışı, görevin hedefi ve amacı.
func map_page_data() -> Dictionary:
	var p := player.global_position if player and player.is_inside_tree() else Vector3.ZERO
	var t := _target(p)
	return {
		"map": map, "player_xz": Vector2(p.x, p.z), "facing": player.get_facing_yaw() if player else 0.0,
		"target_xz": Vector2(t.x, t.z) if t != Vector3.INF else Vector2.INF, "quest_text": str(_quest.get("objective", "")),
		"quest_title": str(_quest.get("title", "")),
	}


## Envanter'i açar ("bag"): oyun durur, HUD gizlenir. HUD görünmüyorsa ya da bir sayfa açıksa false.
func open_screen(kind: String) -> bool:
	if not _shown or _screen != null:
		return false
	var s: HudScreen
	match kind:
		"bag":
			var inv := HudInventoryScreen.new()
			inv.bag = bag
			inv.person = player.person_id() if player else ""
			# Yetişkinin 3B görseli kendi profilinden (çocuğunki ChildLook'tan).
			if player and inv.person.is_empty() and player.get_avatar():
				inv.profile = player.get_avatar().get_profile()
			s = inv
		_:
			return false
	s.name = kind.capitalize() + "Screen"
	_screen = s
	s.closed.connect(_on_screen_closed.bind(kind, s))
	_screen_layer.add_child(s)
	_set_shown(false)
	# Oyuncunun ipucu sayfanın arkasında görünmesin (görünürlüğü denetleyicinindir; yalnız saydamlaşır); tuş ipuçları ve bildirim
	# sayfa kapanana dek gizlenir (canlandırmaları oyunla birlikte durur).
	if prompt and is_instance_valid(prompt):
		prompt.modulate.a = 0.0
	_hidden_for_screen.clear()
	for n: CanvasItem in [hints, toast]:
		if n and is_instance_valid(n):
			_hidden_for_screen.append([n, n.visible])
			n.visible = false
	get_tree().paused = true
	screen_opened.emit(kind)
	return true


## E ile açılan bir kap (sandık, Menzil Ambarı, ambar): Envanter aktarma sekmesinde açılır (HudInventoryScreen.open_container).
func open_container(c: ItemContainer, title_text: String) -> bool:
	if not open_screen("bag"):
		return false
	(_screen as HudInventoryScreen).open_container(c, title_text)
	return true


## Açık sayfayı kapatır.
func close_screen() -> void:
	if _screen:
		_screen.close()


func _on_screen_closed(kind: String, s: HudScreen) -> void:
	if _screen != s:
		return
	_screen = null
	for pair: Array in _hidden_for_screen:
		if is_instance_valid(pair[0]):
			(pair[0] as CanvasItem).visible = pair[1]
	_hidden_for_screen.clear()
	if is_inside_tree():
		get_tree().paused = false
	if _open_pile:
		_open_pile = null
		bag.prune_piles()
	screen_closed.emit(kind)


## Görevler sayfasının listesi: süren görev, sonra bitenler.
func journal_quests() -> Array:
	var out: Array = []
	if quest_source and is_instance_valid(quest_source) and quest_source.has_method(&"hud_quest"):
		var q: Dictionary = quest_source.call(&"hud_quest")
		if not q.is_empty():
			out.append(q)
	out.append_array(finished_quests)
	return out


## Her parça kendi köşesinde ui_k() × HudKit.hud_scale() (0,8) ile çizilir: oyuncunun ölçeği (Ayarlar › Görüntü › «Arayüz ölçeği», K104)
## ui_k()'dadır, ayar %100'de HUD eski «HUD ölçeği %80»inin boyundadır. Alt ortadaki yuva şeridi ve eylem şeridi XP çubuğunun alt kenarından
## büyür (HudKit.lift_for): çubuğun altındaki tuş ipuçları şeridine hiçbir ölçekte değmez.
func _apply_scale() -> void:
	var k := UIKit.ui_k()
	var s := HudKit.hud_scale()
	if hints and is_instance_valid(hints):
		hints.extra_scale = s if hints.hud_style else 1.0
	var lift := HudKit.lift_for(s, xp_floor())
	if hotbar:
		hotbar.set_lift(lift)
	if action_prompt:
		action_prompt.set_lift(lift)
	for c: Control in [portrait, minimap, quest_card, hotbar, buttons, action_prompt]:
		if c:
			UIKit.scale_at_anchor(c, k * s)
	if pointer:
		pointer.ui_scale = k * s


## XP çubuğunun alt kenarının ekranın altına uzaklığı (1080 satır; ekranda × ui_k): HUD_FLOOR. HUD'un dilindeki tuş ipuçları şeridi HUD'un
## ölçeğinde çizilir; şeridin üstü bu çizgiye yaklaşırsa çubuk şeridin HINTS_GAP kadar üstünde durur (bugünkü tek satırlık şeritte çubuk
## HUD_FLOOR'da kalır).
func xp_floor() -> float:
	if hints and is_instance_valid(hints) and hints.hud_style:
		return maxf(HudKit.HUD_FLOOR, hints.strip_top() * HudKit.hud_scale() + HudKit.HINTS_GAP)
	return HudKit.HUD_FLOOR


## HUD açılınca: tuş ipuçları HUD'un dilinde XP çubuğunun altına ortalanır, bildirim üst ortaya geçer, oyuncunun ipucu panelinin yerine
## HUD'un şeridi görünür (on); kapanınca hepsi yerine döner.
func _lift_prompt(on: bool) -> void:
	if hints and is_instance_valid(hints):
		hints.hud_style = on
		hints.bottom_margin = HINTS_BOTTOM if on else 34.0
	if toast and is_instance_valid(toast):
		toast.centered = on
	if prompt and is_instance_valid(prompt):
		prompt.modulate.a = 0.0 if on else 1.0
	if action_prompt:
		action_prompt.set_pairs(_prompt_pairs if on else [])
	# Şeridin HUD ölçeği ve XP çubuğunun tabanı şeridin diline göre yeniden kurulur.
	_apply_scale()
