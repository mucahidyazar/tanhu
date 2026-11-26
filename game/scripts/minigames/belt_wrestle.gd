class_name BeltWrestle
extends RefCounted
## Kuşak güreşi (Önsöz «Güreş», K110; story.md §3 «Göl Obası'nda üç gün»; Ordos tarzı tunç kemer levhalarının güreşi, «Bizim» okuması):
## iki çocuk birbirinin kuşağını tutar. Saf benzetim: sahne kurmaz, ses çalmaz; adım betiği (scripts/story/steps/wrestle_ring.gd) her kare
## step() çağırır, olayları sözlere ve kliplere çevirir, görünüşü (eğiliş, denge) okur. HUD BeltWrestleHud'dur.
##
## Denge (balance) [-1, 1]: 0 ortadır; +1'de Çocuk geriye itilip düşer, -1'de öne çekilip düşer. Börü sırayla iter (+) ya da çeker (-):
## her yüklenişten ≈0,4 sn önce gövdesi o yöne eğilir (telegraph; lean() görünüşün değeridir), sonra kuvvet yükselir, tepede kalır ve
## söner. Oyuncunun eğilişi (lean_input, [-1, 1]; +: Börü'ye doğru, öne) dengeyi kuvvetin tersine iter: db/dt = force × push_rate −
## lean × lean_rate. Tam karşı eğiliş en güçlü yüklenişi yener; fazla eğilen öbür uca kayar (karşı yönü ölçmek gerekir).
## Fazla yüklenme (overcommit): öğretme yüklenişlerinden (teach_bouts) sonra güçlü bir yüklenişin tepesinde oyuncu dengeyi orta bantta
## (hold_band) en az hold_s tutarsa Börü ağırlığını fazla verir: kuvveti düşer, ≈0,5 sn'lik pencere açılır (window), E ile atılır (won).
## Pencere dışında E boşa gider (whiff): Çocuk bir an sendeler, denge o anki kuvvetin yönüne whiff_kick kayar. Ceza yoktur (K110):
## düşen Çocuk fall_s yerde kalır (Stand_To_Side_Lying), Börü «Bir daha!» der, iki çocuk regrip_s'de yeniden tutunur, maç yeniden
## başlar (tries artar). give_up() kuşağı bırakmaktır: maç biter, won false. Belirlenimci: aynı tohum aynı yüklenişleri verir.
##   var w := BeltWrestle.new(1234)
##   w.start()
##   var events := w.step(delta, lean_input, e_pressed)   # ["telegraph", "bout", "window", "fall", "again", "grip", "won", ...]
##   w.balance; w.lean(); w.window_open(); w.phase; w.tries; w.result()

## Evreler: grip (tutunma, «Tutun!»a dek), rest (yüklenişler arası), telegraph (eğiliş görünür, kuvvet yok), bout (kuvvet),
## window (fazla yüklenme: E atar), fallen (Çocuk yerde), regrip (yeniden tutunma), won, gave_up.
const GRIP := &"grip"
const REST := &"rest"
const TELEGRAPH := &"telegraph"
const BOUT := &"bout"
const WINDOW := &"window"
const FALLEN := &"fallen"
const REGRIP := &"regrip"
const WON := &"won"
const GAVE_UP := &"gave_up"

## Varsayılan ayarlar (veri: day2_feast.json'un wrestle bloğu üstüne biner).
const DEFAULTS := {
	"grip_s": 1.2,
	"telegraph_s": 0.4,
	"rest_s": [0.45, 0.9],
	"bout_s": [1.1, 1.7],
	"strength": [0.55, 0.95],
	"strength_growth": 0.04,
	"push_rate": 0.9,
	"lean_rate": 1.15,
	"settle_rate": 0.22,
	"teach_bouts": 3,
	"hold_band": 0.42,
	"hold_s": 0.55,
	"strong_from": 0.72,
	"window_s": 0.5,
	"whiff_kick": 0.22,
	"fall_s": 2.4,
	"regrip_s": 1.3,
	"assist_after_tries": 2,
	"assist_k": 0.85,
}
## Kuvvetin yükseliş ve sönüş payı (yüklenişin süresine oranla).
const RAMP := 0.28
## Pencerede Börü'nün kalan kuvveti (sendeler; denge kendiliğinden ortaya döner).
const WINDOW_FORCE := 0.0

