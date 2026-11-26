extends SceneTree
## Klip kütüphanesini (K90, data/clip_library.json) belge sitesine dışa aktarır: modeli olan her karakter için
## kütüphanenin bütün klipleri (beş oyun klibi ve taşıyıcıların, ör. E9 paketinin klipleri) tek GLB'de, animasyon adları
## klip anahtarlarıyla: docs/assets/animations/<id>.glb. Yanına manifest.json yazılır (belge sitesinin animasyon sayfası
## okur; elle düzenlenmez): klipler ve alımları, kredi özeti, her karakterin kliplerinin kaynağı (kendi klibi, satın
## alınmış ham GLB ya da bağışçıdan/taşıyıcıdan aktarım), kişinin sahnesiz varsayılan çeşitleri (oyuncu karakterinde yok), sahnelerin
## ona bugün oynattığı klipler ve modeli henüz gelmemiş (Meshy kuyruğundaki) kişiler.
##
## Klipler ClipLibrary.build_clip ile oyundaki kurallarla kurulur (döngü, yerinde oynama; aktarım ClipRetarget).
## Web oynatıcısı klip değişince izi olmayan kemikte önceki klibin pozunu bıraktığından her klibe bütün kemiklerin izi
## tamamlanır (dinlenme pozu; oyunda izsiz kemik zaten dinlenme pozundadır), kimi klipte konum izi olan kemiğin (kendi yürüyüşünde
## uyluk) konum izi de öteki kliplere eklenir (complete_position_tracks). Omuz düzeltmesi (<id>_fit.json shoulder_drop;
## oyunda ShoulderRelax) kliplere birebir pişirilir; pişirilemezse klipler ham kalır (konsola yazılır). Sonra her klip zemine
## oturtulur: oyun modeli klibe göre kaydırır (CharacterAvatar), web oynatıcısı (model-viewer) ise zemini ve gölgeyi dinlenme
## pozunun en altına koyar; bu yüzden pay kök kemiğin konumuna pişirilir (_ground_offsets). Pay oyunun ölçümüyle aynı kuraldır
## (scripts/character/pose_fit.gd başı ve floor_offset; tools/anim_library_import.gd): zemine klibin contact kemikleri değer. Geçişte iki ucun
## payı ayrıdır (states: başlangıç ve bitiş duruşunun temas kemikleri), arada doğrusal kayar. Dokular JPEG'den geldiyse JPEG (kalite 0,85; GLB'nin ağ ve doku kısmı MAX_MODEL_BYTES
## hedefini aşarsa kalite adım adım düşer) yazılır; ağın teğetleri yazılmaz (malzemede normal haritası yok, teğet yalnız onun için
## gerekir). Yazılan GLB GLTFDocument ile geri okunup animasyon adları, kemik sayısı ve deri bağı denetlenir; denetimden
## geçmeyen dosya yerine konmaz. manifest.json da yazılmadan önce sözleşmeyle (MANIFEST_FIELDS ve ötekiler; belge
## sitesinin okuyucusu docs-app/src/lib/animations.ts) denetlenir.
##
## Kullanım (game/ klasöründe; önce içe aktarma yapılmış olmalı):
##   Godot --headless --path . -s res://tools/clip_library_export.gd -- [id ...] [--dry-run] [--manifest-only]
## id verilmezse modeli olan her karakter. --dry-run: yalnız kaynak tablosunu yazar, dosya yazmaz. --manifest-only: GLB'lere
## dokunmaz, yalnız manifest.json'u yeniden yazar (atama, sahne seçimi, öbek ya da klip tanımı değişince; klibin kendisi değişince
## GLB de yeniden yazılmalıdır). Bir kısım karakter yazılınca manifest'teki ötekiler (GLB'leri duruyorsa) korunur. Yeni kişinin modeli hazırlanınca
## (tools/prepare_character.py, sonra scripts/character/character_fit_tool.gd) bu araç yeniden koşulur; kredi harcamaz. Oyunda el HandGrip'ten gelir, web oynatıcısında yoktur:
## parmak kemiklerine doğal yarı gevşek el sabit iz olarak yazılır (HandGrip.bake_pose; yere dayanan el düz).

## Çıktı klasörü (depo köküne göre; manifest'teki glb yolları da böyledir).
const OUT_DIR := "docs/assets/animations"
## Karakter başına GLB'nin ağ ve doku kısmının hedefi (bayt; klip verisi ve JSON sayılmaz, glb_model_bytes): aşılırsa
## doku kalitesi düşürülür, yine aşılırsa uyarılır. Eski 8 MB'lık dosya hedefinden beş oyun klibinin ≈0,5 MB'ı düşülmüş
## hâli: klipler çoğaldıkça (taşıyıcı paketleri) dokular bozulmasın.
const MAX_MODEL_BYTES := 7_500_000
const JPEG_QUALITY := 0.85
## Model kısmı hedefi aşınca sırayla denenen JPEG kaliteleri.
const FALLBACK_QUALITIES: Array[float] = [0.8, 0.75, 0.7, 0.65]
## Aracın en uzun süresi (saniye): bir betik hatası koşuyu yarıda bırakırsa süreç yine kapanır.
const TIMEOUT := 3600.0
## CharacterAvatar._add_shoulder_relax'ın eşiği (derece): daha küçük açıda oyunda da düzeltme yoktur.
const MIN_SHOULDER_DROP := 0.5
## Oyunun zemin payı (<id>_fit.json) bu yeni ölçümden bu kadar (metre) ayrışırsa konsola yazılır (eski ölçüm).
const FIT_DRIFT_WARN := 0.01

## manifest.json sözleşmesi: nesnelerin alanları, bu sırayla ve eksiksiz (belge sitesinin okuyucusu
## docs-app/src/lib/animations.ts; sözleşme K90 ve site Varlık Hattı sayfası). Fazla alan yazılmaz.
const MANIFEST_FIELDS: Array[String] = ["updated", "_aciklama", "rule", "credits", "groups", "carriers", "clips", "characters", "pending"]
const CREDIT_FIELDS: Array[String] = ["spent_on_actions", "purchases", "distinct_actions", "duplicate_credits", "motions", "total"]
const MOTION_CREDIT_FIELDS: Array[String] = ["count", "credits"]
const GROUP_FIELDS: Array[String] = ["key", "tr", "count", "live"]
const CARRIER_FIELDS: Array[String] = ["tr"]
const CLIP_FIELDS: Array[String] = ["key", "tr", "en", "role", "group", "seat", "tags", "meshy_action", "kind", "prompt", "derived", "purchases", "loop", "seat_loop", "travel_m", "note_tr"]
const TAG_FIELDS: Array[String] = ["body", "age", "style"]
const DERIVED_FIELDS: Array[String] = ["from", "op", "trim_start"]
const PURCHASE_FIELDS: Array[String] = ["character", "credits"]
const CHARACTER_FIELDS: Array[String] = ["id", "tr", "group", "body", "glb", "bytes", "poster", "height_m", "status", "assigned", "scene_picks", "clips"]
const CHARACTER_CLIP_FIELDS: Array[String] = ["source", "donor", "duration", "frames", "loop", "game_role"]
const PENDING_FIELDS: Array[String] = ["id", "tr", "group", "reason_tr"]
const SOURCES: Array[String] = ["native", "native_raw", "retarget"]
const GROUPS: Array[String] = ["player", "named", "crowd"]
const BODIES: Array[String] = ["male", "female", "child"]
const KINDS: Array[String] = ["purchase", "rig", "derived"]
const SEATS: Array[String] = ["ground", "chair"]
## Sahnelerin kimlikleri (manifest'in scene_picks'i): ateş başı ve doğum.
const SCENES: Array[String] = ["camp", "birth"]
const CAMP_SCENE := "res://scenes/world/camp_npcs.tscn"
const BIRTH_SCENE := "res://scenes/cine/prologue_birth.tscn"
## Sayfanın klip öbekleri: sıra ve görünen ad (clip_library.json groups'un adları oyun tarafınındır; sayfanın adları kısadır).
## Burada olmayan öbek, tanımdaki adıyla sona eklenir (group_rows).
const GROUP_LABELS := {
	"idle_loop": "Bekleme",
	"idle_fidget": "Ara hareket",
	"walk": "Yürüme",
	"run": "Koşma",
	"sit_ground": "Yerde oturma",
	"sit_chair": "Taburede oturma",
	"sit_down": "Oturmaya geçiş",
	"stand_up": "Kalkma",
	"talk": "Konuşma",
	"sleep": "Uyku",
	"work": "İş",
}

var _failed := 0


func _initialize() -> void:
	create_timer(TIMEOUT).timeout.connect(_on_timeout)
	_run.call_deferred()


