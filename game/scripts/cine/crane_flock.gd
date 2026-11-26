class_name CraneFlock
extends Node3D
## Güneye geçen turnalar (story.md §3 satır 7d–7e, §4: «Uzakta güneye turnalar geçer»; audio.md §4 crane_call): 8–12
## kuşluk V düzeni, gökte hareketli ses kaynağı. Düğüm sürünün merkezidir; progress (0..1) onu start_point'ten end_point'e
## yürütür (sahnenin AnimationPlayer'ı sürer, ileri sarmada da doğru yer), kuşlar yönü izler. Kanatlar ağır ve derin
## çırpar (turna ≈2 Hz), her kuşun evresi kayıktır.
## Ses: iki AudioStreamPlayer3D (Call ve CallAlt) sürüyle birlikte gökte yürür, ters uzaklıkla kısılır; crane_call'un
## çeşitlerini (ücretsiz kayıtlar crane_call_2 ve crane_call_1, Wikimedia Commons, CC0) sırayla, arayla çalar. Yollar
## kimlikten kurulur (AudioManager.sfx_variants; kodda ses yolu yazılmaz). Her ses düğümü free_asset meta verisini taşır.
## Kuşlar kodla çizilir (gövde, uzun boyun, geride sarkan bacaklar, iki kanat; paylaşılan ağ ve malzeme). ground_shadows açıkken her
## kuşun zeminde biçimli gölge izi vardır (Decal; doğumun 7e'si, K98: V yukarıdan geçer, gölgesi zeminde seçilir): iz kuştan ışığın
## gidiş yönünde (shadow_dir) ground_y düzlemine iner, kanat çırptıkça daralır. Yönlü ışığın gölgesi bu uzaklıkta ince kanatları
## noktalara bölüyordu. call_peak_db çağrının en yüksek düzeyidir (AudioStreamPlayer3D.max_db): sürü dinleyicinin yakınından geçse de
## çağrı bu düzeyi aşmaz.

## Ses kimliği ve düğümlerin ücretsiz varlıkları (sfx_variants sırasıyla: crane_call, crane_call_v1).
const SOUND_ID := &"crane_call"
const CALL_ASSETS: Array[String] = ["crane_call_2", "crane_call_1"]
const BODY_COLOR := Color(0.36, 0.37, 0.4)
const WING_COLOR := Color(0.3, 0.31, 0.34)
const TIP_COLOR := Color(0.08, 0.08, 0.1)

## Kuş sayısı (8–12).
@export_range(8, 12) var count := 10:
	set(value):
		count = clampi(value, 8, 12)
		if is_inside_tree():
			_build()
## V'nin kolları arasında kuşların aralığı (m) ve kolun yarı açısı (derece).
@export var spacing := 2.6
@export var arm_angle_deg := 34.0
## Kanat açıklığı (m; turna ≈2,2 m) ve kuşların ölçeği (yukarıdan, yakından geçerken kuşlar iri görünmesin diye küçültülebilir).
@export var wing_span := 2.2
@export var bird_scale := 1.0
## Kanat çırpışı (Hz) ve genliği (derece).
@export var flap_hz := 1.9
@export var flap_deg := 32.0
## Uçuş yolu (dünya) ve ilerleme.
@export var start_point := Vector3(0.0, 60.0, -200.0)
@export var end_point := Vector3(0.0, 60.0, 200.0)
@export_range(0.0, 1.0, 0.0001) var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		_place()
## Çağrılar arası süre (sn), sesin düzeyi, uzaklıkla kısılmanın birim uzaklığı (m; AudioStreamPlayer3D.unit_size) ve en yüksek düzey
## (dB; yakından geçerken).
@export var call_gap := Vector2(2.4, 4.2)
@export var call_db := 2.0
@export var call_unit_size := 60.0:
	set(value):
		call_unit_size = value
		for p in calls:
			if is_instance_valid(p):
				p.unit_size = value
@export var call_peak_db := 3.0:
	set(value):
		call_peak_db = value
		for p in calls:
			if is_instance_valid(p):
				p.max_db = value
## Zeminde gölge izi olsun mu, ışığın gidiş yönü (birim; aşağı bakmalı), izin düştüğü zemin yüksekliği (m) ve izin koyuluğu.
@export var ground_shadows := false:
	set(value):
		ground_shadows = value
		if is_inside_tree():
			_build_shadows()
			_place()
@export var shadow_dir := Vector3(-0.97, -0.26, -0.04)
@export var ground_y := 0.0
@export_range(0.0, 1.0) var shadow_alpha := 0.6
## Ses çalsın mı (ileri sarmada ve sınamada kapalı).
var sounding := false

var birds: Array[Node3D] = []
var calls: Array[AudioStreamPlayer3D] = []
## Kuşların zemindeki gölge izleri (ground_shadows; kuşlarla aynı sırada).
var shadows: Array[Decal] = []
## Çalınan çağrılar (sınama okur): [[sn, düğüm adı], ...].
var played: Array = []

