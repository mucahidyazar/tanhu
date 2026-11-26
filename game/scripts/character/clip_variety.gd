class_name ClipVariety
extends RefCounted
## Animasyon çeşitliliği: kütüphanedeki (K90; ClipLibrary, data/clip_library.json) çeşitlerden her kişiye kendi klipleri
## atanır; aynı sahnedeki iki kişi bir öbekte, uygun çeşit kaldıkça aynı klibi almaz. Atama saftır ve belirlenimcidir: aynı
## kişi her çalıştırmada aynı çeşitleri alır (rastgele sayı yok, nesne kimliği yok).
##
## Kişi profili {body, age, style} (profile_of): kişinin meta.json'undaki "variety" alanı; yoksa kütüphanenin characters
## kaydındaki beden. Yaş yazılı değilse bedenden gelir (çocuk bedeni child, öteki adult).
##
## Uygun çeşitler (eligible), tanımdaki tags ile:
##   - tanımda scene_only taşıyan klip varsayılan atamaya girmez, yalnız sahnenin elle seçimiyle (Allocator.assign) gelir: pozu kabul
##     edilmemiş klip (ground_side_sit: bacaklar yana toplanmaz, sol ayak havada) kişiye hash'le düşmesin;
##   - beden ve yaş kişiye uymalı;
##   - PERSONA_STYLES (proud, warrior) taşıyan çeşit yalnız o stile sahip kişiye gider;
##   - SITUATION_STYLES (chore, talk, festive...) taşıyan çeşit varsayılan atamaya girmez: kişinin stilinde yoksa
##     options.situations ile açıkça istenir (o zaman havuz o durumun çeşitlerine daralır). «calm» de taşıyan çeşit durum
##     sayılmaz: ground_warm_hands (night, calm) ve ground_kneel_heels (calm, ceremony) her zaman uygun bir oturuştur;
##   - elinde eşya isteyen çeşit (PROP_CLIPS) yalnız options.props o eşyayı verirse;
##   - yerde oturuşta kalça boşluğu ölçülür (ClipLibrary.seat_gap_for): bu kişide bedeni MAX_SEAT_GAP'ten yukarıda tutan çeşit
##     varsayılan havuza girmez, yalnız sahnenin elle seçimiyle (Allocator.assign) ve altına oturak koyarak gelir (ateş başında
##     Çocuk'un kütüğü). Boşluğu olan oturuşların çoğu klip kurulurken düzeltilir (ClipLibrary.fit_legs), sayılmaz;
##   - oturak isteyen öbek (sit_chair) yalnız sahne oturak verirse (options.seat = {type: "chair", hips_m}): çeşidin bu
##     modeldeki kalça yüksekliği (hips_height_for) oturağa uymalı;
##   - yürüme ve koşma öbeğinde çeşit döngülü olmalı (birkaç adım atıp duran geçişler rol olamaz) ve doğal hızı, oynatma hızı
##     sınırları içinde (CharacterAvatar.WALK_RATE_RANGE, RUN_RATE_RANGE) kişinin gideceği hıza (options.speeds, yoksa
##     DEFAULT_SPEEDS) yetişmeli: elderly_shaky_walk (≈0,22 m/sn) 1,4 m/sn yürüyen kişide ayakları yerde kaydırırdı.
##     Hiçbiri yetişmezse hızı sınıra en yakın tek çeşit kalır: ayağı en az o kaydırır.
##
## Seçim (pick): başlangıç sırası hash(kişi + ":" + öbek), StableSeed'in yöntemi; ağırlıklı (tanımın weight'i): göze batan
## çeşit daha az kişiye düşer. Kişinin stilini taşıyan çeşitler öne alınır (iyileştirme: Teoman proud ise gururlu duruş ve
## yürüyüşü hash'e bırakılmaz; stil kişiyi ayırsın diye vardır). Alınmış (taken) çeşit atlanır; hepsi alınmışsa hash'li olan.
##
## Allocator sahne başına taken tutar; kişiler sabit sırayla kaydolur (register), sıra aynıysa atama aynıdır. CharacterAvatar
## atanan çeşitle rollerini değiştirir (ClipLibrary.clip_for); CineActor ve CampNpcs kişilerini kaydeder. Oyuncunun kendi
## ayarlı klibi (pinned_roles) ve sahnenin el seçimi (Allocator.assign) atamanın önüne geçer.
##
## Ağır iş (ClipRetarget, klip başına 4-40 ms) model ve klip başına bir kezdir (ClipLibrary.clip_for önbelleği); kare içinde
## aktarım olmasın diye sahne kurulumda ısıtır (CharacterAvatar.warm_variety, CineActor.ensure_idle). Kaynak sahneleri kurulum
## bitince release_sources bırakır.
##
##   var allocator := ClipVariety.Allocator.new()
##   allocator.register("teoman")                        # kayıt sırası sahnede sabittir
##   allocator.key_for_role("teoman", &"walk")           # "proud_strut"
##   avatar.variety_person = "teoman"; avatar.variety_allocator = allocator   # model yüklenmeden önce

