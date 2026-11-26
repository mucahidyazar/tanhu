class_name CrowdPuppet
extends RefCounted
## Kalabalığın kuklası (T1 ve T2; Yol Haritası crowd-tiers; army.md §7.1, §7.3; godot.md §4.5): tek ağlı yaya kukla, parça kimliği köşede,
## yürüyüş evresi ve hızı INSTANCE_CUSTOM'da, canlandırma köşe gölgelendiricisinde (prototipin aPart ve aGait'i). Ağ kodla kurulur (sanat
## kodladır): gövde ve kaftan (döner yüzey), kollar, iki parçalı bacaklar, çizmeler, baş, saç ve üç başlık (sivri Saka başlığı, kürk başlık,
## bant). Köşe rengi: R paletin yuvası (Folk.SLOT_*; × 8), G parça kimliği (× 16), B gölge payı (bakılmış kapanma), A 1. Kişinin renkleri
## palet dokusundandır (Folk.palette; CrowdField kurar): kişi başına sekiz piksel, köşe gölgelendiricisi texelFetch ile okur.
##
## Örnek verisi (MultiMesh, TRANSFORM_3D, use_custom_data; renk yok):
##   dönüşüm  konum, yön, ölçek (boy y'de, yapı x ve z'de)
##   CUSTOM.x yürüyüş evresi (adım döngüsü; yürünen yoldan: ayak kaymaz)
##   CUSTOM.y yürüyüş: ≥0 hızın payı (0 durur, 1 yürür, >1 koşar), POSE_SIT oturur, POSE_WORK iş yapar (kollar iner kalkar)
##   CUSTOM.z görünüşün palet sırası
##   CUSTOM.w başlık biçimi × 2 + varlık (0..1; belirerek gelir: dağınık piksel)
## T1 tek çizimdir: üç başlık aynı ağdadır, kişinin olmayan başlığı köşe gölgelendiricisinde başın içine çöker (üçgen çizilmez); gölgesi en
## yakın 24 kişinin ayrı, yalnız gölge düşüren örneğidir. T2 kaba ağdır (≤360 üçgen, başlıksız: başın üstü başlığın renginde), tek çizim.
## Kart kademesinin (T3) atlası bu kuklanın T1 ağından açılışta bir SubViewport'ta pişer (CrowdCards.bake_puppet_atlas): maske ve normal
## gölgelendiricisi aynı koddan, ön işlemci tanımıyla (BAKE_MASK, BAKE_NORMAL).
##   var mesh := CrowdPuppet.mesh(CrowdPuppet.DETAIL_T1)
##   var mat := CrowdPuppet.material(palette_texture)

## Parçalar (köşenin G'si × 16).
const PART_BODY := 0
const PART_THIGH_L := 1
const PART_SHIN_L := 2
const PART_THIGH_R := 3
const PART_SHIN_R := 4
const PART_ARM_L := 5
const PART_ARM_R := 6
const PART_HEAD := 7
const PART_HAT_CAP := 8
const PART_HAT_FUR := 9
const PART_HAT_BAND := 10
## Duruşlar (CUSTOM.y).
const POSE_SIT := -1.0
const POSE_WORK := -2.0
## Ayrıntı düzeyleri.
const DETAIL_T1 := 1
const DETAIL_T2 := 2
## Üçgen sınırları (army.md §7.1: kukla binici ≤1.200, kaba ağ ≤360).
const T1_MAX_TRIANGLES := 1200
const T2_MAX_TRIANGLES := 360
## Paletin satırındaki görünüş sayısı ve görünüş başına piksel.
const PALETTE_COLS := 64
const PALETTE_SLOTS := 8
## Bedenin ölçüleri (m; 1,70 m'lik kişi, ölçek boyla çarpılır): kalça, diz, omuz, boyun, başın merkezi ve yarıçapı.
const HIP_Y := 0.9
const KNEE_Y := 0.48
const ANKLE_Y := 0.07
const HIP_X := 0.095
const SHOULDER_Y := 1.4
const SHOULDER_X := 0.205
const HAND_Y := 0.84
const NECK_Y := 1.46
const HEAD_Y := 1.575
const HEAD_R := 0.105
## Kuklanın boyu (m): örneğin y ölçeği kişinin boyu / BODY_HEIGHT.
const BODY_HEIGHT := 1.7
## Adımın boyu (m; yürüyüşte bir tam döngü iki adımdır): evre = yürünen yol / STRIDE.
const STRIDE := 1.45
const RUN_STRIDE := 2.4