func _on_timeout() -> void:
	printerr("[klip] %d sn içinde bitmedi; durduruluyor" % int(TIMEOUT))
	quit(2)


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var dry := args.has("--dry-run")
	var lib := ClipLibrary.new()
	if lib.definition.is_empty():
		printerr("[klip] kütüphane tanımı okunamadı: %s" % ClipLibrary.DEFINITION_PATH)
		quit(1)
		return
	var started := Time.get_ticks_msec()
	var available := lib.characters_with_models()
	var ids: Array = args.filter(func(a: String) -> bool: return not a.begins_with("--"))
	if args.has("--manifest-only"):
		ids = []
	elif ids.is_empty():
		ids = available.duplicate()
	for line in donor_conflicts(lib):
		print("[klip] UYARI bağışçı ayrılığı: %s" % line)
	var repo := repo_root()
	var out_dir := repo.path_join(OUT_DIR)
	if not dry:
		DirAccess.make_dir_recursive_absolute(out_dir)
	var entries := {}
	for id in ids:
		if not available.has(id):
			printerr("[klip] %s: modeli yok (assets/characters/%s/%s.glb)" % [id, id, id])
			_failed += 1
			continue
		var entry := _export(lib, str(id), available, out_dir, dry)
		if entry.is_empty():
			_failed += 1
		elif not dry:
			entries[id] = entry
	lib.release()
	if not dry:
		_write_manifest(lib, entries, repo, out_dir, available)
	print("[klip] bitti: %d karakter yazıldı, %d hata (%.0f sn)" % [entries.size(), _failed, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if _failed > 0 else 0)


## Bir karakterin GLB'sini yazar; manifest kaydını döndürür (hata olursa boş).
func _export(lib: ClipLibrary, id: String, available: Array, out_dir: String, dry: bool) -> Dictionary:
	# Kayıtlar çelişiyorsa (meta.json kendi klibi diyor, bağışçı tablosu aktarım diyor) veriyle karar verilir.
	var game := lib.game_clips(id)
	for key in game.keys():
		if game[key].get("ambiguous", false):
			var check := lib.verify_game_clip(id, key)
			print("[klip] %s/%s: meta.json kendi klibi, DONORS bağışçı diyor; ham alımla en büyük fark %.4f rad → %s" % [
				id, key, check["difference"], check["source"]])
	var plan := lib.resolve(id, available)
	print("[klip] %s (%s; %s, %s)" % [id, lib.name_of(id), lib.body_of(id), lib.group_of(id)])
	var carried := {}
	for key in plan:
		var e: Dictionary = plan[key]
		if not lib.carrier_of(key).is_empty():
			var label := "%s %s" % [e["source"], str(e["donor"]) if e["donor"] != null else "-"]
			carried[label] = int(carried.get(label, 0)) + 1
			continue
		print("    %-7s %-10s %-7s %s%s" % [key, e["source"], str(e["donor"]) if e["donor"] != null else "-",
			"oyun rolü " + str(e["role"]) if e["game_role"] else "", ("  " + str(e["path"]).get_file()) if not str(e["path"]).is_empty() else ""])
	for label in carried:
		print("    taşıyıcı klipleri: %d × %s" % [carried[label], label])
	if dry:
		return {"id": id}
	var scene := load(StandIn.model_path(id)) as PackedScene
	var model := scene.instantiate() as Node3D if scene else null
	if model == null:
		printerr("[klip] %s: model açılamadı" % id)
		return {}
	var entry := _build_and_write(lib, id, model, plan, available, out_dir)
	model.free()
	return entry


func _build_and_write(lib: ClipLibrary, id: String, model: Node3D, plan: Dictionary, available: Array, out_dir: String) -> Dictionary:
	var skel := ClipLibrary.find_skeleton(model)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	var player: AnimationPlayer = players[0] if not players.is_empty() else null
	if player == null:
		player = AnimationPlayer.new()
		player.name = "AnimationPlayer"
		model.add_child(player)
		player.root_node = NodePath("..")
	var anim_root := player.get_node_or_null(player.root_node)
	if skel == null or anim_root == null:
		printerr("[klip] %s: iskelet ya da oynatıcı kökü yok" % id)
		return {}
	var prefix := String(anim_root.get_path_to(skel))
	var clips := {}
	for key in lib.clip_keys():
		var anim := lib.build_clip(key, id, skel, available, prefix)
		if anim == null:
			printerr("[klip] %s/%s kurulamadı" % [id, key])
			return {}
		ClipLibrary.complete_rest_tracks(anim, skel)
		var pose_fix: Variant = lib.clip(key).get("pose_fix")
		HandGrip.bake_pose(anim, skel, HandGrip.NATURAL_SHAPE, pose_fix.get("flatten_hand", []) if pose_fix is Dictionary else [])
		clips[key] = anim
	complete_position_tracks(clips, skel)
	# Önce omuz: yere dayanan elin (ground_side_sit) yeri düzeltmeyle değişir, pay son pozdan ölçülsün.
	_bake_shoulders(id, model, skel, clips)
	if _ground_offsets(lib, id, model, skel, player, clips, plan).is_empty():
		printerr("[klip] %s: klipler zemine oturtulamadı" % id)
		return {}
	for lib_name in player.get_animation_library_list():
		player.remove_animation_library(lib_name)
	var library := AnimationLibrary.new()
	for key in lib.clip_keys():
		library.add_animation(key, clips[key])
	player.add_animation_library(&"", library)
	var path := out_dir.path_join(id + ".glb")
	var error := _write_glb(model, path, lib.clip_keys(), skel)
	if not error.is_empty():
		printerr("[klip] %s: %s" % [id, error])
		return {}
	var bytes := FileAccess.get_file_as_bytes(path).size()
	var parts := glb_parts(path)
	print("[klip] %s → %s (%.2f MB: ağ ve doku %.2f MB, klipler %.2f MB)%s" % [id, path, bytes / 1000000.0, parts["model"] / 1000000.0,
		parts["animation"] / 1000000.0, "  UYARI: ağ ve doku %.1f MB hedefini aştı" % (MAX_MODEL_BYTES / 1000000.0) if parts["model"] > MAX_MODEL_BYTES else ""])
	var clip_entries := {}
	for key in lib.clip_keys():
		var e: Dictionary = plan[key]
		var anim: Animation = clips[key]
		clip_entries[key] = {
			"source": e["source"],
			"donor": e["donor"],
			"duration": snappedf(anim.length, 0.001),
			"frames": ClipLibrary.frame_count(anim),
			"loop": anim.loop_mode != Animation.LOOP_NONE,
			"game_role": e["game_role"],
		}
	var body := lib.body_of(id)
	return {
		"id": id,
		"tr": lib.name_of(id),
		"group": lib.group_of(id),
		"body": body if not body.is_empty() else null,
		"glb": OUT_DIR.path_join(id + ".glb"),
		"bytes": bytes,
		"poster": poster(lib, id),
		"height_m": StandIn.meta(id).get("height_m", lib.plan_row(id).get("height_m")),
		"status": "ready",
		"assigned": assigned_rows(id, group_keys(lib)),
		"scene_picks": {},
		"clips": clip_entries,
	}


## Bir klipte konum izi olan kemiğe öteki kliplerde de iz ekler (dinlenme konumunda sabit): web oynatıcısı klip değişince izi
## olmayan kemikte önceki klibin konumunu bırakır (ClipLibrary.complete_rest_tracks dönüş izleri ve kök için aynısını yapar). clips:
## {anahtar: Animation}. Eklenen iz sayısını döndürür.
static func complete_position_tracks(clips: Dictionary, skel: Skeleton3D) -> int:
	var bones := {}
	for key in clips:
		var anim: Animation = clips[key]
		for t in anim.get_track_count():
			if anim.track_get_type(t) == Animation.TYPE_POSITION_3D:
				bones[String(anim.track_get_path(t).get_concatenated_subnames())] = true
	var added := 0
	for key in clips:
		var anim: Animation = clips[key]
		var prefix := ClipRetarget.track_prefix(anim)
		for bone_name: String in bones:
			var bone := skel.find_bone(bone_name)
			var path := NodePath("%s:%s" % [prefix, bone_name])
			if bone < 0 or anim.find_track(path, Animation.TYPE_POSITION_3D) >= 0:
				continue
			var rest := skel.get_bone_rest(bone).origin
			var track := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(track, path)
			anim.position_track_insert_key(track, 0.0, rest)
			if anim.length > 0.0:
				anim.position_track_insert_key(track, anim.length, rest)
			added += 1
	return added


## Her klibi zemine oturtur: klibin örnek anlarında (PoseFit.floor_times) temas kemiklerinin (ClipLibrary.contact_for: tanımın contact'ı)
## en altı (PoseFit.skinned_min_y) ölçülür, pay oyunun payıyla aynı kuraldır (PoseFit.floor_offset; tools/anim_library_import.gd): en alçak an y = 0'a
## gelsin diye kök kemik o kadar kaydırılır; yürüme ve koşmada kare başına en alt noktaların alttan dilimi y = 0'dadır.
## Geçişte (transition_states) ilk kare başlangıç, son kare bitiş duruşunun temas kemikleriyle ölçülür ve pay arada doğrusal
## kayar: iki uç da zemine oturur. Web oynatıcısı zemini ve gölgeyi dinlenme pozunun en altına koyar (bu modellerde y = 0); pay
## pişirilmezse oturan klip havada, aktarılmış bekleme yere gömülü durur. Oyunun kendi rol klibinin payı (<id>_fit.json
## ground_offset, baldır ve ayakla ölçülmüş) bu ölçümden ayrışırsa konsola yazılır; sayfada ölçüm geçerlidir. Dönüş: {anahtar:
## Vector2(ilk kare, son kare) (metre)}; ölçülemezse boş.
func _ground_offsets(lib: ClipLibrary, id: String, model: Node3D, skel: Skeleton3D, player: AnimationPlayer, clips: Dictionary, plan: Dictionary) -> Dictionary:
	var fit_offsets: Variant = CharacterAvatar._load_fit(id).get("ground_offset")
	for lib_name in player.get_animation_library_list():
		player.remove_animation_library(lib_name)
	var library := AnimationLibrary.new()
	for key in clips:
		library.add_animation(key, clips[key])
	player.add_animation_library(&"", library)
	# Skeleton3D ağaç dışındayken (ve ana döngü başlamadan, _initialize içinde) poz değişince global pozlarını yenilemez:
	# ölçüm sırasında model ağaçta durur, araç _run'ı call_deferred ile koşar. Döngülü klipte son örnek (t = süre) ilk
	# kareye sarar (character_fit_tool.gd'de de böyle): yürüme ve koşmada son örnek süreden bir adım öncedir (PoseFit.floor_times), öteki
	# döngülerde ilk ve son pozu ayrışan klibin son karesi birkaç mm sapabilir.
	get_root().add_child(model)
	var out := {}
	var stale := []
	var ramps := 0
	var low := INF
	var high := -INF
	for key in clips:
		var anim: Animation = clips[key]
		player.play(key)
		var contact := lib.contact_for(key)
		var lows := PackedFloat32Array()
		for time in PoseFit.floor_times(anim.length, lib.clip(key)):
			player.seek(time, true)
			lows.append(PoseFit.skinned_min_y(model, contact))
		var measured := PoseFit.floor_offset(lows, lib.clip(key))
		var offset := Vector2(measured, measured)
		var states := transition_states(lib.clip(key))
		if not states.is_empty():
			player.seek(0.0, true)
			offset.x = -PoseFit.skinned_min_y(model, lib.contact_for_state(states[0]))
			player.seek(anim.length, true)
			offset.y = -PoseFit.skinned_min_y(model, lib.contact_for_state(states[1]))
			ramps += 1
		var e: Dictionary = plan[key]
		var role := str(e["role"])
		if e["game_role"] and fit_offsets is Dictionary and (fit_offsets as Dictionary).has(role) and absf(float(fit_offsets[role]) - measured) > FIT_DRIFT_WARN:
			stale.append("%s %+.3f (ölçülen %+.3f)" % [key, float(fit_offsets[role]), measured])
		out[key] = offset
		low = minf(low, minf(offset.x, offset.y))
		high = maxf(high, maxf(offset.x, offset.y))
	player.stop()
	get_root().remove_child(model)
	player.remove_animation_library(&"")
	# GLTFDocument kemiklerin o anki pozunu glTF düğümlerine (içe aktarılınca dinlenme pozuna) yazar: ölçümün bıraktığı
	# poz dinlenme pozuna döner, yoksa GLB'nin dinlenme pozu son ölçülen karenin pozu olur.
	skel.reset_bone_poses()
	if out.size() != clips.size():
		return {}
	var up := PoseFit.relative_transform(model, skel).basis.inverse() * Vector3.UP
	for key in out:
		var offset: Vector2 = out[key]
		shift_root_ramp(clips[key], skel, up * offset.x, up * offset.y)
	print("[klip] %s: %d klip zemine oturtuldu, %d geçişin iki ucu ayrı (pay %+.3f..%+.3f m)%s" % [id, out.size(), ramps, low, high,
		"; oyunun rol payı yeni ölçümden ayrışıyor (character_fit_tool yeniden koşmalı): " + ", ".join(stale) if not stale.is_empty() else ""])
	return out


## Klibin iki ucunun duruşu, payları ayrı ölçülecekse: [başlangıç, bitiş] (saf). Geçiş değilse ya da klip oturak istiyorsa boş:
## oturak isteyen klipte yere yalnız ayak değer, beden oturakta ya da yatakta kalır (sleep'in son pozu yerden 58 cm yukarıda).
static func transition_states(spec: Dictionary) -> Array:
	var transition: Variant = spec.get("transition")
	if not transition is Dictionary or str(spec.get("seat")) == "chair":
		return []
	return [str(transition.get("from")), str(transition.get("to"))]


## Kök kemiğin konum izini ilk karede start, son karede end kadar kaydırır, arada doğrusal (iskelet uzayı). İki değer aynıysa
## ClipLibrary.shift_root'un yaptığı; ayrıysa kökün konum izi olmalı (ClipLibrary.complete_rest_tracks kurar). Kaydırdıysa true.
static func shift_root_ramp(anim: Animation, skel: Skeleton3D, start: Vector3, end: Vector3) -> bool:
	var shifted := ClipLibrary.shift_root(anim, skel, start)
	if start.is_equal_approx(end) or anim.length <= 0.0:
		return shifted
	var track := -1
	for b in skel.get_bone_count():
		if skel.get_bone_parent(b) < 0:
			track = anim.find_track(NodePath("%s:%s" % [ClipRetarget.track_prefix(anim), skel.get_bone_name(b)]), Animation.TYPE_POSITION_3D)
			break
	if track < 0:
		return shifted
	for k in anim.track_get_key_count(track):
		var share := clampf(anim.track_get_key_time(track, k) / anim.length, 0.0, 1.0)
		anim.track_set_key_value(track, k, (anim.track_get_key_value(track, k) as Vector3) + (end - start) * share)
	return true


## Omuz düzeltmesini bütün kliplere pişirir (hepsine birden ya da hiçbirine). Pişirildiyse true.
func _bake_shoulders(id: String, model: Node3D, skel: Skeleton3D, clips: Dictionary) -> bool:
	var drop := float(CharacterAvatar._load_fit(id).get("shoulder_drop", 0.0))
	if drop < MIN_SHOULDER_DROP:
		print("[klip] %s: omuz düzeltmesi yok (shoulder_drop %.1f°)" % [id, drop])
		return false
	# ShoulderRelax yukarıyı iskelet uzayında alır; model dik dururken bu, iskeletin model köküne göre dönüşünden gelir.
	var up := (PoseFit.relative_transform(model, skel).basis.inverse() * Vector3.UP).normalized()
	var baked := {}
	var worst := 0.0
	var samples := 0
	for key in clips:
		var copy := (clips[key] as Animation).duplicate(true)
		var result := ClipLibrary.bake_shoulder_relax(copy, skel, up, drop)
		if not result["baked"]:
			print("[klip] %s/%s: omuz düzeltmesi birebir pişirilemedi (%s); klipler ham kalır" % [id, key, result["reason"]])
			return false
		worst = maxf(worst, result["between_deg"])
		samples += int(result["keys"])
		baked[key] = copy
	for key in baked:
		clips[key] = baked[key]
	print("[klip] %s: omuz düzeltmesi %.1f° pişirildi (%d örnek; örnekler arasında en büyük sapma %.4f°)" % [id, drop, samples, worst])
	return true


## Sahneyi GLB olarak yazar: önce geçici dosyaya, denetimden geçerse asıl yerine. Ağ ve doku kısmı (glb_parts) hedefi
## (MAX_MODEL_BYTES) aşarsa JPEG kalitesi FALLBACK_QUALITIES sırasıyla düşürülerek yeniden yazılır (ağ ve klipler
## değişmez). Hata yoksa boş metin.
func _write_glb(model: Node, path: String, keys: PackedStringArray, skel: Skeleton3D) -> String:
	var tmp := path.get_basename() + ".tmp.glb"
	var format := _image_format(model)
	var qualities: Array = [JPEG_QUALITY]
	if format == "JPEG":
		qualities.append_array(FALLBACK_QUALITIES)
	for quality in qualities:
		var doc := GLTFDocument.new()
		doc.image_format = format
		doc.lossy_quality = quality
		var state := GLTFState.new()
		var err := doc.append_from_scene(model, state)
		if err != OK:
			return "sahne glTF'e çevrilemedi (hata %d)" % err
		_drop_tangents(state)
		err = doc.write_to_filesystem(state, tmp)
		if err != OK:
			DirAccess.remove_absolute(tmp)
			return "GLB yazılamadı (hata %d)" % err
		if int(glb_parts(tmp)["model"]) <= MAX_MODEL_BYTES or quality == qualities[-1]:
			if quality != JPEG_QUALITY:
				print("[klip] %s: ağ ve doku %.1f MB hedefi için doku JPEG kalitesi %.2f" % [path.get_file(), MAX_MODEL_BYTES / 1000000.0, quality])
			break
	var problem := _verify_glb(tmp, keys, skel)
	if not problem.is_empty():
		DirAccess.remove_absolute(tmp)
		return "yazılan GLB denetimden geçmedi: " + problem
	var moved := DirAccess.rename_absolute(tmp, path)
	return "" if moved == OK else "GLB yerine konamadı (hata %d)" % moved


## Yazılan GLB'yi geri okur: animasyonlar tam olarak klip anahtarları mı, iskelet aynı kemiklerle ve aynı dinlenme
## pozuyla mı (GLTFDocument kemiklerin o anki pozunu yazar: poz dinlenmede değilse GLB'nin dinlenme pozu bozulur), ağ
## deri bağlı mı, doku var mı? Sorun yoksa boş metin.
func _verify_glb(path: String, keys: PackedStringArray, source: Skeleton3D) -> String:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	if doc.append_from_file(path, state) != OK:
		return "okunamadı"
	var root := doc.generate_scene(state)
	if root == null:
		return "sahne kurulamadı"
	var problem := ""
	var players := root.find_children("*", "AnimationPlayer", true, false)
	var names := Array((players[0] as AnimationPlayer).get_animation_list()) if not players.is_empty() else []
	names = names.filter(func(n: String) -> bool: return n != "RESET")
	names.sort()
	var expected := Array(keys)
	expected.sort()
	var skel := ClipLibrary.find_skeleton(root)
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if names != expected:
		problem = "animasyonlar %s, beklenen %s" % [names, expected]
	elif skel == null or skel.get_bone_count() != source.get_bone_count():
		problem = "iskelet %d kemikli, beklenen %d" % [skel.get_bone_count() if skel else 0, source.get_bone_count()]
	elif not _rest_difference(skel, source).is_empty():
		problem = "dinlenme pozu kaynaktan farklı: %s" % _rest_difference(skel, source)
	elif meshes.is_empty() or (meshes[0] as MeshInstance3D).skin == null:
		problem = "deri bağlı ağ yok"
	elif state.get_images().is_empty():
		problem = "doku yok"
	root.free()
	return problem


## GLB'nin bölümleri (bayt; JSON parçasından): animation klip verisi (animasyon örnekleyicilerinin erişimcilerinin
## bufferView'ları; Godot zaman dizilerini klipler arasında paylaştırır), model geri kalan bufferView'lar (ağ, deri,
## dokular). Okunamazsa ikisi de -1.
static func glb_parts(path: String) -> Dictionary:
	var out := {"model": -1, "animation": -1}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 20:
		return out
	file.seek(12)
	var length := file.get_32()
	file.get_32()
	var gltf: Variant = JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
	file.close()
	if not gltf is Dictionary:
		return out
	var accessors: Array = gltf.get("accessors", [])
	var anim_views := {}
	for animation in gltf.get("animations", []):
		for sampler in animation.get("samplers", []):
			for field in ["input", "output"]:
				var accessor: Dictionary = accessors[int(sampler[field])]
				if accessor.has("bufferView"):
					anim_views[int(accessor["bufferView"])] = true
	var views: Array = gltf.get("bufferViews", [])
	out = {"model": 0, "animation": 0}
	for v in views.size():
		out["animation" if anim_views.has(v) else "model"] += int(views[v].get("byteLength", 0))
	return out


## İki iskeletin dinlenme pozu farkı (kemik adına göre): 0,001 radyandan ya da 0,01 iskelet biriminden büyük ilk fark,
## yoksa boş metin.
static func _rest_difference(a: Skeleton3D, b: Skeleton3D) -> String:
	for i in a.get_bone_count():
		var j := b.find_bone(a.get_bone_name(i))
		if j < 0:
			return "%s kemiği yok" % a.get_bone_name(i)
		var ra := a.get_bone_rest(i)
		var rb := b.get_bone_rest(j)
		var angle := ra.basis.get_rotation_quaternion().angle_to(rb.basis.get_rotation_quaternion())
		var gap := ra.origin.distance_to(rb.origin)
		if angle > 0.001 or gap > 0.01:
			return "%s %.4f rad, %.3f birim" % [a.get_bone_name(i), angle, gap]
	return ""


## Dokular JPEG'den geldiyse JPEG (kayıplı, küçük), değilse PNG (saydamlık korunur).
func _image_format(model: Node) -> String:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s) as BaseMaterial3D
			if mat and mat.albedo_texture and not mat.albedo_texture.resource_path.get_extension().to_lower() in ["jpg", "jpeg"]:
				return "PNG"
	return "JPEG"


