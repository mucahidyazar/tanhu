@tool
class_name CharacterAvatar
extends Node3D
## Bir CharacterProfile'ı (ya da sabit bir NPC modelini) sahnede gösteren karakter.
##
## Öncelik Meshy modelidir: res://assets/characters/<id>/<id>.glb varsa yüklenir, malzemeleri sahnenin
## yumuşak toon ışığına çevrilir, bekle/yürü/koş/otur animasyonları oynatılır ve karakter oluşturucudaki
## renkler bölge maskesiyle uygulanır. Model yoksa kodla kurulan chibi karaktere (ChibiCharacter)
## geri düşülür; böylece oyun her durumda çalışır.
##
## Modeller gerçek boyludur (ör. Mete 1.82 m); düğümün ölçeği 1 bırakılır. <id>_fit.json varsa
## (scripts/character/character_fit_tool.gd ölçer) her rolün "zemine oturma payı" uygulanır: model,
## oynatılan klipte en alt noktası tam zemine değecek kadar yukarı/aşağı kaydırılır (ör. oturan anne
## havada kalmaz, Mete'nin çizmesi toprağa gömülmez). Yürüme ve koşma klipleri de ölçülen doğal
## hızlarına göre hızlandırılır; böylece ayaklar yerde kaymaz.
##
## Çeşitlilik (isteğe bağlı; ClipVariety): variety_person verilirse bekle, yürü, koş ve otur rolleri kişiye atanan çeşitlerle
## oynar (K90 klip kütüphanesi; ClipLibrary.clip_for, model ve klip başına bir kez aktarılır). Zemin payı ve klip hızı o
## çeşidin bu modeldeki ölçüsüdür (clip_library_measure.json; kendi klibinde de zemin payı oradan, ölçülmemişse <id>_fit.json'dan).
## pinned_roles kendi klibinde kalır; modelin zaten oynattığı klip atanırsa aktarım yapılmaz. Klip ilk oynarken kurulur; kare içinde
## kurulmasın diye sahne warm_variety ile ısıtır.
## auto_fidget açıksa rol bekleme iken 8-20 sn'de bir kısa bir ara hareket oynar (kişiye bağlı tohumla; sinemada kapalı).
## Parmak kemiği olan modelde el doğal yarı gevşek durur (HandGrip; set_grip ve relax_hand kapatır, açar; chibi yedeğinde ve parmaksız modelde sessizce kapalı).
##
## Kılık ve pelerin (K58): profil gösteren avatar (oyuncu, oluşturucunun önizlemesi) başlangıç kılığını giyer: Kışlak Kaftanı ve
## Kışlak Pelerini (CharacterOptions.start_outfit, start_cape); sabit model gösteren (model_override: NPC, ansiklopedi, sinema)
## modelin kendi kılığında kalır. outfit ve cape_item elle verilirse onlar giyilir (&"none": kılıksız). Renkler modelin kılık
## maskesiyle (<id>_dye.png, _dye2.png, _dye.json; tools/bake_dye_mask.py) uygulanır; pelerin rengi yalnız
## CharacterOptions.cape_tint(pelerin, profilin boyası)'ndan gelir. Oluşturucu da oyun da bu tek yoldan geçer (M18).
##
## Kullanım:
##   avatar.apply_profile(profile)   # görünümü günceller
##   avatar.set_locomotion(hiz_mps)  # 0 = bekle, ~1.4 = yürü, ~4.5 = koş
##   avatar.play_pose(&"sit")        # NPC'ler için oturma
##   avatar.variety_person = "teoman"; avatar.variety_allocator = allocator   # ağaca girmeden önce (ClipVariety)

signal model_changed(model_id: String)

const CHARACTER_SHADER := preload("res://shaders/character_toon.gdshader")
const OUTLINE_SHADER := preload("res://shaders/character_outline.gdshader")
## Ölçüm dosyası yoksa kullanılan "doğal" klip hızları (m/s); oynatma hızı gerçek hıza göre ölçeklenir.
const WALK_SPEED := 1.6
const RUN_SPEED := 4.2
const ROLES: Array[StringName] = [&"idle", &"walk", &"run", &"sit"]
## Klipler arası geçiş süresi (saniye); zemin payı da bu sürede yumuşakça değişir.
const BLEND_TIME := 0.25
## Kliplerin oynatma hızı sınırları (çok yavaş/hızlı oynatılan klip doğal görünmez).
const WALK_RATE_RANGE := Vector2(0.6, 1.8)
const RUN_RATE_RANGE := Vector2(0.7, 1.5)
## Bir klibin ilk ve son pozu bu kadar yakınsa klip "döngülü" sayılır (radyan / iskelet birimi).
const CYCLE_ROTATION_TOLERANCE := 0.02
const CYCLE_POSITION_TOLERANCE := 0.5
## Model yokken (chibi) yükseklik bilinmiyorsa varsayılan boy (metre).
const FALLBACK_HEIGHT := 1.3
## Oyuncu karakterlerinin kendi ayarlı kliplerinde kalan rolleri (pinned_roles).
const PLAYER_PINNED: Array[StringName] = [&"walk", &"run"]
## Chibi yedeğinin kendi pelerin rengi (pelerinsiz kılıkta).
const CHIBI_CAPE := Color(0.78, 0.15, 0.13)
## İş klibinin rolü (play_job: konuşma, iş, uyku).
const JOB_ROLE := &"job"

## Gösterilecek profil. Boşsa varsayılan profil kullanılır.
@export var profile: CharacterProfile:
	set(value):
		profile = value
		if is_inside_tree():
			apply_profile(value)
## Profil yerine sabit bir model göstermek için (ör. "father"). Boşsa profil kullanılır.
@export var model_override := "":
	set(value):
		model_override = value
		if is_inside_tree():
			_force_reload = true
			apply_profile(_profile)
## Giyilen kaftan ve pelerin (data/character/capes.json kimlikleri). Boşsa kendiliğinden: profil gösteren avatar başlangıç
## kılığını giyer, sabit model gösteren modelin kendi kılığında kalır. &"none" (ya da tanınmayan kimlik) kılıksızdır.
@export var outfit: StringName = &"":
	set(value):
		outfit = value
		if is_inside_tree():
			apply_profile(_profile)
@export var cape_item: StringName = &"":
	set(value):
		cape_item = value
		if is_inside_tree():
			apply_profile(_profile)
