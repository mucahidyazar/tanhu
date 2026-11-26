@tool
class_name Kopuz
extends Procedural3D
## Ozanın kopuzu (K60): üç telli, perdesiz, parmakla çalınan uzun saplı lavta. Armut gövde; göğsün alt üçte ikisi
## açık renkli deri, üst üçte biri ve sap koyu ahşap; üst gövdede iki ses deliği, yanda üç burgu, deride eşik,
## altta kuyruk. Boyu LENGTH (0,95 m; K60 ≈90–100 cm). Konsept: assets/_concepts/kopuz.png.
##
## Meshy modeli (E7.6): res://assets/props/kopuz/kopuz.glb varsa o gösterilir (MeshyProp gibi: gerçek boyuna
## ölçeklenir, tabanı düğümün yerine oturur, AtW dokulu malzemeyle) ve kod çizmez; yoksa (ya da MeshyProp.models_enabled
## kapalıyken) kopuz kodla çizilir. Düğüm yolu (CampNpcs/Elder/Kopuz) ve kimlik (kopuz) ikisinde de aynıdır.
## Yerel uzay eski dombra eşyasınınkidir: taban (kuyruk) düğümün yerinde, sap +Y, deri göğüs +Z'ye bakar. Model de bu
## düzendedir (ölçüldü: boy 1,90 birim, ölçek 0,5; en geniş yer ±0,137 m, sap ±0,018 m ve ortada); göğsü MODEL_FACE_Z
## kadar öndedir, o pay çekilince GRIP, STRUM ve sahnedeki pozlar iki görünümde aynı yere düşer.
##
## İki poz: kucak (düğümün sahnedeki dönüşümü, rest_transform) ve çalış (play_transform: sap sola-yukarı, gövde
## göğse yakın). KopuzPlay ikisi arasında kaldırır, ozanın sol elini sapa (grip_point), sağ elini tellere
## (strum_point) götürür.
##
## Kodla çizimin bütçesi: aynı malzemeli parçalar birleşir; ahşap, deri, donanım, ses delikleri ve üç tel: 7 çizim (eski
## dombra modeli 1). Yalnız ahşap ve deri gölge verir. (WIDE karesi ölçüldü: görünür 426 / 800, gölge 94 / 600.) Model
## tek çizimdir (19,3k üçgen).

const MODEL_PATH := "res://assets/props/kopuz/kopuz.glb"
const MESHY_SHADER := preload("res://shaders/atw_textured.gdshader")
## Boy (metre; tabandan kafanın tepesine).
const LENGTH := 0.95
## Modelin deri göğsü ve sapının önü, sınır kutusu ortalanınca z = +0,02 m'de durur (arkası z = −0,049 m'de: kase
## derindir); kodla çizimin göğsü z = 0'dadır. Model bu kadar geri çekilir: GRIP sapın kesit ortasında, STRUM tellerin hemen
## önünde kalır.
const MODEL_FACE_Z := 0.02
## Gövde: tabandan sapın başladığı yere dek boy, en geniş yerin yüksekliği ve yarı genişliği; gövdenin derinliği
## yarı genişliğin bu katıdır (oyulmuş kase).
const BODY_LENGTH := 0.47
const WIDE_AT := 0.165
const HALF_WIDTH := 0.135
const DEPTH_RATIO := 0.62
## Sap: yarı genişlik (gövdeye birleştiği yerde ve üstte), tepesi (kafanın başladığı yer).
const NECK_HALF_WIDTH := 0.021
const NECK_TOP_HALF_WIDTH := 0.018
const NECK_TOP := 0.80
## Kafa: boy ve geriye yatışı (derece).
const HEAD_LENGTH := 0.15
const HEAD_TILT_DEG := 8.0
## Deri göğsün üst sınırı: ortada SKIN_TOP, kenarlara doğru x² ile yükselen yay (konseptteki gibi).
const SKIN_TOP := 0.285
const SKIN_SAG := 2.3
## Eşik ve kuyruk (tabandan yükseklik).
const BRIDGE_Y := 0.193
const TAIL_Y := 0.03
## Üç tel: eşikte ve sapın başında (üst eşik) yandan uzaklıkları; tel yarıçapı (uzaktan okunsun diye ≈2,5 kat kalın).
const STRING_SPREAD_BRIDGE := 0.022
const STRING_SPREAD_NUT := 0.007
const STRING_RADIUS := 0.0018
const STRING_COUNT := 3
## Ozanın elleri (kopuzun yerel uzayında): sol elin kavradığı yer sapın kesit ortası, sağ elin vurduğu yer derinin üst ucunda
## tellerin üstü. Elin bu noktalara göre duruşu KopuzPlay'dedir.
const GRIP := Vector3(0.0, 0.64, -0.012)
const STRUM := Vector3(0.0, 0.29, 0.03)

