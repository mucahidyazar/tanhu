class_name Craft
extends RefCounted
## Zanaat: tarif çözümü ve el işi (saf, durumsuz; economy.md §6.1–§6.2, §6.7–§6.9; godot.md §3 «Zanaat»). Prototipin game/craft.js'inin
## Godot'su (tarif çözümü, canCraft, craftHand, havuz yardımcıları); tezgâhın kuyruğu ve iş saati Workshop'tadır. Tarifler
## data/economy/recipes.json, tezgâhlar ve zanaatçılar data/economy/stations.json (sayıların sahibi d2/econ-model.json; tools/export_recipes.py).
##
## Üç tür iş (K24): hand el işi (Mete tutuşla, ≤8 sn; işçi İS ile), station tezgâh işi (sipariş, kuyruk, İS akar), master usta işi (tezgâh ve o
## zanaatın ustası; Mete yardım eder, başlatamaz). «Küçük iş elde, parça tezgâhta»: Mete'nin tutuşu olan tarif (hold) elde yapılır; tutuşu
## olmayan (hold null) tezgâhın sırasına girer. tag:x istenen yere o etiketin her eşyası gider (tag:wood her odun); İnce İş +1 asıl malzeme,
## emek ×1,5, çıktı 'id+'. İlk kez yapılan tarif +20 XP (Progression «recipe», kimlik başına bir kez; XP'yi çağıran verir).
##
## Havuz (kaynak kap): Inventory (Heybe; etiketi çözer), ItemContainer (sandık, ambar), ikisinin dizisi (önce ilki) ya da count, remove ve add
## taşıyan nesne. Girdi havuzdan alınır, çıktı havuza konur.
##   Craft.can_craft("rc_rope", {"inv": inventory})        # {ok, missing: [{id, n} | {station} | {role} | {skill} | {fine}]}
##   Craft.craft_hand("rc_rope", inventory, {"first": true}) # {out: [{id, n}], xp: 20}; girdi eksikse {}
##   Craft.unit_minutes("rc_felt_batch", 4.0)                # 122,1 oyun dakikası (İS × 60 ÷ eff(W))

const RECIPES_PATH := "res://data/economy/recipes.json"
const STATIONS_PATH := "res://data/economy/stations.json"
const EPS := 1e-9

static var _recipes: Dictionary = {}
static var _stations: Dictionary = {}


# --- Veri -------------------------------------------------------------------------------------------------------------

static func recipes_data() -> Dictionary:
	if _recipes.is_empty():
		_recipes = Craft._read(RECIPES_PATH)
	return _recipes


static func stations_data() -> Dictionary:
	if _stations.is_empty():
		_stations = Craft._read(STATIONS_PATH)
	return _stations


static func reset_cache() -> void:
	_recipes = {}
	_stations = {}


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func recipes() -> Dictionary:
	return recipes_data().get("recipes", {})


## Tarif satırı (bilinmeyen boş).
static func recipe(id: String) -> Dictionary:
	return recipes().get(id, {})


static func has_recipe(id: String) -> bool:
	return recipes().has(id)


static func stations() -> Dictionary:
	return stations_data().get("stations", {})


static func station(id: String) -> Dictionary:
	return stations().get(id, {})


static func roles() -> Dictionary:
	return stations_data().get("roles", {})


static func role(id: String) -> Dictionary:
	return roles().get(id, {})


static func fine_k() -> float:
	return float(stations_data().get("fineK", 1.5))


## Işıklı atölyenin meşalesi kaç karanlık oyun dakikası yanar (labour.json law.night.torchDarkHours × 60).
static func torch_dark_min() -> float:
	return float((Labour.law().get("night", {}) as Dictionary).get("torchDarkHours", 4.0)) * 60.0


## İlk kez yapılan tarifin tabanı (progression.json xp.sources.recipe.base: 20).
static func recipe_xp() -> int:
	var src: Dictionary = ((Progression.data().get("xp", {}) as Dictionary).get("sources", {}) as Dictionary).get("recipe", {})
	return int(src.get("base", 20))


