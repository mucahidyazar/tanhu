@tool
class_name ChibiCharacter
extends Procedural3D
## Ateş başında oturan sevimli (chibi) karakter.
##
## Tüm parçalar basit şekillerden (küre, kapsül, silindir) kurulur; doku dosyası gerekmez.
## Yerel +Z yüz yönüdür. auto_face açıksa gövde face_point noktasına (ör. ateşe) döner.
## Çalışırken nefes alır, başını oynatır, göz kırpar; dombra çalan karakter tel çalar.

enum Pose { CROSS_LEGGED, KNEELING, PLAYING_LUTE, HOLDING_CUP, STANDING }
enum Hair { SHORT, TOP_BUN, PONYTAIL, TWIN_BRAIDS, FUR_HAT }
enum Beard { NONE, SHORT, LONG }

## Kafa yarıçapı (body_scale = 1 iken). Chibi oranı: kafa, gövdeden büyük.
const HEAD_RADIUS := 0.21

@export var pose: Pose = Pose.CROSS_LEGGED:
	set(value):
		pose = value
		queue_rebuild()
@export var hair: Hair = Hair.SHORT:
	set(value):
		hair = value
		queue_rebuild()
@export var beard: Beard = Beard.NONE:
	set(value):
		beard = value
		queue_rebuild()
@export_range(0.5, 1.6) var body_scale := 1.0:
	set(value):
		body_scale = value
		queue_rebuild()

@export_group("Renkler")
@export var skin_color := Style.SKIN:
	set(value):
		skin_color = value
		queue_rebuild()
@export var hair_color := Style.HAIR_DARK:
	set(value):
		hair_color = value
		queue_rebuild()
@export var outfit_color := Color(0.62, 0.22, 0.2):
	set(value):
		outfit_color = value
		queue_rebuild()
@export var trim_color := Style.FUR_WHITE:
	set(value):
		trim_color = value
		queue_rebuild()
@export var pants_color := Color(0.25, 0.2, 0.18):
	set(value):
		pants_color = value
		queue_rebuild()
@export var boots_color := Color(0.24, 0.15, 0.1):
	set(value):
		boots_color = value
		queue_rebuild()
@export var belt_color := Style.GOLD:
	set(value):
		belt_color = value
		queue_rebuild()
@export var accent_color := Color(0.85, 0.25, 0.2):
	set(value):
		accent_color = value
		queue_rebuild()

@export_group("Kıyafet")
@export var fur_collar := true:
	set(value):
		fur_collar = value
		queue_rebuild()
@export var has_armor := false:
	set(value):
		has_armor = value
		queue_rebuild()
@export var armor_color := Color(0.34, 0.28, 0.24):
	set(value):
		armor_color = value
		queue_rebuild()
@export var has_cape := false:
	set(value):
		has_cape = value
		queue_rebuild()
@export var cape_color := Color(0.93, 0.91, 0.87):
	set(value):
		cape_color = value
		queue_rebuild()

@export_group("Duruş")
## Gövdenin döneceği nokta (dünya koordinatı). Varsayılan: kamp ateşi.
@export var face_point := Vector3.ZERO:
	set(value):
		face_point = value
		_update_facing()
@export var auto_face := true:
	set(value):
		auto_face = value
		_update_facing()
## Başın ek dönüşü (derece): sağa/sola bakış ve yana eğim.
@export_range(-60.0, 60.0) var head_turn := 0.0
@export_range(-30.0, 30.0) var head_tilt := 0.0
## Editörde de canlandırılsın mı? (Kapalıyken yalnızca oyunda hareket eder.)
@export var animate_in_editor := false

## Ayakta pozda hareket miktarı: 0 = duruyor, 1 = yürüyor, 2 = koşuyor (set_locomotion ile ayarlanır).
var locomotion := 0.0
var _stride := 0.0

var _rig := {}
var _time := 0.0
var _phase := 0.0
var _blink_timer := 3.0
var _blink_left := 0.0


