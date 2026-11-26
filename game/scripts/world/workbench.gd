class_name Workbench
extends Node3D
## Bir tezgâhın dünyadaki yeri (economy.md §6.7; deneme haritasının toplama katmanı): kodla kurulan görünüş ve engel dairesi. Demirci Ocağı
## (smithy: taş ocak, közü parlar, örs kütüğün üstünde, deri körük), Ağaç Atölyesi (wood_shop: iki ayaklı tezgâh, üstünde keser ve
## yontulmuş kütük, yanında odun istifi), öteki tezgâhlar sade bir sandık ve kütük. Tezgâhın sandığı (ItemContainer) ve kuyruğu
## (Workshop) katmanındır; bu düğüm yalnız görünüş ve erimdir. Uzak kadrajda (K98) okunsun diye parçalar gerçeğin biraz üstündedir.
##   var bench := Workbench.new(); bench.station = "smithy"; add_child(bench); bench.place(at, yaw)

const RADIUS := 1.25
const SCALE := 1.2
const EMBER := Color("#ff7a2a")

## Tezgâh kimliği (data/economy/stations.json) ve katmanın kaydındaki kimlik.
var station := "wood_shop"
var bench_id := ""
var obstacle_radius := RADIUS


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	_build()


func place(at: Vector3, yaw: float) -> void:
	position = at
	rotation.y = yaw


## Erim: tezgâhın kenarına uzaklık (m; saf olmayan, düğümün yeri).
func distance_to(p: Vector3) -> float:
	var d := Vector2(p.x - global_position.x, p.z - global_position.z).length() if is_inside_tree() else Vector2(p.x - position.x, p.z - position.z).length()
	return maxf(0.0, d - obstacle_radius)


func get_obstacle_circles() -> Array[Vector3]:
	var p := global_position if is_inside_tree() else position
	return [Vector3(p.x, p.z, obstacle_radius)]


func _build() -> void:
	var parts: Array = []
	var glow: Array = []
	match station:
		"smithy":
			# Taş ocak halkası, köz, örs kütüğü ve örs, deri körük.
			for k in 8:
				var a := TAU * k / 8.0
				parts.append([MeshKit.rock(1700 + k, 1), Transform3D(Basis().scaled(Vector3.ONE * 0.26), Vector3(cos(a) * 0.5, 0.0, sin(a) * 0.5) + Vector3(-0.45, 0, 0)), GatherMeshes.STONE])
			glow.append([GatherMeshes._sphere(0.36, 0.1, 8, 3), Transform3D(Basis(), Vector3(-0.45, 0.06, 0.0)), EMBER])
			parts.append([GatherMeshes._cyl(0.26, 0.3, 0.55, 9), Transform3D(Basis(), Vector3(0.55, 0.275, 0.0)), GatherMeshes.BARK])
			parts.append([GatherMeshes._box(Vector3(0.42, 0.14, 0.18)), Transform3D(Basis(), Vector3(0.55, 0.62, 0.0)), GatherMeshes.METAL])
			parts.append([GatherMeshes._box(Vector3(0.16, 0.06, 0.12)), Transform3D(Basis(), Vector3(0.81, 0.66, 0.0)), GatherMeshes.METAL.lightened(0.15)])
			parts.append([GatherMeshes._sphere(0.3, 0.22, 8, 4), Transform3D(Basis(Vector3.UP, 0.4), Vector3(-0.55, 0.12, 0.72)), Color("#6b4a30")])
			parts.append([GatherMeshes._cyl(0.03, 0.03, 0.5, 5), Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5) * Basis(Vector3.UP, 0.0), Vector3(-0.3, 0.14, 0.5)), GatherMeshes.WOOD])
		"wood_shop":
			# İki ayaklı tezgâh, tahta, keser, yontulmuş kütük, odun istifi.
			for side: float in [-0.75, 0.75]:
				for leg: float in [-0.22, 0.22]:
					parts.append([GatherMeshes._cyl(0.05, 0.05, 0.74, 5), Transform3D(Basis(Vector3(1, 0, 0), leg * 0.6), Vector3(side, 0.36, leg)), GatherMeshes.WOOD_DARK])
			parts.append([GatherMeshes._box(Vector3(2.0, 0.08, 0.52)), Transform3D(Basis(), Vector3(0, 0.76, 0)), GatherMeshes.WOOD])
			parts.append([GatherMeshes._cyl(0.14, 0.14, 0.9, 7), Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0.1, 0.94, 0.0)), GatherMeshes.CUT])
			parts.append([GatherMeshes._box(Vector3(0.05, 0.4, 0.04)), Transform3D(Basis(Vector3(0, 0, 1), 1.1), Vector3(-0.6, 0.86, 0.12)), GatherMeshes.WOOD_DARK])
			parts.append([GatherMeshes._box(Vector3(0.12, 0.06, 0.1)), Transform3D(Basis(), Vector3(-0.78, 0.84, 0.12)), GatherMeshes.METAL])
			for k in 5:
				var row := k / 3
				parts.append([GatherMeshes._cyl(0.11, 0.11, 1.0, 7), Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(-0.3 + (k % 3) * 0.24 + row * 0.12, 0.11 + row * 0.2, 0.85)), GatherMeshes.CUT.darkened(0.12)])
		_:
			parts.append([GatherMeshes._cyl(0.3, 0.34, 0.55, 9), Transform3D(Basis(), Vector3(0, 0.275, 0)), GatherMeshes.BARK])
	# Tezgâhın sandığı (her tezgâhta): kapaklı ahşap kutu.
	parts.append([GatherMeshes._box(Vector3(0.62, 0.38, 0.4)), Transform3D(Basis(), Vector3(0.0, 0.19, -0.78)), GatherMeshes.WOOD.darkened(0.1)])
	parts.append([GatherMeshes._box(Vector3(0.66, 0.06, 0.44)), Transform3D(Basis(), Vector3(0.0, 0.41, -0.78)), GatherMeshes.WOOD_DARK])
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = GatherMeshes.merge(parts)
	mi.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.12})
	mi.scale = Vector3.ONE * SCALE
	add_child(mi)
	if not glow.is_empty():
		var g := MeshInstance3D.new()
		g.name = "Embers"
		g.mesh = GatherMeshes.merge(glow)
		g.material_override = Style.glow(EMBER, 2.2)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.scale = Vector3.ONE * SCALE
		add_child(g)