## Renkler konseptin (kahverengi ahşap, ham deri) ateş ışığındaki karşılığıdır: deri ateşte parlamasın diye bir
## ton koyu (yakın planda ve 16 m'lik menü karesinde denetlendi).
const WOOD := Color(0.47, 0.27, 0.13)
const WOOD_DARK := Color(0.28, 0.16, 0.08)
const SKIN := Color(0.76, 0.65, 0.47)
const STRING_COLOR := Color(0.9, 0.84, 0.68)
const HOLE := Color(0.08, 0.05, 0.04)

## Çalış pozu (ebeveyn uzayında; sahnede ozanın kucağına göre). Kucak pozu düğümün kendi dönüşümüdür.
@export var play_transform := Transform3D.IDENTITY
## Meshy modelinin yolu (testler sahte bir sahne verir).
@export var model_path := MODEL_PATH:
	set(value):
		model_path = value
		queue_rebuild()

## Kucak pozu: düğümün sahneye girdiği dönüşüm.
var rest_transform := Transform3D.IDENTITY

var _model: Node3D
var _skin: MeshInstance3D
var _wood: MeshInstance3D
var _strings: Array[MeshInstance3D] = []


func _ready() -> void:
	rest_transform = transform
	super._ready()


## Meshy modeli mi gösteriliyor?
func has_model() -> bool:
	return _model != null


## Kodla mı çizildi?
func is_drawn() -> bool:
	return _model == null and _wood != null


## Modelin dosyası var mı (MeshyProp'un genel anahtarı da açık mı)?
func model_available() -> bool:
	return MeshyProp.models_enabled and not model_path.is_empty() and ResourceLoader.exists(model_path)


## Deri göğüs (kodla çizimde; yoksa null).
func get_skin() -> MeshInstance3D:
	return _skin


## Üç tel (kodla çizimde; yoksa boş).
func get_strings() -> Array[MeshInstance3D]:
	return _strings.duplicate()


## Görünen parçaların bu düğümün yerel uzayındaki sınır kutusu.
func local_bounds() -> AABB:
	var box := AABB()
	var first := true
	for node in find_children("*", "VisualInstance3D", true, false):
		var vi := node as VisualInstance3D
		var local := Kopuz.relative_transform(self, vi) * vi.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box


## Boy (metre): görünen parçaların yerel Y uzunluğu (düğümün ölçeği hariç).
func get_length() -> float:
	return local_bounds().size.y


## Sol elin kavradığı yer ve sağ elin vurduğu yer (dünya uzayında). across: vuruşun teller boyunca dik kayması (metre).
func grip_point() -> Vector3:
	return to_global(GRIP)


func strum_point(across: float = 0.0) -> Vector3:
	return to_global(STRUM + Vector3(across, 0.0, 0.0))


## Kucak (0) ile çalış (1) pozu arası.
func set_lift(weight: float) -> void:
	transform = rest_transform.interpolate_with(play_transform, clampf(weight, 0.0, 1.0))


func _build() -> void:
	_model = null
	_skin = null
	_wood = null
	_strings.clear()
	if model_available() and _build_model():
		return
	_build_drawn()


# --- Meshy modeli ---------------------------------------------------------------------------------

