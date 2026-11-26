@tool
class_name StagedYurt
extends StagedStructure
## Parametrik yurt (K51; godot.md §6.7; structures.md §3): üç eksen (boy, millet, düzen) ve hazır ayar. Kök boyla ölçeklenir (yatayda
## ×0,7 / ×1 / ×1,4, dikeyde ×0,84 / ×1 / ×1,18); iç düzen ve ped ters ölçekli çocuklardır (eşya ×1). Ağlar paylaşılır (YurtGeometry,
## YurtLayouts): yurdun durumu örnek tekdüzenidir (StagedStructure).
##
## Düğümler: Kit (aşama kitinin ağı), Interior/Layout (iç düzen; open ve iç isteyen ayarda), Pad/Ground (ped: zemini izleyen toprak ya da
## ezik kar; site), Hearth (ocak: köz ve alev, aşama 7 ve hearth_lit), Smoke (taçtan duman), Light (ocağın gölgesiz ışığı, yalnız açık
## yurtta ve ocak yanarken), ShadowTwin (oda kesitliyken gölgeyi kesilmemiş verir).
## Oda (K98): open yurtta odak (room_focus; yoksa takip kamerasının hedefi) duvarın içine girince cut 0,35 sn'de 1 olur: çatı kalkar,
## kameraya bakan duvar alçalır; içeride eşya kutuları engeldir. Kapalı yurtta (closed ya da open değil) iç yoktur, duvar dairedir.
##   var y := StagedYurt.new()
##   y.configure({"size": "m", "style": "yuezhi", "layout": "otaci", "preset": "winter", "open": true})
##   y.ground = map_world.ground          # ped zemini izlesin (HeightmapShape ya da TerrainShape)
##   add_child(y)

signal room_changed(inside: bool)

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const CUT_S := 0.35

@export var size := "m"
@export var style_id := "hun"
@export var layout := "ev"
@export var preset := YurtGeometry.WINTER
## İçine girilir mi (oda, iç düzen, halka duvar)?
@export var open := false
## Ped kurulsun mu (şantiye ve yeni yurt; Kışlak'ın yurtları da ezik karın üstündedir).
@export var with_pad := true
## Taçtan duman (ocak yanarken).
@export var smoke := true
## Ocak yanıyor mu (aşama 7'de; aşama 7'nin altına düşünce söner).
@export var hearth_lit := true
## Oda kendiliğinden mi (odak içeri girince kesit açılır); false ise cut elle verilir (geliştirme, sinema).
@export var room_auto := true

## Zemin (height_at(x, z)): ped onu izler. Yoksa düz.
var ground: Object
## Odanın odağı (oyuncu); yoksa takip kamerasının hedefi.
var room_focus: Node3D
var style: YurtStyle
var dims := {}
var interior: Node3D
var layout_mesh: MeshInstance3D
var pad: MeshInstance3D
var hearth: Node3D
var smoke_node: MeshInstance3D
var light: OmniLight3D
var shadow_twin: MeshInstance3D
var inside := false

var _cut_target := 0.0
var _room_check := 0.0
var _built := false


## Kaydın üç ekseni ve hazır ayarı (StructureKit.normalize'ın biçimi).
func configure(rec: Dictionary) -> void:
	size = str(rec.get("size", size))
	style_id = str(rec.get("style", style_id))
	layout = str(rec.get("layout", layout))
	preset = str(rec.get("preset", preset))
	open = bool(rec.get("open", open))
	smoke = bool(rec.get("smoke", smoke))
	hearth_lit = bool(rec.get("hearth", hearth_lit))
	with_pad = bool(rec.get("pad", with_pad))


func _ready() -> void:
	build()
	super._ready()
	set_process(true)


