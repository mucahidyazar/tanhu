class_name Vitals
extends RefCounted
## Oyuncunun canı, takati, seviyesi ve deneyimi (saf; HUD'un sol üstündeki iki çubuğu ve alttaki XP çubuğunu besler).
##
## Takat koşarken azalır, dururken dolar: tick(delta, hız, binekte_mi, yürüme_hızı, koşu_hızı) oyuncunun gerçek hızını
## (PlayerController.get_speed) okur; koşu sayılan hız yürüyüşle koşunun ortasıdır (çocukta 1,5 ve 3,6 m/s → 2,55). Koşu bitince
## takat REGEN_DELAY saniye bekler, sonra yürürken yavaş, dururken (oturunca da) hızlı dolar; binekte koyun koşar, binici dinlenir.
## Takat bitince yalnız gösterge boşalır: oyuncunun koşusunu bugün kısmaz (denetleyici başka işin; ileride yorgunluk buradan okunur).
## Can bugün 100/100'dür (hasar yok), seviye ve deneyim başlangıç değerindedir (1, 0); add_xp ve damage ileride bağlanır.
## Durumlar (HUD'un iki küçük yuvası): "run" (koşuyor, takat azalıyor), "rest" (soluklanıyor, takat doluyor), "tired" (takat bitti).
##   var v := Vitals.new()
##   v.tick(delta, player.get_speed(), player.is_riding(), player.walk_speed, player.run_speed)
##   v.stamina_ratio()   # 0..1

signal changed

const HP_MAX := 100.0
const STAMINA_MAX := 80.0
## Takatin koşarken azalışı ve dolması (takat/sn): dururken, yürürken, binekte.
const DRAIN := 8.0
const REGEN_REST := 7.0
const REGEN_WALK := 3.0
const REGEN_RIDE := 4.0
## Koşu bitince dolmaya başlamadan önceki bekleme (sn).
const REGEN_DELAY := 0.8
## Bu hızın altında «duruyor» sayılır (m/s; PlayerController.MOVE_EPSILON'un biraz üstü).
const STILL := 0.15
## Koşu eşiği: yürüyüşle koşunun bu oranı (0 yürüyüş, 1 koşu).
const RUN_MIX := 0.5
## Takat bunun altında «yorgun» sayılır (oran).
const TIRED := 0.02
## Seviyenin deneyim eşiği: seviye × XP_PER_LEVEL.
const XP_PER_LEVEL := 100

var hp := HP_MAX
var hp_max := HP_MAX
var stamina := STAMINA_MAX
var stamina_max := STAMINA_MAX
var level := 1
var xp := 0
## Son tick'in durumu: "run", "walk", "still", "ride".
var mode := "still"
## İlerleme (Progression; progression.md §1.1): bağlıysa seviye ve XP çubuğu ondan okunur (bind_progression), yoksa yer tutucu eğri.
var progression: Progression
## Koşunun takat gideri çarpanı (yük: Inventory.move_mods run_cost_k = 1 + doluluk; economy.md §4.1). HUD yazar.
var run_cost_k := 1.0
## Tokluk bandının ve süreli yemeğin çarpanları (economy.md §5.3: Tok dolum ×1,15, Aç ×0,6, Bitkin koşu gideri ×1,25). SurvivalLayer yazar.
var regen_k := 1.0
var drain_k := 1.0

var _since_run := 999.0


## Bir karelik güncelleme. speed: oyuncunun yatay hızı (m/s); walk_speed / run_speed: denetleyicinin yürüme ve koşu hızı.
func tick(delta: float, speed: float, riding: bool, walk_speed: float = 1.5, run_speed: float = 3.6) -> void:
	if delta <= 0.0:
		return
	var before := stamina
	mode = classify(speed, riding, walk_speed, run_speed)
	if mode == "run":
		_since_run = 0.0
		stamina = maxf(stamina - DRAIN * maxf(run_cost_k, 0.0) * maxf(drain_k, 0.0) * delta, 0.0)
	else:
		_since_run += delta
		if _since_run >= REGEN_DELAY:
			stamina = minf(stamina + regen_rate(mode) * maxf(regen_k, 0.0) * delta, stamina_max)
	if not is_equal_approx(before, stamina):
		changed.emit()


## Hızın kipi (saf): binek, koşu, yürüyüş ya da duruş.
static func classify(speed: float, riding: bool, walk_speed: float, run_speed: float) -> String:
	if riding:
		return "ride"
	if speed >= lerpf(walk_speed, maxf(run_speed, walk_speed), RUN_MIX):
		return "run"
	return "walk" if speed > STILL else "still"


## Kipin dolma hızı (takat/sn; saf).
static func regen_rate(p_mode: String) -> float:
	match p_mode:
		"still":
			return REGEN_REST
		"ride":
			return REGEN_RIDE
		"walk":
			return REGEN_WALK
	return 0.0


func hp_ratio() -> float:
	return clampf(hp / maxf(hp_max, 0.001), 0.0, 1.0)


func stamina_ratio() -> float:
	return clampf(stamina / maxf(stamina_max, 0.001), 0.0, 1.0)


## Sıradaki seviyenin eşiği ve bu seviyedeki ilerleme (0..1).
func xp_next() -> int:
	if progression:
		return progression.xp_next()
	return level * XP_PER_LEVEL


func xp_ratio() -> float:
	if progression:
		return progression.xp_ratio()
	return clampf(float(xp) / float(maxi(xp_next(), 1)), 0.0, 1.0)


## Seviyeyi ve XP'yi ilerlemeye bağlar (oturum kurar): seviye, XP ve XP çubuğu ondan okunur; null bağı çözer.
func bind_progression(p: Progression) -> void:
	if progression and progression.changed.is_connected(_sync_progression):
		progression.changed.disconnect(_sync_progression)
	progression = p
	if p:
		p.changed.connect(_sync_progression)
		_sync_progression()


func _sync_progression() -> void:
	level = progression.level
	xp = progression.xp
	changed.emit()


## Deneyim ekler; eşik geçilince seviye artar (artan eşikle). İlerlemeye bağlıysa XP ona yazılır (seviyeyi o atlatır).
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	if progression:
		progression.add_xp(amount)
		return
	xp += amount
	while xp >= xp_next():
		xp -= xp_next()
		level += 1
	changed.emit()


## Can kaybı ya da kazancı (eksi iyileştirir); 0..hp_max.
func damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, hp_max)
	changed.emit()


## Durum yuvalarının kimlikleri, sırasıyla (en çok iki): koşuyor / yorgun, soluklanıyor.
func statuses() -> PackedStringArray:
	var out := PackedStringArray()
	if stamina_ratio() <= TIRED:
		out.append("tired")
	elif mode == "run":
		out.append("run")
	if mode != "run" and stamina < stamina_max and _since_run >= REGEN_DELAY:
		out.append("rest")
	return out


## Başlangıç değerleri (yeni beden, yeni sahne).
func reset() -> void:
	hp = hp_max
	stamina = stamina_max
	level = progression.level if progression else 1
	xp = progression.xp if progression else 0
	mode = "still"
	_since_run = 999.0
	changed.emit()
