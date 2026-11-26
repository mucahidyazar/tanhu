class_name CrowdField
extends Node3D
## Kalabalığın kademeli çizimi (Yol Haritası crowd-tiers; army.md §7.1–§7.4, godot.md §4.5): kişiler kademe kademe çizilir, kademe ekran
## pikseliyle seçilir (CrowdPlan.tier_px, select_tiers: Godot kamerasının dikey görüş açısı ve pencerenin yüksekliğiyle; T0 ≥80 px,
## T1 ve T2 ≥28 px, ±%15 gecikme payı, 4 Hz, kare başına ≤8 takas):
##   T0  tam kişi (CharacterAvatar): bu düğüm çizmez, kademeyi bildirir; tam kişi yuvalarını katman doldurur (FolkLayer; adlı önce)
##   T1  kukla (CrowdPuppet DETAIL_T1, tek MultiMesh: tek çizim; en yakın 24'ünün gölgesi ayrı, yalnız gölge düşüren örnekler)
##   T2  kaba kukla (DETAIL_T2, tek çizim, gölgesiz)
##   T3  kart (CrowdCards.palette_card_shader; atlas açılışta pişer: CrowdCards.bake_puppet_atlas), tek çizim, gölgesiz
## T1 ve T2'nin ayağının altında temas lekesi (CrowdCards.blob_shader, tek çizim). Renkler kişinin görünüşündendir (Folk.palette → palet
## dokusu, CrowdPuppet.palette_image): kişi başına sekiz piksel.
##
## Hareket: kişinin planı (yer, yön, duruş, varlık) her kare verilir (set_plan; Schedule ve CrowdPlan.program_pose); gerçek yeri plana
## yürüyerek yetişir: plan yürürken kendi hızıyla, gerideyse hurry katıyla, en çok speed_cap ile (oyuncunun koşusu; K105, PaceLimit);
## 60 m ötesinde ve kadraj dışında yer sıçrar (snap_m; act1.md §5). Yürüyüş evresi yürünen yoldan çıkar (adım kaymaz). Gerçek hız
## peak_speed'e yazılır (sınama).
##   var field := CrowdField.new()
##   field.setup(looks, terrain_shape)          # looks: Folk görünüşleri (kişi başına); terrain_shape: height_at taşıyan
##   add_child(field)
##   field.set_plan(i, Vector2(x, z), yaw, CrowdPlan.State.STAND, 1.0)   # her kare, her kişi
##   field.focus = player.global_position        # sıçrama kuralının merkezi

const STRIDE := CrowdPuppet.STRIDE
## Kademe seçiminin sıklığı (sn) ve kare başına en çok takas.
const TIER_PERIOD := 0.25
const MAX_SWAPS := 8
## Tavanlar (army.md §7.1; K63 kalabalık satırı): T0 yuvaları katmanın verdiği, T1 96, T2 300, T3 12.000.
const CAP_T1 := 96
const CAP_T2 := 300
const CAP_T3 := 12000
## T1'in gölge düşüren en yakın kişileri.
const SHADOW_NEAREST := 24
## Kişinin yeri plana bu kadar yakınsa varmış sayılır (m); dönüş hızı (rad/sn).
const ARRIVE_EPS := 0.04
const TURN_RATE := 3.2
## Yükseklik önbelleğinin yenilendiği yürüyüş (m).
const HEIGHT_STEP := 0.6
## Örnek başına sayılar: kuklada 12 dönüşüm + 4 özel; kartta 12 + 4; lekede 12 + 4 renk.
const PUPPET_FLOATS := 16
const BLOB_FLOATS := 16
const BLOB_SIZE := Vector2(0.9, 0.7)
const BLOB_LIFT := 0.035
## Kişinin boyu (m) varsayılanı; kart ölçeği.
const DEFAULT_HEIGHT := 1.7

