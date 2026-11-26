class_name CrowdCards
extends Node3D
## Dailin'in kalabalığı, kart kademesi (T3; army.md §7.1, §7.4; godot.md §4.5; story.md §5 «uzaktaki sayım kalabalığı kart kademesindedir»):
## kişi başına 2 üçgenlik kart, tek MultiMeshInstance3D (tek çizim, gölge düşürmez); ayağın altında 2 üçgenlik temas lekesi (ikinci çizim).
## Kart modelden pişirilmiş atlastan okunur (tools/bake_crowd_cards.gd: assets/crowd/dailin_cards*.png, .json): 8 yön × (bekleme + 4
## yürüyüş evresi) × 3 kişi (Hun erkeği, kadını, atlısı). Kart kameraya döner, ayağından yere basar; gölgelendirici kameranın kişiye göre
## yönünden hücreyi seçer (kişi döndükçe kartı değişir), rengi ve görüş uzayı normali atlastandır: ışık karakterlerin cel ışığıdır
## (character_toon'un gölge oranı ve sınırı), güneşin düşen gölgesini alır. Hattan uzakta, 40–150 piksel boyda okunur.
##
## Kişilerin yeri ve hâli CrowdPlan'dandır (saf; layout.json "childhood.crowd"): oyunun dakikası (set_minute) kim yola çıktı, planda ne kadar
## yürüdü der. Kişinin gerçek yolu burada tutulur (E20, PaceLimit): saat görünür biçimde akarken (GameClock.begin_lapse) plan öne geçer, kişi
## kendi hızının CrowdPlan.HURRY katıyla, en çok speed_cap ile (oyuncunun koşusu) yetişir; ışınlanmaz. Yola çıkan saat dursa da yürür.
## İlk yazışta (ve snap() sonrası) herkes planın yerindedir (atlanan adımdan başlayan sahne). Yürüyenin karesi yürüdüğü yoldan (adım
## kaymaz), ilk metrelerde belirerek gelir. Duranlar ara ara başını ve gövdesini çevirir; watch(nokta) verilince (Teoman'ın atlıları geçerken)
## kişi kişi, birbirinden az gecikmeyle o noktaya döner. peak_speed yürüyenlerin ölçülen en yüksek hızıdır (m/sn).
##   var crowd := CrowdCards.new()
##   crowd.setup(CrowdPlan.build(spec, blockers), ground, meta, albedo_texture, normal_texture)
##   add_child(crowd); crowd.set_minute(640.0); crowd.watch(teoman_position)

const CARD_CODE := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled, skip_vertex_transform;
uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_atlas : filter_linear_mipmap, repeat_disable;
uniform vec2 cell_px = vec2(128.0, 256.0);
uniform vec2 atlas_px = vec2(2048.0, 2048.0);
uniform float cols = 16.0;
uniform vec2 cell_m = vec2(1.1, 2.2);
uniform float pivot = 0.18;
uniform float dirs = 8.0;
uniform float alpha_cut = 0.5;
group_uniforms cel;
// character_toon.gdshader'ın ışığı: kalabalık adlı kişilerle aynı ışıkta durur.
uniform float shadow_level : hint_range(0.0, 1.0) = 0.78;
uniform vec3 shadow_tint : source_color = vec3(1.0, 0.97, 0.9);
uniform float terminator = 0.05;
uniform float terminator_softness : hint_range(0.0, 0.6) = 0.14;
uniform float form_shading : hint_range(0.0, 0.5) = 0.12;
group_uniforms;
varying vec2 v_uv;
varying float v_presence;
varying vec3 v_tint;

