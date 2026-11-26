class_name HearthCold
extends Node3D
## Menü ateşinin yerindeki ocak (Önsöz, 9–10 Nisan; K110): tipi ocak taşlarını çatlattı, ocak «Ocak» görevine dek boştur. Bu düğüm menünün ateşini
## (Camp/Campfire) gizler (ışık, alev, kıvılcım, çıtırtı) ve yerine kurulan ateşi gösterir (HearthView: önce çatlak taşlar ve kül; «Ocak»ta üç
## taş, odun, alev; HearthFire). Ateş harlanıp menünün ölçüsüne oturunca light_menu_fire() menünün ateşini geri açar ve kurulan ateşi gizler:
## menünün karesi menünün ateşiyle çekilir (test_main_menu). Düğüm koşucunun kökündedir (days.root()); koşucu durunca (atlama, bitiş, Ana
## Menü) kökle silinir ve _exit_tree menünün ateşini her durumda geri açar.
##   var hc := HearthCold.ensure(days)      # yoksa kurar; varsa onu verir
##   hc.fire.place_stone(); hc.view.burst()
##   hc.light_menu_fire()                    # sinemadan önce

const NODE_NAME := "HearthCold"
const CAMPFIRE := ^"Camp/Campfire"

var world: Node3D
var fire: HearthFire
var view: HearthView
var campfire: Node3D

var _saved := {}
var _menu_lit := false


## Koşucunun kökünde ocak (yoksa kurulur; kök yoksa dünyanın altında).
static func ensure(days: PrologueDays) -> HearthCold:
	if days == null or days.world == null:
		return null
	var parent: Node = days.root() if days.root() else days.world
	var found := parent.get_node_or_null(NodePath(NODE_NAME)) as HearthCold
	if found:
		return found
	var hc := HearthCold.new()
	hc.name = NODE_NAME
	hc.world = days.world
	parent.add_child(hc)
	return hc


func _ready() -> void:
	if world == null:
		world = get_parent() as Node3D
	campfire = world.get_node_or_null(CAMPFIRE) as Node3D if world else null
	fire = HearthFire.new(int(hash("hearth_1170")) % 100000)
	view = HearthView.new()
	view.bind(fire)
	add_child(view)
	if campfire:
		view.global_position = campfire.global_position
		_hide_menu_fire()


## Menünün ateşi gösteriliyor mu (light_menu_fire sonrası)?
func menu_fire_lit() -> bool:
	return _menu_lit


## Kurulan ateş menünün ateşine oturdu: menünün ateşi açılır, kurulan ateş gizlenir.
func light_menu_fire() -> void:
	_menu_lit = true
	_restore_menu_fire()
	if view:
		view.visible = false
		view.process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if fire and not _menu_lit:
		fire.tick(delta)


func _hide_menu_fire() -> void:
	if campfire == null or not _saved.is_empty():
		return
	_saved = {"visible": campfire.visible, "process": campfire.process_mode}
	campfire.visible = false
	campfire.process_mode = Node.PROCESS_MODE_DISABLED
	for c in campfire.get_children():
		if c is AudioStreamPlayer3D:
			(c as AudioStreamPlayer3D).stream_paused = true


func _restore_menu_fire() -> void:
	if campfire == null or not is_instance_valid(campfire) or _saved.is_empty():
		return
	campfire.visible = bool(_saved["visible"])
	campfire.process_mode = int(_saved["process"])
	for c in campfire.get_children():
		if c is AudioStreamPlayer3D:
			(c as AudioStreamPlayer3D).stream_paused = false
	_saved = {}


func _exit_tree() -> void:
	_restore_menu_fire()
