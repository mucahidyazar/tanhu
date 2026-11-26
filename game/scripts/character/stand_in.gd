class_name StandIn
extends RefCounted
## Yer tutucu kişi modelleri (K89): kendi Meshy modeli olmayan bir kişi, var olan bir modelle (bugün iki Lan kadını: Hun
## Kadını'nın ağı), kendi renk çarpanı ve ölçeğiyle gösterilir. Kişi her zaman kendi
## kimliğini ve düğüm yolunu taşır; Meshy modeli gelince yalnız assets/characters/<id>/<id>.glb eklenir, kod ve
## sahne değişmez.
##
## Kayıt kişinin klasöründeki meta.json'dadır (glb'siz klasör):
##   {"id": "older_brother", ..., "stand_in": {"model": "father", "tint": "#8090b0", "scale": 0.95}}
##   tint: "#rrggbb" ya da [r, g, b] (0..1); scale: modelin ölçeği (model_scale).
##
##   var r := StandIn.resolve("older_brother")   # {id, model: "father", tint, scale: 0.95, stand_in: true}
##   avatar.model_override = r["model"]
##   StandIn.apply(avatar, r["tint"], r["scale"])  # avatar modelini yükledikten sonra
##
## Renk çarpanı yalnız o avatarın kendi malzemelerine gider: CharacterAvatar Meshy modelinin her yüzeyine kişiye
## özel bir ShaderMaterial kurar (albedo_tint); aynı modeli kullanan öteki kişiler (ör. Baba) etkilenmez. Chibi
## yedeğinin malzemeleri paylaşılır (Style önbelleği): orada renk çarpanı uygulanmaz, yalnız ölçek.

const ROOT := "res://assets/characters"
const META_FILE := "meta.json"
## Avatarda çözülen kişinin kimliği ve uygulanan çarpan (meta veri).
const PERSON_META := &"person_id"
const TINT_META := &"stand_in_tint"
## Malzemenin çarpandan önceki albedo_tint'i (meta veri): uygulama tekrarlanınca çarpan birikmez.
const BASE_TINT_META := &"stand_in_base_tint"


## Kişinin glb yolu (saf).
static func model_path(id: String, root: String = ROOT) -> String:
	return root.path_join(id).path_join("%s.glb" % id)


## Kişinin kendi modeli var mı? (İçe aktarılmış kaynak ya da diskteki dosya.)
static func has_model(id: String, root: String = ROOT) -> bool:
	if id.is_empty():
		return false
	var path := model_path(id, root)
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## Kişinin meta.json'u (yoksa ya da bozuksa boş).
static func meta(id: String, root: String = ROOT) -> Dictionary:
	var path := root.path_join(id).path_join(META_FILE)
	if id.is_empty() or not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("[stand_in] %s okunamadı: %s" % [path, json.get_error_message()])
		return {}
	return json.data if json.data is Dictionary else {}


## Kişinin gösterilecek modeli: {id, model, tint (Color), scale (float), stand_in (bool)}.
##   - <id>.glb varsa kişinin kendi modeli (çarpan beyaz, ölçek 1),
##   - yoksa meta.json'un stand_in kaydı,
##   - o da yoksa kimliğin kendisi (CharacterAvatar chibi yedeğine düşer).
static func resolve(id: String, root: String = ROOT) -> Dictionary:
	var own := {"id": id, "model": id, "tint": Color.WHITE, "scale": 1.0, "stand_in": false}
	if has_model(id, root):
		return own
	var record: Variant = meta(id, root).get("stand_in")
	if not record is Dictionary or not (record as Dictionary).get("model") is String:
		return own
	var model := str(record["model"])
	if model.is_empty() or model == id:
		return own
	return {
		"id": id,
		"model": model,
		"tint": parse_tint(record.get("tint")),
		"scale": maxf(float(record.get("scale", 1.0)), 0.01),
		"stand_in": true,
	}


## "#rrggbb" ya da [r, g, b(, a)] (0..1) → Color; okunamazsa beyaz (saf).
static func parse_tint(value: Variant) -> Color:
	if value is String and Color.html_is_valid(value):
		return Color.html(value)
	if value is Array and (value as Array).size() >= 3:
		var a: Array = value
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	return Color.WHITE


## Avatarın kendi malzemelerine renk çarpanı (albedo_tint × tint) ve modele ölçek (model_scale) uygular. Tekrar
## çağrılabilir: çarpan malzemenin ilk albedo_tint'ine uygulanır, birikmez. Döner: çarpanı alan yüzey sayısı.
static func apply(avatar: CharacterAvatar, tint: Color, scale: float) -> int:
	if avatar == null:
		return 0
	avatar.model_scale = scale
	avatar.set_meta(TINT_META, tint)
	var count := 0
	for mat in own_materials(avatar):
		if not mat.has_meta(BASE_TINT_META):
			var base: Variant = mat.get_shader_parameter("albedo_tint")
			mat.set_meta(BASE_TINT_META, base if base is Color else Color.WHITE)
		var base_tint: Color = mat.get_meta(BASE_TINT_META)
		mat.set_shader_parameter("albedo_tint", base_tint * tint)
		count += 1
	return count


## Avatarın Meshy modelinde kişiye özel yüzey malzemeleri (CharacterAvatar'ın kurduğu, albedo_tint taşıyan
## ShaderMaterial'lar). Chibi yedeğinde ve model yokken boş.
static func own_materials(avatar: CharacterAvatar) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var model := avatar.get_model_node()
	if model == null or not avatar.has_meshy_model():
		return out
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s) as ShaderMaterial
			if mat and mat.shader == CharacterAvatar.CHARACTER_SHADER and not out.has(mat):
				out.append(mat)
	return out
