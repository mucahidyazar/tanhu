class_name PortraitBaker
extends Node
## Portre pişirici (godot.md §5.4; companions.md §8.1, §12 «PortraitBaker»): kişinin görünüşünden göğüsten yukarı yuvarlak bir portre çizer.
## Kendi 3B dünyası olan bir SubViewport (own_world_3d, render_target_update_mode UPDATE_ONCE), 256 × 256: arkada boyalı gök perdesi
## (gök mavisi, açık ufuk, birkaç beyaz bulut; HUD'un çocuk portrelerinin göğü), önde karakter (CharacterAvatar: profil, kılık ve
## pelerin; bekleme pozu, 3/4 açı), sıcak ön ışık ve serin arka ışık. Bir kez çizilir; görüntü yuvarlak kesilip doku olarak tutulur
## (önbellek: görünüşün anahtarı), görünüş değişince yeniden çizilir. Boyalı portre varsa (assets/ui/hud/portrait_<kimlik>.png:
## painted) o kullanılır. Başsızda çizici yoktur: doku gelmez, çağıran yedeğini çizer. HUD'un sol üstündeki yetişkin portresi buradandır.
## Bu kadraj K98'in dışındadır: oyun içi çekim değil, arayüzün portresidir (çocuk portreleri de yakındır).
##   var baker := PortraitBaker.new()
##   add_child(baker)
##   baker.baked.connect(func(key: String, tex: Texture2D) -> void: ...)
##   baker.bake(profile, &"hostage_coat", &"cape_hostage")

signal baked(key: String, texture: Texture2D)

const SIZE := 256
## Kadraj (CreatorTurntable.close_frame): görüş açısı, ekrana sığan dikey alan (1,75 m'lik kişiye göre), yüzün ekrandaki yüksekliği (0 üst,
## 1 alt), kameranın eğimi; kişinin 3/4 dönüşü (derece).
const FOV := 26.0
const VIEW_HEIGHT := 0.7
const FACE_AT := 0.5
const ELEVATION := 1.5
const TURN := -18.0
## Göğün renkleri (çocuk portrelerinin boyalı göğünden).
const SKY_TOP := Color(0.33, 0.55, 0.84)
const SKY_LOW := Color(0.80, 0.87, 0.94)
const SKY_SHADER := "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\n" \
	+ "uniform vec3 top;\nuniform vec3 low;\n" \
	+ "float blob(vec2 uv, vec2 c, vec2 r) { return 1.0 - smoothstep(0.5, 1.0, length((uv - c) / r)); }\n" \
	+ "void fragment() {\n\tvec2 uv = UV;\n\tvec3 col = mix(top, low, smoothstep(0.05, 0.95, uv.y));\n" \
	+ "\tfloat c = max(max(blob(uv, vec2(0.18, 0.40), vec2(0.20, 0.07)), blob(uv, vec2(0.30, 0.36), vec2(0.12, 0.08))),\n" \
	+ "\t\tmax(blob(uv, vec2(0.82, 0.52), vec2(0.22, 0.06)), blob(uv, vec2(0.72, 0.48), vec2(0.11, 0.07))));\n" \
	+ "\tcol = mix(col, vec3(1.0, 0.99, 0.97), c * 0.8);\n\tALBEDO = col;\n}\n"

## Görünüşün anahtarı → doku.
static var _cache: Dictionary = {}
static var _mask: Image
static var _sky_shader: Shader

var _busy := ""


## Görünüşün anahtarı (profilin alanları, kılık ve pelerin).
static func key_of(profile: CharacterProfile, outfit: StringName = &"", cape: StringName = &"") -> String:
	if profile == null:
		return ""
	return "%s|%s|%s" % [JSON.stringify(profile.to_dict(), "", true), outfit, cape]


## Pişmiş doku (yoksa null).
static func cached(key: String) -> Texture2D:
	return _cache.get(key)


static func forget() -> void:
	_cache.clear()


## Çizici var mı (başsızda yok: portre pişmez).
static func can_render() -> bool:
	return DisplayServer.get_name() != "headless"


## Portreyi pişirir (beklenebilir): önbellekte ya da boyalı portre varsa hemen. Döner: doku (çizilemezse null); baked yayılır.
func bake(profile: CharacterProfile, outfit: StringName = &"", cape: StringName = &"", painted: String = "") -> Texture2D:
	var key := key_of(profile, outfit, cape)
	if key.is_empty():
		return null
	if not painted.is_empty():
		var p := HudKit.tex(painted)
		if p:
			_cache[key] = p
	if _cache.has(key):
		var hit: Texture2D = _cache[key]
		baked.emit.call_deferred(key, hit)
		return hit
	if not can_render() or not is_inside_tree() or _busy == key:
		return null
	_busy = key
	return await _render(key, _build(profile, outfit, cape))


## Adlı erin ve kalabalığın kişisinin portresi (Folk'un görünüşünden; beklenebilir; companions.md §1.4 adlı erler): aynı kadraj, gök
## ve ışık; kişi Folk.prepare ile giydirilir. Anahtar Folk.key_of. Döner: doku (başsızda ve çizilemezse null); baked yayılır.
func bake_look(look: Dictionary) -> Texture2D:
	if look.is_empty():
		return null
	var key := Folk.key_of(look)
	if _cache.has(key):
		var hit: Texture2D = _cache[key]
		baked.emit.call_deferred(key, hit)
		return hit
	if not can_render() or not is_inside_tree() or _busy == key:
		return null
	_busy = key
	return await _render(key, _build(null, &"", &"", look))


