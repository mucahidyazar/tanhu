class_name PrologueMyth
extends CineScene
## Önsöz'ün mit sineması (Yol Haritası myth-panels ve myth-audio; story.md §3 satır 1–6, godot.md §3.6, K68, K93):
## scenes/cine/prologue_myth.tscn'in kökü. CineHost onu kendi dünyası olan bir SubViewport'ta (overlay) gösterir, ana 3B
## çizilmez. Görüntü iki kiplidir:
##   - Video (K93; video_path oynatılabiliyorsa): motion-studio'da işlenen parşömen videosu aynı SubViewport'un 2B'sinde oynar
##     (CineVideo). 3B yoktur: keçe panolar kurulmaz (çocuklarının _ready'sinden önce çıkar), SubViewport'un 3B'si kapanır, katman
##     CineVideo.LAYER'dır (boyalı süzgecin üstünde, perdenin ve altyazının altında). Altyazı videonun koyu bandındadır. Video sinema
##     saatini izler (_process): --cine-at ve hız ona da işler. Çekim ve olaylar sürer: sesler ve kancalar çizelgededir.
##   - Keçe yedeği (dosya yoksa ya da CineVideo.enabled kapalıysa): katman 0, boyalı süzgeç (katman 1) açık. Altı keçe pano
##     uzun bir keçe şeritte yan yana durur (x = sıra × 6 m); kamera bir panodan ötekine paralaksla geçer. Sahnenin kendi
##     WorldEnvironment'ı (sis yok, sıcak ton) ve iki ışığı vardır.
## İki kipte de dünyaya, menü kamerasına ve kampa dokunmaz: restore() yalnız kendini durdurur, dizi bu segmentte biterse (Esc)
## açtığı ortam döngülerini de susturur. Son 1,5 sn'de CineHost.crossfade (doğumun crossfade_in'i) overlay'i söndürür, altta 7a'nın
## gerçek közü görünür (süzgeçli); video o sırada akar, segment sonundan 1 sn uzundur.
##
## Çekimler (data/cine/prologue_myth.json): panel_1 … panel_6. Keçede her çekim AnimationPlayer'ın aynı adlı canlandırmasını
## oynatır: kamera önceki panodan 1,6 sn'de gelir (geçiş), sonra panoda kayar; panonun anim_time'ı 0'dan panonun
## gerçek süresine yürür, katmanların kancaları ona göre çalışır. Canlandırmalar setup'ta çizelgeden kurulur: satır
## gerçek dosyasıyla uzayınca pano da, içindeki işaretler de (warp) aynı payla kayar.
## Sahnenin olayları: bed {bed, db, dur} ortam döngüsü (AudioManager.set_ambience_layer; ileri sarmada geçişsiz),
## cue {sfx, db, pitch} efekt (play_sfx; ileri sarmada çalmaz), ember (son 1,5 sn: közün parlaması başlar; keçede ember_node
## parlar, videoda köz işlenmiştir ve yeri MYTH_EMBER_SCREEN'dir; doğumun ilk karesi gerçek közü oraya oturtur).

const SEGMENT_PATH := "res://data/cine/prologue_myth.json"
const PANEL_COUNT := 6
const PANEL_PREFIX := "panel_"
## Kameranın panolar arası geçişi (sn) ve varsayılan uzaklığı (m).
const TRANSIT := 1.6
const CAMERA_Z := 5.6
## Kamera yolunun anahtar aralığı (sn).
const KEY_STEP := 0.2
## Ücretsiz uzak kaz kaydı (geese_distant: Wikimedia Commons, kamu malı): goose_honk'un kaynağı (K89, E7.5).
const GOOSE_FREE_ASSET := "geese_distant"
## Mit videosu (K93; segmentin gerçek süresi + 1,0 sn). Gerçek dosyayı ana oturum motion-studio'dan kopyalar.
const VIDEO_PATH := "res://assets/cine/video/myth.ogv"
## Video kipinde sahneden çıkan keçe düğümleri (çocuklarının _ready'si çalışmadan: hiçbir şey kurulmaz).
const FELT_NODES: Array[NodePath] = [^"Strip", ^"KeyLight", ^"FillLight", ^"WorldEnvironment"]
## Videodaki közün yeri (0..1): motion-studio src/projects/tanhu/myth/time.ts EMBER_X, EMBER_Y (960, 640; 1920 × 1080).
const MYTH_EMBER_SCREEN := Vector2(960.0 / 1920.0, 640.0 / 1080.0)

