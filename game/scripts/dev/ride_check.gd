extends Node3D
## Geliştirme sahnesi (Yol Haritası riding, horse-rig, mete-model-checks; K58 M5–M12, K98): oluşturulan Mete (profilin görünüşü, Kışlak Kaftanı
## ve Pelerini, pelerin iskeleti RideCape) ve kampın atı (RideableHorse, toynak IK'sı RideableHooves), oyunun takip kamerası (FollowCamera: yürüyüşte
## 28 m, atta Sürüş 34 m, 38°). Kareler tools/capture.sh ile alınır; oyun içi çekim uzak ve yüksektir (K98), yakın bakış yalnız geliştiricinin
## incelemesidir (--rc-view).
##
## Argümanlar (Godot ... -- ):
##   --rc-mode=seat|walk|trot|gallop|spur|slope|step|foot|run|stand     seat: atta durur; walk/trot/gallop/spur: düz zeminde sürer (spur:
##                          dörtnalda Shift'e yeniden basar); slope: yan yatık yamaçta (14°) atta durur ve yürür; step: 22 cm'lik basamağı geçer; foot /
##                          run: yaya yürür ya da koşar; stand: yaya durur
##   --rc-ground=flat|slope|step   zemin (mode slope/step kendiliğinden seçer)
##   --rc-dye=N             pelerinin boyası (0 Göl Mavisi; kayda yazılmaz)
##   --rc-view=side|back|front|top|game   game: takip kamerası (varsayılan); ötekiler yakın inceleme (atın yanından, arkasından, önünden, üstünden)
##   --rc-zoom=M            inceleme kamerasının uzaklığı (m; varsayılan 4)
##   --rc-aim=M             inceleme kamerasının baktığı yükseklik (m, oyuncunun yerinden; varsayılan 1,2: göğüs; 0,5 toynaklar)
##   --rc-fixed=x,y,z,tx,ty,tz   sabit inceleme kamerası (yerinden hedefe bakar; at önünden geçer: basamağın kenarı)
##   --rc-painterly         boyalı süzgeç (oyundaki gibi)
##   --rc-key               M4: kılığın dört maskesi anahtar renklerinde (pelerin yeşil, levha eflatun, gömlek camgöbeği, kuşak ve şeritler sarı;
##                          tene, saça ve göze taşan boya karede görünür)
## Örnek: tools/capture.sh $TMPDIR/at.png 360 --window=1920x1080 --freeze-time=12 --scene=res://scenes/dev/ride_check.tscn --rc-mode=gallop

const CaptureTool := preload("res://scripts/dev/capture.gd")
const PAINTERLY := preload("res://scenes/ui/painterly_overlay.tscn")
const HORSE_MODEL := "res://assets/animals/horse_brown/horse_brown.glb"
const GROUND_COLOR := Color("#8fa058")
## Yan yamacın eğimi (derece) ve basamağın yüksekliği (m), basamağın yeri (|z|: at hangi yöne yürürse yürüsün basamağa varır).
const SLOPE_DEG := 14.0
const STEP_H := 0.22
const STEP_Z := 6.0

var args := {}
var mode := "seat"
var player: PlayerController
var horse: RideableHorse
var follow: FollowCamera
var shape: TerrainShape
var _t := 0.0
var _view_camera: Camera3D
var _mounted_at := -1.0


class RcShape:
	extends TerrainShape
	var kind := "flat"

	func height_at(x: float, z: float) -> float:
		match kind:
			"slope":
				return x * tan(deg_to_rad(SLOPE_DEG))
			"step":
				return STEP_H if absf(z) > STEP_Z else 0.0
		return 0.0


func _ready() -> void:
	args = CaptureTool.parse_args(OS.get_cmdline_user_args())
	mode = str(args.get("rc-mode", "seat"))
	var ground_kind := str(args.get("rc-ground", "slope" if mode == "slope" else ("step" if mode == "step" else "flat")))
	shape = RcShape.new()
	(shape as RcShape).kind = ground_kind
	_build_environment()
	_build_ground(ground_kind)
	horse = RideableHorse.new()
	horse.name = "Doru"
	horse.model_path = HORSE_MODEL
	add_child(horse)
	horse.place(Vector3(0.0, shape.height_at(0.0, 0.0), 0.0), PI)
	horse.set_ground(shape)
	player = PlayerController.new()
	player.name = "Player"
	player.terrain_shape = shape
	player.start_active = false
	player.play_area_radius = 400.0
	var avatar := CharacterAvatar.new()
	avatar.name = "Avatar"
	player.add_child(avatar)
	add_child(player)
	player.set_process(false)
	follow = FollowCamera.new()
	follow.name = "FollowCamera"
	follow.terrain_shape = shape
	follow.start_active = false
	add_child(follow)
	if args.has("rc-painterly"):
		add_child(PAINTERLY.instantiate())
	_start.call_deferred()


