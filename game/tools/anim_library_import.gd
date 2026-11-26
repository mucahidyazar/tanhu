extends SceneTree
## E9 hareket paketini (K90; assets/_meshy_raw/_anim_library, .gdignore'lu) oyun kaynağına çevirir ve ölçer. Ham GLB'ler
## yalnız geliştirme ortamındadır (GLB başına 40 MB'lık ağ ve doku taşırlar); dışa aktarılmış oyun klipleri buradan okur.
## Tanım data/clip_library.json'dadır; araç kredi harcamaz, Meshy'yi çağırmaz.
##
## Üç adım, sırayla (game/ klasöründe):
##   Godot --headless --path . -s res://tools/anim_library_import.gd -- --donor
##       assets/animations/donor/donor.glb: taşıyıcının yalnız iskeleti (donor_walking_armature.glb'nin ağı ve klibi
##       atılır). Dosya yeniyse ardından içe aktarma: source tools/_godot_lock.sh && godot_import_locked
##   Godot ... -- --clips [anahtar ...]
##       assets/animations/library/<key>.res: kütüphanenin her taşıyıcı klibi (anahtar verilirse yalnız onlar), GLB'den
##       meshy_name'iyle (RESET atlanır, iz yolları taşıyıcı iskeletin yoluna göre). GLB'nin dinlenme pozu taşıyıcınınkinden
##       ayrışırsa o GLB reddedilir. kind "derived" klipler ana klibinden türetilir (ClipLibrary.reverse_clip, 0 kredi);
##       pose_fix'li klibe düzeltme işlenir (ClipLibrary.apply_pose_fix).
##   Godot ... -- --measure [id ...]
##       data/clip_library_measure.json (biçim: dosyanın _aciklama'sı): her klibin süresi, döngüye uygunluğu, yürüme ve
##       koşmada doğal hızı, oturuşta kalça yüksekliği; her karakterde klip başına zemin payı (temas kemikleri tanımın
##       contact'ı), bacak düzeltmesi (tanımın leg_fit'i) ve kalça ile ayak boşluğu. id verilmezse modeli olan her karakter
##       (karakter başına ≈70 sn). Paralel koşu için:
##       --measure --part=<yol> id ...  yalnız o karakterleri <yol>'a yazar; --merge <yol> ... parçaları birleştirir.
##       --only=<anahtar>,<anahtar> yalnız o klipleri ölçer, kişinin öteki ölçüleri ölçü dosyasından kalır.

const LIBRARY_DIR := ClipLibrary.LIBRARY_DIR
const DONOR_SCENE := ClipLibrary.DONOR_SCENE
const MEASURE_PATH := ClipLibrary.MEASURE_PATH
## Taşıyıcı iskeletin kaynağı: ağı ve klibi olan en küçük dosya (yalnız kemikleri ve deri bağı alınır).
const DONOR_SOURCE := "donor_walking_armature.glb"
const CARRIER := "_anim_library"
const EXPORT := preload("res://tools/clip_library_export.gd")
const FIT_TOOL := ClipLibrary.FIT_TOOL
## Zemin payı için klip başına örnek kare (kural PoseFit.floor_times ve floor_offset: belge sitesinin dışa aktarması da oradan ölçer).
const SAMPLES := PoseFit.FLOOR_SAMPLES
## Bu hızdan (m/sn) hızlı ilerleyen ham klipte doğal hız kökün hızıdır; ayağın kayma hızı (PoseFit.stance_speed) yalnız yerinde
## kliplerde kullanılır: duruş karelerine bakar, kök hızından %10-39 sapıyordu ve ayak o oranda kayardı.
const ROOT_MOTION_MIN := 0.05
## Bacak düzeltmesi (tanımın leg_fit'i): boşluk bu kadarı (metre) aşmıyorsa dokunulmaz; düzeltmeden sonra kalça ve diz REST kadar
## yukarıda kalır (köşeler birbirine girmesin), kalan boşluk STEP'ten büyükse yeniden ölçülüp düzeltilir. Geçişte tek tur: bacak uzanıkken
## inen kalça cüppenin baldıra bağlı eteğini zemine sokar, yeniden ölçmek kişiyi eteğin üstüne kaldırıp kalçayı daha da indirirdi.
const SEAT_FIT_MIN := 0.03
const FOOT_FIT_MIN := 0.015
const SEAT_FIT_REST := 0.01
const FOOT_FIT_REST := 0.003
const LEG_FIT_STEP := 0.005
const LEG_FIT_ROUNDS := 3
## Yere dayanan el (leg_fit hands): elin en alt köşesi zeminin bu kadar üstünde kalır; kalça inmediyse ve el bu kadardan az şaşmışsa dokunulmaz.
const HAND_FIT_REST := 0.003
const HAND_FIT_MIN := 0.015
## Yatan bedenin ayağı (leg_fit lie): saniyede kaç örnekte ölçülür (arası doğrusal: geçişte ve dönüp duran uykuda ayak hızlı iner); bu kadardan az
## gömülen ayağa dokunulmaz.
const LIE_FIT_RATE := 6.0
const LIE_FIT_MIN_SAMPLES := 24
const LIE_FIT_MIN := 0.005
## Diz çökerek oturuşta (leg_fit kneel) diz ekleminin zeminden yüksekliği (metre). Eklemden ölçülür: uzun cüppenin baldıra bağlı eteği
## köşelerde dizden 20 cm aşağı sarkar, köşeyle ölçülse kişi eteğin üstünde yükselirdi.
const KNEEL_KNEE_HEIGHT := 0.05
## Hız ölçümü için örnek (character_fit_tool.gd STRIDE_SAMPLES).
const STRIDE_SAMPLES := 64
const FEET: Array[String] = ["LeftToeBase", "RightToeBase"]
## Kök bu kadar (metre) kaydıysa hız ölçümünde ileri ekseni kaymanın yönüdür; kaymayan klipte z.
const DRIFT_FOR_AXIS := 0.25
## Çekirdek kliplerin (bekleme, oturma, yürüme, koşma) ölçüldüğü başvuru kişisi: beşi de kendinde (ya da ham alımında).
const CORE_REFERENCE := "mete"
## Aracın en uzun süresi (saniye).
const TIMEOUT := 3600.0

var _failed := 0


