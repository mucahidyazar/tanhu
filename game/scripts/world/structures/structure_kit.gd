class_name StructureKit
extends RefCounted
## Yapı kayıtlarından dünya (godot.md §4.2 «yapı kayıtları»; K51 şeması {kind, id, at, rot, size, style, layout}; act1.md §4 «Kışlak
## yerleşimi»): MapWorld her kaydı build'e verir, düğümü «Places» altına koyar. Kayıt önce normalize edilir: rot yoksa pusula facing'i
## (yaw = π − facing), o da yoksa kapı ocağa (center; Kışlak'ta Ulu Ocak (0, 0)): rot = atan2(−x, −z); boy, millet, düzen ve hazır
## ayar türden ve dünyanın varsayılanından (Kışlak: yuezhi, Hane; açık yurtlar great_tent, hostage_yurt, new_yurt, en çok 3; gerisi
## closed, iç yok). Eski design alanı layout okunur (K51).
##
## Türler:
##   yurt gövdeli (yurt, yurt_small, otag, beg_otag, store_yurt, envoy_yurt, healer_yurt, cmd_yurt, armoury, fletchery, supply_depot) ve
##   hearth (adsız ocak: kapısı ocağa bakan kapalı Hane yurdu) → StagedYurt; dünyada bir StructureSet varsa YurtSlot (yakında tam yurt,
##   40–220 m YurtField'in kapalı örneği, ötesi uzak kubbe; godot.md §4.6)
##   StructureCatalog'un türleri (stable, tower, kantu_shed, felt_yard, tent_qiang, great_hearth, count_stone, work_board, kitchen,
##   woodpile, latrine, watch_fire, yurt_pad, hollow_gate, offering_pen) → StagedStructure (+ ateş, örnekli çit, kara bez)
##   «Kışlak yerleşimi»nin işaretleri (lookout_bluff, bluff_ramp, way_camp, goat_foot, goat_gate, scree) yapı değildir: build null döner.
## Sınırlar (structures.md §3.6, §13.6): zonda ≤160 kayıt (RECORDS_MAX), aynı anda ≤48 canlı yapı (LIVE_MAX; StructureSet sayar).
## İz (footprint): navmesh ve otun engeli (MapBaker okur), dünya koordinatında daireler ve kutular; düğüm kurmadan kayıttan.
##   var node := StructureKit.build(rec, {"ground": map.ground, "snow": 0.8, "set": structure_set})
##   StructureKit.footprint(rec)        # {circles: [Vector3(x, z, r)], boxes: [[Vector2 merkez, Vector2 yarı, açı]]}

const RECORDS_MAX := 160
const LIVE_MAX := 48
const OPEN_MAX := 3
## Kışlak'ın açık yurtları (içine girilir; act1.md §9.3 «Açık yurt ≤3»): Amaga'nın Yurdu (Hüküm), Rehine Yurdu (Mete'nin hücresi), Yeni Yurt.
const KISLAK_OPEN: Array[String] = ["great_tent", "hostage_yurt", "new_yurt"]
## Yurt gövdeli türler ve varsayılan düzenleri (structures.md §3.5 «Yerleşim yurtları»).
const YURT_LAYOUT := {
	"yurt": "ev", "yurt_small": "ev", "otag": "otag", "beg_otag": "otag", "store_yurt": "ambar", "envoy_yurt": "konuk",
	"healer_yurt": "otaci", "cmd_yurt": "silah", "armoury": "silah", "fletchery": "silah", "supply_depot": "ambar", "hearth": "ev",
}
const YURT_SIZE := {"yurt_small": "s", "otag": "l", "beg_otag": "l"}
## Yapı olmayan işaretler (act1.md tablosunun yer adları; Menzil E'nindir): build null döner, MapWorld kaydı veri sayar.
const MARKERS: Array[String] = ["lookout", "ramp", "waystation", "path_mark", "scree", "marker"]
## Bu kitin kurmadığı türler: nöbet ateşi (MapWorld'ün WatchFires'ı), yurt içi ocak (veridir; açık havadaki ocağı MapWorld kurar).
const FOREIGN: Array[String] = ["watch_fire", "hearth", "campfire", "prop", "horse", "banner", "rock", "tree"]
## Simgelerden (kind landmark, type) kurulanlar: tip → katalog türü (Esir Çukuru'nun kapısı ve çiti, kara bez, Adak Ağılı ve Mene'nin
## ağılı, Yukarı Ağıllar'ın sundurmaları, tahıl ambarı, Çiang çadırı, Kemik Boğazı'nın kuleleri, Gözcü Platformu).
const LANDMARK_KINDS := {"pen": "offering_pen", "banner": "black_cloth", "shed": "kantu_shed", "granary": "kantu_shed",
	"tent_qiang": "tent_qiang", "tower": "tower", "platform": "tower", "gate": "gate"}
