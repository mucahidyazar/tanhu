class_name Survival
extends RefCounted
## Hayatta kalma (saf; survival.md, economy.md §5, progression.md §3, §8.5; godot.md §3 «Ateş ve av», §3.1 adım 4, §3.4 «survival»):
## Tokluk (Needs), Yara ve Düşüş (Wounds), ateşler (FireSet, FireState), pişirme (Cooking), av verimi (Hunt), süreli yemek etkileri ve
## kayıt v2'nin «survival» bloğu. Session'ın adım 4'üdür (needs): her kare step(dt). Oyun dakikası saatten okunur; ateş yakıtını oyun
## dakikası × 2,5 ile yer (olağan akışta gerçek saniye), atlamada (skipped) atlanan dakikayla: uyku Tokluk'u ×0,25, ateş başı dinlenme
## ×0,5 düşürür, dinlenme ve uyku yarayı kapatır, 24 saatten uzun atlama bütün çukurları kaldırır. Şafakta envanter bozulmayı işler
## (Inventory.on_dawn; aynı şafağı iki kez işlemez). Düşüş (Umay Eşiği) yara sınırı dolunca fell yayar; görünümü sahibi oynatır ve
## karanlıkta apply_fall'u çağırır. Görünümü (dünya düğümleri, HUD, girdi) SurvivalLayer'dır.
##
## Bağlama (Session; godot.md §3.1, §3.4):
##   var s := Survival.new({"difficulty": "normal", "zone": "testmap"})
##   s.inventory_source = func() -> Inventory: return hud.bag.inventory
##   s.bind_session(session)     # add_system(&"needs", s, &"survival"), blocks.register("survival", …), saat ve hizmetler
## Oturum yoksa (geliştirme) s.clock elle verilir ya da yerel saatle (step'in dt'si) yürür.
##   s.feed(fire)                # Y: 3 m içinde yakıt; çukurda yeniden yakma; küllenmiş közü uyandırma
##   s.build_plan(at, probe); s.build(at, plan)   # uzakta Y: yeni ateş
##   s.start_cook("spit_meat", fire); s.cook_press()   # E: tarif çemberi, Tam Vuruş
##   s.skin("marmot", leşin_yeri, {"clean": true})      # E basılı: yüz, verim verim Heybe'ye

signal message(text: String, kind: String)
signal fire_added(fire: FireState)
signal fire_removed(fire: FireState)
signal fire_changed(fire: FireState)
signal cook_started(job: Cooking.Job)
signal cook_finished(job: Cooking.Job)
signal cook_cancelled(job: Cooking.Job)
signal ate(item_id: String, gained: float)
## Yemeğin anlık etkisi: stamina (Bozkır Çayı +30), Can (Kemik Suyu +30, hp_s saniyede).
signal stamina_gained(amount: float)
signal hp_gained(amount: float, seconds: float)
## Yara sınırı doldu: Umay Eşiği (görünüm karanlıkta apply_fall çağırır).
signal fell(plan: Dictionary)
signal hunted(kind_id: String, items: Dictionary)
signal changed

const BLOCK := "survival"
const BLOCK_V := 1
const BLOCK_ORDER := 62
## Ateş başında hemen yenilecek yemeğin bekleme süresi (sn; yıldız yalnız hemen yenince geçer).
const FRESH_S := 45.0
const MIN_PER_SEC := 0.4

var needs: Needs
var wounds: Wounds
var fires := FireSet.new()
## Bilinen tarifler (kimlik → true) ve ilk kez yapılanlar (+20 XP bir kez).
var known: Dictionary = {}
var made: Dictionary = {}
## Tarif çemberinin Yakıt dilimi (oturum boyunca kalır; kayda yazılmaz).
var fuel_choice := "dung"
## Süren pişirme (yoksa null) ve ateş başında hemen yenilecek yemek ({item, quality, share, left, fire}).
var job: Cooking.Job
var fresh: Dictionary = {}
## Süreli yemek etkileri, en çok buff_max ([{item, left, mods}]; yenisi en eskisini siler).
var buffs: Array = []
## Avlanan türler (tür → sayı).
var hunted_kinds: Dictionary = {}
## Kaydın öteki alanları (survival.md §7.10): Gecelik Çadır, son Uyku Zarı'nın gecesi, kapanlar (II'den; olduğu gibi taşınır).
var tents: Array = []
var sleep_last_night := -1
var snares: Array = []

var inventory: Inventory
## Envanterin kaynağı (verilirse inventory'nin yerine her okumada): Callable() → Inventory.
var inventory_source: Callable
## İlerleme (Progression: award, mod; ördek tipli: saf sınıf ilerlemenin derlenmesine bağlı kalmaz).
var progression: Object
var clock: GameClock
## Havanın kaynağı: Callable() → WeatherFx (ya da {type, fire_k, fire_ring, fire_out_s}); yoksa açık hava.
var fx_source: Callable
## Kut'un kaynağı (Düşüşün erzak bedeli; Kut ≥5 almaz): Callable() → int.
var kut_source: Callable
var zone := "testmap"
var difficulty := "normal"
## Çocukta (Serbest Gez) malzeme sayılmaz.
var free_materials := false
var lang := "tr"
## Oyuncunun yeri (x, z; çukurun 30 m ertelemesi) ve zonu.
var player_xz := Vector2.INF
var session: Session

var _last_abs := NAN
var _local_abs := 0.0
## Tokluk'un uyanık dakikaları bir oyun dakikası dolunca işlenir: Needs her güncellemede 1e-6'ya yuvarlar (prototip), kare başına
## yuvarlama 600 karede 1e-4'e birikirdi.
var _needs_acc := 0.0


