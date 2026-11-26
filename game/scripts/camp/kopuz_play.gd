class_name KopuzPlay
extends SkeletonModifier3D
## Ozanın kopuz çalışı (K60, K68; Önsöz'ün kamp sahnesi): ozanın iskeletinde (CharacterAvatar'ın Meshy modeli)
## çalışan değiştirici.
##   - lift(): kopuz LIFT_TIME (1,1 sn) içinde kucaktan çalış pozuna kalkar (Kopuz.set_lift); sol el sapı sarar, sağ el
##     tellerin üstüne gelir (iki kemikli ters kinematik: LeftArm → LeftForeArm → LeftHand ve sağdaki eşi; elin yönü
##     kopuzun uzayındaki duruştan: NECK_*, STRUM_*), ağırlık kalkışla birlikte artar.
##   - start_strum(): sağ el teller boyunca dik salınır, bilek biraz sallanır (STRUM_ROCK), ön kol (RightForeArm) onunla döner: STROKE_HZ (1,2534 tur/sn,
##     kaydın vuruş ızgarası; bir tur aşağı-yukarı iki vuruş). Faz şarkının saatindendir ((song_time − STROKE_ANCHOR) ×
##     STROKE_HZ; kamp sahnesi her kare yazar): el her ızgara noktasında telleri geçer, söylerken yavaşlamaz.
##   - palm_mute(): son vuruşta avuç tellerde kalır (salınım 0).
##   - rest(): kucağa döner; detach(): kopuz kucak pozuna konur, değiştirici kalkar.
##   - Parmaklar (HandGrip, parmak kemiği varsa): kalkışla birlikte sol el sapı kavrar, sağ el tellerin üstünde durur; kucakta doğal el.
## Ağırlık 0'ken (menü, kucak pozu) hiçbir kemiğe dokunulmaz: menü karesi değişmez. Kemik adları Meshy iskeletinindir;
## iskelet yoksa (chibi yedeği) ya da adlar bulunmazsa yalnız kopuz kalkar; parmak kemiği yoksa (eski model) avucun yeri bilinmez: bilek
## hedefe gider, el kolla döner.
##   var play := KopuzPlay.attach(bard, kopuz)   # bard: CharacterAvatar, kopuz: Kopuz (CampNpcs/Elder/Kopuz)
##   play.lift(); play.start_strum(); play.song_time = t; play.palm_mute(); play.rest(); play.detach()

## Vuruşun turu (tur/sn): kol kaydın vuruş ızgarasına uyar (K60, K95). Seçili çekim 3104'ün ızgarası 0,3989 sn'dir
## (tools/song/k75_measure.json, info.strokeGrid; 2,507 vuruş/sn, vuruşların %73'ü oturur; planın sekizliği 0,3846 sn), bir
## tur iki vuruştur (aşağı ve yukarı): 1 / (2 × 0,3989). Ölçünün counted.strokesPerSec'i (2,12) K75'in sayılan ölçüsüdür, kolun
## hızı değildir: sessiz baş ve kuyruğu da böler. Çekim değişirse sabitler de değişir (test_kopuz).
const STROKE_HZ := 1.2534
## Faz sabiti (sn, şarkının başından): el telleri bu anda aşağı geçer. Izgaranın ilk noktası, kaydın ilk duyulur vuruşu
## (info.strokeGrid.anchor). Sonra her tam turda aşağı, her yarım turda yukarı geçer: iki geçiş de ızgara noktasındadır.
const STROKE_ANCHOR := 2.299
## Kaldırma ve kucağa dönüş süresi (saniye).
const LIFT_TIME := 1.1
const REST_TIME := 1.0
## Vuruşta elin teller boyunca dik gidip gelişi (metre, kopuzun yerel X'inde; ± bu kadar).
const STRUM_REACH := 0.045
## Kol zincirleri (Meshy iskeletinin adları): omuz-kol, ön kol, el.
const LEFT_ARM: Array[String] = ["LeftArm", "LeftForeArm", "LeftHand"]
const RIGHT_ARM: Array[String] = ["RightArm", "RightForeArm", "RightHand"]
## Sol elin sapı tutuşu (kopuzun yerel uzayında: sap +Y, göğüs +Z, +X sapın aşağıdaki kenarı). Avuç sapın altında, sapa bakar
## (NECK_PALM); parmaklar bilekten öne ve kafaya doğru uzanır (NECK_FINGERS), sapın önünden üst kenara sarar. Sap avuçta 35°
## çapraz durur: ön kol sapa dik gelmediğinden bilek böyle az kırılır. NECK_STANDOFF: el kemiği ekseninin sap eksenine uzaklığı
## (metre: sapın yarıçapı ve avucun kalınlığı; ölçü test_kopuz).
const NECK_PALM := Vector3(-0.978148, 0.0, -0.207912)
const NECK_FINGERS := Vector3(-0.170311, 0.573576, 0.801252)
const NECK_STANDOFF := 0.045
## Sağ elin tellerin üstündeki duruşu: avuç deriye bakar, parmaklar telleri çaprazlar. STRUM_HAND: avuç ortasının vuruş noktasına
## (Kopuz.STRUM) göre yeri; böyle parmak uçları tellere değer. Vuruşta bilek ± STRUM_ROCK derece sallanır: uçlar telleri süpürür.
const STRUM_PALM := Vector3(0.0, 0.0, -1.0)
const STRUM_FINGERS := Vector3(0.8, 0.6, 0.0)
const STRUM_HAND := Vector3(-0.045, -0.04, 0.06)
const STRUM_ROCK := 10.0
## Sağ dirseğin bükülmesini çektiği yer (kopuzun uzayında): kol kasanın kenarından geçer, kaseye girmez.
const RIGHT_ELBOW := Vector3(-0.27, 0.05, -0.04)
## Avuç ortasının el kemiğindeki yeri: bilekten orta parmağın köküne giden yolun payı (sap parmak köküne yakın oturur).
const PALM_SHARE := 0.75
## Bilekteki burulmanın ön kola geçen payı: kemik başına tek eklem olduğundan hepsi bilekte kalsa bilek büzülür, hepsi ön kola geçse dirsek.
const FOREARM_TWIST := 0.6