var cfg: Dictionary = DEFAULTS.duplicate(true)
var phase: StringName = GRIP
## Denge [-1, 1] (+: Çocuk geriye itilir).
var balance := 0.0
## Börü'nün o anki kuvveti [-1.2, 1.2] (+: iter) ve gelecek yüklenişin yönü (+1 iter, -1 çeker).
var force := 0.0
var next_dir := 1
## Evrenin saati ve süresi (sn).
var phase_t := 0.0
var phase_len := 0.0
## Maçta kaçıncı yükleniş (0'dan), toplam deneme (ilk maç 1), düşüş sayısı.
var bout_index := 0
var tries := 1
var falls := 0
## Düşüşün yönü (+1 geriye, -1 öne; görünüş).
var fall_dir := 1
## Bu yüklenişin gücü, süresi ve tutuşun birikimi (sn).
var bout_strength := 0.0
var bout_len := 0.0
var hold_acc := 0.0
## Açılan pencere sayısı ve boşa giden E sayısı (sınama, rapor).
var windows := 0
var whiffs := 0
## Oyunun saati (sn; benzetimin başından).
var clock := 0.0

var _rng := RandomNumberGenerator.new()
var _overcommit := false


func _init(seed_value: int = 20900409, overrides: Dictionary = {}) -> void:
	_rng.seed = seed_value
	for k: String in overrides:
		cfg[k] = overrides[k]


## Maçı baştan kurar (tutunma evresi; «Tutun!» bitince ilk yükleniş).
func start() -> void:
	balance = 0.0
	force = 0.0
	bout_index = 0
	hold_acc = 0.0
	_overcommit = false
	_enter(GRIP, float(cfg["grip_s"]))


## Maç bitti mi (kazandı ya da kuşağı bıraktı)?
func is_over() -> bool:
	return phase == WON or phase == GAVE_UP


func window_open() -> bool:
	return phase == WINDOW


## Pencerenin kalan payı [0, 1] (HUD'un yanıp sönen halkası).
func window_left() -> float:
	return clampf(1.0 - phase_t / maxf(phase_len, 0.001), 0.0, 1.0) if phase == WINDOW else 0.0


## Sonuç: {won, gave_up, tries, falls, windows, whiffs, seconds}.
func result() -> Dictionary:
	return {"won": phase == WON, "gave_up": phase == GAVE_UP, "tries": tries, "falls": falls, "windows": windows, "whiffs": whiffs,
		"seconds": clock}


## Börü'nün gövdesinin eğilişi [-1, 1] (görünüş; +: öne, iter): eğiliş yüklenişten telegraph_s önce başlar, yükleniş boyunca sürer,
## pencerede öne düşer (ağırlığını fazla vermiştir), aralarda ortaya döner.
func lean() -> float:
	match phase:
		TELEGRAPH:
			return float(next_dir) * clampf(phase_t / maxf(phase_len, 0.001), 0.0, 1.0) * 0.75
		BOUT:
			return clampf(force, -1.0, 1.0) * 0.6 + float(next_dir) * 0.3
		WINDOW:
			return float(next_dir) * 1.0
		_:
			return 0.0


## Kuşağı bırakır (vazgeçmek): maç biter.
func give_up() -> PackedStringArray:
	if is_over():
		return PackedStringArray()
	phase = GAVE_UP
	force = 0.0
	return PackedStringArray(["gave_up"])