## Havanın fx.dryK'sı yokken türün kurutma çarpanı (economy.md §6.13); bilinmeyen tür 1.
static func dry_by_type(type_id: Variant) -> float:
	var table: Dictionary = stations_data().get("dryByType", {})
	return float(table.get(str(type_id), 1.0)) if type_id != null else 1.0


## Oyuncu metni (recipes.json messages; {anahtar} yerine konur).
static func message(key: String, lang := "tr", args := {}) -> String:
	var m: Variant = (recipes_data().get("messages", {}) as Dictionary).get(key)
	var text := Catalog.pick(m, lang) if m != null else key
	for k: String in args:
		text = text.replace("{%s}" % k, str(args[k]))
	return text


## Tarifin adı: ilk çıktının adı (defter payı '@ration' ise tarifin kimliği).
static func recipe_name(id: String, lang := "tr") -> String:
	var r := recipe(id)
	for out_id: String in (r.get("out", {}) as Dictionary):
		if not out_id.begins_with("@"):
			return ItemCatalog.name_of(out_id, lang)
	return id


static func station_name(id: String, lang := "tr") -> String:
	return Catalog.pick(station(id).get("name", {"tr": id, "en": id}), lang)


static func role_name(id: Variant, lang := "tr") -> String:
	if id is Array:
		var names := PackedStringArray()
		for r: Variant in id:
			names.append(Craft.role_name(r, lang))
		return " / ".join(names)
	return Catalog.pick(role(str(id)).get("name", {"tr": str(id), "en": str(id)}), lang)


## Tarifin girdisinin metni: «2 Bakır Cevheri, 1 Kömür» (etiket «Odun» gibi etiketin adıyla).
static func list_text(list: Array, lang := "tr") -> String:
	var parts := PackedStringArray()
	for e: Dictionary in list:
		var id := str(e.get("id", ""))
		parts.append("%d %s" % [int(e.get("n", 0)), Craft.ref_name(id, lang)])
	return ", ".join(parts)


## Kimliğin ya da etiketin adı (tag:wood → «Odun»: data/economy/items.json labels.tags; yoksa etiketin kendisi).
static func ref_name(ref: String, lang := "tr") -> String:
	if ref.begins_with("tag:"):
		var tag := ref.substr(4)
		var tags: Dictionary = (ItemCatalog.data().get("labels", {}) as Dictionary).get("tags", {})
		return Catalog.pick(tags[tag], lang) if tags.has(tag) else tag
	return ItemCatalog.name_of(ref, lang)


# --- Tarif çözümü ---------------------------------------------------------------------------------------------------------

static func _row(r: Variant) -> Dictionary:
	if r is String or r is StringName:
		return Craft.recipe(String(r))
	return r if r is Dictionary else {}


## roles: dizi, sözlük ({rol: true | "master" | "apprentice"}), yazı ya da Callable. Usta işini yalnız Usta derecesi yapar (§6.8).
static func has_role(p_roles: Variant, need: Variant) -> bool:
	if need == null or (need is String and (need as String).is_empty()):
		return true
	if need is Array:
		for r: Variant in need:
			if Craft.has_role(p_roles, r):
				return true
		return false
	if p_roles == null:
		return false
	if p_roles is String or p_roles is StringName:
		return String(p_roles) == str(need)
	if p_roles is Callable:
		return bool((p_roles as Callable).call(str(need)))
	if p_roles is Array or p_roles is PackedStringArray:
		return str(need) in p_roles
	if p_roles is Dictionary:
		var v: Variant = (p_roles as Dictionary).get(str(need))
		return (v is bool and v) or ((v is String or v is StringName) and String(v) == "master")
	return false


