@tool
class_name CampNpcs
extends Node3D
## Kamp ateşinin başında oturan NPC'ler (Meshy modelleri, gerçek boylarıyla). Bu düğüm ateşin merkezine
## konur; alt düğümlerdeki her CharacterAvatar ateşe (bu düğümün merkezine) döndürülür. Düğüm taşınsa da
## (ör. editörde ya da kamp düzeni değişince) karakterler ateşe bakmaya devam eder.
##
## Ocak halkı Göl Obası'nın ocağıdır (K37, K106): Ana, Çocuk, Baba, Ağabey ve Ozan; Mete burada yoktur. Ağabey kendi Meshy
## modeliyle oturur; modeli olmasaydı yer tutucusu renk çarpanı ve ölçekle gösterilirdi (K89; StandIn, stand_ins).
##
## Karakterin eşyaları (ozanın kucağındaki kopuz, Ağabey'in yanındaki yay) o karakterin alt düğümüdür: karakterle
## birlikte döner ve karakter gizlenince onunla birlikte gizlenir. Düğümün kendisi döndürüldüğü için eşyalar
## karakterin "ateşe bakan" yerel uzayında yerleştirilir (+Z = ateşe doğru, +X = karakterin solu).
##
## Oyuncu kamptaki karakterlerden birinin modeliyle gezerken, oturan kopyası gizlenir:
##   camp_npcs.set_hidden_model("child")    # Çocuk'u gizler, diğerlerini gösterir
##   camp_npcs.set_hidden_model("")         # herkesi gösterir
## Serbest Gez'de oyuncu Çocuk'tur (K37): oturan kopyası gizlenir, oyuncu aynı yerde aynı oturuşla belirir ve ilk harekette kalkar. child_seat() yeri ve klibin anını verir;
## set_seat_left(true) gizlenen Çocuk'un kütüğünü yerde bırakır (kalktığı kütük kaybolmasın). Menüde kimse gizli değildir: menü karesi değişmez.
##
## Ateş başının oturuşları elle seçilmiştir (SEATS; kişilerin öteki rolleri ClipVariety'den): menünün ilk karesidir, beş kişinin
## beş ayrı duruşu ateşin çevresinde bir aile resmi kurar. Kişiler sahne ağaca girerken dağıtıcıya kaydolur, klipler modelleri
## yüklenirken bir kez kurulur (bkz. _enter_tree): önce oturuş, sonra yeniden yükleme olmaz.

## Ozanın düğümü ve kucağındaki kopuz (Önsöz'ün kamp sahnesi kaldırır ve çaldırır).
const BARD := ^"Elder"
const KOPUZ := ^"Elder/Kopuz"
## Düğüm adı → yer oturuşu (sit_ground). Seçimin gerekçesi:
##   Mother        ground_kneel_heels: topukları üstünde diz çöker, elleri uyluklarında. Çocuğu tam önünde oturur, ateşe uzanan kol çocuğun başına
##                 girerdi; dizleri kalçasının ≈36 cm önünde, çocuğun ≈7 cm gerisinde biter: kucak gibi yakın, içine girmez (köşelerle ölçüldü, 2026-11-07;
##                 bkz. test_camp_npcs). ground_side_sit'te etek önde fıçı gibi duruyor, çizmeler iki yandan çıkıyor, sol çizme havada kalıyordu.
##   Child         ground_hug_knees: dizlerini kucaklayan çocuk, bakışı ozanda (Önsöz'de ozana döner). Bu klip kalçayı havada
##                 tutar: altına alçak bir kütük konur (Child/SeatLog; SEAT_LOG).
##   Father        ground_warm_hands: ocağın başı ellerini ateşe tutar; ateşin ışığı ellerine ve yüzüne vurur, kadrajın sıcak odağı.
##   OlderBrother  ground_one_knee: bir dizi dik, kolu dizinde; yayı yanında, gözü çevrede: tetikte genç savaşçı.
##   Elder         sit: kendi bağdaşı. Kopuz bu pozda kucağa oturur, çalışı (KopuzPlay) bu poza ayarlıdır; Önsöz'de bozulmaz.
## Baba ve Ağabey'in ayak eklemleri bu kliplerde düğümden 0,7-0,8 m öne uzanır: taş halkaya (ateşin merkezinden 0,8 m) girmesinler diye düğümleri
## bağdaştaki yerlerinden 0,2 m geridedir (ayağın en yakın köşesi ile halka arası Baba 10 cm, Ağabey 8 cm, 2026-11-07; bkz. test_camp_npcs). Bu iki klipte ayak ve baldır zemindeyken kalça
## 9-15 cm havadaydı: klip kurulurken kalça kişinin ölçüsü kadar iner, bilekler yerinde kalır (ClipLibrary.fit_legs). Göz onayı kullanıcınındır.
const SEATS := {"Mother": "ground_kneel_heels", "Child": "ground_hug_knees", "Father": "ground_warm_hands",
	"OlderBrother": "ground_one_knee", "Elder": "sit"}
