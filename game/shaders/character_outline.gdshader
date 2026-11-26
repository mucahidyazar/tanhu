// İnce "mürekkep" konturu (stencil yöntemi).
// Karakter malzemesinin next_pass'i olarak çizilir: her köşe, normalinin EKRANDAKİ yönünde sabit sayıda piksel
// dışarı itilir; stencil testi sayesinde yalnızca karakterin DIŞINDA kalan piksellere çizilir.
// Böylece silüetin çevresinde eşit kalınlıkta bir çizgi oluşur ve çizgi asla yüzün/kıyafetin üstüne taşmaz.
// Kalınlık yakında width_pixels, uzaklaştıkça incelir (en az min_pixels).
shader_type spatial;
render_mode cull_back, unshaded, depth_draw_never, shadows_disabled;
// Yalnızca karakterin kendisinin çizilmediği piksellere çiz.
stencil_mode read, compare_not_equal, 128;

uniform vec4 outline_color : source_color = vec4(0.24, 0.17, 0.14, 1.0);
// Yakın plandaki çizgi kalınlığı (piksel, 1080p'ye göre) ve bu kalınlığın korunduğu mesafe.
uniform float width_pixels = 2.2;
uniform float full_width_distance = 4.0;
uniform float min_pixels = 1.0;

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * view_pos;
	vec2 screen_dir = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	float len = length(screen_dir);
	if (len > 0.0001) {
		float depth = max(-view_pos.z, 0.01);
		float px = max(width_pixels * clamp(full_width_distance / depth, 0.0, 1.0), min_pixels);
		// Kalınlığı 1080p'ye göre ölçekle: Retina/4K ekranlarda da aynı görünsün.
		px *= VIEWPORT_SIZE.y / 1080.0;
		clip.xy += (screen_dir / len) * (px * 2.0 / VIEWPORT_SIZE) * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