func _initialize() -> void:
	create_timer(TIMEOUT).timeout.connect(func() -> void:
		printerr("[anim] %d sn içinde bitmedi; durduruluyor" % int(TIMEOUT))
		quit(2))
	_run.call_deferred()


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var started := Time.get_ticks_msec()
	var flags := args.filter(func(a: String) -> bool: return a.begins_with("--"))
	var rest := args.filter(func(a: String) -> bool: return not a.begins_with("--"))
	if flags.is_empty():
		printerr("[anim] adım yok: --donor, --clips, --measure ya da --merge")
		quit(1)
		return
	if flags.has("--donor"):
		_write_donor()
	if flags.has("--clips"):
		_import_clips(rest)
	if flags.has("--measure"):
		var part := ""
		var only := []
		for flag in flags:
			if str(flag).begins_with("--part="):
				part = str(flag).trim_prefix("--part=")
			elif str(flag).begins_with("--only="):
				only = Array(str(flag).trim_prefix("--only=").split(","))
		await _measure(rest, part, only)
	if flags.has("--merge"):
		await _merge(rest)
	print("[anim] bitti: %d hata (%.0f sn)" % [_failed, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if _failed > 0 else 0)


func _fail(message: String) -> void:
	printerr("[anim] " + message)
	_failed += 1


# --- Taşıyıcı iskelet ---------------------------------------------------------------------------------------

## GLB'yi yalnız iskelete indirir: kemikler ve onların ataları kalır, ağ düğümleri, ağ ve klipler atılır, ikili bölümde
## yalnız deri bağının ters bağ matrisleri kalır. Godot iskeleti deri bağından kurar: skins silinmez.
func _write_donor() -> void:
	var lib := ClipLibrary.new()
	var source := lib.carrier_file_path(CARRIER, DONOR_SOURCE)
	var bytes := FileAccess.get_file_as_bytes(source)
	if bytes.size() < 28:
		_fail("taşıyıcı iskeletin kaynağı okunamadı: %s" % source)
		return
	var stripped := strip_to_skeleton(bytes)
	if stripped.is_empty():
		_fail("%s: glTF yapısı beklenenden farklı" % DONOR_SOURCE)
		return
	var path := ProjectSettings.globalize_path(DONOR_SCENE)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("yazılamadı: %s" % path)
		return
	file.store_buffer(stripped)
	file.close()
	print("[anim] taşıyıcı iskelet → %s (%d bayt; kaynak %d bayt). İçe aktarma gerekir." % [path, stripped.size(), bytes.size()])


# --- Klipler ------------------------------------------------------------------------------------------------

func _import_clips(only: Array = []) -> void:
	var lib := ClipLibrary.new()
	if not ResourceLoader.exists(DONOR_SCENE):
		_fail("taşıyıcı iskelet içe aktarılmamış: önce --donor, sonra godot_import_locked")
		return
	var donor := lib.donor_skeleton()
	var prefix := String(donor.owner.get_path_to(donor))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LIBRARY_DIR))
	var checked := {}
	var written := 0
	var derived := []
	for key in lib.carrier_keys():
		if not only.is_empty() and not only.has(key):
			continue
		var spec := lib.clip(key)
		if str(spec.get("kind")) == ClipLibrary.KIND_DERIVED:
			derived.append(key)
			continue
		var anim := _raw_clip(lib, key, donor, checked)
		if anim == null:
			continue
		written += 1 if _save(key, _prepared(lib, key, anim, donor, prefix), spec) else 0
	# Türetilmiş klipler ana klibin kaydedilmiş hâlinden kurulur (oyundaki kaynağın kendisi).
	for key in derived:
		var spec := lib.clip(key)
		var info: Dictionary = spec.get("derived", {})
		var parent_path := ClipLibrary.resource_path_of(str(info.get("from", "")))
		var parent := load(parent_path) as Animation if ResourceLoader.exists(parent_path) else null
		if parent == null:
			_fail("%s: ana klip yok (%s)" % [key, parent_path])
			continue
		written += 1 if _save(key, ClipLibrary.derive_clip(parent, info), spec) else 0
	print("[anim] %d klip → %s (%.1f MB)" % [written, LIBRARY_DIR, _folder_bytes(LIBRARY_DIR) / 1000000.0])
	lib.release()


## Klibin ham GLB'deki hâli; GLB'nin iskeleti taşıyıcınınkiyle aynı değilse null. Klip kopyalanmaz.
func _raw_clip(lib: ClipLibrary, key: String, donor: Skeleton3D, checked: Dictionary) -> Animation:
	var spec := lib.clip(key)
	var path := lib.carrier_file_path(lib.carrier_of(key), str(spec.get("file", "")))
	if not FileAccess.file_exists(path):
		_fail("%s: ham GLB yok: %s" % [key, path])
		return null
	var root := lib._scene_root(path)
	var skel := ClipLibrary.find_skeleton(root)
	var players := root.find_children("*", "AnimationPlayer", true, false) if root else []
	if skel == null or players.is_empty():
		_fail("%s: GLB'de iskelet ya da klip yok: %s" % [key, path])
		return null
	if not checked.has(path):
		checked[path] = EXPORT._rest_difference(skel, donor)
		if not str(checked[path]).is_empty():
			_fail("%s: dinlenme pozu taşıyıcıdan farklı: %s" % [path.get_file(), checked[path]])
	if not str(checked[path]).is_empty():
		return null
	var player := players[0] as AnimationPlayer
	var clip_name := str(spec.get("meshy_name", ""))
	if clip_name.to_lower() == "reset" or not player.has_animation(clip_name):
		_fail("%s: %s klibi %s içinde yok (var olanlar: %s)" % [key, clip_name, path.get_file(), player.get_animation_list()])
		return null
	return player.get_animation(clip_name)


## Kopya: iz yolları taşıyıcı iskelete göre, düzeltmesi (pose_fix) işlenmiş.
func _prepared(lib: ClipLibrary, key: String, raw: Animation, donor: Skeleton3D, prefix: String) -> Animation:
	var anim := raw.duplicate(true) as Animation
	ClipLibrary.set_track_prefix(anim, prefix)
	ClipLibrary.apply_pose_fix(anim, donor, lib.clip(key).get("pose_fix"))
	return anim


