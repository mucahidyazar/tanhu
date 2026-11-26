// rug.gdshader'ın otağ duvarına asılan, kesitli ve iki yüzlü hali (tör'deki işlemeli duvar halısı): oyuncu
// içerideyken kameraya bakan yarıdaysa duvarla birlikte kesilir (bkz. include/cutaway.gdshaderinc).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#define CUTAWAY
#include "res://shaders/include/rug_body.gdshaderinc"
