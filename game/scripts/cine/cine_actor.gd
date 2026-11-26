class_name CineActor
extends Node3D
## Sinemanın kişisi (Yol Haritası hereka-model; K89; godot.md §3.6): CharacterAvatar'ı saran düğüm. Kişinin kimliği
## (character_id) ve sahnedeki düğüm yolu sabittir (prologue_birth.tscn'de Actors/<Id>); gösterilen model StandIn ile
## çözülür: assets/characters/<id>/<id>.glb varsa kişinin kendi Meshy modeli, yoksa meta.json'un yer tutucusu (var olan
## bir model, kendi renk çarpanı, ölçeği ve varsa başlığıyla). Meshy modeli (meshy-final) gelince yalnız <id>.glb
## eklenir; kod ve sahne değişmez. Çocukluk ve I. Perde aynı kimlikleri kullanır.
##
## Sahnenin AnimationPlayer'ı kişiyi özellikleriyle sürer (ileri sarmada da doğru kurulur):
##   pose          &"sit" (oturma klibi), &"idle" (bekleme), &"walk" (yürüme; walk_speed hızında, yer değiştirmeyi
##                 position izi yapar)
##   bow_amount    CineBow: omurga eğilişi (Teoman doğan güne eğilir; 0..1)
##   reach_amount  reach_turns'ün etkisi (Lan Hatun'un keregeyi tutan kolu)
##   gesture_amount gesture_turns'ün etkisi (sayıcının çentiği, Hereka'nın beşiğe yay asışı)
## reach_grips ve gesture_grips aynı değerlerle eli kapatır (HandGrip): kişi tutarken parmakları kavrar, 0'da doğal el. Değer sahnenin izinden yazılır: ileri sarmada da aynı kare.
## Poz kişinin atanan çeşidiyle oynar (ClipVariety): sahnenin kişileri ortak bir dağıtıcıya sahnedeki sırayla kaydolur, iki
## kişi bir öbekte, uygun çeşit kaldıkça aynı klibi almaz (iki Lan kadını aynı ağı gösterir, başka oturur); sahne bir kişinin oturuşunu
## elle seçebilir (seat_key). Ara hareket sinemada kapalıdır: çekimler belirlenimci kalsın. Kolu CineBow'la bir yere uzanan kişinin (reach_turns: Lan Hatun'un keregeyi
## tutan kolu) oturuşu kendi klibinde kalır: dönüşler o pozun üstüne ayarlandı, başka oturuşta el keregeyi bulmaz.
## Bağışçı tek kaynaktan gelir (ClipLibrary.donor_for); modelin bekleme klibi hiç yoksa FALLBACK_IDLE aktarılır.
## Başlık (stand_in.headwear: band, cap, fur_hat, kerchief; ölçüleri metre) Head kemiğine bağlanır: yer tutucuyu kamp halkından
## ayırır. Bugün başlıklı yer tutucu yok: 2026-11-06'ya dek 100 kat küçük çiziliyordu, gerçek boyda parçalar göz onayından geçmedi.

signal built(actor: CineActor)

const POSES: Array[StringName] = [&"sit", &"idle", &"walk"]
## Başlık parçalarının köşe sayısı.
const HAT_SEGMENTS := 18
## Çeşit seçilirken sayılan yürüme hızı (m/sn): Önsöz'ün kişileri 1,2-1,45 yürür (walk_speed sahnede kişi kurulurken verilir,
## dağıtıcı ise ilk kişiyle kurulur), doğal hızı buna yetişmeyen klipte ayaklar yerde kayardı. Kişinin walk_speed'i
## SLOW_WALK_BELOW'un altındaysa (ağır yürüyen yaşlı) o hız sayılır: titrek yürüyüş böyle gelir.
const WALK_FILTER_SPEED := 1.4
const SLOW_WALK_BELOW := 1.0
## Çeşitlerin ısıtıldığı roller (ensure_idle'ın varsayılanı): sinemada kişi yalnız oturur, durur ve yürür. Sahne kişinin oynamayacağı
## rolü dışarıda bırakabilir: hiç yürümeyen kişinin yürüyüşü boşuna aktarılmasın.
const WARM_ROLES: Array[StringName] = [&"idle", &"walk"]

## Kişinin kimliği (assets/characters/<id>/).
@export var character_id := ""
## Sahne ağaca girince kurulsun mu (false: sahne kurar; ağır kurulum karelere bölünsün diye).
@export var build_on_ready := true
@export var pose: StringName = &"idle":
	set(value):
		pose = value if POSES.has(value) else &"idle"
		_apply_pose()
@export_range(0.0, 1.0, 0.01) var bow_amount := 0.0:
	set(value):
		bow_amount = value
		if bow:
			bow.amount = value