## Kar payı türüne göre (ocak ve kazanın çevresi erir).
const SNOW_BY_KIND := {"great_hearth": 0.0, "kitchen": 0.0, "watch_fire": 0.0, "count_stone": 0.6}
## Kayıt adları → katalog türü (act1.md'nin adları ve kısaltmalar).
const ALIASES := {"shed": "kantu_shed", "hollow": "hollow_gate", "pen": "offering_pen", "pad": "yurt_pad", "watchfire": "watch_fire"}


## Tür yurt gövdeli mi (boy, millet, düzen taşır)?
static func is_yurt(kind: String) -> bool:
	return YURT_LAYOUT.has(kind)


## Kayıt bu kitin mi (MapWorld'ün eski türleri yurt (radius/facing), campfire, prop, horse, banner, rock, tree onundur)? K51 kaydı (rot,
## size, style, layout, preset, open ya da katalog türü) bizimdir; eski Meshy yurdu (radius alanlı, K51 alansız) MapWorld'ündür.
static func handles(rec: Dictionary) -> bool:
	var kind := StructureKit.kind_of(rec)
	if kind.is_empty() or FOREIGN.has(kind) or MARKERS.has(kind):
		return false
	if StructureCatalog.has(kind):
		return true
	if StructureKit.is_yurt(kind):
		for key in ["rot", "size", "style", "layout", "design", "preset", "open", "stage"]:
			if rec.has(key):
				return true
		return kind != "yurt" or not rec.has("radius")
	return false


## Kaydın kit türü: takma adlar ve simgenin tipi (landmark → LANDMARK_KINDS; Esir Çukuru'nun kapısı hollow_gate, ağılın kapısı ağılındır).
## Bu kitin kurmadığı simge "" döner.
static func kind_of(rec: Dictionary) -> String:
	var kind := str(rec.get("kind", ""))
	if kind == "landmark":
		var typ := str(rec.get("type", ""))
		var id := str(rec.get("id", ""))
		if typ == "gate":
			if id == "hollow_gate" or id.begins_with("hollow"):
				return "hollow_gate"
			if id.ends_with("pen_gate"):
				return ""
		return str(LANDMARK_KINDS.get(typ, ""))
	return str(ALIASES.get(kind, kind))


## Dünyanın bağlamı (MapWorld): StructureSet (MapWorld'ün çocuğu «Structures»; Places'in sayımına girmez), zemin, kar, millet ve ocak
## (data/structures/yurt_styles.json «zones», harita kimliğiyle).
static func world_ctx(world: Node3D) -> Dictionary:
	var spec: MapSpec = world.get(&"spec") as MapSpec
	var zone_id := spec.id if spec else ""
	var zones: Dictionary = YurtStyle.data().get("zones", {})
	var zone: Dictionary = zones.get(zone_id, {})
	var set_node := world.get_node_or_null(^"Structures") as StructureSet
	var ground: Object = world.get(&"ground")
	if set_node == null:
		set_node = StructureSet.new()
		set_node.ground = ground
		set_node.snow = float(zone.get("snow", 0.0))
		world.add_child(set_node)
	return {"ground": ground, "snow": float(zone.get("snow", 0.0)), "set": set_node, "style": str(zone.get("style", "hun")),
		"center": zone.get("center", [0.0, 0.0]), "painted": bool(zone.get("painted", false)), "spec": spec}


## Haritanın bağlamı düğüm kurmadan (saf; pişirme aracı, MapBaker): zonun milleti ve ocağı (data/structures/yurt_styles.json «zones»).
static func zone_ctx(spec: MapSpec) -> Dictionary:
	var zones: Dictionary = YurtStyle.data().get("zones", {})
	var zone: Dictionary = zones.get(spec.id if spec else "", {})
	return {"style": str(zone.get("style", "hun")), "center": zone.get("center", [0.0, 0.0]), "snow": float(zone.get("snow", 0.0)),
		"painted": bool(zone.get("painted", false))}


