extends SceneTree
## Kodla müzik, ortam ve efekt basma aracı (K28, K61; audio.md §2–§4, godot.md §3.3). Oyun çalışırken sentez yoktur:
## bu araç tarifleri (data/audio/bake/*.json) okur, çalgı sınıfını adından yükler (res://scripts/audio/synth/<ad>.gd;
## static render(params, rng) → PackedFloat32Array) ve PCM'i ara WAV olarak audio/gen/_wav/<id>.wav'a yazar
## (klasörde .gdignore: ara dosya içe aktarılmaz). Hedefin .import'unu da yazar; WAV'ı Ogg'a çevirmek ve yerine koymak
## tools/bake_music.sh'nin işidir (Godot'nun GDScript'ten çağrılan Vorbis kodlayıcısı yoktur).
##
## Kullanım (tools/bake_music.sh sarar; doğrudan da çalışır):
##   godot --headless --path . -s res://tools/bake_music.gd -- [--only=camp_drone,wind_steppe] [--list]
##         [--recipes=<klasör>] [--out=<klasör>] [--source=<code|free:yol>]
##   --out verilirse WAV o klasöre yazılır, oyuna konmaz ve .import yazılmaz (kulak karşılaştırması adayı).
##   --source tarifin kaynağını bu koşu için değiştirir (ör. ücretsiz kaydı kodla basılanla karşılaştırmak).
##   --rms=<0..1> çıkışı bu RMS düzeyine çeker (kulak karşılaştırmasında adaylar aynı düzeyde dinlensin).
## Her basılan dosya için bir satır yazar: BAKED<TAB>tür<TAB>kimlik<TAB>WAV yolu<TAB>hedef yol (mutlak).
##
## Tarif: {id, kind, instrument | layers, tempo, bars, mode, density, seed, rate, loop, source, gain_db, ...}
##   kind: music (audio/gen/<id>.ogg; .import'ta loop, bpm, beat_count = bars × 2, bar_beats 2), ambience
##   (audio/ambience/gen/<id>.wav; 22,05 kHz mono QOA, ileri döngü, son -1), sfx (audio/sfx/gen/<id>.wav; QOA, döngüsüz),
##   wav (yalnız ara WAV; ör. şarkı ölçüsünün denetim kopuzu).
##   instrument: çalgının dosya adı (kopuz, drone, hujia, kaval, wind …); layers: [{instrument, gain_db, ...}] karışımı
##   (katmanın alanları tarifin alanlarının üstüne biner). Boş cümle: instrument "rest" (sessizlik).
##   source: "code" (varsayılan) ya da "free:<yol>": ücretsiz kaydı ffmpeg ile kırpar (start, seconds), monoya ve
##   hedef hıza çevirir; loop ise kuyruğu başa katlar. Yol proje köküne görelidir (assets/_free/sound/<id>/...).
## Aynı tarif aynı örnekleri verir (seed). Taşan örnek varsa düzey 0,98 tepeye çekilir ve uyarı yazılır.
## Çeşitler (hayvan ses bankası, audio.md §4 «Hayvan sesleri»): variants [{…}, …] verilirse her çeşit tarifin üstüne biner ve ayrı dosyadır:
##   <id>_1, <id>_2 … (tohum seed + sıra, çeşit kendi seed'ini vermezse). dir hedef klasörün alt klasörüdür (ör. "fauna": audio/sfx/gen/fauna/).
##   --only tarifin kimliğini de çeşidin kimliğini de tanır.

const RECIPE_DIR := "res://data/audio/bake"
const WAV_DIR := "res://audio/gen/_wav"
const TARGET_DIRS := {
	"music": "res://audio/gen",
	"ambience": "res://audio/ambience/gen",
	"sfx": "res://audio/sfx/gen",
}
const SYNTH_DIR := "res://scripts/audio/synth"
const KINDS: Array[String] = ["music", "ambience", "sfx", "wav"]
const PEAK_LIMIT := 0.98
const FFMPEG := "ffmpeg"

