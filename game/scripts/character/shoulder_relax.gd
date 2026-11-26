class_name ShoulderRelax
extends SkeletonModifier3D
## Omuz düzeltmesi: T-pozunda iskeletlenmiş Meshy karakterlerinde köprücük kemikleri kollar inikken de yukarı
## bakar; omuz eklemleri boyun tabanının üstüne çıkar ve karakter omuz silkmiş gibi görünür.
##
## Animasyondan sonra her köprücük, yönüyle yukarı ekseninin dikine (öne bakan eksen) göre drop_deg kadar aşağı
## çevrilir; kol kemiği eski yönünü korur, yalnızca kökü aşağı iner. Böylece omuz çizgisi iner, kolun duruşu
## değişmez, el birkaç santim aşağı ve içeri kayar. Açı karakterin ölçüm dosyasından gelir (<id>_fit.json →
## shoulder_drop; scripts/character/character_fit_tool.gd ölçer). Etkisi SkeletonModifier3D.influence ile kısılır.

## [köprücük, kol] kemik çiftleri (Meshy iskeletinin adları).
const PAIRS := [["LeftShoulder", "LeftArm"], ["RightShoulder", "RightArm"]]

## Köprücüklerin aşağı çevrilme açısı (derece; 0 = düzeltme yok).
@export_range(0.0, 40.0, 0.1) var drop_deg := 0.0


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or drop_deg < 0.01:
		return
	var up := (skeleton.global_basis.inverse() * Vector3.UP).normalized()
	for pair: Array in PAIRS:
		var clavicle := skeleton.find_bone(str(pair[0]))
		var arm := skeleton.find_bone(str(pair[1]))
		if clavicle < 0 or arm < 0:
			continue
		var c := skeleton.get_bone_global_pose(clavicle)
		var a := skeleton.get_bone_global_pose(arm)
		var turn := ShoulderRelax.drop_rotation(a.origin - c.origin, up, deg_to_rad(drop_deg))
		skeleton.set_bone_global_pose(clavicle, Transform3D(turn * c.basis, c.origin))
		skeleton.set_bone_global_pose(arm, Transform3D(a.basis, c.origin + turn * (a.origin - c.origin)))


## Köprücük yönünü (direction) angle radyan aşağı çeviren dönüş (saf fonksiyon). Eksen, yön ile yukarı ekseninin
## dikidir: yön yatayda aynı tarafa bakmayı sürdürür, yalnızca eğimi azalır. Yön dikse dönüş yoktur.
static func drop_rotation(direction: Vector3, up: Vector3, angle: float) -> Basis:
	var axis := direction.cross(up)
	if axis.length_squared() < 0.000001 or absf(angle) < 0.000001:
		return Basis.IDENTITY
	return Basis(axis.normalized(), -angle)


## Yönün yatay düzlemden yukarı eğimi (derece; eksi = aşağı) (saf fonksiyon).
static func elevation_deg(direction: Vector3, up: Vector3) -> float:
	var n := up.normalized()
	var vertical := direction.dot(n)
	var horizontal := (direction - n * vertical).length()
	return rad_to_deg(atan2(vertical, horizontal))