## Kişilerin görünüşleri (Folk) ve zemin (height_at).
var looks: Array = []
var shape: RefCounted
## Sıçrama kuralı: merkezi (oyuncu), uzaklık (m); yetişme katı ve en yüksek hız (m/sn), plan yürürken hızı (m/sn).
var focus := Vector3.INF
var snap_m := 60.0
var hurry := 1.5
var speed_cap := PaceLimit.ADULT_RUN
var walk_speed := 1.4
## T0 yuvası sayısı (katman: 16 − tam kişi kadrosu); 0 ise tam kişiye yükselme yok.
var t0_slots := 0
## Kişinin tam kişi önceliği (adlı 2, nöbetçi 1, öbür 0) ve tam kişi olabilir mi (modeli var).
var priority := PackedInt32Array()
var can_full := PackedByteArray()
## Ölçülen en yüksek gerçek hız (m/sn; yürüyenlerin).
var peak_speed := 0.0
## Kamera (yoksa görüntü alanının kamerası) ve kademe ölçüsünün pencere yüksekliği (px; 0: görüntü alanınınki).
var camera: Camera3D
var height_px := 0.0
## Geliştirme: bütün kişiler bu kademede (T1, T2 ya da T3; NONE: seçim pikselle). Kademelerin kareleri ve ölçümü içindir.
var force_tier := CrowdPlan.NONE

var _n := 0
var _plan_xz := PackedVector2Array()
var _plan_yaw := PackedFloat32Array()
var _plan_state := PackedByteArray()
var _plan_presence := PackedFloat32Array()
var _xz := PackedVector2Array()
var _yaw := PackedFloat32Array()
var _y := PackedFloat32Array()
var _y_at := PackedVector2Array()
var _phase := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _state := PackedByteArray()
var _presence := PackedFloat32Array()
var _variant := PackedByteArray()
var _hscale := PackedFloat32Array()
var _build := PackedFloat32Array()
var _tier := PackedByteArray()
var _dirty := PackedByteArray()
var _snapped := true
var _tier_left := 0.0
## Kademenin yuvaları: kademe → [kişi, ...] ve kişi → yuva.
var _slots: Dictionary = {}
var _slot_of: Dictionary = {}
var _bufs: Dictionary = {}
var _mm: Dictionary = {}
var _shadow: MultiMeshInstance3D
var _shadow_buf := PackedFloat32Array()
var _blobs: MultiMeshInstance3D
var _blob_buf := PackedFloat32Array()
var _cards_mat: ShaderMaterial
var _palette: ImageTexture
var _atlas_pending := false


## Kurar (ağaca eklemeden önce ya da sonra): görünüşler ve zemin. Kişi başına yer, yön ve duruş set_plan'la gelir; ilk yazışta herkes
## planının yerindedir.
func setup(p_looks: Array, p_shape: RefCounted = null) -> void:
	looks = p_looks
	shape = p_shape
	_n = looks.size()
	# Paketli diziler değer türüdür: her biri kendi adıyla boyutlanır.
	_plan_xz.resize(_n)
	_xz.resize(_n)
	_y_at.resize(_n)
	_plan_yaw.resize(_n)
	_plan_presence.resize(_n)
	_yaw.resize(_n)
	_y.resize(_n)
	_phase.resize(_n)
	_speed.resize(_n)
	_presence.resize(_n)
	_hscale.resize(_n)
	_build.resize(_n)
	_plan_state.resize(_n)
	_state.resize(_n)
	_variant.resize(_n)
	_tier.resize(_n)
	_dirty.resize(_n)
	priority.resize(_n)
	can_full.resize(_n)
	for i in _n:
		var look: Dictionary = looks[i]
		_variant[i] = Folk.puppet_variant(look)
		_hscale[i] = float(look.get("height_m", DEFAULT_HEIGHT)) / CrowdPuppet.BODY_HEIGHT
		_build[i] = float(look.get("build", 1.0))
		_tier[i] = CrowdPlan.NONE
		_plan_state[i] = CrowdPlan.State.ABSENT
		_state[i] = CrowdPlan.State.ABSENT
		_y_at[i] = Vector2.INF
		_phase[i] = fposmod(float(i) * 0.37, 1.0)
		can_full[i] = 1 if Folk.has_full(look) else 0
		priority[i] = 1 if str(look.get("role", "")) == "guard" else 0
	_snapped = true
	_build_nodes()


## Kişi sayısı.
func size() -> int:
	return _n


## Kişinin planı (her kare): yer (x, z), yön (atan2(x, z)), duruş (CrowdPlan.State), varlık (0..1; kapıda belirir).
func set_plan(i: int, xz: Vector2, yaw: float, state: int, presence: float = 1.0) -> void:
	_plan_xz[i] = xz
	_plan_yaw[i] = yaw
	_plan_state[i] = state
	_plan_presence[i] = presence


