class_name Folk
extends RefCounted
## Kodla kişi üretici (Yol Haritası folk-generator; act1.md §3, army.md §7.3, godot.md §4.5): tohumdan bir kişinin görünüşü. Tek
## iskelettir: kişi var olan Meshy modellerinden birinin ağıyla ve klip kütüphanesiyle oynar (K90, K91; kendi modeli olan adlı kişi kendi
## modelindedir). Veri data/character/folk.json'dadır: halkların (Yüeçi, Hun, Çiang, Usun) ten, saç, giysi, şerit, çizme ve başlık
## renkleri; rollerin (kasabalı, nöbetçi, esir, yapı eri) halk, beden ve giysi ağırlıkları; kendi modeli olmayan adlı kişilerin act1.md
## §3'ten tanımı. Görünüş saftır ve belirlenimcidir: aynı tohum her çalıştırmada aynı kişiyi verir (RandomNumberGenerator, tohumu
## ClipVariety.stable_hash; nesne kimliği ve saat yok).
##
## Görünüşün üç yüzü:
##   T0, tam kişi (CharacterAvatar; prepare): modelin ağı ve ölçeği; bölge maskesi olan modelde (kalabalık modelleri: tools/bake_regions.py
##       --size 1024) ten ve saç halkın renginde, giysi cloth_color boyasıyla kişinin renginde (character_toon.gdshader; ölçüsü
##       tools/bake_folk_cloth.py). Maskesiz modelde StandIn'in renk çarpanı kalıbıdır (albedo_tint, ılımlı). Boyalar avatarın
##       shader_overrides'ındadır: model yeniden yüklense de (model_changed) ve profil yeniden uygulansa da kalır.
##   T1 ve T2, kalabalığın kuklası (CrowdPuppet): başlık biçimi (puppet_variant: sivri Saka başlığı, kürk başlık, açık baş) ve palet
##       (palette: giysi, şerit, ten, saç, başlık, çizme; CrowdField'in palet dokusu).
##   T3, kart: aynı paletle (kartın maskeleri giysi, ten, başlık).
## Adlı erin portresi: PortraitBaker.bake_look(görünüş).
##
##   var look := Folk.make("kislak:market:7", {"role": "townsfolk"})   # {id, people, body, coat, hat, model, scale, ...}
##   var uldin := Folk.person("uldin")                                  # act1.md §3'ün tanımı; kendi modeli olan kişi: {own: true, model}
##   Folk.prepare(avatar, look, allocator)                              # ağaca girmeden önce
##   var colors := Folk.palette(look)                                   # kuklanın ve kartın paleti

const DATA_PATH := "res://data/character/folk.json"
## Kuklanın başlık biçimleri (CrowdPuppet'in ağları bu sırayladır).
const PUPPET_HATS: Array[String] = ["cap", "fur", "bare"]
## Paletin yuvaları (CrowdPuppet'in bölgeleri ve kartın renkleri bu sırayla okur).
const SLOT_COAT := 0
const SLOT_TRIM := 1
const SLOT_SKIN := 2
const SLOT_HAIR := 3
const SLOT_HAT := 4
const SLOT_BOOTS := 5
const SLOTS := 6
## Yaşlı sayılan yaş, çocuk aralığı.
const ELDER_AGE := 55
const CHILD_AGE := Vector2i(6, 11)
## Rengin kişi kişi kayması (HSV: doygunluk, parlaklık çarpanı aralığı).
const JITTER_S := Vector2(0.9, 1.06)
const JITTER_V := Vector2(0.9, 1.07)
## Maskesiz modelde renk çarpanının payı ve kanal sınırları (StandIn kalıbı; ten de kayar, ılımlı kalsın).
const TINT_STRENGTH := 0.45
const TINT_RANGE := Vector2(0.8, 1.15)

static var _data: Dictionary = {}


## Veri (önbellekli; bozuksa boş sözlük ve uyarı).
static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		if not parsed is Dictionary:
			push_warning("[folk] %s okunamadı" % DATA_PATH)
			return {}
		_data = parsed
	return _data


