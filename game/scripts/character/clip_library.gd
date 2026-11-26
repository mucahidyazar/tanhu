class_name ClipLibrary
extends RefCounted
## Klip kütüphanesi (K90): Meshy'den satın alınan her hareket yalnız bir kez alınır ve bütün karakterlere ClipRetarget
## ile aktarılır. Tanım res://data/clip_library.json'dadır: klipler (anahtar, rol, Meshy hareketi, bağışçılar) ve
## kişilerin bedeni (male, female, child) ile öbeği (player, named, crowd).
##
## Bir karakterin bir klibi nereden gelir (resolve):
##   1. Oyunun o rol için oynattığı klip (CharacterAvatar: ana GLB'nin klibi ya da <id>_<rol>.res) o anahtarın
##      kaynağıdır: kişinin kendi alımıysa "native", bir bağışçıdan aktarılmışsa "retarget" ve bağışçısı
##      (character_fit_tool.gd DONORS ve meta.json clip_donors; donors_of).
##   2. Oyunda kullanılmayan ama satın alınmış ham GLB (assets/_meshy_raw/<id>/<id>_animation_<n>.glb): "native_raw".
##   3. Gerisi kişinin bedenine göre bağışçıdan aktarılır: "retarget" (donor_for). Bağışçı bulunamazsa "missing".
## Kişinin kendi klibini kişinin kayıtları söyler: ana GLB'nin klibi kişinin own_actions[0]'ıdır (clip_library.json characters:
## asset_plan.json animations'ın oyundaki kopyası, prepare_character.py böyle kurar; tools/ dışa aktarılmış oyunda yoktur, sınama
## ikisini aynı tutar); <id>_<rol>.res meta.json'un extra_clips'inde yazılıysa kişinin kendi klibidir
## (prepare_character.py çıkarır: yürüme, koşma ve kalan planlı hareketler), yazılı değilse ve rol bağışçı tablosundaysa
## bağışçıdan aktarılmıştır (character_fit_tool.gd yazar, meta.json'a dokunmaz).
##
## Taşıyıcı (carriers): karakter olmayan bir iskelet; bir paketin hareketleri ona bir kez alınır (E9: _anim_library,
## anim_batch_NN.glb'lerde onar hareket, motion_anim_<anahtar>.glb'lerde metinden hareketler). Taşıyıcı klibinin
## bağışçısı taşıyıcıdır: her karaktere ondan aktarılır (karakter aynı hareketi kendisi için almışsa kendi alımı önce
## gelir). Taşıyıcı klipleri oyunun rol çözümüne (keys_for_role, karakterin kendi .res'i) karışmaz.
##
## Alımlar meshy.json'lardan okunur (meshy_actions): anim_<n> görevi tek hareket, action_ids taşıyan anim_* görevi (toplu
## alım, anim_batch_NN) hareket başına bir kayıttır. Metinden hareketler (motion_<anahtar> + motion_anim_<anahtar>)
## ayrıdır (motion_purchases): Meshy kütüphanesinin hareket numarası yoktur, kredi özetine (credit_summary) girmez.
##
## Kullanım:
##   var lib := ClipLibrary.new()
##   lib.resolve("father")                         # {"idle_3": {"source": "retarget", "donor": "mete", ...}, ...}
##   var anim := lib.build_clip("idle_3", "father", skeleton)   # oynamaya hazır Animation (döngü, yerinde)
##   lib.release()                                 # önbellekteki kaynak sahneleri bırakır (çağırmak gerekir:
##                                                 # ağaç dışındaki örnekler kendiliğinden silinmez)
## Ham GLB'ler (assets/_meshy_raw, .gdignore'lu) yalnız geliştirme ortamındadır: dışa aktarılmış oyunda yalnız oyun
## kaynaklarından (ana GLB, .res) gelen klipler kurulabilir.
##
## Oyun kaynakları: taşıyıcı kliplerinin kaynağı assets/animations/library/<key>.res, taşıyıcı iskelet
## assets/animations/donor/donor.glb (ikisini de tools/anim_library_import.gd üretir; ham GLB yalnız .res yoksa, geliştirmede,
## yedektir). Çeşitleri seçmek için: variants_in(grup), variant(anahtar) (seat, transition, contact, tags, weight),
## measure(anahtar) (süre, döngü, doğal hız, kalça yüksekliği; data/clip_library_measure.json). Oynamaya hazır klip:
##   var lib := ClipLibrary.shared()
##   var anim := lib.clip_for("father", "proud_strut", skeleton)   # kişi ve anahtar başına bir kez kurulur; ortak kaynak,
##   var pay := lib.ground_offset_for("father", "proud_strut")     # değiştirmeyin. pay: modelin dikey kaydırması (metre)
##
## Bacak düzeltmesi (fit_legs; tanımın leg_fit'i, kişinin ölçüsü clip_library_measure.json leg_fit): metinden hareketlerde ayak ve baldır
## zemindeyken kalça 9-15 cm havada, kimi bekleme klibinde bir ayak 3-6 cm havada kalır. Zemin payı bunu çözemez: bedenin bir yeri
## zemine inince öteki yeri gömülürdü. Klip kurulurken kalça ve (gerekirse) ayak bilekleri kişinin ölçüsü kadar indirilir, dizler iki
## kemikli çözümle yeniden kurulur; aktarımdan sonradır, kişinin kendi klibine de uygulanır. Kalça bacağı katlanma sınırına itecek kadar inmez,
## bilek zincirin sonuna yumuşak yaklaşır; yere dayanan el (leg_fit hands) kalçayla birlikte gömülmesin diye kol da çözülür; yatan bedenin zemine
## giren ayağı (leg_fit lie) kalkar: zemin payı sırta ve başa göredir (PoseFit.LYING_BONES), bacak aşağı eğimlidir.

const DEFINITION_PATH := "res://data/clip_library.json"
const CHARACTERS_ROOT := StandIn.ROOT
const RAW_ROOT := "res://assets/_meshy_raw"
const ASSET_PLAN_PATH := "res://tools/asset_plan.json"
## Taşıyıcı kliplerinin oyun kaynakları (<key>.res) ve taşıyıcı iskelet (tools/anim_library_import.gd üretir).
const LIBRARY_DIR := "res://assets/animations/library"
const DONOR_SCENE := "res://assets/animations/donor/donor.glb"
## Ham yedeğin taşıyıcı iskeleti (donor.glb bundan indirilir).
const RAW_DONOR_FILE := "donor_walking_armature.glb"
## Kliplerin ve karakterlerin ölçüleri (tools/anim_library_import.gd --measure yazar).
const MEASURE_PATH := "res://data/clip_library_measure.json"
## Türetilmiş klibin türü (kind): başka bir klipten 0 krediyle kurulur (derived: from, op, trim_start).
const KIND_DERIVED := "derived"
## flatten_hand: yere dayanan parmakların yataydan aşağı eğimi (derece).
const FLATTEN_TILT_DEG := 5.0
## close_loop: dikiş kapatılırken klibin son kaçta kaçı ilk kareye çekilir.
const LOOP_CLOSE_SHARE := 0.25
## Geçişte bacak düzeltmesinin söndüğü kalça yüksekliği (metre): yerdeki uçtan bu kadar yükselince düzeltme biter.
const LEG_FIT_FADE_M := 0.3
## Bacak düzeltmesinde kalça-bilek uzaklığının zincire oranı bundan aşağı inmez: katlanma sınırında kalça-bilek çizgisi yön değiştirince diz
## savrulur (2026-11-07, stand_up_3: oran 0,16, sol diz beş karede 34 cm; kaynakta 0,27 ve 17 cm).
const LEG_FIT_MIN_FOLD := 0.25
## Kalça inişi bu sınıra değdiği yerde eğri kaç saniyelik çevreyle yumuşatılır (_smooth_below): kalça sınırın önünde yavaşça yükselir.
const LEG_FIT_ROOM_SMOOTH_S := 0.2
## Bacak düzeltmesinde bilek inerken bacağın zincire oranı buna yaklaşır, aşmaz: diz 1,7 cm'den az sapmaz (2026-11-07, sert 0,9995'te 22 kayıtta
## 0,8-1,3 cm). İstenen yere yetişmeyen bilek birkaç mm havada kalır.
const LEG_FIT_REACH_MAX := 0.999
## Geçişlerde bacak düzeltmesinin uygulandığı duruşlar (beden yerde).
const GROUND_STATES: Array[String] = ["sit_ground", "kneel"]
## Oyunun bağışçı tablosu: DONORS ve meta.json clip_donors (character_fit_tool.donors_of).
const FIT_TOOL := preload("res://scripts/character/character_fit_tool.gd")
const BODIES: Array[String] = ["male", "female", "child"]
## Taşıyıcı kliplerinin CharacterAvatar rolleri (idle, walk, run, sit) dışındaki kuralları (apply_clip_rules): geçişler
## (oturmaya, ayağa kalkmaya), konuşma, uyku ve iş.
const EXTRA_ROLES: Array[String] = ["sit_down", "stand_up", "talk", "sleep", "work"]
## Kaynak türleri (resolve).
const NATIVE := "native"
const NATIVE_RAW := "native_raw"
const RETARGET := "retarget"
const MISSING := "missing"
## Kişinin kendi kaynağının türü (native_sources): oyunun dosyası (ana GLB ya da .res) ya da satın alınmış ham GLB.
const KIND_GAME := "game"
const KIND_RAW := "raw"
## İki klip bu açıdan (radyan) az ayrışıyorsa aynı klip sayılır. Aynı hareketin iki yüklemesi ≈ 0,001 ayrışır
## (kayan nokta); aynı hareketin başka iskeletten aktarımı ≈ 0,04 (Mete'nin oturması: kendi 363'ü ve Baba'dan aktarım; K92
## öncesi ≈ 0,6).
const SAME_CLIP_TOLERANCE := 0.01
## Omuz pişirmesinde birebirlik payı: konum (iskelet birimi) ve ölçek farkı.
const BAKE_POSITION_TOLERANCE := 0.001
const BAKE_SCALE_TOLERANCE := 0.0001

## Oyunun ortak kütüphanesi (shared): clip_for'un önbelleği kişiler arasında paylaşılsın.
static var _shared: ClipLibrary = null

## Kütüphane tanımı (clip_library.json).
var definition: Dictionary = {}
var _clips := {}
var _plan := {}
var _plan_loaded := false
var _natives := {}
var _games := {}
var _models: Array = []
var _models_loaded := false
## verify_game_clip'in veriyle düzelttiği .res kayıtları: {id: {rol: NATIVE|RETARGET}}.
var _res_overrides := {}
## resolve sonuçları ("id|modeli olanlar" → çözüm); kayıt düzelince (verify_game_clip) boşalır.
var _resolved := {}
## Örneklenmiş kaynak sahneler (yol → kök düğüm); release() bırakır.
var _scenes := {}
## Klip kurulurken kişinin bacak düzeltmesi uygulansın mı (ölçüm aracı düzeltmesiz klibi ölçer).
var use_leg_fit := true
## clip_for sonuçları ("kişi|anahtar" → Animation).
var _clip_cache := {}
## Ham yedekten kurulan taşıyıcı klipleri (anahtar → Animation); yalnız .res yoksa dolar.
var _raw_clips := {}
## data/clip_library_measure.json (ilk okumada yüklenir).
var _measure_data: Variant = null


func _init(def: Dictionary = {}) -> void:
	definition = def if not def.is_empty() else ClipLibrary.load_definition()
	for spec in definition.get("clips", []):
		if spec is Dictionary:
			_clips[str(spec.get("key", ""))] = spec


## Oyunun ortak kütüphanesi: her karakterin ayrı örnek açması clip_for'un önbelleğini boşa çıkarır. Kurulan klipler kalır;
## kaynak sahneleri bırakmak için kurulumdan sonra release().
static func shared() -> ClipLibrary:
	if _shared == null:
		_shared = ClipLibrary.new()
	return _shared


