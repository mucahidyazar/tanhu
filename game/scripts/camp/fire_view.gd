class_name FireView
extends Procedural3D
## Oyuncunun ateşinin görünüşü (survival.md §2, §2.8; FireState'in yüzü; kamp ateşinin, Campfire'ın, dilinde): kül yatağı, isteğe bağlı taş
## halkası (Eski Ocak'ta hep), yakıt konisi, kor yatağı, boyalı alevler (flame.gdshader), kıvılcımlar, duman, titreyen sıcak ışık ve konumlu
## çıtırtı. Evre görünüşü değiştirir: Kor alevsiz, az ışıklı; Küçük, Orta, Büyük alevin boyu ve ışığın yarıçapı (6, 10, 14 m) büyür.
## Küllenmiş köz (Küle Yatır) kül yığınıdır: ışık ve duman yok, yalnız külün altında sönük bir kızıllık. Çukur (cold_pit) kül halkasıdır:
## ışık, duman ve ses yok. Yer halkası (fire_ring.gdshader) ateşin 6 m içinde evreyi (renk) ve kalan yakıtı (yay) gösterir (show_ring).
## Işık gölgesizdir (K63: zondaki ≤6 oyuncu ateşi gölgesiz ışık taşır). Görünüş durum ve evre değişince yeniden kurulur, kare başına yalnız
## ışığın titremesi ve halkanın yayı yazılır.
##   var v := FireView.new()
##   v.bind(fire)                  # FireState: durum ve evre sinyalleriyle kendini yeniler
##   v.show_ring = oyuncu_6m_içinde

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const ROCK_SHADER := preload("res://shaders/rock.gdshader")
const RING_SHADER := preload("res://shaders/fire_ring.gdshader")
const CRACKLE_PATH := "res://audio/ambience/campfire_loop.wav"
const LIGHT_COLOR := Color(1.0, 0.56, 0.24)
## Yer halkasının dörtgeni (m) ve halkanın yarıçapı (dörtgenin yarısına oranla: 1,3 × 0,82 ≈ 1,07 m; taş halkasının dışında).
const RING_SIZE := 2.6
## Evrenin görünüşü: alevin ölçeği, ışığın enerjisi ve yarıçap çarpanı, kor yatağının parlaması, kıvılcım, dumanın boyu, sesin düzeyi
## (dB) ve halkanın rengi.
const LOOK := {
	&"embers": {"flame": 0.0, "energy": 0.6, "bed": 1.7, "sparks": 0, "smoke": Vector2(0.45, 1.3), "db": -20.0, "ring": Color(0.86, 0.22, 0.1)},
	&"small": {"flame": 0.52, "energy": 1.25, "bed": 2.0, "sparks": 8, "smoke": Vector2(0.75, 2.0), "db": -10.0, "ring": Color(1.0, 0.5, 0.16)},
	&"steady": {"flame": 0.8, "energy": 1.9, "bed": 2.3, "sparks": 16, "smoke": Vector2(1.0, 2.5), "db": -6.0, "ring": Color(1.0, 0.72, 0.3)},
	&"blaze": {"flame": 1.1, "energy": 2.6, "bed": 2.6, "sparks": 26, "smoke": Vector2(1.3, 3.1), "db": -3.0, "ring": Color(1.0, 0.9, 0.6)},
}
const ASH_COLOR := Color(0.24, 0.22, 0.21)
const PIT_COLOR := Color(0.36, 0.34, 0.32)
const CHAR_COLOR := Color(0.11, 0.08, 0.07)

var fire: FireState
## Yer halkası görünsün mü (oyuncu 6 m içinde; SurvivalLayer yazar)?
var show_ring := false:
	set(value):
		show_ring = value
		_refresh_ring()

var _light: OmniLight3D
var _ring: MeshInstance3D
var _ring_mat: ShaderMaterial
var _time := 0.0
var _seed := 0.0
var _key := ""


