@tool
class_name StagedStructure
extends Node3D
## Dünyadaki aşamalı yapı (godot.md §3 «Emek ve aşamalı yapı», §6.7; structures.md §2.1): aşama kitinin tek ağını (StagedMesh) çizer,
## durumunu bir şantiyeden (SiteState) ya da elle verilen aşamadan okur ve gölgelendiricinin örnek tekdüzenlerine yazar: stage, stage_t,
## damage, burn, tear, snow, cut, glow, frame_on, shake. Ağ paylaşılır (millet, boy, hazır ayar başına bir kez; YurtGeometry,
## StructureCatalog), bu yüzden yapı başına bellek ve çizim eklemez; çizim yüzey başınadır (kalın ve ince parçalar).
## Aşama değişince (kurulum ya da geri düşüş) parçalar kipleriyle belirir ya da çöker: düşüşte düşen aşamanın stage_t'si 0,6 sn'de 1'den 0'a iner.
##
## Engeller (World ve MapWorld «obstacles» grubunu toplar): ayak izinin dairesi ya da kutusu, aşamaya göre (footprint). Navmesh pişirmesi
## aynı izi kayıttan okur (StructureKit.footprint): yapı düğüm kurulmadan da izini verir.
##   var s := StagedStructure.new()
##   s.mesh = StructureCatalog.mesh("tower", "")
##   s.bind_site(site_state)       # ya da s.set_stage(3, 0.5)
##   add_child(s)

signal stage_shown(stage: int)

const SOLID_SHADER := preload("res://shaders/staged.gdshader")
const THIN_SHADER := preload("res://shaders/staged_double.gdshader")
## Geri düşüşün görünür süresi (sn).
const FALL_S := 0.6
const UNIFORMS: Array[StringName] = [&"stage", &"stage_t", &"damage", &"burn", &"tear", &"snow", &"cut", &"glow", &"frame_on", &"shake"]

## Malzeme önbelleği: anahtar → [kalın, ince] (aynı program, millet başına süs renkleri).
static var _materials: Dictionary = {}

@export var kind := ""
@export var record_id := ""
## Ağ (StagedMesh.commit; iki yüzey: kalın ve ince).
var mesh: ArrayMesh:
	set(value):
		mesh = value
		if is_inside_tree():
			_apply_mesh()
## Malzemenin anahtarı ve süs renkleri (motif, accent).
var material_key := "plain"
var material_params := {}
## Gölge verir mi (uzak ve küçük parçalar vermez).
var casts_shadow := true
## Gösterilen durum (SiteState yoksa elle).
var stage := 7
var stage_t := 0.0
var damage := 0.0
var burn := 0.0
var tear := 0.0
var snow := 0.0
var cut := 0.0
var glow := 0.0
var frame_on := 0.0
var shake := 0.0
## Bağlı şantiye (varsa durum ondan okunur).
var site: SiteState
## Ayak izi: {circles: [Vector3(x, z, r) yerel], boxes: [[merkez Vector2, yarı Vector2, açı]]}; aşama < min_stage iken engel yok.
var footprint := {"circles": [], "boxes": []}
var footprint_min_stage := 1
## Çizen düğümler (kurulduğunda).
var mesh_instance: MeshInstance3D
var extra_instances: Array[GeometryInstance3D] = []

var _fall_from := -1
var _fall_left := 0.0
var _shake_left := 0.0


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	_apply_mesh()
	_push()


## Gölgelendiricinin malzemesi (önbellekli; aynı anahtar aynı malzeme).
static func materials(key: String, params: Dictionary = {}) -> Array[ShaderMaterial]:
	if _materials.has(key):
		return _materials[key]
	var out: Array[ShaderMaterial] = []
	for shader: Shader in [SOLID_SHADER, THIN_SHADER]:
		var m := ShaderMaterial.new()
		m.shader = shader
		for p: String in params:
			m.set_shader_parameter(StringName(p), params[p])
		out.append(m)
	_materials[key] = out
	return out


static func forget_materials() -> void:
	_materials.clear()


## Ağın yüzeylerine kalın ya da ince malzeme.
static func dress(mi: MeshInstance3D, p_mesh: Mesh, key: String, params: Dictionary) -> void:
	mi.mesh = p_mesh
	var mats := StagedStructure.materials(key, params)
	var kinds := StagedMesh.surface_kinds(p_mesh)
	for s in p_mesh.get_surface_count() if p_mesh else 0:
		var k := kinds[s] if s < kinds.size() else StagedMesh.SOLID
		mi.set_surface_override_material(s, mats[StagedMesh.THIN if k == StagedMesh.THIN else StagedMesh.SOLID])


func _apply_mesh() -> void:
	if mesh == null:
		return
	if mesh_instance == null or not is_instance_valid(mesh_instance):
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Kit"
		add_child(mesh_instance)
	StagedStructure.dress(mesh_instance, mesh, material_key, material_params)
	if has_meta(&"kit_offset"):
		mesh_instance.position = get_meta(&"kit_offset")
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_push()


