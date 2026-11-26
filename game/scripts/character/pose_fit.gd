class_name PoseFit
extends RefCounted
## Karakter modellerinin pozlu hâlini ölçen yardımcılar (geliştirme aracı ve testler için).
##
## Meshy animasyonlarında karakterin en alt noktası her zaman y = 0'da değildir: ör. "bağdaş kurup oturma"
## klibinde annenin kalçası yerden ~5 cm yukarıda kalır, bekleme klibinde Mete'nin çizme burnu ~3 cm
## gömülür. scripts/character/character_fit_tool.gd bu yardımcılarla her rolün "zemine oturma payını"
## ve yürüme/koşma kliplerinin doğal hızını ölçüp <id>_fit.json dosyasına yazar; CharacterAvatar da
## oynattığı role göre modeli bu kadar kaydırır ve animasyon hızını gerçek hıza göre ayarlar.
##
## Ölçüm, iskeletin o anki pozuyla köşeleri işlemcide (CPU) deri giydirerek yapılır; pencere ya da
## ekran kartı gerekmez (başsız çalışır).
##
## Zemine değen nokta olarak yalnızca baldır ve ayak köşeleri sayılır (CONTACT_BONES): pelerin, etek ve
## uzun cüppe gibi bol kıyafet parçaları uyluk ve kol kemiklerine bağlıdır; bağdaş kurunca bu kumaş
## yerin altına sarkar (ör. Mete'nin pelerini 10 cm). En alt köşeye göre hizalansaydı karakter havada
## kalırdı; kumaşın zemine gömülen kısmı ise halının ve çimenin altında kaybolur.
##
## Klip başına temas kemikleri (K90, data/clip_library.json contact): baldır ve ayak kuralı her duruşa uymaz. Altı eski ve
## dokuz yeni karakterin 120 kliple ölçümü (kemik eklemleri ve baskın kemiğe göre köşeler, zemine göre):
##   - Ayakta, yürürken, koşarken ve sandalyede yere yalnız ayak değer (FOOT_BONES): uzun cüppenin baldıra bağlı eteği
##     ayaktan 1-3 cm aşağı sarkar (Ana 2,6, Ozan 2,8, Lan Hatun 1,0 cm), baldır sayılınca kişi o kadar havada kalır.
##   - Yerde oturuş (SEAT_BONES): kalça ve bacak zinciri, uyluk hariç. Uyluğa baskın köşelerin çoğu kumaştır: bağdaşta
##     18 cm, diz çökmede 23 cm zeminin altına sarkar; uyluk sayılsaydı Mete'nin kalça eklemi bağdaşta 20 yerine 37 cm'de
##     kalırdı. Eli yere dayanan klip eli de sayar (ground_side_sit) ve omuz düzeltmesi (ShoulderRelax) işlenmiş pozdan ölçülür
##     (has_hand_contact). Kalçası zemine indirilen oturuşlar (leg_fit seat) baldırı da saymaz:
##     cüppenin baldıra bağlı eteği kalçayla iner, sayılsa kişi eteğin üstünde yükselir, ayak 5-11 cm havada kalırdı.
##   - Yatarken (LYING_BONES): gövde ve baş; baldır ve ayak kuralı sırtı 7-31 cm havada bırakır. Bu kümede cüppenin eteği zemine gömülür; ayak
##     da gömülürdü (klipte bacak aşağı eğimlidir, kadroda 20 cm'ye kadar): zemine giren ayak klip kurulurken kalkar (leg_fit lie), sırt zeminde kalır.
##   - Diz çökme ve dört ayak: varsayılan (CONTACT_BONES): yere baldır ve diz değer. Diz çökerek oturuş (ground_kneel_heels) ayağıyla
##     ölçülür: dizi ve ayağı ClipLibrary.fit_legs zemine indirir, cüppenin eteği (baldıra bağlı, dizden 20 cm aşağı sarkar) gömülür.
##   - Geçişler ayaklarıyla (FOOT_BONES) ölçülür: ayakta uç, bekleme klibinin zeminine otursun; öteki ucun payı ayrıdır
##     (clip_library_measure.json ends).
##
## Zemin payı temas kemiklerini zemine oturtur; oturuşta beden yine havada kalabilir: metinden hareketlerde ayak ve baldır zemindeyken
## kalça 9-15 cm havadaydı. Kalça boşluğu (seat_min_y) bunu ölçer: kalça ve uyluk köşelerinin kalça ekleminin yatayda SEAT_RADIUS
## çevresindeki en altı; bu çevrenin dışındaki uyluk köşeleri kumaş ya da dizdir, bedeni taşımaz.

