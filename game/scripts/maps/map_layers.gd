class_name MapLayers
extends RefCounted
## İç haritanın veri katmanları (map.json «layers»: {kimlik: res://…json}): her katman kendi dosyasıdır ve kendi düğümünü kurar; ortak
## map.json'a yalnız bir satır girer, haritanın pişmiş parçaları (MapBaker.signature) katmandan etkilenmez. Katmanın dosyası «script»
## (Node betiği) taşır; MapWorld kurulumun son adımında MapLayers.build ile düğümü «Layers/<Kimlik>» altına ekler. Düğüm setup(world, def)
## taşıyorsa ağaca eklenmeden önce çağrılır. Bozuk ya da betiksiz katman bir uyarıyla atlanır: dünya yine kurulur.
##   MapLayers.build(map_world, spec.layers)     # [düğüm, ...]
##   MapLayers.read("res://data/maps/testmap/survival.json")   # katmanın sözlüğü (yoksa boş)

const GROUP_NAME := "Layers"


## Katmanın dosyası (saf okuma; yoksa ya da bozuksa boş).
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Katmanları kurar: world'ün «Layers» düğümünün altına, sözlüğün sırasıyla. Döner: kurulan düğümler.
static func build(world: Node3D, layers: Dictionary) -> Array[Node]:
	var out: Array[Node] = []
	if world == null or layers.is_empty():
		return out
	var holder := world.get_node_or_null(NodePath(GROUP_NAME)) as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = GROUP_NAME
		world.add_child(holder)
	for id: Variant in layers:
		var path := str(layers[id])
		var def := MapLayers.read(path)
		var script_path := str(def.get("script", ""))
		if def.is_empty() or script_path.is_empty() or not ResourceLoader.exists(script_path):
			push_warning("[map_layers] %s katmanı okunamadı ya da betiği yok: %s" % [id, path])
			continue
		var script := load(script_path) as Script
		if script == null or not script.can_instantiate():
			push_warning("[map_layers] %s katmanının betiği kurulamıyor (derleme hatası?): %s" % [id, script_path])
			continue
		var node: Variant = script.new()
		if not node is Node:
			push_warning("[map_layers] %s katmanının betiği düğüm değil: %s" % [id, script_path])
			continue
		(node as Node).name = str(id).to_pascal_case()
		if (node as Node).has_method(&"setup"):
			(node as Node).call(&"setup", world, def)
		holder.add_child(node)
		out.append(node)
	return out
