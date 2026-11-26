class_name FeltPanel
extends Procedural3D
## Keçe aplike pano (Yol Haritası myth-panels; story.md §3 satır 1–6, godot.md §3.6): data/cine/myth_panels.json'daki
## bir panonun katmanlarını kurar. Her katman bir MeshInstance3D'dir: dış hat (FeltShapes) Geometry2D.triangulate_polygon
## ile üçgenlenir, kenarına dış halka ve içe kaydırılmış halkayla dikiş şeridi kurulur (şerit dış kenarda z = 0'dan iç
## halkada keçenin kalınlığına yükselir: parçanın yumuşak kenarı). Bütün katmanlar tek felt_panel malzemesini paylaşır;
## rengi, ipliği ve parıltıyı örnek tekdüzenleri verir. Katmanlar z derinliğiyle dizilir: kamera geçerken paralaks olur.
##
## Katman: {id, shape, p, pos [x, y], z, rot (derece), scale (sayı ya da [sx, sy]), mirror, color, stitch_color,
##   emission, stitch (şerit genişliği), parent (başka katmanın id'si), shadow (false: gölge düşürmez), keep, anim [kancalar]}.
## Görsel (gpt-image-2) gelince panonun image alanına yolu yazılır: zemin (base) görseli felt_panel'in use_albedo_texture'ıyla
## taşır; image_only (varsayılan true) ise kodla şekiller kurulmaz, yalnız zemin, köz (ember) ve keep'li katmanlar kalır.
## Kancalar (zaman, panonun yazıldığı saattir: tahmini satır süreleriyle; warp gerçek saati ona çevirir):
##   appear {t0, t1}, vanish {t0, t1}, move {keys [[t, x, y]]}, rotate {keys [[t, derece]]}, scale {keys [[t, sx, sy]]},
##   bob {amp [ax, ay], period, phase, until}, sway {amp (derece), period, phase}, flap {amp, period, phase, from, to},
##   orbit {center, radius [rx, ry], period, phase, t0, face}, glow {keys [[t, e]]}.
## Ücretsiz keçe dokusu (Fabric034, CC0) malzemeye bağlanır; kullanan her ağ free_asset meta verisini taşır (K89, E7.5).

const SHADER := preload("res://shaders/felt_panel.gdshader")
const DATA_PATH := "res://data/cine/myth_panels.json"
const FELT_ALBEDO := "res://assets/_free/texture/fabric034/Fabric034_2K-JPG_Color.jpg"
const FELT_NORMAL := "res://assets/_free/texture/fabric034/Fabric034_2K-JPG_NormalGL.jpg"
const FREE_ASSET := "fabric034"
## Keçenin kalınlığı (m): şerit bu kadar yükselir.
const THICKNESS := 0.012
## İç halkanın köşedeki uzaması (sivri köşede şerit taşmasın) ve ince yerde karşı kenara olan uzaklığın en çok payı.
const MITER_MIN := 0.35
const SAFE_DEPTH := 0.45
## İç halka kendini keserse şerit bu oranla daralır, en çok STITCH_TRIES deneme.
const STITCH_SHRINK := 0.55
const STITCH_TRIES := 5
const HIDDEN_SCALE := 0.001
## Ağsız katman türü (dönme noktası) ve görselli panoda görseli taşıyan zemin katmanı.
const PIVOT := "pivot"
const BASE_LAYER := "base"

## Panonun sırası (1–6; myth_panels.json'daki panels[i - 1]).
@export var panel_index := 1:
	set(value):
		panel_index = value
		queue_rebuild()

## Panonun tanımı (kurulurken veriden okunur; sınama elle verebilir).
var panel: Dictionary = {}
## Canlandırma saati (sn, panonun başından; AnimationPlayer sürer).
var anim_time := 0.0:
	set(value):
		anim_time = value
		apply_time(value)
## Gerçek saat → yazıldığı saat: [[gerçek, yazılan], ...] (boşsa ikisi aynı).
var warp: Array = []

