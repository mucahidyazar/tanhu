class_name YurtSlot
extends Node3D
## Bir yurt kaydının yeri (StructureSet): yerinde ve dönmüş durur; yakındayken çocuğu tam yurttur (StagedYurt), uzakta YurtField'in
## örneğidir. MapWorld'ün places[kimlik] düğümü budur (işaret ve kapı noktası her kademede aynıdır).

var record: Dictionary = {}
var owner_set: StructureSet
var near_yurt: StagedYurt
## YurtField'deki kademe (YurtField.CLOSED, DOME, HIDDEN) ve örnek dizini.
var field_level := YurtField.CLOSED
var field_index := -1
var field_style := ""


func is_near() -> bool:
	return near_yurt != null and is_instance_valid(near_yurt)


func dims() -> Dictionary:
	return YurtGeometry.dims(YurtStyle.find(str(record.get("style", "hun"))), str(record.get("size", "m")))


## Tam yurdu kurar (bir kez; uzaklaşınca bırakılır).
func make_near() -> void:
	if is_near():
		return
	var y := StructureKit.make_yurt(record)
	y.name = "Yurt"
	if owner_set:
		y.ground = owner_set.ground
		y.snow = owner_set.snow
		y.room_focus = owner_set.focus
	near_yurt = y
	add_child(y)


func make_far() -> void:
	if not is_near():
		return
	remove_child(near_yurt)
	near_yurt.queue_free()
	near_yurt = null


## Kapının önü (dünya).
func door_point(pad_out: float = 0.8) -> Vector3:
	var r: float = dims().get("radius", 3.3)
	return global_position + global_transform.basis.z.normalized() * (r + pad_out)
