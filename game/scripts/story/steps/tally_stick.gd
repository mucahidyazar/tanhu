class_name TallyStick
extends Node3D
## Hereka'nın çetelesi (kodla çizilmiş çubuk; K110, «Ebenin Çetelesi»): bir karış söğüt çubuğu, bir yanında yedi çentik (bu yıl Ebe Obası'nda
## doğanlar). Hereka uzatırken elinde görünür, sonra Mete'nin heybesine girer (TallyErrand; Envanter'deki simgesi HudItemIcon «tally», yedi
## çentik). Çentikler tek MultiMesh'tir.
##   var stick := TallyStick.new(); stick.notches = 7; hand.add_child(stick); stick.build()

const LENGTH := 0.26
const WIDTH := 0.026
const DEPTH := 0.02

var notches := TallyErrand.NOTCHES


## Çubuğu ve çentiklerini kurar (bir kez).
func build() -> void:
	if get_child_count() > 0:
		return
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.72, 0.58, 0.4)
	wood.roughness = 0.85
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(WIDTH, LENGTH, DEPTH)
	body.mesh = box
	body.material_override = wood
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
	var cut := BoxMesh.new()
	cut.size = Vector3(WIDTH * 0.62, 0.006, DEPTH * 0.5)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cut
	mm.instance_count = notches
	for i in notches:
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.FORWARD, 0.25), Vector3(-WIDTH * 0.2, notch_y(i, notches), DEPTH * 0.32)))
	var marks := MultiMeshInstance3D.new()
	marks.name = "Notches"
	marks.multimesh = mm
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.24, 0.16, 0.1)
	marks.material_override = dark
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marks)


## Çentiğin çubuk boyundaki yeri (saf; m, ortadan): uçlardan pay bırakarak eşit aralık.
static func notch_y(i: int, count: int) -> float:
	var span := LENGTH * 0.72
	if count <= 1:
		return 0.0
	return -span * 0.5 + span * float(i) / float(count - 1)


## Çentik sayısı (kurulu çubuktan; sınama).
func notch_count() -> int:
	var marks := get_node_or_null(^"Notches") as MultiMeshInstance3D
	return marks.multimesh.instance_count if marks and marks.multimesh else 0
