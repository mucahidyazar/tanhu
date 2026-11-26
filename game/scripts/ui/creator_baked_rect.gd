@tool
class_name CreatorBakedRect
extends Control
## Ağır ama durağan bir shader'ı (boyalı arka plan, parşömen kâğıdı) her karede yeniden çalıştırmak
## yerine bir kez dokuya "pişirir" ve o dokuyu gösterir.
##
## - Pişirme gizli bir SubViewport içinde, ekranın fiziksel piksel çözünürlüğünde yapılır; Retina
##   ekranlarda da kâğıt lifleri ve boya taneleri keskin kalır.
## - Boyut ya da ekran ölçeği değişince kendiliğinden yeniden pişirir (aynı karedeki istekler birleşir).
## - Shader'ın "rect_size" parametresine düğümün mantıksal boyutu verilir; desenler arayüz pikseliyle
##   aynı ölçekte kalır.
## Böylece ekran açıkken bu katmanların kare başına maliyeti yalnızca bir doku çizimidir.

const UNPREMULTIPLY_SHADER := preload("res://shaders/ui/creator_unpremultiply.gdshader")

## Pişirilecek malzeme (shader'ında "rect_size" parametresi olmalı).
@export var bake_material: ShaderMaterial:
	set(value):
		bake_material = value
		if _canvas:
			_canvas.material = value
		queue_bake()
## İçerik saydam kenarlı mı (ör. gölgeli kâğıt)? Kapalıysa opak pişirilir.
@export var transparent := false:
	set(value):
		transparent = value
		_apply_transparency()
		queue_bake()

var _viewport: SubViewport
var _canvas: ColorRect
var _display: TextureRect
var _bake_queued := false
var _bake_count := 0


func _ready() -> void:
	_build()
	resized.connect(queue_bake)
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(queue_bake)
	# İlk pişirme hemen yapılır ki ilk karede boş bir doku görünmesin.
	bake()


## Bir sonraki boşta yeniden pişirir (aynı karedeki birden çok istek tek pişirmeye dönüşür).
func queue_bake() -> void:
	if _bake_queued or not is_inside_tree():
		return
	_bake_queued = true
	bake.call_deferred()


## Dokuyu şimdi yeniden pişirir: SubViewport'u boyutlandırır ve tek bir kare çizdirir.
func bake() -> void:
	_bake_queued = false
	if _viewport == null or bake_material == null:
		return
	var render_scale := 1.0 if Engine.is_editor_hint() else _screen_scale()
	_viewport.size = CreatorBakedRect.texture_size(size, render_scale)
	bake_material.set_shader_parameter(&"rect_size", size)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_bake_count += 1


## Kaç kez pişirildiği (testler ve hata ayıklama için).
func get_bake_count() -> int:
	return _bake_count


## Pişirilen dokunun piksel boyutu: mantıksal boyut x ekran ölçeği (en az 1 x 1).
static func texture_size(logical_size: Vector2, render_scale: float) -> Vector2i:
	var px := (logical_size * maxf(render_scale, 0.01)).ceil()
	return Vector2i(maxi(int(px.x), 1), maxi(int(px.y), 1))


func _build() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Bake"
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport, false, Node.INTERNAL_MODE_FRONT)
	_canvas = ColorRect.new()
	_canvas.name = "Canvas"
	_canvas.material = bake_material
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(_canvas)
	_display = TextureRect.new()
	_display.name = "Display"
	_display.texture = _viewport.get_texture()
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_display, false, Node.INTERNAL_MODE_FRONT)
	_apply_transparency()


func _apply_transparency() -> void:
	if _viewport == null:
		return
	_viewport.transparent_bg = transparent
	if transparent:
		var mat := ShaderMaterial.new()
		mat.shader = UNPREMULTIPLY_SHADER
		_display.material = mat
	else:
		_display.material = null


## Ekranın fiziksel / mantıksal piksel oranı (Retina'da ~2).
func _screen_scale() -> float:
	var window := get_window()
	if window == null:
		return 1.0
	return CreatorTurntable.render_scale_for(Vector2(window.size), get_viewport().get_visible_rect().size)