var _time := 0.0
var _next_call := 0.0
var _call_index := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2351
	_build()
	_place()


func _process(delta: float) -> void:
	_time += delta
	for i in birds.size():
		var bird := birds[i]
		var flap := sin(TAU * flap_hz * _time + float(i) * 0.9) * deg_to_rad(flap_deg)
		for side in [-1.0, 1.0]:
			var wing := bird.get_node_or_null(NodePath("Wing%s" % ("L" if side < 0.0 else "R"))) as Node3D
			if wing:
				wing.rotation.z = side * flap
		if i < shadows.size():
			shadows[i].size.x = wing_span * bird_scale * maxf(cos(flap), 0.35)
	if sounding and visible:
		_next_call -= delta
		if _next_call <= 0.0:
			play_call()
			_next_call = _rng.randf_range(call_gap.x, call_gap.y)


## Uçuşun yönü (birim; turnalar güneye geçer: z artar).
func heading() -> Vector3:
	var d := end_point - start_point
	return d.normalized() if d.length_squared() > 1e-6 else Vector3.BACK


## Sesi açar ya da kapatır. immediate: ilk çağrı hemen (değilse çağrı aralığı kadar sonra; ileri sarmada ses çalınmaz,
## yalnız durum kurulur).
func set_sounding(on: bool, immediate: bool = true) -> void:
	sounding = on
	if on:
		_next_call = 0.0 if immediate else _rng.randf_range(call_gap.x, call_gap.y)
	else:
		for p in calls:
			p.stop()


## Bir çağrı: sırayla Call ve CallAlt (iki ücretsiz kayıt). Akışı yoksa yalnız kayda geçer.
func play_call() -> void:
	if calls.is_empty():
		return
	var player := calls[_call_index % calls.size()]
	_call_index += 1
	played.append([_time, str(player.name)])
	if player.stream:
		player.pitch_scale = _rng.randf_range(0.96, 1.04)
		player.play()


