class_name JourneyFlags
extends RefCounted
## Yolculuğun işaretleri: oyuncu kampta bir şey yaptıkça (ilk kez dolaşınca, ateşin başına varınca,
## ahırı görünce...) bir işaret konur; Destan Kitabı'nın dizeleri, kişileri ve taşları bu işaretlerle
## açılır. Burada işaretlerin adları, yer işaretlerinin (landmark) kurulması ve koşulların
## değerlendirilmesi vardır; hepsi saf fonksiyondur (sahne gerekmez, test edilebilir).
##
## Yer işaretleri: işaret adı → Vector3(x, z, yarıçap) listesi. Oyuncu bir dairenin içine girince
## o işaret konur. Göl ise kamptan uzakta, aşağıda kalır: platonun kuzey kenarına (vadiye bakan
## yamaç) varmak yeter (bkz. overlooks_lake). Ozanı dinlemek süreli bir yerdir: ozanın çevresinde
## BARD_LISTEN_SECONDS kesintisiz kalmak gerekir; süreyi Journey.visit sayar (flags_at onu koymaz).
##
## Yerden bağımsız işaretler: Önsöz (PROLOGUE; oluşturucunun onayında main.gd yazar, CineHost.PROLOGUE_FLAG
## ile aynı) mit girdilerini ve «Doğum»u açar; ozanı dinlemek (BARD_LISTEN) «Gök ve Yer»de iyeleri açar.

## İlk serbest gezinti.
const FIRST_ROAM := "ilk_gezinti"
## Ateşin başına varmak.
const FIRESIDE := "ates_basi"
## Ahırın önüne gitmek (iki at).
const STABLE := "ahir_ziyaret"
## Büyük yosunlu kayalardan birine varmak.
const BOULDER := "yosunlu_kaya"
## Dikili kaya kümelerinden birine varmak.
const FORMATION := "kaya_kumesi"
## Göle bakan yamaca (platonun kuzey kenarı) varmak.
const LAKE_VIEW := "gol_yamaci"
## Önsöz oynandı ya da atlandı (CineHost.PROLOGUE_FLAG ile aynı): «Gök ve Yer»in Önsöz girdileri ve «Doğum».
const PROLOGUE := "onsoz"
## Ateş başında ozanı BARD_LISTEN_SECONDS kesintisiz dinlemek (K35): «Gök ve Yer»de iyeler açılır.
const BARD_LISTEN := "ozan_dinledi"
const ALL: Array[String] = [FIRST_ROAM, FIRESIDE, STABLE, BOULDER, FORMATION, LAKE_VIEW, PROLOGUE, BARD_LISTEN]
## Süreli yerler: dairenin içinde durmak yetmez, süreyi Journey.visit sayar; flags_at bunları koymaz.
const TIMED: Array[String] = [BARD_LISTEN]

## Ateşin başı sayılan uzaklık (m). Oyuncu ateşin sağ önünde (~4,1 m) belirir; birkaç adım yaklaşmalı.
const FIRESIDE_RADIUS := 3.0
## Ahırın önü sayılan uzaklık (ahırın merkezinden, m).
const STABLE_RADIUS := 6.5
## Büyük kaya sayılan en küçük boyut (m) ve kayanın yarı boyuna eklenen yakınlık payı (m). Pay küçük
## tutulur: oyuncunun belirdiği yer ön plandaki R3 kayasının hemen yanıdır; kayaya dokunmak gerekir.
const BOULDER_MIN_SIZE := 2.0
const BOULDER_REACH := 0.6
## Kaya kümesinin ölçek başına yarıçapı (m).
const FORMATION_RADIUS := 5.5
## Göle bakan yamaç: kamp merkezinden en az bu kadar uzakta (m) ve kuzeyden (-Z) ölçülen bu açı
## aralığında (derece; 0 = kuzey, artı = doğu). Vadi ve göl bu yönde, platonun ~24-28 m ötesinde.
const LAKE_VIEW_DISTANCE := 22.0
const LAKE_VIEW_SECTOR := Vector2(-60.0, 25.0)
## Kampın içi sayılan yarıçap (m; daha uzağı "Çayır").
const CAMP_RADIUS := 14.0
## Ozanı dinlemek: ozanın çevresindeki yarıçap (m) ve kesintisiz kalınacak süre (sn, oynanan süreyle).
## Oyuncunun belirdiği yer (ateşin sağ önü) ozana ≈3,9 m uzaktır: dinlemek için yanına gitmek gerekir.
const BARD_RADIUS := 3.0
const BARD_LISTEN_SECONDS := 5.0

