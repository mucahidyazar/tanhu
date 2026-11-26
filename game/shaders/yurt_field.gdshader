// YurtField: uzaktaki kapalı yurtlar ve kubbeler (MultiMesh; structures.md §13.6, godot.md §4.6): aşama kitinin gövdesi, örnek verisi
// INSTANCE_CUSTOM'dadır (ton, parıltı, yapım yüksekliği, yanık). Gövde include/staged_body.gdshaderinc'tedir.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;

#define FIELD
#include "res://shaders/include/staged_body.gdshaderinc"
