// soft_toon'un iki yüzlü hali: pelerin, kumaş, ince yüzeyler için (arkadan da görünür).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://shaders/include/toon_body.gdshaderinc"