## Bir kare: lean_input oyuncunun eğilişi ([-1, 1], +: öne), throw E'nin bu karede basılması. Olayları döndürür:
## grip (tutunma bitti, ilk yükleniş geliyor), telegraph (eğiliş başladı), bout (kuvvet başladı), window (pencere açıldı),
## window_missed (pencere kaçtı), won, whiff (pencere dışında E), fall (Çocuk düştü), again (Börü «Bir daha!»), regrip (yeniden
## tutunuyorlar), restart (yeni maç).
func step(dt: float, lean_input: float, throw: bool = false) -> PackedStringArray:
	var events := PackedStringArray()
	if is_over() or dt <= 0.0:
		return events
	clock += dt
	phase_t += dt
	var lean_in := clampf(lean_input, -1.0, 1.0)
	# E: pencerede atar, dışında boşa gider (tutunma ve yerdeyken sayılmaz).
	if throw:
		if phase == WINDOW:
			phase = WON
			force = 0.0
			events.append("won")
			return events
		if phase in [REST, TELEGRAPH, BOUT]:
			whiffs += 1
			var dir := signf(force) if absf(force) > 0.05 else float(next_dir)
			balance = clampf(balance + dir * float(cfg["whiff_kick"]), -1.0, 1.0)
			events.append("whiff")
	match phase:
		GRIP:
			if phase_t >= phase_len:
				events.append("grip")
				_begin_rest(events)
		REST:
			_integrate(dt, lean_in)
			if phase_t >= phase_len:
				_enter(TELEGRAPH, float(cfg["telegraph_s"]))
				events.append("telegraph")
		TELEGRAPH:
			_integrate(dt, lean_in)
			if phase_t >= phase_len:
				_begin_bout()
				events.append("bout")
		BOUT:
			force = float(next_dir) * bout_strength * BeltWrestle.envelope(phase_t / maxf(bout_len, 0.001))
			_integrate(dt, lean_in)
			if absf(balance) <= float(cfg["hold_band"]) and absf(force) >= 0.5 * bout_strength:
				hold_acc += dt
			# Fazla yüklenme: güçlü yükleniş, tepenin sonu (yükleniş yarıyı geçti), oyuncu dengeyi tuttu.
			if _overcommit and phase_t >= bout_len * 0.5 and hold_acc >= float(cfg["hold_s"]):
				windows += 1
				force = WINDOW_FORCE
				_enter(WINDOW, float(cfg["window_s"]))
				events.append("window")
			elif phase_t >= bout_len:
				bout_index += 1
				_begin_rest(events)
		WINDOW:
			force = WINDOW_FORCE
			_integrate(dt, lean_in)
			if phase_t >= phase_len:
				events.append("window_missed")
				bout_index += 1
				_begin_rest(events)
		FALLEN:
			force = 0.0
			if phase_t >= phase_len:
				_enter(REGRIP, float(cfg["regrip_s"]))
				events.append("regrip")
		REGRIP:
			balance = move_toward(balance, 0.0, dt * 2.0)
			if phase_t >= phase_len:
				tries += 1
				events.append("restart")
				start()
	if phase in [REST, TELEGRAPH, BOUT, WINDOW] and absf(balance) >= 1.0:
		fall_dir = 1 if balance > 0.0 else -1
		balance = clampf(balance, -1.0, 1.0)
		falls += 1
		force = 0.0
		_enter(FALLEN, float(cfg["fall_s"]))
		events.append("fall")
		events.append("again")
	return events


## Kuvvetin zarfı (saf): yükseliş, tepe, sönüş; x yüklenişin oranı [0, 1].
static func envelope(x: float) -> float:
	if x <= 0.0 or x >= 1.0:
		return 0.0
	if x < RAMP:
		return smoothstep(0.0, RAMP, x)
	if x > 1.0 - RAMP:
		return 1.0 - smoothstep(1.0 - RAMP, 1.0, x)
	return 1.0