## Kaldırılan kopuz (Kopuz: rest_transform ↔ play_transform).
var kopuz: Kopuz
## Ozanın parmak kavraması (parmak kemiği yoksa null).
var grip: HandGrip
## Kucak (0) ile çalış (1) arası.
var lift_weight := 0.0
var strumming := false
var muted := false
## Şarkının saati (saniye, şarkının başından): vuruşun fazı.
var song_time := 0.0

var _tween: Tween


## Ozanın iskeletine (yoksa avatarın kendisine) bir değiştirici ekler ve döndürür.
static func attach(bard: CharacterAvatar, p_kopuz: Kopuz) -> KopuzPlay:
	var play := KopuzPlay.new()
	play.name = "KopuzPlay"
	play.kopuz = p_kopuz
	play.grip = bard.hand_grip if bard else null
	var skeleton := bard.get_skeleton() if bard else null
	var parent: Node = skeleton if skeleton else bard
	if parent:
		parent.add_child(play)
	return play


## Kopuzu kucak pozuna koyar, salınımı durdurur ve değiştiriciyi kaldırır.
func detach() -> void:
	_kill_tween()
	strumming = false
	muted = false
	set_lift(0.0)
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()


## Kopuzu çalış pozuna kaldırır (kalan yol kadar süre). Döner: geçişin Tween'i.
func lift(duration: float = LIFT_TIME) -> Tween:
	return _tween_to(1.0, duration)


## Kucağa döner; salınım ve susturma biter.
func rest(duration: float = REST_TIME) -> Tween:
	strumming = false
	muted = false
	return _tween_to(0.0, duration)


## Kucak (0) ile çalış (1) arası ağırlığı hemen kurar (ileri sarmada).
func set_lift(weight: float) -> void:
	lift_weight = clampf(weight, 0.0, 1.0)
	if grip and is_instance_valid(grip):
		grip.set_shape(&"Left", HandGrip.blend(HandGrip.NATURAL_SHAPE, HandGrip.GRIP_NECK, lift_weight))
		grip.set_shape(&"Right", HandGrip.blend(HandGrip.NATURAL_SHAPE, HandGrip.STRUM_SHAPE, lift_weight))
	if kopuz and is_instance_valid(kopuz):
		if lift_weight <= 0.0:
			kopuz.transform = kopuz.rest_transform
		elif lift_weight >= 1.0:
			kopuz.transform = kopuz.play_transform
		else:
			kopuz.set_lift(lift_weight)


func start_strum() -> void:
	strumming = true
	muted = false


## Son vuruş: avuç tellerde kalır, salınım durur.
func palm_mute() -> void:
	muted = true


## Vuruşun tur sayısı (ilk aşağı vuruştan; önce eksidir).
func cycles() -> float:
	return (song_time - STROKE_ANCHOR) * STROKE_HZ