## Ağların teğetlerini atar (köşe başına 16 bayt): malzemede normal haritası yok, teğet yalnız onun için gerekir.
## GLTFDocument ImporterMesh'teki teğeti yazar; burada teğetsiz kopyasıyla değiştirilir. Karışım şekli olan ağa
## dokunulmaz.
func _drop_tangents(state: GLTFState) -> void:
	for item in state.get_meshes():
		var gltf_mesh := item as GLTFMesh
		var src := gltf_mesh.mesh
		if src == null or src.get_blend_shape_count() > 0:
			continue
		var out := ImporterMesh.new()
		out.set_name(src.get_name())
		for s in src.get_surface_count():
			var arrays := src.get_surface_arrays(s)
			arrays[Mesh.ARRAY_TANGENT] = null
			out.add_surface(src.get_surface_primitive_type(s), arrays, [], {}, src.get_surface_material(s), src.get_surface_name(s),
				src.get_surface_format(s) & ~Mesh.ARRAY_FORMAT_TANGENT)
		gltf_mesh.mesh = out


## manifest.json: klipler, alımlar, kredi özeti, karakterler ve bekleyenler. Sözleşmeye uymazsa yazılmaz.
func _write_manifest(lib: ClipLibrary, entries: Dictionary, repo: String, out_dir: String, available: Array) -> void:
	var path := out_dir.path_join("manifest.json")
	var previous := {}
	var old: Variant = ClipLibrary.read_json(path)
	if old is Dictionary:
		for c in (old as Dictionary).get("characters", []):
			if c is Dictionary:
				previous[str(c.get("id", ""))] = c
	var order := lib.character_ids()
	for id in available:
		if not order.has(id):
			order.append(id)
	var characters := []
	var groups := group_keys(lib)
	var picks := scene_pick_rows(get_root())
	for id in order:
		if entries.has(id):
			var entry: Dictionary = entries[id]
			entry["scene_picks"] = picks.get(id, {})
			characters.append(entry)
		elif previous.has(id) and available.has(id) and FileAccess.file_exists(repo.path_join(str(previous[id].get("glb", "")))):
			# Eski kayıt sözleşmenin alanlarına indirilir (eski sürümün fazla alanları taşınmasın); atama ve sahne seçimi GLB'ye bağlı
			# değil, yenilenir.
			var kept := {}
			for field in CHARACTER_FIELDS:
				match field:
					"assigned":
						kept[field] = assigned_rows(str(id), groups)
					"scene_picks":
						kept[field] = picks.get(id, {})
					_:
						kept[field] = _integers(previous[id].get(field))
			characters.append(kept)
	var purchases := lib.all_purchases()
	var motions := lib.all_motion_purchases()
	var manifest := {
		"updated": Time.get_datetime_string_from_system(true) + "Z",
		"_aciklama": "game/tools/clip_library_export.gd yazar; elle düzenlenmez. K90: her Meshy hareketi bir kez satın alınır, bütün karakterlere ClipRetarget ile aktarılır (tanım game/data/clip_library.json). characters[].glb depo köküne göre GLB'dir (belge sitesi /media/<glb> adresinden okur); içindeki animasyonların adları clips[].key'dir. Her klip zemine oturtulmuştur (klibin contact kemiklerinin en altı y = 0'da; yürüme ve koşmada kare başına en alt noktaların alttan dilimi, oyunun payıyla aynı kural, PoseFit.floor_offset; geçişte iki uç ayrı, states'in temas kemikleriyle, arada doğrusal; pay kök kemiğe pişirildi) ve oyunun omuz düzeltmesi (ShoulderRelax) kliplere pişirilmiştir. groups: sayfanın klip öbekleri (key, tr, count: öbekteki klip sayısı; live: bugün sahnede rolü olan öbek, ClipVariety.ROLE_GROUPS), sayfanın sırasıyla. carriers: karakter olmayan taşıyıcı iskeletler ({kimlik: {tr}}); donor ya da purchases[].character böyle bir kimlik olabilir. clips[]: group (öbek), seat (ground: yerde, chair: oturak ister, null: oturmaz), tags (body, age, style listeleri: ClipVariety'nin uygunluğu), kind (purchase: kredili, rig: iskelet görevinin ücretsiz klibi, derived: başka klipten 0 krediyle türetilmiş), prompt (metinden hareketin istemi, öteki kliplerde null), derived (türetilmiş klibin kaynağı: from, op, trim_start; öteki kliplerde null), loop (klip döngülü mü), seat_loop (bir kez oynayan oturuş oturma rolünde döngüye kapatılıyor mu: true kapatılır, false son pozunda durur, ClipVariety.role_clip; öteki kliplerde null), travel_m (bir kez oynayan klibin kökünün yatay yer değiştirmesi, metre; döngülü klip yerinde oynar, 0). characters[].clips[<anahtar>].source: native (oyundaki kendi klibi), native_raw (satın alınmış, oyunda kullanılmayan ham Meshy klibi), retarget (donor'dan ClipRetarget ile aktarıldı; donor bir karakter ya da taşıyıcıdır); game_role: modelin o rol için kendi dosyalarında durduğu klip (çeşit atanmamış kişi bunu oynar). characters[].assigned: ClipVariety'nin kişiye varsayılan ataması, sahnesiz: {öbek: klip anahtarı}; idle_fidget (ara hareket) kişinin bütün uygun çeşitlerinin listesidir; rol öbekleri dışındakiler (oturak, geçiş, konuşma, uyku, iş) sahne isteyince aynı kuralla seçilen çeşittir; uygun çeşit yoksa öbek yazılmaz; oyuncu karakteri çeşit almaz, kendi klipleriyle oynar: boş (K91). characters[].scene_picks: sahnenin kişiye bugün oynattığı klipler, {sahne: {öbek: klip anahtarı}}; camp: ateş başının elle seçilmiş oturuşları (CampNpcs.SEATS), birth: doğum sahnesinin kullandığı rollerde kişinin klibi; sahnede olmayan kişide boş. credits: spent_on_actions Meshy kütüphanesinin hareket alımlarının kredisi (meshy.json'lardaki anim_* görevleri; toplu alım hareket başına bir alımdır), purchases başarılı alım sayısı, distinct_actions farklı hareket, duplicate_credits aynı hareketin ilk alımı dışındaki alımlarının kredisi, motions metinden hareketler (count: başarılı hareket, credits: text-to-motion ve iskelete uygulama), total hareketlere giden toplam (spent_on_actions + motions.credits; iskelet görevleri girmez). pending: modeli henüz gelmemiş kişiler.",
		"rule": str(lib.definition.get("rule", "K90")),
		"credits": credit_block(purchases, motions),
		"groups": group_rows(lib),
		"carriers": carrier_rows(lib),
		"clips": clip_rows(lib, purchases, motions),
		"characters": characters,
		"pending": pending_rows(lib),
	}
	var problems := manifest_problems(manifest)
	if not problems.is_empty():
		printerr("[klip] manifest sözleşmeye uymuyor, yazılmadı: %s" % "; ".join(problems))
		_failed += 1
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[klip] manifest yazılamadı: %s" % path)
		_failed += 1
		return
	file.store_string(JSON.stringify(manifest, "  ", false) + "\n")
	file.close()
	var credits: Dictionary = manifest["credits"]
	var total_bytes := 0
	for ch: Dictionary in characters:
		total_bytes += int(ch["bytes"])
	print("[klip] manifest → %s (%d klip, %d karakter, GLB'ler toplam %.1f MB, %d bekleyen; hareketlere %d kredi: mağaza %d, %d alım, %d farklı hareket, tekrar %d kredi; metinden %d hareket %d kredi)" % [
		path, manifest["clips"].size(), characters.size(), total_bytes / 1000000.0, manifest["pending"].size(), credits["total"], credits["spent_on_actions"],
		credits["purchases"], credits["distinct_actions"], credits["duplicate_credits"], credits["motions"]["count"], credits["motions"]["credits"]])


