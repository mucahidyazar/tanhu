class_name PainterlyOverlay
extends CanvasLayer
## Boyalı ekran efekti katmanı (shaders/painterly.gdshader).
##
## 3B sahnenin üstünde, arayüzün altında durur (katman 1). Ekranı okuyup hafif bir Kuwahara
## (fırça lekesi) süzgeci, kâğıt dokusu, yumuşak vinyet ve az bir doygunluk artışı uygular.
## Arayüz (menü, ipuçları) daha yüksek bir katmanda olmalıdır; yoksa yazılar da boyanır.
##
## Kullanım:
##   overlay.enabled = false     # efekti kapatır (ayarlar menüsü için; maliyet sıfırlanır)
##   overlay.strength = 0.5      # boyalı görünümün şiddeti (0..1)
## Normalde sahnesiyle (res://scenes/ui/painterly_overlay.tscn) eklenir; PainterlyOverlay.new()
## ile koddan oluşturulursa süzgeç dikdörtgenini kendisi kurar.

## Efektin açılıp kapandığı katman sırası.
const LAYER := 1
## Shader'daki "reference_height": bu ekran yüksekliğinde örnek aralığı 1 pikseldir.
const REFERENCE_HEIGHT := 1080.0
const SHADER := preload("res://shaders/painterly.gdshader")

## Efekt açık mı?
@export var enabled := true:
	set(value):
		enabled = value
		_apply()
## Boyalı görünümün şiddeti (Kuwahara karışımı). 0.5–0.65 yüzleri okunur tutar.
@export_range(0.0, 1.0) var strength := 0.58:
	set(value):
		strength = clampf(value, 0.0, 1.0)
		_apply()


func _ready() -> void:
	layer = LAYER
	var rect := get_filter_rect()
	if rect == null:
		rect = _build_filter()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply()


## Süzgecin çizildiği tam ekran dikdörtgen.
func get_filter_rect() -> ColorRect:
	return get_node_or_null(^"Filter") as ColorRect


## Shader'ın kullandığı örnek aralığı (piksel). Shader'daki formülle aynıdır; test edilebilir.
## 1080p ve altında 1, 4K'da 2, 2104 piksel yüksek Retina ekranda ~1.95.
static func sample_stride(screen_height: float) -> float:
	return maxf(1.0, screen_height / REFERENCE_HEIGHT)


# Sahnesiz oluşturulduğunda: tam ekran, fareyi geçiren ve boyalı shader'ı kullanan dikdörtgen.
func _build_filter() -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "Filter"
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	rect.material = mat
	add_child(rect)
	return rect


func _apply() -> void:
	var rect := get_filter_rect()
	if rect == null:
		return
	rect.visible = enabled
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(&"strength", strength)
		mat.set_shader_parameter(&"reference_height", REFERENCE_HEIGHT)