func _start() -> void:
	player.obstacles = []
	var profile := CharacterProfile.new()
	if args.has("rc-dye") and str(args["rc-dye"]).is_valid_int():
		profile.cape_dye = int(args["rc-dye"])
	player.use_profile(profile)
	if args.has("rc-key"):
		for mat in player.get_avatar().get_materials():
			mat.set_shader_parameter(&"cape_color", Color(0.0, 1.0, 0.0))
			mat.set_shader_parameter(&"plate_color", Color(1.0, 0.0, 1.0))
			mat.set_shader_parameter(&"tunic_color", Color(0.0, 1.0, 1.0))
			mat.set_shader_parameter(&"trim_color", Color(1.0, 1.0, 0.0))
	player.camera = follow
	follow.target = player
	if mode == "foot" or mode == "run" or mode == "stand":
		player.spawn_at(Vector3(2.5, 0.0, 2.0), PI)
	else:
		player.spawn_at(Vector3(1.3, 0.0, 0.3), -PI * 0.5)
		player.begin_mount(horse)
	follow.set_active(true)
	follow.set_yaw(0.0, true)
	follow.snap_to_target()
	player.set_active(true)
	var view := str(args.get("rc-view", "game"))
	if view != "game":
		_view_camera = Camera3D.new()
		_view_camera.fov = 30.0
		_view_camera.near = 0.05
		add_child(_view_camera)
		_view_camera.make_current()


func _process(delta: float) -> void:
	_t += delta
	var input := Vector2.ZERO
	var sprint := false
	var riding := player.is_riding()
	if riding and _mounted_at < 0.0:
		_mounted_at = _t
	var since := _t - _mounted_at if _mounted_at >= 0.0 else 0.0
	match mode:
		"walk", "slope":
			input = Vector2(0.0, 1.0) if riding and since > 0.6 else Vector2.ZERO
		"step":
			input = Vector2(0.0, 1.0) if riding and since > 0.6 else Vector2.ZERO
		"trot":
			input = Vector2(0.0, 1.0) if riding and since > 0.6 else Vector2.ZERO
			sprint = riding and since > 0.6 and since < 1.3
		"gallop":
			input = Vector2(0.0, 1.0) if riding and since > 0.6 else Vector2.ZERO
			sprint = riding and since > 0.6
		"spur":
			input = Vector2(0.0, 1.0) if riding and since > 0.6 else Vector2.ZERO
			sprint = riding and since > 0.6 and not (since > 2.6 and since < 2.75)
		"foot":
			input = Vector2(0.0, 1.0) if _t > 0.5 else Vector2.ZERO
		"run":
			input = Vector2(0.0, 1.0) if _t > 0.5 else Vector2.ZERO
			sprint = _t > 0.5
	if mode == "slope" and since > 3.5:
		input = Vector2.ZERO
	player.step(delta, input, sprint, follow.get_yaw())
	if _view_camera:
		_place_view_camera()


## Yakın inceleme kamerası (geliştirici; K98'in oyun karesi değildir): atın yanından, arkasından, önünden ya da üstünden.
func _place_view_camera() -> void:
	var fixed := str(args.get("rc-fixed", "")).split(",")
	if fixed.size() == 6:
		var v: Array[float] = []
		for part in fixed:
			v.append(float(part))
		_view_camera.look_at_from_position(Vector3(v[0], v[1], v[2]), Vector3(v[3], v[4], v[5]), Vector3.UP)
		return
	var at := player.global_position + Vector3(0.0, float(args.get("rc-aim", 1.2)), 0.0)
	var yaw := player.get_facing_yaw()
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var left := Vector3(cos(yaw), 0.0, -sin(yaw))
	var zoom := float(args.get("rc-zoom", 4.0))
	var from := at + left * zoom
	match str(args.get("rc-view", "side")):
		"back":
			from = at - fwd * zoom + Vector3.UP * zoom * 0.25
		"front":
			from = at + fwd * zoom + Vector3.UP * zoom * 0.2
		"top":
			from = at + Vector3.UP * zoom - fwd * 0.01
		"side":
			from = at + left * zoom + Vector3.UP * 0.4
	_view_camera.look_at_from_position(from, at, Vector3.UP)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.adjustment_enabled = true
	ColorGrade.world().apply_to(env)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.light_energy = 1.25
	sun.rotation_degrees = Vector3(-50.0, -40.0, 0.0)
	add_child(sun)


## Zemin: düzde düzlem, yamaçta ve basamakta şeklin ızgarası (1 m'den sık: basamak keskin görünsün).
func _build_ground(kind: String) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GROUND_COLOR
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.material_override = mat
	if kind == "flat" or kind == "step":
		var plane := PlaneMesh.new()
		plane.size = Vector2(240.0, 240.0)
		mi.mesh = plane
		if kind == "step":
			# Basamak: iki yanda dikey duvarlı kutu (|z| > STEP_Z).
			for side: float in [-1.0, 1.0]:
				var box := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				mesh.size = Vector3(240.0, STEP_H, 60.0)
				box.mesh = mesh
				box.material_override = mat
				box.position = Vector3(0.0, STEP_H * 0.5, side * (STEP_Z + 30.0))
				add_child(box)
	else:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var size := 60.0
		var cell := 0.25
		var n := int(size / cell)
		for iz in n:
			for ix in n:
				var x0 := -size * 0.5 + ix * cell
				var z0 := -size * 0.5 + iz * cell
				var quad: Array[Vector3] = []
				for c: Vector2 in [Vector2(x0, z0), Vector2(x0 + cell, z0), Vector2(x0 + cell, z0 + cell), Vector2(x0, z0 + cell)]:
					quad.append(Vector3(c.x, shape.height_at(c.x, c.y - 0.001 if c.y > z0 else c.y + 0.001), c.y))
				for idx: int in [0, 1, 2, 0, 2, 3]:
					st.add_vertex(quad[idx])
		st.generate_normals()
		mi.mesh = st.commit()
	add_child(mi)