## Sonraki karede herkes planının yerine oturur (sahne atlanınca, dünya kurulunca).
func snap() -> void:
	_snapped = true


## Kişinin kademesi (CrowdPlan.T0…T3, NONE).
func tier_of(i: int) -> int:
	return _tier[i] if i >= 0 and i < _n else CrowdPlan.NONE


## Kişinin gerçek yeri (x, z) ve yönü (sınama ve tam kişi yuvası).
func position_of(i: int) -> Vector3:
	return Vector3(_xz[i].x, _y[i], _xz[i].y)


func yaw_of(i: int) -> float:
	return _yaw[i]


## Kişinin görünen hâli (CrowdPlan.State) ve hızı (m/sn).
func state_of(i: int) -> int:
	return _state[i]


func speed_of(i: int) -> float:
	return _speed[i]


## Kademelerin sayıları: {T0, T1, T2, T3, NONE}.
func counts() -> Dictionary:
	var out := {"T0": 0, "T1": 0, "T2": 0, "T3": 0, "NONE": 0}
	for i in _n:
		match int(_tier[i]):
			CrowdPlan.T0:
				out["T0"] += 1
			CrowdPlan.T1:
				out["T1"] += 1
			CrowdPlan.T2:
				out["T2"] += 1
			CrowdPlan.T3:
				out["T3"] += 1
			_:
				out["NONE"] += 1
	return out


## Kademenin çizim düğümü (sınama ve bütçe): T1, T2, T3; «shadow» T1'in gölgesi, «blobs» temas lekesi.
func node_of(kind: Variant) -> MultiMeshInstance3D:
	if str(kind) == "shadow":
		return _shadow
	if str(kind) == "blobs":
		return _blobs
	return _mm.get(int(kind))


## Kademenin yuvasındaki kişi ve tamponundaki CUSTOM (sınama; başsızda MultiMesh örnek verisini tutmaz).
func slot_member(tier: int, slot: int) -> int:
	var list: PackedInt32Array = _slots.get(tier, PackedInt32Array())
	return list[slot] if slot >= 0 and slot < list.size() else -1


func slot_custom(tier: int, slot: int) -> Color:
	var buf: PackedFloat32Array = _bufs.get(tier, PackedFloat32Array())
	var o := slot * PUPPET_FLOATS
	return Color(buf[o + 12], buf[o + 13], buf[o + 14], buf[o + 15]) if o + 15 < buf.size() else Color()


## Kart atlası pişti mi (başsızda hayır)?
func has_card_atlas() -> bool:
	return not CrowdCards.puppet_atlas().is_empty()


## Ağaçtaki alan sayısı: sonuncusu çıkınca kuklanın ve kartın önbellekleri bırakılır (dünya değişiminde ve çıkışta çizim kaynağı
## kalmasın; godot.md §4.3 madde 5).
static var _alive := 0


func _enter_tree() -> void:
	_alive += 1


func _exit_tree() -> void:
	_alive = maxi(_alive - 1, 0)
	if _alive == 0:
		CrowdPuppet.release_cache()
		CrowdCards.release_puppet_atlas()


func _ready() -> void:
	if _n > 0 and _palette == null:
		_build_nodes()
	_bake_atlas()


func _process(delta: float) -> void:
	tick(delta)


## Bir adım (her kare; sınamalar doğrudan çağırır): gerçek yer plana yetişir, kademe 4 Hz'de seçilir, değişen kişiler yazılır.
func tick(delta: float) -> void:
	if _n == 0:
		return
	var cam := camera if camera and is_instance_valid(camera) else get_viewport().get_camera_3d() if is_inside_tree() else null
	_move(delta, cam)
	_tier_left -= delta
	var selected := false
	if _tier_left <= 0.0 or _snapped:
		_tier_left = TIER_PERIOD
		_select(cam, _snapped)
		selected = true
	_snapped = false
	_write(selected)


# --- Hareket ------------------------------------------------------------------------------------------------------------------