func _save(key: String, anim: Animation, spec: Dictionary) -> bool:
	anim.resource_name = key
	anim.loop_mode = Animation.LOOP_NONE
	var path := str(spec.get("resource", ""))
	if path != ClipLibrary.resource_path_of(key):
		_fail("%s: resource alanı beklenen yol değil: %s" % [key, path])
		return false
	var error := ResourceSaver.save(anim, path, ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		_fail("%s: kaydedilemedi (hata %d)" % [key, error])
		return false
	return true


func _folder_bytes(dir: String) -> int:
	var total := 0
	for name in DirAccess.get_files_at(dir):
		total += FileAccess.get_file_as_bytes(dir.path_join(name)).size()
	return total


# --- Ölçüm ----------------------------------------------------------------------------------------------------

func _measure(ids: Array, part: String, only: Array = []) -> void:
	var lib := ClipLibrary.new()
	var targets: Array = ids if not ids.is_empty() else lib.characters_with_models().duplicate()
	var models := {}
	for id in targets:
		if not StandIn.has_model(str(id)):
			_fail("%s: modeli yok" % id)
			continue
		# Karakter başına ayrı kütüphane: clip_for'un kurduğu 120 klip bellekte birikmesin. Düzeltmesiz klipten ölçülür, düzeltme burada kurulur.
		var own := ClipLibrary.new()
		own.use_leg_fit = false
		var entry: Dictionary = await _measure_model(own, str(id), only)
		own.release()
		if not entry.is_empty():
			models[str(id)] = _merged_entry(own, str(id), entry, only) if not only.is_empty() else entry
	if not part.is_empty():
		_write_json(part, {"models": models})
		print("[anim] parça → %s (%d karakter)" % [part, models.size()])
		lib.release()
		return
	var clips: Dictionary = await _measure_carrier(lib)
	lib.release()
	_write_measure(clips, models)


## Yalnız bazı klipler ölçüldüyse (--only) kişinin kaydı: dosyadaki ölçüler, üstüne yeni ölçüler; yeni ölçüde kalkan düzeltme silinir.
func _merged_entry(lib: ClipLibrary, id: String, entry: Dictionary, only: Array) -> Dictionary:
	var out: Dictionary = lib._model_measures(id).duplicate(true)
	for table: String in entry:
		var merged: Dictionary = out.get(table, {})
		for key: String in only:
			merged.erase(key)
		merged.merge(entry[table], true)
		out[table] = merged
	return out


## Parçaları (--part) birleştirir, klip ölçülerini ekler ve dosyayı yazar.
func _merge(parts: Array) -> void:
	var models := {}
	for path in parts:
		var data: Variant = ClipLibrary.read_json(str(path))
		if not data is Dictionary or not (data as Dictionary).get("models") is Dictionary:
			_fail("parça okunamadı: %s" % path)
			continue
		models.merge(data["models"], true)
	var lib := ClipLibrary.new()
	var clips: Dictionary = await _measure_carrier(lib)
	lib.release()
	_write_measure(clips, models)


func _write_measure(clips: Dictionary, models: Dictionary) -> void:
	var previous: Variant = ClipLibrary.read_json(MEASURE_PATH)
	# Bir kısım karakter ölçüldüyse ötekilerin eski ölçüleri korunur.
	if previous is Dictionary and (previous as Dictionary).get("models") is Dictionary:
		for id in previous["models"]:
			if not models.has(id):
				models[id] = previous["models"][id]
	var ordered := {}
	var ids: Array = models.keys()
	ids.sort()
	for id in ids:
		ordered[id] = models[id]
	_add_seat_gap_max(clips, ordered)
	var data := {
		"_aciklama": "tools/anim_library_import.gd --measure yazar; elle düzenlenmez. Uzunluklar metre, hızlar m/sn, açılar derece. clips: klibin taşıyıcıdaki (çekirdek kliplerde %s'deki) ölçüleri: duration (sn), frames (farklı anahtar zamanı), cyclic (oyunun kuralları uygulanmış klipte CharacterAvatar.is_cyclic), cycle_gap_deg ve cycle_gap_m (ilk ve son kare arasındaki en büyük dönüş ve konum farkı), speed_mps (yalnız yürüme ve koşma: ham klipte kök ilerliyorsa kökün hızı, yerinde klipte ayağın yere bastığı karelerdeki kayma hızı, character_fit_tool.gd'nin yöntemi), root_speed_mps (yerinde oynatılmadan önce kökün yatay hızı), root_delta_m ([x, y, z] kökün ilk kareden son kareye yer değiştirmesi), root_start_m (geçişlerde [x, z] kökün ilk karedeki yatay konumu), yaw_deg (ilk kareden son kareye bedenin y ekseni çevresinde dönüşü; geçişlerde kişi bu kadar dönmüş biter), hips_m ({min, mean, max} kalça ekleminin ham klipteki yüksekliği), lowest_joint_m (ham klipte en alçak eklem), seat_gap_max (kadronun en büyük kalça boşluğu). models.<id>: karakterin kendi ölçüleri. offset: klip başına zemin payı (CharacterAvatar gibi model bu kadar kaydırılınca klibin contact kemiklerinin en alt köşesi zemine değer; ClipLibrary.ground_offset_for okur; yürüme ve koşmada kare başına en alt noktaların alttan dilimi, PoseFit.low_share_offset). leg_fit: tanımın leg_fit'i olan klipte gerekiyorsa {hips, left, right, hand_left, hand_right, lift_left, lift_right}: kalça ve ayak bileklerinin ineceği, yere dayanan elin bileğinin yükseleceği (eksi: ineceği) metre; lift_left ve lift_right yatan bedenin zemine giren ayağının klip boyunca kalkışıdır, eşit aralıklı örnekler, metre (ClipLibrary.fit_legs); öteki ölçüler bu düzeltmeden sonradır. Eli yere dayanan klipte (temas kemiği ya da leg_fit hands) ölçü oyunun gördüğü pozdandır: omuz düzeltmesi işlenmiş. seat_gap_m: yerde oturuşta ve yere inen geçişin yerdeki ucunda bedenin zeminden boşluğu (pay uygulanmış; oturuşta kalça, PoseFit.seat_min_y; diz çökme geçişinde baldır ve diz; diz çökerek oturuşta yazılmaz). foot_gap_m: bekleme ve kıpırdanmada [sol, sağ] ayağın klip boyunca zeminden en az boşluğu. root_start_m: geçişlerde [x, z] kökün ilk karedeki yatay konumu. ends: geçişlerde [başlangıç, bitiş] payı: ilk ve son karede o anki duruşun temas kemikleriyle (states.<durum>.contact); geçiş boyunca bu ikisi arasında kaydırılırsa iki uç da zemine oturur. hips_m: oturuşlarda kalça ekleminin zeminden yüksekliği (o pay uygulanmış; oturağın yüksekliği için), speed_mps: yürüme ve koşma çeşitlerinin bu kişideki doğal hızı (kök ilerliyorsa taşıyıcının kök hızı, kalça oranıyla)." % CORE_REFERENCE,
		"samples": SAMPLES,
		"clips": clips,
		"models": ordered,
	}
	_write_json(MEASURE_PATH, data)
	print("[anim] ölçüler → %s (%d klip, %d karakter)" % [MEASURE_PATH, clips.size(), ordered.size()])


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("yazılamadı: %s" % path)
		return
	file.store_string(JSON.stringify(data, " ", false) + "\n")
	file.close()


## Bir karakterin ölçüleri: oyunun klip kurulumuyla (ClipLibrary.clip_for) oynatılır, köşeler işlemcide giydirilir.
func _measure_model(lib: ClipLibrary, id: String, only: Array = []) -> Dictionary:
	var scene := load(StandIn.model_path(id)) as PackedScene
	var model := scene.instantiate() as Node3D if scene else null
	var skel := ClipLibrary.find_skeleton(model)
	if skel == null:
		_fail("%s: iskeletli model değil" % id)
		if model:
			model.free()
		return {}
	var player := _fresh_player(model)
	# Skeleton3D ağaç dışında poz değişince global pozlarını yenilemez (clip_library_export.gd'deki not).
	get_root().add_child(model)
	await process_frame
	var library: AnimationLibrary = player.get_animation_library(&"")
	var to_model := PoseFit.relative_transform(model, skel)
	var hips_bone := skel.find_bone("Hips")
	var offsets := {}
	var ends := {}
	var seats := {}
	var speeds := {}
	var fits := {}
	var seat_gaps := {}
	var foot_gaps := {}
	var root_starts := {}
	for key in lib.clip_keys():
		if not only.is_empty() and not only.has(key):
			continue
		var built := lib.clip_for(id, key, skel)
		if built == null:
			_fail("%s/%s kurulamadı" % [id, key])
			continue
		# Önceki klibin izi kütüphaneden çıkınca kemik o konumda kalır (kendi yürümesindeki uyluk konumu): ölçü her klipte temiz başlasın.
		skel.reset_bone_poses()
		var spec := lib.clip(key)
		var fit := _leg_fit(id, lib, key, built, model, skel, player, library)
		var anim := built
		if not fit.is_empty():
			fits[key] = fit
			anim = built.duplicate(true)
			ClipLibrary.fit_legs(anim, skel, fit, ClipLibrary.seat_end_of(spec))
		anim = _as_played(id, spec, anim, model, skel)
		library.add_animation(key, anim)
		player.play(key)
		var group := str(spec.get("group", ""))
		var stride := PoseFit.is_stride(spec)
		var contact := lib.contact_for(key)
		var lows := PackedFloat32Array()
		var hips_sum := 0.0
		for time in PoseFit.floor_times(anim.length, spec):
			player.seek(time, true)
			lows.append(PoseFit.skinned_min_y(model, contact))
			hips_sum += (to_model * skel.get_bone_global_pose(hips_bone).origin).y
		var offset := PoseFit.floor_offset(lows, spec)
		offsets[key] = snappedf(offset, 0.001)
		var transition: Variant = spec.get("transition")
		var seated := str(spec.get("group", "")) in ["sit_chair", "sit_ground"]
		if transition is Dictionary:
			player.seek(0.0, true)
			root_starts[key] = _flat_point(to_model * skel.get_bone_global_pose(hips_bone).origin)
			var start := -PoseFit.skinned_min_y(model, lib.contact_for_state(str(transition["from"])))
			if ClipLibrary.seat_end_of(spec) == 0:
				seat_gaps[key] = snappedf(_body_low(lib, key, model) + start, 0.001)
			player.seek(anim.length, true)
			var end := -PoseFit.skinned_min_y(model, lib.contact_for_state(str(transition["to"])))
			ends[key] = [snappedf(start, 0.001), snappedf(end, 0.001)]
			if ClipLibrary.seat_end_of(spec) == 1:
				seat_gaps[key] = snappedf(_body_low(lib, key, model) + end, 0.001)
			if str(transition["to"]) in ["sit_chair", "sit_ground", "kneel"]:
				seats[key] = snappedf((to_model * skel.get_bone_global_pose(hips_bone).origin).y + end, 0.001)
		elif seated:
			seats[key] = snappedf(hips_sum / SAMPLES + offset, 0.001)
		# Diz çökmede beden dizlerde durur (kalça ayakların üstünde yüksekte kalır): kalça boşluğu sayılmaz.
		if group == ClipVariety.GROUND_GROUP and not (spec.get("leg_fit", []) as Array).has("kneel"):
			seat_gaps[key] = snappedf(_lowest_over(player, anim, func() -> float: return PoseFit.seat_min_y(model)) + offset, 0.001)
		if group in [ClipVariety.ROLE_GROUPS[&"idle"], ClipVariety.FIDGET_GROUP]:
			foot_gaps[key] = [snappedf(_lowest_over(player, anim, func() -> float: return PoseFit.skinned_min_y(model, PoseFit.LEFT_FOOT_BONES)) + offset, 0.001),
				snappedf(_lowest_over(player, anim, func() -> float: return PoseFit.skinned_min_y(model, PoseFit.RIGHT_FOOT_BONES)) + offset, 0.001)]
		if stride:
			var root_speed := _root_speed_units(lib, key)
			if root_speed * to_model.basis.get_scale().y > ROOT_MOTION_MIN:
				speeds[key] = snappedf(root_speed * ClipRetarget.hips_ratio(lib.donor_skeleton(), skel) * to_model.basis.get_scale().y, 0.01)
			else:
				speeds[key] = snappedf(_stride_speed(player, anim, model, skel, _forward_axis(lib, key)), 0.01)
		player.stop()
		library.remove_animation(key)
	get_root().remove_child(model)
	model.free()
	print("[anim] %s: %d klip ölçüldü, %d klipte bacak düzeltmesi" % [id, offsets.size(), fits.size()])
	return {"offset": offsets, "ends": ends, "hips_m": seats, "speed_mps": speeds, "leg_fit": fits, "seat_gap_m": seat_gaps, "foot_gap_m": foot_gaps, "root_start_m": root_starts}


## Geçişin yerdeki ucunda bedeni taşıyan yerin en altı: diz çökmede baldır ve diz, oturuşta kalça.
func _body_low(lib: ClipLibrary, key: String, model: Node3D) -> float:
	return PoseFit.skinned_min_y(model, PoseFit.SHIN_BONES) if (lib.clip(key).get("leg_fit", []) as Array).has("knee") else PoseFit.seat_min_y(model)


## Klibin örnek karelerinde read'in en küçüğü.
func _lowest_over(player: AnimationPlayer, anim: Animation, read: Callable) -> float:
	var low := INF
	for i in SAMPLES:
		player.seek(anim.length * i / float(SAMPLES - 1), true)
		low = minf(low, float(read.call()))
	return low


## Yatay nokta [x, z] (metre).
func _flat_point(point: Vector3) -> Array:
	return [snappedf(point.x, 0.001), snappedf(point.z, 0.001)]


## Klibin oyunda görünen hâli: eli yere dayanan klipte omuz düzeltmesi işlenmiş kopya (PoseFit.has_hand_contact; oyunda ShoulderRelax,
## belge sitesinde bake_shoulder_relax), öteki kliplerde kendisi: düzeltme yalnız köprücük ve kolu oynatır, bacak ve kalça köşelerine değmez.
func _as_played(id: String, spec: Dictionary, anim: Animation, model: Node3D, skel: Skeleton3D) -> Animation:
	var drop := float(CharacterAvatar._load_fit(id).get("shoulder_drop", 0.0))
	if not PoseFit.has_hand_contact(spec) or drop < EXPORT.MIN_SHOULDER_DROP:
		return anim
	var relaxed := anim.duplicate(true) as Animation
	var up := (PoseFit.relative_transform(model, skel).basis.inverse() * Vector3.UP).normalized()
	var result := ClipLibrary.bake_shoulder_relax(relaxed, skel, up, drop)
	if not result["baked"]:
		_fail("%s/%s: omuz düzeltmesi ölçüme işlenemedi (%s)" % [id, anim.resource_name, result["reason"]])
		return anim
	return relaxed


## Kişinin bu klipteki bacak düzeltmesi (tanımın leg_fit'i): düzeltmesiz klipten boşluk ölçülür, işlenir, kalanı yeniden ölçülür. Gerekmiyorsa
## boş. Ayak bir daha inemiyorsa (bacak zincirin sonunda) düzeltme orada kalır. Elin düzeltmesi (hands) bacaklardan sonradır.
func _leg_fit(id: String, lib: ClipLibrary, key: String, built: Animation, model: Node3D, skel: Skeleton3D, player: AnimationPlayer, library: AnimationLibrary) -> Dictionary:
	var spec := lib.clip(key)
	var parts: Array = spec.get("leg_fit", [])
	if parts.is_empty():
		return {}
	var seat_end := ClipLibrary.seat_end_of(spec)
	var state := ""
	if seat_end >= 0:
		state = str((spec["transition"] as Dictionary)["to" if seat_end == 1 else "from"])
	var fit := {"hips": 0.0, "left": 0.0, "right": 0.0}
	var clip := built
	var previous := {}
	for round_index in LEG_FIT_ROUNDS if seat_end < 0 else 1:
		library.add_animation(key, clip)
		player.play(key)
		var gaps := _leg_gaps(lib, key, parts, state, seat_end, clip, model, skel, player)
		player.stop()
		library.remove_animation(key)
		var moved := false
		for part: String in fit:
			var gap := float(gaps.get(part, 0.0))
			var low := float((SEAT_FIT_MIN if part == "hips" else FOOT_FIT_MIN) if round_index == 0 else LEG_FIT_STEP)
			if gap > low and gap < float(previous.get(part, INF)) - LEG_FIT_STEP * 0.5:
				fit[part] = float(fit[part]) + gap
				moved = true
			previous[part] = gap
		if not moved:
			break
		clip = built.duplicate(true)
		ClipLibrary.fit_legs(clip, skel, fit, seat_end)
	var out := {}
	for part: String in fit:
		if float(fit[part]) > 0.0:
			out[part] = snappedf(float(fit[part]), 0.001)
	if parts.has("hands"):
		out.merge(_hand_fit(id, lib, key, built, out, model, skel, player, library))
	if parts.has("lie"):
		out.merge(_lie_fit(lib, key, built, out, model, skel, player, library))
	return out


## Yatan bedenin zemine giren ayağı: zemin payı gövde ve başa göredir (LYING_BONES), klipte bacak aşağı eğimlidir, ayak zeminin altında kalır. Her
## örnekte ayağın en alt köşesi o anki zemine göre ölçülür, zeminin altındaysa bilek o kadar kalkar, kalanı yeniden ölçülür. Zemin duruşun temas
## kemiklerindendir, geçişte iki ucun arasında doğrusal: oyunun ve sayfanın payı gibi. Ayak zaten zemindeyse boş: bacak oynamaz.
func _lie_fit(lib: ClipLibrary, key: String, built: Animation, leg_fit: Dictionary, model: Node3D, skel: Skeleton3D, player: AnimationPlayer, library: AnimationLibrary) -> Dictionary:
	var spec := lib.clip(key)
	var transition: Variant = spec.get("transition")
	var contact := lib.contact_for(key)
	var fit := leg_fit.duplicate()
	var lifts := {"lift_left": [], "lift_right": []}
	var sides := {"lift_left": PoseFit.LEFT_FOOT_BONES, "lift_right": PoseFit.RIGHT_FOOT_BONES}
	var samples := maxi(ceili(built.length * LIE_FIT_RATE) + 1, LIE_FIT_MIN_SAMPLES)
	for field: String in lifts:
		(lifts[field] as Array).resize(samples)
		(lifts[field] as Array).fill(0.0)
		fit[field] = lifts[field]
	for round_index in LEG_FIT_ROUNDS:
		var clip := built.duplicate(true) as Animation
		ClipLibrary.fit_legs(clip, skel, fit, ClipLibrary.seat_end_of(spec))
		skel.reset_bone_poses()
		library.add_animation(key, clip)
		player.play(key)
		var floor_start := 0.0
		var floor_end := 0.0
		if transition is Dictionary:
			player.seek(0.0, true)
			floor_start = PoseFit.skinned_min_y(model, lib.contact_for_state(str(transition["from"])))
			player.seek(clip.length, true)
			floor_end = PoseFit.skinned_min_y(model, lib.contact_for_state(str(transition["to"])))
		else:
			floor_start = _lowest_over(player, clip, func() -> float: return PoseFit.skinned_min_y(model, contact))
			floor_end = floor_start
		var moved := false
		for i in samples:
			var share := i / float(samples - 1)
			player.seek(clip.length * share, true)
			for field: String in sides:
				var gap := PoseFit.skinned_min_y(model, sides[field]) - lerpf(floor_start, floor_end, share) - FOOT_FIT_REST
				var value := maxf(float(lifts[field][i]) - gap, 0.0)
				if absf(value - float(lifts[field][i])) > LEG_FIT_STEP:
					lifts[field][i] = value
					moved = true
		player.stop()
		library.remove_animation(key)
		skel.reset_bone_poses()
		if not moved:
			break
	var out := {}
	for field: String in lifts:
		if (lifts[field] as Array).max() >= LIE_FIT_MIN:
			out[field] = (lifts[field] as Array).map(func(value: float) -> float: return snappedf(value, 0.001))
	return out


## Yere dayanan elin düzeltmesi: bacaklar düzeltilmiş ve omuz düzeltmesi işlenmiş klipte elin en alt köşesi zemine göre ölçülür, bilek
## o kadar yükselir ya da iner, kalanı yeniden ölçülür. Kol uzanıp el yetişmiyorsa (kalkık kalçada) düzeltme orada kalır. Kalça inmediyse ve el
## zemine yakınsa boş: kol oynamaz.
func _hand_fit(id: String, lib: ClipLibrary, key: String, built: Animation, leg_fit: Dictionary, model: Node3D, skel: Skeleton3D, player: AnimationPlayer, library: AnimationLibrary) -> Dictionary:
	var spec := lib.clip(key)
	var contact := lib.contact_for(key)
	var fit := leg_fit.duplicate()
	fit["hand_left"] = 0.0
	fit["hand_right"] = 0.0
	var fields := {"hand_left": ["LeftHand"] as Array[String], "hand_right": ["RightHand"] as Array[String]}
	var previous := {}
	for round_index in LEG_FIT_ROUNDS:
		var clip := built.duplicate(true) as Animation
		ClipLibrary.fit_legs(clip, skel, fit, ClipLibrary.seat_end_of(spec))
		clip = _as_played(id, spec, clip, model, skel)
		skel.reset_bone_poses()
		library.add_animation(key, clip)
		player.play(key)
		var floor_y := _lowest_over(player, clip, func() -> float: return PoseFit.skinned_min_y(model, contact))
		var moved := false
		for field: String in fields:
			var bones: Array[String] = fields[field]
			var gap := _lowest_over(player, clip, func() -> float: return PoseFit.skinned_min_y(model, bones)) - floor_y - HAND_FIT_REST
			if absf(gap) > LEG_FIT_STEP and absf(gap) < float(previous.get(field, INF)) - LEG_FIT_STEP * 0.5:
				fit[field] = float(fit[field]) - gap
				moved = true
			previous[field] = absf(gap)
		player.stop()
		library.remove_animation(key)
		skel.reset_bone_poses()
		if not moved:
			break
	var out := {}
	if not leg_fit.has("hips") and absf(float(fit["hand_left"])) < HAND_FIT_MIN and absf(float(fit["hand_right"])) < HAND_FIT_MIN:
		return out
	for field: String in fields:
		out[field] = snappedf(float(fit[field]), 0.001)
	return out


## O anki klipte düzeltilecek boşluklar (metre): {hips, left, right}. Sabit klipte örnek kareler, geçişte yerdeki uç.
func _leg_gaps(lib: ClipLibrary, key: String, parts: Array, state: String, seat_end: int, clip: Animation, model: Node3D, skel: Skeleton3D, player: AnimationPlayer) -> Dictionary:
	var contact := lib.contact_for_state(state) if seat_end >= 0 else lib.contact_for(key)
	var times := PackedFloat32Array()
	if seat_end >= 0:
		times.append(clip.length if seat_end == 1 else 0.0)
	else:
		for i in SAMPLES:
			times.append(clip.length * i / float(SAMPLES - 1))
	var floor_y := INF
	var seat := INF
	var knee := INF
	var left := INF
	var right := INF
	var knee_joint := INF
	var to_model := PoseFit.relative_transform(model, skel)
	for time in times:
		player.seek(time, true)
		floor_y = minf(floor_y, PoseFit.skinned_min_y(model, contact))
		if parts.has("kneel"):
			for bone: String in PoseFit.SHIN_BONES:
				knee_joint = minf(knee_joint, (to_model * skel.get_bone_global_pose(skel.find_bone(bone)).origin).y)
		if parts.has("seat"):
			seat = minf(seat, PoseFit.seat_min_y(model))
		if parts.has("knee"):
			knee = minf(knee, PoseFit.skinned_min_y(model, PoseFit.SHIN_BONES))
		if parts.has("feet") or parts.has("kneel"):
			left = minf(left, PoseFit.skinned_min_y(model, PoseFit.LEFT_FOOT_BONES))
			right = minf(right, PoseFit.skinned_min_y(model, PoseFit.RIGHT_FOOT_BONES))
	var gaps := {}
	if parts.has("kneel"):
		var floor_at_knees := knee_joint - KNEEL_KNEE_HEIGHT
		return {"left": left - floor_at_knees, "right": right - floor_at_knees}
	if parts.has("seat"):
		gaps["hips"] = seat - floor_y - SEAT_FIT_REST
	elif parts.has("knee"):
		gaps["hips"] = knee - floor_y - SEAT_FIT_REST
	if parts.has("feet"):
		gaps["left"] = left - floor_y - FOOT_FIT_REST
		gaps["right"] = right - floor_y - FOOT_FIT_REST
	return gaps


## Kadronun en büyük kalça boşluğu (clips.<anahtar>.seat_gap_max): kişi ölçülmemişse bu sayılır.
func _add_seat_gap_max(clips: Dictionary, models: Dictionary) -> void:
	for id: String in models:
		var table: Variant = (models[id] as Dictionary).get("seat_gap_m")
		if not table is Dictionary:
			continue
		for key: String in table:
			if clips.has(key):
				(clips[key] as Dictionary)["seat_gap_max"] = maxf(float((clips[key] as Dictionary).get("seat_gap_max", -INF)), float(table[key]))


## Ham klipte kökün yatay hızı (iskelet birimi/sn; taşıyıcı klibi değilse ya da kök izi yoksa 0).
func _root_speed_units(lib: ClipLibrary, key: String) -> float:
	var raw := lib.library_clip(key) if not lib.carrier_of(key).is_empty() else null
	if raw == null or raw.length <= 0.0:
		return 0.0
	var hips := raw.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(raw)), Animation.TYPE_POSITION_3D)
	if hips < 0 or raw.track_get_key_count(hips) < 2:
		return 0.0
	var delta: Vector3 = (raw.track_get_key_value(hips, raw.track_get_key_count(hips) - 1) as Vector3) - (raw.track_get_key_value(hips, 0) as Vector3)
	return Vector2(delta.x, delta.z).length() / raw.length