## Ağları kurar (bir kez; yeniden kurulumda çocuklar silinir).
func build() -> void:
	for c in get_children():
		if c.has_meta(&"yurt_part"):
			remove_child(c)
			c.queue_free()
	extra_instances.clear()
	mesh_instance = null
	shadow_twin = null
	pad = null
	layout_mesh = null
	interior = null
	hearth = null
	smoke_node = null
	light = null
	style = YurtStyle.find(style_id)
	dims = YurtGeometry.dims(style, size)
	var sc: Vector2 = dims["scale"]
	scale = Vector3(sc.x, sc.y, sc.x)
	kind = "yurt"
	material_key = "yurt_%s" % style.id
	material_params = {"motif_color": style.motif, "accent_color": style.accent, "cut_radius": style.radius() + 0.4,
		"cut_ceiling": style.crown_height() + 0.5, "cut_top": maxf(style.wall_height() - 0.35, 1.2), "cut_low": 0.55}
	mesh = YurtGeometry.mesh(style, size, preset)
	if mesh_instance:
		mesh_instance.set_meta(&"yurt_part", true)
	var inv := Vector3(1.0 / sc.x, 1.0 / sc.y, 1.0 / sc.x)
	if open and preset != YurtGeometry.CLOSED and preset != YurtGeometry.DOME:
		interior = Node3D.new()
		interior.name = "Interior"
		interior.scale = inv
		# Taban pedin iç düzlüğünün üstündedir (ped 0,05 m).
		interior.position = Vector3(0.0, 0.055 / sc.y, 0.0)
		interior.set_meta(&"yurt_part", true)
		add_child(interior)
		layout_mesh = MeshInstance3D.new()
		layout_mesh.name = "Layout"
		StagedStructure.dress(layout_mesh, YurtLayouts.mesh(layout, size, preset), "interior", {})
		layout_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		interior.add_child(layout_mesh)
		add_part(layout_mesh)
	if with_pad:
		_build_pad(inv)
	_build_hearth()
	footprint = _footprint()
	footprint_min_stage = 1
	_built = true
	_push()


## Ayak izi (yerel, kök ölçeğinden önce): kapalı yurtta daire; açık yurtta halka duvar (get_obstacle_walls) ve iç eşyanın kutuları.
func _footprint() -> Dictionary:
	var r := style.radius() + 0.25
	if open:
		var boxes: Array = []
		var sc: Vector2 = dims["scale"]
		for b: Array in YurtLayouts.boxes(layout, size, preset):
			var c: Vector2 = b[0]
			boxes.append([c / sc.x, b[1] / sc.x, float(b[2])])
		return {"circles": [Vector3(0.0, 0.25, 0.55)], "boxes": boxes}
	return {"circles": [Vector3(0.0, 0.0, r)], "boxes": []}


## Halka duvar (açık yurt, aşama ≥2: kerege): kapı aralığından girilir.
func get_obstacle_walls() -> Array[RingWall]:
	var out: Array[RingWall] = []
	if not open or stage < 2 or not is_inside_tree():
		return out
	var xf := global_transform
	var dir := Vector2(xf.basis.z.x, xf.basis.z.z).normalized()
	var r: float = dims.get("radius", 3.3)
	var door: Vector2 = dims.get("door", Vector2(0.95, 2.05))
	out.append(RingWall.new(Vector2(xf.origin.x, xf.origin.z), r, dir, door.x * 0.5, 0.18))
	return out


## Kapalı yurtta daire; açık yurtta yalnız ocak ve (aşama 7'de) eşya.
func get_obstacle_circles() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if not is_inside_tree():
		return out
	if not open:
		if stage >= 2:
			return super.get_obstacle_circles()
		if stage >= 1:
			# Yalnız bosağanın iki dikmesi.
			var door: Vector2 = dims.get("door", Vector2(0.95, 2.05))
			for s: float in [-1.0, 1.0]:
				var p := global_transform * Vector3(s * (door.x * 0.5 + 0.07) / maxf(scale.x, 0.01), 0.0, style.radius())
				out.append(Vector3(p.x, p.z, 0.16))
		return out
	if stage >= 7:
		return super.get_obstacle_circles()
	return out


func get_obstacle_boxes() -> Array[ObstacleBox]:
	if not open or stage < 7:
		return [] as Array[ObstacleBox]
	return super.get_obstacle_boxes()


## Kapı önünün dünya noktası (zeminde; kapıdan dışarı pay m).
func door_point(pad_out: float = 0.8) -> Vector3:
	var r: float = dims.get("radius", 3.3)
	return global_transform.origin + global_transform.basis.z.normalized() * (r + pad_out)


# --- Ped ---------------------------------------------------------------------------------------------------

