class_name Mount
extends RefCounted
## Binek (saf; godot.md §3 «Binicilik», fauna.md §2.1): satırı data/fauna/mounts.json'dan okur, binişin durumunu tutar ve her adımda
## hedef hızı verir. Düğüm kurmaz, ağaca dokunmaz; PlayerController'ın binme kipi ve RideableSheep kullanır.
##
## Yürüyüş: giriş varsa tırıs, koşu tuşu basılıyken dörtnal (satırın base hızı; koyunda hızlı tırıs), giriş yoksa durur. Satırda graze_every varsa binek o aralıkla otlamak için
## durur (koyun 10 sn): otlarken giriş onu yürütmez; yalnız koşu tuşuna yeni basış (dürtme) yürütür ve saati sıfırlar. Tuş basılı
## kalsa da yeni basış sayılmaz: dürtmek bir vuruştur. graze_every'siz satırda (at) bu kural hiç işlemez.
## Satırın input_gait'i "walk" ise (at) giriş adım yürütür; koşu tuşu basılıyken önce tırıs, tuş gallop_after_s saniye basılı kalınca dörtnal
## (Shift hız verir: adım → tırıs → dörtnal). Tuş bırakılınca adıma döner, saat sıfırlanır.
## Sıçrama (2026-11-08): satırda jump varsa binek binicisiyle sıçrar (at; can_jump, jump_plan). Koyunun satırında yoktur: koyun binicisini taşır, sıçramaz
## (beş yaşında çocuğu sırtında taşıyan koyun sekmez; Boşluk koyunda bir şey yapmaz).
##
## Binişin koşulu (set_condition; MountStable.condition verir, progression.md §2.3, economy.md §4.7): Bağ 0–100 dörtnalı 0,045 × Bağ hızlandırır,
## at staminasının gideri (0,27 − 0,09k) ve dolumu (0,14 + 0,10k) Bağa bağlıdır (k = Bağ / 100); eyersiz (çıplak) binişte gider ×1,3; gem (Kemik Gem
## ×1,04) dönüşü keskinleştirir; terki (Inventory.mount_mods) bütün yürüyüşleri load_k ile yavaşlatır, dörtte üçün üstünde dörtnal yoktur.
## Mahmuz (spur; satırın spur'u, at +3 m/sn; act1.md §10 «Shift mahmuz»): dörtnalda koşu tuşunu bırakıp spur_tap_s içinde yeniden basmak mahmuzlar,
## tuş basılı kaldıkça at dörtnalın spur kadar üstünde koşar ve staminası gider; stamina biterse at soluğu kesilir (winded), stamina spur_min'e
## dolana dek mahmuz yoktur. Mahmuzsuz her an stamina dolar. Bırakılan tuş spur_tap_s boyunca dörtnalı tutar (dürtmenin aralığı), sonra adım.
##
##   var mount := Mount.new("sheep")
##   mount.start_ride()
##   var speed := mount.step(delta, wants_move, sprint_held, sprint_just_pressed)
##   var plan := Mount.new("horse").jump_plan(speed)   # yükseklik, havada kalış, hazırlık, iniş (durarak kısa, koşarak uzun)
##   mount.set_condition({"bond": 40.0, "saddled": true, "turn_mul": 1.04, "load_k": 1.0, "can_gallop": true})
##   mount.stamina                                     # 0..1; is_spurring(), is_winded()

const DATA_PATH := "res://data/fauna/mounts.json"
## Satırda yazılmayan ayarların değeri (ata da yeter; satır yazarsa onun değeri geçer).
const DEFAULTS := {"stamina": 1.0, "load": 0.0, "fall_damage": true, "accel": 6.0, "decel": 8.0, "turn": 6.0, "radius": 0.5, "reach": 1.5,
	"mount_s": 0.62, "dismount_s": 0.56, "dismount_side": 1.15, "graze_every": 0.0, "gallop_after_s": 0.0, "turn_fast": 0.0, "half_length": 0.0,
	"spur": 0.0, "spur_tap_s": 0.3, "spur_min": 0.3}
## Binişin koşulunun varsayılanı (set_condition; Bağ yok, eyerli, gemsiz, yüksüz).
const CONDITION := {"bond": 0.0, "saddled": true, "turn_mul": 1.0, "load_k": 1.0, "can_gallop": true, "drain_mul": 1.0, "regen_mul": 1.0,
	"gallop_add": 0.0, "stamina_mul": 1.0}