## Görüntüyü çizer ve keser (bake ve bake_look'un ortak yolu).
func _render(key: String, vp: SubViewport) -> Texture2D:
	add_child(vp)
	var avatar := vp.get_node(^"Pivot/Avatar") as CharacterAvatar
	# Klip pozu otursun (bekleme klibinin ilk karesi), kadraj kişinin boyuna göre kurulur.
	for i in 3:
		await get_tree().process_frame
	if not is_instance_valid(vp):
		_busy = ""
		return null
	var cam := vp.get_node(^"Camera") as Camera3D
	var height := avatar.get_model_height()
	var frame := CreatorTurntable.close_frame(height, avatar.get_head_height(), FOV, VIEW_HEIGHT, FACE_AT, ELEVATION)
	# Yüz yatayda ortalanır: bekleme pozunda baş gövdenin ekseninden kayar (dönüş, duruş); kadraj başın o anki yerine kayar.
	var shift := Vector3.ZERO
	var skel := avatar.get_skeleton()
	var head_bone := skel.find_bone("Head") if skel else -1
	if head_bone >= 0:
		var head := skel.global_transform * skel.get_bone_global_pose(head_bone).origin
		shift = Vector3(head.x, 0.0, head.z)
	frame[0] += shift
	frame[1] += shift
	cam.look_at_from_position(frame[0], frame[1], Vector3.UP)
	var sky := vp.get_node(^"Sky") as MeshInstance3D
	var back := (frame[1] - frame[0]).normalized()
	sky.global_position = frame[1] + back * 1.2
	sky.look_at(frame[0], Vector3.UP)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image() if is_instance_valid(vp) else null
	if is_instance_valid(vp):
		vp.queue_free()
	_busy = ""
	if img == null or img.is_empty():
		return null
	var tex := ImageTexture.create_from_image(PortraitBaker.round_cut(img))
	_cache[key] = tex
	baked.emit(key, tex)
	return tex


## Görüntüyü yuvarlak keser (saf): dairenin dışı saydam (kenarı halka örter).
static func round_cut(img: Image) -> Image:
	var src := img.duplicate() as Image
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	if _mask == null or _mask.get_width() != w or _mask.get_height() != h:
		_mask = Image.create(w, h, false, Image.FORMAT_RGBA8)
		var r := minf(w, h) * 0.5
		var c := Vector2(w, h) * 0.5
		for y in h:
			var dy := float(y) + 0.5 - c.y
			if absf(dy) >= r:
				continue
			var half := sqrt(r * r - dy * dy)
			var x0 := int(ceil(c.x - half - 0.5))
			var x1 := int(floor(c.x + half - 0.5))
			if x1 >= x0:
				_mask.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), Color.WHITE)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.blit_rect_mask(src, _mask, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return out


func _build(profile: CharacterProfile, outfit: StringName, cape: StringName, look: Dictionary = {}) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = "PortraitViewport"
	vp.size = Vector2i(SIZE, SIZE)
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = SKY_LOW
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.86, 0.88, 0.95)
	e.ambient_light_energy = 0.55
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.name = "Key"
	key.rotation_degrees = Vector3(-30.0, 28.0, 0.0)
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.93, 0.82)
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.name = "Rim"
	rim.rotation_degrees = Vector3(-16.0, -150.0, 0.0)
	rim.light_energy = 0.6
	rim.light_color = Color(0.72, 0.84, 1.0)
	vp.add_child(rim)
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = FOV
	cam.near = 0.05
	cam.far = 20.0
	cam.current = true
	vp.add_child(cam)
	if _sky_shader == null:
		_sky_shader = Shader.new()
		_sky_shader.code = SKY_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _sky_shader
	mat.set_shader_parameter(&"top", Vector3(SKY_TOP.r, SKY_TOP.g, SKY_TOP.b))
	mat.set_shader_parameter(&"low", Vector3(SKY_LOW.r, SKY_LOW.g, SKY_LOW.b))
	var quad := QuadMesh.new()
	quad.size = Vector2(4.0, 4.0)
	var sky := MeshInstance3D.new()
	sky.name = "Sky"
	sky.mesh = quad
	sky.material_override = mat
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vp.add_child(sky)
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	pivot.rotation.y = deg_to_rad(TURN)
	vp.add_child(pivot)
	var avatar := CharacterAvatar.new()
	avatar.name = "Avatar"
	avatar.start_pose = &"idle"
	if not look.is_empty():
		Folk.prepare(avatar, look)
		# Portrenin kadrajı kişinin boyuna kurulur; genişliği çarpılmaz (yüz basık görünmesin).
		avatar.scale = Vector3.ONE
	else:
		avatar.profile = profile
		if outfit != &"":
			avatar.outfit = outfit
		if cape != &"":
			avatar.cape_item = cape
	pivot.add_child(avatar)
	return vp
