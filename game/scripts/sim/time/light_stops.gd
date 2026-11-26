class_name LightStops
extends RefCounted
## Altı ışık durağı ve saatin ışık örneği (saf; K20, K58, K67, K101; time.md §5.1–§5.3; godot.md §4.9): data/time/light_stops.json'u
## okur, dakikanın ışık konumunu (s ∈ [0, 6): 0 night, 1 dawn, 2 morning, 3 noon, 4 golden, 5 dusk) Daylight.sky_keys ile bulur, iki
## durağı karıştırır ve SkyRig'in yazdığı örneği kurar. Örnek SkyRig'in biçimidir (bkz. sky_rig.gd): ışığın yönü ve rengi, ortam, sis,
## gök tekdüzenleri, suyun renkleri (water), gece renk ayarının payı (grade_night), kampın ateşi, köyü ve ateş böcekleri (props).
##
## Işığın yönü ve çarpanı Daylight.light_source'tandır: gündüz güneş (≥15°), akşam ve sabah penceresinde küresel karışım ve çukur,
## gecede ay ya da gök yönü; light_energy durağın değeri × k'dır. Yön oyun dakikasında bir adım değişir (dakika aşağı yuvarlanır: gölge
## kenarı yüzmez, time.md §5.1); göğün güneşi ve ayı o dakikanın kendisidir. Ateş böcekleri (props.motes) doğrusal değildir: ikindide menü
## anahtarına (s 4,3) dek 0, oradan batışa (s 5) dek 0→1 (Serbest Gez'in ilk karesinde ateş böceği yoktur; time.md §5.3).
##
##   var table := LightStops.load_table()
##   var sample := LightStops.sample(table, "camp", 1171, Daylight.MENU_MINUTE)   # s 4,3: ikindi→akşam 0,3, güneş menü yönünde
##   rig.feed_clock(sample)

const PATH := "res://data/time/light_stops.json"
## Ateş böceklerinin ikindide başladığı ışık konumu (time.md §5.3: menü anahtarı).
const MOTES_FROM_S := 4.3

static var _tables: Dictionary = {}


