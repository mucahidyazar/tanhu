class_name StableSeed
extends RefCounted
## Kararlı tohum: düğümün adı, üst düğümünün adı ve konumundan türer, nesne kimliğinden bağımsızdır.
## get_instance_id() betik değiştikçe kayar (yüklemede oluşan nesne sayısı değişir); ateşin titremesi ve
## atların evresi o yüzden koşudan koşuya değişiyor, menü referans karesi tutmuyordu (W10 ölçümü, %2,85).


## [0, modulo) aralığında tamsayı; aynı ad ve konumda her koşuda aynı.
static func of(node: Node3D, modulo: int) -> int:
	var p: Vector3 = node.global_position if node.is_inside_tree() else node.position
	var parent_name := String(node.get_parent().name) if node.get_parent() != null else ""
	var key := "%s/%s|%d|%d|%d" % [parent_name, String(node.name), roundi(p.x * 10.0), roundi(p.y * 10.0), roundi(p.z * 10.0)]
	return absi(key.hash()) % maxi(modulo, 1)
