extends TestCase
## Keçe araba gövdesi (E19 yol denemesi; tools/cart_body.py): Meshy'nin tekerleksiz gövdesi kodla çizilen tekerlekle birleşir. Tekerlek
## DepartCart'ınkidir (scripts/maps/depart_cart.gd: yarıçap, iz, jant, göbek). Dosyalar henüz yoksa testler atlar.

const GLB := "res://assets/props/cart_felt/cart_felt.glb"
const META := "res://assets/props/cart_felt/cart_felt.json"
## DepartCart'ın tekerleği: jant tüpü iz ± 0,04 m, göbek yarıçapı 0,12 m (_build_wheel).
const RIM_HALF := 0.04
const HUB_RADIUS := 0.12


func _skip(path: String) -> bool:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return false
	print("    atlandı: %s yok" % path)
	return true


func _find(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var hit := _find(child, type_name)
		if hit:
			return hit
	return null


func _meta() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(META))


func _vertices(mesh: Mesh) -> PackedVector3Array:
	var out := PackedVector3Array()
	for s in mesh.get_surface_count():
		out.append_array(mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
	return out


func test_body_matches_its_measurements() -> void:
	if _skip(GLB) or _skip(META):
		return
	var meta := _meta()
	var scene := (load(GLB) as PackedScene).instantiate()
	add_child(scene)
	var mesh := _find(scene, "MeshInstance3D") as MeshInstance3D
	assert_not_null(mesh, "Gövde ağı")
	var box := mesh.mesh.get_aabb()
	var lo: Array = meta["box"]["min"]
	var hi: Array = meta["box"]["max"]
	assert_vec_almost(box.position, Vector3(lo[0], lo[1], lo[2]), 0.01, "Kutunun altı ölçüyle aynı")
	assert_vec_almost(box.end, Vector3(hi[0], hi[1], hi[2]), 0.01, "Kutunun üstü ölçüyle aynı")
	assert_true(box.position.y > 0.3, "Gövde tekerleğin üstünde, yerden yüksek (%.2f m)" % box.position.y)
	# +Z ön: okların uçları kasanın önünde.
	var tips: Dictionary = meta["shaft_tips"]
	assert_true(float(tips["L"][2]) > float(meta["bed"]["max"][2]) and float(tips["R"][2]) > float(meta["bed"]["max"][2]), "Oklar +Z'de")
	assert_true(float(tips["L"][0]) > 0.0 and float(tips["R"][0]) < 0.0, "+X arabanın solu")
	var texture := (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
	assert_true(texture.get_width() <= 1024, "Doku prop sınıfında (8K oyuna taşınmaz)")
	scene.queue_free()


func test_code_wheels_fit_the_body() -> void:
	if _skip(GLB) or _skip(META):
		return
	var meta := _meta()
	assert_almost(float(meta["wheel_radius"]), DepartCart.WHEEL_RADIUS, 0.0001, "Tekerlek DepartCart'ın yarıçapında")
	assert_almost(float(meta["wheel_track"]), DepartCart.WHEEL_TRACK, 0.0001, "Tekerlek DepartCart'ın izinde")
	var axle: Array = meta["axle"]
	assert_vec_almost(Vector3(axle[0], axle[1], axle[2]), Vector3(0.0, DepartCart.WHEEL_RADIUS, 0.0), 0.001, "Dingil zeminin tekerlek yarıçapı üstünde")
	# Dingilin ucu göbeğin içinde (göbek iz ± 0,12) ve iki uç aynı z'de (eğik dingil düzeltildi).
	assert_true(absf(float(meta["axle_stub_x"]) - DepartCart.WHEEL_TRACK) < HUB_RADIUS, "Dingil ucu göbeğin içinde")
	assert_true(absf(float(meta["axle_stub_skew_z"])) < 0.02, "Dingilin iki ucu aynı hizada")
	var scene := (load(GLB) as PackedScene).instantiate()
	add_child(scene)
	var mesh := _find(scene, "MeshInstance3D") as MeshInstance3D
	var inside := 0
	for v: Vector3 in _vertices(mesh.mesh):
		if absf(absf(v.x) - DepartCart.WHEEL_TRACK) > RIM_HALF:
			continue
		var r := Vector2(v.y - DepartCart.WHEEL_RADIUS, v.z).length()
		if r > HUB_RADIUS + 0.01 and r < DepartCart.WHEEL_RADIUS + 0.01:
			inside += 1
	assert_eq(inside, 0, "Gövdenin hiçbir köşesi tekerleğin jant ve parmak düzleminde değil")
	scene.queue_free()


func test_code_wheel_builds_on_the_body() -> void:
	if _skip(GLB) or _skip(META):
		return
	# Kodla tekerlek: DepartCart'ın tekerlek düğümleri gövdenin dingil uçlarına oturur.
	var cart := DepartCart.new()
	add_child(cart)
	await wait_frames(1)
	var wheels := cart.find_children("Wheel*", "", true, false)
	assert_eq(wheels.size(), 2, "İki tekerlek düğümü")
	var meta := _meta()
	for wheel: Node in wheels:
		var at := (wheel as Node3D).position
		assert_almost(absf(at.x), float(meta["wheel_track"]), 0.001, "%s izde" % wheel.name)
		assert_almost(at.y, float(meta["axle"][1]), 0.001, "%s dingil yüksekliğinde" % wheel.name)
	cart.queue_free()