## Kütüphane tanımını okur (yoksa ya da bozuksa boş sözlük).
static func load_definition(path: String = DEFINITION_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[clip_library] tanım yok: %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("[clip_library] %s okunamadı: %s (satır %d)" % [path, json.get_error_message(), json.get_error_line()])
		return {}
	if not (json.data is Dictionary) or not ((json.data as Dictionary).get("clips") is Array):
		push_error("[clip_library] %s: \"clips\" listesi yok" % path)
		return {}
	return json.data


## Silinirken kaynak sahneleri bırakır (ağaç dışındaki düğümler kendiliğinden silinmez). Bu bildirimde kendi yöntemleri
## çağrılamaz: release() burada yinelenir.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for path in _scenes:
			if is_instance_valid(_scenes[path]):
				(_scenes[path] as Node).free()


# --- Tanım ------------------------------------------------------------------------------------------

## Kütüphanedeki klip anahtarları (tanımdaki sırayla).
func clip_keys() -> PackedStringArray:
	var out := PackedStringArray()
	for spec in definition.get("clips", []):
		if spec is Dictionary:
			out.append(str(spec.get("key", "")))
	return out


## Klibin tanımı (yoksa boş).
func clip(key: String) -> Dictionary:
	return _clips.get(key, {})


## Klibin CharacterAvatar rolü (idle, walk, run, sit; yoksa boş).
func role_of(key: String) -> String:
	return str(clip(key).get("role", ""))


## Bir role ait oyun klibi anahtarları (tanımdaki sırayla). Taşıyıcı klipleri sayılmaz: bu liste oyunun rol çözümü
## içindir (karakterin kendi .res'inin ve bağışçının klibinin anahtarı).
func keys_for_role(role: String) -> PackedStringArray:
	var out := PackedStringArray()
	for key in clip_keys():
		if role_of(key) == role and carrier_of(key).is_empty():
			out.append(key)
	return out


## Klibin taşıyıcısı (taşıyıcı klibi değilse boş).
func carrier_of(key: String) -> String:
	return str(clip(key).get("carrier", ""))


## Bir taşıyıcının (boşsa bütün taşıyıcıların) klip anahtarları, tanımdaki sırayla.
func carrier_keys(carrier_id: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	for key in clip_keys():
		var c := carrier_of(key)
		if not c.is_empty() and (carrier_id.is_empty() or c == carrier_id):
			out.append(key)
	return out


## Tanımdaki taşıyıcılar (kimlikler).
func carrier_ids() -> Array:
	var carriers: Variant = definition.get("carriers")
	return (carriers as Dictionary).keys() if carriers is Dictionary else []


## Taşıyıcının tanımı (yoksa boş).
func carrier(id: String) -> Dictionary:
	var carriers: Variant = definition.get("carriers")
	if carriers is Dictionary and (carriers as Dictionary).get(id) is Dictionary:
		return carriers[id]
	return {}


func is_carrier(id: String) -> bool:
	return not carrier(id).is_empty()


## Kişinin ya da taşıyıcının assets/_meshy_raw altındaki klasörü.
func raw_dir(id: String) -> String:
	var dir := str(carrier(id).get("dir", ""))
	return dir if not dir.is_empty() else id


## Taşıyıcının bir GLB'sinin mutlak yolu (klasör .gdignore'lu: GLTFDocument ile okunur).
func carrier_file_path(id: String, file: String) -> String:
	return ProjectSettings.globalize_path(RAW_ROOT.path_join(raw_dir(id)).path_join(file))


## Meshy hareket numarasının klip anahtarı (kütüphanede yoksa boş).
func key_for_action(action: int) -> String:
	for key in clip_keys():
		var value: Variant = clip(key).get("meshy_action")
		if value != null and int(value) == action:
			return key
	return ""


## Kişinin bedeni: "male", "female", "child" (kütüphanede yoksa boş).
func body_of(id: String) -> String:
	return str(_character(id).get("body", ""))


## Kişinin belge sitesindeki öbeği: "player", "named" ya da "crowd".
func group_of(id: String) -> String:
	var group := str(_character(id).get("group", ""))
	if not group.is_empty():
		return group
	return "crowd" if id.begins_with("crowd_") else "named"


## Kişinin görünen Türkçe adı: kütüphanedeki, yoksa meta.json'daki, o da yoksa kimliği.
func name_of(id: String) -> String:
	var tr := str(_character(id).get("tr", ""))
	if tr.is_empty():
		tr = str(StandIn.meta(id).get("name", ""))
	return tr if not tr.is_empty() else id


## Kütüphanenin kişileri (tanımdaki sırayla).
func character_ids() -> Array:
	var chars: Variant = definition.get("characters")
	return (chars as Dictionary).keys() if chars is Dictionary else []


func _character(id: String) -> Dictionary:
	var chars: Variant = definition.get("characters")
	if chars is Dictionary and (chars as Dictionary).get(id) is Dictionary:
		return chars[id]
	return {}


# --- Kayıtlar (asset_plan.json, meta.json, meshy.json) ------------------------------------------------------

## Modeli (assets/characters/<id>/<id>.glb) olan kişiler, abecesel.
func characters_with_models() -> Array:
	if not _models_loaded:
		_models_loaded = true
		var dirs := Array(DirAccess.get_directories_at(CHARACTERS_ROOT))
		dirs.sort()
		for id in dirs:
			if StandIn.has_model(str(id)):
				_models.append(str(id))
	return _models


## Kişinin asset_plan.json satırı (yoksa boş).
func plan_row(id: String) -> Dictionary:
	if not _plan_loaded:
		_plan_loaded = true
		var data: Variant = ClipLibrary.read_json(ASSET_PLAN_PATH)
		if data is Dictionary:
			for row in (data as Dictionary).get("assets", []):
				if row is Dictionary:
					_plan[str(row.get("id", ""))] = row
	return _plan.get(id, {})


## Kişinin kendisi için alınmış Meshy hareketleri (tanımın characters.<id>.own_actions; ilki ana GLB'nin klibidir).
func own_actions(id: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	for action in _character(id).get("own_actions", []):
		out.append(int(action))
	return out


## Kişinin ya da taşıyıcının meshy.json görevleri (assets/_meshy_raw/<klasör>/meshy.json → tasks; yoksa boş).
func meshy_tasks(id: String) -> Dictionary:
	var data: Variant = ClipLibrary.read_json(RAW_ROOT.path_join(raw_dir(id)).path_join("meshy.json"))
	if data is Dictionary and (data as Dictionary).get("tasks") is Dictionary:
		return data["tasks"]
	return {}


## Kişinin (ya da taşıyıcının) Meshy hareket alımları: actions_from_tasks biçiminde.
func meshy_actions(id: String) -> Array:
	return ClipLibrary.actions_from_tasks(id, meshy_tasks(id))


## Kişinin (ya da taşıyıcının) metinden hareket alımları: motions_from_tasks biçiminde.
func motion_purchases(id: String) -> Array:
	return ClipLibrary.motions_from_tasks(id, meshy_tasks(id))


## meshy.json görevlerinden hareket alımları (saf): [{character, action, status, credits, task, order}]. anim_<n> görevi
## tek harekettir; action_ids taşıyan anim_* görevi (toplu alım, ör. anim_batch_01) hareket başına bir kayıttır: kredisi
## eşit bölünür (kalan ilk kayıtlara), order hareketin görevdeki sırasıdır. Hareket numarası bulunamayan anim_* görevi
## uyarıyla atlanır (kredisi özete giremez; sessizce kaybolmasın).
static func actions_from_tasks(id: String, tasks: Dictionary) -> Array:
	var out := []
	for name in tasks:
		var task_name := str(name)
		if not task_name.begins_with("anim_") or not (tasks[name] is Dictionary):
			continue
		var task: Dictionary = tasks[name]
		var actions := []
		var ids: Variant = task.get("action_ids")
		if ids is Array:
			actions = ids
		elif task_name.trim_prefix("anim_").is_valid_int():
			actions = [task_name.trim_prefix("anim_").to_int()]
		if actions.is_empty():
			push_warning("[clip_library] %s/%s: hareket numarası yok (ne anim_<n> adı ne action_ids); kredi özetine girmedi" % [id, task_name])
			continue
		var credits := ClipLibrary.task_credits(task)
		var share := credits / actions.size()
		var rest := credits % actions.size()
		for i in actions.size():
			out.append({
				"character": id,
				"action": int(actions[i]),
				"status": str(task.get("status", "")),
				"credits": share + (1 if i < rest else 0),
				"task": str(task.get("id")) if task.get("id") != null else "",
				"order": i,
			})
	return out


## meshy.json görevlerinden metinden hareket alımları (saf): [{character, motion, status, credits, task}]. Bir hareket
## iki görevdir: motion_<anahtar> (text-to-motion, hareketi üretir) ve motion_anim_<anahtar> (iskelete uygular); kredi
## ikisinin toplamı, ikisi de başarılıysa SUCCEEDED (değilse ilk başarısız görevin durumu). task uygulama görevinin
## kimliğidir (yoksa üretiminki). Görev kimliğine göre sıralı.
static func motions_from_tasks(id: String, tasks: Dictionary) -> Array:
	var out := []
	for name in tasks:
		var task_name := str(name)
		if not task_name.begins_with("motion_") or task_name.begins_with("motion_anim_") or not (tasks[name] is Dictionary):
			continue
		var motion := task_name.trim_prefix("motion_")
		var made: Dictionary = tasks[name]
		var applied := {}
		if tasks.get("motion_anim_" + motion) is Dictionary:
			applied = tasks["motion_anim_" + motion]
		var status := str(made.get("status", ""))
		if status == "SUCCEEDED":
			status = str(applied.get("status", "")) if not applied.is_empty() else "NOT_APPLIED"
		var task: Variant = applied.get("id") if not applied.is_empty() else made.get("id")
		out.append({
			"character": id,
			"motion": motion,
			"status": status,
			"credits": ClipLibrary.task_credits(made) + ClipLibrary.task_credits(applied),
			"task": str(task) if task != null else "",
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["task"]) < str(b["task"]))
	return out


## Görevin harcadığı kredi (consumed_credits; yoksa 0).
static func task_credits(task: Dictionary) -> int:
	return int(task.get("consumed_credits")) if task.get("consumed_credits") != null else 0


## Bütün Meshy hareket alımları (kişiler ve taşıyıcılar), görev kimliğine, toplu alımda görevdeki sıraya göre sıralı
## (Meshy kimlikleri zaman sıralıdır, UUIDv7: ilk alım önce gelir).
func all_purchases() -> Array:
	var out := []
	for id in _raw_ids():
		out.append_array(meshy_actions(id))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["task"]) < str(b["task"]) or (str(a["task"]) == str(b["task"]) and int(a.get("order", 0)) < int(b.get("order", 0))))
	return out


## Bütün metinden hareket alımları (kişiler ve taşıyıcılar), görev kimliğine göre sıralı.
func all_motion_purchases() -> Array:
	var out := []
	for id in _raw_ids():
		out.append_array(motion_purchases(id))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["task"]) < str(b["task"]))
	return out


## assets/_meshy_raw altındaki klasörlerin sahipleri (taşıyıcının klasörü taşıyıcının kimliğine çevrilir), abecesel.
func _raw_ids() -> Array:
	var by_dir := {}
	for id in carrier_ids():
		by_dir[raw_dir(str(id))] = str(id)
	var out := []
	var dirs := Array(DirAccess.get_directories_at(RAW_ROOT))
	dirs.sort()
	for dir in dirs:
		out.append(by_dir.get(str(dir), str(dir)))
	return out


## Kredi özeti (saf): records all_purchases biçiminde ve sıralı (Meshy kütüphanesinin hareket alımları; toplu alım
## hareket başına bir kayıttır, metinden hareketler girmez). spent_on_actions bütün kayıtların kredisi, purchases başarılı
## alım sayısı, distinct_actions farklı hareket sayısı, duplicate_credits bir hareketin ilk alımı dışındaki alımların
## kredisi (K90'a göre gereksiz harcama; toplu alımdaki tekrar da sayılır).
static func credit_summary(records: Array) -> Dictionary:
	var spent := 0
	var purchases := 0
	var duplicate := 0
	var seen := {}
	for r in records:
		spent += int(r.get("credits", 0))
		if str(r.get("status", "")) != "SUCCEEDED":
			continue
		purchases += 1
		var action := int(r.get("action", -1))
		if seen.has(action):
			duplicate += int(r.get("credits", 0))
		else:
			seen[action] = true
	return {"spent_on_actions": spent, "purchases": purchases, "distinct_actions": seen.size(), "duplicate_credits": duplicate}


## <id>_<rol>.res yolu.
static func res_path(id: String, role: String) -> String:
	return CHARACTERS_ROOT.path_join(id).path_join("%s_%s.res" % [id, role])


## Satın alınmış ham hareket GLB'sinin mutlak yolu (klasör .gdignore'lu: içe aktarılmaz, GLTFDocument ile okunur).
static func raw_clip_path(id: String, action: int) -> String:
	return ProjectSettings.globalize_path(RAW_ROOT.path_join(id).path_join("%s_animation_%d.glb" % [id, action]))


