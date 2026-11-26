// Otağ kesiti: oyuncu otağın içindeyken kabuğun ve iç döşemenin kameraya bakan yarısı alçak bir duvara kadar,
// geri kalanı da duvarın çatıya döndüğü yerin biraz üstünden kesilir; yüksek açılı oyun kamerası içeriyi görür.
// cut_amount 0 iken kesit yoktur; 0'dan 1'e giderken kesit tepeden aşağı iner (çatı kalkar, ön duvar alçalır).
// Koordinatlar dünya uzayındadır: cut_center otağ duvarının merkezi (zemin yüksekliğinde), cut_dir merkezden
// kameraya doğru yatay birim yön. Kesitli malzemeler gölge vermez: gölgeyi kesilmeyen ayrı bir kopya verir
// (MeshyProp.cutaway), böylece içerideyken de çatı ay ışığını keser, ocağın ışığı duvardan dışarı sızmaz.
uniform float cut_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cut_center = vec3(0.0);
uniform vec2 cut_dir = vec2(0.0, 1.0);
// Kesitin uzandığı yarıçap (metre): bunun dışındaki yüzeyler kesilmez (kapı önündeki basamaklar, kanat...).
uniform float cut_radius = 4.0;
// Kameraya bakan yarıda kalan alçak duvar ve her yerde kesilen yükseklik (metre, zeminden).
uniform float cut_low = 0.42;
uniform float cut_top = 2.55;
// Kesitin başladığı tepe (metre): cut_amount arttıkça kesit buradan aşağı iner.
uniform float cut_ceiling = 4.6;

// Bu dünya noktasının kesit yüksekliği (metre, zeminden; kesit yoksa çok yüksek).
float cutaway_height(vec3 p) {
	vec3 rel = p - cut_center;
	float len = length(rel.xz);
	float facing = len > 0.001 ? dot(rel.xz / len, cut_dir) : 0.0;
	float h = mix(cut_top, cut_low, smoothstep(-0.2, 0.45, facing));
	return mix(cut_ceiling, h, smoothstep(0.0, 1.0, cut_amount));
}

// Kesit bu dünya noktasını gizliyor mu?
bool cutaway_hidden(vec3 p) {
	if (cut_amount <= 0.0 || length(p.xz - cut_center.xz) > cut_radius) {
		return false;
	}
	return p.y - cut_center.y > cutaway_height(p);
}

// Kesitin hemen altındaki ince şerit (0..1): kesilen kenar koyu bir çizgiyle belirginleşir.
float cutaway_rim(vec3 p) {
	if (cut_amount <= 0.0 || length(p.xz - cut_center.xz) > cut_radius) {
		return 0.0;
	}
	float below = cutaway_height(p) - (p.y - cut_center.y);
	return 1.0 - smoothstep(0.0, 0.05, below);
}
