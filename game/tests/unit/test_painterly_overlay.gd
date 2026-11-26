extends TestCase
## PainterlyOverlay testleri: katman, tam ekran süzgeç, shader ayarları, açma/kapama.

const OVERLAY_SCENE := preload("res://scenes/ui/painterly_overlay.tscn")
const SHADER_PATH := "res://shaders/painterly.gdshader"

var overlay: PainterlyOverlay


func before_each() -> void:
	overlay = OVERLAY_SCENE.instantiate() as PainterlyOverlay
	add_child(overlay)


func after_each() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null


func _material() -> ShaderMaterial:
	return overlay.get_filter_rect().material as ShaderMaterial


func test_layer_and_full_screen_rect() -> void:
	assert_eq(overlay.layer, 1, "Efekt 3B sahnenin hemen üstünde, arayüzün altında olmalı")
	var rect := overlay.get_filter_rect()
	assert_not_null(rect)
	assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Efekt fareyi engellememeli")
	assert_almost(rect.anchor_left, 0.0)
	assert_almost(rect.anchor_top, 0.0)
	assert_almost(rect.anchor_right, 1.0)
	assert_almost(rect.anchor_bottom, 1.0)


func test_shader_reads_screen_texture() -> void:
	var mat := _material()
	assert_not_null(mat)
	assert_eq(mat.shader.resource_path, SHADER_PATH)
	assert_true(mat.shader.code.contains("hint_screen_texture"), "Shader ekranı hint_screen_texture ile okumalı")
	assert_true(mat.shader.code.contains("shader_type canvas_item"))


func test_enabled_toggles_filter() -> void:
	assert_true(overlay.enabled)
	assert_true(overlay.get_filter_rect().visible)
	overlay.enabled = false
	assert_false(overlay.get_filter_rect().visible, "Kapalıyken süzgeç çizilmemeli")
	overlay.enabled = true
	assert_true(overlay.get_filter_rect().visible)


func test_strength_is_applied_and_clamped() -> void:
	assert_between(overlay.strength, 0.5, 0.65, "Varsayılan şiddet yüzleri okunur tutmalı")
	overlay.strength = 0.3
	assert_almost(float(_material().get_shader_parameter(&"strength")), 0.3)
	overlay.strength = 2.0
	assert_almost(overlay.strength, 1.0, 0.0001, "Şiddet 0..1 aralığında kalmalı")
	assert_almost(float(_material().get_shader_parameter(&"strength")), 1.0)
	overlay.strength = -1.0
	assert_almost(overlay.strength, 0.0)


func test_each_instance_has_its_own_material() -> void:
	var other := OVERLAY_SCENE.instantiate() as PainterlyOverlay
	add_child(other)
	other.strength = 0.1
	overlay.strength = 0.6
	assert_ne(other.get_filter_rect().material, overlay.get_filter_rect().material)
	assert_almost(float((other.get_filter_rect().material as ShaderMaterial).get_shader_parameter(&"strength")), 0.1)
	other.queue_free()


func test_overlay_created_from_code_builds_its_own_filter() -> void:
	var other := PainterlyOverlay.new()
	add_child(other)
	var rect := other.get_filter_rect()
	assert_not_null(rect, "Sahnesiz oluşturulan efekt süzgecini kendisi kurmalı")
	assert_eq(other.layer, 1)
	assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_almost(rect.anchor_right, 1.0)
	assert_almost(rect.anchor_bottom, 1.0)
	var mat := rect.material as ShaderMaterial
	assert_not_null(mat)
	assert_eq(mat.shader.resource_path, SHADER_PATH)
	other.strength = 0.4
	assert_almost(float(mat.get_shader_parameter(&"strength")), 0.4)
	other.enabled = false
	assert_false(rect.visible)
	other.queue_free()


func test_sample_stride_scales_with_screen_height() -> void:
	assert_almost(PainterlyOverlay.sample_stride(1080.0), 1.0)
	assert_almost(PainterlyOverlay.sample_stride(2160.0), 2.0)
	assert_almost(PainterlyOverlay.sample_stride(720.0), 1.0, 0.0001, "Küçük ekranlarda 1 pikselin altına inmemeli")
	assert_almost(PainterlyOverlay.sample_stride(2104.0), 2104.0 / 1080.0)