## Düğümde sahnenin dağıtıcısını taşıyan meta veri (kişilerin üst düğümünde).
const ALLOCATOR_META := &"clip_variety_allocator"
## Rolün varsayılan öbeği (oturak verilmişse oturma rolü SEAT_GROUP'tur).
const ROLE_GROUPS := {&"idle": "idle_loop", &"walk": "walk", &"run": "run", &"sit": "sit_ground"}
const GROUND_GROUP := "sit_ground"
const SEAT_GROUP := "sit_chair"
const FIDGET_GROUP := "idle_fidget"
## Döngülü oynaması gereken öbekler (rol olur).
const LOOP_GROUPS: Array[String] = ["idle_loop", "walk", "run"]
## Kişiye özgü stiller: bu stili taşımayan kişiye gitmez.
const PERSONA_STYLES: Array[String] = ["proud", "warrior"]
## Durum stilleri: varsayılan atamaya girmez (bkz. eligible). Kıpırdanmada da süzer: anlatan eller (talk) ve koşudan sonra
## soluklanma (tired) durup dururken oynamaz.
const SITUATION_STYLES: Array[String] = ["chore", "talk", "festive", "meal", "drink", "sick", "greet", "listen", "angry",
	"passion", "restless", "night", "tired", "ceremony", "leisure"]
## Bu stili de taşıyan çeşit durum sayılmaz.
const CALM_STYLE := "calm"
## Elinde eşya isteyen, durum stili taşımadığı için ayrıca süzülen çeşitler: anahtar → eşya (options.props).
const PROP_CLIPS := {"spear_walk": "spear"}
## Yerde oturuşta kalça boşluğunun üst sınırı (metre; ClipLibrary.seat_gap_for): bunu aşan çeşit bu kişide havada görünür, varsayılan
## havuza girmez. Bağdaşın kumaşlı kalçası bile 2-3 cm boşluk bırakır; bugün yalnız ground_hug_knees aşar (dizler kucakta, kalça 40 cm).
const MAX_SEAT_GAP := 0.06
## Oturuşta dikişi kapatılabilecek en büyük ayrışma (derece; role_clip).
const MAX_SEAT_SEAM_DEG := 45.0
## Sahne söylemezse kişinin gideceği hızlar (m/sn): sinemanın yürüyüşü 1,2-1,45, kalabalığın koşusu CharacterAvatar.RUN_SPEED.
const DEFAULT_SPEEDS := {"walk": 1.2, "run": 4.2}
## Oturağın kalça yüksekliğiyle çeşidinki arasındaki pay (metre).
const SEAT_TOLERANCE := 0.08
## Ara hareketin bekleme aralığı (saniye).
const FIDGET_WAIT := Vector2(8.0, 20.0)
## Oynatıcıda çeşit klibinin adı: model başına tek (aynı modeli gösteren kişiler oynatıcının kütüphanesini paylaşır).
const CLIP_PREFIX := "v_"
## Kaydın yedeği: kişinin bekleme klibi yoksa bu klip bağışçısından (ClipLibrary.donor_for) aktarılır.
const FALLBACK_IDLE := "idle_3"

## profile_of önbelleği (kişilerin klasörü + kimlik → profil).
static var _profiles := {}
## Oturuşların dikişi kapatılmış kopyaları ("model|anahtar" → Animation; bkz. role_clip).
static var _seat_loops := {}