## Salınım (-1..1): çalmıyorsa ya da susturulduysa 0. Tam turda el telleri aşağı geçer, yarım turda yukarı (ikisinde de 0).
func swing() -> float:
	if not strumming or muted:
		return 0.0
	return sin(TAU * cycles())


## Elin teller boyunca dik kayması (metre).
func strum_offset() -> float:
	return swing() * STRUM_REACH


## Kemiğin iskeletteki sırası (iskelet yoksa ya da ad bulunmazsa -1).
func bone_index(bone_name: String) -> int:
	var skeleton := get_skeleton()
	return skeleton.find_bone(bone_name) if skeleton else -1


## İki kolun kemikleri iskelette var mı?
func has_arms() -> bool:
	for bone_name in LEFT_ARM + RIGHT_ARM:
		if bone_index(bone_name) < 0:
			return false
	return true


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or kopuz == null or not is_instance_valid(kopuz) or lift_weight <= 0.0001:
		return
	var to_skeleton := skeleton.global_transform.affine_inverse()
	var down := (to_skeleton.basis * Vector3.DOWN).normalized()
	var from_kopuz := to_skeleton * kopuz.global_transform
	_hold(skeleton, LEFT_ARM, from_kopuz, Kopuz.GRIP - NECK_PALM * NECK_STANDOFF, NECK_PALM, NECK_FINGERS, down)
	var rock := Basis(Vector3.UP, -swing() * deg_to_rad(STRUM_ROCK))
	var strum_at := Kopuz.STRUM + STRUM_HAND + Vector3(strum_offset(), 0.0, 0.0)
	_hold(skeleton, RIGHT_ARM, from_kopuz, strum_at, rock * STRUM_PALM, rock * STRUM_FINGERS, down, from_kopuz * RIGHT_ELBOW)


## Elin kopuzdaki duruşu: avuç ortası at'ta (kopuzun yerel uzayında), avuç palm'a, parmaklar fingers'a bakar. Bileğin yeri ve elin yönü
## bundan çıkar. Parmak kemiği yoksa bilek at'a gider, el kolla döner.
func _hold(skeleton: Skeleton3D, chain: Array[String], from_kopuz: Transform3D, at: Vector3, palm: Vector3, fingers: Vector3, down: Vector3, elbow_at := Vector3.ZERO) -> void:
	var middle := skeleton.find_bone(chain[2].trim_suffix("Hand") + "Middle1")
	if middle < 0:
		_reach(skeleton, chain, from_kopuz * at, down, lift_weight)
		return
	var rest := skeleton.get_bone_rest(middle)
	var goal := KopuzPlay.hand_basis(rest, from_kopuz.basis * fingers, from_kopuz.basis * palm)
	_reach(skeleton, chain, from_kopuz * at - goal * (rest.origin * PALM_SHARE), down, lift_weight, goal, elbow_at)


## Kol zincirini (kol, ön kol, el) hedefe uzatır; weight: el hedefle eski yeri arasında. hand_goal (Basis) verilirse el o yöne döner,
## burulmanın payı ön kola geçer; elbow_at verilirse dirsek o yana bükülür.
func _reach(skeleton: Skeleton3D, chain: Array[String], target: Vector3, down: Vector3, weight: float, hand_goal: Variant = null, elbow_at := Vector3.ZERO) -> void:
	var arm := skeleton.find_bone(chain[0])
	var fore := skeleton.find_bone(chain[1])
	var hand := skeleton.find_bone(chain[2])
	if arm < 0 or fore < 0 or hand < 0:
		return
	var a := skeleton.get_bone_global_pose(arm)
	var f := skeleton.get_bone_global_pose(fore)
	var h := skeleton.get_bone_global_pose(hand)
	var bend_hint := (f.origin - a.origin).lerp(elbow_at - a.origin, weight) if elbow_at != Vector3.ZERO else Vector3.ZERO
	var solved := KopuzPlay.solve_two_bone(a.origin, f.origin, h.origin, h.origin.lerp(target, weight), down, bend_hint)
	var elbow: Vector3 = solved[0]
	var wrist: Vector3 = solved[1]
	var q1 := KopuzPlay.arc(f.origin - a.origin, elbow - a.origin)
	skeleton.set_bone_global_pose(arm, Transform3D(Basis(q1) * a.basis, a.origin))
	var q2 := KopuzPlay.arc(Basis(q1) * (h.origin - f.origin), wrist - elbow)
	var turn := Basis(q2) * Basis(q1)
	var fore_basis := turn * f.basis
	var hand_turned := turn * h.basis
	if hand_goal is Basis:
		var goal: Quaternion = hand_turned.get_rotation_quaternion().slerp((hand_goal as Basis).get_rotation_quaternion(), weight)
		var axis := (wrist - elbow).normalized()
		var relaxed := (fore_basis * skeleton.get_bone_rest(hand).basis).get_rotation_quaternion()
		fore_basis = Basis(axis, KopuzPlay.twist_about(goal * relaxed.inverse(), axis) * FOREARM_TWIST) * fore_basis
		hand_turned = Basis(goal)
	skeleton.set_bone_global_pose(fore, Transform3D(fore_basis, elbow))
	skeleton.set_bone_global_pose(hand, Transform3D(hand_turned, wrist))