## Yürüyüşler (WALK sonradan eklendi: eski değerler aynı kalsın diye sonda).
enum Gait { STAND, TROT, GALLOP, GRAZE, WALK }

## Dosyanın önbelleği (ilk çağrıda okunur; testler reset_cache ile bırakır).
static var _rows: Dictionary = {}

var id := ""
var spec: Dictionary = {}
var gait: Gait = Gait.STAND
## Son dürtüşten (ya da binişten) bu yana geçen süre (sn).
var graze_clock := 0.0
## Koşu tuşunun kesintisiz basılı kaldığı süre (sn; gallop_after_s'e varınca dörtnal).
var sprint_clock := 0.0
## Binişin koşulu (set_condition): Bağ, eyer, gem, terki, beceri ve eşya çarpanları.
var condition: Dictionary = CONDITION.duplicate()
## At staminası (0..1; MountStable kaydeder): mahmuzla gider, mahmuzsuz dolar.
var stamina := 1.0
## Mahmuz sürüyor mu, at soluğu kesik mi (stamina bitti, spur_min'e dolana dek mahmuz yok)?
var spurring := false
var winded := false
## Dörtnalda koşu tuşu bırakılalı geçen süre (sn; -1 bırakılmadı): spur_tap_s içinde yeniden basış mahmuzdur.
var _released_for := -1.0


## id: satırın kimliği; row verilirse dosya okunmaz (sınama ve sonraki türler için).
func _init(p_id: String = "sheep", row: Dictionary = {}) -> void:
	id = p_id
	spec = row if not row.is_empty() else Mount.row_of(p_id)


## Satırların kimlikleri.
static func ids() -> PackedStringArray:
	return PackedStringArray(Mount._load().keys())


## Satır (yoksa boş).
static func row_of(mount_id: String) -> Dictionary:
	return Mount._load().get(mount_id, {})


static func reset_cache() -> void:
	_rows = {}


static func _load() -> Dictionary:
	if _rows.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		var raw: Dictionary = (parsed as Dictionary).get("mounts", {}) if parsed is Dictionary else {}
		for key: String in raw:
			_rows[key] = Mount.inherit(raw, key)
	return _rows


## Satırın «like» kalıtımı (saf): like verilen satır ondan başlar, kendi alanları üstüne yazılır (iç içe sözlükler alan alan birleşir).
static func inherit(rows: Dictionary, key: String, depth := 0) -> Dictionary:
	var row: Dictionary = rows.get(key, {})
	var base_id := str(row.get("like", ""))
	if base_id.is_empty() or not rows.has(base_id) or depth > 4:
		return row.duplicate(true)
	var out := Mount.inherit(rows, base_id, depth + 1)
	for field: String in row:
		if field == "like":
			continue
		if row[field] is Dictionary and out.get(field) is Dictionary:
			var merged := (out[field] as Dictionary).duplicate(true)
			merged.merge(row[field], true)
			out[field] = merged
		else:
			out[field] = row[field]
	out.erase("like")
	return out


## Satırın değeri (yoksa DEFAULTS).
func value(key: String) -> float:
	return float(spec.get(key, DEFAULTS.get(key, 0.0)))


## Binişin koşulunu verir (eksik anahtar varsayılanında kalır; CONDITION): bond, saddled, turn_mul, load_k, can_gallop, drain_mul, regen_mul,
## gallop_add, stamina_mul.
func set_condition(c: Dictionary) -> void:
	condition = CONDITION.duplicate()
	for key: String in c:
		if condition.has(key):
			condition[key] = c[key]
	condition["bond"] = clampf(float(condition["bond"]), 0.0, 100.0)
	if not can_gallop_now():
		spurring = false


func _cond(key: String) -> float:
	return float(condition.get(key, CONDITION[key]))


## Bağ (0..100).
func bond() -> float:
	return _cond("bond")


## Terkinin hız çarpanı (economy.md §4.7 mountLoadK; 1 yüksüz).
func load_k() -> float:
	return clampf(_cond("load_k"), 0.0, 1.0)


## Tırıs ve dörtnal hızı (m/sn; terkiyle çarpılmış).
func trot_speed() -> float:
	return float(spec.get("trot", 0.0)) * load_k()


## Adım hızı (m/sn; satırda yoksa 0: yürüme yok, tırıs adımı geçer; terkiyle çarpılmış).
func walk_speed() -> float:
	return float(spec.get("walk", 0.0)) * load_k()