func _build_model() -> bool:
	var scene := load(model_path) as PackedScene
	var model := scene.instantiate() as Node3D if scene else null
	if model == null:
		return false
	model.name = "Model"
	add_generated(model)
	var box := Kopuz.visual_bounds(model)
	var s := LENGTH / box.size.y if box.size.y > 0.0001 else 1.0
	model.scale = Vector3.ONE * s
	model.position = MeshyProp.placement_offset(box, s, 0.0) - Vector3(0.0, 0.0, MODEL_FACE_Z)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if src == null or src.albedo_texture == null:
				continue
			var mat := ShaderMaterial.new()
			mat.shader = MESHY_SHADER
			mat.set_shader_parameter("albedo_texture", src.albedo_texture)
			mat.set_shader_parameter("albedo_tint", Color.WHITE)
			mat.set_shader_parameter("ink_strength", 0.25)
			mat.set_shader_parameter("brush_strength", 0.05)
			mat.set_shader_parameter("model_base_y", mi.get_aabb().position.y)
			mat.set_shader_parameter("model_scale", s)
			mi.set_surface_override_material(i, mat)
	_model = model
	return true


# --- Kodla çizim ----------------------------------------------------------------------------------

func _build_drawn() -> void:
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Oyulmuş kase: gövdenin arkası, ön yüz z = 0'da.
	wood.append_from(Kopuz.scaled(MeshKit.lathe(Kopuz.body_profile(18), 20, 1.0, PI, TAU), Vector3(1.0, 1.0, DEPTH_RATIO)), 0, Transform3D.IDENTITY)
	# Göğsün ahşap üst üçte biri.
	wood.append_from(Kopuz.flat_mesh(Kopuz.face_polygon(10, 8)), 0, Transform3D.IDENTITY)
	# Sap: yarım yuvarlak arka ve düz ön.
	var neck_profile := PackedVector2Array([Vector2(NECK_HALF_WIDTH, BODY_LENGTH - 0.04), Vector2(NECK_TOP_HALF_WIDTH, NECK_TOP)])
	wood.append_from(Kopuz.scaled(MeshKit.lathe(neck_profile, 10, 1.0, PI, TAU), Vector3(1.0, 1.0, 1.25)), 0, Transform3D.IDENTITY)
	var board_length := NECK_TOP - BODY_LENGTH + 0.04
	wood.append_from(box(Vector3(NECK_TOP_HALF_WIDTH * 2.0, board_length, 0.004)), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, BODY_LENGTH - 0.04 + board_length * 0.5, 0.0)))
	# Kafa: geriye yatık levha ve yuvarlak tepe.
	var head := Kopuz.head_transform()
	wood.append_from(box(Vector3(0.05, HEAD_LENGTH - 0.02, 0.022)), 0, head * Transform3D(Basis.IDENTITY, Vector3(0.0, (HEAD_LENGTH - 0.02) * 0.5, -0.006)))
	wood.append_from(Kopuz.scaled(sphere(0.025, 0.8), Vector3(1.0, 1.0, 0.44)), 0, head * Transform3D(Basis.IDENTITY, Vector3(0.0, HEAD_LENGTH - 0.02, -0.006)))
	_wood = add_mesh(wood.commit(), Style.toon(WOOD, {"brush_strength": 0.1, "brush_scale": 14.0}))
	_wood.name = "Wood"
	# Deri göğüs: ayrı yüzey, açık bej ve benekli (konseptteki ham deri).
	_skin = add_mesh(Kopuz.flat_mesh(Kopuz.skin_polygon(10, 8)), Style.toon(SKIN, {"brush_strength": 0.22, "brush_scale": 26.0}))
	_skin.name = "Skin"
	# Donanım: burgular, eşik, kuyruk ve ses delikleri (küçük: gölge vermez).
	var fittings := SurfaceTool.new()
	fittings.begin(Mesh.PRIMITIVE_TRIANGLES)
	var peg := MeshKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.005, 0.0), Vector2(0.005, 0.028),
		Vector2(0.011, 0.042), Vector2(0.013, 0.056), Vector2(0.009, 0.068), Vector2(0.0, 0.071)]), 8)
	for i in 3:
		var at := head * Vector3(0.022, 0.035 + 0.035 * i, -0.006)
		fittings.append_from(peg, 0, Transform3D(head.basis * Basis(Vector3.BACK, -PI * 0.5), at))
	fittings.append_from(box(Vector3(0.082, 0.012, 0.016)), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, BRIDGE_Y, 0.008)))
	fittings.append_from(box(Vector3(0.046, 0.034, 0.012)), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, TAIL_Y - 0.008, 0.005)))
	var fittings_mi := add_mesh(fittings.commit(), Style.toon(WOOD_DARK, {"brush_strength": 0.05}))
	fittings_mi.name = "Fittings"
	fittings_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var holes := SurfaceTool.new()
	holes.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		# Disk +Y'ye bakar: önce +Z'ye çevrilir, sonra daraltılır (normal +Z kalır) ve f deliği gibi yatırılır.
		var disc := Kopuz.scaled(MeshKit.disc(0.022, 0.0, 10), Vector3(0.55, 1.0, 1.0))
		holes.append_from(disc, 0, Transform3D(Basis(Vector3.BACK, side * 0.25) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * 0.046, 0.355, 0.0015)))
	var holes_mi := add_mesh(holes.commit(), Style.toon(HOLE, {"brush_strength": 0.0}))
	holes_mi.name = "SoundHoles"
	holes_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Üç tel: kuyruktan eşiğin üstünden üst eşiğe.
	var string_mat := Style.toon(STRING_COLOR, {"brush_strength": 0.0})
	for i in STRING_COUNT:
		var k := float(i - 1)
		var tail := Vector3(k * STRING_SPREAD_BRIDGE * 0.45, TAIL_Y, 0.011)
		var bridge := Vector3(k * STRING_SPREAD_BRIDGE, BRIDGE_Y, 0.017)
		var nut := Vector3(k * STRING_SPREAD_NUT, NECK_TOP, 0.006)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for pair: Array in [[tail, bridge], [bridge, nut]]:
			var a: Vector3 = pair[0]
			var b: Vector3 = pair[1]
			st.append_from(cylinder(STRING_RADIUS, STRING_RADIUS, a.distance_to(b), 5), 0, limb_transform(a, b))
		var mi := add_mesh(st.commit(), string_mat)
		mi.name = "String%d" % (i + 1)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_strings.append(mi)