## Oynatılacak video (sınama fixture verir).
static var video_path := VIDEO_PATH

@onready var camera: Camera3D = $Camera
@onready var player: AnimationPlayer = $AnimationPlayer
## Keçe şeridi (video kipinde null).
@onready var strip: Node3D = get_node_or_null(^"Strip")

## Video kipinin oynatıcısı (keçe yedeğinde null).
var video: CineVideo
## Son çekim (panel_N; iki kipte de).
var current_shot := ""
## Son panonun keçe közü (CineHost'un gerçek köze çakışması için).
var ember_node: MeshInstance3D
## Panoların segment içi gerçek başlangıcı ve süresi (sn) ve yazıldığı (tahmini) süresi.
var panel_starts := PackedFloat64Array()
var panel_lengths := PackedFloat64Array()
## Közün parlaması başladı mı (ember olayı)?
var ember_started := false
## Sahnenin kendi oynattığı sesler (ileri sarmada boş kalır; sınama okur).
var sounds: Array = []

var _built := false
## Sahnenin açtığı ortam döngüleri: dizi bu segmentte biterse (atlama, durdurma) restore onları susturur.
var _touched_beds: Dictionary = {}


## Kök ağaca girerken çocukların _ready'si henüz çalışmamıştır: video kipinde keçe düğümleri burada çıkar, pano kurulmaz.
func _enter_tree() -> void:
	if video == null and CineVideo.usable(video_path):
		_use_video()


func _ready() -> void:
	set_process(video != null)
	if video == null:
		_build_strip()


## Segment başlarken. Video kipinde katman ve altyazı yerine konur; keçede panoların zamanı ve canlandırmalar çizelgeden kurulur,
## kamera ilk panoya konur.
func setup(p_ctx: Dictionary) -> void:
	super.setup(p_ctx)
	if video:
		_enter_video_view()
		return
	build_timing()
	var h := host()
	if h:
		player.speed_scale = maxf(h.speed, 0.001)


## Konak yokken (önizleme, sınama) de kurulabilir: zamanlar tahmini sürelerle.
func build_timing() -> void:
	var real := _segment_times(_real_timeline(), _segment_id())
	var est_seconds := func(line_id: String) -> float: return VoLines.est(line_id)
	var est := _segment_times(CineTimeline.from_path(_segment_file(), est_seconds), "myth")
	panel_starts = real["starts"]
	panel_lengths = real["lengths"]
	for i in PANEL_COUNT:
		var panel := panel_node(i + 1)
		if panel == null:
			continue
		panel.warp = _warp(panel, real, est, i)
		panel.anim_time = 0.0
	_build_animations()
	_place_camera(0, 0.0)
	_built = true


## Video kipinde sinema saatini izler (konak yoksa ya da atlanırken saat anlamsızdır: atlamada saat sona sıçrar, perde inerken
## video sarılmaz).
func _process(_delta: float) -> void:
	var h := host()
	if h == null or h.is_skipping():
		return
	video.speed = h.speed
	video.follow(h.time() - _segment_start())


func on_shot(shot_name: String, ev: Dictionary) -> void:
	if video:
		if shot_name.begins_with(PANEL_PREFIX):
			current_shot = shot_name
		return
	if not shot_name.begins_with(PANEL_PREFIX) or not player.has_animation(shot_name):
		return
	current_shot = shot_name
	if not _built:
		build_timing()
	player.play(shot_name)
	player.seek(elapsed(ev), true)


func on_event(ev: Dictionary) -> void:
	match str(ev.get("type", "")):
		"bed":
			_touched_beds[str(ev.get("bed", ""))] = true
			_audio(&"set_ambience_layer", [str(ev.get("bed", "")), float(ev.get("db", -80.0)),
				0.0 if seeking else float(ev.get("dur", 0.0))])
		"cue":
			if not seeking:
				var opts := {"db": float(ev.get("db", 0.0)), "pitch": float(ev.get("pitch", 1.0))}
				sounds.append([str(ev.get("sfx", "")), opts])
				_audio(&"play_sfx", [str(ev.get("sfx", "")), opts])
		"ember":
			ember_started = true


func restore() -> void:
	if is_instance_valid(player):
		player.stop()
	if video:
		# Süreç de durur: sahne bu karenin sonunda silinir, follow videoyu yeniden başlatıp sarmasın.
		set_process(false)
		video.stop()
		_set_subtitle_band(false)
	sounds.clear()
	# Dizi burada bitiyorsa (Esc, durdurma) rüzgâr ve su menüye taşmasın; doğum sürüyorsa döngüleri o devralır.
	if _sequence_ends():
		for bed: String in _touched_beds:
			_audio(&"set_ambience_layer", [bed, -80.0, 0.5])
	_touched_beds.clear()