## Dörtnal (m/sn): (satırın base'i + 0,045 × Bağ + beceri payı) × terki (progression.md §2.3 gallop; rüzgâr kullanım anındadır).
func gallop_speed() -> float:
	return (base_speed() + Derive.BOND_GALLOP * bond() + _cond("gallop_add")) * load_k()


## Satırın kendi dörtnal hızı (m/sn; koşulsuz).
func base_speed() -> float:
	return float(spec.get("base", 0.0))


## Mahmuzlu hız (m/sn): dörtnal + satırın spur'u (Derive.SPUR ile aynı, +3).
func spur_speed() -> float:
	return gallop_speed() + value("spur")


## Dörtnala izin var mı: satırda dörtnal var (base > trot) ve terki dörtte üçü geçmiyor (economy.md §4.7)?
func can_gallop_now() -> bool:
	return bool(condition.get("can_gallop", true))


## Satır mahmuzlanır mı (spur > 0)?
func has_spur() -> bool:
	return value("spur") > 0.0


## Mahmuz şimdi verilebilir mi (satırda var, dörtnala izin var, soluk kesik değil, stamina var)?
func can_spur() -> bool:
	return has_spur() and can_gallop_now() and not winded and stamina > 0.0


func is_spurring() -> bool:
	return spurring


func is_winded() -> bool:
	return winded


## At staminasının mahmuzdaki gideri (1/sn; progression.md §2.3): (0,27 − 0,09k) × beceri × (eyersiz ×1,3) / (satırın ve çulun dayanıklılığı).
func drain_rate() -> float:
	var k := bond() / 100.0
	var bareback := Derive.BAREBACK if not bool(condition.get("saddled", true)) else 1.0
	var hardiness := maxf(value("stamina") * _cond("stamina_mul"), 0.05)
	return (Derive.DRAIN_BASE - Derive.DRAIN_BOND * k) * _cond("drain_mul") * bareback / hardiness


## At staminasının dolumu (1/sn): (0,14 + 0,10k) × (barınak ×2 ve beceri: regen_mul).
func regen_rate() -> float:
	var k := bond() / 100.0
	return (Derive.REGEN_HORSE + Derive.REGEN_BOND * k) * _cond("regen_mul")


## Binilmeyen bineğin staminasının dolumu (saf; MountStable her binek için çağırır): Bağ k ile.
static func rest_regen(bond_value: float) -> float:
	return Derive.REGEN_HORSE + Derive.REGEN_BOND * clampf(bond_value, 0.0, 100.0) / 100.0


## Adım boyu (m): gidilen hıza göre (yürüyüş, tırıs ya da dörtnal; satırda yoksa 1 m). Yürüyüşle tırıs arasında adım boyu da geçişlidir.
func stride_at(speed: float) -> float:
	var stride: Dictionary = spec.get("stride", {})
	var trot := float(stride.get("trot", 1.0))
	var gallop := float(stride.get("gallop", trot))
	if walk_speed() > 0.0 and speed < trot_speed():
		var walk := float(stride.get("walk", trot))
		return lerpf(walk, trot, clampf(inverse_lerp(walk_speed(), trot_speed(), speed), 0.0, 1.0))
	return lerpf(trot, gallop, clampf(inverse_lerp(trot_speed(), gallop_speed(), speed), 0.0, 1.0))


## Oturma ölçüleri (mounts.json seat; yoksa boş).
func seat() -> Dictionary:
	return spec.get("seat", {})


## Binek otluyor mu?
func is_grazing() -> bool:
	return gait == Gait.GRAZE


## Giriş adım mı yürütür (satırın input_gait'i "walk" ve adım hızı varsa)?
func walks_on_input() -> bool:
	return str(spec.get("input_gait", "trot")) == "walk" and walk_speed() > 0.0


## Binicinin türü binebilir mi (satırın riders'ı; yoksa herkes)? child: çocuk kipi.
func allows_rider(child: bool) -> bool:
	var riders: Variant = spec.get("riders")
	if not riders is Array:
		return true
	return (riders as Array).has("child" if child else "adult")


## Biniş biçimi: "hop" (küçük sıçrayış; koyun) ya da "vault" (yanaşıp sıçrayarak oturma; at).
func mount_style() -> String:
	return str(spec.get("mount_style", "hop"))


