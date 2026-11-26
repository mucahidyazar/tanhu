class_name StructureRoom
extends Node
## Yurt dışı yapının odası (K98 diyoraması; Kışlak'ın ahırı): odak (room_focus; yoksa takip kamerasının hedefi: oyuncu, binilen atla
## birlikte) yapının yerel x, z düzlemindeki rect'in içine girince yapının cut'ı 0,35 sn'de 1 olur: çatı kalkar, kameraya bakan yan alçalır
## (StagedYurt'un kesitiyle aynı gölgelendirici: staged_body cut_*; ölçüleri yapının malzemesindedir, StructureKit ahıra ayrı anahtarla
## kurar). İçerideki oyuncu ve bölmelerdeki atlar yukarıdan görünür; çıkınca çatı geri gelir. Kesitliyken kit gölge vermez, kesilmemiş
## ikizi yalnız gölge verir (çatı içeride de güneşi keser). Yapı bitmemişse (çatı aşaması yoksa) kesit açılmaz.
##   var room := StructureRoom.new()
##   room.rect = Rect2(-6.7, -3.4, 13.4, 7.8)   # yapının yerel düzlemi (x, z)
##   staged_structure.add_child(room)

const CUT_S := 0.35
const CHECK_S := 0.1

## Odanın yerel dikdörtgeni (x, z; yapının dönüşümüyle).
var rect := Rect2()
## Odak (yoksa görünen kameranın üst düğümünün «target»ı: FollowCamera'nın oyuncusu).
var room_focus: Node3D
var inside := false

var _target := 0.0
var _check := 0.0
var _twin: MeshInstance3D


func _process(delta: float) -> void:
	var s := get_parent() as StagedStructure
	if s == null or Engine.is_editor_hint():
		return
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_S
		var f := _focus()
		var now := false
		if f and is_instance_valid(f) and s.stage >= StructureCatalog.stages_of(s.kind):
			var local := s.global_transform.affine_inverse() * f.global_position
			now = rect.has_point(Vector2(local.x, local.z))
		if now != inside:
			inside = now
			_target = 1.0 if inside else 0.0
	if not is_equal_approx(s.cut, _target):
		s.cut = move_toward(s.cut, _target, delta / CUT_S)
		_sync_twin(s)
		s.refresh()


func _focus() -> Node3D:
	if is_instance_valid(room_focus):
		return room_focus
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var p := cam.get_parent() if cam else null
	var t: Variant = p.get(&"target") if p else null
	return t as Node3D if t is Node3D else null


## Kesitliyken kitin gölgesi ikizden (kesilmemiş, yalnız gölge); ikiz yapının parçası değildir (tekdüzenleri varsayılandır: tam ve kesitsiz).
func _sync_twin(s: StagedStructure) -> void:
	if s.mesh_instance == null or not is_instance_valid(s.mesh_instance):
		return
	var cutting := s.cut > 0.01
	if cutting and _twin == null and s.casts_shadow:
		_twin = MeshInstance3D.new()
		_twin.name = "ShadowTwin"
		StagedStructure.dress(_twin, s.mesh, s.material_key, s.material_params)
		_twin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		_twin.position = s.mesh_instance.position
		s.add_child(_twin)
	if _twin:
		_twin.visible = cutting
	if s.casts_shadow:
		s.mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if cutting else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