func _move(delta: float, cam: Camera3D) -> void:
	var cap := minf(walk_speed * hurry, speed_cap)
	var turn := TURN_RATE * maxf(delta, 0.0)
	for i in _n:
		var target := _plan_xz[i]
		var here := _xz[i]
		var plan_state := int(_plan_state[i])
		var was := int(_state[i])
		if _snapped or (plan_state == CrowdPlan.State.ABSENT and _plan_presence[i] <= 0.0 and was == CrowdPlan.State.ABSENT):
			# İlk yazışta ve görünmez kalan kişide yer plandır.
			here = target
		var d := target - here
		var dist := d.length()
		var moved := 0.0
		if dist > ARRIVE_EPS and not _snapped:
			if _far_and_hidden(here, target, cam):
				here = target
			else:
				var step := cap * delta
				if dist <= step:
					moved = dist
					here = target
				else:
					moved = step
					here += d / dist * step
		elif _snapped:
			here = target
		var speed := moved / delta if delta > 0.0 else 0.0
		_speed[i] = speed
		if speed > peak_speed and delta > 0.0 and moved > 0.0:
			peak_speed = speed
		var walking := moved > 0.0001 or (plan_state == CrowdPlan.State.WALK and dist > ARRIVE_EPS)
		var shown := plan_state
		if walking:
			shown = CrowdPlan.State.WALK
		elif plan_state == CrowdPlan.State.WALK:
			shown = CrowdPlan.State.STAND
		var yaw := _yaw[i]
		if moved > 0.0005:
			var want := atan2(d.x, d.y)
			yaw = want if _snapped else yaw + clampf(angle_difference(yaw, want), -turn * 1.5, turn * 1.5)
		else:
			var want_still := _plan_yaw[i]
			yaw = want_still if _snapped else yaw + clampf(angle_difference(yaw, want_still), -turn, turn)
		var stride := STRIDE if speed < 2.6 else CrowdPuppet.RUN_STRIDE
		if moved > 0.0:
			_phase[i] = fposmod(_phase[i] + moved / stride, 1.0)
		var presence := _plan_presence[i] if shown != CrowdPlan.State.ABSENT else 0.0
		if here != _xz[i] or yaw != _yaw[i] or shown != was or absf(presence - _presence[i]) > 0.001 or walking:
			_dirty[i] = 1
		_xz[i] = here
		_yaw[i] = yaw
		_state[i] = shown
		_presence[i] = presence
		if _y_at[i] == Vector2.INF or _y_at[i].distance_squared_to(here) > HEIGHT_STEP * HEIGHT_STEP or _snapped:
			_y[i] = float(shape.call(&"height_at", here.x, here.y)) if shape else 0.0
			_y_at[i] = here


## Sıçrama kuralı (act1.md §5): iki uç da odaktan snap_m ötede ve kadraj dışında.
func _far_and_hidden(a: Vector2, b: Vector2, cam: Camera3D) -> bool:
	if focus == Vector3.INF:
		return false
	var f := Vector2(focus.x, focus.z)
	if a.distance_to(f) <= snap_m or b.distance_to(f) <= snap_m:
		return false
	if cam == null:
		return true
	for p: Vector2 in [a, b]:
		var y := float(shape.call(&"height_at", p.x, p.y)) if shape else 0.0
		if cam.is_position_in_frustum(Vector3(p.x, y + 1.0, p.y)):
			return false
	return true


# --- Kademe -------------------------------------------------------------------------------------------------------------------

func _select(cam: Camera3D, snap_all: bool) -> void:
	var px := PackedFloat32Array()
	px.resize(_n)
	var visible := PackedByteArray()
	visible.resize(_n)
	var present := PackedByteArray()
	present.resize(_n)
	var fov := cam.fov if cam else FollowCamera.DEFAULT_FOV
	var h := height_px if height_px > 0.0 else (get_viewport().get_visible_rect().size.y if is_inside_tree() else 1080.0)
	var eye := cam.global_position if cam else (focus if focus != Vector3.INF else Vector3.ZERO)
	for i in _n:
		present[i] = 1 if _state[i] != CrowdPlan.State.ABSENT and _presence[i] > 0.0 else 0
		var p := Vector3(_xz[i].x, _y[i] + 0.9, _xz[i].y)
		px[i] = CrowdPlan.tier_px(eye.distance_to(p), fov, h)
		visible[i] = 1 if cam == null or cam.is_position_in_frustum(p) else 0
	if force_tier != CrowdPlan.NONE:
		for i in _n:
			px[i] = 1000.0 if force_tier == CrowdPlan.T1 or force_tier == CrowdPlan.T2 else 1.0
	var caps := [t0_slots, CAP_T1, CAP_T2, CAP_T3]
	if force_tier == CrowdPlan.T2:
		caps = [0, 0, CAP_T2, CAP_T3]
	elif force_tier != CrowdPlan.NONE:
		caps[0] = 0
	var tiers := CrowdPlan.select_tiers(px, visible, priority, can_full, _tier, present, caps, MAX_SWAPS, snap_all or force_tier != CrowdPlan.NONE)
	for i in _n:
		if tiers[i] != _tier[i]:
			_move_to_tier(i, int(tiers[i]))