## Biniş başladı: saat sıfırlanır, binek otluyorsa kalkar.
func start_ride() -> void:
	gait = Gait.STAND
	graze_clock = 0.0
	sprint_clock = 0.0
	spurring = false
	_released_for = -1.0


## Biniş bitti.
func end_ride() -> void:
	gait = Gait.STAND
	graze_clock = 0.0
	sprint_clock = 0.0
	spurring = false
	_released_for = -1.0


## Bir adım: durumu ve at staminasını günceller, hedef hızı (m/sn) döndürür. wants_move: giriş var mı; sprint: koşu tuşu basılı mı; prod: koşu
## tuşuna bu adımda yeni mi basıldı.
func step(delta: float, wants_move: bool, sprint: bool, prod: bool) -> float:
	var speed := _step_gait(delta, wants_move, sprint, prod)
	_breathe(delta)
	if spurring:
		speed += value("spur")
	return speed


func _step_gait(delta: float, wants_move: bool, sprint: bool, prod: bool) -> float:
	delta = maxf(delta, 0.0)
	var every := value("graze_every")
	if prod and gait == Gait.GRAZE:
		gait = Gait.STAND
		graze_clock = 0.0
	if every > 0.0 and gait != Gait.GRAZE:
		graze_clock += delta
		if graze_clock >= every:
			gait = Gait.GRAZE
	if gait == Gait.GRAZE:
		spurring = false
		return 0.0
	if not wants_move:
		gait = Gait.STAND
		sprint_clock = 0.0
		spurring = false
		_released_for = -1.0
		return 0.0
	var gallop_ok := can_gallop_now()
	if not sprint:
		spurring = false
		# Dörtnalda bırakılan tuş: dürtmenin aralığı boyunca dörtnal sürer (yeniden basış mahmuzdur), sonra adım ya da tırıs.
		if gait == Gait.GALLOP and has_spur() and gallop_ok:
			_released_for = 0.0 if _released_for < 0.0 else _released_for + delta
			if _released_for <= value("spur_tap_s"):
				return gallop_speed()
		_released_for = -1.0
		sprint_clock = 0.0
		if not walks_on_input():
			gait = Gait.TROT
			return trot_speed()
		gait = Gait.WALK
		return walk_speed()
	var tapped := prod and _released_for >= 0.0 and gait == Gait.GALLOP
	_released_for = -1.0
	if not gallop_ok:
		gait = Gait.TROT
		spurring = false
		sprint_clock += delta
		return trot_speed()
	if not walks_on_input():
		gait = Gait.GALLOP
	else:
		sprint_clock += delta
		if tapped:
			sprint_clock = maxf(sprint_clock, value("gallop_after_s"))
		gait = Gait.GALLOP if sprint_clock >= value("gallop_after_s") else Gait.TROT
	if gait != Gait.GALLOP:
		return trot_speed()
	if tapped and can_spur():
		spurring = true
	elif spurring and not can_spur():
		spurring = false
	return gallop_speed()


## At staminası: mahmuzda gider (biterse soluk kesilir, mahmuz biter), mahmuzsuz dolar; soluk spur_min'de geri gelir.
func _breathe(delta: float) -> void:
	delta = maxf(delta, 0.0)
	if spurring:
		stamina = maxf(stamina - drain_rate() * delta, 0.0)
		if stamina <= 0.0:
			spurring = false
			winded = true
		return
	stamina = minf(stamina + regen_rate() * delta, 1.0)
	if winded and stamina >= value("spur_min"):
		winded = false


## Yürüyüşün adı (HUD ve ses için): stand, walk, trot, gallop, graze (mahmuz da dörtnaldır: is_spurring).
func gait_name() -> String:
	match gait:
		Gait.WALK:
			return "walk"
		Gait.TROT:
			return "trot"
		Gait.GALLOP:
			return "gallop"
		Gait.GRAZE:
			return "graze"
	return "stand"


## Binek binicisiyle sıçrar mı (satırın jump'ı; at evet, koyun hayır)?
func can_jump() -> bool:
	return spec.get("jump") is Dictionary


