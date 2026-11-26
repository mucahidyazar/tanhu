class_name CampTour
extends RefCounted
## Serbest Gez'in görevi «Kampı Dolaş» (HUD'un görev kartı, yön işaretleri ve Görevler sayfası; görev sistemi act-1-p3 gelene dek):
## kampın yer işaretleri (JourneyFlags) sırayla adım olur: ateşin başı, ozanı dinlemek, ahır, yosunlu kaya, dikili kayalar, göle bakan
## yamaç. Adım yolculuğun işaretiyle biter (Journey.visit koyar; bu sınıf yalnız okur), sıradaki bitmemiş adım «o anki»dir; hedefi
## yer işaretinin merkezidir (kaya ve küme için oyuncuya en yakını). Hepsi bitince kart «Kamp dolaşıldı» der, hedef kalmaz.
## Destan Kitabı'nın kayıtları da bu işaretlerle açılır: görev, oyuncuyu kitabı açan yerlere götürür.
##   var tour := CampTour.new(journey, world.get_terrain_shape())
##   tour.hud_quest()          # {id, title, objective, detail, steps: [{id, text, state}], done}
##   tour.hud_target(player.global_position)

const ID := "camp_tour"
const TITLE := "Kampı Dolaş"
const DONE_TEXT := "Kamp dolaşıldı"
const DONE_DETAIL := "Bozkır seni bekliyor."
## Adımlar: yolculuğun işareti, amaç ve ayrıntı.
const STEPS: Array = [
	[JourneyFlags.FIRESIDE, "Ateşin başına var", "Ocağın başında herkes toplandı."],
	[JourneyFlags.BARD_LISTEN, "Ozanı dinle", "Yanında biraz dur; kopuz konuşsun."],
	[JourneyFlags.STABLE, "Ahırdaki atlara bak", "İki at ahırın önünde bekliyor."],
	[JourneyFlags.BOULDER, "Yosunlu bir kayaya dokun", "Büyük kayalar çayırın kıyısında."],
	[JourneyFlags.FORMATION, "Dikili kayalara git", "Eskilerin diktiği taşlar kampın ötesinde."],
	[JourneyFlags.LAKE_VIEW, "Göle bakan yamaca çık", "Vadinin dibinde göl parlıyor."],
]
## Göle bakan yamacın hedefi: eşik uzaklığının bu kadar ötesi (m).
const LAKE_MARGIN := 3.0

var journey: Journey
## Zemin yüksekliği (height_at); yoksa 0.
var shape: RefCounted
var camp_center := JourneyFlags.DEFAULT_FIRE


func _init(p_journey: Journey = null, p_shape: RefCounted = null, p_center: Vector2 = JourneyFlags.DEFAULT_FIRE) -> void:
	journey = p_journey
	shape = p_shape
	camp_center = p_center


## O anki adımın sırası (hepsi bittiyse STEPS.size()).
func current_index() -> int:
	for i in STEPS.size():
		if not _done(str(STEPS[i][0])):
			return i
	return STEPS.size()


func hud_quest() -> Dictionary:
	var cur := current_index()
	var steps: Array = []
	for i in STEPS.size():
		steps.append({"id": str(STEPS[i][0]), "text": str(STEPS[i][1]),
			"state": "done" if _done(str(STEPS[i][0])) else ("current" if i == cur else "todo")})
	var finished := cur >= STEPS.size()
	return {
		"id": ID, "title": TITLE, "objective": DONE_TEXT if finished else str(STEPS[cur][1]),
		"detail": DONE_DETAIL if finished else str(STEPS[cur][2]), "steps": steps, "done": finished,
	}


## O anki adımın hedefi (dünya; yoksa Vector3.INF). from: oyuncunun yeri (en yakın kaya / küme için).
func hud_target(from: Vector3 = Vector3.ZERO) -> Vector3:
	var cur := current_index()
	if cur >= STEPS.size() or journey == null:
		return Vector3.INF
	var key := str(STEPS[cur][0])
	var xz := Vector2.INF
	if key == JourneyFlags.LAKE_VIEW:
		xz = lake_view_point(camp_center)
	else:
		var best := INF
		for c: Variant in journey.landmarks.get(key, []):
			if c is Vector3:
				var p := Vector2((c as Vector3).x, (c as Vector3).y)
				var d := p.distance_to(Vector2(from.x, from.z))
				if d < best:
					best = d
					xz = p
	if xz == Vector2.INF:
		return Vector3.INF
	var y: float = float(shape.call(&"height_at", xz.x, xz.y)) if shape and shape.has_method(&"height_at") else 0.0
	return Vector3(xz.x, y, xz.y)


## Göle bakan yamacın noktası (saf): kamp merkezinden yamaç diliminin ortasında, eşiğin biraz ötesi.
static func lake_view_point(center: Vector2) -> Vector2:
	var bearing := deg_to_rad((JourneyFlags.LAKE_VIEW_SECTOR.x + JourneyFlags.LAKE_VIEW_SECTOR.y) * 0.5)
	return center + Vector2(sin(bearing), -cos(bearing)) * (JourneyFlags.LAKE_VIEW_DISTANCE + LAKE_MARGIN)


func _done(key: String) -> bool:
	return journey != null and journey.has_flag(key)