## Oyunun ortak kütüphanesi (clip_for'un önbelleği kişiler arasında paylaşılır).
static func library() -> ClipLibrary:
	return ClipLibrary.shared()


## Kaynak sahneleri bırakır (kurulan klipler kalır): sahne kurulumu ya da sahne bitince.
static func release_sources() -> void:
	library().release()


## Kararlı sayı: StableSeed'in yöntemi (String.hash), çalıştırmadan çalıştırmaya aynı.
static func stable_hash(text: String) -> int:
	return absi(text.hash())


## Kişinin döngülü kliplerde başlangıç evresi (0..1): kararlı.
static func phase_of(person_id: String) -> float:
	return float(ClipVariety.stable_hash(person_id + ":phase") % 1009) / 1009.0


## Çeşit klibinin oynatıcıdaki adı.
static func clip_name(key: String) -> StringName:
	return StringName(CLIP_PREFIX + key)


## Kişinin profili: {body, age, style} (meta.json "variety", yoksa kütüphane). Önbellekli; değiştirmeyin.
static func profile_of(person_id: String, root: String = StandIn.ROOT) -> Dictionary:
	var cache_key := root.path_join(person_id)
	if _profiles.has(cache_key):
		return _profiles[cache_key]
	var record: Variant = StandIn.meta(person_id, root).get("variety")
	var own: Dictionary = record if record is Dictionary else {}
	var body := str(own.get("body", ""))
	if body.is_empty():
		body = library().body_of(person_id)
	if body.is_empty():
		body = "male"
	var age := str(own.get("age", ""))
	if age.is_empty():
		age = "child" if body == "child" else "adult"
	var style: Array = own.get("style", []) if own.get("style") is Array else []
	var profile := {"body": body, "age": age, "style": style}
	_profiles[cache_key] = profile
	return profile


## Rolün öbeği (sahne oturak verdiyse oturma rolü sit_chair).
static func group_for(role: StringName, options: Dictionary = {}) -> String:
	if role == &"sit" and ClipVariety._seat_type(options) == "chair":
		return SEAT_GROUP
	return str(ROLE_GROUPS.get(role, ""))


## Kişinin modeli (kendi modeli ya da yer tutucusu): ölçüler modele göredir.
static func model_of(person_id: String) -> String:
	return str(StandIn.resolve(person_id).get("model", person_id))


## Öbeğin kişiye uygun çeşitleri, tanımdaki sırayla (kurallar: dosyanın başı). options: situations (Array), props (Array), seat
## ({type, hips_m}), speeds ({walk, run}), model (ölçülerin modeli), from ve to (geçişlerin duruşları: stand, sit_ground...).
static func eligible(group: String, profile: Dictionary, options: Dictionary = {}) -> Array:
	var lib := library()
	var style: Array = profile.get("style", [])
	var situations: Array = options.get("situations", [])
	var out := []
	var situated := []
	for key: String in lib.variants_in(group):
		var spec := lib.variant(key)
		if bool(spec.get("scene_only", false)) or not ClipVariety._fits_person(spec, profile) or not ClipVariety._fits_scene(key, spec, options):
			continue
		var tags: Array = ClipVariety._styles(spec)
		if ClipVariety._has_any(tags, situations):
			situated.append(key)
		if ClipVariety._is_situation(tags) and not ClipVariety._has_any(tags, style):
			continue
		if group == GROUND_GROUP and lib.seat_gap_for(str(options.get("model", "")), key) > MAX_SEAT_GAP:
			continue
		out.append(key)
	# Açıkça istenen durum havuzu daraltır (o öbekte o durumun çeşidi varsa); durum çeşidi yalnız böyle gelir.
	return ClipVariety._within_speed(group, situated if not situated.is_empty() else out, options)


## Kişinin çeşidi: öbeğin uygun çeşitlerinden hash'in gösterdiği, taken'daki (aynı sahnede o öbekte alınmış) atlanarak; hepsi
## alınmışsa hash'li olan. Uygun çeşit yoksa boş.
static func pick(person_id: String, group: String, profile: Dictionary, taken: Array = [], options: Dictionary = {}) -> String:
	var order := ClipVariety.pick_order(person_id, group, profile, options)
	for key: String in order:
		if not taken.has(key):
			return key
	return str(order[0]) if not order.is_empty() else ""


