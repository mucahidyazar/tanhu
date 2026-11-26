extends Node3D
## Geliştirme sahnesi: tüm Meshy karakterlerini yan yana gösterir (modelleri ve animasyonları denetlemek için).

## Oyuncu karakterleri ayakta, kamp ateşindeki NPC'ler bağdaş kurup oturur.
const IDS := ["mete", "hero_f", "mother", "child", "father", "elder"]
const SEATED := ["mother", "child", "father", "elder"]

@export var pose: StringName = &"idle"


func _ready() -> void:
	var args := preload("res://scripts/dev/capture.gd").parse_args(OS.get_cmdline_user_args())
	if args.has("lineup-pose"):
		pose = StringName(str(args["lineup-pose"]))
	var profile := CharacterProfile.new()
	if args.has("recolor"):
		# Hata ayıklama: bölge maskelerini görmek için abartılı renkler.
		profile.hair_color = 8
		profile.skin = 9
		profile.eye_color = 8
	for i in IDS.size():
		var avatar := CharacterAvatar.new()
		avatar.profile = profile
		avatar.model_override = IDS[i]
		avatar.start_pose = &"sit" if IDS[i] in SEATED else pose
		avatar.position = Vector3((i - (IDS.size() - 1) * 0.5) * 1.6, 0.0, 0.0)
		add_child(avatar)
		if args.has("walk"):
			avatar.set_locomotion(float(args["walk"]))
