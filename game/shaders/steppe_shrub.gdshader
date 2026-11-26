// Bozkır çalısı (scripts/maps/childhood_scatter.gd; K98): pelin ve karagan, tek ağlı MultiMesh. Boya köşe rengindedir, INSTANCE_CUSTOM.r örneğin tonu, .g tohumu. Rüzgârda
// tepe salınır (kökü yerde). Işık çizgisi soft_toon'un dilindedir, zaman tn_time() ile okunur.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

uniform float sway = 0.03;
uniform vec2 wind_direction = vec2(0.85, 0.3);

varying float v_tone;
varying vec3 v_local;

void vertex() {
	float t = tn_time() * 1.4 + INSTANCE_CUSTOM.g * 37.0;
	float lift = clamp(VERTEX.y, 0.0, 1.0);
	VERTEX.xz += wind_direction * sin(t + VERTEX.x * 3.0) * sway * lift * lift;
	v_tone = INSTANCE_CUSTOM.r;
	v_local = VERTEX;
}

void fragment() {
	float n = tn_noise3(v_local * 9.0);
	vec3 col = COLOR.rgb * (0.86 + v_tone * 0.3) * (0.9 + n * 0.2);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