## manifest'in clips listesi (saf): kütüphanenin her klibi tanımdaki sırayla; purchases klibin başarılı alımları
## (hareket numarasıyla eşleşen alımlar; metinden harekette text-to-motion ve uygulama kredisinin toplamı). Türetilmiş klibin
## alımı yoktur (derived kaynağını söyler).
static func clip_rows(lib: ClipLibrary, purchases: Array, motions: Array) -> Array:
	var rows := []
	for key in lib.clip_keys():
		var spec := lib.clip(key)
		var action: Variant = spec.get("meshy_action")
		var motion: Variant = spec.get("motion")
		var bought := []
		if motion != null:
			for m in motions:
				if m["motion"] == str(motion) and m["status"] == "SUCCEEDED" and (lib.carrier_of(key).is_empty() or m["character"] == lib.carrier_of(key)):
					bought.append({"character": m["character"], "credits": m["credits"]})
		elif action != null:
			for p in purchases:
				if p["action"] == int(action) and p["status"] == "SUCCEEDED":
					bought.append({"character": p["character"], "credits": p["credits"]})
		var kind := str(spec.get("kind", ""))
		var seat := str(spec.get("seat"))
		rows.append({
			"key": key,
			"tr": str(spec.get("tr", key)),
			"en": str(spec.get("en", key)),
			"role": str(spec.get("role", "")),
			"group": str(spec.get("group", "")),
			"seat": seat if SEATS.has(seat) else null,
			"tags": tag_row(spec),
			"meshy_action": int(action) if action != null else null,
			"kind": kind if KINDS.has(kind) else "purchase",
			"prompt": prompt_of(spec),
			"derived": derived_row(spec),
			"purchases": bought,
			"loop": bool(spec.get("loop", true)),
			"seat_loop": seat_loop_of(lib, key),
			"travel_m": travel_of(lib, key),
			"note_tr": str(spec.get("note_tr", "")),
		})
	return rows


