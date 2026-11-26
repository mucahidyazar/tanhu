class_name FaunaVoiceRules
extends RefCounted
## Hayvan sesinin kuralları (saf; audio.md §4 «Hayvan sesleri», ses-tasarimi.md §6.2, §7.4; K3, K65): tekrar sınırı (aynı kimlik ≥45 sn, aynı
## tür ≥20 sn: Diablo IV'ün kopya sınırı; zaman damgasıyla, Godot'un hazır sınırı yalnız oynatıcı başına max_polyphony'dir), görünmeyen hayvanın
## sesi oyuncuya ≥150 m'den gelir (yürüyüp arayınca bulunamayan yakın ses olmaz), at kişnemesinin iki kümesi (≤60 m kurt ya da ≤1 km gök
## gürültüsü fear, öteki calm), kurt sürüsünün uluması (3–5 çalış, 2–6 sn ara, perde 0,85–1,15). Ayla bağ yoktur.
##   var rules := FaunaVoiceRules.new(FaunaBank.shared().rules())
##   if rules.can_play("wolf_howl", "wolf", now): rules.mark("wolf_howl", "wolf", now)

var same_id_s := 45.0
var same_kind_s := 20.0
var unseen_min := 150.0
var wolf_fear_m := 60.0
var thunder_fear_m := 1000.0
var howl_calls := Vector2i(3, 5)
var howl_gap := Vector2(2.0, 6.0)
var howl_pitch := Vector2(0.85, 1.15)

var _last_id: Dictionary = {}
var _last_kind: Dictionary = {}


func _init(r: Dictionary = {}) -> void:
	same_id_s = float(r.get("same_id_s", same_id_s))
	same_kind_s = float(r.get("same_kind_s", same_kind_s))
	unseen_min = float(r.get("unseen_min_m", unseen_min))
	wolf_fear_m = float(r.get("wolf_fear_m", wolf_fear_m))
	thunder_fear_m = float(r.get("thunder_fear_m", thunder_fear_m))
	if r.get("howl_calls") is Array:
		howl_calls = Vector2i(int(r["howl_calls"][0]), int(r["howl_calls"][1]))
	if r.get("howl_gap_s") is Array:
		howl_gap = Vector2(float(r["howl_gap_s"][0]), float(r["howl_gap_s"][1]))
	if r.get("howl_pitch") is Array:
		howl_pitch = Vector2(float(r["howl_pitch"][0]), float(r["howl_pitch"][1]))


## Çalınabilir mi (now: sn)? Aynı küme ≥same_id_s, aynı tür ≥same_kind_s önce çalmış olmalı.
func can_play(cluster: String, kind: String, now: float) -> bool:
	if _last_id.has(cluster) and now - float(_last_id[cluster]) < same_id_s:
		return false
	if _last_kind.has(kind) and now - float(_last_kind[kind]) < same_kind_s:
		return false
	return true


func mark(cluster: String, kind: String, now: float) -> void:
	_last_id[cluster] = now
	_last_kind[kind] = now


## Son çalış (yoksa -INF).
func last_played(cluster: String) -> float:
	return float(_last_id.get(cluster, -INF))


func reset() -> void:
	_last_id.clear()
	_last_kind.clear()


## Atın kümesi (saf): ≤60 m kurt ya da ≤1 km gök gürültüsü korku, öteki sakin.
func horse_cluster(wolf_m: float, thunder_m: float = INF) -> String:
	return "horse_fear" if wolf_m <= wolf_fear_m or thunder_m <= thunder_fear_m else "horse_calm"


## Görünmeyen hayvanın sesinin yeri (saf): kaynak (toward) dinleyiciye min_d'den yakınsa dinleyiciden kaynağın yönünde min_d'ye itilir; kaynak
## dinleyicinin üstündeyse verilen yedek yönde.
static func unseen_point(listener: Vector2, toward: Vector2, min_d: float = 150.0, fallback_dir: Vector2 = Vector2.UP) -> Vector2:
	var off := toward - listener
	var d := off.length()
	if d >= min_d:
		return toward
	var dir := off / d if d > 0.5 else fallback_dir.normalized()
	return listener + dir * min_d


## Kurt sürüsünün çalışları (saf ama rng ilerler): [Vector2(gecikme sn, perde), ...]; ilki 0 gecikmelidir.
func pack_calls(rng: RandomNumberGenerator) -> Array[Vector2]:
	var n := rng.randi_range(howl_calls.x, howl_calls.y)
	var out: Array[Vector2] = []
	var t := 0.0
	for k in n:
		out.append(Vector2(t, rng.randf_range(howl_pitch.x, howl_pitch.y)))
		t += rng.randf_range(howl_gap.x, howl_gap.y)
	return out
