class_name PaceLimit
extends RefCounted
## Kişilerin hız sınırı (E20, 2026-11-08; kullanıcı: «insanlar çok hızlı hareket ediyorlar, maksimum benim koşma hızım kadar hareket etsinler»):
## oyuncunun dışındaki her kişi (yürüyen, koşan, bineğin sırtındaki; Dailin kalabalığının kartı) o an oyuncunun en yüksek koşu hızını aşmaz.
## Sınır oyuncunun kişisinindir: Çocukluk'ta çocuğun koşusu (PlayerController.CHILD_RUN_SPEED, 3,6 m/sn; küçük Mete'nin koşu klibi de oraya
## yeter), Yola Çıkış'ta ve Serbest Gez'in yetişkininde yetişkininki (ADULT_RUN, 4,6 m/sn); binekli kişi de aynı sınırdadır (Teoman'ın
## atlıları, koyunun sırtındaki Luhun): bineğin dörtnalı sınır değildir. Sahneler sınırı kendileri uygular: StoryMover.go'nun hızı
## (ChildhoodScene, DepartScene: limit), atlı düzeni (RiderColumn.limit_speeds: kıvrımın dışındaki atlı liderden hızlı gider), kalabalık
## (CrowdCards.speed_cap: saat görünür biçimde akarken kişi yetişmek için koşmaz, ışınlanmaz). Hız yüzünden sahnenin akışı uzarsa beklemeler
## ve yollar oyuncunun hızına göre ayarlanır (sahnelerin verisi).
## Ölçü (Probe) kişilerin gerçek yatay hızını en az window saniyelik aralıklarla izler: kare titremesi sayılmaz, ışınlanma sayılır. Otomatik
## oynatma (ChildhoodAutoplay, DepartAutoplay) ve sınamalar en yükseğini yazar.
##   var cap := PaceLimit.run_cap(player)                    # o anki kişinin en yüksek koşusu (m/sn)
##   mover.go(path, PaceLimit.limit(2.9, cap))
##   var probe := PaceLimit.Probe.new()
##   probe.sample("luhun_child", mover.position(), scene.clock)   # her kare
##   probe.peak("luhun_child"); probe.over(cap)                # en yüksek hız; sınırı aşanlar

## Çocuğun ve yetişkinin en yüksek koşusu (m/sn): PlayerController.CHILD_RUN_SPEED ve PlayerController.run_speed'in varsayılanı (sınama
## ikisinin aynı kaldığını denetler).
const CHILD_RUN := 3.6
const ADULT_RUN := 4.6
## Ölçünün payı (m/sn): yuvarlama ve kare adımının yanılgısı sınırı aşmak sayılmaz.
const TOLERANCE := 0.03
## Sahne verisinde kişi hızı taşıyan anahtarlar (m/sn; data_speeds).
const PERSON_KEYS: Array[String] = ["speed", "out_speed", "walk_speed"]


## O anki kişinin en yüksek koşusu (m/sn): oyuncunun run_speed'i (çocukta çocuğun, yetişkinde yetişkinin; yük çarpanı sayılmaz, en yüksek
## koşudur). Oyuncu yoksa yetişkininki.
static func run_cap(player: Object) -> float:
	if player == null or not is_instance_valid(player):
		return ADULT_RUN
	var run: Variant = player.get(&"run_speed")
	return float(run) if run is float and float(run) > 0.0 else ADULT_RUN


## Hız sınırın içinde (saf): eksi hız 0'dır.
static func limit(speed: float, cap: float) -> float:
	return clampf(speed, 0.0, maxf(cap, 0.0))