## Yer kimliği → kayıt kartlarında görünen ad.
const PLACE_NAMES := {
	"ocak": "Ocak başı",
	"ahir": "Ahırın önü",
	"yamac": "Göle bakan yamaç",
	"kaya": "Yosunlu kayalar",
	"kume": "Dikili kayalar",
	"kamp": "Yurtların arası",
	"cayir": "Çayır",
}

## world.tscn'deki yerler (dünya düğümleri okunamazsa yedek): ateş (0, 0), ahır (13,76; -14,65), ozan
## (CampNpcs/Elder, 2,35; -0,65).
const DEFAULT_FIRE := Vector2(0.0, 0.0)
const DEFAULT_STABLE := Vector2(13.76, -14.65)
const DEFAULT_BARD := Vector2(2.35, -0.65)
## Ozanın düğümü (dünyaya göre).
const BARD_NODE := ^"Camp/CampNpcs/Elder"

## holds'un bağlamı (tek örnek: sınama eşzamanlıdır, işaret sözlüğü yalnız sınama boyunca tutulur).
static var _ctx := Cond.DictCtx.new()


## Bir işaret konmuş mu? (true, sıfırdan farklı sayı ya da boş olmayan yazı "konmuş" sayılır; "false" ve "0" yazısı konmamıştır.)
## Doğruluk koşul dilinindir (Cond.truthy). 2026-11-08 (conditions-effects): boş dizi ve boş sözlük konmamış sayılır (prototipin push
## bayrağı: first_ten: [] yanlıştır); bugünkü işaretler bool ve sayıdır, sonuçları değişmez.
static func is_set(flags: Dictionary, key: String) -> bool:
	return Cond.truthy(flags.get(key, false))


## Koşul işaretlerde tutuyor mu? Tanhu 1'in biçimi: "a", "!a", "a || b", "a && !b"; boş koşul ve "*" her zaman tutar.
## Dil genişler, değişmez (conditions-effects, godot.md §1 madde 7): koşul dilinin (Cond) okuduğu her dizge Cond'la sınanır: ayraç,
## kıyas ("takvim_gun>=1041", "child_spared==true", "eskam_saw==uldin"), önekli atom (yolu bayrağın adıdır). Cond'un okumadığı dizge
## (ör. "a ||", "a b", "kisiler/ana", "a && *") eski yoldan sınanır: var olan koşulların sonucu aynı kalır (test_conditions.gd).
static func holds(flags: Dictionary, cond: String) -> bool:
	var node: Variant = Cond.compile(cond)
	if node == null:
		return holds_legacy(flags, cond)
	_ctx.values = flags
	var out := Cond.eval_node(node, _ctx)
	_ctx.values = {}
	return out


## Tanhu 1'in koşul dili (2026-11-08'e dek holds'un kendisi): önce «||», sonra «&&», sonra «!»; parça bayrağın adıdır.
static func holds_legacy(flags: Dictionary, cond: String) -> bool:
	cond = cond.strip_edges()
	if cond == "" or cond == "*":
		return true
	if cond.contains("||"):
		for part in cond.split("||"):
			if holds_legacy(flags, part):
				return true
		return false
	if cond.contains("&&"):
		for part in cond.split("&&"):
			if not holds_legacy(flags, part):
				return false
		return true
	if cond.begins_with("!"):
		return not holds_legacy(flags, cond.substr(1))
	return is_set(flags, cond)