const SHADER_CODE := """
shader_type spatial;
#if defined(BAKE_MASK) || defined(BAKE_NORMAL)
render_mode unshaded, cull_back, depth_draw_opaque;
#else
render_mode cull_back, depth_draw_opaque, specular_disabled;
#endif
uniform sampler2D palette : source_color, filter_nearest, repeat_disable;
uniform int palette_cols = 64;
uniform int palette_slots = 8;
// Başlıksız kaba ağda (T2) başın üstü: başlığı olan kişide başlığın rengi.
uniform bool coarse = false;
group_uniforms cel;
uniform float shadow_level : hint_range(0.0, 1.0) = 0.78;
uniform vec3 shadow_tint : source_color = vec3(1.0, 0.97, 0.9);
uniform float terminator = 0.05;
uniform float terminator_softness : hint_range(0.0, 0.6) = 0.14;
uniform float form_shading : hint_range(0.0, 0.5) = 0.12;
group_uniforms;
varying vec3 v_color;
varying float v_presence;
varying float v_slot;

vec3 rot_x(vec3 p, vec3 pivot, float a) {
	vec3 q = p - pivot;
	float c = cos(a);
	float s = sin(a);
	return pivot + vec3(q.x, q.y * c - q.z * s, q.y * s + q.z * c);
}
vec3 rot_y(vec3 p, vec3 pivot, float a) {
	vec3 q = p - pivot;
	float c = cos(a);
	float s = sin(a);
	return pivot + vec3(q.x * c + q.z * s, q.y, -q.x * s + q.z * c);
}
vec3 rot_z(vec3 p, vec3 pivot, float a) {
	vec3 q = p - pivot;
	float c = cos(a);
	float s = sin(a);
	return pivot + vec3(q.x * c - q.y * s, q.x * s + q.y * c, q.z);
}

void vertex() {
	float part = round(COLOR.g * 16.0);
	float slot = round(COLOR.r * 8.0);
	float ao = COLOR.b;
	vec4 c = INSTANCE_CUSTOM;
	float variant = floor(c.w * 0.5);
	float presence = clamp(c.w - variant * 2.0, 0.0, 1.0);
	float look = c.z;
	float seed = fract(look * 0.6180339 + 0.13);
#if defined(BAKE_MASK) || defined(BAKE_NORMAL)
	float t = 0.0;
#else
	float t = TIME;
#endif
	// Kişinin olmayan başlığı başın içine çöker.
	if (part >= 8.0 && part - 8.0 != variant) {
		VERTEX = vec3(0.0, HEAD_Y_, 0.0);
	}
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	float gait = c.y;
	float ph = c.x * 6.2831853;
	vec3 hip_l = vec3(HIP_X_, HIP_Y_, 0.0);
	vec3 hip_r = vec3(-HIP_X_, HIP_Y_, 0.0);
	vec3 knee_l = vec3(HIP_X_, KNEE_Y_, 0.0);
	vec3 knee_r = vec3(-HIP_X_, KNEE_Y_, 0.0);
	vec3 sh_l = vec3(SHOULDER_X_, SHOULDER_Y_, 0.0);
	vec3 sh_r = vec3(-SHOULDER_X_, SHOULDER_Y_, 0.0);
	vec3 neck = vec3(0.0, NECK_Y_, 0.0);
	bool left_leg = part == 1.0 || part == 2.0;
	bool right_leg = part == 3.0 || part == 4.0;
	bool shin = part == 2.0 || part == 4.0;
	bool head = part >= 7.0;
	if (gait >= 0.0) {
		float walk = clamp(gait, 0.0, 1.7);
		float stride = 0.44 * min(walk, 1.0) + 0.2 * max(walk - 1.0, 0.0);
		float side = left_leg ? 0.0 : 3.14159265;
		float leg_ph = ph + side;
		if (left_leg || right_leg) {
			vec3 hip = left_leg ? hip_l : hip_r;
			vec3 knee = left_leg ? knee_l : knee_r;
			float thigh = stride * sin(leg_ph);
			float bend = (0.15 + 0.75 * walk) * max(0.0, sin(leg_ph + 1.7)) * min(walk * 2.0, 1.0);
			// Pozitif açı ayağı geriye atar (+Z öndür): diz büküldükçe baldır geriye.
			if (shin) {
				v = rot_x(v, knee, bend);
				n = rot_x(n, vec3(0.0), bend);
			}
			v = rot_x(v, hip, thigh);
			n = rot_x(n, vec3(0.0), thigh);
		}
		if (part == 5.0 || part == 6.0) {
			vec3 sh = part == 5.0 ? sh_l : sh_r;
			float arm_ph = ph + (part == 5.0 ? 3.14159265 : 0.0);
			float swing = (0.06 + 0.5 * min(walk, 1.2)) * sin(arm_ph);
			if (walk < 0.05) {
				swing = 0.04 * sin(t * 1.3 + seed * 6.0 + part);
			}
			v = rot_x(v, sh, swing);
			n = rot_x(n, vec3(0.0), swing);
			float abduct = (part == 5.0 ? 1.0 : -1.0) * 0.06;
			v = rot_z(v, sh, abduct);
			n = rot_z(n, vec3(0.0), abduct);
		}
		if (head && walk < 0.05) {
			// Duran kişi ara ara başını çevirir.
			float look_around = 0.35 * sin(t * 0.21 + seed * 40.0) * smoothstep(0.2, 0.9, sin(t * 0.13 + seed * 17.0));
			v = rot_y(v, neck, look_around);
			n = rot_y(n, vec3(0.0), look_around);
		}
		// Adımda gövde iner kalkar, koşuda öne eğilir; duranın nefesi.
		float bob = 0.028 * min(walk, 1.4) * (abs(sin(ph)) - 0.5);
		float breathe = walk < 0.05 ? 0.004 * sin(t * 1.6 + seed * 9.0) : 0.0;
		if (!(left_leg || right_leg)) {
			v.y += breathe * (v.y - HIP_Y_);
		}
		v.y += bob;
		float lean = 0.05 * min(walk, 1.0) + 0.12 * max(walk - 1.0, 0.0);
		v = rot_x(v, vec3(0.0), lean);
		n = rot_x(n, vec3(0.0), lean);
	} else if (gait > -1.5) {
		// Yerde oturur: dizler kalkık, ayaklar önde; gövde iner.
		if (left_leg || right_leg) {
			vec3 hip = left_leg ? hip_l : hip_r;
			vec3 knee = left_leg ? knee_l : knee_r;
			float spread = (left_leg ? 1.0 : -1.0) * 0.32;
			if (shin) {
				v = rot_x(v, knee, 1.7);
				n = rot_x(n, vec3(0.0), 1.7);
			}
			v = rot_x(v, hip, -2.0);
			n = rot_x(n, vec3(0.0), -2.0);
			v = rot_y(v, hip, spread);
			n = rot_y(n, vec3(0.0), spread);
		}
		if (part == 5.0 || part == 6.0) {
			vec3 sh = part == 5.0 ? sh_l : sh_r;
			v = rot_x(v, sh, -0.75);
			n = rot_x(n, vec3(0.0), -0.75);
		}
		if (head) {
			float look_around = 0.3 * sin(t * 0.17 + seed * 31.0);
			v = rot_y(v, neck, look_around);
			n = rot_y(n, vec3(0.0), look_around);
		}
		v.y -= HIP_Y_ - 0.14;
		v = rot_x(v, vec3(0.0, 0.14, 0.0), -0.08);
	} else {
		// İş: gövde öne eğilir, kollar birlikte iner kalkar (kazma, çekiç, kürek): aşağıdan öne, yarım daire.
		float beat = sin(t * 2.6 + seed * 12.0);
		if (part == 5.0 || part == 6.0) {
			vec3 sh = part == 5.0 ? sh_l : sh_r;
			float a = -(0.45 + 0.4 * beat);
			v = rot_x(v, sh, a);
			n = rot_x(n, vec3(0.0), a);
		}
		float lean = 0.34 + 0.1 * beat;
		v = rot_x(v, vec3(0.0, HIP_Y_, 0.0), lean * (v.y > HIP_Y_ - 0.05 && !(left_leg || right_leg) ? 1.0 : 0.0));
		n = rot_x(n, vec3(0.0), lean * (v.y > HIP_Y_ - 0.05 && !(left_leg || right_leg) ? 1.0 : 0.0));
	}
	VERTEX = v;
	NORMAL = normalize(n);
	// Rengin yuvası: kaba ağda başın üstü başlığı olan kişide başlığın rengi.
	if (coarse && slot == 3.0 && variant < 1.5) {
		slot = 4.0;
	}
	int look_i = int(look + 0.5);
	ivec2 texel = ivec2((look_i % palette_cols) * palette_slots + int(slot), look_i / palette_cols);
	v_color = texelFetch(palette, texel, 0).rgb * ao;
	v_presence = presence;
	v_slot = slot;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 to_linear(vec3 col) {
	return mix(col / 12.92, pow((col + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), col));
}

void fragment() {
	if (hash(floor(FRAGCOORD.xy)) > v_presence) {
		discard;
	}
#if defined(BAKE_MASK)
	// Kartın maskesi: R giysi ve kenar şeridi, G ten, B başlık; öbürü (saç, çizme) koyu.
	float s = v_slot;
	vec3 m = vec3(s < 1.5 ? 1.0 : 0.0, s > 1.5 && s < 2.5 ? 1.0 : 0.0, s > 3.5 && s < 4.5 ? 1.0 : 0.0);
	ALBEDO = to_linear(m);
#elif defined(BAKE_NORMAL)
	ALBEDO = to_linear(normalize(NORMAL) * 0.5 + 0.5);
#else
	ALBEDO = v_color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
#endif
}

#if !defined(BAKE_MASK) && !defined(BAKE_NORMAL)
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
#endif
"""

