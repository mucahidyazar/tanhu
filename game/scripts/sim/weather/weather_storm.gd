class_name WeatherStorm
extends RefCounted
## Şimşek, yıldırım ve gök gürültüsü (saf; weather.md §3.2, §8.7, §10.2, H1, H12): fırtına hücresinin şimşek dizisi, yıldırım hedefi
## (uzun ve yalnız olana iner; adil kurallar), vuruşun etkisi, Serbest Gez'in tasarlanmış yakın düşüşü, gök gürültüsünün gecikmesi
## (d / 343 sn) ve bandı. Prototipin weather-core.js'inden birebir; zaman hava saati saniyesidir ((hourAbs − t0) × 150).

const SALT_EVENTS := 0x5f3759df
## Ses hızı (m/sn) ve duyulma sınırı (m).
const SPEED := 343.0
const HEAR_M := 10000.0
## ≤3 km gök gürültüsü gizliliği örter (§8.3).
const MASK_M := 3000.0
## Aday yükseklik eşiği: yaya (1,7 m) seçilmez, açıkta atlı (2,6 m) seçilir (§8.7).
const STRIKE_MIN_H := 2.0
## Hücre: yere iniş payı, iniş dairesi (m), doğal yakın düşüş sınırı (m); şimşek hızı uzakken ve tepedeyken (gdk⁻¹).
const STRIKE_SHARE := 0.3
const DISC_M := 1200.0
const NEAR_M := 60.0
const FLASH_FAR := 2.0
const FLASH_OVERHEAD := 5.0


## Bir şimşek: t hücre başından sn; ground yere iner; x, z oyuncuya göre metre (x doğu, z güney); d uzaklık; strokes dönüş vuruşu;
## near tasarlanmış yakın düşüş (u, v hücrenin zarı). wx, wz, target, warned hazırlıkta yazılır.
class Event:
	extends RefCounted
	var t := 0.0
	var ground := false
	var x := 0.0
	var z := 0.0
	var d := 0.0
	var strokes := 1
	var near := false
	var u := 0.0
	var v := 0.0
	var wx := NAN
	var wz := NAN
	var target: Dictionary = {}
	var warned := false


static func thunder_delay(d: float) -> float:
	return d / SPEED


## Uzaklıkla bant (§10.2): ≤600 m thunder_crack, ≤3 km thunder, ≤10 km thunder_far; ötesi duyulmaz ("").
static func thunder_band(d: float) -> String:
	if d <= 600.0:
		return "thunder_crack"
	if d <= 3000.0:
		return "thunder"
	return "thunder_far" if d <= HEAR_M else ""


## Fırtına hücresinin şimşek dizisi (§8.7): yaklaşma %25 (8 km → b), tepede %50 (b, 0–2 km), uzaklaşma %25; 2 / 5 / 2 gdk⁻¹, %30'u yere
## iner, iniş hücre merkezinin 1,2 km'lik dairesinde. near: tasarlanmış yakın düşüş olasılığı (Serbest Gez 0,6, oyun 0,25; tepede,
## fırtına başına bir kez). Fırtına başına ≤1 yakın (≤60 m) düşüş. out yeniden kullanılır.
static func storm_events(t0: float, t1: float, p_seed: int, zone_hash: int, flow_x: float, flow_z: float, near: float, rate: float,
		out: Array[Event]) -> Array[Event]:
	out.clear()
	var rng := WeatherRng.new(WeatherRng.hash32(p_seed & WeatherRng.MASK, zone_hash, floori(t0 * 4.0), SALT_EVENTS))
	var span := maxf(1.0, (t1 - t0) * WeatherPlanner.S_PER_H)
	var b := rng.next() * 2000.0
	var side := -1.0 if rng.next() < 0.5 else 1.0
	var l := sqrt(maxf(0.0, 8000.0 * 8000.0 - b * b))
	var px := -flow_z * side
	var pz := flow_x * side
	# Çekim sırası prototipinkidir: önce olasılık zarı, tutarsa an zarı.
	var near_at := -1.0
	if rng.next() < near:
		near_at = span * (0.25 + 0.5 * rng.next())
	var near_done := false
	var nat_near := false
	var t := 0.0
	while true:
		var u := t / span
		var lam := ((FLASH_FAR if (u < 0.25 or u >= 0.75) else FLASH_OVERHEAD) * rate) / 60.0
		t += -log(1.0 - rng.next()) / maxf(1e-6, lam)
		if near_at >= 0.0 and not near_done and t >= near_at:
			near_done = true
			var ne := Event.new()
			ne.t = near_at
			ne.ground = true
			ne.d = 50.0
			ne.strokes = 2 + floori(rng.next() * 3.0)
			ne.near = true
			ne.u = rng.next()
			ne.v = rng.next()
			out.append(ne)
		if t >= span:
			break
		var ph := t / span
		var along := 0.0
		if ph < 0.25:
			along = -l * (1.0 - ph / 0.25)
		elif ph >= 0.75:
			along = l * ((ph - 0.75) / 0.25)
		var cx := flow_x * along + px * b
		var cz := flow_z * along + pz * b
		var ground := rng.next() < STRIKE_SHARE
		# Yere inen hücre merkezinin 1,2 km'lik dairesinde; bulut içi hücrenin yarısında (yön ve gök gürültüsünün kaynağı).
		var r := (DISC_M if ground else DISC_M * 0.5) * sqrt(rng.next())
		var th := rng.next() * PI * 2.0
		cx += cos(th) * r
		cz += sin(th) * r
		var d := sqrt(cx * cx + cz * cz)
		if ground and d <= NEAR_M:
			if near_at >= 0.0 or nat_near:
				var s := (NEAR_M + 1.0 + rng.next() * 40.0) / maxf(1.0, d)
				cx *= s
				cz *= s
				d = sqrt(cx * cx + cz * cz)
			else:
				nat_near = true
		var e := Event.new()
		e.t = t
		e.ground = ground
		e.x = cx
		e.z = cz
		e.d = d
		e.strokes = 1 + floori(rng.next() * 4.0) if ground else 1 + floori(rng.next() * 2.0)
		out.append(e)
	if near_at >= 0.0:
		out.sort_custom(func(x: Event, y: Event) -> bool: return x.t < y.t)
	return out