## Başlangıçta oynatılacak poz: &"idle" ya da &"sit".
@export var start_pose: StringName = &"idle"
@export var model_scale := 1.0:
	set(value):
		model_scale = value
		if _model:
			_model.scale = Vector3.ONE * model_scale
			_apply_ground_offset(true)
## Kapalıysa Meshy modelleri yok sayılır ve her zaman chibi yedeği kullanılır (testler için).
## Değiştirmek, bir sonraki apply_profile'da karakteri yeniden kurar.
@export var use_meshy_models := true:
	set(value):
		if value != use_meshy_models:
			_force_reload = true
		use_meshy_models = value
## T-pozunda iskeletlenmiş modellerde kalkık görünen omuzları indirsin mi (ShoulderRelax; açı <id>_fit.json →
## shoulder_drop)? Ölçüm aracı (character_fit_tool.gd) ham pozu ölçmek için kapatır.
@export var shoulder_relax := true
## Açıksa karakter face_point noktasına (dünya koordinatı, ör. kamp ateşi) döner. NPC'ler için.
@export var auto_face := false:
	set(value):
		auto_face = value
		_update_facing()
@export var face_point := Vector3.ZERO:
	set(value):
		face_point = value
		_update_facing()
## Çeşitliliğin kişisi (kimlik: teoman, lan_woman_a...; gösterilen model başka olabilir). Boşsa çeşitlilik kapalı: modelin
## kendi klipleri oynar. Ağaca girmeden önce verilir; sonradan set_variety ile.
@export var variety_person := ""
## Kendi klibinde kalan roller (oyuncu karakterleri walk ve run'ı kendi ayarlı kliplerinde tutabilir: PLAYER_PINNED).
@export var pinned_roles: Array[StringName] = []
## Açıksa rol bekleme iken ara hareketler oynar (ClipVariety.FIDGET_WAIT; kişiye bağlı tohumla). Sinemada kapalıdır.
@export var auto_fidget := false:
	set(value):
		auto_fidget = value
		_setup_fidget()
## Sahnenin çeşit dağıtıcısı (yoksa kişi tek başına atanır: aynı sahnedeki kişiler aynı klibi alabilir).
var variety_allocator: ClipVariety.Allocator
## Malzemelerin kişiye özel parametreleri (Folk.paint: ten, saç, giysi boyası): renkler her uygulanışta profilin renklerinden sonra
## yazılır, model yeniden yüklense de kalır. Boşsa yok.
var shader_overrides: Dictionary = {}

var model_id := ""
var _profile: CharacterProfile
var _force_reload := false
var _model: Node3D
var _anim: AnimationPlayer
var _chibi: ChibiCharacter
var _clips := {}
var _materials: Array[ShaderMaterial] = []
var _current_role: StringName = &""
var _regions := {}
## <id>_fit.json: {"ground_offset": {rol: metre}, "clip_speed": {rol: m/s}, ...}
var _fit := {}
var _offset_tween: Tween
## Çeşitlilik: rol → atanan çeşit (kendi klibinde kalan rol burada yoktur), rol → kurulmuş çeşit, rol → doğal hız (m/sn).
var _role_keys := {}
var _built_keys := {}
var _role_speeds := {}
## Modelin kendi klipleri (rol → klip adı; çeşitler bunların üstüne yazılır) ve oynatıcının kütüphanesi kendinin mi (_own_library).
var _base_clips := {}
var _library_is_own := false
## Son istenen: model değişince yeniden oynatılır (hız ≥ 0 ise set_locomotion, değilse play_pose).
var _last_pose: StringName = &""
var _last_speed := -1.0
## _ready'nin ilk pozu oynatıldı mı (ondan önceki model kurulumları poz oynatmaz).
var _started := false
## Oynayan iş klibinin anahtarı (play_job; model değişince yeniden oynatılır).
var _job_key := ""
## Ara hareket: saat, kalan bekleme, oynayan klibin anahtarı ("" = oynamıyor).
var _fidget_clock: ClipVariety.FidgetClock
var _fidget_wait := 0.0
var _fidget_key := ""
## Parmak kavraması (parmak kemiği yoksa null).
var hand_grip: HandGrip


func _ready() -> void:
	set_notify_transform(true)
	apply_profile(profile if profile else CharacterProfile.new())
	play_pose(start_pose)
	_ensure_some_clip()
	_started = true
	set_process(auto_fidget and not Engine.is_editor_hint())
	_update_facing()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_facing()


func _process(delta: float) -> void:
	tick_fidget(delta)


## auto_face açıksa modeli (düğümün kendisini değil) face_point'e çevirir.
func _update_facing() -> void:
	if _model == null or not is_inside_tree():
		return
	if not auto_face:
		_model.rotation.y = 0.0
		return
	var local := to_local(face_point)
	if Vector2(local.x, local.z).length() > 0.01:
		_model.rotation.y = atan2(local.x, local.z)


## Profili uygular: gerekirse modeli değiştirir, renkleri ve aksesuarları günceller.
func apply_profile(p: CharacterProfile) -> void:
	if p == null:
		p = CharacterProfile.new()
	_profile = p
	var id := model_override if not model_override.is_empty() else p.model_id()
	if id != model_id or _model == null or _force_reload:
		_force_reload = false
		_clear_model()
		var path := CharacterOptions.model_path(id)
		if use_meshy_models and not id.is_empty() and ResourceLoader.exists(path):
			_load_meshy(id, path)
		else:
			_build_fallback(p)
		model_id = id
		_assign_variety()
		_update_facing()
		if _started:
			_replay()
		model_changed.emit(id)
	_apply_colors(p)
	if _chibi:
		_apply_chibi_profile(p)


## Hareket hızına göre bekle / yürü / koş animasyonu seçer.
func set_locomotion(speed_mps: float) -> void:
	_last_speed = speed_mps
	_last_pose = &""
	if _chibi:
		_chibi.set_locomotion(speed_mps)
		return
	if _model == null:
		return
	var walk := clip_speed(&"walk")
	var run := clip_speed(&"run")
	if speed_mps < 0.08:
		_play(&"idle", 1.0)
	elif speed_mps < CharacterAvatar.run_threshold(walk, run) or not _has_role(&"run"):
		_play(&"walk", clampf(speed_mps / walk, WALK_RATE_RANGE.x, WALK_RATE_RANGE.y))
	else:
		_play(&"run", clampf(speed_mps / run, RUN_RATE_RANGE.x, RUN_RATE_RANGE.y))