static func _has_skill(skills: Variant, id: Variant) -> bool:
	if id == null or str(id).is_empty():
		return true
	if skills is Callable:
		return bool((skills as Callable).call(str(id)))
	if skills is Array or skills is PackedStringArray:
		return str(id) in skills
	if skills is Dictionary:
		return (skills as Dictionary).has(str(id))
	return false


## Tezgâh uygun mu: "hand" her yerde; ocak tarifi kazanlı yurt ocağında da (Kazan Ocağı bir ocaktır). at: kimlik ya da kimlikler.
static func station_fits(recipe_station: String, at: Variant) -> bool:
	if recipe_station == "hand":
		return true
	var fits := func(s: String) -> bool: return s == recipe_station or (recipe_station == "hearth" and s == "kitchen")
	if at is String or at is StringName:
		return fits.call(String(at))
	if at is Array or at is PackedStringArray:
		for s: Variant in at:
			if fits.call(str(s)):
				return true
	return false


## İnce İş'in ustası: tarifin rolü, yoksa tezgâhın ilk rolü. İnce İş taşımayan tarifte null.
static func fine_role(r: Variant) -> Variant:
	var row := Craft._row(r)
	if not row.get("fine") is Dictionary:
		return null
	var own: Array = []
	var rr: Variant = row.get("role")
	for id: Variant in (rr if rr is Array else ([rr] if rr != null else [])):
		if Craft.roles().has(str(id)) and not Craft.role(str(id)).get("named", false):
			own.append(str(id))
	if own.size() > 1:
		return own
	return own[0] if not own.is_empty() else Craft.station_role(str(row.get("station", "")))


## Tezgâhın İnce İş ustası: rolü o tezgâhta olan ilk zanaatçı (adlı usta değil).
static func station_role(station_id: String) -> Variant:
	for id: String in Craft.roles():
		var r: Dictionary = Craft.roles()[id]
		if str(r.get("station", "")) == station_id and not r.get("named", false):
			return id
	return null


## Bir birimin girdisi; İnce İş +1 asıl malzeme. → [{id, n}].
static func inputs_of(r: Variant, fine := false) -> Array:
	var row := Craft._row(r)
	var out: Array = []
	var ins: Dictionary = row.get("in", {})
	for ref: String in ins:
		out.append({"id": ref, "n": int(ins[ref])})
	if fine and row.get("fine") is Dictionary:
		var extra: Dictionary = row["fine"]
		for ref: String in extra:
			var hit := false
			for e: Dictionary in out:
				if e["id"] == ref:
					e["n"] = int(e["n"]) + int(extra[ref])
					hit = true
			if not hit:
				out.append({"id": ref, "n": int(extra[ref])})
	return out


## → {ok, missing: [{id, n} | {station} | {role} | {skill} | {fine} | {recipe}]}. opts: inv (havuz), station (yakındaki tezgâh ya da
## tezgâhlar), roles (Usta derecesindeki roller), skills (öğrenilmiş beceriler), fine, n (birim).
static func can_craft(r: Variant, opts := {}) -> Dictionary:
	var row := Craft._row(r)
	if row.is_empty():
		return {"ok": false, "missing": [{"recipe": str(r)}]}
	var missing: Array = []
	if not Craft.station_fits(str(row.get("station", "hand")), opts.get("station")):
		missing.append({"station": str(row.get("station", ""))})
	if str(row.get("who", "")) == "master" and not Craft.has_role(opts.get("roles"), row.get("role")):
		missing.append({"role": row.get("role")})
	var fine := bool(opts.get("fine", false))
	if fine:
		var fr: Variant = Craft.fine_role(row)
		if fr == null:
			missing.append({"fine": true})
		elif not Craft.has_role(opts.get("roles"), fr):
			missing.append({"role": fr})
	if row.get("skill") != null and not Craft._has_skill(opts.get("skills"), row.get("skill")):
		missing.append({"skill": row["skill"]})
	var units := int(opts.get("n", 1))
	for e: Dictionary in Craft.inputs_of(row, fine):
		var need: int = int(e["n"]) * units
		var have := Craft.pool_count(opts.get("inv"), str(e["id"]))
		if have < need:
			missing.append({"id": e["id"], "n": need - have})
	return {"ok": missing.is_empty(), "missing": missing}