## <id>_<rol>.res'in kaynağı (saf). listed: meta.json extra_clips'te yazılı mı; has_record: meta.json'da extra_clips
## kaydı var mı; donors: kişinin bağışçı tablosu. Dönüş: NATIVE (kişinin kendi klibi), RETARGET (bağışçıdan) ya da
## boş (bilinmiyor). Kayıt bağışçı tablosundan önce gelir: kişinin hareketi sonradan kendisi için de alınıp
## prepare_character.py ile çıkarıldıysa tablodaki eski bağışçı geçersizdir (ör. Mete'nin oturması: DONORS'ta Baba,
## dosya ise Mete'nin kendi 363'ü).
static func res_provenance(role: String, listed: bool, has_record: bool, donors: Dictionary) -> String:
	if listed:
		return NATIVE
	if donors.has(role):
		return RETARGET
	if not has_record and (role == "walk" or role == "run"):
		return NATIVE
	return ""


# --- Kaynaklar ve çözüm -----------------------------------------------------------------------------------

## Sınamalar için: kişinin kendi kaynaklarını (native_sources biçimi) elle verir; dosyalara bakılmaz.
func set_native_sources(id: String, sources: Dictionary) -> void:
	_natives[id] = sources
	_resolved.clear()


## Sınamalar için: oyunun kişi için oynattığı klipleri (game_clips biçimi) elle verir.
func set_game_clips(id: String, clips: Dictionary) -> void:
	_games[id] = clips
	_resolved.clear()


## Kişinin kendi klipleri: {anahtar: {kind: "game"|"raw", path, role, action?, clip?}}. "game": oyunun dosyası (ana
## GLB'nin klibi ya da kişinin kendi <id>_<rol>.res'i); "raw": satın alınmış, oyunda kullanılmayan ham GLB. Bağışçıdan
## aktarılmış .res buraya girmez (kişinin kendi klibi değildir). Taşıyıcının kaynakları onun klipleridir: alımı
## başarılı ve GLB'si yerinde olanlar; clip GLB'deki animasyonun adıdır (toplu alımın GLB'sinde on klip vardır).
func native_sources(id: String) -> Dictionary:
	if _natives.has(id):
		return _natives[id]
	if is_carrier(id):
		_natives[id] = _carrier_sources(id)
		return _natives[id]
	var out := {}
	var actions := own_actions(id)
	if StandIn.has_model(id):
		if not actions.is_empty():
			var key := key_for_action(actions[0])
			if not key.is_empty():
				out[key] = {"kind": KIND_GAME, "path": StandIn.model_path(id), "role": role_of(key)}
		var record := _res_record(id)
		for role in record:
			if record[role] != NATIVE:
				continue
			var key := _own_res_key(id, role, actions)
			if not key.is_empty() and not out.has(key):
				out[key] = {"kind": KIND_GAME, "path": ClipLibrary.res_path(id, role), "role": role}
	for purchase in meshy_actions(id):
		if purchase["status"] != "SUCCEEDED":
			continue
		var key := key_for_action(purchase["action"])
		var path := ClipLibrary.raw_clip_path(id, purchase["action"])
		if key.is_empty() or out.has(key) or not FileAccess.file_exists(path):
			continue
		out[key] = {"kind": KIND_RAW, "path": path, "role": role_of(key), "action": purchase["action"]}
	_natives[id] = out
	return out


func _carrier_sources(id: String) -> Dictionary:
	var out := {}
	var raw_keys := []
	for key in carrier_keys(id):
		var resource := str(clip(key).get("resource", ""))
		if not resource.is_empty() and ResourceLoader.exists(resource):
			out[key] = {"kind": KIND_GAME, "path": resource, "role": role_of(key)}
		else:
			raw_keys.append(key)
	if raw_keys.is_empty():
		return out
	# Oyun kaynağı henüz yoksa (geliştirme): alımı başarılı ve GLB'si yerinde olan ham klipler.
	var bought := {}
	for p in meshy_actions(id):
		if p["status"] == "SUCCEEDED":
			bought[int(p["action"])] = true
	var made := {}
	for m in motion_purchases(id):
		if m["status"] == "SUCCEEDED":
			made[str(m["motion"])] = true
	for key in raw_keys:
		var spec := clip(key)
		var action: Variant = spec.get("meshy_action")
		var motion: Variant = spec.get("motion")
		var paid: bool = made.has(str(motion)) if motion != null else (action != null and bought.has(int(action)))
		var path := carrier_file_path(id, str(spec.get("file", "")))
		if not paid or str(spec.get("file", "")).is_empty() or not FileAccess.file_exists(path):
			continue
		out[key] = {"kind": KIND_RAW, "path": path, "role": role_of(key), "clip": str(spec.get("meshy_name", ""))}
		if action != null:
			out[key]["action"] = int(action)
	return out


## Oyunun (CharacterAvatar) kişi için oynattığı klipler: {anahtar: {role, source, donor, path, ambiguous}}. Ana GLB'nin
## klibi, üstüne <id>_<rol>.res'ler (aynı rolü ezer; CharacterAvatar._add_extra_clips gibi). ambiguous: .res
## meta.json'da kişinin kendi klibi diye yazılı ama rolü bağışçı tablosunda da var (verify_game_clip ayırt eder).
func game_clips(id: String) -> Dictionary:
	if _games.has(id):
		return _games[id]
	var by_role := {}
	if StandIn.has_model(id):
		var actions := own_actions(id)
		if not actions.is_empty():
			var key := key_for_action(actions[0])
			if not key.is_empty():
				by_role[role_of(key)] = {"key": key, "source": NATIVE, "donor": null, "path": StandIn.model_path(id), "ambiguous": false}
		var donors := FIT_TOOL.donors_of(id)
		var record := _res_record(id)
		for role in record:
			var key := ""
			var donor: Variant = null
			if record[role] == NATIVE:
				key = _own_res_key(id, role, actions)
			else:
				donor = str(donors[role])
				key = _donor_role_key(str(donor), role)
			if not key.is_empty():
				by_role[role] = {"key": key, "source": record[role], "donor": donor, "path": ClipLibrary.res_path(id, role),
					"ambiguous": record[role] == NATIVE and donors.has(role)}
	var out := {}
	for role in by_role:
		var info: Dictionary = by_role[role]
		info["role"] = role
		out[info["key"]] = info
	_games[id] = out
	return out


## Klibin kişiye hangi bağışçıdan aktarılacağı: taşıyıcı klibinde taşıyıcının kendisi (klibi yerindeyse); öteki
## kliplerde kişinin bedenine göre kütüphanedeki bağışçı; o yoksa, modeli yoksa ya da klip onda kendi klibi değilse
## öteki bedenlerin bağışçıları, sonra klibi kendinde olan herhangi bir kişi (abecesel). Kişi kendine bağışçı olmaz;
## aktarılmış bir klip yeniden aktarılmaz (bağışçının kendi klibi olmalı). available: modeli olan kişiler (boşsa diske
## bakılır). Bulunamazsa boş.
func donor_for(key: String, target_id: String, available: Array = []) -> String:
	var spec := clip(key)
	if spec.is_empty():
		return ""
	var holder := carrier_of(key)
	if not holder.is_empty() and holder != target_id and native_sources(holder).has(key):
		return holder
	var pool: Array = available if not available.is_empty() else characters_with_models()
	var order: Array[String] = []
	var donors: Variant = spec.get("donors")
	if donors is Dictionary:
		var own_body := str((donors as Dictionary).get(body_of(target_id), ""))
		if not own_body.is_empty():
			order.append(own_body)
		for body in BODIES:
			var d := str((donors as Dictionary).get(body, ""))
			if not d.is_empty() and not order.has(d):
				order.append(d)
	var others := pool.duplicate()
	others.sort()
	for id in others:
		if not order.has(str(id)):
			order.append(str(id))
	for id in order:
		if id == target_id or not pool.has(id):
			continue
		if native_sources(id).has(key):
			return id
	return ""


## Kişinin bütün kliplerinin kaynağı: {anahtar: {source, donor, game_role, role, path}}. source: "native" (kişinin
## oyundaki kendi klibi), "native_raw" (satın alınmış ham GLB), "retarget" (donor'dan aktarılır), "missing".
## game_role: klip oyunun o rol için oynattığı klip mi. path: kaynak dosya (aktarımda oyunun aktarılmış .res'i ya da
## boş). available: modeli olan kişiler (boşsa diske bakılır). Sonuç önbelleklidir (aynı sözlük döner: değiştirmeyin).
func resolve(id: String, available: Array = []) -> Dictionary:
	var cache_key := "%s|%s" % [id, ",".join(PackedStringArray(available))]
	if _resolved.has(cache_key):
		return _resolved[cache_key]
	var natives := native_sources(id)
	var game := game_clips(id)
	var out := {}
	for key in clip_keys():
		var entry := {"source": MISSING, "donor": null, "game_role": false, "role": role_of(key), "path": ""}
		if game.has(key):
			var g: Dictionary = game[key]
			entry["source"] = g["source"]
			entry["donor"] = g["donor"]
			entry["game_role"] = true
			entry["path"] = g["path"]
		elif natives.has(key):
			var n: Dictionary = natives[key]
			entry["source"] = NATIVE if n["kind"] == KIND_GAME else NATIVE_RAW
			entry["path"] = n["path"]
		else:
			var donor := donor_for(key, id, available)
			if not donor.is_empty():
				entry["source"] = RETARGET
				entry["donor"] = donor
		out[key] = entry
	_resolved[cache_key] = out
	return out


## Oyunun .res klibini (game_clips) kişinin aynı hareketteki ham alımıyla karşılaştırır ve kaydı veriyle düzeltir:
## aynıysa kişinin kendi klibidir ("native"), değilse ve rol bağışçı tablosundaysa bağışçıdan aktarılmıştır
## ("retarget"). Kayıtlar (meta.json, DONORS) çeliştiğinde (ambiguous) dışa aktarma aracı bununla doğrular. Ham alım
## yoksa ya da klip .res değilse kayıt olduğu gibi kalır. Dönüş: {checked, difference (radyan), source}.
func verify_game_clip(id: String, key: String) -> Dictionary:
	var info: Dictionary = game_clips(id).get(key, {})
	var result := {"checked": false, "difference": INF, "source": info.get("source", MISSING)}
	var action: Variant = clip(key).get("meshy_action")
	if info.is_empty() or action == null or str(info["path"]).get_extension() != "res":
		return result
	var raw := ClipLibrary.raw_clip_path(id, int(action))
	var bought := meshy_actions(id).any(func(p: Dictionary) -> bool: return p["action"] == int(action) and p["status"] == "SUCCEEDED")
	if not bought or not FileAccess.file_exists(raw):
		return result
	var game_src := _load_source(id, str(info["path"]), str(info["role"]))
	var raw_src := _load_source(id, raw, str(info["role"]))
	if game_src.is_empty() or raw_src.is_empty():
		return result
	var difference := ClipLibrary.max_rotation_difference(game_src["anim"], raw_src["anim"])
	var role := str(info["role"])
	var verdict := NATIVE if difference <= SAME_CLIP_TOLERANCE else RETARGET
	if verdict == RETARGET and not FIT_TOOL.donors_of(id).has(role):
		verdict = str(info["source"])
	if verdict != info["source"]:
		if not _res_overrides.has(id):
			_res_overrides[id] = {}
		_res_overrides[id][role] = verdict
		_natives.erase(id)
		_games.erase(id)
		_resolved.clear()
	result["checked"] = true
	result["difference"] = difference
	result["source"] = verdict
	return result


## <id>_<rol>.res kayıtları: {rol: NATIVE|RETARGET} (yalnız var olan dosyalar; kaynağı bilinmeyen atlanır).
func _res_record(id: String) -> Dictionary:
	var out := {}
	var extra: Variant = StandIn.meta(id).get("extra_clips")
	var donors := FIT_TOOL.donors_of(id)
	var overrides: Dictionary = _res_overrides.get(id, {})
	for role_name in CharacterAvatar.ROLES:
		var role := String(role_name)
		var path := ClipLibrary.res_path(id, role)
		if not ResourceLoader.exists(path):
			continue
		var listed := extra is Dictionary and str((extra as Dictionary).get(role, "")) == path.get_file()
		var source := ClipLibrary.res_provenance(role, listed, extra is Dictionary, donors)
		source = str(overrides.get(role, source))
		if not source.is_empty():
			out[role] = source
	return out


## Kişinin kendi .res klibinin anahtarı: yürüme ve koşma kendi adlarıyla; öteki roller asset_plan'daki kalan planlı
## hareketlerden o roldeki (prepare_character.py böyle çıkarır). Planda yoksa kişinin o roldeki başarılı alımı (ana
## GLB'ninki hariç), o da yoksa rolün kütüphanedeki tek klibi.
func _own_res_key(id: String, role: String, actions: PackedInt32Array) -> String:
	var keys := keys_for_role(role)
	if role == "walk" or role == "run":
		return keys[0] if not keys.is_empty() else ""
	for i in range(1, actions.size()):
		var key := key_for_action(actions[i])
		if not key.is_empty() and role_of(key) == role:
			return key
	for purchase in meshy_actions(id):
		var key := key_for_action(purchase["action"])
		if purchase["status"] == "SUCCEEDED" and role_of(key) == role and (actions.is_empty() or purchase["action"] != actions[0]):
			return key
	return keys[0] if keys.size() == 1 else ""


