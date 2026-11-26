class_name ChildDrive
extends Node
## Geliştirme: çocuk denetleyicisini tuşsuz sürer (pencereli kare ve hareket kaydı; main.gd --drive). Yol «;» ile ayrılmış adımlardır, adımlar sırayla işler, süre saniyedir:
##   walk=AÇI/SN    kameraya göre yürür (açı derece, 0 ekranda yukarı, 90 sağ)     run=AÇI/SN    koşar
##   wait=SN        bekler                                                         e             E'ye basar (binme, inme, alma, kalkma)
##   prod           koşu tuşuna bir kez basar (dürtme)                             gallop=AÇI/SN dörtnal (koşu tuşu basılı)
##   aim=DX/DZ      oyuncunun yerine göre noktaya nişan alır, germeye başlar       loose         bırakır
##   dummy=DX/DZ    oyuncunun yerine göre sınama hedefi koyar (TargetDummy)        aimdummy      son hedefe nişan alır
##   zoom=M         kamera uzaklığı                                                yaw=DERECE    kamera açısı
##   jump           zıplar (Boşluk; yürürken ya da koşarken de; atta at sıçrar)    trot=AÇI/SN   koşu tuşu basılı yürür (atta tırıs, sonra dörtnal)
##   tilt=DERECE    kameranın oturum eğimine ekler (artı yükseltir; bant 15–60°)  reset         `/` (kuzey, oturum eğimi 0, başlangıç uzaklığı)
## Her adım işlerken «[drive] kare N: adım» yazılır (N işlenen kare: --fixed-fps ile --write-movie kaydında videonun karesidir; kareyi bulmak için).
## Örnek: tools/capture.sh $TMPDIR/x.png 600 --window=1920x1080 --state=childhood "--drive=walk=90/2;e;wait=1;walk=0/3;aim=6/-2;wait=0.6;loose"
## Atla sıçrama (Serbest Gez, ahırın önünde): --state=play --at=12.49,-12.42,152 "--drive=yaw=152;wait=1.5;e;wait=2.4;walk=15/1.6;walk=90/0.8;gallop=90/2.3;jump;gallop=90/0.9"

var player: PlayerController
var camera: FollowCamera
var steps: PackedStringArray = []
var dummy: Node3D

var _index := 0
var _wait := 0.0


func setup(p_player: PlayerController, p_camera: FollowCamera, path: String) -> void:
	player = p_player
	camera = p_camera
	steps = path.split(";", false)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		# Dünya kurulamadı: sürülecek bir şey yok. Yetişkin de sürülür (deneme haritasında Mete; --state=testmap); nişan adımları
		# yalnız çocuk kipindedir (yay).
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait > 0.0:
			return
		player.auto_move = Vector2.ZERO
		player.auto_sprint = false
	while _index < steps.size() and _wait <= 0.0:
		_run(steps[_index].strip_edges())
		_index += 1
	if _index >= steps.size() and _wait <= 0.0:
		set_process(false)


func _run(step: String) -> void:
	print("[drive] kare %d: %s" % [Engine.get_process_frames(), step])
	var parts := step.split("=", false)
	var verb := parts[0]
	var args := parts[1].split("/", false) if parts.size() > 1 else PackedStringArray()
	match verb:
		"walk", "run", "gallop", "trot":
			var angle := deg_to_rad(float(args[0]))
			player.auto_move = Vector2(sin(angle), cos(angle))
			player.auto_sprint = verb != "walk"
			_wait = float(args[1]) if args.size() > 1 else 1.0
		"wait":
			_wait = float(args[0])
		"jump":
			player.jump()
		"e":
			player.interact()
		"prod":
			player.auto_sprint = true
			_wait = 0.1
		"aim":
			if player.archer() == null:
				push_warning("[drive] nişan yalnız çocuk kipinde: %s" % step)
				return
			var at := player.global_position + Vector3(float(args[0]), 0.0, float(args[1]))
			at.y = float(player.terrain_shape.call(&"height_at", at.x, at.z))
			player.archer().aim_override = at
			player.begin_aim()
		"aimdummy":
			if player.archer() == null:
				push_warning("[drive] nişan yalnız çocuk kipinde: %s" % step)
				return
			player.archer().aim_override = dummy
			player.begin_aim()
		"loose":
			player.release_aim()
		"dummy":
			dummy = TargetDummy.new()
			player.get_parent().add_child(dummy)
			var spot := player.global_position + Vector3(float(args[0]), 0.0, float(args[1]))
			spot.y = float(player.terrain_shape.call(&"height_at", spot.x, spot.z))
			dummy.global_position = spot
		"zoom":
			camera.zoom_by(float(args[0]) - camera.get_target_distance())
		"yaw":
			camera.set_yaw(deg_to_rad(float(args[0])), true)
		"tilt":
			camera.add_pitch(float(args[0]))
		"reset":
			camera.reset_view()
		_:
			push_warning("[drive] bilinmeyen adım: %s" % step)