func is_ready() -> bool:
	return true


## n. pano (1–6; yoksa ya da video kipinde null).
func panel_node(n: int) -> FeltPanel:
	return strip.get_node_or_null(NodePath("Panel%d" % n)) as FeltPanel if strip else null


func panel_nodes() -> Array[FeltPanel]:
	var out: Array[FeltPanel] = []
	for i in PANEL_COUNT:
		var p := panel_node(i + 1)
		if p:
			out.append(p)
	return out


## Közün ekrandaki yeri (0..1; sahnenin görünümünde): videoda sabittir (bantlar hesaba katılır), keçede son panonun közü.
func ember_screen_position() -> Vector2:
	if video:
		return CineVideo.screen_point(MYTH_EMBER_SCREEN, get_viewport().get_visible_rect().size)
	if ember_node == null or not is_instance_valid(camera):
		return Vector2(0.5, 0.5)
	var size := camera.get_viewport().get_visible_rect().size
	var at := camera.unproject_position(ember_node.global_position)
	return Vector2(at.x / maxf(size.x, 1.0), at.y / maxf(size.y, 1.0))


# --- Video --------------------------------------------------------------------------------------------

## Video kipi: oynatıcı kurulur ve açılır; açılırsa keçe düğümleri sahneden çıkar. Açılamazsa keçe yedeği sürer.
func _use_video() -> void:
	var made := CineVideo.new()
	made.name = "Video"
	add_child(made)
	if not made.open(video_path):
		remove_child(made)
		made.free()
		return
	video = made
	for path: NodePath in FELT_NODES:
		var node := get_node_or_null(path)
		if node:
			node.free()


## Konak varsa: overlay'in katmanı videonun katmanına geçer, SubViewport'un 3B'si kapanır, altyazı koyu banda iner.
func _enter_video_view() -> void:
	var h := host()
	if h:
		h.use_video_layer(_segment_id())
	_set_subtitle_band(true)


func _set_subtitle_band(on: bool) -> void:
	var h := host()
	if h and h.subtitles:
		h.subtitles.video_band = on


# --- Kurulum -------------------------------------------------------------------------------------------

## Uzun keçe şerit (bordürlü, panolar arası dikişli ayraç) ve panoların konumu.
func _build_strip() -> void:
	var data := FeltPanel.data()
	var spacing := float(data.get("spacing", 6.0))
	var info: Dictionary = data["strip"] if data.get("strip") is Dictionary else {}
	var band := strip.get_node_or_null(^"Band") as MeshInstance3D
	if band:
		var w := float(info.get("w", 38.0))
		var h := float(info.get("h", 3.6))
		band.mesh = strip_mesh(w, h, spacing * (PANEL_COUNT - 1) * 0.5)
		band.material_override = FeltPanel.felt_material()
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		band.set_instance_shader_parameter(&"shape_color", FeltPanel._color(info.get("color"), Color(0.16, 0.11, 0.08)))
		band.set_instance_shader_parameter(&"pattern", 1)
		band.set_instance_shader_parameter(&"seed", 3.0)
		if FeltPanel.uses_free_texture():
			band.set_meta(&"free_asset", FeltPanel.FREE_ASSET)
	for i in PANEL_COUNT:
		var panel := panel_node(i + 1)
		if panel:
			panel.position = Vector3(spacing * i, 0.0, 0.0)
			if FeltPanel.uses_free_texture():
				panel.set_meta(&"free_asset", FeltPanel.FREE_ASSET)
	var ember_panel := panel_node(PANEL_COUNT)
	if ember_panel:
		ember_node = ember_panel.layer_node(str(ember_panel.panel.get("ember", "ember"))) as MeshInstance3D
	var goose := get_node_or_null(^"GooseHonk")
	if goose:
		goose.set_meta(&"free_asset", GOOSE_FREE_ASSET)