## Modelin oynatıcısı, klipleri boşaltılmış (yoksa oluşturulur); kütüphanesi boş ve adsız.
func _fresh_player(model: Node) -> AnimationPlayer:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	var player: AnimationPlayer = players[0] if not players.is_empty() else null
	if player == null:
		player = AnimationPlayer.new()
		player.name = "AnimationPlayer"
		model.add_child(player)
		player.root_node = NodePath("..")
	for lib_name in player.get_animation_library_list():
		player.remove_animation_library(lib_name)
	player.add_animation_library(&"", AnimationLibrary.new())
	return player


## Klibin ileri ekseni (model uzayında): ham kökü belirgin kayıyorsa kaymanın yönü, değilse z (character_fit_tool.gd).
func _forward_axis(lib: ClipLibrary, key: String) -> Vector3:
	var raw := lib.library_clip(key) if not lib.carrier_of(key).is_empty() else null
	if raw == null:
		return Vector3.BACK
	var hips := raw.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(raw)), Animation.TYPE_POSITION_3D)
	if hips < 0 or raw.track_get_key_count(hips) < 2:
		return Vector3.BACK
	var delta: Vector3 = (raw.track_get_key_value(hips, raw.track_get_key_count(hips) - 1) as Vector3) - (raw.track_get_key_value(hips, 0) as Vector3)
	var flat := Vector3(delta.x, 0.0, delta.z) * 0.01
	return flat.normalized() if flat.length() > DRIFT_FOR_AXIS else Vector3.BACK