## Yürüme rolünü bu hızda oynatır, hız ne olursa olsun (sinemanın yürüyüşü: çeşidin doğal hızı düşükse set_locomotion'ın
## eşiği kişiyi koşturabilirdi).
func play_walk(speed_mps: float) -> void:
	_last_speed = speed_mps
	_last_pose = &""
	if _chibi:
		_chibi.set_locomotion(speed_mps)
		return
	_play(&"walk", clampf(speed_mps / clip_speed(&"walk"), WALK_RATE_RANGE.x, WALK_RATE_RANGE.y))


## Kütüphanenin bir klibini iş olarak oynatır (konuşma, iş, uyku öbeklerinden bir anahtar; kişilerin programı, Schedule): klip model
## başına bir kez kurulur (ClipLibrary.clip_for), kütüphanedeki döngüsüyle oynar; zemin payı o klibin bu modeldeki ölçüsüdür. Rol JOB_ROLE
## olur; set_locomotion ve play_pose ondan çıkar. Kurulamazsa (chibi yedeği, iskeletsiz model, bilinmeyen anahtar) false.
func play_job(key: String) -> bool:
	if _chibi or _anim == null or key.is_empty() or get_skeleton() == null:
		return false
	var clip := ClipVariety.clip_name(key)
	if not _anim.has_animation(clip):
		var anim := ClipVariety.library().clip_for(model_id, key, get_skeleton())
		if anim == null:
			return false
		_own_library()
		_register_clip(anim, clip, true)
	_last_pose = JOB_ROLE
	_last_speed = -1.0
	if _current_role == JOB_ROLE and _job_key == key:
		return true
	_anim.play(clip, 0.0 if _current_role.is_empty() else BLEND_TIME)
	_anim.speed_scale = 1.0
	_current_role = JOB_ROLE
	_job_key = key
	_fidget_key = ""
	_apply_ground_offset(false)
	return true


## Oynayan işin anahtarı (rol JOB_ROLE değilse boş).
func job_key() -> String:
	return _job_key if _current_role == JOB_ROLE else ""


## Belirli bir pozu oynatır (&"idle", &"sit").
func play_pose(pose: StringName) -> void:
	_last_pose = pose
	_last_speed = -1.0
	if _chibi:
		_chibi.pose = ChibiCharacter.Pose.CROSS_LEGGED if pose == &"sit" else ChibiCharacter.Pose.STANDING
		return
	_play(pose if _has_role(pose) else &"idle", 1.0)


## Süren rol geçişini hemen bitirir: klip karışımı ve zemin payı (sinemanın kesmesinde kişi BLEND_TIME boyunca poz değiştirmez).
func snap_transition() -> void:
	if _anim == null or not _clips.has(_current_role):
		return
	_anim.play(_clips[_current_role], 0.0)
	_apply_ground_offset(true)


## Şu an gösterilen profil.
func get_profile() -> CharacterProfile:
	return _profile


## Meshy modeli mi yüklü (yoksa chibi yedeği mi)?
func has_meshy_model() -> bool:
	return _anim != null


## Giyilen kaftan: elle verilmişse o, yoksa profil gösteren avatarda başlangıç kılığı (Kışlak Kaftanı), sabit modelde yok (&"").
func worn_outfit() -> StringName:
	if outfit != &"":
		return outfit
	return CharacterOptions.start_outfit() if model_override.is_empty() else &""


## Giyilen pelerin: elle verilmişse o, yoksa profil gösteren avatarda başlangıç peleri (Kışlak Pelerini), sabit modelde yok (&"").
func worn_cape() -> StringName:
	if cape_item != &"":
		return cape_item
	return CharacterOptions.start_cape() if model_override.is_empty() else &""


## Modelin kılık maskesi var mı (pelerin ve kaftan boyanabilir mi)?
func has_dye_mask() -> bool:
	return _regions.has("dye_mask")


## Gösterilen karakterde boyanabilir bir pelerin var mı? Meshy modelinde kılık maskesi, chibi yedeğinde kodla çizilen pelerin.
func has_cape() -> bool:
	return has_dye_mask() or _chibi != null


## Pelerine verilen renk (CharacterOptions.cape_tint(worn_cape(), profilin boyası); alfa 0 = modelin kendi rengi). Malzemeye
## yazılan değerin kendisidir: oluşturucu ile oyun aynı değeri verir.
func get_cape_color() -> Color:
	if not _materials.is_empty():
		return _materials[0].get_shader_parameter("cape_color")
	if _chibi:
		return _chibi.cape_color
	return Color(0, 0, 0, 0)


## Kılığın bölge renkleri ("plate", "tunic", "trim"), malzemeye yazıldığı gibi.
func get_outfit_colors() -> Dictionary:
	var out := {}
	for region in ["plate", "tunic", "trim"]:
		out[region] = _materials[0].get_shader_parameter(region + "_color") if not _materials.is_empty() else Color(0, 0, 0, 0)
	return out


## Modelin yüzey malzemeleri (karakter gölgelendiricisi; sınamalar ve ölçüm sahnesi okur).
func get_materials() -> Array[ShaderMaterial]:
	return _materials


## Bulunan animasyon rolleri (testler ve hata ayıklama için).
func available_roles() -> Array:
	var roles := _clips.keys()
	for role: StringName in _role_keys:
		if not roles.has(role):
			roles.append(role)
	return roles


## Şu an oynatılan rol (&"" = henüz yok).
func get_current_role() -> StringName:
	return _current_role


## Rolün oynatıcıdaki klip adı (yoksa boş).
func clip_name(role: StringName) -> String:
	_ensure_role_clip(role)
	return str(_clips.get(role, ""))


## Rolün atanan çeşidi (kendi klibinde kalıyorsa boş).
func variety_key(role: StringName) -> String:
	return str(_role_keys.get(role, ""))


## Oynayan ara hareketin anahtarı (oynamıyorsa boş).
func fidget_key() -> String:
	return _fidget_key


## Modelin animasyon oynatıcısı (chibi yedeğinde null).
func get_animation_player() -> AnimationPlayer:
	return _anim


## Elin kapanma oranı (&"Left", &"Right"; 0 düz, 1 yumruk). Parmak kemiği yoksa bir şey yapmaz.
func set_grip(side: StringName, amount: float, seconds: float = 0.0) -> void:
	if hand_grip:
		hand_grip.set_grip(side, amount, seconds)