## Çocuğun oturduğu kütük (Child/SeatLog; karakterle döner, karakterle gizlenir). Ölçüler çocuğun bu klipteki duruşundan: kalçaya
## baskın köşelerin en altı zeminden ≈10,6 cm (bkz. test_camp_npcs), kütüğün üstü oraya değer; karakterin yerel uzayında.
const CHILD := ^"Child"
const SEAT_LOG_NAME := "SeatLog"
## Çocuk ateşten kalkınca yerde kalan kütüğün kopyası.
const LEFT_LOG_NAME := "SeatLogLeft"
const SEAT_LOG := {"radius": 0.053, "length": 0.42, "z": 0.03, "segments": 12}

## Yer tutucular (K89): düğüm adı → kişinin kimliği (assets/characters/<id>/). Kimliğin kendi modeli
## (<id>.glb) yoksa meta.json'un stand_in kaydı çalışırken çözülür: avatar o modeli renk çarpanı ve ölçekle
## gösterir. Sahnedeki model_override kişininkini tutmuyorsa, model yüklenmeden önce kimliğe çevrilir (_enter_tree).
@export var stand_ins := {"OlderBrother": "older_brother"}

## Gizlenen modelin kimliği ("" = kimse gizli değil).
var hidden_model := ""
## Çocuk ateşten kalktı: kütüğü (kopyası) yerde kalır.
var seat_left := false
## Çözülen yer tutucular: düğüm adı → StandIn.resolve sonucu.
var resolved := {}
## Ateş başının çeşit dağıtıcısı.
var allocator: ClipVariety.Allocator


## Kişiler, modelleri yüklenmeden önce çözülür (üst düğüm ağaca önce girer): sahnedeki model_override kişininkini tutmuyorsa model
## iki kez yüklenmez, oturuş kişinin ilk karesinde doğrudur.
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	resolve_stand_ins()
	_assign_variety()


func _ready() -> void:
	set_notify_transform(true)
	if not Engine.is_editor_hint():
		_build_seat_log()
		ClipVariety.release_sources()
	aim_at_center()
	_apply_visibility()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		aim_at_center()


## Yer tutucuları çözer ve uygular (bkz. stand_ins). Model yeniden yüklenirse (model_changed) çarpan yeniden
## uygulanır. root: kişilerin klasörü (testler sahte bir klasör verir).
func resolve_stand_ins(root: String = StandIn.ROOT) -> void:
	for node_name: Variant in stand_ins:
		var avatar := get_node_or_null(NodePath(str(node_name))) as CharacterAvatar
		if avatar == null:
			continue
		var r := StandIn.resolve(str(stand_ins[node_name]), root)
		resolved[str(node_name)] = r
		avatar.set_meta(StandIn.PERSON_META, r["id"])
		if avatar.model_override != r["model"]:
			avatar.model_override = r["model"]
		StandIn.apply(avatar, r["tint"], r["scale"])
		var reapply := _reapply_stand_in.bind(avatar)
		if not avatar.model_changed.is_connected(reapply):
			avatar.model_changed.connect(reapply)


## Tüm karakterleri bu düğümün merkezine (ateşe) döndürür.
func aim_at_center() -> void:
	if not is_inside_tree():
		return
	for avatar in get_avatars():
		var yaw := CampNpcs.facing_yaw(avatar.position, Vector3.ZERO)
		if not is_nan(yaw):
			avatar.rotation = Vector3(0.0, yaw, 0.0)
		avatar.face_point = global_position


## Bu model kimliğini kullanan karakteri (ve eşyalarını) gizler, diğerlerini gösterir.
## Boş kimlik herkesi gösterir. Karakterler henüz yüklenmemiş olsa da çalışır (model_override'a bakar).
func set_hidden_model(id: String) -> void:
	hidden_model = id
	_apply_visibility()


## Çocuk ateşten kalktı mı (kütüğü yerde kalır)? Gizleme set_hidden_model'dedir.
func set_seat_left(left: bool) -> void:
	seat_left = left
	_apply_visibility()


## Çocuğun oturduğu yer: {transform (dünya; ön yüzü ateşe), clip_time (oturuş klibinin anı)}. Çocuk yoksa boş.
func child_seat() -> Dictionary:
	var child := get_node_or_null(CHILD) as CharacterAvatar
	if child == null or not child.is_inside_tree():
		return {}
	var anim := child.get_animation_player()
	return {"transform": child.global_transform, "clip_time": anim.current_animation_position if anim and anim.is_playing() else -1.0}


## Alt düğümlerdeki karakterler (sahnedeki sırayla).
func get_avatars() -> Array[CharacterAvatar]:
	var result: Array[CharacterAvatar] = []
	for child in get_children():
		if child is CharacterAvatar:
			result.append(child)
	return result


## Bu model kimliğini kullanan ilk karakter (yoksa null).
func get_avatar_for_model(id: String) -> CharacterAvatar:
	for avatar in get_avatars():
		if CampNpcs.avatar_model_id(avatar) == id:
			return avatar
	return null