## character_fit_tool.gd'nin _stride_speed'i: yerinde oynayan klipte ayağın yere bastığı karelerdeki kayma hızı (iki ayağın
## ortalaması); ileri ekseni axis.
func _stride_speed(player: AnimationPlayer, anim: Animation, model: Node3D, skel: Skeleton3D, axis: Vector3) -> float:
	var to_model := PoseFit.relative_transform(model, skel)
	var dt := anim.length / float(STRIDE_SAMPLES)
	var total := 0.0
	var feet := 0
	for foot in FEET:
		var bone := skel.find_bone(foot)
		if bone < 0:
			continue
		var heights := PackedFloat32Array()
		var forward := PackedFloat32Array()
		for i in STRIDE_SAMPLES + 1:
			# Döngülü klipte seek(süre) ilk kareye sarar; son örnek bir kare önceden alınır.
			player.seek(minf(dt * i, anim.length - 0.0005), true)
			var p := to_model * skel.get_bone_global_pose(bone).origin
			heights.append(p.y)
			forward.append(p.dot(axis))
		total += PoseFit.stance_speed(heights, forward, dt)
		feet += 1
	return total / feet if feet > 0 else 0.0


## Kliplerin taşıyıcıdaki ölçüleri; taşıyıcıda olmayan çekirdek klipler başvuru kişisinde ölçülür (bacak düzeltmesiz: ham klibin ölçüsü).
func _measure_carrier(lib: ClipLibrary) -> Dictionary:
	lib.use_leg_fit = false
	var out := {}
	var donor_root := (load(DONOR_SCENE) as PackedScene).instantiate() as Node3D
	var donor_skel := ClipLibrary.find_skeleton(donor_root)
	var donor_player := _fresh_player(donor_root)
	get_root().add_child(donor_root)
	await process_frame
	var ref_root: Node3D = null
	var ref_skel: Skeleton3D = null
	var ref_player: AnimationPlayer = null
	if StandIn.has_model(CORE_REFERENCE):
		ref_root = (load(StandIn.model_path(CORE_REFERENCE)) as PackedScene).instantiate() as Node3D
		ref_skel = ClipLibrary.find_skeleton(ref_root)
		ref_player = _fresh_player(ref_root)
		get_root().add_child(ref_root)
		await process_frame
	for key in lib.clip_keys():
		var carried := not lib.carrier_of(key).is_empty()
		if not carried and ref_root == null:
			continue
		var raw: Animation
		if carried:
			raw = lib.library_clip(key)
		else:
			raw = lib.build_clip(key, CORE_REFERENCE, ref_skel, [], String(ref_root.get_path_to(ref_skel)))
		if raw == null:
			_fail("%s: klip okunamadı" % key)
			continue
		var skel: Skeleton3D = donor_skel if carried else ref_skel
		var root: Node3D = donor_root if carried else ref_root
		var player: AnimationPlayer = donor_player if carried else ref_player
		var clip := raw.duplicate(true) as Animation
		var spec := lib.clip(key)
		if carried:
			ClipLibrary.apply_clip_rules(clip, lib.role_of(key), bool(spec.get("loop", true)), spec.has("transition"))
		out[key] = _clip_measure(raw, clip, skel, root, player, spec, key)
	donor_root.free()
	if ref_root:
		ref_root.free()
	return out


