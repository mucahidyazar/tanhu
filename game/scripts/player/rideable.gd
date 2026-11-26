class_name Rideable
extends Node3D
## Binilen hayvanın ortak tabanı (koyun, at; godot.md §3 «Binicilik», fauna.md §2.1): Mount satırı (data/fauna/mounts.json), binilme durumu,
## yere konma (place), sırttaki oturma noktası (seat_transform; iskeletli modelde gövde kemiğini izler: binici hayvanla iner kalkar, yatar),
## modelin ölçüleri (<model>.json; tools/blender/quadruped_rig.py yazar) ve klip adlarının rollere eşlenmesi. Tür kendi modelini ve canlandırmasını
## kurar (RideableSheep, RideableHorse); PlayerController ve StoryMover yalnız bu yüzü kullanır:
##   ride.set_ridden(true); ride.drive(speed, delta); ride.place(pos, yaw, pitch)
##   ride.seat_transform()      # binicinin kalçasının oturduğu yüzün dünya dönüşümü (ön yüz yerel +Z)
## Yerel +Z başın baktığı yöndür; düğümün yeri ayakların zeminidir. Binilebilir hayvanlar GROUP'tadır.
## Sıçrama (2026-11-08): can_leap, leap, is_leaping, is_airborne, leap_phase, leap_lift, leap_ground_speed, cancel_leap. Taban sıçramaz (koyun); at sıçrar
## (RideableHorse): havadaki yay gövdeyi (Body) kaldırır, düğüm yerde kalır, binici oturma noktasıyla kalkar.
## Toynaklar (2026-11-08, Yol Haritası horse-rig): zemin verilince (set_ground; PlayerController binerken kendi zeminini verir, iç haritanın bineği
## kendiliğinden bulur) toynaklar TwoBoneIK3D ile gerçek zemine basar (RideableHooves): eğimde, yan yamaçta, basamakta; gövde gerekirse iner.
## Zemini verilmeyen binek (kampın ve menünün atları, K58) klibin pozunda kalır. Bineğin kaydının anahtarı mount_key()'dir (MountStable, terki).

## Binilebilir hayvanların grubu.
const GROUP := &"mounts"
## Sıçramanın evresi: yok, hazırlık (toplanma, itiş), havada, iniş.
enum LeapPhase { NONE, PREP, AIR, LAND }
## Binicinin izlediği gövde kemiği (iskeletli modelde; <model>.json saddle_bone yazarsa o).
const SEAT_BONE := "Spine"

## Mount satırının kimliği (data/fauna/mounts.json).
@export var mount_id := "sheep"

var mount: Mount
var ridden := false
## Modelin ölçüleri (<model>.json; model yoksa ya da dosya yoksa boş).
var meta: Dictionary = {}

## Toynakların zemini (set_ground): height_at(x, z) taşıyan nesne ya da Callable; yoksa toynaklar klibin pozundadır.
var ground: Variant

var _body: Node3D
var _seat: Node3D
var _model: Node3D
var _anim: AnimationPlayer
var _skeleton: Skeleton3D
var _seat_bone := -1
var _seat_rest := Transform3D.IDENTITY
var _hoof_rig: RideableHooves
## Sırtın ve arka bacakların yükseklik alanları (RideFit.BackField.quadruped; back_clearance).
var _back_fields: Array = []


## Silinirken modelin yüzey malzemeleri önce bırakılır: ağ başka bir atta yaşarken çizim sunucusu silinen malzemenin örnek parametrelerini okumasın
## (CharacterAvatar._release_materials ile aynı sorun: «Parameter "material" is null»).
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _model and is_instance_valid(_model):
		CharacterAvatar._release_materials(_model)


## Çizim yerine model mi gösteriliyor?
func uses_model() -> bool:
	return _model != null


func get_mount() -> Mount:
	return mount


## Binek türü (Mount satırının kimliği: sheep, horse).
func mount_kind() -> String:
	return mount.id if mount else mount_id


## Bineğin kaydının ve terkisinin anahtarı: «<satır>@<düğüm>» (kampın atında düğüm «Ride», adı ebeveyninindir; HudBag ile aynı kural).
func mount_key() -> String:
	var owner_name := str(get_parent().name) if name == "Ride" and get_parent() else str(name)
	return "%s@%s" % [mount_kind(), owner_name]