static func _lone(v: Variant) -> float:
	if v is float or v is int:
		return float(v)
	if v is bool:
		return 1.0 if v else 0.4
	if v == "edge":
		return 0.7
	if v == "forest":
		return 0.4
	return 1.0


## Yıldırım hedefi (§8.7): 45 m içinde en büyük h_eff − 0,15 × uzaklık; skor > 0 değilse noktaya (boş). cands: [{id, key?, kind (tree,
## pole, tower, structure, cart), x, z, h, lone?, ridge?, building?}]. rules: radius, child {x, z} (25 m içinde hedef yok), player {x, z,
## mounted, open, ridge, lone}, difficulty, now (hourAbs), struck {anahtar: hourAbs}, structures (false: bu fırtınada yapı vuruldu).
## Döner: aday, {id: "player", kind: "player"} ya da boş.
static func strike_pick(cands: Array, px: float, pz: float, rules: Dictionary = {}) -> Dictionary:
	var radius := float(rules.get("radius", 45.0))
	var now := float(rules.get("now", 0.0))
	var child: Dictionary = rules.get("child", {}) if rules.get("child") is Dictionary else {}
	var struck: Dictionary = rules.get("struck", {}) if rules.get("struck") is Dictionary else {}
	var best: Dictionary = {}
	var best_score := 0.0
	for cv: Variant in cands:
		if not cv is Dictionary:
			continue
		var c: Dictionary = cv
		if bool(c.get("building", false)):
			continue
		var cx := float(c.get("x", 0.0))
		var cz := float(c.get("z", 0.0))
		var d := _dist(cx - px, cz - pz)
		if d > radius:
			continue
		if not child.is_empty() and _dist(cx - float(child["x"]), cz - float(child["z"])) < 25.0:
			continue
		var kind := str(c.get("kind", ""))
		if kind == "structure" or kind == "tower" or kind == "pole":
			if rules.get("structures") is bool and not bool(rules["structures"]) and kind != "pole":
				continue
			var key: Variant = c.get("key", c.get("id"))
			var at: Variant = struck.get(key)
			if (at is float or at is int) and now - float(at) < 24.0:
				continue
		var h_eff := float(c.get("h", 0.0)) * _lone(c.get("lone", true)) + float(c.get("ridge", 0.0))
		if h_eff < STRIKE_MIN_H:
			continue
		var score := h_eff - 0.15 * d
		if score > best_score:
			best = c
			best_score = score
	var pl: Variant = rules.get("player")
	if pl is Dictionary and str(rules.get("difficulty", "normal")) != "story" and child.is_empty():
		var p: Dictionary = pl
		var d := _dist(float(p["x"]) - px, float(p["z"]) - pz)
		var h := 2.6 if bool(p.get("mounted", false)) and p.get("open", true) != false else 1.7
		var h_eff := h * _lone(p.get("lone", true)) + float(p.get("ridge", 0.0))
		if d <= radius and h_eff >= STRIKE_MIN_H:
			var score := h_eff - 0.15 * d
			if score > best_score:
				best = {"id": "player", "kind": "player"}
	return best