void vertex() {
	// Kart kameraya döner (görüş uzayında), ayak (örneğin kökü) hücrenin alttan pivot oranında.
	vec3 feet = MODEL_MATRIX[3].xyz;
	float s = length(MODEL_MATRIX[0].xyz);
	vec2 corner = VERTEX.xy + vec2(0.5);
	vec3 feet_view = (VIEW_MATRIX * vec4(feet, 1.0)).xyz;
	VERTEX = feet_view + vec3((corner.x - 0.5) * cell_m.x, (corner.y - pivot) * cell_m.y, 0.0) * s;
	NORMAL = vec3(0.0, 0.0, 1.0);
	// Kameranın kişiye göre yönü (0 önde, artan sol) → hücre.
	vec3 to_cam = CAMERA_POSITION_WORLD - feet;
	float rel = atan(to_cam.x, to_cam.z) - INSTANCE_CUSTOM.r;
	float col = mod(floor(fract(rel / TAU + 0.5 / dirs) * dirs), dirs);
	float index = INSTANCE_CUSTOM.g + col;
	vec2 cell = vec2(mod(index, cols), floor(index / cols));
	v_uv = (cell + vec2(corner.x, 1.0 - corner.y)) * cell_px / atlas_px;
	v_presence = COLOR.a;
	v_tint = COLOR.rgb;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 a = texture(albedo_atlas, v_uv);
	// Belirme: varlık payı kadar piksel (titreşimsiz düzensiz örüntü).
	if (a.a < alpha_cut || hash(floor(FRAGCOORD.xy)) > v_presence) {
		discard;
	}
	ALBEDO = a.rgb * v_tint;
	NORMAL = normalize(texture(normal_atlas, v_uv).rgb * 2.0 - 1.0);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(terminator - terminator_softness, terminator + terminator_softness, ndl);
	float form = 1.0 - form_shading * (1.0 - smoothstep(0.0, 1.0, ndl));
	if (LIGHT_IS_DIRECTIONAL) {
		band *= ATTENUATION;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(shadow_tint * shadow_level, vec3(form), band);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * mix(shadow_tint * shadow_level, vec3(1.0), band);
	}
}
"""

const BLOB_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 blob_color : source_color = vec4(0.16, 0.12, 0.08, 0.3);
varying float v_presence;
void vertex() {
	v_presence = COLOR.a;
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	ALBEDO = blob_color.rgb;
	ALPHA = blob_color.a * (1.0 - smoothstep(0.2, 1.0, r)) * v_presence;
}
"""

## Paletli kart (I. Perde'nin kalabalığı, T3; CrowdField; army.md §7.4): atlas açılışta kuklanın T1 ağından bir SubViewport'ta pişer
## (bake_puppet_atlas): 8 yön (sütun) × 8 kare (satır: 0–5 yürüyüşün evreleri, 6 duruş, 7 oturuş) × üç başlık biçimi (satır öbekleri).
## Maske atlası önçarpımlıdır (MSAA'nın kenarı): R giysi ve şerit, G ten, B başlık, A kaplama; geri kalan (saç, çizme) koyudur. Renkler
## kişinin paletinden (Folk.palette; palet dokusu CrowdPuppet.palette_image), köşe gölgelendiricisinde okunur: mipmap güvenlidir, palet
## dizini atlasta tutulmaz. Işık kuklanınkiyle aynı cel ışığıdır (normal atlası). Örnek: CUSTOM (yön, hücrenin başı, palet sırası, varlık).
const PALETTE_CARD_CODE := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled, skip_vertex_transform;
uniform sampler2D mask_atlas : filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_atlas : filter_linear_mipmap, repeat_disable;
uniform sampler2D palette : source_color, filter_nearest, repeat_disable;
uniform int palette_cols = 64;
uniform int palette_slots = 8;
uniform vec2 grid = vec2(8.0, 24.0);
uniform vec2 cell_m = vec2(1.1, 2.2);
uniform float pivot = 0.12;
uniform float dirs = 8.0;
uniform float alpha_cut = 0.4;
group_uniforms cel;
uniform float shadow_level : hint_range(0.0, 1.0) = 0.78;
uniform vec3 shadow_tint : source_color = vec3(1.0, 0.97, 0.9);
uniform float terminator = 0.05;
uniform float terminator_softness : hint_range(0.0, 0.6) = 0.14;
uniform float form_shading : hint_range(0.0, 0.5) = 0.12;
group_uniforms;
varying vec2 v_uv;
varying float v_presence;
varying vec3 v_coat;
varying vec3 v_skin;
varying vec3 v_hat;
varying vec3 v_dark;

vec3 pal(int look, int slot) {
	return texelFetch(palette, ivec2((look % palette_cols) * palette_slots + slot, look / palette_cols), 0).rgb;
}

