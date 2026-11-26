// Havanın derecesi (weather.md §3.4 «Doygunluk ×, karşıtlık ×, ton», §9.2 post.weather): boyalı süzgeçten (PainterlyOverlay) sonra,
// ekran yağışından önce. Yalnız hava varken görünür (kimlikte düğüm gizlidir: ekran okunmaz, menü karesi değişmez). Tipi doygunluğu
// act1 §10'un derecesidir (0,655 × 1,1 = 0,72; ton 0,98 / 0,98 / 1,03).
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform vec3 tone = vec3(1.0);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(lum), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= tone;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
