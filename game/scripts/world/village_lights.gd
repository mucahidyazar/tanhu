@tool
class_name VillageLights
extends Node3D
## Göl kıyısındaki uzak köylerin sıcak ışıkları.
## Her küme, nehrin verilen z noktasında kıyıyı bulur ve oraya birkaç ışık serpiştirir.

@export var terrain_seed := 1207
## Kümelerin nehir boyunca z konumları; işaret, kıyı tarafını belirler (çift/tek sıra sağ/sol).
@export var cluster_z: PackedFloat32Array = PackedFloat32Array([-420.0, -540.0, -690.0, -820.0, -980.0, -1180.0, -1420.0, -1700.0])
@export var lights_per_cluster := 9
@export var light_color := Color(1.0, 0.68, 0.32)
@export var energy := 7.0
@export_tool_button("Yeniden oluştur", "Reload") var rebuild_button: Callable = rebuild


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	for child in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	var shape := TerrainShape.new(terrain_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var transforms: Array[Transform3D] = []
	for i in cluster_z.size():
		var z := cluster_z[i]
		var side := 1.0 if i % 2 == 0 else -1.0
		var shore := find_shore(shape, z, side)
		if shore == Vector2.INF:
			continue
		for _k in lights_per_cluster:
			var p := shore + Vector2(rng.randf_range(-28.0, 28.0), rng.randf_range(-22.0, 22.0)) + Vector2(side * 14.0, 0.0)
			var h := shape.height_at(p.x, p.y)
			if h < TerrainShape.WATER_LEVEL + 0.8 or h > TerrainShape.WATER_LEVEL + 14.0:
				continue
			var s := rng.randf_range(0.6, 1.1)
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), Vector3(p.x, h + 1.4, p.y)))
	var sphere := SphereMesh.new()
	sphere.radius = 0.8
	sphere.height = 1.6
	sphere.radial_segments = 8
	sphere.rings = 4
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Lights"
	mmi.multimesh = Scatter.make_multimesh(sphere, transforms)
	mmi.material_override = Style.glow(light_color, energy)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta(&"generated", true)
	add_child(mmi)


## Nehrin z noktasında, merkezden side yönünde ilerleyerek ilk kara noktasını bulur.
static func find_shore(shape: TerrainShape, z: float, side: float) -> Vector2:
	var river := shape.river_at(z)
	var x := river.x
	for step in 80:
		x += side * 5.0
		if shape.height_at(x, z) > TerrainShape.WATER_LEVEL + 1.0:
			return Vector2(x, z)
	return Vector2.INF
