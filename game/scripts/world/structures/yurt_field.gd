class_name YurtField
extends Node3D
## Uzak yurtlar (godot.md §4.6; structures.md §13.6; settlement.md §13.3): kapalı yurt (40–220 m) ve uzak kubbe (220 m ötesi) millet başına
## birer MultiMesh'tir: millet başına 1 + 1 çizim (gölgeyle 2 + 2), boy ve ton örneğin verisidir (kök ölçeği dönüşümde; INSTANCE_CUSTOM x
## keçe tonu, y kapı aralığının parıltısı, z yapım yüksekliği (aCut), w yanık (aChar)). Gizlenen örnek (yakındaki tam yurt) sıfır
## ölçekle çizilmez.

const SHADER := preload("res://shaders/yurt_field.gdshader")
const NEAR := 0
const CLOSED := 1
const DOME := 2
const HIDDEN := 3

var snow := 0.0:
	set(value):
		snow = value
		for mmi: MultiMeshInstance3D in _instances():
			mmi.set_instance_shader_parameter(&"snow", snow)
## Millet → {closed: MultiMeshInstance3D, dome: MultiMeshInstance3D, slots: Array[YurtSlot]}.
var _styles: Dictionary = {}
var _glow := 0.0
var _dirty := false


func add_entry(slot: YurtSlot) -> void:
	var sid := str(slot.record.get("style", "hun"))
	if not _styles.has(sid):
		_styles[sid] = {"slots": [], "closed": null, "dome": null}
	var row: Dictionary = _styles[sid]
	(row["slots"] as Array).append(slot)
	slot.field_style = sid
	slot.field_index = (row["slots"] as Array).size() - 1
	_dirty = true
	if is_inside_tree():
		_rebuild.call_deferred()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not _dirty and not _styles.is_empty() and (_styles.values()[0] as Dictionary)["closed"] != null:
		return
	_dirty = false
	for sid: String in _styles:
		var row: Dictionary = _styles[sid]
		var style := YurtStyle.find(sid)
		for level: String in ["closed", "dome"]:
			var mmi: MultiMeshInstance3D = row[level]
			if mmi == null:
				mmi = MultiMeshInstance3D.new()
				mmi.name = "%s_%s" % [sid.to_pascal_case(), level.to_pascal_case()]
				var mat := ShaderMaterial.new()
				mat.shader = SHADER
				mat.set_shader_parameter(&"motif_color", style.motif)
				mat.set_shader_parameter(&"accent_color", style.accent)
				mat.set_shader_parameter(&"cut_ceiling", style.crown_height() + 0.2)
				mmi.material_override = mat
				if level == "dome":
					mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(mmi)
				row[level] = mmi
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = YurtGeometry.mesh(style, "m", YurtGeometry.CLOSED if level == "closed" else YurtGeometry.DOME)
			mm.instance_count = (row["slots"] as Array).size()
			mmi.multimesh = mm
			mmi.set_instance_shader_parameter(&"snow", snow)
		for slot: YurtSlot in row["slots"]:
			_write(slot)


## Kademe (CLOSED, DOME, HIDDEN): örnek yalnız kendi kademesinin MultiMesh'inde görünür.
func set_level(slot: YurtSlot, level: int) -> void:
	if slot.field_level == level:
		return
	slot.field_level = level
	_write(slot)


func set_glow(k: float) -> void:
	if absf(k - _glow) < 0.01:
		return
	_glow = k
	for sid: String in _styles:
		for slot: YurtSlot in (_styles[sid] as Dictionary)["slots"]:
			_write(slot)


func _write(slot: YurtSlot) -> void:
	if not _styles.has(slot.field_style):
		return
	var row: Dictionary = _styles[slot.field_style]
	var closed: MultiMeshInstance3D = row["closed"]
	var dome: MultiMeshInstance3D = row["dome"]
	if closed == null or dome == null or slot.field_index < 0 or slot.field_index >= closed.multimesh.instance_count:
		return
	var sc := YurtStyle.size_scale(str(slot.record.get("size", "m")))
	var xf := global_transform.affine_inverse() * slot.global_transform if slot.is_inside_tree() and is_inside_tree() else slot.transform
	var shown := Transform3D(xf.basis * Basis.from_scale(Vector3(sc.x, sc.y, sc.x)), xf.origin)
	var hidden := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), xf.origin + Vector3(0, -50, 0))
	closed.multimesh.set_instance_transform(slot.field_index, shown if slot.field_level == CLOSED else hidden)
	dome.multimesh.set_instance_transform(slot.field_index, shown if slot.field_level == DOME else hidden)
	var stage := int(slot.record.get("stage", 7))
	var cut := 1.0 if stage >= 7 else clampf(float(stage + 1) / 8.0, 0.05, 1.0)
	var tone := YurtStyle.size_tone(str(slot.record.get("size", "m")))
	var custom := Color(tone, _glow if bool(slot.record.get("hearth", true)) else 0.0, cut, float(slot.record.get("burn", 0.0)))
	closed.multimesh.set_instance_custom_data(slot.field_index, custom)
	dome.multimesh.set_instance_custom_data(slot.field_index, custom)


func _instances() -> Array[MultiMeshInstance3D]:
	var out: Array[MultiMeshInstance3D] = []
	for sid: String in _styles:
		for level: String in ["closed", "dome"]:
			var mmi: Variant = (_styles[sid] as Dictionary)[level]
			if mmi is MultiMeshInstance3D:
				out.append(mmi)
	return out


## Çizim sayısı (millet × 2; sınama).
func draw_count() -> int:
	return _instances().size()