static var _shaders: Dictionary = {}
static var _meshes: Dictionary = {}


## Önbelleği bırakır (son kalabalık alanı ağaçtan çıkınca; CrowdField): ağlar ve gölgelendiriciler bir sonraki istekte yeniden kurulur.
static func release_cache() -> void:
	_shaders.clear()
	_meshes.clear()


## Gölgelendirici (önbellekli): "" oyunun, "mask" ve "normal" kart atlasının pişirmesi.
static func shader(kind: String = "") -> Shader:
	if _shaders.has(kind):
		return _shaders[kind]
	var code := SHADER_CODE
	for pair: Array in [["HEAD_Y_", HEAD_Y], ["HIP_X_", HIP_X], ["HIP_Y_", HIP_Y], ["KNEE_Y_", KNEE_Y], ["SHOULDER_X_", SHOULDER_X],
			["SHOULDER_Y_", SHOULDER_Y], ["NECK_Y_", NECK_Y]]:
		code = code.replace(str(pair[0]), "%.4f" % float(pair[1]))
	if kind == "mask":
		code = code.replace("shader_type spatial;", "shader_type spatial;\n#define BAKE_MASK")
	elif kind == "normal":
		code = code.replace("shader_type spatial;", "shader_type spatial;\n#define BAKE_NORMAL")
	var s := Shader.new()
	s.code = code
	_shaders[kind] = s
	return s