## Ped (structures.md §11.3; Godot ölçüsü): içte düz (taban + 0,05), kenarda zemine iner; zemin daha yüksekse zeminin 2 cm üstü. Yerel
## uzayda (ters ölçekli çocuk), dünya metresiyle; aşama 0'da yükselir (RISE).
func _build_pad(inv: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "Pad"
	holder.scale = inv
	holder.set_meta(&"yurt_part", true)
	add_child(holder)
	var sm := StagedMesh.new()
	var r_in: float = dims["radius"] * 1.02
	var r_out: float = dims["pad"]
	var rings := 4
	var segs := 28
	var base := global_position if is_inside_tree() else position
	var col := Color("#7a6248") if snow < 0.5 else Color("#c9c4b8")
	sm.part(0, 0.05, StagedMesh.MODE_RISE, Vector3(0, -0.2, 0), StagedMesh.CLS_STONE)
	var c := sm.vertex(StagedMesh.SOLID, Vector3(0, 0.05, 0), Vector3.UP, col)
	var prev := PackedInt32Array()
	for ring in rings + 1:
		var t := float(ring) / float(rings)
		var r := lerpf(r_in * 0.5, r_out, t)
		var ids := PackedInt32Array()
		for k in segs:
			var a := TAU * float(k) / float(segs)
			var local := Vector3(sin(a) * r, 0.0, cos(a) * r)
			var world := global_transform * local if is_inside_tree() else local + base
			var gy := _ground_y(world.x, world.z) - base.y
			var y := 0.05
			if r > r_in:
				y = maxf(lerpf(0.05, gy, smoothstep(r_in, r_out, r)), gy + 0.02)
			else:
				y = maxf(0.05, gy + 0.02)
			var shade := lerpf(1.0, 0.86, t)
			ids.append(sm.vertex(StagedMesh.SOLID, Vector3(local.x, y, local.z), Vector3.UP, Color(col.r * shade, col.g * shade, col.b * shade)))
		if ring == 0:
			for k in segs:
				sm.tri(StagedMesh.SOLID, c, ids[(k + 1) % segs], ids[k])
		else:
			for k in segs:
				sm.quad(StagedMesh.SOLID, prev[k], prev[(k + 1) % segs], ids[(k + 1) % segs], ids[k])
		prev = ids
	pad = MeshInstance3D.new()
	pad.name = "Ground"
	StagedStructure.dress(pad, sm.commit(), "pad", {"brush_strength": 0.18})
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(pad)
	add_part(pad)


func _ground_y(x: float, z: float) -> float:
	if ground and ground.has_method(&"height_at"):
		return float(ground.call(&"height_at", x, z))
	return global_position.y if is_inside_tree() else position.y


# --- Ocak, duman, ışık ---------------------------------------------------------------------------------------

func _build_hearth() -> void:
	var sc: Vector2 = dims["scale"]
	if smoke:
		smoke_node = Fx.smoke(Vector2(1.4, 2.4), Vector2(-0.5, -0.12))
		smoke_node.name = "Smoke"
		smoke_node.position = Vector3(0.0, style.crown_height() + 0.1, 0.0)
		smoke_node.scale = Vector3(1.0 / sc.x, 1.0 / sc.y, 1.0 / sc.x)
		smoke_node.set_meta(&"yurt_part", true)
		add_child(smoke_node)
	if not open and preset != YurtGeometry.CLOSED and preset != YurtGeometry.DOME:
		# Kapalı yurdun inik kapı keçesi (içine girilmez): aşama 7'de kapıyı örter.
		var door: Vector2 = style.door_size()
		var felt := MeshInstance3D.new()
		felt.name = "DoorFelt"
		var sm := StagedMesh.new()
		sm.part(7, YurtGeometry.ESIK_FROM + 0.03, StagedMesh.MODE_RISE, Vector3(0, door.y, style.radius() + 0.06), StagedMesh.CLS_FELT)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(0, door.y * 0.5, style.radius() + 0.06)), Vector3(door.x + 0.08, door.y, 0.05), style.felt.darkened(0.22))
		sm.part(7, YurtGeometry.ESIK_FROM + 0.03, StagedMesh.MODE_RISE, Vector3(0, door.y, style.radius() + 0.06), StagedMesh.CLS_GLOW)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(door.x * 0.47, door.y * 0.45, style.radius() + 0.07)), Vector3(0.04, door.y * 0.8, 0.02), Color("#ff9a4a"))
		StagedStructure.dress(felt, sm.commit(), material_key, material_params)
		felt.set_meta(&"yurt_part", true)
		add_child(felt)
		add_part(felt)
	if not open or preset == YurtGeometry.CLOSED or preset == YurtGeometry.DOME:
		return
	hearth = Node3D.new()
	hearth.name = "Hearth"
	hearth.position = Vector3(0.0, 0.0, 0.25)
	hearth.scale = Vector3(1.0 / sc.x, 1.0 / sc.y, 1.0 / sc.x)
	hearth.set_meta(&"yurt_part", true)
	add_child(hearth)
	var bed := MeshInstance3D.new()
	bed.name = "Embers"
	bed.mesh = MeshKit.disc(0.24, 0.03, 12)
	bed.material_override = Style.glow(Color(1.0, 0.4, 0.12), 2.4)
	bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hearth.add_child(bed)
	for i in 2:
		var size_v := Vector2(0.42, 0.55) * (1.0 - 0.3 * float(i))
		var quad := QuadMesh.new()
		quad.size = size_v
		quad.center_offset = Vector3(0.0, size_v.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = FLAME_SHADER
		mat.set_shader_parameter("energy", 1.1 - 0.2 * float(i))
		mat.set_shader_parameter("speed", 1.6 + 0.5 * float(i))
		mat.set_shader_parameter("seed", 0.3 + 0.41 * float(i))
		var mi := MeshInstance3D.new()
		mi.name = "Flame%d" % i
		mi.mesh = quad
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0.05 * float(i), 0.02, 0.0)
		hearth.add_child(mi)
	light = OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = 1.6
	light.omni_range = float(dims["radius"]) * 1.05
	light.omni_attenuation = 0.9
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 0.0
	light.position = Vector3(0.0, 0.9, 0.0)
	hearth.add_child(light)


