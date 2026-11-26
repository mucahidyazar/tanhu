extends TestCase
## Mete'nin arabanın oturağında oturuşu (K58 M15; Yol Haritası mete-model-checks ve roads-relays): gerçek araba ağı (assets/props/cart_felt,
## kodla tekerlek) ve gerçek Mete (assets/characters/mete). Ölçü RideFit'tir (M9, M10 ile aynı kalıp): kalça oturak noktasında ±1 cm (oturak
## yüzü + kişinin oturuş yüksekliği; araba yolda, eğimli ve dalgalı zeminde dönerken de), diz ve kaval köşeleri araba gövdesine ≤1 cm girer,
## biniş ve iniş sıçramasızdır (bir karelik yol komşu karelerinkinin 2,5 katından ve 3 cm'den büyük değil). Araba CartSeat'le binilir.

const DT := 1.0 / 60.0
const DYE := "res://assets/characters/mete/mete_dye.png"
const DYE2 := "res://assets/characters/mete/mete_dye2.png"
const M15_SEAT := 0.01
const M15_DEPTH := 0.01


## Dalgalı zemin: araba yolda eğilir, yatar (0,12 m, 9 m dalga).
class WavyShape:
	extends TerrainShape

	func height_at(x: float, z: float) -> float:
		return 0.12 * sin(x * 0.7) + 0.1 * sin(z * 0.55)


var _trash: Array[Node] = []
var _player: PlayerController
var _cart: RoadCart
var _seat: CartSeat
var _shape: TerrainShape
var _rider_anim: AnimationPlayer


func before_each() -> void:
	Travel.reset_cache()


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func _setup(wavy := false) -> bool:
	if not ResourceLoader.exists(RoadCart.BODY_PATH):
		print("    atlandı: araba gövdesi yok")
		return false
	_shape = WavyShape.new() if wavy else TerrainShape.new()
	_cart = RoadCart.new()
	_cart.driver_model = ""
	_cart.effects = false
	add_child(_cart)
	_trash.append(_cart)
	_cart.place_axle(Vector2.ZERO, 0.0, _shape)
	_player = PlayerController.new()
	_player.terrain_shape = _shape
	_player.start_active = false
	var avatar := CharacterAvatar.new()
	_player.add_child(avatar)
	add_child(_player)
	_trash.append(_player)
	_player.set_process(false)
	await wait_frames(1)
	_player.obstacles = []
	_player.use_profile(CharacterProfile.new())
	_player.set_active(true)
	_rider_anim = avatar.get_animation_player()
	var tail := _cart.tail_point("S1", _shape)
	_player.spawn_at(tail, _cart.heading + PI)
	_seat = CartSeat.new(_player, _cart, "S1", _shape)
	return true


## Oturak noktası: oturağın yüzü ve kişinin oturuş yüksekliği.
func _seat_point() -> Vector3:
	var s := _cart.seat_transform("S1")
	return s.origin + s.basis.y.normalized() * _seat.lift


func _hips() -> Vector3:
	var skel := _player.get_avatar().get_skeleton()
	return skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Hips")).origin


func _board() -> void:
	assert_true(_seat.begin_board(), "Biner")
	for i in 120:
		_seat.step(DT)
		_rider_anim.advance(DT)
		if _seat.is_seated():
			break
	assert_true(_seat.is_seated(), "Oturdu")
	for i in 30:
		_seat.step(DT)
		_rider_anim.advance(DT)


## Araba yolda: dönemeçli çizgide at yürür, araba izler; her karede yolcu yerleşir.
func _drive(seconds: float, speed := 4.6) -> void:
	var t := 0.0
	var s := 0.0
	while t < seconds:
		s += speed * DT
		var p := Vector2(sin(s * 0.08) * 9.0, s)
		var ahead := Vector2(sin((s + 0.5) * 0.08) * 9.0, s + 0.5)
		var d := ahead - p
		_cart.place_hitch(p + Vector2(0.0, RoadCart.HITCH_L), atan2(d.x, d.y), _shape, speed, DT)
		_seat.step(DT)
		_rider_anim.advance(DT)
		t += DT


func test_m15_hips_sit_on_the_seat_point() -> void:
	if not await _setup(true):
		return
	_board()
	assert_eq(_player.get_avatar().get_current_role(), BenchPose.ROLE, "Oturak pozu")
	assert_true(_player.carried, "Taşınan oturuş")
	assert_eq(_player.prompt_pairs(), [], "Yolcunun kendi ipucu yok")
	var worst := 0.0
	var t := 0.0
	var s := 0.0
	while t < 6.0:
		s += 4.6 * DT
		var p := Vector2(sin(s * 0.08) * 9.0, s)
		var ahead := Vector2(sin((s + 0.5) * 0.08) * 9.0, s + 0.5)
		var d := ahead - p
		_cart.place_hitch(p + Vector2(0.0, RoadCart.HITCH_L), atan2(d.x, d.y), _shape, 4.6, DT)
		_seat.step(DT)
		_rider_anim.advance(DT)
		worst = maxf(worst, _hips().distance_to(_seat_point()))
		t += DT
	assert_true(worst <= M15_SEAT, "M15: kalça oturak noktasından en çok %.2f cm (±1 cm)" % (100.0 * worst))
	print("    M15 kalça: %.2f cm" % (100.0 * worst))


