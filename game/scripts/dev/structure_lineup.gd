extends Node3D
## Geliştirme aracı: yapı dizisi (yurt-variants, staged-building, building-catalog). Düz bir zeminde boyları, milletleri, aşamaları, iç
## düzenleri (oda kesiti açık), kapalı ve uzak yurdu, Kışlak'ın yapı kataloğunu oyun içi kadrajla (K98: eğim 38–50°, görüş 36°, 28–40 m)
## gösterir; her çekimi <--out>/<ad>.jpg yazar ve kapanır. Ana sahne kurulmaz. Pencere açar.
##   Godot --path . --resolution 1920x1080 res://scenes/dev/structure_lineup.tscn -- --out=$TMPDIR/dizin [--shots=sizes,stages] [--snow=0.7]
## Çekimler: sizes_hun, sizes_yuezhi, styles, stages, fall, layouts_a, layouts_b, closed, catalog_a, catalog_b, catalog_c, kislak_row.

const FOV := 36.0
const SETTLE := 10

var _camera: Camera3D
var _args := {}
var _snow := 0.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	var out := str(_args.get("out", OS.get_user_data_dir()))
	var wanted := str(_args.get("shots", ""))
	_snow = float(str(_args.get("snow", "0.0")))
	_setup_world()
	var shots := _shots()
	for id: String in shots:
		if not _wanted(wanted, id):
			continue
		var row: Array = shots[id]
		var holder := Node3D.new()
		holder.name = id.to_pascal_case()
		add_child(holder)
		(row[0] as Callable).call(holder)
		var focus: Vector3 = row[1]
		_camera.global_transform = FollowCamera.compute_transform(focus, deg_to_rad(float(row[2])), float(row[3]), float(row[4]))
		for i in SETTLE:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg(out.path_join(id + ".jpg"), 0.9)
		print("[structure_lineup] ", id)
		remove_child(holder)
		holder.queue_free()
		await get_tree().process_frame
	get_tree().quit()


## Çekim → [kurucu(holder), odak, yön°, eğim°, uzaklık m].
func _shots() -> Dictionary:
	return {
		"sizes_hun": [_row_sizes.bind("hun"), Vector3(0, 1.5, 0), 0.0, 38.0, 28.0],
		"sizes_yuezhi": [_row_sizes.bind("yuezhi"), Vector3(0, 1.5, 0), 0.0, 38.0, 28.0],
		"styles": [_row_styles, Vector3(0, 1.5, -2), 0.0, 42.0, 40.0],
		"stages": [_row_stages, Vector3(0, 1.2, 0), 0.0, 40.0, 40.0],
		"fall": [_row_fall, Vector3(0, 1.2, 0), 0.0, 40.0, 28.0],
		"layouts_a": [_row_layouts.bind(["ev", "otag", "otaci", "silah"]), Vector3(0, 0.5, 0), 0.0, 50.0, 30.0],
		"layouts_b": [_row_layouts.bind(["bolmeli", "konuk", "ambar", "han"]), Vector3(0, 0.5, 0), 0.0, 50.0, 30.0],
		"closed": [_row_closed, Vector3(0, 1.5, 0), 0.0, 38.0, 40.0],
		"catalog_a": [_row_catalog.bind(["great_hearth", "count_stone", "work_board", "kitchen", "woodpile"]), Vector3(0, 0.5, 0), 0.0, 45.0, 40.0],
		"catalog_b": [_row_catalog.bind(["stable", "tower", "kantu_shed", "felt_yard"]), Vector3(0, 1.5, 0), 0.0, 42.0, 40.0],
		"catalog_c": [_row_catalog.bind(["latrine", "watch_fire", "yurt_pad", "tent_qiang", "hollow_gate"]), Vector3(0, 0.5, 0), 0.0, 45.0, 36.0],
		"pens": [_row_catalog.bind(["offering_pen"]), Vector3(0, 0.5, 0), 0.0, 48.0, 40.0],
		"tower_stages": [_row_catalog_stages.bind("tower"), Vector3(0, 2.0, 0), 0.0, 40.0, 40.0],
		"stable_stages": [_row_catalog_stages.bind("stable"), Vector3(0, 1.0, 0), 0.0, 40.0, 40.0],
	}