## Önbelleği boşaltır (sınamalar).
static func reset() -> void:
	_data = {}


## Tohumdan görünüş (saf). opts: role (roles kaydı; yoksa townsfolk), people, body (male, female, child, elder), age ve görünüşün
## herhangi bir alanı (coat, trim, skin, hair, boots: «#rrggbb» ya da Color; hat: {kind, color}; height_m, build, model, style): verilen
## alan tohumun seçiminin yerine geçer.
static func make(seed_key: String, opts: Dictionary = {}) -> Dictionary:
	var d := Folk.data()
	var rng := RandomNumberGenerator.new()
	rng.seed = ClipVariety.stable_hash("folk|" + seed_key)
	var roles: Dictionary = d.get("roles", {})
	var role_id := str(opts.get("role", "townsfolk"))
	var role: Dictionary = roles.get(role_id, roles.get("townsfolk", {}))
	var people := str(opts.get("people", Folk._weighted(role.get("peoples", {"yuezhi": 1}), rng.randf())))
	var peoples: Dictionary = d.get("peoples", {})
	if not peoples.has(people):
		people = "yuezhi"
	var folk: Dictionary = peoples.get(people, {})
	var body_pick := str(opts.get("body", Folk._weighted(role.get("bodies", {"male": 1, "female": 1}), rng.randf())))
	var elder := body_pick == "elder" or bool(opts.get("elder", false))
	var body := "male" if body_pick == "elder" else body_pick
	if elder and body_pick == "elder":
		body = "male" if rng.randf() < 0.55 else "female"
	if not ["male", "female", "child"].has(body):
		body = "male"
	var age_range: Array = role.get("age", [18, 50])
	var age := int(opts.get("age", 0))
	if age <= 0:
		if body == "child":
			age = rng.randi_range(CHILD_AGE.x, CHILD_AGE.y)
		elif elder:
			age = rng.randi_range(ELDER_AGE, 72)
		else:
			age = rng.randi_range(int(age_range[0]), int(age_range[1]))
	elder = elder or age >= ELDER_AGE
	var heights: Dictionary = d.get("heights", {})
	var h_range: Array = heights.get(body, [1.6, 1.8])
	var height := float(opts.get("height_m", 0.0))
	if height <= 0.0:
		var t := rng.randf()
		if body == "child":
			t = clampf(float(age - CHILD_AGE.x) / float(CHILD_AGE.y - CHILD_AGE.x) * 0.8 + t * 0.2, 0.0, 1.0)
		height = lerpf(float(h_range[0]), float(h_range[1]), t) * (0.97 if elder else 1.0)
	var b_range: Array = d.get("build", [0.92, 1.12])
	var build := float(opts.get("build", lerpf(float(b_range[0]), float(b_range[1]), rng.randf())))
	var coat_list: Array = role.get("coat", folk.get("coat", ["#6a4a34"]))
	var coat_weights: Array = folk.get("coat_weights", []) if not role.has("coat") else []
	var coat := Folk._color(opts.get("coat", Folk._pick_list(coat_list, coat_weights, rng.randf())))
	var trim := Folk._color(opts.get("trim", Folk._pick_list(role.get("trim", folk.get("trim", ["#5a4632"])), [], rng.randf())))
	var skin := Folk._color(opts.get("skin", Folk._pick_list(folk.get("skin", ["#c99a72"]), [], rng.randf())))
	var hair_list: Array = folk.get("elder_hair", folk.get("hair", [])) if elder else folk.get("hair", ["#2a1d16"])
	var hair := Folk._color(opts.get("hair", Folk._pick_list(hair_list, [], rng.randf())))
	var boots := Folk._color(opts.get("boots", Folk._pick_list(folk.get("boots", ["#3b2a1e"]), [], rng.randf())))
	var hats: Dictionary = (role.get("hats", {}) as Dictionary).get(body, (folk.get("hats", {}) as Dictionary).get(body, {"none": 1}))
	var hat_opt: Variant = opts.get("hat")
	var hat_kind := str(hat_opt.get("kind", "none")) if hat_opt is Dictionary else str(Folk._weighted(hats, rng.randf()))
	var hat_color := Folk._color(hat_opt.get("color")) if hat_opt is Dictionary and hat_opt.has("color") \
		else Folk._color(Folk._pick_list(folk.get("hat_color", ["#3a2a20"]), [], rng.randf()))
	# Kişi kişi küçük kayma: aynı listeden gelen iki giysi bire bir aynı görünmesin (verilen renk kaymaz).
	if not opts.has("coat"):
		coat = Folk._jitter(coat, rng)
	if not opts.has("trim"):
		trim = Folk._jitter(trim, rng)
	var shade_range: Array = role.get("shade", [1.0, 1.0])
	var shade := lerpf(float(shade_range[0]), float(shade_range[1]), rng.randf())
	var style: Array = opts.get("style", role.get("style", []))
	var model := str(opts.get("model", ""))
	if model.is_empty():
		model = Folk.model_for(body, elder, str(role.get("model", "")))
	var model_h := float(((d.get("models", {}) as Dictionary).get(model, {}) as Dictionary).get("height_m", 1.72))
	return {
		"id": seed_key,
		"people": people,
		"role": role_id,
		"body": body,
		"elder": elder,
		"age": age,
		"height_m": snappedf(height, 0.001),
		"build": snappedf(clampf(build, 0.85, 1.25), 0.001),
		"skin": skin,
		"hair": hair,
		"coat": coat,
		"trim": trim,
		"boots": boots,
		"hat": hat_kind,
		"hat_color": hat_color,
		"shade": snappedf(shade, 0.001),
		"style": style,
		"model": model,
		"own": false,
		"scale": snappedf(height / maxf(model_h, 0.5), 0.0001) if not model.is_empty() else 1.0,
	}


