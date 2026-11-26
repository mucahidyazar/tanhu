// atw_textured'ın iki yüzlü hali: içi görünen (yurt kapısından iç duvar, kovanın içi) ya da ince
// yüzeyli (ahır çatısı, çit) modeller için. Arka yüzlerin normali Godot tarafından çevrilir.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://shaders/include/atw_textured_body.gdshaderinc"
