class_name HudPortrait
extends Control
## HUD'un sol üstü (referanstaki gibi): bulut kıvrımlı gümüş halkada kişinin portresi, halkanın altında lacivert-altın seviye rozeti,
## sağında ok uçlu iki çubuk (kırmızı can «100 / 100», yeşil takat «64 / 80»; sayılar yazılı), altında iki küçük kare durum yuvası
## (Vitals.statuses: koşu çizme, soluklanma ot; boşsa boş). Çubuklar değişince yumuşakça kayar. Sol üst köşeye çapalıdır, 1080 satıra
## çizilir; ölçeği GameplayHud verir (UIKit.scale_at_anchor).

## Kişi → portre dokusu (assets/ui/hud/). Oluşturulan yetişkinin (kişi "") portresi görünüşünden pişer (PortraitBaker: profil, kılık,
## pelerin; set_profile); pişene dek ya da çizici yokken (başsız) gök mavisi bir boşluk çizilir.
const PORTRAITS := {
	ChildLook.PERSON_METE: "portrait_mete_child",
	ChildLook.PERSON_CHILD: "portrait_child",
}
## Durum → simge ve renk çarpanı.
const STATUS_ICONS := {
	"run": ["icon_boot", Color.WHITE],
	"tired": ["icon_boot", Color(1.0, 0.55, 0.45)],
	"rest": ["icon_herb", Color.WHITE],
}
const BAR_TEXT_SIZE := 19
const LEVEL_TEXT_SIZE := 26
## Çubuğun gösterilen değerinin gerçeğe yaklaşma hızı (1/sn).
const EASE := 9.0

var vitals: Vitals
var person := ""
## Yetişkinin görünüşünün anahtarı (PortraitBaker.key_of) ve pişmiş portresi (yoksa null).
var profile_key := ""
var baked: Texture2D

var _hp_shown := -1.0
var _stamina_shown := -1.0
var _statuses := PackedStringArray()
var _baker: PortraitBaker


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = HudKit.PORTRAIT_SIZE.x
	offset_bottom = HudKit.PORTRAIT_SIZE.y


func set_person(id: String) -> void:
	if person != id:
		person = id
		queue_redraw()


## Oluşturulan yetişkinin görünüşü: portresi bir kez pişer (önbellekte varsa hemen gelir). Kişi yetişkin değilse çizilmez ama hazır durur.
func set_profile(profile: CharacterProfile, outfit: StringName = &"", cape: StringName = &"") -> void:
	var key := PortraitBaker.key_of(profile, outfit, cape)
	if key.is_empty() or (key == profile_key and baked != null):
		return
	profile_key = key
	baked = PortraitBaker.cached(key)
	queue_redraw()
	if baked != null or not PortraitBaker.can_render():
		return
	if _baker == null:
		_baker = PortraitBaker.new()
		_baker.name = "PortraitBaker"
		add_child(_baker)
		_baker.baked.connect(_on_baked)
	_baker.bake(profile, outfit, cape)


func _on_baked(key: String, tex: Texture2D) -> void:
	if key == profile_key:
		baked = tex
		queue_redraw()


## Çizilen portre dokusu: çocuğun boyalı portresi ya da yetişkinin pişmiş portresi (yoksa null: gök mavisi boşluk).
func portrait_texture() -> Texture2D:
	if person.is_empty():
		return baked
	return HudKit.tex(str(PORTRAITS.get(person, "")))


func _process(delta: float) -> void:
	if vitals == null or not is_visible_in_tree():
		return
	var dirty := false
	var t := 1.0 - exp(-EASE * delta)
	if _hp_shown < 0.0:
		_hp_shown = vitals.hp
		_stamina_shown = vitals.stamina
		dirty = true
	for pair: Array in [["_hp_shown", vitals.hp], ["_stamina_shown", vitals.stamina]]:
		var cur: float = get(pair[0])
		var want: float = pair[1]
		if absf(cur - want) > 0.01:
			set(pair[0], want if absf(cur - want) < 0.05 else lerpf(cur, want, t))
			dirty = true
	var st := vitals.statuses()
	if st != _statuses:
		_statuses = st
		dirty = true
	if dirty:
		queue_redraw()


## Gösterilen değerler (sınama): [can, takat] tam sayı olarak, çubuklarda yazıldığı gibi.
func bar_texts() -> PackedStringArray:
	if vitals == null:
		return PackedStringArray()
	return PackedStringArray([value_text(vitals.hp, vitals.hp_max), value_text(vitals.stamina, vitals.stamina_max)])