## Adlı kişinin görünüşü: kendi Meshy modeli varsa {id, own: true, model: id, scale 1} (renkleri modelindedir); folk.json'un named
## kaydı varsa o tanımla (tohum kişinin kimliği); yoksa kimliğin tohumundan bir kasabalı.
static func person(id: String) -> Dictionary:
	if StandIn.has_model(id):
		return {"id": id, "own": true, "model": id, "scale": 1.0, "people": "", "body": ClipVariety.profile_of(id).get("body", "male"),
			"style": ClipVariety.profile_of(id).get("style", [])}
	var named: Dictionary = Folk.data().get("named", {})
	var def: Variant = named.get(id)
	if def is Dictionary:
		var opts: Dictionary = (def as Dictionary).duplicate()
		opts["role"] = str(opts.get("role", "townsfolk"))
		return Folk.make(id, opts)
	return Folk.make(id)


## Bedenin tam kişi modeli (çocuk ve yaşlı tam kişi olmaz: boş). role_model rolün modelidir (nöbetçinin pullu yeleği).
static func model_for(body: String, elder: bool = false, role_model: String = "") -> String:
	if body == "child":
		return ""
	if not role_model.is_empty() and body == "male":
		return role_model
	var bodies: Dictionary = Folk.data().get("bodies", {})
	var model := str(bodies.get(body, ""))
	return "" if elder and model.is_empty() else model


## Görünüş tam kişi olabilir mi (modeli var mı)?
static func has_full(look: Dictionary) -> bool:
	return not str(look.get("model", "")).is_empty()


## Çeşitliliğin profili (ClipVariety.Allocator.register): beden, yaş, stil.
static func variety_profile(look: Dictionary) -> Dictionary:
	if bool(look.get("own", false)):
		return ClipVariety.profile_of(str(look.get("id", "")))
	var body := str(look.get("body", "male"))
	var age := "child" if body == "child" else ("elder" if bool(look.get("elder", false)) else "adult")
	return {"body": body, "age": age, "style": look.get("style", [])}


