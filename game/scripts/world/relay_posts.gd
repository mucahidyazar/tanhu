class_name RelayPosts
extends Node3D
## Menzil direkleri ve Yol Kemikleri (travel.md §4.2 «Menzil Direği», act1.md §4 «Yol Kemikleri»; Yol Haritası roads-relays): kodla çizilir,
## türü başına tek MultiMesh (bir çizim). Menzil Direği taş ayaklı, 1,1 m boyda direk, ucunda iple asılı tahta tokmak (≤120 üçgen). Yol Kemiği
## yüksek direk (2,3 m), taş yığını ayağı, tepedeki kirişte rüzgârda öten dört delikli kemik; kırık direk eğik ve kısa, kemikleri dibinde
## karda yatar. Renkler köşe rengidir (soft_toon use_vertex_color). Onarılan direk 120 m'den duyulur: haritanın ses profili bone_hum'u çalıyorsa
## (Kışlak, MapSoundscape) o çalar, yoksa bu düğüm (audio/ambience/gen/bone_hum.wav; AudioStreamPlayer3D, 120 m'de söner); direğe vuruş
## post_knock'tur (varsa).
##   var posts := RelayPosts.new(); add_child(posts)
##   posts.set_posts([{id, at: Vector3, yaw}])
##   posts.set_bones([{id, at: Vector3, yaw, repaired: bool}])

const HUM_PATH := "res://audio/ambience/gen/bone_hum.wav"
const KNOCK_PATH := "res://audio/sfx/gen/post_knock.wav"
const STONE := Color(0.55, 0.54, 0.52)
const STONE_DARK := Color(0.42, 0.41, 0.4)
const WOOD := Color(0.4, 0.27, 0.16)
const WOOD_DARK := Color(0.27, 0.17, 0.1)
const ROPE := Color(0.62, 0.52, 0.36)
const BONE := Color(0.9, 0.86, 0.76)
const RAG := Color(0.62, 0.16, 0.1)

var posts: Array = []
var bones: Array = []
var hum_m := 120.0
## Onarılan direğin uğultusunu bu düğüm mü çalar (set_own_hum).
var own_hum := true

var _post_mm: MultiMeshInstance3D
var _bone_mm: MultiMeshInstance3D
var _broken_mm: MultiMeshInstance3D
var _hums: Dictionary = {}
var _knock: AudioStreamPlayer3D


func _ready() -> void:
	var mat := Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.08})
	_post_mm = _make_mm("WaystationPosts", RelayPosts.post_mesh(), mat)
	_bone_mm = _make_mm("RoadBones", RelayPosts.bone_mesh(false), mat)
	_broken_mm = _make_mm("BrokenBones", RelayPosts.bone_mesh(true), mat)
	if ResourceLoader.exists(KNOCK_PATH):
		_knock = AudioStreamPlayer3D.new()
		_knock.name = "Knock"
		_knock.stream = load(KNOCK_PATH)
		_knock.bus = AudioUtil.bus_or_master(&"SFX")
		_knock.max_distance = 60.0
		add_child(_knock)
	_refresh()


func _make_mm(node_name: String, mesh: Mesh, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mmi.multimesh = mm
	mmi.material_override = mat
	# Görünürlük aralığı kutunun ortasından ölçülür; örnekler haritaya yayıldığı için aralık konmaz (≈3k üçgen, tek çizim).
	add_child(mmi)
	return mmi


## Menzil direkleri: [{id, at: Vector3 (zeminde), yaw}].
func set_posts(list: Array) -> void:
	posts = list.duplicate(true)
	_refresh()


## Yol Kemikleri: [{id, at: Vector3, yaw, repaired}].
func set_bones(list: Array) -> void:
	bones = list.duplicate(true)
	_refresh()


## Direğin durumu değişti (onarıldı).
func set_repaired(id: String, on: bool) -> void:
	for b: Dictionary in bones:
		if str(b.get("id", "")) == id:
			b["repaired"] = on
	_refresh()


## Direğe vuruşun sesi (post_knock varsa).
func knock(at: Vector3) -> void:
	if _knock:
		_knock.global_position = at + Vector3(0.0, 0.9, 0.0)
		_knock.play()


func _refresh() -> void:
	if _post_mm == null:
		return
	_fill(_post_mm, posts, func(_r: Dictionary) -> bool: return true)
	_fill(_bone_mm, bones, func(r: Dictionary) -> bool: return bool(r.get("repaired", false)))
	_fill(_broken_mm, bones, func(r: Dictionary) -> bool: return not bool(r.get("repaired", false)))
	_refresh_hums()


func _fill(mmi: MultiMeshInstance3D, list: Array, keep: Callable) -> void:
	var picked: Array = list.filter(keep)
	var mm := mmi.multimesh
	mm.instance_count = picked.size()
	for i in picked.size():
		var r: Dictionary = picked[i]
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(r.get("yaw", 0.0))), r["at"]))


## Direklerin kendi uğultusu açık mı: haritanın ses profili bone_hum'u kendisi çalıyorsa (MapSoundscape emitters; Kışlak) kapanır, çift ses olmaz.
func set_own_hum(on: bool) -> void:
	own_hum = on
	_refresh_hums()