func _ready() -> void:
	_phase = float(StableSeed.of(self, 997)) * 0.173
	set_notify_transform(true)
	super._ready()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_facing()


func _process(delta: float) -> void:
	if _rig.is_empty() or (Engine.is_editor_hint() and not animate_in_editor):
		return
	_time += delta
	animate(_time + _phase, delta)


## Yürüme hızını (m/s) yürüme döngüsü miktarına çevirir: 1.6 m/s yürüme, 4.2 m/s koşu.
func set_locomotion(speed_mps: float) -> void:
	locomotion = 0.0 if speed_mps < 0.05 else (speed_mps / 1.6 if speed_mps < 1.6 else 1.0 + clampf((speed_mps - 1.6) / 2.6, 0.0, 1.0))


## Bir karelik animasyon (testlerde doğrudan çağrılabilir).
func animate(t: float, delta: float) -> void:
	var breathe := sin(t * 1.6)
	var spine: Node3D = _rig["spine"]
	spine.scale = Vector3(1.0 + breathe * 0.006, 1.0 + breathe * 0.014, 1.0 + breathe * 0.006)
	if pose == Pose.STANDING:
		_animate_stride(delta)
	var head: Node3D = _rig["head"]
	var nod := 0.0
	if pose == Pose.PLAYING_LUTE:
		var strum := sin(t * TAU * 1.6)
		(_rig["arm_r"] as Node3D).rotation = Vector3(strum * 0.1, 0.0, strum * 0.16)
		nod = absf(sin(t * TAU * 0.8)) * 0.07
	head.rotation = Vector3(
		sin(t * 0.47) * 0.035 + nod,
		deg_to_rad(head_turn) + sin(t * 0.31) * 0.12,
		deg_to_rad(head_tilt) + sin(t * 0.39) * 0.04)
	_update_blink(delta)


## Ayakta pozda bacak/kol salınımı ve gövde zıplaması (basit yürüme döngüsü).
func _animate_stride(delta: float) -> void:
	var amount := clampf(locomotion, 0.0, 2.0)
	var walk := minf(amount, 1.0)
	var run := maxf(amount - 1.0, 0.0)
	_stride += delta * lerpf(7.0, 11.5, run) * (1.0 if amount > 0.01 else 0.0)
	var swing := sin(_stride)
	var leg_amp := 0.5 * walk + 0.25 * run
	var arm_amp := 0.4 * walk + 0.35 * run
	(_rig["leg_l"] as Node3D).rotation.x = swing * leg_amp
	(_rig["leg_r"] as Node3D).rotation.x = -swing * leg_amp
	(_rig["arm_l"] as Node3D).rotation.x = -swing * arm_amp
	(_rig["arm_r"] as Node3D).rotation.x = swing * arm_amp
	var spine: Node3D = _rig["spine"]
	spine.position.y = _rig["pelvis_y"] + absf(sin(_stride)) * (0.02 * walk + 0.025 * run)
	(_rig["body"] as Node3D).rotation.x = 0.1 * run


func _update_blink(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_left = 0.13
		_blink_timer = randf_range(2.5, 5.5)
	var closed := _blink_left > 0.0
	_blink_left = maxf(_blink_left - delta, 0.0)
	for eye in _rig.get("eyes", []):
		(eye as Node3D).scale.y = 0.12 if closed else 1.0


func _update_facing() -> void:
	var body := _rig.get("body") as Node3D
	if body == null or not is_inside_tree():
		return
	if not auto_face:
		body.rotation.y = 0.0
		return
	var local := to_local(face_point)
	if Vector2(local.x, local.z).length() > 0.01:
		body.rotation.y = atan2(local.x, local.z)


# --- Kurulum -----------------------------------------------------------------

func _build() -> void:
	_rig = {}
	var body := add_pivot("Body")
	body.scale = Vector3.ONE * body_scale
	_rig["body"] = body
	var kneeling := pose == Pose.KNEELING
	var standing := pose == Pose.STANDING
	var pelvis_y := 0.36 if standing else (0.2 if kneeling else 0.11)
	var torso_h := 0.34 if kneeling or standing else 0.35
	_rig["pelvis_y"] = pelvis_y

	_build_legs(body, kneeling)
	var spine := add_pivot("Spine", Transform3D(Basis.IDENTITY, Vector3(0.0, pelvis_y, 0.0)), body)
	_rig["spine"] = spine
	_build_torso(spine, torso_h)
	_build_arms(spine, torso_h)
	var head := add_pivot("Head", Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h + 0.03, 0.0)), spine)
	_rig["head"] = head
	_build_head(head)
	_update_facing()