func _move_to_tier(i: int, tier: int) -> void:
	var old := int(_tier[i])
	if _slots.has(old):
		var list: PackedInt32Array = _slots[old]
		var slot := int(_slot_of.get(i, -1))
		if slot >= 0:
			var last := list.size() - 1
			var moved_member := list[last]
			list[slot] = moved_member
			_slot_of[moved_member] = slot
			list.resize(last)
			_slots[old] = list
			if moved_member != i:
				_copy_slot(old, last, slot)
				_dirty[moved_member] = 1
		_slot_of.erase(i)
	_tier[i] = tier
	if _slots.has(tier):
		var list: PackedInt32Array = _slots[tier]
		_slot_of[i] = list.size()
		list.append(i)
		_slots[tier] = list
	_dirty[i] = 1


func _copy_slot(tier: int, from: int, to: int) -> void:
	var buf: PackedFloat32Array = _bufs[tier]
	for k in PUPPET_FLOATS:
		buf[to * PUPPET_FLOATS + k] = buf[from * PUPPET_FLOATS + k]
	_bufs[tier] = buf


# --- Çizim --------------------------------------------------------------------------------------------------------------------

func _build_nodes() -> void:
	for child in get_children():
		child.queue_free()
	_mm.clear()
	_slots.clear()
	_slot_of.clear()
	_bufs.clear()
	var pals: Array = []
	for look: Dictionary in looks:
		pals.append(Folk.palette(look))
	_palette = ImageTexture.create_from_image(CrowdPuppet.palette_image(pals))
	var box := _bounds()
	var t1_mat := CrowdPuppet.material(_palette)
	var t2_mat := CrowdPuppet.material(_palette, "", true)
	_mm[CrowdPlan.T1] = _multimesh("T1", CrowdPuppet.mesh(CrowdPuppet.DETAIL_T1), t1_mat, mini(_n, CAP_T1), box, false)
	_mm[CrowdPlan.T2] = _multimesh("T2", CrowdPuppet.mesh(CrowdPuppet.DETAIL_T2), t2_mat, mini(_n, CAP_T2), box, false)
	_cards_mat = CrowdCards.palette_card_material(_palette, CrowdCards.puppet_atlas())
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_mm[CrowdPlan.T3] = _multimesh("T3", quad, _cards_mat, mini(_n, CAP_T3), box, false)
	_shadow = _multimesh("T1Shadow", CrowdPuppet.mesh(CrowdPuppet.DETAIL_T1), t1_mat, mini(_n, SHADOW_NEAREST), box, true)
	var blob_mat := ShaderMaterial.new()
	blob_mat.shader = CrowdCards.blob_shader()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = plane
	mm.instance_count = mini(_n, CAP_T1 + CAP_T2)
	mm.visible_instance_count = 0
	_blobs = MultiMeshInstance3D.new()
	_blobs.name = "Blobs"
	_blobs.multimesh = mm
	_blobs.material_override = blob_mat
	_blobs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_blobs.custom_aabb = box
	add_child(_blobs)
	_blob_buf.resize(mm.instance_count * BLOB_FLOATS)
	for tier in [CrowdPlan.T1, CrowdPlan.T2, CrowdPlan.T3]:
		_slots[tier] = PackedInt32Array()
		var b := PackedFloat32Array()
		b.resize((_mm[tier] as MultiMeshInstance3D).multimesh.instance_count * PUPPET_FLOATS)
		_bufs[tier] = b
	_shadow_buf.resize(_shadow.multimesh.instance_count * PUPPET_FLOATS)
	for i in _n:
		if _tier[i] != CrowdPlan.NONE and _tier[i] != CrowdPlan.T0:
			var t := int(_tier[i])
			_tier[i] = CrowdPlan.NONE
			_move_to_tier(i, t)