## Gövdenin ve sapın ön görünüşteki yarı genişliği (metre) y yüksekliğinde (saf): alt kısım elips çeyreği, en
## geniş yerden sapa armut gibi S eğrisiyle daralır, sapta NECK_HALF_WIDTH'tan NECK_TOP_HALF_WIDTH'a iner.
static func half_width(y: float) -> float:
	if y <= 0.0:
		return 0.0
	if y < WIDE_AT:
		var u := (WIDE_AT - y) / WIDE_AT
		return HALF_WIDTH * sqrt(maxf(1.0 - u * u, 0.0))
	if y < BODY_LENGTH:
		var t := (y - WIDE_AT) / (BODY_LENGTH - WIDE_AT)
		return lerpf(HALF_WIDTH, NECK_HALF_WIDTH, smoothstep(0.0, 1.0, t))
	return lerpf(NECK_HALF_WIDTH, NECK_TOP_HALF_WIDTH, clampf((y - BODY_LENGTH) / (NECK_TOP - BODY_LENGTH), 0.0, 1.0))


## Derinin üst sınırı x'te (saf): ortada SKIN_TOP, kenarlara doğru yükselir.
static func skin_top(x: float) -> float:
	return SKIN_TOP + SKIN_SAG * x * x


## Derinin üst sınırının gövde kenarına değdiği yükseklik (saf; ikiye bölmeyle).
static func skin_edge_y() -> float:
	var lo := SKIN_TOP
	var hi := BODY_LENGTH
	for i in 40:
		var mid := (lo + hi) * 0.5
		if mid - skin_top(half_width(mid)) < 0.0:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## Gövde kasesinin döndürme profili: tabandan sapın başına (Vector2(yarı genişlik, y)).
