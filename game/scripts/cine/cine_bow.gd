class_name CineBow
extends SkeletonModifier3D
## Sinemada kemik zincirini kodla eğen düzeltme (Yol Haritası birth-scene; story.md §4): Teoman doğan güne eğilir
## (SJ 110 單于朝出營，拜日之始生). Varsayılan zincir omurgadır: Meshy iskeletinin Spine02 → Spine01 → Spine → neck
## kemikleri, her biri açının bir payını alır (payların toplamı 1: başın yönü tam angle_deg döner). Animasyondan (oturma,
## bekleme) sonra uygulanır, etkisi amount ile (0..1) açılır; restore amount'u 0'a çeker.
##
## Dönüşler karakter uzayındadır: iskeletin dinlenme pozundan kurulan eksenler (lateral: sağ uyluktan sol uyluğa, up:
## kalçadan boyna, forward: lateral × up, karakterin önü). Meshy iskeletlerinde kemiklerin yerel eksenleri karakterden
## karaktere değiştiği için (ClipRetarget) dönüş iskelet uzayında, kemiğin kendi ekleminde yapılır. Aynı sınıf kol ve
## el hareketleri için de kullanılır (turns): Lan Hatun'un keregeyi tutan kolu, sayıcının çentik atışı, Hereka'nın
## beşiğe yay asışı.
##   var bow := CineBow.new()          # omurga, 40°
##   skeleton.add_child(bow)
##   bow.amount = 1.0                  # tam eğilir
##   bow.turns = [["RightArm", "forward", -110.0]]   # sağ kol yana ve yukarı (yalnız bu dönüş)

## Omurganın kemikleri ve açının payları (alttan üste).
const SPINE := [["Spine02", 0.34], ["Spine01", 0.28], ["Spine", 0.22], ["neck", 0.16]]
## Saygı eğilişinin varsayılan açısı (derece).
const BOW_DEG := 40.0
## Eksen adları.
const AXES: Array[String] = ["lateral", "up", "forward"]

## Eğilme açısı (derece; turns boşken omurgaya dağıtılır).
@export_range(-90.0, 90.0, 0.5) var angle_deg := BOW_DEG
## Etki (0 = yok, 1 = tam).
@export_range(0.0, 1.0, 0.01) var amount := 0.0
## Elle verilen dönüşler: [[kemik, eksen ("lateral", "up", "forward" ya da Vector3, karakter uzayında), derece], ...].
## Boşsa omurga eğilişi (SPINE × angle_deg). Kemikler iskeletteki sırasıyla (üst kemik önce) yazılmalıdır.
var turns: Array = []
## Son uygulamada kemiklere giden toplam açı (derece; sınama okur).
var applied_deg := 0.0

var _axes := Basis.IDENTITY
var _axes_for: Skeleton3D


func _process_modification() -> void:
	applied_deg = 0.0
	var skeleton := get_skeleton()
	if skeleton == null or amount <= 0.0001:
		return
	if _axes_for != skeleton:
		_axes = character_axes(skeleton)
		_axes_for = skeleton
	for t: Array in resolved_turns():
		var bone := skeleton.find_bone(str(t[0]))
		if bone < 0:
			continue
		var angle := deg_to_rad(float(t[2])) * amount
		var pose := skeleton.get_bone_global_pose(bone)
		pose.basis = Basis(axis_vector(t[1], _axes), angle) * pose.basis
		skeleton.set_bone_global_pose(bone, pose)
		applied_deg += float(t[2]) * amount


## Uygulanacak dönüşler: turns ya da omurga eğilişi.
func resolved_turns() -> Array:
	if not turns.is_empty():
		return turns
	var out: Array = []
	for row: Array in SPINE:
		out.append([row[0], "lateral", angle_deg * float(row[1])])
	return out


## Etkiyi kaldırır (restore).
func reset() -> void:
	amount = 0.0
	applied_deg = 0.0


## Karakter uzayının eksenleri iskelet uzayında (saf): x lateral (karakterin solu), y up, z forward (önü). Kemikler
## yoksa birim.
static func character_axes(skeleton: Skeleton3D) -> Basis:
	var left := Vector3.RIGHT
	var up := Vector3.UP
	var l := skeleton.find_bone("LeftUpLeg")
	var r := skeleton.find_bone("RightUpLeg")
	if l >= 0 and r >= 0:
		var d := skeleton.get_bone_global_rest(l).origin - skeleton.get_bone_global_rest(r).origin
		if d.length_squared() > 1e-8:
			left = d.normalized()
	var hips := skeleton.find_bone("Hips")
	var neck := skeleton.find_bone("neck")
	if hips >= 0 and neck >= 0:
		var u := skeleton.get_bone_global_rest(neck).origin - skeleton.get_bone_global_rest(hips).origin
		u -= left * u.dot(left)
		if u.length_squared() > 1e-8:
			up = u.normalized()
	return Basis(left, up, left.cross(up).normalized())


## Eksenin iskelet uzayındaki yönü: ad ("lateral", "up", "forward") ya da karakter uzayında Vector3.
static func axis_vector(axis: Variant, axes: Basis) -> Vector3:
	if axis is Vector3:
		return (axes * (axis as Vector3)).normalized()
	match str(axis):
		"up":
			return axes.y
		"forward":
			return axes.z
	return axes.x