func _build_legs(body: Node3D, kneeling: bool) -> void:
	var robe := Style.toon(outfit_color, {"brush_strength": 0.12})
	var pants := Style.toon(pants_color)
	var boots := Style.toon(boots_color)
	if pose == Pose.STANDING:
		# Ayakta: kalçadan dönen bacaklar (yürüme döngüsü için) ve kalçayı örten kısa etek.
		add_mesh(cylinder(0.17, 0.205, 0.13, 20), robe, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.36, 0.0)), body)
		for side in [-1.0, 1.0]:
			var leg := add_pivot("LegL" if side > 0.0 else "LegR", Transform3D(Basis.IDENTITY, Vector3(side * 0.08, 0.34, 0.0)), body)
			_rig["leg_l" if side > 0.0 else "leg_r"] = leg
			add_mesh(capsule(0.066, 0.24), pants, limb_transform(Vector3.ZERO, Vector3(0.0, -0.26, 0.01)), leg)
			add_mesh(sphere(0.07), boots, Transform3D(Basis.IDENTITY.scaled(Vector3(0.95, 0.8, 1.35)), Vector3(0.0, -0.29, 0.035)), leg)
		return
	if kneeling:
		# Diz çökmüş: çan biçimli etek, altında katlanmış bacaklar.
		add_mesh(cylinder(0.17, 0.26, 0.24, 20), robe, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.12, 0.02)), body)
		for side in [-1.0, 1.0]:
			add_mesh(capsule(0.075, 0.2), pants, limb_transform(Vector3(side * 0.09, 0.11, 0.0), Vector3(side * 0.1, 0.09, 0.22)), body)
			add_mesh(sphere(0.06, 0.8), boots, Transform3D(Basis.IDENTITY, Vector3(side * 0.08, 0.05, -0.17)), body)
		_add_trim_ring(body, 0.255, 0.012, 0.03)
	else:
		# Bağdaş kurmuş: eteğin örttüğü kucak ve öne çaprazlanmış bacaklar.
		add_mesh(sphere(0.2), robe, Transform3D(Basis.IDENTITY.scaled(Vector3(1.28, 0.42, 1.05)), Vector3(0.0, 0.1, 0.04)), body)
		for side in [-1.0, 1.0]:
			var hip := Vector3(side * 0.2, 0.08, 0.06)
			var foot := Vector3(-side * 0.12, 0.07, 0.24)
			add_mesh(capsule(0.068, hip.distance_to(foot)), pants, limb_transform(hip, foot), body)
			add_mesh(sphere(0.068), boots, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.85, 1.3)), Vector3(-side * 0.13, 0.065, 0.25)), body)


