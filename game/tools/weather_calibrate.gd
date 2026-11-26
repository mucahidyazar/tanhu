extends SceneTree
## Havanın ayarlı ağırlıklarını yazar (weather.md §5.6, H5): her iklim satırı (iklim × mevsim, kampın dört satırı dahil) ve oyunun
## kullandığı dışlamalı satırlar (I. Perde Kışlak'ı: yoğun kar ve tipi; kampın camp3 ocağı yanana dek sev ≥3 türler) için
## WeatherPlanner.calibrate koşar ve data/weather/weights.json'a yazar. Oyun ağırlığı oradan okur: GDScript'te bir satırın ayarı
## ≈1–3 sn sürer, dünya kurulurken koşmaz. Sınama (test_weather_planner.gd) yazılan ağırlıkları prototipin ayarıyla karşılaştırır.
##
##   source tools/_godot_lock.sh; godot_import_locked
##   "$GODOT" --headless --path . -s res://tools/weather_calibrate.gd [-- --only=orkhon]
##
## climates.json'un payları değişince yeniden koşulur; dosyanın shares_hash'i payların özetidir (sınama eskiyen ağırlığı yakalar).

const OUT := "res://data/weather/weights.json"


func _init() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
	WeatherData.reload()
	var rows := calibration_rows()
	var old: Dictionary = WeatherData.weights_table().get("weights", {})
	var out := {}
	var t0 := Time.get_ticks_msec()
	for r: Array in rows:
		var key := WeatherData.weight_key(r[0], r[1], r[2])
		if not only.is_empty() and not key.begins_with(only):
			if old.has(key):
				out[key] = old[key]
			continue
		var t1 := Time.get_ticks_msec()
		var target := WeatherData.target_shares(r[0], r[1], r[2])
		out[key] = WeatherPlanner.calibrate(target, r[0], r[1], r[2])
		print("[weather_calibrate] %s %d ms" % [key, Time.get_ticks_msec() - t1])
	var doc := {
		"meta": {
			"v": 1,
			"doc": "docs/design/weather.md §5.6 (hedef pay → ayarlı ağırlık); godot.md §8.2",
			"tool": "tools/weather_calibrate.gd yazar (WeatherPlanner.calibrate: tohum 0x5eed, turlar 800×4 + 2000×4, son dört turun log-ortalaması); elle değiştirilmez",
			"date": Time.get_date_string_from_system(),
			"shares_hash": shares_hash(),
			"rows": out.size(),
		},
		"weights": out,
	}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(doc, "\t", false, true) + "\n")
	f.close()
	print("[weather_calibrate] %d satır, %.1f sn → %s" % [out.size(), (Time.get_ticks_msec() - t0) / 1000.0, OUT])
	quit()


## Ayarlanacak satırlar: [iklim, mevsim, dışlama].
static func calibration_rows() -> Array:
	var rows: Array = []
	for climate in WeatherData.climate_ids():
		for season in WeatherData.seasons_of(climate):
			rows.append([climate, season, PackedStringArray()])
	rows.append(["hexi", "winter", PackedStringArray(["heavy_snow", "blizzard"])])
	var heavy := heavy_types()
	for season in ["camp_spring", "camp_summer", "camp_autumn", "camp_winter"]:
		rows.append(["orkhon", season, heavy])
	return rows


## sev ≥3 türler (tür sırasıyla): camp3'ün ocağı yanana dek kampta dışlanır (weather.md §6.3).
static func heavy_types() -> PackedStringArray:
	var out := PackedStringArray()
	for i in WeatherData.count():
		if WeatherData.sev[i] >= 3:
			out.append(String(WeatherData.id_of(i)))
	return out


## climates.json'un paylarının özeti: satırların share, p_hail, showery ve dur alanları.
static func shares_hash() -> String:
	var parts := PackedStringArray()
	for climate in WeatherData.climate_ids():
		for season in WeatherData.seasons_of(climate):
			var r := WeatherData.row(climate, season)
			parts.append("%s:%s:%s:%s:%s:%s" % [climate, season, JSON.stringify(r.get("share")), str(r.get("p_hail", 0)), str(r.get("showery", 0)), JSON.stringify(r.get("dur", {}))])
	return "|".join(parts).md5_text()
