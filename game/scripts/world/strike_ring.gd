class_name StrikeRing
extends MeshInstance3D
## Tam Vuruş halkası (economy.md §3.1, §3.7 «Halka»; prototipin game/strike-ring.js'i): yere yatık tek düzlem (bir çizim, derinlik sınaması
## kapalı). Dış halka temas anında hedef banda oturur, bandın genişliği pencereyi gösterir, son vuruşta altın; tam vuruşta sıcak, kaçışta
## soluk bir ışıma. Halka yalnız vuruş sürerken görünür. Toplamanın saati yazar (set_time): kare başına bir uniform, ham TIME yok.
##   ring.start(at, T, window, gold, 0.72)
##   ring.set_time(t)            # her kare
##   ring.resolve(true)          # tam vuruş
##   ring.stop()

const SHADER := preload("res://shaders/strike_ring.gdshader")
## Düzlemin kenarı (m; uzak kadrajda okunur: 28 m'de ≈130 piksel) ve hedef bandın yarıçapı (düzlemin yarısına göre).
const SIZE := 2.6
const BAND_R := 0.5
const FLASH_S := 0.28

var active := false
var t := 0.0
var T := 1.0
var window := 0.18
var contact_k := 0.72
var gold := false
var judged := false
var result := ""
var _flash_at := 0.0
var _mat: ShaderMaterial


func _init() -> void:
	name = "StrikeRing"
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh = plane
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sorting_offset = 20.0
	visible = false


## T sn'lik vuruş, temas contact_k × T'de, pencere sn.
func start(at: Vector3, p_T: float, p_window: float, p_gold: bool, p_contact_k := 0.72) -> void:
	active = true
	t = 0.0
	T = maxf(0.05, p_T)
	window = p_window
	contact_k = p_contact_k
	gold = p_gold
	judged = false
	result = ""
	_flash_at = 0.0
	# Bant: pencerenin süresince dış halkanın aldığı yolun yarısı.
	_mat.set_shader_parameter(&"uBand", (0.96 - BAND_R) * (window / 2.0) / (contact_k * T))
	_mat.set_shader_parameter(&"uGold", 1.0 if gold else 0.0)
	_mat.set_shader_parameter(&"uFlash", 0.0)
	_mat.set_shader_parameter(&"uHit", 0.0)
	_mat.set_shader_parameter(&"uAlpha", 1.0)
	_mat.set_shader_parameter(&"uK", 0.0)
	global_position = at + Vector3(0.0, 0.06, 0.0)
	visible = true


## Toplamanın saatine bağlı (her kare).
func set_time(p_t: float) -> void:
	if not active:
		return
	t = p_t
	_mat.set_shader_parameter(&"uK", minf(1.6, t / (contact_k * T)))
	_mat.set_shader_parameter(&"uFlash", maxf(0.0, 1.0 - (t - _flash_at) / FLASH_S) if judged else 0.0)
	# Temastan sonra halka söner.
	_mat.set_shader_parameter(&"uAlpha", 1.0 - clampf((t - contact_k * T) / (T * (1.0 - contact_k) + 1e-3), 0.0, 1.0))


## Sonucu gösterir (toplama kendi saatiyle yargılar).
func resolve(clean: bool) -> void:
	judged = true
	_flash_at = t
	result = "hit" if clean else "miss"
	_mat.set_shader_parameter(&"uHit", 1.0 if clean else 0.0)
	_mat.set_shader_parameter(&"uFlash", 1.0)


func stop() -> void:
	active = false
	visible = false


## Bandın uniform değeri (sınama).
func band() -> float:
	return float(_mat.get_shader_parameter(&"uBand"))
