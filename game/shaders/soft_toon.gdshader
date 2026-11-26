// Genel amaçlı yumuşak "toon" malzeme.
// Karakterler, yurtlar, ahşap ve dekor parçaları bunu kullanır.
// Renk ayarları Style.toon() ile koddan, isterseniz editörden de değiştirilebilir.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/include/toon_body.gdshaderinc"