## Eli doğal yarı gevşek hâline döndürür.
func relax_hand(side: StringName, seconds: float = 0.0) -> void:
	if hand_grip:
		hand_grip.relax(side, seconds)


## Yüklü modelin kök düğümü (Meshy sahnesi ya da chibi).
func get_model_node() -> Node3D:
	return _model


## Meshy modelinin iskeleti (yoksa null).
func get_skeleton() -> Skeleton3D:
	if _model == null or _chibi:
		return null
	var found := _model.find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if not found.is_empty() else null


## Ayakta duran modelin boyu (metre, düğüm uzayında; model_scale dahil). Meshy modellerinde dinlenme
## pozundaki mesh sınırından, chibi yedeğinde çizilen parçaların sınırından hesaplanır.
func get_model_height() -> float:
	if _model == null:
		return FALLBACK_HEIGHT * model_scale
	var box := CharacterAvatar.rest_bounds(_model)
	return box.end.y * model_scale if box.size.y > 0.01 else FALLBACK_HEIGHT * model_scale


## Kafa ekleminin (boynun üstü, "Head" kemiği) dinlenme pozundaki yüksekliği (metre, düğüm uzayında).
## Kemik yoksa boyun %80'i kabul edilir (chibi yedeğinde kafa büyüktür; yaklaşık değer yeterli).
func get_head_height() -> float:
	var skel := get_skeleton()
	if skel:
		var bone := skel.find_bone("Head")
		if bone >= 0:
			var to_model := PoseFit.relative_transform(_model, skel)
			return (to_model * skel.get_bone_global_rest(bone).origin).y * model_scale
	return get_model_height() * 0.8


## Rolün ölçülmüş zemin payı (metre, ölçeksiz): çeşit ya da modelin kendi klibi ölçü dosyasından (clip_library_measure.json); elle
## verilen klip, ölçülmemiş model ve bacak düzeltmesi olmadan oynayan kendi klibi (sabit rol: ölçü düzeltilmiş klibindir) <id>_fit.json'dan;
## ölçüm yoksa 0.
func ground_offset(role: StringName) -> float:
	var library := ClipVariety.library()
	if _role_keys.has(role):
		return library.ground_offset_for(model_id, _role_keys[role])
	var own := ClipVariety.own_key(model_id, role) if _clips.has(role) and _clips[role] == _base_clips.get(role, "") else ""
	if not own.is_empty() and library.leg_fit_for(model_id, own).is_empty():
		return library.ground_offset_for(model_id, own)
	return CharacterAvatar.fit_value(_fit, "ground_offset", role, 0.0)


## Rolün "doğal" klip hızı (m/s): çeşit atanmışsa onun bu modeldeki ölçüsü (model ölçeğiyle), yoksa ölçüm dosyası, o da yoksa
## sabit varsayılan.
func clip_speed(role: StringName) -> float:
	if float(_role_speeds.get(role, 0.0)) > 0.05:
		return float(_role_speeds[role]) * model_scale
	var fallback := RUN_SPEED if role == &"run" else WALK_SPEED
	var v := CharacterAvatar.fit_value(_fit, "clip_speed", role, fallback)
	return v if v > 0.05 else fallback


# --- Saf yardımcılar (test edilebilir) --------------------------------------------

## fit sözlüğünden fit[group][role] değeri (yoksa fallback).
static func fit_value(fit: Dictionary, group: String, role: StringName, fallback: float) -> float:
	var table = fit.get(group)
	if table is Dictionary and (table as Dictionary).has(String(role)):
		return float(table[String(role)])
	return fallback


## Yürümeden koşmaya geçilen hız: iki klibin doğal hızlarının ortası.
static func run_threshold(walk_speed: float, run_speed: float) -> float:
	return (walk_speed + run_speed) * 0.5


## Animasyon adlarını rollere eşler: önce ada bakar (idle/walk/run/sit), bulamazsa meta.json'daki sırayı kullanır.
static func map_clips(names: PackedStringArray, ordered_roles: Array) -> Dictionary:
	var result := {}
	var keywords := {&"idle": ["idle"], &"walk": ["walk"], &"run": ["run", "sprint"], &"sit": ["sit"]}
	for role in keywords:
		for n in names:
			var lower := n.to_lower()
			for k in keywords[role]:
				if lower.contains(k) and not result.values().has(n):
					result[role] = n
					break
			if result.has(role):
				break
	# Adlar anlamsızsa (ör. "Armature|clip0") meta.json'daki rol sırasına güven.
	var unnamed := []
	for n in names:
		if not result.values().has(n) and not n.to_lower().begins_with("reset"):
			unnamed.append(n)
	for i in ordered_roles.size():
		var role := StringName(ordered_roles[i])
		if not result.has(role) and i < names.size() and unnamed.has(names[i]):
			result[role] = names[i]
	return result


## Kök kemiğin yatay yer değiştirmesini (kök hareketi) siler; karakter kodla hareket ettiği için animasyon
## yerinde oynar. Yalnızca klip boyunca biriken kayma (ilk ve son kare arasındaki fark) zamanla orantılı
## çıkarılır; kalçanın yürürken sağa sola salınması korunur. Zaten yerinde olan klip değişmez.
static func make_in_place(anim: Animation) -> void:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		var bone := String(anim.track_get_path(t).get_concatenated_subnames()).to_lower()
		if not (bone.contains("hips") or bone.contains("pelvis") or bone.contains("root")):
			continue
		var count := anim.track_get_key_count(t)
		if count < 2:
			return
		var first: Vector3 = anim.track_get_key_value(t, 0)
		var last: Vector3 = anim.track_get_key_value(t, count - 1)
		var drift := Vector3(last.x - first.x, 0.0, last.z - first.z)
		var span := anim.track_get_key_time(t, count - 1) - anim.track_get_key_time(t, 0)
		if drift.is_zero_approx() or span <= 0.0:
			return
		var start := anim.track_get_key_time(t, 0)
		for k in count:
			var v: Vector3 = anim.track_get_key_value(t, k)
			var f := (anim.track_get_key_time(t, k) - start) / span
			anim.track_set_key_value(t, k, v - drift * f)
		return