@export_range(0.0, 1.0, 0.01) var reach_amount := 0.0:
	set(value):
		reach_amount = value
		if reach:
			reach.amount = value
		_apply_grips()
@export_range(0.0, 1.0, 0.01) var gesture_amount := 0.0:
	set(value):
		gesture_amount = value
		if gesture:
			gesture.amount = value
		_apply_grips()
## Yürüme klibinin hızı (m/sn; klip doğal hızına göre ölçeklenir).
@export var walk_speed := 1.2
## Eğilme açısı (derece) ve kol dönüşleri (CineBow.turns biçimi).
var bow_deg := CineBow.BOW_DEG
var reach_turns: Array = []
var gesture_turns: Array = []
## Uzanırken ve jestte kapanan eller ({&"Right": 0,85}: kapanma oranı, tam etkide).
var reach_grips := {}
var gesture_grips := {}
## Sahnenin elle seçtiği yer oturuşu (ClipVariety.Allocator.assign; boşsa dağıtıcı seçer). Dağıtıcı ilk kişi kurulurken kurulur: kişilerden önce yazılır.
var seat_key := ""
## Kişilerin klasörü (sınamalar sahte bir klasör verir).
var root := StandIn.ROOT

## StandIn.resolve sonucu: {id, model, tint, scale, stand_in}.
var resolved: Dictionary = {}
var avatar: CharacterAvatar
var bow: CineBow
var reach: CineBow
var gesture: CineBow
var headwear: Node3D


func _ready() -> void:
	if build_on_ready and not Engine.is_editor_hint():
		build()


## Kişiyi kurar: StandIn çözülür, avatar o modelle (tek yüklemeyle) eklenir, renk çarpanı, ölçek, başlık ve
## düzeltmeler (CineBow) uygulanır. İkinci çağrı bir şey yapmaz.
func build(p_root: String = "") -> void:
	if avatar:
		return
	if not p_root.is_empty():
		root = p_root
	resolved = StandIn.resolve(character_id, root)
	avatar = CharacterAvatar.new()
	avatar.name = "Avatar"
	avatar.model_override = str(resolved["model"])
	avatar.start_pose = &"sit" if pose == &"sit" else &"idle"
	avatar.set_meta(StandIn.PERSON_META, character_id)
	avatar.variety_person = character_id
	avatar.variety_allocator = _scene_allocator()
	if not reach_turns.is_empty():
		avatar.pinned_roles = [&"sit"]
	add_child(avatar)
	_after_model()
	avatar.model_changed.connect(_on_model_changed)
	built.emit(self)


func is_built() -> bool:
	return avatar != null


## Kişinin kimliği (düğüm hangi modeli gösterirse göstersin).
func person_id() -> String:
	return character_id


## Gösterilen modelin kimliği (yer tutucuda var olan modelin kimliği).
func model_id() -> String:
	return str(resolved.get("model", character_id))


func is_stand_in() -> bool:
	return bool(resolved.get("stand_in", false))


## Avatarın kişiye özel malzemeleri (renk çarpanı yalnız bunlara gider).
func own_materials() -> Array[ShaderMaterial]:
	return StandIn.own_materials(avatar) if avatar else [] as Array[ShaderMaterial]


## Kişinin yüzünü bir noktaya çevirir (yalnız y ekseninde; +Z yüzdür).
func face(point: Vector3) -> void:
	var yaw := CampNpcs.facing_yaw(global_position, point)
	if not is_nan(yaw):
		rotation.y = yaw


## Pozu ve düzeltmeleri ilk hâline döndürür (sahnenin restore'u).
func reset_pose() -> void:
	bow_amount = 0.0
	reach_amount = 0.0
	gesture_amount = 0.0
	if bow:
		bow.reset()
	if reach:
		reach.reset()
	if gesture:
		gesture.reset()


## Süren poz geçişini bitirir (sahnenin kesmesi): kişi yeni çekimde yeni pozundadır, ekranda oturup kalkmaz.
func snap_pose() -> void:
	if avatar:
		avatar.snap_transition()


## Kişinin ayakta ve yürürken (roles: oynayacağı roller) oynayacağı çeşit kliplerini şimdi kurar (model ve klip başına bir kez): sahne
## ağır işi kesmelere koyar, takılma kesmede görünmez. Model hiç bekleme klibi taşımıyor ve çeşit de atanmadıysa FALLBACK_IDLE aktarılır
## (bağışçısını ClipLibrary.donor_for seçer).
func ensure_idle(roles: Array[StringName] = WARM_ROLES) -> void:
	if avatar == null or not avatar.has_meshy_model():
		return
	avatar.warm_variety(roles)
	if avatar.available_roles().has(&"idle"):
		return
	var anim := ClipVariety.library().clip_for(avatar.model_id, ClipVariety.FALLBACK_IDLE, avatar.get_skeleton())
	if anim:
		avatar.set_role_clip(&"idle", anim)
		_apply_pose()