func _build_torso(spine: Node3D, torso_h: float) -> void:
	var robe := Style.toon(outfit_color, {"brush_strength": 0.12})
	add_mesh(cylinder(0.12, 0.18, torso_h, 20), robe, Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h * 0.5, 0.0)), spine)
	# Kemer.
	add_mesh(cylinder(0.168, 0.172, 0.05, 20), Style.toon(belt_color), Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h * 0.3, 0.0)), spine)
	# Göğüste dikey yaka şeridi (kaftan kapanışı).
	add_mesh(box(Vector3(0.035, torso_h * 0.7, 0.02)), Style.toon(trim_color), Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h * 0.6, 0.138)), spine)
	if fur_collar:
		var collar := add_mesh(torus(0.06, 0.15), Style.toon(trim_color, {"brush_strength": 0.3, "brush_scale": 18.0}),
			Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.75, 1.0)), Vector3(0.0, torso_h - 0.01, 0.0)), spine)
		collar.name = "Collar"
	if has_armor:
		var armor := Style.toon(armor_color, {"brush_strength": 0.15})
		var gold := Style.toon(Style.GOLD)
		add_mesh(cylinder(0.14, 0.165, 0.17, 20), armor, Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h * 0.62, 0.0)), spine)
		add_mesh(torus(0.13, 0.155), gold, Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h * 0.62 + 0.085, 0.0)), spine)
		add_mesh(sphere(0.035), gold, Transform3D(Basis.IDENTITY, Vector3(0.0, torso_h * 0.62, 0.16)), spine)
		for side in [-1.0, 1.0]:
			var pad := add_mesh(_dome(0.09, 10), armor, Transform3D(Basis(Vector3.BACK, side * -0.6), Vector3(side * 0.15, torso_h - 0.05, 0.0)), spine)
			pad.name = "ShoulderPad"
	if has_cape:
		# Omuzlardan yere uzanan, arkada açık bir kabuk.
		var profile := PackedVector2Array([Vector2(0.36, -0.1), Vector2(0.3, 0.1), Vector2(0.2, torso_h * 0.8), Vector2(0.16, torso_h - 0.02)])
		var cape := MeshKit.lathe(profile, 14, 1.0, PI + 0.35, TAU - 0.35)
		add_mesh(cape, Style.toon_double(cape_color, {"brush_strength": 0.1}), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -0.02)), spine)


func _build_arms(spine: Node3D, torso_h: float) -> void:
	var sleeve := Style.toon(outfit_color, {"brush_strength": 0.12})
	var skin := Style.toon(skin_color, {"brush_strength": 0.03})
	var cuff := Style.toon(trim_color, {"brush_strength": 0.3, "brush_scale": 18.0})
	var shoulder_y := torso_h - 0.05
	for side in [-1.0, 1.0]:
		# side: +1 = karakterin solu (+X), -1 = sağı (-X).
		var targets := _arm_targets(side, shoulder_y)
		var shoulder := Vector3(side * 0.15, shoulder_y, 0.0)
		var pivot := add_pivot("ArmL" if side > 0.0 else "ArmR", Transform3D(Basis.IDENTITY, shoulder), spine)
		_rig["arm_l" if side > 0.0 else "arm_r"] = pivot
		var elbow: Vector3 = targets[0] - shoulder
		var hand: Vector3 = targets[1] - shoulder
		add_mesh(capsule(0.052, elbow.length()), sleeve, limb_transform(Vector3.ZERO, elbow), pivot)
		add_mesh(capsule(0.047, elbow.distance_to(hand)), sleeve, limb_transform(elbow, hand), pivot)
		add_mesh(torus(0.035, 0.065), cuff, limb_transform(hand.lerp(elbow, 0.22), hand.lerp(elbow, 0.2)), pivot)
		add_mesh(sphere(0.05), skin, Transform3D(Basis.IDENTITY, hand), pivot)
	if pose == Pose.PLAYING_LUTE:
		_build_lute(spine)
	elif pose == Pose.HOLDING_CUP:
		var cup := MeshKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.036, 0.06)]), 12)
		add_mesh(cup, Style.toon(Style.WOOD_LIGHT), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, 0.24)), spine)


