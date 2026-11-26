class_name WorldSpots
extends RefCounted
## Bir dünyanın bekleme ve etkileşim yerleri (data/world/spots.json; time.md §7.1, survival.md §2.7, economy.md §4.6): döşek (Uyu), ateş
## başı (Dinlen), şantiye (Çalış) ve E ile açılan kap. Yerler dünyanın sahnesinden (kampın düğümleri: yurdun kapısı düğümün +Z yönünde)
## ya da tarifin yapı kayıtlarından (MapSpec.structures: at, facing, radius) kurulur; yalnız yatay düzlemde (x, z) sınanır. Dünya başına
## bir kez kurulur (önbellek: dünyanın kimliği ve düğümü).
##   var spots := WorldSpots.of(world_host.spec, world_host.current_world())
##   spots.nearest("beds", Vector2(p.x, p.z))     # {id, at: Vector2, radius, name, ...} ya da boş

const PATH := "res://data/world/spots.json"
const KINDS: Array[String] = ["beds", "fires", "sites", "containers"]

static var _data: Dictionary = {}
static var _cache: Dictionary = {}

## Tür → [{id, at: Vector2, radius, ...satırın öteki alanları}].
var spots: Dictionary = {}
## Dünyanın kimliği.
var map_id := ""


## Dünyanın yerleri (önbellekli). spec yoksa ya da dünya bilinmiyorsa boş.
static func of(spec: MapSpec, world: Node) -> WorldSpots:
	var id := spec.id if spec else ""
	var key := "%s:%d" % [id, world.get_instance_id() if is_instance_valid(world) else 0]
	if _cache.has(key):
		return _cache[key]
	var out := build(id, spec, world)
	# Bırakılan dünyaların kayıtları birikmesin: önbellek yalnız son dünyalarındır.
	if _cache.size() > 8:
		_cache.clear()
	_cache[key] = out
	return out


## Yerleri kurar (saf değil: kampın düğümlerini okur).
static func build(id: String, spec: MapSpec, world: Node) -> WorldSpots:
	var out := WorldSpots.new()
	out.map_id = id
	var def: Dictionary = (data().get("maps", {}) as Dictionary).get(id, {})
	for kind in KINDS:
		var list: Array = []
		for row: Variant in def.get(kind, []):
			if not row is Dictionary:
				continue
			var at := _locate(row, spec, world)
			if at == Vector2.INF:
				continue
			var spot := (row as Dictionary).duplicate(true)
			spot["at"] = at
			spot["radius"] = float((row as Dictionary).get("radius", 1.5))
			spot["kind"] = kind
			list.append(spot)
		out.spots[kind] = list
	return out


## data/world/spots.json (bir kez okunur).
static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data


static func forget() -> void:
	_cache.clear()


## Türün yerleri.
func list(kind: String) -> Array:
	return spots.get(kind, [])


## Erimdeki en yakın yer (yoksa boş).
func nearest(kind: String, xz: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for s: Dictionary in spots.get(kind, []):
		var d := xz.distance_to(s["at"])
		if d <= float(s["radius"]) and d < best_d:
			best = s
			best_d = d
	return best


## Satırın yeri: düğümün (kamp) ya da yapı kaydının (iç harita) yeri; yurtta kapının önü. Bulunamazsa Vector2.INF.
static func _locate(row: Dictionary, spec: MapSpec, world: Node) -> Vector2:
	var door := float(row.get("door", -1.0))
	if row.has("node"):
		var node := world.get_node_or_null(NodePath(str(row["node"]))) as Node3D if is_instance_valid(world) else null
		if node == null or not node.is_inside_tree():
			return Vector2.INF
		var p := node.global_position
		if door < 0.0:
			return Vector2(p.x, p.z)
		var z := node.global_transform.basis.z
		var dir := Vector2(z.x, z.z).normalized()
		var radius: Variant = node.get(&"radius")
		return Vector2(p.x, p.z) + dir * (float(radius) if radius is float or radius is int else 3.0) + dir * door
	if row.has("structure") and spec:
		for rec: Dictionary in spec.structures:
			if str(rec.get("id", "")) != str(row["structure"]):
				continue
			var at: Vector2 = rec["at"]
			if door < 0.0:
				return at
			var az := deg_to_rad(float(rec.get("facing", 0.0)))
			var dir := Vector2(sin(az), -cos(az))
			return at + dir * (float(rec.get("radius", 3.2)) + door)
	return Vector2.INF
