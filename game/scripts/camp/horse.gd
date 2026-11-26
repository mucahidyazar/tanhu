@tool
class_name Horse
extends Procedural3D
## Bozkır atı. Yerel +Z başın baktığı yöndür.
##
## Oyunda (editör dışında) iskeletli model (res://assets/animals/<model_id>/<model_id>.glb ve ölçüsü <model_id>.json; tools/blender/quadruped_rig.py,
## tarif quadruped_horse.json) binilebilir bir ata kurulur: RideableHorse («Ride» düğümü; Mount satırı «horse»). Bekler, ara ara başını indirip otlar,
## kuyruğunu sallar; oyuncu E ile biner (PlayerController), sürülür, inilince bırakıldığı yerde kalır. Burundan kuyruğa MODEL_LENGTH (modelin ölçüsü).
## Editörde ve iskeletli model yokken eski görünüş: Meshy modeli donuk durur, canlılığı malzeme verir (atw_textured "idle" ayarları; editörde kapalı).
## Model hiç yoksa kodla çizilen sevimli at çıkar; o da kuyruğunu, başını ve kulaklarını eklemleriyle oynatır.

const MODEL_FOLDER := "animals"
const BROWN_MODEL := "horse_brown"
const WHITE_MODEL := "horse_white"
## Burundan kuyruk ucuna uzunluk (metre): sağlam bir bozkır atı (omuz yüksekliği ~1,45 m).
const MODEL_LENGTH := 2.3
## Bu parlaklığın üstündeki tüy rengi beyaz/kır at sayılır (bkz. default_model_for).
const LIGHT_COAT_LUMINANCE := 0.55
## Meshy at modellerinin (iki at aynı duruşta) canlılık ayarları, mesh uzayında (model ~±0,95 birim):
## baş-boyun boyun kökünden döner, kuyruk sağrının arkasından sallanır, gövde yana çok az genişler.
const IDLE_PARAMS := {
	"nod_angle": 0.07,
	"nod_pivot": Vector3(0.0, 0.2, 0.36),
	"nod_region": Vector4(0.38, 0.62, -0.12, 0.14),
	"nod_speed": 0.35,
	"swish_amount": 0.045,
	"swish_region": Vector4(-0.72, -0.86, 0.3, -0.45),
	"swish_speed": 1.25,
	"breath_amount": 0.012,
	"breath_region": Vector2(0.42, -0.05),
	"breath_speed": 1.3,
}

@export var coat_color := Color(0.46, 0.27, 0.15):
	set(value):
		coat_color = value
		queue_rebuild()
@export var mane_color := Color(0.15, 0.09, 0.06):
	set(value):
		mane_color = value
		queue_rebuild()
@export var blaze := true:
	set(value):
		blaze = value
		queue_rebuild()
@export var saddle_color := Color(0.38, 0.2, 0.11):
	set(value):
		saddle_color = value
		queue_rebuild()
@export var blanket_color := Color(0.62, 0.17, 0.13):
	set(value):
		blanket_color = value
		queue_rebuild()
## Meshy model kimliği (assets/animals altında). Boşsa tüy rengine göre seçilir: açık renkli at horse_white,
## koyu renkli at horse_brown.
@export var model_id := "":
	set(value):
		model_id = value
		queue_rebuild()
@export var animate_in_editor := false:
	set(value):
		animate_in_editor = value
		queue_rebuild()

var _rig := {}
var _time := 0.0
var _phase := 0.0
var _model: MeshyProp
var _ride: RideableHorse


func _ready() -> void:
	_phase = float(StableSeed.of(self, 991)) * 0.31
	super._ready()


## Tüy rengine uygun varsayılan model (saf fonksiyon): açık (kır, beyaz) tüy → horse_white, koyu → horse_brown.
static func default_model_for(coat: Color) -> String:
	return WHITE_MODEL if coat.get_luminance() > LIGHT_COAT_LUMINANCE else BROWN_MODEL


## Kullanılacak model kimliği: model_id ya da tüy rengine göre varsayılan.
func resolved_model_id() -> String:
	return model_id if not model_id.is_empty() else default_model_for(coat_color)


## Meshy modeli gösteriliyor mu (false = kodla çizilen yedek at)? Binilebilir at da modeldir.
func uses_model() -> bool:
	return (_ride != null and _ride.uses_model()) or (_model != null and _model.has_model())