## Poza göre dirsek ve el hedefleri (omurga uzayında).
func _arm_targets(side: float, shoulder_y: float) -> Array[Vector3]:
	match pose:
		Pose.STANDING:
			return [Vector3(side * 0.205, shoulder_y - 0.16, -0.01), Vector3(side * 0.215, shoulder_y - 0.33, 0.03)]
		Pose.KNEELING:
			return [Vector3(side * 0.2, shoulder_y - 0.17, 0.06), Vector3(side * 0.09, 0.05, 0.18)]
		Pose.HOLDING_CUP:
			return [Vector3(side * 0.21, shoulder_y - 0.18, 0.07), Vector3(side * 0.045, 0.11, 0.22)]
		Pose.PLAYING_LUTE:
			if side > 0.0:
				return [Vector3(0.27, shoulder_y - 0.12, 0.12), Vector3(0.3, 0.28, 0.22)]
			return [Vector3(-0.21, shoulder_y - 0.18, 0.1), Vector3(-0.05, 0.11, 0.25)]
		_:
			return [Vector3(side * 0.23, shoulder_y - 0.17, 0.07), Vector3(side * 0.19, 0.0, 0.2)]


func _build_lute(spine: Node3D) -> void:
	# Dombra: armut biçimli gövde ve uzun sap; sap karakterin soluna ve yukarı uzanır.
	var body_center := Vector3(0.0, 0.1, 0.2)
	var neck_end := Vector3(0.46, 0.4, 0.22)
	var pivot := add_pivot("Lute", Transform3D(Basis.looking_at(neck_end - body_center, Vector3.UP, true), body_center), spine)
	var wood := Style.toon(Color(0.66, 0.4, 0.2), {"brush_strength": 0.08})
	var dark := Style.toon(Style.WOOD_DARK)
	add_mesh(sphere(0.11), wood, Transform3D(Basis.IDENTITY.scaled(Vector3(0.85, 0.38, 1.2)), Vector3(0.0, 0.0, -0.02)), pivot)
	add_mesh(sphere(0.03), dark, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.038, 0.02)), pivot)
	var length := body_center.distance_to(neck_end)
	add_mesh(box(Vector3(0.035, 0.022, length)), dark, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.02, length * 0.5)), pivot)
	add_mesh(box(Vector3(0.05, 0.03, 0.08)), dark, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.02, length + 0.03)), pivot)


func _build_head(head: Node3D) -> void:
	var r := HEAD_RADIUS
	var c := Vector3(0.0, r * 0.92, 0.0)
	var skin := Style.toon(skin_color, {"brush_strength": 0.03, "rim_strength": 0.35})
	var hair_mat := Style.toon(hair_color, {"brush_strength": 0.14, "brush_scale": 9.0, "rim_strength": 0.4})
	add_mesh(cylinder(0.05, 0.055, 0.07), skin, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0)), head)
	add_mesh(sphere(r, 0.94), skin, Transform3D(Basis.IDENTITY, c), head)
	# Kulaklar.
	for side in [-1.0, 1.0]:
		add_mesh(sphere(0.045), skin, Transform3D(Basis.IDENTITY.scaled(Vector3(0.55, 1.0, 0.8)), c + Vector3(side * r * 0.97, -0.02, -0.01)), head)
	_build_face(head, c)
	_build_hair(head, c, hair_mat)
	_build_beard(head, c)


