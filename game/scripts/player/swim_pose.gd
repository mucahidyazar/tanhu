class_name SwimPose
extends SkeletonModifier3D
## Yüzme pozu (E21, K110; yer tutucu): kütüphanede yüzme klibi yokken (Meshy Swim_Idle 568, Swim_Forward 569 onayla gelir) kodla kurulan poz.
## Animasyondan sonra uygulanır (CineBow'un yolu: karakter uzayında eksen, kemiğin kendi ekleminde dönüş): gövde öne yatar (kalça), baş
## suyun üstünde kalkar (boyun), kollar sırayla öne uzanıp çeker (köpek kulacı), bacaklar hafifçe çırpar. amount 0..1 (suya girişte açılır),
## speed 0..1 (durunca kulaç yavaşlar, yerinde suyu çiğner), dive 0..1 (dalış: kollar öne, gövde aşağı). Gerçek klip gelince yalnız bu düğüm
## düşer: ChildSwim.CLIP_SWIM / CLIP_SWIM_IDLE kütüphanede varsa onları oynatır.
##   var pose := SwimPose.attach(avatar)    # iskelete eklenir (yoksa null)
##   pose.amount = 1.0

## Gövdenin öne yatışı (derece), başın kalkışı, kulacın genliği ve sıklığı (Hz).
const BODY_TILT := 58.0
const HEAD_LIFT := -48.0
const STROKE_DEG := 46.0
const STROKE_HZ := 0.95
const KICK_DEG := 14.0

@export_range(0.0, 1.0, 0.01) var amount := 0.0
@export_range(0.0, 1.0, 0.01) var speed := 0.0
@export_range(0.0, 1.0, 0.01) var dive := 0.0
## Kulacın evresi kişiden kişiye kayık.
var phase_offset := 0.0

var _axes := Basis.IDENTITY
var _axes_for: Skeleton3D


## İskelete ekler (avatarın iskeleti yoksa null); varsa var olanı döner.
static func attach(avatar: CharacterAvatar) -> SwimPose:
	var skeleton := avatar.get_skeleton() if avatar else null
	if skeleton == null:
		return null
	for c in skeleton.get_children():
		if c is SwimPose:
			return c
	var pose := SwimPose.new()
	pose.name = "SwimPose"
	skeleton.add_child(pose)
	return pose


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or amount <= 0.0001:
		return
	if _axes_for != skeleton:
		_axes = CineBow.character_axes(skeleton)
		_axes_for = skeleton
	var t := float(Time.get_ticks_msec()) / 1000.0
	var w := TAU * STROKE_HZ * lerpf(0.45, 1.0, speed) * t + phase_offset
	var reach := STROKE_DEG * lerpf(0.5, 1.0, speed)
	var turns: Array = [
		["Hips", "lateral", BODY_TILT * (1.0 + dive * 0.35)],
		["Spine01", "lateral", -6.0],
		["neck", "lateral", HEAD_LIFT * (1.0 - dive * 0.8)],
		["RightArm", "lateral", lerpf(-95.0 + reach * sin(w), -150.0, dive)],
		["LeftArm", "lateral", lerpf(-95.0 + reach * sin(w + PI), -150.0, dive)],
		["RightForeArm", "lateral", -18.0 - 22.0 * maxf(sin(w + 0.6), 0.0)],
		["LeftForeArm", "lateral", -18.0 - 22.0 * maxf(sin(w + PI + 0.6), 0.0)],
		["RightUpLeg", "lateral", KICK_DEG * sin(w * 2.0)],
		["LeftUpLeg", "lateral", KICK_DEG * sin(w * 2.0 + PI)],
	]
	for row: Array in turns:
		var bone := skeleton.find_bone(str(row[0]))
		if bone < 0:
			continue
		var pose := skeleton.get_bone_global_pose(bone)
		pose.basis = Basis(CineBow.axis_vector(row[1], _axes), deg_to_rad(float(row[2])) * amount) * pose.basis
		skeleton.set_bone_global_pose(bone, pose)
