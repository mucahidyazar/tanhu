extends Node3D
## Geliştirme sahnesi (Ö2; Önsöz'ün son dört görevi, K110): kurulan ateşin evreleri (HearthView, HearthFire), kuzular ve kardaki iz (LambsView),
## güreşin HUD'u (BeltWrestleHud) kamp dünyasında, K98'in uzak kadrajıyla (22 m, 38°, görüş 36°). Koşucusuzdur: görünüşü ayarlamak içindir.
##
## Komut satırı (tools/capture.sh ... --scene=res://scenes/dev/e21_lab.tscn):
##   --lab=hearth --stage=N   ateş: -1 çatlak ocak, 0 kav tutuştu, 1 küçük, 2 orta, 3 büyük (ışık 2, 4, 7, 10 m); --settled menünün ateşine oturmuş
##   --lab=lambs              kuzular, analar ve kardaki iz (day2_lambs.json'un düzeni)
##   --lab=wrestle            güreşin HUD'u (yüklenişin ortasında, eğiliş görünür)
##   --cam=uzaklık            kameranın uzaklığı (m; varsayılan 22)

const WORLD := preload("res://scenes/world/world.tscn")
const LAMBS_DATA := "res://data/story/prologue_days/day2_lambs.json"

var world: Node3D
var camera: Camera3D
var fire: HearthFire
var view: HearthView
var lambs: LambsView
var sim: BeltWrestle

var _args := {}


func _ready() -> void:
	_args = (preload("res://scripts/dev/capture.gd")).parse_args(OS.get_cmdline_user_args())
	world = WORLD.instantiate()
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 36.0
	add_child(camera)
	camera.make_current()
	match str(_args.get("lab", "hearth")):
		"lambs":
			_lab_lambs()
		"wrestle":
			_lab_wrestle()
		_:
			_lab_hearth()


func _frame(focus: Vector3, yaw_deg: float = 0.0) -> void:
	var d := float(str(_args.get("cam", "22")).replace(",", "."))
	camera.global_transform = FollowCamera.compute_transform(focus + Vector3(0.0, 0.7, 0.0), deg_to_rad(yaw_deg), 38.0, d)


func _lab_hearth() -> void:
	var camp_fire := world.get_node(^"Camp/Campfire") as Node3D
	var stage := int(str(_args.get("stage", "3")))
	fire = HearthFire.new(7)
	if stage >= 0 or _args.has("stones"):
		for i in 3:
			fire.place_stone()
		fire.lay_wood()
	if stage >= 0:
		var t := 0.0
		while not fire.lit and t < 10.0:
			fire.strike(t)
			t += 0.6
		for i in stage:
			fire.feed()
		for i in 600:
			fire.tick(1.0 / 60.0)
	if _args.has("settled"):
		fire.begin_settle()
		for i in 200:
			fire.tick(1.0 / 60.0)
	else:
		camp_fire.visible = false
		camp_fire.process_mode = Node.PROCESS_MODE_DISABLED
		view = HearthView.new()
		view.bind(fire)
		view.cracked = stage < 0 or _args.has("cracked")
		world.add_child(view)
		view.global_position = camp_fire.global_position
	_frame(camp_fire.global_position, float(str(_args.get("yaw", "0"))))


func _lab_lambs() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAMBS_DATA))
	var step: Dictionary = {}
	for s: Variant in data.get("steps", []):
		if (s as Dictionary).get("kind") == "lambs_find":
			step = s
	var shape: RefCounted = world.call(&"get_terrain_shape") if world.has_method(&"get_terrain_shape") else TerrainShape.new()
	var lambs_list: Array = []
	for e: Variant in step.get("lambs", []):
		var d: Dictionary = e
		var at: Variant = d.get("at")
		if at is String:
			at = [-6.0, 84.0]
		lambs_list.append({"at": at, "ewe": d.get("ewe"), "frozen": d.get("frozen", false)})
	var yurt := world.get_node(^"Camp/YurtLeft") as Node3D
	var door := yurt.global_position + yurt.global_basis.z.normalized() * 4.4
	var flock := LambFlock.new({"home": [door.x, door.z], "lambs": lambs_list, "seed": 1})
	lambs = LambsView.new()
	lambs.flock = flock
	lambs.ground = func(x: float, z: float) -> float: return float(shape.call(&"height_at", x, z))
	world.add_child(lambs)
	lambs.build()
	var a: Vector3 = flock.lambs[0]["at"]
	_frame(Vector3(a.x - 4.0, float(shape.call(&"height_at", a.x, a.z)), a.z - 8.0), float(str(_args.get("yaw", "0"))))


func _lab_wrestle() -> void:
	sim = BeltWrestle.new(3)
	sim.start()
	for i in 200:
		sim.step(1.0 / 60.0, 0.2)
	var ui := CanvasLayer.new()
	add_child(ui)
	var hud := BeltWrestleHud.new()
	ui.add_child(hud)
	hud.bind(sim)
	_frame(Vector3.ZERO)


func _process(delta: float) -> void:
	if fire and view:
		fire.tick(delta)
	if lambs:
		lambs.tick(delta)