## opts: difficulty, zone, mode ("roam": Tokluk ve Yara yok), inventory, clock, progression, free_materials.
func _init(opts: Dictionary = {}) -> void:
	difficulty = str(opts.get("difficulty", "normal"))
	zone = str(opts.get("zone", zone))
	free_materials = bool(opts.get("free_materials", false))
	inventory = opts.get("inventory") as Inventory
	clock = opts.get("clock") as GameClock
	progression = opts.get("progression") as Object
	needs = Needs.new({"diff": difficulty, "mod": _mod, "enabled": str(opts.get("mode", "story")) != "roam"})
	wounds = Wounds.new(difficulty)
	wounds.fell.connect(_on_fell)
	fires.added.connect(_on_fire_added)
	fires.removed.connect(_on_fire_removed)
	for id in Cooking.start_known():
		known[id] = true
	_local_abs = clock.abs_minute() if clock else 0.0


# --- Bağlama -------------------------------------------------------------------------------------------------

## Oturuma bağlar: adım 4 (needs), «survival» bloğu (opts.save false değilse; deneme haritası Serbest Gez kaydına yazmaz), saat, şafak
## ve atlama, Progression hizmeti («progress»).
func bind_session(s: Session, opts: Dictionary = {}) -> bool:
	if s == null:
		return false
	session = s
	if not s.add_system(&"needs", self, &"survival"):
		return false
	if bool(opts.get("save", true)):
		s.blocks.register(BLOCK, BLOCK_V, to_dict, from_dict, {"reset": reset, "check": Survival.validate_save_block, "order": BLOCK_ORDER})
	set_clock(s.clock)
	s.clock_replaced.connect(set_clock)
	s.skipped.connect(on_skipped)
	s.dawn.connect(on_dawn)
	var p: Variant = s.services().get("progress")
	if p is Object and (p as Object).has_method(&"award") and progression == null:
		progression = p
	return true