## El kemiğinin yönü (saf): parmak kökü fingers'a, avuç palm'a bakar. rest_middle: orta parmağın kök kemiğinin el kemiğine göre dinlenme
## dönüşümü (origin: bilekten parmak köküne; +Z: avucun yönü, parmak +X dönüşüyle oraya kapanır, HandGrip).
static func hand_basis(rest_middle: Transform3D, fingers: Vector3, palm: Vector3) -> Basis:
	return KopuzPlay._frame(fingers, palm) * KopuzPlay._frame(rest_middle.origin, rest_middle.basis.z).inverse()


static func _frame(x: Vector3, y: Vector3) -> Basis:
	var fx := x.normalized()
	var fy := (y - fx * y.dot(fx)).normalized()
	return Basis(fx, fy, fx.cross(fy))


## Dönüşün axis çevresindeki burulma açısı (radyan, -π..π; saf): salınım-burulma ayrımı.
static func twist_about(q: Quaternion, axis: Vector3) -> float:
	return wrapf(2.0 * atan2(Vector3(q.x, q.y, q.z).dot(axis), q.w), -PI, PI)


## İki kemikli ters kinematik (saf): omuz s, dirsek e, bilek w ve hedef; dirsek eski bükülme düzleminde kalır
## (düz kolda pole yönüne bükülür; bend_hint verilirse omuzdan o yöne bükülür). Kemik boyları korunur; hedef erişilmezse kol
## ona doğru uzanır. Döner: [yeni dirsek, yeni bilek].
static func solve_two_bone(s: Vector3, e: Vector3, w: Vector3, target: Vector3, pole: Vector3, bend_hint := Vector3.ZERO) -> Array[Vector3]:
	var upper := s.distance_to(e)
	var lower := e.distance_to(w)
	var to_target := target - s
	var span := to_target.length()
	if upper < 0.000001 or lower < 0.000001 or span < 0.000001:
		return [e, w]
	var dir := to_target / span
	var reach := clampf(span, absf(upper - lower) + 0.0001, (upper + lower) * 0.9999)
	var toward := bend_hint if bend_hint != Vector3.ZERO else e - s
	var bend := toward - dir * toward.dot(dir)
	if bend.length_squared() < 0.00000001:
		bend = pole - dir * pole.dot(dir)
	if bend.length_squared() < 0.00000001:
		bend = dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.UP)
	bend = bend.normalized()
	var cos_a := clampf((upper * upper + reach * reach - lower * lower) / (2.0 * upper * reach), -1.0, 1.0)
	var angle := acos(cos_a)
	var elbow := s + (dir * cos(angle) + bend * sin(angle)) * upper
	return [elbow, s + dir * reach]


## from yönünü to yönüne çeviren en kısa dönüş (saf; yönlerden biri sıfırsa dönüş yok).
static func arc(from: Vector3, to: Vector3) -> Quaternion:
	if from.length_squared() < 0.0000001 or to.length_squared() < 0.0000001:
		return Quaternion.IDENTITY
	var a := from.normalized()
	var b := to.normalized()
	if a.dot(b) > 0.999999:
		return Quaternion.IDENTITY
	if a.dot(b) < -0.999999:
		var axis := a.cross(Vector3.UP if absf(a.y) < 0.9 else Vector3.RIGHT).normalized()
		return Quaternion(axis, PI)
	return Quaternion(a, b)


func _tween_to(target: float, duration: float) -> Tween:
	_kill_tween()
	_tween = create_tween()
	var left := absf(target - lift_weight)
	_tween.tween_method(set_lift, lift_weight, target, maxf(duration * left, 0.0001)) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _tween


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
