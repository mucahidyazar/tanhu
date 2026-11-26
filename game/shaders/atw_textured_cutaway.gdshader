// atw_textured_double'ın otağ kabuğu için kesitli hali (bkz. include/cutaway.gdshaderinc): oyuncu içerideyken
// kabuğun kameraya bakan yarısı ve çatısı açılır. Gölgeyi kabuğun kesilmeyen bir kopyası verir (MeshyProp.cutaway).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#define CUTAWAY
#include "res://shaders/include/atw_textured_body.gdshaderinc"