func _build_face(head: Node3D, c: Vector3) -> void:
	var r := HEAD_RADIUS
	var eye_mat := Style.toon(Color(0.09, 0.06, 0.08), {"brush_strength": 0.0, "rim_strength": 0.0})
	var shine := Style.unshaded(Color(1.0, 1.0, 1.0))
	var blush := Style.toon(skin_color.lerp(Color(1.0, 0.45, 0.45), 0.42), {"brush_strength": 0.0})
	var eyes: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var eye_pos := c + Vector3(side * 0.073, -0.022, r * 0.92)
		var eye := add_pivot("Eye", Transform3D(Basis(Vector3.UP, side * 0.36), eye_pos), head)
		add_mesh(sphere(0.034), eye_mat, Transform3D(Basis.IDENTITY.scaled(Vector3(0.78, 1.05, 0.45)), Vector3.ZERO), eye)
		add_mesh(sphere(0.011), shine, Transform3D(Basis.IDENTITY, Vector3(-0.009, 0.014, 0.014)), eye)
		add_mesh(sphere(0.006), shine, Transform3D(Basis.IDENTITY, Vector3(0.008, -0.012, 0.015)), eye)
		eyes.append(eye)
		add_mesh(sphere(0.03), blush, Transform3D(Basis(Vector3.UP, side * 0.55).scaled(Vector3(1.25, 0.6, 0.3)), c + Vector3(side * 0.118, -0.072, r * 0.77)), head)
	_rig["eyes"] = eyes
	# Ağız: küçük, hafif gülümseyen bir çizgi.
	add_mesh(capsule(0.008, 0.026), Style.toon(Color(0.45, 0.18, 0.16)), Transform3D(Basis(Vector3.BACK, PI * 0.5), c + Vector3(0.0, -0.098, r * 0.885)), head)
	# Burun ucu.
	add_mesh(sphere(0.014), Style.toon(skin_color.darkened(0.06)), Transform3D(Basis.IDENTITY, c + Vector3(0.0, -0.055, r * 0.97)), head)
	# Kaşlar (yetişkinlerde daha belirgin).
	if beard != Beard.NONE or hair == Hair.TOP_BUN or hair == Hair.FUR_HAT:
		var brow_color := hair_color if hair != Hair.FUR_HAT else Style.HAIR_WHITE
		for side in [-1.0, 1.0]:
			add_mesh(capsule(0.012 if beard != Beard.LONG else 0.018, 0.04), Style.toon(brow_color),
				Transform3D(Basis(Vector3.BACK, PI * 0.5 - side * 0.2), c + Vector3(side * 0.075, 0.045, r * 0.9)), head)


func _build_hair(head: Node3D, c: Vector3, hair_mat: Material) -> void:
	var r := HEAD_RADIUS
	if hair == Hair.FUR_HAT:
		var fur := Style.toon(trim_color, {"brush_strength": 0.3, "brush_scale": 16.0})
		var gray_hair := Style.toon(Style.HAIR_WHITE, {"brush_strength": 0.14})
		add_mesh(_dome(r * 1.05, 12), gray_hair, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-32.0)), c + Vector3(0.0, 0.0, -0.02)), head)
		var tilt := Basis(Vector3.RIGHT, deg_to_rad(-10.0))
		add_mesh(cylinder(r * 0.9, r * 1.0, 0.17, 20), fur, Transform3D(tilt, c + Vector3(0.0, r * 0.72, -0.012)), head)
		add_mesh(_dome(r * 0.9, 10), fur, Transform3D(tilt.scaled(Vector3(1.0, 0.45, 1.0)), c + Vector3(0.0, r * 0.72 + 0.08, -0.025)), head)
		add_mesh(torus(r * 0.84, r * 1.14), fur, Transform3D(tilt, c + Vector3(0.0, r * 0.56, 0.005)), head)
		var feather := Style.toon(Color(0.97, 0.96, 0.93), {"brush_strength": 0.05})
		add_mesh(sphere(0.03), feather, Transform3D(Basis.from_euler(Vector3(deg_to_rad(-28.0), 0.0, deg_to_rad(-18.0))).scaled(Vector3(0.6, 4.2, 0.25)),
			c + Vector3(0.09, r * 1.28, -0.06)), head)
		return
	# Saç başlığı: alnı açık bırakıp ensenin aşağısına inen, geriye yatık bir kubbe.
	add_mesh(_dome(r * 1.07, 12), hair_mat, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-28.0)), c + Vector3(0.0, 0.012, -0.012)), head)
	add_mesh(sphere(r * 0.98), hair_mat, Transform3D(Basis.IDENTITY, c + Vector3(0.0, -0.035, -0.075)), head)
	# Kâküller.
	for k in [-1.5, -0.5, 0.5, 1.5]:
		var bang := c + Vector3(k * 0.058, r * 0.5 - absf(k) * 0.012, r * 0.82 - absf(k) * 0.02)
		add_mesh(sphere(0.05), hair_mat, Transform3D(Basis(Vector3.BACK, k * 0.25).scaled(Vector3(0.9, 0.78, 0.7)), bang), head)
	match hair:
		Hair.TOP_BUN:
			add_mesh(sphere(0.078), hair_mat, Transform3D(Basis.IDENTITY, c + Vector3(0.0, r * 1.02, -0.05)), head)
			add_mesh(torus(0.035, 0.06), Style.toon(accent_color), Transform3D(Basis.IDENTITY, c + Vector3(0.0, r * 0.93, -0.045)), head)
		Hair.PONYTAIL:
			var tie := c + Vector3(0.0, r * 0.8, -r * 0.62)
			add_mesh(sphere(0.06), hair_mat, Transform3D(Basis.IDENTITY, tie), head)
			add_mesh(torus(0.028, 0.05), Style.toon(accent_color), limb_transform(tie + Vector3(0.0, 0.0, -0.03), tie + Vector3(0.0, -0.01, -0.06)), head)
			var tail_end := c + Vector3(0.0, -r * 0.35, -r * 1.2)
			add_mesh(capsule(0.055, tie.distance_to(tail_end)), hair_mat, limb_transform(tie + Vector3(0.0, -0.02, -0.05), tail_end), head)
		Hair.TWIN_BRAIDS:
			for side in [-1.0, 1.0]:
				var top := c + Vector3(side * r * 0.78, -r * 0.1, -r * 0.3)
				var bottom := c + Vector3(side * r * 0.86, -r * 1.3, -r * 0.02)
				add_mesh(capsule(0.042, top.distance_to(bottom)), hair_mat, limb_transform(top, bottom), head)
				add_mesh(sphere(0.034), Style.toon(accent_color), Transform3D(Basis.IDENTITY, bottom + Vector3(0.0, -0.03, 0.0)), head)
		Hair.SHORT:
			add_mesh(sphere(0.05), hair_mat, Transform3D(Basis.IDENTITY, c + Vector3(0.03, r * 1.03, 0.02)), head)