## V düzenindeki yerler (saf): öncü 0'da; tekler sola, çiftler sağa; z geriye (−heading), uzayan kollar.
static func formation(n: int, spacing_m: float, half_angle_deg: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var a := deg_to_rad(half_angle_deg)
	for i in n:
		if i == 0:
			out.append(Vector3.ZERO)
			continue
		var k := (i + 1) / 2
		var side := -1.0 if i % 2 == 1 else 1.0
		out.append(Vector3(side * sin(a) * spacing_m * k, -0.15 * k, -cos(a) * spacing_m * k))
	return out


func _place() -> void:
	if not is_inside_tree():
		return
	global_position = start_point.lerp(end_point, progress)
	var h := heading()
	if absf(h.dot(Vector3.UP)) < 0.999:
		# −Z uçuş yönüdür: kuşların burnu −Z'de, kollar +Z'de (geride).
		global_basis = Basis.looking_at(h, Vector3.UP)
	_place_shadows()


## Bir noktanın zemindeki gölge izinin yeri (saf): ışığın gidiş yönünde y = ground düzlemine iner; yön aşağı bakmıyorsa nokta.
static func shadow_point(p: Vector3, dir: Vector3, ground: float) -> Vector3:
	if dir.y > -1e-4:
		return p
	return p + dir * ((p.y - ground) / -dir.y)


func _place_shadows() -> void:
	if shadows.is_empty():
		return
	var h := heading()
	var flat := Vector3(h.x, 0.0, h.z)
	var yaw := Basis.looking_at(flat, Vector3.UP) if flat.length_squared() > 1e-6 else Basis.IDENTITY
	var dir := shadow_dir.normalized()
	for i in mini(shadows.size(), birds.size()):
		shadows[i].global_transform = Transform3D(yaw, CraneFlock.shadow_point(birds[i].global_position, dir, ground_y))


## Gölge izlerini kurar (ground_shadows kapalıysa siler): her kuşa bir Decal, kanat açıklığı × gövde boyu, dünyada (top_level).
func _build_shadows() -> void:
	for d in shadows:
		if is_instance_valid(d):
			d.queue_free()
	shadows.clear()
	if not ground_shadows:
		return
	var tex := CraneFlock.shadow_texture()
	for i in birds.size():
		var d := Decal.new()
		d.name = "Shadow%d" % i
		d.top_level = true
		d.texture_albedo = tex
		d.modulate = Color(0.0, 0.0, 0.0, shadow_alpha)
		d.size = Vector3(wing_span * bird_scale, 3.0, 1.9 * bird_scale)
		d.upper_fade = 0.2
		d.lower_fade = 0.2
		add_child(d)
		shadows.append(d)


## Gölge izinin dokusu (saf): üstten turna biçimi; x kanat ekseni, y gövde ekseni (üst uç baş). Siyah, biçimin içinde opak.
static func shadow_texture() -> ImageTexture:
	var w := 96
	var hgt := 64
	var img := Image.create(w, hgt, false, Image.FORMAT_RGBA8)
	for y in hgt:
		for x in w:
			var u := (float(x) + 0.5) / float(w) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(hgt) * 2.0 - 1.0
			# Kanatlar: gövdenin biraz önünde, uca doğru daralan, arka kenarı tüylü şerit; gövde ve boyun ince elips; bacaklar geride çizgi.
			var span := absf(u)
			var wing := v > -0.25 - 0.1 * span and v < 0.05 + 0.32 * (1.0 - span * span) and span < 0.98
			var body := (u / 0.1) * (u / 0.1) + ((v - 0.05) / 0.45) * ((v - 0.05) / 0.45) < 1.0
			var neck := absf(u) < 0.03 and v < -0.3 and v > -0.98
			var legs := absf(u) < 0.025 and v > 0.4 and v < 0.95
			var a := 1.0 if wing or body or neck or legs else 0.0
			img.set_pixel(x, y, Color(0.0, 0.0, 0.0, a))
	return ImageTexture.create_from_image(img)


func _build() -> void:
	for b in birds:
		if is_instance_valid(b):
			b.queue_free()
	birds.clear()
	var body_mat := Style.toon(BODY_COLOR, {"brush_strength": 0.05})
	var wing_mat := Style.toon_double(WING_COLOR, {"brush_strength": 0.05})
	var tip_mat := Style.toon(TIP_COLOR)
	var body := Procedural3D.sphere(0.16, 1.0)
	var neck := Procedural3D.capsule(0.035, 0.55)
	var legs := Procedural3D.capsule(0.015, 0.55)
	var half := wing_span * 0.5
	var wing := _wing_mesh(half, 0.42)
	var spots := formation(count, spacing, arm_angle_deg)
	for i in count:
		var bird := Node3D.new()
		bird.name = "Crane%d" % i
		# Düğümün −Z'si uçuş yönüdür (Basis.looking_at); kuşun burnu −Z'de.
		bird.position = spots[i] * Vector3(1.0, 1.0, -1.0)
		bird.scale = Vector3.ONE * bird_scale
		add_child(bird)
		_part(bird, "Body", body, body_mat, Transform3D(Basis.from_scale(Vector3(0.8, 0.8, 2.0)), Vector3.ZERO))
		_part(bird, "Neck", neck, body_mat, Procedural3D.limb_transform(Vector3(0.0, 0.03, -0.25), Vector3(0.0, 0.08, -0.85)))
		_part(bird, "Head", Procedural3D.sphere(0.05, 1.0), tip_mat, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.09, -0.9)))
		_part(bird, "Legs", legs, tip_mat, Procedural3D.limb_transform(Vector3(0.0, -0.02, 0.25), Vector3(0.0, -0.06, 0.85)))
		for side in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.name = "Wing%s" % ("L" if side < 0.0 else "R")
			pivot.position = Vector3(side * 0.1, 0.04, -0.05)
			bird.add_child(pivot)
			var w := MeshInstance3D.new()
			w.name = "Mesh"
			w.mesh = wing
			w.material_override = wing_mat
			w.scale = Vector3(side, 1.0, 1.0)
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			pivot.add_child(w)
		birds.append(bird)
	_build_shadows()
	_build_calls()


func _build_calls() -> void:
	for p in calls:
		if is_instance_valid(p):
			p.queue_free()
	calls.clear()
	var paths := PackedStringArray()
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager and manager.has_method(&"sfx_variants"):
		paths = manager.call(&"sfx_variants", SOUND_ID)
	for i in CALL_ASSETS.size():
		var player := AudioStreamPlayer3D.new()
		player.name = "Call" if i == 0 else "CallAlt"
		player.bus = AudioUtil.bus_or_master(&"SFX")
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.unit_size = call_unit_size
		player.max_distance = 1500.0
		player.volume_db = call_db
		player.max_db = call_peak_db
		player.set_meta(&"free_asset", CALL_ASSETS[i])
		if i < paths.size():
			player.stream = AudioUtil.load_stream(paths[i], false)
		add_child(player)
		calls.append(player)


static func _part(bird: Node3D, node_name: String, mesh: Mesh, mat: Material, xform: Transform3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xform
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bird.add_child(mi)


## Kanat (saf): omuzdan (0, 0, 0) +X'e uzanan ince dörtgen, arka kenarı tüylü, ucu dar; yüz yukarı.
static func _wing_mesh(length: float, chord: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline := [Vector3(0.0, 0.0, -chord * 0.5), Vector3(length * 0.55, 0.0, -chord * 0.45),
		Vector3(length, 0.0, -chord * 0.05), Vector3(length * 0.92, 0.0, chord * 0.25),
		Vector3(length * 0.6, 0.0, chord * 0.55), Vector3(length * 0.3, 0.0, chord * 0.5), Vector3(0.0, 0.0, chord * 0.5)]
	for i in range(1, outline.size() - 1):
		for v in [outline[0], outline[i], outline[i + 1]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()