## Mete el işi olarak yapabilir mi (tutuşu var)? Tutuşu olmayan tezgâhın sırasına girer.
static func is_hand(r: Variant) -> bool:
	var row := Craft._row(r)
	return Craft._num(row.get("hold"))


## Tezgâhın sırasına girebilir mi (işçi emeği var)? El işi de NPC'nin uygun tezgâhta yaptığı iştir (§6.7 kural 7).
static func is_queued(r: Variant) -> bool:
	return Craft._num(Craft._row(r).get("wh"))


## El işi, tutuş bitince (≤8 sn; pişirme oturuşu survival.md §3): girdiyi kaptan alır, çıktıyı koyar. Tezgâh, usta ve beceri denetimi
## can_craft'tadır. first: tarif ilk kez yapıldı (+20 XP; bilgisini çağıran tutar). → {out: [{id, n}], xp}; girdi eksikse {}.
static func craft_hand(r: Variant, inv: Variant, opts := {}) -> Dictionary:
	var row := Craft._row(r)
	var units := int(opts.get("n", 1))
	if row.is_empty() or inv == null or not Craft.is_hand(row) or units < 1:
		return {}
	var inputs := Craft.inputs_of(row)
	for e: Dictionary in inputs:
		if Craft.pool_count(inv, str(e["id"])) < int(e["n"]) * units:
			return {}
	for e: Dictionary in inputs:
		Craft.pool_take(inv, str(e["id"]), int(e["n"]) * units)
	var out: Array = []
	var outs: Dictionary = row.get("out", {})
	for id: String in outs:
		var q: int = int(outs[id]) * units
		if id.begins_with("@"):
			out.append({"id": id, "n": q})
			continue
		out.append({"id": id, "n": Craft.pool_put(inv, id, q, opts.get("day"), true)})
	return {"out": out, "xp": Craft.recipe_xp() if opts.get("first", false) else 0}


## Bir birimin oyun dakikası (Defter'in ≈süresi): İS × 60 ÷ eff(W).
static func unit_minutes(r: Variant, w: float, fine := false) -> float:
	var row := Craft._row(r)
	var e := Labour.eff(w)
	if row.is_empty() or not Craft._num(row.get("wh")) or e <= 0.0:
		return INF
	return float(row["wh"]) * 60.0 * (Craft.fine_k() if fine else 1.0) / e


