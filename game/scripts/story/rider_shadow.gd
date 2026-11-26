class_name RiderShadow
extends RefCounted
## Sahnenin atlısının gölge vekili (iç harita bütçesi: gölge ≤1,5M üçgen; godot.md §7.2): atın ve binicinin Meshy ağları (≈98k üçgen)
## gölge düşürmez, onların yerine atın düğümüne bağlı ≈300 üçgenlik bir vekil yalnız gölge düşürür (SHADOWS_ONLY): gövde, boyun, baş,
## dört bacak, kuyruk; binicinin gövdesi, başı ve bacakları. Vekil atla gider, döner, eğilir; yürüyüşün bacak salınımı gölgede yoktur
## (uzak kamerada, K98, seçilmez). Yerel +Z atın önüdür, köken toynakların zeminidir; ölçüler kampın atınındır (horse_brown.json:
## boy 2,3 m, omuz 1,42 m, eyer 1,29 m). MeshyProp'un gölge vekilinin (SHADOW_PROXY_META) aynısıdır.
##   RiderShadow.attach(horse, rider_actor)        # rider_actor null olabilir (binicisiz at)

const NODE_NAME := "ShadowProxy"
## Vekilin parçaları: [biçim, yarıçap ya da ölçü, boy, merkez, eğim (derece, X ekseni çevresinde; + burun aşağı)].
const PARTS := [
	["capsule", 0.31, 1.78, Vector3(0.0, 1.13, -0.02), 90.0],
	["capsule", 0.16, 0.9, Vector3(0.0, 1.5, 0.78), 35.0],
	["capsule", 0.13, 0.62, Vector3(0.0, 1.62, 1.16), 120.0],
	["leg", 0.06, 0.92, Vector3(0.17, 0.46, 0.56), 0.0],
	["leg", 0.06, 0.92, Vector3(-0.17, 0.46, 0.56), 0.0],
	["leg", 0.06, 0.92, Vector3(0.17, 0.46, -0.58), 0.0],
	["leg", 0.06, 0.92, Vector3(-0.17, 0.46, -0.58), 0.0],
	["capsule", 0.07, 0.6, Vector3(0.0, 0.98, -1.02), -12.0],
]
const RIDER_PARTS := [
	["capsule", 0.19, 0.78, Vector3(0.0, 1.74, -0.06), 4.0],
	["sphere", 0.12, 0.0, Vector3(0.0, 2.22, -0.02), 0.0],
	["capsule", 0.07, 0.62, Vector3(0.3, 1.22, 0.06), 0.0],
	["capsule", 0.07, 0.62, Vector3(-0.3, 1.22, 0.06), 0.0],
]


## Atın ve binicinin ağlarının gölgesini kapatır, atın altına vekili ekler (ikinci çağrı vekili yenilemez). Döner: vekil.
static func attach(horse: Node3D, rider: Node3D = null) -> MeshInstance3D:
	if horse == null:
		return null
	for node: Node in [horse, rider]:
		if node == null:
			continue
		for gi in node.find_children("*", "GeometryInstance3D", true, false):
			if not gi.has_meta(MeshyProp.SHADOW_PROXY_META):
				(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var old := horse.get_node_or_null(NodePath(NODE_NAME)) as MeshInstance3D
	if old:
		return old
	var proxy := MeshInstance3D.new()
	proxy.name = NODE_NAME
	proxy.mesh = RiderShadow.mesh(rider != null)
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	proxy.set_meta(MeshyProp.SHADOW_PROXY_META, true)
	horse.add_child(proxy)
	return proxy


## Vekilin ağı (saf): at, isteğe bağlı binici.
static func mesh(with_rider: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts: Array = PARTS.duplicate()
	if with_rider:
		parts.append_array(RIDER_PARTS)
	for p: Array in parts:
		var shape := RiderShadow._primitive(str(p[0]), float(p[1]), float(p[2]))
		var xform := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(float(p[4]))), p[3])
		st.append_from(shape, 0, xform)
	var out := st.commit()
	return out


static func _primitive(kind: String, radius: float, height: float) -> PrimitiveMesh:
	match kind:
		"sphere":
			var s := SphereMesh.new()
			s.radius = radius
			s.height = radius * 2.0
			s.radial_segments = 8
			s.rings = 4
			return s
		"leg":
			var c := CylinderMesh.new()
			c.top_radius = radius
			c.bottom_radius = radius * 0.8
			c.height = height
			c.radial_segments = 6
			c.rings = 1
			return c
		_:
			var cap := CapsuleMesh.new()
			cap.radius = radius
			cap.height = maxf(height, radius * 2.0)
			cap.radial_segments = 8
			cap.rings = 2
			return cap