## Vuruşun etkisi (§8.7, §8.16): okuyan sahiptir (yapı, yerleşim, oyuncu). felt keçe ıslaklığı, dry kuru fırtına.
static func strike_effect(target: Dictionary, felt: float = 0.0, dry: bool = false, difficulty: String = "normal") -> Dictionary:
	var kind := str(target.get("kind", "ground"))
	var fire := felt < 0.5 and difficulty != "story" and ((dry or felt < 0.5) if difficulty == "hard" else (dry and felt < 0.3))
	match kind:
		"player":
			return {"kind": kind, "hp_k": 0.35, "hp_floor": 1, "wound": false, "fall": false, "stagger": 1.2, "deaf": 3, "throw_below_bond": 40, "drop_torch": true}
		"structure":
			return {"kind": kind, "blunt": 25, "ignite": fire, "power": 30, "scorch": true}
		"tower":
			return {"kind": kind, "blunt": 40, "ignite": false, "scorch": true}
		"pole":
			var sky: bool = target.get("id") == "sky_pole" or target.get("pole") == "sky_pole"
			return {"kind": kind, "blunt": 0 if sky else 25, "ignite": dry and felt < 0.3, "power": 70 if sky else 30, "scorch": true, "omen": sky}
		"cart":
			return {"kind": kind, "blunt": 15, "unit": "c_tilt", "spook": true}
		"tree":
			return {"kind": kind, "char": true, "smoke_s": 60, "struck": true, "charcoal": 2}
	return {"kind": "ground", "scorch": true, "scorch_s": 120}


## Oyuncunun Can'ı (§8.7): en çok %35 düşer, 1'in altına inmez, Yara ve Düşüş yok.
static func strike_hp(hp: float, hp_max: float) -> float:
	return maxf(minf(hp, 1.0), hp - 0.35 * hp_max)


## Serbest Gez'in tasarlanmış düşüşü (§8.7): Çocuktan 30–70 m, kameranın baktığı yönde (kadraj), yanlara ±18 m; u, v hücrenin zarı.
## Döner: [x, z].
static func near_point(cx: float, cz: float, fwd_x: float, fwd_z: float, u: float, v: float) -> PackedFloat64Array:
	var l := _dist(fwd_x, fwd_z)
	if l <= 0.0:
		l = 1.0
	var fx := fwd_x / l
	var fz := fwd_z / l
	var along := 30.0 + 40.0 * u
	var side := (v - 0.5) * 36.0
	return PackedFloat64Array([cx + fx * along - fz * side, cz + fz * along + fx * side])


## K98 kadrajında tasarlanmış düşüş (weather.md §8.7'nin Godot karşılığı): prototipin 30–70 m'si alçak kamerasının kadrajıydı (79 m
## ileri); K98'in 38° ve 28 m'lik kadrajı zeminde ≈10 m geriden ≈25 m ileriye uzanır (odağın derinliğinde ±16 m, üst kenarda ±25 m
## yana). Çocuğun 25 m kuralıyla kadrajın içinde kalan yer yalnız üst köşelerdir: düşüş 20–24 m ileride, 15–19 m yanda (yanı v'nin zarı
## seçer), Çocuktan 25–31 m. Varsayılan uzaklıkta şerit üst kenarda kısa görünür, kadraj dışına taşan düşüşte kenarın ayağı çizilir;
## kamera 40 m'ye açılınca şerit kadrajın içindedir. Döner: [x, z].
static func near_point_frame(cx: float, cz: float, fwd_x: float, fwd_z: float, u: float, v: float) -> PackedFloat64Array:
	var l := _dist(fwd_x, fwd_z)
	if l <= 0.0:
		l = 1.0
	var fx := fwd_x / l
	var fz := fwd_z / l
	var along := 20.0 + 4.0 * u
	var side := (15.0 + 4.0 * absf(v * 2.0 - 1.0)) * (-1.0 if v < 0.5 else 1.0)
	return PackedFloat64Array([cx + fx * along - fz * side, cz + fz * along + fx * side])


## Kayan noktası 64 bitlik uzaklık (Vector2 32 bittir).
static func _dist(dx: float, dz: float) -> float:
	return sqrt(dx * dx + dz * dz)