func _clip_measure(raw: Animation, clip: Animation, skel: Skeleton3D, root: Node3D, player: AnimationPlayer, spec: Dictionary, key: String) -> Dictionary:
	var library: AnimationLibrary = player.get_animation_library(&"")
	library.add_animation(key, clip)
	player.play(key)
	var to_model := PoseFit.relative_transform(root, skel)
	var unit := to_model.basis.get_scale().y
	var gap := cycle_gap(clip)
	var entry := {
		"duration": snappedf(raw.length, 0.001),
		"frames": ClipLibrary.frame_count(raw),
		"cyclic": CharacterAvatar.is_cyclic(clip),
		"cycle_gap_deg": snappedf(gap["rotation_deg"], 0.01),
		"cycle_gap_m": snappedf(gap["position"] * unit, 0.001),
	}
	# Kökün ham yer değiştirmesi.
	var hips_path := NodePath("%s:Hips" % ClipRetarget.track_prefix(raw))
	var hips_track := raw.find_track(hips_path, Animation.TYPE_POSITION_3D)
	var delta := Vector3.ZERO
	if hips_track >= 0 and raw.track_get_key_count(hips_track) >= 2:
		delta = (raw.track_get_key_value(hips_track, raw.track_get_key_count(hips_track) - 1) as Vector3) - (raw.track_get_key_value(hips_track, 0) as Vector3)
	delta *= unit
	entry["root_delta_m"] = [snappedf(delta.x, 0.001), snappedf(delta.y, 0.001), snappedf(delta.z, 0.001)]
	entry["root_speed_mps"] = snappedf(Vector2(delta.x, delta.z).length() / maxf(raw.length, 0.001), 0.01)
	if spec.has("transition") and hips_track >= 0 and raw.track_get_key_count(hips_track) > 0:
		entry["root_start_m"] = _flat_point(to_model * (raw.track_get_key_value(hips_track, 0) as Vector3))
	var group := str(spec.get("group", ""))
	if bool(spec.get("loop", true)) and group in ["walk", "run"]:
		var axis := Vector3(delta.x, 0.0, delta.z).normalized() if Vector2(delta.x, delta.z).length() > DRIFT_FOR_AXIS else Vector3.BACK
		if float(entry["root_speed_mps"]) > ROOT_MOTION_MIN:
			entry["speed_mps"] = entry["root_speed_mps"]
		else:
			entry["speed_mps"] = snappedf(_stride_speed(player, clip, root, skel, axis), 0.01)
	# Kalça ve en alçak eklem, ham klipte (kök kaydırılmadan).
	library.remove_animation(key)
	var raw_copy := raw.duplicate(true) as Animation
	library.add_animation(key, raw_copy)
	player.play(key)
	var hips_bone := skel.find_bone("Hips")
	var left_hip := skel.find_bone("LeftUpLeg")
	var right_hip := skel.find_bone("RightUpLeg")
	var low := INF
	var high := -INF
	var total := 0.0
	var lowest := INF
	var first_axis := Vector3.ZERO
	var last_axis := Vector3.ZERO
	for i in SAMPLES:
		player.seek(raw_copy.length * i / float(SAMPLES - 1), true)
		var y := (to_model * skel.get_bone_global_pose(hips_bone).origin).y
		low = minf(low, y)
		high = maxf(high, y)
		total += y
		for b in skel.get_bone_count():
			lowest = minf(lowest, (to_model * skel.get_bone_global_pose(b).origin).y)
		var across := skel.get_bone_global_pose(left_hip).origin - skel.get_bone_global_pose(right_hip).origin
		if i == 0:
			first_axis = across
		last_axis = across
	entry["hips_m"] = {"min": snappedf(low, 0.001), "mean": snappedf(total / SAMPLES, 0.001), "max": snappedf(high, 0.001)}
	entry["lowest_joint_m"] = snappedf(lowest, 0.001)
	entry["yaw_deg"] = snappedf(yaw_between(first_axis, last_axis), 0.1)
	player.stop()
	library.remove_animation(key)
	return entry