## Kuklanın malzemesi (palet dokusu; coarse: T2'nin başlıksız ağı).
static func material(palette: Texture2D, kind: String = "", coarse: bool = false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CrowdPuppet.shader(kind)
	mat.set_shader_parameter(&"palette", palette)
	mat.set_shader_parameter(&"palette_cols", PALETTE_COLS)
	mat.set_shader_parameter(&"palette_slots", PALETTE_SLOTS)
	mat.set_shader_parameter(&"coarse", coarse)
	return mat


## Palet dokusu (saf yardımcı): görünüş başına PALETTE_SLOTS piksel, satırda PALETTE_COLS görünüş (Folk.palette).
static func palette_image(looks: Array) -> Image:
	var rows := maxi(ceili(float(looks.size()) / PALETTE_COLS), 1)
	var img := Image.create_empty(PALETTE_COLS * PALETTE_SLOTS, rows, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.24, 0.18))
	for i in looks.size():
		var pal: PackedColorArray = looks[i] if looks[i] is PackedColorArray else Folk.palette(looks[i])
		var x0 := (i % PALETTE_COLS) * PALETTE_SLOTS
		var y := i / PALETTE_COLS
		for s in mini(pal.size(), PALETTE_SLOTS):
			img.set_pixel(x0 + s, y, pal[s])
	return img