## Ayağın "yere basıyor" sayıldığı yükseklik bandı: en alçak noktasının bu kadar üstüne kadar (metre).
const CONTACT_BAND := 0.015
## Zemine değen kemikler (Meshy iskelet adları): ayakta da bağdaş kurarken de yere baldır ve ayak değer.
const CONTACT_BONES: Array[String] = ["LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
## Klip başına temas kümeleri (yukarıdaki ölçüm; data/clip_library.json contact ve states bunları yazar).
const FOOT_BONES: Array[String] = ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
const SEAT_BONES: Array[String] = ["Hips", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
const LYING_BONES: Array[String] = ["Hips", "Spine02", "Spine01", "Spine", "neck", "Head"]
## Kalça boşluğunun kemikleri ve çevresi (metre): kalça eklemine yatayda bu kadar yakın köşeler bedenin oturduğu yerdir.
const SEAT_CORNER_BONES: Array[String] = ["Hips", "LeftUpLeg", "RightUpLeg"]
const SEAT_RADIUS := 0.2
## Tek ayağın kemikleri (bir ayağı sürekli havada kalan bekleme klipleri için).
const LEFT_FOOT_BONES: Array[String] = ["LeftFoot", "LeftToeBase"]
const RIGHT_FOOT_BONES: Array[String] = ["RightFoot", "RightToeBase"]
## Diz çökmede yere değen baldır ve diz.
const SHIN_BONES: Array[String] = ["LeftLeg", "RightLeg"]
## Yere dayanan el.
const HAND_BONES: Array[String] = ["LeftHand", "RightHand"]
## Zemin payı için klip başına örnek kare (character_fit_tool.gd SAMPLES ile aynı ölçüm).
const FLOOR_SAMPLES := 12
## Yürüme ve koşmanın zemin payı: daha çok örnek ve en alçak ana değil, kare başına en alt noktaların alttan bu kadarlık dilimi
## (low_share_offset). Yürürken her karede bir ayak yerdedir, dilim geniş: 12 örnekli en alçak an Baba'yı quick_walk'ta çoğu
## karede 4-5 cm havada bırakıyordu. Koşunun uçuş kareleri payı bozmasın diye dilim dar. Kural tektir: tools/anim_library_import.gd
## oyunun payını, tools/clip_library_export.gd belge sitesinin payını buradan ölçer (floor_times, floor_offset).
const STRIDE_FLOOR_SAMPLES := 60
const STRIDE_LOW_SHARE := {"walk": 0.25, "run": 0.1}


## Modeldeki deri giydirilmiş (skinned) meshlerin, iskeletlerin ŞU ANKİ pozuyla en alt noktası
## (model kökünün kendi uzayında, metre). contact boş değilse yalnızca en çok bu kemiklere bağlı köşeler
## sayılır (hiç yoksa tüm köşeler). Deri giydirilmemiş meshler dinlenme hâliyle sayılır.
static func skinned_min_y(model: Node3D, contact: Array[String] = CONTACT_BONES) -> float:
	var lowest := INF
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi.skin else null
		var to_model := relative_transform(model, skel if skel else mi)
		var mats := _skin_matrices(mi, skel, to_model)
		var allowed := _contact_binds(mi, skel, contact)
		for s in mi.mesh.get_surface_count():
			lowest = minf(lowest, _surface_min_y(mi.mesh.surface_get_arrays(s), mats, to_model, allowed))
	return lowest


## Oturan bedenin en altı (model kökünün uzayında, metre; bkz. dosyanın başı): kalça ve uyluk köşelerinin, kalça ekleminin yatayda
## SEAT_RADIUS çevresindeki en altı. İskelet ya da böyle köşe yoksa INF.
static func seat_min_y(model: Node3D) -> float:
	var lowest := INF
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi.mesh and mi.skin else null
		if skel == null or skel.find_bone("Hips") < 0:
			continue
		var to_model := relative_transform(model, skel)
		var mats := _skin_matrices(mi, skel, to_model)
		var allowed := _contact_binds(mi, skel, SEAT_CORNER_BONES)
		if allowed.is_empty():
			continue
		var hips: Vector3 = to_model * skel.get_bone_global_pose(skel.find_bone("Hips")).origin
		for s in mi.mesh.get_surface_count():
			lowest = minf(lowest, _surface_seat_min_y(mi.mesh.surface_get_arrays(s), mats, allowed, Vector2(hips.x, hips.z)))
	return lowest


## Tanımdaki temas listesi (JSON dizisi) yazılı dizi olarak; boş ya da yoksa CONTACT_BONES.
static func contact_list(value: Variant) -> Array[String]:
	if not value is Array or (value as Array).is_empty():
		return CONTACT_BONES
	var out: Array[String] = []
	for bone in value:
		out.append(str(bone))
	return out


## node'un root'a göre dönüşümü (root'un kendi dönüşümü hariç).
static func relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			xform = (n as Node3D).transform * xform
		n = n.get_parent()
	return xform


## Ayağın yere bastığı karelerdeki ortalama yatay hızı (m/s): yerinde yürüyen bir klipte bu, ayağın
## gövdeye göre geriye kayma hızıdır; yani klibin "doğal" yürüme hızı. Ayak yüksekliği ve ileri konumu
## eşit aralıklı (dt) örneklerdir. Yeterli örnek yoksa 0 döner.
static func stance_speed(heights: PackedFloat32Array, forward: PackedFloat32Array, dt: float, band: float = CONTACT_BAND) -> float:
	var n := mini(heights.size(), forward.size())
	if n < 3 or dt <= 0.0:
		return 0.0
	var floor_y := INF
	for i in n:
		floor_y = minf(floor_y, heights[i])
	var total := 0.0
	var count := 0
	for i in range(1, n - 1):
		if heights[i] > floor_y + band:
			continue
		# Basan ayak gövdeye göre geri gider. Bandın içinde ileri giden kare salınımdadır: proud_strut'ta sayılınca hız 1,13 çıkıyordu
		# (basış 0,67), Teoman'ın ayağı adım başına 49 cm kayıyordu.
		var speed := (forward[i - 1] - forward[i + 1]) / (2.0 * dt)
		if speed > 0.0:
			total += speed
			count += 1
	return total / count if count > 0 else 0.0


## Bir rolün zemine oturma payı: klibin örneklenen karelerindeki en alt noktanın tersi (metre).
## Model bu kadar kaydırılınca en alt noktası tam zemine (y = 0) değer.
static func ground_offset(min_heights: PackedFloat32Array) -> float:
	if min_heights.is_empty():
		return 0.0
	var lowest := INF
	for h in min_heights:
		lowest = minf(lowest, h)
	return -lowest if is_finite(lowest) else 0.0


## Yürüme ve koşmanın zemin payı: kare başına en alt noktaların alttan share'lik dilimi zemine değer. En alçak ana göre alınan pay
## adımları eşit olmayan klipte kişiyi çoğu karede havada bırakır, örnek kaçırılan klipte de gömer; koşunun uçuş kareleri payı bozmasın
## diye dilim alttan sayılır. Örnek yoksa 0.
static func low_share_offset(min_heights: PackedFloat32Array, share: float) -> float:
	if min_heights.is_empty():
		return 0.0
	var sorted := min_heights.duplicate()
	sorted.sort()
	return -sorted[clampi(int(sorted.size() * share), 0, sorted.size() - 1)]


## Klip döngülü bir yürüme ya da koşma mı (tanımı; zemin payı dilimle ölçülür)?
static func is_stride(spec: Dictionary) -> bool:
	return bool(spec.get("loop", true)) and STRIDE_LOW_SHARE.has(str(spec.get("group", "")))


## Zemin payının ölçüldüğü anlar. Yürüme ve koşmada STRIDE_FLOOR_SAMPLES örnek, sonuncusu süreden bir adım önce (döngülü klipte seek(süre) ilk
## kareye sarar); öteki kliplerde FLOOR_SAMPLES örnek, ilk ve son kare dahil.
static func floor_times(length: float, spec: Dictionary) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	if PoseFit.is_stride(spec):
		for i in STRIDE_FLOOR_SAMPLES:
			times.append(length * i / float(STRIDE_FLOOR_SAMPLES))
	else:
		for i in FLOOR_SAMPLES:
			times.append(length * i / float(FLOOR_SAMPLES - 1))
	return times


## Klibin zemin payı, floor_times'ın anlarındaki en alt noktalardan: yürüme ve koşmada alttan dilim, öteki kliplerde en alçak an.
static func floor_offset(min_heights: PackedFloat32Array, spec: Dictionary) -> float:
	if PoseFit.is_stride(spec):
		return PoseFit.low_share_offset(min_heights, float(STRIDE_LOW_SHARE[str(spec.get("group", ""))]))
	return PoseFit.ground_offset(min_heights)


## Klipte yere dayanan el var mı (tanımı: temas kemiği ya da leg_fit hands)? Varsa ölçüm oyunun gördüğü pozdan yapılır: ShoulderRelax
## köprücüğü indirir, bilek onunla iner (Ana, ground_side_sit: düzeltmesiz ölçülen pay eli 2,4 cm gömüyordu).
static func has_hand_contact(spec: Dictionary) -> bool:
	var contact: Variant = spec.get("contact")
	if contact is Array and HAND_BONES.any(func(bone: String) -> bool: return (contact as Array).has(bone)):
		return true
	var parts: Variant = spec.get("leg_fit")
	return parts is Array and (parts as Array).has("hands")


static func _skin_matrices(mi: MeshInstance3D, skel: Skeleton3D, to_model: Transform3D) -> Array[Transform3D]:
	var mats: Array[Transform3D] = []
	var skin := mi.skin
	if skin == null or skel == null:
		return mats
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		if bone < 0:
			bone = skel.find_bone(skin.get_bind_name(i))
		var pose := skel.get_bone_global_pose(bone) if bone >= 0 else Transform3D.IDENTITY
		mats.append(to_model * pose * skin.get_bind_pose(i))
	return mats


## Deri bağlarından (bind) hangilerinin zemine değen kemiklere ait olduğu (1 = sayılır). Hiçbiri yoksa boş
## döner: o zaman tüm köşeler sayılır.
static func _contact_binds(mi: MeshInstance3D, skel: Skeleton3D, contact: Array[String]) -> PackedByteArray:
	var result := PackedByteArray()
	var skin := mi.skin
	if skin == null or skel == null or contact.is_empty():
		return result
	var any := false
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		var name := skel.get_bone_name(bone) if bone >= 0 else String(skin.get_bind_name(i))
		var hit := contact.has(name)
		result.append(1 if hit else 0)
		any = any or hit
	return result if any else PackedByteArray()


## Bir yüzeyin en alt köşesi. allowed boş değilse yalnızca en büyük ağırlığı izinli bir bağa ait köşeler.
static func _surface_min_y(arrays: Array, mats: Array[Transform3D], to_model: Transform3D, allowed: PackedByteArray) -> float:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var lowest := INF
	if mats.is_empty() or arrays[Mesh.ARRAY_BONES] == null:
		for v in verts:
			lowest = minf(lowest, (to_model * v).y)
		return lowest
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / maxi(verts.size(), 1)
	var filtered := not allowed.is_empty()
	for v in verts.size():
		var base := v * stride
		if filtered:
			var dominant := 0
			for k in range(1, stride):
				if weights[base + k] > weights[base + dominant]:
					dominant = k
			if allowed[bones[base + dominant]] == 0:
				continue
		var y := 0.0
		for k in stride:
			var w := weights[base + k]
			if w > 0.0:
				y += (mats[bones[base + k]] * verts[v]).y * w
		lowest = minf(lowest, y)
	return lowest


## Yüzeyin kalça çevresindeki en alt köşesi (seat_min_y): en büyük ağırlığı izinli bir bağa ait ve kalça ekleminin yatayda SEAT_RADIUS
## çevresindeki köşeler.
static func _surface_seat_min_y(arrays: Array, mats: Array[Transform3D], allowed: PackedByteArray, around: Vector2) -> float:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var lowest := INF
	if mats.is_empty() or arrays[Mesh.ARRAY_BONES] == null:
		return lowest
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / maxi(verts.size(), 1)
	for v in verts.size():
		var base := v * stride
		var dominant := 0
		for k in range(1, stride):
			if weights[base + k] > weights[base + dominant]:
				dominant = k
		if allowed[bones[base + dominant]] == 0:
			continue
		var p := Vector3.ZERO
		for k in stride:
			var w := weights[base + k]
			if w > 0.0:
				p += (mats[bones[base + k]] * verts[v]) * w
		if p.y < lowest and Vector2(p.x, p.z).distance_to(around) <= SEAT_RADIUS:
			lowest = p.y
	return lowest
