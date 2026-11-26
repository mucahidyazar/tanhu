// soft_toon'un otağ içi için kesitli, iki yüzlü hali (duvara asılı yay, sadak, torbalar, tündük): oyuncu içerideyken
// kameraya bakan yarıdakiler ve tavandakiler duvarla birlikte kesilir (bkz. include/cutaway.gdshaderinc).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#define CUTAWAY
#include "res://shaders/include/toon_body.gdshaderinc"