## Bir tezgâhta yapılabilen tarifler: kendi tarifleri, NPC el işi (uygun tezgâhta da yapılır, §6.7 kural 7), Kazan Ocağı'nda ocak işi.
static func recipes_at(station_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in Craft.recipes():
		var s := str(Craft.recipes()[id].get("station", ""))
		if s == station_id or s == "hand" or (s == "hearth" and station_id == "kitchen"):
			out.append(id)
	return out


# --- Havuz ------------------------------------------------------------------------------------------------------------------

## Havuzdaki adet (etiket kabul eder). Dizi havuzda toplam.
static func pool_count(pool: Variant, ref: String) -> int:
	if pool == null:
		return 0
	if pool is Array:
		var n := 0
		for p: Variant in pool:
			n += Craft.pool_count(p, ref)
		return n
	if pool is Object and (pool as Object).has_method(&"count"):
		return int((pool as Object).call(&"count", ref))
	return 0


## Havuzdan alır → gerçekten alınan adet. Dizi havuzda sırayla.
static func pool_take(pool: Variant, ref: String, n: int) -> int:
	if pool == null or n <= 0:
		return 0
	if pool is Array:
		var got := 0
		for p: Variant in pool:
			if got >= n:
				break
			got += Craft.pool_take(p, ref, n - got)
		return got
	if pool is Object and (pool as Object).has_method(&"remove"):
		var r: Variant = (pool as Object).call(&"remove", ref, n)
		if r is Array:
			var s := 0
			for e: Variant in r:
				s += int((e as Dictionary).get("n", 0)) if e is Dictionary else 0
			return s
		return int(r) if Craft._num(r) else 0
	return 0


## Havuza koyar → kaba giren adet. Dizi havuzda ilk kap alır. allow_over: sınırı geçer (el işinin çıktısı heybede kalır, prototipin
## allowOver'ı). day: bozulan yiyeceğin gün anahtarı.
static func pool_put(pool: Variant, id: String, n: int, day: Variant = null, allow_over := false) -> int:
	if pool == null or n <= 0:
		return 0
	if pool is Array:
		var put := 0
		for p: Variant in pool:
			if put >= n:
				break
			put += Craft.pool_put(p, id, n - put, day, allow_over)
		return put
	var r: Variant = null
	if pool is Inventory:
		r = (pool as Inventory).add(id, n, "craft", allow_over)
	elif pool is ItemContainer:
		r = (pool as ItemContainer).add(id, n, int(day) if Craft._num(day) else ItemContainer.NO_DAY, allow_over)
	elif pool is Object and (pool as Object).has_method(&"add"):
		r = (pool as Object).call(&"add", id, n)
	if r is Dictionary:
		return int((r as Dictionary).get("added", 0))
	return int(r) if Craft._num(r) else 0


## Havuzun içeriği: [{id, n}].
static func pool_list(pool: Variant) -> Array:
	if pool is Array:
		var out: Array = []
		for p: Variant in pool:
			out.append_array(Craft.pool_list(p))
		return out
	if pool is Inventory:
		return (pool as Inventory).pack.list()
	if pool is Object and (pool as Object).has_method(&"list"):
		var l: Variant = (pool as Object).call(&"list")
		return l if l is Array else []
	return []


static func _num(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))


# --- Metin ------------------------------------------------------------------------------------------------------------------

## Bekleme nedeninin oyuncu metni (Workshop.wait ya da can_craft eksiği): «Malzeme bekliyor: 2 Bakır Cevheri» · «Usta gerek: Demirci».
static func wait_text(wait: Variant, lang := "tr") -> String:
	if not wait is Dictionary or (wait as Dictionary).is_empty():
		return ""
	var w: Dictionary = wait
	match str(w.get("reason", "")):
		"material":
			return Craft.message("wait_materials", lang, {"list": Craft.list_text(w.get("missing", []), lang)})
		"master":
			return Craft.message("need_master", lang, {"role": Craft.role_name(w.get("role"), lang)})
		"rest":
			return Craft.message("rest", lang)
		"crew":
			return Craft.message("no_crew", lang)
		"slot":
			return Craft.message("slot", lang)
		"weather", "rain":
			return Craft.message("cure_paused", lang)
	return ""


## can_craft'ın eksiklerinin metni (ilk neden): tezgâh, usta, beceri ya da malzeme.
static func missing_text(missing: Array, lang := "tr") -> String:
	var mats: Array = []
	for m: Dictionary in missing:
		if m.has("station"):
			return Craft.message("need_station", lang, {"station": Craft.station_name(str(m["station"]), lang)})
		if m.has("role"):
			return Craft.message("need_master", lang, {"role": Craft.role_name(m["role"], lang)})
		if m.has("skill"):
			var sk: Dictionary = Progression.rows_by_id(Progression.skill_data().get("skills", [])).get(str(m["skill"]), {})
			return Craft.message("need_skill", lang, {"skill": Catalog.pick(sk.get("name", {"tr": m["skill"], "en": m["skill"]}), lang)})
		if m.has("id"):
			mats.append(m)
	return Craft.message("wait_materials", lang, {"list": Craft.list_text(mats, lang)}) if not mats.is_empty() else ""