## Onarılmış direklerin uğultusu: her birinde bir döngü, hum_m'de söner (ses yoksa ya da own_hum kapalıysa sessiz).
func _refresh_hums() -> void:
	var want := {}
	if own_hum and ResourceLoader.exists(HUM_PATH):
		for b: Dictionary in bones:
			if bool(b.get("repaired", false)):
				want[str(b["id"])] = b
	for id: String in _hums.keys():
		if not want.has(id):
			(_hums[id] as Node).queue_free()
			_hums.erase(id)
	for id: String in want:
		if _hums.has(id):
			continue
		var p := AudioStreamPlayer3D.new()
		p.name = "Hum_%s" % id
		var stream: AudioStream = AudioUtil.load_stream(HUM_PATH, true)
		p.stream = stream
		p.bus = AudioUtil.bus_or_master(&"Ambience")
		p.max_distance = hum_m
		p.unit_size = 12.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.volume_db = -8.0
		add_child(p)
		p.position = (want[id]["at"] as Vector3) + Vector3(0.0, 2.2, 0.0)
		p.play(randf() * 2.0)
		_hums[id] = p


# --- Ağlar (saf) -------------------------------------------------------------------------------------------------------

## Menzil Direği: taş ayak, 1,1 m direk, kiriş, ip ve tokmak (köşe renkli; ≤120 üçgen).
static func post_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	RelayPosts._add(st, RelayPosts._cyl(0.2, 0.26, 0.22, 6), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.11, 0.0)), STONE)
	RelayPosts._add(st, RelayPosts._cyl(0.045, 0.055, 1.1, 5), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.66, 0.0)), WOOD)
	RelayPosts._add(st, RelayPosts._box(Vector3(0.05, 0.05, 0.36)), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.18, 0.13)), WOOD_DARK)
	RelayPosts._add(st, RelayPosts._cyl(0.008, 0.008, 0.34, 3), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.29)), ROPE)
	# Tokmak: başı yatay silindir, sapı aşağı.
	RelayPosts._add(st, RelayPosts._cyl(0.05, 0.05, 0.18, 6), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, 0.8, 0.29)), WOOD_DARK)
	RelayPosts._add(st, RelayPosts._cyl(0.015, 0.015, 0.2, 3), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.7, 0.29)), WOOD)
	return st.commit()


## Yol Kemiği: taş yığını, 2,3 m direk, kiriş ve dört delikli kemik, kirişin ucunda kızıl keçe şerit (uzak kadrajda okunsun: K98); kırık: direk
## kısa ve eğik, kemikler ve kiriş dipte karda yatar.
static func bone_mesh(broken: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	RelayPosts._add(st, RelayPosts._cyl(0.3, 0.38, 0.22, 7), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.11, 0.0)), STONE_DARK)
	RelayPosts._add(st, RelayPosts._cyl(0.18, 0.26, 0.2, 6), Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.03, 0.31, -0.02)), STONE)
	if broken:
		var lean := Basis(Vector3.RIGHT, 0.42)
		RelayPosts._add(st, RelayPosts._cyl(0.05, 0.06, 1.15, 5), Transform3D(lean, lean * Vector3(0.0, 0.58, 0.0) + Vector3(0.0, 0.35, 0.0)), WOOD_DARK)
		RelayPosts._add(st, RelayPosts._box(Vector3(0.8, 0.06, 0.06)), Transform3D(Basis(Vector3.UP, 0.9), Vector3(0.45, 0.04, -0.4)), WOOD_DARK)
		for i in 3:
			var a := 0.7 + float(i) * 1.6
			var lying := Basis(Vector3.UP, a) * Basis(Vector3.BACK, PI * 0.5)
			RelayPosts._add(st, RelayPosts._cyl(0.04, 0.05, 0.46, 6), Transform3D(lying, Vector3(cos(a) * 0.6, 0.045, sin(a) * 0.6)), BONE)
		return st.commit()
	RelayPosts._add(st, RelayPosts._cyl(0.05, 0.065, 2.3, 6), Transform3D(Basis.IDENTITY, Vector3(0.0, 1.45, 0.0)), WOOD)
	RelayPosts._add(st, RelayPosts._box(Vector3(0.86, 0.06, 0.06)), Transform3D(Basis.IDENTITY, Vector3(0.0, 2.45, 0.0)), WOOD_DARK)
	for i in 4:
		var x := -0.33 + float(i) * 0.22
		var length := 0.42 + 0.06 * float((i * 3) % 4)
		RelayPosts._add(st, RelayPosts._cyl(0.008, 0.008, 0.12, 3), Transform3D(Basis.IDENTITY, Vector3(x, 2.37, 0.0)), ROPE)
		RelayPosts._add(st, RelayPosts._cyl(0.04, 0.05, length, 6), Transform3D(Basis.IDENTITY, Vector3(x, 2.31 - length * 0.5, 0.0)), BONE)
	RelayPosts._add(st, RelayPosts._box(Vector3(0.1, 0.62, 0.012)), Transform3D(Basis(Vector3.BACK, 0.08), Vector3(0.45, 2.12, 0.0)), RAG)
	return st.commit()


static func _cyl(top: float, bottom: float, height: float, segments: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


## İlkel ağı köşe rengiyle ekler (SurfaceTool'a; rengi her köşeye yazar).
static func _add(st: SurfaceTool, mesh: PrimitiveMesh, xform: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nb := xform.basis.inverse().transposed()
	for i in index:
		st.set_color(color)
		st.set_normal((nb * normals[i]).normalized())
		st.add_vertex(xform * verts[i])