## Şeridin ağı: tek dörtgen; UV ve UV2 metredir (x şerit boyunca, y yukarı; panonun merkezi x = 0). UV.y 1: dikiş yok.
static func strip_mesh(w: float, h: float, center_x: float) -> ArrayMesh:
	var x0 := center_x - w * 0.5
	var x1 := center_x + w * 0.5
	var corners := [Vector2(x0, -h * 0.5), Vector2(x1, -h * 0.5), Vector2(x1, h * 0.5), Vector2(x0, h * 0.5)]
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts := PackedVector3Array()
	var uv2s := PackedVector2Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	for c: Vector2 in corners:
		verts.append(Vector3(c.x, c.y, 0.0))
		uv2s.append(c)
		uvs.append(Vector2(c.x, 1.0))
		normals.append(Vector3.BACK)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	# Ön yüz kameraya (+z) bakar: Godot'da saat yönünde.
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Panoların canlandırmaları: kamera (geçiş + panoda kayış) ve anim_time.
func _build_animations() -> void:
	if player.has_animation_library(&""):
		player.remove_animation_library(&"")
	var lib := AnimationLibrary.new()
	var prev_end := Vector3.ZERO
	for i in PANEL_COUNT:
		var panel := panel_node(i + 1)
		var length := maxf(panel_lengths[i] if i < panel_lengths.size() else 10.0, 0.1)
		var anim := Animation.new()
		anim.length = length
		var cam := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(cam, NodePath("Camera:position"))
		# Doğrusal ara değer, yumuşaklık sık anahtarlardadır: kübik ara değer seyrek ve düzensiz aralıklı anahtarlarda
		# (1,6 sn'de 6 m geçiş, sonra yavaş kayış) yolu aşırı salıyordu.
		anim.track_set_interpolation_type(cam, Animation.INTERPOLATION_LINEAR)
		var keys := _camera_keys(panel, i, length)
		# Geçiş: önceki panonun son konumundan TRANSIT'te bu panoya; geçişin içine düşen anahtar geçişin sonuna kayar.
		var transit := minf(TRANSIT, length * 0.5) if i > 0 else 0.0
		var path: Array = []
		if i > 0:
			path.append([0.0, prev_end])
		for k: Array in keys:
			path.append([clampf(maxf(float(k[0]), transit), 0.0, length), k[1]])
		_insert_eased(anim, cam, path)
		prev_end = (keys[keys.size() - 1] as Array)[1]
		var clock := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(clock, NodePath("Strip/Panel%d:anim_time" % (i + 1)))
		anim.track_set_interpolation_type(clock, Animation.INTERPOLATION_LINEAR)
		anim.value_track_set_update_mode(clock, Animation.UPDATE_CONTINUOUS)
		anim.track_insert_key(clock, 0.0, 0.0)
		anim.track_insert_key(clock, length, length)
		lib.add_animation(StringName(PANEL_PREFIX + str(i + 1)), anim)
	player.add_animation_library(&"", lib)


## Yol noktaları ([[t, Vector3], ...]) arasında yumuşak (smoothstep) geçiş: her aralığa KEY_STEP'te bir anahtar.
static func _insert_eased(anim: Animation, track: int, path: Array) -> void:
	for j in path.size():
		var a: Array = path[j]
		anim.track_insert_key(track, float(a[0]), a[1])
		if j + 1 >= path.size():
			continue
		var b: Array = path[j + 1]
		var span := float(b[0]) - float(a[0])
		var steps := int(ceil(span / KEY_STEP))
		for k in range(1, steps):
			var u := float(k) / float(steps)
			var w := u * u * (3.0 - 2.0 * u)
			anim.track_insert_key(track, float(a[0]) + span * u, (a[1] as Vector3).lerp(b[1], w))


## Panonun kamera anahtarları: [[gerçek t, dünya konumu], ...] (yazılan zamanlar warp ile gerçeğe çevrilir).
func _camera_keys(panel: FeltPanel, index: int, length: float) -> Array:
	var spacing := float(FeltPanel.data().get("spacing", 6.0))
	var raw: Array = []
	if panel and panel.panel.get("camera") is Dictionary and (panel.panel["camera"] as Dictionary).get("keys") is Array:
		raw = panel.panel["camera"]["keys"]
	if raw.is_empty():
		raw = [[0.0, -0.2, 0.0, CAMERA_Z], [length, 0.2, 0.0, CAMERA_Z - 0.2]]
	var out: Array = []
	for k: Variant in raw:
		var a: Array = k
		var t := panel.real_time(float(a[0])) if panel else float(a[0])
		out.append([clampf(t, 0.0, length), Vector3(spacing * index + float(a[1]), float(a[2]), float(a[3]))])
	return out


