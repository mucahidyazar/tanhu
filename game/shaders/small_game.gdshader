// Kodla çizilen küçük av (scripts/fauna/small_game.gd, fauna_mesh.gd; fauna.md §10): kanat, gagalama, koşu ve dikilme köşede.
//
// Örnek başına tekdüze: pose = (fly, run, rear, seed). fly 0 kanat sırtta katlı, 1 açık ve çırpıyor; run 0 duruyor, 1 koşuyor;
// rear 0 dört ayak üstünde, 1 dikilmiş (tarbaganın nöbeti, gerbilin bakışı); seed örneğin tohumu.
// Parça bilgisi (CUSTOM0): x kanat (işaretli; −1 sol uç, +1 sağ uç), y baş ağırlığı, z kuyruk ağırlığı, w bacak (işaretli, ±1).
// İki yüzlü: kanat ve kuyruk tek yüzlü yapraktır. Işık çizgisi soft_toon'un dilindedir; zaman tn_time() ile okunur.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

instance uniform vec4 pose = vec4(0.0, 0.0, 0.0, 0.0);

// Çırpma ve gagalama hızı (rad/sn; türün satırından), bacak hızı.
uniform float flap_rate = 30.0;
uniform float peck_rate = 2.0;
uniform float gait_rate = 18.0;
// Boyun dibi: baş buradan öne eğilir.
uniform vec3 neck_pivot = vec3(0.0, 0.1, 0.05);
// Kalça: dikilirken gövde buradan kalkar.
uniform vec3 hip_pivot = vec3(0.0, 0.05, -0.04);
// Kanadın gövde boyunca açıklığı (metre): katlanınca uç arkaya bu kadar gider.
uniform float wing_span = 0.14;
// Kısmen kapalı çırpma açısı.
uniform float flap_lift = 0.75;
uniform float curl_scale = 30.0;
uniform float curl_strength : hint_range(0.0, 0.6) = 0.12;

varying vec3 v_local;

void vertex() {
	float fly = pose.x;
	float run = pose.y;
	float rear = pose.z;
	float seed = pose.w;
	float t = tn_time() + seed * 53.0;
	vec3 v = VERTEX;
	v_local = v;

	// Kanat: yerdeyken sırta doğru içeri ve arkaya katlanır; açıkken çırpar.
	float w = abs(CUSTOM0.x);
	if (w > 0.0) {
		float folded = 1.0 - fly;
		float side = sign(CUSTOM0.x);
		float x = v.x;
		v.x = mix(x, side * (wing_span * 0.2 + w * wing_span * 0.08), folded);
		v.z -= folded * w * wing_span * 1.15;
		v.y -= folded * w * wing_span * 0.12;
		float flap = sin(t * flap_rate + w * 0.8);
		v.y += fly * w * wing_span * flap * flap_lift;
	}

	// Baş: yerde durunca arada gagalar ya da kokar; uçarken ve koşarken öne uzanır.
	float head = CUSTOM0.y;
	if (head > 0.0) {
		float peck = pow(max(sin(t * peck_rate), 0.0), 6.0) * (1.0 - fly) * (1.0 - run) * (1.0 - rear);
		float a = (peck * 0.95 + fly * -0.2) * head;
		vec3 q = v - neck_pivot;
		float ca = cos(a);
		float sa = sin(a);
		q = vec3(q.x, q.y * ca - q.z * sa, q.y * sa + q.z * ca);
		v = q + neck_pivot;
		// Bakınma: başın küçük dönüşü.
		float look = sin(t * 0.8) * 0.45 * (1.0 - fly) * (1.0 - run) * head;
		float cy = cos(look);
		float sy = sin(look);
		vec3 r = v - neck_pivot;
		r = vec3(r.x * cy + r.z * sy, r.y, -r.x * sy + r.z * cy);
		v = r + neck_pivot;
	}

	// Kuyruk: inip kalkar (kuşta), koşarken arkada sürünür.
	if (CUSTOM0.z > 0.0) {
		v.y += CUSTOM0.z * (sin(t * 3.1) * 0.012 * (1.0 - fly) + run * 0.02);
	}

	// Bacak: koşuda çapraz çalışır; uçarken arkaya toplanır.
	if (abs(CUSTOM0.w) > 0.5) {
		float s = sin(t * gait_rate) * CUSTOM0.w;
		v.z += s * 0.06 * run * clamp(1.0 - v.y * 4.0, 0.0, 1.0);
		v.z -= fly * 0.05 * clamp(1.0 - v.y * 8.0, 0.0, 1.0);
		v.y += fly * 0.03;
	}

	// Dikilme: kalçadan öne kalkar (x çevresinde); bacaklar yerde kalır.
	if (rear > 0.0 && abs(CUSTOM0.w) < 0.5) {
		float a = -rear * 1.15;
		vec3 q = v - hip_pivot;
		float ca = cos(a);
		float sa = sin(a);
		q = vec3(q.x, q.y * ca - q.z * sa, q.y * sa + q.z * ca);
		v = q + hip_pivot;
	}

	// Koşuda gövde sekip iner.
	v.y += abs(sin(t * gait_rate * 0.5)) * run * 0.03;
	VERTEX = v;
}

void fragment() {
	vec3 col = COLOR.rgb;
	float wool = COLOR.a;
	float n = tn_noise3(v_local * curl_scale);
	col *= 1.0 + (n - 0.5) * 2.0 * curl_strength * wool;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