## Klibin ilk ve son pozu (tüm dönüş ve konum izleri) aynı mı? Öyleyse klip dikişsiz döngü yapabilir.
## Meshy'nin "oturma" klibi oturan kişinin nefes alıp vermesidir (döngü); ayağa kalkıp oturan bir geçiş
## klibi ise döngülü değildir ve son karesinde durmalıdır.
static func is_cyclic(anim: Animation) -> bool:
	for t in anim.get_track_count():
		var count := anim.track_get_key_count(t)
		if count < 2:
			continue
		match anim.track_get_type(t):
			Animation.TYPE_ROTATION_3D:
				var a: Quaternion = anim.track_get_key_value(t, 0)
				var b: Quaternion = anim.track_get_key_value(t, count - 1)
				if a.angle_to(b) > CYCLE_ROTATION_TOLERANCE:
					return false
			Animation.TYPE_POSITION_3D:
				var p: Vector3 = anim.track_get_key_value(t, 0)
				var q: Vector3 = anim.track_get_key_value(t, count - 1)
				if p.distance_to(q) > CYCLE_POSITION_TOLERANCE:
					return false
	return true


## Modelin dinlenme pozundaki sınır kutusu (model kökünün uzayında). Deri giydirilmiş Meshy meshlerinde
## köşeler zaten model uzayındadır (bind pozu = dinlenme pozu); diğer meshler düğüm dönüşümleriyle taşınır.
static func rest_bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var vi := node as VisualInstance3D
		var mi := vi as MeshInstance3D
		var local := vi.get_aabb()
		if mi == null or mi.skin == null:
			local = PoseFit.relative_transform(root, vi) * local
		box = local if first else box.merge(local)
		first = false
	return box


# --- Meshy modeli -------------------------------------------------------------

func _load_meshy(id: String, path: String) -> void:
	var scene := CharacterAvatar.load_scene(path)
	if scene == null:
		push_warning("Model yüklenemedi: %s" % path)
		_build_fallback(_profile)
		return
	_model = scene.instantiate() as Node3D
	_model.name = "Model"
	_model.scale = Vector3.ONE * model_scale
	add_child(_model)
	_regions = _load_regions(id)
	_fit = _load_fit(id)
	_convert_materials(_model)
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	_anim = players[0] as AnimationPlayer if not players.is_empty() else null
	_clips = map_clips(_anim.get_animation_list() if _anim else PackedStringArray(), _load_roles(id)) if _anim else {}
	_add_extra_clips(id)
	_add_shoulder_relax()
	hand_grip = HandGrip.attach(get_skeleton())
	var bones := get_skeleton()
	for role in _clips:
		var anim := _anim.get_animation(_clips[role])
		if bones:
			ClipLibrary.complete_rest_tracks(anim, bones)
		if role == &"sit":
			anim.loop_mode = Animation.LOOP_LINEAR if is_cyclic(anim) else Animation.LOOP_NONE
		else:
			anim.loop_mode = Animation.LOOP_LINEAR
			make_in_place(anim)
	_base_clips = _clips.duplicate()


## T-pozunda iskeletlenmiş modellerde kalkık görünen omuzları indirir: ölçüm dosyasındaki shoulder_drop kadar
## (yoksa ya da çok küçükse düzeltme eklenmez).
func _add_shoulder_relax() -> void:
	var drop := float(_fit.get("shoulder_drop", 0.0))
	var skeleton := get_skeleton()
	if not shoulder_relax or drop < 0.5 or skeleton == null:
		return
	var relax := ShoulderRelax.new()
	relax.name = "ShoulderRelax"
	relax.drop_deg = drop
	skeleton.add_child(relax)


## Bir rolün klibini değiştirir ya da ekler (ör. geliştirme sahnesinde aday klipleri denemek için).
## O rol oynuyorsa yeni klip hemen başlar. Chibi yedeğinde bir şey yapmaz.
func set_role_clip(role: StringName, anim: Animation) -> void:
	if _model == null or _chibi or anim == null:
		return
	var clip := _register_clip(anim, StringName(String(role).capitalize() + "_custom"), true)
	anim.loop_mode = Animation.LOOP_LINEAR if role != &"sit" or is_cyclic(anim) else Animation.LOOP_NONE
	_clips[role] = String(clip)
	_role_keys.erase(role)
	_built_keys.erase(role)
	_role_speeds.erase(role)
	if _current_role == role:
		_current_role = &""
		_play(role, _anim.speed_scale)


## Çeşitliliği çalışırken açar ya da değiştirir (kişi boşsa kapatır: model yeniden yüklenmez, kendi klipleri kalır). Rol
## oynuyorsa yeni klibiyle yeniden başlar. Ağaca girmeden önce variety_person ve variety_allocator doğrudan verilir.
func set_variety(person_id: String, allocator: ClipVariety.Allocator = null) -> void:
	variety_person = person_id
	variety_allocator = allocator
	if _model == null or _chibi:
		return
	if _anim:
		_anim.stop()
	_assign_variety()
	_current_role = &""
	_replay()


## Rollerin çeşit kliplerini şimdi kurar (boşsa bütün roller): kare içinde aktarım olmasın diye sahne kurulumda çağırır. Kurulan
## klip önbellektedir, ikinci çağrı iş yapmaz.
func warm_variety(roles: Array = []) -> void:
	for role: StringName in (roles if not roles.is_empty() else ROLES):
		_ensure_role_clip(role)


## Ara hareketin saati (her kare; sınamalar doğrudan çağırır): rol bekleme iken bekleme süresi dolunca ara hareket başlar. Bitince
## (animation_finished) bekleme klibine çapraz geçişle dönülür.
func tick_fidget(delta: float) -> void:
	if not auto_fidget or _fidget_clock == null or _anim == null or _current_role != &"idle" or not _fidget_key.is_empty():
		return
	_fidget_wait -= delta
	if _fidget_wait > 0.0:
		return
	var key := _fidget_clock.next_key()
	_fidget_wait = _fidget_clock.next_wait()
	if key.is_empty() or not _anim.has_animation(ClipVariety.clip_name(key)):
		return
	_fidget_key = key
	_anim.play(ClipVariety.clip_name(key), BLEND_TIME)
	_anim.speed_scale = 1.0
	_apply_ground_offset(false)


## Model sahnesini yükler. Aynı dosya o sırada arka planda yükleniyorsa (ör. karakter oluşturucu oyuncu
## modellerini önceden yüklerken vücut tipi hemen değiştirildi) o yüklemenin sonucu beklenip alınır;
## dosya ikinci kez okunmaz.
static func load_scene(path: String) -> PackedScene:
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path) as PackedScene
	return load(path) as PackedScene