func _setup_world() -> void:
	_camera = Camera3D.new()
	_camera.near = 0.05
	_camera.far = 3000.0
	_camera.fov = FOV
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(_camera)
	_camera.make_current()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.38, 0.52, 0.72)
	sky_mat.sky_horizon_color = Color(0.78, 0.8, 0.82)
	sky_mat.ground_bottom_color = Color(0.35, 0.3, 0.25)
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	ground.mesh = plane
	ground.material_override = Style.toon(Color(0.86, 0.88, 0.9) if _snow > 0.5 else Color(0.5, 0.52, 0.34), {"brush_strength": 0.15})
	add_child(ground)


func _yurt(holder: Node3D, at: Vector3, rec: Dictionary, stage: int = 7, t: float = 0.0) -> StagedYurt:
	var y := StagedYurt.new()
	y.configure(rec)
	y.position = at
	y.rotation.y = float(rec.get("rot", 0.0))
	y.snow = _snow
	y.room_auto = false
	holder.add_child(y)
	y.set_stage(stage, t, false)
	y.snow = _snow
	y.refresh()
	return y


func _row_sizes(holder: Node3D, style: String) -> void:
	var xs := [-11.5, 0.0, 13.5]
	var sizes := ["s", "m", "l"]
	for i in 3:
		_yurt(holder, Vector3(xs[i], 0, 0), {"size": sizes[i], "style": style, "layout": "ev", "preset": "winter", "rot": 0.4})


func _row_styles(holder: Node3D) -> void:
	var styles := ["hun", "yuezhi", "usun", "tunghu", "dingling", "loufan", "baiyang"]
	for i in styles.size():
		var x := (float(i) - 3.0) * 8.6
		_yurt(holder, Vector3(x, 0, -2.0 + 4.0 * float(i % 2)), {"size": "m", "style": styles[i], "preset": "winter", "rot": 0.3})


func _row_stages(holder: Node3D) -> void:
	for i in 8:
		var x := (float(i % 4) - 1.5) * 8.4
		var z := -5.0 + 10.0 * float(i / 4)
		_yurt(holder, Vector3(x, 0, z), {"size": "m", "style": "hun", "layout": "otaci", "preset": "hero", "rot": 0.25}, i - 1, 0.55)


func _row_fall(holder: Node3D) -> void:
	var a := _yurt(holder, Vector3(-5.0, 0, 0), {"size": "m", "style": "yuezhi", "preset": "winter", "rot": 0.3})
	a.tear = 0.6
	a.frame_on = 1.0
	a.refresh()
	var b := _yurt(holder, Vector3(5.0, 0, 0), {"size": "m", "style": "yuezhi", "preset": "winter", "rot": 0.3})
	b.burn = 0.7
	b.damage = 0.6
	b.refresh()


func _row_layouts(holder: Node3D, keys: Array) -> void:
	for i in keys.size():
		var x := (float(i) - 1.5) * 8.0
		var y := _yurt(holder, Vector3(x, 0, 0), {"size": "m", "style": "hun", "layout": keys[i], "preset": "hero", "open": true, "rot": 0.0})
		y.cut = 1.0
		y.refresh()


func _row_closed(holder: Node3D) -> void:
	for i in 3:
		var x := (float(i) - 1.0) * 9.0
		var y := _yurt(holder, Vector3(x, 0, -4.0), {"size": ["s", "m", "l"][i], "style": "yuezhi", "preset": "closed", "rot": 0.2})
		y.glow = 1.0
		y.refresh()
		_yurt(holder, Vector3(x, 0, 6.0), {"size": ["s", "m", "l"][i], "style": "yuezhi", "preset": "dome", "rot": 0.2})


func _row_catalog(holder: Node3D, kinds: Array) -> void:
	for i in kinds.size():
		var x := (float(i) - float(kinds.size() - 1) * 0.5) * 11.0
		var rec := {"kind": kinds[i], "id": kinds[i], "at": [x, 0.0], "rot": 0.3}
		var node := StructureKit.build(rec, {"snow": _snow})
		if node:
			holder.add_child(node)


func _row_catalog_stages(holder: Node3D, kind_id: String) -> void:
	var top := StructureCatalog.stages_of(kind_id)
	for i in top + 1:
		var x := (float(i) - float(top) * 0.5) * 10.0
		var rec := {"kind": kind_id, "id": "%s_%d" % [kind_id, i], "at": [x, 0.0], "rot": 0.3}
		var node := StructureKit.build(rec, {"snow": _snow})
		if node:
			holder.add_child(node)
			if node is StagedStructure:
				(node as StagedStructure).set_stage(i - 1, 0.6, false)


static func _wanted(filter: String, id: String) -> bool:
	if filter.is_empty():
		return true
	for part in filter.split(","):
		if id.contains(part):
			return true
	return false