## Katmanlar: id → {node, def, pos, z, rot, scale}.
var layers: Dictionary = {}

static var _data: Dictionary = {}
static var _material: ShaderMaterial


## Panoların verisi (önbellekli).
static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(DATA_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func clear_cache() -> void:
	_data = {}


static func panel_defs() -> Array:
	var list: Variant = data().get("panels", [])
	return list if list is Array else []


## Bütün panoların paylaştığı keçe malzemesi: Fabric034 dokusu varsa onunla.
static func felt_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		var textured := ResourceLoader.exists(FELT_ALBEDO) and ResourceLoader.exists(FELT_NORMAL)
		_material.set_shader_parameter(&"use_textures", textured)
		if textured:
			_material.set_shader_parameter(&"felt_albedo", load(FELT_ALBEDO))
			_material.set_shader_parameter(&"felt_normal", load(FELT_NORMAL))
	return _material


## Malzeme keçe dokusunu kullanıyor mu?
static func uses_free_texture() -> bool:
	return bool(felt_material().get_shader_parameter(&"use_textures"))


func _build() -> void:
	layers.clear()
	if panel.is_empty():
		var defs := panel_defs()
		if panel_index >= 1 and panel_index <= defs.size():
			panel = defs[panel_index - 1]
	if panel.is_empty():
		return
	var raw: Variant = panel.get("layers", [])
	var image_only := has_image() and bool(panel.get("image_only", true))
	for item: Variant in (raw if raw is Array else []):
		if item is Dictionary:
			# Görselli panoda (gpt-image-2) kodla şekiller kurulmaz: zemin görseli taşır; köz ve keep'li katman kalır.
			if image_only and not _kept_with_image(item):
				continue
			_add_layer(item)
	apply_time(anim_time)


## Panonun görseli (gpt-image-2; panels[].image) var ve yüklenebilir mi?
func has_image() -> bool:
	var image: Variant = panel.get("image")
	return image is String and not (image as String).is_empty() and ResourceLoader.exists(image)


func _kept_with_image(def: Dictionary) -> bool:
	var layer_id := str(def.get("id", ""))
	return layer_id == BASE_LAYER or layer_id == str(panel.get("ember", "")) or bool(def.get("keep", false))


## Görselli panonun zemin malzemesi: keçe malzemesinin kopyası, görsel zeminin dikdörtgenine oturur.
func _image_material(def: Dictionary) -> ShaderMaterial:
	var mat := felt_material().duplicate() as ShaderMaterial
	var p: Dictionary = def["p"] if def.get("p") is Dictionary else {}
	var w := float(p.get("w", 5.2))
	var h := float(p.get("h", 2.8))
	mat.set_shader_parameter(&"use_albedo_texture", true)
	mat.set_shader_parameter(&"albedo_texture", load(str(panel["image"])))
	mat.set_shader_parameter(&"albedo_rect", Vector4(-w * 0.5, -h * 0.5, w, h))
	return mat


## Katmanın düğümü (ağ ya da dönme noktası; yoksa null).
func layer_node(layer_id: String) -> Node3D:
	var entry: Dictionary = layers.get(layer_id, {})
	return entry.get("node")


## Katmanın ağ düğümleri (dönme noktaları hariç).
func meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for layer_id: String in layers:
		var node: Variant = layers[layer_id]["node"]
		if node is MeshInstance3D:
			out.append(node)
	return out


## Yazıldığı saatin gerçek karşılığı (written_time'ın tersi; kamera anahtarları için).
func real_time(te: float) -> float:
	if warp.size() < 2:
		return te
	var first: Array = warp[0]
	if te <= float(first[1]):
		return float(first[0]) + te - float(first[1])
	for i in range(1, warp.size()):
		var a: Array = warp[i - 1]
		var b: Array = warp[i]
		if te <= float(b[1]):
			var span := float(b[1]) - float(a[1])
			var u := (te - float(a[1])) / span if span > 0.0 else 1.0
			return lerpf(float(a[0]), float(b[0]), u)
	var last: Array = warp[warp.size() - 1]
	return float(last[0]) + te - float(last[1])


## Kancaları t anına (gerçek saat, panonun başından) göre uygular.
func apply_time(t: float) -> void:
	var te := written_time(t)
	for layer_id: String in layers:
		_apply_layer(layers[layer_id], te)


## Gerçek saati panonun yazıldığı saate çevirir (warp; yoksa aynı). Uçların dışında eğim 1'dir.
func written_time(t: float) -> float:
	if warp.size() < 2:
		return t
	var first: Array = warp[0]
	if t <= float(first[0]):
		return float(first[1]) + t - float(first[0])
	for i in range(1, warp.size()):
		var a: Array = warp[i - 1]
		var b: Array = warp[i]
		if t <= float(b[0]):
			var span := float(b[0]) - float(a[0])
			var u := (t - float(a[0])) / span if span > 0.0 else 1.0
			return lerpf(float(a[1]), float(b[1]), u)
	var last: Array = warp[warp.size() - 1]
	return float(last[1]) + t - float(last[0])


# --- Ağ ---------------------------------------------------------------------------------------------

## Dış hatlardan keçe parçası: iç dolgu (keçenin kalınlığında) ve kenarda dikiş şeridi. Dış hat saat yönünün tersindedir;
## Godot'nun ön yüzü saat yönünde olduğu için üçgenler ters sırayla yazılır (ön yüz +z'ye, kameraya bakar).
## UV: x yay uzunluğu (m), y şeritte 0 → 1, dolguda 1. UV2: yerel x, y (m).
static func build_mesh(outlines: Array[PackedVector2Array], stitch: float, thickness: float = THICKNESS) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()
	for outline in outlines:
		_add_piece(outline, stitch, thickness, verts, normals, uvs, uv2s, indices)
	if indices.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## İç halka: her köşe iç açıortay boyunca stitch kadar içeri (sivri köşede en çok stitch / MITER_MIN). İnce yerde
## (gaganın ucu, dalın ucu) köşe karşı kenara olan uzaklığın SAFE_DEPTH'inden derine inmez: iki yanın iç halkası
## birbirini kesmez, şerit orada daralır.
static func inset(outline: PackedVector2Array, stitch: float) -> PackedVector2Array:
	var n := outline.size()
	var out := PackedVector2Array()
	out.resize(n)
	for i in n:
		var p := outline[i]
		var e_prev := (p - outline[(i - 1 + n) % n]).normalized()
		var e_next := (outline[(i + 1) % n] - p).normalized()
		var n_prev := Vector2(-e_prev.y, e_prev.x)
		var n_next := Vector2(-e_next.y, e_next.x)
		var m := n_prev + n_next
		m = m.normalized() if m.length_squared() > 1e-9 else n_next
		var depth := stitch / maxf(m.dot(n_next), MITER_MIN)
		# Açıortay boyunca karşı kenara ilk çarpma (komşu iki kenar hariç); yalnız derinliğin birkaç katı aranır.
		var far := p + m * (depth / SAFE_DEPTH + 0.001)
		var hit_at := INF
		for j in n:
			if j == i or (j + 1) % n == i:
				continue
			var hit: Variant = Geometry2D.segment_intersects_segment(p, far, outline[j], outline[(j + 1) % n])
			if hit != null:
				hit_at = minf(hit_at, p.distance_to(hit))
		out[i] = p + m * minf(depth, hit_at * SAFE_DEPTH)
	return out


## Dikiş şeridinin iç halkası: inset; kendini keserse şerit daraltılarak (×STITCH_SHRINK) yeniden denenir. Olmazsa
## boş döner: parça şeritsiz, düz keçe olarak kurulur (çok küçük yıldız gibi).
static func inner_ring(outline: PackedVector2Array, stitch: float) -> PackedVector2Array:
	var w := stitch
	for attempt in STITCH_TRIES:
		if w <= 0.0:
			break
		var inner := inset(outline, w)
		if not FeltShapes.self_intersects(inner):
			return inner
		w *= STITCH_SHRINK
	return PackedVector2Array()


static func _add_piece(outline: PackedVector2Array, stitch: float, thickness: float, verts: PackedVector3Array,
		normals: PackedVector3Array, uvs: PackedVector2Array, uv2s: PackedVector2Array, indices: PackedInt32Array) -> void:
	var n := outline.size()
	if n < 3:
		return
	var inner := inner_ring(outline, stitch)
	var fill_tris := Geometry2D.triangulate_polygon(inner) if inner.size() == n else PackedInt32Array()
	var banded := not fill_tris.is_empty()
	var top := inner if banded else outline
	if not banded:
		fill_tris = Geometry2D.triangulate_polygon(outline)
		if fill_tris.is_empty():
			return
	# Dolgu: keçenin üst yüzü.
	var base := verts.size()
	for p in top:
		verts.append(Vector3(p.x, p.y, thickness))
		normals.append(Vector3.BACK)
		uvs.append(Vector2(0.0, 1.0))
		uv2s.append(p)
	for k in range(0, fill_tris.size(), 3):
		indices.append_array([base + fill_tris[k], base + fill_tris[k + 2], base + fill_tris[k + 1]])
	if not banded:
		return
	# Şerit: dış kenar (z = 0, dışa eğik normal) ile iç halka (keçenin kalınlığı) arasında; ilk köşe sonda yinelenir
	# (yay uzunluğu dikişte sıfıra dönmesin).
	var length := 0.0
	var band := verts.size()
	for j in n + 1:
		var i := j % n
		if j > 0:
			length += outline[i].distance_to(outline[j - 1])
		var out_dir := (outline[i] - inner[i]).normalized()
		verts.append(Vector3(outline[i].x, outline[i].y, 0.0))
		normals.append(Vector3(out_dir.x * 1.3, out_dir.y * 1.3, 1.0).normalized())
		uvs.append(Vector2(length, 0.0))
		uv2s.append(outline[i])
		verts.append(Vector3(inner[i].x, inner[i].y, thickness))
		normals.append(Vector3(out_dir.x * 0.15, out_dir.y * 0.15, 1.0).normalized())
		uvs.append(Vector2(length, 1.0))
		uv2s.append(inner[i])
	for j in n:
		var o0 := band + j * 2
		var i0 := o0 + 1
		var o1 := o0 + 2
		var i1 := o0 + 3
		indices.append_array([o0, i0, o1, i0, i1, o1])


# --- Katmanlar --------------------------------------------------------------------------------------

func _add_layer(def: Dictionary) -> void:
	var layer_id := str(def.get("id", "layer_%d" % layers.size()))
	var kind := str(def.get("shape", "rect"))
	var p: Dictionary = def["p"] if def.get("p") is Dictionary else {}
	if kind == PIVOT:
		_add_pivot_layer(layer_id, def)
		return
	var outlines := FeltShapes.make(kind, p)
	if bool(def.get("mirror", false)):
		outlines = mirrored(outlines)
	var stitch := FeltShapes.recommended_stitch(kind, p, float(def.get("stitch", data().get("stitch", FeltShapes.STITCH))))
	var mesh := build_mesh(outlines, stitch, float(data().get("thickness", THICKNESS)))
	if mesh == null:
		push_warning("FeltPanel %s: «%s» katmanı (%s) üçgenlenemedi" % [panel.get("id", "?"), layer_id, kind])
		return
	var node := MeshInstance3D.new()
	node.name = layer_id.validate_node_name()
	node.mesh = mesh
	node.material_override = _image_material(def) if layer_id == BASE_LAYER and has_image() else felt_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(def.get("shadow", true)) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_instance_shader_parameter(&"shape_color", _color(def.get("color"), Color(0.8, 0.72, 0.6)))
	node.set_instance_shader_parameter(&"stitch_color", _color(def.get("stitch_color"), Color(0, 0, 0, 0)))
	node.set_instance_shader_parameter(&"emission", float(def.get("emission", 0.0)))
	node.set_instance_shader_parameter(&"seed", float(abs(hash(layer_id)) % 997) * 0.1)
	node.set_instance_shader_parameter(&"pattern", 0)
	if uses_free_texture():
		node.set_meta(&"free_asset", FREE_ASSET)
	var parent_entry: Dictionary = layers.get(str(def.get("parent", "")), {})
	var parent_node: Node = parent_entry.get("node", self)
	add_generated(node, parent_node)
	_store(layer_id, node, def)


## Boş dönme noktası (ör. Yedi Karakçı'nın kazık çevresinde dönen öbeği): ağsız Node3D, kancaları alır.
func _add_pivot_layer(layer_id: String, def: Dictionary) -> void:
	var node := Node3D.new()
	node.name = layer_id.validate_node_name()
	var parent_entry: Dictionary = layers.get(str(def.get("parent", "")), {})
	add_generated(node, parent_entry.get("node", self))
	_store(layer_id, node, def)


func _store(layer_id: String, node: Node3D, def: Dictionary) -> void:
	var pos: Array = def["pos"] if def.get("pos") is Array else [0.0, 0.0]
	var scale_v: Variant = def.get("scale", 1.0)
	var sc := Vector2(float(scale_v[0]), float(scale_v[1])) if scale_v is Array else Vector2.ONE * float(scale_v)
	layers[layer_id] = {"node": node, "def": def, "pos": Vector2(float(pos[0]), float(pos[1])),
		"z": float(def.get("z", 0.05)), "rot": deg_to_rad(float(def.get("rot", 0.0))), "scale": sc,
		"emission": float(def.get("emission", 0.0)), "anim": def.get("anim", [])}


## Ayna (x → -x): ağ ters ölçekle değil, dış hattın kendisi çevrilerek kurulur (ön yüz kameraya bakmaya devam etsin).
static func mirrored(outlines: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for outline in outlines:
		var m := PackedVector2Array()
		for i in range(outline.size() - 1, -1, -1):
			m.append(Vector2(-outline[i].x, outline[i].y))
		out.append(m)
	return out


func _apply_layer(entry: Dictionary, te: float) -> void:
	var node: Node3D = entry["node"]
	if not is_instance_valid(node):
		return
	var pos: Vector2 = entry["pos"]
	var rot: float = entry["rot"]
	var sc: Vector2 = entry["scale"]
	var shown := 1.0
	var glow := float(entry["emission"])
	var anim: Variant = entry["anim"]
	for hook: Variant in (anim if anim is Array else []):
		if not hook is Dictionary:
			continue
		var h: Dictionary = hook
		match str(h.get("type", "")):
			"appear":
				shown *= _smooth(float(h.get("t0", 0.0)), float(h.get("t1", 0.5)), te)
			"vanish":
				shown *= 1.0 - _smooth(float(h.get("t0", 0.0)), float(h.get("t1", 0.5)), te)
			"move":
				var v := _keys(h.get("keys"), te, 2)
				if not v.is_empty():
					pos = Vector2(v[0], v[1])
			"rotate":
				var r := _keys(h.get("keys"), te, 1)
				if not r.is_empty():
					rot = entry["rot"] + deg_to_rad(r[0])
			"scale":
				var s := _keys(h.get("keys"), te, 2)
				if not s.is_empty():
					sc = Vector2(entry["scale"].x * s[0], entry["scale"].y * s[1])
			"bob":
				var amp: Array = h["amp"] if h.get("amp") is Array else [0.0, 0.03]
				var w := TAU / maxf(float(h.get("period", 3.0)), 0.01)
				var ph := float(h.get("phase", 0.0))
				var damp := 1.0 - _smooth(float(h.get("until", 1e9)), float(h.get("until", 1e9)) + 1.5, te)
				pos += Vector2(float(amp[0]) * sin(w * te + ph), float(amp[1]) * sin(w * te + ph + 1.3)) * damp
			"sway":
				var damp_s := 1.0 - _smooth(float(h.get("until", 1e9)), float(h.get("until", 1e9)) + 1.5, te)
				rot += deg_to_rad(float(h.get("amp", 4.0))) * sin(TAU / maxf(float(h.get("period", 4.0)), 0.01) * te
						+ float(h.get("phase", 0.0))) * damp_s
			"flap":
				var on := _smooth(float(h.get("from", -1e9)), float(h.get("from", -1e9)) + 0.4, te) \
						* (1.0 - _smooth(float(h.get("to", 1e9)), float(h.get("to", 1e9)) + 0.4, te))
				rot += deg_to_rad(float(h.get("amp", 25.0))) * sin(TAU / maxf(float(h.get("period", 1.0)), 0.01) * te
						+ float(h.get("phase", 0.0))) * on
			"orbit":
				var c: Array = h["center"] if h.get("center") is Array else [0.0, 0.0]
				var rad: Array = h["radius"] if h.get("radius") is Array else [0.5, 0.5]
				var a := float(h.get("phase", 0.0)) + TAU * maxf(te - float(h.get("t0", 0.0)), 0.0) / maxf(float(h.get("period", 10.0)), 0.01)
				pos = Vector2(float(c[0]) + float(rad[0]) * cos(a), float(c[1]) + float(rad[1]) * sin(a))
				if bool(h.get("face", false)):
					rot = entry["rot"] + atan2(float(rad[1]) * cos(a), -float(rad[0]) * sin(a))
			"glow":
				var g := _keys(h.get("keys"), te, 1)
				if not g.is_empty():
					glow = g[0]
	var visible_now := shown > HIDDEN_SCALE
	node.visible = visible_now
	var k := maxf(shown, HIDDEN_SCALE)
	node.transform = Transform3D(Basis(Vector3.BACK, rot) * Basis.from_scale(Vector3(sc.x * k, sc.y * k, 1.0)),
			Vector3(pos.x, pos.y, float(entry["z"])))
	if node is MeshInstance3D:
		(node as MeshInstance3D).set_instance_shader_parameter(&"emission", glow)


## Anahtarlar arasında yumuşak (smoothstep) ara değer: keys [[t, v1, v2...]]; dims değer sayısı. Anahtar yoksa boş.
static func _keys(raw: Variant, t: float, dims: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if not raw is Array or (raw as Array).is_empty():
		return out
	var keys: Array = raw
	var first: Array = keys[0]
	var last: Array = keys[keys.size() - 1]
	var a: Array = first
	var b: Array = first
	var u := 0.0
	if t <= float(first[0]):
		a = first
		b = first
	elif t >= float(last[0]):
		a = last
		b = last
	else:
		for i in range(1, keys.size()):
			var k: Array = keys[i]
			if t <= float(k[0]):
				a = keys[i - 1]
				b = k
				var span := float(b[0]) - float(a[0])
				u = _ease((t - float(a[0])) / span) if span > 0.0 else 1.0
				break
	for d in dims:
		out.append(lerpf(float(a[d + 1]), float(b[d + 1]), u))
	return out


static func _smooth(a: float, b: float, x: float) -> float:
	if b <= a:
		return 1.0 if x >= a else 0.0
	return _ease(clampf((x - a) / (b - a), 0.0, 1.0))


static func _ease(u: float) -> float:
	var x := clampf(u, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _color(value: Variant, fallback: Color) -> Color:
	if value is String and not (value as String).is_empty():
		return Color.html(value)
	if value is Array and (value as Array).size() >= 3:
		var a: Array = value
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	return fallback