## Ek klip dosyaları: res://assets/characters/<id>/<id>_<rol>.res (rol: idle, walk, run, sit).
## Meshy her animasyonu ayrı bir GLB olarak verir; kliplerin yalnızca animasyon kısmı
## tools/extract_animation.gd ile .res dosyasına çıkarılır ve burada modelin oynatıcısına eklenir.
## (Mete'nin oturma klibi bir NPC'ninkinden ClipRetarget ile aktarılmıştır.)
## Model dosyasında hiç animasyon yoksa oynatıcı burada oluşturulur.
func _add_extra_clips(id: String) -> void:
	for role in ROLES:
		var path := "res://assets/characters/%s/%s_%s.res" % [id, id, role]
		if not ResourceLoader.exists(path):
			continue
		var anim := load(path) as Animation
		if anim == null:
			continue
		var clip := StringName(String(role).capitalize() + "_extra")
		_clips[role] = String(_register_clip(anim, clip, false))


## Klibi modelin oynatıcısına ekler (oynatıcı yoksa oluşturur); kullanılan klip adını döndürür.
## replace kapalıysa aynı adlı mevcut klip korunur.
func _register_clip(anim: Animation, clip: StringName, replace: bool) -> StringName:
	if _anim == null:
		_anim = AnimationPlayer.new()
		_anim.name = "AnimationPlayer"
		_model.add_child(_anim)
		_anim.root_node = NodePath("..")
	var library := _anim.get_animation_library(&"")
	if library == null:
		library = AnimationLibrary.new()
		_anim.add_animation_library(&"", library)
	if library.has_animation(clip):
		if not replace or library.get_animation(clip) == anim:
			return clip
		library.remove_animation(clip)
	library.add_animation(clip, anim)
	return clip


func _play(role: StringName, speed: float) -> void:
	_ensure_role_clip(role)
	if _anim == null or not _clips.has(role):
		return
	if _current_role != role:
		var first := _current_role == &""
		_anim.play(_clips[role], 0.0 if first else BLEND_TIME)
		if first and _role_keys.has(role):
			_seek_to_phase(_clips[role], role)
		_current_role = role
		_fidget_key = ""
		if role == &"idle" and _fidget_clock:
			_fidget_wait = _fidget_clock.next_wait()
		_apply_ground_offset(first)
	_anim.speed_scale = speed


## Çeşit klibi kişiye bağlı bir yerinden başlar: aynı klibi alan kişiler (havuz bittiğinde) ve aynı anda kurulan bir kalabalık aynı
## adımda salınmaz. Evre kişinin kimliğinden gelir: her çalıştırmada aynı (menü karesi ve çekimler belirlenimci kalır). Döngüye sokulmayan
## oturuş (ClipVariety.role_clip) son pozundan başlar: kişi sahne açılınca oturmuş olur.
func _seek_to_phase(clip: String, role: StringName) -> void:
	var anim := _anim.get_animation(clip)
	if anim == null:
		return
	if anim.loop_mode != Animation.LOOP_NONE:
		_anim.seek(anim.length * ClipVariety.phase_of(variety_person), true)
	elif role == &"sit":
		_anim.seek(anim.length, true)


## Rol oynatılabilir mi (kendi klibi var ya da çeşit atanmış)?
func _has_role(role: StringName) -> bool:
	return _clips.has(role) or _role_keys.has(role)


## Model değişince son isteneni yeniden oynatır; hiçbir şey istenmediyse başlangıç pozunu.
func _replay() -> void:
	if _last_speed >= 0.0:
		set_locomotion(_last_speed)
	elif _last_pose == JOB_ROLE and not _job_key.is_empty():
		var key := _job_key
		_job_key = ""
		if not play_job(key):
			play_pose(start_pose)
	else:
		play_pose(_last_pose if not _last_pose.is_empty() else start_pose)
	_ensure_some_clip()


## İstenen rolün klibi yoksa elindeki bir klibi oynatır (Ana, Baba, Çocuk ve Ozan'ın bekleme klibi yok: Ansiklopedi'nin görünümü onları
## bekleme pozuyla kurar): kişi T-pozda kalmasın. İlk kurulumda da, model değişiminde de.
func _ensure_some_clip() -> void:
	if not _chibi and _current_role.is_empty() and not _clips.is_empty():
		_play(&"sit" if _clips.has(&"sit") else _clips.keys()[0], 1.0)


## Rollere kişinin çeşitlerini atar (klip ilk oynarken ya da warm_variety ile kurulur). Modelin o rolde zaten oynattığı klip
## atanırsa kendi klibi kalır: aktarım gerekmez, zemin payı ve hız <id>_fit.json'dan.
func _assign_variety() -> void:
	_role_keys.clear()
	_built_keys.clear()
	_role_speeds.clear()
	_clips = _base_clips.duplicate()
	if variety_person.is_empty() or _chibi or _model == null or get_skeleton() == null:
		_setup_fidget()
		return
	if variety_allocator == null:
		variety_allocator = ClipVariety.Allocator.new()
	_own_library()
	for role in ROLES:
		var key := variety_allocator.key_for_role(variety_person, role)
		if pinned_roles.has(role) or key.is_empty() or ClipVariety.is_own_clip(model_id, key, role):
			continue
		_role_keys[role] = key
		if role == &"walk" or role == &"run":
			_role_speeds[role] = ClipVariety.natural_speed(model_id, key, get_skeleton())
	_setup_fidget()


## Rolün çeşit klibini kurar (kurulmuşsa bir şey yapmaz). Kurulamazsa rol kendi klibinde kalır.
func _ensure_role_clip(role: StringName) -> void:
	var key: String = _role_keys.get(role, "")
	if key.is_empty() or _built_keys.get(role, "") == key:
		return
	var anim := ClipVariety.role_clip(model_id, key, role, get_skeleton())
	if anim == null:
		_role_keys.erase(role)
		_role_speeds.erase(role)
		return
	_built_keys[role] = key
	_clips[role] = String(_register_clip(anim, ClipVariety.clip_name(key), true))


