extends Node3D
## Geliştirme sahnesi (kamp modülü): kamp nesnelerini (yurt, ahır ve atlar, ateş, eşyalar, sancaklar, halılar)
## dünyadaki gece ışığıyla, yanlarında boy karşılaştırması için 1,82 m'lik Mete ile gösterir.
##
## Komut satırı (tools/capture.sh ... --scene=res://scenes/dev/camp_lab.tscn):
##   --pose=x,y,z,yaw,pitch  --fov=derece   kadraj
##   --day                                  gündüz ışığı (modelleri incelemek için)
##   --fallback                             Meshy modelleri yerine kodla çizilen yedek görünümler
##   --markers                              eksen işaretleri (+X kırmızı, +Z mavi)

const CaptureTool := preload("res://scripts/dev/capture.gd")
const PROP_SPACING := 2.4

@onready var _camera := $Camera as Camera3D


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture:
		capture.pose_requested.connect(_on_pose_requested)
		capture.fov_requested.connect(func(fov_deg: float) -> void: _camera.fov = fov_deg)
	_setup_light(args.has("day"))
	# Yedek görünüm: modeller hiç yokmuş gibi davranılır.
	MeshyProp.models_enabled = not args.has("fallback")
	_build_ground()
	_build_camp()
	if args.has("markers"):
		_build_markers()


func _on_pose_requested(pos: Vector3, yaw_deg: float, pitch_deg: float) -> void:
	_camera.global_transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)), pos)


func _setup_light(day: bool) -> void:
	var env := ($WorldEnvironment as WorldEnvironment).environment
	var moon := $MoonLight as DirectionalLight3D
	moon.basis = Basis.looking_at(-World.direction_from_angles(140.0, 50.0), Vector3.UP)
	if day:
		env.adjustment_color_correction = null
		env.ambient_light_energy = 0.9
		env.background_color = Color(0.6, 0.66, 0.72)
		moon.light_color = Color(1.0, 0.97, 0.9)
		moon.light_energy = 1.1
	else:
		env.adjustment_color_correction = ColorGrade.world_night().build_lut()


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(80.0, 60.0)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = Style.toon(Color(0.36, 0.5, 0.24), {"brush_strength": 0.12, "brush_scale": 0.6})
	ground.position = Vector3(0.0, 0.0, 4.0)
	add_child(ground)


func _build_camp() -> void:
	var yurt := Yurt.new()
	yurt.name = "Yurt"
	yurt.radius = 2.7
	yurt.hanging_angle = 42.0
	yurt.emblem_angle = -40.0
	_add(yurt, Vector3(0.0, 0.0, 0.0), 0.0)
	var stable := Stable.new()
	stable.name = "Stable"
	_add(stable, Vector3(12.0, 0.0, -1.0), 0.0)
	for i in 2:
		var horse := Horse.new()
		horse.name = "HorseBrown" if i == 0 else "HorseWhite"
		if i == 1:
			horse.coat_color = Color(0.93, 0.91, 0.87)
			horse.mane_color = Color(0.82, 0.82, 0.85)
			horse.blaze = false
			horse.blanket_color = Color(0.2, 0.3, 0.55)
		horse.position = Vector3(-1.3 + 2.6 * i, 0.0, 0.2)
		horse.rotation.y = deg_to_rad(-90.0 + 15.0 * i)
		stable.add_child(horse)
	var fire := Campfire.new()
	fire.name = "Campfire"
	_add(fire, Vector3(-8.0, 0.0, 3.5), 0.0)
	for i in 2:
		var rug := Rug.new()
		rug.size = Vector2(3.0, 1.75)
		if i == 1:
			rug.field_color = Color(0.2, 0.17, 0.32)
			rug.border_color = Color(0.45, 0.12, 0.08)
		_add(rug, Vector3(-8.0 + (i * 2 - 1) * 2.2, 0.0, 4.4), (i * 2 - 1) * 40.0)
	var kinds := CampProp.Kind.values()
	for i in kinds.size():
		var prop := CampProp.new()
		prop.kind = kinds[i]
		prop.name = CampProp.Kind.keys()[i]
		_add(prop, Vector3(-14.0 + i * PROP_SPACING, 0.0, 8.0), 0.0)
	for i in 2:
		var banner := Banner.new()
		banner.kind = Banner.Kind.SPEAR if i == 0 else Banner.Kind.STANDARD
		if i == 1:
			banner.pole_height = 2.9
			banner.cloth_size = Vector2(0.62, 1.05)
			banner.cloth_color = Color(0.94, 0.91, 0.84)
			banner.emblem_color = Color(0.3, 0.18, 0.12)
			banner.trim_color = Color(0.55, 0.3, 0.16)
			banner.tatter = 0.0
		_add(banner, Vector3(-4.0 + i * 1.6, 0.0, 4.0), 0.0)
	for spot in [Vector3(3.6, 0.0, 3.0), Vector3(9.0, 0.0, 3.2), Vector3(-6.0, 0.0, 6.0)]:
		var mete := CharacterAvatar.new()
		mete.model_override = "mete"
		mete.position = spot
		add_child(mete)


func _add(node: Node3D, pos: Vector3, yaw_deg: float) -> void:
	node.position = pos
	node.rotation.y = deg_to_rad(yaw_deg)
	add_child(node)


func _build_markers() -> void:
	for axis in [[Vector3.RIGHT, Color(0.9, 0.2, 0.2)], [Vector3.BACK, Color(0.2, 0.4, 1.0)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = Procedural3D.box(Vector3(0.08, 0.08, 0.08) + (axis[0] as Vector3).abs() * 4.0)
		mi.material_override = Style.unshaded(axis[1])
		mi.position = (axis[0] as Vector3) * 2.0 + Vector3(0.0, 0.05, 0.0)
		add_child(mi)