## Bu kişiyi (kimlik: older_brother, elder...) gösteren karakter; yer tutucuda kişinin kimliği, yoksa model
## kimliği aranır (yoksa null).
func get_avatar_for_person(id: String) -> CharacterAvatar:
	for avatar in get_avatars():
		if CampNpcs.person_id(avatar) == id:
			return avatar
	return null


## Ozan (kopuzu kucağında) ve kopuzu.
func get_bard() -> CharacterAvatar:
	return get_node_or_null(BARD) as CharacterAvatar


func get_kopuz() -> Kopuz:
	return get_node_or_null(KOPUZ) as Kopuz


# --- Saf yardımcılar (test edilebilir) --------------------------------------------

## from noktasındaki karakterin +Z yüzünü to noktasına çeviren dönüş açısı (radyan, Y ekseni).
## İki nokta yatayda üst üste ise NAN döner (yön tanımsız).
static func facing_yaw(from: Vector3, to: Vector3) -> float:
	var d := Vector2(to.x - from.x, to.z - from.z)
	if d.length_squared() < 0.000001:
		return NAN
	return atan2(d.x, d.y)


## Karakterin görünür olup olmayacağı: gizlenen kimlik boşsa herkes görünür.
static func is_visible_for(model_id: String, hidden_id: String) -> bool:
	return hidden_id.is_empty() or model_id != hidden_id


## Karakterin model kimliği: yüklenmişse model_id, yoksa sahnede seçilen model_override.
static func avatar_model_id(avatar: CharacterAvatar) -> String:
	return avatar.model_id if not avatar.model_id.is_empty() else avatar.model_override


## Karakterin kişi kimliği: yer tutucuysa çözülen kimlik (ör. older_brother), değilse model kimliği.
static func person_id(avatar: CharacterAvatar) -> String:
	if avatar.has_meta(StandIn.PERSON_META):
		return str(avatar.get_meta(StandIn.PERSON_META))
	return CampNpcs.avatar_model_id(avatar)


## Karakterleri dağıtıcıya kaydeder: önce elle seçilen oturuşlar (öteki kişiler onları almasın), sonra sahnedeki sırayla kişiler.
func _assign_variety() -> void:
	if allocator:
		return
	allocator = ClipVariety.Allocator.new()
	var avatars := get_avatars()
	for avatar in avatars:
		if SEATS.has(String(avatar.name)):
			allocator.assign(CampNpcs.person_id(avatar), ClipVariety.GROUND_GROUP, SEATS[String(avatar.name)])
	for avatar in avatars:
		var person := CampNpcs.person_id(avatar)
		allocator.register(person)
		avatar.variety_person = person
		avatar.variety_allocator = allocator


## Çocuğun altındaki kütük (Meshy modeli yüklüyse: chibi yedeği bağdaş kurar, kütüğe gerek yok). Kodla çizilir.
func _build_seat_log() -> void:
	var child := get_node_or_null(CHILD) as CharacterAvatar
	if child == null or not child.has_meshy_model() or child.has_node(SEAT_LOG_NAME):
		return
	var radius := float(SEAT_LOG["radius"])
	var log_mesh := MeshInstance3D.new()
	log_mesh.name = SEAT_LOG_NAME
	log_mesh.mesh = Procedural3D.cylinder(radius * 0.94, radius, float(SEAT_LOG["length"]), int(SEAT_LOG["segments"]))
	log_mesh.material_override = Style.toon(Style.WOOD_DARK, {"brush_strength": 0.2})
	# Silindir yatık, karakterin omuzlarına koşut (yerel X).
	log_mesh.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, radius, float(SEAT_LOG["z"])))
	child.add_child(log_mesh)


func _reapply_stand_in(_model_id: String, avatar: CharacterAvatar) -> void:
	var r: Dictionary = resolved.get(str(avatar.name), {})
	if not r.is_empty() and is_instance_valid(avatar):
		StandIn.apply(avatar, r["tint"], r["scale"])


func _apply_visibility() -> void:
	for avatar in get_avatars():
		avatar.visible = CampNpcs.is_visible_for(CampNpcs.avatar_model_id(avatar), hidden_model)
	_apply_left_log()


## Ateşten kalkan Çocuk'un kütüğü: oturan kopya gizliyken kütüğün kopyası aynı yerde durur (gerekene dek kurulmaz: menüde çizim eklemez).
func _apply_left_log() -> void:
	var child := get_node_or_null(CHILD) as CharacterAvatar
	var seat := child.get_node_or_null(SEAT_LOG_NAME) as MeshInstance3D if child else null
	var left := seat_left and seat != null and not child.visible
	var kept := get_node_or_null(LEFT_LOG_NAME) as MeshInstance3D
	if left and kept == null and is_inside_tree():
		kept = seat.duplicate() as MeshInstance3D
		kept.name = LEFT_LOG_NAME
		add_child(kept)
		kept.global_transform = seat.global_transform
	if kept:
		kept.visible = left