## Kişinin öbekteki çeşit sırası (pick bunun ilk boştakini alır): kişinin stilini taşıyanlar önde, ikisi de hash'ten dönük.
static func pick_order(person_id: String, group: String, profile: Dictionary, options: Dictionary = {}) -> Array:
	var style: Array = profile.get("style", [])
	var signature := []
	var rest := []
	for key: String in ClipVariety.eligible(group, profile, options):
		if ClipVariety._has_any(ClipVariety._styles(library().variant(key)), style):
			signature.append(key)
		else:
			rest.append(key)
	var seed_value := ClipVariety.stable_hash("%s:%s" % [person_id, group])
	return ClipVariety._rotated(signature, seed_value) + ClipVariety._rotated(rest, seed_value)


## Kişinin ara hareketleri: idle_fidget'in uygun çeşitleri.
static func fidget_pool(profile: Dictionary) -> Array:
	return ClipVariety.eligible(FIDGET_GROUP, profile)


## Klip modelin oyunun o rolde oynattığı kendi klibi mi (aktarım gerekmez, oynatıcıdakidir)? Kişinin bu klipte bacak düzeltmesi
## varsa (ClipLibrary.leg_fit_for) kendi klibi sayılmaz: klip clip_for'dan düzeltilmiş kurulur.
static func is_own_clip(model_id: String, key: String, role: StringName) -> bool:
	var info: Dictionary = library().game_clips(model_id).get(key, {})
	return not info.is_empty() and str(info.get("role", "")) == String(role) and library().leg_fit_for(model_id, key).is_empty()


## Modelin o rolde oynattığı kendi klibinin anahtarı (oyunun klibi; yoksa boş).
static func own_key(model_id: String, role: StringName) -> String:
	var clips: Dictionary = library().game_clips(model_id)
	for key: String in clips:
		if str((clips[key] as Dictionary).get("role", "")) == String(role):
			return key
	return ""


## Rolün klibi, oynamaya hazır (ortak kaynak; değiştirmeyin). Oturma rolünde bir kez oynayan klip (metinden hareketlerin hepsi:
## 8 sn sürer, son karesinde donup kişiyi kımıltısız bırakırdı) dikişi kapatılmış döngülü kopyasıyla verilir (ClipLibrary
## close_loop: son çeyreği ilk kareye yumuşakça döner; yer oturuşlarının ilk ve son karesi en çok 32° ayrışır). İlk ve son karesi
## MAX_SEAT_SEAM_DEG'den çok ayrışan klip (sit_arms_crossed: kollar kavuşur, 107°) döngüye sokulmaz, son pozunda durur: dikişi kapatmak
## kolları 2,4 sn'de bir açıp kavuştururdu. Kurulamazsa null.
static func role_clip(model_id: String, key: String, role: StringName, skeleton: Skeleton3D) -> Animation:
	var anim := library().clip_for(model_id, key, skeleton)
	if anim == null or role != &"sit" or anim.loop_mode != Animation.LOOP_NONE:
		return anim
	if float(library().measure(key).get("cycle_gap_deg", 0.0)) > MAX_SEAT_SEAM_DEG:
		return anim
	var cache_key := "%s|%s" % [model_id, key]
	if not _seat_loops.has(cache_key):
		var loop := anim.duplicate(true) as Animation
		ClipLibrary.close_loop(loop)
		loop.loop_mode = Animation.LOOP_LINEAR
		loop.resource_name = key
		_seat_loops[cache_key] = loop
	return _seat_loops[cache_key]


## Yürüme ya da koşma çeşidinin bu modeldeki doğal hızı (m/sn; oynatma hızı buna göre ayarlanır, ayaklar kaymaz). Model
## ölçülmemişse taşıyıcınınki, hedefin kalça oranıyla ölçekli (ClipRetarget.hips_ratio). Yoksa 0.
static func natural_speed(model_id: String, key: String, skeleton: Skeleton3D = null) -> float:
	var lib := library()
	var table: Variant = lib._model_measures(model_id).get("speed_mps")
	if table is Dictionary and (table as Dictionary).has(key):
		return float(table[key])
	var carrier := lib.speed_for(model_id, key)
	var donor := lib.donor_skeleton() if skeleton else null
	return carrier * ClipRetarget.hips_ratio(donor, skeleton) if donor else carrier