## Bir kez oynayan oturuş oturma rolünde döngüye kapatılıyor mu (ClipVariety.role_clip): true kapatılır, false son pozunda durur.
## Oturma öbeğinde olmayan ya da zaten döngülü klipte null.
static func seat_loop_of(lib: ClipLibrary, key: String) -> Variant:
	var spec := lib.clip(key)
	var group := str(spec.get("group", ""))
	if (group != ClipVariety.GROUND_GROUP and group != ClipVariety.SEAT_GROUP) or bool(spec.get("loop", true)):
		return null
	return float(lib.measure(key).get("cycle_gap_deg", 0.0)) <= ClipVariety.MAX_SEAT_SEAM_DEG


## Bir kez oynayan klibin kökünün yatay yer değiştirmesi (metre; data/clip_library_measure.json root_delta_m). Döngülü klip
## yerinde oynar, ölçülmemiş klip bilinmez: 0.
static func travel_of(lib: ClipLibrary, key: String) -> float:
	var delta: Variant = lib.measure(key).get("root_delta_m")
	if bool(lib.clip(key).get("loop", true)) or not delta is Array or (delta as Array).size() < 3:
		return 0.0
	return snappedf(Vector2(float(delta[0]), float(delta[2])).length(), 0.01)


## Klibin etiketleri (saf): body, age ve style listeleri (yazılı değilse boş; boş liste kısıt yok demektir).
static func tag_row(spec: Dictionary) -> Dictionary:
	var tags: Dictionary = spec["tags"] if spec.get("tags") is Dictionary else {}
	var out := {}
	for field in TAG_FIELDS:
		out[field] = tags[field] if tags.get(field) is Array else []
	return out


## Metinden hareketin istemi (saf): tanımın note_tr'sinde «İstem: «…»» diye yazılıdır. Metinden hareket değilse ya da istem
## yazılı değilse null.
static func prompt_of(spec: Dictionary) -> Variant:
	if spec.get("motion") == null:
		return null
	var note := str(spec.get("note_tr", ""))
	var mark := "İstem: «"
	var at := note.find(mark)
	var end := note.find("»", at + mark.length()) if at >= 0 else -1
	return note.substr(at + mark.length(), end - at - mark.length()) if end >= 0 else null


## Türetilmiş klibin kaynağı (saf): {from, op, trim_start}; türetilmiş değilse null.
static func derived_row(spec: Dictionary) -> Variant:
	var derived: Variant = spec.get("derived")
	if not derived is Dictionary or str(spec.get("kind", "")) != ClipLibrary.KIND_DERIVED:
		return null
	return {"from": str(derived.get("from", "")), "op": str(derived.get("op", "")), "trim_start": float(derived.get("trim_start", 0.0))}