func _multimesh(node_name: String, mesh: Mesh, mat: Material, count: int, box: AABB, shadow_only: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = maxi(count, 1)
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.name = node_name
	mi.multimesh = mm
	mi.material_override = mat
	mi.custom_aabb = box
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if shadow_only else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## Kişilerin yürüyeceği bütün alanı kapsayan kutu (planların ve görünüşlerin bilinmediği kurulumda geniş tutulur; MultiMesh örnekleri
## kendi kutusunu bilmez, kişiler haritanın her yerinde olabilir).
func _bounds() -> AABB:
	return AABB(Vector3(-2000.0, -200.0, -2000.0), Vector3(4000.0, 600.0, 4000.0))


## Kart atlasını pişirir (bir kez; başsızda pişmez): bitince kartın malzemesi atlası alır.
func _bake_atlas() -> void:
	if _atlas_pending or has_card_atlas() or not is_inside_tree():
		if has_card_atlas() and _cards_mat:
			_apply_atlas(CrowdCards.puppet_atlas())
		return
	_atlas_pending = true
	var atlas: Dictionary = await CrowdCards.bake_puppet_atlas(self)
	_atlas_pending = false
	if not atlas.is_empty() and is_instance_valid(self):
		_apply_atlas(atlas)


func _apply_atlas(atlas: Dictionary) -> void:
	_cards_mat.set_shader_parameter(&"mask_atlas", atlas["mask"])
	_cards_mat.set_shader_parameter(&"normal_atlas", atlas["normal"])


## Değişen kişileri yuvalarına yazar; yazılan kademenin tamponu ekran kartına bir kez gider. T1'in gölgesi en yakın 24'ün, leke T1 ve T2'nin.
func _write(selected: bool = false) -> void:
	var touched := {}
	for tier in [CrowdPlan.T1, CrowdPlan.T2, CrowdPlan.T3]:
		var list: PackedInt32Array = _slots[tier]
		var buf: PackedFloat32Array = _bufs[tier]
		var any := false
		for slot in list.size():
			var i := list[slot]
			if _dirty[i] == 0:
				continue
			if tier == CrowdPlan.T3:
				_put_card(buf, slot * PUPPET_FLOATS, i)
			else:
				_put_puppet(buf, slot * PUPPET_FLOATS, i)
			any = true
		if any or (_mm[tier] as MultiMeshInstance3D).multimesh.visible_instance_count != list.size():
			_bufs[tier] = buf
			var mm := (_mm[tier] as MultiMeshInstance3D).multimesh
			mm.buffer = buf
			mm.visible_instance_count = list.size()
			touched[tier] = true
	for i in _n:
		_dirty[i] = 0
	if selected or touched.has(CrowdPlan.T1) or touched.has(CrowdPlan.T2):
		_write_shadow_and_blobs()


func _write_shadow_and_blobs() -> void:
	var t1: PackedInt32Array = _slots[CrowdPlan.T1]
	var t2: PackedInt32Array = _slots[CrowdPlan.T2]
	var t1_buf: PackedFloat32Array = _bufs[CrowdPlan.T1]
	# Gölge: T1'in yuvaları kadrajda ve uzaklıkta zaten sıralı değildir; ilk SHADOW_NEAREST yuva odağa en yakın olanlardır (seçim
	# en yakından doldurur, yuva sırası kayabilir): odağa göre yeniden seçilir.
	var order: Array[int] = []
	for slot in t1.size():
		order.append(slot)
	if order.size() > SHADOW_NEAREST and focus != Vector3.INF:
		var f := Vector2(focus.x, focus.z)
		order.sort_custom(func(a: int, b: int) -> bool: return _xz[t1[a]].distance_squared_to(f) < _xz[t1[b]].distance_squared_to(f))
	var n_shadow := mini(order.size(), _shadow.multimesh.instance_count)
	for k in n_shadow:
		var src := order[k] * PUPPET_FLOATS
		for f in PUPPET_FLOATS:
			_shadow_buf[k * PUPPET_FLOATS + f] = t1_buf[src + f]
	_shadow.multimesh.buffer = _shadow_buf
	_shadow.multimesh.visible_instance_count = n_shadow
	var k := 0
	for list: PackedInt32Array in [t1, t2]:
		for i in list:
			if k >= _blobs.multimesh.instance_count:
				break
			_put_blob(k * BLOB_FLOATS, i)
			k += 1
	_blobs.multimesh.buffer = _blob_buf
	_blobs.multimesh.visible_instance_count = k


func _put_puppet(buf: PackedFloat32Array, o: int, i: int) -> void:
	var at := Vector3(_xz[i].x, _y[i], _xz[i].y)
	var xf := CrowdPuppet.instance_transform(at, _yaw[i], _hscale[i], _build[i])
	_put_xform(buf, o, xf)
	var gait := 0.0
	match int(_state[i]):
		CrowdPlan.State.WALK:
			gait = clampf(_speed[i] / maxf(walk_speed, 0.1), 0.15, 1.7)
		CrowdPlan.State.SIT:
			gait = CrowdPuppet.POSE_SIT
		CrowdPlan.State.WORK:
			gait = CrowdPuppet.POSE_WORK
	var c := CrowdPuppet.custom(_phase[i], gait, i, _variant[i], _presence[i])
	buf[o + 12] = c.r
	buf[o + 13] = c.g
	buf[o + 14] = c.b
	buf[o + 15] = c.a


func _put_card(buf: PackedFloat32Array, o: int, i: int) -> void:
	var at := Vector3(_xz[i].x, _y[i], _xz[i].y)
	var s := _hscale[i]
	_put_xform(buf, o, Transform3D(Basis.from_scale(Vector3(s, s, s)), at))
	var frame := CrowdCards.walk_frame(_phase[i])
	match int(_state[i]):
		CrowdPlan.State.STAND, CrowdPlan.State.WORK:
			frame = CrowdCards.PUPPET_FRAME_STAND
		CrowdPlan.State.SIT:
			frame = CrowdCards.PUPPET_FRAME_SIT
	buf[o + 12] = _yaw[i]
	buf[o + 13] = float(CrowdCards.puppet_cell(_variant[i], frame))
	buf[o + 14] = float(i)
	buf[o + 15] = _presence[i]


func _put_blob(o: int, i: int) -> void:
	var at := Vector3(_xz[i].x, _y[i] + BLOB_LIFT, _xz[i].y)
	var s := _hscale[i]
	var basis := Basis(Vector3.UP, _yaw[i]) * Basis.from_scale(Vector3(BLOB_SIZE.x * s, 1.0, BLOB_SIZE.y * s))
	_blob_buf[o + 0] = basis.x.x
	_blob_buf[o + 1] = basis.y.x
	_blob_buf[o + 2] = basis.z.x
	_blob_buf[o + 3] = at.x
	_blob_buf[o + 4] = basis.x.y
	_blob_buf[o + 5] = basis.y.y
	_blob_buf[o + 6] = basis.z.y
	_blob_buf[o + 7] = at.y
	_blob_buf[o + 8] = basis.x.z
	_blob_buf[o + 9] = basis.y.z
	_blob_buf[o + 10] = basis.z.z
	_blob_buf[o + 11] = at.z
	_blob_buf[o + 12] = 0.0
	_blob_buf[o + 13] = 0.0
	_blob_buf[o + 14] = 0.0
	_blob_buf[o + 15] = _presence[i] * (0.0 if int(_state[i]) == CrowdPlan.State.SIT else 1.0)


static func _put_xform(buf: PackedFloat32Array, o: int, xf: Transform3D) -> void:
	var b := xf.basis
	buf[o + 0] = b.x.x
	buf[o + 1] = b.y.x
	buf[o + 2] = b.z.x
	buf[o + 3] = xf.origin.x
	buf[o + 4] = b.x.y
	buf[o + 5] = b.y.y
	buf[o + 6] = b.z.y
	buf[o + 7] = xf.origin.y
	buf[o + 8] = b.x.z
	buf[o + 9] = b.y.z
	buf[o + 10] = b.z.z
	buf[o + 11] = xf.origin.z