## Tam kişiyi hazırlar (ağaca girmeden önce): model, ölçek, boyalar, çeşitlilik (allocator verilirse kişi kaydolur). Kendi modelindeki
## adlı kişinin yalnız modeli ve çeşitliliği verilir. Bölge maskesi olmayan modelde renk çarpanı model yüklenince uygulanır (StandIn).
static func prepare(avatar: CharacterAvatar, look: Dictionary, allocator: ClipVariety.Allocator = null) -> void:
	if avatar == null or look.is_empty():
		return
	var id := str(look.get("id", ""))
	avatar.model_override = str(look.get("model", ""))
	avatar.set_meta(StandIn.PERSON_META, id)
	if allocator:
		allocator.register(id, Folk.variety_profile(look), {"model": avatar.model_override})
		avatar.variety_allocator = allocator
	avatar.variety_person = id
	if bool(look.get("own", false)):
		return
	avatar.model_scale = float(look.get("scale", 1.0))
	var w := sqrt(clampf(float(look.get("build", 1.0)), 0.85, 1.25))
	avatar.scale = Vector3(w, 1.0, w)
	if Folk.has_mask(avatar.model_override):
		avatar.shader_overrides = Folk.paint(look)
	else:
		avatar.shader_overrides = {}
		var tint := Folk.fallback_tint(look)
		var reapply := func(_id: String) -> void: StandIn.apply(avatar, tint, float(look.get("scale", 1.0)))
		if not avatar.model_changed.is_connected(reapply):
			avatar.model_changed.connect(reapply)


## Aynı modeldeki avatarı başka bir kişiye boyar (tam kişi yuvası): model yeniden yüklenmez, çeşitliliği yuvanındır; ölçek, yapı ve
## boyalar kişinin.
static func repaint(avatar: CharacterAvatar, look: Dictionary) -> void:
	if avatar == null or look.is_empty():
		return
	avatar.model_scale = float(look.get("scale", 1.0))
	var w := sqrt(clampf(float(look.get("build", 1.0)), 0.85, 1.25))
	avatar.scale = Vector3(w, 1.0, w)
	if Folk.has_mask(avatar.model_override):
		avatar.shader_overrides = Folk.paint(look)
		avatar.refresh_colors()
	else:
		StandIn.apply(avatar, Folk.fallback_tint(look), float(look.get("scale", 1.0)))


## Modelin bölge maskesi var mı (ten, saç ve giysi ayrı boyanır)?
static func has_mask(model: String) -> bool:
	return not model.is_empty() and ResourceLoader.exists("res://assets/characters/%s/%s_regions.png" % [model, model])


## Bölge maskeli modelin boyaları (karakter gölgelendiricisinin parametreleri; saf): ten, saç, giysi boyası ve modelin giysi ölçüsü.
static func paint(look: Dictionary) -> Dictionary:
	var d := Folk.data()
	var m: Dictionary = (d.get("models", {}) as Dictionary).get(str(look.get("model", "")), {})
	var band: Array = m.get("band", [0.03, 0.08])
	var coat: Color = look.get("coat", Color(0.42, 0.29, 0.2))
	var shade := float(look.get("shade", 1.0))
	var hair: Color = look.get("hair", Color(0.16, 0.11, 0.09))
	if ["veil", "fur", "crown", "kam", "bork"].has(str(look.get("hat", ""))):
		# Örtülü ve kürk başlıklı başta görünen saç başlığın kendisidir (modelin keçe başlığı aynı bölgededir).
		hair = look.get("hat_color", hair)
	return {
		"skin_color": look.get("skin", Color(0.79, 0.6, 0.45)),
		"hair_color": hair,
		"cloth_color": Color(coat.r * shade, coat.g * shade, coat.b * shade, float(d.get("cloth_strength", 0.82))),
		"cloth_lum": float(m.get("cloth_lum", 0.1)),
		"cloth_band": Vector2(float(band[0]), float(band[1])),
	}


## Maskesiz modelde renk çarpanı (saf; StandIn kalıbı): giysinin rengi modelin giysisine oranla, ılımlı (ten de kayar).
static func fallback_tint(look: Dictionary) -> Color:
	var m: Dictionary = (Folk.data().get("models", {}) as Dictionary).get(str(look.get("model", "")), {})
	var base := Folk._color(m.get("base", "#755742"))
	var coat: Color = look.get("coat", base)
	var out := Color.WHITE
	for c in 3:
		var ratio: float = coat[c] / maxf(base[c], 0.02)
		out[c] = clampf(lerpf(1.0, ratio, TINT_STRENGTH), TINT_RANGE.x, TINT_RANGE.y)
	return out