## manifest'in groups listesi (saf): öbekler sayfanın sırasıyla ve adıyla (GROUP_LABELS); orada olmayan öbek tanımdaki adıyla
## sona. count öbekteki klip sayısı; klibi olmayan öbek yazılmaz.
static func group_rows(lib: ClipLibrary) -> Array:
	var counts := {}
	var order: Array = GROUP_LABELS.keys()
	for key in lib.clip_keys():
		var group := str(lib.clip(key).get("group", ""))
		if group.is_empty():
			continue
		counts[group] = int(counts.get(group, 0)) + 1
		if not order.has(group):
			order.append(group)
	var defined: Dictionary = lib.definition["groups"] if lib.definition.get("groups") is Dictionary else {}
	var rows := []
	for group: String in order:
		if counts.has(group):
			var own: Dictionary = defined[group] if defined.get(group) is Dictionary else {}
			rows.append({"key": group, "tr": str(GROUP_LABELS.get(group, own.get("tr", group))), "count": counts[group], "live": ClipVariety.ROLE_GROUPS.values().has(group)})
	return rows


## Öbeklerin anahtarları, sayfanın sırasıyla.
static func group_keys(lib: ClipLibrary) -> Array:
	return group_rows(lib).map(func(row: Dictionary) -> String: return row["key"])


## manifest'in carriers'ı (saf): {kimlik: {tr}}.
static func carrier_rows(lib: ClipLibrary) -> Dictionary:
	var out := {}
	for id in lib.carrier_ids():
		out[str(id)] = {"tr": str(lib.carrier(str(id)).get("tr", id))}
	return out


## manifest'in credits'i (saf): credit_summary'nin alanları (Meshy kütüphanesinin hareket alımları), metinden hareketler
## (motions: count başarılı hareket, credits bütün kayıtların kredisi) ve hareketlere giden toplam (total).
static func credit_block(purchases: Array, motions: Array) -> Dictionary:
	var out := ClipLibrary.credit_summary(purchases)
	var count := 0
	var credits := 0
	for m in motions:
		credits += int(m.get("credits", 0))
		if str(m.get("status", "")) == "SUCCEEDED":
			count += 1
	out["motions"] = {"count": count, "credits": credits}
	out["total"] = int(out["spent_on_actions"]) + credits
	return out


## Kişinin varsayılan çeşitleri: ClipVariety'nin kuralları, sahnesiz (boş dağıtıcıdaki ilk kişi gibi; Allocator.key_for). groups:
## öbeklerin sırası. {öbek: klip anahtarı}; ara hareketler (FIDGET_GROUP) kişinin bütün uygun çeşitlerinin listesidir. Oturak öbeği
## sahnenin oturak vermesini ister (yüksekliği belirsiz sayılır). Varsayılan havuzu boş olan öbekler (konuşma, iş, uyku: durum
## çeşitleri) durum açıkça istenmiş gibi seçilir. Uygun çeşit yoksa öbek yazılmaz. Oyuncu karakteri çeşit almaz, kendi klipleriyle
## oynar (K91): boş.
static func assigned_rows(id: String, groups: Array) -> Dictionary:
	var out := {}
	if ClipVariety.library().group_of(id) == "player":
		return out
	var profile := ClipVariety.profile_of(id)
	for group: String in groups:
		if group == ClipVariety.FIDGET_GROUP:
			out[group] = ClipVariety.fidget_pool(profile)
			continue
		var options := {"model": ClipVariety.model_of(id)}
		if group == ClipVariety.SEAT_GROUP:
			options["seat"] = {"type": "chair"}
		var key := ClipVariety.pick(id, group, profile, [], options)
		if key.is_empty():
			options["situations"] = ClipVariety.SITUATION_STYLES
			key = ClipVariety.pick(id, group, profile, [], options)
		if not key.is_empty():
			out[group] = key
	return out


## Sahnelerin kişilere bugün oynattığı klipler: {kişi: {sahne: {öbek: klip anahtarı}}}, sahneler SCENES sırasıyla. parent: doğum
## sahnesinin kurulacağı düğüm (ağaçta olmalı).
static func scene_pick_rows(parent: Node) -> Dictionary:
	var camp := camp_picks()
	var birth := birth_picks(parent)
	var out := {}
	for person: String in camp:
		out[person] = {"camp": {ClipVariety.GROUND_GROUP: camp[person]}}
	for person: String in birth:
		var row: Dictionary = out.get(person, {})
		row["birth"] = birth[person]
		out[person] = row
	return out


## Ateş başının elle seçilmiş oturuşları: {kişi: klip anahtarı}. Sahne yalnız düğüm adlarını ve kişileri okumak için açılır, ağaca
## girmez: model yüklenmez.
static func camp_picks() -> Dictionary:
	var camp := (load(CAMP_SCENE) as PackedScene).instantiate()
	var out := {}
	for avatar in camp.get_children():
		if avatar is CharacterAvatar and CampNpcs.SEATS.has(String(avatar.name)):
			out[CampNpcs.person_id(avatar)] = CampNpcs.SEATS[String(avatar.name)]
	camp.free()
	return out


## Doğum sahnesinin kişilere verdiği klipler: {kişi: {öbek: klip anahtarı}}. Atama sahnenin kurulumuna bağlıdır (tek dağıtıcı, yürüme
## hızları, kendi klibinde kalan oturuş), bu yüzden gerçek sahne kurulur. Yalnız sahnenin çekimlerde kullandığı pozların (kişinin
## pose izi) öbeği yazılır: Teoman yurtta oturmaz, oturuşu yazılmaz. Rolü kendi klibinde tutulan kişide (pinned_roles) klip kendi
## klibidir. Başka bir kişinin ağını gösteren yer tutucu (iki Lan kadını) yazılmaz: sayfada kendi satırı yoktur.
static func birth_picks(parent: Node) -> Dictionary:
	var scene := (load(BIRTH_SCENE) as PackedScene).instantiate() as PrologueBirth
	parent.add_child(scene)
	scene.setup({})
	scene.build_all()
	var poses := {}
	for library_name in scene.player.get_animation_library_list():
		var library := scene.player.get_animation_library(library_name)
		for anim_name in library.get_animation_list():
			var anim := library.get_animation(anim_name)
			for track in anim.get_track_count():
				var path := str(anim.track_get_path(track))
				if not path.begins_with("Actors/") or not path.ends_with(":pose"):
					continue
				var actor_name := path.get_slice("/", 1).get_slice(":", 0)
				for k in anim.track_get_key_count(track):
					var used: Dictionary = poses.get(actor_name, {})
					used[StringName(anim.track_get_key_value(track, k))] = true
					poses[actor_name] = used
	var out := {}
	for actor in scene.actors():
		var person := actor.person_id()
		if person != actor.model_id():
			continue
		var row := {}
		for role: StringName in ClipVariety.ROLE_GROUPS:
			if not (poses.get(String(actor.name), {}) as Dictionary).has(role):
				continue
			var key := actor.avatar.variety_key(role)
			if key.is_empty():
				key = ClipVariety.own_key(person, role)
			if not key.is_empty():
				row[ClipVariety.ROLE_GROUPS[role]] = key
		if not row.is_empty():
			out[person] = row
	scene.free()
	return out