static func body_profile(steps: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps + 1:
		var u := float(i) / float(steps)
		# Tabanda sık örnek: yuvarlak dip düzgün kapansın.
		var y := BODY_LENGTH * (u * u * (3.0 - 2.0 * u) * 0.35 + u * 0.65)
		out.append(Vector2(half_width(y), y))
	return out


## Deri göğsün çokgeni (ön görünüş, saat yönünün tersine): sağ kenar tabandan yukarı, yay boyunca sola, sol kenar aşağı.
static func skin_polygon(side_steps: int, arc_steps: int) -> PackedVector2Array:
	var top := skin_edge_y()
	var edge := half_width(top)
	var out := PackedVector2Array([Vector2(0.0, 0.0)])
	for i in range(1, side_steps + 1):
		var y := top * float(i) / float(side_steps)
		out.append(Vector2(half_width(y), y))
	for i in range(1, arc_steps):
		var x := edge * (1.0 - 2.0 * float(i) / float(arc_steps))
		out.append(Vector2(x, skin_top(x)))
	for i in range(side_steps, 0, -1):
		var y := top * float(i) / float(side_steps)
		out.append(Vector2(-half_width(y), y))
	return out


## Göğsün ahşap üst kısmının çokgeni (saat yönünün tersine): yay soldan sağa, sağ kenar yukarı, sapın başı, sol kenar aşağı.
static func face_polygon(side_steps: int, arc_steps: int) -> PackedVector2Array:
	var bottom := skin_edge_y()
	var edge := half_width(bottom)
	var out := PackedVector2Array()
	for i in arc_steps + 1:
		var x := -edge + 2.0 * edge * float(i) / float(arc_steps)
		out.append(Vector2(x, skin_top(x)))
	for i in range(1, side_steps + 1):
		var y := lerpf(bottom, BODY_LENGTH, float(i) / float(side_steps))
		out.append(Vector2(half_width(y), y))
	for i in range(side_steps, 0, -1):
		var y := lerpf(bottom, BODY_LENGTH, float(i) / float(side_steps))
		out.append(Vector2(-half_width(y), y))
	return out


## Düz çokgen ağı z = 0'da, +Z'ye bakan (Godot'da ön yüz: önden bakınca saat yönünde üçgen).
static func flat_mesh(polygon: PackedVector2Array) -> ArrayMesh:
	var indices := Geometry2D.triangulate_polygon(polygon)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in polygon:
		st.set_normal(Vector3.BACK)
		st.set_uv(Vector2(p.x / (HALF_WIDTH * 2.0) + 0.5, 1.0 - p.y / BODY_LENGTH))
		st.add_vertex(Vector3(p.x, p.y, 0.0))
	for t in range(0, indices.size(), 3):
		var a := indices[t]
		var b := indices[t + 1]
		var c := indices[t + 2]
		var cross := (polygon[b] - polygon[a]).cross(polygon[c] - polygon[a])
		if cross > 0.0:
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
		else:
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
	return st.commit()


## Ağın eşit olmayan ölçekli kopyası (saf): köşeler ölçekle, normaller ters ölçekle çarpılıp birim yapılır
## (SurfaceTool.append_from normali ölçeğin kendisiyle çarpar; yassıltılmış kasede gölgeleme kayardı).
static func scaled(mesh: Mesh, factor: Vector3) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			verts[i] = verts[i] * factor
		arrays[Mesh.ARRAY_VERTEX] = verts
		if arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array:
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in normals.size():
				normals[i] = (normals[i] / factor).normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals
		# Teğetler ölçekle bozulur; düz toon gölgelendiricisi kullanmaz.
		arrays[Mesh.ARRAY_TANGENT] = null
		var primitive := (mesh as ArrayMesh).surface_get_primitive_type(s) if mesh is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
		out.add_surface_from_arrays(primitive, arrays)
	return out


## Kafanın dönüşümü (yerel uzayda): sapın tepesinde, geriye yatık.
static func head_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(HEAD_TILT_DEG)), Vector3(0.0, NECK_TOP, -0.004))


## Kökün altındaki görünen parçaların kökün uzayındaki birleşik sınır kutusu (saf).
static func visual_bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var vi := node as VisualInstance3D
		var local := Kopuz.relative_transform(root, vi) * vi.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box


static func relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			xform = (n as Node3D).transform * xform
		n = n.get_parent()
	return xform
