class_name CartSeat
extends RefCounted
## Arabanın oturağındaki yolcu (travel.md §3.4, §6.1 BOARD ve ALIGHT; K58 M15, Yol Haritası mete-model-checks): biniş (0,62 sn), oturuş ve
## iniş (0,56 sn). Oyuncu taşınan oturuştadır (PlayerController.carry): denetleyici kipe dokunmaz, yeri ve pozu burada yazılır. Poz BenchPose'tur
## (oturma klibinden türer); kalça oturağın yüzünün oturuş yüksekliği üstünde (M15: ±1 cm), uyluk ve baldır arka kenardan aşağı sarkar.
## Biniş: oyuncu arabanın ardında, geriye (arabanın tersine) bakarak durur; avatarın dönüşümü ayaktaki yerinden oturuşa smoothstep'le kayar,
## ortada küçük bir yay çizer, poz oturuşa karışır (sıçrama yok: M15). İniş tersidir; sonunda oyuncu yerde, denetim açıktır.
##   var seat := CartSeat.new(player, cart, "S1")
##   seat.begin_board(); while seat.busy(): seat.step(dt)      # sonra her kare seat.place()
##   seat.begin_alight(); while seat.busy(): seat.step(dt)     # done yayılır

signal boarded
signal alighted

const BOARD_ARC := 0.12
const ALIGHT_ARC := 0.07

var player: PlayerController
var cart: RoadCart
var seat_id := "S1"
## Kalçanın oturak yüzünden yüksekliği (m; BenchPose.hips_lift).
var lift := 0.11
## Kip: "" (yok), "up" (biniyor), "seated", "down" (iniyor).
var phase := ""

var _t := 0.0
var _s := 0.62
var _from := Transform3D.IDENTITY
var _from_node := Vector3.ZERO
var _to := Transform3D.IDENTITY
var _ground: Object


func _init(p_player: PlayerController = null, p_cart: RoadCart = null, p_seat := "S1", p_ground: Object = null) -> void:
	player = p_player
	cart = p_cart
	seat_id = p_seat
	_ground = p_ground


func busy() -> bool:
	return phase == "up" or phase == "down"


func is_seated() -> bool:
	return phase == "seated"


## Biniş başlar: oyuncu taşınan oturuşa geçer, poz kurulur (BenchPose.prepare), avatar oturağa kayar.
func begin_board(seconds := 0.62) -> bool:
	if player == null or cart == null:
		return false
	var avatar := player.get_avatar()
	BenchPose.prepare(avatar)
	lift = BenchPose.hips_lift(avatar)
	_from = avatar.global_transform
	_from_node = player.global_position
	player.set_active(false)
	player.carry(true)
	avatar.play_pose(BenchPose.ROLE)
	cart.open_roof(true)
	_t = 0.0
	_s = maxf(seconds, 0.01)
	phase = "up"
	return true


## İniş başlar: arabanın ardına, geriye bakarak (tail_point).
func begin_alight(seconds := 0.56) -> bool:
	if phase != "seated" and phase != "up":
		return false
	var tail := cart.tail_point(seat_id, _ground)
	_to = Transform3D(Basis(Vector3.UP, cart.heading + PI), tail)
	player.get_avatar().set_locomotion(0.0)
	_t = 0.0
	_s = maxf(seconds, 0.01)
	phase = "down"
	return true


## Avatarın oturuştaki dünya dönüşümü.
func seated_transform() -> Transform3D:
	return BenchPose.seated_transform(cart.seat_transform(seat_id), player.get_avatar(), lift)


## Oturan yolcuyu arabanın bu karesine yerleştirir (oyuncunun düğümü oturağın yüzünde: kamera arabayı izler).
func place() -> void:
	if phase != "seated" or player == null:
		return
	player.global_position = cart.seat_transform(seat_id).origin
	player.get_avatar().global_transform = seated_transform()


## Geçişin adımı.
func step(delta: float) -> void:
	if not busy():
		place()
		return
	_t += delta
	var k := clampf(_t / _s, 0.0, 1.0)
	var e := smoothstep(0.0, 1.0, k)
	var avatar := player.get_avatar()
	var seat_origin := cart.seat_transform(seat_id).origin
	if phase == "up":
		player.global_position = _from_node.lerp(seat_origin, e)
		var xf := _from.interpolate_with(seated_transform(), e)
		xf.origin += Vector3.UP * sin(PI * k) * BOARD_ARC
		avatar.global_transform = xf
		if k >= 1.0:
			phase = "seated"
			place()
			boarded.emit()
	else:
		player.global_position = seat_origin.lerp(_to.origin, e)
		var xf := seated_transform().interpolate_with(_to, e)
		xf.origin += Vector3.UP * sin(PI * k) * ALIGHT_ARC
		avatar.global_transform = xf
		if k >= 1.0:
			finish()
			alighted.emit()


## İnişin sonu (ya da hemen inme): oyuncu yerde, kip FOOT, denetim açık.
func finish() -> void:
	var tail := cart.tail_point(seat_id, _ground) if phase != "down" else _to.origin
	var yaw := cart.heading + PI
	phase = ""
	cart.open_roof(false)
	player.carry(false)
	var avatar := player.get_avatar()
	avatar.position = Vector3.ZERO
	avatar.rotation = Vector3(0.0, yaw, 0.0)
	player.spawn_at(tail, yaw)
	player.set_active(true)
