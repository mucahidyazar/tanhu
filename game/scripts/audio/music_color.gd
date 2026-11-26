class_name MusicColor
extends Resource
## Perde rengi (K59; audio.md §3 «Perde rengi», ses-tasarimi.md §12): ortam ve görev durumlarının üstüne biner,
## 6 × 22 klip yazılmaz. Dosyası `data/music/act_<n>.tres`'tir; MusicBank bankayı kurarken uygular, perde
## değişince AudioManager.set_music_color yeniden kurar.
##
## Bankanın katmanları bir öbek taşıyabilir (`"group"`, data/audio/banks/*.json):
## - `lead`: ezgiyi taşıyan çalgı. Öbeği `lead` olan katmanlardan yalnız adı `lead` olanı çalar, ötekiler susar
##   (I. Perde'de kopuz yerine arp ezgi taşır; kopuz kaçış gecesine dek müzikte yoktur).
## - `add`: perdenin eklediği renk (ör. `hujia`, `kaval`, `harp`). Öbeği `add` olan katman yalnız adı listede
##   varsa çalar.
## - `drum`: davul katmanlarına `drum_db` eklenir.
## Öbeksiz katman (dron, koro) perde renginden etkilenmez.

const SILENT_DB := -80.0

## Perdenin numarası (0 Önsöz, 1–6, 7 Sonsöz); koro sayacı bu numarayla tutulur.
@export var act := 0
## Ezgiyi taşıyan katmanın adı.
@export var lead: StringName = &"kopuz"
## Perdenin eklediği renk katmanları.
@export var add: Array[StringName] = []
## Davul öbeğine eklenen düzey (dB).
@export var drum_db := 0.0
## Ezgi (lead) katmanının cümle Playlist'indeki boş cümle kopyası (bankada yazılanın yerine geçer; -1 bankadaki kalır).
@export var rest_copies := 1
## Motifin bütününün çaldığı klip (bilgi: Önsöz'de doğum).
@export var motif_clip: StringName = &""


## Katmanın perde rengindeki ek düzeyi (dB): susan katmanda SILENT_DB, ötekinde 0 ya da drum_db.
func layer_db(layer_name: StringName, group: String) -> float:
	match group:
		"lead":
			return 0.0 if layer_name == lead else SILENT_DB
		"add":
			return 0.0 if add.has(layer_name) else SILENT_DB
		"drum":
			return drum_db
	return 0.0


## Boş cümlenin kopya sayısı: lead öbeğinde rest_copies (≥ 0 ise), başka yerde bankanın yazdığı.
func rest_count(group: String, written: int) -> int:
	return rest_copies if group == "lead" and rest_copies >= 0 else written
