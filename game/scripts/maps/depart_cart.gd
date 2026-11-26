class_name DepartCart
extends Procedural3D
## Yola Çıkış'ın armağan arabası (story.md §6; docs-app story/childhood «Yola Çıkış»): Eskam'ın Yüeçi'ye götürdüğü armağanlar keçe
## örtülü, iki yüksek tekerlekli bir araba üstündedir (bozkırın keçe arabası; Han kaynaklarının 穹廬車'sı). Kodla çizilir (model yok):
## iki tekerlek (jant, göbek, on parmak), dingil, kasa ve yan tahtalar, kemerli keçe örtü (önünde kızıl bant, sırtında kar), arkada
## keçeye sarılı yük denkleri, öne uzanan iki ok. Çeken at arabanın değil dünyanındır (DepartWorld; RideableHorse, binilmez).
## Yerel +Z arabanın önüdür (okların ucu, atın yeri); düğümün yeri tekerleklerin altındaki zemindir.
##   var cart := DepartCart.new(); cart.transform = ...; add_child(cart)
##   cart.obstacle_box()                       # oyuncunun kutusu (kasa ve tekerlekler)
##   cart.horse_offset()                       # çeken atın yerel yeri (okların arası)

## Tekerleğin yarıçapı, iki tekerleğin arası (yarısı) ve dingilin kasaya göre yeri (m).
const WHEEL_RADIUS := 0.72
const WHEEL_TRACK := 0.92
const AXLE_Z := -0.15
## Kasa: genişlik, boy, kalınlık ve üst yüzünün yüksekliği (m).
const BED_SIZE := Vector3(1.5, 0.12, 2.6)
const BED_TOP := 0.92
const BED_Z := 0.05
## Keçe örtünün kemeri: genişlik, yükseklik, boy (m).
const COVER_SIZE := Vector3(1.56, 1.05, 2.0)
## Okların uzunluğu ve yarı aralığı (m).
const SHAFT_LENGTH := 2.5
const SHAFT_HALF := 0.46
## Kemerin parçalanması.
const ARCH_SEGMENTS := 18

const WOOD := Color(0.4, 0.26, 0.15)
const WOOD_DARK := Color(0.24, 0.15, 0.09)
const FELT_COVER := Color(0.44, 0.35, 0.27)
const FELT_BAND := Color(0.58, 0.12, 0.08)
const FELT_BALE := Color(0.86, 0.79, 0.66)
const SNOW := Color(0.88, 0.92, 1.0)


func _build() -> void:
	var wood := Style.toon(WOOD, {"stripe_count": 9.0, "stripe_strength": 0.3, "brush_strength": 0.12})
	var dark := Style.toon(WOOD_DARK, {"brush_strength": 0.1})
	for side: float in [-1.0, 1.0]:
		_build_wheel(Vector3(side * WHEEL_TRACK, WHEEL_RADIUS, AXLE_Z), dark, wood)
	var axle := add_mesh(cylinder(0.05, 0.05, WHEEL_TRACK * 2.0 + 0.2, 10), dark,
		Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, WHEEL_RADIUS, AXLE_Z)))
	axle.name = "Axle"
	var bed := add_mesh(box(BED_SIZE), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, BED_TOP - BED_SIZE.y * 0.5, BED_Z)))
	bed.name = "Bed"
	for side: float in [-1.0, 1.0]:
		var rail := add_mesh(box(Vector3(0.07, 0.22, BED_SIZE.z)), wood,
			Transform3D(Basis.IDENTITY, Vector3(side * (BED_SIZE.x * 0.5 - 0.035), BED_TOP + 0.11, BED_Z)))
		rail.name = "Rail%s" % ("L" if side < 0.0 else "R")
		# Oklar: kasanın önünden öne, atın iki yanında.
		var shaft := add_mesh(cylinder(0.035, 0.045, SHAFT_LENGTH, 8), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.06), Vector3(side * SHAFT_HALF, BED_TOP - 0.02 + 0.07, BED_Z + BED_SIZE.z * 0.5 + SHAFT_LENGTH * 0.5 - 0.1)))
		shaft.name = "Shaft%s" % ("L" if side < 0.0 else "R")
	var felt := Style.toon_double(FELT_COVER, {"brush_strength": 0.22})
	var cover_z := BED_Z - 0.18
	var cover := add_mesh(DepartCart.arch_mesh(COVER_SIZE.x * 0.5, COVER_SIZE.y, COVER_SIZE.z, ARCH_SEGMENTS), felt,
		Transform3D(Basis.IDENTITY, Vector3(0.0, BED_TOP + 0.02, cover_z)))
	cover.name = "Cover"
	# Kızıl bant örtünün ön ağzında; sırtındaki kar biraz dışarıda, yalnız tepede.
	var band := add_mesh(DepartCart.arch_mesh(COVER_SIZE.x * 0.5 + 0.015, COVER_SIZE.y + 0.015, 0.16, ARCH_SEGMENTS),
		Style.toon_double(FELT_BAND, {"brush_strength": 0.1}),
		Transform3D(Basis.IDENTITY, Vector3(0.0, BED_TOP + 0.02, cover_z + COVER_SIZE.z * 0.5 - 0.06)))
	band.name = "Band"
	var snow := add_mesh(DepartCart.arch_mesh(COVER_SIZE.x * 0.5 + 0.03, COVER_SIZE.y + 0.035, COVER_SIZE.z - 0.1, ARCH_SEGMENTS, 0.32),
		Style.toon(SNOW, {"brush_strength": 0.05}),
		Transform3D(Basis.IDENTITY, Vector3(0.0, BED_TOP + 0.02, cover_z)))
	snow.name = "Snow"
	snow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_load()