var _failed := 0


func _initialize() -> void:
	var args := _args(OS.get_cmdline_user_args())
	var recipes := _load_recipes(str(args.get("recipes", RECIPE_DIR)))
	var only := PackedStringArray(str(args.get("only", "")).split(",", false))
	if args.has("list"):
		for r: Dictionary in recipes:
			print("%s\t%s\t%s" % [r.get("id", "?"), r.get("kind", "?"), r.get("instrument", "layers")])
		quit(0)
		return
	var out_dir := str(args.get("out", ""))
	var count := 0
	for recipe: Dictionary in _expand_variants(recipes):
		var id := str(recipe.get("id", ""))
		if not only.is_empty() and not only.has(id) and not only.has(str(recipe.get("_base", ""))):
			continue
		if args.has("source"):
			recipe["source"] = str(args["source"])
		if args.has("rms"):
			recipe["rms"] = float(args["rms"])
		if _bake(recipe, out_dir):
			count += 1
	print("bake_music: %d dosya basıldı, %d hata" % [count, _failed])
	quit(1 if _failed > 0 else 0)


## Tarifi basar: WAV'ı yazar, hedefin .import'unu kurar, BAKED satırını yazar.
func _bake(recipe: Dictionary, out_dir: String) -> bool:
	var id := str(recipe.get("id", ""))
	var kind := str(recipe.get("kind", "music"))
	var problem := _recipe_problem(recipe)
	if not problem.is_empty():
		return _fail("%s: %s" % [id, problem])
	var rate := int(recipe.get("rate", SynthDsp.RATE))
	var started := Time.get_ticks_msec()
	var pcm := _render(recipe, rate)
	if pcm.is_empty():
		return _fail("%s: ses üretilemedi" % id)
	if float(recipe.get("rms", 0.0)) > 0.0 and SynthDsp.rms(pcm) > 0.0:
		SynthDsp.scale_in_place(pcm, float(recipe["rms"]) / SynthDsp.rms(pcm))
	var peak := SynthDsp.peak(pcm)
	if peak > PEAK_LIMIT:
		push_warning("%s: tepe %.3f; düzey %.3f'e çekildi" % [id, peak, PEAK_LIMIT])
		SynthDsp.scale_in_place(pcm, PEAK_LIMIT / peak)
	var wav_dir := out_dir if not out_dir.is_empty() else ProjectSettings.globalize_path(WAV_DIR)
	DirAccess.make_dir_recursive_absolute(wav_dir)
	var wav_path := wav_dir.path_join(id + ".wav")
	var err := SynthDsp.to_wav(pcm, rate).save_to_wav(wav_path)
	if err != OK:
		return _fail("%s: %s yazılamadı (%s)" % [id, wav_path, error_string(err)])
	var target := ""
	if out_dir.is_empty() and TARGET_DIRS.has(kind):
		var ext := ".ogg" if kind == "music" else ".wav"
		var target_dir := str(TARGET_DIRS[kind])
		if not str(recipe.get("dir", "")).is_empty():
			target_dir = target_dir.path_join(str(recipe["dir"]))
		var res_target := target_dir.path_join(id + ext)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))
		_write_import(res_target, kind, recipe)
		target = ProjectSettings.globalize_path(res_target)
	print("BAKED\t%s\t%s\t%s\t%s" % [kind, id, wav_path, target])
	print("  %s: %.2f sn, %d Hz, tepe %.2f, RMS %.3f (%d ms)" % [id, pcm.size() / float(rate), rate,
			SynthDsp.peak(pcm), SynthDsp.rms(pcm), Time.get_ticks_msec() - started])
	return true