## Şantiyeye bağlar: durum her karede ondan okunur, aşama değişince geri düşüş canlanır.
func bind_site(p_site: SiteState) -> void:
	if site and site.stage_changed.is_connected(_on_stage_changed):
		site.stage_changed.disconnect(_on_stage_changed)
	site = p_site
	if site:
		site.stage_changed.connect(_on_stage_changed)
		_read_site()
	set_process(true)
	_push()


## Elle aşama (senaryo, ölçüm, geliştirme): stage en son biten, t sıradakinin oranı. animate: aşama düşerse düşen parçalar 0,6 sn'de çöker.
func set_stage(p_stage: int, t: float = 0.0, animate: bool = true) -> void:
	var prev := stage
	stage = clampi(p_stage, -1, 7)
	stage_t = clampf(t, 0.0, 1.0)
	if stage < prev and animate:
		_start_fall(prev)
	elif not animate:
		_fall_left = 0.0
	_push()
	if stage != prev:
		stage_shown.emit(stage)


## Vuruşun sallantısı (sn).
func jolt(seconds: float = 0.35) -> void:
	_shake_left = maxf(_shake_left, seconds)


func _on_stage_changed(now: int, prev: int) -> void:
	if now < prev:
		_start_fall(prev)
	stage_shown.emit(now)


func _start_fall(prev: int) -> void:
	_fall_from = prev
	_fall_left = FALL_S
	set_process(true)


func _read_site() -> void:
	if site == null:
		return
	stage = site.stage
	stage_t = site.stage_t
	damage = site.damage
	burn = site.burn
	tear = site.tear
	frame_on = 1.0 if site.tears > 0 or site.damage > 0.25 else frame_on


func _process(delta: float) -> void:
	if site:
		_read_site()
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		shake = 0.06 * _shake_left / 0.35
	elif shake > 0.0:
		shake = 0.0
	if _fall_left > 0.0:
		_fall_left = maxf(_fall_left - delta, 0.0)
	_push()
	if site == null and _fall_left <= 0.0 and _shake_left <= 0.0 and not _wants_process():
		set_process(false)


## Alt sınıf her karede çalışmak istiyor mu (oda, ateş)?
func _wants_process() -> bool:
	return false


## Tekdüzenleri yazar (kit ve ek çizimler: iç düzen, ped, stok aynı değerleri okur).
func _push() -> void:
	var falling := _fall_left > 0.0 and _fall_from > stage
	for gi in _instances():
		gi.set_instance_shader_parameter(&"stage", stage)
		gi.set_instance_shader_parameter(&"stage_t", stage_t)
		gi.set_instance_shader_parameter(&"fall_from", _fall_from if falling else -1)
		gi.set_instance_shader_parameter(&"fall_t", _fall_left / FALL_S if falling else 0.0)
		gi.set_instance_shader_parameter(&"damage", damage)
		gi.set_instance_shader_parameter(&"burn", burn)
		gi.set_instance_shader_parameter(&"tear", tear)
		gi.set_instance_shader_parameter(&"snow", snow)
		gi.set_instance_shader_parameter(&"cut", cut)
		gi.set_instance_shader_parameter(&"glow", glow)
		gi.set_instance_shader_parameter(&"frame_on", frame_on)
		gi.set_instance_shader_parameter(&"shake", shake)


func _instances() -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if mesh_instance and is_instance_valid(mesh_instance):
		out.append(mesh_instance)
	for gi in extra_instances:
		if is_instance_valid(gi):
			out.append(gi)
	return out


## Ek çizim (ped, stok, iç düzen): aynı tekdüzenleri alır.
func add_part(gi: GeometryInstance3D) -> void:
	extra_instances.append(gi)
	_push()


func refresh() -> void:
	_push()


# --- Engeller ------------------------------------------------------------------------------------------

## Oyuncunun çarpıştığı daireler: Vector3(x, z, r) dünya; aşama footprint_min_stage'in altındaysa yok.
func get_obstacle_circles() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if stage < footprint_min_stage or not is_inside_tree():
		return out
	var xf := global_transform
	var sx := xf.basis.get_scale().x
	for c: Variant in footprint.get("circles", []):
		var v: Vector3 = c
		var p := xf * Vector3(v.x, 0.0, v.y)
		out.append(Vector3(p.x, p.z, v.z * sx))
	return out


func get_obstacle_boxes() -> Array[ObstacleBox]:
	var out: Array[ObstacleBox] = []
	if stage < footprint_min_stage or not is_inside_tree():
		return out
	var xf := global_transform
	for b: Variant in footprint.get("boxes", []):
		var row: Array = b
		var c: Vector2 = row[0]
		var half: Vector2 = row[1]
		var ang := float(row[2]) if row.size() > 2 else 0.0
		var local := Transform3D(Basis(Vector3.UP, ang), Vector3(c.x, 0.0, c.y))
		var box := ObstacleBox.from_transform(xf * local, half * Vector2(xf.basis.get_scale().x, xf.basis.get_scale().z))
		out.append(box)
	return out