## Oturumdan ayrılır (blok son hâliyle kayıtta taşınır).
func unbind_session() -> void:
	if session == null or not is_instance_valid(session):
		session = null
		return
	session.remove_system(&"survival")
	if session.blocks.has_block(BLOCK):
		session.blocks.unregister(BLOCK)
	for pair: Array in [[session.clock_replaced, set_clock], [session.skipped, on_skipped], [session.dawn, on_dawn]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	session = null


func set_clock(c: GameClock) -> void:
	clock = c
	_last_abs = c.abs_minute() if c else NAN


func inv() -> Inventory:
	if inventory_source.is_valid():
		var v: Variant = inventory_source.call()
		if v is Inventory:
			return v
	return inventory


# --- Saat ----------------------------------------------------------------------------------------------------

## Şimdiki mutlak oyun dakikası (saat yoksa yerel sayaç).
func now_abs() -> float:
	return clock.abs_minute() if clock else _local_abs


## Hikâye günü (şafakta artar): Ocağa Pay'ın ve bozulmanın günü. Yer verilmemiş saatte takvim günü.
func day() -> int:
	if clock == null:
		return int(floor(_local_abs / 1440.0))
	var dawn_at := clock.at(&"dawn") if clock.has_place() else NAN
	if is_finite(dawn_at) and clock.abs_minute() < dawn_at:
		return clock.day_n - 1
	return clock.day_n


func season() -> StringName:
	return GameCalendar.season(clock.day_n) if clock else &"spring"


func fx() -> Variant:
	return fx_source.call() if fx_source.is_valid() else null


func weather_type() -> String:
	var f: Variant = fx()
	if f is Object and (f as Object).get("type") != null:
		return str((f as Object).get("type"))
	if f is Dictionary:
		return str((f as Dictionary).get("type", "clear"))
	return "clear"


## Session adım 4: kare başı. Saat görünür akıştaysa (Bekle'nin hızlı akışı) iş atlamanın sonundadır (on_skipped).
func step(dt: float) -> void:
	var now := 0.0
	var dmin := 0.0
	if clock == null:
		dmin = maxf(dt, 0.0) * MIN_PER_SEC
		_local_abs += dmin
		now = _local_abs
	else:
		if clock.is_lapsing():
			return
		now = clock.abs_minute()
		if is_nan(_last_abs):
			_last_abs = now
		dmin = maxf(now - _last_abs, 0.0)
		_last_abs = now
	_advance(dmin * FireState.minute_s(), dmin, now, {})


## Atlama (Bekle, Dinlen, Uyu, Çalış, Düşüş): ateş atlanan dakikayla yanar, Tokluk atlamanın oranıyla düşer, dinlenme ve uyku yarayı
## kapatır, 24 saatten uzunu bütün çukurları kaldırır.
func on_skipped(info: Dictionary) -> void:
	var minutes := float(info.get("minutes", 0.0))
	var reason := str(info.get("reason", ""))
	var sleeping := bool(info.get("sleep", false)) or reason == "sleep"
	var resting := reason == "rest"
	var now := now_abs()
	if minutes > 0.0:
		_advance(minutes * FireState.minute_s(), minutes, now, {"sleep": sleeping, "rest": resting})
		if resting:
			if wounds.rest(minutes, needs.fullness, now) > 0:
				message.emit(_needs_text("healed"), "info")
		elif sleeping:
			wounds.sleep(minutes, bool(info.get("interrupted", false)))
	if bool(info.get("long", false)):
		fires.on_long_skip()
	var i := inv()
	if i and clock:
		i.on_dawn(day())
	_last_abs = now
	changed.emit()


func on_dawn(_info: Dictionary) -> void:
	var i := inv()
	if i and clock:
		i.on_dawn(day())


func _advance(fuel_s: float, dmin: float, now: float, needs_opts: Dictionary) -> void:
	var weather: Variant = fx()
	var d := day()
	for ev: Dictionary in fires.advance(fuel_s, now, weather, d):
		var f: FireState = ev["fire"]
		fire_changed.emit(f)
		if _near_player(f, float(FireState.rule("ring_m", 6.0))):
			message.emit(FireState.text("out", lang), "info")
	if needs_opts.is_empty():
		_needs_acc += dmin
		if _needs_acc >= 1.0:
			needs.update(_needs_acc)
			_needs_acc = 0.0
	else:
		flush_needs()
		if dmin > 0.0:
			needs.update(dmin, needs_opts)
	_tick_buffs(fuel_s)
	_tick_job(fuel_s)
	if not fresh.is_empty():
		fresh["left"] = float(fresh["left"]) - fuel_s
		if float(fresh["left"]) <= 0.0:
			fresh = {}
	fires.prune(now, player_xz, zone)


## Birikmiş uyanık dakikaları Tokluk'a işler (atlamadan, kayıttan ve HUD'un kesin okumasından önce).
func flush_needs() -> void:
	if _needs_acc > 0.0:
		needs.update(_needs_acc)
		_needs_acc = 0.0


func _near_player(f: FireState, radius: float) -> bool:
	return player_xz.is_finite() and f.zone == zone and player_xz.distance_to(f.xz()) <= radius


# --- Ateş ------------------------------------------------------------------------------------------------

## Oyuncuya en yakın ateş ya da çukur (radius; varsayılan 3 m).
func fire_near(at: Vector2, radius := -1.0) -> FireState:
	return fires.near(at, radius if radius > 0.0 else float(FireState.rule("near_m", 3.0)), zone)


## Yakıt türlerinin sırası: Yakıt dilimi önce, sonra Yük verimi (tezek, dal, odun).
func fuel_order() -> PackedStringArray:
	var out := PackedStringArray([fuel_choice])
	for row: Dictionary in FireState.fuels():
		var id := str(row.get("id", ""))
		if not out.has(id):
			out.append(id)
	return out


## Yakıt dilimini sıradakine çevirir (tezek → dal → odun → tezek). Döner: yeni tür.
func cycle_fuel() -> String:
	var ids: Array = FireState.fuels().map(func(r: Dictionary) -> String: return str(r.get("id", "")))
	var i := ids.find(fuel_choice)
	fuel_choice = str(ids[(i + 1) % ids.size()]) if not ids.is_empty() else fuel_choice
	changed.emit()
	return fuel_choice


func fuel_name(fuel_id: String) -> String:
	return Catalog.pick(FireState.fuel_row(fuel_id).get("name", fuel_id), lang)


## Heybe'deki o türden yakıt (adet).
func fuel_count(fuel_id: String, i: Inventory = null) -> int:
	var src := i if i else inv()
	if src == null:
		return 0
	var n := 0
	for ref: Variant in FireState.fuel_row(fuel_id).get("refs", []):
		n += src.count(str(ref))
	return n


## Y (3 m içinde): yanan ateşe yakıt, küllenmiş köze 1 yakıt (uyanır), çukura 1 odun ya da 2 tezek (yakıcıyla). Döner: {ok, text, fuel}.
func feed(f: FireState) -> Dictionary:
	if f == null:
		return _fail(FireState.text("no_fuel", lang))
	if f.hearth:
		return _fail(FireState.text("hearth", lang), "info")
	if f.is_pit():
		return relight(f)
	if f.is_lit() and f.is_full():
		return _fail(FireState.text("full", lang), "info")
	var i := inv()
	for fuel_id in fuel_order():
		if not free_materials and fuel_count(fuel_id, i) <= 0:
			continue
		if not free_materials:
			_take_fuel(fuel_id, 1, i)
		var secs := FireState.fuel_seconds(fuel_id)
		if f.is_banked():
			f.wake(secs)
			fire_changed.emit(f)
			return _ok(FireState.text("woke", lang), {"fuel": fuel_id})
		f.add_fuel(secs)
		fire_changed.emit(f)
		return _ok(FireState.text("fed", lang, {"fuel": fuel_name(fuel_id)}), {"fuel": fuel_id})
	return _fail(FireState.text("no_fuel", lang))


## Çukuru yeniden yakar (kav istemez, yakıcı gerekir): Yakıt dilimi odunsa önce odun, değilse önce iki tezek. Eski Ocak'ın ilk yakışı
## da böyledir (light_old). Döner: {ok, text}.
func relight(f: FireState) -> Dictionary:
	var lock := _weather_lock(f.stones)
	if not lock.is_empty():
		return _fail(lock)
	var i := inv()
	if not free_materials and not _has_lighter(i):
		return _fail(FireState.text("no_lighter", lang))
	var cost: Dictionary = (FireState.rule("relight", {}) as Dictionary).get("cost", {"dung": 2, "wood": 1})
	var order: Array = ["wood", "dung"] if fuel_choice == "wood" else ["dung", "wood"]
	for fuel_id: String in order:
		var n := int(cost.get(fuel_id, 0))
		if n <= 0 or (not free_materials and fuel_count(fuel_id, i) < n):
			continue
		if not free_materials:
			_take_fuel(fuel_id, n, i)
		f.relight(FireState.fuel_seconds(fuel_id) * n)
		fire_changed.emit(f)
		_request_autosave()
		return _ok(FireState.text("lit", lang), {"fuel": fuel_id})
	return _fail(FireState.text("pit_needs", lang))


## Eski Ocak'ı yakar (haritanın taş halkası; kümede ateşi yoksa yeni kayıt açılır). Döner: {ok, text, fire}.
func light_old(hearth_id: String, at: Vector2) -> Dictionary:
	var f := fires.by_id(hearth_id)
	if f == null:
		f = FireState.new()
		f.id = hearth_id
		f.old = true
		f.stones = true
		f.zone = zone
		f.x = at.x
		f.z = at.y
		var r := relight(f)
		if not bool(r["ok"]):
			return r
		f.born = now_abs()
		fires.fires.append(f)
		fire_added.emit(f)
		r["fire"] = f
		return r
	var res := feed(f)
	res["fire"] = f
	return res


## Yeni ateşin malzemesi var mı (yakıt, kav, yakıcı; yer ve hava sayılmaz)? HUD'un «Y Ateş kur» ipucu.
func has_build_materials() -> bool:
	if free_materials:
		return true
	var i := inv()
	if i == null or not _has_lighter(i) or i.count(str((FireState.rule("build", {}) as Dictionary).get("tinder", "tag:tinder"))) <= 0:
		return false
	var need: Dictionary = (FireState.rule("build", {}) as Dictionary).get("fuel", {})
	for id: String in need:
		if fuel_count(id, i) >= int(need[id]):
			return true
	return false


## Beceri değeri (Progression.mods; bağlı değilse varsayılan): skinT, huntYield, cookQuality, mealFull.
func mod_of(key: String, def: Variant) -> Variant:
	return _mod(key, def)


## Uzakta Y: yeni ateşin planı. probe: FireSet.can_place'in yoklaması (normal, water, structures, olds, indoor) ve sheltered (barınak:
## sağanakta yakılır). Döner: {ok, reason, text, fuel, fuel_n, tinder, lighter, stones, seconds}.
func build_plan(at: Vector2, probe: Dictionary = {}) -> Dictionary:
	var p := probe.duplicate()
	p["zone"] = zone
	var why := fires.can_place(at, p)
	if not why.is_empty():
		return {"ok": false, "reason": why, "text": FireState.text(why, lang)}
	var i := inv()
	var build: Dictionary = FireState.rule("build", {})
	var stones := not free_materials and _stone_count(i, probe) >= int(build.get("stones", 6))
	var lock := _weather_lock(stones, bool(probe.get("sheltered", false)))
	if not lock.is_empty():
		return {"ok": false, "reason": "weather", "text": lock}
	var need: Dictionary = build.get("fuel", {})
	var fuel_id := ""
	for id in fuel_order():
		if free_materials or fuel_count(id, i) >= int(need.get(id, 999)):
			fuel_id = id
			break
	if fuel_id.is_empty():
		return {"ok": false, "reason": "fuel", "text": FireState.text("build_needs", lang)}
	var tinder := ""
	if not free_materials:
		var wl := _weather_light()
		var dry: Array = build.get("dry_tinder", ["resin", "birch_bark"])
		if bool(wl.get("dry_tinder", false)):
			for t: Variant in dry:
				if i and i.count(str(t)) > 0:
					tinder = str(t)
					break
			if tinder.is_empty():
				return {"ok": false, "reason": "tinder", "text": FireState.text("wet_tinder", lang)}
		elif i and i.count(str(build.get("tinder", "tag:tinder"))) > 0:
			tinder = str(build.get("tinder", "tag:tinder"))
		if tinder.is_empty():
			return {"ok": false, "reason": "tinder", "text": FireState.text("no_tinder", lang)}
		if not _has_lighter(i):
			return {"ok": false, "reason": "lighter", "text": FireState.text("no_lighter", lang)}
	var secs := float(build.get("lay_s", 2.0)) + (float(build.get("stones_s", 2.0)) if stones else 0.0) + float(_weather_light().get("light_s", 3.0))
	return {"ok": true, "reason": "", "text": "", "fuel": fuel_id, "fuel_n": int(need.get(fuel_id, 0)), "tinder": tinder,
		"stones": stones, "stone_bag": probe.get("saddlebags"), "seconds": secs}


## Planı uygular: malzeme düşer (yakıt, kav, taş; yakıcı araçtır, gitmez; köz ve meşale harcanır), ateş tam yakıtla yanar, ilk yakış oto
## kayıt ister. Döner: ateş (plan geçersizse null).
func build(at: Vector2, plan: Dictionary) -> FireState:
	if not bool(plan.get("ok", false)):
		return null
	var i := inv()
	var build_rules: Dictionary = FireState.rule("build", {})
	if not free_materials and i:
		_take_fuel(str(plan["fuel"]), int(plan["fuel_n"]), i)
		i.remove(str(plan.get("tinder", "tag:tinder")), 1)
		_spend_lighter(i)
		if bool(plan.get("stones", false)):
			# Taş önce Heybe'den, kalanı yakındaki atın terkisinden (6 taş 30 Yük: sırta sığmaz, economy.md §6.14).
			var ref := str(build_rules.get("stone_ref", "stone"))
			var left := int(build_rules.get("stones", 6))
			for g: Dictionary in i.remove(ref, left):
				left -= int(g["n"])
			var bag: Variant = plan.get("stone_bag")
			if left > 0 and bag is ItemContainer:
				(bag as ItemContainer).remove(ref, left)
	var f := fires.add(at, zone, bool(plan.get("stones", false)), FireState.fuel_max(), now_abs())
	message.emit(FireState.text("lit", lang), "info")
	_request_autosave()
	return f


## F basılı 2 sn (yalnız Kor): Küle Yatır; köz ertesi doğuştan 1 oyun saati sonrasına dek yaşar. Döner: {ok, text}.
func bank(f: FireState) -> Dictionary:
	if f and f.hearth:
		return _fail(FireState.text("hearth", lang), "info")
	if f == null or not f.is_lit() or f.stage() != &"embers":
		return _fail(FireState.text("bank_embers", lang))
	f.bank(_bank_until(), now_abs())
	fire_changed.emit(f)
	return _ok(FireState.text("banked", lang))


## F basılı 1 sn (Küçük, Orta, Büyük): Söndür. Su Dolu Tulum'dandır (boşalır) ya da yerdeki kardan (snow). Döner: {ok, text}.
func douse(f: FireState, snow := false) -> Dictionary:
	if f and f.hearth:
		return _fail(FireState.text("hearth", lang), "info")
	if f == null or not f.is_lit() or f.stage() == &"embers":
		return _fail(FireState.text("bank_embers", lang) if f and f.is_lit() else FireState.text("douse_needs", lang))
	var i := inv()
	var water := str((Cooking.data()).get("water_ref", "waterskin"))
	if not snow and not free_materials and (i == null or i.count(water) <= 0):
		return _fail(FireState.text("douse_needs", lang))
	if not snow and not free_materials:
		i.remove(water, 1)
		i.add("skin_bag", 1, "douse", true)
	f.douse(now_abs())
	fire_changed.emit(f)
	return _ok(FireState.text("doused", lang))


## F'nin o ateşteki işi: "bank" (Kor), "douse" (Küçük ve üstü) ya da "".
static func f_job(f: FireState) -> String:
	if f == null or not f.is_lit() or f.hearth:
		return ""
	return "bank" if f.stage() == &"embers" else "douse"


func _bank_until() -> float:
	var after := float(FireState.rule("bank_after_sunrise_min", 60.0))
	if clock and clock.has_place():
		var sunrise := clock.next(&"sunrise")
		if is_finite(sunrise):
			return sunrise + after
	# Yer verilmemiş saatte doğuş 06:00 sayılır.
	var now := now_abs()
	var next := floorf(now / 1440.0) * 1440.0 + 360.0
	if next <= now:
		next += 1440.0
	return next + after


## Havanın yakma kilidi (yazısı; "" geçer): dolu, açıkta sağanak, taşsız fırtına.
func _weather_lock(stones: bool, sheltered := false) -> String:
	var wl := _weather_light()
	if bool(wl.get("never", false)):
		return FireState.text("hail", lang)
	if bool(wl.get("open", false)) and not sheltered:
		return FireState.text("no_open", lang)
	if bool(wl.get("stones", false)) and not stones:
		return FireState.text("wind_stones", lang)
	return ""


func _weather_light() -> Dictionary:
	var table: Dictionary = FireState.rule("weather_light", {})
	return table.get(weather_type(), table.get("clear", {"light_s": 3.0}))


func _has_lighter(i: Inventory) -> bool:
	if i == null:
		return false
	for ref: Variant in (FireState.rule("build", {}) as Dictionary).get("lighters", []):
		if i.has(str(ref)):
			return true
	return false


## Yakıcının bedeli: çakmak taşı ve Köz Kabı araçtır (gitmez); köz ve meşale harcanır.
func _spend_lighter(i: Inventory) -> void:
	for ref: Variant in (FireState.rule("build", {}) as Dictionary).get("lighters", []):
		if not i.has(str(ref)):
			continue
		if str(ref) in ["ember", "torch"]:
			i.remove(str(ref), 1)
		return


func _stone_count(i: Inventory, probe: Dictionary) -> int:
	var ref := str((FireState.rule("build", {}) as Dictionary).get("stone_ref", "stone"))
	var n := i.count(ref) if i else 0
	var bag: Variant = probe.get("saddlebags")
	if bag is ItemContainer:
		n += (bag as ItemContainer).count(ref)
	return n


func _take_fuel(fuel_id: String, n: int, i: Inventory) -> void:
	var left := n
	for ref: Variant in FireState.fuel_row(fuel_id).get("refs", []):
		if left <= 0:
			break
		var got := i.remove(str(ref), left)
		for g: Dictionary in got:
			left -= int(g["n"])


func _on_fire_added(f: FireState) -> void:
	fire_added.emit(f)


func _on_fire_removed(f: FireState) -> void:
	fire_removed.emit(f)


# --- Pişirme ----------------------------------------------------------------------------------------------

## Ateşin tarif çemberi: bilinen ateş tarifleri ve durumları [{id, name, station, ok, reason, missing}] (reason: "", "no_station",
## "no_pot", "weather", "missing").
func cook_options(f: FireState) -> Array:
	var out: Array = []
	var i := inv()
	var counter := func(ref: String) -> int: return i.count(ref) if i else 0
	var has_pot := i != null and i.count(str(Cooking.data().get("pot_ref", "pot"))) > 0
	var stations := Cooking.stations_for(f, has_pot)
	for rec: Dictionary in Cooking.recipes():
		var id := str(rec.get("id", ""))
		var station := str(rec.get("station", ""))
		if not known.has(id) or not Cooking.is_fire_station(station):
			continue
		var reason := ""
		var lack := {}
		if not stations.has(station):
			reason = "no_pot" if station == "cauldron" and f and f.is_lit() and (f.stage_row().get("cook", []) as Array).has("cauldron") else "no_station"
		elif Cooking.weather_k(station, weather_type()) < 0.0:
			reason = "weather"
		elif not free_materials and Cooking.pick_inputs(rec, counter).is_empty():
			reason = "missing"
			lack = Cooking.missing(rec, counter)
		out.append({"id": id, "name": ItemCatalog.name_of(id, lang), "station": station, "ok": reason.is_empty(), "reason": reason, "missing": lack})
	return out


## Pişirmeye başlar: girdi Heybe'den alınır (yarıda bırakılınca geri döner), süre evre ve havadan, Ocağa Pay ateşin bugünüdür. Döner:
## {ok, text, job}.
func start_cook(recipe_id: String, f: FireState, share := false) -> Dictionary:
	if job != null:
		cancel_cook()
	var rec := Cooking.recipe(recipe_id)
	if rec.is_empty() or not known.has(recipe_id):
		return _fail(Cooking.text("unknown", lang))
	var opt: Dictionary = {}
	for o: Dictionary in cook_options(f):
		if str(o["id"]) == recipe_id:
			opt = o
	if opt.is_empty() or not bool(opt["ok"]):
		var why := str(opt.get("reason", "no_station"))
		match why:
			"missing":
				var names := PackedStringArray()
				for ref: String in opt.get("missing", {}):
					names.append(ref_name(ref))
				return _fail(Cooking.text("missing", lang, {"items": ", ".join(names)}))
			"weather":
				return _fail(Cooking.text("weather_blocks", lang))
			"no_pot":
				return _fail(Cooking.text("no_pot", lang))
		return _fail(Cooking.text("no_station", lang))
	var i := inv()
	var taken := {}
	if not free_materials and i:
		var counter := func(ref: String) -> int: return i.count(ref)
		var inputs := Cooking.pick_inputs(rec, counter)
		for ref: String in inputs:
			for g: Dictionary in i.remove(ref, int(inputs[ref])):
				taken[str(g["id"])] = int(taken.get(str(g["id"]), 0)) + int(g["n"])
	var station := str(rec.get("station", ""))
	var has_water := i != null and i.count(str(Cooking.data().get("water_ref", "waterskin"))) > 0
	var stage_row := f.stage_row()
	var T := Cooking.seconds_for(rec, stage_row, weather_type(), has_water)
	var j := Cooking.Job.make(recipe_id, taken, T, bool(rec.get("timed", false)), station == "ember" and bool(stage_row.get("safe", false)),
		Cooking.burn_k(station, stage_row))
	j.fire_id = f.id
	j.drop = Cooking.quality_drop(weather_type())
	if station == "cauldron" and _mod("cookQuality", 0.0) >= 1.0:
		j.bonus = 1
	if share and f.give_share(day()):
		j.share = true
	elif share:
		message.emit(Cooking.text("share_used", lang), "warn")
	job = j
	fresh = {}
	cook_started.emit(j)
	return _ok(Cooking.text("cooking", lang, {"dish": ItemCatalog.name_of(recipe_id, lang)}), {"job": j})


## E (Tam Vuruş): zamanlı işte hüküm. Döner: kalite (3, 1, 0 Yanık) ya da −1 (henüz pişmedi), −2 (iş yok ya da zamansız).
func cook_press() -> int:
	if job == null:
		return Cooking.Q_PENDING
	var q := job.press()
	if q == Cooking.Q_EARLY:
		message.emit(Cooking.text("not_yet", lang), "info")
	elif q != Cooking.Q_PENDING:
		_finish_job()
	return q


## İş yarıda bırakıldı (oyuncu yürüdü, ateş söndü): girdi Heybe'ye döner. Döner: bırakılan iş vardı mı.
func cancel_cook() -> bool:
	if job == null:
		return false
	var j := job
	job = null
	var i := inv()
	if i:
		for item_id: String in j.inputs:
			i.add(item_id, int(j.inputs[item_id]), "cook", true)
	if j.share:
		var f := fires.by_id(j.fire_id)
		if f and f.share_day == day():
			f.share_day = -1
	cook_cancelled.emit(j)
	message.emit(Cooking.text("left", lang), "info")
	return true


func _tick_job(sec: float) -> void:
	if job == null:
		return
	var f := fires.by_id(job.fire_id)
	if f == null or not f.is_lit():
		cancel_cook()
		return
	if job.tick(sec) != Cooking.Q_PENDING:
		_finish_job()


func _finish_job() -> void:
	var j := job
	job = null
	var i := inv()
	if i:
		i.receive(j.out, 1, "cook")
	var first := not made.has(j.recipe_id)
	made[j.recipe_id] = true
	if first and progression and progression.has_method(&"award"):
		progression.call(&"award", "recipe", {"key": j.recipe_id})
	fresh = {"item": j.out, "quality": maxi(j.quality, 1), "share": j.share, "left": FRESH_S, "fire": j.fire_id}
	var dish := ItemCatalog.name_of(j.recipe_id, lang)
	if j.quality == Cooking.Q_BURNT:
		message.emit(Cooking.text("burnt", lang), "warn")
	else:
		message.emit(Cooking.text("done", lang, {"dish": dish, "stars": Cooking.stars(j.quality)}), "info")
	if first and j.quality != Cooking.Q_BURNT:
		message.emit(Cooking.text("first", lang, {"dish": dish}), "info")
	cook_finished.emit(j)
	changed.emit()


## Ateş başında hemen ye (yıldız geçer). Döner: kazanılan Tokluk (yemek yoksa 0).
func eat_fresh() -> float:
	if fresh.is_empty():
		return 0.0
	var item := str(fresh["item"])
	var q := int(fresh["quality"])
	var share := bool(fresh["share"])
	fresh = {}
	return eat(item, q, share)


## Yer (Heybe'den bir tane): Tokluk (kalite ve Ocağa Pay), süreli etki (en çok iki), anlık etki (yara, stamina, Can). Döner: kazanılan Tokluk.
func eat(item_id: String, quality := 2, share := false) -> float:
	var i := inv()
	if i == null or i.count(item_id) <= 0:
		return 0.0
	var food: Variant = ItemCatalog.row(item_id).get("food")
	if not food is Dictionary:
		return 0.0
	i.remove(item_id, 1)
	var gained := needs.eat(item_id, quality, share)
	var f := food as Dictionary
	var qk := Cooking.quality_k(quality)
	var buff: Variant = f.get("buff")
	if buff is Dictionary:
		_add_buff(item_id, buff, qk)
	if f.get("wounds") is float or f.get("wounds") is int:
		if wounds.heal(-int(f["wounds"])) > 0:
			message.emit(_needs_text("healed"), "info")
	if f.get("stamina") is float or f.get("stamina") is int:
		stamina_gained.emit(float(f["stamina"]))
	if f.get("hp") is float or f.get("hp") is int:
		hp_gained.emit(float(f["hp"]), float(f.get("hpSec", 0.0)))
	ate.emit(item_id, gained)
	message.emit(Cooking.text("ate", lang, {"dish": ItemCatalog.name_of(item_id, lang), "n": int(round(gained))}), "info")
	changed.emit()
	return gained


func _add_buff(item_id: String, buff: Dictionary, qk: float) -> void:
	var mods := {}
	for k: Variant in buff:
		if str(k) != "sec":
			mods[str(k)] = buff[k]
	buffs.append({"item": item_id, "left": float(buff.get("sec", 0.0)) * qk, "mods": mods})
	var cap := int(Needs.data().get("buff_max", 2))
	while buffs.size() > cap:
		buffs.pop_front()


func _tick_buffs(sec: float) -> void:
	if buffs.is_empty() or sec <= 0.0:
		return
	for b: Dictionary in buffs:
		b["left"] = float(b["left"]) - sec
	buffs = buffs.filter(func(b: Dictionary) -> bool: return float(b["left"]) > 0.0)


## Süreli etkilerin toplamı (Derive'ın «buff» girdisi): stat ve sta toplanır, staRegen, runMul, visMul çarpılır.
func buff_block() -> Dictionary:
	var out := {"staRegen": 1.0, "runMul": 1.0, "visMul": 1.0}
	for b: Dictionary in buffs:
		for k: String in b["mods"]:
			var v := float(b["mods"][k])
			if k in ["staRegen", "runMul", "visMul"]:
				out[k] = float(out[k]) * v
			else:
				out[k] = float(out.get(k, 0.0)) + v
	return out


func ref_name(ref: String) -> String:
	if ref.begins_with("tag:"):
		return ItemCatalog.label("tags", ref.substr(4), lang)
	return ItemCatalog.name_of(ref, lang)


# --- Av ------------------------------------------------------------------------------------------------------

## Düşen hayvanı yüzer (yetişkin; E basılı 2 sn): verim verim Heybe'ye, sığmayan terkiye ve leşin yerine. opts: clean (tek okta düştü),
## kopuz. Döner: {ok, text, added, rest, first}.
func skin(kind_id: String, at: Variant = null, opts: Dictionary = {}) -> Dictionary:
	var i := inv()
	if Hunt.skin_block(kind_id, i) == "need_knife":
		return _fail(Hunt.text("need_knife", lang))
	var ctx := {"season": season(), "clean": bool(opts.get("clean", false)), "hunter": int(_mod("huntYield", 0.0)),
		"kopuz": bool(opts.get("kopuz", false))}
	var y := Hunt.yield_of(kind_id, ctx)
	var r := Hunt.deliver(i, y, at)
	var first := not hunted_kinds.has(kind_id)
	hunted_kinds[kind_id] = int(hunted_kinds.get(kind_id, 0)) + 1
	if first and progression and progression.has_method(&"award"):
		progression.call(&"award", "hunt", {"key": kind_id})
	var kind_name := Catalog.pick(Hunt.kind_row(kind_id).get("name", kind_id), lang)
	message.emit(Hunt.text("got", lang, {"kind": kind_name, "items": Hunt.items_text(y, lang)}), "info")
	hunted.emit(kind_id, r["added"])
	changed.emit()
	return {"ok": true, "text": "", "added": r["added"], "rest": r["rest"], "first": first, "yield": y}


## Heybe'deki bütün avı düzer (Çocukluk'un avı; mevsimin eki o günün mevsimidir).
func dress(item_id: String, at: Variant = null) -> Dictionary:
	return Hunt.dress(inv(), item_id, {"season": season()}, at)


# --- Yara ve Düşüş --------------------------------------------------------------------------------------------

## Can 0 (Mete): Yara +1. Döner: Düşüş oldu mu (olmadıysa çağıran Can'ı %50'ye çeker).
func on_hp_zero() -> bool:
	return wounds.hit_zero()


func _on_fell(plan: Dictionary) -> void:
	if job:
		cancel_cook()
	fell.emit(plan)


## Düşüşü uygular (görünüm karanlıkta çağırır): yara uyanış sayısına iner, erzak bedeli düşer (en az Kıymetli yiyecekten), saat +2 oyun
## saati ilerler (bekleyişi geçmez). Döner: plan ve lost [{id, n}].
func apply_fall() -> Dictionary:
	var i := inv()
	var amulet := i != null and i.equipped("neck") == "deer_amulet"
	var kut := int(kut_source.call()) if kut_source.is_valid() else 0
	var plan := wounds.fall({"kut": kut, "amulet": amulet})
	var lost: Array = []
	for _k in int(plan["cost"]):
		var item := _cheapest_food(i)
		if item.is_empty():
			break
		i.remove(item, 1)
		lost.append({"id": item, "n": 1})
	plan["lost"] = lost
	if clock:
		clock.skip(float(plan["skip_min"]), &"cine")
	else:
		_advance(float(plan["skip_min"]) * FireState.minute_s(), float(plan["skip_min"]), _local_abs + float(plan["skip_min"]), {})
		_local_abs += float(plan["skip_min"])
	changed.emit()
	return plan


func _cheapest_food(i: Inventory) -> String:
	if i == null:
		return ""
	var best := ""
	var best_worth := INF
	for it: Dictionary in i.pack.list():
		var id := str(it["id"])
		if ItemCatalog.tab_of(id) != "food" or ItemCatalog.row(id).get("food") == null:
			continue
		var w := ItemCatalog.worth_of(id)
		if w < best_worth or (is_equal_approx(w, best_worth) and id < best):
			best = id
			best_worth = w
	return best


func _needs_text(key: String) -> String:
	return Catalog.pick((Needs.data().get("text", {}) as Dictionary).get(key, key), lang)


# --- Kayıt (godot.md §3.4 «survival»; survival.md §2.8, §7.10) ------------------------------------------------------

## {v, recipes, made, fires, tents, sleep: {last_night}, snares, needs: {fullness}, wounds: {n, falls, rest_at}, hunted}.
func to_dict() -> Dictionary:
	flush_needs()
	var rec := PackedStringArray(known.keys())
	rec.sort()
	var mk := PackedStringArray(made.keys())
	mk.sort()
	return {"v": BLOCK_V, "recipes": Array(rec), "made": Array(mk), "fires": fires.to_array(), "tents": tents.duplicate(true),
		"sleep": {"last_night": sleep_last_night}, "snares": snares.duplicate(true), "needs": needs.to_dict(), "wounds": wounds.to_dict(),
		"hunted": hunted_kinds.duplicate()}


## Bloğu okur (bozuk alan varsayılanıyla açılır). Döner: okundu mu (sözlük değilse false: kayıt boş yuva sayılır).
func from_dict(d: Variant) -> bool:
	if not d is Dictionary:
		return false
	var o := d as Dictionary
	known = {}
	for id in Cooking.start_known():
		known[id] = true
	for r: Variant in (o.get("recipes", []) if o.get("recipes") is Array else []):
		if not Cooking.recipe(str(r)).is_empty():
			known[str(r)] = true
	made = {}
	for r: Variant in (o.get("made", []) if o.get("made") is Array else []):
		made[str(r)] = true
	fires.from_array(o.get("fires", []))
	tents = (o.get("tents", []) as Array).duplicate(true) if o.get("tents") is Array else []
	snares = (o.get("snares", []) as Array).duplicate(true) if o.get("snares") is Array else []
	var sl: Variant = o.get("sleep", {})
	sleep_last_night = int((sl as Dictionary).get("last_night", -1)) if sl is Dictionary and ((sl as Dictionary).get("last_night") is int or (sl as Dictionary).get("last_night") is float) else -1
	needs.from_dict(o.get("needs", {}))
	wounds.from_dict(o.get("wounds", {}))
	hunted_kinds = {}
	var h: Variant = o.get("hunted", {})
	if h is Dictionary:
		for k: Variant in h:
			if h[k] is int or h[k] is float:
				hunted_kinds[str(k)] = int(h[k])
	job = null
	fresh = {}
	buffs = []
	_needs_acc = 0.0
	_last_abs = clock.abs_minute() if clock else NAN
	changed.emit()
	return true


## Yeni yolculuk ya da bloksuz kayıt.
func reset() -> void:
	from_dict({"v": BLOCK_V})
	needs.from_dict({"fullness": Needs.start_value()})


## Menünün durağan denetimi (SaveBlocks.OWNERS: «survival» → Survival): "" geçer.
static func validate_save_block(d: Dictionary) -> String:
	for key: String in ["fires", "tents", "snares", "recipes"]:
		if d.has(key) and not d[key] is Array:
			return "survival.%s dizi değil" % key
	if d.has("needs") and not d["needs"] is Dictionary:
		return "survival.needs sözlük değil"
	for row: Variant in d.get("fires", []):
		if not row is Dictionary or not FireState.STATES.has(StringName(str((row as Dictionary).get("state", "")))):
			return "survival.fires: bozuk satır"
	return ""


# --- İç ---------------------------------------------------------------------------------------------------------

func _mod(key: String, def: Variant) -> Variant:
	if progression and progression.has_method(&"mod"):
		var v: Variant = progression.call(&"mod", key, def)
		if v is float or v is int:
			return v
	return def


func _request_autosave() -> void:
	if session and is_instance_valid(session):
		session.request_autosave(&"fire")


func _ok(text: String, extra: Dictionary = {}) -> Dictionary:
	if not text.is_empty():
		message.emit(text, "info")
	var r := {"ok": true, "text": text}
	r.merge(extra)
	return r


func _fail(text: String, kind := "warn") -> Dictionary:
	message.emit(text, kind)
	return {"ok": false, "text": text}