# --- İç ------------------------------------------------------------------------------------------------

static func _styles(spec: Dictionary) -> Array:
	var tags: Variant = spec.get("tags")
	return (tags as Dictionary).get("style", []) if tags is Dictionary else []


static func _has_any(values: Array, wanted: Array) -> bool:
	for value: Variant in values:
		if wanted.has(value):
			return true
	return false


## Çeşit durum çeşidi mi: durum stili taşır ve «calm» değil.
static func _is_situation(tags: Array) -> bool:
	return not tags.has(CALM_STYLE) and ClipVariety._has_any(tags, SITUATION_STYLES)


## Beden, yaş ve kişiye özgü stil.
static func _fits_person(spec: Dictionary, profile: Dictionary) -> bool:
	var tags: Variant = spec.get("tags")
	if not tags is Dictionary:
		return true
	var bodies: Variant = (tags as Dictionary).get("body")
	if bodies is Array and not (bodies as Array).has(str(profile.get("body", ""))):
		return false
	var ages: Variant = (tags as Dictionary).get("age")
	if ages is Array and not (ages as Array).has(str(profile.get("age", ""))):
		return false
	var style: Array = profile.get("style", [])
	for tag: Variant in ClipVariety._styles(spec):
		if PERSONA_STYLES.has(tag) and not style.has(tag):
			return false
	return true


## Sahnenin verdikleri: döngü, eşya, oturak, geçişin iki ucu.
static func _fits_scene(key: String, spec: Dictionary, options: Dictionary) -> bool:
	var group := str(spec.get("group", ""))
	if LOOP_GROUPS.has(group) and (not bool(spec.get("loop", true)) or spec.has("transition")):
		return false
	if PROP_CLIPS.has(key) and not (options.get("props", []) as Array).has(PROP_CLIPS[key]):
		return false
	if group == SEAT_GROUP and not ClipVariety._fits_seat(key, options):
		return false
	var transition: Variant = spec.get("transition")
	if options.has("from") and not (transition is Dictionary and str(transition.get("from")) == str(options["from"])):
		return false
	if options.has("to") and not (transition is Dictionary and str(transition.get("to")) == str(options["to"])):
		return false
	return true


static func _seat_type(options: Dictionary) -> String:
	var seat: Variant = options.get("seat")
	return str((seat as Dictionary).get("type", "")) if seat is Dictionary else ""


## Sahne oturak verdi mi, oturağın yüksekliği çeşide (bu modelde kalça yüksekliği) uyuyor mu?
static func _fits_seat(key: String, options: Dictionary) -> bool:
	if ClipVariety._seat_type(options) != "chair":
		return false
	var hips := float((options["seat"] as Dictionary).get("hips_m", 0.0))
	if hips <= 0.0:
		return true
	return absf(library().hips_height_for(str(options.get("model", "")), key) - hips) <= SEAT_TOLERANCE


## Yürüme ve koşma: doğal hızı, oynatma hızı sınırları içinde kişinin hızına yetişenler; hiçbiri yetişmiyorsa sınıra en yakın tek çeşit.
static func _within_speed(group: String, keys: Array, options: Dictionary) -> Array:
	if group != "walk" and group != "run":
		return keys
	var model := str(options.get("model", ""))
	var speeds: Dictionary = options.get("speeds", {})
	var speed := float(speeds.get(group, DEFAULT_SPEEDS[group]))
	var rates := CharacterAvatar.WALK_RATE_RANGE if group == "walk" else CharacterAvatar.RUN_RATE_RANGE
	var out := []
	var closest := ""
	var closest_gap := INF
	for key: String in keys:
		var natural := library().speed_for(model, key)
		if natural <= 0.0 or (speed >= natural * rates.x and speed <= natural * rates.y):
			out.append(key)
			continue
		var gap := maxf(speed / (natural * rates.y), natural * rates.x / speed)
		if gap < closest_gap:
			closest = key
			closest_gap = gap
	if not out.is_empty():
		return out
	return [closest] if not closest.is_empty() else keys