## Ocak, duman ve ışık aşamaya ve hearth_lit'e uyar.
func _sync_fire() -> void:
	var lit := hearth_lit and stage >= 7
	if hearth:
		hearth.visible = lit
	if smoke_node:
		smoke_node.visible = lit
	if light:
		light.visible = lit


# --- Oda ---------------------------------------------------------------------------------------------------

func _focus() -> Node3D:
	if is_instance_valid(room_focus):
		return room_focus
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var p := cam.get_parent() if cam else null
	var t: Variant = p.get(&"target") if p else null
	return t as Node3D if t is Node3D else null


func _process(delta: float) -> void:
	super._process(delta)
	_sync_fire()
	if not open or Engine.is_editor_hint():
		return
	if not room_auto:
		return
	_room_check -= delta
	if _room_check <= 0.0:
		_room_check = 0.1
		var f := _focus()
		var now := false
		if f and stage >= 6:
			var d := Vector2(f.global_position.x - global_position.x, f.global_position.z - global_position.z).length()
			now = d < float(dims.get("radius", 3.3)) - 0.15
		if now != inside:
			inside = now
			_cut_target = 1.0 if inside else 0.0
			room_changed.emit(inside)
	if not is_equal_approx(cut, _cut_target):
		cut = move_toward(cut, _cut_target, delta / CUT_S)
		_sync_shadow_twin()
		_push()


## Oda kesitliyken kit gölge vermez; kesilmemiş ikizi yalnız gölge verir (içeride de çatı ay ışığını keser).
func _sync_shadow_twin() -> void:
	if mesh_instance == null:
		return
	var cutting := cut > 0.01
	if cutting and shadow_twin == null:
		shadow_twin = MeshInstance3D.new()
		shadow_twin.name = "ShadowTwin"
		shadow_twin.set_meta(&"yurt_part", true)
		StagedStructure.dress(shadow_twin, mesh, material_key, material_params)
		shadow_twin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		add_child(shadow_twin)
		add_part(shadow_twin)
	if shadow_twin:
		shadow_twin.visible = cutting
		shadow_twin.set_instance_shader_parameter(&"cut", 0.0)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if cutting else (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func _push() -> void:
	super._push()
	if shadow_twin and is_instance_valid(shadow_twin):
		shadow_twin.set_instance_shader_parameter(&"cut", 0.0)
	_sync_fire()


func _wants_process() -> bool:
	return open


## Üçgen sayısı (kit, iç, ped; ölçüm ve sınama).
func triangles() -> Dictionary:
	return {
		"kit": StagedMesh.triangles_of(mesh), "interior": StagedMesh.triangles_of(layout_mesh.mesh) if layout_mesh else 0,
		"pad": StagedMesh.triangles_of(pad.mesh) if pad else 0,
	}