# --- Saf yardımcılar -------------------------------------------------------------------------------------------

## Klibin ilk ve son karesi arasındaki en büyük fark (CharacterAvatar.is_cyclic'in baktığı izler): rotation_deg (derece),
## position (iskelet birimi).
static func cycle_gap(anim: Animation) -> Dictionary:
	var angle := 0.0
	var distance := 0.0
	for t in anim.get_track_count():
		var count := anim.track_get_key_count(t)
		if count < 2:
			continue
		match anim.track_get_type(t):
			Animation.TYPE_ROTATION_3D:
				var a: Quaternion = anim.track_get_key_value(t, 0)
				var b: Quaternion = anim.track_get_key_value(t, count - 1)
				angle = maxf(angle, a.normalized().angle_to(b.normalized()))
			Animation.TYPE_POSITION_3D:
				var p: Vector3 = anim.track_get_key_value(t, 0)
				var q: Vector3 = anim.track_get_key_value(t, count - 1)
				distance = maxf(distance, p.distance_to(q))
	return {"rotation_deg": rad_to_deg(angle), "position": distance}


## İki yatay yön arasındaki y ekseni çevresinde dönüş (derece, -180..180; soldan sağa kalça ekseni gibi).
static func yaw_between(from: Vector3, to: Vector3) -> float:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	if a.length_squared() < 0.000001 or b.length_squared() < 0.000001:
		return 0.0
	return rad_to_deg(a.angle_to(b))