## Sahne verisindeki kişi hızları (saf; sınama): yol boyu bütün PERSON_KEYS anahtarları (m/sn) ile atlı düzeninin «speeds»i (approach,
## pass, leave). Saatin akış hızı (lapse_speed: oyun dk/sn) kişi hızı değildir. Döner: [[yol, değer], ...] (yol «steps/1/rival/speed» gibi).
static func data_speeds(data: Variant, path := "") -> Array:
	var out: Array = []
	if data is Dictionary:
		var d: Dictionary = data
		for key: Variant in d:
			var here := "%s/%s" % [path, key] if not path.is_empty() else str(key)
			var value: Variant = d[key]
			if (value is float or value is int) and PERSON_KEYS.has(str(key)):
				out.append([here, float(value)])
			elif str(key) == "speeds" and value is Dictionary:
				for gait: Variant in value:
					out.append(["%s/%s" % [here, gait], float(value[gait])])
			else:
				out.append_array(PaceLimit.data_speeds(value, here))
	elif data is Array:
		for i in (data as Array).size():
			out.append_array(PaceLimit.data_speeds(data[i], "%s/%d" % [path, i]))
	return out


## Hızı sınırı aşanlar (saf): {kimlik: hız} sözlüğünden cap + TOLERANCE'ı geçenlerin kimlikleri.
static func over(speeds: Dictionary, cap: float) -> PackedStringArray:
	var out := PackedStringArray()
	for id: Variant in speeds:
		if float(speeds[id]) > cap + TOLERANCE:
			out.append(str(id))
	return out


## Konumların ölçtüğü en yüksek yatay hız (saf): ardışık örnekler arasında en az window saniye geçince ölçülür (m/sn). points ve times aynı
## boydadır; zaman artar.
static func peak_speed(points: PackedVector3Array, times: PackedFloat64Array, window := 0.2) -> float:
	var probe := Probe.new()
	probe.window = window
	for i in mini(points.size(), times.size()):
		probe.sample("p", points[i], times[i])
	return probe.peak("p")


## Kişilerin hız ölçüsü: kişi başına son ölçünün yeri ve zamanı; en az window saniye geçince hız ölçülür, kişinin en yükseği tutulur. Gizlenen
## ya da sahnenin yerine koyduğu (görünmeden) kişi forget ile yeniden başlar: görünmezken alınan yer hız sayılmaz.
class Probe:
	extends RefCounted

	## Ölçü aralığı (sn).
	var window := 0.2
	## Kimlik → en yüksek hız (m/sn).
	var peaks: Dictionary = {}
	## Kimlik → en yükseğin ölçüldüğü an (sn).
	var peak_at: Dictionary = {}
	var _from: Dictionary = {}

	## Kişinin o anki yeri (dünya) ve zamanı (sn; sahnenin saati: Engine.time_scale ile akar).
	func sample(id: String, at: Vector3, t: float) -> void:
		var last: Variant = _from.get(id)
		if last == null:
			_from[id] = Vector3(at.x, at.z, t)
			if not peaks.has(id):
				peaks[id] = 0.0
			return
		var from: Vector3 = last
		var dt := t - from.z
		if dt < window:
			return
		var v := Vector2(at.x - from.x, at.z - from.y).length() / dt
		if v > float(peaks.get(id, 0.0)):
			peaks[id] = v
			peak_at[id] = t
		_from[id] = Vector3(at.x, at.z, t)

	## Kişinin son yeri unutulur (gizlendi ya da görünmeden yerine kondu); en yükseği kalır.
	func forget(id: String) -> void:
		_from.erase(id)

	func peak(id: String) -> float:
		return float(peaks.get(id, 0.0))

	## En hızlı kişi: [kimlik, hız] (ölçü yoksa ["", 0]).
	func worst() -> Array:
		var best := ["", 0.0]
		for id: String in peaks:
			if float(peaks[id]) > float(best[1]):
				best = [id, float(peaks[id])]
		return best

	## Sınırı aşanların kimlikleri.
	func over(cap: float) -> PackedStringArray:
		return PaceLimit.over(peaks, cap)

	## Günlük satırı: kişi başına en yüksek hız, en hızlıdan başlayarak (m/sn) ve sınır.
	func report(cap: float) -> String:
		var ids: Array = peaks.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return float(peaks[a]) > float(peaks[b]))
		var parts := PackedStringArray()
		for id: String in ids:
			parts.append("%s %.2f" % [id, float(peaks[id])])
		return "sınır %.2f m/sn · %s · aşan: %s" % [cap, ", ".join(parts), "yok" if over(cap).is_empty() else ", ".join(over(cap))]