## Kuklanın ve kartın paleti (saf): SLOT_* sırasıyla giysi, şerit, ten, saç, başlık, çizme (esirin solgun giysisi shade ile).
static func palette(look: Dictionary) -> PackedColorArray:
	var shade := float(look.get("shade", 1.0))
	var coat: Color = look.get("coat", Color(0.42, 0.29, 0.2))
	var trim: Color = look.get("trim", Color(0.35, 0.27, 0.2))
	var hair: Color = look.get("hair", Color(0.16, 0.11, 0.09))
	var hat_color: Color = look.get("hat_color", hair)
	if str(look.get("hat", "")) == "veil":
		hair = hat_color
	var out := PackedColorArray()
	out.resize(SLOTS)
	out[SLOT_COAT] = Color(coat.r * shade, coat.g * shade, coat.b * shade)
	out[SLOT_TRIM] = Color(trim.r * shade, trim.g * shade, trim.b * shade)
	out[SLOT_SKIN] = look.get("skin", Color(0.79, 0.6, 0.45))
	out[SLOT_HAIR] = hair
	out[SLOT_HAT] = hat_color
	out[SLOT_BOOTS] = look.get("boots", Color(0.23, 0.16, 0.12))
	return out


## Kuklanın başlık biçimi (saf): PUPPET_HATS'in sırası (0 sivri Saka başlığı, 1 kürk, 2 açık baş).
static func puppet_variant(look: Dictionary) -> int:
	var hats: Dictionary = Folk.data().get("puppet_hats", {})
	return maxi(PUPPET_HATS.find(str(hats.get(str(look.get("hat", "none")), "bare"))), 0)


## Görünüşün anahtarı (portre önbelleği; saf).
static func key_of(look: Dictionary) -> String:
	var parts := PackedStringArray([str(look.get("id", "")), str(look.get("model", "")), str(look.get("hat", ""))])
	for k in ["skin", "hair", "coat", "trim", "hat_color"]:
		var c: Variant = look.get(k)
		parts.append((c as Color).to_html(false) if c is Color else "")
	return "folk|" + "|".join(parts)


# --- Yardımcılar ---------------------------------------------------------------------------------------------------------

## «#rrggbb» ya da Color → Color (okunamazsa koyu kahve).
static func _color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is String and Color.html_is_valid(str(value)):
		return Color.html(str(value))
	return Color(0.35, 0.26, 0.19)


## Ağırlıklı seçim (saf): {anahtar: ağırlık}, u ∈ [0, 1).
static func _weighted(weights: Dictionary, u: float) -> String:
	var total := 0.0
	for k: Variant in weights:
		total += maxf(float(weights[k]), 0.0)
	if total <= 0.0:
		return str(weights.keys()[0]) if not weights.is_empty() else ""
	var acc := 0.0
	for k: Variant in weights:
		acc += maxf(float(weights[k]), 0.0) / total
		if u < acc:
			return str(k)
	return str(weights.keys()[weights.size() - 1])


## Listeden seçim (ağırlık dizisi boşsa eşit).
static func _pick_list(list: Array, weights: Array, u: float) -> Variant:
	if list.is_empty():
		return null
	if weights.size() != list.size():
		return list[clampi(int(floor(u * list.size())), 0, list.size() - 1)]
	var table := {}
	for i in list.size():
		table[str(i)] = weights[i]
	return list[int(Folk._weighted(table, u))]


static func _jitter(c: Color, rng: RandomNumberGenerator) -> Color:
	return Color.from_hsv(c.h, clampf(c.s * rng.randf_range(JITTER_S.x, JITTER_S.y), 0.0, 1.0),
		clampf(c.v * rng.randf_range(JITTER_V.x, JITTER_V.y), 0.0, 1.0))