## Sıçramanın planı (saf; satırın jump'ı, sıçramayan binekte boş). speed: sıçrayıştaki hız (m/sn). Satırın üçlü alanları duruş, tırıs ve dörtnal
## hızındaki değerdir, arası doğrusal: height gövdenin havadaki yayının tepesi (m), air_s havada kalış (sn). run_from'dan hızlısı koşarak sıçramadır:
## klip ön bacaklar kalkmışken başlar, hazırlık kısadır (prep_s[1]), hız korunur, inişte land_keep'i kalır; yavaşı durarak (adımdan da): at toplanır
## (prep_s[0]), yerinden push hızıyla fırlar. land_rate inişin klip hızı (durarak, koşarak), air_turn havadaki dönüş keskinliğinin payı.
## Döner: {running, height, air_s, prep_s, land_rate, push, land_keep, air_turn, gravity (m/sn²; yayın kendi yerçekimi)}.
func jump_plan(speed: float) -> Dictionary:
	var row: Variant = spec.get("jump")
	if not row is Dictionary:
		return {}
	var jump := row as Dictionary
	var running := speed >= float(jump.get("run_from", trot_speed()))
	var height := Mount.by_speed(jump.get("height", [0.3]), speed, trot_speed(), gallop_speed())
	var air := maxf(Mount.by_speed(jump.get("air_s", [0.5]), speed, trot_speed(), gallop_speed()), 0.05)
	var prep: Array = jump.get("prep_s", [0.3, 0.12])
	var land: Array = jump.get("land_rate", [1.0, 1.0])
	var i := 1 if running else 0
	return {"running": running, "height": height, "air_s": air, "prep_s": float(prep[mini(i, prep.size() - 1)]), "land_rate": float(land[mini(i, land.size() - 1)]),
		"push": float(jump.get("push", 2.0)), "land_keep": float(jump.get("land_keep", 0.9)), "air_turn": float(jump.get("air_turn", 0.3)),
		"gravity": 8.0 * height / (air * air)}


## Duruş, tırıs ve dörtnal hızındaki üç değerden hızdakini verir (saf; arası doğrusal, dörtnalın ötesinde son değer). Tek değerli liste her hızda odur.
static func by_speed(values: Array, speed: float, trot: float, gallop: float) -> float:
	if values.is_empty():
		return 0.0
	if values.size() == 1 or speed <= 0.0:
		return float(values[0])
	if speed <= trot or values.size() == 2:
		return lerpf(float(values[0]), float(values[1]), clampf(speed / maxf(trot, 0.01), 0.0, 1.0))
	return lerpf(float(values[1]), float(values[2]), clampf(inverse_lerp(trot, gallop, speed), 0.0, 1.0))


## Hızda dönüş keskinliği: satırın turn'ü, turn_fast verilmişse dörtnala doğru ona iner (atın dörtnalda dönüşü geniştir); gem (turn_mul: Kemik Gem
## ×1,04, Tunç Gem ×1,08) çarpar.
func turn_at(speed: float) -> float:
	var fast := value("turn_fast")
	var mul := _cond("turn_mul")
	if fast <= 0.0:
		return value("turn") * mul
	return lerpf(value("turn"), fast, clampf(inverse_lerp(walk_speed() if walk_speed() > 0.0 else 0.0, gallop_speed(), speed), 0.0, 1.0)) * mul


## Oyuncu bineğe erişiyor mu (yatay uzaklık; saf)?
static func in_reach(rider: Vector2, mount_at: Vector2, reach: float) -> bool:
	return rider.distance_to(mount_at) <= reach


## Yerler arasında erimdeki en yakının sırası (yoksa -1; saf).
static func nearest_in_reach(rider: Vector2, spots: Array[Vector2], reach: float) -> int:
	var best := -1
	var best_d := INF
	for i in spots.size():
		var d := rider.distance_to(spots[i])
		if d <= reach and d < best_d:
			best = i
			best_d = d
	return best


## İnilen nokta (saf): önce bineğin sol yanı, sonra sağ yanı, ikisi de kapalıysa arkası, o da kapalıysa sol yan. heading: ön yüzün açısı
## (radyan, yerel +Z; 0 = +Z); blocked: Vector2 → bool (boşsa hepsi açık).
static func dismount_spot(center: Vector2, heading: float, side: float, blocked: Callable = Callable()) -> Vector2:
	var left := Vector2(cos(heading), -sin(heading))
	var back := Vector2(-sin(heading), -cos(heading))
	var spots: Array[Vector2] = [center + left * side, center - left * side, center + back * side]
	if blocked.is_valid():
		for spot in spots:
			if not bool(blocked.call(spot)):
				return spot
	return spots[0]