func _ready() -> void:
	_seed = float(absi(hash(name)) % 1000) * 0.37
	super._ready()


## Ateşe bağlar: durum ve evre değişince görünüş yeniden kurulur.
func bind(p_fire: FireState) -> void:
	if fire and fire.stage_changed.is_connected(_on_fire_changed):
		fire.stage_changed.disconnect(_on_fire_changed)
		fire.state_changed.disconnect(_on_state_changed)
	fire = p_fire
	if fire:
		fire.stage_changed.connect(_on_fire_changed)
		fire.state_changed.connect(_on_state_changed)
		position = Vector3(fire.x, position.y, fire.z)
	refresh()


## Oyuncunun çarpıştığı daire (World.OBSTACLE_GROUP'taysa): taş halkası 0,78 m, taşsız ateş 0,55 m; kül çukurunun üstünden geçilir.
func get_obstacle_circles() -> Array[Vector3]:
	if fire != null and fire.is_pit() and not fire.stones:
		return []
	return [Vector3(global_position.x, global_position.z, 0.78 if fire == null or fire.stones else 0.55)]


## Durum ya da evre değiştiyse yeniden kurar.
func refresh() -> void:
	if look_key() != _key:
		queue_rebuild()


## Görünüşün anahtarı: durum, evre, taş.
func look_key() -> String:
	if fire == null:
		return "pit|stones"
	return "%s|%s|%s" % [fire.state, fire.stage(), "stones" if fire.stones else ""]


func _on_fire_changed(_stage: StringName) -> void:
	refresh()


func _on_state_changed(_state: StringName, _reason: StringName) -> void:
	refresh()


## Görünüşün özeti (sınama ve kare): {state, stage, light, light_range, flames, smoke, sparks, sound, stones}.
func look() -> Dictionary:
	var out := {"state": String(fire.state) if fire else "pit", "stage": String(fire.stage()) if fire else "", "light": _light != null,
		"light_range": _light.omni_range if _light else 0.0, "flames": 0, "smoke": false, "sparks": false, "sound": false,
		"stones": fire.stones if fire else true}
	for c in get_children():
		if not c.has_meta(&"generated"):
			continue
		match str(c.get_meta(&"part", "")):
			"flame":
				out["flames"] = int(out["flames"]) + 1
			"smoke":
				out["smoke"] = true
			"sparks":
				out["sparks"] = true
			"sound":
				out["sound"] = true
	return out


func _process(delta: float) -> void:
	_time += delta
	if _light:
		var f := Campfire.flicker(_time, _seed)
		var base: float = float(_look().get("energy", 1.0))
		_light.light_energy = base * f
		_light.position = Vector3(sin(_time * 3.1) * 0.03, 0.6 + (f - 1.0) * 0.12, cos(_time * 2.6) * 0.03)
	if _ring and _ring.visible and fire:
		_ring_mat.set_shader_parameter(&"fill", clampf(fire.fuel / FireState.fuel_max(), 0.0, 1.0) if fire.is_lit() else 1.0)


func _look() -> Dictionary:
	return LOOK.get(fire.stage() if fire and fire.is_lit() else &"", {})


func _build() -> void:
	_key = look_key()
	_light = null
	var lit := fire != null and fire.is_lit()
	var banked := fire != null and fire.is_banked()
	var stones := fire == null or fire.stones
	var look_row := _look()
	_build_bed(lit, banked)
	if stones:
		_build_stones()
	if lit:
		_build_fuel(fire.stage())
		_build_embers(float(look_row.get("bed", 2.0)), fire.stage() == &"embers")
		_build_flames(float(look_row.get("flame", 0.0)))
		_build_light(look_row)
		var n := int(look_row.get("sparks", 0))
		if n > 0:
			var sparks := Fx.embers(n)
			sparks.position = Vector3(0.0, 0.25, 0.0)
			_part(sparks, "sparks")
		var smoke := Fx.smoke(look_row.get("smoke", Vector2(0.8, 2.0)), Vector2(-0.4, -0.12))
		smoke.position = Vector3(0.0, 0.35, 0.0)
		_part(smoke, "smoke")
		if fire.stage() != &"embers" and not Engine.is_editor_hint():
			_build_sound(float(look_row.get("db", -8.0)))
	elif banked:
		_build_ash_mound()
	_build_ring()