## Tabloyu okur (önbellekli): {order: [id × 6], stops: {id: çözülmüş durak}, places: {id: yer}, probe: {...}}. Okunamazsa boş.
static func load_table(path: String = PATH) -> Dictionary:
	if _tables.has(path):
		return _tables[path]
	if not FileAccess.file_exists(path):
		push_warning("[light_stops] dosya yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not (parsed as Dictionary).get("stops") is Dictionary:
		push_warning("[light_stops] dosya bozuk: %s" % path)
		return {}
	var root: Dictionary = parsed
	var order: Array[StringName] = []
	for id: Variant in root.get("order", []):
		order.append(StringName(str(id)))
	var stops := {}
	for id: String in root["stops"]:
		stops[StringName(id)] = resolve_stop(root["stops"][id])
	var table := {"order": order, "stops": stops, "places": root.get("places", {}), "probe": root.get("probe", {}), "path": path}
	_tables[path] = table
	return table


## Önbelleği boşaltır (sınama ve ayar sırasında dosya değişince).
static func clear_cache() -> void:
	_tables.clear()


## Durağın renklerini Color'a çevirir (*_color, sky'ın kısa adları, water'ın renkleri); öteki değerler olduğu gibi.
static func resolve_stop(def: Dictionary) -> Dictionary:
	var out := {}
	for key: String in def:
		var v: Variant = def[key]
		if v is Dictionary:
			var part := {}
			for k: String in v:
				part[k] = _color_or_value(k, v[k])
			out[key] = part
		else:
			out[key] = _color_or_value(key, v)
	return out


static func _color_or_value(key: String, v: Variant) -> Variant:
	var colorish := key.ends_with("_color") or key.ends_with("color") or key in ["zenith", "mid", "horizon", "ground", "albedo",
		"deep_color", "shallow_color", "reflection_horizon", "reflection_zenith"]
	if colorish and (v is String or (v is Array and (v as Array).size() >= 3)):
		return to_color(v)
	return v


## "#rrggbb" ya da [r, g, b(, a)] → Color (sRGB değerleri olduğu gibi).
static func to_color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is String:
		return Color.from_string(value, Color.WHITE)
	if value is Array and (value as Array).size() >= 3:
		var a: Array = value
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	return Color.WHITE


## Yerin bilgisi (lat, dec_offset, golden, menu); yoksa boş.
static func place(table: Dictionary, id: String) -> Dictionary:
	var places: Dictionary = table.get("places", {})
	return places.get(id, {})


## Durağın çözülmüş değerleri (yoksa boş).
static func stop(table: Dictionary, id: StringName) -> Dictionary:
	return (table.get("stops", {}) as Dictionary).get(id, {})


## Işık konumu s'in iki durağının karışımı (s 6 ≡ 0).
static func mix_stops(table: Dictionary, s: float) -> Dictionary:
	var order: Array = table.get("order", [])
	if order.size() != 6:
		return {}
	var x := fposmod(s, 6.0)
	var i := floori(x)
	var f := x - float(i)
	var a: Dictionary = stop(table, order[i])
	var b: Dictionary = stop(table, order[(i + 1) % 6])
	var out := blend(a, b, f)
	if out.get("props") is Dictionary:
		(out["props"] as Dictionary)["motes"] = motes_at(table, x)
	return out


## Ateş böceklerinin payı (time.md §5.3): ikindiden menü anahtarına dek 0, oradan batışa 0→1; öteki aralıklarda iki durağın karışımı.
static func motes_at(table: Dictionary, s: float) -> float:
	var x := fposmod(s, 6.0)
	if x >= 4.0 and x < 5.0:
		var dusk: Dictionary = stop(table, &"dusk").get("props", {})
		return clampf((x - MOTES_FROM_S) / (5.0 - MOTES_FROM_S), 0.0, 1.0) * float(dusk.get("motes", 1.0))
	var order: Array = table.get("order", [])
	var i := floori(x)
	var a: Dictionary = stop(table, order[i]).get("props", {})
	var b: Dictionary = stop(table, order[(i + 1) % 6]).get("props", {})
	return lerpf(float(a.get("motes", 0.0)), float(b.get("motes", 0.0)), x - float(i))


## İki değer sözlüğünün karışımı (saf): sayılar ve renkler doğrusal, iç sözlükler özyinelemeli, öteki değerler t < 0,5'te a'nınki.
static func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for key: Variant in a:
		out[key] = blend_value(a[key], b.get(key, a[key]), t)
	for key: Variant in b:
		if not out.has(key):
			out[key] = b[key]
	return out


static func blend_value(x: Variant, y: Variant, t: float) -> Variant:
	if (x is float or x is int) and (y is float or y is int) and not (x is bool or y is bool):
		return lerpf(float(x), float(y), t)
	if x is Color and y is Color:
		return (x as Color).lerp(y, t)
	if x is Vector3 and y is Vector3:
		return (x as Vector3).lerp(y, t)
	if x is Dictionary and y is Dictionary:
		return blend(x, y, t)
	return x if t < 0.5 else y


## Yerin ışık anahtarları (o günün bilgisiyle).
static func keys_for(info: Dictionary, p: Dictionary) -> PackedFloat64Array:
	return Daylight.sky_keys(info, float(p.get("golden", NAN)), float(p.get("menu", NAN)))


## Yerin o günkü sapması (derece): tarihten, yerin payıyla.
static func dec_for(p: Dictionary, day_n: int) -> float:
	return Daylight.solar_dec(float(GameCalendar.doy(day_n))) + float(p.get("dec_offset", 0.0))


## Saatin ışık örneği (SkyRig biçimi). p_place: yerin kimliği ("camp") ya da sözlüğü. opts: {cloud: 0..1 (yalnız ışık düzeyine)}.
static func sample(table: Dictionary, p_place: Variant, day_n: int, minute: float, opts: Dictionary = {}) -> Dictionary:
	var p: Dictionary = p_place if p_place is Dictionary else place(table, str(p_place))
	if p.is_empty() or table.is_empty():
		return {}
	var lat := float(p.get("lat", Daylight.CAMP_LAT))
	var dec := dec_for(p, day_n)
	var info := Daylight.day_info(lat, dec)
	var s := Daylight.sky_at(keys_for(info, p), minute)
	var out := mix_stops(table, s)
	var abs_min := GameClock.abs_of(day_n, minute)
	var age := GameCalendar.moon_age(abs_min)
	var sun := Daylight.sun_at(lat, dec, minute)
	var moon := Daylight.moon_at(lat, dec, minute, age)
	# Işığın yönü oyun dakikasında bir adım (time.md §5.1): dakika aşağı yuvarlanır.
	var qm := floorf(minute)
	var q_sun := Daylight.sun_at(lat, dec, qm)
	var q_moon := Daylight.moon_at(lat, dec, qm, GameCalendar.moon_age(GameClock.abs_of(day_n, qm)))
	var src := Daylight.light_source(info, qm, q_sun, q_moon)
	out["lat"] = lat
	out["dec"] = dec
	out["day_n"] = day_n
	out["minute"] = minute
	out["moon_age"] = age
	out["s"] = s
	out["sun"] = sun
	out["moon"] = moon
	out["sun_dir"] = Daylight.dir_of(sun)
	out["moon_dir"] = Daylight.dir_of(moon)
	out["light_dir"] = Daylight.source_dir(src)
	out["light_k"] = float(src["k"])
	out["light_energy"] = float(out.get("light_energy", 1.0)) * float(src["k"])
	out["light_shadow"] = true
	var sky: Dictionary = out.get("sky", {})
	sky["sky_latitude"] = lat
	sky["sky_rotation"] = sidereal_angle(day_n, minute)
	out["sky"] = sky
	out["phase"] = Daylight.phase_at(info, minute)
	out["light_level"] = Daylight.light_level(float(sun["el"]), float(moon["el"]), float(moon["illum"]), float(opts.get("cloud", 0.0)))
	out["night_class"] = Daylight.night_class(float(out["light_level"]))
	return out


## Yerel yıldız zamanı (radyan; gök kutbun çevresinde bu kadar dönmüştür; time.md §5.6): güneşin sağ açıklığı artı saat açısı. Güneşin
## boylamı oyunun sapma formülüyle aynı yıldandır (ilkbahar noktası doy 81,25, eğiklik 23,44°): bir tur 23 sa 56 dk oyun saatidir.
static func sidereal_angle(day_n: int, minute: float) -> float:
	var t := float(GameCalendar.doy(day_n)) + minute / 1440.0
	var lam := deg_to_rad(360.0 * (t + 10.0) / 365.0 - 90.0)
	var eps := deg_to_rad(23.44)
	var ra := atan2(cos(eps) * sin(lam), cos(lam))
	return fposmod(ra + deg_to_rad((minute - Daylight.NOON) / 4.0), TAU)


## Ölçüm karesinin dakikası (probe; «hh:mm» → gün dakikası). Bilinmeyen durak NAN.
static func probe_minute(table: Dictionary, id: StringName) -> float:
	var probe: Dictionary = table.get("probe", {})
	if not probe.has(String(id)):
		return NAN
	var m := GameClock.parse_hhmm(probe[String(id)])
	return m if m >= 0.0 else NAN


## Ölçüm karesinin örneği (K58, K101; pelerinin okunurluğu: data/character/cape_light_stops.json, scenes/dev/cape_lineup.tscn,
## tools/palette_compare.py): durağın ölçüm dakikasında kampın ışığı, düz değerlerle: light_color, light_energy (× k), ambient_color,
## ambient_energy, ambient_sky, exposure, grade_night, saturation, contrast; ışığın azimutu ve yüksekliği (derece). Bilinmeyen durak boş.
static func probe_sample(table: Dictionary, id: StringName) -> Dictionary:
	var m := probe_minute(table, id)
	if is_nan(m):
		return {}
	var d := probe_day(table)
	var s := sample(table, "camp", d, m)
	if s.is_empty():
		return {}
	var dir: Vector3 = (s["light_dir"] as Vector3).normalized()
	var az := rad_to_deg(atan2(dir.x, -dir.z))
	return {
		"day_n": d, "minute": m, "s": float(s["s"]), "light_k": float(s["light_k"]),
		"light_color": s["light_color"], "light_energy": float(s["light_energy"]),
		"ambient_color": s["ambient_color"], "ambient_energy": float(s["ambient_energy"]), "ambient_sky": float(s["ambient_sky"]),
		"exposure": float(s["exposure"]), "grade_night": float(s["grade_night"]),
		"saturation": float(s.get("saturation", 1.0)), "contrast": float(s.get("contrast", 1.0)),
		"light_azimuth": az + 360.0 if az < 0.0 else az, "light_elevation": rad_to_deg(asin(clampf(dir.y, -1.0, 1.0))),
	}


## Ölçüm karesinin günü (probe.day_n; yoksa 1.171).
static func probe_day(table: Dictionary) -> int:
	return int((table.get("probe", {}) as Dictionary).get("day_n", GameCalendar.HOME_DAY))
