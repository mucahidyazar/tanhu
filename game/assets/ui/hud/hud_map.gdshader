// Haritanın dairesi (HudMinimap, HudMapScreen): pişirilmiş dünya görüntüsünden (WorldMap) yuvarlak bir kesit.
// Mini harita kamerayla döner (rotation = kameranın yaw'ı: ekranda yukarısı kameranın baktığı yön), büyük harita kuzeyi yukarıda tutar.
// Renk referanstaki boyalı haritaya çekilir: doygunluk, sıcak ton, kenara doğru hafif koyulaşma; pişirilen alanın dışı parşömendir.
shader_type canvas_item;

uniform sampler2D map_tex : source_color, filter_linear_mipmap, repeat_disable;
// Dairenin merkezinin haritadaki yeri (0..1) ve dairenin yarıçapının harita birimiyle boyu.
uniform vec2 center_uv = vec2(0.5);
uniform float radius_uv = 0.25;
uniform float rotation = 0.0;
// Pişirmenin ölçtüğü renk ayarı (WorldMap.measure): kazanç, karşıtlık, dayanak rengi.
uniform float exposure = 1.0;
uniform float contrast = 1.0;
uniform vec3 pivot = vec3(0.5);
uniform float saturation = 1.12;
uniform float brightness = 1.0;
// Boyalı haritanın parşömen tonu: rengin bu kadarı aynı parlaklıktaki sıcak sepyaya karışır (gece kampının yeşili de, Ordos'un
// sarısı da referanstaki haritanın tonuna yaklaşır).
uniform float sepia = 0.3;
uniform vec3 warm : source_color = vec3(1.04, 0.99, 0.88);
uniform float rim_dark = 0.32;
uniform vec3 paper : source_color = vec3(0.66, 0.55, 0.36);
// Kenar yumuşatması (dairenin yarıçapına göre).
uniform float edge = 0.012;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = 1.0 - smoothstep(1.0 - edge, 1.0, r);
	float c = cos(rotation);
	float s = sin(rotation);
	vec2 q = vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
	vec2 uv = center_uv + q * radius_uv;
	vec3 col = texture(map_tex, uv).rgb * exposure;
	col = pivot + (col - pivot) * contrast;
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	col = mix(paper, col, inside);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col = mix(col, l * vec3(1.2, 0.98, 0.64), sepia) * brightness * warm;
	col *= 1.0 - rim_dark * smoothstep(0.55, 1.0, r);
	COLOR = vec4(clamp(col, 0.0, 1.0), a * COLOR.a);
}
