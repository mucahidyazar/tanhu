// Meshy ile üretilen dokulu modeller (yurt, ahır, atlar, kamp eşyaları, kayalar, ağaçlar) için malzeme.
//
// Gövdenin tamamı (doku, boyalı renk düzeni, fırça lekeleri, mürekkep kenarı, taban koyulaşması,
// kor parlaması, hafif canlılık) atw_textured_body içindedir; ışık ortak "After the Wind" cel modelidir.
// Bu sürüm tek yüzlüdür (kapalı modeller: fıçı, at, sandık...). İçi görünen ya da ince yüzeyli modeller
// (yurt, ahır, kova) için atw_textured_double kullanılır.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;

#include "res://shaders/include/atw_textured_body.gdshaderinc"
