extends Node3D
## Geliştirme aracı: Çocukluk'un yerlerini oyun içi kadrajla (K98: eğim 38°, görüş 36°, 14–40 m) gösterir, her çekimi <--out>/<ad>.jpg yazar, kapanır. Oyunun gerçek dünyasıdır
## (childhood_ordos, gün ışığı, boyalı süzgeç); ana sahne kurulmaz, kısa sürer. Pencere açar.
##   Godot --path . --resolution 1920x1080 res://scenes/dev/childhood_lineup.tscn -- --out=$TMPDIR/dizin [--shots=pen,frame]

const WORLD := "res://scenes/maps/childhood_ordos.tscn"
## Oyun içi kadraj (K98).
const PITCH := 38.0
const FOV := 36.0
const SETTLE := 8

var _camera: Camera3D
var _world: OrdosWorld


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	var out := str(args.get("out", OS.get_user_data_dir()))
	var wanted := str(args.get("shots", ""))
	_camera = Camera3D.new()
	_camera.near = 0.05
	_camera.far = 6000.0
	_camera.fov = FOV
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(_camera)
	_camera.make_current()
	_world = (load(WORLD) as PackedScene).instantiate() as OrdosWorld
	add_child(_world)
	while not _world.is_ready():
		await get_tree().process_frame
	_world.set_childhood_mode(true)
	while not _world.is_childhood_ready():
		await get_tree().process_frame
	var site := _world.childhood()
	# Sahte Meshy ağı (--herd-model=res://...): sürüye verilir, kendiliğinden yerine geçişi gösterir.
	if args.has("herd-model"):
		site.herd.set_model_path(str(args["herd-model"]))
		site.herd._request_model()
		while not site.herd.uses_model():
			await get_tree().process_frame
	_cast()
	site.herd.process_mode = Node.PROCESS_MODE_DISABLED
	site.game.process_mode = Node.PROCESS_MODE_DISABLED
	# K98 kadrajı: [sürü durumu, tik, odak işareti (ya da nokta), yön, uzaklık].
	var frame_center := _world.marker("frame_center")
	var shots := {
		"frame_40m": [&"reset", 0, frame_center, 0.0, 40.0],
		"yurt_22m": [&"reset", 0, _world.marker("child_start"), 0.0, 22.0],
		"pen_22m": [&"reset", 0, _world.marker("pen_inside"), 0.0, 22.0],
		"pen_22m_e": [&"reset", 0, _world.marker("pen_inside"), 90.0, 22.0],
		"leaving_22m": [&"release", 90, _world.marker("pen_gate") + Vector3(4.0, 0.0, 0.0), 0.0, 22.0],
		"race_22m": [&"meadow", 10, _world.marker("race_start") + Vector3(13.0, 0.0, -9.0), 0.0, 22.0],
		"stone_22m": [&"meadow", 10, _world.marker("race_stone"), 0.0, 22.0],
		"meadow_22m": [&"meadow", 40, _world.marker("meadow"), 0.0, 22.0],
		"meadow_40m": [&"meadow", 40, _world.marker("meadow"), 270.0, 40.0],
		"count_22m": [&"drive", 110, _world.marker("count_point") + Vector3(0.0, 0.0, 7.0), 0.0, 22.0],
		"count_40m": [&"drive", 110, _world.marker("line_start") + Vector3(4.0, 0.0, -10.0), 90.0, 40.0],
		"hill_22m": [&"meadow", 10, Vector3(66.0, 0.0, -14.0), 0.0, 22.0],
		"gully_22m": [&"meadow", 10, Vector3(38.0, 0.0, 34.0), 0.0, 22.0],
		"south_40m": [&"reset", 0, Vector3(14.0, 0.0, 44.0), 180.0, 40.0],
		"near_14m": [&"reset", 0, _world.marker("pen_gate"), 0.0, 14.0],
		"game_14m": [&"meadow", 10, Vector3(50.0, 0.0, 33.0), 0.0, 14.0],
	}
	var shape := _world.get_terrain_shape()
	# Üç çocuk odakta (ölçek: K98'de kişi kare yüksekliğinin ≈%8–12'si).
	var kids: Array[CharacterAvatar] = []
	for i in 3:
		var kid := CharacterAvatar.new()
		kid.model_override = "child"
		_world.add_child(kid)
		kids.append(kid)
	for id: String in shots:
		if not _wanted(wanted, id):
			continue
		var row: Array = shots[id]
		_advance_herd(site, row[0], row[1])
		var at: Vector3 = row[2]
		var focus := Vector3(at.x, shape.height_at(at.x, at.z) + 0.7, at.z)
		for i in kids.size():
			var k: Vector2 = [Vector2(0.0, 0.0), Vector2(1.5, 0.8), Vector2(-1.3, 1.1)][i]
			kids[i].global_position = Vector3(at.x + k.x, shape.height_at(at.x + k.x, at.z + k.y), at.z + k.y)
		_camera.global_transform = FollowCamera.compute_transform(focus, deg_to_rad(float(row[3])), PITCH, float(row[4]))
		for i in SETTLE:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg(out.path_join(id + ".jpg"), 0.92)
		print("[lineup] ", id)
	get_tree().quit()


## Kişiler ölçek için: sayıcı yerinde, Lan Hatun kapıda.
func _cast() -> void:
	for pair: Array in [["counter", _world.marker("counter")], ["lan_hatun", _world.marker("lan_stand")]]:
		var avatar := CharacterAvatar.new()
		avatar.model_override = pair[0]
		_world.add_child(avatar)
		avatar.global_position = pair[1]


## Sürüyü duruma koyar ve ticks kez ilerletir (kare çizilmeden).
func _advance_herd(site: ChildhoodSite, state: StringName, ticks: int) -> void:
	match state:
		&"reset":
			site.reset_herd()
		&"release":
			site.reset_herd()
			site.release_herd()
		&"meadow":
			site.skip_herd_to_meadow()
		&"drive":
			site.skip_herd_to_meadow()
			site.drive_herd()
	for i in ticks:
		site.herd._process(HerdSim.TICK)


## Çekim süzgeci: virgülle ayrılmış parçalardan biri adında geçiyorsa (boş süzgeç hepsini geçirir).
static func _wanted(filter: String, id: String) -> bool:
	if filter.is_empty():
		return true
	for part in filter.split(","):
		if id.contains(part):
			return true
	return false