void vertex() {
	vec3 feet = MODEL_MATRIX[3].xyz;
	float s = length(MODEL_MATRIX[1].xyz);
	vec2 corner = VERTEX.xy + vec2(0.5);
	vec3 feet_view = (VIEW_MATRIX * vec4(feet, 1.0)).xyz;
	VERTEX = feet_view + vec3((corner.x - 0.5) * cell_m.x, (corner.y - pivot) * cell_m.y, 0.0) * s;
	NORMAL = vec3(0.0, 0.0, 1.0);
	vec3 to_cam = CAMERA_POSITION_WORLD - feet;
	float rel = atan(to_cam.x, to_cam.z) - INSTANCE_CUSTOM.x;
	float col = mod(floor(fract(rel / TAU + 0.5 / dirs) * dirs), dirs);
	float index = INSTANCE_CUSTOM.y + col;
	vec2 cell = vec2(mod(index, grid.x), floor(index / grid.x));
	v_uv = (cell + vec2(corner.x, 1.0 - corner.y)) / grid;
	int look = int(INSTANCE_CUSTOM.z + 0.5);
	v_coat = pal(look, 0);
	v_skin = pal(look, 2);
	v_hat = pal(look, 4);
	v_dark = pal(look, 3) * 0.6 + pal(look, 5) * 0.4;
	v_presence = INSTANCE_CUSTOM.w;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 m = texture(mask_atlas, v_uv);
	if (m.a < alpha_cut || hash(floor(FRAGCOORD.xy)) > v_presence) {
		discard;
	}
	vec3 w = m.rgb / max(m.a, 0.001);
	float dark = clamp(1.0 - w.r - w.g - w.b, 0.0, 1.0);
	ALBEDO = v_coat * w.r + v_skin * w.g + v_hat * w.b + v_dark * dark;
	vec4 nrm = texture(normal_atlas, v_uv);
	NORMAL = normalize((nrm.rgb / max(nrm.a, 0.001)) * 2.0 - 1.0);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(terminator - terminator_softness, terminator + terminator_softness, ndl);
	float form = 1.0 - form_shading * (1.0 - smoothstep(0.0, 1.0, ndl));
	if (LIGHT_IS_DIRECTIONAL) {
		band *= ATTENUATION;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(shadow_tint * shadow_level, vec3(form), band);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * mix(shadow_tint * shadow_level, vec3(1.0), band);
	}
}
"""
## Paletli kart atlasının ölçüleri: hücre (piksel ve metre), sütun (yön), kare (satır öbeği), başlık biçimi, ayağın hücredeki yeri, eğim.
const PUPPET_CELL := Vector2i(32, 64)
const PUPPET_CELL_M := Vector2(1.1, 2.2)
const PUPPET_DIRS := 8
const PUPPET_FRAMES := 8
const PUPPET_WALK_FRAMES := 6
const PUPPET_FRAME_STAND := 6
const PUPPET_FRAME_SIT := 7
const PUPPET_PIVOT := 0.12
const PUPPET_ELEVATION := 38.0

## Örnek başına sayılar: kartta 12 dönüşüm + 4 renk + 4 özel, lekede 12 + 4.
const CARD_FLOATS := 20
const BLOB_FLOATS := 16
## Temas lekesinin boyu (m; en, derinlik) ve yerden yüksekliği.
const BLOB_SIZE := Vector2(0.95, 0.75)
const BLOB_LIFT := 0.035
## Duranın kendi kendine dönüşü: aralık (sn), en büyük sapma (derece), dönüş hızı (rad/sn).
const IDLE_TURN_EVERY := Vector2(5.0, 13.0)
const IDLE_TURN_DEG := 38.0
const TURN_RATE := 2.4
## İzlenen noktaya dönüş: en uzak kişi (m) ve en çok gecikme (sn).
const WATCH_RANGE := 90.0
const WATCH_DELAY := 1.3
## Rengin aydınlık aralığı (kişi kişi).
const SHADE := Vector2(0.84, 1.07)

## Plan (CrowdPlan.build), zemin (height_at) ve atlasın ölçüleri (dailin_cards.json).
var plan: Array[Dictionary] = []
var shape: RefCounted
var meta: Dictionary = {}
## Oyunun dakikası (kişilerin planı bundan).
var minute := 0.0
## Kişinin en yüksek hızı (m/sn; E20: oyuncunun koşusu, Çocukluk'ta çocuğunki) ve yürüyenlerin ölçülen en yüksek hızı.
var speed_cap := PaceLimit.CHILD_RUN
var peak_speed := 0.0

var _cards: MultiMeshInstance3D
var _blobs: MultiMeshInstance3D
var _card_buf := PackedFloat32Array()
var _blob_buf := PackedFloat32Array()
# Kişi başına sıcak veri (sözlük yerine dizi: kare başına GDScript işi az kalsın).
var _spots := PackedVector2Array()
var _heights := PackedFloat32Array()
var _from := PackedFloat32Array()
var _to := PackedFloat32Array()
var _early := PackedByteArray()
var _yaw0 := PackedFloat32Array()
var _scales := PackedFloat32Array()
var _shades := PackedFloat32Array()
var _seeds := PackedFloat32Array()
var _bases := PackedInt32Array()
var _shown := PackedFloat32Array()
var _idle := PackedFloat32Array()
var _idle_left := PackedFloat32Array()
var _cycles := PackedFloat32Array()
# Son yazılan hâl, yön ve kare: değişmeyen kişi yeniden yazılmaz.
var _w_state := PackedByteArray()
var _w_yaw := PackedFloat32Array()
var _watch := Vector3.INF
var _watch_time := 0.0
var _rng := RandomNumberGenerator.new()
var _frames := 5
var _dirs := 8
# Kişinin gerçekte yürüdüğü yol (m), kendi hızı (m/sn) ve ilk yazışta plana oturtma.
var _walked := PackedFloat32Array()
var _own := PackedFloat32Array()
var _snap := true


## Kurar (ağaca eklemeden önce ya da sonra): plan, zemin, atlasın ölçüleri ve iki dokusu. heights (yerlerin zemin yüksekliği) ve bounds
## (kırpma kutusu) iş parçacığında önceden hesaplandıysa verilir (CrowdPlan.heights, CrowdPlan.bounds): ana iş parçacığında kurulum kısa kalır.
func setup(p_plan: Array[Dictionary], p_shape: RefCounted, p_meta: Dictionary, albedo: Texture2D, normal: Texture2D,
		heights: PackedFloat32Array = PackedFloat32Array(), bounds: AABB = AABB()) -> void:
	plan = p_plan
	shape = p_shape
	meta = p_meta
	_rng.seed = 2280
	_frames = (meta.get("frames", ["idle"]) as Array).size()
	_dirs = int(meta.get("dirs", 8))
	var n := plan.size()
	# Paketli diziler değer türüdür: her biri kendi adıyla boyutlanır.
	_heights.resize(n)
	_from.resize(n)
	_to.resize(n)
	_yaw0.resize(n)
	_scales.resize(n)
	_shades.resize(n)
	_seeds.resize(n)
	_shown.resize(n)
	_idle.resize(n)
	_idle_left.resize(n)
	_cycles.resize(n)
	_w_yaw.resize(n)
	_spots.resize(n)
	_early.resize(n)
	_bases.resize(n)
	_w_state.resize(n)
	_walked.resize(n)
	_own.resize(n)
	_snap = true
	var cycle_by: Dictionary = meta.get("walk_cycle_m", {})
	var variants: Array = meta.get("variants", [])
	for i in n:
		var p := plan[i]
		var spot: Vector2 = p["spot"]
		_spots[i] = spot
		_heights[i] = heights[i] if i < heights.size() else _height(spot.x, spot.y)
		_from[i] = float(p["from"])
		_to[i] = float(p["to"])
		_early[i] = 1 if bool(p["early"]) else 0
		_yaw0[i] = float(p["yaw"])
		_scales[i] = float(p["scale"])
		_shades[i] = lerpf(SHADE.x, SHADE.y, float(p["shade"]))
		_seeds[i] = float(p["seed"])
		var variant := int(p["variant"])
		_bases[i] = variant * _frames * _dirs
		_shown[i] = _yaw0[i]
		_idle_left[i] = _rng.randf_range(0.0, IDLE_TURN_EVERY.y)
		var vname := str(variants[variant]) if variant < variants.size() else ""
		_cycles[i] = maxf(float(cycle_by.get(vname, 1.5)), 0.3)
		_w_state[i] = 255
		_own[i] = CrowdPlan.own_speed(p)
		_walked[i] = 0.0
	_card_buf.resize(n * CARD_FLOATS)
	_blob_buf.resize(n * BLOB_FLOATS)
	_build_nodes(albedo, normal, bounds if bounds.size != Vector3.ZERO else CrowdPlan.bounds(plan, shape))


## Kaç kişi var (planda).
func size() -> int:
	return plan.size()


## Oyunun dakikası: planda kişiler bu ana göre yerinde, yolda ya da yok (gerçek yolları plana yetişir).
func set_minute(m: float) -> void:
	minute = m


## Sonraki yazışta herkes planın yerine oturur (sahne atlanan adımdan başlayınca: saat ileri kurulur, kimse yetişmek için yürümez).
func snap() -> void:
	_snap = true


## Kalabalığın bakacağı nokta (Vector3.INF: kendi hâline).
func watch(point: Vector3) -> void:
	if point == Vector3.INF:
		_watch = Vector3.INF
		return
	if _watch == Vector3.INF:
		_watch_time = 0.0
	_watch = point


func is_watching() -> bool:
	return _watch != Vector3.INF


## Şu anki sayılar (görünen; kişilerin gerçek yolundan): {standing, walking, absent}.
func counts() -> Dictionary:
	var out := {"standing": 0, "walking": 0, "absent": 0}
	for i in plan.size():
		match _state_of(i):
			CrowdPlan.State.STAND:
				out["standing"] += 1
			CrowdPlan.State.WALK:
				out["walking"] += 1
			_:
				out["absent"] += 1
	return out


## Planın sayıları (oyunun dakikasında herkes nerede olmalı).
func planned_counts() -> Dictionary:
	return CrowdPlan.counts(plan, minute)


## Kişinin gerçekte yürüdüğü yol (m; sınama).
func walked(i: int) -> float:
	return _walked[i] if i >= 0 and i < _walked.size() else 0.0


## Kişinin görünen hâli: erken gelen ve yolunu bitiren duruyor; yola çıkan (ya da planda çıkmış olan) yürüyor; öteki yok.
func _state_of(i: int) -> CrowdPlan.State:
	var length := float(plan[i]["length"])
	if _early[i] == 1 or (_walked[i] >= length - 0.0001 and minute > _from[i]):
		return CrowdPlan.State.STAND
	if _walked[i] > 0.0 or minute > _from[i]:
		return CrowdPlan.State.WALK
	return CrowdPlan.State.ABSENT


## Kartın gösterdiği yön (sınama).
func shown_yaw(i: int) -> float:
	return _shown[i]


## Kart çizimi (sınama ve bütçe).
func cards_node() -> MultiMeshInstance3D:
	return _cards


func _process(delta: float) -> void:
	if plan.is_empty() or _cards == null:
		return
	if _watch != Vector3.INF:
		_watch_time += delta
	_write(delta)


## Gölgelendiriciler bir kez derlenir (sınamalar ve dünya değişimi yeniden kurar).
static var _card_shader: Shader
static var _blob_shader: Shader


static func card_shader() -> Shader:
	if _card_shader == null:
		_card_shader = Shader.new()
		_card_shader.code = CARD_CODE
	return _card_shader


static func blob_shader() -> Shader:
	if _blob_shader == null:
		_blob_shader = Shader.new()
		_blob_shader.code = BLOB_CODE
	return _blob_shader


static var _palette_card_shader: Shader
## Kuklanın kart atlası (bake_puppet_atlas; koşu boyunca bir kez pişer, dünyalar arasında kalır).
static var _puppet_atlas: Dictionary = {}


static func palette_card_shader() -> Shader:
	if _palette_card_shader == null:
		_palette_card_shader = Shader.new()
		_palette_card_shader.code = PALETTE_CARD_CODE
	return _palette_card_shader


## Paletli kartın malzemesi (atlas bake_puppet_atlas'tan; atlas yoksa, başsızda, maske boştur: kart çizilmez).
static func palette_card_material(palette: Texture2D, atlas: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CrowdCards.palette_card_shader()
	mat.set_shader_parameter(&"palette", palette)
	mat.set_shader_parameter(&"palette_cols", CrowdPuppet.PALETTE_COLS)
	mat.set_shader_parameter(&"palette_slots", CrowdPuppet.PALETTE_SLOTS)
	mat.set_shader_parameter(&"grid", Vector2(PUPPET_DIRS, PUPPET_FRAMES * Folk.PUPPET_HATS.size()))
	mat.set_shader_parameter(&"cell_m", PUPPET_CELL_M)
	mat.set_shader_parameter(&"pivot", PUPPET_PIVOT)
	mat.set_shader_parameter(&"dirs", float(PUPPET_DIRS))
	if atlas.has("mask"):
		mat.set_shader_parameter(&"mask_atlas", atlas["mask"])
		mat.set_shader_parameter(&"normal_atlas", atlas["normal"])
	return mat


## Kartın hücresinin başı (saf): başlık biçimi ve kare (satır), yön sütunu gölgelendiricide eklenir.
static func puppet_cell(variant: int, frame: int) -> int:
	return (variant * PUPPET_FRAMES + clampi(frame, 0, PUPPET_FRAMES - 1)) * PUPPET_DIRS


## Yürüyüşün karesi (saf): evre (0..1) → 0..PUPPET_WALK_FRAMES-1.
static func walk_frame(phase: float) -> int:
	return clampi(int(floor(fposmod(phase, 1.0) * PUPPET_WALK_FRAMES)), 0, PUPPET_WALK_FRAMES - 1)


## Atlasın ızgarası (saf): [sütun, satır] ve piksel boyu.
static func puppet_atlas_size() -> Vector2i:
	return Vector2i(PUPPET_DIRS * PUPPET_CELL.x, PUPPET_FRAMES * Folk.PUPPET_HATS.size() * PUPPET_CELL.y)


## Hücrede kuklanın yeri (saf; pişirme): ortografik kameranın sağ ve yukarı eksenlerinde, ayak hücrenin alttan PUPPET_PIVOT'unda.
static func puppet_cell_offset(dir: int, row: int) -> Vector2:
	var size := CrowdCards.puppet_atlas_size()
	var mpp := PUPPET_CELL_M.y / float(PUPPET_CELL.y)
	var x_px := (float(dir) + 0.5) * PUPPET_CELL.x - size.x * 0.5
	var feet_px := (float(row) + 1.0) * PUPPET_CELL.y - PUPPET_PIVOT * PUPPET_CELL.y
	return Vector2(x_px * mpp, (size.y * 0.5 - feet_px) * mpp)


## Kuklanın kart atlasını pişirir (beklenebilir; army.md §7.4: açılışta bir SubViewport'ta, bir kez): iki görüntü alanı (maske ve
## normal) aynı karede çizer; 8 yön × 8 kare × üç başlık, hepsi tek MultiMesh'in örnekleri (kişi yönüyle döner, kamera sabittir:
## ortografikte ikisi aynıdır). Kamera oyunun kadrajının eğimindedir (PUPPET_ELEVATION). Görüntüler mipmap'lenir. Başsızda çizici yoktur:
## boş sözlük döner (kart kademesi çizilmez, kademe seçimi sürer). Sonuç önbellektedir. Döner: {mask, normal, ms (süre)}.
static func bake_puppet_atlas(host: Node) -> Dictionary:
	if not _puppet_atlas.is_empty():
		return _puppet_atlas
	if host == null or not host.is_inside_tree() or DisplayServer.get_name() == "headless":
		return {}
	var started := Time.get_ticks_usec()
	var size := CrowdCards.puppet_atlas_size()
	var palette := ImageTexture.create_from_image(CrowdPuppet.palette_image([PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE,
		Color.WHITE, Color.WHITE, Color.WHITE])]))
	var ports: Array[SubViewport] = []
	for kind in ["mask", "normal"]:
		var vp := SubViewport.new()
		vp.name = "PuppetAtlas_" + kind
		vp.size = size
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_4X
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		var we := WorldEnvironment.new()
		we.environment = env
		vp.add_child(we)
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.size = PUPPET_CELL_M.y / float(PUPPET_CELL.y) * size.y
		cam.near = 0.05
		cam.far = 200.0
		var el := deg_to_rad(PUPPET_ELEVATION)
		var to_cam := Vector3(0.0, sin(el), cos(el))
		cam.transform = Transform3D(Basis(), to_cam * 60.0).looking_at(Vector3.ZERO, Vector3.UP)
		vp.add_child(cam)
		var right := cam.transform.basis.x
		var up := cam.transform.basis.y
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = CrowdPuppet.mesh(CrowdPuppet.DETAIL_T1)
		var hats := Folk.PUPPET_HATS.size()
		mm.instance_count = hats * PUPPET_FRAMES * PUPPET_DIRS
		var k := 0
		for v in hats:
			for f in PUPPET_FRAMES:
				var row := v * PUPPET_FRAMES + f
				var gait := 1.0
				var phase := float(f) / PUPPET_WALK_FRAMES
				if f == PUPPET_FRAME_STAND:
					gait = 0.0
					phase = 0.0
				elif f == PUPPET_FRAME_SIT:
					gait = CrowdPuppet.POSE_SIT
					phase = 0.0
				for d in PUPPET_DIRS:
					var off := CrowdCards.puppet_cell_offset(d, row)
					var at := right * off.x + up * off.y
					# Yön d: kamera kişinin önünden sola doğru d × 45° (kartın sütunu; atan2(x, z) artar).
					mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, -TAU * float(d) / PUPPET_DIRS), at))
					mm.set_instance_custom_data(k, CrowdPuppet.custom(phase, gait, 0, v, 1.0))
					k += 1
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = CrowdPuppet.material(palette, kind)
		mi.custom_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
		vp.add_child(mi)
		host.add_child(vp)
		ports.append(vp)
	for vp in ports:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var images: Array[Image] = []
	for vp in ports:
		var img: Image = vp.get_texture().get_image() if is_instance_valid(vp) else null
		images.append(img)
		if is_instance_valid(vp):
			vp.queue_free()
	if images[0] == null or images[0].is_empty() or images[1] == null or images[1].is_empty():
		return {}
	var out := {}
	for i in 2:
		var img := images[i]
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		img.generate_mipmaps()
		out["mask" if i == 0 else "normal"] = ImageTexture.create_from_image(img)
	out["ms"] = (Time.get_ticks_usec() - started) / 1000.0
	out["size"] = size
	_puppet_atlas = out
	return out


## Pişmiş atlas (yoksa boş).
static func puppet_atlas() -> Dictionary:
	return _puppet_atlas


## Kuklanın atlasını ve paletli kartın gölgelendiricisini bırakır (son kalabalık alanı ağaçtan çıkınca): bir sonraki dünya yeniden pişirir.
static func release_puppet_atlas() -> void:
	_puppet_atlas = {}
	_palette_card_shader = null


func _build_nodes(albedo: Texture2D, normal: Texture2D, box: AABB) -> void:
	for child in get_children():
		child.queue_free()
	var n := plan.size()
	var cell_px: Array = meta.get("cell_px", [128, 256])
	var atlas_px: Array = meta.get("atlas_px", [2048, 2048])
	var cell_m: Array = meta.get("cell_m", [1.1, 2.2])
	var mat := ShaderMaterial.new()
	mat.shader = CrowdCards.card_shader()
	mat.set_shader_parameter("albedo_atlas", albedo)
	mat.set_shader_parameter("normal_atlas", normal)
	mat.set_shader_parameter("cell_px", Vector2(float(cell_px[0]), float(cell_px[1])))
	mat.set_shader_parameter("atlas_px", Vector2(float(atlas_px[0]), float(atlas_px[1])))
	mat.set_shader_parameter("cols", float(meta.get("cols", 16)))
	mat.set_shader_parameter("cell_m", Vector2(float(cell_m[0]), float(cell_m[1])))
	mat.set_shader_parameter("pivot", float(meta.get("pivot", 0.18)))
	mat.set_shader_parameter("dirs", float(meta.get("dirs", 8)))
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_cards = _multimesh("Cards", quad, mat, n)
	var blob_mat := ShaderMaterial.new()
	blob_mat.shader = CrowdCards.blob_shader()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	_blobs = _multimesh("Blobs", plane, blob_mat, n)
	_cards.custom_aabb = box
	_blobs.custom_aabb = box


func _multimesh(node_name: String, mesh: Mesh, mat: Material, n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = node_name == "Cards"
	mm.mesh = mesh
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.name = node_name
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## Örnekleri yazar: hâl dakikadan, yön (bekleme dönüşü, izleme) her kare; değişmeyen kişi yeniden yazılmaz, hiçbiri değişmediyse
## ekran kartına bir şey gitmez.
func _write(delta: float) -> void:
	var watching := _watch != Vector3.INF
	var changed := false
	var turn := TURN_RATE * delta
	var snapping := _snap
	_snap = false
	for i in plan.size():
		# Gerçek yol: ilk yazışta plana oturur, sonra plana kendi hızıyla (gerideyse HURRY katıyla, en çok speed_cap) yetişir (E20).
		var p := plan[i]
		var length := float(p["length"])
		if _early[i] == 0:
			var planned := CrowdPlan.planned_walked(p, minute)
			var before := _walked[i]
			if snapping:
				_walked[i] = planned
			else:
				_walked[i] = CrowdPlan.chase(before, planned, length, _own[i], speed_cap, CrowdPlan.HURRY, delta)
				if delta > 0.0:
					peak_speed = maxf(peak_speed, (_walked[i] - before) / delta)
		var state := _state_of(i)
		if state == CrowdPlan.State.ABSENT:
			if _w_state[i] != CrowdPlan.State.ABSENT:
				_w_state[i] = CrowdPlan.State.ABSENT
				_put_card(i * CARD_FLOATS, Vector3.ZERO, 0.0, 0.0, 0.0, Color(0, 0, 0, 0))
				_put_blob(i * BLOB_FLOATS, Vector3.ZERO, 0.0, 0.0, 0.0)
				changed = true
			continue
		if state == CrowdPlan.State.WALK:
			var on := CrowdPlan.point_on(p["path"], _walked[i])
			var xz: Vector2 = on["xz"]
			var at := Vector3(xz.x, _height(xz.x, xz.y), xz.y)
			_shown[i] = float(on["yaw"])
			var frame := clampi(1 + int(floor(fposmod(_walked[i] / _cycles[i] + _seeds[i], 1.0) * 4.0)), 1, _frames - 1)
			var presence := clampf(_walked[i] / CrowdPlan.FADE_IN_M, 0.0, 1.0)
			_put_card(i * CARD_FLOATS, at, _scales[i], _shown[i], float(_bases[i] + frame * _dirs), _tint(i, presence))
			_put_blob(i * BLOB_FLOATS, at + Vector3.UP * BLOB_LIFT, _scales[i], _shown[i], presence)
			_w_state[i] = CrowdPlan.State.WALK
			changed = true
			continue
		# Duran: izlenen noktaya ya da kendi yönüne (ara ara dönerek).
		var spot := _spots[i]
		var want := _yaw0[i]
		if watching and Vector2(_watch.x - spot.x, _watch.z - spot.y).length_squared() <= WATCH_RANGE * WATCH_RANGE and _watch_time >= _seeds[i] * WATCH_DELAY:
			want = atan2(_watch.x - spot.x, _watch.z - spot.y)
		else:
			_idle_left[i] -= delta
			if _idle_left[i] <= 0.0:
				_idle_left[i] = _rng.randf_range(IDLE_TURN_EVERY.x, IDLE_TURN_EVERY.y)
				_idle[i] = deg_to_rad(_rng.randf_range(-IDLE_TURN_DEG, IDLE_TURN_DEG))
			want += _idle[i]
		_shown[i] = _turn_toward(_shown[i], want, turn)
		if _w_state[i] != CrowdPlan.State.STAND or absf(angle_difference(_shown[i], _w_yaw[i])) > 0.01:
			var at := Vector3(spot.x, _heights[i], spot.y)
			_put_card(i * CARD_FLOATS, at, _scales[i], _shown[i], float(_bases[i]), _tint(i, 1.0))
			_put_blob(i * BLOB_FLOATS, at + Vector3.UP * BLOB_LIFT, _scales[i], _shown[i], 1.0)
			_w_state[i] = CrowdPlan.State.STAND
			_w_yaw[i] = _shown[i]
			changed = true
	if changed:
		_cards.multimesh.buffer = _card_buf
		_blobs.multimesh.buffer = _blob_buf


func _tint(i: int, presence: float) -> Color:
	var shade := _shades[i]
	return Color(shade, shade * 0.985, shade * 0.965, presence)


func _put_card(o: int, at: Vector3, scale: float, yaw: float, base: float, color: Color) -> void:
	_card_buf[o + 0] = scale
	_card_buf[o + 1] = 0.0
	_card_buf[o + 2] = 0.0
	_card_buf[o + 3] = at.x
	_card_buf[o + 4] = 0.0
	_card_buf[o + 5] = scale
	_card_buf[o + 6] = 0.0
	_card_buf[o + 7] = at.y
	_card_buf[o + 8] = 0.0
	_card_buf[o + 9] = 0.0
	_card_buf[o + 10] = scale
	_card_buf[o + 11] = at.z
	_card_buf[o + 12] = color.r
	_card_buf[o + 13] = color.g
	_card_buf[o + 14] = color.b
	_card_buf[o + 15] = color.a
	_card_buf[o + 16] = yaw
	_card_buf[o + 17] = base
	_card_buf[o + 18] = 0.0
	_card_buf[o + 19] = 0.0


func _put_blob(o: int, at: Vector3, scale: float, yaw: float, presence: float) -> void:
	var basis := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(BLOB_SIZE.x * scale, 1.0, BLOB_SIZE.y * scale))
	_blob_buf[o + 0] = basis.x.x
	_blob_buf[o + 1] = basis.y.x
	_blob_buf[o + 2] = basis.z.x
	_blob_buf[o + 3] = at.x
	_blob_buf[o + 4] = basis.x.y
	_blob_buf[o + 5] = basis.y.y
	_blob_buf[o + 6] = basis.z.y
	_blob_buf[o + 7] = at.y
	_blob_buf[o + 8] = basis.x.z
	_blob_buf[o + 9] = basis.y.z
	_blob_buf[o + 10] = basis.z.z
	_blob_buf[o + 11] = at.z
	_blob_buf[o + 12] = 0.0
	_blob_buf[o + 13] = 0.0
	_blob_buf[o + 14] = 0.0
	_blob_buf[o + 15] = presence


static func _turn_toward(from: float, to: float, step: float) -> float:
	var d := angle_difference(from, to)
	return from + clampf(d, -step, step)


func _height(x: float, z: float) -> float:
	return float(shape.call(&"height_at", x, z)) if shape else 0.0