## Toynakların zeminini verir (RideableHooves kurulur; iskeletsiz bineğe bir şey olmaz). null toynakları klibin pozuna bırakır.
func set_ground(p_ground: Variant) -> void:
	ground = p_ground
	if p_ground == null:
		if _hoof_rig and is_instance_valid(_hoof_rig):
			_hoof_rig.detach()
		_hoof_rig = null
		_update_body(0.0)
		return
	if _skeleton == null:
		return
	if _hoof_rig == null or not is_instance_valid(_hoof_rig):
		_hoof_rig = RideableHooves.attach(_skeleton, p_ground, _model)
	else:
		_hoof_rig.ground = p_ground


## Toynakların kurulumu (zemin yoksa ya da iskeletsizse null).
func hooves() -> RideableHooves:
	return _hoof_rig if _hoof_rig and is_instance_valid(_hoof_rig) else null


## İç haritanın (MapWorld) bineği zeminini kendisi bulur (kampın atları bulmaz: menü karesi değişmez).
func _find_map_ground() -> void:
	if ground != null or not is_inside_tree():
		return
	var node := get_parent()
	while node:
		if node is MapWorld:
			set_ground((node as MapWorld).get_terrain_shape())
			return
		node = node.get_parent()


## Gövdenin yüksekliği (Body): sıçramanın yayı eksi toynakların indirişi. delta > 0 ise iniş hedefine yaklaşır.
func _update_body(delta: float) -> void:
	var offset := 0.0
	var hooves := hooves()
	if hooves:
		hooves.active = not is_airborne()
		offset = hooves.step_offset(delta) if delta > 0.0 else hooves.body_offset
	if _body:
		_body.position.y = leap_lift() - offset


## Noktanın (dünya) bineğin sırtının üstündeki yüksekliği (m; artı üstte, eksi gövdenin içinde; sırtın alanı dışında INF): binicinin pelerini
## sağrıya buna göre serilir (RideCape). İskeletsiz bineğin sırtı bilinmez: INF.
func back_clearance(p: Vector3) -> float:
	if _skeleton == null or _model == null:
		return INF
	if _back_fields.is_empty():
		var meshes := _model.find_children("*", "MeshInstance3D", true, false)
		if meshes.is_empty():
			return INF
		_back_fields = RideFit.BackField.quadruped(meshes[0] as MeshInstance3D, _skeleton)
	var best := INF
	for field: RideFit.BackField in _back_fields:
		best = minf(best, field.clearance(_skeleton, p))
	return best


## Gövdenin toynaklarla inişi (m, artı aşağı).
func body_offset() -> float:
	var hooves := hooves()
	return hooves.body_offset if hooves else 0.0


## Binildi / inildi (tür ayrıca kendi durumunu sıfırlar).
func set_ridden(on: bool) -> void:
	ridden = on


## Binilirken bir adım: hız m/sn (tür canlandırır).
func drive(_speed: float, _delta: float) -> void:
	pass


## Yere koyar: yer (ayakların zemini), yaw (ön yüzün açısı; 0 = +Z), pitch (zeminin eğimi, artı öne aşağı).
func place(pos: Vector3, yaw: float, pitch: float = 0.0) -> void:
	var xform := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch), pos)
	if is_inside_tree():
		global_transform = xform
	else:
		transform = xform


## Oturma noktasının (sırtın yüzü) dünya dönüşümü (ön yüz yerel +Z): gövde kemiği klipte iner kalkar, eğilir; binici onunla gider. Gövde (Body) kalkmışsa
## (sıçramanın yayı) kemiğin hareketi gövdenin yerinde uygulanır.
func seat_transform() -> Transform3D:
	var at := _seat.global_transform if _seat and _seat.is_inside_tree() else global_transform
	if _skeleton and _seat_bone >= 0:
		var pose := _skeleton.get_bone_global_pose(_seat_bone)
		var moved := pose * _seat_rest.affine_inverse()
		var lift := _body.position if _body else Vector3.ZERO
		var local_seat := to_local(at.origin) - lift
		return Transform3D(global_basis * moved.basis.orthonormalized(), to_global(moved * local_seat + lift))
	return at


# --- Sıçrama (taban sıçramaz; at: RideableHorse) -------------------------------------------------------

## Binicisiyle sıçrayabilir mi (satırın jump'ı ve türün sıçraması)?
func can_leap() -> bool:
	return false


## Sıçrar: speed sıçrayıştaki hız (m/sn). Sıçradıysa true.
func leap(_speed: float) -> bool:
	return false


## Sıçrıyor mu (toplanmadan toparlanmaya dek)?
func is_leaping() -> bool:
	return false


## Havada mı (dört toynak yerden kalkık)?
func is_airborne() -> bool:
	return false


func leap_phase() -> LeapPhase:
	return LeapPhase.NONE


## Gövdenin havadaki kalkışı (m; yay, yerde 0).
func leap_lift() -> float:
	return 0.0