func _place_camera(index: int, t: float) -> void:
	var anim_name := StringName(PANEL_PREFIX + str(index + 1))
	if player.has_animation(anim_name):
		player.play(anim_name)
		player.seek(t, true)
		player.pause()


# --- Zaman -----------------------------------------------------------------------------------------

## Panoların ve satırların segment içi zamanı: {starts, lengths, lines (id → [başlangıç, bitiş]), total}.
func _segment_times(timeline: CineTimeline, seg_id: String) -> Dictionary:
	var starts := PackedFloat64Array()
	var lengths := PackedFloat64Array()
	var lines := {}
	var total := 0.0
	if timeline and timeline.ok():
		var seg := timeline.segment(seg_id)
		if seg.is_empty():
			seg = timeline.segments[0]
			seg_id = str(seg["id"])
		var start := float(seg["start"])
		total = float(seg["length"])
		for i in PANEL_COUNT:
			var at := timeline.time_of("%s:%s%d" % [seg_id, PANEL_PREFIX, i + 1])
			starts.append(at - start if not is_nan(at) else 0.0)
		for ev in timeline.line_events():
			if str(ev["segment"]) == seg_id:
				lines[str(ev["line"])] = [float(ev["t"]) - start, float(ev["end"]) - start]
	for i in PANEL_COUNT:
		var next := starts[i + 1] if i + 1 < starts.size() else total
		lengths.append(maxf(next - (starts[i] if i < starts.size() else 0.0), 0.0))
	return {"starts": starts, "lengths": lengths, "lines": lines, "total": total}


## Panonun warp'ı: [[gerçek, yazılan], ...] panonun başı, satırlarının başı ve sonu, panonun sonu.
func _warp(panel: FeltPanel, real: Dictionary, est: Dictionary, i: int) -> Array:
	var out: Array = [[0.0, 0.0]]
	var rs: float = (real["starts"] as PackedFloat64Array)[i] if i < (real["starts"] as PackedFloat64Array).size() else 0.0
	var es: float = (est["starts"] as PackedFloat64Array)[i] if i < (est["starts"] as PackedFloat64Array).size() else 0.0
	var line_ids: Variant = panel.panel.get("lines", [])
	for line_id: Variant in (line_ids if line_ids is Array else []):
		var r: Array = (real["lines"] as Dictionary).get(str(line_id), [])
		var e: Array = (est["lines"] as Dictionary).get(str(line_id), [])
		if r.is_empty() or e.is_empty():
			continue
		out.append([float(r[0]) - rs, float(e[0]) - es])
		out.append([float(r[1]) - rs, float(e[1]) - es])
	var rl := (real["lengths"] as PackedFloat64Array)[i] if i < (real["lengths"] as PackedFloat64Array).size() else 0.0
	var el := (est["lengths"] as PackedFloat64Array)[i] if i < (est["lengths"] as PackedFloat64Array).size() else 0.0
	out.append([rl, el])
	return out


## Konağın çizelgesi (yoksa segment dosyası gerçek sürelerle).
func _real_timeline() -> CineTimeline:
	var h := host()
	if h and h.timeline():
		return h.timeline()
	return CineTimeline.from_path(_segment_file())


func _segment_id() -> String:
	var seg: Variant = ctx.get("segment")
	return str((seg as Dictionary).get("id", "myth")) if seg is Dictionary else "myth"


## Segmentin dizideki başlangıcı (sn).
func _segment_start() -> float:
	var seg: Variant = ctx.get("segment")
	return float((seg as Dictionary).get("start", 0.0)) if seg is Dictionary else 0.0


func _segment_file() -> String:
	var seg: Variant = ctx.get("segment")
	var file := str((seg as Dictionary).get("file", "")) if seg is Dictionary else ""
	if file.is_empty() and host() and host().timeline():
		file = host().timeline().source
	return file if not file.is_empty() else SEGMENT_PATH


func _audio(method: StringName, args: Array) -> void:
	var audio: Variant = ctx.get("audio")
	if audio is CineAudio:
		(audio as CineAudio).call_target(method, args)


## Dizi bu segmentle bitiyor mu (atlama, durdurma ya da son segment)? PrologueCamp ve PrologueBirth'ün kuralı.
func _sequence_ends() -> bool:
	var h := host()
	if h == null or h.is_skipping() or not h.is_playing() or h.runner == null or h.runner.done:
		return true
	var timeline := h.timeline()
	var seg: Dictionary = ctx.get("segment", {})
	if timeline == null or seg.is_empty():
		return true
	return int(seg.get("index", 0)) >= timeline.segments.size() - 1