## Binilebilir at (oyunda, iskeletli model varken; yoksa null).
func rideable() -> RideableHorse:
	return _ride


## Bu kimliğin iskeletli, ölçülü modeli var mı (binilebilir at kurulur)?
static func has_rigged_model(id: String) -> bool:
	return MeshyProp.exists(MODEL_FOLDER, id) and FileAccess.file_exists(MeshyProp.model_path(MODEL_FOLDER, id).get_basename() + ".json")


func _process(delta: float) -> void:
	if _rig.is_empty() or (Engine.is_editor_hint() and not animate_in_editor):
		return
	_time += delta
	var t := _time + _phase
	# Ara sıra otlanır gibi başını indirir.
	var graze := smoothstep(0.6, 1.0, sin(t * 0.21))
	(_rig["neck"] as Node3D).rotation.x = 0.06 * sin(t * 0.8) + graze * 0.5
	(_rig["tail"] as Node3D).rotation = Vector3(0.15 + sin(t * 1.3) * 0.08, 0.0, sin(t * 2.1) * 0.35)
	for ear in _rig.get("ears", []):
		(ear as Node3D).rotation.z = sin(t * 3.7 + (ear as Node3D).position.x * 20.0) * 0.15 * maxf(sin(t * 0.7), 0.0)


func _build() -> void:
	_rig = {}
	_model = null
	_ride = null
	var id := resolved_model_id()
	if not Engine.is_editor_hint() and Horse.has_rigged_model(id):
		_build_rideable(id)
		if uses_model():
			return
	if MeshyProp.exists(MODEL_FOLDER, id):
		_build_model(id)
	if not uses_model():
		_build_procedural()


## Binilebilir at: iskeletli model, klipler, binek satırı (RideableHorse). Boyu modelin ölçüsüdür (MODEL_LENGTH ile üretildi).
func _build_rideable(id: String) -> void:
	var ride := RideableHorse.new()
	ride.name = "Ride"
	ride.model_path = MeshyProp.model_path(MODEL_FOLDER, id)
	add_generated(ride)
	if ride.uses_model():
		_ride = ride
	else:
		remove_child(ride)
		ride.queue_free()


func _build_model(id: String) -> void:
	var prop := MeshyProp.new()
	prop.name = "HorseModel"
	prop.model_id = id
	prop.folder = MODEL_FOLDER
	prop.size_axis = MeshyProp.SizeAxis.LONGEST
	prop.target_size = MODEL_LENGTH
	prop.sink = 0.015
	prop.ink_strength = 0.35
	prop.brush_strength = 0.03
	# İskeletli modelin ağı metre birimindedir: donuk modelin ayarları (ağ uzayı ≈±0,95) ona uymaz.
	if (not Engine.is_editor_hint() or animate_in_editor) and not Horse.has_rigged_model(id):
		for param in IDLE_PARAMS:
			prop.set_shader_parameter(param, IDLE_PARAMS[param])
	add_generated(prop)
	if prop.has_model():
		_model = prop
	else:
		remove_child(prop)
		prop.queue_free()


# --- Kodla çizilen yedek at --------------------------------------------------------------