## Anahtarlar, başlangıcı hash'in ağırlıklı seçtiği yerden dönük.
static func _rotated(keys: Array, seed_value: int) -> Array:
	if keys.size() < 2:
		return keys
	var total := 0.0
	for key: String in keys:
		total += maxf(float(library().variant(key).get("weight", 1.0)), 0.01)
	var point := float(seed_value % 10007) / 10007.0 * total
	var start := 0
	for i in keys.size():
		point -= maxf(float(library().variant(keys[i]).get("weight", 1.0)), 0.01)
		if point < 0.0:
			start = i
			break
	return keys.slice(start) + keys.slice(0, start)


## Sahne başına dağıtıcı: öbek başına alınmış çeşitleri ve kişilerin atamalarını tutar. Kişiler sabit sırayla kaydolur; kayıt
## varsayılan öbeklerin hepsini hemen atar, böylece atama kurulumun sırasına (hangi kişi önce kurulur) bağlı kalmaz.
class Allocator:
	extends RefCounted

	## öbek → alınmış çeşitler.
	var taken := {}
	## Kayıt sırası.
	var order: Array[String] = []
	## kişi → {öbek: çeşit}.
	var chosen := {}
	## kişi → {profile, options}.
	var people := {}

	## Kişiyi kaydeder ve varsayılan öbeklerini atar (bir kez). profile boşsa profile_of; options: eligible'ın seçenekleri
	## (model verilmezse kişinin modeli).
	func register(person_id: String, profile: Dictionary = {}, options: Dictionary = {}) -> void:
		if people.has(person_id):
			return
		var own_options := options.duplicate()
		if not own_options.has("model"):
			own_options["model"] = ClipVariety.model_of(person_id)
		people[person_id] = {"profile": profile if not profile.is_empty() else ClipVariety.profile_of(person_id), "options": own_options}
		order.append(person_id)
		for role: StringName in ROLE_GROUPS:
			key_for_role(person_id, role)

	## Sahnenin elle seçimi: kişinin bu öbekteki çeşidi key'dir, öteki kişiler onu almaz. Kayıttan önce çağrılır.
	func assign(person_id: String, group: String, key: String) -> void:
		var own: Dictionary = chosen.get(person_id, {})
		own[group] = key
		chosen[person_id] = own
		_take(group, key)

	## Kişinin öbekteki çeşidi (ilk istekte atanır; kişi kayıtlı değilse kaydolur).
	func key_for(person_id: String, group: String) -> String:
		if not people.has(person_id):
			register(person_id)
		var own: Dictionary = chosen.get(person_id, {})
		if own.has(group):
			return str(own[group])
		var record: Dictionary = people[person_id]
		var key := ClipVariety.pick(person_id, group, record["profile"], taken.get(group, []), record["options"])
		own[group] = key
		chosen[person_id] = own
		if not key.is_empty():
			_take(group, key)
		return key

	## Kişinin rolündeki çeşit.
	func key_for_role(person_id: String, role: StringName) -> String:
		var options: Dictionary = (people.get(person_id, {}) as Dictionary).get("options", {})
		var group := ClipVariety.group_for(role, options)
		return key_for(person_id, group) if not group.is_empty() else ""

	func profile_for(person_id: String) -> Dictionary:
		if not people.has(person_id):
			register(person_id)
		return people[person_id]["profile"]

	func _take(group: String, key: String) -> void:
		var list: Array = taken.get(group, [])
		if not list.has(key):
			list.append(key)
		taken[group] = list


## Ara hareketin saati: kişiye bağlı tohumla (aynı kişi aynı sırayı alır) bekleme süresi (FIDGET_WAIT) ve klip (art arda aynısı
## değil; havuz tek klipse o).
class FidgetClock:
	extends RefCounted

	var pool: Array = []
	var last := ""
	var _rng := RandomNumberGenerator.new()

	func _init(person_id: String, p_pool: Array) -> void:
		pool = p_pool
		_rng.seed = ClipVariety.stable_hash(person_id + ":fidget")

	func next_wait() -> float:
		return _rng.randf_range(FIDGET_WAIT.x, FIDGET_WAIT.y)

	func next_key() -> String:
		if pool.is_empty():
			return ""
		var options := pool.filter(func(key: String) -> bool: return key != last)
		if options.is_empty():
			options = pool
		last = str(options[_rng.randi_range(0, options.size() - 1)])
		return last