## Dizi bayrağına tekil eleman ekler (prototipin FlagStore.push'u): eski dizi değişmez, yenisi yazılır; dizi olmayan eski değer boş
## sayılır. Sözlük eleman id'siyle (id'si yoksa içeriğiyle) kıyaslanır. Döner: eklendi mi?
static func push(flags: Dictionary, key: String, value: Variant) -> bool:
	var prev: Variant = flags.get(key)
	var list: Array = (prev as Array).duplicate() if prev is Array else []
	for entry: Variant in list:
		if same_entry(entry, value):
			return false
	list.append(value)
	flags[key] = list
	return true


## Sayı bayrağını artırır (sayı olmayan eski değer 0'dan başlar). Döner: yeni değer.
static func inc(flags: Dictionary, key: String, n: float = 1.0) -> float:
	var prev: Variant = flags.get(key)
	var next := (float(prev) if (prev is int or prev is float) else 0.0) + n
	flags[key] = int(next) if is_equal_approx(next, roundf(next)) and absf(next) < 9.0e15 else next
	return next


## Dizi elemanı kıyası: kayıttan dönen sözlük başka örnektir; id'si olan id ile, olmayan içerikle kıyaslanır.
static func same_entry(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var da := a as Dictionary
		var db := b as Dictionary
		if da.has("id") or db.has("id"):
			return da.get("id") == db.get("id")
		return JSON.stringify(da, "", true) == JSON.stringify(db, "", true)
	if (a is String or a is StringName) and (b is String or b is StringName):
		return String(a) == String(b)
	if typeof(a) != typeof(b) and not ((a is int or a is float) and (b is int or b is float)):
		return false
	return a == b


## Yerin görünen adı (bilinmeyen kimlik: kampın içi).
static func place_name(place_id: String) -> String:
	return str(PLACE_NAMES.get(place_id, PLACE_NAMES["kamp"]))


## Dünyadan yer işaretlerini kurar: Camp/Campfire, Camp/Stable, ozan (Camp/CampNpcs/Elder) ve RockField'ın
## büyük kayaları ile kaya kümeleri. Düğümler yoksa world.tscn'deki yerlere düşer.
static func landmarks_from_world(world: Node) -> Dictionary:
	var fire := DEFAULT_FIRE
	var stable := DEFAULT_STABLE
	var bard := DEFAULT_BARD
	var rocks: Array = []
	var formations: Array = []
	if world:
		var fire_node := world.get_node_or_null(^"Camp/Campfire") as Node3D
		if fire_node:
			fire = Vector2(fire_node.position.x, fire_node.position.z)
		var stable_node := world.get_node_or_null(^"Camp/Stable") as Node3D
		if stable_node:
			stable = Vector2(stable_node.position.x, stable_node.position.z)
		var bard_node := world.get_node_or_null(BARD_NODE) as Node3D
		if bard_node:
			bard = xz_in(world, bard_node)
		var field := world.get_node_or_null(^"RockField")
		if field:
			var hero: Variant = field.get(&"hero_rocks")
			if hero is Array:
				rocks = hero
			var groups: Variant = field.get(&"formations")
			if groups is Array:
				formations = groups
	return build_landmarks(fire, stable, rocks, formations, bard)


## Düğümün dünyaya göre (x, z) konumu: dünyaya dek ebeveynlerin dönüşümleri çarpılır (sahne ağaçta olmasa da).
static func xz_in(world: Node, node: Node3D) -> Vector2:
	var xform := Transform3D.IDENTITY
	var n: Node = node
	while n and n != world:
		if n is Node3D:
			xform = (n as Node3D).transform * xform
		n = n.get_parent()
	return Vector2(xform.origin.x, xform.origin.z)


## Yer işaretlerini verilen konumlardan kurar (saf fonksiyon).
## rocks: Vector4(x, z, boyut, yön) listesi; formations: Vector4(x, z, ölçek, yön) listesi; bard: ozanın yeri.
static func build_landmarks(fire: Vector2, stable: Vector2, rocks: Array, formations: Array, bard: Vector2 = DEFAULT_BARD) -> Dictionary:
	var boulders: Array = []
	for r in rocks:
		if r is Vector4 and (r as Vector4).z >= BOULDER_MIN_SIZE:
			var v := r as Vector4
			boulders.append(Vector3(v.x, v.y, v.z * 0.5 + BOULDER_REACH))
	var clusters: Array = []
	for f in formations:
		if f is Vector4:
			var v := f as Vector4
			clusters.append(Vector3(v.x, v.y, FORMATION_RADIUS * maxf(v.z, 0.3)))
	return {
		FIRESIDE: [Vector3(fire.x, fire.y, FIRESIDE_RADIUS)],
		STABLE: [Vector3(stable.x, stable.y, STABLE_RADIUS)],
		BOULDER: boulders,
		FORMATION: clusters,
		BARD_LISTEN: [Vector3(bard.x, bard.y, BARD_RADIUS)],
	}


## Nokta ozanı dinleyecek kadar yakın mı? (Süreyi Journey.visit sayar.)
static func near_bard(xz: Vector2, landmarks: Dictionary) -> bool:
	for c: Variant in landmarks.get(BARD_LISTEN, []):
		if c is Vector3 and xz.distance_to(Vector2(c.x, c.y)) <= c.z:
			return true
	return false


## Bu noktada konması gereken işaretler (saf fonksiyon). xz: oyuncunun (x, z) konumu. Süreli yerler
## (TIMED: ozanı dinlemek) burada konmaz.
static func flags_at(xz: Vector2, landmarks: Dictionary, camp_center: Vector2 = DEFAULT_FIRE) -> PackedStringArray:
	var out := PackedStringArray()
	for key in landmarks:
		if str(key) in TIMED:
			continue
		for c in landmarks[key]:
			if c is Vector3 and xz.distance_to(Vector2(c.x, c.y)) <= c.z:
				out.append(str(key))
				break
	if overlooks_lake(xz, camp_center):
		out.append(LAKE_VIEW)
	return out


## Nokta göle bakan yamaçta mı? Kamp merkezinden en az LAKE_VIEW_DISTANCE uzakta ve kuzey (-Z)
## yönündeki LAKE_VIEW_SECTOR açı aralığında olmalı.
static func overlooks_lake(xz: Vector2, camp_center: Vector2 = DEFAULT_FIRE) -> bool:
	var d := xz - camp_center
	if d.length() < LAKE_VIEW_DISTANCE:
		return false
	return angle_in_sector(bearing_deg(d), LAKE_VIEW_SECTOR)


## Kuzeyden (-Z) saat yönünde ölçülen yön açısı (derece, -180..180; 90 = doğu, +X).
static func bearing_deg(d: Vector2) -> float:
	return rad_to_deg(atan2(d.x, -d.y))


static func angle_in_sector(angle: float, sector: Vector2) -> bool:
	return angle >= sector.x and angle <= sector.y


## Noktanın yer kimliği (kayıt kartları için): ateş, ahır, yamaç, kaya, küme, kamp ya da çayır.
static func place_at(xz: Vector2, landmarks: Dictionary, camp_center: Vector2 = DEFAULT_FIRE) -> String:
	var here := flags_at(xz, landmarks, camp_center)
	# Ateşin başı biraz geniş tutulur: oturanların halkası da "ocak başı"dır.
	var fire: Array = landmarks.get(FIRESIDE, [])
	if not fire.is_empty() and xz.distance_to(Vector2(fire[0].x, fire[0].y)) <= fire[0].z * 1.6:
		return "ocak"
	for pair in [[STABLE, "ahir"], [LAKE_VIEW, "yamac"], [FORMATION, "kume"], [BOULDER, "kaya"]]:
		if str(pair[0]) in here:
			return str(pair[1])
	return "kamp" if xz.distance_to(camp_center) <= CAMP_RADIUS else "cayir"