## Kül yatağı ve kömür parçaları (her durumda): çukurun kendisi.
func _build_bed(lit: bool, banked: bool) -> void:
	var color := ASH_COLOR if lit or banked else PIT_COLOR
	add_mesh(MeshKit.disc(0.5, 0.012, 22), Style.toon(color, {"brush_strength": 0.15}))
	var rng := RandomNumberGenerator.new()
	rng.seed = 911
	var char_mat := Style.toon(CHAR_COLOR)
	for i in 7:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.08, 0.38)
		var s := rng.randf_range(0.035, 0.06)
		add_mesh(sphere(s, 0.55), char_mat, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(cos(a) * r, 0.02, sin(a) * r)))


## Taş halkası (dokuz isli taş; Eski Ocak'ta hep vardır).
func _build_stones() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("moss_amount", 0.0)
	mat.set_shader_parameter("rock_color", Color(0.48, 0.46, 0.44))
	mat.set_shader_parameter("rock_shadow", Color(0.26, 0.26, 0.3))
	mat.set_shader_parameter("soot", 0.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4243
	var count := 9
	for i in count:
		var a := TAU * float(i) / float(count) + rng.randf_range(-0.1, 0.1)
		var r := 0.66 + rng.randf_range(-0.04, 0.04)
		var s := rng.randf_range(0.15, 0.21)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.75, 1.0), s))
		add_mesh(MeshKit.rock(200 + i, 2, 0.3), mat, Transform3D(basis, Vector3(cos(a) * r, 0.0, sin(a) * r)))


## Yakıt konisi: Kor'da kısalmış kömürleşmiş kütükler, büyüdükçe uzun.
func _build_fuel(stage: StringName) -> void:
	var wood := Style.toon(Style.WOOD_DARK.darkened(0.2), {"brush_strength": 0.2})
	var charred := Style.toon(Color(0.12, 0.08, 0.07))
	var rng := RandomNumberGenerator.new()
	rng.seed = 78
	var height := {&"embers": 0.12, &"small": 0.3, &"steady": 0.4, &"blaze": 0.46}.get(stage, 0.35) as float
	var count := 3 if stage == &"embers" else 5
	for i in count:
		var a := TAU * float(i) / float(count) + 0.3
		var foot := Vector3(cos(a) * 0.42, 0.04, sin(a) * 0.42)
		var top := Vector3(cos(a + 2.4) * 0.06, height + rng.randf_range(-0.04, 0.05), sin(a + 2.4) * 0.06)
		add_mesh(capsule(0.05, foot.distance_to(top)), charred if stage == &"embers" or i % 2 == 1 else wood, limb_transform(foot, top))


## Kor yatağı: parlayan disk ve kor parçaları (Kor evresinde daha geniş ve kızıl).
func _build_embers(energy: float, low: bool) -> void:
	var bed_color := Color(1.0, 0.3, 0.08) if low else Color(1.0, 0.38, 0.1)
	var radius := 0.36 if low else 0.28
	add_mesh(MeshKit.disc(radius, 0.03, 20), Style.glow(bed_color, energy))
	var rng := RandomNumberGenerator.new()
	rng.seed = 79
	var bit := Style.glow(Color(1.0, 0.45, 0.12), energy + 1.2)
	for i in (7 if low else 4):
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.05, radius * 0.85)
		add_mesh(sphere(rng.randf_range(0.03, 0.05), 0.6), bit, Transform3D(Basis.IDENTITY, Vector3(cos(a) * r, 0.05, sin(a) * r)))