## Çeşitli tarifleri açar: her çeşit tarifin üstüne biner (kimliği <id>_<sıra>, _base tarifin kimliği); çeşitsiz tarif olduğu gibi.
func _expand_variants(recipes: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for recipe: Dictionary in recipes:
		if not recipe.get("variants") is Array:
			out.append(recipe)
			continue
		var base := str(recipe.get("id", ""))
		var list: Array = recipe["variants"]
		for k in list.size():
			var v: Dictionary = recipe.duplicate(true)
			v.erase("variants")
			if list[k] is Dictionary:
				v.merge(list[k] as Dictionary, true)
			v["id"] = "%s_%d" % [base, k + 1]
			v["_base"] = base
			if not (list[k] as Dictionary).has("seed"):
				v["seed"] = int(recipe.get("seed", 1)) + k
			out.append(v)
	return out


func _render(recipe: Dictionary, rate: int) -> PackedFloat32Array:
	var source := str(recipe.get("source", "code"))
	if source.begins_with("free:"):
		return _from_free(recipe, source.substr(5), rate)
	var rng := SynthDsp.make_rng(int(recipe.get("seed", 1)))
	if recipe.get("layers") is Array:
		var mix := PackedFloat32Array()
		for layer: Variant in recipe["layers"]:
			var params: Dictionary = recipe.merged(layer as Dictionary, true)
			params.erase("layers")
			params["rate"] = rate
			var part := _instrument(params, rng)
			if mix.size() < part.size():
				mix.resize(part.size())
			SynthDsp.mix_into(mix, part, 0, 1.0)
		return mix
	var p := recipe.duplicate()
	p["rate"] = rate
	return _instrument(p, rng)


func _instrument(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var name := str(params.get("instrument", ""))
	if name == "rest":
		return SynthDsp.zeros(SynthSequencer.bar_samples(float(params.get("tempo", 52.0)), int(params.get("bars", 2)), int(params["rate"])))
	var path := SYNTH_DIR.path_join(name + ".gd")
	if not ResourceLoader.exists(path):
		_fail("çalgı yok: %s" % path)
		return PackedFloat32Array()
	var script := load(path) as GDScript
	if script == null or not _has_render(script):
		_fail("%s: static render(params, rng) yok" % path)
		return PackedFloat32Array()
	return script.call("render", params, rng)


func _has_render(script: GDScript) -> bool:
	for method: Dictionary in script.get_script_method_list():
		if str(method.get("name", "")) == "render":
			return true
	return false


## Ücretsiz kayıt: ffmpeg ile kırpılır, monoya ve hedef hıza çevrilir; loop ise kuyruk başa katlanır.
func _from_free(recipe: Dictionary, source: String, rate: int) -> PackedFloat32Array:
	var src := source if source.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(source)
	if not FileAccess.file_exists(src):
		_fail("%s: ücretsiz kayıt yok: %s" % [recipe.get("id", "?"), src])
		return PackedFloat32Array()
	var loop := bool(recipe.get("loop", false))
	var fold := float(recipe.get("fold", 2.0)) if loop else 0.0
	var seconds := float(recipe.get("seconds", 0.0))
	var tmp_dir := OS.get_environment("TMPDIR")
	if tmp_dir.is_empty() or not DirAccess.dir_exists_absolute(tmp_dir):
		tmp_dir = OS.get_temp_dir()
	var tmp := tmp_dir.path_join("bake_%s_%d.wav" % [recipe.get("id", "free"), Time.get_ticks_usec()])
	var ff := ["-y", "-v", "error", "-ss", str(float(recipe.get("start", 0.0))), "-i", src]
	if seconds > 0.0:
		ff.append_array(["-t", str(seconds + fold)])
	ff.append_array(["-ac", "1", "-ar", str(rate), "-c:a", "pcm_s16le", tmp])
	var output: Array = []
	if OS.execute(FFMPEG, PackedStringArray(ff), output, true) != 0:
		_fail("%s: ffmpeg başarısız: %s" % [recipe.get("id", "?"), "\n".join(PackedStringArray(output))])
		return PackedFloat32Array()
	var wav := AudioStreamWAV.load_from_file(tmp)
	DirAccess.remove_absolute(tmp)
	if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS:
		_fail("%s: ffmpeg çıktısı okunamadı" % recipe.get("id", "?"))
		return PackedFloat32Array()
	var data := wav.data
	var pcm := SynthDsp.zeros(data.size() / 2)
	for i in pcm.size():
		pcm[i] = data.decode_s16(i * 2) / 32768.0
	if loop and fold > 0.0 and pcm.size() > int(fold * rate):
		pcm = SynthDsp.fold_loop(pcm, pcm.size() - int(fold * rate), int(fold * rate), true)
	SynthDsp.scale_in_place(pcm, SynthDsp.db_to_gain(float(recipe.get("gain_db", 0.0))))
	return pcm


## Hedefin .import'u: yeni dosyada yalnız [remap] importer ve [params]; Godot'nun yazdığı dosyada yalnız [params]
## güncellenir (uid ve dest_files korunur). Sonraki godot --import gerisini doldurur.
func _write_import(res_target: String, kind: String, recipe: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(res_target) + ".import"
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(path):
		cfg.load(path)
	var params := {}
	match kind:
		"music":
			cfg.set_value("remap", "importer", "oggvorbisstr")
			var bars := int(recipe.get("bars", 2))
			params = {"loop": bool(recipe.get("loop", false)), "loop_offset": 0.0, "bpm": float(recipe.get("tempo", 52.0)),
				"beat_count": bars * SynthSequencer.BAR_BEATS, "bar_beats": SynthSequencer.BAR_BEATS}
		"ambience", "sfx":
			cfg.set_value("remap", "importer", "wav")
			var ambience := kind == "ambience"
			params = {"force/8_bit": false, "force/mono": true, "force/max_rate": ambience,
				"force/max_rate_hz": 22050 if ambience else int(recipe.get("rate", 22050)), "edit/trim": false,
				"edit/normalize": false, "edit/loop_mode": 2 if ambience or bool(recipe.get("loop", false)) else 1,
				"edit/loop_begin": 0, "edit/loop_end": -1, "compress/mode": 2}
	for key: String in params:
		cfg.set_value("params", key, params[key])
	cfg.save(path)


func _recipe_problem(recipe: Dictionary) -> String:
	if str(recipe.get("id", "")).is_empty():
		return "id yok"
	if not KINDS.has(str(recipe.get("kind", ""))):
		return "kind %s olmalı" % "/".join(KINDS)
	var source := str(recipe.get("source", "code"))
	if source == "code" and not (recipe.get("instrument") is String or recipe.get("layers") is Array):
		return "instrument ya da layers gerekli"
	if source != "code" and not source.begins_with("free:"):
		return "source code ya da free:<yol> olmalı"
	if str(recipe.get("kind")) == "music" and (float(recipe.get("tempo", 0)) <= 0.0 or int(recipe.get("bars", 0)) <= 0):
		return "müzikte tempo ve bars gerekli (vuruş bilgisi)"
	return ""


func _load_recipes(dir: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var abs_dir := ProjectSettings.globalize_path(dir) if dir.begins_with("res://") else dir
	if not DirAccess.dir_exists_absolute(abs_dir):
		_fail("tarif klasörü yok: %s" % dir)
		return out
	var files := DirAccess.get_files_at(abs_dir)
	files.sort()
	for file in files:
		if file.get_extension() != "json":
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(abs_dir.path_join(file)))
		if parsed is Dictionary:
			out.append(parsed)
		else:
			_fail("tarif okunamadı: %s" % file)
	return out


func _args(raw: PackedStringArray) -> Dictionary:
	var out := {}
	for a in raw:
		if not a.begins_with("--"):
			continue
		var body := a.substr(2)
		var eq := body.find("=")
		if eq == -1:
			out[body] = true
		else:
			out[body.substr(0, eq)] = body.substr(eq + 1)
	return out


func _fail(message: String) -> bool:
	printerr("bake_music: ", message)
	_failed += 1
	return false