## Bağışçının o roldeki klibinin anahtarı: character_fit_tool.gd bağışçının ana GLB klibini aktarır.
func _donor_role_key(donor: String, role: String) -> String:
	var actions := own_actions(donor)
	if not actions.is_empty():
		var key := key_for_action(actions[0])
		if role_of(key) == role:
			return key
	for key in native_sources(donor):
		if role_of(key) == role:
			return key
	var keys := keys_for_role(role)
	return keys[0] if not keys.is_empty() else ""


# --- Çeşitler ve ölçüler ----------------------------------------------------------------------------------

## Bir grubun (idle_loop, idle_fidget, walk, run, sit_chair, sit_ground, sit_down, stand_up, talk, sleep, work) klip
## anahtarları, tanımdaki sırayla. Grup bilinmiyorsa boş.
func variants_in(group: String) -> Array:
	var out := []
	for key in clip_keys():
		if str(clip(key).get("group", "")) == group:
			out.append(key)
	return out


## Çeşidin tanımı (clip gibi: resource, seat, transition, contact, tags, weight, loop...; yoksa boş). Değiştirmeyin.
func variant(key: String) -> Dictionary:
	return clip(key)


## Klibin ölçüleri (data/clip_library_measure.json clips; alanlar orada anlatılır). Ölçülmemişse boş.
func measure(key: String) -> Dictionary:
	var clips: Variant = _measures().get("clips")
	if clips is Dictionary and (clips as Dictionary).get(key) is Dictionary:
		return clips[key]
	return {}


## Modelin bu klipte zemin payı (metre; CharacterAvatar gibi model bu kadar yukarı kaydırılır). Ölçülmemişse oyunun rol payı
## (<id>_fit.json), o da yoksa 0.
func ground_offset_for(model_id: String, key: String) -> float:
	var table: Variant = _model_measures(model_id).get("offset")
	if table is Dictionary and (table as Dictionary).has(key):
		return float(table[key])
	return CharacterAvatar.fit_value(CharacterAvatar._load_fit(model_id), "ground_offset", StringName(role_of(key)), 0.0)


## Geçişin iki ucunun zemin payı: x ilk karede, y son karede (o anki duruşun temas kemikleriyle). Geçiş değilse iki değer de
## ground_offset_for.
func ground_offset_ends(model_id: String, key: String) -> Vector2:
	var table: Variant = _model_measures(model_id).get("ends")
	if table is Dictionary and (table as Dictionary).get(key) is Array:
		return Vector2(float(table[key][0]), float(table[key][1]))
	var whole := ground_offset_for(model_id, key)
	return Vector2(whole, whole)


## Oturuşta kalça ekleminin bu kişide zeminden yüksekliği (metre; oturağın yüksekliği için). Ölçülmemişse taşıyıcınınki
## (kalça ortalaması), o da yoksa 0.
func hips_height_for(model_id: String, key: String) -> float:
	var table: Variant = _model_measures(model_id).get("hips_m")
	if table is Dictionary and (table as Dictionary).has(key):
		return float(table[key])
	var hips: Variant = measure(key).get("hips_m")
	return float((hips as Dictionary).get("mean", 0.0)) if hips is Dictionary else 0.0


## Yerde oturuşta ve yere inen geçişte bedenin zeminden boşluğu (metre; oturuşta kalça, PoseFit.seat_min_y; zemin payı ve bacak düzeltmesi
## uygulanmış). Kişi ölçülmemişse kadronun en kötüsü (clips.<anahtar>.seat_gap_max), o da yoksa 0 (diz çökerek oturuş ölçülmez).
func seat_gap_for(model_id: String, key: String) -> float:
	var table: Variant = _model_measures(model_id).get("seat_gap_m")
	if table is Dictionary and (table as Dictionary).has(key):
		return float(table[key])
	return float(measure(key).get("seat_gap_max", 0.0))


## Bekleme ve kıpırdanmada iki ayağın zeminden boşluğu (metre; x sol, y sağ; klip boyunca en alçak anı). Ölçülmemişse sıfır.
func foot_gap_for(model_id: String, key: String) -> Vector2:
	var table: Variant = _model_measures(model_id).get("foot_gap_m")
	if table is Dictionary and (table as Dictionary).get(key) is Array:
		return Vector2(float(table[key][0]), float(table[key][1]))
	return Vector2.ZERO


## Kişinin bu klipteki bacak düzeltmesi ({hips, left, right}: metre; fit_legs). Gerekmiyorsa boş.
func leg_fit_for(model_id: String, key: String) -> Dictionary:
	var table: Variant = _model_measures(model_id).get("leg_fit")
	if table is Dictionary and (table as Dictionary).get(key) is Dictionary:
		return table[key]
	return {}


## Geçişin ilk karesinde kökün yatay konumu (metre; x ve z, model uzayı). Bekleme klibinden geçişi oynatacak sahne kişinin düğümünü bu
## kadar öne alır (ya da kökü bu kadar kaydırır), yoksa kişi geçişin başında kayar: rev_stand_up_10'da 55 cm. Ölçülmemişse taşıyıcınınki,
## o da yoksa sıfır.
func root_start_for(model_id: String, key: String) -> Vector2:
	var table: Variant = _model_measures(model_id).get("root_start_m")
	var value: Variant = (table as Dictionary).get(key) if table is Dictionary else null
	if not value is Array:
		value = measure(key).get("root_start_m")
	return Vector2(float(value[0]), float(value[1])) if value is Array else Vector2.ZERO


## Yürüme ve koşma çeşidinin bu kişideki doğal hızı (m/sn; ayaklar kaymasın diye oynatma hızı buna göre ayarlanır).
## Ölçülmemişse taşıyıcınınki, o da yoksa 0.
func speed_for(model_id: String, key: String) -> float:
	var table: Variant = _model_measures(model_id).get("speed_mps")
	if table is Dictionary and (table as Dictionary).has(key):
		return float(table[key])
	return float(measure(key).get("speed_mps", 0.0))


## Zemin payının temas kemikleri (tanımın contact'ı; yoksa PoseFit.CONTACT_BONES).
func contact_for(key: String) -> Array[String]:
	return PoseFit.contact_list(clip(key).get("contact"))


## Bir duruşun (states: stand, sit_chair, sit_ground, kneel...) temas kemikleri; bilinmiyorsa PoseFit.CONTACT_BONES.
func contact_for_state(state: String) -> Array[String]:
	var states: Variant = definition.get("states")
	if states is Dictionary and (states as Dictionary).get(state) is Dictionary:
		return PoseFit.contact_list(states[state].get("contact"))
	return PoseFit.CONTACT_BONES


func _measures() -> Dictionary:
	if _measure_data == null:
		var data: Variant = ClipLibrary.read_json(MEASURE_PATH)
		_measure_data = data if data is Dictionary else {}
	return _measure_data


func _model_measures(model_id: String) -> Dictionary:
	var models: Variant = _measures().get("models")
	if models is Dictionary and (models as Dictionary).get(model_id) is Dictionary:
		return models[model_id]
	return {}


# --- Oyun kaynakları ------------------------------------------------------------------------------------------

## <key>.res yolu.
static func resource_path_of(key: String) -> String:
	return LIBRARY_DIR.path_join(key + ".res")


## Taşıyıcı klibi, taşıyıcı iskelet için (oyun kaynağı; yoksa, geliştirmede, ham GLB'den). Ortak kaynak: değiştirmeyin.
## Taşıyıcı klibi değilse ya da bulunamazsa null.
func library_clip(key: String) -> Animation:
	var spec := clip(key)
	if carrier_of(key).is_empty():
		return null
	var resource := str(spec.get("resource", ""))
	if not resource.is_empty() and ResourceLoader.exists(resource):
		return load(resource) as Animation
	if _raw_clips.has(key):
		return _raw_clips[key]
	var anim: Animation = null
	if str(spec.get("kind", "")) == KIND_DERIVED:
		var info: Dictionary = spec.get("derived", {})
		var parent := library_clip(str(info.get("from", "")))
		anim = ClipLibrary.derive_clip(parent, info) if parent else null
	else:
		var source: Dictionary = native_sources(carrier_of(key)).get(key, {})
		var src := _load_source(carrier_of(key), str(source.get("path", "")), str(source.get("role", "")), str(source.get("clip", ""))) if not source.is_empty() else {}
		if not src.is_empty():
			anim = (src["anim"] as Animation).duplicate(true)
			ClipLibrary.apply_pose_fix(anim, src["skeleton"], spec.get("pose_fix"))
	if anim:
		anim.resource_name = key
		_raw_clips[key] = anim
	return anim


## Taşıyıcı iskelet (önbellekli; release() bırakır): assets/animations/donor/donor.glb, yoksa, geliştirmede, ham GLB'si.
func donor_skeleton() -> Skeleton3D:
	var path := DONOR_SCENE
	if not ResourceLoader.exists(path):
		var carriers := carrier_ids()
		path = carrier_file_path(str(carriers[0]), RAW_DONOR_FILE) if not carriers.is_empty() else ""
	return ClipLibrary.find_skeleton(_scene_root(path)) if not path.is_empty() else null


## Kişinin klibi, oynamaya hazır (kişi ve anahtar başına bir kez kurulur; ortak kaynak, değiştirmeyin). Kaynak ve kurallar
## build_clip'tir: taşıyıcı klibi ClipRetarget (DIRECTION) ile aktarılır; oturma dışındaki döngülü klip yerinde oynar;
## geçiş ve tek seferlik klipler (tanımda loop false) döngüsüzdür ve kök hareketini korur. İz yolları hedef iskeletin
## sahibine göredir (modelin kökü). Kurulamazsa null.
func clip_for(model_id: String, key: String, target_skeleton: Skeleton3D) -> Animation:
	var cache_key := "%s|%s" % [model_id, key]
	if _clip_cache.has(cache_key):
		return _clip_cache[cache_key]
	if target_skeleton == null:
		return null
	var prefix := String(target_skeleton.owner.get_path_to(target_skeleton)) if target_skeleton.owner else ""
	var anim := build_clip(key, model_id, target_skeleton, [], prefix)
	if anim:
		_clip_cache[cache_key] = anim
	return anim


## Türetilmiş klibi ana klibinden kurar (derived: {from, op, trim_start}). Bilinmeyen işlemde null.
static func derive_clip(parent: Animation, info: Dictionary) -> Animation:
	if str(info.get("op", "")) == "reverse":
		return ClipLibrary.reverse_clip(parent, float(info.get("trim_start", 0.0)))
	push_error("[clip_library] bilinmeyen türetme: %s" % info)
	return null


## Klibi ters oynatan yeni klip: ilk karesi ana klibin son karesi, son karesi ana klibin trim_start anı (0: ilk karesi). Her
## izin anahtarları ters sırayla yazılır, uçlara ana klibin o andaki değeri eklenir. Bir kez oynar.
static func reverse_clip(anim: Animation, trim_start: float = 0.0) -> Animation:
	var out := Animation.new()
	var end := anim.length
	var start := clampf(trim_start, 0.0, end)
	out.length = end - start
	out.loop_mode = Animation.LOOP_NONE
	for t in anim.get_track_count():
		var type := anim.track_get_type(t)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var r := out.add_track(type)
		out.track_set_path(r, anim.track_get_path(t))
		out.track_set_interpolation_type(r, anim.track_get_interpolation_type(t))
		var times := PackedFloat64Array([end])
		for k in range(anim.track_get_key_count(t) - 1, -1, -1):
			var time := anim.track_get_key_time(t, k)
			if time > start + 0.00001 and time < end - 0.00001:
				times.append(time)
		times.append(start)
		for time in times:
			out.track_insert_key(r, end - time, ClipLibrary._track_value(anim, t, type, time))
	return out


## Tanımın pose_fix'ini klibe işler: {"trim_start": saniye} klibin başını, {"trim_end": saniye} sonunu keser; {"flatten_hand": ["LeftHand",
## ...], "lift_wrist": iskelet birimi} yere dayanan eli yatırır. Yoksa dokunmaz.
static func apply_pose_fix(anim: Animation, skel: Skeleton3D, fix: Variant) -> void:
	if not fix is Dictionary:
		return
	var spec: Dictionary = fix
	if spec.has("trim_end"):
		ClipLibrary.trim_clip_end(anim, float(spec["trim_end"]))
	if spec.has("trim_start"):
		ClipLibrary.trim_clip_start(anim, float(spec["trim_start"]))
	for bone in spec.get("flatten_hand", []):
		ClipLibrary.flatten_hand(anim, skel, str(bone), float(spec.get("lift_wrist", 0.0)))