## Küllenmiş köz: kül yığını, altında sönük kızıllık (ışık değil).
func _build_ash_mound() -> void:
	add_mesh(sphere(0.3, 0.32), Style.toon(Color(0.5, 0.48, 0.46), {"brush_strength": 0.2}), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.02, 0.0)))
	add_mesh(MeshKit.disc(0.18, 0.025, 14), Style.glow(Color(0.7, 0.16, 0.06), 0.35))


func _build_flames(scale: float) -> void:
	if scale <= 0.0:
		return
	# Kamp ateşinin katmanları (Campfire._build_flames): üst üste binen alev kartları, evrenin ölçeğiyle.
	var layers := [
		[Vector2(1.25, 1.2), 1.5, 1.4, 0.0, Vector3(0.0, 0.0, 0.0)],
		[Vector2(0.95, 1.05), 1.3, 1.8, 0.37, Vector3(0.14, 0.0, 0.06)],
		[Vector2(0.85, 0.9), 1.15, 2.1, 0.71, Vector3(-0.15, 0.0, -0.05)],
		[Vector2(0.7, 0.75), 1.0, 2.4, 0.53, Vector3(0.05, 0.0, -0.12)],
		[Vector2(0.55, 0.55), 0.9, 2.7, 0.13, Vector3(0.0, 0.0, 0.1)],
	]
	var n := layers.size() if scale >= 0.7 else 3
	for i in n:
		var layer: Array = layers[i]
		var size: Vector2 = layer[0] * scale
		var quad := QuadMesh.new()
		quad.size = size
		quad.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = FLAME_SHADER
		mat.set_shader_parameter("energy", layer[1])
		mat.set_shader_parameter("speed", layer[2])
		mat.set_shader_parameter("seed", float(layer[3]) + _seed)
		var mi := add_mesh(quad, mat, Transform3D(Basis.IDENTITY, (layer[4] as Vector3) * scale + Vector3(0.0, 0.02, 0.0)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_meta(&"part", "flame")


func _build_light(look_row: Dictionary) -> void:
	_light = OmniLight3D.new()
	_light.name = "FireLight"
	_light.light_color = LIGHT_COLOR
	_light.light_energy = float(look_row.get("energy", 1.0))
	# Işığın yarıçapı oyunun ışık halkasıdır (Kor 1,6, Küçük 6, Orta 10, Büyük 14 m); sönüm kamp ateşininki gibi düşük.
	_light.omni_range = maxf(fire.light_m(), 1.6)
	_light.omni_attenuation = 0.55
	_light.shadow_enabled = false
	_light.light_size = 0.25
	_light.light_volumetric_fog_energy = 2.0
	_light.position = Vector3(0.0, 0.6, 0.0)
	_part(_light, "light")


func _build_sound(db: float) -> void:
	var stream := AudioUtil.load_stream(CRACKLE_PATH, true)
	if stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "Crackle"
	player.stream = stream
	player.bus = AudioUtil.bus_or_master(&"Ambience")
	player.volume_db = db
	player.unit_size = 3.0
	player.max_distance = 36.0
	player.autoplay = true
	player.position = Vector3(0.0, 0.4, 0.0)
	_part(player, "sound")


func _build_ring() -> void:
	_ring = FireView.make_ring(RING_SIZE)
	_ring.name = "Ring"
	_ring_mat = _ring.material_override as ShaderMaterial
	add_generated(_ring)
	_refresh_ring()


func _refresh_ring() -> void:
	if _ring == null or not is_instance_valid(_ring):
		return
	var on := show_ring and fire != null and not fire.is_pit()
	_ring.visible = on
	if not on:
		return
	if fire.is_banked():
		_ring_mat.set_shader_parameter(&"color", Color(0.62, 0.6, 0.58, 0.85))
		_ring_mat.set_shader_parameter(&"fill", 1.0)
	else:
		var c: Color = _look().get("ring", Color(1.0, 0.72, 0.3))
		_ring_mat.set_shader_parameter(&"color", Color(c, 0.95))
		_ring_mat.set_shader_parameter(&"fill", clampf(fire.fuel / FireState.fuel_max(), 0.0, 1.0))


func _part(node: Node, part: String) -> void:
	node.set_meta(&"part", part)
	add_generated(node)


## Pişirmenin görünüşü (survival.md §3): «spit» iki çatallı kazık ve şişte et, «cauldron» taşların üstünde küçük kazan, «ember» korda
## balık; "" kaldırır. Düğüm üretilmiş değildir: evre değişip görünüş yeniden kurulunca pişen yemek yerinde kalır.
func set_cooking(station: String) -> void:
	var old := get_node_or_null(^"Cook")
	if old:
		remove_child(old)
		old.queue_free()
	if station.is_empty():
		return
	var cook := Node3D.new()
	cook.name = "Cook"
	add_child(cook)
	var wood := Style.toon(Style.WOOD_DARK, {"brush_strength": 0.2})
	var meat := Style.toon(Color(0.55, 0.24, 0.14), {"brush_strength": 0.15})
	match station:
		"spit":
			for side: float in [-0.62, 0.62]:
				var stake := MeshInstance3D.new()
				stake.mesh = capsule(0.025, 0.62)
				stake.material_override = wood
				stake.position = Vector3(side, 0.31, 0.0)
				cook.add_child(stake)
			var rod := MeshInstance3D.new()
			rod.mesh = capsule(0.018, 1.36)
			rod.material_override = wood
			rod.transform = limb_transform(Vector3(-0.68, 0.6, 0.0), Vector3(0.68, 0.6, 0.0))
			cook.add_child(rod)
			var lump := MeshInstance3D.new()
			lump.mesh = sphere(0.13, 0.75)
			lump.material_override = meat
			lump.position = Vector3(0.0, 0.6, 0.0)
			lump.scale = Vector3(1.5, 1.0, 1.0)
			cook.add_child(lump)
		"cauldron":
			var pot := MeshInstance3D.new()
			pot.mesh = cylinder(0.24, 0.19, 0.26, 18)
			pot.material_override = Style.toon(Color(0.16, 0.14, 0.13), {"brush_strength": 0.2})
			pot.position = Vector3(0.0, 0.42, 0.0)
			cook.add_child(pot)
			var brim := MeshInstance3D.new()
			brim.mesh = MeshKit.disc(0.21, 0.0, 18)
			brim.material_override = Style.toon(Color(0.86, 0.8, 0.62))
			brim.position = Vector3(0.0, 0.54, 0.0)
			cook.add_child(brim)
			for i in 3:
				var a := TAU * float(i) / 3.0
				var leg := MeshInstance3D.new()
				leg.mesh = capsule(0.02, 0.95)
				leg.material_override = wood
				leg.transform = limb_transform(Vector3(cos(a) * 0.62, 0.0, sin(a) * 0.62), Vector3(0.0, 0.95, 0.0))
				cook.add_child(leg)
		"ember":
			var fish := MeshInstance3D.new()
			fish.mesh = sphere(0.1, 0.45)
			fish.material_override = Style.toon(Color(0.62, 0.6, 0.52))
			fish.position = Vector3(0.0, 0.07, 0.0)
			fish.scale = Vector3(2.4, 1.0, 1.0)
			cook.add_child(fish)


## Yere yatık halka (fire_ring.gdshader; mode 0 yay, 1 Tam Vuruş): yer seçiminin önizlemesi, işin ilerlemesi ve ateşin halkası.
static func make_ring(size: float, mode := 0) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter(&"mode", mode)
	mat.render_priority = 2
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0.0, 0.06, 0.0)
	return mi