## Çatılı ya da dolu tabanlı yapıların yarı ölçüsü (yerel x, z; m): ot tabanın tamamında çıkmaz (izin kutuları yalnız duvardır).
const GRASS_BASE := {
	"stable": Vector2(6.9, 3.7), "kantu_shed": Vector2(3.3, 2.3), "shed": Vector2(3.3, 2.3), "tent_qiang": Vector2(3.4, 2.6),
	"felt_yard": Vector2(7.0, 5.0), "tower": Vector2(1.6, 1.6), "woodpile": Vector2(1.9, 0.9), "latrine": Vector2(1.2, 0.9),
	"kitchen": Vector2(1.8, 1.8), "work_board": Vector2(1.0, 0.4), "count_stone": Vector2(0.8, 0.8),
}


## Kaydın otu kesen daireleri (dünya; saf; MapBaker.grass_blockers): yurdun duvarı (+0,4), çatılı yapının bütün tabanı (GRASS_BASE'i kaplayan
## daireler), izin daireleri (+0,25). Çitin kesimleri ot kesmez (çitin dibinde kuru tutam doğaldır), kapının direkleri keser.
static func grass_blockers(rec: Dictionary, ctx: Dictionary = {}) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var r := StructureKit.normalize(rec, ctx)
	var kind := str(r["kind"])
	var fp := StructureKit.footprint(rec, ctx)
	if StructureKit.is_yurt(kind):
		for c: Variant in fp.get("circles", []):
			var v: Vector3 = c
			out.append(Vector3(v.x, v.y, v.z + 0.4))
		return out
	for c: Variant in fp.get("circles", []):
		var v: Vector3 = c
		out.append(Vector3(v.x, v.y, v.z + 0.25))
	if GRASS_BASE.has(kind):
		var half: Vector2 = GRASS_BASE[kind]
		var at: Vector2 = r["at"]
		var rot := float(r["rot"])
		var long_x := half.x >= half.y
		var n := maxi(ceili((half.x if long_x else half.y) / maxf(half.y if long_x else half.x, 0.1)), 1)
		var seg := (half.x if long_x else half.y) / float(n)
		var radius := Vector2(seg, half.y if long_x else half.x).length()
		var basis := Basis(Vector3.UP, rot)
		for k in n:
			var t := -((half.x if long_x else half.y)) + seg * (2.0 * float(k) + 1.0)
			var p := basis * (Vector3(t, 0.0, 0.0) if long_x else Vector3(0.0, 0.0, t))
			out.append(Vector3(at.x + p.x, at.y + p.z, radius))
	return out


## İzin kutusunun dünya köşeleri (saf; navmesh'in çokgen engeli): [merkez, yarı, açı] → dört köşe (açı Basis(UP, açı)'dır: yerel z
## (sin, cos) yönünde yarı.y).
static func box_outline(box: Array) -> PackedVector2Array:
	var c: Vector2 = box[0]
	var half: Vector2 = box[1]
	var ang := float(box[2]) if box.size() > 2 else 0.0
	var ax := Vector2(cos(ang), -sin(ang)) * half.x
	var az := Vector2(sin(ang), cos(ang)) * half.y
	return PackedVector2Array([c - ax - az, c + ax - az, c + ax + az, c - ax + az])