## Süren sıçramanın planı (Mount.jump_plan ve klibin evreleri; sıçramıyorken boş).
func leap_plan() -> Dictionary:
	return {}


## Basan toynağın klipte geri kayma hızı (m/sn; düğüm bu hızla giderse ayak yerde kaymaz); havada ya da sıçramıyorken -1.
func leap_ground_speed() -> float:
	return -1.0


## Süren sıçramayı hemen bitirir (gövde yere iner).
func cancel_leap() -> void:
	pass


## Şu an oynayan modelin klibi (modelsizde boş).
func model_clip() -> StringName:
	return _anim.assigned_animation if _anim else &""


## Engel olarak gövdesi (binilmezken; dünya x, z): yatay kutu, satırın half_length'i ve radius'u (yoksa daire gibi kare).
func obstacle_box() -> ObstacleBox:
	var half_length := mount.value("half_length") if mount else 0.0
	var radius := mount.value("radius") if mount else 0.4
	var xform := global_transform if is_inside_tree() else transform
	return ObstacleBox.from_transform(Transform3D(Basis(Vector3.UP, xform.basis.get_euler().y), xform.origin), Vector2(radius * 0.8, half_length + radius * 0.8))


# --- Ortak yardımcılar ----------------------------------------------------------------------------

## Modelin ölçü dosyası (<model>.json; yoksa boş).
static func read_meta(path: String) -> Dictionary:
	var meta_path := path.get_basename() + ".json"
	if not FileAccess.file_exists(meta_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	return parsed if parsed is Dictionary else {}


## Oturma noktası (düğüm uzayı, saf): modelin ölçüsü (saddle_y, saddle_z) varsa o, yoksa satırın seat'i.
static func saddle_point(p_meta: Dictionary, seat: Dictionary) -> Vector3:
	var y := float(p_meta.get("saddle_y", seat.get("saddle_y", 0.7)))
	var z := float(p_meta.get("saddle_z", seat.get("saddle_z", 0.0)))
	return Vector3(0.0, y, z)


## Klip adlarını rollere eşler (saf): table rol → aranan parçalar (sırayla), büyük küçük harf ayrımsız; bulunamayan rol yoktur.
static func clips_by_role(names: PackedStringArray, table: Dictionary) -> Dictionary:
	var out := {}
	for role: StringName in table:
		for part: String in table[role]:
			for clip_name in names:
				if clip_name.to_lower().contains(part):
					out[role] = StringName(clip_name)
					break
			if out.has(role):
				break
	return out


## Modelin malzemesi karakterlerin yumuşak toon'una döner (dokuyu korur; K92'nin kişileriyle aynı ışık).
static func to_toon(mi: MeshInstance3D, ink: float = 0.3) -> void:
	for s in mi.mesh.get_surface_count():
		var source := mi.get_active_material(s)
		var mat := ShaderMaterial.new()
		mat.shader = CharacterAvatar.CHARACTER_SHADER
		if source is BaseMaterial3D:
			mat.set_shader_parameter("albedo_texture", (source as BaseMaterial3D).albedo_texture)
			mat.set_shader_parameter("albedo_tint", (source as BaseMaterial3D).albedo_color)
		mat.set_shader_parameter("ink_strength", ink)
		mi.set_surface_override_material(s, mat)


# --- Kurulum (türler çağırır) ----------------------------------------------------------------------

## Gövde ve oturma noktası düğümleri (modelden önce).
func _make_body() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)


func _make_seat(seat: Dictionary) -> void:
	_seat = Node3D.new()
	_seat.name = "Seat"
	_seat.position = Rideable.saddle_point(meta, seat)
	_body.add_child(_seat)


## İskeletli, klipli modeli gövdeye kurar (klipsizse kurmaz ve null döner). Klipler döngülüdür; oturma kemiği bulunur, malzeme toon'a döner.
func _load_model(path: String, node_name: String, ink: float = 0.3) -> Node3D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	var root := scene.instantiate() as Node3D if scene else null
	if root == null:
		return null
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		root.free()
		return null
	_model = root
	_model.name = node_name
	_body.add_child(_model)
	_anim = players[0] as AnimationPlayer
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	_skeleton = skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
	if _skeleton:
		_seat_bone = _skeleton.find_bone(str(meta.get("saddle_bone", SEAT_BONE)) if not meta.is_empty() else SEAT_BONE)
		_seat_rest = _skeleton.get_bone_global_rest(_seat_bone) if _seat_bone >= 0 else Transform3D.IDENTITY
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		Rideable.to_toon(node as MeshInstance3D, ink)
	return _model