func test_m15_knee_and_shin_stay_out_of_the_cart() -> void:
	if not await _setup(false):
		return
	_board()
	var mi := RideCape.skinned_mesh(_player.get_avatar())
	assert_not_null(mi, "Mete'nin deri giydirilmiş ağı")
	var legs := RideFit.leg_vertices(mi, _image(DYE), 0, _image(DYE2))
	assert_true(legs.size() > 2000, "Diz ve kaval köşeleri (%d)" % legs.size())
	var body_mi: MeshInstance3D = _cart.body.find_children("*", "MeshInstance3D", true, false)[0]
	var worst := 0.0
	for pose in 3:
		if pose > 0:
			_drive(1.2)
		var box := AABB(_cart.global_transform * Vector3(-1.2, 0.2, -1.4), Vector3.ZERO).expand(_cart.global_transform * Vector3(1.2, 2.4, 1.2))
		var body := RideFit.Surface.from_mesh(body_mi, box)
		var pts := RideFit.skinned_points(mi, legs)
		var r := RideFit.penetration(pts, body)
		if pose == 0:
			var deepest := -INF
			var at := Vector3.ZERO
			for p in pts:
				var d := body.depth(p)
				if d > deepest:
					deepest = d
					at = p
			print("    M15 en derin nokta (arabanın yerelinde): %s, %.2f cm" % [_cart.global_transform.affine_inverse() * at, 100.0 * deepest])
		worst = maxf(worst, float(r["max_depth"]))
		assert_true(float(r["max_depth"]) <= M15_DEPTH, "M15 duruş %d: diz ve kaval en çok %.1f cm girer (≤1 cm)" % [pose, 100.0 * float(r["max_depth"])])
	print("    M15 diz ve kaval: en derin %.2f cm" % (100.0 * worst))


func test_m15_boarding_and_alighting_have_no_jumps() -> void:
	if not await _setup(false):
		return
	var skel := _player.get_avatar().get_skeleton()
	var tracked: Array[int] = [skel.find_bone("Hips"), skel.find_bone("LeftHand"), skel.find_bone("RightFoot"), skel.find_bone("Head")]
	var paths := []
	for b in tracked:
		paths.append([])
	assert_true(_seat.begin_board(), "Biner")
	var t := 0.0
	var phase := 0
	while t < 4.0:
		if phase == 0 and _seat.is_seated():
			phase = 1
		elif phase == 1 and t > 1.6:
			phase = 2
			assert_true(_seat.begin_alight(), "İner")
		_seat.step(DT)
		_rider_anim.advance(DT)
		for i in tracked.size():
			(paths[i] as Array).append(skel.global_transform * skel.get_bone_global_pose(tracked[i]).origin)
		t += DT
		if phase == 2 and not _seat.busy():
			break
	assert_eq(_player.get_stance(), PlayerController.Stance.FOOT, "Binip indi")
	assert_false(_player.carried)
	assert_true(_player.is_active(), "Denetim açık")
	var tail := _cart.tail_point("S1", _shape)
	assert_almost(Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2(tail.x, tail.z)), 0.0, 0.02, "Arabanın ardına iner")
	for i in tracked.size():
		var path: Array = paths[i]
		var spikes := 0
		var biggest := 0.0
		for f in range(1, path.size() - 1):
			var d := (path[f] as Vector3).distance_to(path[f - 1])
			var before := (path[f - 1] as Vector3).distance_to(path[f - 2]) if f >= 2 else d
			var after := (path[f + 1] as Vector3).distance_to(path[f])
			biggest = maxf(biggest, d)
			if d > 2.5 * maxf(before, after) + 0.03:
				spikes += 1
		assert_eq(spikes, 0, "M15 %s: biniş ve iniş sıçramasız (karede en çok %.1f cm)" % [skel.get_bone_name(tracked[i]), 100.0 * biggest])


func test_bench_pose_and_seat_geometry() -> void:
	if not await _setup(false):
		return
	var avatar := _player.get_avatar()
	assert_true(BenchPose.prepare(avatar), "Oturak pozu Mete'nin iskeletinde kurulur")
	assert_true(avatar.available_roles().has(BenchPose.ROLE))
	# Oturak arka ağızda, geriye bakar; kenarın ardında boşluk (bacak sarkar), çatının altı başa yeter.
	var s1: Dictionary = _cart.seats["S1"]
	assert_almost(float(s1["yaw"]), PI, 0.001, "Geriye bakar")
	assert_true((s1["at"] as Vector3).z > RoadCart.BED_Z.x, "Oturak döşemenin üstünde")
	assert_true((s1["at"] as Vector3).z - RoadCart.BED_Z.x < 0.5, "Arka kenara yakın (%.2f m)" % ((s1["at"] as Vector3).z - RoadCart.BED_Z.x))


func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))