## Örneğin CUSTOM'u (saf): evre, yürüyüş ya da duruş, palet sırası, başlık ve varlık.
static func custom(phase: float, gait: float, look: int, variant: int, presence: float) -> Color:
	return Color(fposmod(phase, 1.0), gait, float(look), float(variant) * 2.0 + clampf(presence, 0.0, 1.0))


## Ağ (önbellekli): DETAIL_T1 ya da DETAIL_T2.
static func mesh(detail: int = DETAIL_T1) -> ArrayMesh:
	if _meshes.has(detail):
		return _meshes[detail]
	var b := _Builder.new()
	var t1 := detail == DETAIL_T1
	var seg := 8 if t1 else 5
	# Bacaklar: uyluk (şalvar, çizmenin rengi), baldır ve çizme; ayak öne uzanır.
	for side: float in [1.0, -1.0]:
		var thigh := PART_THIGH_L if side > 0.0 else PART_THIGH_R
		var shin_part := PART_SHIN_L if side > 0.0 else PART_SHIN_R
		var x: float = HIP_X * side
		b.tube(Vector3(x, HIP_Y + 0.02, 0.0), Vector3(x, KNEE_Y, 0.0), 0.078, 0.06, seg, Folk.SLOT_BOOTS, thigh, 0.82)
		b.tube(Vector3(x, KNEE_Y, 0.0), Vector3(x, ANKLE_Y, 0.0), 0.058, 0.05, seg, Folk.SLOT_BOOTS, shin_part, 0.7)
		b.box(Vector3(x, 0.035, 0.04), Vector3(0.09, 0.07, 0.2), Folk.SLOT_BOOTS, shin_part, 0.6)
	# Gövde ve kaftan: omuzdan bele, belden eteğe (diz boyu); kuşak ve etek şeridi.
	var coat := [[SHOULDER_Y + 0.02, 0.12], [SHOULDER_Y - 0.04, 0.2], [1.18, 0.185], [1.0, 0.17], [0.78, 0.22], [0.52, 0.27]]
	if not t1:
		coat = [[SHOULDER_Y + 0.02, 0.13], [SHOULDER_Y - 0.04, 0.2], [1.0, 0.17], [0.52, 0.26]]
	b.lathe(coat, seg + (2 if t1 else 1), Folk.SLOT_COAT, PART_BODY, 1.0, true)
	b.lathe([[1.04, 0.178], [0.96, 0.176]], seg + 2 if t1 else seg + 1, Folk.SLOT_TRIM, PART_BODY, 0.85, false)
	if t1:
		b.lathe([[0.575, 0.252], [0.52, 0.272]], seg + 2, Folk.SLOT_TRIM, PART_BODY, 0.8, false)
		# Yaka: kaftanın üstünde şerit.
		b.lathe([[SHOULDER_Y + 0.045, 0.085], [SHOULDER_Y - 0.01, 0.15]], seg + 2, Folk.SLOT_TRIM, PART_BODY, 0.9, false)
	# Kollar: kolluk kaftanın rengi, el ten.
	for side: float in [1.0, -1.0]:
		var part := PART_ARM_L if side > 0.0 else PART_ARM_R
		var x: float = SHOULDER_X * side
		var elbow := Vector3(x * 1.08, 1.12, -0.02)
		b.tube(Vector3(x, SHOULDER_Y, 0.0), elbow, 0.062, 0.052, seg - (2 if t1 else 1), Folk.SLOT_COAT, part, 0.92)
		b.tube(elbow, Vector3(x * 1.1, HAND_Y + 0.05, 0.02), 0.052, 0.045, seg - (2 if t1 else 1), Folk.SLOT_COAT, part, 0.88)
		if t1:
			b.sphere(Vector3(x * 1.1, HAND_Y, 0.025), 0.042, 5, 4, Folk.SLOT_SKIN, part, 1.0)
	# Boyun ve baş; saç başın üst ve arka yarısı.
	b.tube(Vector3(0.0, NECK_Y - 0.03, 0.0), Vector3(0.0, HEAD_Y - 0.05, 0.0), 0.045, 0.045, 5 if t1 else 4, Folk.SLOT_SKIN, PART_HEAD, 0.85)
	b.sphere(Vector3(0.0, HEAD_Y, 0.01), HEAD_R, 8 if t1 else 5, 6 if t1 else 4, Folk.SLOT_SKIN, PART_HEAD, 1.0, Folk.SLOT_HAIR, 0.15)
	if t1:
		# Sivri Saka başlığı: başın üstünde, ucu öne eğik; kenarında şerit.
		b.lathe([[HEAD_Y + 0.02, HEAD_R + 0.012], [HEAD_Y + 0.13, 0.075], [HEAD_Y + 0.29, 0.012]], 8, Folk.SLOT_HAT, PART_HAT_CAP, 1.0, true,
			Vector3(0.0, 0.0, 0.03))
		b.lathe([[HEAD_Y + 0.045, HEAD_R + 0.016], [HEAD_Y + 0.005, HEAD_R + 0.016]], 8, Folk.SLOT_TRIM, PART_HAT_CAP, 0.9, false)
		# Kürk ve keçe başlık: yuvarlak tepe ve kalın kenar.
		b.lathe([[HEAD_Y + 0.0, HEAD_R + 0.03], [HEAD_Y + 0.07, HEAD_R + 0.03], [HEAD_Y + 0.12, 0.085], [HEAD_Y + 0.16, 0.03]], 8,
			Folk.SLOT_HAT, PART_HAT_FUR, 1.0, true)
		# Açık baş: alında bant.
		b.lathe([[HEAD_Y + 0.045, HEAD_R + 0.008], [HEAD_Y + 0.01, HEAD_R + 0.008]], 8, Folk.SLOT_HAT, PART_HAT_BAND, 0.95, false)
	var m := b.commit()
	_meshes[detail] = m
	return m


