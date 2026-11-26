// Tam Vuruş halkası (economy.md §3.1, §3.7; prototipin game/strike-ring.js'i): yere yatık tek düzlem, derinlik sınaması kapalı, ek
// karışım. Dış halka temas anında hedef banda oturur (uK = t / temas), bant genişliği pencereyi gösterir (uBand), son vuruşta altın
// (uGold); tam vuruş ve kaçış kısa bir ışımayla söner (uFlash, uHit). Zaman uniform'la gelir (ham TIME okunmaz).
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, blend_add, cull_disabled, shadows_disabled, fog_disabled;

uniform float uK = 0.0;
uniform float uBand = 0.05;
uniform float uGold = 0.0;
uniform float uFlash = 0.0;
uniform float uHit = 0.0;
uniform float uAlpha = 1.0;

const float BAND_R = 0.5;

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = length(q);
	float r = mix(0.96, BAND_R, uK);
	float band = smoothstep(uBand + 0.02, uBand - 0.005, abs(d - BAND_R));
	float ring = smoothstep(0.035, 0.0, abs(d - r));
	float near = 1.0 - smoothstep(0.0, 0.25, abs(r - BAND_R));
	vec3 warm = mix(vec3(1.0, 0.86, 0.62), vec3(1.0, 0.74, 0.22), uGold);
	vec3 col = warm * (band * (0.32 + 0.4 * near)) + warm * ring * 1.4;
	vec3 flash = mix(vec3(0.55, 0.5, 0.45), vec3(1.6, 1.15, 0.4), uHit);
	col += flash * uFlash * smoothstep(0.09, 0.0, abs(d - BAND_R)) * 2.0;
	float a = clamp(max(max(band * 0.55, ring), uFlash * smoothstep(0.1, 0.0, abs(d - BAND_R))), 0.0, 1.0) * uAlpha;
	ALBEDO = col * a;
	ALPHA = a;
}