## Tekerlek: kalın jant, göbek ve on parmak; dingilin ekseni X.
func _build_wheel(at: Vector3, dark: Material, wood: Material) -> void:
	var pivot := add_pivot("Wheel%s" % ("L" if at.x < 0.0 else "R"), Transform3D(Basis.IDENTITY, at))
	var rim := add_mesh(torus(WHEEL_RADIUS - 0.08, WHEEL_RADIUS), dark, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), pivot)
	rim.name = "Rim"
	var hub := add_mesh(cylinder(0.12, 0.12, 0.24, 12), dark, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), pivot)
	hub.name = "Hub"
	for i in 10:
		var a := TAU * float(i) / 10.0
		var spoke := add_mesh(box(Vector3(0.05, WHEEL_RADIUS - 0.14, 0.05)), wood,
			Transform3D(Basis(Vector3.RIGHT, a), Vector3(0.0, cos(a), -sin(a)) * (WHEEL_RADIUS * 0.5)), pivot)
		spoke.name = "Spoke%d" % i


## Armağanların yükü: keçeye sarılı denkler ve iple bağlı bir sandık (örtünün arkasından taşar).
func _build_load() -> void:
	var bale := Style.toon(FELT_BALE, {"brush_strength": 0.2})
	var rope := Style.toon(Color(0.52, 0.4, 0.26))
	var back := BED_Z - BED_SIZE.z * 0.5
	var bales := [[Vector3(-0.38, 0.0, back + 0.42), 0.34, 0.92], [Vector3(0.36, 0.0, back + 0.4), 0.32, 0.86], [Vector3(-0.02, 0.32, back + 0.48), 0.3, 0.8]]
	for i in bales.size():
		var spec: Array = bales[i]
		var r: float = spec[1]
		var length: float = spec[2]
		var at: Vector3 = spec[0] + Vector3(0.0, BED_TOP + r, 0.0)
		var mi := add_mesh(cylinder(r, r, length, 14), bale, Transform3D(Basis(Vector3.BACK, PI * 0.5), at))
		mi.name = "Bale%d" % i
		for k: float in [-0.28, 0.28]:
			var tie := add_mesh(torus(r - 0.01, r + 0.025), rope, Transform3D(Basis(Vector3.BACK, PI * 0.5), at + Vector3(k * length, 0.0, 0.0)))
			tie.name = "Tie%d_%d" % [i, int(k > 0.0)]
	var chest := add_mesh(box(Vector3(0.62, 0.42, 0.5)), Style.toon(Color(0.32, 0.18, 0.11), {"stripe_count": 6.0, "stripe_strength": 0.3}),
		Transform3D(Basis(Vector3.UP, 0.12), Vector3(0.05, BED_TOP + 0.21, BED_Z + 0.55)))
	chest.name = "Chest"


## Oyuncunun kutusu (dünya; kasa ve tekerlekler).
func obstacle_box() -> ObstacleBox:
	var xform := global_transform if is_inside_tree() else transform
	var center := xform * Vector3(0.0, 0.0, BED_Z)
	return ObstacleBox.from_transform(Transform3D(xform.basis, center), Vector2(WHEEL_TRACK + 0.14, BED_SIZE.z * 0.5 + 0.05))


## Çeken atın yeri (yerel; okların arası, gap: atın sağrısıyla kasanın önü arası) ve atın yarı boyu (m).
static func horse_offset(half_length: float, gap: float) -> Vector3:
	return Vector3(0.0, 0.0, BED_Z + BED_SIZE.z * 0.5 + gap + half_length)


## Kemerli örtü (saf): yarı genişlik rx, yükseklik ry, boy length, Z boyunca; kesit yarım elips. top_share > 0 ise yalnız tepedeki pay
## (0..1, kemerin ortasından iki yana) çizilir (sırttaki kar). UV: x kemer boyunca (0..1), y boy boyunca.
static func arch_mesh(rx: float, ry: float, length: float, segments: int, top_share: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var from := PI * 0.5 * (1.0 - top_share)
	var to := PI - from
	var z0 := -length * 0.5
	var z1 := length * 0.5
	for i in segments:
		var a0 := lerpf(from, to, float(i) / float(segments))
		var a1 := lerpf(from, to, float(i + 1) / float(segments))
		var p0 := Vector3(cos(a0) * rx, sin(a0) * ry, 0.0)
		var p1 := Vector3(cos(a1) * rx, sin(a1) * ry, 0.0)
		var n0 := Vector3(cos(a0) / maxf(rx, 0.001), sin(a0) / maxf(ry, 0.001), 0.0).normalized()
		var n1 := Vector3(cos(a1) / maxf(rx, 0.001), sin(a1) / maxf(ry, 0.001), 0.0).normalized()
		var u0 := float(i) / float(segments)
		var u1 := float(i + 1) / float(segments)
		var quad := [[p0 + Vector3(0, 0, z0), n0, Vector2(u0, 0.0)], [p1 + Vector3(0, 0, z0), n1, Vector2(u1, 0.0)],
			[p0 + Vector3(0, 0, z1), n0, Vector2(u0, 1.0)], [p1 + Vector3(0, 0, z1), n1, Vector2(u1, 1.0)]]
		for idx: int in [0, 2, 1, 1, 2, 3]:
			st.set_normal(quad[idx][1])
			st.set_uv(quad[idx][2])
			st.add_vertex(quad[idx][0])
	return st.commit()