## GLB'yi yalnız iskelete indirir: kemikler ve onların ataları kalır, ağ düğümleri, ağ ve klipler atılır, ikili bölümde
## yalnız ters bağ matrisleri kalır (Godot iskeleti deri bağından kurar: skins silinmez). Yapı beklenenden farklıysa boş.
static func strip_to_skeleton(bytes: PackedByteArray) -> PackedByteArray:
	if bytes.size() < 28:
		return PackedByteArray()
	var json_size := bytes.decode_u32(12)
	var gltf: Variant = JSON.parse_string(bytes.slice(20, 20 + json_size).get_string_from_utf8())
	if not gltf is Dictionary or (gltf.get("skins", []) as Array).size() != 1:
		return PackedByteArray()
	var bin_start: int = 20 + json_size + 8
	var nodes: Array = gltf["nodes"]
	var skin: Dictionary = gltf["skins"][0]
	# Kemikler ve ataları.
	var parent := {}
	for i in nodes.size():
		for child in nodes[i].get("children", []):
			parent[int(child)] = i
	var keep := {}
	for joint in skin["joints"]:
		var x := int(joint)
		while x >= 0 and not keep.has(x):
			keep[x] = true
			x = int(parent.get(x, -1))
	var order: Array = keep.keys()
	order.sort()
	var index := {}
	for i in order.size():
		index[order[i]] = i
	var kept_nodes := []
	for i in order:
		var node: Dictionary = (nodes[i] as Dictionary).duplicate()
		node.erase("mesh")
		node.erase("skin")
		var children := []
		for child in node.get("children", []):
			if index.has(int(child)):
				children.append(index[int(child)])
		if children.is_empty():
			node.erase("children")
		else:
			node["children"] = children
		kept_nodes.append(node)
	var scene: Dictionary = (gltf["scenes"][int(gltf.get("scene", 0))] as Dictionary).duplicate()
	var roots := []
	for root in scene.get("nodes", []):
		if index.has(int(root)):
			roots.append(index[int(root)])
	scene["nodes"] = roots
	var accessor: Dictionary = (gltf["accessors"][int(skin["inverseBindMatrices"])] as Dictionary).duplicate()
	var view: Dictionary = (gltf["bufferViews"][int(accessor["bufferView"])] as Dictionary).duplicate()
	var view_start := int(view.get("byteOffset", 0))
	var blob := bytes.slice(bin_start + view_start, bin_start + view_start + int(view["byteLength"]))
	accessor["bufferView"] = 0
	accessor.erase("byteOffset")
	view["byteOffset"] = 0
	view["buffer"] = 0
	var joints := []
	for joint in skin["joints"]:
		joints.append(index[int(joint)])
	var out_skin := {"name": skin.get("name", "Armature"), "inverseBindMatrices": 0, "joints": joints}
	var out := {
		"asset": gltf["asset"],
		"scene": 0,
		"scenes": [scene],
		"nodes": kept_nodes,
		"skins": [out_skin],
		"accessors": [accessor],
		"bufferViews": [view],
		"buffers": [{"byteLength": blob.size()}],
	}
	var text := JSON.stringify(EXPORT._integers(out), "", false, true).to_utf8_buffer()
	while text.size() % 4 != 0:
		text.append(0x20)
	while blob.size() % 4 != 0:
		blob.append(0)
	var glb := PackedByteArray()
	glb.resize(12)
	glb.encode_u32(0, 0x46546C67)
	glb.encode_u32(4, 2)
	glb.encode_u32(8, 12 + 8 + text.size() + 8 + blob.size())
	var head := PackedByteArray()
	head.resize(8)
	head.encode_u32(0, text.size())
	head.encode_u32(4, 0x4E4F534A)
	glb.append_array(head)
	glb.append_array(text)
	head.encode_u32(0, blob.size())
	head.encode_u32(4, 0x004E4942)
	glb.append_array(head)
	glb.append_array(blob)
	return glb
