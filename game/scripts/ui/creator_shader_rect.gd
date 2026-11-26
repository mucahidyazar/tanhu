@tool
class_name CreatorShaderRect
extends ColorRect
## Shader ile boyanan dikdörtgen (arka plan, parşömen kâğıdı, fırça darbesi).
##
## Shader'daki "rect_size" parametresini düğümün boyutuyla eşit tutar; böylece kâğıt lifleri,
## fırça kılları ve motifler her ekran boyutunda aynı piksel ölçüsünde kalır.
## Aynı malzemeyi paylaşan düğümler olmaması için sahnede malzemeler "local to scene" işaretlidir.


func _ready() -> void:
	resized.connect(sync_size)
	sync_size()


## Malzemenin rect_size parametresini günceller.
func sync_size() -> void:
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(&"rect_size", size)