## Kaydı düzleştirir: kind (takma adlar), id, at (Vector2), rot (radyan), y (taban payı) ve yurtta size, style, layout, preset, open.
## ctx: style (dünyanın milleti), open_ids, center (adsız yurdun kapısının baktığı ocak).
static func normalize(rec: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var out := rec.duplicate(true)
	var raw_kind := str(rec.get("kind", ""))
	var kind := StructureKit.kind_of(rec)
	var id := str(rec.get("id", raw_kind))
	out["kind"] = kind
	out["id"] = id
	var at := MapSpec.vec2(rec.get("at", [0.0, 0.0]))
	out["at"] = at
	var center := MapSpec.vec2(ctx.get("center", [0.0, 0.0]))
	var rot := 0.0
	if rec.has("rot") and (rec["rot"] is float or rec["rot"] is int):
		rot = float(rec["rot"])
	elif rec.has("facing") and float(rec.get("facing", 0.0)) != 0.0:
		rot = PI - deg_to_rad(float(rec["facing"]))
	elif kind == "hearth" or bool(rec.get("unnamed", false)) or bool(rec.get("face_center", false)):
		# Kapısı ocağa bakar (act1.md: rot = atan2(−x, −z)).
		rot = atan2(center.x - at.x, center.y - at.y)
	out["rot"] = rot
	if StructureKit.is_yurt(kind):
		var layout := str(rec.get("layout", rec.get("design", YURT_LAYOUT.get(kind, "ev"))))
		out["layout"] = YurtLayouts.resolve(layout) if not layout.is_empty() else "ev"
		out["size"] = str(rec.get("size", YURT_SIZE.get(kind, "m")))
		out["style"] = str(rec.get("style", ctx.get("style", "hun")))
		var open_ids: Array = ctx.get("open_ids", [])
		var is_open := bool(rec.get("open", open_ids.has(id)))
		out["open"] = is_open
		out["preset"] = str(rec.get("preset", YurtGeometry.WINTER if is_open else YurtGeometry.CLOSED))
		if bool(ctx.get("painted", false)) and not rec.has("pad"):
			out["pad"] = false
		if kind == "hearth":
			out["unnamed"] = true
		if kind == "store_yurt" or kind == "armoury" or kind == "fletchery" or kind == "supply_depot":
			out["hearth"] = false
	return out


## Kaydın izi (dünya; saf): navmesh ve otun engeli. Yurtta duvarın dairesi (yarıçap + 0,25); katalogda türün daireleri ve kutuları.
static func footprint(rec: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var r := StructureKit.normalize(rec, ctx)
	var kind := str(r["kind"])
	var at: Vector2 = r["at"]
	var rot := float(r["rot"])
	var out := {"circles": [], "boxes": []}
	if MARKERS.has(kind):
		return out
	if StructureKit.is_yurt(kind):
		var d := YurtGeometry.dims(YurtStyle.find(str(r["style"])), str(r["size"]))
		out["circles"].append(Vector3(at.x, at.y, float(d["foot"])))
		return out
	var fp := StructureCatalog.footprint(kind)
	var basis := Basis(Vector3.UP, rot)
	# Ağılın kapısı (iki direk) kapının yerindedir (kit oraya kayar), kaydın ortasında değil.
	var posts_at := at
	if kind == "offering_pen":
		posts_at = Vector2(StructureKit.pen_area(r)["gate"])
	for c: Variant in fp.get("circles", []):
		var v: Vector3 = c
		var p := basis * Vector3(v.x, 0.0, v.y)
		out["circles"].append(Vector3(posts_at.x + p.x, posts_at.y + p.z, v.z))
	for b: Variant in fp.get("boxes", []):
		var row: Array = b
		var c2: Vector2 = row[0]
		var p := basis * Vector3(c2.x, 0.0, c2.y)
		out["boxes"].append([Vector2(at.x + p.x, at.y + p.z), row[1], rot + float(row[2])])
	if kind == "offering_pen" or kind == "hollow_gate":
		for seg: Array in StructureKit.fence_segments(r):
			out["boxes"].append(seg)
	return out


## Ahırın bölmeleri (dünya; E'nin atları için): [{at: Vector2, facing: pusula derecesi}] (atın önü kapıya, yerel +Z).
static func stable_stalls(rec: Dictionary) -> Array:
	var r := StructureKit.normalize(rec)
	var at: Vector2 = r["at"]
	var rot := float(r["rot"])
	var basis := Basis(Vector3.UP, rot)
	var out: Array = []
	for p: Vector2 in StructureCatalog.stable_stalls():
		var w := basis * Vector3(p.x, 0.0, p.y)
		var fwd := basis * Vector3(0.0, 0.0, 1.0)
		out.append({"at": Vector2(at.x + w.x, at.y + w.z), "facing": fposmod(rad_to_deg(atan2(fwd.x, -fwd.z)), 360.0)})
	return out


## Kapının dünya noktası (zeminde değil; düzlemde): yurtta kapının önü (yarıçap + pay), öteki türde kaydın yeri.
static func door_point(rec: Dictionary, ctx: Dictionary = {}, pad_out: float = 0.8) -> Vector2:
	var r := StructureKit.normalize(rec, ctx)
	var at: Vector2 = r["at"]
	if not StructureKit.is_yurt(str(r["kind"])):
		return at
	var d := YurtGeometry.dims(YurtStyle.find(str(r["style"])), str(r["size"]))
	var rot := float(r["rot"])
	return at + Vector2(sin(rot), cos(rot)) * (float(d["radius"]) + pad_out)


# --- Kurulum ----------------------------------------------------------------------------------------------------

## Kayıttan düğüm (yerinde, zeminde, dönmüş). ctx: ground (height_at), snow (0..1), set (StructureSet), style, open_ids, center.
## Yapı olmayan işaret null döner.
static func build(rec: Dictionary, ctx: Dictionary = {}) -> Node3D:
	var r := StructureKit.normalize(rec, ctx)
	var kind := str(r["kind"])
	if MARKERS.has(kind):
		return null
	var at: Vector2 = r["at"]
	var ground: Object = ctx.get("ground")
	var y := float(r.get("y", 0.0))
	if ground and ground.has_method(&"height_at"):
		y += float(ground.call(&"height_at", at.x, at.y))
	var xf := Transform3D(Basis(Vector3.UP, float(r["rot"])), Vector3(at.x, y, at.y))
	var snow := float(ctx.get("snow", 0.0))
	var node: Node3D
	if StructureKit.is_yurt(kind):
		var set_node: Variant = ctx.get("set")
		if set_node is StructureSet:
			node = (set_node as StructureSet).yurt_slot(r, xf)
			(set_node as StructureSet).count_record()
		else:
			var yurt := StructureKit.make_yurt(r)
			yurt.ground = ground
			yurt.snow = snow
			yurt.transform = xf
			node = yurt
	else:
		node = StructureKit._build_catalog(r, xf, ctx)
		var set_any: Variant = ctx.get("set")
		if node and set_any is StructureSet:
			(set_any as StructureSet).count_record()
	if node:
		node.name = str(r["id"]).to_pascal_case() if not str(r["id"]).is_empty() else kind.to_pascal_case()
		node.set_meta(&"record", str(r["id"]))
		node.set_meta(&"kind", kind)
	return node


## Kayıttan yurt düğümü (kurulmamış; ağaca girince kurulur).
static func make_yurt(r: Dictionary) -> StagedYurt:
	var yurt := StagedYurt.new()
	yurt.configure(r)
	yurt.record_id = str(r.get("id", ""))
	var st := int(r.get("stage", 7))
	yurt.stage = st
	return yurt


static func _build_catalog(r: Dictionary, xf: Transform3D, ctx: Dictionary) -> Node3D:
	var kind := str(r["kind"])
	# Ağılın kapısı ayrı simgeyse (<kimlik>_gate) yeri ondan.
	if kind == "offering_pen" and not r.has("gate") and ctx.get("spec") is MapSpec:
		var gate_rec := (ctx["spec"] as MapSpec).structure(str(r.get("id", "")) + "_gate")
		if not gate_rec.is_empty():
			r["gate"] = gate_rec["at"]
	if not StructureCatalog.has(kind):
		push_warning("[structure_kit] bilinmeyen yapı türü: %s" % kind)
		return null
	var s := StagedStructure.new()
	s.kind = kind
	s.record_id = str(r.get("id", ""))
	s.transform = xf
	s.material_key = "catalog"
	s.mesh = StructureCatalog.mesh(kind, str(r.get("preset", "")))
	# Kar: ocak ve kazanın çevresinde erir (TerrainPaint'in erime yarıçapı), öteki yapılarda zonunki.
	s.snow = float(ctx.get("snow", 0.0)) * float(SNOW_BY_KIND.get(kind, 1.0))
	var fp := StructureCatalog.footprint(kind)
	s.footprint = {"circles": fp.get("circles", []), "boxes": fp.get("boxes", [])}
	s.footprint_min_stage = int(fp.get("min_stage", 1))
	s.stage = int(r.get("stage", StructureCatalog.stages_of(kind)))
	s.casts_shadow = kind != "watch_fire" and kind != "yurt_pad"
	match kind:
		"great_hearth":
			StructureKit._add_great_fire(s, r, ctx)
		"watch_fire":
			StructureKit._add_watch_fire(s)
		"kitchen":
			StructureKit._add_kitchen_fire(s)
		"offering_pen", "hollow_gate":
			StructureKit._add_fence(s, r, ctx)
			StructureKit._fence_footprint(s, r)
		"stable":
			StructureKit._add_stable_room(s)
	return s


## Ahırın odası (K98): içerideki oyuncu ve bölmelerdeki atlar için çatı kalkar, kameraya bakan yan alçalır (StructureRoom; yurdun kesiti).
## Kesitin ölçüleri ahırın malzemesindedir (ayrı anahtar): yarıçap yarı köşegenden ve saçaktan geniş, uzak yan saçağın altında (2,15 m),
## kameraya bakan yan 1 m'de, üstü mahyanın üstünde.
static func _add_stable_room(s: StagedStructure) -> void:
	var half := StructureCatalog.STABLE_HALF
	s.material_key = "catalog_stable"
	s.material_params = {"cut_radius": half.length() + 0.8, "cut_top": 2.15, "cut_low": 1.0, "cut_ceiling": 4.4}
	var room := StructureRoom.new()
	room.name = "Room"
	# Önü açıktır: atın başındaki oyuncu ve kapı ağzı odadadır.
	room.rect = Rect2(-half.x - 0.2, -half.y - 0.2, half.x * 2.0 + 0.4, half.y * 2.0 + 1.4)
	s.add_child(room)


## Çitin izi (yapının yerel düzleminde; oyuncu, sürü ve kişiler çitten geçmez): kesimler kutu, kapının iki direği kapının yerinde (ağılın
## kiti kapının yerine kaydırılır: kit_offset). Navmesh aynı izi kayıttan okur (footprint).
static func _fence_footprint(s: StagedStructure, r: Dictionary) -> void:
	var inv := s.transform.affine_inverse()
	var rot := float(r.get("rot", 0.0))
	var boxes: Array = []
	for seg: Array in StructureKit.fence_segments(r):
		var c: Vector2 = seg[0]
		var lc := inv * Vector3(c.x, s.transform.origin.y, c.y)
		boxes.append([Vector2(lc.x, lc.z), seg[1], float(seg[2]) - rot])
	var circles: Array = []
	var offset: Vector3 = s.get_meta(&"kit_offset", Vector3.ZERO)
	for c: Variant in s.footprint.get("circles", []):
		var v: Vector3 = c
		circles.append(Vector3(v.x + offset.x, v.y + offset.z, v.z))
	s.footprint = {"circles": circles, "boxes": boxes}


## Ulu Ocak: r 12 m meydan (ezik zemin; zemini izler) ve büyük ateş (Campfire: gölgesiz ışık).
static func _add_great_fire(s: StagedStructure, r: Dictionary, ctx: Dictionary) -> void:
	var fire := Campfire.new()
	fire.name = "Fire"
	fire.flame_scale = 1.5
	fire.light_energy = 2.4
	fire.light_range = 13.0
	s.add_child(fire)
	if bool(ctx.get("painted", false)):
		# Meydanın ezik karı ve erimesi zeminin boyasıdır (TerrainPaint).
		return
	var plaza := StructureKit.ground_disc(Vector2(r["at"]), float(r.get("plaza", 12.0)), ctx.get("ground"), s.transform.origin.y, Color("#8a7860") if float(ctx.get("snow", 0.0)) < 0.5 else Color("#b8b2a8"))
	plaza.name = "Plaza"
	s.add_child(plaza)
	s.add_part(plaza)


## Nöbet ateşi (act1.md: 16:30'da yanar, 07:40'ta söner; ışık sahtedir: kor parıltısı ve zemin lekesi, gerçek ışık yok).
static func _add_watch_fire(s: StagedStructure) -> void:
	for i in 2:
		var size_v := Vector2(0.55, 0.7) * (1.0 - 0.28 * float(i))
		var quad := QuadMesh.new()
		quad.size = size_v
		quad.center_offset = Vector3(0.0, size_v.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = StagedYurt.FLAME_SHADER
		mat.set_shader_parameter("energy", 1.2 - 0.2 * float(i))
		mat.set_shader_parameter("speed", 1.7 + 0.4 * float(i))
		mat.set_shader_parameter("seed", 0.2 + 0.37 * float(i))
		var mi := MeshInstance3D.new()
		mi.name = "Flame%d" % i
		mi.mesh = quad
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0.04 * float(i), 0.05, 0.0)
		mi.set_meta(&"fire", true)
		s.add_child(mi)
	var glow := MeshInstance3D.new()
	glow.name = "GroundGlow"
	var q := QuadMesh.new()
	q.size = Vector2(5.0, 5.0)
	q.orientation = PlaneMesh.FACE_Y
	glow.mesh = q
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.albedo_texture = Fx.soft_dot_texture()
	gm.albedo_color = Color(1.0, 0.5, 0.2, 0.55)
	glow.material_override = gm
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.position = Vector3(0.0, 0.06, 0.0)
	glow.set_meta(&"fire", true)
	s.add_child(glow)
	s.glow = 1.0


## Mutfak Kazanı'nın altındaki kor (alev yok: kazan kaynıyor).
static func _add_kitchen_fire(s: StagedStructure) -> void:
	var embers := MeshInstance3D.new()
	embers.name = "Embers"
	embers.mesh = MeshKit.disc(0.5, 0.05, 12)
	embers.material_override = Style.glow(Color(1.0, 0.38, 0.1), 1.8)
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.add_child(embers)
	var smoke := Fx.smoke(Vector2(1.2, 2.2), Vector2(-0.4, -0.1))
	smoke.name = "Steam"
	smoke.position = Vector3(0.0, 1.0, 0.0)
	s.add_child(smoke)


## Zemini izleyen disk (meydan, ezik toprak ya da kar): yerel uzayda (düğümün altında), merkez at, yarıçap r.
static func ground_disc(at: Vector2, radius: float, ground: Object, base_y: float, col: Color) -> MeshInstance3D:
	var sm := StagedMesh.new()
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
	var rings := 6
	var segs := 36
	var center := sm.vertex(StagedMesh.SOLID, Vector3(0, 0.03, 0), Vector3.UP, col)
	var prev := PackedInt32Array()
	for ring in rings:
		var rr := radius * float(ring + 1) / float(rings)
		var ids := PackedInt32Array()
		for k in segs:
			var a := TAU * float(k) / float(segs)
			var lx := sin(a) * rr
			var lz := cos(a) * rr
			var gy := base_y
			if ground and ground.has_method(&"height_at"):
				gy = float(ground.call(&"height_at", at.x + lx, at.y + lz))
			var t := float(ring + 1) / float(rings)
			var shade := lerpf(1.0, 0.9, t)
			ids.append(sm.vertex(StagedMesh.SOLID, Vector3(lx, gy - base_y + 0.03, lz), Vector3.UP, Color(col.r * shade, col.g * shade, col.b * shade)))
		if ring == 0:
			for k in segs:
				sm.tri(StagedMesh.SOLID, center, ids[(k + 1) % segs], ids[k])
		else:
			for k in segs:
				sm.quad(StagedMesh.SOLID, prev[k], prev[(k + 1) % segs], ids[(k + 1) % segs], ids[k])
		prev = ids
	var mi := MeshInstance3D.new()
	StagedStructure.dress(mi, sm.commit(), "pad", {"brush_strength": 0.2})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- Çit (ağıl, Esir Çukuru) -----------------------------------------------------------------------------------

## Çitin kesimleri (dünya kutuları; footprint ve pano yerleşimi): Adak Ağılı 44 × 30 m dikdörtgen (kapı kuzey kenarda, gate'in x'inde);
## Esir Çukuru kuzey çiti (kapı kaydın yerinde; batıya 28, doğuya 92 m; uçlarda 10 m güneye dönüş). Kapının aralığı (3,2 m) boş.
static func fence_segments(r: Dictionary) -> Array:
	var out: Array = []
	for seg: Array in StructureKit.fence_lines(r):
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var d := b - a
		out.append([(a + b) * 0.5, Vector2(0.12, d.length() * 0.5), atan2(d.x, d.y)])
	return out


## Çitin çizgileri (dünya): [[a, b], ...]; kapı aralığı çizgilerin arasındadır.
static func fence_lines(r: Dictionary) -> Array:
	var at: Vector2 = MapSpec.vec2(r.get("at", [0.0, 0.0]))
	var gap := 3.2
	var lines: Array = []
	if str(r.get("kind", "")) == "offering_pen":
		var size := StructureKit.pen_size(r)
		var hx := size.x * 0.5
		var hz := size.y * 0.5
		var gate := MapSpec.vec2(r.get("gate", [at.x, at.y - hz]))
		var gx := clampf(gate.x, at.x - hx + gap, at.x + hx - gap)
		var nw := Vector2(at.x - hx, at.y - hz)
		var ne := Vector2(at.x + hx, at.y - hz)
		var se := Vector2(at.x + hx, at.y + hz)
		var sw := Vector2(at.x - hx, at.y + hz)
		lines.append([nw, Vector2(gx - gap * 0.5, nw.y)])
		lines.append([Vector2(gx + gap * 0.5, ne.y), ne])
		lines.append([ne, se])
		lines.append([se, sw])
		lines.append([sw, nw])
		return lines
	# Esir Çukuru: kuzey çiti, kapı kaydın yerinde.
	var west := float(r.get("west", 28.0))
	var east := float(r.get("east", 92.0))
	var south := float(r.get("returns", 10.0))
	var w := Vector2(at.x - west, at.y)
	var e := Vector2(at.x + east, at.y)
	lines.append([w, Vector2(at.x - gap * 0.5, at.y)])
	lines.append([Vector2(at.x + gap * 0.5, at.y), e])
	lines.append([w, w + Vector2(0, south)])
	lines.append([e, e + Vector2(0, south)])
	return lines


## Örgü panolar (MultiMesh; sağlam ve kırık iki çizim): çizgiler boyunca 2,2 m'lik panolar; kırık panolar holes'tan (dünya noktaları).
## Esir Çukuru'nun kuzey çitinde dokuz şeritli kara bez (Hunların Kara Nama'sı; story.md §9).
static func _add_fence(s: StagedStructure, r: Dictionary, ctx: Dictionary) -> void:
	var ground: Object = ctx.get("ground")
	var inv := s.transform.affine_inverse()
	var holes: Array = []
	for h: Variant in r.get("holes", [[110.0, 124.0], [-60.0, 175.0]]):
		holes.append(MapSpec.vec2(h))
	var whole: Array[Transform3D] = []
	var broken: Array[Transform3D] = []
	for seg: Array in StructureKit.fence_lines(r):
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var length := a.distance_to(b)
		var n := maxi(int(roundf(length / 2.2)), 1)
		var dir := (b - a) / length
		for k in n:
			var p := a + dir * (float(k) + 0.5) * length / float(n)
			var gy := s.transform.origin.y
			if ground and ground.has_method(&"height_at"):
				gy = float(ground.call(&"height_at", p.x, p.y))
			var world := Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y) - PI * 0.5) * Basis.from_scale(Vector3(length / float(n) / 2.2, 1.0, 1.0)), Vector3(p.x, gy, p.y))
			var is_hole := false
			for h: Vector2 in holes:
				if h.distance_to(p) < 1.3:
					is_hole = true
			if is_hole:
				broken.append(inv * world)
			else:
				whole.append(inv * world)
	for pair: Array in [[whole, false, "Wattle"], [broken, true, "WattleBroken"]]:
		var list: Array[Transform3D] = pair[0]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = StructureCatalog.wattle_panel(bool(pair[1]))
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = str(pair[2])
		mmi.multimesh = mm
		var mats := StagedStructure.materials("catalog", {})
		mmi.material_override = mats[StagedMesh.THIN]
		s.add_child(mmi)
		s.add_part(mmi)
	# Ağılın kapısı kuzey kenardadır (kit kaydın yerinde kurulur, kapının yerine kaydırılır).
	if str(r.get("kind", "")) == "offering_pen":
		var size := StructureKit.pen_size(r)
		var at: Vector2 = MapSpec.vec2(r.get("at", [0.0, 0.0]))
		var gate := MapSpec.vec2(r.get("gate", [at.x, at.y - size.y * 0.5]))
		var gx := clampf(gate.x, at.x - size.x * 0.5 + 3.2, at.x + size.x * 0.5 - 3.2)
		var gy := s.transform.origin.y
		if ground and ground.has_method(&"height_at"):
			gy = float(ground.call(&"height_at", gx, at.y - size.y * 0.5))
		s.set_meta(&"kit_offset", inv * Vector3(gx, gy, at.y - size.y * 0.5))