## Klibin başını keser (yerinde): yeni ilk kare eski start anı; anahtarlar öne çekilir, uzunluk kısalır.
static func trim_clip_start(anim: Animation, start: float) -> void:
	var cut := clampf(start, 0.0, anim.length)
	for t in anim.get_track_count():
		var type := anim.track_get_type(t)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var keys := [[0.0, ClipLibrary._track_value(anim, t, type, cut)]]
		for k in anim.track_get_key_count(t):
			var time := anim.track_get_key_time(t, k)
			if time > cut + 0.00001:
				keys.append([time - cut, anim.track_get_key_value(t, k)])
		for k in range(anim.track_get_key_count(t) - 1, -1, -1):
			anim.track_remove_key(t, k)
		for key: Array in keys:
			anim.track_insert_key(t, key[0], key[1])
	anim.length -= cut


## Klibin sonunu keser (yerinde): yeni son kare eski end anı.
static func trim_clip_end(anim: Animation, end: float) -> void:
	var cut := clampf(end, 0.0, anim.length)
	for t in anim.get_track_count():
		var type := anim.track_get_type(t)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var last: Variant = ClipLibrary._track_value(anim, t, type, cut)
		for k in range(anim.track_get_key_count(t) - 1, -1, -1):
			if anim.track_get_key_time(t, k) >= cut - 0.00001:
				anim.track_remove_key(t, k)
		anim.track_insert_key(t, cut, last)
	anim.length = cut


static func _track_value(anim: Animation, t: int, type: int, time: float) -> Variant:
	match type:
		Animation.TYPE_POSITION_3D:
			return anim.position_track_interpolate(t, time)
		Animation.TYPE_ROTATION_3D:
			return anim.rotation_track_interpolate(t, time).normalized()
		_:
			return anim.scale_track_interpolate(t, time)


## Yere dayanan eli yere yatırır: Meshy'nin el kemiği bileğe bağlı tek parçadır; metinden üretilen hareket kolu düz indirince
## parmak uçları bileğin 18-20 cm altına iner, bilek de kalçanın altında kalır ve el zemine gömülür. Her karede önce kol,
## omuz çevresinde dışa açılarak bileği lift_wrist kadar (iskelet birimi) yükseltir (kol boyu değişmez), sonra el, bilek
## çevresinde, parmaklar kalçadan dışa ve neredeyse yatay duracak kadar döndürülür (bilek bükülür, avuç yere bakar). El ve
## kolun izi yoksa (klip eli dinlenme pozunda bırakır) kalçanın anahtar anlarında kurulur. Kemikler ya da kalçanın dönüş izi
## yoksa false.
static func flatten_hand(anim: Animation, skel: Skeleton3D, bone_name: String, lift_wrist: float = 0.0) -> bool:
	var bone := skel.find_bone(bone_name)
	var hips := skel.find_bone("Hips")
	var forearm := skel.get_bone_parent(bone) if bone >= 0 else -1
	var arm := skel.get_bone_parent(forearm) if forearm >= 0 else -1
	var shoulder := skel.get_bone_parent(arm) if arm >= 0 else -1
	var prefix := ClipRetarget.track_prefix(anim)
	var clock := anim.find_track(NodePath("%s:Hips" % prefix), Animation.TYPE_ROTATION_3D)
	if bone < 0 or hips < 0 or shoulder < 0 or clock < 0:
		return false
	var rest := ClipRetarget.rest_rotations(skel)
	var rest_inverse: Quaternion = ClipRetarget.global_rotations(skel, rest)[bone].inverse()
	var points := ClipRetarget.rest_points(skel)
	var fingers := (points[bone] - points[forearm]).normalized()
	var tilt := deg_to_rad(FLATTEN_TILT_DEG)
	var times := PackedFloat64Array()
	for k in anim.track_get_key_count(clock):
		times.append(anim.track_get_key_time(clock, k))
	var arm_values: Array[Quaternion] = []
	var hand_values: Array[Quaternion] = []
	for t in times:
		var local := ClipRetarget.local_rotations_at(anim, skel, rest, prefix, t)
		var global := ClipRetarget.global_rotations(skel, local)
		var pose := ClipRetarget.pose_points(skel, local, global, anim, prefix, t)
		var outward := pose[bone] - pose[hips]
		outward.y = 0.0
		outward = outward.normalized()
		var reach := pose[bone] - pose[arm]
		var opened := ClipRetarget.shortest_arc(reach, ClipLibrary._lifted_reach(reach, outward, lift_wrist))
		arm_values.append((global[shoulder].inverse() * (opened * global[arm])).normalized())
		var hand_global := opened * global[bone]
		var want := outward * cos(tilt) + Vector3.DOWN * sin(tilt)
		var turn := ClipRetarget.shortest_arc((hand_global * rest_inverse) * fingers, want)
		hand_values.append(((opened * global[forearm]).inverse() * (turn * hand_global)).normalized())
	if lift_wrist > 0.0:
		ClipLibrary._replace_rotation_track(anim, NodePath("%s:%s" % [prefix, skel.get_bone_name(arm)]), times, arm_values)
	ClipLibrary._replace_rotation_track(anim, NodePath("%s:%s" % [prefix, bone_name]), times, hand_values)
	return true


## Omuzdan bileğe uzanan yön, boyu aynı, dışa açılarak ucu height kadar yükselmiş (ikiye bölme; yükselemiyorsa olabildiğince).
static func _lifted_reach(reach: Vector3, outward: Vector3, height: float) -> Vector3:
	if height <= 0.0:
		return reach
	var want := reach.y + height
	var low := 0.0
	var high := reach.length() * 4.0
	for i in 24:
		var middle := (low + high) * 0.5
		if (reach + outward * middle).normalized().y * reach.length() < want:
			low = middle
		else:
			high = middle
	return (reach + outward * high).normalized() * reach.length()


static func _replace_rotation_track(anim: Animation, path: NodePath, times: PackedFloat64Array, values: Array[Quaternion]) -> void:
	var old := anim.find_track(path, Animation.TYPE_ROTATION_3D)
	if old >= 0:
		anim.remove_track(old)
	var track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(track, path)
	for i in times.size():
		anim.rotation_track_insert_key(track, times[i], values[i])


static func _replace_position_track(anim: Animation, path: NodePath, times: PackedFloat64Array, values: PackedVector3Array) -> void:
	var old := anim.find_track(path, Animation.TYPE_POSITION_3D)
	if old >= 0:
		anim.remove_track(old)
	var track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track, path)
	for i in times.size():
		anim.position_track_insert_key(track, times[i], values[i])


# --- Klip kurma -----------------------------------------------------------------------------------------

## Kişinin klibini kurar: kendi klibi (oyun dosyası ya da ham GLB) kopyalanır; oyunun aktarılmış .res'i olduğu gibi
## alınır; öteki aktarımlar bağışçının (ya da taşıyıcının) kendi klibinden ClipRetarget ile yapılır. Sonra
## CharacterAvatar'ın kuralları uygulanır (apply_clip_rules), kişinin bacak düzeltmesi işlenir (fit_legs) ve klibin adı anahtarı olur. prefix verilirse izlerin düğüm
## yolu ona çevrilir (ör. "Armature/Skeleton3D"). Kurulamazsa null.
func build_clip(key: String, target_id: String, target: Skeleton3D, available: Array = [], prefix: String = "") -> Animation:
	if clip(key).is_empty():
		push_error("[clip_library] kütüphanede böyle bir klip yok: %s" % key)
		return null
	var entry: Dictionary = resolve(target_id, available)[key]
	var anim: Animation = null
	match str(entry["source"]):
		NATIVE, NATIVE_RAW:
			var own: Dictionary = native_sources(target_id).get(key, {})
			var src := _load_source(target_id, str(entry["path"]), str(entry["role"]), str(own.get("clip", "")))
			anim = (src["anim"] as Animation).duplicate(true) if not src.is_empty() else null
		RETARGET:
			if entry["game_role"]:
				var res := load(str(entry["path"])) as Animation
				anim = res.duplicate(true) if res else null
			else:
				anim = retarget_from(key, str(entry["donor"]), target, target_id)
	if anim == null:
		push_warning("[clip_library] %s/%s kurulamadı (%s)" % [target_id, key, entry["source"]])
		return null
	if not prefix.is_empty():
		ClipLibrary.set_track_prefix(anim, prefix)
	ClipLibrary.apply_clip_rules(anim, role_of(key), bool(clip(key).get("loop", true)), clip(key).has("transition"))
	if use_leg_fit:
		ClipLibrary.fit_legs(anim, target, leg_fit_for(target_id, key), ClipLibrary.seat_end_of(clip(key)))
	ClipLibrary.complete_rest_tracks(anim, target)
	anim.resource_name = key
	return anim


## Bağışçının (ya da taşıyıcının) kendi klibini (key) hedef iskelete aktarır (ClipRetarget, varsayılan yöntem). Kurallar
## (döngü, yerinde) uygulanmaz; build_clip uygular. Bağışçıda klip yoksa null.
func retarget_from(key: String, donor_id: String, target: Skeleton3D, target_id: String) -> Animation:
	var source: Dictionary = native_sources(donor_id).get(key, {})
	if source.is_empty() or target == null:
		return null
	var src := _load_source(donor_id, str(source["path"]), str(source["role"]), str(source.get("clip", "")))
	if src.is_empty():
		return null
	return ClipRetarget.retarget(src["anim"], src["skeleton"], target, ClipRetarget.Mode.DIRECTION, ClipRetarget.DEFAULT_FPS, ClipRetarget.LIMB_KEYS, donor_id, target_id)


## Önbellekteki kaynak sahneleri bırakır (taşıyıcı iskelet dahil; clip_for'un kurduğu klipler kalır).
func release() -> void:
	for path in _scenes:
		if is_instance_valid(_scenes[path]):
			(_scenes[path] as Node).free()
	_scenes.clear()


## CharacterAvatar'ın klip kuralları (_load_meshy gibi): oturma dışındaki her klip yerinde oynar (kök kayması silinir) ve
## döngülüdür, dikişi kapatılır (close_loop); oturma ilk ve son pozu aynıysa (is_cyclic: nefes döngüsü) döngülü, değilse son
## karesinde durur. loop false olan klip (tanımda döngüsüz; oturma rolünde de) bir kez oynar. Geçiş (transition true ya da
## sit_down, stand_up rolü: oturmaya geçiş, ayağa kalkma gibi) kök hareketini korur; öteki tek seferlik klipler (iş, selam,
## kıpırdanma) yerinde oynar.
static func apply_clip_rules(anim: Animation, role: String, loop: bool = true, transition: bool = false) -> void:
	if role == "sit":
		anim.loop_mode = Animation.LOOP_LINEAR if loop and CharacterAvatar.is_cyclic(anim) else Animation.LOOP_NONE
	elif not loop:
		anim.loop_mode = Animation.LOOP_NONE
		if not transition and role != "sit_down" and role != "stand_up":
			CharacterAvatar.make_in_place(anim)
	else:
		anim.loop_mode = Animation.LOOP_LINEAR
		CharacterAvatar.make_in_place(anim)
		ClipLibrary.close_loop(anim)


## Döngünün dikişini kapatır: ilk ve son karesi ayrışan klipte (CharacterAvatar.is_cyclic değil; Meshy'nin yürüme ve koşma
## kliplerinin çoğu 4-37 derece ayrışır) her izin son bölümü, klibin share kadarında, ilk karesine doğru yumuşakça çekilir;
## son kare ilk kareyle aynı olur. Yapıldıysa true.
static func close_loop(anim: Animation, share: float = LOOP_CLOSE_SHARE) -> bool:
	if CharacterAvatar.is_cyclic(anim):
		return false
	var span := maxf(anim.length * share, 0.0001)
	for t in anim.get_track_count():
		var count := anim.track_get_key_count(t)
		if count < 2:
			continue
		var type := anim.track_get_type(t)
		var end := anim.track_get_key_time(t, count - 1)
		if type == Animation.TYPE_ROTATION_3D:
			var first: Quaternion = (anim.track_get_key_value(t, 0) as Quaternion).normalized()
			var last: Quaternion = (anim.track_get_key_value(t, count - 1) as Quaternion).normalized()
			var delta := (first * last.inverse()).normalized()
			for k in count:
				var s := clampf((anim.track_get_key_time(t, k) - end + span) / span, 0.0, 1.0)
				if s > 0.0:
					var eased := s * s * (3.0 - 2.0 * s)
					anim.track_set_key_value(t, k, (Quaternion.IDENTITY.slerp(delta, eased) * (anim.track_get_key_value(t, k) as Quaternion)).normalized())
		elif type == Animation.TYPE_POSITION_3D:
			var gap: Vector3 = (anim.track_get_key_value(t, 0) as Vector3) - (anim.track_get_key_value(t, count - 1) as Vector3)
			for k in count:
				var s := clampf((anim.track_get_key_time(t, k) - end + span) / span, 0.0, 1.0)
				if s > 0.0:
					anim.track_set_key_value(t, k, (anim.track_get_key_value(t, k) as Vector3) + gap * (s * s * (3.0 - 2.0 * s)))
	return true