func _build_procedural() -> void:
	var coat := Style.toon(coat_color, {"brush_strength": 0.1, "rim_strength": 0.4})
	var mane := Style.toon(mane_color, {"brush_strength": 0.2, "brush_scale": 10.0})
	var hoof := Style.toon(Color(0.16, 0.13, 0.12))
	var dark := Style.toon(Color(0.07, 0.05, 0.05))

	# Gövde.
	add_mesh(capsule(0.37, 0.82), coat, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.98, 0.0)))
	# Bacaklar ve toynaklar.
	for x in [-0.19, 0.19]:
		for z in [-0.42, 0.44]:
			var top := Vector3(x, 0.86, z)
			var bottom := Vector3(x * 1.05, 0.12, z + 0.02)
			add_mesh(capsule(0.085, top.distance_to(bottom)), coat, limb_transform(top, bottom))
			add_mesh(cylinder(0.075, 0.09, 0.12, 12), hoof, Transform3D(Basis.IDENTITY, Vector3(bottom.x, 0.06, bottom.z)))

	# Boyun ve baş (otlanma animasyonu için omuzdan dönen bir eklem).
	var neck := add_pivot("Neck", Transform3D(Basis.IDENTITY, Vector3(0.0, 1.12, 0.5)))
	_rig["neck"] = neck
	var neck_top := Vector3(0.0, 0.58, 0.32)
	add_mesh(capsule(0.19, neck_top.length()), coat, limb_transform(Vector3.ZERO, neck_top), neck)
	var head_from := neck_top + Vector3(0.0, 0.06, 0.0)
	var head_to := neck_top + Vector3(0.0, -0.32, 0.38)
	add_mesh(capsule(0.16, head_from.distance_to(head_to)), coat, limb_transform(head_from, head_to), neck)
	add_mesh(sphere(0.15), Style.toon(coat_color.darkened(0.25)), Transform3D(Basis.IDENTITY.scaled(Vector3(0.95, 0.85, 1.0)), head_to + Vector3(0.0, -0.02, 0.04)), neck)
	if blaze:
		add_mesh(box(Vector3(0.07, 0.02, 0.32)), Style.toon(Color(0.95, 0.93, 0.88)), limb_transform(head_from + Vector3(0.0, 0.0, 0.14), head_to + Vector3(0.0, 0.11, 0.05)), neck)
	# Gözler ve burun delikleri.
	for side in [-1.0, 1.0]:
		add_mesh(sphere(0.032), dark, Transform3D(Basis.IDENTITY, neck_top + Vector3(side * 0.135, -0.04, 0.17)), neck)
		add_mesh(sphere(0.01), Style.unshaded(Color.WHITE), Transform3D(Basis.IDENTITY, neck_top + Vector3(side * 0.155, -0.03, 0.18)), neck)
		add_mesh(sphere(0.02), dark, Transform3D(Basis.IDENTITY, head_to + Vector3(side * 0.06, -0.01, 0.16)), neck)
	# Kulaklar.
	var ears: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var ear := add_pivot("Ear", Transform3D(Basis.IDENTITY, neck_top + Vector3(side * 0.08, 0.15, 0.0)), neck)
		add_mesh(cylinder(0.0, 0.045, 0.16, 8), coat, Transform3D(Basis(Vector3.BACK, -side * 0.25), Vector3(0.0, 0.07, 0.0)), ear)
		ears.append(ear)
	_rig["ears"] = ears
	# Yele: boyun boyunca dizili yumuşak tutamlar + perçem.
	for i in 6:
		var t := float(i) / 5.0
		var p := Vector3(0.0, 0.18, -0.12).lerp(neck_top + Vector3(0.0, 0.14, -0.06), t)
		add_mesh(sphere(0.085 - t * 0.02), mane, Transform3D(Basis.IDENTITY.scaled(Vector3(0.55, 1.0, 1.1)), p), neck)
	add_mesh(sphere(0.06), mane, Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.7, 0.8)), neck_top + Vector3(0.0, 0.12, 0.14)), neck)

	# Kuyruk.
	var tail := add_pivot("Tail", Transform3D(Basis.IDENTITY, Vector3(0.0, 1.12, -0.78)))
	_rig["tail"] = tail
	add_mesh(capsule(0.09, 0.62), mane, limb_transform(Vector3.ZERO, Vector3(0.0, -0.62, -0.16)), tail)
	add_mesh(sphere(0.11), mane, Transform3D(Basis.IDENTITY.scaled(Vector3(0.8, 1.3, 0.8)), Vector3(0.0, -0.66, -0.18)), tail)

	# Eyer ve altındaki desenli örtü.
	add_mesh(box(Vector3(0.82, 0.04, 0.66)), Style.toon(blanket_color, {"stripe_count": 6.0, "stripe_strength": 0.35}),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 1.33, 0.02)))
	add_mesh(sphere(0.25), Style.toon(saddle_color, {"brush_strength": 0.15}),
		Transform3D(Basis.IDENTITY.scaled(Vector3(1.05, 0.34, 1.25)), Vector3(0.0, 1.38, 0.0)))
	add_mesh(box(Vector3(0.04, 0.5, 0.06)), Style.toon(saddle_color.darkened(0.3)), Transform3D(Basis.IDENTITY, Vector3(0.38, 1.12, 0.05)))
	add_mesh(box(Vector3(0.04, 0.5, 0.06)), Style.toon(saddle_color.darkened(0.3)), Transform3D(Basis.IDENTITY, Vector3(-0.38, 1.12, 0.05)))
