// Önizlemedeki karakterin ayaklarının altındaki yumuşak, yuvarlak gölge lekesi.
//
// Saydam arka planlı önizlemede gerçek bir zemin yoktur; bu leke karakteri boyalı zemine "oturtur".
// İki katmandan oluşur: ayakların hemen altında koyu bir çekirdek ve geniş, çok yumuşak bir hale.
// Önizlemenin renk ayarı (soluk film LUT'u) koyuları biraz açtığı için alfa değerleri buna göre seçildi.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 shadow_color : source_color = vec4(0.02, 0.1, 0.09, 1.0);
uniform float core_alpha : hint_range(0.0, 1.0) = 0.7;
uniform float halo_alpha : hint_range(0.0, 1.0) = 0.34;
// Çekirdeğin yarıçapı (0..1, düzlemin yarı boyutuna oranla).
uniform float core_radius : hint_range(0.05, 1.0) = 0.5;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float core = 1.0 - smoothstep(core_radius * 0.25, core_radius, r);
	float halo = 1.0 - smoothstep(0.15, 1.0, r);
	ALBEDO = shadow_color.rgb;
	ALPHA = clamp(core * core_alpha + halo * halo * halo_alpha, 0.0, 1.0);
}