## Ağılın alanı (dünya; saf; sürünün gecesi ve kapıdan geçişi, PastureFlock.set_pen): {center, half (yarı boy), gate (kapının ortası, kuzey
## kenarda), gap (kapının aralığı)}. Çit eksenlere hizalıdır (fence_lines).
static func pen_area(rec: Dictionary) -> Dictionary:
	var r := StructureKit.normalize(rec)
	var at: Vector2 = MapSpec.vec2(r.get("at", [0.0, 0.0]))
	var size := StructureKit.pen_size(r)
	var gap := 3.2
	var gate := MapSpec.vec2(r.get("gate", [at.x, at.y - size.y * 0.5]))
	var gx := clampf(gate.x, at.x - size.x * 0.5 + gap, at.x + size.x * 0.5 - gap)
	return {"center": at, "half": size * 0.5, "gate": Vector2(gx, at.y - size.y * 0.5), "gap": gap}


## Ağılın boyu (m): kayıtta size; yoksa Adak Ağılı 44 × 30 (act1.md §4), öteki ağıllar 12 × 8 (settlement.md §7.3: 40 m çizgi).
static func pen_size(r: Dictionary) -> Vector2:
	if r.has("size") and not (r["size"] is String):
		return MapSpec.vec2(r["size"])
	return Vector2(44.0, 30.0) if str(r.get("id", "")) == "offering_pen" else Vector2(12.0, 8.0)


## Dokuz şeritli kara bez (eski yardımcı; katalogdaki black_cloth türü kullanılır).
static func _black_cloth() -> MeshInstance3D:
	var sm := StagedMesh.new()
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_FELT)
	for k in 9:
		var x := (float(k) - 4.0) * 0.22
		var c := Color("#1e1a18") if k % 2 == 0 else Color("#3a3230")
		sm.box(Transform3D(Basis.IDENTITY, Vector3(x, 1.25, 0.08)), Vector3(0.2, 1.1 - 0.06 * float(k % 3), 0.02), c)
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-1.1, 1.85, 0.08), Vector3(1.1, 1.85, 0.08), 0.05, 0.05, StructureCatalog.WOOD_DARK)
	var mi := MeshInstance3D.new()
	mi.name = "KaraNama"
	StagedStructure.dress(mi, sm.commit(), "catalog", {})
	return mi