func _build_beard(head: Node3D, c: Vector3) -> void:
	if beard == Beard.NONE:
		return
	var r := HEAD_RADIUS
	var long := beard == Beard.LONG
	var color := Style.HAIR_WHITE if long else hair_color
	var mat := Style.toon(color, {"brush_strength": 0.18, "brush_scale": 12.0})
	if long:
		add_mesh(sphere(0.11), mat, Transform3D(Basis.IDENTITY.scaled(Vector3(1.05, 1.6, 0.78)), c + Vector3(0.0, -0.19, 0.105)), head)
	else:
		add_mesh(sphere(0.12), mat, Transform3D(Basis.IDENTITY.scaled(Vector3(1.22, 0.85, 0.82)), c + Vector3(0.0, -0.115, 0.095)), head)
	for side in [-1.0, 1.0]:
		add_mesh(capsule(0.017 if long else 0.015, 0.05), mat,
			Transform3D(Basis(Vector3.BACK, side * (PI * 0.5 - 0.5)), c + Vector3(side * 0.034, -0.078, r * 0.91)), head)


## Yumuşak kenarlı kürk halkası (etek ucu gibi).
func _add_trim_ring(parent: Node3D, radius: float, y: float, thickness: float) -> void:
	add_mesh(torus(radius - thickness, radius + thickness), Style.toon(trim_color, {"brush_strength": 0.3, "brush_scale": 18.0}),
		Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.6, 1.0)), Vector3(0.0, y, 0.0)), parent)


## Üst yarım küre (saç başlığı, omuzluk). Altı açık, normaller dışa bakar.
static func _dome(radius: float, rings: int) -> ArrayMesh:
	var profile := PackedVector2Array()
	for i in rings + 1:
		var phi := PI * 0.5 * float(i) / float(rings)
		profile.append(Vector2(cos(phi) * radius, sin(phi) * radius))
	return MeshKit.lathe(profile, 24)