## Ağın üçgen sayısı (sınama ve bütçe).
static func triangles(m: Mesh) -> int:
	var total := 0
	for s in m.get_surface_count():
		var arrays := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		total += idx.size() / 3 if not idx.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


## Örneğin dönüşümü (saf): yer, yön (atan2(x, z)), boy ölçeği ve yapı.
static func instance_transform(at: Vector3, yaw: float, height_scale: float, build: float) -> Transform3D:
	var w := sqrt(clampf(build, 0.8, 1.3))
	return Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(w * height_scale, height_scale, w * height_scale)), at)


## Ağ kurucusu: köşeler, normaller, köşe rengi (yuva, parça, gölge payı) ve dizin.
class _Builder:
	extends RefCounted

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	func _color(slot: int, part: int, ao: float) -> Color:
		return Color(float(slot) / 8.0, float(part) / 16.0, clampf(ao, 0.0, 1.0), 1.0)

	func _add(p: Vector3, n: Vector3, c: Color) -> int:
		verts.append(p)
		normals.append(n.normalized() if n.length_squared() > 0.000001 else Vector3.UP)
		colors.append(c)
		return verts.size() - 1

	## Konik boru (a'dan b'ye, yarıçap ra'dan rb'ye), uçları kapalı.
	func tube(a: Vector3, b: Vector3, ra: float, rb: float, seg: int, slot: int, part: int, ao: float) -> void:
		var axis := (b - a).normalized()
		var side := axis.cross(Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var up := side.cross(axis).normalized()
		var c := _color(slot, part, ao)
		var ring_a: Array[int] = []
		var ring_b: Array[int] = []
		for i in seg:
			var t := TAU * float(i) / float(seg)
			var dir := side * cos(t) + up * sin(t)
			ring_a.append(_add(a + dir * ra, dir, c))
			ring_b.append(_add(b + dir * rb, dir, c))
		# Godot'nun ön yüzü saat yönündedir (dışarıdan bakınca): (b - a) × (c - a) içe bakar.
		for i in seg:
			var j := (i + 1) % seg
			indices.append_array([ring_a[i], ring_b[j], ring_b[i], ring_a[i], ring_a[j], ring_b[j]])
		var ca := _add(a, -axis, c)
		var cb := _add(b, axis, c)
		for i in seg:
			var j := (i + 1) % seg
			indices.append_array([ca, ring_a[j], ring_a[i], cb, ring_b[i], ring_b[j]])

	## Kutu (merkez, boy).
	func box(center: Vector3, size: Vector3, slot: int, part: int, ao: float) -> void:
		var c := _color(slot, part, ao)
		var h := size * 0.5
		var faces := [
			[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.FORWARD],
			[Vector3.UP, Vector3.BACK, Vector3.RIGHT], [Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT],
			[Vector3.BACK, Vector3.UP, Vector3.LEFT], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT],
		]
		for f: Array in faces:
			var n: Vector3 = f[0]
			var u: Vector3 = f[1]
			var v: Vector3 = f[2]
			var o := center + n * h
			var du := u * h
			var dv := v * h
			var i0 := _add(o - du - dv, n, c)
			var i1 := _add(o + du - dv, n, c)
			var i2 := _add(o + du + dv, n, c)
			var i3 := _add(o - du + dv, n, c)
			indices.append_array([i0, i2, i1, i0, i3, i2])

	## Küre (merkez, yarıçap); top_slot verilirse üst ve arka yarısı (saç) o yuvada (top_from: başlangıç yüksekliği, yarıçapa oran).
	func sphere(center: Vector3, r: float, seg: int, rings: int, slot: int, part: int, ao: float, top_slot: int = -1, top_from: float = 0.0) -> void:
		var grid: Array = []
		for k in rings + 1:
			var phi := PI * float(k) / float(rings)
			var row: Array[int] = []
			for i in seg:
				var t := TAU * float(i) / float(seg)
				var dir := Vector3(sin(phi) * sin(t), cos(phi), sin(phi) * cos(t))
				var use := slot
				if top_slot >= 0 and (dir.y > top_from or (dir.z < -0.2 and dir.y > -0.45)):
					use = top_slot
				row.append(_add(center + dir * r, dir, _color(use, part, ao)))
			grid.append(row)
		for k in rings:
			var r0: Array[int] = grid[k]
			var r1: Array[int] = grid[k + 1]
			for i in seg:
				var j := (i + 1) % seg
				if k > 0:
					indices.append_array([r0[i], r0[j], r1[j]])
				if k < rings - 1:
					indices.append_array([r0[i], r1[j], r1[i]])

	## Döner yüzey: profil [[y, r], ...] (yukarıdan aşağı), seg dilim; cap: üst ucu kapatır. lean: uca doğru kayma (sivri başlık).
	func lathe(raw_profile: Array, seg: int, slot: int, part: int, ao: float, cap: bool, lean: Vector3 = Vector3.ZERO) -> void:
		var c := _color(slot, part, ao)
		var rings: Array = []
		# Profil yukarıdan aşağı sıralanır: kapak en üst halkadadır (başlığın ucu, omuzun üstü).
		var profile := raw_profile.duplicate()
		profile.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
		var top_y := float(profile[0][0])
		var bottom_y := float(profile[profile.size() - 1][0])
		for k in profile.size():
			var y := float(profile[k][0])
			var r := float(profile[k][1])
			var shift := lean * clampf((y - bottom_y) / maxf(top_y - bottom_y, 0.001), 0.0, 1.0)
			var row: Array[int] = []
			# Normalin dikey payı profilin eğiminden: aşağı doğru genişleyen yüzey (etek, başlığın ucu) dışarı ve yukarı bakar.
			var above: Array = profile[maxi(k - 1, 0)]
			var below: Array = profile[mini(k + 1, profile.size() - 1)]
			var drop := float(above[0]) - float(below[0])
			var slope := (float(below[1]) - float(above[1])) / drop if drop > 0.0001 else 0.0
			for i in seg:
				var t := TAU * float(i) / float(seg)
				var dir := Vector3(sin(t), 0.0, cos(t))
				var n := (dir + Vector3.UP * slope).normalized()
				row.append(_add(Vector3(0.0, y, 0.0) + dir * r + shift, n, c))
			rings.append(row)
		for k in rings.size() - 1:
			var r0: Array[int] = rings[k]
			var r1: Array[int] = rings[k + 1]
			for i in seg:
				var j := (i + 1) % seg
				indices.append_array([r0[i], r1[j], r1[i], r0[i], r0[j], r1[j]])
		if cap:
			var top: Array[int] = rings[0]
			var apex := _add(Vector3(0.0, top_y, 0.0) + lean, Vector3.UP, c)
			for i in seg:
				var j := (i + 1) % seg
				indices.append_array([apex, top[j], top[i]])

	func commit() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m