## «86 / 100» (saf).
static func value_text(value: float, max_value: float) -> String:
	return "%d / %d" % [roundi(value), roundi(max_value)]


func shown_statuses() -> PackedStringArray:
	return _statuses


func _draw() -> void:
	var hp := vitals.hp if vitals else 100.0
	var hp_max := vitals.hp_max if vitals else 100.0
	var st := vitals.stamina if vitals else 80.0
	var st_max := vitals.stamina_max if vitals else 80.0
	var hp_shown := _hp_shown if _hp_shown >= 0.0 else hp
	var st_shown := _stamina_shown if _stamina_shown >= 0.0 else st
	_draw_bar(HudKit.HP_RECT, "bar_fill_red", hp_shown / maxf(hp_max, 0.001), value_text(hp, hp_max))
	_draw_bar(HudKit.STAMINA_RECT, "bar_fill_green", st_shown / maxf(st_max, 0.001), value_text(st, st_max))
	_draw_portrait()
	var ring := HudKit.tex("portrait_ring")
	if ring:
		var s := HudKit.PORTRAIT_RING_SCALE
		draw_texture_rect(ring, Rect2(HudKit.PORTRAIT_CENTER - HudKit.PORTRAIT_RING_PIVOT * s, ring.get_size() * s), false)
	else:
		draw_arc(HudKit.PORTRAIT_CENTER, HudKit.PORTRAIT_RADIUS + 3.0, 0.0, TAU, 64, HudKit.SILVER, 7.0, true)
	HudKit.draw_centered(self, "badge_level", HudKit.BADGE_CENTER, Vector2.ONE * HudKit.BADGE_SIZE)
	var level := vitals.level if vitals else 1
	HudKit.draw_text(self, HudKit.number_font(600), HudKit.BADGE_CENTER + Vector2(0.0, 9.0), str(level), LEVEL_TEXT_SIZE, HudKit.CREAM, 1)
	for i in HudKit.STATUS_CENTERS.size():
		var c: Vector2 = HudKit.STATUS_CENTERS[i]
		HudKit.draw_centered(self, "slot_square", c, Vector2.ONE * HudKit.STATUS_SIZE)
		if i < _statuses.size() and STATUS_ICONS.has(_statuses[i]):
			var def: Array = STATUS_ICONS[_statuses[i]]
			HudKit.draw_icon(self, str(def[0]), c + Vector2(0.5, 0.5), HudKit.STATUS_SIZE * 0.66, def[1])


func _draw_portrait() -> void:
	var c := HudKit.PORTRAIT_CENTER
	var r := HudKit.PORTRAIT_RADIUS
	var t := portrait_texture()
	if t:
		draw_texture_rect(t, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)
		return
	# Portresi henüz pişmemiş yetişkin (ya da çizicisiz koşu): gök mavisi boşluk, altta açık bir pus.
	draw_circle(c, r, Color("#6f9fd6"))
	draw_circle(c + Vector2(0.0, r * 0.35), r * 0.62, Color("#a9c8ea"))


## Çubuk: çerçeve (9 dilim: sol yuvarlak uç, sağda ok ucu), koyu kanalın içinde değerin dolgusu, ortada sayılar.
func _draw_bar(rect: Rect2, fill_id: String, ratio: float, text: String) -> void:
	var k := rect.size.y / HudKit.BAR_SIZE.y
	HudKit.draw_hslice(self, "bar_frame", rect, HudKit.BAR_PATCH.x, HudKit.BAR_PATCH.z)
	var ch := HudKit.BAR_CHANNEL
	var x0 := rect.position.x + ch.position.x * k
	var x1 := rect.end.x - (HudKit.BAR_SIZE.x - ch.end.x) * k
	var y0 := rect.position.y + ch.position.y * k + 1.0
	var y1 := rect.position.y + ch.end.y * k - 1.0
	var w := (x1 - x0) * clampf(ratio, 0.0, 1.0)
	if w > 0.5:
		HudKit.draw_hslice(self, fill_id, Rect2(x0, y0, w, y1 - y0), HudKit.FILL_PATCH, HudKit.FILL_PATCH)
	# Yazı halkanın altında kalmasın: görünen kanalın ortası (halkanın sağ kenarından ok ucuna).
	var left := maxf(x0, HudKit.PORTRAIT_CENTER.x + HudKit.PORTRAIT_RADIUS + 8.0)
	var mid := Vector2((left + x1) * 0.5, (y0 + y1) * 0.5 + BAR_TEXT_SIZE * 0.34)
	HudKit.draw_text(self, HudKit.number_font(600), mid, text, BAR_TEXT_SIZE, HudKit.CREAM, 1)