## Oynatıcıya kendi klip kütüphanesini verir. GLB'nin kütüphanesi aynı modelin bütün örneklerince paylaşılır: iki kişi aynı modeli
## gösterip başka çeşitler oynayınca (iki Lan kadını) birinin eklediği klip ötekinin listesine (map_clips) ve aktarımın kaynağına
## (ClipLibrary._load_source) karışırdı. Oynayan klip varsa kaldığı yerden sürer (kütüphaneyi söküp takmak onu düşürür).
func _own_library() -> void:
	if _library_is_own or _anim == null:
		return
	_library_is_own = true
	var playing := _anim.assigned_animation if _anim.is_playing() else &""
	var clip_time := _anim.current_animation_position if _anim.is_playing() else 0.0
	var shared := _anim.get_animation_library(&"")
	var own := AnimationLibrary.new()
	if shared:
		for clip in shared.get_animation_list():
			own.add_animation(clip, shared.get_animation(clip))
		_anim.remove_animation_library(&"")
	_anim.add_animation_library(&"", own)
	if not playing.is_empty():
		_anim.play(playing)
		_anim.seek(clip_time, true)


## Ara hareketin saatini kurar ve kliplerini ısıtır (kare içinde aktarım olmasın). Kişi verilmemişse saatin tohumu ve profili
## modelin kimliğinden: oyuncu karakteri çeşitliliksiz de ara hareket oynayabilir.
func _setup_fidget() -> void:
	_fidget_clock = null
	_fidget_key = ""
	set_process(auto_fidget and not Engine.is_editor_hint())
	if not auto_fidget or _chibi or _model == null or _anim == null or get_skeleton() == null:
		return
	_own_library()
	var person := variety_person if not variety_person.is_empty() else model_id
	var person_profile := variety_allocator.profile_for(person) if variety_allocator and not variety_person.is_empty() else ClipVariety.profile_of(person)
	var pool := ClipVariety.fidget_pool(person_profile)
	_fidget_clock = ClipVariety.FidgetClock.new(person, pool)
	_fidget_wait = _fidget_clock.next_wait()
	for key: String in pool:
		var anim := ClipVariety.library().clip_for(model_id, key, get_skeleton())
		if anim:
			_register_clip(anim, ClipVariety.clip_name(key), true)
	ClipVariety.release_sources()
	if not _anim.animation_finished.is_connected(_on_animation_finished):
		_anim.animation_finished.connect(_on_animation_finished)


## Ara hareket bitti: bekleme klibine çapraz geçiş.
func _on_animation_finished(anim_name: StringName) -> void:
	if _fidget_key.is_empty() or anim_name != ClipVariety.clip_name(_fidget_key):
		return
	_fidget_key = ""
	if _current_role == &"idle" and _clips.has(&"idle"):
		_anim.play(_clips[&"idle"], BLEND_TIME)
		_apply_ground_offset(false)


## Modeli oynatılan rolün (ara harekette o klibin) zemin payı kadar kaydırır (geçişte klip karışımıyla birlikte yumuşakça).
func _apply_ground_offset(instant: bool) -> void:
	if _model == null or _chibi:
		return
	_apply_flat_hands()
	var offset := ClipVariety.library().ground_offset_for(model_id, _fidget_key) if not _fidget_key.is_empty() else ground_offset(_current_role)
	if _fidget_key.is_empty() and _current_role == JOB_ROLE:
		offset = ClipVariety.library().ground_offset_for(model_id, _job_key)
	var target := offset * model_scale
	if _offset_tween:
		_offset_tween.kill()
		_offset_tween = null
	if instant or not is_inside_tree() or Engine.is_editor_hint() or is_equal_approx(_model.position.y, target):
		_model.position.y = target
		return
	_offset_tween = create_tween()
	_offset_tween.tween_property(_model, ^"position:y", target, BLEND_TIME).set_trans(Tween.TRANS_SINE)


## Yere dayanan el düz durur (tanımın pose_fix flatten_hand): doğal kapanma parmağı zemine sokardı.
func _apply_flat_hands() -> void:
	if hand_grip == null:
		return
	var key: String = _fidget_key if not _fidget_key.is_empty() else str(_role_keys.get(_current_role, ""))
	var fix: Variant = ClipVariety.library().clip(key).get("pose_fix") if not key.is_empty() else null
	hand_grip.set_flat_hands(fix.get("flatten_hand", []) if fix is Dictionary else [])


## Meshy'nin PBR malzemelerini, dokuyu koruyarak yumuşak toon malzemeye çevirir.
func _convert_materials(root: Node) -> void:
	_materials.clear()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var source := mi.get_active_material(s)
			var mat := ShaderMaterial.new()
			mat.shader = CHARACTER_SHADER
			mat.next_pass = _outline_material()
			if source is BaseMaterial3D:
				var base := source as BaseMaterial3D
				mat.set_shader_parameter("albedo_texture", base.albedo_texture)
				mat.set_shader_parameter("albedo_tint", base.albedo_color)
			if _regions.has("mask"):
				mat.set_shader_parameter("region_mask", _regions["mask"])
				if _regions.has("mask2"):
					mat.set_shader_parameter("region_mask2", _regions["mask2"])
				mat.set_shader_parameter("use_region_mask", true)
				for key in ["hair_base", "skin_base", "eye_base", "hair_natural_tint"]:
					if _regions.has(key):
						mat.set_shader_parameter(key, _regions[key])
			if _regions.has("dye_mask"):
				mat.set_shader_parameter("dye_mask", _regions["dye_mask"])
				if _regions.has("dye_mask2"):
					mat.set_shader_parameter("dye_mask2", _regions["dye_mask2"])
				mat.set_shader_parameter("use_dye_mask", true)
				for key in ["cape_lum", "plate_lum", "tunic_lum", "trim_lum"]:
					if _regions.has(key):
						mat.set_shader_parameter(key, _regions[key])
			mi.set_surface_override_material(s, mat)
			_materials.append(mat)


## Tüm karakterlerin paylaştığı ince kahve kontur malzemesi.
static func _outline_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = OUTLINE_SHADER
	return mat


func _apply_colors(p: CharacterProfile) -> void:
	# Kılık maskesi olmayan modelde (NPC'ler, kadın kahraman) kılık renkleri alfa 0 kalır: malzemede de etkisizdir.
	var dressed := has_dye_mask()
	var cape := CharacterOptions.cape_tint(worn_cape(), p.cape_dye) if dressed else Color(0, 0, 0, 0)
	var kit := CharacterOptions.outfit_colors(worn_outfit() if dressed else &"")
	for mat in _materials:
		mat.set_shader_parameter("hair_color", CharacterOptions.color_for(&"hair_color", p.hair_color))
		mat.set_shader_parameter("skin_color", CharacterOptions.color_for(&"skin", p.skin))
		mat.set_shader_parameter("eye_color", CharacterOptions.color_for(&"eye_color", p.eye_color))
		mat.set_shader_parameter("cape_color", cape)
		for region in kit:
			mat.set_shader_parameter(region + "_color", kit[region])
		for key: Variant in shader_overrides:
			mat.set_shader_parameter(StringName(str(key)), shader_overrides[key])