## Geçişin yerdeki ucu: 1 son kare (yere iner), 0 ilk kare (yerden kalkar), -1 geçiş değil ya da beden yere inmiyor (saf).
static func seat_end_of(spec: Dictionary) -> int:
	var transition: Variant = spec.get("transition")
	if not transition is Dictionary:
		return -1
	if GROUND_STATES.has(str(transition.get("to"))):
		return 1
	if GROUND_STATES.has(str(transition.get("from"))):
		return 0
	return -1


## Klibin bacaklarını kişinin ölçüsüne göre düzeltir (yerinde): kalça hips metre, ayak bilekleri left ve right metre iner (fit: {hips,
## left, right, hand_left, hand_right}; dünyanın yukarısı modelin kökünden okunur). Ayak bileği kalça inse de yerinde kalır, ayağın yönü
## değişmez, diz iki kemikli çözümle kurulur ve bükülme yönü klipten gelir: oturan bedenin üstü iner, bacak altında toplanır. Kalça, bacak
## zincirin LEG_FIT_MIN_FOLD'undan çok katlanacak kadar inmez (_hip_room; klip orada zaten katlıysa o karede inmez). Bilek uzarken zincirin
## sonuna yumuşak yaklaşır, diz dümdüz kilitlenmez (_fit_reach). Geçişte seat_end yerdeki ucu verir (seat_end_of): düzeltme orada tamdır,
## kalça LEG_FIT_FADE_M yükselince söner; ayakta uç değişmez. hand_left ya da hand_right yazılıysa o kol da çözülür (yere dayanan el, leg_fit
## hands): kalça inse de bilek yerinde kalır, üstüne o kadar metre yükselir (eksi: iner), elin yönü değişmez. lift_left ve lift_right (leg_fit lie)
## bileğin klip boyunca kalkışıdır: eşit aralıklı örnekler (metre), ilki ilk kare, sonuncusu son kare; yatan bedenin ayağı zemine girmez. Kalçanın konumu ve değişen
## kemiklerin dönüş izleri ClipRetarget.DEFAULT_FPS ile yeniden yazılır, kök kemik Hips değilse ya da zincir eksikse klip değişmez. Yaptıysa true.
static func fit_legs(anim: Animation, skel: Skeleton3D, fit: Dictionary, seat_end: int = -1) -> bool:
	var hips_m := float(fit.get("hips", 0.0))
	var drops := {"Left": float(fit.get("left", 0.0)), "Right": float(fit.get("right", 0.0))}
	var ankle_lifts := {"Left": fit.get("lift_left", []), "Right": fit.get("lift_right", [])}
	var lifts := {}
	if fit.has("hand_left"):
		lifts["Left"] = float(fit["hand_left"])
	if fit.has("hand_right"):
		lifts["Right"] = float(fit["hand_right"])
	var hips := skel.find_bone("Hips")
	if hips < 0 or skel.get_bone_parent(hips) >= 0 or (is_zero_approx(hips_m) and is_zero_approx(drops["Left"]) and is_zero_approx(drops["Right"]) and lifts.is_empty() and (ankle_lifts["Left"] as Array).is_empty() and (ankle_lifts["Right"] as Array).is_empty()):
		return false
	var prefix := ClipRetarget.track_prefix(anim)
	var chains := []
	for side: String in drops:
		var chain := {"side": side, "drop": drops[side], "lift": ankle_lifts[side], "keys": [[], [], []]}
		for bone_name: String in [side + "UpLeg", side + "Leg", side + "Foot"]:
			if skel.find_bone(bone_name) < 0:
				return false
		chain["bones"] = [_LegBone.new(anim, skel, prefix, side + "UpLeg"), _LegBone.new(anim, skel, prefix, side + "Leg"), _LegBone.new(anim, skel, prefix, side + "Foot")]
		chains.append(chain)
	var arms := []
	for side: String in lifts:
		var arm := ClipLibrary._arm_chain(anim, skel, prefix, side, lifts[side])
		if arm.is_empty():
			return false
		arms.append(arm)
	var root := _LegBone.new(anim, skel, prefix, "Hips")
	# İskelet uzayında bir metre yukarı (Meshy iskeletinde 100 birim).
	var up := PoseFit.relative_transform(skel.owner as Node3D, skel).basis.inverse() * Vector3.UP
	var up_unit := up.normalized()
	var times := PackedFloat64Array(Array(ClipRetarget.sample_times(anim.length, ClipRetarget.DEFAULT_FPS)))
	var seat_height := root.position_at(times[times.size() - 1 if seat_end == 1 else 0]).dot(up_unit)
	var weights := PackedFloat32Array()
	var rooms := PackedFloat32Array()
	for time in times:
		var position := root.position_at(time)
		var weight := 1.0
		if seat_end >= 0:
			weight = clampf(1.0 - (position.dot(up_unit) - seat_height) / (LEG_FIT_FADE_M * up.length()), 0.0, 1.0)
		weights.append(weight)
		var room := hips_m
		if hips_m > 0.0:
			for chain: Dictionary in chains:
				room = minf(room, ClipLibrary._hip_room(chain, time, position, root.rotation_at(time), ClipLibrary._ankle_drop(chain, up, weight, time / anim.length), up_unit) / up.length())
		rooms.append(room)
	rooms = ClipLibrary._smooth_below(rooms, ceili(LEG_FIT_ROOM_SMOOTH_S * ClipRetarget.DEFAULT_FPS))
	var positions := PackedVector3Array()
	var last_pole := {}
	for i in times.size():
		var time := times[i]
		var position := root.position_at(time)
		var turn := root.rotation_at(time)
		var moved := position - up * minf(hips_m * weights[i], rooms[i])
		positions.append(moved)
		for chain: Dictionary in chains:
			ClipLibrary._fit_leg_at(chain, time, position, moved, turn, ClipLibrary._ankle_drop(chain, up, weights[i], time / anim.length), last_pole)
		for arm: Dictionary in arms:
			ClipLibrary._fit_arm_at(arm, time, position, moved, turn, up * float(arm["lift"]) * weights[i], last_pole)
	ClipLibrary._replace_position_track(anim, NodePath("%s:Hips" % prefix), times, positions)
	for chain: Dictionary in chains + arms:
		for i in 3:
			var values: Array[Quaternion] = []
			values.assign(chain["keys"][i])
			ClipLibrary._replace_rotation_track(anim, (chain["bones"][i] as _LegBone).path, times, values)
	return true


## Bileğin bu andaki inişi (iskelet uzayı): zincirin düzeltmesi geçişin ağırlığıyla, yatıştaki kalkışı (lift) klibin örneklerinden. share: klipteki yeri (0..1).
static func _ankle_drop(chain: Dictionary, up: Vector3, weight: float, share: float) -> Vector3:
	return up * (float(chain["drop"]) * weight - ClipLibrary._curve_at(chain["lift"], share))


## Eşit aralıklı örneklerin share (0..1) anındaki değeri (doğrusal; örnek yoksa 0).
static func _curve_at(values: Array, share: float) -> float:
	if values.is_empty():
		return 0.0
	if values.size() == 1:
		return float(values[0])
	var at := clampf(share, 0.0, 1.0) * (values.size() - 1)
	var low := mini(int(at), values.size() - 2)
	return lerpf(float(values[low]), float(values[low + 1]), at - low)


## Kalçanın bu anda en çok ne kadar inebileceği (iskelet birimi): bilek yerinde kalırken bacak zincirin LEG_FIT_MIN_FOLD'undan çok
## katlanmasın. Klip orada zaten daha katlıysa 0; kalça bilekten uzaklaşıyorsa ya da bileğin yanından geçiyorsa sınır yok (INF).
static func _hip_room(chain: Dictionary, time: float, root_position: Vector3, root_turn: Quaternion, ankle_drop: Vector3, up_unit: Vector3) -> float:
	var bones: Array = chain["bones"]
	var up_global := root_turn * (bones[0] as _LegBone).rotation_at(time)
	var leg_global := up_global * (bones[1] as _LegBone).rotation_at(time)
	var thigh_offset := (bones[1] as _LegBone).position_at(time)
	var shin_offset := (bones[2] as _LegBone).position_at(time)
	var hip := root_position + root_turn * (bones[0] as _LegBone).position_at(time)
	var goal := hip + up_global * thigh_offset + leg_global * shin_offset - ankle_drop
	var limit := (thigh_offset.length() + shin_offset.length()) * LEG_FIT_MIN_FOLD
	var from_goal := hip - goal
	if from_goal.length() <= limit:
		return 0.0
	var height := from_goal.dot(up_unit)
	var side_squared := from_goal.length_squared() - height * height
	if height <= 0.0 or side_squared >= limit * limit:
		return INF
	return height - sqrt(limit * limit - side_squared)


## Eğriyi yumuşatır, hiçbir yerde kendini aşmadan: önce radius kadar çevrenin en küçüğü, sonra aynı çevrenin ortalaması. Her örnek,
## kendisini aşmayan değerlerin ortalamasıdır; düz giden eğri (sınır hiç değmiyorsa) olduğu gibi kalır.
static func _smooth_below(values: PackedFloat32Array, radius: int) -> PackedFloat32Array:
	var count := values.size()
	var lows := PackedFloat32Array()
	lows.resize(count)
	for i in count:
		var low := INF
		for j in range(maxi(i - radius, 0), mini(i + radius + 1, count)):
			low = minf(low, values[j])
		lows[i] = low
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var total := 0.0
		var first := maxi(i - radius, 0)
		var end := mini(i + radius + 1, count)
		for j in range(first, end):
			total += lows[j]
		out[i] = total / float(end - first)
	return out


## Zincirin (bacak, kol) yeni uzanımı. Kısalan zincir istenen yere tam gider. Uzayan zincir, klipteki uzanımından devam ederek
## LEG_FIT_REACH_MAX'a ClipRetarget._soft_reach ile yaklaşır: aktarımın yumuşattığı bacak ikinci kez yumuşamaz, yerinde kalan bilek oynamaz; diz ve
## dirsek dümdüz kilitlenmez, kilide girerken sıçramaz.
static func _fit_reach(wanted: float, old: float, reach: float) -> float:
	if wanted <= old:
		return wanted
	var limit := reach * LEG_FIT_REACH_MAX
	if old >= limit:
		return old
	return ClipRetarget._soft_reach(ClipRetarget._soft_reach_inverse(old, limit) + wanted - old, limit)


## Bir bacağın bir anı: eski pozdan kalça, diz ve bilek; yeni kalçadan indirilmiş bileğe iki kemikli çözüm. Yerel dönüşler zincirin
## keys'ine eklenir.
static func _fit_leg_at(chain: Dictionary, time: float, old_root: Vector3, new_root: Vector3, root_turn: Quaternion, ankle_drop: Vector3, last_pole: Dictionary) -> void:
	var bones: Array = chain["bones"]
	var up_bone: _LegBone = bones[0]
	var leg_bone: _LegBone = bones[1]
	var foot_bone: _LegBone = bones[2]
	var leg_local := leg_bone.rotation_at(time)
	var up_global := root_turn * up_bone.rotation_at(time)
	var leg_global := up_global * leg_local
	var foot_global := leg_global * foot_bone.rotation_at(time)
	var thigh_offset := leg_bone.position_at(time)
	var shin_offset := foot_bone.position_at(time)
	var hip_old := old_root + root_turn * up_bone.position_at(time)
	var knee_old := hip_old + up_global * thigh_offset
	var ankle_old := knee_old + leg_global * shin_offset
	var hip := hip_old + (new_root - old_root)
	var goal := ankle_old - ankle_drop
	var thigh := thigh_offset.length()
	var shin := shin_offset.length()
	var to_goal := goal - hip
	var distance := maxf(ClipLibrary._fit_reach(to_goal.length(), ankle_old.distance_to(hip_old), thigh + shin), absf(thigh - shin) * 1.001 + 0.001)
	var along := to_goal.normalized() if to_goal.length_squared() > 1e-8 else root_turn * Vector3.DOWN
	# Dizin bükülme yönü: eski dizin eski kalça-bilek çizgisinden sapması; bacak dümdüzse önceki an, o da yoksa bedenin önü.
	var old_line := (ankle_old - hip_old).normalized()
	var old_knee := knee_old - hip_old
	var pole := old_knee - old_line * old_knee.dot(old_line)
	if pole.length() < ClipRetarget.POLE_MIN:
		pole = last_pole.get(chain["side"], root_turn * Vector3.BACK)
	last_pole[chain["side"]] = pole
	pole = pole - along * pole.dot(along)
	pole = pole.normalized() if pole.length_squared() > 1e-8 else root_turn * Vector3.BACK
	var x := (thigh * thigh - shin * shin + distance * distance) / (2.0 * distance)
	var knee := hip + along * x + pole * sqrt(maxf(thigh * thigh - x * x, 0.0))
	var ankle := hip + along * distance
	var new_up := (ClipRetarget.shortest_arc(up_global * thigh_offset, knee - hip) * up_global).normalized()
	var carried := new_up * leg_local
	var new_leg := (ClipRetarget.shortest_arc(carried * shin_offset, ankle - knee) * carried).normalized()
	var keys: Array = chain["keys"]
	(keys[0] as Array).append((root_turn.inverse() * new_up).normalized())
	(keys[1] as Array).append((new_up.inverse() * new_leg).normalized())
	(keys[2] as Array).append((new_leg.inverse() * foot_global).normalized())