## Klip kaynaklarının sahnelerini (ağaç dışındaki örnekler) bırakır; kurulan klipler kalır: sahnenin restore'u ve sınama.
static func clear_cache() -> void:
	ClipVariety.release_sources()


# --- İç -------------------------------------------------------------------------------------------

## Sahnenin ortak dağıtıcısı: kişilerin üst düğümünde durur. İlk kurulan kişi bütün kardeşlerini sahnedeki sırayla kaydeder; atama
## sahnenin kişi kurma sırasına (kurulum karelere bölünür, ileri sarma sırayı değiştirir) bağlı kalmaz.
func _scene_allocator() -> ClipVariety.Allocator:
	var parent := get_parent()
	if parent == null:
		return ClipVariety.Allocator.new()
	if parent.has_meta(ClipVariety.ALLOCATOR_META):
		return parent.get_meta(ClipVariety.ALLOCATOR_META)
	var allocator := ClipVariety.Allocator.new()
	parent.set_meta(ClipVariety.ALLOCATOR_META, allocator)
	var actors: Array[CineActor] = []
	for child in parent.get_children():
		if child is CineActor:
			actors.append(child)
	# Kendi klibinde oturan kişinin oturuşu öteki kişilere verilmesin.
	for actor in actors:
		if not actor.reach_turns.is_empty():
			allocator.assign(actor.character_id, ClipVariety.GROUND_GROUP, "sit")
		elif not actor.seat_key.is_empty():
			allocator.assign(actor.character_id, ClipVariety.GROUND_GROUP, actor.seat_key)
	for actor in actors:
		var walk := actor.walk_speed if actor.walk_speed < SLOW_WALK_BELOW else WALK_FILTER_SPEED
		allocator.register(actor.character_id, {}, {"speeds": {"walk": walk}})
	return allocator


func _on_model_changed(_id: String) -> void:
	_after_model()


## Model yüklendikten (ya da değiştikten) sonra: çarpan ve ölçek, düzeltmeler, başlık, poz.
func _after_model() -> void:
	StandIn.apply(avatar, resolved.get("tint", Color.WHITE), float(resolved.get("scale", 1.0)))
	var skeleton := avatar.get_skeleton()
	bow = _modifier(skeleton, "CineBow", [], bow_amount)
	if bow:
		bow.angle_deg = bow_deg
	reach = _modifier(skeleton, "CineReach", reach_turns, reach_amount)
	gesture = _modifier(skeleton, "CineGesture", gesture_turns, gesture_amount)
	_apply_grips()
	_build_headwear(skeleton)
	_apply_pose()


func _modifier(skeleton: Skeleton3D, node_name: String, list: Array, value: float) -> CineBow:
	if skeleton == null:
		return null
	var old := skeleton.get_node_or_null(NodePath(node_name)) as CineBow
	if old:
		old.turns = list
		old.amount = value
		return old
	var mod := CineBow.new()
	mod.name = node_name
	mod.turns = list
	mod.amount = value
	skeleton.add_child(mod)
	return mod


## Elleri reach_amount ve gesture_amount'a göre kapatır: doğal el ile yumruk arası. Kavrama tanımlı değilse ya da parmak kemiği yoksa dokunmaz.
func _apply_grips() -> void:
	if avatar == null or avatar.hand_grip == null or (reach_grips.is_empty() and gesture_grips.is_empty()):
		return
	for side: StringName in HandGrip.SIDES:
		var share := maxf(float(reach_grips.get(side, 0.0)) * reach_amount, float(gesture_grips.get(side, 0.0)) * gesture_amount)
		avatar.hand_grip.set_shape(side, HandGrip.blend(HandGrip.NATURAL_SHAPE, HandGrip.FIST_SHAPE, share))


func _apply_pose() -> void:
	if avatar == null:
		return
	match pose:
		&"sit":
			avatar.play_pose(&"sit")
		&"walk":
			avatar.play_walk(walk_speed)
		_:
			avatar.set_locomotion(0.0)