## Renkleri yeniden yazar (profil, kılık ve shader_overrides; Folk boyaları değişince).
func refresh_colors() -> void:
	_apply_colors(_profile if _profile else CharacterProfile.new())


## <id>_regions.png (R saç, G ten, B göz) ve <id>_regions.json (bölgelerin temel renkleri) varsa yükler; kılık maskesi de
## (<id>_dye.png R pelerin, G zırh levhası, B gömlek; <id>_dye2.png R kuşak ve şeritler; <id>_dye.json bölgelerin doğrusal
## ortalama parlaklığı) varsa "dye_mask", "dye_mask2", "cape_lum"... anahtarlarıyla.
static func _load_regions(id: String) -> Dictionary:
	var result := {}
	var dir := "res://assets/characters/%s/" % id
	if ResourceLoader.exists(dir + id + "_regions.png"):
		result["mask"] = load(dir + id + "_regions.png")
	if ResourceLoader.exists(dir + id + "_regions2.png"):
		result["mask2"] = load(dir + id + "_regions2.png")
	var json_path := dir + id + "_regions.json"
	if FileAccess.file_exists(json_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(json_path))
		if data is Dictionary:
			for key in ["hair_base", "skin_base", "eye_base", "hair_natural_tint"]:
				if data.has(key):
					result[key] = Color.html(str(data[key]))
	var dye_json := dir + id + "_dye.json"
	if ResourceLoader.exists(dir + id + "_dye.png") and FileAccess.file_exists(dye_json):
		result["dye_mask"] = load(dir + id + "_dye.png")
		if ResourceLoader.exists(dir + id + "_dye2.png"):
			result["dye_mask2"] = load(dir + id + "_dye2.png")
		var dye = JSON.parse_string(FileAccess.get_file_as_string(dye_json))
		if dye is Dictionary:
			for region in ["cape", "plate", "tunic", "trim"]:
				if dye.get(region) is Dictionary and (dye[region] as Dictionary).has("lum"):
					result[region + "_lum"] = float(dye[region]["lum"])
	return result


## <id>_fit.json (zemin payları, klip hızları); yoksa ya da bozuksa boş sözlük.
static func _load_fit(id: String) -> Dictionary:
	var path := "res://assets/characters/%s/%s_fit.json" % [id, id]
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


## meta.json'daki animasyon rol sırası (ör. ["idle", "walk", "run"]).
static func _load_roles(id: String) -> Array:
	var path := "res://assets/characters/%s/meta.json" % id
	if not FileAccess.file_exists(path):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		for key in ["clip_roles", "intended_clip_roles", "clips"]:
			if data.get(key) is Array:
				return data[key]
	return []


# --- Chibi yedeği -------------------------------------------------------------

func _build_fallback(p: CharacterProfile) -> void:
	_chibi = ChibiCharacter.new()
	_chibi.name = "Chibi"
	_chibi.auto_face = false
	_chibi.pose = ChibiCharacter.Pose.STANDING
	_chibi.has_cape = true
	_chibi.fur_collar = false
	_chibi.outfit_color = Color(0.93, 0.91, 0.86)
	_chibi.cape_color = CHIBI_CAPE
	_chibi.belt_color = Color(0.8, 0.18, 0.15)
	_chibi.pants_color = Color(0.2, 0.19, 0.21)
	_chibi.boots_color = Color(0.25, 0.24, 0.26)
	_model = _chibi
	add_child(_chibi)
	_apply_chibi_profile(p)


func _apply_chibi_profile(p: CharacterProfile) -> void:
	# Model dosyası eksikse chibi yedeği o karakterin saç biçimine ve rengine yakın görünür.
	var defaults := {
		"mete": [ChibiCharacter.Hair.TOP_BUN, Color(0.08, 0.07, 0.08)],
		"hero_f": [ChibiCharacter.Hair.TWIN_BRAIDS, Color(0.27, 0.16, 0.1)],
	}
	var d: Array = defaults.get(p.model_id(), [ChibiCharacter.Hair.SHORT, Style.HAIR_DARK])
	_chibi.hair = d[0]
	var hair := CharacterOptions.color_for(&"hair_color", p.hair_color)
	_chibi.hair_color = hair if hair.a > 0.0 else d[1]
	var skin := CharacterOptions.color_for(&"skin", p.skin)
	_chibi.skin_color = skin if skin.a > 0.0 else Style.SKIN
	_chibi.beard = [ChibiCharacter.Beard.NONE, ChibiCharacter.Beard.SHORT, ChibiCharacter.Beard.SHORT, ChibiCharacter.Beard.LONG][clampi(p.beard, 0, 3)]
	# Yedekte de pelerin rengi tek yerden gelir (K58); pelerinsiz kılıkta yedeğin kendi kızılı kalır.
	var cape := CharacterOptions.cape_tint(worn_cape(), p.cape_dye)
	_chibi.cape_color = cape if cape.a > 0.0 else CHIBI_CAPE


func _clear_model() -> void:
	if _offset_tween:
		_offset_tween.kill()
		_offset_tween = null
	if _model:
		CharacterAvatar._release_materials(_model)
		remove_child(_model)
		_model.queue_free()
	_model = null
	_anim = null
	_chibi = null
	_clips = {}
	_materials.clear()
	_current_role = &""
	_regions = {}
	_fit = {}
	_role_keys.clear()
	_built_keys.clear()
	_role_speeds.clear()
	_fidget_clock = null
	_fidget_key = ""
	hand_grip = null
	_base_clips = {}
	_library_is_own = false


## Kişiye özel yüzey malzemelerini eski modelin ağlarından alır. Model silinmeye sırasını beklerken _materials boşalır: malzemenin tek
## sahibi ağ kalır ve MeshInstance3D silinirken önce malzeme, sonra örnek düşer. Örnek çizim sunucusunda henüz işlenmemişse (aynı karede
## kurulup değişen model) ve ağ başka bir kişide yaşıyorsa sunucu silinmiş malzemenin örnek parametrelerini okumaya kalkar: «Parameter
## "material" is null» (material_get_instance_shader_parameters). Malzeme önceden çıkarılınca örnek ağın kendi malzemesine döner.
static func _release_materials(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			mi.set_surface_override_material(s, null)