## Bir kolun zinciri (fit_legs; yere dayanan el): bones kol, ön kol, el; path kalçadan köprücüğe ara kemikler; lift bileğin yükselişi
## (metre). Kemikler eksikse boş.
static func _arm_chain(anim: Animation, skel: Skeleton3D, prefix: String, side: String, lift: float) -> Dictionary:
	for bone_name: String in [side + "Arm", side + "ForeArm", side + "Hand"]:
		if skel.find_bone(bone_name) < 0:
			return {}
	var path := []
	var bone := skel.get_bone_parent(skel.find_bone(side + "Arm"))
	while bone >= 0 and skel.get_bone_parent(bone) >= 0:
		path.push_front(_LegBone.new(anim, skel, prefix, skel.get_bone_name(bone)))
		bone = skel.get_bone_parent(bone)
	return {"side": "arm" + side, "lift": lift, "outward": 1.0 if side == "Left" else -1.0, "keys": [[], [], []], "path": path,
		"bones": [_LegBone.new(anim, skel, prefix, side + "Arm"), _LegBone.new(anim, skel, prefix, side + "ForeArm"), _LegBone.new(anim, skel, prefix, side + "Hand")]}


## Bir kolun bir anı: kalça indi, omuz onunla iner; bilek eski yerinde kalır, üstüne wrist_lift kadar yükselir; iki kemikli çözüm, dirseğin
## bükülme yönü klipten (kol dümdüzse önceki an, o da yoksa dışa ve arkaya). Elin dünyadaki yönü değişmez. Yerel dönüşler zincirin keys'ine eklenir.
static func _fit_arm_at(chain: Dictionary, time: float, old_root: Vector3, new_root: Vector3, root_turn: Quaternion, wrist_lift: Vector3, last_pole: Dictionary) -> void:
	var parent := root_turn
	var from_root := Vector3.ZERO
	for bone: _LegBone in chain["path"]:
		from_root += parent * bone.position_at(time)
		parent = (parent * bone.rotation_at(time)).normalized()
	var bones: Array = chain["bones"]
	var fore_local := (bones[1] as _LegBone).rotation_at(time)
	var arm_global := parent * (bones[0] as _LegBone).rotation_at(time)
	var fore_global := arm_global * fore_local
	var hand_global := fore_global * (bones[2] as _LegBone).rotation_at(time)
	var upper_offset := (bones[1] as _LegBone).position_at(time)
	var lower_offset := (bones[2] as _LegBone).position_at(time)
	var joint_from_root := from_root + parent * (bones[0] as _LegBone).position_at(time)
	var joint_old := old_root + joint_from_root
	var elbow_old := joint_old + arm_global * upper_offset
	var wrist_old := elbow_old + fore_global * lower_offset
	var joint := new_root + joint_from_root
	var to_goal := wrist_old + wrist_lift - joint
	var upper := upper_offset.length()
	var lower := lower_offset.length()
	var distance := maxf(ClipLibrary._fit_reach(to_goal.length(), wrist_old.distance_to(joint_old), upper + lower), absf(upper - lower) * 1.001 + 0.001)
	var along := to_goal.normalized() if to_goal.length_squared() > 1e-8 else root_turn * Vector3.DOWN
	var old_line := (wrist_old - joint_old).normalized()
	var old_elbow := elbow_old - joint_old
	var pole := old_elbow - old_line * old_elbow.dot(old_line)
	if pole.length() < ClipRetarget.POLE_MIN:
		pole = last_pole.get(chain["side"], root_turn * Vector3(float(chain["outward"]), 0.0, -1.0))
	last_pole[chain["side"]] = pole
	pole = pole - along * pole.dot(along)
	pole = pole.normalized() if pole.length_squared() > 1e-8 else root_turn * Vector3.BACK
	var x := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var elbow := joint + along * x + pole * sqrt(maxf(upper * upper - x * x, 0.0))
	var wrist := joint + along * distance
	var new_arm := (ClipRetarget.shortest_arc(arm_global * upper_offset, elbow - joint) * arm_global).normalized()
	var carried := new_arm * fore_local
	var new_fore := (ClipRetarget.shortest_arc(carried * lower_offset, wrist - elbow) * carried).normalized()
	var keys: Array = chain["keys"]
	(keys[0] as Array).append((parent.inverse() * new_arm).normalized())
	(keys[1] as Array).append((new_arm.inverse() * new_fore).normalized())
	(keys[2] as Array).append((new_fore.inverse() * hand_global).normalized())


## Bir kemiğin izleri (fit_legs): izi olmayan dönüş ve konum dinlenme pozundadır.
class _LegBone:
	var anim: Animation
	var path: NodePath
	var position_track := -1
	var rotation_track := -1
	var rest: Transform3D

	func _init(a: Animation, skel: Skeleton3D, prefix: String, bone_name: String) -> void:
		anim = a
		path = NodePath("%s:%s" % [prefix, bone_name])
		position_track = a.find_track(path, Animation.TYPE_POSITION_3D)
		rotation_track = a.find_track(path, Animation.TYPE_ROTATION_3D)
		rest = skel.get_bone_rest(skel.find_bone(bone_name))

	func position_at(time: float) -> Vector3:
		return anim.position_track_interpolate(position_track, time) if position_track >= 0 else rest.origin

	func rotation_at(time: float) -> Quaternion:
		return anim.rotation_track_interpolate(rotation_track, time).normalized() if rotation_track >= 0 else rest.basis.get_rotation_quaternion()


## Kök kemiğin (ebeveyni olmayan ilk kemik) konum izini delta kadar kaydırır (iskelet uzayı; ör. klibi zemine oturtmak
## için dikey pay). İz yoksa dinlenme konumundan iki anahtarla kurulur. Kaydırdıysa true.
static func shift_root(anim: Animation, skel: Skeleton3D, delta: Vector3) -> bool:
	if delta.is_zero_approx():
		return false
	var root_bone := -1
	for b in skel.get_bone_count():
		if skel.get_bone_parent(b) < 0:
			root_bone = b
			break
	if root_bone < 0:
		return false
	var path := NodePath("%s:%s" % [ClipRetarget.track_prefix(anim), skel.get_bone_name(root_bone)])
	var track := anim.find_track(path, Animation.TYPE_POSITION_3D)
	if track < 0:
		track = anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(track, path)
		var rest := skel.get_bone_rest(root_bone).origin
		anim.position_track_insert_key(track, 0.0, rest)
		if anim.length > 0.0:
			anim.position_track_insert_key(track, anim.length, rest)
	for k in anim.track_get_key_count(track):
		anim.track_set_key_value(track, k, (anim.track_get_key_value(track, k) as Vector3) + delta)
	return true


## Kemik izlerinin düğüm yolunu değiştirir (ör. "Armature/Skeleton3D:Head" → "<prefix>:Head").
static func set_track_prefix(anim: Animation, prefix: String) -> void:
	for t in anim.get_track_count():
		var path := anim.track_get_path(t)
		if path.get_subname_count() > 0:
			anim.track_set_path(t, NodePath("%s:%s" % [prefix, path.get_concatenated_subnames()]))


## Klipte izi olmayan kemiklere dinlenme pozunda sabit dönüş izi, kök kemiğe izi yoksa konum izi ekler. Godot'nun içe aktarıcısı dinlenmeye
## eşit izi siler; oynatıcı da web oynatıcısı (three.js) da izsiz kemikte önceki klibin pozunu bırakır: yürümeden Spine izi olmayan
## klibe geçince gövde 3-9° eğik kalıyordu. Uyluğun dönüş izi konumunu da korur: yeni iskeletlerin kendi yürüme ve koşmasında uyluğun konum izi vardır
## (0,4-1,7 cm), Godot kemiğin konum ve dönüşünü tek önbellekte uyguladığı için sonraki klipte konum dinlenmeye döner (web oynatıcısında dönmez:
## clip_library_export.gd complete_position_tracks). Eklenen iz sayısını döndürür.
static func complete_rest_tracks(anim: Animation, skel: Skeleton3D) -> int:
	var prefix := ClipRetarget.track_prefix(anim)
	var end := maxf(anim.length, 0.0)
	var added := 0
	for b in skel.get_bone_count():
		var path := NodePath("%s:%s" % [prefix, skel.get_bone_name(b)])
		var rest := skel.get_bone_rest(b)
		if anim.find_track(path, Animation.TYPE_ROTATION_3D) < 0:
			var t := anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(t, path)
			anim.rotation_track_insert_key(t, 0.0, rest.basis.get_rotation_quaternion())
			if end > 0.0:
				anim.rotation_track_insert_key(t, end, rest.basis.get_rotation_quaternion())
			added += 1
		if skel.get_bone_parent(b) < 0 and anim.find_track(path, Animation.TYPE_POSITION_3D) < 0:
			var p := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(p, path)
			anim.position_track_insert_key(p, 0.0, rest.origin)
			if end > 0.0:
				anim.position_track_insert_key(p, end, rest.origin)
			added += 1
	return added


## Klipteki farklı anahtar zamanlarının sayısı (örnek sayısı; 0,1 ms'ye yuvarlanır).
static func frame_count(anim: Animation) -> int:
	var times := {}
	for t in anim.get_track_count():
		for k in anim.track_get_key_count(t):
			times[roundi(anim.track_get_key_time(t, k) * 10000.0)] = true
	return times.size()


## İki klibin ortak dönüş izlerindeki en büyük açı farkı (radyan; samples eşit aralıklı anda). Ortak iz yoksa INF.
## Ara değerler birimlenerek karşılaştırılır (yakın anahtarlar arasında Godot'nun slerp'i birim olmayan sonuç verir).
static func max_rotation_difference(a: Animation, b: Animation, samples: int = 24) -> float:
	var worst := 0.0
	var common := 0
	var length := minf(a.length, b.length)
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
			continue
		var u := b.find_track(a.track_get_path(t), Animation.TYPE_ROTATION_3D)
		if u < 0:
			continue
		common += 1
		for i in samples:
			var time := length * i / float(maxi(samples - 1, 1))
			var qa: Quaternion = a.rotation_track_interpolate(t, time)
			var qb: Quaternion = b.rotation_track_interpolate(u, time)
			worst = maxf(worst, qa.normalized().angle_to(qb.normalized()))
	return worst if common > 0 else INF


# --- Omuz düzeltmesini pişirme ---------------------------------------------------------------------------