## Oyuncunun yerine oynayan el (otomatik oynatma ve sınama; saf): eğilişin yönünün tersine, dengeyi ortaya çeken eğiliş ve pencerede E.
## react_s tepki gecikmesidir: eğiliş o kadar sürdükten sonra karşılanır (insan ≈0,15–0,25 sn).
static func bot_input(w: BeltWrestle, react_s: float = 0.15) -> Dictionary:
	var lean_in := 0.0
	match w.phase:
		TELEGRAPH:
			if w.phase_t >= react_s:
				lean_in = float(w.next_dir) * 0.6
		BOUT:
			# Kuvveti karşıla, sapmayı düzelt: tam karşı eğiliş + dengeyi ortaya çeken pay.
			var need := w.force * float(w.cfg["push_rate"]) / float(w.cfg["lean_rate"])
			lean_in = clampf(need + w.balance * 1.4, -1.0, 1.0)
		REST, WINDOW:
			lean_in = clampf(w.balance * 1.4, -1.0, 1.0)
	var throw := w.phase == WINDOW and w.phase_t >= react_s
	return {"lean": lean_in, "throw": throw}


## Kameranın güreşi yandan gösteren yatay açısı (saf; FollowCamera.compute_transform'un açısı): kameranın sağı Çocuk'tan Börü'ye giden
## eksendir, Çocuk ekranın solunda, Börü sağında kalır (HUD'un çubuğu ekranla aynı yöndedir).
static func camera_yaw_for_axis(axis: Vector3) -> float:
	var a := Vector2(axis.x, axis.z)
	if a.length() < 0.0001:
		return 0.0
	a = a.normalized()
	return atan2(-a.y, a.x)


## Hareket girişinin (x sağ, y ileri) eksene izdüşümü (saf): +1 Börü'ye doğru (öne), -1 ondan geri (PlayerController.camera_relative_direction).
static func lean_from_input(input: Vector2, camera_yaw: float, axis: Vector3) -> float:
	if input == Vector2.ZERO:
		return 0.0
	var dir := PlayerController.camera_relative_direction(input, camera_yaw)
	var flat := Vector3(axis.x, 0.0, axis.z)
	if flat.length() < 0.0001:
		return 0.0
	return clampf(dir.dot(flat.normalized()), -1.0, 1.0)


func _integrate(dt: float, lean_in: float) -> void:
	var push := float(cfg["push_rate"])
	# Yardım (K110: ceza yok): iki düşüşten sonra Börü biraz yorulur.
	if tries > int(cfg["assist_after_tries"]):
		push *= float(cfg["assist_k"])
	var settle := float(cfg["settle_rate"]) if absf(force) < 0.05 and absf(lean_in) < 0.05 else 0.0
	balance += (force * push - lean_in * float(cfg["lean_rate"])) * dt
	balance = move_toward(balance, 0.0, settle * dt)


func _begin_rest(events: PackedStringArray) -> void:
	force = 0.0
	hold_acc = 0.0
	# Yönler çoğunlukla değişir; arada aynı yön iki kez gelir (ezber bozulsun).
	next_dir = -next_dir if _rng.randf() < 0.7 else next_dir
	var r: Array = cfg["rest_s"]
	_enter(REST, _rng.randf_range(float(r[0]), float(r[1])))
	events.append("rest")


func _begin_bout() -> void:
	var s: Array = cfg["strength"]
	var b: Array = cfg["bout_s"]
	bout_strength = minf(_rng.randf_range(float(s[0]), float(s[1])) + float(cfg["strength_growth"]) * float(bout_index), 1.15)
	bout_len = _rng.randf_range(float(b[0]), float(b[1]))
	hold_acc = 0.0
	_overcommit = bout_index >= int(cfg["teach_bouts"]) and bout_strength >= float(cfg["strong_from"])
	# Öğretme yüklenişlerinden sonra her üçüncü yükleniş güçlüdür (pencere hep gelir).
	if bout_index >= int(cfg["teach_bouts"]) and (bout_index - int(cfg["teach_bouts"])) % 3 == 2:
		bout_strength = maxf(bout_strength, float(cfg["strong_from"]) + 0.05)
		_overcommit = true
	_enter(BOUT, bout_len)


func _enter(p: StringName, length: float) -> void:
	phase = p
	phase_t = 0.0
	phase_len = length