## GLB'nin animasyon adları (JSON parçasından; dosyayı açıp sahne kurmaz). Okunamazsa boş.
static func glb_animation_names(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 20:
		return []
	file.seek(12)
	var length := file.get_32()
	file.get_32()
	var gltf: Variant = JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
	file.close()
	if not gltf is Dictionary:
		return []
	return (gltf.get("animations", []) as Array).map(func(a: Dictionary) -> String: return str(a.get("name", "")))


## asset_plan.json'da kişi olup modeli henüz olmayanlar (Meshy kuyruğu, doku çeşidi).
static func pending_rows(lib: ClipLibrary) -> Array:
	var out := []
	var data: Variant = ClipLibrary.read_json(ClipLibrary.ASSET_PLAN_PATH)
	if not data is Dictionary:
		return out
	for row in (data as Dictionary).get("assets", []):
		if not row is Dictionary or str(row.get("kind", "")) != "character":
			continue
		var id := str(row.get("id", ""))
		if StandIn.has_model(id):
			continue
		out.append({"id": id, "tr": lib.name_of(id), "group": lib.group_of(id), "reason_tr": pending_reason(lib, row, lib.meshy_tasks(id))})
	return out


## Bekleyen kişinin gerekçesi (saf): row asset_plan satırı, tasks kişinin meshy.json görevleri. Kişi model ve iskelet
## (rig) görevinden sonra oyuna girer (prepare_character.py); ilk bitmemiş görev söylenir.
static func pending_reason(lib: ClipLibrary, row: Dictionary, tasks: Dictionary) -> String:
	var base := str(row.get("variant_of", ""))
	if not base.is_empty():
		return "%s modelinin doku çeşidi (Retexture); %s gelince klipleriyle burada" % [lib.name_of(base), lib.name_of(base)]
	if not tasks.get("model") is Dictionary:
		return "Henüz Meshy'ye gönderilmedi"
	for stage in ["model", "rig"]:
		if not tasks.get(stage) is Dictionary:
			continue
		var status := str(tasks[stage].get("status", ""))
		if status == "SUCCEEDED":
			continue
		if status in ["FAILED", "CANCELED", "EXPIRED"]:
			return "Meshy %s görevi tamamlanmadı (%s); yeniden denenecek" % ["model" if stage == "model" else "iskelet", status]
		if stage == "model":
			return "Meshy kuyruğunda; gelince klipleriyle burada"
		return "Meshy modeli hazır, iskelet (rig) görevi %s; gelince klipleriyle burada" % ("sırada" if status == "PLANNED" else "sürüyor")
	if not tasks.get("rig") is Dictionary:
		return "Meshy modeli hazır, iskelet (rig) görevi sırada; gelince klipleriyle burada"
	return "Meshy'den indi; oyun kopyası (tools/prepare_character.py) bekleniyor"


## manifest'in sözleşmeye uyup uymadığı (saf): her nesnenin alanları sözleşmedeki gibi (tam, sırası aynı), türler ve
## değerler doğru, karakterlerin klipleri kütüphanenin klipleri. Sorunların listesi (boşsa uyar). Araç yazmadan önce,
## sınamalar yazılmış dosyayla denetler (JSON'dan okununca sayılar ondalıktır: tam sayı alanında tam değer aranır).
static func manifest_problems(manifest: Variant) -> PackedStringArray:
	var out: Array[String] = []
	if not manifest is Dictionary:
		return PackedStringArray(["kök bir nesne değil"])
	var m: Dictionary = manifest
	_check_fields(out, "kök", m, MANIFEST_FIELDS)
	if not str(m.get("rule", "")).begins_with("K"):
		out.append("rule: %s" % m.get("rule"))
	_check_credits(out, m.get("credits"))
	var carriers: Dictionary = m["carriers"] if m.get("carriers") is Dictionary else {}
	if not m.get("carriers") is Dictionary:
		out.append("carriers nesne değil")
	for id in carriers:
		if not carriers[id] is Dictionary:
			out.append("carriers[%s] nesne değil" % id)
			continue
		_check_fields(out, "carriers[%s]" % id, carriers[id], CARRIER_FIELDS)
		if str(carriers[id].get("tr", "")).is_empty():
			out.append("carriers[%s].tr boş" % id)
	var groups := {}
	for g in (m["groups"] if m.get("groups") is Array else []):
		if not g is Dictionary:
			out.append("groups: nesne olmayan öğe")
			continue
		var group := str(g.get("key", ""))
		_check_fields(out, "groups[%s]" % group, g, GROUP_FIELDS)
		if group.is_empty() or groups.has(group):
			out.append("groups: boş ya da yinelenen anahtar «%s»" % group)
		if str(g.get("tr", "")).is_empty() or not _is_whole(g.get("count")):
			out.append("groups[%s]: tr/count %s %s" % [group, g.get("tr"), g.get("count")])
		if not g.get("live") is bool:
			out.append("groups[%s].live bool değil" % group)
		groups[group] = 0
	if not m.get("groups") is Array:
		out.append("groups liste değil")
	var keys := {}
	for c in (m["clips"] if m.get("clips") is Array else []):
		if not c is Dictionary:
			out.append("clips: nesne olmayan öğe")
			continue
		var key := str(c.get("key", ""))
		_check_fields(out, "clips[%s]" % key, c, CLIP_FIELDS)
		if key.is_empty() or keys.has(key):
			out.append("clips: boş ya da yinelenen anahtar «%s»" % key)
		keys[key] = str(c.get("group"))
		if groups.has(str(c.get("group"))):
			groups[str(c.get("group"))] += 1
		else:
			out.append("clips[%s].group: %s öbeklerde yok" % [key, c.get("group")])
		if c.get("seat") != null and not SEATS.has(str(c.get("seat"))):
			out.append("clips[%s].seat: %s" % [key, c.get("seat")])
		_check_tags(out, key, c.get("tags"))
		if not KINDS.has(str(c.get("kind"))):
			out.append("clips[%s].kind: %s" % [key, c.get("kind")])
		if not c.get("loop") is bool:
			out.append("clips[%s].loop bool değil" % key)
		if c.get("seat_loop") != null and (not c.get("seat_loop") is bool or c.get("loop") == true):
			out.append("clips[%s].seat_loop: %s (yalnız bir kez oynayan klipte bool)" % [key, c.get("seat_loop")])
		if not (c.get("travel_m") is float or c.get("travel_m") is int) or float(c.get("travel_m", -1.0)) < 0.0:
			out.append("clips[%s].travel_m: %s" % [key, c.get("travel_m")])
		if c.get("meshy_action") != null and not _is_whole(c.get("meshy_action")):
			out.append("clips[%s].meshy_action: %s" % [key, c.get("meshy_action")])
		if c.get("prompt") != null and (not c.get("prompt") is String or str(c.get("prompt")).is_empty()):
			out.append("clips[%s].prompt: %s" % [key, c.get("prompt")])
		for p in (c["purchases"] if c.get("purchases") is Array else []):
			if not p is Dictionary or not (p.get("character") is String) or not _is_whole(p.get("credits")):
				out.append("clips[%s].purchases: bozuk öğe %s" % [key, p])
			else:
				_check_fields(out, "clips[%s].purchases" % key, p, PURCHASE_FIELDS)
				_check_raw_id(out, "clips[%s].purchases" % key, p.get("character"), carriers)
	if not m.get("clips") is Array:
		out.append("clips liste değil")
	for c in (m["clips"] if m.get("clips") is Array else []):
		if c is Dictionary:
			_check_derived(out, str(c.get("key", "")), c, keys)
	for g in (m["groups"] if m.get("groups") is Array else []):
		if g is Dictionary and _is_whole(g.get("count")) and int(g["count"]) != int(groups.get(str(g.get("key")), -1)):
			out.append("groups[%s].count %s, öbekte %s klip var" % [g.get("key"), g.get("count"), groups.get(str(g.get("key")))])
	for ch in (m["characters"] if m.get("characters") is Array else []):
		if not ch is Dictionary:
			out.append("characters: nesne olmayan öğe")
			continue
		var id := str(ch.get("id", ""))
		_check_fields(out, "characters[%s]" % id, ch, CHARACTER_FIELDS)
		if not GROUPS.has(str(ch.get("group"))):
			out.append("characters[%s].group: %s" % [id, ch.get("group")])
		if ch.get("body") != null and not BODIES.has(str(ch.get("body"))):
			out.append("characters[%s].body: %s" % [id, ch.get("body")])
		if str(ch.get("glb")) != OUT_DIR.path_join(id + ".glb") or not _is_whole(ch.get("bytes")):
			out.append("characters[%s]: glb/bytes %s %s" % [id, ch.get("glb"), ch.get("bytes")])
		_check_assigned(out, id, ch.get("assigned"), groups, keys)
		if str(ch.get("group")) == "player" and ch.get("assigned") is Dictionary and not (ch["assigned"] as Dictionary).is_empty():
			out.append("characters[%s].assigned: oyuncu karakteri çeşit almaz (K91)" % id)
		_check_scene_picks(out, id, ch.get("scene_picks"), keys)
		if not ch.get("clips") is Dictionary:
			out.append("characters[%s].clips nesne değil" % id)
			continue
		for key in ch["clips"]:
			var e: Variant = ch["clips"][key]
			if not keys.has(key):
				out.append("characters[%s]: kütüphanede olmayan klip %s" % [id, key])
			if not e is Dictionary:
				out.append("characters[%s].clips[%s] nesne değil" % [id, key])
				continue
			_check_fields(out, "characters[%s].clips[%s]" % [id, key], e, CHARACTER_CLIP_FIELDS)
			var source := str(e.get("source"))
			if not SOURCES.has(source):
				out.append("characters[%s].clips[%s].source: %s" % [id, key, source])
			if (source == "retarget") != (e.get("donor") is String and not str(e.get("donor")).is_empty()):
				out.append("characters[%s].clips[%s]: donor ile source uyuşmuyor (%s, %s)" % [id, key, source, e.get("donor")])
			_check_raw_id(out, "characters[%s].clips[%s].donor" % [id, key], e.get("donor"), carriers)
			if not (e.get("duration") is float or e.get("duration") is int) or not _is_whole(e.get("frames")):
				out.append("characters[%s].clips[%s]: duration/frames" % [id, key])
			if not e.get("loop") is bool or not e.get("game_role") is bool:
				out.append("characters[%s].clips[%s]: loop/game_role bool değil" % [id, key])
	for p in (m["pending"] if m.get("pending") is Array else []):
		if not p is Dictionary:
			out.append("pending: nesne olmayan öğe")
			continue
		_check_fields(out, "pending[%s]" % p.get("id"), p, PENDING_FIELDS)
		if not GROUPS.has(str(p.get("group"))):
			out.append("pending[%s].group: %s" % [p.get("id"), p.get("group")])
	return PackedStringArray(out)


static func _check_credits(out: Array[String], credits: Variant) -> void:
	if not credits is Dictionary:
		out.append("credits nesne değil")
		return
	_check_fields(out, "credits", credits, CREDIT_FIELDS)
	for field in CREDIT_FIELDS:
		if field != "motions" and not _is_whole(credits.get(field)):
			out.append("credits.%s tam sayı değil: %s" % [field, credits.get(field)])
	var motions: Variant = credits.get("motions")
	if not motions is Dictionary:
		out.append("credits.motions nesne değil")
		return
	_check_fields(out, "credits.motions", motions, MOTION_CREDIT_FIELDS)
	for field in MOTION_CREDIT_FIELDS:
		if not _is_whole(motions.get(field)):
			out.append("credits.motions.%s tam sayı değil: %s" % [field, motions.get(field)])
	if _is_whole(credits.get("total")) and _is_whole(credits.get("spent_on_actions")) and _is_whole(motions.get("credits")) \
			and int(credits["total"]) != int(credits["spent_on_actions"]) + int(motions["credits"]):
		out.append("credits.total %s, mağaza %s + metinden %s değil" % [credits["total"], credits["spent_on_actions"], motions["credits"]])


static func _check_tags(out: Array[String], key: String, tags: Variant) -> void:
	if not tags is Dictionary:
		out.append("clips[%s].tags nesne değil" % key)
		return
	_check_fields(out, "clips[%s].tags" % key, tags, TAG_FIELDS)
	for field in TAG_FIELDS:
		if not tags.get(field) is Array:
			out.append("clips[%s].tags.%s liste değil" % [key, field])


## Türetilmiş klibin kaynağı: kind derived ise derived nesnedir ve from kütüphanede, değilse null. keys: {anahtar: öbek}.
static func _check_derived(out: Array[String], key: String, clip: Dictionary, keys: Dictionary) -> void:
	var derived: Variant = clip.get("derived")
	if clip.get("kind") != ClipLibrary.KIND_DERIVED:
		if derived != null:
			out.append("clips[%s].derived: türetilmiş olmayan klipte %s" % [key, derived])
		return
	if not derived is Dictionary:
		out.append("clips[%s].derived nesne değil" % key)
		return
	_check_fields(out, "clips[%s].derived" % key, derived, DERIVED_FIELDS)
	if not keys.has(str(derived.get("from"))):
		out.append("clips[%s].derived.from kütüphanede yok: %s" % [key, derived.get("from")])


## Kişinin ataması: her öbek öbeklerde, her klip kütüphanede ve o öbekte; ara hareketler liste, ötekiler tek anahtar.
static func _check_assigned(out: Array[String], id: String, assigned: Variant, groups: Dictionary, keys: Dictionary) -> void:
	if not assigned is Dictionary:
		out.append("characters[%s].assigned nesne değil" % id)
		return
	for group in assigned:
		if not groups.has(group):
			out.append("characters[%s].assigned: öbeklerde olmayan %s" % [id, group])
		var value: Variant = assigned[group]
		if (group == ClipVariety.FIDGET_GROUP) != (value is Array):
			out.append("characters[%s].assigned[%s]: %s" % [id, group, "ara hareketler liste olmalı" if group == ClipVariety.FIDGET_GROUP else "tek anahtar olmalı"])
		for key in (value if value is Array else [value]):
			if not keys.has(str(key)) or keys[str(key)] != group:
				out.append("characters[%s].assigned[%s]: %s o öbeğin klibi değil" % [id, group, key])


## Taşıyıcı kimliği (alt çizgiyle başlar) carriers'ta yazılı olmalı: sayfa onun adını oradan gösterir.
static func _check_scene_picks(out: Array[String], id: String, picks: Variant, keys: Dictionary) -> void:
	if not picks is Dictionary:
		out.append("characters[%s].scene_picks nesne değil" % id)
		return
	for scene in picks:
		if not SCENES.has(str(scene)) or not picks[scene] is Dictionary:
			out.append("characters[%s].scene_picks: bilinmeyen sahne ya da bozuk satır %s" % [id, scene])
			continue
		for group in picks[scene]:
			var key: Variant = picks[scene][group]
			if keys.get(str(key)) != group:
				out.append("characters[%s].scene_picks[%s][%s]: %s o öbeğin klibi değil" % [id, scene, group, key])


static func _check_raw_id(out: Array[String], where: String, id: Variant, carriers: Dictionary) -> void:
	if id is String and (id as String).begins_with("_") and not carriers.has(id):
		out.append("%s: %s carriers'ta yok" % [where, id])


## Nesnenin alanları tam olarak fields mi (aynı sırayla)? Değilse eksikler ve fazlalar out'a yazılır.
static func _check_fields(out: Array[String], where: String, obj: Dictionary, fields: Array[String]) -> void:
	var have := PackedStringArray()
	for k in obj:
		have.append(str(k))
	if have == PackedStringArray(fields):
		return
	var missing := fields.filter(func(f: String) -> bool: return not have.has(f))
	var extra := Array(have).filter(func(f: String) -> bool: return not fields.has(f))
	out.append("%s alanları: eksik %s, sözleşmede olmayan %s%s" % [where, missing, extra, ", sıra farklı" if missing.is_empty() and extra.is_empty() else ""])


static func _is_whole(v: Variant) -> bool:
	return v is int or (v is float and is_finite(v) and v == floorf(v))


## Oyunun bağışçı tablosuyla (asset_plan.json clip_donors; character_fit_tool.gd DONORS ve meta.json clip_donors)
## kütüphanenin bedene göre bağışçıları arasındaki ayrılıklar (K90: ikisi aynı tutulur). Oyun bugün tabloyu oynatır;
## ayrılık konsola uyarı olarak yazılır. Bir rolün kütüphanede birden çok klibi varsa (bekleme) bağışçılarından biri yeter.
static func donor_conflicts(lib: ClipLibrary) -> PackedStringArray:
	var out := PackedStringArray()
	var data: Variant = ClipLibrary.read_json(ClipLibrary.ASSET_PLAN_PATH)
	if not data is Dictionary:
		return out
	for row in (data as Dictionary).get("assets", []):
		if not row is Dictionary or str(row.get("kind", "")) != "character":
			continue
		var id := str(row.get("id", ""))
		var body := lib.body_of(id)
		var table := {}
		if row.get("clip_donors") is Dictionary:
			table.merge(row["clip_donors"])
		table.merge(ClipLibrary.FIT_TOOL.donors_of(id), true)
		for role in table:
			var allowed := []
			for key in lib.keys_for_role(str(role)):
				var donors: Variant = lib.clip(key).get("donors")
				var d := str((donors as Dictionary).get(body, "")) if donors is Dictionary else ""
				if not d.is_empty() and not allowed.has(d):
					allowed.append(d)
			if not allowed.is_empty() and not allowed.has(str(table[role])):
				out.append("%s (%s): oyunun %s bağışçısı %s, kütüphanede %s" % [id, body, role, table[role], "/".join(allowed)])
	return out


## Afiş görseli (depo köküne göre): kavram görseli, yoksa ansiklopedi portresi, o da yoksa null.
static func poster(lib: ClipLibrary, id: String) -> Variant:
	var repo := repo_root()
	var concept := "game/assets/_concepts/%s.png" % id
	if FileAccess.file_exists(repo.path_join(concept)):
		return concept
	var portrait := "docs/assets/encyclopedia/%s/portrait.png" % _encyclopedia_id(lib, id)
	if FileAccess.file_exists(repo.path_join(portrait)):
		return portrait
	return null


## Kişinin ansiklopedi kimliği: asset_plan encyclopedia_id, meta.json encyclopedia_images klasörü ya da id'nin
## tireli yazımı.
static func _encyclopedia_id(lib: ClipLibrary, id: String) -> String:
	var row := lib.plan_row(id)
	if row.has("encyclopedia_id"):
		return str(row["encyclopedia_id"])
	var images := str(StandIn.meta(id).get("encyclopedia_images", ""))
	if not images.is_empty():
		return images.trim_suffix("/").get_file()
	return id.replace("_", "-")


## Depo kökü (game/ klasörünün üstü).
static func repo_root() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()


## JSON'dan okunan değerde tam sayı olan ondalıkları tam sayıya çevirir (yeniden yazılınca "12.0" görünmesin).
static func _integers(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for k in value:
			out[k] = _integers(value[k])
		return out
	if value is Array:
		var items := []
		for item in value:
			items.append(_integers(item))
		return items
	if value is float and is_finite(value) and value == floorf(value) and absf(value) < 9.0e15:
		return int(value)
	return value