## Omuz düzeltmesini (ShoulderRelax) klibin karelerine pişirir. Her örnek anında iskeletin pozu klipten kurulur
## (izi olmayan kemik dinlenme pozunda), ShoulderRelax._process_modification'ın adımları aynen uygulanır (drop_rotation
## ile köprücük döner, kol global yönünü korur; Skeleton3D.set_bone_global_pose gibi yerel poza ayrıştırılır) ve
## köprücükle kolun yerel dönüşü ize yazılır. Örnek anları: köprücük, kol ve atalarının bütün anahtarları ile 1/fps
## ızgarası. Düzeltme yalnız bu iki kemiğin dönüşünü değiştirir; her anda konum ve ölçeğin değişmediği denetlenir
## (değişseydi yalnız dönüş izi yazmak birebir olmazdı: o zaman klip değişmeden kalır).
## up: iskelet uzayında yukarı (ShoulderRelax: skeleton.global_basis.inverse() * UP). Dönüş: {baked, reason, keys,
## between_deg}: between_deg iki örnek arasının ortasında pişmiş klibin gerçek düzeltmeden en büyük sapması (derece).
static func bake_shoulder_relax(anim: Animation, skel: Skeleton3D, up: Vector3, drop_deg: float, fps: float = ClipRetarget.DEFAULT_FPS) -> Dictionary:
	var result := {"baked": false, "reason": "", "keys": 0, "between_deg": 0.0}
	if drop_deg < 0.01:
		result["reason"] = "düzeltme açısı yok"
		return result
	var pairs: Array = []
	var chain := {}
	for pair: Array in ShoulderRelax.PAIRS:
		var c := skel.find_bone(str(pair[0]))
		var a := skel.find_bone(str(pair[1]))
		if c < 0 or a < 0 or skel.get_bone_parent(a) != c:
			result["reason"] = "%s/%s kemiği yok" % [pair[0], pair[1]]
			return result
		pairs.append([c, a])
		var x := a
		while x >= 0:
			chain[x] = true
			x = skel.get_bone_parent(x)
	for p in pairs:
		for q in pairs:
			if p != q and (chain_has_ancestor(skel, p[0], q[0]) or chain_has_ancestor(skel, q[0], p[0])):
				result["reason"] = "köprücükler iç içe"
				return result
	var prefix := ClipRetarget.track_prefix(anim)
	var sampler := _PoseSampler.new(anim, skel, prefix, chain.keys())
	var times := sampler.bake_times(fps)
	var angle := deg_to_rad(drop_deg)
	var keys := {}
	for p in pairs:
		keys[p[0]] = []
		keys[p[1]] = []
	for t in times:
		var pose := sampler.relaxed(pairs, up, angle, t)
		if pose.has("error"):
			result["reason"] = "%.3f sn: %s" % [t, pose["error"]]
			return result
		for b in pose:
			var list: Array = keys[b]
			var q: Quaternion = pose[b]
			if not list.is_empty() and (list[-1][1] as Quaternion).dot(q) < 0.0:
				q = -q
			list.append([t, q])
	# İki örnek arasının ortasında pişmiş klibin (küresel ara değer) gerçek düzeltmeden sapması. Çok yakın dörtlülerde
	# slerp doğrusal karışıma döner ve birim olmayan sonuç verir; angle_to'dan önce birimlenir.
	var between := 0.0
	for i in range(times.size() - 1):
		var mid := (times[i] + times[i + 1]) * 0.5
		var pose := sampler.relaxed(pairs, up, angle, mid)
		if pose.has("error"):
			continue
		for b in pose:
			var q0: Quaternion = keys[b][i][1]
			var q1: Quaternion = keys[b][i + 1][1]
			between = maxf(between, q0.slerp(q1, 0.5).normalized().angle_to((pose[b] as Quaternion).normalized()))
	for b in keys:
		var path := NodePath("%s:%s" % [prefix, skel.get_bone_name(b)])
		var track := anim.find_track(path, Animation.TYPE_ROTATION_3D)
		if track < 0:
			track = anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(track, path)
		for k in range(anim.track_get_key_count(track) - 1, -1, -1):
			anim.track_remove_key(track, k)
		for k: Array in keys[b]:
			anim.rotation_track_insert_key(track, k[0], k[1])
	result["baked"] = true
	result["keys"] = times.size()
	result["between_deg"] = rad_to_deg(between)
	return result


## ancestor, bone'un atası mı (ya da kendisi)?
static func chain_has_ancestor(skel: Skeleton3D, bone: int, ancestor: int) -> bool:
	var x := bone
	while x >= 0:
		if x == ancestor:
			return true
		x = skel.get_bone_parent(x)
	return false


## Bir klibin seçili kemiklerdeki pozunu herhangi bir anda kuran yardımcı (iz yoksa dinlenme pozu).
class _PoseSampler:
	var anim: Animation
	var skel: Skeleton3D
	var bones: Array
	var tracks := {}
	var rest := {}

	func _init(a: Animation, s: Skeleton3D, prefix: String, chain: Array) -> void:
		anim = a
		skel = s
		bones = chain.duplicate()
		# Ebeveyn çocuktan önce gelsin.
		bones.sort_custom(func(x: int, y: int) -> bool: return _depth(x) < _depth(y) or (_depth(x) == _depth(y) and x < y))
		for b in bones:
			var path := NodePath("%s:%s" % [prefix, skel.get_bone_name(b)])
			tracks[b] = [anim.find_track(path, Animation.TYPE_POSITION_3D), anim.find_track(path, Animation.TYPE_ROTATION_3D), anim.find_track(path, Animation.TYPE_SCALE_3D)]
			var r := skel.get_bone_rest(b)
			rest[b] = [r.origin, r.basis.get_rotation_quaternion(), r.basis.get_scale()]

	func _depth(b: int) -> int:
		var d := 0
		var x := skel.get_bone_parent(b)
		while x >= 0:
			d += 1
			x = skel.get_bone_parent(x)
		return d

	## Kemiğin t anındaki yerel pozu: [konum, dönüş, ölçek].
	func local(b: int, t: float) -> Array:
		var tr: Array = tracks[b]
		var parts: Array = (rest[b] as Array).duplicate()
		if tr[0] >= 0 and anim.track_get_key_count(tr[0]) > 0:
			parts[0] = anim.position_track_interpolate(tr[0], t)
		if tr[1] >= 0 and anim.track_get_key_count(tr[1]) > 0:
			parts[1] = anim.rotation_track_interpolate(tr[1], t)
		if tr[2] >= 0 and anim.track_get_key_count(tr[2]) > 0:
			parts[2] = anim.scale_track_interpolate(tr[2], t)
		return parts

	## Skeleton3D'nin poz önbelleği gibi: Basis(dönüş, ölçek) = R · S.
	static func compose(parts: Array) -> Transform3D:
		return Transform3D(Basis(parts[1] as Quaternion) * Basis.from_scale(parts[2]), parts[0])

	## Örnek anları: ilgili izlerin bütün anahtarları, 0, klibin sonu ve 1/fps ızgarası (en yakın anahtara çeyrek
	## adımdan yakın ızgara anı atlanır; 0,1 ms'den yakın anlar birleşir).
	func bake_times(fps: float) -> PackedFloat64Array:
		var found := {0.0: true, anim.length: true}
		for b in bones:
			for tr in tracks[b]:
				if tr < 0:
					continue
				for k in anim.track_get_key_count(tr):
					var time := anim.track_get_key_time(tr, k)
					if time >= 0.0 and time <= anim.length + 0.00001:
						found[minf(time, anim.length)] = true
		var keys: Array = found.keys()
		keys.sort()
		var all: Array = keys.duplicate()
		var step := 1.0 / maxf(fps, 1.0)
		var j := 0
		var i := 1
		while i * step < anim.length - step * 0.25:
			var g := i * step
			while j < keys.size() and float(keys[j]) < g:
				j += 1
			var near := INF
			if j < keys.size():
				near = float(keys[j]) - g
			if j > 0:
				near = minf(near, g - float(keys[j - 1]))
			if near > step * 0.25:
				all.append(g)
			i += 1
		all.sort()
		var out := PackedFloat64Array()
		for time in all:
			if out.is_empty() or float(time) - out[out.size() - 1] > 0.0001:
				out.append(time)
		return out

	## t anında ShoulderRelax uygulanmış köprücük ve kolların yerel dönüşleri {kemik: Quaternion}; birebirlik
	## bozulursa {"error": neden}.
	func relaxed(pairs: Array, up: Vector3, angle: float, t: float) -> Dictionary:
		var locals := {}
		var globals := {}
		for b in bones:
			var parts := local(b, t)
			locals[b] = parts
			var parent := skel.get_bone_parent(b)
			var own := compose(parts)
			globals[b] = (globals[parent] as Transform3D) * own if parent >= 0 else own
		var out := {}
		for p in pairs:
			var c: int = p[0]
			var a: int = p[1]
			var cg: Transform3D = globals[c]
			var ag: Transform3D = globals[a]
			var turn := ShoulderRelax.drop_rotation(ag.origin - cg.origin, up, angle)
			var parent := skel.get_bone_parent(c)
			var pg: Transform3D = globals[parent] if parent >= 0 else Transform3D.IDENTITY
			# set_bone_global_pose(köprücük): yerel = ebeveyn⁻¹ · yeni global; konum, dönüş ve ölçeğe ayrışır.
			var cl := pg.affine_inverse() * Transform3D(turn * cg.basis, cg.origin)
			var c_parts := [cl.origin, cl.basis.get_rotation_quaternion(), cl.basis.get_scale()]
			# set_bone_global_pose(kol): köprücüğün yeni global pozuna göre.
			var c_global := pg * compose(c_parts)
			var al := c_global.affine_inverse() * Transform3D(ag.basis, cg.origin + turn * (ag.origin - cg.origin))
			var c_old: Array = locals[c]
			var a_old: Array = locals[a]
			if (c_parts[0] as Vector3).distance_to(c_old[0]) > BAKE_POSITION_TOLERANCE or al.origin.distance_to(a_old[0]) > BAKE_POSITION_TOLERANCE:
				return {"error": "konum değişiyor"}
			if ((c_parts[2] as Vector3) - (c_old[2] as Vector3)).length() > BAKE_SCALE_TOLERANCE or (al.basis.get_scale() - (a_old[2] as Vector3)).length() > BAKE_SCALE_TOLERANCE:
				return {"error": "ölçek değişiyor"}
			out[c] = c_parts[1]
			out[a] = al.basis.get_rotation_quaternion()
		return out


# --- Kaynak yükleme ---------------------------------------------------------------------------------------

## Kaynak klip ve iskeleti: {anim, skeleton} (yüklenemezse boş). .res'in iskeleti sahibinin ana modelinden, GLB'ninki
## kendi sahnesinden gelir; oyunun GLB'sinde klip CharacterAvatar gibi role göre (map_clips), ham GLB'de clip_name
## (taşıyıcının çok klipli GLB'si), verilmemişse ilk klip seçilir. Ham GLB'nin iskeleti düzeltilmemiş hâldedir (tools/rig_fix.py
## yalnız oyunun GLB'sini düzeltir): kişinin modeli varsa dinlenme pozu oradan alınır, kalibrasyon ona göre ölçülmüştür.
func _load_source(id: String, path: String, role: String, clip_name: String = "") -> Dictionary:
	var anim: Animation = null
	var skel: Skeleton3D = null
	if path.get_extension() == "res":
		anim = load(path) as Animation
		skel = donor_skeleton() if is_carrier(id) else ClipLibrary.find_skeleton(_scene_root(StandIn.model_path(id)))
	else:
		var root := _scene_root(path)
		var players: Array = root.find_children("*", "AnimationPlayer", true, false) if root else []
		if players.is_empty():
			return {}
		var player := players[0] as AnimationPlayer
		var chosen := ""
		if path.begins_with("res://"):
			chosen = str(CharacterAvatar.map_clips(player.get_animation_list(), CharacterAvatar._load_roles(id)).get(StringName(role), ""))
		elif not clip_name.is_empty():
			chosen = clip_name if player.has_animation(clip_name) else ""
		else:
			for n in player.get_animation_list():
				if n.to_lower() != "reset":
					chosen = n
					break
		if chosen.is_empty():
			return {}
		anim = player.get_animation(chosen)
		var model_root := _scene_root(StandIn.model_path(id)) if not is_carrier(id) and StandIn.has_model(id) else root
		skel = ClipLibrary.find_skeleton(model_root)
	if anim == null or skel == null:
		return {}
	return {"anim": anim, "skeleton": skel}


## Kaynak sahnenin örneklenmiş kökü (önbellekli). res:// yolu içe aktarılmış sahnedir; mutlak yol (ham GLB) dokusuz
## okunur (GLTFDocument) ve ağları atılır: yalnız iskelet ve klipler gerekir (taşıyıcının on dokuz GLB'si 40'ar MB).
func _scene_root(path: String) -> Node:
	if _scenes.has(path) and is_instance_valid(_scenes[path]):
		return _scenes[path]
	var root: Node = null
	if path.begins_with("res://"):
		var packed: PackedScene = CharacterAvatar.load_scene(path) if ResourceLoader.exists(path) else null
		root = packed.instantiate() if packed else null
	elif FileAccess.file_exists(path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_DISCARD_TEXTURES
		if doc.append_from_file(path, state) == OK:
			root = doc.generate_scene(state)
		if root:
			for mesh in root.find_children("*", "MeshInstance3D", true, false):
				if is_instance_valid(mesh):
					mesh.get_parent().remove_child(mesh)
					mesh.free()
	if root:
		_scenes[path] = root
	return root


## Sahnedeki ilk iskelet (yoksa null).
static func find_skeleton(root: Node) -> Skeleton3D:
	if root == null:
		return null
	var found := root.find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if not found.is_empty() else null


## JSON dosyası (yoksa ya da bozuksa null).
static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("[clip_library] %s okunamadı: %s" % [path, json.get_error_message()])
		return null
	return json.data