## Başlık: stand_in.headwear (band: alın bağı, cap: keçe başlık ve bandı, fur_hat: kürk börk ve kızıl tepe, kerchief:
## baş örtüsü ve ense kanadı). Head kemiğine bağlanır; yeri ve yönü dinlenme pozundaki Head → head_end çizgisinden.
func _build_headwear(skeleton: Skeleton3D) -> void:
	if headwear and is_instance_valid(headwear):
		headwear.get_parent().remove_child(headwear)
		headwear.queue_free()
	headwear = null
	var spec: Variant = StandIn.meta(character_id, root).get("stand_in", {})
	var hat: Variant = (spec as Dictionary).get("headwear") if spec is Dictionary else null
	if not is_stand_in() or skeleton == null or not hat is Dictionary:
		return
	var head := skeleton.find_bone("Head")
	var top := skeleton.find_bone("head_end")
	if head < 0 or top < 0:
		return
	var h: Dictionary = hat
	var head_rest := skeleton.get_bone_global_rest(head)
	var top_local := head_rest.affine_inverse() * skeleton.get_bone_global_rest(top).origin
	var up := top_local.normalized() if top_local.length() > 0.001 else Vector3.UP
	var attach := BoneAttachment3D.new()
	attach.name = "Headwear"
	attach.bone_name = "Head"
	skeleton.add_child(attach)
	var pivot := Node3D.new()
	pivot.name = "Hat"
	# Kemik uzayı iskeletin birimindedir (Meshy iskeletinde model ölçeği 0,01: santimetre); başlığın ölçüleri metredir.
	var unit := CineActor.skeleton_unit(skeleton, avatar.get_model_node())
	var drop := float(h.get("drop", 0.05)) / unit
	pivot.transform = Transform3D(Basis(Quaternion(Vector3.UP, up)).scaled(Vector3.ONE / unit), top_local - up * drop)
	attach.add_child(pivot)
	CineActor.hat_parts(h, pivot)
	headwear = attach


## İskeletin modele göre ölçeği (saf): modelin kökünden iskelete inen düğümlerin ölçeği (Meshy iskeletinde 0,01).
static func skeleton_unit(skeleton: Skeleton3D, model: Node3D) -> float:
	var unit := 1.0
	var node: Node = skeleton
	while node != null and node != model:
		if node is Node3D:
			unit *= (node as Node3D).transform.basis.get_scale().y
		node = node.get_parent()
	return maxf(unit, 0.000001)


## Başlığın parçaları (saf kurucu): pivot'un +Y'si başın tepesine bakar, merkez tepe noktasının drop altındadır.
static func hat_parts(h: Dictionary, pivot: Node3D) -> void:
	var r := float(h.get("radius", 0.1))
	var height := float(h.get("height", 0.08))
	var color := StandIn.parse_tint(h.get("color", "#6b5040"))
	var mat := Style.toon(color, {"brush_strength": 0.15})
	match str(h.get("shape", "cap")):
		"band":
			_hat_mesh(pivot, "Band", _ring(r * 1.02, r * 1.05, height), mat, Vector3(0.0, -height * 0.2, 0.0))
		"cap":
			_hat_mesh(pivot, "Crown", Procedural3D.sphere(r, 0.75), mat, Vector3(0.0, height * 0.2, 0.0))
			var band := Style.toon(StandIn.parse_tint(h.get("band", "#8a2a1e")), {"brush_strength": 0.1})
			_hat_mesh(pivot, "Band", _ring(r * 1.04, r * 1.06, height * 0.45), band, Vector3(0.0, -height * 0.1, 0.0))
		"fur_hat":
			_hat_mesh(pivot, "Fur", Procedural3D.cylinder(r * 1.12, r * 1.08, height, HAT_SEGMENTS), mat, Vector3(0.0, 0.0, 0.0))
			var top := Style.toon(StandIn.parse_tint(h.get("top", "#7a1c18")), {"brush_strength": 0.1})
			_hat_mesh(pivot, "Top", Procedural3D.sphere(r * 0.9, 0.8), top, Vector3(0.0, height * 0.45, 0.0))
		"kerchief":
			_hat_mesh(pivot, "Cover", Procedural3D.sphere(r * 1.06, 0.95), mat, Vector3(0.0, 0.0, -r * 0.08))
			_hat_mesh(pivot, "Flap", Procedural3D.box(Vector3(r * 1.5, height * 1.6, r * 0.25)), mat,
					Vector3(0.0, -height * 0.9, -r * 0.85))


## Kapaksız şerit (alın bağı, başlığın bandı): başın tepesini örtmez.
static func _ring(r_top: float, r_bottom: float, height: float) -> CylinderMesh:
	var mesh := Procedural3D.cylinder(r_top, r_bottom, height, HAT_SEGMENTS)
	mesh.cap_top = false
	mesh.cap_bottom = false
	return mesh


static func _hat_mesh(pivot: Node3D, node_name: String, mesh: Mesh, mat: Material, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	pivot.add_child(mi)
